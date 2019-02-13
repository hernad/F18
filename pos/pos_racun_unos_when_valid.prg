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

#define POS_ROBA_DUZINA_SIFRE 13  // citanje barkoda

STATIC s_nMaxKolicinaPosRacun := NIL

MEMVAR gIdPos, gOcitBarKod, gPosPratiStanjePriProdaji

FUNCTION pos_when_racun_artikal( cIdRoba )

   pos_set_key_handler_ispravka_racuna()
   cIdroba := PadR( cIdroba, POS_ROBA_DUZINA_SIFRE )
   pos_racun_artikal_info( 0, "XCLEARX" )

   RETURN .T.

/*
   cIdRoba - parametar po referenci
*/
FUNCTION pos_valid_racun_artikal( cIdroba, aGetList, nRow, nCol )

   LOCAL lOk, cBarkodProcitati

   lOk := pos_postoji_roba( @cIdroba, nRow, nCol, @cBarkodProcitati, aGetList ) ;
      .AND. pos_racun_provjera_dupli_artikal( cIdroba )

   IF gOcitBarKod
      hb_keyPut( K_ENTER )
   ENDIF

   RETURN lOk


STATIC FUNCTION pos_racun_provjera_dupli_artikal( cIdroba )

   LOCAL nCount := 0
   LOCAL nCijenaT, nNCijenaT, nKolicinaT

   SELECT _pos_pripr
   PushWa()

   SET ORDER TO TAG "1" // "IdRoba+Transform(nCijena,'99999.99')+Transform(ncijena,'99999.99')"
   HSEEK cIdRoba
   DO WHILE !Eof() .AND. _pos_pripr->idroba == cIdroba
      nCijenaT := _pos_pripr->cijena
      nNCijenaT := _pos_pripr->ncijena
      nKolicinaT := 0
      DO WHILE !Eof() .AND. _pos_pripr->idroba == cIdroba .AND. _pos_pripr->cijena == nCijenaT .AND. _pos_pripr->ncijena == nNCijenaT
         nCount++
         nKolicinaT += _pos_pripr->kolicina
         SKIP
      ENDDO
      pos_racun_sumarno_stavka( cIdRoba, nCijenaT, nNCijenaT, nKolicinaT )
   ENDDO

   IF nCount > 0
      pos_racun_artikal_info( 2, cIdRoba, "Artikal na računu (x " + AllTrim( Str( nCount ) ) + ") !" )
   ENDIF
   PopWa()

   RETURN .T.


FUNCTION pos_when_racun_cijena_ncijena( cIdRoba, nCijena, nNCijena )

   LOCAL nPotrebnaKolicinaStavka

   IF roba->tip == "T"
      RETURN .T.
   ENDIF
altd()
   pos_racun_artikal_info( 1, cIdRoba, "Stanje: " + AllTrim( Str( pos_dostupno_artikal( cIdRoba, nCijena, nNCijena ), 12, 3 ) ) )
   nPotrebnaKolicinaStavka := pos_racun_sumarno_stavka( cIdRoba, nCijena, nNCijena )
   pos_racun_artikal_info( 3, cIdRoba, "Potrebna količina do sada: " + AllTrim( Str( nPotrebnaKolicinaStavka, 12, 3 ) ) + "" )

   RETURN .F.


FUNCTION pos_when_racun_kolicina( nKolicina )

   IF gOcitBarKod
      // IF param_tezinski_barkod() == "D" .AND. kolicina <> 0
      // ELSE
      nKolicina := 1
      // ENDIF
   ENDIF

   RETURN .T.


FUNCTION pos_valid_racun_kolicina( cIdRoba, nKolicina, nCijena, nNCijena )

   RETURN pos_provjera_stanje( cIdRoba, nKolicina, nCijena, nNCijena ) .AND. ;
      pos_provjera_max_kolicine( @nKolicina ) .AND. ;
      pos_cijena_nije_nula( nCijena )


STATIC FUNCTION pos_provjera_stanje( cIdRoba, nKolicina, nCijena, nNCijena )

   LOCAL lOk := .F.
   LOCAL cMsg
   LOCAL nStanjeRobe

   IF LastKey() == K_UP
      lOk := .T.
      RETURN lOk
   ENDIF

   IF ( nKolicina == 0 )
      MsgBeep( "Nepravilan unos količine! Ponovite unos!", 15 )
      RETURN lOk
   ENDIF

   IF gPosPratiStanjePriProdaji == "N" .OR. roba->tip $ "TU"
      lOk := .T.
      RETURN lOk
   ENDIF
   nStanjeRobe := pos_dostupno_artikal( cIdroba, nCijena, nNCijena )

   lOk := .T.
   IF ( nKolicina > nStanjeRobe )
      cMsg := "Artikal: " + cIdroba + " Trenutno na stanju: " + Str( nStanjeRobe, 12, 2 )
      IF gPosPratiStanjePriProdaji = "!"
         cMsg += "#Unos artikla onemogućen !?"
         lOk := .F.
      ENDIF
      MsgBeep( cMsg )

   ENDIF

   RETURN lOk


FUNCTION pos_max_kolicina_kod_unosa( nMaxKolicina )

   IF nMaxKolicina != NIL
      s_nMaxKolicinaPosRacun := fetch_metric( "pos_maksimalna_kolicina_na_unosu", my_user(), 0 )
   ENDIF

   RETURN s_nMaxKolicinaPosRacun


STATIC FUNCTION pos_provjera_max_kolicine( nKolicina )

   LOCAL nPosUnosMaxKolicina

   nPosUnosMaxKolicina := pos_max_kolicina_kod_unosa()
   IF nPosUnosMaxKolicina == 0
      nPosUnosMaxKolicina := 99999
   ENDIF

   IF nPosUnosMaxKolicina == 0
      RETURN .T.
   ENDIF

   IF nKolicina > nPosUnosMaxKolicina
      IF Pitanje(, "Da li je ovo ispravna količina (D/N) ?: " + AllTrim( Str( nKolicina ) ), "N" ) == "D"
         RETURN .T.
      ELSE
         nKolicina := 0
         RETURN .F.
      ENDIF
   ELSE
      RETURN .T.
   ENDIF

   RETURN .T.


STATIC FUNCTION pos_cijena_nije_nula( nCijena )

   IF LastKey() == K_UP
      RETURN .T.
   ENDIF

   IF nCijena == 0
      MsgBeep( "Nepravilan unos cijene, cijena mora biti <> 0 !?" )
      RETURN .F.
   ENDIF

   RETURN .T.


FUNCTION pos_racun_prikazi_ukupno( lRekalkulisati )

   LOCAL aRet

   IF lRekalkulisati == NIL
      lRekalkulisati := .F.
   ENDIF
   IF lRekalkulisati
      aRet := pos_racun_tekuci_saldo()
      pos_racun_iznos( aRet[ 1 ] )
      pos_racun_popust( aRet[ 2 ] )
   ENDIF

   @ box_x_koord() + 3, box_y_koord() + 15 SAY Space( 10 )
   pos_racun_prikaz_ukupno( box_x_koord() + 2 )
   ispis_veliki_brojevi_iznos( pos_racun_iznos_neto(), box_x_koord() + ( f18_max_rows() - 12 ), f18_max_cols() - 2 )

   SELECT _pos_pripr
   GO TOP

   RETURN .T.
