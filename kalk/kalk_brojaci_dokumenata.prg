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

MEMVAR glKalkBrojacPoKontima, gBrojacKalkulacija

STATIC s_nLenKalkBrojac


// postgresql  FUNCTION public.kalk_novi_brdok(cIdVd varchar) RETURNS varchar
FUNCTION kalk_novi_brdok( cIdVd )

   LOCAL cQuery, oRet

   cQuery := "SELECT public.kalk_novi_brdok(" + sql_quote( cIdVd ) + ")"

   oRet := run_sql_query( cQuery )

   IF is_var_objekat_tpqquery( oRet )
      RETURN oRet:FieldGet( 1 )
   ENDIF

   RETURN Replicate( "0", FIELD_LEN_KALK_BRDOK )



FUNCTION kalk_get_next_broj_v5( cIdFirma, cIdVd, cIdKonto )

   LOCAL cSufiks := Space( 3 )

   IF is_brojac_po_kontima() .AND. cIdKonto != NIL
      cSufiks := kalk_sufiks_brdok( cIdKonto )
   ENDIF

   RETURN kalk_sljedeci_brdok( cIdVd, cIdFirma, cSufiks )


FUNCTION is_brojac_po_kontima()

   RETURN glKalkBrojacPoKontima


FUNCTION kalk_duzina_brojaca_dokumenta( nLen )

   IF s_nLenKalkBrojac == NIL
      s_nLenKalkBrojac := fetch_metric( "kalk_duzina_brojaca_dokumenta", NIL, 8 )
   ENDIF

   IF nLen <> NIL
      set_metric( "kalk_duzina_brojaca_dokumenta", NIL, nLen )
      s_nLenKalkBrojac  := nLen
   ENDIF

   RETURN s_nLenKalkBrojac


/*
       kalk_konto_za_brojac( "11", "1320", "13301" ) => 13301
*/

FUNCTION kalk_konto_za_brojac( cIdVd, cMKonto, cPKonto )

   DO CASE
   CASE cIdvd $ "KO#10#16#14#96#95#IM#11"  // 11-ke uzimaju konto magacina za osnovu brojaca, malo glupo, ali tako je napravljeno
      RETURN cMkonto

   CASE cIdvd $ "80#81#41#42#19"
      RETURN cPKonto
   OTHERWISE

      RETURN cMKonto
   ENDCASE

   RETURN cMKonto


/*
  sljedeci broj kalkulacije, za zadani sufiks
*/

STATIC FUNCTION kalk_sljedeci_brdok( cTipKalk, cIdFirma, cSufiks )

   LOCAL cBrKalk := Space( 8 )
   LOCAL nLenGlavni := kalk_duzina_brojaca_dokumenta()
   LOCAL nLenSufiks := 8 - nLenGlavni

   IF cSufiks == NIL .OR. Empty( cSufiks )
      cSufiks := Space( nLenSufiks )
   ELSE
      // "/BL"
      nLenSufiks := Len( cSufiks )
      nLenGlavni := 8 - nLenSufiks // duzina sifre se mora prilagoditi sufiksu
   ENDIF


   IF is_brojac_po_kontima() .AND. !Empty( cSufiks ) // samo trazi ako ima sufiks npr '/T '
      find_kalk_doks_za_tip_sufix_zadnji_broj( cIdFirma, cTipKalk, cSufiks )
   ELSE // ako je sufiks prazan, onda se samo gleda tip
      find_kalk_doks_za_tip_zadnji_broj( cIdFirma, cTipKalk )
   ENDIF

   GO BOTTOM

   IF cTipKalk <> field->idVD .OR. ( is_brojac_po_kontima() .AND. Right( field->brDok, nLenSufiks ) <> cSufiks )
      cBrKalk := Space( kalk_duzina_brojaca_dokumenta() ) + cSufiks
   ELSE
      cBrKalk := field->brDok
   ENDIF

