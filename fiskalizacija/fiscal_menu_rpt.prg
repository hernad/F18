/*
 * This file is part of the bring.out FMK, a free and open source
 * accounting software suite,
 * Copyright (c) 1996-2011 by bring.out doo Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including FMK specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_FMK.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */


#include "f18.ch"

STATIC s_nFiskalniDeviceId
STATIC s_hFiskalniDeviceParams


FUNCTION fiskalni_izvjestaji_komande( lObicniUser, lPozivFromPOS )

   LOCAL _dev_id := 0
   LOCAL cFiskalniDrajver
   LOCAL _m_x
   LOCAL _m_y
   LOCAL hParams := hb_hash()


   LOCAL nIzbor := 1
   LOCAL aOpc := {}
   LOCAL aOpcExe := {}

   IF lObicniUser == NIL
      lObicniUser := .F.
   ENDIF

   IF lPozivFromPOS == NIL
      lPozivFromPOS := .F.
   ENDIF

   hParams[ "idpos" ] := pos_pm()
   create_pos_tmp( hParams )
   cleanup_pos_tmp( hParams )

   s_nFiskalniDeviceId := odaberi_fiskalni_uredjaj( NIL, lPozivFromPOS, .F. )

   IF s_nFiskalniDeviceId == 0
      RETURN .F.
   ENDIF

   s_hFiskalniDeviceParams := get_fiscal_device_params( s_nFiskalniDeviceId, my_user() )

   IF s_hFiskalniDeviceParams == NIL
      MsgBeep( "Fiskalni parametri nisu podešeni,#fiskalne funkcije nedostupne." )
      RETURN .F.
   ENDIF

   cFiskalniDrajver := s_hFiskalniDeviceParams[ "drv" ]

   DO CASE

   CASE cFiskalniDrajver == "OFS"

      AAdd( aOpc, "1. promet fiskalni za period" )
      AAdd( aOpcExe, {|| ofs_invoice_search() } )

      AAdd( aOpc, "2. sadrzaj fiskalnog racuna" )
      AAdd( aOpcExe, {|| ofs_invoice_get() } )

      AAdd( aOpc, "3. status - osnovne informacije" )
      AAdd( aOpcExe, {|| ofs_status(NIL, "S") } )

      AAdd( aOpc, "4. status - porezne stope" )
      AAdd( aOpcExe, {|| ofs_status(NIL, "P") } )

      AAdd( aOpc, "5. postmp ciscenje" )
      AAdd( aOpcExe, {|| ofs_cleanup() } )

      AAdd( aOpc, "6. test hello curl" )
      AAdd( aOpcExe, {|| curl_hello() } )

#ifdef F18_DEBUG
      AAdd( aOpc, "T. test create invoice" )
      AAdd( aOpcExe, {|| ofs_create_test_invoice() } )
