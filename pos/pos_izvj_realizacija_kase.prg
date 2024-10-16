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

STATIC LEN_TRAKA := 80
STATIC LEN_RAZMAK := 1
STATIC PIC_UKUPNO := "9999999.99"
STATIC s_oPDF

MEMVAR dDatum0, dDatum1, plPrikazPRO
MEMVAR cUslovRadnici, cUslovVrsteP
MEMVAR cPrikazPoVrstamaPlacanja

FUNCTION realizacija_kase

   PARAMETERS dDatum0, dDatum1 // funkcije VarEdit zahtjevaju privatne varijable

   LOCAL xPrintOpt
   LOCAL bZagl
   LOCAL cVarijanta := "0"

   PRIVATE cUslovRadnici := Space( 60 )
   PRIVATE cUslovVrsteP := Space( 60 )
   PRIVATE cIdPos := pos_pm()

   PRIVATE aNiz
   PRIVATE cFilterIdRadnik := {}
   PRIVATE cFilterIdVrsteP := {}
   PRIVATE plPrikazPRO := "O"
   PRIVATE cFilter := ".t."
   PRIVATE cPartId := Space( 8 )

   set_cursor_on()

   IF ( dDatum0 == NIL )
      dDatum0 := danasnji_datum()
      dDatum1 := danasnji_datum()
   ENDIF

   pos_realizacija_tbl_cre_pom()
   o_pos_tables()
   o_pom_table()

   cPrikazPoVrstamaPlacanja := "N"
   cAPrometa := "N"
   cVrijOd := "00:00"
   cVrijDo := "23:59"

   IF pos_get_vars_izvjestaj_realizacija( @cIdPos, @dDatum0, @dDatum1, @cVrijOd, @cVrijDo, @cFilterIdRadnik, @cFilterIdVrsteP, @cUslovVrsteP, @cAPrometa, @cPartId ) == 0
      RETURN 0
   ENDIF

   s_oPDF := PDFClass():New()
   xPrintOpt := hb_Hash()
   xPrintOpt[ "tip" ] := "PDF"
   xPrintOpt[ "layout" ] := "portrait"
   xPrintOpt[ "opdf" ] := s_oPDF
   xPrintOpt[ "font_size" ] := 9
   IF f18_start_print( NIL, xPrintOpt,  "POS REALIZACIJA NA DAN: " + DToC( Date() ) ) == "X"
      RETURN .F.
   ENDIF

   bZagl := {|| pos_zagl_realizacija( dDatum0, dDatum1, cIdPos, cUslovRadnici, cUslovVrsteP ) }
   Eval( bZagl )
   o_pos_tables()
   o_pom_table()

   SELECT pos_doks
   pos_set_filter_pos_doks( @cFilter, cFilterIdRadnik, cFilterIdVrsteP, cVrijOd, cVrijDo, cPartId )
   pos_kasa_pripremi_pom_za_realkase( cIdPos, "42", dDatum0, dDatum1 )

   PRIVATE nTotal := 0
   PRIVATE nTotalPopust := 0

   SELECT POM
   SET ORDER TO TAG "1"
   IF ( plPrikazPRO $ "PO" )
      check_nova_strana( bZagl, s_oPDF )
      pos_realizacija_po_radnicima( bZagl )
   ENDIF

   check_nova_strana( bZagl, s_oPDF, .F., 6 )
   pos_pdv_po_tarifama( dDatum0, dDatum1, cIdPos, NIL )

   f18_end_print( NIL, xPrintOpt )
   my_close_all_dbf()

   RETURN .T.


