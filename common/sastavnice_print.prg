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


FUNCTION pr_pr_sast() // lista sastavnica sa pretpostavljenim sirovinama

   LOCAL cSirovine := Space( 200 )
   LOCAL cArtikli := Space( 200 )
   LOCAL cIdRoba
   LOCAL aSast := {}
   LOCAL i
   LOCAL nScan
   LOCAL aError := {}
   LOCAL aArt := {}

   BOX(, 2, 65 )
   @ box_x_koord() + 1, box_y_koord() + 2 SAY "pr.sirovine:" GET cSirovine PICT "@S40"  VALID !Empty( cSirovine )
   @ box_x_koord() + 2, box_y_koord() + 2 SAY "uslov za artikle:" GET cArtikli PICT "@S40"
   READ
   BOXC()

   IF LastKey() == K_ESC
      RETURN .F.
   ENDIF

   // sastavnice u matricu...
   aSast := TokToNiz( AllTrim( cSirovine ), ";" )

   IF !Empty( cArtikli )
      bUsl := Parsiraj( AllTrim( cArtikli ), "ID" )
   ENDIF

   o_roba_tip_p()

   DO WHILE !Eof()


      IF !Empty( cArtikli )
         IF &bUsl
            // idi dalje...
         ELSE
            SKIP
            LOOP
         ENDIF
      ENDIF

      cIdRoba := field->id
      cRobaNaz := ( field->naz )

      IF !select_o_sastavnice( cIdRoba )

         AAdd( aError, { 1, cIdRoba, cRobaNaz,  "ne postoji sastavnica !" } )

         SELECT roba_p
         SKIP
         LOOP

      ENDIF

      i := 0

      cUzorak := ""
      lPostoji := .F.

      DO WHILE !Eof() .AND. field->id == cIdRoba

         // sirovina za
         cUzorak := AllTrim( field->id2 )

         lPostoji := .F.

         FOR i := 1 TO Len( aSast )

            cPretp := aSast[ i ]

            IF cPretp $ cUzorak
               lPostoji := .T.
               EXIT
            ENDIF

         NEXT

         IF lPostoji == .F.
            AAdd( aError, { 2, cIdRoba, roba_p->naz, "uzorak " + "se ne poklapa !"  } )
         ENDIF

         SKIP

      ENDDO

      SELECT roba
      SKIP

   ENDDO

   IF Len( aError ) == 0
      MsgBeep( "sve ok :)" )
      RETURN
   ENDIF

   START PRINT CRET

   i := 0

   ?

   cLine := Replicate( "-", 5 )
   cLine += Space( 1 )
   cLine += Replicate( "-", 15 )
   cLine += Space( 1 )
   cLine += Replicate( "-", 50 )
   cLine += Space( 1 )
   cLine += Replicate( "-", 50 )

   cTxt := PadR( "rbr", 5 )
   cTxt += Space( 1 )
   cTxt += PadR( "uzrok", 15 )
   cTxt += Space( 1 )
   cTxt += PadR( "artikal / sirovina", 50 )
   cTxt += Space( 1 )
   cTxt += PadR( "opis", 50 )

   P_COND
   ? cLine
   ? cTxt
   ? cLine

   nCnt := 0

   FOR i := 1 TO Len( aError )

      ? PadL( AllTrim( Str( ++nCnt ) ) + ")", 5 )

      IF aError[ i, 1 ] == 1
         cPom := "nema sastavnice"
      ELSE
         cPom := "  fale sirovine"
      ENDIF

      @ PRow(), PCol() + 1 SAY cPom
      @ PRow(), PCol() + 1 SAY PadR( AllTrim( aError[ i, 2 ] ) + "-" + ;
         AllTrim( aError[ i, 3 ] ), 50 )
      @ PRow(), PCol() + 1 SAY PadR( aError[ i, 4 ], 50 )

   NEXT

   FF
   ENDPRINT

   RETURN .T.


