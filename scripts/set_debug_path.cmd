@echo off

set ROOT=%cd%
set HB_DBG_PATH=%ROOT%\common;%ROOT%\kalk;%ROOT%\fin
set HB_DBG_PATH=%HB_DBG_PATH%;%ROOT%\fakt
set HB_DBG_PATH=%HB_DBG_PATH%;%ROOT%\kalk

set HB_DBG_PATH=%HB_DBG_PATH%;%ROOT%\core
set HB_DBG_PATH=%HB_DBG_PATH%;%ROOT%\core_sql
set HB_DBG_PATH=%HB_DBG_PATH%;%ROOT%\core_dbf
set HB_DBG_PATH=%HB_DBG_PATH%;%ROOT%\core_pdf
set HB_DBG_PATH=%HB_DBG_PATH%;%ROOT%\core_string
set HB_DBG_PATH=%HB_DBG_PATH%;%ROOT%\core_ui2
set HB_DBG_PATH=%HB_DBG_PATH%;%ROOT%\core_semafori
set HB_DBG_PATH=%HB_DBG_PATH%;%ROOT%\fiskalizacija

echo HB_DBG_PATH=%HB_DBG_PATH%

