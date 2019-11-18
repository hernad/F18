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

// picture iznos
STATIC gPIC_VAL
// picture dimenzije
STATIC gPIC_DIM
// picture kolicina
STATIC gPIC_QTTY


// -----------------------------------------
// set parametara pri pokretanju modula
// -----------------------------------------
FUNCTION rnal_set_params()

   read_fi_params()
   read_zf_params()
   read_doc_params()
   read_ex_params()
   read_ost_params()
   read_elat_params()

   RETURN


// --------------------------------------
// parametri zaokruzenja
// --------------------------------------
FUNCTION ed_zf_params()

   LOCAL cDimPict := "99999.99"

   gPIC_VAL := PadR( gPIC_VAL, 20 )
   gPIC_DIM := PadR( gPIC_DIM, 20 )
   gPIC_QTTY := PadR( gPIC_QTTY, 20 )

   nX := 1
   Box(, 15, 70 )

   set_cursor_on()

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "1. Prikazi ***"
   nX ++

   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( " kolicina ", 30 )   GET gPIC_QTTY
   nX ++

   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( " dimenzija ", 30 )   GET gPIC_DIM
   nX ++

   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( " iznos ", 30 )   GET gPIC_VAL


   READ

   BoxC()

   gPIC_QTTY := AllTrim( gPIC_QTTY )
   gPIC_DIM := AllTrim( gPIC_DIM )
   gPIC_VAL := AllTrim( gPIC_VAL )

   IF LastKey() <> K_ESC
      write_zf_params()
   ENDIF

   RETURN


// --------------------------------------
// parametri firme
// --------------------------------------
FUNCTION ed_fi_params()

   LOCAL nLeft := 35

   nX := 1
   Box(, 20, 70 )

   set_cursor_on()

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "1. Opci podaci ***"

   nX += 2

   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "Puni naziv firme:", nLeft ) GET gFNaziv PICT "@S30"
   nX ++

   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "Adresa firme:", nLeft ) GET gFAdresa PICT "@S30"
   nX ++

   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "Id broj:", nLeft ) GET gFIdBroj

   nX += 2

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "2. Dodatni podaci ***"

   nX += 2

   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "Telefoni:", nLeft ) GET gFTelefon PICT "@S30"
   nX ++

   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "email/web:", nLeft ) GET gFEmail PICT "@S30"

   nX += 2

   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "Banka 1:", nLeft ) GET gFBanka1 PICT "@S30"
   nX ++

   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "Banka 2:", nLeft ) GET gFBanka2 PICT "@S30"
   nX ++

   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "Banka 3:", nLeft ) GET gFBanka3 PICT "@S30"
   nX ++

   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "Banka 4:", nLeft ) GET gFBanka4 PICT "@S30"
   nX ++

   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "Banka 5:", nLeft ) GET gFBanka5 PICT "@S30"

   nX += 2

   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "Dodatni red 1:", nLeft ) GET gFPrRed1 PICT "@S30"
   nX ++

   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "Dodatni red 2:", nLeft ) GET gFPrRed2 PICT "@S30"


   READ

   BoxC()

   IF LastKey() <> K_ESC
      write_fi_params()
   ENDIF

   RETURN



FUNCTION ed_ex_params()

   LOCAL nX := 1
   LOCAL nLeft := 40
   LOCAL nLab_broj_komada := fetch_metric( "rnal_label_br_kom_razdvoji", NIL, 200 )

   Box(, 20, 70 )

   set_cursor_on()

   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "****** export GPS.opt Lisec parametri", nLeft )

   nX += 2

   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "Izlazni direktorij:", 20 ) GET gExpOutDir PICT "@S45"

   nX += 1

   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "Uvijek overwrite export fajla (D/N)?", 45 ) GET gExpAlwOvWrite PICT "@!" VALID gExpAlwOvWrite $ "DN"

   nX += 1

   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 PadL( "Dodaj (mm) na brušeno staklo:", 45 ) GET gBrusenoStakloDodaj PICT "9999.99"

   nX += 2

   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "****** export naljepnice", nLeft )

   nX += 1

   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "Razdvajanje naljepnica na broj komada:", 45 ) GET nLab_broj_komada PICT "9999"

   READ

   BoxC()

   IF LastKey() <> K_ESC
      set_metric( "rnal_label_br_kom_razdvoji", NIL, nLab_broj_komada )
      write_ex_params()
   ENDIF

   RETURN



