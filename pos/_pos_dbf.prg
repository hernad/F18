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
   RETURN o_dbf_table( F_PRIPRZ, { "PRIPRZ", "pos_priprz" }, "1" )

FUNCTION o_pos__pripr()
   RETURN o_dbf_table( F__PRIPR, { "_POS_PRIPR", "_pos_pripr" }, "1" )


FUNCTION pos_init()

   my_close_all_dbf()
   pos_definisi_inicijalne_podatke()

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

   IF select_o_pos_osob( cId )
      RETURN .F.
   ENDIF

   hRec := dbf_get_rec()
   hRec[ "id" ] := PadR( cId, Len( hRec[ "id" ] ) )
   hRec[ "korsif" ] := PadR( CryptSc( PadR( cLozinka, 6 ) ), 6 )
   hRec[ "naz" ] := PadR( cOpis, Len( hRec[ "naz" ] ) )
   hRec[ "status" ] := PadR( cStatus, Len( hRec[ "status" ] ) )

   APPEND BLANK
   lOk := update_rec_server_and_dbf( "pos_osob", hRec, 1, "FULL" )

   RETURN lOk


STATIC FUNCTION pos_definisi_inicijalne_podatke()


   pos_dodaj_u_sifarnik_prioriteta( "0", "0", "Nivo adm." )
   pos_dodaj_u_sifarnik_prioriteta( "1", "1", "Nivo upr." )
   pos_dodaj_u_sifarnik_prioriteta( "3", "3", "Nivo prod." )
   pos_dodaj_u_sifarnik_radnika( "0001", "PARSON", "Admin", "0" )
   pos_dodaj_u_sifarnik_radnika( "0010", "P1", "Prodavac 1", "3" )
   pos_dodaj_u_sifarnik_radnika( "0011", "P2", "Prodavac 2", "3" )
   my_close_all_dbf()

   RETURN .T.


FUNCTION o_pos_tables( lOtvoriKumulativ )

   LOCAL lKumulativOtvoren := .F.
   my_close_all_dbf()

   IF lOtvoriKumulativ == NIL
      lOtvoriKumulativ := .T.
   ENDIF
   IF lOtvoriKumulativ
      lKumulativOtvoren := o_pos_kumulativne_tabele()
   ENDIF

   IF !lKumulativOtvoren
      RETURN .F.
   ENDIF
   
   o_pos_priprz()
   o_pos__pripr()
   IF lOtvoriKumulativ
      SELECT pos_doks
   ELSE
      SELECT _pos_pripr
   ENDIF

   RETURN .T.


FUNCTION o_pos_kumulativne_tabele()

   o_pos_pos()
   RETURN o_pos_doks()

