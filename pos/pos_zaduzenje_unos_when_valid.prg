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


STATIC s_nMaxKolicinaPosRacun := NIL

MEMVAR gOcitBarKod
MEMVAR _cijena, _ncijena


FUNCTION pos_zaduzenje_valid_kolicina( nKol )

   IF LastKey() = K_UP
      RETURN .T.
   ENDIF
   IF nKol == 0
      MsgBeep( "Količina mora biti različita od nule!#Ponovite unos!", 20 )
      RETURN .F.
   ENDIF

   RETURN .T.


FUNCTION pos_inventura_when_knjizna_kolicina( cIdRoba, nKnjiznaKolicina, nPopisanaKolicina )

  nKnjiznaKolicina := pos_dostupno_artikal_sa_kalo( cIdRoba )
  nPopisanaKolicina := -99999
  ShowGets()

RETURN .F.

FUNCTION pos_inventura_when_popisana_kolicina( cIdroba, nKnjiznaKolicina, nPopisanaKolicina )

   //IF LastKey() == K_UP
   //    RETURN .T.
   //ENDIF
   IF nPopisanaKolicina == -99999
      nPopisanaKolicina := nKnjiznaKolicina
   END IF
   ShowGets()

   RETURN .T.

FUNCTION pos_inventura_valid_kolicina_kol2( cIdRoba, nKnjiznaKolicina, nPopisanaKolicina )

   //IF LastKey() == K_UP
   //    RETURN .T.
   //ENDIF

   RETURN .T.

FUNCTION pos_zaduzenje_roba_when( cIdRoba )

   pos_set_key_handler_ispravka_zaduzenja()
   cIdroba := PadR( cIdRoba, POS_ROBA_DUZINA_SIFRE )

   RETURN .T.

FUNCTION pos_zaduzenje_roba_valid( cIdRoba, nX, nY )

   LOCAL lOk

   pos_unset_key_handler_ispravka_zaduzenja()
   lOk := pos_postoji_roba( @cIdRoba, nX, nY )
   pos_set_key_handler_ispravka_zaduzenja()
   cIdroba := PadR( cIdroba, POS_ROBA_DUZINA_SIFRE )

   RETURN lOk .AND. pos_zaduzenje_provjeri_duple_stavke( cIdroba )



// FUNCTION pos_when_71_ncijena( nNovaCijena, nCijena, nNCijena )
//
// nNovaCijena := nCijena - nNCijena
//
// RETURN .T.
//
// FUNCTION pos_valid_71_ncijena( nNovaCijena, nCijena, nNCijena )
//
// nNcijena := nCijena - nNovaCijena
//
// RETURN .T.

FUNCTION pos_zaduzenje_when_dat_od( cIdVd, dDatOd, dDatDo )

   LOCAL lSet := .F.

   IF Empty( dDatOd ) .AND. cIdVd == POS_IDVD_ZAHTJEV_SNIZENJE
      dDatOd := danasnji_datum()
      lSet := .T.
   ENDIF

   IF Empty( dDatDo ) .AND. cIdVd == POS_IDVD_ZAHTJEV_SNIZENJE
      IF lSet
         dDatDo := danasnji_datum() + 7
      ENDIF
   ENDIF

   RETURN .T.
