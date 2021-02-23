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

STATIC _pic := "999999999.99"
STATIC _skip_docs := "#00#"


// --------------------------------------------
// otvara tabele potrebne za izvjestaj
// --------------------------------------------
STATIC FUNCTION _o_rpt_tables()

   O_MAT_SUBAN
  // o_roba()
  // o_sifk()
  // o_sifv()
  // o_partner()
  // o_konto()

   RETURN



// ----------------------------------------------
// specifikacija po broju dana
// ----------------------------------------------
FUNCTION mat_spec_br_dan()

   LOCAL _params := hb_Hash()
   LOCAL _line

   _o_rpt_tables()

   // uslovi izvjestaja
   IF !_get_vars( @_params )
      my_close_all_dbf()
      RETURN
   ENDIF

   // kreiraj pomocnu tabelu
   _cre_tmp_tbl()
   // otvori tabele izvjestaja
   _o_rpt_tables()

   msgO( "Punim pomocnu tabelu izvjestaja..." )

   // napuni podatke pomocne tabele
   _fill_rpt_data( _params )

   msgC()

   // linija za report
   _line := _get_line()

   // ispisi izvjestaj iz pomocne tabele
   START PRINT CRET
   ?
   P_COND2

   _show_report( _params, _line )

   FF
   ENDPRINT

   RETURN


