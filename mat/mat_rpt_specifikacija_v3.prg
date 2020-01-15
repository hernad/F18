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


STATIC PicDEM := "999999999.99"
STATIC PicBHD := "999999999.99"
STATIC PicKol := "99999999.999"


// -------------------------------------------------
// otvara potrebne tabele za report
// -------------------------------------------------
STATIC FUNCTION _o_rpt_tables()

//   o_roba()
//   o_sifk()
//   o_sifv()
   O_MAT_SUBAN
//   o_partner()

   RETURN



// ------------------------------------------------
// uslovi izvjestaja
// ------------------------------------------------
STATIC FUNCTION _get_vars( params )

   LOCAL _fmt
   LOCAL _firma
   LOCAL _konta
   LOCAL _artikli
   LOCAL _dat_od
   LOCAL _dat_do
   LOCAL _group
   LOCAL _group_sifra
   LOCAL _sel_groups
   LOCAL _group_lista
   LOCAL _cnt := 1
   LOCAL _ret := .T.

   // inicijalizujem def.parametre
   _fmt := "2"
   _firma := self_organizacija_id()
   _konta := Space( 200 )
   _artikli := Space( 200 )
   _dat_od := CToD( "" )
   _dat_do := CToD( "" )
   _group := "N"
   _sel_groups := Space( 200 )
   _vrijednost := "N"
   _group_sifra := "N"
   _group_lista := "N"

   // uzmi parametre iz sql/db
   _firma := fetch_metric( "mat_rpt_specifikacija_firma", my_user(), _firma )
   _konta := fetch_metric( "mat_rpt_specifikacija_konta", my_user(), _konta )
   _artikli := fetch_metric( "mat_rpt_specifikacija_artikli", my_user(), _artikli )
   _dat_od := fetch_metric( "mat_rpt_specifikacija_datum_od", my_user(), _dat_od )
   _dat_do := fetch_metric( "mat_rpt_specifikacija_datum_do", my_user(), _dat_do )
   _group := fetch_metric( "mat_rpt_specifikacija_grupe", my_user(), _group )
   _group_sifra := fetch_metric( "mat_rpt_specifikacija_grupe_iz_sifre", my_user(), _group_sifra )
   _group_lista := fetch_metric( "mat_rpt_specifikacija_sadrzaj_grupe", my_user(), _group_lista )
   _sel_groups := fetch_metric( "mat_rpt_specifikacija_selektovane_grupe", my_user(), _sel_groups )
   _vrijednost := fetch_metric( "mat_rpt_specifikacija_samo_vrijednost", my_user(), _vrijednost )


   Box( "Spe2", 13, 65, .F. )

   ++ _cnt

   @ box_x_koord() + _cnt, box_y_koord() + 2 SAY "Iznos u " + valuta_domaca_skraceni_naziv() + "/" + ValPomocna() + "(1/2) ?" GET _fmt ;
      VALID _fmt $ "12"
   READ

   IF _fmt == "1"
      _fmt := "2"
   ELSE
      _fmt := "3"
   ENDIF

   ++ _cnt
   ++ _cnt


      @ box_x_koord() + _cnt, box_y_koord() + 2 SAY "Firma "
      ?? self_organizacija_id(), "-", self_organizacija_naziv()


   ++ _cnt
   @ box_x_koord() + _cnt, box_y_koord() + 2 SAY "Konta : " GET _konta PICT "@S50"

   ++ _cnt
   @ box_x_koord() + _cnt, box_y_koord() + 2 SAY "Artikli : " GET _artikli PICT "@S50"

   ++ _cnt
   @ box_x_koord() + _cnt, box_y_koord() + 2 SAY "Datum dokumenta - od:" GET _dat_od
   @ box_x_koord() + _cnt, Col() + 1 SAY "do:" GET _dat_do VALID _dat_do >= _dat_od

   ++ _cnt
   @ box_x_koord() + _cnt, box_y_koord() + 2 SAY "Prikaz po grupacijama (D/N)?" GET _group ;
      VALID _group $ "DN" PICT "@!"

   @ box_x_koord() + _cnt, Col() + 1 SAY "Grupu uzmi iz sifre (D/N)?" GET _group_sifra ;
      VALID _group_sifra $ "DN" PICT "@!"

   ++ _cnt
   @ box_x_koord() + _cnt, box_y_koord() + 2 SAY "Grupe:" GET _sel_groups PICT "@S50"

   ++ _cnt
   @ box_x_koord() + _cnt, box_y_koord() + 2 SAY "Prikazati sadrzaj grupe (D/N)?" GET _group_lista ;
      VALID _group_lista $ "DN" PICT "@!"

   ++ _cnt
   @ box_x_koord() + _cnt, box_y_koord() + 2 SAY "Prikaz samo vrijednosti" GET _vrijednost PICT "@!" VALID _vrijednost $ "DN"

   READ

   BoxC()

   IF LastKey() == K_ESC
      _ret := .F.
      RETURN _ret
   ENDIF

   // hash parametre napuni sa varijablama
   params[ "format" ] := _fmt
   params[ "firma" ] := _firma
   params[ "konta" ] := _konta
   params[ "artikli" ] := _artikli
   params[ "dat_od" ] := _dat_od
   params[ "dat_do" ] := _dat_do
   params[ "po_grupi" ] := _group
   params[ "grupa_na_osnovu_sifre" ] := _group_sifra
   params[ "grupe" ] := _sel_groups
   params[ "samo_vrijednost" ] := _vrijednost
   params[ "listaj_sadrzaj_grupe" ] := _group_lista

   // snimi parametre u sql/db
   set_metric( "mat_rpt_specifikacija_firma", my_user(), _firma )
   set_metric( "mat_rpt_specifikacija_konta", my_user(), _konta )
   set_metric( "mat_rpt_specifikacija_artikli", my_user(), _artikli )
   set_metric( "mat_rpt_specifikacija_datum_od", my_user(), _dat_od )
   set_metric( "mat_rpt_specifikacija_datum_do", my_user(), _dat_do )
   set_metric( "mat_rpt_specifikacija_grupe", my_user(), _group )
   set_metric( "mat_rpt_specifikacija_grupe_iz_sifre", my_user(), _group_sifra )
   set_metric( "mat_rpt_specifikacija_selektovane_grupe", my_user(), _sel_groups )
   set_metric( "mat_rpt_specifikacija_samo_vrijednost", my_user(), _vrijednost )
   set_metric( "mat_rpt_specifikacija_sadrzaj_grupe", my_user(), _group_lista )

   RETURN _ret



