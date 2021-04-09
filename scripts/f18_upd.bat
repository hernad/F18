@echo off
REM # ver 2.1.0
REM # hernad@bring.out.ba
REM # date 09.04.2021
set PATH=%PATH%;C:\knowhowERP\bin;C:\knowhowERP\lib;C:\knowhowERP\util
set DEST=C:\knowhowERP\bin
set UTIL=C:\knowhowERP\util
set KLIB=C:\knowhowERP\lib
set PSQLUTIL=C:\knowhowERP\bin\F18_util\psql
set PSQLVER=12.1
set URL=http://download.bring.out.ba/F18_v3

:SERVICE
echo.
echo.
echo Provjera da li je F18 zatvoren
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
echo Provjera ispravnosti arhive
echo.
echo.
gzip -tv  %1
if errorlevel 1 goto ERR2 if errorlevel 0 goto OK

:OK

gzip -dNfc  < %1 > %DEST%\F18.exe
del /Q  %1
goto PSQL

:ERR1
echo.
echo.
echo Problem sa F18 update fajlom, Prekidam operaciju UPDATE-a
echo.
echo.
pause
rem exit

:ERR2

echo.
echo.
echo Greska unutar F18 update fajla, Prekidam operaciju, ponovite UPDATE
echo.
echo.
pause
rem exit

:PSQL

IF NOT EXIST %UTIL%\psql.exe goto UPSQL
%PSQLUTIL%\psql.exe --version | %UTIL%\grep.exe "%PSQLVER%"

IF "%ERRORLEVEL%"=="0" GOTO END

echo upgrade psql utilities

del /Q %PSQLUTIL%\*.exe
del /Q %PSQLUTIL%\*.dll

del /Q %KLIB%\libpq.dll
del /Q %KLIB%\psql.exe
del /Q %KLIB%\pg_dump.exe
del /Q %KLIB%\pg_dumpall.exe

del /Q %UTIL%\psql.exe
del /Q %UTIL%\pg_dump.exe
del /Q %UTIL%\pg_dumpall.exe

set FILE=libcrypto-1_1.dll
%UTIL%\wget -qO %FILE%.gz %URL%/%FILE%.gz
%UTIL%\gzip -tv %FILE%.gz
if NOT "%ERRORLEVEL%"=="0" GOTO GZERR   
%UTIL%\gzip -dNfc  < %FILE%.gz > %UTIL%\%FILE%
%UTIL%\gzip -dNfc  < %FILE%.gz > %PSQLUTIL%\%FILE%
del /Q %FILE%.gz 

set FILE=libiconv.dll
%UTIL%\wget -qO %FILE%.gz %URL%/%FILE%.gz 
%UTIL%\gzip -tv %FILE%.gz
if NOT "%ERRORLEVEL%"=="0" GOTO GZERR
%UTIL%\gzip -dNfc  < %FILE%.gz > %UTIL%\%FILE%
%UTIL%\gzip -dNfc  < %FILE%.gz > %PSQLUTIL%\%FILE%
del /Q %FILE%.gz 

set FILE=libpq.dll
%UTIL%\wget -qO %FILE%.gz %URL%/%FILE%.gz
%UTIL%\gzip -tv %FILE%.gz
if NOT "%ERRORLEVEL%"=="0" GOTO GZERR
%UTIL%\gzip -dNfc  < %FILE%.gz > %UTIL%\%FILE%
%UTIL%\gzip -dNfc  < %FILE%.gz > %PSQLUTIL%\%FILE%
del /Q %FILE%.gz

set FILE=libssl-1_1.dll
%UTIL%\wget -qO %FILE%.gz %URL%/%FILE%.gz
%UTIL%\gzip -tv %FILE%.gz
if NOT "%ERRORLEVEL%"=="0" GOTO GZERR 
%UTIL%\gzip -dNfc  < %FILE%.gz > %UTIL%\%FILE%
%UTIL%\gzip -dNfc  < %FILE%.gz > %PSQLUTIL%\%FILE%
del /Q %FILE%.gz

set FILE=libxml2.dll
%UTIL%\wget -qO %FILE%.gz %URL%/%FILE%.gz
%UTIL%\gzip -tv %FILE%.gz
if NOT "%ERRORLEVEL%"=="0" GOTO GZERR 
%UTIL%\gzip -dNfc  < %FILE%.gz > %UTIL%\%FILE%
%UTIL%\gzip -dNfc  < %FILE%.gz > %PSQLUTIL%\%FILE%
del /Q %FILE%.gz

set FILE=zlib1.dll
%UTIL%\wget -qO %FILE%.gz %URL%/%FILE%.gz
%UTIL%\gzip -tv %FILE%.gz
if NOT "%ERRORLEVEL%"=="0" GOTO GZERR 
%UTIL%\gzip -dNfc  < %FILE%.gz > %UTIL%\%FILE%
%UTIL%\gzip -dNfc  < %FILE%.gz > %PSQLUTIL%\%FILE%
del /Q %FILE%.gz

set FILE=pg_dump.exe
%UTIL%\wget -qO %FILE%.gz %URL%/%FILE%.gz
%UTIL%\gzip -tv %FILE%.gz
if NOT "%ERRORLEVEL%"=="0" GOTO GZERR 
%UTIL%\gzip -dNfc  < %FILE%.gz > %UTIL%\%FILE%
%UTIL%\gzip -dNfc  < %FILE%.gz > %PSQLUTIL%\%FILE%
del /Q %FILE%.gz

set FILE=pg_dumpall.exe
%UTIL%\wget -qO %FILE%.gz %URL%/%FILE%.gz
%UTIL%\gzip -tv %FILE%.gz
if NOT "%ERRORLEVEL%"=="0" GOTO GZERR 
%UTIL%\gzip -dNfc  < %FILE%.gz > %UTIL%\%FILE%
%UTIL%\gzip -dNfc  < %FILE%.gz > %PSQLUTIL%\%FILE%
del /Q %FILE%.gz

set FILE=pg_restore.exe
%UTIL%\wget -qO %FILE%.gz %URL%/%FILE%.gz
%UTIL%\gzip -tv %FILE%.gz
if NOT "%ERRORLEVEL%"=="0" GOTO GZERR 
%UTIL%\gzip -dNfc  < %FILE%.gz > %UTIL%\%FILE%
%UTIL%\gzip -dNfc  < %FILE%.gz > %PSQLUTIL%\%FILE%
del /Q %FILE%.gz

set FILE=psql.exe
%UTIL%\wget -qO %FILE%.gz %URL%/%FILE%.gz
%UTIL%\gzip -tv %FILE%.gz
if NOT "%ERRORLEVEL%"=="0" GOTO GZERR 
%UTIL%\gzip -dNfc  < %FILE%.gz > %UTIL%\%FILE%
%UTIL%\gzip -dNfc  < %FILE%.gz > %PSQLUTIL%\%FILE%
del /Q %FILE%.gz

goto end

:GZERR
echo ERROR wget gunzip
goto :eof

:END
echo.
echo.
echo Update je zavrsen uspjesno
echo.
echo Mozete zatvoriti ovaj prozor te ponovo pokrenuti F18
echo.
echo.
pause

