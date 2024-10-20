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


FUNCTION unos_datuma_isplate_place()

   LOCAL dDatPr
   LOCAL dDat1
   LOCAL dDat2
   LOCAL dDat3
   LOCAL dDat4
   LOCAL dDat5
   LOCAL dDat6
   LOCAL dDat7
   LOCAL dDat8
   LOCAL dDat9
   LOCAL dDat10
   LOCAL dDat11
   LOCAL dDat12
   LOCAL nMjPr
   LOCAL nMj1
   LOCAL nMj2
   LOCAL nMj3
   LOCAL nMj4
   LOCAL nMj5
   LOCAL nMj6
   LOCAL nMj7
   LOCAL nMj8
   LOCAL nMj9
   LOCAL nMj10
   LOCAL nMj11
   LOCAL nMj12
   LOCAL cIsZaPr
   LOCAL cIsZa1
   LOCAL cIsZa2
   LOCAL cIsZa3
   LOCAL cIsZa4
   LOCAL cIsZa5
   LOCAL cIsZa6
   LOCAL cIsZa7
   LOCAL cIsZa8
   LOCAL cIsZa9
   LOCAL cIsZa10
   LOCAL cIsZa11
   LOCAL cIsZa12
   LOCAL cVrIsPr
   LOCAL cVrIs1
   LOCAL cVrIs2
   LOCAL cVrIs3
   LOCAL cVrIs4
   LOCAL cVrIs5
   LOCAL cVrIs6
   LOCAL cVrIs7
   LOCAL cVrIs8
   LOCAL cVrIs9
   LOCAL cVrIs10
   LOCAL cVrIs11
   LOCAL cVrIs12

   LOCAL nGod := Year( Date() )
   LOCAL cObr := "1"
   LOCAL cRj := "  "
   LOCAL nX := 1
   LOCAL cOk := "D"
   LOCAL GetList := {}

   my_close_all_dbf()

   // o_ld_obracuni()
   // o_ld_rj()


   Box(, 20, 65 )

   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "*** Unos datuma isplata plata" COLOR f18_color_i()

   ++nX
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Tekuća godina:" GET nGod PICT "9999"

   @ box_x_koord() + nX, Col() + 2 SAY "Radna jedinica:" GET cRJ PICT "99" ;
      VALID Empty( cRJ ) .OR. P_LD_RJ( @cRJ )

   @ box_x_koord() + nX, Col() + 2 SAY8 "Obračun (1/2):" GET cObr VALID cObr $ "12"

   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "----------------------------------------"
   ++nX

   READ

   dDatPr := ld_get_datum_isplate_plate( cRj, nGod - 1, 12, cObr, @nMjPr, @cIsZaPr, ;
      @cVrIsPr )

   dDat1 := ld_get_datum_isplate_plate( cRj, nGod, 1, cObr, @nMj1, @cIsZa1, @cVrIs1 )
   dDat2 := ld_get_datum_isplate_plate( cRj, nGod, 2, cObr, @nMj2, @cIsZa2, @cVrIs2 )
   dDat3 := ld_get_datum_isplate_plate( cRj, nGod, 3, cObr, @nMj3, @cIsZa3, @cVrIs3 )
   dDat4 := ld_get_datum_isplate_plate( cRj, nGod, 4, cObr, @nMj4, @cIsZa4, @cVrIs4 )
   dDat5 := ld_get_datum_isplate_plate( cRj, nGod, 5, cObr, @nMj5, @cIsZa5, @cVrIs5 )
   dDat6 := ld_get_datum_isplate_plate( cRj, nGod, 6, cObr, @nMj6, @cIsZa6, @cVrIs6 )
   dDat7 := ld_get_datum_isplate_plate( cRj, nGod, 7, cObr, @nMj7, @cIsZa7, @cVrIs7 )
   dDat8 := ld_get_datum_isplate_plate( cRj, nGod, 8, cObr, @nMj8, @cIsZa8, @cVrIs8 )
   dDat9 := ld_get_datum_isplate_plate( cRj, nGod, 9, cObr, @nMj9, @cIsZa9, @cVrIs9 )
   dDat10 := ld_get_datum_isplate_plate( cRj, nGod, 10, cObr, @nMj10, @cIsZa10, @cVrIs10 )
   dDat11 := ld_get_datum_isplate_plate( cRj, nGod, 11, cObr, @nMj11, @cIsZa11, @cVrIs11 )
   dDat12 := ld_get_datum_isplate_plate( cRj, nGod, 12, cObr, @nMj12, @cIsZa12, @cVrIs12 )

   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "datum", 7 ) + ;
      PadL( "mj.ispl.", 18 ) + ;
      PadL( "isplata za", 18 ) + ;
      PadL( "vrsta ispl.", 18 )

   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "12." + AllTrim( Str( nGod - 1 ) ) + ;
      " => " GET dDatPr
   @ box_x_koord() + nX, Col() + 2 SAY "" GET nMjPr PICT "99"
   @ box_x_koord() + nX, Col() + 2 SAY "" GET cIsZaPr PICT "@S15"
   @ box_x_koord() + nX, Col() + 2 SAY "" GET cVrIsPr PICT "@S15"

   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "01." + AllTrim( Str( nGod ) ) + ;
      " => " GET dDat1
   @ box_x_koord() + nX, Col() + 2 SAY "" GET nMj1 PICT "99"
   @ box_x_koord() + nX, Col() + 2 SAY "" GET cIsZa1 PICT "@S15"
   @ box_x_koord() + nX, Col() + 2 SAY "" GET cVrIs1 PICT "@S15"

   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "02." + AllTrim( Str( nGod ) ) + ;
      " => " GET dDat2
   @ box_x_koord() + nX, Col() + 2 SAY "" GET nMj2 PICT "99"
   @ box_x_koord() + nX, Col() + 2 SAY "" GET cIsZa2 PICT "@S15"
   @ box_x_koord() + nX, Col() + 2 SAY "" GET cVrIs2 PICT "@S15"

   ++nX

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "03." + AllTrim( Str( nGod ) ) + ;
      " => " GET dDat3
   @ box_x_koord() + nX, Col() + 2 SAY "" GET nMj3 PICT "99"
   @ box_x_koord() + nX, Col() + 2 SAY "" GET cIsZa3 PICT "@S15"
   @ box_x_koord() + nX, Col() + 2 SAY "" GET cVrIs3 PICT "@S15"

   ++nX

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "04." + AllTrim( Str( nGod ) ) + ;
      " => " GET dDat4
   @ box_x_koord() + nX, Col() + 2 SAY "" GET nMj4 PICT "99"
   @ box_x_koord() + nX, Col() + 2 SAY "" GET cIsZa4 PICT "@S15"
   @ box_x_koord() + nX, Col() + 2 SAY "" GET cVrIs4 PICT "@S15"

   ++nX

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "05." + AllTrim( Str( nGod ) ) + ;
      " => " GET dDat5
   @ box_x_koord() + nX, Col() + 2 SAY "" GET nMj5 PICT "99"
   @ box_x_koord() + nX, Col() + 2 SAY "" GET cIsZa5 PICT "@S15"
   @ box_x_koord() + nX, Col() + 2 SAY "" GET cVrIs5 PICT "@S15"

   ++nX

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "06." + AllTrim( Str( nGod ) ) + ;
      " => " GET dDat6
   @ box_x_koord() + nX, Col() + 2 SAY "" GET nMj6 PICT "99"
   @ box_x_koord() + nX, Col() + 2 SAY "" GET cIsZa6 PICT "@S15"
   @ box_x_koord() + nX, Col() + 2 SAY "" GET cVrIs6 PICT "@S15"

   ++nX

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "07." + AllTrim( Str( nGod ) ) + ;
      " => " GET dDat7
   @ box_x_koord() + nX, Col() + 2 SAY "" GET nMj7 PICT "99"
   @ box_x_koord() + nX, Col() + 2 SAY "" GET cIsZa7 PICT "@S15"
   @ box_x_koord() + nX, Col() + 2 SAY "" GET cVrIs7 PICT "@S15"

   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "08." + AllTrim( Str( nGod ) ) + ;
      " => " GET dDat8
   @ box_x_koord() + nX, Col() + 2 SAY "" GET nMj8 PICT "99"
   @ box_x_koord() + nX, Col() + 2 SAY "" GET cIsZa8 PICT "@S15"
   @ box_x_koord() + nX, Col() + 2 SAY "" GET cVrIs8 PICT "@S15"

   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "09." + AllTrim( Str( nGod ) ) + ;
      " => " GET dDat9
   @ box_x_koord() + nX, Col() + 2 SAY "" GET nMj9 PICT "99"
   @ box_x_koord() + nX, Col() + 2 SAY "" GET cIsZa9 PICT "@S15"
   @ box_x_koord() + nX, Col() + 2 SAY "" GET cVrIs9 PICT "@S15"

   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "10." + AllTrim( Str( nGod ) ) + ;
      " => " GET dDat10
   @ box_x_koord() + nX, Col() + 2 SAY "" GET nMj10 PICT "99"
   @ box_x_koord() + nX, Col() + 2 SAY "" GET cIsZa10 PICT "@S15"
   @ box_x_koord() + nX, Col() + 2 SAY "" GET cVrIs10 PICT "@S15"

   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "11." + AllTrim( Str( nGod ) ) + ;
      " => " GET dDat11
   @ box_x_koord() + nX, Col() + 2 SAY "" GET nMj11 PICT "99"
   @ box_x_koord() + nX, Col() + 2 SAY "" GET cIsZa11 PICT "@S15"
   @ box_x_koord() + nX, Col() + 2 SAY "" GET cVrIs11 PICT "@S15"

   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "12." + AllTrim( Str( nGod ) ) + ;
      " => " GET dDat12
   @ box_x_koord() + nX, Col() + 2 SAY "" GET nMj12 PICT "99"
   @ box_x_koord() + nX, Col() + 2 SAY "" GET cIsZa12 PICT "@S15"
   @ box_x_koord() + nX, Col() + 2 SAY "" GET cVrIs12 PICT "@S15"


   ++nX
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Unos ispravan (D/N)" GET cOk ;
      VALID cOK $ "DN" ;
      PICT "@!"

   READ
   BoxC()

   IF LastKey() <> K_ESC

      IF cOk == "N"
         RETURN .F.
      ENDIF

      nGodina := nGod

      ld_obracun_set_datum_isplate( cRJ, nGodina - 1, 12, cObr, dDatPr, nMjPr, cIsZaPr, cVrIsPr )

      ld_obracun_set_datum_isplate( cRJ, nGodina, 1, cObr, dDat1, nMj1, cIsZa1, cVrIs1 )
      ld_obracun_set_datum_isplate( cRJ, nGodina, 2, cObr, dDat2, nMj2, cIsZa2, cVrIs2 )
      ld_obracun_set_datum_isplate( cRJ, nGodina, 3, cObr, dDat3, nMj3, cIsZa3, cVrIs3 )
      ld_obracun_set_datum_isplate( cRJ, nGodina, 4, cObr, dDat4, nMj4, cIsZa4, cVrIs4 )
      ld_obracun_set_datum_isplate( cRJ, nGodina, 5, cObr, dDat5, nMj5, cIsZa5, cVrIs5 )
      ld_obracun_set_datum_isplate( cRJ, nGodina, 6, cObr, dDat6, nMj6, cIsZa6, cVrIs6 )
      ld_obracun_set_datum_isplate( cRJ, nGodina, 7, cObr, dDat7, nMj7, cIsZa7, cVrIs7 )
      ld_obracun_set_datum_isplate( cRJ, nGodina, 8, cObr, dDat8, nMj8, cIsZa8, cVrIs8 )
      ld_obracun_set_datum_isplate( cRJ, nGodina, 9, cObr, dDat9, nMj9, cIsZa9, cVrIs9 )
      ld_obracun_set_datum_isplate( cRJ, nGodina, 10, cObr, dDat10, nMj10, cIsZa10, cVrIs10 )
      ld_obracun_set_datum_isplate( cRJ, nGodina, 11, cObr, dDat11, nMj11, cIsZa11, cVrIs11 )
      ld_obracun_set_datum_isplate( cRJ, nGodina, 12, cObr, dDat12, nMj12, cIsZa12, cVrIs12 )

   ENDIF

   my_close_all_dbf()

   RETURN .T.


