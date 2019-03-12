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

MEMVAR gAutoCjen

MEMVAR _idfirma, _datdok, _mkonto, _idroba, _Kolicina, _nc, _fcj, _fcj2, _idvd, _error
MEMVAR _marza, _vpc, _tmarza, _rabatv
MEMVAR _prevoz, _tprevoz, _cardaz, _tcardaz, _zavtr, _tzavtr, _banktr, _tbanktr, _spedtr, _TSpedTr
MEMVAR nKalkPrevoz, nKalkCarDaz, nKalkBankTr, nKalkSpedTr, nKalkZavTr
MEMVAR cFieldName
MEMVAR nKalkMarzaVP
MEMVAR GetList

STATIC s_nPragOdstupanjaNCSumnjiv := NIL
STATIC s_nStandarnaStopaMarze := NIL

/*

   ako je srednja nabavna cijena 0.2 i ako je nabavna cijena posljednjeg ulaza 0.42

   irb(main):009:0> (0.2-0.42)/0.2*100
   => -109.999 %

  odstupanje je 109%, sto okida prag ako je on 99%

*/
FUNCTION prag_odstupanja_nc_sumnjiv( nSet )

   IF  s_nPragOdstupanjaNCSumnjiv == NIL
      s_nPragOdstupanjaNCSumnjiv := fetch_metric( "prag_odstupanja_nc_sumnjiv", NIL, 99.99 ) // 99,99%
   ENDIF

   IF nSet != NIL
      s_nPragOdstupanjaNCSumnjiv := nSet
      set_metric( "prag_odstupanja_nc_sumnjiv", NIL, nSet )
   ENDIF

   RETURN s_nPragOdstupanjaNCSumnjiv


/*

ako je nabavna cijena 0, ponuditi cijenu koja je roba.vpc / ( 1 + standardna_stopa_marze )
npr. vpc=1, standarna_stopa_marze = 20%, nc=0.8

IF Abs( Round( nSrednjaNabavnaCijena, 4 ) ) == 0 .AND. roba->vpc != 0
   nSrednjaNabavnaCijena := Round( roba->vpc / ( 1 + standardna_stopa_marze() / 100 ), 4 )
ENDIF

*/

FUNCTION standardna_stopa_marze( nSet )

   IF s_nStandarnaStopaMarze == NIL
      s_nStandarnaStopaMarze  := fetch_metric( "standarna_stopa_marze", NIL, 19.99 ) // 19.99%
   ENDIF
   IF nSet != NIL
      s_nStandarnaStopaMarze := nSet
      set_metric( "standarna_stopa_marze", NIL, nSet )
   ENDIF

   RETURN s_nStandarnaStopaMarze


FUNCTION korekcija_nabavne_cijene_sa_zadnjom_ulaznom( nKolicina, nZadnjiUlazKol, nZadnjaUlaznaNC, nSrednjaNabavnaCijena, lSilent )

   LOCAL nOdst
   LOCAL cDN
   LOCAL nX
   LOCAL GetList := {}

   hb_default( @lSilent, .F. )
   IF Round( nSrednjaNabavnaCijena, 4 ) == 0 .AND. Round( nZadnjaUlaznaNC, 4 ) > 0
      nSrednjaNabavnaCijena := nZadnjaUlaznaNC
      RETURN nSrednjaNabavnaCijena
   ENDIF

   IF prag_odstupanja_nc_sumnjiv() == 0 .OR. Round( nZadnjaUlaznaNC, 4 ) <= 0
      RETURN nSrednjaNabavnaCijena
   ENDIF

   nOdst := ( Round( nSrednjaNabavnaCijena, 4 ) - Round( nZadnjaUlaznaNC, 4 ) ) / ;
      Min( Abs( Round( nZadnjaUlaznaNC, 4 ) ), Abs( Round( nSrednjaNabavnaCijena, 4 ) )  ) * 100

   IF Abs( nOdst ) > prag_odstupanja_nc_sumnjiv()

      IF ( nKolicina <= 0 ) .OR. ( nSrednjaNabavnaCijena < 0 )
         cDN := "D" // kartica je u minusu - najbolje razduzi prema posljednjem ulazu
      ELSE
         cDN := "N" // metodom srednje nabavne cijene razduzi
      ENDIF
      IF !lSilent
         CLEAR TYPEAHEAD
         nX := 2
         Box( "#" + "== Odstupanje NC " + AllTrim( _mkonto ) + "/" + AllTrim( _idroba ) + " ===", 12, 70, .T. )

         @ box_x_koord() + nX, box_y_koord() + 2   SAY     "Artikal: " + AllTrim( _idroba ) + "-" + PadR( roba->naz, 20 )
         nX += 2
         @ box_x_koord() + nX++, box_y_koord() + 2 SAY8 "  količina na stanju: " + AllTrim( say_kolicina( nKolicina ) )
         @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "            Srednja NC: " + AllTrim( say_cijena( nSrednjaNabavnaCijena ) ) + " <"
         nX  += 2
         @ box_x_koord() + nX++, box_y_koord() + 2 SAY8 "količina zadnji ulaz: " + AllTrim( say_kolicina( nZadnjiUlazKol ) )
         @ box_x_koord() + nX++, box_y_koord() + 2 SAY8 "      NC Zadnji ulaz: " + AllTrim( say_cijena( nZadnjaUlaznaNC ) ) + " <"
         nX += 2
         @ box_x_koord() + nX, box_y_koord() + 2 SAY8 " Korigovati NC na zadnju ulaznu: D/N ?"  GET cDn VALID cDn $ "DN" PICT "@!"

         READ
         BoxC()
      ENDIF
      IF cDN == "D"
         nSrednjaNabavnaCijena := nZadnjaUlaznaNC
      ENDIF

   ENDIF

   RETURN nSrednjaNabavnaCijena


