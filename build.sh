#!/bin/bash
# Author Jaroslav Kondela
# License MIT 2017 Jaroslav Kondela

# constants
LIGHT_GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No color

VERSION='1.0.0'

push=0
merge_from_feature=0
run_npm_build=0
commit_msg='ADDED: new build'

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
\r\n\nExample:
\r\n${LIGHT_GREEN}./build.sh -p -f feature/checkout -r build$NC
\r\nThis firstly does merge of branch 'feature/checkout' to develop,
\r\nrun 'npm run build'' and push to server
END
)

while getopts ":phf:r:c:v" opt; do
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
		?)
			echo -e "${RED}Invalid command '$OPTARG'. Run with -h to see help${NC}"
			exit
			;;
	esac
done



if ! git rev-parse --git-dir >/dev/null 2>&1; then
	echo -e "${RED}There is no git repo. Aborting...${NC}"
	exit
fi


my_name=$(basename "$0")

# issue if self (build.sh) is not ignored by git
check_ignore_self() {
	git check-ignore $my_name -q >/dev/null 2>&1
	exit
	if [ $? -eq 1 ]; then
		echo -e "${RED}You must add this script to .gitignore because of fatal issues.\n\rIt must be in develop branch and master too.${NC}"
		exit
	fi
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

print_action() {
	echo -e -n "$1 "
}

print_ok() {
	echo -e " ${LIGHT_GREEN}OK$NC"
}

print_error() {
	echo -e " ${RED}ERROR$NC"
}

verify_clean_working_tree
result=$?

if [ $result -eq 0 ]; then
	echo -e "${LIGHT_GREEN}Starting release${NC}"

	if git show-branch release > /dev/null 2>&1; then
		print_action 'Release branch exists... force removing'
		git branch -D release > /dev/null 2>&1
		print_ok
	fi

	if [ $merge_from_feature ]; then
		git show-branch $feature > /dev/null 2>&1
		# git returns 128 if branch does not exist
		if [ $? -eq 128 ]; then
			echo -e "${RED}Feature branch '${feature} does no exists'$NC"
			exit
		fi

		git checkout $feature > /dev/null 2>&1
		check_ignore_self
	fi

	git checkout develop > /dev/null 2>&1
	check_ignore_self
	git pull origin develop > /dev/null 2>&1
	if [ $? -eq 1 ]; then
		echo -e "${RED}\nError occured when pulling from server (possible merge conflicts) - resolve manualy${NC}"
		exit
	fi

	if [ $merge_from_feature ]; then
		git merge $feature > /dev/null 2>&1
		if [ $? -eq 1 ]; then
			echo -e "${RED}\nError occured - possible merge conflicts${NC}"
		fi	
	fi
	
	if [ $run_npm_build ]; then
		git checkout -b release > /dev/null 2>&1

		print_action "Running npm script"
		eval $npm_script
		if [ $? -eq 1 ]; then
			print_error
			echo -e "${RED}Error occured when running '$npm_script'$NC"
			exit
		fi

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

		git pull origin master > /dev/null 2>&1
		if [ $? -eq 1 ]; then
			echo -e "${RED}\nError occured when pulling from server (possible merge conflicts) - resolve manualy${NC}"
			exit
		fi

		if [ $run_npm_build ]; then
			git merge release > /dev/null 2>&1
			if [ $? -eq 1 ]; then
				echo -e "${RED}\nError occured - possible merge conflicts${NC}"
				exit
			fi

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

	if [ $push -eq 1 ]; then
		print_action "Pushing to master and develop"
		git push origin master develop > /dev/null 2>&1

		# git returns 128 if error occured
		if [ $? -eq 128 ]; then
			print_error
			echo -e "${RED}Pushing was not successfully\n\nDone with errors!${NC}"
			exit
		fi
		print_ok
	fi


	echo -e "${LIGHT_GREEN}Done!$NC"
fi