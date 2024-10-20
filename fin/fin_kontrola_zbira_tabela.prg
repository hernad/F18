/*
 * This file is part of the bring.out FMK, a free and open source
 * accounting software suite,
 * Copyright (c) 1994-2024 by bring.out d.o.o Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including knowhow ERP specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_knowhow.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */

#include "f18.ch"

// --------------------------------
// kontrola zbira naloga
// lKontrolaZaDatumskiPeriod = datumski uslov
// lSilent - ne prikazuj box
// vraca lRet - .t. ako je sve ok,
// .f. ako nije
// --------------------------------
FUNCTION fin_kontrola_zbira_tabele_prometa( lKontrolaZaDatumskiPeriod )

   LOCAL lRet := .T.
   LOCAL nSaldo := 0
   LOCAL nSintD := 0
   LOCAL nSintP := 0
   LOCAL nSubD := 0
   LOCAL nSubP := 0
   LOCAL nNalD := 0
   LOCAL nNalP := 0
   LOCAL nAnalP := 0
   LOCAL nAnalD := 0
   LOCAL cLinija
   LOCAL dDatOd, dDatDo
   LOCAL GetList := {}

   IF ( lKontrolaZaDatumskiPeriod == NIL )
      lKontrolaZaDatumskiPeriod := .T.
   ENDIF


   my_close_all_dbf()

   Box( "#Promet bez datumskog ograničenja", 11, 77, .F. )

   set_cursor_off()

   cLinija := Replicate( "=", 10 ) + " " + Replicate( "=", 16 ) + " " + ;
      Replicate( "=", 16 ) + " " + Replicate( "=", 16 ) + " " + Replicate( "=", 16 )

   @ box_x_koord() + 1, box_y_koord() + 11 SAY "|" + PadC( "NALOZI", 16 ) + ;
      "|" + PadC( "SINTETIKA", 16 ) + ;
      "|" + PadC( "ANALITIKA", 16 ) + ;
      "|" + PadC( "SUBANALITIKA", 16 )

   @ box_x_koord() + 2, box_y_koord() + 1 SAY cLinija

   @ box_x_koord() + 3, box_y_koord() + 1 SAY "duguje " + valuta_domaca_skraceni_naziv()
   @ box_x_koord() + 4, box_y_koord() + 1 SAY "potraz." + valuta_domaca_skraceni_naziv()
   @ box_x_koord() + 5, box_y_koord() + 1 SAY "saldo  " + valuta_domaca_skraceni_naziv()
   @ box_x_koord() + 7, box_y_koord() + 1 SAY "duguje " + ValPomocna()
   @ box_x_koord() + 8, box_y_koord() + 1 SAY "potraz." + ValPomocna()
   @ box_x_koord() + 9, box_y_koord() + 1 SAY "saldo  " + ValPomocna()

   @ box_x_koord() + 10, box_y_koord() + 1 SAY cLinija

   @ box_x_koord() + 11, box_y_koord() + 1 SAY "<ANYKEY> - kontrola"

   FOR i := 11 TO 65 STEP 17
      FOR j := 3 TO 9
         @ box_x_koord() + j, box_y_koord() + i SAY "|"
      NEXT
   NEXT

   picBHD := FormPicL( "9 " + gPicBHD, 16 )
   picDEM := FormPicL( "9 " + pic_iznos_eur(), 16 )


   fin_kontrola_zbira_nalozi()


   IF LastKey() == K_ESC
      BoxC()
      CLOSERET
   ENDIF
   @ box_x_koord() + 3, box_y_koord() + 12 SAY duguje PICTURE picBHD
   @ box_x_koord() + 4, box_y_koord() + 12 SAY potrazuje PICTURE picBHD
   @ box_x_koord() + 5, box_y_koord() + 12 SAY duguje - potrazuje PICTURE picBHD
   @ box_x_koord() + 7, box_y_koord() + 12 SAY duguje2 PICTURE picDEM
   @ box_x_koord() + 8, box_y_koord() + 12 SAY potrazuje2 PICTURE picDEM
   @ box_x_koord() + 9, box_y_koord() + 12 SAY duguje2 - potrazuje2 PICTURE picDEM


   fin_kontrola_zbira_sintetika()

   ESC_BCR
   
   @ box_x_koord() + 3, box_y_koord() + 29 SAY duguje PICTURE picBHD
   @ box_x_koord() + 4, box_y_koord() + 29 SAY potrazuje PICTURE picBHD
   @ box_x_koord() + 5, box_y_koord() + 29 SAY duguje - potrazuje PICTURE picBHD
   @ box_x_koord() + 7, box_y_koord() + 29 SAY duguje2 PICTURE picDEM
   @ box_x_koord() + 8, box_y_koord() + 29 SAY potrazuje2 PICTURE picDEM
   @ box_x_koord() + 9, box_y_koord() + 29 SAY duguje2 - potrazuje2 PICTURE picDEM


   fin_kontrola_zbira_analitika()

   ESC_BCR


   @ box_x_koord() + 3, box_y_koord() + 46 SAY duguje PICTURE picBHD
   @ box_x_koord() + 4, box_y_koord() + 46 SAY potrazuje PICTURE picBHD
   @ box_x_koord() + 5, box_y_koord() + 46 SAY duguje - potrazuje PICTURE picBHD
   @ box_x_koord() + 7, box_y_koord() + 46 SAY duguje2 PICTURE picDEM
   @ box_x_koord() + 8, box_y_koord() + 46 SAY potrazuje2 PICTURE picDEM
   @ box_x_koord() + 9, box_y_koord() + 46 SAY duguje2 - potrazuje2 PICTURE picDEM



   fin_kontrola_zbira_subanalitika()

   // ESC_BCR

   @ box_x_koord() + 3, box_y_koord() + 63 SAY duguje PICTURE picBHD
   @ box_x_koord() + 4, box_y_koord() + 63 SAY potrazuje PICTURE picBHD
   @ box_x_koord() + 5, box_y_koord() + 63 SAY duguje - potrazuje PICTURE picBHD
   @ box_x_koord() + 7, box_y_koord() + 63 SAY duguje2 PICTURE picDEM
   @ box_x_koord() + 8, box_y_koord() + 63 SAY potrazuje2 PICTURE picDEM
   @ box_x_koord() + 9, box_y_koord() + 63 SAY duguje2 - potrazuje2 PICTURE picDEM

   // WHILE Inkey( 0.1 ) != K_ESC
   // END
   Inkey( 0 )

   BoxC()

   IF ( lKontrolaZaDatumskiPeriod )
      dDatOd := CToD( "01.01." + Str( tekuca_sezona(), 4, 0 ) )
      dDatDo := CToD( "31.12." + Str( tekuca_sezona(), 4, 0 ) )
      Box(, 1, 45 )
      @ 1 + box_x_koord(), 2 + box_y_koord() SAY "Kontrola za period: " GET dDatOd
      @ 1 + box_x_koord(), Col() + 2 SAY "-" GET dDatDo
      READ
      BoxC()

      IF LastKey() == K_ESC
         RETURN .F.
      ENDIF
   ENDIF

   // provjeri da li su podaci tacni !
   IF ( Round( nSaldo, 2 ) > 0 ) .OR. ( Round( nSubD + nNalD + nAnalD + nSintD, 2 ) <> Round( nSubP + nNalP + nAnalP + nSintP, 2 ) )
      lRet := .F.
   ENDIF

   IF gnKZBdana > 0
      // upisi u params podatak o datumu povlacenja...
      set_metric( "fin_kontrola_zbira_datum", NIL, Date() )
   ENDIF

   info_bar( "fin", "kontrola neuravnoteženih naloga ..." )
   IF fin_kontrola_ima_li_neuravnotezenih_naloga()
      SELECT SUBAN_KONTROLA
      DO WHILE !Eof()
         MsgBeep( "Neravnoteža naloga: " + field->idfirma + "-"  + field->idvn + "-" + field->brnal )
         SKIP
         IF LastKey() == K_ESC
            USE
            RETURN .F.
         ENDIF
      ENDDO
      USE
   ENDIF

   info_bar( "fin", "kontrola stavke van zadatog perioda ..." )
   IF lKontrolaZaDatumskiPeriod .AND. fin_kontrola_stavke_van_perioda( dDatOd, dDatDo )
      SELECT SUBAN_KONTROLA
      DO WHILE !Eof()
         MsgBeep( "Nalog sadrži stavke van zadanog perioda: " + field->idfirma + "-"  + field->idvn + "-" + field->brnal + " ##" + ;
            DToC( field->min_datdok ) + " - " + DToC( field->max_datdok ) )
         SKIP
         IF LastKey() == K_ESC
            USE
            RETURN .F.
         ENDIF
      ENDDO
      USE
   ENDIF

   RETURN lRet