STATIC FUNCTION pos_get_vars_izvjestaj_realizacija( cIdPos, dDatum0, dDatum1, cVrijOd, cVrijDo, cFilterIdRadnik, cFilterIdVrsteP, cUslovVrsteP, cAPrometa, cPartId )

   LOCAL aNiz

   aNiz := {}
   cIdPos := pos_pm()

   AAdd( aNiz, { "Radnici (prazno-svi)", "cUslovRadnici",, "@!S30", } )
   AAdd( aNiz, { "Vrste plaćanja (prazno-sve)", "cUslovVrsteP",, "@!S30", } )

   AAdd( aNiz, { "Izvještaj se pravi od datuma", "dDatum0",,, } )
   AAdd( aNiz, { "                   do datuma", "dDatum1",,, } )

   plPrikazPRO := "O"
   AAdd( aNiz, { "Prikazati Pazar/Robe/Oboje (P/R/O)?", "plPrikazPRO", "plPrikazPRO$'PRO'", "@!", } )

   AAdd( aNiz, { "Prikazati pregled po vrstama plaćanja ?", "cPrikazPoVrstamaPlacanja", "cPrikazPoVrstamaPlacanja$'DN'", "@!", } )
   AAdd( aNiz, { "Vrijeme od", "cVrijOd",, "99:99", } )
   AAdd( aNiz, { "Vrijeme do", "cVrijDo", "cVrijDo>=cVrijOd", "99:99", } )
   AAdd( aNiz, { "Partner (prazno-svi)", "cPartId", ".t.",, } )

   DO WHILE .T.

      IF !VarEdit( aNiz, 6, 5, 24, 74, "USLOVI ZA IZVJEŠTAJ: REALIZACIJA KASE-PRODAJNOG MJESTA", "B1" )
         CLOSE ALL
         RETURN 0
      ENDIF

      cFilterIdRadnik := Parsiraj( cUslovRadnici, "IdRadnik" )
      cFilterIdVrsteP := Parsiraj( cUslovVrsteP, "IdVrsteP" )
      IF cFilterIdRadnik <> NIL .AND. cFilterIdVrsteP <> NIL .AND. dDatum0 <= dDatum1
         EXIT
      ELSEIF cFilterIdRadnik == nil
         Msg( "Kriterij za radnike nije korektno postavljen!" )
      ELSEIF cFilterIdVrsteP == nil
         Msg( "Kriterij za vrste placanja nije korektno postavljen!" )
      ELSE
         Msg( "'Datum do' ne smije biti stariji od 'datum od'!" )
      ENDIF

   ENDDO

   RETURN 1


STATIC FUNCTION pos_zagl_realizacija( dDatum0, dDatum1, cIdPos, cUslovRadnici, cUslovVrsteP )

   ? "Prodavnica:", pos_prodavnica()
   IF Empty( cIdPos )
      ? "PRODAJNO MJESTO: SVA"
   ELSE
      ? "PRODAJNO MJESTO: " + cIdPos
   ENDIF

   IF Empty( cUslovRadnici )
      ? "RADNIK     :  SVI"
   ELSE
      ? "RADNIK     : " + cUslovRadnici + "-" + RTrim( find_pos_osob_naziv( cUslovRadnici ) )
   ENDIF

   IF Empty( cUslovVrsteP )

      ?U "VR.PLAĆANJA: SVE"
   ELSE
      ?U "VR.PLAĆANJA: " + RTrim( cUslovVrsteP )
   ENDIF

   ? "PERIOD     : " + FormDat1( dDatum0 ) + " - " + FormDat1( dDatum1 )

   RETURN .T.


STATIC FUNCTION pos_set_filter_pos_doks( cFilter, cFilterIdRadnik, cFilterIdVrsteP, cVrijOd, cVrijDo, cPartId )

   SELECT pos_doks
   SET ORDER TO TAG "2"  // "2" - "IdVd+DTOS (Datum)"

   IF cFilterIdRadnik <> ".t."
      cFilter += ".and." + cFilterIdRadnik
   ENDIF

   IF cFilterIdVrsteP <> ".t."
      cFilter += ".and." + cFilterIdVrsteP
   ENDIF
   IF !( cVrijOd == "00:00" .AND. cVrijDo == "23:59" )
      cFilter += ".and. Vrijeme>='" + cVrijOd + "'.and. Vrijeme<='" + cVrijDo + "'"
   ENDIF
   IF !Empty( cPartId )
      cFilter += ".and. idPartner==" + dbf_quote( cPartId )
   ENDIF

   IF !( cFilter == ".t." )
      SET FILTER TO &cFilter
   ENDIF

   RETURN .T.



