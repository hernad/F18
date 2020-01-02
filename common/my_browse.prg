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
#include "f18_color.ch"



STATIC s_lExitBrowseOnEnter := .F.

MEMVAR TB, Ch, GetList, goModul
MEMVAR bGoreREd, bDoleRed, bDodajRed, fTBNoviRed, TBCanClose, bZaglavlje, TBScatter, nTBLine, nTBLastLine, TBPomjerise
MEMVAR TBSkipBlock

MEMVAR  ImeKol, Kol
// MEMVAR  azImeKol, azKol  // snimaju stanje ImeKol, Kol

MEMVAR cKolona

/*

 * brief Glavna funkcija tabelarnog prikaza podataka
 * param cImeBoxa - ime box-a
 * param xw - duzina
 * param yw - sirina
 * param bUserF - kodni blok, user funkcija
 * param cMessTop - poruka na vrhu
 * return NIL
 *

 brief Privatna Varijabla koja se inicijalizira prije "ulaska" u ObjDBedit
 param - [ 1] Zalavlje kolone
 param - [ 2] kodni blok za prikaz kolone {|| id}
 param - [ 3] izraz koji se edituje (string), obradjuje sa & operatorom
 param - [ 4] kodni blok When
 param - [ 5] kodni blok Valid
 param - [ 6] -
 param - [ 7] picture
 param - [ 8] - ima jos getova
 param - [ 9] -
 param - [10] NIL - prikazi u sljedecem redu,  15 - prikazi u koloni my+15  broj kolone pri editu sa <F2>
*/

