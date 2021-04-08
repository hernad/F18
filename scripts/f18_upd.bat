@echo off
REM # ver 1.0.3
REM # bjasko@bring.out.ba
REM # date 09.02.2021
set PATH=%PATH%;C:\knowhowERP\bin;C:\knowhowERP\lib;C:\knowhowERP\util
set DEST=C:\knowhowERP\bin
set UTIL=C:\knowhowERP\util
set PSQLVER=11.0.0
set URL=http://download.bring.out.ba/F18_v3

:SERVICE
echo.
echo.
echo "Provjeravam dali je F18 zatvoren"
echo.
echo.

PING -n 6 www.google.com  >NUL
taskkill /IM "F18.exe" /F
REM # provjeri dali se F18 vrti
tasklist.exe /FI "IMAGENAME eq F18.exe" 2>NUL | find.exe /I /N "F18.exe" >NUL
if "%ERRORLEVEL%"=="0" echo "izgleda je je F18 aktivan, zatvorite ga" & goto SERVICE else got UPDATE

:UPDATE

if not exist %1  goto ERR1

echo.
echo.
echo "Provjera ispravnosti arhive"
echo.
echo.
gzip -tv  %1
if errorlevel 1 goto ERR2 if errorlevel 0 goto OK

:OK

gzip -dNfc  < %1 > %DEST%\F18.exe
del /Q  %1
goto END

:ERR1
echo.
echo.
echo "Problem sa F18 update fajlom, Prekidam operaciju UPDATE-a"
echo.
echo.
pause
rem exit

:ERR2

echo.
echo.
echo "Greska unutar F18 update fajla, Prekidam operaciju, ponovite UPDATE"
echo.
echo.
pause
rem exit

:END

%UTIL%\psql.exe --version | %UTIL%\grep.exe "%PSQLVER%"

IF "%ERRORLEVEL%"=="0" GOTO END2

echo upgrade psql utilities

REM libcrypto-1_1.dll.gz
REM libiconv.dll.gz
REM libpq.dll.gz
REM libssl-1_1.dll.gz
REM libxml2.dll.gz
REM pg_dump.exe.gz
REM pg_restore.exe.gz
REM psql.exe.gz
REM zlib1.dll.gz


REM %UTIL%\gzip -tv  
REM if errorlevel 1 goto ERR2 if errorlevel 0 goto OK
set FILE=libcrypto-1_1.dll
%UTIL%\wget %URL%/%FILE%.gz -o %FILE%.gz
%UTIL%\gzip -dNfc  < %FILE%.gz > %UTIL%\%FILE%.gz
del /Q %FILE%.gz 

set FILE=libiconv.dll.gz
%UTIL%\wget %URL%/%FILE%.gz -o %FILE%.gz
%UTIL%\gzip -dNfc  < %FILE%.gz > %UTIL%\%FILE%.gz
del /Q %FILE%.gz 

set FILE=libpq.dll.gz
%UTIL%\wget %URL%/%FILE%.gz -o %FILE%.gz
%UTIL%\gzip -dNfc  < %FILE%.gz > %UTIL%\%FILE%.gz
del /Q %FILE%.gz

set FILE=libssl-1_1.dll.gz
%UTIL%\wget %URL%/%FILE%.gz -o %FILE%.gz
%UTIL%\gzip -dNfc  < %FILE%.gz > %UTIL%\%FILE%.gz
del /Q %FILE%.gz

:END2
echo.
echo.
echo "Update je zavrsen uspjesno"
echo.
echo "Mozete zatvoriti ovaj prozor te ponovo pokrenuti F18"
echo.
echo.
pause
rem exit
