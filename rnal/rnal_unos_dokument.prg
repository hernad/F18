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

STATIC l_new
STATIC _doc
STATIC _doc_it
STATIC __item_no
STATIC __art_id
STATIC l_auto_tab
STATIC __dok_x
STATIC __dok_y

// ---------------------------------------------
// edit dokument
// lNewDoc - novi dokument .t. or .f.
// ---------------------------------------------
FUNCTION ed_document( lNewDoc )

   IF lNewDoc == nil
      lNewDoc := .F.
   ENDIF

   l_new := lNewDoc
   // otvori radne i pripremne tabele...
   rnal_o_tables( .T. )
   // otvori unos dokumenta
   _document()

   RETURN



// ---------------------------------------------
// otvara unos novog dokumenta
// ---------------------------------------------
STATIC FUNCTION _document()

   LOCAL cHeader
   LOCAL cFooter
   LOCAL i
   LOCAL nX
   LOCAL nY
   LOCAL nRet := 1
   LOCAL cCol1 := "W/B"
   LOCAL cCol2 := "W+/G"
   PRIVATE ImeKol
   PRIVATE Kol

   // x: 22
   // y: 77

   __dok_x := f18_max_rows() - 5
   __dok_y := f18_max_cols() - 5

   Box(, __dok_x, __dok_y )

   l_auto_tab := .F.

   SELECT _doc_it
   GO TOP
   SELECT _doc_ops
   GO TOP
   SELECT _docs
   GO TOP

   _doc := _docs->doc_no

   // ispisi header i footer
   header_footer()

   // bilo: 50
   box_y_koord( box_y_koord() + __dok_x * 2 )
   // bilo: 6
   box_x_koord( box_x_koord() + 6 )

   DO WHILE .T.

      IF Alias() == "_DOCS"

         nX := 6
         nY := __dok_y + 1

         box_x_koord( box_x_koord() - 6 )
         box_y_koord( box_y_koord() - __dok_x * 2 )

         // prikazi naslov tabele
         _say_tbl_desc( box_x_koord() + 1, box_y_koord() + 1, cCol2,  "*** osnovni podaci", 20 )

         docs_kol( @ImeKol, @Kol )

      ELSEIF Alias() == "_DOC_IT"

         nX := ( __dok_x - 10 )
         nY := ( ( __dok_x * 2 ) - 1 )

         box_x_koord( box_x_koord() + 6 )

         _say_tbl_desc( box_x_koord() + 1, ;
            box_y_koord() + 1, ;
            cCol2, ;
            "*** stavke naloga", ;
            20 )

         docit_kol( @ImeKol, @Kol )

      ELSEIF Alias() == "_DOC_OPS"

         // bilo: 15
         nX := ( __dok_x - 10 )
         // bilo: 28
         nY := ( __dok_y - ( ( __dok_x * 2 ) - 1 ) )
         // bilo: 50
         box_y_koord( box_y_koord() + __dok_x * 2 )

         _say_tbl_desc( box_x_koord() + 1,  box_y_koord() + 1,  cCol2,   "*** dod.oper.",  20 )

         docop_kol( @ImeKol, @Kol )

      ENDIF

      my_browse( "docum", nX, nY, {| Ch| key_handler( Ch ) }, "", "",,,,, 1 )

      IF LastKey() == K_ESC

         IF _docs->doc_status == 3
            MsgBeep( "Dokument ostavljen za doradu !!!" )
         ENDIF

         EXIT

      ENDIF

   ENDDO

   BoxC()

   RETURN nRet


// ---------------------------------------
// prikaz osnovni podaci
// nX - x koord.
// nY - y koord.
// cTxt - tekst
// cColSheme - kolor shema...
// nLeft - poravnanje ulijevo nnn
// ---------------------------------------
FUNCTION _say_tbl_desc( nX, nY, cColSheme, cTxt, nLeft )

   IF nLeft == nil
      nLeft := 20
   ENDIF

   IF cColSheme == nil
      @ nX, nY SAY PadR( cTxt, nLeft )
   ELSE
      @ nX, nY SAY PadR( cTxt, nLeft ) COLOR cColSheme
   ENDIF

   RETURN



// -----------------------------------------------------------------------
// vraca broj dokumenta u pripremi
// -----------------------------------------------------------------------
STATIC FUNCTION get_document_no()
   RETURN "dok.broj:" + PadL( AllTrim( Str ( _doc ) ), 10 )

// ----------------------------------------------------------------------
// prikazuje broj dokumenta u pripremi
// ----------------------------------------------------------------------
STATIC FUNCTION show_document_no()

   @ 2, 3 SAY get_document_no()

   RETURN


