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

THREAD STATIC PIC_IZN := "999999999.99"
THREAD STATIC _NUM := 12
THREAD STATIC _DEC := 2
THREAD STATIC _ZAOK := 2
THREAD STATIC _FNUM := 15
THREAD STATIC _FDEC := 4


FUNCTION fakt_real_maloprodaje()

   LOCAL nOperater
   LOCAL cFirma
   LOCAL dD_from
   LOCAL dD_to
   LOCAL cDocType
   LOCAL nVar
   LOCAL nT_uk := 0
   LOCAL nT_pdv := 0
   LOCAL nT_osn := 0
   LOCAL _params

   IF ! fakt_mp_uzmi_parametre_izvjestaja( @_params )
      RETURN .F.
   ENDIF

   fakt_realiz_pdv_cre_open_r_export_table()
   fakt_gen_rekapitulacija_mp( _params )

   SELECT r_export
   IF Reccount2() == 0
      MsgBeep( "Nema podataka za prikaz !" )
      my_close_all_dbf()
      RETURN .F.
   ENDIF

   IF !start_print()
      RETURN .F.
   ENDIF

   ?
   ? "REALIZACIJA PRODAJE na dan: " + DToC( Date() ), Space( 6 ), f18_ver_info()
   ? Replicate( "-", 80 )
   ? "Period od:" + DToC( _params[ "datum_od" ] ) + " do:" + DToC( _params[ "datum_do" ] )
   ?

   P_COND

   fakt_mp_set_totali( @nT_osn, @nT_pdv, @nT_uk )

   fakt_mp_po_operaterima()
   fakt_mp_po_vrstama_placanja()

   IF _params[ "tip_partnera" ] == "D"
      ?
      fakt_mp_po_tipu_partnera()
   ENDIF

   ?
   IF _params[ "varijanta" ] = 1
      fakt_mp_po_robama()
   ELSEIF _params[ "varijanta" ] = 2
      fakt_mp_po_dokumentima()
   ENDIF

   ?

   P_10CPI

   ? "REKAPITULACIJA:"
   ? "---------------------------"
   ? "1) ukupno bez pdv-a:"
   @ PRow(), PCol() + 1 SAY Str( nT_osn, _NUM, _DEC ) PICT PIC_IZN
   ? "2) vrijednost pdv-a:"
   @ PRow(), PCol() + 1 SAY Str( nT_pdv, _NUM, _DEC ) PICT PIC_IZN
   ? "3)    ukupno sa pdv:"
   @ PRow(), PCol() + 1 SAY Str( nT_uk, _NUM, _DEC ) PICT PIC_IZN

   FF
   end_print()

   RETURN .T.


STATIC FUNCTION fakt_mp_uzmi_parametre_izvjestaja( hParams )

   LOCAL nX := 1
   LOCAL _tip_partnera, cIdFirma, _d_from, _d_to, _dok_tip, _operater, _varijanta
   LOCAL _partner, _vrsta_p
   LOCAL GetList := {}

   cIdFirma := PadR( fetch_metric( "fakt_real_mp_firma", my_user(), "" ), 100 )
   _d_from := fetch_metric( "fakt_real_mp_datum_od", my_user(), Date() )
   _d_to := fetch_metric( "fakt_real_mp_datum_do", my_user(), Date() )
   _dok_tip := PadR( fetch_metric( "fakt_real_mp_tip_dok", my_user(), "11;" ), 100 )
   _operater := fetch_metric( "fakt_real_mp_operater", my_user(), 0 )
   _vrsta_p := fetch_metric( "fakt_real_mp_vrsta_p", my_user(), Space( 2 ) )
   _varijanta := fetch_metric( "fakt_real_mp_varijanta", my_user(), 1 )
   _tip_partnera := fetch_metric( "fakt_real_mp_tip_partnera", my_user(), "D" )
   _partner := PadR( fetch_metric( "fakt_real_mp_partner", my_user(), "" ), 200 )

   Box( , 14, 66 )

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "**** REALIZACIJA PRODAJE ****"
   nX += 2
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Firma (prazno-sve):" GET cIdFirma PICT "@S20"
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Obuhvatiti period od:" GET _d_from
   @ box_x_koord() + nX, Col() + 1 SAY "do:" GET _d_to
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Vrste dokumenata:" GET _dok_tip PICT "@S30"
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Partner (prazno-svi):" GET _partner PICT "@S40"
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Vrsta plaćanja (prazno-svi):" GET _vrsta_p VALID Empty( _vrsta_p ) .OR. P_VRSTEP( @_vrsta_p )
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Operater (0-svi):" GET _operater PICT "9999999999" ;
      VALID {|| _operater == 0, iif( _operater == -99, choose_f18_user_from_list( @_operater ), .T. ) }
   nX += 2
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Razvrstati po tipu partnera (D/N)?" GET _tip_partnera VALID _tip_partnera $ "DN" PICT "@!"
   nX += 2
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Varijanta prikaza 1-po robi 2-po dokumentima"
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "                  3-samo total" GET _varijanta PICT "9"

   READ
   BoxC()

   IF LastKey() == K_ESC
      RETURN .F.
   ENDIF

   set_metric( "fakt_real_mp_firma", my_user(), AllTrim( cIdFirma ) )
   set_metric( "fakt_real_mp_datum_od", my_user(), _d_from )
   set_metric( "fakt_real_mp_datum_do", my_user(), _d_to )
   set_metric( "fakt_real_mp_tip_dok", my_user(), AllTrim( _dok_tip ) )
   set_metric( "fakt_real_mp_operater", my_user(), _operater )
   set_metric( "fakt_real_mp_vrsta_p", my_user(), _vrsta_p )
   set_metric( "fakt_real_mp_varijanta", my_user(), _varijanta )
   set_metric( "fakt_real_mp_tip_partnera", my_user(), _tip_partnera )
   set_metric( "fakt_real_mp_partner", my_user(), AllTrim( _partner ) )

   // snimi parametre i matricu
   hParams := hb_Hash()
   hParams[ "datum_od" ] := _d_from
   hParams[ "datum_do" ] := _d_to
   hParams[ "varijanta" ] := _varijanta
   hParams[ "cIdTipDok" ] := AllTrim( _dok_tip )
   hParams[ "operater" ] := _operater
   hParams[ "firma" ] := AllTrim( cIdFirma )
   hParams[ "tip_partnera" ] := _tip_partnera
   hParams[ "partner" ] := _partner
   hParams[ "vrstap" ] := _vrsta_p

   RETURN .T.