FUNCTION ld_get_datum_isplate_plate( cRj, nGod, nMjesec, cObr, nMjIsp, cIsplZa, cVrsta )

   LOCAL dDate := CToD( "" )

   PushWa()

   nMjIsp := 0
   cIsplZa := Space( 50 )
   cVrsta := Space( 50 )

   o_ld_obracuni( cRJ + Str( nGod, 4, 0 ) + Str( nMjesec, 2, 0 ) + "G" + cObr )

   IF field->rj == cRj .AND. ;
         field->mjesec = nMjesec .AND. ;
         field->godina = nGod .AND. ;
         field->obr == cObr .AND. ;
         field->STATUS == "G"

      dDate := field->dat_ispl
      IF dDate < SToD( "10010101" ) // 1000-01-01
         dDate := CToD( "" )
      ENDIF
      nMjIsp := field->mj_ispl
      cIsplZa := field->ispl_za
      cVrsta := field->vr_ispl

   ELSE
      dDate := CToD( "" )
   ENDIF

   PopWa()

   RETURN dDate


STATIC FUNCTION ld_obracun_set_datum_isplate( cRj, nGod, nMjesec, cObr, dDatIspl, nMjIspl, cIsplZa, cVrsta )

   LOCAL hRec
   LOCAL _field_ids, _where_cond

   PushWA()

   o_ld_obracuni( cRJ + AllTrim( Str( nGod, 4, 0 ) ) + Str( nMjesec, 2, 0 ) + "G" + cObr )

   IF field->rj == cRj .AND. field->mjesec = nMjesec .AND. field->godina = nGod .AND. ;
         field->obr == cObr .AND. field->STATUS == "G"

      hRec := dbf_get_rec()
      hRec[ "dat_ispl" ] := dDatIspl
      hRec[ "mj_ispl" ] := nMjIspl
      hRec[ "ispl_za" ] := cIsplZa
      hRec[ "vr_ispl" ] := cVrsta
   ELSE

      APPEND BLANK
      hRec := dbf_get_rec()
      hRec[ "rj" ] := cRj
      hRec[ "godina" ] := nGod
      hRec[ "mjesec" ] := nMjesec
      hRec[ "obr" ] := cObr
      hRec[ "status" ] := "G"
      hRec[ "dat_ispl" ] := dDatIspl
      hRec[ "mj_ispl" ] := nMjIspl
      hRec[ "ispl_za" ] := cIsplZa
      hRec[ "vr_ispl" ] := cVrsta

   ENDIF

   update_rec_server_and_dbf( "ld_obracuni", hRec, 1, "FULL" )

   PopWa()

   RETURN .T.




