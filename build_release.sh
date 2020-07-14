#!/bin/bash

unset F18_DEBUG
export F18_POS=1
export F18_GT_CONSOLE=1

NODE_PROG="const json=require('./package.json') ; console.log(json.f18)"
F18_VERSION=`echo $NODE_PROG | node`


#get F18 date from package.json
NODE_PROG="const json=require('./package.json') ; console.log(json.f18_date)"
F18_DATE=`echo $NODE_PROG | node`


#get harbour version from package.json
NODE_PROG="const json=require('./package.json') ; console.log(json.harbour)"
HARBOUR_VERSION=`echo $NODE_PROG | node`


# get harbour date from package.json
NODE_PROG="const json=require('./package.json') ; console.log(json.harbour_date)"
HARBOUR_DATE=`echo $NODE_PROG | node`

#get architecture x64, x32
NODE_PROG="console.log( process.arch === 'x64' ? '64' : '32');"
BUILD_ARCH=`echo $NODE_PROG | node`


echo $BUILD_ARCH, $F18_VERSION, $F18_DATE, $HARBOUR_VERSION, $HARBOUR_DATE

LINE="#define F18_VER_DEFINED"
echo $LINE > include/f18_ver.ch

LINE="#define F18_VER       \"$F18_VERSION\""
echo $LINE >> include/f18_ver.ch

LINE="#define F18_VER_DATE  \"$F18_DATE\""
echo $LINE >> include/f18_ver.ch

LINE="#define F18_DEV_PERIOD  \"1994-2020\""
echo $LINE >> include/f18_ver.ch

LINE="#define F18_HARBOUR  \"$HARBOUR_VERSION\""
echo $LINE >> include/f18_ver.ch

LINE="#define F18_ARCH   \"$BUILD_ARCH\""
echo $LINE >> include/f18_ver.ch

LINE="#define F18_TEMPLATE_VER \"3.1.0\""
echo $LINE >> include/f18_ver.ch

LINE="#define F18_DBF_VER_MAJOR  2"
echo $LINE >> include/f18_ver.ch

LINE="#define F18_DBF_VER_MINOR  1"
echo $LINE >> include/f18_ver.ch

LINE="#define F18_DBF_VER_PATCH  6"
echo $LINE >> include/f18_ver.ch

LINE="#define SERVER_DB_VER  0"
echo $LINE >> include/f18_ver.ch

echo ===========f18_ver====================================
cat include/f18_ver.ch
echo ======================================================

echo -------------------- clean ...
hbmk2 F18 -clean
echo -------------------- build ...
hbmk2 F18 -trace-
