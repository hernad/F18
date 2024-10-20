/*
 * This file is part of the bring.out FMK, a free and open source
 * accounting software suite,
 * Copyright (c) 1994-2024 by bring.out d.o.o Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including knowhow ERP specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_knowhow.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */

#include "f18.ch"

/* OiNIsplate
 *     Odobrenje i nalog isplate

FUNCTION OiNIsplate()

   LOCAL nRec := 0
   PRIVATE cBrojOiN := "T"     // T,S,O

   SELECT fin_pripr
   nRec := RecNo()

   IF !VarEdit( { { "Koliko obrazaca stampati? (T-samo tekuci, S-sve, O-od tekuceg do kraja)", "cBrojOiN", "cBrojOiN$'TSO'", "@!", } }, 10, 0, 14, 79, ;
         'STAMPANJE OBRASCA "ODOBRENJE I NALOG ZA ISPLATU"', ;
         "B1" )
      RETURN ( NIL )
   ENDIF
   IF cBrojOiN == "S"; GO TOP; ENDIF
   IF !start_print()
      RETURN .F.
   ENDIF

   DO WHILE !Eof()
      ?
      gpCOND()
      ? Space( gnLMONI )
      gpB_ON(); gp12cpi()
      ?? "ORGAN UPRAVE-SLU" + IF( gKodnaS == "8", "�", "@" ) + "BA"
      gpB_OFF(); gpCOND()
      ?? Space( 50 ) + "Ispla" + IF( gKodnaS == "8", "�", "}" ) + "eno putem"
      gpB_ON()
      ?? " ZPP-BLAGAJNE"
      gpB_OFF()

      ? Space( gnLMONI ) + Space( 77 ) + "sa " + IF( gKodnaS == "8", "�", "`" ) + "iro ra" + IF( gKodnaS == "8", "�", "~" ) + "una"
      // ? SPACE(gnLMONI); gPI_ON()
      // ?? ocitaj_izbaci(F_KONTO,idkonto,"naz")
      // gPI_OFF()
      ?
      // ? SPACE(gnLMONI)+REPL("-",60)
      // ? SPACE(gnLMONI)+SPACE(77); gpI_ON()
      ? Space( gnLMONI ); gPI_ON()
    --  ?? PadC( AllTrim( ocitaj_izbaci( F_KONTO, idkonto, "naz" ) ), 60 ); gPI_OFF()
      ?? Space( 17 ); gpI_ON()
      ?? PadC( AllTrim( idkonto ), 28 ); gPI_OFF()
      ? Space( gnLMONI ) + REPL( "-", 60 ) + Space( 17 ) + REPL( "-", 28 )
      ?
      ? Space( gnLMONI ) + "Broj: "; gPI_ON()
      ?? PadC( AllTrim( idpartner ), 54 ); gPI_OFF()
      ?? Space( 17 ) + "Dana" + Space( 14 ) + "      god."
      ? Space( gnLMONI ) + "      " + REPL( "-", 54 ) + Space( 21 ) + REPL( "-", 14 ) + "   " + "--"
      ? Space( gnLMONI ) + "Zenica, "; gPI_ON()
      ?? PadC( SrediDat( datdok ), 52 ); gPI_OFF()
      ? Space( gnLMONI ) + "        " + REPL( "-", 52 )
      ?; ?; ?; ?; ?
      ? Space( gnLMONI ) + Space( 30 ); gPB_ON(); gP10cpi()
      ?? "ODOBRENJE I NALOG ZA ISPLATU"; gPB_OFF(); gPCOND()
      ?; ?; ?; ?; ?
      ? Space( gnLMONI ) + "Kojim se odre" + IF( gKodnaS == "8", "�", "|" ) + "uje da se izvr" + IF( gKodnaS == "8", "�", "{" ) + "i isplata u korist "; gpI_ON()
  --    ?? PadC( AllTrim( ocitaj_izbaci( F_PARTN, idpartner, "TRIM(naz)+', '+mjesto" ) ), 57 ); gpI_OFF()
      ? Space( gnLMONI ) + "                                                " + REPL( "-", 57 )
      ?
      ? Space( gnLMONI ) + REPL( "-", 105 )
      ? Space( gnLMONI ) + "na ime ra" + IF( gKodnaS == "8", "�", "~" ) + "una broj "; gpI_ON()
      ?? PadC( AllTrim( brdok ), 24 ); gpI_OFF()
      ?? " od "; gPI_ON()
      ?? PadC( DToC( datval ), 23 ); gPI_OFF()
      ?? " za kupljenu robu - izvr" + IF( gKodnaS == "8", "�", "{" ) + "ene usluge"; gPI_ON()
      ? Space( gnLMONI ) + "                   " + REPL( "-", 24 ) + "    " + REPL( "-", 23 )
      ?
      ? Space( gnLMONI ) + REPL( "-", 105 )
      ? Space( gnLMONI ) + PadC( AllTrim( opis ), 105 ); gPI_OFF()
      ? Space( gnLMONI ) + REPL( "-", 105 )
      ?
      ? Space( gnLMONI ) + REPL( "-", 105 )
      ? Space( gnLMONI ) + "na teret ovog organa - slu" + IF( gKodnaS == "8", "�", "`" ) + "be i to:        " + valuta_domaca_skraceni_naziv() + " "; gPI_ON()
      ?? Transform( iznosbhd, gPicBHD ); gPI_OFF()
      ? Space( gnLMONI ) + Space( 43 ) + "     " + REPL( "-", 17 )
      ? Space( gnLMONI ) + Space( 43 ) + valuta_domaca_skraceni_naziv()
      ? Space( gnLMONI ) + Space( 43 ) + "     " + REPL( "-", 17 )
      ? Space( gnLMONI ) + Space( 43 ) + valuta_domaca_skraceni_naziv()
      ? Space( gnLMONI ) + Space( 43 ) + "     " + REPL( "-", 17 )
      ? Space( gnLMONI ) + Space( 43 ) + valuta_domaca_skraceni_naziv()
      ? Space( gnLMONI ) + Space( 43 ) + "     " + REPL( "-", 17 )
      ? Space( gnLMONI ) + Space( 43 ) + valuta_domaca_skraceni_naziv()
      ? Space( gnLMONI ) + Space( 43 ) + "     " + REPL( "-", 17 )
      ? Space( gnLMONI ) + Space( 32 ) + "UKUPNO     " + valuta_domaca_skraceni_naziv() + " "; gPI_ON()
      ?? Transform( iznosbhd, gPicBHD ); gPI_OFF()
      ? Space( gnLMONI ) + Space( 43 ) + "     " + REPL( "-", 17 )
      ? Space( gnLMONI ) + Space( 32 ) + REPL( "-", 33 )
      ? Space( gnLMONI ) + Space( 32 ) + "ZA ISPLATU " + valuta_domaca_skraceni_naziv() + " "; gPI_ON()
      ?? Transform( iznosbhd, gPicBHD ); gPI_OFF()
      ? Space( gnLMONI ) + Space( 43 ) + "     " + REPL( "-", 17 )
      ? Space( gnLMONI ) + Space( 32 ) + REPL( "-", 33 )
      ?; ?; ?; ?
      ? Space( gnLMONI ) + Space( 15 ) + "Ra" + IF( gKodnaS == "8", "�", "~" ) + "unopolaga" + IF( gKodnaS == "8", "�", "~" ) + Space( 50 ) + "Naredbodavac"
      ?; ?
      ? Space( gnLMONI ) + REPL( "-", 43 ) + Space( 20 ) + REPL( "-", 42 )
      ?
      FF
      IF cBrojOiN == "T"
         EXIT
      ELSE
         SKIP 1
      ENDIF
   ENDDO
   end_print()
   GO ( nRec )

   RETURN ( NIL )

*/


