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

MEMVAR nMPV80, nNVPredhodna
MEMVAR nKalkRBr
MEMVAR GetList
MEMVAR _pkonto

FUNCTION kalk_get1_80()

   LOCAL nX := 5
   LOCAL _kord_x := 0
   LOCAL _unos_left := 40
   PRIVATE aPorezi := {}
   PRIVATE cProracunMarzeUnaprijed := " "

   IF Empty( _pkonto )
      _pkonto := _idkonto2
      _idkonto := Space( FIELD_LEN_KONTO_ID )
   ENDIF

   IF nKalkRbr == 1 .AND. kalk_is_novi_dokument()
      _DatFaktP := _datdok
   ENDIF

   IF nKalkRbr == 1 .OR. !kalk_is_novi_dokument()

      _kord_x := box_x_koord() + nX

      @ box_x_koord() + nX, box_y_koord() + 2 SAY "Temeljnica:" GET _BrFaktP
      @ box_x_koord() + nX, Col() + 1 SAY "Datum:" GET _DatFaktP

      ++nX
      @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Prodavnički konto: " GET _pkonto VALID {|| P_Konto( @_pkonto ), ispisi_naziv_konto( _kord_x - 1, 35, 30 ) } PICT "@!"

      ++nX
      _kord_x := box_x_koord() + nX
      @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "  Prenos na konto: " GET _IdKonto2 VALID {|| Empty( _idkonto2 ) .OR. P_Konto( @_IdKonto2 ), ispisi_naziv_konto( _kord_x, 35, 30 )  } PICT "@!"
      READ

      ESC_RETURN K_ESC

   ELSE

      @ box_x_koord() + nX, box_y_koord() + 2 SAY "Temeljnica: "
      ?? _BrFaktP
      @ box_x_koord() + nX, Col() + 2 SAY "Datum: "
      ?? _DatFaktP

      ++nX
      @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Konto zadužuje: "
      ?? _pkonto

      ++nX
      @ box_x_koord() + nX, box_y_koord() + 2 SAY "Prenos na konto: "
      ?? _IdKonto2

      READ
      ESC_RETURN K_ESC

   ENDIF

   SELECT kalk_pripr

   nX += 2

   kalk_pripr_form_get_roba( @GetList, @_idRoba, @_idTarifa, _IdVd, kalk_is_novi_dokument(), box_x_koord() + nX, box_y_koord() + 2, @aPorezi )
   @ box_x_koord() + nX, box_y_koord() + ( f18_max_cols() - 20 ) SAY "Tarifa:" GET _IdTarifa  VALID P_Tarifa( @_IdTarifa )

   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Količina " GET _Kolicina PICT pickol() VALID _Kolicina <> 0

   READ
   ESC_RETURN K_ESC

   IF roba_barkod_pri_unosu()
      _idRoba := Left( _idRoba, 10 )
   ENDIF
   select_o_roba( _idroba )
   select_o_tarifa( roba->idtarifa )
   select_o_koncij( _pkonto )

   SELECT kalk_pripr


   IF kalk_is_novi_dokument()
      select_o_koncij( _pkonto )
      select_o_roba( _idroba )
      _mpcsapp := kalk_get_mpc_by_koncij_pravilo()
      _TMarza2 := "%"
      _TCarDaz := "%"
      _CarDaz := 0
   ENDIF

   SELECT kalk_pripr

   nX += 2 // NC

   _kord_x := box_x_koord() + nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "NABAVNA CJENA:"
   @ box_x_koord() + nX, box_y_koord() + _unos_left GET _nc WHEN VKol( _kord_x - 2 ) PICT PicDEM

   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "MARŽA:" GET _TMarza2 VALID _Tmarza2 $ "%AU" PICT "@!"
   @ box_x_koord() + nX, box_y_koord() + _unos_left GET _Marza2 PICT PicDEM VALID {|| _vpc := _nc, .T. }
   @ box_x_koord() + nX, Col() + 1 GET cProracunMarzeUnaprijed PICT "@!"

   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "MALOPROD. CIJENA (MPC):"
   @ box_x_koord() + nX, box_y_koord() + _unos_left GET _mpc ;
      PICT PicDEM  WHEN kalk_when_valid_mpc_80_81_41_42( "80", ( cProracunMarzeUnaprijed == "F" ), @aPorezi ) VALID kalk_valid_mpc_80_81_41_42( "80", ( cProracunMarzeUnaprijed == "F" ), @aPorezi )

   ++nX
   SayPorezi_lv( nX, aPorezi )

   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "PC SA PDV:"
   @ box_x_koord() + nX, box_y_koord() + _unos_left GET _MPCSaPP PICT PicDEM VALID kalk_valid_mpcsapdv( "80", .F., @aPorezi, .T. )

   READ
   ESC_RETURN K_ESC

   select_o_koncij( _pkonto )
   roba_set_mcsapp_na_osnovu_koncij_pozicije( _MpcSapp, .T. )

   SELECT kalk_pripr

   _PU_I := "1"
   _MKonto := ""
   _MU_I := ""

   nKalkStrana := 3

   RETURN LastKey()




