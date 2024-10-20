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


FUNCTION epdv_azur_kif()
   RETURN epdv_azur_kuf_kif( "KIF" )

FUNCTION epdv_azur_kuf()
   RETURN epdv_azur_kuf_kif( "KUF" )


FUNCTION epdv_povrat_kuf( nBrDok )
   RETURN epdv_povrat_kuf_kif( "KUF", nBrDok )

FUNCTION epdv_povrat_kif( nBrDok )
   RETURN epdv_povrat_kuf_kif( "KIF", nBrDok )


FUNCTION epdv_azur_kuf_kif( cKufKif )

   LOCAL nPArea, nKArea, nCount
   LOCAL hRec
   LOCAL nNextGRbr := 0
   LOCAL nLastBrDok := 0
   LOCAL nNextBrDok := 0
   LOCAL nBrDok := 0

   IF cKufKif == "KUF"
      epdv_otvori_kuf_priprema()
      nPArea := F_P_KUF
      nKArea := F_KUF
   ELSE
      epdv_otvori_kif_priprema()
      nPArea := F_P_KIF
      nKArea := F_KIF
   ENDIF

   Box(, 2, 60 )

   nCount := 0

   SELECT ( nPArea )
   IF RECCOUNT2() == 0
      RETURN 0
   ENDIF

   nNextGRbr := epdv_next_globalni_redni_broj( cKufKif )

   SELECT ( nPArea )
   GO TOP

   IF ( field->br_dok == 0 )
      nNextBrDok := epdv_next_br_dok( cKufKif )
      nBrdok := nNextBrDok
   ELSE
      nBrDok := field->br_dok
   ENDIF

   IF epdv_kuf_kif_azur_sql( cKufKif, nNextGRbr, nBrDok )

/*
      SELECT ( nPArea )
      GO TOP

      DO WHILE !Eof() // p_kuf ili p_kif

         // set_global_memvars_from_dbf()
         hRec := dbf_get_rec()

         hRec[ "datum_2" ] := Date()
         hRec[ "g_r_br" ] := nNextGRbr
         hRec[ "br_dok" ] := nBrDok
         nLastBrDok := hRec[ "br_dok" ]

         ++nCount
         @ box_x_koord() + 1, box_y_koord() + 2 SAY PadR( "Dodajem P_KIF -> KUF " + Transform( nCount, "9999" ), 40 )
         @ box_x_koord() + 2, box_y_koord() + 2 SAY PadR( "   " + cKufKif + " G.R.BR: " + Transform( nNextGRbr, "99999" ), 40 )

         nNextGRbr++

         SELECT ( nKArea )
         APPEND BLANK

         // hRec := get_hash_record_from_global_vars()
         dbf_update_rec( hRec )

         SELECT ( nPArea )
         SKIP
      ENDDO
*/

   ELSE

      MsgBeep( "Neuspješno ažuriranje epdv/sql !" )
      RETURN .F.

   ENDIF

   SELECT ( nKArea )
   USE

   @ box_x_koord() + 1, box_y_koord() + 2 SAY8 PadR( "Brišem pripremu ...", 40 )

   SELECT ( nPArea )
   my_dbf_zap()
   // USE

   // IF ( cKufKif == "KUF" )
   // epdv_otvori_kuf_priprema()
   // ELSE
   // epdv_otvori_kif_priprema()
   // ENDIF

   BoxC()

   MsgBeep( "Ažuriran je " + cKufKif + " dokument " + Str( nBrDok, 6, 0 ) )

   RETURN nLastBrDok



FUNCTION epdv_kuf_kif_azur_sql( cKufKif, nNextRbrGlobalno, nNextBrDok )

   LOCAL lOk := .T.
   LOCAL hRec := hb_Hash()
   LOCAL cTable
   LOCAL nI
   LOCAL cTmpId
   LOCAL _ids := {}
   LOCAL nWA
   LOCAL hParams

   IF cKufKif == "KIF"
      nWA := F_P_KIF
      epdv_open_kif_empty()
   ELSEIF cKufKif == "KUF"
      nWA := F_P_KUF
      epdv_open_kuf_empty()
   ENDIF

   cTable := "epdv_" + Lower( cKufKif )

   info_bar( "epdv", "sql " + cTable )

   run_sql_query( "BEGIN" )
   IF !f18_lock_tables( { cTable } )
      run_sql_query( "ROLLBACK" )
      RETURN .F.
   ENDIF

   // lOk := .T.

   // IF lOk = .T.

   SELECT ( nWA )
   GO TOP
   DO WHILE !Eof()

      hRec := dbf_get_rec()
      hRec[ "datum_2" ] := Date()
      hRec[ "br_dok" ] := nNextBrDok
      hRec[ "g_r_br" ] := nNextRbrGlobalno++

      IF cKufKif == "KIF"
         hRec[ "part_kat_2" ] := "" // ovo je polje koje se nalazi u epdv.kif, ali se ne koristi
      ENDIF


      IF cKufKif == "KIF"
         hRec[ "src_pm" ] := field->src_pm
      ENDIF

      cTmpId := "#2" + PadL( AllTrim( Str( hRec[ "br_dok" ], 6 ) ), 6 )

      IF !sql_table_update( cTable, "ins", hRec )
         lOk := .F.
         EXIT
      ENDIF

      SKIP

   ENDDO

   // ENDIF

   IF !lOk
      run_sql_query( "ROLLBACK" )
   ELSE
      AAdd( _ids, cTmpId )
      push_ids_to_semaphore( cTable, _ids )

      hParams := hb_Hash()
      hParams[ "unlock" ] :=  { cTable }
      run_sql_query( "COMMIT", hParams )
   ENDIF

   RETURN lOk



