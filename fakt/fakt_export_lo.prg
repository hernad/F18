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



// ------------------------------------------------
// export dokumenta u dbf/xls
// ------------------------------------------------
FUNCTION fakt_export_dokument_lo()

   LOCAL cLaunch
   LOCAL aDbf := {}

   aDbf := _g_fields()

   IF !xlsx_export_init( aDbf )
      RETURN .F.
   ENDIF
   
   _exp_dok()
   open_exported_xlsx()

   RETURN .T.


// ---------------------------------------------
// ubaci u exp dbf stavke iz tabele
// ---------------------------------------------
STATIC FUNCTION _exp_dok()

   LOCAL nTArea := Select()

   LOCAL cParNaz
   LOCAL cParRegb

   // pripremi fakturu za stampu, samo napuni tabele...
   fakt_stdok_pdv( NIL, NIL, NIL, .T. )

   o_r_export()
   O_DRN
   O_DRNTEXT
   O_RN

   // #format partnera: naziv + adresa + ptt + mjesto
   cParNaz := AllTrim( get_dtxt_opis( "K01" ) ) + ;
      " " + ;
      AllTrim( get_dtxt_opis( "K02" ) ) + ;
      " " + ;
      AllTrim( get_dtxt_opis( "K10" ) ) + ;
      " " + ;
      AllTrim( get_dtxt_opis( "K11" ) )

   cParRegb := get_dtxt_opis( "K03" )

   // te tabele iskoristi za export
   SELECT drn
   GO TOP

   SELECT rn
   GO TOP

   DO WHILE !Eof()

      SELECT r_export
      APPEND BLANK

      REPLACE brdok WITH drn->brdok
      REPLACE rbr WITH rn->rbr
      REPLACE art_id WITH rn->idroba
      REPLACE art_naz WITH rn->robanaz
      REPLACE art_jmj WITH rn->jmj

      REPLACE dat_dok WITH drn->datdok
      REPLACE par_naz WITH cParNaz
      REPLACE par_regb WITH cParRegb

      REPLACE i_kol WITH rn->kolicina
      REPLACE i_bpdv WITH rn->cjenbpdv
      REPLACE i_popust WITH rn->popust
      REPLACE i_bpdvp WITH rn->cjen2bpdv
      REPLACE i_ukupno WITH ( rn->kolicina * rn->cjen2bpdv )

      SELECT rn
      SKIP

   ENDDO

   SELECT r_export

   // totali....
   REPLACE t_bpdv WITH drn->ukbezpdv
   REPLACE t_popust WITH drn->ukpopust
   REPLACE t_bpdvp WITH drn->ukbpdvpop
   REPLACE t_pdv WITH drn->ukpdv
   REPLACE t_ukupno WITH drn->ukupno

   SELECT ( nTArea )

   RETURN .T.


// --------------------------------------------
// struktura export tabele
// --------------------------------------------
STATIC FUNCTION _g_fields()

   LOCAL aDbf := {}

   AAdd( aDbf, { "brdok", "C", 8, 0 } )
   AAdd( aDbf, { "rbr", "C", 3, 0 } )
   AAdd( aDbf, { "art_id", "C", 10, 0 } )
   AAdd( aDbf, { "art_naz", "C", 160, 0 } )
   AAdd( aDbf, { "art_jmj", "C", 3, 0 } )
   AAdd( aDbf, { "par_naz", "C", 80, 0 } )
   AAdd( aDbf, { "par_regb", "C", 13, 0 } )
   AAdd( aDbf, { "dat_dok", "D", 8, 0 } )
   AAdd( aDbf, { "i_kol", "N", 15, 5 } )
   AAdd( aDbf, { "i_bpdv", "N", 15, 5 } )
   AAdd( aDbf, { "i_popust", "N", 15, 5 } )
   AAdd( aDbf, { "i_bpdvp", "N", 15, 5 } )
   AAdd( aDbf, { "i_ukupno", "N", 15, 5 } )
   AAdd( aDbf, { "t_bpdv", "N", 15, 5 } )
   AAdd( aDbf, { "t_popust", "N", 15, 5 } )
   AAdd( aDbf, { "t_bpdvp", "N", 15, 5 } )
   AAdd( aDbf, { "t_pdv", "N", 15, 5 } )
   AAdd( aDbf, { "t_ukupno", "N", 15, 5 } )

   RETURN aDbf
