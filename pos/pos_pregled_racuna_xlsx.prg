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

MEMVAR gIdRadnik

STATIC s_cXlsxName := NIL
STATIC s_pWorkBook, s_pWorkSheet, s_nWorkSheetRow
STATIC s_pMoneyFormat, s_pDateFormat
STATIC s_nPredhodniBroj

FUNCTION pos_pregled_racuna_xlsx()

   LOCAL cSql, oQuery, oRow
   LOCAL dDatOd := date()
   LOCAL dDatDo := date()
   LOCAL GetList := {}
   

   Box(, 2, 60 )
    @ box_x_koord() + 1, box_y_koord() + 2 SAY8 "Datum od: " GET dDatOd
    @ box_x_koord() + 1, col() + 2 SAY8 "do: " GET dDatDo 


   READ
   BoxC()

   IF LastKey() == K_ESC
      RETURN .F.
   ENDIF

   cSql := "select  pos_items.idvd, " + pos_prodavnica_sql_schema() + ".pos_items.datum, pos.vrijeme, pos_items.brdok, pos_fisk_doks.broj_rn,"
   cSql += "sum(round((case when pos_items.ncijena=0 then pos_items.cijena else pos_items.ncijena end) * pos_items.kolicina, 2)) as iznos," 
   cSql += "count(pos_items.*) as brstavki"
   cSql += " FROM " +  pos_prodavnica_sql_schema() + ".pos_items" 
   cSql += " LEFT JOIN " + pos_prodavnica_sql_schema() + ".pos on " + pos_prodavnica_sql_schema() + ".pos.dok_id = " + pos_prodavnica_sql_schema() + ".pos_items.dok_id"
   cSql += " LEFT JOIN " +  pos_prodavnica_sql_schema() + ".pos_fisk_doks on " + pos_prodavnica_sql_schema() + ".pos_fisk_doks.ref_pos_dok = " + pos_prodavnica_sql_schema() + ".pos.dok_id"
   cSql += " WHERE " + pos_prodavnica_sql_schema() + ".pos_items.idvd='42' and (" + pos_prodavnica_sql_schema() + ".pos_items.datum>=" + sql_quote(dDatOd) + " and  " + pos_prodavnica_sql_schema() + ".pos_items.datum<=" + sql_quote(dDatDo) + ")"
   cSql += " GROUP BY " + pos_prodavnica_sql_schema() + ".pos.vrijeme, " + pos_prodavnica_sql_schema() + ".pos_items.brdok, " + pos_prodavnica_sql_schema() + ".pos_items.datum, pos_fisk_doks.broj_rn, " + pos_prodavnica_sql_schema() + ".pos_items.idvd"
   cSql += " ORDER BY " + pos_prodavnica_sql_schema() + ".pos_items.datum, " + pos_prodavnica_sql_schema() + ".pos_items.brdok"

   oQuery := run_sql_query( cSql )

   IF sql_error_in_query( oQuery )
      Alert("Greska SQL upit?!")
     return .f.
   ENDIF

   s_cXlsxName := my_home_root() + "pos_pregled_rn_" + dtos(dDatOd) + "_" + dtos(dDatDo) + ".xlsx"


   oQuery:GoTo( 1 )
   s_nPredhodniBroj := -999

   DO WHILE !oQuery:Eof()

      oRow := oQuery:GetRow()
      xlsx_export_fill_row(oRow)
   
      oQuery:Skip()

   ENDDO

   
   my_close_all_dbf()
   workbook_close( s_pWorkBook )
   s_pWorkBook := NIL
   s_pWorkSheet := NIL
   f18_open_mime_document( s_cXlsxName )

RETURN .T.

STATIC FUNCTION xlsx_export_fill_row(oRow)

   LOCAL nI
   LOCAL aKolona
   LOCAL nBrojFiskRacuna := oRow:FieldGet( oRow:FieldPos( "broj_rn" ) )
   LOCAL cKontrola := "OK"

   
   IF s_nPredhodniBroj == -999
      cKontrola := "OK"
   ELSE
      IF nBrojFiskRacuna - s_nPredhodniBroj <> 1
         cKontrola := "ERR"
      ENDIF
   ENDIF   
      
   s_nPredhodniBroj := nBrojFiskRacuna
   aKolona := {}
   AADD(aKolona, { "D", "Datum", 10, oRow:FieldGet( oRow:FieldPos( "datum" ) ) })
   AADD(aKolona, { "C", "Vrijeme", 12, oRow:FieldGet( oRow:FieldPos( "vrijeme" ) ) })

   AADD(aKolona, { "C", "Brdok", 12, oRow:FieldGet( oRow:FieldPos( "brdok" ) ) })
   AADD(aKolona, { "N", "Fisk.RN", 12, nBrojFiskRacuna })
   AADD(aKolona, { "C", "kontrola", 12, cKontrola })

   AADD(aKolona, { "M", "Iznos", 20, oRow:FieldGet( oRow:FieldPos( "iznos" ) ) })

   AADD(aKolona, { "N", "Br.stavki", 10, oRow:FieldGet( oRow:FieldPos( "brstavki" ) ) })


   IF s_pWorkSheet == NIL

         s_pWorkBook := workbook_new( s_cXlsxName )
         s_pWorkSheet := workbook_add_worksheet(s_pWorkBook, NIL)
      
         s_pMoneyFormat := workbook_add_format(s_pWorkBook)
         format_set_num_format(s_pMoneyFormat, /*"#,##0"*/ "#0.00" )
      
         s_pDateFormat := workbook_add_format(s_pWorkBook)
         format_set_num_format(s_pDateFormat, "d.mm.yy")
         
            
         /* Set the column width. */
         for nI := 1 TO LEN(aKolona)
            // worksheet_set_column(lxw_worksheet *self, lxw_col_t firstcol, lxw_col_t lastcol, double width, lxw_format *format)
            worksheet_set_column(s_pWorkSheet, nI - 1, nI - 1, aKolona[ nI, 3], NIL)
         next
         
         /* Set header */
         s_nWorkSheetRow := 0
         for nI := 1 TO LEN(aKolona)
            worksheet_write_string( s_pWorkSheet, s_nWorkSheetRow, nI - 1,  aKolona[nI, 2], NIL)
         next
            
   ENDIF
      
      
   s_nWorkSheetRow++
      
   FOR nI := 1 TO LEN(aKolona)
         IF aKolona[ nI, 1 ] == "C"
            worksheet_write_string( s_pWorkSheet, s_nWorkSheetRow, nI - 1,  hb_StrToUtf8(aKolona[nI, 4]), NIL)
         ELSEIF aKolona[ nI, 1 ] == "M"
            worksheet_write_number( s_pWorkSheet, s_nWorkSheetRow, nI - 1,  aKolona[nI, 4], s_pMoneyFormat)
         ELSEIF aKolona[ nI, 1 ] == "N"
            worksheet_write_number( s_pWorkSheet, s_nWorkSheetRow, nI - 1,  aKolona[nI, 4], NIL)
         ELSEIF aKolona[ nI, 1 ] == "D"
            worksheet_write_datetime( s_pWorkSheet, s_nWorkSheetRow, nI - 1,  aKolona[nI, 4], s_pDateFormat)
         ENDIF
   NEXT
            
RETURN .T.