/*
 * This file is part of the bring.out knowhow ERP, a free and open source
 * Enterprise Resource Planning software suite,
 * Copyright (c) 1994-2024 by bring.out doo Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including FMK specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_knowhow.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */

#include "f18.ch"

STATIC LEN_KOLICINA := 12
STATIC LEN_CIJENA := 10
STATIC LEN_VRIJEDNOST := 12

STATIC PIC_KOLICINA := ""
STATIC PIC_VRIJEDNOST := ""
STATIC PIC_CIJENA := ""

STATIC __default_odt_vp_template := ""
STATIC __default_odt_mp_template := ""
STATIC __default_odt_kol_template := ""
STATIC _temporary := .F.
STATIC __auto_odt := ""


FUNCTION fakt_stampa_dok_odt( cIdf, cIdVd, cBrDok )

   LOCAL _template := ""
   LOCAL cTemplatesDir := f18_template_location()
   LOCAL _xml_file := my_home() + "data.xml"
   LOCAL _file_pdf := ""
   LOCAL _ext_pdf := fetch_metric( "fakt_dokument_pdf_lokacija", my_user(), "" )
   LOCAL _ext_path
   LOCAL _gen_pdf := .F.
   LOCAL _t_path
   LOCAL _racuni := {}
   LOCAL __tip_dok

   __auto_odt_template() // setuj static var

   IF ( cIdF <> NIL )
      _file_pdf := "fakt_" + cIdF + "_" + cIdVd + "_" + AllTrim( cBrDok ) + ".pdf"
      __tip_dok := cIdVd
   ELSE
      _file_pdf := "fakt_priprema.pdf"
      // ali moramo znati koji je dokument u pitanju !
      SELECT fakt_pripr
      SET ORDER TO TAG "1"
      GO TOP
      __tip_dok := field->idtipdok

   ENDIF

   IF !Empty( cTemplatesDir )
      _t_path := AllTrim( cTemplatesDir )
   ENDIF

   // treba li generisati pdf fajl
   IF !Empty( AllTrim( _ext_pdf ) )
      IF Pitanje(, "Generisati PDF dokument ?", "N" ) == "D"
         _gen_pdf := .T.
      ENDIF
   ENDIF

   MsgO( "formiraju se stavke odt računa..." )

   AAdd( _racuni, { cIdF, cIdVd, cBrDok  } )
   _fakt_dok_gen_xml( _xml_file, _racuni )

   MsgC()

   fakt_odaberi_template( @_template, __tip_dok )

   my_close_all_dbf()

   IF generisi_odt_iz_xml( _template, _xml_file )

      IF _gen_pdf .AND. !Empty( _file_pdf )
         _ext_path := AllTrim( _ext_pdf )
         IF Left( AllTrim( _ext_pdf ), 4 ) == "HOME"
            _ext_path := my_home()
         ENDIF
         konvertuj_odt_u_pdf( NIL, _ext_path + _file_pdf )

      ENDIF
      prikazi_odt()

   ENDIF

   RETURN .T.



STATIC FUNCTION fakt_odaberi_template( cTemplate, tip_dok )

   LOCAL _ok := .T.
   LOCAL _mp_template := "f-stdm.odt"
   LOCAL _vp_template := "f-std.odt"
   LOCAL _kol_template := "f-stdk.odt"
   LOCAL _auto_odabir := __auto_odt == "D"
   LOCAL _f_path := f18_template_location()
   LOCAL _f_filter := "f-*.odt"

   download_template( "f-std.odt", "a2faecede3dc1477161e848e8a288fb4359c767b29fac1b535d2082585a512b1" )
   download_template( "f-stdk.odt", "e4158099b8f42b10f9afc1d1fa7d622a56f2f05bb814776356e64beff00bb9c1" )
   download_template( "f-stdm.odt", "7661536736d43f3c678c3c11612e62952ea1e9c27c6dba953845b9349a105079" )

   cTemplate := ""

   // odabir cTemplate fajla na osnovu tipa dokumenta
   DO CASE

   CASE tip_dok $ "12#13#21#22#23#26"

      // tipovi dokumenata gdje trebaju samo kolicine

      IF !Empty( __default_odt_kol_template )
         cTemplate := __default_odt_kol_template
      ENDIF

      IF Empty( cTemplate ) .AND. _auto_odabir
         cTemplate := _kol_template
      ENDIF

   CASE  tip_dok $ "11#"

      // maloprodajni racuni i ostalo...

      IF !Empty( __default_odt_mp_template )
         cTemplate := __default_odt_mp_template
      ENDIF

      IF Empty( cTemplate ) .AND. _auto_odabir
         cTemplate := _mp_template
      ENDIF

   OTHERWISE

      // ostalo cemo smatrati veleprodajom

      IF !Empty( __default_odt_vp_template )
         cTemplate := __default_odt_vp_template
      ENDIF

      IF Empty( cTemplate ) .AND. _auto_odabir
         cTemplate := _vp_template
      ENDIF

   ENDCASE

   IF Empty( cTemplate )
      _ok := get_file_list_array( _f_path, _f_filter, @cTemplate, .T. ) == 1
   ENDIF

   RETURN _ok



