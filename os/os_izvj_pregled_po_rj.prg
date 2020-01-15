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


FUNCTION os_pregled_po_rj()

   LOCAL lPartner
   LOCAL _export_dn := "N"
   LOCAL _po_amort := "N"
   LOCAL _export := .F.
   LOCAL _start_cmd

   o_rj()
   o_os_sii()

   cIdRj := Space( Len( field->idrj ) )

   lPartner := os_fld_partn_exist()

   cON := "N"
   cKolP := "N"
   cPocinju := "N"

   cBrojSobe := Space( 6 )
   lBrojSobe := .F.
   cFiltK1 := Space( 40 )
   cFiltDob := Space( 40 )
   cOpis := "N"

   Box(, 12, 77 )
   DO WHILE .T.
      @ box_x_koord() + 1, box_y_koord() + 2 SAY "Radna jedinica:" GET cIdRj VALID {|| P_RJ( @cIdRj ), if ( !Empty( cIdRj ), cIdRj := PadR( cIdRj, 4 ), .T. ), .T. }
      @ box_x_koord() + 1, Col() + 2 SAY "sve koje pocinju " GET cPocinju VALID cPocinju $ "DN" PICT "@!"
      @ box_x_koord() + 2, box_y_koord() + 2 SAY "Prikaz svih neotpisanih (N) / otpisanih(O) /"
      @ box_x_koord() + 3, box_y_koord() + 2 SAY "samo novonabavljenih (B)    / iz proteklih godina (G)"   GET cON PICT "@!" VALID con $ "ONBG"
      @ box_x_koord() + 4, box_y_koord() + 2 SAY "Prikazati kolicine na popisnoj listi D/N" GET cKolP VALID cKolP $ "DN" PICT "@!"
      @ box_x_koord() + 5, box_y_koord() + 2 SAY "Prikazati kolonu 'opis' ? (D/N)" GET cOpis VALID cOpis $ "DN" PICT "@!"

      IF os_sii_da_li_postoji_polje( "brsoba" )
         lBrojSobe := .T.
         @ box_x_koord() + 6, box_y_koord() + 2 SAY "Broj sobe (prazno sve) " GET cBrojSobe  PICT "@!"
      ENDIF

      @ box_x_koord() + 7, box_y_koord() + 2 SAY "Filter po grupaciji K1:" GET cFiltK1 PICT "@!S20"
      @ box_x_koord() + 8, box_y_koord() + 2 SAY "Filter po dobavljacima:" GET cFiltDob PICT "@!S20"

      @ box_x_koord() + 10, box_y_koord() + 2 SAY "Pregled po amortizacionim stopama (D/N) ?" GET _po_amort PICT "@!" VALID _po_amort $ "DN"

      @ box_x_koord() + 12, box_y_koord() + 2 SAY8 "Export izvještaja (D/N) ?" GET _export_dn PICT "@!" VALID _export_dn $ "DN"

      READ
      ESC_BCR

      aUsl1 := Parsiraj( cFiltK1, "K1" )
      aUsl2 := Parsiraj( cFiltDob, "idPartner" )

      IF aUsl1 <> NIL .AND. aUsl2 <> nil
         EXIT
      ENDIF

   ENDDO
   BoxC()

   cIdRj := PadR( cIdRj, 4 )

   IF _export_dn == "D"

      _export := .T.
      xlsx_export_init( _g_exp_flds() )

      // otvori ponovo tabele...
      o_rj()
      o_os_sii()

   ENDIF

   IF lBrojSobe .AND. Empty( cBrojSobe )
      lBrojSobe := ( Pitanje(, "Zelite li da bude prikazan broj sobe? (D/N)", "N" ) == "D" )
   ENDIF

   lPoKontima := .F.
   lPoAmortStopama := .F.
   IF _po_amort == "D"
      lPoAmortStopama := .T.
   ENDIF

   IF cPocinju == "D"
      cIdRj := Trim( cIdRj )
   ENDIF

   START PRINT CRET

   m := "----- ---------- ----------------------------" + IIF( cOpis == "D", " " + REPL( "-", Len( field->opis ) ), "" ) + "  ---- ------- -------------"

   IF lPoAmortStopama

      select_o_os_or_sii()

      IF cIdRj == ""
         SET ORDER TO TAG "5"
         // idam+idrj+id
      ELSE
         INDEX ON idrj + idam + id TO "TMPOS"
      ENDIF

   ELSEIF lBrojSobe .AND. Empty( cBrojSobe )

      m := "----- ------ ---------- ----------------------------" + IF( cOpis == "D", " " + REPL( "-", Len( field->opis ) ), "" ) + "  ---- ------- -------------"

      select_o_os_or_sii()
      SET ORDER TO TAG "2"
      // idrj+id+dtos(datum)
      INDEX ON idrj + brsoba + id + DToS( datum ) TO "TMPOS"

   ELSEIF lPoKontima

      select_o_os_or_sii()
      INDEX ON idkonto + id TO "TMPOS"

   ELSEIF cIdRj == ""

      select_o_os_or_sii()
      SET ORDER TO TAG "1"
      // id+idam+dtos(datum)

   ELSE

      select_o_os_or_sii()
      SET ORDER TO TAG "2"
      // idrj+id+dtos(datum)

   ENDIF

   IF !Empty( cFiltK1 ) .OR. !Empty( cFiltDob )
      cFilter := aUsl1 + ".and." + aUsl2
      select_o_os_or_sii()
      SET FILTER to &cFilter
   ENDIF

   GO TOP
   cIdRj := PadR( cIdRj, Len( field->idrj ) )

   ZglPrj()

   IF !lPoKontima
      SEEK cIdRj
   ENDIF

   PRIVATE nRbr := 0
   cLastKonto := ""

   DO WHILE !Eof() .AND. ( field->idrj = cIdRj .OR. lPoKontima )

      IF lPoKontima .AND. !( field->idrj = cIdRj )
         SKIP
         LOOP
      ENDIF

      IF ( cON = "B" .AND. Year( os_datum_obracuna() ) <> Year( field->datum ) )
         // nije novonabavljeno
         SKIP
         LOOP
         // prikazi samo novonabavlj.
      ENDIF

      IF ( cON = "G" .AND. Year( os_datum_obracuna() ) = Year( field->datum ) )
         // iz protekle godine
         SKIP
         LOOP
         // prikazi samo novonabavlj.
      ENDIF

      IF ( !datotp_prazan() .AND. Year( datotp ) <= Year( os_datum_obracuna() ) ) .AND. cON $ "NB"
         // otpisano sredstvo , a zelim prikaz neotpisanih
         SKIP
         LOOP
      ENDIF

      IF ( datotp_prazan() .AND. Year( datotp ) < Year( os_datum_obracuna() ) ) .AND. cON == "O"
         // neotpisano, a zelim prikaz otpisanih
         SKIP
         LOOP
      ENDIF

      IF !Empty( cBrojsobe )
         IF cbrojsobe <> field->brsoba
            SKIP
            LOOP
         ENDIF
      ENDIF

      IF lPoKontima .AND. ( nRbr = 0 .OR. cLastKonto <> idkonto )

         // prvo sredstvo,
         // ispisi zaglavlje

         IF nrbr > 0
            ? m
            ?
         ENDIF

         IF PRow() > RPT_PAGE_LEN
            FF
            ZglPrj()
         ENDIF

         ?
         ? "KONTO:", idkonto
         ? REPL( "-", 14 )
         nRbr := 0

      ENDIF

      IF PRow() > RPT_PAGE_LEN
         FF
         ZglPrj()
      ENDIF

      IF lBrojSobe .AND. Empty( cBrojSobe )
         ? Str( ++nRbr, 4 ) + ".", field->brsoba, field->id, field->naz
      ELSE
         ? Str( ++nRbr, 4 ) + ".", field->id, field->naz
      ENDIF

      IF cOpis == "D"
         ?? "", field->opis
      ENDIF

      ?? "", field->jmj

      IF cKolP == "D"
         @  PRow(), PCol() + 1 SAY field->kolicina PICT "9999.99"
      ELSE
         @  PRow(), PCol() + 1 SAY Space( 7 )
      ENDIF

      cLastKonto := field->idkonto

      @ PRow(), PCol() + 1 SAY " ____________"

      IF _export
         _a_to_exp( AllTrim( Str( nRbr, 4 ) ), field->id, field->naz, field->jmj, field->kolicina, field->datum )
      ENDIF

      SKIP

   ENDDO

   ? m

   IF PRow() > RPT_PAGE_LEN
      FF
      ZglPrj()
   ENDIF

   ?
   ? "     Zaduzeno lice:                                     Clanovi komisije:"
   ?
   ? "     _______________                                  1.___________________"
   ?
   ? "                                                      2.___________________"
   ?
   ? "                                                      3.___________________"

   FF
   ENDPRINT

   IF _export
      open_exported_xlsx()
   ENDIF

   my_close_all_dbf()

   RETURN .T.



