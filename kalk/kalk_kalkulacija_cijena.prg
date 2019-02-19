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

MEMVAR nKalkPrevoz
MEMVAR nKalkBankTr
MEMVAR nKalkSpedTr
MEMVAR nKalkCarDaz
MEMVAR nKalkZavTr
MEMVAR nKalkMarzaVP, nKalkMarzaMP

FUNCTION kalkulacija_cijena( azurirana )

   LOCAL hParams
   LOCAL _template
   LOCAL _tip := "V"
   LOCAL _predisp := .F.
   LOCAL cOk

   IF azurirana == NIL
      azurirana := .T.
   ENDIF

   download_template( "kalk_mp.odt", "f745ca8770ca02b9781f935ecff90e0e34aa625af26b103d5e3a3f9d5f568ca8" )
   download_template( "kalk_mp_pred.odt", "5442e7b9d5ef0044217e04a5294f3aa15577218b45850714b4152cddb86e26ca" )
   download_template( "kalk_vp.odt", "7e38d1455c0f8be2054ec688eccf1106de2ca0a2d91ac60eb3553d492d522285" )

   o_tables( azurirana )

   IF azurirana .AND. !get_vars( @hParams )
      RETURN .F.
   ENDIF

   IF !azurirana
      hParams := hb_Hash()
      hParams[ "id_firma" ] := kalk_pripr->idfirma
      hParams[ "tip_dok" ] := kalk_pripr->idvd
      hParams[ "br_dok" ] := kalk_pripr->brdok
   ENDIF

   IF !( hParams[ "tip_dok" ] $ "10#16#95#96#81#80" )
      RETURN .F.
   ENDIF

   IF hParams[ "tip_dok" ] $ "10#16#95#96"

      _tip := "V"
      _template := "kalk_vp.odt"

   ELSEIF hParams[ "tip_dok" ] $ "80#81"

      _tip := "M"
      _template := "kalk_mp.odt"

      IF mp_predispozicija( hParams[ "id_firma" ], hParams[ "tip_dok" ], hParams[ "br_dok" ] )
         _template := "kalk_mp_pred.odt"
         _predisp := .T.
      ENDIF

   ENDIF

   IF !File( f18_template_location( _template ) )
      MsgBeep( "Template fajl ne postoji: " + f18_template_location( _template ) )
      RETURN .F.
   ENDIF

   IF !seek_dokument( hParams, azurirana )
      RETURN .F.
   ENDIF

   IF !Empty ( cOk := kalkulacija_ima_sve_cijene( hParams[ "id_firma" ], hParams[ "tip_dok" ], hParams[ "br_dok" ] ) )
      MsgBeep( "Unutar kalkulacije nedostaju pojedine cijene bitne za obračun!##Stavke: " + cOk )
      // RETURN .F.
   ENDIF

   DO CASE

   CASE _predisp == .T.
      IF gen_kalk_predispozicija_xml( hParams ) > 0
         st_kalkulacija_cijena_odt( _template )
      ENDIF

   CASE _tip == "M"
      IF gen_kalk_mp_xml( hParams ) > 0
         st_kalkulacija_cijena_odt( _template )
      ENDIF

   CASE _tip == "V"
      IF gen_kalk_vp_xml( hParams ) > 0
         st_kalkulacija_cijena_odt( _template )
      ENDIF

   ENDCASE

   RETURN .T.


FUNCTION mp_predispozicija( firma, tip_dok, br_dok )

   LOCAL _ret := .F.
   LOCAL nDbfArea := Select()
   LOCAL hRec

   IF tip_dok <> "80"
      RETURN _ret
   ENDIF

   SELECT kalk_pripr
   GO TOP
   SEEK firma + tip_dok + br_dok

   hRec := RecNo()
   DO WHILE !Eof() .AND. field->idfirma + field->idvd + field->brdok == firma + tip_dok + br_dok
      IF field->idkonto2 = "XXX"
         _ret := .T.
         EXIT
      ENDIF
      SKIP
   ENDDO

   SELECT ( nDbfArea )

   RETURN _ret



STATIC FUNCTION st_kalkulacija_cijena_odt( template_file )

   IF generisi_odt_iz_xml( template_file )
      prikazi_odt()
   ENDIF

   RETURN


STATIC FUNCTION o_tables( azurirana )

   SELECT F_KONCIJ
   IF !Used()
      o_koncij()
   ENDIF

   SELECT F_TARIFA
   IF !Used()
      o_tarifa()
   ENDIF

   SELECT F_PARTN
   IF !Used()
      o_partner()
   ENDIF

   SELECT F_KONTO
   IF !Used()
      o_konto()
   ENDIF

   SELECT F_TDOK
   IF !Used()
      o_tdok()
   ENDIF

   IF azurirana
      open_kalk_as_pripr()
   ELSE
      o_kalk_pripr()
   ENDIF

   SELECT kalk_pripr
   SET ORDER TO TAG "1"
   GO TOP

   RETURN


