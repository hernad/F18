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

STATIC s_oPDF

MEMVAR cIdfirma // fn preduzece trazi privatnu varijablu

FUNCTION kalk_stampa_liste_dokumenata()

   LOCAL nCol1 := 0, cImeKup
   LOCAL nUl, nIzl, nRbr
   LOCAL cLinija
   LOCAL nC
   LOCAL GetList := {}

   LOCAL cIdVd
   LOCAL _n_col := 20
   LOCAL cFilterMkonto, cFilterPKonto
   LOCAL cPartnerNazivDN := "N"
   LOCAL cNaslov
   LOCAL bZagl, xPrintOpt
   LOCAL dDatOd, dDatDo
   LOCAL cBrojeviDokumenata, cMagacinskaKonta, cProdavnickaKonta

   PRIVATE qqTipDok

   PRIVATE cIdfirma := self_organizacija_id()

   my_close_all_dbf()
   dDatOd := CToD( "" )
   dDatDo := Date()
   cMagacinskaKonta := Space( 300 )
   cProdavnickaKonta := Space( 300 )
   cFilterPKonto := ""
   cFilterMkonto := ""
   cIdVd := ""

   Box(, 12, 75 )

   // PRIVATE cStampaj := "N"
   cBrojeviDokumenata := ""

   cIdFirma := fetch_metric( "kalk_lista_dokumenata_firma", my_user(), cIdFirma )
   cIdVd := fetch_metric( "kalk_lista_dokumenata_vd", my_user(), cIdVd )
   cBrojeviDokumenata := fetch_metric( "kalk_lista_dokumenata_brdok", my_user(), cBrojeviDokumenata )
   dDatOd := fetch_metric( "kalk_lista_dokumenata_datum_od", my_user(), dDatOd )
   dDatDo := fetch_metric( "kalk_lista_dokumenata_datum_do", my_user(), dDatDo )
   cMagacinskaKonta := fetch_metric( "kalk_lista_dokumenata_mkonto", my_user(), cMagacinskaKonta )
   cProdavnickaKonta := fetch_metric( "kalk_lista_dokumenata_pkonto", my_user(), cProdavnickaKonta )
   cPartnerNazivDN := fetch_metric( "kalk_lista_dokumenata_ispis_partnera", my_user(), cPartnerNazivDN )

   cIdVd := PadR( cIdVd, 2 )
   cBrojeviDokumenata := PadR( cBrojeviDokumenata, 60 )

   cImeKup := Space( 20 )
   cIdPartner := Space( 6 )

   DO WHILE .T.

      cIdFirma := PadR( cidfirma, 2 )
      @ box_x_koord() + 1, box_y_koord() + 2 SAY "Firma - prazno svi" GET cIdFirma VALID {|| .T. }
      READ
      IF !Empty( cidfirma )
         @ box_x_koord() + 2, box_y_koord() + 2 SAY "Tip dokumenta (prazno svi tipovi)" GET cIdVd PICT "@!"
         cIdVd := "  "
      ELSE
         cIdfirma := ""
      ENDIF

      @ box_x_koord() + 3, box_y_koord() + 2 SAY8 "Od datuma "  GET dDatOd
      @ box_x_koord() + 3, Col() + 1 SAY8 "do"  GET dDatDo
      @ box_x_koord() + 5, box_y_koord() + 2 SAY8 "Partner" GET cIdPartner PICT "@!" VALID Empty( cIdpartner ) .OR. p_partner( @cIdPartner )
      @ box_x_koord() + 6, box_y_koord() + 2 SAY8 " Magacinska konta:" GET cMagacinskaKonta PICT "@S30"
      @ box_x_koord() + 7, box_y_koord() + 2 SAY8 "Prodavnička konta:" GET cProdavnickaKonta PICT "@S30"
      @ box_x_koord() + 8, box_y_koord() + 2 SAY8 "Brojevi dokumenata (prazno-svi)" GET cBrojeviDokumenata PICT "@!S40"
      @ box_x_koord() + 10, box_y_koord() + 2 SAY8 "Ispis naziva partnera (D/N)?" GET cPartnerNazivDN PICT "@!" VALID cPartnerNazivDN $ "DN"
      // @ box_x_koord() + 12, box_y_koord() + 2 SAY8 "Štampanje sadržaja ovih dokumenata ?"  GET cStampaj PICT "@!" VALID cStampaj $ "DN"

      READ
      ESC_BCR

      cFilterBrDok := Parsiraj( cBrojeviDokumenata, "BRDOK" )
      IF !Empty( cMagacinskaKonta )
         cFilterMkonto := Parsiraj( cMagacinskaKonta, "mkonto" )
      ENDIF
      IF !Empty( cProdavnickaKonta )
         cFilterPKonto := Parsiraj( cProdavnickaKonta, "pkonto" )
      ENDIF

      IF cFilterBrDok <> NIL
         EXIT
      ENDIF

   ENDDO

   cIdVd := Trim( cIdVd )
   cBrojeviDokumenata := Trim( cBrojeviDokumenata )

   set_metric( "kalk_lista_dokumenata_firma", my_user(), cIdFirma )
   set_metric( "kalk_lista_dokumenata_vd", my_user(), cIdVd )
   set_metric( "kalk_lista_dokumenata_brdok", my_user(), cBrojeviDokumenata )
   set_metric( "kalk_lista_dokumenata_datum_od", my_user(), dDatOd )
   set_metric( "kalk_lista_dokumenata_datum_do", my_user(), dDatDo )
   set_metric( "kalk_lista_dokumenata_mkonto", my_user(), cMagacinskaKonta )
   set_metric( "kalk_lista_dokumenata_pkonto", my_user(), cProdavnickaKonta )
   set_metric( "kalk_lista_dokumenata_ispis_partnera", my_user(), cPartnerNazivDN )

   BoxC()

   IF Empty( cIdvd )
      cIdVd := NIL
   ENDIF
   find_kalk_doks_by_tip_datum( cIdFirma, cIdVd, dDatOd, dDatDo )

   PRIVATE cFilterLista := ".t."
   IF !Empty( cIdPartner )
      cFilterLista += ".and. idpartner==" + dbf_quote( cIdPartner )
   ENDIF
   IF !Empty( cBrojeviDokumenata )
      cFilterLista += ( ".and." + cFilterBrDok )
   ENDIF
   IF !Empty( cFilterMkonto )
      cFilterLista += ( ".and." + cFilterMkonto )
   ENDIF
   IF !Empty( cFilterPKonto )
      cFilterLista += ( ".and." + cFilterPKonto )
   ENDIF

   SET FILTER TO &cFilterLista
   GO TOP
   EOF CRET

   cNaslov := "KALK Lista dokumenata za period: " + DToC( dDatOd ) + "-" +  DToC( dDatDo ) + " NA DAN " + DToC( danasnji_datum() )
   s_oPDF := PDFClass():New()
   xPrintOpt := hb_Hash()
   xPrintOpt[ "tip" ] := "PDF"
   xPrintOpt[ "layout" ] := "landscape"
   xPrintOpt[ "opdf" ] := s_oPDF
   IF f18_start_print( NIL, xPrintOpt,  cNaslov ) == "X"
      RETURN .F.
   ENDIF

   bZagl := {|| zagl( cIdVd, cMagacinskaKonta, cProdavnickaKonta, cBrojeviDokumenata, cLinija ) }
   cLinija := get_linija()

   nC := 0
   nCol1 := 30
   nNV := nVPV := nRabat := nMPV := 0
   nUkStavki := 0

   Eval( bZagl )
   DO WHILE !Eof() .AND. kalk_doks->IdFirma == cIdFirma

      select_o_partner( kalk_doks->idpartner )
      SELECT kalk_doks

      check_nova_strana( bZagl, s_oPDF )
      ? Str( ++nC, 6 ) + "."
      info_bar( "k_lista", "kalk_stampa_liste_dok " + DToC( kalk_doks->datdok ) + Str( nC, 6 ) )

      @ PRow(), PCol() + 1 SAY field->datdok
      @ PRow(), PCol() + 1 SAY PadR( field->idfirma + "-" + field->idVd + "-" + field->brdok, 16 )

      IF field->idvd == "80"
         find_kalk_by_broj_dokumenta( kalk_doks->idfirma, kalk_doks->idvd, kalk_doks->brdok )
         IF !Empty( kalk->idkonto2 )
            @ PRow(), PCol() + 1 SAY PadR( AllTrim( field->idkonto ) + "->" + AllTrim( field->idkonto2 ), 15 )
         ELSE
            @ PRow(), PCol() + 1 SAY PadR( kalk_doks->mkonto, 7 )
            @ PRow(), PCol() + 1 SAY PadR( kalk_doks->pkonto, 7 )
         ENDIF
         SELECT kalk_doks
      ELSE
         @ PRow(), PCol() + 1 SAY PadR( kalk_doks->mkonto, 7 )
         @ PRow(), PCol() + 1 SAY PadR( kalk_doks->pkonto, 7 )
      ENDIF

      @ PRow(), _n_col := PCol() + 1 SAY PadR( field->idpartner, 6 )
      @ PRow(), PCol() + 1 SAY PadR( field->idzaduz, 6 )
      @ PRow(), PCol() + 1 SAY PadR( field->idzaduz2, 6 )

      nCol1 := PCol() + 1
      @ PRow(), PCol() + 1 SAY Str( kalk_doks->nv, 12, 2 )
      @ PRow(), PCol() + 1 SAY Str( kalk_doks->vpv, 12, 2 )
      @ PRow(), PCol() + 1 SAY Str( kalk_doks->rabat, 12, 2 )
      @ PRow(), PCol() + 1 SAY Str( kalk_doks->mpv, 12, 2 )
      @ PRow(), PCol() + 1 SAY kalk_doks->brfaktp
      @ PRow(), PCol() + 1 SAY kalk_doks->datval

      SELECT kalk_doks
      @ PRow(), PCol() + 1 SAY PadR( iif( Empty( sifra ), Space( 2 ), Left( CryptSC( kalk_doks->sifra ), 2 ) ), 6 )

      // drugi red
      IF cPartnerNazivDN == "D" .AND. !Empty( field->idpartner )
         ?
         @ PRow(), _n_col SAY AllTrim( partn->naz )
      ENDIF

      nNV += kalk_doks->NV
      nVPV += kalk_doks->VPV
      nRabat += kalk_doks->Rabat
      nMPV += kalk_doks->MPV
      SKIP

   ENDDO

   check_nova_strana( bZagl, s_oPDF, .F., 3 )
   ? cLinija
   ? "UKUPNO   "
   @ PRow(), nCol1 SAY Str( nNv, 12, 2 )
   @ PRow(), PCol() + 1 SAY Str( nVpv, 12, 2 )
   @ PRow(), PCol() + 1 SAY Str( nRabat, 12, 2 )
   @ PRow(), PCol() + 1 SAY Str( nMpv, 12, 2 )
   IF FieldPos( "sifra" ) <> 0
      ?? "       "
   ENDIF
   ? cLinija

   f18_end_print( NIL, xPrintOpt )
   my_close_all_dbf()

   RETURN .T.



