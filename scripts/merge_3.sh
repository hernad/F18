#!/bin/bash

echo "merge from origin/3 (no commit)"

git merge --no-ff --no-commit origin/3

git checkout origin/3 CHANGELOG.md
echo "CHANGELOG.md -> CHANGELOG_MERGE.md (from origin/3 branch)"

cp CHANGELOG.md CHANGELOG_MERGE.md

for f in VERSION VERSION_E VERSION_X script/commit.sh include/f18_ver.ch CHANGELOG.md
do
      echo "git checkout origin/3-std -- $f"
      git checkout origin/3-std -- $f
done

git status

