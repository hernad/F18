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

MEMVAR gPosProdajnoMjesto, gOcitBarKod, gPosPratiStanjePriProdaji
MEMVAR _cijena, _ncijena

FUNCTION pos_when_racun_artikal( cIdRoba )

   pos_set_key_handler_ispravka_racuna()
   cIdroba := PadR( cIdroba, POS_ROBA_DUZINA_SIFRE )
   pos_racun_artikal_info( 0, "XCLEARX" )

   RETURN .T.


FUNCTION pos_racun_odabir_cijene( aCijene )

   LOCAL aOpc := {}
   LOCAL nIzbor := 1
   LOCAL cCijena, nI
   LOCAL lCentury
   LOCAL nCijena, nNCijena, nPopust, nPopustProc

   lCentury := __SetCentury( .T. )
   FOR nI := 1 TO Len( aCijene )
      nCijena := aCijene[ nI, 1 ]
      nNCijena := aCijene[ nI, 2 ]
      IF Round( nNCijena, 4 ) <> 0
         nPopust := nCijena - nNCijena
         nPopustProc := nPopust / nCijena * 100
      ELSE
         nPopust := 0
         nPopustProc := 0
      ENDIF

      IF nPopust == 0
         cCijena := PadR( Transform( nCijena, "999999.99" ), 30 )
      ELSE
         cCijena := PadR( Transform( nCijena, "999999.99" ) + " - " + Transform( nPopustProc, "99.99%" ) + " = " + Transform( nCijena - nPopust, "99999.99" ), 30 )
      ENDIF
      cCijena += " [" + DToC( aCijene[ nI, 3 ] ) + " - " + DToC( aCijene[ nI, 4 ] ) + "] "
      AAdd( aOpc, cCijena )
   NEXT
   __SetCentury( lCentury )

   RETURN meni_fiksna_lokacija( box_x_koord() + 3, box_y_koord() + 10, aOpc, nIzbor )




/*
   cIdRoba - parametar po referenci
*/
FUNCTION pos_valid_racun_artikal( cIdroba, aGetList, nRow, nCol )

   LOCAL lOk, cBarkodProcitati, aCijene, nOdabranaCijena

   lOk := pos_postoji_roba( @cIdroba, nRow, nCol, @cBarkodProcitati, aGetList ) ;
      .AND. pos_racun_provjera_dupli_artikal( cIdroba )

   aCijene := pos_dostupne_cijene_za_artikal( cIdRoba )
   IF Len( aCijene ) > 1
      nOdabranaCijena := pos_racun_odabir_cijene( aCijene )
      IF LastKey() == K_ESC
         RETURN .F.
      ENDIF
      _cijena := aCijene[ nOdabranaCijena, 1 ]
      _ncijena := aCijene[ nOdabranaCijena, 2 ]

   ELSEIF Len( aCijene ) == 1
      nOdabranaCijena := 1
      _cijena := aCijene[ nOdabranaCijena, 1 ]
      _ncijena := aCijene[ nOdabranaCijena, 2 ]
   ELSE
       IF !pos_ne_prati_stanje()
         Alert( "Artikla " + cIdRoba + " nema na stanju !?" )
      ENDIF
      _cijena := pos_get_mpc()
      _ncijena := 0
   ENDIF

   IF gOcitBarKod
      hb_keyPut( K_ENTER )
   ENDIF

   RETURN lOk


static function pos_ne_prati_stanje()
    RETURN .T.


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

   pos_racun_artikal_info( 1, cIdRoba, "Stanje: " + AllTrim( Str( pos_dostupno_artikal_za_cijenu( cIdRoba, nCijena, nNCijena ), 12, 3 ) ) )
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

   LOCAL cMsg
   LOCAL nStanjeRobe, nPotrebnaKolicinaVecUnesenoUPripremu

   IF LastKey() == K_UP
      RETURN .T.
   ENDIF

   IF ( nKolicina == 0 )
      MsgBeep( "Nepravilan unos količine! Ponovite unos!", 15 )
      RETURN .F.
   ENDIF

   IF gPosPratiStanjePriProdaji == "N" .OR. roba->tip $ "TU"
      RETURN .T.
   ENDIF
   nStanjeRobe := pos_dostupno_artikal_za_cijenu( cIdroba, nCijena, nNCijena )
   nPotrebnaKolicinaVecUnesenoUPripremu := pos_racun_sumarno_stavka( cIdRoba, nCijena, nNCijena )

   IF ( nKolicina + nPotrebnaKolicinaVecUnesenoUPripremu ) > nStanjeRobe
      cMsg := AllTrim( cIdroba ) + " na stanju: " + AllTrim( Str( nStanjeRobe, 12, 3 ) )
      cMsg += " vi želite prodati " +  AllTrim( Str( nKolicina + nPotrebnaKolicinaVecUnesenoUPripremu, 12, 3 ) )
      IF gPosPratiStanjePriProdaji == "!"
         cMsg += "#Unos artikla onemogućen !?"
         MsgBeep( cMsg )
         RETURN .F.
      ELSE
         Alert( _u( cMsg ) )
         IF Pitanje( , "Ignorisati nedostatak robe na stanju (N/D)?", "N" ) == "D"
            RETURN .T.
         ELSE
            RETURN .F.
         ENDIF
      ENDIF
   ENDIF

   RETURN .T.


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

   IF Round( nCijena, 4 ) == 0
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


FUNCTION pos_popust( nCijena, nNCijena )

   IF Round( nNcijena, 4 ) == 0
      RETURN 0
   ENDIF

   RETURN nCijena - nNCijena


FUNCTION pos_pripr_popust()

   IF Round( _pos_pripr->ncijena, 4 ) == 0
      RETURN 0
   ENDIF

   RETURN _pos_pripr->cijena - _pos_pripr->ncijena


FUNCTION pos_pripr_cijena_sa_popustom()

   IF Round( _pos_pripr->ncijena, 4 ) == 0
      RETURN _pos_pripr->cijena
   ENDIF

   RETURN _pos_pripr->ncijena


FUNCTION pos_racun_tekuci_saldo()

   LOCAL nIznos := 0
   LOCAL nPopust := 0

   PushWa()
   SELECT _pos_pripr
   GO TOP
   DO WHILE !Eof()
      nIznos += _pos_pripr->kolicina *  _pos_pripr->cijena
      nPopust += _pos_pripr->kolicina * pos_pripr_popust()
      SKIP
   ENDDO
   PopWa()

   RETURN { nIznos, nPopust }
