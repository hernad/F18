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

STATIC s_oPDF

MEMVAR cRobaUslov, dDatum, cNule

FUNCTION pos_stanje_artikala()

   LOCAL nStanjeKolicina
   LOCAL nVrijednost
   LOCAL cIdRoba
   LOCAL nRobaNazivSirina := 29
   LOCAL cLijevaMargina := ""
   LOCAL xPrintOpt, bZagl
   LOCAL nRbr
   LOCAL aNiz
   LOCAL cFilterRoba, cQuery
   LOCAL cIdPos
   LOCAL nUlaz, nIzlaz
   LOCAL nUkVrijednost

   // LOCAL lInicijalizacija
   LOCAL nKalo
   LOCAL nPopust
   LOCAL nPredhodnoStanjeKalo
   LOCAL nPredhodnaVrijednost
   LOCAL nPredhodniPopust
   LOCAL nPredhodnoStanjeUlaz, nPredhodnoStanjeIzlaz
   LOCAL nPredhodnaRealizacija, nRealizacija

   // PRIVATE cIdPos
   PRIVATE dDatum
   PRIVATE cRobaUslov := Space( 60 )
   PRIVATE cNule := "N"

   dDatum := danasnji_datum()
   cIdPos := pos_pm()

   aNiz := {}
   AAdd ( aNiz, { "Artikli  (prazno-svi)", "cRobaUslov",, "@!S30", } )
   AAdd ( aNiz, { "Izvještaj se pravi za datum", "dDatum",,, } )
   AAdd ( aNiz, { "Štampati artikle sa stanjem 0", "cNule", "cNule$'DN'", "@!", } )
   DO WHILE .T.
      IF !VarEdit( aNiz, 10, 5, 21, 74, 'USLOVI ZA IZVJESTAJ STANJE ARTIKALA', "B1" )
         CLOSERET
      ENDIF
      cFilterRoba := Parsiraj( cRobaUslov, "IdRoba", "C" )
      IF cFilterRoba <> NIL
         EXIT
      ELSE
         Msg( "Kriterij za artikal nije korektno postavljen!" )
      ENDIF
   ENDDO

   // 21-ce ne gledati
   cQuery := "select *,date(pos.obradjeno) as datum_obrade, to_char(pos.obradjeno, 'HH24:MI') as vrij_obrade FROM "  + f18_sql_schema( "pos_items" ) + ;
      " left join " + f18_sql_schema( "pos" ) + " on pos_items.idpos=pos.idpos and pos_items.idvd=pos.idvd and pos_items.brdok=pos.brdok and pos_items.datum=pos.datum" + ;
      " WHERE pos.idvd <> '21' AND pos.datum<=" + sql_quote( dDatum ) + ;
      " ORDER BY idroba, pos.datum, pos.obradjeno, pos.idvd, pos.brdok"

   MsgO("Preuzimanje podataka sa servera za datum " + DToC(dDatum) + " ...")
   SELECT F_POS
   USE
   dbUseArea_run_query( cQuery, F_POS, "POS" )
   MsgC()


   // seek_pos_pos_2()
   IF !( cFilterRoba == ".t." )
      SET FILTER TO &cFilterRoba
   ENDIF
   GO TOP

   EOF CRET

   nRbr := 0

   s_oPDF := PDFClass():New()
   xPrintOpt := hb_Hash()
   xPrintOpt[ "tip" ] := "PDF"
   xPrintOpt[ "layout" ] := "landscape"
   xPrintOpt[ "opdf" ] := s_oPDF
   xPrintOpt[ "font_size" ] := 10
   IF f18_start_print( NIL, xPrintOpt,  "POS STANJE [" +  pos_prodavnica_str() + "/" + AllTrim( cIdPos ) + "] NA DAN: " + DToC( dDatum ) ) == "X"
      RETURN .F.
   ENDIF

   bZagl := {|| pos_stanje_artikala_zagl( cIdPos, cLijevaMargina, nRobaNazivSirina ) }

   Eval( bZagl )

   nUkVrijednost := 0
   DO WHILE !Eof()

      cIdRoba := pos->idroba
      nVrijednost := 0
      nPredhodnoStanjeUlaz := 0
      nPredhodnoStanjeIzlaz := 0
      nUlaz := 0
      nIzlaz := 0
      nKalo := 0
      nPopust := 0
      nStanjeKolicina := 0
      nPredhodnoStanjeKalo := 0
      nPredhodnaVrijednost := 0
      nPredhodniPopust := 0
      nPredhodnaRealizacija := 0

      // lInicijalizacija := .F.

      // 1) promet prije zadanog datuma
      DO WHILE !Eof() .AND. pos->idRoba == cIdRoba .AND. pos->datum < dDatum
         pos_stanje_proracun_kartica( @nPredhodnoStanjeUlaz, @nPredhodnoStanjeIzlaz, @nPredhodnoStanjeKalo, @nStanjeKolicina, @nPredhodnaRealizacija, @nPredhodnaVrijednost, @nPredhodniPopust, .F. )
         SELECT POS
         SKIP
      ENDDO

      // nUlaz := nPredhodnoStanjeUlaz
      // nIzlaz := nPredhodnoStanjeIzlaz
      nKalo := nPredhodnoStanjeKalo
      nVrijednost := nPredhodnaVrijednost
      nRealizacija := nPredhodnaRealizacija
      nPopust := nPredhodniPopust

      // 2) stanje na tekuci dan
      DO WHILE !Eof() .AND. pos->idroba == cIdRoba .AND. pos->datum == dDatum
         // pos_stanje_proracun( @nUlaz, @nIzlaz, @nVrijednost, @lInicijalizacija )
         pos_stanje_proracun_kartica( @nUlaz, @nIzlaz, @nKalo, @nStanjeKolicina, @nVrijednost, @nRealizacija, @nPopust, .F. )

         SELECT POS
         SKIP
      ENDDO

      // IF lInicijalizacija // u tekucem danu bila inicijalizacija, predhodni promet se ne gleda
      // nPUlaz := 0
      // nPIzlaz := 0
      // ENDIF

      // nStanjeKolicina := ( nPUlaz - nPIzlaz ) + nUlaz - nIzlaz

      check_nova_strana( bZagl, s_oPDF )
      IF Round( nStanjeKolicina, 4 ) <> 0 .OR. Round( nVrijednost, 4 ) <> 0  .OR. cNule == "D"

         select_o_roba( cIdRoba )
         ? Str( ++nRbr, 4 ) + " "
         ?? cIdRoba, PadR( roba->naz, nRobaNazivSirina ) + " "

         SELECT POS
         ?? Str ( nPredhodnoStanjeUlaz - nPredhodnoStanjeIzlaz, 10, 3 ) + " "
         IF Round ( nUlaz, 4 ) <> 0
            ?? Str( nUlaz, 10, 3 )
         ELSE
            ?? Space ( 10 )
         ENDIF
         ?? " "
         IF Round ( nIzlaz, 4 ) <> 0
            ?? Str( nIzlaz, 10, 3 )
         ELSE
            ?? Space ( 10 )
         ENDIF
         ?? " "
         ?? Str ( nStanjeKolicina, 10, 3 )

         ?? " "
         IF nStanjeKolicina <> 0
            // cijena
            ?? Str( nVrijednost / nStanjeKolicina, 10, 3 )
         ELSE
            Space( 10 )
         ENDIF

         ?? " "
         ?? Str( nVrijednost, 10, 2 )

         ?? " "
         ?? Str( nKalo, 10, 3 )

         ?? " "
         ?? Str( nStanjeKolicina - nKalo, 10, 3 )
      ENDIF
      nUkVrijednost += nVrijednost


   ENDDO
   podvuci( cLijevaMargina, nRobaNazivSirina )
   ? Space( 55 ), "Ukupno vrijednost:", Str( nUkVrijednost, 12, 2 )
   podvuci( cLijevaMargina, nRobaNazivSirina )

   f18_end_print( NIL, xPrintOpt )

   SELECT POS
   USE
   my_close_all_dbf()

   RETURN .T.




STATIC FUNCTION pos_stanje_artikala_zagl( cIdPos, cLijevaMargina, nRobaNazivSirina )

   ? cLijevaMargina + "Prodajno mjesto: " + cIdPos
   podvuci( cLijevaMargina, nRobaNazivSirina )
   ?U cLijevaMargina + "R.br)", PadR ( "Šifra", 10 ), " ", PadR ( "Naziv artikla", nRobaNazivSirina ) + " "
   ??U "Poč.stanje ", PadC ( "Ulaz", 10 ), PadC ( "Izlaz", 10 ), PadC ( "Stanje", 10 ), PadC( "Cijena", 10 ), PadC( "Vrijednost", 10 ), PadC ( "Kalo", 10 ), PadC ( "Kol.za Prod", 10 )
   podvuci( cLijevaMargina, nRobaNazivSirina )

   RETURN .T.

STATIC FUNCTION podvuci( cLijevaMargina, nRobaNazivSirina )

   LOCAL nI

   ? cLijevaMargina  + REPL( "-", 5 ), REPL ( "-", 10 ), REPL ( "-", nRobaNazivSirina )
   FOR nI := 1 TO 8
      ?? " " + REPL ( "-", 10 )
   NEXT

   RETURN .T.