// -----------------------------------------------
// puni podatke pomocne tabele za izvjestaj
// -----------------------------------------------
STATIC FUNCTION _fill_rpt_data( param )

   LOCAL _firma := PARAM[ "firma" ]
   LOCAL _datum := PARAM[ "datum" ]
   LOCAL _filter := ""
   LOCAL _usl_konto, _usl_artikli
   LOCAL _interv_1, _interv_2, _interv_3
   LOCAL _dug_1, _dug_2, _pot_1, _pot_2
   LOCAL _saldo_1, _saldo_2
   LOCAL cIdRoba, _roba_naz
   LOCAL _ima_poc_stanje := .F.

   SELECT mat_suban
   // "IdFirma+IdKonto+IdRoba+dtos(DatDok)"
   SET ORDER TO TAG "3"

   _usl_konto := Parsiraj( PARAM[ "konta" ], "IdKonto", "C" )
   _usl_artikli := Parsiraj( PARAM[ "artikli" ], "IdRoba", "C" )

   // napravi filter...
   _filter := "idfirma == " + dbf_quote( _firma )

   IF _usl_konto != ".t."
      _filter += " .and. " + _usl_konto
   ENDIF

   IF _usl_artikli != ".t."
      _filter += " .and. " + _usl_artikli
   ENDIF

   IF !Empty( _datum )
      _filter += " .and. DTOS(datdok) <= " + dbf_quote( DToS( _datum ) )
   ENDIF

   SET FILTER to &_filter
   GO TOP


   DO WHILE !Eof()

      _id_konto := field->idkonto

      select_o_konto( _id_konto )

      SELECT mat_suban

      // prodji kroz odredjeni konto
      DO WHILE !Eof() .AND. field->idkonto == _id_konto

         // resetuj brojace
         _int_k_1 := 0
         _int_k_2 := 0
         _int_k_3 := 0
         _int_i_1 := 0
         _int_i_2 := 0
         _int_i_3 := 0
         _saldo_k := 0
         _saldo_i := 0
         _dug := 0
         _pot := 0
         _ulaz := 0
         _izlaz := 0

         cIdRoba := field->idroba

         // nadji mi robu
         SELECT roba
         HSEEK cIdRoba
         _roba_naz := roba->naz

         SELECT mat_suban

         // prodji sada kroz stavke artikla
         DO WHILE !Eof() .AND. field->idkonto == _id_konto .AND. field->idroba == cIdRoba

            // logika izvjestaja

            IF field->idvn == "00"
               _ima_poc_stanje := .T.
            ENDIF

            IF field->u_i == "1"
               _ulaz := field->kolicina
               _izlaz := 0
            ELSE
               _izlaz := field->kolicina
               _ulaz := 0
            ENDIF

            IF field->d_p = "1"
               _dug := field->iznos
               _pot := 0
            ELSE
               _pot := field->iznos
               _dug := 0
            ENDIF

            _saldo_k += _ulaz - _izlaz
            _saldo_i += _dug - _pot

            // ovo ce vratiti interval u odnosu na datum dokumenta
            _interval := _get_interval( field->datdok, _datum )

            // prvi interval, gledamo samo pozitivne ulaze
            IF _interval <= PARAM[ "interval_1" ]
               // ovo je interval do 6 mjeseci npr..
               IF ( ! ( field->idvn $ _skip_docs ) .AND. field->kolicina > 0 ) .OR. field->idvn == "03"
                  _int_i_1 += _dug
                  _int_k_1 += _ulaz
               ENDIF
            ENDIF

            // drugi interval, gledamo samo pozitivne ulaze opet
            IF _interval > PARAM[ "interval_1" ] .AND. _interval <= PARAM[ "interval_2" ]
               // ovo je interval od 6 do 12 mj, npr..
               IF ( ! ( field->idvn $ _skip_docs ) .AND. field->kolicina > 0 ) .OR. field->idvn == "03"
                  _int_i_2 += _dug
                  _int_k_2 += _ulaz
               ENDIF
            ENDIF

            // treci interval
            IF _interval > PARAM[ "interval_2" ]
               // ovo je interval preko 12 mj, npr..
               IF field->kolicina > 0 .OR. field->idvn == "03"
                  _int_i_3 += _dug
                  _int_k_3 += _ulaz
               ENDIF
            ENDIF

            SKIP

         ENDDO

         IF ( _int_k_1 <= 0 )
            _int_k_1 := 0
            _int_i_1 := 0
         ENDIF

         IF ( _int_k_2 <= 0 )
            _int_k_2 := 0
            _int_i_2 := 0
         ENDIF

         IF ( _int_k_3 <= 0 )
            _int_k_3 := 0
            _int_i_3 := 0
         ENDIF

         // ako je saldo manji od prvog intervala
         IF ( _int_k_1 > 0 ) .AND. ( _saldo_k < _int_k_1 )

            _int_k_1 := _saldo_k
            _int_i_1 := _saldo_i

            // ostale intervale resetuj
            _int_k_2 := 0
            _int_i_2 := 0

            _int_k_3 := 0
            _int_i_3 := 0

            // ako je saldo manji od drugog intervala
         ELSEIF ( _int_k_1 == 0 .AND. _int_k_2 > 0 ) .AND. ( _saldo_k < _int_k_2 )

            // ostale intervale resetuj
            _int_k_1 := 0
            _int_i_1 := 0

            // a drugi setuj na ovaj iznos
            _int_k_2 := _saldo_k
            _int_i_2 := _saldo_i

            _int_k_3 := 0
            _int_i_3 := 0

            // ako je saldo manji od treceg intervala
         ELSEIF ( _int_k_1 == 0 .AND. _int_k_2 == 0 .AND. _int_k_3 > 0 ) .AND. ( _saldo_k < _int_k_3 )

            // ostale intervale resetuj
            _int_k_1 := 0
            _int_i_1 := 0

            _int_k_2 := 0
            _int_i_2 := 0

            // a drugi setuj na ovaj iznos
            _int_k_3 := _saldo_k
            _int_i_3 := _saldo_i

         ELSE

            // ako nije nista od toga racunaj treci interval ovako
            _int_k_3 := ( _saldo_k - _int_k_1 - _int_k_2 )
            _int_i_3 := ( _saldo_i - _int_i_1 - _int_i_2 )

         ENDIF


         // ako je negativan onda je nula
         IF _int_k_3 < 0
            _int_k_3 := 0
            _int_i_3 := 0
         ENDIF

         IF Round( _saldo_k, 2 ) == 0 .AND. PARAM[ "prikaz_nule" ] == "N"
            // preskoci...
         ELSE
            // ubaci u pomocnu tabelu podatke
            _fill_tmp_tbl( _id_konto, konto->naz, cIdRoba, _roba_naz, ;
               _int_k_1, _int_k_2, _int_k_3, ;
               _int_i_1, _int_i_2, _int_i_3, ;
               _saldo_k, _saldo_i )
         ENDIF

         SELECT mat_suban

      ENDDO

   ENDDO

   RETURN



