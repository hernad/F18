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

MEMVAR ImeKol, Kol


FUNCTION P_Roba_select( cId )

   LOCAL xRet

   // lExit := browse_exit_on_enter()
   // browse_exit_on_enter( .T. )
   xRet := p_roba( @cId )
   // browse_exit_on_enter( lExit )

   RETURN xRet


/*
   P_Roba( @cId )
   P_Roba( @cId, NIL, NIL, "IDP") - tag IDP - proizvodi
*/

FUNCTION P_Roba( cId, dx, dy, cTagTraziPoSifraDob )

   LOCAL xRet
   LOCAL bRoba
   LOCAL lArtGroup := .F.
   LOCAL nBrowseRobaNazivLen := 40
   LOCAL nI
   LOCAL cPomTag
   PRIVATE ImeKol
   PRIVATE Kol

   IF cTagTraziPoSifraDob == NIL
      cTagTraziPoSifraDob := ""
   ENDIF

   ImeKol := {}

   PushWA()

   IF cId != NIL .AND. !Empty( cId )
      select_o_roba( "XXXXXXX" ) // cId je zadan, otvoriti samo dummy tabelu sa 0 zapisa
   ELSE
      select_o_roba()
   ENDIF

   AAdd( ImeKol, { PadC( "ID", 10 ),  {|| field->id }, "id", {|| .T. }, {|| valid_sifarnik_id_postoji( wId ) } } )
   AAdd( ImeKol, { PadC( "Naziv", nBrowseRobaNazivLen ), {|| PadR( field->naz, nBrowseRobaNazivLen ) }, "naz", {|| .T. }, {|| .T. } } )
   AAdd( ImeKol, { PadC( "JMJ", 3 ), {|| field->jmj },   "jmj"    } )

   AAdd( ImeKol, { PadC( "PLU kod", 8 ),  {|| PadR( fisc_plu, 10 ) }, "fisc_plu", {|| gen_plu( @wfisc_plu ), .F. }, {|| .T. } } )
   AAdd( ImeKol, { PadC( "S.dobav.", 13 ), {|| PadR( sifraDob, 13 ) }, "sifradob"   } )


   IF programski_modul() != "POS"
      AAdd( ImeKol, { PadC( "VPC", 10 ), {|| Transform( field->VPC, "999999.999" ) }, "vpc", NIL, NIL, NIL, kalk_pic_cijena_bilo_gpiccdem()  } )
      AAdd( ImeKol, { PadC( "VPC2", 10 ), {|| Transform( field->VPC2, "999999.999" ) }, "vpc2", NIL, NIL, NIL, kalk_pic_cijena_bilo_gpiccdem()   } )
      AAdd( ImeKol, { PadC( "Plan.C", 10 ), {|| Transform( field->PLC, "999999.999" ) }, "PLC", NIL, NIL, NIL, kalk_pic_cijena_bilo_gpiccdem()    } )
      AAdd( ImeKol, { PadC( "MPC1", 10 ), {|| Transform( field->MPC, "999999.999" ) }, "mpc", NIL, NIL, NIL, kalk_pic_cijena_bilo_gpiccdem()  } )

      FOR nI := 2 TO 4

         cPom := "mpc" + AllTrim( Str( nI ) )
         cPom2 := '{|| transform(' + cPom + ',"999999.999")}'
         cPrikazi := fetch_metric( "roba_prikaz_" + cPom, NIL, "D" )
         IF cPrikazi == "D"
            AAdd( ImeKol, { PadC( Upper( cPom ), 10 ), &( cPom2 ), cPom, NIL, NIL, NIL, kalk_pic_cijena_bilo_gpiccdem() } )
         ENDIF

      NEXT
      AAdd( ImeKol, { PadC( "NC", 10 ), {|| Transform( field->NC, kalk_pic_cijena_bilo_gpiccdem() ) }, "NC", NIL, NIL, NIL, kalk_pic_cijena_bilo_gpiccdem()  } )
   ENDIF

   AAdd( ImeKol, { "Tarifa", {|| field->IdTarifa }, "IdTarifa", {|| .T. }, {|| P_Tarifa( @wIdTarifa ), roba_opis_edit()  }   } )

   // " " - roba, "G" - roba gorivo, "U" - usluge, "P" - proizvod, "S" - sirovina
   AAdd( ImeKol, { "Tip", {|| " " + field->Tip + " " }, "Tip", {|| .T. }, {|| wTip $ " UPSG" }, NIL, NIL, NIL, NIL, 27 } )
   AAdd ( ImeKol, { PadC( "BARKOD", 14 ), {|| field->BARKOD }, "BarKod", {|| .T. }, {|| roba_valid_barkod( Ch, @wId, @wBarkod ) }  } )

   AAdd ( ImeKol, { PadC( "MINK", 10 ), {|| Transform( field->MINK, "999999.99" ) }, "MINK"   } )

   IF programski_modul() != "POS"
      AAdd ( ImeKol, { PadC( "K1", 4 ), {|| field->k1 }, "k1"   } )
      AAdd ( ImeKol, { PadC( "K2", 4 ), {|| field->k2 }, "k2", {|| .T. }, {|| .T. }, NIL, NIL, NIL, NIL, 35   } )
      AAdd ( ImeKol, { PadC( "N1", 12 ), {|| field->N1 }, "N1"   } )
      AAdd ( ImeKol, { PadC( "N2", 12 ), {|| field->N2 }, "N2", {|| .T. }, {|| .T. }, NIL, NIL, NIL, NIL, 35   } )
   ENDIF

   // AUTOMATSKI TROSKOVI ROBE, samo za KALK
   IF programski_modul() == "KALK"   // .AND. roba->( FieldPos( "TROSK1" ) ) <> 0
      AAdd ( ImeKol, { PadR( c10T1, 8 ), {|| trosk1 }, "trosk1", {|| .T. }, {|| .T. } } )
      AAdd ( ImeKol, { PadR( c10T2, 8 ), {|| trosk2 }, "trosk2", {|| .T. }, {|| .T. }, NIL, NIL, NIL, NIL, 30 } )
      AAdd ( ImeKol, { PadR( c10T3, 8 ), {|| trosk3 }, "trosk3", {|| .T. }, {|| .T. } } )
      AAdd ( ImeKol, { PadR( c10T4, 8 ), {|| trosk4 }, "trosk4", {|| .T. }, {|| .T. }, NIL, NIL, NIL, NIL, 30 } )
      AAdd ( ImeKol, { PadR( c10T5, 8 ), {|| trosk5 }, "trosk5"   } )
   ENDIF

   IF programski_modul() == "KALK"
      AAdd ( ImeKol, { PadC( "Nova cijena", 20 ), {|| Transform( zanivel, "999999.999" ) }, "zanivel", NIL, NIL, NIL, kalk_pic_cijena_bilo_gpiccdem()  } )
      AAdd ( ImeKol, { PadC( "Nova cijena/2", 20 ), {|| Transform( zaniv2, "999999.999" ) }, "zaniv2", NIL, NIL, NIL, kalk_pic_cijena_bilo_gpiccdem()  } )
      AAdd ( ImeKol, { "Id konto", {|| idkonto }, "idkonto", {|| .T. }, {|| Empty( widkonto ) .OR. P_Konto( @widkonto ) }   } )
   ENDIF


   Kol := {}

   FOR nI := 1 TO Len( ImeKol )
      AAdd( Kol, nI )
   NEXT

   SELECT ROBA
   if programski_modul() != "POS"
      sifk_fill_ImeKol( "ROBA", @ImeKol, @Kol )
   ENDIF

   DO CASE
   CASE programski_modul() == "KALK"
      bRoba := {| Ch | kalk_roba_key_handler( Ch ) }

   CASE programski_modul() == "FAKT"
      bRoba := {| Ch | fakt_roba_key_handler( Ch ) }

   OTHERWISE
      bRoba := {| Ch | pos_roba_block( Ch ) }
   ENDCASE


   IF is_roba_trazi_po_sifradob() .AND. !Empty( cTagTraziPoSifraDob )

   /*
      cPomTag := Trim( cTagTraziPoSifraDob )
      SELECT ( F_ROBA )
      IF index_tag_num( "SIFRADOB" ) == 0
         INDEX ON SIFRADOB TAG "SIFRADOB" TO ( "ROBA" )
      ENDIF
      IF cPomTag == "SIFRADOB" .AND. Len( Trim( cId ) ) < 5 // https://redmine.bring.out.ba/issues/36373
         cId := PadL( Trim( cId ), 5, "0" ) // 7148 => 07148, 22 => 00022
      ENDIF
*/
      cPomTag := Trim( cTagTraziPoSifraDob )
      IF find_roba_by_sifradob( cId )
         cId := roba->id
      ENDIF
   ELSE
      cPomTag := "ID"
   ENDIF

   xRet := p_sifra( F_ROBA, ( cPomTag ), f18_max_rows() - 11, f18_max_cols() - 5, "Lista artikala - robe", @cId, dx, dy, bRoba,,,,, { "ID" } )

   PopWa()

   RETURN xRet



