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

#ifdef F18_MIGRATE

STATIC __fin_fmk_tables := { { "suban", "fin_suban" }, { "anal", "fin_anal" } }

#ifdef TEST
STATIC __test_fmk_tables := { { "t_fmk_1", "test_sem_1" }, { "test_fmk_2", "test_sem_2" } }
#endif



FUNCTION fmk_migrate_root( fmk_root_dir )

   IF fmk_root_dir == NIL
#ifdef __PLATFORM__WINDOWS
      fmk_root_dir := "c:" + SLASH + "SIGMA"
#else
#ifdef TEST
      fmk_root_dir := hb_DirSepAdd( tmp_dir() ) +  "SIGMA"
#endif
#endif
   ENDIF

   RETURN fmk_root_dir



FUNCTION fmk_migrate( cur_dir )

   LOCAL _files, _file

   cur_dir := fmk_migrate_root( cur_dir )

   log_write( ProcName( 1 ) + ": " + cur_dir )

   _files := Directory( cur_dir + hb_ps()() + "*", "D" )

   FOR EACH _file in _files
      IF _file[ 5 ] != "D"
         IF FILEEXT( Lower( _file[ 1 ] ) ) == "dbf"
            push_fmk_dbf_to_server( cur_dir, _file[ 1 ] )
         ENDIF
      ENDIF
   NEXT

   FOR EACH _file in _files
      IF _file[ 5 ] == "D"
         fmk_migrate( cur_dir + hb_ps()() +  _file[ 1 ] )
      ENDIF
   NEXT




FUNCTION push_fmk_dbf_to_server( cur_dir, dbf_name )

   LOCAL nI, _org_id, _pos, _tmp_1, _tmp_2
   LOCAL _year
   LOCAL _curr_year := Year( Date() )

   FOR nI := 1 TO 99
      _org_id := AllTrim( Str( nI, 2 ) )

      FOR _year := 1994 TO _curr_year

         IF _year == _curr_year
            _tmp_2 := ""
         ELSE
            _tmp_2 := SLASH + AllTrim( Str( _year ) )
         ENDIF

         _tmp_1 := Right( Lower( cur_dir ), 3 + Len( _org_id ) + Len( _tmp_2 ) )

         IF _tmp_1 == "kum" + _org_id + _tmp_2
            DO CASE
            CASE At( SLASH + "fin" + SLASH + _tmp_1, Lower( cur_dir ) ) != 0
               _pos := AScan( __fin_fmk_tables, {|x| x[ 1 ] == FILEBASE( Lower( dbf_name ) ) } )
               IF _pos != 0
                  log_write( cur_dir + SLASH + dbf_name + "=> b_year=" + AllTrim( Str( _year ) ) + "  org_id=" +  _org_id + " / " + __fin_fmk_tables[ _pos, 2 ] )
               ENDIF
            END CASE
         ENDIF


/*
   if RIGHT(cur_dir, 3 + LEN(_org_id) ) == "sif" + _org_id
       _sif
   endif
*/

      NEXT

   NEXT

#endif