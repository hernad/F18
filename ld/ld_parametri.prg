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


STATIC s_cBeneficiraniTip

FUNCTION ld_parametri()

   LOCAL _opc := {}
   LOCAL _opcexe := {}
   LOCAL _izbor := 1

   o_ld_rj()
   o_params()

   PRIVATE cSection := "1"
   PRIVATE cHistory := " "
   PRIVATE aHistory := {}

   AAdd( _opc, "1. osnovni podaci organizacione jedinice                        " )
   AAdd( _opcexe, {|| parametri_organizacije() } )
   AAdd( _opc, "2. RJ, mjesec, godina...         " )
   AAdd( _opcexe, {|| ld_set_firma() } )
   AAdd( _opc, "3. postavke zaokruženja, valute, formata prikaza iznosa...  " )
   AAdd( _opcexe, {|| ld_set_forma() } )
   AAdd( _opc, "4. postavke načina obracuna " )
   AAdd( _opcexe, {|| ld_set_obracun() } )
   AAdd( _opc, "5. postavka formula (uk.prim.,uk.sati,godisnji) i koeficijenata " )
   AAdd( _opcexe, {|| ld_set_formule() } )
   AAdd( _opc, "6. postavka parametara izgleda dokumenata " )
   AAdd( _opcexe, {|| ld_set_prikaz() } )
   AAdd( _opc, "7. poseban odbitak za elementarne nepogode" )
   AAdd( _opcexe, {|| ld_elementarne_nepogode_parametri() } )

   f18_menu( "par", .F., _izbor, _opc, _opcexe )

   RETURN .T.



FUNCTION ld_get_params( hParams )

   ld_tekuca_godina( fetch_metric( "ld_godina", my_user(), 2017 ) )
   ld_tekuci_mjesec( fetch_metric( "ld_mjesec", my_user(), 1 ) )

   gLDRadnaJedinica := fetch_metric( "ld_rj", my_user(), gLDRadnaJedinica )

   gObracun := fetch_metric( "ld_obracun", my_user(), gObracun )

   // ---------
   gPicI := fetch_metric( "ld_pic_iznos", NIL, AllTrim( gPicI ) )
   gPicS := fetch_metric( "ld_pic_sati", NIL, AllTrim( gPicS ) )
   gValuta := fetch_metric( "ld_valuta", NIL, gValuta )
   gZaok2 := fetch_metric( "ld_zaok_por_dopr", NIL, gZaok2 )
   gZaok := fetch_metric( "ld_zaok_prim", NIL, gZaok )

   // ---------
   gFUPrim := fetch_metric( "ld_formula_ukupna_primanja", NIL, gFUPrim )
   gFUSati := fetch_metric( "ld_formula_ukupni_sati", NIL, gFUSati )
   gFUGod := fetch_metric( "ld_formula_godisnji", NIL, gFUGod )
   gFURaz := fetch_metric( "ld_formula_ukupna_primanja_razno", NIL, gFURaz )
   gFURSati := fetch_metric( "ld_formula_ukupni_sati_razno", NIL, gFURSati )
   gMRZ := fetch_metric( "ld_minuli_rad_koef_zene", NIL, gMRZ )
   gMRM := fetch_metric( "ld_minuli_rad_koef_muskarci", NIL, gMRM )
   gPDLimit := fetch_metric( "ld_donji_limit_poreza_doprinosa", NIL, gPDLimit )
   gBFForm := fetch_metric( "ld_formula_beneficirani_staz", NIL, gBFForm )

   IF hParams != NIL
      hParams[ "benef_tip" ] := param_ld_sati_beneficirani_staz_tip()
   ENDIF

   gOsnLOdb := fetch_metric( "ld_osnovni_licni_odbitak_iznos", NIL, gOsnLOdb )
   gUgTrosk := fetch_metric( "ld_trosak_ugovori", NIL, gUgTrosk )
   gAhTrosk := fetch_metric( "ld_trosak_honorari", NIL, gAhTrosk )

   // ---------
   gVarObracun := fetch_metric( "ld_varijanta_obracuna", NIL, gVarObracun )
   gSihtarica := fetch_metric( "ld_obrada_sihtarica", NIL, gSihtarica )
   gSihtGroup := fetch_metric( "ld_obrada_sihtarica_po_grupama", NIL, "N" )


   // ----------
   gSetForm := fetch_metric( "ld_set_formula", NIL, gSetForm )
   gMinR := fetch_metric( "ld_minuli_rad", NIL, gMinR )
   gDaPorOl := fetch_metric( "ld_poreske_olaksice", NIL, gDaPorOl )
   gTipObr := fetch_metric( "ld_tip_obracuna_legacy", NIL, gTipObr )
   //gUnMjesec := fetch_metric( "ld_unos_mjeseca_kod_obracuna", NIL, gUnMjesec )
   gcLdSpec2001GrupePoslovaAutoRucno := fetch_metric( "ld_grupe_poslova_specifikacija", NIL, "1" )
   gRadnFilter := fetch_metric( "ld_filter_radnici", NIL, gRadnFilter )

   // ----------
   gBodK := fetch_metric( "ld_opis_osnovnih_podataka", NIL, gBodK )
   gReKrKP := fetch_metric( "ld_varijanta_kartice_krediti", NIL, gReKrKP )
   gVarPP := fetch_metric( "ld_pregled_plata_varijanta", NIL, gVarPP )
   gPrBruto := fetch_metric( "ld_prikaz_bruto_iznosa_varijanta", NIL, gPrBruto )
   gPotp := fetch_metric( "ld_potpis_na_kartici_radnika", NIL, gPotp )
   gReKrOs := fetch_metric( "ld_krediti_osnova_varijanta", NIL, "X" )
   gPotpRpt := fetch_metric( "ld_potpis_na_izvjestajima", NIL, gPotpRpt )
   gPotp1 := fetch_metric( "ld_potpis_red_1", NIL, gPotp1 )
   gPotp2 := fetch_metric( "ld_potpis_red_2", NIL, gPotp2 )
   gKarSDop := fetch_metric( "ld_kartica_svi_doprinosi", NIL, gKarSDop )

   RETURN .T.


