/*
 * This file is part of the bring.out knowhow ERP, a free and open source
 * Enterprise Resource Planning software suite,
 * Copyright (c) 1994-2018 by bring.out d.o.o Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including knowhow ERP specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_knowhow.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */

#include "f18.ch"

STATIC s_cId_taksa := "TAKGORI-M "


STATIC FUNCTION is_modul_pos()
   IF programski_modul() == "POS"
      RETURN .T.
   ELSE
      RETURN .F.
   ENDIF


FUNCTION valid_taksa_gorivo( cError, nGorivoKolicina, nTaksaKolicina )

   LOCAL lRet := .T.

   IF is_modul_pos()
      SELECT _pos_pripr
   ELSE
      SELECT fakt_pripr
   ENDIF

   IF RecCount() == 0
      RETURN lRet
   ENDIF

   PushWa()
   GO TOP

   nGorivoKolicina := 0
   nTaksaKolicina := 0

   DO WHILE !Eof()

      IF artikal_je_gorivo( field->idroba )
         nGorivoKolicina += field->kolicina
      ENDIF

      IF field->idroba == s_cId_taksa
         nTaksaKolicina += field->kolicina
      ENDIF

      SKIP

   ENDDO

   GO TOP

   PopWa()

   IF nGorivoKolicina <> nTaksaKolicina
      lRet := .F.
      cError := "Količina goriva na računu je " + AllTrim( Str( nGorivoKolicina ) ) + "#Dok je unesena taksa TAKGORI-M " + ;
               AllTrim( Str( nTaksaKolicina ) )
   ENDIF

   RETURN lRet



STATIC FUNCTION artikal_je_gorivo( cIdRoba )

   LOCAL lRet := .F.
   LOCAL cSql, oQuery

   cSql := "SELECT k1 FROM " + F18_PSQL_SCHEMA_DOT + "roba WHERE id = " + sql_quote( cIdRoba )
   oQuery := run_sql_query( cSql )

   IF query_row( oQuery, "k1" ) == "GORI"
      lRet := .T.
   ENDIF

   RETURN lRet




FUNCTION valid_dodaj_taksu_za_gorivo()

   LOCAL cError := ""
   LOCAL nGorivoKolicina := 0
   LOCAL nTaksaKolicina := 0
   LOCAL nDodajTakse := 0
   LOCAL lRet := .T.

   IF !valid_taksa_gorivo( @cError, @nGorivoKolicina, @nTaksaKolicina )

       MsgBeep( cError )

       nDodajTakse := nGorivoKolicina - nTaksaKolicina

       IF nDodajTakse > 0

          IF Pitanje(, "Unijeti stavku TAKGORI-M " + AllTrim( Str( nDodajTakse ), 12, 2 ) + " na gorivo (D/N) ?", "D" ) == "D"
             dodaj_taksu_za_gorivo( nDodajTakse )
          ENDIF

       ELSE
          error_dodaj_stavku_takse_goriva()
       ENDIF

       lRet := .F.

   ENDIF

   RETURN lRet



STATIC FUNCTION error_dodaj_stavku_takse_goriva()
   MsgBeep( "Pobrisati stavku TAKGORI-M iz pripreme pa ponoviti operciju ažuriranja !" )
   RETURN .T.



FUNCTION dodaj_taksu_za_gorivo( nKolicina )

   LOCAL nSelect := SELECT()
   LOCAL hRec, hPrviRec
   LOCAL lRet := .T.

   o_roba()
   HSEEK s_cId_taksa

   IF !FOUND()
      dodaj_sifru_takse_u_sifarnik_robe()
   ENDIF

   IF is_modul_pos()
      dodaj_taksu_za_gorivo_na_pos_racun( nKolicina )
   ELSE
      dodaj_taksu_za_gorivo_na_fakt_racun( nKolicina )
   ENDIF

   SELECT ( nSelect )

   RETURN lRet



STATIC FUNCTION dodaj_taksu_za_gorivo_na_pos_racun( nKolicina )

   LOCAL hRec, hPrviRec

   SELECT _pos_pripr

   GO TOP
   hPrviRec := dbf_get_rec()

   APPEND BLANK
   hRec := dbf_get_rec()

   hRec["idpos"] := hPrviRec["idpos"]
   hRec["idvd"] := hPrviRec["idvd"]
   hRec["brdok"] := hPrviRec["brdok"]
   hRec["datum"] := hPrviRec["datum"]
   hRec["sto"] := hPrviRec["sto"]
   hRec["idradnik"] := hPrviRec["idradnik"]
   hRec["idcijena"] := hPrviRec["idcijena"]
   hRec["prebacen"] := hPrviRec["prebacen"]
   hRec["mu_i"] := hPrviRec["mu_i"]

   hRec["idroba"] := s_cId_taksa
   hRec["kolicina"] := nKolicina
   hRec["cijena"] := roba->mpc
   hRec["idtarifa"] := roba->idtarifa
   hRec["robanaz"] := roba->naz
   hRec["jmj"] := roba->jmj

   dbf_update_rec( hRec )

   RETURN .T.



STATIC FUNCTION dodaj_taksu_za_gorivo_na_fakt_racun( nKolicina )

   MsgBeep( "Prema zakonu o naftnim derivatima potrebno je na svaki izdati litar goriva#dodati na račun i posebnu stavku TAKGORI-M za istu količinu !" )

   RETURN .T.



STATIC FUNCTION dodaj_sifru_takse_u_sifarnik_robe()

   LOCAL hRec
   LOCAL lOk := .T.
   LOCAL nNovi_plu := 0

   dodaj_sifru_takse_u_tarife()

   SELECT roba
   APPEND BLANK

   hRec := dbf_get_rec()

   hRec["id"] := s_cId_taksa
   hRec["fisc_plu"] := roba_max_fiskalni_plu() + 1
   hRec["naz"] := "TAKSA M NAFTNI DERIVATI"
   hRec["jmj"] := "KOM"
   hRec["idtarifa"] := PadR( "PDVM0", 6 )
   hRec["mpc"] := 0.01

   lOk := update_rec_server_and_dbf( "roba", hRec, 1, "FULL" )

   IF !lOk
      delete_with_rlock()
   ENDIF

   SELECT roba
   HSEEK s_cId_taksa

   RETURN lOk


STATIC FUNCTION dodaj_sifru_takse_u_tarife()

   LOCAL lOk := .T.
   LOCAL hRec
   LOCAL cTarifa := PADR( "PDVM0", 6 )

   IF table_count( F18_PSQL_SCHEMA_DOT + "tarifa", "id = " + sql_quote( cTarifa ) ) > 0
      RETURN lOk
   ENDIF

   o_tarifa()

   APPEND BLANK
   hRec := dbf_get_rec()
   hRec["id"] := cTarifa
   hRec["naz"] := "PDV 0 %"
   hRec["opp"] := 0
   hRec["ppp"] := 0
   hRec["zpp"] := 0
   hRec["vpp"] := 0
   hRec["mpp"] := 0
   hRec["dlruc"] := 0

   lOk := update_rec_server_and_dbf( "tarifa", hRec, 1, "FULL" )

   IF !lOk
      delete_with_rlock()
   ENDIF

   RETURN lOk
