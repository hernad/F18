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

MEMVAR gIdRadnik, lTekuci, cPrikazPazarRoba, cIdRadnik, cVrsteP, cFilterVrstePlacanja, cIdPos, dDatOd, dDatDo

FUNCTION pos_realizacija_radnik
   PARAMETERS lTekuci, cPrikazPazarRoba

   LOCAL xPrintOpt, bZagl
   LOCAL aDbf
   LOCAL cNaslov
   LOCAL aNiz

   PRIVATE cIdRadnik := Space( 4 )
   PRIVATE cVrsteP := Space( 60 )
   PRIVATE cFilterVrstePlacanja := ".t."
   PRIVATE cIdPos := pos_prodajno_mjesto()

   PRIVATE dDatOd := danasnji_datum()
   PRIVATE dDatDo := danasnji_datum()

   cPrikazPazarRoba := iif ( cPrikazPazarRoba == NIL, "P", cPrikazPazarRoba )


   IF lTekuci
      cIdRadnik := gIdRadnik
      dDatOd := dDatDo := danasnji_datum()
   ELSE
      aNiz := {}
      cIdPos := gIdPos

      AAdd( aNiz, { "Prodajno mjesto (prazno-sve)", "cIdPos", "cIdPos='X' .or. empty(cIdPos) .or. p_pos_kase(@cIdPos)", "@!", } )
      AAdd( aNiz, { "Šifra radnika  (prazno-svi)", "cIdRadnik", "IF(!EMPTY(cIdRadnik),P_OSOB(@cIdRadnik),.t.)",, } )
      AAdd( aNiz, { "Vrsta placanja (prazno-sve)", "cVrsteP",, "@!S30", } )
      AAdd( aNiz, { "Izvještaj se pravi od datuma", "dDatOd",,, } )
      AAdd( aNiz, { "                   do datuma", "dDatDo",,, } )


      cPrikazPazarRoba := "O"
      AAdd( aNiz, { "Prikazi Pazar/Robe/Oboje (P/R/O)", "cPrikazPazarRoba", "cPrikazPazarRoba$'PRO'", "@!", } )
      DO WHILE .T.
         IF !VarEdit( aNiz, 10, 5, 13 + Len( aNiz ), 74, 'USLOVI ZA IZVJESTAJ "REALIZACIJA"', "B1" )
            CLOSERET
         ENDIF
         cFilterVrstePlacanja := Parsiraj( cVrsteP, "IdVrsteP" )
         IF cFilterVrstePlacanja <> NIL .AND. dDatOd <= dDatDo
            EXIT
         ELSEIF cFilterVrstePlacanja == NIL
            Msg( "Kriterij za vrstu placanja nije korektno postavljen!" )
         ELSE
            Msg( "'Datum do' ne smije biti stariji nego 'datum od'!" )
         ENDIF
      ENDDO
   ENDIF

   aDbf := {}
   AAdd ( aDbf, { "IdRadnik", "C",  4, 0 } )
   AAdd ( aDbf, { "IdVrsteP", "C",  2, 0 } )
   AAdd ( aDbf, { "IdRoba", "C", 10, 0 } )
   AAdd ( aDbf, { "Kolicina", "N", 15, 3 } )
   AAdd ( aDbf, { "Iznos",    "N", 20, 5 } )
   AAdd ( aDbf, { "Iznos2",   "N", 20, 5 } )
   AAdd ( aDbf, { "Iznos3",   "N", 20, 5 } )

   pos_cre_pom_dbf( aDbf )

   SELECT ( F_POM )
   IF Used()
      USE
   ENDIF

   my_use_temp( "POM", my_home() + "pom", .F., .T. )
   INDEX ON ( idradnik + idvrstep + idroba ) TAG "1"
   INDEX ON ( idroba ) TAG "2"

   SET ORDER TO TAG "1"

   s_oPDF := PDFClass():New()
   xPrintOpt := hb_Hash()
   xPrintOpt[ "tip" ] := "PDF"
   xPrintOpt[ "layout" ] := "portrait"
   xPrintOpt[ "opdf" ] := s_oPDF
   xPrintOpt[ "font_size" ] := 10

   cNaslov := "POS "
   IF lTekuci
      IF cPrikazPazarRoba $ "PO"
         cNaslov += "PAZAR RADNIKA"
      ELSE
         cNaslov += "REALIZACIJA RADNIKA PO ROBAMA"
      ENDIF
   ELSE
      IF glRetroakt
         cNaslov += "REALIZACIJA NA DAN " + FormDat1( dDatDo )
      ELSE
         cNaslov += "REALIZACIJA NA DAN " + FormDat1( danasnji_datum() )
      ENDIF
   ENDIF

   IF f18_start_print( NIL, xPrintOpt,  cNaslov ) == "X"
      RETURN .F.
   ENDIF

   IF lTekuci
      ? gIdRadnik, "-", AllTrim ( find_pos_osob_naziv( gIdRadnik ) ),  "   NA DAN: " + FormDat1 ( danasnji_datum() )
      ?
   ELSE
      ?U "PROD.MJESTO: " + cidpos + "-" + IF( Empty( cIdPos ), "SVA", find_pos_kasa_naz( cIdPos ) )
      ?U "RADNIK     : " + IF( Empty( cIdRadnik ), "svi", cIdRadnik + "-" + RTrim( find_pos_osob_naziv( cIdRadnik ) ) )
      ?U "VR.PLAĆANJA: " + IF( Empty( cVrsteP ), "sve", RTrim( cVrsteP ) )

      ?U "PERIOD     : " + FormDat1( dDatOd ) + " - " + FormDat1( dDatDo )
      ?
      ?U "ŠIFRA PREZIME I IME RADNIKA"
      ?U "-----", Replicate ( "-", 30 )
   ENDIF

   IF !lTekuci
      pos_radnik_izvuci ( VD_PRR )
   ENDIF
   pos_radnik_izvuci ( POS_IDVD_RACUN )

   SELECT pos_doks
   SET ORDER TO TAG "2"       // "DOKSi2", "IdVd+DTOS (Datum)"
   IF !( cFilterVrstePlacanja == ".t." )
      SET FILTER TO &cFilterVrstePlacanja
   ENDIF

   IF cPrikazPazarRoba $ "PO"
      nTotal := 0
      nTotal3 := 0
      SELECT POM
      SET ORDER TO TAG "1"
      GO TOP
      bZagl := {|| zagl_radnik() }
      Eval( bZagl )
      DO WHILE !Eof()

         check_nova_strana( bZagl, s_oPDF )
         _IdRadnik := POM->IdRadnik
         nTotRadn := 0
         nTotRadn3 := 0
         IF ! lTekuci
            ? _IdRadnik + "  " + PadR ( find_pos_osob_naziv( _IdRadnik ), 30 )
            ? Replicate ( "-", 40 )
            SELECT POM

         ENDIF

         nKolicO := 0    // kolicina za ostale
         nKolicPr := 0  // kolicina za premirane
         DO WHILE !Eof() .AND. POM->IdRadnik == _IdRadnik
            _IdVrsteP := POM->IdVrsteP
            nTotVP := 0
            nTotVP3 := 0
            DO WHILE !Eof() .AND. POM->( IdRadnik + IdVrsteP ) == ( _IdRadnik + _IdVrsteP )
               nTotVP += POM->Iznos
               nTotVP3 += pom->iznos3
               SKIP
            ENDDO

            select_o_vrstep( _IdVrsteP )
            ? Space ( 5 ) + PadR ( VRSTEP->Naz, 24 ), Str ( nTotVP, 10, 2 )

            nTotRadn += nTotVP
            nTotRadn3 += nTotVP3

            SELECT POM
         ENDDO

         ? Replicate ( "-", 40 )
         ? PadL ( "UKUPNO RADNIK (" + _idradnik + "):", 29 ), Str ( nTotRadn, 10, 2 )

         IF nTotRadn3 <> 0
            ? PadL ( NenapPop(), 29 ), Str ( nTotRadn3, 10, 2 )
            ? PadL ( "UKUPNO NAPLATA:", 29 ), Str ( nTotRadn - nTotRadn3 + nTotRadn2, 10, 2 )
         ENDIF
         ? Replicate ( "-", 40 )

         nTotal += nTotRadn
         nTotal3 += nTotRadn3
      ENDDO

      IF Empty ( cIdRadnik )
         ?
         ? Replicate ( "=", 40 )
         ? PadC ( "SVI RADNICI UKUPNO:", 25 ), Str ( nTotal, 14, 2 )
         IF nTotal3 <> 0
            ? PadL ( NenapPop(), 29 ), Str ( nTotal3, 10, 2 )
            ? PadL ( "UKUPNO NAPLATA:", 29 ), Str ( nTotal - nTotal3 + nTotal2, 10, 2 )
         ENDIF
         ? Replicate ( "=", 40 )
      ENDIF
   ENDIF

   IF cPrikazPazarRoba $ "RO"
      IF ! lTekuci
         ?
         ?
         ? PadC ( "REALIZACIJA PO ROBAMA", 40 )
      ENDIF

      bZagl := {|| zagl_roba() }
      Eval( bZagl )

      SELECT POM
      SET ORDER TO TAG "2"
      GO TOP
      nTotal := 0
      nTotal3 := 0
      DO WHILE !Eof()

         check_nova_strana( bZagl, s_oPDF )
         select_o_roba( POM->IdRoba )
         SELECT POM
         ?U POM->IdRoba + " "
         ??U PadR ( roba->Naz, 21 )

         _IdRoba := POM->IdRoba
         nRobaIzn := 0
         nRobaIzn3 := 0
         DO WHILE !Eof() .AND. POM->IdRoba == _IdRoba

            nIzn := 0
            nIzn3 := 0
            nKol := 0
            DO WHILE !Eof() .AND. POM->IdRoba == _IdRoba
               nKol += POM->Kolicina
               nIzn += POM->Iznos
               nIzn3 += POM->Iznos3
               SELECT POM
               SKIP
            ENDDO
            ? Str ( nKol, 12, 3 ), Str ( nIzn, 15, 2 )
            nTotal += nIzn
            nTotal3 += nIzn3
         ENDDO
      ENDDO
      ? REPL ( "=", 40 )
      ? PadL ( "U K U P N O", 24 ), Str ( nTotal, 15, 2 )
      IF nTotal3 <> 0
         ? PadL ( NenapPop(), 24 ), Str ( nTotal3, 15, 2 )
         ? PadL ( "UKUPNO NAPLATA:", 24 ), Str ( nTotal - nTotal3, 15, 2 )
      ENDIF
      ? REPL ( "=", 40 )
   ENDIF

   f18_end_print( NIL, xPrintOpt )
   my_close_all_dbf()

   RETURN .T.


