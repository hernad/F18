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


/* -----------------------------------------------
 pomocna tabela finansijskog stanja prodavnice

 uslovi koji se u hash matrici trebaju koristi
 su:
 - "vise_konta" (D/N)
 - "konto" (lista konta ili jedan konto)
 - "datum_od"
 - "datum_do"
 - "tarife"
 - "vrste_dok"

koristi TKM

*/

FUNCTION kalk_gen_fin_stanje_prodavnice( hParamsIn )

   LOCAL cIdKonto := ""
   LOCAL _datum_od := Date()
   LOCAL _datum_do := Date()
   LOCAL _tarife := ""
   LOCAL _vrste_dok := ""
   LOCAL cIdFirma := self_organizacija_id()
   LOCAL _vise_konta := .F.
   LOCAL nDbfArea, nTrec
   LOCAL _ulaz, _izlaz, _rabatv, _rabatm
   LOCAL _nv_ulaz, _nv_izlaz, _mp_ulaz, _mp_izlaz, _mp_ulaz_p, _mp_izlaz_p
   LOCAL _tr_prevoz, _tr_prevoz_2
   LOCAL _tr_bank, _tr_zavisni, _tr_carina, _tr_sped
   LOCAL _br_fakt, _tip_dok, _tip_dok_naz, _id_partner
   LOCAL _partn_naziv, _partn_ptt, _partn_mjesto, _partn_adresa
   LOCAL _broj_dok, _dat_dok
   LOCAL _usl_konto := ""
   LOCAL _usl_vrste_dok := ""
   LOCAL _usl_tarife := ""
   LOCAL _v_konta := "N"
   LOCAL _gledati_usluge := "N"
   LOCAL _cnt := 0
   LOCAL _a_porezi
   LOCAL __porez, _porez, _d_opis
   LOCAL hParams

   aPorezi := {}


   hParams := hb_Hash()
   hParams[ "idfirma" ] := cIdFirma


   IF hb_HHasKey( hParamsIn, "datum_od" )
      hParams[ "dat_od" ] := hParamsIn[ "datum_od" ]
   ENDIF

   IF hb_HHasKey( hParamsIn, "datum_do" )
      hParams[ "dat_do" ] := hParamsIn[ "datum_do" ]
   ENDIF

   hParams[ "order_by" ] := "idFirma,datdok,idvd,brdok,rbr"


   IF hb_HHasKey( hParamsIn, "vise_konta" )
      _v_konta := hParamsIn[ "vise_konta" ]
   ENDIF


   IF hb_HHasKey( hParamsIn, "tarife" )
      _tarife := hParamsIn[ "tarife" ]
   ENDIF

   IF hb_HHasKey( hParamsIn, "vrste_dok" )
      _vrste_dok := hParamsIn[ "vrste_dok" ]
   ENDIF

   IF hb_HHasKey( hParamsIn, "gledati_usluge" )
      _gledati_usluge := hParamsIn[ "gledati_usluge" ]
   ENDIF

   IF hb_HHasKey( hParamsIn, "konto" )
      cIdKonto :=  hParamsIn[ "konto" ]
   ENDIF

   _cre_tmp_tbl()
   _o_tbl()

   IF _v_konta == "D"
      _vise_konta := .T.
   ENDIF

   IF _vise_konta
      IF !Empty( cIdKonto )
         _usl_konto := Parsiraj( cIdKonto, "pkonto" )
      ENDIF
   ELSE

      IF Len( Trim( cIdKonto ) ) == 3
         cIdKonto := Trim( cIdKonto )
         hParams[ "pkonto_sint" ] := cIdKonto
      ELSE
         hParams[ "pkonto" ] := cIdKonto
      ENDIF

   ENDIF

   IF !Empty( _tarife )
      _usl_tarife := Parsiraj( _tarife, "idtarifa" )
   ENDIF

   IF !Empty( _vrste_dok )
      _usl_vrste_dok := Parsiraj( _vrste_dok, "idvd" )
   ENDIF

   MsgO( "Preuzimanje podataka sa SQL servera ..." )
   find_kalk_za_period( hParams )
   MsgC()

