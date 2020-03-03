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

FIELD idfirma, idvd, brdok, rbr, idtarifa, mkonto, pkonto, idroba, mu_i, pu_i, datdok, idpartner
FIELD brfaktp

FUNCTION find_kalk_doks_by_tip_datum( cIdFirma, cIdVd, dDatOd, dDatDo )

   LOCAL hParams := hb_Hash()

   IF cIdFirma <> NIL
      hParams[ "idfirma" ] := cIdFirma
   ENDIF

   IF cIdVd <> NIL .AND. !( Empty( cIdVd ) )
      hParams[ "idvd" ] := cIdVd
   ENDIF

   IF dDatOd <> NIL .AND. !Empty( dDatOd )
      hParams[ "dat_od" ] := dDatOd
   ENDIF
   IF dDatDo <> NIL .AND. !Empty( dDatDo )
      hParams[ "dat_do" ] := dDatDo
   ENDIF

   hParams[ "order_by" ] := "idfirma, idvd, brdok, datdok" // ako ima vise brojeva dokumenata sortiraj po njima
   hParams[ "indeks" ] := .F. // ne trositi vrijeme na kreiranje indeksa

   use_sql_kalk_doks( hParams )
   GO TOP

   RETURN ! Eof()


FUNCTION find_kalk_doks_za_tip_sufix_zadnji_broj( cIdFirma, cIdVd, cBrDokSfx )

   LOCAL hParams := hb_Hash()
   LOCAL nLenSufiks := Len( cBrDokSfx )

   IF cIdFirma <> NIL
      hParams[ "idfirma" ] := cIdFirma
   ENDIF

   IF cIdVd <> NIL
      hParams[ "idvd" ] := cIdVd
   ENDIF
  
   hParams[ "brdok_sfx" ] := cBrDokSfx  // 000010/T => /T
   hParams[ "order_by" ] := "SUBSTR(brdok," + AllTrim( Str( 8 - nLenSufiks + 1 ) ) + "),LEFT(brdok," + AllTrim( Str( 8 -nLenSufiks ) ) + ")" // ako ima brojeva dokumenata sortiraj po sufixu
   hParams[ "indeks" ] := .F.
   hParams[ "desc" ] := .T.
   hParams[ "limit" ] := 1

   use_sql_kalk_doks( hParams )
   GO TOP

   RETURN ! Eof()


FUNCTION find_kalk_doks_za_tip( cIdFirma, cIdvd )

   RETURN find_kalk_doks_by_broj_dokumenta( cIdFirma, cIdvd, NIL )


FUNCTION find_kalk_doks_za_tip_zadnji_broj( cIdFirma, cIdvd )

   LOCAL hParams := hb_Hash()

   IF cIdFirma <> NIL
      hParams[ "idfirma" ] := cIdFirma
   ENDIF

   IF cIdVd <> NIL .AND. !( Empty( cIdVd ) )
      hParams[ "idvd" ] := cIdVd
   ENDIF

   hParams[ "order_by" ] := "idfirma,idvd,brdok"
   hParams[ "indeks" ] := .F.  // ne trositi vrijeme na kreiranje indeksa
   hParams[ "desc" ] := .T.
   hParams[ "limit" ] := 1
   hParams[ "where_ext" ] := " AND not (left(brdok,1)='G' OR brdok similar to '%(-|/)%')" // NOT: G00000001, 00020-BL, 00020/BL

   use_sql_kalk_doks( hParams )
   GO TOP

   RETURN ! Eof()

/*
--FUNCTION find_kalk_doks_by_broj_radnog_naloga( cIdFirma, cMKonto, cIdZaduz2, cIdVd )

   LOCAL hParams := hb_Hash()

   IF cIdFirma <> NIL
      hParams[ "idfirma" ] := cIdFirma
   ENDIF

   IF cMKonto <> NIL .AND. !( Empty( cMKonto ) )
      hParams[ "mkonto" ] := cMKonto
   ENDIF

   IF cIdVd <> NIL .AND. !( Empty( cIdVd ) )
      hParams[ "idvd" ] := cIdVd
   ENDIF

   hParams[ "indeks" ] := .F.  // ne trositi vrijeme na kreiranje indeksa
   use_sql_kalk_doks( hParams )
   GO TOP

   RETURN ! Eof()
*/


