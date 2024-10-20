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


// -------------------------------------------------------
// import dokumenta iz txt fajla sa barkod terminala
// -------------------------------------------------------
FUNCTION fakt_import_bterm()

   LOCAL nRet
   LOCAL cFile

   // importuj podatke u pomocnu tabelu TEMP.DBF
   nRet := barkod_terminal_import_sa_terminala( @cFile )

   IF nRet == 0
      RETURN .F.
   ENDIF


   bterm_to_fakt_priprema()    // prebaci podatke u pripremu FAKT

   // pobrisi txt fajl
   kalk_imp_brisi_txt( cFile, .T. )

   RETURN .T.



FUNCTION fakt_export_bterm()

   LOCAL nRet

   nRet := barkod_terminal_export_artikle_na_terminal()

   RETURN .T.


// -----------------------------------------------
// kopira TEMP.DBF -> PRIPR.DBF
// -----------------------------------------------
STATIC FUNCTION bterm_to_fakt_priprema()

   LOCAL aParams := {}
   LOCAL nCnt := 0
   LOCAL cSave

   PRIVATE cTipVPC := "1"

   //o_fakt_doks_dbf()
   o_fakt_pripr()
   //o_fakt_dbf()
   //o_roba()
   //o_rj()
   //o_partner()

   SELECT ( F_TMP_1 )
   USE

   my_use_temp( "temp", my_home() + my_dbf_prefix() + "temp" )

   IF _gForm( @aParams ) = 0
      RETURN 0
   ENDIF

   // sacuvaj parametar cijene
   cSave := g13dcij

   // setuj tip cijene koja se koristi
   g13dcij := AllTrim( aParams[ 12 ] )

   SELECT temp
   // idroba
   SET ORDER TO TAG "1"
   GO TOP

   DO WHILE !Eof()

      cTrm_roba := field->idroba
      nTrm_qtty := 0

      // saberi iste artikle
      DO WHILE !Eof() .AND. field->idroba == cTrm_roba
         nTrm_qtty += field->kolicina
         SKIP
      ENDDO

      // imam konacan artikal
      SELECT fakt_pripr
      APPEND BLANK

      scatter()

      _idfirma := aParams[ 2 ]
      _idtipdok := aParams[ 3 ]
      _brdok := aParams[ 4 ]
      _datdok := aParams[ 5 ]
      _rbr := Str( ++nCnt, 3 )
      _idroba := cTrm_roba
      _kolicina := nTrm_qtty
      _idpartner := aParams[ 8 ]
      _dindem := "KM "
      _zaokr := 2
      _txt := "" // fakt_txt

      // ovo setuje cijenu
      fakt_v_kolicina( "1" )
      SELECT fakt_pripr

      // 1 roba tip U - nista
      fakt_add_to_public_var_txt_uokviri_sa_chr16_chr17( "", .T. )
      // 2 dodatni tekst otpremnice - nista
      fakt_add_to_public_var_txt_uokviri_sa_chr16_chr17( "", .T. )
      // 3 naziv partnera
      fakt_add_to_public_var_txt_uokviri_sa_chr16_chr17( aParams[ 9 ], .T. )
      // 4 adresa
      fakt_add_to_public_var_txt_uokviri_sa_chr16_chr17( aParams[ 10 ], .T. )
      // 5 ptt i mjesto
      fakt_add_to_public_var_txt_uokviri_sa_chr16_chr17( aParams[ 11 ], .T. )
      // 6 broj otpremnice
      fakt_add_to_public_var_txt_uokviri_sa_chr16_chr17( "", .T. )
      // 7 datum  otpremnice
      fakt_add_to_public_var_txt_uokviri_sa_chr16_chr17( DToC( aParams[ 6 ] ), .T. )
      // 8 broj ugovora - nista
      fakt_add_to_public_var_txt_uokviri_sa_chr16_chr17( "", .T. )
      // 9 datum isporuke - nista
      fakt_add_to_public_var_txt_uokviri_sa_chr16_chr17( DToC( aParams[ 7 ] ), .T. )
      // 10 datum valute - nista
      fakt_add_to_public_var_txt_uokviri_sa_chr16_chr17( "", .T. )

      gather()

      SELECT temp

   ENDDO

   // vrati parametar cijene
   g13dcij := cSave

   MsgBeep( "Kreiran je novi dokument i nalazi se u pripremi." )

   RETURN 1



