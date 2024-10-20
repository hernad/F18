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


MEMVAR Ch

STATIC _status
STATIC __sort
STATIC __filter
STATIC _operater

FUNCTION rnal_lista_dokumenata( nStatus )

   _status := nStatus

   rnal_o_tables( .F. )

   rnal_browse_azurirani_nalozi()

   RETURN .T.



STATIC FUNCTION rnal_browse_azurirani_nalozi()

   LOCAL cFooter
   LOCAL cHeader
   LOCAL nSort := 3
   LOCAL nBoxX := f18_max_rows() - 10
   LOCAL nBoxY := f18_max_cols() - 10

   IF lst_args( @nSort ) == 0
      RETURN 0
   ENDIF

   PRIVATE aDocs := {}

   PRIVATE ImeKol
   PRIVATE Kol

   cFooter := "Pregled azuriranih naloga..."
   cHeader := ""

   Box(, nBoxX, nBoxY )

   _set_box( nBoxX, nBoxY )

   _set_sort()

   GO TOP
   set_a_kol( @ImeKol, @Kol )

   SELECT docs

   my_browse( "lstnal", nBoxX, nBoxY, {|| key_handler() }, cHeader, cFooter, , , , , 5 )

   BoxC()

   my_close_all_dbf()

   RETURN 1



STATIC FUNCTION _set_sort()

   LOCAL cSort

   cSort := AllTrim( Str( __sort ) )

   SELECT docs
   SET ORDER TO tag &cSort

   RETURN .T.



STATIC FUNCTION _set_box( nBoxX, nBoxY )

   LOCAL cLine1 := ""
   LOCAL cLine2 := ""

   cLine1 := "(D) dorada nal. "

   IF ( _status == 1 )
      cLine1 += "(Z) zatv.nal. "
      cLine1 += "(P) promjene "
   ENDIF

   cLine1 += "(N) nađi.nal. "
   cLine1 += "(Q) nađi.opis"


   cLine2 := "(c-P) štamp.nal. "
   cLine2 += "(c-O) specif.    "
   cLine2 += "(K) kontakti "
   cLine2 += "(L) promjene"

   @ box_x_koord() + ( nBoxX - 1 ), box_y_koord() + 2 SAY8 cLine1
   @ box_x_koord() + ( nBoxX ), box_y_koord() + 2 SAY8 cLine2

   RETURN .T.