FUNCTION find_kalk_doks_by_broj_fakture( cIdVd, cBrFaktP, cMKonto )

   LOCAL hParams := hb_Hash()

   IF cIdVd <> NIL
      hParams[ "idvd" ] := cIdVd
   ENDIF
   IF cBrFaktP <> NIL
      hParams[ "broj_fakture" ] := cBrFaktP
   ENDIF
   IF cMKonto <> NIL
      hParams[ "mkonto" ] := cMKonto
   ENDIF

   hParams[ "order_by" ] := "brfaktp,idvd"
   hParams[ "indeks" ] := .F.  // ne trositi vrijeme na kreiranje indeksa

   use_sql_kalk_doks( hParams )
   GO TOP

   RETURN ! Eof()


FUNCTION find_kalk_doks_by_broj_dokumenta( cIdFirma, cIdvd, cBrDok )

   LOCAL hParams := hb_Hash()

   IF cIdFirma <> NIL
      hParams[ "idfirma" ] := cIdFirma
   ENDIF

   IF cIdVd <> NIL .AND. !( Empty( cIdVd ) )
      hParams[ "idvd" ] := cIdVd
   ENDIF

   IF cBrDok <> NIL
      hParams[ "brdok" ] := cBrDok
   ENDIF

   hParams[ "order_by" ] := "idfirma,idvd,brdok"
   hParams[ "indeks" ] := .F.  // ne trositi vrijeme na kreiranje indeksa

   use_sql_kalk_doks( hParams )
   GO TOP

   RETURN ! Eof()


/*
FUNCTION find_kalk_doks2_by_broj_dokumenta( cIdFirma, cIdvd, cBrDok )

   LOCAL hParams := hb_Hash()

   IF cIdFirma <> NIL
      hParams[ "idfirma" ] := cIdFirma
   ENDIF

   IF cIdVd <> NIL
      hParams[ "idvd" ] := cIdVd
   ENDIF

   IF cBrDok <> NIL
      hParams[ "brdok" ] := cBrDok
   ENDIF

   hParams[ "order_by" ] := "idfirma,idvd,brdok"
   hParams[ "indeks" ] := .F.

   use_sql_kalk_doks2( hParams )
   GO TOP

   RETURN ! Eof()
*/


FUNCTION find_kalk_za_period( xIdFirma, cIdVd, cIdPartner, cIdRoba, dDatOd, dDatDo, cOrderBy )

   LOCAL hParams := hb_Hash()

   IF xIdFirma != NIL
      IF ValType( xIdFirma ) == "C"
         hParams[ "idfirma" ] := xIdFirma
         hb_default( @cOrderBy, "idFirma,IdVD,BrDok,RBr" )
      ELSE
         hParams := hb_HClone( xIdFirma )
         use_sql_kalk( hParams )
         GO TOP
         RETURN !Eof()
      ENDIF
   ENDIF


   IF cIdVd != NIL
      hParams[ "idvd" ] := cIdVd
   ENDIF
   IF cIdPartner != NIL
      hParams[ "idpartner" ] := cIdPartner
   ENDIF
   IF cIdRoba != NIL
      hParams[ "idroba" ] := cIdRoba
   ENDIF
   IF dDatOd <> NIL
      hParams[ "dat_od" ] := dDatOd
   ENDIF
   IF dDatOd <> NIL
      hParams[ "dat_do" ] := dDatDo
   ENDIF
   hParams[ "order_by" ] := cOrderBy
   hParams[ "indeks" ] := .F.
   use_sql_kalk( hParams )
   GO TOP

   RETURN !Eof()


FUNCTION find_kalk_by_mkonto_idroba_idvd( cIdFirma, cIdVd, cIdKonto, cIdRoba, cOrderBy, lReport )

   LOCAL hParams := hb_Hash()

   hb_default( @cOrderBy, "idfirma,mkonto,idroba,datdok,mu_i,idvd" )

   IF "obradjeno" $ cOrderBy
      hParams[ "obradjeno" ] := .T.
   ENDIF

   hb_default( @lReport, .T. )

   IF cIdFirma != NIL
      hParams[ "idfirma" ] := cIdFirma
   ENDIF

   IF cIdVd != NIL .AND. !Empty( cIdVd )
      hParams[ "idvd" ] := cIdVd
   ENDIF

   IF cIdKonto != NIL
      hParams[ "mkonto" ] := cIdKonto
   ENDIF
   IF cIdRoba != NIL
      hParams[ "idroba" ] := cIdRoba
   ENDIF
   hParams[ "order_by" ] := cOrderBy

   IF lReport
      hParams[ "polja" ] := "rpt_magacin" // samo polja potrebna za magacin
   ENDIF

   hParams[ "indeks" ] := .F.
   use_sql_kalk( hParams )
   GO TOP

   RETURN !Eof()



