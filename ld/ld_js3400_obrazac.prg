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

STATIC __mj_od
STATIC __mj_do
STATIC __god_od
STATIC __god_do
STATIC __por_per
STATIC __datum
STATIC __djl_broj
STATIC __op_jmb
STATIC __op_ime



FUNCTION ld_js3400_obrazac()

   LOCAL nC1 := 20
   LOCAL i
   LOCAL cRj := Space( 60 )
   LOCAL cRJDef := Space( 2 )
   LOCAL cIdRadnik := Space( LEN_IDRADNIK )
   LOCAL cPrimDobra := Space( 100 )
   LOCAL cIdRj
   LOCAL cMj_od
   LOCAL cMj_do
   LOCAL cGod_od
   LOCAL cGod_do
   LOCAL cDopr10 := "10"
   LOCAL cDopr11 := "11"
   LOCAL cDopr12 := "12"
   LOCAL cDopr1X := "1X"
   LOCAL cTipRpt := "1"
   LOCAL cTP_off := Space( 100 )
   LOCAL cObracun := gObracun
   LOCAL cWinPrint := "S"
   LOCAL _x := 1
   LOCAL _oper := "O"

   // kreiraj pomocnu tabelu
   ol_tmp_tbl()

   cIdRj := gLDRadnaJedinica
   cMj_od := ld_tekuci_mjesec()
   cMj_do := ld_tekuci_mjesec()
   cGod_od := ld_tekuca_godina()
   cGod_do := ld_tekuca_godina()

   cPredNaz := Space( 50 )
   cPredAdr := Space( 50 )
   cPredJMB := Space( 13 )
   cPredOpc := Space( 30 )
   cPredTel := Space( 30 )
   cPredEml := Space( 50 )
   cDjlBroj := Space( 20 )
   cOpJmb := Space( 16 )
   cOpIme := Space( 50 )

   nPorGodina := Year( Date() )
   dDatUnosa := Date()
   dDatPodnosenja := Date()

   // otvori tabele
   ol_o_tbl()

   // upisi parametre...
   cPredNaz := hb_UTF8ToStr( fetch_metric( "obracun_plata_preduzece_naziv", NIL, cPredNaz ) )
   cPredAdr := hb_UTF8ToStr( fetch_metric( "obracun_plata_preduzece_adresa", NIL, cPredAdr ) )
   cPredJMB := hb_UTF8ToStr( fetch_metric( "obracun_plata_preduzece_id_broj", NIL, cPredJMB ) )
   cPredOpc := hb_UTF8ToStr( fetch_metric( "obracun_plata_preduzece_opcina", NIL, cPredOpc ) )
   cPredTel := hb_UTF8ToStr( fetch_metric( "obracun_plata_preduzece_telefon", NIL, cPredTel ) )
   cPredEml := hb_UTF8ToStr( fetch_metric( "obracun_plata_preduzece_email", NIL, cPredEml ) )
   cDjlBroj := hb_UTF8ToStr( fetch_metric( "obracun_plata_js_obrazac_djelovodni_broj", NIL, cDjlBroj ) )
   cOpJmb := hb_UTF8ToStr( fetch_metric( "obracun_plata_js_obrazac_op_jmb", NIL, cOpJmb ) )
   cOpIme := hb_UTF8ToStr( fetch_metric( "obracun_plata_js_obrazac_op_ime", NIL, cOpIme ) )

   Box( "#JS-3400", 22, 75 )

   @ box_x_koord() + _x, box_y_koord() + 2 SAY "Radne jedinice: " GET cRj PICT "@!S25"

   ++ _x
   @ box_x_koord() + _x, box_y_koord() + 2 SAY "Period od:" GET cMj_od PICT "99"
   @ box_x_koord() + _x, Col() + 1 SAY "/" GET cGod_od PICT "9999"
   @ box_x_koord() + _x, Col() + 1 SAY "do:" GET cMj_do PICT "99"
   @ box_x_koord() + _x, Col() + 1 SAY "/" GET cGod_do PICT "9999"
   @ box_x_koord() + _x, Col() + 2 SAY "Obracun:" GET cObracun WHEN ld_help_broj_obracuna( .T., cObracun ) VALID ld_valid_obracun( .T., cObracun )

   ++ _x
   ++ _x
   @ box_x_koord() + _x, box_y_koord() + 2 SAY "Radnik (prazno-svi radnici): " GET cIdRadnik ;
      VALID Empty( cIdRadnik ) .OR. P_RADN( @cIdRadnik )

   ++ _x
   ++ _x
   @ box_x_koord() + _x, box_y_koord() + 2 SAY "   Doprinos iz pio: " GET cDopr10

   ++ _x
   @ box_x_koord() + _x, box_y_koord() + 2 SAY "   Doprinos iz zdr: " GET cDopr11

   ++ _x
   @ box_x_koord() + _x, box_y_koord() + 2 SAY "   Doprinos iz nez: " GET cDopr12

   ++ _x
   @ box_x_koord() + _x, box_y_koord() + 2 SAY "Doprinos iz ukupni: " GET cDopr1X

   ++ _x
   ++ _x
   @ box_x_koord() + _x, box_y_koord() + 2 SAY "Naziv preduzeca: " GET cPredNaz PICT "@S30"
   @ box_x_koord() + _x, Col() + 1 SAY "JID: " GET cPredJMB

   ++ _x
   @ box_x_koord() + _x, box_y_koord() + 2 SAY "Adr.: " GET cPredAdr PICT "@S30"
   @ box_x_koord() + _x, Col() + 1 SAY "Sifra opc: " GET cPredOpc PICT "@S10"

   ++ _x
   @ box_x_koord() + _x, box_y_koord() + 2 SAY "Tel.: " GET cPredTel PICT "@S20"
   @ box_x_koord() + _x, Col() + 1 SAY "Email: " GET cPredEml PICT "@S30"

   ++ _x
   ++ _x
   @ box_x_koord() + _x, box_y_koord() + 2 SAY "(1) JS-3400 " GET cTipRpt VALID cTipRpt $ "1"
   @ box_x_koord() + _x, Col() + 2 SAY "def.rj" GET cRJDef
   @ box_x_koord() + _x, Col() + 2 SAY "st./exp.(S/E)?" GET cWinPrint VALID cWinPrint $ "SE" PICT "@!"

   ++ _x
   ++ _x
   @ box_x_koord() + _x, box_y_koord() + 2 SAY "P.godina" GET nPorGodina PICT "9999"
   @ box_x_koord() + _x, Col() + 2 SAY "Dat.podnos." GET dDatPodnosenja
   @ box_x_koord() + _x, Col() + 2 SAY "Dat.unosa" GET dDatUnosa

   ++ _x
   @ box_x_koord() + _x, box_y_koord() + 2 SAY "Dj.broj:" GET cDjlBroj PICT "@S10"
   @ box_x_koord() + _x, Col() + 2 SAY "Podnosi:" GET cOpIme PICT "@S20"
   @ box_x_koord() + _x, Col() + 2 SAY "JMB:" GET cOpJmb

   ++ _x
   @ box_x_koord() + _x, box_y_koord() + 2 SAY "operacija: (O)snovna (P)onovljena " GET _oper VALID _oper $ "OP" PICT "@!"

   READ

   cOperacija := g_operacija( _oper )

   clvbox()

   ESC_BCR

   BoxC()

   IF LastKey() == K_ESC
      RETURN .F.
   ENDIF

   // staticke
   __mj_od := cMj_od
   __mj_do := cMj_do
   __god_od := cGod_od
   __god_do := cGod_do
   __por_per := nPorGodina
   __datum := dDatPodnosenja
   __djl_broj := cDjlBroj
   __op_jmb := cOpJmb
   __op_ime := cOpIme

   // upisi parametre...
   set_metric( "obracun_plata_preduzece_naziv", NIL, cPredNaz )
   set_metric( "obracun_plata_preduzece_adresa", NIL, cPredAdr )
   set_metric( "obracun_plata_preduzece_id_broj", NIL, cPredJMB )
   set_metric( "obracun_plata_preduzece_opcina", NIL, cPredOpc )
   set_metric( "obracun_plata_preduzece_telefon", NIL, cPredTel )
   set_metric( "obracun_plata_preduzece_email", NIL, cPredEml )
   set_metric( "obracun_plata_js_obrazac_djelovodni_broj", NIL, cDjlBroj )
   set_metric( "obracun_plata_js_obrazac_op_jmb", NIL, cOpJmb )
   set_metric( "obracun_plata_js_obrazac_op_ime", NIL, cOpIme )


   seek_ld( NIL, NIL, NIL, NIL, cIdRadnik ) // seek_ld( cIdRj, nGodina, nMjesec, cObracun, cIdRadn, cTag )

   // sortiraj tabelu i postavi filter
   ld_obracunski_list_sort( cRj, cGod_od, cGod_do, cMj_od, cMj_do, cIdRadnik, cTipRpt, cObracun )

   // nafiluj podatke obracuna
   ol_fill_data( cRj, cRjDef, cGod_od, cGod_do, cMj_od, cMj_do, cIdRadnik, ;
      cPrimDobra, cTP_off, cDopr10, cDopr11, cDopr12, cDopr1X, cTipRpt, ;
      cObracun )


   // stampa izvjestaja xml/oo3
   _xml_print( cTipRpt )

   RETURN .T.


