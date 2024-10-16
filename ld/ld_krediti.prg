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

MEMVAR cIdRadn, cIdkred, cNaOsnovu


FUNCTION ld_krediti_menu()

   LOCAL _izbor := 1
   LOCAL _opc := {}
   LOCAL _opcexe := {}

   AAdd( _opc, "1. novi kredit                                  " )
   AAdd( _opcexe, {|| ld_novi_kredit() } )
   AAdd( _opc, "2. pregled/ispravka kredita" )
   AAdd( _opcexe, {|| ld_ispravka_kredita() } )
   AAdd( _opc, "3. lista kredita za jednog kreditora " )
   AAdd( _opcexe, {|| ld_lista_kredita() } )
   AAdd( _opc, "4. brisanje kredita" )
   AAdd( _opcexe, {|| ld_brisanje_kredita() } )
   AAdd( _opc, "5. specifikacija kredita po kreditorima" )
   AAdd( _opcexe, {|| ld_kred_specifikacija() } )

   f18_menu( "kred", .F., _izbor, _opc, _opcexe )

   RETURN .T.




FUNCTION ld_novi_kredit()

   LOCAL lBrojRata := .F.
   LOCAL i
   LOCAL hRec
   LOCAL nOstalo, nTekMj, nTekGodina
   LOCAL cIdRadn  := Space( LEN_IDRADNIK )
   LOCAL nMjesec  := ld_tekuci_mjesec()
   LOCAL nGodina  := ld_tekuca_godina()
   LOCAL cIdKred  := Space( _LK_ )
   LOCAL nIznKred := 0
   LOCAL nRata    := 0
   LOCAL nRata2   := 0
   LOCAL cOsnov   := Space( 20 )
   LOCAL nIRata
   LOCAL hParams

   DO WHILE .T.

      ld_otvori_tabele_kredita()

      Box(, 10, 70 )
      @ box_x_koord() + 1, box_y_koord() + 2   SAY "Mjesec:" GET nMjesec PICT "99"
      @ box_x_koord() + 1, Col() + 2 SAY "Godina:" GET nGodina PICT "9999"
      @ box_x_koord() + 2, box_y_koord() + 2   SAY "Radnik  :" GET cIdRadn  VALID {|| P_Radn( @cIdRadn ), SetPos( box_x_koord() + 2, box_y_koord() + 20 ), QQOut( Trim( radn->naz ) + " (" + Trim( radn->imerod ) + ") " + radn->ime ), .T. }
      @ box_x_koord() + 3, box_y_koord() + 2   SAY "Kreditor:" GET cIdKred PICT "@!" VALID P_Kred( @cIdKred, 3, 21 )
      @ box_x_koord() + 4, box_y_koord() + 2   SAY "Kredit po osnovu:" GET cOsnov PICT "@!"
      @ box_x_koord() + 5, box_y_koord() + 2   SAY "Ukupan iznos kredita:" GET nIznKred PICT "99" + gPicI

      IF lBrojRata
         @ box_x_koord() + 7, box_y_koord() + 2 SAY "Broj rata   :" GET nRata2 PICT "9999" VALID nRata2 > 0
      ELSE
         @ box_x_koord() + 7, box_y_koord() + 2 SAY "Rata kredita:" GET nRata PICT gpici VALID nRata > 0
      ENDIF

      READ

      ESC_BCR
      BoxC()

      IF lBrojRata
         nRata := Round( nIznKred / nRata2, 2 )
         IF nRata * nRata2 - nIznKred < 0
            nRata += 0.01
         ENDIF
      ENDIF

      // SELECT radkr
      // "2", idradn + idkred + naosnovu + str(godina) + str(mjesec)
      // SET ORDER TO TAG "2"

      seek_radkr_2( cIdRadn, cIdkred, cOsnov, NIL, NIL )
      PRIVATE nRec := 0

      IF !Eof()

         IF Pitanje( , "Stavke vec postoje. Zamijeniti novim podacima ?", "D" ) == "N"
            MsgBeep( "Rate nisu formirane! Unesite novu osnovu kredita za zadanog kreditora!" )
            my_close_all_dbf()
            RETURN .F.
         ELSE
            hRec := hb_Hash()
            hRec[ "idradn" ]    := cIdRadn
            hRec[ "idkred" ]    := cIdKred
            hRec[ "naosnovu" ]  := cOsnov
            delete_rec_server_and_dbf( "ld_radkr", hRec, 2, "FULL" )
         ENDIF

      ENDIF


      nOstalo := nIznKred
      nTekMj := nMjesec
      nTekGodina := nGodina

      i := 0
      nTekMj := nMjesec - 1

      run_sql_query( "BEGIN" )
      IF !f18_lock_tables( { "ld_radkr" }, .T. )
         run_sql_query( "ROLLBACK" )
         RETURN .F.
      ENDIF

      DO WHILE .T.

         IF nTeKMj + 1 > 12
            nTekMj := 1
            ++nTekGodina
         ELSE
            nTekMj++
         ENDIF

         nIRata := nRata

         IF nIRata > 0 .AND. ( nOstalo - nIRata < 0 )
            // rata je pozitivna
            nIRata := nOstalo
         ENDIF

         IF nIRata < 0 .AND. ( nOstalo - nIRata > 0 )
            // rata je negativna
            nIRata := nOstalo
         ENDIF

         IF Round( nIRata, 2 ) <> 0

            APPEND BLANK
            hRec := dbf_get_rec()

            hRec[ "idradn" ]   := cIdRadn
            hRec[ "idkred" ]   := cIdKred
            hRec[ "naosnovu" ] := cOsnov
            hRec[ "mjesec" ]   := nTekMj
            hRec[ "godina" ]   := nTekGodina
            hRec[ "iznos" ]    := nIRata

            update_rec_server_and_dbf( "ld_radkr", hRec, 1, "CONT" )
            ++i

         ENDIF

         nOstalo := nOstalo - nIRata
         IF Round( nOstalo, 2 ) == 0
            EXIT
         ENDIF

      ENDDO

      hParams := hb_Hash()
      hParams[ "unlock" ] := { "ld_radkr" }
      run_sql_query( "COMMIT", hParams )

      log_write( "F18_DOK_OPER: ld unos novog kredita - radnik: " + cIdRadn + " iznos: " + AllTrim( Str( nIznKred ) ), 2 )

      PRIVATE cDn := "N"

      Box(, 5, 60 )