FUNCTION find_kalk_by_mkonto_idroba( cIdFirma, cIdKonto, cIdRoba, cOrderBy, lReport, cAlias, cDistinct )

   LOCAL hParams := hb_Hash()

   hb_default( @cOrderBy, "idfirma,mkonto,idroba,datdok,mu_i,idvd" )
   hb_default( @lReport, .T. )
   hb_default( @cDistinct, "" )

   IF cIdFirma != NIL
      hParams[ "idfirma" ] := cIdFirma
   ENDIF
   IF cIdKonto != NIL
      hParams[ "mkonto" ] := cIdKonto
   ENDIF
   IF cIdRoba != NIL .AND. !Empty( cIdRoba )
      hParams[ "idroba" ] := cIdRoba
   ENDIF
   IF cAlias != NIL
      hParams[ "alias" ] := cAlias
   ENDIF
   hParams[ "order_by" ] := cOrderBy

   IF cDistinct != NIL
      hParams[ "distinct" ] := cDistinct
   ENDIF

   IF lReport
      hParams[ "polja" ] := "rpt_magacin" // samo polja potrebna za magacin
   ENDIF

   hParams[ "indeks" ] := .F.
   use_sql_kalk( hParams )
   GO TOP

   RETURN !Eof()



FUNCTION find_kalk_by_pkonto_idroba( cIdFirma, cIdKonto, cIdRoba )

   LOCAL hParams := hb_Hash()

   IF cIdFirma != NIL
      hParams[ "idfirma" ] := cIdFirma
   ENDIF
   IF cIdKonto != NIL
      hParams[ "pkonto" ] := cIdKonto
   ENDIF
   IF cIdRoba != NIL
      hParams[ "idroba" ] := cIdRoba
   ENDIF
   hParams[ "order_by" ] := "idfirma,pkonto,idroba,datdok,pu_i,idvd"

   use_sql_kalk( hParams )
   GO TOP

   RETURN !Eof()


FUNCTION find_kalk_by_pkonto_idroba_idvd( cIdFirma, cIdVd, cIdKonto, cIdRoba, cOrderBy )

   LOCAL hParams := hb_Hash()

   IF cIdFirma != NIL
      hParams[ "idfirma" ] := cIdFirma
   ENDIF
   IF cIdKonto != NIL
      hParams[ "pkonto" ] := cIdKonto
   ENDIF
   IF cIdRoba != NIL
      hParams[ "idroba" ] := cIdRoba
   ENDIF
   IF cIdVd != NIL .AND. !Empty( cIdVd )
      hParams[ "idvd" ] := cIdVd
   ENDIF

   IF cOrderBy != NIL
      hParams[ "order_by" ] := cOrderBy
   ELSE
      hParams[ "order_by" ] := "idfirma,pkonto,idroba,datdok,pu_i,idvd"
   ENDIF

   use_sql_kalk( hParams )
   GO TOP

   RETURN !Eof()


FUNCTION find_kalk_by_broj_dokumenta( cIdFirma, cIdvd, cBrDok, cAlias, nWa )

   LOCAL hParams := hb_Hash()

   IF cIdFirma <> NIL
      hParams[ "idfirma" ] := cIdFirma
   ENDIF

   IF cIdVd <> NIL
      hParams[ "idvd" ] := cIdVd
   ENDIF

   IF cBrDok <> NIL
      hParams[ "brdok" ] := cBrDok
   ENDIF

   IF cAlias <> NIL
      hParams[ "alias" ] := cAlias
   ENDIF
   IF nWa <> NIL
      hParams[ "wa" ] := nWA
   ENDIF

   hParams[ "order_by" ] := "idfirma,idvd,brdok"
   hParams[ "indeks" ] := .F.


   use_sql_kalk( hParams )
   GO TOP

   RETURN ! Eof()



FUNCTION use_kalk( hParams )
   RETURN use_sql_kalk( hParams )

FUNCTION use_kalk_doks( hParams )
   RETURN use_sql_kalk_doks( hParams )



