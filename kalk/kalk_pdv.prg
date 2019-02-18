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



/*
 *   Ispitivanje tarife, te punjenje matrice aPorezi
 * param: cIdKonto - Oznaka konta
 * param: cIdRoba - Oznaka robe
 * param: aPorezi - matrica za vrijednosti poreza
 * param: cIdTar - oznaka tarife, ovaj parametar je nil, ali se koristi za izvjestaje radi starih dokumenata (gdje je bilo promjene tarifa)
 */

FUNCTION set_pdv_array_by_koncij_region_roba_idtarifa_2_3( cIdKonto, cIdRoba, aPorezi, cIdTar )

   LOCAL cTarifa
   LOCAL lUsedRoba
   LOCAL lUsedTarifa
   LOCAL cIdTarifa

   PRIVATE cPolje

   lUsedRoba := .T.
   lUsedTarifa := .T.

   PushWA()

   cPolje := "IdTarifa"

   IF cIdTar == nil
      select_o_roba( cIdRoba )
      cTarifa := roba->idtarifa  // &cPolje  // F18 roba ima samo idtarifa
      select_o_tarifa( cTarifa )
      cIdTarifa := tarifa->id
   ELSE
      cTarifa := cIdTar
      select_o_tarifa( cTarifa )
      cIdTarifa := cIdTar
   ENDIF

   ??set_pdv_array( @aPorezi )

   PopWa()

   RETURN cIdTarifa


/*
 *     Racuna iznos PPP
    *   param: nMpcBp Maloprodajna cijena bez poreza
    *   param: aPorezi Matrica poreza
    *   param: aPoreziIzn Matrica izracunatih poreza
    *   param: nMpcSaP Maloprodajna cijena sa porezom
*/

FUNCTION kalk_porezi_maloprodaja( aPorezi, nMpcBp, nMpcSaP ) ??

   LOCAL nPom
   LOCAL nPDV

   IF nMpcBp == NIL // zadate je cijena sa porezom, utvrdi cijenu bez poreza
      nPDV := aPorezi[ POR_PDV ] // POR_PDV - PDV
      nMpcBp := nMpcSaP / ( nPDV / 100 + 1 )
   ENDIF

   RETURN nMpcBP * aPorezi[ POR_PDV ] / 100



FUNCTION kalk_porezi_maloprodaja_legacy_array( aPorezi, nMpc, nMpcSaPP ) ??

   LOCAL nPDV

   nPDV := kalk_porezi_maloprodaja( aPorezi, nMpc, nMpcSaPP )

   RETURN { nPDV, 0, 0 }



FUNCTION pdv_procenat_by_tarifa( cIdTarifa )

   PushWa()
   select_o_tarifa( cIdTarifa )
   PopWa()

   RETURN tarifa->pdv / 100


// formatiraj stopa pdv kao string
// " 17 %"
// "15.5%"

FUNCTION format_stopa_pdv_string( nPdv )

   IF nPdv == nil
      nPdv := tarifa->pdv
   ENDIF

   IF Round( nPdv, 1 ) == Round( nPdv, 0 )
      RETURN Str( nPdv, 3, 0 ) + " %"
   ENDIF

   RETURN Str( nPdv, 3, 1 ) + "%"


FUNCTION mpc_sa_pdv_by_tarifa( cIdTarifa, nMPCBp )

   LOCAL nPDV

   PushWa()
   select_o_tarifa( cIdTarifa )
   nPDV := tarifa->pdv / 100
   PopWa()

   RETURN nMpcBp * ( nPDV + 1 )


FUNCTION mpc_bez_pdv_by_tarifa( cIdTarifa, nMpcSaPP )

   LOCAL nPDV

   PushWa()
   select_o_tarifa( cIdTarifa )
   nPDV := tarifa->pdv / 100
   PopWa()

   RETURN nMpcSaPP / ( 1 + nPDV )