// -------------------------------------------------
// linija za ogranicavanje na izvjestaju
// -------------------------------------------------
STATIC FUNCTION _get_line( r_format, params )

   LOCAL _line := ""

   _line += Replicate( "-", 4 )
   _line += Space( 1 )
   _line += Replicate( "-", 10 )
   _line += Space( 1 )
   _line += Replicate( "-", 40 )
   _line += Space( 1 )
   _line += Replicate( "-", 3 )

   IF params[ "samo_vrijednost" ] == "N"

      _line += Space( 1 )
      _line += Replicate( "-", Len( PICDEM ) )
      _line += Space( 1 )
      _line += Replicate( "-", Len( PICDEM ) )
      _line += Space( 1 )
      _line += Replicate( "-", Len( PICDEM ) )

   ENDIF

   IF r_format == "1"
      _line += Space( 1 )
      _line += Replicate( "-", Len( PICDEM ) )
      _line += Space( 1 )
      _line += Replicate( "-", Len( PICDEM ) )
      _line += Space( 1 )
      _line += Replicate( "-", Len( PICDEM ) )
   ENDIF

   _line += Space( 1 )
   _line += Replicate( "-", Len( PICDEM ) )
   _line += Space( 1 )
   _line += Replicate( "-", Len( PICDEM ) )
   _line += Space( 1 )
   _line += Replicate( "-", Len( PICDEM ) )

   IF r_format == "1"
      _line += Space( 1 )
      _line += Replicate( "-", Len( PICDEM ) )
      _line += Space( 1 )
      _line += Replicate( "-", Len( PICDEM ) )
      _line += Space( 1 )
      _line += Replicate( "-", Len( PICDEM ) )
   ENDIF

   RETURN _line



