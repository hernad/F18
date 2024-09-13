/*
 * This file is part of the bring.out FMK, a free and open source
 * accounting software suite,
 * Copyright (c) 1994-2024 by bring.out d.o.o Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including knowhow ERP specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_knowhow.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */

#include "f18.ch"

STATIC PIC_VRIJEDNOST := ""
STATIC LEN_VRIJEDNOST := 12


// -----------------------------------------------------
// stampa naloga za proizvodnju u odt formatu...
// -----------------------------------------------------
FUNCTION rnal_obracunski_list_odt()

   LOCAL _params
   LOCAL _doc_no, _doc_gr
   LOCAL _ok := .F.
   LOCAL _template := "obrlist.odt"

   download_template( "obrlist.odt", "b8be3841cea218a18fe804e34ba9aa035924ce0449095b910365e6d1c83d70e9" )

   t_rpt_open()

   _get_t_pars( @_params )

   IF !_cre_xml( _params )
      RETURN _ok
   ENDIF

   SELECT t_docit
   USE
   SELECT t_docop
   USE
   SELECT t_pars
   USE

   IF generisi_odt_iz_xml( _template )
      prikazi_odt()
   ENDIF

   _ok := .T.

   RETURN _ok



// ------------------------------------------------------
// citanje vrijednosti iz tabele tpars u hash matricu
// ------------------------------------------------------
STATIC FUNCTION _get_t_pars( params )

   LOCAL _tmp

   params := hb_Hash()

   // ttotal
   _tmp := Val( g_t_pars_opis( "N10" ) )
   params[ "ttotal" ] := _tmp

   // rekapitulacija materijala
   params[ "rekap_materijala" ] := ( AllTrim( g_t_pars_opis( "N20" ) ) == "D" )

   // operater
   _tmp := g_t_pars_opis( "N13" )
   params[ "spec_operater" ] := _tmp
   // operater koji printa
   _tmp := getfullusername( f18_get_user_id( f18_user() ) )
   params[ "spec_print_operater" ] := _tmp
   // vrijeme printanja
   _tmp := PadR( Time(), 5 )
   params[ "spec_print_vrijeme" ] := _tmp

   // podaci header-a
   // ==============================================
   // broj dokumenta
   params[ "nalog_broj" ] := g_t_pars_opis( "N01" )
   // naziv naloga
   params[ "nalog_datum" ] := g_t_pars_opis( "N02" )
   // vrijeme naloga
   params[ "nalog_vrijeme" ] := g_t_pars_opis( "N12" )
   // dokumenti
   params[ "nalozi_lista" ] := g_t_pars_opis( "N14" )
   // objekat id
   params[ "nalog_objekat_id" ] := g_t_pars_opis( "P20" )
   // naziv objekta
   params[ "nalog_objekat_naziv" ] := g_t_pars_opis( "P21" )


   // podaci kupca
   // ===============================================
   // firma
   params[ "firma_naziv" ] := AllTrim( gFNaziv )
   // kupac
   params[ "kupac_id" ] := g_t_pars_opis( "P01" )
   params[ "kupac_naziv" ] := g_t_pars_opis( "P02" )
   params[ "kupac_adresa" ] := g_t_pars_opis( "P03" )
   params[ "kupac_telefon" ] := g_t_pars_opis( "P04" )
   // kontakt
   params[ "kontakt_id" ] := g_t_pars_opis( "P10" )
   params[ "kontakt_naziv" ] := g_t_pars_opis( "P11" )
   params[ "kontakt_telefon" ] := g_t_pars_opis( "P12" )
   params[ "kontakt_opis" ] := g_t_pars_opis( "P13" )
   params[ "kontakt_opis_2" ] := g_t_pars_opis( "N09" )

   RETURN .T.