FUNCTION my_browse( cImeBoxa, xw, yw, bMyKeyHandler, cMessTop, cMessBot, lInvert, ;
      aOpcije, nFreeze, bPodvuci, nPrazno, nGPrazno, aPoredak, bSkipBlock )

   LOCAL hParams := hb_Hash()
   LOCAL nBroji2
   LOCAL cSmj, nRez, i, K, aUF, cPomDB, nTTrec
   LOCAL cLoc := Space( 40 )
   LOCAL cStVr, cNovVr, nRec, nOrder, nPored, xcpos, ycpos
   LOCAL lExitBrowse := .F.
   LOCAL nKeyHandlerRetEvent
   LOCAL lKeyHandlerStarted := .F.

   // LOCAL azImeKol, azKol
   LOCAL lDoIdleCall, lContinue, oBrowse, nKey // extended key
   LOCAL oTCol
   LOCAL nHeight, nWidth, nBrojRedovaZaPoruke


   PRIVATE  bGoreRed := NIL
   PRIVATE  bDoleRed := NIL
   PRIVATE  bDodajRed := NIL

   // PRIVATE  TBInitialized := .F.
   PRIVATE  fTBNoviRed := .F.  // trenutno smo u novom redu ?
   PRIVATE  TBCanClose := .T. // da li se moze zavrsiti unos podataka ?

   PRIVATE  bZaglavlje := NIL // zaglavlje se edituje kada je kursor u prvoj koloni prvog reda

   PRIVATE  TBScatter := "N"  // uzmi samo tekuce polje
   PRIVATE  nTBLine   := 1      // tekuca linija-kod viselinijskog browsa
   PRIVATE  nTBLastLine := 1  // broj linija kod viselinijskog browsa
   PRIVATE  TBPomjerise := "" // ako je ">2" pomjeri se lijevo dva

   // ovo se moze setovati u when/valid fjama

   PRIVATE  TBSkipBlock // := {| nSkip | SkipDB( nSkip, @nTBLine ) }

   PRIVATE bTekCol
   PRIVATE Ch := 0


   // azImeKol := ImeKol
   // azKol := Kol

   IF nPrazno == NIL
      nPrazno := 0
   ENDIF

   IF nGPrazno == NIL
      nGPrazno := 0
   ENDIF

   IF aPoredak == NIL
      aPoredak := {}
   ENDIF

   IF ( nPored := Len( aPoredak ) ) > 1
      AAdd( aOpcije, "<c+U> - Uredi" )
   ENDIF

   PRIVATE Tb

   IF lInvert == NIL
      lInvert := .F.
   ENDIF

   hParams[ "ime" ]           := cImeBoxa
   hParams[ "xw" ]            := xw
   hParams[ "yw" ]            := yw
   hParams[ "invert" ]        := lInvert
   hParams[ "msgs" ]          := aOpcije
   hParams[ "freeze" ]        := nFreeze
   hParams[ "msg_bott" ]      := cMessBot
   hParams[ "msg_top" ]       := cMessTop
   hParams[ "prazno" ]        := nPrazno
   hParams[ "gprazno" ]       := nGPrazno
   hParams[ "podvuci_b" ]     := bPodvuci

   // IF bSkipBlock <> NIL
   // ovo je zadavanje skip bloka kroz parametar
   // TBSkipBlock := bSkipBlock
   // ELSE
   // TBSkipBlock := {| nSkip | SkipDB( nSkip, @nTBLine ) }
   // TBSkipBlock     := {| nRecs | __my_dbSkipper( nRecs ) }
   // ENDIF

   // harbour-core src/rtl/dbedit.prg



   // lKeyPressed := .F.

   // TB:ForceStable()

   // DispEnd()
   // IF LastRec() == 0
   // Ch := hb_keyNew( HB_KX_DOWN )
   // lKeyPressed := .T.
   // ENDIF
   lDoIdleCall := .T.
   lContinue := .T.

   // browse_only( oBrowse, hParams, .T. )


   // LOCAL i, j, k

   // LOCAL lSql := ( my_rddName() == "SQLMIX" )
   // LOCAL bShowField

   // IF lIzOBJDB == NIL
   // lIzOBJDB := .F.
   // ENDIF

   nHeight        :=  hParams[ "xw" ]
   nBrojRedovaZaPoruke :=  hParams[ "prazno" ] + iif( hParams[ "prazno" ] <> 0, 1, 0 )
   nWidth       :=  hParams[ "yw" ]

   IF hParams[ "prazno" ] == 0
      // IF !lIzOBJDB
      // BoxC()
      // ENDIF
      Box( hParams[ "ime" ], nHeight, nWidth, hParams[ "invert" ], hParams[ "msgs" ] )
   ELSE
      @ box_x_koord() + hParams[ "xw" ] - hParams[ "prazno" ], box_y_koord() + 1 SAY Replicate( hb_UTF8ToStrBox( BROWSE_PODVUCI ), hParams[ "yw" ] )
   ENDIF

   // IF !lIzOBJDB
   // ImeKol := azImeKol
   // Kol := azKol
   // ENDIF

   @ box_x_koord(), box_y_koord() + 2     SAY hParams[ "msg_top" ]   // +  REPL( hb_UTF8ToStrBox( BROWSE_PODVUCI_2 ),  42 )
   @ box_x_koord() + hParams[ "xw" ] + 1,  box_y_koord() + 2   SAY hParams[ "msg_bott" ] COLOR F18_COLOR_MSG_BOTTOM

   // @ box_x_koord() + hParams[ "xw" ] + 1,  Col() + 1 SAY REPL( hb_UTF8ToStrBox( BROWSE_PODVUCI_2 ), 42 )
   @ box_x_koord() + 1, box_y_koord() + hParams[ "yw" ] - 6    SAY Str( RecCount(), 5 )

   oBrowse := TBrowseDB( box_x_koord() + 2 + hParams[ "prazno" ], box_y_koord() + 1, box_x_koord() + nHeight - nBrojRedovaZaPoruke, box_y_koord() + nWidth )

   IF bSkipBlock <> NIL
      oBrowse:SkipBlock := bSkipBlock
   ENDIF

   FOR k := 1 TO Len( Kol ) // Dodavanje kolona za prikaz
      i := AScan( Kol, k )
      IF i <> 0
         // bShowField := ImeKol[ i, 2 ]
         // oTCol := TBColumnNew( ImeKol[ i, 1 ], bShowField )
         oTCol := TBColumnNew( ImeKol[ i, 1 ], ImeKol[ i, 2 ] ) // "Rb.br", { || field->rbr }
         IF hParams[ "podvuci_b" ] <> NIL
            oTCol:colorBlock := {|| iif( Eval( hParams[ "podvuci_b" ] ), { 5, 2 }, { 1, 2 } ) }
         ENDIF
         oBrowse:addColumn( oTCol )
      END IF
   NEXT

   oBrowse:headSep := hb_UTF8ToStrBox( BROWSE_HEAD_SEP )
   oBrowse:colsep :=  hb_UTF8ToStrBox( BROWSE_COL_SEP )

   IF hParams[ "freeze" ] == NIL
      oBrowse:Freeze := 1
   ELSE
      oBrowse:Freeze := hParams[ "freeze" ]
   ENDIF

   TB := oBrowse


   DO WHILE lContinue


      DO WHILE .T.
         Ch := hb_keyStd( Inkey(, hb_bitOr( Set( _SET_EVENTMASK ), f18_browse_inkey() ) ) )
         IF oBrowse:stabilize()
            EXIT // browse renderiran
         ENDIF
         IF Ch != 0 // tipka u toku renderiranja pritisnuta
            EXIT
         ENDIF
      ENDDO

      IF Ch == 0 // nije bilo nikakvog keyboard eventa

         IF lDoIdleCall

            nKeyHandlerRetEvent := my_browse_f18_komande_with_my_key_handler( oBrowse, Ch, @nKeyHandlerRetEvent, nPored, aPoredak, bMyKeyHandler )

            IF nKeyHandlerRetEvent == DE_ABORT
               lContinue := .F.
            ENDIF
            oBrowse:forceStable()
         ENDIF

         IF lContinue   // .AND. lFlag
            oBrowse:hiLite()
            Ch := hb_keyStd( nKey := Inkey( 0, hb_bitOr( Set( _SET_EVENTMASK ), f18_browse_inkey() ) ) )
            oBrowse:deHilite()
            // ELSE
            // lFlag := .T.
         ENDIF
      ENDIF

      nKeyHandlerRetEvent := -99
      lKeyHandlerStarted := .F.

      lDoIdleCall := .T.

      IF Ch == 0
         LOOP
      ENDIF


    

      DO CASE

      CASE Ch == K_UP
         oBrowse:up()

      CASE Ch == K_DOWN
         oBrowse:down()

      CASE Ch == K_LEFT
         oBrowse:Left()

      CASE Ch == K_RIGHT
         oBrowse:Right()

      CASE Ch == K_PGUP
         oBrowse:PageUp()

      CASE Ch == K_CTRL_PGUP
         oBrowse:GoTop()
         oBrowse:Refreshall()

      CASE Ch == K_CTRL_PGDN
         oBrowse:GoBottom()

      CASE Ch == K_PGDN
         oBrowse:PageDown()

      CASE Ch == K_CTRL_END .OR. Ch == K_ESC
         lExitBrowse := .T.
         nKeyHandlerRetEvent := DE_ABORT

      CASE Ch == K_ENTER .AND. browse_exit_on_enter()
         lExitBrowse := .T.
         nKeyHandlerRetEvent := DE_ABORT

      OTHERWISE

         nKeyHandlerRetEvent := my_browse_f18_komande_with_my_key_handler( Tb, Ch, @nKeyHandlerRetEvent, nPored, aPoredak, bMyKeyHandler )
         IF nKeyHandlerRetEvent == DE_ABORT
            lContinue := .F.
         ENDIF
         lDoIdleCall := .F.
      ENDCASE


      SWITCH nKeyHandlerRetEvent

      CASE DE_REFRESH

         IF Deleted()
            SKIP
            IF Eof()
               oBrowse:Down()
            ELSE
               oBrowse:Up()
            ENDIF
            oBrowse:RefreshCurrent()
         ENDIF
         oBrowse:RefreshAll()
         // TB:ForceStable()

         @ box_x_koord() + 1, box_y_koord() + yw - 6 SAY Str( RecCount2(), 5 )
         EXIT

      CASE DE_ABORT
         IF nPrazno == 0
            browse_stabilize_boxc( oBrowse )
         ENDIF
         lExitBrowse := .T.
         EXIT

      ENDSWITCH

      IF lExitBrowse
         lContinue := .F.
      ENDIF


   ENDDO



   RETURN .T.


