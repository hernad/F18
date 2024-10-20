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


//STATIC __table_os
//STATIC __table_promj
//STATIC __table_os_alias
//STATIC __table_promj_alias


FUNCTION os_generacija_pocetnog_stanja()

   LOCAL aInformacije := {}
   LOCAL lOk
   LOCAL nX, nY
   //LOCAL _dat_ps := Date()
   LOCAL hDatabaseParams := my_server_params()
   LOCAL cTekucaDatabaseName := my_server_params()[ "database" ]
  // LOCAL _year_tek := Year( _dat_ps )
  // LOCAL _year_sez := _year_tek - 1

   ps_info()

//   IF AllTrim( Str( _year_sez ) ) $ cTekucaDatabaseName
//      // ne moze se raditi razdvajanje u 2012
//      MsgBeep( "Ne mogu vrsti prenos u sezonskim podacima..." )
//      RETURN lOk
//   ENDIF

   IF Pitanje(, "Generisati početno unutar baze " + cTekucaDatabaseName + " (D/N) ?", "N" ) == "N"
      RETURN .F.
   ENDIF


   IF !spec_funkcije_sifra( "OSGEN" )
      MsgBeep( "Opcija onemogucena !" )
      RETURN .F.
   ENDIF

   // setuj staticke varijable na koje se tabele odnosi, nakon ovoga su nam dostupne,__table_os, __table_promj
   //open_sii_tabele_init_static_vars()

   Box(, 10, 60 )

   @ nX := box_x_koord() + 1, nY := box_y_koord() + 2 SAY "... prenos pocetnog stanja u toku" COLOR f18_color_i()


   lOk := os_pocstanje_brisi_tekucu_godinu( @aInformacije )

   // prebaciti iz prethodne godine tabele os/promj
   IF lOk
      lOk := os_pocstanje_prebaci_stanje_iz_predhodne_godine( @aInformacije )
   ENDIF


   IF lOk
      lOk := os_pocstanje_dodati_amortizaciju_u_otpisanu_vrijednost( @aInformacije )
   ENDIF

   // pakuj tabele...
   //IF lOk
    //  _pakuj_tabelu( __table_os_alias, __table_os )
    //  _pakuj_tabelu( __table_promj_alias, __table_promj )
   //ENDIF

   IF lOk
      @ nX + 8, box_y_koord() + 2 SAY "... operacija uspjesna"
   ELSE
      @ nX + 8, box_y_koord() + 2 SAY "... operacija NEUSPJEŠNA !?"
   ENDIF

   @ nX + 9, box_y_koord() + 2 SAY "Pritisnite <ESC> za izlazak i pregled rezulatata."

   // cekam ESC
   WHILE Inkey( 0.1 ) != K_ESC
   END

   BoxC()

   my_close_all_dbf()

   IF Len( aInformacije ) > 0
      _rpt_info( aInformacije )
   ENDIF

   RETURN .T.



STATIC FUNCTION ps_info()

   LOCAL cMsg := "Ovom operacijom se vrši formiranje početnog stanja."

   cMsg += "##1. Pokrenuti u novoj sezoni "
   cMsg += "##2. brišu se podaci tekuće godine "
   cMsg += "##3. prebacuju se podaci#"
   cMsg += "   iz prethodne godine#  sa uračunatom amortizacijom"

   RETURN MsgBeep( cMsg )


/*
STATIC FUNCTION open_sii_tabele_init_static_vars()

   my_close_all_dbf()


   o_os_sii()
   o_os_sii_promj()


   select_o_os_or_sii()  // tabela OS_OS/SII_SII

   //__table_os := get_os_table_name()
   //__table_os_alias := Alias()

   // tabela OS_PROMJ/SII_PROMJ
  -- os_select_promj()
   //__table_promj := get_promj_table_name()
   //__table_promj_alias := Alias()

   my_close_all_dbf()

   RETURN .T.
*/

