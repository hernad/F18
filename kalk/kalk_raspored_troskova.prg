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

MEMVAR gZaokr
MEMVAR _Prevoz, _TPrevoz, _BankTr, _ZavTr, _CarDaz, _SpedTr
MEMVAR _fcj, _vpc, _rabat, _kolicina, _idvd, _rbr, _fcj2
MEMVAR nPrevoz, nBankTr, nSpedTr, nMarza, nMarza2, nCarDaz, nZavTr

FUNCTION kalk_raspored_troskova( lSilent, hTrosakSet, cSet, nSetStep )

   LOCAL nStUc := 20
   LOCAL cTipPrevoz := "0", nIznosPrevoz
   LOCAL cTipCarDaz := "0", nIznosCarDaz
   LOCAL cTipBankTr := "0", nIznosBankTr
   LOCAL cTipSpedTr := "0", nIznosSpedTr
   LOCAL cTipZavTr := "0", nIznosZavTr
   LOCAL nUBankTr, nUPrevoz, nUZavTr, nUSpedTr, nUCarDaz
   LOCAL nUkupanIznosFakture, nUkupnoTezina, nUkupnoKolicina, cJmj
   LOCAL cIdFirma, cIdVd, cBrDok
   LOCAL nPrviRec
   LOCAL nSet, nSetEnd, lExit := .F. // end for next petlje
   LOCAL nProcKorak := 0.01
   LOCAL cOdgovor := "N"
   LOCAL nDodaj, nFV, nStavkaObracunato, nDeltaStvarnoObracunato, nUkupnoObracunato, nNovaStopa
   LOCAL nRNUkupnoProdVrijednost
   LOCAL GetList := {}

   IF lSilent == NIL
      lSilent := .F.
   ENDIF
   IF !lSilent .AND. ( cSet == NIL  ) .AND. ( cOdgovor := Pitanje(, "Rasporediti troškove (D/N/X) ?", "N", "DNX" ) ) == "N"
      RETURN .F.
   ENDIF

   // PRIVATE qqTar := ""
   // PRIVATE aUslTar := ""

   IF cSet == NIL
      nSetEnd := 1
      cSet := ""
   ELSE
      IF cSet != "cardaz"
         MsgBeep( "Implementiran ALG-2 samo za cardaz!" )
      ENDIF

      hTrosakSet[ cSet + "_last"   ] := hTrosakSet[ cSet + "_0" ]
      hTrosakSet[ cSet + "_last_2" ] := hTrosakSet[ cSet + "_0" ]

      IF nSetStep != NIL
         nSetEnd := 1
         hTrosakSet[ cSet + "_step" ] := nSetStep
      ELSE
         nSetEnd := 1000
         hTrosakSet[ cSet + "_step" ] := 0
      ENDIF

   ENDIF

   IF kalk_pripr->idvd $ "16#80"
      Box(, 1, 55 )
      IF kalk_pripr->idvd == "16"
         @ box_x_koord() + 1, box_y_koord() + 2 SAY8 "Stopa marže (vpc - stopa*vpc)=nc:" GET nStUc PICT "999.999"
      ELSE
         @ box_x_koord() + 1, box_y_koord() + 2 SAY8 "Stopa marže (mpc-stopa*mpcsapp)=nc:" GET nStUc PICT "999.999"
      ENDIF
      READ
      BoxC()
   ENDIF
   GO TOP

   select_o_koncij( kalk_pripr->mkonto )
   SELECT kalk_pripr

