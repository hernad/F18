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


FUNCTION sast_repl_all() // zamjena sastavnice u svim proizvodima

   LOCAL lOk := .T.
   LOCAL cOldS
   LOCAL cNewS
   LOCAL nKolic
   LOCAL hRec
   LOCAL hParams
   LOCAL GetList := {}

   cOldS := Space( 10 )
   cNewS := Space( 10 )
   nKolic := 0

   Box(, 6, 70 )
   @ box_x_koord() + 1, box_y_koord() + 2 SAY "'Stara' sirovina :" GET cOldS PICT "@!" VALID P_Roba_select( @cOldS )
   @ box_x_koord() + 2, box_y_koord() + 2 SAY "'Nova'  sirovina :" GET cNewS PICT "@!" VALID cNewS <> cOldS .AND. P_Roba( @cNewS )
   @ box_x_koord() + 4, box_y_koord() + 2 SAY "Kolicina u normama (0 - zamjeni bez obzira na kolicinu)" GET nKolic PICT "999999.99999"
   READ
   BoxC()

   IF ( LastKey() <> K_ESC )

      run_sql_query( "BEGIN" )
      //IF !f18_lock_tables( { "sast" }, .T. )
      //   run_sql_query( "ROLLBACK" )
      //   MsgBeep( "Greska sa lock-om tabele sast !" )
      //   RETURN .F.
      //ENDIF

      o_sastavnice()
      GO TOP

      DO WHILE !Eof()
         IF id2 == cOldS
            IF ( nKolic = 0 .OR. Round( nKolic - field->kolicina, 5 ) = 0 )
               hRec := dbf_get_rec()
               hRec[ "id2" ] := cNewS
               lOk := update_rec_server_and_dbf( "sast", hRec, 1, "CONT" )
            ENDIF
         ENDIF
         IF !lOk
            EXIT
         ENDIF
         SKIP
      ENDDO

      IF lOk
         hParams := hb_Hash()
         //hParams[ "unlock" ] :=  { "sast" }
         run_sql_query( "COMMIT", hParams )
      ELSE
         run_sql_query( "ROLLBACK" )
      ENDIF

      //SET ORDER TO TAG "idrbr"

   ENDIF

   RETURN .T.


FUNCTION sast_promjena_ucesca_materijala() // promjena ucesca

   LOCAL lOk := .T.
   LOCAL cOldS
   LOCAL cNewS
   LOCAL nKolic
   LOCAL nKolic2
   LOCAL hRec
   LOCAL hParams
   LOCAL GetList := {}

   cOldS := Space( 10 )
   cNewS := Space( 10 )
   nKolic := 0
   nKolic2 := 0

   Box(, 6, 65 )
   @ box_x_koord() + 1, box_y_koord() + 2 SAY8 "Sirovina :" GET cOldS PICT "@!" VALID P_Roba_select( @cOldS )
   @ box_x_koord() + 4, box_y_koord() + 2 SAY8 "postojeca količina u normama " GET nKolic PICT "999999.99999"
   @ box_x_koord() + 5, box_y_koord() + 2 SAY8 "nova količina u normama      " GET nKolic2 PICT "999999.99999"   VALID nKolic <> nKolic2
   READ
   BoxC()

   IF ( LastKey() <> K_ESC )

      run_sql_query( "BEGIN" )
      //IF !f18_lock_tables( { "sast" }, .T. )
      //   run_sql_query( "ROLLBACK" )
      //   MsgBeep( "Greska sa lock-om tabele sast !" )
      //   RETURN .F.
      //ENDIF

      //SELECT sast
      o_sastavnice()
      SET ORDER TO
      GO TOP

      DO WHILE !Eof()

         IF PadR( field->id2, 10 ) == PadR( cOldS, 10 )
            IF Round( nKolic - field->kolicina, 5 ) = 0
               hRec := dbf_get_rec()
               hRec[ "kolicina" ] := nKolic2
               lOk := update_rec_server_and_dbf( Alias(), hRec, 1, "CONT" )
            ENDIF
         ENDIF

         IF !lOk
            EXIT
         ENDIF

         SKIP

      ENDDO

      IF lOk
         hParams := hb_Hash()
         //hParams[ "unlock" ] :=  { "sast" }
         run_sql_query( "COMMIT", hParams )
      ELSE
         run_sql_query( "ROLLBACK" )
      ENDIF

      //SET ORDER TO TAG "idrbr"
   ENDIF

   RETURN .T.
