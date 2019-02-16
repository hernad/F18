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


STATIC slChanged := .F.


MEMVAR _datdok, _idfirma, _idtipdok, _brdok, _podbr, _tip_rabat, _idpartner
MEMVAR _cijena, _idroba, _kolicina, _rbr, _rabat, _serbr, _porez, _zaokr, _idrelac, _k1, _k2, _m1, _dindem, _idvrstep, _txt



/*
FUNCTION IzSifre( lSilent )

   LOCAL _pos
   LOCAL _sif := _idpartner
   LOCAL _tmp

   IF lSilent == NIL
      lSilent := .F.
   ENDIF

   IF Right( _sif, 1 ) = "." .AND. Len( _sif ) <= 7

      _pos := RAt( ".", _sif )
      _sif := Left( _sif, _pos - 1 )

      IF !lSilent
         p_partner( PadR( _sif, 6 ) )
      ENDIF

      _idpartner := partn->id

   ENDIF

   IF gFaktPrikazFinSaldaKupacDobavljac == "D"
      fin_partner_prikaz_stanja_ekran( PadR( _idpartner, 6 ), gFinKtoDug, gFinKtoPot )
   ENDIF

   RETURN  .T.

*/


FUNCTION V_Rj()

   IF gDetPromRj == "D" .AND. self_organizacija_id() <> _IdFirma
      Beep ( 3 )
      Msg ( "Mijenjate radnu jedinicu!#" )
   ENDIF

   RETURN .T.

/*
FUNCTION V_Podbr()

   LOCAL fRet := .F., nTRec, nPrec, nPkolicina := 1, nPRabat := 0

   PRIVATE GetList := {}

   IF ( Left( _podbr, 1 ) $ " .0123456789" ) .AND. ( Right( _podbr, 1 ) $ " .0123456789" )
      fRet := .T.
   ENDIF

   IF Val( _podbr ) > 0
      _podbr := Str( Val( _podbr ), 2, 0 )
   ENDIF


   IF AllTrim( _podbr ) == "."
      _podbr := " ."
      cPRoba := ""  // proizvod sifra
      nPKolicina := _kolicina
      _idroba := Space( Len( _idroba ) )
      Box(, 5, 50 )
      @ box_x_koord() + 1, box_y_koord() + 2 SAY "Proizvod:" GET _idroba VALID {|| Empty( _idroba ) .OR. P_roba( @_idroba ) } PICT "@!"
      READ
      IF !Empty( _idroba )
         @ box_x_koord() + 3, box_y_koord() + 2 SAY8 "količina        :" GET nPkolicina PICT fakt_pic_kolicina()
         @ box_x_koord() + 4, box_y_koord() + 2 SAY "rabat %         :" GET nPRabat    PICT "999.999"
         @ box_x_koord() + 5, box_y_koord() + 2 SAY "Varijanta cijene:" GET cTipVPC
         READ
      ENDIF
      BoxC()

      IF !Empty( _idroba )
         _txt1 := PadR( roba->naz, 40 )
         nTRec := RecNo()
         GO TOP
         nTRbr := nRbr
         DO WHILE !Eof()
            skip; nPRec := RecNo(); SKIP -1
            IF nTrbr == Val( rbr ) .AND. AllTrim( podbr ) <> "."
               // pobrisi stare zapise
               my_delete()
            ENDIF
            GO nPrec
         ENDDO

         cPRoba := _idroba
         cPtxt1 := _txt1
      --   select_o_sastavnice( cPRoba )
         nPbr := 0
         DO WHILE !Eof() .AND. cPRoba == id

            select_o_roba( sast->id2  ) // pozicioniraj se na materijal
            SELECT fakt_pripr
            APPEND ncnl
            my_flock()
            _rbr := Str( nTrbr, 3, 0 )
            _podbr := Str( ++nPbr, 2, 0 )
            _idroba := sast->id2
            _kolicina := sast->kolicina * npkolicina
            _rabat := nPRabat
            fakt_setuj_cijenu( cTipVPC )

            IF roba->tip == "U"
               _txt1 := Trim( Left( roba->naz, 40 ) )
            ELSE
               _txt1 := ""
            ENDIF
            IF _podbr == " ." .OR.  roba->tip = "U"
      --         _txt := Chr( 16 ) + Trim( _txt1 ) + Chr( 17 ) + Chr( 16 ) + _txt2 + Chr( 17 ) + ;
                  Chr( 16 ) + Trim( _txt3a ) + Chr( 17 ) + Chr( 16 ) + _txt3b + Chr( 17 ) + ;
                  Chr( 16 ) + Trim( _txt3c ) + Chr( 17 ) + ;
                  Chr( 16 ) + _BrOtp + Chr( 17 ) + ;
                  Chr( 16 ) + DToC( _DatOtp ) + Chr( 17 ) + ;
                  Chr( 16 ) + _BrNar + Chr( 17 ) + ;
                  Chr( 16 ) + DToC( _DatPl ) + Chr( 17 )
            ENDIF
            Gather()
            my_unlock()
            SELECT sast
            SKIP
         ENDDO
         SELECT fakt_pripr
         GO nTRec
         _podbr := " ."
         _cijena := 0
         _idroba := cPRoba
         _kolicina := npkolicina
         _txt1 := cptxt1
      ENDIF
      _txt1 := PadR( _txt1, 40 )
      _porez := _rabat := 0
      IF Empty( cPRoba )
         _idroba := ""
         _Cijena := 0
      ENDIF
      _SerBr := ""
   ENDIF

   RETURN fRet
*/


