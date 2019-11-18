/*
 * This file is part of the bring.out FMK, a free and open source
 * accounting software suite,
 * Copyright (c) 1994-2018 by bring.out d.o.o Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including knowhow ERP specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_knowhow.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */

#include "f18.ch"


FUNCTION fin_gen_panal_psint( cIdFirma, cIdVn, cBrNal, dDatNal )

   LOCAL fNasao, nStr, nD1, nD2, nP1, nP2
   LOCAL nDugBhd, nPotBHD, nDugDEM, nPotDEM

   nStr := 0
   nD1 := nD2 := nP1 := nP2 := 0

   DO WHILE !Eof() .AND. cIdFirma == IdFirma .AND. cIdVN == IdVN .AND. cBrNal == BrNal

      cIdkonto := idkonto

      nDugBHD := nDugDEM := 0
      nPotBHD := nPotDEM := 0
      IF D_P = "1"
         nDugBHD := IznosBHD; nDugDEM := IznosDEM
      ELSE
         nPotBHD := IznosBHD; nPotDEM := IznosDEM
      ENDIF

      SELECT PANAL
      SEEK cIdfirma + cIdvn + cBrNal + cIdKonto
      fNasao := .F.

      DO WHILE !Eof() .AND. cIdFirma == IdFirma .AND. cIdVN == IdVN .AND. cBrNal == BrNal .AND. IdKonto == cIdKonto
         IF gDatNal == "N"
            IF Month( psuban->datdok ) == Month( datnal )
               fNasao := .T.
               EXIT
            ENDIF
         ELSE
            // sintetika se generise na osnovu datuma naloga
            IF Month( dDatNal ) == Month( datnal )
               fNasao := .T.
               EXIT
            ENDIF
         ENDIF
         SKIP
      ENDDO

      SELECT PANAL
      IF !fNasao
         APPEND BLANK
      ENDIF

      REPLACE IdFirma WITH cIdFirma, IdKonto WITH cIdKonto, IdVN WITH cIdVN, BrNal WITH cBrNal, ;
         DatNal WITH iif( gDatNal == "D", dDatNal, Max( psuban->datdok, datnal ) ), ;
         DugBHD WITH DugBHD + nDugBHD, PotBHD WITH PotBHD + nPotBHD, ;
         DugDEM WITH DugDEM + nDugDEM, PotDEM WITH PotDEM + nPotDEM


      SELECT PSINT
      SEEK cIdfirma + cIdvn + cBrNal + Left( cIdKonto, 3 )

      fNasao := .F.

      DO WHILE !Eof() .AND. cIdFirma == IdFirma .AND. cIdVN == IdVN .AND. cBrNal == BrNal .AND. Left( cIdkonto, 3 ) == idkonto
         IF gDatNal == "N"
            IF  Month( psuban->datdok ) == Month( datnal )
               fNasao := .T.
               EXIT
            ENDIF
         ELSE
            IF Month( dDatNal ) == Month( datnal )
               fNasao := .T.
               EXIT
            ENDIF
         ENDIF
         SKIP
      ENDDO

      SELECT PSINT
      IF !fNasao
         APPEND BLANK
      ENDIF

      REPLACE IdFirma WITH cIdFirma, IdKonto WITH Left( cIdKonto, 3 ), IdVN WITH cIdVN, BrNal WITH cBrNal, DatNal WITH iif( gDatNal == "D", dDatNal,  Max( psuban->datdok, datnal ) ), ;
         DugBHD WITH DugBHD + nDugBHD, PotBHD WITH PotBHD + nPotBHD, ;
         DugDEM WITH DugDEM + nDugDEM, PotDEM WITH PotDEM + nPotDEM
      nD1 += nDugBHD; nD2 += nDugDEM; nP1 += nPotBHD; nP2 += nPotDEM

      SELECT PSUBAN
      SKIP

   ENDDO

   SELECT PNALOG
   APPEND BLANK
   REPLACE IdFirma WITH cIdFirma, IdVN WITH cIdVN, BrNal WITH cBrNal, DatNal WITH iif( gDatNal == "D", dDatNal, Date() ), ;
      DugBHD WITH nD1, PotBHD WITH nP1, ;
      DugDEM WITH nD2, PotDEM WITH nP2

   RETURN .T.


