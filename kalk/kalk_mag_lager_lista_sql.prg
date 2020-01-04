/*
 * This file is part of the bring.out FMK, a free and open source
 * accounting software suite,
 * Copyright (c) 1996-2011 by bring.out doo Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including FMK specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_FMK.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */


#include "f18.ch"


FUNCTION kalk_mag_lager_lista_sql( hParams, lPocetnoStanje )

   LOCAL oDataSet
   LOCAL cQuery, cWhere
   LOCAL dDatOd, dDatDo, dDatPocStanje, cIdKontoMagacin
   LOCAL cFilterArtikli, cFilterDokumenti, cFilterTarife, cFilterPartneri
   LOCAL hServerParams := my_server_params()
   LOCAL cDatabaseTekuca := my_server_params()[ "database" ]
   LOCAL nYearPredhodna, nYearTekuca
   LOCAL cZaokruzenje := AllTrim( Str( gZaokr ) )

   IF hParams == NIL
      hParams := hb_Hash()
      IF !kalk_mag_lager_lista_vars( @hParams, lPocetnoStanje )
         RETURN NIL
      ENDIF
   ENDIF

   dDatOd := hParams[ "datum_od" ]
   dDatDo := hParams[ "datum_do" ]
   dDatPocStanje := hParams[ "datum_ps" ]
   cIdKontoMagacin := hParams[ "m_konto" ]
   nYearPredhodna := Year( dDatDo )
   nYearTekuca := Year( dDatPocStanje )


   cWhere := " WHERE "
   cWhere += _sql_date_parse( "k.datdok", dDatOd, dDatDo )
   cWhere += " AND " + _sql_cond_parse( "k.idfirma", self_organizacija_id() )
   cWhere += " AND " + _sql_cond_parse( "k.mkonto", cIdKontoMagacin )

   cQuery := " SELECT " + ;
      " k.idroba, " + ;
      " SUM( CASE " + ;
      "WHEN k.mu_i = '1' AND k.idvd NOT IN ('12', '22', '94') THEN k.kolicina ELSE 0 " + ;
      "END ) AS ulaz, " + ;
      "ROUND( SUM( CASE " + ;
      "WHEN k.mu_i = '1' AND k.idvd NOT IN ('12', '22', '94') THEN k.nc * k.kolicina ELSE 0 " + ;
      "END ), " + cZaokruzenje + " ) AS nvu, " + ;
      "ROUND( SUM( CASE " + ;
      "WHEN k.mu_i = '1' AND k.idvd NOT IN ('12', '22', '94') THEN r.vpc * k.kolicina ELSE 0 " + ;
      "END ), " + cZaokruzenje + " ) AS vpvu, " + ;
      "SUM( CASE " + ;
      "WHEN k.mu_i = '1' AND k.idvd IN ('12', '22', '94') THEN -k.kolicina " + ;
      "WHEN k.mu_i = '5' THEN k.kolicina ELSE 0 " + ;
      "END ) AS izlaz, " + ;
      "ROUND( SUM( CASE " + ;
      "WHEN k.mu_i = '1' AND k.idvd IN ('12', '22', '94') THEN -( k.nc * k.kolicina ) " + ;
      "WHEN k.mu_i = '5' THEN k.nc * k.kolicina ELSE 0 " + ;
      "END ), " + cZaokruzenje + " ) AS nvi, " + ;
      "ROUND( SUM( CASE " + ;
      "WHEN k.mu_i = '1' AND k.idvd IN ('12', '22', '94') THEN -( r.vpc * k.kolicina ) " + ;
      "WHEN k.mu_i = '5' THEN r.vpc * k.kolicina ELSE 0 " + ;
      "END ), " + cZaokruzenje + " ) AS vpvi " + ;
      " FROM " + F18_PSQL_SCHEMA_DOT + "kalk_kalk k " + ;
      " RIGHT JOIN " + F18_PSQL_SCHEMA_DOT + " roba r ON r.id = k.idroba "

   cQuery += cWhere

   cQuery += " GROUP BY k.idroba "
   cQuery += " ORDER BY k.idroba "

   stop_refresh_operations()

   IF lPocetnoStanje
      switch_to_database( hServerParams, cDatabaseTekuca, nYearPredhodna )
   ENDIF

   IF lPocetnoStanje
      MsgO( "početno stanje - sql query u toku..." )
   ELSE
      MsgO( "formiranje podataka u toku...." )
   ENDIF

   oDataSet := run_sql_query( cQuery )

   IF !is_var_objekat_tpqquery( oDataSet )
      oDataSet := NIL
   ELSE
      IF oDataSet:LastRec() == 0
         oDataSet := NIL
      ENDIF
   ENDIF

   MsgC()

   IF lPocetnoStanje
      switch_to_database( hServerParams, cDatabaseTekuca, nYearTekuca )
   ENDIF

   start_refresh_operations()
   RETURN oDataSet




