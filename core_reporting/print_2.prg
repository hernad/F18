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
#include "f18_color.ch"

MEMVAR /*GetList,*/ gModul

THREAD STATIC s_cF18Txt
THREAD STATIC s_xPrintOpt
THREAD STATIC s_cColor

STATIC s_nDodatniRedoviPoStranici
STATIC s_lConsole, s_cDevice, s_cPrinterFile, s_lPrinter


FUNCTION f18_start_print( cFileName, xPrintOpt, cDocumentName )

   LOCAL cMsg, nI, cLogMsg := ""
   LOCAL cOpt
   LOCAL oPDF
   LOCAL lBezParametara := .F.

   cFileName := set_print_file_name( cFileName )
   IF ( cDocumentName == NIL )
      cDocumentName :=  gModul + '_' + DToC( Date() )
   ENDIF

   IF xPrintOpt == NIL  // poziv bez parametara
      lBezParametara := .T.
   ENDIF

   IF ValType( xPrintOpt ) == "H"
      cOpt := xPrintOpt[ "tip" ]
   ELSEIF ValType( xPrintOpt ) == "C"
      cOpt := xPrintOpt
   ELSE
      cOpt := "V"
   ENDIF

   set_ptxt_sekvence()
   IF !( cOpt == "PDF" .OR. cOpt == "D" .OR. cOpt $ "EFG" .OR. cOpt == "0" ) // pdf, direktna stampa, interni editor, bez dijaloga
      cOpt := print_dialog_box( cOpt )
      IF cOpt == "X"
         RETURN cOpt
      ENDIF
   ENDIF

   set_print_codes( cOpt )
   //PRIVATE GetList := {}

#ifdef F18_DEBUG_PRINT
   LOG_CALL_STACK cLogMsg
   Alert ( cLogMsg )
#endif

   MsgO( "Priprema " + iif( cOpt == "PDF", "PDF", "tekst" ) + " izvještaja ..." )

   LOG_CALL_STACK cLogMsg
   SetPRC( 0, 0 )
   s_lConsole := Set( _SET_CONSOLE, .F. )
   // SET PRINTER OFF
   s_cDevice := Set( _SET_DEVICE, "PRINTER" )
   s_cPrinterFile := Set( _SET_PRINTFILE, cFileName )
   s_lPrinter := Set( _SET_PRINTER, .T. )

   IF cOpt != "PDF"
      GpIni( cDocumentName )
   ELSE
      download_template_ubuntu_mono_ttf()
      hb_cdpSelect( "SLWIN" )
      oPDF := xPrintOpt[ "opdf" ]
      oPDF:cFileName := txt_print_file_name()
      oPDF:cHeader := hb_UTF8ToStr( cDocumentName )
      IF xPrintOpt[ "layout" ] == "portrait"
         oPDF:SetType( PDF_TXT_PORTRAIT )
      ELSE
         oPDF:SetType( PDF_TXT_LANDSCAPE )
      ENDIF
      IF hb_HHasKey( xPrintOpt, "font_size" )
         oPDF:SetFontSize( xPrintOpt[ "font_size" ] )
      ENDIF
      oPDF:Begin()
      oPDF:PageHeader()
   ENDIF

   my_use_refresh_stop()

   IF lBezParametara
      s_xPrintOpt := cOpt // ovo ce koristiti f18_end_print
   ENDIF

   RETURN cOpt


STATIC FUNCTION set_print_codes( cOpt )

   DO CASE

   CASE cOpt $ "E#F#G"

      gPrinter := "E"
      set_epson_print_codes()

   CASE cOpt == "0"
      gPrinter := "0"
      set_0_sekvence()

   OTHERWISE

      gPrinter := "R"
      set_ptxt_sekvence()

   ENDCASE

   RETURN .T.