// ---------------------------------------------------
// vraca polja za tabelu exporta...
// ---------------------------------------------------
STATIC FUNCTION _g_exp_flds()

   LOCAL _dbf := {}

   AAdd( _dbf, { "rbr", "C", 4, 0 } )
   AAdd( _dbf, { "sredstvo", "C", 10, 0 } )
   AAdd( _dbf, { "naziv", "C", 100, 0 } )
   AAdd( _dbf, { "jmj", "C", 3, 0 } )
   AAdd( _dbf, { "datum", "D", 8, 0 } )
   AAdd( _dbf, { "kolicina", "N", 15, 2 } )

   RETURN _dbf


// -------------------------------------------
// dodaj u tabelu export-a
// -------------------------------------------
STATIC FUNCTION _a_to_exp( r_br, sredstvo, naziv_sredstva, jmj_sredstva, trenutna_kolicina, datum_nabavke )

   LOCAL nDbfArea := Select()

   o_r_export()
   APPEND BLANK
   REPLACE field->rbr WITH r_br
   REPLACE field->sredstvo WITH sredstvo
   REPLACE field->naziv WITH naziv_sredstva
   REPLACE field->jmj WITH jmj_sredstva
   REPLACE field->kolicina WITH trenutna_kolicina
   REPLACE field->datum WITH datum_nabavke

   SELECT ( nDbfArea )

   RETURN