FUNCTION fakt_setuj_cijenu( cTipCijene )

   // LOCAL _rj := .F.
   LOCAL _tmp

   // SELECT ( F_RJ )
   // IF Used()
   // _rj := .T.
   select_o_rj( _idfirma )
   // ENDIF

   // -- SELECT roba

   IF _idtipdok == "13" .AND. ( gVar13 == "2" .OR. glCij13Mpc ) .OR. _idtipdok == "19"

      _tmp := "mpc"
      IF g13dcj <> "1"
         _tmp += g13dcij
      ENDIF
      _cijena := roba->&_tmp

   ELSEIF rj->tip = "M"

      _cijena := fakt_mpc_iz_sifrarnika()

   ELSEIF _idtipdok $ "11#15#27"

      IF gMP == "1"
         _cijena := roba->mpc
      ELSEIF gMP == "2"
         _cijena := Round( roba->vpc * ( 1 + tarifa->pdv / 100 ), 2 )
      ELSEIF gMP == "3"
         _cijena := roba->mpc2
      ELSEIF gMP == "4"
         _cijena := roba->mpc3
         // ELSEIF gMP == "5"
         // _cijena := roba->mpc4
         // ELSEIF gMP == "6"
         // _cijena := roba->mpc5
         // ELSEIF gMP == "7"
         // _cijena := roba->mpc6
      ENDIF

   ELSE

      IF cTipCijene == "1"
         _cijena := roba->vpc
      ELSEIF FieldPos( "vpc2" ) <> 0
         IF gVarC == "1"
            _cijena := roba->vpc2
         ELSEIF gVarc == "2"
            _cijena := roba->vpc
            IF _cijena <> 0
               _rabat := ( roba->vpc - roba->vpc2 ) / _cijena * 100
            ENDIF
         ELSEIF gVarc == "3"
            _cijena := roba->nc
         ENDIF
      ELSE
         _cijena := 0
      ENDIF
   ENDIF

   SELECT fakt_pripr

   RETURN .T.



FUNCTION fakt_v_kolicina( cTipVpc )

   LOCAL cRjTip
   LOCAL nUl := 0
   LOCAL nIzl := 0
   LOCAL nRezerv := 0
   LOCAL nRevers := 0
   LOCAL lRoba := .T.
   LOCAL lFaktIzlaz := .T.

   IF _kolicina == 0
      RETURN .F.
   ENDIF

   // IF JeStorno10()
   // _kolicina := - Abs( _kolicina )
   // ENDIF
   IF Year( _datdok ) < 2007 // podrska za podatke <= 2001
      RETURN .T.
   ENDIF

   // IF _podbr <> " ."

   select_o_rj( _idfirma )

   cRjTip := rj->tip

   fakt_set_pozicija_sif_roba( _IdRoba )
   lRoba := ( roba->tip != "U" )
   lFaktIzlaz := Left( _idtipdok, 1 ) $ "12"


   IF lRoba
      IF _idtipdok == "13" .AND. ( gVar13 == "2" .OR. glCij13Mpc ) .AND. gVarNum == "1"
         IF gVar13 == "2" .AND. _idtipdok == "13"
            _cijena := fakt_mpc_iz_sifrarnika()
         ELSE
            // IF g13dcij == "6"
            // _cijena := MPC6
            // ELSEIF g13dcij == "5"
            // _cijena := MPC5
            IF g13dcij == "4"
               _cijena := MPC4
            ELSEIF g13dcij == "3"
               _cijena := MPC3
            ELSEIF g13dcij == "2"
               _cijena := MPC2
            ELSE
               _cijena := MPC
            ENDIF
         ENDIF
      ELSEIF _idtipdok == "13" .AND. ( gVar13 == "2" .OR. glCij13Mpc ) .AND. gVarNum == "2"
         // IF g13dcij == "6"
         // _cijena := MPC6
         // ELSEIF g13dcij == "5"
         // _cijena := MPC5
         IF g13dcij == "4"
            _cijena := MPC4
         ELSEIF g13dcij == "3"
            _cijena := MPC3
         ELSEIF g13dcij == "2"
            _cijena := MPC2
         ELSE
            _cijena := MPC
         ENDIF
      ELSEIF cRjtip = "M"
         _cijena := fakt_mpc_iz_sifrarnika()

      ELSEIF _idtipdok $ "11#15#27"

         IF gMP == "1"
            _Cijena := MPC
         ELSEIF gMP == "2"
            _Cijena := Round( VPC * ( 1 + tarifa->pdv / 100 ), 2 )
         ELSEIF gMP == "3"
            _Cijena := MPC2
         ELSEIF gMP == "4"
            _Cijena := MPC3
         ELSEIF gMP == "5"
            _Cijena := MPC4
            // ELSEIF gMP == "6"
            // _Cijena := MPC5
            // ELSEIF gMP == "7"
            // _Cijena := MPC6
         ENDIF

      ELSEIF _idtipdok == "25" .AND. _cijena <> 0
      ELSEIF cRjTip = "V" .AND. _idTipDok $ "10#20"
         _cijena := fakt_vpc_iz_sifrarnika()

      ELSE
         IF cTipVpc == "1"
            _Cijena := vpc
         ELSEIF FieldPos( "vpc2" ) <> 0
            IF gVarC == "1"
               _Cijena := vpc2
            ELSEIF gVarc == "2"
               _Cijena := vpc
               IF vpc <> 0
                  _Rabat := ( vpc - vpc2 ) / vpc * 100
               ENDIF
            ELSEIF gVarc == "3"
               _Cijena := nc
            ENDIF
         ELSE
            _Cijena := 0
         ENDIF
      ENDIF
   ENDIF
   // ENDIF


   // lBezMinusa := .F.
   // select_o_roba( _IdRoba )

   IF lRoba .AND. lFaktIzlaz .AND. is_fakt_pratiti_kolicinu()   // .AND. !( Left( _idtipdok, 1 ) == "1" .AND. Left( _serbr, 1 ) == "*" )

      MsgO( "Izračunavam trenutno stanje FAKT ..." )

      seek_fakt_3( NIL, _idroba )

      nUl := 0
      nIzl := 0
      nRezerv := 0
      nRevers := 0

      DO WHILE !Eof() .AND. roba->id == IdRoba

         IF fakt->IdFirma <> _IdFirma
            SKIP
            LOOP
         ENDIF

         IF idtipdok = "0"
            nUl  += kolicina
         ELSEIF idtipdok = "1"
            IF !( Left( serbr, 1 ) == "*" .AND. idtipdok == "10" )
               nIzl += kolicina
            ENDIF
         ELSEIF idtipdok $ "20#27"
            IF serbr = "*"
               nRezerv += kolicina
            ENDIF
         ELSEIF idtipdok == "21"
            nRevers += kolicina
         ENDIF
         SKIP
      ENDDO

      MsgC()

      IF ( ( nUl - nIzl - nRevers - nRezerv - _kolicina ) < 0 )

         fakt_box_stanje( { { _IdFirma, nUl, nIzl, nRevers, nRezerv } }, _idroba )

         // IF LEFT( _idtipdok, 1 ) == "1"  //.AND. lBezMinusa = .T.
         // SELECT fakt_pripr
         // RETURN .F.
         // ENDIF

      ELSE
         info_bar( "fakt_stanje", "Artikal: " + _idRoba + " stanje: " + AllTrim( Str( nUl - nIzl - nRevers - nRezerv, 12, 3 ) ) )
      ENDIF
   ENDIF

   SELECT fakt_pripr

   // IF _idtipdok == "26" .AND. glDistrib .AND. !UGenNar()
   // RETURN .F.
   // ENDIF

   RETURN .T.



