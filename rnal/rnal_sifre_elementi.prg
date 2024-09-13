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

STATIC art_id
STATIC el_gr_id
STATIC l_auto_tab
STATIC __el_schema
STATIC __box_x
STATIC __box_y

// ----------------------------------------------
// otvara formu za definisanje elemenata
// input: nArt_id - id artikla
// input: nArtType - tip artikla (jednostruko, visestruko...)
// input: cSchema - shema artikla
// output: art_desc update u articles
// ----------------------------------------------
FUNCTION s_elements( nArt_id, lNew, nArtType, cSchema )

   LOCAL i
   LOCAL nX
   LOCAL nY
   LOCAL nRet := 1
   LOCAL cCol2 := "W+/G"
   LOCAL cLineClr := "GR+/B"
   LOCAL cSchClr := "GR+/B"
   LOCAL lRuleRet := .T.
   PRIVATE nEl_id := 0
   PRIVATE nEl_gr_id := 0
   PRIVATE ImeKol
   PRIVATE Kol

   _o_tables()

   __box_x := f18_max_rows() -5
   __box_y := f18_max_cols() -5

   IF lNew == nil
      lNew := .F.
   ENDIF

   IF nArtType == nil
      nArtType := 0
   ENDIF

   art_id := nArt_id
   l_auto_tab := .F.

   __el_schema := "----"

   IF nArtType <> 0
      __el_schema := cSchema
      IF !Empty( cSchema )
         generisi_elemente_iz_sheme( nArt_id, nArtType, cSchema )
      ENDIF
   ENDIF

   Box(, __box_x, __box_y )

   @ box_x_koord(), box_y_koord() + 15 SAY " DEFINISANJE ELEMENATA ARTIKLA: " + artid_str( art_id ) + " "

   @ box_x_koord() + __box_x -1, box_y_koord() + 1 SAY Replicate( hb_UTF8ToStrBox( BROWSE_PODVUCI ), __box_y + 1 ) COLOR cLineClr

   @ box_x_koord() + __box_x -4, box_y_koord() + 1 SAY "<c+N> nova"
   @ box_x_koord() + __box_x -3, box_y_koord() + 1 SAY "<F2> ispravka"
   @ box_x_koord() + __box_x -2, box_y_koord() + 1 SAY8 "<c+T> briši"
   @ box_x_koord() + __box_x, box_y_koord() + 1 SAY "<TAB>-brow.tabela | <ESC> snimi "

   _sh_piccode( __el_schema )

   FOR i := 1 to ( __box_x -2 )
      @ box_x_koord() + i, box_y_koord() + __box_x SAY BROWSE_COL_SEP COLOR cLineClr
   NEXT

   @ box_x_koord() + ( __box_x / 2 ), box_y_koord() + __box_x + 1 SAY Replicate( hb_UTF8ToStrBox( BROWSE_PODVUCI_2 ), ( __box_y - __box_x ) + 1 ) COLOR cLineClr

   SELECT e_att
   GO TOP
   SELECT e_aops
   GO TOP
   SELECT elements
   GO TOP

   box_y_koord( box_y_koord() + __box_x )

   DO WHILE .T.

      IF Alias() == "ELEMENTS"

         // bilo: 16
         nX := __box_x -5
         // bilo: 20
         nY := __box_x -1

         // bilo: 21
         box_y_koord( box_y_koord() - __box_x )

         _say_tbl_desc( box_x_koord() + 1, box_y_koord() + 1, cCol2, "** elementi", 11 )

         elem_kol( @ImeKol, @Kol )

         elem_filter( art_id )

      ELSEIF Alias() == "E_ATT"

         // bilo: 10
         nX := (  __box_x / 2 )
         // bilo: 56
         nY := ( __box_y - __box_x ) + 1

         // bilo: 21
         box_y_koord( box_y_koord() + __box_x )

         _say_tbl_desc( box_x_koord() + 1, box_y_koord() + 1, cCol2, "** atributi", 20 )

         e_att_kol( @ImeKol, @Kol )

         e_att_filter( nEl_id )

      ELSEIF Alias() == "E_AOPS"

         // bilo: 10
         nX := ( __box_x / 2 ) -1

         // bilo: 56
         nY := ( __box_y - __box_x ) + 1

         // bilo: 10
         box_x_koord( box_x_koord() +  __box_x / 2 )

         _say_tbl_desc( box_x_koord() + 1, ;
            box_y_koord() + 1, ;
            cCol2, ;
            "** dod.operacije", ;
            20 )

         e_aops_kol( @ImeKol, @Kol )
         e_aops_filter( nEl_id )

      ENDIF

      my_browse( "elem", nX, nY, {| Ch| elem_hand( Ch ) }, "", "",,,,, 1 )

      aTmp := {}
      nTmpArea := Select()

      rnal_matrica_artikla( art_id, @aTmp )

      SELECT ( nTmpArea )

      IF LastKey() <> K_ESC
         nTmpX := box_x_koord()
         lRuleRet := rule_articles( aTmp )
         box_x_koord( nTmpX )
         SELECT ( nTmpArea )
      ENDIF

      IF Alias() == "ELEMENTS"
         box_x_koord( box_x_koord() - __box_x / 2 )
      ENDIF

      IF LastKey() == K_ESC
         SELECT articles
         nRet := rnal_setuj_naziv_artikla( art_id, lNew )
         SELECT articles
         EXIT
      ENDIF

   ENDDO

   BoxC()

   RETURN nRet


