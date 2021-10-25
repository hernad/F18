#!/bin/bash

#SSH_OPTS="-i $HOME/hernad_ssh.key -o StrictHostKeyChecking=no"
#WWW_PATH=/var/www/files

#scp $SSH_OPTS $1 root@download.bring.out.ba:$WWW_PATH/
#ssh $SSH_OPTS root@download.bring.out.ba chmod +r $WWW_PATH/*

GREEN1=docker@192.168.168.171

scp $1 $GREEN1:/data_0/f18-downloads_0/downloads.bring.out.ba/www/files/

