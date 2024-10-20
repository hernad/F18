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



FUNCTION os_amortizacija_po_stopama()

   LOCAL _sr_id, _sr_id_rj, _sr_id_am, _sr_dat_otp, _sr_datum
   LOCAL cIdAmort := Space( 8 ), cidsk := "", ndug := ndug2 := npot := npot2 := ndug3 := npot3 := 0
   LOCAL nCol1 := 10, qIdAm := Space( 8 )
   LOCAL lExpRpt := .F.
   LOCAL _mod_name := "OS"

   IF gOsSii == "S"
      _mod_name := "SII"
   ENDIF

   //o_amort()
   //o_rj()

   //o_os_sii_promj()
   o_os_sii()

   cIdRj := Space( 4 )
   cPromj := "2"
   cPocinju := "N"
   cFiltSadVr := "0"
   cFiltK1 := Space( 40 )
   cON := " " // novo!

   cBrojSobe := Space( 6 )
   lBrojSobe := .F.

   cExportXlsxDN := "N"

   Box(, 12, 77 )
   DO WHILE .T.
      @ box_x_koord() + 1, box_y_koord() + 2 SAY "Radna jedinica (prazno - svi):" GET cIdRj ;
         VALID {|| Empty( cIdRj ) .OR. P_RJ( @cIdRj ), if( !Empty( cIdRj ), cIdRj := PadR( cIdRj, 4 ), .T. ), .T. }

      @ box_x_koord() + 1, Col() + 2 SAY "sve koje pocinju " GET cPocinju VALID cPocinju $ "DN" PICT "@!"
      @ box_x_koord() + 2, box_y_koord() + 2 SAY "Grupa amort.stope (prazno - sve):" GET qIdAm PICT "@!" VALID Empty( qidAm ) .OR. P_Amort( @qIdAm )
      @ box_x_koord() + 4, box_y_koord() + 2 SAY "Za sredstvo prikazati vrijednost:"
      @ box_x_koord() + 5, box_y_koord() + 2 SAY "1 - bez promjena"
      @ box_x_koord() + 6, box_y_koord() + 2 SAY "2 - osnovni iznos + promjene"
      @ box_x_koord() + 7, box_y_koord() + 2 SAY "3 - samo promjene           " GET cPromj VALID cpromj $ "123"
      @ box_x_koord() + 8, box_y_koord() + 2 SAY "Filter po sadasnjoj vr.(0-sve,1-samo koja je imaju,2-samo koja je nemaju):" GET cFiltSadVr VALID cFiltSadVr $ "012" PICT "9"
      @ box_x_koord() + 9, box_y_koord() + 2 SAY "Filter po grupaciji K1:" GET cFiltK1 PICT "@!S20"
      @ box_x_koord() + 10, box_y_koord() + 2 SAY "Prikaz svih os ( )      /   neotpisanih (N)     / otpisanih   (O) "
      @ box_x_koord() + 11, box_y_koord() + 2 SAY "/novonabavljenih   (B) / iz proteklih godina (G)" GET cON VALID con $ "ONBG " PICT "@!"

      @ box_x_koord() + 12, box_y_koord() + 2 SAY "Export u XLSX (D/N)?" GET cExportXlsxDN VALID cExportXlsxDN $ "DN" PICT "@!"
      read; ESC_BCR
      aUsl1 := Parsiraj( cFiltK1, "K1" )
      IF aUsl1 <> NIL; exit; ENDIF
   ENDDO
   BoxC()

   cIdRj := PadR( cIdRj, 4 )

   lExpRpt := ( cExportXlsxDN == "D" )

   IF lExpRpt
      aDbfFields := get_exp_fields()
      xlsx_export_init( aDbfFields )
   ENDIF

   //o_amort()
   //o_rj()

   o_os_sii_promj()
   o_os_sii()

   IF Empty( qidAm ); qidAm := ""; ENDIF
   IF Empty( cIdRj ); cIdRj := ""; ENDIF

   IF cPocinju == "D"
      cIdRj := Trim( cIdRj )
   ENDIF

   IF Empty( cIdRj )
      select_o_os_or_sii()
      cSort1 := "idam+idrj+id"
      INDEX ON &cSort1 TO "TMPOS" FOR &aUsl1
      SEEK qidAm
   ELSE
      select_o_os_or_sii()
      cSort1 := "idrj+idam+id"
      INDEX ON &cSort1 TO "TMPOS" FOR &aUsl1
      SEEK cIdRj + qidAm
   ENDIF
   IF !Empty( qIdAm ) .AND. !( idam == qIdAm )
      MsgBeep( "Ne postoje trazeni podaci!" )
      CLOSERET
   ENDIF

   os_rpt_default_valute()

   start PRINT cRet
   PRIVATE nStr := 0  // strana

   select_o_rj( cIdRj )

   select_o_os_or_sii()

   P_10CPI
   ? tip_organizacije() + ":", self_organizacija_naziv()

   IF !Empty( cIdRj )
      ? "Radna jedinica:", cIdRj, rj->naz
   ENDIF

   ? _mod_name + ": Pregled obracuna amortizacije po grupama amortizacionih stopa"
   ?? "", PrikazVal(), "    Datum:", os_datum_obracuna()

   IF !Empty( cFiltK1 )
      ? "Filter grupacija K1 pravljen po uslovu: '" + Trim( cFiltK1 ) + "'"
   ENDIF

   P_COND2

   PRIVATE m := "----- ---------- ---- -------- ------------------------------ --- ------" + REPL( " " + REPL( "-", Len( gPicI ) ), 5 )

   PRIVATE nrbr := 0

   nDug := nPot1 := nPot2 := 0

   os_zagl_amort()

   nA1 := 0
   nA2 := 0

   DO WHILE !Eof() .AND. ( idrj = cIdRj .OR. Empty( cIdRj ) )
      cIdAm := idam
      nDug2 := nPot21 := nPot22 := 0
      DO WHILE !Eof() .AND. ( idrj = cIdRj .OR. Empty( cIdRj ) ) .AND. idam == cidam
         cIdAmort := idam
         nDug3 := nPot31 := nPot32 := 0
         DO WHILE !Eof() .AND. ( idrj = cIdRj .OR. Empty( cIdRj ) )  .AND. idam == cidamort
            IF PRow() > 60; FF; os_zagl_amort(); ENDIF
            IF !( ( cON == "N" .AND. datotp_prazan() ) .OR. ;
                  ( con == "O" .AND. !datotp_prazan() ) .OR. ;
                  ( con == "B" .AND. Year( datum ) = Year( os_datum_obracuna() ) ) .OR. ;
                  ( con == "G" .AND. Year( datum ) < Year( os_datum_obracuna() ) ) .OR. ;
                  Empty( con ) )
               SKIP 1
               LOOP
            ENDIF

            fIma := .T.
            IF cpromj == "3"
               // ako zelim samo promjene vidi ima li za sr.
               // uopste promjena
               _sr_id := field->id
               os_select_promj( _sr_id )
               //HSEEK _sr_id
               fIma := .F.
               DO WHILE !Eof() .AND. field->id == _sr_id .AND. field->datum <= os_datum_obracuna()
                  fIma := .T.
                  SKIP
               ENDDO
               select_o_os_or_sii()
            ENDIF


            // utvrdjivanje da li sredstvo ima sadasnju vrijednost
            // --------------------------------------------------
            lImaSadVr := .F.
            IF cPromj <> "3"
               IF nabvr - otpvr - amp > 0
                  lImaSadVr := .T.
               ENDIF
            ENDIF
            IF cPromj $ "23"
               // prikaz promjena
               _sr_id := field->id
               os_select_promj( _sr_id )
               //HSEEK _sr_id
               DO WHILE !Eof() .AND. field->id == _sr_id .AND. field->datum <= os_datum_obracuna()
                  nA1 := 0
                  nA2 := amp
                  IF nabvr - otpvr - amp > 0
                     lImaSadVr := .T.
                  ENDIF
                  SKIP
               ENDDO
               select_o_os_or_sii()
            ENDIF

            // ispis stavki
            // ------------
            IF cFiltSadVr == "1" .AND. !( lImaSadVr ) .OR. ;
                  cFiltSadVr == "2" .AND. lImaSadVr
               SKIP
               LOOP
            ELSE
               IF fIma
                  ? Str( ++nrbr, 4 ) + ".", id, idrj, datum, naz, jmj, Str( kolicina, 6, 1 )
                  nCol1 := PCol() + 1
               ENDIF
               IF cPromj <> "3"
                  @ PRow(), ncol1    SAY nabvr * nBBK PICT gpici
                  @ PRow(), PCol() + 1 SAY otpvr * nBBK PICT gpici
                  @ PRow(), PCol() + 1 SAY amp * nBBK PICT gpici
                  @ PRow(), PCol() + 1 SAY otpvr * nBBK + amp * nBBK PICT gpici
                  @ PRow(), PCol() + 1 SAY nabvr * nBBK - otpvr * nBBK - amp * nBBK PICT gpici
                  nDug3 += nabvr; nPot31 += otpvr
                  nPot32 += amp

                  _sr_id_am := field->idam
                  nArr := Select()

                  select_o_amort( _sr_id_am )
                  nAmIznos := amort->iznos

                  SELECT ( nArr )

               ENDIF

               IF cPromj $ "23"

                  // prikaz promjena
                  _sr_id := field->id
                  _sr_id_rj := field->idrj

                  os_select_promj( _sr_id )
                  //HSEEK _sr_id

                  DO WHILE !Eof() .AND. field->id == _sr_id .AND. field->datum <= os_datum_obracuna()
                     ? Space( 5 ), Space( Len( id ) ), Space( Len( _sr_id_rj ) ), datum, opis
                     nA1 := 0; nA2 := amp
                     @ PRow(), ncol1    SAY nabvr * nBBK PICT gpici
                     @ PRow(), PCol() + 1 SAY otpvr * nBBK PICT gpici
                     @ PRow(), PCol() + 1 SAY amp * nBBK PICT gpici
                     @ PRow(), PCol() + 1 SAY otpvr * nBBK + amp * nBBK PICT gpici
                     @ PRow(), PCol() + 1 SAY nabvr * nBBK - amp * nBBK - otpvr * nBBK PICT gpici
                     nDug3 += nabvr; nPot31 += otpvr
                     nPot32 += amp
                     SKIP
                  ENDDO
                  select_o_os_or_sii()
               ENDIF

               IF lExpRpt
                  fill_rpt_exp( id, naz, datum, datotp, ;
                     idkonto, kolicina, jmj, nAmIznos, nabvr, otpvr, amp )
               ENDIF

            ENDIF

            SKIP

         ENDDO

         IF PRow() > 60
            FF
            os_zagl_amort()
         ENDIF

         ? m
         ? " ukupno ", cidamort
         @ PRow(), ncol1    SAY ndug3 * nBBK PICT gpici
         @ PRow(), PCol() + 1 SAY npot31 * nBBK PICT gpici
         @ PRow(), PCol() + 1 SAY npot32 * nBBK PICT gpici
         @ PRow(), PCol() + 1 SAY npot31 * nBBK + npot32 * nBBK PICT gpici
         @ PRow(), PCol() + 1 SAY ndug3 * nBBK - npot31 * nBBK - npot32 * nBBK PICT gpici
         ? m
         nDug2 += nDug3; nPot21 += nPot31; nPot22 += nPot32
         IF !Empty( qidAm )
            EXIT
         ENDIF

      ENDDO

      IF !Empty( qidAm )
         EXIT
      ENDIF

      nDug += nDug2; nPot1 += nPot21; nPot2 += nPot22

   ENDDO

   IF Empty( qidAm )
      IF PRow() > 60
         FF
         os_zagl_amort()
      ENDIF
      ?
      ? m
      ? " U K U P N O :"
      @ PRow(), ncol1    SAY ndug * nBBK PICT gpici
      @ PRow(), PCol() + 1 SAY npot1 * nBBK PICT gpici
      @ PRow(), PCol() + 1 SAY npot2 * nBBK PICT gpici
      @ PRow(), PCol() + 1 SAY npot1 * nBBK + npot2 * nBBK PICT gpici
      @ PRow(), PCol() + 1 SAY ndug * nBBK - npot1 * nBBK - npot2 * nBBK PICT gpici
      ? m
   ENDIF

   FF
   ENDPRINT

   IF lExpRpt
      open_exported_xlsx()
   ENDIF

   my_close_all_dbf()

   RETURN