// -----------------------------------------------
// pregled brojnog stanja sastavnica
// -----------------------------------------------
FUNCTION pr_br_sast()

   LOCAL nMin := 5
   LOCAL nMax := 15
   LOCAL cArtikli := Space( 200 )
   LOCAL cIdRoba
   LOCAL i
   LOCAL aError := {}

   Box(, 3, 65 )
   @ box_x_koord() + 1, box_y_koord() + 2 SAY "min.broj sastavnica:" GET nMin PICT "999"
   @ box_x_koord() + 2, box_y_koord() + 2 SAY "max.broj sastavnica:" GET nMax PICT "999"
   @ box_x_koord() + 3, box_y_koord() + 2 SAY "uslov za artikle:" GET cArtikli PICT "@S40"
   READ
   BoxC()

   IF LastKey() == K_ESC
      RETURN .F.
   ENDIF

   IF !Empty( cArtikli )
      bUsl := Parsiraj( AllTrim( cArtikli ), "ID" )
   ENDIF

   o_roba_tip_p()


   DO WHILE !Eof()

      IF !Empty( cArtikli )
         IF &bUsl
            // idi dalje...
         ELSE
            SKIP
            LOOP
         ENDIF
      ENDIF

      cIdRoba := field->id

      IF !select_o_sastavnice( cIdRoba )
         SELECT roba_p
         SKIP
         LOOP
      ENDIF

      nTmp := 0

      // koliko ima sastavnica ?
      DO WHILE !Eof() .AND. field->id == cIdRoba
         ++nTmp
         SKIP
      ENDDO

      IF ( nTmp < nMin ) .OR. ( nTmp > nMax )

         AAdd( aError, {  AllTrim( cIdRoba ) + " - " +  AllTrim( roba_p->naz ), nTmp  } )
      ENDIF

      SELECT roba_p
      SKIP

   ENDDO

   IF Len( aError ) == 0
      MsgBeep( "sve ok :)" )
      RETURN
   ENDIF

   START PRINT CRET

   i := 0

   ?

   cLine := Replicate( "-", 5 )
   cLine += Space( 1 )
   cLine += Replicate( "-", 5 )
   cLine += Space( 1 )
   cLine += Replicate( "-", 50 )

   cTxt := PadR( "rbr", 5 )
   cTxt += Space( 1 )
   cTxt += PadR( "broj", 5 )
   cTxt += Space( 1 )
   cTxt += PadR( "roba", 50 )

   P_COND
   ? cLine
   ? cTxt
   ? cLine

   nCnt := 0

   FOR i := 1 TO Len( aError )

      ? PadL( AllTrim( Str( ++nCnt ) ) + ")", 5 )
      @ PRow(), PCol() + 1 SAY Str( aError[ i, 2 ], 5 )
      @ PRow(), PCol() + 1 SAY PadR( aError[ i, 1 ], 50 )

   NEXT

   FF
   ENDPRINT

   RETURN .T.


FUNCTION pr_ned_sast() // pregled sastavnica koje nedostaju

   LOCAL cSirovine := Space( 200 )
   LOCAL cArtikli := Space( 200 )
   LOCAL cPostoji := "P"
   LOCAL cIdRoba
   LOCAL aSast := {}
   LOCAL i
   LOCAL nScan
   LOCAL aError := {}

   Box(, 3, 65 )
   @ box_x_koord() + 1, box_y_koord() + 2 SAY "tr.sirovine:" GET cSirovine PICT "@S40" VALID !Empty( cSirovine )
   @ box_x_koord() + 2, box_y_koord() + 2 SAY "[P]ostoji / [N]epostoji" GET cPostoji PICT "@!" VALID cPostoji $ "PN"
   @ box_x_koord() + 3, box_y_koord() + 2 SAY "uslov za artikle:" GET cArtikli PICT "@S40"

   READ
   BoxC()

   IF LastKey() == K_ESC
      RETURN .F.
   ENDIF

   // sastavnice u matricu...
   aSast := TokToNiz( cSirovine, ";" )

   IF !Empty( cArtikli )
      bUsl := Parsiraj( AllTrim( cArtikli ), "ID" )
   ENDIF

   o_roba_tip_p()

   DO WHILE !Eof()

      IF !Empty( cArtikli )
         IF &bUsl
         ELSE
            SKIP
            LOOP
         ENDIF
      ENDIF

      cIdRoba := field->id

      IF !select_o_sastavnice( cIdRoba )
         SELECT roba_p
         SKIP
         LOOP
      ENDIF

      i := 0

      lPostoji := .F.

      DO WHILE !Eof() .AND. field->id == cIdRoba

         // sirovina za
         cUzorak := AllTrim( field->id2 )
         nScan := AScan( aSast, {| xVal | xVal $ cUzorak } )

         IF nScan <> 0
            lPostoji := .T.
            EXIT
         ENDIF

         SKIP

      ENDDO

      IF cPostoji == "N" .AND. lPostoji == .F.
         AAdd( aError, {  AllTrim( cIdRoba ) + " - " +  AllTrim( roba_p->naz )  } )
      ENDIF

      IF cPostoji == "P" .AND. lPostoji == .T.
         AAdd( aError, {  AllTrim( cIdRoba ) + " - " +  AllTrim( roba_p->naz )  } )
      ENDIF

      SELECT roba_p
      SKIP

   ENDDO

   IF Len( aError ) == 0
      MsgBeep( "sve ok :)" )
      RETURN .F.
   ENDIF

   START PRINT CRET

   i := 0

   ?

   cLine := Replicate( "-", 5 )
   cLine += Space( 1 )
   cLine += Replicate( "-", 50 )

   cTxt := PadR( "rbr", 5 )
   cTxt += Space( 1 )
   cTxt += PadR( "roba", 50 )

   P_COND
   ? cLine
   ? cTxt
   ? cLine

   nCnt := 0

   FOR i := 1 TO Len( aError )

      ? PadL( AllTrim( Str( ++nCnt ) ) + ")", 5 )
      @ PRow(), PCol() + 1 SAY PadR( aError[ i, 1 ], 50 )

   NEXT

   FF
   ENDPRINT

   RETURN .T.



