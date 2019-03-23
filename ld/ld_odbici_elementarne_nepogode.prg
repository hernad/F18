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

STATIC s_cTipPrimanja
STATIC s_nTipObracuna


FUNCTION ld_tip_primanja_el_nepogode()

   IF s_cTipPrimanja == NIL
      s_cTipPrimanja := fetch_metric( "ld_elementarne_nepogode_tippr", NIL, SPACE(2) )
   ENDIF

   RETURN s_cTipPrimanja


FUNCTION ld_tip_obracuna_el_nepogode()

   IF s_nTipObracuna == NIL
      s_nTipObracuna := fetch_metric( "ld_elementarne_nepogode_obracun_tip", NIL, 1 )
   ENDIF

   RETURN s_nTipObracuna


FUNCTION ld_obracunaj_odbitak_za_elementarne_nepogode( lNovi )

   LOCAL cTipPrimanja := ld_tip_primanja_el_nepogode()
   LOCAL lOk := .T.
   LOCAL nIznos := 0
   LOCAL cTmp

   IF EMPTY( cTipPrimanja )
      lOk := .F.
      RETURN lOk
   ENDIF

   nIznos := obracunaj_odbitak()

   cTmp := "_I" + PADL( cTipPrimanja, 2, "0" )

   IF nIznos == 0 .AND. Round( &cTmp, 2 ) == 0
      lOk := .F.
      RETURN lOk
   ENDIF

   IF nIznos <> 0
      nIznos := -nIznos
   ENDIF

   &cTmp := nIznos

   RETURN lOk



STATIC FUNCTION obracunaj_odbitak()

   LOCAL nX := 1
   LOCAL cTipPrimanja := ld_tip_primanja_el_nepogode()
   LOCAL nTipObracuna := ld_tip_obracuna_el_nepogode()
   LOCAL nProcIznos := 1
   LOCAL cOpcSt
   LOCAL lRadnikJeIzRs := .F.
   LOCAL cObr := "D"
   LOCAL nIznos := 0
   PRIVATE getList := {}

   cOpcSt := ld_iz_koje_opcine_je_radnik( _idradn )

   lRadnikJeIzRs := radnik_iz_rs( cOpcSt )

   IF lRadnikJeIzRs
      nProcIznos := 1.5
   ENDIF

   Box(, 7, 67 )

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "*** ODBITAK ZA ELEMENTARNE NEPOGODE"

   nX := nX + 2

   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Tip obračuna (1) procentualni iznos (2) jedna neto dnevnica" GET nTipObracuna PICT "9"

   READ

   IF LastKey() == K_ESC
      BoxC()
      RETURN nIznos
   ENDIF

   nX := nX + 2

   IF nTipObracuna == 1
      @ box_x_koord() + nX, box_y_koord() + 2 SAY "u procentualnom iznosu od:" GET nProcIznos PICT "999.99"
      @ box_x_koord() + nX, col() + 1 SAY "%"
   ELSE
      @ box_x_koord() + nX, box_y_koord() + 2 SAY "na osnovu jedne neto dnevnice."
   ENDIF

   READ

   IF LastKey() == K_ESC
      BoxC()
      nIznos := 0
      RETURN nIznos
   ENDIF

   IF nTipObracuna == 1
      nIznos := Round( _uneto2 * ( nProcIznos / 100 ), 2 )
   ENDIF

   IF nTipObracuna == 2
      nIznos := Round( ( _uneto2 / _usati ) * 8 , 2 )
   ENDIF

   ++ nX

   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Iznos odbitka = " + AllTrim( Str( nIznos, 12, 2 ) ) + ", obračunati odbitak (D/N) ?" GET cObr ;
             VALID cObr $ "DN" PICT "@!"

   READ

   BoxC()

   IF LastKey() == K_ESC .OR. cObr == "N"
      nIznos := 0
      RETURN nIznos
   ENDIF

   RETURN nIznos



FUNCTION ld_elementarne_nepogode_parametri()

   LOCAL cTipPrimanja := fetch_metric( "ld_elementarne_nepogode_tippr", NIL, SPACE(2) )
   LOCAL nTipObracuna := fetch_metric( "ld_elementarne_nepogode_obracun_tip", NIL, 1 )
   LOCAL nX := 1

   PRIVATE GetList := {}

   Box(, 5, 66 )

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Tip primanja posebnog odbitka za elementarne nepogode:" GET cTipPrimanja ;
             VALID valid_tip_primanja_elementarne_nepogode( @cTipPrimanja )

   ++ nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Način obračuna odbitka za elementarne nepogode:"

   ++ nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 " (1) procenat od neto plate uposlenika"

   ++ nX

   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 " (2) iznos jedne neto dnevnice uposlenika"

   ++ nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "     tekući odabir:" GET nTipObracuna PICT "9" VALID nTipObracuna > 0 .AND. nTipObracuna < 3

   READ

   BoxC()

   IF ( LastKey() <> K_ESC )

      IF !EMPTY( cTipPrimanja )
         MsgBeep( "Ukoliko želite deaktivirati opciju jednostavno izbrište tip primanja !" )
      ENDIF

      set_metric( "ld_elementarne_nepogode_tippr", NIL, cTipPrimanja )
      set_metric( "ld_elementarne_nepogode_obracun_tip", NIL, nTipObracuna )

   ENDIF

   RETURN .T.




STATIC FUNCTION valid_tip_primanja_elementarne_nepogode( cTip )

   LOCAL lRet := .T.

   IF EMPTY( cTip )
       RETURN lRet
   ENDIF

   IF !ld_tip_primanja_se_koristi( cTip )
      dodaj_tip_primanja_elementarnih_nepogoda( cTip )
   ELSE
      MsgBeep( "Uneseni tip primanja " + cTip + " se već koristi unutar obračuna !" )
      IF Pitanje(, "Koristiti tip primanja " + cTip + " za odbitak", " " ) == "N"
         lRet := .F.
      ENDIF
   ENDIF

   RETURN lRet




FUNCTION ld_tip_primanja_se_koristi( cTip )

   LOCAL lRet := .F.
   LOCAL cSql

   cSql := "id = " + sql_quote( cTip )

   IF table_count( f18_sql_schema( "tippr" ), cSql ) > 0
      lRet := .T.
   ENDIF

   RETURN lRet



STATIC FUNCTION dodaj_tip_primanja_elementarnih_nepogoda( cTip )

   LOCAL hRec
   LOCAL lOk := .T.

   o_tippr()

   APPEND BLANK
   hRec := dbf_get_rec()

   hRec["id"] := cTip
   hRec["naz"] := "EL.NEPOGODE ODBITAK"
   hRec["aktivan"] := "D"
   hRec["fiksan"] := "D"
   hRec["ufs"] := "N"
   hRec["koef1"] := 0
   hRec["uneto"] := "N"
   hRec["formula"] := "_I" + cTip

   lOk := update_rec_server_and_dbf( "tippr", hRec, 1, "FULL" )

   IF !lOk
      delete_with_rlock()
      MsgBeep( "Problem sa dodavanjem nove šifre u šifarnik !" )
   ENDIF

   RETURN lOk
