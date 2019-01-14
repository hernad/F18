#!/bin/bash

BINTRAY_API_KEY=${BINTRAY_API_KEY:-`cat bintray_api_key`}
BINTRAY_OWNER=hernad
BINTRAY_REPOS=F18
BINTRAY_PACKAGE=F18-windows-${BINTRAY_ARCH}
BINTRAY_PACKAGE_VER=${BUILD_BUILDNUMBER}
FILE=${BINTRAY_PACKAGE}_${BINTRAY_PACKAGE_VER}.zip

echo "upload: ${BINTRAY_PACKAGE} / ${FILE}"

DLLS="libeay32.dll libiconv-2.dll libintl-8.dll libpq.dll libssl32.dll"

if [ "$BINTRAY_ARCH" == "x64" ] ; then
   MINGW_BASE='mingw64'
   DLLS+=" libssl-1_1-x64.dll libcrypto-1_1-x64.dll"
   DLLS+=" libgcc_s_seh-1.dll"
   
else
   MINGW_BASE='mingw32'
   DLLS+=" libssl-1_1.dll libcrypto-1_1.dll"
   DLLS+=" libgcc_s_dw2-1.dll"
fi

pacman --noconfirm -S --needed mingw-w64-${MINGW_ARCH}-postgresql mingw-w64-${MINGW_ARCH}-openssl mingw-w64-${MINGW_ARCH}-gettext  mingw-w64-${MINGW_ARCH}-icu mingw-w64-${MINGW_ARCH}-curl mingw-w64-${MINGW_ARCH}-wget


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


#C:\msys64\mingw64\bin\psql.exe
#  C:\msys64\mingw64\bin\LIBPQ.dll
#    C:\WINDOWS\system32\ADVAPI32.dll
#      C:\WINDOWS\system32\msvcrt.dll
#        C:\WINDOWS\system32\ntdll.dll
#        C:\WINDOWS\system32\KERNELBASE.dll
#      C:\WINDOWS\system32\SECHOST.dll
#        C:\WINDOWS\system32\RPCRT4.dll
#      C:\WINDOWS\system32\KERNEL32.dll
#    C:\WINDOWS\system32\Secur32.dll
#    C:\WINDOWS\system32\SHELL32.dll
#      C:\WINDOWS\system32\USER32.dll
#        C:\WINDOWS\system32\win32u.dll
#        C:\WINDOWS\system32\GDI32.dll
#    C:\WINDOWS\system32\WLDAP32.dll
#    C:\WINDOWS\system32\WS2_32.dll
#    C:\msys64\mingw64\bin\LIBEAY32.dll
#    C:\msys64\mingw64\bin\libintl-8.dll
#      C:\msys64\mingw64\bin\libiconv-2.dll
#    C:\msys64\mingw64\bin\SSLEAY32.dll
#    C:\msys64\mingw64\bin\libxml2-2.dll
#      C:\msys64\mingw64\bin\liblzma-5.dll
#      C:\msys64\mingw64\bin\zlib1.dll

#$ pacman -Fys psql.exe
#:: Synchronizing package databases...
# mingw32 is up to date
# mingw64 is up to date
# msys is up to date
#mingw32/mingw-w64-i686-postgresql 11.1-1
#    mingw32/bin/psql.exe
#mingw64/mingw-w64-x86_64-postgresql 11.1-1
#    mingw64/bin/psql.exe

#$ pacman -Fys libcrypto-1_1-x64.dll
#:: Synchronizing package databases...
# mingw32 is up to date
# mingw64 is up to date
# msys is up to date
#mingw64/mingw-w64-x86_64-openssl 1.1.1.a-1
#    mingw64/bin/libcrypto-1_1-x64.dll



#hernad@DESKTOP-0HRJEDF MINGW64 /mingw64
#$ pacman -Ql mingw-w64-$MINGW_ARCH-openssl | grep dll
#mingw-w64-x86_64-openssl /mingw64/bin/libeay32.dll
#mingw-w64-x86_64-openssl /mingw64/bin/ssleay32.dll
#mingw-w64-x86_64-openssl /mingw64/lib/engines/4758ccaeay32.dll
#mingw-w64-x86_64-openssl /mingw64/lib/engines/aepeay32.dll
#mingw-w64-x86_64-openssl /mingw64/lib/engines/atallaeay32.dll
#mingw-w64-x86_64-openssl /mingw64/lib/engines/capieay32.dll
#mingw-w64-x86_64-openssl /mingw64/lib/engines/chileay32.dll
#mingw-w64-x86_64-openssl /mingw64/lib/engines/cswifteay32.dll
#mingw-w64-x86_64-openssl /mingw64/lib/engines/gmpeay32.dll
#mingw-w64-x86_64-openssl /mingw64/lib/engines/gosteay32.dll
#mingw-w64-x86_64-openssl /mingw64/lib/engines/nuroneay32.dll
#mingw-w64-x86_64-openssl /mingw64/lib/engines/padlockeay32.dll
#mingw-w64-x86_64-openssl /mingw64/lib/engines/surewareeay32.dll
#mingw-w64-x86_64-openssl /mingw64/lib/engines/ubseceay32.dll
#mingw-w64-x86_64-openssl /mingw64/lib/libcrypto.dll.a
#mingw-w64-x86_64-openssl /mingw64/lib/libssl.dll.a



echo "=========== cygcheck /${MINGW_BASE}/bin/wget.exe ==============="
cygcheck /${MINGW_BASE}/bin/wget.exe

echo "=========== cygcheck /${MINGW_BASE}/bin/psql.exe ==============="
cygcheck /${MINGW_BASE}/bin/psql.exe


echo "========== openssl ===================="
pacman -Qi mingw-w64-$MINGW_ARCH-openssl

pacman -Ql mingw-w64-$MINGW_ARCH-openssl
echo "======================================="

DLLS+=" wget.exe"
DLLS+=" libpsl-5.dll libcares-3.dll libgpgme-11.dll libwinpthread-1.dll"
DLLS+=" libassuan-0.dll libgpg-error-0.dll libiconv-2.dll libidn2-4.dll"
DLLS+=" libintl-8.dll libunistring-2.dll libmetalink-3.dll libexpat-1.dll"
DLLS+=" libpcre2-8-0.dll zlib1.dll"


DLLS+=" pg_dump.exe pg_restore.exe psql.exe libxml2-2.dll liblzma-5.dll"


echo "=================== /${MINGW_BASE}/bin ==============="
find /${MINGW_BASE}/bin


echo "======================== copy - zip files =============================="
mkdir -p zip_loc/bin
mkdir -p zip_loc/etc
#mkdir -p zip_loc/share

mv F18.exe zip_loc/
cd zip_loc
for f in $DLLS ; do
  if ! cp /${MINGW_BASE}/bin/$f bin/ ; then
    echo "ERROR pri formiranju zip arhive - file not found: /${MINGW_BASE}/bin/$f" 
    exit 1
  fi
done
cp -av /${MINGW_BASE}/etc/pki etc/
cp -av /${MINGW_BASE}/ssl ssl/
#cp -av /${MINGW_BASE}/share/ca-* share/

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