FUNCTION param_ld_sati_beneficirani_staz_tip( nSet )

   // hernad: ne razumijem !?
   IF s_cBeneficiraniTip == NIL
      s_cBeneficiraniTip := fetch_metric( "ld_sati_beneficirani_staz_tip", NIL, 1 )
   ENDIF

   IF nSet != NIL
      s_cBeneficiraniTip := nSet
      set_metric( "ld_sati_beneficirani_staz_tip", NIL, nSet )
   ENDIF

   RETURN s_cBeneficiraniTip


FUNCTION is_beneficirani_staz_redovan_rad()

   // hernad: ne razumijem !?

   RETURN param_ld_sati_beneficirani_staz_tip() == 1



FUNCTION ld_set_firma()

   LOCAL _godina := fetch_metric( "ld_godina", my_user(), ld_tekuca_godina() )
   LOCAL _rj := fetch_metric( "ld_rj", my_user(), gLDRadnaJedinica )
   LOCAL _mjesec := fetch_metric( "ld_mjesec", my_user(), ld_tekuci_mjesec() )

   // LOCAL _v_obr := fetch_metric( "ld_vise_obracuna", NIL, ld_vise_obracuna() )
   LOCAL _obracun := fetch_metric( "ld_obracun", my_user(), gObracun )

   PRIVATE GetList := {}

   Box(, 4, 60 )

   @ box_x_koord() + 1, box_y_koord() + 2 SAY "Radna jedinica :" GET _rj VALID P_LD_Rj( @_rj ) PICT "@!"
   @ box_x_koord() + 2, box_y_koord() + 2 SAY "Mjesec         :" GET _mjesec PICT "99"
   @ box_x_koord() + 3, box_y_koord() + 2 SAY "Godina         :" GET _godina PICT "9999"
   @ box_x_koord() + 4, box_y_koord() + 2 SAY "Obracun        :" GET _obracun WHEN ld_help_broj_obracuna( .F., _obracun ) VALID ld_valid_obracun( .F., _obracun )

   READ

   ClvBox()

   BoxC()

   IF ( LastKey() <> K_ESC )

      set_metric( "ld_godina", my_user(), _godina )
      ld_tekuca_godina( _godina )

      set_metric( "ld_mjesec", my_user(), _mjesec )
      ld_tekuci_mjesec( _mjesec )

      set_metric( "ld_rj", my_user(), _rj )
      gLDRadnaJedinica := _rj

      set_metric( "ld_obracun", my_user(), _obracun )
      gObracun := _obracun

   ENDIF

   RETURN .T.



