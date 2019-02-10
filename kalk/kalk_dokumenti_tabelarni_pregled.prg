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

MEMVAR ImeKol, Kol

FUNCTION kalk_pregled_dokumenata_tabela()

   LOCAL cFirma := self_organizacija_id()
   LOCAL cIdVd := PadR( "", 30 )
   LOCAL dDatOd := Date() - 7
   LOCAL dDatDo := Date()
   LOCAL cProdKto := PadR( "", 50 )
   LOCAL cMagKto := PadR( "", 50 )
   LOCAL cPartner := PadR( "", 6 )
   LOCAL cFooter := ""
   LOCAL cHeader := "KALK pregled dokumenata"
   PRIVATE ImeKol
   PRIVATE Kol

   IF usl_browse_kalk_dokumenti( @cFirma, @cIdVd, @dDatOd, @dDatDo, @cMagKto, @cProdKto, @cPartner ) == 0
      RETURN .F.
   ENDIF

   find_kalk_doks_by_tip_datum( cFirma, NIL, dDatOd, dDatDo )
   set_filter_kalk_doks( cFirma, cIdVd, dDatOd, dDatDo, cMagKto, cProdKto, cPartner )
   GO TOP

   Box(, 20, 77 )

   @ box_x_koord() + 18, box_y_koord() + 2 SAY ""
   @ box_x_koord() + 19, box_y_koord() + 2 SAY ""
   @ box_x_koord() + 20, box_y_koord() + 2 SAY ""

   set_a_kol( @ImeKol, @Kol )

   my_browse( "pregl", 20, 77, {|| brow_keyhandler( Ch ) }, cFooter, cHeader,,,,, 3 )

   BoxC()

   closeret

   RETURN .T.


STATIC FUNCTION set_filter_kalk_doks( cFirma, cIdVd, dDatOd, dDatDo, cMagKto, cProdKto, cPartner )

   LOCAL cFilter := ".t."

   IF !Empty( cFirma )
      cFilter += " .and. idfirma == " + dbf_quote( cFirma )
   ENDIF

   IF !Empty( cIdVd )
      cFilter += " .and. " + cIdVd
   ENDIF

   IF !Empty( DToS( dDatOd ) )
      cFilter += " .and. DTOS(datdok) >= " + dbf_quote( DToS( dDatOd ) )
   ENDIF

   IF !Empty( DToS( dDatDo ) )
      cFilter += " .and. DTOS(datdok) <= " + dbf_quote( DToS( dDatDo ) )
   ENDIF

   IF !Empty( cMagKto )
      cFilter += " .and. " + cMagKto
   ENDIF

   IF !Empty( cProdKto )
      cFilter += " .and. " + cProdKto
   ENDIF

   IF !Empty( cPartner )
      cFilter += " .and. idpartner == " + dbf_quote( cPartner )
   ENDIF

   MsgO( "pripremam pregled ... sacekajte trenutak !" )
   SELECT kalk_doks
   SET FILTER to &cFilter
   GO TOP
   MsgC()

   RETURN .T.



STATIC FUNCTION set_a_kol( aImeKol, aKol )

   LOCAL i

   aImeKol := {}
   aKol := {}

   AAdd( aImeKol, { "F.",    {|| kalk_doks->idfirma } } )
   AAdd( aImeKol, { "Tip", {|| kalk_doks->idvd } } )
   AAdd( aImeKol, { "Broj",     {|| kalk_doks->brdok } } )
   AAdd( aImeKol, { "Datum",    {|| kalk_doks->datdok } } )
   AAdd( aImeKol, { "M.Konto",  {|| kalk_doks->mkonto } } )
   AAdd( aImeKol, { "P.Konto",  {|| kalk_doks->pkonto } } )
   AAdd( aImeKol, { "Partner",  {|| kalk_doks->idpartner } } )
   AAdd( aImeKol, { "NV",       {|| Transform( kalk_doks->nv, kalk_pic_iznos_bilo_gpicdem() ) } } )
   AAdd( aImeKol, { "VPV",      {|| Transform( kalk_doks->vpv, kalk_pic_iznos_bilo_gpicdem() ) } } )
   AAdd( aImeKol, { "MPV",      {|| Transform( kalk_doks->mpv, kalk_pic_iznos_bilo_gpicdem() ) } } )
   AAdd( aImeKol, { "Dokument",   {|| kalk_doks->Brfaktp }                           } )

   FOR i := 1 TO Len( aImeKol )
      AAdd( aKol, i )
   NEXT

   RETURN .T.


