@echo off

dir /B %USERPROFILE%\.eShell-dev\extensions\F18\F18-windows-x64* > tmpFile
set /p ESHELL_DEV_INSTALLED= < tmpFile
del tmpFile

echo F18 installed in eShell: %ESHELL_DEV_INSTALLED%

echo eShell-dev F18 provjera nove verzije iskljuciti !


REM set PATH=%USERPROFILE%\.eShell-dev\extensions\F18\%ESHELL_DEV_INSTALLED%

set F18_0_DIR=%USERPROFILE%\.eShell-dev\extensions\F18\F18_0

IF NOT EXIST %F18_0_DIR%  ( 
    mkdir %F18_0_DIR%
)

copy /y F18-klijent.exe %USERPROFILE%\.eShell-dev\extensions\F18\F18_0\F18-klijent.exe

cd c:\dev\eShell


set Token=ESHELL_%RANDOM%

start "%Token%" cmd /c scripts\code.bat

:waiteShell
ping -n 2 localhost >nul 2>nul
tasklist /fi "WINDOWTITLE eq %Token%" | findstr "cmd" >nul 2>nul && set Child1=1 || set Child1=
if not defined Child1 goto endloop
goto waiteShell

:endloop
echo eShell-dev died

cd c:\dev\F18
