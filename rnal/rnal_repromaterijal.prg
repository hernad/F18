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

// -----------------------------------------------
// jedinica mjere je metrička
// -----------------------------------------------
FUNCTION jmj_is_metric( jmj )

   LOCAL _ok := .F.

   jmj := Upper( jmj )
   jmj := StrTran( jmj, "'", "" )

   IF jmj $ "#M  #MM #M' #"
      _ok := .T.
   ENDIF

   RETURN _ok

// ----------------------------------------------------------------
// preracunavanje količine repromaterijala
// ----------------------------------------------------------------
FUNCTION preracunaj_kolicinu_repromaterijala( kolicina, duzina, jmj, jmj_art )

   LOCAL _kolicina

   IF jmj_is_metric( jmj_art ) .AND. jmj == "KOM"

      // imamo potrebu da koristimo i duzinu

      // ukoliko je iz nekog razloga dužina 0
      IF Round( duzina, 2 ) == 0
         MsgBeep( "Koristi se metrička konverzija a dužina = 0 ?!???" )
         RETURN kolicina
      ENDIF

      DO CASE
      CASE jmj_art $ "#M' #M  #"
         // varijanta primarne jedince u metrima
         _kolicina := kolicina * ( duzina / 1000 )

      CASE jmj_art $ "#MM #"
         // varijanta primarne jedince u mm
         _kolicina := ( kolicina * duzina )

      OTHERWISE
         // sve ostalo bi trebala biti greška
         MsgBeep( "Problem sa pretvaranjem [mm] u [" + AllTrim( jmj_art ) + ")" )
         _kolicina := kolicina

      ENDCASE

   ELSE

      // ili su iste dimenzije, ili su sasvim neke druge vrijednosti
      DO CASE

      CASE jmj == jmj_art
         // količine su iste
         _kolicina := kolicina

      CASE jmj $ "#M  #M' #" .AND. jmj_art $ "#MM #"
         // uneseno M a roba u MM
         _kolicina := kolicina * 1000

      CASE _jmj $ "#MM #" .AND. jmj_art $ "#M' #M  #"
         // uneseno MM a roba u M
         _kolicina := kolicina / 1000

      OTHERWISE
         // sve ostalo... greska
         MsgBeep( "Ne mogu pretvoriti [" + AllTrim( jmj ) + "]" + ;
            " u [" + AllTrim( jmj_art ) + "]" )
         _kolicina := kolicina
      ENDCASE

   ENDIF

   RETURN _kolicina



// --------------------------------------------------------------------
// validacija ispravnosti unesenih parova jedinica mjere
// --------------------------------------------------------------------
FUNCTION valid_repro_jmj( jmj, jmj_art )

   LOCAL _ok := .T.
   LOCAL _x := box_x_koord()
   LOCAL _y := box_y_koord()

   IF jmj_is_metric( jmj ) .AND. !jmj_is_metric( jmj_art )
      // primjer: M -> KG
      _ok := .F.
   ELSEIF ( !jmj_is_metric( jmj ) .AND. jmj <> "KOM" ) .AND. jmj_is_metric( jmj_art )
      // primjer: KG -> M
      _ok := .F.
   ELSEIF !jmj_is_metric( jmj ) .AND. !jmj_is_metric( jmj_art ) .AND. ( jmj <> jmj_art )
      // primjer: KG -> PAK ili KOM -> KG itd...
      _ok := .F.
   ENDIF

   IF !_ok
      MsgBeep( "Ne postoji konverzija [" + AllTrim( jmj )  + "] u [" + AllTrim( jmj_art ) + "] !" )
      box_x_koord( _x )
      box_y_koord( _y )
   ENDIF

   RETURN _ok