// -----------------------------------------------
// otvaranje grupe tabela za sifrarnik
// -----------------------------------------------
STATIC FUNCTION _o_tables()

   O_E_ATT
   O_E_AOPS
   O_E_GROUPS
   O_ELEMENTS

   RETURN




FUNCTION generisi_elemente_iz_sheme( nArt_id, nArtType, cSchema, nStartFrom )

   LOCAL nTArea := Select()
   LOCAL aSchema
   LOCAL cSep := "-"
   LOCAL nRbr

   IF nStartFrom == nil
      nStartFrom := 0
   ENDIF

   // aschema[1] = G
   // aschema[2] = F
   // aschema[3] = G
   // ......

   aSchema := TokToNiz( cSchema, cSep )


   FOR i := 1 TO Len( aSchema )

      // dodaj element...
      // tipa = aSchema[i] = G ili F ili ????
      SELECT elements

      nRbr := i

      IF nStartFrom > 0
         nRbr += nStartFrom
      ENDIF

      elem_edit( nArt_id, .T., AllTrim( aSchema[ i ] ), nRbr )

   NEXT

   SELECT ( nTArea )

   RETURN cSchema



// ------------------------------------------------------
// provjeri da li su svi atributi elementa uneseni...
// vraca 0 ili 1
// ------------------------------------------------------
STATIC FUNCTION _chk_elements( nArt_id )

   LOCAL nRet := 1
   LOCAL nTArea := Select()
   LOCAL nEl_id := 0

   SELECT elements
   SET ORDER TO TAG "1"
   GO TOP
   SEEK artid_str( art_id )

   DO WHILE !Eof() .AND. field->art_id == nArt_id

      nEl_id := field->el_id

      SELECT e_att
      SET ORDER TO TAG "1"
      GO TOP
      SEEK elid_str( nEl_id )

      DO WHILE !Eof() .AND. field->el_id == nEl_id

         // ako postoji vrijednost ok
         IF field->e_gr_vl_id <> 0

            SELECT e_att
            SKIP
            LOOP

         ENDIF

         // inace izbaci da nije sve ok.

         nRet := 0

         MsgBeep( "Atribut: '" + ;
            AllTrim( g_gr_at_desc( field->e_gr_at_id ) ) + ;
            "' nije definisan !!!" )

         SELECT ( nTArea )
         RETURN nRet

      ENDDO

      SELECT elements
      SKIP
   ENDDO

   SELECT ( nTArea )

   RETURN nRet


// ------------------------------------
// automatski pozovi TAB
// ------------------------------------
STATIC FUNCTION auto_tab()

   IF l_auto_tab == .T.
      KEYBOARD K_TAB
      l_auto_tab := .F.
   ENDIF

   RETURN