STATIC FUNCTION get_vars( hParams )

   LOCAL cIdFirma := self_organizacija_id()
   LOCAL _tip := "10"
   LOCAL _broj := Space( 8 )
   LOCAL _ret := .F.

   Box(, 1, 40 )
   @ box_x_koord() + 1, box_y_koord() + 2 SAY "Broj dokumenta:"
   @ box_x_koord() + 1, Col() + 1 GET cIdFirma
   @ box_x_koord() + 1, Col() + 1 SAY "-" GET _tip VALID !Empty( _tip )
   @ box_x_koord() + 1, Col() + 1 SAY "-" GET _broj VALID !Empty( _broj )
   READ
   BoxC()

   IF LastKey() == K_ESC
      RETURN _ret
   ENDIF

   hParams := hb_Hash()
   hParams[ "id_firma" ] := cIdFirma
   hParams[ "tip_dok" ] := _tip
   hParams[ "br_dok" ] := _broj

   RETURN .T.


STATIC FUNCTION seek_dokument( hParams, azurirani )

   LOCAL cIdFirma := hParams[ "id_firma" ]
   LOCAL cIdVd := hParams[ "tip_dok" ]
   LOCAL cBrDok := hParams[ "br_dok" ]

   SELECT kalk_pripr
   SET ORDER TO TAG "1"
   GO TOP

   IF azurirani

      SEEK cIdFirma + cIdVd + cBrDok
      IF !Found()
         MsgBeep( "Trazeni dokument " + cIdFirma + "-" + cIdVd + "-" + AllTrim( cBrDok ) + " ne postoji !" )
         RETURN .F.
      ENDIF

   ENDIF

   RETURN .T.


