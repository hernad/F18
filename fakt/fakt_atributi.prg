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



FUNCTION get_fakt_attr_opis( hId, lFromServer )

   LOCAL oAttr := DokAttr():new( "fakt", F_FAKT_ATTR )
   oAttr:lGetAttrFromDbf := ( lFromServer == .F. )
   oAttr:cAttr := "opis"
   oAttr:hAttrId := hId

   RETURN oAttr:get_attr()



FUNCTION get_fakt_attr_ref( dok, from_server )

   LOCAL oAttr := DokAttr():new( "fakt", F_FAKT_ATTR )

   oAttr:lGetAttrFromDbf := ( from_server == .F. )
   oAttr:cAttr := "ref"
   oAttr:hAttrId := dok

   RETURN oAttr:get_attr()


FUNCTION get_fakt_attr_lot( dok, from_server )

   LOCAL oAttr := DokAttr():new( "fakt", F_FAKT_ATTR )

   oAttr:lGetAttrFromDbf := ( from_server == .F. )
   oAttr:cAttr := "lot"
   oAttr:hAttrId := dok

   RETURN oAttr:get_attr()