#ifndef TEST
      SET CONFIRM OFF
#endif
      @ box_x_koord() + 1, box_y_koord() + 2 SAY "Za radnika " + cIdRadn + " kredit je formiran na " + Str( i, 3 ) + " rata"
      @ box_x_koord() + 3, box_y_koord() + 2 SAY "Prikazati pregled kamata:" GET cDN PICT "@!"
      READ
      BoxC()

#ifndef TEST
      SET CONFIRM ON
#endif

      my_close_all_dbf()

      IF ( cDn == "D" )
         ld_ispravka_kredita( cIdRadn, cIdKred, cOsnov )
      ENDIF

   ENDDO

   my_close_all_dbf()

   RETURN .T.




FUNCTION ld_krediti_redefinisanje_rata()

   LOCAL GetList := {}
   LOCAL nTRata
   LOCAL nNRata
   LOCAL cNaOsnovu := Space( 20 )
   LOCAL _rec
   LOCAL hParams

   Box(, 6, 60 )

   @ box_x_koord() + 1, box_y_koord() + 2 SAY "*** podaci o kreditu" COLOR f18_color_i()

   @ box_x_koord() + 3, box_y_koord() + 2 SAY "kredit na osnovu" GET cNaOsnovu

   READ

   // SELECT radkr
   // SET ORDER TO TAG "4"
   // SEEK Str( _godina, 4 ) + Str( _mjesec, 2 ) + _idradn + cNaOsnovu
   seek_radkr( _godina, _mjesec, _idradn, NIL, cNaOsnovu, "4" ) // seek_radkr( nGodina, nMjesec, cIdRadn, cIdKred, cNaOsnovu, cTag )
   // SET ORDER TO TAG "4"
   GO TOP


   nTRata := field->iznos
   nNRata := nTRata

   @ box_x_koord() + 4, box_y_koord() + 2 SAY8 "tekuća rata kredita = " + ;
      AllTrim( Str( nTRata ) ) + " KM"
   @ box_x_koord() + 5, box_y_koord() + 2 SAY "rata kredita za obracun" GET nNRata VALID nNRata <> 0
   READ

   BoxC()

   IF nNRata <> nTRata

      // SELECT radkr
      // SET ORDER TO TAG "4"
      // SEEK Str( _godina, 4 ) + Str( _mjesec, 2 ) + _idradn + cNaOsnovu
      seek_radkr( _godina, _mjesec, _idradn, NIL, cNaOsnovu, "4" )
      // SET ORDER TO TAG "4"
      GO TOP

      cKreditor := idkred
      cIdRadn := idradn

      // SET ORDER TO TAG "2"
      // SEEK cIdRadn + cKreditor + cNaOsnovu + Str( _godina, 4 ) + Str( _mjesec, 2 )
      seek_radkr_2( cIdRadn, cKreditor, cNaOsnovu, _godina, _mjesec )

      nTotalKr := 0

      run_sql_query( "BEGIN" )
      IF !f18_lock_tables( { "ld_radkr" }, .T. )
         run_sql_query( "ROLLBACK" )
         RETURN .F.
      ENDIF


      DO WHILE !Eof() .AND. cKreditor == idkred  .AND. idradn = _idradn .AND. naosnovu == cNaOsnovu

         nTotalKr += iznos

         _rec := dbf_get_rec()
         delete_rec_server_and_dbf( "ld_radkr", _rec, 1, "CONT" )

         SKIP
      ENDDO


      nOstalo := nTotalKr
      nTekMj := _mjesec
      nTekGodina := _godina

      i := 0
      nTekMj := nMjesec - 1

      DO WHILE .T.
         IF nTeKMj + 1 > 12
            nTekMj := 1
            ++nTekGodina
         ELSE
            nTekMj++
         ENDIF

         nIRata := nNRata

         IF nIRata > 0 .AND. ( nOstalo - nIRata < 0 )
            // rata je pozitivna
            nIRata := nOstalo
         ENDIF

         IF nIRata < 0 .AND. ( nOstalo - nIRata > 0 )
            // rata je negativna
            nIRata := nOstalo
         ENDIF

         IF Round( nIRata, 2 ) <> 0

            APPEND BLANK
            _rec := dbf_get_rec()
            _rec[ "idradn" ] := cIdRadn
            _rec[ "mjesec" ] := nTekMj
            _rec[ "godina" ] := nTekGodina
            _rec[ "idkred" ] := cKreditor
            _rec[ "iznos" ] := nIRata
            _rec[ "naosnovu" ] := cNaOsnovu

            update_rec_server_and_dbf( "ld_radkr", _rec, 1, "CONT" )

            ++i

         ENDIF

         nOstalo := nOstalo - nIRata

         IF Round( nOstalo, 2 ) == 0
            EXIT
         ENDIF
      ENDDO


      hParams := hb_Hash()
      hParams[ "unlock" ] := { "ld_radkr" }
      run_sql_query( "COMMIT", hParams )


      log_write( "F18_DOK_OPER: ld, redefinisanje kredita za radnika: " + cIdRadn, 2 )

   ENDIF

   RETURN nNRata



