/*
 * This file is part of the bring.out FMK, a free and open source
 * accounting software suite,
 * Copyright (c) 1994-2018 by bring.out d.o.o Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including knowhow ERP specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_knowhow.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */

#include "f18.ch"

FUNCTION cre_fin_mat( ver )

   LOCAL aDbf
   LOCAL _table_name
   LOCAL _alias
   LOCAL _created

/*
Harbour extended Field Types

 Type Short
 Code Name Width (Bytes) Description
 ---- ------- ----------------- -------------------------------------------------------------------
 D Date 3, 4 or 8 Date
 M Memo 4 or 8 Memo
 + AutoInc 4 Auto increment
 = ModTime 8 Last modified date & time of this record
 ^ RowVers 8 Row version number; modification count of this record
 @ DayTime 8 Date & Time
 I Integer 1, 2, 3, 4 or 8 Signed Integer ( Width : )" },;
 T Time 4 or 8 Only time (if width is 4 ) or Date & Time (if width is 8 ) (?)
 V Variant 3, 4, 6 or more Variable type Field
 Y Currency 8 64 bit integer with implied 4 decimal
 B Double 8 Floating point / 64 bit binary
 */

   aDbf := {}
   AAdd( aDBf, { "IDFIRMA", "C",   2,  0 } )
   AAdd( aDBf, { "IDKONTO", "C",   7,  0 } )
   AAdd( aDBf, { "IDKONTO2", "C",   7,  0 } )
   AAdd( aDBf, { "IDTARIFA", "C",   6,  0 } )
   AAdd( aDBf, { "IDPARTNER", "C",   6,  0 } )
   AAdd( aDBf, { 'IDZADUZ', 'C',   6,  0 } )
   AAdd( aDBf, { "IDVD", "C",   2,  0 } )
   AAdd( aDBf, { "BRDOK", "C",   8,  0 } )
   AAdd( aDBf, { "DATDOK", "D",   8,  0 } )
   AAdd( aDBf, { "BRFAKTP", "C",  10,  0 } )
   AAdd( aDBf, { "DATFAKTP", "D",   8,  0 } )
   AAdd( aDBf, { "DATKURS", "D",   8,  0 } )
   AAdd( aDBf, { 'RABAT', 'B',  8,  8 } )
   AAdd( aDBf, { 'PREVOZ', 'B',  8,  8 } )
   AAdd( aDBf, { 'CARDAZ', 'B',  8,  8 } )
   AAdd( aDBf, { 'BANKTR', 'B',  8,  8 } )
   AAdd( aDBf, { 'SPEDTR', 'B',  8,  8 } )
   AAdd( aDBf, { 'ZAVTR', 'B',  8,  8 } )
   AAdd( aDBf, { 'VPVSAP', 'B',  8,  8 } )
   AAdd( aDBf, { 'PRUCMP', 'B',  8,  8 } )
   AAdd( aDBf, { 'PORPOT', 'B',  8,  8 } )
   AAdd( aDBf, { "FV", "B",  8,  8 } )
   AAdd( aDBf, { "GKV", "B",  8,  8 } )
   AAdd( aDBf, { "GKV2", "B",  8,  8 } )
   AAdd( aDBf, { "TR1", "B",  8,  8 } )
   AAdd( aDBf, { "TR2", "B",  8,  8 } )
   AAdd( aDBf, { "TR3", "B",  8,  8 } )
   AAdd( aDBf, { "TR4", "B",  8,  8 } )
   AAdd( aDBf, { "TR5", "B",  8,  8 } )
   AAdd( aDBf, { "TR6", "B",  8,  8 } )
   AAdd( aDBf, { "NV", "B",  8,  8 } )
   AAdd( aDBf, { "RABATV", "B",  8,  8 } )
   AAdd( aDBf, { "POREZV", "B",  8,  8 } )
   AAdd( aDBf, { "MARZA", "B",  8,  8 } )
   AAdd( aDBf, { "VPV", "B",  8,  8 } )
   AAdd( aDBf, { "MPV", "B",  8,  8 } )
   AAdd( aDBf, { "MARZA2", "B",  8,  8 } )
   AAdd( aDBf, { "POREZ", "B",  8,  10 } )
   AAdd( aDBf, { "POREZ2", "B",  8,  8 } )
   AAdd( aDBf, { "POREZ3", "B",  8,  8 } )
   AAdd( aDBf, { "MPVSAPP", "B",  8,  8 } )
   AAdd( aDBf, { "IDROBA", "C",  10,  0 } )
   AAdd( aDBf, { "KOLICINA", "B",  8,  8 } )
   AAdd( aDBf, { "GKol", "B",  8,  8 } )
   AAdd( aDBf, { "GKol2", "B",  8,  8 } )
   AAdd( aDBf, { "PORVT", "B",  8,  8 } )
   AAdd( aDBf, { "UPOREZV", "B",  8,  8 } )
   AAdd( aDBf, { "K1", "C",   1,  0 } )
   AAdd( aDBf, { "K2", "C",   1,  0 } )

   _alias := "FINMAT"
   _table_name := "finmat"

   IF ver[ "current" ] > 0 .AND. ver[ "current" ] < 020104 // 2.1.2 - rbr numeric
      f18_delete_dbf( "finmat" )
   ENDIF

   IF_NOT_FILE_DBF_CREATE

   // 0.9.1
   IF ver[ "current" ] > 0 .AND. ver[ "current" ] < 0901
      modstru( { "*" + _table_name, "A K1 C 1 0", "A K2 C 1 0" } )
   ENDIF

   CREATE_INDEX( "1", "idFirma+IdVD+BRDok", _alias )

   RETURN .T.
