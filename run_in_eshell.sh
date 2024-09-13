#!/bin/bash


ESHELL_F18_DIR="$HOME/.eShell-dev/extensions/F18"

# codium
ESHELL_F18_DIR="$HOME/.vscode-oss/extensions/F18"

F18_INSTALLED_ALREADY=`ls -d $ESHELL_F18_DIR/F18-linux-x64-*`

CURRENTDIR=`pwd`

echo F18 installed in eShell: $F18_INSTALLED_ALREADY

echo "eShell-dev F18 provjera nove verzije iskljuciti !"


PATH=$F18_INSTALLED_ALREADY:$PATH
#konflikt sa eShell openssl LD_LIBRARY_PATH=$F18_INSTALLED_ALREADY:$LD_LIBRARY_PATH

F18_0_DIR=$ESHELL_F18_DIR/F18_0

for f in libcrypto.so libcurl.so libpq.so libssl.so libz.so
do
   echo "ln -sf ${F18_INSTALLED_ALREADY}/$f $F18_0_DIR"
   ln -sf ${F18_INSTALLED_ALREADY}/$f $F18_0_DIR
done

ls -l $F18_0_DIR/*.so

if [[ ! -d "${F18_0_DIR}" ]] ; then 
   echo F18_0_DIR=${F18_0_DIR} ne postoji
   mkdir -p ${F18_0_DIR}
   
fi

chmod +w ${F18_0_DIR}/F18-klijent
cp -av F18-klijent ${F18_0_DIR}/F18-klijent


#cd ../eShell
#LD_LIBRARY_PATH= scripts/code.sh


#cd $CURRENTDIR

codium