FUNCTION ld_set_forma()

   PRIVATE GetList := {}

   gPicI := PadR( gPicI, 15 )
   gPicS := PadR( gPicS, 15 )

   Box(, 5, 60 )
   @ box_x_koord() + 1, box_y_koord() + 2 SAY "Zaokruzenje primanja          :" GET gZaok PICT "99"
   @ box_x_koord() + 2, box_y_koord() + 2 SAY "Zaokruzenje poreza i doprinosa:" GET gZaok2 PICT "99"
   @ box_x_koord() + 3, box_y_koord() + 2 SAY "Valuta                        :" GET gValuta PICT "XXX"
   @ box_x_koord() + 4, box_y_koord() + 2 SAY "Prikaz iznosa                 :" GET gPicI
   @ box_x_koord() + 5, box_y_koord() + 2 SAY "Prikaz sati                   :" GET gPicS
   READ
   BoxC()

   IF ( LastKey() <> K_ESC )
      set_metric( "ld_pic_iznos", NIL, AllTrim( gPicI ) )
      set_metric( "ld_pic_sati", NIL, AllTrim( gPicS ) )
      set_metric( "ld_valuta", NIL, gValuta )
      set_metric( "ld_zaok_por_dopr", NIL, gZaok2 )
      set_metric( "ld_zaok_prim", NIL, gZaok )
   ENDIF

   RETURN .T.



