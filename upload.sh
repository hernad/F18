#!/bin/bash

CURRENT_DIR=`pwd`
export BUILD_ARCH=x64


if [ -d tmp ] ; then
  rm -rf tmp
fi

if [ ! -f $HOME/.bintray_owner ]; then
   echo potreban fajl $HOME/.bintray_owner
   exit 1
fi

if [ ! -f $HOME/.bintray_api_key ]; then
   echo potreban fajl $HOME/.bintray_api_key
   exit 1
fi



export BINTRAY_OWNER=`cat $HOME/.bintray_owner`
export BINTRAY_API_KEY=`cat $HOME/.bintray_api_key`

export HB_ROOT=$HOME/harbour

echo "$HB_ROOT, bintray: $BINTRAY_OWNER, $BINTRAY_API_KEY"

#read

./upload_bintray_linux.sh


echo delete $CURRENT_DIR/tmp ...
rm -rf $CURRENT_DIR/tmp