FUNCTION W_Roba()

   PRIVATE Getlist := {}

   IF _podbr == " ."
      @ box_x_koord() + 15, box_y_koord() + 2  SAY "Roba     " GET _txt1 PICT "@!"
      READ
      RETURN .F.
   ELSE
      RETURN .T.
   ENDIF

   RETURN .T.



FUNCTION fakt_valid_roba( cIdFirma, cIdTipDok, cIdRoba, cTxt1, cIdPartner, lFaktNoviRec, nX )

   LOCAL cPom
   LOCAL lPrikTar := .T.
   LOCAL nArr

   // PRIVATE cVarIDROBA

   // cVarIDROBA := "_IDROBA"

   // IF lPrikTar == nil
   // lPrikTar := .T.
   // ENDIF

   IF Len( Trim( cIdroba ) ) < Val( gDuzSifIni )
      cIdroba :=  Left( cIdroba, Val( gDuzSifIni ) )
   ENDIF

/*
   IF Right( Trim ( &cVarIdRoba ), 2 ) = "--"
      cPom := PadR( Left( &cVarIdRoba, Len( Trim( &cVarIdRoba ) ) - 2 ), Len( &cVarIdRoba ) )
      IF select_o_roba( cPom )
         fakt_stanje_roba( roba->id )    // prelistaj kalkulacije
         &cVarIdRoba := cPom
      ENDIF
   ENDIF
*/
   P_Roba( @cIdroba, NIL, NIL, roba_trazi_po_sifradob() )


   SELECT fakt_pripr

   IF Empty( cIdRoba )
      RETURN .F.
   ENDIF

   fakt_unos_stavka_usluga( lFaktNoviRec, @cTxt1, nX, 25  )
   fakt_unos_provjera_dupla_stavka( lFaktNoviRec )
   fakt_zadnji_izlazi_info( cIdPartner, cIdRoba, "F" )
   fakt_trenutno_na_stanju_kalk( cIdfirma, cIdtipdok,  cIdroba )

   IF lPrikTar
      select_o_tarifa( roba->idtarifa )
      @ box_x_koord() + 16, box_y_koord() + 28 SAY "TBr: "
      ?? roba->idtarifa, "PDV", Str( tarifa->pdv, 7, 2 ) + "%"
      IF _IdTipdok == "13"
         @ box_x_koord() + 18, box_y_koord() + 47 SAY "MPC.s.PDV sif:"
         ?? Str( roba->mpc, 8, 2 )
      ENDIF
   ENDIF

   IF gRabIzRobe == "D"
      _rabat := roba->n1
   ENDIF

   SELECT fakt_pripr

   RETURN .T.



STATIC FUNCTION fakt_trenutno_na_stanju_kalk( cIdRj, cIdTipDok, cIdRoba )

   LOCAL _stanje := NIL
   LOCAL cIdKonto := ""
   LOCAL nDbfArea := Select()
   LOCAL _color := "W/N+"

   select_o_rj( cIdRj )
   select_fakt_pripr()

   IF rj->( FieldPos( "konto" ) ) == 0 .OR. Empty( rj->konto )
      RETURN .T.
   ENDIF

   cIdKonto := rj->konto
   SELECT ( nDbfArea )

   IF cIdTipDok $ "10#12"
      _stanje := kalk_kol_stanje_artikla_magacin( cIdKonto, cIdRoba, Date() )
   ELSEIF cIdTipDok $ "11#13"
      _stanje := kalk_kol_stanje_artikla_prodavnica( cIdKonto, cIdRoba, Date() )
   ENDIF

   IF _stanje <> NIL

      IF _stanje <= 0
         _color := "W/R+"
      ENDIF

      @ box_x_koord() + 17, box_y_koord() + 28 SAY PadR( "", 60 )
      @ box_x_koord() + 17, box_y_koord() + 28 SAY "Na stanju konta " + ;
         AllTrim( cIdKonto ) + " : "
      @ box_x_koord() + 17, Col() + 1 SAY AllTrim( Str( _stanje, 12, 3 ) ) + " " + PadR( roba->jmj, 3 ) COLOR _color
   ENDIF

   RETURN .T.


