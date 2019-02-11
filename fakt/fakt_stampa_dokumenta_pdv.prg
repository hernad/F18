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

THREAD STATIC __KTO_DUG
THREAD STATIC __KTO_POT
THREAD STATIC __SH_SLD_VAR


FUNCTION fakt_stdok_pdv( cIdFirma, cIdTipDok, cBrDok, lJFill )

   LOCAL cFax
   LOCAL lPrepisDok := .F.
   LOCAL hDok := hb_Hash(), hParamsFill := hb_Hash()
   LOCAL hFaktParams := fakt_params()
   LOCAL lSamoKol := .F.  // samo kolicine

   IF lJFill == NIL
      lJFill := .F.
   ENDIF

   IF PCount() == 4 .AND. ( cIdtipDok <> NIL ) // azurirani dokument fakt_fakt - alias FAKT_PRIPR
      lPrepisDok := .T.
      hParamsFill[ "from_server" ] := .T.
      close_open_fakt_tabele( .T. )
      seek_fakt( cIdFirma, cIdTipDok, cBrDok, NIL, NIL, NIL, NIL, "FAKT_PRIPR" )
   ELSE
      hParamsFill[ "from_server" ] := .F.
      close_open_fakt_tabele()
   ENDIF

   close_open_racun_tbl()
   zap_racun_tbl()

   SELECT fakt_pripr

   // barkod artikla
   PRIVATE lPBarkod := .F.

   IF hFaktParams[ "barkod" ] $ "12"  // pitanje, default "N"
      lPBarkod := ( Pitanje( , "Želite li ispis barkodova ?", iif( hFaktParams[ "barkod" ] == "1", "N", "D" ) ) == "D" )
   ENDIF

   IF PCount() == 0 .OR. ( cIdTipDok == NIL .AND. lJFill == .T. )
      cIdTipdok := field->idtipdok
      cIdFirma := field->IdFirma
      cBrDok := field->BrDok
   ENDIF

   SEEK cIdFirma + cIdTipDok + cBrDok // fakt_pripr
   NFOUND CRET

   IF PCount() <= 1 .OR. ( cIdTipDok == NIL .AND. lJFill == .T. )
      SELECT fakt_pripr
   ENDIF

   // napuni podatke za stampu
   hDok[ "idfirma" ] := field->IdFirma
   hDok[ "idtipdok" ] := field->IdTipDok
   hDok[ "brdok" ] := field->BrDok
   hDok[ "datdok" ] := field->DatDok

   cDocumentName := doc_name( hDok, fakt_pripr->IdPartner )

   // prikaz samo kolicine
   IF cIdTipDok $ "01#00#12#13#19#21#22#23#26"
      IF ( ( gPSamoKol == "0" .AND. Pitanje(, "Prikazati samo kolicine (D/N)", "N" ) == "D" ) ) ;
            .OR. gPSamoKol == "D"
         lSamoKol := .T.
      ENDIF
   ENDIF

   IF !( Val( podbr ) == 0 .AND. Val( rbr ) == 1 )
      Beep( 2 )
      Msg( "Prva stavka mora biti  '1.'  ili '1 ' !", 4 )
      RETURN .F.
   ENDIF

   hParamsFill[ "barkod" ] := lPBarkod
   hParamsFill[ "samo_kolicine" ] := lSamoKol

   IF !fill_porfakt_data( hDok, hParamsFill )
      RETURN .F.
   ENDIF

   IF lJFill
      RETURN .F.
   ENDIF

   my_close_all_dbf()

   IF cIdTipDok $ "13#23"
      // stampa 13-ke
      fakt_otpremnica_mp_13_print()
   ELSE

#ifdef F18_POS
      IF cIdTipDok == "11" .AND. gMPPrint $ "DXT"
         IF gMPPrint == "D" .OR. ( gMpPrint == "X" .AND. Pitanje(, "Stampati na traku (D/N)?", "D" ) == "D" ) .OR. gMPPrint == "T"

            // stampa na traku
            gLocPort := "LPT" + AllTrim( gMpLocPort )

            lStartPrint := .T.

            cPrn := gPrinter
            gPrinter := "0"

            IF gMPPrint == "T"
               // test mode
               gPrinter := "R"
            ENDIF

            st_rb_traka( lStartPrint, lPrepisDok )

            gPrinter := cPrn

         ELSE
            pf_a4_print( NIL, cDocumentName )
         ENDIF

      ELSE
         pf_a4_print( NIL, cDocumentName )
      ENDIF

#else
      pf_a4_print( NIL, cDocumentName )
#endif

   ENDIF
   my_close_all_dbf()

   RETURN .T.