STATIC FUNCTION fakt_gen_rekapitulacija_mp( hParams )

   LOCAL cFaktDoksFilter
   LOCAL cIdFirmaTekuci
   LOCAL cIdTipDokTekuci
   LOCAL cBrDokTekuci
   LOCAL nUkupno
   LOCAL _tip_partnera := "1"
   LOCAL _pdv_broj := ""
   LOCAL lOslobodjenPDV
   LOCAL dDatDo, dDatOd, _varijanta, _tip_dok, _operater, cIdFirma, lPoTipovimaPartnera
   LOCAL _vrsta_p, _partner, _oper_id
   LOCAL nCjPDV, nCj2PDV, nCjBPDV, nCj2BPDV, nVPopust, nPPDV
   LOCAL  nKol, nRCijen, nPopust, nVPDV

   LOCAL cRoba_id, cPart_id

   //o_fakt_doks_dbf()
   //o_fakt_dbf()
   //o_roba()
   //o_sifk()
   //o_sifv()
   //o_vrstep()
   //o_tarifa()
   //o_partner()

   // parametri
   dDatOd := hParams[ "datum_od" ]
   dDatDo := hParams[ "datum_do" ]
   _varijanta := hParams[ "varijanta" ]
   _tip_dok := hParams[ "cIdTipDok" ]
   _operater := hParams[ "operater" ]
   cIdFirma := hParams[ "firma" ]
   lPoTipovimaPartnera := hParams[ "tip_partnera" ] == "D"
   _partner := hParams[ "partner" ]
   _vrsta_p := hParams[ "vrstap" ]

   cFaktDoksFilter := ""

   IF !Empty( cIdFirma )
      cFaktDoksFilter += Parsiraj( AllTrim( cIdFirma ), "idfirma" )
   ENDIF

   IF !Empty( _vrsta_p )
      IF !Empty( cFaktDoksFilter )
         cFaktDoksFilter += ".and."
      ENDIF
      cFaktDoksFilter += "idvrstep = " + _filter_quote( _vrsta_p )
   ENDIF

   IF _operater <> 0
      IF !Empty( cFaktDoksFilter )
         cFaktDoksFilter += ".and."
      ENDIF
      cFaktDoksFilter += "oper_id = " + _filter_quote( _operater )
   ENDIF

   IF !Empty( _tip_dok )
      IF !Empty( cFaktDoksFilter )
         cFaktDoksFilter += ".and."
      ENDIF
      cFaktDoksFilter += Parsiraj( AllTrim( _tip_dok ), "idtipdok" )
   ENDIF

   // partner
   IF !Empty( _partner )
      IF !Empty( cFaktDoksFilter )
         cFaktDoksFilter += ".and."
      ENDIF
      cFaktDoksFilter += Parsiraj( AllTrim( _partner ), "idpartner" )
   ENDIF



   MsgO( "Generacija podataka ..." )

  // SELECT fakt_doks
  // SET FILTER TO &cFaktDoksFilter
  // GO TOP

   find_fakt_doks_za_period( cIdFirma, dDatOd, dDatDo, "FAKT_DOKS", "idfirma,datdok,idtipdok,brdok" )
   SET FILTER TO &cFaktDoksFilter
   GO TOP

   DO WHILE !Eof()

      cIdFirmaTekuci := field->idfirma
      cIdTipDokTekuci := field->idtipdok
      cBrDokTekuci := field->brdok
      nUkupno := field->iznos
      _oper_id := field->oper_id

      seek_fakt( cIdFirmaTekuci, cIdTipDokTekuci, cBrDokTekuci )
      info_bar( "gen_r_exp", "GEN FAKT " + cIdFirmaTekuci + "-" + cIdTipDokTekuci + "-" + cBrDokTekuci )
      DO WHILE !Eof() .AND. field->idfirma == cIdFirmaTekuci .AND. field->idtipdok == cIdTipDokTekuci .AND. field->brdok == cBrDokTekuci

         cRoba_id := field->idroba
         cPart_id := field->idpartner

         _tip_partnera := "1" // fizicka lica
         lOslobodjenPDV := is_part_pdv_oslob_po_clanu( cPart_id ) .OR. partner_is_ino( cPart_id )

         IF lPoTipovimaPartnera

            _pdv_broj := firma_pdv_broj( cPart_id )
            IF !Empty( _pdv_broj )
               _tip_partnera := "2"
            ENDIF

         ENDIF

         select_o_roba( cRoba_id )
         select_o_tarifa( roba->idtarifa )
         select_o_partner( cPart_id )

         SELECT fakt

         nCjPDV := 0
         nCj2PDV := 0
         nCjBPDV := 0
         nCj2BPDV := 0
         nVPopust := 0

         IF lOslobodjenPDV
            nPPDV := 0
         ELSE
            nPPDV := tarifa->pdv  // procenat pdv-a
         ENDIF

         nKol := field->kolicina
         nRCijen := field->cijena

         IF Left( field->dindem, 3 ) <> Left( ValBazna(), 3 )
            // preracunaj u EUR
            // omjer EUR / KM
            nRCijen := nRCijen / OmjerVal( ValBazna(), field->dindem, field->datdok )
            nRCijen := Round( nRCijen, DEC_CIJENA() )
         ENDIF

         nPopust := field->rabat // rabat - popust

         // ako je 13-ka ili 27-ca
         // cijena bez pdv se utvrdjuje unazad
         IF ( field->idtipdok == "13" .AND. glCij13Mpc ) .OR. ( field->idtipdok $ "11#27" .AND. gMP $ "1234567" )
            // cjena bez pdv-a
            nCjPDV := nRCijen
            nCjBPDV := ( nRCijen / ( 1 + nPPDV / 100 ) )
         ELSE
            nCjBPDV := nRCijen // cjena bez pdv-a
            nCjPDV := ( nRCijen * ( 1 + nPPDV / 100 ) )
         ENDIF

         IF Round( nPopust, 4 ) <> 0
            nVPopust := ( nCjBPDV * ( nPopust / 100 ) ) // vrijednost popusta
         ENDIF

         nCj2BPDV := ( nCjBPDV - nVPopust ) // cijena sa popustom bez pdv-a
         nCj2PDV := ( nCj2BPDV * ( 1 + nPPDV / 100 ) )// izracuna PDV na cijenu sa popustom
         nVPDV := ( nCj2BPDV * ( nPPDV / 100 ) ) // preracunaj VPDV sa popustom

         SELECT r_export
         APPEND BLANK

         REPLACE field->tip WITH _tip_partnera, ;
            field->idfirma WITH fakt->idfirma, ;
            field->idtipdok WITH fakt->idtipdok, ;
            field->brdok WITH fakt->brdok, ;
            field->datdok WITH fakt->datdok, ;
            field->operater WITH _oper_id, ;
            field->vrstap WITH  get_naziv_vrsta_placanja( fakt->idtipdok, fakt->idvrstep ), ;
            field->part_id WITH fakt->idpartner, ;
            field->part_naz WITH AllTrim( partn->naz ), ;
            field->roba_id WITH fakt->idroba, ;
            field->roba_naz WITH AllTrim( roba->naz ), ;
            field->kolicina WITH nKol, ;
            field->s_pdv WITH nPPDV, ;
            field->popust WITH nVPopust, ;
            field->c_bpdv WITH nCj2BPdv, ;
            field->pdv WITH nVPDV, ;
            field->c_pdv WITH nCj2PDV, ;
            field->uk_fakt WITH nUkupno

         SELECT fakt
         SKIP

      ENDDO

      SELECT fakt_doks
      SKIP

   ENDDO

   MsgC()

   RETURN .T.