STATIC FUNCTION header_footer()

   LOCAL i
   LOCAL nTArea := Select()
   LOCAL cHeader
   LOCAL cFooter
   LOCAL cLineClr := "GR+/B"

   cFooter := "<TAB> brow.tab "
   cFooter += "<c-N> nova "
   cFooter += "<c-T> brisi "
   cFooter += "<F2>  ispravka "
   cFooter += "<c-P> stampa "
   cFooter += "<a-A> ažuriraj"

   cHeader := get_document_no()
   cHeader += Space( 5 )

   IF l_new
      cHeader += "UNOS NOVOG DOKUMENTA"
   ELSE
      cHeader += "DORADA DOKUMENTA"
   ENDIF

   cHeader += Space( 5 )
   cHeader += "operater: "
   cHeader += PadR( AllTrim( f18_user() ), 30 )

   @ box_x_koord(), box_y_koord() + 2 SAY8 cHeader

   @ box_x_koord() + 6, box_y_koord() + 1 SAY Replicate( hb_UTF8ToStrBox(BROWSE_PODVUCI_2), __dok_y + 1 ) COLOR cLineClr

   @ box_x_koord() + __dok_x - 1, box_y_koord() + 1 SAY Replicate( hb_UTF8ToStrBox(BROWSE_PODVUCI), __dok_y + 1 ) COLOR cLineClr

   @ box_x_koord() + __dok_x, box_y_koord() + 1 SAY8 cFooter

   FOR i := 7 to ( __dok_x - 2 )
      @ box_x_koord() + i, box_y_koord() + ( __dok_x * 2 ) SAY BROWSE_COL_SEP COLOR cLineClr
   NEXT

   SELECT ( nTArea )

   RETURN .T.



// ---------------------------------------------
// setuje matricu kolona tabele _DOCS
// ---------------------------------------------
STATIC FUNCTION docs_kol( aImeKol, aKol )

   LOCAL i

   aImeKol := {}
   aKol := {}

   AAdd( aImeKol, { PadC( "Naručioc", 20 ), {|| PadR( g_cust_desc( cust_id ), 18 ) + ".." }, "cust_id" } )
   AAdd( aImeKol, { PadC( "Datum", 8 ), {|| doc_date }, "doc_date", {|| .T. }, {|| .T. } } )
   AAdd( aImeKol, { PadC( "Dat.isp", 8 ), {|| doc_dvr_da }, "doc_dvr_da" } )
   AAdd( aImeKol, { "Vr.isp", {|| PadR( doc_dvr_ti, 5 ) }, "doc_dvr_ti"  } )
   AAdd( aImeKol, { "Mj.isp", {|| PadR( doc_ship_p, 10 ) }, "doc_ship_p" } )
   AAdd( aImeKol, { "Kontakt", {|| PadR( g_cont_desc( cont_id ), 8 ) + ".." }, "cont_id" } )
   AAdd( aImeKol, { "Kont.opis", {|| PadR( cont_add_d, 18 ) + ".." }, "cont_add_d" } )
   AAdd( aImeKol, { "Vrsta p.", {|| doc_pay_id }, "doc_pay_id" } )
   AAdd( aImeKol, { "Prioritet", {|| doc_priori }, "doc_priori" } )
   AAdd( aImeKol, { "Tip", {|| doc_type }, "doc_type" } )

   FOR i := 1 TO Len( aImeKol )
      AAdd( aKol, i )
   NEXT

   RETURN


// ---------------------------------------------
// setuje matricu kolona tabele _DOC_IT
// ---------------------------------------------
STATIC FUNCTION docit_kol( aImeKol, aKol )

   LOCAL i

   aImeKol := {}
   aKol := {}

   AAdd( aImeKol, { "R.br", {|| doc_it_no }, "doc_it_no" } )
   AAdd( aImeKol, { "Artikal", {|| PadR( g_art_desc( art_id, nil, .F. ), 18 ) + ".." }, "art_id" } )
   AAdd( aImeKol, { "sirina", {|| Transform( doc_it_wid, PIC_DIM() ) }, "doc_it_wid" } )
   AAdd( aImeKol, { "visina", {|| Transform( doc_it_hei, PIC_DIM() ) }, "doc_it_hei" } )
   AAdd( aImeKol, { "kol.", {|| Transform( doc_it_qtt, PIC_QTTY() ) }, "doc_it_qtt" } )


   FOR i := 1 TO Len( aImeKol )
      AAdd( aKol, i )
   NEXT

   RETURN


// ---------------------------------------------
// setuje matricu kolona tabele _DOC_OP
// ---------------------------------------------
STATIC FUNCTION docop_kol( aImeKol, aKol )

   LOCAL i

   aImeKol := {}
   aKol := {}

   AAdd( aImeKol, { "dod.oper", {|| PadR( g_aop_desc( aop_id ), 10 ) }, "aop_id" } )
   AAdd( aImeKol, { "atr.dod.oper", {|| PadR( g_aop_att_desc( aop_att_id ), 10 ) }, "aop_att_id" } )
   AAdd( aImeKol, { "dod.opis", {|| PadR( doc_op_des, 13 ) + ".." }, "doc_op_des" } )

   FOR i := 1 TO Len( aImeKol )
      AAdd( aKol, i )
   NEXT

   RETURN


// --------------------------------------------
// --------------------------------------------
STATIC FUNCTION _show_op_item( x, y )

   @ x + ( __dok_x - 10 ), y + 2 SAY "stavka: " + PadR( AllTrim( Str( field->doc_it_no ) ), 10 )

   RETURN .T.


