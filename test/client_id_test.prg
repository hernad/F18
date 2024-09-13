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

function test_client_id()

get_client_id()

my_home()



function get_client_id()
local _ini_params 

_ini_params := hb_hash()
_ini_params["id"] := NIL

if !f18_ini_config_read(F18_CLIENT_ID_INI_SECTION, @_ini_params, .t.)
   MsgBeep("problem ini read")
endif