// -----------------------------------------------
// forma uslova prenosa
// -----------------------------------------------
STATIC FUNCTION _gForm( aParam )

   LOCAL GetList := {}
   LOCAL nX := 1
   LOCAL cVpMp := "1"
   LOCAL cFirma := self_organizacija_id()
   LOCAL cTipDok := Space( 2 )
   LOCAL cBrDok := Space( 8 )
   LOCAL cPartner := Space( 6 )
   LOCAL dDatdok := Date()
   LOCAL dDatOtpr := Date()
   LOCAL dDatIsp := Date()
   LOCAL nTArea := Select()
   LOCAL cGen := "D"
   LOCAL cMPCSet := " "

   Box(, 15, 67 )

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Generisanje podataka iz barkod terminala:"

   ++nX
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "(1) Veleprodaja"

   ++nX

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "(2) Maloprodaja" GET cVpMp VALID cVpMp $ "12"
   READ

   ++ nX
   ++ nX

   // datum dokumenta

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Datum dok.:" GET dDatDok
   @ box_x_koord() + nX, Col() + 1 SAY "Datum otpr.:" GET dDatOtpr
   @ box_x_koord() + nX, Col() + 1 SAY "Datum isp.:" GET dDatIsp

   ++ nX
   ++ nX

   // vrsta i broj dokumenta

   // koji je tip dokumenta
   cTipDok := _gtdok( cVpMp )

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Dokument broj:" GET cFirma
   @ box_x_koord() + nX, Col() + 1 SAY "-" GET cTipDok ;
      VALID _nBrDok( cFirma, cTipDok, @cBrDok )
   @ box_x_koord() + nX, Col() + 1 SAY "-" GET cBrDok

   ++nX
   ++nX

   // partner
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Partner:" GET cPartner ;
      VALID Empty( cPartner ) .OR. p_partner( @cPartner )

   ++ nX
   ++ nX

   IF cVpMp == "2"

      // tip cijena
      @ box_x_koord() + nX, box_y_koord() + 2 SAY "Koristiti MPC ( /1/2/3...)"  GET cMPCSet VALID cMPCSet $ " 123456"
      ++ nX
      ++ nX

   ENDIF

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Izvrsiti transfer (D/N)?" GET cGen  VALID cGen $ "DN" PICT "@!"

   READ
   BoxC()

   IF cGen == "N"
      RETURN 0
   ENDIF

   IF LastKey() <> K_ESC

      // snimi parametre
      // [1]
      AAdd( aParam, cVpMp )
      // [2]
      AAdd( aParam, cFirma )
      // [3]
      AAdd( aParam, cTipDok )
      // [4]
      AAdd( aParam, cBrDok )
      // [5]
      AAdd( aParam, dDatDok )
      // [6]
      AAdd( aParam, dDatOtpr )
      // [7]
      AAdd( aParam, dDatIsp )
      // [8]
      AAdd( aParam, cPartner )

      select_o_partner( cPartner )

      // [9]
      AAdd( aParam, AllTrim( field->naz ) )
      // [10]
      AAdd( aParam, AllTrim( field->adresa ) )
      // [11]
      AAdd( aParam, AllTrim( field->ptt ) )

      // [12]
      AAdd( aParam, cMPCSet )

   ELSE
      RETURN 0
   ENDIF

   SELECT ( nTArea )

   RETURN 1


// -----------------------------------------------
// vraca novi broj dokumenta
// -----------------------------------------------
STATIC FUNCTION _nBrDok( cFirma, cTip, cBrDok )

   cBrDok := PadR( Replicate( "0", gNumDio ), 8 )

   RETURN .T.


// -------------------------------------------------
// vraca tip dokumenta na osnovu tipa importa
// -------------------------------------------------
STATIC FUNCTION _gTdok( cTip )

   LOCAL cRet := ""

   DO CASE
   CASE cTip == "1"
      // veleprodaja - direktno racun
      cRet := "10"
   CASE cTip == "2"
      // maloprodaja
      cRet := "13"
   ENDCASE

   RETURN cRet
