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


STATIC DUZ_STRANA := 64


FUNCTION ld_kartica_plate_samostalni( cIdRj, nMjesec, nGodina, cIdRadn, cObrac, aNeta )

   LOCAL nKRedova
   LOCAL cDoprSpace := Space( 3 )
   LOCAL cTprLine
   LOCAL cDoprLine
   LOCAL cMainLine
   LOCAL _bn_stepen, _bn_osnova
   LOCAL _a_benef := {}
   PRIVATE cLDLijevaMargina := ""

   cTprLine := _gtprline()
   cDoprLine := _gdoprline( cDoprSpace )
   cMainLine := _gmainline()

   // koliko redova ima kartica
   nKRedova := ld_kartica_redova()

   Eval( bZagl )

   cUneto := "D"
   nRRsati := 0
   nOsnNeto := 0
   nOsnOstalo := 0
   // nLicOdbitak := g_licni_odb( radn->id )
   nLicOdbitak := ld->ulicodb
   nKoefOdbitka := radn->klo
   cRTipRada := get_ld_rj_tip_rada( ld->idradn, ld->idrj )
   nRPrKoef := 0
   IF radn->( FieldPos( "SP_KOEF" ) ) <> 0
      nRPrKoef := radn->sp_koef // propisani koeficijent samostalni poduzetnici
   ENDIF

   FOR i := 1 TO cLDPolja

      cPom := PadL( AllTrim( Str( i ) ), 2, "0" )

      select_o_tippr( cPom )
      IF tippr->( Found() ) .AND. tippr->aktivan == "D"

         IF _I&cpom <> 0 .OR. _S&cPom <> 0

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


            IF "SUMKREDITA" $ tippr->formula

               //SELECT radkr
               //SET ORDER TO 1
               //SEEK Str( _godina, 4 ) + Str( _mjesec, 2 ) + _idradn
               seek_radkr( _godina, _mjesec, _idradn )

               ukredita := 0


               DO WHILE !Eof() .AND. _godina == godina .AND. _mjesec = mjesec .AND. idradn == _idradn
                  select_o_kred( radkr->idkred )
                  SELECT radkr
                  aIznosi := ld_iznosi_za_kredit( idradn, idkred, naosnovu, _mjesec, _godina )
                  ukredita += iznos
                  SKIP 1
               ENDDO

               SELECT ld
            ENDIF
         ENDIF
      ENDIF
   NEXT

   IF gPrBruto == "D"


      SELECT ( F_POR ) // prikaz bruto iznosa

      IF !Used()
         o_por()
      ENDIF

      SELECT ( F_DOPR )

      IF !Used()
         o_dopr()
      ENDIF

      SELECT ( F_KBENEF )

      IF !Used()
         o_koef_beneficiranog_radnog_staza()
      ENDIF

      nBO := 0
      nBFO := 0

      nOsnZaBr := nOsnNeto

      nBo := ld_get_bruto_osnova( nOsnZaBr, cRTipRada, nLicOdbitak, nRPrKoef )

      IF is_radn_k4_bf_ide_u_benef_osnovu()
         _bn_osnova := ld_get_bruto_osnova( nOsnZaBr - if( !Empty( gBFForm ), &gBFForm, 0 ), cRTipRada, nLicOdbitak, nRPrKoef )
         _bn_stepen := ld_beneficirani_stepen()
         add_to_a_benef( @_a_benef, AllTrim( radn->k3 ), _bn_stepen, _bn_osnova )
      ENDIF

      ? cMainLine
      ? cLDLijevaMargina + "1. OSNOVA ZA OBRACUN:"

      @ PRow(), 60 + Len( cLDLijevaMargina ) SAY nOsnZaBr PICT gPici

      ? cMainLine
      ? cLDLijevaMargina + "2. PROPISANI KOEFICIJENT:"

      @ PRow(), 60 + Len( cLDLijevaMargina ) SAY nRPrKoef PICT gpici

      ? cMainLine
      ? cLDLijevaMargina + "3. BRUTO OSNOVA :  ", ld_bruto_isplata_ispis( nOsnZaBr, cRTipRada, nLicOdbitak, nRPrKoef )

      @ PRow(), 60 + Len( cLDLijevaMargina ) SAY nBo PICT gpici

      ? cMainLine

      // razrada doprinosa

      ? cLDLijevaMargina + cDoprSpace +  "Obracun doprinosa:"

      select_o_dopr()
      GO TOP

      nPom := 0
      nDopr := 0
      nUkDoprIz := 0
      nC1 := 20 + Len( cLDLijevaMargina )

      DO WHILE !Eof()

         IF dopr->tiprada <> "S"
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

         ld_opstina_stanovanja_rada( DOPR->poopst )

         IF !ld_ima_u_ops_porez_ili_doprinos( "DOPR", DOPR->id ) .OR. !lPrikSveDopr .AND. !DOPR->ID $ cPrikDopr
            SKIP 1
            LOOP
         ENDIF

         IF Right( id, 1 ) == "X"
            ? cDoprLine
         ENDIF

         ? cLDLijevaMargina + cDoprSpace + id, "-", naz
         @ PRow(), PCol() + 1 SAY iznos PICT "99.99%"

         IF Empty( idkbenef )

            @ PRow(), PCol() + 1 SAY nBo PICT gpici // doprinos udara na neto
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

      ? cMainLine
      ?  cLDLijevaMargina +  "UKUPNO ZA ISPLATU"
      @ PRow(), 60 + Len( cLDLijevaMargina ) SAY nOsnZaBr PICT gpici

      ? cMainLine

      IF !lSkrivena .AND. PRow() > 55 + dodatni_redovi_po_stranici()
         FF
      ENDIF

   ENDIF

   // potpis na kartici
   ld_kartica_potpis()

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
