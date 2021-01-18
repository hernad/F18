#include "f18.ch"

// http://www.harbourdoc.com.br/show.asp?seek=description&key=PDFClass

STATIC s_cFont := "Courier"
STATIC s_codePage := "CP1250"
STATIC s_cEmbeddedFontFileName := 'ubuntu-mono.ttf'

CREATE CLASS PDFClass

   VAR    oPdf
   VAR    oPage
   VAR    cFileName         INIT ""
   VAR    nRow              INIT 999
   VAR    nLeftSpace        INIT 0
   VAR    nCol              INIT 0
   VAR    nAngle            INIT 0
   VAR    cFontName         INIT s_cFont
   VAR    nFontSize         INIT 7
   VAR    nLineHeight       INIT 1.3
   VAR    nMargin           INIT 20 // margina
   VAR    nType             INIT 1
   VAR    nPdfPage          INIT 0
   VAR    nPageNumber       INIT 0
   VAR    cHeader           INIT {}
   VAR    cCodePage         INIT s_codePage
   VAR    cEmbeddedFontName
   VAR    nXScale           INIT 1
   VAR    nYScale           INIT 1
   VAR    lConsole
   VAR    cPrinter
   VAR    cDevice

   METHOD AddPage()
   METHOD RowToPDFRow( nRow )
   METHOD ColToPDFCol( nCol )
   METHOD MaxRow()
   METHOD MaxCol()
   METHOD DrawText( nRow, nCol, xValue, cPicture, nFontSize, cFontName, nAngle, aNRGB )
   METHOD DrawLine( nRowi, nColi, nRowf, nColf, nPenSize )
   METHOD DrawRectangle( nTop, nLeft, nWidth, nHeight, nPenSize, nFillType, aNRGB )
   METHOD DrawImage( cJPEGFile, nRow, nCol, nWidth, nHeight )
   METHOD Cancel()
   METHOD PrnToPdf( cInputFile )
   METHOD SetType( nType )
   METHOD SetFontSize( nFontSize )
   METHOD SetLeftSpace( nLeft )
   METHOD PageHeader()
   METHOD MaxRowTest( nRows )
   METHOD SetInfo( cAuthor, cCreator, cTitle, cSubject )
   METHOD BEGIN()
   METHOD END()
   METHOD View()

ENDCLASS

METHOD BEGIN() CLASS PDFClass

   LOCAL cFontFile

   cFontFile := f18_template_file_name( s_cEmbeddedFontFileName )
   IF File( cFontFile )
      ::nXScale := 1.10
      ::nYScale := 1.20
   ENDIF

   IF ::nType == PDF_TXT_PORTRAIT .OR. ::nType == PDF_TXT_LANDSCAPE
      IF Empty( ::cFileName )
         ::cFileName := MyTempFile( "LST" )
      ENDIF
      ::cPrinter := Set( _SET_PRINTER, ::cFileName )
      ::cDevice := Set( _SET_DEVICE, "PRINTER" )
      ::lConsole := Set( _SET_CONSOLE )
   ELSE
      IF Empty( ::cFileName )
         ::cFileName := MyTempFile( "PDF" )
      ENDIF
      ::oPdf := HPDF_New()
      HPDF_SetCompressionMode( ::oPdf, HPDF_COMP_ALL )

      IF File( cFontFile )
         ::cEmbeddedFontName := HPDF_LoadTTFontFromFile( ::oPdf, cFontFile, .T. )
         // info_bar( "pdf", ::cEmbeddedFontName + " / " + AllTrim( Str( ::nFontSize ) ) )
         ::cFontName := ::cEmbeddedFontName
      ENDIF

      IF ::cCodePage != NIL
         HPDF_SetCurrentEncoder( ::oPDF, ::cCodePage )
      ENDIF
   ENDIF

   RETURN NIL


METHOD END() CLASS PDFClass

   IF ::nType == PDF_TXT_PORTRAIT .OR. ::nType == PDF_TXT_LANDSCAPE
      Set( _SET_PRINTER, ::cPrinter )
      Set( _SET_DEVICE, ::cDevice )
      Set( _SET_CONSOLE, ::lConsole )
   ELSE
      IF File( ::cFileName )
         FErase( ::cFileName )
      ENDIF
      HPDF_SaveToFile( ::oPdf, ::cFileName )
      HPDF_Free( ::oPdf )

   ENDIF

   RETURN NIL

