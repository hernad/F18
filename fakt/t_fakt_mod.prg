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




CLASS TFaktMod FROM TAppMod

   VAR nDuzinaSifre
   VAR cTekVpc
   VAR lOpcine
   VAR lDoks2
   VAR lId_J
   VAR lCRoba
   VAR cRoba_Rj
   METHOD NEW
   METHOD set_module_gvars
   METHOD mMenu
   METHOD programski_modul_osnovni_meni

ENDCLASS



METHOD new( p1, p2, p3, p4, p5, p6, p7, p8, p9 )

   ::super:new( p1, p2, p3, p4, p5, p6, p7, p8, p9 )

   RETURN self



METHOD mMenu()

   PRIVATE Izbor

   Izbor := 1

   fakt_set_params()
   set_sifk_partn_bank()

   ::programski_modul_osnovni_meni()

   RETURN NIL



METHOD programski_modul_osnovni_meni

   LOCAL aOpc    := {}
   LOCAL aOpcExe := {}
   LOCAL _izbor  := 1

   AAdd( aOpc, "1. unos/ispravka dokumenta             " )
   AAdd( aOpcExe, {|| fakt_unos_dokumenta() } )
   AAdd( aOpc, "2. izvještaji" )
   AAdd( aOpcExe, {|| fakt_izvjestaji() } )
   AAdd( aOpc, "3. pregled dokumenata" )
   AAdd( aOpcExe, {|| fakt_pregled_dokumenata() } )
   AAdd( aOpc, "4. generacija dokumenata" )
   AAdd( aOpcExe, {|| fakt_mnu_generacija_dokumenta() } )
   AAdd( aOpc, "5. moduli - razmjena podataka" )
   AAdd( aOpcExe, {|| fakt_razmjena_podataka() } )
   AAdd( aOpc, "6. udaljene lokacije razmjena podataka" )
   AAdd( aOpcExe, {|| fakt_udaljena_razmjena_podataka() } )
   AAdd( aOpc, "7. ostale operacije nad dokumentima" )
   AAdd( aOpcExe, {|| fakt_ostale_operacije_doks() } )
   AAdd( aOpc, "------------------------------------" )
   AAdd( aOpcExe, {|| NIL } )
   AAdd( aOpc, "8. šifarnici" )
   AAdd( aOpcExe, {|| fakt_sifrarnik() } )
   //AAdd( aOpc, "9. uplate" )
   //AAdd( aOpcExe, {|| mnu_fakt_uplate() } )
   AAdd( aOpc, "------------------------------------" )
   AAdd( aOpcExe, {|| NIL } )
   AAdd( aOpc, "A. štampa ažuriranog dokumenta" )
   AAdd( aOpcExe, {|| fakt_stampa_azuriranog() } )
   AAdd( aOpc, "P. povrat dokumenta u pripremu" )
   AAdd( aOpcExe, {|| Povrat_fakt_dokumenta() } )
   AAdd( aOpc, "------------------------------------" )
   AAdd( aOpcExe, {|| NIL } )
   AAdd( aOpc, "X. parametri" )
   AAdd( aOpcExe, {|| fakt_params_meni() } )

   f18_menu( "fmai", .T., _izbor, aOpc, aOpcExe )

   RETURN .F.


