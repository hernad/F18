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


FUNCTION get_kalk_attr_opis( dok, from_server )

   LOCAL oAttr := DokAttr():new( "kalk", F_KALK_ATTR )

   oAttr:lGetAttrFromDbf := ( from_server == .F. )
   oAttr:cAttr := "opis"
   oAttr:workarea := F_KALK_ATTR
   oAttr:hAttrId := dok

   RETURN oAttr:get_attr()


// --------------------------------------------------
// get atribut rok
// --------------------------------------------------
FUNCTION get_kalk_attr_rok( dok, from_server )

   LOCAL oAttr := DokAttr():new( "kalk", F_KALK_ATTR )

   oAttr:lGetAttrFromDbf := ( from_server == .F. )
   oAttr:cAttr := "rok"
   oAttr:hAttrId := dok

   RETURN oAttr:get_attr()