/*
FUNCTION box_fin_nalog( cIdFirma, cIdVn, cBrNal, dDatNal )

   LOCAL GetList := {}

   Box( "", 2, 50 )

   set_cursor_on()

   @ box_x_koord() + 1, box_y_koord() + 2 SAY "Nalog broj:"

   //IF gNW == "D"
  //    cIdFirma := self_organizacija_id()
  //    @ box_x_koord() + 1, Col() + 1 SAY cIdFirma
   //ELSE
      @ box_x_koord() + 1, Col() + 1 GET cIdFirma
   //ENDIF

   @ box_x_koord() + 1, Col() + 1 SAY "-" GET cIdVn
   @ box_x_koord() + 1, Col() + 1 SAY "-" GET cBrNal

   IF gDatNal == "D"
      @ box_x_koord() + 2, box_y_koord() + 2 SAY "Datum naloga:" GET dDatNal
   ENDIF

   READ

   BoxC()

   IF LastKey() == K_ESC
      RETURN .F.
   ENDIF

   RETURN .T.
*/

/*
   otvori psuban i ostale potrebne ostale tabele
*/
FUNCTION fin_open_psuban_and_ostalo()

   //o_vrstep()
   //o_konto()
   //o_partner()
   //o_tnal()
   //o_tdok()
   o_fin_psuban()
   o_fin_pripr()

   RETURN .T.

/*
    otvori psuban, panal, psint i ostale potrebne tabele
*/
FUNCTION fin_open_lock_panal( lZap )

   o_fin_psuban()
   o_fin_panal()
   o_fin_psint()
   o_fin_pnalog()

   //o_partner()
   //o_konto()
   //o_tnal()

   IF !lock_fin_priprema( lZap )
      Alert( "lock fin priprema error ?" )
      RETURN .F.
   ENDIF

   SELECT PSUBAN
   SET ORDER TO TAG "2"

   RETURN .T.


/*
   1) lZap := .T. => pobrisi tabele panal, psint, pnalog
                     PSUBAN ne diraj !
              .F. => ne brisi nista

   3) lockuj sve tabele

*/
STATIC FUNCTION lock_fin_priprema( lZap )

   LOCAL nCnt
   LOCAL lLock := .T.

#ifdef F18_DEBUG_FIN_AZUR
   AltD() // F18_DEBUG_FIN_AZUR
#endif

   nCnt := 0
   DO WHILE .T.

      ++nCnt
      IF nCnt > 5
         MsgBeep( "Neko već koristi tabele za pripreme finansijskog naloga !" )
         RETURN .F.
      ENDIF

      SELECT PANAL
      iif( lZap, my_dbf_zap(), NIL )

      lLock := lLock .AND. my_flock()
      IF !lLock
         hb_idleSleep( 1 )
         LOOP
      ENDIF

      SELECT PSINT
      iif( lZap, my_dbf_zap(), NIL )

      lLock := lLock .AND. my_flock()
      IF !lLock
         hb_idleSleep( 1 )
         LOOP
      ENDIF

      SELECT PNALOG
      iif( lZap, my_dbf_zap(), NIL )

      lLock := lLock .AND. my_flock()
      IF !lLock
         hb_idleSleep( 1 )
         LOOP
      ENDIF

      SELECT PSUBAN
      lLock := lLock .AND. my_flock()
      IF !lLock
         hb_idleSleep( 1 )
         LOOP
      ENDIF

      // sve lock prepreke prebrođene :)
      EXIT
   ENDDO

   RETURN .T.