FUNCTION fakt_stanje_roba( cIdRoba )

   LOCAL nPos, nUl, nIzl, nRezerv, nRevers, fOtv := .F., nIOrd, nFRec, aStanje

   PushWa()
   seek_fakt_3( NIL, cIdRoba )

   aStanje := {}  // {idfirma, nUl,nIzl,nRevers,nRezerv }

   nUl := nIzl := nRezerv := nRevers := 0
   DO WHILE !Eof() .AND. cIdRoba == IdRoba
      nPos := AScan ( aStanje, {| x | x[ 1 ] == field->IdFirma } )
      IF nPos == 0
         AAdd ( aStanje, { field->IdFirma, 0, 0, 0, 0 } )
         nPos := Len ( aStanje )
      ENDIF
      IF Left( field->idtipdok, 1 ) == "0"  // ulaz
         aStanje[ nPos ][ 2 ] += kolicina
      ELSEIF Left( field->idtipdok, 1 ) == "1"   // izlazni dokument
         IF !( Left( serbr, 1 ) == "*" .AND. idtipdok == "10" )  // za fakture na osnovu optpremince ne ra~unaj izlaz
            aStanje[ nPos ][ 3 ] += kolicina
         ENDIF
      ELSEIF field->idtipdok $ "20#27"
         IF serbr = "*"
            aStanje[ nPos ][ 5 ] += kolicina
         ENDIF
      ELSEIF field->idtipdok == "21"
         aStanje[ nPos ][ 4 ] += kolicina
      ENDIF
      SKIP
   ENDDO


   fakt_box_stanje( aStanje, cIdRoba )      // nUl,nIzl,nRevers,nRezerv)

   PopWa()

   RETURN .T.



FUNCTION fakt_roba_key_handler( Ch )

   IF Upper( Chr( Ch ) ) == "S"
      fakt_stanje_roba( roba->id )
      RETURN DE_CONT
   ENDIF

   RETURN DE_CONT



FUNCTION fakt_box_stanje( aStanje, cIdroba )

   LOCAL i, nR, nC, nTSta := 0, nTRev := 0, nTRez := 0, ;
      nTOst := 0, npd, cDiv := " | ", nLen

   nPd := Len ( fakt_pic_iznos() )
   nLen := Len ( aStanje )

   // ucitajmo dodatne parametre stanja iz FMK.INI u aDodPar

   // aDodPar := {}
   // FOR i := 1 TO 6
   // cI := AllTrim( Str( i ) )
   // cPomZ := my_get_from_ini( "roba_box_stanje", "ZaglavljeStanje" + cI, "", KUMPATH )
   // cPomF := my_get_from_ini( "roba_box_stanje", "FormulaStanje" + cI, "", KUMPATH )
   // IF !Empty( cPomF )
   // AAdd( aDodPar, { cPomZ, cPomF } )
   // ENDIF
   // NEXT
   // nLenDP := IIF( Len( aDodPar ) > 0, Len( aDodPar ) + 1, 0 )


   select_o_roba( cIdRoba )


   Box(, 6 + nLen / 2, 75 )
   Beep( 1 )
   @ box_x_koord() + 1, box_y_koord() + 2 SAY "ARTIKAL: "
   @ box_x_koord() + 1, Col() SAY PadR( AllTrim( cIdRoba ) + " - " + Left( roba->naz, 40 ), 51 ) COLOR "GR+/B"
   @ box_x_koord() + 3, box_y_koord() + 2 SAY cDiv + "RJ" + cDiv + PadC ( "Stanje", npd ) + cDiv + ;
      PadC ( "Na reversu", npd ) + cDiv + PadC ( "Rezervisano", npd ) + cDiv + PadC ( "Ostalo", nPd ) + cDiv
   nR := box_x_koord() + 4
   FOR nC := 1 TO nLen
      // {idfirma, nUl,nIzl,nRevers,nRezerv }
      @ nR, box_y_koord() + 2 SAY cDiv
      @ nR, Col() SAY aStanje[ nC ][ 1 ]
      @ nR, Col() SAY cDiv
      nPom := aStanje[ nC ][ 2 ] - aStanje[ nC ][ 3 ]
      @ nR, Col() SAY nPom PICT fakt_pic_iznos()
      @ nR, Col() SAY cDiv
      nTSta += nPom
      @ nR, Col() SAY aStanje[ nC ][ 4 ] PICT fakt_pic_iznos()
      @ nR, Col() SAY cDiv
      nTRev += aStanje[ nC ][ 4 ]
      nPom -= aStanje[ nC ][ 4 ]
      @ nR, Col() SAY aStanje[ nC ][ 5 ] PICT fakt_pic_iznos()
      @ nR, Col() SAY cDiv
      nTRez += aStanje[ nC ][ 5 ]
      nPom -= aStanje[ nC ][ 5 ]
      @ nR, Col() SAY nPom PICT fakt_pic_iznos()
      @ nR, Col() SAY cDiv
      nTOst += nPom
      nR++
   NEXT
   @ nR, box_y_koord() + 2 SAY cDiv + "--" + cDiv + REPL ( "-", npd ) + cDiv + ;
      REPL ( "-", npd ) + cDiv + ;
      REPL ( "-", npd ) + cDiv + REPL ( "-", npd ) + cDiv
   nR++
   @ nR, box_y_koord() + 2 SAY " | UK.| "
   @ nR, Col() SAY nTSta PICT fakt_pic_iznos()
   @ nR, Col() SAY cDiv
   @ nR, Col() SAY nTRev PICT fakt_pic_iznos()
   @ nR, Col() SAY cDiv
   @ nR, Col() SAY nTRez PICT fakt_pic_iznos()
   @ nR, Col() SAY cDiv
   @ nR, Col() SAY nTOst PICT fakt_pic_iznos()
   @ nR, Col() SAY cDiv