FUNCTION f18_end_print( cFileName, xPrintOpt )

   LOCAL nRet
   LOCAL cCommand := ""
   LOCAL cKom
   LOCAL cPrinterPort
   LOCAL cOpt
   LOCAL oPDF

   IF cOpt == "PDF"
      // hb_cdpSelect( "SLWIN" )
      oPDF:End()
   ENDIF

   hb_cdpSelect( "SL852" )
   // hb_SetTermCP( "SLISO" )

   IF xPrintOpt == NIL  // poziv bez parametara
      xPrintOpt := s_xPrintOpt
   ENDIF

   IF xPrintOpt == NIL
      cOpt := "V"
   ENDIF

   IF ValType( xPrintOpt ) == "C"
      cOpt := xPrintOpt
   ENDIF

   IF ValType( xPrintOpt ) == "H"
      cOpt := xPrintOpt[ "tip" ]
      IF cOpt == "PDF"
         oPDF := xPrintOpt[ "opdf" ]
      ENDIF
   ENDIF

   cPrinterPort := get_printer_port( cOpt )
   cFileName := txt_print_file_name( cFileName )

   // SET DEVICE TO SCREEN
   // SET PRINTER OFF
   // SET PRINTER TO
   // SET CONSOLE ON
   Set( _SET_CONSOLE, s_lConsole )
   Set( _SET_DEVICE, s_cDevice )
   IF ValType(s_cPrinterFile) == "C"
      Set( _SET_PRINTFILE, s_cPrinterFile )
   ENDIF
   Set( _SET_PRINTER, s_lPrinter  )

   MsgC()

   f18_tone( 440, 2 )
   f18_tone( 440, 2 )


   DO CASE

   CASE cOpt == "D"
      // priprema za email

   CASE cOpt == "P"
      txt_izvjestaj_podrska_email( cFileName )

   CASE cOpt $ "E#F#G" // direct print
      IF is_windows()
         direct_print_windows( cFileName, cPrinterPort )
      ELSE
         direct_print_unix( cFileName, cPrinterPort )
      ENDIF

   CASE cOpt == "PDF"

      oPDF := PDFClass():New()
      IF xPrintOpt[ "layout" ] == "portrait"
         oPDF:SetType( PDF_PORTRAIT )
      ELSE
         oPDF:SetType( PDF_LANDSCAPE )
      ENDIF
      IF hb_HHasKey( xPrintOpt, "left_space" )
         oPDF:SetLeftSpace( xPrintOpt[ "left_space" ] )
      ENDIF
      IF hb_HHasKey( xPrintOpt, "font_size" )
         oPDF:SetFontSize( xPrintOpt[ "font_size" ] )
      ENDIF
      oPDF:cFileName := StrTran( txt_print_file_name(), ".txt", ".pdf" )
      oPDF:Begin()
      oPDF:PrnToPdf( txt_print_file_name() )
      oPDF:End()

      hb_cdpSelect( "SL852" )
      // hb_SetTermCP( "SLISO" )
      oPDF:View()

   CASE cOpt == "R"

      Ptxt( cFileName )

   CASE cOpt == "0"
      RETURN editor( cFileName )

   OTHERWISE

      nRet := f18_editor( cFileName )
      IF nRet <> 0
         MsgBeep ( "f18_editor (" + cFileName + ") ERROR ?!" )
      ENDIF
   END CASE


   my_use_refresh_start()

   RETURN .T.


FUNCTION start_print_editor()

   info_bar( "edit", "<ESC> izlaz iz pregleda dokumenta" )
   s_cColor := SetColor( F18_COLOR_NORMAL_BW )

   RETURN start_print( "0" )


FUNCTION start_print( xPrintOpt, lCloseDbf )

   LOCAL cDocumentName

   hb_default( @lCloseDbf, .F. )

   IF HB_ISHASH( xPrintOpt ) .AND. hb_HHasKey( xPrintOpt, "header" )
      cDocumentName := xPrintOpt[ "header" ]
   ENDIF

   IF  f18_start_print( NIL, @xPrintOpt, cDocumentName ) == "X"
      IF lCloseDbf
         my_close_all_dbf()
      ENDIF
      RETURN .F.
   ENDIF

   RETURN .T.


FUNCTION end_print_editor()

   LOCAL lRet

   lRet := f18_end_print( NIL, "0" )
   SetColor( s_cColor )
   info_bar( "edit", "" )

   RETURN lRet


FUNCTION end_print( xPrintOpt )

   RETURN f18_end_print( NIL, xPrintOpt )