/*
--   update fmk.kalk_doks set brdok=lPad( (100000 + substr(brdok,2)::integer)::text, 8, '0')
    where left(brdok,1)='A' and  not brdok like '%/%';
--   update fmk.kalk_doks set brdok=lPad( (110000 + substr(brdok,2)::integer)::text, 8, '0')
    where left(brdok,1)='B' and  not brdok like '%/%';
--   update fmk.kalk_doks set brdok=lPad( trim(brdok), 8, '0')
    where Length(trim(brdok))<8  and not brdok like '%/%'
*/

   IF AllTrim( cBrKalk ) >= Replicate( "9", nLenGlavni )  // 10_0001 -> A0001, 11_0001 -> B0001
      cBrKalk := PadR( novasifra( AllTrim( cBrKalk ) ), nLenGlavni ) + Right( cBrKalk, nLenSufiks )
   ELSE
      cBrKalk := UBrojDok( Val( Left( cBrKalk, nLenGlavni ) ) + 1, nLenGlavni, Right( cBrKalk, nLenSufiks ) )
   ENDIF

   RETURN cBrKalk


/*
      kalk_set_brkalk_za_idvd( "11", @cBrKalk )
*/

FUNCTION kalk_set_brkalk_za_idvd( cIdVd, cBrKalk )

   IF gBrojacKalkulacija == "D"

      find_kalk_doks_za_tip_zadnji_broj( self_organizacija_id(), cIdVd )
      GO BOTTOM
      IF field->idvd <> cIdVd
         cBrKalk := Space( 8 )
      ELSE
         cBrKalk := field->brdok
      ENDIF
      kalk_fix_brdok_add_1( @cBrKalk )

   ENDIF

   RETURN cBrKalk


FUNCTION kalk_fix_brdok_add_1( cBrKalk )

   LOCAL nLenGlavni := kalk_duzina_brojaca_dokumenta()
   LOCAL nLenSufiks := 8 - nLenGlavni

   IF gBrojacKalkulacija == "D"
      cBrKalk := UBrojDok( Val( Left( cBrKalk, nLenGlavni ) ) + 1, nLenGlavni, Right( cBrKalk, nLenSufiks ) )
   ENDIF

   RETURN cBrKalk


FUNCTION kalk_fix_brdok( cBrKalk )

   LOCAL nLenGlavni := kalk_duzina_brojaca_dokumenta()
   LOCAL nLenSufiks := 8 - nLenGlavni

   IF "/" $ cBrKalk  .OR. "-" $ cBrKalk .OR. slovo_unutar( cBrKalk ) // ne mijenjati nista za G000002, 00002/TZ, 00002-TZ
      RETURN cBrKalk
   ENDIF

   IF Right( AllTrim( cBrKalk ), 1 ) == "#" // ako imam neki "ludi broj" npr "0003    ", onda navodim "0003#"
      RETURN StrTran( cBrKalk, "#", " " )
   ENDIF

   IF gBrojacKalkulacija == "D"
      cBrKalk := UBrojDok( Val( Left( cBrKalk, nLenGlavni ) ), nLenGlavni, Right( cBrKalk, nLenSufiks ) )
   ENDIF

   RETURN cBrKalk


STATIC FUNCTION slovo_unutar( cString )

   LOCAL aMatch, pRegex := hb_regexComp( ".*[a-zA-Z].*" )

   aMatch := hb_regex( pRegex, cString )
   IF Len( aMatch ) > 0
      RETURN .T.
   ENDIF

   RETURN .F.




/*
    uvecava broj kalkulacije sa stepenom uvecanja nUvecaj
*/

FUNCTION kalk_get_next_kalk_doc_uvecaj( cIdFirma, cIdTipDok, nUvecaj )

   LOCAL nX
   LOCAL i
   LOCAL lIdiDalje
   LOCAL cResult

   IF nUvecaj == nil
      nUvecaj := 1
   ENDIF

   lIdiDalje := .F.

   find_kalk_doks_by_broj_dokumenta( cIdFirma, cIdTipDok )
   GO BOTTOM

   DO WHILE .T.
      FOR i := 2 TO Len( AllTrim( field->brDok ) )
         IF !IsNumeric( SubStr( AllTrim( field->brDok ), i, 1 ) )
            lIdiDalje := .F.
            SKIP -1
            LOOP
         ELSE
            lIdiDalje := .T.
         ENDIF
      NEXT

      IF lIdiDalje := .T.
         cResult := field->brDok
         EXIT
      ENDIF

   ENDDO

   nX := 1
   FOR nX := 1 TO nUvecaj
      cResult := PadR( novasifra( AllTrim( cResult ) ), 5 ) + ;
         Right( cResult, 3 )
   NEXT

   RETURN cResult