// IF IsVindija()
// PushWA()
   // IF !Empty( qqTar )
   // aUslTar := Parsiraj( qqTar, "idTarifa" )
   // IF aUslTar <> NIL .AND. !aUslTar == ".t."
   // SET FILTER TO &aUslTar
   // ENDIF
   // ENDIF
   // ENDIF

   DO WHILE !Eof()
      nUkupanIznosFakture := 0
      nUkupnoTezina := 0
      nUkupnoKolicina := 0
      nRNUkupnoProdVrijednost := 0

      cIdFirma := field->idfirma
      cIdVd := field->idvd
      cBrDok := field->Brdok

      nPrviRec := RecNo()
      DO WHILE !Eof() .AND. cIdFirma == kalk_pripr->idfirma .AND. cIdVd == kalk_pripr->idvd .AND. cBrDok == kalk_pripr->BrDok

         cJmj := "KG "
         nUkupnoTezina += svedi_na_jedinicu_mjere( kalk_pripr->kolicina, kalk_pripr->idroba, @cJmj )
         nUkupnoKolicina += field->kolicina

         IF cIdVd $ "10#16#81#80"
            nUkupanIznosFakture += Round( field->fcj * ( 1 - field->Rabat / 100 ) * field->kolicina, gZaokr ) // zaduzenje magacina,prodavnice
         ENDIF

         IF cIdVd $ "11#12#13"
            nUkupanIznosFakture += Round( field->fcj * field->kolicina, gZaokr ) // magacin-> prodavnica,povrat
         ENDIF

         IF cIdVd $ "RN"
            IF Val( kalk_pripr->Rbr ) < 900
               nRNUkupnoProdVrijednost += Round( field->vpc * field->kolicina, gZaokr )
            ELSE
               nUkupanIznosFakture += Round( field->nc * field->kolicina, gZaokr )  // sirovine
            ENDIF
         ENDIF
         SKIP
      ENDDO

      IF cIdVd $ "10#16#81#80#RN"  // zaduzenje magacina,prodavnice

         Box(, 3, 60, iif( Empty( cSet ), .T., .F. ) )
         lExit := .F.
         FOR nSet := 1 TO nSetEnd
            GO nPrviRec

            cTipPrevoz := "0"
            nIznosPrevoz := 0
            cTipCarDaz := "0"
            nIznosCarDaz := 0
            cTipBankTr := "0"
            nIznosBankTr := 0
            cTipSpedTr := "0"
            nIznosSpedTr := 0
            cTipZavTr := "0"
            nIznosZavTr := 0

            cTipPrevoz := field->TPrevoz
            nIznosPrevoz := field->Prevoz
            cTipCarDaz :=  field->TCarDaz
            nIznosCarDaz := field->CarDaz
            cTipBankTr := field->TBankTr
            nIznosBankTr := field->BankTr
            cTipSpedTr := field->TSpedTr
            nIznosSpedTr := field->SpedTr
            cTipZavTr := field->TZavTr
            nIznosZavTr := field->ZavTr

            nUBankTr := 0   // do sada utroseno na bank tr itd, radi "sitnisha"
            nUPrevoz := 0
            nUZavTr := 0
            nUSpedTr := 0
            nUCarDaz := 0

            IF nSetStep == NIL .AND. !Empty( cSet ) // nSetStep != NIL - obraditi sa definisanim stepom
               IF ( hTrosakSet[ cSet ] - hTrosakSet[ cSet + "_last" ] ) > 0
                  IF hTrosakSet[ cSet ] - hTrosakSet[ cSet + "_last_2" ] < 0
                     nProcKorak := nProcKorak / 2 // zadnji veci, a predzadnji rezultat manji, znaci treba smanjiti korak
                  ENDIF
                  IF nSetStep == NIL
                     hTrosakSet[ cSet + "_step" ] += nProcKorak
                  ENDIF
               ELSE
                  IF hTrosakSet[ cSet ] - hTrosakSet[ cSet + "_last_2" ] > 0
                     nProcKorak := nProcKorak / 2 // zadnji manji, a predzadnji rezultat veci
                  ENDIF
                  IF nSetStep == NIL
                     hTrosakSet[ cSet + "_step" ] -= nProcKorak
                  ENDIF
               ENDIF

            ENDIF

            @ box_x_koord() + 1, box_y_koord() + 2 SAY "Step set " + cSet + " step: " + AllTrim( kalk_say_iznos( nSet ) )

            IF !Empty( cSet )
               ??  " / " +  AllTrim( kalk_say_iznos( hTrosakSet[ cSet + "_step" ] ) )
            ENDIF


            DO WHILE !Eof() .AND. cIdFirma == field->idfirma .AND. cIdVd == field->idvd .AND. cBrDok == field->BrDok

               Scatter()

               IF _idvd == "RN" .AND. Val( _rbr ) < 900
                  IF Round( nRNUkupnoProdVrijednost, 4 ) == 0
                     error_bar( "RN", "RN stavke - ukupna prodajna vrijednost 0?!" )
                     _fcj := _fcj2 := 0
                  ELSE
                     _fcj := _fcj2 := _vpc / nRNUkupnoProdVrijednost * nUkupanIznosFakture // nabavne cijene proporcionalno prodajnim
                  ENDIF
               ENDIF

               IF cTipPrevoz $ "RT"  // troskovi 1 - R - raspored, T - raspored po tezini
                  IF Round( nUkupanIznosFakture, 4 ) == 0
                     _Prevoz := 0
                  ELSE

                     IF cTipPrevoz == "T"
                        cJmj := "KG "
                        _Prevoz := Round( svedi_na_jedinicu_mjere( _kolicina, _idroba, cJmj ) / nUkupnoTezina * nIznosPrevoz, gZaokr )
                     ELSE
                        _Prevoz := Round( _fcj * ( 1 - _Rabat / 100 ) * _kolicina / nUkupanIznosFakture * nIznosPrevoz, gZaokr )
                     ENDIF

                     nUPrevoz += _Prevoz
                     IF Abs( nIznosPrevoz - nUPrevoz ) < 0.1 // sitnish, baci ga na zadnju st.
                        SKIP
                        IF !( !Eof() .AND. cIdFirma == kalk_pripr->idfirma .AND. cIdVd == kalk_pripr->idvd .AND. cBrDok == kalk_pripr->BrDok )
                           _Prevoz += ( nIznosPrevoz - nUPrevoz )
                        ENDIF
                        SKIP -1
                     ENDIF
                  ENDIF
                  _TPrevoz := "U"


               ELSEIF cTipPrevoz == "%"
                  IF cSet == "prevoz" .AND. _Prevoz > 0
                     _Prevoz += hTrosakSet[ cSet + "_step" ]
                  ENDIF
                  nUPrevoz += _fcj * ( 1 - _Rabat / 100 ) * _kolicina * _Prevoz / 100
               ENDIF

               IF cTipCarDaz $ "RT"   // troskovi 2
                  IF Round( nUkupanIznosFakture, 4 ) == 0
                     _CarDaz := 0
                  ELSE
                     IF cTipCarDaz == "T"
                        cJmj := "KG "
                        _CarDaz := Round( svedi_na_jedinicu_mjere( _kolicina, _idroba, cJmj ) / nUkupnoTezina * nIznosCarDaz, gZaokr )
                     ELSE
                        _CarDaz := Round( _fcj * ( 1 - _Rabat / 100 ) * _kolicina / nUkupanIznosFakture * nIznosCarDaz, gZaokr )
                     ENDIF

                     nUCarDaz += _Cardaz
                     IF Abs( nIznosCarDaz - nUCarDaz ) < 0.1 // sitniš, baci ga na zadnju stavku
                        SKIP
                        IF !( !Eof() .AND. cIdFirma == idfirma .AND. cIdVd == idvd .AND. cBrDok == BrDok )
                           _Cardaz += ( nIznosCarDaz - nUCarDaz )
                        ENDIF
                        SKIP -1
                     ENDIF
                  ENDIF
                  _TCarDaz := "U"

               ELSEIF cTipCarDaz == "%"
                  /*
                  IF cSet == "cardaz" .AND. _CarDaz > 0
                     _CarDaz += hTrosakSet[ cSet + "_step" ]
                  ENDIF
                  nUCarDaz += _fcj * ( 1 - _Rabat / 100 ) * _kolicina * _Cardaz / 100
                  */

                  // dodaj=iznos_carine_stavka_0/ukupno_obracunata_carina_0*ukupno_razlika_carina
                  nFV := _fcj * ( 1 - _Rabat / 100 ) * _kolicina
                  nStavkaObracunato := nFV * _Cardaz / 100
                  IF cSet == "cardaz" .AND. _CarDaz > 0
                     nDeltaStvarnoObracunato := hTrosakSet[ cSet ] - hTrosakSet[ cSet + "_0" ]
                     nUkupnoObracunato :=  hTrosakSet[ cSet + "_0" ]
                     nDodaj := nStavkaObracunato / nUkupnoObracunato * nDeltaStvarnoObracunato
                     // nova_stopa = (iznos_carine_stavka_0+dodaj)/fakt_vrijednost
                     nNovaStopa := ( nStavkaObracunato + nDodaj ) / nFV * 100
                     _CarDaz := nNovaStopa
                     nUCarDaz += nFV * nNovaStopa / 100
                  ELSE
                     nUCarDaz += nStavkaObracunato
                  ENDIF

               ENDIF

               IF cTipBankTr  $ "RT" // troskovi 3
                  IF Round( nUkupanIznosFakture, 4 ) == 0
                     _BankTr := 0
                  ELSE

                     IF cTipCarDaz == "T"
                        cJmj := "KG "
                        _BankTr := Round( svedi_na_jedinicu_mjere( _kolicina, _idroba, cJmj ) / nUkupnoTezina * nIznosBankTr, gZaokr )
                     ELSE
                        _BankTr := Round( _fcj * ( 1 - _Rabat / 100 ) * _kolicina / nUkupanIznosFakture * nIznosBankTr, gZaokr )
                     ENDIF

                     nUBankTr += _BankTr
                     IF Abs( nIznosBankTr - nUBankTr ) < 0.1 // sitniç, baci ga na zadnju st.
                        SKIP
                        IF !( !Eof() .AND. cIdFirma == idfirma .AND. cIdVd == idvd .AND. cBrDok == BrDok )
                           _BankTr += ( nIznosBankTr - nUBankTr )
                        ENDIF
                        SKIP -1
                     ENDIF
                  ENDIF
                  _TBankTr := "U"

               ELSEIF cTipBankTr == "%"

                  IF cSet == "banktr" .AND. _Prevoz > 0
                     _BankTr += hTrosakSet[ cSet + "_step" ]
                  ENDIF
                  nUBankTr += _fcj * ( 1 - _Rabat / 100 ) * _kolicina * _BankTr / 100
               ENDIF

               IF cTipSpedTr  $ "RT"  // troskovi 4
                  IF Round( nUkupanIznosFakture, 4 ) == 0
                     _SpedTr := 0
                  ELSE

                     IF cTipCarDaz == "T"
                        cJmj := "KG "
                        _SpedTr := Round( svedi_na_jedinicu_mjere( _kolicina, _idroba, cJmj ) / nUkupnoTezina * nIznosSpedTr, gZaokr )
                     ELSE

                        _SpedTr := Round( _fcj * ( 1 - _Rabat / 100 ) * _kolicina / nUkupanIznosFakture * nIznosSpedTr, gZaokr )
                     ENDIF

                     nUSpedTr += _SpedTr
                     IF Abs( nIznosSpedTr - nUSpedTr ) < 0.1 // sitnish baci ga na zadnju st.
                        SKIP
                        IF !( !Eof() .AND. cIdFirma == idfirma .AND. cIdVd == idvd .AND. cBrDok == BrDok )
                           _SpedTr += ( nIznosSpedTr - nUSpedTr )
                        ENDIF
                        SKIP -1
                     ENDIF
                  ENDIF
                  _TSpedTr := "U"

               ELSEIF cTipSpedTr == "%"
                  IF cSet == "spedtr" .AND. _SpedTr > 0
                     _SpedTr += hTrosakSet[ cSet + "_step" ]
                  ENDIF
                  nUSpedTr += _fcj * ( 1 - _rabat / 100 ) * _kolicina * _SpedTr / 100
               ENDIF


               IF cTipZavTr $ "RT"   // troskovi 5
                  IF Round( nUkupanIznosFakture, 4 ) == 0
                     _ZavTr := 0
                  ELSE

                     IF cTipZavTr == "T"
                        cJmj := "KG "
                        _ZavTr := Round( svedi_na_jedinicu_mjere( _kolicina, _idroba, cJmj ) / nUkupnoTezina * nIznosZavTr, gZaokr )
                     ELSE
                        _ZavTr := Round( _fcj * ( 1 - _Rabat / 100 ) * _kolicina / nUkupanIznosFakture * nIznosZavTr, gZaokr )
                     ENDIF

                     nUZavTr += _ZavTR
                     IF Abs( nIznosZavTr - nUZavTr ) < 0.1 // sitnish, baci ga na zadnju st.
                        SKIP
                        IF !( !Eof() .AND. cIdFirma == idfirma .AND. cIdVd == idvd .AND. cBrDok == BrDok )
                           _ZavTR += ( nIznosZavTr - nUZavTr )
                        ENDIF
                        SKIP -1
                     ENDIF
                  ENDIF
                  _TZavTr := "U"

               ELSEIF cTipZavTr == "%"
                  IF cSet == "zavtr" .AND. _ZavTr > 0
                     _ZavTr += hTrosakSet[ cSet + "_step" ]
                  ENDIF
                  nUZavTr += _fcj * ( 1 - _Rabat / 100 ) * _kolicina * _ZavTr / 100
               ENDIF

               select_o_roba( _idroba )
               select_o_tarifa( _idtarifa )

               SELECT kalk_pripr
               IF _idvd == "RN"
                  IF Val( _rbr ) < 900
                     kalk_when_valid_nc_ulaz()
                  ENDIF
               ELSE
                  kalk_when_valid_nc_ulaz()
               ENDIF

               IF _idvd == "16"
                  _nc := _vpc * ( 1 - nStUc / 100 )
               ENDIF
               IF _idvd == "80"
                  _nc := _mpc - _mpcsapp * nStUc / 100
                  _vpc := _nc
                  _TMarza2 := "A"
                  _Marza2 := _mpc - _nc
               ENDIF

               IF koncij->naz == "N1"
                  _VPC := _NC
               ENDIF
               IF _idvd == "RN"
                  IF Val( _rbr ) < 900
                     kalk_10_pr_rn_valid_vpc_set_marza_polje_nakon_iznosa()
                  ENDIF
               ELSE
                  kalk_10_pr_rn_valid_vpc_set_marza_polje_nakon_iznosa()
               ENDIF

               IF nSetEnd == 1
                  my_rlock()
                  Gather()
                  my_unlock()
               ENDIF
               SKIP
            ENDDO

            @ box_x_koord() + 3, box_y_koord() + 2 SAY "Step set " + cSet + " iznos: "
            SWITCH cSet
            CASE "prevoz"
               ?? kalk_say_iznos( nUPrevoz )
               hTrosakSet[ "prevoz_last_2" ] := hTrosakSet[ "prevoz_last" ]
               hTrosakSet[ "prevoz_last" ] := nUPrevoz
               IF nSetStep == NIL .AND.  Round( hTrosakSet[ "prevoz" ] - nUPrevoz, 2 ) == 0
                  MsgBeep( "HIT 1!" )
                  lExit := .T.
               ENDIF
               EXIT

            CASE "banktr"
               ?? kalk_say_iznos( nUBankTr )
               hTrosakSet[ "banktr_last_2" ] := hTrosakSet[ "banktr_last" ]
               hTrosakSet[ "banktr_last" ] := nUBankTr
               IF nSetStep == NIL .AND. Round( hTrosakSet[ "banktr" ] - nUBanktr, 2 ) == 0
                  MsgBeep( "HIT 2!" )
                  lExit := .T.
               ENDIF
               EXIT

            CASE "spedtr"
               ?? kalk_say_iznos( nUSpedtr )
               hTrosakSet[ "spedtr_last_2" ] := hTrosakSet[ "spedtr_last" ]
               hTrosakSet[ "spedtr_last" ] := nUSpedTr
               IF nSetStep == NIL .AND. Round( hTrosakSet[ "spedtr" ] - nUSpedTr, 2 ) == 0
                  MsgBeep( "HIT spedtr!" )
                  lExit := .T.
               ENDIF
               EXIT

            CASE "zavtr"
               ?? kalk_say_iznos( nUZavTr )
               hTrosakSet[ "zavtr_last_2" ] := hTrosakSet[ "zavtr_last" ]
               hTrosakSet[ "zavtr_last" ] := nUZavTr
               IF nSetStep == NIL .AND. Round( hTrosakSet[ "zavtr" ] - nUZavTr, 2 ) == 0
                  MsgBeep( "HIT zavtr!" )
                  lExit := .T.
               ENDIF
               EXIT


            CASE "cardaz"
               ?? kalk_say_iznos( nUCarDaz )
               hTrosakSet[ "cardaz_last_2" ] := hTrosakSet[ "cardaz_last" ]
               hTrosakSet[ "cardaz_last" ] := nUCarDaz
               IF nSetStep == NIL .AND. Round( hTrosakSet[ "cardaz" ] - nUCarDaz, 2 ) == 0
                  MsgBeep( "HIT cardaz!" )
                  lExit := .T.
               ENDIF
               EXIT

            ENDSWITCH


            IF lExit
               EXIT
            ENDIF

         NEXT
         BoxC()

         IF !Empty( cSet ) .AND. lExit // pronadjen step, promijeni tabelu

            IF nSetEnd > 1 .AND. nSetStep == NIL // nije bio poziv sa zadanim stepom
               RETURN kalk_raspored_troskova( lSilent, hTrosakSet, cSet, hTrosakSet[ cSet + "_step" ] )
            ENDIF
         ENDIF

      ENDIF // cIdVd $ 10


      IF cIdVd $ "11#12#13"
         GO nPrviRec
         cTipPrevoz := .F. ;nIznosPrevoz := 0
         IF TPrevoz == "R"; cTipPrevoz := .T. ;nIznosPrevoz := Prevoz; ENDIF
         nMarza2 := 0
         DO WHILE !Eof() .AND. cIdFirma == idfirma .AND. cIdVd == idvd .AND. cBrDok == BrDok
            Scatter()
            IF cTipPrevoz    // troskovi 1
               IF Round( nUkupanIznosFakture, 4 ) == 0
                  _Prevoz := 0
               ELSE
                  _Prevoz := _fcj / nUkupanIznosFakture * nIznosPrevoz
               ENDIF
               _TPrevoz := "A"
            ENDIF
            _nc := _fcj + _prevoz
            IF koncij->naz == "N1"; _VPC := _NC; ENDIF
            _marza := _VPC - _FCJ
            _TMarza := "A"
            select_o_roba( _idroba )
            select_o_tarifa( _idtarifa )
            SELECT kalk_pripr
            kalk_Marza_11()
            _TMarza2 := "A"
            _Marza2 := nMarza2
            my_rlock()
            Gather()
            my_unlock()
            SKIP
         ENDDO
      ENDIF // cIdVd $ "11#12#13"
   ENDDO  // eof()