// ----------------------------------------------------
// sinteticka specifikacija
// ----------------------------------------------------
FUNCTION mat_sint_specifikacija()

   LOCAL _params := hb_Hash()
   LOCAL _usl_1
   LOCAL _usl_2
   LOCAL _dat_od
   LOCAL _dat_do
   LOCAL _firma
   LOCAL _fmt
   LOCAL _line
   LOCAL _filter := ""
   LOCAL _a_tmp
   LOCAL _samo_vrijednost

   // otvori potrebne tabele
   _o_rpt_tables()

   // daj mi uslove izvjestaja
   IF !_get_vars( @_params )
      my_close_all_dbf()
      RETURN
   ENDIF

   // kreiraj pomocnu tabelu izvjestaja
   _cre_tmp_tbl()

   // otvori tabele izvjestaja
   _o_rpt_tables()

   _usl_1 := Parsiraj( _params[ "konta" ], "IdKonto", "C" )
   _usl_2 := Parsiraj( _params[ "artikli" ], "IdRoba", "C" )
   _dat_od := _params[ "dat_od" ]
   _dat_do := _params[ "dat_do" ]
   _firma := Left( _params[ "firma" ], 2 )
   _fmt := _params[ "format" ]
   _samo_vrijednost := _params[ "samo_vrijednost" ]

   SELECT mat_suban
   // "IdFirma+IdRoba+dtos(DatDok)"
   SET ORDER TO TAG "1"

   // napravi filter...
   _filter := "idfirma == " + dbf_quote( _firma )

   IF _usl_1 != ".t."
      _filter += " .and. " + _usl_1
   ENDIF

   IF _usl_2 != ".t."
      _filter += " .and. " + _usl_2
   ENDIF

   IF !Empty( _dat_od ) .OR. !Empty( _dat_do )
      _filter += " .and. DTOS(datdok) <= " + dbf_quote( DToS( _dat_do ) )
      _filter += " .and. DTOS(datdok) >= " + dbf_quote( DToS( _dat_od ) )
   ENDIF

   SET FILTER to &_filter

   GO TOP

   EOF CRET

   msgO( "Punim pomocnu tabelu izvjestaja..." )

   // napuni pomocnu tabelu podacima
   _fill_rpt_data( _params )

   msgC()

   // daj mi liniju za izvjestaj
   _line := _get_line( _fmt, _params )

   START PRINT CRET

   IF _params[ "po_grupi" ] == "D"
      _show_report_grupe( _params, _line )
   ELSE
      _show_report( _params, _line )
   ENDIF

   FF
   ENDPRINT

   my_close_all_dbf()

   RETURN