// --------------------------------------------------------------
// vraca interval u odnosu na tekuci datum i datum dokumenta
// --------------------------------------------------------------
STATIC FUNCTION _get_interval( dat_dok, datum )

   LOCAL _ret := 1

   _ret := ( datum - dat_dok ) / 30

   RETURN _ret




// -----------------------------------------------
// stampa izvjestaj iz pomocne tabele
// -----------------------------------------------
STATIC FUNCTION _show_report( param, line )

   LOCAL _rbr := 0
   LOCAL _u_int_k_1, _u_int_k_2, _u_int_k_3, _u_saldo_k, _u_saldo_i
   LOCAL _t_int_k_1, _t_int_k_2, _t_int_k_3, _t_saldo_k, _t_saldo_i
   LOCAL _mark_pos := 0
   LOCAL _id_konto, _konto_naz

   // ispis zaglavlje...
   _zaglavlje( param, line )

   SELECT r_export
   SET ORDER TO TAG "1"
   GO TOP

   _t_int_k_1 := 0
   _t_int_k_2 := 0
   _t_int_k_3 := 0
   _t_int_i_1 := 0
   _t_int_i_2 := 0
   _t_int_i_3 := 0
   _t_saldo_k := 0
   _t_saldo_i := 0

   DO WHILE !Eof()

      _id_konto := field->id_konto
      _konto_naz := field->konto_naz

      _u_int_k_1 := 0
      _u_int_k_2 := 0
      _u_int_k_3 := 0
      _u_int_i_1 := 0
      _u_int_i_2 := 0
      _u_int_i_3 := 0
      _u_saldo_k := 0
      _u_saldo_i := 0

      DO WHILE !Eof() .AND. field->id_konto == _id_konto

         _n_str( 63 )

         @ PRow() + 1, 0 SAY ++_rbr PICT '9999'
         @ PRow(), PCol() + 1 SAY field->id_roba
         @ PRow(), PCol() + 1 SAY PadR( field->roba_naz, 40 )

         _mark_pos := PCol()

         @ PRow(), PCol() + 1 SAY field->saldo_k   PICT _pic
         @ PRow(), PCol() + 1 SAY field->saldo_i   PICT _pic

         @ PRow(), PCol() + 1 SAY field->inter_k_1 PICT _pic
         @ PRow(), PCol() + 1 SAY field->inter_i_1 PICT _pic

         @ PRow(), PCol() + 1 SAY field->inter_k_2 PICT _pic
         @ PRow(), PCol() + 1 SAY field->inter_i_2 PICT _pic

         @ PRow(), PCol() + 1 SAY field->inter_k_3 PICT _pic
         @ PRow(), PCol() + 1 SAY field->inter_i_3 PICT _pic

         _u_int_k_1 += field->inter_k_1
         _u_int_k_2 += field->inter_k_2
         _u_int_k_3 += field->inter_k_3
         _u_saldo_k += field->saldo_k

         _u_int_i_1 += field->inter_i_1
         _u_int_i_2 += field->inter_i_2
         _u_int_i_3 += field->inter_i_3
         _u_saldo_i += field->saldo_i

         _t_int_k_1 += field->inter_k_1
         _t_int_k_2 += field->inter_k_2
         _t_int_k_3 += field->inter_k_3
         _t_saldo_k += field->saldo_k

         _t_int_i_1 += field->inter_i_1
         _t_int_i_2 += field->inter_i_2
         _t_int_i_3 += field->inter_i_3
         _t_saldo_i += field->saldo_i

         SKIP

      ENDDO

      // ispisi total za konto
      ? line

      @ PRow() + 1, 0 SAY PadR( " kt:", 4 )
      @ PRow(), PCol() + 1 SAY PadR( _id_konto, 10 )
      @ PRow(), PCol() + 1 SAY PadR( _konto_naz, 40 )
      @ PRow(), PCol() + 1 SAY _u_saldo_k PICT _pic
      @ PRow(), PCol() + 1 SAY _u_saldo_i PICT _pic
      @ PRow(), PCol() + 1 SAY _u_int_k_1 PICT _pic
      @ PRow(), PCol() + 1 SAY _u_int_i_1 PICT _pic
      @ PRow(), PCol() + 1 SAY _u_int_k_2 PICT _pic
      @ PRow(), PCol() + 1 SAY _u_int_i_2 PICT _pic
      @ PRow(), PCol() + 1 SAY _u_int_k_3 PICT _pic
      @ PRow(), PCol() + 1 SAY _u_int_i_3 PICT _pic
      ? line

   ENDDO

   // ukupno....
   ? line
   ? "UKUPNO :"

   @ PRow(), _mark_pos SAY ""
   @ PRow(), PCol() + 1 SAY _t_saldo_k PICT _pic
   @ PRow(), PCol() + 1 SAY _t_saldo_i PICT _pic
   @ PRow(), PCol() + 1 SAY _t_int_k_1 PICT _pic
   @ PRow(), PCol() + 1 SAY _t_int_i_1 PICT _pic
   @ PRow(), PCol() + 1 SAY _t_int_k_2 PICT _pic
   @ PRow(), PCol() + 1 SAY _t_int_i_2 PICT _pic
   @ PRow(), PCol() + 1 SAY _t_int_k_3 PICT _pic
   @ PRow(), PCol() + 1 SAY _t_int_i_3 PICT _pic
   ? line

   RETURN