FUNCTION roba_opis_edit( view )

   LOCAL _op := "N"
   LOCAL GetList := {}

   IF view == NIL
      view := .F.
   ENDIF

   IF !view

      @ box_x_koord() + 7, box_y_koord() + 43 SAY "Definisati opis artikla (D/N) ?" GET _op PICT "@!" VALID _op $ "DN"
      READ

      IF _op == "N"
         RETURN .T.
      ENDIF

   ENDIF

   Box(, 14, 55 )

   @ box_x_koord() + 1, box_y_koord() + 2 SAY "OPIS ARTIKLA # " + if( !view, "<c-W> za kraj unosa...", "" )

   // otvori memo edit
   wopis := MemoEdit( field->opis, box_x_koord() + 3, box_y_koord() + 1, box_x_koord() + 14, box_y_koord() + 55 )

   BoxC()

   RETURN .T.



// ------------------------------------
// formiranje MPC na osnovu VPC
// ------------------------------------
FUNCTION MpcIzVpc()

   IF pitanje(, "Formirati MPC na osnovu VPC ? (D/N)", "N" ) == "N"
      RETURN DE_CONT
   ENDIF

   PRIVATE GetList := {}
   PRIVATE nZaokNa := 1
   PRIVATE cMPC := " "
   PRIVATE cVPC := " "

   Scatter()
   select_o_tarifa( _idtarifa )
   SELECT roba

   Box(, 4, 70 )
   @ box_x_koord() + 2, box_y_koord() + 2 SAY "Set cijena VPC ( /2)  :" GET cVPC VALID cVPC $ " 2"
   @ box_x_koord() + 3, box_y_koord() + 2 SAY "Set cijena MPC ( /2/3):" GET cMPC VALID cMPC $ " 23"
   READ
   IF Empty( cVPC )
      cVPC := ""
   ENDIF
   IF Empty( cMPC )
      cMPC := ""
   ENDIF
   BoxC()

   Box(, 6, 70 )
   @ box_x_koord() + 1, box_y_koord() + 2 SAY Trim( roba->id ) + "-" + Trim( Left( roba->naz, 40 ) )
   @ box_x_koord() + 2, box_y_koord() + 2 SAY "TARIFA"
   @ box_x_koord() + 2, Col() + 2 SAY _idtarifa
   @ box_x_koord() + 3, box_y_koord() + 2 SAY "VPC" + cVPC
   @ box_x_koord() + 3, Col() + 1 SAY _VPC&cVPC PICT kalk_pic_iznos_bilo_gpicdem()
   @ box_x_koord() + 4, box_y_koord() + 2 SAY "Postojeca MPC" + cMPC
   @ box_x_koord() + 4, Col() + 1 SAY roba->MPC&cMPC PICT kalk_pic_iznos_bilo_gpicdem()
   @ box_x_koord() + 5, box_y_koord() + 2 SAY "Zaokruziti cijenu na (broj decimala):" GET nZaokNa VALID {|| _MPC&cMPC := Round( _VPC&cVPC * ( 1 + tarifa->opp / 100 ) * ( 1 + tarifa->ppp / 100 + tarifa->zpp / 100 ), nZaokNa ), .T. } PICT "9"
   @ box_x_koord() + 6, box_y_koord() + 2 SAY "MPC" + cMPC GET _MPC&cMPC WHEN {|| _MPC&cMPC := Round( _VPC&cVPC * ( 1 + tarifa->opp / 100 ) * ( 1 + tarifa->ppp / 100 + tarifa->zpp / 100 ), nZaokNa ), .T. } PICT kalk_pic_iznos_bilo_gpicdem()
   READ

   BoxC()
   IF LastKey() <> K_ESC
      Gather()
      IF Pitanje(, "Želite li isto uraditi za sve artikle kod kojih je MPC" + cMPC + "=0 ? (D/N)", "N" ) == "D"
         nRecAM := RecNo()
         Postotak( 1, RECCOUNT2(), "Formiranje cijena" )
         nStigaoDo := 0
         GO TOP
         DO WHILE !Eof()
            IF ROBA->MPC&cMPC == 0
               Scatter()
               select_o_tarifa( _idtarifa )
               SELECT roba
               _MPC&cMPC := Round( _VPC&cVPC * ( 1 + tarifa->opp / 100 ) * ( 1 + tarifa->ppp / 100 + tarifa->zpp / 100 ), nZaokNa )
               Gather()
            ENDIF
            Postotak( 2, ++nStigaoDo )
            SKIP 1
         ENDDO
         Postotak( 0 )
         GO ( nRecAM )
      ENDIF
      RETURN DE_REFRESH
   ENDIF

   RETURN DE_CONT


