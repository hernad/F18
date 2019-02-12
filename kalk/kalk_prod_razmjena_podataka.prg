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


FUNCTION prenos_fakt_kalk_prodavnica()

   PRIVATE Opc := {}
   PRIVATE opcexe := {}

   AAdd( Opc, "1. fakt 13 -> kalk 11 otpremnica maloprodaje        " )
   AAdd( opcexe, {||  fakt_13_kalk_11() } )

   AAdd( Opc, "2. fakt 11 -> kalk 41 racun maloprodaje" )
   AAdd( opcexe, {||  fakt_11_kalk_41()  } )

   AAdd( Opc, "3. fakt 11 -> kalk 42 paragon" )
   AAdd( opcexe, {||  fakt_11_kalk_42()  } )

   AAdd( Opc, "4. fakt 11 -> kalk 11 zaduzenje diskonta" )
   AAdd( opcexe, {||  fakt_11_kalk_prenos_11()  } )

   AAdd( Opc, "5. fakt 01 -> kalk 81 doprema u prod" )
   AAdd( opcexe, {||  fakt_01_kalk_81() } )

   AAdd( Opc, "6. fakt 13 -> kalk 80 prenos iz cmag. u prodavnicu" )
   AAdd( opcexe, {||  fakt_13_kalk_80()  } )
   // AAdd( Opc, "7. fakt 15 -> kalk 15 izlaz iz MP putem VP" )
   // AAdd( opcexe, {||  fakt_15_kalk_15() } )
   PRIVATE Izbor := 1
   f18_menu_sa_priv_vars_opc_opcexe_izbor( "fkpr" )
   my_close_all_dbf()

   RETURN .T.



FUNCTION fakt_11_kalk_prenos_11()

   LOCAL cIdFirma := self_organizacija_id()
   LOCAL cIdTipDok := "11"
   LOCAL cBrDok := Space( 8 )
   LOCAL cBrKalk := Space( 8 )
   LOCAL dFaktOd := Date() - 10
   LOCAL dFaktDo := Date()
   LOCAL cArtPocinju := Space( 10 )
   LOCAL nLeftArt := 0
   LOCAL dDatKalk, cIdKonto, cIdKonto2, cIdZaduz, cIdZaduz2, cSabirati, cCjenSif
   LOCAL nX
   LOCAL cFaktBrDokumenti := Space( 150 ), cFilterBrDok
   LOCAL nPos, aDokumenti
   LOCAL aGetList := {}

   o_kalk_pripr()
  // o_koncij()
   // o_kalk()
   // o_roba()
   //o_konto()
  // o_partner()
  // o_tarifa()

   //o_fakt_dbf()

   SET ORDER TO TAG "7" // idfirma + DTOS(datdok)

   dDatKalk := Date()

   cIdKonto := PadR( "1330", 7 )
   cIdKonto2 := PadR( "1320", 7 )

   cIdZaduz2 := Space( 6 )
   cIdZaduz := Space( 6 )

   cSabirati := gAutoCjen
   cCjenSif := "N"


   kalk_set_brkalk_za_idvd( "11", @cBrKalk )

   Box(, 15, 70 )


   DO WHILE .T.

      nRBr := 0
      nX := 1

      @ box_x_koord() + nX++, box_y_koord() + 2   SAY "Broj kalkulacije 11 -" GET cBrKalk PICT "@!"
      @ box_x_koord() + nX++, Col() + 2 SAY "Datum:" GET dDatKalk
      @ box_x_koord() + nX++, box_y_koord() + 2  SAY8 "            Magacinski konto razdužuje:" GET cIdKonto2 PICT "@!" VALID P_Konto( @cIdKonto2 )
      @ box_x_koord() + nX++, box_y_koord() + 2  SAY8 "Prodavnički konto (diskonto) zadužuje :" GET cIdKonto  PICT "@!" VALID P_Konto( @cIdKonto )

      cFaktIdFirma := cIdFirma

      nX++

      @ box_x_koord() + nX++, box_y_koord() + 2 SAY "Brojevi dokumenata (BRDOK1;BRDOK2;)" GET cFaktBrDokumenti PICT "@!S20"
      READ
      IF LastKey() == K_ESC
         EXIT
      ENDIF


      IF Empty( cFaktBrDokumenti )
         @ box_x_koord() + nX, box_y_koord() + 2 SAY "Fakture tipa 11 u periodu od" GET dFaktOd
         @ box_x_koord() + nX++, Col() + 1 SAY "do" GET dFaktDo
      ENDIF

      @ box_x_koord() + nX++, box_y_koord() + 2 SAY8 "Uzimati MPC iz šifarnika (D/N) ?" GET cCjenSif VALID cCjenSif $ "DN" PICT "@!"
      @ box_x_koord() + nX++, box_y_koord() + 2 SAY8 "Sabirati iste artikle (D/N) ?" GET cSabirati VALID cSabirati $ "DN" PICT "@!"
      @ box_x_koord() + nX++, box_y_koord() + 2 SAY8 "Uslov za artikle koji počinju sa:" GET cArtPocinju

      READ
      IF LastKey() == K_ESC
         EXIT
      ENDIF

      //SELECT fakt
      //SET ORDER TO TAG "1"
      //GO TOP

      //SEEK cFaktIdFirma + cIdTipDok
      seek_fakt( cFaktIdFirma, cIdTipDok )

      cArtPocinju := Trim( cArtPocinju )
      nLeftArt := Len( cArtPocinju )

      IF !Empty( cFaktBrDokumenti )
         cFilterBrDok := Parsiraj( cFaktBrDokumenti, "BRDOK" )
         SET FILTER TO &cFilterBrDok
         GO TOP
      ELSE
         cFilterBrDok := ".t."
      ENDIF

      MsgO( "Generacija podataka: " + cFaktIdFirma + "-" + cIdTipDok )

      aDokumenti := {}
      DO WHILE !Eof() .AND. cFaktIdFirma + cIdTipDok == field->IdFirma + field->IdTipDok


         IF cFilterBrDok == ".t."
            IF fakt->datdok < dFaktOd .OR. fakt->datdok > dFaktDo // datumska provjera
               SKIP
               LOOP
            ENDIF
         ENDIF


         IF nLeftArt > 0 .AND. Left( fakt->idroba, nLeftArt ) != cArtPocinju
            SKIP
            LOOP
         ENDIF

         nPos := AScan( aDokumenti, {| cBrDok | cBrDok == fakt->brdok } )
         IF nPos == 0
            AAdd( aDokumenti, fakt->brdok )
         ENDIF

         IF AllTrim( fakt->podbr ) == "."  .OR. fakt->idroba == "U" // usluge ne prenosi takodjer
            SKIP
            LOOP
         ENDIF

         cIdRoba := fakt->idroba
         select_o_roba( cIdRoba )

         cIdTar := roba->idtarifa

         select_o_tarifa( cIdTar )
         select_o_koncij( cIdKonto )

         PRIVATE aPorezi := {}

         cPKonto := cIdKonto

         SELECT kalk_pripr

         IF cSabirati == "D"
            SET ORDER TO TAG "4"
            SEEK cIdFirma + "11" + cIdRoba
         ELSE
            SET ORDER TO TAG "5"
            SEEK cIdFirma + "11" + cIdRoba + Str( fakt->cijena, 12, 2 )
         ENDIF

         IF !Found()

            APPEND BLANK
            REPLACE idfirma WITH cIdFirma, ;
               rbr WITH Str( ++nRbr, 3 ), ;
               idvd WITH "11", ;
               brdok WITH cBrKalk, ;
               datdok WITH dDatKalk, ;
               idtarifa WITH set_pdv_array_by_koncij_region_roba_idtarifa_2_3( cPKonto, fakt->idroba, @aPorezi ), ;
               brfaktp WITH "", ;
               datfaktp WITH fakt->datdok, ;
               idkonto   WITH cPKonto, ;
               idzaduz  WITH cidzaduz, ;
               idkonto2  WITH cidkonto2, ;
               idzaduz2  WITH cidzaduz2, ;
               idroba WITH fakt->idroba, ;
               nc  WITH ROBA->nc, ;
               vpc WITH fakt->cijena, ;
               rabatv WITH fakt->rabat, ;
               mpc WITH fakt->porez, ;
               tmarza2 WITH "A", ;
               tprevoz WITH "A"

            IF cCjenSif == "D"
               REPLACE mpcsapp WITH kalk_get_mpc_by_koncij_pravilo()
            ELSE
               REPLACE mpcsapp WITH fakt->cijena
            ENDIF

         ENDIF

         my_rlock() // saberi kolicine za jedan artikal
         REPLACE kolicina WITH ( kolicina + fakt->kolicina ) // kalk_pripr

         SELECT fakt
         SKIP

      ENDDO

      MsgC()

      SELECT kalk_pripr
      SET ORDER TO TAG "1"
      GO TOP


      DO WHILE !Eof() // brisi stavke koje su kolicina = 0
         IF field->kolicina = 0
            my_rlock()
            DELETE
            my_unlock()
         ENDIF
         SKIP
      ENDDO
      GO TOP

      SELECT fakt

      @ box_x_koord() + 10, box_y_koord() + 2 SAY "KALK Dokument izgenerisan !"

      kalk_fix_brdok_add_1( @cBrKalk )
      Inkey( 4 )

      @ box_x_koord() + 8, box_y_koord() + 2 SAY Space( 30 )
      @ box_x_koord() + 10, box_y_koord() + 2 SAY Space( 40 )

      MsgBeep( "Prenos dokumenata (broj): " + AllTrim( Str( Len( aDokumenti ) ) ) )
   ENDDO

   Boxc()

   my_close_all_dbf()

   RETURN .T.




