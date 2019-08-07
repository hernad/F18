/*
 * This file is part of the bring.out FMK, a free and open source
 * accounting software suite,
 * Copyright (c) 1996-2011 by bring.out doo Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including FMK specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_FMK.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */


#include "f18.ch"

// ----------------------------------------------
// kopiranje fajlova
// ----------------------------------------------
FUNCTION _txt_copy( cFile, cDest )

   LOCAL cScreen
   LOCAL cKLin

   SAVE SCREEN TO cScreen

   cKLin := "copy " + my_home() + cFile + " " + cDest
   f18_run( cKLin )

   RESTORE SCREEN FROM cScreen

   RETURN .T.


FUNCTION fiskalni_get_struct_za_gen_fajlova( cFileName )

   LOCAL aRet := {}

   DO CASE

   CASE cFileName == "RACUN_TXT"

      // fiskalni racun broj (1-5)
      AAdd( aRet, { "N", 5, 0 } )
      // tip racuna (6)
      AAdd( aRet, { "N", 1, 0 } )
      // storno stavka identifikator (7)
      AAdd( aRet, { "N", 1, 0 } )
      // fiskalna sifra robe (8-12)
      AAdd( aRet, { "N", 5, 0 } )
      // naziv robe (13-44)
      AAdd( aRet, { "C", 32, 0 } )
      // barkod (45-58)
      AAdd( aRet, { "C", 14, 0 } )
      // sifra grupe robe (59-60)
      AAdd( aRet, { "N", 2, 0 } )
      // sifra poreske stope (61)
      AAdd( aRet, { "N", 1, 0 } )
      // cijena robe (62-74)
      AAdd( aRet, { "N", 12, 2 } )
      // kolicina robe (75-87)
      AAdd( aRet, { "N", 12, 2 } )

   CASE cFileName == "RACUN_PLA"

      // fiskalni racun broj (1-5)
      AAdd( aRet, { "N", 5, 0 } )
      // tip racuna (6)
      AAdd( aRet, { "N", 1, 0 } )
      // nacin placanja (7)
      AAdd( aRet, { "N", 1, 0 } )
      // uplaceno (8-12)
      AAdd( aRet, { "N", 12, 2 } )
      // total racuna (13-20)
      AAdd( aRet, { "N", 12, 2 } )
      // povrat novca (21-33)
      AAdd( aRet, { "N", 12, 2 } )

   CASE cFileName == "RACUN_MEM"

      // slobodan red teksta
      AAdd( aRet, { "C", 32, 0 } )

   CASE cFileName == "SEMAFOR"

      // redni broj racuna-nivelacije-operacije (1-5)
      AAdd( aRet, { "N", 5, 0 } )
      // tip knjizenja - komanda operacije (6-10)
      AAdd( aRet, { "N", 5, 0 } )
      // print memo identifikator od broja (11-15)
      AAdd( aRet, { "N", 5, 0 } )
      // print memo identifikator do broja (16-20)
      AAdd( aRet, { "N", 5, 0 } )
      // fiskalna sifra kupca za veleprodaju ili 0 (21-25)
      AAdd( aRet, { "N", 5, 0 } )
      // broj reklamnog racuna (26-31)
      AAdd( aRet, { "N", 5, 0 } )

   CASE cFileName == "NIVELACIJA"

      // redni broj nivelacije (1-5)
      AAdd( aRet, { "N", 5, 0 } )
      // fiskalna sifra robe (6-10)
      AAdd( aRet, { "N", 5, 0 } )
      // naziv robe (11-42)
      AAdd( aRet, { "C", 32, 0 } )
      // barkod (43-56)
      AAdd( aRet, { "C", 14, 0 } )
      // sifra grupe (57-58)
      AAdd( aRet, { "N", 2, 0 } )
      // sifra poreske stope (59)
      AAdd( aRet, { "N", 1, 0 } )
      // cijena robe (60-72)
      AAdd( aRet, { "N", 12, 2 } )

   CASE cFileName == "POREZI"

      // sifra stope (1)
      AAdd( aRet, { "N", 1, 0 } )
      // naziv poreske stope u pravilniku (2-17)
      AAdd( aRet, { "C", 16, 0 } )
      // poreska stopa procenat (18-22)
      AAdd( aRet, { "N", 5, 2 } )

   CASE cFileName == "ROBA"

      // sifra robe (1-5)
      AAdd( aRet, { "N", 5, 0 } )
      // naziv robe (6-37)
      AAdd( aRet, { "C", 32, 0 } )
      // barkod (38-51)
      AAdd( aRet, { "C", 14, 0 } )
      // sifra grupe (52-53)
      AAdd( aRet, { "N", 2, 0 } )
      // sifra poreske stope (54)
      AAdd( aRet, { "N", 1, 0 } )
      // cijena robe (55-67)
      AAdd( aRet, { "N", 12, 2 } )

   CASE cFileName == "ROBAGRUPE"

      // sifra  (1-2)
      AAdd( aRet, { "N", 2, 0 } )
      // naziv  (3-19)
      AAdd( aRet, { "C", 17, 0 } )

   CASE cFileName == "PARTNERI"

      // sifra  (1-5)
      AAdd( aRet, { "N", 5, 0 } )
      // naziv  (6-36)
      AAdd( aRet, { "C", 31, 0 } )
      // adresa A (37-67)
      AAdd( aRet, { "C", 31, 0 } )
      // adresa B (68-98)
      AAdd( aRet, { "C", 31, 0 } )
      // adresa C (99-129)
      AAdd( aRet, { "C", 31, 0 } )
      // IBO (130-150)
      AAdd( aRet, { "C", 21, 2 } )

   CASE cFileName == "OPERATERI"

      // sifra operatera (1-2)
      AAdd( aRet, { "N", 2, 0 } )
      // naziv operatera (3-18)
      AAdd( aRet, { "C", 16, 0 } )
      // lozinka (19-38)
      AAdd( aRet, { "C", 20, 0 } )

   CASE cFileName == "OBJEKTI"

      // sifra  (1-5)
      AAdd( aRet, { "N", 5, 0 } )
      // naziv  (6-36)
      AAdd( aRet, { "C", 31, 0 } )
      // telefonski broj (37-67)
      AAdd( aRet, { "C", 31, 0 } )
      // naziv firme (68-98)
      AAdd( aRet, { "C", 31, 0 } )
      // adresa firme (99-129)
      AAdd( aRet, { "C", 31, 0 } )
      // poreski broj (130-160)
      AAdd( aRet, { "C", 31, 0 } )

   CASE cFileName == "POS_RN"

      // pos racun - stavke
      AAdd( aRet, { "C", 100, 0 } )

   ENDCASE

   RETURN aRet



