#!/bin/bash

git merge --no-ff --no-commit origin/3-vindi

#for f in VERSION VERSION_E VERSION_X script/commit.sh
#do
#      echo "git checkout $f"
#      git checkout origin/3 -- $f 
#done

rm VERSION VERSION_E VERSION_X scripts/commit.sh

git status