// -------------------------------------------------------
// setovanje tarife 2 i 3 u sifrarniku na osnovu idtarifa
// -------------------------------------------------------
FUNCTION set_tar_rs( cId1, cId2 )

   IF Empty( cId1 )
      cId1 := cId2
   ENDIF

   RETURN .T.


FUNCTION WhenBK()

   IF Empty( wBarKod )
      wBarKod := PadR( wId, Len( wBarKod ) )
      AEval( GetList, {| o | o:display() } )
   ENDIF

   RETURN .T.



// roba ima zasticenu cijenu
// sto znaci da krajnji kupac uvijek placa fixan iznos pdv-a
// bez obzira po koliko se roba prodaje
FUNCTION RobaZastCijena( cIdTarifa )

   lZasticena := .F.
   lZasticena := lZasticena .OR.  ( PadR( cIdTarifa, 6 ) == PadR( "PDVZ", 6 ) )
   lZasticena := lZasticena .OR.  ( PadR( cIdTarifa, 6 ) == PadR( "PDV17Z", 6 ) )
   lZasticena := lZasticena .OR.  ( PadR( cIdTarifa, 6 ) == PadR( "CIGA05", 6 ) )

   RETURN lZasticena


FUNCTION OFmkRoba()

   // o_sifk()
   // o_sifv()
   // o_konto()
   // o_koncij()
   o_trfp()
   // o_tarifa()
   // o_roba()
   // o_sastavnice()

   RETURN .T.