FUNCTION fiskalni_array_to_fajl( cFilePath, cFileName, aStruct, aData, cSeparator, lTrim, lLastSep )

   LOCAL i
   LOCAL ii
   LOCAL cLine := ""
   LOCAL nCount := 0
   LOCAL cNumFill := "0"
   LOCAL cPrintFile

   IF cSeparator == nil
      cSeparator := ""
   ENDIF

   IF lTrim == nil
      lTrim := .F.
   ENDIF

   IF lLastSep == nil
      lLastSep := .T.
   ENDIF

   cPrintFile := AllTrim( cFilePath ) + AllTrim( cFileName )

   SET PRINTER to ( cPrintFile )
   SET PRINTER ON
   SET CONSOLE OFF

   // prodji kroz podatke u aData
   FOR i := 1 TO Len( aData )

      cLine := ""

      // prodji kroz strukturu jednog zapisa u matrici
      // i napuni liniju...
      FOR ii := 1 TO Len( aStruct )

         cType := aStruct[ ii, 1 ]
         nLen := aStruct[ ii, 2 ]
         nDec := aStruct[ ii, 3 ]

         IF cType == "C"
            xVal := PadR( aData[ i, ii ], nLen )
         ELSEIF cType == "N"

            IF nDec > 0
               xVal := AllTrim( Str( aData[ i, ii ], nLen, nDec ) )
            ELSE
               xVal := AllTrim( Str( aData[ i, ii ] ) )
            ENDIF

            IF lTrim == .F.
               xVal := PadL( xVal, nLen, cNumFill )
            ENDIF

            IF lTrim == .T.
               // zamjeni "." sa ","
               xVal := StrTran( xVal, ".", "," )
            ENDIF

         ENDIF

         IF lTrim == .T.
            xVal := AllTrim( xVal )
         ENDIF

         IF ii = Len( aStruct ) .AND. lLastSep == .F.
            cLine += xVal
         ELSE
            cLine += xVal + cSeparator
         ENDIF

      NEXT

      ?? cLine
      ?

      ++ nCount

   NEXT

   SET PRINTER TO
   SET PRINTER OFF
   SET CONSOLE ON

   RETURN .T.


// ----------------------------------------------------------
// upisi u fajl iz DBF tabele
// ----------------------------------------------------------
FUNCTION _dbf_to_file( cFilePath, cFileName, aStruct, cDBF, ;
      cSeparator, lTrim, lLastSep )

   LOCAL i
   LOCAL ii
   LOCAL cLine := ""
   LOCAL nCount := 0
   LOCAL cNumFill := "0"

   IF cSeparator == nil
      cSeparator := ""
   ENDIF

   IF lTrim == nil
      lTrim := .F.
   ENDIF

   IF lLastSep == nil
      lLastSep := .T.
   ENDIF

   cPrintFile := AllTrim( cFilePath ) + AllTrim( cFileName )

   SET PRINTER to ( cPrintFile )
   SET PRINTER ON
   SET CONSOLE OFF

   // zakaci se na dbf
   SELECT ( F_TMP_1 )
   USE

   my_use_temp( "exp", my_home() + cDBF )
   GO TOP

   DO WHILE !Eof()

      cLine := ""

      // prodji kroz strukturu jednog zapisa u matrici
      // i napuni liniju...
      FOR ii := 1 TO Len( aStruct )

         cType := aStruct[ ii, 1 ]
         nLen := aStruct[ ii, 2 ]
         nDec := aStruct[ ii, 3 ]

         IF cType == "C"
            xVal := PadR( &( exp->( FieldName( ii ) ) ), nLen )
         ELSEIF cType == "N"

            IF nDec > 0
               xVal := AllTrim( Str( &( exp->( FieldName( ii ) ) ), nLen, nDec ) )
            ELSE
               xVal := AllTrim( Str( &( exp->( FieldName( ii ) ) ) ) )
            ENDIF

            IF lTrim == .F.
               xVal := PadL( xVal, nLen, cNumFill )
            ENDIF

            IF lTrim == .T.
               // zamjeni "." sa ","
               xVal := StrTran( xVal, ".", "," )
            ENDIF

         ENDIF

         IF lTrim == .T.
            xVal := AllTrim( xVal )
         ENDIF

         IF ii = Len( aStruct ) .AND. lLastSep == .F.
            cLine += xVal
         ELSE
            cLine += xVal + cSeparator
         ENDIF

      NEXT

      ?? to_win1250_encoding( hb_StrToUTF8( cLine ), .T. )
      ?

      ++ nCount

      SKIP

   ENDDO

   SET PRINTER TO
   SET PRINTER OFF
   SET CONSOLE ON

   SELECT ( F_TMP_1 )
   USE

   RETURN