STATIC FUNCTION lst_args( nSort )

   LOCAL nX := 1
   LOCAL nBoxX := 21
   LOCAL nBoxY := 70
   LOCAL dDateFrom := CToD( "" )
   LOCAL dDateTo := danasnji_datum()
   LOCAL dDvrDFrom := CToD( "" )
   LOCAL dDvrDTo := CToD( "" )
   LOCAL cCustomer := PadR( "", 10 )
   LOCAL nCustomer := Val( Str( 0, 10 ) )
   LOCAL cContact := PadR( "", 10 )
   LOCAL cObject := PadR( "", 10 )
   LOCAL nObject := Val( Str( 0, 10 ) )
   LOCAL nContact := Val( Str( 0, 10 ) )
   LOCAL nOperater := Val( Str( 0, 10 ) )
   LOCAL cOperater := PadR( "", 10 )
   LOCAL cShowRejected := "N"
   LOCAL nTip := 0
   LOCAL nRet := 1
   LOCAL cFilter
   LOCAL cColor1 := "BG+/B"
   LOCAL cHelpClr := "GR+/B"

   dDateFrom := fetch_metric( "rnal_preg_nalog_datum_od", my_user(), dDateFrom )
   dDateTo := fetch_metric( "rnal_preg_nalog_datum_do", my_user(), dDateTo )
   dDvrDFrom := fetch_metric( "rnal_preg_nalog_isporuka_od", my_user(), dDvrDFrom )
   dDvrDTo := fetch_metric( "rnal_preg_nalog_isporuka_do", my_user(), dDvrDTo )
   cCustomer := fetch_metric( "rnal_preg_nalog_partner", my_user(), cCustomer )
   cContact := fetch_metric( "rnal_preg_nalog_kontakt", my_user(), cContact )
   cObject := fetch_metric( "rnal_preg_nalog_objekat", my_user(), cObject )
   nOperater := fetch_metric( "rnal_preg_nalog_operater", my_user(), nOperater )
   nSort := fetch_metric( "rnal_preg_nalog_sort", my_user(), nSort )
   cShowRejected := fetch_metric( "rnal_preg_nalog_odbaceni", my_user(), cShowRejected )
   nTip := fetch_metric( "rnal_preg_nalog_tip", my_user(), nTip )

   Box( , nBoxX, nBoxY )

   @ box_x_koord() + nX, box_y_koord() + 1 SAY PadL( "**** uslovi pregleda dokumenata", nBoxY - 2 ) COLOR cColor1

   nX += 2
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 PadL( "Naručioc (prazno-svi):", 25 ) GET cCustomer ;
      VALID {|| Empty( cCustomer ) .OR. ;
      s_customers( @cCustomer, cCustomer ), ;
      set_var( @nCustomer, @cCustomer ),  ;
      show_it( g_cust_desc( nCustomer ) ) } ;
      WHEN set_opc_box( nBoxX, 60, "naručioc naloga, pretraži šifarnik", nil, nil, cHelpClr )

   nX += 1
   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "Kontakt (prazno-svi):", 25 ) GET cContact ;
      VALID {|| Empty( cContact ) .OR. ;
      s_contacts( @cContact, nCustomer, cContact ), ;
      set_var( @nContact, @cContact ), ;
      show_it( g_cont_desc( nContact ) ) } ;
      WHEN set_opc_box( nBoxX, 60, "kontakt osoba naloga, pretraži šifarnik", nil, nil, cHelpClr )

   nX += 1

   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "Objekat isporuke:", 25 ) GET cObject VALID {|| Empty( cObject ) .OR. s_objects( @cObject, nCustomer, cObject ), set_var( @nObject, @cObject ), show_it( g_obj_desc( nObject ) ) } WHEN set_opc_box( nBoxX, 60, "objekat isporuke, pretrazi sifrarnik", nil, nil, cHelpClr )

   nX += 1
   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "Datum naloga od:", 18 ) GET dDateFrom WHEN set_opc_box( nBoxX, 60 )
   @ box_x_koord() + nX, Col() + 1 SAY "do:" GET dDateTo WHEN set_opc_box( nBoxX, 60 )

   IF _status == 1

      nX += 1
      @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "Datum isporuke od:", 18 ) GET dDvrDFrom WHEN set_opc_box( nBoxX, 60 )
      @ box_x_koord() + nX, Col() + 1 SAY "do:" GET dDvrDTo WHEN set_opc_box( nBoxX, 60 )

   ENDIF

   nX += 2
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Operater (prazno-svi):" GET nOperater ;
      PICT "9999999999" ;
      VALID {|| nOperater == 0, iif( nOperater == -99, choose_f18_user_from_list( @nOperater ), .T. ), ;
      show_it( getusername( nOperater ), 30 ) } ;
      WHEN set_opc_box( nBoxX, 60, "pretraga po operateru", "-99 : odaberi iz liste", nil, cHelpClr )

   nX += 1
   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "Tip naloga:", 10 ) GET nTip ;
      VALID nTip >= 0 .AND. nTip < 3 WHEN set_opc_box( nBoxX, 60, "0 - svi nalozi / 1 - samo regularni / 2 - samo NP", nil, nil, cHelpClr ) ;
      PICT "9"

   nX += 2

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "***** sort pregleda:" GET nSort ;
      VALID _val_sort( nSort ) ;
      PICT "9" ;
      WHEN set_opc_box( nBoxX, 60, "način sortiranja pregleda dokumenata", nil, nil, cHelpClr )

   nX += 1
   @ box_x_koord() + nX, box_y_koord() + 2 SAY " * (1) broj dokumenta" COLOR cColor1

   nX += 1
   @ box_x_koord() + nX, box_y_koord() + 2 SAY " * (2) prioritet + datum dokumenta + broj dokumenta" COLOR cColor1

   nX += 1
   @ box_x_koord() + nX, box_y_koord() + 2 SAY " * (3) prioritet + datum isporuke + broj dokumenta" COLOR cColor1

   IF _status == 2

      nX += 2
      @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Prikaz poništenih dokumenata (D/N)?" GET cShowRejected VALID cShowRejected $ "DN" PICT "@!" WHEN set_opc_box( nBoxX, 60, "pored zatvorenih naloga", "prikazi i ponistene", nil, cHelpClr )

   ENDIF

   READ

   BoxC()

   __sort := nSort

   IF LastKey() == K_ESC
      RETURN 0
   ENDIF

   _operater := nOperater

   set_metric( "rnal_preg_nalog_datum_od", my_user(), dDateFrom )
   set_metric( "rnal_preg_nalog_datum_do", my_user(), dDateTo )
   set_metric( "rnal_preg_nalog_isporuka_od", my_user(), dDvrDFrom )
   set_metric( "rnal_preg_nalog_isporuka_do", my_user(), dDvrDTo )
   set_metric( "rnal_preg_nalog_partner", my_user(), cCustomer )
   set_metric( "rnal_preg_nalog_kontakt", my_user(), cContact )
   set_metric( "rnal_preg_nalog_objekat", my_user(), cObject )
   set_metric( "rnal_preg_nalog_operater", my_user(), nOperater )
   set_metric( "rnal_preg_nalog_sort", my_user(), nSort )
   set_metric( "rnal_preg_nalog_odbaceni", my_user(), cShowRejected )
   set_metric( "rnal_preg_nalog_tip", my_user(), nTip )

   cFilter := gen_filter( dDateFrom, ;
      dDateTo, ;
      dDvrDFrom, ;
      dDvrDTo, ;
      nCustomer, ;
      nContact, ;
      nObject, ;
      nOperater, ;
      cShowRejected, ;
      nTip )


   __filter := cFilter

   set_f_kol( cFilter )

   RETURN nRet



