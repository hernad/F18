#!/bin/bash

MY_BRANCH=origin/3-vindi

git merge --no-ff --no-commit 3

for f in VERSION VERSION_E VERSION_X \
   include/f18.ch \
   kalk/kalk_imp_txt_racuni.prg  \
   kalk/kalk_imp_txt_roba_partn.prg \
   kalk/kalk_mnu_razmjena_podataka.prg
do
      echo "git checkout $MY_BRANCH -- $f"
      git checkout $MY_BRANCH -- $f
done

FILE=scripts/merge_from_3-vindi.sh
[ -f $FILE ] && echo "suvisan $FILE" && rm $FILE

git status

