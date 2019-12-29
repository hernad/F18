#!/bin/bash

#HARBOUR_VERSION=20190112.4
echo "bintray arch = $BINTRAY_ARCH"

F18_VERSION=`echo "const json=require('./package.json') ; console.log(json.f18)" | node`
HARBOUR_VERSION=`echo "const json=require('./package.json') ; console.log(json.harbour)" | node`

[ -z "$HARBOUR_VERSION" ] && echo "HARBOUR_VERSION error" && exit 1

echo "F18 linux CI build with $HARBOUR_VERSION"

gcc --version

# https://redmine.bring.out.ba/issues/35387

export HB_PLATFORM=linux
uname -a

if [ "$BUILD_ARCH" == "x86" ] ; then


   # zip unzip

   dpkg -L libpq5:i386
   # /usr/lib/libpq.so.5

   curl -L https://bintray.com/bringout/harbour/download_file?file_path=harbour-linux-x86_${HARBOUR_VERSION}.zip > hb.zip

   #tar xvf hb.tar.gz
   unzip hb.zip -d harbour

   export HB_USER_CFLAGS=-m32
   export HB_USER_DFLAGS='-m32 -L/usr/lib32'
   export HB_USER_LDFLAGS='-m32 -L/usr/lib32'

   export HB_ROOT=$(pwd)/harbour

   #cp -av /usr/lib/i386-linux-gnu/libpq.so .
   #cp -av /usr/lib/i386-linux-gnu/libpq.so linux_32/

   export LD_LIBRARY_PATH=.

else
    #
    curl -L https://bintray.com/bringout/harbour/download_file?file_path=harbour-linux-x64_${HARBOUR_VERSION}.zip > hb.zip
    unzip hb.zip -d harbour

    export HB_ROOT=$(pwd)/harbour
fi

set

PATH=$HB_ROOT/bin:$PATH
echo $PATH

export F18_VER=${BUILD_BUILDNUMBER}
scripts/update_f18_ver_ch.sh $F18_VER $HARBOUR_VERSION

export LX_UBUNTU=1
#source scripts/set_envars.sh

export F18_POS=1
export F18_RNAL=0
export F18_GT_CONSOLE=1

hbmk2 -workdir=.h F18.hbp
