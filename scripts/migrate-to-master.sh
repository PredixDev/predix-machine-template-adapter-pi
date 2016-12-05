#!/bin/bash
DIR=$(cd $(dirname $0) && pwd)

git checkout master
git merge develop -Xtheirs --no-commit

if [ $(uname) == "Darwin" ]; then
    sed -i "" -e "s/\"develop\"/\"master\"/g" quickstart.sh
else
    sed -i -e "s/\"develop\"/\"master\"/g" quickstart.sh
fi

git add quickstart.sh
git status
if [ -z "$(git status --untracked-files=no --porcelain)" ]; then
    echo "Nothing to merge"
else
    git commit -m "Merge branch 'develop'"
    git push
fi