STATIC FUNCTION zagl( cIdVd, cMagacinskaKonta, cProdavnickaKonta, cBrojeviDokumenata, cLinija )

   Preduzece()
   IF !Empty( cMagacinskaKonta )
      ? "Magacini:", Trim( cMagacinskaKonta )
   ENDIF
   IF !Empty( cProdavnickaKonta )
      ? "Prodavnice:", Trim( cProdavnickaKonta )
   ENDIF
   IF !Empty( cIdVd )
      ? "Tipovi dokumenata:", Trim( cIdVd )
   ENDIF
   IF !Empty( cBrojeviDokumenata )
      ? "Brojevi dokumenata:", Trim( cBrojeviDokumenata )
   ENDIF

   ? cLinija
   ? get_header()
   ? cLinija

   RETURN .T.

STATIC FUNCTION get_linija()

   LOCAL cLinija := ""

   cLinija += Replicate( "-", 7 )
   cLinija += Space( 1 )
   cLinija += Replicate( "-", 8 )
   cLinija += Space( 1 )
   cLinija += Replicate( "-", 16 )
   cLinija += Space( 1 )
   cLinija += Replicate( "-", 7 )
   cLinija += Space( 1 )
   cLinija += Replicate( "-", 7 )
   cLinija += Space( 1 )
   cLinija += Replicate( "-", 6 )
   cLinija += Space( 1 )
   cLinija += Replicate( "-", 6 )
   cLinija += Space( 1 )
   cLinija += Replicate( "-", 6 )
   cLinija += Space( 1 )
   cLinija += Replicate( "-", 12 )
   cLinija += Space( 1 )
   cLinija += Replicate( "-", 12 )
   cLinija += Space( 1 )
   cLinija += Replicate( "-", 12 )
   cLinija += Space( 1 )
   cLinija += Replicate( "-", 12 )
   cLinija += Space( 1 )
   cLinija += Replicate( "-", 10 )
   cLinija += Space( 1 )
   cLinija += Replicate( "-", 8 )
   cLinija += Space( 1 )
   cLinija += Replicate( "-", 6 )

   RETURN cLinija