// IF IsVindija()
// SELECT kalk_pripr
// PopWA()
// ENDIF

   GO TOP


   IF cOdgovor == "X" .AND. !lSilent .AND. cIdVd == "10" .AND. hTrosakSet == NIL

      hTrosakSet := raspored_procent_tr( cTipPrevoz, nUPrevoz, cTipCarDaz, nUCarDaz, ;
         cTipBankTr, nUBankTr, cTipSpedTr, nUSpedTr, cTipZavTr, nUZavTr )

      IF hb_HHasKey( hTrosakSet, "prevoz" ) .AND. ( hTrosakSet[ "prevoz" ] - hTrosakSet[ "prevoz_0" ]  <> 0 )
         RETURN kalk_raspored_troskova( lSilent, hTrosakSet, "prevoz" )
      ENDIF

      IF hb_HHasKey( hTrosakSet, "cardaz" ) .AND. ( hTrosakSet[ "cardaz" ] - hTrosakSet[ "cardaz_0" ]  <> 0 )
         RETURN kalk_raspored_troskova( lSilent, hTrosakSet, "cardaz" )
      ENDIF

      IF hb_HHasKey( hTrosakSet, "banktr" ) .AND. ( hTrosakSet[ "banktr" ] - hTrosakSet[ "banktr_0" ]  <> 0 )
         RETURN kalk_raspored_troskova( lSilent, hTrosakSet, "banktr" )
      ENDIF

      IF hb_HHasKey( hTrosakSet, "zavtr" ) .AND. ( hTrosakSet[ "zavtr" ] - hTrosakSet[ "zavtr_0" ]  <> 0 )
         RETURN kalk_raspored_troskova( lSilent, hTrosakSet, "zavtr" )
      ENDIF

   ENDIF

   RETURN .T.



