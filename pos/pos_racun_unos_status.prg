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
#include "f18_color.ch"

// STATIC s_nIznosRacuna, s_nPopust
STATIC s_hRacunSumarno


/*
    R01  x 2 kom,  cijena=10, nCijena=0
    R01  x 1 kom,  cijena=10, nCijena=2 ( => neto_cijena = 8, 20% rabat)
    R01  x 5 kom,  cijena=10, nCijena=0
    R02  x 3 kom,  cijena=1, nCijena=0
    ======================================
    suma =
    =======================================
    R01  x 7 kom,  cijena=10, nCijena=0
    R01  x 1 kom,  cijena=10, nCijena=2 ( => neto_cijena = 8, 20% rabat)
    R02  x 3 kom,  cijena=1, nCijena=0
*/

FUNCTION pos_racun_sumarno_init()

   s_hRacunSumarno := hb_hash()


FUNCTION pos_racun_sumarno_stavka( cIdRoba, nCijena, nNCijena, nKolicina )

   LOCAL cKey

   IF s_hRacunSumarno == NIL
      s_hRacunSumarno := hb_Hash()
   ENDIF

   // npr. cKey = 'R01     10.00       0.00'
   cKey :=  cIdRoba + "" + Transform( nCijena, "99999.99" ) + Transform( nNCijena, "99999.99" )

   IF nKolicina != NIL
      s_hRacunSumarno[ cKey ] :=  nKolicina
   ENDIF

   IF !hb_HHasKey( s_hRacunSumarno, cKey )
      RETURN 0
   ENDIF

   RETURN s_hRacunSumarno[ cKey ]

/*
-- FUNCTION pos_racun_iznos_neto()

   RETURN s_nIznosRacuna - s_nPopust


-- FUNCTION pos_racun_iznos( nIznos )

   IF nIznos != NIL
      s_nIznosRacuna := nIznos
   ENDIF

   RETURN s_nIznosRacuna



FUNCTION pos_racun_popust( nIznos )

   IF nIznos != NIL
      s_nPopust := nIznos
   ENDIF

   RETURN s_nPopust
*/


FUNCTION pos_racun_prikaz_ukupno( nRow, nIznosRacuna, nPopust )

   @ box_x_koord() + nRow + 0, box_y_koord() + ( f18_max_cols() - 12 ) SAY nIznosRacuna PICT "99999.99" COLOR f18_color_invert()
   @ box_x_koord() + nRow + 1, box_y_koord() + ( f18_max_cols() - 12 ) SAY nPopust PICT "99999.99" COLOR f18_color_invert()
   @ box_x_koord() + nRow + 2, box_y_koord() + ( f18_max_cols() - 12 ) SAY nIznosRacuna - nPopust PICT "99999.99" COLOR f18_color_invert()

   RETURN .T.
*/

FUNCTION pos_racun_artikal_info( nLinija, cIdRoba, cMessage )

   LOCAL nI, nColor

   IF cIdRoba == "XCLEARX" // pobrisi statusne linije
      FOR nI := 1 TO 3
         @ box_x_koord() + ( f18_max_rows() - 11 ) + nI, box_y_koord() + 2 SAY Space( f18_max_cols() / 2 )
      NEXT
      RETURN .T.
   ENDIF

   nColor := SetColor( F18_COLOR_NAGLASENO )
   @ box_x_koord() + ( f18_max_rows() - 11 ) + nLinija, box_y_koord() + 2 SAY Space( f18_max_cols() / 2 )
   @ box_x_koord() + ( f18_max_rows() - 11 ) + nLinija, box_y_koord() + 2 SAY _u( cIdRoba + " : " + cMessage )
   SetColor( nColor )

   RETURN .T.


FUNCTION pos_racun_info( hParams )

   info_bar( "pos", "POS račun broj: " +  pos_dokument_sa_vrijeme( hParams ) )

   RETURN .T.
