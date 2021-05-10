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

//THREAD STATIC __var_obr

FUNCTION rekap_ld( cId, nGodina, nMjesec, nIzn1, nIzn2, cIdPartner, cOpis, cOpis2, lObavDodaj, cIzdanje )

   IF lObavDodaj == nil
      lObavDodaj := .F.
   ENDIF

   IF cIdPartner = NIL
      cIdPartner = ""
   ENDIF

   IF cOpis = nil
      cOpis = ""
   ENDIF

   IF cOpis2 = nil
      cOpis2 = ""
   ENDIF

   IF cIzdanje == nil
      cIzdanje := ""
   ENDIF

   PushWA()

   SELECT rekld
   IF lObavDodaj
      APPEND BLANK
   ELSE
      SEEK Str( nGodina, 4, 0 ) + Str( nMjesec, 2, 0 ) + cId + " " // rekld tmp
      IF !Found()
         APPEND BLANK
      ENDIF
   ENDIF

   RREPLACE godina WITH Str( nGodina, 4, 0 ), mjesec WITH Str( nMjesec, 2, 0 ), ;
      id WITH  cId, ;
      iznos1 WITH nIzn1, iznos2 WITH nIzn2, ;
      idpartner WITH cIdPartner, ;
      opis WITH cOpis, ;
      opis2 WITH cOpis2


   PopWA()

   RETURN .T.



FUNCTION o_ld_rekap()

   o_por()
   o_dopr()
   o_ld_parametri_obracuna()
   o_ld_rj()
   o_ld_radn()
   o_str_spr()
   o_koef_beneficiranog_radnog_staza()
   o_ld_vrste_posla()
   o_ops()
   // O_RADKR
   o_kred()
   // o_ld()

   set_tippr_ili_tippr2( cObracun )

   RETURN .T.


FUNCTION ld_rekap_get_svi()

   LOCAL GetList := {}
   PushWa()

   Box(, 11 + iif( IsRamaGlas(), 1, 0 ), 75 )
   DO WHILE .T.

      @ box_x_koord() + 2, box_y_koord() + 2 SAY8 "Vrsta djelatnosti: "  GET cRTipRada VALID val_tiprada( cRTipRada ) PICT "@!"

      @ box_x_koord() + 3, box_y_koord() + 2 SAY8 "Radne jedinice: "  GET  qqRJ PICT "@!S25"
      @ box_x_koord() + 4, box_y_koord() + 2 SAY8 "Za mjesece od:"  GET  nMjesec  PICT "99" VALID {|| nMjesecDo := nMjesec, .T. }
      @ box_x_koord() + 4, Col() + 2 SAY8 "do:"  GET  nMjesecDo  PICT "99" VALID nMjesecDo >= nMjesec
      @ box_x_koord() + 4, Col() + 2 SAY8 "Obracun: " GET cObracun WHEN ld_help_broj_obracuna( .T., cObracun ) VALID ld_valid_obracun( .T., cObracun )
      @ box_x_koord() + 5, box_y_koord() + 2 SAY8 "Godina: "  GET  nGodina  PICT "9999"
      @ box_x_koord() + 7, box_y_koord() + 2 SAY8 "Stručna Sprema: "  GET  cStrSpr PICT "@!" VALID Empty( cStrSpr ) .OR. P_StrSpr( @cStrSpr )
      @ box_x_koord() + 8, box_y_koord() + 2 SAY8 "Opština stanovanja: "  GET  cOpsSt PICT "@!" VALID Empty( cOpsSt ) .OR. P_Ops( @cOpsSt )
      @ box_x_koord() + 9, box_y_koord() + 2 SAY8 "Opština rada:       "  GET  cOpsRad  PICT "@!" VALID Empty( cOpsRad ) .OR. P_Ops( @cOpsRad )

      @ box_x_koord() + 10, box_y_koord() + 2 SAY8 "Vrsta invaliditeta (0 sve)  : "  GET  nVrstaInvaliditeta  PICT "9" VALID nVrstaInvaliditeta == 0 .OR. valid_vrsta_invaliditeta( @nVrstaInvaliditeta )
      @ box_x_koord() + 11, box_y_koord() + 2 SAY8 "Stepen invaliditeta (>=)    : "  GET  nStepenInvaliditeta  PICT "999" VALID valid_stepen_invaliditeta( @nStepenInvaliditeta )

      READ
      ClvBox()

      ESC_BCR
      aUsl1 := Parsiraj( qqRJ, "IDRJ" )
      aUsl2 := Parsiraj( qqRJ, "ID" ) // koristi se u zagl_rekapitulacija_plata_svi za filtriranje radnih jedinica
      IF aUsl1 <> NIL
         EXIT
      ENDIF
   ENDDO
   BoxC()

   PopWa()

   RETURN .T.


FUNCTION ld_rekap_get_rj()

   LOCAL GetList := {}

   PushWa()

   Box(, 10 + iif( IsRamaGlas(), 1, 0 ), 75 )

   @ box_x_koord() + 1, box_y_koord() + 2 SAY8 "Vrsta djelatnosti: "  GET cRTipRada VALID val_tiprada( cRTipRada ) PICT "@!"
   @ box_x_koord() + 2, box_y_koord() + 2 SAY8 "Radna jedinica: "  GET cIdRJ
   @ box_x_koord() + 3, box_y_koord() + 2 SAY8 "Za mjesece od:"  GET  nMjesec  PICT "99" VALID {|| nMjesecDo := nMjesec, .T. }
   @ box_x_koord() + 3, Col() + 2 SAY8 "do:"  GET  nMjesecDo  PICT "99" VALID nMjesecDo >= nMjesec
   @ box_x_koord() + 3, Col() + 2 SAY8 "Obracun: " GET cObracun WHEN ld_help_broj_obracuna( .T., cObracun ) VALID ld_valid_obracun( .T., cObracun )
   @ box_x_koord() + 4, box_y_koord() + 2 SAY8 "Godina: "  GET  nGodina  PICT "9999"
   @ box_x_koord() + 6, box_y_koord() + 2 SAY8 "Stručna Sprema: "  GET  cStrSpr PICT "@!" VALID Empty( cStrSpr ) .OR. P_StrSpr( @cStrSpr )
   @ box_x_koord() + 7, box_y_koord() + 2 SAY8 "Opština stanovanja:  "  GET  cOpsSt PICT "@!" VALID Empty( cOpsSt ) .OR. P_Ops( @cOpsSt )
   @ box_x_koord() + 8, box_y_koord() + 2 SAY8 "Opština rada:        "  GET  cOpsRad  PICT "@!" VALID Empty( cOpsRad ) .OR. P_Ops( @cOpsRad )

   @ box_x_koord() + 9, box_y_koord() + 2 SAY8 "Vrsta invaliditeta (0 sve)  : "  GET  nVrstaInvaliditeta  PICT "9" VALID nVrstaInvaliditeta == 0 .OR. valid_vrsta_invaliditeta( @nVrstaInvaliditeta )
   @ box_x_koord() + 10, box_y_koord() + 2 SAY8 "Stepen invaliditeta (>=)    : "  GET  nStepenInvaliditeta  PICT "999" VALID valid_stepen_invaliditeta( @nStepenInvaliditeta )

   READ

   ClvBox()
   ESC_BCR
   BoxC()

   PopWa()

   RETURN .T.