FUNCTION sredi_rbr_fin_nalog( lSilent )

   LOCAL nArr
   LOCAL nTREC
   LOCAL i
   LOCAL _rec

   IF ( lSilent == nil )
      lSilent := .F.
   ENDIF

   IF !lSilent
      IF Pitanje(, "Srediti redne brojeve?", "D" ) == "N"
         RETURN .F.
      ENDIF
   ENDIF

   nArr := Select()
   nRec := RecNo()

   SELECT fin_pripr
   SET ORDER TO TAG "0"
   GO TOP

   i := 1

   Box(, 1, 50 )

   DO WHILE !Eof()
      SKIP 1
      nTREC := RecNo()
      SKIP -1

      _rec := dbf_get_rec()

      _rec[ "rbr" ] := i
      dbf_update_rec( _rec )

      @ box_x_koord() + 1, box_y_koord() + 2 SAY "redni broj: " + STR( field->rbr, 5)

      ++ i

      GO ( nTREC )

   ENDDO

   SET ORDER TO TAG "1"

   BoxC()

   GO TOP

   SELECT ( nArr )
   GO nRec

   RETURN .T.



/* ChkKtoMark(cIdKonto)
 *     provjeri da li postoji marker na kontu
 *     Uslov za ovu opciju: SIFK podesenje: ID=KONTO, OZNAKA=MARK, TIP=C, DUZ=1
 *   param: cIdKonto - id konto
 
FUNCTION ChkKtoMark( cIdKonto )

   bRet := .T.
   cMark := IzSifKKonto( "MARK", cIdKonto, NIL )
   DO CASE
      // ne postoji definicija...
   CASE cMark == nil
      bRet := .T.
      // postoji marker
   CASE cMark == "*"
      bRet := .T.
      // ne postoji marker
   CASE cMark == " "
      bRet := .F.
   ENDCASE

   RETURN bRet
*/