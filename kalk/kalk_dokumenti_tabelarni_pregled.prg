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

   LOCAL cIdFirma := self_organizacija_id()
   LOCAL cIdVd := Space( 2 )
   LOCAL dDatOd := Date() - 7
   LOCAL dDatDo := Date()
   LOCAL cProdKto := PadR( "", 7 )
   LOCAL cMagKto := PadR( "", 7 )

   // LOCAL cPartner := PadR( "", 6 )
   LOCAL cFooter := ""
   LOCAL cHeader := "KALK pregled dokumenata"
   LOCAL hParams := hb_Hash()

   PRIVATE ImeKol
   PRIVATE Kol

   IF usl_browse_kalk_dokumenti( @cIdFirma, @cIdVd, @dDatOd, @dDatDo, @cMagKto, @cProdKto ) == 0
      RETURN .F.
   ENDIF



   IF cIdFirma <> NIL
      hParams[ "idfirma" ] := cIdFirma
   ENDIF

   IF !Empty( cIdVd )
      hParams[ "idvd" ] := cIdVd
   ENDIF

   IF !Empty( cMagKto )
      hParams[ "mkonto" ] := cMagKto
   ENDIF

   IF !Empty( cProdKto )
      hParams[ "pkonto" ] := cProdKto
   ENDIF

   IF dDatOd <> NIL .AND. !Empty( dDatOd )
      hParams[ "dat_od" ] := dDatOd
   ENDIF
   IF dDatDo <> NIL .AND. !Empty( dDatDo )
      hParams[ "dat_do" ] := dDatDo
   ENDIF


   // IF !Empty( cPartner )
   // hParams[ "idpartner" ] := cPartner
   // ENDIF

   hParams[ "order_by" ] := "idfirma, idvd, brdok, datdok" // ako ima vise brojeva dokumenata sortiraj po njima
   hParams[ "indeks" ] := .F.
   hParams[ "alias" ] := "KALK_DOKS2"
   hParams[ "wa" ] := F_KALK_DOKS2

   use_sql_kalk_doks( hParams )
   GO TOP

   Box(, f18_max_rows() - 5, f18_max_cols() - 8 )

   @ box_x_koord() + 18, box_y_koord() + 2 SAY ""
   @ box_x_koord() + 19, box_y_koord() + 2 SAY ""
   @ box_x_koord() + 20, box_y_koord() + 2 SAY ""

   set_a_kol( @ImeKol, @Kol )

   my_browse( "pregl", f18_max_rows() - 5, f18_max_cols() - 8, {|| brow_keyhandler( Ch ) }, cFooter, cHeader,,,,, 3 )

   BoxC()

   closeret

   RETURN .T.




STATIC FUNCTION set_a_kol( aImeKol, aKol )

   LOCAL i

   aImeKol := {}
   aKol := {}

   AAdd( aImeKol, { "F.",    {|| kalk_doks2->idfirma } } )
   AAdd( aImeKol, { "Tip", {|| kalk_doks2->idvd } } )
   AAdd( aImeKol, { "Broj",     {|| kalk_doks2->brdok } } )
   AAdd( aImeKol, { "Datum",    {|| kalk_doks2->datdok } } )
   AAdd( aImeKol, { "M.Konto",  {|| kalk_doks2->mkonto } } )
   AAdd( aImeKol, { "P.Konto",  {|| kalk_doks2->pkonto } } )
   AAdd( aImeKol, { "Partner",  {|| kalk_doks2->idpartner } } )
   AAdd( aImeKol, { "Dokument",   {|| kalk_doks2->Brfaktp } } )
   AAdd( aImeKol, { "NV",       {|| Transform( kalk_doks2->nv, kalk_pic_iznos_bilo_gpicdem() ) } } )
   AAdd( aImeKol, { "VPV",      {|| Transform( kalk_doks2->vpv, kalk_pic_iznos_bilo_gpicdem() ) } } )
   AAdd( aImeKol, { "MPV",      {|| Transform( kalk_doks2->mpv, kalk_pic_iznos_bilo_gpicdem() ) } } )


   FOR i := 1 TO Len( aImeKol )
      AAdd( aKol, i )
   NEXT

   RETURN .T.

