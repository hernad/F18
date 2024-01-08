@echo off

dir /B %USERPROFILE%\.eShell\extensions\F18\F18-windows-x64* > tmpFile
set /p ESHELL_DEV_INSTALLED= < tmpFile
del tmpFile

echo F18 installed in eShell: %ESHELL_DEV_INSTALLED%

echo eShell F18 provjera nove verzije iskljuciti !


REM set PATH=%USERPROFILE%\.eShell-dev\extensions\F18\%ESHELL_DEV_INSTALLED%

set F18_0_DIR=%USERPROFILE%\.eShell\extensions\F18\F18_0

IF NOT EXIST %F18_0_DIR%  ( 
    mkdir %F18_0_DIR%
)

copy /y F18-klijent.exe %USERPROFILE%\.eShell\extensions\F18\F18_0\F18-klijent.exe

REM cd %USERPROFILE%\dev\F18_mono\eShell


REM set Token=ESHELL_%RANDOM%

REM start "%Token%" cmd /c scripts\code.bat


eShell