// ------------------------------------------------------
// vraca vrstu operacije
// ------------------------------------------------------
STATIC FUNCTION g_operacija( oper )

   LOCAL _operacija := ""

   IF oper == "O"
      _operacija := "Osnovna"
   ELSEIF oper == "P"
      _operacija := "Ponovljena"
   ENDIF

   RETURN _operacija


// --------------------------------------
// vraca period osiguranja
// --------------------------------------
STATIC FUNCTION g_osig( mjesec, od_do )

   LOCAL _ret := ""
   LOCAL _tmp
   LOCAL _day

   IF Empty( AllTrim( Str( mjesec ) ) )
      RETURN _ret
   ENDIF

   IF od_do == "1"
      _day := "01"
   ELSE
      DO CASE
      CASE mjesec = 1 .OR. mjesec = 3 .OR. mjesec = 5 .OR. mjesec = 7 .OR. mjesec = 8 .OR. mjesec = 10 .OR. mjesec = 12
         _day := "31"
      CASE mjesec = 2
         _day := "28"
      CASE mjesec = 4 .OR. mjesec = 6 .OR. mjesec = 9 .OR. mjesec = 11
         _day := "30"
      ENDCASE
   ENDIF

   // mjesec/dan
   _ret := PadL( AllTrim( Str( mjesec  ) ), 2, "0" )
   _ret += "/" + _day

   RETURN _ret



