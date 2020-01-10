/* Copyright 2017-2019 Rafał Jopek ( rafaljopek at hotmail com ) */
/* License: MIT */


// #include "directry.ch"
#include "fileio.ch"
#include "hbgtinfo.ch"
#include "inkey.ch"
#include "setcurs.ch"

#define DIR_PREFIX( v )  iif( "D" $ v[ F_ATTR ], "A", "B" )


/*
    lEdit - .F. - view only
*/
PROCEDURE hc_edit( cFileName, lEdit )

   LOCAL cString
   LOCAL aString
   LOCAL lContinue := .T.
   LOCAL nMaxRow := 0, nMaxCol := 0
   LOCAL nRow := 1, nCol := 0, nRowNo := 0, nColNo := 0
   LOCAL cStringEditingRow
   LOCAL cSubString
   LOCAL lToggleInsert := .F.
   LOCAL nKey, nKeyStd
   LOCAL nOldRow, nOldCol
   LOCAL cScreen
   LOCAL tsDateTime

   nOldRow := Row()
   nOldCol := Col()
   cScreen := SaveScreen( 0, 0, MaxRow(), MaxCol() )

   IF HB_ISSTRING( cFileName ) // ?

      cString := hb_MemoRead( cFileName )

      aString := hb_ATokens( cString, .T. )

      DO WHILE lContinue

         IF nMaxRow != MaxRow() .OR. nMaxCol != MaxCol()
            nMaxRow := MaxRow()
            nMaxCol := MaxCol()

            IF nRow > nMaxRow - 1
               nRow := nMaxRow - 1
            ENDIF

            hc_edit_display( aString, nRow, nCol, nRowNo )

         ENDIF

         DispBegin()
         hb_DispOutAt( 0, 0, ;
            PadR( cFileName + "  ", nMaxCol + 1 ), 0x30 )

         hc_edit_display( aString, nRow, nCol, nRowNo )

         hb_vfTimeGet( cFileName, @tsDateTime )
         hb_DispOutAt( nMaxRow, 0, ;
            PadR( " Row(" + hb_ntos( nRow + nRowNo ) + ") Col(" + hb_ntos( nCol + 1 ) + ") Size(" + hb_ntos( hb_vfSize( cFileName ) ) + ") Date(" + hb_TToC( tsDateTime ) + ")", nMaxCol + 1 ), 0x30 )
         DispEnd()

         nKey := Inkey( 0 )
         nKeyStd := hb_keyStd( nKey )

         SWITCH nKeyStd

         CASE K_ESC
            lContinue := .F.
            EXIT

         CASE K_LBUTTONDOWN

            IF MRow() > 0 .AND. MCol() > 0 .AND. MRow() < Len( aString ) + 1 .AND. MCol() < nMaxCol
               nRow := MRow()
               nCol := Len( aString[ nRowNo + nRow ] )
            ENDIF

            EXIT

         CASE K_MWFORWARD

            IF nRowNo >= 1
               nRowNo--
            ENDIF

            EXIT

         CASE K_MWBACKWARD

            IF nRow + nRowNo < Len( aString )
               nRowNo++
            ENDIF

            EXIT

         CASE K_UP

            IF nRow > 1
               nRow--
            ELSE
               IF nRowNo >= 1
                  nRowNo--
               ENDIF
            ENDIF

            IF aString[ nRowNo + nRow ] == ""
               nCol  := 0
            ELSE
               IF nCol > Len( aString[ nRowNo + nRow ] )
                  nCol := Len( aString[ nRowNo + nRow ] )
               ENDIF
            ENDIF

            EXIT

         CASE K_LEFT

            IF nCol > 0
               nCol--
            ELSE
               IF nColNo > 0
                  nColNo--
               ENDIF
            ENDIF

            EXIT

         CASE K_DOWN

            IF nRow < nMaxRow - 1 .AND. nRow < Len( aString )
               nRow++
            ELSE
               IF nRowNo + nRow < Len( aString )
                  nRowNo++
               ENDIF
            ENDIF

            IF aString[ nRowNo + nRow ] == ""
               nCol := 0
            ELSE
               IF nCol > Len( aString[ nRowNo + nRow ] )
                  nCol := Len( aString[ nRowNo + nRow ] )
               ENDIF
            ENDIF

            EXIT

         CASE K_RIGHT

            IF nCol < Len( aString[ nRowNo + nRow ] )
               nCol++
            ENDIF

            EXIT

         CASE K_HOME

            nCol := 0

            EXIT

         CASE K_END

            nCol := Len( aString[ nRowNo + nRow ] )

            EXIT

         CASE K_PGUP

            IF nRow <= 1
               IF nRowNo - nMaxRow >= 0
                  nRowNo -= nMaxRow
               ENDIF
            ENDIF
            nRow := 1

            EXIT

         CASE K_PGDN

            IF nRow >= nMaxRow - 1
               IF nRowNo + nMaxRow  <= Len( aString )
                  nRowNo += nMaxRow
               ENDIF
            ENDIF
            nRow := Min( nMaxRow - 1, Len( aString ) - nRowNo )

            hb_Scroll( 1, 0, nMaxRow, nMaxCol )

            EXIT

         CASE K_CTRL_PGUP

            nRow := 0
            nRowNo := 0

            EXIT

         CASE K_CTRL_PGDN

            nRow := nMaxRow - 1
            nRowNo := Len( aString ) - nMaxRow + 1

            EXIT

         CASE K_ENTER

            IF lEdit
               IF aString[ nRowNo + nRow ] == "" .OR. nCol == 0

                  hb_AIns( aString, nRowNo + nRow, "", .T. )
                  nRow++
               ELSE
                  IF nCol == Len( aString[ nRowNo + nRow ] )
                     hb_AIns( aString, nRowNo + nRow + 1, "", .T. )
                     nRow++
                     nCol := 0
                  ELSE
                     cSubString := Right( aString[ nRowNo + nRow ], Len( aString[ nRowNo + nRow ] ) - nCol )
                     cStringEditingRow := aString[ nRowNo + nRow ]
                     aString[ nRowNo + nRow ] := Stuff( cStringEditingRow, nCol + 1, Len( aString[ nRowNo + nRow ] ) - nCol, "" )
                     hb_AIns( aString, nRowNo + nRow + 1, cSubString, .T. )
                     nRow++
                     nCol := 0
                  ENDIF
               ENDIF

               SaveFile( aString, cFileName )

            ENDIF
            EXIT

         CASE K_INS
            IF lEdit
               IF lToggleInsert
                  SetCursor( SC_NORMAL )
                  lToggleInsert := .F.
               ELSE
                  SetCursor( SC_INSERT )
                  lToggleInsert := .T.
               ENDIF
            ENDIF
            EXIT

         CASE K_DEL
            IF lEdit
               IF aString[ nRowNo + nRow ] == ""
                  IF nRow >= 0
                     hb_ADel( aString, nRowNo + nRow, .T. )
                  ENDIF
               ELSE
                  IF nCol == Len( aString[ nRowNo + nRow ] )

                     aString[ nRowNo + nRow ] += aString[ nRowNo + nRow + 1 ]

                     hb_ADel( aString, nRowNo + nRow + 1, .T. )
                  ELSE
                     cStringEditingRow := aString[ nRowNo + nRow ]
                     aString[ nRowNo + nRow ] := Stuff( cStringEditingRow, nCol + 1, 1, "" )
                  ENDIF
               ENDIF

               SaveFile( aString, cFileName )

            ENDIF
            EXIT

         CASE K_BS
            IF lEdit
               IF aString[ nRowNo + nRow ] == ""
                  IF nRow > 1
                     hb_ADel( aString, nRowNo + nRow, .T. )
                     nRow--
                     nCol := Len( aString[ nRowNo + nRow ] )
                  ENDIF
               ELSE
                  IF nCol > 0
                     cStringEditingRow := aString[ nRowNo + nRow ]
                     aString[ nRowNo + nRow ] := Stuff( cStringEditingRow, nCol, 1, "" )
                     nCol--
                  ELSE
                     IF nRow > 1
                        IF aString[ nRowNo + nRow - 1 ] == ""
                           nCol := 0
                        ELSE
                           nCol := Len( aString[ nRowNo + nRow - 1 ] )
                        ENDIF

                        aString[ nRowNo + nRow - 1 ] += aString[ nRowNo + nRow ]

                        hb_ADel( aString, nRowNo + nRow, .T. )
                        nRow--
                     ENDIF
                  ENDIF
               ENDIF

               SaveFile( aString, cFileName )

            ENDIF
            EXIT

         CASE K_TAB
            IF lEdit
               cStringEditingRow := aString[ nRowNo + nRow ]

               aString[ nRowNo + nRow ] := Stuff( cStringEditingRow, nCol + 1, iif( lToggleInsert, 1, 0 ), "   " )
               nCol += 3

               SaveFile( aString, cFileName )

            ENDIF
            EXIT

         OTHERWISE

            IF lEdit
               IF ( nKeyStd >= 32 .AND. nKeyStd <= 126 ) .OR. ( nKeyStd >= 160 .AND. nKeyStd <= 255 ) .OR. ! hb_keyChar( nKeyStd ) == ""

                  cStringEditingRow := aString[ nRowNo + nRow ]
                  aString[ nRowNo + nRow ] := Stuff( cStringEditingRow, nCol + 1, iif( lToggleInsert, 1, 0 ), hb_keyChar( nKeyStd ) )
                  nCol++

                  SaveFile( aString, cFileName )

               ENDIF
            ENDIF

         ENDSWITCH

      ENDDO

   ELSE
      HC_Alert( "Error reading:;" + cFileName )
      RETURN
   ENDIF

   RestScreen( 0, 0, MaxRow(), MaxCol(), cScreen )
   SetPos( nOldRow, nOldCol )

   RETURN


