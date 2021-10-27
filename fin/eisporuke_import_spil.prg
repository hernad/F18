#include "f18.ch"

FUNCTION fin_parametri_import_spil()

    LOCAL nX := 1
    LOCAL cHost := PADR(fetch_metric( "fin_spil_host", NIL, "" ), 30)
    LOCAL cUser := PADR(fetch_metric( "fin_spil_user", NIL, "" ), 30)
    LOCAL cPassword := PADR(fetch_metric( "fin_spil_password", NIL, "" ), 30)
    LOCAL cDatabase := PADR(fetch_metric( "fin_spil_db", NIL, "" ), 30)
    LOCAL GetList := {}
 
    Box(, 10, 70 )
 
    SET CURSOR ON
 
    @ box_x_koord() + nX, box_y_koord() + 2 SAY "  PRAMETRI SPIL -> F18:"
 
    nX += 2
    @ box_x_koord() + nX++, box_y_koord() + 2 SAY "MSSQL Host:" GET cHost
    @ box_x_koord() + nX++, box_y_koord() + 2 SAY "      user:" GET cUser
    @ box_x_koord() + nX++, box_y_koord() + 2 SAY "  password:" GET cPassword
    @ box_x_koord() + nX++, box_y_koord() + 2 SAY "  Database:" GET cDatabase

    READ
    BoxC()
 
    IF LastKey() <> K_ESC
       set_metric( "fin_spil_host", NIL, cHost )
       set_metric( "fin_spil_user", NIL, cUser )
       set_metric( "fin_spil_password", NIL, cPassword )
       set_metric( "fin_spil_db", NIL, cDatabase )

    ENDIF
 
    RETURN .T.
 