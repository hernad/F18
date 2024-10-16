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
FUNCTION KatBr()

   IF roba->( FieldPos( "KATBR" ) ) <> 0
      IF !Empty( roba->katbr )
         RETURN " (" + Trim( roba->katbr ) + ")"
      ENDIF
   ENDIF

   RETURN ""
*/

/*
FUNCTION GetRegion()

   LOCAL cRegion := " "
   LOCAL nArr

   nArr := Select()
   SELECT ( F_ROBA )
   IF !Used()
      o_roba()
   ENDIF

   IF ROBA->( FieldPos( "IDTARIFA2" ) <> 0 )
      cRegion := Pitanje( , "Porezi za region (1/2/3) ?", "1", " 123" )
   ENDIF
   SELECT ( nArr )

   RETURN cRegion
*/

/* GetRtmFile(cDefRtm)
 *     Vraca naziv rtm fajla za stampu
 */
FUNCTION GetRtmFile( cDefRtm )

   LOCAL GetList := {}

   aRtm := {}
   AAdd( aRtm, { my_get_from_ini( "DelphiRb", "Rtm1", "", KUMPATH ) } )
   AAdd( aRtm, { my_get_from_ini( "DelphiRb", "Rtm2", "", KUMPATH ) } )
   AAdd( aRtm, { my_get_from_ini( "DelphiRb", "Rtm3", "", KUMPATH ) } )

   // ako nema nista u matrici vrati default
   IF Len( aRtm ) == 0
      RETURN cDefRtm
   ENDIF

   //PRIVATE GetList := {}

   Box(, 6, 30 )
   @ 1 + box_x_koord(), 2 + box_y_koord() GET aRtm[ 1, 1 ]
   @ 2 + box_x_koord(), 2 + box_y_koord() GET aRtm[ 1, 2 ]
   @ 3 + box_x_koord(), 2 + box_y_koord() GET aRtm[ 1, 3 ]
   READ
   BoxC()

   RETURN cRet


FUNCTION pocni_stampu()

   IF !lSSIP99 .AND. !start_print()
      my_close_all_dbf()
      RETURN .F.
   ENDIF

   RETURN .T.


FUNCTION zavrsi_stampu()

   IF !lSSIP99
      my_close_all_dbf()
      RETURN end_print()
   ENDIF

   RETURN .F.



FUNCTION fakt_stamp_txt_dokumenta( cIdFirma, cIdTipDok, cBrDok, lJFill )

   //PRIVATE InPicDEM := fakt_pic_iznos()
   //PRIVATE InPicCDEM := fakt_pic_cijena()

   IF lJFill == nil
      lJFill := .F.
   ENDIF

   IF cIdFirma == nil
      fakt_stdok_pdv()
   ELSE
      fakt_stdok_pdv( cIdFirma, cIdTipDok, cBrDok, lJFill )
   ENDIF

   RETURN .T.

// ------------------------------------------
// fakt_zagl_firma()
// Ispis zaglavlja na izvjestajima
// ------------------------------------------
FUNCTION fakt_zagl_firma()

   ?

   P_12CPI
   U_OFF
   B_OFF
   I_OFF

   ?? "Subjekt:"; U_ON; ?? PadC( Trim( tip_organizacije() ) + " " + Trim( self_organizacija_naziv() ), 39 ); U_OFF
   ?  "Prodajni objekat:"; U_ON; ?? PadC( AllTrim( NazProdObj() ), 30 ) ; U_OFF
   ?  "(poslovnica-poslovna jedinica)"
   ?  "Datum:"; U_ON; ?? PadC( SrediDat( field->DATDOK ), 18 ); U_OFF
   ?
   ?

   RETURN .T.