STATIC FUNCTION browse_stabilize_boxc( oBrowse )

DO WHILE !oBrowse:stabilize() // ENTER keystorm unos nove sifre prevenirati
   oBrowse:stabilize()
ENDDO
BoxC()

RETURN .T.


FUNCTION browse_exit_on_enter( lSet )

   IF lSet != NIL
      s_lExitBrowseOnEnter := lSet
   ENDIF

   RETURN s_lExitBrowseOnEnter





STATIC FUNCTION ForceStable()

   DO WHILE ! TB:stabilize()
   ENDDO

   RETURN .T.


STATIC FUNCTION alt_s_provjeri_tip_uslova( cExpr, cMes, cT )

   LOCAL lVrati := .T., cPom

   IF cMes == nil
      cmes := "Greska!"
   ENDIF

   IF cT == nil
      cT := "L"
   ENDIF

   cPom := cExpr

   IF !( Type( cPom ) == cT )
      lVrati := .F.
      MsgBeep( cMes )
   ENDIF

   RETURN lVrati



STATIC FUNCTION tb_editabilna_kolona( oTb, aImeKol )

   IF ValType( oTB ) != "O"
      RETURN .F.
   ENDIF

   IF oTB:colPos < 1
      RETURN .F.
   ENDIF

   // aImeKol[ 3] izraz koji se edituje (string), obradjuje sa & operatorom
   // aImeKol[ 4] kodni blok When
   // aImeKol[ 5] kodni blok Valid
   IF Len( aImeKol ) < oTb:colPos
      RETURN .F.
   ENDIF

   RETURN Len( aImeKol[ TB:colPos ] ) > 2


STATIC FUNCTION f18_browse_inkey()

if is_electron_host()
   return HB_INKEY_ALL
