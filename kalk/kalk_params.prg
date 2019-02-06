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

MEMVAR gCijene, gDefNiv

STATIC s_cKalkFinIstiBroj := NIL
STATIC s_cKalkPreuzimanjeTroskovaIzSifRoba := NIL
STATIC s_cKalkMetodaNc := NIL
STATIC s_cKonverzijaValuteDN := NIL
STATIC s_cKalkPosGeneracijaKalk11NaOsnovuPos42DN := NIL
STATIC s_cFinAutomatskaRavnotezaKodAzuriranjaDN := NIL

FUNCTION kalk_params()

   LOCAL nIzbor := 1
   LOCAL aOpc := {}
   LOCAL aOpcExe := {}

   AAdd( aOpc, "1. osnovni podaci o firmi                                 " )
   AAdd( aOpcExe, {|| parametri_organizacije() } )

   AAdd( aOpc, "2. metoda proračuna NC, mogucnosti ispravke dokumenata " )
   AAdd( aOpcExe, {|| kalk_par_metoda_nc( 'D' ) } )

   AAdd( aOpc, "3. varijante obrade i prikaza pojedinih dokumenata " )
   AAdd( aOpcExe, {|| kalk_par_varijante_prikaza( 'D' ) } )

   AAdd( aOpc, "4. nazivi troškova za 10-ku " )
   AAdd( aOpcExe, {|| kalk_troskovi_10ka( 'D' ) } )

   AAdd( aOpc, "5. nazivi troškova za 24-ku" )
   AAdd( aOpcExe, {|| kalk_par_troskovi_24( 'D' ) } )

   AAdd( aOpc, "6. nazivi troskova za RN" )
   AAdd( aOpcExe, {|| kalk_par_troskovi_rn( 'D' ) } )

   AAdd( aOpc, "7. prikaz cijene,%,iznosa" )
   AAdd( aOpcExe, {|| kalk_par_cijene( 'D' ) } )

   AAdd( aOpc, "8. način formiranja zavisnih dokumenata" )
   AAdd( aOpcExe, {|| kalk_par_zavisni_dokumenti( 'D' ) } )

   AAdd( aOpc, "B. parametri - razno" )
   AAdd( aOpcExe, {|| kalk_par_razno( 'D' ) } )

   f18_menu( "pars", .F., nIzbor, aOpc, aOpcExe )

   my_close_all_dbf()

   RETURN .T.



FUNCTION kalk_preuzimanje_troskova_iz_sif_roba( cSet )

   IF s_cKalkPreuzimanjeTroskovaIzSifRoba == NIL
      s_cKalkPreuzimanjeTroskovaIzSifRoba := fetch_metric( "kalk_preuzimanje_troskova_iz_sif_roba", NIL, "N" )
   ENDIF

   IF cSet != NIL
      set_metric( "kalk_preuzimanje_troskova_iz_sif_roba", NIL, cSet )
      s_cKalkPreuzimanjeTroskovaIzSifRoba := cSet
   ENDIF

   RETURN s_cKalkPreuzimanjeTroskovaIzSifRoba