// ----------------------------------------------------------------------
// puni  pomocne tabele rn drn
// ----------------------------------------------------------------------
STATIC FUNCTION fill_porfakt_data( hDokument, hFillParams )

   LOCAL cTxt1, cTxt2, cTxt3, cTxt4, cTxt5
   LOCAL cIdPartner
   LOCAL dDatDok

   // LOCAL cDestinacija
   LOCAL dDatVal
   LOCAL dDatumIsporuke
   // LOCAL aMemo

   LOCAL cIdRoba := ""
   LOCAL cRobaNaz := ""
   LOCAL cRbr := ""
   LOCAL cPodBr := ""
   LOCAL cJmj := ""
   LOCAL i
   LOCAL nTmp
   LOCAL nKol := 0
   LOCAL nCjPDV := 0
   LOCAL nCjBPDV := 0
   LOCAL nPopust := 0 // proc popusta
   LOCAL nPopNaTeretProdavca := 0
   LOCAL nVPDV := 0
   LOCAL nCj2PDV := 0
   LOCAL nCj2BPDV := 0
   LOCAL nPPDV := 0
   LOCAL nRCijen := 0
   LOCAL nCSum := 0
   LOCAL nTotal := 0
   LOCAL nUkBPDV := 0
   LOCAL nUkBPDVPop := 0
   LOCAL nUkVPop := 0
   LOCAL nVPopust := 0
   LOCAL nVPopNaTeretProdavca := 0
   LOCAL nUkPDV := 0
   LOCAL nUkPopNaTeretProdavca := 0
   LOCAL cTime := ""
   LOCAL cDinDem
   LOCAL nRec1zapis
   LOCAL nZaokr
   LOCAL nFZaokr := 0
   LOCAL nDrnZaokr := 0
   LOCAL cDokNaz
   LOCAL nUkKol := 0
   LOCAL lIno := .F.
   LOCAL cPdvOslobadjanje := ""
   LOCAL nPom1
   LOCAL nPom2
   LOCAL nPom3
   LOCAL nPom4
   LOCAL nPom5
   LOCAL cOpis := ""
   LOCAL _a_tmp, _tmp
   LOCAL lPdvObveznik := .F.
   LOCAL nDx1 := 0
   LOCAL nDx2 := 0
   LOCAL nDx3 := 0
   LOCAL nSw1 := 72
   LOCAL nSw2 := 1
   LOCAL nSw3 := 72
   LOCAL nSw4 := 31
   LOCAL nSw5 := 1
   LOCAL nSw6 := 1
   LOCAL nSw7 := 0
   LOCAL aDokumentVeze

   LOCAL hFaktParams := fakt_params()
   LOCAL hFaktTxt

   // radi citanja parametara
   PRIVATE cSection := "F"
   PRIVATE cHistory := " "
   PRIVATE aHistory := {}

   SELECT F_PARAMS
   IF !Used()
      o_params()
   ENDIF
   RPar( "x1", @nDx1 )
   RPar( "x2", @nDx2 )
   RPar( "x3", @nDx3 )

   RPar( "x4", @nSw1 )
   RPar( "x5", @nSw2 )
   RPar( "x6", @nSw3 )
   RPar( "x7", @nSw4 )
   // ovaj switch se koristi za poziv ptxt-a ... u principu
   // ovdje mi i ne treba
   RPar( "x8", @nSw5 )
   // narudzbenice - samo kolicine 0, cijene 1
   RPar( "x9", @nSw6 )
   RPar( "y1", @nSw7 )

   // napuni firmine podatke
   fill_firm_data()


   // select_o_roba()

   SELECT fakt_pripr

   // napuni podatke partnera

   lPdvObveznik := is_pdv_obveznik( field->idpartner )
   porezna_faktura_fill_partner_data( field->idpartner, @lPdvObveznik )

   // popuni ostale podatke, radni nalog i slicno
   porezna_faktura_fill_ostali_podaci()

   SELECT fakt_pripr

   // vrati naziv dokumenta
   fakt_get_dok_naziv( @cDokNaz, field->idtipdok, field->idvrstep, hFillParams[ "samo_kolicine" ] )

   SELECT fakt_pripr

   dDatDok := hDokument[ "datdok" ]

   dDatVal := dDatDok
   dDatumIsporuke := dDatDok
   cDinDem := dindem

   nRec1zapis := RecNo()

   // ukupna kolicina
   nUkKol := 0

   DEC_CIJENA( ZAO_CIJENA() )
   DEC_VRIJEDNOST( ZAO_VRIJEDNOST() )

   lIno := .F.
   DO WHILE !Eof() .AND. field->idfirma == hDokument[ "idfirma" ] .AND. field->idtipdok == hDokument[ "idtipdok" ] .AND. ;
         field->brdok == hDokument[ "brdok" ]


      IF !select_o_roba( fakt_pripr->idroba )
         Msgbeep( "Artikal " + fakt_pripr->idroba + " ne postoji u šifarniku !?" )
         RETURN .F.
      ENDIF

      IF !select_o_tarifa( roba->idtarifa )
         MsgBeep( "Tarifa " + roba->idtarifa + " ne postoji u šifaniku !?" )
         RETURN .F.
      ENDIF

      SELECT fakt_pripr

      hFaktTxt := fakt_ftxt_decode_string( field->txt )
      cIdRoba := field->idroba

      IF roba->tip == "U" // usluge su pohranjene u fakt->txt sekcija txt1
         cRobaNaz := hFaktTxt[ "opis_usluga" ]
      ELSE
         cRobaNaz := AllTrim( roba->naz )
         IF hFillParams[ "barkod" ]
            cRobaNaz := cRobaNaz + " (BK: " + roba->barkod + ")"
         ENDIF
      ENDIF

      // ako je roba grupa:
      IF glRGrPrn == "D"
         cPom := roba_sifk_opis_grupe( roba->id, "GR1" ) + ": " + _val_gr( roba->id, "GR1" ) + ;
            ", " + roba_sifk_opis_grupe( roba->id, "GR2" ) + ": " + _val_gr( roba->id, "GR2" )

         cRobaNaz += " "
         cRobaNaz += cPom
         SELECT fakt_pripr
      ENDIF


      IF !Empty( AllTrim( fakt_pripr->serbr ) )   // dodaj i vrijednost iz polja SERBR
         cRobaNaz := cRobaNaz + ", " + AllTrim( fakt_pripr->serbr )
      ENDIF

      // resetuj varijable sa cijenama
      nCjPDV := 0
      nCj2PDV := 0
      nCjBPDV := 0
      nCj2BPDV := 0
      nVPopust := 0
      nPPDV := 0

      cRbr := field->rbr
      cPodBr := field->podbr
      cJmj := roba->jmj

      // procenat pdv-a
      nPPDV := tarifa->pdv

      cIdPartner := field->idpartner

      IF Year( field->datdok ) > 2001 .AND. Empty( cIdPartner )  // podrska za godine <=2001
         MsgBeep( "Partner na fakturi - prazno - nesto nije ok !?" )
         RETURN .F.
      ENDIF

      IF hFaktParams[ "fakt_opis_stavke" ]
         hDokument[ "rbr" ] := rbr
         cOpis := get_fakt_attr_opis( hDokument, hFillParams[ "from_server" ] )
         SELECT fakt_pripr
      ELSE
         cOpis := ""
      ENDIF

      // rn Veleprodaje
      IF hDokument[ "idtipdok" ] $ "10#11#12#13#20#22#25"

         IF partner_is_ino( cIdPartner )
            nPPDV := 0
            lIno := .T.
         ENDIF

         // ako je po nekom clanu PDV-a partner oslobodjenj
         // placanja PDV-a
         cPdvOslobadjanje := pdv_oslobodjen( cIdPartner )
         IF !Empty( cPdvOslobadjanje )
            nPPDV := 0
         ENDIF

      ENDIF

      // IF hDokument[ "idtipdok" ] == "12"
      // IF IsProfil( cIdPartner, "KMS" )  // radi se o komisionaru
      // nPPDV := 0
      // ENDIF
      // ENDIF

      // kolicina
      nKol := field->kolicina
      nRCijen := field->cijena

      IF Left( fakt_pripr->DINDEM, 3 ) <> Left( ValBazna(), 3 )
         // preracunaj u EUR
         // omjer EUR / KM
         nRCijen := nRCijen / OmjerVal( ValBazna(), fakt_pripr->DINDEM, fakt_pripr->datdok )
         nRCijen := Round( nRCijen, DEC_CIJENA() )
      ENDIF

      // resetuj prije eventualnog setovanja
      nPopNaTeretProdavca := 0

      // zasticena cijena, za krajnjeg kupca
      IF RobaZastCijena( tarifa->id )  .AND. !lPdvObveznik
         // krajnji potrosac
         // roba sa zasticenom cijenom
         nPopNaTeretProdavca := field->rabat
         nPopust := 0
      ELSE
         // rabat - popust
         nPopust := field->rabat
         nPopNaTeretProdavca := 0
      ENDIF

      // ako je 13-ka ili 27-ca
      // cijena bez pdv se utvrdjuje unazad
      IF ( field->idtipdok == "13" .AND. glCij13Mpc ) .OR. ( field->idtipdok $ "11#27" .AND. gMP $ "1234567" )
         // cjena bez pdv-a
         nCjPDV := nRCijen
         nCjBPDV := ( nRCijen / ( 1 + nPPDV / 100 ) )
      ELSE
         // cjena bez pdv-a
         nCjBPDV := nRCijen
         nCjPDV := ( nRCijen * ( 1 + nPPDV / 100 ) )
      ENDIF

      nVPopust := 0

      // izracunaj vrijednost popusta
      IF Round( nPopust, 4 ) <> 0
         // vrijednost popusta
         nVPopust := ( nCjBPDV * ( nPopust / 100 ) )
      ENDIF

      // resetuj prije eventualnog setovanja
      nVPopNaTeretProdavca := 0

      // izacunaj vrijednost popusta na teret prodavca
      IF Round( nPopNaTeretProdavca, 4 ) <> 0
         nVPopNaTeretProdavca := ( nCjBPDV * ( nPopNaTeretProdavca / 100 ) ) // vrijednost popusta
      ENDIF

      nCj2BPDV := ( nCjBPDV - nVPopust ) // cijena sa popustom bez pdv-a
      nCj2PDV := ( nCj2BPDV * ( 1 + nPPDV / 100 ) )   // izracuna PDV na cijenu sa popustom

      // ukupno stavka
      nUkStavka := nKol * nCj2PDV
      nUkStavke := Round( nUkStavka, ZAO_VRIJEDNOST() + iif( field->idtipdok $ "11#13", 4, 0 ) )

      nPom1 := nKol * nCjBPDV
      nPom1 := Round( nPom1, ZAO_VRIJEDNOST() + iif( field->idtipdok $ "11#13", 4, 0 ) )
      // ukupno bez pdv
      nUkBPDV += nPom1


      // ukupno popusta za stavku
      nPom2 := nKol * nVPopust
      nPom2 := Round( nPom2, ZAO_VRIJEDNOST() + iif( idtipdok $ "11#13", 4, 0 ) )
      nUkVPop += nPom2

      // preracunaj VPDV sa popustom
      nVPDV := ( nCj2BPDV * ( nPPDV / 100 ) )


      // ukupno vrijednost bez pdva sa uracunatim poputstom
      nPom3 := nPom1 - nPom2
      nPom3 := Round( nPom3, ZAO_VRIJEDNOST() + iif( idtipdok $ "11#13", 4, 0 ) )
      nUkBPDVPop += nPom3


      // ukupno PDV za stavku = (ukupno bez pdv - ukupno popust) * stopa
      nPom4 := nPom3 * nPPDV / 100
      // povecaj preciznost
      nPom4 := Round( nPom4, ZAO_VRIJEDNOST() + iif( idtipdok $ "11#13", 4, 2 ) )
      nUkPDV += nPom4

      // ukupno za stavku sa pdv-om
      nTotal +=  nPom3 + nPom4

      nPom5 := nKol * nVPopNaTeretProdavca
      nPom5 := Round( nPom5, ZAO_VRIJEDNOST() )
      nUkPopNaTeretProdavca += nPom5

      ++nCSum

      nUkKol += nKol

      dodaj_stavku_racuna( hDokument[ "brdok" ], cRbr, cPodBr, cIdRoba, cRobaNaz, cJmj, nKol, ;
         nCjPDV, nCjBPDV, nCj2PDV, nCj2BPDV, nPopust, ;
         nPPDV, nVPDV, nUkStavka, nPopNaTeretProdavca, nVPopNaTeretProdavca, "", "", "", cOpis )

      SELECT fakt_pripr
      SKIP

   ENDDO

   nUkPDV := Round( nUkPDV, ZAO_VRIJEDNOST() )    // zaokruzi pdv na zao_vrijednost()

   nTotal := ( nUkBPDVPop + nUkPDV )

   nFZaokr := zaokr_5pf( nTotal )
   IF gZ_5pf == "N"
      nFZaokr := 0
   ENDIF


   IF ( gFZaok <> 9 .AND. Round( nFZaokr, 4 ) <> 0 )
      nDrnZaokr := nFZaokr
   ENDIF

   nTotal := Round( nTotal - nDrnZaokr, ZAO_VRIJEDNOST() )

   nUkPopNaTeretProdavca := Round( nUkPopNaTeretProdavca, ZAO_VRIJEDNOST() )
   nUkBPDV := Round( nUkBPDV, ZAO_VRIJEDNOST() )
   nUkVPop := Round( nUkVPop, ZAO_VRIJEDNOST() )

   SELECT fakt_pripr
   GO ( nRec1zapis )

   // nafiluj ostale podatke vazne za sam dokument
   // aMemo := fakt_ftxt_decode( fakt_pripr->txt )
   hFaktTxt := fakt_ftxt_decode_string( fakt_pripr->txt )

   dDatDok := fakt_pripr->datdok
   dDatumIsporuke := hFaktTxt[ "datotp" ]
   dDatVal := hFaktTxt[ "datpl" ]

