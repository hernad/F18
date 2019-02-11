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

MEMVAR GetList
MEMVAR nKalkRBr

STATIC s_cKonverzijaValuteDN // konverzija valute
STATIC aPorezi := {}
STATIC s_lIsNoviDokument := .F.


FUNCTION kalk_is_novi_dokument( lSet )

   IF lSet != NIL
      s_lIsNoviDokument := lSet
   ENDIF

   RETURN s_lIsNoviDokument


FUNCTION kalk_get_1_10()

   LOCAL nX := 5
   LOCAL nBoxKoordX := 0
   LOCAL nSayDeltaY := 40
   LOCAL GetList := {}

   s_cKonverzijaValuteDN := "N"

   IF nKalkRbr == 1 .AND. kalk_is_novi_dokument()
      _DatFaktP := _datdok
   ENDIF

   IF nKalkRbr == 1  .OR. !kalk_is_novi_dokument() .OR. gMagacin == "1"

      @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "DOBAVLJAČ:" GET _IdPartner PICT "@!"  VALID {|| kalk_valid_dobavljac( @_IdPartner, box_x_koord() + nX ) }

      @ box_x_koord() + nX, 50 SAY "Broj fakture:" GET _BrFaktP VALID !Empty ( _brFaktP )
      @ box_x_koord() + nX, Col() + 1 SAY "Datum:" GET _DatFaktP VALID {||  datum_not_empty_upozori_godina( _datFaktP, "Datum fakture" ) }

      ++nX
      nBoxKoordX := box_x_koord() + nX
      @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Magacinski Konto zadužuje" GET _IdKonto VALID {|| P_Konto( @_IdKonto ), ispisi_naziv_konto( nBoxKoordX, 40, 30 ) } PICT "@!"

      IF !Empty( cRNT1 )
         @ box_x_koord() + nX, box_y_koord() + 60  SAY "Rad.nalog:" GET _IdZaduz2  PICT "@!"
      ENDIF

      READ

      ESC_RETURN K_ESC

   ELSE

      @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "DOBAVLJAČ: "
      ?? _IdPartner
      @ box_x_koord() + nX, Col() + 1 SAY "Faktura dobavljaca - Broj: "
      ?? _BrFaktP
      @ box_x_koord() + nX, Col() + 1 SAY "Datum: "
      ?? _DatFaktP

      ++nX
      @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Magacinski Konto zadužuje "
      ?? _IdKonto

      ino_dobavljac_set_konverzija_valute( _idpartner, @s_cKonverzijaValuteDN )

   ENDIF

   nX += 2

   nBoxKoordX := box_x_koord() + nX

   kalk_pripr_form_get_roba( @GetList, @_idRoba, @_idTarifa, _IdVd, kalk_is_novi_dokument(), nBoxKoordX, box_y_koord() + 2, @aPorezi, _idPartner )
   @ box_x_koord() + nX, box_y_koord() + ( f18_max_cols() - 20  ) SAY "Tarifa:" GET _IdTarifa VALID P_Tarifa( @_IdTarifa )

   READ

   ESC_RETURN K_ESC

   IF roba_barkod_pri_unosu()
      _idRoba := Left( _idRoba, 10 )
   ENDIF

   select_o_koncij( _idkonto )
   SELECT kalk_pripr

   _MKonto := _Idkonto
   _MU_I := "1"

   select_o_tarifa( _IdTarifa )
   SELECT kalk_pripr

   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Količina " GET _Kolicina PICT PicKol VALID _Kolicina <> 0

   IF kalk_is_novi_dokument()
      select_o_roba( _IdRoba )
      _VPC := kalk_vpc_za_koncij()
      _TCarDaz := "%"
      _CarDaz := 0
   ENDIF

   SELECT kalk_pripr

   IF _tmarza <> "%"
      _Marza := 0 // procente ne diraj
   ENDIF

   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Fakturna cijena:"

   IF is_kalk_konverzija_valute_na_unosu()
      @ box_x_koord() + nX, Col() + 1 SAY "EUR (D/N)->" GET s_cKonverzijaValuteDN VALID kalk_ulaz_preracun_fakturne_cijene( s_cKonverzijaValuteDN ) PICT "@!"
   ENDIF

   @ box_x_koord() + nX, box_y_koord() + nSayDeltaY GET _fcj PICT gPicNC VALID {|| _fcj > 0 .AND. _set_konv( @_fcj, @s_cKonverzijaValuteDN ) } WHEN V_kol10()

   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Rabat (%):"
   @ box_x_koord() + nX, box_y_koord() + nSayDeltaY GET _Rabat PICT PicDEM



   READ

   ESC_RETURN K_ESC

   _FCJ2 := _FCJ * ( 1 - _Rabat / 100 )

   kalk_get_2_10( nX, _idPartner )

   RETURN LastKey()



