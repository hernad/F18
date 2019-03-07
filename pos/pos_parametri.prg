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

STATIC s_cKalkKontoMagacin := NIL

FUNCTION pos_parametri()

   LOCAL aOpc := {}
   LOCAL aOpcExe := {}
   LOCAL nIzbor := 1

   //AAdd( aOpc, "1. podaci kase                    " )
   //AAdd( aOpcExe, {|| pos_param_podaci_kase() } )

   AAdd( aOpc, "1. principi rada" )
   AAdd( aOpcExe, {|| pos_principi_rada_kase() } )
   AAdd( aOpc, "2. izgled racuna" )
   AAdd( aOpcExe, {|| pos_param_izgled_racuna() } )
   AAdd( aOpc, "3. cijene" )
   AAdd( aOpcExe, {|| pos_param_cijene() } )
   AAdd( aOpc, "4. podaci firme" )
   AAdd( aOpcExe, {|| pos_param_firma() } )
   AAdd( aOpc, "5. fiskalni parametri" )
   AAdd( aOpcExe, {|| fiskalni_parametri_za_korisnika() } )
   AAdd( aOpc, "6. podešenja organizacije" )
   AAdd( aOpcExe, {|| parametri_organizacije() } )
   AAdd( aOpc, "7. podešenja barkod-a" )
   AAdd( aOpcExe, {|| label_params() } )

   f18_menu( "par", .F., nIzbor, aOpc, aOpcExe )

   RETURN .F.


//FUNCTION pos_param_podaci_kase()
//
//   LOCAL aNiz := {}
//   LOCAL cPom := ""
//   LOCAL _user := my_user()
//
//   SET CURSOR ON
//
//   AAdd( aNiz, { "Oznaka/ID prodajnog mjesta", "gPosProdajnoMjesto",, "@!", } )
//
//   VarEdit( aNiz, 2, 2, 24, 78, "PARAMETRI RADA PROGRAMA - PODACI KASE", "B1" )
//
//   IF LastKey() <> K_ESC
//      set_metric( "PM", NIL, gPosProdajnoMjesto )
//   ENDIF
//
//   RETURN .T.



FUNCTION pos_param_firma()

   LOCAL aNiz := {}
   LOCAL cPom := ""

   gFirIdBroj := PadR( gFirIdBroj, 13 )

   SET CURSOR ON

   AAdd( aNiz, { "Puni naziv firme", "gFirNaziv", , , } )
   AAdd( aNiz, { "Adresa firme", "gFirAdres", , , } )
   AAdd( aNiz, { "Telefoni", "gFirTel", , , } )
   AAdd( aNiz, { "ID broj", "gFirIdBroj", , , } )
   AAdd( aNiz, { "Prodajno mjesto", "gFirPM", , , } )
   AAdd( aNiz, { "Mjesto nastanka racuna", "gRnMjesto", , , } )
   AAdd( aNiz, { "Pomocni tekst racuna - linija 1:", "gRnPTxt1", , , } )
   AAdd( aNiz, { "Pomocni tekst racuna - linija 2:", "gRnPTxt2", , , } )
   AAdd( aNiz, { "Pomocni tekst racuna - linija 3:", "gRnPTxt3", , , } )

   VarEdit( aNiz, 7, 2, 24, 78, "PODACI FIRME I RACUNA", "B1" )

   // Upisujem nove parametre
   IF LastKey() <> K_ESC

      set_metric( "pos_header_org_naziv", nil, gFirNaziv )
      set_metric( "pos_header_org_adresa", nil, gFirAdres )
      set_metric( "pos_header_org_id_broj", nil, gFirIdBroj )
      set_metric( "pos_header_pm", nil, gFirPM )
      set_metric( "pos_header_mjesto", nil, gRnMjesto )
      set_metric( "pos_header_telefon", nil, gFirTel )
      set_metric( "pos_header_txt_1", nil, gRnPTxt1 )
      set_metric( "pos_header_txt_2", nil, gRnPTxt2 )
      set_metric( "pos_header_txt_3", nil, gRnPTxt3 )

   ENDIF

   RETURN .T.