FUNCTION epdv_povrat_kuf_kif( cKufKif, nBrDok )

   LOCAL hRecDelete, lOk
   LOCAL hRec
   LOCAL nPrivateWA
   LOCAL nKumulativWA
   LOCAL nCnt
   LOCAL cTable
   LOCAL hParams := hb_Hash()

   hParams[ "brdok" ] := nBrDok
   IF ( cKufKif == "KUF" )
      // epdv_otvori_kuf_priprema()
      select_o_epdv_p_kuf()
      nPrivateWA := F_P_KUF
      nKumulativWA := F_KUF
      cTable := "epdv_kuf"
      find_epdv_kuf_za_period( NIL, NIL, hParams, "br_dok" )
   ELSE
      // epdv_otvori_kif_priprema()
      select_o_epdv_p_kif()

      nPrivateWA := F_P_KIF
      nKumulativWA := F_KIF
      cTable := "epdv_kif"
      find_epdv_kif_za_period( NIL, NIL, hParams, "br_dok" )
   ENDIF

   nCnt := 0

   SELECT ( nKumulativWA )
   // SET ORDER TO TAG "BR_DOK"
   // SEEK Str( nBrdok, 6, 0 )

   IF Eof()
      MsgBeep( "KUF dokument " + Str( nBrDok, 6, 0 ) + " ne postoji?!" )
      SELECT ( nPrivateWA )
      RETURN 0
   ENDIF

   SELECT ( nPrivateWA )
   IF RECCOUNT2() > 0
      MsgBeep( "U pripremi postoji dokument#Ne može se izvršiti povrat#operacija prekinuta !" )
      RETURN -1
   ENDIF

   Box(, 2, 60 )

   SELECT ( nKumulativWA ) // KUF -> P_KUF
   DO WHILE !Eof() .AND. ( field->br_dok == nBrDok )

      ++nCnt
      @ box_x_koord() + 1, box_y_koord() + 2 SAY PadR( "P_" + cKufKif +  " -> " + cKufKif + " :" + Transform( nCnt, "9999" ), 40 )

      SELECT ( nKumulativWA )
      hRec := dbf_get_rec()

      SELECT ( nPrivateWA )
      APPEND BLANK
      dbf_update_rec( hRec )

      SELECT ( nKumulativWA )
      SKIP
   ENDDO


   // my_close_all_dbf()
   // IF ( cKufKif == "KUF" )
   // epdv_otvori_kuf_priprema()
   // ELSE
   // epdv_otvori_kif_priprema()
   // ENDIF

   SELECT ( nKumulativWA )
   // SET ORDER TO TAG "BR_DOK"
   // SEEK Str( nBrdok, 6, 0 )
   GO TOP
   hRecDelete := dbf_get_rec()
   lOk := .T.
   MsgO( "del " + cKufKif )
   lOk := delete_rec_server_and_dbf( cTable, hRecDelete, 2, "FULL" )
   MsgC()
   IF !lOk
      MsgBeep( "Operacija brisanja dokumenta nije uspješna, dokument: " + AllTrim( Str( nBrDok ) ) )
   ENDIF

   SELECT ( nKumulativWA )
   USE

   // IF ( cKufKif == "KUF" )
   // epdv_otvori_kuf_priprema()
   // ELSE
   // epdv_otvori_kif_priprema()
   // ENDIF

   BoxC()

   IF lOk
      MsgBeep( "Izvršen je povrat dokumenta " + Str( nBrDok, 6, 0 ) + " u pripremu" )
   ENDIF

   RETURN nBrDok



FUNCTION epdv_renumeracija_rbr( cKufKif, lShow )

   LOCAL hRec, nRbr

   IF lShow == nil
      lShow := .T.
   ENDIF

   IF cKufKif == "P_KUF"
      select_o_epdv_p_kuf()

   ELSEIF cKufKif == "P_KIF"
      select_o_epdv_p_kif()

   ENDIF

   SET ORDER TO TAG "datum"
   GO TOP
   nRbr := 1

   DO WHILE !Eof()
      hRec := dbf_get_rec()
      hRec[ "r_br" ] := nRbr
      dbf_update_rec( hRec )
      ++nRbr
      SKIP
   ENDDO

   IF lShow
      MsgBeep( "Renumeracija pripreme završena" )
   ENDIF

   RETURN .T.


/*
FUNCTION epdv_renum_g_rbr( cKufKif, lShow )

   LOCAL nRbr, hRec
   LOCAL nLRbr

   IF lShow == nil
      lShow := .T.
   ENDIF

   IF cKufKif == "KUF"
  --    select_o_epdv_kuf()

   ELSEIF cKufKif == "P_KIF"
  --    select_o_epdv_kif()

   ENDIF

   SET ORDER TO TAG "l_datum"

   SEEK "DZ"
   SKIP -1
   IF lock == "D"
      nLRbr := g_r_br
   ELSE
      nLRbr := 0
   ENDIF

   PRIVATE cFilter := "!(lock == 'D')"

   SET FILTER TO &cFilter
   GO TOP

   Box(, 3, 60 )
   nRbr := nLRbr
   DO WHILE !Eof()
      ++nRbr
      @ box_x_koord() + 1, box_y_koord() + 2 SAY cKufKif + ":" + Str( nRbr, 8, 0 )
      hRec := dbf_get_rec()
      hRec[ "g_r_br" ] := nRbr
      dbf_update_rec( hRec )
      ++nRbr
      SKIP
   ENDDO
   BoxC()

   USE

   IF lShow
      MsgBeep( cKufKif + " : G.Rbr renumeracija izvršena" )
   ENDIF

   RETURN .T.
*/