// ------------------------------------
// provjera novog reda...
// ------------------------------------
STATIC FUNCTION _n_str( row )

   IF PRow() > row
      FF
   ENDIF

   RETURN



// -------------------------------------------------
// linija za ogranicavanje na izvjestaju
// -------------------------------------------------
STATIC FUNCTION _get_line()

   LOCAL _line := ""

   _line += Replicate( "-", 4 )
   _line += Space( 1 )
   _line += Replicate( "-", 10 )
   _line += Space( 1 )
   _line += Replicate( "-", 40 )
   _line += Space( 1 )
   _line += Replicate( "-", 25 )
   _line += Space( 1 )
   _line += Replicate( "-", 25 )
   _line += Space( 1 )
   _line += Replicate( "-", 25 )
   _line += Space( 1 )
   _line += Replicate( "-", 25 )

   RETURN _line






// -------------------------------------------
// zaglavlje izvjestaja.
// -------------------------------------------
STATIC FUNCTION _zaglavlje( param, line )

   LOCAL _r_line_1 := ""
   LOCAL _r_line_2 := ""
   LOCAL _r_line_3 := ""

   ? "MAT: SPECIFIKACIJA PO ROCNIM INTERVALIMA, na dan", Date()
   ? "Firma: " + PARAM[ "firma" ]

   SELECT partn
   HSEEK PARAM[ "firma" ]

   SELECT r_export

   ?? ", " + AllTrim( partn->naz )

   IF !Empty( AllTrim( PARAM[ "konta" ] ) )
      ? "Za konta: " + AllTrim( PARAM[ "konta" ] )
   ENDIF

   IF !Empty( AllTrim( PARAM[ "artikli" ] ) )
      ? "Artikli: " + AllTrim( PARAM[ "artikli" ] )
   ENDIF


   // definisi _r_line...
   _r_line_1 += PadR( " R.", 5 )
   _r_line_2 += PadR( " br.", 5 )
   _r_line_3 += PadR( "", 5 )

   _r_line_1 += PadR( " SIFRA", 11 )
   _r_line_2 += PadR( " ART.", 11 )
   _r_line_3 += PadR( "", 11 )

   _r_line_1 += PadR( "", 41 )
   _r_line_2 += PadR( "      N A Z I V   A R T I K L A", 41 )
   _r_line_3 += PadR( "", 41 )

   _r_line_1 += PadR( "  UKUPNE VRIJEDNOSTI", 26 )
   _r_line_2 += PadR( "", 26 )
   _r_line_3 += PadR( PadC( "KOLICINA", 12 ) + PadC( "IZNOS", 12 ), 26 )

   _r_line_1 += PadR( "           DO " + AllTrim( Str( PARAM[ "interval_1" ], 3 ) ) + " mj.", 26 )
   _r_line_2 += PadR( "", 26 )
   _r_line_3 += PadR( PadC( "KOLICINA", 12 ) + PadC( "IZNOS", 12 ), 26 )

   _r_line_1 += PadR( "       OD " + AllTrim( Str( PARAM[ "interval_1" ], 3 ) ) + " mj.", 26 )
   _r_line_2 += PadR( "       DO " + AllTrim( Str( PARAM[ "interval_2" ], 3 ) ) + " mj.", 26 )
   _r_line_3 += PadR( PadC( "KOLICINA", 12 ) + PadC( "IZNOS", 12 ), 26 )

   _r_line_1 += PadR( "     PREKO " + AllTrim( Str( PARAM[ "interval_2" ], 3 ) ) + " mj.", 26 )
   _r_line_2 += PadR( "", 26 )
   _r_line_3 += PadR( PadC( "KOLICINA", 12 ) + PadC( "IZNOS", 12 ), 26 )


   ? line
   ? _r_line_1
   ? _r_line_2
   ? _r_line_3
   ? line

   RETURN




