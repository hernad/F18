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

STATIC aPorezi := {}

FUNCTION kalk_get_1_16()

   LOCAL nRVPC

   pIzgSt := .F.   // izgenerisane stavke jos ne postoje

   SET KEY K_ALT_K TO KM94()

   IF nRbr == 1 .AND. kalk_is_novi_dokument()
      _DatFaktP := _datdok
   ENDIF

   IF Empty( _TMarza )
      _TMarza := "%"
   ENDIF

   IF nRbr == 1 .OR. !kalk_is_novi_dokument()

      IF _idvd $ "94#97"
         @  box_x_koord() + 6, box_y_koord() + 2   SAY "KUPAC:" GET _IdPartner PICT "@!" VALID Empty( _IdPartner ) .OR. p_partner( @_IdPartner, 6, 18 )
      ENDIF
      @  box_x_koord() + 7, box_y_koord() + 2   SAY "Faktura/Otpremnica Broj:" GET _BrFaktP
      @  box_x_koord() + 7, Col() + 2 SAY "Datum:" GET _DatFaktP  VALID {|| .T. }


      @ box_x_koord() + 9, box_y_koord() + 2 SAY8 "Magacinski konto zadužuje"  GET _IdKonto VALID Empty( _IdKonto ) .OR. P_Konto( @_IdKonto, 21, 5 )

      IF !Empty( cRNT1 )
         @ box_x_koord() + 9, box_y_koord() + 40 SAY "Rad.nalog:"   GET _IdZaduz2  PICT "@!"
      ENDIF

      IF _idvd == "16" .AND. _idkonto2 != "XXX"
         @ box_x_koord() + 10, box_y_koord() + 2   SAY "Prenos na konto          " GET _IdKonto2   VALID Empty( _idkonto2 ) .OR. P_Konto( @_IdKonto2, 21, 5 ) PICT "@!"

      ENDIF

   ELSE
      @  box_x_koord() + 6, box_y_koord() + 2   SAY "KUPAC: "; ?? _IdPartner
      @  box_x_koord() + 7, box_y_koord() + 2   SAY "Faktura Broj: "; ?? _BrFaktP
      @  box_x_koord() + 7, Col() + 2 SAY "Datum: "; ?? _DatFaktP
      @  box_x_koord() + 9, box_y_koord() + 2 SAY8 "Magacinski konto zadužuje "; ?? _IdKonto


   ENDIF

   @ box_x_koord() + 10, box_y_koord() + 66 SAY "Tarif.br "

   kalk_pripr_form_get_roba( @GetList, @_idRoba, @_idTarifa, _IdVd, kalk_is_novi_dokument(), box_x_koord() + 11, box_y_koord() + 2, @aPorezi )


   @ box_x_koord() + 11, box_y_koord() + 70 GET _IdTarifa VALID P_Tarifa( @_IdTarifa )

   @ box_x_koord() + 12, box_y_koord() + 2   SAY8 "Količina " GET _Kolicina PICTURE PicKol VALID _Kolicina <> 0

   READ
   ESC_RETURN K_ESC

   IF roba_barkod_pri_unosu()
      _idRoba := Left( _idRoba, 10 )
   ENDIF

   select_o_koncij( _idkonto )
   select_o_tarifa( _IdTarifa )

   SELECT kalk_pripr
   _MKonto := _Idkonto
   _MU_I := "1"

   // check_datum_posljednje_kalkulacije()
   // DuplRoba()
   _GKolicina := 0
   IF kalk_is_novi_dokument()
      select_o_roba( _IdRoba )
      IF koncij->naz == "P2"
         _nc := plc
         _vpc := plc
      ELSE
         _VPC := kalk_vpc_za_koncij()
         _NC := NC
      ENDIF
   ENDIF
   set_pdv_public_vars()
   SELECT kalk_pripr

   @ box_x_koord() + 14, box_y_koord() + 2   SAY "NAB.CJ   "  GET _NC  PICTURE gPicNC  WHEN V_kol10()
   READ

   PRIVATE _vpcsappp := 0

   _VPC := _nc
   marza := 0

   nKalkStrana := 2

   _marza := _vpc - _nc
   _MKonto := _Idkonto
   _MU_I := "1"
   _PKonto := ""
   _PU_I := ""

   SET KEY K_ALT_K TO

   RETURN LastKey()




