#include "f18.ch"

STATIC aHeader := {}
STATIC aZaglLen := {}
STATIC aZagl := {}
STATIC lSvakaHeader := .T.

// tekuca linija reporta
STATIC nCurrLine := 0

STATIC cRptNaziv := "Izvještaj KUF na dan "

STATIC s_cTabela := "kuf"

STATIC cTar := ""
STATIC cPart := ""

STATIC cRptBrDok := 0



FUNCTION epdv_rpt_kuf( nBrDok, cIdTarifa )

   LOCAL cHeader
   LOCAL cPom
   LOCAL cPom11
   LOCAL cPom12
   LOCAL cPom21
   LOCAL cPom22
   LOCAL nLenIzn
   LOCAL cExportDN := "N"
   LOCAL cExportDbf
   LOCAL GetList := {}
   LOCAL nX

   // 1 - red.br / ili br.dok
   // 2 - br.dok / ili r.br
   // 3 - dat dok
   // 4 - tarifna kategorija
   // 5 - dobavljac (naziv + id)
   // 6 - brdok dobavljaca
   // 7 - opis
   // 8 - izn bez pdv
   // 9 - izn  pdv
   // 10 - izn sa pdv

   nLenIzn := Len( PIC_IZN() )
   aZaglLen := { 8, 8, 8, 8, 82, 12, 70,  nLenIzn, nLenIzn, nLenIzn, nLenIzn }


   IF nBrDok == nil
      nBrDok := -999
   ENDIF
   nRptBrDok := nBrDok


   IF cIdTarifa == nil
      cTar := ""
   ELSE
      cTar := cIdTarifa
   ENDIF

   cPart := ""

   aDInt := epdv_rpt_d_interval ( Date() )

   dDate := Date()

   dDatOd := aDInt[ 1 ]
   dDatDo := aDInt[ 2 ]


   IF ( nBrDok == -999 )

      cTar := PadR( cTar, 6 )
      cPart := PadR( cPart, 6 )

      nX := 1

      Box(, 11, 60 )

      @ box_x_koord() + nX, box_y_koord() + 2 SAY "Period"

      nX++
      @ box_x_koord() + nX, box_y_koord() + 2 SAY "od " GET dDatOd
      @ box_x_koord() + nX, Col() + 2 SAY "do " GET dDatDo

      nX += 2
      @ box_x_koord() + nX, box_y_koord() + 2 SAY "Tarifa (prazno svi) ?  " GET cTar ;
         VALID {|| Empty( cTar ) .OR. P_Tarifa( @cTar ) } PICT "@!"

      nX += 1
      @ box_x_koord() + nX, box_y_koord() + 2 SAY "Partner (prazno svi) ? " GET cPart ;
         VALID {|| Empty( cPart ) .OR. p_partner( @cPart ) } PICT "@!"

      nX += 2
      @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Eksport izvještaja u DBF (D/N) ?" GET cExportDN  VALID cExportDN $ "DN" PICT "@!"

      nX += 2
      @ box_x_koord() + nX, box_y_koord() + 2 SAY Replicate( "-", 30 )

      nX++

      READ

      BoxC()

      IF LastKey() == K_ESC
         my_close_all_dbf()
         RETURN .F.
      ENDIF

   ENDIF

   aHeader := {}

   IF ( nBrDok == -999 )
      cHeader :=  cRptNaziv +  DToC( dDate ) + ", za period :" + DToC( dDatOd ) + "-" + DToC( dDatDo )

   ELSE
      IF nBrDok == 0
         cPom := "PRIPREMA"
      ELSE
         cPom := Str( nBrDok, 6, 0 )
      ENDIF
      cHeader :=  "Dokument KUF: " + cPom + ", na dan " + DToC( Date() )
   ENDIF

   AAdd( aHeader, "Preduzeće: " + my_firma() )
   AAdd( aHeader, cHeader )

   IF !Empty( cTar )
      cPom := "Prikaz kategorije : " + s_tarifa( cTar )
      AAdd( aHeader, cPom )
   ENDIF


   aZagl := {}

   cPom1 := ""
   cPom2 := ""

   IF ( nBrDok == -999 )
      cPom11 := "Red."
      cPom12 := "br."

      cPom21 := "Broj"
      cPom22 := "dok"
   ELSE
      cPom11 := "Broj"
      cPom12 := "dok"
      cPom21 := "Red"
      cPom22 := "br."

   ENDIF

   AAdd( aZagl, { cPom11,  cPom21, "Datum", "Tar.",  "Dobavljač", "Broj",  "Opis",  "iznos", "izn.",    "izn. 2", "iznos" } )
   AAdd( aZagl, { cPom12,  cPom22,  "",     "kat.",      "(naziv, PDV / identifikacijski broj)",      "RN",     "",    "bez PDV", "PDV", "PDV NP", "sa PDV" } )
   AAdd( aZagl, { "(1)",   "(2)",  "(3)",   "(4)",   "(5)",  "(6)",     "(7)", "(8)", "(9)",  "(10)",  "11=8+9+10" } )

   epdv_fill_rpt( nBrDok )

   my_close_all_dbf()

   IF cExportDN == "D"

      cExportDbf := my_home() + "epdv_r_kuf.dbf"
      open_exported_xlsx( cExportDbf )

   ELSE
      show_rpt(  .F.,  .F. )
   ENDIF

   RETURN .T.


