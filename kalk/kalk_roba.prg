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

STATIC s_lRobaBarkodPriUnosu := NIL

FUNCTION kalk_kartica_get_roba_id( cIdRoba, nX, nY, GetList )

   LOCAL bWhen, bValid

   // empty, "5;" - klasa sifri 5,
   IF roba_barkod_pri_unosu()
      bWhen := {|| cIdRoba := PadR( cIdRoba, roba_duzina_sifre() ), .T. }
      bValid := {|| cIdRoba := iif( Len( Trim( cIdRoba ) ) <= 10, Left( cIdRoba, 10 ), cIdRoba ), ;
         Empty( cIdRoba ) .OR. Right( Trim( cIdRoba ), 1 ) == ";" .OR. P_Roba( @cIdRoba ) }
   ELSE
      bWhen := {|| .T. }
      bValid := {|| Empty( cIdroba ) .OR. Right( Trim( cIdRoba ), 1 ) == ";" .OR. P_Roba( @cIdRoba ) }
   ENDIF

   @ nX, nY SAY "Roba  " GET cIdRoba WHEN Eval( bWhen )  VALID  Eval( bValid ) PICT "@!S10"

   IF roba_barkod_pri_unosu()
      cIdRoba := PadR( cIdRoba, 10 )
   ENDIF

   RETURN .T.


FUNCTION kalk_unos_get_roba_id( GetList, cIdRoba, cIdTarifa, cIdVd, lNoviDokument, nKoordX, nKoordY, cIdPartner )

   LOCAL bWhen, bValid, cProdMag := "M"

   IF roba_barkod_pri_unosu()
      bWhen := {|| cIdRoba := PadR( cIdRoba, roba_duzina_sifre() ), .T. }
   ELSE
      bWhen := {|| .T. }
   ENDIF

   IF cIdvd $ "80#81"
      cProdMag := "P"
   ENDIF

   bValid := {|| kalk_valid_roba( @cIdRoba, @cIdTarifa, lNoviDokument ), ;
      ispisi_naziv_roba( nKoordX, 25, 41 ), ;
      /* kalk_zadnji_ulazi_info( cIdpartner, cIdroba, cProdMag ), */ !Empty( cIdRoba ) }

   // _ocitani_barkod := _idroba, ;
   // P_Roba( @_IdRoba ), ;
   // if ( !tezinski_barkod_get_tezina( @_ocitani_barkod, @_kolicina ), .T., .T. ), ;
   @ nKoordX, nKoordY SAY "Artikal: " GET cIdRoba PICT "@!S10" WHEN  Eval( bWhen ) VALID Eval( bValid )

   RETURN .T.


FUNCTION roba_duzina_sifre()

   IF roba_barkod_pri_unosu()
      RETURN 13
   ENDIF

   RETURN 10


STATIC FUNCTION kalk_valid_roba( cIdRoba, cIdTarifa, lNoviDokument )

   //LOCAL _tezina := 0
   //LOCAL _ocitani_barkod := cIdRoba
   //LOCAL cTarifa

   P_Roba( @cIdRoba )

   select_o_tarifa( roba->idtarifa )
   cIdTarifa := tarifa->id

   // IF tezinski_barkod_get_tezina( _ocitani_barkod, @_tezina ) .AND. _tezina <> 0 // momenat kada mozemo ocitati tezinu iz barkod-a ako se koristi
   // _kolicina := _tezina // ako je ocitan tezinski barkod
   // IF _idvd == "80" .AND. ( !Empty( _idkonto2 ) .AND. _idkonto2 <> "XXX" ) // kod predispozicije kolicina treba biti negativna kod prvog ocitanja
   // _kolicina := -_kolicina
   // ENDIF

   // ENDIF

   RETURN .T.



FUNCTION roba_barkod_pri_unosu( lSet )

   IF s_lRobaBarkodPriUnosu == NIL
      s_lRobaBarkodPriUnosu := fetch_metric( "kalk_koristiti_barkod_pri_unosu", my_user(), .F. )
   ENDIF

   IF lSet != NIL
      set_metric( "kalk_koristiti_barkod_pri_unosu", my_user(), lSet )
      s_lRobaBarkodPriUnosu :=  lSet
   ENDIF

   // lKoristitiB-K := fetch_metric( "kalk_koristiti_barkod_pri_unosu", my_user(), lKoristitiB-K )
   // set_metric( "kalk_koristiti_barkod_pri_unosu", my_user(), lKoristitiB-K )

   RETURN s_lRobaBarkodPriUnosu