FUNCTION fin_kontrola_ima_li_neuravnotezenih_naloga()

   LOCAL cSql := "SELECT idfirma, idvn, brnal,"

   cSql += "sum(CASE WHEN d_p='1' THEN iznosbhd ELSE -iznosbhd END) as saldo_naloga"
   cSql += " FROM fmk.fin_suban"
   cSql += " GROUP BY idfirma,idvn,brnal"
   cSql += " HAVING sum(CASE WHEN d_p='1' THEN iznosbhd ELSE -iznosbhd END) <> 0"

   IF !use_sql( "fin_suban", cSql, "SUBAN_KONTROLA" )
      RETURN .F.
   ENDIF

   SELECT suban_kontrola
   IF Eof()
      USE
      RETURN .F.
   ENDIF

   RETURN .T.


FUNCTION fin_kontrola_stavke_van_perioda( dDatOd, dDatDo )

   LOCAL cSql := "SELECT idfirma, idvn, brnal,"

   cSql += "sum(CASE WHEN d_p='1' THEN iznosbhd ELSE -iznosbhd END) as saldo_naloga,"
   cSql += "min(datdok) as min_datdok, max(datdok) as max_datdok"
   cSql += " FROM fmk.fin_suban"
   cSql += " GROUP BY idfirma,idvn,brnal"
   cSql += " HAVING min(datdok)<" + sql_quote( dDatOd ) + " OR max(datdok) >" + sql_quote( dDatDo )

