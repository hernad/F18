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

MEMVAR gZaokr


/* -----------------------------------------------
 pomocna tabela finansijskog stanja magacina

 uslovi koji se u hash matrici trebaju koristi
 su:
 - "vise_konta" (D/N)
 - "konto" (lista konta ili jedan konto)
 - "datum_od"
 - "datum_do"
 - "tarife"
 - "vrste_dok"

koristi TKV

*/


FUNCTION vpc_magacin_rs_priprema()
   RETURN vpc_magacin_rs( .T. )


FUNCTION vpc_magacin_rs( lKalkPriprema )

   LOCAL nVPC, nAlias

   hb_default( @lKalkPriprema, .F. )

altd()
   IF lKalkPriprema
      IF kalk_pripr->IdVd $ "14#10#KO" // u dokumentu je vpc
         nVPC := kalk_pripr->vpc
      ELSE
         // HACK: u dokument nije pohranjena vpc, uzeti iz robe
         // select_o_roba( kalk->idroba ) ne treba ovo je vec uradjeno u nadfunkciji
         IF kalk_pripr->idpartner == PadR( "118169", 7 ) // HACK-2: majop
            nVPC := roba->vpc2
         ELSE
            nVPC := roba->vpc
         ENDIF
      ENDIF

   ELSE
      IF kalk->IdVd $ "14#10#KO"
         nVPC := kalk->vpc
      ELSE
         // select_o_roba( kalk->idroba ) ne treba ovo je vec uradjeno u nadfunkciji
         IF kalk->idpartner == PadR( "118169", 7 ) // majop
            nVPC := roba->vpc2
         ELSE
            nVPC := roba->vpc
         ENDIF
      ENDIF
   ENDIF

   RETURN nVPC



STATIC FUNCTION kalk_fin_stanje_add_to_r_export( cIdFirma, cIdVd, cBrDok, dDatDok, cVrstaDokumenta, cIdPartner, ;
      part_naz, part_mjesto, part_ptt, part_adr, broj_fakture, ;
      n_v_dug, n_v_pot, n_v_saldo, ;
      v_p_dug, v_p_pot, v_p_saldo, ;
      v_p_rabat, marza, marza_2, tr_prevoz, tr_prevoz_2, ;
      tr_bank, tr_sped, tr_carina, tr_zavisni )

   LOCAL nDbfArea := Select()
   LOCAL hRec

   o_r_export()

   APPEND BLANK

   hRec := hb_Hash()
   hRec[ "idfirma" ] := cIdFirma
   hRec[ "idvd" ] := cIdVd
   hRec[ "brdok" ] := cBrDok
   hRec[ "datum" ] := dDatDok
   hRec[ "vr_dok" ] := cVrstaDokumenta
   hRec[ "idpartner" ] := cIdPartner
   hRec[ "part_naz" ] := part_naz
   hRec[ "part_mj" ] := part_mjesto
   hRec[ "part_ptt" ] := part_ptt
   hRec[ "part_adr" ] := part_adr
   hRec[ "br_fakt" ] := broj_fakture
   hRec[ "nv_dug" ] := n_v_dug
   hRec[ "nv_pot" ] := n_v_pot
   hRec[ "nv_saldo" ] := n_v_saldo
   hRec[ "vp_dug" ] := v_p_dug
   hRec[ "vp_pot" ] := v_p_pot
   hRec[ "vp_saldo" ] := v_p_saldo
   hRec[ "vp_rabat" ] := v_p_rabat
   hRec[ "marza" ] := marza
   hRec[ "marza2" ] := marza_2
   hRec[ "t_prevoz" ] := tr_prevoz
   hRec[ "t_prevoz2" ] := tr_prevoz_2
   hRec[ "t_bank" ] := tr_bank
   hRec[ "t_sped" ] := tr_sped
   hRec[ "t_cardaz" ] := tr_carina
   hRec[ "t_zav" ] := tr_zavisni

   dbf_update_rec( hRec )

   SELECT ( nDbfArea )

   RETURN .T.
