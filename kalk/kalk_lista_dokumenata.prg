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

FUNCTION kalk_stampa_liste_dokumenata()

   LOCAL nCol1 := 0, cImeKup
   LOCAL nUl, nIzl, nRbr
   LOCAL m
   LOCAL nC
   LOCAL GetList := {}

   LOCAL cIdVd
   LOCAL _head
   LOCAL _n_col := 20
   LOCAL _pkonto, _mkonto
   LOCAL _qqmkonto, _qqpkonto
   LOCAL _partn_naz := "N"

   PRIVATE qqTipDok
   PRIVATE ddatod, ddatdo
   PRIVATE cIdfirma := self_organizacija_id() // fn preduzece trazi privatnu varijablu

   my_close_all_dbf()

   dDatOd := CToD( "" )
   dDatDo := Date()
   _mkonto := Space( 300 )
   _pkonto := Space( 300 )
   _qqpkonto := ""
   _qqmkonto := ""

   cIdVd := ""

   Box(, 12, 75 )

   //PRIVATE cStampaj := "N"
   qqBrDok := ""

   cIdFirma := fetch_metric( "kalk_lista_dokumenata_firma", my_user(), cIdFirma )
   cIdVd := fetch_metric( "kalk_lista_dokumenata_vd", my_user(), cIdVd )
   qqBrDok := fetch_metric( "kalk_lista_dokumenata_brdok", my_user(), qqBrDok )
   dDatOd := fetch_metric( "kalk_lista_dokumenata_datum_od", my_user(), dDatOd )
   dDatDo := fetch_metric( "kalk_lista_dokumenata_datum_do", my_user(), dDatDo )
   _mkonto := fetch_metric( "kalk_lista_dokumenata_mkonto", my_user(), _mkonto )
   _pkonto := fetch_metric( "kalk_lista_dokumenata_pkonto", my_user(), _pkonto )
   _partn_naz := fetch_metric( "kalk_lista_dokumenata_ispis_partnera", my_user(), _partn_naz )

   cIdVd := PadR( cIdVd, 2 )
   qqBrDok := PadR( qqBrDok, 60 )

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
      @ box_x_koord() + 6, box_y_koord() + 2 SAY8 " Magacinska konta:" GET _mkonto PICT "@S30"
      @ box_x_koord() + 7, box_y_koord() + 2 SAY8 "Prodavnička konta:" GET _pkonto PICT "@S30"
      @ box_x_koord() + 8, box_y_koord() + 2 SAY8 "Brojevi dokumenata (prazno-svi)" GET qqBrDok PICT "@!S40"
      @ box_x_koord() + 10, box_y_koord() + 2 SAY8 "Ispis naziva partnera (D/N)?" GET _partn_naz PICT "@!" VALID _partn_naz $ "DN"
      //@ box_x_koord() + 12, box_y_koord() + 2 SAY8 "Štampanje sadržaja ovih dokumenata ?"  GET cStampaj PICT "@!" VALID cStampaj $ "DN"

      READ

      ESC_BCR

      aUsl1 := Parsiraj( qqBrDok, "BRDOK" )

      IF !Empty( _mkonto )
         _qqmkonto := Parsiraj( _mkonto, "mkonto" )
      ENDIF

      IF !Empty( _pkonto )
         _qqpkonto := Parsiraj( _pkonto, "pkonto" )
      ENDIF

      IF aUsl1 <> NIL
         EXIT
      ENDIF

   ENDDO

   cIdVd := Trim( cIdVd )
   qqBrDok := Trim( qqBrDok )

   set_metric( "kalk_lista_dokumenata_firma", my_user(), cIdFirma )
   set_metric( "kalk_lista_dokumenata_vd", my_user(), cIdVd )
   set_metric( "kalk_lista_dokumenata_brdok", my_user(), qqBrDok )
   set_metric( "kalk_lista_dokumenata_datum_od", my_user(), dDatOd )
   set_metric( "kalk_lista_dokumenata_datum_do", my_user(), dDatDo )
   set_metric( "kalk_lista_dokumenata_mkonto", my_user(), _mkonto )
   set_metric( "kalk_lista_dokumenata_pkonto", my_user(), _pkonto )
   set_metric( "kalk_lista_dokumenata_ispis_partnera", my_user(), _partn_naz )

   BoxC()

   IF Empty( cIdvd )
      cIdVd := NIL
   ENDIF
   find_kalk_doks_by_tip_datum( cIdFirma, cIdVd, dDatOd, dDatDo )


   PRIVATE cFilt := ".t."


   IF !Empty( cIdPartner )
      cFilt += ".and. idpartner==" + dbf_quote( cIdPartner )
   ENDIF

   IF !Empty( qqBrDok )
      cFilt += ( ".and." + aUsl1 )
   ENDIF

   IF !Empty( _qqmkonto )
      cFilt += ( ".and." + _qqmkonto )
   ENDIF

   IF !Empty( _qqpkonto )
      cFilt += ( ".and." + _qqpkonto )
   ENDIF

   SET FILTER TO &cFilt
   GO TOP


   EOF CRET

   gaZagFix := { 6, 3 }

   START PRINT CRET
   ?

   Preduzece()


   P_COND

   ??U "KALK: Štampa dokumenata na dan:", Date(), Space( 10 ), "za period", dDatOd, "-", dDatDo

   IF !Empty( cIdVd )
      ?? Space( 2 ), "za tipove dokumenta:", Trim( cIdVd )
   ENDIF

   IF !Empty( qqBrDok )
      ?? Space( 2 ), "za brojeve dokumenta:", Trim( qqBrDok )
   ENDIF

   m := _get_rpt_line()
   _head := _get_rpt_header()

   ? m
   ? _head
   ? m

   nC := 0
   nCol1 := 30
   nNV := nVPV := nRabat := nMPV := 0
   nUkStavki := 0

   DO WHILE !Eof() .AND. IdFirma == cIdFirma

      select_o_partner( kalk_doks->idpartner )

      SELECT kalk_doks

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

      @ PRow(), PCol() + 1 SAY Str( nv, 12, 2 )
      @ PRow(), PCol() + 1 SAY Str( vpv, 12, 2 )
      @ PRow(), PCol() + 1 SAY Str( rabat, 12, 2 )
      @ PRow(), PCol() + 1 SAY Str( mpv, 12, 2 )
      @ PRow(), PCol() + 1 SAY kalk_doks->brfaktp

      find_kalk_doks_by_broj_dokumenta( idfirma, idvd, brdok )
      @ PRow(), PCol() + 1 SAY kalk_doks->datval

      SELECT kalk_doks
      // IF FieldPos( "sifra" ) <> 0
      @ PRow(), PCol() + 1 SAY PadR( iif( Empty( sifra ), Space( 2 ), Left( CryptSC( sifra ), 2 ) ), 6 )
      // ENDIF


      // drugi red
      IF _partn_naz == "D" .AND. !Empty( field->idpartner )
         ?
         @ PRow(), _n_col SAY AllTrim( partn->naz )
      ENDIF

      nNV += NV
      nVPV += VPV
      nRabat += Rabat
      nMPV += MPV


      SKIP

   ENDDO

   ? m
   ? "UKUPNO   "

   @ PRow(), nCol1 SAY Str( nnv, 12, 2 )
   @ PRow(), PCol() + 1 SAY Str( nvpv, 12, 2 )
   @ PRow(), PCol() + 1 SAY Str( nrabat, 12, 2 )
   @ PRow(), PCol() + 1 SAY Str( nmpv, 12, 2 )

   IF FieldPos( "sifra" ) <> 0
      ?? "       "
   ENDIF

   ? m

   FF
   ENDPRINT

   my_close_all_dbf()

   RETURN .T.