// ---------------------------------------------
// obrada dogadjaja na tipke tastature
// ---------------------------------------------
STATIC FUNCTION key_handler()

   LOCAL nRet := DE_CONT
   LOCAL nX := box_x_koord()
   LOCAL nY := box_y_koord()
   LOCAL GetList := {}
   LOCAL nRec := RecNo()
   LOCAL nDocNoNew := 0
   LOCAL cDesc := ""
   LOCAL nArea, oCsvImport
   LOCAL _art_id, _imported

   IF Alias() == "_DOC_OPS"
      // ispis broja stavke na koju se odnosi operacija
      _show_op_item( nX, nY )
   ENDIF

   DO CASE

      // automatski tab
   CASE l_auto_tab == .T.

      KEYBOARD Chr( K_TAB )
      l_auto_tab := .F.
      RETURN DE_REFRESH

      // browse tabele
   CASE Ch == K_TAB

      IF Alias() == "_DOCS"

         _say_tbl_desc( box_x_koord() + 1, box_y_koord() + 1, ;
            nil, "*** osnovni podaci", 20 )

         SELECT _doc_it
         nRet := DE_ABORT

      ELSEIF Alias() == "_DOC_IT"

         _say_tbl_desc( box_x_koord() + 1, box_y_koord() + 1, ;
            nil, "*** stavke naloga", 20 )

         __art_id := field->art_id
         __item_no := field->doc_it_no

         SELECT _doc_ops
         nRet := DE_ABORT

      ELSEIF Alias() == "_DOC_OPS"

         _say_tbl_desc( box_x_koord() + 1, box_y_koord() + 1, ;
            nil, "*** dod.oper.", 20 )

         SELECT _docs
         nRet := DE_ABORT

      ENDIF

      // nove stavke
   CASE Ch == K_CTRL_N

      nRet := DE_CONT

      IF Alias() == "_DOCS"

         IF rnal_unos_osnovnih_podataka_naloga( .T. ) == 1
            SELECT _docs
            nRet := DE_REFRESH
            l_auto_tab := .T.
         ENDIF

         SELECT _docs

      ELSEIF Alias() == "_DOC_IT"

         SELECT _docs
         IF RECCOUNT2() == 0
            MsgBeep( "Nema definisanog naloga !!!" )
            SELECT _doc_it
            RETURN DE_CONT
         ENDIF

         _doc := field->doc_no
         SELECT _doc_it
         SET ORDER TO TAG "1"

         IF e_doc_item( _doc, .T. ) <> 0

            SELECT _doc_it
            SET ORDER TO TAG "1"
            nRet := DE_REFRESH

         ENDIF

         SELECT _doc_it
         SET ORDER TO TAG "1"

      ELSEIF Alias() == "_DOC_OPS"

         SELECT _docs
         IF RECCOUNT2() == 0
            MsgBeep( "Nema definisanog naloga !!!" )
            SELECT _doc_ops
            RETURN DE_CONT
         ENDIF

         SELECT _doc_ops

         IF e_doc_ops( _doc, .T., __art_id ) <> 0

            SELECT _doc_ops
            nRet := DE_REFRESH

         ENDIF

         SELECT _doc_ops

      ENDIF

   CASE Ch == K_F2 .OR. Ch == K_ENTER

      nRet := DE_CONT

      IF RECCOUNT2() == 0
         RETURN nRet
      ENDIF

      IF Alias() == "_DOCS"

         IF _docs->doc_status == 3

            MsgBeep( "Ispravka osnovnih podataka onemogucena kod dorade#Opcija promjena sluzi u tu svrhu !!!" )
            RETURN DE_CONT

         ENDIF

         IF rnal_unos_osnovnih_podataka_naloga( .F. ) == 1

            SELECT _docs
            nRet := DE_REFRESH

         ENDIF

         SELECT _docs

      ELSEIF Alias() == "_DOC_IT"

         IF e_doc_item( _doc, .F. ) <> 0

            SELECT _doc_it
            nRet := DE_REFRESH

         ENDIF

         SELECT _doc_it

      ELSEIF Alias() == "_DOC_OPS"

         IF e_doc_ops( _doc, .F., __art_id ) <> 0

            SELECT _doc_ops
            nRet := DE_REFRESH

         ENDIF

         SELECT _doc_ops

      ENDIF

   CASE Ch == k_ctrl_f9()

      // brisanje sve iz stavki ili operacija

      nRet := DE_CONT

      IF Alias() == "_DOCS"
         RETURN nRet
      ENDIF

      IF Alias() == "_DOC_IT" .AND. RecCount() > 0
         IF docit_delete_all() == 1
            nRet := DE_REFRESH
         ENDIF
      ELSEIF Alias() == "_DOC_OPS" .AND. RecCount() > 0
         IF docop_delete_all() == 1
            nRet := DE_REFRESH
         ENDIF
      ENDIF


   CASE Ch == K_CTRL_T

      nRet := DE_CONT

      IF Alias() == "_DOCS"

         IF docs_delete() == 1

            l_auto_tab := .T.
            KEYBOARD Chr( K_TAB )
            nRet := DE_REFRESH

         ENDIF

      ELSEIF Alias() == "_DOC_IT"

         IF docit_delete() == 1

            nRet := DE_REFRESH

         ENDIF

      ELSEIF Alias() == "_DOC_OPS"

         IF docop_delete() == 1

            nRet := DE_REFRESH

         ENDIF

      ENDIF

   CASE Upper( Chr( Ch ) ) == "E"
      // export dokumenta
      rnal_export_menu( _docs->doc_no, nil, .T., .T. )
      RETURN DE_CONT

   CASE Upper( Chr( Ch )  ) == "R"

      // promjena rednog broja stavke
      IF Alias() <> "_DOC_IT"
         RETURN DE_CONT
      ENDIF

      IF _change_item_no( field->doc_no, field->doc_it_no )
         RETURN DE_REFRESH
      ENDIF

   CASE Upper( Chr( Ch ) ) == "C"

      // import CSV
      IF Alias() <> "_DOC_IT"
         RETURN DE_CONT
      ENDIF

      oCsvImport := RnalCsvImport():new( _doc )
      IF oCsvImport:import()
         SELECT _doc_it
         GO TOP
         box_x_koord( nX )
         box_y_koord( nY )
         RETURN DE_REFRESH
      ELSE
         SELECT _doc_it
         GO TOP
      ENDIF


   CASE Upper( Chr( Ch ) ) == "S"

      // setovanje artikla za sve stavke
      IF Alias() <> "_DOC_IT"
         RETURN DE_CONT
      ENDIF

      IF Pitanje(, "Postaviti novi artikal za sve stavke (D/N) ?", "D" ) == "D" .AND. set_items_article()
         box_x_koord( nX )
         box_y_koord( nY )
         RETURN DE_REFRESH
      ENDIF


   CASE Upper( Chr( Ch ) ) == "O"

      // promjena rednog broja stavke
      IF Alias() <> "_DOCS"
         RETURN DE_CONT
      ENDIF

      // reset broja dokumenta na "0"
      IF _reset_to_zero()
         SELECT _docs
         GO TOP
         _doc := field->doc_no
         show_document_no()
         RETURN DE_REFRESH
      ENDIF

   CASE Ch == K_ALT_C

      nRet := DE_CONT

      IF Alias() == "_DOC_IT"
         IF rnal_kopiranje_stavki_naloga() <> 0
            nRet := DE_REFRESH
         ENDIF
      ELSE
         MsgBeep( "Za ovu operaciju pozicionirajte se na#unos stavki naloga !!!" )
      ENDIF

      SELECT _doc_it

      box_x_koord( nX )
      box_y_koord( nY )

      RETURN nRet

   CASE Ch == K_ALT_A

      nRet := DE_CONT

      IF Alias() == "_DOCS" .AND. RECCOUNT2() <> 0 .AND. ;
            Pitanje(, "Izvršiti ažuriranje dokumenta (D/N) ?", "D" ) == "D"

         // ima li stavki u nalogu
         IF _doc_integ() == 0
            MsgBeep( "!!! Azuriranje naloga onemoguceno !!!" )
            box_x_koord( nX )
            box_y_koord( nY )
            RETURN DE_CONT
         ENDIF

         IF field->doc_status == 3
            _g_doc_desc( @cDesc )
         ENDIF

         nDocNoNew := _docs->doc_no

         IF rnal_treba_setovati_broj_naloga( @nDocNoNew )
            rnal_set_broj_naloga_u_pripremi( nDocNoNew )
         ENDIF

         IF rnal_azuriraj_dokument( cDesc ) == 1
            SELECT _docs
            l_auto_tab := .T.
            KEYBOARD Chr( K_TAB )
            _doc := 0
            nRet := DE_REFRESH
         ELSE
            SELECT _docs
            l_auto_tab := .T.
            KEYBOARD Chr( K_TAB )
         ENDIF

      ELSEIF Alias() <> "_DOCS"
         Msgbeep( "Pozicionirajte se na tabelu osnovnih podataka" )
      ENDIF

      RETURN nRet

   CASE Ch == K_CTRL_P

      // stampa naloga
      nTArea := Select()
      SELECT _docs

      // ima li stavki u nalogu
      IF _doc_integ( .T. ) == 0
         box_x_koord( nX )
         box_y_koord( nY )
         SELECT ( nTArea )
         RETURN DE_CONT
      ENDIF

      SELECT _docs

      nDocNoNew := _docs->doc_no

      IF rnal_treba_setovati_broj_naloga( @nDocNoNew )
         rnal_set_broj_naloga_u_pripremi( nDocNoNew )
      ENDIF

      SELECT _docs
      GO TOP
      _doc := field->doc_no
      show_document_no()

      stampa_nalog_proizvodnje( .T., _docs->doc_no )

      SELECT ( nTArea )
      GO TOP

      nRet := DE_CONT

   CASE Ch == K_CTRL_O

      // obracunski list......
      nTArea := Select()
      SELECT _docs

      // ima li stavki u nalogu
      IF _doc_integ( .T. ) == 0
         box_x_koord( nX )
         box_y_koord( nY )
         SELECT ( nTArea )
         RETURN DE_CONT
      ENDIF

      SELECT _docs

      nDocNoNew := _docs->doc_no

      IF rnal_treba_setovati_broj_naloga( @nDocNoNew )
         rnal_set_broj_naloga_u_pripremi( nDocNoNew )
      ENDIF

      SELECT _docs
      GO TOP
      _doc := field->doc_no
      show_document_no()

      rnal_stampa_obracunski_list( .T., _docs->doc_no )

      SELECT ( nTArea )
      GO TOP

      nRet := DE_CONT

   CASE Ch == K_CTRL_R

      IF Alias() == "_DOC_IT" .AND. RECCOUNT2() <> 0
         box_it2( field->doc_no, field->doc_it_no )
      ENDIF

      nRet := DE_CONT

   CASE Ch == K_CTRL_L

      nTArea := Select()
      rnal_stampa_naljepnica( .T., _docs->doc_no )
      SELECT ( nTArea )
      nRet := DE_CONT

   ENDCASE

   box_x_koord( nX )
   box_y_koord( nY )

   RETURN nRet