STATIC PROCEDURE hc_edit_display( aString, nRow, nCol, nRowNo )

   LOCAL i
   LOCAL nMaxRow := MaxRow(), nMaxCol := MaxCol()
   LOCAL nLine

   hb_Scroll( 2, 0, nMaxRow - 2, nMaxCol )

   FOR i := 1 TO nMaxRow

      nLine := i + nRowNo

      IF nLine <= Len( aString )
         hb_DispOutAt( i, 0, ;
            PadR( aString[ nLine ], nMaxCol + 1 ), ;
            iif( i == nRow, 0x8f, 0x7 ) )
      ELSE
         hb_Scroll( i, 0, nMaxRow, nMaxCol + 1 )
         hb_DispOutAt( i, 1, ">> EOF <<", 0x01 )
         EXIT
      ENDIF

   NEXT

   SetPos( nRow, nCol )

   RETURN

STATIC PROCEDURE SaveFile( aString, cFileName )

   LOCAL cString := ""

   AEval( aString, {| e | cString += e + hb_eol() } )
   hb_MemoWrit( cFileName, cString )

   RETURN

STATIC FUNCTION FileError()
   RETURN { ;
      {   0, "The operation completed successfully." }, ;
      {   2, "The system cannot find the file specified." }, ;
      {   3, "The system cannot find the path specified." }, ;
      {   4, "The system cannot open the file." }, ;
      {   5, "Access is denied." }, ;
      {   6, "The handle is invalid." }, ;
      {   8, "Not enough storage is available to process this command." }, ;
      {  15, "The system cannot find the drive specified." }, ;
      {  16, "The directory cannot be removed." }, ;
      {  17, "The system cannot move the file to a different disk drive." }, ;
      {  18, "There are no more files." }, ;
      {  19, "Attempted to write to a write-protected disk." }, ;
      {  21, "The device is not ready." }, ;
      {  23, "Data error (cyclic redundancy check)." }, ;
      {  29, "The system cannot write to the specified device." }, ;
      {  30, "The system cannot read from the specified device." }, ;
      {  32, "The process cannot access the file because ; it is being used by another process." }, ;
      {  33, "The process cannot access the file because ; another process has locked a portion of the file." }, ;
      {  36, "Too many files opened for sharing." }, ;
      {  38, "Reached the end of the file." }, ;
      {  62, "Space to store the file waiting to be printed ; is not available on the server." }, ;
      {  63, "Your file waiting to be printed was deleted." }, ;
      {  80, "The file exists." }, ;
      {  82, "The directory or file cannot be created." }, ;
      { 110, "The system cannot open the device or file specified." }, ;
      { 111, "The file name is too long" }, ;
      { 113, "No more internal file identifiers available." }, ;
      { 114, "The target internal file identifier is incorrect." }, ;
      { 123, "The filename, directory name, ; or volume label syntax is incorrect." }, ;
      { 130, "Attempt to use a file handle to an open disk ; partition for an operation other than raw disk I/O." }, ;
      { 131, "An attempt was made to move the file pointer ; before the beginning of the file." }, ;
      { 132, "The file pointer cannot be set on the specified ; device or file." }, ;
      { 138, "The system tried to join a drive ; to a directory on a joined drive." }, ;
      { 139, "The system tried to substitute a drive ; to a directory on a substituted drive." }, ;
      { 140, "The system tried to join a drive ; to a directory on a substituted drive." }, ;
      { 141, "The system tried to SUBST a drive ; to a directory on a joined drive." }, ;
      { 143, "The system cannot join or substitute a drive ; to or for a directory on the same drive." }, ;
      { 144, "The directory is not a subdirectory of the root directory." }, ;
      { 145, "The directory is not empty." }, ;
      { 150, "System trace information was not specified ; in your CONFIG.SYS file, or tracing is disallowed." }, ;
      { 154, "The volume label you entered exceeds ; the label character limit of the target file system." }, ;
      { 167, "Unable to lock a region of a file." }, ;
      { 174, "The file system does not support ; atomic changes to the lock type." }, ;
      }




