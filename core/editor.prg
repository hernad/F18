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
#include "f18_color.ch"


FUNCTION editor( cFile, cText )

   LOCAL oEditor, cScr, cColor

   info_bar( "edit", "<ESC> izlaz iz pregleda dokumenta" )
   cColor := SetColor( F18_COLOR_NORMAL_BW )

   SAVE SCREEN TO cScr
   oEditor := HBEditor():New( "editor", 1, 1, f18_max_rows() -1, f18_max_cols() -1, .F., 120, ;
      4, 1, 1, 1, 1 )

   IF cFile == NIL .and. cText != NIL
      oEditor:LoadText( cText )
   ELSE
     oEditor:LoadFile( cFile )
   ENDIF

   oEditor:Display()
   oEditor:edit()
   RESTORE SCREEN FROM cScr

   SetColor( cColor )
   info_bar( "edit", "")

   RETURN cFile
