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

FUNCTION pos_racun_sadrzi_artikal( cIdPos, cIdVd, dDatum, cBroj, cIdRoba )

   LOCAL lRet := .F.
   LOCAL cWhere

   cWhere := " idpos " + sql_quote( cIdPos )
   cWhere += " AND idvd = " + sql_quote( cIdVd )
   cWhere += " AND datum = " + sql_quote( dDatum )
   cWhere += " AND brdok = " + sql_quote( cBroj )
   cWhere += " AND idroba = " + sql_quote( cIdRoba )

   IF table_count( f18_sql_schema( "pos_pos" ), cWhere ) > 0
      lRet := .T.
   ENDIF

   RETURN lRet


FUNCTION pos_iznos_dokumenta( lUI )

   LOCAL cRet := Space( 13 )
   LOCAL l_u_i
   LOCAL nIznos := 0
   LOCAL cIdPos, cIdVd, cBrDok
   LOCAL dDatum

   SELECT pos_doks

   cIdPos := pos_doks->idPos
   cIdVd := pos_doks->idVd
   cBrDok := pos_doks->brDok
   dDatum := pos_doks->datum

   IF ( ( lUI == NIL ) .OR. lUI )

      IF pos_doks->IdVd $ POS_IDVD_ULAZI
         seek_pos_pos( cIdPos, cIdVd, dDatum, cBrDok )
         DO WHILE !Eof() .AND. pos->( IdPos + IdVd + DToS( datum ) + BrDok ) == cIdPos + cIdVd + DToS( dDatum ) + cBrDok
            nIznos += pos->kolicina * pos->cijena
            SKIP
         ENDDO

      ENDIF
   ENDIF

   IF ( ( lUI == NIL ) .OR. !lUI ) // izlazi
      IF pos_doks->idvd $ POS_IDVD_RACUN + "#" + "IN" + "#" + POS_IDVD_NIVELACIJA

         seek_pos_pos( cIdPos, cIdVd, dDatum, cBrDok )

         DO WHILE !Eof() .AND. pos->( IdPos + IdVd + DToS( datum ) + BrDok ) == cIdPos + cIdVd + DToS( dDatum ) + cBrDok
            DO CASE
            CASE pos_doks->idvd = POS_IDVD_INVENTURA
               // samo ako je razlicit iznos od 0
               // ako je 0 onda ne treba mnoziti sa cijenom
               IF pos->kol2 <> 0
                  nIznos += pos->kol2 * pos->cijena
               ENDIF
            CASE pos_doks->IdVd == POS_IDVD_NIVELACIJA
               nIznos += pos->kolicina * ( pos->ncijena - pos->cijena )
            OTHERWISE
               nIznos += pos->kolicina * pos->cijena
            ENDCASE
            SKIP
         ENDDO
      ENDIF
   ENDIF

   SELECT pos_doks
   cRet := Str( nIznos, 13, 2 )

   RETURN ( cRet )
