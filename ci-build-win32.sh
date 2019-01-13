#!/bin/bash

echo "bintray arch = $BINTRAY_ARCH"

HARBOUR_VERSION=`./bintray_get_latest_version.sh harbour harbour-windows-${BINTRAY_ARCH}`

[ -z "$HARBOUR_VERSION" ] && echo "HARBOUR_VERSION error" && exit 1

echo "F18 windows ${BINTRAY_ARCH} CI build with $HARBOUR_VERSION"

# Configure
set

export WIN_DRIVE=$1

pacman --noconfirm -S zip unzip
pacman --noconfirm -S --needed mingw-w64-$MINGW_ARCH-postgresql mingw-w64-$MINGW_ARCH-icu mingw-w64-$MINGW_ARCH-curl mingw-w64-$MINGW_ARCH-openssl
pacman --noconfirm -S --needed mingw-w64-$MINGW_ARCH-curl

# export HB_ARCHITECTURE=win 

# D:\msys64\mingw32\bin\gcc.exe
# cygpath `which gcc` -d
# /mingw64/include/libpq-fe.h


if [ "$HB_COMPILER" == "mingw64" ] ; then
   # PATH=/mingw64/bin:/usr/local/bin:/usr/bin:/bin: ...
   MINGW_BASE='mingw64'
   CURL=/${MINGW_BASE}/bin/curl

   $CURL -L https://bintray.com/hernad/harbour/download_file?file_path=harbour-windows-x64_${HARBOUR_VERSION}.zip > hb.zip   
   
else
   # PATH=/mingw32/bin:/usr/local/bin:/usr/bin:/bin:/c/Windows/System32: ...
   MINGW_BASE='mingw32'
   CURL=/${MINGW_BASE}/bin/curl

   $CURL -L https://bintray.com/hernad/harbour/download_file?file_path=harbour-windows-x86_${HARBOUR_VERSION}.zip > hb.zip   

   export HB_USER_CFLAGS=-m32
   export HB_USER_DFLAGS='-m32 -L/usr/lib32'
   export HB_USER_LDFLAGS='-m32 -L/usr/lib32'
    
fi

unzip hb.zip -d harbour
export HB_ROOT=$(pwd)/harbour

set

PATH=$HB_ROOT/bin:$PATH
echo $PATH

export F18_VER=${BUILD_BUILDNUMBER}
scripts/update_f18_ver_ch.sh $F18_VER

export F18_POS=1
export F18_RNAL=0
export F18_GT_CONSOLE=1

hbmk2 -workdir=.h F18.hbp

#cp -av /usr/lib/i386-linux-gnu/libpq.so .
