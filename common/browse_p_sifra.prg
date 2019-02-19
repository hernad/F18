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

MEMVAR ImeKol
MEMVAR Ch  // , fID_J
// MEMVAR aAstruct

THREAD STATIC __PSIF_NIVO__ := 0
THREAD STATIC __A_SIFV__ := { { NIL, NIL, NIL }, { NIL, NIL, NIL }, { NIL, NIL, NIL }, { NIL, NIL, NIL } }

STATIC s_lPrviPoziv := .F.

/*
    ImeKol{   {"ID" ... }, { "Naz" ...} }
    p_sifra( F_TIPDOK, cIdVD, -2 ) => vrijednost polja "Naz" za ID == cIdVd
*/

FUNCTION p_sifra( nWa, xIndex, nVisina, nSirina, cNaslov, cID, nDeltaX, nDeltaY,  bBlok, aPoredak, bPodvuci, aZabrane, lInvert, aZabIsp )

   LOCAL cRet, cIdBK
   LOCAL nI
   LOCAL aOpcije := { "<c-N> Novi", "<F2>  Ispravka", "<ENT> Odabir", _to_str( "<c-T> Briši" ), "<c-P> Print", iif( is_mac(), "<X> Export", "<a-E> Export" ), ;
      "<F4>  Dupliciraj", _to_str( "<c-F9> Briši SVE" ), _to_str( "<c-F> Traži" ), "<a-S> Popuni kol.", ;
      "<a-R> Zamjena vrij.", "<c-A> Cirk.ispravka" }
   LOCAL cUslovSrch :=  ""
   LOCAL cNazSrch
   LOCAL cOrderTag
   LOCAL lExit
   LOCAL lExitOnEnter := .F.

   // LOCAL cSeekRet
   LOCAL lOtvoriBrowse := .F.
   LOCAL lRet := .T.

   IF cId != NIL
      lExit := browse_exit_on_enter()
      browse_exit_on_enter( .T. )
      lExitOnEnter := .T.
   ENDIF


   // PRIVATE fID_J := .F.

   IF aZabIsp == nil
      aZabIsp := {}
   ENDIF

   FOR nI := 1 TO Len( aZabIsp )
      aZabIsp[ nI ] := Upper( aZabIsp[ nI ] )
   NEXT

   PushWA()
   PushSifV()

   IF lInvert == NIL
      lInvert := .T.
   ENDIF

   SELECT ( nWa )
   IF !Used()
      MsgBeep( "Tabela nije otvorena u radnom području !#Prekid operacije!" )
      IF lExitOnEnter
         browse_exit_on_enter( lExit )
      ENDIF
      RETURN .F.
   ENDIF

   IF ValType( nDeltaX ) == "N" .AND. nDeltaX < 0 // ako se zada -5 zeli se samo ispis neke kolone, ne browse

      IF !Found()
         GO BOTTOM
         SKIP
         cRet := Eval( ImeKol[ - nDeltaX, 2 ] )
         SKIP -1
      ELSE
         cRet := Eval( ImeKol[ - nDeltaX, 2 ] )
      ENDIF

      PopSifV()
      PopWa( nWa )

      IF lExitOnEnter
         browse_exit_on_enter( lExit )
      ENDIF
      RETURN cRet

   ENDIF

   cOrderTag := ordName( 1 )
   sif_set_order( xIndex, cOrderTag ) // , @fID_j )


   IF p_sifra_da_li_vec_postoji_sifra( @cId, @cIdBK, @cUslovSrch, @cNazSrch ) // , fId_j, cOrderTag )
// IF cSeekRet == "naz" .or. cSeekRet == "sint_konto"
      lOtvoriBrowse := .F.
   ELSE
      lOtvoriBrowse := .T.
   ENDIF

   lRet := .T.

   // IF ( lOtvoriBrowse .AND. ( cNazSrch == "" .OR. !Trim( cNazSrch ) == Trim( field->naz ) ) ) ;
   IF lOtvoriBrowse
      // .OR. cId == NIL .OR. ( !Found() .AND. cNaslov <> NIL ) ;
      // .OR. ( cNaslov <> NIL .AND. Left( cNaslov, 1 ) = "#" )

      s_lPrviPoziv := .T.
      IF Eof()
         SKIP -1
      ENDIF

      IF cId == NIL
         GO TOP // bez parametara
      ENDIF

      lRet := my_browse( NIL, nVisina, nSirina,  {| nCh | my_browse_p_sifra_key_handler( nCh, nWa, cNaslov, bBlok, aZabrane, aZabIsp ) }, ;
         ToStrU( cNaslov ), "", lInvert, aOpcije, 1, bPodvuci, , , aPoredak )

      IF Type( "id" ) $ "U#UE"
         cId := ( nWa )->( FieldGet( 1 ) )
      ELSE

         IF !( nWa )->( Used() )
            Alert( "not used ?!" )
         ENDIF
         cID := ( nWa )->id
         // IF fID_J
         // __A_SIFV__[ __PSIF_NIVO__, 1 ] := ( nWa )->ID_J
         // ENDIF
      ENDIF

   ENDIF
   // ELSE

   // IF fID_J
   // cId := ( nWa )->id
   // __A_SIFV__[ __PSIF_NIVO__, 1 ] := ( nWa )->ID_J
   // ENDIF

   // ENDIF

   __A_SIFV__[ __PSIF_NIVO__, 2 ] := RecNo()

   sifra_ispis_naziva( nWa, nDeltaX, nDeltaY )

   SELECT ( nWa )
   IF Used()
      ordSetFocus( cOrderTag )
      SET FILTER TO
   ENDIF

   PopSifV()
   PopWa( nWa )

   IF lExitOnEnter
      browse_exit_on_enter( lExit )
   ENDIF

   IF ValType( cId ) == "C" .AND. Empty( cId ) .AND. Used() .AND. RecCount() == 0
      RETURN .F. // empty id na praznoj tabeli
   ENDIF

   RETURN lRet



FUNCTION p_sifra_da_li_vec_postoji_sifra( cId, cIdBK, cUslovSrch, cNazSrch ) // , fId_j )

   LOCAL _bk := ""

   // LOCAL _order := IndexOrd()
   LOCAL _tezina := 0


   IF cId == NIL .OR. Empty( cId )
      // RETURN "nil"
      RETURN .F.
   ENDIF

   IF ValType( cId ) != "C" // u RNAL modulu postoje numericke sifre
      RETURN .F.
   ENDIF

   /*
      IF ValType( cId ) == "N"
         SEEK Str( cId )
         //RETURN "num"
         RETURN Found()
      ENDIF
   */