STATIC FUNCTION _val_sort( nSort )

   IF nSort >= 1 .AND. nSort <= 3
      RETURN .T.
   ENDIF
   MsgBeep( "Sort je u rangu od 1 do 3 !!!" )

   RETURN .F.



STATIC FUNCTION gen_filter( dDateFrom, dDateTo, dDvrDFrom, dDvrDTo, ;
      nCustomer, nContact, nObject, nOper, cShReject, nTip )

   LOCAL nClosed := 1
   LOCAL cFilter := ""

   IF _status == 1
      cFilter += "(doc_status == 0 .or. doc_status > 2)"
   ELSE
      cFilter += "doc_status == 1"
      IF cShReject == "D"
         cFilter := "( " + cFilter +  " .or. doc_status == 2 )"
      ENDIF

   ENDIF

   IF nTip == 1
      cFilter += ".and. doc_type = '  '"
   ELSEIF nTip == 2
      cFilter += ".and. doc_type = 'NP'"
   ENDIF

   IF !Empty( dDateFrom )
      cFilter += " .and. DTOS(doc_date) >= " + dbf_quote( DToS( dDateFrom ) )
   ENDIF

   IF !Empty( dDateTo )
      cFilter += " .and. DTOS(doc_date) <= " + dbf_quote( DToS( dDateTo ) )
   ENDIF

   IF !Empty( dDvrDFrom )
      cFilter += " .and. DTOS(doc_dvr_da) >= " + dbf_quote( DToS( dDvrDFrom ) )
   ENDIF

   IF !Empty( dDvrDTo )
      cFilter += " .and. DTOS(doc_dvr_da) <= " + dbf_quote( DToS( dDvrDTo ) )
   ENDIF

   IF nCustomer <> 0
      cFilter += " .and. cust_id == " + custid_str( nCustomer )
   ENDIF

   IF nContact <> 0
      cFilter += " .and. cont_id == " + contid_str( nContact )
   ENDIF

   IF nObject <> 0
      cFilter += " .and. obj_id == " + objid_str( nObject )
   ENDIF

   IF nOper <> 0
      cFilter += " .and. operater_i == " + AllTrim( Str( nOper, 10 ) )
   ENDIF

   RETURN cFilter



STATIC FUNCTION set_f_kol( cFilter )

   _set_sort()
   SET FILTER to &cFilter
   GO TOP

   RETURN .T.



