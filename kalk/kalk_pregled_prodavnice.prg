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


FUNCTION kalk_izvjestaji_prod_zbir_menu()

   LOCAL aOpc := {}
   LOCAL aOpcExe := {}
   LOCAL nIzbor := 1

   AAdd( aOpc, "1. pregled prodavnice - A                 " )
   AAdd( aOpcExe, {|| kalk_pregled_prod_1() } )

   f18_menu( "zbp", .F., nIzbor, aOpc, aOpcExe )

   RETURN NIL


FUNCTION kalk_pregled_prod_1()

   LOCAL i
   LOCAL oReport, cSql, cSql2, cSqlMaster
   LOCAL cIdRoba := PadR( "", 10 )
   LOCAL cIdPartner := Space( 6 )
   LOCAL dDatOd := fetch_metric( "pregled_prod_d_od", my_user(), CToD( "01.01." + AllTrim( Str( Year( Date() ) ) ) ) )
   LOCAL dDatDo := fetch_metric( "pregled_prod_d_do", my_user(), Date() )
   LOCAL cVarijanta := fetch_metric( "pregled_prod_var", my_user(), "2" )

   LOCAL GetList := {}
   LOCAL hHeader, hHeader2
   LOCAL cProdavnice := fetch_metric( "pregled_prod", my_user(), "2,16" )
   LOCAL cNcDN := fetch_metric( "pregled_prod_nc", my_user(), "N" )
   LOCAL nI, nProdavnica, cProdavnica
   LOCAL hFooter

   cProdavnice := PadR( cProdavnice, 200 )

   Box(, 7, 60 )
   @ box_x_koord() + 1, box_y_koord() + 2  SAY "Datum od " GET dDatOd
   @ box_x_koord() + 1, Col() + 2 SAY "do" GET dDatDo
   @ box_x_koord() + 3, box_y_koord() + 2  SAY "Roba% : " GET cIdRoba
   @ box_x_koord() + 4, box_y_koord() + 2  SAY8 "Proračun nabavne cijene (DN) : " GET cNcDN PICT "@!" VALID cNcDN $ "DN"
   @ box_x_koord() + 4, col() + 2  SAY "Varijanta : " GET cVarijanta VALID cVarijanta $ "12"

   @ box_x_koord() + 6, box_y_koord() + 2  SAY "Prodavnice : " GET cProdavnice PICTURE "@S40"


   READ
   BoxC()

   IF LastKey() == K_ESC
      RETURN .F.
   ENDIF

   cProdavnice := AllTrim( cProdavnice )
   set_metric( "pregled_prod_d_od", my_user(), dDatOd )
   set_metric( "pregled_prod_d_do", my_user(), dDatDo )
   set_metric( "pregled_prod", my_user(), cProdavnice )
   set_metric( "pregled_prod_nc", my_user(), cNcDN )
   set_metric( "pregled_prod_var", my_user(), cVarijanta )

   nProdavnica := NumToken( cProdavnice, ',' )

   download_template( "kalk_pregled_prod_2.xlsx", "4588ede2a2c1178a1e0ff3e04278b810c2d72cb7f4b2cfdcd35d28e8a5beda88", .T. )
   download_template( "kalk_pregled_prod_1.xlsx", "1443c32d8b87e85ec1043c2041b5f79c5328c61f34a20d1305a01306dbea352c", .T. )

   oReport := YargReport():New( "kalk_pregled_prod_" + cVarijanta, "xlsx", NIL )

   oReport:aSql := {}
   oReport:cBands := "Header1#BandSql1#Footer1"

   hHeader := hb_Hash()
   hHeader[ "hvar1" ] := ""
   hHeader[ "dat_od" ] := DToC( dDatOd )
   hHeader[ "dat_do" ] := DToC( dDatDo )
   oReport:aHeader := { hHeader }

   hFooter := hb_Hash()
   hFooter[ "fvar1" ] := ""
   oReport:aFooter := { hFooter }

   cSqlMaster := "select roba.id id, roba.naz naz, roba.jmj jmj, roba.barkod barkod, tarifa.pdv pdv, roba.idtarifa idtarifa from roba "
   cSqlMaster += " LEFT JOIN tarifa on roba.idtarifa=tarifa.id"
   cSqlMaster += " WHERE roba.id in ("

   oReport:aSql := { NIL }

   FOR nI := 1 TO nProdavnica
      cProdavnica :=  "p" + Token( cProdavnice, ",", nI )
      cSql := "select idroba, pdv, sum(prijem) as prijem, sum(povrat) as povrat, sum(ulaz_ostalo) as ulaz_ostalo, sum(p_popust) p_popust, sum(popust) popust, sum(p_izlaz_ostalo) p_izlaz_ostalo, sum(izlaz_ostalo) izlaz_ostalo,"
      cSql += "sum(p_kalo + kalo) u_kalo, sum(p_prijem+p_ulaz_ostalo-p_povrat-p_realizacija-p_izlaz_ostalo) p_stanje, sum(p_realizacija) p_realizacija, sum(realizacija) realizacija,"
      cSql += "sum(p_realizacija_v) p_realizacija_v, sum(realizacija_v) realizacija_v,sum(p_popust_v) p_popust_v, sum(popust_v) popust_v, sum(p_vrijednost + vrijednost) u_vrijednost,"
      IF cNcDN == "D"
        cSql += "public.prodavnica_nc(" + Token( cProdavnice, ",", nI ) + ", idroba, " + sql_quote(dDatDo) + ") nc,"
      ELSE
        cSql += "0 nc,"
      ENDIF
      cSql += cProdavnica + ".pos_dostupna_osnovna_cijena_za_artikal( idroba ) osnovna_cijena, roba.naz roba_naz, roba.jmj  "
      cSql += " FROM " + cProdavnica + ".pos_artikal_stanje( " + sql_quote( cIdRoba ) + ", " + sql_quote( dDatOd ) + ", " + sql_quote( dDatDo ) + " ) pstanje"
      cSql += " LEFT JOIN roba on pstanje.idroba = roba.id"
      cSql += " LEFT JOIN tarifa on roba.idtarifa = tarifa.id"
      cSql += " group by idroba, roba.naz, roba.jmj, tarifa.pdv"
      AAdd( oReport:aSql, cSql )

      cSqlMaster += "(select idroba from " + cProdavnica + ".pos_items"
      cSqlMaster += " group by " + cProdavnica + ".pos_items.idroba having count(pos_items.idroba) > 0)"
      IF nI < nProdavnica
         cSqlMaster += " union "
      ENDIF

      oReport:cBands += " Header" + AllTrim( Str( nI + 1 ) ) + "#BandSql" + AllTrim( Str( nI + 1 ) ) + + "#Footer" + AllTrim( Str( nI + 1 ) )

      hHeader := hb_Hash()
      hHeader[ "dat_od" ] := DToC( dDatOd )
      hHeader[ "dat_do" ] := DToC( dDatDo )
      hHeader[ "prod" ] := Upper( cProdavnica )
      AAdd( oReport:aHeader, hHeader )

      hFooter := hb_Hash()
      hFooter[ "sign" ] := "bring.out"
      AAdd( oReport:aFooter, hFooter )
   NEXT

   cSqlMaster += ")"
   cSqlMaster += " ORDER by roba.id"


   //Alert("Prodavnice :" + Alltrim(Str(nProdavnica)) + ": " + oReport:cBands )


   oReport:aSql[ 1 ] := cSqlMaster
   oReport:run()

   RETURN .T.
