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


/* Omogucava izradu naljepnica u dvije varijante:
 1 - prikaz naljepnica sa tekucom cijenom
 2 - prikaz naljepnica sa novom cijenom, kao i prekrizenom starom cijenom


 - kalk_roba_naljepnice_stampa( cIdFirma, cIdVd, cBrDok ) - stampa za azurirani dokument
 - kalk_roba_naljepnice_stampa() - stampa pripreme

*/

FUNCTION kalk_roba_naljepnice_stampa( cIdFirma, cIdVd, cBrDok )

   LOCAL cVarijanta
   LOCAL cKolicina
   LOCAL _tkm_no
   LOCAL _xml_file := my_home() + "data.xml"
   LOCAL _template := "rlab1.odt"
   LOCAL _len_naz := 25
   LOCAL lPriprema := .F.

   cVarijanta := "1"
   cKolicina := "N"

   download_template( "rlab1.odt", "56c4e769a40a99f642878d3bf2876533a5611f2629c5c4e6a14155b31e4af78f" )
   download_template( "rlab2.odt", "f7ad93b382e9fdf26cada7b9cf95314b8e5d98cf17a926ab65ab53aa07ce74d8" )

   IF cVarijanta == "2"
      _template := "rlab2.odt"
   ENDIF

   IF cIdFirma != NIL .AND. cIdVd != NIL .AND. cBrDok != NIL
      open_kalk_as_pripr( cIdFirma, cIdVd, cBrDok )
      lPriprema := .F.
   ELSE
      // my_close_all_dbf()
      select_o_kalk_pripr()
      lPriprema := .T.
   ENDIF

   IF !GetVars( @cVarijanta, @cKolicina, @_tkm_no, @_len_naz )
      RETURN .F.
   ENDIF

   cre_open_roba_naljepnice()
   roba_naljepnice_napuni_iz_kalk_pripr( cKolicina )

   SELECT rlabele
   IF RecCount() == 0
      MsgBeep( "Nije generisano ništa#Greška - STOP!" )
      USE
      // my_close_all_dbf()
      RETURN .F.
   ENDIF

   _gen_xml( _xml_file, _tkm_no, _len_naz )

   my_close_all_dbf()
   IF generisi_odt_iz_xml( _template, _xml_file )
      prikazi_odt()
   ENDIF



   RETURN .T.


STATIC FUNCTION GetVars( cVarijanta, cKolicina, tkm_no, len_naz )

   // LOCAL lOpened
   LOCAL cIdVd

   // cIdVd := "XX"
   cVarijanta := "1"
   cKolicina := "N"
   lOpened := .T.

   tkm_no := PadR( fetch_metric( "rlabel_tkm_no", my_user(), "" ), 20 )
   len_naz := fetch_metric( "rlabel_naz_len", NIL, 28 )

   IF ( gModul == "KALK" )

      IF kalk_pripr->idVd == "19"
         cVarijanta := "2"
      ENDIF
   ENDIF

   Box(, 10, 65 )

   @ box_x_koord() + 1, box_y_koord() + 2 SAY "Broj labela zavisi od kolicine artikla (D/N):" GET cKolicina VALID cKolicina $ "DN" PICT "@!"

   @ box_x_koord() + 3, box_y_koord() + 2 SAY "1 - standardna naljepnica"
   @ box_x_koord() + 4, box_y_koord() + 2 SAY "2 - sa prikazom stare cijene (prekrizeno)"

   @ box_x_koord() + 6, box_y_koord() + 3 SAY "Odaberi zeljenu varijantu "  GET cVarijanta VALID cVarijanta $ "12"
   @ box_x_koord() + 7, box_y_koord() + 2 SAY "Broj TKM:" GET tkm_no
   @ box_x_koord() + 8, box_y_koord() + 2 SAY "Naziv skrati na broj karaktera:" GET len_naz PICT "999"

   READ

   BoxC()

   // IF ( gModul == "KALK" )
   // IF ( !lOpened )
   // USE
   // ENDIF
   // ENDIF

   IF ( LastKey() == K_ESC )
      RETURN .F.
   ENDIF

   set_metric( "rlabel_tkm_no", my_user(), AllTrim( tkm_no ) )
   set_metric( "rlabel_naz_len", NIL, len_naz )

   RETURN .T.



/*
 Puni tabelu rLabele podacima na osnovu dokumenta iz pripreme modula KALK
 cKolicina - D ili N, broj labela zavisi od kolicine robe
*/

STATIC FUNCTION roba_naljepnice_napuni_iz_kalk_pripr( cKolicina )

   LOCAL cDok, i
   LOCAL nBr_labela := 0
   LOCAL _predisp := .F.

   SELECT kalk_pripr
   SET ORDER TO TAG "1"
   GO TOP

   IF mp_predispozicija( field->idfirma, field->idvd, field->brdok )
      _predisp := .T.
   ENDIF

   SELECT kalk_pripr
   GO TOP

   cDok := ( field->idFirma + field->idVd + field->brDok )

   DO WHILE ( !Eof() .AND. cDok == ( field->idFirma + field->idVd + field->brDok ) )

      IF _predisp
         IF field->idkonto2 <> "XXX"
            SKIP
            LOOP
         ENDIF
      ENDIF

      nBr_labela := field->kolicina

      // ako ne zavisi od kolicine artikla
      // uvijek je jedna labela

      IF cKolicina == "N"
         nBr_labela := 1
      ENDIF

      select_o_roba( kalk_pripr->idRoba )

      SELECT rlabele
      SEEK kalk_pripr->idroba

      IF ( cKolicina == "D" .OR. ( cKolicina == "N" .AND. !Found() ) )

         FOR i := 1 TO nBr_labela

            SELECT rlabele
            APPEND BLANK

            Scatter()

            _idroba := kalk_pripr->idroba
            _naz := Left( roba->naz, 40 )
            _idtarifa := kalk_pripr->idtarifa
            _evbr := kalk_pripr->brdok
            _jmj := roba->jmj

            IF !Empty( roba->barkod )
               _barkod := roba->barkod
            ENDIF

            IF ( kalk_pripr->idVd == "19" )
               _cijena := kalk_pripr->mpcsapp + kalk_pripr->fcj
               _scijena := kalk_pripr->fcj
            ELSE
               _cijena := kalk_pripr->mpcsapp
               _scijena := _cijena
            ENDIF

            Gather()

         NEXT

      ENDIF

      SELECT kalk_pripr
      SKIP 1

   ENDDO

   RETURN NIL