STATIC FUNCTION HC_Alert( cTitle, xMessage, xOptions, nColorNorm, nArg )

   LOCAL nOldCursor := SetCursor( SC_NONE )

   // LOCAL nRowPos := Row(), nColPos := Col()
   LOCAL aMessage, aOptions, aPos
   LOCAL nColorHigh
   LOCAL nLenOptions, nLenMessage
   LOCAL nWidth := 0
   LOCAL nLenght := 0
   LOCAL nPos
   LOCAL i
   LOCAL nMaxRow := 0, nMaxCol := 0
   LOCAL nRow, nCol
   LOCAL nKey, nKeyStd
   LOCAL nTop, nLeft, nBottom, nRight
   LOCAL nChoice := 1
   LOCAL nMRow, nMCol

   DO CASE
   CASE ValType( cTitle ) == "U"
      cTitle := "OK"
   ENDCASE

   DO CASE
   CASE ValType( xMessage ) == "U"
      aMessage := { "" }
   CASE ValType( xMessage ) == "C"
      aMessage := hb_ATokens( xMessage, ";" )
   CASE ValType( xMessage ) == "A"
      aMessage := xMessage
   CASE ValType( xMessage ) == "N"
      aMessage := hb_ATokens( hb_CStr( xMessage ) )
   ENDCASE

   DO CASE
   CASE ValType( xOptions ) == "U"
      aOptions := { "OK" }
   CASE ValType( xOptions ) == "C"
      aOptions := hb_ATokens( xOptions, ";" )
   CASE ValType( xOptions ) == "A"
      aOptions := xOptions
   ENDCASE

   DO CASE
   CASE ValType( nColorNorm ) == "U"
      nColorNorm := 0x4f
      nColorHigh := 0x1f
   CASE ValType( nColorNorm ) == "N"
      nColorNorm := hb_bitAnd( nColorNorm, 0xff )
      nColorHigh := hb_bitAnd( hb_bitOr( hb_bitShift( nColorNorm, - 4 ), hb_bitShift( nColorNorm, 4 ) ), 0x77 )
   ENDCASE

   nLenOptions := Len( aOptions )
   FOR i := 1 TO nLenOptions
      nWidth += Len( aOptions[ i ] ) + 2
      nLenght += Len( aOptions[ i ] ) + 2
   NEXT

   /* w pętli przechodzę przez nWidth, wybieram co jest większe */
   nLenMessage := Len( aMessage )
   FOR i := 1 TO nLenMessage
      nWidth := Max( nWidth, Len( aMessage[ i ] ) )
   NEXT

   DO WHILE .T.

      DispBegin()

      /* zachowanie drugiego ustawienia ! */
      IF nMaxRow != MaxRow( .T. ) .OR. nMaxCol != iif( nArg == NIL, MaxCol( .T. ), iif( nArg == 0x0, Int( MaxCol( .T. ) / 2 ), MaxCol( .T. ) + Int( MaxCol( .T. ) / 2 ) ) )

         WSelect( 0 )

         nMaxRow := MaxRow( .T. )
         /* ostatni parametr ustawia okienko dialogowe: NIL środek, 0x0 po lewo i 0x1 po prawo */
         nMaxCol := iif( nArg == NIL, MaxCol( .T. ), iif( nArg == 0x0, Int( MaxCol( .T. ) / 2 ), MaxCol( .T. ) + Int( MaxCol( .T. ) / 2 ) ) )

         nTop    := Int( nMaxRow / 3 ) - 3
         nLeft   := Int( ( nMaxCol - nWidth ) / 2 ) - 2
         nBottom := nTop + 4 + nLenMessage
         nRight  := Int( ( nMaxCol + nWidth ) / 2 ) - 1 + 2

         WClose( 1 )
         WSetShadow( 0x8 )
         WOpen( nTop, nLeft, nBottom, nRight, .T. )

         hb_DispBox( 0, 0, nMaxRow, nMaxCol, hb_UTF8ToStrBox( " █       " ), nColorNorm )
         hb_DispOutAt( 0, 0, Center( cTitle ), hb_bitShift( nColorNorm, 4 ) )

         FOR nPos := 1 TO Len( aMessage )
            hb_DispOutAt( 1 + nPos, 0, Center( aMessage[ nPos ] ), nColorNorm )
         NEXT

      ENDIF

      /* zapisuje współrzędne przycisków aOptions */
      aPos := {}
      nRow := nPos + 2
      nCol := Int( ( MaxCol() + 1 - nLenght - nLenOptions + 1 ) / 2 )

      FOR i := 1 TO nLenOptions
         AAdd( aPos, nCol )
         hb_DispOutAt( nRow, nCol, " " + aOptions[ i ] + " ", iif( i == nChoice, nColorHigh, nColorNorm ) )
         nCol += Len( aOptions[ i ] ) + 3
      NEXT

      DispEnd()

      nKey := Inkey( 0 )
      nKeyStd := hb_keyStd( nKey )

      DO CASE
      CASE nKeyStd == K_ESC
         nChoice := 0
         EXIT

      CASE nKeyStd == K_ENTER .OR. nKeyStd == K_SPACE
         EXIT

      CASE nKeyStd == K_MOUSEMOVE

         FOR i := 1 TO nLenOptions
            IF MRow() == nPos + 2 .AND. MCol() >= aPos[ i ] .AND. MCol() <= aPos[ i ] + Len( aOptions[ i ] ) + 1
               nChoice := i
            ENDIF
         NEXT

      CASE nKeyStd == K_LBUTTONDOWN

         nMCol := MCol()
         nMRow := MRow()

         IF MRow() == 0 .AND. MCol() >= 0 .AND. MCol() <= MaxCol()

            DO WHILE MLeftDown()
               WMove( WRow() + MRow() - nMRow, WCol() + MCol() - nMCol )
            ENDDO

         ENDIF

         FOR i := 1 TO nLenOptions
            IF MRow() == nPos + 2 .AND. MCol() >= aPos[ i ] .AND. MCol() <= aPos[ i ] + Len( aOptions[ i ] ) + 1
               nChoice := i
               EXIT
            ENDIF
         NEXT

         IF nChoice == i
            EXIT
         ENDIF

      CASE ( nKeyStd == K_LEFT .OR. nKeyStd == K_SH_TAB ) .AND. nLenOptions > 1

         nChoice--
         IF nChoice == 0
            nChoice := nLenOptions
         ENDIF

      CASE ( nKeyStd == K_RIGHT .OR. nKeyStd == K_TAB ) .AND. nLenOptions > 1

         nChoice++
         IF nChoice > nLenOptions
            nChoice := 1
         ENDIF

      CASE nKeyStd == K_CTRL_UP
         WMove( WRow() - 1, WCol() )

      CASE nKeyStd == K_CTRL_DOWN
         WMove( WRow() + 1, WCol() )

      CASE nKeyStd == K_CTRL_LEFT
         WMove( WRow(), WCol() - 1 )

      CASE nKeyStd == K_CTRL_RIGHT
         WMove( WRow(), WCol() + 1 )

      CASE nKeyStd == HB_K_RESIZE

         WClose( 1 )

         AutoSize()

         PanelDisplay( aPanelLeft )
         PanelDisplay( aPanelRight )
         ComdLineDisplay( aPanelSelect )

         BottomBar()

      ENDCASE

   ENDDO

   WClose( 1 )
   SetCursor( nOldCursor )
   // SetPos( nRowPos, nColPos )

   RETURN iif( nKey == 0, 0, nChoice )


