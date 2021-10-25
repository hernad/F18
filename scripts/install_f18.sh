#!/bin/bash

VER=0.1.0
DAT=25.11.2011

echo F188 install app ver: $VER, dat: $DAT

echo F18 mac installacija ....

mkdir ~/.f18

mkdir ~/bin

echo " "
echo TODO !
echo provjeriti da li postoji dir pa tek onda pokrenuti mkdir komande 
echo " "

cp bin/F18 ~/bin
chmod +x ~/bin/F18

echo " "
echo " "
echo TODO  !!!:
echo dodati delphirb, ptxt shell u ovaj install program
echo " " 
echo " "

echo ako ~/.bin nije u PATH-u, u .bash_profile dodajte na kraj liniju:
echo -----------------------------------------------------------------
echo export PATH=\$PATH:~/bin


