#!/bin/bash

function usage() {
  echo "primjer: $0 Ubuntu_i686 1.7.750"
  echo "         $0 Windows 1.7.750"
  echo "         $0 MacOSX 1.7.750"
}

[ -z "$1" ] && echo "set envar F18_TYPE argument 1"  && usage && exit 1

F18_TYPE=$1
F18_VER=$2

git pull

if [ -z "$F18_VER" ] ; then
  F18_VER=`cat VERSION | grep "[0-9]\{1,2\}\.[0-9]\{1,2\}\.[0-9]\{1,3\}$"`

fi

scripts/update_f18_ver_ch.sh $F18_VER
[ $? != 0 ] && echo "error git version BUILD ERROR" && exit 1
  
[ -z "$F18_VER" ] && echo "set envar F18_VER argument 2"  && usage && exit 1
date +%d.%m.%Y


echo F18_TYPE=$F18_TYPE, F18_VER=$F18_VER

echo "NAPOMENA: envars su bitne, npr:"
echo "--------------------------------------"
echo "export F18_RNAL=1"
echo "export F18_USE_MATCH_CODE=1"
echo "export F18_FMK=1"
echo "export F18_POS=1"
echo "export POS_PRENOS_POS_KALK=1"


./build.sh --no-rm $F18_VER && scripts/build_gz.sh $F18_VER && scripts/push_to_downloads.sh F18_${F18_TYPE}_${F18_VER}.gz 