METHOD SetInfo( cAuthor, cCreator, cTitle, cSubject ) CLASS PDFClass

   IF ::nType == PDF_TXT_PORTRAIT .OR. ::nType == PDF_TXT_LANDSCAPE
      RETURN NIL
   ENDIF

   cAuthor  := iif( cAuthor == NIL, "bring.out", cAuthor )
   cCreator := iif( cCreator == NIL, "Harupdf", cCreator )
   cTitle   := iif( cTitle == NIL, "", cTitle )
   cSubject := iif( cSubject == NIL, cTitle, cSubject )

   HPDF_SetInfoAttr( ::oPDF, HPDF_INFO_AUTHOR, cAuthor )
   HPDF_SetInfoAttr( ::oPDF, HPDF_INFO_CREATOR, cCreator )
   HPDF_SetInfoAttr( ::oPDF, HPDF_INFO_TITLE, cTitle )
   HPDF_SetInfoAttr( ::oPdf, HPDF_INFO_SUBJECT, cSubject )
   HPDF_SetInfoDateAttr( ::oPDF, HPDF_INFO_CREATION_DATE, { Year( Date() ), Month( Date() ), Day( Date() ), ;
      Val( SubStr( Time(), 1, 2 ) ), Val( SubStr( Time(), 4, 2 ) ), Val( SubStr( Time(), 7, 2 ) ), "+", 4, 0 } )

   RETURN NIL

METHOD SetType( nType ) CLASS PDFClass

   IF nType != NIL
      ::nType := nType
   ENDIF
   /*
   IF ::nType == PDF_PORTRAIT .OR. ::nType == PDF_TXT_PORTRAIT
      ::nFontSize := 9
   ELSE
      ::nFontSize := 6
   ENDIF
   */

   RETURN NIL

METHOD SetFontSize( nFontSize ) CLASS PDFClass

   IF nFontSize != NIL
      ::nFontSize := nFontSize
   ENDIF

   RETURN NIL

METHOD SetLeftSpace( nLeft ) CLASS PDFClass

   IF nLeft != NIL
      ::nLeftSpace := nLeft
   ENDIF

   RETURN NIL



METHOD AddPage() CLASS PDFClass

   IF !( ::nType == PDF_TXT_PORTRAIT .OR. ::nType == PDF_TXT_LANDSCAPE )
      ::oPage := HPDF_AddPage( ::oPdf )
      HPDF_Page_SetSize( ::oPage, HPDF_PAGE_SIZE_A4, iif( ::nType == PDF_PORTRAIT, HPDF_PAGE_PORTRAIT, HPDF_PAGE_LANDSCAPE ) )
      HPDF_Page_SetFontAndSize( ::oPage, HPDF_GetFont( ::oPdf, ::cFontName, ::cCodePage ), ::nFontSize )
   ENDIF
   ::nRow := 0

   RETURN NIL


METHOD Cancel() CLASS PDFClass

   IF !( ::nType == PDF_TXT_PORTRAIT .OR. ::nType == PDF_TXT_LANDSCAPE )
      HPDF_Free( ::oPdf )
   ENDIF

   RETURN NIL


