#!/bin/bash

function count_prgs() {

   NUM=`find $1 -name "*.prg" | grep -c ^$1`
   echo "$1: $NUM"
}

count_prgs common
count_prgs fin
count_prgs kalk
count_prgs fakt
count_prgs pos
count_prgs epdv
count_prgs os
count_prgs ld
count_prgs virm
count_prgs mat
count_prgs kadev