FUNCTION kalk_par_varijante_prikaza()

   LOCAL nX := 1
   LOCAL cRobaTrosk :=  kalk_preuzimanje_troskova_iz_sif_roba()
   LOCAL cKonverzijaValuteDn := kalk_konverzija_valute_na_unosu()
   LOCAL cFinAutoAzurDN := param_fin_automatska_ravnoteza_kod_azuriranja()
   LOCAL GetList := {}

   Box(, 23, 76, .F., "Varijante obrade i prikaza pojedinih dokumenata" )

   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "14 - Nivelaciju izvršiti na ukupno stanje/na prodanu kolicinu  1/2 ?" GET gNiv14  VALID gNiv14 $ "12"
   nX += 1
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "10 - prikaz ukalkulisanog poreza (D/N)" GET  g10Porez  PICT "@!" VALID g10Porez $ "DN"
   nX += 1
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "10 - automatsko preuzimanje troškova iz sifrarnika robe ? (0/D/N)" GET cRobaTrosk VALID cRobaTrosk $ "0DN" PICT "@!"
   nX += 1
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "   default tip za pojedini trošak:"

   nX += 1
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "   " + c10T1 GET gRobaTr1Tip VALID gRobaTr1Tip $ " %URA" PICT "@!"

   @ box_x_koord() + nX, Col() + 1 SAY c10T2 GET gRobaTr2Tip VALID gRobaTr2Tip $ " %URA" PICT "@!"

   @ box_x_koord() + nX, Col() + 1 SAY c10T3 GET gRobaTr3Tip VALID gRobaTr3Tip $ " %URA" PICT "@!"

   @ box_x_koord() + nX, Col() + 1 SAY c10T4 GET gRobaTr4Tip VALID gRobaTr4Tip $ " %URA" PICT "@!"

   @ box_x_koord() + nX, Col() + 1 SAY c10T5 GET gRobaTr5Tip VALID gRobaTr5Tip $ " %URA" PICT "@!"

   nX += 1
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Mogućnost konverzije valute pri unosu dokumenta (D/N)" GET cKonverzijaValuteDn VALID cKonverzijaValuteDn $ "DN" PICT "@!"

   nX += 1
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Program se koristi isključivo za vođenje magacina po NC  Da-1 / Ne-2 " GET gMagacin VALID gMagacin $ "12"

   nX += 2
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Varijanta FAKT13->KALK11 ( 1-mpc iz šifarnika, 2-mpc iz FAKT13)" GET  gVar13u11  PICT "@!" VALID gVar13u11 $ "12"
   nX += 2
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Varijanta KALK 11 bez prikaza NC i storna RUC-a (D/N)" GET  g11bezNC  PICT "@!" VALID g11bezNC $ "DN"
   nX += 1
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Pri ulaznoj kalkulaciji pomoć sa C.sa PDV (D/N)" GET  gcMpcKalk10 PICT "@!" VALID gcMpcKalk10 $ "DN"
   nX += 1
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Varijanta popusta na dokumentima, default P-%, C-cijena" GET gRCRP

   nX += 1
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "80 - var.rek.po tarifama ( 1 -samo ukupno / 2 -prod.1,prod.2,ukupno)" GET  g80VRT PICT "9" VALID g80VRT $ "12"

   nX += 2
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Količina za nivelaciju iz FAKT-a " GET  gKolicFakt VALID gKolicFakt $ "DN"  PICT "@!"

   @ box_x_koord() + nX, Col() + 1 SAY8 "Auto ravnoteža naloga (FIN):" GET cFinAutoAzurDN VALID cFinAutoAzurDN $ "DN" PICT "@!"
   nX += 1
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Automatsko ažuriranje cijena u šifarnik (D/N)" GET gAutoCjen VALID gAutoCjen $ "DN" PICT "@!"
   READ

   BoxC()

   IF LastKey() <> K_ESC
      set_metric( "kalk_magacin_po_nc", NIL, gMagacin )
      set_metric( "kalk_dokument_10_prikaz_ukalk_poreza", NIL, g10Porez )
      set_metric( "kalk_dokument_14_varijanta_poreza", NIL, gVarVP )
      set_metric( "kalk_dokument_11_bez_nc", NIL, g11bezNC )
      set_metric( "kalk_dokument_80_rekap_po_tar", NIL, g80VRT )
      set_metric( "kalk_tip_nivelacije_14", NIL, gNiv14 )
      set_metric( "kalk_varijanta_fakt_13_kalk_11_cijena", NIL, gVar13u11 )
      set_metric( "kalk_pomoc_sa_mpc", NIL, gcMpcKalk10 )
      set_metric( "kalk_kolicina_kod_nivelacije_fakt", NIL, gKolicFakt )
      kalk_preuzimanje_troskova_iz_sif_roba( cRobaTrosk )
      set_metric( "kalk_varijanta_popusta_na_dokumentima", NIL, gRCRP )
      set_metric( "kalk_automatsko_azuriranje_cijena", NIL, gAutoCjen )
      set_metric( "kalk_trosak_1_tip", NIL, gRobaTr1Tip )
      set_metric( "kalk_trosak_2_tip", NIL, gRobaTr2Tip )
      set_metric( "kalk_trosak_3_tip", NIL, gRobaTr3Tip )
      set_metric( "kalk_trosak_4_tip", NIL, gRobaTr4Tip )
      set_metric( "kalk_trosak_5_tip", NIL, gRobaTr5Tip )
      kalk_konverzija_valute_na_unosu( cKonverzijaValuteDn )
      param_fin_automatska_ravnoteza_kod_azuriranja( cFinAutoAzurDN )
   ENDIF

   RETURN NIL