/*
IF hb_HHasKey( hFaktTxt, "brnar")
   //IF Len( aMemo ) <= 5
      dDatVal := dDatDok
      dDatumIsporuke := dDatDok
      cBrOtpr := ""
      cBrNar  := ""
   ELSE
      //dDatVal := CToD( aMemo[ 9 ] )
      //dDatumIsporuke := CToD( aMemo[ 7 ] )
      //cBrOtpr := aMemo[ 6 ]
      //cBrNar  := aMemo[ 8 ]
      dDatVal := hFaktTxt[ "datpl"]
      dDatumIsporuke :=
   ENDIF


   // destinacija na fakturi
   IF Len( aMemo ) >= 18
      cDestinacija := aMemo[ 18 ]
   ELSE
      cDestinacija := ""
   ENDIF

   // dokument_veza
   IF Len( aMemo ) >= 19
      cM_d_veza := aMemo[ 19 ]
   ELSE
      cM_d_veza := ""
   ENDIF

   IF Len( aMemo ) >= 20
      cObjekti := aMemo[ 20 ]
   ELSE
      cObjekti := ""
   ENDIF
*/


   add_drntext( "D01", gMjStr )    // mjesto
   add_drntext( "D02", cDokNaz )    // naziv dokumenta

   add_drntext( "D04", Slovima( nTotal - nUkPopNaTeretProdavca, cDinDem ) )  // slovima iznos fakture
   add_drntext( "D05", hFaktTxt[ "brotp" ] )    // broj otpremnice
   add_drntext( "D06", hFaktTxt[ "brnar" ] )    // broj narudzbenice
   add_drntext( "D07", cDinDem )    // DM/EURO
   add_drntext( "D08", hFaktTxt[ "destinacija" ] )    // Destinacija

   // objekakt
   IF !Empty( hFaktTxt[ "objekti" ] )
      add_drntext( "O01", hFaktTxt[ "objekti" ] )
      add_drntext( "O02", fakt_objekat_naz( hFaktTxt[ "objekti" ] ) )
   ENDIF

   // tip dokumenta
   add_drntext( "D09", hDokument[ "idtipdok" ] )

   // radna jedinica
   add_drntext( "D10", hDokument[ "idfirma" ] )


   aDokumentVeze := SjeciStr( hFaktTxt[ "dokument_veza" ], 200 )
   nTmp := 30

   // koliko ima redova
   add_drntext( "D30", AllTrim( Str( Len( aDokumentVeze ) ) ) )
   FOR i := 1 TO Len( aDokumentVeze )
      add_drntext( "D" + AllTrim( Str( nTmp + i ) ), aDokumentVeze[ i ] )
   NEXT

   // tekst na kraju fakture F04, F05, F06
   porezna_faktura_dodatni_tekst( hFaktTxt[ "txt2" ], fakt_pripr->idpartner )


   fill_potpis( hDokument[ "idtipdok" ] )  // potpis na kraju

   // parametri generalni za stampu dokuemnta
   // lijeva margina
   add_drntext( "P01", AllTrim( Str( gnLMarg ) ) )

   // zaglavlje na svakoj stranici
   add_drntext( "P04", iif( gZagl == "1", "D", "N" ) )

   // prikaz dodatnih podataka
   add_drntext( "P05", iif( gDodPar == "1", "D", "N" ) )
   // dodati redovi po listu

   add_drntext( "P06", AllTrim( Str( gERedova ) ) )

   // gornja margina
   add_drntext( "P07", AllTrim( Str( gnTMarg ) ) )

   // da li se formira automatsko zaglavlje
   add_drntext( "P10", gStZagl )

   DO CASE

   CASE lIno
      // ino faktura
      add_drntext( "P11", "INO" )

   CASE !Empty( cPdvOslobadjanje )
      add_drntext( "P11", cPdvOslobadjanje )

   OTHERWISE
      // domaca faktura
      add_drntext( "P11", "DOMACA" )

   ENDCASE

   // redova iznad "kupac"
   add_drntext( "X01", Str( nDx1, 2, 0 ) )
   // redova ispod "kupac"
   add_drntext( "X02", Str( nDx2, 2, 0 ) )
   // redova izmedju broja narudbze i tabele
   add_drntext( "X03", Str( nDx3, 2, 0 ) )

   add_drntext( "X04", Str( nSw1, 2, 0 ) )
   add_drntext( "X05", Str( nSw2, 2, 0 ) )
   add_drntext( "X06", Str( nSw3, 2, 0 ) )
   add_drntext( "X07", Str( nSw4, 2, 0 ) )
   add_drntext( "X08", Str( nSw5, 2, 0 ) )
   add_drntext( "X09", Str( nSw6, 1, 0 ) )
   add_drntext( "X10", Str( nSw7, 1, 0 ) )

   // header i footer - broj redova
   // IF gPDFPrint == "D"
   // add_drntext( "X11", Str( gFPicHRow, 2, 0 ) )
   // add_drntext( "X12", Str( gFPicFRow, 1, 0 ) )
   // ELSE
   // ako nije pdf stampa - nema parametara....
   add_drntext( "X11", Str( 0 ) )
   add_drntext( "X12", Str( 0 ) )
   // ENDIF


   gPtxtC50 := .F. // fakturu stampaj u ne-compatibility modu
   DO CASE
   CASE nSw5 == 0
      gPtxtSw := "/noline /s /l /p"
   CASE nSw5 == 1
      gPtxtSw := "/p"

   OTHERWISE
      gPtxtSw := NIL // citaj ini fajl
   ENDCASE

   // dodaj total u DRN
   add_drn( hDokument[ "brdok" ], hDokument[ "datdok" ], dDatVal, dDatumIsporuke, cTime, ;
      nUkBPDV, nUkVPop, nUkBPDVPop, nUkPDV, nTotal, ;
      nCSum, nUkPopNaTeretProdavca, nDrnZaokr, nUkKol )

   IF ( hDokument[ "idtipdok" ] $ "10#11" ) .AND. Round( nUkPDV, 2 ) == 0
      IF Pitanje(, "Faktura je bez iznosa PDV-a! Da li je to u redu (D/N)", "D" ) == "N"
         RETURN .F.
      ENDIF
   ENDIF

   RETURN .T.



