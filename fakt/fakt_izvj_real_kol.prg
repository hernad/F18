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


MEMVAR cLinija, cRelation, gnLMarg, cSvediJmj, cPrikaz, dDatOd, dDatDo, nStrana, lGroup

MEMVAR cSection, cHistory, aHistory

FUNCTION fakt_specif_prodaje_real_kolicina()

   LOCAL nX := 1
   LOCAL cExport := "N"
   LOCAL lExpRpt := .F.
   LOCAL lRelations := .F.
   LOCAL cDDokOtpr := "D"
   LOCAL GetList := {}
   LOCAL cFilter
   LOCAL cIdFirma
   LOCAL cOpcine30, cIdRefer, cFilterOpcinaReferent

   PRIVATE cPrikaz
   PRIVATE cSection := "N"
   PRIVATE cHistory := " "
   PRIVATE aHistory := {}
   PRIVATE cIdPartner
   PRIVATE nStrana := 0
   PRIVATE cLinija
   PRIVATE lGroup := .F.
   PRIVATE cRelation := Space( 4 )
   PRIVATE cSvediJmj := "N"

   // da li se koriste relacije
   // o_fakt_dbf()
   // SELECT fakt

   // IF fakt->( FieldPos( "idrelac" ) ) <> 0
   lRelations := .T.
   // ENDIF

   // _o_tables()
   // o_ops()

   // partneri po grupama
   lGroup := p_sifk_partn_group()

   cIdfirma := self_organizacija_id()
   dDatOd := CToD( "" )
   dDatDo := Date()
   qqTipDok := Space( 20 )

   Box( "#SPECIFIKACIJA PRODAJE PO ARTIKLIMA", 16, 77 )
   o_params()
   RPar( "c1", @cIdFirma )
   RPar( "d1", @dDatOd )
   RPar( "d2", @dDatDo )
   RPar( "d3", @cDDokOtpr )
   qqIdRoba := Space( 20 )
   cPrikaz := "2"
   cIdRoba := Space( 20 )
   cImeKup := Space( 20 )
   cOpcine30 := Space( 200 )
   cIdRefer := SPACE(10)
   qqPartn := Space( 20 )
   RPar( "sk", @qqPartn )
   RPar( "td", @qqTipDok )
   qqPartn := PadR( qqPartn, FIELD_LEN_PARTNER_ID )
   qqIdRoba := PadR( qqIdRoba, 200 )
   qqTipDok := PadR( qqTipDok, 40 )

   nX := 2

   DO WHILE .T.

      cIdFirma := PadR( cIdFirma, 2 )

      fakt_getlist_rj_read( box_x_koord() + nX, box_y_koord() + 2, @GetList, @cIdFirma )

      ++nX
      @ box_x_koord() + nX, box_y_koord() + 2 SAY "Tip dokumenta " GET qqTipDok PICT "@!S20"

      ++nX
      @ box_x_koord() + nX, box_y_koord() + 2 SAY "Od datuma "  GET dDatOd
      @ box_x_koord() + nX, Col() + 1 SAY "do"  GET dDatDo

      ++nX
      @ box_x_koord() + nX, box_y_koord() + 2 SAY "gledati dat. (D)dok. (O)otpr. (V)valute:" GET cDDokOtpr VALID cDDokOtpr $ "DOV" PICT "@!"

      nX := nX + 3
      @ box_x_koord() + nX, box_y_koord() + 2 SAY "Uslov po sifri partnera (prazno svi) "  GET qqPartn PICT "@!" VALID {|| Empty( qqPartn ) .OR. p_partner( @qqPartn ) }
      ++nX
      @ box_x_koord() + nX, box_y_koord() + 2 SAY "Uslov po artiklu (prazno svi) "  GET qqIdRoba PICT "@S30"

      ++nX
      @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Uslov po općini (prazno sve) "  GET cOpcine30 PICT "@S30"

      ++nX
      @ box_x_koord() + nX, box_y_koord() + 2 SAY "Relacija (prazno sve):" GET cRelation
      @ box_x_koord() + nX, COL() + 2 SAY8 "Referent: "  GET cIdRefer PICT "@!" VALID Empty(cIdRefer) .OR. P_Refer(@cIdRefer)

      IF lGroup
         PRIVATE cPGroup := Space( 3 )
         ++nX
         @ box_x_koord() + nX, box_y_koord() + 2 SAY "Grupa partnera (prazno sve):" GET cPGroup VALID Empty( cPGroup ) .OR. cPGroup $ "VP #AMB#SIS#OST"
      ENDIF

      ++nX
      @ box_x_koord() + nX, box_y_koord() + 2 SAY "Svedi na jedinicu mjere ?" GET cSvediJmj VALID cSvediJmj $ "DN" PICT "@!"

      nX := nX + 2
      @ box_x_koord() + nX, box_y_koord() + 2 SAY "Export u XLSX?" GET cExport VALID cExport $ "DN" PICT "@!"

      READ

      ESC_BCR

      aUslRB := Parsiraj( qqIdRoba, "IDROBA", "C" )
      cFilterOpcinaReferent := Parsiraj( cOpcine30, "IDOPS", "C" )
      IF !Empty(cIdRefer)
        cFilterOpcinaReferent += ".and. idrefer==" + sql_quote(cIdRefer)
      ENDIF

      aUslTD := Parsiraj( qqTipdok, "IdTipdok", "C" )

      IF ( aUslTD <> NIL )
         EXIT
      ENDIF


   ENDDO

   qqTipDok := Trim( qqTipDok )
   qqPartn := Trim( qqPartn )
   qqIdRoba := Trim( qqIdRoba )
   qqTipDok := Trim( qqTipDok )

   WPar( "c1", cIdFirma )
   WPar( "d1", dDatOd )
   WPar( "d2", dDatDo )
   WPar( "d3", cDDokOtpr )
   WPar( "vi", cPrikaz )
   WPar( "td", qqTipDok )

   SELECT params
   USE
   BoxC()

   IF cExport == "D" // ako je export izabran
      lExpRpt := .T.
   ENDIF

   IF lExpRpt == .T. // export dokumenta
      aExpFields := get_rpt_fields()
      IF !create_dbf_r_export( aExpFields )
         RETURN .F.
      ENDIF
   ENDIF

   // _o_tables()

   // SELECT fakt

   cFilter := ".t."

   IF ( !Empty( dDatOd ) .OR. !Empty( dDatDo ) )
      IF cDDokOtpr == "D"
         cFilter += ".and.  datdok>=" + dbf_quote( dDatOd ) + " .and. datdok<=" + dbf_quote( dDatDo )
      ENDIF
   ENDIF

   // IF ( !Empty( cIdFirma ) )
   // cFilter += " .and. IdFirma=" + dbf_quote( cIdFirma )
   // ENDIF

   IF ( !Empty( qqPartn ) )
      cFilter += " .and. IdPartner=" + dbf_quote( qqPartn )
   ENDIF

   IF ( !Empty( qqIdRoba ) )
      cFilter += " .and. " + aUslRB
   ENDIF

   IF ( !Empty( qqTipDok ) )
      cFilter += " .and. " + aUslTD
   ENDIF

   IF ( !Empty( cRelation ) )
      cFilter += " .and. idrelac == " + dbf_quote( cRelation )
   ENDIF

   IF ( cFilter = " .t. .and. " )
      cFilter := SubStr( cFilter, 9 )
   ENDIF


   IF cPrikaz == "1"
      find_fakt_za_period( cIdFirma, dDatOd, dDatDo, NIL, NIL, "6" ) // hIndexes[ "6" ] := "idfirma+idpartner+idroba+idtipdok+dtos(datdok)"
   ELSE
      find_fakt_za_period( cIdFirma, dDatOd, dDatDo, NIL, NIL, "3" ) // idroba, datdok
   ENDIF

   IF ( cFilter == ".t." )
      SET FILTER TO
   ELSE
      SET FILTER TO &cFilter
   ENDIF
   GO TOP

   EOF CRET

   START PRINT CRET

   IF cPrikaz == "1"
      cLinija := "---- ------ -------------------------- ------------"
   ELSE
      cLinija := "---- ----------- " + REPL( "-", 40 ) + " ------------" + ;
         " ------------ -------------"
   ENDIF

   IF cSvediJmj == "D"
      cLinija += " ------------"
   ENDIF

   cIdPartner := fakt->idPartner

   fakt_zagl_specif_prodaje( cIdFirma, cIdRefer, , cOpcine30 )

   IF cPrikaz == "1"
      seek_fakt( cIdFirma )
      nC := 0
      nCol1 := 10
      nTKolicina := 0

      DO WHILE !Eof() .AND. IdFirma == cIdFirma

         IF cDDokOtpr == "O"
            seek_fakt_doks( fakt->idfirma, fakt->idtipdok, fakt->brdok )
            IF fakt_doks->dat_otpr < dDatOd .OR. fakt_doks->dat_otpr > dDatDo
               SELECT fakt
               SKIP
               LOOP
            ENDIF
            SELECT fakt
         ENDIF

         IF cDDokOtpr == "V"
            seek_fakt_doks( fakt->idfirma, fakt->idtipdok, fakt->brdok )
            IF fakt_doks->dat_val < dDatOd .OR. fakt_doks->dat_val > dDatDo
               SELECT fakt
               SKIP
               LOOP
            ENDIF
            SELECT fakt
         ENDIF

         nKolicina := 0
         cIdPartner := IdPartner

         DO WHILE !Eof() .AND. IdFirma == cIdFirma .AND. idpartner == cIdpartner

            IF cDDokOtpr == "O"
               seek_fakt_doks( fakt->idfirma, fakt->idtipdok, fakt->brdok )
               IF fakt_doks->dat_otpr < dDatOd .OR.  fakt_doks->dat_otpr > dDatDo
                  SELECT fakt
                  SKIP
                  LOOP
               ENDIF
               SELECT fakt
            ENDIF

            IF cDDokOtpr == "V"
               seek_fakt_doks( fakt->idfirma, fakt->idtipdok, fakt->brdok )
               IF fakt_doks->dat_val < dDatOd .OR. fakt_doks->dat_val > dDatDo
                  SELECT fakt
                  SKIP
                  LOOP
               ENDIF
               SELECT fakt
            ENDIF

            select_o_partner( fakt->idPartner )
            SELECT fakt
            IF !( partn->( &cFilterOpcinaReferent ) )
               SKIP 1
               LOOP
            ENDIF

            nKolicina += kolicina

            SKIP 1

         ENDDO

         IF PRow() > 61
            FF
            fakt_zagl_specif_prodaje( cIdFirma, cIdRefer, , cOpcine30 )
         ENDIF

         select_o_partner( cIdPartner )
         SELECT fakt

         IF Round( nKolicina, 4 ) <> 0
            ? Space( gnLMarg )
            ?? Str( ++nC, 4 ) + ".", cIdPartner, partn->naz
            nCol1 := PCol() + 1
            @ PRow(), PCol() + 1 SAY Str( nKolicina, 12, 2 )
            nTKolicina += nKolicina
         ENDIF

         IF lExpRpt
            fill_exp_tbl( cIdPartner, partn->naz, nKolicina, 0 )
         ENDIF
      ENDDO
   ELSE


      nC := 0
      nCol1 := 10
      nTKolicina := 0
      nTKolJmj := 0
      nTOsn := 0
      nTUkupno := 0
      nCounter := 0
      nMX := 0
      nMY := 0

      Box(, 3, 60 )

      SET DEVICE TO SCREEN
      @ 1 + box_x_koord(), 2 + box_y_koord() SAY8 "formiranje izvještaja u toku..."
      nMX := 3 + box_x_koord()
      nMY := 2 + box_y_koord()
      SET DEVICE TO PRINTER

      DO WHILE !Eof()

         nKolicina := 0
         nKolJmj := 0
         nOsn := 0
         nPojOsn := 0
         nUkupno := 0
         nPojUk := 0
         cIdRoba := IdRoba

         IF cDDokOtpr == "O"
            seek_fakt_doks( fakt->idfirma, fakt->idtipdok, fakt->brdok )
            IF fakt_doks->dat_otpr < dDatOd .OR. fakt_doks->dat_otpr > dDatDo
               SELECT fakt
               SKIP
               LOOP
            ENDIF
            SELECT fakt
         ENDIF

         IF cDDokOtpr == "V"
            seek_fakt_doks( fakt->idfirma, fakt->idtipdok, fakt->brdok )
            IF fakt_doks->dat_val < dDatOd .OR. fakt_doks->dat_val > dDatDo
               SELECT fakt
               SKIP
               LOOP
            ENDIF
            SELECT fakt
         ENDIF

         DO WHILE !Eof() .AND. idRoba == cIdRoba

            IF cDDokOtpr == "O"
               seek_fakt_doks( fakt->idfirma, fakt->idtipdok, fakt->brdok )
               IF fakt_doks->dat_otpr < dDatOd .OR. fakt_doks->dat_otpr > dDatDo
                  SELECT fakt
                  SKIP
                  LOOP
               ENDIF
               SELECT fakt
            ENDIF

            IF cDDokOtpr == "V"
               seek_fakt_doks( fakt->idfirma, fakt->idtipdok, fakt->brdok )
               IF fakt_doks->dat_val < dDatOd .OR. fakt_doks->dat_val > dDatDo
                  SELECT fakt
                  SKIP
                  LOOP
               ENDIF
               SELECT fakt
            ENDIF

            select_o_partner( fakt->idPartner )
            SELECT fakt
            IF !( partn->( &cFilterOpcinaReferent ) )
               SKIP 1
               LOOP
            ENDIF

            IF lGroup .AND. !Empty( cPGroup )
               cPartn := fakt->idpartner
               select_o_partner( cPartn )
               SELECT fakt
               IF !p_in_group( cPartn, cPGroup )
                  SKIP
                  LOOP
               ENDIF
            ENDIF

            nKolicina += kolicina

            IF cSvediJmj == "D"
               cJmj := ""
               nKolJmj += svedi_na_jedinicu_mjere( kolicina, idroba, @cJmj )
            ENDIF

            // pojedinacna osnova
            nPojOsn := Round( kolicina * Cijena * ( 1 - Rabat / 100 ) * ( 1 + Porez / 100 ), fakt_zaokruzenje() )


            nPojUk := nPojOsn // ukupni iznos sa PDV

            // ako je rijec o MP dokumentima
            // potrebno je izvuci osnovicu iz iznosa
            // jer se radi o cijeni sa PDV-om

            IF field->idtipdok $ "11#13#23"
               nPojOsn := _osnovica( field->idtipdok, field->idpartner, nPojOsn )
            ENDIF

            // ako je rijec o VP dokumentima, treba izracunati
            // ukupno sa PDV

            IF field->idtipdok $ "10#12"
               nPojUk := _uk_sa_pdv( field->idtipdok, field->idpartner, nPojUk )
            ENDIF

            // dodaj na total
            nOsn += nPojOsn
            nUkupno += nPojUk

            ++nCounter

            // ispisi progres u box-u
            IF nCounter % 50 == 0
               SET DEVICE TO SCREEN
               @ nMX, nMY SAY "obradjeno " + AllTrim( Str( nCounter ) ) + " zapisa"
               SET DEVICE TO PRINTER
            ENDIF

            SKIP 1
         ENDDO

         IF PRow() > 61
            FF
            fakt_zagl_specif_prodaje( cIdFirma, cIdRefer, , cOpcine30 )
         ENDIF

         select_o_roba( cIdRoba )
         SELECT fakt

         IF Round( nKolicina, 4 ) <> 0
            ? Space( gnLMarg )
            ?? Str( ++nC, 4 ) + ".", cIdRoba, Left( roba->naz, 40 )
            nCol1 := PCol() + 1
            @ PRow(), PCol() + 1 SAY Str( nKolicina, 12, 2 )

            IF cSvediJmj == "D"
               @ PRow(), PCol() + 1 SAY Str( nKolJmj, 12, 2 )
               nTKolJmj += nKolJmj
            ENDIF

            @ PRow(), PCol() + 1 SAY Str( nOsn, 12, 2 )
            @ PRow(), PCol() + 1 SAY Str( nUkupno, 12, 2 )

            nTKolicina += nKolicina
            nTOsn += nOsn
            nTUkupno += nUkupno
         ENDIF

         IF lExpRpt
            fill_exp_tbl( cIdRoba, Left( roba->naz, 40 ), nKolicina, nOsn, nUkupno )
         ENDIF

      ENDDO

      BoxC()

   ENDIF

   IF PRow() > 59
      FF
      fakt_zagl_specif_prodaje( cIdFirma, cIdRefer, , cOpcine30 )
   ENDIF

   ? Space( gnLMarg )
   ?? cLinija
   ? Space( gnLMarg )
   ?? " Ukupno"
   @ PRow(), nCol1 SAY Str( nTKolicina, 12, 2 )
   IF cSvediJmj == "D"
      @ PRow(), PCol() + 1 SAY Str( nTKolJmj, 12, 2 )
   ENDIF
   @ PRow(), PCol() + 1 SAY Str( nTOsn, 12, 2 )
   @ PRow(), PCol() + 1 SAY Str( nTUkupno, 12, 2 )
   ? Space( gnLMarg )
   ?? cLinija

   SET FILTER TO

   IF lExpRpt
      fill_exp_tbl( "UKUPNO", "", nTKolicina, nTOsn, nTUkupno )
   ENDIF

   FF
   ENDPRINT

   IF lExpRpt
      open_r_export_table()
   ENDIF

   RETURN .T.