FUNCTION ld_set_formule()

   LOCAL hParams := hb_Hash()
   LOCAL GetList := {}

   ld_get_params( @hParams )

   Box(, 19, 77 )

   gFURaz := PadR( gFURaz, 100 )
   gFUPrim := PadR( gFUPrim, 100 )
   gFUSati := PadR( gFUSati, 100 )
   gFURSati := PadR( gFURSati, 100 )
   gBFForm := PadR( gBFForm, 100 )

   @ box_x_koord() + 1, box_y_koord() + 2 SAY "Formula za ukupna primanja:" GET gFUPrim  PICT "@!S30"
   @ box_x_koord() + 2, box_y_koord() + 2 SAY "Formula za ukupno sati    :" GET gFUSati  PICT "@!S30"
   @ box_x_koord() + 3, box_y_koord() + 2 SAY "Formula za godisnji       :" GET gFUGod PICT "@!S30"
   @ box_x_koord() + 5, box_y_koord() + 2 SAY "Formula za uk.prim.-razno :" GET gFURaz PICT "@!S30"
   @ box_x_koord() + 6, box_y_koord() + 2 SAY "Formula za uk.sati -razno :" GET gFURSati PICT "@!S30"
   @ box_x_koord() + 8, box_y_koord() + 2 SAY "God. promjena koef.min.rada - ZENE:" GET gMRZ   PICT "9999.99"
   @ box_x_koord() + 9, box_y_koord() + 2 SAY "God. promjena koef.min.rada - MUSK:" GET gMRM   PICT "9999.99"
   @ box_x_koord() + 11, box_y_koord() + 2 SAY "% prosjecne plate kao donji limit neta za obracun poreza i doprinosa" GET gPDLimit PICT "999.99"

   @ box_x_koord() + 13, box_y_koord() + 2 SAY "Osnovni licni odbitak" GET gOsnLOdb VALID gOsnLOdb > 0 PICT "9999.99"

   @ box_x_koord() + 15, box_y_koord() + 2 SAY "  Trosak - ugovor o djelu (%):" GET gUgTrosk PICT "999.99"

   @ box_x_koord() + 16, box_y_koord() + 2 SAY "Trosak - autorski honorar (%):" GET gAhTrosk PICT "999.99"

   @ box_x_koord() + 18, box_y_koord() + 2 SAY "Kod benef.gledaj formulu:" GET gBFForm PICT "@!S30"
   @ box_x_koord() + 19, box_y_koord() + 2 SAY "Sati benef. (1 - ukupni, 2 - po obracunu):" GET hParams[ "benef_tip" ] PICT "9"

   READ

   BoxC()

   IF ( LastKey() <> K_ESC )

      set_metric( "ld_formula_ukupna_primanja", NIL, gFUPrim )
      set_metric( "ld_formula_ukupni_sati", NIL, gFUSati )
      set_metric( "ld_formula_godisnji", NIL, gFUGod )
      set_metric( "ld_formula_ukupna_primanja_razno", NIL, gFURaz )
      set_metric( "ld_formula_ukupni_sati_razno", NIL, gFURSati )
      set_metric( "ld_minuli_rad_koef_zene", NIL, gMRZ )
      set_metric( "ld_minuli_rad_koef_muskarci", NIL, gMRM )
      set_metric( "ld_donji_limit_poreza_doprinosa", NIL, gPDLimit )
      set_metric( "ld_formula_beneficirani_staz", NIL, gBFForm )
      param_ld_sati_beneficirani_staz_tip( hParams[ "benef_tip" ] )
      set_metric( "ld_osnovni_licni_odbitak_iznos", NIL, gOsnLOdb )
      set_metric( "ld_trosak_ugovori", NIL, gUgTrosk )
      set_metric( "ld_trosak_honorari", NIL, gAhTrosk )

   ENDIF

   RETURN .T.


