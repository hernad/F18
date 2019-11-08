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

FUNCTION o_pos_priprz()

   SELECT ( F_PRIPRZ )
   my_use( "priprz" )
   SET ORDER TO TAG "1"

   RETURN .T.



FUNCTION o_pos_priprg()

   SELECT ( F_PRIPRG )
   my_use( "priprg" )
   SET ORDER TO TAG "1"

   RETURN .T.


FUNCTION o_pos__pos()

   SELECT ( F__POS )
   my_use( "_pos" )
   SET ORDER TO TAG "1"

   RETURN .T.

/*
-- FUNCTION o_pos_uredj()

   SELECT ( F_UREDJ )
   my_use( "uredj" )
   SET ORDER TO TAG "ID"

   RETURN .T.
*/

FUNCTION pos_init()

   my_close_all_dbf()
   pos_definisi_inicijalne_podatke()
   cre_priprz()

   RETURN .T.


STATIC FUNCTION cre_priprz()

   LOCAL cFileName := my_home() + "PRIPRZ"
   LOCAL lCreate := .F.
   LOCAL aDbf

   IF !File( f18_ime_dbf( "priprz" ) )
      lCreate := .T.
   ELSE
      CLOSE ALL
      o_pos_priprz()
      IF reccount2() > 0
         RETURN .F.
      ENDIF

      IF FieldPos( "k7" ) == 0
         lCreate := .T.
      ENDIF
   ENDIF

   CLOSE ALL
   IF lCreate
      aDbf := g_pos_pripr_fields()
      DBcreate2 ( cFileName, aDbf )
      CREATE_INDEX ( "1", "IdRoba", cFileName )
   ENDIF

   RETURN .T.




STATIC FUNCTION pos_dodaj_u_sifarnik_prioriteta( cId, cPrioritet, cOpis )

   LOCAL lOk := .T.
   LOCAL hRec

   IF select_o_pos_strad( PadR( cId, 2 ) )
      RETURN .F.
   ENDIF

   hRec := dbf_get_rec()
   hRec[ "id" ] := PadR( cId, 2 )
   hRec[ "prioritet" ] := PadR( cPrioritet, Len( hRec[ "prioritet" ] ) )
   hRec[ "naz" ] := PadR( cOpis, Len( hRec[ "naz" ] ) )

   APPEND BLANK
   lOk := update_rec_server_and_dbf( "pos_strad", hRec, 1, "FULL" )

   RETURN lOk




STATIC FUNCTION pos_dodaj_u_sifarnik_radnika( cId, cLozinka, cOpis, cStatus )

   LOCAL lOk := .T.
   LOCAL hRec

   // IF Select( "OSOB" ) == 0
   IF select_o_pos_osob( cId )
      RETURN .F.
   ENDIF
   // ELSE
   // SELECT OSOB
   // ENDIF


   hRec := dbf_get_rec()
   hRec[ "id" ] := PadR( cId, Len( hRec[ "id" ] ) )
   hRec[ "korsif" ] := PadR( CryptSc( PadR( cLozinka, 6 ) ), 6 )
   hRec[ "naz" ] := PadR( cOpis, Len( hRec[ "naz" ] ) )
   hRec[ "status" ] := PadR( cStatus, Len( hRec[ "status" ] ) )

   APPEND BLANK
   lOk := update_rec_server_and_dbf( "pos_osob", hRec, 1, "FULL" )

   RETURN lOk