STATIC FUNCTION get_naziv_vrsta_placanja( cIdTipDok, cIdVrstaPlacanja )

   LOCAL _ret := "MP GOTOVINA"

   DO CASE

   CASE cIdTipDok == "11"

      IF !Empty( cIdVrstaPlacanja )
         IF cIdVrstaPlacanja == "KT"
            _ret := "MP KARTICA"
         ELSEIF cIdVrstaPlacanja == "AV"
            _ret := "MP AVANSNA FAKTURA"
         ELSEIF cIdVrstaPlacanja == "VR"
            _ret := "MP VIRMANSKO PLACANJE"
         ENDIF
      ENDIF

   CASE cIdTipDok == "10"
      _ret := "VP VIRMANSKO PLACANJE"
      IF !Empty( cIdVrstaPlacanja )
         IF cIdVrstaPlacanja == "G "
            _ret := "VP GOTOVINA"
         ELSEIF cIdVrstaPlacanja == "KT"
            _ret := "VP KARTICA"
         ELSEIF cIdVrstaPlacanja == "AV"
            _ret := "VP AVANSNA FAKTURA"
         ENDIF
      ENDIF

   ENDCASE

   RETURN _ret


STATIC FUNCTION fakt_realiz_pdv_cre_open_r_export_table()

   LOCAL aDbf := {}

   AAdd( aDbf, { "tip", "C", 1, 0 } )
   AAdd( aDbf, { "idfirma", "C", 2, 0 } )
   AAdd( aDbf, { "idtipdok", "C", 2, 0 } )
   AAdd( aDbf, { "brdok", "C", 10, 0 } )
   AAdd( aDbf, { "datdok", "D", 8, 0 } )
   AAdd( aDbf, { "operater", "N", 10, 0 } )
   AAdd( aDbf, { "vrstap", "C", 40, 0 } )
   AAdd( aDbf, { "part_id", "C", 6, 0 } )
   AAdd( aDbf, { "part_naz", "C", 100, 0 } )
   AAdd( aDbf, { "roba_id", "C", 10, 0 } )
   AAdd( aDbf, { "roba_naz", "C", 100, 0 } )
   AAdd( aDbf, { "kolicina", "N", 15, 5 } )
   AAdd( aDbf, { "popust", "N", 15, 5 } )
   AAdd( aDbf, { "s_pdv", "N", 12, 2 } )
   AAdd( aDbf, { "c_bpdv", "N", _FNUM, _FDEC } )
   AAdd( aDbf, { "pdv", "N", _FNUM, _FDEC } )
   AAdd( aDbf, { "c_pdv", "N", _FNUM, _FDEC } )
   AAdd( aDbf, { "uk_fakt", "N", _FNUM, _FDEC } )

   IF !xlsx_export_init( aDbf )
      RETURN .F.
   ENDIF

   SELECT ( F_R_EXP )
   my_usex ( "r_export" )

   INDEX ON field->idfirma + field->idtipdok + field->brdok TAG "1"
   INDEX ON field->roba_id TAG "2"
   INDEX ON Str( field->operater, 10 ) + field->idfirma + field->idtipdok + field->brdok TAG "3"
   INDEX ON field->tip TAG "4"
   INDEX ON field->vrstap TAG "5"

   RETURN .T.


