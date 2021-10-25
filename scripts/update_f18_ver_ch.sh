#!/bin/bash

if [ -n "$1" ] ; then
  F18_VER=$1
else
  F18_VER=`cat VERSION | grep "[0-9]\{1,2\}\.[0-9]\{1,2\}\.[0-9]\{1,3\}$"`
  if [ -z "$F18_VER" ] ; then
     echo "verzija u VERSION ne odgovara konvenciji X.Y.ZZZ"
     exit 1
  fi
fi

F18_DATE=`date +%d.%m.%Y`

if [ -n "$2" ] ; then
   F18_HARBOUR=$2
else
   F18_HARBOUR=`harbour --version | head -1  | sed -e 's/Harbour//'`
fi

#harbour -build

#Harbour 3.4.6hernad (0ed48dfa0b) (2018-04-05 12:24)
#Copyright (c) 1999-2017, https://github.com/hernad/harbour-core/

#Harbour Build Info
#---------------------------
#Version: Harbour 3.4.6hernad (0ed48dfa0b) (2018-04-05 12:24)
#Compiler: GNU C 8.1.1 (64-bit)
#Platform: Linux 4.19.13-200.fc28.x86_64 x86_64
#PCode version: 0.3
#Commit info: 2018-04-05 14:24:36 +0200
#Commit ID: 0ed48dfa0b
#Build options:
#---------------------------

BITS=`harbour -build 2>&1 | grep 'Compiler' | sed -e 's/.*(\(.*\)).*/\1/'`
if [ "$BITS" == '32-bit' ] ; then
   F18_ARCH='32'
else
   F18_ARCH='64'
fi


echo F18_VER=$F18_VER, F18_DATE=$F18_DATE

sed -e "s/___F18_DATE___/$F18_DATE/" \
    -e "s/___F18_VER___/$F18_VER/" \
    -e "s/___F18_HARBOUR___/$F18_HARBOUR/" \
    -e "s/___F18_ARCH___/$F18_ARCH/" \
     f18_ver.template > include/f18_ver.ch

echo include/f18_ver.ch updated
echo ============================
cat  include/f18_ver.ch