STATIC FUNCTION get_header()

   LOCAL cHeader := ""

   cHeader += PadC( "Rbr", 7 )
   cHeader += Space( 1 )
   cHeader += PadC( "Datum", 8 )
   cHeader += Space( 1 )
   cHeader += PadC( "Dokument", 16 )
   cHeader += Space( 1 )
   cHeader += PadC( "cLinija-konto", 7 )
   cHeader += Space( 1 )
   cHeader += PadC( "P-konto", 7 )
   cHeader += Space( 1 )
   cHeader += PadC( "Part.", 6 )
   cHeader += Space( 1 )
   cHeader += PadC( "Zad.", 6 )
   cHeader += Space( 1 )
   cHeader += PadC( "Zad.2", 6 )
   cHeader += Space( 1 )
   cHeader += PadC( "NV", 12 )
   cHeader += Space( 1 )
   cHeader += PadC( "VPV", 12 )
   cHeader += Space( 1 )
   cHeader += PadC( "RABATV", 12 )
   cHeader += Space( 1 )
   cHeader += PadC( "MPV", 12 )
   cHeader += Space( 1 )
   cHeader += PadC( "brfaktp", 10 )
   cHeader += Space( 1 )
   cHeader += PadC( "DatVal", 8 )
   cHeader += Space( 1 )
   cHeader += PadC( "Op.", 6 )

   RETURN cHeader