METHOD DrawText( nRow, nCol, xValue, cPicture, nFontSize, cFontName, nAngle, aNRGB ) CLASS PDFClass

   LOCAL nRadian, cTexto

   nFontSize := iif( nFontSize == NIL, ::nFontSize, nFontSize )
   cFontName := iif( cFontName == NIL, ::cFontName, cFontName )
   cPicture  := iif( cPicture == NIL, "", cPicture )
   nAngle    := iif( nAngle == NIL, ::nAngle, nAngle )

   // IF ::lUTF8 .AND. ValType( xValue ) == "C" .AND. !( ::nType == PDF_TXT_PORTRAIT .OR. ::nType == PDF_TXT_LANDSCAPE )
   // xValue := hb_UTF8ToStr( xValue )
   // ENDIF
   cTexto  := Transform( xValue, cPicture )
   ::nCol := nCol + Len( cTexto )

   IF ::nType == PDF_TXT_PORTRAIT .OR. ::nType == PDF_TXT_LANDSCAPE
      @ nRow, nCol SAY cTexto
   ELSE
      nRow := ::RowToPDFRow( nRow )
      nCol := ::ColToPDFCol( nCol )
      HPDF_Page_SetFontAndSize( ::oPage, HPDF_GetFont( ::oPdf, cFontName, ::cCodePage ), nFontSize )
      IF aNRGB != NIL
         HPDF_Page_SetRGBFill( ::oPage, aNRGB[ 1 ], aNRGB[ 2 ], aNRGB[ 3 ] )
         HPDF_Page_SetRGBStroke( ::oPage, aNRGB[ 1 ], aNRGB[ 2 ], aNRGB[ 3 ] )
      ENDIF
      HPDF_Page_BeginText( ::oPage )
      nRadian := ( nAngle / 180 ) * 3.141592
      HPDF_Page_SetTextMatrix( ::oPage, Cos( nRadian ), Sin( nRadian ), - Sin( nRadian ), Cos( nRadian ), nCol, nRow )
      HPDF_Page_ShowText( ::oPage, cTexto )
      HPDF_Page_EndText( ::oPage )
      IF aNRGB != NIL
         HPDF_Page_SetRGBFill( ::oPage, 0, 0, 0 )
         HPDF_Page_SetRGBStroke( ::oPage, 0, 0, 0 )
      ENDIF
   ENDIF

   RETURN NIL

METHOD DrawLine( nRowi, nColi, nRowf, nColf, nPenSize ) CLASS PDFClass

   IF ::nType == PDF_TXT_PORTRAIT .OR. ::nType == PDF_TXT_LANDSCAPE
      nRowi := Round( nRowi, 0 )
      nColi := Round( nColi, 0 )
      @ nRowi, nColi SAY Replicate( "-", nColf - nColi )
      ::nCol := Col()
   ELSE
      nPenSize := iif( nPenSize == NIL, 0.2, nPenSize )
      nRowi := ::RowToPDFRow( nRowi )
      nColi := ::ColToPDFCol( nColi )
      nRowf := ::RowToPDFRow( nRowf )
      nColf := ::ColToPDFCol( nColf )
      HPDF_Page_SetLineWidth( ::oPage, nPenSize )
      HPDF_Page_MoveTo( ::oPage, nColi, nRowi )
      HPDF_Page_LineTo( ::oPage, nColf, nRowf )
      HPDF_Page_Stroke( ::oPage )
   ENDIF

   RETURN NIL

METHOD DrawImage( cJPEGFile, nRow, nCol, nWidth, nHeight ) CLASS PDFClass

   LOCAL oImage

   IF ::nType == PDF_TXT_PORTRAIT .OR. ::nType == PDF_TXT_LANDSCAPE
      RETURN NIL
   ENDIF
   nRow    := ::RowToPDFRow( nRow )
   nCol    := ::ColToPDFCol( nCol )
   nWidth  := Int( nWidth * ::nFontSize / 2 )
   nHeight := nHeight * ::nFontSize
   oImage := HPDF_LoadJpegImageFromFile( ::oPdf, cJPEGFile )
   HPDF_Page_DrawImage( ::oPage, oImage, nCol, nRow, nWidth, nHeight )

   RETURN NIL


METHOD DrawRectangle( nTop, nLeft, nWidth, nHeight, nPenSize, nFillType, aNRGB ) CLASS PDFClass

   IF ::nType == PDF_TXT_PORTRAIT .OR. ::nType == PDF_TXT_LANDSCAPE
      RETURN NIL
   ENDIF
   nFillType := iif( nFillType == NIL, 1, nFillType )
   nPenSize  := iif( nPenSize == NIL, 0.2, nPenSize )
   nTop      := ::RowToPDFRow( nTop )
   nLeft     := ::ColToPDFCol( nLeft )
   nWidth    := ( nWidth ) * ::nFontSize / 1.666
   nHeight   := -( nHeight ) * :: nFontSize
   HPDF_Page_SetLineWidth( ::oPage, nPenSize )
   IF aNRGB != NIL
      HPDF_Page_SetRGBFill( ::oPage, aNRGB[ 1 ], aNRGB[ 2 ], aNRGB[ 3 ] )
      HPDF_Page_SetRGBStroke( ::oPage, aNRGB[ 1 ], aNRGB[ 2 ], aNRGB[ 3 ] )
   ENDIF
   HPDF_Page_Rectangle( ::oPage, nLeft, nTop, nWidth, nHeight )
   IF nFillType == 1
      HPDF_Page_Stroke( ::oPage )     // borders only
   ELSEIF nFillType == 2
      HPDF_Page_Fill( ::oPage )       // inside only
   ELSE
      HPDF_Page_FillStroke( ::oPage ) // all
   ENDIF
   IF aNRGB != NIL
      HPDF_Page_SetRGBStroke( ::oPage, 0, 0, 0 )
      HPDF_Page_SetRGBFill( ::oPage, 0, 0, 0 )
   ENDIF

   RETURN NIL