FUNCTION pos_realizacija_po_vrstama_placanja( bZagl )

   // Rekapitulacija vrsta placanja

   LOCAL nTotal
   LOCAL nTotalPopust
   LOCAL nTotPos
   LOCAL nTotalPosPopust
   LOCAL nTotVrstaPlacanja
   LOCAL nTotVP2
   LOCAL nTotVrstaPlacanjaPopust

   ?
   ?U PadC( "REKAPITULACIJA PO VRSTAMA PLAĆANJA", LEN_TRAKA )
   ? PadC( "------------------------------------", LEN_TRAKA )
   ?
   ?U Space( 5 ) + PadR( "Vrsta plaćanja", 20 ), "     Bruto     -    Popust   =    NETO"
   ? Space( 5 ) + Replicate( "-", 20 ), Replicate( "-", 14 ), Replicate( "-", 14 ), Replicate( "-", 14 )

   nTotal := 0
   nTotalPopust := 0

   SELECT POM
   SET ORDER TO TAG "4"
   GO TOP

   DO WHILE !Eof()
      cIdPos := pom->IdPos
      IF Empty( cIdPos )
         ?
         ? Replicate( "-", LEN_TRAKA ), Replicate( "-", 14 ), Replicate( "-", 14 )
         ? Space( 1 ) + cIdPos + "    Bruto   -  Popust   =  Neto"
         ? Replicate( "-", LEN_TRAKA ), Replicate( "-", 14 ), Replicate( "-", 14 )
      ENDIF

      nTotPos := 0
      nTotalPosPopust := 0

      DO WHILE !Eof() .AND. pom->IdPos == cIdPos
         check_nova_strana( bZagl, s_oPDF )
         nTotVrstaPlacanja := 0
         nTotVP2 := 0
         nTotVrstaPlacanjaPopust := 0
         cIdVrsteP := pom->IdVrsteP
         select_o_vrstep( cIdVrsteP )
         check_nova_strana( bZagl, s_oPDF )
         ? Space( 5 ) + vrstep->Naz
         SELECT pom
         DO WHILE !Eof() .AND. pom->( IdPos + IdVrsteP ) == ( cIdPos + cIdVrsteP )
            nTotVrstaPlacanja += pom->Iznos
            nTotVrstaPlacanjaPopust += pom->popust
            SKIP
         ENDDO
         ?? Str( nTotVrstaPlacanja, 14, 2 ), Str( nTotVrstaPlacanjaPopust, 14, 2 ), Str( nTotVrstaPlacanja - nTotVrstaPlacanjaPopust, 14, 2 )
         nTotPos += nTotVrstaPlacanja
         nTotalPosPopust += nTotVrstaPlacanjaPopust
      ENDDO

      check_nova_strana( bZagl, s_oPDF, .F., 5 )
      pos_total_kasa( cIdPos, nTotPos, nTotalPosPopust, 0, "-" )

      nTotal += nTotPos
      nTotalPopust += nTotalPosPopust

   ENDDO

   IF Empty( cIdPos )
      ? REPL ( "=", LEN_TRAKA )
      ? PadC ( "SVE KASE", 20 ) + Str ( nTotal, 20, 2 )
      ? REPL ( "=", LEN_TRAKA )
   ENDIF

   RETURN .T.