STATIC PROCEDURE PanelDisplay( aPanel )

   LOCAL nRow, nPos := 1
   LOCAL nLengthName := 4 /* 4 is len of top element ".." plus brackets "[" and "]" */
   LOCAL nLengthSize := 0

   AScan( aPanel[ _aDirectory ], {| x | ;
      nLengthName := Max( nLengthName, Len( x[ 1 ] ) ), ;
      nLengthSize := Max( nLengthSize, Len( Str( x[ 2 ] ) ) ) } )

   DispBegin()

   IF aPanelSelect == aPanel
      hb_DispBox( aPanel[ _nTop ], aPanel[ _nLeft ], aPanel[ _nBottom ], aPanel[ _nRight ], HB_B_DOUBLE_UNI + " ", 0x1f )
   ELSE
      hb_DispBox( aPanel[ _nTop ], aPanel[ _nLeft ], aPanel[ _nBottom ], aPanel[ _nRight ], HB_B_SINGLE_UNI + " ", 0x1f )
   ENDIF
         /* The item will be displayed from the menu selection
            hb_DispOutAt( aPanel[ _nTop ], aPanel[ _nLeft ] + 1, PadR( hb_StrShrink( aPanel[ _cCurrentDir ], 1 ), ;
               Min( aPanel[ _nRight ] - aPanel[ _nLeft ] - 1, Len( aPanel[ _cCurrentDir ] ) ) ), "GR+/W"  )
         */
   nPos += aPanel[ _nRowNo ]
   FOR nRow := aPanel[ _nTop ] + 1 TO aPanel[ _nBottom ] - 1

      IF nPos <= Len( aPanel[ _aDirectory ] )
         hb_DispOutAt( nRow, aPanel[ _nLeft ] + 1, ;
            PadR( Expression( nLengthName, nLengthSize, ;
            aPanel[ _aDirectory ][ nPos ][ F_NAME ], ;
            aPanel[ _aDirectory ][ nPos ][ F_SIZE ], ;
            aPanel[ _aDirectory ][ nPos ][ F_DATE ], ;
            aPanel[ _aDirectory ][ nPos ][ F_ATTR ] ), ;
            aPanel[ _nRight ] - aPanel[ _nLeft ] - 1 ), ;
            iif( aPanelSelect == aPanel .AND. nPos == aPanel[ _nRowBar ] + aPanel[ _nRowNo ], ;
            iif( ! aPanel[ _aDirectory ][ nPos ][ F_STATUS ], 0x3e, 0x30 ), ;
            ColoringSyntax( aPanel[ _aDirectory ][ nPos ][ F_ATTR ], aPanel[ _aDirectory ][ nPos ][ F_STATUS ] ) ) )
         ++nPos
      ELSE
         EXIT
      ENDIF

   NEXT

   // PanelTitleDisplay( aPanel )

   DispEnd()

   RETURN