/*
   // ispis dodatnih parametara stanja

   IF nLenDP > 0
      ++nR
      @ nR, box_y_koord() + 2 SAY REPL( "-", 74 )
      FOR i := 1 TO nLenDP - 1

         cPom777 := aDodPar[ i, 2 ]

         IF "TARIFA->" $ Upper( cPom777 )
            select_o_tarifa( ROBA->idtarifa )
         ENDIF

         IF i % 2 != 0
            ++nR
            @ nR, box_y_koord() + 2 SAY PadL( aDodPar[ i, 1 ], 15 ) COLOR "W+/B"
            @ nR, Col() + 2 SAY &cPom777 COLOR "R/W"
         ELSE
            @ nR, box_y_koord() + 37 SAY PadL( aDodPar[ i, 1 ], 15 ) COLOR "W+/B"
            @ nR, Col() + 2 SAY &cPom777 COLOR "R/W"
         ENDIF

      NEXT
   ENDIF
*/

   Inkey( 0 )
   BoxC()

   RETURN .T.



FUNCTION fakt_unos_w_brotp( lNovi )

   IF lNovi
      _datotp := _datdok
      _datpl := _datdok
   ENDIF

   RETURN .T.



FUNCTION fakt_unos_v_rabat( tip_rabata )

   IF tip_rabata $ " U"

      IF _cijena * _kolicina <> 0
         _rabat := _rabat * 100 / ( _cijena * _kolicina )
      ELSE
         _rabat := 0
      ENDIF

   ELSEIF tip_rabata = "A"

      IF _cijena <> 0
         _rabat := _rabat * 100 / _cijena
      ELSE
         _rabat := 0
      ENDIF

   ELSEIF tip_rabata == "C"

      IF _cijena <> 0
         _rabat := ( _cijena - _rabat ) / _cijena * 100
      ELSE
         _rabat := 0
      ENDIF

   ELSEIF tip_rabata == "I"

      IF _kolicina * _cijena <> 0
         _rabat := ( _kolicina * _cijena - _rabat ) / ( _kolicina * _cijena ) * 100
      ELSE
         _rabat := 0
      ENDIF

   ENDIF

   IF ( _rabat > 99 .OR. _rabat < 0 )
      Beep( 2 )
      Msg( "Rabat ne može biti > 99% ili < 0%", 6 )
      _rabat := 0
   ENDIF

   IF _idtipdok $ "11#15#27"
      _porez := 0  // fakt->porez
   ELSE
      IF roba->tip == "V"
         _porez := 0
      ENDIF
   ENDIF

   fakt_set_cijena_sif_roba( _idtipdok, _idroba, _cijena, _rabat )

   ShowGets()

   RETURN .T.



STATIC FUNCTION fakt_unos_stavka_usluga( lFaktNovaStavka, cTxt1, nX, nY )

   LOCAL GetList := {}

   IF !( roba->tip = "U" )
      DevPos( box_x_koord() + 15, box_y_koord() + 25 )
      ?? Space( 40 )
      DevPos( box_x_koord() + 15, box_y_koord() + 25 )

      ?? Trim( Left( roba->naz, 40 ) ), "(" + roba->jmj + ")"
   ENDIF

   IF roba->tip $ "UT" .AND. lFaktNovaStavka
      _kolicina := 1
   ENDIF

   IF roba->tip == "U"
      cTxt1 := PadR( iif( lFaktNovaStavka, roba->naz, cTxt1 ), 320 )
      IF lFaktNovaStavka
         _cijena := roba->vpc
      ENDIF

      _porez := 0
      @ box_x_koord() + nX, box_y_koord() + nY SAY Space( 70 )
      @ box_x_koord() + nX, box_y_koord() + nY SAY "opis usluge:" GET cTxt1 PICT "@S50"

      READ
      cTxt1 := Trim( cTxt1 )

   ELSE
      cTxt1 := ""

   ENDIF

   RETURN .T.


FUNCTION fakt_unos_provjera_dupla_stavka( lFaktNovaStavka )

   LOCAL nEntBK, ibk, uEntBK
   LOCAL nPrevRec

   // ako se radi o stornu fakture -> preuzimamo rabat i porez iz fakture
   // IF JeStorno10()
   // RabPor10()
   // ENDIF

   SELECT fakt_pripr

   nPrevRec := RecNo()
   LOCATE FOR idfirma + idtipdok + brdok + idroba == _idfirma + _idtipdok + _brdok + _idroba .AND. ( RecNo() <> nPrevrec .OR. lFaktNovaStavka )

   IF Found ()
      IF !( roba->tip $ "UT" )
         Beep ( 2 )
         Msg ( "Roba se već nalazi na dokumentu, stavka " + AllTrim ( fakt_pripr->rbr ), 30 )
      ENDIF
   ENDIF

   GO nPrevRec

   RETURN ( .T. )


