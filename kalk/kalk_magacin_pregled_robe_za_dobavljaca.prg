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


FUNCTION kalk_magacin_pregled_robe_za_dobavljaca()

   // O_SIFK
   // O_SIFV
   // O_ROBA
   // O_PARTN
   // -- o_kalk()

   // SET RELATION TO idroba INTO ROBA
   LOCAL cIdFirma := self_organizacija_id()
   LOCAL cIdRoba    := Space( FIELD_ROBA_ID_LENGTH )
   LOCAL cIdPartner := Space( FIELD_LEN_PARTNER_ID )
   LOCAL dOd := CToD( "" )
   LOCAL dDo := Date()
   LOCAL cFilt
   LOCAL GetList := {}


   Box( "#PREGLED ROBE ZA DOBAVLJACA", 6, 70 )

   @ box_x_koord() + 2, box_y_koord() + 2 SAY8 "Dobavljač           " GET cIdPartner VALID P_Partner( @cIdPartner ) PICT "@!"
   @ box_x_koord() + 3, box_y_koord() + 2 SAY8 "Artikal (prazno-svi)" GET cIdRoba VALID Empty( cIdRoba ) .OR. P_Roba( @cIdRoba ) PICT "@!"

   @ box_x_koord() + 4, box_y_koord() + 2 SAY8 "Za period od" GET dOd
   @ box_x_koord() + 4, Col() + 2 SAY "do" GET dDo
   // @ box_x_koord() + 5, box_y_koord() + 2 SAY "Koliko prethodnih sezona gledati? (0/1/2/3)" GET nPrSez VALID nPrSez < 4 PICT "9"
   READ

   ESC_BCR
   BoxC()

   IF Empty( cIdRoba )
      lPromVP := ( Pitanje(, "Prikazati stanje samo za artikle sa promjenama(ulaz/izlaz) u VP? (D/N)", "D" ) == "D" )
   ENDIF


   find_kalk_by_mkonto_idroba( cIdFirma, NIL, cIdRoba, "idroba,datdok", .F. )

   cFilt := "DATDOK>=" + dbf_quote( dOd ) + ".and. DATDOK<=" + dbf_quote( dDo )

   IF !Empty( cIdRoba )
      cFilt += ".and. IDROBA==" + dbf_quote( cIdRoba )
   ENDIF

   SET FILTER TO &cFilt
   GO TOP


   nSlog := 0
   nUkupno := RECCOUNT2()

   IF Empty( cIdRoba )

      // kao lager lista
      // ---------------
      START PRINT CRET
      ?

      gnLMarg := 0; gTabela := 1; gOstr := "D"
      PRIVATE cRoba := "", nUlaz := 0, nStanje := 0, lImaVP := .F., nNC := 0, nVPC := 0

      aKol := { { "ROBA", {|| cRoba    }, .F., "C", 56, 0, 1, 1 }, ;
         { "Ulaz (svi", {|| nUlaz    }, .F., "N", 12, 3, 1, 2 }, ;
         { "objekti)", {|| "#"      }, .F., "C", 12, 0, 2, 2 }, ;
         { "Stanje u", {|| IF( lPromVP .AND. !lImaVP, "  n e m a   ", Str( nStanje, 12, 3 ) )  }, .F., "C", 12, 0, 1, 3 }, ;
         { "veleprod.", {|| "#"      }, .F., "C", 12, 0, 2, 3 }, ;
         { "Poslj.NC", {|| nNC      }, .F., "N-", 10, 3, 1, 4 }, ;
         { "VPC", {|| nVPC     }, .F., "N-", 10, 2, 1, 5 } }

      ?? Space( gnLMarg )
      ??U "KALK: Izvještaj na dan", Date()
      ? Space( gnLMarg ); IspisFirme( "" )
      ?
      ?U "PREGLED ROBE OD DOBAVLJAČA ZA PERIOD OD", dOD, "DO", dDo
      select_o_partner( cIdPartner )
      ?U "DOBAVLJAČ:", cIdPartner, "-", PARTN->naz
      SELECT kalk
      ?
      print_lista_2( aKol, {|| NIL },, gTabela,, ;
         ,, ;
         {|| FForPRD1( cIdPartner ) }, iif( gOstr == "D",, - 1 ),,,,, )
      FF
      ENDPRINT
   ELSE
      // kao kartica
      // -----------
      START PRINT CRET

      gnLMarg := 0; gTabela := 1; gOstr := "D"
      PRIVATE cDokum := "", nUlaz := 0, nUlaz2 := 0, nIzlaz := 0, nStanje := 0

      aKol := { { "Dokument", {|| cDokum       }, .F., "C", 14, 0, 1, 1 }, ;
         { "Datum", {|| DToC( DATDOK ) }, .F., "C",  8, 0, 1, 2 }, ;
         { "Ulaz od", {|| nUlaz        }, .T., "N-", 12, 3, 1, 3 }, ;
         { "zadanog", {|| "#"          }, .F., "C", 12, 0, 2, 3 }, ;
         { "dobavljaca", {|| "#"          }, .F., "C", 12, 0, 3, 3 }, ;
         { "Ulaz", {|| nUlaz2       }, .T., "N", 12, 3, 1, 4 }, ;
         { "Izlaz", {|| nIzlaz       }, .T., "N", 12, 3, 1, 5 }, ;
         { "Stanje", {|| nStanje      }, .F., "N", 12, 3, 1, 6 } }

      ?? Space( gnLMarg ); ?? "KALK: Izvjestaj na dan", Date()
      ? Space( gnLMarg ); IspisFirme( "" )
      ?
      ?U "PREGLED ROBE OD DOBAVLJAČA ZA PERIOD OD", dOD, "DO", dDo
      select_o_partner( cIdPartner )
      ?U "DOBAVLJAČ:", cIdPartner, "-", PARTN->naz
      select_o_roba( cIdRoba )
      ? "ROBA:", cIdRoba, "-", Left( ROBA->naz, 40 )
      SELECT kalk
      ?
      print_lista_2( aKol, {|| NIL },, gTabela,, ;
         ,, ;
         {|| FForPRD2( cIdPartner ) }, iif( gOstr == "D",, - 1 ),,,,, )
      FF
      ENDPRINT
   ENDIF

   my_close_all_dbf()

   RETURN .T.