STATIC FUNCTION pos_definisi_inicijalne_podatke()

   LOCAL lOk := .T., hParams

   // select_o_pos_strad()
   // IF table_count( F18_PSQL_SCHEMA_DOT + "pos_strad" ) == 0
   // IF ( RECCOUNT2() == 0 )

   // MsgO( "Definišem šifre prioriteta ..." )

   // run_sql_query( "BEGIN" )
   // IF !f18_lock_tables( { "pos_strad" }, .T. )
   // run_sql_query( "ROLLBACK" )
   // RETURN .F.
   // ENDIF

   lOk := pos_dodaj_u_sifarnik_prioriteta( "0", "0", "Nivo adm." )

   // IF lOk
   lOk := pos_dodaj_u_sifarnik_prioriteta( "1", "1", "Nivo upr." )
   // ENDIF

   // IF lOk
   lOk := pos_dodaj_u_sifarnik_prioriteta( "3", "3", "Nivo prod." )
   // ENDIF

   // MsgC()

   // IF lOk
   // hParams := hb_Hash()
   // hParams[ "unlock" ] := { "pos_strad" }
   // run_sql_query( "COMMIT", hParams )

   // ELSE
   // run_sql_query( "ROLLBACK" )
   // ENDIF

   // ENDIF

   // o_pos_osob()
   // IF ( RECCOUNT2() == 0 )
   // IF table_count( F18_PSQL_SCHEMA_DOT + "pos_osob" ) == 0

   // MsgO( "Definišem šifranik radnika ..." )

   // run_sql_query( "BEGIN" )
   // IF !f18_lock_tables( { "pos_osob" }, .T. )
   // run_sql_query( "COMMIT" )
   // RETURN .F.
   // ENDIF

   lOk := pos_dodaj_u_sifarnik_radnika( "0001", "PARSON", "Admin", "0" )

   // IF lOk
   lOk := pos_dodaj_u_sifarnik_radnika( "0010", "P1", "Prodavac 1", "3" )
   // ENDIF

   // IF lOk
   lOk := pos_dodaj_u_sifarnik_radnika( "0011", "P2", "Prodavac 2", "3" )
   // ENDIF

   // MsgC()

   // IF lOk
   // f18_unlock_tables( { "pos_osob" } )
   // run_sql_query( "COMMIT" )
   // ELSE
   // run_sql_query( "ROLLBACK" )
   // ENDIF

   // ENDIF

   my_close_all_dbf()

   RETURN .T.


FUNCTION o_pos_tables( lOtvoriKumulativ )

   my_close_all_dbf()

   IF lOtvoriKumulativ == NIL
      lOtvoriKumulativ := .T.
   ENDIF

   IF lOtvoriKumulativ
      o_pos_kumulativne_tabele()
   ENDIF

   // o_pos_odj()
   // o_pos_osob()
   // SET ORDER TO TAG "NAZ"

   // o_vrstep()
// o_partner()
   // O_K2C
// O_MJTRUR
// o_pos_kase()
// o_sastavnice()
// o_roba()
   // o_tarifa()
   // o_sifk()
   // o_sifv()
   o_pos_priprz()
   o_pos_priprg()
   o_pos__pos()
   O__POS_PRIPR

   IF lOtvoriKumulativ
      SELECT pos_doks
   ELSE
      SELECT _pos_pripr
   ENDIF

   RETURN .T.


FUNCTION o_pos_kumulativne_tabele()

   o_pos_pos()
   o_pos_doks()
   // o_pos_dokspf()

   RETURN .T.



FUNCTION o_pos_sifre()

   // o_pos_kase()
   // o_pos_uredj()
   // o_pos_odj()
   // o_roba()
   // o_tarifa()
   // o_vrstep()
   // o_valute()
   // o_partner()
   // o_pos_osob()
   // o_pos_strad()
   // o_sifk()
   // o_sifv()

   RETURN .T.






