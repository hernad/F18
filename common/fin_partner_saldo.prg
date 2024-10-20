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


// ----------------------------------------
// vraca saldo partnera
// ----------------------------------------
FUNCTION get_fin_partner_saldo( id_partner, id_konto, id_firma )

   LOCAL cQuery, _table
   LOCAL _data := {}
   LOCAL nI, oRow
   LOCAL _saldo := 0

   cQuery := "SELECT SUM( CASE WHEN d_p = '1' THEN iznosbhd ELSE -iznosbhd END ) AS saldo FROM " + F18_PSQL_SCHEMA + ".fin_suban " + ;
      " WHERE idpartner = " + sql_quote( id_partner ) + ;
      " AND idkonto = " + sql_quote( id_konto ) + ;
      " AND idfirma = " + sql_quote( id_firma )

   _table := run_sql_query( cQuery )
   oRow := _table:GetRow( 1 )

   _saldo := oRow:FieldGet( oRow:FieldPos( "saldo" ) )

   IF ValType(_saldo ) == "L"
      _saldo := 0
   ENDIF

   RETURN _saldo



// -----------------------------------------
// datum posljednje uplate partnera
// -----------------------------------------
FUNCTION g_dpupl_part( id_partner, id_konto, id_firma )

   LOCAL cQuery, _table
   LOCAL _data := {}
   LOCAL nI, oRow
   LOCAL _max := CToD( "" )

   cQuery := "SELECT MAX( datdok ) AS uplata FROM " + F18_PSQL_SCHEMA + ".fin_suban " + ;
      " WHERE idpartner = " + sql_quote( id_partner ) + ;
      " AND idkonto = " + sql_quote( id_konto ) + ;
      " AND idfirma = " + sql_quote( id_firma ) + ;
      " AND d_p = '2' "

   _table := run_sql_query( cQuery )
   oRow := _table:GetRow( 1 )
   _max := oRow:FieldGet( oRow:FieldPos( "uplata" ) )

   IF ValType( _max ) == "L"
      _max := CToD( "" )
   ENDIF

   RETURN _max



FUNCTION datum_posljednje_promjene_kupac_dobavljac( id_partner, id_konto, id_firma )

   LOCAL cQuery, _table
   LOCAL _data := {}
   LOCAL nI, oRow
   LOCAL _max := CToD( "" )

   cQuery := "SELECT MAX( datdok ) AS uplata FROM " + F18_PSQL_SCHEMA + ".fin_suban " + ;
      " WHERE idpartner = " + sql_quote( id_partner ) + ;
      " AND idkonto = " + sql_quote( id_konto ) + ;
      " AND idfirma = " + sql_quote( id_firma )

   _table := run_sql_query( cQuery )
   oRow := _table:GetRow( 1 )
   _max := oRow:FieldGet( oRow:FieldPos( "uplata" ) )

   IF ValType( _max ) == "L"
      _max := CToD( "" )
   ENDIF

   RETURN _max



// -------------------------------------------------------
// ispisuje na ekranu box sa stanjem kupca
// -------------------------------------------------------
FUNCTION fin_partner_prikaz_stanja_ekran( cPartner, cKKup, cKDob )

   LOCAL nSKup := 0
   LOCAL nSDob := 0
   LOCAL dDate := CToD( "" )
   LOCAL nSaldo := 0
   LOCAL nX
   PRIVATE GetList := {}

   IF cKKUP <> NIL
      nSKup := get_fin_partner_saldo( cPartner, cKKup, self_organizacija_id() )
      dDate := g_dpupl_part( cPartner, cKKup, self_organizacija_id() )
   ENDIF

   IF cKDOB <> NIL
      nSDob := get_fin_partner_saldo( cPartner, cKDob, self_organizacija_id() )
   ENDIF

   nSaldo := nSKup + nSDob

   IF nSaldo = 0
      RETURN .T.
   ENDIF

   nX := 1

   Box(, 9, 50 )

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Trenutno stanje partnera:"

   ++ nX

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "-----------------------------------------------"

   ++ nX
   IF cKKUP <> NIL
      @ box_x_koord() + nX, box_y_koord() + 2 SAY PadR( "(1) stanje na kontu " + cKKup + ": " + AllTrim( Str( nSKup, 12, 2 ) ) + " KM", 45 ) COLOR IF( nSKup > 100, "W/R+", "W/G+" )
   ENDIF

   ++ nX
   IF cKDOB <> NIL
      @ box_x_koord() + nX, box_y_koord() + 2 SAY PadR( "(2) stanje na kontu " + cKDob + ": " + AllTrim( Str( nSDob, 12, 2 ) ) + " KM", 45 ) COLOR "W/GB+"
   ENDIF

   ++ nX

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "-----------------------------------------------"
   ++nX

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Total (1+2) = " + AllTrim( Str( nSaldo, 12, 2 ) ) + " KM" COLOR IF( nSaldo > 100, "W/R+", "W/G+" )

   nX += 2

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Datum zadnje uplate: " + DToC( dDate )

   Inkey( 0 )

   BoxC()

   RETURN .T.