STATIC FUNCTION kalk_valid_dobavljac( cIdPartner, nX )

   p_partner( @cIdPartner )

   ispisi_naziv_partner( nX - 1, 22, 20 )
   ino_dobavljac_set_konverzija_valute( cIdpartner, @s_cKonverzijaValuteDN )

   IF Empty( cIdPartner )
      RETURN .F.
   ENDIF

   RETURN .T.



STATIC FUNCTION ino_dobavljac_set_konverzija_valute( cPartn, s_cKonverzijaValuteDN )

   IF kalk_is_novi_dokument() .AND. partner_is_ino( cPartn )
      s_cKonverzijaValuteDN := "D"
   ENDIF

   RETURN .T.



FUNCTION kalk_ulaz_preracun_fakturne_cijene( cDn )

   LOCAL lRet := .T.

   IF cDN $ "DN"
      RETURN lRet
   ELSE
      MsgBeep( "Preračun: " + valpomocna() + "=>" + valuta_domaca_skraceni_naziv() + "#Unijeti 'D' ili 'N' !" )
      lRet := .F.
      RETURN lRet
   ENDIF

   RETURN .T.


// --------------------------------------
// konverzija fakturne cijene
// --------------------------------------
FUNCTION _set_konv( nFcj, cPretv )

   IF cPretv == "D"
      a_val_convert()
      cPretv := "N"
      showgets()
   ENDIF

   RETURN .T.