/*
// Prikaz toka filterisanja glavne baze
FUNCTION TekRec2()

   nSlog++
   @ box_x_koord() + 1, box_y_koord() + 2 SAY PadC( AllTrim( Str( nSlog ) ) + "/" + AllTrim( Str( nUkupno ) ), 20 )
   @ box_x_koord() + 2, box_y_koord() + 2 SAY "Obuhvaceno: " + Str( 0 )

   RETURN ( nil )


// Predvidjeno za dodatnu obradu slogova - koristi je print_lista_2()
FUNCTION FSvakiPRD()
   RETURN

*/

// Obrada podataka - koristi je print_lista_2()
// return .t. ako se slog prikazuje, .f. - ako se ne prikazuje u tabeli
STATIC FUNCTION FForPRD1( cIdPartner )

   LOCAL cIdR
   LOCAL dLastNab

   select_o_roba( kalk->idroba )

   SELECT KALK
   cRoba  := IDROBA + "-" + Left( ROBA->naz, 40 ) + "(" + ROBA->jmj + ")"
   cIdR   := idroba
   nUlaz  := nStanje := 0
   lImaVP := .F.
   lIzProsleGod := .F.
   nNC := 0
   nVPC := ROBA->vpc
   dLastNab := CToD( "" )

   DO WHILE !Eof() .AND. idroba == cIdR
      IF mu_i == "1" .AND. !( idvd $ "12#22#94" ) .AND. idpartner == cIdPartner
         nUlaz += kolicina - gkolicina - gkolicin2
         IF datdok > dLastNab
            nNC := fcj2
            dLastNab := datdok
         ENDIF
      ENDIF
      IF pu_i == "1" .AND. idpartner == cIdPartner
         nUlaz += kolicina - gkolicina - gkolicin2
         IF datdok > dLastNab
            nNC := fcj2
            dLastNab := datdok
         ENDIF
      ENDIF

      IF !Empty( mkonto )
         IF mu_i == "1" .AND. !( idvd $ "12#22#94" )
            nStanje += ( kolicina - gkolicina - gkolicin2 )
            lImaVP := .T.
         ELSEIF mu_i == "5"
            nStanje -= ( kolicina )
            lImaVP := .T.
         ELSEIF mu_i == "1" .AND. ( idvd $ "12#22#94" )    // povrat
            nStanje -= ( - kolicina )
            lImaVP := .T.
         ELSEIF mu_i == "8"
         ENDIF
      ENDIF

      SKIP 1
   ENDDO

   SKIP -1

   // IF nUlaz = 0 .AND. nPrSez > 0
   // lIzProsleGod := ImaUProsGod( nPrSez, cIdPartner, cIdR, @nNC )
   // ENDIF

   RETURN ( nUlaz <> 0 .OR. lIzProsleGod )


