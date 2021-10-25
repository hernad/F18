#!/bin/bash

echo "linux setup"


#export QT_VER=5.5.1
#export QT_ROOT=/usr/local/Qt

export HB_COMPILER=gcc

unset HB_INSTALL_PREFIX
#export HB_INC_INSTALL=/usr/local
#export HB_LIB_INSTALL=/usr/local/lib/harbour

export INCLUDE=$HB_INC_INSTALL

LX_64=`uname -a | grep -c x86_64`

if [ "$LX_64" == "1" ] ; then
   export LX_64=1
else
   unset LX_64 
fi

export HB_USER_CFLAGS=-fPIC

if [ "$LX_64" == "1" ] ; then
   gcc_qt=gcc_64
else
   gcc_qt=gcc
fi

#echo $QT_ROOT
#if [ -f "$QT_ROOT/$qcc_qt" ] 
#then
#   export QT_ROOT=$QT_ROOT/$gcc_qt
#   echo "Qt: $QT_ROOT"
#fi

#export PGSQL_ROOT=$HOME/F18_knowhow/pgsql

#export PATH=$QT_ROOT/bin:$HB_ROOT/bin:$PATH
#export HB_WITH_QT=$QT_ROOT/include
#export HB_WITH_PGSQL=$PGSQL_ROOT/include

#export LD_LIBRARY_PATH=$QT_ROOT/lib:$HB_ROOT/lib:$PGSQL_ROOT/lib

#export QT_PLUGIN_PATH=$QT_ROOT/plugins

export GT_DEFAULT_XCW=1

#HB_DBG=`pwd`