STATIC FUNCTION fakt_zagl_specif_prodaje( cIdFirma, cIdRefer, cOpcine30 )

   ?
   P_12CPI

   ?? Space( gnLMarg )
   IspisFirme( cIdFirma )

   ?
   SET CENTURY ON

   P_12CPI

   IF cPrikaz == "1"
      ? Space( gnLMarg )
      ?? "Specifikacija prodaje po partnerima na dan", Date(), Space( 8 ), "Strana:", Str( ++nStrana, 3 )
   ELSE
      ? Space( gnLMarg )
      ?? "Specifikacija prodaje po artiklima na dan", Date(), Space( 8 ), "Strana:", Str( ++nStrana, 3 )
   ENDIF

   ? Space( gnLMarg )
   ?? "      za period:", dDatOd, " - ", dDatDo

   ? Space( gnLMarg )
   ?? "Izvjestaj za tipove dokumenata : ", Trim( qqTipDok )

   IF !Empty( cRelation )
      ? Space( gnLMarg )
      ?? "Relacija : " + cRelation
   ENDIF

   IF !Empty( cIdRefer )
      ? Space( gnLMarg )
      ?? "Referent : " + cIdRefer
   ENDIF

   IF cPrikaz == "2" .AND. !Empty( qqPartn )
      ? Space( gnLMarg )
      ?? "Partner: " + qqPartn + " - " + get_partner_naziv( qqPartn )
   ENDIF

   IF !Empty( cOpcine30 )
      ? Space( gnLMarg )
      ?? "Opcine: " + Trim( cOpcine30 )
   ENDIF

   IF lGroup .AND. !Empty( cPGroup )
      ? Space( gnLMarg )
      ?? "Grupa partnera: " + Trim( cPGroup ), " - " + gr_opis( cPGroup )
   ENDIF

   SET CENTURY OFF

   P_COND
   ? Space( gnLMarg )
   ?? cLinija

   IF cPrikaz == "1"
      ? Space( gnLMarg )
      ?? " Rbr  Sifra     Partner                  Kolicina                           "
   ELSE
      ? Space( gnLMarg )
      ?? " Rbr  Sifra      " + ;
         PadC( "Naziv", 40 ) + ;
         "   Kolicina   " + ;
         if( cSvediJmj == "D", "  Kol.po jmj ", "" ) + ;
         " Uk.bez PDV " + ;
         "  Uk.sa PDV "
   ENDIF

   ? Space( gnLMarg )
   ?? "                                                                            "
   ? Space( gnLMarg )
   ?? cLinija

   RETURN .T.