// IF Right( Trim( cId ), 1 ) == "*"
// sif_katbr_zvjezdica( @cId, @cIdBK, fId_j )
// // RETURN "katbr"
// RETURN .F.
// ENDIF


   IF AllTrim( cId ) == "?"
      Box( NIL, 7, 60, .T. )

      @ box_x_koord() + 1, box_y_koord() + 2 SAY8 'Džokeri za pretragu naziv: ".$", id: ">#"'

      @ box_x_koord() + 3, box_y_koord() + 2  SAY8 '"BRI." - naziv počinje sa "BRI" ili "bri"'
      @ box_x_koord() + 4, box_y_koord() + 2  SAY8 '"BRI$" - unutar naziva postoji "BRI"'

      @ box_x_koord() + 6, box_y_koord() + 2  SAY8 '"23>" - id počinje sa "23"'
      @ box_x_koord() + 7, box_y_koord() + 2  SAY8 '"23#" - unutar id-a postoji "23"'
      Inkey( 0 )

      BoxC()
   ENDIF

   IF Right( Trim( cId ), 1 ) $ ".$>#" // . - pocetni dio naziva, $ - unutar naziva, > - pocetni dio sifre, # - unutar sifre
      IF find_sifra_by_naz( Lower( Alias() ), Left( Trim( cId ), Len( Trim( cId ) ) - 1 ), Right( Trim( cId ), 1 ) )
         RETURN .F.
      ENDIF
   ENDIF
   // sifra_na_kraju_ima_tacka_ili_dolar( @cId, @cUslovSrch, @cNazSrch )
   // // RETURN "naz"
   // RETURN .F.
   // ENDIF

   IF Alias() == "ROBA" .AND. Len( cId ) > 10

#ifdef F18_POS
      IF !tezinski_barkod( @cId, @_tezina, .F. )
         barkod_or_roba_id( @cId )
      ENDIF
#else
      barkod_or_roba_id( @cId )
#endif
      // ordSetFocus( _order )
      // RETURN "barkod"

      IF cId == field->id
         RETURN .T.
      ENDIF

   ENDIF

   IF Alias() == "OS" .OR. Alias() == "SII"
      find_os_sii_by_naz_or_id( cId )
   ELSEIF Alias() == "REVAL"
      find_reval_by_id( cId )
   ELSEIF Alias() == "AMORT"
      find_amort_by_id( cId )
   ELSEIF Alias() == "PARTN"
      find_partner_by_naz_or_id( cId )
   ELSEIF Alias() == "ROBA"
      find_roba_by_naz_or_id( cId )
   ELSEIF Alias() == "ROBA_P"
      find_roba_p_by_naz_or_id( cId )
   ELSEIF Alias() == "KONTO"
      find_konto_by_naz_or_id( cId )
   ELSEIF Alias() == "RADN"
      find_radn_by_naz_or_id( cId )
   ELSEIF Alias() == "TARIFA"
      find_tarifa_by_id( cId )
   ELSEIF Alias() == "KONCIJ"
      find_koncij_by_id( cId )
   ELSEIF Alias() == "RJ"
      find_rj_by_id( cId )
   ELSEIF Alias() == "FAKT_FTXT"
      find_fakt_ftxt_by_id( cId )
   ELSEIF Alias() == "TNAL"
      select_o_tnal( cId )
   ELSE
      IF Used() .AND. !Empty( ordKey() )
         SEEK cId
      ENDIF
   ENDIF

   IF !Used() .OR. FieldPos( "id" ) == 0
      RETURN .F.
   ENDIF

   IF field->id == cId .AND. !Empty( cId )  // ako je empty cId - not found
      // cId := &( FieldName( 1 ) )
      IF Alias() == "KONTO" .AND. Len( Trim( cId ) ) < 4 // sinteticki konto
         RETURN .F.
      ENDIF

      RETURN .T.
   ENDIF

   RETURN .F.



FUNCTION find_sifra_by_naz( cTable, cIdPart, cDjoker )

   LOCAL cSqlQuery := "select * from fmk."
   LOCAL cIdSql
   LOCAL cField

   IF cTable == "ftxt"
      cTable := "fakt_ftxt"
   ENDIF

   cSqlQuery += cTable
   cIdSql := sql_quote( Upper( AllTrim( cIdPart ) ) + "%" )


   IF cDjoker $ ".>" // "." - pocetni dio naziva, ">" pocetni dio sifre
      cIdSql := sql_quote( Upper( AllTrim( cIdPart ) ) + "%" ) // NAZ%
   ELSE
      // "$" - unutar naziva,  '#' - unutar sifre
      cIdSql := sql_quote( "%" + Upper( AllTrim( cIdPart ) ) + "%" )  // %NAZ%
   ENDIF
   IF cDjoker $ ".$"
      cField := "naz"
   ELSE
      cField := "id"
   ENDIF
   cSqlQuery += " WHERE " + cField + " ilike " + cIdSql

   IF !use_sql( cTable, cSqlQuery )
      RETURN .F.
   ENDIF
   INDEX ON ID TAG ID
   INDEX ON NAZ TAG NAZ
   SET ORDER TO TAG "ID"

   IF cDjoker $ ".$" // pretraga po nazivu, sortiraj po nazivu
      IF !Empty( ordKey( "NAZ " ) )
         ordSetFocus( "NAZ" )
      ENDIF
   ENDIF

   GO TOP

   RETURN !Eof()


/*
   find_field_by_id( "dopr", "01, "iznos" )
*/
FUNCTION find_field_by_id( cTable, cId, cField )

   LOCAL cSqlQuery := "select " + cField + " from fmk." + cTable

   cSqlQuery += " WHERE id=" + sql_quote( cId )

   IF !use_sql( cTable, cSqlQuery )
      IF !Used()
         RETURN NIL
      ELSE
         RETURN &cField
      ENDIF
   ENDIF

   RETURN &cField


STATIC FUNCTION sif_set_order( xIndex, cOrderTag ) // , fID_j )

   LOCAL nPos

   DO CASE
   CASE ValType( xIndex ) == "N"

      IF xIndex == 1
         ordSetFocus( cOrderTag )
      ELSE

         IF Empty( cOrderTag )
            SET ORDER TO TAG "2"
         ENDIF
      ENDIF

      // CASE ValType( xIndex ) == "C" .AND. Right( Upper( Trim( xIndex ) ), 2 ) == "_J"
//
      // SET ORDER TO TAG ( xIndex )
      // fID_J := .T.

   OTHERWISE

      nPos := At( "_", xIndex )
      IF nPos <> 0
         IF Empty( Left( xIndex, nPos - 1 ) )
            dbSetIndex( SubStr( xIndex, nPos + 1 ) )
         ELSE
            SET ORDER TO TAG ( Left( xIndex, nPos - 1 ) ) IN ( SubStr( xIndex, nPos + 1 ) )
         ENDIF
      ELSE
         SET ORDER TO TAG ( xIndex )
      ENDIF

   END CASE

   RETURN .T.




