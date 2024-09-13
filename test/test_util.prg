/* 
 * This file is part of the bring.out knowhow ERP, a free and open source 
 * Enterprise Resource Planning software suite,
 * Copyright (c) 1994-2024 by bring.out doo Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including FMK specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_knowhow.md located at the 
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */

#include "f18.ch"

function tmp_dir()

#ifdef __PLATFORM__WINDOWS
  home := GetEnv("TMP")
#else
  return "/tmp"
#endif

// -----------------------------------------------------------------------
// test_diff_between_files(fakt_1.txt, my_home() + OUTF_FILE)
//
// sa diff programom uporedi test/data/fakt_1.txt i my_home() + outf.txt
// ------------------------------------------------------------------------
function test_diff_between_files(test_file, out_file)
local _ret, _cmd := ""

_cmd := "diff test/data/" + test_file + " " + out_file
_ret := f18_run(_cmd)

return _ret

// -----------------------------------------------------------------------
// -----------------------------------------------------------------------
function test_diff_between_odt_files(test_file, out_file)
local _ret, _cur_dir
local _cmd, _dir_1, _dir_2
local _msg

/*
#ifdef __PLATFORM__WINDOWS
    _msg := "diff odt ne radi na windows"
    RaiseError(_msg)
    QUIT
#endif
*/

_dir_1 := "f18_odt_test_1"
_dir_2 := "f18_odt_test_2"

MAKEDIR("/tmp" + _dir_1)
MAKEDIR("/tmp" + _dir_2)

_cmd := "unzip -q -o test/data/" + test_file  + " -d /tmp/" + _dir_1
if f18_run(_cmd) > 0
  MsgBeep("ERR: " + _cmd)
  QUIT
endif


_cmd := "unzip -q -o " + out_file + " -d /tmp/" + _dir_2
if f18_run(_cmd) > 0
  MsgBeep("ERR: " + _cmd)
  QUIT
endif


// u odt-u nas interesuje content xml
_cmd := "xmllint /tmp/" + _dir_1 + "/content.xml --format > /tmp/" + _dir_1 + "/test.xml"
if f18_run(_cmd) > 0
  MsgBeep("ERR: " + _cmd)
  QUIT
endif

_cmd := "xmllint /tmp/" + _dir_2 + "/content.xml --format > /tmp/" + _dir_2 + "/test.xml"
if f18_run(_cmd) > 0
  MsgBeep("ERR: " + _cmd)
  QUIT
endif


_cmd := "diff /tmp/" + _dir_1 + "/test.xml  /tmp/" + _dir_2 + "/test.xml"
_ret := f18_run(_cmd)

return _ret 