FUNCTION kalk_otvori_kumulativ_kao_pripremu( cIdFirma, cIdVd, cBrDok )

   LOCAL hParams

   hParams := hb_Hash()

   IF cIdFirma != NIL .AND. cIdVd != NIL .AND. cBrDok != NIL
      hParams[ "idfirma" ] := cIdFirma
      hParams[ "idvd" ] := cIdVd
      hParams[ "brdok" ] := cBrDok
   ENDIF


   hParams[ "indeks" ] := .F.
   use_sql_kalk_doks( hParams )

   SELECT F_KALK_PRIPR
   hParams[ "alias" ] := "kalk_pripr"
   hParams[ "indeks" ] := .T.
   RETURN use_sql_kalk( hParams )



FUNCTION use_sql_kalk( hParams )

   LOCAL cTable := "KALK"
   LOCAL cWhere, cOrder
   LOCAL cSql
   LOCAL lReportMagacin := .F.
   LOCAL lReportProdavnica := .F.
   LOCAL lAlias := .F.
   LOCAL cDistinct := .F.

   default_if_nil( @hParams, hb_Hash() )

   IF hb_HHasKey( hParams, "polja" ) .AND. hParams[ "polja" ] == "rpt_magacin"
      lReportMagacin := .T.
   ENDIF
   IF hb_HHasKey( hParams, "polja" ) .AND. hParams[ "polja" ] == "rpt_prod"
      lReportProdavnica := .T.
   ENDIF

   IF hb_HHasKey( hParams, "distinct" )
      cDistinct := hParams[ "distinct" ]
   ENDIF

   cSql := "SELECT "
   IF !Empty( cDistinct )
      cSql += " DISTINCT ON (" + cDistinct + ") "
   ENDIF
   cSql += coalesce_char_zarez( "kalk_kalk.idfirma", 2 )
   cSql += coalesce_char_zarez( "kalk_kalk.idvd", 2 )
   cSql += coalesce_char_zarez( "kalk_kalk.brdok", 8 )
   cSql += coalesce_char_zarez( "idroba", 10 )
   cSql += "rbr,"
   cSql += "coalesce(kalk_kalk.datdok, TO_DATE('','yyyymmdd')) as datdok, "
   cSql += coalesce_char_zarez( "kalk_kalk.brfaktp", 10 )
   cSql += coalesce_char_zarez( "kalk_kalk.idpartner", 6 )
   cSql += coalesce_char_zarez( "idtarifa", 6 )
   cSql += coalesce_char_zarez( "kalk_kalk.mkonto", 7 )
   cSql += coalesce_char_zarez( "kalk_kalk.pkonto", 7 )
   cSql += coalesce_char_zarez( "idkonto", 7 )
   cSql += coalesce_char_zarez( "idkonto2", 7 )

   IF !( lReportMagacin  .OR. lReportProdavnica )

      cSql += coalesce_char_zarez( "trabat", 1 )
      cSql += coalesce_char_zarez( "tprevoz", 1 )
      cSql += coalesce_char_zarez( "tprevoz2", 1 )
      cSql += coalesce_char_zarez( "tbanktr", 1 )
      cSql += coalesce_char_zarez( "tspedtr", 1 )
      cSql += coalesce_char_zarez( "tcardaz", 1 )
      cSql += coalesce_char_zarez( "tzavtr", 1 )
      cSql += coalesce_char_zarez( "tmarza", 1 )
      cSql += coalesce_char_zarez( "tmarza2", 1 )
      cSql += coalesce_num_num_zarez( "rabat", 18, 8 )
      cSql += coalesce_num_num_zarez( "marza2", 18, 8 )
      cSql += coalesce_num_num_zarez( "prevoz", 18, 8 )
      cSql += coalesce_num_num_zarez( "prevoz2", 18, 8 )
      cSql += coalesce_num_num_zarez( "banktr", 18, 8 )
      cSql += coalesce_num_num_zarez( "cardaz", 18, 8 )
      cSql += coalesce_num_num_zarez( "spedtr", 18, 8 )
      cSql += coalesce_num_num_zarez( "zavtr", 18, 8 )
   ENDIF

   cSql += coalesce_num_num_zarez( "kolicina", 12, 3 )
   cSql += coalesce_num_num_zarez( "gkolicina", 12, 3  )
   cSql += coalesce_num_num_zarez( "gkolicin2", 12, 3  )

   cSql += coalesce_num_num_zarez( "fcj", 18, 8 )
   cSql += coalesce_num_num_zarez( "fcj2", 18, 8 )
   cSql += coalesce_num_num_zarez( "nc", 18, 8 )
   cSql += coalesce_num_num_zarez( "marza", 18, 8 )
   cSql += coalesce_num_num_zarez( "vpc", 18, 8 )

   IF !lReportProdavnica
      cSql += coalesce_num_num_zarez( "rabatv", 18, 8 )
   ENDIF

   IF !lReportMagacin
      cSql += coalesce_num_num_zarez( "mpc", 18, 8 )
      cSql += coalesce_num_num_zarez( "mpcsapp", 18, 8 )
   ENDIF

   cSql += coalesce_char_zarez( "mu_i", 1 )
   cSql += coalesce_char_zarez( "pu_i", 1 )

   IF hb_HHasKey( hParams, "obradjeno" )
      cSql += " kalk_doks.obradjeno as obradjeno, "
   ENDIF
   cSql += coalesce_char( "error", 1 )

   cSql += " FROM " + f18_sql_schema("kalk_kalk") + " "

   IF hb_HHasKey( hParams, "obradjeno" )
      // select kolicina, kalk_doks.obradjeno  from fmk.kalk_kalk
      // join fmk.kalk_doks on  kalk_doks.idfirma=kalk_kalk.idfirma and kalk_doks.idvd=kalk_kalk.idvd and kalk_doks.brdok=kalk_kalk.brdok
      // limit 1
      cSql += "JOIN " + f18_sql_schema("kalk_doks") + " ON kalk_doks.idfirma=kalk_kalk.idfirma and kalk_doks.idvd=kalk_kalk.idvd and kalk_doks.brdok=kalk_kalk.brdok "
   ENDIF

   cWhere := use_sql_kalk_where( hParams )
   cOrder := use_sql_kalk_order( hParams )

   IF !Empty( cWhere )
      cSql += " WHERE " + cWhere
      IF !Empty( cOrder )
         cSql += cOrder
      ENDIF
   ELSE
      cSql += " OFFSET 0 LIMIT 1"
   ENDIF

   IF hb_HHasKey( hParams, "alias" )
      cTable := hParams[ "alias" ]
      lAlias := .T.
   ENDIF

   IF hb_HHasKey( hParams, "wa" )
      SELECT ( hParams[ "wa" ] )
   ELSE
      IF !lAlias
         SELECT ( F_KALK )
      ELSE
         SELECT 0
      ENDIF
   ENDIF