FUNCTION param_fin_automatska_ravnoteza_kod_azuriranja( cSet )

   LOCAL cParamKey := "kalk_kontiranje_automatska_ravnoteza_naloga"
   LOCAL cUserGlobal := NIL
   LOCAL xDefault := "N"

   IF cSet != NIL
      s_cFinAutomatskaRavnotezaKodAzuriranjaDN := cSet
      set_metric( cParamKey, cUserGlobal, cSet )
   ENDIF

   IF s_cFinAutomatskaRavnotezaKodAzuriranjaDN == NIL
      s_cFinAutomatskaRavnotezaKodAzuriranjaDN := fetch_metric( cParamKey, cUserGlobal, xDefault )
   ENDIF

   RETURN s_cFinAutomatskaRavnotezaKodAzuriranjaDN


FUNCTION fin_automatska_ravnoteza_kod_azuriranja()
   RETURN  param_fin_automatska_ravnoteza_kod_azuriranja() == "D"


FUNCTION kalk_konverzija_valute_na_unosu( cSet )

   IF cSet != NIL
      s_cKonverzijaValuteDN := cSet
      set_metric( "kalk_konverzija_valute_na_unosu", NIL, cSet )
   ENDIF

   IF s_cKonverzijaValuteDN == NIL
      s_cKonverzijaValuteDN := fetch_metric( "kalk_konverzija_valute_na_unosu", NIL, "N" )
   ENDIF

   RETURN s_cKonverzijaValuteDN


FUNCTION is_kalk_konverzija_valute_na_unosu()
   RETURN kalk_konverzija_valute_na_unosu() == "D"