STATIC PROCEDURE BottomBar()

   LOCAL nRow := MaxRow()
   LOCAL cSpaces
   LOCAL nCol := Int( MaxCol() / 10 ) + 1

   cSpaces := Space( nCol - 8 )

   hb_DispOutAt( nRow, 0,        " 1", 0x7 )
   hb_DispOutAt( nRow, 2,            "Help  " + cSpaces, 0x30 )
   hb_DispOutAt( nRow, nCol,     " 2", 0x7 )
   hb_DispOutAt( nRow, nCol + 2,     "Menu  " + cSpaces, 0x30 )
   hb_DispOutAt( nRow, nCol * 2, " 3", 0x7 )
   hb_DispOutAt( nRow, nCol * 2 + 2, "View  " + cSpaces, 0x30 )
   hb_DispOutAt( nRow, nCol * 3, " 4", 0x7 )
   hb_DispOutAt( nRow, nCol * 3 + 2, "Edit  " + cSpaces, 0x30 )
   hb_DispOutAt( nRow, nCol * 4, " 5", 0x7 )
   hb_DispOutAt( nRow, nCol * 4 + 2, "Copy  " + cSpaces, 0x30 )
   hb_DispOutAt( nRow, nCol * 5, " 6", 0x7 )
   hb_DispOutAt( nRow, nCol * 5 + 2, "RenMov" + cSpaces, 0x30 )
   hb_DispOutAt( nRow, nCol * 6, " 7", 0x7 )
   hb_DispOutAt( nRow, nCol * 6 + 2, "MkDir " + cSpaces, 0x30 )
   hb_DispOutAt( nRow, nCol * 7, " 8", 0x7 )
   hb_DispOutAt( nRow, nCol * 7 + 2, "Delete" + cSpaces, 0x30 )
   hb_DispOutAt( nRow, nCol * 8, " 9", 0x7 )
   hb_DispOutAt( nRow, nCol * 8 + 2, "PullDn" + cSpaces, 0x30 )
   hb_DispOutAt( nRow, nCol * 9, "10", 0x7 )
   hb_DispOutAt( nRow, nCol * 9 + 2, "Quit  " + cSpaces, 0x30 )

   RETURN