STATIC FUNCTION _grupno_params( params )

   LOCAL _ok := .F.
   LOCAL _box_x := 15
   LOCAL _box_y := 70
   LOCAL _x := 1
   LOCAL _id_firma, _id_tip_dok, _brojevi
   LOCAL _datum_od, _datum_do
   LOCAL _partneri, cIdRoba, _na_lokaciju
   LOCAL _tip_gen := "1"
   LOCAL _gen_pdf := "N"

   _id_firma := fetch_metric( "export_odt_grupno_firma", my_user(), self_organizacija_id() )
   _id_tip_dok := fetch_metric( "export_odt_grupno_tip_dok", my_user(), "10" )
   _datum_od := fetch_metric( "export_odt_grupno_datum_od", my_user(), Date() )
   _datum_do := fetch_metric( "export_odt_grupno_datum_do", my_user(), Date() )
   _brojevi := PadR( fetch_metric( "export_odt_grupno_brojevi", my_user(), "" ), 500 )
   _partneri := PadR( fetch_metric( "export_odt_grupno_partneri", my_user(), "" ), 500 )
   cIdRoba := PadR( fetch_metric( "export_odt_grupno_roba", my_user(), "" ), 500 )
   _na_lokaciju := PadR( fetch_metric( "export_odt_grupno_exp_lokacija", my_user(), "" ), 500 )

   // uslov za stampanje
   Box(, _box_x, _box_y )

   @ box_x_koord() + _x, box_y_koord() + 2 SAY "*** Stampa ODT dokumenata po zadanom uslovu:"

   ++_x
   ++_x

   @ box_x_koord() + _x, box_y_koord() + 2 SAY "Radna jedinica / vrsta:" GET _id_firma VALID !Empty( _id_firma )
   @ box_x_koord() + _x, Col() + 1 SAY "-" GET _id_tip_dok VALID !Empty( _id_tip_dok )

   ++_x

   @ box_x_koord() + _x, box_y_koord() + 2 SAY "Za datum od:" GET _datum_od
   @ box_x_koord() + _x, Col() + 1 SAY "do:" GET _datum_do

   ++_x
   ++_x

   @ box_x_koord() + _x, box_y_koord() + 2 SAY "Brojevi dokumenata:" GET _brojevi PICT "@S45"

   ++_x

   @ box_x_koord() + _x, box_y_koord() + 2 SAY "Obuhvati artikle:" GET cIdRoba PICT "@S45"

   ++_x

   @ box_x_koord() + _x, box_y_koord() + 2 SAY "Obuhvati partnere:" GET _partneri PICT "@S45"

   ++_x
   ++_x

   @ box_x_koord() + _x, box_y_koord() + 2 SAY "Generisati grupno/jedan po jedan (1/2) ?" GET _tip_gen VALID _tip_gen $ "12"

   ++_x

   @ box_x_koord() + _x, box_y_koord() + 2 SAY "Formirati PDF dokument (D/N) ?" GET _gen_pdf VALID _gen_pdf $ "DN"

   ++_x
   ++_x

   @ box_x_koord() + _x, box_y_koord() + 2 SAY "Prebaci na lokaciju:" GET _na_lokaciju PICT "@S40"

   READ

   BoxC()

   IF LastKey() == K_ESC
      RETURN _ok
   ENDIF

   // sql params
   set_metric( "export_odt_grupno_firma", my_user(), _id_firma )
   set_metric( "export_odt_grupno_tip_dok", my_user(), _id_tip_dok )
   set_metric( "export_odt_grupno_datum_od", my_user(), _datum_od )
   set_metric( "export_odt_grupno_datum_do", my_user(), _datum_do )
   set_metric( "export_odt_grupno_brojevi", my_user(), AllTrim( _brojevi ) )
   set_metric( "export_odt_grupno_partneri", my_user(), AllTrim( _partneri ) )
   set_metric( "export_odt_grupno_roba", my_user(), AllTrim( cIdRoba ) )
   set_metric( "export_odt_grupno_exp_lokacija", my_user(), AllTrim( _na_lokaciju ) )

   // params
   params := hb_Hash()
   params[ "datum_od" ] := _datum_od
   params[ "datum_do" ] := _datum_do
   params[ "id_firma" ] := _id_firma
   params[ "id_tip_dok" ] := _id_tip_dok
   params[ "brojevi" ] := _brojevi
   params[ "roba" ] := cIdRoba
   params[ "partneri" ] := _partneri
   params[ "tip_gen" ] := _tip_gen
   params[ "gen_pdf" ] := _gen_pdf
   params[ "na_lokaciju" ] := _na_lokaciju

   _ok := .T.

   RETURN _ok