/*
       ako je nabavna cijena 0, ponuditi cijenu koja je roba.vpc / ( 1 + standardna_stopa_marze )
       npr. vpc=1, standarna_stopa_marze = 20%, nc=0.8
*/

FUNCTION korekcija_nabavna_cijena_0( nSrednjaNabavnaCijena )

   IF Abs( Round( nSrednjaNabavnaCijena, 4 ) ) <= 0 .AND. roba->vpc != 0
      nSrednjaNabavnaCijena := Round( roba->vpc / ( 1 + standardna_stopa_marze() / 100 ), 4 )
   ENDIF

   RETURN nSrednjaNabavnaCijena


FUNCTION kalk_valid_marza_veleprodaja_10( cIdVd, lNaprijed )

   LOCAL nStvarnaKolicina := 0
   LOCAL nKalkMarzaVP

   IF ( Round( _nc, 7 ) == 0 )
      _nc := 9999
   ENDIF

   nStvarnaKolicina := _Kolicina
   IF _Marza == 0 .OR. _VPC <> 0 .AND. !lNaprijed

      nKalkMarzaVP := _VPC - _NC // unazad formiraj marzu
      IF _TMarza == "%"
         _Marza := 100 * ( _VPC / _NC - 1 )
      ELSEIF _TMarza == "A"
         _Marza := nKalkMarzaVP
      ELSEIF _TMarza == "U"
         _Marza := nKalkMarzaVP * nStvarnaKolicina
      ENDIF

   ELSEIF Round( _VPC, 4 ) == 0  .OR. lNaprijed // formiraj marzu "unaprijed" od nc do vpc
      IF _TMarza == "%"
         nKalkMarzaVP := _Marza / 100 * _NC
      ELSEIF _TMarza == "A"
         nKalkMarzaVP := _Marza
      ELSEIF _TMarza == "U"
         nKalkMarzaVP := _Marza / nStvarnaKolicina
      ENDIF
      _VPC := Round( ( nKalkMarzaVP + _NC ), 2 )

   ELSE
      IF cIdvd == "14"
         nKalkMarzaVP := _VPC * ( 1 - _Rabatv / 100 ) - _NC
      ELSE
         nKalkMarzaVP := _VPC - _NC
      ENDIF
   ENDIF
   AEval( GetList, {| o | o:display() } )

   RETURN .T.


