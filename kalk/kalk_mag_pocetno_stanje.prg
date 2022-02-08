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

FUNCTION kalk_pocetno_stanje_magacin()

   LOCAL lPocetnoStanje := .T.
   LOCAL hParams := NIL
   LOCAL oDataSet
   LOCAL nCount := 0

   stop_refresh_operations()
   oDataSet := kalk_mag_lager_lista_sql( @hParams, lPocetnoStanje )

   IF oDataSet == NIL
      start_refresh_operations()
      RETURN .F.
   ENDIF

   altd()
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
   LOCAL cRobaTipTU := hParams[ "roba_tip_tu" ]
   LOCAL oRow, _sufix
   LOCAL nUlaz, nIzlaz, nNvU, nNvI, cIdRoba, nVPVUlaz, nVPVIzlaz
   LOCAL lMagacinPoNabavnoj := .T.
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

      IF cRobaTipTU == "N" .AND. roba->tip $ "TU"
         altd()
         oDataSet:Skip()
         LOOP
      ENDIF

      IF Round(nUlaz - nIzlaz, 4) == 0
         IF Round(nNvI - nNvU, 4) <> 0
            Alert( cIdRoba + " kolicina=0, NV<> 0. SKIP!")
         ENDIF
         oDataSet:Skip()
         LOOP
      ENDIF

      SELECT kalk_pripr
      APPEND BLANK

      hRec := dbf_get_rec()

      hRec[ "idfirma" ] := self_organizacija_id()
      hRec[ "idvd" ] := cIdVd
      hRec[ "brdok" ] := cBrKalk
      hRec[ "rbr" ] := Str( ++nCount, 3 )
      hRec[ "datdok" ] := dDatumKalk
      hRec[ "idroba" ] := cIdRoba
      hRec[ "idkonto" ] := cIdKontoMagacin
      hRec[ "mkonto" ] := cIdKontoMagacin
      hRec[ "idtarifa" ] := roba->idtarifa
      hRec[ "mu_i" ] := "1"
      hRec[ "brfaktp" ] := PadR( "PS", Len( hRec[ "brfaktp" ] ) )
      hRec[ "datfaktp" ] := dDatumKalk
      hRec[ "kolicina" ] := ( nUlaz - nIzlaz )
      hRec[ "nc" ] := ( nNvU - nNvI ) / ( nUlaz - nIzlaz )
      hRec[ "vpc" ] := ( nVPVUlaz - nVPVIzlaz ) / ( nUlaz - nIzlaz )
      hRec[ "error" ] := "0"

      IF lMagacinPoNabavnoj
         hRec[ "vpc" ] := hRec[ "nc" ]
      ENDIF
      dbf_update_rec( hRec )

      oDataSet:Skip()

   ENDDO

   MsgC()

   RETURN nCount