#!/bin/bash


F18_HOST=192.168.124.1
F18_ORG=proba_2018

[ -z "$1" ] && echo "navesti modul" && echo $0 "<modul> <host> <organizacija>" && exit 1
[ -n "$2" ] && F18_HOST=$2
[ -n "$3" ] && F18_ORG=$3

[ -z "$F18_PASSWORD" ] && echo "navesti envar F18_PASSWORD" && exit 1
[ -z "$F18_ADMIN_PASSWORD" ] && echo "navesti envar F18_ADMIN_PASSWORD" && exit 1


export F18_HOME=$(pwd)/data

echo $F18_HOME


/home/hernad/F18_knowhow/F18 2>${1}_1.log --dbf-prefix 1 -h $F18_HOST -y 5432 -ua admin -pa $F18_ADMIN_PASSWORD -u hernad -p $F18_PASSWORD -d $F18_ORG --${1} ${4}