STATIC FUNCTION pos_realizacija_po_radnicima( bZagl )

   LOCAL nTotal, nTotalPopust
   LOCAL nTotPos, nTotalPosPopust
   LOCAL cIdPos, cIdRadnik
   LOCAL nTotalRadnik, nTotalRadnikPopust
   LOCAL nTotVrstaPlacanja, nTotVrstaPlacanjaPopust
   LOCAL cIdVrsteP
   LOCAL i, aReal

   ?
   ?U "ŠIFRA PREZIME I IME RADNIKA"
   ? "-----", Replicate( "-", 34 )

   nTotal := 0
   nTotalPopust := 0

   SELECT pom
   GO TOP

   DO WHILE !Eof()
      nTotPos := 0
      nTotalPosPopust := 0
      cIdPos := pom->IdPos
      DO WHILE !Eof() .AND. pom->IdPos == cIdPos
         nTotalRadnik := 0
         nTotalRadnikPopust := 0
         cIdRadnik := pom->IdRadnik
         find_pos_osob_by_naz( cIdRadnik )
         SELECT pom
         ? cIdRadnik + "  " + PadR( osob->Naz, 25 ) + "   Bruto        Popust       Neto"

         ? Replicate( "-", 5 ), Replicate( "-", 34 ), Replicate( "-", 14 ), Replicate( "-", 14 )
         DO WHILE !Eof() .AND. pom->IdPos + pom->IdRadnik == cIdPos + cIdRadnik
            nTotVrstaPlacanja := 0
            nTotVrstaPlacanjaPopust := 0
            cIdVrsteP := pom->IdVrsteP
            select_o_vrstep( cIdVrsteP )
            SELECT pom
            ? Space( 6 ) + PadR( vrstep->Naz, 20 )
            DO WHILE !Eof() .AND. pom->IdPos + pom->IdRadnik + pom->IdVrsteP == cIdPos + cIdRadnik + cIdVrsteP
               nTotVrstaPlacanja += pom->Iznos
               nTotVrstaPlacanjaPopust += pom->popust
               SKIP
            ENDDO
            ?? Str( nTotVrstaPlacanja, 14, 2 ), Str( nTotVrstaPlacanjaPopust, 14, 2 ),  Str( nTotVrstaPlacanja - nTotVrstaPlacanjaPopust, 14, 2 )
            nTotalRadnik += nTotVrstaPlacanja

            nTotalRadnikPopust += nTotVrstaPlacanjaPopust
         ENDDO // radnik
         ? Space( 6 ) + Replicate( "-", 34 )
         ? Space( 6 ) + PadL( "UKUPNO BRUTO", 20 ) + Str( nTotalRadnik, 14, 2 )
         //IF nTotalRadnikPopust <> 0
         ? Space( 6 ) + PadL( pos_popust_prikaz(), 20 ) + Str( nTotalRadnikPopust, 14, 2 )
         ? Space( 6 ) + PadL( "UKUPNO NETO:", 20 ) + Str( nTotalRadnik - nTotalRadnikPopust, 14, 2 )
         //ENDIF
         ? Space( 6 ) + Replicate( "-", 34 )
         nTotPos += nTotalRadnik
         nTotalPosPopust += nTotalRadnikPopust
      ENDDO  // kasa
      ? Replicate( "-", 40 )
      ? PadC( "BRUTO KASA " + cIdPos, 20 ) + Str( nTotPos, 20, 2 )

      IF nTotalPosPopust <> 0
         ? PadL( pos_popust_prikaz(), 20 ) + Str( nTotalPosPopust, 20, 2 )
         ? PadL( "KASA NETO:", 20 ) + Str( nTotPos - nTotalPosPopust, 20, 2 )
      ENDIF
      ? Replicate( "-", 40 )
      nTotal += nTotPos
      nTotalPopust += nTotalPosPopust
   ENDDO // ! pom->eof()
   IF Empty( cIdPos )
      ? Replicate( "=", 40 )
      ? PadC( "KASE BRUTO", 20 ) + Str( nTotal, 20, 2 )
      ? PadC(    "POPUST", 20 ) + Str( nTotalPopust, 20, 2 )
      ? PadC( "KASE NETO", 20 ) + Str( nTotal - nTotalPopust, 20, 2 )
      ? Replicate( "=", 40 )
   ENDIF

   // idemo skupno sa vrstama placanja
   IF cPrikazPoVrstamaPlacanja == "D"
      pos_realizacija_po_vrstama_placanja( bZagl )
   ENDIF

   IF plPrikazPRO $ "RO"
      // ako je zakljucenje NE realizacija po robama

      set_pos_zagl_realizacija()
      nTotal := 0
      nTotalPopust := 0

      SELECT POM
      SET ORDER TO TAG "3"
      GO TOP
      DO WHILE !Eof()
         nTotPos := 0
         nTotalPosPopust := 0
         cIdPos := POM->IdPos
         IF Empty( cIdPos )
            ? REPL ( "-", LEN_TRAKA )
            ? Space( 1 ) + cIdPos
            ? REPL ( "-", LEN_TRAKA )
         ENDIF
         SELECT POM

         DO WHILE !Eof() .AND. pom->idPos == cIdPos
            select_o_roba( pom->idRoba )

            cStr1 := ""
            IF grbStId == "D"
               cStr1 += AllTrim( pom->idroba ) + " "
            ENDIF

            cStr1 += AllTrim( roba->naz )
            cStr1 += " (" + AllTrim( roba->jmj ) + ") "
            nLen1 := Len( cStr1 )

            SELECT POM

            _IdRoba := POM->idRoba
            nRobaIzn := 0
            nRobaKol := 0


            nRobaIzn3 := 0
            DO WHILE !Eof() .AND. POM->IdPos + POM->IdRoba == cIdPos + _IdRoba
               nRobaKol += POM->Kolicina
               nRobaIzn += POM->Iznos
               nRobaIzn3 += POM->popust

               SKIP
            ENDDO

            cStr2 := ""
            cStr2 += show_number( nRobaKol, NIL, - 8 )
            nLen2 := Len( cStr2 )

            cStr3 := show_number( nRobaIzn, PIC_UKUPNO )
            nLen3 := Len( cStr3 )

            aReal := SjeciStr( cStr1, LEN_TRAKA )

            FOR i := 1 TO Len( aReal )
               ? RTrim( aReal[ i ] )
               nLenRow := Len( RTrim( aReal[ i ] ) )
            NEXT

            IF  nLen2 + 1 + nLen3 > LEN_TRAKA - nLenRow
               ? PadL( cStr2 + Space( LEN_RAZMAK ) + cStr3, LEN_TRAKA )
            ELSE
               ?? PadL( cStr2 + Space( LEN_RAZMAK ) + cStr3, LEN_TRAKA - nLenRow )
            ENDIF

            SELECT POM

            nTotPos += nRobaIzn
            nTotalPosPopust += nRobaIzn3
         ENDDO

         pos_total_kasa( cIdPos, nTotPos, nTotalPosPopust, 0, "-" )
         nTotal += nTotPos
         nTotalPopust += nTotalPosPopust
      ENDDO
      IF Empty( cIdPos )
         ? REPL( "-", LEN_TRAKA )
         ? PadC( " SVE KASE BRUTO:", 25 ), Transform( nTotal, "999,999,999.99" )
         ? PadC( "         POPUST:", 25 ), Transform( nTotalPopust, "999,999,999.99" )
         ? PadC( "  SVE KASE NETO:", 25 ), Transform( nTotal - nTotalPopust, "999,999,999.99" )
         ? REPL( "-", LEN_TRAKA )
      ENDIF
   ENDIF

   RETURN .T.


