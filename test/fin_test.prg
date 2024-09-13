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

function fin_test()
LOCAL _user := f18_user()
LOCAL _server := sql_data_conn()


local nI, _rec

SELECT F_SUBAN
my_usex("suban")

ZAPP()
_sql_query_2( _server, "delete from fmk.fin_suban where idvn='9X'")


log_disable()
for nI := 1 to 10
    for _j:= 1 to 5

        APPEND BLANK
        _rec := dbf_get_rec()
        _rec["idfirma"] := "10"
        _rec["idvn"] := "9X"
        _rec["brnal"] := PADL(ALLTRIM(STR(nI, 8)), 8, "0")
        _rec["rbr"] := STR(_j, 4)
        _rec["iznosbhd"] := 100
        _rec["iznosdem"] := 0

        if (_j % 2) == 0
          _rec["idkonto"] := "1200"
          _rec["d_p"] := "2"
        else
          _rec["idkonto"] := "3000"
          _rec["d_p"] := "1"
        endif
   
        update_rec_server_and_dbf( ALIAS(), _rec)

    next
next
log_enable()
TEST_LINE(reccount(), 10*5)

return


// pomocna funkcija za sql query izvršavanje
static function _sql_query_2( oServer, cQuery )
local oResult, cMsg

oResult := oServer:Query( cQuery )
IF oResult:NetErr() .AND. !EMPTY(oResult:ErrorMsg())
      cMsg := oResult:ErrorMsg()
      MsgBeep( cMsg )
      return .f.
ENDIF
RETURN oResult