// ----------------------------------------------
// parametri izvjestaja
// ----------------------------------------------
STATIC FUNCTION _get_vars( params )

   LOCAL _cnt := 1
   LOCAL _ret := .T.
   LOCAL _konta := Space( 200 )
   LOCAL _artikli := Space( 200 )
   LOCAL _firma := self_organizacija_id()
   LOCAL _date := Date()
   LOCAL _int_1 := 6
   LOCAL _int_2 := 12
   LOCAL _nule := "N"
   LOCAL _curr_user := "<>"

   _konta := fetch_metric( "mat_spec_br_dana_konta", _curr_user, _konta )
   _artikli := fetch_metric( "mat_spec_br_dana_artikli", _curr_user, _artikli )
   _firma := fetch_metric( "mat_spec_br_dana_firma", _curr_user, _firma )
   _int_1 := fetch_metric( "mat_spec_br_dana_interval_1", _curr_user, _int_1 )
   _int_2 := fetch_metric( "mat_spec_br_dana_interval_2", _curr_user, _int_2 )
   _nule := fetch_metric( "mat_spec_br_dana_prikaz_nula", _curr_user, _nule )
   _date := fetch_metric( "mat_spec_br_dana_datum", _curr_user, _date )

   Box(, 10, 70 )


      @ box_x_koord() + _cnt, box_y_koord() + 2 SAY "Firma "
      ?? self_organizacija_id(), "-", self_organizacija_naziv()

   ++ _cnt
   ++ _cnt

   @ box_x_koord() + _cnt, box_y_koord() + 2 SAY "  Konto (prazno-sva):" GET _konta PICT "@S45"

   ++ _cnt
   @ box_x_koord() + _cnt, box_y_koord() + 2 SAY "Artikli (prazno-sva):" GET _artikli PICT "@S45"

   ++ _cnt
   @ box_x_koord() + _cnt, box_y_koord() + 2 SAY "Izvjestaj se pravi na dan:" GET _date

   ++ _cnt
   ++ _cnt
   @ box_x_koord() + _cnt, box_y_koord() + 2 SAY "Interval 1 (mj):" GET _int_1 PICT "999"

   ++ _cnt
   @ box_x_koord() + _cnt, box_y_koord() + 2 SAY "Interval 2 (mj):" GET _int_2 PICT "999"

   ++ _cnt
   @ box_x_koord() + _cnt, box_y_koord() + 2 SAY "Prikaz stavki sa stanjem 0 (D/N)?" GET _nule ;
      VALID _nule $ "DN" PICT "!@"

   READ

   BoxC()

   IF LastKey() == K_ESC
      _ret := .F.
      RETURN _ret
   ENDIF

   // setuj parmetre u hash matricu
   params[ "firma" ] := _firma
   params[ "datum" ] := _date
   params[ "konta" ] := _konta
   params[ "artikli" ] := _artikli
   params[ "interval_1" ] := _int_1
   params[ "interval_2" ] := _int_2
   params[ "prikaz_nule" ] := _nule

   // snimi parametre
   set_metric( "mat_spec_br_dana_konta", f18_user(), _konta )
   set_metric( "mat_spec_br_dana_artikli", f18_user(), _artikli )
   set_metric( "mat_spec_br_dana_firma", f18_user(), _firma )
   set_metric( "mat_spec_br_dana_interval_1", f18_user(), _int_1 )
   set_metric( "mat_spec_br_dana_interval_2", f18_user(), _int_2 )
   set_metric( "mat_spec_br_dana_prikaz_nula", f18_user(), _nule )
   set_metric( "mat_spec_br_dana_datum", f18_user(), _date )

   RETURN _ret