STATIC FUNCTION key_handler()

   LOCAL nDoc_no
   LOCAL nDoc_status
   LOCAL cDesc
   LOCAL nTRec
   LOCAL cTmpFilter := dbFilter()

   SELECT docs

   IF _status == 1

      IF doc_status == 5
         _sh_dvr_info( 0, 5 )
      ELSE
         _sh_dvr_warr( _chk_date( doc_dvr_da ), _chk_time( doc_dvr_ti ), 5 )
      ENDIF

   ENDIF

   _sh_doc_status( doc_status )

   _sh_doc_info()

   IF ( _status == 2 )
      IF ( Upper( Chr( Ch ) ) $ "ZP" )
         RETURN DE_CONT
      ENDIF
   ENDIF

   DO CASE

   CASE ( Ch == K_CTRL_P )

      IF Pitanje(, "Štampati nalog (D/N) ?", "D" ) == "D"

         nDoc_no := docs->doc_no
         nTRec := RecNo()

         SET FILTER TO

         stampa_nalog_proizvodnje( .F., nDoc_no )

         SELECT docs

         set_f_kol( cTmpFilter )

         GO ( nTRec )

         RETURN DE_REFRESH
      ENDIF

      SELECT docs
      RETURN DE_CONT

   CASE ( Ch == K_CTRL_O )

      IF Pitanje(, "Štampati specifikaciju (D/N) ?", "D" ) == "D"

         nDoc_no := docs->doc_no
         nTRec := RecNo()

         SET FILTER TO

         rnal_stampa_obracunski_list( .F., nDoc_no, aDocs )
         SELECT docs

         set_f_kol( cTmpFilter )

         GO ( nTRec )
         RETURN DE_REFRESH
      ENDIF

      SELECT docs
      RETURN DE_CONT

   CASE ( Ch == K_CTRL_L )

      IF Pitanje(, "Štampati naljepnice (D/N) ?", "D" ) == "D"

         nDoc_no := docs->doc_no
         nTRec := RecNo()

         SET FILTER TO

         rnal_stampa_naljepnica( .F., nDoc_no )

         SELECT docs
         set_f_kol( cTmpFilter )

         GO ( nTRec )

         RETURN DE_REFRESH
      ENDIF

      SELECT docs
      RETURN DE_CONT

   CASE ( Upper( Chr( Ch ) ) == "K" )

      SELECT docs
      doc_cont_view( docs->doc_no )

      SELECT docs

      RETURN DE_CONT

   CASE ( Upper( Chr( Ch ) ) == "X" )

      SELECT docs
      nDoc_no := docs->doc_no
      IF rnal_promjena_broja_naloga( nDoc_no )
         log_write( "F18_DOK_OPER: rnal, promjena broja naloga, nalog broj: " + AllTrim( Str( nDoc_no ) ), 2 )
         SELECT docs
         RETURN DE_REFRESH
      ENDIF

      RETURN DE_CONT

   CASE ( Upper( Chr( Ch ) ) == "O" )

      otpr_edit( docs->fmk_doc )

      RETURN DE_REFRESH

   CASE ( Upper( Chr( Ch ) ) == "N" )

      SELECT docs

      nRet := qf_nalog()

      SELECT docs

      RETURN nRet

   CASE ( Upper( Chr( Ch ) ) == "A" )

      nScn := AScan( aDocs, {| xVar| xVar[ 1 ] == docs->doc_no } )

      IF nScn == 0

         AAdd( aDocs, { docs->doc_no, AllTrim( g_cust_desc( docs->cust_id ) ) + "/" + ;
            AllTrim( g_cont_desc( docs->cont_id ) ) } )

         Beep( 2 )

         s_ol_status( aDocs )

      ENDIF

      RETURN DE_CONT

   CASE ( Upper( Chr( Ch ) ) == "Y" )

      nScn := AScan( aDocs, {| xVar| xVar[ 1 ] == docs->doc_no } )

      IF nScn <> 0
         aDocs[ nScn, 1 ] := -99
         Beep( 2 )
         s_ol_status( aDocs )
      ENDIF

      RETURN DE_CONT

   CASE ( Upper( Chr( Ch ) ) == "D" )

      IF is_doc_busy()
         msg_busy_doc()
         SELECT docs
         RETURN DE_CONT
      ENDIF

      IF Pitanje(, "Otvoriti nalog radi dorade (D/N) ?", "N" ) == "D"

         nTRec := RecNo()
         nDoc_no := docs->doc_no

         IF doc_2__doc( nDoc_no ) == 1
            MsgBeep( "Nalog otvoren!#Prelazim u pripremu##Pritisni nesto za nastavak..." )
            log_write( "F18_DOK_OPER: rnal, dorada naloga broj: " + AllTrim( Str( nDoc_no ) ), 2 )
         ENDIF

         SELECT docs
         GO ( nTRec )

         ed_document( .F. )

         SELECT docs
         set_f_kol( cTmpFilter )

         RETURN DE_REFRESH
      ENDIF

      SELECT docs
      RETURN DE_CONT

   CASE ( Upper( Chr( Ch ) ) == "Q" )

      cFilt := _quick_srch_()

      IF !Empty( cFilt )
         cFilt := __filter + cFilt
         SELECT docs
         set_f_kol( cFilt )
         SELECT docs
         RETURN DE_REFRESH
      ELSE
         RETURN DE_CONT
      ENDIF

   CASE ( Upper( Chr( Ch ) ) == "Z" )

      IF is_doc_busy()
         msg_busy_doc()
         SELECT docs
         RETURN DE_CONT
      ENDIF

      IF Pitanje(, "Zatvoriti nalog (D/N) ?", "N" ) == "D"

         IF _g_doc_status( @nDoc_status, @cDesc ) == 1

            nTRec := RecNo()
            nDoc_no := docs->doc_no

            set_doc_marker( nDoc_no, nDoc_status )

            logiraj_zatvaranje_naloga( nDoc_no, cDesc, nDoc_status )

            MsgBeep( "Nalog zatvoren !!!" )

            SELECT docs
            set_f_kol( cTmpFilter )
            SELECT docs

            RETURN DE_REFRESH

         ELSE

            MsgBeep( "Setovanje statusa obavezno !" )
            SELECT docs
            RETURN DE_CONT

         ENDIF
      ENDIF

      SELECT docs
      RETURN DE_CONT

   CASE ( Upper( Chr( Ch ) ) == "F" )

      IF Pitanje(, "Resetovati status dokumenta (D/N) ?", "N" ) == "N"
         RETURN DE_CONT
      ENDIF

      IF !spec_funkcije_sifra( "FIXSTAT" )
         RETURN DE_CONT
      ENDIF

      nDoc_no := docs->doc_no
      nTRec := RecNo()
      SET FILTER TO

      set_doc_marker( nDoc_no, 0 )

      log_write( "F18_DOK_OPER: rnal, reset statusa naloga broj: " + AllTrim( Str( nDoc_no ) ) + " na status 0", 2 )

      set_f_kol( cTmpFilter )

      GO ( nTRec )

      RETURN DE_CONT

   CASE ( Upper( Chr( Ch ) ) == "L" )

      nDoc_no := docs->doc_no
      nTRec := RecNo()

      rnal_pregled_loga_za_nalog( nDoc_no )

      SELECT docs
      set_f_kol( cTmpFilter )

      GO ( nTRec )

      RETURN DE_CONT

   CASE Upper( Chr( Ch ) ) == "E"

      nTRec := RecNo()

      nDoc_no := docs->doc_no

      rnal_export_menu( nDoc_no, aDocs, .F., .T. )

      SELECT docs
      set_f_kol( cTmpFilter )

      GO ( nTRec )

      RETURN DE_REFRESH

   CASE ( Upper( Chr( Ch ) ) == "P" )

      nTRec := RecNo()

      IF is_doc_busy()
         msg_busy_doc()
         SELECT docs
         RETURN DE_CONT
      ENDIF

      nDoc_no := docs->doc_no

      m_changes( nDoc_no )

      IF LastKey() == K_ESC
         Ch := 0
      ENDIF

      SELECT docs
      GO ( nTRec )

      RETURN DE_REFRESH

   ENDCASE

   RETURN DE_CONT


