@echo off
setlocal enableDelayedExpansion
set CURRENT_DIR=%~dp0
echo %CURRENT_DIR%

REM get architecture x64, x32
set NODE_PROG=console.log( process.arch === "x64" ? "x64" : "x86");
echo %NODE_PROG% | node > tmpFile
set /p BUILD_ARCH= < tmpFile
del tmpFile

echo BUILD_ARCH=%BUILD_ARCH%

IF EXIST tmp (
  echo delete tmp ...
  c:\cygwin64\bin\rm -rf tmp
)

REM if NOT EXIST %USERPROFILE%\.bintray_owner (
REM    echo potreban fajl %USERPROFILE%\.bintray_owner
REM    goto end
REM )
REM 
REM if NOT EXIST %USERPROFILE%\.bintray_api_key (
REM    echo potreban fajl %USERPROFILE%\.bintray_api_key
REM    goto end
REM )
REM 
REM set /p BINTRAY_OWNER= < %USERPROFILE%\.bintray_owner
REM set /p BINTRAY_API_KEY= < %USERPROFILE%\.bintray_api_key


set HARBOUR_ROOT=c:\dev\harbour\%BUILD_ARCH%\harbour

echo %HARBOUR_ROOT%
call build_zip.cmd

set F18_PACKAGE=F18-windows-%BUILD_ARCH%.zip

set HOST=192.168.168.251
set DIR=/var/www/html/F18/
echo scp  %F18_PACKAGE% root@%HOST%:%DIR%
scp -i %USERPROFILE%\.ssh\id_rsa %F18_PACKAGE% root@%HOST%:%DIR%
ssh -i %USERPROFILE%\.ssh\id_rsa root@%HOST% chmod +r %DIR%/%F18_PACKAGE%

set HOST=192.168.168.252
echo scp  %F18_PACKAGE% root@%HOST%:%DIR%
scp -i %USERPROFILE%\.ssh\id_rsa %F18_PACKAGE% root@%HOST%:%DIR%
ssh -i %USERPROFILE%\.ssh\id_rsa root@%HOST% chmod +r %DIR%/%F18_PACKAGE%


if EXIST %CURRENT_DIR%tmp\nul (
  echo rm -rf %CURRENT_DIR%tmp
  c:\cygwin64\bin\rm.exe -rf %CURRENT_DIR%tmp
) else (
   echo  dir %CURRENT_DIR%tmp not exists
)



:end

echo kraj