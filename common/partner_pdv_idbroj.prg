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

/*
   pozvati iz f18_init procedure
   1)  kreira partn.sifk polja PDVB, IDBR ako ne postoje
   2)  ako nisu postojali PDVB, IDBR onda puni za sve partnere ova polja na osnovu legacy REGB polja

*/

FUNCTION kreiraj_pa_napuni_partn_idbr_pdvb()

   LOCAL lDodano

   lDodano := fill_sifk_partn_idbr()
   lDodano := lDodano .AND. fill_sifk_partn_pdvb()

   IF lDodano
      RETURN fill_all_partneri_idbr_pdvb()
   ENDIF

   RETURN .F.


/*
   prodji kroz tabelu partnera i popuni IDBR, PDVB
*/

FUNCTION fill_all_partneri_idbr_pdvb()

   LOCAL nCnt := 0

   o_partner()

   ?E  "Podešavam identifikacijski i PDV broj za sve partnere  /",  partn->( RecCount() )

   DO WHILE !Eof()
      ++nCnt
      ?E "fill_all_partneri_idbr_pdvb",  nCnt
      update_idbr_pdvb_from_regb()
      SKIP
   ENDDO


   delete_sifk_partner_regb()

   RETURN .T.


/*
    partn.sifk PDVB, IDBR
*/

FUNCTION fill_sifk_partn_idbr()

   RETURN fill_sifk_partn( "IDBR", "IDENT br:", "07", 13 )


FUNCTION fill_sifk_partn_pdvb()

   RETURN fill_sifk_partn( "PDVB", "PDV br:", "08", 12 )


/*
   vidi #34188
   puni partn.sifk IDBR, PDVB na osnovu REGB polja
*/

FUNCTION update_idbr_pdvb_from_regb()

   LOCAL cPartnId, cRegB, cIdBr, cPdvBr

   PushWA()

   SELECT PARTN

   cPartnId := partn->id

   cRegB := get_partn_regb( cPartnId )
   cIdBr := get_partn_idbr( cPartnId )
   cPdvBr := get_partn_pdvb( cPartnId )


   IF !Empty( cIdBr ) .OR. !Empty( cPdvBr )
      RETURN .F.
   ENDIF

   SWITCH Len( cRegB )

   CASE 12

      USifK( "PARTN", "IDBR", cPartnID, "4" + cRegB )
      USifK( "PARTN", "PDVB", cPartnID, cRegB )
      EXIT

   CASE 13

      USifK( "PARTN", "IDBR", cPartnId, cRegB )
      USifK( "PARTN", "PDVB", cPartnId, "" )
      EXIT

   CASE 0

      // ne upisivati prazan string
      EXIT

   OTHERWISE

      USifK( "PARTN", "IDBR", cPartnId, cRegB )
      USifK( "PARTN", "PDVB", cPartnId, "" )

   ENDSWITCH

   PopWa()

   RETURN .T.


FUNCTION find_sifk_by_id_oznaka_naz_sort( cId, cOznaka, cNaz, cSort )

   LOCAL cSql := "select * from " + f18_sql_schema( "sifk" )

   cSql += " WHERE id=" + sql_quote( PadR( cId, FIELD_LEN_SIFK_ID ) )
   cSql += " AND oznaka=" + sql_quote( PadR( cOznaka, FIELD_LEN_SIFK_OZNAKA ) )
   cSql += " AND sort=" + sql_quote( cSort )
   cSql += " AND naz=" + sql_quote( PadR( cNaz, FIELD_LEN_SIFK_NAZ ) )

   SELECT F_SIFK
   IF !use_sql( "sifk", cSql )
      ?E "ERRRRRRRRR find_sifk_by_id_oznaka_naz_sort", cSql
   ENDIF

   RETURN !Eof()


/*
   fill_sifk_partn( "IDBR", "IDENT br:", "07", 13 )
*/

FUNCTION fill_sifk_partn( cIdSifk, cNazSifk, cSort, nLen )

   LOCAL lFound
   LOCAL cSeek
   LOCAL cNaz
   LOCAL cId
   LOCAL hRec


   IF !find_sifk_by_id_oznaka_naz_sort( "PARTN", cIdSifk, cNazSifk, cSort )

      o_sifk( "XXXX" )
      APPEND BLANK
      ?E "fill_sifk_partn - not fonud", cIdSifk, cNazSifk, cSort, nLen

      hRec := dbf_get_rec()
      hRec[ "id" ] := PadR( "PARTN", FIELD_LEN_SIFK_ID )
      hRec[ "naz" ] := PadR( cNazSifk, FIELD_LEN_SIFK_NAZ )
      hRec[ "oznaka" ] := cIdSifk
      hRec[ "sort" ] := cSort
      hRec[ "tip" ] := "C"
      hRec[ "duzina" ] := nLen
      hRec[ "veza" ] := "1"

      IF !update_rec_server_and_dbf( "sifk", hRec, 1, "FULL" )
         delete_with_rlock()
      ENDIF

      RETURN .T.
   ENDIF

   RETURN .F.



/*
   Opis: vraća id broj iz šifranika partnera na osnovu SIFK->REGB
        ukoliko je unešen PDV broj dužine 12, dodaje se "4" ispred

*/

FUNCTION firma_id_broj( cPartnerId )

   LOCAL cBroj

   cBroj := get_partn_idbr( cPartnerId )

   RETURN cBroj


/*
   Opis: vraća id broj unešen u šifarnik partnera kroz polje SIFK->REGB
         ukoliko je broj > 13 vraća se prazno
*/

FUNCTION firma_pdv_broj( cPartnerId )

   LOCAL cBroj

   cBroj := get_partn_pdvb( cPartnerId )

   RETURN cBroj


/*
   Opis: vraća karaketristiku REGB iz tabele SIFK za partnera
*/

FUNCTION get_partn_regb( cPartnerId )

   RETURN AllTrim( get_partn_sifk_sifv( "REGB", cPartnerId, .F. ) )


FUNCTION get_partn_pdvb( cPartnerId )

   RETURN AllTrim( get_partn_sifk_sifv( "PDVB", cPartnerId, .F. ) )


FUNCTION get_partn_idbr( cPartnerId )

   RETURN AllTrim( get_partn_sifk_sifv( "IDBR", cPartnerId, .F. ) )



FUNCTION delete_sifk_partner_regb()

   LOCAL cQuery

   cQuery := "DELETE FROM " + f18_sql_schema("sifk") + " WHERE oznaka='REGB'"

   RETURN run_sql_query( cQuery )