FUNCTION ld_set_obracun()

   LOCAL nX := 1
   LOCAL _radni_sati := fetch_metric( "ld_radni_sati", NIL, "N" )
   LOCAL _st_stopa := fetch_metric( "ld_porezi_stepenasta_stopa", NIL, "N" )
   LOCAL _v_obr_unos := fetch_metric( "ld_vise_obracuna_na_unosu", my_user(), "N" )
   PRIVATE GetList := {}

   cVarPorol := PadR( cVarPorol, 2 )

   Box(, 20, 77 )

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "  ' ' - (prazno) stara varijanta obracuna"
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "  '2' - nova varijanta obracuna, zak.pr.2009"

   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Odabir broja obracuna na unosu (D/N) ?" GET _v_obr_unos VALID _v_obr_unos $ "DN" PICT "@!"

   nX += 2
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Tip obracuna (legacy)" GET gTipObr
   //@ box_x_koord() + nX, Col() + 1 SAY "Mogucnost unosa mjeseca pri obradi D/N:" GET gUnMjesec  PICT "@!" VALID gUnMjesec $ "DN"

   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Koristiti set formula (sifrarnik Tipovi primanja):" GET gSetForm PICT "9"

   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Minuli rad  %/B:" GET gMinR  VALID gMinR $ "%B"   PICT "@!"

   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Pri obracunu napraviti poreske olaksice D/N:" GET gDaPorOl  VALID gDaPorOl $ "DN"   PICT "@!"

   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Ako se prave por.ol.pri obracunu, koja varijanta se koristi:"
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY " '1' - POROL = RADN->porol*PAROBR->prosld/100 "
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY " '2' - POROL = RADN->porol, '29' - LD->I29    ->" GET cVarPorOl WHEN gDaPorOl == "D"   PICT "99"

   nX += 2
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Grupe poslova u specif.uz platu (1-automatski/2-korisnik definiše):" GET gcLdSpec2001GrupePoslovaAutoRucno  VALID gcLdSpec2001GrupePoslovaAutoRucno $ "12" PICT "9"

   nX  += 2
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Obrada sihtarice ?" GET gSihtarica VALID gSihtarica $ "DN" PICT "@!"
   @ box_x_koord() + nX, Col() + 1 SAY "Sihtarice po grupama ?" GET gSihtGroup VALID gSihtGroup $ "DN" PICT "@!"

   nX += 2
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Filter 'aktivan' u sifaniku radnika ?" GET gRadnFilter VALID gRadnFilter $ "DN" PICT "@!"

   ++nX
   @ box_x_koord() + nX++, box_y_koord() + 2 SAY "Unos i obrada radnih sati (D/N)" GET _radni_sati VALID _radni_sati $ "DN" PICT "@!"

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Porezi - stepenaste stope ? (D/N)" GET _st_stopa VALID _st_stopa $ "DN" PICT "@!"

   READ

   BoxC()

   IF ( LastKey() <> K_ESC )

      IF gSihtGroup == "D"
         gSihtarica := "N"
      ENDIF

      set_metric( "ld_set_formula", NIL, gSetForm )
      set_metric( "ld_minuli_rad", NIL, gMinR )
      set_metric( "ld_poreske_olaksice", NIL, gDaPorOl )
      set_metric( "ld_tip_obracuna_legacy", NIL, gTipObr )
      //set_metric( "ld_unos_mjeseca_kod_obracuna", NIL, gUnMjesec )
      set_metric( "ld_varijanta_porezne_olaksice", NIL, cVarPorOl )
      set_metric( "ld_grupe_poslova_specifikacija", NIL, gcLdSpec2001GrupePoslovaAutoRucno )
      set_metric( "ld_filter_radnici", NIL, gRadnFilter )
      set_metric( "ld_varijanta_obracuna", NIL, gVarObracun )
      set_metric( "ld_obrada_sihtarica", NIL, gSihtarica )

      set_metric( "ld_obrada_sihtarica_po_grupama", NIL, gSihtGroup )

      set_metric( "ld_radni_sati", NIL, _radni_sati )
      set_metric( "ld_porezi_stepenasta_stopa", NIL, _st_stopa )
      set_metric( "ld_vise_obracuna_na_unosu", my_user(), _v_obr_unos )

   ENDIF

   RETURN .T.


