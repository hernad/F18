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



FUNCTION ld_kartica_plate_autorski_honorar( cIdRj, nMjesec, nGodina, cIdRadn, cObrac, aNeta )

   LOCAL nKRedova
   LOCAL cDoprSpace := Space( 3 )
   LOCAL cTprLine
   LOCAL cDoprLine
   LOCAL cMainLine
   LOCAL _a_benef := {}
   PRIVATE cLMSK := ""

   cTprLine := _gtprline()
   cDoprLine := _gdoprline( cDoprSpace )
   cMainLine := _gmainline()

   // koliko redova ima kartica
   nKRedova := kart_redova()

   Eval( bZagl )

   cUneto := "D"
   nRRsati := 0
   nOsnNeto := 0
   nOsnOstalo := 0
   nLicOdbitak := ld->ulicodb
   nKoefOdbitka := radn->klo
   cRTipRada := get_ld_rj_tip_rada( ld->idradn, ld->idrj )

   FOR i := 1 TO cLDPolja

      cPom := PadL( AllTrim( Str( i ) ), 2, "0" )

      select_o_tippr( cPom )

      IF tippr->( FieldPos( "TPR_TIP" ) ) <> 0
         // uzmi osnovice
         IF tippr->tpr_tip == "N"
            nOsnNeto += _I&cPom
         ELSEIF tippr->tpr_tip == "2"
            nOsnOstalo += _I&cPom
         ELSEIF tippr->tpr_tip == " "
            // standardni tekuci sistem
            IF tippr->uneto == "D"
               nOsnNeto += _I&cPom
            ELSE
               nOsnOstalo += _I&cPom
            ENDIF
         ENDIF
      ELSE
         // standardni tekuci sistem
         IF tippr->uneto == "D"
            nOsnNeto += _I&cPom
         ELSE
            nOsnOstalo += _I&cPom
         ENDIF
      ENDIF

   NEXT

   select_o_por()
   select_o_dopr()

   SELECT ( F_KBENEF )

   IF !Used()
      o_koef_beneficiranog_radnog_staza()
   ENDIF

   nBO := 0
   nBFO := 0
   nBSaTr := 0
   nTrosk := 0

   nOsnZaBr := nOsnNeto

   nBo := ld_get_bruto_osnova( nOsnZaBr, cRTipRada, nLicOdbitak )

   IF is_radn_k4_bf_ide_u_benef_osnovu()
      _bn_osnova := ld_get_bruto_osnova( nOsnZaBr - if( !Empty( gBFForm ), &gBFForm, 0 ), cRTipRada, nLicOdbitak )
      _bn_stepen := BenefStepen()
      add_to_a_benef( @_a_benef, AllTrim( radn->k3 ), _bn_stepen, _bn_osnova )
   ENDIF


   nBSaTr := ( nBo * 1.2500 ) // izracunava bruto sa troskovima 30%
   // troskovi su
   nTrosk := nBSaTr * ( gAHTrosk / 100 )

   // bruto placa iz neta

   ? cMainLine
   ? cLMSK + "1. BRUTO SA TROSKOVIMA :  ", AllTrim( Str( nBo ) ) + " * 1.2500 ="

   @ PRow(), 60 + Len( cLMSK ) SAY nBSaTr PICT gpici

   ? cMainLine
   ? cLMSK + "2. TROSKOVI", AllTrim( Str( gAhTrosk ) ) + "% (1 * troskovi%) ="

   @ PRow(), 60 + Len( cLMSK ) SAY nTrosk PICT gpici

   ? cMainLine
   ? cLMSK + "3. BRUTO BEZ TROSKOVA :  ", ld_bruto_isplata_ispis( nOsnZaBr, cRTipRada, nLicOdbitak )

   @ PRow(), 60 + Len( cLMSK ) SAY nBo PICT gpici

   ? cMainLine

   ?

   // razrada doprinosa ....
   ? cLmSK + cDoprSpace + _l( "Obracun doprinosa:" )

   select_o_dopr()
   GO TOP

   nPom := 0
   nDopr := 0
   nUkDoprIz := 0
   nC1 := 20 + Len( cLMSK )

   DO WHILE !Eof()

      IF dopr->tiprada <> "A"
         SKIP
         LOOP
      ENDIF

      IF dopr->( FieldPos( "DOP_TIP" ) ) <> 0

         IF dopr->dop_tip == "N" .OR. dopr->dop_tip == " "
            nOsn := nOsnNeto
         ELSEIF dopr->dop_tip == "2"
            nOsn := nOsnOstalo
         ELSEIF dopr->dop_tip == "P"
            nOsn := nOsnNeto + nOsnOstalo
         ENDIF

      ENDIF

      PozicOps( DOPR->poopst )

      IF !ImaUOp( "DOPR", DOPR->id ) .OR. !lPrikSveDopr .AND. !DOPR->ID $ cPrikDopr
         SKIP 1
         LOOP
      ENDIF

      IF Right( id, 1 ) == "X"
         ? cDoprLine
      ENDIF

      ? cLMSK + cDoprSpace + id, "-", naz
      @ PRow(), PCol() + 1 SAY iznos PICT "99.99%"

      IF Empty( idkbenef )
         // doprinos udara na neto
         @ PRow(), PCol() + 1 SAY nBo PICT gpici
         nC1 := PCol() + 1
         @ PRow(), PCol() + 1 SAY nPom := Max( dlimit, Round( iznos / 100 * nBO, gZaok2 ) ) PICT gpici

         IF dopr->id == "1X"
            nUkDoprIz += nPom
         ENDIF

      ELSE
         nPom2 := get_benef_osnovica( _a_benef, idkbenef )
         IF Round( nPom2, gZaok2 ) <> 0
            @ PRow(), PCol() + 1 SAY nPom2 PICT gpici
            nC1 := PCol() + 1
            nPom := Max( dlimit, Round( iznos / 100 * nPom2, gZaok2 ) )
            @ PRow(), PCol() + 1 SAY nPom PICT gpici
         ENDIF
      ENDIF

      IF Right( id, 1 ) == "X"

         ? cDoprLine
         ?
         nDopr += nPom

      ENDIF

      IF !lSkrivena .AND. PRow() > 57 + dodatni_redovi_po_stranici()
         FF
      ENDIF

      SKIP 1

   ENDDO


   nOporDoh := nBo - nUkDoprIz

   // oporezivi dohodak ......

   ? cMainLine
   ?  cLMSK + _l( "4. NETO IZNOS NAKNADE ( bruto - dopr.IZ )" )
   @ PRow(), 60 + Len( cLMSK ) SAY nOporDoh PICT gpici

   ? cMainLine

   nPorOsnovica := ( nOporDoh )

   // ako je negativna onda je 0
   IF nPorOsnovica < 0
      nPorOsnovica := 0
   ENDIF

   // razrada poreza na platu ....
   // u ovom dijelu idu samo porezi na bruto TIP = "B"

   ? cLMSK + _l( "5. AKONTACIJA POREZA NA DOHODAK" )

   select_o_por()
   GO TOP

   nPom := 0
   nPor := 0
   nC1 := 30 + Len( cLMSK )
   nPorOl := 0

   DO WHILE !Eof()

      // vrati algoritam poreza
      cAlgoritam := get_algoritam()

      PozicOps( POR->poopst )

      IF !ImaUOp( "POR", POR->id )
         SKIP 1
         LOOP
      ENDIF

      // sracunaj samo poreze na bruto
      IF por->por_tip <> "B"
         SKIP
         LOOP
      ENDIF

      // obracunaj porez
      aPor := obr_por( por->id, nPorOsnovica, 0 )

      // ispisi porez
      nPor += isp_por( aPor, cAlgoritam, cLMSK, .T., .T. )

      SKIP 1
   ENDDO

   @ PRow(), 60 + Len( cLMSK ) SAY nPor PICT gpici

   // ukupno za isplatu ....
   nZaIsplatu := ( nOporDoh - nPor )

   ?

   ? cMainLine
   ?  cLMSK + _l( "UKUPNO ZA ISPLATU ( 4 - 5 )" )
   @ PRow(), 60 + Len( cLMSK ) SAY nZaIsplatu PICT gpici

   ? cMainLine

   IF !lSkrivena .AND. PRow() > 55 + dodatni_redovi_po_stranici()
      FF
   ENDIF

   ?

   // if prow()>31
   IF gPotp <> "D"
      IF PCount() == 0
         FF
      ENDIF
   ENDIF


   kart_potpis()

   // obrada sekvence za kraj papira

   // skrivena kartica
   IF lSkrivena
      IF PRow() < nKRSK + 5
         nPom := nKRSK - PRow()
         FOR i := 1 TO nPom
            ?
         NEXT
      ELSE
         FF
      ENDIF
      // 2 kartice na jedan list N - obavezno FF
   ELSEIF c2K1L == "N"
      FF
      // ako je prikaz bruto D obavezno FF
   ELSEIF gPrBruto == "D"
      FF
      // nova kartica novi list - obavezno FF
   ELSEIF lNKNS
      FF
      // druga kartica takodjer FF
   ELSEIF ( nRBRKart % 2 == 0 )
      FF
      // prva kartica, ali druga ne moze stati
   ELSEIF ( nRBRKart % 2 <> 0 ) .AND. ( DUZ_STRANA - PRow() < nKRedova )
      --nRBRKart
      FF
   ENDIF

   RETURN .T.