FUNCTION SumKredita()

   LOCAL fUsed := .T.
   LOCAL cTRada := " "
   LOCAL hParams

   PushWA()

   // SELECT ( F_RADKR )
   // IF !Used()
   // fUsed := .F.
   // /  O_RADKR
   // ENDIF

   IF gVarObracun == "2"
      cTRada := get_ld_rj_tip_rada( _idradn, _idrj )
      IF cTRada $ "A#U#P#S"
         PopWa()
         RETURN 0
      ENDIF
   ENDIF

   seek_radkr( _godina, _mjesec, _idradn )

   nIznos := 0

   run_sql_query( "BEGIN" )
   IF !f18_lock_tables( { "ld_radkr" }, .T. )
      run_sql_query( "ROLLBACK" )
      RETURN .F.
   ENDIF

   DO WHILE !Eof() .AND. _godina == godina .AND. _mjesec == mjesec .AND. idradn == _idradn

      nIznos += field->iznos

      hRec := dbf_get_rec()
      hRec[ "placeno" ] := iznos

      update_rec_server_and_dbf( "ld_radkr", hRec, 1, "CONT" )

      SKIP

   ENDDO

   hParams := hb_Hash()
   hParams[ "unlock" ] := { "ld_radkr" }
   run_sql_query( "COMMIT", hParams )

   IF !fUsed
      SELECT radkr
      USE
   ENDIF

   PopWa()

   RETURN nIznos



FUNCTION ld_iznosi_za_kredit( _idradn, cIdkred, cNaOsnovu, _mjesec, _godina )

   LOCAL nUkupno, nPlaceno, nNTXORd

   // LOCAL fused := .T.

   PushWA()