FUNCTION fakt_13_kalk_11()

   LOCAL cIdFirma := self_organizacija_id()
   LOCAL cIdTipDok := "13"
   LOCAL cBrDok := Space( 8 )
   LOCAL cBrKalk := Space( 8 )

   o_kalk_pripr()
//   o_koncij()
   // o_kalk()
// o_roba()
//   o_konto()
//   o_partner()
//   o_tarifa()

//   o_fakt_dbf()

   dDatKalk := Date()
   cIdKonto := PadR( "1320", 7 )
   cIdKonto2 := PadR( "1310", 7 )
   cIdZaduz2 := cIdZaduz := Space( 6 )

   cBrkalk := Space( 8 )

   kalk_set_brkalk_za_idvd( "11", @cBrKalk )


   Box(, 15, 60 )


   DO WHILE .T.

      nRBr := 0
      @ box_x_koord() + 1, box_y_koord() + 2   SAY "Broj kalkulacije 11 -" GET cBrKalk PICT "@!"
      @ box_x_koord() + 1, Col() + 2 SAY "Datum:" GET dDatKalk
      @ box_x_koord() + 3, box_y_koord() + 2   SAY "Magac. konto razduzuje:" GET cIdKonto2 PICT "@!" VALID P_Konto( @cIdKonto2 )
      // IF gNW <> "X"
      // @ box_x_koord() + 3, Col() + 2 SAY "Razduzuje:" GET cIdZaduz2  PICT "@!"      VALID Empty( cidzaduz2 ) .OR. p_partner( @cIdZaduz2 )
      // ENDIF

      IF gVar13u11 == "1"
         @ box_x_koord() + 4, box_y_koord() + 2   SAY "Prodavn. konto zaduzuje :" GET cIdKonto  PICT "@!" VALID P_Konto( @cIdKonto )
      ENDIF

      // IF gNW <> "X"
      // @ box_x_koord() + 4, Col() + 2 SAY "Zaduzuje:" GET cIdZaduz  PICT "@!"      VALID Empty( cidzaduz ) .OR. p_partner( @cIdZaduz )
      // ENDIF

      cFaktIdFirma := cIdFirma
      @ box_x_koord() + 6, box_y_koord() + 2 SAY "Broj otpremnice u MP: " GET cFaktIdFirma
      @ box_x_koord() + 6, Col() + 1 SAY "- " + cidtipdok
      @ box_x_koord() + 6, Col() + 1 SAY "-" GET cBrDok
      READ
      IF LastKey() == K_ESC; exit; ENDIF


      //SELECT fakt
      //SEEK cFaktIdFirma + cIdTipDok + cBrDok

      //IF !Found()
      IF !find_fakt_dokument( cFaktIdFirma, cIdTipDok, cBrDok )
         Beep( 4 )
         @ box_x_koord() + 14, box_y_koord() + 2 SAY "Ne postoji ovaj dokument !!"
         Inkey( 4 )
         @ box_x_koord() + 14, box_y_koord() + 2 SAY Space( 30 )
         LOOP
      ELSE
         seek_fakt( cFaktIdFirma, cIdTipDok, cBrDok )
         aMemo := fakt_ftxt_decode( txt )

         SELECT kalk_pripr
         LOCATE FOR BrFaktP == cBrDok // faktura je vec prenesena
         IF Found()
            Beep( 4 )
            @ box_x_koord() + 8, box_y_koord() + 2 SAY "Dokument je vec prenesen !!"
            Inkey( 4 )
            @ box_x_koord() + 8, box_y_koord() + 2 SAY Space( 30 )
            LOOP
         ENDIF
         IF gVar13u11 == "2"  .AND. Empty( fakt->idpartner )
            @ box_x_koord() + 10, box_y_koord() + 2   SAY "Prodavn. konto zaduzuje :" GET cIdKonto  PICT "@!" VALID P_Konto( @cIdKonto )
            READ
         ENDIF
         GO BOTTOM
         IF brdok == cBrKalk; nRbr := Val( Rbr ); ENDIF

         SELECT fakt
         //IF !provjerisif_izbaciti_ovu_funkciju( "!eof() .and. '" + cFaktIdFirma + cIdTipDok + cBrDok + "'==IdFirma+IdTipDok+BrDok", "IDROBA", F_ROBA )
        //    MsgBeep( "U ovom dokumentu nalaze se sifre koje ne postoje u tekucem sifrarniku!#Prenos nije izvrsen!" )
        //    LOOP
         //ENDIF
         DO WHILE !Eof() .AND. cFaktIdFirma + cIdTipDok + cBrDok == IdFirma + IdTipDok + BrDok
            select_o_roba( fakt->idroba )
            select_o_tarifa( roba->idtarifa )
            select_o_koncij( cidkonto )

            SELECT fakt
            IF AllTrim( podbr ) == "."  .OR. idroba = "U"
               SKIP
               LOOP
            ENDIF

            SELECT kalk_pripr
            APPEND BLANK
            cPKonto := IF( gVar13u11 == "1", cidkonto, fakt->idpartner )
            PRIVATE aPorezi := {}
            REPLACE idfirma WITH cIdFirma, ;
               rbr     WITH Str( ++nRbr, 3 ), ;
               idvd WITH "11", ;   // izlazna faktura
               brdok WITH cBrKalk, ;
               datdok WITH dDatKalk, ;
               idtarifa WITH set_pdv_array_by_koncij_region_roba_idtarifa_2_3( cPKonto, fakt->idroba, @aPorezi ), ;
               brfaktp WITH fakt->brdok, ;
               datfaktp WITH fakt->datdok, ;
               idkonto   WITH cPKonto, ;
               idzaduz  WITH cidzaduz, ;
               idkonto2  WITH cidkonto2, ;
               idzaduz2  WITH cidzaduz2, ;
               kolicina WITH fakt->kolicina, ;
               idroba WITH fakt->idroba, ;
               nc  WITH ROBA->nc, ;
               vpc WITH IIF( gVar13u11 == "1", fakt->cijena, kalk_vpc_za_koncij() ), ;
               rabatv WITH fakt->rabat, ;
               mpc WITH fakt->porez, ;
               tmarza2 WITH "A", ;
               tprevoz WITH "A", ;
               mpcsapp WITH IF( gVar13u11 == "1", roba->mpc, fakt->cijena )

            IF gVar13u11 == "1"
               REPLACE mpcsapp WITH kalk_get_mpc_by_koncij_pravilo()
            ENDIF
            IF gVar13u11 == "2" .AND. Empty( fakt->idpartner )
               REPLACE idkonto WITH cidkonto
            ENDIF

            SELECT fakt
            SKIP
         ENDDO
         @ box_x_koord() + 8, box_y_koord() + 2 SAY "Dokument je prenesen !"

         kalk_fix_brdok_add_1( @cBrKalk )

         Inkey( 4 )
         @ box_x_koord() + 8, box_y_koord() + 2 SAY Space( 30 )
         @ box_x_koord() + 10, box_y_koord() + 2 SAY Space( 40 )
      ENDIF

   ENDDO
   Boxc()
   my_close_all_dbf()

   RETURN .T.



