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
   LOCAL nPUlaz, nPIzlaz
   LOCAL cIdPos
   LOCAL nUlaz, nIzlaz
   LOCAL nUkVrijednost
   LOCAL lInicijalizacija

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
   cQuery := "select * from "  + f18_sql_schema( "pos_items" ) + ;
      " left join " + f18_sql_schema( "pos" ) + " on pos_items.idpos=pos.idpos and pos_items.idvd=pos.idvd and pos_items.brdok=pos.brdok and pos_items.datum=pos.datum" + ;
      " WHERE pos.idvd <> '21' AND pos.datum<=" + sql_quote( dDatum ) + ;
      " order by idroba, pos.datum, pos.obradjeno  "

   SELECT F_POS
   USE
   dbUseArea_run_query( cQuery, F_POS, "POS" )

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
   IF f18_start_print( NIL, xPrintOpt,  "POS STANJE [" +  pos_prodavnica_str() + "/" + AllTrim(cIdPos) + "] NA DAN: " + DToC( Date() ) ) == "X"
      RETURN .F.
   ENDIF

   bZagl := {|| pos_stanje_artikala_zagl( cIdPos, cLijevaMargina, nRobaNazivSirina ) }

   Eval( bZagl )

   nUkVrijednost := 0
   DO WHILE !Eof()

      cIdRoba := pos->idroba
      nVrijednost := 0
      nPUlaz := 0
      nPIzlaz := 0
      nUlaz := 0
      nIzlaz := 0

      lInicijalizacija := .F.

      // 1) promet prije zadanog datuma
      DO WHILE !Eof() .AND. pos->idRoba == cIdRoba .AND. pos->datum < dDatum
         pos_stanje_proracun( @nPUlaz, @nPizlaz, @nVrijednost )
         SELECT POS
         SKIP
      ENDDO

      // 2) stanje na tekuci dan
      DO WHILE !Eof() .AND. pos->idroba == cIdRoba .AND. pos->datum == dDatum
         pos_stanje_proracun( @nUlaz, @nIzlaz, @nVrijednost, @lInicijalizacija )
         SELECT POS
         SKIP
      ENDDO

      IF lInicijalizacija // u tekucem danu bila inicijalizacija, predhodni promet se ne gleda
         nPUlaz := 0
         nPIzlaz := 0
      ENDIF

      nStanjeKolicina := ( nPUlaz - nPIzlaz ) + nUlaz - nIzlaz

      check_nova_strana( bZagl, s_oPDF )
      IF Round( nStanjeKolicina, 4 ) <> 0 .OR. Round( nVrijednost, 4 ) <> 0  .OR. cNule == "D"

         select_o_roba( cIdRoba )
         ? Str( ++nRbr, 4 ) + " "
         ?? cIdRoba, PadR( roba->naz, nRobaNazivSirina ) + " "

         SELECT POS
         ?? Str ( nPUlaz - nPIzlaz, 10, 2 ) + " "
         IF Round ( nUlaz, 4 ) <> 0
            ?? Str( nUlaz, 10, 2 )
         ELSE
            ?? Space ( 10 )
         ENDIF
         ?? " "
         IF Round ( nIzlaz, 4 ) <> 0
            ?? Str( nIzlaz, 10, 2 )
         ELSE
            ?? Space ( 10 )
         ENDIF
         ?? " "
         ?? Str ( nStanjeKolicina, 10, 2 )
         ?? " "
         IF nStanjeKolicina <> 0
            ?? Str( nVrijednost / nStanjeKolicina, 10, 2 )
         ELSE
            Space( 10 )
         ENDIF
         ?? " "
         ?? Str( nVrijednost, 10, 2 )

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


STATIC FUNCTION pos_stanje_proracun( nUlaz, nIzlaz, nVrijednost, lInicijalizacija )

   IF pos->idvd == POS_IDVD_POCETNO_STANJE_PRODAVNICA
      nUlaz := POS->Kolicina
      nVrijednost := POS->Kolicina * POS->Cijena
      nIzlaz := 0
      lInicijalizacija := .T.

   ELSEIF POS->idvd $ POS_IDVD_ULAZI
      nUlaz += POS->Kolicina
      nVrijednost += POS->Kolicina * POS->Cijena

   ELSEIF POS->IdVd $ POS_IDVD_NIVELACIJE
      nVrijednost += POS->Kolicina * ( POS->Cijena - POS->Cijena )

   ELSEIF POS->IdVd == POS_IDVD_RACUN
      nIzlaz += POS->Kolicina
      nVrijednost -= POS->Kolicina * POS->Cijena

   ENDIF

   RETURN .T.


STATIC FUNCTION pos_stanje_artikala_zagl( cIdPos, cLijevaMargina, nRobaNazivSirina )

   ? cLijevaMargina + "Prodajno mjesto: " + cIdPos
   podvuci( cLijevaMargina, nRobaNazivSirina )
   ?U cLijevaMargina + "R.br)", PadR ( "Šifra", 10 ), " ", PadR ( "Naziv artikla", nRobaNazivSirina ) + " "
   ??U "Poč.stanje ", PadC ( "Ulaz", 10 ), PadC ( "Izlaz", 10 ), PadC ( "Stanje", 10 ), PadC( "Cijena", 10 ), PadC( "Ukupno", 10 )
   podvuci( cLijevaMargina, nRobaNazivSirina )

   RETURN .T.

STATIC FUNCTION podvuci( cLijevaMargina, nRobaNazivSirina )

   LOCAL nI

   ? cLijevaMargina  + REPL( "-", 5 ), REPL ( "-", 10 ), REPL ( "-", nRobaNazivSirina )
   FOR nI := 1 TO 6
      ?? " " + REPL ( "-", 10 )
   NEXT

   RETURN .T.
