#!/bin/bash

BINTRAY_API_KEY=${BINTRAY_API_KEY:-`cat bintray_api_key`}
BINTRAY_OWNER=hernad
BINTRAY_REPOS=F18
BINTRAY_PACKAGE=F18-windows-${BINTRAY_ARCH}
BINTRAY_PACKAGE_VER=${BUILD_BUILDNUMBER}
FILE=${BINTRAY_PACKAGE}_${BINTRAY_PACKAGE_VER}.zip

echo "upload: ${BINTRAY_PACKAGE} / ${FILE}"

DLLS="iconv.dll libeay32.dll libiconv-2.dll libiconv2.dll  libintl-2.dll  libintl-8.dll libintl3.dll libpq.dll libssl32.dll ssleay32.dll"

if [ "$BINTRAY_ARCH" == "x64" ] ; then
   MINGW_BASE='mingw64'
else
   MINGW_BASE='mingw32'
   
fi

pacman --noconfirm -S --needed mingw-w64-${MINGW_ARCH}-postgresql mingw-w64-${MINGW_ARCH}-curl mingw-w64-${MINGW_ARCH}-wget

#$ cygcheck ./wget.exe
#C:\msys64\mingw64\bin\wget.exe
#  C:\WINDOWS\system32\KERNEL32.dll
#    C:\WINDOWS\system32\ntdll.dll
#    C:\WINDOWS\system32\KERNELBASE.dll
#  C:\WINDOWS\system32\msvcrt.dll
#  C:\WINDOWS\system32\ole32.dll
#    C:\WINDOWS\system32\RPCRT4.dll
#    C:\WINDOWS\system32\GDI32.dll
#    C:\WINDOWS\system32\USER32.dll
#      C:\WINDOWS\system32\win32u.dll
#    C:\WINDOWS\system32\combase.dll
#      C:\WINDOWS\system32\bcryptPrimitives.dll
#  C:\WINDOWS\system32\WS2_32.dll
#  C:\msys64\mingw64\bin\libcares-2.dll
#    C:\WINDOWS\system32\ADVAPI32.dll
#      C:\WINDOWS\system32\SECHOST.dll
#  C:\msys64\mingw64\bin\LIBEAY32.dll
#  C:\msys64\mingw64\bin\libgpgme-11.dll
#    C:\msys64\mingw64\bin\libwinpthread-1.dll
#    C:\msys64\mingw64\bin\libassuan-0.dll
#      C:\msys64\mingw64\bin\libgpg-error-0.dll
#  C:\msys64\mingw64\bin\libiconv-2.dll
#  C:\msys64\mingw64\bin\libidn2-0.dll
#    C:\msys64\mingw64\bin\libintl-8.dll
#    C:\msys64\mingw64\bin\libunistring-2.dll
#  C:\msys64\mingw64\bin\libmetalink-3.dll
#    C:\msys64\mingw64\bin\libexpat-1.dll
#  C:\msys64\mingw64\bin\libpcre-1.dll
#  C:\msys64\mingw64\bin\SSLEAY32.dll
#  C:\msys64\mingw64\bin\zlib1.dll
#

DLLS+=" wget.exe"
DLLS+=" libcares-2.dll LIBEAY32.dll libgpgme-11.dll libwinpthread-1.dll"
DLLS+=" libassuan-0.dll libgpg-error-0.dll libiconv-2.dll libidn2-0.dll"
DLLS+=" libintl-8.dll libunistring-2.dll libmetalink-3.dll libexpat-1.dll"
DLLS+=" libpcre-1.dll SSLEAY32.dll zlib1.dll"

mkdir zip_loc
mv F18.exe zip_loc/
cd zip_loc
for f in $DLLS ; do
  cp /${MINGW_BASE}/bin/$f .
done
zip -r -v ../$FILE *
unzip -v ../$FILE
cd ..

ls -lh $FILE

CURL=/${MINGW_BASE}/bin/curl

echo uploading $FILE to bintray with $CURL ...

$CURL -s -T $FILE \
      -u $BINTRAY_OWNER:$BINTRAY_API_KEY \
      --header "X-Bintray-Override: 1" \
     https://api.bintray.com/content/$BINTRAY_OWNER/$BINTRAY_REPOS/$BINTRAY_PACKAGE/$BINTRAY_PACKAGE_VER/$FILE

$CURL -s -u $BINTRAY_OWNER:$BINTRAY_API_KEY \
   -X POST https://api.bintray.com/content/$BINTRAY_OWNER/$BINTRAY_REPOS/$BINTRAY_PACKAGE/$BINTRAY_PACKAGE_VER/publish

