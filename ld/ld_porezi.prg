/*
 * This file is part of the bring.out FMK, a free and open source
 * accounting software suite,
 * Copyright (c) 1996-2011 by bring.out doo Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including FMK specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_FMK.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */


#include "f18.ch"

// -------------------------------------
// obracun i prikaz poreza
// -------------------------------------
FUNCTION obr_porez( nGodina, nMjesec, nPor, nPor2, nPorOps, nPorOps2, nUPorOl, cTipPor )

   LOCAL cAlgoritam := ""
   LOCAL nOsnova := 0

   IF cTipPor == nil
      cTipPor := ""
   ENDIF

   select_o_por()
   GO TOP

   nPom := 0
   nPor := 0
   nPor2 := 0
   nPorOps := 0
   nPorOps2 := 0
   nC1 := 20

   cLinija := "----------------------- -------- ----------- -----------"

   IF cUmPD == "D"
      m += " ----------- -----------"
   ENDIF

   IF cUmPD == "D"
      P_12CPI
      ? "----------------------- -------- ----------- ----------- ----------- -----------"
      ? _l( "                                 Obracunska     Porez    Preplaceni     Porez   " )
      ? _l( "     Naziv poreza          %      osnovica   po obracunu    porez     za uplatu " )
      ? "          (1)             (2)        (3)     (4)=(2)*(3)     (5)     (6)=(4)-(5)"
      ? "----------------------- -------- ----------- ----------- ----------- -----------"
   ENDIF

   DO WHILE !Eof()

      cAlgoritam := get_algoritam()

      // ako to nije taj tip poreza preskoci
      IF !Empty( cTipPor )
         IF por_tip <> cTipPor
            SKIP
            LOOP
         ENDIF
      ENDIF

      IF PRow() > ( 64 + dodatni_redovi_po_stranici() )
         // FF
      ENDIF

      ? id, "-", naz

      IF cAlgoritam == "S"
         @ PRow(), PCol() + 1 SAY "st.por"
      ELSE
         @ PRow(), PCol() + 1 SAY iznos PICT "99.99%"
      ENDIF

      nC1 := PCol() + 1

      IF !Empty( poopst )

         IF poopst == "1"
            ?? _l( " (po opst.stan)" )
         ELSEIF poopst == "2"
            ?? _l( " (po opst.stan)" )
         ELSEIF poopst == "3"
            ?? _l( " (po kant.stan)" )
         ELSEIF poopst == "4"
            ?? _l( " (po kant.rada)" )
         ELSEIF poopst == "5"
            ?? _l( " (po ent. stan)" )
         ELSEIF poopst == "6"
            ?? _l( " (po ent. rada)" )
            ?? _l( " (po opst.rada)" )
         ENDIF

         nOOP := 0
         // ukupna Osnovica za Obracun Poreza za po opstinama

         nPOLjudi := 0
         // ukup.ljudi za po opstinama

         nPorOps := 0
         nPorOps2 := 0

         IF cAlgoritam == "S"
            cSeek := por->id
         ELSE
            cSeek := Space( 2 )
         ENDIF

         SELECT opsld
         SEEK cSeek + por->poopst // opsld tmp

         ? StrTran( cLinija, "-", "=" )

         DO WHILE !Eof() .AND. porid == cSeek .AND. id == por->poopst

            cOpst := opsld->idops

            select_o_ops( cOpst )

            SELECT opsld

            IF !ld_ima_u_ops_porez_ili_doprinos( "POR", POR->id )
               SKIP 1
               LOOP

            ENDIF

            IF cAlgoritam == "S"

               ?U idops, ops->naz

               nPom := 0

               DO WHILE !Eof() .AND. porid == cSeek .AND. id == por->poopst .AND. idops == cOpst

                  IF t_iz_1 <> 0
                     ? " -obracun za stopu "
                     @ PRow(), PCol() + 1 SAY t_st_1 PICT "99.99%"
                     @ PRow(), PCol() + 1 SAY "="
                     @ PRow(), PCol() + 1 SAY t_iz_1 PICT gpici
                  ENDIF

                  IF t_iz_2 <> 0
                     ? " -obracun za stopu "
                     @ PRow(), PCol() + 1 SAY t_st_2 PICT "99.99%"
                     @ PRow(), PCol() + 1 SAY "="
                     @ PRow(), PCol() + 1 SAY t_iz_2 PICT gpici
                  ENDIF

                  IF t_iz_3 <> 0
                     ? " -obracun za stopu "
                     @ PRow(), PCol() + 1 SAY t_st_3 PICT "99.99%"
                     @ PRow(), PCol() + 1 SAY "="
                     @ PRow(), PCol() + 1 SAY t_iz_3 PICT gpici
                  ENDIF

                  IF t_iz_4 <> 0
                     ? " -obracun za stopu "
                     @ PRow(), PCol() + 1 SAY t_st_4 PICT "99.99%"
                     @ PRow(), PCol() + 1 SAY "="
                     @ PRow(), PCol() + 1 SAY t_iz_4 PICT gpici
                  ENDIF

                  IF t_iz_5 <> 0
                     ? " -obracun za stopu "
                     @ PRow(), PCol() + 1 SAY t_st_5 PICT "99.99%"
                     @ PRow(), PCol() + 1 SAY "="
                     @ PRow(), PCol() + 1 SAY t_iz_5 PICT gpici
                  ENDIF

                  nPom += t_iz_1
                  nPom += t_iz_2
                  nPom += t_iz_3
                  nPom += t_iz_4
                  nPom += t_iz_5

                  SKIP

               ENDDO

               @ PRow(), PCol() + 1 SAY "UK="
               @ PRow(), PCol() + 1 SAY nPom PICT gPici

               rekap_ld( "POR" + por->id + idops, nGodina, nMjesec, nPom, iznos, idops, NLjudi() )

            ELSE

               ?U idops, ops->naz

               // ovo je osnovica za porez
               nTmpPor := iznos

               IF por->por_tip == "B"
                  // ako je na bruto onda je ovo osnovica
                  nTmpPor := iznos3
               ELSEIF por->por_tip == "R"
                  // ako je na ruke onda je osnovica
                  nTmpPor := iznos5
               ENDIF

               @ PRow(), nC1 SAY nTmpPor PICTURE gpici

               // osnovica ne moze biti negativna
               IF nTmpPor < 0
                  nTmpPor := 0
               ENDIF

               nPom := round2( Max( por->dlimit, por->iznos / 100 * nTmpPor ), gZaok2 )

               @ PRow(), PCol() + 1 SAY nPom PICT gpici

               IF cUmPD == "D"
                  @ PRow(), PCol() + 1 SAY nPom2 := round2( Max( por->dlimit, por->iznos / 100 * piznos ), gZaok2 ) PICT gpici
                  @ PRow(), PCol() + 1 SAY nPom - nPom2 PICT gpici

                  rekap_ld( "POR" + por->id + idops, nGodina, nMjesec, nPom - nPom2, 0, idops, NLjudi() )
                  nPorOps2 += nPom2
               ELSE

                  rekap_ld( "POR" + por->id + idops, nGodina, nMjesec, nPom, nTmpPor, idops, NLjudi() )
               ENDIF

            ENDIF

            nOOP += nTmpPor

            nOsnova += nTmpPor

            nPOLjudi += ljudi
            nPorOps += nPom

            IF cAlgoritam <> "S"
               SKIP
            ENDIF

            IF PRow() > ( 64 + dodatni_redovi_po_stranici() )
               // FF
            ENDIF

         ENDDO
         select_o_por()

         ? cLinija

         nPor += nPorOps
         nPor2 += nPorOps2

      ENDIF

      IF !Empty( poopst )

         ? _l( "Ukupno po ops.:" )

         @ PRow(), nC1 SAY nOOP PICT gpici
         @ PRow(), PCol() + 1 SAY nPorOps   PICT gpici

         IF cUmPD == "D"
            @ PRow(), PCol() + 1 SAY nPorOps2   PICT gpici
            @ PRow(), PCol() + 1 SAY nPorOps - nPorOps2   PICT gpici
            rekap_ld( "POR" + por->id, nGodina, nMjesec, nPorOps - nPorOps2, 0,, NLjudi() )
         ELSE
            rekap_ld( "POR" + por->id, nGodina, nMjesec, nPorOps, nOOP,, "(" + AllTrim( Str( nPOLjudi ) ) + ")" )
         ENDIF

         ? cLinija
      ELSE

         nTmpOsnova := nUNeto
         IF por->por_tip == "B"
            nTmpOsnova := nUPorOsnova
         ELSEIF por->por_tip == "R"
            nTmpOsnova := nUPorNROsnova
         ENDIF

         IF nTmpOsnova < 0
            nTmpOsnova := 0
         ENDIF

         nOsnova := nTmpOsnova

         @ PRow(), nC1 SAY nTmpOsnova PICT gpici
         @ PRow(), PCol() + 1 SAY nPom := round2( Max( dlimit, iznos / 100 * nTmpOsnova ), gZaok2 ) PICT gpici
         IF cUmPD == "D"
            @ PRow(), PCol() + 1 SAY nPom2 := round2( Max( dlimit, iznos / 100 * nUNeto2 ), gZaok2 ) PICT gpici
            @ PRow(), PCol() + 1 SAY nPom - nPom2 PICT gpici
            rekap_ld( "POR" + por->id, nGodina, nMjesec, nPom - nPom2, 0 )
            nPor2 += nPom2
         ELSE
            rekap_ld( "POR" + por->id, nGodina, nMjesec, nPom, nTmpOsnova,, "(" + AllTrim( Str( nLjudi ) ) + ")" )
         ENDIF

         nPor += nPom
      ENDIF

      SKIP
   ENDDO

   ? cLinija
   ? _l( "Ukupno Porez" )
   @ PRow(), nC1 SAY Space( Len( gpici ) )
   @ PRow(), PCol() + 1 SAY nPor - nUPorOl PICT gpici

   IF cUmPD == "D"
      @ PRow(), PCol() + 1 SAY nPor2              PICT gpici
      @ PRow(), PCol() + 1 SAY nPor - nUPorOl - nPor2 PICT gpici
   ENDIF

   ? cLinija

   RETURN nOsnova