/*
 *     Prenos maloprodajnih kalkulacija FAKT->KALK (11->41)
 */

FUNCTION fakt_11_kalk_41()

   LOCAL GetList := {}

   PRIVATE cIdFirma := self_organizacija_id()
   PRIVATE cIdTipDok := "11"
   PRIVATE cBrDok := Space( 8 )
   PRIVATE cBrKalk := Space( 8 )
   PRIVATE cFaktIdFirma

   o_kalk_pripr()
//   o_kalk()
// o_roba()
//   o_konto()
  // o_partner()
//   o_tarifa()

  // o_fakt_dbf()

   dDatKalk := Date()
   cIdKonto := PadR( "1330", 7 )
   cIdZaduz := Space( 6 )
   cBrkalk := Space( 8 )
   cZbirno := "N"
   cNac_rab := "P"

   kalk_set_brkalk_za_idvd( "41", @cBrKalk )

   Box(, 15, 60 )


   DO WHILE .T.
      nRBr := 0
      @ box_x_koord() + 1, box_y_koord() + 2 SAY "Broj kalkulacije 41 -" GET cBrKalk PICT "@!"
      @ box_x_koord() + 1, Col() + 2 SAY "Datum:" GET dDatKalk
      @ box_x_koord() + 3, box_y_koord() + 2 SAY "Konto razduzuje :" GET cIdKonto  PICT "@!" VALID P_Konto( @cIdKonto )
      // IF gNW <> "X"
      // @ box_x_koord() + 3, Col() + 2 SAY "Razduzuje:" GET cIdZaduz  PICT "@!"      VALID Empty( cidzaduz ) .OR. p_partner( @cIdZaduz )
      // ENDIF
      @ box_x_koord() + 5, box_y_koord() + 2 SAY "Napraviti zbirnu kalkulaciju (D/N): " GET cZbirno VALID cZbirno $ "DN" PICT "@!"
      READ

      IF cZbirno == "N"

         cFaktIdFirma := cIdFirma

         @ box_x_koord() + 6, box_y_koord() + 2 SAY "Broj fakture: " GET cFaktIdFirma
         @ box_x_koord() + 6, Col() + 2 SAY "- " + cIdTipDok
         @ box_x_koord() + 6, Col() + 2 SAY "-" GET cBrDok

         READ

         IF ( LastKey() == K_ESC )
            EXIT
         ENDIF

         //SELECT fakt
         //SEEK cFaktIdFirma + cIdTipDok + cBrDok

         //IF !Found()
         IF !find_fakt_dokument( cFaktIdFirma, cIdTipDok, cBrDok )
            Beep( 4 )
            @ box_x_koord() + 14, box_y_koord() + 2 SAY "Ne postoji ovaj dokument !"
            Inkey( 4 )
            @ box_x_koord() + 14, box_y_koord() + 2 SAY Space( 30 )
            LOOP
         ELSE
            seek_fakt( cFaktIdFirma, cIdTipDok, cBrDok )
            aMemo := fakt_ftxt_decode( txt )

            IF Len( aMemo ) >= 5
               @ box_x_koord() + 10, box_y_koord() + 2 SAY PadR( Trim( aMemo[ 3 ] ), 30 )
               @ box_x_koord() + 11, box_y_koord() + 2 SAY PadR( Trim( aMemo[ 4 ] ), 30 )
               @ box_x_koord() + 12, box_y_koord() + 2 SAY PadR( Trim( aMemo[ 5 ] ), 30 )
            ELSE
               cTxt := ""
            ENDIF

            IF ( LastKey() == K_ESC )
               EXIT
            ENDIF

            cIdPartner := IdPartner

            @ box_x_koord() + 14, box_y_koord() + 2 SAY "Sifra partnera:" GET cIdpartner PICT "@!" VALID p_partner( @cIdPartner )

            READ

            SELECT kalk_pripr
            LOCATE FOR BrFaktP = cBrDok

            IF Found() // da li je faktura vec prenesena
               Beep( 4 )
               @ box_x_koord() + 8, box_y_koord() + 2 SAY "Dokument je vec prenesen !"
               Inkey( 4 )
               @ box_x_koord() + 8, box_y_koord() + 2 SAY Space( 30 )
               LOOP
            ENDIF
            GO BOTTOM
            IF brdok == cBrKalk
               nRbr := Val( Rbr )
            ENDIF

            SELECT fakt
            //IF !provjerisif_izbaciti_ovu_funkciju( "!eof() .and. '" + cFaktIdFirma + cIdTipDok + cBrDok + "'==IdFirma+IdTipDok+BrDok", "IDROBA", F_ROBA )
            //   MsgBeep( "U ovom dokumentu nalaze se sifre koje ne postoje u tekucem sifrarniku!#Prenos nije izvrsen!" )
            //   LOOP
            //ENDIF

            DO WHILE !Eof() .AND. cFaktIdFirma + cIdTipDok + cBrDok == IdFirma + IdTipDok + BrDok
               select_o_roba( fakt->idroba )
               select_o_tarifa( roba->idtarifa )
               SELECT fakt
               IF AllTrim( podbr ) == "."
                  SKIP
                  LOOP
               ENDIF

               SELECT kalk_pripr

               PRIVATE aPorezi := {}

               set_pdv_array_by_koncij_region_roba_idtarifa_2_3( cIdKonto, fakt->idRoba, @aPorezi )

               nMPVBP := MpcBezPor( fakt->( kolicina * cijena ), aPorezi )

               APPEND BLANK
               REPLACE idfirma WITH cIdFirma, ;
                  rbr WITH Str( ++nRbr, 3 ), ;
                  idvd WITH "41", ;
                  brdok WITH cBrKalk, ;
                  datdok WITH dDatKalk, ;
                  idpartner WITH cIdPartner, ;
                  idtarifa WITH ROBA->idtarifa, ;
                  brfaktp WITH fakt->brdok, ;
                  datfaktp WITH fakt->datdok, ;
                  idkonto WITH cidkonto, ;
                  idzaduz WITH cidzaduz, ;
                  kolicina WITH fakt->kolicina, ;
                  idroba WITH fakt->idroba, ;
                  mpcsapp WITH fakt->cijena, ;
                  tmarza2 WITH "%"

               REPLACE rabatv WITH ;
                  ( nMPVBP * fakt->rabat / ( fakt->kolicina * 100 ) ) // * 1.17

               SELECT fakt
               SKIP
            ENDDO

         ENDIF
      ELSE // zbirno

         cFaktIdFirma := cIdFirma
         cIdTipDok := "11"
         dDatOd := Date()
         dDatDo := Date()

         @ box_x_koord() + 7, box_y_koord() + 2 SAY "ID firma FAKT: " GET cFaktIdFirma
         @ box_x_koord() + 8, box_y_koord() + 2 SAY "Datum fakture: "
         @ box_x_koord() + 8, Col() + 2 SAY "od " GET dDatOd
         @ box_x_koord() + 8, Col() + 2 SAY "do " GET dDatDo

         READ

         IF ( LastKey() == K_ESC )
            EXIT
         ENDIF

         find_fakt_za_period( cFaktIdFirma, dDatOd, dDatDo, NIL, NIL, "1" )
         //SELECT fakt
         //GO TOP

         DO WHILE !Eof()

            IF ( fakt->idfirma == cFaktIdFirma .AND. fakt->idtipdok == cIdTipDok  )

               cIdPartner := fakt->IdPartner

               @ box_x_koord() + 14, box_y_koord() + 2 SAY "Sifra partnera:" GET cIdpartner PICT "@!" VALID p_partner( @cIdPartner )
               READ

               SELECT kalk_pripr
               GO BOTTOM

               IF brdok == cBrKalk
                  nRbr := Val( Rbr )
               ENDIF

               //SELECT fakt

               //IF !provjerisif_izbaciti_ovu_funkciju( "!eof() .and. '" + cFaktIdFirma + cIdTipDok + "'==IdFirma+IdTipDok", "IDROBA", F_ROBA )
              //    MsgBeep( "U ovom dokumentu nalaze se sifre koje ne postoje u tekucem sifrarniku!#Prenos nije izvrsen!" )
              //    LOOP
               //ENDIF

               SELECT kalk_pripr

               PRIVATE aPorezi := {}

               set_pdv_array_by_koncij_region_roba_idtarifa_2_3( cIdKonto, fakt->idRoba, @aPorezi )

               nMPVBP := MpcBezPor( fakt->( kolicina * cijena ), aPorezi )

               APPEND BLANK

               REPLACE idfirma WITH cIdFirma
               REPLACE rbr WITH Str( ++nRbr, 3 )
               REPLACE idvd WITH "41"
               REPLACE brdok WITH cBrKalk
               REPLACE datdok WITH dDatKalk
               REPLACE idpartner WITH cIdPartner
               REPLACE idtarifa WITH ROBA->idtarifa
               REPLACE brfaktp WITH fakt->brdok
               REPLACE datfaktp WITH fakt->datdok
               REPLACE idkonto WITH cIdKonto
               REPLACE idzaduz WITH cIdZaduz
               REPLACE kolicina WITH fakt->kolicina
               REPLACE idroba WITH fakt->idroba
               REPLACE mpcsapp WITH fakt->cijena
               REPLACE tmarza2 WITH "%"
               REPLACE rabatv WITH ;
                  ( nMPVBP * fakt->rabat / ( fakt->kolicina * 100 ) ) // * 1.17

               SELECT fakt
               SKIP
               LOOP
            ELSE
               SKIP
               LOOP
            ENDIF
         ENDDO
      ENDIF

      @ box_x_koord() + 10, box_y_koord() + 2 SAY "Dokument je prenesen !"
      @ box_x_koord() + 11, box_y_koord() + 2 SAY "Obavezno pokrenuti asistenta <opcija A> !"

      kalk_fix_brdok_add_1( @cBrKalk )

      Inkey( 0 )

      @ box_x_koord() + 10, box_y_koord() + 2 SAY Space( 30 )
      @ box_x_koord() + 11, box_y_koord() + 2 SAY Space( 40 )

   ENDDO
   Boxc()

   my_close_all_dbf()

   RETURN .T.