// ------------------------------------------------------
// pregled efekata prenosa pocetnog stanja
// ------------------------------------------------------
STATIC FUNCTION _rpt_info( aInformacije )

   LOCAL nI

   START PRINT CRET

   ?
   ? "Pregled efekata prenosa u novu godinu:"
   ? Replicate( "-", 70 )
   ? "Operacija                        Iznos       Ostalo"
   ? Replicate( "-", 70 )

   FOR nI := 1 TO Len( aInformacije )
      ? PadR( aInformacije[ nI, 1 ], 50 ), aInformacije[ nI, 2 ], PadR( aInformacije[ nI, 3 ], 30 )
   NEXT

   FF
   ENDPRINT

   RETURN .T.



STATIC FUNCTION os_pocstanje_brisi_tekucu_godinu( aInformacije )

   LOCAL lOk := .F.
   LOCAL _table, _table_promj
   LOCAL _count := 0
   LOCAL _count_promj := 0
   LOCAL nTrec
   LOCAL nX, nY
   LOCAL hParams
   LOCAL hRec


   my_close_all_dbf()

   o_os_sii()
   o_os_sii_promj()

   run_sql_query( "BEGIN" )
   //IF !f18_lock_tables( { __table_os, __table_promj } )
    //  run_sql_query( "ROLLBACK" )
    //  MsgBeep( "Problem sa lokovanjem tabela " + __table_os + ", " + __table_promj + " !!!#Prekidamo proceduru." )
    //  RETURN lOk
   //ENDIF


   select_o_os_or_sii()
   SET ORDER TO TAG "1"
   GO TOP

   @ nX := box_x_koord() + 2, nY := box_y_koord() + 2 SAY8 PadR( "1) Brisanje podataka tekuće godine ", 40, "." )

   DO WHILE !Eof()

      SKIP
      nTrec := RecNo()
      SKIP -1

      hRec := dbf_get_rec()
      delete_rec_server_and_dbf( Alias(), hRec, 1, "CONT" )

      ++ _count
      GO ( nTrec )

   ENDDO

   o_os_sii_promj()
   SET ORDER TO TAG "1"
   GO TOP

   DO WHILE !Eof()

      SKIP
      nTrec := RecNo()
      SKIP -1

      hRec := dbf_get_rec()

      delete_rec_server_and_dbf( Alias(), hRec, 1, "CONT" )

      ++ _count_promj

      GO ( nTrec )

   ENDDO


   hParams := hb_Hash()
   //hParams[ "unlock" ] :=  { __table_os, __table_promj }
   run_sql_query( "COMMIT", hParams )

   @ nX, nY + 55 SAY "OK"

   AAdd( aInformacije, { "1) izbrisano sredstava:", _count, ""  } )
   AAdd( aInformacije, { "2) izbrisano promjena:", _count_promj, ""  } )

   lOk := .T.

   my_close_all_dbf()

   RETURN lOk