STATIC FUNCTION otpr_edit( cValue )

   LOCAL GetList := {}
   LOCAL nX := box_x_koord()
   LOCAL nY := box_y_koord()

   cValue := PadR( cValue, 150 )

   Box(, 1, 50 )
   @ box_x_koord() + 1, box_y_koord() + 2 SAY "Vezni dokumenti:" GET cValue PICT "@S30"
   READ
   BoxC()

   IF LastKey() <> K_ESC
      _rec := dbf_get_rec()
      _rec[ "fmk_doc" ] := cValue
      update_rec_server_and_dbf( Alias(), _rec, 1, "FULL" )
   ENDIF

   box_x_koord( nX )
   box_y_koord( nY )

   RETURN .T.


STATIC FUNCTION s_ol_status( aArr )

   LOCAL cStr := ""
   LOCAL i
   LOCAL n
   LOCAL aStr := {}
   LOCAL cOpt

   IF Len( aArr ) == 0
      cStr := "! prazno !"
   ELSE

      FOR i := 1 TO Len( aArr )

         IF aArr[ i, 1 ] < 0
            LOOP
         ENDIF

         IF !Empty( cStr )
            cStr += ","
         ENDIF

         cStr += AllTrim( Str( aArr[ i, 1 ] ) )
      NEXT
   ENDIF

   cOpt := "A-dodaj Y-brisi: "
   aStr := SjeciStr( cOpt + cStr, f18_max_cols() - 20 )

   @ f18_max_rows() - 7, 5 SAY PadR( "", f18_max_cols() -10 ) COLOR "W/G+"
   @ f18_max_rows() - 6, 5 SAY PadR( "", f18_max_cols() -10 ) COLOR "W/G+"

   FOR n := 1 TO Len( aStr )
      @ f18_max_rows() - 8  + n, 5 SAY aStr[ n ] COLOR "W/G+"
   NEXT

   RETURN .T.




FUNCTION qf_nalog()

   LOCAL GetList := {}
   LOCAL nDoc_no := 0
   LOCAL cFilter := ""

   Box(, 1, 30 )
   @ box_x_koord() + 1, box_y_koord() + 2 SAY8 "Želim pronaci nalog:" GET nDoc_no PICT "999999999"
   READ
   BoxC()

   IF LastKey() == K_ESC .OR. nDoc_no = 0
      RETURN DE_CONT
   ENDIF

   cFilter := "doc_no = " + docno_str( nDoc_no )
   SELECT docs
   SET FILTER to &cFilter
   GO TOP

   RETURN DE_REFRESH