/*
   SELECT ( F_RADKR )

   IF !Used()
      fUsed := .F.
    --  O_RADKR
      SET ORDER TO TAG "2"
      // "RADKRi2","idradn+idkred+naosnovu itd..."
   ELSE
      nNTXORD := IndexOrd()
      SET ORDER TO TAG "2"
   ENDIF
*/

   seek_radkr_2( _idradn, cIdkred, cNaOsnovu, ;           // seek_radkr_2( cIdRadn, cIdkred, cNaOsnovu,
        NIL, NIL, NIL, { F_RADKR_2, "RADKR_2" } ) // nGodina, nMjesec, cTag, aWorkarea )

   nUkupno := 0
   nPlaceno := 0

   SELECT radkr_2
   DO WHILE !Eof() .AND. AllTrim( idradn ) == AllTrim( _idradn ) .AND. AllTrim( idkred ) == AllTrim( cIdKred ) .AND. naosnovu == cNaOsnovu
      nUkupno += iznos

      IF ( mjesec > _mjesec .AND. godina >= _godina )
         SKIP
         LOOP
      ELSE
         nPlaceno += placeno
      ENDIF

      SKIP
   ENDDO
   USE

   // IF !fUsed
   // SELECT radkr
   // USE
   // ENDIF

   PopWa()

   RETURN { nUkupno, nPlaceno }




