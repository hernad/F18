@echo off


IF [%VERSION%]==[] (
   echo ENVAR VERSION nije definisana. STOP!
   goto end
)

REM IF [%1]==[] (
REM    ECHO download host nije definisan?!
REM    ECHO POZIV: push_release_to_server download_host.bring.out.ba
REM    
REM    ECHO PREREQ: push ssh-key from build machine [ON download_host.bring.out.ba]
REM    ECHO "ssh-rsa AAAAB3N.... zaCs274Or//xwd4OOgUd sa\ernad.h@hp-desk-sa-X" >> /root/.ssh/authorized_keys
REM    goto end
REM )

set HOST=192.168.168.251
set DIR=/var/www/html/
set DIR_VERSION=/var/www/html/F18_v3/
echo scp  F18_Windows_%VERSION%.gz root@%HOST%:%DIR%
scp -i %USERPROFILE%\.ssh\id_rsa F18_Windows_%VERSION%.gz root@%HOST%:%DIR%
scp -i %USERPROFILE%\.ssh\id_rsa VERSION* root@%HOST%:%DIR_VERSION%
scp -i %USERPROFILE%\.ssh\id_rsa scripts\f18_upd.* root@%HOST%:%DIR_VERSION%
ssh -i %USERPROFILE%\.ssh\id_rsa  root@%HOST% chmod +r %DIR%/F18_Windows_%VERSION%.gz

set HOST=192.168.168.252
set DIR=/var/www/html/
echo scp  F18_Windows_%VERSION%.gz root@%HOST%:%DIR%
scp -i %USERPROFILE%\.ssh\id_rsa F18_Windows_%VERSION%.gz root@%HOST%:%DIR%
scp -i %USERPROFILE%\.ssh\id_rsa VERSION* root@%HOST%:%DIR_VERSION%
scp -i %USERPROFILE%\.ssh\id_rsa scripts\f18_upd.* root@%HOST%:%DIR_VERSION%
ssh -i %USERPROFILE%\.ssh\id_rsa  root@%HOST% chmod +r %DIR%/F18_Windows_%VERSION%.gz

:end
echo ---- kraj ----