FUNCTION pos_iznos_dokumenta( lUI )

   LOCAL cRet := Space( 13 )
   LOCAL l_u_i
   LOCAL nIznos := 0
   LOCAL cIdPos, cIdVd, cBrDok
   LOCAL dDatum

   SELECT pos_doks

   cIdPos := pos_doks->idPos
   cIdVd := pos_doks->idVd
   cBrDok := pos_doks->brDok
   dDatum := pos_doks->datum

   IF ( ( lUI == NIL ) .OR. lUI )

      IF pos_doks->IdVd $ VD_ZAD + "#" + POS_VD_POCETNO_STANJE + "#" + VD_REK // ulazi

         seek_pos_pos( cIdPos, cIdVd, dDatum, cBrDok )
         DO WHILE !Eof() .AND. pos->( IdPos + IdVd + DToS( datum ) + BrDok ) == cIdPos + cIdVd + DToS( dDatum ) + cBrDok
            nIznos += pos->kolicina * pos->cijena
            SKIP
         ENDDO
         IF pos_doks->idvd == VD_REK
            nIznos := -nIznos
         ENDIF
      ENDIF
   ENDIF

   IF ( ( lUI == NIL ) .OR. !lUI ) // izlazi
      IF pos_doks->idvd $ POS_VD_RACUN + "#" + VD_OTP + "#" + VD_RZS + "#" + VD_PRR + "#" + "IN" + "#" + VD_NIV

         seek_pos_pos( cIdPos, cIdVd, dDatum, cBrDok )

         DO WHILE !Eof() .AND. pos->( IdPos + IdVd + DToS( datum ) + BrDok ) == cIdPos + cIdVd + DToS( dDatum ) + cBrDok
            DO CASE
            CASE pos_doks->idvd == "IN"
               // samo ako je razlicit iznos od 0
               // ako je 0 onda ne treba mnoziti sa cijenom
               IF pos->kol2 <> 0
                  nIznos += pos->kol2 * pos->cijena
               ENDIF
            CASE pos_doks->IdVd == VD_NIV
               nIznos += pos->kolicina * ( pos->ncijena - pos->cijena )
            OTHERWISE
               nIznos += pos->kolicina * pos->cijena
            ENDCASE
            SKIP
         ENDDO
      ENDIF
   ENDIF

   SELECT pos_doks
   cRet := Str( nIznos, 13, 2 )

   RETURN ( cRet )




FUNCTION Del_Skip()

   LOCAL nNextRec

   nNextRec := 0
   SKIP
   nNextRec := RecNo()
   SKIP -1
   my_delete()
   GO nNextRec

   RETURN .T.



FUNCTION GoTop2()

   GO TOP
   IF Deleted()
      SKIP
   ENDIF

   RETURN .T.



/*
    Opis: da li ažurirani račun sadrži traženi artikal
 */

FUNCTION pos_racun_sadrzi_artikal( cIdPos, cIdVd, dDatum, cBroj, cIdRoba )

   LOCAL lRet := .F.
   LOCAL cWhere

   cWhere := " idpos " + sql_quote( cIdPos )
   cWhere += " AND idvd = " + sql_quote( cIdVd )
   cWhere += " AND datum = " + sql_quote( dDatum )
   cWhere += " AND brdok = " + sql_quote( cBroj )
   cWhere += " AND idroba = " + sql_quote( cIdRoba )

   IF ( F18_PSQL_SCHEMA_DOT + "pos_pos", cWhere ) > 0
      lRet := .T.
   ENDIF

   RETURN lRet


/*
-- FUNCTION pos_import_fmk_roba()

   LOCAL _location := fetch_metric( "pos_import_fmk_roba_path", my_user(), PadR( "", 300 ) )
   LOCAL _cnt := 0
   LOCAL hRec
   LOCAL lOk := .T.
   LOCAL hParams

   o_roba()

   _location := PadR( AllTrim( _location ), 300 )

   Box(, 1, 60 )
   @ box_x_koord() + 1, box_y_koord() + 2 SAY "lokacija:" GET _location PICT "@S50"
   READ
   BoxC()

   IF LastKey() == K_ESC
      RETURN .F.
   ENDIF

   set_metric( "pos_import_fmk_roba_path", my_user(), _location )

   SELECT ( F_TMP_1 )
   IF Used()
      USE
   ENDIF

   my_use_temp( "TOPS_ROBA", AllTrim( _location ), .F., .T. )
   INDEX ON ( "id" ) TAG "ID"

   SELECT tops_roba
   SET ORDER TO TAG "ID"
   GO TOP

   run_sql_query( "BEGIN" )
   IF !f18_lock_tables( { "roba" }, .T. )
      run_sql_query( "ROLLBACK" )
      RETURN .F.
   ENDIF

   Box(, 1, 60 )

   DO WHILE !Eof()

      cIdRoba := field->id

      select_o_roba( cIdRoba )

      IF !Found()
         APPEND BLANK
      ENDIF

      hRec := dbf_get_rec()

      hRec[ "id" ] := tops_roba->id

      hRec[ "naz" ] := tops_roba->naz
      hRec[ "jmj" ] := tops_roba->jmj
      hRec[ "idtarifa" ] := tops_roba->idtarifa
      hRec[ "barkod" ] := tops_roba->barkod
      hRec[ "tip" ] := tops_roba->tip
      hRec[ "mpc" ] := tops_roba->cijena1
      hRec[ "mpc2" ] := tops_roba->cijena2

      IF tops_roba->( FieldPos( "fisc_plu" ) ) <> 0
         hRec[ "fisc_plu" ] := tops_roba->fisc_plu
      ENDIF

      ++_cnt
      @ box_x_koord() + 1, box_y_koord() + 2 SAY "import roba: " + hRec[ "id" ] + ":" + PadR( hRec[ "naz" ], 20 ) + "..."
      lOk := update_rec_server_and_dbf( "roba", hRec, 1, "CONT" )

      IF !lOk
         EXIT
      ENDIF

      SELECT tops_roba
      SKIP

   ENDDO

   BoxC()

   IF lOk
      hParams := hb_Hash()
      hParams[ "unlock" ] := { "roba" }
      run_sql_query( "COMMIT", hParams )
   ELSE
      run_sql_query( "ROLLBACK" )
   ENDIF

   SELECT ( F_TMP_1 )
   USE

   IF lOk .AND. _cnt > 0
      MsgBeep( "Update " + AllTrim( Str( _cnt ) ) + " zapisa !" )
   ENDIF

   CLOSE ALL

   RETURN .T.
*/