STATIC FUNCTION os_pocstanje_prebaci_stanje_iz_predhodne_godine( aInformacije )

   LOCAL lOk := .F.
   LOCAL oDataOS, oDataPromj
   LOCAL cQueryOS, cQueryPromj, _where
   //LOCAL _dat_ps := Date()
   LOCAL hDatabaseParams := my_server_params()
   LOCAL cTekucaDatabaseName := my_server_params()[ "database" ]
   //LOCAL _year_tek := Year( _dat_ps )
   //LOCAL _year_sez := _year_tek - 1
   LOCAL nTekucaSezona := tekuca_sezona()
   LOCAL _table, _table_promj
   LOCAL nX, nY
   LOCAL hParams

   // query za OS/PROMJ
   cQueryOS := " SELECT * FROM " + F18_PSQL_SCHEMA_DOT + "" + os_sii_table_name()
   cQueryPromj := " SELECT * FROM " + F18_PSQL_SCHEMA_DOT + "" + promj_table_name()

   // 1) predji u sezonsko podrucje -1
   // PRIMJER: nalazimo se u bringout_2017 => nTekucaSezona = 2017
   // prebaciti se u sezonu 2016
   switch_to_database( hDatabaseParams, cTekucaDatabaseName, nTekucaSezona - 1 )


   @ nX := box_x_koord() + 3, nY := box_y_koord() + 2 SAY PadR( "2) vrsim sql upit ", 40, "." )


   oDataOS := run_sql_query( cQueryOS )
   oDataPromj := run_sql_query( cQueryPromj )

   @ nX, nY + 55 SAY "OK"

   // 3) povratak u tekucu sezonu 2017
   switch_to_database( hDatabaseParams, cTekucaDatabaseName, nTekucaSezona )

   IF sql_error_in_query ( oDataOS )
      MsgBeep( "SQL ERR OS" )
      RETURN .F.
   ENDIF

   // ubaci sada podatke u OS/PROMJ

   run_sql_query( "BEGIN" )

  // IF !f18_lock_tables( { __table_os, __table_promj } )
  //    run_sql_query( "ROLLBACK" )
  //    MsgBeep( "Problem sa lokovanjem tabela..." )
  //    RETURN lOk
  // ENDIF

   @ nX := box_x_koord() + 4, nY := box_y_koord() + 2 SAY PadR( "3) insert podataka u novoj sezoni ", 40, "." )

   os_insert_into_os_sii( oDataOS )
   os_insert_into_promj( oDataPromj )


   hParams := hb_Hash()
  // hParams[ "unlock" ] :=  { __table_os, __table_promj }
   run_sql_query( "COMMIT", hParams )

   @ nX, nY + 55 SAY "OK"

   AAdd( aInformacije, { "3) prebacio iz prethodne godine sredstva", oDataOS:LastRec(), "" } )
   AAdd( aInformacije, { "4) prebacio iz prethodne godine promjene", oDataPromj:LastRec(), "" } )

   lOk := .T.

   RETURN lOk



STATIC FUNCTION o_row_to_h_rec( oRow )

   LOCAL hRec := hb_Hash()
   LOCAL cFieldName
   LOCAL cFieldValue
   LOCAL nI

   FOR nI := 1 TO oRow:FCount()

      cFieldName := oRow:FieldName( nI )
      cFieldValue := oRow:FieldGet( nI )

      IF ValType( cFieldValue ) == "C"
         cFieldValue := hb_UTF8ToStr( cFieldValue )
      ENDIF

      hRec[ cFieldName ] := cFieldValue

   NEXT

   hb_HDel( hRec, "match_code" )

   RETURN hRec




STATIC FUNCTION os_insert_into_os_sii( oDataset )

   LOCAL nI
   LOCAL _table
   LOCAL oRow, hRec

   //my_close_all_dbf()
   o_os_sii()

   oDataset:GoTo( 1 )

   DO WHILE !oDataset:Eof()

      oRow := oDataset:GetRow()
      hRec := o_row_to_h_rec( oRow )

      hRec[ "naz" ] := PadR( hRec[ "naz" ], 30 )

      select_o_os_or_sii()
      APPEND BLANK

      update_rec_server_and_dbf( Alias(), hRec, 1, "CONT" )

      @ box_x_koord() + 5, box_y_koord() + 2 SAY "  " + os_sii_table_name() + "/ sredstvo: " + hRec[ "id" ]

      oDataset:Skip()

   ENDDO

   //my_close_all_dbf()

   RETURN .T.



STATIC FUNCTION os_insert_into_promj( oDataset )

   LOCAL nI
   LOCAL _table
   LOCAL oRow, hRec

   //my_close_all_dbf()
   o_os_sii_promj()

   oDataset:GoTo( 1 )

   DO WHILE !oDataset:Eof()

      oRow := oDataset:GetRow()
      hRec := o_row_to_h_rec( oRow )

      os_select_promj()
      APPEND BLANK
      update_rec_server_and_dbf( Alias(), hRec, 1, "CONT" )

      @ box_x_koord() + 5, box_y_koord() + 2 SAY promj_table_name() + "/ promjena za sredstvo: " + hRec[ "id" ]

      oDataset:Skip()

   ENDDO

   //my_close_all_dbf()

   RETURN .T.