STATIC FUNCTION fakt_mp_set_totali( nT_os, nT_pdv, nT_uk )

   RETURN fakt_mp_po_dokumentima( @nT_os, @nT_pdv, @nT_uk, .T. )


STATIC FUNCTION fakt_mp_po_dokumentima( nT_osnovica, nT_pdv, nT_ukupno, lCalc )

   LOCAL nOsnovica
   LOCAL nPDV
   LOCAL nUkupno
   LOCAL nRbr := 0
   LOCAL nRow := 35
   LOCAL cLine := ""
   LOCAL nOperater
   LOCAL cOper_Naz := ""
   LOCAL nS_pdv, nUk_fakt
   LOCAL cIdFirma, cIdTipDok, cBrDok
   LOCAL cPart_id, cPart_naz
   LOCAL lOslobodjenPDV

   IF lCalc == nil
      lCalc := .F.
   ENDIF

   nT_osnovica := 0
   nT_pdv := 0
   nT_ukupno := 0

   IF lCalc == .F.

      get_linija_fakt_mp_po_dok( @cLine )
      s_z_mpdok( cLine )
   ENDIF

   SELECT r_export
   SET ORDER TO TAG "1" // po dokumentima
   GO TOP

   DO WHILE !Eof()

      cIdFirma := field->idfirma
      cIdTipDok := field->idtipdok
      cBrDok := field->brdok
      cPart_id := field->part_id
      cPart_naz := field->part_naz
      nOperater := field->operater
      cOper_naz := GetFullUserName( nOperater )

      nOsnovica := 0
      nPDV := 0
      nUkupno := 0
      nS_pdv := 0
      nUk_fakt := 0

      lOslobodjenPDV := is_part_pdv_oslob_po_clanu( cPart_id ) .OR. partner_is_ino( cPart_id )

      DO WHILE !Eof() .AND. field->idfirma + field->idtipdok + field->brdok == cIdFirma + cIdTipDok + cBrDok

         nOsnovica += field->kolicina * field->c_bpdv

         IF !lOslobodjenPDV
            nPDV += field->kolicina * field->pdv
            nS_pdv := field->s_pdv
         ELSE
            nS_pdv := 0
         ENDIF

         nUk_fakt := field->uk_fakt

         SKIP
      ENDDO

      // zaokruzi
      nOsnovica := Round( ( nUk_fakt / ( 1 + ( nS_pdv / 100 ) ) ), ZAO_VRIJEDNOST() )
      nPDV := Round( ( nUk_fakt / ( 1 + ( nS_pdv / 100 ) ) * ( nS_pdv / 100 ) ), ZAO_VRIJEDNOST() )
      nUkupno := Round( nUk_fakt, ZAO_VRIJEDNOST() )

      IF lCalc == .F.
         // pa ispisi tu stavku
         ? PadL( AllTrim( Str( ++nRbr ) ), 4 ) + "."

         // dokument
         @ PRow(), PCol() + 1 SAY PadR( AllTrim( cIdFirma + "-" + cIdTipDok + "-" + cBrDok ), 16 )

         // partner
         @ PRow(), PCol() + 1 SAY PadR( AllTrim( cPart_id ) + "-" +  AllTrim( cPart_naz ), 40 )

         // osnovica
         @ PRow(), nRow := PCol() + 1 SAY Str( nOsnovica, _NUM, _DEC )  PICT PIC_IZN

         // pdv
         @ PRow(), PCol() + 1 SAY Str( nPDV, _NUM, _DEC ) PICT PIC_IZN

         // ukupno
         @ PRow(), PCol() + 1 SAY Str( nUkupno, _NUM, _DEC ) PICT PIC_IZN

         // operater
         @ PRow(), PCol() + 1 SAY PadR( AllTrim( cOper_naz ), 20 )

      ENDIF

      nT_ukupno += nUkupno
      nT_osnovica += nOsnovica
      nT_pdv += nPDV

   ENDDO

   IF lCalc == .F.


      ? cLine

      ? "UKUPNO:"  // total
      @ PRow(), nRow SAY Str( nT_osnovica, _NUM, _DEC ) PICT PIC_IZN
      @ PRow(), PCol() + 1 SAY Str( nT_pdv, _NUM, _DEC ) PICT PIC_IZN
      @ PRow(), PCol() + 1 SAY Str( nT_ukupno, _NUM, _DEC ) PICT PIC_IZN

      ? cLine
   ENDIF

   RETURN .T.