FUNCTION sastavnice_duple()

   LOCAL cIdRoba
   LOCAL cArtikli := Space( 200 )
   LOCAL aSast := {}
   LOCAL i
   LOCAL nScan
   LOCAL aError := {}
   LOCAL aDbf := {}
   LOCAL cUzorak

   Box(, 1, 65 )
   @ box_x_koord() + 1, box_y_koord() + 2 SAY "uslov za artikle:" GET cArtikli PICT "@S40"
   READ
   BoxC()

   IF LastKey() == K_ESC
      RETURN .F.
   ENDIF

   AAdd( aDbf, { "IDROBA", "C", 10, 0 } )
   AAdd( aDbf, { "ROBANAZ", "C", 200, 0 } )
   AAdd( aDbf, { "SAST", "C", 150, 0 } )
   AAdd( aDbf, { "MARK", "C", 1, 0 } )

   IF !xlsx_export_init( aDbf )
      RETURN .F.
   ENDIF

   o_r_export_legacy()
   INDEX ON sast TAG "1"


   o_roba_tip_p() // sva roba

   IF !Empty( cArtikli )
      bUsl := Parsiraj( AllTrim( cArtikli ), "ID" )
   ENDIF


   Box(, 1, 50 )

   // prvo sva robu  sa sastavnicama
   DO WHILE !Eof()


      IF !Empty( cArtikli )
         IF &bUsl
         ELSE
            SKIP
            LOOP
         ENDIF
      ENDIF

      cIdRoba := field->id
      cRobaNaz := AllTrim( field->naz )

      @ box_x_koord() + 1, box_y_koord() + 2 SAY "generisem uzorak: " + cIdRoba

      IF !select_o_sastavnice( cIdRoba )
         SELECT roba_p
         SKIP
         LOOP
      ENDIF

      // === SAST ===
      cUzorak := ""
      DO WHILE !Eof() .AND. field->id == cIdRoba
         cUzorak += AllTrim( field->id2 )
         SKIP
      ENDDO

      // upisi u pomocnu tabelu
      SELECT r_export
      APPEND BLANK
      REPLACE field->idroba WITH cIdRoba
      REPLACE field->robanaz WITH cRobaNaz
      REPLACE field->sast WITH cUzorak

      SELECT roba_p
      SKIP

   ENDDO

   // sada provjera na osnovu uzoraka

   SELECT roba_p
   GO TOP

   DO WHILE !Eof()

      cTmpRoba := field->id
      cTmpNaz := AllTrim( field->naz )

      IF field->tip <> "P"
         SKIP
         LOOP
      ENDIF

      IF !Empty( cArtikli )
         IF &bUsl
         ELSE
            SKIP
            LOOP
         ENDIF
      ENDIF

      @ box_x_koord() + 1, box_y_koord() + 2 SAY "provjeravam uzorke: " + cTmpRoba

      IF !select_o_sastavnice( cTmpRoba )
         SELECT roba_p
         SKIP
         LOOP
      ENDIF

      cTmp := ""

      DO WHILE !Eof() .AND. field->id == cTmpRoba
         cTmp += AllTrim( field->id2 )
         SKIP
      ENDDO

      SELECT r_export
      SET ORDER TO TAG "1"
      GO TOP
      SEEK PadR( cTmp, 150 )

      DO WHILE !Eof() .AND. field->sast == PadR( cTmp, 150 )

         IF field->mark == "1"
            SKIP
            LOOP
         ENDIF

         IF field->idroba == cTmpRoba
            // ovo je ta sifra, preskoci
            REPLACE field->mark WITH "1"
            SKIP
            LOOP
         ENDIF

         // markiraj da sam ovaj artikal prosao
         REPLACE field->mark WITH "1"

         AAdd( aError, { AllTrim( cTmpRoba ) + " - " + ;
            AllTrim( cTmpNaz ), AllTrim( r_export->idroba ) + ;
            " - " + AllTrim( r_export->robanaz ) } )
         SKIP
      ENDDO


      SELECT roba_p
      SKIP
   ENDDO

   BoxC()

   IF Len( aError ) == 0
      MsgBeep( "sve ok :)" )
      RETURN .T.
   ENDIF

   START PRINT CRET

   i := 0

   ?

   cLine := Replicate( "-", 5 )
   cLine += Space( 1 )
   cLine += Replicate( "-", 50 )
   cLine += Space( 1 )
   cLine += Replicate( "-", 50 )

   cTxt := PadR( "rbr", 5 )
   cTxt += Space( 1 )
   cTxt += PadR( "roba uzorak", 50 )
   cTxt += Space( 1 )
   cTxt += PadR( "ima i u", 50 )

   P_COND
   ? cLine
   ? cTxt
   ? cLine

   nCnt := 0

   FOR i := 1 TO Len( aError )

      ? PadL( AllTrim( Str( ++nCnt ) ) + ")", 5 )
      @ PRow(), PCol() + 1 SAY PadR( aError[ i, 1 ], 50 )
      @ PRow(), PCol() + 1 SAY PadR( aError[ i, 2 ], 50 )

   NEXT

   FF
   ENDPRINT

   RETURN .T.