#ifdef F18_DEBUG
   ?E cSql
#endif


   use_sql( cTable, cSql )
   IF is_sql_rdd_treba_indeks( hParams )
      INDEX ON ( idfirma + idvd + brdok ) TAG "1" TO cTable
      INDEX ON ( idfirma + mkonto + idvd + brdok ) TAG "2" TO cTable
      INDEX ON ( idfirma + DToS( datdok ) + idvd + brdok ) TAG "3" TO cTable
      INDEX ON ( datdok ) TAG "DAT" TO cTable
      INDEX ON ( brfaktp + idvd ) TAG "V_BRF" TO cTable

      INDEX ON idFirma + IdVD + BrDok + TRANSFORM(RBr,'99999')  TAG "1" TO cTable
      INDEX ON idFirma + idvd + brdok + IDTarifa TAG "2" TO cTable
      INDEX ON idFirma + mkonto + idroba + DToS( datdok ) + MU_I + IdVD TAG "3" TO cTable
      INDEX ON idFirma + Pkonto + idroba + DToS( datdok ) + PU_I + IdVD TAG "4" TO cTable
      INDEX ON idFirma + DToS( datdok ) + idvd + brdok TAG "5" TO cTable
      INDEX ON idFirma + IdTarifa + idroba TAG "6" TO cTable
      INDEX ON idroba + idvd TAG "7" TO cTable
      INDEX ON mkonto TAG "8" TO cTable
      INDEX ON pkonto TAG "9" TO cTable
      INDEX ON datdok TAG "DAT" TO cTable
      INDEX ON mu_i + mkonto + idfirma + idvd + brdok  TAG "MU_I" TO cTable
      INDEX ON mu_i + idfirma + idvd + brdok  TAG "MU_I2" TO cTable
      INDEX ON pu_i + pkonto + idfirma + idvd + brdok   TAG "PU_I" TO cTable
      INDEX ON pu_i + idfirma + idvd + brdok   TAG "PU_I2" TO cTable
      INDEX ON idfirma + mkonto + idpartner + idvd + DToS( datdok )   TAG "PMAG" TO cTable

      SET ORDER TO TAG "1"
      GO TOP
   ENDIF

   RETURN .T.