/*
   SELECT kalk
   SET ORDER TO TAG "5"  CREATE_INDEX( "5", "idFirma+dtos(datdok)+podbr+idvd+brdok", _alias )
   HSEEK cIdFirma
  */


   select_o_koncij( cIdKonto )

   SELECT kalk

   Box(, 2, 60 )

   @ box_x_koord() + 1, box_y_koord() + 2 SAY8 PadR( "Generisanje pomoćne tabele u toku...", 58 ) COLOR f18_color_i()

   DO WHILE !Eof() .AND. cIdFirma == field->idfirma .AND. IspitajPrekid()


      IF _vise_konta .AND. !Empty( _usl_konto )
         IF !Tacno( _usl_konto )
            SKIP
            LOOP
         ENDIF
      ENDIF

      IF !Empty( _usl_vrste_dok )
         IF !Tacno( _usl_vrste_dok )
            SKIP
            LOOP
         ENDIF
      ENDIF

      IF !Empty( _usl_tarife )
         IF !Tacno( _usl_tarife )
            SKIP
            LOOP
         ENDIF
      ENDIF

      _ulaz := 0
      _izlaz := 0
      _mp_ulaz := 0
      _mp_ulaz_p := 0
      _mp_izlaz := 0
      _mp_izlaz_p := 0
      _nv_ulaz := 0
      _nv_izlaz := 0
      _rabatv := 0
      _rabatm := 0
      _tr_bank := 0
      _tr_zavisni := 0
      _tr_carina := 0
      _tr_prevoz := 0
      _tr_prevoz_2 := 0
      _tr_sped := 0
      _porez := 0

      _id_d_firma := field->idfirma
      _d_br_dok := field->brdok
      _br_fakt := field->brfaktp
      _id_partner := field->idpartner
      _dat_dok := field->datdok
      _broj_dok := field->idvd + "-" + field->brdok
      _tip_dok := field->idvd
      _d_opis := ""

      IF field->idvd == "80" .AND. !Empty( field->idkonto2 )
         _d_opis := "predispozicija " + AllTrim( field->idkonto ) + " -> " + AllTrim( field->idkonto2 )
      ENDIF

      SELECT tdok
      HSEEK _tip_dok
      _tip_dok_naz := field->naz

      IF !Empty( _id_partner )
         select_o_partner( _id_partner )

         _partn_naziv := field->naz
         _partn_ptt := field->ptt
         _partn_mjesto := field->mjesto
         _partn_adresa := field->adresa

      ELSE

         _partn_naziv := ""
         _partn_ptt := ""
         _partn_mjesto := ""
         _partn_adresa := ""

         IF _tip_dok $ "41#42"
            _partn_naziv := "prodavnica " + AllTrim( kalk->pkonto )
         ENDIF

      ENDIF


      SELECT KALK
      DO WHILE !Eof() .AND. cIdFirma + DToS( _dat_dok ) + _broj_dok == field->idfirma + DToS( field->datdok ) + field->idvd + "-" + field->brdok .AND. IspitajPrekid()

         IF _vise_konta .AND. !Empty( _usl_konto )
            IF !Tacno( _usl_konto )
               SKIP
               LOOP
            ENDIF
         ENDIF

         IF !Empty( _usl_vrste_dok )
            IF !Tacno( _usl_vrste_dok )
               SKIP
               LOOP
            ENDIF
         ENDIF

         IF !Empty( _usl_tarife )
            IF !Tacno( _usl_tarife )
               SKIP
               LOOP
            ENDIF
         ENDIF

         select_o_roba( kalk->idroba )

         IF ( _gledati_usluge == "N" .AND. roba->tip $ "U" )
            SELECT kalk
            SKIP
            LOOP
         ENDIF

         select_o_tarifa( kalk->idtarifa )

         SELECT kalk

         set_pdv_array_by_koncij_region_roba_idtarifa_2_3( field->pkonto, field->idRoba, @aPorezi )

         set_pdv_public_vars()

         IF field->pu_i == "1"

            _mp_ulaz += field->mpc * field->kolicina
            _mp_ulaz_p += field->mpcsapp * field->kolicina
            _nv_ulaz += field->nc * field->kolicina

         ELSEIF field->pu_i == "5"

            _a_porezi := kalk_porezi_maloprodaja_legacy_array( aPorezi, field->mpc, field->mpcsapp, field->nc )

            __porez := _a_porezi[ 1 ]

            IF field->idvd $ "12#13"

               _mp_ulaz -= field->mpc * field->kolicina
               _mp_ulaz_p -= field->mpcsapp * field->kolicina
               _nv_ulaz -= field->nc * field->kolicina
               _porez -= __porez * field->kolicina

               _rabatv -= field->rabatv * field->kolicina
               IF tarifa->opp <> 0
                  _rabatm -= field->kolicina * ( field->rabatv * ( 1 + tarifa->opp / 100 ) )
               ELSE
                  _rabatm -= field->kolicina * field->rabatv
               ENDIF

            ELSE

               _mp_izlaz += field->mpc * field->kolicina
               _mp_izlaz_p += field->mpcsapp * field->kolicina
               _nv_izlaz += field->nc * field->kolicina
               _porez += __porez * field->kolicina

               _rabatv += field->rabatv * field->kolicina
               IF tarifa->opp <> 0
                  _rabatm += field->kolicina * ( field->rabatv * ( 1 + tarifa->opp / 100 ) )
               ELSE
                  _rabatm += field->kolicina * field->rabatv
               ENDIF

            ENDIF

         ELSEIF field->pu_i == "3"

            _mp_ulaz += field->mpc * field->kolicina
            _mp_ulaz_p += field->mpcsapp * field->kolicina

         ELSEIF field->pu_i == "I"

            set_pdv_array_by_koncij_region_roba_idtarifa_2_3( field->pkonto, field->idRoba, @aPorezi )

            _mp_izlaz += kalk_mpc_by_vrsta_dokumenta( field->idvd, aPorezi ) * field->gkolicin2
            _mp_izlaz_p += field->mpcsapp * field->gkolicin2
            _nv_izlaz += field->nc * field->gkolicin2

         ENDIF

         SKIP

      ENDDO


      @ box_x_koord() + 2, box_y_koord() + 2 SAY "Dokument: " + _id_d_firma + "-" + _tip_dok + "-" + _d_br_dok

      insert_into_rexport( _id_d_firma, _tip_dok, _d_br_dok, _d_opis, _dat_dok, _tip_dok_naz, _id_partner, ;
         _partn_naziv, _partn_mjesto, _partn_ptt, _partn_adresa, _br_fakt, ;
         _nv_ulaz, _nv_izlaz, _nv_ulaz - _nv_izlaz, ;
         _mp_ulaz, _mp_izlaz, _mp_ulaz - _mp_izlaz, ;
         _mp_ulaz_p, _mp_izlaz_p, _mp_ulaz_p - _mp_izlaz_p, ;
         _rabatv, _rabatm, _porez, 0, 0, 0, 0, 0, 0 )

      ++ _cnt

   ENDDO

   BoxC()

   RETURN _cnt