/*
-- STATIC FUNCTION sif_katbr_zvjezdica( cId, cIdBK, fId_j )

   cId := PadR( cId, 10 )

   IF  FieldPos( "KATBR" ) <> 0
      SET ORDER TO TAG "KATBR"
      SEEK Left( cId, Len( Trim( cId ) ) - 1 )
      cId := id
   ELSE
      SEEK Chr( 250 ) + Chr( 250 ) + Chr( 250 )
   ENDIF

   IF !Found()

      cIdBK := Left( cId, Len( Trim( cId ) ) - 1 )
      cId   := ""

      ImauSifV( "ROBA", "KATB", cIdBK, @cId )

      IF !Empty( cId )

         SELECT roba
         SET ORDER TO TAG "ID"

         SEEK cId
         cId := Id
      --   IF fid_j
            cId := ID_J
            SET ORDER TO TAG "ID_J"
            SEEK cId
         ENDIF

      ENDIF
   ENDIF

   RETURN .T.
*/

/*
FUNCTION sifra_na_kraju_ima_tacka_ili_dolar( cId, cUslovSrch, cNazSrch )

   LOCAL _filter

   cId := PadR( cId, 10 )

   IF !Empty( ordKey( "NAZ " ) )
      ordSetFocus( "NAZ" )
   ELSE
      ordSetFocus( "2" )
   ENDIF


   cNazSrch := ""
   cUslovSrch := ""

   IF Left( Trim( cId ), 1 ) == "."

      PRIVATE GetList := {}

      Box(, 1, 60 )

      cNazSrch := Space( Len( naz ) )
      Beep( 1 )

      @ box_x_koord() + 1, box_y_koord() + 2 SAY "Unesi naziv:" GET cNazSrch PICT "@!S40"
      READ

      BoxC()

      SEEK Trim( cNazSrch )
      cId := field->id


   ELSEIF Right( Trim( cId ), 1 ) == "$"

      _filter := _filter_quote( Left( Upper( cId ), Len( Trim( cId ) ) - 1 ) ) + " $ UPPER(naz)"
      SET FILTER TO
      SET FILTER TO &( _filter )
      GO TOP

   ELSE

      SEEK Left( cId, Len( Trim( cId ) ) - 1 ) // "BRING."" =>  SEEK "BRING" po nazivu

   ENDIF

   RETURN .T.
*/

   /*
   FUNCTION sif_dbf_point_or_slash( cId, nOrdId, cUslovSrch, cNazSrch )

      LOCAL _filter

      cId := PadR( cId, 10 )

      IF index_tag_num( "ID" ) != 0
         SET ORDER TO TAG "NAZ"
      ELSE
         SET ORDER TO TAG "2"
      ENDIF


      cNazSrch := ""
      cUslovSrch := ""

      IF Left( Trim( cId ), 1 ) == "." // SEEK PO NAZ kada se unese DUGACKI DIO


         PRIVATE GetList := {}

         Box(, 1, 70 )

         cNazSrch := Space( Len( naz ) )
         Beep( 1 )

         @ box_x_koord() + 1, box_y_koord() + 2 SAY "Unesi naziv (trazi):" GET cNazSrch PICT "@!S40"
         READ

         BoxC()

         SEEK Trim( cNazSrch )

         cId := field->id

      ELSEIF Right( Trim( cId ), 1 ) == "$"

         // pretraga dijela sifre...
         _filter := _filter_quote( Left( Upper( cId ), Len( Trim( cId ) ) - 1 ) ) + " $ UPPER(naz)"
         SET FILTER TO
         SET FILTER to &( _filter )
         GO TOP

      ELSE

         SEEK Left( cId, Len( Trim( cId ) ) - 1 )

      ENDIF

      RETURN .T.
   */


STATIC FUNCTION my_browse_p_sifra_key_handler( Ch, nWa, cNaslov, bBlok, aZabrane, aZabIsp )

   LOCAL nI
   LOCAL j
   LOCAL imin
   LOCAL imax
   LOCAL nGet
   LOCAL nRet
   LOCAL cOrderTag
   LOCAL nLen
   LOCAL nRed
   LOCAL nKolona
   LOCAL nTekRed
   LOCAL nTrebaRedova
   LOCAL cUslovSrch
   LOCAL lNovi
   LOCAL aStruct

   PRIVATE cPom
   PRIVATE aQQ
   PRIVATE aUsl

   // PRIVATE aStruct

   IF aZabrane = nil
      aZabrane := {}
   ENDIF

   IF aZabIsp = nil
      aZabIsp := {}
   ENDIF

   // Ch := LastKey()
   IF !Used()
      RETURN DE_ABORT
   ENDIF

   aStruct := dbStruct()
   SkratiAZaD ( @aStruct )
   FOR nI := 1 TO Len( aStruct )
      cImeP := aStruct[ nI, 1 ]
      cVar := "w" + cImeP
      PRIVATE &cVar := &cImeP
   NEXT

   cOrderTag := ordName()
   nRet := -1
   lZabIsp := .F.

   IF bBlok <> NIL

      nRet := Eval( bBlok, Ch )
      IF nRet > 4
         IF nRet == 5
            RETURN DE_ABORT

         ELSEIF nRet == 6
            RETURN DE_CONT

         ELSEIF nRet == 7
            RETURN DE_REFRESH

         ELSEIF nRet == 99 .AND. Len( aZabIsp ) > 0
            lZabIsp := .T.
            nRet := -1
         ENDIF
      ENDIF

   ENDIF


   DO CASE

   CASE Ch == K_ENTER

      // IF gPregledSifriIzMenija
      RETURN DE_CONT
      // ELSE
      // s_lPrviPoziv := .F.
      // s_lPrviPoziv := .F.
      // RETURN DE_ABORT
      // ENDIF

#ifdef F18_USE_MATCH_CODE
   CASE Upper( Chr( Ch ) ) == "F"

      IF m_code_src() == 0
         RETURN DE_CONT
      ELSE
         RETURN DE_REFRESH
      ENDIF
#endif
   CASE ( Ch == K_CTRL_N .OR. Ch == K_F4 )

      IF Alias() == "ROBA_P"
         sastavnica_copy()
         RETURN DE_REFRESH
      ENDIF
      Tb:RefreshCurrent()

      IF my_browse_edit_red( Ch, cOrderTag, aZabIsp, .T. )
         // altd() ENTER keystorm
         RETURN DE_REFRESH
      ENDIF

      RETURN DE_CONT

   CASE ( Ch == K_F2 .OR. Ch == K_CTRL_A )

      Tb:RefreshCurrent()
      IF my_browse_edit_red( Ch, cOrderTag, aZabIsp, .F. )
         RETURN DE_REFRESH
      ENDIF

      RETURN DE_CONT

   CASE Ch == K_CTRL_P

      PushWA()
      sifarnik_izbor_polja( Kol, my_home() + Alias() )
      IF LastKey() == K_ESC
         RETURN DE_CONT
      ENDIF

      print_lista( "Pregled: " + AllTrim( cNaslov ) + " na dan " + DToC( Date() ) + " g.", "sifarnik" )
      PopWa()

      RETURN DE_CONT


   CASE Ch == K_ALT_E .OR. ( is_mac() .AND. Upper( Chr( Ch ) ) == "X" )

      PushWA()
      sifarnik_izbor_polja( Kol, my_home() + Alias() )
      IF LastKey() == K_ESC
         RETURN DE_CONT
      ENDIF

      export_sifarnik()
      RETURN DE_ABORT


   CASE Ch == K_ALT_F
      uslovsif()
      RETURN DE_REFRESH

   CASE Ch == K_CTRL_F6

      Box( , 1, 30 )
      PUBLIC gIdFilter := Eval( ImeKol[ TB:ColPos, 2 ] )
      @ box_x_koord() + 1, box_y_koord() + 2 SAY "Filter :" GET gidfilter
      READ
      BoxC()

      IF Empty( gidfilter )
         SET FILTER TO
      ELSE
         SET FILTER TO Eval( ImeKol[ TB:ColPos, 2 ] ) == gIdfilter
         GO TOP
      ENDIF
      RETURN DE_REFRESH

   CASE Ch == K_CTRL_T
      RETURN sifarnik_brisi_stavku()

   CASE Ch == k_ctrl_f9()
      RETURN sifarnik_brisi_sve()