STATIC FUNCTION use_sql_kalk_order( hParams )

   LOCAL cOrder := ""

   IF hb_HHasKey( hParams, "order_by" )
      cOrder += " ORDER BY " + hParams[ "order_by" ]
   ELSE
      cOrder += " ORDER BY idfirma, idvd, brdok, rbr"
   ENDIF

   RETURN cOrder


STATIC FUNCTION use_sql_kalk_where( hParams )

   LOCAL cWhere := ""
   LOCAL dDatOd

   IF hb_HHasKey( hParams, "idfirma" )
      cWhere += parsiraj_sql( "kalk_kalk.idfirma", hParams[ "idfirma" ] )
   ENDIF

   IF hb_HHasKey( hParams, "idvd" )
      cWhere += " AND " + parsiraj_sql( "kalk_kalk.idvd", hParams[ "idvd" ] )
   ENDIF

   IF hb_HHasKey( hParams, "brdok" )
      cWhere += " AND " + parsiraj_sql( "kalk_kalk.brdok", hParams[ "brdok" ] )
   ENDIF

   IF hb_HHasKey( hParams, "mkonto" )
      cWhere += " AND " + parsiraj_sql( "kalk_kalk.mkonto", hParams[ "mkonto" ] )
   ENDIF
   IF hb_HHasKey( hParams, "mkonto_sint" )
      cWhere += " AND " + parsiraj_sql( "LEFT(kalk_kalk.mkonto,3)", hParams[ "mkonto_sint" ] )
   ENDIF

   IF hb_HHasKey( hParams, "pkonto" )
      cWhere += " AND " + parsiraj_sql( "kalk_kalk.pkonto", hParams[ "pkonto" ] )
   ENDIF
   IF hb_HHasKey( hParams, "pkonto_sint" )
      cWhere += " AND " + parsiraj_sql( "LEFT(kalk_kalk.pkonto,3)", hParams[ "pkonto_sint" ] )
   ENDIF

   IF hb_HHasKey( hParams, "idpartner" )
      cWhere += "AND " + parsiraj_sql( "kalk_kalk.idpartner", hParams[ "idpartner" ] )
   ENDIF

   IF hb_HHasKey( hParams, "idroba" )
      cWhere += "AND " + parsiraj_sql( "idroba", hParams[ "idroba" ] )
   ENDIF

   IF hb_HHasKey( hParams, "dat_do" )
      IF !hb_HHasKey( hParams, "dat_od" )
         dDatOd := CToD( "" )
      ELSE
         dDatOd := hParams[ "dat_od" ]
      ENDIF
      cWhere += " AND " + parsiraj_sql_date_interval( "kalk_kalk.datdok", dDatOd, hParams[ "dat_do" ] )
   ENDIF

   RETURN cWhere


/*
STATIC FUNCTION order_by(  cSort )

   LOCAL cRet := "idfirma"

   SWITCH cSort
   CASE "brdok"
      cRet += ",idvd, brdok"
      EXIT
   CASE "pkonto"
      cRet += ",pkonto, idroba"
      EXIT
   CASE "mkonto"
      cRet += ",mkonto, idroba"
      EXIT
   CASE "tarifa"
      cRet += ",idtarifa, idroba"
      EXIT
   ENDSWITCH

   cRet += ",datdok"

   RETURN cRet
*/


FUNCTION kalk_mkonto( cIdFirma, cIdKonto, cIdRoba, cX )
   RETURN kalk_mkonto_pkonto( "M", cIdFirma, cIdKonto, cIdRoba, cX )


FUNCTION kalk_pkonto( cIdFirma, cIdKonto, cIdRoba, cX )
   RETURN kalk_mkonto_pkonto( "P", cIdFirma, cIdKonto, cIdRoba, cX )

