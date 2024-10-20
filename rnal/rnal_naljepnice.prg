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

FUNCTION rnal_stampa_naljepnica_odt()

   LOCAL _data_xml := my_home() + "data.xml"
   LOCAL _h_stavke, _h_header, _uk_kolicina
   LOCAL nCount := 0
   LOCAL nCutCount := 0
   LOCAL i, nUkupno
   LOCAL nMax_Komada := fetch_metric( "rnal_label_br_kom_razdvoji", NIL, 200 )
   LOCAL lDijeli := .F.
   LOCAL _template := ""
   LOCAL _t_path := f18_template_location()
   LOCAL _desktop_folder
   LOCAL _output_odt := NIL

   IF get_file_list_array( _t_path, "_rg*.odt", @_template ) = 0
      RETURN .F.
   ENDIF

   t_rpt_open()

   _h_header := hash_header_naljepnice()

   SELECT t_docit
   SET ORDER TO TAG "1"
   GO TOP

   nUkupno := koliko_ima_naljepnica()

   IF nUkupno > nMax_komada
      lDijeli := .T.
   ENDIF

   IF lDijeli
      napravi_folder_na_desktopu( @_desktop_folder, t_docit->doc_no )
   ENDIF

   DO WHILE !Eof()

      _kolicina_stavke := field->doc_it_qtt
	  _h_stavke := hash_podaci_naljepnice()

      FOR i := 1 TO _kolicina_stavke

         IF ( nCount == 0 .OR. nCount%nMax_komada == 0 )

            create_xml( _data_xml )
            xml_head()
            xml_subnode( "label", .F. )
            upisi_header_xml( _h_header )

         ENDIF

         upisi_stavke_xml( _h_stavke, _kolicina_stavke )
         ++ nCount

         IF ( nCount > 0 .AND. nCount%nMax_komada == 0 ) .OR. nUkupno == nCount

            ++ nCutCount

            xml_subnode( "label", .T. )
            close_xml()

            IF lDijeli
                // formira se fajl naziva: lab_001.odt, lab_002.odt, lab_003.odt
                _output_odt := _desktop_folder + SLASH
                _output_odt += "lab_"
                _output_odt += PADL( ALLTRIM( STR( nCutCount ) ), 3, "0" )
                _output_odt += ".odt"
                #IFNDEF __PLATFORM__WINDOWS
                   _output_odt := '"' + _output_odt + '"'
                #ENDIF

            ENDIF

            IF generisi_odt_iz_xml( _template, _data_xml, _output_odt )
               IF !lDijeli
                  prikazi_odt()
               ENDIF
            ENDIF

         ENDIF

      NEXT

      SELECT t_docit
      SKIP

   ENDDO

   IF lDijeli
      MsgBeep( "Naljepnice sa naloga su razdjeljene u " + ALLTRIM( STR( nCutCount ) ) + " ODT dokumenta.#" + ;
               "Smještene su u folderu F18_dokumenti na Desktopu" )
   ENDIF

   RETURN



STATIC FUNCTION napravi_folder_na_desktopu( folder_path, doc_no )

   LOCAL _desktop_path
   LOCAL _folder := "lab_" + ALLTRIM( STR( doc_no ) )
   LOCAL _cre

   // napravi folder: ~\Desktop\F18_dokumenti\
   create_f18_dokumenti_on_desktop( @_desktop_path )

   folder_path := _desktop_path + _folder

   // ako ne postoji F18_dokumenti\lab_23111\ napravi ga
   IF DirChange( folder_path ) != 0
      _cre := MakeDir( folder_path )
   ENDIF

   DirChange( my_home() )

   RETURN



STATIC FUNCTION koliko_ima_naljepnica()

   LOCAL nCount := 0

   SELECT t_docit
   GO TOP
   DO WHILE !Eof()
       nCount += field->doc_it_qtt
       SKIP
   ENDDO
   GO TOP

   RETURN nCount




STATIC FUNCTION upisi_header_xml( hash )

   xml_node( "c_desc", hash["cust_desc"] )
   xml_node( "c_tel", hash["cust_tel"] )
   xml_node( "c_addr", hash["cust_adr"] )
   xml_node( "cn_desc", hash["cont_desc"] )
   xml_node( "cn_tel", hash["cont_tel"] )
   xml_node( "cn_addr", hash["cont_adr"] )
   xml_node( "kratki_op", hash["kratki_op"] )
   xml_node( "obj", hash["cust_object"] )

   RETURN



