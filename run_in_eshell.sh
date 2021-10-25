#!/bin/bash

F18_INSTALLED_ALREADY=`ls -d $HOME/.eShell-dev/extensions/F18/F18-linux-x64-*`

CURRENTDIR=`pwd`

echo F18 installed in eShell: $F18_INSTALLED_ALREADY

echo "eShell-dev F18 provjera nove verzije iskljuciti !"


PATH=$F18_INSTALLED_ALREADY:$PATH
#konflikt sa eShell openssl LD_LIBRARY_PATH=$F18_INSTALLED_ALREADY:$LD_LIBRARY_PATH

F18_0_DIR=$HOME/.eShell-dev/extensions/F18/F18_0

for f in libcrypto.so libcurl.so libpq.so libssl.so libz.so
do
   echo "ln -sf ${F18_INSTALLED_ALREADY}/$f $F18_0_DIR"
   ln -sf ${F18_INSTALLED_ALREADY}/$f $F18_0_DIR
done

ls -l $F18_0_DIR/*.so

if [[ ! -d "${F18_0_DIR}" ]] ; then 
   echo F18_0_DIR=${F18_0_DIR} ne postoji
   mkdir -p ${F18_0_DIR}
   
fi

chmod +w ${F18_0_DIR}/F18-klijent
cp -av F18-klijent ${F18_0_DIR}/F18-klijent


cd ../eShell
LD_LIBRARY_PATH= scripts/code.sh

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