STATIC FUNCTION fakt_mp_po_tipu_partnera( nT_osnovica, nT_pdv, nT_ukupno )

   LOCAL nOsnovica
   LOCAL nPDV
   LOCAL nUkupno
   LOCAL nRbr := 0
   LOCAL nRow := 35
   LOCAL cLine := ""
   LOCAL cIdTipDokTekuci
   LOCAL cIdFirmaTekuci
   LOCAL cBrDokTekuci
   LOCAL _tip_partnera, _opis
   LOCAL __osn, __pdv, __total
   LOCAL cIdFirma, _tip_dok, _br_dok
   LOCAL nS_pdv, nUk_fakt

   // tip partnera: 1 - nepdv, 2 - pdv, 3 - ino

   nT_osnovica := 0
   nT_pdv := 0
   nT_ukupno := 0

   g_l_mptip( @cLine )
   s_z_mptip( cLine )

   SELECT r_export
   SET ORDER TO TAG "4" // po operaterima
   GO TOP

   DO WHILE !Eof()

      _tip_partnera := field->tip

      __osn := 0
      __pdv := 0
      __total := 0

      DO WHILE !Eof() .AND. field->tip == _tip_partnera

         _tip_partnera := field->tip

         cIdFirma := field->idfirma
         _tip_dok := field->idtipdok
         _br_dok := field->brdok

         nOsnovica := 0
         nPDV := 0
         nUkupno := 0
         nS_pdv := 0
         nUk_fakt := 0

         DO WHILE !Eof() .AND. _tip_partnera == field->tip .AND. field->idfirma + field->idtipdok + field->brdok == cIdFirma + _tip_dok + _br_dok

            nS_pdv := field->s_pdv
            nUk_fakt := field->uk_fakt
            SKIP

         ENDDO

         // zaokruzi
         nOsnovica := Round( ( nUk_fakt / ( 1 + ( nS_pdv / 100 ) ) ),  ZAO_VRIJEDNOST() )
         nPDV := Round( ( nUk_fakt / ( 1 + ( nS_pdv / 100 ) ) *  ( nS_pdv / 100 ) ), ZAO_VRIJEDNOST() )
         nUkupno := Round( nUk_fakt, ZAO_VRIJEDNOST() )

         __osn += nOsnovica
         __pdv += nPDV
         __total += nUkupno

      ENDDO

      ? PadL( AllTrim( Str( ++nRbr ) ), 4 ) + "."

      _opis := "Fizicka lica"

      IF _tip_partnera == "2"
         _opis := "Pravna lica"
      ENDIF

      // tip partnera
      @ PRow(), PCol() + 1 SAY PadR( _opis, 40 )

      // total
      @ PRow(), nRow := PCol() + 1 SAY Str( __osn, _NUM, _DEC ) PICT PIC_IZN

      // pdv
      @ PRow(), PCol() + 1 SAY Str( __pdv, _NUM, _DEC ) PICT PIC_IZN

      // osnovica
      @ PRow(), PCol() + 1 SAY Str( __total, _NUM, _DEC ) PICT PIC_IZN

      nT_ukupno += __total
      nT_osnovica += __osn
      nT_pdv += __pdv

   ENDDO


   ? cLine
   ? "UKUPNO:" // total

   @ PRow(), nRow SAY Str( nT_osnovica, _NUM, _DEC ) PICT PIC_IZN
   @ PRow(), PCol() + 1 SAY Str( nT_pdv, _NUM, _DEC ) PICT PIC_IZN
   @ PRow(), PCol() + 1 SAY Str( nT_ukupno, _NUM, _DEC ) PICT PIC_IZN

   ? cLine

   RETURN .T.