STATIC FUNCTION roba_sifk_opis_grupe( cId, cSifK )

   LOCAL nTArea := Select()
   LOCAL cRet := ""

   o_sifk( "ROBA" )
   SELECT sifk
   SET ORDER TO TAG "ID2"
   GO TOP
   SEEK PadR( "ROBA", 8 ) + PadR( cSifK, 4 )

   IF Found()
      cRet := AllTrim( field->naz )
   ENDIF

   SELECT ( nTArea )

   RETURN cRet


// -------------------------------------
// vraca vrijednost grupe iz sifK
// -------------------------------------
STATIC FUNCTION _val_gr( cId, cSifK )

   LOCAL cRet := ""

   cRet := IzSifKRoba( cSifK, cId, .F. )
   IF cRet == nil
      cRet := ""
   ENDIF

   RETURN AllTrim( cRet )



STATIC FUNCTION fill_potpis( cIdVD )

   LOCAL cPom
   LOCAL cPotpis

   IF ( cIdVd $ "01#00" )
      cPotpis := Replicate( " ", 12 ) + "Odobrio" + Replicate( " ", 25 ) + "Primio"

   ELSEIF cIdVd $ "19"
      cPotpis := Replicate( " ", 12 ) + "Odobrio" + Replicate( " ", 25 ) + "Predao"
   ELSE
      cPom := "G" + cIdVD + "STR2T"
      cPotpis := &cPom
   ENDIF

   add_drntext( "F10", cPotpis )  // potpis

   RETURN .T.



