#!/bin/bash

RHEL=0
[ -d /etc/redhat-release ] && RHEL=1

#HARBOUR_VERSION=20190112.4
echo "bintray arch = $BUILD_ARCH RHEL=$RHEL"

F18_VERSION=`echo "const json=require('./package.json') ; console.log(json.f18)" | node`
HARBOUR_VERSION=`echo "const json=require('./package.json') ; console.log(json.harbour)" | node`

[ -z "$HARBOUR_VERSION" ] && echo "HARBOUR_VERSION error" && exit 1

echo "F18 linux CI build with $HARBOUR_VERSION"

gcc --version

# https://redmine.bring.out.ba/issues/35387

export HB_PLATFORM=linux
uname -a



curl -LO https://github.com/hernad/harbour/releases/download/$HARBOUR_VERSION/harbour-linux-$BUILD_ARCH-$HARBOUR_VERSION.tar.gz
tar xvf harbour-linux-$BUILD_ARCH-$HARBOUR_VERSION.tar.gz

if [ "$BUILD_ARCH" == "x86" ] ; then
   # zip unzip
   dpkg -L libpq5:i386
   # /usr/lib/libpq.so.5

   export HB_USER_CFLAGS=-m32
   export HB_USER_DFLAGS='-m32 -L/usr/lib32'
   export HB_USER_LDFLAGS='-m32 -L/usr/lib32'
   #cp -av /usr/lib/i386-linux-gnu/libpq.so .
   #cp -av /usr/lib/i386-linux-gnu/libpq.so linux_32/
    
fi

export HB_ROOT=$(pwd)/harbour
export LD_LIBRARY_PATH=$HB_ROOT/lib


set

PATH=$HB_ROOT/bin:$PATH
echo $PATH

scripts/update_f18_ver_ch.sh $F18_VERSION $HARBOUR_VERSION

#export LX_UBUNTU=1
#source scripts/set_envars.sh

export F18_POS=1
export F18_RNAL=0
export F18_GT_CONSOLE=1

hbmk2 -workdir=.h F18.hbp