// CASE Ch == K_F10
      // Popup( cOrderTag )
// RETURN DE_CONT

   OTHERWISE
      IF nRet > -1
         RETURN nRet
      ELSE
         RETURN DE_CONT
      ENDIF

   ENDCASE

   RETURN DE_CONT



STATIC FUNCTION my_browse_edit_red( nCh, cOrderTag, aZabIsp, lNovi )

   LOCAL nI
   LOCAL j
   LOCAL _alias
   LOCAL nForJg
   LOCAL imin
   LOCAL imax
   LOCAL nGet
   LOCAL nRet
   LOCAL nLen
   LOCAL nRed
   LOCAL nKolona
   LOCAL nTekRed
   LOCAL nTrebaRedova
   LOCAL oTable
   LOCAL nPrevRecNo
   LOCAL cMCField
   LOCAL nMCScan
   LOCAL _vars
   LOCAL cTekuciZapis
   LOCAL lShowPGroup

   PRIVATE nXP
   PRIVATE nYP
   PRIVATE cPom
   PRIVATE aQQ
   PRIVATE aUsl

   // PRIVATE aStruct

   nPrevRecNo := RecNo()
   cTekuciZapis := vrati_vrijednosti_polja_sifarnika_u_string( "w" )

#ifdef F18_USE_MATCH_CODE
   add_match_code( @ImeKol, @Kol )
#endif
   __A_SIFV__[ __PSIF_NIVO__, 3 ] :=  Ch

   IF Ch == K_CTRL_N .OR. Ch == K_F2
      ordSetFocus( cOrderTag )
      GO ( nPrevRecNo )
   ENDIF

   IF nCh == K_CTRL_N
      lNovi := .T.
      GO BOTTOM
      SKIP 1
   ENDIF

   IF nCh == K_F4
      lNovi := .T.
   ENDIF

   DO WHILE .T.

      set_sif_vars()

      IF nCh == K_CTRL_N
         sifarnik_set_roba_defaults()
      ENDIF

      nTrebaredova := Len( ImeKol )

      FOR nI := 1 TO Len( ImeKol )
         IF Len( ImeKol[ nI ] ) >= 10 .AND. Imekol[ nI, 10 ] <> NIL
            nTrebaRedova--
         ENDIF
      NEXT

      nI := 1
      FOR nForJg := 1 TO 3

         IF nForJg == 1
            Box( NIL, Min( f18_max_rows() - 7, nTrebaRedova ) + 1, f18_max_cols() - 20, .F. )
         ELSE
            BoxCLS()
         ENDIF

         SET CURSOR ON

         PRIVATE Getlist := {}

         nGet := 1
         nNestampati := 0

         nTekRed := 1

         DO WHILE .T.

            lShowPGroup := .F.

            IF Empty( ImeKol[ nI, 3 ] )
               cPom := ""
            ELSE
               cPom := set_w_var( ImeKol, nI, @lShowPGroup )
            ENDIF

            cPic := ""

            IF !Empty( cPom )
               browse_stavka_formiraj_getlist( cPom, @GetList,  lZabIsp, aZabIsp, lShowPGroup, Ch, @nGet, @nI, @nTekRed )
               nGet++
            ELSE
               nRed := 1
               nKolona := 1
               IF Len( ImeKol[ nI ] ) >= 10 .AND. Imekol[ nI, 10 ] <> NIL
                  nKolona := ImeKol[ nI, 10 ]
                  nRed := 0
               ENDIF

               IF nKolona == 1
                  ++nTekRed
               ENDIF
               @ box_x_koord() + nTekRed, box_y_koord() + nKolona SAY8 PadL( AllTrim( ImeKol[ nI, 1 ] ), 15 )
               @ box_x_koord() + nTekRed, Col() + 1 SAY Eval( ImeKol[ nI, 2 ] )

            ENDIF

            nI++
            IF ( Len( ImeKol ) < nI ) .OR. ( nTekRed > Min( f18_max_rows() - 7, nTrebaRedova ) .AND. !( Len( ImeKol[ nI ] ) >= 10 .AND. ImeKol[ nI, 10 ] <> NIL )  )
               EXIT
            ENDIF

         ENDDO

         // SET KEY K_F8 TO k_f8_nadji_novu_sifru()
         SET KEY K_F9 TO sifarnik_f9_nova_sifra()
         // SET KEY K_F5 TO k_f5_nadji_novu_sifru()

         READ

         SET KEY K_F8 TO
         SET KEY K_F9 TO
         SET KEY K_F5 TO

         IF ( Len( ImeKol ) < nI )
            EXIT
         ENDIF

      NEXT

      BoxC()

      IF nCh != K_CTRL_A
         EXIT
      ENDIF

      // slijedi sekcija koja se odnosi na ispravku vise stavki
      IF LastKey() == K_ESC
         EXIT
      ENDIF

      IF !snimi_promjene_cirkularne_ispravke_sifarnika()
         EXIT
      ENDIF

      IF LastKey() == K_PGUP
         SKIP -1
      ELSE
         SKIP
      ENDIF

      IF Eof()
         SKIP -1
         EXIT
      ENDIF

   ENDDO

   IF nCh == K_CTRL_N .OR. nCh == K_F2
      IF !Used()
         RETURN .F.
      ENDIF
      ordSetFocus( cOrderTag )
   ENDIF

   IF LastKey() == K_ESC // prekid operacije
      IF lNovi
         GO ( nPrevRecNo )
      ENDIF
      RETURN .F.
   ENDIF

   browse_snimi_promjene_sifarnika( lNovi, cTekuciZapis )

   IF nCh == K_F4 .AND. Pitanje( , "Vratiti se na predhodni zapis (D/N) ?", "D" ) == "D"
      GO ( nPrevRecNo )
   ENDIF

   ordSetFocus( cOrderTag )

   RETURN .T.