STATIC FUNCTION porezna_faktura_fill_ostali_podaci()

   LOCAL cPom

   // broj fiskalnog isjecka
   add_drntext( "O10", fisc_isjecak( fakt_pripr->idfirma, fakt_pripr->idtipdok, ;
      fakt_pripr->brdok ) )

   // traka - ispis, cjene bez pdv, sa pdv (1) bez pdv, (2) sa pdv
   cPom := gMPCjenPDV
   add_drntext( "P20", cPom )

   // stampa id roba na racunu D/N
   cPom := gMPArtikal
   add_drntext( "P21", cPom )

   // redukcija trake 0/1/2
   cPom := gMpRedTraka
   add_drntext( "P22", cPom )

   // ispis kupca na racunu
   cPom := "D"
   add_drntext( "P23", cPom )

   // mjesto
   cPom := gMjStr
   add_drntext( "R01", cPom )

   IF gSecurity == "D"
      // naziv operatera
      cPom := getfullusername( f18_get_user_id() )
      add_drntext( "R02", cPom )
   ENDIF

   // smjena
   cPom := "1"
   add_drntext( "R03", cPom )

   // vrsta placanja
   cPom := "GOTOVINA"
   add_drntext( "R05", cPom )

   // dodatni tekst racuna
   cPom := ""
   add_drntext( "R06", cPom )
   add_drntext( "R07", cPom )
   add_drntext( "R08", cPom )

   // broj linija za odcjep.trake
   cPom := "8"
   add_drntext( "P12", cPom )

   // sekv.otvaranje ladice
   cPom := ""
   add_drntext( "P13", cPom )

   // sekv.cjepanje trake
   cPom := ""
   add_drntext( "P14", cPom )

   // prodajno mjesto
   cPom := "prod. 1"
   add_drntext( "I04", cPom )

   RETURN .T.