FUNCTION fakt_zadnji_izlazi_info( cIdPartner, cIdRoba )

   LOCAL _data := {}
   LOCAL _count := 3

   IF fetch_metric( "pregled_rabata_kod_izlaza", my_user(), "N" ) == "N"
      RETURN .T.
   ENDIF

   _data := fakt_get_izlazi_10_11( cIdPartner, cIdRoba )
   IF Len( _data ) > 0
      kalk_podaci_o_rabatima( _data, "F", _count )
   ENDIF

   RETURN .T.


STATIC FUNCTION fakt_get_izlazi_10_11( cIdPartner, cIdRoba )

   LOCAL cQuery, _table
   LOCAL _data := {}
   LOCAL nI, oRow

   cQuery := "SELECT idfirma, idtipdok, brdok, datdok, cijena, rabat FROM " + F18_PSQL_SCHEMA_DOT + "fakt_fakt " + ;
      " WHERE idpartner = " + sql_quote( cIdPartner ) + ;
      " AND idroba = " + sql_quote( cIdRoba ) + ;
      " AND ( idtipdok = " + sql_quote( "10" ) + " OR idtipdok = " + sql_quote( "11" ) + " ) " + ;
      " ORDER BY datdok"

   _table := run_sql_query( cQuery )
   _table:GoTo( 1 )

   FOR nI := 1 TO _table:LastRec()

      oRow := _table:GetRow( nI )
      AAdd( _data, { oRow:FieldGet( oRow:FieldPos( "idfirma" ) ), ;
         oRow:FieldGet( oRow:FieldPos( "idtipdok" ) ) + "-" + AllTrim( oRow:FieldGet( oRow:FieldPos( "brdok" ) ) ), ;
         oRow:FieldGet( oRow:FieldPos( "datdok" ) ), ;
         oRow:FieldGet( oRow:FieldPos( "cijena" ) ), ;
         oRow:FieldGet( oRow:FieldPos( "rabat" ) ) } )

   NEXT

   RETURN _data


FUNCTION fakt_valid_preracun_cijene_u_valutu_dokumenta( cPretvori, cDinDem, dDatDok, nCijena )

   IF !( cPretvori $ "DN" )
      MsgBeep( "preračunati cijenu u valutu dokumenta " + cDinDem + " ##(D)a ili (N)e ?" )
      RETURN .F.
   ENDIF

   IF cPretvori == "D"
      nCijena := nCijena * OmjerVal( ValBazna(), cDinDem, dDatDok )
      cPretvori := "N"
   ENDIF

   ShowGets()

   RETURN .T.



FUNCTION fakt_set_cijena_sif_roba( cIdTipDok, cIdRoba, nCijena, nRabat )

   LOCAL nTArea := Select()
   LOCAL lFill := .F.
   LOCAL _vars

   IF select_o_roba( cIdRoba )

      // provjeri da li je cijena ista ?
      _vars := dbf_get_rec()

      IF cIdTipDok $ "#10#01#12#20#" .AND. nCijena <> 0
         IF field->vpc <> nCijena .AND. ;
               Pitanje(, "Postaviti novu VPC u šifarnik ?", "N" ) == "D"
            _vars[ "vpc" ] := nCijena
            lFill := .T.
         ENDIF

      ELSEIF cIdTipDok $ "11#13#" .AND. nCijena <> 0
         IF field->mpc <> nCijena .AND. ;
               Pitanje(, "Postaviti novu MPC u šifarnik ?", "N" ) == "D"
            _vars[ "mpc" ] := nCijena
            lFill := .T.
         ENDIF
      ENDIF

      IF gRabIzRobe == "D" .AND. lFill == .T. .AND. nRabat <> 0 .AND. ;
            nRabat <> field->n1
         _vars[ "n1" ] := nRabat
      ENDIF

      IF lFill == .T.
         update_rec_server_and_dbf( "roba", _vars, 1, "FULL" )
      ENDIF

   ENDIF

   SELECT ( nTArea )

   RETURN .T.



FUNCTION Tb_V_RBr()

   REPLACE Rbr WITH Str( nRbr, 3 )

   RETURN .T.



FUNCTION Tb_W_IdRoba()

   _idroba := PadR( _idroba, 15 )

   RETURN W_Roba()


FUNCTION TbRobaNaz()

   fakt_set_pozicija_sif_roba()

   RETURN Left( Roba->naz, 25 )



// ----------------------------------------
// Promjena cijene u sifrarniku
// ----------------------------------------

FUNCTION fakt_promjena_cijene_u_sif()

   fakt_set_pozicija_sif_roba()
   SELECT fakt_pripr

   RETURN .T.


FUNCTION fakt_set_pozicija_sif_roba( cIdRoba, lRobaIdSintetika )

   IF lRobaIdSintetika == NIL
      lRobaIdSintetika := .F.
   ENDIF

   IF cIdRoba == NIL
      cIdRoba := fakt_pripr->IdRoba
   ENDIF

   IF ( lRobaIdSintetika )
      find_roba_by_id_sintetika( cIdRoba )
      // IF !Found() .OR. ROBA->tip != "S"
      // HSEEK cIdRoba
      // ENDIF
   ELSE
      find_roba_by_id( cIdRoba )
      // HSEEK cIdRoba
   ENDIF

   IF cIdRoba == NIL
      SELECT fakt_pripr
   ENDIF

   RETURN .T.



