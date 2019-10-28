#!/bin/bash

#echo "bintray arch = $BINTRAY_ARCH, PATH= $PATH"

#HARBOUR_VERSION=`./bintray_get_latest_version.sh harbour harbour-windows-${BINTRAY_ARCH}`

#[ -z "$HARBOUR_VERSION" ] && echo "HARBOUR_VERSION error" && exit 1

#echo "F18 windows ${BINTRAY_ARCH} CI build with $HARBOUR_VERSION"

# Configure
set

export WIN_DRIVE=$1

#pacman --noconfirm -S zip unzip
#pacman --noconfirm -S --needed mingw-w64-$MINGW_ARCH-postgresql mingw-w64-$MINGW_ARCH-icu mingw-w64-$MINGW_ARCH-curl mingw-w64-$MINGW_ARCH-openssl
#pacman --noconfirm -S --needed mingw-w64-$MINGW_ARCH-curl


MINGW_BASE='mingw64'

if [ "$HB_COMPILER" == "mingw64" ] && [ ! -d harbour ]; then
   # PATH=/mingw64/bin:/usr/local/bin:/usr/bin:/bin: ...
   MINGW_BASE='mingw64'
   CURL=/${MINGW_BASE}/bin/curl

   $CURL -L https://bintray.com/bringout/harbour/download_file?file_path=harbour-windows-x64_${HARBOUR_VERSION}.zip > hb.zip

fi

if [ ! -d harbour ] ; then
   unzip hb.zip -d harbour
fi

export HB_ROOT=$(pwd)/harbour

set

export MINGW_INCLUDE=$WIN_DRIVE:\\\\msys64\\\\${MINGW_BASE}\\\\include
export HB_WITH_CURL=${MINGW_INCLUDE} HB_WITH_OPENSSL=${MINGW_INCLUDE} HB_WITH_PGSQL=${MINGW_INCLUDE} HB_WITH_ICU=${MINGW_INCLUDE}

PATH=$HB_ROOT/bin:/${MINGW_BASE}/bin:$PATH
echo $PATH

export F18_VER=${BUILD_BUILDNUMBER}
scripts/update_f18_ver_ch.sh $F18_VER $HARBOUR_VERSION

export F18_POS=1
export F18_RNAL=0
export F18_GT_CONSOLE=1

#gcc --version

hbmk2 -workdir=.h F18.hbp
