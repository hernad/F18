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


MEMVAR gIdRadnik

/*

-- 1) radnik 00010 odbija prijem:
-- select p2.pos_21_to_22( '20567431', '0010', false );
-- generise se samo p2.pos stavka 22, sa opisom: ODBIJENO: 0010

-- 2) radnik 00010 potvrdjuje prijem:
-- select p2.pos_21_to_22( '20567431', '0010', true );
-- generise se samo p2.pos stavka 22, sa opisom: PRIJEM: 0010

FUNCTION p2.pos_21_to_22( cBrFaktP varchar, cIdRadnik varchar, lPreuzimaSe boolean) RETURNS integer

*/

FUNCTION pos_21_to_22_unos()

   LOCAL cBrFaktP := Space( 10 )
   LOCAL GetList := {}
   LOCAL cPregledDN := "D"
   LOCAL cPreuzimaSeDN := "D"
   LOCAL nRet, cMsg

   Box(, 5, 60 )
   @ box_x_koord() + 1, box_y_koord() + 2 SAY8 "Broj otpremnice iz magacina: " GET cBrFaktP VALID !Empty( cBrFaktP )
   @ box_x_koord() + 2, box_y_koord() + 2 SAY8 "pregled dokumenta prije potvrde: " GET cPregledDN PICT "@!" ;
      VALID pos_21_pregled_valid( @cPregledDN, cBrFaktP )

   @ box_x_koord() + 3, box_y_koord() + 2 SAY8 "Potvrda (D) Odbijanje prijema (N): " GET cPreuzimaSeDN ;
      VALID cPreuzimaSeDN $ "DN" PICT "@!"
   READ
   BoxC()

   IF LastKey() == K_ESC
      RETURN .F.
   ENDIF

   cBrFaktP := Trim( cBrFaktP )
   nRet := pos_21_to_22( cBrFaktP,  gIdRadnik, cPreuzimaSeDN == "D" )

   IF nRet >= 0
      // 0 - uspjesno, 10 - uspjesno za lPreuzimaSe false
      IF nRet == 0
         cMsg := "Roba po fakturi [" + cBrFaktP + "] na stanju :)"
      ELSE
         cMsg := "Prijem po fakturi [" + cBrFaktP + "] na ODBIJEN !"
      ENDIF
      MsgBeep( cMsg )
   ELSE
      Alert( _u( "Neuspješno izvršenje operacije [" + cBrFaktP +  "] ?! STATUS: " + AllTrim( Str( nRet ) )  ) )
      IF nRet == -2
         MsgBeep( "Već postoji dokument 22 sa brojem otpremnice [" + cBrFaktP + "]" )
      ENDIF
   ENDIF

   RETURN .T.


STATIC FUNCTION pos_21_pregled_valid( cPregledDN, cBrFaktP )

   LOCAL hParams := hb_Hash()

   hParams[ "idvd" ] := '21'
   hParams[ "brfaktp" ] := AllTrim( cBrFaktP )

   IF !( cPregledDN $ "DN" )
      RETURN .F.
   ENDIF

   IF !find_pos_doks_by_idvd_brfaktp( @hParams )
      Alert( 'Dokument 21 sa brojem optremnice [' + cBrFaktP + "] ne postoji ?!" )
      RETURN .T.
   ENDIF

   // pos_stampa_dokumenta( hParams )

   PushWa()
   hParams[ "priprema" ] := .F.
   pos_pregled_stavki_dokumenta( hParams[ "idpos" ], hParams[ "idvd" ], hParams[ "datum" ], hParams[ "brdok" ], " OTP:" + hParams[ "brfaktp"] )
   PopWa()

   RETURN .T.


FUNCTION pos_21_to_22( cBrFaktP, cIdRadnik, lPreuzimaSe )

   LOCAL cQuery, oRet, oError, nRet := -999, cLPreuzimaSe
   LOCAL cMsg

   IF lPreuzimaSe
      cLPreuzimaSe := "True"
   ELSE
      cLPreuzimaSe := "False"
   ENDIF
   cQuery := "SELECT " + pos_prodavnica_sql_schema() + ".pos_21_to_22(" + ;
      sql_quote( cBrFaktP ) + "," + ;
      sql_quote( cIdRadnik ) + "," + ;
      cLPreuzimaSe + ")"

   BEGIN SEQUENCE WITH {| err | Break( err ) }

      oRet := run_sql_query( cQuery )
      IF is_var_objekat_tpqquery( oRet )
         nRet := oRet:FieldGet( 1 )
      ENDIF

   RECOVER USING oError
      Alert( _u( "SQL neuspješno izvršenje 21->22 [" + cBrFaktP + "] ?" ) )
   END SEQUENCE

   RETURN nRet



FUNCTION pos_21_neobradjeni_lista()

   LOCAL aLista, nI
   LOCAL aMeni := {}
   LOCAL nIzbor := 1
   LOCAL nRet

   aLista := pos_21_get_lista()
   IF Len( aLista ) == 0
      RETURN  ""
   ENDIF

   FOR nI := 1 TO Len( aLista )
      AAdd( aMeni, PadR( iif( aLista[ nI ][ "storno" ], "POVRAT", "PRIJEM" ) + ": " + DToC( aLista[ nI ][ "datum" ] ) + " /" + aLista[ nI ][ "brdok" ] + " - " + aLista[ nI ][ "brfaktp" ], 40 ) )
   NEXT

   nRet := meni_fiksna_lokacija( box_x_koord() + 5, box_y_koord() + 10, aMeni, nIzbor )
   IF nRet == 0
      RETURN ""
   ENDIF

   RETURN aLista[ nRet ][ "brfaktp" ]


FUNCTION pos_21_get_lista()

   LOCAL cQuery, oData, oRow, oError, hRec, aLista := {}

   cQuery := "SELECT * FROM  " + pos_prodavnica_sql_schema() + ".pos_21_neobradjeni_dokumenti()"
   oData := run_sql_query( cQuery )

   DO WHILE !oData:Eof()
      oRow := oData:GetRow()
      hRec := hb_Hash()
      hRec[ "brdok" ] := oRow:FieldGet( oRow:FieldPos( "brdok" ) )
      hRec[ "datum" ] := oRow:FieldGet( oRow:FieldPos( "datum" ) )
      hRec[ "brfaktp" ] := oRow:FieldGet( oRow:FieldPos( "brfaktp" ) )
      hRec[ "storno" ] := oRow:FieldGet( oRow:FieldPos( "storno" ) )

      AAdd( aLista, hRec )
      oData:skip()
   ENDDO()

   RETURN aLista
