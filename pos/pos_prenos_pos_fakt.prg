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

STATIC cIdPos


/*
-- STATIC FUNCTION GetPm()

   LOCAL cPm
   LOCAL cPitanje

   cPm := cIdPos

  -- cPitanje := my_get_from_ini( "POS", "PrenosGetPm", "0" )
  ----x----- IF ( ( gVrstaRs <> "S" ) .AND. ( cPitanje == "0" ) )
      RETURN ""
   ENDIF


----x-----   IF ( gVrstaRs == "S" ) .OR. ( ( cPitanje == "D" ) .OR. Pitanje(, "Postaviti oznaku prodajnog mjesta? (D/N)", "N" ) == "D" )
      Box(, 1, 30 )
      SET CURSOR ON
      @ box_x_koord() + 1, box_y_koord() + 2 SAY "Oznaka prodajnog mjesta:" GET cPm
      READ
      BoxC()
   ENDIF

   RETURN cPm
*/


FUNCTION PripTOPSFAKT( cIdPartnG )

   aDbf := {}
   AAdd( aDBF, { "IdPos", "C", 2, 0 } )
   AAdd( aDBF, { "IDROBA", "C", 10, 0 } )
   AAdd( aDBF, { "IDPARTNER", "C", Len( cIdPartnG ), 0 } )
   AAdd( aDBF, { "kolicina", "N", 13, 4 } )
   AAdd( aDBF, { "MPC", "N", 13, 4 } )
   AAdd( aDBF, { "STMPC", "N", 13, 4 } )
   // stmpc - kod dokumenta tipa 42 koristi se za iznos popusta !!
   AAdd( aDBF, { "IDTARIFA", "C", 6, 0 } )
   AAdd( aDBF, { "DATUM", "D", 8, 0 } )
   AAdd( aDBF, { "IdVd", "C", 2, 0 } )
   AAdd( aDBF, { "M1", "C", 1, 0 } )

   pos_cre_pom_dbf( aDbf, "TOPSFAKT" )

   SELECT 7000
   USE
   my_use ( "topsfakt", "TOPSFAKT" )
   INDEX ON IdPos + idVd + idPartner + IdRoba + Str( mpc, 13, 4 ) + Str( stmpc, 13, 4 ) TAG ( "1" ) TO ( my_home() + "TOPSFAKT" )
   INDEX ON brisano + "10" TAG "BRISAN"    // TO (my_home()+"ZAKSM")
   SET ORDER TO TAG "1"

   RETURN .T.





/* Stanje2Fakt()
 *     Prenos stanja robe u FAKT
 */

FUNCTION Stanje2Fakt()

   // o_roba()
