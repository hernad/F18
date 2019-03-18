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

MEMVAR cSection, cHistory, aHistory, izbor, opc, opcexe, gAImpPrint
MEMVAR GetList, m_x, m_y
MEMVAR cExpPath, cImpFile

STATIC __stampaj // stampanje dokumenata .t. or .f.
// STATIC s_lAutom := .T. // Automatski asistent i ažuriranje naloga (D/N)

FUNCTION meni_import_vindija()

   PRIVATE izbor := 1
   PRIVATE opc := {}
   PRIVATE opcexe := {}

   __stampaj := .F.

   IF gAImpPrint == "D"
      __stampaj := .T.
   ENDIF

   AAdd( opc, "1. import vindija računi                 " )
   AAdd( opcexe, {|| kalk_auto_import_racuni() } )
   AAdd( opc, "2. import vindija partner" )
   AAdd( opcexe, {|| kalk_import_txt_partner() } )
   AAdd( opc, "3. import vindija roba" )
   AAdd( opcexe, {|| kalk_import_txt_roba() } )
   // AAdd( opc, "4. popuna polja šifra dobavljača " )
   // AAdd( opcexe, {|| FillDobSifra() } )
   AAdd( opc, "5. nastavak obrade dokumenata " )
   AAdd( opcexe, {|| kalk_imp_continue_from_check_point() } )
   AAdd( opc, "6. podešenja importa " )
   AAdd( opcexe, {|| kalk_auto_import_setup() } )

   AAdd( opc, "P. parametri kontiranja poslovnica" )
   AAdd( opcexe, {|| set_kalk_imp_parametri_za_poslovnica() } )
   AAdd( opc, "R. parametri kontiranja prodavnica" )
   AAdd( opcexe, {|| kalk_imp_set_konto_zaduz_prodavnica_za_prod_mjesto() } )

   dbf_refresh_stop()

   f18_menu_sa_priv_vars_opc_opcexe_izbor( "itx" )

   dbf_refresh_start()

   RETURN .T.



FUNCTION kalk_auto_import_racuni()

   // LOCAL cCtrl_art := "N"
   PRIVATE cExpPath
   PRIVATE cImpFile

   cre_kalk_priprt()

   cExpPath := get_liste_za_import_path()

   cFFilt := kalk_get_vp_ili_mp() // filter za import MP ili VP

   // IF prag_odstupanja_nc_sumnjiv() > 0 .AND. Pitanje(, "Ispusti artikle sa sumnjivom NC (D/N)",  "N" ) == "D"
   // cCtrl_art := "D"
   // ENDIF


   IF get_file_list( cFFilt, cExpPath, @cImpFile ) == 0 // daj pregled fajlova za import, te setuj varijablu cImpFile
      RETURN .F.
   ENDIF


   IF fajl_get_broj_linija( cImpFile ) == 0
      MsgBeep( "Odabrani fajl je prazan!#Prekidam operaciju !" )
      RETURN .F.
   ENDIF


   PRIVATE aDbf := {}
   PRIVATE aRules := {}
   PRIVATE aFaktEx
   PRIVATE lFtSkip := .F.
   PRIVATE lNegative := .F.

   kalk_imp_txt_set_a_dbf_temp( @aDbf ) // setuj polja temp tabele u matricu aDbf
   kalk_imp_set_rule_dok( @aRules ) // setuj pravila upisa podataka u temp tabelu
   kalk_imp_txt_to_temp( aDbf, aRules, cImpFile ) // prebaci iz txt => temp tbl


   IF !kalk_imp_check_partn_roba_exist()
      MsgBeep( "Prekidamo operaciju !#Nepostojeće šifre!" )
      RETURN .F.
   ENDIF

   my_close_all_dbf()

   IF kalk_imp_check_broj_fakture_exist( @aFaktEx )
      IF Pitanje(, "Preskočiti ove dokumente prilikom importa (D/N)?", "D" ) == "D"
         lFtSkip := .T.
      ENDIF
   ENDIF

   lNegative := .F.

   IF Pitanje(, "Prebaciti prvo negativne dokumente (povrate) ?", "D" ) == "D"
      lNegative := .T.
   ENDIF


   IF kalk_imp_from_temp_to_pript( aFaktEx, lFtSkip, lNegative ) == 0  // , cCtrl_art ) == 0
      MsgBeep( "Operacija prekinuta!" )
      RETURN .F.
   ENDIF

   IF Pitanje(, "Obraditi dokumente iz kalk pript (D/N)?", "D" ) == "D"
      IF kalk_imp_obradi_sve_dokumente_iz_pript( NIL, __stampaj )
         kalk_imp_brisi_txt( cImpFile )
      ENDIF
   ELSE
      MsgBeep( "Dokumenti nisu obrađeni!#Obrada se moze uraditi i naknadno!" )
      my_close_all_dbf()
   ENDIF

   RETURN .T.


/*
 *     Vraca filter za naziv dokumenta u zavisnosti sta je odabrano VP ili MP
 */

STATIC FUNCTION kalk_get_vp_ili_mp()

   LOCAL cVPMP := "V", cRet

   // pozovi box za izbor
   Box(, 5, 60 )
   @ 1 + m_x, 2 + m_y SAY "Importovati:"
   @ 2 + m_x, 2 + m_y SAY "----------------------------------"
   @ 3 + m_x, 2 + m_y SAY "Veleprodaja (V)"
   @ 4 + m_x, 2 + m_y SAY "Maloprodaja (M)"
   @ 5 + m_x, 17 + m_y SAY "izbor =>" GET cVPMP VALID cVPMP $ "MV" .AND. !Empty( cVPMP ) PICT "@!"
   READ
   BoxC()


   cRet := "R*.R??" // filter za veleprodaju

   DO CASE
   CASE cVPMP == "M" // maloprodaja
      cRet := "M*.M??"
   CASE cVPMP == "V"
      cRet := "R*.R??"
   ENDCASE

   RETURN cRet



/*
 *     Kreiranje temp tabele, te prenos zapisa iz text fajla "cTextFile" u tabelu putem aRules pravila
 *   param: aDbf - struktura tabele
 *   param: aRules - pravila upisivanja jednog zapisa u tabelu, princip uzimanja zapisa iz linije text fajla
 *   param: cTxtFile - txt fajl za import
 */