STATIC FUNCTION kalk_get_2_10( nX, cIdPartner )

   LOCAL cSPom := " (%,A,U,R,T) "

   // LOCAL nX := x_kord + 4
   LOCAL nSayDeltaY := 40
   LOCAL nBoxKoordX
   LOCAL lSaTroskovima := .T., cTroskoviDN := "D"
   PRIVATE getlist := {}

   nX := nX + 4
   IF Empty( _TPrevoz )
      _TPrevoz := "%"
   ENDIF
   IF Empty( _TCarDaz )
      _TCarDaz := "%"
   ENDIF
   IF Empty( _TBankTr )
      _TBankTr := "%"
   ENDIF
   IF Empty( _TSpedTr )
      _TSpedtr := "%"
   ENDIF
   IF Empty( _TZavTr )
      _TZavTr := "%"
   ENDIF
   IF Empty( _TMarza )
      _TMarza := "%"
   ENDIF

   IF !partner_is_ino( cIdPartner ) // domaci
      cTroskoviDN := "N"
   ENDIF

   IF Pitanje( , "Unos zavisnih troškova ?", cTroskoviDN ) == "D"
      lSaTroskovima := .T.
   ELSE
      lSaTroskovima := .F.
   ENDIF

   IF lSaTroskovima

      _auto_set_trosk( kalk_is_novi_dokument() )   // automatski setuj troskove

      // TROSKOVNIK
      @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Raspored troškova kalkulacije ->"

      @ box_x_koord() + nX, box_y_koord() + nSayDeltaY + 10 SAY c10T1 + cSPom GET _TPrevoz VALID _TPrevoz $ "%AURT" PICTURE "@!"
      @ box_x_koord() + nX, Col() + 2 GET _Prevoz PICT  PicDEM

      ++nX
      @ box_x_koord() + nX, box_y_koord() + nSayDeltaY + 10 SAY c10T2 + cSPom  GET _TBankTr VALID _TBankTr $ "%AURT" PICT "@!"
      @ box_x_koord() + nX, Col() + 2 GET _BankTr PICT PicDEM

      ++nX
      @ box_x_koord() + nX, box_y_koord() + nSayDeltaY + 10 SAY c10T3 + cSPom GET _TSpedTr VALID _TSpedTr $ "%AURT" PICT "@!"
      @ box_x_koord() + nX, Col() + 2 GET _SpedTr PICT PicDEM

      ++nX
      @ box_x_koord() + nX, box_y_koord() + nSayDeltaY + 10 SAY c10T4 + cSPom GET _TCarDaz VALID _TCarDaz $ "%AURT" PICTURE "@!"
      @ box_x_koord() + nX, Col() + 2 GET _CarDaz PICT PicDEM

      ++nX
      @ box_x_koord() + nX, box_y_koord() + nSayDeltaY + 10 SAY c10T5 + cSPom GET _TZavTr VALID _TZavTr $ "%AURT" PICTURE "@!"
      @ box_x_koord() + nX, Col() + 2 GET _ZavTr PICT PicDEM

      nX += 2

   ENDIF

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "NABAVNA CJENA:"
   @ box_x_koord() + nX, box_y_koord() + nSayDeltaY GET _nc PICT gPicNC WHEN {|| kalk_when_valid_nc_ulaz(), .T. }

   IF koncij->naz != "N1" // magacin po nabavnim cijenama

      PRIVATE cProracunMarzeUnaprijed := " "
      ++nX
      @ box_x_koord() + nX, box_y_koord() + 2    SAY8 "Magacin. Marža     :" GET _TMarza VALID _Tmarza $ "%AU" PICTURE "@!"
      @ box_x_koord() + nX, Col() + 2 GET _Marza PICT PicDEM
      @ box_x_koord() + nX, Col() + 1 GET cProracunMarzeUnaprijed PICT "@!" VALID {|| kalk_10_pr_rn_valid_vpc_set_marza_polje_nakon_iznosa( @cProracunMarzeUnaprijed ) }

      // PRODAJNA CIJENA / PLANSKA CIJENA
      ++nX
      IF koncij->naz == "P2"
         @ box_x_koord() + nX, box_y_koord() + 2    SAY "PLANSKA CIJENA  (PLC)       :"
      ELSE
         @ box_x_koord() + nX, box_y_koord() + 2    SAY "PRODAJNA CIJENA BEZ PDV   :"
      ENDIF

      @ box_x_koord() + nX, box_y_koord() + nSayDeltaY GET _vpc PICT PicDEM VALID {|| kalk_10_vaild_Marza_VP( _Idvd, ( cProracunMarzeUnaprijed == "F" ) ), .T. }

      IF ( gcMpcKalk10 == "D" )   // VPC se izracunava pomocu MPC cijene

         _mpcsapp := roba->mpc
         ++nX
         @ box_x_koord() + nX, box_y_koord() + 2 SAY "PRODAJNA CIJENA SA PDV:"
         @ box_x_koord() + nX, box_y_koord() + nSayDeltaY GET _mpcsapp PICT PicDEM ;
            VALID {|| _mpcsapp := iif( _mpcsapp = 0, Round( _vpc * ( 1 + tarifa->pdv / 100 ), 2 ), _mpcsapp ), _mpc := _mpcsapp / ( 1 + tarifa->pdv / 100 ), ;
            iif( _mpc <> 0, _vpc := Round( _mpc, 2 ), _vpc ), ShowGets(), .T. }

      ENDIF
   ENDIF

   READ

   IF ( gcMpcKalk10 == "D" )

      IF ( roba->mpc == 0 .OR. roba->mpc <> Round( _mpcsapp, 2 ) ) .AND. Pitanje(, "Staviti MPC u šifarnik" ) == "D"

         SELECT roba
         hRec := dbf_get_rec()
         hRec[ "mpc" ] := _mpcsapp
         update_rec_server_and_dbf( Alias(), hRec, 1, "FULL" )
         SELECT kalk_pripr

      ENDIF

   ENDIF

   kalk_set_vpc_sifarnik( _vpc )

   _MKonto := _Idkonto
   _MU_I := "1"

   nKalkStrana := 3

   RETURN LastKey()