STATIC FUNCTION fakt_mp_po_vrstama_placanja( nT_osnovica, nT_pdv, nT_ukupno )

   LOCAL nOsnovica
   LOCAL nPDV
   LOCAL nUkupno
   LOCAL nRbr := 0
   LOCAL nRow := 35
   LOCAL cLine := ""
   LOCAL cIdTipDokTekuci
   LOCAL cIdFirmaTekuci
   LOCAL cBrDokTekuci
   LOCAL _vrsta_p, _vrsta_p_naz
   LOCAL nS_pdv, nU_fakt, nUU_fakt

   nT_osnovica := 0
   nT_pdv := 0
   nT_ukupno := 0

   g_l_mpop( @cLine )
   s_z_mpvrstap( cLine ) // zaglavlje pregled po robi

   SELECT r_export
   SET ORDER TO TAG "5" // po operaterima
   GO TOP

   DO WHILE !Eof()

      _vrsta_p := field->vrstap
      nOsnovica := 0
      nPDV := 0
      nUkupno := 0
      nS_pdv := 0
      nU_fakt := 0
      nUU_fakt := 0

      DO WHILE !Eof() .AND. field->vrstap == _vrsta_p

         cBrDokTekuci := field->brdok
         cIdTipDokTekuci := field->idtipdok
         cIdFirmaTekuci := field->idfirma

         DO WHILE !Eof() .AND. field->vrstap == _vrsta_p .AND. cIdFirmaTekuci + cIdTipDokTekuci + cBrDokTekuci == field->idfirma +  field->idtipdok + field->brdok

            nU_fakt := field->uk_fakt
            nS_pdv := field->s_pdv
            nOsnovica += field->kolicina * field->c_bpdv
            nPDV += field->kolicina * field->pdv

            SKIP
         ENDDO

         nUU_fakt += nU_fakt

      ENDDO

      // zaokruzi
      nOsnovica := Round( ( nUU_fakt / ( 1 + ( nS_pdv / 100 ) ) ), ZAO_VRIJEDNOST() )
      nPDV := Round( ( nUU_fakt / ( 1 + ( nS_pdv / 100 ) ) * ( nS_pdv / 100 ) ), ZAO_VRIJEDNOST() )
      nUkupno := Round( nUU_fakt, ZAO_VRIJEDNOST() )


      ? PadL( AllTrim( Str( ++nRbr ) ), 4 ) + "."

      // operater
      @ PRow(), PCol() + 1 SAY PadR( AllTrim( _vrsta_p ), 40 )

      // total
      @ PRow(), nRow := PCol() + 1 SAY Str( nUkupno, _NUM, _DEC ) ;
         PICT PIC_IZN

      nT_ukupno += nUkupno
      nT_osnovica += nOsnovica
      nT_pdv += nPDV

   ENDDO

   ? cLine
   ? "UKUPNO:"
   @ PRow(), nRow SAY Str( nT_Ukupno, _NUM, _DEC ) PICT PIC_IZN
   ? cLine

   RETURN .T.