FUNCTION ld_lista_kredita()

   PRIVATE fSvi
   PRIVATE nR := nIzn := nIznP := 0
   PRIVATE nUkIzn := nUkIznP := nUkIRR := 0
   PRIVATE nCol1 := 10
   PRIVATE lRjRadn := .F.
   PRIVATE cIdRj

   o_kred()
   o_ld_radn()

   IF FieldPos( "IDRJ" ) <> 0
      lRjRadn := .T.
      o_ld_rj()
      cIdRj := "  "
   ENDIF

   // O_RADKR

   PRIVATE m := "----- " + Replicate( "-", LEN_IDRADNIK ) + " ------------------------------- " + Replicate( "-", 39 )

   cIdKred := Space( _LK_ )

   cNaOsnovu := PadR( ".", 20 )
   cIdRadnaJedinica := Space( 2 )
   nGodina := ld_tekuca_godina(); nMjesec := ld_tekuci_mjesec()
   PRIVATE cRateDN := "D", cAktivni := "D"

   Box(, 13, 60 )
   IF lRjRadn
      @ box_x_koord() + 1, box_y_koord() + 2 SAY "RJ (prazno=sve): " GET cIdRj  VALID {|| Empty( cIdRj ) .OR. P_LD_Rj( @cIdRj ) } PICT "@!"
   ENDIF
   @ box_x_koord() + 2, box_y_koord() + 2 SAY "Kreditor ('.' svi): " GET cIdKred  VALID {|| cIdkred = '.' .OR. P_Kred( @cIdKred ) } PICT "@!"
   @ box_x_koord() + 3, box_y_koord() + 2 SAY "Na osnovu ('.' po svim osnovama):" GET cNaOsnovu PICT "@!"
   @ box_x_koord() + 4, box_y_koord() + 2 SAY "Prikazati rate kredita D/N/J/R/T:"
   @ box_x_koord() + 5, box_y_koord() + 2 SAY "D - prikazati sve rate"
   @ box_x_koord() + 6, box_y_koord() + 2 SAY "N - prikazati samo broj rata i ukupan iznos"
   @ box_x_koord() + 7, box_y_koord() + 2 SAY "J - samo jedna rata"
   @ box_x_koord() + 8, box_y_koord() + 2 SAY "R - partija,br.rata,iznos,rata,ostalo"
   @ box_x_koord() + 9, box_y_koord() + 2 SAY "T - trenutno stanje" GET cRateDN PICT "@!" VALID cRateDN $ "DNJRT"
   @ box_x_koord() + 10, box_y_koord() + 2 SAY "Prikazi samo aktivne-neotplacene kredite D/N" GET cAktivni PICT "@!" VALID cAktivni $ "DN"
   READ
   ESC_BCR

   IF cRateDN $ "JR"
      @ box_x_koord() + 12, box_y_koord() + 2 SAY "Prikazati ratu od godina/mjesec:" GET nGodina PICT "9999"
      @ box_x_koord() + 12, Col() + 1 SAY "/" GET nMjesec PICT "99"
      READ
      ESC_BCR
   ENDIF
   IF lRjRadn .AND. Empty( cIdRj )
      lRazdvojiPoRj := ( Pitanje(, "Razdvojiti spiskove po radnim jedinicama? (D/N)", "N" ) == "D" )
   ELSE
      lRazdvojiPoRj := .F.
   ENDIF
   BoxC()

   IF Trim( cNaOsnovu ) == "."
      cNaOsnovu := ""
   ENDIF

   o_radkr_all_rec()

   IF lRazdvojiPoRj

      SET RELATION TO idradn into radn

      Box(, 2, 30 )
      nSlog := 0
      cSort1 := "radn->idRj+idKred+naOsnovu+idRadn"
      cFilt := ".t."
      IF !cIdKred = "."
         cFilt += ".and. idKred==" + _filter_quote( cIdKred )
      ENDIF
      INDEX ON &cSort1 TO "TMPRK" FOR &cFilt
      BoxC()

      GO TOP

   ELSE
      IF lRjRadn .AND. !Empty( cIdRj )
         SET RELATION TO idradn into radn
         SET FILTER TO radn->idRj == cIdRj
      ENDIF
      SET ORDER TO TAG "3"
      SEEK cIdKred + cNaOsnovu // radkr all records
   ENDIF

   nRbr := 0

   IF cRateDN == "R"
      m += REPL( "-", 16 )
   ENDIF

   IF cIdkred = '.'
      fSvi := .T.
      GO TOP
   ELSE
      IF !lRazdvojiPoRj .AND. !Found()
         MsgBeep( "Nema podataka!" )
         CLOSERET
      ENDIF
      fSvi := .F.
   ENDIF

   START PRINT CRET

   ld_lista_kredita_zaglavlje()

   DO WHILE !Eof()

      IF lRazdvojiPoRj
         cIdTekRj := radn->idRj
         ?
         ? "RJ:", radn->idRj, "-", get_ld_rj_naz(  cIdTekRj )
         ?
      ENDIF

      cIdKred := IdKred

      select_o_kred( cIdKred )

      SELECT radkr

      IF fSvi
         ?
         ? StrTran( m, "-", "*" )
         ? tip_organizacije() + ":", cIdKred, kred->naz
         ? StrTran( m, "-", "*" )
      ENDIF
      cOsn := ""
      nCol1 := 20

      DO WHILE !Eof() .AND. idkred = cIdKred .AND. naosnovu = cNaOsnovu .AND. if( lRazdvojiPoRj, radn->idRj == cIdTekRj, .T. )

         PRIVATE cOsn := naosnovu
         cIdRadn := idradn
         nIzn := nIznP := 0

         IF cAktivni == "D"
            nTekRec := RecNo()
            RKgod := RADKR->Godina
            RKmjes := RADKR->Mjesec
            DO WHILE !Eof() .AND. idkred = cIdkred .AND. cOsn == naosnovu .AND. idradn == cIdradn
               nIzn += RADKR->Iznos
               nIznP += RADKR->Placeno
               RKgod := RADKR->Godina
               RKmjes := RADKR->Mjesec
               SKIP 1
            ENDDO
            IF nIzn > nIznP .OR. ( nIzn == nIznP .AND. RKgod == nGodina .AND. RKmjes >= nMjesec )
               GO nTekRec
            ELSE
               LOOP
            ENDIF
         ENDIF

         IF cNaOsnovu == "" .AND. cOsn <> naosnovu
            ?
            ? m
            ? "KREDIT PO OSNOVI:", naosnovu
            ? m
         ENDIF

         select_o_radn( cIdradn )
         SELECT radkr

         ?
         ? Str( ++nRbr, 4 ) + ".", cIdRadn, RADNIK_PREZ_IME

         IF cRateDN == "D"
            ?? " Osnov:", cOsn, Replicate( "_", 11 )
         ENDIF

         nR := nIzn := nIznP := 0
         nCol1 := 64
         nIRR := 0

         DO WHILE !Eof() .AND. idkred = cidkred .AND. cosn == naosnovu .AND. idradn == cidradn
            nKoef := 1

            IF cRateDN <> "J" .OR. ( godina == nGodina .AND. mjesec == nMjesec )
               ++nR
               nIzn += iznos * nKoef
               nIznP += placeno
               IF iznos * nKoef == 0 .AND. cRateDN == "R"
                  --nR
               ENDIF  // mozda i za sve var. ?!
               IF nMjesec == mjesec .AND. nGodina == godina
                  nIRR := iznos * nKoef
               ENDIF
            ENDIF

            IF cRateDN == "D"
               ? Space( 47 ), Str( mjesec ) + "/" + Str( godina )
               nCol1 := PCol() + 1
               @ PRow(), PCol() + 1 SAY iznos * nKoef PICT gpici
            ELSEIF cRateDN == "J"
               IF godina == nGodina .AND. mjesec == nMjesec
                  ?? "", Str( mjesec ) + "/" + Str( godina )
                  nCol1 := PCol() + 1
                  @ PRow(), PCol() + 1 SAY iznos * nKoef PICT gpici
                  @ PRow(), PCol() + 1 SAY "___________"
               ENDIF
            ENDIF
            SKIP 1
         ENDDO

         IF cRateDN == "N"
            @ PRow(), PCol() + 1 SAY nR PICT "9999"
            nCol1 := PCol() + 1
            @ PRow(), PCol() + 1 SAY nIzn PICT gpici
            @ PRow(), PCol() + 1 SAY "___________"
         ENDIF

         IF cRateDN == "T"
            @ PRow(), PCol() + 1 SAY ""
            nCol1 := PCol() + 1
            @ PRow(), PCol() + 1 SAY nIzn PICT gpici
            @ PRow(), PCol() + 1 SAY nIznP PICT gpici
            @ PRow(), PCol() + 1 SAY nIzn - nIznP PICT gpici
         ENDIF

         IF cRateDN == "R"
            @ PRow(), PCol() + 1 SAY cOsn
            @ PRow(), PCol() + 1 SAY nR PICT "9999"
            nCol1 := PCol() + 1
            @ PRow(), PCol() + 1 SAY nIzn PICT gpici
            @ PRow(), PCol() + 1 SAY nIRR PICT gpici
            @ PRow(), PCol() + 1 SAY nIzn - nIznP PICT gpici
         ENDIF

         nUkIzn += nIzn
         nUkIznP += nIznP
         nUkIRR += nIRR
      ENDDO

      ? m
      ? "UKUPNO:"

      @ PRow(), nCol1 SAY nUkIzn PICT gpici

      IF cRatedn == "T"
         @ PRow(), PCol() + 1 SAY nUkIznP  PICT gpici
         @ PRow(), PCol() + 1 SAY nUkizn - nUkIznP  PICT gpici
      ENDIF

      IF cRatedn == "R"
         @ PRow(), PCol() + 1 SAY nUkIRR          PICT gpici
         @ PRow(), PCol() + 1 SAY nUkizn - nUkIznP  PICT gpici
      ENDIF

      ? m

      IF !fsvi .AND. !lRazdvojiPoRj
         EXIT
      ENDIF

   ENDDO

   FF
   ENDPRINT

   my_close_all_dbf()

   RETURN .T.