FUNCTION ddor_nal()

   LOCAL GetList := {}
   LOCAL nDoc_no := 0

   Box(, 1, 30 )
   @ box_x_koord() + 1, box_y_koord() + 2 SAY8 "Broj naloga:" GET nDoc_no PICT "999999999"
   READ
   BoxC()

   IF LastKey() == K_ESC .OR. nDoc_no = 0
      RETURN
   ENDIF

   rnal_o_tables( .T. )

   SELECT docs
   GO TOP
   SEEK docno_str( nDoc_no )

   IF is_doc_busy()
      msg_busy_doc()
      SELECT docs
      RETURN
   ENDIF

   IF Pitanje(, "Otvoriti nalog radi dorade (D/N) ?", "N" ) == "D"

      nDoc_no := docs->doc_no

      IF doc_2__doc( nDoc_no ) == 1
         MsgBeep( "Nalog otvoren!#Prelazim u pripremu##Pritisni nesto za nastavak..." )
         log_write( "F18_DOK_OPER: rnal, dorada naloga broj: " + AllTrim( Str( nDoc_no ) ), 2 )
      ENDIF

      SELECT docs

      ed_document( .F. )

      RETURN
   ENDIF

   RETURN



STATIC FUNCTION _quick_srch_()

   LOCAL GetList := {}
   LOCAL nX := 1
   LOCAL cDesc := Space( 150 )

   Box(, 5, 70, .T. )

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Brza pretraga naloga *******"

   nX += 2

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Unesi kratki opis naloga:" GET cDesc PICT "@S40" VALID !Empty( cDesc )

   @ box_x_koord() + nX, Col() SAY ">" COLOR f18_color_i()

   READ
   BoxC()

   IF LastKey() == K_ESC
      xRet := ""
   ELSE
      // formiram filter
      xRet := " .and. "
      xRet += " ( "
      xRet += dbf_quote( Upper( AllTrim( cDesc ) ) )
      xRet += " $ UPPER(doc_sh_desc) "
      xRet += " .or. "
      xRet += dbf_quote( Upper( AllTrim( cDesc ) ) )
      xRet += " $ UPPER(doc_desc) "
      xRet += " ) "
   ENDIF

   RETURN xRet



STATIC FUNCTION msg_busy_doc()

   MsgBeep( "Dokument je zauzet#Operacije onemogucene !!!" )

   RETURN



STATIC FUNCTION _g_doc_status( nDoc_status, cDesc )

   LOCAL cStat := "R"
   LOCAL nX := 1
   LOCAL nBoxX := 11
   LOCAL nBoxY := 60
   LOCAL cColor := "BG+/B"

   Beep( 2 )

   Box(, nBoxX, nBoxY )

   cDesc := Space( 150 )

   nX += 1

   @ box_x_koord() + nX, box_y_koord() + 2 SAY " **** Trenutni status naloga je:" COLOR cColor

   nX += 2

   @ box_x_koord() + nX, box_y_koord() + 2 SAY Space( 3 ) + "(R) realizovan" COLOR cColor

   nX += 1

   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 Space( 3 ) + "(N) realizovan, nije isporučen" COLOR cColor
   nX += 1

   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 Space( 3 ) + "(D) djelimično realizovan" COLOR cColor

   nX += 1

   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 Space( 3 ) + "(X) poništen" COLOR cColor

   nX += 2

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "postavi status na -------->" GET cStat VALID cStat $ "RXDN" PICT "@!"

   nX += 2

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Opis:" GET cDesc VALID !Empty( cDesc ) PICT "@S50"

   READ
   BoxC()


   IF cStat == "R"
      nDoc_status := 1
   ENDIF

   IF cStat == "X"
      nDoc_status := 2
   ENDIF

   IF cStat == "D"
      nDoc_status := 4
   ENDIF

   IF cStat == "N"
      nDoc_status := 5
   ENDIF


   ESC_RETURN 0

   RETURN 1



STATIC FUNCTION __sh_cust( cCust, cCont )

   LOCAL xRet := ""
   LOCAL cTmp
   LOCAL nPadR := 35

   cTmp := AllTrim( cCust )

   IF cTmp == "NN"
      xRet := "(" + cTmp + ")"
      xRet += " "
      xRet += AllTrim( cCont )
   ELSE
      xRet := cTmp
      xRet += "/"
      xRet += AllTrim( cCont )
   ENDIF

   RETURN PadR( xRet, nPadR )



