F18_0 exec ne postoji: 


set ESHELL_DEST=c:\Users\hernad\.eShell\extensions\F18\F18_0
set F18_SRC=c:\dev\F18
set HARBOUR_SRC=c:\dev\harbour\x64\harbour\bin

mkdir %ESHELL_DEST%

REM set FILE=F18-klijent.exe
REM copy %F18_SRC%\%FILE% %ESHELL_DEST%\%FILE% 

set FILE=F18-klijent.exe
mklink  %ESHELL_DEST%\%FILE%  %F18_SRC%\%FILE% 


set FILE=libcrypto-1_1-x64.dll
mklink %ESHELL_DEST%\%FILE% %HARBOUR_SRC%\%FILE%

set FILE=libiconv.dll
mklink %ESHELL_DEST%\%FILE% %HARBOUR_SRC%\%FILE%

set FILE=libpq.dll
mklink %ESHELL_DEST%\%FILE% %HARBOUR_SRC%\%FILE%

set FILE=libssl-1_1-x64.dll
mklink %ESHELL_DEST%\%FILE% %HARBOUR_SRC%\%FILE%

set FILE=libxml2.dll
mklink %ESHELL_DEST%\%FILE% %HARBOUR_SRC%\%FILE%

set FILE=zlib1.dll
mklink %ESHELL_DEST%\%FILE% %HARBOUR_SRC%\%FILE%

set FILE=curl.exe
mklink %ESHELL_DEST%\%FILE% %HARBOUR_SRC%\%FILE%