FUNCTION ld_lista_kredita_zaglavlje()

   ?
   P_10CPI

   IF cRateDN == "R"
      ?? "LD, izvjestaj na dan:", Date()
      ? "FIRMA   :", self_organizacija_naziv()
      ?
      IF !fsvi
         ? "Kreditor:", cidkred, kred->naz
      ENDIF
      ? "Ziro-r. :", kred->ziro
      ?
      ? PadC( "DOJAVA KREDITA ZA MJESEC : " + Str( nMjesec ) + ". GODINE: " + Str( nGodina ) + ".", 78 )
   ELSE
      ? "LD: SPISAK KREDITA, izvjestaj na dan:", Date()
      IF !fsvi
         ? "Kreditor:", cidkred, kred->naz
      ENDIF
      IF !( cNaOsnovu == "" )
         ?? "   na osnovu:", cnaosnovu
      ENDIF
   ENDIF

   IF lRjRadn .AND. !Empty( cIdRj )
      ? "RJ:", cIdRj, "-", get_ld_rj_naz( cIdRj )
   ENDIF

   IF cRateDN == "R"
      P_COND
   ELSE
      P_12CPI
   ENDIF

   ?
   ? m
   IF cRateDN == "N"
      ? " Rbr *" + PadC( "Sifra ", LEN_IDRADNIK ) + "*    Radnik                         Br.Rata    Iznos      Potpis"
   ELSEIF cRateDN == "T"
      ? " Rbr *" + PadC( "Sifra ", LEN_IDRADNIK ) + "*    Radnik                           Ukupno       Placeno       Ostalo"
   ELSEIF cRateDN == "R"
      ? " Red.*" + PadC( " ", LEN_IDRADNIK ) + "*                                  Partija kr.   Broj     Iznos                   Ostatak"
      ? " br. *" + PadC( "Sifra ", LEN_IDRADNIK ) + "*    Radnik                        (na osnovu)   rata     kredita      Rata         duga "
   ELSE
      ? " Rbr *" + PadC( "Sifra ", LEN_IDRADNIK ) + "*    Radnik                        Mjesec/godina/Rata"
   ENDIF
   ? m

   RETURN





FUNCTION P_Krediti

   PARAMETERS cIdRadn, cIdkred, cNaOsnovu

   LOCAL nI, lRet
   PRIVATE ImeKol

   PushWA()

   select_o_radn( cIdRadn )
   seek_radkr_2( cIdRadn, NIL, NIL, NIL, NIL, "3", NIL)  // seek_radkr_2( cIdRadn, cIdkred, cNaOsnovu, nGodina, nMjesec, aWorkarea )


   PRIVATE Imekol := {}
   AAdd( ImeKol, { "Kreditor",      {|| IdKred   } } )
   AAdd( ImeKol, { "Osnov",         {|| NaOsnovu } } )
   AAdd( ImeKol, { "Mjesec",        {|| Str( mjesec, 2, 0 )   } } )
   AAdd( ImeKol, { "Godina",        {|| Str( godina, 4, 0 )   } } )
   AAdd( ImeKol, { "Iznos",         {|| Iznos    } } )

   Kol := {}

   FOR nI := 1 TO Len( ImeKol )
      AAdd( Kol, nI )
   NEXT

   Box(, 18, 60 )
   lRet := my_browse( "PKred", 18, 60, {|| ld_lista_kredita_key_handler() }, "Radnik-krediti za " + cIdradn, "", , , , )
   Boxc()

   // SET SCOPE TO

   PopwA()

   RETURN lRet




