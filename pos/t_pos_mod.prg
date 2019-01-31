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

CLASS TPosMod FROM TAppMod

   METHOD NEW
   METHOD set_module_gvars
   METHOD setScreen
   METHOD mMenu

ENDCLASS


METHOD New( p1, p2, p3, p4, p5, p6, p7, p8, p9 )

   ::super:new( p1, p2, p3, p4, p5, p6, p7, p8, p9 )

   RETURN self


METHOD mMenu()

   LOCAL Fx
   LOCAL Fy

   gPrevPos := gIdPos

   Fx := 4
   Fy := 8

   pos_init()
   CLOSE ALL

/*
   DO WHILE ( .T. )

      box_x_koord( Fx )
      box_y_koord( Fy )
      g_cUserLevel := pos_prijava( Fx, Fy )

      IF g_cUserLevel == "X"
         RETURN .F.
      ENDIF

      SetPos ( Fx, Fy )
      //IF gVsmjene == "N"
      gSmjena := "1"
      pos_odredi_smjenu( .F. )
      //ELSE
      //   pos_odredi_smjenu( .T. )
      //ENDIF
      EXIT

   ENDDO
*/

   //SetPos( Fx, Fy )
   //fPrviPut := .T.

   DO WHILE ( .T. )

      box_x_koord( Fx )
      box_y_koord( Fy )
      g_cUserLevel := pos_prijava( Fx, Fy )

      IF g_cUserLevel == "X"
         RETURN .F.
      ENDIF

      // unesi prijavu korisnika
    //  IF fPRviPut //.AND. gVSmjene == "N"
      //   fPrviPut := .F.
      //ELSE
      //   g_cUserLevel := pos_prijava( Fx, Fy )
      //   pos_status_traka()
      //ENDIF

      pos_status_traka()
      SetPos( Fx, Fy )
      pos_main_menu_level( Fx, Fy )

      IF self:lTerminate
         EXIT
      ENDIF

   ENDDO

   CLOSE ALL

   RETURN .T.


FUNCTION pos_main_menu_level( Fx, Fy )

   DO CASE

   CASE pos_admin()
      pos_main_menu_admin()
   CASE pos_upravnik()
      SetPos( Fx, Fy )
      pos_main_menu_upravnik()
   CASE pos_prodavac()
      SetPos( Fx, Fy )
      pos_main_menu_prodavac()

   ENDCASE

   RETURN .T.


METHOD setScreen()

   pripremi_naslovni_ekran( self )
   crtaj_naslovni_ekran()

   RETURN .T.


