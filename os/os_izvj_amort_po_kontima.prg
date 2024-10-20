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



FUNCTION os_amortizacija_po_kontima()

   LOCAL cIdAmort := Space( 8 )
   LOCAL _sr_id, _sr_id_rj, _sr_id_am, _sr_datum, _sr_dat_otp
   LOCAL cIdKonto := qidkonto := Space( 7 ), cidsk := "", ndug := ndug2 := npot := npot2 := ndug3 := npot3 := 0
   LOCAL nCol1 := 10, qIdAm := Space( 8 )
   LOCAL _mod_name := "OS"

   IF gOsSii == "S"
      _mod_name := "SII"
   ENDIF

   //o_amort()
   //o_konto()
   //o_rj()

   o_os_sii_promj()
   o_os_sii()

   cIdRj := Space( 4 )
   cPromj := "2"
   cPocinju := "N"
   cFiltSadVr := "0"
   cFiltK1 := Space( 40 )
   cSamoSpec := my_get_from_ini( "OS", "DefaultSamoSpecZaIzv7", "N" )
   cON := " " // novo!

   Box(, 12, 77 )
   DO WHILE .T.
      @ box_x_koord() + 1, box_y_koord() + 2 SAY "Radna jedinica (prazno - svi):" GET cIdRj ;
         VALID {|| Empty( cIdRj ) .OR. P_RJ( @cIdRj ), if( !Empty( cIdRj ), cIdRj := PadR( cIdRj, 4 ), .T. ), .T. }

      @ box_x_koord() + 1, Col() + 2 SAY "sve koje pocinju " GET cPocinju VALID cPocinju $ "DN" PICT "@!"
      @ box_x_koord() + 2, box_y_koord() + 2 SAY "Konto (prazno - svi):" GET qIdKonto PICT "@!" VALID Empty( qidkonto ) .OR. P_Konto( @qIdKonto )
      @ box_x_koord() + 3, box_y_koord() + 2 SAY "Grupa amort.stope (prazno - sve):" GET qIdAm PICT "@!" VALID Empty( qidAm ) .OR. P_Amort( @qIdAm )
      @ box_x_koord() + 4, box_y_koord() + 2 SAY "Za sredstvo prikazati vrijednost:"
      @ box_x_koord() + 5, box_y_koord() + 2 SAY "1 - bez promjena"
      @ box_x_koord() + 6, box_y_koord() + 2 SAY "2 - osnovni iznos + promjene"
      @ box_x_koord() + 7, box_y_koord() + 2 SAY "3 - samo promjene           " GET cPromj VALID cpromj $ "123"
      @ box_x_koord() + 8, box_y_koord() + 2 SAY "Filter po sadasnjoj vr.(0-sve,1-samo koja je imaju,2-samo koja je nemaju):" GET cFiltSadVr VALID cFiltSadVr $ "012" PICT "9"
      @ box_x_koord() + 9, box_y_koord() + 2 SAY "Filter po grupaciji K1:" GET cFiltK1 PICT "@!S20"
      @ box_x_koord() + 10, box_y_koord() + 2 SAY "Prikaz samo specifikacije (D/N):" GET cSamoSpec VALID cSamoSpec $ "DN" PICT "@!"
      @ box_x_koord() + 11, box_y_koord() + 2 SAY "Prikaz svih os ( )      /   neotpisanih (N)     / otpisanih   (O) "
      @ box_x_koord() + 12, box_y_koord() + 2 SAY "/novonabavljenih   (B) / iz proteklih godina (G)" GET cON VALID con $ "ONBG " PICT "@!"
      read; ESC_BCR
      aUsl1 := Parsiraj( cFiltK1, "K1" )
      IF aUsl1 <> NIL; exit; ENDIF
   ENDDO
   BoxC()

   cIdRj := PadR( cIdRj, 4 )

   IF Empty( qidAm ); qidAm := ""; ENDIF
   IF Empty( qidkonto ); qidkonto := ""; ENDIF
   IF Empty( cIdRj ); cIdRj := ""; ENDIF
   IF cPocinju == "D"
      cIdRj := Trim( cIdRj )
   ENDIF


   select_o_os_or_sii()
   cSort1 := "idkonto+idam+id"

   aUslS := ".t."
   IF !Empty( cIdRj )
      aUslS := aUslS + ".and." + ;
         "IDRJ=" + dbf_quote( cIdRj )
   ENDIF
   IF !Empty( qIdKonto )
      aUslS := aUslS + ".and." + ;
         "IDKONTO=" + dbf_quote( qIdKonto )
   ENDIF
   IF !Empty( qIdAm )
      aUslS := aUslS + ".and." + ;
         "IDKONTO=" + dbf_quote( qIdAm )
   ENDIF
   IF !Empty( cFiltK1 )
      aUslS := aUslS + ".and." + ;
         aUsl1
   ENDIF

   select_o_os_or_sii()
   SET ORDER TO
   SET FILTER TO
   GO TOP

   IF cPromj == "3" .OR. cFiltSadVr != "0"
      cSort1 := "FSVPROMJ()+idkonto+idam+id"
      INDEX ON &cSort1 TO "TMPOS" FOR &aUslS
      SET SCOPE TO " "
   ELSE
      INDEX ON &cSort1 TO "TMPOS" FOR &aUslS
   ENDIF
   GO TOP

   IF Eof()
      MsgBeep( "Ne postoje trazeni podaci!" )
      CLOSERET
   ENDIF

   os_rpt_default_valute()

   START PRINT CRET

   P_12CPI

   ? tip_organizacije() + ":", self_organizacija_naziv()

   IF !Empty( cIdRj )
      select_o_rj( cIdRj )
      select_o_os_or_sii()
      ? "Radna jedinica:", cIdRj, rj->naz
   ENDIF

   ? _mod_name + ": Pregled obracuna amortizacije po kontima i amortizacionim grupama "
   ?? "", PrikazVal(), "    Datum:", os_datum_obracuna()

   IF !Empty( cFiltK1 )
      ? "Filter grupacija K1 pravljen po uslovu: '" + Trim( cFiltK1 ) + "'"
   ENDIF

   IF con = "N"
      ? "PRIKAZ NEOTPISANIH SREDSTAVA:"
   ELSEIF con == "B"
      ? "PRIKAZ NOVONABAVLJENIH SREDSTAVA:"
   ELSEIF con == "G"
      ? "PRIKAZ SREDSTAVA IZ PROTEKLIH GODINA:"
   ELSEIF con == "O"
      ? "PRIKAZ OTPISANIH SREDSTAVA:"
   ELSEIF   con == " "
      ? "PRIKAZ SVIH SREDSTAVA:"
   ENDIF

   PRIVATE nRbr := 0
   aKol := {}
   nKol := 0
   nPI := Len( gPicI )
   nPID := 0
   j := At( ".", gPicI )

   IF ( j > 0 )
      FOR i := j TO Len( gPicI )
         IF SubStr( gPicI, i, 1 ) == "9"
            ++nPID
         ELSE
            // EXIT
            LOOP
         ENDIF
      NEXT
   ENDIF

   IF cSamoSpec == "D"
      AAdd( aKol, { "OtpVr", {|| otpvr * nBBK            }, .F., "N", nPI, nPID, 1, ++nKol } )
      AAdd( aKol, { "Amort.", {|| amp * nBBK              }, .F., "N", nPI, nPID, 1, ++nKol } )
      AAdd( aKol, { "O+Am", {|| otpvr * nBBK + amp * nBBK        }, .F., "N", nPI, nPID, 1, ++nKol } )
      AAdd( aKol, { "SadVr", {|| nabvr * nBBK - otpvr * nBBK - amp * nBBK  }, .F., "N", nPI, nPID, 1, ++nKol } )
   ELSE
      AAdd( aKol, { "Rbr.", {|| Str( nRBr, 4 ) + "."  }, .F., "C",   5,   0, 1, ++nKol } )
      AAdd( aKol, { "Inv.broj", {|| id               }, .F., "C",  10,   0, 1, ++nKol } )
      AAdd( aKol, { "RJ", {|| idrj             }, .F., "C",   4,   0, 1, ++nKol } )
      AAdd( aKol, { "Datum", {|| datum            }, .F., "D",   8,   0, 1, ++nKol } )
      AAdd( aKol, { "Sredstvo", {|| naz              }, .F., "C",  30,   0, 1, ++nKol } )
      AAdd( aKol, { "jmj", {|| jmj              }, .F., "C",   3,   0, 1, ++nKol } )
      AAdd( aKol, { "kol", {|| kolicina         }, .F., "N",   6,   1, 1, ++nKol } )
      AAdd( aKol, { "NabVr", {|| nabvr * nBBK            }, .T., "N", nPI, nPID, 1, ++nKol } )
      AAdd( aKol, { "OtpVr", {|| otpvr * nBBK            }, .T., "N", nPI, nPID, 1, ++nKol } )
      AAdd( aKol, { "Amort.", {|| amp * nBBK              }, .T., "N", nPI, nPID, 1, ++nKol } )
      AAdd( aKol, { "O+Am", {|| otpvr * nBBK + amp * nBBK        }, .T., "N", nPI, nPID, 1, ++nKol } )
      AAdd( aKol, { "SadVr", {|| nabvr * nBBK - otpvr * nBBK - amp * nBBK  }, .T., "N", nPI, nPID, 1, ++nKol } )
   ENDIF

   gnLMarg := 0; gTabela := 1; gOstr := "D"

   cIdSK    := Left( IDKONTO, 3 )
   cIdKonto := IDKONTO
   cIdAm    := IDAM

   nNab1 := nOtp1 := nAmo1 := 0
   nNab2 := nOtp2 := nAmo2 := 0
   nNab3 := nOtp3 := nAmo3 := 0
   nNab9 := nOtp9 := nAmo9 := 0

   gaSubTotal := {}
   gaDodStavke := {}

   IF cSamoSpec == "D"

      print_lista_2( aKol,,, gTabela,, ;
         ,, ;
         {|| FFor1s() }, IIF( gOstr == "D",, -1 ),,,,, )

   ELSE

      print_lista_2( aKol,,, gTabela,, ;
         ,, ;
         {|| FFor1() }, IIF( gOstr == "D",, -1 ),,,,, )

   ENDIF

   FF
   ENDPRINT
   my_close_all_dbf()

   RETURN .T.