FUNCTION kalk_imp_txt_to_temp( aDbf, aRules, cTxtFile )

   LOCAL oFile, nCnt

   my_close_all_dbf()

   cre_kalk_imp_temp( aDbf )
   o_kalk_imp_temp()

   IF !File( f18_ime_dbf( "kalk_imp_temp" ) )
      MsgBeep( "Ne mogu kreirati fajl kalk_imp_temp.dbf !" )
      RETURN .F.
   ENDIF


   cTxtFile := AllTrim( cTxtFile ) // zatim iscitaj fajl i ubaci podatke u tabelu

   oFile := TFileRead():New( cTxtFile )
   oFile:Open()

   IF oFile:Error()
      MsgBeep( oFile:ErrorMsg( "Problem sa otvaranjem fajla: " ) )
   ENDIF


   DO WHILE oFile:MoreToRead() // prodji kroz svaku liniju i insertuj zapise u temp.dbf

      cVar := hb_StrToUTF8( oFile:ReadLine() ) // uzmi u cText liniju fajla

      SELECT kalk_imp_temp
      APPEND BLANK

      FOR nCnt := 1 TO Len( aRules )
         cFName := Field( nCnt )
         xVal := aRules[ nCnt, 1 ]
         RREPLACE &cFName WITH &xVal
      NEXT

   ENDDO

   oFile:Close()

   SELECT kalk_imp_temp

   // proci kroz temp i napuni da li je dtype pozitivno ili negativno ali samo ako je u pitanju racun tabela... !
   IF kalk_imp_temp->( FieldPos( "idtipdok" ) ) <> 0
      GO TOP
      my_flock()
      DO WHILE !Eof()
         IF field->idtipdok == "10" .AND. field->kolicina < 0
            RREPLACE field->dtype WITH "0"
         ELSE
            RREPLACE field->dtype WITH "1"
         ENDIF
         SKIP
      ENDDO
      my_unlock()
   ENDIF

   MsgBeep( "Import txt => temp - OK" )

   RETURN .T.



/*
*  kopira podatke iz pomocne tabele u tabelu KALK->PRIPT
*  - aFExist matrica sa postojecim fakturama
*  - lFSkip preskaci postojece fakture
*  - lNegative - prvo prebaci negativne fakture
* - cCtrl_art - preskoci sporne artikle NC u hendeku ! na osnovu CACHE tabele
*/

STATIC FUNCTION kalk_imp_from_temp_to_pript( aFExist, lFSkip, lNegative )// , cCtrl_art )

   LOCAL cBrojKalk
   LOCAL cTipDok
   LOCAL cIdKonto
   LOCAL cIdKonto2
   LOCAL cIdPJ
   LOCAL aArr_ctrl := {}
   LOCAL cIdKontoZaduzuje, cIdKontoRazduzuje
   LOCAL nRbr, nUvecaj, nCnt, cPredhodniFaktDokument, cPredhodniTipDokumenta, cPredhodnoProdMjesto, aPom
   LOCAL cFakt, cTDok, cIdProdajnoMjesto
   LOCAL nFExist, nT_scan, cIdRobaSifraDob
   LOCAL cIdKontoTmp, cSifraDobavljaca, cIdRobaTmp
   LOCAL i

   my_close_all_dbf()

   o_kalk_pripr()
   // o_koncij()
   // select_o_roba()
   o_kalk_pript()

   select_o_kalk_imp_temp()

   IF lNegative == nil
      lNegative := .F.
   ENDIF

   IF lNegative == .T.
      SET ORDER TO TAG "2"
   ELSE
      SET ORDER TO TAG "1"
   ENDIF

   GO TOP

   nRbr := 0
   nUvecaj := 0
   nCnt := 0

   cPredhodniFaktDokument := "XXXXXX"
   cPredhodniTipDokumenta := "XX"
   cPredhodnoProdMjesto := "XXX"
   aPom := {}

   MsgO( "tmp -> pript ..." )
   DO WHILE !Eof()

      cFakt := AllTrim( kalk_imp_temp->brdok )
      cTDok := get_kalk_tip_by_vind_fakt_tip( AllTrim( kalk_imp_temp->idtipdok ), kalk_imp_temp->idpm )
      cIdProdajnoMjesto := kalk_imp_temp->idpm
      cIdPJ := kalk_imp_temp->idpj

   /*
         IF cCtrl_art == "D"   // pregledaj CACHE, da li treba preskociti ovaj artikal

            nT_scan := 0

            cIdKontoTmp := kalk_imp_get_konto_by_tip_pm_poslovnica( cTDok, kalk_imp_temp->idpm, "R", cIdPJ )

    ---        SELECT roba
            -- SET ORDER TO TAG "ID_VSD"
            cSifraDobavljaca := PadL( AllTrim( kalk_imp_temp->idroba ), 5, "0" )

            SEEK cSifraDobavljaca // aha trazi se po sifri dobavljaca 52 => 00052
            cIdRobaTmp := field->id

            O_CACHE
            SELECT cache
            SET ORDER TO TAG "1"
            GO TOP
            SEEK PadR( cIdKontoTmp, 7 ) + PadR( cIdRobaTmp, 10 )


            IF Found() .AND. prag_odstupanja_nc_sumnjiv() > 0 .AND. ( field->odst > prag_odstupanja_nc_sumnjiv() ) // dodaj sporne u kontrolnu matricu

               nT_scan := AScan( aArr_ctrl, ;
                  {| xVal| xVal[ 1 ] + PadR( xVal[ 2 ], 10 ) == cTDok + PadR( AllTrim( cFakt ), 10 ) } )

               IF nT_scan = 0
                  AAdd( aArr_ctrl, { cTDok, PadR( AllTrim( cFakt ), 10 ) } )
               ENDIF

            ENDIF

            SELECT kalk_imp_temp
         ENDIF
   */

      IF lFSkip // ako je ukljucena opcija preskakanja postojecih faktura
         IF Len( aFExist ) > 0
            nFExist := AScan( aFExist, {| aVal | AllTrim( aVal[ 1 ] ) == cFakt } )
            IF nFExist > 0
               SELECT kalk_imp_temp  // prekoci onda ovaj zapis i idi dalje
               SKIP
               LOOP
            ENDIF
         ENDIF
      ENDIF


      // IF cTDok <> cPredhodniTipDokumenta // promjena tipa dokumenta
      // nUvecaj := 0
      // ENDIF

      IF ( cFakt <> cPredhodniFaktDokument ) // .OR. (cTDok == "11" .AND. (cIdProdajnoMjesto <> cPredhodnoProdMjesto) )
         ++nUvecaj
         cBrojKalk := kalk_imp_get_next_temp_broj( nUvecaj )
         nRbr := 0
         AAdd( aPom, { cTDok, cBrojKalk, cFakt } )
      ENDIF

