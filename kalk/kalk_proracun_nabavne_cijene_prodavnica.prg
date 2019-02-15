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

MEMVAR _datdok

FUNCTION kalk_get_nabavna_prod( cIdFirma, cIdroba, cIdkonto, nKolicina, nKolicinaPriZadnjojNabavci, ;
      nNcPriZadnjojNabavci, nSrednjaNabavnaCijena, ;
      nSrednjaNcPoUlazima, nNabavnaVrijednost, lSilent )

   LOCAL nPom
   LOCAL nIzlNV
   LOCAL nIzlKol
   LOCAL nUlNV
   LOCAL nUlKol
   LOCAL nSkiniKol
   LOCAL nTmp, nLen
   LOCAL nUlaziNV := 0, nUlaziKolicina := 0

   nKolicina := 0
   hb_default( @lSilent, .F. )

   IF Empty( kalk_metoda_nc() )
      RETURN .F.
   ENDIF

   MsgO( "Proračun stanja u prodavnici: " + AllTrim( cIdKonto ) + "/" + cIdRoba )
   find_kalk_by_pkonto_idroba( cIdFirma, cIdKonto, cIdRoba )
   GO BOTTOM
   IF cIdfirma + cIdkonto + cIdroba == kalk->idfirma + kalk->pkonto + kalk->idroba .AND. _datdok < kalk->datdok
      error_bar( "KA_" + cIdfirma + "-" + Trim( cIdkonto )  + "-" + Trim( cIdroba ), ;
         " KA_PROD " + Trim( cIdkonto ) + "-" + Trim( cIdroba ) + " postoje stavke na datum " + DToC( kalk->datdok ) )
      // _ERROR := "1"
   ENDIF

   nLen := 1
   nKolicina := 0
   nUlNV := 0
   nUlKol := 0 // ulazna kolicina
   nIzlNV := 0 // ukupna izlazna nabavna vrijednost
   nIzlKol := 0 // ukupna izlazna kolicina
   nNcPriZadnjojNabavci := 0
   nKolicinaPriZadnjojNabavci := 0

   GO TOP
   DO WHILE !Eof() .AND. cIdFirma + cIdKonto + cIdroba == kalk->idFirma + kalk->pkonto + kalk->idroba .AND. _datdok >= kalk->datdok

      IF kalk->pu_i == "1" .OR. kalk->pu_i == "5"
         IF ( kalk->pu_i == "1" .AND. kalk->kolicina > 0 ) .OR. ( kalk->pu_i == "5" .AND. kalk->kolicina < 0 )
            // ulazi i storno izlaza
            nKolicina += Abs( kalk->kolicina )
            nUlKol    += Abs( kalk->kolicina )
            nUlNV     += ( Abs( kalk->kolicina ) * kalk->nc )

            IF kalk->idvd $ "11#80#81" .AND. kalk->kolicina > 0
               nNcPriZadnjojNabavci := kalk->nc
               nKolicinaPriZadnjojNabavci := kalk->kolicina
               nUlaziNV += kalk->nc * kalk->kolicina
               nUlaziKolicina += kalk->kolicina
            ENDIF

         ELSE
            // ostalo su izlazi
            nKolicina -= Abs( kalk->kolicina )
            nIzlKol   += Abs( kalk->kolicina )
            nIzlNV    += ( Abs( kalk->kolicina ) * kalk->nc )
         ENDIF

      ELSEIF kalk->pu_i == "I"
         // IP dokument
         nKolicina -= kalk->gkolicin2
         nIzlKol += kalk->gkolicin2
         nIzlNV += kalk->nc * kalk->gkolicin2
      ENDIF
      SKIP

   ENDDO

   IF Round( nUlaziKolicina, 4 ) <> 0
      nSrednjaNcPoUlazima := nUlaziNV / nUlaziKolicina
   ELSE
      nSrednjaNcPoUlazima := 0
   ENDIF

   nNabavnaVrijednost :=  ( nUlNv - nIzlNv  )
   IF Round( nKolicina, 4 ) == 0
      nSrednjaNabavnaCijena := 0
   ELSE
      nSrednjaNabavnaCijena :=  nNabavnaVrijednost / nKolicina
   ENDIF
   nSrednjaNabavnaCijena := korekcija_nabavne_cijene_sa_zadnjom_ulaznom( nKolicina, nKolicinaPriZadnjojNabavci, nNcPriZadnjojNabavci, nSrednjaNabavnaCijena, lSilent )
   nKolicina := Round( nKolicina, 4 )
   nSrednjaNabavnaCijena := korekcija_nabavna_cijena_0( nSrednjaNabavnaCijena )

   IF Round( nSrednjaNabavnaCijena, 4 ) <= 0
      sumnjive_stavke_error()
   ENDIF

   SELECT kalk_pripr
   MsgC()

   RETURN .T.
