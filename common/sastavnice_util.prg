/*
 * This file is part of the bring.out knowhow ERP, a free and open source
 * Enterprise Resource Planning software suite,
 * Copyright (c) 1994-2018 by bring.out doo Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including FMK specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_knowhow.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */

#include "f18.ch"


FUNCTION sastavnica_copy()

   LOCAL lOk := .T.
   LOCAL nTRobaRec
   LOCAL cNoviProizvod
   LOCAL cIdTek
   LOCAL nTRec
   LOCAL nCnt := 0
   LOCAL hRec
   LOCAL hParams


   nTRobaRec := RecNo()

   IF Pitanje(, "Kopirati postojeće sastavnice u novi proizvod", "N" ) == "D"

      cNoviProizvod := Space( 10 )
      cIdTek := field->id

      Box(, 2, 60 )
      @ box_x_koord() + 1, box_y_koord() + 2 SAY "Kopirati u proizvod:" GET cNoviProizvod ;
         VALID cNoviProizvod <> cIdTek .AND. P_roba_select( @cNoviProizvod ) .AND. roba->tip == "P"
      READ
      BoxC()

      IF ( LastKey() <> K_ESC )

         run_sql_query( "BEGIN" )
         IF !f18_lock_tables( { "sast" }, .T. )
            run_sql_query( "ROLLBACK" )
            MsgBeep( "lock sast neuspjesno !" )
            RETURN .F.
         ENDIF

         // SELECT sast
         // SET ORDER TO TAG "idrbr"
         o_sastavnice( cIdTek, "IDRBR" )
         nCnt := 0

         DO WHILE !Eof() .AND. ( id == cIdTek )
            ++nCnt
            nTRec := RecNo()
            hRec := dbf_get_rec()
            hRec[ "id" ] := cNoviProizvod
            APPEND BLANK

            lOk := update_rec_server_and_dbf( Alias(), hRec, 1, "CONT" )
            IF !lOk
               EXIT
            ENDIF

            GO ( nTrec )
            SKIP

         ENDDO

         IF lOk
            hParams := hb_Hash()
            hParams[ "unlock" ] :=  { "sast" }
            run_sql_query( "COMMIT", hParams )
         ELSE
            run_sql_query( "ROLLBACK" )
         ENDIF

         SELECT roba_p
         // SET ORDER TO TAG "idun"

      ENDIF
   ENDIF

   GO ( nTrobaRec )

   IF ( nCnt > 0 )
      MsgBeep( "Kopirano stavki: " + AllTrim( Str( nCnt ) ) + "# iz proizvoda " + cIdTek + " -> " + cNoviProizvod )
   ELSE
      MsgBeep( "Ne postoje sastavnice na uzorku za kopiranje!" )
   ENDIF

   RETURN .T.


FUNCTION sastavnice_delete_empty_id()

   LOCAL cSql := "delete from " + f18_sql_schema( "sast" ) + " where ( id is null or trim(id) = '') or ( id2 is null or trim(id2) = '') "
   LOCAL oRet

   oRet := run_sql_query( cSql )
   IF sql_error_in_query( oRet, "DELETE" )
      info_bar( "sql", cSql )
      RETURN .F.
   ENDIF

FUNCTION bris_sast()

   LOCAL lOk := .T.
   LOCAL _d_n
   LOCAL _thRec
   LOCAL hRec
   LOCAL hParams

   _d_n := "0"

   Box(, 5, 40 )
   @ box_x_koord() + 1, box_y_koord() + 2 SAY8 "Odaberite željenu opciju:"
   @ box_x_koord() + 3, box_y_koord() + 2 SAY8 "0. Ništa !"
   @ box_x_koord() + 4, box_y_koord() + 2 SAY "1. Izbrisati samo sastavnice ?"
   @ box_x_koord() + 5, box_y_koord() + 2 SAY "2. Izbrisati i artikle i sastavnice "
   @ box_x_koord() + 5, Col() + 2 GET _d_n VALID _d_n $ "012"
   READ
   BoxC()

   IF LastKey() == K_ESC
      RETURN 7
   ENDIF

   run_sql_query( "BEGIN" )
   IF !f18_lock_tables( {  "sast" }, .T. )
      run_sql_query( "ROLLBACK" )
      MsgBeep( "lock roba, sast neuspjeno !" )
      RETURN 7
   ENDIF


   IF _d_n $ "12" .AND. Pitanje(, "Sigurno želite izbrisati definisane sastavnice (D/N) ?", "N" ) == "D"

      SELECT sast
      DO WHILE !Eof()
         SKIP 1
         _thRec := RecNo()
         SKIP -1
         hRec := dbf_get_rec()
         lOk := delete_rec_server_and_dbf( Alias(), hRec, 1, "CONT" )
         IF !lOk
            EXIT
         ENDIF
         GO ( _thRec )
      ENDDO

   ENDIF

   IF lOk .AND. _d_n $ "2" .AND. Pitanje(, "Sigurno želite izbrisati proizvode (D/N) ?", "N" ) == "D"

      SELECT roba_p
      DO WHILE !Eof()
         SKIP
         _thRec := RecNo()
         SKIP -1

         hRec := dbf_get_rec()
         lOk := delete_rec_server_and_dbf( Alias(), hRec, 1, "CONT" )

         IF !lOk
            EXIT
         ENDIF

         GO ( _thRec )
      ENDDO

   ENDIF

   IF lOk
      hParams := hb_Hash()
      hParams[ "unlock" ] :=  { "sast" }
      run_sql_query( "COMMIT", hParams )
   ELSE
      run_sql_query( "ROLLBACK" )
      RETURN .F.
   ENDIF

   RETURN .T.
