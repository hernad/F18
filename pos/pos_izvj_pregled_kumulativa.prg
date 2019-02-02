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

FUNCTION pos_kumulativ_prometa()

   LOCAL nSir := 80
   LOCAL nRobaSir := 40
   LOCAL cLm := Space( 5 )
   LOCAL cPicKol := "999999.999"

   START PRINT CRET

   nSir := 40
   nRobaSir := 18
   cLM := ""
   cPicKol := "9999.999"

   // ZagFirma()
   IF Empty( pos_doks->IdPos )
      ? PadC( "KUMULATIV PROMETA " + AllTrim( pos_doks->BrDok ), nSir )
   ELSE
      ? PadC( "KUMULATIV PROMETA " + AllTrim( pos_doks->IdPos ) + "-" + AllTrim( pos_doks->BrDok ), nSir )
   ENDIF

   ?
   ? PadC( FormDat1( pos_doks->Datum ), nSir )
   ?
   select_o_vrstep( pos_doks->IdVrsteP )


   cPom := Left( VRSTEP->Naz, 23 )

   ? cLM + "Vrsta placanja:", cPom
   select_o_partner( pos_doks->idPartner )

   cPom := Left( partn->Naz, 23 )
   ? cLM + "Gost / partner:", cPom

   IF pos_doks->Placen == PLAC_JEST .OR. pos_doks->IdVrsteP == gGotPlac
      ? cLM + "       Placeno:", "DA"
   ELSE
      ? cLM + "       Placeno:", "NE"
   ENDIF

   seek_pos_pos( pos_doks->IdPos, pos_doks->IdVd, pos_doks->datum, pos_doks->BrDok )

   ? cLM

   ?? "Sifra    Naziv              JMJ Kolicina"
   m := cLM + "-------- ------------------ --- --------"
   ? m

   nFin := 0
   SELECT POS

   DO WHILE !Eof() .AND. POS->( IdPos + IdVd + DToS( datum ) + BrDok ) == pos_doks->( IdPos + IdVd + DToS( datum ) + BrDok )
      ? cLM
      ?? IdRoba, ""
      select_o_roba( POS->IdRoba )
      ?? PadR( ROBA->Naz, nRobaSir ), ROBA->Jmj, ""
      SELECT POS
      ?? TRANS( POS->Kolicina, cPicKol )
      nFin += POS->( Kolicina * Cijena )
      SKIP
   ENDDO

   ? m
   ? cLM

   ?? PadL( "IZNOS DOKUMENTA (" + Trim( gDomValuta ) + ")", 10 + nRobaSir ), TRANS( nFin, "9,999,999.99" )
   ? m
   //PaperFeed()

   ENDPRINT
   SELECT pos_doks

   RETURN .T.