STATIC FUNCTION upisi_stavke_xml( hash, ukupna_kolicina )

   LOCAL cTmp_h, cTmp_w

   xml_subnode( "glass", .F. )

   xml_node( "id", AllTrim( Str( hash["art_id"] ) ) )
   xml_node( "ldesc", AllTrim( hash["ldesc"] ) )
   xml_node( "sdesc", AllTrim( hash["sdesc"] ) )
   xml_node( "fdesc", AllTrim( hash["fdesc"] ) )
   xml_node( "city", hash["city"] )
   xml_node( "altt", hash["altitude"] )
   xml_node( "qtty", AllTrim( Str( 1, 12 ) ) )
   xml_node( "tqt", AllTrim( Str( ukupna_kolicina, 12 ) ) )
   xml_node( "type", hash["article_type"] )

   cTmp_h := AllTrim( Str( hash["height"], 12, 2 ) )
   cTmp_w := AllTrim( Str( hash["width"], 12, 2 ) )

   xml_node( "full_he", cTmp_h )
   xml_node( "full_wi", cTmp_w )
   xml_node( "dim", cTmp_w + " x " + cTmp_h )

   cTmp_h := AllTrim( Str( hash["height_inch"], 12, 2 ) )
   cTmp_w := AllTrim( Str( hash["width_inch"], 12, 2 ) )

   xml_node( "dim_in", cTmp_w + " x " + cTmp_h )

   cTmp_h := AllTrim( Str( hash["height"], 12 ) )
   cTmp_w := AllTrim( Str( hash["width"], 12 ) )

   xml_node( "sh_he", cTmp_h )
   xml_node( "sh_wi", cTmp_w )

   xml_node( "l_pos", hash["def_position"] )
   xml_node( "l_epos", hash["def_position_en"] )
   xml_node( "pos", hash["position"] )

   xml_subnode( "glass", .T. )


   RETURN



STATIC FUNCTION hash_header_naljepnice()

   LOCAL hash := hb_hash()

   hash["cust_desc"] := ALLTRIM( to_xml_encoding( g_t_pars_opis( "P02" ) ) )
   hash["cust_tel"] := ALLTRIM( g_t_pars_opis( "P04" ) )
   hash["cust_adr"] := ALLTRIM( to_xml_encoding( g_t_pars_opis( "P03" ) ) )
   hash["cont_desc"] := ALLTRIM( to_xml_encoding( g_t_pars_opis( "P11" ) ) )
   hash["cont_tel"] := ALLTRIM( g_t_pars_opis( "P12" ) )
   hash["cont_adr"] := ALLTRIM( to_xml_encoding( g_t_pars_opis( "P13" ) ) )
   hash["kratki_op"] := ALLTRIM( to_xml_encoding( g_t_pars_opis( "N08" ) ) )

   IF hash["cust_desc"] == "NN"
      hash["cust_desc"] := hash["cont_desc"]
      hash["cust_tel"] := hash["cont_tel"]
      hash["cust_adr"] := hash["cont_adr"]
   ENDIF

   hash["cust_object"] := ALLTRIM( to_xml_encoding( g_t_pars_opis( "P21" ) ) )

   RETURN hash



STATIC FUNCTION hash_podaci_naljepnice()

   LOCAL hash := hb_hash()

   SELECT t_docit

   hash["def_position"] := "Unutra"
   hash["def_position_en"] := "Inside"

   hash["doc_no"] := field->doc_no
   hash["doc_it_no"] := field->doc_it_no
   hash["art_id"] := field->art_id

   SELECT articles
   GO TOP
   SEEK artid_str( hash["art_id"] )

   hash["ldesc"] := to_xml_encoding( AllTrim( field->art_lab_de ) )
   hash["fdesc"] := to_xml_encoding( AllTrim( field->art_full_d ) )
   hash["sdesc"] := to_xml_encoding( AllTrim( field->art_desc ) )

   IF Empty( hash["ldesc"] )
      hash["ldesc"] := hash["sdesc"]
   ENDIF

   SELECT t_docit

   hash["height"] := field->doc_it_hei
   hash["width"] := field->doc_it_wid

   hash["height_inch"] := to_inch( field->doc_it_hei )
   hash["width_inch"] := to_inch( field->doc_it_wid )

   hash["qtty"] := field->doc_it_qtt

   hash["position"] := AllTrim( to_xml_encoding( AllTrim( field->doc_it_pos ) ) )
   hash["city"] := AllTrim( to_xml_encoding( AllTrim( field->doc_acity ) ) )
   hash["altitude"] := to_xml_encoding( AllTrim( Str( field->doc_it_alt, 12 ) ) )

   hash["article_type"] := "-"

   IF is_ramaterm( AllTrim( field->art_desc ) )
       hash["article_type"] := "RAMA-TERM"
   ENDIF

   RETURN hash