FUNCTION kalk_prazan_broj_dokumenta()
   RETURN PadR( "0", kalk_duzina_brojaca_dokumenta(), "0" )






// ------------------------------------------------------------
// resetuje brojac dokumenta ako smo pobrisali dokument
// ------------------------------------------------------------
FUNCTION kalk_reset_broj_dokumenta( firma, tip_dokumenta, broj_dokumenta, konto )

   LOCAL _param
   LOCAL _broj := 0
   LOCAL _sufix := ""

   IF konto == NIL
      konto := ""
   ENDIF

   IF is_brojac_po_kontima()
      _sufix := kalk_sufiks_brdok( konto )
   ENDIF

   // param: kalk/10/10
   _param := "kalk" + "/" + firma + "/" + tip_dokumenta + iif( !Empty( _sufix ), "_" + _sufix, "" )
   _broj := fetch_metric( _param, NIL, _broj )

   IF Val( broj_dokumenta ) == _broj
      --_broj
      // smanji globalni brojac za 1
      set_metric( _param, NIL, _broj )
   ENDIF

   RETURN .T.


// ------------------------------------------------------------------
// kalk, uzimanje novog broja za kalk dokument
// ------------------------------------------------------------------
FUNCTION kalk_novi_broj_dokumenta( firma, tip_dokumenta, konto )

   LOCAL _broj := 0
   LOCAL _broj_dok := 0
   LOCAL _len_broj := 5
   LOCAL _len_brdok, _len_sufix
   LOCAL _param
   LOCAL _tmp, _rest
   LOCAL _ret := ""
   LOCAL nDbfArea := Select()
   LOCAL _sufix := ""

   // ova funkcija se brine i za sufiks
   IF konto == NIL
      konto := ""
   ENDIF


   IF is_brojac_po_kontima()
      _sufix := kalk_sufiks_brdok( konto )
   ENDIF

   // param: kalk/10/10
   _param := "kalk" + "/" + firma + "/" + tip_dokumenta + iif( !Empty( _sufix ), "_" + _sufix, "" )
   _broj := fetch_metric( _param, NIL, _broj )

   find_kalk_doks_za_tip_sufix_zadnji_broj(  firma, tip_dokumenta, _sufix )    // konsultuj i kalk_doks uporedo

   GO BOTTOM

   IF field->idfirma == firma .AND. field->idvd == tip_dokumenta .AND. ;
         iif( glKalkBrojacPoKontima, Right( AllTrim( field->brdok ), Len( _sufix ) ) == _sufix, .T. )

      IF glKalkBrojacPoKontima .AND. ( _sufix $ field->brdok )
         _len_brdok := Len( AllTrim( field->brdok ) )
         _len_sufix := Len( _sufix )
         // odrezi sufiks ako postoji
         _broj_dok := Val( Left( AllTrim( field->brdok ), _len_brdok - _len_sufix ) )
      ELSE
         _broj_dok := Val( field->brdok )
      ENDIF

   ELSE
      _broj_dok := 0
   ENDIF

   _broj := Max( _broj, _broj_dok ) // uzmi sta je vece, dokument broj ili globalni brojac
   ++_broj

   // ovo ce napraviti string prave duzine...
   // dodaj i sufiks na kraju ako treba
   _ret := PadL( AllTrim( Str( _broj ) ), _len_broj, "0" ) + _sufix

   // upisi ga u globalni parametar
   set_metric( _param, NIL, _broj )

   SELECT ( nDbfArea )

   RETURN _ret



/*
koncij.sufiks  polje
*/

FUNCTION kalk_sufiks_brdok( cIdKonto )

   LOCAL cSufiks := Space( 3 )

   PushWa()
   IF select_o_koncij( cIdKonto )
      cSufiks := field->sufiks
   ENDIF
   PopWa()

   RETURN cSufiks



