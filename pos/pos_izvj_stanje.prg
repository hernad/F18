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

FUNCTION pos_stanje_artikala()

   LOCAL nStanje
   LOCAL nSign := 1
   LOCAL cSt
   LOCAL nVrijednost
   LOCAL nCijena := 0
   LOCAL cIdRoba
   LOCAL nRobaNazivSirina := 29
   LOCAL cLijevaMargina := ""
   LOCAL xPrintOpt, bZagl

   PRIVATE cIdPos
   PRIVATE dDatum
   PRIVATE cRoba := Space( 60 )
   PRIVATE cNule := "N"

   dDatum := danasnji_datum()
   cIdPos := gIdPos

   aNiz := {}
   AAdd ( aNiz, { "Prodajno mjesto (prazno-svi)", "cIdPos", "cIdpos='X'.or.empty(cIdPos).or. p_pos_kase(@cIdPos)", "@!", } )
   AAdd ( aNiz, { "Artikli  (prazno-svi)", "cRoba",, "@!S30", } )
   AAdd ( aNiz, { "Izvještaj se pravi za datum", "dDatum",,, } )
   AAdd ( aNiz, { "Štampati artikle sa stanjem 0", "cNule", "cNule$'DN'", "@!", } )
   DO WHILE .T.
      IF !VarEdit( aNiz, 10, 5, 21, 74, 'USLOVI ZA IZVJESTAJ "STANJE ODJELJENJA"', "B1" )
         CLOSERET
      ENDIF
      cFilterRoba := Parsiraj( cRoba, "IdRoba", "C" )
      IF cFilterRoba <> NIL
         EXIT
      ELSE
         Msg( "Kriterij za artikal nije korektno postavljen!" )
      ENDIF
   ENDDO

   seek_pos_pos_2()
   IF !( cFilterRoba == ".t." )
      SET FILTER TO &cFilterRoba
   ENDIF
   GO TOP

   EOF CRET

   xIdOdj := "??"
   nRbr := 0

   s_oPDF := PDFClass():New()
   xPrintOpt := hb_Hash()
   xPrintOpt[ "tip" ] := "PDF"
   xPrintOpt[ "layout" ] := "landscape"
   xPrintOpt[ "opdf" ] := s_oPDF
   xPrintOpt[ "font_size" ] := 8
   IF f18_start_print( NIL, xPrintOpt,  "POS REALIZACIJA PO ARTIKLIMA NA DAN: " + DToC( Date() ) ) == "X"
      RETURN .F.
   ENDIF

   bZagl := {|| pos_stanje_artikala_zagl( cIdPos, cLijevaMargina, nRobaNazivSirina ) }

   Eval(bZagl)

   nStanje := 0
   nVrijednost := 0

   DO WHILE !Eof()

      nStanje := 0
      nVrijednost := 0
      nPstanje := 0
      nUlaz := nIzlaz := 0
      cIdRoba := pos->idroba

      // 1) promet prije zadanog datuma
      DO WHILE !Eof() .AND. pos->idRoba == cIdRoba .AND. pos->datum < dDatum

         IF !Empty( cIdPos ) .AND. POS->idpos != cIdPos
            SKIP
            LOOP
         ENDIF
         IF POS->idvd $ "16#00"
            nPstanje += POS->Kolicina
            nVrijednost += POS->Kolicina * POS->Cijena
         ELSEIF POS->idvd $ "IN#NI#" + "42#01"
            DO CASE
            CASE POS->IdVd == "IN"
               nPstanje -= ( POS->Kolicina - POS->Kol2 )
               nVrijednost += ( POS->Kol2 - POS->Kolicina ) * POS->Cijena
            CASE POS->IdVd == "NI" // nivelacijom se ne mijenja kolicina
               nVrijednost := POS->Kolicina * POS->Cijena
            OTHERWISE
               nPstanje -= POS->Kolicina
               nVrijednost -= POS->Kolicina * POS->Cijena
            ENDCASE
         ENDIF
         SKIP
      ENDDO

      // 2) stanje na tekuci dan
      DO WHILE !Eof() .AND. pos->idroba == cIdRoba .AND. pos->datum == dDatum

         IF !Empty( cIdPos ) .AND. POS->idpos != cIdPos
            SKIP
            LOOP
         ENDIF

         IF POS->idvd $ "16#00"
            nUlaz += pos->Kolicina
            nVrijednost += POS->Kolicina * POS->Cijena
         ELSEIF pos->idvd $  "IN#NI#" + "42#01"
            DO CASE
            CASE POS->IdVd == "IN"
               nIzlaz += ( pos->kolicina - pos->kol2 )
               nVrijednost += ( pos->kol2 - pos->kolicina ) * POS->Cijena
            CASE POS->IdVd == "NI" // ne mijenja kolicinu, samo vrijednost
               nVrijednost := POS->Kolicina * POS->Cijena
            OTHERWISE
               nIzlaz += POS->Kolicina
               nVrijednost -= POS->Kolicina * POS->Cijena
            ENDCASE
         ENDIF
         SKIP
      ENDDO

      nStanje := nPstanje + nUlaz - nIzlaz

      check_nova_strana( bZagl, s_oPDF )
      IF Round( nStanje, 4 ) <> 0 .OR. cNule == "D"

         select_o_roba( cIdRoba )
         ? cLijevaMargina + PadL( AllTrim( Str( ++nRbr, FIELD_LEN_POS_RBR ) ), FIELD_LEN_POS_RBR ) + ")"
         ?? cIdRoba, PadR( roba->naz, nRobaNazivSirina ) + " "

         SELECT POS
         ?? Str ( nPstanje, 10, 2 ) + " "
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
         ?? Str ( nStanje, 10, 2 )
         ?? " "
         ?? Str( roba->mpc, 10, 2 )
         ?? " "
         ?? Str( nStanje * roba->mpc, 10, 2 )
      ENDIF

   ENDDO
   podvuci(cLijevaMargina, nRobaNazivSirina)

   f18_end_print( NIL, xPrintOpt )
   my_close_all_dbf()

   RETURN .T.


STATIC FUNCTION pos_stanje_artikala_zagl( cIdPos, cLijevaMargina, nRobaNazivSirina )

   ? cLijevaMargina + "Prodajno mjesto: " + iif ( Empty( cIdPos ), "SVE", cIdPos + " - " + find_pos_kasa_naz( cIdPos ) )
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