// ----------------------------------------------------
// postavlja filter na tabelu ELEMENTS po polju ART_ID
// nArt_id - artikal id
// ----------------------------------------------------
STATIC FUNCTION elem_filter( nArt_id )

   LOCAL cFilter

   cFilter := "art_id == " + artid_str( nArt_id )
   SET FILTER to &cFilter
   GO TOP

   RETURN


// ---------------------------------------------------
// postavlja filter na tabelu E_ATT po polju EL_ID
// nEl_id - element id
// ---------------------------------------------------
STATIC FUNCTION e_att_filter( nEl_id )

   LOCAL cFilter := "el_id == " + elid_str( nEl_id )

   SET FILTER to &cFilter
   GO TOP

   RETURN


// ---------------------------------------------------
// postavlja filter na tabelu E_AOPS po polju EL_ID
// nEl_id - element id
// ---------------------------------------------------
STATIC FUNCTION e_aops_filter( nEl_id )

   LOCAL cFilter := "el_id == " + elid_str( nEl_id )

   SET FILTER to &cFilter
   GO TOP

   RETURN


// -----------------------------------------
// kolone tabele "elements"
// -----------------------------------------
STATIC FUNCTION elem_kol( aImeKol, aKol, nArt_id )

   aKol := {}
   aImeKol := {}

   AAdd( aImeKol, { "rb", {|| el_no }, "el_no", {|| rnal_uvecaj_id( @wEl_id, "EL_ID" ), .F. }, {|| .T. } } )
   AAdd( aImeKol, { PadC( "el.grupa", __box_x ), {|| PadR( g_e_gr_desc( e_gr_id ), __box_x ) }, "e_gr_id" } )

   FOR i := 1 TO Len( aImeKol )
      AAdd( aKol, i )
   NEXT

   RETURN


// -----------------------------------------------
// uvecaj el_no, za elemente artikla
// -----------------------------------------------
STATIC FUNCTION _inc_el_no( wel_no, nArt_id )

   LOCAL nTRec
   LOCAL cTBFilter := dbFilter()

   SET FILTER TO
   SET ORDER TO TAG "1"

   wel_no := _last_elno( nArt_id ) + 1

   SET FILTER to &cTBFilter
   SET ORDER TO TAG "1"

   RETURN .T.


// -------------------------------------------
// vraca posljednji zapis za artikal
// -------------------------------------------
STATIC FUNCTION _last_elno( nArtId )

   LOCAL nLast_rec := 0

   GO TOP
   SEEK artid_str( nArtId ) + Str( 9999, 4 )

   SKIP -1

   IF field->art_id <> nArtId
      nLast_rec := 0
   ELSE
      nLast_rec := field->el_no
   ENDIF

   RETURN nLast_rec


// -----------------------------------------
// kolone tabele "e_att"
// -----------------------------------------
STATIC FUNCTION e_att_kol( aImeKol, aKol )

   aKol := {}
   aImeKol := {}

   AAdd( aImeKol, { PadC( "atribut", 10 ), {|| PadR( g_gr_at_desc( e_gr_at_id, .T. ), 20 ) }, "e_gr_at_id" } )
   AAdd( aImeKol, { PadC( "vrijedost atributa", 30 ), {|| PadR( g_e_gr_vl_desc( e_gr_vl_id ), 30 ) }, "e_gr_vl_id" } )

   FOR i := 1 TO Len( aImeKol )
      AAdd( aKol, i )
   NEXT

   RETURN




// -----------------------------------------
// kolone tabele "e_aops"
// -----------------------------------------
STATIC FUNCTION e_aops_kol( aImeKol, aKol )

   aKol := {}
   aImeKol := {}

   AAdd( aImeKol, { PadC( "dod.operacija", 15 ), {|| PadR( g_aop_desc( aop_id ), 18 ) }, "aop_id" } )
   AAdd( aImeKol, { PadC( "atr.dod.operacije", 20 ), {|| PadR( g_aop_att_desc( aop_att_id ), 32 ) }, "aop_att_id" } )

   FOR i := 1 TO Len( aImeKol )
      AAdd( aKol, i )
   NEXT

   RETURN


