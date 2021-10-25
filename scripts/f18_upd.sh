#!/bin/bash

# VARS
PATH=/bin:/usr/bin:/usr/local/bin:/opt/knowhowERP/bin:/opt/knowhowERP/util
VER=1.0.0
DAT=22.11.2013
SERVICE=$(ps ax | grep -v grep | grep -c 'F18$')
DEST=/opt/knowhowERP/bin

# spavaj dok se F18 ne zatvori
sleep 3

# da li je update zero lenght
if [ ! -s $1 ]; then
    echo "nema fajla!"
    exit 0
else
    echo "sve spremno za update, nastavljam"
fi

# provjeravam F18 servis i radim update"
while  [ "$SERVICE" -gt 0 ]
	do
       echo "$SERVICE je pokrenut cekam da se zatvori"
       sleep 5
    done
       gzip -dNfc  < $1 > $DEST/F18
       chmod +x $DEST/F18
       echo "update je zavrsen"
       DISPLAY=:0 notify-send  "F18 upgrade završen, možete pokrenuti F18"
       rm $1

exit 0
