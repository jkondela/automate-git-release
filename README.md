# Automate GIT release
[![License](https://img.shields.io/badge/license-MIT-brightgreen.svg)](https://opensource.org/licenses/MIT) [![GitHub release](https://img.shields.io/github/release/jkondela/automate-git-release.svg)]() [![GitHub issues](https://img.shields.io/github/issues/jkondela/automate-git-release.svg)](https://github.com/jkondela/automate-git-release/issues)

Automate daily git release based on [Gitflow workflow](http://nvie.com/posts/a-successful-git-branching-model/).
It merges feature branch to develop, pulls changes, creates middle branch for release, runs npm script for building, auto commits changes, merges to develop/master and pushes to remote.

Why? For saving time and instantly releases.

### Installation
Copy ``build.sh`` to your project, make it executable with running
```sh
$ chmod +x build.sh
```
If you want to run custom npm script, it must be in directory where is package.json defined or in child directory where is available npm run.
There is no need to add script to your ``.gitignore`` because with first run it will automatically add to gitignore on each branch.


### Usage
```sh
$ ./build.sh -p -t v1.4.0 -f {BRANCH_NAME} -r build
```
See below for explain each command.


### Commands

```sh
$ ./build.sh -v
$ 1.2.2
```

```sh
$ ./build.sh -h # help command
```

```sh
$ ./build.sh -p # for push master/develop to remote
```

```sh
$ ./build.sh -f [branch-name] # for merge feature branch to develop
```

```sh
$ ./build.sh -r [npm-script-name] #  script name from npm scripts for run (example: -r build = npm run build)
```

```sh
$ ./build.sh -c 'ADDED: new webpack build' # message for commit if release branch is active (runnable only with -r command)
```
Default commit message: ``ADDED: new build``

```sh
$ ./build.sh -n [branch-name] 
# after successful build checkout to [branch-name]
# if does not exist, it will be firstly created
```

```sh
$ ./build.sh -t [tag] # creates lightweight tag on master and push it to remote
```


### Contributing
Create [new issue](https://github.com/jkondela/automate-git-release/issues/new).

### License
MIT

