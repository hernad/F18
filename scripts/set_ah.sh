#!/bin/bash

export HARBOUR_ROOT=/home/$USER/ah/x64


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

export LD_LIBRARY_PATH=$HARBOUR_ROOT/lib:.
