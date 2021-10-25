#!/bin/bash

# https://github.com/$BINTRAY_OWNER/greenbox/blob/apps_modular/upload_app.sh


BINTRAY_OWNER=bringout
BINTRAY_REPOS=F18
BUILD_ARCH=x64
F18_PACKAGE=F18-linux-$BUILD_ARCH

RHEL=0
[ -d /etc/redhat-release ] && RHEL=1

if [[ ! `which curl` ]] ; then
    if [ "$RHEL" == "1" ] ; then
        sudo yum -y install -y curl
    else
       sudo apt-get install -y curl
    fi
fi

#F18_VERSION=${BUILD_BUILDNUMBER}
F18_VERSION=`echo "const json=require('./package.json') ; console.log(json.f18)" | node`


FILE=${F18_PACKAGE}_${F18_VERSION}.zip
echo "upload: ${F18_PACKAGE} / ${FILE}"

if [[ -z "$HB_ROOT" ]] ; then
    export HB_ROOT=$(pwd)/harbour
fi

cp -av $HB_ROOT/lib/libssl.so .
cp -av $HB_ROOT/lib/libcrypto.so .
cp -av $HB_ROOT/lib/libpq.so .
cp -av $HB_ROOT/lib/libcurl.so .
cp -av $HB_ROOT/lib/libz.so .
cp -av $HB_ROOT/bin/psql .
cp -av $HB_ROOT/bin/pg_dump .
cp -av $HB_ROOT/bin/pg_restore .
cp -av $HB_ROOT/bin/curl .

ln -s libcrypto.so libcrypto.so.1.1
ln -s libssl.so libssl.so.1.1
ln -s libz.so libz.so.1
ln -s libcurl.so libcurl.so.4 


FILES="F18-klijent libz.so libssl.so libcrypto.so libpq.so libcurl.so psql pg_dump pg_restore curl"

chmod +x F18-klijent
chmod +x psql
chmod +x pg_dump 
chmod +x pg_restore 
chmod +x curl
chmod +x libcurl.so

echo "FILE=$FILE FILES=$FILES"
zip -r -v $FILE $FILES

[ ! -f $FILE ] && exit 1  

ls -lh $FILE

