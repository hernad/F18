export HB_ARCHITECTURE=win
export HB_COMPILER=mingw

C_ROOT=C:
MSYS=msys64
HB_ROOT=$C_ROOT\\hbwin


export HB_INC_INSTALL=$HB_ROOT\\include
export HB_LIB_INSTALL=$HB_ROOT\\lib

export HB_INSTALL_PREFIX=$HB_ROOT

export MSYS2=c:\\$MSYS\\mingw32

export PATH=/c/$MSYS/mingw32/bin:$HB_ROOT\\bin:$PATH

#export PATH=$MSYS2\\bin:$PATH
export HB_WITH_PGSQL=$MSYS2\\include
export HB_WITH_OPENSSL=$MSYS2\\include

#export HB_CCPREFIX=${MINGW}-
. scripts/set_envars.sh