// ---------------------------------------------------
// vraca broj naloga na 0
// ---------------------------------------------------
STATIC FUNCTION _reset_to_zero()

   LOCAL nDbfArea := Select()
   LOCAL _rec, nTrec

   IF Pitanje(, "Resetovati broj dokumenta na 0 (D/N) ?", "N" ) == "N"
      RETURN .F.
   ENDIF

   // 1) _doc_it
   SELECT _doc_it
   SET ORDER TO TAG "1"
   GO TOP
   DO WHILE !Eof()
      SKIP 1
      nTrec := RecNo()
      SKIP -1
      _rec := dbf_get_rec()
      _rec[ "doc_no" ] := 0
      dbf_update_rec( _rec )
      GO ( nTrec )
   ENDDO
   GO TOP

   // 2) _doc_it2
   SELECT _doc_it2
   SET ORDER TO TAG "1"
   GO TOP
   DO WHILE !Eof()
      SKIP 1
      nTrec := RecNo()
      SKIP -1
      _rec := dbf_get_rec()
      _rec[ "doc_no" ] := 0
      dbf_update_rec( _rec )
      GO ( nTrec )
   ENDDO
   GO TOP

   // 3) _doc_ops
   SELECT _doc_ops
   SET ORDER TO TAG "1"
   GO TOP
   DO WHILE !Eof()
      SKIP 1
      nTrec := RecNo()
      SKIP -1
      _rec := dbf_get_rec()
      _rec[ "doc_no" ] := 0
      dbf_update_rec( _rec )
      GO ( nTrec )
   ENDDO
   GO TOP

   // 4) _docs
   SELECT _docs
   SET ORDER TO TAG "1"
   GO TOP
   _rec := dbf_get_rec()
   _rec[ "doc_no" ] := 0
   dbf_update_rec( _rec )

   SELECT ( nDbfArea )

   RETURN .T.