FUNCTION cre_rekld_temp()

   aDbf := { { "GODINA",  "C",  4, 0 }, ;
      { "MJESEC",  "C",  2, 0 }, ;
      { "ID",  "C", 40, 0 }, ;
      { "opis",  "C", 100, 0 }, ;
      { "opis2",  "C", 100, 0 }, ;
      { "iznos1",  "N", 25, 4 }, ;
      { "iznos2",  "N", 25, 4 }, ;
      { "idpartner",  "C",  6, 0 } }


   DBCREATE2( KUMPATH + "REKLD", aDbf )

   SELECT ( F_REKLD )
   my_usex( "rekld" )

   INDEX ON  godina + mjesec + id TAG "1"

   SET ORDER TO TAG "1"
   USE

   RETURN .T.


FUNCTION cre_ops_ld_temp()

   aDbf := { { "ID", "C", 1, 0 }, ;
      { "PORID", "C", 2, 0 }, ;
      { "IDOPS", "C", 4, 0 }, ;
      { "IZNOS", "N", 25, 4 }, ;
      { "IZNOS2", "N", 25, 4 }, ;
      { "IZNOS3", "N", 25, 4 }, ;
      { "IZNOS4", "N", 25, 4 }, ;
      { "IZNOS5", "N", 25, 4 }, ;
      { "IZNOS6", "N", 25, 4 }, ;
      { "IZNOS7", "N", 25, 4 }, ;
      { "BR_OSN", "N", 25, 4 }, ;
      { "IZN_OST", "N", 25, 4 }, ;
      { "T_ST_1", "N", 5, 2 }, ;
      { "T_ST_2", "N", 5, 2 }, ;
      { "T_ST_3", "N", 5, 2 }, ;
      { "T_ST_4", "N", 5, 2 }, ;
      { "T_ST_5", "N", 5, 2 }, ;
      { "T_IZ_1", "N", 25, 4 }, ;
      { "T_IZ_2", "N", 25, 4 }, ;
      { "T_IZ_3", "N", 25, 4 }, ;
      { "T_IZ_4", "N", 25, 4 }, ;
      { "T_IZ_5", "N", 25, 4 }, ;
      { "LJUDI", "N", 10, 0 } }


   IF File( my_home() + "OPSLD.DBF" )
      FErase( my_home() + "OPSLD.DBF" )
      FErase( my_home() + "OPSLD.CDX" )
   ENDIF

   DBCreate2( "opsld", aDbf )
   Select( F_OPSLD )
   my_usex( "opsld" )

   INDEX ON PORID + ID + IDOPS TAG "1"
   USE

   RETURN .T.