// ----------------------------------------------------------
// generisanje upita za matricu racuna za export
// ----------------------------------------------------------
STATIC FUNCTION _grupno_sql_gen( racuni, params )

   LOCAL _ok := .F.
   LOCAL cQuery, _table, _where
   LOCAL oRow
   LOCAL _scan

   // idfirma
   _where := "WHERE f.idfirma = " + sql_quote( params[ "id_firma" ] )
   // idtipdok
   _where += " AND f.idtipdok = " + sql_quote( params[ "id_tip_dok" ] )
   // datdok
   IF params[ "datum_od" ] <> CToD( "" )
      _where += " AND " + _sql_date_parse( "f.datdok", params[ "datum_od" ], params[ "datum_do" ] )
   ENDIF
   // roba
   IF !Empty( params[ "roba" ] )
      _where += " AND " + _sql_cond_parse( "f.idroba", AllTrim( params[ "roba" ] ) + " " )
   ENDIF
   // brojevi
   IF !Empty( params[ "brojevi" ] )
      _where += " AND " + _sql_cond_parse( "f.brdok", AllTrim( params[ "brojevi" ] ) )
   ENDIF
   // partneri
   IF !Empty( params[ "partneri" ] )
      _where += " AND " + _sql_cond_parse( "f.idpartner", AllTrim( params[ "partneri" ] ) + " " )
   ENDIF

   // glavni upit !
   cQuery := "SELECT f.idfirma, f.idtipdok, f.brdok, MAX( f.rbr ) " + ;
      "FROM " + f18_sql_schema( "fakt_fakt" ) + " f "

   cQuery += _where

   cQuery += " GROUP BY f.idfirma, f.idtipdok, f.brdok "
   cQuery += " ORDER BY f.idfirma, f.idtipdok, f.brdok "

   _table := run_sql_query( cQuery )
   IF sql_error_in_query( _table )
      RETURN NIL
   ENDIF

   _table:GoTo( 1 )

   racuni := {}

   DO WHILE !_table:Eof()

      oRow := _table:GetRow()

      _scan := AScan( racuni, {| val | val[ 1 ] + val[ 2 ] + val[ 3 ] == oRow:FieldGet( 1 ) + oRow:FieldGet( 2 ) + oRow:FieldGet( 3 ) } )

      IF _scan == 0
         AAdd( racuni, { oRow:FieldGet( 1 ), oRow:FieldGet( 2 ), oRow:FieldGet( 3 ) } )
      ENDIF

      _table:Skip()

   ENDDO

   _ok := .T.

   RETURN _ok



/*
stampa dokumenta u odt formatu, grupne fakture
*/