// -------------------------------
// convert el_id to string
// -------------------------------
FUNCTION elid_str( nId )
   RETURN Str( nId, 10 )




// -----------------------------------------
// key handler funkcija
// -----------------------------------------
STATIC FUNCTION elem_hand()

   LOCAL nX := box_x_koord()
   LOCAL nY := box_y_koord()
   LOCAL GetList := {}
   LOCAL nRec := RecNo()
   LOCAL nTRec := 0
   LOCAL nRet := DE_CONT

   DO CASE

   CASE l_auto_tab == .T.

      KEYBOARD Chr( K_TAB )
      l_auto_tab := .F.
      RETURN DE_REFRESH

   CASE Ch == K_TAB

      // browse kroz tabele

      IF Alias() == "E_ATT"

         _say_tbl_desc( box_x_koord() + 1, ;
            box_y_koord() + 1, ;
            nil, ;
            "** atributi", ;
            20 )

         SELECT e_aops
         nRet := DE_ABORT

      ELSEIF Alias() == "ELEMENTS"

         IF field->el_id == 0

            MsgBeep( "Nema unesenih elemenata !!!!" )

            nRet := DE_CONT

         ELSE

            _say_tbl_desc( box_x_koord() + 1, ;
               box_y_koord() + 1, ;
               nil, ;
               "** elementi", ;
               11 )


            nEl_id := field->el_id
            el_gr_id := field->e_gr_id

            SELECT e_att
            nRet := DE_ABORT

         ENDIF

      ELSEIF Alias() == "E_AOPS"

         _say_tbl_desc( box_x_koord() + 1, ;
            box_y_koord() + 1, ;
            nil, ;
            "** dod.operacije", ;
            20 )

         SELECT elements

         nRet := DE_ABORT

      ENDIF

   CASE Ch == K_CTRL_N

      // nove stavke

      cTBFilter := dbFilter()

      IF Alias() == "ELEMENTS"

         nRet := DE_REFRESH

         GO BOTTOM

         IF elem_edit( art_id, .T. ) == 1
            l_auto_tab := .T.
         ELSE
            GO TOP
         ENDIF

      ELSEIF Alias() == "E_ATT"

         nRet := DE_REFRESH

         IF e_att_edit( nEl_id, .T. ) == 1
            //
         ELSE
            GO TOP
         ENDIF

      ELSEIF Alias() == "E_AOPS"

         nRet := DE_REFRESH

         IF e_aops_edit( nEl_id, .T. ) == 1
            //
         ELSE
            GO TOP
         ENDIF

      ENDIF

   CASE Ch == K_F2 .OR. Ch == K_ENTER

      // ispravka stavki

      cTBFilter := dbFilter()

      IF Alias() == "ELEMENTS"

         IF Ch == K_ENTER

            Msgbeep( "Opcija onemogucena##Koristiti F2" )
            nRet := DE_CONT

         ELSE
            // ispravka rednog broja elementa...

            nRet := DE_REFRESH

            e_no_edit()

            SET FILTER to &cTbFilter
            GO TOP

         ENDIF

      ELSEIF Alias() == "E_ATT"

         nRet := DE_REFRESH
         e_att_edit( nEl_id, .F. )
         SET FILTER to &cTbFilter
         GO TOP

      ELSEIF Alias() == "E_AOPS"

         nRet := DE_REFRESH
         e_aops_edit( nEl_id, .F. )
         SET FILTER to &cTbFilter
         GO TOP

      ENDIF


   CASE Ch == K_CTRL_T

      // brisanje stavki

      IF Alias() == "ELEMENTS"

         nRet := elem_del()

      ELSEIF Alias() == "E_ATT"

         nRet := e_att_del()

      ELSEIF Alias() == "E_AOPS"

         nRet := e_aops_del()

      ENDIF

   CASE Upper( Chr( Ch ) ) == "C"

      IF Alias() <> "ELEMENTS"
         RETURN DE_CONT
      ENDIF

      nEl_id := field->el_id
      nEl_gr_id := field->e_gr_id

      nRet := el_convert( nEl_id, nEl_gr_id, art_id )


   CASE Upper( Chr( Ch ) ) == "U"

      IF Alias() <> "ELEMENTS"
         RETURN DE_CONT
      ENDIF

      nEl_id := field->el_id
      nEl_gr_id := field->e_gr_id

      nRet := el_restore( nEl_id, nEl_gr_id, art_id )

   ENDCASE


   IF Alias() == "ELEMENTS"
      upd_el_piccode( art_id )
   ENDIF


   box_x_koord( nX )
   box_y_koord( nY )

   RETURN nRet