STATIC FUNCTION zagl_radnik()

   LOCAL cLinija :=  REPL ( "-", 24 ) + " " + REPL ( "-", 10 )

   ?U Space( 5 ) + cLinija
   ?U Space( 5 ) + PadR ( "Vrsta plaćanja", 24 ), PadC( "Iznos", 10 )
   ?U Space( 5 ) + cLinija

   RETURN .T.

STATIC FUNCTION zagl_roba()

   LOCAL cLinija := REPL ( "-", 12 ) + " " + REPL ( "-", 15 )

   ?U
   ?U cLinija
   ?U PadR ( "Šifra", 10 ), PadR ( "Naziv robe", 21 )
   ?U PadC ( "Količina", 12 ), PadC ( "Iznos", 15 )
   ?U cLinija

   RETURN .T.


FUNCTION pos_close_dbfs_real_radnici()

   SELECT VRSTEP
   USE
   SELECT pos_doks
   USE
   SELECT POS
   USE
   SELECT POM
   USE

   RETURN .T.


FUNCTION pos_radnik_izvuci( cIdVd )

   seek_pos_doks_2( cIdVd, dDatOd )
   DO WHILE ! Eof() .AND. IdVd == cIdVd .AND. pos_doks->Datum <= dDatDo

      IF ( !pos_admin() .AND. pos_doks->idpos = "X" ) .OR. ( pos_doks->IdPos = "X" .AND. AllTrim ( cIdPos ) <> "X" ) .OR. ( !Empty( cIdPos ) .AND. pos_doks->IdPos <> cIdPos ) .OR. ( !Empty( cIdRadnik ) .AND. pos_doks->IdRadnik <> cIdRadnik )
         SKIP
         LOOP
      ENDIF

      _IdVrsteP := pos_doks->IdVrsteP
      _IdRadnik := pos_doks->IdRadnik


      seek_pos_pos( pos_doks->IdPos, pos_doks->IdVd, pos_doks->datum, pos_doks->BrDok )
      DO WHILE !Eof() .AND. POS->( IdPos + IdVd + DToS( datum ) + BrDok ) == pos_doks->( IdPos + IdVd + DToS( datum ) + BrDok )


         select_o_roba( pos->idroba )

         nNeplaca := 0
         nNeplaca += pos->( NCijena * kolicina )

         SELECT POM
         GO TOP
         HSEEK _IdRadnik + _IdVrsteP + POS->IdRoba

         IF !Found()
            APPEND BLANK
            REPLACE IdRadnik WITH _IdRadnik, IdVrsteP WITH _IdVrsteP, IdRoba WITH POS->IdRoba, Kolicina WITH POS->KOlicina, Iznos WITH POS->Kolicina * POS->Cijena, iznos3 WITH nNeplaca

         ELSE
            REPLACE Kolicina WITH Kolicina + POS->Kolicina, Iznos WITH Iznos + POS->Kolicina * POS->Cijena, iznos3 WITH iznos3 + nNeplaca
            // IF gPopVar = "A"
            // REPLACE Iznos2   WITH Iznos2 + pos->( ncijena )
            // ENDIF
         ENDIF
         SELECT POS
         SKIP
      ENDDO
      SELECT pos_doks
      SKIP
   ENDDO

   RETURN .T.