/*
FUNCTION _exp_sast_dbf()

   LOCAL aDbf := {}

   AAdd( aDbf, { "R_ID", "C", 10, 0 } )
   AAdd( aDbf, { "R_NAZ", "C", 200, 0 } )
   AAdd( aDbf, { "R_JMJ", "C", 3, 0 } )
   AAdd( aDbf, { "S_ID", "C", 10, 0 } )
   AAdd( aDbf, { "S_NAZ", "C", 200, 0 } )
   AAdd( aDbf, { "S_JMJ", "C", 3, 0 } )
   AAdd( aDbf, { "KOL", "N", 12, 2 } )
   AAdd( aDbf, { "NC", "N", 12, 2 } )
   AAdd( aDbf, { "VPC", "N", 12, 2 } )
   AAdd( aDbf, { "MPC", "N", 12, 2 } )

   IF !xlsx_export_init( aDbf )
      RETURN .F.
   ENDIF

   o_r_export_legacy()
   o_sastavnice()
   o_roba()

   SELECT sast
   SET ORDER TO TAG "ID"
   GO TOP

   Box(, 1, 50 )
   DO WHILE !Eof()

      cIdRoba := field->id

      IF Empty( cIdROba )
         SKIP
         LOOP
      ENDIF

      SELECT roba
      GO TOP
      SEEK cIdRoba

      cR_naz := field->naz
      cR_jmj := field->jmj

      SELECT sast

      DO WHILE !Eof() .AND. field->id == cIdRoba

         cSast := field->id2
         nKol := field->kolicina

         SELECT roba
         GO TOP
         SEEK cSast

         cNaz := field->naz
         nCjen := field->nc

         SELECT sast

         @ box_x_koord() + 1, box_y_koord() + 2 SAY "upisujem: " + cIdRoba

         SELECT r_export
         APPEND BLANK

         REPLACE field->r_id WITH cIdRoba
         REPLACE field->r_naz WITH cR_naz
         REPLACE field->r_jmj WITH cR_jmj
         REPLACE field->s_id WITH cSast
         REPLACE field->s_naz WITH cNaz
         REPLACE field->kol WITH nKol
         REPLACE field->nc WITH nCjen

         SELECT sast
         SKIP

      ENDDO

   ENDDO

   BoxC()

   MsgBeep( "Podaci se nalaze u " + my_home() + "r_export.dbf tabeli !" )

   SELECT r_export
   USE

   RETURN .T.
*/
