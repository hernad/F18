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

FUNCTION pos_realizacija_radnik

   PARAMETERS lTekuci, fPrik, fZaklj

   PRIVATE cIdRadnik := Space( 4 )
   PRIVATE cVrsteP := Space( 60 )
   PRIVATE cFilterVrstePlacanja := ".t."
   PRIVATE cSmjena := Space( 1 )
   PRIVATE cIdPos := pos_prodajno_mjesto()

   // PRIVATE cIdDio := gIdDio
   PRIVATE dDatOd := gDatum
   PRIVATE dDatDo := gDatum
   PRIVATE aNiz
   PRIVATE cGotZir := " "

   //o_tables()

   fPrik := iif ( fPrik == NIL, "P", fPrik )
   fZaklj := iif ( fZaklj == NIL, .F., fZaklj )

   PRIVATE fPrikPrem := "N"

   fPrikPrem := "D"


   IF lTekuci
      cIdRadnik := gIdRadnik
      IF gRadniRac == "D"
         cSmjena   := ""
         // ako radnik prelazi u narednu smjenu
      ELSE
         cSmjena := gSmjena
      ENDIF
      dDatOd := dDatDo := gDatum
   ELSE
      aNiz := {}
      cIdPos := gIdPos

      AAdd( aNiz, { "Prodajno mjesto (prazno-sve)", "cIdPos", "cIdPos='X' .or. empty(cIdPos) .or. p_pos_kase(@cIdPos)", "@!", } )
      AAdd( aNiz, { "Sifra radnika  (prazno-svi)", "cIdRadnik", "IF(!EMPTY(cIdRadnik),P_OSOB(@cIdRadnik),.t.)",, } )
      AAdd( aNiz, { "Vrsta placanja (prazno-sve)", "cVrsteP",, "@!S30", } )
      AAdd( aNiz, { "Smjena (prazno-sve)", "cSmjena",,, } )
      AAdd( aNiz, { "Izvjestaj se pravi od datuma", "dDatOd",,, } )
      AAdd( aNiz, { "                   do datuma", "dDatDo",,, } )
      IF fPrikPrem == "D"
         AAdd( aNiz, { "Prikaz kolicina za premirane artikle ", "fPrikPrem", "fprikPrem$'DN'", "@!", } )
      ENDIF


      fPrik := "O"
      AAdd( aNiz, { "Prikazi Pazar/Robe/Oboje (P/R/O)", "fPrik", "fPrik$'PRO'", "@!", } )
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
   AAdd ( aDbf, { "IdCijena", "C",  1, 0 } )
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
   INDEX ON ( idradnik + idvrstep + idroba + idcijena ) TAG "1"
   INDEX ON ( idroba + idcijena ) TAG "2"

   SET ORDER TO TAG "1"

   o_tables()

   IF lTekuci
      IF fZaklj
         STARTPRINTPORT CRET gLocPort, .F.
      ELSE
         STARTPRINT CRET
      ENDIF

      //ZagFirma()

      ?
      IF fPrik $ "PO"
         ?? PadC ( iif ( fZaklj, "ZAKLJUCENJE", "PAZAR" ) + " RADNIKA", 40 )
      ELSE
         ?? PadC ( "REALIZACIJA RADNIKA PO ROBAMA", 40 )
      ENDIF
      ? PadC ( gPosNaz )
      ?

      ? gIdRadnik, "-", PadC ( AllTrim ( find_pos_osob_naziv( gIdRadnik ) ), 40 )
      cTxt := "Na dan: " + FormDat1 ( gDatum )
      IF gRadniRac == "N"
         cTxt += " u smjeni " + gSmjena
      ENDIF
      ? PadC ( cTxt, 40 )
      ?
   ELSE
      START PRINT CRET
      //ZagFirma()
      ?? gP12cpi
      ?
      IF glRetroakt
         ? PadC( "REALIZACIJA NA DAN " + FormDat1( dDatDo ), 40 )
      ELSE
         ? PadC( "REALIZACIJA NA DAN " + FormDat1( gDatum ), 40 )
      ENDIF
      ? PadC( "-------------------------------------", 40 )
      ? "PROD.MJESTO: " + cidpos + "-" + IF( Empty( cIdPos ), "SVA", find_pos_kasa_naz( cIdPos ) )
      ? "RADNIK     : " + IF( Empty( cIdRadnik ), "svi", cIdRadnik + "-" + RTrim( find_pos_osob_naziv( cIdRadnik ) ) )
      ? "VR.PLACANJA: " + IF( Empty( cVrsteP ), "sve", RTrim( cVrsteP ) )
      IF ! Empty ( cSmjena )
         ? "SMJENA     : " + RTrim( cSmjena )
      ENDIF


      ? "PERIOD     : " + FormDat1( dDatOd ) + " - " + FormDat1( dDatDo )
      ?
      ? "SIFRA PREZIME I IME RADNIKA"
      ? "-----", Replicate ( "-", 30 )
   ENDIF // lTekuci

   // formiram pomocnu datoteku sa podacima o realizaciji
   IF !lTekuci
      pos_radnik_izvuci ( VD_PRR )
   ENDIF
   pos_radnik_izvuci ( POS_VD_RACUN )


   SELECT pos_doks
   SET ORDER TO TAG "2"       // "DOKSi2", "IdVd+DTOS (Datum)+Smjena"
   IF !( cFilterVrstePlacanja == ".t." )
      SET FILTER TO &cFilterVrstePlacanja
   ENDIF

   // ispis izvjestaja
   IF fPrik $ "PO"
      nTotal := 0
    //  nTotal2 := 0
      nTotal3 := 0
      SELECT POM
      SET ORDER TO TAG "1"
      GO TOP
      DO WHILE !Eof()
         _IdRadnik := POM->IdRadnik
         nTotRadn := 0
      //   nTotRadn2 := 0
         nTotRadn3 := 0
         IF ! lTekuci
            ? _IdRadnik + "  " + PadR ( find_pos_osob_naziv( _IdRadnik ), 30 )
            ? Replicate ( "-", 40 )
            SELECT POM
         ELSE
            ? Space ( 5 ) + PadR ( "Vrsta placanja", 24 ), PadC( "Iznos", 10 )
            ? Space ( 5 ) + REPL ( "-", 24 ), REPL ( "-", 10 )
         ENDIF

         nKolicO := 0    // kolicina za ostale
         nKolicPr := 0  // kolicina za premirane
         DO WHILE !Eof() .AND. POM->IdRadnik == _IdRadnik
            _IdVrsteP := POM->IdVrsteP
            nTotVP := 0
        //    nTotVP2 := 0
            nTotVP3 := 0
            DO WHILE !Eof() .AND. POM->( IdRadnik + IdVrsteP ) == ( _IdRadnik + _IdVrsteP )
               nTotVP += POM->Iznos
          //     nTotVP2 += pom->iznos2
               nTotVP3 += pom->iznos3

               IF fPrikPrem == "D"
                  select_o_roba( pom->idroba )
                  SELECT pom
                  IF !( roba->k2 = 'X' )
                     IF roba->k7 = '*'
                        nKolicPr += pom->kolicina
                     ELSE
                        nKolicO += pom->kolicina
                     ENDIF
                  ENDIF
               ENDIF // fPrikPrem=="D"
               SKIP
            ENDDO

            select_o_vrstep( _IdVrsteP )
            ? Space ( 5 ) + PadR ( VRSTEP->Naz, 24 ), Str ( nTotVP, 10, 2 )

            nTotRadn += nTotVP
        //    nTotRadn2 += nTotVP2
            nTotRadn3 += nTotVP3

            SELECT POM
         ENDDO

         ? Replicate ( "-", 40 )
         IF fPrikPrem == "D"
            ?
            ?  PadL( "Kolicina - k7='*' ", 29, "." ), Str( nKolicPr, 10, 2 )
            ?  PadL( "Kolicina - ostali artikli", 29, ), Str( nKolicO, 10, 2 )
            ?
         ENDIF

         ? PadL ( "UKUPNO RADNIK (" + _idradnik + "):", 29 ), Str ( nTotRadn, 10, 2 )

         IF nTotRadn3 <> 0
            ? PadL ( NenapPop(), 29 ), Str ( nTotRadn3, 10, 2 )
            ? PadL ( "UKUPNO NAPLATA:", 29 ), Str ( nTotRadn - nTotRadn3 + nTotRadn2, 10, 2 )
         ENDIF
         ? Replicate ( "-", 40 )

         nTotal += nTotRadn
      //   nTotal2 += nTotRadn2
         nTotal3 += nTotRadn3
      ENDDO

      IF Empty ( cIdRadnik )
         ?
         ? Replicate ( "=", 40 )
         ? PadC ( "SVI RADNICI UKUPNO:", 25 ), Str ( nTotal, 14, 2 )
         IF nTotal2 <> 0
            ? PadL ( "PARTICIPACIJA:", 29 ), Str ( nTotal2, 10, 2 )
         ENDIF
         IF nTotal3 <> 0
            ? PadL ( NenapPop(), 29 ), Str ( nTotal3, 10, 2 )
            ? PadL ( "UKUPNO NAPLATA:", 29 ), Str ( nTotal - nTotal3 + nTotal2, 10, 2 )
         ENDIF
         ? Replicate ( "=", 40 )
      ENDIF
   ENDIF

   IF fPrik $ "RO"
      IF ! lTekuci
         ?
         ?
         ? PadC ( "REALIZACIJA PO ROBAMA", 40 )
      ENDIF
      ?
      ? PadR ( "Sifra", 10 ), PadR ( "Naziv robe", 21 )
      ? PadL ( "Set c.", 11 ), PadC ( "Kolicina", 12 ), PadC ( "Iznos", 15 )
      ? REPL ( "-", 11 ), REPL ( "-", 12 ), REPL ( "-", 15 )
      SELECT POM
      SET ORDER TO TAG "2"
      GO TOP
      nTotal := 0
    //  nTotal2 := 0
      nTotal3 := 0
      DO WHILE !Eof()
         select_o_roba( POM->IdRoba )
         SELECT POM
         ? POM->IdRoba + " "
         IF roba->( FieldPos( "K7" ) ) <> 0
            ?? PadR ( roba->Naz, 23 ) + roba->k7
         ELSE
            ?? PadR ( roba->Naz, 21 )
         ENDIF
         _IdRoba := POM->IdRoba
         nRobaIzn := 0
        // nRobaIzn2 := 0
         nRobaIzn3 := 0
         DO WHILE !Eof() .AND. POM->IdRoba == _IdRoba
            _IdCijena := POM->IdCijena
            nIzn := 0
          //  nIzn2 := 0
            nIzn3 := 0
            nKol := 0
            DO WHILE !Eof() .AND. POM->( IdRoba + IdCijena ) == ( _IdRoba + _IdCijena )
               nKol += POM->Kolicina
               nIzn += POM->Iznos
            //   nIzn2 += POM->Iznos2
               nIzn3 += POM->Iznos3
               SELECT POM
               SKIP
            ENDDO
            ? PadL ( _IdCijena, 11 ), Str ( nKol, 12, 3 ), Str ( nIzn, 15, 2 )
            nTotal += nIzn
          //  nTotal2 += nIzn2
            nTotal3 += nIzn3
         ENDDO
      ENDDO
      ? REPL ( "=", 40 )
      ? PadL ( "U K U P N O", 24 ), Str ( nTotal, 15, 2 )
      //IF nTotal2 <> 0
      //   ? PadL ( "PARTICIPACIJA:", 24 ), Str ( nTotal2, 15, 2 )
      //ENDIF
      IF nTotal3 <> 0
         ? PadL ( NenapPop(), 24 ), Str ( nTotal3, 15, 2 )
         ? PadL ( "UKUPNO NAPLATA:", 24 ), Str ( nTotal - nTotal3 + nTotal2, 15, 2 )
      ENDIF
      ? REPL ( "=", 40 )
   ENDIF
   IF lTekuci
      //PaperFeed()
      IF fZaklj
         ENDPRN2
      ELSE
         ENDPRINT
      ENDIF
   ELSE
      ENDPRINT
   ENDIF

   IF fZaklj
      pos_close_dbfs_real_radnici()
   ELSE
      CLOSE ALL
   ENDIF

   RETURN .T.