// -------------------------------------------
// vraca definiciju polja tabele exporta
// -------------------------------------------
STATIC FUNCTION get_exp_fields()

   LOCAL aDbf := {}

   AAdd( aDBF, { "ID", "C", 10, 0 } )
   AAdd( aDBF, { "NAZIV", "C", 40, 0 } )
   AAdd( aDBF, { "DATUM", "D", 8, 0 } )
   AAdd( aDBF, { "DATOTP", "D", 8, 0 } )
   AAdd( aDBF, { "IDKONTO", "C", 7, 0 } )
   AAdd( aDBF, { "KOLICINA", "N", 10, 2 } )
   AAdd( aDBF, { "JMJ", "C", 3, 0 } )
   AAdd( aDBF, { "STAM", "N", 12, 5 } )
   AAdd( aDBF, { "NABVR", "N", 12, 5 } )
   AAdd( aDBF, { "OTPVR", "N", 12, 5 } )
   AAdd( aDBF, { "SADVR", "N", 12, 5 } )

   RETURN aDBF



// -------------------------------------------
// filuje tabelu R_EXP
// -------------------------------------------
STATIC FUNCTION fill_rpt_exp( cId, cNaz, dDatum, dDatOtp, cIdKto, nKol, cJmj, nStAm, nNab, nOtp, nAmp )

   LOCAL nArr

   nArr := Select()

   o_r_export_legacy()
   APPEND BLANK
   REPLACE field->id WITH cId
   REPLACE field->naziv WITH cNaz
   REPLACE field->datum WITH dDatum
   REPLACE field->datotp WITH fix_dat_var( dDatOtp )
   REPLACE field->idkonto WITH cIdKto
   REPLACE field->kolicina WITH nKol
   REPLACE field->jmj WITH cJmj
   REPLACE field->stam WITH nStAm
   REPLACE field->nabvr WITH nNab
   REPLACE field->otpvr WITH nOtp + nAmp
   REPLACE field->sadvr WITH nabvr - otpvr

   SELECT ( nArr )

   RETURN .T.