STATIC FUNCTION get_printer_port( xPrintOpt )

   LOCAL cPrinterPort := "1"

   DO CASE
   CASE xPrintOpt == "E"
      cPrinterPort := "1"
   CASE xPrintOpt == "F"
      cPrinterPort := "2"
   CASE xPrintOpt == "G"
      cPrinterPort := "3"
   ENDCASE

   RETURN cPrinterPort


STATIC FUNCTION direct_print_unix( cFileName, cPrinterPortNumber )

   LOCAL cCommand
   LOCAL _printer := "epson"
   LOCAL cPrinterName
   LOCAL nError

   IF cPrinterPortNumber == NIL
      cPrinterPortNumber := "1"
   ENDIF

   cPrinterName := _printer + "_" + cPrinterPortNumber

   cCommand := "lpq -P " + cPrinterName + " | grep " + cPrinterName

   nError := f18_run( cCommand )
   IF nError <> 0
      MsgBeep( "Printer " + cPrinterName + " nije podešen !" )
      RETURN .F.
   ENDIF

   cCommand := "lpr -P "
   cCommand += cPrinterName + " "
   cCommand += cFileName

   nError := f18_run( cCommand )

   IF nError <> 0
      MsgBeep( "Greška sa direktnom štampom !" )
   ENDIF

   RETURN .T.


STATIC FUNCTION direct_print_windows( cFileName, cPrinterPortNumber )

   LOCAL cCommand
   LOCAL nError

   IF cPrinterPortNumber == NIL
      cPrinterPortNumber := "1"
   ENDIF

   cFileName := file_path_quote( cFileName )

   cCommand := "copy " + cFileName + " LPT" + cPrinterPortNumber
   nError := hb_run( cCommand ) // ovaj antikvitet koriste knjigovodstveni servisi

   IF nError <> 0
      MsgBeep( "Greška sa direktnom štampom !?##" + cCommand )
   ENDIF

   RETURN .T.


FUNCTION txt_print_file_name( cFileName )

   IF cFileName == nil
      RETURN s_cF18Txt
   ENDIF

   RETURN cFileName


STATIC FUNCTION set_print_file_name( cFileName )

   LOCAL cDir, hFile, cTempFile

   IF cFileName == NIL

      IF my_home() == NIL
         cDir := my_home_root()
      ELSE
         cDir := my_home()
      ENDIF

      IF ( hFile := hb_vfTempFile( @cTempFile, cDir, "F18_rpt_", ".txt" ) ) != NIL // hb_vfTempFile( @<cFileName>, [ <cDir> ], [ <cPrefix> ], [ <cExt> ], [ <nAttr> ] )
         hb_vfClose( hFile )
         cFileName := cTempFile
      ELSE
         cFileName := OUTF_FILE
      ENDIF

   ENDIF
   s_cF18Txt := cFileName

   RETURN cFileName




FUNCTION GpIni( cDocumentName )

   IF cDocumentName == NIL .OR. gPrinter <> "R"
      cDocumentName := ""
   ENDIF

   IF !is_legacy_ptxt()
      RETURN .F.
   ENDIF

   QQOut( gPini )

   IF !Empty( cDocumentName )
      QQOut( "#%DOCNA#" + cDocumentName )
   ENDIF

   RETURN .T.


FUNCTION gpPicH( nRows )

   LOCAL cPom

   IF nRows == nil
      nRows := 7
   ENDIF

   IF nRows > 0
      cPom := PadL( AllTrim( Str( nRows ) ), 2, "0" )

      QQOut( "#%PH0" + cPom + "#" )
   ENDIF

   RETURN .T.


FUNCTION gpPicF()

   IF !is_legacy_ptxt()
      RETURN .F.
   ENDIF
   QQOut( "#%PIC_F#" )

   RETURN .T.


FUNCTION gpCOND()

   IF !is_legacy_ptxt()
      RETURN .F.
   ENDIF
   QQOut( gpCOND )

   RETURN .T.

FUNCTION gpCOND2()

   IF !is_legacy_ptxt()
      RETURN .F.
   ENDIF
   QQOut( gpCOND2 )

   RETURN .T.

FUNCTION gp10CPI()

   IF !is_legacy_ptxt()
      RETURN .F.
   ENDIF
   QQOut( gP10CPI )

   RETURN .T.