// ------------------------------------------------------
// filuje pomocnu tabelu izvjestaja
// ------------------------------------------------------
STATIC FUNCTION _fill_rpt_data( param )

   LOCAL _dug_1, _pot_1, _dug_2, _pot_2
   LOCAL _ulaz_k_1, _izlaz_k_1, _ulaz_k_2, _izlaz_k_2
   LOCAL _saldo_k_1, _saldo_k_2, _saldo_i_1, _saldo_i_2
   LOCAL cIdRoba

   SELECT mat_suban

   DO WHILE !Eof()

      cIdRoba := field->idroba

      // resetuj brojace...
      _dug_1 := 0
      _pot_1 := 0
      _dug_2 := 0
      _pot_2 := 0
      _ulaz_k_1 := 0
      _izlaz_k_1 := 0
      _ulaz_k_2 := 0
      _izlaz_k_2 := 0
      _saldo_k_1 := 0
      _saldo_k_2 := 0
      _saldo_i_1 := 0
      _saldo_i_2 := 0

      DO WHILE !Eof() .AND. cIdRoba = field->idroba

         // saberi ulaze/izlaze
         IF field->u_i = "1"
            _ulaz_k_1 += field->kolicina
         ELSE
            _izlaz_k_1 += field->kolicina
         ENDIF

         // saberi iznose d/p
         IF field->d_p = "1"
            _dug_1 += field->iznos
            _dug_2 += field->iznos2
         ELSE
            _pot_1 += field->iznos
            _pot_2 += field->iznos2
         ENDIF

         SKIP

      ENDDO

      select_o_roba( cIdRoba )

      // da li se grupa odredjuje putem sifre ili iz sifk ?
      IF PARAM[ "grupa_na_osnovu_sifre" ] == "D"
         _roba_gr := PadR( cIdRoba, 2 )
      ELSE
         // ovdje cemo smjestiti grupaciju...
         _roba_gr := IzSifKRoba( "GR1", cIdRoba, .F. )
      ENDIF

      SELECT mat_suban

      _saldo_k_1 := _ulaz_k_1 - _izlaz_k_1
      _saldo_i_1 := _dug_1 - _pot_1
      _saldo_k_2 := _ulaz_k_2 - _izlaz_k_2
      _saldo_i_2 := _dug_2 - _pot_2

      _fill_tmp_tbl( cIdRoba, _roba_gr, roba->naz, roba->jmj, ;
         roba->nc, roba->vpc, roba->mpc, ;
         "", "", "", "", ;
         _ulaz_k_1, _ulaz_k_2, _izlaz_k_1, _izlaz_k_2, ;
         _saldo_k_1, _saldo_k_2, ;
         _dug_1, _dug_2, _pot_1, _pot_2, ;
         _saldo_i_1, _saldo_i_2 )

      SELECT mat_suban

   ENDDO

   RETURN




// ---------------------------------------------
// ispisi izvjestaj
// ---------------------------------------------
STATIC FUNCTION _show_report( params, line )

   LOCAL _mark_pos
   LOCAL _rbr
   LOCAL _uk_dug_1, _uk_dug_2, _uk_pot_1, _uk_pot_2
   LOCAL cIdRoba, _roba_naz, _roba_jmj
   LOCAL _fmt := params[ "format" ]

   ?
   _mark_pos := 0

   // stampaj zaglavlje
   _zaglavlje( params, line )

   SELECT r_export
   SET ORDER TO TAG "1"
   GO TOP

   _rbr := 0
   _uk_dug_1 := 0
   _uk_pot_1 := 0
   _uk_dug_2 := 0
   _uk_pot_2 := 0

   DO WHILE !Eof()

      // provjera novog reda...
      IF PRow() > 63
         FF
      ENDIF

      @ PRow() + 1, 0 SAY ++_rbr PICT '9999'
      @ PRow(), PCol() + 1 SAY field->id_roba
      @ PRow(), PCol() + 1 SAY PadR( field->roba_naz, 40 )
      @ PRow(), PCol() + 1 SAY field->roba_jmj

      IF _fmt == "1"
         @ PRow(), PCol() + 1 SAY field->roba_nc PICT PICDEM
         @ PRow(), PCol() + 1 SAY field->roba_vpc PICT PICDEM
         @ PRow(), PCol() + 1 SAY field->roba_mpc PICT PICDEM
      ENDIF

      @ PRow(), PCol() + 1 SAY field->ulaz_1 PICT PICKOL
      @ PRow(), PCol() + 1 SAY field->izlaz_1 PICT PICKOL
      @ PRow(), PCol() + 1 SAY field->saldo_k_1 PICT PICKOL

      _mark_pos := PCol()

      IF _fmt $ "12"
         @ PRow(), PCol() + 1 SAY field->dug_1 PICT PicDEM
         @ PRow(), PCol() + 1 SAY field->pot_1 PICT PicDEM
         @ PRow(), PCol() + 1 SAY field->saldo_i_1 PICT PicDEM
      ENDIF

      IF _fmt $ "13"
         @ PRow(), PCol() + 1 SAY field->dug_2 PICT PicBHD
         @ PRow(), PCol() + 1 SAY field->pot_2 PICT PicBHD
         @ PRow(), PCol() + 1 SAY field->saldo_i_2 PICT PicBHD
      ENDIF

      _uk_dug_1 += field->dug_1
      _uk_pot_1 += field->pot_1
      _uk_dug_2 += field->dug_2
      _uk_pot_2 += field->pot_2

      SELECT r_export
      SKIP

   ENDDO

   ?  line
   ?  "UKUPNO :"

   @  PRow(), _mark_pos SAY ""

   IF _fmt $ "12"
      @ PRow(), PCol() + 1 SAY _uk_dug_1 PICT PicDEM
      @ PRow(), PCol() + 1 SAY _uk_pot_1 PICT PicDEM
      @ PRow(), PCol() + 1 SAY ( _uk_dug_1 - _uk_pot_1 ) PICT PicDEM
   ENDIF

   IF _fmt $ "13"
      @ PRow(), PCol() + 1 SAY _uk_dug_2 PICT PicBHD
      @ PRow(), PCol() + 1 SAY _uk_pot_2 PICT PicBHD
      @ PRow(), PCol() + 1 SAY ( _uk_dug_2 - _uk_pot_2 ) PICT PicBHD
   ENDIF

   ? line

   RETURN