// ----------------------------------------------------
// provjera cijena u sifrarniku artikala
// ----------------------------------------------------
FUNCTION sifre_artikli_provjera_mp_cijena()

   LOCAL _check := {}
   LOCAL nI, _n, _x, _mpc
   LOCAL _line
   LOCAL _decimal := 2

   SELECT ( F_ROBA )
   IF !Used()
      o_roba()
   ENDIF

   MsgO( "Provjera šifarnika artikala u toku ..." )
   GO TOP
   DO WHILE !Eof()

      // prodji kroz MPC setove
      FOR _n := 1 TO 9

         // MPC, MPC2, MPC3...

         _tmp := "mpc"

         IF _n > 1
            _tmp += AllTrim( Str( _n ) )
         ENDIF

         _mpc := field->&_tmp

         IF Abs( _mpc ) - Abs( Val( Str( _mpc, 12, _decimal ) ) ) <> 0

            _n_scan := AScan( _check, {| val | val[ 1 ] == field->id  } )

            IF _n_scan == 0
               // dodaj u matricu...
               AAdd( _check, { field->id, field->barkod, field->naz, ;
                  IF( _n == 1, _mpc, 0 ), ;
                  IF( _n == 2, _mpc, 0 ), ;
                  IF( _n == 3, _mpc, 0 ), ;
                  IF( _n == 4, _mpc, 0 ), ;
                  IF( _n == 5, _mpc, 0 ), ;
                  IF( _n == 6, _mpc, 0 ), ;
                  IF( _n == 7, _mpc, 0 ), ;
                  IF( _n == 8, _mpc, 0 ), ;
                  IF( _n == 9, _mpc, 0 ) } )
            ELSE
               // dodaj u postojecu matricu
               _check[ _n_scan, 2 + _n ] := _mpc
            ENDIF

         ENDIF

      NEXT

      SKIP

   ENDDO

   MsgC()

   // nema gresaka
   IF Len( _check ) == 0
      my_close_all_dbf()
      RETURN
   ENDIF

   START PRINT CRET

   ?

   P_COND2

   _count := 0
   _line := _get_check_line()

   ? _line

   ? "Lista artikala sa nepravilnom MPC"

   ? _line

   ? PadR( "R.br.", 6 ), PadR( "Artikal ID", 10 ), PadR( "Barkod", 13 ), ;
      PadR( "Naziv artikla", 30 ), ;
      PadC( "MPC1", 15 ), ;
      PadC( "MPC2", 15 ), ;
      PadC( "MPC3", 15 ), ;
      PadC( "MPC4", 15 )
   // PadC( "MPC5", 15 ), ;
   // PadC( "MPC6", 15 ), ;
   // PadC( "MPC7", 15 ), ;
   // PadC( "MPC8", 15 ), ;
   // PadC( "MPC9", 15 )

   ? _line

   FOR nI := 1 TO Len( _check )

      ? PadL( AllTrim( Str( ++_count ) ) + ".", 6 )
      // id
      @ PRow(), PCol() + 1 SAY _check[ nI, 1 ]
      // barkod
      @ PRow(), PCol() + 1 SAY _check[ nI, 2 ]
      // naziv
      @ PRow(), PCol() + 1 SAY PadR( _check[ nI, 3 ], 30 )

      // setovi cijena...
      FOR _x := 1 TO 9

         // mpc, mpc2, mpc3...
         _cijena := _check[ nI, 3 + _x ]

         IF Round( _cijena, 4 ) == 0
            _tmp := PadR( "", 15 )
         ELSE
            _tmp := Str( _cijena, 15, 4 )
         ENDIF

         @ PRow(), PCol() + 1 SAY _tmp

      NEXT
   NEXT

   ? _line

   FF

   my_close_all_dbf()

   ENDPRINT

   RETURN