FUNCTION PopuniOpsLD( cTip, cPorId, aPorezi )

   LOCAL nT_st_1 := 0
   LOCAL nT_st_2 := 0
   LOCAL nT_st_3 := 0
   LOCAL nT_st_4 := 0
   LOCAL nT_st_5 := 0
   LOCAL nT_iz_1 := 0
   LOCAL nT_iz_2 := 0
   LOCAL nT_iz_3 := 0
   LOCAL nT_iz_4 := 0
   LOCAL nT_iz_5 := 0
   LOCAL i
   LOCAL nPom
   LOCAL nOsnovica := 0
   LOCAL nOstalo := 0
   LOCAL nBrOsnova := 0
   LOCAL nOsnov5 := 0
   LOCAL nOsnov4 := 0

   IF cTip == nil
      cTip := ""
   ENDIF

   IF cPorId == nil
      cPorId := Space( 2 )
   ENDIF

   IF aPorezi == nil
      aPorezi := {}
   ENDIF

   IF cTip == "S"

      cPrObr := get_pr_obracuna()

      IF cPrObr == "N" .OR. cPrObr == " " .OR. cPrObr == "B"
         nOsnovica := _oosnneto
      ELSEIF cPrObr == "2"
         nOsnovica := _oosnostalo
      ELSEIF cPrObr == "P"
         nOsnovica := ( _oosnneto + _oosnostalo )
      ENDIF

      FOR i := 1 TO Len( aPorezi )

         IF i == 1
            nT_st_1 := aPorezi[ i, 5 ]
            nT_iz_1 := aPorezi[ i, 6 ]
         ENDIF

         IF i == 2
            nT_st_2 := aPorezi[ i, 5 ]
            nT_iz_2 := aPorezi[ i, 6 ]
         ENDIF
         IF i == 3
            nT_st_3 := aPorezi[ i, 5 ]
            nT_iz_3 := aPorezi[ i, 6 ]
         ENDIF
         IF i == 4
            nT_st_4 := aPorezi[ i, 5 ]
            nT_iz_4 := aPorezi[ i, 6 ]
         ENDIF
         IF i == 5
            nT_st_5 := aPorezi[ i, 5 ]
            nT_iz_5 := aPorezi[ i, 6 ]
         ENDIF
      NEXT

   ELSE
      cPorId := "  "
      nOsnovica := _ouneto
      nOsnov3 := nPorOsnova
      nOsnov4 := _oosnneto
      nOsnov5 := nPorNROsnova
      nOstalo := _uodbici
      nBrOsnova := nMRadn_bo
   ENDIF

   select_o_ops( radn->idopsst )
   SELECT opsld

   // po opc.stanovanja
   SEEK cPorId + "1" + radn->idopsst // opsld tmp
   IF Found()

      REPLACE iznos WITH iznos + nOsnovica
      REPLACE iznos2 WITH iznos2 + nPorOl
      REPLACE iznos3 WITH iznos3 + nOsnov3
      REPLACE iznos4 WITH iznos4 + nOsnov4
      REPLACE iznos5 WITH iznos5 + nOsnov5
      REPLACE izn_ost WITH izn_ost + nOstalo
      REPLACE br_osn WITH br_osn + nBrOsnova
      REPLACE ljudi WITH ljudi + 1

      REPLACE t_iz_1 WITH t_iz_1 + nT_iz_1
      REPLACE t_iz_2 WITH t_iz_2 + nT_iz_2
      REPLACE t_iz_3 WITH t_iz_3 + nT_iz_3
      REPLACE t_iz_4 WITH t_iz_4 + nT_iz_4
      REPLACE t_iz_5 WITH t_iz_5 + nT_iz_5

      IF nT_st_1 > t_st_1
         REPLACE t_st_1 WITH nT_st_1
      ENDIF

      IF nT_st_2 > t_st_2
         REPLACE t_st_2 WITH nT_st_2
      ENDIF

      IF nT_st_3 > t_st_3
         REPLACE t_st_3 WITH nT_st_3
      ENDIF

      IF nT_st_4 > t_st_4
         REPLACE t_st_4 WITH nT_st_4
      ENDIF

      IF nT_st_5 > t_st_5
         REPLACE t_st_5 WITH nT_st_5
      ENDIF

   ELSE

      APPEND BLANK
      REPLACE id WITH "1"
      REPLACE porid WITH cPorId
      REPLACE idops WITH radn->idopsst
      REPLACE iznos WITH nOsnovica
      REPLACE iznos2 WITH iznos2 + nPorOl
      REPLACE iznos3 WITH iznos3 + nOsnov3
      REPLACE iznos4 WITH iznos4 + nOsnov4
      REPLACE iznos5 WITH iznos5 + nOsnov5
      REPLACE br_osn WITH br_osn + nBrOsnova

      REPLACE izn_ost WITH nOstalo
      REPLACE ljudi WITH 1

      REPLACE t_iz_1 WITH nT_iz_1
      REPLACE t_iz_2 WITH nT_iz_2
      REPLACE t_iz_3 WITH nT_iz_3
      REPLACE t_iz_4 WITH nT_iz_4
      REPLACE t_iz_5 WITH nT_iz_5

      IF nT_st_1 > t_st_1
         REPLACE t_st_1 WITH nT_st_1
      ENDIF

      IF nT_st_2 > t_st_2
         REPLACE t_st_2 WITH nT_st_2
      ENDIF

      IF nT_st_3 > t_st_3
         REPLACE t_st_3 WITH nT_st_3
      ENDIF

      IF nT_st_4 > t_st_4
         REPLACE t_st_4 WITH nT_st_4
      ENDIF

      IF nT_st_5 > t_st_5
         REPLACE t_st_5 WITH nT_st_5
      ENDIF

   ENDIF

   // po kantonu
   SEEK cPorId + "3" + ops->idkan
   IF Found()
      REPLACE iznos WITH iznos + nOsnovica
      REPLACE iznos2 WITH iznos2 + nPorOl
      REPLACE iznos3 WITH iznos3 + nOsnov3
      REPLACE iznos4 WITH iznos4 + nOsnov4
      REPLACE iznos5 WITH iznos5 + nOsnov5
      REPLACE br_osn WITH br_osn + nBrOsnova

      REPLACE ljudi WITH ljudi + 1

      REPLACE izn_ost WITH izn_ost + nOstalo
      REPLACE t_iz_1 WITH t_iz_1 + nT_iz_1
      REPLACE t_iz_2 WITH t_iz_2 + nT_iz_2
      REPLACE t_iz_3 WITH t_iz_3 + nT_iz_3
      REPLACE t_iz_4 WITH t_iz_4 + nT_iz_4
      REPLACE t_iz_5 WITH t_iz_5 + nT_iz_5

      IF nT_st_1 > t_st_1
         REPLACE t_st_1 WITH nT_st_1
      ENDIF

      IF nT_st_2 > t_st_2
         REPLACE t_st_2 WITH nT_st_2
      ENDIF

      IF nT_st_3 > t_st_3
         REPLACE t_st_3 WITH nT_st_3
      ENDIF

      IF nT_st_4 > t_st_4
         REPLACE t_st_4 WITH nT_st_4
      ENDIF

      IF nT_st_5 > t_st_5
         REPLACE t_st_5 WITH nT_st_5
      ENDIF
   ELSE
      APPEND BLANK
      REPLACE id WITH "3"
      REPLACE porid WITH cPorId
      REPLACE idops WITH ops->idkan
      REPLACE iznos WITH nOsnovica
      REPLACE iznos2 WITH iznos2 + nPorOl
      REPLACE iznos3 WITH iznos3 + nOsnov3
      REPLACE iznos4 WITH iznos4 + nOsnov4
      REPLACE iznos5 WITH iznos5 + nOsnov5
      REPLACE br_osn WITH br_osn + nBrOsnova

      REPLACE izn_ost WITH nOstalo
      REPLACE ljudi WITH 1

      REPLACE t_iz_1 WITH nT_iz_1
      REPLACE t_iz_2 WITH nT_iz_2
      REPLACE t_iz_3 WITH nT_iz_3
      REPLACE t_iz_4 WITH nT_iz_4
      REPLACE t_iz_5 WITH nT_iz_5

      IF nT_st_1 > t_st_1
         REPLACE t_st_1 WITH nT_st_1
      ENDIF

      IF nT_st_2 > t_st_2
         REPLACE t_st_2 WITH nT_st_2
      ENDIF

      IF nT_st_3 > t_st_3
         REPLACE t_st_3 WITH nT_st_3
      ENDIF

      IF nT_st_4 > t_st_4
         REPLACE t_st_4 WITH nT_st_4
      ENDIF

      IF nT_st_5 > t_st_5
         REPLACE t_st_5 WITH nT_st_5
      ENDIF

   ENDIF

   // po idn0
   SEEK cPorId + "5" + ops->idn0
   IF Found()

      REPLACE iznos WITH iznos + nOsnovica
      REPLACE iznos2 WITH iznos2 + nPorOl
      REPLACE iznos3 WITH iznos3 + nOsnov3
      REPLACE iznos4 WITH iznos4 + nOsnov4
      REPLACE iznos5 WITH iznos5 + nOsnov5
      REPLACE br_osn WITH br_osn + nBrOsnova

      REPLACE ljudi WITH ljudi + 1

      REPLACE izn_ost WITH izn_ost + nOstalo
      REPLACE t_iz_1 WITH t_iz_1 + nT_iz_1
      REPLACE t_iz_2 WITH t_iz_2 + nT_iz_2
      REPLACE t_iz_3 WITH t_iz_3 + nT_iz_3
      REPLACE t_iz_4 WITH t_iz_4 + nT_iz_4
      REPLACE t_iz_5 WITH t_iz_5 + nT_iz_5

      IF nT_st_1 > t_st_1
         REPLACE t_st_1 WITH nT_st_1
      ENDIF

      IF nT_st_2 > t_st_2
         REPLACE t_st_2 WITH nT_st_2
      ENDIF

      IF nT_st_3 > t_st_3
         REPLACE t_st_3 WITH nT_st_3
      ENDIF

      IF nT_st_4 > t_st_4
         REPLACE t_st_4 WITH nT_st_4
      ENDIF

      IF nT_st_5 > t_st_5
         REPLACE t_st_5 WITH nT_st_5
      ENDIF

   ELSE
      APPEND BLANK
      REPLACE id WITH "5"
      REPLACE porid WITH cPorId
      REPLACE idops WITH ops->idn0
      REPLACE iznos WITH nOsnovica
      REPLACE iznos2 WITH iznos2 + nPorOl
      REPLACE iznos3 WITH iznos3 + nOsnov3
      REPLACE iznos4 WITH iznos4 + nOsnov4
      REPLACE iznos5 WITH iznos5 + nOsnov5
      REPLACE br_osn WITH br_osn + nBrOsnova

      REPLACE izn_ost WITH nOstalo
      REPLACE ljudi WITH 1

      REPLACE t_iz_1 WITH nT_iz_1
      REPLACE t_iz_2 WITH nT_iz_2
      REPLACE t_iz_3 WITH nT_iz_3
      REPLACE t_iz_4 WITH nT_iz_4
      REPLACE t_iz_5 WITH nT_iz_5

      IF nT_st_1 > t_st_1
         REPLACE t_st_1 WITH nT_st_1
      ENDIF

      IF nT_st_2 > t_st_2
         REPLACE t_st_2 WITH nT_st_2
      ENDIF

      IF nT_st_3 > t_st_3
         REPLACE t_st_3 WITH nT_st_3
      ENDIF

      IF nT_st_4 > t_st_4
         REPLACE t_st_4 WITH nT_st_4
      ENDIF

      IF nT_st_5 > t_st_5
         REPLACE t_st_5 WITH nT_st_5
      ENDIF

   ENDIF

   select_o_ops( radn->idopsrad )

   SELECT opsld

   // po opc.rada
   SEEK cPorId + "2" + radn->idopsrad
   IF Found()

      REPLACE iznos WITH iznos + nOsnovica
      REPLACE iznos2 WITH iznos2 + nPorOl
      REPLACE iznos3 WITH iznos3 + nOsnov3
      REPLACE iznos4 WITH iznos4 + nOsnov4
      REPLACE iznos5 WITH iznos5 + nOsnov5
      REPLACE br_osn WITH br_osn + nBrOsnova

      REPLACE ljudi WITH ljudi + 1

      REPLACE izn_ost WITH izn_ost + nOstalo
      REPLACE t_iz_1 WITH t_iz_1 + nT_iz_1
      REPLACE t_iz_2 WITH t_iz_2 + nT_iz_2
      REPLACE t_iz_3 WITH t_iz_3 + nT_iz_3
      REPLACE t_iz_4 WITH t_iz_4 + nT_iz_4
      REPLACE t_iz_5 WITH t_iz_5 + nT_iz_5

      IF nT_st_1 > t_st_1
         REPLACE t_st_1 WITH nT_st_1
      ENDIF

      IF nT_st_2 > t_st_2
         REPLACE t_st_2 WITH nT_st_2
      ENDIF

      IF nT_st_3 > t_st_3
         REPLACE t_st_3 WITH nT_st_3
      ENDIF

      IF nT_st_4 > t_st_4
         REPLACE t_st_4 WITH nT_st_4
      ENDIF

      IF nT_st_5 > t_st_5
         REPLACE t_st_5 WITH nT_st_5
      ENDIF


   ELSE
      APPEND BLANK
      REPLACE id WITH "2"
      REPLACE porid WITH cPorId
      REPLACE idops WITH radn->idopsrad
      REPLACE iznos WITH nOsnovica
      REPLACE iznos2 WITH iznos2 + nPorOl
      REPLACE iznos3 WITH iznos3 + nOsnov3
      REPLACE iznos4 WITH iznos4 + nOsnov4
      REPLACE iznos5 WITH iznos5 + nOsnov5
      REPLACE br_osn WITH br_osn + nBrOsnova

      REPLACE izn_ost WITH nOstalo
      REPLACE ljudi WITH 1

      REPLACE t_iz_1 WITH nT_iz_1
      REPLACE t_iz_2 WITH nT_iz_2
      REPLACE t_iz_3 WITH nT_iz_3
      REPLACE t_iz_4 WITH nT_iz_4
      REPLACE t_iz_5 WITH nT_iz_5

      IF nT_st_1 > t_st_1
         REPLACE t_st_1 WITH nT_st_1
      ENDIF

      IF nT_st_2 > t_st_2
         REPLACE t_st_2 WITH nT_st_2
      ENDIF

      IF nT_st_3 > t_st_3
         REPLACE t_st_3 WITH nT_st_3
      ENDIF

      IF nT_st_4 > t_st_4
         REPLACE t_st_4 WITH nT_st_4
      ENDIF

      IF nT_st_5 > t_st_5
         REPLACE t_st_5 WITH nT_st_5
      ENDIF

   ENDIF

   // po kantonu
   SEEK cPorId + "4" + ops->idkan
   IF Found()

      REPLACE iznos WITH iznos + nOsnovica
      REPLACE iznos2 WITH iznos2 + nPorOl
      REPLACE iznos3 WITH iznos3 + nOsnov3
      REPLACE iznos4 WITH iznos4 + nOsnov4
      REPLACE iznos5 WITH iznos5 + nOsnov5
      REPLACE br_osn WITH br_osn + nBrOsnova

      REPLACE ljudi WITH ljudi + 1

      REPLACE izn_ost WITH izn_ost + nOstalo
      REPLACE t_iz_1 WITH t_iz_1 + nT_iz_1
      REPLACE t_iz_2 WITH t_iz_2 + nT_iz_2
      REPLACE t_iz_3 WITH t_iz_3 + nT_iz_3
      REPLACE t_iz_4 WITH t_iz_4 + nT_iz_4
      REPLACE t_iz_5 WITH t_iz_5 + nT_iz_5

      IF nT_st_1 > t_st_1
         REPLACE t_st_1 WITH nT_st_1
      ENDIF

      IF nT_st_2 > t_st_2
         REPLACE t_st_2 WITH nT_st_2
      ENDIF

      IF nT_st_3 > t_st_3
         REPLACE t_st_3 WITH nT_st_3
      ENDIF

      IF nT_st_4 > t_st_4
         REPLACE t_st_4 WITH nT_st_4
      ENDIF

      IF nT_st_5 > t_st_5
         REPLACE t_st_5 WITH nT_st_5
      ENDIF

   ELSE
      APPEND BLANK
      REPLACE id WITH "4"
      REPLACE porid WITH cPorId
      REPLACE idops WITH ops->idkan
      REPLACE iznos WITH nOsnovica
      REPLACE iznos2 WITH iznos2 + nPorOl
      REPLACE iznos3 WITH iznos3 + nOsnov3
      REPLACE iznos4 WITH iznos4 + nOsnov4
      REPLACE iznos5 WITH iznos5 + nOsnov5
      REPLACE br_osn WITH br_osn + nBrOsnova

      REPLACE izn_ost WITH nOstalo
      REPLACE ljudi WITH 1

      REPLACE t_iz_1 WITH nT_iz_1
      REPLACE t_iz_2 WITH nT_iz_2
      REPLACE t_iz_3 WITH nT_iz_3
      REPLACE t_iz_4 WITH nT_iz_4
      REPLACE t_iz_5 WITH nT_iz_5

      IF nT_st_1 > t_st_1
         REPLACE t_st_1 WITH nT_st_1
      ENDIF

      IF nT_st_2 > t_st_2
         REPLACE t_st_2 WITH nT_st_2
      ENDIF

      IF nT_st_3 > t_st_3
         REPLACE t_st_3 WITH nT_st_3
      ENDIF

      IF nT_st_4 > t_st_4
         REPLACE t_st_4 WITH nT_st_4
      ENDIF

      IF nT_st_5 > t_st_5
         REPLACE t_st_5 WITH nT_st_5
      ENDIF

   ENDIF

   // po idn0
   SEEK cPorId + "6" + ops->idn0
   IF Found()

      REPLACE iznos WITH iznos + nOsnovica
      REPLACE iznos2 WITH iznos2 + nPorOl
      REPLACE iznos3 WITH iznos3 + nOsnov3
      REPLACE iznos4 WITH iznos4 + nOsnov4
      REPLACE iznos5 WITH iznos5 + nOsnov5
      REPLACE br_osn WITH br_osn + nBrOsnova

      REPLACE ljudi WITH ljudi + 1

      REPLACE izn_ost WITH izn_ost + nOstalo
      REPLACE t_iz_1 WITH t_iz_1 + nT_iz_1
      REPLACE t_iz_2 WITH t_iz_2 + nT_iz_2
      REPLACE t_iz_3 WITH t_iz_3 + nT_iz_3
      REPLACE t_iz_4 WITH t_iz_4 + nT_iz_4
      REPLACE t_iz_5 WITH t_iz_5 + nT_iz_5

      IF nT_st_1 > t_st_1
         REPLACE t_st_1 WITH nT_st_1
      ENDIF

      IF nT_st_2 > t_st_2
         REPLACE t_st_2 WITH nT_st_2
      ENDIF

      IF nT_st_3 > t_st_3
         REPLACE t_st_3 WITH nT_st_3
      ENDIF

      IF nT_st_4 > t_st_4
         REPLACE t_st_4 WITH nT_st_4
      ENDIF

      IF nT_st_5 > t_st_5
         REPLACE t_st_5 WITH nT_st_5
      ENDIF

   ELSE
      APPEND BLANK
      REPLACE id WITH "6"
      REPLACE porid WITH cPorId
      REPLACE idops WITH ops->idn0
      REPLACE iznos WITH nOsnovica
      REPLACE izn_ost WITH nOstalo
      REPLACE iznos2 WITH iznos2 + nPorOl
      REPLACE iznos3 WITH iznos3 + nOsnov3
      REPLACE iznos4 WITH iznos4 + nOsnov4
      REPLACE iznos5 WITH iznos5 + nOsnov5
      REPLACE br_osn WITH br_osn + nBrOsnova

      REPLACE ljudi WITH 1
      REPLACE t_iz_1 WITH nT_iz_1
      REPLACE t_iz_2 WITH nT_iz_2
      REPLACE t_iz_3 WITH nT_iz_3
      REPLACE t_iz_4 WITH nT_iz_4
      REPLACE t_iz_5 WITH nT_iz_5

      IF nT_st_1 > t_st_1
         REPLACE t_st_1 WITH nT_st_1
      ENDIF

      IF nT_st_2 > t_st_2
         REPLACE t_st_2 WITH nT_st_2
      ENDIF

      IF nT_st_3 > t_st_3
         REPLACE t_st_3 WITH nT_st_3
      ENDIF

      IF nT_st_4 > t_st_4
         REPLACE t_st_4 WITH nT_st_4
      ENDIF

      IF nT_st_5 > t_st_5
         REPLACE t_st_5 WITH nT_st_5
      ENDIF

   ENDIF

   SELECT ld

   RETURN .T.







