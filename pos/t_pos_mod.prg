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

MEMVAR gPosProdajnoMjesto

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

   Fx := 4
   Fy := 8

   pos_init()
   CLOSE ALL
   pos_check_dbf_fields()

   DO WHILE ( .T. )
      box_x_koord( Fx )
      box_y_koord( Fy )
      g_cUserLevel := pos_prijava( Fx, Fy )
      IF g_cUserLevel == "X"
         RETURN .F.
      ENDIF
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

   PUBLIC gOcitBarKod := .F.
   PUBLIC gSmijemRaditi := 'D'
   PUBLIC gPosSamoProdaja := 'N'
   PUBLIC gZauzetSam := 'N'

   // sifra radnika
   PUBLIC gIdRadnik
   // prezime i ime korisnika (iz OSOB)
   PUBLIC gKorIme
   PUBLIC gSTRAD // status radnika
   PUBLIC gPopust := 0
   PUBLIC gPopDec := 2
   // PUBLIC gPopZcj := "N"
   PUBLIC gPopProc := "N"
   PUBLIC gPopIzn := 0
   PUBLIC gPopIznP := 0
   PUBLIC SC_Opisi[ 5 ]      // nazivi (opisi) setova cijena
   PUBLIC gSmjena := " "   // identifikator smjene

   // PUBLIC gDupliArt        // da li dopusta unos duplih artikala na racunu
   PUBLIC gDupliUpoz       // ako se dopusta, da li se radnik upozorava na duple

   PUBLIC gPosProdajnoMjesto           // id prodajnog mjesta
   PUBLIC nFeedLines       // broj linija potrebnih da se racun otcijepi
   PUBLIC CRinitDone       // da li je uradjen init kase (na pocetku smjene)

   PUBLIC gDomValuta
   PUBLIC gDisplay  // koristiti ispis na COM DISPLAY

   PUBLIC gStamPazSmj      // da li se automatski stampa pazar smjene
   // na kasi
   PUBLIC gStamStaPun      // da li se automatski stampa stanje
   // nedijeljenih punktova koje kasa pokriva

   PUBLIC gRnSpecOpc  // HOPS - rn specificne opcije
   PUBLIC gSjeciStr := ""
   PUBLIC gOtvorStr := ""
   PUBLIC gSezonaTip := "M"
   PUBLIC gSifUpravn := "D"
   PUBLIC gPosPretragaRobaUvijekPoNazivu := "N" // sifra uvijek po nazivu

   PUBLIC gRnHeder := "RacHeder.TXT"
   PUBLIC gRnFuter := "RacPodn.TXT "
   PUBLIC gZagIz := "1;2;"
   PUBLIC gDuplo := "N"
   PUBLIC gDuploKum := ""
   PUBLIC gDuploSif := ""

   PUBLIC gDiskFree := "N"
   // PUBLIC grbCjen := 2
   PUBLIC grbStId := "D"

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

   PUBLIC gPopProc := "N"
   PUBLIC gIsPopust := .F.
   PUBLIC gKolDec := 2
   PUBLIC gCijDec := 2
   PUBLIC gStariObrPor := .F.
   PUBLIC gPosPratiStanjePriProdaji := "N"
   PUBLIC gPosProdajnoMjesto := "1 "
   PUBLIC gPostDO := "N"
   PUBLIC nFeedLines := 6
   PUBLIC gStamPazSmj := "D"
   PUBLIC gStamStaPun := "D"
   PUBLIC CRinitDone := .T.
   PUBLIC gSifPath := my_home()
   PUBLIC LocSIFPATH := my_home()

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

   gRnSpecOpc := "N"
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
   gPosProdajnoMjesto := PadR( get_f18_param( "pos_pm" ), 2 )
   gPostDO := fetch_metric( "ZasebneCjelineObjekta", NIL, gPostDO )
   gRnSpecOpc := fetch_metric( "RacunSpecifOpcije", NIL, gRnSpecOpc )
   gDupliUpoz := fetch_metric( "DupliUnosUpozorenje", NIL, gDupliUpoz )
   gPosPratiStanjePriProdaji := fetch_metric( "PratiStanjeRobe", NIL, gPosPratiStanjePriProdaji )
   gStamPazSmj := fetch_metric( "StampanjePazara", NIL, gStamPazSmj )
   gStamStaPun := fetch_metric( "StampanjePunktova", NIL, gStamStaPun )
   gSezonaTip := fetch_metric( "TipSezone", NIL, gSezonaTip )
   gSifUpravn := fetch_metric( "UpravnikIspravljaCijene", NIL, gSifUpravn )
   gDisplay := fetch_metric( "DisplejOpcije", NIL, gDisplay )
   gPosPretragaRobaUvijekPoNazivu := fetch_metric( "PretragaArtiklaPoNazivu", NIL, gPosPretragaRobaUvijekPoNazivu )
   gDiskFree := fetch_metric( "SlobodniProstorDiska", NIL, gDiskFree )

   // izgled racuna
   gSjecistr := PadR( GETPStr( gSjeciStr ), 20 )
   gOtvorstr := PadR( GETPStr( gOtvorStr ), 20 )

   nFeedLines := fetch_metric( "BrojLinijaZaKrajRacuna", NIL, nFeedLines )
   gSjeciStr := fetch_metric( "SekvencaSjeciTraku", NIL, gSjeciStr )
   gOtvorStr := fetch_metric( "SekvencaOtvoriLadicu", NIL, gOtvorStr )

   gSjeciStr := Odsj( @gSjeciStr )
   gOtvorStr := Odsj( @gOtvorStr )

   gZagIz := fetch_metric( "IzgledZaglavlja", NIL, gZagIz )
   gRnHeader := fetch_metric( "RacunHeader", NIL, gRnHeder )
   gRnFuter := fetch_metric( "RacunFooter", NIL, gRnFuter )

   // izgled racuna
   // grbCjen := fetch_metric( "RacunCijenaSaPDV", NIL, grbCjen )

   grbStId := fetch_metric( "RacunStampaIDArtikla", NIL, grbStId )
   // cijene
   gPopust := fetch_metric( "Popust", NIL, gPopust )
   gPopDec := fetch_metric( "PopustDecimale", NIL, gPopDec )
   // gPopZCj := fetch_metric( "PopustZadavanjemCijene", NIL, gPopZCj )
   gPopProc := fetch_metric( "PopustProcenat", NIL, gPopProc )
   gPopIzn := fetch_metric( "PopustIznos", NIL, gPopIzn )
   gPopIznP := fetch_metric( "PopustVrijednostProcenta", NIL, gPopIznP )

   gDuplo := fetch_metric( "AzurirajUPomocnuBazu", NIL, gDuplo )
   gDuploKum := fetch_metric( "KumulativPomocneBaze", NIL, gDuploKum )
   gDuploSif := fetch_metric( "SifrarnikPomocneBaze", NIL, gDuploSif )
   gPosSamoProdaja := fetch_metric( "SamoProdaja", NIL, gPosSamoProdaja )
   PUBLIC glRetroakt := .F.
   PUBLIC glPorezNaSvakuStavku := .F.

   CLOSE ALL

   pos_set_naziv_domaca_valuta() // set valuta
   param_tezinski_barkod( .T. ) // setuj parametar tezinski_barkod
   pos_max_kolicina_kod_unosa( .T. ) // maksimalna kolicina kod unosa racuna
   fiscal_opt_active() // koristenje fiskalnih opcija

   set_sql_search_path( pos_prodavnica_sql_schema() )

   RETURN .T.


FUNCTION pos_pm()

   IF Type("gPosProdajnoMjesto") == "U"
     RETURN "1 "
   ENDIF

   RETURN gPosProdajnoMjesto
