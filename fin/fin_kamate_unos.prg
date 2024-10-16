/*
 * This file is part of the bring.out FMK, a free and open source
 * accounting software suite,
 * Copyright (c) 1996-2011 by bring.out doo Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including FMK specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_FMK.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */

#include "f18.ch"


STATIC s_dDatumObracuna
STATIC s_cFinKamPrikazKumulativDN := "N"
STATIC s_cObracunPdvDN := "N"


FUNCTION fin_kamate_menu()

   LOCAL _izbor := 1
   LOCAL _opc := {}
   LOCAL _opcexe := {}

   AAdd( _opc, "1. prenos FIN->kamate                     " )
   AAdd( _opcexe, {|| prenos_fin_kam() } )

   AAdd( _opc, "2. unos/ispravka pripreme kamata   " )
   AAdd( _opcexe, {|| kamate_unos() } )

   AAdd( _opc, "3. kontrola cjelovitosti kamatnih stopa   " )
   AAdd( _opcexe, {|| kontrola_cjelovitosti_ks() } )
   AAdd( _opc, "4. lista kamatnih stopa  " )
   AAdd( _opcexe, {|| p_ks() } )

   AAdd( _opc, "P. obračun pojedinačnog dokumenta              " )
   AAdd( _opcexe, {|| kamate_obracun_pojedinacni() } )

   fin_kam_datum_obracuna( Date() )

   f18_menu( "kamat", .F., _izbor, _opc, _opcexe )

   RETURN .T.



FUNCTION kamate_unos()

   LOCAL nI
   LOCAL _x := f18_max_rows() - 15
   LOCAL _y := f18_max_cols() - 5
   PRIVATE ImeKol := {}
   PRIVATE Kol := {}

   O_Edit()

   ImeKol := { ;
      { "KONTO",         {|| IdKonto  }, "Idkonto"   }, ;
      { "Partner",       {|| IdPartner }, "IdPartner" }, ;
      { "Brdok",         {|| Brdok    }, "Brdok"     }, ;
      { "DatOd",         {|| DatOd    }, "DatOd"     }, ;
      { "DatDo",         {|| DatDo    }, "DatDo"     }, ;
      { "Osnovica",      {|| Osnovica }, "Osnovica"  }, ;
      { "M1",            {|| M1       }, "M1"        }  ;
      }

   FOR nI := 1 TO Len( imekol )
      AAdd( Kol, nI )
   NEXT

   Box(, _x, _y )
   @ box_x_koord() + ( _x - 2 ), box_y_koord() + 2 SAY " <c-N>  Nove Stavke      | <ENT> Ispravi stavku   | <c-T> Brisi Stavku"
   @ box_x_koord() + ( _x - 1 ), box_y_koord() + 2 SAY " <c-A>  Ispravka Dokum.  | <c-P> Stampa svi KL    | <c-U> Lista uk.dug"
   @ box_x_koord() + _x, box_y_koord() + 2 SAY " <c-F9> Brisi pripremu   | <a-P> Stampa pojedinac.³                   "
   my_browse( "PNal", _x, _y, {|| fin_kamate_key_handler() }, "", "KAMATE Priprema.....", , , , , 3 )
   BoxC()

   my_close_all_dbf()

   RETURN .T.


// otvaranje potrebnih tabela
STATIC FUNCTION O_Edit()


   O_KS
   //o_partner()
   o_konto()
   select_o_kam_pripr()
   select_o_kam_kamat()
   SELECT kam_pripr
   SET ORDER TO TAG "1"
   GO TOP

   RETURN .T.



// korekcija unos/ispravka
STATIC FUNCTION ispravka_unosa( l_novi )

   IF l_novi
      _idkonto := PadR( "2110", 7 )
   ENDIF

   set_cursor_on()

   @ box_x_koord() + 1, box_y_koord() + 2  SAY "Partner  :" GET _IdPartner PICT "@!" VALID p_partner( @_idpartner )
   @ box_x_koord() + 3, box_y_koord() + 2  SAY "Broj Veze:" GET _BrDok
   @ box_x_koord() + 5, box_y_koord() + 2  SAY "Datum od  " GET _datOd VALID PostojiLi( _idPartner, _brDok, _datOd, l_novi )
   @ box_x_koord() + 5, Col() + 2 SAY "do" GET _datDo
   @ box_x_koord() + 7, box_y_koord() + 2  SAY "Osnovica  " GET _Osnovica PICT "999999999.99"

   READ

   ESC_RETURN 0

   RETURN 1