FUNCTION browse_snimi_promjene_sifarnika( lNovi, cTekuciZapis )

   LOCAL lRet := .F.
   LOCAL lOk := .T.
   LOCAL hRec
   LOCAL cAlias := Lower( Alias() )
   LOCAL cEditovaniZapis
   LOCAL lSqlTable
   LOCAL lAppended := .F.
   LOCAL hParams

   lSqlTable := is_sql_table( cAlias )

   hRec := get_hash_record_from_global_vars( "w", .T., .F. ) // uvijek napraviti cp852 enkodiran string
   IF  !begin_sql_tran_lock_tables( { cAlias } )
      RETURN .F.
   ENDIF


   IF lNovi .AND. is_sifra_postoji_u_sifarniku( hRec )
      run_sql_query( "COMMIT" )
      Msgbeep( "Šifra koju želite dodati već postoji u šifarniku !" )
      RETURN lRet
   ENDIF

   IF lNovi
      lAppended := .T.
      APPEND BLANK
   ENDIF

   lOk := update_rec_server_and_dbf( cAlias, hRec, 1, "CONT" )

   IF lOk
      lOk := update_sifk_na_osnovu_ime_kol_from_global_var( ImeKol, "w", lNovi, "CONT" )
   ENDIF

   IF lOk

      lRet := .T.

      hParams := hb_Hash()
      hParams[ "unlock" ] :=  { cAlias }
      run_sql_query( "COMMIT", hParams )
      log_write( "F18_DOK_OPER: dodavanje/ispravka zapisa u sifarnik " + cAlias, 2 )

   ELSE

      run_sql_query( "ROLLBACK" )

      IF lNovi .AND. lAppended
         // brisi DBF zapis koji smo prvobitno dodali
         delete_with_rlock()
      ENDIF

      log_write( "F18_DOK_OPER: greska kod dodavanja/ispravke zapisa u sifarnik " + cAlias, 2 )
      MsgBeep( "Greška kod dodavanja/ispravke šifre !#Operacija prekinuta." )

   ENDIF

   set_global_vars_from_dbf( "w" )

   IF lRet
      cEditovaniZapis := vrati_vrijednosti_polja_sifarnika_u_string( "w" )
      IF cEditovaniZapis <> cTekuciZapis
         log_write( "F18_DOK_OPER: " + ;
            iif( lNovi, "NOVI", "EDIT" ) + " TBL: " + cAlias + ;
            iif( !lNovi, " OLD: " + cTekuciZapis, "" ) + " NEW: " + cEditovaniZapis, 2 )
      ENDIF
   ENDIF

   RETURN lRet



FUNCTION snimi_promjene_cirkularne_ispravke_sifarnika()

   LOCAL _vars, _alias
   LOCAL lRet := .F.
   LOCAL lOk := .T.
   LOCAL lSqlTable
   LOCAL hParams

   lSqlTable := is_sql_table( Alias() )

   _vars := get_hash_record_from_global_vars( "w", NIL, .F. )
   // _vars := get_hash_record_from_global_vars( "w", NIL, lSqlTable )
   _alias := Lower( Alias() )

   IF !begin_sql_tran_lock_tables( { _alias  } )
      RETURN .F.
   ENDIF


   lOk := update_rec_server_and_dbf( _alias, _vars, 1, "CONT" )
   IF lOk
      lOk := update_sifk_na_osnovu_ime_kol_from_global_var( ImeKol, "w", Ch == K_CTRL_N, "CONT" )
   ENDIF

   IF lOk
      lRet := .T.
      hParams := hb_Hash()
      hParams[ "unlock" ] :=  { _alias }
      run_sql_query( "COMMIT", hParams )

      log_write( "F18_DOK_OPER: cirkularna ispravka sifarnika " + _alias, 2 )
   ELSE
      run_sql_query( "ROLLBACK" )
      log_write( "F18_DOK_OPER: greška sa cirkularnom ispravkom sifarnika " + _alias, 2 )
      MsgBeep( "Greška sa operacijom cirkularne ispravke !#Operacija prekinuta." )
   ENDIF

   set_global_vars_from_dbf( "w", .F. )

   RETURN lRet




STATIC FUNCTION set_w_var( aImeKol, nI, lShowGrupa )

   LOCAL _tmp, cVariableName

   IF Left( aImeKol[ nI, 3 ], 6 ) != "SIFK->"

      cVariableName := "w" + aImeKol[ nI, 3 ]

   ELSE

      IF Alias() == "PARTN" .AND. Right( aImeKol[ nI, 3 ], 4 ) == "GRUP"
         lShowGrupa := .T.
      ENDIF

      cVariableName := "wSifk_" + SubStr( aImeKol[ nI, 3 ], 7 )

      _tmp := get_sifk_sifv( Alias(), SubStr( aImeKol[ nI, 3 ], 7 ) )

      IF _tmp == NIL
         cVariableName := ""
      ELSE
         __mvPublic( cVariableName )
         Eval( MemVarBlock( cVariableName ), _tmp )
      ENDIF

   ENDIF

   RETURN cVariableName




#ifdef F18_USE_MATCH_CODE
STATIC FUNCTION add_match_code( ImeKol, Kol )

   LOCAL  _pos, cMCField := Alias()

   IF ( cMCField )->( FieldPos( "MATCH_CODE" ) ) <> 0

      _pos := AScan( ImeKol, {| xImeKol | Upper( xImeKol[ 3 ] ) == "MATCH_CODE" } )

      IF _pos == 0
         AAdd( ImeKol, { "MATCH_CODE", {|| match_code }, "match_code" } )
         AAdd( Kol, Len( ImeKol ) )
      ENDIF

   ENDIF

   RETURN .T.
#endif

/*
   vraca naziv polja + vrijednost za tekuci alias
   cMarker = "w" ako je Scatter("w")
*/

FUNCTION vrati_vrijednosti_polja_sifarnika_u_string( cMarker )

   LOCAL cRet := ""
   LOCAL nI
   LOCAL cFName
   LOCAL xFVal
   LOCAL cFVal
   LOCAL cType

   FOR nI := 1 TO FCount()

      cFName := AllTrim( Field( nI ) )

      xFVal := FieldGet( nI )

      cType := ValType( xFVal )

      IF cType == "C"
         cFVal := AllTrim( xFVal )
      ELSEIF cType == "N"
         cFVal := AllTrim( Str( xFVal, 12, 2 ) )
      ELSEIF cType == "D"
         cFVal := DToC( xFVal )
      ENDIF

      cRet += cFName + "=" + cFVal + "#"
   NEXT

   RETURN cRet




STATIC FUNCTION set_sif_vars()

   LOCAL nI, _struct
   PRIVATE cImeP
   PRIVATE cVar

   _struct := dbStruct()

   SkratiAZaD( @_struct )

   FOR nI := 1 TO Len( _struct )
      cImeP := _struct[ nI, 1 ]
      cVar := "w" + cImeP

      &cVar := &cImeP
   NEXT

   RETURN .T.


FUNCTION sifarnik_set_roba_defaults()

   IF Alias() <> "ROBA"
      RETURN .F.
   ENDIF

   wIdtarifa := PadR( "PDV17", 6 )

   RETURN .T.