STATIC FUNCTION _cre_tmp_tbl()

   LOCAL _dbf := {}

   AAdd( _dbf, { "idfirma", "C",  2, 0 } )
   AAdd( _dbf, { "idvd", "C",  2, 0 } )
   AAdd( _dbf, { "brdok", "C",  8, 0 } )
   AAdd( _dbf, { "datum", "D",  8, 0 } )
   AAdd( _dbf, { "vr_dok", "C", 30, 0 } )
   AAdd( _dbf, { "idpartner", "C",  6, 0 } )
   AAdd( _dbf, { "part_naz", "C", 100, 0 } )
   AAdd( _dbf, { "part_mj", "C", 50, 0 } )
   AAdd( _dbf, { "part_ptt", "C", 10, 0 } )
   AAdd( _dbf, { "part_adr", "C", 50, 0 } )
   AAdd( _dbf, { "br_fakt", "C", 20, 0 } )
   AAdd( _dbf, { "opis", "C", 50, 0 } )
   AAdd( _dbf, { "nv_dug", "N", 18, 5 } )
   AAdd( _dbf, { "nv_pot", "N", 18, 5 } )
   AAdd( _dbf, { "nv_saldo", "N", 18, 5 } )
   AAdd( _dbf, { "mp_dug", "N", 18, 5 } )
   AAdd( _dbf, { "mp_pot", "N", 18, 5 } )
   AAdd( _dbf, { "mp_saldo", "N", 18, 5 } )
   AAdd( _dbf, { "mpp_dug", "N", 18, 5 } )
   AAdd( _dbf, { "mpp_pot", "N", 18, 5 } )
   AAdd( _dbf, { "mpp_saldo", "N", 18, 5 } )
   AAdd( _dbf, { "vp_rabat", "N", 18, 5 } )
   AAdd( _dbf, { "mp_rabat", "N", 18, 5 } )
   AAdd( _dbf, { "mp_porez", "N", 18, 5 } )
   AAdd( _dbf, { "t_prevoz", "N", 18, 5 } )
   AAdd( _dbf, { "t_prevoz2", "N", 18, 5 } )
   AAdd( _dbf, { "t_bank", "N", 18, 5 } )
   AAdd( _dbf, { "t_sped", "N", 18, 5 } )
   AAdd( _dbf, { "t_cardaz", "N", 18, 5 } )
   AAdd( _dbf, { "t_zav", "N", 18, 5 } )

   create_dbf_r_export( _dbf )

   RETURN _dbf


