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

FUNCTION kalk_89_to_81_unos()

   LOCAL cIdFirma := self_organizacija_id()
   LOCAL cBrDok
   LOCAL GetList := {}
   LOCAL nRet

   cBrDok := kalk_89_odabir_brdok_iz_liste()
   IF Empty( cBrDok )
      MsgBeep( "Nema dokumenata prema zadatom kriteriju ?" )
      cBrDok := Space( FIELD_LEN_KALK_BRDOK )
      RETURN .F.
   ENDIF

   Box(, 3, 60 )
   @ box_x_koord() + 1, box_y_koord() + 2 SAY8 "Broj dokumenta 89: " GET cBrDok
   READ
   BoxC()

   IF LastKey() == K_ESC
      RETURN .F.
   ENDIF

   // cBrDok := PadL(AllTrim( cBrDok ), FIELD_LEN_KALK_BRDOK, '0')
   nRet := kalk_89_to_81( cBrDok )

   IF nRet == 0
      IF kalk_povrat_dokumenta_by_idfirma_idvd_brdok( cIdFirma, '81', cBrDok )
         MsgBeep( "U pripremi se nalazi dokument 81-" + cBrDok )
         kalk_pripr_set_idpartner()
         kalk_pripr_obrada( .F. )
      ELSE
         MsgBeep( "89-" + cBrDok + "povrat u pripremu neuspješan?!" )
      ENDIF
   ELSE
      Alert( _u( "Neuspješno izvršenje operacije 89->81 Status:" + AllTrim( Str( nRet ) ) + " ?!" ) )
   ENDIF

   RETURN .T.


FUNCTION kalk_89_odabir_brdok_iz_liste()

   LOCAL GetList := {}
   LOCAL nProdavnica := 0, dDatum := danasnji_datum(), aLista, nI
   LOCAL aMeni := {}
   LOCAL nIzbor := 1
   LOCAL nRet := 0

   nProdavnica := fetch_metric( "prod_89", my_user(), nProdavnica )
   dDatum := fetch_metric( "prod_89_dat", my_user(), dDatum )

   Box(, 3, 60 )
   @ box_x_koord() + 1, box_y_koord() + 2 SAY8 "Prodavnica: " GET nProdavnica PICT "999" VALID nProdavnica > 0
   @ box_x_koord() + 2, box_y_koord() + 2 SAY8 "     Datum: " GET dDatum
   READ
   BoxC()
   IF LastKey() == K_ESC
      RETURN ""
   ENDIF

   set_metric( "prod_89", my_user(), nProdavnica )
   set_metric( "prod_89_dat", my_user(), dDatum )

   aLista := kalk_89_get_lista( nProdavnica, dDatum )
   IF Len( aLista ) == 0
      RETURN ""
   ENDIF

   FOR nI := 1 TO Len( aLista )
      AAdd( aMeni, PadR( "PROD " + aLista[ nI ][ "prod" ] + ": " + aLista[ nI ][ "dan" ] + "." + aLista[ nI ][ "mjesec" ] + " / " + aLista[ nI ][ "pos_broj" ], 30 ) )
   NEXT

   nRet := meni_fiksna_lokacija( box_x_koord() + 3, box_y_koord() + 10, aMeni, nIzbor )
   IF nRet == 0
      RETURN ""
   ENDIF

   RETURN aLista[ nRet ][ "brdok" ]

// FUNCTION public.kalk_71_to_79_dokumenti( nProdavnica integer, dDatum date )
// RETURNS TABLE (brdok varchar, prodavnica varchar, mjesec varchar, dan varchar, broj varchar )

FUNCTION kalk_89_get_lista( nProdavnica, dDatum )

   LOCAL cQuery, oData, oRow, oError, hRec, aLista := {}

   cQuery := "SELECT * FROM public.kalk_89_to_81_dokumenti(" + ;
      sql_quote( nProdavnica ) + "," + ;
      sql_quote( dDatum ) + ")"

   oData := run_sql_query( cQuery )
   DO WHILE !oData:Eof()
      oRow := oData:GetRow()
      hRec := hb_Hash()
      hRec[ "brdok" ] := oRow:FieldGet( 1 )
      hRec[ "prod" ] := oRow:FieldGet( 2 )
      hRec[ "mjesec" ] := oRow:FieldGet( 3 )
      hRec[ "dan" ] := oRow:FieldGet( 4 )
      hRec[ "pos_broj" ] := oRow:FieldGet( 5 )
      AAdd( aLista, hRec )
      oData:skip()
   ENDDO()

   RETURN aLista



// FUNCTION public.kalk_71_to_79( cBrDok varchar ) RETURNS integer

FUNCTION kalk_89_to_81( cBrDok )

   LOCAL cQuery, oRet, oError, nRet := -999

   cQuery := "SELECT public.kalk_89_to_81(" + ;
      sql_quote( cBrDok ) + ")"

   BEGIN SEQUENCE WITH {| err | Break( err ) }

      oRet := run_sql_query( cQuery )
      IF is_var_objekat_tpqquery( oRet )
         nRet := oRet:FieldGet( 1 )
      ENDIF

   RECOVER USING oError
      Alert( _u( "SQL neuspješno izvršenje 89->81 [" + AllTrim( Str( nRet ) ) + "] ?" ) )
   END SEQUENCE

   RETURN nRet


STATIC FUNCTION kalk_pripr_set_idpartner()

   LOCAL cIdPartner

   PushWa()
   SELECT F_KALK_PRIPR
   use
   o_kalk_pripr()
   GO TOP
   cIdPartner := kalk_doks_idpartner_by_brdok( kalk_pripr->IdFirma, "89", kalk_pripr->BrDok )
   SET ORDER TO
   DO WHILE !Eof()
      rreplace idpartner WITH cIdPartner
      SKIP
   ENDDO
   USE
   PopWa()

   RETURN .T.
