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



FUNCTION p_fakt_objekti( cId, dx, dy )

   LOCAL i
   LOCAL nDbfArea := Select()
   PRIVATE ImeKol
   PRIVATE Kol

   ImeKol := {}
   Kol := {}

   o_fakt_objekti()

   AAdd( ImeKol, { PadC( "Id", 10 ), {|| id }, "id", {|| .T. }, {|| validacija_postoji_sifra( wId ) } } )
   AAdd( ImeKol, { PadC( "Naziv", 60 ), {|| naz }, "naz" } )

   FOR i := 1 TO Len( ImeKol )
      AAdd( Kol, i )
   NEXT

   SELECT ( nDbfArea )

   RETURN p_sifra( F_FAKT_OBJEKTI, 1, f18_max_rows() - 15, f18_max_cols() - 20, "Lista objekata", @cId, dx, dy )




/*

FUNCTION FaRobaBlock( Ch )

   LOCAL cSif := ROBA->id, cSif2 := ""
   LOCAL nArr := Select()

   IF Upper( Chr( Ch ) ) == "K"
      RETURN 6

   ELSEIF Upper( Chr( Ch ) ) == "D"
      // prikaz detalja sifre
      roba_opis_edit( .T. )
      RETURN 6

   ELSEIF Upper( Chr( Ch ) ) == "S"
      TB:Stabilize()
      PushWA()
      fakt_stanje_roba( roba->id )
      PopWa()
      RETURN 6

   ELSEIF Upper( Chr( ch ) ) == "P"

  --    IF gen_all_plu()
         RETURN DE_REFRESH
      ENDIF

   ELSEIF Ch == K_CTRL_T .AND. gSKSif == "D"
      // provjerimo da li je sifra dupla
      PushWA()
      SET ORDER TO TAG "ID"
  --    SEEK cSif
      SKIP 1
      cSif2 := ROBA->id
      PopWA()
      IF !( cSif == cSif2 )
         // ako nije dupla provjerimo da li postoji u kumulativu
    --     IF ima_u_fakt_kumulativ( cSif, "3" )
            Beep( 1 )
            Msg( "Stavka artikla/robe se ne moze brisati jer se vec nalazi u dokumentima!" )
            RETURN 7
         ENDIF
      ENDIF

   ELSEIF Ch == K_F2 .AND. gSKSif == "D"
    --  IF ima_u_fakt_kumulativ( cSif, "3" )
         RETURN 99
      ENDIF

   ELSE // nista od magicnih tipki
      RETURN DE_CONT
   ENDIF

   RETURN DE_CONT

*/




/*

STATIC FUNCTION ObSif()

   // IF glDistrib
   // o_relac()
   // O_VOZILA
   // O_KALPOS
   // ENDIF

   // o_sifk()
   // o_sifv()
   // select_o_konto()
   // select_o_partner()
   // select_o_roba()
   //o_fakt_txt()
   // o_tarifa()
   //o_valute()
   // o_rj()
   //o_sastavnice()
--   o_ugov()
   //o_rugov()

   //IF RUGOV->( FieldPos( "DEST" ) ) <> 0
      o_dest()
   //ENDIF

//   IF gNW == "T"
//      O_FADO
//      O_FADE
//   ENDIF

   //o_vrstep()
   //o_ops()

   RETURN .T.

*/