FUNCTION gp12CPI()

   IF !is_legacy_ptxt()
      RETURN .T.
   ENDIF
   QQOut( gP12CPI )

   RETURN .T.

FUNCTION gpB_ON()

   IF !is_legacy_ptxt()
      RETURN .T.
   ENDIF
   QQOut( gPB_ON )

   RETURN .T.


FUNCTION gpB_OFF()

   IF !is_legacy_ptxt()
      RETURN .T.
   ENDIF
   QQOut( gPB_OFF )

   RETURN .T.

FUNCTION gpU_ON()

   IF !is_legacy_ptxt()
      RETURN .T.
   ENDIF
   QQOut( gPU_ON )

   RETURN .T.

FUNCTION gpU_OFF()

   IF !is_legacy_ptxt()
      RETURN .T.
   ENDIF
   QQOut( gPU_OFF )

   RETURN .T.

FUNCTION gpI_ON()

   IF !is_legacy_ptxt()
      RETURN .T.
   ENDIF
   QQOut( gPI_ON )

   RETURN .T.

FUNCTION gpI_OFF()

   IF !is_legacy_ptxt()
      RETURN .T.
   ENDIF
   QQOut( gPI_OFF )

   RETURN .T.



FUNCTION gpNR()

   QOut()

   RETURN .T.

FUNCTION gPFF()

   IF !is_legacy_ptxt()

      SetPRC( 0, 0 )
      RETURN .F.
   ENDIF
   QQOut( hb_eol() + gPFF )
   SetPRC( 0, 0 )

   RETURN .T.

FUNCTION gpO_Port()

   QQOut( gPO_Port )

   RETURN .T.

FUNCTION gpO_Land()

   QQOut( gPO_Land )

   RETURN .T.

FUNCTION gRPL_Normal()

   IF !is_legacy_ptxt()
      RETURN .T.
   ENDIF
   QQOut( gRPL_Normal )

   RETURN .T.

FUNCTION gRPL_Gusto()

   IF !is_legacy_ptxt()
      RETURN .T.
   ENDIF
   QQOut( gRPL_Gusto )

   RETURN .T.

FUNCTION RPar_Printer()

   IF !is_legacy_ptxt()
      RETURN .T.
   ENDIF
   RPAR( "01", @gPINI )
   RPAR( "02", @gPCOND )
   RPAR( "03", @gPCOND2 )
   RPAR( "04", @gP10CPI )
   RPAR( "05", @gP12CPI )
   RPAR( "06", @gPB_ON )
   RPAR( "07", @gPB_OFF )
   RPAR( "08", @gPI_ON )
   RPAR( "09", @gPI_OFF )
   RPAR( "11", @gPFF )
   RPAR( "12", @gPU_ON )
   RPAR( "13", @gPU_OFF )
   RPAR( "14", @gPO_Port )
   RPAR( "15", @gPO_Land )
   RPAR( "16", @gRPL_Normal )
   RPAR( "17", @gRPL_Gusto )
   RPAR( "PP", @gPPort )
   IF Empty( gPPort )
      gPPort := "1"
   ENDIF
   RPar( "pt", @gPPTK )

   RETURN .T.


FUNCTION WPar_Printer()

   IF !is_legacy_ptxt()
      RETURN .T.
   ENDIF
   WPAR( "01", gPINI )
   WPAR( "02", gPCOND )
   WPAR( "03", gPCOND2 )
   WPAR( "04", gP10CPI )
   WPAR( "05", gP12CPI )
   WPAR( "06", gPB_ON )
   WPAR( "07", gPB_OFF )
   WPAR( "08", gPI_ON )
   WPAR( "09", gPI_OFF )
   WPAR( "11", gPFF )
   WPAR( "12", gPU_ON )
   WPAR( "13", gPU_OFF )
   WPAR( "14", gPO_Port )
   WPAR( "15", gPO_Land )
   WPAR( "16", gRPL_Normal )
   WPAR( "17", gRPL_Gusto )
   WPAR( "PP", gPPort )
   WPar( "pt", gPPTK )

   RETURN .T.