/*

STATIC FUNCTION Popup( cOrderTag )

   LOCAL opc := {}
   LOCAL opcexe := {}
   LOCAL Izbor

   AAdd( Opc, "1. novi                  " )
   AAdd( opcexe, {|| my_browse_edit_red( K_CTRL_N, cOrderTag, NIL, .T. ) } )
   AAdd( Opc, "2. edit  " )
   AAdd( opcexe, {|| my_browse_edit_red( K_F2, cOrderTag, NIL, .F. ) } )
   AAdd( Opc, "3. dupliciraj  " )
   AAdd( opcexe, {|| my_browse_edit_red( K_F4, cOrderTag, NIL, .T. ) } )
   AAdd( Opc, "4. <a+R> za sifk polja  " )
   AAdd( opcexe, {|| repl_sifk_item() } )
   AAdd( Opc, "5. copy polje -> sifk polje  " )
   AAdd( opcexe, {|| copy_to_sifk() } )

   Izbor := 1
   f18_menu( "bsif", .F., izbor, opc, opcexe )

   RETURN 0
*/

// -------------------------------------------
// sredi uslov ako nije postavljeno ; na kraj
// -------------------------------------------
STATIC FUNCTION _fix_usl( xUsl )

   LOCAL nLenUsl := Len( xUsl )
   LOCAL xRet := Space( nLenUsl )

   IF Empty( xUsl )
      RETURN xUsl
   ENDIF

   IF Right( AllTrim( xUsl ), 1 ) <> ";"
      xRet := PadR( AllTrim( xUsl ) + ";", nLENUSL )
   ELSE
      xRet := xUsl
   ENDIF

   RETURN xRet




FUNCTION sifarnik_brisi_stavku()

   LOCAL hRecDbf, hRec, cAlias
   LOCAL lOk
   LOCAL hParams

   IF Pitanje( , "Želite li izbrisati ovu stavku (D/N) ?", "D" ) == "N"
      RETURN DE_CONT
   ENDIF

   cAlias := Lower( Alias() )

   IF !begin_sql_tran_lock_tables( { cAlias } )
      RETURN DE_CONT
   ENDIF

   PushWA()
   hRecDbf := dbf_get_rec()
   hRec := hRecDbf
   lOk := delete_rec_server_and_dbf( cAlias, hRecDbf, 1, "CONT" )

   IF programski_modul() != "POS" // POS ne koristi sifk, sifv
      IF lOk .AND. Alias() != "SIFK" .AND. hb_HHasKey( hRecDbf, "id" )
         o_sifk_sifv_empty()
         hRec := hb_Hash()
         hRec[ "id" ]    := PadR( cAlias, 8 )
         hRec[ "idsif" ] := PadR( hRecDbf[ "id" ], 15 )
         lOk := delete_rec_server_and_dbf( "sifv", hRec, 3, "CONT" )
      ENDIF
   ENDIF

   IF lOk
#ifdef F18_DEBUG
      MsgBeep( "table " + cAlias  + " updated and locked" )
#endif
      hParams := hb_Hash()
      hParams[ "unlock" ] :=  { cAlias }
      run_sql_query( "COMMIT", hParams )
      log_write( "F18_DOK_OPER: brisanje stavke iz sifarnika, stavka " + pp( hRec ), 2 )
   ELSE
      run_sql_query( "ROLLBACK" )
      log_write( "F18_DOK_OPER: greška sa brisanjem stavke iz sifarnika", 2 )
      MsgBeep( "Greška sa brisanjem zapisa iz šifarnika !#Operacija prekinuta." )
   ENDIF

   PopWa()

   IF lOk
      RETURN DE_REFRESH
   ENDIF

   RETURN DE_CONT



FUNCTION sifarnik_brisi_sve()

   PushWA()

   IF Pitanje( , "Želite li sigurno izbrisati SVE zapise (D/N) ?", "N" ) == "N"
      RETURN DE_CONT
   ENDIF

   Beep( 6 )

   IF Pitanje( , "Ponavljam : izbrisati BESPOVRATNO kompletan šifarnik (D/N) ?", "N" ) == "D"

      IF delete_all_dbf_and_server( Alias() )
         log_write( "F18_DOK_OPER: brisanje kompletnog sifarnika " + Alias(), 2 )
      ENDIF

      PopWa()

   ENDIF

   RETURN DE_REFRESH



STATIC FUNCTION PushSifV()

   __PSIF_NIVO__++
   IF __PSIF_NIVO__ > Len( __A_SIFV__ )
      AAdd( __A_SIFV__, { "", 0, 0 } )
   ENDIF

   RETURN .T.



STATIC FUNCTION PopSifV()

   --__PSIF_NIVO__

   RETURN .T.







/*
   Opis: funkcija ispituje da li šifra postoji na serveru
 */

FUNCTION is_sifra_postoji_u_sifarniku( hTekuciRec )

   LOCAL lRet := .F.
   LOCAL cAlias := Alias()
   LOCAL hTblRec := get_a_dbf_rec( cAlias, .T. )
   LOCAL cTable, cWhere

   IF ValType( hTblRec ) <> "H"
      RETURN .F.
   ENDIF

   IF hTblRec[ "temp" ]
      RETURN .F.
   ENDIF

   cTable := hTblRec[ "table" ]
   IF Left( cTable, 4 ) <>  F18_PSQL_SCHEMA + "."
      cTable := F18_PSQL_SCHEMA + "." + cTable
   ENDIF

   cWhere := napravi_where_uslov_na_osnovu_hash_matrica( hTblRec, hTekuciRec )

   IF Empty( cWhere )
      RETURN lRet
   ENDIF

   IF table_count( cTable, cWhere ) > 0
      lRet := .T.
   ENDIF

   RETURN lRet



STATIC FUNCTION napravi_where_uslov_na_osnovu_hash_matrica( hTblRec, hRec )

   LOCAL cSqlFields, aDbfFields, nI, aTmp
   LOCAL cWhere := ""
   LOCAL cTmp := ""

   cSqlFields := hTblRec[ "algoritam" ][ 1 ][ "sql_in" ]
   aDbfFields := hTblRec[ "algoritam" ][ 1 ][ "dbf_key_fields" ]

   IF cSqlFields == NIL .OR. Empty( cSqlFields )
      RETURN cWhere
   ENDIF

   IF aDbfFields == NIL .OR. Len( aDbfFields ) == 0
      RETURN cWhere
   ENDIF

   FOR nI := 1 TO Len( aDbfFields )
      IF ValType( aDbfFields[ nI ] ) == "A"
         aTmp := aDbfFields[ nI ]
         cTmp += Str( hRec[ aTmp[ 1 ] ], aTmp[ 2 ], 0 )
      ELSE
         cTmp += hRec[ aDbfFields[ nI ] ]
      ENDIF
   NEXT

   IF Empty( cTmp )
      RETURN cWhere
   ENDIF

   cWhere := cSqlFields
   cWhere += " = "
   cWhere += sql_quote( cTmp )

   RETURN cWhere