// postoji li zapis vec
STATIC FUNCTION PostojiLi( idp, brd, dod, lNovi )

   LOCAL _vrati := .T.
   LOCAL _rec_no

   PushWA()

   SELECT kam_pripr
   _rec_no := RecNo()
   GO TOP

   DO WHILE !Eof()
      IF idpartner == idp .AND. brdok == brd .AND. DToC( datod ) == DToC( dod ) .AND. ( RecNo() != _rec_no .OR. lNovi )
         _vrati := .F.
         Msg( "Greska! Vec ste unijeli ovaj podatak!", 3 )
         EXIT
      ENDIF
      SKIP 1
   ENDDO

   GO ( _rec_no )

   PopWA()

   RETURN _vrati



STATIC FUNCTION fin_kamate_key_handler()

   LOCAL nTr2

   IF ( Ch == K_CTRL_T .OR. Ch == K_ENTER ) .AND. reccount2() == 0
      RETURN DE_CONT
   ENDIF

   SELECT kam_pripr

   DO CASE

   CASE Ch == K_CTRL_T
      RETURN browse_brisi_stavku()

   CASE Ch = k_ctrl_f9()
      RETURN browse_brisi_pripremu()

      // ispravka stavke
   CASE Ch == K_ENTER

      Box( "ist", 20, 75, .F. )

      Scatter()

      IF ispravka_unosa( .F. ) == 0
         BoxC()
         RETURN DE_CONT
      ELSE
         my_rlock()
         Gather()
         my_unlock()
         BoxC()
         RETURN DE_REFRESH
      ENDIF

   CASE Ch == K_CTRL_K

      fin_kamate_generisi_mj_uplate()
      RETURN DE_CONT

   CASE Ch == K_CTRL_A

      PushWA()

      SELECT kam_pripr
      GO TOP

      Box( "anal", 13, 75, .F., "Ispravka stavki dokumenta" )

      nDug := 0
      nPot := 0

      DO WHILE !Eof()
         SKIP
         nTR2 := RecNo()
         SKIP - 1
         Scatter()
         @ box_x_koord() + 1, box_y_koord() + 1 CLEAR TO box_x_koord() + 12, box_y_koord() + 74
         IF ispravka_unosa( .F. ) == 0
            EXIT
         ENDIF
         SELECT kam_pripr
         my_rlock()
         Gather()
         my_unlock()
         GO nTR2
      ENDDO

      PopWA()

      BoxC()

      RETURN DE_REFRESH


   CASE Ch == K_CTRL_N   // unos nove stavke

      nDug := 0
      nPot := 0
      nPrvi := 0

      GO BOTTOM

      Box( "knjn", 13, 77, .F., "Unos novih stavki" )

      DO WHILE .T.
         Scatter()
         @ box_x_koord() + 1, box_y_koord() + 1 CLEAR TO box_x_koord() + 12, box_y_koord() + 76
         IF ispravka_unosa( .T. ) == 0
            EXIT
         ENDIF
         SELECT kam_pripr
         APPEND BLANK
         my_rlock()
         Gather()
         my_unlock()
      ENDDO

      BoxC()
      RETURN DE_REFRESH

      // printanje kamatnog lista
   CASE Ch == K_CTRL_P

      fin_kamate_print()
      RETURN DE_REFRESH

      // lista
   CASE Ch == K_CTRL_U

      nArr := Select()
      nUD1 := 0
      nUD2 := 0
      nUD3 := 0

      IF File( my_home() + "pom.dbf" )

         SELECT ( F_TMP_1 )
         USE
         my_use_temp( "POM", my_home() + "pom", .F., .T. )

         SELECT pom
         GO TOP

         IF !start_print()
            RETURN .F.
         ENDIF

         ? "PREGLED UKUPNIH DUGOVANJA PO KUPCIMA"
         ? "------------------------------------"
         ?
         ? "      SIFRA I NAZIV KUPCA            DUG         KAMATA       UKUPNO   "
         ? "-------------------------------- ------------ ------------ ------------"

         DO WHILE !Eof()
            select_o_partner( field->idpartner )
            ? field->idpartner, PadR( partn->naz, 25 ), ;
               Str( field->osndug, 12, 2 ), Str( field->kamate, 12, 2 ), Str( field->osndug + field->kamate, 12, 2 )
            nUd1 += field->osndug
            nUd2 += field->kamate
            nUd3 += ( field->osndug + field->kamate )
            SKIP 1
         ENDDO

         ? "-------------------------------- ------------ ------------ ------------"
         ? "UKUPNO SVI KUPCI................", ;
            Str( nUd1, 12, 2 ), Str( nUd2, 12, 2 ), Str( nUd3, 12, 2 )

         end_print()
         USE
      ENDIF

      select_o_kam_pripr()
      SELECT ( nArr )
      RETURN DE_REFRESH

   CASE Ch == K_ALT_P

      SELECT kam_pripr

      PRIVATE nKamMala := 0
      PRIVATE nOsnDug := 0
      PRIVATE nSOsnSD := 0
      PRIVATE nKamate := 0
      PRIVATE cVarObrac := "Z"

      cIdpartner := Eval( ( TB:getColumn( 2 ) ):Block )

      Box(, 2, 70 )
      @ box_x_koord() + 1, box_y_koord() + 2 SAY "Varijanta (Z-zatezna kamata,P-prosti kamatni racun)" GET cVarObrac VALID cVarObrac $ "ZP" PICT "@!"
      READ
      BoxC()

      IF !start_print()
         RETURN .F.
      ENDIF

      IF fin_kamate_obracun_sa_kamatni_list( cIdPartner, .F., cVarObrac ) > nKamMala
         fin_kamate_obracun_sa_kamatni_list( cIdPartner, .T., cVarObrac )
      ENDIF

      end_print()

      select_o_kam_pripr()
      SELECT kam_pripr
      GO TOP

      RETURN DE_REFRESH

   CASE is_key_alt_a( Ch )
      RETURN DE_REFRESH

   ENDCASE

   RETURN DE_CONT




