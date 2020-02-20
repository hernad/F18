#!/bin/bash

BUILD_ARCH=x64

export HARBOUR_ROOT=/home/$USER/ah/$BUILD_ARCH/harbour

#DEST=$HOME/F18/F18/F18_0/
DEST=$HOME/.eShell/extensions/F18/F18_0/

cp -av $HARBOUR_ROOT/lib/libpq.so  $DEST 
cp -av $HARBOUR_ROOT/lib/libssl.so $DEST
cp -av $HARBOUR_ROOT/lib/libcrypto.so $DEST
cp -av F18-klijent $DEST
