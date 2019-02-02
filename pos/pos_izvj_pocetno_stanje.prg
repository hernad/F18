/*
 * This file is part of the bring.out knowhow ERP, a free and open source
 * Enterprise Resource Planning suite,
 * Copyright (c) 1994-2018 by bring.out d.o.o Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including knowhow ERP specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_knowhow.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */

#include "f18.ch"


FUNCTION pos_prepis_pocetno_stanje()

   LOCAL nSir := 80, nRobaSir := 30, cLm := Space ( 5 ), cPicKol := "999999.999"

   START PRINT CRET

   nSir := 40
   nRobaSir := 18
   cLM := ""
   cPicKol := "9999.999"
   ? PadC ( "POCETNO STANJE " + ;
      iif ( Empty ( DOKS->IdPos ), "", AllTrim ( DOKS->IdPos ) + "-" ) + ;
      AllTrim ( DOKS->BrDok ), nSir )

   seek_pos_pos( pos_doks->IdPos,  pos_doks->IdVd, pos_doks->datum,  pos_doks->BrDok )
   ? PadC ( FormDat1 ( DOKS->Datum ) + ;
      iif ( !Empty ( DOKS->Smjena ), " Smjena: " + DOKS->Smjena, "" ), nSir )
   ?

   IF !Empty( doks->idPartner )
      ?
      ? "Partner: ", doks->idPartner
      ?
   ENDIF

   ? cLM

   ?? "Sifra    Naziv              JMJ Kolicina"
   m := cLM + "-------- ------------------ --- --------"
   IF gPostDO == "D"
      ?? " DIO"
   ENDIF
   ? m

/****
Sifra    Naziv                          JMJ Cijena  Kolicina   ODJ DIO
-------- ------------------------------ --- ------- ---------- --- ---
01234567 012345678901234567890123456789     9999.99 999999.999
                                            999,999,999,999.99
Sifra    Naziv              JMJ Kolicina
         ODJ DIO
-------- ------------------ --- --------
01234567 012345678901234567 012 9999.999
         01  01
                            9,999,999.99
****/

   nFin := 0

   SELECT POS
   DO WHILE ! Eof() .AND. POS->( IdPos + IdVd + DToS( datum ) + BrDok ) == DOKS->( IdPos + IdVd + DToS( datum ) + BrDok )

      ? cLM
      ?? IdRoba, ""
      select_o_roba( POS->IdRoba )
      ?? PadR ( _field->Naz, nRobaSir ), _field->Jmj, ""
      SELECT POS
      ?? TRANS ( POS->Kolicina, cPicKol )
      ? cLM + Space ( Len ( POS->IdRoba ) )
      ?? " " + POS->IdOdj
      nFin += POS->( Kolicina * Cijena )
      SKIP
   ENDDO

   ? m
   ? cLM
   ?? PadL ( "IZNOS DOKUMENTA (" + Trim ( gDomValuta ) + ")",  10  + nRobaSir ), TRANS ( nFin, "9,999,999.99" )
   ? m

   //PaperFeed()

   ENDPRINT
   SELECT pos_doks

   RETURN .T.