// PROTUSTAVKA 80-ka, druga strana
// _odlval nalazi se u knjiz, filuje staru vrijenost
// _odlvalb nalazi se u knjiz, filuje staru vrijenost nabavke
FUNCTION kalk_get_1_80_protustavka()

   LOCAL cSvedi := fetch_metric( "kalk_dok_80_predispozicija_set_cijena", my_user(), " " )
   LOCAL nX := 2
   LOCAL _kord_x := 0
   LOCAL _unos_left := 40
   PRIVATE aPorezi := {}
   PRIVATE PicDEM := "9999999.99999999"

   kalk_is_novi_dokument( .T. )

   pickol( "999999.999" )
   Beep( 1 )

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "PROTUSTAVKA   ( S - svedi M - mpc sifr i ' ' - ne diraj ):"
   @ box_x_koord() + nX, Col() + 2 GET cSvedi VALID cSvedi $ " SM" PICT "@!"

   READ
   AltD()

   set_metric( "kalk_dok_80_predispozicija_set_cijena", my_user(), cSvedi ) // zapamti zadnji unos

   nX := 12
   _kord_x := box_x_koord() + nX

   kalk_pripr_form_get_roba( @GetList, @_idRoba, @_idTarifa, _IdVd, kalk_is_novi_dokument(), box_x_koord() + nX, box_y_koord() + 2, @aPorezi )

   @ box_x_koord() + nX, box_y_koord() + ( f18_max_cols() - 20 ) SAY "Tarifa:" GET _IdTarifa VALID P_Tarifa( @_IdTarifa )

   READ

   ESC_RETURN K_ESC

   select_o_koncij( _pkonto )

   SELECT kalk_pripr
   _pkonto := _pkonto

   PRIVATE cProracunMarzeUnaprijed := " "

   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Kolicina " GET _Kolicina PICT pickol() VALID _Kolicina <> 0

   select_o_koncij( _pkonto )
   select_o_roba( _idroba )

   // ako nije popunjeno
   _mpcsapp := kalk_get_mpc_by_koncij_pravilo()
   _TMarza2 := "%"
   _TCarDaz := "%"
   _CarDaz := 0

   SELECT kalk_pripr

   ++nX
   _kord_x := box_x_koord() + nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "NABAVNA CIJENA:"
   @ box_x_koord() + nX, box_y_koord() + _unos_left GET _NC PICT PicDEM WHEN VKol( _kord_x )

   // MARZA
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "MARZA:" GET _TMarza2  VALID _Tmarza2 $ "%AU" PICT "@!"
   @ box_x_koord() + nX, box_y_koord() + _unos_left  GET _Marza2 PICT PicDEM VALID {|| _vpc := _nc, .T. }
   @ box_x_koord() + nX, Col() + 1 GET cProracunMarzeUnaprijed PICT "@!"

   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2  SAY "PROD.CIJENA BEZ PDV:"
   @ box_x_koord() + nX, box_y_koord() + _unos_left GET _mpc PICT PicDEM WHEN WMpc_lv( NIL, NIL, aPorezi ) VALID VMpc_lv( NIL, NIL, aPorezi )

   ++nX
   SayPorezi_lv( nX, aPorezi )
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "P.CIJENA SA PDV:"
   @ box_x_koord() + nX, box_y_koord() + _unos_left GET _mpcsapp PICT PicDEM VALID {|| kalk_80_svedi( cSvedi ), VMpcSapp_lv( NIL, NIL, aPorezi ) }

   READ

   ESC_RETURN K_ESC

   select_o_koncij( _pkonto )
   roba_set_mcsapp_na_osnovu_koncij_pozicije( _mpcsapp, .T. )

   SELECT kalk_pripr

   _PU_I := "1"
   _MKonto := ""
   _MU_I := ""

   nKalkStrana := 3

   RETURN LastKey()



FUNCTION kalk_80_svedi( cSvedi )

   IF cSvedi == "M"

      select_o_koncij( _pkonto )
      select_o_roba( _idroba )
      _mpcsapp := kalk_get_mpc_by_koncij_pravilo()

   ELSEIF cSvedi == "S"
      IF _mpcsapp <> 0
         _kolicina := -Round( nMPV80 / _mpcsapp, 4 )
      ELSE
         _kolicina := 99999999
      ENDIF

      IF _kolicina <> 0
         _nc := Abs( nNVPredhodna / _kolicina )
      ELSE
         _nc := 0
      ENDIF
   ENDIF

   RETURN .T.




/* VKol()
 *     Validacija unesene kolicine u dokumentu tipa 80
 */

STATIC FUNCTION VKol( x_kord )

   IF _kolicina < 0

      nKolS := 0
      nKolZN := 0

      nc1 := nc2 := 0

      kalk_get_nabavna_prod( _idfirma, _idroba, _pkonto, @nKolS, @nKolZN, @nC1, @nC2 )

      @ x_kord, box_y_koord() + 30 SAY "Ukupno na stanju "
      @ x_kord, Col() + 2 SAY nKols PICT pickol()

      IF _nc == 0
         _nc := nc2
      ENDIF

      IF nKols < Abs( _kolicina )

         sumnjive_stavke_error()

         error_bar( "KA_" + _pkonto + " / " + _idroba, _pkonto + " / " + _idroba + " kolicina:" + ;
            AllTrim( Str( nKols, 12, 3 ) ) +  " treba: " + AllTrim( Str( _kolicina, 12, 3 ) ) )
      ENDIF

      SELECT kalk_pripr

   ENDIF

   RETURN .T.