/*

--      SELECT roba   // pronadji robu sifra dobavljaca
      --SET ORDER TO TAG "ID_VSD"

      GO TOP
  --    SEEK cIdRobaSifraDob
*/
      cIdRobaSifraDob := PadL( AllTrim( kalk_imp_temp->idroba ), 5, "0" )
      find_roba_by_sifradob( cIdRobaSifraDob )

      cIdKontoZaduzuje := kalk_imp_get_konto_by_tip_pm_poslovnica( cTDok, kalk_imp_temp->idpm, "Z", cIdPJ )
      cIdKontoRazduzuje := kalk_imp_get_konto_by_tip_pm_poslovnica( cTDok, kalk_imp_temp->idpm, "R", cIdPJ )

      select_o_koncij( cIdKontoZaduzuje )


      select_o_kalk_pript()
      APPEND BLANK // pript
      REPLACE idfirma WITH self_organizacija_id(), ;
         rBr WITH Str( ++nRbr, 3 ), ;
         idvd WITH cTDok, ;
         brdok WITH cBrojKalk, ;
         datdok WITH kalk_imp_temp->datdok, ;
         idpartner WITH kalk_imp_temp->idpartner, ;
         idtarifa WITH ROBA->idtarifa, ;
         brfaktp WITH cFakt, ;
         datfaktp WITH kalk_imp_temp->datdok, ;
         datval WITH kalk_imp_temp->datval, ;
         idkonto WITH cIdKontoZaduzuje, ;
         idkonto2 WITH cIdKontoRazduzuje, ;
         idzaduz2 WITH ""

      IF cTDok $ "11#41"

         REPLACE tmarza2 WITH "A"
         REPLACE tprevoz WITH "A"

         IF cTDok == "11"
            REPLACE pkonto WITH cIdKontoZaduzuje, ;
               mkonto WITH cIdKontoRazduzuje, ;
               mpcsapp WITH kalk_get_mpc_by_koncij_pravilo( cIdKontoZaduzuje )
         ELSE
            REPLACE mpcsapp WITH kalk_imp_temp->cijena
         ENDIF

      ENDIF

      REPLACE kolicina WITH kalk_imp_temp->kolicina, ;
         idroba WITH roba->id, ;
         nc WITH ROBA->nc, ;
         vpc WITH kalk_imp_temp->cijena, ;
         rabatv WITH kalk_imp_temp->rabatp, ;
         mpc WITH kalk_imp_temp->porez


      cPredhodniFaktDokument := cFakt
      cPredhodniTipDokumenta := cTDok
      cPredhodnoProdMjesto := cIdProdajnoMjesto

      ++nCnt
      SELECT kalk_imp_temp
      SKIP

   ENDDO
   MsgC()

   IF nCnt > 0 // izvjestaj o prebacenim dokumentima

      ASort( aPom,,, {| x, y | x[ 1 ] + "-" + x[ 2 ] < y[ 1 ] + "-" + y[ 2 ] } )

      START PRINT EDITOR
      ? "========================================"
      ? "Generisani sljedeci dokumenti:          "
      ? "========================================"
      ? "Dokument     * Sporna NC"
      ? "----------------------------------------"

      FOR i := 1 TO Len( aPom )

         cT_tipdok := aPom[ i, 1 ]
         cT_brdok := aPom[ i, 2 ]
         cT_brfakt := aPom[ i, 3 ]
         cT_ctrl := ""

   /*
            IF cCtrl_art == "D" .AND. Len( aArr_ctrl ) > 0
               nT_scan := AScan( aArr_ctrl, {| xVal| xVal[ 1 ] + PadR( xVal[ 2 ], 10 ) == cT_tipdok + PadR( cT_brfakt, 10 ) } )

               IF nT_scan <> 0
                  cT_ctrl := " !!! ERROR !!!"
               ENDIF
            ENDIF
   */
         ? cT_tipdok + " - " + cT_brdok, cT_ctrl

      NEXT

      ?
      FF
      ENDPRINT

   ENDIF

   /*
      IF cCtrl_art == "D" .AND. Len( aArr_ctrl ) > 0

         START PRINT EDITOR

         ?
         ? "Ispusteni dokumenti:"
         ? "------------------------------------"

         FOR xy := 1 TO Len( aArr_ctrl )
            ? aArr_ctrl[ xy, 1 ] + "-" + aArr_ctrl[ xy, 2 ]
         NEXT

         FF
         ENDPRINT

      ENDIF
   */

   /*
      IF cCtrl_art == "D" .AND. Len( aArr_ctrl ) > 0 // pobrisi ispustene dokumente

         nT_scan := 0

         SELECT pript
         SET ORDER TO TAG "0"
         GO TOP

         DO WHILE !Eof()

            nT_scan := AScan( aArr_ctrl, {| xval| xval[ 1 ] + PadR( xval[ 2 ], 10 ) == field->idvd + PadR( field->brfaktp, 10 ) } )

            IF nT_scan <> 0
               DELETE
            ENDIF

            SKIP
         ENDDO

      ENDIF
   */

   RETURN 1




// == SEKCIJA ====================== provjere - validacije =========================================


/*
 *     Provjeri da li postoji broj fakture u azuriranim dokumentima
 */

STATIC FUNCTION kalk_imp_check_broj_fakture_exist( aFakt )

   LOCAL i

   MsgO( "provjera da li u kalk dokumentima vec postoje brfaktp ..." )
   // aPomFakt := kalk_postoji_faktura_a( gAImpRight )
   aFakt := kalk_postoji_faktura_a()
   MsgC()

   IF Len( aFakt ) > 0

      start_print_editor()
      ?
      ? "Kontrolom azuriranih KALK dokumenata, uoceno da se vec pojavljuju"
      ? "navedeni brojevi faktura iz fajla za import:"
      ?
      ?
      ? "Kontrola azuriranih dokumenata:"
      ? "-------------------------------"
      ? "Broj fakture => kalkulacija"
      ? "-------------------------------"
      ?

      FOR i := 1 TO Len( aFakt )
         ? aFakt[ i, 1 ] + " => " + aFakt[ i, 2 ]
      NEXT

      end_print_editor()

      RETURN .T.

   ENDIF

   RETURN .F. // ne postoje azurirane fakture