FUNCTION kalk_10_pr_rn_valid_vpc_set_marza_polje_nakon_iznosa( cProracunMarzeUnaprijed )

   LOCAL nStvarnaKolicina := 0, nKalkMarzaVP

   IF cProracunMarzeUnaprijed == NIL
      cProracunMarzeUnaprijed := " "
   ENDIF

   IF ( Round( _nc, 7 ) == 0 )
      _NC := 9999
   ENDIF

   nStvarnaKolicina := _Kolicina

   IF !Empty( cProracunMarzeUnaprijed ) // proračun unaprijed od nc -> vpc
      IF _TMarza == "%"
         nKalkMarzaVP := _Marza / 100 * _NC
      ELSEIF _TMarza == "A"
         nKalkMarzaVP := _Marza
      ELSEIF _TMarza == "U"
         nKalkMarzaVP := _Marza / nStvarnaKolicina
      ENDIF
      _VPC := Round( nKalkMarzaVP + _NC, 2 )

   ELSE // proračun unazad
      IF _Marza == 0 .OR. _VPC <> 0

         nKalkMarzaVP := _VPC - _NC
         IF _TMarza == "%"
            _Marza := 100 * ( _VPC / _NC - 1 )
         ELSEIF _TMarza == "A"
            _Marza := nKalkMarzaVP
         ELSEIF _TMarza == "U"
            _Marza := nKalkMarzaVP * nStvarnaKolicina
         ENDIF
      ELSE
         IF _idvd $ "14#94"
            nKalkMarzaVP := _VPC * ( 1 - _Rabatv / 100 ) - _NC
         ELSE
            nKalkMarzaVP := _VPC - _NC
         ENDIF
      ENDIF

   ENDIF

   cProracunMarzeUnaprijed := " "
   AEval( GetList, {| o | o:display() } )

   IF Round( _VPC, 5 ) == 0
      error_bar( "kalk_unos", "VPC=0" )
   ENDIF

   IF Round( _NC, 9 ) == 0
      error_bar( "kalk", "NC=0" )
   ENDIF

   IF ( nKalkMarzaVP / _NC ) > 100000
      error_bar( "kalk", "ERROR Marza > 100 000 x veća od NC: " + AllTrim( Str( nKalkMarzaVP, 14, 2 ) ) )
   ENDIF

   RETURN .T.


FUNCTION kalk_vpc_po_kartici( nVPC, cIdFirma, cMKonto, cIdRoba, dDatum )

   IF koncij->naz == "V2" .AND. roba->( FieldPos( "vpc2" ) ) <> 0
      nVPC := roba->vpc2
   ELSE
      nVPC := roba->vpc
   ENDIF

   PushWA()
   find_kalk_by_mkonto_idroba( cIdFirma, cMKonto, cIdRoba )
   DO WHILE !Bof() .AND. kalk->idfirma + kalk->mkonto + kalk->idroba == cIdFirma + cMKonto + cIdRoba

      IF dDatum <> NIL .AND. dDatum < kalk->datdok
         SKIP -1
         LOOP
      ENDIF

      IF kalk->idvd $ "RN#10#16#12#13"
         IF koncij->naz <> "P2"
            nVPC := kalk->vpc
         ENDIF
         EXIT
      ELSEIF kalk->idvd == "18"
         nVPC := kalk->mpcsapp + kalk->vpc
         EXIT
      ENDIF
      SKIP -1
   ENDDO
   PopWa()

   RETURN .T.


/*
   koristi se u kalk PR, RN, 81
*/

FUNCTION kalk_when_valid_nc_ulaz()

   LOCAL nStvarnaKolicina
   LOCAL nKolicinaNaStanju := 0
   LOCAL nKolZN := 0
   LOCAL nNabCjZadnjaNabavka
   LOCAL nNabCj2 := 0

   nStvarnaKolicina := _Kolicina

   IF _TPrevoz == "%"
      nKalkPrevoz := _Prevoz / 100 * _FCj2
   ELSEIF _TPrevoz == "A"
      nKalkPrevoz := _Prevoz
   ELSEIF _TPrevoz == "U"
      nKalkPrevoz := _Prevoz / nStvarnaKolicina
   ELSEIF _TPrevoz == "R"
      nKalkPrevoz := 0
   ELSE
      nKalkPrevoz := 0
   ENDIF
   IF _TCarDaz == "%"
      nKalkCarDaz := _CarDaz / 100 * _FCj2
   ELSEIF _TCarDaZ == "A"
      nKalkCarDaz := _CarDaz
   ELSEIF _TCArDaz == "U"
      nKalkCarDaz := _CarDaz / nStvarnaKolicina
   ELSEIF _TCArDaz == "R"
      nKalkCarDaz := 0
   ELSE
      nKalkCarDaz := 0
   ENDIF
   IF _TZavTr == "%"
      nKalkZavTr := _ZavTr / 100 * _FCj2
   ELSEIF _TZavTr == "A"
      nKalkZavTr := _ZavTr
   ELSEIF _TZavTr == "U"
      nKalkZavTr := _ZavTr / nStvarnaKolicina
   ELSEIF _TZavTr == "R"
      nKalkZavTr := 0
   ELSE
      nKalkZavTr := 0
   ENDIF
   IF _TBankTr == "%"
      nKalkBankTr := _BankTr / 100 * _FCj2
   ELSEIF _TBankTr == "A"
      nKalkBankTr := _BankTr
   ELSEIF _TBankTr == "U"
      nKalkBankTr := _BankTr / nStvarnaKolicina
   ELSE
      nKalkBankTr := 0
   ENDIF
   IF _TSpedTr == "%"
      nKalkSpedTr := _SpedTr / 100 * _FCj2
   ELSEIF _TSpedTr == "A"
      nKalkSpedTr := _SpedTr
   ELSEIF _TSpedTr == "U"
      nKalkSpedTr := _SpedTr / nStvarnaKolicina
   ELSE
      nKalkSpedTr := 0
   ENDIF

   _NC := _FCj2 + nKalkPrevoz + nKalkCarDaz + nKalkBankTr + nKalkSpedTr + nKalkZavTr
   IF koncij->naz == "N1" // sirovine
      _VPC := _NC
   ENDIF

   nNabCjZadnjaNabavka := _nc // proslijediti nabavnu cijenu
   // proracun nabavne cijene radi utvrdjivanja odstupanja ove nabavne cijene od posljednje
   kalk_get_nabavna_mag( _datdok, _idfirma, _idroba, _mkonto, @nKolicinaNaStanju, @nKolZN, nNabCjZadnjaNabavka, @nNabCj2 )

   RETURN .T.