/*
FUNCTION st_dok_status( cIdFirma, cIdVd, cBrDok )

   LOCAL nTArea := Select()
   LOCAL cStatus := "na stanju"

   IF cIdVd == "80" .AND. dok_u_procesu( cIdFirma, cIdVd, cBrDok )
      cStatus := "u procesu"
   ENDIF

   cStatus := PadR( cStatus, 10 )

   SELECT ( nTArea )

   RETURN cStatus
*/

STATIC FUNCTION brow_keyhandler( Ch )

   LOCAL GetList := {}
   LOCAL hRec
   LOCAL cBrFaktP
   LOCAL hParams

   DO CASE

      // CASE Ch == K_F2

      // hRec := dbf_get_rec()
      // cBrFaktP := hRec[ "brfaktp" ]

      // Box(, 3, 60 )
      // @ box_x_koord() + 1, box_y_koord() + 2 SAY "Ispravka podataka dokumenta ***"
      // @ box_x_koord() + 3, box_y_koord() + 2 SAY "Broj fakture:" GET cBrFaktP
      // READ
      // BoxC()

      // IF LastKey() == K_ESC
      // RETURN DE_CONT
      // ENDIF

      // hRec[ "brfaktp" ] := cBrFaktP
      // update_rec_server_and_dbf( "kalk_doks", hRec, 1, "FULL" )
      // RETURN DE_REFRESH

   CASE Ch == K_ENTER
      hParams := hb_Hash()
      hParams[ "idfirma" ] := kalk_doks2->idfirma
      hParams[ "idvd" ] := kalk_doks2->idvd
      hParams[ "brdok" ] := kalk_doks2->brdok
      PushWa()
      kalk_stampa_azuriranog_dokumenta_by_hparams( hParams )
      PopWa()
      RETURN DE_CONT

      // CASE Upper( Chr( Ch ) ) ==  "P"
      // // povrat dokumenta u pripremu
      // RETURN DE_CONT
   ENDCASE

   RETURN DE_CONT


STATIC FUNCTION usl_browse_kalk_dokumenti( cIdFirma, cIdVd, dDatOd, dDatDo, cMagKto, cProdKto )

   LOCAL nX := 1
   LOCAL GetList := {}

   Box(, 10, 65 )

   SET CURSOR ON

   @ nX + box_x_koord(), 2 + box_y_koord() SAY "Firma" GET cIdFirma

   ++nX
   @ nX + box_x_koord(), 2 + box_y_koord() SAY "Datumski period od" GET dDatOd
   @ nX + box_x_koord(), Col() + 1 SAY "do" GET dDatDo

   nX := nX + 2
   @ nX + box_x_koord(), 2 + box_y_koord() SAY8 "Vrsta dokumenta:   " GET cIdVd PICT "@S30"
   ++nX
   @ nX + box_x_koord(), 2 + box_y_koord() SAY8 "Magacinski konto:  " GET cMagKto PICT "@S30"

   ++nX
   @ nX + box_x_koord(), 2 + box_y_koord() SAY8 "Prodavnički konto: " GET cProdKto PICT "@S30"

   // nX := nX + 2
   // @ nX + box_x_koord(), 2 + box_y_koord() SAY8 "Partner:" GET cPartner VALID Empty( cPartner ) .OR. p_partner( @cPartner )

   READ
   BoxC()

   IF LastKey() == K_ESC
      RETURN 0
   ENDIF

   // cIdVd := Parsiraj( cIdVd, "idvd" )
   // cMagKto := Parsiraj( cMagKto, "mkonto" )
   // cProdKto := Parsiraj( cProdKto, "pkonto" )

   RETURN 1