STATIC FUNCTION kalk_imp_check_partn_roba_exist()

   LOCAL aPomPart := {}, aPomRoba := {}, i

   aPomPart := kalk_imp_partn_exist()

   IF Len( aPomPart )  == 0
      aPomRoba := kalk_imp_roba_exist_sifradob()
   ENDIF

   IF ( Len( aPomPart ) > 0 .OR. Len( aPomRoba ) > 0 )

      start_print_editor()

      IF ( Len( aPomPart ) > 0 )
         ?U "P) Lista nepostojećih partnera:"
         ? "------------------------------"
         ?
         FOR i := 1 TO Len( aPomPart )
            ? Str( i, 4 ), aPomPart[ i ]
         NEXT
         ?
      ENDIF

      IF ( Len( aPomRoba ) > 0 )
         ?U "R) Lista nepostojećih artikala (sifradob):"
         ? "-------------------------------------------"
         ?
         FOR i := 1 TO Len( aPomRoba )
            ? Str( i, 4 ), aPomRoba[ i, 1 ]
         NEXT
         ?
      ENDIF

      end_print_editor()

      RETURN .F.
   ENDIF

   RETURN .T.



FUNCTION kalk_imp_roba_exist_sifradob()

   LOCAL aRet, cIdRobaSifraDobavljaca, nRes, cNazRoba, nCount := 0

   // o_roba()
   select_o_kalk_imp_temp()
   GO TOP

   aRet := {}

   Box( "#Sifra roba (sifradob) provjera", 3, 50 )

   DO WHILE !Eof()

      ++nCount

      // IF lSifraDob == .T.
      cIdRobaSifraDobavljaca := PadL( AllTrim( kalk_imp_temp->idroba ), 5, "0" )

      @ m_x + 1, m_y + 2 SAY Str( nCount, 5 ) + " : " + cIdRobaSifraDobavljaca

      // ELSE
      // cIdRobaSifraDobavljaca := AllTrim( kalk_imp_temp->idroba )
      // ENDIF

      cNazRoba := ""

      // ako u temp postoji "NAZROBA"
      IF kalk_imp_temp->( FieldPos( "nazroba" ) ) <> 0
         cNazRoba := AllTrim( kalk_imp_temp->nazroba )
      ENDIF

      IF !find_roba_by_sifradob( cIdRobaSifraDobavljaca, .T. )
         nRes := AScan( aRet, {| aVal | aVal[ 1 ] == cIdRobaSifraDobavljaca } )
         IF nRes == 0
            AAdd( aRet, { cIdRobaSifraDobavljaca, cNazRoba } )
         ENDIF
      ENDIF

      SELECT kalk_imp_temp
      SKIP
   ENDDO

   BoxC()

   RETURN aRet


/*
 *   vraca matricu sa parovima faktura -> pojavljuje se u azur.kalk
 */
STATIC FUNCTION kalk_postoji_faktura_a()

   LOCAL cBrFakt
   LOCAL cTDok
   LOCAL aRet, cDok, cBrOriginal

   // IF nRight == nil
   // nRight := 0
   // ENDIF

   // o_kalk_doks()
   select_o_kalk_imp_temp()
   GO TOP

   aRet := {}
   cDok := "XXXXXX"

   DO WHILE !Eof()

      cBrFakt := AllTrim( kalk_imp_temp->brdok )
      cBrOriginal := cBrFakt

      // IF nRight > 0
      // cBrFakt := PadR( cBrFakt, Len( cBrFakt ) - nRight )
      // ENDIF

      cTDok := get_kalk_tip_by_vind_fakt_tip( AllTrim( kalk_imp_temp->idtipdok ), kalk_imp_temp->idpm )

      IF cBrFakt == cDok
         SKIP
         LOOP
      ENDIF


      IF find_kalk_doks_by_broj_fakture( cTDok,  PadR( cBrFakt, 10 ) )
         AAdd( aRet, { cBrOriginal, kalk_doks->idfirma + "-" + kalk_doks->idvd + "-" + AllTrim( kalk_doks->brdok ) } )
      ENDIF

      SELECT kalk_imp_temp
      SKIP

      cDok := cBrFakt

   ENDDO

   RETURN aRet



FUNCTION kalk_imp_get_next_temp_broj( nUvecaj )

   LOCAL nX := 1, cResult := "00001   "

   FOR nX := 1 TO nUvecaj
      cResult := PadR( novasifra( AllTrim( cResult ) ), 5 ) + Right( cResult, 3 )
   NEXT

   RETURN cResult



// =================== veze =====================================================


/*
 *   Vraca kalk tip dokumenta na osnovu fakt tip dokumenta
 *   param: cFaktTD - fakt tip dokumenta
 */

STATIC FUNCTION get_kalk_tip_by_vind_fakt_tip( cFaktTD, cIdProdajnoMjesto )

   LOCAL cRet := ""

   IF ( cFaktTD == "" .OR. cFaktTD == NIL )
      RETURN "XX"
   ENDIF

   DO CASE

   CASE cFaktTD == "10" // racuni VP FAKT 10 -> KALK 14
      cRet := "14"


   CASE ( cFaktTD == "11" .AND. cIdProdajnoMjesto < "200" ) // zaduzenje prodavnica KALK 11
      cRet := "11"

   CASE ( cFaktTD == "11" .AND. cIdProdajnoMjesto >= "200" ) // diskont vindija FAKT 11 -> KALK 41
      cRet := "41"


   CASE cFaktTD $ "90#91#92" // kalo, rastur - otpis radio se u kalku
      cRet := "95"


   CASE cFaktTD $ "96"  // otprema - medjuskladisnica
      cRet := "96"

   CASE cFaktTD == "70" // Knjizna obavjest 70 -> KALK KO
      cRet := "KO"

   ENDCASE

   RETURN cRet



