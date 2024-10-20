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


FUNCTION kalk_prod_lager_lista_sql( hParams, lPocetnoStanje )

   LOCAL oDataSet
   LOCAL cQuery, _where
   LOCAL _dat_od, _dat_do, _dat_ps, cPKonto
   LOCAL _art_filter, _dok_filter, _tar_filter, _part_filter
   LOCAL hServerParams := my_server_params()
   LOCAL cTekucaBaza := my_server_params()[ "database" ]
   LOCAL nYearPredhodna, nYearTekuca

   IF hParams == NIL
      hParams := hb_Hash()
      IF !kalk_prod_lager_lista_vars( @hParams, lPocetnoStanje )
         RETURN NIL
      ENDIF
   ENDIF

   _dat_od := hParams[ "datum_od" ]
   _dat_do := hParams[ "datum_do" ]
   _dat_ps := hParams[ "datum_ps" ]
   cPKonto := hParams[ "p_konto" ]
   nYearPredhodna := Year( _dat_do )
   nYearTekuca := Year( _dat_ps )


   _where := " WHERE "
   _where += _sql_date_parse( "k.datdok", _dat_od, _dat_do )
   _where += " AND " + _sql_cond_parse( "k.idfirma", self_organizacija_id() )
   _where += " AND " + _sql_cond_parse( "k.pkonto", cPKonto )

   cQuery := " SELECT " + ;
      " k.idroba, k.idtarifa, " + ;
      " SUM( CASE " + ;
      "WHEN k.pu_i = '1' THEN k.kolicina " + ;
      "WHEN k.pu_i = '5' AND k.idvd IN ('12', '13') THEN -k.kolicina " + ;
      "END ) AS ulaz, " + ;
      " SUM( CASE " + ;
      "WHEN k.pu_i = '1' THEN k.kolicina * k.nc " + ;
      "WHEN k.pu_i = '5' AND k.idvd IN ('12', '13') THEN -( k.kolicina * k.nc ) " + ;
      "END ) AS nvu, " + ;
      " SUM( CASE " + ;
      "WHEN k.pu_i = '3' THEN k.kolicina * k.mpcsapp " + ;
      "WHEN k.pu_i = '1' THEN k.kolicina * k.mpcsapp " + ;
      "WHEN k.pu_i = '5' AND k.idvd IN ('12', '13') THEN -( k.kolicina * k.mpcsapp ) " + ;
      "END ) AS mpvu, " + ;
      " SUM( CASE " + ;
      "WHEN k.pu_i = '5' AND k.idvd NOT IN ('12', '13') THEN k.kolicina " + ;
      "WHEN k.pu_i = 'I' THEN k.gkolicin2 " + ;
      "END ) AS izlaz, " + ;
      " SUM( CASE " + ;
      "WHEN k.pu_i = '5' AND k.idvd NOT IN ('12', '13') THEN k.kolicina * k.nc " + ;
      "WHEN k.pu_i = 'I' THEN k.gkolicin2 * k.nc " + ;
      "END ) AS nvi, " + ;
      " SUM( CASE " + ;
      "WHEN k.pu_i = '5' AND k.idvd NOT IN ('12', '13') THEN k.kolicina * k.mpcsapp " + ;
      "WHEN k.pu_i = 'I' THEN k.gkolicin2 * k.mpcsapp " + ;
      "END ) AS mpvi " + ;
      " FROM " + f18_sql_schema("kalk_kalk") + " k "

   cQuery += _where

   cQuery += " GROUP BY k.idroba, k.idtarifa "
   cQuery += " ORDER BY k.idroba, k.idtarifa "

   IF lPocetnoStanje
      switch_to_database( hServerParams, cTekucaBaza, nYearPredhodna )
      MsgO( "Preuzimanje podataka " + AllTrim(Str( nYearPredhodna)))
   ENDIF

   IF lPocetnoStanje
      MsgO( "pocetno stanje - sql query u toku..." )
   ELSE
      MsgO( "formiranje podataka u toku..." )
   ENDIF

   oDataSet := run_sql_query( cQuery )
   IF lPocetnoStanje
      MsgC()
   ENDIF

   IF !is_var_objekat_tpqquery( oDataSet )
      oDataSet := NIL
   ELSE
      IF oDataSet:LastRec() == 0
         oDataSet := NIL
      ENDIF
   ENDIF

   MsgC()

   IF lPocetnoStanje
      switch_to_database( hServerParams, cTekucaBaza, nYearTekuca )
   ENDIF

   RETURN oDataSet




