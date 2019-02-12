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

FUNCTION kalk_get_1_14()

   LOCAL dDatVal := CToD( "" ), nNabCj1, nNabCj2

   lKalkIzgenerisaneStavke := .F.

   SET KEY K_ALT_K TO kalk_kartica_magacin_pomoc_unos_14()

   IF nKalkRbr == 1 .AND. kalk_is_novi_dokument()
      _DatFaktP := _datdok
   ENDIF

   IF nKalkRbr == 1 .OR. !kalk_is_novi_dokument()
      @ box_x_koord() + 6, box_y_koord() + 2   SAY "KUPAC:" GET _IdPartner PICT "@!" VALID Empty( _IdPartner ) .OR. p_partner( @_IdPartner, 6, 18 )
      @ box_x_koord() + 7, box_y_koord() + 2   SAY "Faktura Broj:" GET _BrFaktP
      @ box_x_koord() + 7, Col() + 2 SAY "Datum:" GET _DatFaktP   VALID {|| .T. }
      @ box_x_koord() + 7, Col() + 2 SAY "DatVal:" GET dDatVal ;
         WHEN  {|| dDatVal := get_kalk_14_datval( _brdok ), .T. } ;
         VALID {|| update_kalk_14_datval( _BrDok, dDatVal ), .T. }
      _IdZaduz := ""
      _Idkonto := "2110"
      PRIVATE cNBrDok := _brdok
      @ box_x_koord() + 9, box_y_koord() + 2 SAY8 "Magacinski konto razdužuje"  GET _IdKonto2  VALID ( Empty( _IdKonto2 ) .OR. P_Konto( @_IdKonto2, 21, 5 ) )

   ELSE
      @ box_x_koord() + 6, box_y_koord() + 2   SAY8 "KUPAC: "; ?? _IdPartner
      @ box_x_koord() + 7, box_y_koord() + 2   SAY8 "Faktura Broj: "; ?? _BrFaktP
      @ box_x_koord() + 7, Col() + 2 SAY8 "Datum: "; ?? _DatFaktP

      _IdZaduz := ""
      _Idkonto := "2110"
      @ box_x_koord() + 9, box_y_koord() + 2 SAY8 "Magacinski konto razdužuje "; ?? _IdKonto2

   ENDIF

   @ box_x_koord() + 10, box_y_koord() + 66 SAY "Tarif.br "
   kalk_pripr_form_get_roba( @GetList, @_idRoba, @_idTarifa, _IdVd, kalk_is_novi_dokument(), box_x_koord() + 11, box_y_koord() + 2, @aPorezi )
   @ box_x_koord() + 11, box_y_koord() + 70 GET _IdTarifa VALID P_Tarifa( @_IdTarifa )
   @ box_x_koord() + 12, box_y_koord() + 2   SAY8 "Količina " GET _Kolicina PICTURE PicKol VALID _Kolicina <> 0

   READ
   ESC_RETURN K_ESC

   _MKonto := _Idkonto2

   IF roba_barkod_pri_unosu()
      _idRoba := Left( _idRoba, 10 )
   ENDIF

   select_o_tarifa( _IdTarifa )
   select_o_roba( _IdRoba )
   select_o_koncij( _idkonto2 )
   SELECT kalk_pripr

   IF koncij->naz = "P"
      _FCJ := roba->PlC
   ENDIF

   IF kalk_is_novi_dokument()
      _VPC := kalk_vpc_za_koncij()
      SELECT roba
      _NC := NC
      SELECT kalk_pripr
   ENDIF

   IF dozvoljeno_azuriranje_sumnjivih_stavki() .AND. kalk_is_novi_dokument()
      SELECT kalk_pripr
   ENDIF

   _GKolicina := 0
   nKolS := 0
   nKolZN := 0
   nNabCj1 := 0
   nNabCj2 := 0

   IF _TBankTr <> "X"   // ako je X onda su stavke vec izgenerisane

      IF !Empty( kalk_metoda_nc() )
         kalk_get_nabavna_mag( _datdok, _idfirma, _idroba, _idkonto2, @nKolS, @nKolZN, @nNabCj1, @nNabCj2 )
         @ box_x_koord() + 12, box_y_koord() + 30   SAY "Ukupno na stanju "
         @ box_x_koord() + 12, Col() + 2 SAY nKols PICT pickol
      ENDIF

      // Vindija trazi da se uvijek nudi srednja nabavna cijena
      // kada malo razmislim najbolje da se ona uvijek nudi
      // if _kolicina >= 0
      IF kalk_metoda_nc() == "2"
         _nc := nNabCj2
      ENDIF

   ENDIF
   SELECT kalk_pripr


   @ box_x_koord() + 13, box_y_koord() + 2    SAY8 "Nab.Cjena "  GET _NC  PICTURE PicDEM   VALID kalk_valid_kolicina_mag(nKols)

   PRIVATE _vpcsappp := 0

   @ box_x_koord() + 14, box_y_koord() + 2   SAY8 "PC BEZ PDV" GET _VPC  VALID {|| iif( gVarVP == "2" .AND. ( _vpc - _nc ) > 0, cisMarza := ( _vpc - _nc ), _vpc - _nc ), .T. }  PICTURE PicDEM

   PRIVATE cTRabat := "%"
   @ box_x_koord() + 15, box_y_koord() + 2    SAY8 "RABAT    " GET  _RABATV PICT picdem
   @ box_x_koord() + 15, Col() + 2  GET cTRabat  PICT "@!"  VALID {|| kalk_preracun_rabatv_14(), V_RabatV(), cTrabat $ "%AU" }

   _PNAP := 0
   _MPC := tarifa->pdv

   @ box_x_koord() + 16, box_y_koord() + 2 SAY8 "PDV (%)  " + Transform( _MPC, "99.99" )

   IF gVarVP == "1"
      _VPCsaPP := 0
      @ box_x_koord() + 17, box_y_koord() + 2  SAY8 "PC SA PDV "
      @ box_x_koord() + 17, box_y_koord() + 50 GET _vpcSaPP PICTURE picdem ;
         WHEN {|| _VPCSAPP := iif( _VPC <> 0, _VPC * ( 1 - _RabatV / 100 ) * ( 1 + _MPC / 100 ), 0 ), ShowGets(), .T. } ;
         VALID {|| _vpcsappp := iif( _VPCsap <> 0, _vpcsap + _PNAP, _VPCSAPPP ), .T. }

   ELSE
      _VPCsaPP := 0
      @ box_x_koord() + 17, box_y_koord() + 2  SAY8 "PC SA PDV "
      @ box_x_koord() + 17, box_y_koord() + 50 GET _vpcSaPP PICTURE picdem ;
         WHEN {|| _VPCSAPP := iif( _VPC <> 0, _VPC * ( 1 - _RabatV / 100 ) * ( 1 + _MPC / 100 ), 0 ), ShowGets(), .T. } ;
         VALID {|| _vpcsappp := iif( _VPCsap <> 0, _vpcsap + _PNAP, _VPCSAPPP ), .T. }
   ENDIF

   READ

   nKalkStrana := 2
   _mpcsapp := 0
   _marza := _vpc - _nc


   // izlaz iz magacina
   _MKonto := _Idkonto2
   _MU_I := "5"
   _PKonto := ""
   _PU_I := ""

   IF _idvd == "KO"
      _MU_I := "4" // ne utice na stanje
   ENDIF

   IF lKalkIzgenerisaneStavke .AND. _kolicina > 0 .AND. LastKey() <> K_ESC // izgenerisane stavke postoje
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

            REPLACE vpc WITH _vpc, ;
               rabatv WITH _rabatv, ;
               mkonto WITH _mkonto, ;
               tmarza  WITH _tmarza, ;
               mpc     WITH  _MPC, ;
               marza  WITH _vpc - kalk_pripr->nc, ;   // mora se uzeti nc iz ove stavke
               mu_i WITH  _mu_i, ;
               pkonto WITH "", ;
               pu_i WITH  "", ;
               error WITH "0"

         ENDIF
         SKIP
      ENDDO
      my_unlock()
      GO nRRec
   ENDIF

   SET KEY K_ALT_K TO

   RETURN LastKey()