FUNCTION ld_set_prikaz()

   LOCAL _pr_kart_pl := fetch_metric( "ld_obracun_prikaz_kartice_na_unosu", NIL, "N" )
   PRIVATE GetList := {}

   gPotp1 := PadR( gPotp1, 150 )
   gPotp2 := PadR( gPotp2, 150 )

   Box(, 15, 77 )
   @ box_x_koord() + 1, box_y_koord() + 2 SAY "Krediti-rekap.po 'na osnovu' (D/N/X)?" GET gReKrOs VALID gReKrOs $ "DNX" PICT "@!"
   @ box_x_koord() + 2, box_y_koord() + 2 SAY "Na kraju obrade odstampati listic D/N:" GET _pr_kart_pl  PICT "@!" VALID _pr_kart_pl $ "DN"
   @ box_x_koord() + 3, box_y_koord() + 2 SAY "Prikaz bruto iznosa na kartici radnika (D/N/X) " GET gPrBruto PICT "@!" VALID gPrBruto $ "DNX"
   @ box_x_koord() + 4, box_y_koord() + 2 SAY "Potpis na kartici radnika D/N:" GET gPotp  VALID gPotp $ "DN"   PICT "@!"
   @ box_x_koord() + 5, box_y_koord() + 2 SAY "Varijanta kartice plate za kredite (1/2) ?" GET gReKrKP VALID gReKrKP $ "12"
   @ box_x_koord() + 6, box_y_koord() + 2 SAY "Opis osnovnih podataka za obracun (1-bodovi/2-koeficijenti) ?" GET gBodK VALID gBodK $ "12"
   @ box_x_koord() + 7, box_y_koord() + 2 SAY "Pregled plata: varijanta izvjestaja (1/2)" GET gVarPP VALID gVarPP $ "12"
   @ box_x_koord() + 8, box_y_koord() + 2 SAY "Potpisi na svim izvjestajima (D/N)" GET gPotpRpt VALID gPotpRpt $ "DN" PICT "@!"
   READ

   IF gPotpRpt == "D"
      @ box_x_koord() + 10, box_y_koord() + 2 SAY "red 1:" GET gPotp1 PICT "@S25"
      @ box_x_koord() + 10, Col() + 1 SAY "red 2:" GET gPotp2 PICT "@S25"
      READ
   ENDIF

   @ box_x_koord() + 11, box_y_koord() + 2 SAY "Kartica plate - svi doprinosi (D/N)" GET gKarSDop VALID gKarSDop $ "DN" PICT "@!"

   READ

   BoxC()

   IF ( LastKey() <> K_ESC )

      // parametri sql/db
      set_metric( "ld_obracun_prikaz_kartice_na_unosu", NIL, _pr_kart_pl )
      set_metric( "ld_opis_osnovnih_podataka", NIL, gBodK )
      set_metric( "ld_varijanta_kartice_krediti", NIL, gReKrKP )
      set_metric( "ld_pregled_plata_varijanta", NIL, gVarPP )
      set_metric( "ld_prikaz_bruto_iznosa_varijanta", NIL, gPrBruto )
      set_metric( "ld_potpis_na_kartici_radnika", NIL, gPotp )
      set_metric( "ld_krediti_osnova_varijanta", NIL, gReKrOs )
      set_metric( "ld_potpis_na_izvjestajima", NIL, gPotpRpt )
      set_metric( "ld_potpis_red_1", NIL, gPotp1 )
      set_metric( "ld_potpis_red_2", NIL, gPotp2 )
      set_metric( "ld_kartica_svi_doprinosi", NIL, gKarSDop )

   ENDIF

   RETURN


FUNCTION LDPoljaINI()

   PUBLIC cLDPolja := 60

   RETURN .T.



FUNCTION ld_help_broj_obracuna( lIzv, cObracun )

   IF lIzv == nil
      lIzv := .F.
   ENDIF

   IF gNHelpObr = 0
      Box(, 3 + IF( lIzv, 1, 0 ), 40 )
      @ box_x_koord() + 0, box_y_koord() + 2 SAY8 PadC( " POMOĆ: ", 36, " " )
      IF lIzv
         @ box_x_koord() + 2, box_y_koord() + 2 SAY8 "Ukucajte broj obračuna (1/2/.../9)"
         @ box_x_koord() + 3, box_y_koord() + 2 SAY8 "ili prazno ako želite sve obracune"
      ELSE
         @ box_x_koord() + 2, box_y_koord() + 2 SAY8 "Ukucajte broj obračuna (1/2/.../9)"
      ENDIF
      ++gnHelpObr
   ENDIF

   RETURN .T.




FUNCTION ld_valid_obracun( lIzv, cObracun )

   LOCAL lVrati := .T.

   IF lIzv == nil
      lIzv := .F.
   ENDIF

   IF lIzv
      lVrati := ( cObracun $ " 123456789" )
   ELSE
      lVrati := ( cObracun $ "123456789" )
   ENDIF

   IF gnHelpObr > 0 .AND. lVrati
      BoxC()
      --gnHelpObr
   ENDIF

   RETURN lVrati


FUNCTION ClVBox()

   LOCAL i := 0

   FOR i := 1 TO gnHelpObr
      BoxC()
   NEXT
   gnHelpObr := 0

   RETURN .T.
