#!/bin/bash

export LX_UBUNTU=1

. scripts/linux.sh

. scripts/set_envars.sh

for m in $MODULES
do
    HB_DBG_PATH="$HB_DBG_PATH:$HB_DBG/$m"
done

export HB_DBG_PATH
echo "HB_DBG_PATH="  $HB_DBG_PATH

export GT_DEFAULT_XWC=1