// ------------------------------------------------
// filovanje pomocne tabele
// ------------------------------------------------
STATIC FUNCTION _fill_tmp_tbl( id_konto, konto_naz, id_roba, roba_naz, ;
      int_k_1, int_k_2, int_k_3, int_i_1, int_i_2, int_i_3, saldo_k, saldo_i )

   LOCAL _arr := Select()

   SELECT ( F_R_EXP )
   IF !Used()
      o_r_export_legacy()
   ENDIF

   APPEND BLANK
   REPLACE field->id_konto WITH id_konto
   REPLACE field->konto_naz WITH konto_naz
   REPLACE field->id_roba WITH id_roba
   REPLACE field->roba_naz WITH roba_naz
   REPLACE field->inter_k_1 WITH int_k_1
   REPLACE field->inter_k_2 WITH int_k_2
   REPLACE field->inter_k_3 WITH int_k_3
   REPLACE field->inter_i_1 WITH int_i_1
   REPLACE field->inter_i_2 WITH int_i_2
   REPLACE field->inter_i_3 WITH int_i_3
   REPLACE field->saldo_k WITH saldo_k
   REPLACE field->saldo_i WITH saldo_i

   SELECT ( _arr )

   RETURN


// -------------------------------------------------------
// vraca matricu pomocne tabele za izvjestaj
// -------------------------------------------------------
STATIC FUNCTION _cre_tmp_tbl()

   LOCAL _dbf := {}

   AAdd( _dbf, { "id_konto", "C", 7, 0 } )
   AAdd( _dbf, { "konto_naz", "C", 50, 0 } )
   AAdd( _dbf, { "id_roba", "C", 10, 0 } )
   AAdd( _dbf, { "roba_naz", "C", 50, 0 } )
   AAdd( _dbf, { "inter_k_1", "N", 15, 3 } )
   AAdd( _dbf, { "inter_k_2", "N", 15, 3 } )
   AAdd( _dbf, { "inter_k_3", "N", 15, 3 } )
   AAdd( _dbf, { "inter_i_1", "N", 15, 3 } )
   AAdd( _dbf, { "inter_i_2", "N", 15, 3 } )
   AAdd( _dbf, { "inter_i_3", "N", 15, 3 } )
   AAdd( _dbf, { "saldo_k", "N", 15, 3 } )
   AAdd( _dbf, { "saldo_i", "N", 15, 3 } )

   // kreiraj tabelu
   xlsx_export_init( _dbf )

   o_r_export_legacy()
   // indeksiraj...
   INDEX ON id_konto + id_roba TAG "1"

   RETURN