METHOD set_module_gvars()

   LOCAL cSekcija
   LOCAL cVar
   LOCAL cVal

   __default_odt_template()

   ::nDuzinaSifre := 10
   ::cTekVpc := "1"

   PUBLIC gFiltNov := ""
   PUBLIC gVarNum := "1"
   PUBLIC gProtu13 := "N"

   PUBLIC gDK1 := "N"
   PUBLIC gDK2 := "N"

   PUBLIC gFPzag := 0
   PUBLIC gZnPrec := "="
   PUBLIC gnDS := 5             // duzina sifre artikla - sinteticki
   PUBLIC Kurslis := "1"

   PUBLIC gnLMarg := 6  // lijeva margina teksta
   PUBLIC gnLMargA5 := 6  // lijeva margina teksta
   PUBLIC gnTMarg := 11 // gornja margina
   PUBLIC gnTMarg2 := 3 // vertik.pomj. stavki u fakturi var.9
   PUBLIC gnTMarg3 := 0 // vertik.pomj. totala fakture var.9
   PUBLIC gnTMarg4 := 0 // vertik.pomj. za donji dio fakture var.9

   PUBLIC g10Str := hb_UTF8ToStr( "POREZNA FAKTURA br." )
   PUBLIC g10Str2T := "              Predao                  Odobrio                  Preuzeo"

   PUBLIC g20Str := hb_UTF8ToStr( "PREDRAČUN br." )
   PUBLIC g20Str2T := "                                                               Direktor"

   PUBLIC g11Str := hb_UTF8ToStr( "RAČUN MP br." )
   PUBLIC g11Str2T := "              Predao                  Odobrio                  Preuzeo"

   PUBLIC g15Str := hb_UTF8ToStr( "RAČUN br." )
   PUBLIC g15Str2T := "              Predao                  Odobrio                  Preuzeo"

   PUBLIC g12Str := hb_UTF8ToStr( "OTPREMNICA br." )
   PUBLIC g12Str2T := "              Predao                  Odobrio                  Preuzeo"

   PUBLIC g13Str := hb_UTF8ToStr( "OTPREMNICA U MP br." )
   PUBLIC g13Str2T := "              Predao                  Odobrio                  Preuzeo"

   PUBLIC g21Str := hb_UTF8ToStr( "REVERS br." )
   PUBLIC g21Str2T := "              Predao                  Odobrio                  Preuzeo"

   PUBLIC g22Str := hb_UTF8ToStr( "ZAKLJ.OTPREMNICA br." )
   PUBLIC g22Str2T := "              Predao                  Odobrio                  Preuzeo"

   PUBLIC g23Str := hb_UTF8ToStr( "ZAKLJ.OTPR.MP    br." )
   PUBLIC g23Str2T := "              Predao                  Odobrio                  Preuzeo"

   PUBLIC g25Str := hb_UTF8ToStr( "KNJIŽNA OBAVIJEST br." )
   PUBLIC g25Str2T := "              Predao                  Odobrio                  Preuzeo"

   PUBLIC g26Str := hb_UTF8ToStr( "NARUDŽBA SA IZJAVOM br." )
   PUBLIC g26Str2T := "                                      Potpis:"

   PUBLIC g27Str := hb_UTF8ToStr( "PREDRAČUN MP br." )
   PUBLIC g27Str2T := "                                                               Direktor"
   PUBLIC gNazPotStr := Space( 69 )

   // lista kod dodatnog teksta
   PUBLIC g10ftxt := PadR( "", 100 )
   PUBLIC g11ftxt := PadR( "", 100 )
   PUBLIC g12ftxt := PadR( "", 100 )
   PUBLIC g13ftxt := PadR( "", 100 )
   PUBLIC g15ftxt := PadR( "", 100 )
   //PUBLIC g16ftxt := PadR( "", 100 )
   PUBLIC g20ftxt := PadR( "", 100 )
   PUBLIC g21ftxt := PadR( "", 100 )
   PUBLIC g22ftxt := PadR( "", 100 )
   PUBLIC g23ftxt := PadR( "", 100 )
   PUBLIC g25ftxt := PadR( "", 100 )
   PUBLIC g26ftxt := PadR( "", 100 )
   PUBLIC g27ftxt := PadR( "", 100 )

   PUBLIC gDodPar := "2"
   PUBLIC gDatVal := "N"

   PUBLIC gPdvDRb := "N"
   PUBLIC gPdvDokVar := "1"


   PUBLIC gTipF := "2"
   PUBLIC gVarF := "2"
   PUBLIC gVarRF := " "
   PUBLIC gKriz := 0
   PUBLIC gKrizA5 := 2
   PUBLIC gERedova := 9 // extra redova
   PUBLIC gFaktPratitiKolicinuDN := "N"
   PUBLIC gPratiC := "N"
   PUBLIC gFZaok := 2
   PUBLIC gImeF := "N"
   PUBLIC gKomlin := ""
   PUBLIC gNumDio := 5
   PUBLIC gDetPromRj := "N"
   PUBLIC gVarC := " "
   PUBLIC gMP := "1"
   PUBLIC gTabela := 1
   PUBLIC gZagl := "2"
   PUBLIC gBold := "2"
   PUBLIC gRekTar := "N"
   PUBLIC gHLinija := "N"
   PUBLIC gRabProc := "D"

   // default MP cijena za 13-ku
   PUBLIC g13dcij := "1"
   PUBLIC gVar13 := "1"
   PUBLIC gFormatA5 := "0"
   PUBLIC gMreznoNum := "N"
   PUBLIC gIMenu := "3"
   PUBLIC gOdvT2 := 0
   PUBLIC gV12Por := "N"

   PUBLIC gVFU := "1"
   PUBLIC gModemVeza := "N"
   PUBLIC gFPZagA5 := 0
   PUBLIC gnTMarg2A5 := 3
   PUBLIC gnTMarg3A5 := -4
   PUBLIC gnTMarg4A5 := 0
   PUBLIC gVFRP0 := "N"

   PUBLIC gFNar := PadR( "NAR.TXT", 12 )
   PUBLIC gFUgRab := PadR( "UGRAB.TXT", 12 )

   PUBLIC gRabIzRobe := "N"

   PUBLIC gKarC1 := "N"
   PUBLIC gKarC2 := "N"
   PUBLIC gKarC3 := "N"
   PUBLIC gKarN1 := "N"
   PUBLIC gKarN2 := "N"
   PUBLIC gPSamoKol := "N"
   PUBLIC gcRabDef := Space( 10 )
   PUBLIC gcRabIDef := "1"
   PUBLIC gcRabDok := Space( 30 )

   PUBLIC gFaktPrikazFinSaldaKupacDobavljac := "N"
   PUBLIC gFinKtoDug := PadR( "2110", 7 )
   PUBLIC gFinKtoPot := PadR( "4320", 7 )
   PUBLIC gFaktPrikazFinSaldaKupacDobavljacVar := 1

   // roba group na fakturi
   PUBLIC glRGrPrn := "N"
   // brisanje dokumenta -> ide u smece
   PUBLIC gcF9USmece := "N"
   // time-out kod azuriranja
   PUBLIC gAzurTimeOut := 150

   // stmpa na traku
   PUBLIC gMpPrint := "N"
   PUBLIC gMPLocPort := "1"
   PUBLIC gMPRedTraka := "2"
   PUBLIC gMPArtikal := "D"
   PUBLIC gMPCjenPDV := "2"

   // zaokruzenje 5pf
   PUBLIC gZ_5pf := "N"

   PUBLIC zaokruzenje := 2
   PUBLIC i_id := 1
   PUBLIC nl := hb_eol()

   // firma naziv
   PUBLIC gFNaziv := Space( 250 )
   // firma dodatni opis

   PUBLIC gFPNaziv := Space( 250 )
   // firma adresa

   PUBLIC gFAdresa := Space( 35 )

   // firma id broj
   PUBLIC gFIdBroj := Space( 13 )

   // telefoni
   PUBLIC gFTelefon := Space( 72 )

   // web
   PUBLIC gFEmailWeb := Space( 72 )
   // banka 1

   PUBLIC gFBanka1 := Space( 50 )

   // banka 2
   PUBLIC gFBanka2 := Space( 50 )
   // banka 3
   PUBLIC gFBanka3 := Space( 50 )
   // banka 4
   PUBLIC gFBanka4 := Space( 50 )
   // banka 5
   PUBLIC gFBanka5 := Space( 50 )
   // proizv.text 1
   PUBLIC gFText1 := Space( 72 )
   // proizv.text 2
   PUBLIC gFText2 := Space( 72 )
   // proizv.text 3
   PUBLIC gFText3 := Space( 72 )
   // stampati zaglavlje
   PUBLIC gStZagl := "D"

   // picture header rows
   PUBLIC gFPicHRow := 0
   PUBLIC gFPicFRow := 0

   // citaj parametre sa db servera

   // parametri zaglavlja
   gFNaziv := fetch_metric( "org_naziv", NIL, gFNaziv )
   gFPNaziv := fetch_metric( "org_naziv_dodatno", NIL, gFPNaziv )
   gFAdresa := fetch_metric( "org_adresa", NIL, gFAdresa )
   gFIdBroj := fetch_metric( "org_pdv_broj", NIL, gFIdBroj )
   gFBanka1 := fetch_metric( "fakt_zagl_banka_1", NIL, gFBanka1 )
   gFBanka2 := fetch_metric( "fakt_zagl_banka_2", NIL, gFBanka2 )
   gFBanka3 := fetch_metric( "fakt_zagl_banka_3", NIL, gFBanka3 )
   gFBanka4 := fetch_metric( "fakt_zagl_banka_4", NIL, gFBanka4 )
   gFBanka5 := fetch_metric( "fakt_zagl_banka_5", NIL, gFBanka5 )
   gFTelefon := fetch_metric( "fakt_zagl_telefon", NIL, gFTelefon )
   gFEmailWeb := fetch_metric( "fakt_zagl_email", NIL, gFEmailWeb )
   gFText1 := fetch_metric( "fakt_zagl_dtxt_1", NIL, gFText1 )
   gFText2 := fetch_metric( "fakt_zagl_dtxt_2", NIL, gFText2 )
   gFText3 := fetch_metric( "fakt_zagl_dtxt_3", NIL, gFText3 )
   gStZagl := fetch_metric( "fakt_zagl_koristiti_txt", NIL, gStZagl )
   gFPicHRow := fetch_metric( "fakt_zagl_pic_header", NIL, gFPicHRow )
   gFPicFRow := fetch_metric( "fakt_zagl_pic_footer", NIL, gFPicFRow )

   // izgled dokumenta
   gDodPar := fetch_metric( "fakt_datum_placanja_otpremnica", NIL, gDoDPar )
   gDatVal := fetch_metric( "fakt_datum_placanja_svi_dokumenti", NIL, gDatVal )
   gNumDio := fetch_metric( "fakt_numericki_dio_dokumenta", NIL, gNumDio )
   gPSamoKol := fetch_metric( "fakt_prikaz_samo_kolicine", NIL, gPSamoKol )
   gcF9usmece := fetch_metric( "fakt_povrat_u_smece", NIL, gcF9usmece )
   gERedova := fetch_metric( "fakt_dokument_dodati_redovi_po_listu", NIL, gERedova )
   gnLMarg := fetch_metric( "fakt_dokument_lijeva_margina", NIL, gnLMarg )
   gnTMarg := fetch_metric( "fakt_dokument_top_margina", NIL, gnTMarg )
   gPDVDrb := fetch_metric( "fakt_dokument_delphirb_prikaz", NIL, gPDVDrb )
   gPDVDokVar := fetch_metric( "fakt_dokument_txt_prikaz_varijanta", NIL, gPDVDokVar )

   // obrada dokumenta
   glRGrPrn := fetch_metric( "fakt_ispis_grupacije_na_dokumentu", NIL, glRGrPrn )
   gFaktPrikazFinSaldaKupacDobavljac := fetch_metric( "fakt_ispis_salda_kupca_dobavljaca", NIL, gFaktPrikazFinSaldaKupacDobavljac )
   gFaktPrikazFinSaldaKupacDobavljacVar := fetch_metric( "fakt_ispis_salda_kupca_dobavljaca_varijanta", NIL, gFaktPrikazFinSaldaKupacDobavljacVar )
   gFinKtoDug := fetch_metric( "konto_duguje", NIL, gFinKtoDug )
   gFinKtoPot := fetch_metric( "konto_potrazuje", NIL, gFinKtoPot )
   // gSamoKol := fetch_metric( "fakt_voditi_samo_kolicine", nil, gSamoKol )

   //gResetRoba := fetch_metric( "fakt_reset_artikla_na_unosu", my_user(), gResetRoba )
   gIMenu := fetch_metric( "fakt_meni_tekuci", my_user(), gIMenu )

   // potpisi
   g10Str := fetch_metric( "fakt_dokument_dok_10_naziv", NIL, g10Str )
   g10Str2T := fetch_metric( "fakt_dokument_dok_10_potpis", NIL, g10Str2T )
   g10ftxt := fetch_metric( "fakt_dokument_dok_10_txt_lista", NIL, g10ftxt )
   g11Str := fetch_metric( "fakt_dokument_dok_11_naziv", NIL, g11Str )
   g11Str2T := fetch_metric( "fakt_dokument_dok_11_potpis", NIL, g11Str2T )
   g11ftxt := fetch_metric( "fakt_dokument_dok_11_txt_lista", NIL, g11ftxt )
   g12Str := fetch_metric( "fakt_dokument_dok_12_naziv", NIL, g12Str )
   g12Str2T := fetch_metric( "fakt_dokument_dok_12_potpis", NIL, g12Str2T )
   g12ftxt := fetch_metric( "fakt_dokument_dok_12_txt_lista", NIL, g12ftxt )
   g13Str := fetch_metric( "fakt_dokument_dok_13_naziv", NIL, g13Str )
   g13Str2T := fetch_metric( "fakt_dokument_dok_13_potpis", NIL, g13Str2T )
   g13ftxt := fetch_metric( "fakt_dokument_dok_13_txt_lista", NIL, g13ftxt )
   //g16Str := fetch_metric( "fakt_dokument_dok_16_naziv", NIL, g16Str )
   //g16Str2T := fetch_metric( "fakt_dokument_dok_16_potpis", NIL, g16Str2T )
   //g16ftxt := fetch_metric( "fakt_dokument_dok_16_txt_lista", NIL, g16ftxt )
   g20Str := fetch_metric( "fakt_dokument_dok_20_naziv", NIL, g20Str )
   g20Str2T := fetch_metric( "fakt_dokument_dok_20_potpis", NIL, g20Str2T )
   g20ftxt := fetch_metric( "fakt_dokument_dok_20_txt_lista", NIL, g20ftxt )
   g22Str := fetch_metric( "fakt_dokument_dok_22_naziv", NIL, g22Str )
   g22Str2T := fetch_metric( "fakt_dokument_dok_22_potpis", NIL, g22Str2T )
   g22ftxt := fetch_metric( "fakt_dokument_dok_22_txt_lista", NIL, g22ftxt )

   gFZaok := fetch_metric( "fakt_zaokruzenje", NIL, gFZaok )
   gZ_5pf := fetch_metric( "fakt_zaokruzenje_5_pf", NIL, gZ_5pf )

   // unos artikala na dokument pomocu barkod-a
   IF fetch_metric( "fakt_unos_artikala_po_barkodu", my_user(), "N" ) == "D"
      gDuzSifIni := "13"
   ENDIF

   o_params()

   PRIVATE cSection := "1"
   PUBLIC cHistory := " "
   PUBLIC aHistory := {}

   // varijanta cijene
   RPar( "50", @gVarC )
   // prvenstveno za win 95
   RPar( "95", @gKomLin )

   RPar( "cr", @gZnPrec )
   RPar( "d1", @gnTMarg2 )
   RPar( "d2", @gnTMarg3 )
   RPar( "d3", @gnTMarg4 )
   RPar( "dc", @g13dcij )
   // dodatni parametri fakture broj otpremnice itd
   RPar( "fp", @gFPzag )
   RPar( "if", @gImeF )
   // varijanta maloprodajne cijene
   RPar( "mp", @gMP )
   RPar( "PR", @gDetPromRj )
   Rpar( "NF", @gFNar )
   Rpar( "UF", @gFUgRab )
   Rpar( "rR", @gRabIzRobe )
   Rpar( "ds", @gnDS )
   Rpar( "ot", @gOdvT2 )
   RPar( "pk", @gFaktPratitiKolicinuDN )
   RPar( "pc", @gPratiC )
   RPar( "56", @gnLMargA5 )
   //RPar( "r3", @g06Str )
   RPar( "xl", @g15Str )
   //RPar( "r4", @g06Str2T )
   RPar( "xm", @g15Str2T )
   RPar( "uc", @gNazPotStr )
   RPar( "tb", @gTabela )
   RPar( "tf", @gTipF )
   RPar( "vf", @gVarF )
   RPar( "v0", @gVFRP0 )
   RPar( "kr", @gKriz )
   RPar( "55", @gKrizA5 )
   RPar( "51", @gFPzagA5 )
   RPar( "52", @gnTMarg2A5 )
   RPar( "53", @gnTMarg3A5 )
   RPar( "54", @gnTMarg4A5 )
   RPar( "vp", @gV12Por )
   RPar( "vu", @gVFU )
   RPar( "vr", @gVarRF )
   RPar( "vn", @gVarNum )
   RPar( "x9", @g21Str )
   RPar( "xa", @g21Str2T )
   RPar( "xC", @g23Str )
   RPar( "xD", @g23Str2T )
   RPar( "xf", @g25Str )
   RPar( "xg", @g25Str2T )
   RPar( "xi", @g26Str )
   RPar( "xj", @g26Str2T )
   RPar( "xo", @g27Str )
   RPar( "xp", @g27Str2T )

   // lista dodatni tekst
   RPar( "ye", @g15ftxt )
   RPar( "yh", @g21ftxt )
   RPar( "yI", @g23ftxt )
   RPar( "yj", @g25ftxt )
   RPar( "yk", @g26ftxt )
   RPar( "yl", @g27ftxt )

   // stmapa mp - traka
   RPar( "mP", @gMpPrint )
   RPar( "mL", @gMpLocPort )
   RPar( "mT", @gMpRedTraka )
   RPar( "mA", @gMpArtikal )
   RPar( "mC", @gMpCjenPDV )

   // dodatni parametri fakture broj otpremnice itd
   RPar( "za", @gZagl )
   RPar( "zb", @gbold )
   RPar( "RT", @gRekTar )
   RPar( "HL", @gHLinija )
   RPar( "rp", @gRabProc )
   RPar( "pd", @gProtu13 )
   RPar( "a5", @gFormatA5 )
   RPar( "g1", @gKarC1 )
   RPar( "g2", @gKarC2 )
   RPar( "g3", @gKarC3 )
   RPar( "g4", @gKarN1 )
   RPar( "g5", @gKarN2 )
   RPar( "rs", @gcRabDef )
   RPar( "ir", @gcRabIDef )
   RPar( "id", @gcRabDok )
   // RPar( "Fi", @gIspPart )
   // RPar( "Fz", @gAzurTimeOut )

   cSection := "1"

   IF ValType( gtabela ) <> "N"
      gTabela := 1
   ENDIF

   SELECT params
   USE