STATIC FUNCTION gen_kalk_predispozicija_xml( hParams )

   LOCAL cIdFirma := hParams[ "id_firma" ]
   LOCAL cIdVd := hParams[ "tip_dok" ]
   LOCAL cBrDok := hParams[ "br_dok" ]
   LOCAL _generated := 0
   LOCAL _xml_file := my_home() + "data.xml"
   LOCAL nTrec
   LOCAL nRbr := 0
   LOCAL nPDVStopa, nPDVCijena
   LOCAL _s_kolicina, _tmp, _a_porezi
   LOCAL _u_porez, _t_porez, _u_pv, _t_pv, _u_pv_porez, _t_pv_porez, _t_kol
   LOCAL _razd_id, _razd_naz
   LOCAL _zad_id, _zad_naz
   LOCAL _dio

   PRIVATE nKalkPrevoz, nKalkCarDaz, nKalkZavTr, nKalkBankTr, nKalkSpedTr, nKalkMarzaVP, nKalkMarzaMP

   select_o_konto( kalk_pripr->pkonto )
   _razd_id := kalk_pripr->pkonto
   _razd_naz := konto->naz

   select_o_konto( kalk_pripr->idkonto2 )
   _zad_id := kalk_pripr->idkonto2
   _zad_naz := konto->naz

   select_o_tdok(kalk_pripr->idvd)

   SELECT kalk_pripr
   nTrec := RecNo()

   create_xml( _xml_file )
   xml_head()

   xml_subnode( "kalk", .F. )
   xml_node( "org_id", AllTrim( self_organizacija_id() ) )
   xml_node( "org_naziv", to_xml_encoding( AllTrim( self_organizacija_naziv() ) ) )

   xml_node( "dok_naziv", to_xml_encoding( AllTrim( tdok->naz ) ) )
   xml_node( "dok_tip", field->idvd )
   xml_node( "dok_broj", to_xml_encoding( AllTrim( cBrDok ) ) )
   xml_node( "dok_datum", DToC( field->datdok ) )

   xml_node( "zad_id", to_xml_encoding( AllTrim( _zad_id ) ) )
   xml_node( "zad_naz", to_xml_encoding( AllTrim( _zad_naz ) ) )

   xml_node( "razd_id", to_xml_encoding( AllTrim( _razd_id ) ) )
   xml_node( "razd_naz", to_xml_encoding( AllTrim( _razd_naz ) ) )

   xml_node( "rn_broj", to_xml_encoding( AllTrim( field->brfaktp ) ) )
   xml_node( "rn_datum", DToC( field->datfaktp ) )

   FOR _dio := 1 TO 2
      IF _dio == 1
         xml_subnode( "razd", .F. )
      ELSE
         xml_subnode( "zad", .F. )
      ENDIF

      nRbr := 0
      SELECT kalk_pripr
      GO TOP
      SEEK cIdFirma + cIdVd + cBrDok

      _u_nv := _t_nv := _u_marza := _t_marza := 0
      _u_porez := _t_porez := 0
      _u_pv := _t_pv := _u_pv_porez := _t_pv_porez := 0
      _t_kol := 0

      DO WHILE !Eof() .AND. cIdFirma == kalk_pripr->idfirma .AND. cIdVd == kalk_pripr->idvd .AND. cBrDok == kalk_pripr->brdok

         IF _dio == 1
            IF field->idkonto2 = "XXX"
               SKIP
               LOOP
            ENDIF
         ELSE
            IF field->idkonto2 <> "XXX"
               SKIP
               LOOP
            ENDIF
         ENDIF

         ++_generated
         kalk_set_vars_troskovi_marzavp_marzamp()
         kalk_pozicioniraj_roba_tarifa_by_kalk_fields()
         nPDVStopa := tarifa->pdv
         nPDVCijena := field->mpc * pdv_procenat_by_tarifa( kalk_pripr->idtarifa)
         _s_kolicina := field->kolicina
         _t_kol += _s_kolicina
         _u_nv := Round( field->nc * _s_kolicina, gZaokr )
         _t_nv += _u_nv
         _u_marza := Round( nKalkMarzaMP * _s_kolicina, gZaokr )
         _t_marza += _u_marza
         _u_pv := Round( field->mpc * _s_kolicina, gZaokr )
         _t_pv += _u_pv
         _u_porez := ( nPDVCijena * field->kolicina )
         _t_porez += _u_porez
         _u_pv_porez := ( field->mpcsapp * field->kolicina )
         _t_pv_porez += _u_pv_porez

         xml_subnode( "stavka", .F. )

         xml_node( "art_id", to_xml_encoding( AllTrim( field->idroba ) ) )
         xml_node( "art_naz", to_xml_encoding( AllTrim( roba->naz ) ) + iif( roba_barkod_pri_unosu(), ", BK: " + roba->barkod, "" ) )
         xml_node( "art_jmj", to_xml_encoding( AllTrim( roba->jmj ) ) )
         xml_node( "tarifa", to_xml_encoding( AllTrim( field->idtarifa ) ) )
         xml_node( "rbr", PadL( AllTrim( Str( ++nRbr ) ), 4 ) + "." )

         xml_node( "kol", Str( field->kolicina, 12, 2 ) )
         xml_node( "g_kol", Str( field->gkolicina, 12, 2 ) )
         xml_node( "g_kol2", Str( field->gkolicin2, 12, 2 ) )
         xml_node( "skol", Str( _s_kolicina, 12, 2 ) )

         xml_node( "nc", Str( field->nc, 12, 2 ) )
         xml_node( "marzap", Str( nKalkMarzaMP / field->nc * 100, 12, 2 ) )
         xml_node( "marza", Str( nKalkMarzaMP, 12, 2 ) )
         xml_node( "pc", Str( field->mpc, 12, 2 ) )
         xml_node( "por_st", Str( nPDVStopa, 12, 2 ) )
         xml_node( "porez", Str( nPDVCijena, 12, 2 ) )
         xml_node( "pcsap", Str( field->mpcsapp, 12, 2 ) )

         xml_node( "unv", Str( _u_nv, 12, 2 ) )
         xml_node( "umarza", Str( _u_marza, 12, 2 ) )
         xml_node( "upv", Str( _u_pv, 12, 2 ) )
         xml_node( "upor", Str( _u_porez, 12, 2 ) )
         xml_node( "upvp", Str( _u_pv_porez, 12, 2 ) )

         xml_subnode( "stavka", .T. )

         SKIP

      ENDDO

      xml_node( "tkol", Str( _t_kol, 12, 2 ) )
      xml_node( "tnv", Str( _t_nv, 12, 2 ) )
      xml_node( "tmarza", Str( _t_marza, 12, 2 ) )
      xml_node( "tpv", Str( _t_pv, 12, 2 ) )
      xml_node( "tpor", Str( _t_porez, 12, 2 ) )
      xml_node( "tpvp", Str( _t_pv_porez, 12, 2 ) )

      IF _dio == 1
         xml_subnode( "razd", .T. )
      ELSE
         xml_subnode( "zad", .T. )
      ENDIF

   NEXT

   xml_subnode( "kalk", .T. )

   close_xml()

   RETURN _generated