STATIC FUNCTION set_pos_zagl_realizacija()

   LOCAL cLinija

   cLinija := Replicate( "-", LEN_TRAKA )

   ?
   ? cLinija
   ? PadC( "REALIZACIJA PO ROBAMA", LEN_TRAKA )
   ? cLinija
   ?

   cStr1 := ""

   IF grbStId == "D"
      cStr1 += "Sifra, naziv, jmj, kolicina"
   ELSE
      cStr1 += "Naziv, jmj, kolicina"
   ENDIF

   cHead := cStr1 + PadL( "vrijednost", LEN_TRAKA - Len( cStr1 ) )

   ? cHead
   ? cLinija

   RETURN .T.



STATIC FUNCTION pos_total_kasa( cIdPos, nTotPos, nTotalPosPopust, nTotPosk, cPodvuci )

   ? REPL( cPodvuci, LEN_TRAKA )
   ? PadC( "BRUTO KASA:" + cIdPos, 25 ), Transform( nTotPos, "999,999,999.99" )
   //IF nTotalPosPopust <> 0
   ? PadL( pos_popust_prikaz(), 25 ) + Str( nTotalPosPopust, 15, 2 )
   ? PadL( " NETO KASA:", 25 ) + Str( nTotPos - nTotalPosPopust, 15, 2 )
   //ENDIF
   ? REPL( cPodvuci, LEN_TRAKA )
   ?

   RETURN .T.


STATIC FUNCTION pos_realizacija_tbl_cre_pom()

   LOCAL aDbf := {}

   AAdd( aDbf, { "IdPos", "C",  2, 0 } )
   AAdd( aDbf, { "IdRadnik", "C",  4, 0 } )
   AAdd( aDbf, { "IdVrsteP", "C",  2, 0 } )
   AAdd( aDbf, { "IdRoba", "C", 10, 0 } )
   AAdd( aDbf, { "Kolicina", "N", 12, 3 } )
   AAdd( aDbf, { "Iznos", "N", 20, 5 } )
   AAdd( aDbf, { "popust", "N", 20, 5 } )

   pos_cre_pom_dbf( aDbf )

   RETURN .T.


STATIC FUNCTION o_pom_table()

   SELECT ( F_POM )
   IF Used()
      USE
   ENDIF

   my_use_temp( "POM", my_home() + "pom", .F., .T. )
   INDEX ON ( IdPos + IdRadnik + IdVrsteP + IdRoba ) TAG "1"
   INDEX ON ( IdPos + IdRoba ) TAG "2"
   INDEX ON ( IdPos + IdVrsteP ) TAG "4"
   SET ORDER TO TAG "1"

   RETURN .T.