STATIC FUNCTION _get_rpt_header()

   LOCAL _head := ""

   _head += PadC( "Rbr", 7 )
   _head += Space( 1 )
   _head += PadC( "Datum", 8 )
   _head += Space( 1 )
   _head += PadC( "Dokument", 16 )
   _head += Space( 1 )
   _head += PadC( "M-konto", 7 )
   _head += Space( 1 )
   _head += PadC( "P-konto", 7 )
   _head += Space( 1 )
   _head += PadC( "Part.", 6 )
   _head += Space( 1 )
   _head += PadC( "Zad.", 6 )
   _head += Space( 1 )
   _head += PadC( "Zad.2", 6 )
   _head += Space( 1 )
   _head += PadC( "NV", 12 )
   _head += Space( 1 )
   _head += PadC( "VPV", 12 )
   _head += Space( 1 )
   _head += PadC( "RABATV", 12 )
   _head += Space( 1 )
   _head += PadC( "MPV", 12 )
   _head += Space( 1 )
   _head += PadC( "brfaktp", 10 )
   _head += Space( 1 )
   _head += PadC( "DatVal", 8 )
   _head += Space( 1 )
   _head += PadC( "Op.", 6 )

   RETURN _head



STATIC FUNCTION _get_rpt_line()

   LOCAL _line := ""

   _line += Replicate( "-", 7 )
   _line += Space( 1 )
   _line += Replicate( "-", 8 )
   _line += Space( 1 )
   _line += Replicate( "-", 16 )
   _line += Space( 1 )
   _line += Replicate( "-", 7 )
   _line += Space( 1 )
   _line += Replicate( "-", 7 )
   _line += Space( 1 )
   _line += Replicate( "-", 6 )
   _line += Space( 1 )
   _line += Replicate( "-", 6 )
   _line += Space( 1 )
   _line += Replicate( "-", 6 )
   _line += Space( 1 )
   _line += Replicate( "-", 12 )
   _line += Space( 1 )
   _line += Replicate( "-", 12 )
   _line += Space( 1 )
   _line += Replicate( "-", 12 )
   _line += Space( 1 )
   _line += Replicate( "-", 12 )
   _line += Space( 1 )
   _line += Replicate( "-", 10 )
   _line += Space( 1 )
   _line += Replicate( "-", 8 )
   _line += Space( 1 )
   _line += Replicate( "-", 6 )

   RETURN _line
