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


STATIC s_cPictKolicina := "999999999.999"
STATIC s_cPictIznos := "999999999.99"



/*
FUNCTION kalk_mag_promet_grupe_partnera()

   nlPK := Len( s_cPictKolicina )
   nlPI := Len( s_cPictIznos )

   cIdFirma := self_organizacija_id()
   cIdKonto := PadR( "1310", FIELD_LENGTH_IDKONTO )

   PRIVATE nVPVU := nVPVI := nNVU := nNVI := 0

   _o_tables()
   PRIVATE dDatOd := CToD( "" )
   PRIVATE dDatDo := Date()

   qqRoba := Space( 60 )
   qqIdPartner := Space( 60 )

   cGP := " "

   Box( "#PROMET GRUPE PARTNERA", 10, 75 )

   DO WHILE .T.

      IF gNW $ "DX"
         @ box_x_koord() + 2, box_y_koord() + 2 SAY "Firma "; ?? self_organizacija_id(), "-", self_organizacija_naziv()
      ELSE
         @ box_x_koord() + 2, box_y_koord() + 2 SAY "Firma: " GET cIdFirma valid {|| p_partner( @cIdFirma ), cidfirma := Left( cidfirma, 2 ), .T. }
      ENDIF

      @ box_x_koord() + 3, box_y_koord() + 2 SAY "Konto " GET cIdKonto VALID "." $ cidkonto .OR. P_Konto( @cIdKonto )
      @ box_x_koord() + 4, box_y_koord() + 2 SAY "Artikal (prazno-svi)" GET qqRoba PICT "@!S40"
      @ box_x_koord() + 6, box_y_koord() + 2 SAY "Partner (prazno-svi)" GET qqIdPartner PICT "@!S40"
      @ box_x_koord() + 7, box_y_koord() + 2 SAY "Grupa partnera (prazno-sve)" GET cGP PICT "@!"
      @ box_x_koord() + 9, box_y_koord() + 2 SAY "Datum od " GET dDatOd
      @ box_x_koord() + 9, Col() + 2 SAY "do" GET dDatDo

      READ

      ESC_BCR

      PRIVATE aUsl1 := Parsiraj( qqRoba, "IdRoba" )
      PRIVATE aUsl4 := Parsiraj( qqIDPartner, "idpartner" )

      IF aUsl1 <> NIL .AND. aUsl4 <> NIL
         EXIT
      ENDIF

   ENDDO

   BoxC()

   fSint := .F.
   cSintK := cIdKonto

   IF "." $ cidkonto
      cidkonto := StrTran( cidkonto, ".", "" )
      cIdkonto := Trim( cidkonto )
      cSintK := cIdkonto
      fSint := .T.
      lSabKon := ( Pitanje(, "Računati stanje robe kao zbir stanja na svim obuhvaćenim kontima ? (D/N)", "N" ) == "D" )
   ENDIF

   -- o_kalk()

   PRIVATE cFilt := ".t."

   IF aUsl1 <> ".t."
      cFilt += ".and." + aUsl1
   ENDIF

   IF aUsl4 <> ".t."
      cFilt += ".and." + aUsl4
   ENDIF

   IF !Empty( dDatOd ) .OR. !Empty( dDatDo )
      cFilt += ".and. DatDok>=" + dbf_quote( dDatOd ) + ".and. DatDok<=" + dbf_quote( dDatDo )
   ENDIF

   IF fSint .AND. lSabKon
      cFilt += ".and. MKonto=" + dbf_quote( cSintK )
      cSintK := ""
   ENDIF

   IF cFilt == ".t."
      SET FILTER TO
   ELSE
      SET FILTER to &cFilt
   ENDIF

   SELECT kalk

   IF fSint .AND. lSabKon
      SET ORDER TO TAG "6"
      HSEEK cidfirma
   ELSE
      SET ORDER TO TAG "3"
      HSEEK cidfirma + cidkonto
   ENDIF

  -- SELECT koncij
  -- SEEK Trim( cidkonto )
   SELECT kalk

   EOF CRET

   nLen := 1
   m := "----- ---------- -------------------- --- " + REPL( "-", nlPK ) + " " + REPL( "-", nlPI ) + " " + REPL( "-", nlPK ) + " " + REPL( "-", nlPI )

   gaZagFix := { 7, 5 }

   START PRINT CRET
   ?

   PRIVATE nTStrana := 0

   PRIVATE bZagl := {|| ZaglPGP() }

   Eval( bZagl )
   nTUlaz := nTIzlaz := 0
   nTVPVU := nTVPVI := nTNVU := nTNVI := 0
   nTRabat := 0
   nCol1 := nCol0 := 50
   PRIVATE nRbr := 0

   cLastPar := ""
   cSKGrup := ""

   DO WHILE !Eof() .AND. ;
         IF( fSint .AND. lSabKon, idfirma, idfirma + mkonto ) = cidfirma + cSintK .AND. ;
         IspitajPrekid()

      cIdRoba := Idroba
      nUlaz := nIzlaz := 0
      nVPVU := nVPVI := nNVU := nNVI := 0
      nRabat := 0

    ==  SELECT ROBA
      HSEEK cidroba
      SELECT KALK

      IF ROBA->tip $ "TUY"; SKIP 1; LOOP; ENDIF

      cIdkonto := mkonto

      DO WHILE !Eof() .AND. iif( fSint .AND. lSabKon, ;
            cidfirma + cidroba == idFirma + idroba, ;
            cidfirma + cidkonto + cidroba == idFirma + mkonto + idroba ) .AND.  IspitajPrekid()

         IF ROBA->tip $ "TU"; SKIP 1; LOOP; ENDIF

         IF !Empty( cGP )
            IF !( cLastPar == idpartner )
               cLastPar := idpartner
               // uzmi iz sifk karakteristiku GRUP
               cSKGrup := IzSifKRoba( "GRUP", idpartner, .F. )
            ENDIF
            IF cSKGrup != cGP
               SKIP 1; LOOP
            ENDIF
         ENDIF

         IF mu_i == "1"
            IF !( idvd $ "12#22#94" )
               nUlaz += kolicina - gkolicina - gkolicin2
               nCol1 := PCol() + 1
               IF koncij->naz == "P2"
                  nVPVU += Round( roba->plc * ( kolicina - gkolicina - gkolicin2 ), gZaokr )
               ELSE
                  nVPVU += Round( vpc * ( kolicina - gkolicina - gkolicin2 ), gZaokr )
               ENDIF
               nNVU += Round( nc * ( kolicina - gkolicina - gkolicin2 ), gZaokr )
            ELSE
               nIzlaz -= kolicina
               IF koncij->naz == "P2"
                  nVPVI -= Round( roba->plc * kolicina, gZaokr )
               ELSE
                  nVPVI -= Round( vpc * kolicina, gZaokr )
               ENDIF
               nNVI -= Round( nc * kolicina, gZaokr )
            ENDIF
         ELSEIF mu_i == "5"
            nIzlaz += kolicina
            IF koncij->naz == "P2"
               nVPVI += Round( roba->plc * kolicina, gZaokr )
            ELSE
               nVPVI += Round( vpc * kolicina, gZaokr )
            ENDIF
            nRabat += Round(  rabatv / 100 * vpc * kolicina, gZaokr )
            nNVI += nc * kolicina
         ELSEIF mu_i == "3"    // nivelacija
            nVPVU += Round( vpc * kolicina, gZaokr )
         ELSEIF mu_i == "8"
            nIzlaz +=  - kolicina
            IF koncij->naz == "P2"
               nVPVI += Round( roba->plc * ( -kolicina ), gZaokr )
            ELSE
               nVPVI += Round( vpc * ( -kolicina ), gZaokr )
            ENDIF
            nRabat += Round(  rabatv / 100 * vpc * ( -kolicina ), gZaokr )
            nNVI += nc * ( -kolicina )
            nUlaz +=  - kolicina
            IF koncij->naz == "P2"
               nVPVU += Round( -roba->plc * ( kolicina - gkolicina - gkolicin2 ), gZaokr )
            ELSE
               nVPVU += Round( -vpc * ( kolicina - gkolicina - gkolicin2 ), gZaokr )
            ENDIF
            nNVU += Round( -nc * ( kolicina - gkolicina - gkolicin2 ), gZaokr )
         ENDIF

         SKIP 1
      ENDDO

      IF Round( nVPVI, 4 ) <> 0 .OR. ;
            Round( nNVU, 4 ) <> 0  // ne prikazuj stavke 0
         aNaz := Sjecistr( roba->naz, 20 )
         IF PRow() > 61 + dodatni_redovi_po_stranici(); FF; Eval( bZagl ); ENDIF

         ? Str( ++nrbr, 4 ) + ".", cidroba
         nCr := PCol() + 1

         @ PRow(), PCol() + 1 SAY aNaz[ 1 ]
         @ PRow(), PCol() + 1 SAY roba->jmj
         nCol0 := PCol() + 1

         @ PRow(), PCol() + 1 SAY nUlaz PICT s_cPictKolicina
         @ PRow(), PCol() + 1 SAY nNVU PICT s_cPictIznos
         @ PRow(), PCol() + 1 SAY nIzlaz PICT s_cPictKolicina
         @ PRow(), PCol() + 1 SAY nVPVI - nRabat PICT s_cPictIznos

         IF Len( aNaz ) > 1
            @ PRow() + 1, 0 SAY ""
            @ PRow(), nCR  SAY aNaz[ 2 ]
         ENDIF

         nTUlaz  += nUlaz ; nTIzlaz += nIzlaz
         nTVPVU  += nVPVU ; nTVPVI  += nVPVI
         nTNVU   += nNVU  ; nTNVI   += nNVI
         nTRabat += nRabat
      ENDIF

   ENDDO

   ? m
   ? "UKUPNO:"
   @ PRow(), nCol0    SAY nTUlaz PICT s_cPictKolicina
   @ PRow(), PCol() + 1 SAY nTNVU PICT s_cPictIznos
   @ PRow(), PCol() + 1 SAY nTIzlaz PICT s_cPictKolicina
   @ PRow(), PCol() + 1 SAY nTVPVI - nTRabat PICT s_cPictIznos
   nCol1 := PCol() + 1

   ? m
   FF
   ENDPRINT

   IF gKalks
      SELECT kalk
      USE
   ENDIF
   my_close_all_dbf()

   RETURN




FUNCTION ZaglPGP()

   Preduzece()

   P_12CPI

--   SELECT KONTO; HSEEK cidkonto

   SET CENTURY ON
   ?? "KALK: PROMET GRUPE PARTNERA ZA PERIOD", dDatOd, "-", dDatdo, "  na dan", Date(), Space( 4 ), "Str:", Str( ++nTStrana, 3 )
   SET CENTURY OFF

   ? "Grupa partnera:", IF( Empty( cGP ), "SVE", "'" + cGP + "'" )
   ? "Magacin:", cIdkonto, "-", konto->naz
   SELECT KALK

   ? m
   ?U " R.  *  ŠIFRA   *   NAZIV ARTIKLA    *JMJ*" + PadC( "   ULAZ   ", nlPK ) + "*" + PadC( "  NV ULAZA  ", nlPI ) + "*" + PadC( "  IZLAZ   ", nlPK ) + "*" + PadC( " VPV IZLAZA ", nlPI ) + "*"
   ? " BR. * ARTIKLA  *                    *   *" + PadC( "          ", nlPK ) + "*" + PadC( "            ", nlPI ) + "*" + PadC( "          ", nlPK ) + "*" + PadC( " minus RABAT", nlPI ) + "*"
   ? "     *    1     *         2          * 3 *" + PadC( "     4    ", nlPK ) + "*" + PadC( "      5     ", nlPI ) + "*" + PadC( "     6    ", nlPK ) + "*" + PadC( "      7     ", nlPI ) + "*"
   ? m

   RETURN ( nil )


   STATIC FUNCTION _o_tables()

    --  o_sifk()
    --  o_sifv()
    --  o_roba()
      o_koncij()
      o_konto()
      o_partner()

      RETURN .T.


  */
