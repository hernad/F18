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

STATIC __dbf_pack_algoritam := "1"

// algoritam 1 - vise od 700 deleted zapisa
STATIC __dbf_pack_v1 := 700
// algoritam 2 - vise od 10% deleted zapisa
STATIC __dbf_pack_v2 := 10


/*
   Funkcije koje koriste xBASE RDD-ovi (replacable database driver)
   DBCDX, SQLMIX
*/

THREAD STATIC aWaStack := {}

FUNCTION PushWA()

   LOCAL hRet := hb_Hash()
   LOCAL cFilter, lSql

   IF Used()

      IF my_rddName() != "SQLMIX"
         cFilter := dbFilter()
         lSql := .F.
      ELSE
         cFilter := dbFilter()
         lSql := .T.
      ENDIF
      hRet[ 'wa' ] := Select()
      hRet[ 'index' ] := ordName()
      hRet[ 'filter' ] := cFilter
      hRet[ 'recno' ] := RecNo()
      hRet[ 'sql' ] := lSql

   ELSE
      hRet[ 'wa' ] := NIL
      hRet[ 'index' ] := NIL
      hRet[ 'filter' ] := NIL
      hRet[ 'recno' ] := -1
      hRet[ 'sql' ] := .F.

   ENDIF

   StackPush( aWAStack, hRet )

   RETURN hRet


/*

    PopWa() - pozicioniraj se na WA sa stacka

    PopWa( F_KONTO ) - pozicioniraj se na WA sa stack-a,
                       ALI SAMO AKO NA stacku NIJE pohranjena F_KONTO WA



*/

FUNCTION PopWA( nWANeDiraj )

   LOCAL hRet

   IF nWaNeDiraj == NIL
      nWaNeDiraj := -1
   ENDIF

   hRet := StackPop( aWaStack )

   IF !HB_ISHASH( hRet )  .OR. !hb_HHasKey( hRet, "wa" )
      error_bar( "bug", log_stack( 1 ) )
      RETURN NIL
   ENDIF

   IF hRet[ 'wa' ] <> NIL  .AND. ( hRet[ "wa" ] != nWaNeDiraj )

      my_dbSelectArea( hRet[ "wa" ] )

      IF Used()
         ordSetFocus( hRet[ "index" ] )

         IF !Empty( hRet[ "filter" ] )
            SET FILTER to &( hRet[ "filter" ] )
         ELSE
            IF !Empty( dbFilter() )
               SET FILTER TO
            ENDIF
         ENDIF

         GO hRet[ "recno" ]
      ENDIF

   ENDIF

   RETURN hRet


FUNCTION log_stack( nStart )

   LOCAL cLogStr := "", nI, cMsg

   FOR nI := nStart TO 30
      IF !Empty( ProcName( nI ) )
         cMsg := AllTrim( Str( nI, 3 ) ) + ")" + AllTrim( ProcName( nI ) ) + "/" + AllTrim( Str( ProcLine( nI ), 6 ) )
         IF Empty( cLogStr )
            cLogStr := cMsg
         ELSE
            cLogStr +=  "% " + cMsg
         ENDIF
      END
   NEXT

   RETURN cLogStr


FUNCTION index_tag_num( cName )

   LOCAL nI

   IF !Used()
      RETURN -1
   ENDIF

   IF my_rddName() != "SQLMIX"
      RETURN ordNumber( cName )
   ELSE
      FOR nI := 1 TO ordCount()
         IF ordName( nI ) == cName
            RETURN nI
         ENDIF
      NEXT
      RETURN 0
   ENDIF


/*
     dbf lock / unlock
*/

FUNCTION my_flock()

   LOCAL lRet

   IF Used() .AND.  ( my_rddName() != "SQLMIX" )
      lRet := FLock()
      IF !lRet
         ?E "FLOCK neuspjesno: " + Alias()
      ENDIF
      RETURN lRet
   ENDIF

   RETURN .T.


FUNCTION my_rlock()

   IF Used() .AND. ( my_rddName() != "SQLMIX" )
      RETURN RLock()
   ELSE
      RETURN .T.
   ENDIF

FUNCTION my_unlock()

   IF Used() .AND. ( my_rddName() != "SQLMIX" )
      RETURN dbUnlock()
   ELSE
      RETURN .T.
   ENDIF


/*
   provjeri da li je potrebno pakovati dbfcdx tabelu
   - da li se nakupilo deleted zapisa
*/

FUNCTION hocu_li_pakovati_dbf( cnt, del )

   LOCAL _pack_alg

   _pack_alg := dbf_pack_algoritam()

   DO CASE
   CASE _pack_alg == "0"

      RETURN .F.

   CASE _pack_alg == "1"

      // 1 - pakuje ako ima vise od 00 deleted() zapisa
      IF del > dbf_pack_v1()
         RETURN .T.
      ENDIF

   CASE _pack_alg == "2"


      IF cnt > 0
         // 2 - standardno pakuje se samo ako je > 10% od broja zapisa deleted
         IF ( del / cnt ) * 100 > dbf_pack_v2()
            RETURN .T.
         ENDIF
      ENDIF

   CASE "9"
   CASE _pack_alg == "9"

      // 9 - uvijek ako ima ijedan delted rec
      IF del > 0
         RETURN .T.
      ENDIF

   END CASE

   RETURN .F.


/*
  vraca informacije o dbf parametrima
*/

FUNCTION get_dbf_params_from_ini_conf()

   LOCAL _var_name
   LOCAL _ini_params := hb_Hash()

   _ini_params[ "pack_algoritam" ] := nil
   _ini_params[ "pack_v1" ] := nil
   _ini_params[ "pack_v2" ] := nil

   IF !f18_ini_config_read( F18_DBF_INI_SECTION, @_ini_params, .T. )
      MsgBeep( F18_DBF_INI_SECTION + "  problem sa ini read" )
      RETURN .F.
   ENDIF

   // setuj varijable iz inija
   IF _ini_params[ "pack_algoritam" ] != nil
      __dbf_pack_algoritam := _ini_params[ "pack_algoritam" ]
   ENDIF

   IF _ini_params[ "pack_v1" ] != nil
      __dbf_pack_v1 := Val( _ini_params[ "pack_v1" ] )
   ENDIF

   IF _ini_params[ "pack_v2" ] != nil
      __dbf_pack_v2 := Val( _ini_params[ "pack_v2" ] )
   ENDIF

   RETURN .T.



STATIC FUNCTION dbf_pack_algoritam()

   RETURN __dbf_pack_algoritam



STATIC FUNCTION dbf_pack_v1()
   RETURN __dbf_pack_v1


STATIC FUNCTION dbf_pack_v2()
   RETURN __dbf_pack_v2
