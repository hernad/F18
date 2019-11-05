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


PROCEDURE set_global_vars_0()

#ifdef F18_DEBUG

   ?E "set_global_vars_0"
#endif
   PUBLIC ZGwPoruka := ""
   PUBLIC GW_STATUS := "-"
   PUBLIC GW_HANDLE := 0
   PUBLIC gModul := ""

   PUBLIC ZGwPoruka := ""
   PUBLIC GW_STATUS := "-"
   PUBLIC GW_HANDLE := 0
   PUBLIC gProcPrenos := "N"
   PUBLIC gInstall := .F.
   // PUBLIC gfKolor := "D"
   PUBLIC gPrinter := "R"
   PUBLIC gPtxtSw := nil
   PUBLIC gPDFSw := nil
   PUBLIC gPregledSifriIzMenija := .F.
   PUBLIC gValIz := "280 "
   PUBLIC gValU := "000 "
   PUBLIC gKurs := "1"
   PUBLIC gPTKONV := "0 "
   PUBLIC gcDirekt := "V"
   PUBLIC gSKSif := "D"
   PUBLIC gSezona := "    "
   PUBLIC gShemaVF := "B5"

   //PUBLIC m_x
   //PUBLIC m_y

   PUBLIC h[ 20 ]
   PUBLIC lInstal := .F.
   PUBLIC aRel := {}
   PUBLIC cDirRad
   PUBLIC cDirSif
   PUBLIC cDirPriv
   PUBLIC gNaslov
   PUBLIC gSezonDir := ""
   PUBLIC gRadnoPodr := "RADP"
   PUBLIC ImeKorisn := ""
   PUBLIC SifraKorisn := ""
   PUBLIC g_cUserLevel := "3"
   PUBLIC gArhDir := ""
   PUBLIC gPFont := "Arial"
   PUBLIC gKodnaS := "8"
   PUBLIC g50f := " "
   PUBLIC System := .F.

   PUBLIC cBteksta
   PUBLIC cBokvira
   
   PUBLIC cBshema := "B1"

   //PUBLIC gPDFPrint := "N"
   PUBLIC gPDFPAuto := "D"
   PUBLIC gPDFViewer := Space( 150 )
   PUBLIC gDefPrinter := Space( 150 )

   PUBLIC gPicDem := "9999999.99"
   PUBLIC gPicBHD := "999999999999.99"

   PUBLIC gRavnot := "D"
   PUBLIC gDatNal := "N"
   PUBLIC gSAKrIz := "N"
   PUBLIC gBezVracanja := "N"
   //PUBLIC gBuIz := "N"
   PUBLIC gFinRj := "N"
   PUBLIC gFinFunkFond := "N"
   PUBLIC gVSubOp := "N"
   PUBLIC gnLMONI := 120
   PUBLIC gKtoLimit := "N"
   PUBLIC gnKtoLimit := 3
   //PUBLIC gDugiUslovFirmaRJFinSpecif := "N"
   PUBLIC gBrojacFinNaloga := "1"
   PUBLIC gDatVal := "D"
   PUBLIC gnLOSt := 0
   PUBLIC gPotpis := "N"
   PUBLIC gnKZBDana := 0
   PUBLIC gAzurTimeOut := 120
   PUBLIC g_knjiz_help := "N"
   PUBLIC gMjRj := "N"

   PUBLIC gFinRj         := "N"
   PUBLIC gOModul     := NIL
   PUBLIC cDirPriv    := ""
   PUBLIC cDirRad     := ""
   PUBLIC cDirSif     := ""
   PUBLIC glBrojacPoKontima := .T.

   // init_print_variables() // setuje globalne varijable printera
   set_ptxt_sekvence()
   set_global_vars_roba()

#ifdef F18_DEBUG
   ?E "set_global_vars_0 end"
#endif

   RETURN


FUNCTION set_ptxt_sekvence()

   PUBLIC gpIni :=  "#%INI__#"
   PUBLIC gpCOND := "#%KON17#"
   PUBLIC gpCOND2 := "#%KON20#"
   PUBLIC gp10CPI := "#%10CPI#"
   PUBLIC gP12CPI := "#%12CPI#"
   PUBLIC gPB_ON := "#%BON__#"
   PUBLIC gPB_OFF := "#%BOFF_#"
   PUBLIC gPU_ON := "#%UON__#"
   PUBLIC gPU_OFF := "#%UOFF_#"
   PUBLIC gPI_ON := "#%ION__#"
   PUBLIC gPI_OFF := "#%IOFF_#"
   PUBLIC gPFF   := "#%NSTR_#"
   PUBLIC gPO_Port := "#%PORTR#"
   PUBLIC gPO_Land := "#%LANDS#"
   PUBLIC gPPort := "1"
   PUBLIC gRPL_Normal := ""
   PUBLIC gRPL_Gusto := ""
   PUBLIC gPPTK := " "

   RETURN .T.