FUNCTION kalk_par_razno()

   LOCAL _brojac := "N"
   LOCAL cUnosBarKodDN := "N"
   LOCAL nX := 1
   LOCAL _reset_roba := fetch_metric( "kalk_reset_artikla_kod_unosa", my_user(), "N" )
   LOCAL _rabat := fetch_metric( "pregled_rabata_kod_ulaza", my_user(), "N" )
   LOCAL _vise_konta := fetch_metric( "kalk_dokument_vise_konta", NIL, "N" )

   LOCAL _opis := fetch_metric( "kalk_dodatni_opis_kod_unosa_dokumenta", NIL, "N" )
   LOCAL nLenBrKalk :=  kalk_duzina_brojaca_dokumenta()
   LOCAL cRobaTrazi := PadR( roba_trazi_po_sifradob(), 20 )
   LOCAL nPragOdstupanjaNc := prag_odstupanja_nc_sumnjiv()
   LOCAL nStandardnaStopaMarza  := standardna_stopa_marze()
   LOCAL GetList := {}

   IF glKalkBrojacPoKontima
      _brojac := "D"
   ENDIF

   IF roba_barkod_pri_unosu()
      cUnosBarKodDN := "D"
   ENDIF

   Box(, 20, 75, .F., "RAZNO" )

   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Brojač kalkulacija D/N     " GET gBrojacKalkulacija PICT "@!" VALID gBrojacKalkulacija $ "DN"
   @ box_x_koord() + nX, Col() + 2 SAY8 "dužina brojača:" GET nLenBrKalk PICT "9" VALID ( nLenBrKalk > 0 .AND. nLenBrKalk < 10 )
   ++nX

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Brojac kalkulacija po kontima (D/N)" GET _brojac VALID _brojac $ "DN" PICT "@!"
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Koristiti BARKOD pri unosu kalkulacija (D/N)" GET cUnosBarKodDN VALID cUnosBarKodDN $ "DN" PICT "@!"
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Potpis na kraju naloga D/N     " GET gPotpis VALID gPotpis $ "DN"

   nX += 2
   @ box_x_koord() + nX, Col() + 2 SAY "Vise konta na dokumentu (D/N) ?" GET _vise_konta VALID _vise_konta $ "DN" PICT "@!"
   ++nX

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "F-ja za odredjivanje dzokera F1 u kontiranju" GET gFunKon1 PICT "@S28"
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "F-ja za odredjivanje dzokera F2 u kontiranju" GET gFunKon2 PICT "@S28"
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Limit za otvorene stavke" GET gnLOst PICT "99999"
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Timeout kod azuriranja dokumenta (sec.)" GET gAzurTimeout PICT "99999"
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Timeout kod azuriranja fin.naloga (sec.)" GET gAzurFinTO PICT "99999"
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Auto obrada dokumenata iz cache tabele (D/N)" GET gCache VALID gCache $ "DN" PICT "@!"
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Prag odstupanja NC od posljednjeg ulaza sumnjiv :" GET nPragOdstupanjaNc PICT "999.99"
   @ box_x_koord() + nX, Col() SAY "%"
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Standardna stopa marze [NC x ( 1 + ST_STOPA ) = Roba.VPC] :" GET nStandardnaStopaMarza PICT "999.99"
   @ box_x_koord() + nX, Col() SAY "%"

   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Traži robu prema (prazno/SIFRADOB/)" GET cRobaTrazi PICT "@15"

   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Reset artikla prilikom unosa dokumenta (D/N)" GET _reset_roba PICT "@!" VALID _reset_roba $ "DN"
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Pregled rabata za dobavljaca kod unosa ulaza (D/N)" GET _rabat PICT "@!" VALID _rabat $ "DN"
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Def.opisa kod unosa (D/N)" GET _opis VALID _opis $ "DN" PICT "@!"


   READ

   BoxC()

   IF LastKey() <> K_ESC

      IF _brojac == "D"
         glKalkBrojacPoKontima := .T.
      ELSE
         glKalkBrojacPoKontima := .F.
      ENDIF

      roba_barkod_pri_unosu( cUnosBarKodDN == "D" )
      set_metric( "kalk_brojac_kalkulacija", NIL, gBrojacKalkulacija )
      set_metric( "kalk_brojac_dokumenta_po_kontima", NIL, glKalkBrojacPoKontima )
      set_metric( "kalk_potpis_na_kraju_naloga", NIL, gPotpis )

      //set_metric( "kalk_zabrana_promjene_tarifa", NIL, gPromTar )
      set_metric( "kalk_djoker_f1_kod_kontiranja", NIL, gFunKon1 )
      set_metric( "kalk_djoker_f2_kod_kontiranja", NIL, gFunKon2 )
      set_metric( "kalk_timeout_kod_azuriranja", NIL, gAzurTimeout )
      set_metric( "kalk_cache_tabela", f18_user(), gCache )
      prag_odstupanja_nc_sumnjiv( nPragOdstupanjaNc )
      set_metric( "kalk_limit_za_otvorene_stavke", f18_user(), gnLOst )
      kalk_duzina_brojaca_dokumenta( nLenBrKalk )
      roba_trazi_po_sifradob( cRobaTrazi )
      standardna_stopa_marze( nStandardnaStopaMarza )
      set_metric( "kalk_reset_artikla_kod_unosa", my_user(), _reset_roba )
      set_metric( "pregled_rabata_kod_ulaza", my_user(), _rabat )
      set_metric( "kalk_dodatni_opis_kod_unosa_dokumenta", NIL, _opis )
      set_metric( "kalk_dokument_vise_konta", NIL, _vise_konta )

   ENDIF

   RETURN .T.


