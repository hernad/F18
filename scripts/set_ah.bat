SET HB_INSTALL_PREFIX=c:\dev\harbour\x64\harbour
SET F18_POS=1
SET F18_GT_CONSOLE=1
SET F18_DEBUG=1

SET PATH=%HB_INSTALL_PREFIX%\bin;%PATH%

set HB_DBG=c:\dev\F18
set HB_DBG_PATH=%HB_DBG%\common;%HB_DBG%\pos;%HB_DBG%\kalk;%HB_DBG%\fin;%HB_DBG%\fakt;%HB_DBG%\os;%HB_DBG%\ld;%HB_DBG%\epdv;%HB_DBG%\virm;%HB_DBG%\core;%HB_DBG%\core_sql;%HB_DBG%\core_pdf
set HB_DBG_PATH=%HB_DBG_PATH%;%HB_DBG%\core_reporting

echo HB_INSTALL_PREFIX=%HB_INSTALL_PREFIX%
echo HB_DBG_PATH=%HB_DBG%



set F18_VERSION=4.x.x
set F18_DATE=x.y.z
set F18_HARBOUR=z.z.z
set BUILD_ARCH=64

set LINE=#define F18_VER_DEFINED
echo %LINE% > include\f18_ver.ch

set LINE=#define F18_VER       "%F18_VERSION%"
echo %LINE% >> include\f18_ver.ch

set LINE=#define F18_VER_DATE  "%F18_DATE%"
echo %LINE% >> include\f18_ver.ch

set LINE=#define F18_DEV_PERIOD  "1994-2020"
echo %LINE% >> include\f18_ver.ch

set LINE=#define F18_HARBOUR   "%HARBOUR_VERSION%"
echo %LINE% >> include\f18_ver.ch

set LINE=#define F18_ARCH   "%BUILD_ARCH%"
echo %LINE% >> include\f18_ver.ch

set LINE=#define F18_TEMPLATE_VER "3.1.0"
echo %LINE% >> include\f18_ver.ch

set LINE=#define F18_DBF_VER_MAJOR  2
echo %LINE% >> include\f18_ver.ch

set LINE=#define F18_DBF_VER_MINOR  1
echo %LINE% >> include\f18_ver.ch

set LINE=#define F18_DBF_VER_PATCH  6
echo %LINE% >> include\f18_ver.ch

set LINE=#define SERVER_DB_VER  0
echo %LINE% >> include\f18_ver.ch

echo ===========f18_ver====================================
type include\f18_ver.ch
echo ======================================================