/*
 *     Prenos FAKT->KALK (01->81)
 */

FUNCTION fakt_01_kalk_81()

   LOCAL cIdFirma := self_organizacija_id(), cIdTipDok := "01", cBrDok := cBrKalk := Space( 8 )
   LOCAL GetList := {}

   o_kalk_pripr()
   o_kalk()
// o_roba()
  // o_konto()
  // o_partner()
//   o_tarifa()

//   o_fakt_dbf()

   dDatKalk := Date()
   cIdKonto := PadR( "1320", 7 )
   cIdZaduz := Space( 6 )

   cBrkalk := Space( 8 )

   kalk_set_brkalk_za_idvd( "81", @cBrKalk )

   Box(, 15, 60 )


   DO WHILE .T.

      nRBr := 0
      @ box_x_koord() + 1, box_y_koord() + 2   SAY "Broj kalkulacije 81 -" GET cBrKalk PICT "@!"
      @ box_x_koord() + 1, Col() + 2 SAY "Datum:" GET dDatKalk
      @ box_x_koord() + 3, box_y_koord() + 2   SAY "Konto razduzuje :" GET cIdKonto  PICT "@!" VALID P_Konto( @cIdKonto )
      // IF gNW <> "X"
      // @ box_x_koord() + 3, Col() + 2 SAY "Zaduzuje:" GET cIdZaduz  PICT "@!"      VALID Empty( cidzaduz ) .OR. p_partner( @cIdZaduz )
      // ENDIF

      cFaktIdFirma := cIdFirma
      @ box_x_koord() + 6, box_y_koord() + 2 SAY "Broj fakture: " GET cFaktIdFirma
      @ box_x_koord() + 6, Col() + 2 SAY "- " + cidtipdok
      @ box_x_koord() + 6, Col() + 2 SAY "-" GET cBrDok
      READ

      IF LastKey() == K_ESC; exit; ENDIF


      //SELECT fakt
      //SEEK cFaktIdFirma + cIdTipDok + cBrDok
      IF !find_fakt_dokument( cFaktIdFirma, cIdTipDok, cBrDok )
      //IF !Found()
         Beep( 4 )
         @ box_x_koord() + 14, box_y_koord() + 2 SAY "Ne postoji ovaj dokument !!"
         Inkey( 4 )
         @ box_x_koord() + 14, box_y_koord() + 2 SAY Space( 30 )
         LOOP
      ELSE
         seek_fakt( cFaktIdFirma, cIdTipDok, cBrDok )
         aMemo := fakt_ftxt_decode( txt )
         IF Len( aMemo ) >= 5
            @ box_x_koord() + 10, box_y_koord() + 2 SAY PadR( Trim( aMemo[ 3 ] ), 30 )
            @ box_x_koord() + 11, box_y_koord() + 2 SAY PadR( Trim( aMemo[ 4 ] ), 30 )
            @ box_x_koord() + 12, box_y_koord() + 2 SAY PadR( Trim( aMemo[ 5 ] ), 30 )
         ELSE
            cTxt := ""
         ENDIF
         cIdPartner := IdPartner
         @ box_x_koord() + 14, box_y_koord() + 2 SAY "Sifra partnera:"  GET cIdpartner PICT "@!" VALID p_partner( @cIdPartner )
         READ

         SELECT kalk_pripr
         LOCATE FOR BrFaktP = cBrDok // faktura je vec prenesena
         IF Found()
            Beep( 4 )
            @ box_x_koord() + 8, box_y_koord() + 2 SAY "Dokument je vec prenesen !!"
            Inkey( 4 )
            @ box_x_koord() + 8, box_y_koord() + 2 SAY Space( 30 )
            LOOP
         ENDIF
         GO BOTTOM
         IF brdok == cBrKalk; nRbr := Val( Rbr ); ENDIF

         SELECT fakt
         //IF !provjerisif_izbaciti_ovu_funkciju( "!eof() .and. '" + cFaktIdFirma + cIdTipDok + cBrDok + "'==IdFirma+IdTipDok+BrDok", "IDROBA", F_ROBA )
        //    MsgBeep( "U ovom dokumentu nalaze se sifre koje ne postoje u tekucem sifrarniku!#Prenos nije izvrsen!" )
          //  LOOP
         //ENDIF

         DO WHILE !Eof() .AND. cFaktIdFirma + cIdTipDok + cBrDok == IdFirma + IdTipDok + BrDok
            select_o_roba( fakt->idroba )
            select_o_tarifa( roba->idtarifa )

            SELECT fakt
            IF AllTrim( podbr ) == "."
               skip; LOOP
            ENDIF

            SELECT kalk_pripr
            APPEND BLANK
            REPLACE idfirma WITH cIdFirma, ;
               rbr     WITH Str( ++nRbr, 3 ), ;
               idvd WITH "81", ;   // izlazna faktura
               brdok WITH cBrKalk, ;
               datdok WITH dDatKalk, ;
               idpartner WITH cIdPartner, ;
               idtarifa WITH ROBA->idtarifa, ;
               brfaktp WITH fakt->brdok, ;
               datfaktp WITH fakt->datdok, ;
               idkonto   WITH cidkonto, ;
               idzaduz  WITH cidzaduz, ;
               kolicina WITH fakt->kolicina, ;
               idroba WITH fakt->idroba, ;
               mpcsapp WITH fakt->cijena, ;
               fcj WITH fakt->cijena / ( 1 + tarifa->pdv / 100 ), ;
               tmarza2 WITH "%"

            SELECT fakt
            SKIP
         ENDDO
         @ box_x_koord() + 8, box_y_koord() + 2 SAY "Dokument je prenesen !"

         kalk_fix_brdok_add_1( @cBrKalk )

         Inkey( 4 )
         @ box_x_koord() + 8, box_y_koord() + 2 SAY Space( 30 )
      ENDIF

   ENDDO
   Boxc()
   my_close_all_dbf()

   RETURN .T.