FUNCTION ed_doc_params()

   nX := 2
   Box(, 10, 70 )

   set_cursor_on()

   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "Dodati redovi po listu:", 35 ) GET gDd_redovi PICT "99"
   nX ++

   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "Lijeva margina:", 35 ) GET gDl_margina PICT "99"
   nX ++

   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "Gornja margina:", 35 ) GET gDg_margina PICT "99"

   nX ++

   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "Varijanta stampe ODT (D/N):", 35 ) GET gRnalOdt PICT "@!" VALID gRnalOdt $ "DN"

   READ

   BoxC()

   IF LastKey() <> K_ESC
      write_doc_params()
   ENDIF

   RETURN



// --------------------------------------
// parametri elementi atributi
// --------------------------------------
FUNCTION ed_elat_params()

   nX := 1

   Box(, 18, 70 )

   set_cursor_on()

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "***** Parametri atributa i elemenata"

   nX += 2

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "oznaka (staklo)         :" GET gGlassJoker VALID !Empty( gGlassJoker )

   nX ++

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "oznaka (distancer)      :" GET gFrameJoker VALID !Empty( gFrameJoker )

   nX ++

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "oznaka (debljina stakla):" GET gDefGlTick VALID !Empty( gDefGlTick )

   nX ++

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "oznaka (tip stakla)     :" GET gDefGlType VALID !Empty( gDefGlType )

   nX += 2

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "***** Specificni parametri operacija"

   nX += 2

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "oznaka (brusenje)     :" GET gAopBrusenje VALID !Empty( gAopBrusenje )

   nX ++

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "oznaka (kaljenje)     :" GET gAopKaljenje VALID !Empty( gAopKaljenje )

   nX += 2

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "***** Specificni parametri za pojedinu vrstu stakla"

   nX += 2

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "oznaka stakla / LAMI:" GET gGlLamiJoker VALID !Empty( gGlLamiJoker )

   READ

   BoxC()

   IF LastKey() <> K_ESC
      write_elat_params()
   ENDIF

   RETURN




// --------------------------------------
// parametri ostali
// --------------------------------------
FUNCTION ed_ost_params()

   LOCAL nLeft := 50
   LOCAL nX := 1

   Box(, 20, 70 )

   set_cursor_on()

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "1. Pretraga artikla *******"

   nX += 2

   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "Resetuj vrijednosti u tabeli pretrage (0/1)", nLeft ) GET gFnd_reset PICT "9"

   nX += 1

   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "Timeout kod azuriranja dokumenata", nLeft ) GET gInsTimeOut PICT "99999"


   nX += 2

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "2. Limiti unosa *******"

   nX += 2

   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "maksimalna sirina (mm)", nLeft - 10 ) GET gMaxWidth PICT "99999.99"

   nX += 1

   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "maksimalna visina (mm)", nLeft - 10 ) GET gMaxHeigh PICT "99999.99"

   nX += 2

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "3. Default vrijednosti ********"

   nX += 2

   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "Nadmorska visina (nv.m)", nLeft - 10 ) GET gDefNVM PICT "99999.99"

   nX += 1

   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "3mm zaokruzenja ?", nLeft - 20 ) GET g3mmZaokUse ;
      PICT "@!" VALID g3mmZaokUse $ "DN"

   @ box_x_koord() + nX, Col() + 1 SAY "PROFILIT zaokruzenja ?" GET gProfZaokUse ;
      PICT "@!" VALID gProfZaokUse $ "DN"


   nX += 1

   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "Koristiti GN zaokruzenja ?", nLeft - 20 ) GET gGnUse ;
      PICT "@!" VALID gGnUse $ "DN"
   nX += 1

   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "GN zaok. (min)", nLeft - 20 ) GET gGnMin ;
      PICT "99999"
   @ box_x_koord() + nX, Col() + 1 SAY "(max)" GET gGnMax PICT "99999"
   @ box_x_koord() + nX, Col() + 1 SAY "korak" GET gGnStep PICT "9999"

   READ

   BoxC()

   IF LastKey() <> K_ESC
      write_ost_params()
   ENDIF

   RETURN



// --------------------------------------
// citaj paramtre firme
// --------------------------------------
FUNCTION read_fi_params()

   gFNaziv := fetch_metric( "org_naziv", nil, gFNaziv )
   gFAdresa := fetch_metric( "org_adresa", nil, gFAdresa )
   gFIdBroj := fetch_metric( "org_pdv_broj", nil, gFIdBroj )

   gFBanka1 := fetch_metric( "fakt_zagl_banka_1", nil, gFBanka1 )
   gFBanka2 := fetch_metric( "fakt_zagl_banka_2", nil, gFBanka2 )
   gFBanka3 := fetch_metric( "fakt_zagl_banka_3", nil, gFBanka3 )
   gFBanka4 := fetch_metric( "fakt_zagl_banka_4", nil, gFBanka4 )
   gFBanka5 := fetch_metric( "fakt_zagl_banka_5", nil, gFBanka5 )

   gFTelefon := fetch_metric( "fakt_zagl_telefon", nil, gFTelefon )
   gFEmail := fetch_metric( "fakt_zagl_email", nil, gFEmail )

   gFPrRed1 := fetch_metric( "fakt_zagl_dtxt_1", nil, gFPrRed1 )
   gFPrRed2 := fetch_metric( "fakt_zagl_dtxt_2", nil, gFPrRed2 )

   RETURN


