/*
 * This file is part of the bring.out knowhow ERP, a free and open source
 * ERP software suite,
 * Copyright (c) 1994-2018 by bring.out doo Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including FMK specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_knowhow.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */

#include "f18.ch"

MEMVAR Kol, ImeKol
MEMVAR wId

FUNCTION P_KonCij( cId, dx, dy )

   LOCAL lRet
   LOCAL i
   LOCAL nTArea
   PRIVATE ImeKol
   PRIVATE Kol

   ImeKol := {}
   Kol := {}

   nTArea := Select()

   IF cId != NIL .AND. !Empty( cId )
      select_o_koncij( "XXXXXXX" ) // cId je zadan, otvoriti samo dummy tabelu sa 0 zapisa
   ELSE
      select_o_koncij()
   ENDIF

   AAdd( ImeKol, { "ID", {|| dbf_get_rec()[ "id" ] }, "id", {|| .T. }, {|| valid_sifarnik_id_postoji( wId ) } } )
   AAdd( ImeKol, { PadC( "Shema", 5 ), {|| PadC( koncij->shema, 5 ) }, "shema" } )
   AAdd( ImeKol, { "Tip", {|| dbf_get_rec()[ "naz" ] }, "naz" } )
   AAdd( ImeKol, { "PM (v3)", {|| koncij->idprodmjes }, "idprodmjes" } )
   AAdd( ImeKol, { "Prod (v4)", {|| transform(koncij->prod, '99999') }, "prod" } )

   AAdd ( ImeKol, { "KK1", {|| dbf_get_rec()[ "kk1" ] }, "KK1" } )
   AAdd ( ImeKol, { PadC( "KK2", 7 ), {|| koncij->KK2 }, "KK2", {|| .T. }, {|| Empty( wKK2 ) .OR. P_Konto( @wKK2 ) } } )
   AAdd ( ImeKol, { PadC( "KK3", 7 ), {|| koncij->KK3 }, "KK3", {|| .T. }, {|| Empty( wKK3 ) .OR. P_Konto( @wKK3 ) } } )
   AAdd ( ImeKol, { PadC( "KK4", 7 ), {|| koncij->KK4 }, "KK4", {|| .T. }, {|| Empty( wKK4 ) .OR. P_Konto( @wKK4 ) } } )
   AAdd ( ImeKol, { PadC( "KK5", 7 ), {|| koncij->KK5 }, "KK5", {|| .T. }, {|| Empty( wKK5 ) .OR. P_Konto( @wKK5 ) } } )
   AAdd ( ImeKol, { PadC( "KK6", 7 ), {|| koncij->KK6 }, "KK6", {|| .T. }, {|| Empty( wKK6 ) .OR. P_Konto( @wKK6 ) } } )

   AAdd ( ImeKol, { PadC( "KP1", 7 ), {|| koncij->KP1 }, "KP1", {|| .T. }, {|| Empty( wKP1 ) .OR. P_Konto( @wKP1 ) } } )
   AAdd ( ImeKol, { PadC( "KP2", 7 ), {|| koncij->KP2 }, "KP2", {|| .T. }, {|| Empty( wKP2 ) .OR. P_Konto( @wKP2 ) } } )
   AAdd ( ImeKol, { PadC( "KP3", 7 ), {|| koncij->KP3 }, "KP3", {|| .T. }, {|| Empty( wKP3 ) .OR. P_Konto( @wKP3 ) } } )
   AAdd ( ImeKol, { PadC( "KP4", 7 ), {|| koncij->KP4 }, "KP4", {|| .T. }, {|| Empty( wKP4 ) .OR. P_Konto( @wKP4 ) } } )
   AAdd ( ImeKol, { PadC( "KP5", 7 ), {|| koncij->KP5 }, "KP5", {|| .T. }, {|| Empty( wKP5 ) .OR. P_Konto( @wKP5 ) } } )

   AAdd ( ImeKol, { PadC( "KO1", 7 ), {|| koncij->KO1 }, "KO1", {|| .T. }, {|| Empty( wKO1 ) .OR. P_Konto( @wKO1 ) } } )
   AAdd ( ImeKol, { PadC( "KO2", 7 ), {|| koncij->KO2 }, "KO2", {|| .T. }, {|| Empty( wKO2 ) .OR. P_Konto( @wKO2 ) } } )
   AAdd ( ImeKol, { PadC( "KO3", 7 ), {|| koncij->KO3 }, "KO3", {|| .T. }, {|| Empty( wKO3 ) .OR. P_Konto( @wKO3 ) } } )
   AAdd ( ImeKol, { PadC( "KO4", 7 ), {|| koncij->KO4 }, "KO4", {|| .T. }, {|| Empty( wKO4 ) .OR. P_Konto( @wKO4 ) } } )
   AAdd ( ImeKol, { PadC( "KO5", 7 ), {|| koncij->KO5 }, "KO5", {|| .T. }, {|| Empty( wKO5 ) .OR. P_Konto( @wKO5 ) } } )


   AAdd ( ImeKol, { "Region", {|| koncij->Region }, "Region", {|| .T. }, {|| .T. } } )
   AAdd ( ImeKol, { "Sfx KALK", {|| koncij->sufiks }, "sufiks", {|| .T. }, {|| .T. } } )


   FOR i := 1 TO Len( ImeKol )
      AAdd( Kol, i )
   NEXT

   SELECT ( nTArea )

   lRet := p_sifra( F_KONCIJ, 1, f18_max_rows() - 10, f18_max_cols() - 15, "Lista: Konta - tipovi cijena", @cId, dx, dy )

   RETURN lRet


