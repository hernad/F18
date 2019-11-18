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

// -------------------------------------------------------------------
// StartPrint(lUlFajl, cF)
// Pocetna procedura za stampu u OUTF.TXT
// * lUFajl - True -> cDirekt="V", False - tekuca postavka varijanta
// * cF - ime izlaznog fajla, tekuca vrijednost OUTF.TXT
// * FmkIni/f18_exe_path/Printeri_DirektnoOUTFTXT
// --------------------------------------------------------------
FUNCTION StartPrint( lUFajl, cF, cDocumentName )

   LOCAL cDirekt
   LOCAL cLpt
   LOCAL cDDir
   LOCAL cOutfTXT
   LOCAL lConfirmEnter := Set( _SET_CONFIRM )

   IF lUFajl == nil
      lUFajl := .F.
   ENDIF

   cFName := OUTF_FILE

   IF cF <> nil
      cFName := cF
   ENDIF

   IF ( cDocumentName == NIL )
      cDocumentName :=  gModul + '_' + DToC( Date() )
   ENDIF

   PRIVATE GetList := {}

   SetPRC( 0, 0 )

   cDirekt := gcDirekt
   cLpt := "1"
   nZagrada := 0

   cTekPrinter := gPrinter

   cOutfTXT := 'N' // my_get_from_ini( 'Printeri', 'DirektnoOUTFTXT', 'N' )

   IF !( lUFajl )
      cDirekt := print_dialog_box( cDirekt )
      cKom := "LPT" + gPPort

      IF cDirekt = "R"
         gPrinter := "R"
      ENDIF

      IF gPrinter = "G"
         cDirekt := "G"
      ENDIF

      IF cDirekt = "G"
         gPrinter := "G"
      ENDIF

      IF gPrinter == "R"
         set_ptxt_sekvence()
      ENDIF

      // transformisi cKom varijablu za portove > 4
      GPPortTransform( @cKom )

      SET CONFIRM ON

   ELSE
      cDirekt := "V"
   ENDIF

   cPrinter := cDirekt

   IF cDirekt == "D" .AND. gPrinter <> "R" .AND. gPrinter <> "G" .AND. cOutfTxt <> "D"
      DO WHILE .T.
         IF InRange( Val( gPPort ), 5, 7 )  .OR. ;
               ( Val( gPPort ) = 8 ) .OR. ;
               ( Val( gPPort ) = 9 ) .OR. ;
               ( Val( gPPort ) < 4 .AND. PrintReady( Val( gPPort ) ) )

            // 8 - copy lpt1
            EXIT

         ELSE
            Beep( 2 )
            MsgO( "Printer nije ukljucen - ON LINE !" )
            nBroji2 := Seconds()
            DO WHILE NextKey() == 0
               CekaHandler( @nBroji2 )
            ENDDO
            Inkey()
            MsgC()
            IF LastKey() == K_ESC
               RETURN .F.
            ENDIF
         ENDIF
      ENDDO

      SET CONSOLE OFF
   ELSE

      MsgO( "Priprema izvjestaja..." )

      SET CONSOLE OFF

      cKom := my_home() + cFName

      IF gnDebug >= 5
         MsgBeep( "Direktno N, cKom=" + AllTrim( cKom ) )
      ENDIF

   ENDIF


   SET PRINTER OFF
   SET DEVICE TO PRINTER

   cDDir := Set( _SET_DEFAULT )
   SET DEFAULT TO

   IF cKom = "LPT1" .AND. gPPort <> "8"
      SET PRINTER TO

   ELSEIF cKom == "LPT2" .AND. gPPort <> "9"
      Set( 24, "lpt2", .F. )
   ELSE

      IF SLASH $ cKom   // radi se o fajlu

         BEGIN SEQUENCE
            SET PRINTER TO ( cKom )
         recover
            Alert( "ERROR: SET PRINTER TO " + AllTrim( cKom ) )
            QUIT_1
         END SEQUENCE

      ELSE
         IF gnDebug >= 5
            MsgBeep( "set printer to (cKom)##var cKom=" + AllTrim( cKom ) )
         ENDIF
         SET PRINTER TO ( ckom )
      ENDIF

   ENDIF

   SET PRINTER ON

   nSekundi := Seconds()

   Set( _SET_DEFAULT, cDDir )
   GpIni( cDocumentName )
   Set( _SET_CONFIRM, lConfirmEnter )

   RETURN .T.