/*  ovo se ne koristi ?
FUNCTION kalk_set_broj_dokumenta()

   LOCAL _broj_dokumenta
   LOCAL nTrec, hRec
   LOCAL _firma, _td, _null_brdok
   LOCAL _konto := ""

   PushWA()

   SELECT kalk_pripr
   GO TOP

   _null_brdok := kalk_prazan_broj_dokumenta()

   IF field->brdok <> _null_brdok
      // nemam sta raditi, broj je vec setovan
      PopWa()
      RETURN .F.
   ENDIF

   _firma := field->idfirma
   _td := field->idvd
   _konto := field->idkonto


   _broj_dokumenta := kalk_novi_broj_dokumenta( _firma, _td, _konto ) // odrediti novi broj dokumenta

   SELECT kalk_pripr
   SET ORDER TO TAG "1"
   GO TOP

   DO WHILE !Eof()

      SKIP 1
      nTrec := RecNo()
      SKIP -1

      IF field->idfirma == _firma .AND. field->idvd == _td .AND. field->brdok == _null_brdok
         hRec := dbf_get_rec()
         hRec[ "brdok" ] := _broj_dokumenta
         dbf_update_rec( hRec )
      ENDIF

      GO ( nTrec )

   ENDDO

   PopWa()

   RETURN .T.
*/


// ------------------------------------------------------------
// setovanje parametra brojaca na admin meniju
// ------------------------------------------------------------
FUNCTION kalk_set_param_broj_dokumenta()

   LOCAL _param
   LOCAL _broj := 0
   LOCAL _broj_old
   LOCAL _firma := self_organizacija_id()
   LOCAL _tip_dok := "10"
   LOCAL _sufix := ""
   LOCAL _konto := PadR( "1330", 7 )

   Box(, 2, 60 )

   @ box_x_koord() + 1, box_y_koord() + 2 SAY "Dokument:" GET _firma
   @ box_x_koord() + 1, Col() + 1 SAY "-" GET _tip_dok

   IF glKalkBrojacPoKontima
      @ box_x_koord() + 1, Col() + 1 SAY " konto:" GET _konto
   ENDIF

   READ

   IF LastKey() == K_ESC
      BoxC()
      RETURN .F.
   ENDIF

   IF glKalkBrojacPoKontima
      _sufix := kalk_sufiks_brdok( _konto )
   ENDIF

   // param: kalk/10/10
   _param := "kalk" + "/" + firma + "/" + tip_dokumenta + iif( !Empty( _sufix ), "_" + _sufix, "" )
   _broj := fetch_metric( _param, NIL, _broj )
   _broj_old := _broj

   @ box_x_koord() + 2, box_y_koord() + 2 SAY "Zadnji broj dokumenta:" GET _broj PICT "99999999"

   READ

   BoxC()

   IF LastKey() != K_ESC
      // snimi broj u globalni brojac
      IF _broj <> _broj_old
         set_metric( _param, NIL, _broj )
      ENDIF
   ENDIF

   RETURN .T.




FUNCTION kalk_unos_get_brdok( cIdFirma, cIdVd, cIdKonto1, cIdKonto2 )

   LOCAL cIdKontoUnos, cSay
   LOCAL GetList := {}

   IF is_brojac_po_kontima()

      Box( "#Glavni konto za brojač", 3, 70 )
      IF cIdVd $ KALK_IDVD_MAGACIN
         cSay := "Magacinski konto: "
         cIdKontoUnos := cIdKonto1
      ELSE
         cSay := "Prodavnički konto: "
         cIdKontoUnos := cIdKonto2
      ENDIF
      cIdKontoUnos := PadR( cIdKontoUnos, FIELD_LENGTH_IDKONTO )
      @ box_x_koord() + 2, box_y_koord() + 2 SAY8 cSay GET cIdKontoUnos VALID P_Konto( @cIdKontoUnos ) PICT "@!"
      READ

      BoxC()

      IF cIdVd $ KALK_IDVD_MAGACIN
         cIdKonto1 := cIdKontoUnos
      ELSE
         cIdKonto2 := cIdKontoUnos
      ENDIF

   ENDIF

   RETURN kalk_get_next_broj_v5( cIdFirma, cIdVd, cIdKontoUnos )