// ------------------------------------------------------
// automatsko setovanje troskova kalkulacije
// na osnovu sifrarnika robe
//
// lNewItem - radi se o novoj stavci
// ------------------------------------------------------
STATIC FUNCTION _auto_set_trosk( lNewItem )

   LOCAL lForce := .F.

   // ako nema polja TROSK1 u robi idi dalje....
   // nemas sta raditi

   IF roba->( FieldPos( "TROSK1" ) ) == 0
      RETURN .F.
   ENDIF

   // ako su automatski troskovi = "N", izadji
   IF kalk_preuzimanje_troskova_iz_sif_roba() == "N"
      RETURN .F.
   ENDIF

   IF kalk_preuzimanje_troskova_iz_sif_roba() == "0"

      IF Pitanje( , "Preuzeti troskove iz sifrarnika robe ?", "D" ) == "N"
         RETURN .F.
      ENDIF

      // setuj forirano uzimanje troska.....
      lForce := .T.

   ENDIF

   IF ( _Prevoz == 0 .OR. lForce == .T. .OR. lNewItem == .T. )

      _Prevoz := roba->trosk1

      IF !Empty( gRobaTr1Tip )
         _TPrevoz := gRobaTr1Tip
      ENDIF

   ENDIF

   IF ( _BankTr == 0 .OR. lForce == .T. .OR. lNewItem == .T. )

      _BankTr := roba->trosk2

      IF !Empty( gRobaTr2Tip )
         _TBankTr := gRobaTr2Tip
      ENDIF

   ENDIF

   IF ( _SpedTr == 0 .OR. lForce == .T. .OR. lNewItem == .T. )

      _SpedTr := roba->trosk3

      IF !Empty( gRobaTr3Tip )
         _TSpedTr := gRobaTr3Tip
      ENDIF

   ENDIF

   IF ( _CarDaz == 0 .OR. lForce == .T. .OR. lNewItem == .T. )

      _CarDaz := roba->trosk4

      IF !Empty( gRobaTr4Tip )
         _TCarDaz := gRobaTr4Tip
      ENDIF

   ENDIF

   IF ( _ZavTr == 0 .OR. lForce == .T. .OR. lNewItem == .T. )

      _ZavTr := roba->trosk5

      IF !Empty( gRobaTr5Tip )
         _TZavTr := gRobaTr5Tip
      ENDIF

   ENDIF

   RETURN .T.




/*
   Validacija unosa kolicine
 */

FUNCTION V_kol10()

   IF _kolicina < 0  // storno
      nKolS := 0
      nKolZN := 0
      nc1 := nc2 := 0

      IF !Empty( kalk_metoda_nc() )

         kalk_get_nabavna_mag( _datdok, _idfirma, _idroba, _mkonto, @nKolS, @nKolZN, @nC1, @nC2 )

         @ box_x_koord() + 12, box_y_koord() + 30   SAY "Ukupno na stanju "; @ box_x_koord() + 12, Col() + 2 SAY nKols PICT pickol
      ENDIF

      IF _idvd == "16"  // storno prijema
         IF kalk_metoda_nc() $ "13"
            _nc := nC1
         ELSEIF kalk_metoda_nc() == "2"
            _nc := nc2
         ENDIF
      ENDIF
      IF nKols < Abs( _kolicina )
         _ERROR := "1"
         Beep( 2 )
         error_bar( "KA_" + _idfirma + "-" + _idvd + "-" + _brdok, ;
            _idroba + " kol na stanju:" + AllTrim( Str( nKols, 12, 3 ) ) + " treba: " + AllTrim( Str( _kolicina, 12, 3 ) ) )
      ENDIF
      SELECT kalk_pripr
   ENDIF

   RETURN .T.