FUNCTION kalk_mag_lager_lista_vars( hParams, lPocetnoStanje )

   LOCAL _ret := .T.
   LOCAL cIdKontoMagacin, dDatOd, dDatDo, _nule, _pr_nab, _roba_tip_tu, dDatPocStanje, _do_nab
   LOCAL nX := 1
   LOCAL cFilterArtikli := Space( 300 )
   LOCAL cFilterTarife := Space( 300 )
   LOCAL cFilterPartneri := Space( 300 )
   LOCAL cFilterDokumenti := Space( 300 )
   LOCAL cFilterBrFakt := Space( 300 )
   LOCAL _curr_user := my_user()
   LOCAL cMinimalneKolicineDN

   IF lPocetnoStanje == NIL
      lPocetnoStanje := .F.
   ENDIF

   cMinimalneKolicineDN := fetch_metric( "kalk_lager_lista_mag_minimalne_kolicine", _curr_user, "N" )
   _do_nab := fetch_metric( "kalk_lager_Lista_mag_prikaz_do_nabavne", _curr_user, "N" )
   cIdKontoMagacin := fetch_metric( "kalk_lager_lista_mag_id_konto", _curr_user, PadR( "1320", 7 ) )
   _pr_nab := fetch_metric( "kalk_lager_lista_mag_po_nabavnoj", _curr_user, "D" )
   _nule := fetch_metric( "kalk_lager_lista_mag_prikaz_nula", _curr_user, "N" )
   dDatOd := fetch_metric( "kalk_lager_lista_mag_datum_od", _curr_user, Date() -30 )
   dDatDo := fetch_metric( "kalk_lager_lista_mag_datum_do", _curr_user, Date() )
   dDatPocStanje := NIL
   _roba_tip_tu := "N"

   IF lPocetnoStanje
      dDatOd := CToD( "01.01." + AllTrim( Str( Year( Date() ) -1 ) ) )
      dDatDo := CToD( "31.12." + AllTrim( Str( Year( Date() ) -1 ) ) )
      dDatPocStanje := CToD( "01.01." + AllTrim( Str( Year( Date() ) ) ) )
   ENDIF

   Box( "# LAGER LISTA MAGACINA" + iif( lPocetnoStanje, " / POČETNO STANJE", "" ), 15, f18_max_cols() -5 )

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Firma "

   ?? self_organizacija_id(), "-", AllTrim( self_organizacija_naziv() )

   ++nX
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Magacinski konto:" GET cIdKontoMagacin VALID P_Konto( @cIdKontoMagacin )

   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Datum od:" GET dDatOd
   @ box_x_koord() + nX, Col() + 1 SAY "do:" GET dDatDo

   IF lPocetnoStanje
      @ box_x_koord() + nX, Col() + 1 SAY8 "Datum poč.stanja:" GET dDatPocStanje
   ENDIF

   ++nX
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Filter po artiklima:" GET cFilterArtikli PICT "@S50"
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Filter po tarifama:" GET cFilterTarife PICT "@S50"
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Filter po partnerima:" GET cFilterPartneri PICT "@S50"
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Filter po v.dokument:" GET cFilterDokumenti PICT "@S50"
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Filter po broju.fakt:" GET cFilterBrFakt PICT "@S50"

   ++nX
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Prikaz nabavne vrijednosti (D/N)" GET _pr_nab VALID _pr_nab $ "DN" PICT "@!"
   @ box_x_koord() + nX, Col() + 1 SAY "Prikaz stavki kojima je NV = 0 (D/N)" GET _nule VALID _nule $ "DN" PICT "@!"

   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Prikaz samo kritičnih zaliha (D/N)" GET cMinimalneKolicineDN VALID cMinimalneKolicineDN $ "DN" PICT "@!"

   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Prikaz robe tipa T/U (D/N)" GET _roba_tip_tu VALID _roba_tip_tu $ "DN" PICT "@!"

   READ

   BoxC()

   IF LastKey() == K_ESC
      RETURN .F.
   ENDIF

   set_metric( "kalk_lager_Lista_mag_prikaz_do_nabavne", _curr_user, _do_nab )
   set_metric( "kalk_lager_lista_mag_id_konto", _curr_user, cIdKontoMagacin )
   set_metric( "kalk_lager_lista_mag_po_nabavnoj", _curr_user, _pr_nab )
   set_metric( "kalk_lager_lista_mag_prikaz_nula", _curr_user, _nule )
   set_metric( "kalk_lager_lista_mag_datum_od", _curr_user, dDatOd )
   set_metric( "kalk_lager_lista_mag_datum_do", _curr_user, dDatDo )
   set_metric( "kalk_lager_lista_mag_minimalne_kolicine", _curr_user, cMinimalneKolicineDN )

   hParams[ "datum_od" ] := dDatOd
   hParams[ "datum_do" ] := dDatDo
   hParams[ "datum_ps" ] := dDatPocStanje
   hParams[ "m_konto" ] := cIdKontoMagacin
   hParams[ "nule" ] := _nule
   hParams[ "roba_tip_tu" ] := _roba_tip_tu
   hParams[ "pr_nab" ] := _pr_nab
   hParams[ "do_nab" ] := _do_nab
   hParams[ "min_kol" ] := cMinimalneKolicineDN
   hParams[ "filter_dok" ] := cFilterDokumenti
   hParams[ "filter_roba" ] := cFilterArtikli
   hParams[ "filter_partner" ] := cFilterPartneri
   hParams[ "filter_tarifa" ] := cFilterTarife
   hParams[ "filter_brfakt" ] := cFilterBrFakt

   RETURN _ret



