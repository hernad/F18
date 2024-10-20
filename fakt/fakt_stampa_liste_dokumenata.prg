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

#define PARTNER_LEN 45

FUNCTION fakt_stampa_liste_dokumenata( dDatOd, dDatDo, qqTipDok, cIdFirma, cIdObjekat, cImeKup, cFilterOpcinaReferent, cValute )

   LOCAL m, cDinDnem, cRezerv, nC, nIznos, nRab, nIznosD, nIznos3, nRabD, nRab3, nOsn_tot, nPDV_tot, nUkPDV_tot
   LOCAL gnLMarg := 0
   LOCAL nCol1 := 0
   LOCAL hParams := fakt_params()
   LOCAL lVrstep := hParams[ "fakt_vrste_placanja" ]

   IF cValute == NIL
      cValute := Space( 3 )
   ENDIF

   START PRINT CRET
   ?

   P_COND

   ?? Space( gnLMarg )
   ??U "FAKT: Štampa dokumenata na dan:"
   ?? Date()
   ?? Space( 10 )
   ?? "za period", dDatOd, "-", dDatDo
   ?

   ? Space( gnLMarg )

   IspisFirme( cIdfirma )

   IF !Empty( qqTipDok )
      ?? Space( 2 ), "za tipove dokumenta:", Trim( qqTipDok )
   ENDIF

   IF !Empty( cValute )
      ?? Space( 2 ), "za valute:", cValute
   ENDIF

   IF hParams[ "fakt_objekti" ] .AND. !Empty( cIdObjekat )
      ?? Space( 2 ), "uslov po objektu: ", Trim( cIdObjekat )
      ? fakt_objekat_naz( cIdObjekat )
   ENDIF

   m := "----- -------- -- -- ---------"

   m += " " + Replicate( "-", PARTNER_LEN )

   m += " ------------ ------------ ------------ ------------ ------------ ------------ ---"

   IF FieldPos( "SIFRA" ) <> 0
      m += " --"
   ENDIF

   IF lVrsteP
      m += " -------"
   ENDIF

   IF FieldPos( "DATPL" ) <> 0
      m += " --------"
   ENDIF

   P_COND2
   ? Space( gnLMarg )
   ?? m
   ? Space( gnLMarg )

   ?? "  Rbr Dat.Dok  RJ TD Br.Dok   " +  PadC( "Partner", PARTNER_LEN ) + "   Ukupno       Rabat         UKUPNO     OSNOVICA       PDV       UK.SA PDV      VAL"

   IF FieldPos( "SIFRA" ) <> 0
      ?? " OP"
   ENDIF

   IF lVrsteP
      ??U " Nač.pl."
   ENDIF

   IF FieldPos( "DATPL" ) <> 0
      ?? " Dat.pl. "
   ENDIF

   ? Space( gnLMarg )
   ?? m

   nC       := 0
   // domaca valuta
   nIznos   := 0
   nRab     := 0
   // strana valuta
   nIznosD  := 0
   nRabD    := 0
   // ukupno domaca i strana
   nIznos3  := 0
   nRab3    := 0
   // domaca valuta
   nOsn_tot := 0
   nPdv_tot := 0
   nUkPDV_tot := 0
   // strana valuta
   nOsn_tot_s := 0
   nPdv_tot_s := 0
   nUkPDV_tot_s := 0

   cRezerv := " "

   cImeKup := Trim( cImeKup )

   DO WHILE !Eof()  // .AND. if( !Empty( cIdFirma ), IdFirma == cIdFirma, .T. )

      cDinDem := fakt_doks_pregled->dindem

      IF !Empty( AllTrim( cImekup ) )
         IF !( field->partner = AllTrim( cImeKup ) )
            SKIP
            LOOP
         ENDIF
      ENDIF

      select_o_partner( fakt_doks_pregled->idpartner )
      SELECT fakt_doks_pregled
      IF !( PARTN->( &cFilterOpcinaReferent ) )
         SKIP
         LOOP
      ENDIF

      SELECT fakt_doks_pregled
      ? Space( gnLMarg )

      ?? Str( ++nC, 4 ) + ".", datdok, idfirma, idtipdok, brdok + Rezerv + " "

      IF m1 <> "Z"
         ?? PadR( Trim( fakt_doks_pregled->idpartner ) + " - " + fakt_doks_pregled->partner, PARTNER_LEN )
      ELSE
         ?? PadC ( "<<dokument u pripremi>>", PARTNER_LEN )
      ENDIF

      nCol1 := PCol() + 1
      IF cDinDem == Left( ValBazna(), 3 )

         @ PRow(), PCol() + 1 SAY Str( iznos + rabat, 12, 2 )
         @ PRow(), PCol() + 1 SAY Str( Rabat, 12, 2 )
         @ PRow(), PCol() + 1 SAY Str( Round( iznos, gFZaok ), 12, 2 )

         // osnovica i pdv na prikazu
         @ PRow(), PCol() + 1 SAY Str( nOsn_izn := Round( _osnovica( idtipdok, idpartner, iznos ), gFZaok ),  12, 2 )
         @ PRow(), PCol() + 1 SAY Str( nPdv_izn := Round( _pdv( idtipdok, idpartner, iznos ), gFZaok ),  12, 2 )
         @ PRow(), PCol() + 1 SAY Str( nUkPdv_izn := Round( _uk_sa_pdv( idtipdok, idpartner, iznos ), gFZaok ), 12, 2 )

         nIznos     += Round( fakt_doks_pregled->iznos, gFZaok )
         nRab       += fakt_doks_pregled->rabat

         // iznos obje cValute... u KM
         nIznos3    += Round( fakt_doks_pregled->iznos,  gFZaok )
         nRab3      += fakt_doks_pregled->rabat
         nOsn_tot   += nOsn_izn
         nPdv_tot   += nPdv_izn
         nUkPDV_tot += nUkPDV_izn

      ELSE

         @ PRow(), PCol() + 1 SAY Str( ( fakt_doks_pregled->iznos / UBaznuValutu( fakt_doks_pregled->datdok ) ) + fakt_doks_pregled->rabat, 12, 2 )
         @ PRow(), PCol() + 1 SAY Str( fakt_doks_pregled->rabat, 12, 2 )
         @ PRow(), PCol() + 1 SAY Str( Round( fakt_doks_pregled->iznos / UBaznuValutu( fakt_doks_pregled->datdok ), gFZaok ), 12, 2 )

         // osnovica i pdv na prikazu
         @ PRow(), PCol() + 1 SAY Str( nOsn_izn := Round( _osnovica( idtipdok, idpartner, iznos / UBaznuValutu( datdok ) ), gFZaok ),  12, 2 )
         @ PRow(), PCol() + 1 SAY Str( nPDV_izn := Round( _pdv( idtipdok, idpartner, iznos / UBaznuValutu( datdok ) ), gFZaok ),  12, 2 )
         @ PRow(), PCol() + 1 SAY Str( nUkPdv_izn := Round( _uk_sa_pdv( idtipdok, idpartner, iznos / UBaznuValutu( datdok ) ), gFZaok ), 12, 2 )

         nIznosD   += Round( fakt_doks_pregled->iznos / UBaznuValutu( datdok ), gFZaok )
         nRabD     += fakt_doks_pregled->rabat

         // total obje Valute... ovu preracunaj u KM
         nIznos3   += Round( fakt_doks_pregled->iznos, gFZaok )
         nRab3     += fakt_doks_pregled->rabat

         nOsn_tot_s  += nOsn_izn
         nPdv_tot_s  += nPdv_izn
         nUkPdv_tot_s += nUkPdv_izn

      ENDIF

      @ PRow(), PCol() + 1 SAY cDinDEM

      IF FieldPos( "SIFRA" ) <> 0
         @ PRow(), PCol() + 1 SAY iif( Empty( fakt_doks_pregled->sifra ), Space( 2 ), Left( CryptSC( fakt_doks_pregled->sifra ), 2 ) )
      ENDIF

      IF lVrsteP
         select_o_vrstep( fakt_doks_pregled->idvrstep )
         @ PRow(), PCol() + 1 SAY fakt_doks_pregled->idvrstep + "-" + Left( VRSTEP->naz, 4 )
         SELECT fakt_doks_pregled
      ENDIF

      IF FieldPos( "DATPL" ) <> 0
         @ PRow(), PCol() + 1 SAY fakt_doks_pregled->datpl
      ENDIF

      SELECT fakt_doks_pregled
      SKIP

   ENDDO

   ? Space( gnLMarg )
   ?? m
   ? Space( gnLMarg )

   // domaca valuta
   ?? "UKUPNO " + ValBazna() + ":"
   @ PRow(), nCol1    SAY  Str( nIznos + nRab, 12, 2 )
   @ PRow(), PCol() + 1 SAY  Str( nRab, 12, 2 )
   @ PRow(), PCol() + 1 SAY  Str( nIznos, 12, 2 )
   @ PRow(), PCol() + 1 SAY  Str( nOsn_tot, 12, 2 )
   @ PRow(), PCol() + 1 SAY  Str( nPDV_tot, 12, 2 )
   @ PRow(), PCol() + 1 SAY  Str( nUkPDV_tot, 12, 2 )
   @ PRow(), PCol() + 1 SAY  Left( ValBazna(), 3 )

   ? Space( gnLMarg )
   ?? m
   ? Space( gnLMarg )

   // strana valuta
   ?? "UKUPNO " + ValSekund() + ":"
   @ PRow(), nCol1    SAY  Str( nIznosD + nRabD, 12, 2 )
   @ PRow(), PCol() + 1 SAY  Str( nRabD, 12, 2 )
   @ PRow(), PCol() + 1 SAY  Str( nIznosD, 12, 2 )
   @ PRow(), PCol() + 1 SAY  Str( nOsn_tot_s, 12, 2 )
   @ PRow(), PCol() + 1 SAY  Str( nPDV_tot_s, 12, 2 )
   @ PRow(), PCol() + 1 SAY  Str( nUkPDV_tot_s, 12, 2 )
   @ PRow(), PCol() + 1 SAY  Left( ValSekund(), 3 )

   ? Space( gnLMarg )
   ?? m
   ? Space( gnLMarg )
   ?? m
   ? Space( gnLMarg )

   ?? "UKUPNO " + AllTrim( valbazna() ) + " + " + AllTrim( valsekund() ) + ":"
   @ PRow(), nCol1    SAY  Str( nIznos3 + nRab3, 12, 2 )
   @ PRow(), PCol() + 1 SAY  Str( nRab3, 12, 2 )
   @ PRow(), PCol() + 1 SAY  Str( nIznos3, 12, 2 )
   @ PRow(), PCol() + 1 SAY  Left( VAlBazna(), 3 )

   ? Space( gnLMarg )
   ?? m

   FF
   ENDPRINT

   RETURN .T.