/*
 *     Otprema u mp->kalk (13->80) prebaci u prodajni objekt
 */

FUNCTION fakt_13_kalk_80()

   LOCAL cIdFirma := self_organizacija_id(), cIdTipDok := "13", cBrDok := cBrKalk := Space( 8 )
   LOCAL GetList := {}

   o_kalk_pripr()
   //o_koncij()
   //o_kalk()
   // o_roba()
   //o_konto()
   //o_partner()
   //o_tarifa()

   //o_fakt_dbf()

   dDatKalk := Date()
   cIdKonto := PadR( "1320999", 7 )
   cIdKonto2 := PadR( "1320", 7 )
   cIdZaduz2 := cIdZaduz := Space( 6 )

   cBrkalk := Space( 8 )
   kalk_set_brkalk_za_idvd( "80", @cBrKalk )

   Box(, 15, 60 )


   DO WHILE .T.

      nRBr := 0
      @ box_x_koord() + 1, box_y_koord() + 2   SAY "Broj kalkulacije 80 -" GET cBrKalk PICT "@!"
      @ box_x_koord() + 1, Col() + 2 SAY "Datum:" GET dDatKalk
      @ box_x_koord() + 3, box_y_koord() + 2   SAY "Prodavn. konto zaduzuje :" GET cIdKonto  PICT "@!" VALID P_Konto( @cIdKonto )
      // IF gNW <> "X"
      // @ box_x_koord() + 3, Col() + 2 SAY "Zaduzuje:" GET cIdZaduz  PICT "@!"      VALID Empty( cidzaduz ) .OR. p_partner( @cIdZaduz )
      // ENDIF
      @ box_x_koord() + 4, box_y_koord() + 2   SAY "CM. konto razduzuje:" GET cIdKonto2 PICT "@!" VALID P_Konto( @cIdKonto2 )
      // IF gNW <> "X"
      // @ box_x_koord() + 4, Col() + 2 SAY "Razduzuje:" GET cIdZaduz2  PICT "@!"      VALID Empty( cidzaduz2 ) .OR. p_partner( @cIdZaduz2 )
      // ENDIF

      cFaktIdFirma := cIdFirma
      @ box_x_koord() + 6, box_y_koord() + 2 SAY "Broj otpremnice u MP: " GET cFaktIdFirma
      @ box_x_koord() + 6, Col() + 1 SAY "- " + cidtipdok
      @ box_x_koord() + 6, Col() + 1 SAY "-" GET cBrDok
      READ
      IF LastKey() == K_ESC; exit; ENDIF


      //SELECT fakt
      //SEEK cFaktIdFirma + cIdTipDok + cBrDok
      //IF !Found()
      IF !find_fakt_dokument( cFaktIdFirma, cIdTipDok, cBrDok )

         Beep( 4 )
         @ box_x_koord() + 14, box_y_koord() + 2 SAY "Ne postoji ovaj dokument !!"
         Inkey( 4 )
         @ box_x_koord() + 14, box_y_koord() + 2 SAY Space( 30 )
         LOOP
      ELSE
         seek_fakt( cFaktIdFirma, cIdTipDok, cBrDok )
         aMemo := fakt_ftxt_decode( txt )


         SELECT kalk_pripr
         LOCATE FOR BrFaktP = cBrDok // faktura je vec prenesena
         IF Found()
            Beep( 4 )
            @ box_x_koord() + 8, box_y_koord() + 2 SAY "Dokument je vec prenesen !!"
            Inkey( 4 )
            @ box_x_koord() + 8, box_y_koord() + 2 SAY Space( 30 )
            LOOP
         ENDIF
         IF gVar13u11 == "2"  .AND. Empty( fakt->idpartner )
            @ box_x_koord() + 10, box_y_koord() + 2   SAY "Prodavn. konto zaduzuje :" GET cIdKonto  PICT "@!" VALID P_Konto( @cIdKonto )
            READ
         ENDIF
         GO BOTTOM
         IF brdok == cBrKalk; nRbr := Val( Rbr ); ENDIF

         SELECT fakt
         //IF !provjerisif_izbaciti_ovu_funkciju( "!eof() .and. '" + cFaktIdFirma + cIdTipDok + cBrDok + "'==IdFirma+IdTipDok+BrDok", "IDROBA", F_ROBA )
        //    MsgBeep( "U ovom dokumentu nalaze se sifre koje ne postoje u tekucem sifrarniku!#Prenos nije izvrsen!" )
        //    LOOP
        // ENDIF
         DO WHILE !Eof() .AND. cFaktIdFirma + cIdTipDok + cBrDok == IdFirma + IdTipDok + BrDok

            select_o_roba( fakt->idroba )
            select_o_tarifa( roba->idtarifa )
            select_o_koncij( cIdkonto )

            SELECT fakt
            IF AllTrim( podbr ) == "."  .OR. idroba = "U"
               skip
               LOOP
            ENDIF
            cPKonto := cIdKonto
            PRIVATE aPorezi := {}
            cIdTarifa := set_pdv_array_by_koncij_region_roba_idtarifa_2_3( cPKonto, fakt->idroba, @aPorezi )
            SELECT kalk_pripr
            APPEND BLANK
            REPLACE idfirma WITH cIdFirma, ;
               rbr     WITH Str( ++nRbr, 3 ), ;
               idvd WITH "80", ;   // izlazna faktura
               brdok WITH cBrKalk, ;
               datdok WITH dDatKalk, ;
               idtarifa WITH cIdTarifa, ;
               brfaktp WITH fakt->brdok, ;
               datfaktp WITH fakt->datdok, ;
               idkonto   WITH cidkonto2, ;
               idzaduz  WITH cidzaduz2, ;
               idkonto2  WITH cidkonto, ;
               idzaduz2  WITH cidzaduz, ;
               kolicina WITH -fakt->kolicina, ;
               idroba WITH fakt->idroba, ;
               nc WITH fakt->cijena / ( 1 + tarifa->pdv / 100 ), ;
               mpc WITH 0, ;
               tmarza2 WITH "A", ;
               tprevoz WITH "A", ;
               mpcsapp WITH fakt->cijena

            APPEND BLANK // protustavka
            REPLACE idfirma WITH cIdFirma, ;
               rbr     WITH Str( nRbr, 3 ), ;
               idvd WITH "80", ;   // izlazna faktura
               brdok WITH cBrKalk, ;
               datdok WITH dDatKalk, ;
               idtarifa WITH cIdTarifa, ;
               brfaktp WITH fakt->brdok, ;
               datfaktp WITH fakt->datdok, ;
               idkonto   WITH cidkonto, ;
               idzaduz  WITH cidzaduz, ;
               idkonto2  WITH "XXX", ;
               idzaduz2  WITH "", ;
               kolicina WITH fakt->kolicina, ;
               idroba WITH fakt->idroba, ;
               nc WITH fakt->cijena / ( 1 + tarifa->pdv / 100 ), ;
               mpc WITH 0, ;
               tmarza2 WITH "A", ;
               tprevoz WITH "A", ;
               mpcsapp WITH fakt->cijena


            SELECT fakt
            SKIP
         ENDDO
         @ box_x_koord() + 8, box_y_koord() + 2 SAY "Dokument je prenesen !"

         kalk_fix_brdok_add_1( @cBrKalk )

         Inkey( 4 )
         @ box_x_koord() + 8, box_y_koord() + 2 SAY Space( 30 )
         @ box_x_koord() + 10, box_y_koord() + 2 SAY Space( 40 )
      ENDIF

   ENDDO
   Boxc()
   my_close_all_dbf()

   RETURN .T.




