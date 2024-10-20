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



FUNCTION BrowseKey( y1, x1, y2, x2, ImeKol, bfunk, uslov, traz, brkol, dx, dy, bPodvuci )

   STATIC poziv := 0
   LOCAL lk, REKORD, TCol
   LOCAL nCurRec := 1
   LOCAL nRecCnt := 0

   PRIVATE TB
   PRIVATE usl

   usl = 'USL' + AllTrim( Str( POZIV, 2 ) )
   POZIV++
   &usl = uslov


   BEGIN SEQUENCE WITH {| oErr | Break( oErr ) }
      TB := TBrowseDB( y1, x1, y2, x2 )
   RECOVER using oErr
      Alert( _u("Povećati ekran. Nema se gdje nacrtati tabela!"))
      RETURN .F.
   END SEQUENCE


  
   TB:headsep := hb_UTF8ToStrBox( BROWSE_HEAD_SEP )
   TB:colsep := hb_UTF8ToStrBox( BROWSE_COL_SEP )

   IF Eof()
      SKIP -1
   ENDIF

   SEEK traz
   DO while  &( &usl )
      nRecCnt++
      SKIP
   ENDDO

   SEEK traz
   IF !Found()
      nCurRec := 0
   ENDIF

   FOR i := 1 TO Len( ImeKol )
      TCol := TBColumnNew( ImeKol[ i, 1 ], Imekol[ i, 2 ] )
      IF bPodvuci <> NIL
         TCol:colorBlock := {|| iif( Eval( bPodvuci ), { 5, 2 }, { 1, 2 } ) }
      ENDIF
      TB:addcolumn( TCol )
   NEXT

   IF !Empty( brkol ) .AND. ValType( brkol ) = 'N'
      TB:freeze := brkol
   ENDIF

   TB:skipblock := {| x| korisnik( x, traz, dx, dy, @nCurRec, @nRecCnt ) }

   Eval( bfunk, 0 )

   DO WHILE .T.
      IF dx <> NIL .AND. dy <> NIL
         @ box_x_koord() + dx, box_y_koord() + dy SAY Str( nRecCnt, 4 )
      ENDIF

      DO WHILE !Tb:stable .AND. ( ( lk := Inkey() ) == 0 )
         Tb:stabilize()
      ENDDO

      IF TB:stable .AND. ( lk := Inkey() ) == 0

         IF dx <> NIL .AND. dy <> NIL
            @ box_x_koord() + dx, box_y_koord() + dy SAY Str( nRecCnt, 4 )
         ENDIF

         lk := Inkey( 0 )
      ENDIF




      IF lk == K_ESC
         POZIV--
         EXIT

      ELSEIF lk = K_DOWN
         TB:down()
      ELSEIF lk = K_UP
         TB:up()
      ELSEIF lk = K_RIGHT
         TB:Right()
      ELSEIF lk = K_LEFT
         TB:Left()
      ELSEIF lk = K_END
         TB:end()
      ELSEIF lk = K_HOME
         TB:home()
      ELSEIF lk = K_PGDN
         TB:pagedown()
      ELSEIF lk = K_PGUP
         TB:pageup()
      ELSEIF lk = 26
         TB:panleft()
      ELSEIF lk = 2
         TB:panright()
      ELSE
         povrat := Eval( bFunk, lk )
         IF povrat == 0
            POZIV--
            EXIT
         ELSEIF povrat == DE_ADD
            nRecCnt++
            TB:refreshall()
         ELSEIF povrat == DE_DEL
            IF nRecCnt > 0
               nRecCnt--
            ENDIF
            TB:refreshall()
         ELSEIF povrat == DE_REFRESH
            TB:refreshall()
         ENDIF
      ENDIF

   ENDDO

   RETURN ( nil )



STATIC FUNCTION Korisnik( nRequest, traz, dx, dy, nCurRec, nRecCnt )

   LOCAL nCount

   nCount := 0
   IF LastRec() != 0
      IF !&( &usl )
         SEEK traz
         IF ! &( &usl )
            GO BOTTOM
            SKIP 1
         ENDIF
         nRequest = 0
      ENDIF
      IF nRequest > 0
         DO WHILE nCount < nRequest .AND. &( &usl )
            SKIP 1
            nCurRec++
            IF Eof() .OR. ! &( &usl )
               SKIP -1
               nCurRec--
               EXIT
            ENDIF
            nCount++
         ENDDO
      ELSEIF nRequest < 0
         DO WHILE nCount > nRequest .AND. &( &usl )
            SKIP -1
            nCurRec--
            IF ( Bof() )
               nCurRec++
               EXIT
            ENDIF
            nCount--
         ENDDO
         IF ! &( &usl )
            SKIP 1
            nCurRec++
            nCount++
         ENDIF
      ENDIF
   ENDIF
   IF dx <> NIL .AND. dy <> NIL
      // @ box_x_koord()+dx,box_y_koord()+dy say STR(nCurRec,4)+"/"+STR(nRecCnt,4)
      @ box_x_koord() + dx, box_y_koord() + dy SAY Str( nRecCnt, 4 )
   ENDIF

   RETURN ( nCount )