// ---------------------------------------------------------------
// Vrati konto za prodajno mjesto Vindijine prodavnice
// cProd - prodajno mjesto C(3), npr "200"
// cPoslovnica - poslovnica sarajevo ili tuzla ili ....
// cita iz fmk.ini/kumpath
// [Vindija]
// VPR200_050=13200
// VPR201_050=13201
// ---------------------------------------------------------------

STATIC FUNCTION kalk_imp_get_konto_zaduz_prodavnica_za_prod_mjesto( cPoslovnica, cProd )

   LOCAL cRet

   IF cProd == "XXX"
      RETURN "XXXXX"
   ENDIF

   IF cProd == "" .OR. cProd == nil
      RETURN "XXXXX"
   ENDIF

   IF cPoslovnica == "" .OR. cPoslovnica == nil
      RETURN "XXXXX"
   ENDIF

   cRet := fetch_metric(  "kalk_imp_prod_zad_" + cPoslovnica + "_" + cProd, NIL,  Space( 7 ) )

   IF Empty( cRet )
      kalk_imp_set_konto_zaduz_prodavnica_za_prod_mjesto( cPoslovnica, cProd )
      cRet := kalk_imp_get_konto_zaduz_prodavnica_za_prod_mjesto( cPoslovnica, cProd )
   ENDIF

   IF cRet == "" .OR. cRet == nil
      cRet := "XXXXX"
   ENDIF

   RETURN cRet


/*
   040 poslovnica, prodajno mjesto 0001, konto 13300
*/
STATIC FUNCTION  kalk_imp_set_konto_zaduz_prodavnica_za_prod_mjesto( cPoslovnica, cIdProdajnoMjesto )

   LOCAL hKonta := hb_Hash(), cKonto

   Box(, 10, 75 )
   IF cPoslovnica == NIL
      cPoslovnica := Space( 3 )
      cIdProdajnoMjesto := Space( 3 )
      @ m_x + 1, m_y + 2 SAY "Poslovnica:" GET cPoslovnica
      @ m_x + 2, m_y + 2 SAY "Prodajno mjesto:" GET cIdProdajnoMjesto
      READ
      IF LastKey() == K_ESC
         BoxC()
         RETURN .F.
      ENDIF
   ELSE
      @ m_x + 1, m_y + 2 SAY "Poslovnica: " + cPoslovnica
      @ m_x + 2, m_y + 2 SAY "Prodajno mjesto: " + cIdProdajnoMjesto
   ENDIF


   cKonto := PadR( fetch_metric(  "kalk_imp_prod_zad_" + cPoslovnica + "_" + cIdProdajnoMjesto, NIL,  Space( 7 ) ), 7 )

   @ m_x + 3, m_y + 2 SAY8 "KALK 11 prod konto zaduzuje: " GET cKonto

   READ
   BoxC()

   IF LastKey() == K_ESC
      RETURN .F.
   ENDIF

   set_metric( "kalk_imp_prod_zad_" + cPoslovnica + "_" + cIdProdajnoMjesto, NIL, cKonto )

   RETURN .T.


/* -----------------------------------------------------------

Vraca konto za odredjeni tipdokumenta
cTipDok - tip dokumenta
 cTip - "Z" zaduzuje, "R" - razduzuje
 cPoslovnica -poslovnica vindije sarajevo, tuzla ili ...


 primjer:
 TD14Z050=1310 // posl.sarajevo
 TD14R050=1200
 TD14R042=1201 // posl.tuzla


 Poslovnica sarajevo 050
 ==================================
 kalk_imp_050_14_Z = 1310   // kalk 14 kto zaduzuje
 kalk_imp_050_14_R = 1200   // kalk 14 kto razduzuje

*/

STATIC FUNCTION kalk_imp_get_konto_za_tip_dokumenta_poslovnica( cTipDok, cZadRazd, cPoslovnica )

   LOCAL cRet := fetch_metric( "kalk_imp_" + cPoslovnica + "_" + cTipDok + "_" + cZadRazd, NIL,  "XXXX" )

   IF cRet == "XXXX"
      set_kalk_imp_parametri_za_poslovnica( cPoslovnica )
      kalk_imp_get_konto_za_tip_dokumenta_poslovnica( cTipDok, cZadRazd, cPoslovnica )
   ENDIF

   RETURN cRet


