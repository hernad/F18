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

FUNCTION pos_cre_pom_dbf( aDbf, cPom )

   IF cPom == nil
      cPom := "POM"
   ENDIF

   cPomDBF := my_home() + "pom.dbf"
   cPomCDX := my_home() + "pom.cdx"

   IF File( cPomDBF )
      FErase( cPomDBF )
   ENDIF

   IF File( cPomCDX )
      FErase( cPomCDX )
   ENDIF

   IF File( Upper( cPomDBF ) )
      FErase( Upper( cPomDBF ) )
   ENDIF

   IF FILE ( Upper( cPomCDX ) )
      FErase( Upper( cPomCDX ) )
   ENDIF

   // kreiraj tabelu pom.dbf
   dbCreate( my_home() + "pom.dbf", aDbf )

   RETURN .T.


FUNCTION pos2_pripr()

   LOCAL hRec

   SELECT _pos_pripr

   my_dbf_zap()
   GO TOP
   scatter()

   seek_pos_pos( pos_doks->IdPos, pos_doks->IdVd, pos_doks->datum, pos_doks->BrDok )
   DO WHILE !Eof() .AND. POS->( IdPos + IdVd + DToS( datum ) + BrDok ) == pos_doks->( IdPos + IdVd + DToS( datum ) + BrDok )

      hRec := dbf_get_rec()
      hb_HDel( hRec, "rbr" )

      select_o_roba( _IdRoba )
      hRec[ "robanaz" ] := roba->naz
      hRec[ "jmj" ] := roba->jmj

      SELECT _pos_pripr
      APPEND BLANK

      dbf_update_rec( hRec )

      SELECT pos
      SKIP

   ENDDO

   SELECT _pos_pripr

   RETURN .T.


FUNCTION pos_vrati_dokument_iz_pripr( cIdVd, cIdRadnik )

   LOCAL cSta
   LOCAL cBrDok

   DO CASE
   CASE cIdVd == POS_IDVD_DOBAVLJAC_PRODAVNICA
      cSta := "zaduzenja"
   CASE cIdVd == POS_IDVD_NIVELACIJA
      cSta := "nivelacije"
   CASE cIdVd == POS_IDVD_INVENTURA
      cSta := "inventure"

   OTHERWISE
      cSta := "ostalo"
   ENDCASE

   RETURN .T.
