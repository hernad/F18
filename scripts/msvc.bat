
set ROOT=c:\Users\hernad\x86
set PSQL_VER=10.11-1

set PATH=%ROOT%\hb\bin;%PATH%
set INCLUDE=%ROOT%\include;%ROOT%\hb\contrib\hbhpdf\harupdf.ch;%INCLUDE%

set HB_INSTALL_PREFIX=%ROOT%\hb
set HB_WITH_PGSQL=%ROOT%\postgresql-%PSQL_VER%\pgsql\include

set HB_USER_CFLAGS="-DHB_TR_LEVEL=HB_TR_DEBUG"
set HB_TR_LEVEL=HB_TR_DEBUG

set F18_POS=1
set F18_GT_CONSOLE=1

REM call "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Visual C++ Build Tools\Windows Desktop Command Prompts\Visual C++ 2015 x86 Native Build Tools Command Prompt.lnk"

REM amd64 ili x86
call "C:\Program Files (x86)\Microsoft Visual C++ Build Tools\vcbuildtools.bat" x86

cd \users\hernad\F18




REM You should build Harbour this way (or similar)
REM call "%ProgramFiles(x86)%\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build\vcvarsall.bat" x86_amd64
REM 
REM set HB_BUILD_MODE=c
REM 
REM set HB_USER_PRGFLAGS=-l-
REM 
REM set HB_BUILD_CONTRIBS=yes
REM 
REM set HB_WITH_OPENSSL=c:\OpenSSL-Win32\include
REM 
REM set HB_WITH_CURL=c:\curl\include
REM 
REM del .\src\common\obj\win\msvc64\hbver.obj
REM 
REM del .\src\common\obj\win\msvc64\hbver_dyn.obj
REM 
REM del .\src\common\obj\win\msvc\hbverdsp.obj
REM 
REM win-make.exe



