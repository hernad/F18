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




FUNCTION P_Destin( cId, cPartId, dx, dy )

   LOCAL GetList := {}
   PRIVATE ImeKol := {}
   PRIVATE Kol := {}
   PRIVATE cLastOznaka := " "
   PRIVATE cIdTek := cPartId
   PRIVATE nArr := Select()


   o_dest_partner( cIdTek )
   //SELECT DEST
   //SET ORDER TO TAG "ID"

   //HSEEK cIdTek + cId

   //SET SCOPE TO cIdTek

   ImeKol := { ;
      { "OZNAKA", {|| OZNAKA },  "OZNAKA"  }, ;
      { "NAZIV", {|| NAZ    },  "NAZ"     }, ;
      { "NAZIV2", {|| NAZ2   },  "NAZ2"    }, ;
      { "PTT", {|| PTT    },  "PTT"     }, ;
      { "MJESTO", {|| MJESTO },  "MJESTO"  }, ;
      { "ADRESA", {|| ADRESA },  "ADRESA"  }, ;
      { "TELEFON", {|| TELEFON },  "TELEFON" }, ;
      { "FAX", {|| FAX    },  "FAX"     }, ;
      { "MOBTEL", {|| MOBTEL },  "MOBTEL"  };
      }
   FOR i := 1 TO Len( ImeKol ); AAdd( Kol, i ); NEXT

   p_sifra( F_DEST, "ID", 10, 70, "Destinacije za:" + cIdTek + "-" + get_partner_naziv( cIdTek ), , , , {| Ch | EdDestBlok( Ch ) },,,, .F. )

   cId := cLastOznaka
   //SET SCOPE TO
   SELECT ( nArr )

   RETURN .T.

// --------------------------------
// key handler
// --------------------------------
FUNCTION EdDestBlok( Ch, cDest )

   LOCAL GetList := {}
   LOCAL nRet := DE_CONT

   DO CASE
   CASE Ch == K_F2  .OR. Ch == K_CTRL_N

      sID       := cIdTek
      sOZNAKA   := IF( Ch == K_CTRL_N, cDest, OZNAKA )
      sNAZ      := IF( Ch == K_CTRL_N, get_partner_naziv( cIdTek ), NAZ )
      sNAZ2     := IF( Ch == K_CTRL_N, get_partner_naziv2( cIdTek ), NAZ2 )
      sPTT      := PTT
      sMJESTO   := MJESTO
      sADRESA   := ADRESA
      sTELEFON  := TELEFON
      sFAX      := FAX
      sMOBTEL   := MOBTEL

      Box(, 11, 75, .F. )
      @ box_x_koord() + 2, box_y_koord() + 2 SAY "Oznaka destinacije" GET sOZNAKA   PICT "@!"
      @ box_x_koord() + 3, box_y_koord() + 2 SAY "NAZIV             " GET sNAZ
      @ box_x_koord() + 4, box_y_koord() + 2 SAY "NAZIV2            " GET sNAZ2
      @ box_x_koord() + 5, box_y_koord() + 2 SAY "PTT broj          " GET sPTT      PICT "@!"
      @ box_x_koord() + 6, box_y_koord() + 2 SAY "Mjesto            " GET sMJESTO   PICT "@!"
      @ box_x_koord() + 7, box_y_koord() + 2 SAY "Adresa            " GET sADRESA   PICT "@!"
      @ box_x_koord() + 8, box_y_koord() + 2 SAY "Telefon           " GET sTELEFON  PICT "@!"
      @ box_x_koord() + 9, box_y_koord() + 2 SAY "Fax               " GET sFAX      PICT "@!"
      @ box_x_koord() + 10, box_y_koord() + 2 SAY "Mobitel           " GET sMOBTEL   PICT "@!"
      READ
      BoxC()
      IF Ch == K_CTRL_N .AND. LastKey() <> K_ESC
         APPEND BLANK
         REPLACE id WITH sid
      ENDIF
      IF LastKey() <> K_ESC
         REPLACE OZNAKA   WITH sOZNAKA, ;
            NAZ      WITH sNAZ, ;
            NAZ2     WITH sNAZ2, ;
            PTT      WITH sPTT, ;
            MJESTO   WITH sMJESTO, ;
            ADRESA   WITH sADRESA, ;
            TELEFON  WITH sTELEFON, ;
            FAX      WITH sFAX, ;
            MOBTEL   WITH sMOBTEL
      ENDIF
      nRet := DE_REFRESH
   CASE Ch == K_CTRL_T
      IF Pitanje(, "Izbrisati stavku ?", "N" ) == "D"
         DELETE
      ENDIF
      nRet := DE_DEL
   CASE Ch == K_ESC .OR. Ch == K_ENTER
      cLastOznaka := DEST->OZNAKA

   ENDCASE

   RETURN nRet




FUNCTION get_partner_naziv( cId )

   LOCAL cRet

   PushWA()
   cRet := find_field_by_id( "partn", cId, "naz" )
   PopWA()

   RETURN cRet


FUNCTION get_partner_naziv2( cId )

   LOCAL cRet

   PushWA()
   cRet := find_field_by_id( "partn", cId, "naz2" )
   PopWA()

   RETURN cRet



// -----------------------------
// get partner naziv + mjesto
// -----------------------------
FUNCTION get_partner_name_mjesto( cIdPartner )

   LOCAL cRet

   PushWA()

   IF !select_o_partner( cIdPartner )
      cRet := "!NOPARTN!"
   ELSE
      cRet := Trim( Left( field->naz, 25 ) ) + " " + Trim( field->mjesto )
   ENDIF

   PopWa()

   RETURN cRet


FUNCTION get_kred_naz( cId )

   LOCAL cRet

   PushWA()
   cRet := find_field_by_id( "kred", cId, "naz" )
   PopWA()

   RETURN cRet


FUNCTION get_rj_naz( cId )

   LOCAL cRet

   PushWA()
   cRet := find_field_by_id( "rj", cId, "naz" )
   PopWA()

   RETURN cRet

FUNCTION get_ld_rj_naz( cId )

   LOCAL cRet

   PushWA()
   cRet := find_field_by_id( "ld_rj", cId, "naz" )
   PopWA()

   RETURN cRet

FUNCTION get_roba_sifradob( cId )

   LOCAL cRet

   PushWA()
   cRet := find_field_by_id( "roba", cId, "sifradob" )
   PopWA()

   RETURN cRet


FUNCTION get_vrstep_naz( cId )

   LOCAL cRet

   PushWA()
   cRet := find_field_by_id( "vrstep", cId, "naz" )
   PopWA()

   RETURN cRet

/*
FUNCTION get_partner_naz_naz2_mjesto()

   LOCAL cVrati
   LOCAL cPom

   cPom := Upper( AllTrim( mjesto ) )
   IF cPom $ Upper( naz ) .OR. cPom $ Upper( naz2 )
      cVrati := Trim( naz ) + " " + Trim( naz2 )
   ELSE
      cVrati := Trim( naz ) + " " + Trim( naz2 ) + " " + Trim( mjesto )
   ENDIF

   RETURN PadR( cVrati, 40 )
*/