/*
   cSekcija := "SifRoba"
   cVar := "PitanjeOpis"
   my_get_from_ini ( cSekcija, cVar, my_get_from_ini( cSekcija, cVar, 'D' ), SIFPATH )
   cSekcija := "SifRoba"; cVar := "ID_J"
   my_get_from_ini ( cSekcija, cVar, my_get_from_ini( cSekcija, cVar, 'N' ), SIFPATH )
   cSekcija := "SifRoba"; cVar := "VPC2"
   my_get_from_ini ( cSekcija, cVar, my_get_from_ini( cSekcija, cVar, 'D' ), SIFPATH )
   cSekcija := "SifRoba"; cVar := "MPC2"
   my_get_from_ini ( cSekcija, cVar, my_get_from_ini( cSekcija, cVar, 'D' ), SIFPATH )
   cSekcija := "SifRoba"; cVar := "MPC3"
   my_get_from_ini ( cSekcija, cVar, my_get_from_ini( cSekcija, cVar, 'D' ), SIFPATH )
   cSekcija := "SifRoba"; cVar := "PrikId"
   my_get_from_ini ( cSekcija, cVar, my_get_from_ini( cSekcija, cVar, 'ID' ), SIFPATH )
   cSekcija := "SifRoba"; cVar := "DuzSifra"
   my_get_from_ini ( cSekcija, cVar, my_get_from_ini( cSekcija, cVar, '10' ), SIFPATH )

   cSekcija := "BarKod"; cVar := "Auto"
   my_get_from_ini ( cSekcija, cVar, my_get_from_ini( cSekcija, cVar, 'N' ), SIFPATH )
   cSekcija := "BarKod"; cVar := "AutoFormula"
   my_get_from_ini ( cSekcija, cVar, my_get_from_ini( cSekcija, cVar, 'ID' ), SIFPATH )
   cSekcija := "BarKod"; cVar := "Prefix"
   my_get_from_ini ( cSekcija, cVar, my_get_from_ini( cSekcija, cVar, '' ), SIFPATH )
   cSekcija := "BarKod"; cVar := "NazRTM"
   my_get_from_ini ( cSekcija, cVar, my_get_from_ini( cSekcija, cVar, 'barkod' ), SIFPATH )
*/

   PUBLIC gPovDob := "0"
   gModul := "FAKT"

   gPartnBlock := NIL
   PUBLIC glCij13Mpc := .T. //( my_get_from_ini( "FAKT", "Cijena13MPC", "D", KUMPATH ) == "D" )
   PUBLIC glRadNal := .F.
   PUBLIC gKonvZnWin
   gKonvZnWin := "3" //my_get_from_ini( "DelphiRB", "Konverzija", "3", EXEPATH )

   ::lOpcine := .F. //my_get_from_ini( "FAKT", "Opcine", "N", SIFPATH ) == "D"
   ::lDoks2 := .F. //my_get_from_ini( "FAKT", "Doks2", "N", KUMPATH ) == "D"
   ::lId_J := .F. //my_get_from_ini( "SifRoba", "ID_J", "N", SIFPATH ) == "D"
   ::lCRoba := .F. //( my_get_from_ini( 'CROBA', 'GledajFakt', 'N', KUMPATH ) == 'D' )
   ::cRoba_Rj := "10#20" //my_get_from_ini( 'CROBA', 'CROBA_RJ', '10#20', KUMPATH )

   param_racun_na_email( .T. )
   fakt_opis_stavke()
   destinacije()
   ref_lot()
   fakt_params( .T. )
   fiscal_opt_active()

   info_bar( "FAKT", "params in cache: " + AllTrim( Str( params_in_cache() ) ) )

   RETURN .T.


FUNCTION is_modul_fakt()

   RETURN gModul == "FAKT"


FUNCTION fakt_rok_placanja_dana()

   RETURN fetch_metric( "fakt_rok_placanja_tekuca_vrijednost", my_user(), 15 )