// -------------------------------------------
// update piccode of article
// -------------------------------------------
STATIC FUNCTION upd_el_piccode( nArt_id )

   LOCAL nTRec := RecNo()
   LOCAL cSchema := ""
   LOCAL cTmp
   LOCAL i := 0
   LOCAL cSep := "-"

   GO TOP
   DO WHILE !Eof() .AND. field->art_id == nArt_id

      i += 1

      cTmp := AllTrim( g_e_gr_desc( field->e_gr_id, nil, .F. ) )

      IF i <> 1
         cSchema += cSep
      ENDIF

      cSchema += cTmp

      SKIP
   ENDDO

   _sh_piccode( cSchema )

   GO ( nTRec )

   RETURN


// ---------------------------------------------
// prikazi piccode na formi unosa
// ---------------------------------------------
STATIC FUNCTION _sh_piccode( cSchema )

   LOCAL _desc_len := 35
   LOCAL nX := __box_x + 1
   LOCAL nY := __box_y - _desc_len
   LOCAL cSchClr := "GR+/B"

   // prvo ocisti
   @ nX, nY SAY Space( _desc_len )

   // ispisi
   @ nX, nY SAY "|"
   @ nX, Col() + 1 SAY "shema: "
   @ nX, Col() + 1 SAY PadR( g_a_piccode( cSchema ), 25 ) ;
      COLOR cSchClr

   RETURN


STATIC FUNCTION el_convert( nEl_id, nEl_gr_id, nArt_id )

   LOCAL nRet := DE_CONT
   LOCAL nEl_no := field->el_no
   LOCAL nX := 1
   LOCAL cSelect := "1"
   LOCAL nFolNr := 1
   LOCAL cGr_code

   cGr_code := AllTrim( g_e_gr_desc( nEl_gr_id, nil, .F. ) )

   IF cGr_code <> AllTrim( gGlassJoker )
      MsgBeep( "Konverzija se vrši samo na elementu tipa staklo !!!" )
      RETURN nRet
   ENDIF

   Box(, 10, 60 )

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "***** konvertovanje stavke artikla"

   nX += 2

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "(1) staklo -> lami staklo sa folijom"

   nX += 2

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "selekcija:" GET cSelect VALID cSelect $ "1"

   READ

   IF cSelect == "1"

      nX += 2

      @ box_x_koord() + nX, box_y_koord() + 2 SAY "broj folija lami stakla:" GET nFolNr PICT "9"

      READ

   ENDIF

   BoxC()

   IF LastKey() == K_ESC
      RETURN DE_CONT
   ENDIF

   IF cSelect == "1"
      rnal_generisi_lamistal_staklo( field->el_no, nFolNr, nArt_id )
      nRet := DE_REFRESH
   ENDIF

   RETURN nRet


STATIC FUNCTION el_restore()

   LOCAL nRet := DE_CONT

   RETURN nRet




