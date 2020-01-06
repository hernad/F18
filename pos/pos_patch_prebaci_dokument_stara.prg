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


FUNCTION pos_patch_prebaci_dokument_stara_godina()

   LOCAL dDatDok := DATE() - 30
   LOCAL cIdVd := '22'
   LOCAL cBrDok := '00000001'
   LOCAL cBrDokNovi := SPACE( 8 )
   LOCAL hServerParams := my_server_params()
   LOCAL cDatabaseTekuca := my_server_params()[ "database" ]
   LOCAL nYearPredhodna
   LOCAL cSql
   LOCAL nCount
   LOCAL cSigurno := SPACE(4)
   LOCAL GetList := {}
   LOCAL cOpis

   Box(, 6, 60 )
   @ box_x_koord() + 1, box_y_koord() + 2 SAY8 "Sigurnosni kod operacije:" GET cSigurno PICT "@!" ;
      VALID {|| cSigurno == 'P06H' }
   @ box_x_koord() + 3, box_y_koord() + 2 SAY8 "    Datum dokumenta: " GET dDatDok
   @ box_x_koord() + 4, box_y_koord() + 2 SAY8 "    Vrsta dokumenta: " GET cIdVd
   @ box_x_koord() + 5, box_y_koord() + 2 SAY8 "               Broj: " GET cBrDok VALID !Empty( cBrDok )

   // mora se rijesiti problem preklapanja brojeva dokumenata
   // npr. 31.12.2019, 22-00000730 u buducnosti ce se pojaviti KALK dokument 22-00000730 npr 10.05.2020
   // zato brojevi dokumenta trebaju biti SPACE vodjeni
   // 00000730 -> '     730'

   @ box_x_koord() + 6, box_y_koord() + 2 SAY8 "Broj u novoj godini: " GET cBrDokNovi VALID !Empty( cBrDokNovi ) ;
         WHEN { || cBrDokNovi := STRTRAN(cBrDok, '0', ' '), .T. } 
   READ
   
   BoxC()

   IF LastKey() == K_ESC
      RETURN .F.
   ENDIF

   nYearPredhodna := year(date())-1

   switch_to_database( hServerParams, cDatabaseTekuca, nYearPredhodna )

   SELECT 401
   cSql := "SELECT * from " + f18_sql_schema( "pos" ) + " WHERE "
   cSql += "datum=" + sql_quote( dDatDok ) + " AND idvd=" + sql_quote( cIdVd ) + " AND brdok=" + sql_quote( cBrDok )

   IF !use_sql( "POS_STARA", cSql, "POS_STARA" )
      Alert( "cSqlQuery")
      RETURN .F.
   ENDIF
   
   IF Eof() .OR. (pos_stara->idvd <> cIdVd)
      Alert(_u("Nema traženog dokumenta u " +  Alltrim(Str(nYearPredhodna)) + " ?!"))
      switch_to_database(hServerParams, cDatabaseTekuca, year( date()) )
      SELECT 401
      USE
      RETURN .F.
   ENDIF
      

   SELECT 402
   cSql := "SELECT * from " + f18_sql_schema( "pos_items" ) + " WHERE "
   cSql += "datum=" + sql_quote( dDatDok ) + " AND idvd=" + sql_quote( cIdVd ) + " AND brdok=" + sql_quote( cBrDok )

   altd()
   IF !use_sql( "POS_ITEMS_STARA",  cSql, "POS_ITEMS_STARA" )
      Alert( "cSqlQuery")
      RETURN .F.
   ENDIF

   switch_to_database(hServerParams, cDatabaseTekuca, year( date()) )



   run_sql_query( "BEGIN" )
   SELECT POS_STARA
   IF cIdvd == "22"
      // vidi v4_util.sql
      // FUNCTION public.kalk_22_neobradjeni_dokumenti() RETURNS TABLE( pkonto varchar, brdok varchar, datdok date, brfaktp varchar )
      // na ovaj nacin KALK nece pokusavati ove dokumente obraditi
      cOpis := "ODBIJENO - PATCH PRENOS STARA GODINA"
   ELSE
      cOpis := pos_stara->opis
   ENDIF
   cSql := "INSERT INTO " + f18_sql_schema( "pos" ) + "(idpos,idpartner,idradnik,idvrstep,datum,idvd,brdok,opis,brfaktp) values("
   cSql += sql_quote( pos_stara->idpos) + "," + sql_quote( pos_stara->idpartner) + "," + sql_quote(pos_stara->idradnik) + "," + sql_quote(pos_stara->idvrstep) + ","
   cSql += sql_quote( pos_stara->datum) + "," + sql_quote( pos_stara->idvd) + "," + sql_quote( cBrDokNovi ) + ","
   cSql += sql_quote( cOpis ) + "," + sql_quote( pos_stara->brfaktp )
   cSql += ")"
   run_sql_query( cSql )

   SELECT POS_ITEMS_STARA
   GO TOP
   nCount := 0
   DO WHILE !EOF()
      cSql := "INSERT INTO " + f18_sql_schema( "pos_items" ) + "(idpos,datum,idvd,brdok,kolicina,cijena,kol2,idroba,idtarifa,ncijena,rbr,robanaz,jmj) values("
      cSql += sql_quote( pos_items_stara->idpos) + "," + sql_quote( pos_items_stara->datum) + "," + sql_quote( pos_items_stara->idvd) + "," + sql_quote( cBrDokNovi ) + ","
      cSql += sql_quote( pos_items_stara->kolicina) + "," + sql_quote( pos_items_stara->cijena) + "," + sql_quote(pos_items_stara->kol2) + ","
      cSql += sql_quote( pos_items_stara->idroba) + "," +  sql_quote( pos_items_stara->idtarifa) + "," + sql_quote( pos_items_stara->ncijena) + "," + sql_quote( pos_items_stara->rbr) + "," + sql_quote( pos_items_stara->robanaz) + "," + sql_quote( pos_items_stara->jmj)
      cSql += ")"
      run_sql_query( cSql )
      nCount ++
      SKIP
   ENDDO

   SELECT 401
   USE
   SELECT 402
   USE

   run_sql_query( "COMMIT" )

   MsgBeep( "Prebačeno stavki " + AllTrim(Str(nCount)) )
   

   RETURN .T.