FUNCTION pos_param_principi_rada()

   PRIVATE opc := {}
   PRIVATE opcexe := {}
   PRIVATE Izbor := 1

   AAdd( opc, "1. osnovna podešenja              " )
   AAdd( opcexe, {|| pos_principi_rada_kase() } )


   f18_menu_sa_priv_vars_opc_opcexe_izbor( "prr" )

   RETURN .F.



FUNCTION pos_principi_rada_kase()

   LOCAL aNiz := {}
   LOCAL cPom := ""

   PRIVATE _konstantni_unos := fetch_metric( "pos_konstantni_unos_racuna", my_user(), "N" )
   //PRIVATE _kalk_konto := fetch_metric( "pos_stanje_sa_kalk_konta", NIL, Space( 7 ) )
   PRIVATE cKalkKontoMagacin := pos_kalk_konto_magacin()
   PRIVATE _max_qtty := fetch_metric( "pos_maksimalna_kolicina_na_unosu", NIL, 0 )

   SET CURSOR ON

   aNiz := {}

   //AAdd ( aNiz, { "Dopustiti dupli unos artikala na računu (D/N)", "gDupliArt", "gDupliArt$'DN'", "@!", } )
   AAdd ( aNiz, { "Ako se dopusta dupli unos, da li se radnik upozorava(D/N)", "gDupliUpoz", "gDupliUpoz$'DN'", "@!", } )
   AAdd ( aNiz, { "Da li se prati stanje artikla na unosu (D/N/!)", "gPosPratiStanjePriProdaji", "gPosPratiStanjePriProdaji$'DN!'", "@!", } )

   IF pos_admin()
      AAdd ( aNiz, { "Upravnik može ispravljati cijene", "gSifUpravn", "gSifUpravn$'DN'", "@!", } )
   ENDIF

   AAdd ( aNiz, { "Kod unosa računa uvijek pretraga art.po nazivu (D/N)? ", "gPosPretragaRobaUvijekPoNazivu", "gPosPretragaRobaUvijekPoNazivu$'DN'", "@!", } )
   AAdd ( aNiz, { "Maksimalna količina pri unosu racuna (0 - bez provjere) ", "_max_qtty", "_max_qtty >= 0", "999999", } )
   AAdd ( aNiz, { "Unos računa bez izlaska iz pripreme (D/N) ", "_konstantni_unos", "_konstantni_unos$'DN'", "@!", } )
   AAdd ( aNiz, { "Za stanje artikla gledati KALK magacinski konto", "cKalkKontoMagacin",, "@S7", } )

   VarEdit( aNiz, 2, 2, f18_max_rows() - 10, f18_max_cols() - 5, "POS PARAMETRI RADA - PRINCIPI RADA", "B1" )

   IF LastKey() <> K_ESC

      MsgO( "Ažuriranje parametara" )
      set_metric( "RacunSpecifOpcije", nil, gRnSpecOpc )
      set_metric( "DupliUnosUpozorenje", nil, gDupliUpoz )
      set_metric( "PratiStanjeRobe", nil, gPosPratiStanjePriProdaji )
      set_metric( "StampanjePazara", nil, gStamPazSmj )
      set_metric( "StampanjePunktova", nil, gStamStaPun )
      set_metric( "UpravnikIspravljaCijene", nil, gSifUpravn )
      set_metric( "PretragaArtiklaPoNazivu", nil, gPosPretragaRobaUvijekPoNazivu )

      pos_kalk_konto_magacin( cKalkKontoMagacin )

      set_metric( "pos_maksimalna_kolicina_na_unosu", my_user(), _max_qtty )
      pos_max_kolicina_kod_unosa( .T. )

      set_metric( "pos_konstantni_unos_racuna", my_user(), _konstantni_unos )
      MsgC()

   ENDIF

   RETURN .T.


   FUNCTION pos_kalk_konto_magacin( cSet )

      IF s_cKalkKontoMagacin == NIL
         s_cKalkKontoMagacin := fetch_metric( "pos_stanje_sa_kalk_konta", my_user(), Space( 7 ) )
      ENDIF

      IF cSet != NIL
         s_cKalkKontoMagacin := cSet
         set_metric( "pos_stanje_sa_kalk_konta", my_user(), cSet )
      ENDIF

      RETURN s_cKalkKontoMagacin