// --------------------------------------------------------------
// daj naziv dokumenta iz parametara
// --------------------------------------------------------------
FUNCTION fakt_get_dok_naziv( cNaz, cIdVd, cVP, lSamoKol )

   LOCAL cPom
   LOCAL cSamoKol

   IF ( cIdVd == "01" )
      cNaz := "Prijem robe u magacin br."
   ELSEIF ( cIdVd == "00" )
      cNaz := "Pocetno stanje br."
   ELSEIF ( cIdVD == "19" )
      cNaz := "Izlaz po ostalim osnovama br."
   ELSEIF ( cIdVD == "10" .AND. cVP == "AV" )
      cNaz := "Avansna faktura br."
   ELSE
      cPom := "G" + cIdVd + "STR"
      cNaz := &cPom
   ENDIF

   // ako je lSamoKol := .t. onda je prikaz samo kolicina
   cSamoKol := "N"
   IF lSamoKol
      cSamoKol := "D"
   ENDIF

   add_drntext( "P03", cSamoKol )

   RETURN .T.




STATIC FUNCTION set_partner_id_broj( cId )

   LOCAL cBroj := ""
   LOCAL cIdBroj := firma_id_broj( cId )
   LOCAL cPdvBroj := firma_pdv_broj( cId )

   cBroj += cIdBroj

   IF !Empty( cPdvBroj )
      cBroj += " PDV broj: " + cPdvBroj
   ENDIF

   RETURN cBroj


