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
echo scp doc\enabavke_eisporuke.pdf  root@%HOST%:%DIR%
scp -i %USERPROFILE%\.ssh\id_rsa doc\enabavke_eisporuke.pdf root@%HOST%:%DIR%


set HOST=192.168.168.252
set DIR=/var/www/html/
echo scp doc\enabavke_eisporuke.pdf root@%HOST%:%DIR%
scp -i %USERPROFILE%\.ssh\id_rsa doc\enabavke_eisporuke.pdf root@%HOST%:%DIR%


:end
echo ---- kraj ----