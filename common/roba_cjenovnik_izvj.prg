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

/*
FUNCTION CjenR()

   LOCAL cIniName

   PRIVATE cKomLin

   IF Pitanje(, "Formiranje cjenovnika ?", "N" ) == "N"
      RETURN DE_CONT
   ENDIF

   SELECT ROBA
  -- SELECT ( F_BARKOD )

   IF !Used()
      o_barkod()
   ENDIF
   SELECT BARKOD
   zapp()

   SELECT roba
   GO TOP
   MsgO( "Priprema barkod.dbf za cjen" )

   cIniName := EXEPATH + 'ProIzvj.ini'

   // Iscita var Linija1 iz FMK.INI/KUMPATH u PROIZVJ.INI
   UzmiIzIni( cIniName, 'Varijable', 'Linija1', my_get_from_ini( "Zaglavlje", "Linija1", self_organizacija_naziv(), KUMPATH ), 'WRITE' )
   UzmiIzIni( cIniName, 'Varijable', 'Linija2', my_get_from_ini( "Zaglavlje", "Linija2", "-", KUMPATH ), 'WRITE' )
   UzmiIzIni( cIniName, 'Varijable', 'Linija3', my_get_from_ini( "Zaglavlje", "Linija3", "-", KUMPATH ), 'WRITE' )
   UzmiIzIni( cIniName, 'Varijable', 'Linija4', my_get_from_ini( "Zaglavlje", "Linija4", "-", KUMPATH ), 'WRITE' )
   UzmiIzIni( cIniName, 'Varijable', 'Linija5', my_get_from_ini( "Zaglavlje", "Linija5", "-", KUMPATH ), 'WRITE' )
   UzmiIzIni( cIniName, 'Varijable', 'CjenBroj', my_get_from_ini( "Zaglavlje", "CjenBroj", "-", KUMPATH ), 'WRITE' )
   cCjenIzbor := my_get_from_ini( "Zaglavlje", "CjenIzbor", " ", KUMPATH )

   DO WHILE !Eof()
      SELECT BARKOD
      APPEND BLANK
      REPLACE ID       WITH  roba->id, ;
         NAZIV    WITH  Trim( Left( ROBA->naz, 40 ) ) + " (" + Trim( ROBA->jmj ) + ")", ;
         VPC      WITH  ROBA->vpc, ;
         MPC      WITH  ROBA->mpc
      SELECT roba
      SKIP
   ENDDO
   MsgC()

   my_close_all_dbf()

   // Izbor cjenovnika  ( /M/V)

   PRIVATE cCjenBroj := Space( 15 )
   PRIVATE cCjenIzbor := " "

   BOX (, 4, 40 )
   @ box_x_koord() + 1, box_y_koord() + 2 SAY "Cjenovnik broj : " GET cCjenBroj
   @ box_x_koord() + 3, box_y_koord() + 2 SAY "Cjenovnik ( /M/V) : " GET cCjenIzbor VALID cCjenIzbor $ " MV"
   @ box_x_koord() + 4, box_y_koord() + 2 SAY "M - sa MPC,V - sa VPC,prazno - sve"
   READ
   BoxC()

   UzmiIzIni( cIniName, 'Varijable', 'CjenBroj', cCjenBroj, 'WRITE' )
   UzmiIzIni( KUMPATH + 'FMK.INI', 'Zaglavlje', 'CjenBroj', cCjenBroj, 'WRITE' )
   UzmiIzIni( KUMPATH + 'FMK.INI', 'Zaglavlje', 'CjenIzbor', cCjenIzbor, 'WRITE' )

   IF LastKey() == K_ESC
      RETURN DE_CONT
   ENDIF

   f18_rtm_print( "cjen", "barkod", "id" )

   RETURN DE_CONT

*/