/* kalk_set_vpc_sifarnik(nNovaVrijednost,fUvijek)
 *   param: fUvijek -.f. samo ako je vrijednost u sifrarniku 0, .t. uvijek setuj
 *     Utvrdi varijablu VPC. U sifrarnik staviti novu vrijednost
 */

FUNCTION kalk_set_vpc_sifarnik( nNovaVrijednost, lUvijek )

   LOCAL nVal
   LOCAL hVars

   IF lUvijek == nil
      lUvijek := .F.
   ENDIF

   PRIVATE cFieldName := "VPC"

   IF koncij->naz == "N1"  // magacin se vodi po nabavnim cijenama
      RETURN .T.
   ENDIF

   IF koncij->naz == "P2"
      cFieldName := "plc"
      nVal := roba->plc
   ELSEIF koncij->naz == "V2"
      cFieldName := "vpc2"
      nVal := roba->VPC2
   ELSE
      cFieldName := "vpc"
      nVal := roba->VPC
   ENDIF

   IF nVal == 0  .OR. Abs( Round( nVal - nNovaVrijednost, 2 ) ) > 0 .OR. lUvijek

      IF gAutoCjen == "D" .AND. Pitanje( , "Staviti cijenu (" + cFieldName + ")" + " u šifarnik ?", "D" ) == "D"
         SELECT roba
         hVars := dbf_get_rec()
         hVars[ cFieldName ] := nNovaVrijednost
         update_rec_server_and_dbf( "roba", hVars, 1, "FULL" )
         SELECT kalk_pripr
      ENDIF
   ENDIF

   RETURN .T.


FUNCTION kalk_vpc_za_koncij()

   IF koncij->naz == "V2"
      RETURN roba->VPC2
   ELSEIF koncij->naz == "V3"
      RETURN roba->VPC3
   ENDIF

   RETURN roba->VPC


FUNCTION kalk_marza_veleprodaja()

   LOCAL nStvarnaKolicina, nKalkMarzaVP

   nStvarnaKolicina := field->Kolicina
   IF field->TMarza == "%" .OR. Empty( field->tmarza )
      nKalkMarzaVP := nStvarnaKolicina * field->Marza / 100 * field->NC
   ELSEIF field->TMarza == "A"
      nKalkMarzaVP := field->Marza * nStvarnaKolicina
   ELSEIF field->TMarza == "U"
      nKalkMarzaVP := field->Marza
   ENDIF

   RETURN nKalkMarzaVP



FUNCTION kalk_valid_kolicina_mag( nKolicinaNaStanju )

   IF roba->tip $ "UT"
      RETURN .T.
   ENDIF

   IF Empty( kalk_metoda_nc() ) .OR. _TBankTr == "X" // parametri postavljeni - bez obračuna cijene
      RETURN .T.
   ENDIF

   IF ( ( _nc <= 0 ) .AND. !( _idvd $ "11#12#13#21#22" ) ) .OR. ( _fcj <= 0 .AND. _idvd $ "11#12#13#21#22" )
      // kod 11-ke se unosi fcj
      Msg( _idroba + " Nabavna cijena <= 0 ! STOP!" )
      error_bar( "kalk_mag", _mkonto + "/" + _idroba + " Nabavna cijena <= 0 !" )
      _ERROR := "1"
      automatska_obrada_error( .T. )
      RETURN .F.
   ENDIF

   IF nKolicinaNaStanju < _Kolicina
      sumnjive_stavke_error()
      error_bar( "KA_" + _mkonto + "/" + _idroba, ;
         _mkonto + " / " + _idroba + "na stanju: " + AllTrim( Str( nKolicinaNaStanju, 10, 4 ) ) + " treba " +  AllTrim( Str( _kolicina, 10, 4 ) ) )
   ENDIF

   RETURN .T.