METHOD set_module_gvars()

   // gPrevIdPos - predhodna vrijednost gIdPos
   PUBLIC gPrevIdPos := "  "
   PUBLIC gOcitBarcod := .F.
   PUBLIC gSmijemRaditi := 'D'
   PUBLIC gSamoProdaja := 'N'
   PUBLIC gZauzetSam := 'N'
   // sifra radnika
   PUBLIC gIdRadnik
   // prezime i ime korisnika (iz OSOB)
   PUBLIC gKorIme

   // status radnika
   PUBLIC gSTRAD

   // identifikator seta cijena koji se
   PUBLIC gSetMPCijena := "1"
   PUBLIC gIdCijena := "1"
   PUBLIC gPopust := 0
   PUBLIC gPopDec := 2
   PUBLIC gPopZcj := "N"
   // PUBLIC gPopVar := "P"
   PUBLIC gPopProc := "N"
   PUBLIC gPopIzn := 0
   PUBLIC gPopIznP := 0
   PUBLIC SC_Opisi[ 5 ]      // nazivi (opisi) setova cijena
   PUBLIC gSmjena := " "   // identifikator smjene
   PUBLIC gDatum           // datum

   //PUBLIC gVodiOdj
   PUBLIC gRadniRac        // da li se koristi princip radnih racuna ili se
   // racuni furaju kao u trgovini
   PUBLIC gDupliArt        // da li dopusta unos duplih artikala na racunu
   PUBLIC gDupliUpoz       // ako se dopusta, da li se radnik upozorava na duple

   PUBLIC gDirZaklj        // ako se ne koristi princip radnih racuna, da li se
   // racuni zakljucuju odmah po unosu stavki

  // PUBLIC gPoreziRaster    // da li se porezi stampaju pojedinacno ili zbirno
   PUBLIC gPocStaSmjene    // da li se uvodi pocetno stanje smjene
   // (da li se radnicima dodjeljuju pocetna sredstva)
   PUBLIC gIdPos           // id prodajnog mjesta

   // PUBLIC gIdDio           // id dijela objekta u kome je kasa locirana
   // (ima smisla samo za HOPS)

   PUBLIC nFeedLines       // broj linija potrebnih da se racun otcijepi
   PUBLIC CRinitDone       // da li je uradjen init kase (na pocetku smjene)

   PUBLIC gDomValuta
   PUBLIC gGotPlac         // sifra za gotovinsko (default) placanje
   PUBLIC gDugPlac

   // ( K-kasa S-server A-samostalna kasa)
   PUBLIC gEvidPl          // evidentiranje podataka za vrste placanja CEK, SIND.KRED. i GARANTNO PISMO

   PUBLIC gDisplay  // koristiti ispis na COM DISPLAY

   PUBLIC gLocPort := "LPT1" // lokalni port za stampanje racuna

   PUBLIC gStamPazSmj      // da li se automatski stampa pazar smjene
   // na kasi
   PUBLIC gStamStaPun      // da li se automatski stampa stanje
   // nedijeljenih punktova koje kasa pokriva

   PUBLIC gRnSpecOpc  // HOPS - rn specificne opcije
   PUBLIC gSjeciStr := ""
   PUBLIC gOtvorStr := ""
   //PUBLIC gVSmjene := "N"
   PUBLIC gSezonaTip := "M"
   PUBLIC gSifUpravn := "D"
   PUBLIC gEntBarCod := "D"
   PUBLIC gSifUvPoNaz := "N" // sifra uvijek po nazivu

   PUBLIC gPosNaz
   PUBLIC gRnHeder := "RacHeder.TXT"
   PUBLIC gRnFuter := "RacPodn.TXT "
   PUBLIC gZagIz := "1;2;"
   PUBLIC gColleg := "N"
   PUBLIC gDuplo := "N"
   PUBLIC gDuploKum := ""
   PUBLIC gDuploSif := ""
   PUBLIC gFmkSif := ""
   PUBLIC gRNALSif := ""
   PUBLIC gRNALKum := ""

   PUBLIC gDuzSifre := 13

   // postavljanje globalnih varijabli
   PUBLIC gLocPort := "LPT1"
   PUBLIC gIdCijena := "1"
   PUBLIC gDiskFree := "N"
   PUBLIC grbCjen := 2
   PUBLIC grbStId := "D"
   PUBLIC grbReduk := 0
   // PUBLIC gRnInfo := "N"
   PUBLIC aRabat

   self:cName := "POS"
   gModul := self:cName

   gKorIme := ""
   gIdRadnik := ""
   gStRad := ""

   SC_Opisi[ 1 ] := "1"
   SC_Opisi[ 2 ] := "2"
   SC_Opisi[ 3 ] := "3"
   SC_Opisi[ 4 ] := "4"
   SC_Opisi[ 5 ] := "5"

   gDatum := Date()

   // PUBLIC gPopVar := "P"
   PUBLIC gPopZcj := "N"
   PUBLIC gZadCij := "N"
   PUBLIC gPopProc := "N"
   PUBLIC gIsPopust := .F.
   PUBLIC gKolDec := 2
   PUBLIC gCijDec := 2
   PUBLIC gStariObrPor := .F.
  // PUBLIC gPoreziRaster := "D"
   PUBLIC gPratiStanje := "N"
   PUBLIC gIdPos := "1 "
   PUBLIC gPostDO := "N"
   // PUBLIC gIdDio := "  "
   PUBLIC nFeedLines := 6
   PUBLIC gPocStaSmjene := "N"
   PUBLIC gStamPazSmj := "D"
   PUBLIC gStamStaPun := "D"
   PUBLIC CRinitDone := .T.
   PUBLIC gEvidPl := "N"
   PUBLIC gGotPlac := "01"
   PUBLIC gDugPlac := "DP"
   PUBLIC gSifPath := my_home()
   PUBLIC LocSIFPATH := my_home()
   PUBLIC gServerPath := PadR( "i:" + SLASH + "sigma", 40 )
   PUBLIC gKalkDEST := PadR( "a:" + SLASH, 300 )
   PUBLIC gUseChkDir := "N"
   PUBLIC gStrValuta := Space( 4 )
   // upit o nacinu placanja
   PUBLIC gUpitNp := "N"
   // podaci kase - zaglavlje
   PUBLIC gFirNaziv := Space( 35 )
   PUBLIC gFirAdres := Space( 35 )
   PUBLIC gFirIdBroj := Space( 13 )
   PUBLIC gFirPM := Space( 35 )
   PUBLIC gRnMjesto := Space( 20 )
   PUBLIC gPorFakt := "N"
   PUBLIC gRnPTxt1 := Space( 35 )
   PUBLIC gRnPTxt2 := Space( 35 )
   PUBLIC gRnPTxt3 := Space( 35 )
   PUBLIC gFirTel := Space( 20 )

   // fiskalni parametri
   //gVodiOdj := "N"
   gRnSpecOpc := "N"
   gRadniRac := "N"
   gDirZaklj := "D"
   gDupliArt := "D"
   gDupliUpoz := "N"
   gDisplay := "N"

   // citaj parametre iz metric tabele
   gFirNaziv := fetch_metric( "pos_header_org_naziv", NIL, gFirNaziv )
   gFirAdres := fetch_metric( "pos_header_org_adresa", NIL, gFirAdres )
   gFirIdBroj := fetch_metric( "pos_header_org_id_broj", NIL, gFirIdBroj )
   gFirPM := fetch_metric( "pos_header_pm", NIL, gFirPM )
   gRnMjesto := fetch_metric( "pos_header_mjesto", NIL, gRnMjesto )
   gFirTel := fetch_metric( "pos_header_telefon", NIL, gFirTel )
   gRnPTxt1 := fetch_metric( "pos_header_txt_1", NIL, gRnPTxt1 )
   gRnPTxt2 := fetch_metric( "pos_header_txt_2", NIL, gRnPTxt2 )
   gRnPTxt3 := fetch_metric( "pos_header_txt_3", NIL, gRnPTxt3 )
   gPorFakt := fetch_metric( "StampatiPoreskeFakture", NIL, gPorFakt )
   gIdPos := fetch_metric( "IDPos", my_user(), gIdPos )
   gPostDO := fetch_metric( "ZasebneCjelineObjekta", NIL, gPostDO )
   // gIdDio := fetch_metric( "OznakaDijelaObjekta", nil, gIdDio )
   gServerPath := fetch_metric( "PutanjaServera", NIL, gServerPath )
   gKalkDest := fetch_metric( "KalkDestinacija", my_user(), gKalkDest )
   gUseChkDir := fetch_metric( "KoristitiDirektorijProvjere", my_user(), gUseChkDir )
   gStrValuta := fetch_metric( "StranaValuta", NIL, gStrValuta )
   gLocPort := fetch_metric( "OznakaLokalnogPorta", my_user(), gLocPort )
   gGotPlac := fetch_metric( "OznakaGotovinskogPlacanja", NIL, gGotPlac )
   gDugPlac := fetch_metric( "OznakaDugPlacanja", NIL, gDugPlac )
   // gRnInfo := fetch_metric( "RacunInfo", NIL, gRnInfo )


   gServerPath := AllTrim( gServerPath )
   IF ( Right( gServerPath, 1 ) <> SLASH )
      gServerPath += SLASH
   ENDIF

   // principi rada kase
   cPrevPSS := gPocStaSmjene

   gZadCij := fetch_metric( "AzuriranjeCijena", NIL, gZadCij )
   //gVodiOdj := fetch_metric( "VodiOdjeljenja", NIL, gVodiOdj )
   gRadniRac := fetch_metric( "RadniRacuni", NIL, gRadniRac )
   gDirZaklj := fetch_metric( "DirektnoZakljucivanjeRacuna", NIL, gDirZaklj )
   gRnSpecOpc := fetch_metric( "RacunSpecifOpcije", NIL, gRnSpecOpc )
   gDupliArt := fetch_metric( "DupliArtikli", NIL, gDupliArt )
   gDupliUpoz := fetch_metric( "DupliUnosUpozorenje", NIL, gDupliUpoz )
   gPratiStanje := fetch_metric( "PratiStanjeRobe", NIL, gPratiStanje )
   gPocStaSmjene := fetch_metric( "PratiPocetnoStanjeSmjene", NIL, gPocStaSmjene )
   gStamPazSmj := fetch_metric( "StampanjePazara", NIL, gStamPazSmj )
   gStamStaPun := fetch_metric( "StampanjePunktova", NIL, gStamStaPun )
   //gVSmjene := fetch_metric( "VoditiPoSmjenama", NIL, gVsmjene )
   gSezonaTip := fetch_metric( "TipSezone", NIL, gSezonaTip )
   gSifUpravn := fetch_metric( "UpravnikIspravljaCijene", NIL, gSifUpravn )
   gDisplay := fetch_metric( "DisplejOpcije", NIL, gDisplay )
   gEntBarCod := fetch_metric( "BarkodEnter", my_user(), gEntBarCod )
   gEvidPl := fetch_metric( "EvidentiranjeVrstaPlacanja", NIL, gEvidPl )
   gSifUvPoNaz := fetch_metric( "PretragaArtiklaPoNazivu", NIL, gSifUvPoNaz )
   gDiskFree := fetch_metric( "SlobodniProstorDiska", NIL, gDiskFree )

   // izgled racuna
   gSjecistr := PadR( GETPStr( gSjeciStr ), 20 )
   gOtvorstr := PadR( GETPStr( gOtvorStr ), 20 )

  // gPoreziRaster := fetch_metric( "PorezniRaster", NIL, gPoreziRaster )
   nFeedLines := fetch_metric( "BrojLinijaZaKrajRacuna", NIL, nFeedLines )
   gSjeciStr := fetch_metric( "SekvencaSjeciTraku", NIL, gSjeciStr )
   gOtvorStr := fetch_metric( "SekvencaOtvoriLadicu", NIL, gOtvorStr )

   gSjeciStr := Odsj( @gSjeciStr )
   gOtvorStr := Odsj( @gOtvorStr )

   gZagIz := fetch_metric( "IzgledZaglavlja", NIL, gZagIz )
   gRnHeader := fetch_metric( "RacunHeader", NIL, gRnHeder )
   gRnFuter := fetch_metric( "RacunFooter", NIL, gRnFuter )

   // izgled racuna
   grbCjen := fetch_metric( "RacunCijenaSaPDV", NIL, grbCjen )
   grbStId := fetch_metric( "RacunStampaIDArtikla", NIL, grbStId )
   grbReduk := fetch_metric( "RacunRedukcijaTrake", NIL, grbReduk )

   // cijene
   gSetMPCijena := fetch_metric( "pos_set_cijena", NIL, gSetMPCijena )
   gIdCijena := fetch_metric( "SetCijena", NIL, gIdCijena )
   gPopust := fetch_metric( "Popust", NIL, gPopust )
   gPopDec := fetch_metric( "PopustDecimale", NIL, gPopDec )
   // gPopVar := fetch_metric( "PopustVarijanta", NIL, gPopVar )
   gPopZCj := fetch_metric( "PopustZadavanjemCijene", NIL, gPopZCj )
   gPopProc := fetch_metric( "PopustProcenat", NIL, gPopProc )
   gPopIzn := fetch_metric( "PopustIznos", NIL, gPopIzn )
   gPopIznP := fetch_metric( "PopustVrijednostProcenta", NIL, gPopIznP )

   gColleg := fetch_metric( "PodesenjeNonsense", NIL, gColleg )
   gDuplo := fetch_metric( "AzurirajUPomocnuBazu", NIL, gDuplo )
   gDuploKum := fetch_metric( "KumulativPomocneBaze", NIL, gDuploKum )
   gDuploSif := fetch_metric( "SifrarnikPomocneBaze", NIL, gDuploSif )
   gFMKSif := fetch_metric( "FMKSifrarnik", NIL, gFmkSif )
   gRNALSif := fetch_metric( "RNALSifrarnik", NIL, gRNALSif )
   gRNALKum := fetch_metric( "RNALKumulativ", NIL, gRNALKum )

   gDuzSifre := fetch_metric( "DuzinaSifre", my_user(), gDuzSifre )

   gUpitNp := fetch_metric( "UpitZaNacinPlacanja", NIL, gUpitNp )

   PUBLIC gStela := CryptSC( "STELA" )
   PUBLIC gPVrsteP := .F.
   gPVrsteP := fetch_metric( "AzuriranjePrometaPoVP", NIL, gPVrsteP )


   PUBLIC gSQLKom
   gSQLLogBase := my_get_from_ini( "SQL", "SQLLogBase", "c:" + SLASH + "sigma", EXEPATH )

   gSamoProdaja := fetch_metric( "SamoProdaja", NIL, gSamoProdaja )

   PUBLIC gPosSirovine
   PUBLIC gPosKalk

   PUBLIC gSQLSynchro
   PUBLIC gPosModem

   PUBLIC glRetroakt := .F.

   gPosSirovine := "D"
   gPosKalk := "D"
   gSQLSynchro := "D"
   gPosModem := "D"

   PUBLIC glPorezNaSvakuStavku := .F.
   PUBLIC glPorNaSvStRKas := .F.

   IF select_o_pos_kase( gIdPos )
      gPosNaz := AllTrim( KASE->Naz )
   ELSE
      gPosNaz := "SERVER"
   ENDIF
   CLOSE ALL

   SetNazDVal() // set valuta
   param_tezinski_barkod( .T. ) // setuj parametar tezinski_barkod
   max_kolicina_kod_unosa( .T. ) // maksimalna kolicina kod unosa racuna
   // kalk_konto_za_stanje_pos( .T. ) // kalk konto za stanje pos artikla
   fiscal_opt_active() // koristenje fiskalnih opcija

   // gRobaBlock := {| Ch | pos_roba_block( Ch ) }

   radna_prodavnica( gIdPos )
   set_sql_search_path( radna_prodavnica_sql_schema() )


   RETURN .T.
