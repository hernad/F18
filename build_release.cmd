@echo off

set HB_ARCHITECTURE=win
set HB_COMPILER=msvc

set F18_DEBUG=
set F18_POS=1
set DATE=26.04.2021
set VERSION=3.3.71

IF [%VERSION%]==[] (
   echo ENVAR VERSION nije definisana. STOP!
   goto end
)

copy /Y include\f18_ver_template.ch include\f18_ver.ch

echo #define F18_VER       "%VERSION%" >> include\f18_ver.ch
echo #define F18_VER_DATE  "%DATE%" >> include\f18_ver.ch

type include\f18_ver.ch


REM hbmk2 F18 -clean -workdir=.b32
hbmk2 F18 -trace- -ldflag+=/NODEFAULTLIB:LIBCMT -workdir=.b32

copy /y F18.exe F18_2.exe
c:\cygwin64\bin\gzip --force F18.exe

echo pravim F18_Windows_%VERSION%.gz ...
copy /y F18.exe.gz F18_Windows_%VERSION%.gz

:end
echo -- end --