STATIC FUNCTION get_r_fields( aArr )

   AAdd( aArr, { "r_br",   "N",  8, 0 } )
   AAdd( aArr, { "br_dok",   "N",  6, 0 } )
   AAdd( aArr, { "datum",   "D",  8, 0 } )

   AAdd( aArr, { "id_tar",   "C",  6, 0 } )
   AAdd( aArr, { "id_part",   "C",  6, 0 } )

   AAdd( aArr, { "dob_rn",   "C",  12, 0 } )
   AAdd( aArr, { "dob_naz",   "C",  200, 0 } )
   AAdd( aArr, { "opis",   "C",  80, 0 } )

   AAdd( aArr, { "i_b_pdv",   "N",  18, 2 } )
   AAdd( aArr, { "i_pdv",   "N",  18, 2 } )
   AAdd( aArr, { "i_pdv2",   "N",  18, 2 } )
   AAdd( aArr, { "i_uk",   "N",  18, 2 } )

   RETURN .T.


STATIC FUNCTION epdv_create_r_kuf()

   LOCAL aArr := {}

   my_close_all_dbf()

   FErase ( my_home() + "epdv_r_" +  s_cTabela + ".cdx" )
   FErase ( my_home() + "epdv_r_" +  s_cTabela + ".dbf" )

   get_r_fields( @aArr )

   dbcreate2( my_home() + "epdv_r_" + s_cTabela + ".dbf", aArr )
   CREATE_INDEX( "br_dok", "br_dok", "epdv_r_" +  s_cTabela, .T. )

   RETURN .T.