// --------------------------------
// upisi parametre firme
// --------------------------------
FUNCTION write_fi_params()

   set_metric( "org_naziv", nil, gFNaziv )
   set_metric( "org_adresa", nil, gFAdresa )
   set_metric( "org_pdv_broj", nil, gFIdBroj )

   set_metric( "fakt_zagl_banka_1", nil, gFBanka1 )
   set_metric( "fakt_zagl_banka_2", nil, gFBanka2 )
   set_metric( "fakt_zagl_banka_3", nil, gFBanka3 )
   set_metric( "fakt_zagl_banka_4", nil, gFBanka4 )
   set_metric( "fakt_zagl_banka_5", nil, gFBanka5 )

   set_metric( "fakt_zagl_telefon", nil, gFTelefon )
   set_metric( "fakt_zagl_email", nil, gFEmail )

   set_metric( "fakt_zagl_dtxt_1", nil, gFPrRed1 )
   set_metric( "fakt_zagl_dtxt_2", nil, gFPrRed2 )

   RETURN


// --------------------------------------
// citaj paramtre izgleda dokumenta
// --------------------------------------
FUNCTION read_doc_params()

   gDg_margina := fetch_metric( "rnal_stampa_desna_margina", nil, gDg_margina )
   gDl_margina := fetch_metric( "rnal_stampa_lijeva_margina", nil, gDl_margina )
   gDd_redovi := fetch_metric( "rnal_stampa_dodatni_redovi", nil, gDd_redovi )
   gRnalOdt := fetch_metric( "rnal_stampa_odt", NIL, gRnalOdt )

   RETURN


// ----------------------------------
// upisi parametre izgleda dokumenta
// ----------------------------------
FUNCTION write_doc_params()

   set_metric( "rnal_stampa_desna_margina", nil, gDg_margina )
   set_metric( "rnal_stampa_lijeva_margina", nil, gDl_margina )
   set_metric( "rnal_stampa_dodatni_redovi", nil, gDd_redovi )
   set_metric( "rnal_stampa_odt", NIL, gRnalOdt )

   RETURN




// --------------------------------------
// citaj paramtre elemenata i atributa
// --------------------------------------
FUNCTION read_elat_params()

   gDefGlType := PadR( "<GL_TYPE>", 30 )
   gDefGlTick := PadR( "<GL_TICK>", 30 )

   gGlassJoker := PadR( "G", 20 )
   gFrameJoker := PadR( "F", 20 )

   gGlLamiJoker := PadR( "LA", 20 )

   gAopKaljenje := PadR( "<A_KA>", 20 )
   gAopBrusenje := PadR( "<A_BR>", 20 )

   gGlassJoker := fetch_metric( "rnal_staklo_joker", nil, gGlassJoker )
   gFrameJoker := fetch_metric( "rnal_dist_joker", nil, gFrameJoker )
   gGlLamiJoker := fetch_metric( "rnal_lami_staklo_joker", nil, gGlLamiJoker )

   gAopKaljenje := fetch_metric( "rnal_aop_kaljenje", nil, gAopKaljenje )
   gAopBrusenje := fetch_metric( "rnal_aop_brusenje", nil, gAopBrusenje )

   gDefGlType := fetch_metric( "rnal_def_gl_type", nil, gDefGlType )
   gDefGlTick := fetch_metric( "rnal_def_gl_tick", nil, gDefGlTick )

   RETURN



// ---------------------------------------
// upisi parametre elemenata i atributa
// ---------------------------------------
FUNCTION write_elat_params()

   set_metric( "rnal_staklo_joker", nil, gGlassJoker )
   set_metric( "rnal_dist_joker", nil, gFrameJoker )
   set_metric( "rnal_lami_staklo_joker", nil, gGlLamiJoker )

   set_metric( "rnal_aop_kaljenje", nil, gAopKaljenje )
   set_metric( "rnal_aop_brusenje", nil, gAopBrusenje )

   set_metric( "rnal_def_gl_type", nil, gDefGlType )
   set_metric( "rnal_def_gl_tick", nil, gDefGlTick )

   RETURN