STATIC FUNCTION _get_check_line()

   LOCAL _line := ""

   _line += Replicate( "-", 6 )
   _line += Space( 1 )
   _line += Replicate( "-", 10 )
   _line += Space( 1 )
   _line += Replicate( "-", 13 )
   _line += Space( 1 )
   _line += Replicate( "-", 30 )
   _line += Space( 1 )
   _line += Replicate( "-", 15 )
   _line += Space( 1 )
   _line += Replicate( "-", 15 )
   _line += Space( 1 )
   _line += Replicate( "-", 15 )
   _line += Space( 1 )
   _line += Replicate( "-", 15 )
   _line += Space( 1 )
   _line += Replicate( "-", 15 )
   _line += Space( 1 )
   _line += Replicate( "-", 15 )
   _line += Space( 1 )
   _line += Replicate( "-", 15 )
   _line += Space( 1 )
   _line += Replicate( "-", 15 )
   _line += Space( 1 )
   _line += Replicate( "-", 15 )

   RETURN _line





// --------------------------------------------------
// prikaz izvjestaja duplih barkodova
// --------------------------------------------------
FUNCTION rpt_dupli_barkod()

   LOCAL _data

   MsgO( "Formiram sql upit ..." )
   _data := __dupli_bk_sql()
   MsgC()

   __dupli_bk_rpt( _data )

   RETURN