FUNCTION st_dok_status( cFirma, cIdVd, cBrDok )

   LOCAL nTArea := Select()
   LOCAL cStatus := "na stanju"

   IF cIdVd == "80" .AND. dok_u_procesu( cFirma, cIdVd, cBrDok )
      cStatus := "u procesu"
   ENDIF

   cStatus := PadR( cStatus, 10 )

   SELECT ( nTArea )

   RETURN cStatus


STATIC FUNCTION brow_keyhandler( Ch )

   LOCAL GetList := {}
   LOCAL hRec
   LOCAL cBrFaktP

   DO CASE

   CASE Ch == K_F2

      hRec := dbf_get_rec()
      cBrFaktP := hRec[ "brfaktp" ]

      Box(, 3, 60 )
      @ box_x_koord() + 1, box_y_koord() + 2 SAY "Ispravka podataka dokumenta ***"
      @ box_x_koord() + 3, box_y_koord() + 2 SAY "Broj fakture:" GET cBrFaktP
      READ
      BoxC()

      IF LastKey() == K_ESC
         RETURN DE_CONT
      ENDIF

      hRec[ "brfaktp" ] := cBrFaktP
      update_rec_server_and_dbf( "kalk_doks", hRec, 1, "FULL" )
      RETURN DE_REFRESH

   CASE Ch == K_ENTER
      kalk_stampa_azuriranog_dokumenta_na_osnovu_doks()
      RETURN DE_CONT

   CASE Upper( Chr( Ch ) ) ==  "P"
      // povrat dokumenta u pripremu
      RETURN DE_CONT
   ENDCASE

   RETURN DE_CONT


STATIC FUNCTION usl_browse_kalk_dokumenti( cFirma, cIdVd, dDatOd, dDatDo, cMagKto, cProdKto, cPartner )

   LOCAL nX := 1
   LOCAL GetList := {}

   Box(, 10, 65 )

   SET CURSOR ON

   @ nX + box_x_koord(), 2 + box_y_koord() SAY "Firma" GET cFirma

   ++ nX
   @ nX + box_x_koord(), 2 + box_y_koord() SAY "Datumski period od" GET dDatOd
   @ nX + box_x_koord(), Col() + 1 SAY "do" GET dDatDo

   nX := nX + 2
   @ nX + box_x_koord(), 2 + box_y_koord() SAY8 "Vrsta dokumenta (prazno-svi)" GET cIdVd PICT "@S30"
   ++ nX
   @ nX + box_x_koord(), 2 + box_y_koord() SAY8 "Magacinski konto (prazno-svi)" GET cMagKto PICT "@S30"

   ++ nX
   @ nX + box_x_koord(), 2 + box_y_koord() SAY8 "Prodavnički konto (prazno-svi)" GET cProdKto PICT "@S30"

   nX := nX + 2
   @ nX + box_x_koord(), 2 + box_y_koord() SAY8 "Partner:" GET cPartner VALID Empty( cPartner ) .OR. p_partner( @cPartner )

   READ
   BoxC()

   IF LastKey() == K_ESC
      RETURN 0
   ENDIF

   cIdVd := Parsiraj( cIdVd, "idvd" )
   cMagKto := Parsiraj( cMagKto, "mkonto" )
   cProdKto := Parsiraj( cProdKto, "pkonto" )

   RETURN 1