FUNCTION get_serbr_opis()

   LOCAL _tmp := "Ser.broj"

   // ovo rudnik koristi za preracunavanje kj/kg
   // if _is_rudnik
   // _tmp := "  KJ/KG"
   // endif

   RETURN _tmp



FUNCTION Koef( cDindem )

   LOCAL nNaz, nRet, nArr, dDat

   IF cDinDem == Left( ValSekund(), 3 )
      RETURN 1 / UbaznuValutu( datdok )
   ENDIF

   RETURN 1


FUNCTION fakt_valid_cijena( nCijena, cTipDok, lNovidok )

   LOCAL lRet := .T.
   LOCAL nRCijena := nil

   IF !lNoviDok
      RETURN lRet
   ENDIF

   IF cTipDok $ "11#15#27"

      IF gMP == "1"
         nRCijena := roba->mpc
      ELSEIF gMP == "3"
         nRCijena := roba->mpc2
      ELSEIF gMP == "4"
         nRCijena := roba->mpc3
      ELSEIF gMP == "5"
         nRCijena := roba->mpc4

      ENDIF

   ELSEIF cTipDok $ "10#"
      nRCijena := roba->vpc
   ENDIF

   IF gPratiC == "D" .AND. nRCijena <> NIL .AND. nCijena <> nRCijena
      MsgBeep( "Unesena cijena različita od cijene u šifarniku !" + ;
         "#Trenutna: " + AllTrim( Str( nCijena, 12, 2 ) ) + ;
         ", šifarnik: " + AllTrim( Str( nRCijena, 12, 2 ) ) )
      IF Pitanje(, "Koristiti ipak ovu cijenu (D/N) ?", "D" ) == "N"
         lRet := .F.
      ENDIF
   ENDIF

   RETURN lRet


FUNCTION GetKarC3N2( mx )

   LOCAL nKor := 0
   LOCAL nDod := 0
   LOCAL x := 0
   LOCAL y := 0

   IF ( fakt_pripr->( FieldPos( "C1" ) ) <> 0 .AND. gKarC1 == "D" )
      @ mx + ( ++nKor ), box_y_koord() + 2 SAY "C1" GET _C1 PICT "@!"
      nDod++
   ENDIF

   IF ( fakt_pripr->( FieldPos( "C2" ) ) <> 0 .AND. gKarC2 == "D" )
      SljPozGet( @x, @y, @nKor, mx, nDod )
      @ x, y SAY "C2" GET _C2 PICT "@!"
      nDod++
   ENDIF

   IF ( fakt_pripr->( FieldPos( "C3" ) ) <> 0 .AND. gKarC3 == "D" )
      SljPozGet( @x, @y, @nKor, mx, nDod )
      @ x, y SAY "C3" GET _C3 PICT "@!"
      nDod++
   ENDIF

   IF ( fakt_pripr->( FieldPos( "N1" ) ) <> 0 .AND. gKarN1 == "D" )
      SljPozGet( @x, @y, @nKor, mx, nDod )
      @ x, y SAY "N1" GET _N1 PICT "999999.999"
      nDod++
   ENDIF

   IF ( fakt_pripr->( FieldPos( "N2" ) ) <> 0 .AND. gKarN2 == "D" )
      SljPozGet( @x, @y, @nKor, mx, nDod )
      @ x, y SAY "N2" GET _N2 PICT "999999.999"
      nDod++
   ENDIF

   IF ( fakt_pripr->( FieldPos( "opis" ) ) <> 0 )
      SljPozGet( @x, @y, @nKor, mx, nDod )
      @x, y SAY "Opis" GET _opis PICT "@S40"
      nDod++
   ENDIF

   IF nDod > 0
      ++nKor
   ENDIF

   RETURN nKor


FUNCTION SljPozGet( x, y, nKor, mx, nDod )

   IF nDod > 0
      IF nDod % 3 == 0
         x := mx + ( ++nKor )
         y := box_y_koord() + 2
      ELSE
         x := mx + nKor
         y := Col() + 2
      ENDIF
   ELSE
      x := mx + ( ++nKor )
      y := box_y_koord() + 2
   ENDIF

   RETURN .T.


FUNCTION fakt_rbr()

   LOCAL cRet

   IF Eof()
      cRet := ""
   ELSEIF Val( fakt_pripr->podbr ) == 0
      cRet := fakt_pripr->rbr + ")"
   ELSE
      cRet := fakt_pripr->rbr + "." + AllTrim( fakt_pripr->podbr )
   ENDIF

   RETURN PadR( cRet, 6 )


/* CijeneOK(cStr)
 *
 *   param: cStr
 */

FUNCTION CijeneOK( cStr )

   LOCAL fMyFlag := .F., lRetFlag := .T., nTekRec

   SELECT fakt_pripr
   nTekRec := RecNo ()
   IF fakt_pripr->IdTipDok $ "10#11#15#20#25#27"
      // PROVJERI IMA LI NEODREDJENIH CIJENA ako se radi o fakturi
      Scatter()
      SET ORDER TO TAG "1"
      Seek2 ( _IdFirma + _IdTipDok + _BrDok )
      DO WHILE ! Eof() .AND. IdFirma == _IdFirma .AND. ;
            IdTipDok == _IdTipDok .AND. BrDok == _BrDok
         IF Cijena == 0 .AND. Empty ( PodBr )
            Beep ( 3 )
            Msg ( "Utvrđena greška na stavci broj " + ;
               AllTrim ( rbr ) + "!#" + ;
               "CIJENA NIJE ODREĐENA!!!", 30 )
            fMyFlag := .T.
         ENDIF
         SKIP
      END
      IF fMyFlag
         Msg ( cStr + " nije dozvoljeno!#Vraćate se u pripremu!", 30 )
         lRetFlag := .F.
      ENDIF
   ENDIF
   GO nTekRec

   RETURN ( lRetFlag )