// ---------------------------------------------------
// provjera problematicnih stavki naloga
// ---------------------------------------------------
STATIC FUNCTION _check_orphaned_items()

   LOCAL _ok := .T.
   LOCAL _orph := {}
   LOCAL nDbfArea := Select()
   LOCAL nTrec := RecNo()
   LOCAL _it_no, _doc_no

   // 1) provjera operacija
   SELECT _doc_ops
   SET ORDER TO TAG "1"
   GO TOP

   IF RecCount() > 0

      _doc_no := field->doc_no

      DO WHILE !Eof()
         _it_no := field->doc_it_no
         SELECT _doc_it
         SET ORDER TO TAG "1"
         GO TOP
         SEEK doc_str( _doc_no ) + docit_str( _it_no )
         IF !Found()
            _scan := AScan( _orph, {|val| val[ 2 ] == _it_no } )
            IF _scan == 0
               AAdd( _orph, { _doc_no, _it_no, "operacija" } )
            ENDIF
         ENDIF
         SELECT _doc_ops
         SKIP
      ENDDO
      SELECT _doc_ops
      GO TOP

   ENDIF

   // 2) provjera repromaterijala...
   SELECT _doc_it2
   SET ORDER TO TAG "1"
   GO TOP
   _doc_no := field->doc_no

   DO WHILE !Eof()
      _it_no := field->doc_it_no
      SELECT _doc_it
      SET ORDER TO TAG "1"
      GO TOP
      SEEK doc_str( _doc_no ) + docit_str( _it_no )
      IF !Found()
         _scan := AScan( _orph, {|val| val[ 2 ] == _it_no } )
         IF _scan == 0
            AAdd( _orph, { _doc_no, _it_no, "repromaterijal" } )
         ENDIF
      ENDIF
      SELECT _doc_it2
      SKIP
   ENDDO
   SELECT _doc_it2
   GO TOP

   SELECT _doc_it
   SET ORDER TO TAG "1"
   GO TOP

   SELECT ( nDbfArea )
   GO ( nTrec )

   IF Len( _orph ) > 0
      _show_orphaned_items( _orph )
      _ok := .F.
   ENDIF

   SELECT ( nDbfArea )

   RETURN _ok