STATIC FUNCTION os_pocstanje_dodati_amortizaciju_u_otpisanu_vrijednost( aInformacije )

   LOCAL nTrec
   LOCAL hRec, _r_br
   LOCAL cSredstvoId
   LOCAL _table
   LOCAL lOk := .F.
   LOCAL _table_promj
   LOCAL _data := {}
   LOCAL nI, _count, nOtpisCount
   LOCAL nX, nY
   LOCAL hParams

   // nalazim se u tekucoj godini, zelim "slijepiti" promjene i izbrisati
   // otpisana sredstva u protekloj godini

   //my_close_all_dbf()
   o_os_sii()
   o_os_sii_promj()

   select_o_os_or_sii()
   GO TOP

   run_sql_query( "BEGIN" )
   //IF !f18_lock_tables( { __table_os, __table_promj } )
    //  run_sql_query( "ROLLBACK" )
    //  MsgBeep( "Problem sa zaključavanjem OS tabela !" )
    //  RETURN lOk
   //ENDIF


   nOtpisCount := 0

   @ nX := box_x_koord() + 6, nY := box_y_koord() + 2 SAY PadR( "4) generacija podataka za novu sezonu ", 40, "." )

   DO WHILE !Eof()

      cSredstvoId := field->id
      _r_br := 0

      SKIP
      nTrec := RecNo()
      SKIP -1

      hRec := dbf_get_rec()

      hRec[ "nabvr" ] := hRec[ "nabvr" ] + hRec[ "revd" ]
      hRec[ "otpvr" ] := hRec[ "otpvr" ] + hRec[ "revp" ] + hRec[ "amp" ]
      hRec[ "datotp" ] := fix_dat_var( hRec[ "datotp" ] )

      // brisi sta je otpisano
      // ali samo osnovna sredstva, sitan inventar ostaje u bazi...
      IF !Empty( hRec[ "datotp" ] ) .AND. gOsSii == "O"

         AAdd( aInformacije, { "     sredstvo: " + hRec[ "id" ] + "-" + PadR( hRec[ "naz" ], 30 ), 0, "OTPIS" } )

         ++ nOtpisCount
         select_o_os_or_sii()
         delete_rec_server_and_dbf( Alias(), hRec, 1, "CONT" )

         GO nTrec
         LOOP

      ENDIF

      os_select_promj( cSredstvoId )
      //SET ORDER TO TAG "1"
      //GO TOP
      //SEEK cSredstvoId

      DO WHILE !Eof() .AND. field->id == cSredstvoId
         hRec[ "nabvr" ] += field->nabvr + field->revd
         hRec[ "otpvr" ] += field->otpvr + field->revp + field->amp
         SKIP
      ENDDO

      select_o_os_or_sii()

      hRec[ "amp" ] := 0
      hRec[ "amd" ] := 0
      hRec[ "revd" ] := 0
      hRec[ "revp" ] := 0

      update_rec_server_and_dbf( Alias(), hRec, 1, "CONT" )

      GO nTrec

   ENDDO

   @ nX, nY + 55 SAY "OK"

   AAdd( aInformacije, { "5) broj otpisanih sredstava u novoj godini", nOtpisCount, "" } )

   // pobrisi sve promjene:
   o_os_sii_promj()
   SET ORDER TO TAG "1"
   GO TOP

   @ nX := box_x_koord() + 7, nY := box_y_koord() + 2 SAY PadR( "5) brisem promjene u novoj sezoni ", 40, "." )

   DO WHILE !Eof()

      SKIP 1
      nTrec := RecNo()
      SKIP -1

      hRec := dbf_get_rec()
      delete_rec_server_and_dbf( Alias(),  hRec, 1, "CONT" )

      GO ( nTrec )

   ENDDO

   @ nX, nY + 55 SAY "OK"

   hParams := hb_Hash()
   //hParams[ "unlock" ] :=  { __table_os, __table_promj }
   run_sql_query( "COMMIT", hParams )

   //my_close_all_dbf()

   lOk := .T.

   RETURN lOk


/*
STATIC FUNCTION _pakuj_tabelu( alias, table )

   SELECT ( F_TMP_1 )
   USE

   my_use_temp( alias, my_home() + table + ".dbf", .F., .T. )

   PACK
   USE

   RETURN .T.
*/