STATIC FUNCTION set_kalk_imp_parametri_za_poslovnica( cPoslovnica )

   LOCAL hKonta := hb_Hash(), cTipDok, cZadRazd

   Box(, 11, 75 )
   IF cPoslovnica == NIL
      cPoslovnica := Space( 3 )
      @ m_x + 1, m_y + 2 SAY "Poslovnica:" GET cPoslovnica
      READ
      IF LastKey() == K_ESC
         BoxC()
         RETURN .F.
      ENDIF
   ELSE
      @ m_x + 1, m_y + 2 SAY "Poslovnica: " + cPoslovnica
   ENDIF


   cTipDok := "14"
   cZadRazd := "Z"
   hKonta[ "14Z" ] := fetch_metric(  "kalk_imp_" + cPoslovnica + "_" + cTipDok + "_" + cZadRazd, NIL,  Space( 7 ) )
   cZadRazd := "R"
   hKonta[ "14R" ] := fetch_metric(  "kalk_imp_" + cPoslovnica + "_" + cTipDok + "_" + cZadRazd, NIL,  Space( 7 ) )

   cTipDok := "11"
   cZadRazd := "Z"
   hKonta[ "11Z" ] := fetch_metric(  "kalk_imp_" + cPoslovnica + "_" + cTipDok + "_" + cZadRazd, NIL,  Space( 7 ) )
   cZadRazd := "R"
   hKonta[ "11R" ] := fetch_metric(  "kalk_imp_" + cPoslovnica + "_" + cTipDok + "_" + cZadRazd, NIL,  Space( 7 ) )

   cTipDok := "41"
   cZadRazd := "Z"
   hKonta[ "41Z" ] := fetch_metric(  "kalk_imp_" + cPoslovnica + "_" + cTipDok + "_" + cZadRazd, NIL,  Space( 7 ) )
   cZadRazd := "R"
   hKonta[ "41R" ] := fetch_metric(  "kalk_imp_" + cPoslovnica + "_" + cTipDok + "_" + cZadRazd, NIL,  Space( 7 ) )

   cTipDok := "95"
   cZadRazd := "Z"
   hKonta[ "95Z" ] := fetch_metric(  "kalk_imp_" + cPoslovnica + "_" + cTipDok + "_" + cZadRazd, NIL,  Space( 7 ) )
   cZadRazd := "R"
   hKonta[ "95R" ] := fetch_metric(  "kalk_imp_" + cPoslovnica + "_" + cTipDok + "_" + cZadRazd, NIL,  Space( 7 ) )

   cTipDok := "96"
   cZadRazd := "Z"
   hKonta[ "96Z" ] := fetch_metric(  "kalk_imp_" + cPoslovnica + "_" + cTipDok + "_" + cZadRazd, NIL,  Space( 7 ) )
   cZadRazd := "R"
   hKonta[ "96R" ] := fetch_metric(  "kalk_imp_" + cPoslovnica + "_" + cTipDok + "_" + cZadRazd, NIL,  Space( 7 ) )

   cTipDok := "KO"
   cZadRazd := "Z"
   hKonta[ "KOZ" ] := fetch_metric(  "kalk_imp_" + cPoslovnica + "_" + cTipDok + "_" + cZadRazd, NIL,  Space( 7 ) )
   cZadRazd := "R"
   hKonta[ "KOR" ] := fetch_metric(  "kalk_imp_" + cPoslovnica + "_" + cTipDok + "_" + cZadRazd, NIL,  Space( 7 ) )


   @ m_x + 3, m_y + 2 SAY "KALK 14 KTO ZAD: " GET hKonta[ "14Z" ]
   @ m_x + 3, Col() + 2 SAY "KALK 14 KTO RAZD: " GET hKonta[ "14R" ]

   @ m_x + 4, m_y + 2 SAY "KALK 11 KTO ZAD: " GET hKonta[ "11Z" ]
   @ m_x + 4, Col() + 2 SAY "KALK 11 KTO RAZD: " GET hKonta[ "11R" ]

   @ m_x + 5, m_y + 2 SAY "KALK 41 KTO ZAD: " GET hKonta[ "41Z" ]
   @ m_x + 5, Col() + 2 SAY "KALK 41 KTO RAZD: " GET hKonta[ "41R" ]

   @ m_x + 6, m_y + 2 SAY "KALK 95 KTO ZAD: " GET hKonta[ "95Z" ]
   @ m_x + 6, Col() + 2 SAY "KALK 95 KTO RAZD: " GET hKonta[ "95R" ]

   @ m_x + 7, m_y + 2 SAY "KALK 96 KTO ZAD: " GET hKonta[ "96Z" ]
   @ m_x + 7, Col() + 2 SAY "KALK 96 KTO RAZD: " GET hKonta[ "96R" ]

   @ m_x + 8, m_y + 2 SAY "KALK KO KTO ZAD: " GET hKonta[ "KOZ" ]
   @ m_x + 8, Col() + 2 SAY "KALK KO KTO RAZD: " GET hKonta[ "KOR" ]

   READ
   BoxC()

   IF LastKey() == K_ESC
      RETURN .F.
   ENDIF

   cTipDok := "14"
   cZadRazd := "Z"
   set_metric( "kalk_imp_" + cPoslovnica + "_" + cTipDok + "_" + cZadRazd, NIL, hKonta[ cTipDok + cZadRazd ] )
   cZadRazd := "R"
   set_metric( "kalk_imp_" + cPoslovnica + "_" + cTipDok + "_" + cZadRazd, NIL, hKonta[ cTipDok + cZadRazd ] )

   cTipDok := "11"
   cZadRazd := "Z"
   set_metric( "kalk_imp_" + cPoslovnica + "_" + cTipDok + "_" + cZadRazd, NIL, hKonta[ cTipDok + cZadRazd ] )
   cZadRazd := "R"
   set_metric( "kalk_imp_" + cPoslovnica + "_" + cTipDok + "_" + cZadRazd, NIL, hKonta[ cTipDok + cZadRazd ] )

   cTipDok := "41"
   cZadRazd := "Z"
   set_metric( "kalk_imp_" + cPoslovnica + "_" + cTipDok + "_" + cZadRazd, NIL, hKonta[ cTipDok + cZadRazd ] )
   cZadRazd := "R"
   set_metric( "kalk_imp_" + cPoslovnica + "_" + cTipDok + "_" + cZadRazd, NIL, hKonta[ cTipDok + cZadRazd ] )

   cTipDok := "95"
   cZadRazd := "Z"
   set_metric( "kalk_imp_" + cPoslovnica + "_" + cTipDok + "_" + cZadRazd, NIL, hKonta[ cTipDok + cZadRazd ] )
   cZadRazd := "R"
   set_metric( "kalk_imp_" + cPoslovnica + "_" + cTipDok + "_" + cZadRazd, NIL, hKonta[ cTipDok + cZadRazd ] )

   cTipDok := "96"
   cZadRazd := "Z"
   set_metric( "kalk_imp_" + cPoslovnica + "_" + cTipDok + "_" + cZadRazd, NIL, hKonta[ cTipDok + cZadRazd ] )
   cZadRazd := "R"
   set_metric( "kalk_imp_" + cPoslovnica + "_" + cTipDok + "_" + cZadRazd, NIL, hKonta[ cTipDok + cZadRazd ] )

   cTipDok := "KO"
   cZadRazd := "Z"
   set_metric( "kalk_imp_" + cPoslovnica + "_" + cTipDok + "_" + cZadRazd, NIL, hKonta[ cTipDok + cZadRazd ] )
   cZadRazd := "R"
   set_metric( "kalk_imp_" + cPoslovnica + "_" + cTipDok + "_" + cZadRazd, NIL, hKonta[ cTipDok + cZadRazd ] )

   RETURN .T.


/*
 *   Vraca konto za trazeni tip dokumenta i prodajno mjesto
 *   param: cTipDok - tip dokumenta
 *   param: cIdProdajnoMjesto - prodajno mjesto
 *   param: cTip - tip "Z" zad. i "R" razd.
 *   param: cPoslovnica - poslovnica tuzla ili sarajevo
 */

