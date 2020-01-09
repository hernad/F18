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

MEMVAR nKalkRBr
MEMVAR GetList
MEMVAR _datfaktp, _datdok, _idkonto, _mkonto, _idkonto2
MEMVAR _vpc, _nc, _marza, _brfaktp, _idroba, _idtarifa, _idvd, _idpartner, _kolicina

FUNCTION kalk_get_1_95_96()

   // lKalkIzgenerisaneStavke := .F. // izgenerisane stavke jos ne postoje

   SET KEY K_ALT_K TO kalk_kartica_magacin_pomoc_unos_14()

   IF nKalkRbr == 1 .AND. kalk_is_novi_dokument()
      _DatFaktP := _datdok
   ENDIF

   IF Empty(_mkonto)
      _mKonto := _idkonto
   ENDIF

   IF nKalkRbr == 1 .OR. !kalk_is_novi_dokument()

      @  box_x_koord() + 5, box_y_koord() + 2   SAY "Dokument Broj:" GET _BrFaktP VALID !Empty( _BrFaktP )
      @  box_x_koord() + 5, Col() + 1 SAY "Datum:" GET _DatFaktP  VALID {||  datum_not_empty_upozori_godina( _datFaktP, "Datum fakture" ) }

      @ box_x_koord() + 8, box_y_koord() + 2 SAY8 "Magacinski konto razdužuje"  GET _mkonto ;
         VALID Empty( _mkonto ) .OR. P_Konto( @_mkonto, 21, 5 )

      // IF !Empty( cRNT1 ) .AND. _idvd $ "95#96"
      // IF ( IsRamaGlas() )
      // @ box_x_koord() + 8, box_y_koord() + 60 SAY "Rad.nalog:" GET _IdZaduz2 PICT "@!" VALID RadNalOK()
      // ELSE
      // @ box_x_koord() + 8, box_y_koord() + 60 SAY "Rad.nalog:" GET _IdZaduz2   PICT "@!"
      // ENDIF
      // ENDIF

      @ box_x_koord() + 9, box_y_koord() + 2   SAY8 "Konto zadužuje            " GET _idkonto2 VALID  Empty( _idkonto2 ) .OR. P_Konto( @_idkonto2, 21, 5 ) PICT "@!"
      @ box_x_koord() + 9, box_y_koord() + 40 SAY8 "Partner zadužuje:" GET _IdPartner  VALID Empty( _idPartner ) .OR. p_partner( @_IdPartner, 21, 5 ) PICT "@!"

   ELSE
      @  box_x_koord() + 6, box_y_koord() + 2   SAY "Dokument Broj: "; ?? _BrFaktP
      @  box_x_koord() + 6, Col() + 2 SAY "Datum: "; ?? _DatFaktP
      @ box_x_koord() + 8, box_y_koord() + 2 SAY8 "Magacinski konto razdužuje "; ?? _mkonto
      @ box_x_koord() + 9, box_y_koord() + 2 SAY8 "Konto zadužuje "; ?? _IdKonto

   ENDIF

   @ box_x_koord() + 10, box_y_koord() + 66 SAY "Tarif.br->"

   kalk_unos_get_roba_id( @GetList, @_idRoba, @_idTarifa, _IdVd, kalk_is_novi_dokument(), box_x_koord() + 11, box_y_koord() + 2 )
   @ box_x_koord() + 11, box_y_koord() + 70 GET _IdTarifa VALID P_Tarifa( @_IdTarifa )

   READ
   ESC_RETURN K_ESC

   IF roba_barkod_pri_unosu()
      _idRoba := Left( _idRoba, 10 )
   ENDIF


   select_o_koncij( _mkonto )
   select_o_tarifa( _IdTarifa )
   SELECT kalk_pripr  // napuni tarifu

   @ box_x_koord() + 13, box_y_koord() + 2   SAY8 "Količina " GET _Kolicina PICTURE PicKol VALID _Kolicina <> 0

   _GKolicina := 0
   IF kalk_is_novi_dokument()
      select_o_roba( _IdRoba )
      _VPC := kalk_vpc_za_koncij()
      _NC := NC
   ENDIF

   IF dozvoljeno_azuriranje_sumnjivih_stavki() .AND. kalk_is_novi_dokument()
      kalk_vpc_po_kartici( @_VPC, _idfirma, _mkonto, _idroba )
      SELECT kalk_pripr
   ENDIF

   nKolicinaNaStanju := 0
   nKolicinaZadnjaNabavka := 0
   nNabCjZadnjaNabavka := nNabCjSrednja := 0

   IF _TBankTr <> "X"

      kalk_get_nabavna_mag( _datdok, _idfirma, _idroba, _mkonto, @nKolicinaNaStanju, @nKolicinaZadnjaNabavka, @nNabCjZadnjaNabavka, @nNabCjSrednja )
      @ box_x_koord() + 12, box_y_koord() + 30   SAY "Ukupno na stanju "; @ box_x_koord() + 12, Col() + 2 SAY nKolicinaNaStanju PICT pickol
      @ box_x_koord() + 13, box_y_koord() + 30   SAY "Srednja nc "; @ box_x_koord() + 13, Col() + 2 SAY nNabCjSrednja PICT pickol

      IF !( roba->tip $ "UT" )

         IF kalk_metoda_nc() $ "13"
            _nc := nNabCjZadnjaNabavka
         ELSEIF kalk_metoda_nc() == "2"
            _nc := nNabCjSrednja
         ENDIF

         IF kalk_metoda_nc() == "2"
            IF _kolicina > 0
               SELECT roba
               hRec := dbf_get_rec()
               hRec[ "nc" ] := _nc
               update_rec_server_and_dbf( "ROBA", hRec, 1, "FULL" )
               SELECT kalk_pripr // nafiluj sifrarnik robe sa nc sirovina, robe
            ENDIF
         ENDIF

      ENDIF
   ENDIF


   SELECT kalk_pripr
   @ box_x_koord() + 14, box_y_koord() + 2  SAY "NAB.CJ   "  GET _NC  PICTURE picnc()  VALID kalk_valid_kolicina_mag( nKolicinaNaStanju )

   @ box_x_koord() + 15, box_y_koord() + 2  SAY "VPC      "  GET _VPC  PICTURE piccdem() WHEN set_vpc_mag_16_95_96()

   READ


   nKalkStrana := 2
   _Marza := 0
   _TMarza := "A"
   _MU_I := "5"
   _PKonto := ""
   _PU_I := ""


   SET KEY K_ALT_K TO

   RETURN LastKey()

/*
STATIC FUNCTION RadNalOK()

   LOCAL nArr
   LOCAL lOK
   LOCAL nLenBrDok

   IF ( !IsRamaGlas() )
      RETURN .T.
   ENDIF
   nArr := Select()
   lOK := .T.
   nLenBrDok := Len( _idZaduz2 )
   SELECT rnal
   HSEEK PadR( _idZaduz2, 10 )
   IF !Found()
      MsgBeep( "Unijeli ste nepostojeci broj radnog naloga. Otvaram sifrarnik radnih##naloga da biste mogli izabrati neki od postojecih!" )
      P_fakt_objekti( @_idZaduz2, 8, 60 )
      _idZaduz2 := PadR( _idZaduz2, nLenBrDok )
      ShowGets()
   ENDIF
   SELECT ( nArr )

   RETURN lOK
*/


FUNCTION set_vpc_mag_16_95_96()

   _vpc := vpc_magacin_rs_priprema()
   _marza := _vpc - _nc

   RETURN .F.