FUNCTION raspored_procent_tr( cTipPrevoz, nIznosPrevoz, cTipCarDaz, nIznosCarDaz, ;
      cTipBankTr, nIznosBankTr, cTipSpedTr, nIznosSpedTr, cTipZavTr, nIznosZavTr )

   LOCAL hRet := hb_Hash(), GetList := {}, cKey

   Box( "##Postavi % trosak", 7, 60 )

   IF cTipPrevoz == "%"  .AND. Round(  nIznosPrevoz, 3 ) >  0
      hRet[ "prevoz_0" ] := nIznosPrevoz
      hRet[ "prevoz" ] := nIznosPrevoz
      @ box_x_koord() + 1, box_y_koord() + 2 SAY  " [T1] : " + kalk_say_iznos( nIznosPrevoz ) GET hRet[ "prevoz" ]

   ENDIF

   IF cTipBankTr == "%" .AND. Round(  nIznosBankTr, 3 ) >  0
      hRet[ "banktr_0" ] := nIznosBankTr
      hRet[ "banktr" ] := nIznosBankTr
      @ box_x_koord() + 2, box_y_koord() + 2 SAY  " [T2]  " + kalk_say_iznos( nIznosBankTr ) GET hRet[ "banktr" ]
   ENDIF

   IF cTipSpedTr == "%" .AND. Round(  nIznosSpedTr, 3 ) >  0
      hRet[ "spedtr_0" ] := nIznosSpedTr
      hRet[ "spedtr" ] := nIznosSpedTr
      @ box_x_koord() + 3, box_y_koord() + 2 SAY  " [T3]  " + kalk_say_iznos( nIznosSpedTr ) GET hRet[ "spedtr" ]
   ENDIF

   IF cTipCarDaz == "%" .AND. Round(  nIznosCarDaz, 3 ) >  0
      hRet[ "cardaz_0" ] := nIznosCarDaz
      hRet[ "cardaz" ] := nIznosCarDaz
      @ box_x_koord() + 4, box_y_koord() + 2 SAY  " [T4]  " + kalk_say_iznos( nIznosCarDaz ) GET hRet[ "cardaz" ]
   ENDIF

   IF cTipZavTr == "%" .AND. Round(  nIznosZavTr, 3 ) >  0
      hRet[ "zavtr_0" ] := nIznosCarDaz
      hRet[ "zavtr" ] := nIznosZavTr
      @ box_x_koord() + 5, box_y_koord() + 2 SAY  " [T5]  " + kalk_say_iznos( nIznosZavTr ) GET hRet[ "zavtr" ]
   ENDIF

   READ
   BoxC()

   IF LastKey() == K_ESC
      FOR EACH cKey in hRet:Keys
         hRet[ cKey ] := 0
      NEXT
   ENDIF

   RETURN hRet