FUNCTION stdokodt_grupno()

   LOCAL _t_path := my_home()
   LOCAL _filter := "f-*.odt"
   LOCAL _template := ""
   LOCAL _ext_pdf := fetch_metric( "fakt_dokument_pdf_lokacija", my_user(), "" )
   LOCAL _file_out := ""
   LOCAL cTemplatesDir := f18_template_location()
   LOCAL _xml_file := my_home() + "data.xml"
   LOCAL _ext_path
   LOCAL _racuni := {}
   LOCAL _params := hb_Hash()
   LOCAL _ctrl_data := {}
   LOCAL _tip_gen
   LOCAL _gen_pdf, nI
   LOCAL _gen_jedan := {}
   LOCAL _na_lokaciju

   __auto_odt_template()

   AAdd( _ctrl_data, { 0, 0, 0, 0, 0, 0, 0, 0, 0 } )

   IF !_grupno_params( @_params )
      RETURN .F.
   ENDIF

   IF !_grupno_sql_gen( @_racuni, _params )
      RETURN .F.
   ENDIF

   IF Len( _racuni ) == 0
      MsgBeep( "Nema podataka za export !" )
      RETURN .F.
   ENDIF

   _tip_gen := _params[ "tip_gen" ]
   _gen_pdf := _params[ "gen_pdf" ]
   _na_lokaciju := _params[ "na_lokaciju" ]

   DO CASE

   CASE _tip_gen == "1"

      _fakt_dok_gen_xml( _xml_file, _racuni, @_ctrl_data )

      IF !Empty( cTemplatesDir )
         _t_path := AllTrim( cTemplatesDir )
      ENDIF

      IF get_file_list_array( _t_path, _filter, @_template, .T. ) == 0
         RETURN .F.
      ENDIF

      my_close_all_dbf()

      IF generisi_odt_iz_xml( _template, _xml_file, NIL, .T. )

         _file_out := "fakt_" + DToS( _params[ "datum_od" ] ) + "_" + DToS( _params[ "datum_do" ] )

         IF !Empty( _na_lokaciju )
            f18_odt_copy( NIL, AllTrim( _na_lokaciju ) + _file_out + ".odt" )
         ENDIF

         IF _params[ "gen_pdf" ] == "D"
            konvertuj_odt_u_pdf( NIL, AllTrim( _ext_pdf ) + _file_out + ".pdf" )
         ENDIF

         prikazi_odt()

      ENDIF

   CASE _tip_gen == "2"

      FOR nI := 1 TO Len( _racuni )

         _gen_jedan := {}
         AAdd( _gen_jedan, { _racuni[ nI, 1 ], _racuni[ nI, 2 ], _racuni[ nI, 3 ] } )

         _fakt_dok_gen_xml( _xml_file, _gen_jedan, @_ctrl_data )

         IF !Empty( cTemplatesDir )
            _t_path := AllTrim( cTemplatesDir )
         ENDIF

         IF __auto_odt == "D"
            IF _racuni[ nI, 2 ] $ "12#13"
               _template := "f-stdk.odt"
            ELSE
               _template := "f-std.odt"
            ENDIF
         ELSE
            IF Empty( _template )
               IF get_file_list_array( _t_path, _filter, @_template, .T. ) == 0
                  RETURN
               ENDIF
            ENDIF
         ENDIF

         my_close_all_dbf()

         IF generisi_odt_iz_xml( _template, _xml_file, NIL, .T. )

            _file_out := "fakt_" + _racuni[ nI, 1 ] + "_" + _racuni[ nI, 2 ] + "_" + ;
               AllTrim( _racuni[ nI, 3 ] )

            IF !Empty( _na_lokaciju )
               f18_odt_copy( NIL, AllTrim( _na_lokaciju ) + _file_out + ".odt" )
            ENDIF

            IF _params[ "gen_pdf" ] == "D"
               konvertuj_odt_u_pdf( NIL, AllTrim( _ext_pdf ) + _file_out + ".pdf" )
            ENDIF

         ENDIF

      NEXT

   ENDCASE

   RETURN



