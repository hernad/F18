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


/*
 *     When blok za unos MPC
 *   param: fRealizacija -
 *   param: cProracunMarzeUnaprijed -
 */

FUNCTION WMpc( fRealizacija, cProracunMarzeUnaprijed )

   IF fRealizacija == nil
      fRealizacija := .F.
   ENDIF

   IF fRealizacija
      cProracunMarzeUnaprijed := " "
   ENDIF

   IF _mpcsapp <> 0
      _marza2 := 0
      _mpc := MpcBezPor( _mpcsapp, aPorezi, , _nc )
   ENDIF

   IF fRealizacija
      IF ( _idvd == "47" )
         _nc := _mpc
      ENDIF
   ENDIF

   RETURN .T.



/* VMpc(fRealizacija,cProracunMarzeUnaprijed)
 *     Valid blok za unos MPC
 *   param: fRealizacija -
 *   param: cProracunMarzeUnaprijed -
 */
FUNCTION VMpc( fRealizacija, cProracunMarzeUnaprijed )

   IF fRealizacija == NIL
      fRealizacija := .F.
   ENDIF

   IF fRealizacija
      cProracunMarzeUnaprijed := " "
   ENDIF

   IF cProracunMarzeUnaprijed == NIL
      cProracunMarzeUnaprijed := " "
   ENDIF

   kalk_marza_11( cProracunMarzeUnaprijed )

   IF _mpcsapp == 0
      _MPCSaPP := Round( MpcSaPor( _mpc, aPorezi ), 2 )
   ENDIF

   RETURN .T.



/* VMpcSaPP(fRealizacija,cProracunMarzeUnaprijed)
 *     Valid blok za unos MpcSaPP
 *   param: fRealizacija -
 *   param: cProracunMarzeUnaprijed -
 */
FUNCTION VMpcSaPP( fRealizacija, cProracunMarzeUnaprijed )

   LOCAL nRabat

   IF fRealizacija == NIL
      fRealizacija := .F.
   ENDIF

   IF fRealizacija
      nRabat := _rabatv
   ELSE
      nRabat := 0
   ENDIF

   IF cProracunMarzeUnaprijed == NIL
      cProracunMarzeUnaprijed := " "
   ENDIF

   IF _mpcsapp <> 0 .AND. Empty( cProracunMarzeUnaprijed )

      _mpc := MpcBezPor( _mpcsapp, aPorezi, nRabat, _nc )

      _marza2 := 0
      IF fRealizacija
         Marza2R()
      ELSE
         kalk_Marza_11()
      ENDIF
      ShowGets()

      IF fRealizacija
         // DuplRoba()
      ENDIF
   ENDIF

   cProracunMarzeUnaprijed := " "

   RETURN .T.


FUNCTION kalk_say_pdv_a_porezi_var( nRow )

   @ box_x_koord() + nRow, box_y_koord() + 2  SAY "PDV (%):"
   @ Row(), Col() + 2 SAY aPorezi[ POR_PDV ] PICTURE "99.99"

   RETURN .T.



/*
 *     Puni polja izgenerisane stavke
 *   param: pIzgStavke - .f. ne puni, .t. puni


--FUNCTION kalk_puni_polja_za_izgenerisane_stavke( lKalkIzgenerisaneStavke )

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
            REPLACE nc WITH kalk_pripr->fcj, ;
               vpc WITH _vpc, ;
               tprevoz WITH _tprevoz, ;
               prevoz WITH _prevoz, ;
               mpc    WITH _mpc, ;
               mpcsapp WITH _mpcsapp, ;
               tmarza  WITH _tmarza, ;
               marza  WITH _vpc - kalk_pripr->fcj, ;      // konkretna vp marza
               tmarza2  WITH _tmarza2, ;
               marza2  WITH _marza2, ;
               mkonto WITH _mkonto, ;
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

   RETURN .T.
*/


/*
 *     When blok za unos MPC
 *   param: fRealizacija -
 *   param: cProracunMarzeUnaprijed -
 *  note koriste se lokalne varijable
 */