/*
FUNCTION kalk_zadnji_ulazi_info( cIdPartner, cIdRoba, cProdMag )

   LOCAL aData := {}
   LOCAL nCount := 3

   IF cIdPartner == NIL
      RETURN .T.
   ENDIF

   IF fetch_metric( "pregled_rabata_kod_ulaza", my_user(), "N" ) == "N"
      RETURN .T.
   ENDIF

   IF cProdMag == NIL
      cProdMag := "P"
   ENDIF

   aData := kalk_get_ulazi( cIdPartner, cIdRoba, cProdMag )
   IF Len( aData ) > 0
      kalk_podaci_o_rabatima( aData, cProdMag, nCount )
   ENDIF

   RETURN .T.
*/

STATIC FUNCTION kalk_get_ulazi( cIdPartner, cIdRoba, cMagIliProd )

   LOCAL cQuery, oQuery
   LOCAL aData := {}
   LOCAL nI, oRow
   LOCAL _u_i := "pu_i"

   IF cMagIliProd == "M"
      _u_i := "mu_i"
   ENDIF

   cQuery := "SELECT idkonto, idvd, brdok, datdok, fcj, rabat FROM " + f18_sql_schema( "kalk_kalk" ) + " WHERE idfirma = " + ;
      sql_quote( self_organizacija_id() ) + ;
      " AND idpartner = " + sql_quote( cIdPartner ) + ;
      " AND idroba = " + sql_quote( cIdRoba ) + ;
      " AND " + _u_i + " = " + sql_quote( "1" ) + ;
      " ORDER BY datdok"

   oQuery := run_sql_query( cQuery )
   oQuery:GoTo( 1 )

   FOR nI := 1 TO oQuery:LastRec()
      oRow := oQuery:GetRow( nI )
      AAdd( aData, { oRow:FieldGet( oRow:FieldPos( "idkonto" ) ), ;
         oRow:FieldGet( oRow:FieldPos( "idvd" ) ) + "-" + AllTrim( oRow:FieldGet( oRow:FieldPos( "brdok" ) ) ), ;
         oRow:FieldGet( oRow:FieldPos( "datdok" ) ), ;
         oRow:FieldGet( oRow:FieldPos( "fcj" ) ), ;
         oRow:FieldGet( oRow:FieldPos( "rabat" ) ) } )
   NEXT

   RETURN aData


FUNCTION kalk_podaci_o_rabatima( aUlazi, cMagIliProd, nUlaziCount )

   LOCAL GetList := {}
   LOCAL cLine := ""
   LOCAL cHeader := ""
   LOCAL cNastavi := " "
   LOCAL nX := 4
   LOCAL nI, nLen

   nLen := Len( aUlazi )
   cHeader := PadR( iif( cMagIliProd == "F", "FIRMA", "KONTO" ), 7 )
   cHeader += " "
   cHeader += PadR( "DOKUMENT", 10 )
   cHeader += " "
   cHeader += PadR( "DATUM", 8 )
   cHeader += " "
   cHeader += PadL( IF ( cMagIliProd == "F", "CIJENA", "NC" ), 12 )
   cHeader += " "
   cHeader += PadL( "RABAT", 13 )

   DO WHILE .T.

      nX := 4
      Box(, 5 + nUlaziCount, 60 )
      @ box_x_koord() + 1, box_y_koord() + 2 SAY PadR( "*** Pregled rabata", 59 ) COLOR f18_color_i()
      @ box_x_koord() + 2, box_y_koord() + 2 SAY cHeader
      @ box_x_koord() + 3, box_y_koord() + 2 SAY Replicate( "-", 59 )

      FOR nI := nLen TO ( nLen - nUlaziCount ) STEP -1

         IF nI > 0
            cLine := PadR( aUlazi[ nI, 1 ], 7 )
            cLine += " "
            cLine += PadR( aUlazi[ nI, 2 ], 10 )
            cLine += " "
            cLine += DToC( aUlazi[ nI, 3 ] )
            cLine += " "
            cLine += Str( aUlazi[ nI, 4 ], 12, 3 )
            cLine += " "
            cLine += Str( aUlazi[ nI, 5 ], 12, 3 ) + "%"
            @ box_x_koord() + nX, box_y_koord() + 2 SAY cLine
            ++nX

         ENDIF
      NEXT

      @ box_x_koord() + nX, box_y_koord() + 2 SAY Replicate( "-", 59 )
      ++nX
      @ box_x_koord() + nX, box_y_koord() + 2 SAY "Pritisni 'ENTER' za nastavak ..." GET cNastavi
      READ

      BoxC()
      IF LastKey() == K_ENTER
         EXIT
      ENDIF

   ENDDO

   RETURN .T.