FUNCTION set_0_sekvence()

   PUBLIC gpIni :=  ""
   PUBLIC gpCOND := ""
   PUBLIC gpCOND2 := ""
   PUBLIC gp10CPI := ""
   PUBLIC gP12CPI := ""
   PUBLIC gPB_ON := ""
   PUBLIC gPB_OFF := ""
   PUBLIC gPU_ON := ""
   PUBLIC gPU_OFF := ""
   PUBLIC gPI_ON := ""
   PUBLIC gPI_OFF := ""
   PUBLIC gPFF   := ""
   PUBLIC gPO_Port := ""
   PUBLIC gPO_Land := ""
   PUBLIC gPPort := "1"
   PUBLIC gRPL_Normal := ""
   PUBLIC gRPL_Gusto := ""
   PUBLIC gPPTK := " "

   RETURN .T.

FUNCTION set_global_vars_1()

   LOCAL cImeDbf

   info_bar( "vars", "set_global_vars_1" )

   create_gparams()

   PUBLIC gSezonDir := ""
   PUBLIC gRadnoPodr := "RADP"
   PUBLIC ImeKorisn := ""
   PUBLIC SifraKorisn := ""
   PUBLIC gPTKONV := "0 "
   PUBLIC gcDirekt := "V", gShemaVF := "B5", gSKSif := "D"
   PUBLIC gKodnaS := "8"
   PUBLIC g50f := " "
   // PUBLIC gFKolor := "D"

   o_gparams()
   PRIVATE cSection := "1", cHistory := " "; aHistory := {}

   Rpar( "pt", @gPTKonv )
   Rpar( "SK", @gSKSif )
   Rpar( "DO", @gcDirekt )
   Rpar( "SB", @gShemaVF )
   Rpar( "Ad", @gArhDir )
   Rpar( "FO", @gPFont )
   Rpar( "KS", @gKodnaS )
   Rpar( "5f", @g50f )
   //Rpar( "pR", @gPDFPrint )
   Rpar( "pV", @gPDFViewer )
   Rpar( "pA", @gPDFPAuto )
   Rpar( "dP", @gDefPrinter )
   // Rpar( "FK", @gFKolor )

   SELECT ( F_GPARAMS )
   USE

   RETURN NIL



FUNCTION set_global_vars_2()

   info_bar( "init", "set global_vars_2 - start" )

   init_printer()

   PUBLIC gOznVal := "KM"

   //PUBLIC gBaznaV := "D"
   PUBLIC gZaokr := 2
   PUBLIC gTabela := 0
   PUBLIC gPDV := "D"
   PUBLIC gMjStr := PadR( "Sarajevo", 30 )
   PUBLIC gModemVeza := "N"


   PUBLIC gPartnBlock
   gPartnBlock := nil

   PUBLIC gSecurity := "D"
   PUBLIC gnDebug := 0
   PUBLIC gOpSist := "-"

   info_bar( "init", "set global_vars_2 - end" )

   RETURN .T.



FUNCTION set_global_vars_roba()

   //PUBLIC gUVarPP
   //PUBLIC gRobaBlock
   PUBLIC gPicProc

   // PUBLIC gFPicCDem
   // PUBLIC gFPicDem
   // PUBLIC gFPicKol

   PUBLIC gDuzSifIni

   PUBLIC glPoreziLegacy
   PUBLIC glUgost
   PUBLIC gUgostVarijanta

   // R - Obracun porez na RUC
   // D - starija varijanta ???
   // N - obicno robno knjigovodstvo

   glPoreziLegacy := .T.
   glUgost := .F.

   // RMarza_DLimit - osnovica realizovana marza ili donji limit
   // mpc_sa_pdv - Maloprodajna cijena sa porezom
   gUgostVarijanta := "Rmarza_DLimit"
   //gUVarPP := "N"
   //gRobaBlock := NIL


   gPicProc := "999999.99%"



   // gFPicCDem := "3"
   // gFPicDem := "3"
   // gFPicKol := "3"

   gDuzSifINI := "10"

   RETURN .T.




FUNCTION init_printer() // procitaj gPrinter, gpini,  postavi shift F2 kao hotkey

   info_bar( "init", "init printer seqs start" )

   IF gModul $ "EPDV"
      gPrinter := "R"
   ENDIF

   IF gPrinter == "E"
      set_epson_print_codes()
   ELSE
      set_ptxt_sekvence()
   ENDIF


   SetKey( K_SH_F2, {|| PPrint() } )
   info_bar( "init", "init printer seqs end" )

   RETURN .T.