STATIC FUNCTION epdv_fill_rpt( nBrDok )

   LOCAL nIzArea
   LOCAL nBPdv
   LOCAL nPdv
   LOCAL nRbr
   LOCAL dDatum
   LOCAL cDobRn
   LOCAL cDobNaz
   LOCAL cIdTar
   LOCAL cOpis
   LOCAL cIdPart
   LOCAL nCount

   epdv_create_r_kuf()

   select_o_epdv_r_kuf()

   IF ( nBrDok == 0 )
      nIzArea := F_P_KUF
      select_o_epdv_p_kuf()
      SET ORDER TO TAG "br_dok"

   ELSE
      nIzArea := F_KUF
      // select_o_epdv_kuf()
      // SET ORDER TO TAG "g_r_br"
      find_epdv_kuf_za_period( dDatOd, dDatDo )

   ENDIF

   SELECT ( nIzArea )

   PRIVATE cFilter := ""

   IF ( nBrdok == -999 )
      cFilter := dbf_quote( dDatOd ) + " <= datum .and. " + dbf_quote( dDatDo ) + ">= datum"
   ENDIF

   IF !Empty( cTar )
      IF !Empty( cFilter )
         cFilter += " .and. "
      ENDIF
      cFilter += "id_tar == " + dbf_quote( cTar )
   ENDIF

   IF !Empty( cPart )
      IF !Empty( cFilter )
         cFilter += " .and. "
      ENDIF
      cFilter += "id_part == " + dbf_quote( cPart )
   ENDIF

   SET FILTER TO &cFilter
   GO TOP

   Box(, 3, 60 )

   nCount := 0


   DO WHILE !Eof() // kuf ili p_kuf

      ++nCount

      @ box_x_koord() + 2, box_y_koord() + 2 SAY Str( nCount, 6, 0 )

      nBrDok := field->br_dok
      nBPdv := field->i_b_pdv
      nPdv := field->i_pdv

      IF ( nRptBrDok == -999 )
         nRbr := field->g_r_br // za vise dokumenata
      ELSE
         nRbr := field->r_br // za jedan dokument
      ENDIF

      dDatum := field->datum
      cDobRn := field->src_br_2
      cDobNaz := s_partner( field->id_part )
      cIdTar := field->id_tar
      cIdPart := field->id_part
      cOpis := field->opis

      SELECT r_kuf
      APPEND BLANK

      REPLACE id_part WITH cIdPart
      REPLACE br_dok WITH nBrDok
      REPLACE r_br WITH nRbr
      REPLACE id_tar WITH cIdTar
      REPLACE datum WITH dDatum
      REPLACE dob_rn WITH cDobRn
      REPLACE dob_naz WITH cDobNaz
      REPLACE opis WITH cOpis

      REPLACE i_b_pdv WITH nBPdv
      REPLACE i_pdv WITH nPdv

      IF t_u_n_poup( field->id_tar )
         REPLACE i_pdv WITH 0
         REPLACE i_pdv2 WITH nPdv
      ELSE
         REPLACE i_pdv WITH nPdv
         REPLACE i_pdv2 WITH 0
      ENDIF

      REPLACE i_uk WITH ( field->i_b_pdv + field->i_pdv + field->i_pdv2 )

      SELECT ( nIzArea )
      SKIP

   ENDDO

   BoxC()

   SELECT ( nIzArea )
   SET FILTER TO

   RETURN .T.



