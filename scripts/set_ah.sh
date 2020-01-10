#!/bin/bash

BUILD_ARCH=x64

export HARBOUR_ROOT=/home/$USER/ah/$BUILD_ARCH/harbour

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

cp -av $HARBOUR_ROOT/lib/libpq.so $HOME/F18/F18/F18_0/
cp -av $HARBOUR_ROOT/lib/libssl.so $HOME/F18/F18/F18_0/
cp -av $HARBOUR_ROOT/lib/libcrypto.so $HOME/F18/F18/F18_0/
cp -av $HARBOUR_ROOT/lib/libz.so $HOME/F18/F18/F18_0/


export F18_POS=1
export F18_GT_CONSOLE=1
export F18_DEBUG=1