FUNCTION kalk_prod_lager_lista_vars( hParams, lPocetnoStanje )

   LOCAL _ret := .T.
   LOCAL cPKonto, _dat_od, _dat_do, _nule, _pr_nab, cRobaTipUslugeDN, _dat_ps
   LOCAL nX := 1
   LOCAL _art_filter := Space( 300 )
   LOCAL _tar_filter := Space( 300 )
   LOCAL _part_filter := Space( 300 )
   LOCAL _dok_filter := Space( 300 )
   LOCAL _curr_user := my_user()
   LOCAL _set_roba := "N"
   LOCAL GetList := {}

   IF lPocetnoStanje == NIL
      lPocetnoStanje := .F.
   ENDIF

   cPKonto := fetch_metric( "kalk_lager_lista_prod_id_konto", _curr_user, PadR( "1330", 7 ) )
   _pr_nab := fetch_metric( "kalk_lager_lista_prod_po_nabavnoj", _curr_user, "D" )
   _nule := fetch_metric( "kalk_lager_lista_prod_prikaz_nula", _curr_user, "N" )
   _dat_od := fetch_metric( "kalk_lager_lista_prod_datum_od", _curr_user, Date() -30 )
   _dat_do := fetch_metric( "kalk_lager_lista_prod_datum_do", _curr_user, Date() )
   _dat_ps := NIL
   cRobaTipUslugeDN := "N"

   IF lPocetnoStanje
      _dat_od := CToD( "01.01." + AllTrim( Str( Year( Date() ) -1 ) ) )
      _dat_do := CToD( "31.12." + AllTrim( Str( Year( Date() ) -1 ) ) )
      _dat_ps := CToD( "01.01." + AllTrim( Str( Year( Date() ) ) ) )
   ENDIF

   Box( "# LAGER LISTA PRODAVNICE" + if( lPocetnoStanje, " / POČETNO STANJE", "" ), 15, f18_max_cols() -5 )

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Firma "

   ?? self_organizacija_id(), "-", AllTrim( self_organizacija_naziv() )

   ++nX
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Prodavnički konto:" GET cPKonto VALID P_Konto( @cPKonto )

   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Datum od:" GET _dat_od
   @ box_x_koord() + nX, Col() + 1 SAY "do:" GET _dat_do

   IF lPocetnoStanje
      @ box_x_koord() + nX, Col() + 1 SAY8 "Datum poč.stanja:" GET _dat_ps
   ENDIF

   ++nX
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Filter po artiklima:" GET _art_filter PICT "@S50"
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Filter po tarifama:" GET _tar_filter PICT "@S50"
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Filter po partnerima:" GET _part_filter PICT "@S50"
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Filter po v.dokument:" GET _dok_filter PICT "@S50"

   ++nX
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Prikaz nabavne vrijednosti (D/N)" GET _pr_nab VALID _pr_nab $ "DN" PICT "@!"
   @ box_x_koord() + nX, Col() + 1 SAY "Prikaz stavki kojima je MPV=0 (D/N)" GET _nule VALID _nule $ "DN" PICT "@!"

   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Prikaz robe tipa T/U (D/N)" GET cRobaTipUslugeDN VALID cRobaTipUslugeDN $ "DN" PICT "@!"

   IF lPocetnoStanje
      @ box_x_koord() + nX, Col() + 1 SAY8 "MPC uzmi iz šifarnika (D/N) ?" GET _set_roba VALID _set_roba $ "DN" PICT "@!"
   ENDIF

   READ

   BoxC()

   IF LastKey() == K_ESC
      RETURN .F.
   ENDIF

   set_metric( "kalk_lager_lista_prod_id_konto", _curr_user, cPKonto )
   set_metric( "kalk_lager_lista_prod_po_nabavnoj", _curr_user, _pr_nab )
   set_metric( "kalk_lager_lista_prod_prikaz_nula", _curr_user, _nule )
   set_metric( "kalk_lager_lista_prod_datum_od", _curr_user, _dat_od )
   set_metric( "kalk_lager_lista_prod_datum_do", _curr_user, _dat_do )

   hParams[ "datum_od" ] := _dat_od
   hParams[ "datum_do" ] := _dat_do
   hParams[ "datum_ps" ] := _dat_ps
   hParams[ "p_konto" ] := cPKonto
   hParams[ "nule" ] := _nule
   hParams[ "roba_tip_tu" ] := cRobaTipUslugeDN
   hParams[ "pr_nab" ] := _pr_nab
   hParams[ "filter_dok" ] := _dok_filter
   hParams[ "filter_roba" ] := _art_filter
   hParams[ "filter_partner" ] := _part_filter
   hParams[ "filter_tarifa" ] := _tar_filter
   hParams[ "set_mpc" ] := ( _set_roba == "D" )

   RETURN _ret



