#!/bin/bash

export LX_RHEL=1

. scripts/linux.sh

. scripts/set_envars.sh

for m in $MODULES
do
    HB_DBG_PATH="$HB_DBG_PATH:$(pwd)/$m"
done

export HB_DBG_PATH
echo "HB_DBG_PATH="  $HB_DBG_PATH

#export GT_DEFAULT_XWC=1
export F18_GT_CONSOLE=1

export F18_POS=1
export F18_DEBUG=1

echo "-------------- F18 envars ---------------------"
set | grep ^F18_