STATIC FUNCTION _show_orphaned_items( orph )

   LOCAL _m_x := box_x_koord()
   LOCAL _m_y := box_y_koord()
   LOCAL nI
   LOCAL _tmp
   PRIVATE izbor := 1
   PRIVATE opc := {}
   PRIVATE opcexe := {}
   PRIVATE GetList := {}

   AAdd( opc, PadC( "*** Nepovezane stavke naloga  ( <ESC> - izlaz )", 70 ) )
   AAdd( opcexe, {|| NIL } )
   AAdd( opc, "-" )
   AAdd( opcexe, {|| NIL } )

   FOR nI := 1 TO Len( orph )
      _tmp := PadL( AllTrim( Str( nI ) ) + ")", 4 )
      _tmp += " nepovezana stavka "
      _tmp += AllTrim( orph[ nI, 3 ] ) + " trazi broj: " + PadR( AllTrim( Str( orph[ nI, 2 ] ) ), 10 )
      AAdd( opc, _tmp )
      AAdd( opcexe, {|| NIL } )
   NEXT

   f18_menu_sa_priv_vars_opc_opcexe_izbor( "orph" )

   IF LastKey() == K_ESC
      ch := 0
      izbor := 0
   ENDIF

   box_x_koord( _m_x )
   box_y_koord( _m_y )

   RETURN



// ----------------------------------------
// promjeni redni broj !
// ----------------------------------------
STATIC FUNCTION _change_item_no( docno, docitno )

   LOCAL _ok := .F.
   LOCAL _new_it_no := 0
   LOCAL _rec, nTrec
   LOCAL _m_x, _m_y
   LOCAL _op_count := 0
   LOCAL _it2_count := 0

   _m_x := box_x_koord()
   _m_y := box_y_koord()

   Box(, 2, 60 )
   @ box_x_koord() + 1, box_y_koord() + 2 SAY "*** promjena rednog broja stavke"
   @ box_x_koord() + 2, box_y_koord() + 2 SAY "Broj " + AllTrim( Str( docitno ) ) + " postavi na:" GET _new_it_no ;
      PICT "9999" VALID _change_item_no_valid( _new_it_no, docitno, docno )
   READ
   BoxC()

   box_x_koord( _m_x )
   box_y_koord( _m_y )

   IF LastKey() == K_ESC
      RETURN _ok
   ENDIF

   // 1) promjeni redni broj u stavkama
   SELECT _doc_it
   _rec := dbf_get_rec()
   _rec[ "doc_it_no" ] := _new_it_no
   dbf_update_rec( _rec )

   // 2) promjeni operacije ako ih ima...
   SELECT _doc_ops
   SET ORDER TO TAG "1"
   GO TOP

   DO WHILE !Eof()
      SKIP 1
      nTrec := RecNo()
      SKIP -1
      IF field->doc_it_no == docitno
         ++ _op_count
         _rec := dbf_get_rec()
         _rec[ "doc_it_no" ] := _new_it_no
         dbf_update_rec( _rec )
      ENDIF
      GO ( nTrec )
   ENDDO

   SET ORDER TO TAG "1"
   GO TOP

   // 3) promjeni repromaterijal
   SELECT _doc_it2
   SET ORDER TO TAG "1"
   GO TOP

   DO WHILE !Eof()
      SKIP 1
      nTrec := RecNo()
      SKIP -1
      IF field->doc_it_no == docitno
         ++ _it2_count
         _rec := dbf_get_rec()
         _rec[ "doc_it_no" ] := _new_it_no
         dbf_update_rec( _rec )
      ENDIF
      GO ( nTrec )
   ENDDO

   SET ORDER TO TAG "1"
   GO TOP

   // 4) vrati se na postojecu tabelu stavki...
   SELECT _doc_it

   log_write( "F18_DOK_OPER, promjena rednog broja naloga sa " + AllTrim( Str( docitno ) ) + ;
      " na " + AllTrim( Str( _new_it_no ) ) + ;
      " / broj operacija: " + AllTrim( Str( _op_count ) )  + ;
      " / broj stavki repromaterijala: " + AllTrim( Str( _it2_count ) ), 3 )

   _ok := .T.

   RETURN _ok



STATIC FUNCTION _change_item_no_valid( it_no, it_old, doc_no )

   LOCAL _ok := .F.
   LOCAL nTrec := RecNo()

   IF it_no < 1
      MsgBeep( "Redni broj mora biti > 0 !!!" )
      RETURN _ok
   ENDIF

   IF it_no == it_old
      MsgBeep( "Greška ! Odabran je isti redni broj !" )
      RETURN _ok
   ENDIF

   IF it_no >= 1

      SELECT _doc_it
      GO TOP
      SEEK docno_str( doc_no ) + docit_str( it_no )

      IF Found()
         MsgBeep( "Redni broj " + AllTrim( Str( it_no ) ) + " vec postoji !!!" )
         GO ( nTrec )
         RETURN _ok
      ENDIF

   ENDIF

   GO ( nTrec )
   _ok := .T.

   RETURN _ok