// ---------------------------------------------
// ispisi izvjestaj po grupama
// ---------------------------------------------
STATIC FUNCTION _show_report_grupe( params, line )

   LOCAL _mark_pos
   LOCAL _rbr
   LOCAL _uk_dug_1, _uk_dug_2, _uk_pot_1, _uk_pot_2
   LOCAL _fmt := params[ "format" ]
   LOCAL _grupa
   LOCAL _u_ulaz, _u_izlaz, _u_sld_k, _u_dug_1, _u_dug_2, _u_pot_1, _u_pot_2
   LOCAL _u_sld_i_1, _u_sld_i_2

   ?
   _mark_pos := 0

   // stampaj zaglavlje
   _zaglavlje( params, line )

   SELECT r_export
   SET ORDER TO TAG "2"
   GO TOP

   _rbr := 0

   _uk_dug_1 := 0
   _uk_pot_1 := 0
   _uk_dug_2 := 0
   _uk_pot_2 := 0

   DO WHILE !Eof()

      // provjera novog reda...
      IF PRow() > 63
         FF
      ENDIF

      _grupa := field->grupa

      // provjeri da li postoji uslov za grupacije...
      IF !Empty( params[ "grupe" ] )
         IF ! ( AllTrim( _grupa ) $ params[ "grupe" ] )
            SELECT r_export
            SKIP
            LOOP
         ENDIF
      ENDIF

      _u_ulaz := 0
      _u_izlaz := 0
      _u_sld_k := 0
      _u_dug_1 := 0
      _u_dug_2 := 0
      _u_pot_1 := 0
      _u_pot_2 := 0
      _u_sld_i_1 := 0
      _u_sld_i_2 := 0
      _gr_count := 0

      // ako je listanje sadrzaja grupe
      IF params[ "listaj_sadrzaj_grupe" ] == "D"
         // postavi zaglavlje za grupu...
         @ PRow() + 1, 0 SAY "Sadrzaj grupe " + _grupa
         ? line
      ENDIF

      DO WHILE !Eof() .AND. field->grupa == _grupa

         IF !Empty( params[ "grupe" ] )
            IF ! ( AllTrim( _grupa ) $ params[ "grupe" ] )
               SELECT r_export
               SKIP
               LOOP
            ENDIF
         ENDIF

         IF params[ "listaj_sadrzaj_grupe" ] == "D"
            // ispisi za svaku grupu...

            @ PRow() + 1, 0 SAY ++_gr_count PICT '9999'
            @ PRow(), PCol() + 1 SAY PadR( AllTrim( field->id_roba ) + " - " + AllTrim( field->roba_naz ) + " (" + field->roba_jmj + ")", 50 )

            IF params[ "samo_vrijednost" ] == "N"

               @ PRow(), PCol() + 1 SAY field->ulaz_1 PICT picKol
               @ PRow(), PCol() + 1 SAY field->izlaz_1 PICT picKol
               @ PRow(), PCol() + 1 SAY field->saldo_k_1 PICT picKol

            ENDIF

            IF _fmt $ "12"
               @ PRow(), PCol() + 1 SAY field->dug_1 PICT PicDEM
               @ PRow(), PCol() + 1 SAY field->pot_1 PICT PicDEM
               @ PRow(), PCol() + 1 SAY field->saldo_i_1 PICT PicDEM
            ENDIF

            IF _fmt $ "13"
               @ PRow(), PCol() + 1 SAY field->dug_2 PICT PicBHD
               @ PRow(), PCol() + 1 SAY field->pot_2 PICT PicBHD
               @ PRow(), PCol() + 1 SAY field->saldo_i_2 PICT PicBHD
            ENDIF

         ENDIF

         // saberi totale...
         _u_ulaz += field->ulaz_1
         _u_izlaz += field->izlaz_1
         _u_sld_k += field->saldo_k_1

         _u_dug_1 += field->dug_1
         _u_dug_2 += field->dug_2
         _u_pot_1 += field->pot_1
         _u_pot_2 += field->pot_2

         _u_sld_i_1 += field->saldo_i_1
         _u_sld_i_2 += field->saldo_i_2

         SKIP

      ENDDO

      // liniju postavi ako postoji sadrzaj grupe...
      IF params[ "listaj_sadrzaj_grupe" ] == "D"
         ? line
      ENDIF

      @ PRow() + 1, 0 SAY ++_rbr PICT '9999'
      @ PRow(), PCol() + 1 SAY PadR( "Ukupno grupa: " + _grupa, 55 )

      IF params[ "samo_vrijednost" ] == "N"

         @ PRow(), PCol() + 1 SAY _u_ulaz PICT picKol
         @ PRow(), PCol() + 1 SAY _u_izlaz PICT picKol
         @ PRow(), PCol() + 1 SAY _u_sld_k PICT picKol

      ENDIF

      _mark_pos := PCol()

      IF _fmt $ "12"
         @ PRow(), PCol() + 1 SAY _u_dug_1 PICT PicDEM
         @ PRow(), PCol() + 1 SAY _u_pot_1 PICT PicDEM
         @ PRow(), PCol() + 1 SAY _u_sld_i_1 PICT PicDEM
      ENDIF

      IF _fmt $ "13"
         @ PRow(), PCol() + 1 SAY _u_dug_2 PICT PicBHD
         @ PRow(), PCol() + 1 SAY _u_pot_2 PICT PicBHD
         @ PRow(), PCol() + 1 SAY _u_sld_i_2 PICT PicBHD
      ENDIF

      // liniju postavi ako postoji sadrzaj grupe...
      IF params[ "listaj_sadrzaj_grupe" ] == "D"
         ? line
      ENDIF

      _uk_dug_1 += _u_dug_1
      _uk_pot_1 += _u_pot_1
      _uk_dug_2 += _u_dug_2
      _uk_pot_2 += _u_pot_2

      SELECT r_export
      SKIP

   ENDDO

   ?  line
   ?  "UKUPNO (sve grupe) :"

   @  PRow(), _mark_pos SAY ""

   IF _fmt $ "12"
      @ PRow(), PCol() + 1 SAY _uk_dug_1 PICT PicDEM
      @ PRow(), PCol() + 1 SAY _uk_pot_1 PICT PicDEM
      @ PRow(), PCol() + 1 SAY ( _uk_dug_1 - _uk_pot_1 ) PICT PicDEM
   ENDIF

   IF _fmt $ "13"
      @ PRow(), PCol() + 1 SAY _uk_dug_2 PICT PicBHD
      @ PRow(), PCol() + 1 SAY _uk_pot_2 PICT PicBHD
      @ PRow(), PCol() + 1 SAY ( _uk_dug_2 - _uk_pot_2 ) PICT PicBHD
   ENDIF

   ? line

   RETURN