FUNCTION ld_provjeri_dat_isplate_za_mjesec( cIdRj, nGodina, nMjesec, cObracun )

   LOCAL cQuery, oQuery, nCount

   cQuery := "SELECT count(*) FROM fmk.ld_obracuni where godina=" + sql_quote( nGodina) + " AND mjesec=" + sql_quote( nMjesec )


   IF cIdRj <> NIL .AND. !Empty( cIdRj )
      cQuery += " AND rj = " + sql_quote( cIdRj )
   ENDIF

   IF !Empty( cObracun )
         cQuery += " AND obr = " + sql_quote( cObracun )
   ENDIF

   oQuery := run_sql_query( cQuery )

   nCount := oQuery:FieldGet( 1 )

/*
   cQuery := "SELECT "
   cQuery += "  COUNT(*) "
   cQuery += "FROM " + F18_PSQL_SCHEMA_DOT + "ld_ld ld"
   cQuery += " LEFT JOIN "
   cQuery += F18_PSQL_SCHEMA_DOT + "ld_obracuni obr ON ld.godina = obr.godina AND ld.mjesec = obr.mjesec"

   // AND obr.status = 'G' "

   IF cIdRj <> NIL .AND. !Empty( cIdRj )
      cQuery += " AND obr.rj = " + sql_quote( cIdRj )
   ELSE
      cQuery += " AND ld.idrj = obr.rj"
   ENDIF


   cQuery += " WHERE "
   cQuery += " ld.godina = " + AllTrim( Str( nGodina ) )
   cQuery += " AND ld.mjesec = " + AllTrim( Str( nMjesec ) )
   //cQuery += " AND obr.dat_ispl IS NULL "
   cQuery += "  GROUP BY ld.godina, ld.mjesec, ld.idrj, obr.obr  "

   IF !Empty( cObracun )
         cQuery += " AND ld.obr = " + sql_quote( cObracun )
   ENDIF

   MsgBeep( cQuery )

   oQuery := run_sql_query( cQuery )

   nCount := oQuery:FieldGet( 1 )
*/

   RETURN nCount