/*
   pPDV14(fret)
   Prikaz PDV pri unosu 14-ke
 */

FUNCTION pPDV14( lRet )

   DevPos( box_x_koord(), box_y_koord() + 41 )
   IF roba->tip $ "VKX"
      // nista ppp
   ELSE
      QQOut( "   PDV:", Transform( _PNAP := _VPC * ( 1 - _RabatV / 100 ) * _MPC / 100, picdem ) )
   ENDIF


   RETURN lRet



   /* V_RabatV
    *     Ispisuje vrijednost rabata u VP
    */

// Trenutna pozicija u tabeli KONCIJ (na osnovu koncij->naz ispituje cijene)
// Trenutan pozicija u tabeli ROBA (roba->tip)

FUNCTION V_RabatV()

   LOCAL nPom, nMPCVT
   LOCAL nRVPC := 0
   LOCAL getlist := {}

   PRIVATE cPom := "VPC"

   IF koncij->naz == "P2"
      cPom := "PLC"
   ELSEIF koncij->naz == "V2"
      cPom := "VPC2"
   ELSE
      cPom := "VPC"
   ENDIF

   IF roba->tip $ "UTY"
      RETURN .T.
   ENDIF

   nRVPC := kalk_vpc_za_koncij()
   IF Round( nRVPC - _vpc, 4 ) <> 0  .AND. gMagacin == "2"
      IF nRVPC == 0
         Beep( 1 )
         Box(, 3, 60 )
         @ box_x_koord() + 1, box_y_koord() + 2 SAY "Roba u sifrarniku ima " + cPom + " = 0 !??"
         @ box_x_koord() + 3, box_y_koord() + 2 SAY "Unesi " + cPom + " u sifrarnik:" GET _vpc PICT picdem

         READ

         SELECT roba
         hRec := dbf_get_rec()

         hRec[ Lower( cPom ) ] := _vpc
         update_rec_server_and_dbf( "roba", hRec, 1, "FULL" )

         SELECT kalk_pripr
         BoxC()

      ENDIF
   ENDIF

   nMarza := _VPC * ( 1 - _RabatV / 100 ) - _NC
   @ box_x_koord() + 15, box_y_koord() + 41  SAY "PC b.pdv.-RAB:"
   @ box_x_koord() + 15, Col() + 1 SAY _Vpc * ( 1 - _RabatV / 100 ) PICT picdem

   ShowGets()

   RETURN .T.


STATIC FUNCTION kalk_preracun_rabatv_14()

   LOCAL nPrRab

   IF cTRabat == "%"
      nPrRab := _rabatv
   ELSEIF cTRabat == "A"
      IF _VPC <> 0
         nPrRab := _RABATV / _VPC * 100
      ELSE
         nPrRab := 0
      ENDIF
   ELSEIF cTRabat == "U"
      IF _vpc * _kolicina <> 0
         nprRab := _rabatV / ( _vpc * _kolicina ) * 100
      ELSE
         nPrRab := 0
      ENDIF
   ELSE
      RETURN .F.
   ENDIF
   _rabatv := nPrRab
   cTrabat := "%"
   showgets()

   RETURN .T.