FUNCTION zagl_rekapitulacija_plata_svi()

   select_o_por()
   GO TOP
   o_ld_rj()
   SELECT ld_rj
   P_10CPI

   ?U "Obuhvaćene radne jedinice: "
   IF !Empty( qqRJ )
      SET FILTER TO &aUsl2
      GO TOP
      DO WHILE !Eof()
         ?? id + " - " + naz
         ? Space( 27 )
         SKIP 1
      ENDDO
   ELSE
      ?? "SVE"
      ?
   ENDIF

   B_ON

   IF nMjesec == nMjesecDo
      ? _l( "Firma:" ), self_organizacija_naziv(), "  " + _l( "Mjesec:" ), Str( nMjesec, 2 ) + IspisObr()
      ?? "    " + _l( "Godina:" ), Str( nGodina, 4 )
      B_OFF
      ? IF( gBodK == "1", _l( "Vrijednost boda:" ), _l( "Vr.koeficijenta:" ) ), Transform( parobr->vrbod, "99999.99999" )
   ELSE
      ? _l( "Firma:" ), self_organizacija_naziv(), "  " + _l( "Za mjesece od:" ), Str( nMjesec, 2 ), "do", Str( nMjesecDo, 2 ) + IspisObr()
      ?? "    " + _l( "Godina:" ), Str( nGodina, 4 )
      B_OFF
   ENDIF
   ?

   RETURN .T.


