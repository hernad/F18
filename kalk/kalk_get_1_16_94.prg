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

// prijem robe 16
// storno 14-ke fakture ! - 94
// storno otpreme  - 97

FUNCTION kalk_get_1_94()

   LOCAL nRVPC

   pIzgSt := .F.   // izgenerisane stavke jos ne postoje

   SET KEY K_ALT_K TO KM94()

   IF nRbr == 1 .AND. kalk_is_novi_dokument()
      _DatFaktP := _datdok
   ENDIF

   IF nRbr == 1 .OR. !kalk_is_novi_dokument() .OR. gMagacin == "1"
      IF _idvd $ "94#97"
         @  box_x_koord() + 6, box_y_koord() + 2   SAY "KUPAC:" GET _IdPartner PICT "@!" VALID Empty( _IdPartner ) .OR. p_partner( @_IdPartner, 6, 18 )
      ENDIF
      @  box_x_koord() + 7, box_y_koord() + 2   SAY "Faktura/Otpremnica Broj:" GET _BrFaktP
      @  box_x_koord() + 7, Col() + 2 SAY "Datum:" GET _DatFaktP   valid {|| .T. }

      @ box_x_koord() + 9, box_y_koord() + 2 SAY8 "Magacinski konto zadužuje"  GET _IdKonto VALID Empty( _IdKonto ) .OR. P_Konto( @_IdKonto, 21, 5 )
      // IF gNW <> "X"
      // @ box_x_koord() + 9, box_y_koord() + 40 SAY "Zaduzuje:" GET _IdZaduz   PICT "@!"  VALID Empty( _idZaduz ) .OR. p_partner( @_IdZaduz, 21, 5 )
      // ELSE
      IF !Empty( cRNT1 )
         @ box_x_koord() + 9, box_y_koord() + 40 SAY "Rad.nalog:"   GET _IdZaduz2  PICT "@!"
      ENDIF
      // ENDIF

      IF _idvd == "16"
         @ box_x_koord() + 10, box_y_koord() + 2   SAY "Prenos na konto          " GET _IdKonto2   VALID Empty( _idkonto2 ) .OR. P_Konto( @_IdKonto2, 21, 5 ) PICT "@!"
         // IF gNW <> "X"
         // @ box_x_koord() + 10, box_y_koord() + 35  SAY "Zaduzuje: "   GET _IdZaduz2  PICT "@!" VALID Empty( _idZaduz ) .OR. p_partner( @_IdZaduz2, 21, 5 )
         // ENDIF
      ENDIF

   ELSE
      @  box_x_koord() + 6, box_y_koord() + 2   SAY "KUPAC: "; ?? _IdPartner
      @  box_x_koord() + 7, box_y_koord() + 2   SAY "Faktura Broj: "; ?? _BrFaktP
      @  box_x_koord() + 7, Col() + 2 SAY "Datum: "; ?? _DatFaktP
      @ box_x_koord() + 9, box_y_koord() + 2 SAY8 "Magacinski konto zadužuje "; ?? _IdKonto
      // IF gNW <> "X"
      // @ box_x_koord() + 9, box_y_koord() + 40 SAY "Zaduzuje: "; ?? _IdZaduz
      // ENDIF

   ENDIF

   @ box_x_koord() + 10, box_y_koord() + 66 SAY "Tarif.br "

   kalk_pripr_form_get_roba( @GetList, @_idRoba, @_idTarifa, _IdVd, kalk_is_novi_dokument(), box_x_koord() + 11, box_y_koord() + 2, @aPorezi, _idPartner )


   @ box_x_koord() + 11, box_y_koord() + 70 GET _IdTarifa VALID P_Tarifa( @_IdTarifa )

   @ box_x_koord() + 12, box_y_koord() + 2   SAY "Kolicina " GET _Kolicina PICTURE PicKol VALID _Kolicina <> 0
   read; ESC_RETURN K_ESC
   IF roba_barkod_pri_unosu()
      _idRoba := Left( _idRoba, 10 )
   ENDIF

   select_o_koncij( _idkonto )
   select_o_tarifa( _IdTarifa )

   SELECT kalk_pripr  // napuni tarifu
   _MKonto := _Idkonto
   _MU_I := "1"



   //check_datum_posljednje_kalkulacije()
   //DuplRoba()

   _GKolicina := 0
   IF kalk_is_novi_dokument()
      select_o_roba(  _IdRoba )
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

   @ box_x_koord() + 13, box_y_koord() + 2    SAY "NAB.CJ   "  GET _NC  PICTURE gPicNC  WHEN V_kol10()

   PRIVATE _vpcsappp := 0


   READ
   _VPC := _nc
   _marza := 0  // vodi se po nc



   _mpcsapp := 0
   nKalkStrana := 2

   _marza := _vpc - _nc
   _MKonto := _Idkonto;_MU_I := "1"
   _PKonto := ""; _PU_I := ""
   SET KEY K_ALT_K TO

   RETURN LastKey()



/*
 *     Magacinska kartica kao pomoc pri unosu 94-ke
 */

// koristi se stkalk14   za stampu kalkulacije
// stkalk 95 za stampu 16-ke
FUNCTION KM94()

   LOCAL nR1, nR2, nR3
   PRIVATE GetList := {}

   SELECT  roba
   nR1 := RecNo()
   SELECT kalk_pripr
   nR2 := RecNo()
   //SELECT tarifa
   //nR3 := RecNo()
   my_close_all_dbf()
   kalk_kartica_magacin( _IdFirma, _idroba, _IdKonto )
   o_kalk_edit()
   SELECT roba
   GO nR1
   SELECT kalk_pripr
   GO nR2
   //SELECT tarifa
   //GO nR3
   SELECT kalk_pripr

   RETURN .T.