// ----------------------------------------
// vraca box sa opisom
// ----------------------------------------
FUNCTION _g_doc_desc( cDesc )

   LOCAL GetList := {}

   Box( , 5, 70 )
   cDesc := Space( 150 )
   @ box_x_koord() + 1, box_y_koord() + 2 SAY "Unesi opis promjene na nalogu:"
   @ box_x_koord() + 3, box_y_koord() + 2 SAY "Opis:" GET cDesc VALID !Empty( cDesc ) PICT "@S60"
   READ
   BoxC()

   ESC_RETURN 0

   RETURN 1



// -------------------------------------------
// docs - integritet
// -------------------------------------------
STATIC FUNCTION _doc_integ( lPrint )

   LOCAL nTAREA := Select()
   LOCAL nRet := 1
   LOCAL cTmp := ""
   LOCAL nItems := 0
   LOCAL nCustId := 0
   LOCAL nContId := 0

   IF lPrint == nil
      lPrint := .F.
   ENDIF

   SELECT _docs

   nCustId := field->cust_id
   nContId := field->cont_id

   SELECT _doc_it
   nItems := RECCOUNT2()

   // vrati se gdje si bio...
   SELECT ( nTAREA )

   IF lPrint == .F. .AND. ( nItems == 0 .OR. nCustId == 0 .OR. nContId == 0 )
      nRet := 0
   ELSEIF lPrint == .T. .AND. ( nItems == 0 )
      nRet := 0
   ENDIF

   IF nItems == 0
      MsgBeep( "Nalog mora da sadrzi najmanje 1 stavku !" )
   ENDIF

   IF lPrint == .F.
      IF nCustId == 0
         MsgBeep( "Polje naručioca mora biti popunjeno !" )
      ENDIF
      IF nContId == 0
         MsgBeep( "Polje kontakta mora biti popunjeno !!!" )
      ENDIF
   ENDIF

   // provjera nepovezanih stavki naloga...
   IF !_check_orphaned_items()
      nRet := 0
   ENDIF

   RETURN nRet



// --------------------------------------------
// opcija brisanja dokumenta
// lSilent - tihi nacin rada bez upita
// --------------------------------------------
STATIC FUNCTION docs_delete( lSilent )

   LOCAL nDoc_no
   LOCAL nDoc_status
   LOCAL _vals, _id_fields, _where_bl
   LOCAL _it_count := 0
   LOCAL _it2_count := 0
   LOCAL _op_count := 0

   IF lSilent == nil
      lSilent := .F.
   ENDIF

   IF !lSilent .AND. Pitanje(, "Izbrisati nalog iz pripreme (D/N) ?!", "N" ) == "N"
      RETURN 0
   ENDIF

   nDoc_no := field->doc_no
   nDoc_status := field->doc_status

   // 1) brisi dokument
   SELECT _docs
   my_delete_with_pack()

   SELECT _doc_it
   my_dbf_zap()

   // 3) brisi pomocne stavke
   SELECT _doc_it2
   my_dbf_zap()

   // 4) brisi operacije
   SELECT _doc_ops
   my_dbf_zap()

   IF nDoc_status == 3
      // ukloni marker sa azuriranog dokumenta (busy)
      set_doc_marker( nDoc_no, 0 )
   ENDIF

   SELECT _docs
   GO TOP

   RETURN 1



// -------------------------------------------
// brisanje svih zapisa stavki naloga
// -------------------------------------------
STATIC FUNCTION docit_delete_all( lSilent )

   LOCAL _ret := 0
   LOCAL _doc_no

   IF lSilent == NIL
      lSilent := .F.
   ENDIF

   IF !lSilent .AND. Pitanje(, "Izbrisati sve stavke naloga (D/N) ?", "D" ) == "N"
      RETURN _ret
   ENDIF

   SELECT _docs
   _doc_no := field->doc_no

   SELECT _doc_it
   my_dbf_zap()

   SELECT _doc_ops
   my_dbf_zap()

   SELECT _doc_it2
   my_dbf_zap()

   SELECT _doc_it
   GO TOP
   _ret := 1

   RETURN _ret