FUNCTION fin_gen_sint_stavke_auto_import() // lAuto )

   o_fin_panal()
   o_fin_psint()
   o_fin_pnalog()
   o_fin_psuban()
   //o_konto()
   //o_tnal()

   //IF lAuto == NIL
  //    lAuto := .F.
  // ENDIF

   SELECT PANAL
   my_dbf_zap()

   SELECT PSINT
   my_dbf_zap()

   SELECT PNALOG
   my_dbf_zap()

   SELECT PSUBAN
   SET ORDER TO TAG "2"
   GO TOP

   IF Empty( BrNal )
      //IF lAuto == .T.
      //   closeret
      //ELSE
         closeret2
      //ENDIF
   ENDIF

   A := 0

   DO WHILE !Eof()
      // svi nalozi
      nStr := 0
      nD1 := 0
      nD2 := 0
      nP1 := 0
      nP2 := 0

      cIdFirma := IdFirma
      cIDVn := IdVN
      cBrNal := BrNal

      DO WHILE !Eof() .AND. cIdFirma == IdFirma .AND. cIdVN == IdVN  .AND. cBrNal == BrNal

         cIdkonto := idkonto
         nDugBHD := 0
         nDugDEM := 0
         nPotBHD := 0
         nPotDEM := 0

         IF D_P = "1"
            nDugBHD := IznosBHD
            nDugDEM := IznosDEM
         ELSE
            nPotBHD := IznosBHD
            nPotDEM := IznosDEM
         ENDIF

         SELECT PANAL // analitika
         SEEK cIdFirma + cIdVn + cBrNal + cIdKonto

         fNasao := .F.
         DO WHILE !Eof() .AND. cIdFirma == IdFirma .AND. cIdVN == IdVN .AND. cBrNal == BrNal .AND. IdKonto == cIdKonto

            IF gDatNal == "N"
               IF Month( psuban->datdok ) == Month( datnal )
                  fNasao := .T.
                  EXIT
               ENDIF
            ELSE
               // sintetika se generise na osnovu datuma naloga
               IF Month( dDatNal ) == Month( datnal )
                  fNasao := .T.
                  EXIT
               ENDIF
            ENDIF
            SKIP
         ENDDO

         IF !fNasao
            APPEND BLANK
         ENDIF

         my_rlock()
         REPLACE IdFirma WITH cIdFirma
         REPLACE IdKonto WITH cIdKonto
         REPLACE IdVN WITH cIdVN
         REPLACE BrNal WITH cBrNal
         REPLACE DatNal WITH iif( gDatNal == "D", dDatNal, Max( psuban->datdok, datnal ) )
         REPLACE DugBHD WITH DugBHD + nDugBHD
         REPLACE PotBHD WITH PotBHD + nPotBHD
         REPLACE DugDEM WITH DugDEM + nDugDEM
         REPLACE PotDEM WITH PotDEM + nPotDEM
         my_unlock()

         SELECT PSINT
         SEEK cIdfirma + cIdvn + cBrnal + Left( cIdkonto, 3 )
         fNasao := .F.

         DO WHILE !Eof() .AND. cIdFirma == IdFirma ;
               .AND. cIdVN == IdVN .AND. cBrNal == BrNal ;
               .AND. Left( cidkonto, 3 ) == idkonto
            IF gDatNal == "N"
               IF  Month( psuban->datdok ) == Month( datnal )
                  fNasao := .T.
                  EXIT
               ENDIF
            ELSE // sintetika se generise na osnovu dDatNal
               IF Month( dDatNal ) == Month( datnal )
                  fNasao := .T.
                  EXIT
               ENDIF
            ENDIF

            SKIP
         ENDDO

         IF !fNasao
            APPEND BLANK
         ENDIF

         my_rlock()
         REPLACE IdFirma WITH cIdFirma, IdKonto WITH Left( cIdKonto, 3 ), IdVN WITH cIdVN, ;
            BrNal WITH cBrNal, ;
            DatNal WITH iif( gDatNal == "D", dDatNal,  Max( psuban->datdok, datnal ) ), ;
            DugBHD WITH DugBHD + nDugBHD, PotBHD WITH PotBHD + nPotBHD, ;
            DugDEM WITH DugDEM + nDugDEM, PotDEM WITH PotDEM + nPotDEM

         my_unlock()

         nD1 += nDugBHD; nD2 += nDugDEM; nP1 += nPotBHD; nP2 += nPotDEM

         SELECT PSUBAN
         SKIP

      ENDDO
      // nalog

      SELECT PNALOG    // datoteka naloga
      APPEND BLANK

      my_rlock()
      REPLACE IdFirma WITH cIdFirma, IdVN WITH cIdVN, BrNal WITH cBrNal, ;
         DatNal WITH iif( gDatNal == "D", dDatNal, Date() ), ;
         DugBHD WITH nD1, PotBHD WITH nP1, ;
         DugDEM WITH nD2, PotDEM WITH nP2

      my_unlock()

      PRIVATE cDN := "N"

      SELECT PSUBAN

   ENDDO
   // svi nalozi

   SELECT PANAL
   GO TOP
   my_flock()
   DO WHILE !Eof()
      nRbr := 0
      cIdFirma := IdFirma
      cIDVn := IdVN
      cBrNal := BrNal
      DO WHILE !Eof() .AND. cIdFirma == IdFirma .AND. cIdVN == IdVN .AND. cBrNal == BrNal     // jedan nalog
         REPLACE rbr WITH Str( ++nRbr, 3 )
         SKIP
      ENDDO
   ENDDO
   my_unlock()

   SELECT PSINT
   GO TOP
   my_flock()
   DO WHILE !Eof()
      nRbr := 0
      cIdFirma := IdFirma;cIDVn = IdVN;cBrNal := BrNal
      DO WHILE !Eof() .AND. cIdFirma == IdFirma .AND. cIdVN == IdVN .AND. cBrNal == BrNal     // jedan nalog
         REPLACE rbr WITH Str( ++nRbr, 3 )
         SKIP
      ENDDO
   ENDDO
   my_unlock()

   my_close_all_dbf()

   RETURN .T.
