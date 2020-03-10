#!/bin/bash

HB_DBG=`pwd`

HB_DBG_PATH=$HB_DBG:$HB_DBG/common:$HB_DBG/pos:$HB_DBG/kalk:$HB_DBG/fin:$HB_DBG/fakt:$HB_DBG/os:$HB_DBG/ld:/$HB_DBG/epdv:$HB_DBG/virm:$HB_DBG/core
HB_DBG_PATH=$HB_DBG_PATH:$HB_DBG/core_pdf
HB_DBG_PATH=$HB_DBG_PATH:$HB_DBG/core_sql
HB_DBG_PATH=$HB_DBG_PATH:$HB_DBG/core_semafori
HB_DBG_PATH=$HB_DBG_PATH:$HB_DBG/fiskalizacija

export HB_DBG_PATH

echo "HB_DBG_PATH="  $HB_DBG_PATH