STATIC PROCEDURE AutoSize()

   Resize( aPanelLeft, 0, 0, MaxRow() - 2, MaxCol() / 2 )
   Resize( aPanelRight, 0, MaxCol() / 2 + 1, MaxRow() - 2, MaxCol() )

   RETURN

STATIC PROCEDURE Resize( aPanel, nTop, nLeft, nBottom, nRight )

   aPanel[ _nTop    ] := nTop
   aPanel[ _nLeft   ] := nLeft
   aPanel[ _nBottom ] := nBottom
   aPanel[ _nRight  ] := nRight

   RETURN



STATIC PROCEDURE ComdLineDisplay( aPanel )

   LOCAL nMaxRow := MaxRow(), nMaxCol := MaxCol()

   DispBegin()

   hb_DispOutAt( nMaxRow - 1, 0, ;
      PadR( aPanel[ _cCurrentDir ] + SubStr( aPanel[ _cComdLine ], 1 + aPanel[ _nComdColNo ], nMaxCol + aPanel[ _nComdColNo ] ), nMaxCol ), 0x7 )

   SetPos( nMaxRow - 1, aPanel[ _nComdCol ] + Len( aPanel[ _cCurrentDir ] ) )

   DispEnd()

   RETURN


STATIC FUNCTION Expression( nLengthName, nLengthSize, cName, cSize, dDate, cAttr )

   LOCAL cFileName, cFileSize, dFileDate, cFileAttr

   iif( nLengthName == 2, nLengthName := 4, nLengthName )

   cFileName := PadR( cName + Space( nLengthName ), nLengthName ) + " "

   IF cName == ".."
      cFileName := PadR( "[" + AllTrim( cFileName ) + "]" + Space( nLengthName ), nLengthName ) + " "
   ENDIF

   IF cAttr == "D" .OR. cAttr == "HD" .OR. cAttr == "HSD" .OR. cAttr == "HSDL" .OR. cAttr == "RHSA" .OR. cAttr == "RD" .OR. cAttr == "AD" .OR. cAttr == "RHD"
      cFileSize := PadL( "DIR", nLengthSize + 3 ) + " "
   ELSE
      cFileSize := PadL( Transform( cSize, "9 999 999 999" ), nLengthSize + 3 ) + " "
   ENDIF

   dFileDate := hb_TToC( dDate ) + " "
   cFileAttr := PadL( cAttr, 3 )

   RETURN cFileName + cFileSize + dFileDate + cFileAttr



STATIC FUNCTION ColoringSyntax( cAttr, lStatus )

   LOCAL nColor

   IF cAttr == "HD" .OR. cAttr == "HSD" .OR. cAttr == "HSDL" .OR. cAttr == "RHSA" .OR. cAttr == "RD"
      nColor := 0x13
   ELSE
      nColor := 0x1f
   ENDIF

   IF ! lStatus
      nColor := 0x1e
   ENDIF

   RETURN nColor
