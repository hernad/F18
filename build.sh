#!/bin/bash

#if [ "$HB_INC_INSTALL" == "" ]; then
#    echo "setuj envars"
#    exit -1
#fi

if [ "$1" != "--no-rm" ] ; then
   rm -r -f .h
fi

F18_VER=$2

unset F18_DEBUG
unset F18_DEBUG_BROWSE_SIF
unset F18_DEBUG_FIN_AZUR
unset F18_DEBUG_THREAD
unset F18_DEBUG_SYNC
unset F18_DEBUG_SQL

if [ -n "$F18_VER" ] ; then
 scripts/update_f18_ver_ch.sh $F18_VER
 [ $? != 0 ] && echo "error git version BUILD ERROR" && exit 1
fi

hbmk2 -workdir=.h F18.hbp
