
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