STATIC FUNCTION FFor1()

   LOCAL _sr_id, _sr_id_rj, _sr_datum, _sr_dat_otp, _sr_id_am
   LOCAL lVrati := .T., fIma := .T., lImaSadVr := .T.
   LOCAL _sr_kol, _sr_naz, _sr_jmj

   gaSubTotal  := {}
   gaDodStavke := {}

   IF !( ( cON == "N" .AND. datotp_prazan() ) .OR. ;
         ( con == "O" .AND. !datotp_prazan() ) .OR. ;
         ( con == "B" .AND. Year( datum ) = Year( os_datum_obracuna() ) ) .OR. ;
         ( con == "G" .AND. Year( datum ) < Year( os_datum_obracuna() ) ) .OR. ;
         Empty( con ) )
      RETURN .F.
   ENDIF

   // priprema za ispis dodatnih stavki
   // ---------------------------------

   ++nRbr

   IF cPromj $ "23"  // prikaz promjena

      _sr_id := field->id
      _sr_id_rj := field->idrj
      _sr_naz := field->naz
      _sr_jmj := field->jmj
      _sr_datum := field->datum
      _sr_kol := field->kolicina

      os_select_promj( _sr_id )
      //HSEEK _sr_id

      IF cPromj == "2" .AND. !Eof() .AND. field->id == _sr_id .AND. field->datum <= os_datum_obracuna() .OR. cPromj == "3"
         IF cPromj == "3"
            AAdd( gaDodStavke, ;
               { Str( nRBr, 4 ) + ".", _sr_id, _sr_id_rj, _sr_datum,;
               _sr_naz, _sr_jmj, _sr_kol, , , , , } )
            lVrati := .F.
         ENDIF
         DO WHILE !Eof() .AND. field->id == _sr_id .AND. field->datum <= os_datum_obracuna()

            AAdd( gaDodStavke, ;
               {,,, datum, opis,,, nabvr * nBBK, otpvr * nBBK, amp * nBBK, otpvr * nBBK + amp * nBBK, nabvr * nBBK - amp * nBBK - otpvr * nBBK } )
            nNab3 += nabvr * nBBK;  nOtp3 += otpvr * nBBK;  nAmo3 += amp * nBBK
            nNab2 += nabvr * nBBK;  nOtp2 += otpvr * nBBK;  nAmo2 += amp * nBBK
            nNab1 += nabvr * nBBK;  nOtp1 += otpvr * nBBK;  nAmo1 += amp * nBBK
            SKIP 1
         ENDDO
      ENDIF
      select_o_os_or_sii()
   ENDIF

   cIdSK    := Left( IDKONTO, 3 )
   cIdKonto := IDKONTO
   cIdAm    := IDAM
   cST1 := "UK.GRUPA AMORTIZ. '" + cIdAM + "'"

   nTArea := Select()

   select_o_konto( cIdKonto )
   cST2 := "UK.ANALIT.KONTO '" + cIdKonto + "'" + PadR( konto->naz, 30 ) + "..."

   select_o_konto( cIdSK )
   cST3 := "UK.SINT.KONTO '" + cIdSK + "'" + PadR( konto->naz, 30 ) + "..."

   SELECT ( nTArea )

   IF cPromj != "3"
      // sinteticki
      nNab3 += nabvr * nBBK;  nOtp3 += otpvr * nBBK;  nAmo3 += amp * nBBK
      // analiticki
      nNab2 += nabvr * nBBK;  nOtp2 += otpvr * nBBK;  nAmo2 += amp * nBBK
      // po grupi amortizacije
      nNab1 += nabvr * nBBK;  nOtp1 += otpvr * nBBK;  nAmo1 += amp * nBBK
   ENDIF

   SKIP 1

   IF cIdSK != Left( IDKONTO, 3 ) .OR. Eof()
      // stampaj subtot.amort.
      // stampaj subtot.analit.
      // stampaj subtot.sint.
      gaSubTotal := { ;
         {,,,,,,,  nNab1, nOtp1, nAmo1, nOtp1 + nAmo1, nNab1 - nOtp1 - nAmo1, cST1 }, ;
         {,,,,,,,  nNab2, nOtp2, nAmo2, nOtp2 + nAmo2, nNab2 - nOtp2 - nAmo2, cST2 }, ;
         {,,,,,,,  nNab3, nOtp3, nAmo3, nOtp3 + nAmo3, nNab3 - nOtp3 - nAmo3, cST3 } }
      nNab1 := nOtp1 := nAmo1 := 0
      nNab2 := nOtp2 := nAmo2 := 0
      nNab3 := nOtp3 := nAmo3 := 0
   ELSEIF cIdKonto != IDKONTO
      // stampaj subtot.amort.
      // stampaj subtot.analit.
      gaSubTotal := { ;
         {,,,,,,,  nNab1, nOtp1, nAmo1, nOtp1 + nAmo1, nNab1 - nOtp1 - nAmo1, cST1 }, ;
         {,,,,,,,  nNab2, nOtp2, nAmo2, nOtp2 + nAmo2, nNab2 - nOtp2 - nAmo2, cST2 } }
      nNab1 := nOtp1 := nAmo1 := 0
      nNab2 := nOtp2 := nAmo2 := 0
   ELSEIF cIdAm != IDAM
      // stampaj subtot.amort.
      gaSubTotal := { ;
         {,,,,,,,  nNab1, nOtp1, nAmo1, nOtp1 + nAmo1, nNab1 - nOtp1 - nAmo1, cST1 } }
      nNab1 := nOtp1 := nAmo1 := 0
   ELSE
      gaSubTotal := {}
   ENDIF
   SKIP -1

   RETURN lVrati