FUNCTION fin_kamate_rekalkulisi_osnovni_dug()

   LOCAL _date := Date()
   LOCAL nTrec, _id_partner
   LOCAL _osn_dug, _br_dok, _racun
   LOCAL _predhodni
   LOCAL _l_prvi

   Box(, 1, 50 )
   @ box_x_koord() + 1, box_y_koord() + 2 SAY "Ukucaj tacan datum:" GET _date
   READ
   BoxC()

   fin_kam_datum_obracuna( _date )

   SELECT kam_pripr
   GO TOP

   DO WHILE !Eof()

      _id_partner := field->idpartner

      SELECT kam_pripr

      nTrec := RecNo()
      _osn_dug := 0

      DO WHILE !Eof() .AND. _id_partner == field->idpartner

         _br_dok := field->brdok
         _racun := 0
         _predhodni := 0
         _l_prvi := .F.

         DO WHILE !Eof() .AND. _id_partner == field->idpartner .AND. field->brdok == _br_dok

            IF _l_prvi
               _racun := field->osnovica
               _l_prvi := .F.
            ELSE
               _racun := _racun - ( _predhodni - field->osnovica )
            ENDIF

            _racun := fin_kam_iznos_na_dan( _racun, _date, field->datod )
            _predhodni := field->osnovica
            SKIP
         ENDDO

         _osn_dug += _racun
      ENDDO

      GO nTrec

      DO WHILE !Eof() .AND. _id_partner == field->idpartner
         my_rlock()
         REPLACE field->osndug WITH _osn_dug
         my_unlock()
         SKIP
      ENDDO

   ENDDO

   RETURN .T.



FUNCTION fin_kamate_kreiraj_pomocnu_tabelu()

   LOCAL aDbf := {}

   AAdd ( aDbf, { "IDPARTNER", "C",  6, 0 } )
   AAdd ( aDbf, { "OSNDUG", "N", 12, 2 } )
   AAdd ( aDbf, { "KAMATE", "N", 12, 2 } )
   AAdd ( aDbf, { "PDV", "N", 12, 2 } )

   FErase( my_home() + "pom.dbf" )
   FErase( my_home() + "pom.cdx" )

   dbCreate( my_home() + "pom.dbf", aDbf )
   USE

   SELECT ( F_TMP_1 )
   my_use_temp( "POM", my_home() + "pom.dbf", .F., .T. )
   GO TOP

   RETURN .T.


FUNCTION fin_kam_prikaz_kumulativ( cSet )

   IF cSet != NIL
      s_cFinKamPrikazKumulativDN := cSet
   ENDIF

   RETURN s_cFinKamPrikazKumulativDN

FUNCTION fin_kam_obracun_pdv( cSet )

   IF cSet != NIL
      s_cObracunPdvDN := cSet
   ENDIF

   RETURN s_cObracunPdvDN

FUNCTION fin_kam_datum_obracuna( dSet )

   IF dSet != NIL
      s_dDatumObracuna := dSet
   ENDIF

   RETURN s_dDatumObracuna
