#!/bin/bash


BINTRAY_SUBJECT=hernad
BINTRAY_REPOS=$1
BINTRAY_PACKAGE=$2

VERSION=$(curl --silent -I https://bintray.com/${BINTRAY_SUBJECT}/${BINTRAY_REPOS}/${BINTRAY_PACKAGE}/_latestVersion | grep "Location:")

#echo $VERSION
VERSION=$(echo $VERSION | sed -n 's/.*'"${BINTRAY_PACKAGE}"'\/\(.*\)$/\1/p' | tr -d '/' | tr -d '\r')
#echo "v2: $VERSION"

#HTTP/1.1 302 Found
#Server: nginx
#Date: Fri, 11 Jan 2019 15:38:41 GMT
#Content-Length: 0
#Connection: keep-alive
#Location: https://bintray.com/hernad/harbour/harbour-windows-x64/20190111.12
#X-Frame-Options: SAMEORIGIN
#Strict-Transport-Security: max-age=31536000; preload


#echo "downloading https://dl.bintray.com/${BINTRAY_SUBJECT}/${BINTRAY_REPOS}/${BINTRAY_PACKAGE}_${VERSION}.zip > ${BINTRAY_PACKAGE}_latest.zip"
#curl -L "https://dl.bintray.com/${BINTRAY_SUBJECT}/${BINTRAY_REPOS}/${BINTRAY_PACKAGE}_${VERSION}.zip" -o ${BINTRAY_PACKAGE}_latest.zip

echo $VERSION