/*
   prenos fakt->kalk dokumenti tipa 11 u paragon blok kalk->42
*/

FUNCTION fakt_11_kalk_42()

   LOCAL cRazdvojiRazliciteCijeneDN := "D"
   LOCAL _kalk_tip_dok := "42"
   LOCAL nAutoRazd := 2
   LOCAL nX := 1
   LOCAL _x_dok_info := 16
   LOCAL cZbirniPrenosDN := "D"
   LOCAL _dat_kalk := Date()
   LOCAL GetList := {}
   LOCAL dDatOd
   LOCAL dDatDo
   LOCAL cIdFirma := self_organizacija_id(), cFaktIdFirma

   LOCAL cIdTipDok := "11"
   LOCAL  cBrDok := Space( 8 )
   LOCAL cBrKalk := Space( 8 )
   LOCAL cIdKonto, cIdKtoZad, cIdZaduz, nRbr
   LOCAL aMemo, cIdPartner


   cIdKonto := PadR( "1330", 7 )
   cIdKtoZad := PadR( "1330", 7 )
   cIdZaduz := Space( 6 )
   cBrkalk := Space( 8 )

   _o_prenos_tbls()

   Box(, 15, 60 )

   DO WHILE .T.

      nRBr := 0
      nX := 1
      @ box_x_koord() + nX, box_y_koord() + 2 SAY "Generisati kalk dokument (1) 11 (2) 42 ?" GET nAutoRazd PICT "9"

      READ

      IF nAutoRazd == 1
         _kalk_tip_dok := "11"
      ELSE
         _kalk_tip_dok := "42"
      ENDIF

      kalk_set_brkalk_za_idvd( _kalk_tip_dok, @cBrKalk )

      ++nX
      ++nX
      @ box_x_koord() + nX, box_y_koord() + 2 SAY "Broj kalkulacije " + _kalk_tip_dok + " -" GET cBrKalk PICT "@!"
      @ box_x_koord() + nX, Col() + 2 SAY "Datum:" GET _dat_kalk

      ++nX
      @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Konto razdužuje:" GET cIdKonto  PICT "@!"  VALID P_Konto( @cIdKonto )

      IF nAutoRazd == 1
         @ box_x_koord() + nX, Col() + 1 SAY8 "zadužuje:" GET cIdKtoZad  PICT "@!" VALID P_Konto( @cIdKtoZad )
      ENDIF

      // IF gNW <> "X"
      // @ box_x_koord() + nX, Col() + 2 SAY "Partner razduzuje:" GET cIdZaduz ;
      // PICT "@!" ;
      // VALID Empty( cIdZaduz ) .OR. p_partner( @cIdZaduz )
      // ENDIF

      ++nX
      ++nX
      @ box_x_koord() + nX, box_y_koord() + 2 SAY "Napraviti zbirnu kalkulaciju (D/N): " GET cZbirniPrenosDN  VALID cZbirniPrenosDN $ "DN"  PICT "@!"
      ++nX
      @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Razdvoji artikle različitih cijena (D/N): " GET cRazdvojiRazliciteCijeneDN VALID cRazdvojiRazliciteCijeneDN $ "DN"  PICT "@!"

      READ

      ++nX

      IF cZbirniPrenosDN == "N"

         cFaktIdFirma := cIdFirma

         @ box_x_koord() + nX, box_y_koord() + 2 SAY "Broj fakture: " GET cFaktIdFirma
         @ box_x_koord() + nX, Col() + 2 SAY "- " + cIdTipDok
         @ box_x_koord() + nX, Col() + 2 SAY "-" GET cBrDok

         READ

         IF ( LastKey() == K_ESC )
            EXIT
         ENDIF

         //SELECT fakt
         //SEEK cFaktIdFirma + cIdTipDok + cBrDok
         IF !find_fakt_dokument( cFaktIdFirma, cIdTipDok, cBrDok )
         //IF !Found()
            Beep( 4 )
            @ box_x_koord() + 15, box_y_koord() + 2 SAY "Ne postoji ovaj dokument !!"
            Inkey( 4 )
            @ box_x_koord() + 15, box_y_koord() + 2 SAY Space( 30 )
            LOOP
         ELSE
            seek_fakt( cFaktIdFirma, cIdTipDok, cBrDok )
            aMemo := fakt_ftxt_decode( txt )

            IF Len( aMemo ) >= 5
               @ box_x_koord() + _x_dok_info, box_y_koord() + 2 SAY PadR( Trim( aMemo[ 3 ] ), 30 )
               @ box_x_koord() + 1 + _x_dok_info, box_y_koord() + 2 SAY PadR( Trim( aMemo[ 4 ] ), 30 )
               @ box_x_koord() + 2 + _x_dok_info, box_y_koord() + 2 SAY PadR( Trim( aMemo[ 5 ] ), 30 )
            ELSE
               cTxt := ""
            ENDIF

            IF ( LastKey() == K_ESC )
               EXIT
            ENDIF

            cIdPartner := ""

            SELECT kalk_pripr
            LOCATE FOR BrFaktP = cBrDok

            // da li je faktura vec prenesena
            IF Found()
               Beep( 4 )
               @ box_x_koord() + 15, box_y_koord() + 2 SAY "Dokument je vec prenesen !!"
               Inkey( 4 )
               @ box_x_koord() + 15, box_y_koord() + 2 SAY Space( 30 )
               LOOP
            ENDIF

            GO BOTTOM

            IF brdok == cBrKalk
               nRbr := Val( Rbr )
            ENDIF

            SELECT fakt
            //IF !provjerisif_izbaciti_ovu_funkciju( "!eof() .and. '" + cFaktIdFirma + cIdTipDok + cBrDok + "'==IdFirma+IdTipDok+BrDok", "IDROBA", F_ROBA )
            //   MsgBeep( "U ovom dokumentu nalaze se sifre koje ne postoje u tekucem sifarniku!#Prenos nije izvrsen!" )
            //   LOOP
            //ENDIF


            DO WHILE !Eof() .AND. cFaktIdFirma + cIdTipDok + cBrDok == IdFirma + IdTipDok + BrDok

               select_o_roba( fakt->idroba )
               select_o_tarifa( roba->idtarifa )

               SELECT fakt

               IF AllTrim( podbr ) == "."
                  SKIP
                  LOOP
               ENDIF

               SELECT kalk_pripr

               PRIVATE aPorezi := {}
               set_pdv_array_by_koncij_region_roba_idtarifa_2_3( cIdKonto, fakt->idRoba, @aPorezi )
               nMPVBP := MpcBezPor( fakt->( kolicina * cijena ), aPorezi )

               APPEND BLANK

               REPLACE idfirma WITH cIdFirma
               REPLACE rbr WITH Str( ++nRbr, 3 )
               REPLACE idvd WITH _kalk_tip_dok
               REPLACE brdok WITH cBrKalk
               REPLACE datdok WITH _dat_kalk
               REPLACE idpartner WITH cIdPartner
               REPLACE idtarifa WITH ROBA->idtarifa
               REPLACE brfaktp WITH fakt->brdok
               REPLACE datfaktp WITH fakt->datdok
               REPLACE idkonto WITH cidkonto
               REPLACE idzaduz WITH cidzaduz
               REPLACE kolicina WITH fakt->kolicina
               REPLACE idroba WITH fakt->idroba
               REPLACE mpcsapp WITH fakt->cijena
               REPLACE tmarza2 WITH "%"
               REPLACE rabatv WITH nMPVBP * fakt->rabat / ( fakt->kolicina * 100 )

               SELECT fakt
               SKIP

            ENDDO

         ENDIF

      ELSE

         cFaktIdFirma := cIdFirma
         cIdTipDok := "11"
         dDatOd := Date()
         dDatDo := Date()

         @ box_x_koord() + nX, box_y_koord() + 2 SAY "ID firma FAKT: " GET cFaktIdFirma

         ++nX
         @ box_x_koord() + nX, box_y_koord() + 2 SAY "Datum fakture: "
         @ box_x_koord() + nX, Col() + 2 SAY "od " GET dDatOd
         @ box_x_koord() + nX, Col() + 2 SAY "do " GET dDatDo

         READ

         IF ( LastKey() == K_ESC )
            EXIT
         ENDIF

         find_fakt_za_period( cFaktIdFirma, dDatOd, dDatDo, NIL, NIL, "1" )

         DO WHILE !Eof()

            IF ( field->idfirma == cFaktIdFirma .AND. field->idtipdok == cIdTipDok )

               cIdPartner := ""

               SELECT kalk_pripr
               GO BOTTOM

               IF field->brdok == cBrKalk
                  nRbr := Val( Rbr )
               ENDIF

               SELECT fakt

               // IF !provjerisif_izbaciti_ovu_funkciju( "!eof() .and. '" + cFaktIdFirma + cIdTipDok + "'==IdFirma+IdTipDok", "IDROBA", F_ROBA )
               // MsgBeep( "U ovom dokumentu nalaze se sifre koje ne postoje u tekucem sifrarniku!#Prenos nije izvrsen!" )
               // LOOP
               // ENDIF

               select_o_roba( fakt->idroba )
               SELECT kalk_pripr

               LOCATE FOR idroba == fakt->idroba // ako fakt ima vise istih artikala - .T.


               IF Found() .AND. ;
                     ( Round( fakt->rabat, 2 ) == 0 .AND. Round( field->rabatv, 2 ) == 0 ) .AND. ;
                     ( cRazdvojiRazliciteCijeneDN == "N" .OR. ( cRazdvojiRazliciteCijeneDN == "D" .AND. mpcsapp == fakt->cijena ) )

                  RREPLACE field->kolicina WITH field->kolicina + fakt->kolicina

               ELSE

                  PRIVATE aPorezi := {}

                  set_pdv_array_by_koncij_region_roba_idtarifa_2_3( cIdKonto, fakt->idRoba, @aPorezi )
                  nMPVBP := MpcBezPor( fakt->( kolicina * cijena ), aPorezi )

                  APPEND BLANK

                  REPLACE idfirma WITH cIdFirma, ;
                     rbr WITH Str( ++nRbr, 3 ), ;
                     idvd WITH _kalk_tip_dok, ;
                     brdok WITH cBrKalk, ;
                     datdok WITH _dat_kalk, ;
                     idpartner WITH cIdPartner, ;
                     idtarifa WITH ROBA->idtarifa, ;
                     brfaktp WITH fakt->brdok, ;
                     datfaktp WITH fakt->datdok

                  IF nAutoRazd == 1
                     REPLACE idkonto WITH cIdKtoZad
                     REPLACE idkonto2 WITH cIdKonto
                  ELSE
                     REPLACE idkonto WITH cIdKonto
                  ENDIF

                  REPLACE idzaduz WITH cIdZaduz
                  REPLACE kolicina WITH fakt->kolicina
                  REPLACE idroba WITH fakt->idroba
                  REPLACE mpcsapp WITH fakt->cijena

                  IF nAutoRazd == 1
                     REPLACE tprevoz WITH "R"
                     REPLACE tmarza2 WITH "A"
                  ELSE
                     REPLACE tmarza2 WITH "%"
                  ENDIF
                  REPLACE rabatv WITH nMPVBP * fakt->rabat / ( fakt->kolicina * 100 )

               ENDIF

               SELECT fakt
               SKIP
               LOOP
            ELSE
               SKIP
               LOOP
            ENDIF
         ENDDO
      ENDIF

      @ box_x_koord() + 10, box_y_koord() + 2 SAY "Dokument je prenesen !"
      @ box_x_koord() + 11, box_y_koord() + 2 SAY "Obavezno pokrenuti asistenta <opcija A>!"

      kalk_fix_brdok_add_1( @cBrKalk )

      Inkey( 4 )

      @ box_x_koord() + 10, box_y_koord() + 2 SAY Space( 30 )
      @ box_x_koord() + 11, box_y_koord() + 2 SAY Space( 40 )

   ENDDO

   Boxc()

   my_close_all_dbf()

   RETURN .T.




STATIC FUNCTION _o_prenos_tbls()

   o_kalk_pripr()
   o_kalk()
   // o_roba()
   //o_konto()
   //o_partner()
   //o_tarifa()
   //o_fakt_dbf()

   RETURN .T.
