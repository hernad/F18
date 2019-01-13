#!/bin/bash

BINTRAY_API_KEY=${BINTRAY_API_KEY:-`cat bintray_api_key`}
BINTRAY_OWNER=hernad
BINTRAY_REPOS=F18
BINTRAY_PACKAGE=F18-windows-${BINTRAY_ARCH}
BINTRAY_PACKAGE_VER=${BUILD_BUILDNUMBER}
FILE=${BINTRAY_PACKAGE}_${BINTRAY_PACKAGE_VER}.zip

echo "upload: ${BINTRAY_PACKAGE} / ${FILE}"

zip -r -v $FILE F18.exe

ls -lh $FILE

set
if [ "$BINTRAY_ARCH" == "x64" ] ; then
   MINGW_BASE='mingw64'
else
   MINGW_BASE='mingw32' 
fi
pacman --noconfirm -S --needed mingw-w64-${MINGW_ARCH}-curl
CURL=/${MINGW_BASE}/bin/curl

echo uploading $FILE to bintray with $CURL ...

$CURL -s -T $FILE \
      -u $BINTRAY_OWNER:$BINTRAY_API_KEY \
      --header "X-Bintray-Override: 1" \
     https://api.bintray.com/content/$BINTRAY_OWNER/$BINTRAY_REPOS/$BINTRAY_PACKAGE/$BINTRAY_PACKAGE_VER/$FILE

$CURL -s -u $BINTRAY_OWNER:$BINTRAY_API_KEY \
   -X POST https://api.bintray.com/content/$BINTRAY_OWNER/$BINTRAY_REPOS/$BINTRAY_PACKAGE/$BINTRAY_PACKAGE_VER/publish