FUNCTION ZglPrj()

   LOCAL _mod_name := "OS"
   LOCAL nArr := Select()

   IF gOsSii == "S"
      _mod_name := "SII"
   ENDIF

   P_10CPI
   ?? Upper( tip_organizacije() ) + ":", self_organizacija_naziv()
   ?
   ? _mod_name + ": Pregled "

   IF cON == "N"
      ?? "sredstava u upotrebi"
   ELSEIF cON == "B"
      ?? "novonabavljenih sredstava u toku godine"
   ELSE
      ?? "sredstava otpisanih u toku godine"
   ENDIF

   select_o_rj( cIdRj )

   SELECT ( nArr )

   ?? "     Datum:", os_datum_obracuna()

   ? "Radna jedinica:", cIdRj, rj->naz

   IF cPocinju == "D"
      ?? Space( 6 ), "(SVEUKUPNO)"
   ENDIF

   IF !Empty( cFiltK1 )
      ? "Filter grupacija K1 pravljen po uslovu: '" + Trim( cFiltK1 ) + "'"
   ENDIF

   IF !Empty( cFiltDob )
      ? "Filter za dobavljace pravljen po uslovu: '" + Trim( cFiltDob ) + "'"
   ENDIF

   IF !Empty( cBrojSobe )
      ?
      ? "Prikaz za sobu br:", cBrojSobe
      ?
   ENDIF

   IF cOpis == "D"
      P_COND
   ENDIF

   ? m
   IF lBrojSobe .AND. Empty( cBrojSobe )
      ? " Rbr. Br.sobe Inv.broj        Sredstvo               " + IF( cOpis == "D", PadC( "Opis", 1 + Len( field->opis ) ), "" ) + " jmj  kol  "
   ELSE
      ? " Rbr.  Inv.broj        Sredstvo              " + IF( cOpis == "D", PadC( "Opis", 1 + Len( field->opis ) ), "" ) + "  jmj  kol  "
   ENDIF
   ? m

   RETURN