STATIC FUNCTION __dupli_bk_sql()

   LOCAL _qry, _table

   _qry := "SELECT id, naz, barkod " + ;
      "FROM " + F18_PSQL_SCHEMA + ".roba r1 " + ;
      "WHERE barkod <> '' AND barkod IN ( " + ;
      "SELECT barkod " + ;
      "FROM " + F18_PSQL_SCHEMA + ".roba r2 " + ;
      "GROUP BY barkod " + ;
      "HAVING COUNT(*) > 1 " + ;
      ") " + ;
      "ORDER BY barkod"

   _table := run_sql_query( _qry )
   IF sql_error_in_query( _table, "SELECT" )
      RETURN NIL
   ENDIF

   RETURN _table


// -----------------------------------------------
// prikaz duplih barkodova iz sifrarnika
// -----------------------------------------------
STATIC FUNCTION __dupli_bk_rpt( DATA )

   LOCAL nI

   IF ValType( DATA ) == "L" .OR. Len( DATA ) == 0
      MsgBeep( "Nema podataka za prikaz !" )
      RETURN
   ENDIF

   START PRINT CRET

   ?

   ? "Dupli barkodovi unutar sifrarnika artikala:"
   ? "----------------------------------------------------------------------------------"
   ? "ID             NAZIV                                    BARKOD"
   ? "----------------------------------------------------------------------------------"

   DO WHILE !data:Eof()

      _row := data:GetRow()

      ? _row:FieldGet( _row:FieldPos( "id" ) ), ;
         PadR( hb_UTF8ToStr( _row:FieldGet( _row:FieldPos( "naz" ) ) ), 40 ), ;
         _row:FieldGet( _row:FieldPos( "barkod" ) )

      data:Skip()

   ENDDO

   FF
   ENDPRINT

   RETURN .T.