// ------------------------------------------------
// filovanje pomocne tabele
// ------------------------------------------------
STATIC FUNCTION _fill_tmp_tbl( id_roba, grupa, roba_naz, roba_jmj, ;
      roba_nc, roba_vpc, roba_mpc, ;
      id_konto, konto_naz, id_partner, partn_naz, ;
      ulaz_1, ulaz_2, izlaz_1, izlaz_2, ;
      saldo_k_1, saldo_k_2, ;
      dug_1, dug_2, pot_1, pot_2, ;
      saldo_i_1, saldo_i_2 )

   LOCAL _arr := Select()

   SELECT ( F_R_EXP )
   IF !Used()
      o_r_export()
   ENDIF

   APPEND BLANK
   REPLACE field->id_roba WITH id_roba
   REPLACE field->grupa WITH grupa
   REPLACE field->roba_naz WITH roba_naz
   REPLACE field->roba_jmj WITH roba_jmj
   REPLACE field->roba_nc WITH roba_nc
   REPLACE field->roba_vpc WITH roba_vpc
   REPLACE field->roba_mpc WITH roba_mpc
   REPLACE field->id_konto WITH id_konto
   REPLACE field->konto_naz WITH konto_naz
   REPLACE field->id_partner WITH id_partner
   REPLACE field->partn_naz WITH partn_naz
   REPLACE field->ulaz_1 WITH ulaz_1
   REPLACE field->ulaz_2 WITH ulaz_2
   REPLACE field->izlaz_1 WITH izlaz_1
   REPLACE field->izlaz_2 WITH izlaz_2
   REPLACE field->saldo_k_1 WITH saldo_k_1
   REPLACE field->saldo_k_2 WITH saldo_k_2
   REPLACE field->dug_1 WITH dug_1
   REPLACE field->dug_2 WITH dug_2
   REPLACE field->pot_1 WITH pot_1
   REPLACE field->pot_2 WITH pot_2
   REPLACE field->saldo_i_1 WITH saldo_i_1
   REPLACE field->saldo_i_2 WITH saldo_i_2

   SELECT ( _arr )

   RETURN


