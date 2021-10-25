#!/bin/bash

BASE=/opt/harbour
#$HOME/Platform/HB

export HB_ROOT=$BASE
export PATH=$PATH:$BASE/bin

export HB_WITH_SQLITE3=external
export HB_COMPILER=clang
export HB_USER_CFLAGS=-fPIC

echo $BASE

export HB_INC_INSTALL=$BASE/include
export HB_LIB_INSTALL=$BASE/lib
export HB_WITH_QT=/usr/local/opt/qt5/include
export HB_QTPATH=/usr/local/opt/qt5/bin

. scripts/set_envars.sh

HB_DBG=`pwd`
for m in $MODULES
do
    HB_DBG_PATH="$HB_DBG_PATH:$HB_DBG/$m"
done

export HB_DBG_PATH
echo "HB_DBG_PATH="  $HB_DBG_PATH

export PATH=$HB_QTPATH:$PATH

export DYLD_LIBRARY_PATH=.:$HB_LIB_INSTALL

export GT_DEFAULT_TRM=1

export F18_GT_CONSOLE=1
unset  F18_ELECTRON_HOST=1
export F18_DEBUG=1
export F18_POS=1