STATIC FUNCTION fakt_mp_po_operaterima( nT_osnovica, nT_pdv, nT_ukupno )

   LOCAL nOperater
   LOCAL cOper_naz
   LOCAL nOsnovica
   LOCAL nPDV
   LOCAL nUkupno
   LOCAL nRbr := 0
   LOCAL nRow := 35
   LOCAL cLine := ""
   LOCAL cIdTipDokTekuci
   LOCAL cIdFirmaTekuci
   LOCAL cBrDokTekuci
   LOCAL nS_pdv, nU_fakt, nUU_fakt

   nT_osnovica := 0
   nT_pdv := 0
   nT_ukupno := 0

   g_l_mpop( @cLine )
   s_z_mpop( cLine )

   SELECT r_export
   SET ORDER TO TAG "3" // po operaterima
   GO TOP

   DO WHILE !Eof()

      nOperater := field->operater
      cOper_naz := ""


      IF nOperater <> 0 // ako postoji operater
         PushWa()
         cOper_naz := GetFullUserName( nOperater )
         cOper_naz := "(" + AllTrim( Str( nOperater ) ) + ") " + cOper_naz
         PopWa()
      ENDIF

      nOsnovica := 0
      nPDV := 0
      nUkupno := 0
      nS_pdv := 0
      nU_fakt := 0
      nUU_fakt := 0

      DO WHILE !Eof() .AND. field->operater == nOperater

         cBrDokTekuci := field->brdok
         cIdTipDokTekuci := field->idtipdok
         cIdFirmaTekuci := field->idfirma

         DO WHILE !Eof() .AND. field->operater == nOperater .AND. cIdFirmaTekuci + cIdTipDokTekuci + cBrDokTekuci == field->idfirma + field->idtipdok + field->brdok

            nU_fakt := field->uk_fakt
            nS_pdv := field->s_pdv
            nOsnovica += field->kolicina * field->c_bpdv
            nPDV += field->kolicina * field->pdv

            SKIP
         ENDDO

         nUU_fakt += nU_fakt

      ENDDO

      // zaokruzi
      nOsnovica := Round( ( nUU_fakt / ( 1 + ( nS_pdv / 100 ) ) ), ZAO_VRIJEDNOST() )
      nPDV := Round( ( nUU_fakt / ( 1 + ( nS_pdv / 100 ) ) * ( nS_pdv / 100 ) ), ZAO_VRIJEDNOST() )
      nUkupno := Round( nUU_fakt, ZAO_VRIJEDNOST() )


      ? PadL( AllTrim( Str( ++nRbr ) ), 4 ) + "."

      @ PRow(), PCol() + 1 SAY PadR( AllTrim( cOper_naz ), 40 )

      @ PRow(), nRow := PCol() + 1 SAY Str( nUkupno, _NUM, _DEC ) PICT PIC_IZN // total

      nT_ukupno += nUkupno
      nT_osnovica += nOsnovica
      nT_pdv += nPDV

   ENDDO

   ? cLine
   ? "UKUPNO:"
   @ PRow(), nRow SAY Str( nT_Ukupno, _NUM, _DEC ) PICT PIC_IZN
   ? cLine

   RETURN .T.



STATIC FUNCTION fakt_mp_po_robama()

   LOCAL cRoba_id
   LOCAL nOsnovica
   LOCAL nPDV
   LOCAL nUkupno
   LOCAL nKolicina
   LOCAL nT_kolicina := 0
   LOCAL nRbr := 0
   LOCAL nRow := 35
   LOCAL cLine := ""
   LOCAL nT_osnovica := 0
   LOCAL nT_pdv := 0
   LOCAL nT_ukupno := 0
   LOCAL nS_pdv, cRoba_naz

   g_l_mproba( @cLine )
   s_z_mproba( cLine ) // zaglavlje pregled po robi

   SELECT r_export
   SET ORDER TO TAG "2"
   GO TOP

   DO WHILE !Eof()

      cRoba_id := field->roba_id
      cRoba_naz := field->roba_naz

      nOsnovica := 0
      nPDV := 0
      nS_pdv := 0
      nUkupno := 0
      nKolicina := 0

      DO WHILE !Eof() .AND. field->roba_id == cRoba_id

         nS_pdv := field->s_pdv
         nOsnovica += field->kolicina * field->c_bpdv
         nPDV += field->kolicina * field->pdv
         nKolicina += field->kolicina

         SKIP
      ENDDO

      nOsnovica := Round( nOsnovica, ZAO_VRIJEDNOST() )
      nPDV := Round( ( nOsnovica * ( nS_pdv / 100 ) ), ZAO_VRIJEDNOST() + _ZAOK )
      nUkupno := Round( nOsnovica + nPDV, ZAO_VRIJEDNOST() )

      ? PadL( AllTrim( Str( ++nRbr ) ), 4 ) + "."
      @ PRow(), PCol() + 1 SAY PadR( AllTrim( cRoba_id ) + "-" + AllTrim( cRoba_naz ), 50 )
      @ PRow(), nRow := PCol() + 1 SAY Str( nKolicina, 12, 2 )

      nT_kolicina += nKolicina

   ENDDO

   ? cLine
   ? "UKUPNO:" // total
   @ PRow(), nRow SAY Str( nT_kolicina, 12, 2 )

   ? cLine

   RETURN .T.


// -----------------------------------------
// vraca liniju za pregled po robi
// -----------------------------------------
STATIC FUNCTION g_l_mproba( cLine )

   cLine := ""

   cLine += Replicate( "-", 5 )
   cLine += Space( 1 )
   cLine += Replicate( "-", 50 )
   cLine += Space( 1 )
   cLine += Replicate( "-", 12 )

   RETURN .T.