/*
 *     Proracun iznosa troskova pri unosu u kalk_pripremi
*/

FUNCTION kalk_set_troskovi_priv_vars_ntrosakx_nmarzax()

   LOCAL nStvarnaKolicina := 0

   nStvarnaKolicina := field->Kolicina

   IF field->TPrevoz == "%"
      nPrevoz := field->Prevoz / 100 * field->FCj2
   ELSEIF field->TPrevoz == "A"
      nPrevoz := field->Prevoz
   ELSEIF field->TPrevoz == "U"
      IF nStvarnaKolicina <> 0
         nPrevoz := field->Prevoz / nStvarnaKolicina
      ELSE
         nPrevoz := 0
      ENDIF
   ELSE
      nPrevoz := 0
   ENDIF

   IF field->TCarDaz == "%"
      nCarDaz := field->CarDaz / 100 * field->FCj2
   ELSEIF field->TCarDaz == "A"
      nCarDaz := field->CarDaz
   ELSEIF field->TCarDaz == "U"
      IF nStvarnaKolicina <> 0
         nCarDaz := field->CarDaz / nStvarnaKolicina
      ELSE
         nCarDaz := 0
      ENDIF
   ELSE
      nCarDaz := 0
   ENDIF

   IF field->TZavTr == "%"
      nZavTr := field->ZavTr / 100 * field->FCj2
   ELSEIF field->TZavTr == "A"
      nZavTr := field->ZavTr
   ELSEIF field->TZavTr == "U"
      IF nStvarnaKolicina <> 0
         nZavTr := field->ZavTr / nStvarnaKolicina
      ELSE
         nZavTr := 0
      ENDIF
   ELSE
      nZavTr := 0
   ENDIF

   IF field->TBankTr == "%"
      nBankTr := field->BankTr / 100 * field->FCj2
   ELSEIF field->TBankTr == "A"
      nBankTr := field->BankTr
   ELSEIF field->TBankTr == "U"
      IF nStvarnaKolicina <> 0
         nBankTr := field->BankTr / nStvarnaKolicina
      ELSE
         nBankTr := 0
      ENDIF
   ELSE
      nBankTr := 0
   ENDIF

   IF field->TSpedTr == "%"
      nSpedTr := field->SpedTr / 100 * field->FCj2
   ELSEIF field->TSpedTr == "A"
      nSpedTr := field->SpedTr
   ELSEIF field->TSpedTr == "U"
      IF nStvarnaKolicina <> 0
         nSpedTr := field->SpedTr / nStvarnaKolicina
      ELSE
         nSpedTr := 0
      ENDIF
   ELSE
      nSpedTr := 0
   ENDIF

   IF field->IdVD $ "14"   // izlaz po vp
      nMarza := field->VPC * ( 1 - field->Rabatv / 100 ) - field->NC
   ELSEIF field->idvd $ "11#12#13"
      nMarza := field->VPC - field->FCJ
   ELSE
      nMarza := field->VPC - field->NC
   ENDIF

   IF ( field->idvd $ "11#12#13" )
      nMarza2 := field->MPC - field->VPC - nPrevoz
   ELSEIF ( ( field->idvd $ "41#42#81" ) )
      nMarza2 := field->MPC - field->NC
   ELSE
      nMarza2 := field->MPC - field->VPC
   ENDIF

   RETURN .T.