FUNCTION kalk_pocetno_stanje_prodavnica()

   LOCAL hParams := NIL
   LOCAL oDataSet
   LOCAL nCount := 0

   oDataSet := kalk_prod_lager_lista_sql( @hParams, .T. )

   IF oDataSet == NIL
      RETURN .F.
   ENDIF

   nCount := kalk_prod_insert_ps_into_pripr( oDataSet, hParams )

   IF nCount > 0
      renumeracija_kalk_pripr( nil, nil, .T. )
      my_close_all_dbf()
      kalk_azuriranje_dokumenta_auto_bez_stampe()
      MsgBeep( "Formiran dokument početnog stanja i automatski ažuriran !" )
   ELSE
      MsgBeep( "Nema prenesenih stavki?!" )
   ENDIF

   RETURN .T.


STATIC FUNCTION kalk_prod_insert_ps_into_pripr( oDataset, hParams )

   LOCAL nCount := 0
   LOCAL cKalkBrDok := ""
   LOCAL cIdVd := "01"
   LOCAL _kalk_datum := hParams[ "datum_ps" ]
   LOCAL cPKonto := hParams[ "p_konto" ]
   LOCAL cRobaTipUslugeDN := hParams[ "roba_tip_tu" ]
   LOCAL oRow, _sufix
   LOCAL nUlaz, nIzlaz, nNVUlaz, nNVIzlaz, nMpvUlaz, nMpvIzlaz, cIdRoba, cIdTarifa
   LOCAL hRec

   o_kalk_pripr()
   o_kalk_doks()

   cKalkBrDok := kalk_get_next_broj_v5( self_organizacija_id(), cIdVd, cPKonto )

   IF Empty( cKalkBrDok )
      cKalkBrDok := PadR( "00001", 8 )
   ENDIF

   select_o_koncij( cPKonto )

   MsgO( "Punjenje pripreme podacima početnog stanja u toku, dok: " + cIdVd + "-" + AllTrim( cKalkBrDok ) )

   oDataset:GoTo( 1 )

   DO WHILE !oDataset:Eof()

      oRow := oDataset:GetRow()
      cIdRoba := hb_UTF8ToStr( oRow:FieldGet( oRow:FieldPos( "idroba" ) ) )
      cIdTarifa := oRow:FieldGet( oRow:FieldPos( "idtarifa" ) )
      nUlaz := oRow:FieldGet( oRow:FieldPos( "ulaz" ) )
      nIzlaz := oRow:FieldGet( oRow:FieldPos( "izlaz" ) )
      nNVUlaz := oRow:FieldGet( oRow:FieldPos( "nvu" ) )
      nNVIzlaz := oRow:FieldGet( oRow:FieldPos( "nvi" ) )
      nMpvUlaz := oRow:FieldGet( oRow:FieldPos( "mpvu" ) )
      nMpvIzlaz := oRow:FieldGet( oRow:FieldPos( "mpvi" ) )

      select_o_roba( cIdRoba )
      IF cRobaTipUslugeDN == "N" .AND. roba->tip $ "TU"
         oDataset:Skip()
         LOOP
      ENDIF

      IF Round( nUlaz - nIzlaz, 2 ) == 0
         oDataset:Skip()
         LOOP
      ENDIF

      SELECT kalk_pripr
      APPEND BLANK

      hRec := dbf_get_rec()
      hRec[ "idfirma" ] := self_organizacija_id()
      hRec[ "idvd" ] := cIdVd
      hRec[ "brdok" ] := cKalkBrDok
      hRec[ "rbr" ] := ++nCount
      hRec[ "datdok" ] := _kalk_datum
      hRec[ "idroba" ] := cIdRoba
      hRec[ "idkonto" ] := cPKonto
      hRec[ "pkonto" ] := cPKonto
      hRec[ "idtarifa" ] := cIdTarifa
      hRec[ "tcardaz" ] := "%"
      hRec[ "pu_i" ] := "1"
      hRec[ "brfaktp" ] := PadR( "POCST", Len( hRec[ "brfaktp" ] ) )
      hRec[ "tmarza2" ] := "A"
      hRec[ "kolicina" ] := ( nUlaz - nIzlaz )
      hRec[ "nc" ] := ( nNVUlaz - nNVIzlaz ) / ( nUlaz - nIzlaz )
      hRec[ "fcj" ] := hRec[ "nc" ]
      hRec[ "vpc" ] := hRec[ "nc" ]
      hRec[ "error" ] := "0"
      hRec[ "mpcsapp" ] := Round( ( nMpvUlaz - nMpvIzlaz ) / ( nUlaz - nIzlaz ), 2 )
      IF hParams[ "set_mpc" ]
         hRec[ "mpcsapp" ] := kalk_get_mpc_by_koncij_pravilo()
      ENDIF
      IF hRec[ "mpcsapp" ] <> 0
         hRec[ "mpc" ] := mpc_bez_pdv_by_tarifa( hRec["idtarifa"], hRec[ "mpcsapp" ] )
         hRec[ "marza2" ] := hRec[ "mpc" ] - hRec[ "nc" ]
      ENDIF

      dbf_update_rec( hRec )
      oDataset:Skip()

   ENDDO

   MsgC()

   RETURN nCount
