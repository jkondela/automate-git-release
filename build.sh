#!/bin/bash
# Author Jaroslav Kondela
# License MIT 2017 Jaroslav Kondela

# constants
LIGHT_GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No color

VERSION='1.2.2'

push=0
merge_from_feature=0
run_npm_build=0
commit_msg='ADDED: new build'
checkout_after_done=0
tag=''
has_tag=0

GIT_MERGE_AUTOEDIT=no
export GIT_MERGE_AUTOEDIT


help=$(cat <<-END
Automate GIT release\n
\rversion ${VERSION}\n\n
\rCommands:
\r\n${LIGHT_GREEN}-v${NC} for version
\r\n${LIGHT_GREEN}-h${NC} for help
\r\n${LIGHT_GREEN}-p${NC} for push master/develop to server
\r\n${LIGHT_GREEN}-f [branch-name] ${NC} for merge feature branch to develop
\r\n${LIGHT_GREEN}-r [npm-script-name] ${NC}   script name from npm scripts for run (example: build = npm run build)
\r\n${LIGHT_GREEN}-c [commit-message] ${NC} message for commit if release branch is active (runnable only with -r command)
\r\n${LIGHT_GREEN}-n [branch-name] ${NC} after build checkout to [branch-name], if does not exist, it will be firstly created
\r\n${LIGHT_GREEN}-t [tag] ${NC} creates lightweight tag
\r\n\nExample:
\r\n${LIGHT_GREEN}./build.sh -p -f feature/checkout -r build$NC
\r\nThis firstly does merge of branch 'feature/checkout' to develop,
\r\nrun 'npm run build' and push to server
END
)

while getopts ":phf:r:c:vn:t:" opt; do
	case $opt in
		p)
			push=1
			;;
		h)
			echo -e $help
			exit
			;;
		v)
			echo $VERSION
			exit
			;;
		f)
			merge_from_feature=1
			feature=${OPTARG}
			;;
		r)
			run_npm_build=1
			npm_script="npm run $OPTARG > /dev/null 2>&1"
			;;
		c)
			commit_msg=$OPTARG
			;;
		n)
			checkout_after_done=1
			checkout_branch_after_done=$OPTARG
			;;
		t)
			tag=$OPTARG
			;;
		?)
			echo -e "${RED}Invalid command '$OPTARG'. Run with -h to see help${NC}"
			exit
			;;
	esac
done


echo -e "${LIGHT_GREEN}Preparing...$NC"


check_git() {
	which --skip-functions --skip-alias git >/dev/null 2>&1
	if [ $? -eq 1 ]; then
		echo -e "${RED}Git was not found in PATH.\nPlease, firstly install git from https://git-scm.com/downloads${NC}"		
		exit
	fi
}

check_git


if ! git rev-parse --git-dir >/dev/null 2>&1; then
	echo -e "${RED}There is no git repo. Aborting...${NC}"
	exit
fi


my_name=$(basename "$0")

find_gitignore() {
	local path="$(git rev-parse --show-toplevel)"
	echo "${path}/.gitignore"
}

# issue if self (build.sh) is not ignored by git
# firstly check if is ignored, if not -> install
# add to gitignore and commit it
check_ignore_self() {
	git check-ignore $my_name -q >/dev/null 2>&1

	if [ $? -eq 1 ]; then
		if [ -n "$1" ]; then
			print_action 'Performing first run install'
		fi
		gitignore_path="$(find_gitignore)"
		if [ -w $gitignore_path]; then
			echo -e "\n${my_name}" >> $gitignore_path
			
			git add $gitignore_path >/dev/null 2>&1
			git commit -m 'ADDED: ignoring build script' >/dev/null 2>&1
			
			if [ -n "$1" ]; then	
				print_ok
			fi
		fi
	fi
}


print_action() {
	echo -e -n "$1 "
}

print_ok() {
	echo -e " ${LIGHT_GREEN}OK$NC"
}

print_error() {
	echo -e " ${RED}ERROR$NC"
}

print_noclean_tree_msg() {
	echo -e "${RED}You have uncommited files${NC}\n"
	exit
}

verify_clean_working_tree() {
	local valid=0
	if ! git diff --exit-code --quiet; then
		valid=1
	elif ! git diff-index --cached --exit-code --quiet HEAD --; then
		valid=1;
	fi

	if [ $valid -eq 1 ]; then
		print_noclean_tree_msg
	fi
	
	return $valid
}