METHOD RowToPDFRow( nRow ) CLASS PDFClass
   RETURN HPDF_Page_GetHeight( ::oPage ) - ::nMargin - ( nRow * ::nFontSize * ::nLineHeight )

METHOD ColToPDFCol( nCol ) CLASS PDFClass
   RETURN nCol * ::nFontSize / 1.666 + ::nMargin

METHOD MaxRow() CLASS PDFClass

   LOCAL nPageHeight, nMaxRow

   IF ::nType == PDF_TXT_PORTRAIT
      IF ::nFontSize == 9.5
        RETURN Round( 56 * ::nXScale, 0 )
      ENDIF
      IF ::nFontSize == 8.5
         RETURN Round( 62 * ::nXScale, 0 )
      ENDIF
      IF ::nFontSize == 9.5
        RETURN Round( 56 * ::nXScale, 0 )
      ENDIF
    
      SWITCH Round( ::nFontSize, 0 )
      CASE 10
         RETURN Round( 53 * ::nXScale, 0 )
      CASE 9
         RETURN Round( 58 * ::nXScale, 0 )
      CASE 8
         RETURN Round( 64 * ::nXScale, 0 )
      CASE 7
         RETURN Round( 75 * ::nXScale, 0 )
      CASE 6
         RETURN Round( 82 * ::nXScale, 0 )
      CASE 5
         RETURN Round( 85 * ::nXScale, 0 )
      OTHERWISE
         RETURN Round( 66 * ::nXScale, 0 )
      ENDSWITCH
   ENDIF

   IF ::nType == PDF_TXT_LANDSCAPE
      IF ::nFontSize == 5.5
         RETURN Round( 65 * ::nXScale, 0 )
      ENDIF
      IF ::nFontSize == 6.5
         RETURN Round( 62 * ::nXScale, 0 )
      ENDIF
      IF ::nFontSize == 9.5
        RETURN Round( 40 * ::nXScale, 0 )
      ENDIF

      SWITCH Round( ::nFontSize, 0 )
      CASE 10
         RETURN Round( 37 * ::nXScale, 0 )
      CASE 9
         RETURN Round( 41 * ::nXScale, 0 )
      CASE 8
         RETURN Round( 45 * ::nXScale, 0 )
      CASE 7
         RETURN Round( 50 * ::nXScale, 0 )
      CASE 6
         RETURN Round( 60 * ::nXScale, 0 )
      CASE 5
         RETURN Round( 70 * ::nXScale, 0 )
      OTHERWISE
         RETURN Round( 40 * ::nXScale, 0 )
      ENDSWITCH
   ENDIF

   nPageHeight := HPDF_Page_GetHeight( ::oPage ) - ( ::nMargin * 2 )
   nMaxRow     := Int( nPageHeight / ( ::nFontSize * ::nLineHeight )  )

   RETURN nMaxRow


METHOD MaxCol() CLASS PDFClass

   LOCAL nPageWidth, nMaxCol

   IF ::nType == PDF_TXT_PORTRAIT
      SWITCH Round( ::nFontSize, 0 )
      CASE 10
         RETURN Round( 92 * ::nYScale, 0 )
      CASE 9
         RETURN Round( 102 * ::nYScale, 0 )
      CASE 8
         RETURN Round( 115 * ::nYScale, 0 )
      CASE 7
         RETURN Round( 132 * ::nYScale, 0 )
      CASE 6
         RETURN Round( 145 * ::nYScale, 0 )
      CASE 5
         RETURN Round( 152 * ::nYScale, 0 )
      OTHERWISE
         RETURN Round( 102 * ::nYScale, 0 )
      ENDSWITCH

   ENDIF


   IF ::nType == PDF_TXT_LANDSCAPE

      IF ::nFontSize == 5.5
         RETURN Round( 240 * ::nYScale, 0 )
      ENDIF

      IF ::nFontSize == 7.5
         RETURN Round( 175 * ::nYScale, 0 )
      ENDIF

      SWITCH Round( ::nFontSize, 0 )
      CASE 10
         RETURN Round( 135 * ::nYScale, 0 )
      CASE 9
         RETURN Round( 150 * ::nYScale, 0 )
      CASE 8
         RETURN Round( 170 * ::nYScale, 0 )
      CASE 7
         RETURN Round( 180 * ::nYScale, 0 )
      CASE 6
         RETURN Round( 190 * ::nYScale, 0 )
      CASE 5
         RETURN Round( 225 * ::nYScale, 0 )
      OTHERWISE
         RETURN Round( 155 * ::nYScale, 0 )
      ENDSWITCH
   ENDIF

   nPageWidth := HPDF_Page_GetWidth( ::oPage ) - ( ::nMargin * 2 )
   nMaxCol    := Int( nPageWidth / ::nFontSize * 1.666 )

   RETURN nMaxCol