// ----------------------------------------------
// ispravka elementa, unos novog elementa
// nArt_id - artikal id
// lNewRec - novi zapis .t. or .f.
// cType - tip elementa, ako postoji automatski
// ga dodaje
// nEl_no - brojac elementa
// ----------------------------------------------
STATIC FUNCTION elem_edit( nArt_id, lNewRec, cType, nEl_no )

   LOCAL nEl_id := 0
   LOCAL nLeft := 30
   LOCAL lAuto := .F.
   LOCAL nRet := DE_CONT
   LOCAL cColor := "BG+/B"
   LOCAL lCoat := .F.
   LOCAL _rec
   PRIVATE GetList := {}

   IF cType == nil
      cType := ""
   ENDIF

   IF !lNewRec .AND. field->el_id == 0
      MsgBeep( "Stavka ne postoji !!!#Koristite c-N da dodate novu!" )
      RETURN DE_REFRESH
   ENDIF

   IF lNewRec

      IF !Empty( cType )
         lAuto := .T.
      ENDIF

      IF setuj_novi_id_tabele( @nEl_id, "EL_ID", lAuto, "FULL" ) == 0
         RETURN 0
      ENDIF

   ENDIF

   set_global_memvars_from_dbf()

   IF lNewRec

      _art_id := nArt_id

      IF Empty( cType )
         // uvecaj redni broj elementa...
         // brojac dbf + sql/par
         _inc_el_no( @_el_no, nArt_id )
      ELSE
         // auto kreiranje zna za brojac
         // necemo koristiti iz baze, da ne opterecujemo rad
         // radi filtera
         _el_no := nEl_no
      ENDIF

      _e_gr_id := 0

   ENDIF

   IF Empty( cType )

      Box(, 7, 60 )

      IF lNewRec
         @ box_x_koord() + 1, box_y_koord() + 2 SAY "Unos novog elementa *******" COLOR cColor
      ELSE
         @ box_x_koord() + 1, box_y_koord() + 2 SAY "Ispravka elementa *******" COLOR cColor
      ENDIF

      @ box_x_koord() + 3, box_y_koord() + 2 SAY PadL( "pozicija (rbr) elementa:", nLeft ) GET _el_no VALID _el_no > 0

      @ box_x_koord() + 5, box_y_koord() + 2 SAY PadL( "element pripada grupi:", nLeft ) GET _e_gr_id VALID s_e_groups( @_e_gr_id, .T. )

      @ box_x_koord() + 6, box_y_koord() + 2 SAY8 PadL( "(0 - otvori šifarnik)", nLeft )

      READ

      BoxC()

   ENDIF

   IF Empty( cType ) .AND. LastKey() == K_ESC .AND. lNewRec

      _rec := get_hash_record_from_global_vars( NIL, .F. )
      delete_rec_server_and_dbf( Alias(), _rec, 1, "FULL" )

      RETURN 0

   ENDIF

   IF !Empty( cType )

      // coating postoji... obrati na to paznju
      IF "*" $ cType
         lCoat := .T.
      ENDIF

      // ukloni "*" ako postoji...
      cType := StrTran( cType, "*", "" )

      _e_gr_id := g_gr_by_type( cType )

   ENDIF

   _rec := get_hash_record_from_global_vars( NIL, .F. )
   update_rec_server_and_dbf( Alias(), _rec, 1, "FULL" )

   IF lNewRec
      nafiluj_atribute_grupe( e_gr_id, nEl_id )
      SELECT elements
   ENDIF

   RETURN 1


// ---------------------------------------------
// ispravka rednog broja elementa
// ---------------------------------------------
STATIC FUNCTION e_no_edit()

   set_global_memvars_from_dbf()

   Box(, 1, 40 )

   @ box_x_koord() + 1, box_y_koord() + 2 SAY "postavi na:" GET _el_no VALID _el_no > 0 PICT "99"
   READ

   BoxC()

   IF LastKey() <> K_ESC
      _rec := get_hash_record_from_global_vars( NIL, .F. )
      update_rec_server_and_dbf( Alias(), _rec, 1, "FULL" )
   ENDIF

   RETURN 1