FUNCTION k_f5_nadji_novu_sifru()

   LOCAL cPom
   LOCAL cPom2
   LOCAL nOrder
   LOCAL nDuz

   PRIVATE cK1 := ""
   PRIVATE cImeVar := ""
   PRIVATE cNumDio := ""

   IF Alias() <> "ROBA" .OR.  FieldPos( "K1" ) == 0 .OR. !( ( cImeVar := ReadVar() ) == "WID" ) .OR. !Empty( cK1 := Space( Len( K1 ) ) ) .OR. !VarEdit( { { "Unesite K1", "cK1",, "@!", } }, 10, 23, 14, 56, "Odredjivanje nove sifre artikla", "B5" )
      RETURN ( NIL )
   ENDIF
   cNumDio := my_get_from_ini( "ROBA", "NumDio", "SUBSTR(ID,7,3)", SIFPATH )
   cPom2   := &( cImeVar )
   nDuz    := Len( cPom2 )
   cPom2   := RTrim( cPom2 )
   cPom    := cK1 + Chr( 255 )
   PushWA()

   nOrder := index_tag_num( "BROBA" )
   IF nOrder = 0
      MsgBeep( "Ako ste u mrezi, svi korisnici moraju napustiti FMK. Zatim pritisnite Enter!" )
      MsgO( "Kreiram tag(index) 'BROBA'" )
      cSort := my_get_from_ini( "ROBA", "Sort", "K1+SUBSTR(ID,7,3)", SIFPATH )
      INDEX ON &cSort TAG BROBA
      MsgC()
   ENDIF
   SET ORDER TO TAG "BROBA"
   GO TOP
   SEEK cPom
   SKIP -1
   cNumDio := &cNumDio
   IF K1 == cK1
      &( cImeVar ) := PadR( cPom2 + PadL( AllTrim( Str( Val( cNumDio ) + 1 ) ), Len( cNumDio ), "0" ), nDuz )
   ELSE
      &( cImeVar ) := PadR( cPom2 + PadL( "1", Len( cNumDio ), "0" ), nDuz )
   ENDIF

   wk1 := cK1
   AEval( GetList, {| o | o:display() } )
   PopWA()
   KEYBOARD Chr( K_END )

   RETURN ( NIL )






// ----------------------------------------------------
// nadji novu sifru - radi na pritisak F8 pri unosu
// nove sifre
// ----------------------------------------------------
FUNCTION k_f8_nadji_novu_sifru()

   LOCAL cPom
   LOCAL nDuzSif := 0
   LOCAL lPopuni := .F.
   LOCAL nDuzUn := 0
   LOCAL cLast := Chr( 252 ) + Chr( 253 )
   LOCAL nKor := 0

   IF my_get_from_ini( "NovaSifraOpc_F8", "PopunjavaPraznine", "N" ) == "D"
      lPopuni := .T.
   ENDIF

   // ime polja
   PRIVATE cImeVar := ReadVar()
   // vrijednost unjeta u polje
   cPom := &( cImeVar )

   IF cImeVar == "WID"

      nDuzSif := Len( cPom )
      nDuzUn := Len( Trim( cPom ) )
      cPom := PadR( RTrim( cPom ), nDuzSif, "Z" )

      PushWA()

      IF index_tag_num( "ID" ) != 0
         SET ORDER TO TAG "ID"
      ELSE
         SET ORDER TO TAG "1"
      ENDIF

      GO TOP
      IF lPopuni
         SEEK Left( cPom, nDuzUn )
         DO WHILE !Eof() .AND. Left( cPom, 2 ) = Left( id, 2 )
            // preskoci stavke opisa grupe artikala
            IF Len( Trim( id ) ) <= nDuzUn .OR. Right( Trim( id ), 1 ) == "."
               SKIP 1
            ENDIF
            IF cLast == "¬¦æÑ" // tj. prva konkretna u nizu
               IF Val( SubStr( id, nDuzUn + 1 ) ) > 1
                  // rupa odmah na poetku
                  nKor := nDuzSif - Len( Trim( id ) )
                  EXIT
               ENDIF
            ELSEIF Val( SubStr( id, nDuzUn + 1 ) ) - Val( cLast ) > 1
               // rupa izmeÐu
               EXIT
            ENDIF
            cLast := SubStr( id, nDuzUn + 1 )
            SKIP 1
         ENDDO
         // na osnovu cLast formiram slijedeu çifru
         cPom := Left( cPom, nDuzUn ) + IF( cLast == "¬¦æÑ", REPL( "0", nDuzSif - nDuzUn - nKor ), cLast )
         &( cImeVar ) := PadR( NovaSifra( IF( Empty( cPom ), cPom, RTrim( cPom ) ) ), nDuzSif, " " )
      ELSE

         SEEK cPom
         SKIP -1
         &( cImeVar ) := PadR( NovaSifra( IF( Empty( id ), id, RTrim( id ) ) ), nDuzSif, " " )

      ENDIF

      AEval( GetList, {| o | o:display() } )
      PopWA()
   ENDIF

   RETURN ( NIL )





FUNCTION UslovSif()

   LOCAL aStruct := dbStruct()
   LOCAL nPos

   SkratiAZaD( @aStruct )

   Box( "", iif( Len( aStruct ) > 22, 22, Len( aStruct ) ), 67, .F., "", "Postavi kriterije za pretrazivanje" )

   PRIVATE Getlist := {}

   //
   // postavljanje uslova
   //
   aQQ := {}
   aUsl := {}

   IF "U" $ Type( "aDefSpremBaz" )
      aDefSpremBaz := NIL
   ENDIF

   IF aDefSpremBaz != NIL .AND. !Empty( aDefSpremBaz )
      FOR nI := 1 TO Len( aDefSpremBaz )
         aDefSpremBaz[ nI, 4 ] := ""
      NEXT
   ENDIF

   SET CURSOR ON


#ifndef F18_USE_MATCH_CODE
   nPos :=   AScan( aStruct, {| aItem | aItem[ 1 ] == "MATCH_CODE" } )
   IF nPos > 0
      ADel( aStruct, nPos )
      ASize( aStruct, Len( aStruct ) - 1 )
   ENDIF