STATIC FUNCTION insert_into_rexport( id_firma, id_tip_dok, broj_dok, d_opis, datum_dok, vrsta_dok, id_partner, ;
      part_naz, part_mjesto, part_ptt, part_adr, broj_fakture, ;
      n_v_dug, n_v_pot, n_v_saldo, ;
      m_p_dug, m_p_pot, m_p_saldo, ;
      m_pp_dug, m_pp_pot, m_pp_saldo, ;
      v_p_rabat, m_p_rabat, m_p_porez, tr_prevoz, tr_prevoz_2, ;
      tr_bank, tr_sped, tr_carina, tr_zavisni )

   LOCAL nDbfArea := Select()
   LOCAL hRec

   o_r_export()

   APPEND BLANK

   hRec := hb_Hash()
   hRec[ "idfirma" ] := id_firma
   hRec[ "idvd" ] := id_tip_dok
   hRec[ "brdok" ] := broj_dok
   hRec[ "opis" ] := d_opis
   hRec[ "datum" ] := datum_dok
   hRec[ "vr_dok" ] := vrsta_dok
   hRec[ "idpartner" ] := id_partner
   hRec[ "part_naz" ] := part_naz
   hRec[ "part_mj" ] := part_mjesto
   hRec[ "part_ptt" ] := part_ptt
   hRec[ "part_adr" ] := part_adr
   hRec[ "br_fakt" ] := broj_fakture
   hRec[ "nv_dug" ] := n_v_dug
   hRec[ "nv_pot" ] := n_v_pot
   hRec[ "nv_saldo" ] := n_v_saldo
   hRec[ "mp_dug" ] := m_p_dug
   hRec[ "mp_pot" ] := m_p_pot
   hRec[ "mp_saldo" ] := m_p_saldo
   hRec[ "mpp_dug" ] := m_pp_dug
   hRec[ "mpp_pot" ] := m_pp_pot
   hRec[ "mpp_saldo" ] := m_pp_saldo
   hRec[ "mp_rabat" ] := m_p_rabat
   hRec[ "vp_rabat" ] := v_p_rabat
   hRec[ "mp_porez" ] := m_p_porez
   hRec[ "t_prevoz" ] := tr_prevoz
   hRec[ "t_prevoz2" ] := tr_prevoz_2
   hRec[ "t_bank" ] := tr_bank
   hRec[ "t_sped" ] := tr_sped
   hRec[ "t_cardaz" ] := tr_carina
   hRec[ "t_zav" ] := tr_zavisni

   dbf_update_rec( hRec )

   SELECT ( nDbfArea )

   RETURN .T.




STATIC FUNCTION _o_tbl()

   // o_kalk_doks()
   // o_kalk()
//   o_sifk()
//   o_sifv()
   o_tdok()
  // o_roba()
//   o_tarifa()
//   o_koncij()
  // o_konto()
//   o_partner()

   RETURN .T.