STATIC FUNCTION _xml_print( tip )

   LOCAL _template
   LOCAL _xml_file := my_home() + "data.xml"

   _fill_xml( tip, _xml_file )

   download_template( "ld_js_1.odt", "4f3f455942d21b48221435e59750b26e8402b0357b5a50aa3b99b6796e93029d" )

   DO CASE
   CASE tip == "1"
      _template := "ld_js_1.odt"
   ENDCASE

   IF generisi_odt_iz_xml( _template, _xml_file )
      prikazi_odt()
   ENDIF

   RETURN .T.


// --------------------------------------------
// filuje xml fajl sa podacima izvjestaja
// --------------------------------------------
STATIC FUNCTION _fill_xml( cTip, xml_file )

   LOCAL nTArea := Select()
   LOCAL nT_bruto := 0
   LOCAL nT_sati := 0
   LOCAL nT_dop_u := 0
   LOCAL nT_d_zdr := 0
   LOCAL nT_d_pio := 0
   LOCAL nT_d_nez := 0
   LOCAL nR_bruto := 0
   LOCAL nR_sati := 0
   LOCAL nR_dop_u := 0
   LOCAL nR_d_zdr := 0
   LOCAL nR_d_pio := 0
   LOCAL nR_d_nez := 0
   LOCAL nOsig_od, nOsig_do

   // otvori xml za upis
   create_xml( xml_file )
   // upisi header
   xml_head()

   xml_subnode( "rpt", .F. )

   // naziv firme
   xml_node( "p_naz", to_xml_encoding( AllTrim( cPredNaz ) ) )
   xml_node( "p_adr", to_xml_encoding( AllTrim( cPredAdr ) ) )
   xml_node( "p_jmb", AllTrim( cPredJmb ) )
   xml_node( "p_opc", AllTrim( cPredOpc ) )
   xml_node( "p_tel", AllTrim( cPredTel ) )
   xml_node( "p_eml", to_xml_encoding( AllTrim( cPredEml ) ) )
   xml_node( "p_per", g_por_per() )
   xml_node( "datum", DToC( __datum ) )
   xml_node( "pod_ime", to_xml_encoding( AllTrim( __op_ime ) ) )
   xml_node( "pod_jmb", to_xml_encoding( AllTrim( __op_jmb ) ) )
   xml_node( "dj_broj", to_xml_encoding( AllTrim( __djl_broj ) ) )

   SELECT r_export
   SET ORDER TO TAG "1"
   GO TOP

   nCnt := 0

   DO WHILE !Eof()

      // po radniku
      cT_radnik := field->idradn

      select_o_radn( cT_radnik )

      SELECT r_export

      nR_bruto := 0
      nR_sati := 0
      nR_dop_u := 0
      nR_d_zdr := 0
      nR_d_pio := 0
      nR_d_nez := 0

      // startna vrijednost osiguranja
      nOsig_od := field->mjesec

      // prodji kroz radnike i saberi im vrijednosti...
      DO WHILE !Eof() .AND. field->idradn == cT_radnik

         // ukupni doprinosi
         REPLACE field->dop_uk WITH field->dop_pio + ;
            field->dop_nez + field->dop_zdr

         nR_bruto += field->bruto
         nT_bruto += field->bruto

         nR_sati += field->sati
         nT_sati += field->sati

         nR_dop_u += field->dop_uk
         nT_dop_u += field->dop_uk

         nR_d_zdr += field->dop_zdr
         nT_d_zdr += field->dop_zdr

         nR_d_pio += field->dop_pio
         nT_d_pio += field->dop_pio

         nR_d_nez += field->dop_nez
         nT_d_nez += field->dop_nez

         // krajnja vrijednost osiguranja
         nOsig_do := field->mjesec

         SKIP

      ENDDO

      // subnode radnik
      xml_subnode( "radnik", .F. )

      xml_node( "ime", to_xml_encoding( AllTrim( radn->ime ) + ;
         " (" + AllTrim( radn->imerod ) + ;
         ") " + AllTrim( radn->naz ) ) )

      xml_node( "os_od", AllTrim( g_osig( nOsig_od, "1" ) ) )
      xml_node( "os_do", AllTrim( g_osig( nOsig_do, "2" ) ) )
      xml_node( "mb", AllTrim( radn->matbr ) )
      xml_node( "rbr", Str( ++nCnt ) )
      xml_node( "sati", Str( nR_sati ) )
      xml_node( "bruto", Str( nR_bruto, 12, 2 ) )
      xml_node( "do_uk", Str( nR_dop_u, 12, 2 ) )
      xml_node( "do_pio", Str( nR_d_pio, 12, 2 ) )
      xml_node( "do_zdr", Str( nR_d_zdr, 12, 2 ) )
      xml_node( "do_nez", Str( nR_d_nez, 12, 2 ) )

      // zatvori radnika
      xml_subnode( "radnik", .T. )

   ENDDO

   // upisi totale za radnika
   xml_subnode( "total", .F. )

   xml_node( "red", Str( nCnt ) )
   xml_node( "sati", Str( nT_sati, 12, 2 ) )
   xml_node( "bruto", Str( nT_bruto, 12, 2 ) )
   xml_node( "do_uk", Str( nT_dop_u, 12, 2 ) )
   xml_node( "do_pio", Str( nT_d_pio, 12, 2 ) )
   xml_node( "do_zdr", Str( nT_d_zdr, 12, 2 ) )
   xml_node( "do_nez", Str( nT_d_nez, 12, 2 ) )

   xml_subnode( "total", .T. )

   // zatvori <rpt>
   xml_subnode( "rpt", .T. )

   SELECT ( nTArea )

   // zatvori xml fajl za upis
   close_xml()

   RETURN .T.


// ----------------------------------------------------------
// vraca string poreznog perioda
// ----------------------------------------------------------
STATIC FUNCTION g_por_per()

   LOCAL _ret := ""

   _ret := AllTrim( Str( __por_per ) )

   RETURN _ret
