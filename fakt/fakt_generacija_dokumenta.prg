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


STATIC __generisati := .F.




FUNCTION fakt_mnu_generacija_dokumenta()

   LOCAL _opc := {}
   LOCAL _opcexe := {}
   LOCAL _izbor := 1

   AAdd( _opc, "1. početno stanje                    " )
   AAdd( _opcexe, {|| fakt_pocetno_stanje() } )
   //AAdd( _opc, "2. dokument inventure     " )
   //AAdd( _opcexe, {|| fakt_unos_inventure() } )

   f18_menu( "mgdok", .F., _izbor, _opc, _opcexe )

   //my_close_all_dbf()

   RETURN .T.


/*
FUNCTION fakt_generisi_inventuru( cIdRj )

   LOCAL cIdRoba
   LOCAL cBrDok
   LOCAL nUl
   LOCAL nIzl
   LOCAL nRezerv
   LOCAL nRevers
   LOCAL nRbr
   LOCAL lFoundUPripremi

   //o_fakt_doks_dbf()
   //o_roba()
   //o_tarifa()

   o_fakt_pripr()
   SET ORDER TO TAG "3"

  -- o_fakt_dbf()

   MsgO( "scaniram tabelu fakt" )
   nRbr := 0

   GO TOP
   cBrDok := PadR( Replicate( "0", gNumDio ), 8 )

   DO WHILE !Eof()
      IF ( field->idFirma <> cIdRj )
         SKIP
         LOOP
      ENDIF

      SELECT fakt_pripr
      cIdRoba := fakt->idRoba
      SEEK cIdRj + cIdRoba // vidi imali ovo u pripremi; ako ima stavka je obradjena
      lFoundUPripremi := Found()

      PushWA()
      IF !( lFoundUPripremi )
         fakt_stanje_artikla( cIdRj, cIdroba, @nUl, @nIzl, @nRezerv, @nRevers, .T. )
         IF ( nUl - nIzl - nRevers ) <> 0
            SELECT fakt_pripr
            nRbr++
            ShowKorner( nRbr, 10 )
            cRbr := rbr_u_char( nRbr )
            fakt_dodaj_stavku_inventura( cIdRj, cIdRoba, cBrDok, nUl - nIzl - nRevers, cRbr )
         ENDIF
      ENDIF
      PopWa()

      SKIP
   ENDDO
   MsgC()

   my_close_all_dbf()

   RETURN .T.




STATIC FUNCTION fakt_dodaj_stavku_inventura( cIdRj, cIdRoba, cBrDok, nKolicina, cRbr )

   APPEND BLANK
   REPLACE idFirma WITH cIdRj
   REPLACE idRoba  WITH cIdRoba
   REPLACE datDok  WITH Date()
   REPLACE idTipDok WITH "IM"
   REPLACE serBr   WITH Str( nKolicina, 15, 4 )
   REPLACE kolicina WITH nKolicina
   REPLACE rBr WITH cRbr

   IF Val( cRbr ) == 1
      cTxt := ""
      AddTxt( @cTxt, "" )
      AddTxt( @cTxt, "" )
      AddTxt( @cTxt, self_organizacija_naziv() )
      AddTxt( @cTxt, "RJ:" + cIdRj )
      AddTxt( @cTxt, gMjStr )
      REPLACE txt WITH cTxt
   ENDIF

   REPLACE brDok WITH cBrDok
   REPLACE dinDem WITH valuta_domaca_skraceni_naziv()

   select_o_roba( cIdRoba )

   SELECT fakt_pripr
   REPLACE cijena WITH roba->vpc

   RETURN .T.

*/

STATIC FUNCTION AddTxt( cTxt, cStr )

   cTxt := cTxt + Chr( 16 ) + cStr + Chr( 17 )

   RETURN NIL



FUNCTION fakt_inventura_manjak( cIdRj, cBrDok )

   LOCAL nRBr
   LOCAL nRazlikaKol
   LOCAL cRBr
   LOCAL cNoviBrDok

   nRBr := 0

   o_fakt_pripr()
   //o_roba()

   cNoviBrDok := PadR( Replicate( "0", gNumDio ), 8 )

   seek_fakt( cIdRj, "IM", cBrDok )
   DO WHILE ( !Eof() .AND. cIdRj + "IM" + cBrDok == fakt->( idFirma + idTipDok + brDok ) )
      nRazlikaKol := Val( fakt->serBr ) -fakt->kolicina
      IF ( Round( nRazlikaKol, 5 ) > 0 )
         select_o_roba( fakt->idRoba )
         SELECT fakt_pripr
         nRBr++
         cRBr := rbr_u_char( nRBr )
         dodaj_stavku_inventure_manjka( cIdRj, fakt->idRoba, cNoviBrDok, nRazlikaKol, cRBr )
      ENDIF
      SELECT fakt
      SKIP 1
   ENDDO

   IF ( nRBr > 0 )
      MsgBeep( "U pripremu je izgenerisan dokument otpreme manjka " + cIdRj + "-19-" + cNoviBrDok )
   ELSE
      MsgBeep( "Inventurom nije evidentiran manjak pa nije generisan nikakav dokument!" )
   ENDIF

   my_close_all_dbf()

   RETURN .T.



