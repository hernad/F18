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

STATIC s_cXlsxName 
STATIC s_pWorkBook, s_pWorkSheet, s_nWorkSheetRow
STATIC s_pMoneyFormat, s_pDateFormat
STATIC s_aKolone
STATIC s_aHeader 



FUNCTION xlsx_export_init( aFieldList, aHeader, cXlsxName )

   LOCAL nI, nFieldWidth, cFieldCaption
   
   IF cXlsxName <> NIL
      s_cXlsxName := cXlsxName
   ELSE
      s_cXlsxName := "f18_export.xlsx" 
   ENDIF
   
   s_aKolone := {}
   FOR nI := 1 TO LEN(aFieldList)
      // { "tip", "C", 1, 0 } )  => { "C", "tip", 4 }
      nFieldWidth := ROUND( aFieldList[ nI, 3 ] * 1.2, 0)
      IF LEN( aFieldList[ nI ] ) >= 6
         nFieldWidth := aFieldList[ nI, 6 ]
      ENDIF

      // { "IDROBA", "C", 10, 0, "Roba.ID", 10 }
      IF LEN( aFieldList[ nI ] ) >= 5
         // "Roba.ID"
         cFieldCaption := aFieldList[ nI, 5 ]
      ELSE
         // "IDROBA"
         cFieldCaption := aFieldList[ nI, 1 ]
      ENDIF
      AADD( s_aKolone, { aFieldList[ nI, 2], aFieldList[ nI, 1], nFieldWidth, cFieldCaption }   )
   NEXT 
  
   // aHeader := { 
   //    { "Konto:", "2110 - Kupci" },
   //    { "Partner:", "BR01 - bring.out doo Sarajevo"}
   //   }
   IF aHeader == NIL
      s_aHeader := {}
   ELSE
      s_aHeader := aHeader
   ENDIF

   RETURN .T.




FUNCTION xlsx_export_do_fill_row( hRow )
   
    LOCAL nI, cKey

   
    IF s_pWorkSheet == NIL
       
       s_pWorkBook := workbook_new( s_cXlsxName )
       s_pWorkSheet := workbook_add_worksheet(s_pWorkBook, NIL)
   
       s_pMoneyFormat := workbook_add_format(s_pWorkBook)
       format_set_num_format(s_pMoneyFormat, /*"#,##0"*/ "#0.00" )
   
       s_pDateFormat := workbook_add_format(s_pWorkBook)
       format_set_num_format(s_pDateFormat, "d.mm.yy")
     
       
       /* Set the column width. */
        FOR nI := 1 TO LEN( s_aKolone )
          // worksheet_set_column(lxw_worksheet *self, lxw_col_t firstcol, lxw_col_t lastcol, double width, lxw_format *format)
          worksheet_set_column(s_pWorkSheet, nI - 1, nI - 1, s_aKolone[ nI, 3], NIL)
        NEXT
   
   
        FOR nI := 1 TO LEN( s_aHeader )
          worksheet_write_string( s_pWorkSheet, nI - 1, 0,  hb_StrToUTF8( s_aHeader[nI, 1]), NIL)
          worksheet_write_string( s_pWorkSheet, nI - 1, 1,  hb_StrToUtf8( s_aHeader[nI, 2]), NIL)
        NEXT
       
        s_nWorkSheetRow := LEN( s_aHeader)
        IF LEN( s_aHeader) > 0
           s_nWorkSheetRow ++
        ENDIF

        /* Set header kolona */
        for nI := 1 TO LEN( s_aKolone )
          worksheet_write_string( s_pWorkSheet, s_nWorkSheetRow, nI - 1,  s_aKolone[nI, 4], NIL)
        next

   ENDIF
   
    s_nWorkSheetRow++
   
    altd()
    FOR EACH cKey in hRow:Keys
           xValue := hRow[ cKey ]
           // 
           nI := AScan( s_aKolone, { | element | Lower( element[2]) == cKey  })
           IF nI == 0
              Alert( "hRow key? " + cKey + " nema u kolonama")
           ENDIF
           IF s_aKolone[ nI, 1 ] == "C"
              worksheet_write_string( s_pWorkSheet, s_nWorkSheetRow, nI - 1,  hb_StrToUtf8(xValue), NIL)
           ELSEIF s_aKolone[ nI, 1 ] == "M"
              worksheet_write_number( s_pWorkSheet, s_nWorkSheetRow, nI - 1, xValue, s_pMoneyFormat)
           ELSEIF s_aKolone[ nI, 1 ] == "N"
             worksheet_write_number( s_pWorkSheet, s_nWorkSheetRow, nI - 1,  xValue, NIL)
          ELSEIF s_aKolone[ nI, 1 ] == "D"
             worksheet_write_datetime( s_pWorkSheet, s_nWorkSheetRow, nI - 1, xValue, s_pDateFormat)
          ENDIF
    NEXT
         
    RETURN .T.


FUNCTION open_exported_xlsx()

   my_close_all_dbf()
   workbook_close( s_pWorkBook )
   s_pWorkBook := NIL
   s_pWorkSheet := NIL
   f18_open_mime_document( s_cXlsxName )

   RETURN .T.



FUNCTION o_r_export()

   SELECT ( F_R_EXP )
   my_usex ( "r_export" )

   RETURN .T.


FUNCTION select_o_r_export()

   SELECT ( F_R_EXP )
   IF !Used()
      my_usex ( "r_export" )
   ENDIF

   RETURN .T.