else
   return HB_INKEY_EXT
endif



/*

STATIC FUNCTION StandTBTipke()

   IF Ch == K_ESC .OR. Ch == K_CTRL_T .OR. Ch = K_CTRL_P .OR. Ch = K_CTRL_N .OR. ;
         Ch == K_ALT_A .OR. Ch == K_ALT_P .OR. Ch = k_alt_s() .OR. Ch = k_alt_r() .OR. ;
         Ch == K_DEL .OR. Ch = K_F2 .OR. Ch = K_F4 .OR. Ch = k_ctrl_f9() .OR. Ch = 0
      RETURN .T.
   ENDIF

   RETURN .F.
*/


/*
STATIC FUNCTION EditPolja( nX, nY, xIni, cNazPolja, bWhen, bValid, cBoje )

   LOCAL i
   LOCAL cPict
   LOCAL bGetSet
   LOCAL nSirina

   IF TBScatter == "N"
      cPom77I := cNazpolja
      cPom77U := "w" + cNazpolja
      &cPom77U := xIni
   ELSE
      Scatter()
      IF FieldPos( cNazPolja ) <> 0 // field varijabla
         cPom77I := cNazpolja
         cPom77U := "_" + cNazpolja
      ELSE
         cPom77I := cNazpolja
         cPom77U := cNazPolja
      ENDIF
   ENDIF

   cPict := NIL
   IF Len( ImeKol[ TB:Colpos ] ) >= 7  // ima picture
      cPict := ImeKol[ TB:Colpos, 7 ]
   ENDIF


   // provjeriti kolika je sirina get-a!!

   aTBGets := {}
   GET := GetNew( nX, nY, MemVarBlock( cPom77U ), ;
      cPom77U, cPict, "W+/BG,W+/B" )
   get:PreBlock := bWhen
   get:PostBlock := bValid
   AAdd( aTBGets, GET )
   nSirina := 8
   IF cPict <> NIL
      nSirina := Len( Transform( &cPom77U, cPict ) )
   ENDIF

   IF Len( ImeKol[ TB:Colpos ] ) >= 8  // ima jos getova
      aPom := ImeKol[ TB:Colpos, 8 ]  // matrica
      FOR i := 1 TO Len( aPom )
         nY := nY + nSirina + 1
         GET := GetNew( nX, nY, MemVarBlock( aPom[ i, 1 ] ), ;
            aPom[ i, 1 ], aPom[ i, 4 ], "W+/BG,W+/B" )
         nSirina := Len( Transform( &( aPom[ i, 1 ] ), aPom[ i, 4 ] ) )
         get:PreBlock := aPom[ i, 2 ]
         get:PostBlock := aPom[ i, 3 ]
         AAdd( aTBGets, GET )
      NEXT

      IF nY + nSirina > f18_max_cols() - 2

         FOR i := 1 TO Len( aTBGets )
            aTBGets[ i ]:Col := aTBGets[ i ]:Col  - ( nY + nSirina - 78 ) // smanji col koordinate
         NEXT
      ENDIF

   ENDIF

   ReadModal( aTBGets )

   IF TBScatter = "N"
      // azuriraj samo ako nije zadan when blok !
      REPLACE &cPom77I WITH &cPom77U
      sql_azur( .T. )

   ELSE
      IF LastKey() != K_ESC .AND. cPom77I <> cPom77U  // field varijabla
         Gather()
         sql_azur( .T. )
         GathSQL()
      ENDIF
   ENDIF

   RETURN .T.

*/

/* function TBPomjeranje(TB, cPomjeranje)
 *     Opcije pomjeranja tbrowsea u direkt rezimu
 *   param: TB          -  TBrowseObjekt
 *   param: cPomjeranje - ">", ">2", "V0"


STATIC FUNCTION TBPomjeranje( TB, cPomjeranje )

   LOCAL cPomTB, i

   IF ( cPomjeranje ) = ">"
      cPomTb := SubStr( cPomjeranje, 2, 1 )
      TB:Right()
      IF !Empty( cPomTB )
         FOR i := 1 TO Val( cPomTB )
            TB:Right()
         NEXT
      ENDIF

   ELSEIF ( cPomjeranje ) = "V"
      TB:Down()
      cPomTb := SubStr( cPomjeranje, 2, 1 )
      IF !Empty( cPomTB )
         TB:PanHome()
         FOR i := 1 TO Val( cPomTB )
            TB:Right()
         NEXT
      ENDIF
      IF bDoleRed = NIL .OR. Eval( bDoleRed )
         fTBNoviRed := .F.
      ENDIF
   ELSEIF ( cPomjeranje ) = "<"
      TB:Left()
   ELSEIF ( cPomjeranje ) = "0"
      TB:PanHome()
   ENDIF

   RETURN .T.
*/