FUNCTION ld_lista_kredita_key_handler()

   IF Ch == K_ENTER
      cIdKred := radkr->idkred
      cNaOsnovu := radkr->naosnovu
      RETURN DE_ABORT
   ENDIF

   RETURN DE_CONT




/* GodMjesec(nGodina,nMjesec,nPomak)
 *     eg. GodMjesec(2002,4,-6) -> {2001,10}
 *   param: nGodina
 *   param: nMjesec
 *   param: nPomak
 */

FUNCTION GodMjesec( nGodina, nMjesec, nPomak )

   LOCAL nPGodina
   LOCAL nPMjesec
   LOCAL nVgodina := 0

   IF nPomak < 0  // vrati se unazad
      nPomak := Abs( nPomak )
      nVGodina := Int( nPomak / 12 )
      nPomak := nPomak % 12
      IF nMjesec - nPomak < 1
         nPGodina := nGodina - 1
         nPMjesec := 12 + nMjesec - nPomak
      ELSE
         nPGodina := nGodina
         nPMjesec := nMjesec - nPomak
      ENDIF
      nPGodina := nPGodina - nVGodina
   ELSE
      nVGodina := Int( nPomak / 12 )
      nPomak := nPomak % 12
      IF nMjesec + nPomak > 12
         nPGodina := nGodina + 1
         nPMjesec := nMjesec + nPomak - 12
      ELSE
         nPGodina := nGodina
         nPMjesec := nMjesec + nPomak
      ENDIF
      nPGodina := nPGodina + nVGodina
   ENDIF

   RETURN { nPGodina, nPMjesec }





FUNCTION DatADD( dDat, nMjeseci, nGodina )

   LOCAL aRez
   LOCAL cPom := ""

   aRez := GodMjesec( Year( dDat ), Month( dDat ), nMjeseci + 12 * nGodina )
   cPom := Str( aRez[ 1 ], 4 )
   cPom += PadL( AllTrim( Str( aRez[ 2 ], 2 ) ), 2, "0" )
   cPom += PadL( AllTrim( Str( Day( dDat ), 2 ) ), 2, "0" )

   RETURN SToD( cPom )




/* DatRazmak(dDatDo,dDatOd,nMjeseci,nDana)
 *     Datumski razmak izrazen u: mjeseci, dana. Poziv: DatRazmak("15.07.2002","05.06.2001",@nMjeseci,@nDana)
 *   param:
 *   param:
 *   param:
 *   param:
 */
FUNCTION DatRazmak( dDatDo, dDatOd, nMjeseci, nDana )

   LOCAL aRez
   LOCAL cPom := ""
   LOCAL lZadnjiDan := .F.

   nMjeseci := 0
   nDana := 0
   dNextMj := dDatOd
   i := 0

   IF Day( dDatOd ) = LastDayOM( dDatOd )
      lZadnjiDan := .T.
   ENDIF

   IF Month( dDatDo ) == Month( dDatOd ) .AND. Day( dDatDo ) = Day( dDatOd )
      // isti mjesec, isti dan
      nMjeseci := ( Year( dDatDo ) - Year( dDatOd ) ) * 12
      nDana := 0
      RETURN
   ENDIF

   DO WHILE .T.
      // predvidjen je razmak do 36 mjeseci
      IF Month( dNextMj ) = Month( dDatDO ) .AND. Year( dNextMj ) = Year( dDatDo )
         // uletili smo u isti mjesec
         nDana := Day( dDatDo ) - Day( dNextMj )
         IF nDana < 0  // moramo se vratiti mjesec unazad
            dNextMj := AddMonth( dNextMj, - 1 )
            --nMjeseci
            IF nMjeseci = 0  // samo dva krnjava mjeseca
               nDana := ( Day( EoM( dDatOd ) ) - Day( dDatOd ) + 1 ) + Day( dDatDo ) - 1
            ELSE
               nDana := ( Day( EoM( dNextMj ) ) - Day( dDatOd ) + 1 ) + Day( dDatDo ) - 1
            ENDIF
         ELSEIF nDana >= 0
            // not implemented
         ENDIF
         EXIT
      ENDIF

      dNextMj := AddMonth( dNextMj, 1 )

      IF lZadnjiDan  // zadnji dan u mjesecu
         dNextMj := EoM( dNextMj )
      ENDIF

      nMjeseci++
      ++i
      IF i > 200
         MsgBeep( "jel to neko lud ovdje ?" )
         EXIT
      ENDIF
   ENDDO

   RETURN