STATIC FUNCTION porezna_faktura_fill_partner_data( cId, lPdvObveznik )

   LOCAL cIdBroj := ""
   LOCAL cPdvBroj := ""
   LOCAL cPorBroj := ""
   LOCAL cBrRjes := ""
   LOCAL cBrUpisa := ""
   LOCAL cPartNaziv := ""
   LOCAL cPartAdres := ""
   LOCAL cPartMjesto := ""
   LOCAL cPartTel := ""
   LOCAL cPartFax := ""
   LOCAL cPartPTT := ""
   LOCAL aMemo := {}
   LOCAL lFromMemo := .F.
   LOCAL nDbfArea := Select()

   IF Empty( AllTrim( cId ) )
      // ako je prazan partner uzmi iz memo polja
      aMemo := fakt_ftxt_decode( fakt_pripr->txt )
      lFromMemo := .T.
   ELSE
      select_o_partner( cId )
   ENDIF

   IF !lFromMemo .AND. partn->id == cId

      cIdBroj := firma_id_broj( cId )
      cPdvBroj := firma_pdv_broj( cId )

      // cPorBroj := get_partn_sifk_sifv( "PORB", cId, .F. )

/*
      cBrRjes := get_partn_sifk_sifv( "BRJS", cId, .F. )
      cBrUpisa := get_partn_sifk_sifv( "BRUP", cId, .F. )
*/
      cPartNaziv := partn->naz
      cPartAdres := partn->adresa
      cPartMjesto := partn->mjesto
      cPartPtt := partn->ptt
      cPartTel := partn->telefon
      cPartFax := partn->fax
   ELSE
      IF Len( aMemo ) == 0
         cPartNaziv := ""
         cPartAdres := ""
         cPartMjesto := ""
      ELSE
         cPartNaziv := aMemo[ 3 ]
         cPartAdres := aMemo[ 4 ]
         cPartMjesto := aMemo[ 5 ]
      ENDIF
   ENDIF

   // naziv
   add_drntext( "K01", cPartNaziv )
   // adresa
   add_drntext( "K02", cPartAdres )
   // mjesto
   add_drntext( "K10", cPartMjesto )
   // ptt
   add_drntext( "K11", cPartPTT )

   // idbroj staro polje, koje sadrži i id i pdv broj
   add_drntext( "K03", set_partner_id_broj( cId ) )

   // idbroj, pdvbroj, nova polja
   add_drntext( "K15", cIdBroj )
   add_drntext( "K16", cPdvBroj )


   // porbroj - OUT
   // add_drntext( "K05", cPorBroj )

   // tel
   add_drntext( "K13", cPartTel )
   // fax
   add_drntext( "K14", cPartFax )