FUNCTION WMpc_lv( fRealizacija, cProracunMarzeUnaprijed, aPorezi )

   // legacy

   IF fRealizacija == nil
      fRealizacija := .F.
   ENDIF

   IF fRealizacija
      cProracunMarzeUnaprijed := " "
   ENDIF

   IF _MpcSapp <> 0
      _marza2 := 0
      _Mpc := MpcBezPor( _MpcSaPP, aPorezi, , _nc )
   ENDIF

   IF fRealizacija
      IF ( _idvd == "47" )
         _nc := _mpc
      ENDIF
   ENDIF

   RETURN .T.



/* VMpc_lv(fRealizacija, cProracunMarzeUnaprijed, aPorezi)
 *     Valid blok za unos MPC
 *   param: fRealizacija -
 *   param: cProracunMarzeUnaprijed -
 *  note koriste se lokalne varijable
 */
FUNCTION VMpc_lv( fRealizacija, cProracunMarzeUnaprijed, aPorezi )

   IF fRealizacija == nil
      fRealizacija := .F.
   ENDIF
   IF fRealizacija
      cProracunMarzeUnaprijed := " "
   ENDIF
   IF cProracunMarzeUnaprijed == nil
      cProracunMarzeUnaprijed := " "
   ENDIF

   kalk_marza_11( cProracunMarzeUnaprijed )
   IF ( _mpcsapp == 0 )
      _MPCSaPP := Round( MpcSaPor( _mpc, aPorezi ), 2 )
   ENDIF

   RETURN .T.



FUNCTION kalk_when_valid_mpc_80_81_41_42( cIdVd, lNaprijed, aPorezi )

   LOCAL _st_popust

   // formiraj cijenu naprijed
   IF lNaprijed
      // postavi _Mpc bez poreza
      MarzaMP( cIdVd, .T., aPorezi )
   ENDIF

   IF cIdVd $ "41#42#47"
      nMpcSaPDV := _MpcSaPP
      _st_popust := _rabatv
   ELSE
      nMpcSaPDV := _MpcSapp
      _st_popust := 0
   ENDIF

   // postoji MPC, idi unazad
   IF !lNaprijed .AND. _MpcSapp <> 0
      _Marza2 := 0
      _Mpc := MpcBezPor( nMpcSaPDV, aPorezi, , _nc ) - _st_popust
   ENDIF

   RETURN .T.


FUNCTION kalk_valid_mpc_80_81_41_42( cIdVd, lNaprijed, aPorezi )

   LOCAL nPopust

   IF cIdVd $ "41#42#47"
      nPopust := _RabatV
   ELSE
      nPopust := 0
   ENDIF

   MarzaMp( cIdVd, lNaprijed, aPorezi )

   IF ( _Mpcsapp == 0 )
      _mpcsapp := Round( MpcSaPor( _mpc, aPorezi ), 2 ) + nPopust
   ENDIF

   RETURN .T.