#endif

   FOR nI := 1 TO Len( aStruct )

      IF nI == 23
         @ box_x_koord() + 1, box_y_koord() + 1 CLEAR TO box_x_koord() + 22, box_y_koord() + 67
      ENDIF
      AAdd( aQQ, Space( 100 ) )
      AAdd( aUsl, NIL )
      @ box_x_koord() + IF( nI > 22, nI - 22, nI ), box_y_koord() + 67 SAY Chr( 16 )
      @ box_x_koord() + IF( nI > 22, nI - 22, nI ), box_y_koord() + 1 SAY PadL( AllTrim( aStruct[ nI, 1 ] ), 15 ) GET aQQ[ nI ] PICTURE "@S50" ;
         VALID {|| aUsl[ nI ] := Parsiraj( aQQ[ nI ] := _fix_usl( aQQ[ nI ] ), aStruct[ nI, 1 ], iif( aStruct[ nI, 2 ] == "M", "C", aStruct[ nI, 2 ] ) ), aUsl[ nI ] <> NIL  }
      READ
      IF LastKey() == K_ESC
         EXIT
      ELSE
         IF aDefSpremBaz != NIL .AND. !Empty( aDefSpremBaz ) .AND. aUsl[ nI ] <> NIL .AND. ;
               aUsl[ nI ] <> ".t."
            FOR j := 1 TO Len( aDefSpremBaz )
               IF Upper( aDefSpremBaz[ j, 2 ] ) == Upper( aStruct[ nI, 1 ] )
                  aDefSpremBaz[ j, 4 ] := aDefSpremBaz[ j, 4 ] + ;
                     IF( !Empty( aDefSpremBaz[ j, 4 ] ), ".and.", "" ) + ;
                     IF( Upper( aDefSpremBaz[ j, 2 ] ) == Upper( aDefSpremBaz[ j, 3 ] ), aUsl[ nI ], ;
                     Parsiraj( aQQ[ nI ] := _fix_usl( aQQ[ nI ] ), aDefSpremBaz[ j, 3 ], iif( aStruct[ nI, 2 ] == "M", "C", aStruct[ nI, 2 ] ) ) )
               ENDIF
            NEXT
         ENDIF
      ENDIF
   NEXT
   READ
   BoxC()
   IF LastKey() == K_ESC; RETURN DE_CONT; ENDIF
   aOKol := AClone( Kol )

   PRIVATE cFilter := ".t."
   FOR nI := 1 TO Len( aUsl )
      IF ausl[ nI ] <> NIL .AND. aUsl[ nI ] <> ".t."
         cFilter += ".and." + aUsl[ nI ]
      ENDIF
   NEXT
   IF cFilter == ".t."
      SET FILTER TO
   ELSE
      IF Left( cFilter, 8 ) == ".t..and."
         cFilter := SubStr( cFilter, 9 )
         SET FILTER TO &cFilter
      ENDIF
   ENDIF
   GO TOP

   RETURN NIL




FUNCTION validacija_postoji_sifra( wId, cTag )
   RETURN valid_sifarnik_id_postoji( wId, cTag )



FUNCTION valid_sifarnik_id_postoji( cId )

   LOCAL hRec

   __mvPublic( "wId" )
   Eval( MemVarBlock( "wId" ), cId ) // wId <-- cId

   IF ( Ch == K_CTRL_N .OR. Ch == K_F4 )
      hRec := get_hash_record_from_global_vars( "w", .F., .F. ) // uvijek napraviti cp852 enkodiran string
      IF is_sifra_postoji_u_sifarniku( hRec )
         MsgBeep( "Šifarnik: " + Alias() + ", ID već postoji: " + Trim( ToStr( cId ) ) + " !" )
         RETURN .F.
      ENDIF
   ENDIF

   RETURN .T.


/*
FUNCTION valid_sifarnik_id_postoji( wId, cTag )

   LOCAL nRec := RecNo()
   LOCAL nRet := .T.
   LOCAL cUpozorenje


   IF cTag == NIL
      cTag := "ID"
   ENDIF

   IF index_tag_num( cTag ) == 0
      _msg := "alias: " + Alias() + ", tag ne postoji :" + cTag
      log_write( _msg )
      MsgBeep( _msg )
      RETURN nRet
   ENDIF

   IF cTag <> "ID" .AND. Empty( wId )
      RETURN nRet
   ENDIF

   cUpozorenje := "Vrijednost polja " + cTag + " već postoji !"

   PushWA()

   SET ORDER TO TAG ( cTag )
   SEEK wId

   IF ( Found() .AND. ( Ch == K_CTRL_N .OR. Ch == K_F4 ) )
      MsgBeep( cUpozorenje )
      nRet := .F.

   ELSEIF ( gSKSif == "D" .AND. Found() )
      IF nRec <> RecNo()
         MsgBeep( cUpozorenje )
         nRet := .F.
      ELSE
         SKIP 1
         IF ( !Eof() .AND. wId == id )
            MsgBeep( cUpozorenje )
            nRet := .F.
         ENDIF
      ENDIF
   ENDIF

   PopWa()

   RETURN nRet
*/



FUNCTION sifarnik_f9_nova_sifra()

   // LOCAL cFilter := "val(id) <> 0"
   // LOCAL nI
   // LOCAL nLId
   // LOCAL lCheck
   // LOCAL lLoop
   // LOCAL nSifraLength := 4       // '0100  ' -> cSifraLength := 4,  nFieldLength := 6
   LOCAL nFieldLength := 6
   LOCAL cPom
   LOCAL cImeVar

   cImeVar := ReadVar()  // WID

   cPom := &( cImeVar )  // '0100  '
   nFieldLength := Len( cPom )

   IF cImeVar != "WID"
      RETURN .F.
   ENDIF

   IF Alias() != "PARTN"
      RETURN .F.
   ENDIF

   cMaxId := AllTrim( find_partner_max_numeric_id() )
   // nSifraLength := Len( cMaxId )
   // AltD()

   IF !Empty( cMaxId )
      // &( cImeVar ) := PadR( NovaSifra( IF( Empty( id ), id, RTrim( id ) ) ), nDuzSif, " " )
      &( cImeVar ) := PadR( NovaSifra( RTrim( cMaxId ) ), nFieldLength, " " )
   ENDIF

/*
   IF cImeVar == "WID"

      PushWA()

      nDuzSif := Len( cPom )


      SET FILTER TO &cFilter // postavi filter na numericke sifre

      // kreiraj indeks
      INDEX ON Val( id ) TAG "_VAL"

      GO BOTTOM

      // zapis
      nTRec := RecNo()
      nLast := nTRec

      // sifra kao uzorak
      nLId := Val( ID )
      lCheck := .F.

      DO WHILE lCheck = .F.

         lLoop := .F.
         // ispitaj prekid sifri
         FOR nI := 1 TO 10

            SKIP -1

            IF nLId = Val( field->id )
               // ako je zadnja sifra ista kao nI prethodna
               // idi na sljedecu
               // ili idi na zadnju sifru
               nTRec := nLast
               lLoop := .T.
               EXIT
            ENDIF

            IF nLId - Val( field->id ) <> nI
               // ima prekid
               // idi, ponovo...
               nLID := Val( field->id )
               nTRec := RecNo()
               lCheck := .F.
               lLoop := .F.
               EXIT
            ELSE
               lLoop := .T.
            ENDIF

         NEXT

         IF lLoop = .T.
            lCheck := .T.
         ENDIF

      ENDDO

      GO ( nTREC )

      &( cImeVar ) := PadR( NovaSifra( IF( Empty( id ), id, RTrim( id ) ) ), nDuzSif, " " )

      SET FILTER TO

      IF index_tag_num( "ID" ) != 0
         SET ORDER TO TAG "ID"
      ELSE
         SET ORDER TO TAG "1"
      ENDIF

      GO TOP

   ENDIF


   PopWA()
*/

   AEval( GetList, {| o | o:display() } )

   RETURN NIL