FUNCTION zagl_rekapitulacija_plata_rj()

   select_o_ld_rj( cIdRj )

   select_o_por()
   GO TOP
   SELECT ld

   ?
   B_ON
   IF nMjesec == nMjesecDo
      ? _l( "RJ:" ), cIdRj, ld_rj->naz, Space( 2 ) + _l( "Mjesec:" ), Str( nMjesec, 2 ) + IspisObr()
      ?? Space( 4 ) + _l( "Godina:" ), Str( nGodina, 4 )
      B_OFF
      ? if( gBodK == "1", _l( "Vrijednost boda:" ), _l( "Vr.koeficijenta:" ) ), Transform( parobr->vrbod, "99999.99999" )
   ELSE
      ? _l( "RJ:" ), cidrj, ld_rj->naz, "  " + _l( "Za mjesece od:" ), Str( nMjesec, 2 ), "do", Str( nMjesecDo, 2 ) + IspisObr()
      ?? Space( 4 ) + _l( "Godina:" ), Str( nGodina, 4 )
      B_OFF
   ENDIF

   ?

   RETURN .T.



FUNCTION ld_ispis_po_tipovima_primanja( lSvi, cRekapTipoviOut )

   LOCAL i

   LOCAL cTipPrElem := ld_tip_primanja_el_nepogode()

   cUNeto := "D"


   FOR i := 1 TO cLDPolja

      IF PRow() > 55 + dodatni_redovi_po_stranici()
         FF
      ENDIF

      cPom := PadL( AllTrim( Str( i ) ), 2, "0" )

      IF !Empty(cRekapTipoviOut) .AND. cPom $ cRekapTipoviOut
         // tip primanja npr. TO neoporezivi izbaciti
         loop
      ENDIF

      _S&cPom := aRekap[ i, 1 ]   // nafiluj ove varijable radi proracuna dodatnih stavki
      _I&cPom := aRekap[ i, 2 ]

      cPom := PadL( AllTrim( Str( i ) ), 2, "0" )
      select_o_tippr( cPom )

      IF tippr->uneto == "N" .AND. cUneto == "D"
         cUneto := "N"
         ? cLinija

         ?  "Ukupno:"
         @ PRow(), nC1 + 8  SAY Str( nUSati, 12, 2 )
         ?? Space( 1 ) + _l( "sati" )
         @ PRow(), 60 SAY nUNeto PICT gpici
         ?? "", gValuta

         _UNeto := nUNeto
         _USati := nUSati
         ? cLinija
      ENDIF

      IF tippr->( Found() ) .AND. tippr->aktivan == "D" .AND. ( aRekap[ i, 2 ] <> 0 .OR. aRekap[ i, 1 ] <> 0 )
         cTPNaz := tippr->naz
         ? tippr->id + "-" + cTPNaz
         nC1 := PCol()

         IF tippr->fiksan $ "DN"
            @ PRow(), PCol() + 8 SAY Str( aRekap[ i, 1 ], 12, 2 )
            ?? " s"
            @ PRow(), 60 SAY aRekap[ i, 2 ]      PICT gpici
         ELSEIF tippr->fiksan == "P"
            @ PRow(), PCol() + 8 SAY aRekap[ i, 1 ] / nLjudi PICT "999.99%"
            @ PRow(), 60 SAY aRekap[ i, 2 ]        PICT gpici
         ELSEIF tippr->fiksan == "C"
            @ PRow(), 60 SAY aRekap[ i, 2 ]        PICT gpici
         ELSEIF tippr->fiksan == "B"
            @ PRow(), PCol() + 8 SAY aRekap[ i, 1 ] PICT "999999"; ?? " b"
            @ PRow(), 60 SAY aRekap[ i, 2 ]      PICT gpici
         ENDIF


         IF !Empty( cTipPrElem ) .AND. cPom == cTipPrElem
            aRekap[ i, 2 ] := Abs( aRekap[ i, 2 ] )
         ENDIF

         IF nMjesec == nMjesecDo
            rekap_ld( "PRIM" + tippr->id, nGodina, nMjesec, aRekap[ i, 2 ], aRekap[ i, 1 ] )
         ELSE
            rekap_ld( "PRIM" + tippr->id, nGodina, nMjesecDo, aRekap[ i, 2 ], aRekap[ i, 1 ] )
         ENDIF

         IspisKred( lSvi )
      ENDIF

   NEXT

   RETURN .T.