FUNCTION browse_brisi_stavku( lPack )

   IF lPack == NIL
      lPack := .T.
   ENDIF

   IF Pitanje( , "Želite izbrisati ovu stavku ?", "D" ) == "D"

      my_rlock()
      DELETE
      my_unlock()

      IF lPack
         my_dbf_pack()
      ENDIF

      RETURN DE_REFRESH
   ENDIF

   RETURN DE_CONT


FUNCTION browse_brisi_pripremu()

   IF Pitanje(, D_ZELITE_LI_IZBRISATI_PRIPREMU, "N" ) == "D"
      my_dbf_zap()
      RETURN DE_REFRESH
   ENDIF

   RETURN DE_CONT




FUNCTION my_browse_f18_komande_with_my_key_handler( oBrowse, nKey, nKeyHandlerRetEvent, nPored, aPoredak, bMyKeyHandler )

   LOCAL _tr := hb_UTF8ToStr( "Traži:" ), cZamijeni := "Zamijeni sa:"
   LOCAL cLastSearchDN := "N"
   LOCAL i, cIzraz
   LOCAL cLoc := Space( 40 )
   LOCAL cTraziVrijednost, cZamijeniVrijednost, cTraziUslov
   LOCAL _sect, _pict
   LOCAL bTekCol
   LOCAL cSmj
   LOCAL nRez
   LOCAL cIdOrNaz := Space( 100 )
   LOCAL GetList := {}
   LOCAL lKeyHendliran := .F.

   IF bMyKeyHandler != NIL
      nKeyHandlerRetEvent := Eval( bMyKeyHandler, Ch )
      IF nKeyHandlerRetEvent != DE_CONT // samo ako je DE_CONT nastavi procesiranje
         RETURN nKeyHandlerRetEvent
      ENDIF
   ENDIF

   DO CASE

   CASE  nKey == K_F5
      oBrowse:RefreshAll()
      lKeyHendliran := .T.
      RETURN DE_REFRESH

   CASE Upper( Chr( nKey ) ) == "F"


      IF Alias() == "OS" .OR. Alias() == "SII"
         Box( "#Unijeti dio šifre ili naziva ili mjesta", 1, 70 )
         set_cursor_on()
         @ box_x_koord() + 1, box_y_koord() + 1 SAY "" GET cIdOrNaz PICT "@!S50"
         READ
         BoxC()
         IF LastKey() != K_ESC
            find_os_sii_by_naz_or_id( cIdOrNaz )
            oBrowse:RefreshAll()
            RETURN DE_REFRESH
         ENDIF
         lKeyHendliran := .T.
      ENDIF

      IF Alias() == "PARTN"
         Box( "#Unijeti dio šifre ili naziva ili mjesta", 1, 70 )
         set_cursor_on()
         @ box_x_koord() + 1, box_y_koord() + 1 SAY "" GET cIdOrNaz PICT "@!S50"
         READ
         BoxC()
         IF LastKey() != K_ESC
            find_partner_by_naz_or_id( cIdOrNaz )
            oBrowse:RefreshAll()
            RETURN DE_REFRESH
         ENDIF
         lKeyHendliran := .T.
      ENDIF

      IF Alias() == "ROBA" .OR. Alias() == "ROBA_P"
         Box( "#Unijeti dio šifre / sifredob / naziva", 1, 70 )
         set_cursor_on()
         @ box_x_koord() + 1, box_y_koord() + 1 SAY "" GET cIdOrNaz PICT "@!S50"
         READ
         BoxC()
         IF LastKey() != K_ESC
            IF Alias() == "ROBA_P"
               find_roba_p_by_naz_or_id( cIdOrNaz )
            ELSE
               find_roba_by_naz_or_id( cIdOrNaz )
            ENDIF
            oBrowse:RefreshAll()
            RETURN DE_REFRESH
         ENDIF
         lKeyHendliran := .T.
      ENDIF

      IF Alias() == "KONTO"
         Box( "#Unijeti dio šifre ili naziva", 1, 70 )
         set_cursor_on()
         @ box_x_koord() + 1, box_y_koord() + 1 SAY "" GET cIdOrNaz PICT "@!S50"
         READ
         BoxC()
         IF LastKey() != K_ESC
            find_konto_by_naz_or_id( cIdOrNaz )
            oBrowse:RefreshAll()
            RETURN DE_REFRESH
         ENDIF
         lKeyHendliran := .T.
      ENDIF

      IF Alias() == "RADN"
         Box( "#Unijeti dio šifre, prezimena ili imena radnika", 1, 70 )
         set_cursor_on()
         @ box_x_koord() + 1, box_y_koord() + 1 SAY "" GET cIdOrNaz PICT "@!S50"
         READ
         BoxC()
         IF LastKey() != K_ESC
            find_radn_by_naz_or_id( cIdOrNaz )
            oBrowse:RefreshAll()
            RETURN DE_REFRESH
         ENDIF
         lKeyHendliran := .T.
      ENDIF

      IF Alias() == "FAKT_FTXT"
         Box( "#Unijeti dio šifre ili sadržaja uzorka", 1, 70 )
         set_cursor_on()
         @ box_x_koord() + 1, box_y_koord() + 1 SAY "" GET cIdOrNaz PICT "@!S50"
         READ
         BoxC()
         IF LastKey() != K_ESC
            find_fakt_txt_by_naz_or_id( cIdOrNaz )
            oBrowse:RefreshAll()
            RETURN DE_REFRESH
         ENDIF
         lKeyHendliran := .T.
      ENDIF


   CASE nKey == K_CTRL_F

      bTekCol := ( oBrowse:getColumn( oBrowse:colPos ) ):Block

      IF ValType( Eval( bTekCol ) ) != "C"
         RETURN DE_CONT
      ENDIF

      Box( "bFind", 2, 50, .F. )

      cLoc := PadR( cLoc, 40 )
      cSmj := "+"
      @ box_x_koord() + 1, box_y_koord() + 2 SAY _tr GET cLoc PICT "@!"
      @ box_x_koord() + 2, box_y_koord() + 2 SAY "Prema dolje (+), gore (-)" GET cSmj VALID cSmj $ "+-"
      READ
      BoxC()
      lKeyHendliran := .T.

      IF LastKey() == K_ESC
         RETURN DE_CONT
      ENDIF

      cLoc := Trim( cLoc )
      cIzraz := NIL
      IF Right( cLoc, 1 ) == ";"
         Beep( 1 )
         cIzraz := parsiraj( cLoc, "Eval(xVar)" )
      ENDIF
      oBrowse:hitTop := oBrowse:hitBottom := .F.
      DO WHILE !( oBrowse:hitTop .OR. oBrowse:hitBottom )
         IF cIzraz <> NIL
            IF Tacno( cIzraz, oBrowse:getColumn( oBrowse:colPos ):block() )
               EXIT
            ENDIF
         ELSE
            IF Upper( Left( Eval( bTekCol ), Len( cLoc ) ) ) == cLoc
               EXIT
            ENDIF
         ENDIF
         IF cSmj == "+"
            oBrowse:down()
            oBrowse:Stabilize()
         ELSE
            oBrowse:Up()
            oBrowse:Stabilize()
         ENDIF

      ENDDO
      oBrowse:hitTop := oBrowse:hitBottom := .F.
      RETURN DE_REFRESH


   CASE nKey == k_alt_r()

      PRIVATE cKolona

      IF !tb_editabilna_kolona( oBrowse, ImeKol )
         RETURN DE_CONT
      ENDIF

      IF Empty( ImeKol[ oBrowse:colPos, 3 ] )
         RETURN DE_CONT
      ENDIF

      cKolona := ImeKol[ oBrowse:ColPos, 3 ]
      IF ValType( &cKolona ) $ "CD"

         Box("<CENTAR>", 3, 60, .F. )

         set_cursor_on()
         @ box_x_koord() + 1, box_y_koord() + 2 SAY "Uzmi podatke posljednje pretrage ?" GET cLastSearchDN VALID cLastSearchDN $ "DN" PICT "@!"

         READ
         lKeyHendliran := .T.

         _sect := "_brow_fld_find_" + AllTrim( Lower( cKolona ) )
         cTraziVrijednost := &cKolona

         IF cLastSearchDN == "D"
            cTraziVrijednost := fetch_metric( _sect, "<>", cTraziVrijednost )
         ENDIF

         cZamijeniVrijednost := cTraziVrijednost
         _sect := "_brow_fld_repl_" + AllTrim( Lower( cKolona ) )

         IF cLastSearchDN == "D"
            cZamijeniVrijednost := fetch_metric( _sect, "<>", cZamijeniVrijednost )
         ENDIF

         _pict := ""

         IF ValType( cTraziVrijednost ) == "C" .AND. Len( cTraziVrijednost ) > 45
            _pict := "@S45"
         ENDIF

         @ box_x_koord() + 2, box_y_koord() + 2 SAY PadR( _tr, 12 ) GET cTraziVrijednost PICT _pict
         @ box_x_koord() + 3, box_y_koord() + 2 SAY PadR( cZamijeni, 12 ) GET cZamijeniVrijednost PICT _pict

         READ

         BoxC()

         IF LastKey() == K_ESC
            RETURN DE_CONT
         ENDIF

         IF replace_kolona_in_table( cKolona, cTraziVrijednost, cZamijeniVrijednost, cLastSearchDN )
            oBrowse:RefreshAll()
            RETURN DE_REFRESH
         ENDIF

         RETURN DE_CONT

      ENDIF

      RETURN DE_CONT


   CASE nKey == k_alt_s()

      PRIVATE cKolona

      IF !tb_editabilna_kolona( oBrowse, ImeKol )
         RETURN DE_CONT
      ENDIF

      IF Empty( ImeKol[ oBrowse:colPos, 3 ] )
         RETURN DE_CONT
      ENDIF

      cKolona := ImeKol[ oBrowse:ColPos, 3 ]

      IF ValType( &cKolona ) == "N"

         Box(, 3, 66, .F. )

         set_cursor_on()
         cTraziVrijednost := &cKolona
         cTraziUslov := Space( 80 )

         @ box_x_koord() + 1, box_y_koord() + 2 SAY "Postavi na:" GET cTraziVrijednost
         @ box_x_koord() + 2, box_y_koord() + 2 SAY "Uslov za obuhvatanje stavki (prazno-sve):" GET cTraziUslov PICT "@S20" ;
            VALID Empty( cTraziUslov ) .OR. alt_s_provjeri_tip_uslova( cTraziUslov, "Greška! Neispravno postavljen uslov!" )
         READ

         BoxC()
         lKeyHendliran := .T.

         IF LastKey() == K_ESC
            RETURN DE_CONT
         ENDIF

         IF zamjeni_numericka_polja_u_tabeli( cKolona, cTraziVrijednost, cTraziUslov )
            TB:RefreshAll()
            RETURN DE_REFRESH
         ELSE
            RETURN DE_CONT
         ENDIF

      ENDIF

      RETURN DE_CONT


   CASE nKey == K_CTRL_U .AND. nPored > 1

      nRez := IndexOrd()
      box_crno_na_zuto( 12, 20, 17 + nPored, 59, "UTVRĐIVANJE PORETKA", F18_COLOR_NASLOV, F18_COLOR_OKVIR, F18_COLOR_TEKST, 2 )
      FOR i := 1 TO nPored
         @ 13 + i, 23 SAY PadR( "poredak po " + aPoredak[ i ], 33, "ú" ) + Str( i, 1 )
      NEXT
      @ 18, 27 SAY "UREDITI TABELU PO BROJU:" GET nRez VALID nRez > 0 .AND. nRez < nPored + 1 PICT "9"
      READ
      box_crno_na_zuto_end()

      IF LastKey() != K_ESC
         dbSetOrder( nRez + 1 )
         RETURN DE_REFRESH
      ENDIF
      lKeyHendliran := .T.
      RETURN DE_CONT

   OTHERWISE

      nKeyHandlerRetEvent := goModul:globalni_key_handler( nKey, nKeyHandlerRetEvent )
      IF nKeyHandlerRetEvent == DE_ABORT
         RETURN DE_ABORT
      ENDIF


   ENDCASE

   RETURN nKeyHandlerRetEvent


