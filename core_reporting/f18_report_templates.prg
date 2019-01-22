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

STATIC  s_cTemplatesLoc

FUNCTION f18_template_location( cTemplate )

   LOCAL cLoc, aFileList

   IF cTemplate == NIL .AND. s_cTemplatesLoc != NIL
      RETURN s_cTemplatesLoc
   ENDIF

   IF cTemplate == NIL
      cTemplate := "*.*" // ponudice prvi template od 3 opcije
   ENDIF

   // 1) /opt/knowhowERP/template - prvo pogledati u starim template-ovima
   IF is_windows()
      cLoc := "c:" + SLASH + "knowhowERP" + SLASH + "template" + SLASH
   ELSE
      cLoc := SLASH + "opt" + SLASH + "knowhowERP" + SLASH + "template" + SLASH
   ENDIF
   aFileList := Directory( cLoc + cTemplate )
   IF Len( aFileList ) > 0
      s_cTemplatesLoc := cLoc
      IF cTemplate == "*.*"
         s_cTemplatesLoc := cLoc
         RETURN cLoc
      ELSE
         RETURN cLoc + cTemplate
      ENDIF
   ENDIF

   // 2) F18.exe/../template/
   cLoc := f18_exe_path() + f18_template_path()
   aFileList := Directory( cLoc + cTemplate )
   IF Len( aFileList ) > 0
      s_cTemplatesLoc := cLoc
      IF cTemplate == "*.*"
         s_cTemplatesLoc := cLoc
         RETURN cLoc
      ELSE
         RETURN cLoc + cTemplate
      ENDIF
   ENDIF

   // 3) ~/.f18/template
   cLoc := my_home_root() + "template" +  SLASH
   aFileList := Directory( cLoc + cTemplate )
   IF Len( aFileList ) > 0
      s_cTemplatesLoc := cLoc
      IF cTemplate == "*.*"
         s_cTemplatesLoc := cLoc
         RETURN cLoc
      ELSE
         RETURN cLoc + cTemplate
      ENDIF
   ENDIF

   RETURN ""



/*
    Opis: kopira template sa lokacije /knowhowERP/templates => home path
*/

FUNCTION f18_template_copy_to_my_home( cTemplate )

   LOCAL _ret := .F.
   LOCAL _a_source, _a_template
   LOCAL _src_size, _src_date, _src_time
   LOCAL _temp_size, _temp_date, _temp_time
   LOCAL _copy := .F.

   IF !File( my_home() + cTemplate )
      _copy := .T.
   ELSE

      _a_source := Directory( my_home() + cTemplate )
      IF Len( _a_source[ 1 ] ) < 4
         Alert( "file atributi error: " + my_home() + cTemplate )
      ENDIF

      _a_template := Directory( f18_template_location( cTemplate ) )
      IF ValType( _a_template ) == "A" .AND. Len( _a_template ) > 0 .AND. Len( _a_template[ 1 ] ) > 4
         ?E "template location:", f18_template_location(), pp( _a_template[ 1 ] )
      ELSE
         Alert( "file atributi error: " + f18_template_location( cTemplate ) )
      ENDIF

      _src_size := AllTrim( Str( _a_source[ 1, 2 ] ) )
      _src_date := DToS( _a_source[ 1, 3 ] )
      _src_time := _a_source[ 1, 4 ]

      _temp_size := AllTrim( Str( _a_template[ 1, 2 ] ) )
      _temp_date := DToS( _a_template[ 1, 3 ] )
      _temp_time := _a_template[ 1, 4 ]

      IF _temp_date + _temp_time > _src_date + _src_time // provjera vremena
         _copy := .T.
      ENDIF

   ENDIF

   IF _copy
      IF File( f18_template_location(  cTemplate ) )
         FileCopy( f18_template_location( cTemplate ), my_home() + cTemplate )
      ELSE
         MsgBeep( "Fajl template " + cTemplate + "(" + f18_template_location( cTemplate ) + ") ne postoji !?" )
         RETURN _ret
      ENDIF
   ENDIF

   _ret := .T.

   RETURN _ret