FUNCTION P_KonCij2( CId, dx, dy )

   LOCAL nTArea
   PRIVATE ImeKol
   PRIVATE Kol

   ImeKol := {}
   Kol := {}

   nTArea := Select()
   o_koncij()

   AAdd( ImeKol, { "ID", {|| id }, "id", {|| .T. }, {|| valid_sifarnik_id_postoji( wId ) } } )
   AAdd( ImeKol, { PadC( "Shema", 5 ), {|| PadC( shema, 5 ) }, "shema" } )
   AAdd( ImeKol, { "Tip", {|| naz }, "naz" } )
   AAdd( ImeKol, { "PM", {|| idprodmjes }, "idprodmjes" } )

   IF KONCIJ->( FieldPos( "KP9" ) ) <> 0   
      AAdd ( ImeKol, { PadC( "KP6", 7 ), {|| KP6 }, "KP6", {|| .T. }, {|| Empty( wKP6 ) .OR. P_Konto( @wKP6 ) } } )
      AAdd ( ImeKol, { PadC( "KP7", 7 ), {|| KP7 }, "KP7", {|| .T. }, {|| Empty( wKP7 ) .OR. P_Konto( @wKP7 ) } } )
      AAdd ( ImeKol, { PadC( "KP8", 7 ), {|| KP8 }, "KP8", {|| .T. }, {|| Empty( wKP8 ) .OR. P_Konto( @wKP8 ) } } )
      AAdd ( ImeKol, { PadC( "KP9", 7 ), {|| KP9 }, "KP9", {|| .T. }, {|| Empty( wKP9 ) .OR. P_Konto( @wKP9 ) } } )
   ENDIF

   IF KONCIJ->( FieldPos( "KPD" ) ) <> 0
      AAdd ( ImeKol, { PadC( "KPA", 7 ), {|| KPA }, "KPA", {|| .T. }, {|| Empty( wKPA ) .OR. P_Konto( @wKPA ) } } )
      AAdd ( ImeKol, { PadC( "KPB", 7 ), {|| KPB }, "KPB", {|| .T. }, {|| Empty( wKPB ) .OR. P_Konto( @wKPB ) } } )
      AAdd ( ImeKol, { PadC( "KPC", 7 ), {|| KPC }, "KPC", {|| .T. }, {|| Empty( wKPC ) .OR. P_Konto( @wKPC ) } } )
      AAdd ( ImeKol, { PadC( "KPD", 7 ), {|| KPD }, "KPD", {|| .T. }, {|| Empty( wKPD ) .OR. P_Konto( @wKPD ) } } )
   ENDIF

   IF KONCIJ->( FieldPos( "KPK" ) ) <> 0
      AAdd ( ImeKol, { PadC( "KPF", 7 ), {|| KOF }, "KPF", {|| .T. }, {|| Empty( wKPF ) .OR. P_Konto( @wKPF ) } } )
      AAdd ( ImeKol, { PadC( "KPG", 7 ), {|| KOG }, "KPG", {|| .T. }, {|| Empty( wKPG ) .OR. P_Konto( @wKPG ) } } )
      AAdd ( ImeKol, { PadC( "KPH", 7 ), {|| KOH }, "KPH", {|| .T. }, {|| Empty( wKPH ) .OR. P_Konto( @wKPH ) } } )
      AAdd ( ImeKol, { PadC( "KPI", 7 ), {|| KOI }, "KPI", {|| .T. }, {|| Empty( wKPI ) .OR. P_Konto( @wKPI ) } } )
      AAdd ( ImeKol, { PadC( "KPJ", 7 ), {|| KOJ }, "KPJ", {|| .T. }, {|| Empty( wKPJ ) .OR. P_Konto( @wKPJ ) } } )
      AAdd ( ImeKol, { PadC( "KPK", 7 ), {|| KOK }, "KPK", {|| .T. }, {|| Empty( wKPK ) .OR. P_Konto( @wKPK ) } } )
   ENDIF

   IF KONCIJ->( FieldPos( "KO9" ) ) <> 0
      AAdd ( ImeKol, { PadC( "KO6", 7 ), {|| KO6 }, "KO6", {|| .T. }, {|| Empty( wKO6 ) .OR. P_Konto( @wKO6 ) } } )
      AAdd ( ImeKol, { PadC( "KO7", 7 ), {|| KO7 }, "KO7", {|| .T. }, {|| Empty( wKO7 ) .OR. P_Konto( @wKO7 ) } } )
      AAdd ( ImeKol, { PadC( "KO8", 7 ), {|| KO8 }, "KO8", {|| .T. }, {|| Empty( wKO8 ) .OR. P_Konto( @wKO8 ) } } )
      AAdd ( ImeKol, { PadC( "KO9", 7 ), {|| KO9 }, "KO9", {|| .T. }, {|| Empty( wKO9 ) .OR. P_Konto( @wKO9 ) } } )
   ENDIF

   IF KONCIJ->( FieldPos( "KOD" ) ) <> 0   
      AAdd ( ImeKol, { PadC( "KOA", 7 ), {|| KOA }, "KOA", {|| .T. }, {|| Empty( wKOA ) .OR. P_Konto( @wKOA ) } } )
      AAdd ( ImeKol, { PadC( "KOB", 7 ), {|| KOB }, "KOB", {|| .T. }, {|| Empty( wKOB ) .OR. P_Konto( @wKOB ) } } )
      AAdd ( ImeKol, { PadC( "KOC", 7 ), {|| KOC }, "KOC", {|| .T. }, {|| Empty( wKOC ) .OR. P_Konto( @wKOC ) } } )
      AAdd ( ImeKol, { PadC( "KOD", 7 ), {|| KOD }, "KOD", {|| .T. }, {|| Empty( wKOD ) .OR. P_Konto( @wKOD ) } } )
   ENDIF

   IF KONCIJ->( FieldPos( "KOK" ) ) <> 0
      AAdd ( ImeKol, { PadC( "KOF", 7 ), {|| KOF }, "KOF", {|| .T. }, {|| Empty( wKOF ) .OR. P_Konto( @wKOF ) } } )
      AAdd ( ImeKol, { PadC( "KOG", 7 ), {|| KOG }, "KOG", {|| .T. }, {|| Empty( wKOG ) .OR. P_Konto( @wKOG ) } } )
      AAdd ( ImeKol, { PadC( "KOH", 7 ), {|| KOH }, "KOH", {|| .T. }, {|| Empty( wKOH ) .OR. P_Konto( @wKOH ) } } )
      AAdd ( ImeKol, { PadC( "KOI", 7 ), {|| KOI }, "KOI", {|| .T. }, {|| Empty( wKOI ) .OR. P_Konto( @wKOI ) } } )
      AAdd ( ImeKol, { PadC( "KOJ", 7 ), {|| KOJ }, "KOJ", {|| .T. }, {|| Empty( wKOJ ) .OR. P_Konto( @wKOJ ) } } )
      AAdd ( ImeKol, { PadC( "KOK", 7 ), {|| KOK }, "KOK", {|| .T. }, {|| Empty( wKOK ) .OR. P_Konto( @wKOK ) } } )
   ENDIF

   FOR i := 1 TO Len( ImeKol )
      AAdd( Kol, i )
   NEXT

   SELECT ( nTArea )

   RETURN p_sifra( F_KONCIJ, 1, 10, 60, "Lista: Konta / Atributi / 2 ", @cId, dx, dy )
