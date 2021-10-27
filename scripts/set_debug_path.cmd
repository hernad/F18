@echo off

set ROOT=%cd%
set HB_DBG_PATH=%ROOT%\common;%ROOT%\pos;%ROOT%\kalk;%ROOT%\fin
set HB_DBG_PATH=%HB_DBG_PATH%;%ROOT%\fakt
set HB_DBG_PATH=%HB_DBG_PATH%;%ROOT%\os
set HB_DBG_PATH=%HB_DBG_PATH%;%ROOT%\ld
set HB_DBG_PATH=%HB_DBG_PATH%;%ROOT%\virm
set HB_DBG_PATH=%HB_DBG_PATH%;%ROOT%\core
set HB_DBG_PATH=%HB_DBG_PATH%;%ROOT%\core_sql
set HB_DBG_PATH=%HB_DBG_PATH%;%ROOT%\core_pdf


echo HB_DBG_PATH=%HB_DBG_PATH%