STATIC FUNCTION FFor1s()

   LOCAL lVrati := .T., fIma := .T., lImaSadVr := .T.
   LOCAL _sr_id, _sr_id_rj, _sr_datum, _sr_dat_otp, _sr_id_am
   LOCAL _sr_naz, _sr_kol, _sr_jmj

   gaSubTotal  := {}
   gaDodStavke := {}

   IF !( ( cON == "N" .AND. datotp_prazan() ) .OR. ;
         ( con == "O" .AND. !datotp_prazan() ) .OR. ;
         ( con == "B" .AND. Year( datum ) = Year( os_datum_obracuna() ) ) .OR. ;
         ( con == "G" .AND. Year( datum ) < Year( os_datum_obracuna() ) ) .OR. ;
         Empty( con ) )
      RETURN .F.
   ENDIF

   // priprema za ispis dodatnih stavki
   // ---------------------------------

   ++nRbr

   IF cPromj $ "23"

      // prikaz promjena

      _sr_id := field->id
      _sr_id_rj := field->idrj
      _sr_datum := field->datum
      _sr_naz := field->naz
      _sr_jmj := field->jmj
      _sr_kol := field->kolicina

      os_select_promj( _sr_id )
      //HSEEK _sr_id

      IF cPromj == "2" .AND. !Eof() .AND. field->id == _sr_id .AND. field->datum <= os_datum_obracuna() .OR. cPromj == "3"

         IF cPromj == "3"
            AAdd( gaDodStavke, ;
               { Str( nRBr, 4 ) + ".", _sr_id, _sr_id_rj, _sr_datum,;
               _sr_naz, _sr_jmj, _sr_kol, , , , , } )
            lVrati := .F.
         ENDIF

         DO WHILE !Eof() .AND. field->id == _sr_id .AND. field->datum <= os_datum_obracuna()
            AAdd( gaDodStavke, ;
               {,,, datum, opis,,, nabvr * nBBK, otpvr * nBBK, amp * nBBK, otpvr * nBBK + amp * nBBK, nabvr * nBBK - amp * nBBK - otpvr * nBBK } )
            nNab9 += nabvr * nBBK;  nOtp9 += otpvr * nBBK;  nAmo9 += amp * nBBK
            nNab3 += nabvr * nBBK;  nOtp3 += otpvr * nBBK;  nAmo3 += amp * nBBK
            nNab2 += nabvr * nBBK;  nOtp2 += otpvr * nBBK;  nAmo2 += amp * nBBK
            nNab1 += nabvr * nBBK;  nOtp1 += otpvr * nBBK;  nAmo1 += amp * nBBK
            SKIP 1
         ENDDO
      ENDIF
      select_o_os_or_sii()
   ENDIF

   cIdSK    := Left( IDKONTO, 3 )
   cIdKonto := IDKONTO
   cIdAm    := IDAM

   nTArea := Select()

   cST1 := "                    UK.GRUPA AMORTIZACIJE '" + cIdAM + "'"

   select_o_konto( cIdKonto )

   cST2 := "          UK.ANALITICKI KONTO '" + cIdKonto + "'" + PadR( konto->naz, 30 ) + "..."

   HSEEK cIdSK

   cST3 := "UK.SINTETICKI KONTO '" + cIdSK + "'" + PadR( konto->naz, 30 ) + "..."
   cST9 := "S V E    U K U P N O"

   SELECT ( nTArea )

   IF cPromj != "3"
      // sveukupno
      nNab9 += nabvr * nBBK;  nOtp9 += otpvr * nBBK;  nAmo9 += amp * nBBK
      // sinteticki
      nNab3 += nabvr * nBBK;  nOtp3 += otpvr * nBBK;  nAmo3 += amp * nBBK
      // analiticki
      nNab2 += nabvr * nBBK;  nOtp2 += otpvr * nBBK;  nAmo2 += amp * nBBK
      // po grupi amortizacije
      nNab1 += nabvr * nBBK;  nOtp1 += otpvr * nBBK;  nAmo1 += amp * nBBK
   ENDIF

   SKIP 1

   IF cIdSK != Left( IDKONTO, 3 ) .OR. Eof()
      // stampaj subtot.amort.
      // stampaj subtot.analit.
      // stampaj subtot.sint.
      gaSubTotal := { ;
         {,  nNab1, nOtp1, nAmo1, nOtp1 + nAmo1, nNab1 - nOtp1 - nAmo1, cST1 }, ;
         {,  nNab2, nOtp2, nAmo2, nOtp2 + nAmo2, nNab2 - nOtp2 - nAmo2, cST2 }, ;
         {,  nNab3, nOtp3, nAmo3, nOtp3 + nAmo3, nNab3 - nOtp3 - nAmo3, cST3 } }
      nNab1 := nOtp1 := nAmo1 := 0
      nNab2 := nOtp2 := nAmo2 := 0
      nNab3 := nOtp3 := nAmo3 := 0
      // stampaj sve ukupno
      IF Eof()
         AAdd( gaSubTotal, {,  nNab9, nOtp9, nAmo9, nOtp9 + nAmo9, nNab9 - nOtp9 - nAmo9, cST9 } )
      ENDIF
   ELSEIF cIdKonto != IDKONTO
      // stampaj subtot.amort.
      // stampaj subtot.analit.
      gaSubTotal := { ;
         {,  nNab1, nOtp1, nAmo1, nOtp1 + nAmo1, nNab1 - nOtp1 - nAmo1, cST1 }, ;
         {,  nNab2, nOtp2, nAmo2, nOtp2 + nAmo2, nNab2 - nOtp2 - nAmo2, cST2 } }
      nNab1 := nOtp1 := nAmo1 := 0
      nNab2 := nOtp2 := nAmo2 := 0
   ELSEIF cIdAm != IDAM
      // stampaj subtot.amort.
      gaSubTotal := { ;
         {,  nNab1, nOtp1, nAmo1, nOtp1 + nAmo1, nNab1 - nOtp1 - nAmo1, cST1 } }
      nNab1 := nOtp1 := nAmo1 := 0
   ELSE
      gaSubTotal := {}
   ENDIF
   SKIP -1

   gaDodStavke := {}

   RETURN .F.