// ----------------------------------------------------
// filovanje tabele e_att sa atributima grupe
// ako smo odabrali grupu STAKLO, automatski se
// insertuju u E_ATT atributi te grupe, npr:
// - tip
// - debljina
// - vrsta
// ----------------------------------------------------
STATIC FUNCTION nafiluj_atribute_grupe( __gr_id, __el_id )

   LOCAL nTArea := Select()
   LOCAL nEl_att_id := 0
   LOCAL _rec
   LOCAL lAuto := .T.
   LOCAL lOk := .T.
   LOCAL hParams

   run_sql_query( "BEGIN" )

   IF !f18_lock_tables( { "e_att" }, .T. )
      run_sql_query( "ROLLBACK" )
      MsgBeep( "Ne mogu zaključati e_att tabelu !#Prekidam operaciju." )
      RETURN .F.
   ENDIF

   SELECT e_gr_att
   SET ORDER TO TAG "2"
   GO TOP
   SEEK e_gr_id_str( __gr_id ) + "*"

   DO WHILE !Eof() .AND. field->e_gr_id == __gr_id ;
         .AND. field->e_gr_at_re == "*"

      nEl_att_id := 0

      SELECT e_att

      IF setuj_novi_id_tabele( @nEl_att_id, "EL_ATT_ID", lAuto ) == 0
         SELECT e_gr_att
         LOOP
      ENDIF

      _rec := dbf_get_rec()

      _rec[ "el_id" ] := __el_id
      _rec[ "el_att_id" ] := nEl_att_id
      _rec[ "e_gr_at_id" ] := e_gr_att->e_gr_at_id
      _rec[ "e_gr_vl_id" ] := 0

      lOk := update_rec_server_and_dbf( Alias(), _rec, 1, "CONT" )

      IF !lOk
         EXIT
      ENDIF

      SELECT e_gr_att
      SKIP

   ENDDO

   IF lOk
      hParams := hb_Hash()
      hParams[ "unlock" ] := { "e_att" }
      run_sql_query( "COMMIT", hParams )
   ELSE
      run_sql_query( "ROLLBACK" )
   ENDIF

   SELECT ( nTArea )

   RETURN .T.



// ----------------------------------------------
// ispravka atributa elementa, unos novog
// nEl_id - element id
// lNewRec - novi zapis .t. or .f.
// ----------------------------------------------
STATIC FUNCTION e_att_edit( nEl_id, lNewRec )

   LOCAL nLeft := 25
   LOCAL nEl_att_id := 0
   LOCAL cColor := "BG+/B"
   LOCAL cElGrVal := Space( 10 )
   LOCAL _rec
   PRIVATE GetList := {}

   IF !lNewRec .AND. field->el_id == 0

      MsgBeep( "Stavka ne postoji !!!#Koristite c-N da dodate novu!" )
      RETURN DE_REFRESH

   ENDIF

   IF lNewRec
      IF setuj_novi_id_tabele( @nEl_att_id, "EL_ATT_ID", NIL, "FULL" ) == 0
         RETURN 0
      ENDIF
   ENDIF

   set_global_memvars_from_dbf()

   IF lNewRec
      _el_id := nEl_id
      _e_gr_vl_id := 0
      _e_gr_at_id := 0
   ENDIF

   Box(, 6, 65 )

   IF lNewRec
      @ box_x_koord() + 1, box_y_koord() + 2 SAY "Unos novog atributa elementa *******" COLOR cColor
   ELSE
      @ box_x_koord() + 1, box_y_koord() + 2 SAY "Ispravka atributa elementa *******" COLOR cColor
   ENDIF

   @ box_x_koord() + 3, box_y_koord() + 2 SAY PadL( "izaberi atribut elementa", nLeft ) GET _e_gr_at_id VALID {|| s_e_gr_att( @_e_gr_at_id, el_gr_id, nil, .T. ), show_it( g_gr_at_desc( _e_gr_at_id ) ) } WHEN lNewRec == .T.

   @ box_x_koord() + 4, box_y_koord() + 2 SAY PadL( "izaberi vrijednost atributa", nLeft ) GET cElGrVal VALID {|| s_e_gr_val( @cElGrVal, _e_gr_at_id, cElGrVal, .T. ), set_var( @_e_gr_vl_id, @cElGrVal ) }

   @ box_x_koord() + 5, box_y_koord() + 2 SAY8 PadL( "0 - otvori šifarnik", nLeft )

   READ
   BoxC()

   IF LastKey() == K_ESC .AND. lNewRec
      _rec := get_hash_record_from_global_vars( NIL, .F. )
      delete_rec_server_and_dbf( Alias(), _rec, 1, "FULL" )
      RETURN 0
   ENDIF

   _rec := get_hash_record_from_global_vars( NIL, .F. )
   update_rec_server_and_dbf( Alias(), _rec, 1, "FULL" )

   RETURN 1