FUNCTION k_alt_r()

   IF is_mac()
      RETURN 1124073646
   ENDIF

   RETURN K_ALT_R


FUNCTION k_alt_s()

   IF is_mac()
      RETURN 225
   ENDIF

   RETURN K_ALT_S


FUNCTION zamjeni_numericka_polja_u_tabeli( cKolona, cTrazi, cUslov )

   LOCAL lRet := .F.
   LOCAL lOk := .T.
   LOCAL nRec := RecNo()
   LOCAL nOrder := IndexOrd()
   LOCAL lImaSemafor := dbf_alias_has_semaphore()
   LOCAL hRec
   LOCAL cAlias
   LOCAL hParams

   SET ORDER TO 0

   IF Pitanje(, "Promjena će se izvršiti u " + iif( Empty( cUslov ), "svim ", "" ) + "stavkama" + ;
         iif( !Empty( cUslov ), " koje obuhvata uslov", "" ) + ". Želite nastaviti ?", "N" ) == "N"
      RETURN lRet
   ENDIF

   cAlias := Lower( Alias() )

   IF lImaSemafor
      RETURN .F.
      // IF !begin_sql_tran_lock_tables( { cAlias  } )
      // RETURN .F.
      // ENDIF
   ENDIF

   GO TOP

   DO WHILE !Eof()

      IF Empty( cUslov ) .OR. &( cUslov )

         hRec := dbf_get_rec()
         hRec[ Lower( cKolona ) ] := cTrazi

         // IF lImaSemafor
         // lOk := ( Alias(), hRec, 1, "CONT" )
         // ELSE
         dbf_update_rec( hRec )
         // ENDIF

      ENDIF

      IF !lOk
         EXIT
      ENDIF

      SKIP

   ENDDO