STATIC FUNCTION dodaj_stavku_inventure_manjka( cIdRj, cIdRoba, cBrDok, nKolicina, cRbr )

   APPEND BLANK
   REPLACE idFirma WITH cIdRj
   REPLACE idRoba  WITH cIdRoba
   REPLACE datDok  WITH Date()
   REPLACE idTipDok WITH "19"
   REPLACE serBr   WITH ""
   REPLACE kolicina WITH nKolicina
   REPLACE rBr WITH cRbr

   IF ( Val( cRbr ) == 1 )
      cTxt := ""
      AddTxt( @cTxt, "" )
      AddTxt( @cTxt, "" )
      AddTxt( @cTxt, self_organizacija_naziv() )
      AddTxt( @cTxt, "RJ:" + cIdRj )
      AddTxt( @cTxt, gMjStr )
      REPLACE txt WITH cTxt
   ENDIF

   REPLACE brDok WITH cBrDok
   REPLACE dinDem WITH valuta_domaca_skraceni_naziv()
   REPLACE cijena WITH roba->vpc

   RETURN .T.



FUNCTION fakt_inventura_visak( cIdRj, cBrDok )

   LOCAL nRBr
   LOCAL nRazlikaKol
   LOCAL cRBr
   LOCAL cNoviBrDok

   nRBr := 0

   o_fakt_pripr()
   //o_roba()

   cNoviBrDok := PadR( Replicate( "0", gNumDio ), 8 )

   seek_fakt( cIdRj, "IM", cBrDok )
   DO WHILE ( !Eof() .AND. cIdRj + "IM" + cBrDok == fakt->( idFirma + idTipDok + brDok ) )
      nRazlikaKol := Val( fakt->serBr ) -fakt->kolicina
      IF ( Round( nRazlikaKol, 5 ) < 0 )
         select_o_roba( fakt->idRoba )
         SELECT fakt_pripr
         nRBr++
         cRBr := rbr_u_char( nRBr )
         dodaj_stavku_inventure_viska( cIdRj, fakt->idRoba, cNoviBrDok, -nRazlikaKol, cRBr )
      ENDIF
      SELECT fakt
      SKIP 1
   ENDDO

   IF ( nRBr > 0 )
      MsgBeep( "U pripremu je izgenerisan dokument dopreme viska " + cIdRj + "-01-" + cNoviBrDok )
   ELSE
      MsgBeep( "Inventurom nije evidentiran visak pa nije generisan nikakav dokument!" )
   ENDIF

   my_close_all_dbf()

   RETURN .T.



STATIC FUNCTION dodaj_stavku_inventure_viska( cIdRj, cIdRoba, cBrDok, nKolicina, cRbr )

   APPEND BLANK
   REPLACE idFirma WITH cIdRj
   REPLACE idRoba  WITH cIdRoba
   REPLACE datDok  WITH Date()
   REPLACE idTipDok WITH "01"
   REPLACE serBr   WITH ""
   REPLACE kolicina WITH nKolicina
   REPLACE rBr WITH cRbr

   IF ( Val( cRbr ) == 1 )
      cTxt := ""
      AddTxt( @cTxt, "" )
      AddTxt( @cTxt, "" )
      AddTxt( @cTxt, self_organizacija_naziv() )
      AddTxt( @cTxt, "RJ:" + cIdRj )
      AddTxt( @cTxt, gMjStr )
      REPLACE txt WITH cTxt
   ENDIF

   REPLACE brDok WITH cBrDok
   REPLACE dinDem WITH valuta_domaca_skraceni_naziv()
   REPLACE cijena WITH roba->vpc

   RETURN .T.




FUNCTION fakt_generisi_racun_iz_pripreme()

   LOCAL _novi_tip, _tip_dok, _br_dok
   LOCAL nTekRec

   IF !( field->idtipdok $ "12#20#13#01#27" )
      Msg( "Ova opcija je za promjenu 20,12,13 -> 10 i 27 -> 11 " )
      RETURN .F.
   ENDIF

   IF field->idtipdok = "27"
      _novi_tip := "11"
   ELSEIF field->idtipdok = "01"
      _novi_tip := "19"
   ELSE
      _novi_tip := "10"
   ENDIF

   IF Pitanje(, "Želite li dokument pretvoriti u " + _novi_tip + " ? (D/N)", "D" ) == "N"
      RETURN .F.
   ENDIF

   Box(, 5, 60 )

   _tip_dok := field->idtipdok
   _br_dok := PadR( Replicate( "0", 5 ), 8 )

   SELECT fakt_pripr
   PushWA()

   GO TOP
   nTekRec := 0

   my_flock()

   DO WHILE !Eof()

      SKIP
      nTekRec := RecNo()
      SKIP -1

      REPLACE field->brdok WITH _br_dok
      REPLACE field->idtipdok WITH _novi_tip
      REPLACE field->datdok WITH Date()

      IF _tip_dok == "12"
         // otpremnica u racun ???
         REPLACE serbr WITH "*"
      ENDIF

      IF _tip_dok == "13"
         REPLACE kolicina WITH -kolicina
      ENDIF

      GO ( nTekRec )

   ENDDO

   my_unlock()

   PopWa()

   BoxC()

   fakt_ispravka_ftxt()

   RETURN .T.