// o_sifk()
// o_sifv()
// o_partner()
// o_pos_kase()
   o_pos_kumulativne_tabele()

   cIdPos := gIdPos
   dDatOd := CToD( "" )
   dDatDo := Date()
   cIdPartnG := Space( FIELD_LEN_PARTNER_ID )

   SET CURSOR ON

   Box( "#PRENOS STANJA ROBE POS->FAKT", 5, 70 )
   @ box_x_koord() + 2, box_y_koord() + 2 SAY "Prodajno mjesto " GET cIdPos PICT "@!" VALID !Empty( cIdPos ) .OR. p_pos_kase( @cIdPos, 2, 25 )
   @ box_x_koord() + 3, box_y_koord() + 2 SAY "Partner/dost.vozilo " GET cIdPartnG PICT "@!" VALID Empty( cIdPartnG ) .OR. p_partner( @cIdPartnG, 3, 28 )
   @ box_x_koord() + 4, box_y_koord() + 2 SAY "Stanje robe na dan" GET dDatDo
   READ
   ESC_BCR
   BoxC()

   cIdPos := gIdPos

   IF !Empty( cIdPartnG )
      select_o_partner( cIdPartnG )
      cIdPartnG := partn->idfmk
   ELSE
      cIdPartnG := Space( FIELD_LEN_PARTNER_ID )
   ENDIF

   PripTOPSFAKT( cIdPartnG )


   // ------------------------------------------------------------------

   SELECT POS

   // ("2", "IdOdj+idroba+DTOS(Datum)", KUMPATH+"POS")
   SET ORDER TO TAG "2"

   GO TOP

   cIdOdj := Space( 2 )
   nRBr := 0
   SEEK cIdOdj
   // do while !eof()
   // cIdOdj:=IdOdj
   DO WHILE !Eof() .AND. POS->IdOdj == cIdOdj
      nStanje := 0
      nVrijednost := 0
      nUlaz := nIzlaz := 0
      cIdRoba := POS->IdRoba
      nUlaz := nIzlaz := nVrijednost := 0
      SELECT pos
      DO WHILE !Eof() .AND. POS->IdOdj == cIdOdj .AND. POS->IdRoba == cIdRoba
         IF ( !pos_admin() .AND. pos->idpos = "X" ) .OR. ( !Empty( cIdPos ) .AND. IdPos <> cIdPos )
            SKIP
            LOOP
         ENDIF

         IF pos->idvd == "96"
            // otpremnice za robu - zdravo
            SKIP
            LOOP
         ENDIF

         IF POS->idvd $ "16#00"
            nUlaz += POS->Kolicina
            nVrijednost += POS->Kolicina * POS->Cijena
         ELSEIF POS->idvd $ "42#01#IN#NI#96"
            DO CASE
            CASE POS->IdVd == "IN"
               nIzlaz += ( POS->Kolicina - POS->Kol2 )
               nVrijednost -= ( POS->Kol2 - POS->Kolicina ) * POS->Cijena
            CASE POS->IdVd == VD_NIV
               // ne mijenja kolicinu
               nVrijednost := POS->Kolicina * POS->Cijena
            OTHERWISE
               // 42#01
               nIzlaz += POS->Kolicina
               nVrijednost -= POS->Kolicina * POS->Cijena
            ENDCASE
         ENDIF
         SKIP
      ENDDO


      select_o_roba( cIdRoba )
      SELECT topsfakt
      nKolicina := nUlaz - nIzlaz
      cIdRoba := PadR( cIdRoba, Len( topsfakt->idRoba ) )
      cIdPartner := cIdPartnG
      cIdVd := "12"
      IF Round( nKolicina, 4 ) <> 0
         APPEND BLANK
         REPLACE idPos WITH cIdPos
         REPLACE idRoba WITH cIdRoba
         REPLACE kolicina WITH nKolicina
         REPLACE idTarifa WITH roba->idTarifa
         REPLACE mpc WITH pos_get_mpc()
         REPLACE datum WITH dDatDo
         REPLACE idVd WITH cIdVd
         REPLACE idPartner WITH cIdPartner
         REPLACE stMpc WITH 0
         ++nRbr
      ENDIF
      SELECT pos

   ENDDO

   // ------------------------------------------------------------------

   CLOSE ALL

   cLokacija := PadR( "A:\", 40 )
   Box( "#DEFINISANJE LOKACIJE ZA PRENOS DATOTEKE TOPSFAKT", 5, 70 )
   @ box_x_koord() + 2, box_y_koord() + 2 SAY "Datoteka TOPSFAKT je izgenerisana. Broj stavki:" + Str( nRbr, 4 )
   @ box_x_koord() + 4, box_y_koord() + 2 SAY "Lokacija za prenos je:" GET cLokacija
   READ
   IF LastKey() <> K_ESC
      SAVE SCREEN TO cS
      cPom := "copy " + my_home() + "TOPSFAKT.DBF " + Trim( cLokacija ) + "TOPSFAKT.DBF"
      f18_run( cPom )
      cPom := "copy " + my_home() + "TOPSFAKT.CDX " + Trim( cLokacija ) + "TOPSFAKT.CDX"
      f18_run( cPom )
      RESTORE SCREEN FROM cS
   ENDIF
   BoxC()

   CLOSERET

   RETURN
// }
