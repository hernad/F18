REM BINTRAY_API_KEY=${BINTRAY_API_KEY:-`cat bintray_api_key`}

set CURRENT_DIR=%~dp0
set BINTRAY_OWNER=bringout
set BINTRAY_REPOS=F18
set BINTRAY_PACKAGE=F18-windows-%BUILD_ARCH%

set BINTRAY_OWNER=bringout
set BINTRAY_REPOS=F18
set BINTRAY_PACKAGE=F18-windows-%BUILD_ARCH%
set CURL=curl.exe


set NODE_PROG=const json=require('./package.json') ; console.log(json.f18)
echo %NODE_PROG% | node > tmpFile
set /p BINTRAY_PACKAGE_VER= < tmpFile
del tmpFile

REM F18-windows-x64_4.20.0.zip
set FILE=%BINTRAY_PACKAGE%_%BINTRAY_PACKAGE_VER%.zip

REM x64
IF [%BUILD_ARCH%] EQU [x64] set HARBOUR_ROOT=\users\%USERNAME%\ah\x64\harbour

REM x86
IF [%BUILD_ARCH%] NEQ [x64] set HARBOUR_ROOT=\users\%USERNAME%\ah\x86\harbour


REM x64
REM IF [%BUILD_ARCH%] EQU  [x64] move .build\win32-x64\user-setup\eShellSetup.exe eShellSetup-x64-%BINTRAY_PACKAGE_VER%.exe

REM x86
REM IF [%BUILD_ARCH%] NEQ  [x64] move .build\win32-ia32\user-setup\eShellSetup.exe eShellSetup-x86-%BINTRAY_PACKAGE_VER%.exe


echo "======================== package: %BINTRAY_PACKAGE% ========== package_ver: %BINTRAY_PACKAGE_VER% =================="

REM set ZIPACMD=\users\%USERNAME%\harbour\tools\win32\7z a -tzip
set FILES=F18-klijent.exe curl.exe psql.exe pg_dump.exe pg_restore.exe libpq.dll zlib1.dll libiconv.dll libxml2.dll

REM x64
IF [%BUILD_ARCH%] EQU [x64] set FILES=%FILES% libcrypto-1_1-x64.dll
IF [%BUILD_ARCH%] EQU [x64] set FILES=%FILES% libssl-1_1-x64.dll

REM x86
IF [%BUILD_ARCH%] NEQ [x64] set FILES=%FILES% libcrypto-1_1.dll
IF [%BUILD_ARCH%] NEQ [x64] set FILES=%FILES% libssl-1_1.dll

mkdir tmp
cd tmp
copy %HARBOR_ROOT%\bin\*.* .
move ..\F18-klijent.exe .
echo copy harbour binaries (exe, dll) to tmp ...
copy /y %HARBOUR_ROOT%\bin\*.* .

echo ZIP=%FILE% FILES=%FILES%
echo CMD=%ZIPACMD% ..\%FILE% %FILES% 

REM %ZIPACMD% ..\%FILE% %FILES%

REM public static void CreateFromDirectory (string sourceDirectoryName, string destinationArchiveFileName);
REM public System.IO.Compression.ZipArchiveEntry CreateEntry (string entryName);

mkdir tmpzip
echo moving files to tmp\tmpzip
powershell -Command "& { \"$ENV:FILES\".split() | foreach { move $_ tmpzip } }" 

echo back from tmp\tmpzip
cd ..\..\

powershell -Command "& {Add-Type -AssemblyName System.IO.Compression.FileSystem ; [System.IO.Compression.ZipFile]:: CreateFromDirectory(\"test.zip\")}"
powershell -Command "& {Add-Type -AssemblyName System.IO.Compression.FileSystem ; [System.IO.Compression.ZipFile]:: CreateFromDirectory(\"$PWD\\tmp\\tmpzip\",\"$ENV:FILE\")}"

echo dir %FILE%
dir  %FILE%

IF NOT EXIST %FILE% EXIT /B 10001

echo uploading %FILE% to bintray ...


%CURL% -s -T %FILE% ^
      -u %BINTRAY_OWNER%:%BINTRAY_API_KEY% ^
      --header "X-Bintray-Override: 1"  ^
	  	--header "X-Bintray-Publish: 1"  ^
     https://api.bintray.com/content/%BINTRAY_OWNER%/%BINTRAY_REPOS%/%BINTRAY_PACKAGE%/%BINTRAY_PACKAGE_VER%/%FILE%

%CURL% -s -u %BINTRAY_OWNER%:%BINTRAY_API_KEY% ^
   -X POST https://api.bintray.com/content/%BINTRAY_OWNER%/%BINTRAY_REPOS%/%BINTRAY_PACKAGE%/%BINTRAY_PACKAGE_VER%/publish