STATIC FUNCTION show_rpt()

   LOCAL nLenUk
   LOCAL nPom1
   LOCAL nPom2
   LOCAL nPdv
   LOCAL nPdv2
   LOCAL aDobavljacNaziv
   LOCAL cPom

   nCurrLine := 0

   START PRINT CRET

   nPageLimit := 40
   ? "#%LANDS#"

   P_COND
   nRow := 0

   zaglavlje_kuf()

   select_o_epdv_r_kuf()
   SELECT r_kuf
   SET ORDER TO TAG "1"
   GO TOP
   nRbr := 0

   nUBPdv := 0
   nUPdv :=  0
   nUPdv2 :=  0

   DO WHILE !Eof()

      ++nCurrLine

      // 3 - dat dok
      // 4 - tarifna kategorija
      // 5 - dobavljac (naziv + id)
      // 6 - brdok dobavljaca
      // 7 - opis
      // 8 - izn bez pdv
      // 9 - izn  pdv
      // 10 - izn sa pdv

      aDobavljacNaziv := SjeciStr( dob_naz, aZaglLen[ 5 ] )

      IF nRptBrDok == -999
         nPom1 := r_br
         nPom2 := br_dok
      ELSE
         nPom1 := br_dok
         nPom2 := r_br
      ENDIF

      ?
      // 1. broj dokumenta
      ?? Transform( nPom1, Replicate( "9", aZaglLen[ 1 ] ) )
      ?? " "

      // 2. r.br
      ?? Transform( nPom2, Replicate( "9", aZaglLen[ 2 ] ) )
      ?? " "


      // 3. datum
      ?? PadR( field->datum, aZaglLen[ 3 ] )
      ?? " "

      // 4. tarifa
      ?? PadR( field->id_tar, aZaglLen[ 4 ] )
      ?? " "

      nPos := PCol()

      // 5. dobavljac naziv
      ?? PadR( aDobavljacNaziv[ 1 ], aZaglLen[ 5 ] )
      ?? " "

      // 6. dobavljac rn
      ?? PadR( field->dob_rn, aZaglLen[ 6 ] )
      ?? " "

      // 7. opis
      ?? PadR( field->opis, aZaglLen[ 7 ] )
      ?? " "

      // 8. bez pdv
      ?? Transform( field->i_b_pdv,  PIC_IZN() )
      ?? " "

      IF t_u_n_poup( field->id_tar )
         nPdv := 0
         nPdv2 := field->i_pdv2
      ELSE
         nPdv := field->i_pdv
         nPdv2 := 0
      ENDIF

      // 9. standardni pdv
      ?? Transform( nPdv,  PIC_IZN() )
      ?? " "

      // bez prava na odbitak
      // 10. pdv NP  - neposlovne svrhe
      ?? Transform( nPdv2,  PIC_IZN() )
      ?? " "

      // 10. sa pdv
      ?? Transform( field->i_b_pdv + ( field->i_pdv + field->i_pdv2 ),  PIC_IZN() )
      ?? " "

      IF Len( aDobavljacNaziv ) > 1

         nCurrLine := nCurrLine + 1

         kuf_nova_stranica( @nCurrLine, nPageLimit, lSvakaHeader )

         ?
         @ PRow(), nPos SAY aDobavljacNaziv[ 2 ]

      ENDIF

      nUBPdv += field->i_b_pdv
      nUPdv += nPdv
      nUPdv2 += nPdv2

      kuf_nova_stranica( @nCurrLine, nPageLimit, lSvakaHeader )

      SKIP

   ENDDO

   nCurrLine := nCurrLine + 3
   kuf_nova_stranica( @nCurrLine, nPageLimit, lSvakaHeader )

   kuf_linija()

   ?
   cPom := "   U K U P N O :  "

   nLenUk := 0
   FOR i := 1 TO 7
      nLenUk += aZaglLen[ i ] + 1
   NEXT
   nLenUk -= 1

   ?? PadR( cPom, nLenUk )
   ?? " "
   ?? Transform( nUBPdv, PIC_IZN() )
   ?? " "

   ?? Transform( nUPdv, PIC_IZN() )
   ?? " "

   ?? Transform( nUPdv2, PIC_IZN() )
   ?? " "

   ?? Transform( nUBPdv + nUPdv + nUPdv2, PIC_IZN() )

   kuf_linija()

   FF
   ENDPRINT

   RETURN .T.


STATIC FUNCTION kuf_nova_stranica( nCurrLine, nPageLimit, lSvakaHeader )

   IF nCurrLine > nPageLimit
      FF
      nCurrLine := 0
      IF lSvakaHeader
         zaglavlje_kuf()
      ENDIF
   ENDIF

   RETURN .T.



STATIC FUNCTION zaglavlje_kuf()

   P_COND
   B_ON
   FOR i := 1 TO Len( aHeader )
      ?U aHeader[ i ]
      ++nCurrLine
   NEXT
   B_OFF

   P_COND2

   kuf_linija()

   FOR i := 1 TO Len( aZagl )
      ++nCurrLine
      ?
      FOR nCol := 1 TO Len( aZaglLen )
         IF Left( aZagl[ i, nCol ], 1 ) = "#"

            nMergirano := Val( SubStr( aZagl[ i, nCol ], 2, 1 ) )
            cPom := SubStr( aZagl[ i, nCol ], 3, Len( aZagl[ i, nCol ] ) - 2 )
            nMrgWidth := 0
            FOR nMrg := 1 TO nMergirano
               nMrgWidth += aZaglLen[ nCol + nMrg - 1 ]
               nMrgWidth++
            NEXT
            ??U PadC( cPom, nMrgWidth )
            ?? " "
            nCol += ( nMergirano - 1 )
         ELSE
            ??U PadC( aZagl[ i, nCol ], aZaglLen[ nCol ] )
            ?? " "
         ENDIF
      NEXT
   NEXT

   kuf_linija()

   RETURN .T.


STATIC FUNCTION kuf_linija()

   LOCAL i

   ++nCurrLine
   ?
   FOR i = 1 TO Len( aZaglLen )
      ?? PadR( "-", aZaglLen[ i ], "-" )
      ?? " "
   NEXT

   RETURN .T.
