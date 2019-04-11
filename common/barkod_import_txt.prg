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


// -------------------------------------------------------
// Setuj matricu sa poljima tabele dokumenata TERM
// -------------------------------------------------------
STATIC FUNCTION get_term_tbl_struct( aDbf )

   AAdd( aDbf, { "barkod",  "C", 13, 0 } )
   AAdd( aDbf, { "idroba",  "C", 10, 0 } )
   AAdd( aDbf, { "kolicina", "N", 15, 5 } )
   AAdd( aDbf, { "status", "N", 2, 0 } )

   // status
   // 0 - nema robe u sifrarniku
   // 1 - roba je tu

   RETURN NIL


// --------------------------------------------------------
// Kreiranje temp tabele, te prenos zapisa iz text fajla
// "cTextFile" u tabelu
// - param cTxtFile - txt fajl za import
// --------------------------------------------------------
FUNCTION bterm_txt_to_tbl( cTxtFile )

   LOCAL cDelimiter := ";"
   LOCAL aDbf := {}
   LOCAL oFile
   LOCAL cTmp
   LOCAL cVar, aRow, nTmp

   cTxtFile := AllTrim( cTxtFile )

   // prvo kreiraj tabelu temp
   my_close_all_dbf()

   // polja tabele TEMP.DBF
   get_term_tbl_struct( @aDbf )
   cre_temp_tbl( aDbf, .T. )

   IF !File( my_home() + my_dbf_prefix() + "temp.dbf" )
      MsgBeep( "Ne mogu kreirati fajl TEMP.DBF!" )
      RETURN .F.
   ENDIF

   // otvori tabele
   //o_roba()

   SELECT ( F_TMP_1 )
   USE
   my_use_temp( "temp", my_home() + my_dbf_prefix() + "temp.dbf" )

   // zatim iscitaj fajl i ubaci podatke u tabelu

   oFile := TFileRead():New( cTxtFile )
   oFile:Open()

   IF oFile:Error()
      MsgBeep( oFile:ErrorMsg( "Problem sa otvaranjem fajla: " ) )
      RETURN .F.
   ENDIF

   // prodji kroz svaku liniju i insertuj zapise u temp.dbf

   DO WHILE oFile:MoreToRead()

      cVar := hb_StrToUTF8( oFile:ReadLine() )
      IF Empty( cVar )
         LOOP
      ENDIF

      aRow := csvrow2arr( cVar, cDelimiter )
      // struktura podataka u txt-u je
      // [1] - barkod
      // [2] - kolicina
      // pa uzimamo samo sta nam treba
      cTmp := PadR( AllTrim( aRow[ 1 ] ), 13 )
      nTmp := Val ( AllTrim( aRow[ 2 ] ) )

      //SELECT roba
      //SET ORDER TO TAG "BARKOD"
      //GO TOP
      //SEEK cTmp


      //IF Found()
      IF find_roba_by_barkod( cTmp )
         cRoba_id := field->id
         nStatus := 1
      ELSE
         cRoba_id := ""
         nStatus := 0
      ENDIF

      // selektuj temp tabelu
      SELECT temp
      // dodaj novi zapis
      APPEND BLANK

      REPLACE barkod WITH cTmp
      REPLACE idroba WITH cRoba_id
      REPLACE kolicina WITH nTmp
      REPLACE status WITH nStatus

   ENDDO

   oFile:Close()

   SELECT temp
   MsgBeep( "Import txt => temp - OK" )

   RETURN .T.


// ----------------------------------------------------------------
// Kreira tabelu TEMP.DBF prema definiciji polja iz aDbf
// ----------------------------------------------------------------
STATIC FUNCTION cre_temp_tbl( aDbf, lIndex )

   LOCAL _table := "temp"

   IF lIndex == NIL
      lIndex := .T.
   ENDIF

   FErase( my_home() + my_dbf_prefix() + "temp.dbf" )

   dbCreate( my_home() + my_dbf_prefix() + _table, aDbf )

   IF lIndex

      SELECT ( F_TMP_1 )
      USE

      my_use_temp( "temp", my_home() + my_dbf_prefix() + "temp.dbf" )

      INDEX ON barkod TAG "1"
      INDEX ON idroba TAG "2"
      INDEX ON Str( status ) TAG "3"

      SELECT ( F_TMP_1 )
      USE

   ENDIF

   RETURN .T.