#ifdef F18_DEBUG
   ?E cSql
#endif

   IF !use_sql( "fin_suban", cSql, "SUBAN_KONTROLA" )
      RETURN .F.
   ENDIF

   SELECT suban_kontrola
   IF Eof()
      USE
      RETURN .F.
   ENDIF

   RETURN .T.


// -------------------------------------------------
// automatsko pokretanje kontrole zbira datoteka
// -------------------------------------------------
FUNCTION auto_kzb()

   LOCAL dDate := Date()
   LOCAL nTArea := Select()
   LOCAL lKzbOk
   LOCAL dLastDate := Date()
   PRIVATE cSection := "9"
   PRIVATE cHistory := " "
   PRIVATE aHistory := {}

   IF gnKZBdana == 0
      RETURN .F.
   ENDIF

   // uzmi datum zadnjeg povlacenja kontrole zbira
   dLastDate := fetch_metric( "fin_kontrola_zbira_datum", NIL, dLastdate )

   // ako je manje od KZBdana ne pozivaj opciju...
   IF ( dDate - dLastDate ) <= gnKZBdana
      SELECT ( nTArea )
      RETURN .F.
   ENDIF

   lKzbOk := fin_kontrola_zbira_tabele_prometa( NIL, .T. )

   IF !lKzbOk
      MsgBeep( "Kontrola zbira datoteka je pronašla greske!#Pregledajte greške." )
      fin_kontrola_zbira_tabele_prometa()
   ENDIF

   SELECT ( nTArea )

   RETURN .T.




FUNCTION fin_kontrola_zbira_subanalitika()

   LOCAL cTable := "SUBAN"
   LOCAL cSql :=  "select "

   cSql += "coalesce(sum(CASE WHEN d_p='1' THEN iznosbhd ELSE 0 END),0) as duguje,"
   cSql += "coalesce(sum(CASE WHEN d_p='2' THEN iznosbhd ELSE 0 END),0) as potrazuje,"
   cSql += "coalesce(sum(CASE WHEN d_p='1' THEN iznosdem ELSE 0 END),0) as duguje2,"
   cSql += "coalesce(sum(CASE WHEN d_p='2' THEN iznosdem ELSE 0 END),0) as potrazuje2"
   cSql += " from fmk.fin_suban"

   RETURN use_sql( cTable, cSql )

FUNCTION fin_kontrola_zbira_analitika()

   LOCAL cTable := "ANAL"
   LOCAL cSql :=  "select "

   cSql += "coalesce(sum(dugbhd),0) as duguje,"
   cSql += "coalesce(sum(potbhd),0) as potrazuje,"
   cSql += "coalesce(sum(dugdem),0) as duguje2,"
   cSql += "coalesce(sum(potdem),0) as potrazuje2"
   cSql += " from fmk.fin_anal"

   RETURN use_sql( cTable, cSql )


FUNCTION fin_kontrola_zbira_sintetika()

   LOCAL cTable := "SINT"
   LOCAL cSql :=  "select "

   cSql += "coalesce(sum(dugbhd),0) as duguje,"
   cSql += "coalesce(sum(potbhd),0) as potrazuje,"
   cSql += "coalesce(sum(dugdem),0) as duguje2,"
   cSql += "coalesce(sum(potdem),0) as potrazuje2"
   cSql += " from fmk.fin_sint"

   RETURN use_sql( cTable, cSql )

FUNCTION fin_kontrola_zbira_nalozi()

   LOCAL cTable := "NALOG"
   LOCAL cSql :=  "select "

   cSql += "coalesce(sum(dugbhd),0) as duguje,"
   cSql += "coalesce(sum(potbhd),0) as potrazuje,"
   cSql += "coalesce(sum(dugdem),0) as duguje2,"
   cSql += "coalesce(sum(potdem),0) as potrazuje2"
   cSql += " from fmk.fin_nalog"

   RETURN use_sql( cTable, cSql )