// Obrada podataka - koristi je print_lista_2()
// return .t. ako se slog prikazuje, .f. - ako se ne prikazuje u tabeli
STATIC FUNCTION FForPRD2( cIdPartner )

   LOCAL cIdR

   select_o_roba( kalk->idroba )
   SELECT KALK
   cDokum := idfirma + "-" + idvd + "-" + brdok
   nUlaz := nUlaz2 := nIzlaz := 0

   IF mu_i == "1" .AND. !( idvd $ "12#22#94" ) .AND. idpartner == cIdPartner
      nUlaz += kolicina - gkolicina - gkolicin2
   ENDIF
   IF pu_i == "1" .AND. idpartner == cIdPartner
      nUlaz += kolicina - gkolicina - gkolicin2
   ENDIF

   IF !Empty( mkonto )
      IF mu_i == "1" .AND. !( idvd $ "12#22#94" )
         nUlaz2 := ( kolicina - gkolicina - gkolicin2 )
      ELSEIF mu_i == "5"
         nIzlaz := ( kolicina )
      ELSEIF mu_i == "1" .AND. ( idvd $ "12#22#94" )    // povrat
         nIzlaz := ( - kolicina )
      ELSEIF mu_i == "8"
         nUlaz2 := nIzlaz := -kolicina
      ENDIF
   ELSE
      IF pu_i == "1"
         nUlaz2 := ( kolicina - GKolicina - GKolicin2 )
      ELSEIF pu_i == "5"  .AND. !( idvd $ "12#13#22" )
         nIzlaz := ( kolicina )
      ELSEIF pu_i == "I"
         nIzlaz := ( gkolicin2 )
      ELSEIF pu_i == "5"  .AND. ( idvd $ "12#13#22" )    // povrat
         nUlaz2 := ( - kolicina )
      ENDIF
   ENDIF

   nStanje += ( nUlaz2 - nIzlaz )

   RETURN .T.


/*
FUNCTION ImaUProsGod( nPrSez, cIdPartner, cIdRoba, nNC )

   LOCAL lIma
   LOCAL cPom
   LOCAL cSez
   LOCAL nUlaz
   LOCAL i
   LOCAL dLastNab
   LOCAL nArr

   lIma := .F.
   nUlaz := 0
   dLastNab := CToD( "" )
   nArr := Select()
   FOR i := 1 TO nPrSez
      cSez := Str( Val( tekuca_sezona() ) -i, 4 )
      cPom := "KALK" + cSez
      IF SELECT( cPom ) = 0
         SELECT 0
         USE ( KUMPATH + cSez + SLASH + "KALK.DBF" ) Alias ( cPom )
      ELSE
         SELECT ( Select( cPom ) )
      ENDIF
      SET ORDER TO TAG "PARM"
      SEEK cIdPartner + cIdRoba + "1"
      DO WHILE !Eof() .AND. idPartner + idRoba + mu_i == cIdPartner + cIdRoba + "1"
         IF !( idvd $ "12#22#94" )
            nUlaz += kolicina - gkolicina - gkolicin2
            IF datdok > dLastNab
               nNC := fcj2
               dLastNab := datdok
            ENDIF
         ENDIF
         SKIP 1
      ENDDO
      SET ORDER TO TAG "PARP"
      SEEK cIdPartner + cIdRoba + "1"
      DO WHILE !Eof() .AND. idPartner + idRoba + pu_i == cIdPartner + cIdRoba + "1"
         nUlaz += kolicina - gkolicina - gkolicin2
         IF datdok > dLastNab
            nNC := fcj2
            dLastNab := datdok
         ENDIF
         SKIP 1
      ENDDO
      IF nUlaz <> 0
         lIma := .T.
         EXIT
      ENDIF
   NEXT
   SELECT ( nArr )

   RETURN lIma

*/
