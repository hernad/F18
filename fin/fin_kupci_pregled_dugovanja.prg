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


FUNCTION fin_kupci_pregled_dugovanja()

   LOCAL i
   LOCAL oReport, cSql
   LOCAL cIdKonto := PadR( "21", 7 )
   LOCAL cIdPartner := Space( 6 )
   LOCAL dDatOd := CToD( "01.01." + AllTrim( Str( Year( Date() ) ) ) )
   LOCAL dDatDo := Date()
   LOCAL cAvans := "N"
   LOCAL GetList := {}

   Box(, 5, 60 )
   @ box_x_koord() + 1, box_y_koord() + 2  SAY "Datum od " GET dDatOd
   @ box_x_koord() + 1, Col() + 2 SAY "do" GET dDatDo
   @ box_x_koord() + 3, box_y_koord() + 2  SAY "Konto% duguje: " GET cIdKonto
   @ box_x_koord() + 4, box_y_koord() + 2  SAY "Partner% (prazno svi): " GET cIdPartner
   @ box_x_koord() + 5, box_y_koord() + 2  SAY8 "Prikaz kupaca koji su u avansu D/N?" GET cAvans PICT "@!" VALID cAvans $ "DN"

   READ
   BoxC()

   IF LastKey() == K_ESC
      RETURN .F.
   ENDIF


   //[ernad.husremovic@sa.out.ba@zvijer F18_template]$ sha256sum kupci_pregled_dugovanja.xlsx 
   download_template( "kupci_pregled_dugovanja_2.xlsx", "f25e2f106abfd71a898798983ae14e728397954daed1021a5842eed5dde37606", .T. /* from master branch */ )

   oReport := YargReport():New( "kupci_pregled_dugovanja_2", "xlsx", "Header#BandSql1" )
   
   // 1) select * from sp_dugovanja('2022-01-01','2022-01-31', '211%', '%')
   // 2) select sp_dugovanja.*, partn.s_velicina, partn.s_vr_obezbj, partn.s_regija from sp_dugovanja('2022-01-01','2022-01-31', '211%', '%')
   //    left join partn on sp_dugovanja.partner_id = partn.id 
   // 3) select sp_dugovanja.*, partn_velicina_naz(partn.s_velicina), partn_vr_obezbj_naz(partn.s_vr_obezbj), partn_regija_naz(partn.s_regija) 
   //    from sp_dugovanja('2022-01-01','2022-01-31', '211%', '%')
   //    left join partn on sp_dugovanja.partner_id = partn.id

   cSql := "select sp_dugovanja.*,"
   cSql += " partn_velicina_naz(partn.s_velicina), partn_vr_obezbj_naz(partn.s_vr_obezbj), partn_regija_naz(partn.s_regija)"
   cSql += " from sp_dugovanja("
   cSql += sql_quote( dDatOd ) + ","
   cSql += sql_quote( dDatDo ) + ","
   cSql += sql_quote( Trim( cIdKonto ) + "%" ) + ","
   cSql += sql_quote( Trim( cIdPartner ) + "%" ) + ")"
   cSql += " left join partn on sp_dugovanja.partner_id = partn.id" 

   IF cAvans == "N"
      cSql += " WHERE i_ukupno>0"
   ELSE
      cSql += " WHERE i_ukupno<>0 "
   ENDIF

   // cSql += " WHERE i_ukupno"+to_xml_encoding("<>")+"0"
   // cSql += " AND idkonto=" + to_xml_encoding(sql_quote( Padr( "2110", 7) ))
   oReport:aSql := { cSql }

/*   oReport:aRecords := {}


   FOR i := 1 TO 1000
      hRec := hb_Hash()
      hRec[ "partner_id" ] := "000" + AllTrim( Str ( i ) )
      hRec[ "partner_naz" ] := "naz " + Str( i )
      hRec[ "i_ukupno" ] := i

      AAdd( oReport:aRecords, hRec )
   NEXT
*/
   oReport:run()

   RETURN .T.