// -----------------------------------------
// zaglavlje za pregled po robama
// -----------------------------------------
STATIC FUNCTION s_z_mproba( cLine )

   LOCAL cTxt := ""

   cTxt += PadR( "r.br", 5 )
   cTxt += Space( 1 )
   cTxt += PadR( "roba (id/naziv)", 50 )
   cTxt += Space( 1 )
   cTxt += PadR( "kolicina", 12 )
   ? "Realizacija po robi:"
   ? cLine
   ? cTxt
   ? cLine

   RETURN .T.

// -----------------------------------------
// vraca liniju za pregled po robi
// -----------------------------------------
STATIC FUNCTION g_l_mptip( cLine )

   cLine := ""

   cLine += Replicate( "-", 5 )
   cLine += Space( 1 )
   cLine += Replicate( "-", 40 )
   cLine += Space( 1 )
   cLine += Replicate( "-", 12 )
   cLine += Space( 1 )
   cLine += Replicate( "-", 12 )
   cLine += Space( 1 )
   cLine += Replicate( "-", 12 )

   RETURN .T.




// -----------------------------------------
// vraca liniju za pregled po robi
// -----------------------------------------
STATIC FUNCTION g_l_mpop( cLine )

   cLine := ""

   cLine += Replicate( "-", 5 )
   cLine += Space( 1 )
   cLine += Replicate( "-", 40 )
   cLine += Space( 1 )
   cLine += Replicate( "-", 12 )

   RETURN .T.


// -----------------------------------------
// zaglavlje za pregled po robama
// -----------------------------------------
STATIC FUNCTION s_z_mptip( cLine )

   LOCAL cTxt := ""

   cTxt += PadR( "r.br", 5 )
   cTxt += Space( 1 )
   cTxt += PadR( "Tip partnera", 40 )
   cTxt += Space( 1 )
   cTxt += PadR( "osnovica", 12 )
   cTxt += Space( 1 )
   cTxt += PadR( "pdv", 12 )
   cTxt += Space( 1 )
   cTxt += PadR( "ukupno", 12 )

   ? "Realizacija po tipu partnera:"
   ? cLine
   ? cTxt
   ? cLine

   RETURN .T.



// -----------------------------------------
// zaglavlje za pregled po vrsti placanja
// -----------------------------------------
STATIC FUNCTION s_z_mpvrstap( cLine )

   LOCAL cTxt := ""

   cTxt += PadR( "r.br", 5 )
   cTxt += Space( 1 )
   cTxt += PadR( "vrsta plaćanja (id/naziv)", 40 )
   cTxt += Space( 1 )
   cTxt += PadR( "ukupno", 12 )

   ?
   ?U "Realizacija po vrstama plaćanja:"
   ?U cLine
   ?U cTxt
   ?U cLine

   RETURN .T.




// -----------------------------------------
// zaglavlje za pregled po robama
// -----------------------------------------
STATIC FUNCTION s_z_mpop( cLine )

   LOCAL cTxt := ""

   cTxt += PadR( "r.br", 5 )
   cTxt += Space( 1 )
   cTxt += PadR( "operater (id/naziv)", 40 )
   cTxt += Space( 1 )
   cTxt += PadR( "ukupno", 12 )

   ? "Realizacija po operaterima:"
   ? cLine
   ? cTxt
   ? cLine

   RETURN .T.


STATIC FUNCTION get_linija_fakt_mp_po_dok( cLine )

   cLine := ""

   cLine += Replicate( "-", 5 )
   cLine += Space( 1 )
   cLine += Replicate( "-", 16 )
   cLine += Space( 1 )
   cLine += Replicate( "-", 40 )
   cLine += Space( 1 )
   cLine += Replicate( "-", 12 )
   cLine += Space( 1 )
   cLine += Replicate( "-", 12 )
   cLine += Space( 1 )
   cLine += Replicate( "-", 12 )
   cLine += Space( 1 )
   cLine += Replicate( "-", 20 )

   RETURN .T.


// -----------------------------------------
// zaglavlje za pregled po robama
// -----------------------------------------
STATIC FUNCTION s_z_mpdok( cLine )

   LOCAL cTxt := ""

   cTxt += PadR( "r.br", 5 )
   cTxt += Space( 1 )
   cTxt += PadR( "dokument", 16 )
   cTxt += Space( 1 )
   cTxt += PadR( "partner (id/naziv)", 40 )
   cTxt += Space( 1 )
   cTxt += PadR( "osnovica", 12 )
   cTxt += Space( 1 )
   cTxt += PadR( "pdv", 12 )
   cTxt += Space( 1 )
   cTxt += PadR( "ukupno", 12 )
   cTxt += Space( 1 )
   cTxt += PadR( "operater", 20 )

   ? "Realizacija po dokumentima:"
   ? cLine
   ? cTxt
   ? cLine

   RETURN .T.