#endif

   CASE cFiskalniDrajver == "FLINK"

      AAdd( aOpc, "------ izvještaji ---------------------------------" )
      AAdd( aOpcExe, {|| NIL } )

      AAdd( aOpc, "1. dnevni izvještaj  (Z-rep / X-rep)          " )
      AAdd( aOpcExe, {|| flink_dnevni_izvjestaj() } )

      AAdd( aOpc, "------ ostale komande --------------------" )
      AAdd( aOpcExe, {|| NIL } )

      AAdd( aOpc, "5. unos depozita u uređaj       " )
      AAdd( aOpcExe, {|| flink_polog() } )

      AAdd( aOpc, "6. poništi otvoren racun      " )
      AAdd( aOpcExe, {|| flink_reset_racuna() } )

   CASE cFiskalniDrajver == "FPRINT"

      IF !lObicniUser

         AAdd( aOpc, "------ izvještaji ---------------------------------" )
         AAdd( aOpcExe, {|| NIL } )

         AAdd( aOpc, "1. dnevni izvještaj  (Z-rep / X-rep)          " )
         AAdd( aOpcExe, {|| fprint_daily_rpt( s_hFiskalniDeviceParams ) } )

         AAdd( aOpc, "2. periodični izvještaj" )
         AAdd( aOpcExe, {|| fprint_izvjestaj_za_period( s_hFiskalniDeviceParams ) } )

         AAdd( aOpc, "3. pregled artikala " )
         AAdd( aOpcExe, {|| fprint_sold_plu( s_hFiskalniDeviceParams ) } )

      ENDIF

      AAdd( aOpc, "------ ostale komande --------------------" )
      AAdd( aOpcExe, {|| NIL } )

      AAdd( aOpc, "5. unos depozita u uredjaj       " )
      AAdd( aOpcExe, {|| fprint_unos_pologa(s_hFiskalniDeviceParams) } )

      AAdd( aOpc, "6. duplikat računa - po broju" )
      AAdd( aOpcExe, {|| fprint_print_kopija_rn(s_hFiskalniDeviceParams, 0) } )

      AAdd( aOpc, "7. zatvori račun (cmd 56)       " )
      AAdd( aOpcExe, {|| fiscal_fprint_zatvori_racun(s_hFiskalniDeviceParams) } )

      AAdd( aOpc, "8. zatvori nasilno račun (cmd 301) " )
      AAdd( aOpcExe, {|| fprint_komanda_301_zatvori_racun(s_hFiskalniDeviceParams) } )

      AAdd( aOpc, "9. deblokada fiskalnog uređaja" )
      AAdd( aOpcExe, {||  fprint_komanda_deblokada(s_hFiskalniDeviceParams) } )

      IF !lObicniUser

         AAdd( aOpc, "V. duplikat - prema vremenu " )
         AAdd( aOpcExe, {|| fprint_dupliciraj_racun_vrijeme(s_hFiskalniDeviceParams) } )
   
         AAdd( aOpc, "P. proizvoljna komanda " )
         AAdd( aOpcExe, {|| fprint_manual_cmd( s_hFiskalniDeviceParams ) } )

         IF s_hFiskalniDeviceParams[ "type" ] == "P"
            AAdd( aOpc, "A. brisanje artikala iz uređaja (cmd 107)" )
            AAdd( aOpcExe, {|| fprint_delete_plu( s_hFiskalniDeviceParams, .F. ) } )
         ENDIF

         AAdd( aOpc, "B. reset PLU " )
         AAdd( aOpcExe, {|| auto_plu( .T., NIL, s_hFiskalniDeviceParams ) } )

         AAdd( aOpc, "C. non-fiscal racun - test" )
         AAdd( aOpcExe, {|| fprint_non_fiscal_text( s_hFiskalniDeviceParams, "ČčĆćŽžĐđŠš" ) } )

         AAdd( aOpc, "T. test email" )
         AAdd( aOpcExe, {|| f18_email_test() } )

      ENDIF


   CASE cFiskalniDrajver == "HCP"

      IF !lObicniUser
         AAdd( aOpc, "------ izvještaji -----------------------" )
         AAdd( aOpcExe, {|| .F. } )
         AAdd( aOpc, "1. dnevni fiskalni izvještaj (Z rep.)    " )
         AAdd( aOpcExe, {|| hcp_z_rpt( s_hFiskalniDeviceParams ) } )
         AAdd( aOpc, "2. presjek stanja (X rep.)    " )
         AAdd( aOpcExe, {|| hcp_x_rpt( s_hFiskalniDeviceParams ) } )

         AAdd( aOpc, "3. periodični izvjestaj (Z rep.)    " )
         AAdd( aOpcExe, {|| hcp_s_rpt( s_hFiskalniDeviceParams ) } )
      ENDIF

      AAdd( aOpc, "------ ostale komande --------------------" )
      AAdd( aOpcExe, {|| .F. } )

      AAdd( aOpc, "5. kopija računa    " )
      AAdd( aOpcExe, {|| hcp_rn_copy( s_hFiskalniDeviceParams ) } )
      AAdd( aOpc, "6. unos depozita u uređaj    " )
      AAdd( aOpcExe, {|| hcp_polog( s_hFiskalniDeviceParams ) } )
      AAdd( aOpc, "7. pošalji cmd.ok    " )
      AAdd( aOpcExe, {|| hcp_create_cmd_ok( s_hFiskalniDeviceParams ) } )

      IF !lObicniUser

         AAdd( aOpc, "8. izbaci stanje računa    " )
         AAdd( aOpcExe, {|| fiskalni_hcp_get_broj_racuna( s_hFiskalniDeviceParams ) } )
         AAdd( aOpc, "P. reset PLU " )
         AAdd( aOpcExe, {|| auto_plu( .T., NIL, s_hFiskalniDeviceParams ) } )

      ENDIF

   CASE cFiskalniDrajver == "TREMOL"

      IF !lObicniUser

         AAdd( aOpc, "------ izvještaji -----------------------" )
         AAdd( aOpcExe, {|| .F. } )

         AAdd( aOpc, "1. dnevni fiskalni izvještaj (Z rep.)    " )
         AAdd( aOpcExe, {|| tremol_z_rpt( s_hFiskalniDeviceParams ) } )

         AAdd( aOpc, "2. izvještaj po artiklima (Z rep.)    " )
         AAdd( aOpcExe, {|| tremol_z_item( s_hFiskalniDeviceParams ) } )

         AAdd( aOpc, "3. presjek stanja (X rep.)    " )
         AAdd( aOpcExe, {|| tremol_x_rpt( s_hFiskalniDeviceParams ) } )

         AAdd( aOpc, "4. izvještaj po artiklima (X rep.)    " )
         AAdd( aOpcExe, {|| tremol_x_item( s_hFiskalniDeviceParams ) } )

         AAdd( aOpc, "5. periodični izvjestaj (Z rep.)    " )
         AAdd( aOpcExe, {|| tremol_per_rpt( s_hFiskalniDeviceParams ) } )

      ENDIF

      AAdd( aOpc, "------ ostale komande --------------------" )
      AAdd( aOpcExe, {|| .F. } )

      AAdd( aOpc, "K. kopija računa    " )
      AAdd( aOpcExe, {|| tremol_stampa_kopije_racuna( s_hFiskalniDeviceParams ) } )

      IF !lObicniUser

         AAdd( aOpc, "R. reset artikala    " )
         AAdd( aOpcExe, {|| tremol_reset_plu_artikla( s_hFiskalniDeviceParams ) } )

      ENDIF

      AAdd( aOpc, "P. unos depozita u uređaj    " )
      AAdd( aOpcExe, {|| tremol_polog( s_hFiskalniDeviceParams ) } )

      IF !lObicniUser
         AAdd( aOpc, "R. reset PLU " )
         AAdd( aOpcExe, {|| auto_plu( .T., NIL, s_hFiskalniDeviceParams ) } )
      ENDIF


   CASE cFiskalniDrajver == "TRING"

      IF !lObicniUser

         AAdd( aOpc, "------ izvještaji ---------------------------------" )
         AAdd( aOpcExe, {|| NIL } )
         AAdd( aOpc, "1. dnevni izvještaj                               " )
         AAdd( aOpcExe, {|| tring_daily_rpt( s_hFiskalniDeviceParams ) } )
         AAdd( aOpc, "2. periodični izvjestaj" )
         AAdd( aOpcExe, {|| tring_per_rpt( s_hFiskalniDeviceParams ) } )
         AAdd( aOpc, "3. presjek stanja" )
         AAdd( aOpcExe, {|| tring_x_rpt( s_hFiskalniDeviceParams ) } )

      ENDIF

      AAdd( aOpc, "------ ostale komande --------------------" )
      AAdd( aOpcExe, {|| .F. } )
      AAdd( aOpc, "5. unos depozita u uređaj       " )
      AAdd( aOpcExe, {|| tring_polog( s_hFiskalniDeviceParams ) } )
      AAdd( aOpc, "6. štampanje duplikata       " )
      AAdd( aOpcExe, {|| tring_double( s_hFiskalniDeviceParams ) } )
      AAdd( aOpc, "7. zatvori (poništi) racun " )
      AAdd( aOpcExe, {|| tring_close_rn( s_hFiskalniDeviceParams ) } )

      IF !lObicniUser

         AAdd( aOpc, "8. inicijalizacija " )
         AAdd( aOpcExe, {|| tring_init( s_hFiskalniDeviceParams, "1", "" ) } )
         AAdd( aOpc, "S. reset zahtjeva na PU serveru " )
         AAdd( aOpcExe, {|| tring_reset( s_hFiskalniDeviceParams ) } )

         AAdd( aOpc, "R. reset PLU " )
         AAdd( aOpcExe, {|| auto_plu( .T., NIL, s_hFiskalniDeviceParams ) } )

      ENDIF

   OTHERWISE
      MsgBeep( "Fiskalni drajver:" + cFiskalniDrajver + " ne postoji?!" )
      QUIT_1

   ENDCASE

   _m_x := box_x_koord()
   _m_y := box_y_koord()


   f18_menu( "izvf", .F., nIzbor, aOpc, aOpcExe )

   box_x_koord( _m_x )
   box_y_koord( _m_y )

   RETURN .T.