FUNCTION set_epson_print_codes()

   gPIni := ""
   gPCond := "P"
   gPCond2 := "M"
   gP10CPI := "P"
   gP12CPI := "M"
   gPB_ON := "G"
   gPB_OFF := "H"
   gPI_ON := "4"
   gPI_OFF := "5"
   gPU_ON := "-1"
   gPU_OFF := "-0"
   gPPort := "1"
   gPPTK := "  "
   gPO_Port := ""
   gPO_Land := ""
   gRPL_Normal := "0"
   gRPL_Gusto := "3" + Chr( 24 )
   gPFF := Chr( 12 )

   RETURN .T.


FUNCTION InigHP()

   PUBLIC gPINI := Chr( 27 ) + "(17U(s4099T&l66F"
   PUBLIC gPCond := Chr( 27 ) + "(s4102T(s18H"
   PUBLIC gPCond2 := Chr( 27 ) + "(s4102T(s22H"
   PUBLIC gP10CPI := Chr( 27 ) + "(s4099T(s10H"
   PUBLIC gP12CPI := Chr( 27 ) + "(s4099T(s12H"
   PUBLIC gPB_ON := Chr( 27 ) + "(s3B"
   PUBLIC gPB_OFF := Chr( 27 ) + "(s0B"
   PUBLIC gPI_ON := Chr( 27 ) + "(s1S"
   PUBLIC gPI_OFF := Chr( 27 ) + "(s0S"
   PUBLIC gPU_ON := Chr( 27 ) + "&d0D"
   PUBLIC gPU_OFF := Chr( 27 ) + "&d@"
   PUBLIC gPFF := Chr( 12 )
   PUBLIC gPO_Port := "&l0O"
   PUBLIC gPO_Land := "&l1O"
   PUBLIC gRPL_Normal := "&l6D&a3L"
   PUBLIC gRPL_Gusto := "&l8D(s12H&a6L"

   RETURN .T.


FUNCTION All_GetPstr()

   gPINI       := GetPStr( gPINI   )
   gPCond      := GetPStr( gPCond  )
   gPCond2     := GetPStr( gPCond2 )
   gP10cpi     := GetPStr( gP10CPI )
   gP12cpi     := GetPStr( gP12CPI )
   gPB_ON      := GetPStr( gPB_ON   )
   gPB_OFF     := GetPStr( gPB_OFF  )
   gPI_ON      := GetPStr( gPI_ON   )
   gPI_OFF     := GetPStr( gPI_OFF  )
   gPU_ON      := GetPStr( gPU_ON   )
   gPU_OFF     := GetPStr( gPU_OFF  )
   gPFF        := GetPStr( gPFF    )
   gPO_Port    := GetPStr( gPO_Port    )
   gPO_Land    := GetPStr( gPO_Land    )
   gRPL_Normal := GetPStr( gRPL_Normal )
   gRPL_Gusto  := GetPStr( gRPL_Gusto  )

   RETURN .T.


FUNCTION SetGParams( cs, ch, cid, cvar, cval )

   LOCAL cPosebno := "N"
   //LOCAL GetList := {}

   PushWA()

   PRIVATE cSection := cs
   PRIVATE cHistory := ch
   PRIVATE aHistory := {}

   SELECT ( F_PARAMS )
   USE
   o_params()
   RPar( "p?", @cPosebno )
   SELECT params
   USE

   // IF cPosebno == "D"
   // SELECT ( F_GPARAMSP )
   // USE
// O_GPARAMSP
// ELSE
   SELECT ( F_GPARAMS )
   USE
   o_gparams()
// ENDIF

   &cVar := cVal
   Wpar( cId, &cVar )
   SELECT gparams
   USE
   PopWa()

   RETURN .T.


FUNCTION dodatni_redovi_po_stranici( nSet )

   IF nSet != NIL
      set_metric( "print_dodatni_redovi_po_stranici", NIL, nSet )
      s_nDodatniRedoviPoStranici := nSet
   ENDIF

   IF HB_ISNIL( s_nDodatniRedoviPoStranici )
      s_nDodatniRedoviPoStranici := fetch_metric( "print_dodatni_redovi_po_stranici", NIL, 0 )
   ENDIF

   RETURN s_nDodatniRedoviPoStranici



FUNCTION page_length()

   RETURN fetch_metric( "rpt_duzina_stranice", my_user(), 60 ) + dodatni_redovi_po_stranici()

FUNCTION page_length_landscape()

   RETURN page_length() - 20
