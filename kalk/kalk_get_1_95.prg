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
STATIC aPorezi := {}

FUNCTION kalk_get_1_95()

   lKalkIzgenerisaneStavke := .F. // izgenerisane stavke jos ne postoje

   SET KEY K_ALT_K TO kalk_kartica_magacin_pomoc_unos_14()
   IF nKalkRbr == 1 .AND. kalk_is_novi_dokument()
      _DatFaktP := _datdok
   ENDIF

   IF nKalkRbr == 1 .OR. !kalk_is_novi_dokument() .OR. gMagacin == "1"

      @  box_x_koord() + 5, box_y_koord() + 2   SAY "Dokument Broj:" GET _BrFaktP VALID !Empty( _BrFaktP )
      @  box_x_koord() + 5, Col() + 1 SAY "Datum:" GET _DatFaktP  VALID {||  datum_not_empty_upozori_godina( _datFaktP, "Datum fakture" ) }

      _IdZaduz := ""
      @ box_x_koord() + 8, box_y_koord() + 2 SAY8 "Magacinski konto razdužuje"  GET _IdKonto2 ;
         VALID Empty( _IdKonto2 ) .OR. P_Konto( @_IdKonto2, 21, 5 )

      IF !Empty( cRNT1 ) .AND. _idvd $ "97#96#95"
         IF ( IsRamaGlas() )
            @ box_x_koord() + 8, box_y_koord() + 60 SAY "Rad.nalog:" GET _IdZaduz2 PICT "@!" VALID RadNalOK()
         ELSE
            @ box_x_koord() + 8, box_y_koord() + 60 SAY "Rad.nalog:" GET _IdZaduz2   PICT "@!"
         ENDIF
      ENDIF
      // ENDIF
      IF _idvd $ "97#96#95"    // ako je otprema, gdje to ide

         @ box_x_koord() + 9, box_y_koord() + 2   SAY "Konto zaduzuje            " GET _IdKonto VALID  Empty( _IdKonto ) .OR. P_Konto( @_IdKonto, 21, 5 ) PICT "@!"

         IF gMagacin == "1"
            @ box_x_koord() + 9, box_y_koord() + 40 SAY8 "Partner zadužuje:" GET _IdPartner  VALID Empty( _idPartner ) .OR. p_partner( @_IdPartner, 21, 5 ) PICT "@!"
         ELSE
            IF _idvd == "96"
               @ box_x_koord() + 9, box_y_koord() + 40 SAY8 "Partner zadužuje:" GET _IdPartner  VALID Empty( _idPartner ) .OR. p_partner( @_IdPartner, 21, 5 ) PICT "@!"
            ENDIF
         ENDIF

      ELSE
         _idkonto := ""
      ENDIF

   ELSE

      @  box_x_koord() + 6, box_y_koord() + 2   SAY "Dokument Broj: "; ?? _BrFaktP
      @  box_x_koord() + 6, Col() + 2 SAY "Datum: "; ?? _DatFaktP
      _IdZaduz := ""
      @ box_x_koord() + 8, box_y_koord() + 2 SAY "Magacinski konto razduzuje "; ?? _IdKonto2
      @ box_x_koord() + 9, box_y_koord() + 2 SAY "Konto zaduzuje "; ?? _IdKonto

   ENDIF

   @ box_x_koord() + 10, box_y_koord() + 66 SAY "Tarif.br->"

   kalk_pripr_form_get_roba( @GetList, @_idRoba, @_idTarifa, _IdVd, kalk_is_novi_dokument(), box_x_koord() + 11, box_y_koord() + 2, @aPorezi )

   @ box_x_koord() + 11, box_y_koord() + 70 GET _IdTarifa VALID P_Tarifa( @_IdTarifa )

   READ
   ESC_RETURN K_ESC

   IF roba_barkod_pri_unosu()
      _idRoba := Left( _idRoba, 10 )
   ENDIF

   _MKonto := _Idkonto2


   select_o_koncij( _idkonto2 )
   select_o_tarifa( _IdTarifa )
   SELECT kalk_pripr  // napuni tarifu

   @ box_x_koord() + 13, box_y_koord() + 2   SAY8 "Količina " GET _Kolicina PICTURE PicKol VALID _Kolicina <> 0

   _GKolicina := 0
   IF kalk_is_novi_dokument()
      select_o_roba( _IdRoba )
      IF koncij->naz == "P2"
         _VPC := PLC
      ELSE
         _VPC := kalk_vpc_za_koncij()
      ENDIF
      _NC := NC
   ENDIF

   IF dozvoljeno_azuriranje_sumnjivih_stavki() .AND. kalk_is_novi_dokument()
      kalk_vpc_po_kartici( @_VPC, _idfirma, _idkonto2, _idroba )
      SELECT kalk_pripr
   ENDIF

   nKolS := 0
   nKolZN := 0
   nc1 := nc2 := 0

   IF _TBankTr <> "X"

      kalk_get_nabavna_mag( _datdok, _idfirma, _idroba, _idkonto2, @nKolS, @nKolZN, @nC1, @nC2 )
      @ box_x_koord() + 12, box_y_koord() + 30   SAY "Ukupno na stanju "; @ box_x_koord() + 12, Col() + 2 SAY nKols PICT pickol
      @ box_x_koord() + 13, box_y_koord() + 30   SAY "Srednja nc "; @ box_x_koord() + 13, Col() + 2 SAY nc2 PICT pickol

      IF !( roba->tip $ "UT" )

         IF kalk_metoda_nc() $ "13"
            _nc := nc1
         ELSEIF kalk_metoda_nc() == "2"
            _nc := nc2
         ENDIF

         IF kalk_metoda_nc() == "2"
            IF _kolicina > 0
               SELECT roba
               hRec := dbf_get_rec()
               hRec[ "nc" ] := _nc
               update_rec_server_and_dbf( Alias(), hRec, 1, "FULL" )
               SELECT kalk_pripr // nafiluj sifrarnik robe sa nc sirovina, robe
            ENDIF
         ENDIF

      ENDIF
   ENDIF

   SELECT kalk_pripr
   @ box_x_koord() + 14, box_y_koord() + 2  SAY "NAB.CJ   "  GET _NC  PICTURE gPicNC  VALID kalk_valid_kolicina_mag(nKols)
   PRIVATE _vpcsappp := 0

   READ
   _Marza := 0; _TMarza := "A"; _VPC := _NC

   nKalkStrana := 2
   _marza := _vpc - _nc
   _MKonto := _Idkonto2;_MU_I := "5"     // izlaz iz magacina
   _PKonto := ""; _PU_I := ""

   IF lKalkIzgenerisaneStavke  .AND. _kolicina > 0 .AND.  LastKey() <> K_ESC // izgenerisane stavke postoje
      PRIVATE nRRec := RecNo()
      GO TOP
      my_flock()
      DO WHILE !Eof()  // nafiluj izgenerisane stavke
         IF kolicina == 0
            SKIP
            PRIVATE nRRec2 := RecNo()
            SKIP -1
            my_delete()
            GO nRRec2
            LOOP
         ENDIF
         IF brdok == _brdok .AND. idvd == _idvd .AND. Val( Rbr ) == nKalkRbr

            //nMarza := 0
            REPLACE vpc WITH kalk_pripr->nc, vpcsap WITH  kalk_pripr->nc, rabatv WITH  0, ;
               marza WITH  0

            REPLACE  mkonto WITH _mkonto, ;
               tmarza  WITH _tmarza, ;
               mpc WITH  _MPC, ;
               mu_i WITH  _mu_i, ;
               pkonto WITH _pkonto, ;
               pu_i WITH  _pu_i, ;
               error WITH "0"
         ENDIF
         SKIP
      ENDDO
      my_unlock()
      GO nRRec
   ENDIF

   SET KEY K_ALT_K TO

   RETURN LastKey()


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
