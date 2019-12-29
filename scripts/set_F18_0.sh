#!/bin/bash

BUILD_ARCH=x64

export HARBOUR_ROOT=/home/$USER/ah/$BUILD_ARCH/harbour


cp -av $HARBOUR_ROOT/lib/libpq.so $HOME/F18/F18/F18_0/
cp -av $HARBOUR_ROOT/lib/libssl.so $HOME/F18/F18/F18_0/
cp -av $HARBOUR_ROOT/lib/libcrypto.so $HOME/F18/F18/F18_0/
cp -av F18-klijent $HOME/F18/F18/F18_0/