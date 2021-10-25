@echo off

REM https://stackoverflow.com/questions/22278456/enable-and-disable-delayed-expansion-what-does-it-do/22278518#22278518
setlocal enableDelayedExpansion

set CYGWIN=
REM set CYGWIN=c:\cygwin64\bin\

del /F /Q F18-klijent.exe

IF EXIST F18-klijent.exe (
   echo F18-klijent.exe se ne moze izbrisati?!
   goto end
)

set F18_DEBUG=
set F18_POS=1
SET F18_GT_CONSOLE=1


set HB_DBG=%cd%
set HB_DBG_PATH=%HB_DBG%\common;%HB_DBG%\pos;%HB_DBG%\kalk;%HB_DBG%\fin;%HB_DBG%\fakt;%HB_DBG%\os;%HB_DBG%\ld;%HB_DBG%\epdv;%HB_DBG%\virm;%HB_DBG%\core;%HB_DBG%\core_sql;%HB_DBG%\core_pdf
set HB_DBG_PATH=%HB_DBG_PATH%;%HB_DBG%\core_reporting
set HB_DBG_PATH=%HB_DBG_PATH%;%HB_DBG%\fiskalizacija

set CL_X86=
set CL_X64=


IF EXIST tmpFile (
    del tmpFile
)

REM get F18 version from package.json
set NODE_PROG=const json=require('./package.json') ; console.log(json.f18)
echo %NODE_PROG% | node > tmpFile
set /p F18_VERSION= < tmpFile
del tmpFile

REM get F18 date from package.json
set NODE_PROG=const json=require('./package.json') ; console.log(json.f18_date)
echo %NODE_PROG% | node > tmpFile
set /p F18_DATE= < tmpFile
del tmpFile

REM get harbour version from package.json
set NODE_PROG=const json=require('./package.json') ; console.log(json.harbour)
echo %NODE_PROG% | node > tmpFile
set /p HARBOUR_VERSION= < tmpFile
del tmpFile

REM get harbour date from package.json
set NODE_PROG=const json=require('./package.json') ; console.log(json.harbour_date)
echo %NODE_PROG% | node > tmpFile
set /p HARBOUR_DATE= < tmpFile
del tmpFile

REM get architecture x64, x32
set NODE_PROG=console.log( process.arch === "x64" ? "64" : "32");
echo %NODE_PROG% | node > tmpFile
set /p BUILD_ARCH= < tmpFile
del tmpFile

echo !F18_VERSION!, !F18_DATE!, !HARBOUR_VERSION!, !HARBOUR_DATE!

REM (c:\cygwin64\bin\which.exe cl.exe 2>&1 | c:\cygwin64\bin\grep.exe -c "no cl.exe") > tmpFile
REM set /p CL_NOT= < tmpFile
REM del tmpFile

REM IF [!CL_NOT!]==[1] (
REM    echo cl.exe NOT IN PATH
REM    echo run: Native cmd tools for MSVC [c:\dev\x64_VS_2019.lnk] or [c:\dev\x86_VS_2019.lnk]
REM    goto end
REM)


set LINE=#define F18_VER_DEFINED
echo %LINE% > include\f18_ver.ch

set LINE=#define F18_VER       "!F18_VERSION!"
echo %LINE% >> include\f18_ver.ch

set LINE=#define F18_VER_DATE  "!F18_DATE!"
echo %LINE% >> include\f18_ver.ch

set LINE=#define F18_DEV_PERIOD  "1994-2020"
echo %LINE% >> include\f18_ver.ch

set LINE=#define F18_HARBOUR   "!HARBOUR_VERSION!"
echo %LINE% >> include\f18_ver.ch

set LINE=#define F18_ARCH   "!BUILD_ARCH!"
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


hbmk2 F18 -clean
REM hbmk2 F18 -trace- -ldflag+=/NODEFAULTLIB:LIBCMT
hbmk2 F18  -workdir=.%ARCH%r -trace-

REM copy F18.exe F18_Windows_%VERSION%
REM echo pravim F18_Windows_%VERSION%.gz ...
REM c:\cygwin64\bin\gzip --force F18_Windows_%VERSION%

REM dir F18_Windows_%VERSION%.gz

:end
echo -- end --