@echo off

REM set HB_ARCHITECTURE=win
REM 
REM IF [%ARCH%]==[x64] (
REM   set HB_COMPILER=msvc64
REM ) ELSE (
REM    set HB_COMPILER=msvc
REM )

set F18_POS=1
set F18_DEBUG=1
set DATE=08.02.2023
set VERSION=3.3.115

IF [%VERSION%]==[] (
   echo ENVAR VERSION nije definisana. STOP!
   goto end
)

copy /Y include\f18_ver_template.ch include\f18_ver.ch

echo #define F18_VER       "%VERSION%" >> include\f18_ver.ch
echo #define F18_VER_DATE  "%DATE%" >> include\f18_ver.ch

type include\f18_ver.ch

hbmk2 F18 -workdir=.%ARCH%d -trace- -ldflag+=/NODEFAULTLIB:LIBCMT


:end
echo -- end --