FUNCTION Part1Stavka()

   LOCAL cRet := ""

   IF AllTrim( fakt_pripr->rbr ) == "1"
      cRet += Trim( fakt_pripr->idpartner ) + ": "
   ENDIF

   RETURN cRet


FUNCTION fakt_prikazi_Roba()

   LOCAL cRet := ""

   cRet += Trim( field->idroba ) + " "
   DO CASE
   CASE Eof()
      cRet := ""
   CASE  AllTrim( podbr ) == "."
      aMemo := fakt_ftxt_decode( txt )
      cRet += aMemo[ 1 ]
   OTHERWISE

      select_o_roba( fakt_pripr->IdRoba )
      SELECT fakt_pripr
      cRet += Left( ROBA->naz, 40 )
   ENDCASE

   RETURN PadR( cRet, 30 )


FUNCTION fakt_brisi_stavku_pripreme()

   LOCAL _secur_code
   LOCAL _log_opis
   LOCAL _log_stavka
   LOCAL _log_artikal, _log_kolicina, _log_cijena
   LOCAL _log_datum
   LOCAL nDbfArea
   LOCAL _rec, nTrec
   LOCAL _tek, _prva
   LOCAL _id_tip_dok, _id_firma, _br_dok, _r_br
   LOCAL oAttr
   LOCAL _update_rbr

   IF Pitanje(, "Želite izbrisati ovu stavku ?", "D" ) == "N"
      RETURN 0
   ENDIF

   _id_firma := field->idfirma
   _id_tip_dok := field->idtipdok
   _br_dok := field->brdok
   _r_br := field->rbr

   log_write( "F18_DOK_OPER: fakt, brisanje stavke iz pripreme: " + _id_firma + "-" + _id_tip_dok + "-" + _br_dok + " stavka br: " + _r_br, 5 )

   IF ( RecCount2() == 1 ) .OR. fakt_unos_is_jedina_stavka()
      fakt_reset_broj_dokumenta( _id_firma, _id_tip_dok, _br_dok )
   ENDIF

   IF _r_br == PadL( "1", 3 ) .AND. ( RecCount() > 1 )

      _prva := dbf_get_rec()

      SKIP

      _tek := dbf_get_rec()

      _update_rbr := _tek[ "rbr" ]

      _tek[ "txt" ] := _prva[ "txt" ]
      _tek[ "rbr" ] := _prva[ "rbr" ]

      dbf_update_rec( _tek )

      SKIP -1

   ENDIF

   PushWA()

   // pobrisi i fakt atribute ove stavke...
   oAttr := DokAttr():new( "fakt", F_FAKT_ATTR )
   oAttr:hAttrId[ "idfirma" ] := _id_firma
   oAttr:hAttrId[ "idtipdok" ] := _id_tip_dok
   oAttr:hAttrId[ "brdok" ] := _br_dok
   oAttr:hAttrId[ "rbr" ] := _r_br
   oAttr:hAttrId[ "update_rbr" ] := _update_rbr
   oAttr:delete_attr_from_dbf()

   IF _update_rbr <> NIL
      oAttr:update_attr_rbr()
   ENDIF

   PopWa()

   my_delete()

   RETURN 1



STATIC FUNCTION fakt_unos_is_jedina_stavka()

   LOCAL nTekRec, cIdFirma, nBrStavki, cIdTipDok, cBrDok

   nBrStavki := 0


   select_o_fakt_pripr()

   nTekRec   := RecNo()
   cIdFirma  := fakt_pripr->IdFirma
   cIdTipDok := fakt_pripr->IdTipDok
   cBrDok    := fakt_pripr->BrDok

   GO TOP
   HSEEK cIdFirma + cIdTipDok + cBrDok // fakt_pripr
   DO WHILE ! Eof () .AND. ( IdFirma == cIdFirma ) .AND. ( IdTipDok == cIdTipDok ) .AND. ( BrDok == cBrDok )
      nBrStavki++
      SKIP
   ENDDO

   GO nTekRec

   RETURN iif( nBrStavki == 1, .T., .F. )



FUNCTION fakt_tip_dok_arr()

   LOCAL aOpcije := {}

   AAdd( aOpcije, "00 - Početno stanje                " )
   AAdd( aOpcije, "01 - Ulaz / Radni nalog " )
   AAdd( aOpcije, "10 - Porezna faktura" )
   AAdd( aOpcije, "11 - Porezna faktura gotovina" )
   AAdd( aOpcije, "12 - Otpremnica" )
   AAdd( aOpcije, "13 - Otpremnica u maloprodaju" )
   AAdd( aOpcije, "19 - Izlaz po ostalim osnovama" )
   AAdd( aOpcije, "20 - Ponuda/Avansna faktura" )
   AAdd( aOpcije, "21 - Revers" )
   AAdd( aOpcije, "22 - Realizovane otpremnice   " )
   AAdd( aOpcije, "25 - Knjižna obavijest " )
   AAdd( aOpcije, "26 - Narudžbenica " )
   AAdd( aOpcije, "27 - Ponuda/Avansna faktura gotovina" )

   RETURN aOpcije