FUNCTION kalk_mkonto_pkonto( cTip, cIdFirma, cIdKonto, cIdRoba, cX )

   LOCAL lKraj
   LOCAL hParams := hb_Hash()

   IF cX == NIL
      lKraj := .F.
      cX := ""
   ELSE
      // cX := "X"
      lKraj := .T.
   ENDIF

   hParams[ 'idfirma' ]  := cIdFirma + ";"
   hParams[ iif( cTip == "M", 'mkonto', 'pkonto' ) ]  := cIdKonto + ";"
   IF cIdRoba != NIL
      hParams[ 'idroba'  ]  := cIdRoba  + ";"
   ENDIF
   hParams[ 'order_by' ] := iif( cTip == "M", "mkonto", "pkonto" )
   use_sql_kalk( hParams )

   IF lKraj
      GO BOTTOM
   ENDIF

   RETURN Eof()


FUNCTION use_sql_kalk_doks( hParams )

   LOCAL cSql, cWhere, cOrder
   LOCAL cTable := "KALK_DOKS"

   default_if_nil( @hParams, hb_Hash() )

   cWhere := sql_kalk_doks_where( hParams )
   cOrder := sql_kalk_doks_order( hParams )

   cSql := "SELECT "
   cSql += coalesce_char_zarez( "idfirma", 2 )
   cSql += coalesce_char_zarez( "idvd", 2 )
   cSql += coalesce_char_zarez( "brdok", 8 )
   cSql += " datdok, datfaktp, datval, dat_od, dat_do, "
   cSql += coalesce_char_zarez( "brfaktp", 10 )
   cSql += coalesce_char_zarez( "idpartner", 6 )
   cSql += coalesce_char_zarez( "pkonto", 7 )
   cSql += coalesce_char_zarez( "mkonto", 7 )
   cSql += coalesce_num_num_zarez( "nv", 12, 2 )
   cSql += coalesce_num_num_zarez( "vpv", 12, 2 )
   cSql += coalesce_num_num_zarez( "rabat", 12, 2 )
   cSql += coalesce_num_num_zarez( "mpv", 12, 2 )
   cSql += coalesce_char_zarez( "opis", 100 )
   cSql += " korisnik, obradjeno"
   cSql += " FROM " + f18_sql_schema("kalk_doks") + " "

   IF !Empty( cWhere )
      cSql += " WHERE " + cWhere
      IF hb_HHasKey( hParams, "where_ext" )
         cSql += " " + hParams[ "where_ext" ]
      ENDIF
      IF !Empty( cOrder )
         cSql += cOrder
      ENDIF
   ELSE
      cSql += " OFFSET 0 LIMIT 1 "
   ENDIF

   IF hb_HHasKey( hParams, "desc" ) .AND. hParams[ "desc" ]
      cSql += " DESC "
   ENDIF
   IF hb_HHasKey( hParams, "limit" )
      cSql += " LIMIT " + sql_quote( hParams[ "limit" ] )
   ENDIF


   IF hb_HHasKey( hParams, "alias" )
      cTable := hParams[ "alias" ]
   ENDIF

#ifdef F18_DEBUG
   ?E cSql
#endif

   IF hb_HHasKey( hParams, "wa" )
      SELECT ( hParams[ "wa" ] )
   ELSE
      SELECT ( F_KALK_DOKS )
   ENDIF
   use_sql( cTable, cSql )

   IF is_sql_rdd_treba_indeks( hParams )
      INDEX ON ( idfirma + idvd + brdok ) TAG "1" TO cTable
      INDEX ON ( idfirma + mkonto + idvd + brdok ) TAG "2" TO cTable
      INDEX ON ( idfirma + DToS( datdok ) + idvd + brdok ) TAG "3" TO cTable
      INDEX ON ( datdok ) TAG "DAT" TO cTable
      INDEX ON ( brfaktp + idvd ) TAG "V_BRF" TO cTable
      SET ORDER TO TAG "1"
      GO TOP
   ENDIF

   RETURN .T.



