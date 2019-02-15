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
  5) kolicina na stanju - mijenja se, parametar koji se prosljeđuje po referenci
  6) nKolicinaPriZadnjojNabavci - kolicina koja je na stanju od zadnje nabavke
  7) nNcZadnjaNabavka - zadnja nabavna cijena
  8) nSrednjaNabavnaCijena - srednja nabavna cijena

*/
FUNCTION kalk_get_nabavna_mag( dDatDo, cIdFirma, cIdRoba, cIdKonto, ;
      nKolicina, nKolicinaPriZadnjojNabavci, nNcZadnjaNabavka, nSrednjaNabavnaCijena, ;
      nNabavnaVrijednost, nSrednjaNcPoUlazima, lSilent )

   LOCAL nPom
   LOCAL nIzlNV
   LOCAL nIzlKol
   LOCAL nUlNV
   LOCAL nUlKol
   LOCAL nSkiniKol
   LOCAL nKolicinaAbs

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

   MsgO( "Proračun stanja u magacinu: " + AllTrim( cIdKonto ) + "/" + cIdRoba )
   my_use_refresh_stop()

   find_kalk_by_mkonto_idroba( cIdFirma, cIdKonto, cIdRoba )
   GO BOTTOM

   IF ( cIdFirma + cIdKonto + cIdRoba ) == ( kalk->idfirma + kalk->mkonto + kalk->idroba ) ;
         .AND. dDatDo < kalk->datdok
      error_bar( "KA_" + cIdfirma + "/" + cIdKonto + "/" + cIdRoba, "Postoji dokument " + kalk->idfirma + "-" + kalk->idvd + "-" + kalk->brdok + " na datum: " + DToC( kalk->datdok ), 4 )
   ENDIF

   nLen := 1
   nKolicina := 0
   nIzlNV := 0
   nUlNV := 0
   nIzlKol := 0
   nUlKol := 0

   IF ValType( nNcZadnjaNabavka ) != "N"
      nNcZadnjaNabavka := 0
   ENDIF
   IF Round( nNcZadnjaNabavka, 8 ) > 0   // kod ulazne kalkulacije prosljeđujemo zadnju nabavnu cijenu kao parametar
      lZadataNabavnaCijenaNabavka := .T.
   ENDIF

   nKolicinaPriZadnjojNabavci := 0
   nSrednjaNcPoUlazima := 0 // srednja nc gledajuci samo ulaze

   GO TOP
   DO WHILE !Eof() .AND. cIdFirma + cIdKonto + cIdRoba == kalk->idFirma + kalk->mkonto + kalk->idroba ;
         .AND. dDatDo >= kalk->datdok

      IF !( kalk->mu_i $ "1#5" )
         SKIP
         LOOP
      ENDIF

      nKolicinaAbs := Abs( kalk->kolicina )
      IF ( kalk->mu_i == "1" .AND.  kalk->kolicina > 0 ) .OR. ( kalk->mu_i == "5" .AND. kalk->kolicina < 0 )
         // ulazi i storno izlaza
         nKolicina += nKolicinaAbs
         nUlKol    += nKolicinaAbs
         nUlNV     += ( nKolicinaAbs * kalk->nc )
         IF kalk->idvd $ "10#16" .AND. kalk->kolicina > 0
            // zapamtiti zadnju ulaznu NC svakog prijema u magacin od dobavljača ili po direktnom prijemu
            IF !lZadataNabavnaCijenaNabavka
               nNcZadnjaNabavka := kalk->nc
            ENDIF
            nKolicinaPriZadnjojNabavci := kalk->kolicina
            nUlaziNV += kalk->nc * nKolicinaAbs
            nUlaziKolicina += nKolicinaAbs
         ENDIF
      ELSE
         // sve ostalo su izlazi
         nKolicina -= nKolicinaAbs
         nIzlKol   += nKolicinaAbs
         nIzlNV    += ( nKolicinaAbs * kalk->nc )
      ENDIF

      SKIP

   ENDDO

   nNabavnaVrijednost := nUlNv - nIzlNv
   IF Round( nUlaziKolicina, 4 ) <> 0
      nSrednjaNcPoUlazima := nUlaziNV / nUlaziKolicina
   ELSE
      nSrednjaNcPoUlazima := 0
   ENDIF

   IF Round( nKolicina, 4 ) == 0
      nSrednjaNabavnaCijena := 0
   ELSE
      nSrednjaNabavnaCijena :=  nNabavnaVrijednost / nKolicina
   ENDIF

   nSrednjaNabavnaCijena := korekcija_nabavne_cijene_sa_zadnjom_ulaznom( nKolicina, nKolicinaPriZadnjojNabavci, nNcZadnjaNabavka, nSrednjaNabavnaCijena, lSilent )

   nKolicina := Round( nKolicina, 4 )
   nSrednjaNabavnaCijena := korekcija_nabavna_cijena_0( nSrednjaNabavnaCijena )

   IF Round( nSrednjaNabavnaCijena, 4 ) <= 0
      sumnjive_stavke_error()
   ENDIF

   SELECT kalk_pripr
   my_use_refresh_start()

   MsgC()

   RETURN .T.
