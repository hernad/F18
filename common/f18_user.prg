/*
 * This file is part of the bring.out knowhow ERP, a free and open source
 * Enterprise Resource Planning software suite,
 * Copyright (c) 1994-2018 by bring.out d.o.o Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including knowhow ERP specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_knowhow.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */

#include "f18.ch"

/*
FUNCTION f18_set_user_preferences( hParams )

   LOCAL _user_id := 0
   LOCAL _x := 1
   LOCAL _proper_name
   LOCAL _user_name
   LOCAL _active := "D"
   LOCAL _email
   LOCAL cQuery, _table
   LOCAL _show_box := .F.

   IF hParams == NIL
      _proper_name := Space( 50 )
      _email := Space( 50 )
      _user_name := ""
      _show_box := .T.
   ELSE
      _proper_name := hParams[ "proper_name" ]
      _email := hParams[ "email" ]
      _user_name := hParams[ "user_name" ]
   ENDIF

   IF !Empty( _user_name )
      _user_id := f18_get_user_id( _user_name )
   ENDIF

   IF _show_box

      Box(, 6, 65 )

      @ box_x_koord() + _x, box_y_koord() + 2 SAY "Korisnik (0 - odaberi iz liste):" GET _user_id ;
         VALID {|| iif( _user_id == 0, choose_f18_user_from_list( @_user_id ), .T. ), ;
         show_it( GetFullUserName( _user_id ), 30 ), .T.  }

      READ

      // uzmi ime usera iz liste
      _user_name := GetUserName( _user_id )

      ++ _x
      ++ _x
      @ box_x_koord() + _x, box_y_koord() + 2 SAY PadL( "Puno ime i prezime:", 20 ) GET _proper_name PICT "@S50"

      ++ _x
      @ box_x_koord() + _x, box_y_koord() + 2 SAY PadL( "Email:", 20 ) GET _email PICT "@S50"

      READ

      BoxC()

      IF LastKey() == K_ESC
         RETURN .F.
      ENDIF

   ENDIF

   cQuery := "SELECT setUserPreference(" + sql_quote( _user_name ) + ;
      "," + sql_quote( "propername" ) + "," + sql_quote( _proper_name ) + ");"

   cQuery += "SELECT setUserPreference(" + sql_quote( _user_name ) + ;
      "," + sql_quote( "email" ) + "," + sql_quote( _email ) + ");"

   cQuery += "SELECT setUserPreference(" + sql_quote( _user_name ) + ;
      "," + sql_quote( "active" ) + "," + sql_quote( "t" ) + ");"

   _table := run_sql_query( cQuery )

   RETURN .T.

*/