/*
   IF lImaSemafor
      IF lOk
         lRet := .T.
         hParams := hb_Hash()
         hParams[ "unlock" ] :=  { cAlias }
         run_sql_query( "COMMIT", hParams )
      ELSE
         run_sql_query( "ROLLBACK" )
      ENDIF
   ELSE
  */
   lRet := .T.
   // ENDIF

   IF lRet
      dbSetOrder( nOrder )
      GO nRec
   ENDIF

   RETURN lRet



FUNCTION replace_kolona_in_table( cKolona, trazi_val, zamijeni_val, last_search )

   LOCAL lRet := .F.
   LOCAL nRec
   LOCAL nOrder
   LOCAL _saved
   LOCAL _has_semaphore
   LOCAL hRec
   LOCAL cDio1, cDio2
   LOCAL _sect
   LOCAL lOk := .T.
   LOCAL cAlias
   LOCAL hParams

   nRec := RecNo()
   nOrder := IndexOrd()
   cAlias := Lower( Alias() )


   SET ORDER TO 0
   GO TOP

   _saved := .F.

   _has_semaphore := dbf_alias_has_semaphore()

   IF _has_semaphore
      IF !begin_sql_tran_lock_tables( { cAlias  } )
         RETURN .F.
      ENDIF
   ENDIF


   DO WHILE !Eof()

      IF Eval( FieldBlock( cKolona ) ) == trazi_val

         hRec := dbf_get_rec()
         hRec[ Lower( cKolona ) ] := zamijeni_val

         IF _has_semaphore
            lOk := update_rec_server_and_dbf( cAlias, hRec, 1, "CONT" )
         ELSE
            dbf_update_rec( hRec )
         ENDIF

         IF !_saved .AND. last_search == "D"
            // snimi
            _sect := "_brow_fld_find_" + AllTrim( Lower( cKolona ) )
            set_metric( _sect, "<>", trazi_val )

            _sect := "_brow_fld_repl_" + AllTrim( Lower( cKolona ) )
            set_metric( _sect, "<>", zamijeni_val )
            _saved := .T.
         ENDIF

      ENDIF

      IF !lOk
         EXIT
      ENDIF

      IF ValType( trazi_val ) == "C"

         hRec := dbf_get_rec()

         cDio1 := Left( trazi_val, Len( Trim( trazi_val ) ) - 2 )
         cDio2 := Left( zamijeni_val, Len( Trim( zamijeni_val ) ) - 2 )

         IF Right( Trim( trazi_val ), 2 ) == "**" .AND. cDio1 $  hRec[ Lower( cKolona ) ]

            hRec[ Lower( cKolona ) ] := StrTran( hRec[ Lower( cKolona ) ], cDio1, cDio2 )

            IF _has_semaphore
               lOk := update_rec_server_and_dbf( cAlias, hRec, 1, "CONT" )
            ELSE
               dbf_update_rec( hRec )
            ENDIF

         ENDIF

      ENDIF

      IF !lOk
         EXIT
      ENDIF

      SKIP

   ENDDO

   IF _has_semaphore
      IF lOk
         lRet := .T.
         hParams := hb_Hash()
         hParams[ "unlock" ] :=  { cAlias }
         run_sql_query( "COMMIT", hParams )
      ELSE
         run_sql_query( "ROLLBACK" )
         MsgBeep( "Greška sa opcijom ALT+R !#Operacija prekinuta." )
      ENDIF
   ELSE
      lRet := .T.
   ENDIF

   dbSetOrder( nOrder )
   GO nRec

   RETURN lRet

/*
STATIC FUNCTION SkipDB( nRequest, nTBLine )   // nTBLine is a reference

   LOCAL nActually := 0

   IF nRequest == 0
      dbSkip( 0 )

   ELSEIF nRequest > 0 .AND. !Eof()

      WHILE nActually < nRequest
         IF nTBLine < nTBLastLine
            ++nTBLine // This will print up to nTBLastLine of text; Some of them (or even all) might be empty
         ELSE
            dbSkip( +1 )  // Go to the next record
            nTBLine := 1

         ENDIF
         IF Eof()
            dbSkip( - 1 )
            nTBLine := nTBLastLine
            EXIT
         ENDIF
         nActually++

      END

   ELSEIF nRequest < 0
      WHILE nActually > nRequest
         // Go to previous line
         IF nTBLine > 1
            --nTBLine

         ELSE
            dbSkip( - 1 )
            IF !Bof()
               nTBLine := nTBLastLine

            ELSE
               // You need this. Believe me!
               nTBLine := 1
               GOTO RecNo()
               EXIT

            ENDIF

         ENDIF
         nActually--

      END

   ENDIF

   RETURN ( nActually )
*/