// _odlval nalazi se u knjiz, filuje staru vrijednost
// _odlvalb nalazi se u knjiz, filuje staru vrijednost nabavke
FUNCTION kalk_get_16_1()

   LOCAL cSvedi := " "

   kalk_is_novi_dokument( .T. )

   PRIVATE PicDEM := "9999999.99999999", PicKol := "999999.999"

   Beep( 1 )

   @ box_x_koord() + 2, box_y_koord() + 2 SAY "PROTUSTAVKA   (svedi na staru vrijednost - kucaj S):"
   @ box_x_koord() + 2, Col() + 2 GET cSvedi VALID csvedi $ " S" PICT "@!"
   READ

   @ box_x_koord() + 11, box_y_koord() + 66 SAY "Tarif.brĿ"
   @ box_x_koord() + 12, box_y_koord() + 2  SAY "Artikal  " GET _IdRoba PICT "@!" ;
      VALID  {|| P_Roba( @_IdRoba ), say_from_valid( 12, 23, Trim( Left( roba->naz, 40 ) ) + " (" + ROBA->jmj + ")", 40 ), _IdTarifa := ROBA->idtarifa, .T. }
   @ box_x_koord() + 12, box_y_koord() + 70 GET _IdTarifa VALID P_Tarifa( @_IdTarifa )

   READ
   ESC_RETURN K_ESC
   select_o_tarifa( _IdTarifa )
   select_o_koncij( _idkonto )
   SELECT kalk_pripr

   _PKonto := _Idkonto

   // kalk_dat_poslj_promjene_prod()
   // DuplRoba()

   PRIVATE cProracunMarzeUnaprijed := " "

   @ box_x_koord() + 13, box_y_koord() + 2   SAY "Kolicina " GET _Kolicina PICTURE PicKol VALID _Kolicina <> 0

   select_o_koncij( _idkonto )
   select_o_roba(  _IdRoba )

   _VPC := kalk_vpc_za_koncij()
   _TMarza2 := "%"
   _TCarDaz := "%"
   _CarDaz := 0

   SELECT kalk_pripr

   set_pdv_public_vars()
   SELECT kalk_pripr



   @ box_x_koord() + 14, box_y_koord() + 2    SAY "NAB.CJ   "  GET _NC  PICTURE  gPicNC  WHEN V_kol10()

   PRIVATE _vpcsappp := 0


   // vodi se po nc
   _vpc := _nc
   marza := 0


   cBeze := " "
   @ box_x_koord() + 17, box_y_koord() + 2 GET cBeze VALID SvediM( cSvedi )



   READ


   nKalkStrana := 2
   _marza := _vpc - _nc
   _MKonto := _Idkonto
   _MU_I := "1"
   _PKonto := ""
   _PU_I := ""
   _ERROR := "0"
   nKalkStrana := 3

   RETURN LastKey()




/*
  *   Svodjenje kolicine u protustavci da bi se dobila ista vrijednost (kada su cijene u stavci i protustavci razlicite)
*/

STATIC FUNCTION SvediM( cSvedi )

   IF koncij->naz == "N1"
      _VPC := _NC
   ENDIF
   IF csvedi == "S"
      IF _vpc <> 0
         _kolicina := -Round( _oldval / _vpc, 4 )
      ELSE
         _kolicina := 99999999
      ENDIF
      IF _kolicina <> 0
         _nc := Abs( _oldvaln / _kolicina )
      ELSE
         _nc := 0
      ENDIF
   ENDIF

   RETURN .T.