// ----------------------------------------------------
// izracunaj porez na osnovu tipa
// ----------------------------------------------------
FUNCTION izr_porez( nOsnovica, cTipPor )

   LOCAL nPor
   LOCAL nPom
   LOCAL nPorOl
   LOCAL cAlgoritam
   LOCAL aPor

   IF cTipPor == nil
      cTipPor := ""
   ENDIF

   o_por()

   select_o_por()
   GO TOP

   nPom := 0
   nPor := 0
   nPorOl := 0

   DO WHILE !Eof()

      // vrati algoritam poreza
      cAlgoritam := get_algoritam()

      ld_opstina_stanovanja_rada( POR->poopst )

      IF !ld_ima_u_ops_porez_ili_doprinos( "POR", POR->id )
         SKIP 1
         LOOP
      ENDIF

      // sracunaj samo poreze na bruto
      IF !Empty( cTipPor ) .AND. por->por_tip <> cTipPor
         SKIP
         LOOP
      ENDIF

      // obracunaj porez
      aPor := obr_por( por->id, nOsnovica, 0 )

      nTmp := isp_por( aPor, cAlgoritam, "", .F., .T. )

      IF nTmp < 0
         nTmp := 0
      ENDIF

      nPor += nTmp

      SKIP 1

   ENDDO

   select_o_por()
   GO TOP

   RETURN nPor