/*
 *     Ispravka parametara "METODA NC, ISPRAVKA DOKUMENATA"
 */

FUNCTION kalk_par_metoda_nc()

   LOCAL cMetodaNc := kalk_metoda_nc()
   LOCAL GetList := {}

   Box(, 4, 75, .F., "METODA NC, ISPRAVKA DOKUMENATA" )
   @ box_x_koord() + 1, box_y_koord() + 2 SAY8 "Metoda nabavne cijene: bez kalk./zadnja/prosječna/prva ( /1/2/3)" GET cMetodaNc VALID cMetodaNC $ " 123" .AND. metodanc_info()
   @ box_x_koord() + 2, box_y_koord() + 2 SAY8 "Program omogućava /ne omogućava ažuriranje sumnjivih dokumenata (1/2)" GET gCijene VALID  gCijene $ "12"
   @ box_x_koord() + 4, box_y_koord() + 2 SAY8 "Tekući odgovor na pitanje o promjeni cijena ?" GET gDefNiv VALID  gDefNiv $ "DN" PICT "@!"
   READ
   BoxC()

   IF LastKey() <> K_ESC
      kalk_metoda_nc ( cMetodaNC )
      set_metric( "kalk_promjena_cijena_odgovor", NIL, gDefNiv )
      set_metric( "kalk_azuriranje_sumnjivih_dokumenata", NIL, gCijene )
      set_metric( "kalk_broj_decimala_za_kolicinu", NIL, gDecKol )
   ENDIF

   RETURN .F.


FUNCTION nije_dozvoljeno_azuriranje_sumnjivih_stavki()

   RETURN ( gCijene == "2" )


FUNCTION dozvoljeno_azuriranje_sumnjivih_stavki()

   RETURN !( gCijene == "2" )


FUNCTION sumnjive_stavke_error( lForce )

   hb_default( @lForce, .F. )

   IF lForce .OR. nije_dozvoljeno_azuriranje_sumnjivih_stavki()
      Beep( 2 )
      error_bar( "kalk_asist", "sumnjive stavke error" )
      CLEAR TYPEAHEAD // zaustavi asistenta
      _ERROR := "1"
   ENDIF

   RETURN .T.


FUNCTION metodanc_info()

   IF kalk_metoda_nc() == " "
      Beep( 2 )
      Msg( "Ova metoda omogucava da izvrsite proizvoljne ispravke#" + ;
         "Program ce Vam omoguciti da ispravite bilo koji dokument#" + ;
         "bez bilo kakve analize. Zato nakon ispravki dobro provjerite#" + ;
         "odgovarajuce kartice.#" + ;
         "Ako ste neiskusan korisnik konsultujte uputstvo !", 0 )

   ELSEIF kalk_metoda_nc() $ "13"
      Beep( 2 )
      Msg( "Ovu metodu obracuna nabavne cijene ne preporucujemo !#" + ;
         "Molimo Vas da usvojite metodu  2 - srednja nabavna cijena !", 0 )
   ENDIF

   RETURN .T.



