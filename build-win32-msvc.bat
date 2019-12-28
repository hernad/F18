
set CURRENT_DIR=%~dp0
set HARBOUR_REPOS_GIT=\users\%USERNAME%\harbour

echo "bintray arch = %BINTRAY_ARCH%, PATH= %PATH%"


REM HARBOUR_VERSION=`./bintray_get_latest_version.sh harbour harbour-windows-${BINTRAY_ARCH}`
set NODE_PROG=const json=require('./package.json') ; console.log(json.harbour)
echo %NODE_PROG% | node > tmpFile
set /p HARBOUR_VERSION= < tmpFile
del tmpFile
set NODE_PROG=const json=require('./package.json') ; console.log(json.harbour_date)
echo %NODE_PROG% | node > tmpFile
set /p HARBOUR_DATE= < tmpFile
del tmpFile


REM F18_VERSION
set NODE_PROG=const json=require('./package.json') ; console.log(json.f18)
echo %NODE_PROG% | node > tmpFile
set /p F18_VERSION= < tmpFile
del tmpFile
REM F18_DATE
set NODE_PROG=const json=require('./package.json') ; console.log(json.f18_date)
echo %NODE_PROG% | node > tmpFile
set /p F18_DATE= < tmpFile
del tmpFile

echo "Harbour repos git=%HARBOUR_REPOS_GIT%"
echo "F18 windows %BINTRAY_ARCH% CI build with %HARBOUR_VERSION%

set WINSDK_VER=10.0.18362.0

cd %HARBOUR_REPOS_GIT%
REM x64
IF [%BINTRAY_ARCH%] EQU [x64] set VCBUILDTOOLS=amd64
IF [%BINTRAY_ARCH%] EQU [x64] set HARBOUR_BINARIES_ROOT=\users\%USERNAME%\ah\x64\harbour
IF [%BINTRAY_ARCH%] EQU [x64] set HB_COMPILER=msvc64

REM x86
IF [%BINTRAY_ARCH%] NEQ [x64] set VCBUILDTOOLS=x86
IF [%BINTRAY_ARCH%] NEQ [x64] set HARBOUR_BINARIES_ROOT=\users\%USERNAME%\ah\x86\harbour
IF [%BINTRAY_ARCH%] NEQ [x64] set HB_COMPILER=msvc

set VCBUILDTOOLS_PATH="C:\Program Files (x86)\Microsoft Visual C++ Build Tools\vcbuildtools.bat"    
set LIB_BIN_ROOT=%ROOT_DIR%\3rd\%BUILD_ARCH%

echo set-up vc build tools ......................
call %VCBUILDTOOLS_PATH% %VCBUILDTOOLS%
set PATH=%HB_INSTALL_PREFIX%\bin;%PATH%

set HB_INSTALL_PREFIX=%HARBOUR_BINARIES_ROOT%
set PATH=%HARBOUR_BINARIES_ROOT%\bin;%PATH%
set PATH=%PATH%;C:\Program Files (x86)\Windows Kits\10\bin\%WINSDK_VER%\%BUILD_ARCH%

echo --- PATH=%PATH% ----------------------
echo --- HB_INSTALL_PREFIX=%HB_INSTALL_PREFIX% --------------------
cl

echo ====== skip to current_dir=%CURRENT_DIR% ================================
cd %CURRENT_DIR%

set LINE=#define F18_VER_DEFINED
echo %LINE% > include\f18_ver.ch

set LINE=#define F18_VER       "%F18_VERSION%"
echo %LINE% >> include\f18_ver.ch

set LINE=#define F18_VER_DATE  "%F18_DATE%"
echo %LINE% >> include\f18_ver.ch

set LINE=#define F18_DEV_PERIOD  "1994-2020"
echo %LINE% >> include\f18_ver.ch

set LINE=#define F18_HARBOUR   "%HARBOUR_VERSION%"
echo %LINE% >> include\f18_ver.ch

set LINE=#define F18_ARCH   "%BINTRAY_ARCH%"
echo %LINE% >> include\f18_ver.ch

set LINE=#define F18_TEMPLATE_VER "3.1.0"
echo %LINE% >> include\f18_ver.ch

set LINE=#define F18_DBF_VER_MAJOR  2
echo %LINE% >> include\f18_ver.ch

set LINE=#define F18_DBF_VER_MINOR  1
echo %LINE% >> include\f18_ver.ch

set LINE=#define F18_DBF_VER_PATCH  6
echo %LINE% >> include\f18_ver.ch

set LINE=#define SERVER_DB_VER  0
echo %LINE% >> include\f18_ver.ch

echo ===========f18_ver====================================
type include\f18_ver.ch
echo ======================================================


set F18_POS=1
set F18_RNAL=0
set F18_GT_CONSOLE=1
set F18_DEBUG=

hbmk2 -workdir=.h F18.hbp -clean
hbmk2 -workdir=.h F18.hbp

IF NOT EXIST F18-klijent.exe EXIT /B 10001
