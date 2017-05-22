# Automate GIT release
[![License](https://img.shields.io/badge/license-MIT-brightgreen.svg)](https://opensource.org/licenses/MIT) ![Version: 1.0.0](https://img.shields.io/badge/version-1.0.0-brightgreen.svg) [![GitHub issues](https://img.shields.io/github/issues/jkondela/automate-git-release.svg)](https://github.com/jkondela/automate-git-release/issues)

Automate daily git release based on [Gitflow workflow](http://nvie.com/posts/a-successful-git-branching-model/).
It merges feature branch to develop, pulls changes, creates middle branch for release, runs npm script for building, auto commits changes, merges to develop/master and pushes to remote.

Why? For saving time and instantly releases.

### Installation
Copy ``build.sh`` to your project, make it executable with running
```sh
$ chmod +x build.sh
```
If you can run custom npm script, it must be in directory where is package.json defined.
**Warning:** Before running a script, you must add script to your .gitignore in both branches (master/develop).

### Usage
```sh
$ ./build.sh -p -f {BRANCH_NAME} -r build
```
See below for explain each command.


### Commands

```sh
$ ./build.sh -v
$ 1.0.0
```

```sh
$ ./build.sh -h # help command
```

```sh
$ ./build.sh -p # for push master/develop to remote
```

```sh
$ ./build.sh -f feature/checkout # for merge feature branch to develop
```

```sh
$ ./build.sh -r build #  script name from npm scripts for run (example: build = npm run build)
```

```sh
$ ./build.sh -c 'ADDED: new webpack build' # message for commit if release branch is active (runnable only with -r command)
```
Default commit message: ``ADDED: new build``

### Contributing
Create [new issue](https://github.com/jkondela/automate-git-release/issues/new).

### License
MIT

