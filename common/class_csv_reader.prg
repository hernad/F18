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


CLASS CsvReader

   DATA STRUCT
   DATA csvname
   DATA memname
   DATA DELIMITER
   DATA wa

   METHOD new()
   METHOD READ()
   METHOD CLOSE()

   PROTECTED:

   METHOD create_mem_dbf()
   METHOD open_csv_as_local_dbf()

ENDCLASS



METHOD CsvReader:New()

   ::memname := "csvimp"
   ::wa := 360

   RETURN self



METHOD CsvReader:close()

   SELECT ( ::wa )
   USE

   RETURN SELF



METHOD CsvReader:read()

   LOCAL _ok := .F.

   IF ::STRUCT == NIL
      MsgBeep( "Struktura zaboravljena !" )
      RETURN _ok
   ENDIF

   IF ::csvname == NIL
      MsgBeep( "A koji fajl da importujem ???" )
      RETURN _ok
   ENDIF

   IF ::DELIMITER == NIL
      ::DELIMITER := ";"
   ENDIF


   ::create_mem_dbf()    // kreiraj i otvori lokalni dbf

   ::open_csv_as_local_dbf()    // otvori csv u dbf

   RETURN _ok



METHOD CsvReader:create_mem_dbf()

   dbCreate( ::memname, ::struct, "ARRAYRDD" )

   RETURN .T.



METHOD CsvReader:open_csv_as_local_dbf()

   SELECT ( ::wa )
   USE ( ::memname ) VIA "ARRAYRDD"

   APPEND FROM ( ::csvname ) DELIMITED
   GO TOP
   SKIP 1

   RETURN .T.
