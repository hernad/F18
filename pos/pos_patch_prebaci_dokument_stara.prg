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


MEMVAR gIdRadnik

/*

-- 1) radnik 00010 odbija prijem:
-- select p2.pos_21_to_22( '20567431', '0010', false );
-- generise se samo p2.pos stavka 22, sa opisom: ODBIJENO: 0010

-- 2) radnik 00010 potvrdjuje prijem:
-- select p2.pos_21_to_22( '20567431', '0010', true );
-- generise se samo p2.pos stavka 22, sa opisom: PRIJEM: 0010

FUNCTION p2.pos_21_to_22( cBrFaktP varchar, cIdRadnik varchar, lPreuzimaSe boolean) RETURNS integer

*/

FUNCTION pos_patch_prebaci_dokument_stara_godina()

   LOCAL dDatDok := DATE() - 30
   LOCAL cIdVd := '22'
   LOCAL cBrDok := SPACE(8)
   LOCAL hServerParams := my_server_params()
   LOCAL cDatabaseTekuca := my_server_params()[ "database" ]
   LOCAL nYearPredhodna
   LOCAL cSql
   
   cBrFaktP := Space( 10 )
   LOCAL GetList := {}
   LOCAL cPregledDN := "D"
   LOCAL cPreuzimaSeDN := "D"
   LOCAL nRet, cMsg
   LOCAL nCount

   Box(, 5, 60 )
   @ box_x_koord() + 1, box_y_koord() + 2 SAY8 "Datum dokumenta: " GET dDatDok VALID year(date())-1 == year(dDatDok)
   @ box_x_koord() + 2, box_y_koord() + 2 SAY8 "Vrsta dokumenta: " GET cIdVd
   @ box_x_koord() + 3, box_y_koord() + 2 SAY8 "           Broj: " GET cBrDok VALID !Empty( cBrDok )
   READ
   
   BoxC()

   IF LastKey() == K_ESC
      RETURN .F.
   ENDIF

   nYearPredhodna := year(dDatDok)

   switch_to_database( hServerParams, cDatabaseTekuca, nYearPredhodna )

   SELECT 401
   cSql := "SELECT * from " + f18_sql_schema( "pos" ) + " WHERE "
   cSql += "datum=" + sql_quote( dDatum ) + " AND idvd=" + sql_quote( cIdVd ) + " AND brdok=" + sql_quote( cBrDok )

   IF !use_sql( "POS_STARA",  cSql, "POS_STARA" )
      Alert( "cSqlQuery")
      RETURN .F.
   ENDIF
   
   IF pos_stara->eof() .OR. pos_stara->idvd <> cIdVd
      Alert("Nema traženog dokumenta u " +  Alltrim(Str(nYearPredhodna) + " ?!")
      switch_to_database(hServerParams, cDatabaseTekuca, year( date()) )
      SELECT 401
      USE
      RETURN .F.
   ENDIF
      

   SELECT 402
   cSql := "SELECT * from " + f18_sql_schema( "pos_items" ) + " WHERE "
   cSql += "datum=" + sql_quote( dDatum ) + " AND idvd=" + sql_quote( cIdVd ) + " AND brdok=" + sql_quote( cBrDok )

   IF !use_sql( "POS_ITEMS_STARA",  cSql, "POS_ITEMS_STARA" )
      Alert( "cSqlQuery")
      RETURN .F.
   ENDIF


   switch_to_database(hServerParams, cDatabaseTekuca, year( date()) )

   
   run_sql_query( "BEGIN" )
   SELECT POS_STARA
   cSql := "INSERT INTO " + f18_sql_schema( "pos" ) + "(datum,idvd,brdok,opis) values("
   cSql += sql_quote( pos_stara->datum) + "," + sql_quote( pos_stara->idvd) + "," + sql_quote( pos_stara->brdok) + ","
   cSql += sql_quote( pos_stara->opis)
   cSql += ")"
   run_sql_query( cSql )

   SELECT POS_ITEMS_STARA
   GO TOP
   nCount := 0
   DO WHILE !EOF()
      cSql := "INSERT INTO " + f18_sql_schema( "pos_items" ) + "(datum,idvd,brdok,kolicina,cijena,kol2) values("
      cSql += sql_quote( pos_items_stara->datum) + "," + sql_quote( pos_items_stara->idvd) + "," + sql_quote( pos_items_stara->brdok) + ","
      cSql += sql_quote( pos_items_stara->kolicina) + "," + sql_quote( pos_items_stara->cijena) + "," + sql_quote(pos_items_stara->kol2)
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

   MsgBeep( "Prebačeno stavki " + AllTrm(Str(nCount)) )
   

   RETURN .T.