STATIC FUNCTION IspisKred( lSvi )

   LOCAL _kr_partija
   LOCAL lFoundKreditI30 := .F.
   LOCAL nMjesecFor, nMjesecRadKr
   LOCAL nTrec
   LOCAL cIdKred, cNaOsnovu, nUkKred, nUkKrRad, cOpis2
   LOCAL cFilter


   IF "SUMKREDITA" $ tippr->formula

      IF gReKrOs == "X"

         ? cLinija
         ?U "  ", "Od toga pojedinačni krediti:"
         o_radkr_all_rec()
         SET ORDER TO TAG "3" // idkred+naosnovu+idradn+str(godina)+str(mjesec)
         SET FILTER TO Str( nGodina, 4, 0 ) + Str( nMjesec, 2, 0 ) <= Str( field->godina, 4, 0 ) + Str( field->mjesec, 2, 0 ) .AND. ;
            Str( nGodina, 4, 0 ) + Str( nMjesecDo, 2, 0 ) >= Str( field->godina, 4, 0 ) + Str( field->mjesec, 2, 0 )
         GO TOP

         DO WHILE !Eof()

            cIdKred := IDKRED

            select_o_kred( cIdKred )

            SELECT RADKR
            nUkKred := 0

            DO WHILE !Eof() .AND. field->IDKRED == cIdKred

               cNaOsnovu := radkr->NAOSNOVU
               cIdRadnKR := radkr->IDRADN

               select_o_radn( cIdRadnKR )

               SELECT RADKR
               cOpis2 := RADNIK_PREZ_IME
               nUkKrRad := 0

               DO WHILE !Eof() .AND. field->IDKRED == cIdKred .AND. cNaOsnovu == field->NAOSNOVU .AND. cIdRadnKR == field->IDRADN

                  nMjesecRadKr := radkr->mjesec
                  lFoundKreditI30 := .F.

                  IF lSvi

                     // SELECT ld  // rekap za sve rj
                     // SET ORDER TO TAG ( ld_index_tag_vise_obracuna( "2" ) )
                     // HSEEK Str( nGodina, 4, 0 ) + Str( nMjesec, 2, 0 ) + cObracun + radkr->idradn
                     seek_ld_2( NIL, nGodina, nMjesecRadKr, cObracun, radkr->idradn )
                     IF !Empty( qqRj )
                        cFilter := Parsiraj( qqRj, "IDRJ" )
                        SET FILTER TO &cFilter
                        GO TOP
                     ENDIF

                     nTrec := RecNo()
                     DO WHILE !Eof() .AND. ld->godina == nGodina .AND. ld->mjesec == nMjesec .AND. ld->obr == cObracun .AND. ld->idradn == radkr->idradn
                        IF ld->i30 <> 0
                           lFoundKreditI30 := .T.
                           EXIT
                        ENDIF
                        SKIP
                     ENDDO
                     GO ( nTrec )

                  ELSE
                     // rekap za jednu rj
                     // SELECT ld
                     // HSEEK  Str( nGodina, 4 ) + cIdrj + Str( mj, 2 ) + IF( !Empty( cObracun ), cObracun, "" ) + radkr->idradn
                     // ako ima radnika i ako mu je podatak kredita unesen na obracunu
                     seek_ld( cIdRj, nGodina, nMjesecRadKr, iif( !Empty( cObracun ), cObracun, NIL ), radkr->idradn )

                     IF !Eof() .AND. ld->i30 <> 0
                        lFoundKreditI30 := .T.
                     ENDIF
                  ENDIF

                  SELECT radkr

                  IF lFoundKreditI30
                     nUkKred  += radkr->iznos
                     nUkKrRad += radkr->iznos
                  ENDIF

                  SKIP 1

               ENDDO

               IF nUkKrRad <> 0
                  _kr_partija := AllTrim( kred->zirod )
                  rekap_ld( "KRED" + cIdKred + cNaOsnovu, nGodina, nMjesecDo, nUkKrRad, 0, cIdkred, cNaosnovu, AllTrim( cOpis2 ) + ", " + _kr_partija, .T. )

               ENDIF

            ENDDO

            IF nUkKred <> 0   // ispisati kreditora

               IF PRow() > 55 + dodatni_redovi_po_stranici()
                  FF
               ENDIF

               ? "  ", cIdkred, Left( kred->naz, 22 )
               @ PRow(), 58 SAY nUkKred  PICT "(" + gpici + ")"
            ENDIF
         ENDDO

      ELSE

         ? cLinija
         ?U "  ", "Od toga pojedinačni krediti:"
         cOpis2 := ""

         o_radkr_all_rec()
         // SELECT radkr
         SET ORDER TO TAG "3"
         GO TOP


         DO WHILE !Eof()

            select_o_kred( radkr->idkred )
            select_o_radn( radkr->idradn )
            cOpis2 := RADNIK_PREZ_IME


            SELECT radkr
            cIdkred := radkr->idkred
            cNaOsnovu := radkr->naosnovu
            nUkKred := 0

            DO WHILE !Eof() .AND. radkr->idkred == cIdkred .AND. ( cNaosnovu == radkr->naosnovu .OR. gReKrOs == "N" )

               lFoundKreditI30 := .F.

               IF lSvi
                  // SELECT ld
                  // SET ORDER TO TAG ( ld_index_tag_vise_obracuna( "2" ) )
                  // HSEEK  Str( nGodina, 4 ) + Str( nMjesec, 2 ) + iif( ld_vise_obracuna() .AND. !Empty( cObracun ), cObracun, "" ) + radkr->idradn
                  seek_ld_2( NIL, nGodina, nMjesec, cObracun, radkr->idradn )
                  // medjutim ovdje treba uzeti u obzir listu radnih jedinica koje su navedene u qqRJ, npr "10;20;"
                  IF !Empty( qqRj )
                     cFilter := Parsiraj( qqRj, "IDRJ" )
                     SET FILTER TO &cFilter
                     GO TOP
                  ENDIF
               ELSE
                  seek_ld( cIdRj, nGodina, nMjesec, iif( !Empty( cObracun ), cObracun, NIL ), radkr->idradn )
                  // SELECT ld
                  // HSEEK  Str( nGodina, 4 ) + cIdrj + Str( nMjesec, 2 ) + iif( ld_vise_obracuna() .AND. !Empty( cObracun ), cObracun, "" ) + radkr->idradn
               ENDIF

               IF Found()
                  lFoundKreditI30 := .T.
               ENDIF

               SELECT radkr

               IF lFoundKreditI30 .AND. radkr->godina == nGodina .AND. radkr->mjesec == nMjesec
                  nUkKred += radkr->iznos
               ENDIF

               IF nMjesecDo > nMjesec
                  FOR nMjesecFor := nMjesec + 1 TO nMjesecDo
                     IF lSvi
                        SELECT ld
                        SET ORDER TO TAG ( ld_index_tag_vise_obracuna( "2" ) )
                        // HSEEK  Str( nGodina, 4 ) + Str( nMjesecFor, 2 ) + if( ld_vise_obracuna() .AND. !Empty( cObracun ), cObracun, "" ) + radkr->idradn
                        // "LDi2","str(godina)+str(mjesec)+idradn"
                        seek_ld_2( NIL, nGodina, nMjesecFor, iif( ld_vise_obracuna() .AND. !Empty( cObracun ), cObracun, NIL ), radkr->idradn )
                        IF !Empty( qqRj )
                           cFilter := Parsiraj( qqRj, "IDRJ" )
                           SET FILTER TO &cFilter
                           GO TOP
                        ENDIF

                     ELSE
                        // SELECT ld
                        // HSEEK  Str( nGodina, 4 ) + cIdrj + Str( nMjesecFor, 2 ) + if( ld_vise_obracuna() .AND. !Empty( cObracun ), cObracun, "" ) + radkr->idradn
                        seek_ld( cIdRj, nGodina, nMjesecFor, iif( ld_vise_obracuna() .AND. !Empty( cObracun ), cObracun, NIL ), radkr->idradn )
                     ENDIF // lSvi

                     SELECT radkr

                     IF ld->( Found() ) .AND. godina == nGodina .AND. mjesec == nMjesecFor
                        nUkKred += iznos
                     ENDIF
                  NEXT
               ENDIF

               SKIP
            ENDDO

            IF nUkkred <> 0

               IF PRow() > 55 + dodatni_redovi_po_stranici()
                  FF
               ENDIF

               ? "  ", cidkred, Left( kred->naz, 22 ), IF( gReKrOs == "N", "", cnaosnovu )

               @ PRow(), 58 SAY nUkKred  PICT "(" + gpici + ")"

               _kr_partija := AllTrim( kred->zirod )

               IF nMjesec == nMjesecDo
                  rekap_ld( "KRED" + cIdkred + cNaOsnovu, nGodina, nMjesec, nUkKred, 0, ;
                     cIdKred, cNaosnovu, AllTrim( cOpis2 ) + ", " + _kr_partija )
               ELSE
                  rekap_ld( "KRED" + cIdKred + cNaosnovu, nGodina, nMjesecDo, nUkkred, 0, ;
                     cIdKred, cNaosnovu, AllTrim( cOpis2 ) + ", " + _kr_partija )
               ENDIF

            ENDIF
         ENDDO

         SELECT ld
      ENDIF
   ENDIF

   RETURN .T.