FUNCTION pos_close_dbfs_real_radnici()

   SELECT DIO
   USE
   // SELECT KASE
   // USE
   // SELECT roba
   // USE
   SELECT VRSTEP
   USE
   SELECT pos_doks
   USE
   SELECT POS
   USE
   SELECT POM
   USE

   RETURN .T.


/* pos_radnik_izvuci(cIdVd)
 *     Punjenje pomocne baze realizacijom po radnicima
 */

FUNCTION pos_radnik_izvuci( cIdVd )

   //SEEK cIdVd + DToS ( dDatOd )
   seek_pos_doks_2( cIdVd, dDatOd )
   DO WHILE ! Eof() .AND. IdVd == cIdVd .AND. pos_doks->Datum <= dDatDo

      IF ( !pos_admin() .AND. pos_doks->idpos = "X" ) .OR. ( pos_doks->IdPos = "X" .AND. AllTrim ( cIdPos ) <> "X" ) .OR. ( !Empty( cIdPos ) .AND. pos_doks->IdPos <> cIdPos ) .OR. ( !Empty( cSmjena ) .AND. pos_doks->Smjena <> cSmjena ) .OR. ( !Empty( cIdRadnik ) .AND. pos_doks->IdRadnik <> cIdRadnik )
         SKIP
         LOOP
      ENDIF

      _IdVrsteP := pos_doks->IdVrsteP
      _IdRadnik := pos_doks->IdRadnik


      seek_pos_pos( pos_doks->IdPos, pos_doks->IdVd, pos_doks->datum, pos_doks->BrDok )
      DO WHILE !Eof() .AND. POS->( IdPos + IdVd + DToS( datum ) + BrDok ) == pos_doks->( IdPos + IdVd + DToS( datum ) + BrDok )

         // IF ( !Empty( cIdDio ) .AND. POS->IdDio <> cIdDio )
         // SKIP
         // LOOP
         // ENDIF

         select_o_roba( pos->idroba )

         IF roba->( FieldPos( "idodj" ) ) <> 0
            //SELECT odj
            select_o_pos_odj( roba->idodj )
         ENDIF

         nNeplaca := 0

        // IF Right( odj->naz, 5 ) == "#1#0#"  // proba!!!
        //    nNeplaca := pos->( Kolicina * Cijena )
        // ELSEIF Right( odj->naz, 6 ) == "#1#50#"
        //    nNeplaca := pos->( Kolicina * Cijena ) / 2
        // ENDIF
         //IF gPopVar = "P"
            nNeplaca += pos->( NCijena * kolicina )
         //ENDIF

         SELECT POM
         GO TOP
         HSEEK _IdRadnik + _IdVrsteP + POS->IdRoba + POS->IdCijena // POM

         IF !Found()
            APPEND BLANK
            REPLACE IdRadnik WITH _IdRadnik, IdVrsteP WITH _IdVrsteP, IdRoba WITH POS->IdRoba, IdCijena WITH POS->IdCijena, Kolicina WITH POS->KOlicina, Iznos WITH POS->Kolicina * POS->Cijena, iznos3 WITH nNeplaca
            //IF gPopVar = "A"
            //   REPLACE Iznos2   WITH pos->( ncijena )
            //ENDIF
         ELSE
            REPLACE Kolicina WITH Kolicina + POS->Kolicina, Iznos WITH Iznos + POS->Kolicina * POS->Cijena, iznos3 WITH iznos3 + nNeplaca
            //IF gPopVar = "A"
            //   REPLACE Iznos2   WITH Iznos2 + pos->( ncijena )
            //ENDIF
         ENDIF
         SELECT POS
         SKIP
      ENDDO
      SELECT pos_doks
      SKIP
   ENDDO

   RETURN .T.



STATIC FUNCTION o_tables()

   // o_sifk()
   // o_sifv()
   // o_pos_kase()
   //o_pos_odj()
   // o_roba()
   // o_pos_osob()
   //SET ORDER TO TAG "NAZ"
   //o_vrstep()
   //o_pos_pos()
   //o_pos_doks()

   RETURN .T.