// filter za sadasnju vrijednost i prikaz promjena
// koristi se u sort-u izvjestaja po kontima i amort.grupama
// cPromj: 1-bez promjena/2-sa promjenama/3-samo promjene
// cFiltSadVr: 0-sve/1-koja imaju sadasnju vrijednost/2-koja nemaju sad.vrij.
// --------------------------------------------------------------------------
FUNCTION fsvpromj()

   LOCAL nArr := Select()
   LOCAL cVrati := Chr( 255 )
   LOCAL lImaSadVr := .F.

   IF cPromj <> "3"
      // osnovno sredstvo: ima li sad.vr.
      IF ( field->nabvr - field->otpvr - field->amp ) > 0
         lImaSadVr := .T.
      ENDIF
   ENDIF

   IF !lImaSadVr .AND. cPromj == "2" .OR. cPromj == "3"

      // promjene:ispitujemo ima li sadasnju vrijednost
      _sr_id := field->id

      os_select_promj( _sr_id )
      //SEEK _sr_id

      IF Found()
         DO WHILE !Eof() .AND. field->id == _sr_id .AND. field->datum <= os_datum_obracuna()
            IF ( field->nabvr - field->otpvr - field->amp ) > 0
               lImaSadVr := .T.
            ENDIF
            SKIP 1
         ENDDO
      ELSEIF cPromj == "3"
         SELECT ( nArr )
         RETURN Chr( 255 )
      ENDIF
   ENDIF

   IF cFiltSadVr == "1" .AND. !( lImaSadVr ) .OR. cFiltSadVr == "2" .AND. lImaSadVr
      cVrati := Chr( 255 )
   ELSE
      cVrati := " "
   ENDIF
   SELECT ( nArr )

   RETURN cVrati