// -----------------------------------
// generisanje xml fajla
// -----------------------------------
STATIC FUNCTION _cre_xml( params )

   LOCAL _xml := my_home() + "data.xml"
   LOCAL _picdem := "999999999.99"
   LOCAL _docs, _doc_no, _doc_xxx, _doc_no_str, _doc_it_str, _art_sh, _art_id
   LOCAL _t_neto, _t_qtty, _t_total, _t_total_m, _description
   LOCAL _t_u_neto, _t_u_qtty, _t_u_total, _t_u_total_m
   LOCAL _ok := .T.
   LOCAL _count := 0

   PIC_VRIJEDNOST := PadL( AllTrim( Right( _picdem, LEN_VRIJEDNOST ) ), LEN_VRIJEDNOST, "9" )

   // otvori xml za upis...
   create_xml( _xml )

   xml_subnode( "specifikacija", .F. )
   xml_subnode( "spec", .F. )

   // upisi osvnovne podatke naloga
   xml_node( "fdesc", to_xml_encoding( params[ "firma_naziv" ] ) )
   xml_node( "no", params[ "nalog_broj" ] )
   xml_node( "cdate", DToC( danasnji_datum() ) )
   xml_node( "date", params[ "nalog_datum" ] )
   xml_node( "time", params[ "nalog_vrijeme" ] )
   xml_node( "ob_id", to_xml_encoding( params[ "nalog_objekat_id" ] ) )
   xml_node( "ob_desc", to_xml_encoding( params[ "nalog_objekat_naziv" ] ) )
   xml_node( "oper", to_xml_encoding( params[ "spec_operater" ] ) )
   xml_node( "oper_print", to_xml_encoding( params[ "spec_print_operater" ] ) )
   xml_node( "pr_time", params[ "spec_print_vrijeme" ] )

   _docs := AllTrim( params[ "nalozi_lista" ] )
   IF "," $ _docs
      xml_node( "lst", to_xml_encoding( "prema nalozima: " + AllTrim( _docs ) ) )
   ELSE
      xml_node( "lst", to_xml_encoding( "prema nalogu br: " + AllTrim( params[ "nalog_broj" ] ) ) )
   ENDIF

   // kupac/kontakt podaci...
   xml_node( "cust_id", to_xml_encoding( params[ "kupac_id" ] ) )
   xml_node( "cust_desc", to_xml_encoding( params[ "kupac_naziv" ] ) )
   xml_node( "cust_adr", to_xml_encoding( params[ "kupac_adresa" ] ) )
   xml_node( "cust_tel", to_xml_encoding( params[ "kupac_telefon" ] ) )
   xml_node( "cont_id", to_xml_encoding( params[ "kontakt_id" ] ) )
   xml_node( "cont_desc", to_xml_encoding( params[ "kontakt_naziv" ] ) )
   xml_node( "cont_tel", to_xml_encoding( params[ "kontakt_telefon" ] ) )
   xml_node( "cont_desc_2", to_xml_encoding( params[ "kontakt_opis" ] ) )
   xml_node( "cont_desc_3", to_xml_encoding( params[ "kontakt_opis_2" ] ) )

   SELECT t_docit
   SET ORDER TO TAG "3"
   GO TOP

   _doc_xxx := "XX"

   _item := 0

   _t_neto := 0
   _t_qtty := 0
   _t_total := 0
   _t_total_m := 0
   _t_u_neto := 0
   _t_u_qtty := 0
   _t_u_total := 0
   _t_u_total_m := 0

   // stampaj podatke
   DO WHILE !Eof()

      _doc_no := field->doc_no

      DO WHILE !Eof() .AND. field->doc_no == _doc_no

         _art_sh := field->art_sh_des

         // da li se stavka stampa ili ne ?
         IF field->PRINT == "N"
            SKIP
            LOOP
         ENDIF

         _doc_no_str := docno_str( field->doc_no )
         _doc_it_str := docit_str( field->doc_it_no )

         // <"nalog">
         xml_subnode( "nalog", .F. )

         // broj naloga
         xml_node( "no", _doc_no_str )

         DO WHILE !Eof() .AND. field->doc_no == _doc_no ;
               .AND. PadR( field->art_sh_des, 150 ) == ;
               PadR( _art_sh, 150 )

            ++_count

            // da li se stavka stampa ili ne ?
            IF field->PRINT == "N"
               SKIP
               LOOP
            ENDIF

            _doc_no_str := docno_str( field->doc_no )
            _doc_it_str := docit_str( field->doc_it_no )

            xml_subnode( "item", .F. )

            xml_node( "no", AllTrim( Str( ++_item ) ) )

            xml_node( "art_id", AllTrim( Str( field->art_id ) ) )
            xml_node( "qtty", show_number( field->doc_it_qtt, PIC_VRIJEDNOST ) )
            xml_node( "h", show_number( field->doc_it_hei, PIC_VRIJEDNOST ) )
            xml_node( "w", show_number( field->doc_it_wid, PIC_VRIJEDNOST ) )
            xml_node( "zh", show_number( field->doc_it_zhe, PIC_VRIJEDNOST ) )
            xml_node( "zw", show_number( field->doc_it_zwi, PIC_VRIJEDNOST ) )
            xml_node( "nt", show_number( field->doc_it_net, PIC_VRIJEDNOST ) )
            xml_node( "tot", show_number( field->doc_it_tot, PIC_VRIJEDNOST ) )
            xml_node( "tm", show_number( field->doc_it_tm, PIC_VRIJEDNOST ) )

            // saberi...
            _t_qtty += field->doc_it_qtt
            _t_neto += field->doc_it_net
            _t_total += field->doc_it_tot
            _t_total_m += field->doc_it_tm

            _description := AllTrim( field->art_desc )
            IF _count == 1 .AND. Empty( _description )
               _description := AllTrim( field->full_desc )
            ENDIF

            // opis stavke...
            IF Empty( _description )
               _art_desc := "-//-"
            ELSE
               _art_desc := AllTrim( _description )
            ENDIF

            // redni broj u nalogu
            _art_desc := "(" + AllTrim( Str( field->doc_it_no ) ) + ") " + _art_desc
            // pozicija ako postotoji
            _art_desc += "; " + AllTrim( field->doc_it_des )

            xml_node( "art_desc", to_xml_encoding( _art_desc ) )

            // zatvori node...
            xml_subnode( "item", .T. )

            SELECT t_docit
            SKIP

         ENDDO

         // totali po dokumentu ...
         xml_node( "qtty",  show_number( _t_qtty, PIC_VRIJEDNOST ) )
         xml_node( "nt",  show_number( _t_neto, PIC_VRIJEDNOST ) )
         xml_node( "tot",  show_number( _t_total, PIC_VRIJEDNOST ) )
         xml_node( "tm",  show_number( _t_total_m, PIC_VRIJEDNOST ) )

         // dodaj na konacni zbir
         _t_u_qtty += _t_qtty
         _t_u_neto += _t_neto
         _t_u_total += _t_total
         _t_u_total_m += _t_total_m

         // resetuj varijable totale
         _t_total_m := 0
         _t_total := 0
         _t_qtty := 0
         _t_neto := 0

         _doc_xxx := _doc_no_str

         xml_subnode( "nalog", .T. )

      ENDDO

   ENDDO

   // ukupno total...
   xml_node( "qtty",  show_number( _t_u_qtty, PIC_VRIJEDNOST ) )
   xml_node( "nt",  show_number( _t_u_neto, PIC_VRIJEDNOST ) )
   xml_node( "tot",  show_number( _t_u_total, PIC_VRIJEDNOST ) )
   xml_node( "tm",  show_number( _t_u_total_m, PIC_VRIJEDNOST ) )

   // rekapitulacija materijala treba
   xml_subnode( "rekap", .F. )

   SELECT t_docit2
   GO TOP

   IF RECCOUNT2() <> 0 .AND. params[ "rekap_materijala" ]

      DO WHILE !Eof()

         _r_doc := field->doc_no
         _r_doc_it_no := field->doc_it_no

         // da li se treba stampati ?
         SELECT t_docit
         SEEK docno_str( _r_doc ) + docit_str( _r_doc_it_no )

         IF field->PRINT == "N"
            SELECT t_docit2
            SKIP
            LOOP
         ENDIF

         // vrati se
         SELECT t_docit2

         DO WHILE !Eof() .AND. field->doc_no == _r_doc ;
               .AND. field->doc_it_no == _r_doc_it_no

            xml_subnode( "item", .F. )

            xml_node( "no", "(" + AllTrim( Str( field->doc_it_no ) ) + ")/" + AllTrim( Str( field->it_no ) ) )
            xml_node( "id", to_xml_encoding( AllTrim( field->art_id ) ) )
            xml_node( "desc", to_xml_encoding( AllTrim( field->art_desc ) ) )
            xml_node( "notes", to_xml_encoding( AllTrim( field->descr ) ) )
            xml_node( "qtty", repro_qtty_str( field->doc_it_qtt, field->doc_it_q2 ) )

            xml_subnode( "item", .T. )

            SKIP
         ENDDO

      ENDDO

   ENDIF

   xml_subnode( "rekap", .T. )

   xml_subnode( "spec", .T. )

   xml_subnode( "specifikacija", .T. )

   close_xml()

   RETURN _ok