STATIC FUNCTION MarzaMP( cIdVd, lNaprijed, aPorezi )

   LOCAL nPrevMP

   // za svaki slucaj setujemo ovo ako slucajno u dokumentu nije ispranvo
   IF cIdVD $ "11#12#13"
      // inace je _fcj kod ovih dokumenata  = nabavnoj cijeni
      // _nc u ovim dokumentima moze biti uvecana za troskove prevoza
      _VPC := _FCJ
   ENDIF

   IF cIdVD $ "80"
      _vpc := _nc
      _fcj := _nc
   ENDIF

   // ako je prevoz u MP rasporedjen uzmi ga u obzir
   IF  ( cIdVd $ "11#12#13" ) .AND. ( _TPrevoz == "A" )
      nPrevMP := _Prevoz
   ELSE
      nPrevMP := 0
   ENDIF

   IF  ( _Marza2 == 0 ) .AND. !lNaprijed

      nMarza2 := _MPC - _VPC - nPrevMP

      IF _TMarza2 == "%"
         IF Round( _VPC, 5 ) <> 0
            _Marza2 := 100 * ( _MPC / ( _VPC + nPrevMP ) - 1 )
         ELSE
            _Marza2 := 0
         ENDIF

      ELSEIF _TMarza2 == "A"
         _Marza2 := nMarza2

      ELSEIF _TMarza2 == "U"
         _Marza2 := nMarza2 * ( _Kolicina )
      ENDIF

   ELSEIF ( _MPC == 0 ) .OR. lNaprijed

      IF _TMarza2 == "%"
         nMarza2 := _Marza2 / 100 * ( _VPC + nPrevMP )
      ELSEIF _TMarza2 == "A"
         nMarza2 := _Marza2
      ELSEIF _TMarza2 == "U"
         nMarza2 := _Marza2 / ( _Kolicina )
      ENDIF

      _MPC := Round( nMarza2 + _VPC, 2 )

      _MpcSaPP := Round( MpcSaPor( _mpc, aPorezi ), 2 )

   ELSE
      nMarza2 := _MPC - _VPC - nPrevMP
   ENDIF

   AEval( GetList, {| o | o:display() } )

   RETURN



/* VMpcSaPP_lv(fRealizacija, cProracunMarzeUnaprijed, aPorezi)
 *     Valid blok za unos MpcSaPP
 *   param: fRealizacija -
 *   param: cProracunMarzeUnaprijed -
 */
FUNCTION VMpcSaPP_lv( fRealizacija, cProracunMarzeUnaprijed, aPorezi, lShowGets )

   LOCAL nPom

   IF lShowGets == nil
      lShowGets := .T.
   ENDIF

   IF fRealizacija == NIL
      fRealizacija := .F.
   ENDIF

   IF fRealizacija
      nPom := _mpcsapp
   ELSE
      nPom := _mpcsapp
   ENDIF

   IF cProracunMarzeUnaprijed == nil
      cProracunMarzeUnaprijed := " "
   ENDIF

   IF _mpcsapp <> 0 .AND. Empty( cProracunMarzeUnaprijed )
      _mpc := MpcBezPor ( nPom, aPorezi, , _nc ) - _rabatv
      _marza2 := 0
      IF fRealizacija
         Marza2R()
      ELSE
         kalk_marza_11()
      ENDIF
      IF lShowGets
         ShowGets()
      ENDIF
      IF fRealizacija
         // DuplRoba()
      ENDIF
   ENDIF

   cProracunMarzeUnaprijed := " "

   RETURN .T.


// ---------------------------------------------------------------
// racuna mpc sa porezom
// ---------------------------------------------------------------
FUNCTION kalk_valid_mpcsapdv( cIdVd, lNaprijed, aPorezi, lShowGets )

   LOCAL nPom

   IF lShowGets == nil
      lShowGets := .T.
   ENDIF

   IF cIdvd $ "41#42"
      nPom := _mpcsapp
   ELSE
      nPom := _mpcsapp
   ENDIF

   IF _Mpcsapp <> 0 .AND. !lNaprijed

      // mpc ce biti umanjena mpc sa pp - porez - rabat (ako postoji)
      _mpc := MpcBezPor( nPom, aPorezi, , _nc ) - _rabatv

      _marza2 := 0

      MarzaMP( cIdVd, lNaprijed, aPorezi )

      IF lShowGets
         ShowGets()
      ENDIF

      IF cIdVd $ "41#42"
         // DuplRoba()
      ENDIF

   ENDIF

   RETURN .T.



/*
 *     Ispisuje poreze
 *   param: nRow - relativna kooordinata reda u kojem se ispisuju porezi
 *  aPorezi - koristi lokalne varijable
 */

FUNCTION SayPorezi_lv( nRow, aPorezi )

   @ box_x_koord() + nRow, box_y_koord() + 2  SAY "PDV (%):"
   @ Row(), Col() + 2 SAY  aPorezi[ POR_PDV ] PICTURE "99.99"

   RETURN .T.