// ----------------------------------------------
// ispravka operacija elementa, unos novih
// nEl_id - element id
// lNewRec - novi zapis .t. or .f.
// ----------------------------------------------
STATIC FUNCTION e_aops_edit( nEl_id, lNewRec )

   LOCAL nLeft := 25
   LOCAL nEl_op_id := 0
   LOCAL cColor := "BG+/B"
   LOCAL _rec
   PRIVATE GetList := {}

   IF !lNewRec .AND. field->el_id == 0
      Msgbeep( "Stavka ne postoji !!!#Koristite c-N da bi dodali novu!" )
      RETURN DE_REFRESH
   ENDIF

   IF lNewRec
      IF setuj_novi_id_tabele( @nEl_op_id, "EL_OP_ID", NIL, "FULL" ) == 0
         RETURN 0
      ENDIF
   ENDIF

   set_global_memvars_from_dbf()

   IF lNewRec
      _el_id := nEl_id
      _aop_id := 0
      _aop_att_id := 0
   ENDIF

   Box(, 6, 65 )

   IF lNewRec
      @ box_x_koord() + 1, box_y_koord() + 2 SAY "Unos dodatnih operacija elementa *******" COLOR cColor
   ELSE
      @ box_x_koord() + 1, box_y_koord() + 2 SAY "Ispravka dodatnih operacija elementa *******" COLOR cColor
   ENDIF

   @ box_x_koord() + 3, box_y_koord() + 2 SAY PadL( "izaberi dodatnu operaciju", nLeft ) GET _aop_id VALID {|| s_aops( @_aop_id, nil, .T. ), show_it( g_aop_desc( _aop_id ) ) }

   @ box_x_koord() + 4, box_y_koord() + 2 SAY PadL( "izaberi atribut operacije", nLeft ) GET _aop_att_id VALID {|| s_aops_att( @_aop_att_id, _aop_id, nil, .T. ), show_it( g_aop_att_desc( _aop_att_id ) )  }

   @ box_x_koord() + 5, box_y_koord() + 2 SAY8 PadL( "0 - otvori šifarnik", nLeft )

   READ
   BoxC()

   IF LastKey() == K_ESC .AND. lNewRec
      _rec := get_hash_record_from_global_vars( NIL, .F. )
      delete_rec_server_and_dbf( Alias(), _rec, 1, "FULL" )
      RETURN 0
   ENDIF

   _rec := get_hash_record_from_global_vars( NIL, .F. )
   update_rec_server_and_dbf( Alias(), _rec, 1, "FULL" )

   RETURN 1




STATIC FUNCTION elem_del()

   LOCAL _rec

   IF Pitanje(, "Izbrisati stavku (D/N) ?", "N" ) == "N"
      RETURN DE_CONT
   ENDIF

   _rec := dbf_get_rec()
   delete_rec_server_and_dbf( Alias(), _rec, 1, "FULL" )

   RETURN DE_REFRESH



STATIC FUNCTION e_att_del()

   LOCAL _rec

   IF Pitanje(, "Izbrisati stavku (D/N) ?", "N" ) == "N"
      RETURN DE_CONT
   ENDIF

   _rec := dbf_get_rec()
   delete_rec_server_and_dbf( Alias(), _rec, 1, "FULL" )

   RETURN DE_REFRESH



STATIC FUNCTION e_aops_del()

   LOCAL _rec

   IF Pitanje(, "Izbrisati stavku (D/N) ?", "N" ) == "N"
      RETURN DE_CONT
   ENDIF

   _rec := dbf_get_rec()
   delete_rec_server_and_dbf( Alias(), _rec, 1, "FULL" )

   RETURN DE_REFRESH