// --------------------------------------
// za portove > 4 izvrsi transformaciju
// cKom
// -------------------------------------
STATIC FUNCTION GPPortTransform( cKom )

   IF gPPort > "4"
      IF gpport == "5"
         cKom := "LPT1"
      ELSEIF gPPort == "6"
         cKom := "LPT2"
      ELSEIF gPPort == "7"
         cKom := "LPT3"
      ELSEIF gPPort $ "89"
         cKom := my_home() + cFName
         IF gnDebug >= 5
            MsgBeep( "Inicijalizacija var cKom##var cKom=" + AllTrim( cKom ) )
         ENDIF
      ENDIF
   ENDIF

   RETURN .T.




FUNCTION EndPrint()

   LOCAL cS
   LOCAL i
   LOCAL nSek2
   LOCAL cOutfTxt
   LOCAL cCommand
   PRIVATE cPom

   // #ifdef __PLATFORM__UNIX

   // TODO: #27234
   // my_close_all_dbf()
   // #endif


   SET DEVICE TO SCREEN
   SET PRINTER OFF
   SET PRINTER TO
   SET CONSOLE ON

   cOutfTxt := ""

   nSek2 := Seconds()

   f18_tone( 440, 2 )
   f18_tone( 440, 2 )

   // ako nije direktno na printer
   IF cPrinter <> "D" .OR. ( gPPort $ "89" .AND. cPrinter == "D" ) .OR. gPrinter == "R" .OR. gPrinter == "G" .OR. ( cOutftxt == "D" .AND. cPrinter == "D" )



      IF cPrinter <> "D" .OR. gPrinter == "R" .OR. gPrinter == "G" .OR. ( cOutftxt == "D" .AND. cPrinter == "D" )
         MsgC()
      ENDIF

      SAVE SCREEN TO cS

      IF cOutfTXT == "D" .AND. cPrinter = "D"
         // direktno na printer, ali preko outf.txt
         cKom := ckom + " LPT" + gPPort
         cPom := cKom
         !COPY &cPom

      ELSEIF gPPort $ "89" .AND. cPrinter = "D"
         cKom := ckom + " LPT"
         IF gPPort == "8"
            cKom += "1"
         ELSE
            cKom += "2"
         ENDIF
         cPom := cKom
         !COPY &cPom
         IF gnDebug >= 5
            MsgBeep( "LPT port 8 ili 9##!copy " + AllTrim( cKom ) )
         ENDIF
      ELSEIF cPrinter == "N"
         cPom := cKom
         !ll &cPom

      ELSEIF cPrinter == "E"
         cPom := cKom
         !q &cPom

      ELSEIF cPrinter == "V"

         IF "U" $ Type( "gaZagFix" )
            gaZagFix := NIL
         ENDIF
         IF "U" $ Type( "gaKolFix" )
            gaKolFix := NIL
         ENDIF

         // VidiFajl(cKom, gaZagFix, gaKolFix)
         // cCommand := "f18_editor " + my_home() + cFName
         // f18_run( cCommand )
         f18_editor( cFName )

         gaZagFix := NIL
         gaKolFix := NIL

      ELSEIF cPrinter == "G"
         cKom := my_home() + cFName
         gvim_cmd( cKom )
      ELSE
         // R - Windowsi
         Beep( 1 )
         cKom := my_home() + cFName

         IF gPrinter == "R"
            // IF gPDFprint == "X" .AND. programski_modul() == "FAKT"
            // IF Pitanje(, "Print u PDF/PTXT (D/N)?", "D" ) == "D"
            // PDFView( cKom )
            // ELSE
            // Ptxt( cKom )
            // ENDIF
            // ELSEIF gPDFprint == "D" .AND. programski_modul() == "FAKT"
            // PDFView( cKom )
            // ELSE
            Ptxt( cKom )
            // ENDIF
         ENDIF

      ENDIF
      RESTORE SCREEN FROM cS

      // cPrinter
   ENDIF

   // nemoj "brze izvjestaje"
   IF nSek2 - nSekundi > 10
      @ 23, 75 SAY nSek2 - nSekundi PICT "9999"
   ENDIF

   IF gPrinter <> cTekPrinter
      gPrinter := cTekPrinter
      PushWA()
      o_gparams()
      PRIVATE cSection := "P"
      PRIVATE cHistory := gPrinter
      PRIVATE aHistory := {}
      RPar_Printer()
      SELECT gparams
      USE
      PopWa()
   ENDIF

   RETURN .T.


