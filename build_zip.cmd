@echo off


REM get architecture x64, x32
set NODE_PROG=console.log( process.arch === "x64" ? "x64" : "x86");
echo %NODE_PROG% | node > tmpFile
set /p BUILD_ARCH= < tmpFile
del tmpFile

set CURRENT_DIR=%~dp0

set F18_PACKAGE=F18-windows-%BUILD_ARCH%

set F18_PACKAGE=F18-windows-%BUILD_ARCH%
set CURL=curl.exe


set NODE_PROG=const json=require('./package.json') ; console.log(json.f18)
echo %NODE_PROG% | node > tmpFile
set /p F18_VERSION= < tmpFile
del tmpFile

REM F18-windows-x64_4.20.0.zip
set ZIP_FILE=%F18_PACKAGE%_%F18_VERSION%.zip

set HARBOUR_ROOT=c:\dev\harbour\%BUILD_ARCH%\harbour

if [%HARBOUR_ROOT%] EQU [] (
  REM x64
  IF [%BUILD_ARCH%] EQU [x64] set HARBOUR_ROOT=\users\%USERNAME%\ah\%BUILD_ARCH%\harbour

  REM x86
  IF [%BUILD_ARCH%] NEQ [x64] set HARBOUR_ROOT=\users\%USERNAME%\ah\%BUILD_ARCH%\harbour
)

echo ==== HARBOUR_ROOT=%HARBOUR_ROOT% ====

REM x64
REM IF [%BUILD_ARCH%] EQU  [x64] move .build\win32-x64\user-setup\eShellSetup.exe eShellSetup-x64-%F18_VERSION%.exe

REM x86
REM IF [%BUILD_ARCH%] NEQ  [x64] move .build\win32-ia32\user-setup\eShellSetup.exe eShellSetup-x86-%F18_VERSION%.exe


echo "============ package: %F18_PACKAGE% ======= package_ver: %F18_VERSION% ============="

REM set ZIPACMD=\users\%USERNAME%\harbour\tools\win32\7z a -tzip
set FILES=F18-klijent.exe curl.exe psql.exe pg_dump.exe pg_restore.exe libpq.dll zlib1.dll libiconv.dll libxml2.dll

REM x64
IF [%BUILD_ARCH%] EQU [x64] set FILES=%FILES% libcrypto-1_1-x64.dll
IF [%BUILD_ARCH%] EQU [x64] set FILES=%FILES% libssl-1_1-x64.dll

REM x86
IF [%BUILD_ARCH%] NEQ [x64] set FILES=%FILES% libcrypto-1_1.dll
IF [%BUILD_ARCH%] NEQ [x64] set FILES=%FILES% libssl-1_1.dll


IF NOT EXIST %CURRENT_DIR%tmp\nul (
  echo mkdir %CURRENT_DIR%tmp ...
  mkdir tmp
  echo mkdir tmp end ...

) else (
  echo delete tmp\ tmp\tmpzip ...
  del /Q tmp\*.*
  del /Q tmp\tmpzip\*.*
)


echo == COPY %HARBOUR_ROOT%\bin\*.* TO tmp\ ====
copy %HARBOUR_ROOT%\bin\*.* tmp\
copy /y F18-klijent.exe tmp\


cd tmp
echo ZIP=%ZIP_FILE% FILES=%FILES%
echo CMD=%ZIPACMD% ..\%ZIP_FILE% %FILES% 

REM %ZIPACMD% ..\%ZIP_FILE% %FILES%

REM public static void CreateFromDirectory (string sourceDirectoryName, string destinationArchiveFileName);
REM public System.IO.Compression.ZipArchiveEntry CreateEntry (string entryName);

mkdir tmpzip
echo moving files to tmp\tmpzip
powershell -Command "& { \"$ENV:FILES\".split() | foreach { move $_ tmpzip } }" 

echo back from tmp\tmpzip
cd ..

echo curdir=%CD%
IF EXIST %ZIP_FILE% del %ZIP_FILE%
powershell -Command "& {Add-Type -AssemblyName System.IO.Compression.FileSystem ; [System.IO.Compression.ZipFile]:: CreateFromDirectory(\"tmp\\tmpzip\",\"$ENV:ZIP_FILE\")}"

echo dir %ZIP_FILE%
dir  %ZIP_FILE%

IF NOT EXIST %ZIP_FILE% EXIT /B 10001

:end

echo kraj build_zip