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



FUNCTION sifra_ispis_naziva( nDbf, dx, dy )

   LOCAL cTmp  := ""

   IF ( nDbf )->( FieldPos( "naz" ) ) <> 0
      cTmp := Trim( ( nDbf )->naz  )
   ENDIF

   IF ( nDbf )->( FieldPos( "naziv" ) ) <> 0
      cTmp := Trim( ( nDbf )->naziv  )
   ENDIF

   // IF ( nDbf )->( my_rddName() ) == "SQLMIX" // sql data utf-8
   // cTmp := _u( cTmp )
   // ENDIF

   IF dx <> NIL .AND. dy <> nil

      IF ( nDbf )->( FieldPos( "naz" ) ) <> 0
         @ box_x_koord() + dx, box_y_koord() + dy SAY PadR( cTmp, 70 - dy )
      ENDIF

      IF ( nDbf )->( FieldPos( "naziv" ) ) <> 0
         @ box_x_koord() + dx, box_y_koord() + dy SAY PadR( cTmp, 70 - dy )
      ENDIF

   ELSEIF dx <> NIL .AND. dx > 0 .AND. dx < 25
      // CentrTxt( cTmp, dx )
   ENDIF

   RETURN .T.


/*
   sifk_fill_ImeKol( "PARTN", @ImeKol, @Kol )

*/
FUNCTION sifk_fill_ImeKol( cDbf, ImeKol, Kol )

   LOCAL hRec, aRecords, ii, nIKol

   IF !use_sql_sifk( cDbf, NIL )
      ?E "ERROR SIFK ", cDbf
      RETURN .F.
   ENDIF
   //use_sql_sifv()

   nIKol := LEN( Kol )

   cDbf := PadR( cDbf, FIELD_LEN_SIFK_ID )

   SELECT sifk
   aRecords := {}
   GO TOP
   DO WHILE !Eof() .AND. field->ID == cDbf
      hRec := dbf_get_rec()
      IF hRec[ "edkolona" ] == NIL
         hRec[ "edkolona" ] := 0
      ENDIF
      AAdd( aRecords, hRec )
      SKIP
   ENDDO

   FOR EACH hRec in aRecords

      AAdd ( ImeKol, {  get_sifk_naz( cDbf, hRec[ "oznaka" ] ) } )
      AAdd ( ImeKol[ Len( ImeKol ) ], &( "{|| ToStr( get_partn_sifk_sifv('" + hRec[ "oznaka" ] + "')) }" ) )
      AAdd ( ImeKol[ Len( ImeKol ) ], "SIFK->" + hRec[ "oznaka" ] )

      IF hRec[ "edkolona" ] > 0
         FOR ii := 4 TO 9
            AAdd( ImeKol[ Len( ImeKol ) ], NIL  )
         NEXT
         AAdd( ImeKol[ Len( ImeKol ) ], hRec[ "edkolona" ]  )
      ELSE
         FOR ii := 4 TO 10
            AAdd( ImeKol[ Len( ImeKol ) ], NIL  )
         NEXT
      ENDIF

      // postavi PICT za brojeve
      IF hRec[ "tip" ] == "N"
         IF f_decimal > 0
            ImeKol[ Len( ImeKol ), 7 ] := Replicate( "9", hRec[ "duzina" ] - hRec[ "f_decimal" ] - 1 ) + "." + Replicate( "9", hRec[ "f_decimal" ] )
         ELSE
            ImeKol[ Len( ImeKol ), 7 ] := Replicate( "9", hRec[ "duzina" ] )
         ENDIF
      ENDIF

      AAdd( Kol, iif( hRec[ "ubrowsu" ] == '1', ++nIKol, 0 ) )

   NEXT

   RETURN .T.