FUNCTION pos_param_izgled_racuna()

   LOCAL aNiz := {}
   LOCAL cPom := ""

   gSjecistr := PadR( GETPStr( gSjeciStr ), 20 )
   gOtvorstr := PadR( GETPStr( gOtvorStr ), 20 )

   SET CURSOR ON

   gSjeciStr := PadR( gSjeciStr, 30 )
   gOtvorStr := PadR( gOtvorStr, 30 )
   gZagIz := PadR( gZagIz, 20 )

   AAdd( aNiz, { "Broj redova potrebnih da se racun otcijepi", "nFeedLines", "nFeedLines>=0", "99", } )
   AAdd( aNiz, { "Sekvenca za cijepanje trake", "gSjeciStr", , "@S20", } )
   AAdd( aNiz, { "Sekvenca za otvaranje kase ", "gOtvorStr", , "@S20", } )
  // AAdd( aNiz, { "Racun, prikaz cijene bez PDV (1) ili sa PDV (2) ?", "grbCjen", , "9", } )
   AAdd( aNiz, { "Racun, prikaz id artikla na racunu (D/N)", "grbStId", "grbStId$'DN'", "@!", } )

   VarEdit( aNiz, 9, 1, 19, 78, "PARAMETRI RADA PROGRAMA - IZGLED RAČUNA", "B1" )

   IF LastKey() <> K_ESC
      MsgO( "Ažuriranje parametara" )
      set_metric( "BrojLinijaZaKrajRacuna", nil, nFeedLines )
      set_metric( "SekvencaSjeciTraku", nil, gSjeciStr )
      set_metric( "SekvencaOtvoriLadicu", nil, gOtvorStr )
  //    set_metric( "RacunCijenaSaPDV", nil, grbCjen )
      set_metric( "RacunStampaIDArtikla", nil, grbStId )
      set_metric( "RacunHeader", nil, gRnHeder )
      set_metric( "IzgledZaglavlja", nil, gZagIz )
      set_metric( "RacunFooter", nil, gRnFuter )
      MsgC()
   ENDIF

   gSjeciStr := Odsj( gSjeciStr )
   gOtvorStr := Odsj( gOtvorStr )
   gZagIz := Trim( gZagIz )

   RETURN .T.


FUNCTION pos_param_cijene()

   LOCAL aNiz := {}

   SET CURSOR ON

   AAdd ( aNiz, { "Generalni popust % (99-gledaj sifranik)", "gPopust", , "99", } )
   AAdd ( aNiz, { "Zakružiti cijenu na (broj decimala)    ", "gPopDec", ,  "9", } )
   //AAdd ( aNiz, { "Popust zadavanjem nove cijene          ", "gPopZCj", "gPopZCj$'DN'", , } )
   AAdd ( aNiz, { "Popust zadavanjem procenta             ", "gPopProc", "gPopProc$'DN'", , } )
   AAdd ( aNiz, { "Popust preko određenog iznosa (iznos):", "gPopIzn",, "999999.99", } )
   AAdd ( aNiz, { "                  procenat popusta (%):", "gPopIznP",, "999.99", } )
   VarEdit( aNiz, 9, 2, 20, 78, "PARAMETRI RADA PROGRAMA - CIJENE", "B1" )

   o_params()

   IF LastKey() <> K_ESC
      set_metric( "Popust", nil, gPopust )
      //set_metric( "PopustZadavanjemCijene", nil, gPopZCj )
      set_metric( "PopustDecimale", nil, gPopDec )
      set_metric( "PopustProcenat", nil, gPopProc )
      set_metric( "PopustIznos", nil, gPopIzn )
      set_metric( "PopustVrijednostProcenta", nil, gPopIznP )
   ENDIF

   RETURN .T.