// --------------------------------------------------------
// setovanje mpc cijene iz vpc
// --------------------------------------------------------
FUNCTION roba_setuj_mpc_iz_vpc()

   LOCAL _params := hb_Hash()
   LOCAL _rec
   LOCAL _mpc_set
   LOCAL _tarifa
   LOCAL _count := 0
   LOCAL lOk := .T.
   LOCAL hParams

   IF !_get_params( @_params )
      RETURN .F.
   ENDIF

   run_sql_query( "BEGIN" )
   IF !f18_lock_tables( { "roba" }, .T. )
      run_sql_query( "ROLLBACK" )
      RETURN .F.
   ENDIF

   o_tarifa()
   o_roba()
   GO TOP

   // koji cu set mpc gledati...
   IF _params[ "mpc_set" ] == 1
      _mpc_set := "mpc"
   ELSE
      _mpc_set := "mpc" + AllTrim( Str( _params[ "mpc_set" ] ) )
   ENDIF

   Box(, 2, 70 )

   DO WHILE !Eof()

      _rec := dbf_get_rec()

      IF !Empty( _params[ "filter_id" ] )
         _filt_id := Parsiraj( _params[ "filter_id" ], "id" )
         IF !( &_filt_id )
            SKIP
            LOOP
         ENDIF
      ENDIF

      // vpc je 0, preskoci...
      IF Round( _rec[ "vpc" ], 3 ) == 0
         SKIP
         LOOP
      ENDIF

      // konverzija samo tamo gdje je mpc = 0
      IF Round( _rec[ _mpc_set ], 3 ) <> 0 .AND. _params[ "mpc_nula" ] == "D"
         SKIP
         LOOP
      ENDIF

      _tarifa := _rec[ "idtarifa" ]

      IF Empty( _tarifa )
         SKIP
         LOOP
      ENDIF

      select_o_tarifa( _tarifa )

      IF !Found()
         SELECT roba
         SKIP
         LOOP
      ENDIF

      SELECT roba

      IF tarifa->opp > 0

         // napravi kalkulaciju...
         _rec[ _mpc_set ] := Round( _rec[ "vpc" ] * ( 1 + ( tarifa->opp / 100 ) ), 2 )

         // zaokruzi na 5 pf
         IF _params[ "zaok_5pf" ] == "D"
            _rec[ _mpc_set ] := _rec[ _mpc_set ] - zaokr_5pf( _rec[ _mpc_set ] )
         ENDIF

         @ box_x_koord() + 1, box_y_koord() + 2 SAY PadR( "Artikal: " + _rec[ "id" ] + "-" + PadR( _rec[ "naz" ], 20 ) + "...", 50 )
         @ box_x_koord() + 2, box_y_koord() + 2 SAY PadR( " VPC: " + AllTrim( Str( _rec[ "vpc" ], 12, 3 ) ) + ;
            " -> " + Upper( _mpc_set ) + ": " + AllTrim( Str( _rec[ _mpc_set ], 12, 3 ) ), 50 )

         lOk := update_rec_server_and_dbf( "roba", _rec, 1, "CONT" )

         ++_count

      ENDIF

      IF !lOk
         EXIT
      ENDIF

      SKIP

   ENDDO

   BoxC()

   IF lOk
      hParams := hb_Hash()
      hParams[ "unlock" ] :=  { "roba" }
      run_sql_query( "COMMIT", hParams )
   ELSE
      run_sql_query( "ROLLBACK" )
   ENDIF

   RETURN .T.



STATIC FUNCTION _get_params( params )

   LOCAL _ok := .F.
   LOCAL _x := 1
   LOCAL _mpc_no := 1
   LOCAL _zaok_5pf := "D"
   LOCAL _mpc_nula := "D"
   LOCAL _filter_id := Space( 200 )

   Box(, 10, 65 )

   @ box_x_koord() + _x, box_y_koord() + 2 SAY "VPC -> MPC..."

   _x += 2
   @ box_x_koord() + _x, box_y_koord() + 2 SAY "Setovati MPC (1/2/.../9)" GET _mpc_no VALID _mpc_no >= 1 .AND. _mpc_no < 10 PICT "9"
   ++_x
   @ box_x_koord() + _x, box_y_koord() + 2 SAY "Zaokruženje 0.5pf (D/N) ?" GET _zaok_5pf VALID _zaok_5pf $ "DN" PICT "@!"
   ++_x
   @ box_x_koord() + _x, box_y_koord() + 2 SAY "Setovati samo gdje je MPC = 0 (D/N) ?" GET _mpc_nula VALID _mpc_nula $ "DN" PICT "@!"
   _x += 2
   @ box_x_koord() + _x, box_y_koord() + 2 SAY "Filter po polju ID:" GET _filter_id PICT "@S40"

   READ

   BoxC()

   IF LastKey() == K_ESC
      RETURN _ok
   ENDIF

   params := hb_Hash()
   params[ "mpc_set" ] := _mpc_no
   params[ "zaok_5pf" ] := _zaok_5pf
   params[ "mpc_nula" ] := _mpc_nula
   params[ "filter_id" ] := AllTrim( _filter_id )

   _ok := .T.

   RETURN _ok