METHOD PrnToPdf( cInputFile ) CLASS PDFClass

   LOCAL cTxtReport, cTxtPage, cTxtLine, nRow
   LOCAL nLineLength
   LOCAL cPicture
   LOCAL nFontSize
   LOCAL cFontName
   LOCAL nAngle
   LOCAL aNRGB := { 0.0, 0.5, 0.5 }
   LOCAL aTmp

   cTxtReport := MemoRead( cInputFile ) + Chr( 12 )
   // Chr(12) - kraj stranice
   TokenInit( @cTxtReport, Chr( 12 ) )
   DO WHILE ! TokenEnd()
      cTxtPage := TokenNext( cTxtReport ) + hb_eol()
      IF Len( cTxtPage ) > 5
         // EOL Windows \r\n = chr(13) + chr(10)
         IF SubStr( cTxtPage, 1, 1 ) == Chr( 13 )
            cTxtPage := SubStr( cTxtPage, 2 )
         ENDIF
         ::AddPage()
         nRow := 0
         DO WHILE At( hb_eol(), cTxtPage ) != 0
            cTxtLine := SubStr( cTxtPage, 1, At( hb_eol(), cTxtPage ) - Len(hb_eol()) )
            cTxtPage := SubStr( cTxtPage, At( hb_eol(), cTxtPage ) + Len(hb_eol()) )
            nLineLength := Len( cTxtLine )
            // ::DrawText( nRow, 0, Replicate( " ", ::nLeftSpace + nLineLength ), cPicture, nFontSize, cFontName, nAngle, aNRGB  )
            // IF nRow % 2 == 0
            // aTmp := NIL
            // ELSE
            // aTmp := aNRGB
            // ::DrawRectangle( nRow, 0,  HPDF_Page_GetWidth( ::oPage ), ::nFontSize, 0, NIL, aNRGB)
            // ENDIF
            ::DrawText( nRow++, 0, Space( ::nLeftSpace ) + cTxtLine, cPicture, nFontSize, cFontName, nAngle, NIL )
         ENDDO
      ENDIF
   ENDDO

   RETURN NIL



METHOD PageHeader() CLASS PDFClass

   ::nPdfPage    += 1
   ::nPageNumber += 1
   ::nRow        := 0
   //info_bar( "debug", Str( ::MaxCol() ) )
   ::AddPage()
   ::DrawText( 0, 0, "(c) bring.out" )
   ::DrawText( 0, ( ::MaxCol() - Len( ::cHeader ) ) / 2, ::cHeader )
   ::DrawText( 0, ::MaxCol() - 16, "Str: " + StrZero( ::nPageNumber, 6 ) )
   ::DrawLine( 0.5, 1.5, 0.5, ::MaxCol() - 2 )
   ::nRow := 2
   ::nCol := 0

   RETURN NIL


METHOD View() CLASS PDFClass

   PDF_open_dokument( ::cFileName )

   RETURN .T.

METHOD MaxRowTest( nRows ) CLASS PDFClass

   nRows := iif( nRows == NIL, 0, nRows )
   IF ::nRow > ::MaxRow() - 2 - nRows
      ::PageHeader()
   ENDIF

   RETURN NIL

FUNCTION TxtSaida()
   RETURN { "PDF Landscape", "PDF Portrait", "Matrix" }

FUNCTION MyTempFile( cExt )
   RETURN "temp." + cExt