FUNCTION kalk_pocetno_stanje_magacin()

   LOCAL hParams := NIL
   LOCAL oDataSet
   LOCAL nCount := 0

   stop_refresh_operations()
   oDataSet := kalk_mag_lager_lista_sql( @hParams, .T. )

   IF oDataSet == NIL
      start_refresh_operations()
      RETURN .F.
   ENDIF

   nCount := kalk_mag_insert_ps_into_pripr( oDataSet, hParams )

   IF nCount > 0
      renumeracija_kalk_pripr( nil, nil, .T. )
      my_close_all_dbf()
      kalk_azuriranje_dokumenta_auto_bez_stampe()
      MsgBeep( "Formiran dokument početnog stanja i automatski ažuriran !" )
   ENDIF

   start_refresh_operations()

   RETURN .T.



STATIC FUNCTION kalk_mag_insert_ps_into_pripr( oDataSet, hParams )

   LOCAL nCount := 0
   LOCAL cBrKalk := ""
   LOCAL cIdVd := "16"
   LOCAL dDatumKalk := hParams[ "datum_ps" ]
   LOCAL cIdKontoMagacin := hParams[ "m_konto" ]
   LOCAL _roba_tip_tu := hParams[ "roba_tip_tu" ]
   LOCAL oRow, _sufix
   LOCAL nUlaz, nIzlaz, nNvU, nNvI, cIdRoba, nVPVUlaz, nVPVIzlaz
   LOCAL _magacin_po_nabavnoj := .T.
   LOCAL hRec

   o_kalk_pripr()
   o_kalk_doks()
   o_koncij()
  // o_roba()
   o_tarifa()

   cBrKalk := kalk_get_next_broj_v5( self_organizacija_id(), cIdVd, cIdKontoMagacin )


   IF Empty( cBrKalk )
      cBrKalk := PadR( "00001", 8 )
   ENDIF

   select_o_koncij( cIdKontoMagacin )

   MsgO( "Punjenje pripreme podacima početnog stanja u toku, dok: " + cIdVd + "-" + AllTrim( cBrKalk ) )

   oDataSet:GoTo( 1 )

   DO WHILE !oDataSet:Eof()

      oRow := oDataSet:GetRow()

      cIdRoba := hb_UTF8ToStr( oRow:FieldGet( oRow:FieldPos( "idroba" ) ) )
      nUlaz := oRow:FieldGet( oRow:FieldPos( "ulaz" ) )
      nIzlaz := oRow:FieldGet( oRow:FieldPos( "izlaz" ) )
      nNvU := oRow:FieldGet( oRow:FieldPos( "nvu" ) )
      nNvI := oRow:FieldGet( oRow:FieldPos( "nvi" ) )
      nVPVUlaz := oRow:FieldGet( oRow:FieldPos( "vpvu" ) )
      nVPVIzlaz := oRow:FieldGet( oRow:FieldPos( "vpvi" ) )

      select_o_roba( cIdRoba )

      IF _roba_tip_tu == "N" .AND. roba->tip $ "TU"
         oDataSet:Skip()
         LOOP
      ENDIF

      IF Round( nUlaz - nIzlaz, 2 ) == 0
         oDataSet:Skip()
         LOOP
      ENDIF

      SELECT kalk_pripr
      APPEND BLANK

      hRec := dbf_get_rec()

      hRec[ "idfirma" ] := self_organizacija_id()
      hRec[ "idvd" ] := cIdVd
      hRec[ "brdok" ] := cBrKalk
      hRec[ "rbr" ] := ++nCount
      hRec[ "datdok" ] := dDatumKalk
      hRec[ "idroba" ] := cIdRoba
      hRec[ "idkonto" ] := cIdKontoMagacin
      hRec[ "mkonto" ] := cIdKontoMagacin
      hRec[ "idtarifa" ] := roba->idtarifa
      hRec[ "mu_i" ] := "1"
      hRec[ "brfaktp" ] := PadR( "PS", Len( hRec[ "brfaktp" ] ) )
      //hRec[ "datfaktp" ] := dDatumKalk
      hRec[ "kolicina" ] := ( nUlaz - nIzlaz )
      hRec[ "nc" ] := ( nNvU - nNvI ) / ( nUlaz - nIzlaz )
      hRec[ "vpc" ] := ( nVPVUlaz - nVPVIzlaz ) / ( nUlaz - nIzlaz )
      hRec[ "error" ] := "0"
      IF _magacin_po_nabavnoj
         hRec[ "vpc" ] := hRec[ "nc" ]
      ENDIF

      dbf_update_rec( hRec )

      oDataSet:Skip()

   ENDDO

   MsgC()

   RETURN nCount
