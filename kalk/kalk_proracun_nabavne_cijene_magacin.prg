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

MEMVAR _idroba

/*
  Racuna nabavnu cijenu i stanje robe u magacinu
   1 - dDatDo datum do kojeg se obracunava
   2-4 cIdFirma, cIdRoba, cIdKonto,
  5) kolicina na stanju
  6) nKolZN - kolicina koja je na stanju od zadnje nabavke
  7) nNcZadnjaNabavka - zadnja nabavna cijena
  8) nSrednjaNabavnaCijena - srednja nabavna cijena

*/

FUNCTION kalk_get_nabavna_mag( dDatDo, cIdFirma, cIdRoba, cIdKonto, ;
      nKolicina, nKolZN, nNcZadnjaNabavka, nSrednjaNabavnaCijena, ;
      nNabavnaVrijednost, nSrednjaNcPoUlazima, lSilent )

   LOCAL nPom
   LOCAL nIzlNV
   LOCAL nIzlKol
   LOCAL nUlNV
   LOCAL nUlKol
   LOCAL nSkiniKol
   LOCAL nKolicinaAbs
   LOCAL nKol_poz := 0 // posljednje pozitivno stanje

   // LOCAL nUVr_poz, nIVr_poz
   // LOCAL nUKol_poz, nIKol_poz
   LOCAL nTmp
   LOCAL nTmp_n_stanje, nTmp_n_nv, nTmp_s_nv
   LOCAL cIdVd, nLen
   LOCAL nUlaziNV := 0, nUlaziKolicina := 0
   LOCAL lZadataNabavnaCijenaNabavka := .F.

   nKolicina := 0

   hb_default( @lSilent, .F. )
   IF Empty( kalk_metoda_nc() )  .OR. ( roba->tip $ "UT" )
      RETURN .F.
   ENDIF
/*
--   IF lAutoObr == .T.
      IF knab_cache( cIdKonto, cIdroba, @nUlKol, @nIzlKol, @nKolicina, @nUlNv, @nIzlNv, @nSrednjaNabavnaCijena ) == 1   // uzmi stanje iz cache tabele
         SELECT kalk_pripr
         RETURN .T.
      ENDIF
   ENDIF
*/
   MsgO( "Proračun stanja u magacinu: " + AllTrim( cIdKonto ) + "/" + cIdRoba )
   my_use_refresh_stop()


   find_kalk_by_mkonto_idroba( cIdFirma, cIdKonto, cIdRoba )
   GO BOTTOM

   IF ( cIdFirma + cIdKonto + cIdRoba ) == ( field->idfirma + field->mkonto + field->idroba ) ;
         .AND. dDatDo < field->datdok
      error_bar( "KA_" + cIdfirma + "/" + cIdKonto + "/" + cIdRoba, "Postoji dokument " + field->idfirma + "-" + field->idvd + "-" + field->brdok + " na datum: " + DToC( field->datdok ), 4 )
      // _ERROR := "1"
   ENDIF

   nLen := 1

   nKolicina := 0
   nIzlNV := 0  // ukupna izlazna nabavna vrijednost
   nUlNV := 0
   nIzlKol := 0 // ukupna izlazna kolicina
   nUlKol := 0 // ulazna kolicina

   IF ValType( nNcZadnjaNabavka ) != "N"
      nNcZadnjaNabavka := 0
   ENDIF
   IF ROUND( nNcZadnjaNabavka, 8 ) > 0   // kod ulazne kalkulacije prosljeđujemo zadnju nabavnu cijenu kao parametar
      lZadataNabavnaCijenaNabavka := .T.
   ENDIF

   nKolZN := 0
   nSrednjaNcPoUlazima := 0 // srednja nc gledajuci samo ulaze


   GO TOP
   DO WHILE !Eof() .AND. ( ( cIdFirma + cIdKonto + cIdRoba ) == ( field->idFirma + field->mkonto + field->idroba ) ) ;
         .AND. dDatDo >= field->datdok

      IF field->mu_i == "1" .OR. field->mu_i == "5"

         IF field->IdVd == "10"
            nKolicinaAbs := Abs( field->kolicina - field->gKolicina - field->gKolicin2 )
         ELSE
            nKolicinaAbs := Abs( field->kolicina )
         ENDIF

         IF ( field->mu_i == "1" .AND.  field->kolicina > 0 ) .OR. ( field->mu_i == "5" .AND. field->kolicina < 0 )

            nKolicina += nKolicinaAbs // ulazi plus, storno izlaza
            nUlKol    += nKolicinaAbs
            nUlNV     += ( nKolicinaAbs * field->nc )

            IF field->idvd $ "10#16" .AND. field->kolicina > 0 // zapamtiti uvijek zadnju ulaznu NC
               IF !lZadataNabavnaCijenaNabavka
                   nNcZadnjaNabavka := field->nc
               ENDIF
               nKolZn := field->kolicina
               nUlaziNV += field->nc * nKolicinaAbs
               nUlaziKolicina += nKolicinaAbs
            ENDIF

         ELSE

            nKolicina -= nKolicinaAbs
            nIzlKol   += nKolicinaAbs
            nIzlNV    += ( nKolicinaAbs * field->nc )

         ENDIF

/*
         IF Round( nKolicina, 8 ) > 0  // ako je kolicinsko stanje pozitivno zapamti ga
            nKol_poz := nKolicina
            nUKol_poz := nUlKol
            nIKol_poz := nIzlKol
            nUVr_poz := nUlNv
            nIVr_poz := nIzlNv
         ENDIF
*/

      ENDIF
      SKIP

   ENDDO

   nNabavnaVrijednost := nUlNv - nIzlNv

   IF Round( nUlaziKolicina, 4 ) <> 0
      nSrednjaNcPoUlazima := nUlaziNV / nUlaziKolicina
   ELSE
      nSrednjaNcPoUlazima := 0
   ENDIF

   // IF Round( nKol_poz, 8 ) == 0 // utvrdi srednju nabavnu cijenu na osnovu posljednjeg pozitivnog stanja
   IF Round( nKolicina, 4 ) == 0
      nSrednjaNabavnaCijena := 0
   ELSE
      // nSrednjaNabavnaCijena := ( nUVr_poz - nIVr_poz ) / nKol_poz // srednja nabavna cijena
      nSrednjaNabavnaCijena :=  nNabavnaVrijednost / nKolicina
      // IF nSrednjaNabavnaCijena < 0 // kartica je prolupala, srednja nabavna cijena negativna
      // nSrednjaNabavnaCijena := 0
      // ENDIF
   ENDIF

   nSrednjaNabavnaCijena := korekcija_nabavne_cijene_sa_zadnjom_ulaznom( nKolicina, nKolZN, nNcZadnjaNabavka, nSrednjaNabavnaCijena, lSilent )

   nKolicina := Round( nKolicina, 4 )
   nSrednjaNabavnaCijena := korekcija_nabavna_cijena_0( nSrednjaNabavnaCijena )

   IF Round( nSrednjaNabavnaCijena, 4 ) <= 0
      sumnjive_stavke_error()
   ENDIF

   SELECT kalk_pripr
   my_use_refresh_start()

   MsgC()

   RETURN .T.