STATIC FUNCTION set_a_kol( aImeKol, aKol, nStatus )

   LOCAL i

   aImeKol := {}


   AAdd( aImeKol, { "Narucioc / kontakt", ;
      {|| __sh_cust( g_cust_desc( cust_id ), g_cont_desc( cont_id ) ) }, ;
      "cust_id", {|| .T. }, {|| .T. } } )

   AAdd( aImeKol, { "Datum", {|| doc_date },  "doc_date", {|| .T. }, {|| .T. } } )

   AAdd( aImeKol, { "Dat.isp.", {|| doc_dvr_da }, "doc_dvr_da", {|| .T. }, {|| .T. } } )

   AAdd( aImeKol, { "Vr.isp.", {|| doc_dvr_ti }, "doc_dvr_ti", {|| .T. }, {|| .T. } } )

   AAdd( aImeKol, { PadC( "Dok.br", 10 ), {|| doc_no }, "doc_no", {|| .T. }, {|| .T. } } )

   IF _operater == 0
      AAdd( aImeKol, { "Operater", {|| PadR( getusername( operater_i ), 10 ) },  "operater_i",  {|| .T. }, {|| .T. } } )
   ENDIF

   AAdd( aImeKol, { "Prioritet", {|| PadR( s_priority( doc_priori ), 10 ) }, "doc_priori", {|| .T. }, {|| .T. } } )

   AAdd( aImeKol, { "Vr.plac", {|| PadR( s_pay_id( doc_pay_id ), 10 ) }, "doc_pay_id", {|| .T. }, {|| .T. } } )

   AAdd( aImeKol, { "Plac.", {|| PadR( doc_paid, 4 ) }, "doc_paid", {|| .T. }, {|| .T. } } )

   AAdd( aImeKol, { "Tip", {|| PadR( doc_type, 2 ) }, "doc_type", {|| .T. },  {|| .T. } } )

   AAdd( aImeKol, { "FMK", {|| fmk_doc }, "fmk_doc", {|| .T. }, {|| .T. } } )

   aKol := {}

   FOR i := 1 TO Len( aImeKol )
      AAdd( aKol, i )
   NEXT

   RETURN .T.


STATIC FUNCTION _chk_date( dD_dvr_date )

   LOCAL nDays := 0

   nDays := danasnji_datum() - dD_dvr_date

   RETURN nDays


STATIC FUNCTION _chk_time( cDvr_time )

   LOCAL nMinutes := 0

   RETURN nMinutes


STATIC FUNCTION _sh_dvr_warr( nDays, nMinutes, nX, nLen )

   LOCAL cColWarr := "W/R+"
   LOCAL cColOk := "GR+/B"
   LOCAL cColor
   LOCAL cTmp

   IF nX == nil
      nX := 2
   ENDIF

   IF nLen == nil
      nLen := 20
   ENDIF

   IF nDays > 0
      cTmp := " van roka " + AllTrim( Str( nDays ) ) + " dana"
      cColor := cColWarr
   ELSE
      cTmp := " u roku"
      cColor := cColOk
   ENDIF

   @ nX, box_y_koord() + 1 SAY PadR( cTmp, nLen ) COLOR cColor

   RETURN .T.



STATIC FUNCTION _sh_dvr_info( nDays, nX, nLen )

   LOCAL cColOk := "GR+/B"
   LOCAL cColor
   LOCAL cTmp := ""

   IF nX == NIL
      nX := 2
   ENDIF

   IF nLen == NIL
      nLen := 20
   ENDIF

   IF nDays > 0
      cTmp := AllTrim( Str( nDays ) ) + " dana"
      cColor := cColOk
      @ nX, box_y_koord() + 1 SAY PadR( cTmp, nLen ) COLOR cColor
   ELSE
      @ nX, box_y_koord() + 1 SAY Space( nLen )
   ENDIF

   RETURN .T.



STATIC FUNCTION _sh_doc_status( doc_status, nX, nY )

   LOCAL cTmp
   LOCAL cDoc_stat
   LOCAL cColor := "GR+/B"

   IF nX == nil
      nX := 5
   ENDIF

   IF nY == nil
      nY := 21
   ENDIF

   cTmp := get_status_dokumenta( doc_status )

   DO CASE

   CASE doc_status == 0

      cColor := "GR+/B"

   CASE doc_status == 1

      cColor := "GB+/B"

   CASE doc_status == 2

      cColor := "W/R+"

   CASE doc_status == 3

      cColor := "GR+/G+"

   CASE doc_status == 4

      cColor := "W/G+"

   CASE doc_status == 5

      cColor := "W/G+"

   ENDCASE

   @ nX, nY SAY8 PadR( cTmp, 20 ) COLOR cColor

   RETURN .T.


