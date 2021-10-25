#!/bin/bash

BUILD_ARCH=x64
HB_VER=4.8.0
BUILD_ARCH=x64

CURDIR=`pwd`

if [ ! -d $HOME/ah/$BUILD_ARCH ] ; then
     mkdir -p $HOME/ah/$BUILD_ARCH

     cd $HOME/ah/$BUILD_ARCH
     echo `pwd`
     curl -LO https://github.com/hernad/harbour/releases/download/$HB_VER/harbour-linux-$BUILD_ARCH-$HB_VER.tar.gz
     tar xvf harbour-linux-$BUILD_ARCH-$HB_VER.tar.gz
fi

cd $CURDIR


export HARBOUR_ROOT=$HOME/ah/$BUILD_ARCH/harbour
export HB_INSTALL_PREFIX=$HARBOUR_ROOT
export PATH=$HARBOUR_ROOT/bin:$PATH

if [ ! -e $HARBOUR_ROOT/lib/libpq.so.5 ] ; then
    ln -s $HARBOUR_ROOT/lib/libpq.so $HARBOUR_ROOT/lib/libpq.so.5
fi

if [ ! -e $HARBOUR_ROOT/lib/libcrypto.so.1.1 ] ; then
    ln -s $HARBOUR_ROOT/lib/libcrypto.so $HARBOUR_ROOT/lib/libcrypto.so.1.1
fi

if [ ! -e $HARBOUR_ROOT/lib/libssl.so.1.1 ] ; then
    ln -s $HARBOUR_ROOT/lib/libssl.so $HARBOUR_ROOT/lib/libssl.so.1.1
fi

if [ ! -e $HARBOUR_ROOT/lib/libz.so.1 ] ; then
    ln -s $HARBOUR_ROOT/lib/libz.so $HARBOUR_ROOT/lib/libz.so.1
fi


export LD_LIBRARY_PATH=$HARBOUR_ROOT/lib:.

#cp -av $HARBOUR_ROOT/lib/libpq.so $HOME/F18/F18/F18_0/
#cp -av $HARBOUR_ROOT/lib/libssl.so $HOME/F18/F18/F18_0/
#cp -av $HARBOUR_ROOT/lib/libcrypto.so $HOME/F18/F18/F18_0/
#cp -av $HARBOUR_ROOT/lib/libz.so $HOME/F18/F18/F18_0/


echo set debug 
. scripts/set_debug_path.sh

export F18_POS=1
export F18_GT_CONSOLE=1
export F18_DEBUG=1


harbour --version
