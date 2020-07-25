#!/bin/bash

ESHELL_DEV_INSTALLED=`ls -d $HOME/.eShell-dev/extensions/F18/F18-linux-x64-*`

CURRENTDIR=`pwd`

echo F18 installed in eShell: $ESHELL_DEV_INSTALLED

echo "eShell-dev F18 provjera nove verzije iskljuciti !"


PATH=$HOME/.eShell-dev/extensions/F18/$ESHELL_DEV_INSTALLED:$PATH

F18_0_DIR=$HOME/.eShell-dev/extensions/F18/F18_0



if [[ ! -d "${F18_0_DIR}" ]] ; then 
   echo F180DIR=${F18_0_DIR} ne postoji
   mkdir -p ${F18_0_DIR}
   
fi


cp -av F18-klijent ${F18_0_DIR}/F18-klijent


cd $HOME/eShell
scripts/code.sh

#set Token=ESHELL_%RANDOM%

#start "%Token%" cmd /c scripts\code.bat

#:waiteShell
#ping -n 2 localhost >nul 2>nul
#tasklist /fi "WINDOWTITLE eq %Token%" | findstr "cmd" >nul 2>nul && set Child1=1 || set Child1=
#if not defined Child1 goto endloop
#goto waiteShell

#:endloop
#echo eShell-dev died

cd $CURRENTDIR