FUNCTION DanaUmjesecu( dDatum )

   LOCAL nDatZM

   nDatZM := EoM( dDatum )

   RETURN Day( nDatZM )



/* DatZadUMjesecu(dDatum)
 *     Vraca datum zadnjed u mjesecu
 *   param: dDatum
 */

FUNCTION DatZadUMjesecu( dDatum )

   LOCAL nDana
   LOCAL dPoc

   dPoc := dDatum
   nDana := Day( dDatum )
   DO WHILE .T.
      dDatum++
      IF Month( dPoc ) = Month( dDatum )
         nDana := Day( dDatum )
      ELSE
         EXIT  // uletio sam usljedeci mjesec
      ENDIF
   ENDDO

   RETURN dDatum - 1


FUNCTION ld_brisanje_kredita()

   LOCAL _rec
   LOCAL hParams

   cIdRadn := Space( LEN_IDRADNIK )
   cIdKRed := Space( _LK_ )
   cNaOsnovu := Space( 20 )
   cBrisi := "N"

   ld_otvori_tabele_kredita()

   SET ORDER TO TAG "2"

   Box( "#BRISANJE NEOTPLACENIH RATA KREDITA", 9, 77 )
   @ box_x_koord() + 2, box_y_koord() + 2 SAY "Radnik:   " GET cIdRadn  VALID {|| P_Radn( @cIdRadn ), SetPos( box_x_koord() + 2, box_y_koord() + 20 ), ;
      QQOut( Trim( radn->naz ) + " (" + Trim( radn->imerod ) + ") " + radn->ime ), ;
      P_Krediti( cIdRadn, @cIdKred, @cNaOsnovu ), .T. }

   @ box_x_koord() + 3, box_y_koord() + 2 SAY "Kreditor: " GET cIdKred  VALID P_Kred( @cIdKred, 3, 21 ) PICT "@!"
   @ box_x_koord() + 4, box_y_koord() + 2 SAY "Na osnovu:" GET cNaOsnovu PICT "@!"
   @ box_x_koord() + 6, box_y_koord() + 2, box_x_koord() + 8, box_y_koord() + 76 BOX "         " COLOR "GR+/R"
   @ box_x_koord() + 7, box_y_koord() + 8 SAY "Jeste li 100% sigurni da zelite izbrisati ovaj kredit ? (D/N)" COLOR "GR+/R"
   @ Row(), Col() + 1 GET cBrisi VALID cBrisi $ "DN" PICT "@!" COLOR "N/W"
   READ
   ESC_BCR
   BoxC()

   IF cBrisi == "N"
      my_close_all_dbf()
      RETURN .F.
   ENDIF

   seek_radkr_2( cIdRadn, cIdKred, cNaOsnovu )

   run_sql_query( "BEGIN" )
   IF !f18_lock_tables( { "ld_radkr" }, .T. )
      run_sql_query( "ROLLBACK" )
      RETURN .F.
   ENDIF


   nStavki := 0
   DO WHILE !Eof() .AND. idradn + idkred + naosnovu == cIdRadn + cIdKred + cNaOsnovu
      SKIP 1
      nRec := RecNo()
      SKIP -1
      IF placeno = 0
         ++nStavki
         _rec := dbf_get_rec()
         delete_rec_server_and_dbf( "ld_radkr", _rec, 1, "CONT" )
      ENDIF
      GO ( nRec )
   ENDDO


   hParams := hb_Hash()
   hParams[ "unlock" ] := { "ld_radkr" }
   run_sql_query( "COMMIT", hParams )


   IF nStavki > 0
      MsgBeep( "Sve neotplacene rate (ukupno " + AllTrim( Str( nStavki ) ) + ") kredita izbrisane!" )
   ELSE
      MsgBeep( "Nista nije izbrisano. Za izabrani kredit ne postoje neotplacene rate!" )
   ENDIF

   my_close_all_dbf()

   RETURN



FUNCTION ld_otvori_tabele_kredita()

   o_ld_rj()
   o_kred()
   o_str_spr()
   o_ops()
   o_ld_radn()
   // O_RADKR

   RETURN
