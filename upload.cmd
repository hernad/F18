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

if NOT EXIST %USERPROFILE%\.bintray_owner (
   echo potreban fajl %USERPROFILE%\.bintray_owner
   goto end
)

if NOT EXIST %USERPROFILE%\.bintray_api_key (
   echo potreban fajl %USERPROFILE%\.bintray_api_key
   goto end
)

set /p BINTRAY_OWNER= < %USERPROFILE%\.bintray_owner
set /p BINTRAY_API_KEY= < %USERPROFILE%\.bintray_api_key


set HARBOUR_ROOT=c:\dev\harbour\%BUILD_ARCH%\harbour

echo %HARBOUR_ROOT%, bintray: %BINTRAY_OWNER%, %BINTRAY_API_KEY%
REM upload_bintray_win32.bat


if EXIST %CURRENT_DIR%tmp\nul (
  echo rm -rf %CURRENT_DIR%tmp
  c:\cygwin64\bin\rm.exe -rf %CURRENT_DIR%tmp
)


:end

echo kraj