// ------------------------------------------------
// upisi zaglavlje u xml fajl
// ------------------------------------------------
STATIC FUNCTION __upisi_zaglavlje()

   LOCAL _id_broj, cTmp

   // podaci zaglavlja
   cTmp := AllTrim( get_dtxt_opis( "I01" ) )
   xml_node( "fnaz", to_xml_encoding( cTmp ) )

   cTmp := AllTrim( get_dtxt_opis( "I02" ) )
   xml_node( "fadr", to_xml_encoding( cTmp ) )

   _id_broj := AllTrim( get_dtxt_opis( "I03" ) )
   xml_node( "fid", _id_broj )

   IF Len( _id_broj ) == 12
      _id_broj := "4" + _id_broj
      xml_node( "fidp", _id_broj )
   ELSE
      xml_node( "fidp", _id_broj )
   ENDIF

   xml_node( "ftel", to_xml_encoding( AllTrim( get_dtxt_opis( "I10" ) ) ) )
   xml_node( "feml", to_xml_encoding( AllTrim( get_dtxt_opis( "I11" ) ) ) )
   xml_node( "fbnk", to_xml_encoding( AllTrim( get_dtxt_opis( "I09" ) ) ) )

   cTmp := AllTrim( get_dtxt_opis( "I12" ) )
   xml_node( "fdt1", to_xml_encoding( cTmp ) )

   cTmp := AllTrim( get_dtxt_opis( "I13" ) )
   xml_node( "fdt2", to_xml_encoding( cTmp ) )

   cTmp := AllTrim( get_dtxt_opis( "I14" ) )
   xml_node( "fdt3", to_xml_encoding( cTmp ) )

   RETURN .T.


