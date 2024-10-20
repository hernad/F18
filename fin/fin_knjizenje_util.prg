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

/* SetDatUPripr()
 *     Postavi datum u pripremi
 */
FUNCTION SetDatUPripr()

   LOCAL _rec

   PRIVATE cTDok := "00"
   PRIVATE dDatum := CToD( "01.01." + Str( Year( Date() ), 4 ) )

   IF !VarEdit( { { "Postaviti datum dokumenta", "dDatum",,, }, ;
         { "Promjenu izvrsiti u nalozima vrste", "cTDok",,, } }, 10, 0, 15, 79, ;
         'SETOVANJE NOVOG DATUMA DOKUMENTA I PREBACIVANJE STAROG U DATUM VALUTE', ;
         "B1" )
      CLOSERET
   ENDIF

   o_fin_pripr()
   GO TOP
   DO WHILE !Eof()
      IF IDVN <> cTDok
         SKIP 1
         LOOP
      ENDIF
      _rec := dbf_get_rec()
      IF Empty( _rec[ "datval" ] )
         _rec[ "datval" ] := _rec[ "datdok" ]
      ENDIF
      _rec[ "datdok" ] := dDatum
      dbf_update_rec( _rec )
      SKIP 1
   ENDDO

   CLOSERET

   RETURN .T.

/* K3Iz256(cK3)
 *
 *   param: cK3
 */

FUNCTION K3Iz256( cK3 )

   
   LOCAL i, c, o, d := 0, aC := { " ", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9" }
   IF my_get_from_ini( "FIN", "LimitiPoUgovoru_PoljeK3", "N", SIFPATH ) == "D"
      IF !Empty( cK3 )
         FOR i := Len( cK3 ) TO 1 STEP -1
            d += Asc( SubStr( cK3, i, 1 ) ) * 256 ^ ( Len( cK3 ) -i )
         NEXT
         cK3 := ""
         DO WHILE .T.
            c := Int( d / 11 )
            o := d % 11
            cK3 := aC[ o + 1 ] + cK3
            IF c = 0; EXIT; ENDIF
            d := c
         ENDDO
      ENDIF
      cK3 := PadL( cK3, 3 )
   ENDIF

   RETURN cK3



/* K3U256(cK3)
 *
 *  \cK3
 */

FUNCTION K3U256( cK3 )

   // {
   LOCAL i, c, o, d := 0, aC := { " ", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9" }
   IF !Empty( cK3 ) .AND. my_get_from_ini( "FIN", "LimitiPoUgovoru_PoljeK3", "N", SIFPATH ) == "D"
      FOR i := 1 TO Len( cK3 )
         p := AScan( aC, SubStr( cK3, i, 1 ) ) - 1
         d += p * 11 ^ ( Len( cK3 ) -i )
      NEXT
      cK3 := ""
      DO WHILE .T.
         c := Int( d / 256 )
         o := d % 256
         cK3 := Chr( o ) + cK3
         IF c = 0; EXIT; ENDIF
         d := c
      ENDDO
      cK3 := PadL( cK3, 2, Chr( 0 ) )
   ENDIF

   RETURN cK3