// ---------------------------------
// otvara potrebne tabele
// ---------------------------------
//STATIC FUNCTION _o_tables()

   // o_fakt_dbf()
   // o_fakt_doks_dbf()
   // o_partner()
   // o_valute()
   // o_rj()
   // o_sifk()
   // o_sifv()
   // o_roba()

//   RETURN .T.



// --------------------------------------------------
// vraca matricu sa definicijom polja exp.tabele
// --------------------------------------------------
STATIC FUNCTION get_rpt_fields()

   LOCAL aFields := {}

   AAdd( aFields, { "sifra", "C", 7, 0 } )
   AAdd( aFields, { "naziv", "C", 40, 0 } )
   AAdd( aFields, { "kolicina", "N", 15, 5 } )
   AAdd( aFields, { "osnovica", "N", 15, 5 } )
   AAdd( aFields, { "ukupno", "N", 15, 5 } )

   RETURN aFields


// -------------------------------------------
// filuje export tabelu sa podacima
// -------------------------------------------
STATIC FUNCTION fill_exp_tbl( cIdSif, cNazSif, nKol, nOsn, nUk )

   LOCAL nArr

   nArr := Select()

   o_r_export()
   APPEND BLANK
   REPLACE field->sifra WITH cIdSif
   REPLACE field->naziv WITH cNazSif
   REPLACE field->kolicina WITH nKol
   REPLACE field->osnovica WITH nOsn
   REPLACE field->ukupno WITH nUk

   SELECT ( nArr )

   RETURN .T.