FUNCTION SPrint2( cKom )

   // cKom je oznaka porta, npr. "3"

   LOCAL cddir, nNPort

   IF gPrinter = "R"
      IF !start_print()
         RETURN .F.
      ENDIF
      RETURN .T.
   ENDIF

   SetPRC( 0, 0 )
   nZagrada := 0
   cKom := Upper( cKom )
   nNPort := Val( SubStr( cKom, 4 ) )

   DO WHILE .T.

      IF ( SLASH $  cKom ) .OR. InRange( nNPort, 5, 7 )  .OR. ;
            ( nNPort = 8 ) .OR.  ;
            ( nNPort = 9 ) .OR.  ;
            ( nNPort < 4 .AND. PrintReady( Val( gPPort ) ) )
         EXIT
      ELSE
         Beep( 2 )
         MsgO( "Printer nije ukljucen ili je blokiran! PROVJERITE GA!" )
         Inkey()
         MsgC()
         IF LastKey() == K_ESC
            RETURN .F.
         ENDIF
      ENDIF
   ENDDO

   IF nNPort > 4
      IF nNport == 5
         cKom := "LPT1"
      ELSEIF nNport == 6
         ckom := "LPT2"
      ELSEIF nNport == 7
         cKom := "LPT3"
      ELSEIF nNPort > 7
         cKom := my_home() + cFName
         IF gnDebug >= 5
            MsgBeep( "SPrint2() var cKom=" + AllTrim( cKom ) )
         ENDIF
      ENDIF
   ENDIF

   SET CONSOLE OFF
   SET PRINTER OFF
   SET DEVICE TO PRINTER
   cDDir := Set( _SET_DEFAULT )
   SET DEFAULT TO
   IF cKom == "LPT1"
      IF gnDebug >= 5
         MsgBeep( "set printer to" )
      ENDIF
      SET PRINTER TO
   ELSEIF cKom == "LPT2"
      Set( 24, "lpt2", .F. )
   ELSE
      IF gnDebug >= 5
         MsgBeep( "set printer to (cKom) " + AllTrim( cKom ) )
      ENDIF
      SET PRINTER TO ( cKom )
   ENDIF
   IF gnDebug >= 5
      MsgBeep( "SPrint2(), set printer to (cKom)##var cKom=" + AllTrim( cKom ) + "##var cDDir=" + AllTrim( cDDir ) )
   ENDIF
   SET PRINTER ON
   Set( _SET_DEFAULT, cDDir )
   INI

   RETURN .T.