FUNCTION kalk_par_cijene()

   LOCAL cCijena := kalk_pic_cijena_bilo_gpiccdem()
   LOCAL cIznos := kalk_pic_iznos_bilo_gpicdem()
   LOCAL cKolicina :=  kalk_pic_kolicina_bilo_gpickol()
   LOCAL GetList := {}

   Box(, 10, 60, .F., "PARAMETRI PRIKAZA" )

   @ box_x_koord() + 1, box_y_koord() + 2 SAY8 "Prikaz Cijene  " GET cCijena
   @ box_x_koord() + 2, box_y_koord() + 2 SAY8 "Prikaz procenta" GET gPicProc
   @ box_x_koord() + 3, box_y_koord() + 2 SAY8 "Prikaz iznosa  " GET cIznos
   @ box_x_koord() + 4, box_y_koord() + 2 SAY8 "Prikaz količine" GET cKolicina

   @ box_x_koord() + 5, box_y_koord() + 2 SAY8 "Ispravka NC    " GET gPicNC
   @ box_x_koord() + 6, box_y_koord() + 2 SAY8 "Decimale za količine" GET gDecKol PICT "9"
   @ box_x_koord() + 7, box_y_koord() + 2 SAY8 Replicate( "-", 30 )

   // @ box_x_koord() + 8, box_y_koord() + 2 SAY8 "Dodatno proširenje cijene" GET gFPicCDem
   // @ box_x_koord() + 9, box_y_koord() + 2 SAY8 "Dodatno proširenje iznosa" GET gFPicDem
   // @ box_x_koord() + 10, box_y_koord() + 2 SAY8 "Dodatno proširenje količine" GET gFPicKol
   READ
   BoxC()

   IF LastKey() <> K_ESC
      kalk_pic_cijena_bilo_gpiccdem( cCijena )
      set_metric( "kalk_format_prikaza_procenta", NIL, gPicProc )
      kalk_pic_iznos_bilo_gpicdem( cIznos )
      kalk_pic_kolicina_bilo_gpickol( cKolicina )
      set_metric( "kalk_format_prikaza_nabavne_cijene", NIL, gPicNC )
      // set_metric( "kalk_format_prikaza_cijene_prosirenje", nil, gFPicCDem )
      // set_metric( "kalk_format_prikaza_iznosa_prosirenje", nil, gFPicDem )
      // set_metric( "kalk_format_prikaza_kolicine_prosirenje", nil, gFPicKol )
      set_metric( "kalk_broj_decimala_za_kolicinu", NIL, gDecKol )
   ENDIF

   RETURN .T.



FUNCTION is_kalk_fin_isti_broj()

   RETURN kalk_fin_isti_broj() == "D"


FUNCTION kalk_fin_isti_broj( cSet )

   IF s_cKalkFinIstiBroj == NIL
      s_cKalkFinIstiBroj := fetch_metric( "kalk_fin_isti_broj", NIL, "D" )
   ENDIF

   IF cSet != NIL
      s_cKalkFinIstiBroj := cSet
      set_metric( "kalk_fin_isti_broj", NIL, cSet )
   ENDIF

   RETURN s_cKalkFinIstiBroj


