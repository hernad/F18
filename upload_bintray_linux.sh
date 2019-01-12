#!/bin/bash

# https://github.com/$BINTRAY_OWNER/greenbox/blob/apps_modular/upload_app.sh

cd "$(dirname "$0")"

if [[ ! `which curl` ]] ; then
    sudo apt-get install -y curl
fi

BINTRAY_API_KEY=${BINTRAY_API_KEY:-`cat bintray_api_key`}
BINTRAY_OWNER=hernad
BINTRAY_REPOS=harbour
BINTRAY_PACKAGE=F18-windows-$BINTRAY_ARCH
BINTRAY_PACKAGE_VER=$BUILD_BUILDNUMBER


FILE=${BINTRAY_PACKAGE}_${BINTRAY_PACKAGE_VER}.zip

zip -r -v $FILE F18

ls -lh $FILE

set
echo uploading $FILE to bintray ...

curl -s -T $FILE \
      -u $BINTRAY_OWNER:$BINTRAY_API_KEY \
      --header "X-Bintray-Override: 1" \
     https://api.bintray.com/content/$BINTRAY_OWNER/$BINTRAY_REPOS/$BINTRAY_PACKAGE/$BINTRAY_PACKAGE_VER/$FILE

curl -s -u $BINTRAY_OWNER:$BINTRAY_API_KEY \
   -X POST https://api.bintray.com/content/$BINTRAY_OWNER/$BINTRAY_REPOS/$BINTRAY_PACKAGE/$BINTRAY_PACKAGE_VER/publish