/*

FUNCTION pos_brisi_nepostojece_dokumente()

   LOCAL cSql, oQry
   LOCAL cIdPos, cIdVd, cBrDok, dDatum
   LOCAL nCount := 0
   LOCAL oRow

   IF !spec_funkcije_sifra( "ADMIN" )
      MsgBeep( "Opcija nije dostupna !" )
      RETURN .F.
   ENDIF

   cSql := "SELECT p.idpos, p.idvd, p.datum, p.brdok "
   cSql += "FROM " + F18_PSQL_SCHEMA_DOT + "pos_pos p "
   cSql += "WHERE ( SELECT COUNT(*) FROM " + F18_PSQL_SCHEMA_DOT + "pos_doks d "
   cSql += "         WHERE d.idpos = p.idpos "
   cSql += "           AND d.idvd = p.idvd "
   cSql += "           AND d.datum = p.datum "
   cSql += "           AND d.brdok = p.brdok ) = 0 "
   cSql += "GROUP BY p.idpos, p.idvd, p.datum, p.brdok "
   cSql += "ORDER BY p.idpos, p.idvd, p.datum, p.brdok "

   MsgO( "SQL upit u toku, sačekajte trenutak ... " )
   oQry := run_sql_query( cSql )
   MsgC()

   IF !is_var_objekat_tpqquery( oQry )
      MsgBeep( "Problem sa SQL upitom !" )
      RETURN .F.
   ENDIF

   IF oQry:LastRec() > 0
      IF Pitanje(, "Izbrisati ukupno " + AllTrim( Str( oQry:LastRec() ) ) + " dokumenata (D/N) ?", "N" ) == "N"
         RETURN .F.
      ENDIF
   ENDIF

   //o_pos_doks()
   //o_pos_pos()

   oQry:GoTo( 1 )

   Box(, 1, 50 )

   DO WHILE !oQry:Eof()

      oRow := oQry:GetRow()

      dDatum := query_row( oRow, "datum" )
      cIdPos := query_row( oRow, "idpos" )
      cIdVd := query_row( oRow, "idvd" )
      cBrDok := query_row( oRow, "brdok" )

      @ box_x_koord() + 1, box_y_koord() + 2 SAY8 "Brišem dokument: " + cIdPos + "-" + cIdVd + "-" + cBrDok + " od datuma " + DToC( dDatum )

    --  IF !pos_brisi_dokument( cIdPos, cIdVd, dDatum, cBrDok )
         BoxC()
         MsgBeep( "Problem sa brisanjem dokumenta !" )
         RETURN .F.
      ENDIF

      ++nCount

      oQry:Skip()

   ENDDO

   BoxC()

   IF nCount > 0
      MsgBeep( "Izbrisao ukupno " + AllTrim( Str( nCount ) ) + " dokumenta !"  )
   ENDIF

   RETURN .T.

*/