FUNCTION get_status_dokumenta( doc_status )

   LOCAL cTmp := ""

   DO CASE

   CASE doc_status == 0
      cTmp := " otvoren"
   CASE doc_status == 1
      cTmp := " realizovan"
   CASE doc_status == 2
      cTmp := " poništen"
   CASE doc_status == 3
      cTmp := " zauzet"
   CASE doc_status == 4
      cTmp := " realizovan dio"
   CASE doc_status == 5
      cTmp := "real.nije isporučen"
   ENDCASE

   RETURN cTmp




STATIC FUNCTION _sh_doc_info( nX, nY )

   LOCAL cTmp
   LOCAL aTmp
   LOCAL nTxtLen := f18_max_cols() - 12
   LOCAL cColor := "GR+/B"

   IF nX == nil
      nX := f18_max_rows() - 11
   ENDIF

   IF nY == nil
      nY := 6
   ENDIF

   cTmp := ""

   cTmp += AllTrim( g_obj_desc( obj_id ) )
   cTmp += ", "
   cTmp += AllTrim( doc_sh_des )

   IF !Empty( cTmp )
      cTmp += ", "
   ENDIF

   cTmp += AllTrim( doc_desc )

   aTmp := SjeciStr( cTmp, nTxtLen )

   @ nX + 1, nY SAY Space( nTxtLen ) COLOR cColor
   @ nX + 2, nY SAY Space( nTxtLen ) COLOR cColor
   @ nX + 3, nY SAY Space( nTxtLen ) COLOR cColor

   FOR i := 1 TO Len( aTmp )
      @ nX + i, nY SAY PadR( aTmp[ i ], nTxtLen ) COLOR cColor
   NEXT

   RETURN


FUNCTION doc_cont_view( nDoc_no )

   LOCAL aCont := {}

   IF _get_doc_contacts( @aCont, nDoc_no ) > 0
      show_c_list( aCont )
   ELSE
      MsgBeep( "Dokument nema kontakata !!!" )
   ENDIF

   RETURN


STATIC FUNCTION _get_doc_contacts( aArr, nDoc_no )

   LOCAL nC_count := 0
   LOCAL nTArea := Select()
   LOCAL cLogType := PadR( "12", 3 )
   LOCAL nSrch := 0
   LOCAL nCont_id := 0

   use_sql_doc_log( nDoc_no, cLogType )
   SET ORDER TO TAG "2"
   GO TOP

   SELECT doc_log
   SET ORDER TO TAG "2"
   GO TOP

   DO WHILE !Eof() .AND. field->doc_no == nDoc_no ;
         .AND. field->doc_log_ty == cLogType

      nDoc_log_no := field->doc_log_no

      use_sql_doc_lit( nDoc_no, nDoc_log_no )
      SEEK docno_str( nDoc_no ) + doclog_str( nDoc_log_no )

      DO WHILE !Eof() .AND. field->doc_no == nDoc_no ;
            .AND. field->doc_log_no == nDoc_log_no

         IF field->int_1 <> 0

            nCont_id := field->int_1

            nSrch := AScan( aArr, {| xVal| xVal[ 1 ] == nCont_id } )
            IF nSrch == 0

               AAdd( aArr, { field->int_1, g_cont_desc( field->int_1 ), g_cont_tel( field->int_1 ) } )

               ++ nC_count
            ENDIF
         ENDIF

         SKIP
      ENDDO

      SELECT doc_log
      SKIP

   ENDDO

   SELECT ( nTArea )

   RETURN nC_count



STATIC FUNCTION show_c_list( aArr )

   LOCAL nX := box_x_koord()
   LOCAL nY := box_y_koord()
   LOCAL nBoxX := Len( aArr ) + 2
   LOCAL nBoxY := 70
   LOCAL i
   LOCAL cGet := " "
   LOCAL lShow := .T.

   IF Len( aArr ) == 0
      RETURN .F.
   ENDIF

   DO WHILE lShow == .T.

      Box( , nBoxX, nBoxY )

      FOR i := 1 TO Len( aArr )

         @ box_x_koord() + i, box_y_koord() + 2 SAY "(" + AllTrim( Str( aArr[ i, 1 ] ) ) + ")"
         @ box_x_koord() + i, Col() + 1 SAY ", " + AllTrim( aArr[ i, 2 ] )

         @ box_x_koord() + i, Col() + 1 SAY ", " + AllTrim( aArr[ i, 3 ] )


      NEXT

      @ box_x_koord() + Len( aArr ) + 1, box_y_koord() + 2 GET cGet

      READ


      BoxC()

      IF LastKey() == K_ENTER .OR. LastKey() == K_ESC
         lShow := .F.
      ENDIF

   ENDDO

   box_x_koord( nX )
   box_y_koord( nY )

   RETURN .T.
