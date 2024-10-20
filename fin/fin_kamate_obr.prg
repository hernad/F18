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


STATIC picdem := "9999999999999.99"



FUNCTION kamate_obracun_pojedinacni( fVise )

   LOCAL nKumKam := 0
   LOCAL nGlavn := 2892359.28
   LOCAL dDatOd := CToD( "01.09.07" )
   LOCAL dDatDo := CToD( "30.09.17" )
   LOCAL nExp := 365
   LOCAL GetList := {}


   PRIVATE cVarObracuna := "Z"

   IF fvise = NIL
      fVise := .F.
   ENDIF

   IF !fVise

      Box( "#OBRACUN KAMATE ZA JEDNU GLAVNICU", 3, 77 )
      @ box_x_koord() + 1, box_y_koord() + 2 SAY "Glavnica:" GET nGlavn PICT "9999999999999.99"
      @ box_x_koord() + 2, box_y_koord() + 2 SAY "Od datuma:" GET dDatOd
      @ box_x_koord() + 2, Col() + 2 SAY "do:" GET dDatDo
      @ box_x_koord() + 3, box_y_koord() + 2 SAY "Varijanta obracuna kamate (Z-zatezna kamata,P-prosti kamatni racun)" GET cVarObracuna VALID cVarObracuna $ "ZP" PICT "@!"
      READ
      ESC_BCR
      BoxC()

   ENDIF

   O_KS
   SET ORDER TO TAG "2"

   IF !start_print()
      RETURN .F.
   ENDIF

   ?
   P_10CPI
   ? Space( 45 ), "K A M A T E"
   ?
   ?
   B_ON
   ?U Space( 45 ), "Preduzeće:", self_organizacija_naziv()
   B_OFF
   ?
   ? "Partner: _____________________________________"
   ?
   ? "Obracun kamate po dokumentu : ________________ "
   ?
   ?

   IF ( cVarObracuna == "Z" )
      ? "Obracun zatezne kamate za period:", dDatOd, "-", dDatDo
   ELSE
      ? "Prosti kamatni obracun za period:", dDatOd, "-", dDatDo
   ENDIF

   ?
   ? "   Glavnica:"
   @ PRow(), PCol() + 1 SAY nGlavn PICT picDEM

   IF ( cVarObracuna == "Z" )
      ? m := "-------- -------- --- ---------------- ---------- ------- ----------------"
      ? "     Period       Dana      Osnovica     Tip kam.  Konform.      Iznos"
      ? "                                         i stopa    koef         kamate"
   ELSE
      ? m := "-------- -------- --- ---------------- --------- ----------------"
      ? "     Period       Dana    Osnovica       Stopa       Iznos"
      ? "                                                     kamate"
   ENDIF

   ? m

   nKumKam := 0

   SEEK DToS( dDatOd )
   IF dDatOd < ks->DatOd .OR. Eof()
      SKIP -1
   ENDIF

   DO WHILE .T.

      ddDatDo := Min( ks->DatDO, dDatDo )

      nPeriod := ddDatDo - dDatOd + 1

      IF ( cVarObracuna == "P" )
         IF ( Prestupna( Year( dDatOd ) ) )
            nExp := 366
         ELSE
            nExp := 365
         ENDIF
      ELSE
         IF ks->tip == "G"
            IF ks->duz == 0
               nExp := 365
            ELSE
               nExp := ks->duz
            ENDIF
         ELSEIF ks->tip == "M"
            IF ks->duz == 0
               dExp := "01."
               IF Month( ddDatdo ) == 12
                  dExp += "01." + AllTrim( Str( Year( ddDatdo ) + 1 ) )
               ELSE
                  dExp += AllTrim( Str( Month( ddDatdo ) + 1 ) ) + "." + AllTrim( Str( Year( ddDatdo ) ) )
               ENDIF
               nExp := Day( CToD( dExp ) -1 )
            ELSE
               nExp := ks->duz
            ENDIF
         ELSEIF ks->tip == "3"
            nExp := ks->duz
         ENDIF
      ENDIF

      IF ks->den <> 0  .AND. dDatOd == ks->datod
         ? "********* Izvrsena Denominacija osnovice sa koeficijentom:", ks->den, "****"
         nGlavn := Round( nGlavn * ks->den, 2 )
         nKumKam := Round( nKumKam * ks->den, 2 )
      ENDIF

      IF ( cVarObracuna == "Z" )
         nKKam := ( ( 1 + ks->stkam / 100 ) ^ ( nPeriod / nExp ) - 1.00000 )
         nIznKam := nKKam * nGlavn
      ELSE
         nKStopa := ks->stkam / 100
         nIznKam := nGlavn * nKStopa * nPeriod / nExp
      ENDIF

      nIznKam := Round( nIznKam, 2 )

      ? dDatOd, ddDatDo

      @ PRow(), PCol() + 1 SAY nPeriod PICT "999"
      @ PRow(), PCol() + 1 SAY nGlavn PICT picdem

      IF ( cVarObracuna == "Z" )
         @ PRow(), PCol() + 1 SAY ks->tip
         @ PRow(), PCol() + 1 SAY ks->stkam
         @ PRow(), PCol() + 1 SAY nKKam * 100 PICT "9999.99"
      ELSE
         @ PRow(), PCol() + 1 SAY ks->stkam
      ENDIF

      @ PRow(), PCol() + 1 SAY nIznKam PICT picdem

      nKumKam += nIznKam

      IF ( cVarObracuna == "Z" )
         nGlavn += nIznKam
      ENDIF

      IF dDatDo <= ks->datdo
         // kraj obracuna
         EXIT
      ENDIF

      SKIP

      dDatOd := ks->DatOd

   ENDDO


   ? m
   ?
   ? "Ukupno kamata    :", Transform( nKumKam, "999,999,999,999,999.99" )
   ?
   IF ( cVarObracuna == "Z" )
      ? "NOVO STANJE      :", Transform( nGlavn, "999,999,999,999,999.99" )
   ELSE
      ? "GLAVNICA+KAMATA  :", Transform( nGlavn + nKumKam, "999,999,999,999,999.99" )
   ENDIF

   ?

   FF


   end_print()

   my_close_all_dbf()

   RETURN .T.



// Racuna prestupnu godinu
FUNCTION Prestupna( nGodina )

   LOCAL lPrestupna

   lPrestupna := .F.
   IF nGodina % 4 == 0
      lPrestupna := .T.
   ENDIF

   RETURN lPrestupna