STATIC FUNCTION kalk_imp_get_konto_by_tip_pm_poslovnica( cTipDok, cIdProdajnoMjesto, cTip, cPoslovnica )

   LOCAL cRet

   DO CASE

   CASE cTipDok == "14"
      cRet := kalk_imp_get_konto_za_tip_dokumenta_poslovnica( cTipDok, cTip, cPoslovnica )

   CASE cTipDok == "11"
      IF cTip == "R"
         cRet := kalk_imp_get_konto_za_tip_dokumenta_poslovnica( cTipDok, cTip, cPoslovnica ) // razduzuje magacin
      ELSE // zaduzuje prodavnica
         cRet := kalk_imp_get_konto_zaduz_prodavnica_za_prod_mjesto( cPoslovnica, cIdProdajnoMjesto ) // zaduzuje prodavnica
      ENDIF

   CASE cTipDok == "41"
      cRet := kalk_imp_get_konto_za_tip_dokumenta_poslovnica( cTipDok, cTip, cPoslovnica )

   CASE cTipDok == "95"
      cRet := kalk_imp_get_konto_za_tip_dokumenta_poslovnica( cTipDok, cTip, cPoslovnica )

   CASE cTipDok $ "96"
      IF cTip == "R"
         cRet := kalk_imp_get_konto_za_tip_dokumenta_poslovnica( cTipDok, cTip, cPoslovnica )
      ELSE
         cRet := kalk_imp_get_konto_za_tip_dokumenta_poslovnica( cTipDok, cTip, cIdProdajnoMjesto )
      ENDIF

   CASE cTipDok == "KO"
      cRet := kalk_imp_get_konto_za_tip_dokumenta_poslovnica( cTipDok, cTip, cPoslovnica )

   ENDCASE

   RETURN cRet




// ================== parametri - Rpar, WPara checkpoint ==================

/*  kalk_imp_set_check_point
 *  Snima momenat do kojeg je dosao pri obradi dokumenata
 */
STATIC FUNCTION kalk_imp_set_check_point( nPRec )

   LOCAL nArr

   nArr := Select()

   o_params()
   SELECT params

   PRIVATE cSection := "K"
   PRIVATE cHistory := " "
   PRIVATE aHistory := {}

   Wpar( "is", nPRec )

   SELECT ( nArr )

   RETURN .T.



STATIC FUNCTION kalk_auto_import_setup()

   LOCAL nX
   LOCAL GetList := {}
   LOCAL cAImpRKonto

   cAImpRKonto := PadR( kalk_imp_txt_param_auto_import_podataka_konto(), 7 )

   nX := 1
   Box(, 10, 70 )

   @ m_x + nX, m_y + 2 SAY8 "Podešenja importa ********"

   nX += 2
   @ m_x + nX, m_y + 2 SAY8 "Štampati dokumente pri auto obradi (D/N)" GET gAImpPrint VALID gAImpPrint $ "DN" PICT "@!"
   nX += 1
   @ m_x + nX, m_y + 2 SAY8 "Automatska ravnoteža naloga na konto: " GET cAImpRKonto

   // nX += 1
   // @ m_x + nX, m_y + 2 SAY "Provjera broj naloga (minus karaktera):" GET gAImpRight PICT "9"


   READ
   BoxC()

   IF LastKey() <> K_ESC

      kalk_imp_txt_param_auto_import_podataka_konto( cAImpRKonto )

      o_params()

      PRIVATE cSection := "7"
      PRIVATE cHistory := " "
      PRIVATE aHistory := {}

      WPar( "ap", gAImpPrint )
      // WPar( "ar", gAImpRight )

      SELECT params
      USE

   ENDIF

   RETURN .T.


/*
 *  Pokrece ponovo obradu od momenta do kojeg je stao
 */
STATIC FUNCTION kalk_imp_continue_from_check_point()

   o_params()
   SELECT params
   PRIVATE cSection := "K"
   PRIVATE cHistory := " "
   PRIVATE aHistory := {}
   PRIVATE nDosaoDo
   Rpar( "is", @nDosaoDo )

   IF nDosaoDo == nil
      MsgBeep( "Nema nista zapisano u parametrima!#Prekidam operaciju!" )
      RETURN .F.
   ENDIF

   IF nDosaoDo == 0
      MsgBeep( "Nema zapisa o prekinutoj obradi!" )
      RETURN .F.
   ENDIF

   o_kalk_pript()
   SELECT pript
   SET ORDER TO TAG "1"
   GO nDosaoDo

   IF !Eof()
      MsgBeep( "Nastavljam od dokumenta#" + field->idfirma + "-" + field->idvd + "-" + field->brdok )
   ELSE
      MsgBeep( "Kraj tabele, nema nista za obradu!" )
      RETURN .T.
   ENDIF

   IF Pitanje(, "Nastaviti sa obradom dokumenata", "D" ) == "N"
      MsgBeep( "Operacija prekinuta!" )
      RETURN .F.
   ENDIF

   IF kalk_imp_obradi_sve_dokumente_iz_pript( nDosaoDo, __stampaj )

      kalk_imp_set_check_point( 0 ) // oznaci da je obrada zavrsena
      MsgBeep( "Dokumenti obradjeni!" )
      kalk_imp_brisi_txt( cImpFile )
   ENDIF

   RETURN .T.




/*
 *     Popunjavanje polja sifradob prema kljucu


STATIC FUNCTION FillDobSifra()

   LOCAL i

   IF !spec_funkcije_sifra( "FILLDOB" )
      MsgBeep( "Nemate ovlastenja za ovu opciju!!!" )
      RETURN .F.
   ENDIF

   o_roba()

--   SELECT roba
   SET ORDER TO TAG "ID"
   GO TOP

   cSifra := ""
   nCnt := 0
   aRpt := {}
   aSDob := {}

   Box(, 5, 60 )
   @ 1 + m_x, 2 + m_y SAY "Vrsim upis sifre dobavaljaca robe:"
   @ 2 + m_x, 2 + m_y SAY "==================================="

   DO WHILE !Eof()
      // ako je prazan zapis preskoci
      IF Empty( field->id )
         SKIP
         LOOP
      ENDIF

      cSStr := SubStr( field->id, 1, 1 )

      // provjeri karakteristicnost robe
      IF cSStr == "K" .OR. cSStr == "P"
         // roba KOKA LEN 5 sifradob
         cSifra := SubStr( RTrim( field->id ), -5 )
      ELSEIF cSStr == "V"
         // ostala roba
         cSifra := SubStr( RTrim( field->id ), -4 )
      ELSE
         SKIP
         LOOP
      ENDIF

      // upisi zapis
      Scatter()
      _sifradob := cSifra
      my_rlock()
      Gather()
      my_unlock()

      // potrazi sifru u matrici
      nRes := AScan( aSDob, {| aVal| aVal[ 1 ] == cSifra } )
      IF nRes == 0
         AAdd( aSDob, { cSifra, field->id } )
      ELSE
         AAdd( aRpt, { cSifra, aSDob[ nRes, 2 ] } )
         AAdd( aRpt, { cSifra, field->id } )
      ENDIF

      ++ nCnt

      @ 3 + m_x, 2 + m_y SAY "FMK sifra " + AllTrim( field->id ) + " => sifra dob. " + cSifra
      @ 5 + m_x, 2 + m_y SAY " => ukupno " + AllTrim( Str( nCnt ) )

      SKIP

   ENDDO

   BoxC()

   // ako je report matrica > 0 dakle postoje dupli zapisi
   IF Len( aRpt ) > 0

      START PRINT EDITOR
      ? "KONTROLA DULIH SIFARA VINDIJA_FAKT:"
      ? "==================================="
      ? "Sifra Vindija_FAKT -> Sifra FMK  "
      ?

      FOR i := 1 TO Len( aRpt )
         ? aRpt[ i, 1 ] + " -> " + aRpt[ i, 2 ]
      NEXT

      ?
      ? "Provjerite navedene sifre..."
      ?

      FF
      ENDPRINT
   ENDIF

   RETURN .T.

*/