// -------------------------------------------------------
// vraca matricu pomocne tabele za izvjestaj
// -------------------------------------------------------
STATIC FUNCTION _cre_tmp_tbl()

   LOCAL _dbf := {}

   AAdd( _dbf, { "id_roba",  "C",  10, 0 } )
   AAdd( _dbf, { "grupa",    "C",  20, 0 } )
   AAdd( _dbf, { "roba_naz", "C", 100, 0 } )
   AAdd( _dbf, { "roba_jmj", "C",   3, 0 } )
   AAdd( _dbf, { "roba_nc",  "N", 12, 3 } )
   AAdd( _dbf, { "roba_vpc", "N", 12, 3 } )
   AAdd( _dbf, { "roba_mpc", "N", 12, 3 } )
   AAdd( _dbf, { "id_konto", "C", 7, 0 } )
   AAdd( _dbf, { "konto_naz", "C", 50, 0 } )
   AAdd( _dbf, { "id_partner", "C", 6, 0 } )
   AAdd( _dbf, { "partn_naz", "C", 100, 0 } )
   AAdd( _dbf, { "ulaz_1", "N", 15, 3 } )
   AAdd( _dbf, { "ulaz_2", "N", 15, 3 } )
   AAdd( _dbf, { "izlaz_1", "N", 15, 3 } )
   AAdd( _dbf, { "izlaz_2", "N", 15, 3 } )
   AAdd( _dbf, { "dug_1", "N", 15, 3 } )
   AAdd( _dbf, { "dug_2", "N", 15, 3 } )
   AAdd( _dbf, { "pot_1", "N", 15, 3 } )
   AAdd( _dbf, { "pot_2", "N", 15, 3 } )
   AAdd( _dbf, { "saldo_k_1", "N", 15, 3 } )
   AAdd( _dbf, { "saldo_k_2", "N", 15, 3 } )
   AAdd( _dbf, { "saldo_i_1", "N", 15, 3 } )
   AAdd( _dbf, { "saldo_i_2", "N", 15, 3 } )

   // kreiraj tabelu
   xlsx_export_init( _dbf )

   o_r_export()
   // indeksiraj...
   INDEX ON id_roba TAG "1"
   INDEX ON grupa TAG "2"

   RETURN




