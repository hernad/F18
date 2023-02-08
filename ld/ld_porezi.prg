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

MEMVAR cLinija

/*

   ld_obr_porez( "R", nGodina, nMjesec, nNetoIspl, @nUkPorNeto) //, @nUPorOl )
   ld_obr_porez( "B", nGodina, nMjesec, @nPorOsnovaBruto, @nUkPorBruto) //, @nUPorOl )

*/

FUNCTION ld_obr_porez(cTipPor, nGodina, nMjesec, nUkPorOsnovica, nUkPorez) //, nUPorOl )

   LOCAL cSeek, nC1, nPorez
   LOCAL cAlgoritam := ""
   LOCAL nOsnova := 0
   LOCAL nPorOsnovica, nUkLjudiPoOpst
   LOCAL nTmpOsnova

   IF cTipPor == nil
      cTipPor := ""
   ENDIF

   // cTipPor = "B" - porez na bruto

   select_o_por()
   GO TOP

   nUkPorez := 0
   //nPor2 := 0

   //nPorOps2 := 0
   nC1 := 20

   cLinija := "----------------------- -------- ----------- -----------"

   //IF cUmPDNeKontamStajeOvoVazdajeN == "D"
   //   m += " ----------- -----------"
   //ENDIF

   //IF cUmPDNeKontamStajeOvoVazdajeN == "D"
   //   P_12CPI
   //   ? "----------------------- -------- ----------- ----------- ----------- -----------"
   //   ? _l( "                                 Obracunska     Porez    Preplaceni     Porez   " )
   //   ? _l( "     Naziv poreza          %      osnovica   po obracunu    porez     za uplatu " )
   //   ? "          (1)             (2)        (3)     (4)=(2)*(3)     (5)     (6)=(4)-(5)"
   //   ? "----------------------- -------- ----------- ----------- ----------- -----------"
   //ENDIF

   DO WHILE !Eof() // vrti kroz poreze

      cAlgoritam := ld_get_por_algoritam()

      // ako to nije taj tip poreza preskoci
      IF !Empty( cTipPor )
         IF por->por_tip <> cTipPor
            SKIP
            LOOP
         ENDIF
      ENDIF

      IF PRow() > ( 64 + dodatni_redovi_po_stranici() )
         // FF
      ENDIF

      ? por->id, "-", por->naz

      IF cAlgoritam == "S" // stepenasti obracun
         @ PRow(), PCol() + 1 SAY "st.por"
      ELSE
         @ PRow(), PCol() + 1 SAY por->iznos PICT "99.99%"
      ENDIF

      nC1 := PCol() + 1

      IF !Empty( por->poopst )

         IF por->poopst == "1"
            ?? _l( " (po opst.stan)" )
         ELSEIF por->poopst == "2"
            ?? _l( " (po opst.stan)" )
         ELSEIF por->poopst == "3"
            ?? _l( " (po kant.stan)" )
         ELSEIF por->poopst == "4"
            ?? _l( " (po kant.rada)" )
         ELSEIF por->poopst == "5"
            ?? _l( " (po ent. stan)" )
         ELSEIF por->poopst == "6"
            ?? _l( " (po ent. rada)" )
            ?? _l( " (po opst.rada)" )
         ENDIF

         // ukupna Osnovica za Obracun Poreza za po opstinama
         nUkPorOsnovica := 0
         // ukup.ljudi za po opstinama
         nUkLjudiPoOpst := 0
         

         nUkPorez := 0
         // ovaj je vazda 0 nPorOps2
         //nPorOps2 := 0

         IF cAlgoritam == "S" // stepenasti obracun
            cSeek := por->id
         ELSE
            cSeek := Space( 2 )
         ENDIF

         SELECT opsld
         SEEK cSeek + por->poopst // opsld tmp

         ? StrTran( cLinija, "-", "=" )

         DO WHILE !Eof() .AND. opsld->porid == cSeek .AND. opsld->id == por->poopst

            cOpst := opsld->idops

            select_o_ops( cOpst )
            SELECT opsld

            IF !ld_ima_u_ops_porez_ili_doprinos( "POR", POR->id )
               SKIP 1
               LOOP
            ENDIF

            IF cAlgoritam == "S" // stepenasti obracun

               ?U opdld->idops, ops->naz
               nPom := 0

               DO WHILE !Eof() .AND. opsld->porid == cSeek .AND. id == por->poopst .AND. opsld->idops == cOpst

                  IF opsld->t_iz_1 <> 0
                     ? " -obracun za stopu "
                     @ PRow(), PCol() + 1 SAY opsld->t_st_1 PICT "99.99%"
                     @ PRow(), PCol() + 1 SAY "="
                     @ PRow(), PCol() + 1 SAY opsld->t_iz_1 PICT gpici
                  ENDIF

                  IF opsld->t_iz_2 <> 0
                     ? " -obracun za stopu "
                     @ PRow(), PCol() + 1 SAY opsld->t_st_2 PICT "99.99%"
                     @ PRow(), PCol() + 1 SAY "="
                     @ PRow(), PCol() + 1 SAY opsld->t_iz_2 PICT gpici
                  ENDIF

                  IF opsld->t_iz_3 <> 0
                     ? " -obracun za stopu "
                     @ PRow(), PCol() + 1 SAY opsld->t_st_3 PICT "99.99%"
                     @ PRow(), PCol() + 1 SAY "="
                     @ PRow(), PCol() + 1 SAY opsld->t_iz_3 PICT gpici
                  ENDIF

                  IF opsld->t_iz_4 <> 0
                     ? " -obracun za stopu "
                     @ PRow(), PCol() + 1 SAY opsld->t_st_4 PICT "99.99%"
                     @ PRow(), PCol() + 1 SAY "="
                     @ PRow(), PCol() + 1 SAY opsld->t_iz_4 PICT gpici
                  ENDIF

                  IF opsld->t_iz_5 <> 0
                     ? " -obracun za stopu "
                     @ PRow(), PCol() + 1 SAY opsld->t_st_5 PICT "99.99%"
                     @ PRow(), PCol() + 1 SAY "="
                     @ PRow(), PCol() + 1 SAY opsld->t_iz_5 PICT gpici
                  ENDIF

                  nPom += opsld->t_iz_1
                  nPom += opsld->t_iz_2
                  nPom += opsld->t_iz_3
                  nPom += opsld->t_iz_4
                  nPom += opsld->t_iz_5

                  SKIP

               ENDDO

               @ PRow(), PCol() + 1 SAY "UK="
               @ PRow(), PCol() + 1 SAY nPom PICT gPici

               ld_rekap_ld( "POR" + por->id + opsld->idops, nGodina, nMjesec, nPom, iznos, opsld->idops, ld_opsld_ljudi() )

            ELSE // cAlgoritam nije "S"

               ?U opsld->idops, ops->naz

               IF por->por_tip == "B" // ako je na bruto onda je ovo osnovica
                  nPorOsnovica := opsld->iznos3
               ELSEIF por->por_tip == "R" // ako je na ruke onda je osnovica
                  nPorOsnovica := opsld->iznos5
               ENDIF

               @ PRow(), nC1 SAY nPorOsnovica PICTURE gpici

               // osnovica ne moze biti negativna
               IF nPorOsnovica < 0
                  nPorOsnovica := 0
               ENDIF

               nPorez := round2( Max( por->dlimit, por->iznos / 100 * nPorOsnovica ), gZaok2 )
               @ PRow(), PCol() + 1 SAY nPorez PICT gpici

               //IF cUmPDNeKontamStajeOvoVazdajeN == "D"
               //   @ PRow(), PCol() + 1 SAY nPom2 := round2( Max( por->dlimit, por->iznos / 100 * piznos ), gZaok2 ) PICT gpici
               //   @ PRow(), PCol() + 1 SAY nPom - nPom2 PICT gpici
               //
               //   ld_rekap_ld( "POR" + por->id + idops, nGodina, nMjesec, nPom - nPom2, 0, idops, ld_opsld_ljudi() )
               //   nPorOps2 += nPom2
               //ELSE

                  ld_rekap_ld( "POR" + por->id + opsld->idops, nGodina, nMjesec, nPorez, nPorOsnovica, opsld->idops, ld_opsld_ljudi() )
               //ENDIF

            ENDIF

            nUkPorOsnovica += nPorOsnovica
            //nOsnova += nPorOsnovica
            nUkLjudiPoOpst += opsld->ljudi
            nUkPorez += nPorez

            IF cAlgoritam <> "S"
               SKIP
            ENDIF

            IF PRow() > ( 64 + dodatni_redovi_po_stranici() )
               // FF
            ENDIF

         ENDDO
         select_o_por()

         ? cLinija

         //nUkPorez += nUkPorez
         //nPor2 += nPorOps2

         ? _l( "Ukupno po ops.:" )
         @ PRow(), nC1 SAY nUkPorOsnovica PICT gpici
         @ PRow(), PCol() + 1 SAY nUkPorez   PICT gpici

         //IF cUmPDNeKontamStajeOvoVazdajeN == "D"
         //   @ PRow(), PCol() + 1 SAY nPorOps2   PICT gpici
         //   @ PRow(), PCol() + 1 SAY nUkPorez - nPorOps2   PICT gpici
         //   ld_rekap_ld( "POR" + por->id, nGodina, nMjesec, nUkPorez - nPorOps2, 0,, ld_opsld_ljudi() )
         //ELSE
            ld_rekap_ld( "POR" + por->id, nGodina, nMjesec, nUkPorez, nUkPorOsnovica, NIL, "(" + AllTrim( Str( nUkLjudiPoOpst ) ) + ")" )
         //ENDIF

         ? cLinija

      ELSE // Empty( por->poopst )

         //nTmpOsnova := nUNeto
         //IF por->por_tip == "B"
         //nTmpOsnova := nUkPorOsnovica
         //ELSEIF por->por_tip == "R"
         //   nTmpOsnova := nUkPorNaRukeOsnova
         //ENDIF
         // port_tip == "R" vodne naknade
         IF nUkPorOsnovica < 0
            nUkPorOsnovica := 0
         ENDIF

         //nUkPorOsnovica := nTmpOsnova
         @ PRow(), nC1 SAY nUkPorOsnovica PICT gpici
         @ PRow(), PCol() + 1 SAY nPorez := round2( Max( dlimit, por->iznos / 100 * nUkPorOsnovica ), gZaok2 ) PICT gpici
         //IF cUmPDNeKontamStajeOvoVazdajeN == "D"
         //   @ PRow(), PCol() + 1 SAY nPom2 := round2( Max( dlimit, iznos / 100 * nUNeto2 ), gZaok2 ) PICT gpici
         //   @ PRow(), PCol() + 1 SAY nPom - nPom2 PICT gpici
         //   ld_rekap_ld( "POR" + por->id, nGodina, nMjesec, nPom - nPom2, 0 )
         //   nPor2 += nPom2
         //ELSE
            ld_rekap_ld( "POR" + por->id, nGodina, nMjesec, nPorez, nUkPorOsnovica, NIL, "(" + AllTrim( Str( nLjudi ) ) + ")" )
         //ENDIF

         nUkPorez += nPorez
      ENDIF

      SKIP
   ENDDO

   ? cLinija
   IF cTipPor == "B"
      ?  "Ukupno Porez"
   ELSE
      ?  "Ukupno Porez[N]"
   ENDIF
   @ PRow(), nC1 SAY Space( Len( gpici ) )
   @ PRow(), PCol() + 1 SAY nUkPorez  PICT gpici //- nUPorOl PICT gpici

   //IF cUmPDNeKontamStajeOvoVazdajeN == "D"
   //   @ PRow(), PCol() + 1 SAY nPor2              PICT gpici
   //   @ PRow(), PCol() + 1 SAY nUkPorez - nUPorOl - nPor2 PICT gpici
   //ENDIF

   ? cLinija

   RETURN nUkPorOsnovica



// ----------------------------------------------------
// izracunaj porez na osnovu tipa
// ----------------------------------------------------
FUNCTION ld_izr_porez( nOsnovica, cTipPor )

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
      cAlgoritam := ld_get_por_algoritam()

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
      aPor := ld_obr_por( por->id, nOsnovica, 0 )

      nTmp := ld_ispis_poreza( aPor, cAlgoritam, "", .F., .T. )

      IF nTmp < 0
         nTmp := 0
      ENDIF

      nPor += nTmp

      SKIP 1

   ENDDO

   select_o_por()
   GO TOP

   RETURN nPor