STATIC FUNCTION gen_kalk_mp_xml( hParams )

   LOCAL cIdFirma := hParams[ "id_firma" ]
   LOCAL cIdVd := hParams[ "tip_dok" ]
   LOCAL cBrDok := hParams[ "br_dok" ]
   LOCAL _generated := 0
   LOCAL _xml_file := my_home() + "data.xml"
   LOCAL nTrec
   LOCAL nRbr := 0
   LOCAL nPDVStopa, nPDVCijena
   LOCAL _s_kolicina, _tmp, _a_porezi
   LOCAL _u_fv, _t_fv, _u_fv_r, _t_fv_r, _u_tr_prevoz, _u_tr_bank, _u_tr_carina, _u_tr_zavisni, _u_tr_sped, _u_tr_svi
   LOCAL _t_tr_prevoz, _t_tr_bank, _t_tr_carina, _t_tr_zavisni, _t_tr_sped, _t_tr_svi, _u_nv, _t_nv, _u_marza, _t_marza
   LOCAL _u_porez, _t_porez, _u_pv, _t_pv, _u_pv_porez, _t_pv_porez, _t_kol, _u_rabat, _t_rabat

   PRIVATE nKalkPrevoz, nKalkCarDaz, nKalkZavTr, nKalkBankTr, nKalkSpedTr, nKalkMarzaVP, nKalkMarzaMP

   select_o_konto( kalk_pripr->pkonto )
   select_o_partner( kalk_pripr->idpartner )
   select_o_tdok(kalk_pripr->idvd)

   SELECT kalk_pripr

   nTrec := RecNo()

   create_xml( _xml_file )
   xml_head()

   xml_subnode( "kalk", .F. )

   xml_node( "org_id", AllTrim( self_organizacija_id() ) )
   xml_node( "org_naziv", to_xml_encoding( AllTrim( self_organizacija_naziv() ) ) )

   xml_node( "dok_naziv", to_xml_encoding( AllTrim( tdok->naz ) ) )
   xml_node( "dok_tip", field->idvd )
   xml_node( "dok_broj", to_xml_encoding( AllTrim( cBrDok ) ) )
   xml_node( "dok_datum", DToC( field->datdok ) )

   xml_node( "zad_id", to_xml_encoding( AllTrim( field->pkonto ) ) )
   xml_node( "zad_naz", to_xml_encoding( AllTrim( konto->naz ) ) )

   xml_node( "dob_id", to_xml_encoding( AllTrim( field->idpartner ) ) )
   xml_node( "dob_naziv", to_xml_encoding( AllTrim( partn->naz ) ) )
   xml_node( "rn_broj", to_xml_encoding( AllTrim( field->brfaktp ) ) )
   xml_node( "rn_datum", DToC( field->datfaktp ) )

   _u_fv := _t_fv := 0
   _u_fv_r := _t_fv_r := 0
   _u_tr_prevoz := _u_tr_bank := _u_tr_carina := _u_tr_zavisni := _u_tr_sped := _u_tr_svi := 0
   _t_tr_prevoz := _t_tr_bank := _t_tr_carina := _t_tr_zavisni := _t_tr_sped := _t_tr_svi := 0
   _u_nv := _t_nv := _u_marza := _t_marza := 0
   _u_porez := _t_porez := 0
   _u_pv := _t_pv := _u_pv_porez := _t_pv_porez := 0
   _t_kol := 0
   _u_rabat := _t_rabat := 0

   DO WHILE !Eof() .AND. cIdFirma == field->idfirma .AND. cIdVd == field->idvd .AND. cBrDok == field->brdok

      ++_generated

      kalk_set_vars_troskovi_marzavp_marzamp()
      kalk_pozicioniraj_roba_tarifa_by_kalk_fields()
      nPDVStopa := tarifa->pdv
      nPDVCijena := field->mpc * nPDVStopa/100

      _s_kolicina := field->kolicina
      _t_kol += _s_kolicina

      _u_fv := Round( field->fcj * field->kolicina, gZaokr )
      _t_fv += _u_fv

      _u_rabat := Round( - field->rabat, gZaokr )
      _t_rabat += _u_rabat

      _u_fv_r := Round( - field->rabat / 100 * field->fcj * field->kolicina, gZaokr )
      _t_fv_r += _u_fv_r

      _u_tr_prevoz := Round( nKalkPrevoz * _s_kolicina, gZaokr )
      _u_tr_bank := Round( nKalkBankTr * _s_kolicina, gZaokr )
      _u_tr_sped := Round( nKalkSpedTr * _s_kolicina, gZaokr )
      _u_tr_carina := Round( nKalkCarDaz * _s_kolicina, gZaokr )
      _u_tr_zavisni := Round( nKalkZavTr * _s_kolicina, gZaokr )
      _u_tr_svi := ( _u_tr_prevoz + _u_tr_bank + _u_tr_sped + _u_tr_carina + _u_tr_zavisni )

      _t_tr_prevoz += _u_tr_prevoz
      _t_tr_bank += _u_tr_bank
      _t_tr_sped += _u_tr_sped
      _t_tr_carina += _u_tr_carina
      _t_tr_zavisni += _u_tr_zavisni
      _t_tr_svi += _u_tr_svi

      _u_nv := Round( field->nc * _s_kolicina, gZaokr )
      _t_nv += _u_nv

      _u_marza := Round( nKalkMarzaMP * _s_kolicina, gZaokr )
      _t_marza += _u_marza

      _u_pv := Round( field->mpc * _s_kolicina, gZaokr )
      _t_pv += _u_pv

      _u_porez := ( nPDVCijena * field->kolicina )
      _t_porez += _u_porez
      _u_pv_porez := ( field->mpcsapp * field->kolicina )
      _t_pv_porez += _u_pv_porez

      xml_subnode( "stavka", .F. )

      xml_node( "art_id", to_xml_encoding( AllTrim( field->idroba ) ) )
      xml_node( "art_naz", to_xml_encoding( AllTrim( roba->naz ) ) + iif( roba_barkod_pri_unosu(), ", BK: " + roba->barkod, "" ) )
      xml_node( "art_jmj", to_xml_encoding( AllTrim( roba->jmj ) ) )
      xml_node( "tarifa", to_xml_encoding( AllTrim( field->idtarifa ) ) )
      xml_node( "rbr", PadL( AllTrim( Str( ++nRbr ) ), 4 ) + "." )

      xml_node( "kol", Str( field->kolicina, 12, 2 ) )
      xml_node( "g_kol", Str( field->gkolicina, 12, 2 ) )
      xml_node( "g_kol2", Str( field->gkolicin2, 12, 2 ) )
      xml_node( "skol", Str( _s_kolicina, 12, 2 ) )

      xml_node( "fcj", Str( field->fcj, 12, 2 ) )
      xml_node( "rabat", Str( - field->rabat, 12, 2 ) )
      xml_node( "fcjr", Str( - field->rabat / 100 * field->fcj, 12, 2 ) )
      xml_node( "nc", Str( field->nc, 12, 2 ) )
      xml_node( "marzap", Str( nKalkMarzaMP / field->nc * 100, 12, 2 ) )
      xml_node( "marza", Str( nKalkMarzaMP, 12, 2 ) )
      xml_node( "pc", Str( field->mpc, 12, 2 ) )
      xml_node( "por_st", Str( nPDVStopa, 12, 2 ) )
      xml_node( "porez", Str( nPDVCijena, 12, 2 ) )
      xml_node( "pcsap", Str( field->mpcsapp, 12, 2 ) )

      _pr_tr_prev := if( nKalkPrevoz <> 0, nKalkPrevoz / field->fcj2 * 100, 0 )
      _pr_tr_bank := if( nKalkBankTr <> 0, nKalkBankTr / field->fcj2 * 100, 0 )
      _pr_tr_sped := if( nKalkSpedTr <> 0, nKalkSpedTr / field->fcj2 * 100, 0 )
      _pr_tr_car := if( nKalkCarDaz <> 0, nKalkCarDaz / field->fcj2 * 100, 0 )
      _pr_tr_zav := if( nKalkZavTr <> 0, nKalkZavTr / field->fcj2 * 100, 0 )
      _pr_tr_svi := ( _pr_tr_prev + _pr_tr_bank + _pr_tr_sped + _pr_tr_car + _pr_tr_zav )

      xml_node( "tr1p", Str( _pr_tr_prev, 12, 2 ) )
      xml_node( "tr2p", Str( _pr_tr_bank, 12, 2 ) )
      xml_node( "tr3p", Str( _pr_tr_sped, 12, 2 ) )
      xml_node( "tr4p", Str( _pr_tr_car, 12, 2 ) )
      xml_node( "tr5p", Str( _pr_tr_zav, 12, 2 ) )
      xml_node( "trsp", Str( _pr_tr_svi, 12, 2 ) )

      _tmp := nKalkPrevoz + nKalkBankTr + nKalkSpedTr + nKalkCarDaz + nKalkZavTr
      xml_node( "tr1", Str( nKalkPrevoz, 12, 2 ) )
      xml_node( "tr2", Str( nKalkBankTr, 12, 2 ) )
      xml_node( "tr3", Str( nKalkSpedTr, 12, 2 ) )
      xml_node( "tr4", Str( nKalkCarDaz, 12, 2 ) )
      xml_node( "tr5", Str( nKalkZavTr, 12, 2 ) )
      xml_node( "trs", Str( _tmp, 12, 2 ) )

      xml_node( "ufv", Str( _u_fv, 12, 2 ) )
      xml_node( "ufvr", Str( _u_fv_r, 12, 2 ) )
      xml_node( "utr1", Str( _u_tr_prevoz, 12, 2 ) )
      xml_node( "utr2", Str( _u_tr_bank, 12, 2 ) )
      xml_node( "utr3", Str( _u_tr_sped, 12, 2 ) )
      xml_node( "utr4", Str( _u_tr_carina, 12, 2 ) )
      xml_node( "utr5", Str( _u_tr_zavisni, 12, 2 ) )
      xml_node( "utrs", Str( _u_tr_svi, 12, 2 ) )
      xml_node( "unv", Str( _u_nv, 12, 2 ) )
      xml_node( "umarza", Str( _u_marza, 12, 2 ) )
      xml_node( "upv", Str( _u_pv, 12, 2 ) )
      xml_node( "upor", Str( _u_porez, 12, 2 ) )
      xml_node( "upvp", Str( _u_pv_porez, 12, 2 ) )

      xml_subnode( "stavka", .T. )

      SKIP

   ENDDO

   xml_node( "tkol", Str( _t_kol, 12, 2 ) )
   xml_node( "tfv", Str( _t_fv, 12, 2 ) )
   xml_node( "tfvr", Str( _t_fv_r, 12, 2 ) )
   xml_node( "ttr1", Str( _t_tr_prevoz, 12, 2 ) )
   xml_node( "ttr2", Str( _t_tr_bank, 12, 2 ) )
   xml_node( "ttr3", Str( _t_tr_sped, 12, 2 ) )
   xml_node( "ttr4", Str( _t_tr_carina, 12, 2 ) )
   xml_node( "ttr5", Str( _t_tr_zavisni, 12, 2 ) )
   xml_node( "ttrs", Str( _t_tr_svi, 12, 2 ) )
   xml_node( "tnv", Str( _t_nv, 12, 2 ) )
   xml_node( "tmarza", Str( _t_marza, 12, 2 ) )
   xml_node( "tpv", Str( _t_pv, 12, 2 ) )
   xml_node( "tpor", Str( _t_porez, 12, 2 ) )
   xml_node( "tpvp", Str( _t_pv_porez, 12, 2 ) )

   xml_subnode( "kalk", .T. )

   close_xml()

   RETURN _generated