FUNCTION EPrint2( xPos )

   PRIVATE cPom

   IF gPrinter == "R"
      RETURN end_print()
   ENDIF

   SET PRINTER TO
   SET PRINTER OFF
   SET CONSOLE ON
   SET DEVICE TO SCREEN
   SET PRINTER TO

   IF gPPort $ "89"
      cKom := my_home() + cFName
      IF gnDebug >= 5
         MsgBeep( "EPrint2(), var cKom=" + AllTrim( cKom ) )
      ENDIF
      IF gPPort $ "89"
         SAVE SCREEN TO cS
         cKom := cKom + " LPT"
         IF gPPort == "8"
            cKom += "1"
         ELSE
            cKom += "2"
         ENDIF
         cPom := cKom
         IF gnDebug >= 5
            MsgBeep( "before !copy cPom##var cKom=" + AllTrim( cKom ) + "##var cPom=" + AllTrim( cPom ) )
            MsgBeep( "Pocni stampu" )
         ENDIF

         !COPY &cPom

         IF gnDebug >= 5
            MsgBeep( "Zavrsio stampu! Vracam screen!" )
         ENDIF

         RESTORE SCREEN FROM cS

      ENDIF
   ENDIF

   // LPT1, LPT2 ...
   IF gOpSist $ "W2000WXP"
      SAVE SCREEN TO cS
      cPom := EXEPATH + "dummy.txt"
      !COPY &cPom
      RESTORE SCREEN FROM cS
   ENDIF

   IF gnDebug >= 5
      cPom := EXEPATH + "dummy.txt"
      MsgBeep( AllTrim( cPom ) )
      !COPY &cPom
   ENDIF

   f18_tone( 440, 2 )
   f18_tone( 440, 2 )
   Msg( "Stampanje zavrseno. Pritisnite bilo koju tipku za nastavak rada!",  15, xPos )

   RETURN .T.