/*
    *   Setovanje pravila upisa zapisa u temp tabelu
    *   param: aRule - matrica pravila
*/

STATIC FUNCTION kalk_imp_set_rule_dok( aRule )

   // 1- idfirma
   AAdd( aRule, { "SUBSTR(cVar, 1, 2)" } )
   // 2-idtipdok
   AAdd( aRule, { "SUBSTR(cVar, 4, 2)" } )
   // 3-brdok
   AAdd( aRule, { "SUBSTR(cVar, 7, 8)" } )
   // 4-datdok
   AAdd( aRule, { "CTOD(SUBSTR(cVar, 16, 10))" } )
   // 5-idpartner
   AAdd( aRule, { "SUBSTR(cVar, 27, 6)" } )
   // 6-id pm
   AAdd( aRule, { "SUBSTR(cVar, 34, 3)" } )
   // 7-dindem
   AAdd( aRule, { "SUBSTR(cVar, 38, 3)" } )
   // 8-zaokr
   AAdd( aRule, { "VAL(SUBSTR(cVar, 42, 1))" } )
   // 9-rbr
   AAdd( aRule, { "STR(VAL(SUBSTR(cVar, 44, 3)),3)" } )
   // 10-idroba
   AAdd( aRule, { "ALLTRIM(SUBSTR(cVar, 48, 5))" } )
   // 11-kolicina
   AAdd( aRule, { "VAL(SUBSTR(cVar, 54, 16))" } )
   // 12-cijena
   AAdd( aRule, { "VAL(SUBSTR(cVar, 71, 16))" } )
   // 13-rabat
   AAdd( aRule, { "VAL(SUBSTR(cVar, 88, 14))" } )
   // 14-porez
   AAdd( aRule, { "VAL(SUBSTR(cVar, 103, 14))" } )
   // 15-procenat rabata
   AAdd( aRule, { "VAL(SUBSTR(cVar, 118, 14))" } )
   // 16-datum valute
   AAdd( aRule, { "CTOD(SUBSTR(cVar, 133, 10))" } )
   // 17-obracunska kolicina
   AAdd( aRule, { "VAL(SUBSTR(cVar, 144, 16))" } )
   // 18-poslovna jedinica "kod"
   AAdd( aRule, { "SUBSTR(cVar, 161, 3)" } )

   RETURN .T.



/*
 *   Setuj matricu sa poljima tabele dokumenata RACUN
 *   param: aDbf - matrica
*/

STATIC FUNCTION kalk_imp_txt_set_a_dbf_temp( aDbf )

   AAdd( aDbf, { "idfirma", "C", 2, 0 } )
   AAdd( aDbf, { "idtipdok", "C", 2, 0 } )
   AAdd( aDbf, { "brdok", "C", 8, 0 } )
   AAdd( aDbf, { "datdok", "D", 8, 0 } )
   AAdd( aDbf, { "idpartner", "C", 6, 0 } )
   AAdd( aDbf, { "idpm", "C", 3, 0 } )
   AAdd( aDbf, { "dindem", "C", 3, 0 } )
   AAdd( aDbf, { "zaokr", "N", 1, 0 } )
   AAdd( aDbf, { "rbr", "C", 3, 0 } )
   AAdd( aDbf, { "idroba", "C", 10, 0 } )
   AAdd( aDbf, { "kolicina", "N", 14, 5 } )
   AAdd( aDbf, { "cijena", "N", 14, 5 } )
   AAdd( aDbf, { "rabat", "N", 14, 5 } )
   AAdd( aDbf, { "porez", "N", 14, 5 } )
   AAdd( aDbf, { "rabatp", "N", 14, 5 } )
   AAdd( aDbf, { "datval", "D", 8, 0 } )
   AAdd( aDbf, { "obrkol", "N", 14, 5 } )
   AAdd( aDbf, { "idpj", "C", 3, 0 } )
   AAdd( aDbf, { "dtype", "C", 3, 0 } )

   RETURN .T.


STATIC FUNCTION cre_kalk_imp_temp( aDbf )

   LOCAL cTmpTbl := "kalk_imp_temp"

   IF File( f18_ime_dbf( cTmpTbl ) ) .AND. FErase( f18_ime_dbf( cTmpTbl ) ) == -1
      MsgBeep( "Ne mogu izbrisati kalk_imp_temp.dbf !" )

   ENDIF

   DbCreate2( cTmpTbl, aDbf )

   IF aDbf[ 1, 1 ] == "idpartner" // provjeri jesu li partneri ili dokumenti ili je roba
      create_index( "1", "idpartner", cTmpTbl ) // partner
   ELSEIF aDbf[ 1, 1 ] == "idpm"
      create_index( "1", "sifradob", cTmpTbl ) // roba
   ELSE
      create_index( "1", "idfirma+idtipdok+brdok+rbr", cTmpTbl ) // dokumenti
      create_index( "2", "dtype+idfirma+idtipdok+brdok+rbr", cTmpTbl )
   ENDIF

   RETURN .T.