STATIC FUNCTION sql_kalk_doks_where( hParams )

   LOCAL cWhere := "", dDatOd

   IF hb_HHasKey( hParams, "idfirma" )
      cWhere += "idfirma = " + sql_quote( hParams[ "idfirma" ] )
   ENDIF

   IF hb_HHasKey( hParams, "idvd" )
      IF !Empty( cWhere )
         cWhere += " AND "
      ENDIF
      cWhere += "idvd = " + sql_quote( hParams[ "idvd" ] )
   ENDIF

   IF hb_HHasKey( hParams, "brdok" )
      IF !Empty( cWhere )
         cWhere += " AND "
      ENDIF
      cWhere += "brdok = " + sql_quote( hParams[ "brdok" ] )
   ENDIF

   IF hb_HHasKey( hParams, "idpartner" )
      IF !Empty( cWhere )
         cWhere += " AND "
      ENDIF
      cWhere += "idpartner = " + sql_quote( hParams[ "idpartner" ] )
   ENDIF

   IF hb_HHasKey( hParams, "broj_fakture" )
      IF !Empty( cWhere )
         cWhere += " AND "
      ENDIF
      cWhere += "brfaktp = " + sql_quote( hParams[ "broj_fakture" ] )
   ENDIF


   IF hb_HHasKey( hParams, "mkonto" )
      IF !Empty( cWhere )
         cWhere += " AND "
      ENDIF
      cWhere += "mkonto = " + sql_quote( hParams[ "mkonto" ] )
   ENDIF

   IF hb_HHasKey( hParams, "pkonto" )
      IF !Empty( cWhere )
         cWhere += " AND "
      ENDIF
      cWhere += "pkonto = " + sql_quote( hParams[ "pkonto" ] )
   ENDIF

   IF hb_HHasKey( hParams, "brdok_sfx" )
      IF !Empty( cWhere )
         cWhere += " AND "
      ENDIF

/*
      -- select * from fmk.kalk_doks
      where substr(brdok,6) ='/T'
      order by substr(brdok,6),left(brdok,5) DESC
*/
      // cWhere += "substr(brdok,6) = " + sql_quote( hParams[ "brdok_sfx" ] )
      cWhere += "substr(brdok," + AllTrim( Str( 8 -Len( hParams[ "brdok_sfx" ] ) + 1 ) ) + ")=" + sql_quote( hParams[ "brdok_sfx" ] )
   ENDIF

   IF hb_HHasKey( hParams, "dat_do" )
      IF !hb_HHasKey( hParams, "dat_od" )
         dDatOd := CToD( "" )
      ELSE
         dDatOd := hParams[ "dat_od" ]
      ENDIF
      cWhere += " AND " + parsiraj_sql_date_interval( "datdok", dDatOd, hParams[ "dat_do" ] )
   ENDIF

   RETURN cWhere



STATIC FUNCTION sql_kalk_doks_order( hParams )

   LOCAL cOrder

   IF hb_HHasKey( hParams, "order_by" )
      cOrder := " ORDER BY " + hParams[ "order_by" ]
   ELSE
      cOrder := " ORDER BY idfirma, idvd, brdok "
   ENDIF

   RETURN cOrder



// FUNCTION public.kalk_idpartner_by_brdok( cIdFirma varchar, cIdVd varchar, cBrDok varchar ) RETURNS varchar


FUNCTION kalk_doks_idpartner_by_brdok( cIdFirma, cIdVd, cBrDok )

   LOCAL cQuery, oQry, oError, cRet := ""

   cQuery := "SELECT public.kalk_idpartner_by_brdok(" + ;
      sql_quote( cIdFirma ) + "," +;
      sql_quote( cIdVd ) + "," +;
      sql_quote( cBrDok ) + ")"

   BEGIN SEQUENCE WITH {| err | Break( err ) }

      oQry := run_sql_query( cQuery )
      IF is_var_objekat_tpqquery( oQry )
         cRet := oQry:FieldGet( 1 )
      ENDIF

   RECOVER USING oError
      Alert( _u( "SQL neuspješno kalk_idpartner_by_brdok ?" ) )
   END SEQUENCE

   RETURN cRet


// FUNCTION public.kalk_pkonto_idvd_brfaktp_kalk_exists( cIdVd varchar, cPKonto varchar,  cBrFaktP varchar) RETURNS boolean

FUNCTION kalk_pkonto_idvd_brfaktp_kalk_exists( cIdVd, cPKonto, cBrFaktP )

   LOCAL cQuery, oRet

   cQuery := "SELECT public.kalk_pkonto_idvd_brfaktp_kalk_exists(" + ;
      sql_quote( cIdVd ) + "," + ;
      sql_quote( cPKonto ) + "," + ;
      sql_quote( cBrFaktP ) + ")"
   oRet := run_sql_query( cQuery )

   IF is_var_objekat_tpqquery( oRet )
      RETURN oRet:FieldGet( 1 )
   ENDIF

   RETURN .F.
