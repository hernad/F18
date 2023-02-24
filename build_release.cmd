@echo off

REM set CYGWIN=c:\cygwin64\bin\
set CYGWIN=

REM set HB_ARCHITECTURE=win
REM IF [%ARCH%]==[x64] (
REM   set HB_COMPILER=msvc64
REM ) ELSE (
REM    set HB_COMPILER=msvc
REM )
set F18_GT_CONSOLE=
set F18_GT_GUI=1

set F18_DEBUG=
set F18_POS=1
set DATE=24.02.2023
set VERSION=3.3.116

IF [%VERSION%]==[] (
   echo ENVAR VERSION nije definisana. STOP!
   goto end
)

copy /Y include\f18_ver_template.ch include\f18_ver.ch

echo #define F18_VER       "%VERSION%" >> include\f18_ver.ch
echo #define F18_VER_DATE  "%DATE%" >> include\f18_ver.ch

type include\f18_ver.ch


REM hbmk2 F18 -clean -workdir=.b32
hbmk2 F18 -trace- -ldflag+=/NODEFAULTLIB:LIBCMT -workdir=.%ARCH%r

copy /y F18.exe F18_2.exe
%CYGWIN%gzip --force F18.exe

echo pravim F18_Windows_%VERSION%.gz ...
copy /y F18.exe.gz F18_Windows_%VERSION%.gz

:end
echo -- end --