STATIC FUNCTION gen_kalk_vp_xml( hParams )

   LOCAL cIdFirma := hParams[ "id_firma" ]
   LOCAL cIdVd := hParams[ "tip_dok" ]
   LOCAL cBrDok := hParams[ "br_dok" ]
   LOCAL _generated := 0
   LOCAL _xml_file := my_home() + "data.xml"
   LOCAL nTrec
   LOCAL nRbr := 0
   LOCAL nPDVStopa, nPDVCijena
   LOCAL _s_kolicina, _tmp
   LOCAL _u_fv, _t_fv, _u_fv_r, _t_fv_r, _u_tr_prevoz, _u_tr_bank, _u_tr_carina, _u_tr_zavisni, _u_tr_sped, _u_tr_svi
   LOCAL _t_tr_prevoz, _t_tr_bank, _t_tr_carina, _t_tr_zavisni, _t_tr_sped, _t_tr_svi, _u_nv, _t_nv, _u_marza, _t_marza
   LOCAL _u_porez, _t_porez, _u_pv, _t_pv, _u_pv_porez, _t_pv_porez, _t_kol, _u_rabat, _t_rabat
   LOCAL _ima_mpcsapp := .F.

   PRIVATE nKalkPrevoz, nKalkCarDaz, nKalkZavTr, nKalkBankTr, nKalkSpedTr, nKalkMarzaVP, nKalkMarzaMP

   select_o_konto( kalk_pripr->mkonto )
   select_o_partner( kalk_pripr->idpartner )
   select_o_tdok( kalk_pripr->idvd )

   SELECT kalk_pripr

   nTrec := RecNo()

   create_xml( _xml_file )
   xml_head()

   xml_subnode( "kalk", .F. )

   xml_node( "org_id", AllTrim( self_organizacija_id() ) )
   xml_node( "org_naziv", to_xml_encoding( AllTrim( self_organizacija_naziv() ) ) )

   xml_node( "dok_naziv", to_xml_encoding( AllTrim( tdok->naz ) ) )
   xml_node( "dok_tip", field->idvd )
   xml_node( "dok_broj", to_xml_encoding( AllTrim( cBrDok ) ) )
   xml_node( "dok_datum", DToC( field->datdok ) )

   xml_node( "zad_id", to_xml_encoding( AllTrim( field->mkonto ) ) )
   xml_node( "zad_naz", to_xml_encoding( AllTrim( konto->naz ) ) )

   xml_node( "dob_id", to_xml_encoding( AllTrim( field->idpartner ) ) )
   xml_node( "dob_naziv", to_xml_encoding( AllTrim( partn->naz ) ) )
   xml_node( "rn_broj", to_xml_encoding( AllTrim( field->brfaktp ) ) )
   xml_node( "rn_datum", DToC( field->datfaktp ) )

   _u_fv := _t_fv := 0
   _u_fv_r := _t_fv_r := 0
   _u_tr_prevoz := _u_tr_bank := _u_tr_carina := _u_tr_zavisni := _u_tr_sped := _u_tr_svi := 0
   _t_tr_prevoz := _t_tr_bank := _t_tr_carina := _t_tr_zavisni := _t_tr_sped := _t_tr_svi := 0
   _u_nv := _t_nv := _u_marza := _t_marza := 0
   _u_porez := _t_porez := 0
   _u_pv := _t_pv := _u_pv_porez := _t_pv_porez := 0
   _t_kol := 0
   _u_rabat := _t_rabat := 0

   DO WHILE !Eof() .AND. cIdFirma == field->idfirma .AND. cIdVd == field->idvd .AND. cBrDok == field->brdok

      ++_generated

      kalk_pozicioniraj_roba_tarifa_by_kalk_fields()
      kalk_set_vars_troskovi_marzavp_marzamp()

      nPDVStopa := tarifa->pdv

      _ima_mpcsapp := .F.

      IF Round( field->mpcsapp, 2 ) == 0
         nPDVCijena := field->vpc * ( nPDVStopa / 100 )
      ELSE
         nPDVCijena := field->mpcsapp / ( 1 + ( nPDVStopa / 100 ) ) * ( nPDVStopa / 100 )
         _ima_mpcsapp := .T.
      ENDIF

      _s_kolicina := field->kolicina - field->gkolicina - field->gkolicin2
      _t_kol += _s_kolicina

      _u_fv := Round( field->fcj * field->kolicina, gZaokr )
      _u_fv += Round( field->fcj2 * ( field->gkolicina + field->gkolicin2 ), gZaokr )
      _t_fv += _u_fv

      _u_rabat := Round( - field->rabat, gZaokr )
      _t_rabat += _u_rabat

      _u_fv_r := Round( - field->rabat / 100 * field->fcj * field->kolicina, gZaokr )
      _t_fv_r += _u_fv_r

      _u_tr_prevoz := Round( nKalkPrevoz * _s_kolicina, gZaokr )
      _u_tr_bank := Round( nKalkBankTr * _s_kolicina, gZaokr )
      _u_tr_sped := Round( nKalkSpedTr * _s_kolicina, gZaokr )
      _u_tr_carina := Round( nKalkCarDaz * _s_kolicina, gZaokr )
      _u_tr_zavisni := Round( nKalkZavTr * _s_kolicina, gZaokr )
      _u_tr_svi := ( _u_tr_prevoz + _u_tr_bank + _u_tr_sped + _u_tr_carina + _u_tr_zavisni )

      _t_tr_prevoz += _u_tr_prevoz
      _t_tr_bank += _u_tr_bank
      _t_tr_sped += _u_tr_sped
      _t_tr_carina += _u_tr_carina
      _t_tr_zavisni += _u_tr_zavisni
      _t_tr_svi += _u_tr_svi

      _u_nv := Round( field->nc * _s_kolicina, gZaokr )
      _t_nv += _u_nv

      _u_marza := Round( nKalkMarzaVP * _s_kolicina, gZaokr )
      _t_marza += _u_marza

      _u_pv := Round( field->vpc * _s_kolicina, gZaokr )
      _t_pv += _u_pv

      _u_porez := ( nPDVCijena * field->kolicina )
      _t_porez += _u_porez

      IF _ima_mpcsapp
         _u_pv_porez := ( field->mpcsapp * field->kolicina )
      ELSE
         _u_pv_porez := _u_pv + _u_porez
      ENDIF
      _t_pv_porez += _u_pv_porez

      xml_subnode( "stavka", .F. )

      xml_node( "art_id", to_xml_encoding( AllTrim( field->idroba ) ) )
      xml_node( "art_naz", to_xml_encoding( AllTrim( roba->naz ) ) )
      xml_node( "art_jmj", to_xml_encoding( AllTrim( roba->jmj ) ) )
      xml_node( "tarifa", to_xml_encoding( AllTrim( field->idtarifa ) ) )
      xml_node( "rbr", PadL( AllTrim( Str( ++nRbr ) ), 4 ) + "." )

      xml_node( "kol", Str( field->kolicina, 12, 2 ) )
      xml_node( "g_kol", Str( field->gkolicina, 12, 2 ) )
      xml_node( "g_kol2", Str( field->gkolicin2, 12, 2 ) )
      xml_node( "skol", Str( _s_kolicina, 12, 2 ) )

      xml_node( "fcj", Str( field->fcj, 12, 2 ) )
      xml_node( "rabat", Str( - field->rabat, 12, 2 ) )
      xml_node( "fcjr", Str( - field->rabat / 100 * field->fcj, 12, 2 ) )
      xml_node( "nc", Str( field->nc, 12, 2 ) )
      xml_node( "marzap", Str( nKalkMarzaVP / field->nc * 100, 12, 2 ) )
      xml_node( "marza", Str( nKalkMarzaVP, 12, 2 ) )
      xml_node( "pc", Str( field->vpc, 12, 2 ) )
      xml_node( "por_st", Str( nPDVStopa, 12, 2 ) )
      xml_node( "porez", Str( nPDVCijena, 12, 2 ) )

      IF _ima_mpcsapp
         xml_node( "pcsap", Str( field->mpcsapp, 12, 2 ) )
      ELSE
         xml_node( "pcsap", Str( field->vpc + nPDVCijena, 12, 2 ) )
      ENDIF

      IF Round( field->fcj2, 4 ) != 0
         _pr_tr_prev := nKalkPrevoz / field->fcj2 * 100
         _pr_tr_bank := nKalkBankTr / field->fcj2 * 100
         _pr_tr_sped := nKalkSpedTr / field->fcj2 * 100
         _pr_tr_car := nKalkCarDaz / field->fcj2 * 100
         _pr_tr_zav := nKalkZavTr / field->fcj2 * 100
         _pr_tr_svi := ( _pr_tr_prev + _pr_tr_bank + _pr_tr_sped + _pr_tr_car + _pr_tr_zav )

      ELSE

         _pr_tr_prev := 0
         _pr_tr_bank := 0
         _pr_tr_sped := 0
         _pr_tr_car := 0
         _pr_tr_zav := 0
         _pr_tr_svi := 0

      ENDIF

      xml_node( "tr1p", Str( _pr_tr_prev, 12, 2 ) )
      xml_node( "tr2p", Str( _pr_tr_bank, 12, 2 ) )
      xml_node( "tr3p", Str( _pr_tr_sped, 12, 2 ) )
      xml_node( "tr4p", Str( _pr_tr_car, 12, 2 ) )
      xml_node( "tr5p", Str( _pr_tr_zav, 12, 2 ) )
      xml_node( "trsp", Str( _pr_tr_svi, 12, 2 ) )

      _tmp := nKalkPrevoz + nKalkBankTr + nKalkSpedTr + nKalkCarDaz + nKalkZavTr
      xml_node( "tr1", Str( nKalkPrevoz, 12, 2 ) )
      xml_node( "tr2", Str( nKalkBankTr, 12, 2 ) )
      xml_node( "tr3", Str( nKalkSpedTr, 12, 2 ) )
      xml_node( "tr4", Str( nKalkCarDaz, 12, 2 ) )
      xml_node( "tr5", Str( nKalkZavTr, 12, 2 ) )
      xml_node( "trs", Str( _tmp, 12, 2 ) )

      xml_node( "ufv", Str( _u_fv, 12, 2 ) )
      xml_node( "ufvr", Str( _u_fv_r, 12, 2 ) )
      xml_node( "utr1", Str( _u_tr_prevoz, 12, 2 ) )
      xml_node( "utr2", Str( _u_tr_bank, 12, 2 ) )
      xml_node( "utr3", Str( _u_tr_sped, 12, 2 ) )
      xml_node( "utr4", Str( _u_tr_carina, 12, 2 ) )
      xml_node( "utr5", Str( _u_tr_zavisni, 12, 2 ) )
      xml_node( "utrs", Str( _u_tr_svi, 12, 2 ) )
      xml_node( "unv", Str( _u_nv, 12, 2 ) )
      xml_node( "umarza", Str( _u_marza, 12, 2 ) )
      xml_node( "upv", Str( _u_pv, 12, 2 ) )
      xml_node( "upor", Str( _u_porez, 12, 2 ) )
      xml_node( "upvp", Str( _u_pv_porez, 12, 2 ) )

      xml_subnode( "stavka", .T. )

      SKIP

   ENDDO

   xml_node( "tkol", Str( _t_kol, 12, 2 ) )
   xml_node( "tfv", Str( _t_fv, 12, 2 ) )
   xml_node( "trab", Str( _t_rabat, 12, 2 ) )
   xml_node( "tfvr", Str( _t_fv_r, 12, 2 ) )
   xml_node( "ttr1", Str( _t_tr_prevoz, 12, 2 ) )
   xml_node( "ttr2", Str( _t_tr_bank, 12, 2 ) )
   xml_node( "ttr3", Str( _t_tr_sped, 12, 2 ) )
   xml_node( "ttr4", Str( _t_tr_carina, 12, 2 ) )
   xml_node( "ttr5", Str( _t_tr_zavisni, 12, 2 ) )
   xml_node( "ttrs", Str( _t_tr_svi, 12, 2 ) )
   xml_node( "tnv", Str( _t_nv, 12, 2 ) )
   xml_node( "tmarza", Str( _t_marza, 12, 2 ) )
   xml_node( "tpv", Str( _t_pv, 12, 2 ) )
   xml_node( "tpor", Str( _t_porez, 12, 2 ) )
   xml_node( "tpvp", Str( _t_pv_porez, 12, 2 ) )

   xml_subnode( "kalk", .T. )

   close_xml()

   RETURN _generated
