#!/bin/bash

usage()
{
  echo "     poziv: $0 <verzija> [--push] "
  echo "       ili: $0 XX --push" 
  echo "koristenje: $0 0.9.38"
}

VER=$1

if [ "$VER" == "XX" ] ; then
  VER=`cat common/f18_ver.ch | grep 'F18_VER  ' | awk -F\" '{ print $2 }'`
fi

if [ "$VER" == "" ] ; then
  echo "verzija nije ispravno utvrdjena !?"
else
  echo "VER=$VER"
fi

if [[ $VER == "" ]]
then  
   usage
   exit 1
fi


WINDOWS=`echo $HB_ARCHITECTURE| grep -c win`
DARWIN=`uname| grep -c Darwin`

#ARCH=`$HOSTTYPE`

if [[ "$WINDOWS" == "1" ]]
then
  TAG_OS="Windows"
  F18_EXE="F18.exe"
else
   F18_EXE="F18"
   ARCH="x86_64"
   BIT32=`strings  ./F18 | grep '\-bit)' | grep -c 32`

   if [[ "$BIT32" == "1" ]] 
   then
      ARCH="i686"
   fi

   if [[ "$DARWIN" == "1" ]]; then
      TAG_OS="MacOSX"
   else
      TAG_OS="Ubuntu_$ARCH"
   fi
fi

gzip -v -cN ${F18_EXE} > F18_${TAG_OS}_${VER}.gz

ls -l F18_${TAG_OS}_${VER}.gz

if [ "$2" == "--push" ]; then
  scripts/push_to_downloads.sh F18_${TAG_OS}_${VER}.gz
fi

