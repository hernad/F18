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
#include "f18_ver.ch"

STATIC s_cIniSection := "DBF_version"


FUNCTION read_dbf_version_from_config()

   LOCAL hIniParams
   LOCAL _current_dbf_ver, _new_dbf_ver
   LOCAL s_cIniSection := "DBF_version"
   LOCAL hRet

   hIniParams := hb_Hash()
   hIniParams[ "major" ] := "0"
   hIniParams[ "minor" ] := "0"
   hIniParams[ "patch" ] := "0"

   hRet := hb_Hash()

   IF !f18_ini_config_read( s_cIniSection, @hIniParams, .F. )
      ?E "problem sa ini_params " + s_cIniSection
   ENDIF
   _current_dbf_ver := get_version_num( hIniParams[ "major" ], hIniParams[ "minor" ], hIniParams[ "patch" ] )
   _new_dbf_ver     := get_version_num( F18_DBF_VER_MAJOR, F18_DBF_VER_MINOR, F18_DBF_VER_PATCH )

   ?E "current dbf version:" + Str( _current_dbf_ver )
   ?E "    F18 dbf version:" + Str( _new_dbf_ver )

   hRet[ "current" ] := _current_dbf_ver
   hRet[ "new" ]     := _new_dbf_ver

   RETURN hRet



FUNCTION write_dbf_version_to_ini_conf()

   LOCAL hIniParams, cMsg, cDbfVer

   hIniParams := hb_Hash()
   hIniParams[ "major" ] := "0"
   hIniParams[ "minor" ] := "0"
   hIniParams[ "patch" ] := "0"


   hIniParams[ "major" ] := F18_DBF_VER_MAJOR
   hIniParams[ "minor" ] := F18_DBF_VER_MINOR
   hIniParams[ "patch" ] := F18_DBF_VER_PATCH

   cDbfVer := AllTrim( Str( F18_DBF_VER_MAJOR ) ) + "." + AllTrim( Str( F18_DBF_VER_MINOR ) ) + "." + AllTrim( Str( F18_DBF_VER_PATCH ) )

   IF !f18_ini_config_write( s_cIniSection, @hIniParams, .F. )
      cMsg := "ini_dbf: problem write dbf verzija: " + cDbfVer
      ?E cMsg
      error_bar( "ini_dbf:" + my_server_params()[ "database" ], cMsg )
   ELSE
      info_bar( "ini_dbf:" + my_server_params()[ "database" ], "write dbf verzija: " + cDbfVer )
   ENDIF

   RETURN .T.