// ------------------------------------------
// PPrint()
// Podesenja parametara stampaca
// ------------------------------------------
FUNCTION PPrint()

   LOCAL fUsed := .F.
   LOCAL ch
   LOCAL cSekvence := "N"
   LOCAL nPStranica := dodatni_redovi_po_stranici()

   PushWA()

   set_cursor_on()

   SetKey( K_SH_F2, NIL )
   SetKey( k_alt_r(), {|| UzmiPPr(), AEval( GetList, {| o | o:display() } ) } )
   PRIVATE GetList := {}

   o_gparams()
   SELECT 99
   IF Used()
      fUsed := .T.
   ELSE
      o_params()
   ENDIF

   PRIVATE cSection := "1", cHistory := " "; aHistory := {}
   RPAR( "px", @gPrinter )

   Box(, 3, 65 )
   set_cursor_on()
   info_bar( "info", "<a-R> - preuzmi parametre štampača" )
   @ box_x_koord() + 1, box_y_koord() + 2  SAY8 "TEKUCI STAMPAC:"
   @ box_x_koord() + 1, Col() + 4  GET  gPrinter PICT "@!"
   @ box_x_koord() + 3, box_y_koord() + 2 SAY "Pregled sekvenci ?"
   @ box_x_koord() + 3, Col() + 2 GET cSekvence VALID csekvence $ "DN" PICT "@!"
   READ
   Boxc()
   info_bar( "info", "<a-R> - preuzmi parametre štampača" )

   IF Empty( gPPort )
      gPPort := "1"
   ENDIF


   Box(, 23, 65 )

   IF gPrinter == "*"
      SELECT gparams // parametri stampaca
      cSection := "P"
      SEEK cSection
      DO WHILE !Eof() .AND. cSection == sec
         cH := h
         DO WHILE !Eof() .AND. cSection == sec .AND. ch == h
            SKIP
         ENDDO
         AAdd( aHistory, { ch } )
      ENDDO
      IF Len( aHistory ) > 0
         gPrinter := ( ABrowse( aHistory, 10, 1, {| ch |  HistUser( ch ) } ) )[ 1 ]
      ELSE
         gPrinter := " "
      ENDIF
      SELECT params
      cSection := "1"
   ENDIF
   WPar( "px", gPrinter )

   SELECT gparams

   PRIVATE cSection := "P"
   PRIVATE cHistory := gPrinter
   PRIVATE aHistory := {}
   Rpar_Printer()
   All_GetPstr()

   SET KEY K_CTRL_P TO  PSeqv()
   @ box_x_koord() + 3, box_y_koord() + 2  SAY "INI          " GET gPINI    PICT "@S40"
   @ box_x_koord() + 4, box_y_koord() + 2  SAY "Kond. -17cpi " GET gPCOND   PICT "@S40"
   @ box_x_koord() + 5, box_y_koord() + 2  SAY "Kond2.-20cpi " GET gPCond2  PICT "@S40"
   @ box_x_koord() + 6, box_y_koord() + 2  SAY "CPI 10       " GET gP10cpi PICT "@S40"
   @ box_x_koord() + 7, box_y_koord() + 2  SAY "CPI 12       " GET gP12CPI PICT "@S40"
   @ box_x_koord() + 8, box_y_koord() + 2  SAY "Bold on      " GET gPB_ON   PICT "@S40"
   @ box_x_koord() + 9, box_y_koord() + 2  SAY "Bold off     " GET gPB_OFF  PICT "@S40"
   @ box_x_koord() + 10, box_y_koord() + 2 SAY "Podvuceno on " GET gPU_ON   PICT "@S40"
   @ box_x_koord() + 11, box_y_koord() + 2 SAY "Podvuceno off" GET gPU_OFF  PICT "@S40"
   @ box_x_koord() + 12, box_y_koord() + 2 SAY "Italic on    " GET gPI_ON    PICT "@S40"
   @ box_x_koord() + 13, box_y_koord() + 2 SAY "Italic off   " GET gPI_OFF   PICT "@S40"
   @ box_x_koord() + 14, box_y_koord() + 2 SAY "Nova strana  " GET gPFF     PICT "@S40"
   @ box_x_koord() + 15, box_y_koord() + 2 SAY "Portret      " GET gPO_Port     PICT "@S40"
   @ box_x_koord() + 16, box_y_koord() + 2 SAY "Lendskejp    " GET gPO_Land     PICT "@S40"
   @ box_x_koord() + 17, box_y_koord() + 2 SAY "Red.po l./nor" GET gRPL_Normal  PICT "@S40"
   @ box_x_koord() + 18, box_y_koord() + 2 SAY "Red.po l./gus" GET gRPL_Gusto   PICT "@S40"
   @ box_x_koord() + 21, box_y_koord() + 2 SAY "Dodatnih redova +/- u odnosu na A4 format " GET nPStranica PICT "999"
   @ box_x_koord() + 23, box_y_koord() + 2 SAY "LPT 1/2/3    " GET gPPort   VALID gPPort $ "12356789"
   gPPTK := PadR( gPPTK, 2 )
   @ box_x_koord() + 23, Col() + 2 SAY "Konverzija" GET gPPTK PICT "@!" VALID subst( gPPTK, 2, 1 ) $ " 1"
   IF csekvence == "D"
      READ
   ENDIF
   SET KEY K_CTRL_P TO
   BoxC()


   WPAR( "01", Odsj( @gPINI ) )
   WPAR( "02", Odsj( @gPCOND ) )
   WPAR( "03", Odsj( @gPCOND2 ) )
   WPAR( "04", Odsj( @gP10cpi ) )
   WPAR( "05", Odsj( @gP12cpi ) )
   WPAR( "06", Odsj( @gPB_ON ) )
   WPAR( "07", Odsj( @gPB_OFF ) )
   WPAR( "08", Odsj( @gPI_ON ) )
   WPAR( "09", Odsj( @gPI_OFF ) )
   WPAR( "11", Odsj( @gPFF ) )
   WPAR( "12", Odsj( @gPU_ON ) )
   WPAR( "13", Odsj( @gPU_OFF ) )

   WPAR( "14", Odsj( @gPO_Port ) )
   WPAR( "15", Odsj( @gPO_Land ) )
   WPAR( "16", Odsj( @gRPL_Normal ) )
   WPAR( "17", Odsj( @gRPL_Gusto ) )

   IF Empty( gPPort )
      gPPort := "1"
   ENDIF
   WPar( "PP", gPPort )


   Wpar( "pt", gPPTK )

   dodatni_redovi_po_stranici( nPStranica )

   SELECT gparams
   USE

   SELECT params
   IF !fUsed
      SELECT params
      USE
   ENDIF

   SetKey( K_SH_F2, {|| PPrint() } )
   SetKey( k_alt_r(), NIL )
   PopWa()

   IF !Empty( gPPTK )
      SetGParams( "1", " ", "pt", "gPTKonv", gPPTK )
   ENDIF

   RETURN .T.