// --------------------------------------
// citaj paramtre izgleda dokumenta
// --------------------------------------
FUNCTION read_ex_params()

   gExpOutDir := fetch_metric( "rnal_export_lokacija", my_user(), gExpOutDir )
   gExpAlwOvWrite := fetch_metric( "rnal_export_overwrite_file", my_user(), gExpAlwOvWrite )
   gBrusenoStakloDodaj := fetch_metric( "rnal_dodatak_na_dimenzije", nil, gBrusenoStakloDodaj )

   RETURN



// ----------------------------------
// upisi parametre exporta
// ----------------------------------
FUNCTION write_ex_params()

   set_metric( "rnal_export_lokacija", my_user(), gExpOutDir )
   set_metric( "rnal_export_overwrite_file", my_user(), gExpAlwOvWrite )
   set_metric( "rnal_dodatak_na_dimenzije", nil, gBrusenoStakloDodaj )

   RETURN



// --------------------------------------
// citaj parametre ostale
// --------------------------------------
FUNCTION read_ost_params()

   gFnd_reset := fetch_metric( "rnal_reset_kod_pretrage", my_user(), gFnd_reset )

   gMaxWidth := fetch_metric( "rnal_maksimalna_sirina_stakla", nil, gMaxWidth )
   gMaxHeigh := fetch_metric( "rnal_maksimalna_visina_stakla", nil, gMaxHeigh )

   gDefNVM := fetch_metric( "rnal_default_nadmorska_visina", nil, gDefNVM )

   gInsTimeOut := fetch_metric( "rnal_ins_timeout", nil, gInsTimeOut )

   gProfZaokUse := fetch_metric( "rnal_profilit_zaokruzenje", nil, gProfZaokUse )
   g3mmZaokUse := fetch_metric( "rnal_3mm_zaokruzenje", nil, g3mmZaokUse )

   gGnUse := fetch_metric( "rnal_gn_tabela", nil, gGnUse )
   gGnMin := fetch_metric( "rnal_gn_min", nil, gGnMin )
   gGnMax := fetch_metric( "rnal_gn_max", nil, gGnMax )
   gGnStep := fetch_metric( "rnal_gn_step", nil, gGnStep )

   RETURN


// ----------------------------------
// upisi parametre ostalo
// ----------------------------------
FUNCTION write_ost_params()

   set_metric( "rnal_reset_kod_pretrage", my_user(), gFnd_reset )
   set_metric( "rnal_maksimalna_sirina_stakla", nil, gMaxWidth )
   set_metric( "rnal_maksimalna_visina_stakla", nil, gMaxHeigh )
   set_metric( "rnal_default_nadmorska_visina", nil, gDefNVM )
   set_metric( "rnal_ins_timeout", nil, gInsTimeOut )
   set_metric( "rnal_3mm_zaokruzenje", nil, g3mmZaokUse )
   set_metric( "rnal_profilit_zaokruzenje", nil, gProfZaokUse )
   set_metric( "rnal_gn_tabela", nil, gGnUse )
   set_metric( "rnal_gn_min", nil, gGnMin )
   set_metric( "rnal_gn_max", nil, gGnMax )
   set_metric( "rnal_gn_step", nil, gGnStep )

   RETURN


// --------------------------------------
// citaj podatke zaokruzenja...
// --------------------------------------
FUNCTION read_zf_params()

   gPIC_VAL := "9999.99"
   gPIC_DIM := "9999.99"
   gPIC_QTTY := "99999"

   gPic_val := fetch_metric( "rnal_pict_val", nil, gPIC_VAL )
   gPic_dim := fetch_metric( "rnal_pict_dim", nil, gPIC_DIM )
   gPic_qtty := fetch_metric( "rnal_pict_qtty", nil, gPIC_QTTY )

   RETURN


// ------------------------------------
// upisi paramtre zaokruzenja
// ------------------------------------
FUNCTION write_zf_params()

   set_metric( "rnal_pict_val", nil, gPIC_VAL )
   set_metric( "rnal_pict_dim", nil, gPIC_DIM )
   set_metric( "rnal_pict_qtty", nil, gPIC_QTTY )

   RETURN



// maximalna dimenzija
FUNCTION max_heigh()
   RETURN gMaxHeigh

// maximalna dimenzija
FUNCTION max_width()
   RETURN gMaxWidth



// -------------------------------
// -------------------------------
FUNCTION PIC_VAL( xVal )

   IF xVal <> nil
      gPIC_VAL := xVal
   ENDIF

   RETURN gPIC_VAL

// -------------------------------
// -------------------------------
FUNCTION PIC_DIM( xVal )

   IF xVal <> nil
      gPIC_DIM := xVal
   ENDIF

   RETURN gPIC_DIM


// -------------------------------
// -------------------------------
FUNCTION PIC_QTTY( xVal )

   IF xVal <> nil
      gPIC_QTTY := xVal
   ENDIF

   RETURN gPIC_QTTY