/*
   IF cBrRjes != NIL
      add_drntext( "K06", cBrRjes )
   ENDIF

   IF cBrUpisa != NIL
      add_drntext( "K07", cBrUpisa )
   ENDIF
*/

   SELECT ( nDbfArea )

   RETURN .T.


STATIC FUNCTION fill_firm_data()

   LOCAL i
   LOCAL cBanke
   LOCAL cPom
   LOCAL lPrazno
   LOCAL nDbfArea := Select()

   // opci podaci
   add_drntext( "I01", gFNaziv )
   add_drntext( "I20", gFPNaziv )
   add_drntext( "I02", gFAdresa )
   add_drntext( "I03", gFIdBroj )
   // 4. se koristi za id prod.mjesto u pos
   // telefon pos = I05
   add_drntext( "I05", AllTrim( gFTelefon ) )
   add_drntext( "I10", AllTrim( gFTelefon ) )
   add_drntext( "I11", AllTrim( gFEmailWeb ) )

   // banke
   cBanke := ""
   lPrazno := .T.

   FOR i := 1 TO 5
      IF i == 1
         cPom := AllTrim( gFBanka1 )
      ELSEIF i == 2
         cPom := AllTrim( gFBanka2 )
      ELSEIF i == 3
         cPom := AllTrim( gFBanka3 )
      ELSEIF i == 4
         cPom := AllTrim( gFBanka4 )
      ELSEIF i == 5
         cPom := AllTrim( gFBanka5 )
      ENDIF
      IF !Empty( cPom )
         IF !lPrazno
            cBanke += ", "
         ENDIF
         cBanke += cPom
         lPrazno := .F.
      ENDIF
   NEXT


   add_drntext( "I09", cBanke )

   // dodatni redovi
   add_drntext( "I12", AllTrim( gFText1 ) )
   add_drntext( "I13", AllTrim( gFText2 ) )
   add_drntext( "I14", AllTrim( gFText3 ) )

   SELECT ( nDbfArea )

   RETURN


// ------------------------------------
// ------------------------------------
FUNCTION ZAO_VRIJEDNOST()

   LOCAL nPos
   LOCAL nLen

   // 999.99
   nPos := At( ".", fakt_pic_iznos() )
   // = 4
   nLen := Len( fakt_pic_iznos() )
   // = 6

   IF nPos == 0
      nPos := nLen
   ENDIF

   RETURN nLen - nPos


// ------------------------------------
// ------------------------------------
FUNCTION ZAO_CIJENA()

   LOCAL nPos
   LOCAL nLen

   // 999.99
   nPos := At( ".", fakt_pic_cijena() )
   // = 4
   nLen := Len( fakt_pic_iznos() )
   // = 6

   IF nPos == 0
      nPos := nLen
   ENDIF

   RETURN nLen - nPos


// -------------------------------------------
// cDocName
// -------------------------------------------
STATIC FUNCTION doc_name( hDokument, cIdPartner )

   LOCAL cFax
   LOCAL cPartner
   LOCAL cDocumentName

   // primjer cDocumentName = FAKT_DOK_10-10-00050_planika-flex-sarajevo_29.05.06_FAX:032440173
   cDocumentName := gModul + "_DOK_" + hDokument[ "idfirma" ]  + "-" + hDokument[ "idtipdok" ] + "-" + Trim( hDokument[ "brdok" ] ) + "-" + Trim( cIdPartner ) + "_" + DToC( DatDok )

   cPartner := AllTrim( get_partner_name_mjesto( cIdPartner ) )

   cPartner := StrTran( cPartner, " ", "-" )
   cPartner := StrTran( cPartner, '"', "" )
   cPartner := StrTran( cPartner, "'", "" )
   cPartner := StrTran( cPartner, '/', "-" )

   cDocumentName += "_" + cPartner

   // 032/440-170 => 032440170
   cFax := StrTran( g_part_fax( cIdPartner ), "-", "" )
   cFax := StrTran( cFax, "/", "" )
   cFax := StrTran( cFax, " ", "" )

   cDocumentName += "_FAX-" + cFax

   cDocumentName := KonvZnWin( cDocumentName, "4" )

   RETURN cDocumentName