// ---------------------------------------------------------------
// Prodji kroz pripremu FAKT-a i napuni tabelu rLabele
// ---------------------------------------------------------------
STATIC FUNCTION FaFillroba_naljepnice()
   RETURN NIL



// -------------------------------------------------------------------
// Stampaj RLabele (delphirb)
// cVarijanta - varijanta izgleda labele robe:
// "1" - standardna;
// "2" - za dokument nivelacije - prikazuju snizenje,
// gdje se vidi i precrtana stara cijena
// -------------------------------------------------------------------
STATIC FUNCTION Printroba_naljepnice( cVarijanta )

   LOCAL _rtm_naziv := AllTrim( "rLab" + cVarijanta )

   f18_rtm_print( _rtm_naziv, "rlabele", "1" )

   RETURN NIL


// ----------------------------------------------------------
// generisi xml na osnovu tabele rlabele
// ----------------------------------------------------------
STATIC FUNCTION _gen_xml( xml_file, tkm_no, len_naz )

   create_xml( xml_file )
   xml_head()

   xml_subnode( "lab", .F. )

   SELECT rlabele
   SET ORDER TO TAG "1"
   GO TOP

   xml_node( "pred", to_xml_encoding( AllTrim( self_organizacija_naziv() ) ) )
   xml_node( "grad", to_xml_encoding( AllTrim( gMjStr ) ) )
   xml_node( "tkm", to_xml_encoding( AllTrim( tkm_no ) ) )
   xml_node( "dok", to_xml_encoding( AllTrim( rlabele->evbr ) ) )

   DO WHILE !Eof()

      xml_subnode( "data", .F. )

      xml_node( "id", to_xml_encoding( AllTrim( rlabele->idroba ) )  )
      xml_node( "naz", to_xml_encoding( PadR( AllTrim( rlabele->naz ), len_naz ) ) )
      xml_node( "jmj", to_xml_encoding( AllTrim( rlabele->jmj ) )  )
      xml_node( "bk", to_xml_encoding( AllTrim( rlabele->barkod ) )  )
      xml_node( "c1", AllTrim( Str( rlabele->cijena, 12, 2 ) )  )
      xml_node( "c2", AllTrim( Str( rlabele->scijena, 12, 2 ) )  )

      xml_subnode( "data", .T. )

      SKIP
   ENDDO

   USE

   xml_subnode( "lab", .T. )
   close_xml()

   RETURN .T.


   /*
    Kreira tabelu rLabele u privatnom direktoriju
   */

STATIC FUNCTION cre_open_roba_naljepnice()

   LOCAL aDbf
   LOCAL _tbl
   LOCAL _dbf
   LOCAL _cdx

   SELECT ( F_RLABELE )
   IF Used()
      USE
   ENDIF

   _tbl := "rlabele"
   _dbf := my_home() + my_dbf_prefix() + _tbl + ".dbf"
   _cdx := my_home() + my_dbf_prefix() + _tbl + ".cdx"

   FErase( _dbf )
   FErase( _cdx )

   aDBf := {}
   AAdd( aDBf, { 'idRoba', 'C', 10, 0 } )
   AAdd( aDBf, { 'naz', 'C', 100, 0 } )
   AAdd( aDBf, { 'idTarifa', 'C',  6, 0 } )
   AAdd( aDBf, { 'barkod', 'C', 20, 0 } )
   AAdd( aDBf, { 'evBr', 'C', 10, 0 } )
   AAdd( aDBf, { 'cijena', 'N', 10, 2 } )
   AAdd( aDBf, { 'sCijena', 'N', 10, 2 } )
   AAdd( aDBf, { 'skrNaziv', 'C', 20, 0 } )
   AAdd( aDBf, { 'brojLabela', 'N',  6, 0 } )
   AAdd( aDBf, { 'jmj', 'C',  3, 0 } )
   AAdd( aDBf, { 'katBr', 'C', 20, 0 } )
   AAdd( aDBf, { 'catribut', 'C', 30, 0 } )
   AAdd( aDBf, { 'catribut2', 'C', 30, 0 } )
   AAdd( aDBf, { 'natribut', 'N', 10, 2 } )
   AAdd( aDBf, { 'natribut2', 'N', 10, 2 } )
   AAdd( aDBf, { 'vpc', 'N',  8, 2 } )
   AAdd( aDBf, { 'mpc', 'N',  8, 2 } )
   AAdd( aDBf, { 'porez', 'N',  8, 2 } )

   dbCreate( _dbf, aDbf )

   SELECT ( F_RLABELE )
   my_use_temp( "RLABELE", AllTrim( _dbf ), .F., .T. )

   INDEX ON ( "idroba" ) TAG "1"
   SET ORDER TO TAG "1"

   RETURN NIL
