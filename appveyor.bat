
REM https://superuser.com/questions/345964/start-bash-shell-cygwin-with-correct-path-without-changing-directory
set CHERE_INVOKING=yes

rem Matrix-driven Appveyor CI script for libmypaint
rem Currently only does MSYS2 builds.
rem https://www.appveyor.com/docs/installed-software#mingw-msys-cygwin
rem Needs the following vars:
rem    MSYS2_ARCH:  x86_64 or i686
rem    MSYSTEM:  MINGW64 or MINGW32

rem Set the paths appropriately
set PATH=C:\msys64\%MSYSTEM%\bin;C:\msys64\usr\bin;%PATH%

rem Upgrade the MSYS2 platform
REM bash -lc "pacman --noconfirm --sync --refresh --refresh pacman"
REM bash -lc "pacman --noconfirm --sync --refresh --refresh --sysupgrade --sysupgrade"
bash -xlc "pacman --noconfirm -S curl zip unzip"

rem Install required tools
REM bash -xlc "pacman --noconfirm -S --needed base-devel"

rem Install the relevant native dependencies
REM bash -xlc "pacman --noconfirm -S --needed mingw-w64-%MSYS2_ARCH%-json-c"
REM bash -xlc "pacman --noconfirm -S --needed mingw-w64-%MSYS2_ARCH%-glib2"
REM bash -xlc "pacman --noconfirm -S --needed mingw-w64-%MSYS2_ARCH%-gobject-introspection"
bash -xlc "pacman --noconfirm -S --needed mingw-w64-%MSYS2_ARCH%-postgresql"


rem Invoke subsequent bash in the build tree
cd %APPVEYOR_BUILD_FOLDER%
bash -xlc "cd /c ; curl -LO https://dl.bintray.com/bringout/harbour/harbour-windows-x86_20190119.4.zip ; mkdir hbwin ; cd hbwin ; unzip ../harbour-windows-x86_20190119.4.zip"
set PATH=C:\hbwin\bin;%PATH%

rem Build/test scripting
bash -xlc "set pwd"


REM build hello.hbp

bash -xlc "export HB_ARCHITECTURE=win; export HB_COMPILER=mingw; export F18_VER=${APPVEYOR_REPO_TAG_NAME:=0.0.0} ; scripts/update_f18_ver_ch.sh $F18_VER; export F18_POS=1; source scripts/mingw_appveyor_set_envars.sh ; hbmk2 -workdir=.h F18.hbp"


REM postgresql dlls libpq.dll i kompanija
bash -xlc "curl -LO https://dl.bintray.com/hernad/F18/postgresql_windows_x86_dlls.zip; unzip postgresql_windows_x86_dlls.zip"

REM run hello.exe
bash -xlc "zip F18_${BUILD_ARTIFACT}_${APPVEYOR_REPO_TAG_NAME}.zip F18.exe"