FUNCTION kalk_par_zavisni_dokumenti()

   LOCAL cTopsDest := PadR( kalk_destinacija_topska(), 100 )
   LOCAL cKalkTopsAutoRazduzenjeDN := kalk_tops_generacija_kalk_11_na_osnovu_pos_42()
   LOCAL cKalkFinIstiBroj := kalk_fin_isti_broj()
   LOCAL GetList := {}

   Box(, 12, 76, .F., "NAČIN FORMIRANJA ZAVISNIH DOKUMENATA" )

   @ box_x_koord() + 1, box_y_koord() + 2 SAY8 "Automatika formiranja FIN naloga D/N/0" GET gAFin PICT "@!" VALID gAFin $ "DN0"
   @ box_x_koord() + 2, box_y_koord() + 2 SAY8 "Automatika formiranja MAT naloga D/N/0" GET gAMAT PICT "@!" VALID gAMat $ "DN0"
   @ box_x_koord() + 3, box_y_koord() + 2 SAY8 "Automatika formiranja FAKT dokum D/N" GET gAFakt PICT "@!" VALID gAFakt $ "DN"

   @ box_x_koord() + 4, box_y_koord() + 2 SAY8 "Generisati 16-ku nakon 96  D/N (1/2) ?" GET gGen16  VALID gGen16 $ "12"
   @ box_x_koord() + 5, box_y_koord() + 2 SAY8 "Nakon štampe zaduženja prodavnice prenos u TOPS 0-ne/1 /2 " GET gTops  VALID gTops $ "0 /1 /2 /3 /99" PICT "@!"
   @ box_x_koord() + 6, box_y_koord() + 2 SAY8 "Nakon štampe zaduženja prenos u FAKT 0-ne/1 /2 " GET gFakt  VALID gFakt $ "0 /1 /2 /3 /99" PICT "@!"

   @ box_x_koord() + 7, box_y_koord() + 2 SAY8 "KALK-FIN identičan broj (D/N): " GET cKalkFinIstiBroj VALID cKalkFinIstiBroj $ "DN" PICT "@!"
   // READ

   // IF gTops <> "0 " .OR. gFakt <> "0 "
   @ box_x_koord() + 8, box_y_koord() + 2 SAY8 "kalk->tops destinacija: " GET cTopsDest PICT "@S40"
   @ box_x_koord() + 10, box_y_koord() + 2 SAY8 "KALK-POS generisati KALK 11 na osnovu prodaje (D/N) ?" GET cKalkTopsAutoRazduzenjeDN PICT "@!" VALID cKalkTopsAutoRazduzenjeDN $ "DN"

   READ
   // ENDIF

   BoxC()

   IF LastKey() <> K_ESC
      set_metric( "kalk_kontiranje_fin", f18_user(), gAFin )
      set_metric( "kalk_kontiranje_mat", f18_user(), gAMat )
      set_metric( "kalk_kontiranje_fakt", f18_user(), gAFakt )
      set_metric( "kalk_generisi_16_nakon_96", f18_user(), gGen16 )
      set_metric( "kalk_prenos_pos", f18_user(), gTops )
      set_metric( "kalk_prenos_fakt", f18_user(), gFakt )
      kalk_destinacija_topska( cTopsDest )
      kalk_tops_generacija_kalk_11_na_osnovu_pos_42( cKalkTopsAutoRazduzenjeDN )
      kalk_fin_isti_broj( cKalkFinIstiBroj )
   ENDIF

   RETURN NIL



FUNCTION kalk_tops_generacija_kalk_11_na_osnovu_pos_42( cSet )

   IF s_cKalkPosGeneracijaKalk11NaOsnovuPos42DN == NIL
      s_cKalkPosGeneracijaKalk11NaOsnovuPos42DN := fetch_metric( "kalk_tops_prenos_auto_razduzenje", my_user(), "N" )
   ENDIF

   IF cSet != NIL
      set_metric( "kalk_tops_prenos_auto_razduzenje", my_user(), cSet )
      s_cKalkPosGeneracijaKalk11NaOsnovuPos42DN := cSet
   ENDIF

   RETURN s_cKalkPosGeneracijaKalk11NaOsnovuPos42DN

FUNCTION is_kalk_tops_generacija_kalk_11_na_osnovu_pos_42()
   RETURN kalk_tops_generacija_kalk_11_na_osnovu_pos_42() == "D"


FUNCTION kalk_troskovi_10ka()

   PRIVATE  GetList := {}

   Box(, 5, 76, .T., "Troskovi 10-ka" )
   @ box_x_koord() + 1, box_y_koord() + 2  SAY "T1:" GET c10T1
   @ box_x_koord() + 1, box_y_koord() + 40 SAY "T2:" GET c10T2
   @ box_x_koord() + 2, box_y_koord() + 2  SAY "T3:" GET c10T3
   @ box_x_koord() + 2, box_y_koord() + 40 SAY "T4:" GET c10T4
   @ box_x_koord() + 3, box_y_koord() + 2  SAY "T5:" GET c10T5
   READ
   BoxC()

   IF LastKey() <> K_ESC
      set_metric( "kalk_dokument_10_trosak_1", NIL, c10T1 )
      set_metric( "kalk_dokument_10_trosak_2", NIL, c10T2 )
      set_metric( "kalk_dokument_10_trosak_3", NIL, c10T3 )
      set_metric( "kalk_dokument_10_trosak_4", NIL, c10T4 )
      set_metric( "kalk_dokument_10_trosak_5", NIL, c10T5 )

   ENDIF

   RETURN NIL