perform_checkout_with_create() {
	local branch_name=$1

	print_action "Checkouting to branch ${branch_name}"
	if git show-branch $branch_name > /dev/null 2>&1; then
		git checkout $branch_name > /dev/null 2>&1
	else
		git checkout -b $branch_name > /dev/null 2>&1
	fi

	if [ $? -eq 1 ]; then
		print_error
		return 1
	else
		print_ok
		return 0
	fi
}


set_master_tag() {
	if [ "$1" != '' ]; then
		print_action "Creating tag '${tag}'"
		git tag $tag > /dev/null 2>&1
		local result=$? # 128 if tag exists

		if [ $result -eq 0 ]; then
			has_tag=1
			print_ok
			return 0
		else
			print_error

			if [ $result -eq 128 ]; then
				echo -e "${RED}Tag '${tag} already exists$NC"
			fi
		fi
	fi
	return 1
}


# run before verify clean working copy 
# because of first run installation of gitignore
check_ignore_self 1

verify_clean_working_tree
result=$?

if [ $result -eq 0 ]; then
	echo -e "${LIGHT_GREEN}Starting release${NC}"

	if [ $run_npm_build -eq 1 ]; then
		if git show-branch release > /dev/null 2>&1; then
			print_action 'Removing existing release branch'
			git branch -D release > /dev/null 2>&1
			print_ok
		fi
	fi

	if [ $merge_from_feature -eq 1 ]; then
		print_action 'Checkout feature branch'
		git show-branch $feature > /dev/null 2>&1
		# git returns 128 if branch does not exist
		if [ $? -eq 128 ]; then
			print_error
			echo -e "${RED}Feature branch '${feature} does no exists'$NC"
			exit
		fi
		print_ok
		git checkout $feature > /dev/null 2>&1
		check_ignore_self
	fi
	
	git checkout develop > /dev/null 2>&1
	check_ignore_self

	print_action 'Pulling develop'
	git pull origin develop > /dev/null 2>&1
	if [ $? -eq 1 ]; then
		print_error
		echo -e "${RED}\nError occured when pulling from server (possible merge conflicts) - resolve manualy${NC}"
		exit
	fi
	print_ok

	if [ $merge_from_feature -eq 1 ]; then
		print_action 'Merging feature'
		git merge $feature > /dev/null 2>&1
		if [ $? -eq 1 ]; then
			print_error
			echo -e "${RED}\nError occured - possible merge conflicts${NC}"
		fi
		print_ok
	fi
	
	if [ $run_npm_build -eq 1 ]; then
		git checkout -b release > /dev/null 2>&1

		print_action "Running npm script"
		eval $npm_script
		if [ $? -eq 1 ]; then
			print_error
			echo -e "${RED}Error occured when running '$npm_script'$NC"
			exit
		fi

		print_ok

		print_action 'Staging changes from build'
		print_ok
		git add . > /dev/null 2>&1
		commit_cmd="git commit -m '$commit_msg' > /dev/null 2>&1"
		print_action 'Commiting npm build'
		eval $commit_cmd
		print_ok
	fi
	
	
	git checkout master > /dev/null 2>&1
	check_ignore_self
	if [ $? -eq 0 ]; then

		print_action 'Pulling master'
		git pull origin master > /dev/null 2>&1
		if [ $? -eq 1 ]; then
			print_error
			echo -e "${RED}\nError occured when pulling from server (possible merge conflicts) - resolve manualy${NC}"
			exit
		fi
		print_ok

		if [ $run_npm_build -eq 1 ]; then
			print_action 'Merging feature'
			git merge release > /dev/null 2>&1
			if [ $? -eq 1 ]; then
				print_error
				echo -e "${RED}\nError occured - possible merge conflicts${NC}"
				exit
			fi
			print_ok

			git checkout develop > /dev/null 2>&1

			git merge release > /dev/null 2>&1
			if [ $? -eq 0 ]; then
				git branch -D release > /dev/null 2>&1
			else
				echo -e "${RED}\nError occured - possible merge conflicts${NC}"
				exit
			fi
		fi

	else
		echo -e "${RED}\nError occured${NC}"
		exit
	fi

	set_master_tag $tag

	if [ $push -eq 1 ]; then
		print_action "Pushing to master and develop"

		if [ $has_tag -eq 1 ]; then
			git push origin master develop --tags > /dev/null 2>&1
		else
			git push origin master develop > /dev/null 2>&1
		fi


		# git returns 128 if error occured
		if [ $? -eq 128 ]; then
			print_error
			echo -e "${RED}Pushing was not successfully\n\nDone with errors!${NC}"
			exit
		fi
		print_ok
	fi

	if [ $checkout_after_done -eq 1 ]; then
		perform_checkout_with_create $checkout_branch_after_done
	fi


	echo -e "${LIGHT_GREEN}Done!$NC"
fi