// ------------------------------------------------------------
// zaglavlje izvestaja...
// ------------------------------------------------------------
STATIC FUNCTION _zaglavlje( param, line )

   LOCAL _r_line_1 := ""
   LOCAL _r_line_2 := ""
   LOCAL _r_line_3 := ""

   P_COND2
   ?

   @ PRow(), 0 SAY "MAT.P: SPECIFIKACIJA ROBE (U "

   IF PARAM[ "format" ] == "1"
      ?? ValPomocna() + "/" + valuta_domaca_skraceni_naziv() + ") "
   ELSEIF PARAM[ "format" ] == "2"
      ?? ValPomocna() + ") "
   ELSE
      ?? valuta_domaca_skraceni_naziv() + ") "
   ENDIF

   IF !Empty( PARAM[ "dat_od" ] ) .OR. !Empty( PARAM[ "dat_do" ] )
      ?? "ZA PERIOD OD", PARAM[ "dat_od" ], "-", PARAM[ "dat_do" ]
   ENDIF

   ?? "      NA DAN:"
   @ PRow(), PCol() + 1 SAY Date()

   @ PRow() + 1, 0 SAY "FIRMA:"
   @ PRow(), PCol() + 1 SAY PARAM[ "firma" ]

   SELECT partn
   HSEEK PARAM[ "firma" ]

   @ PRow(), PCol() + 1 SAY field->naz
   @ PRow(), PCol() + 1 SAY field->naz2

   ? "Kriterij za " + KonSeks( "konta" ) + ":", Trim( PARAM[ "konta" ] )

   ? line

   // definisi nazive kolona
   _r_line_1 += "*R. "
   _r_line_2 += "*Br."
   _r_line_3 += "*   "

   IF PARAM[ "po_grupi" ] == "N"

      _r_line_1 += "*  SIFRA   "
      _r_line_2 += "*          "
      _r_line_3 += "*          "

      _r_line_1 += "*       N A Z I V                        "
      _r_line_2 += "*                                        "
      _r_line_3 += "*                                        "

   ELSE

      _r_line_1 += "*  GRUPACIJA                                        "
      _r_line_2 += "*                                                   "
      _r_line_3 += "*                                                   "

   ENDIF

   _r_line_1 += "*J. "
   _r_line_2 += "*MJ."
   _r_line_3 += "*   "

   IF PARAM[ "samo_vrijednost" ] == "N"

      _r_line_1 += "*" + PadC( "K O L I C I N A", Len( PICKOL ) * 3 + 2 )
      _r_line_2 += Replicate( "-", Len( PICKOL ) * 3 + 2 )
      _r_line_3 += "*" + PadC( "ULAZ", Len( PICKOL ) )
      _r_line_3 += "*" + PadC( "IZLAZ", Len( PICKOL ) )
      _r_line_3 += "*" + PadC( "STANJE", Len( PICKOL ) )

   ENDIF

   _r_line_1 += "*" + PadC( "V R I J E D N O S T", Len( PICDEM ) * 3 + 2 ) + "*"
   _r_line_2 += Replicate( "-", Len( PICDEM ) * 3 + 2 )
   _r_line_3 += "*" + PadC( "DUGUJE", Len( PICDEM ) )
   _r_line_3 += "*" + PadC( "POTRAZUJE", Len( PICDEM ) )
   _r_line_3 += "*" + PadC( "SALDO", Len( PICDEM ) ) + "*"

   ? _r_line_1
   ? _r_line_2
   ? _r_line_3

   ?  line

   RETURN