FUNCTION kalk_par_troskovi_rn()

   PRIVATE GetList := {}

   Box(, 5, 76, .T., "RADNI NALOG" )
   @ box_x_koord() + 1, box_y_koord() + 2  SAY "T 1:" GET cRNT1
   @ box_x_koord() + 1, box_y_koord() + 40 SAY "T 2:" GET cRNT2
   @ box_x_koord() + 2, box_y_koord() + 2  SAY "T 3:" GET cRNT3
   @ box_x_koord() + 2, box_y_koord() + 40 SAY "T 4:" GET cRNT4
   @ box_x_koord() + 3, box_y_koord() + 2  SAY "T 5:" GET cRNT5
   READ
   BoxC()

   IF LastKey() <> K_ESC
      set_metric( "kalk_dokument_rn_trosak_1", NIL, cRNT1 )
      set_metric( "kalk_dokument_rn_trosak_2", NIL, cRNT2 )
      set_metric( "kalk_dokument_rn_trosak_3", NIL, cRNT3 )
      set_metric( "kalk_dokument_rn_trosak_4", NIL, cRNT4 )
      set_metric( "kalk_dokument_rn_trosak_5", NIL, cRNT5 )
   ENDIF

   cIspravka := "N"

   RETURN NIL



FUNCTION kalk_par_troskovi_24()

   PRIVATE  GetList := {}

   Box(, 5, 76, .T., "24 - USLUGE" )
   @ box_x_koord() + 1, box_y_koord() + 2  SAY "T 1:" GET c24T1
   @ box_x_koord() + 1, box_y_koord() + 40 SAY "T 2:" GET c24T2
   @ box_x_koord() + 2, box_y_koord() + 2  SAY "T 3:" GET c24T3
   @ box_x_koord() + 2, box_y_koord() + 40 SAY "T 4:" GET c24T4
   @ box_x_koord() + 3, box_y_koord() + 2  SAY "T 5:" GET c24T5
   @ box_x_koord() + 3, box_y_koord() + 40 SAY "T 6:" GET c24T6
   @ box_x_koord() + 4, box_y_koord() + 2  SAY "T 7:" GET c24T7
   @ box_x_koord() + 4, box_y_koord() + 40 SAY "T 8:" GET c24T8
   READ
   BoxC()

   IF LastKey() <> K_ESC
      set_metric( "kalk_dokument_24_trosak_1", NIL, c24T1 )
      set_metric( "kalk_dokument_24_trosak_2", NIL, c24T2 )
      set_metric( "kalk_dokument_24_trosak_3", NIL, c24T3 )
      set_metric( "kalk_dokument_24_trosak_4", NIL, c24T4 )
      set_metric( "kalk_dokument_24_trosak_5", NIL, c24T5 )
      set_metric( "kalk_dokument_24_trosak_6", NIL, c24T6 )
      set_metric( "kalk_dokument_24_trosak_7", NIL, c24T7 )
      set_metric( "kalk_dokument_24_trosak_8", NIL, c24T8 )
   ENDIF

   RETURN NIL


FUNCTION kalk_metoda_nc( cSet )

   IF s_cKalkMetodaNc == NIL
      s_cKalkMetodaNc := fetch_metric( "kalk_metoda_nc", NIL, "2" )
   ENDIF
   IF cSet != NIL
      s_cKalkMetodaNc := cSet
      set_metric( "kalk_metod_nc", NIL, cSet )
   ENDIF

   RETURN s_cKalkMetodaNc