// -------------------------------------------------------
// generisi xml sa podacima
// a_racuni - lista racuna koji treba da se generisu
// -------------------------------------------------------
STATIC FUNCTION _fakt_dok_gen_xml( xml_file, a_racuni, ctrl_data )

   LOCAL i
   LOCAL cTmpTxt := ""
   LOCAL _id_broj
   LOCAL _n
   LOCAL _din_dem

   IF ctrl_data == NIL
      ctrl_data := {}
      AAdd( ctrl_data, { 0, 0, 0, 0, 0, 0, 0, 0, 0 } )
   ENDIF

   PIC_KOLICINA := PadL( AllTrim( Right( fakt_pic_kolicina(), LEN_KOLICINA ) ), LEN_KOLICINA, "9" )
   PIC_VRIJEDNOST := PadL( AllTrim( Right( fakt_pic_iznos(), LEN_VRIJEDNOST ) ), LEN_VRIJEDNOST, "9" )
   PIC_CIJENA := PadL( AllTrim( Right( fakt_pic_cijena(), LEN_CIJENA ) ), LEN_CIJENA, "9" )

   // DRN tabela
   // brdok, datdok, datval, datisp, vrijeme, zaokr, ukbezpdv, ukpopust
   // ukpoptp, ukbpdvpop, ukpdv, ukupno, ukkol, csumrn

   create_xml( xml_file )

   xml_head()
   xml_subnode( "invoice", .F. )

   my_use_refresh_stop()


   FOR _n := 1 TO Len( a_racuni )

      // napuni pomocnu tabelu na osnovu fakture
      // posljednji parametar .t. odredjuje da se samo napune rn i drn tabele
      fakt_stdok_pdv( a_racuni[ _n, 1 ], a_racuni[ _n, 2 ], a_racuni[ _n, 3 ], .T. )


      IF Select( "RN" ) == 0  .OR. Select( "DRN" ) == 0 // da je fakt_stdok_pdv napunio rn.dbf, drn.dbf
         error_bar( "fa_bug", log_stack( 1 ) )
         LOOP
      ENDIF

      IF _n == 1 // zaglavlje ide samo jednom
         __upisi_zaglavlje()
      ENDIF

      // invoice_no
      xml_subnode( "invoice_no", .F. )

      _din_dem := AllTrim( get_dtxt_opis( "D07" ) )

      SELECT RN
      GO TOP
      _pdv_stopa := field->ppdv

      SELECT drn
      GO TOP

      // neki totali...
      xml_node( "u_zaokr", show_number( field->zaokr, PIC_VRIJEDNOST ) )
      xml_node( "u_kol", show_number( field->ukkol, PIC_KOLICINA ) )

      // TOTALI:
      // ------------------------------------
      xml_subnode( "total", .F. )

      // ukupno bez pdv
      xml_subnode( "item", .F. )
      xml_node( "bold", "0" )
      xml_node( "naz", to_xml_encoding( "Ukupno bez PDV" ) )
      xml_node( "iznos", show_number( field->ukbezpdv, PIC_VRIJEDNOST ) )
      xml_subnode( "item", .T. )

      IF Round( field->ukpopust, 2 ) <> 0
         // ukupno popust
         xml_subnode( "item", .F. )
         xml_node( "bold", "0" )
         xml_node( "naz", to_xml_encoding( "Ukupno popust" ) )
         xml_node( "iznos", show_number( field->ukpopust, PIC_VRIJEDNOST ) )
         xml_subnode( "item", .T. )

         // ukupno bez pdv - popust
         xml_subnode( "item", .F. )
         xml_node( "bold", "0" )
         xml_node( "naz", to_xml_encoding( "Ukupno bez PDV - popust" ) )
         xml_node( "iznos", show_number( field->ukbpdvpop, PIC_VRIJEDNOST ) )
         xml_subnode( "item", .T. )
      ENDIF

      // pdv
      xml_subnode( "item", .F. )
      xml_node( "bold", "0" )
      xml_node( "naz", to_xml_encoding( "PDV " + AllTrim( Str( _pdv_stopa, 12, 0 ) ) + "%" ) )
      xml_node( "iznos", show_number( field->ukpdv, PIC_VRIJEDNOST ) )
      xml_subnode( "item", .T. )

      // ukupno sa pdv
      xml_subnode( "item", .F. )
      xml_node( "bold", "1" )
      xml_node( "naz", to_xml_encoding( "Ukupno sa PDV (" + AllTrim( _din_dem ) + ")" ) )
      xml_node( "iznos", show_number( field->ukupno, PIC_VRIJEDNOST ) )
      xml_subnode( "item", .T. )

      // popust na teret prodavca, ako ga ima !

      IF Round( field->ukpoptp, 2 ) <> 0

         // Popust na teret prodavca
         xml_subnode( "item", .F. )
         xml_node( "bold", "0" )
         xml_node( "naz", to_xml_encoding( "Popust na t.p." ) )
         xml_node( "iznos", show_number( field->ukpoptp, PIC_VRIJEDNOST ) )
         xml_subnode( "item", .T. )

         // Ukupno - pop.na teret prodavca
         xml_subnode( "item", .F. )
         xml_node( "bold", "1" )
         xml_node( "naz", to_xml_encoding( "UKUPNO - popust na t.p." ) )
         xml_node( "iznos", show_number( field->ukupno - field->ukpoptp, PIC_VRIJEDNOST ) )
         xml_subnode( "item", .T. )

      ENDIF

      xml_subnode( "total", .T. )

      // da li je faktura sa popustom na teret prodavaca ili nije !
      IF Round( field->ukpoptp, 2 ) <> 0
         xml_node( "poptp", "1" )
      ELSE
         xml_node( "poptp", "0" )
      ENDIF

      // dodaj u kontrolnu matricu podatke
      ctrl_data[ 1, 1 ] := ctrl_data[ 1, 1 ] + field->ukbezpdv
      ctrl_data[ 1, 2 ] := ctrl_data[ 1, 2 ] + field->ukpopust
      ctrl_data[ 1, 3 ] := ctrl_data[ 1, 3 ] + field->ukpoptp
      ctrl_data[ 1, 4 ] := ctrl_data[ 1, 4 ] + field->ukbpdvpop
      ctrl_data[ 1, 5 ] := ctrl_data[ 1, 5 ] + field->ukpdv
      ctrl_data[ 1, 6 ] := ctrl_data[ 1, 6 ] + field->ukkol
      ctrl_data[ 1, 7 ] := ctrl_data[ 1, 7 ] + field->ukupno
      ctrl_data[ 1, 8 ] := ctrl_data[ 1, 8 ] + field->zaokr
      ctrl_data[ 1, 9 ] := ctrl_data[ 1, 9 ] + ( field->ukupno - field->ukpoptp )

      // dokument iz tabele
      xml_node( "dbr", to_xml_encoding( AllTrim( field->brdok ) ) )
      xml_node( "ddat", if( DToC( field->datdok ) != DToC( CToD( "" ) ), DToC( field->datdok ), "" ) )
      xml_node( "ddval", if( DToC( field->datval ) != DToC( CToD( "" ) ), DToC( field->datval ), "" ) )
      xml_node( "ddisp", if( DToC( field->datisp ) != DToC( CToD( "" ) ), DToC( field->datisp ), "" ) )
      xml_node( "dvr", AllTrim( field->vrijeme ) )

      // dokument iz teksta
      cTmp := AllTrim( get_dtxt_opis( "D01" ) )
      xml_node( "dmj", to_xml_encoding( cTmp ) )

      cTmp := AllTrim( get_dtxt_opis( "D02" ) )
      xml_node( "ddok", to_xml_encoding( cTmp ) )

      cTmp := AllTrim( get_dtxt_opis( "D04" ) )
      xml_node( "dslovo", to_xml_encoding( cTmp ) )

      xml_node( "dotpr", to_xml_encoding( AllTrim( get_dtxt_opis( "D05" ) ) ) )
      xml_node( "dnar", to_xml_encoding( AllTrim( get_dtxt_opis( "D06" ) ) ) )
      xml_node( "ddin", to_xml_encoding( _din_dem ) )

      // destinacija na fakturi
      cTmp := AllTrim( get_dtxt_opis( "D08" ) )
      IF Empty( cTmp )
         // ako je prazno, uzmi adresu partnera
         cTmp := get_dtxt_opis( "K02" )
      ENDIF

      xml_node( "ddest", to_xml_encoding( cTmp ) )
      xml_node( "dtdok", to_xml_encoding( AllTrim( get_dtxt_opis( "D09" ) ) ) )
      xml_node( "drj", to_xml_encoding( AllTrim( get_dtxt_opis( "D10" ) ) ) )
      xml_node( "didpm", to_xml_encoding( AllTrim( get_dtxt_opis( "D11" ) ) ) )

      // objekat i naziv
      xml_node( "obj_id", AllTrim( to_xml_encoding( get_dtxt_opis( "O01" ) ) ) )
      xml_node( "obj_naz", AllTrim( to_xml_encoding( get_dtxt_opis( "O02" ) ) ) )

      // broj fiskalnog racuna
      xml_node( "fisc", AllTrim( get_dtxt_opis( "O10" ) ) )

      cTmp := AllTrim( get_dtxt_opis( "F10" ) )
      xml_node( "dsign", to_xml_encoding( cTmp ) )

      // broj veze
      nLines := Val( get_dtxt_opis( "D30" ) )
      cTmp := ""
      nTmp := 30
      FOR i := 1 TO nLines
         cTmp += get_dtxt_opis( "D" + AllTrim( Str( nTmp + i ) ) )
      NEXT
      xml_node( "dveza", to_xml_encoding( cTmp ) )

      // partner
      xml_node( "knaz", to_xml_encoding( AllTrim( get_dtxt_opis( "K01" ) ) ) )
      xml_node( "kadr", to_xml_encoding( AllTrim( get_dtxt_opis( "K02" ) ) ) )
      xml_node( "kid", to_xml_encoding( AllTrim( get_dtxt_opis( "K03" ) ) ) )
      xml_node( "kidbroj", to_xml_encoding( AllTrim( get_dtxt_opis( "K15" ) ) ) )
      xml_node( "kpdvbroj", to_xml_encoding( AllTrim( get_dtxt_opis( "K16" ) ) ) )
      xml_node( "kpbr", AllTrim( get_dtxt_opis( "K05" ) ) )
      xml_node( "kmj", to_xml_encoding( AllTrim( get_dtxt_opis( "K10" ) ) ) )
      xml_node( "kptt", AllTrim( get_dtxt_opis( "K11" ) ) )
      xml_node( "ktel", to_xml_encoding( AllTrim( get_dtxt_opis( "K13" ) ) ) )
      xml_node( "kfax", to_xml_encoding( AllTrim( get_dtxt_opis( "K14" ) ) ) )

      // dodatni tekst na fakturi....
      // koliko ima redova ?
      nTxtR := Val( get_dtxt_opis( "P02" ) )

      FOR i := 20 TO ( 20 + nTxtR )

         cTmp := "F" + AllTrim( Str( i ) )
         cTmpTxt := AllTrim( get_dtxt_opis( cTmp ) )

         xml_subnode( "text", .F. )
         xml_node( "row", to_xml_encoding( cTmpTxt ) )
         xml_subnode( "text", .T. )

      NEXT

      // RN
      // brdok, rbr, podbr, idroba, robanaz, jmj, kolicina, cjenpdv, cjenbpdv
      // cjen2pdv, cjen2bpdv, popust, ppdv, vpdv, ukupno, poptp, vpoptp
      // c1, c2, c3, opis

      // predji sada na stavke fakture
      SELECT rn
      GO TOP

      DO WHILE !Eof()

         xml_subnode( "item", .F. )

         xml_node( "rbr", AllTrim( field->rbr ) )
         xml_node( "pbr", AllTrim( field->podbr ) )
         xml_node( "id", to_xml_encoding( AllTrim( field->idroba ) ) )
         xml_node( "naz", to_xml_encoding( AllTrim( field->robanaz ) ) )
         xml_node( "jmj", to_xml_encoding( AllTrim( field->jmj ) ) )
         xml_node( "kol", show_number( field->kolicina, PIC_KOLICINA ) )
         xml_node( "cpdv", show_number( field->cjenpdv, PIC_CIJENA ) )
         xml_node( "cbpdv", show_number( field->cjenbpdv, PIC_CIJENA ) )
         xml_node( "c2pdv", show_number( field->cjen2pdv, PIC_CIJENA ) )
         xml_node( "c2bpdv", show_number( field->cjen2bpdv, PIC_CIJENA ) )
         xml_node( "pop", show_number( field->popust, PIC_VRIJEDNOST ) )
         xml_node( "ppdv", show_number( field->ppdv, PIC_VRIJEDNOST ) )
         xml_node( "vpdv", show_number( field->vpdv, PIC_VRIJEDNOST ) )
         // ukupno bez pdv
         xml_node( "ukbpdv", show_number( field->cjenbpdv * field->kolicina, ;
            PIC_VRIJEDNOST ) )
         // ukupno sa pdv
         xml_node( "ukpdv", show_number( field->ukupno, PIC_VRIJEDNOST ) )
         // ukupno bez pdv-a sa popustom
         xml_node( "uk2bpdv", show_number( field->cjen2bpdv * field->kolicina, ;
            PIC_VRIJEDNOST ) )
         // ukupno sa pdv-om sa popustom
         xml_node( "uk2pdv", show_number( field->cjen2pdv * field->kolicina, ;
            PIC_VRIJEDNOST ) )
         xml_node( "ptp", show_number( field->poptp, PIC_VRIJEDNOST ) )
         xml_node( "vtp", show_number( field->vpoptp, PIC_VRIJEDNOST ) )

         xml_node( "opis", to_xml_encoding( field->opis ) )

         xml_subnode( "item", .T. )

         SKIP

      ENDDO

      xml_subnode( "invoice_no", .T. )

   NEXT
   my_use_refresh_start()

   xml_subnode( "invoice", .T. )

   close_xml()

   RETURN .T.


// ------------------------------------------------------
// setuje defaultni odt cTemplate
// ------------------------------------------------------
FUNCTION __default_odt_template()

   __default_odt_vp_template := fetch_metric( "fakt_default_odt_template", my_user(), "" )
   __default_odt_mp_template := fetch_metric( "fakt_default_odt_mp_template", my_user(), "" )
   __default_odt_kol_template := fetch_metric( "fakt_default_odt_kol_template", my_user(), "" )

   RETURN


FUNCTION __auto_odt_template()

   __auto_odt := fetch_metric( "fakt_odt_template_auto", NIL, "D" )

   RETURN .T.