// --------------------------------------------
// opcija brisanja stavke naloga
// lSilent - tihi nacin rada bez upita
// --------------------------------------------
STATIC FUNCTION docit_delete( lSilent )

   LOCAL nSkip
   LOCAL nDoc_it_no
   LOCAL nDoc_no
   LOCAL _art_id, _qtty
   LOCAL _it2_count := 0
   LOCAL _op_count := 0

   IF lSilent == NIL
      lSilent := .F.
   ENDIF

   IF !lSilent .AND. Pitanje(, "Izbrisati stavku (D/N) ?", "D" ) == "N"
      RETURN 0
   ENDIF

   nDoc_no := field->doc_no
   nDoc_it_no := field->doc_it_no
   _art_id := field->art_id
   _qtty := field->doc_it_qtt

   SELECT _doc_it
   my_delete()


   // 2) brisi operacije
   SELECT _doc_ops
   SET ORDER TO TAG "1"
   GO TOP
   SEEK doc_str( nDoc_no ) + docit_str( nDoc_it_no )

   my_flock()
   DO WHILE !Eof() .AND. field->doc_no == nDoc_no .AND. field->doc_it_no == nDoc_it_no
      SKIP
      nSkip := RECNO()
      SKIP -1
      DELETE
      ++ _op_count
      GO nSkip
   ENDDO
   my_unlock()
   my_dbf_pack()

   // 3) brisi repromaterijal
   IF !lSilent .AND. Pitanje(, "Brisati vezne stavke repromaterijala (D/N) ?", "D" ) == "D"
      SELECT _doc_it2
      SET ORDER TO TAG "1"
      GO TOP
      my_flock()
      SEEK doc_str( nDoc_no ) + docit_str( nDoc_it_no )
      DO WHILE !Eof() .AND. field->doc_no == nDoc_no .AND. field->doc_it_no == nDoc_it_no
         SKIP
         nSkip := RECNO()
         SKIP -1
         DELETE
         ++ _it2_count
         GO nSkip
      ENDDO
      my_unlock()
   ENDIF

   // 5) vrati se na pravo podrucje
   SELECT _doc_it

   log_write( "F18_DOK_OPER, brisanje stavke naloga iz pripreme broj: " + AllTrim( Str( nDoc_no ) ) + ;
      " / stavka broj: " + AllTrim( Str( nDoc_it_no ) ) + ;
      " / kolicina: " + AllTrim( Str( _qtty, 12, 2 ) ) + " / artikal id: " + AllTrim( Str( _art_id ) ) + ;
      " / broj operacija: " + AllTrim( Str( _op_count ) ) + ;
      " / broj stavki repromaterijala: " + AllTrim( Str( _it2_count ) ), 3 )

   MsgBeep( "INFO / brisanje: stavka broj: " + AllTrim( Str( nDoc_it_no ) ) + ;
      "#" + ;
      "artikal id: " + AllTrim( Str( _art_id ) ) + " / kolicina: " + AllTrim( Str( _qtty, 12, 2 ) ) + ;
      "#" + ;
      "broj operacija: " + AllTrim( Str( _op_count ) ) + ;
      "#" + ;
      "broj reprom: " + AllTrim( Str( _it2_count ) ) )

   RETURN 1


// --------------------------------------------
// opcija brisanja operacije
// lSilent - tihi nacin rada bez upita
// --------------------------------------------
STATIC FUNCTION docop_delete( lSilent )

   LOCAL _doc_no, _doc_it_no, _doc_op_no

   IF lSilent == NIL
      lSilent := .F.
   ENDIF

   IF !lSilent .AND. Pitanje(, "Izbrisati stavku (D/N)?", "D" ) == "N"
      RETURN 0
   ENDIF

   _doc_no := field->doc_no
   _doc_it_no := field->doc_it_no
   _doc_op_no := field->doc_op_no

   my_delete_with_pack()


   log_write( "F18_DOK_OPER, brisanje operacije naloga broj: " + AllTrim( Str( _doc_no ) ) + ;
      " / stavka broj: " + AllTrim( Str( _doc_it_no ) ) + ;
      " / broj operacije: " + AllTrim( Str( _doc_op_no ) ), 3 )

   RETURN 1



// -------------------------------------------
// brisanje svih zapisa stavki naloga
// -------------------------------------------
STATIC FUNCTION docop_delete_all( lSilent )

   LOCAL _ret := 0
   LOCAL _doc_no

   IF lSilent == NIL
      lSilent := .F.
   ENDIF

   IF !lSilent .AND. Pitanje(, "Izbrisati sve operacije naloga (D/N) ?", "D" ) == "N"
      RETURN _ret
   ENDIF

   SELECT _docs
   _doc_no := field->doc_no

   SELECT _doc_ops
   my_dbf_zap()
   my_dbf_pack()

   GO TOP

   _ret := 1

   log_write( "F18_DOK_OPER, brisanje svih operacija naloga iz pripreme broj: " + AllTrim( Str( _doc_no ) ), 3 )

   MsgBeep( "INFO / brisanje: pobrisane sve operacije naloga " )

   RETURN _ret




// ------------------------------------------------
// validacija vrijednosti, mora se unjeti
// ------------------------------------------------
FUNCTION must_enter( xVal )

   LOCAL lRet := .T.

   IF ValType( xVal ) == "C"
      IF Empty( xVal )
         lRet := .F.
      ENDIF
   ELSEIF ValType( xVal ) == "N"
      IF xVal == 0
         lRet := .F.
      ENDIF
   ELSEIF ValType( xVal ) == "D"
      IF CToD( "" ) == xVal
         lRet := .F.
      ENDIF
   ENDIF

   msg_must_enter( lRet )

   RETURN lRet


STATIC FUNCTION msg_must_enter( lVal )

   IF lVal == .F.
      MsgBeep( "Unos polja obavezan !" )
   ENDIF

   RETURN