STATIC FUNCTION UzmiPPr( cProc, nline, cVar )

   LOCAL cOzn := " ", GetList := {}

   Box(, 1, 77 )
   @ box_x_koord() + 1, box_y_koord() + 2 SAY "Ukucajte oznaku stampaca cije parametre zelite preuzeti:" GET cOzn
   READ
   IF LastKey() != K_ESC
      SELECT gparams
      PRIVATE cSection := "P", cHistory := cOzn; aHistory := {}
      RPar_Printer()
      All_GetPstr()
   ENDIF
   BoxC()

   RETURN

// --------------------------------------------
// --------------------------------------------
STATIC FUNCTION PSeqv( cProc, nLine, cVar )

   Box(, 1, 70 )

   @ box_x_koord() + 1, box_y_koord() + 2 SAY Odsj( &cVar )

   Inkey()

   BoxC()

   RETURN


FUNCTION GetPStr( cStr, nDuzina )

   LOCAL i
   LOCAL cPom := ""
   LOCAL cNum
   LOCAL fSl

   IF nDuzina == NIL
      nDuzina := 60
   ENDIF

   fSL := .F.

   FOR i := 1 TO Len( cStr )

      cNum := SubStr( cStr, i, 1 )

      // slova
      IF Asc( cNum ) >= 33 .AND. Asc( cNum ) <= 126
         IF fSl  // proslo je bilo slovo
            cPom := Left( cPom, Len( cPom ) - 1 ) + cNum + SLASH
         ELSE
            cPom += "'" + cNum + SLASH
         ENDIF
         fSl := .T.
      ELSE
         cPom += AllTrim( Str( Asc( cNum ), 3 ) ) + SLASH
         fSl := .F.
      ENDIF

   NEXT

   RETURN PadR( cPom, nDuzina )

// ----------------------------------------------
// * nZnak  - broj znakova u redu
// * cPapir - "4" za A4, ostalo za A3
// -----------------------------------------------
FUNCTION GuSt( nZnak, cPapir )

   IF cPapir == "POS"
      RETURN gP12cpi
   ENDIF

   nZnak = IF( cPapir == "4", nZnak * 2 - 1, nZnak )

   RETURN iif( nZnak < 161, gP10cpi, iif( nZnak < 193, gP12cpi, iif( nZnak < 275, gPCOND, gPCond2 ) ) )

/*
* nZnak  - broj znakova u redu
* cPapir - "4" za A4, ostalo za A3
*/

FUNCTION GuSt2( nZnak, cPapir )

   IF cPapir == "POS"
      RETURN gP12cpi()
   ENDIF

   IF cPapir == "4"
      nZnak := nZnak * 2 - 1
   ELSE
      IF  cPapir == "L4"
         nZnak := nZnak * 1.4545 - 1
      ENDIF
   ENDIF

   IF nZnak < 161
      RETURN gP10cpi()
   ELSE
      IF nZnak < 193
         RETURN gP12cpi()
      ELSE
         IF nZnak < 275
            gPCOND()
         ELSE
            gPCond2()
         ENDIF
      ENDIF
   ENDIF

FUNCTION Odsj( cStr )

   LOCAL nPos, cPom, cnum

   cPom := ""
   DO WHILE .T.
      nPos := At( SLASH, cStr )
      IF nPos == 0
         EXIT
      ENDIF
      cNum := Left( cStr, nPos - 1 )

      IF Left( cNum, 1 ) = "'" // oblik '(s<ESC>    => (s

         cPom += SubStr( cNum, 2 )
      ELSE // oblik 027<ESC>    => Chr(27)

         cPom += Chr( Val( cNum ) )
      ENDIF

      cStr := SubStr( cStr, nPos + 1 )
   ENDDO
   cStr := cPom

   RETURN cPom
