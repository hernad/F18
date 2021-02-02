/*
 * This file is part of the bring.out FMK, a free and open source
 * accounting software suite,
 * Copyright (c) 1996-2011 by bring.out doo Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including FMK specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_FMK.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */


#include "f18.ch"



FUNCTION vise_kalk_dok_u_pripremi( cIdd )

/* TODO: ne trebamo ovo vise ?!
   IF field->idPartner + field->brFaktP + field->idKonto + field->idKonto2 <> cIdd
      SET DEVICE TO SCREEN
      Beep( 2 )
      Msg( "Unutar kalkulacije se pojavilo vise dokumenata !", 6 )
      SET DEVICE TO PRINTER
   ENDIF
*/

   RETURN .T.

FUNCTION show_more_info( cPartner, dDatum, cFaktura, cMU_I )

   LOCAL cRet := ""
   LOCAL cMIPart := ""
   LOCAL cTip := ""

   IF !Empty( cPartner )

      cMIPart := AllTrim( get_partner_naziv( cPartner ) )

      IF cMU_I == "1"
         cTip := "dob.:"
      ELSE
         cTip := "kup.:"
      ENDIF

      cRet := DToC( dDatum )
      cRet += ", "
      cRet += "br.dok: "
      cRet += AllTrim( cFaktura )
      cRet += ", "
      cRet += cTip
      cRet += " "
      cRet += cPartner
      cRet += " ("
      cRet += cMIPart
      cRet += ")"

   ENDIF

   RETURN cRet




/*
 *     Funkcija vraca dobavljaca cIdRobe na osnovu polja roba->dob
 *   param: cIdRoba
 *   param: nRazmak - razmak prije ispisa dobavljaca
 *   param: lNeIspisujDob - ako je .t. ne ispisuje "Dobavljac:"
 *  return cVrati - string "dobavljac: xxxxxxx"
 */

FUNCTION PrikaziDobavljaca( cIdRoba, nRazmak, lNeIspisujDob )

   IF lNeIspisujDob == NIL
      lNeIspisujDob := .T.
   ELSE
      lNeIspisujDob := .F.
   ENDIF

   cIdDob := get_roba_sifradob( cIdRoba )

   IF lNeIspisujDob
      cVrati := Space( nRazmak ) + "Dobavljac: " + Trim( cIdDob )
   ELSE
      cVrati := Space( nRazmak ) + Trim( cIdDob )
   ENDIF

   IF !Empty( cIdDob )
      RETURN cVrati
   ELSE
      cVrati := ""
      RETURN cVrati
   ENDIF

FUNCTION PrikTipSredstva( cKalkTip )

   IF !Empty( cKalkTip )
      ? "Uslov po tip-u: "
      IF cKalkTip == "D"
         ?? cKalkTip, ", donirana sredstva"
      ELSEIF cKalkTip == "K"
         ?? cKalkTip, ", kupljena sredstva"
      ELSE
         ?? cKalkTip, ", --ostala sredstva"
      ENDIF
   ENDIF

   RETURN


FUNCTION g_obj_naz( cKto )

   LOCAL cVal := ""
   LOCAL nTArr

   nTArr := Select()

   kalk_o_objekti()
   SELECT objekti
   SET ORDER TO TAG "idobj"
   GO TOP
   SEEK cKto

   IF Found()
      cVal := objekti->naz
   ENDIF

   SELECT ( nTArr )

   RETURN cVal