STATIC FUNCTION PoTekRacunima()

   ? cLinija
   ? _l( "ZA ISPLATU:" )
   ? "-----------"

   nMArr := Select()
   SELECT KRED
   ASort( aUkTr,,, {| x, y | x[ 1 ] < y[ 1 ] } )
   FOR i := 1 TO Len( aUkTR )
      IF Empty( aUkTR[ i, 1 ] )
         ? PadR( _l( "B L A G A J N A" ), Len( aUkTR[ i, 1 ] + KRED->naz ) + 1 )
      ELSE
         HSEEK aUkTR[ i, 1 ]
         ? aUkTR[ i, 1 ], KRED->naz
      ENDIF
      @ PRow(), 60 SAY aUkTR[ i, 2 ] PICT gpici; ?? "", gValuta
   NEXT
   SELECT ( nMArr )

   RETURN .T.


// ----------------------------------------------
// ispis tipova primanja....
// ----------------------------------------------
FUNCTION ProizvTP()

   // proizvoljni redovi pocinju sa "9"

   select_o_tippr()
   SEEK "9"

   DO WHILE !Eof() .AND. Left( id, 1 ) = "9"
      IF PRow() > 55 + dodatni_redovi_po_stranici()
         FF
      ENDIF
      ? tippr->id + "-" + tippr->naz
      cPom := tippr->formula

      @ PRow(), 60 SAY round2( &cPom, gZaok2 ) PICT gpici
      IF nMjesec == nMjesecDo
         rekap_ld( "PRIM" + tippr->id, nGodina, nMjesec, round2( &cpom, gZaok2 ), 0 )
      ELSE
         rekap_ld( "PRIM" + tippr->id, nGodina, nMjesecDo, round2( &cpom, gZaok2 ), 0 )
      ENDIF

      SKIP

      IF Eof() .OR. !Left( id, 1 ) = "9"
         ? cLinija
      ENDIF
   ENDDO

   RETURN .T.



STATIC FUNCTION PrikKBO()

   nBO := 0
   ? _l( "Koef. Bruto osnove (KBO):" ), Transform( parobr->k3, "999.99999%" )
   ?? Space( 1 ), _l( "BRUTO OSNOVA = NETO OSNOVA*KBO =" )
   @ PRow(), PCol() + 1 SAY nBo := round2( parobr->k3 / 100 * nUNetoOsnova, gZaok2 ) PICT gpici
   ?

   RETURN .T.
