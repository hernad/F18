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
// vraca ukupno doprinosa IZ plate, 1X
// ------------------------------------------------
FUNCTION u_dopr_iz( nDopOsn, cRTipRada )

   LOCAL nU_dop_iz

   select_o_dopr()
   GO TOP

   nU_dop_iz := 0

   DO WHILE !Eof()

      // provjeri tip rada
      IF Empty( dopr->tiprada ) .AND. cRTipRada $ tr_list()
         // ovo je u redu...
      ELSEIF ( cRTipRada <> dopr->tiprada )
         SKIP
         LOOP
      ENDIF

      // preskoci zbirne doprinose
      IF dopr->id <> "1X"
         SKIP
         LOOP
      ENDIF

      nU_dop_iz += round2( ( iznos / 100 ) * nDopOsn, gZaok2 )

      SKIP 1

   ENDDO

   RETURN nU_dop_iz

// ------------------------------------------------
// vraca ukupno doprinosa NA plate, 2X
// ------------------------------------------------
FUNCTION u_dopr_na( nDopOsn, cRTipRada )

   select_o_dopr()
   GO TOP

   nU_dop_na := 0

   DO WHILE !Eof()

      // provjeri tip rada
      IF Empty( dopr->tiprada ) .AND. cRTipRada $ tr_list()
         // ovo je u redu...
      ELSEIF ( cRTipRada <> dopr->tiprada )
         SKIP
         LOOP
      ENDIF

      // preskoci zbirne doprinose
      IF dopr->id <> "2X"
         SKIP
         LOOP
      ENDIF

      nU_dop_na += round2( ( iznos / 100 ) * nDopOsn, gZaok2 )

      SKIP 1

   ENDDO

   RETURN nU_dop_na




FUNCTION obr_doprinos( nGodina, nMjesec, nDopr, nDopr2, cTRada, a_benef )

   LOCAL nIznos := 0

   IF cTRada == nil
      cTRada := " "
   ENDIF

   IF a_benef == NIL
      a_benef := {}
   ENDIF

   m := "----------------------- -------- ----------- -----------"

   IF cUmPD == "D"
      m += " ----------- -----------"
   ENDIF

   select_o_dopr()
   GO TOP

   nPom := 0
   nDopr := 0
   nPom2 := 0
   nDopr2 := 0
   nC1 := 20
   nDoprIz := 0

   IF cUmPD == "D"

      ? "----------------------- -------- ----------- ----------- ----------- -----------"
      ? _l( "                                 Obracunska   Doprinos   Preplaceni   Doprinos  " )
      ? _l( "    Naziv doprinosa        %      osnovica   po obracunu  doprinos    za uplatu " )
      ? "          (1)             (2)        (3)     (4)=(2)*(3)     (5)     (6)=(4)-(5)"
      ? "----------------------- -------- ----------- ----------- ----------- -----------"

   ENDIF

   DO WHILE !Eof()

      IF gVarObracun == "2"
         IF Empty( dopr->tiprada ) .AND. cRTipRada $ tr_list()
            // ovo je ok
         ELSEIF dopr->tiprada <> cRTipRada
            SKIP
            LOOP
         ENDIF
      ENDIF

      IF Right( id, 1 ) == "X"
         ? cLinija
      ENDIF

      ? "  " + id, "-", naz
      @ PRow(), PCol() + 1 SAY iznos PICT "99.99%"

      nC1 := PCol() + 1

      IF Empty( field->idkbenef )

         IF !Empty( field->poopst )

            IF poopst == "1"
               ?? _l( " (po opst.stan)" )
            ELSEIF poopst == "2"
               ?? _l( " (po opst.rada)" )
            ELSEIF poopst == "3"
               ?? _l( " (po kant.stan)" )
            ELSEIF poopst == "4"
               ?? _l( " (po kant.rada)" )
            ELSEIF poopst == "5"
               ?? _l( " (po ent. stan)" )
            ELSEIF poopst == "6"
               ?? _l( " (po ent. rada)" )
            ENDIF

            ? StrTran( m, "-", "=" )

            nOOD := 0 // ukup.osnovica za obr.doprinosa za po opstinama

            nPOLjudi := 0 // ukup.ljudi za po opstinama

            nDoprOps := 0
            nDoprOps2 := 0

            SELECT opsld
            SEEK Space( 2 ) + dopr->poOpst // opsld tmp

            DO WHILE !Eof() .AND. field->id == dopr->poopst .AND. field->porid == Space( 2 )

               select_o_ops( opsld->idops )

               SELECT opsld

               IF !ld_ima_u_ops_porez_ili_doprinos( "DOPR", DOPR->id )
                  SKIP 1
                  LOOP
               ENDIF

               ?U "  " + field->idops, ops->naz

               IF dopr->( FieldPos( "DOP_TIP" ) ) <> 0
                  IF dopr->dop_tip == "N" .OR.  dopr->dop_tip == " "
                     nIznos := iznos
                  ELSEIF dopr->dop_tip == "2"
                     nIznos := izn_ost
                  ELSEIF dopr->dop_tip == "P"
                     nIznos := iznos + izn_ost
                  ENDIF
               ELSE
                  nIznos := iznos
               ENDIF

               IF gVarObracun == "2"
                  nBOOps := br_osn
                  IF ops->reg == "2" .AND. cTRada $ "A#U"
                     nBOOps := 0
                  ENDIF
               ELSE
                  nBOOps := ld_get_bruto_osnova( nIznos, cRTipRada, nKoefLO )
               ENDIF

               @ PRow(), nC1 SAY nBOOps PICTURE gpici

               nPom := round2( Max( dopr->dlimit, dopr->iznos / 100 * nBOOps ), gZaok2 )

               IF cUmPD == "D"
                  nBOOps2 := round2( piznos * nPK3 / 100, gZaok2 )
                  nPom2 := round2( Max( dopr->dlimit, dopr->iznos / 100 * nBOOps2 ), gZaok2 )
               ENDIF

               IF Round( dopr->iznos, 4 ) = 0 .AND. dopr->dlimit > 0

                  nPom := dopr->dlimit * opsld->ljudi

                  IF cUmPD == "D"
                     nPom2 := dopr->dlimit * opsld->pljudi
                  ENDIF
               ENDIF

               @ PRow(), PCol() + 1 SAY nPom PICTURE gPici

               IF cUmPD == "D"

                  @ PRow(), PCol() + 1 SAY  nPom2 PICTURE gPici
                  @ PRow(), PCol() + 1 SAY  nPom - nPom2 PICTURE gPici

                  rekap_ld( "DOPR" + dopr->id + idops, nGodina, nMjesec, nPom - nPom2, 0, idops, NLjudi() )
                  nDoprOps2 += nPom2
                  nDoprOps += nPom

               ELSE

                  rekap_ld( "DOPR" + dopr->id + opsld->idops, nGodina, nMjesec, npom, nBOOps, idops, NLjudi() )
                  nDoprOps += nPom
               ENDIF

               nOOD += nBOOps
               nPOLjudi += ljudi

               SKIP

            ENDDO

            select_o_dopr()

            ? cLinija
            ? "  " + "UKUPNO" + Space( 1 ), DOPR->ID

            @ PRow(), nC1 SAY nOOD PICT gpici
            @ PRow(), PCol() + 1 SAY nDoprOps PICT gpici

            IF cUmPD == "D"

               @ PRow(), PCol() + 1 SAY nDoprOps2 PICT gpici
               @ PRow(), PCol() + 1 SAY nDoprOps - nDoprOps2 PICT gpici
               rekap_ld( "DOPR" + dopr->id, nGodina, nMjesec, nDoprOps - nDoprOps2, 0,, NLjudi() )
               nPom2 := nDoprOps2
            ELSE
               IF nDoprOps > 0
                  rekap_ld( "DOPR" + dopr->id, nGodina, nMjesec, nDoprOps, nOOD,, "(" + AllTrim( Str( nPOLjudi ) ) + ")" )
               ENDIF
            ENDIF

            IF dopr->id == "1X"
               IF ops->reg == "2" .AND. cTRada $ "A#U"
                  nPom := 0
               ENDIF
               nUDoprIz += nPom
            ENDIF

            ? cLinija

            nPom := nDoprOps

         ELSE

            IF dopr->( FieldPos( "DOP_TIP" ) ) <> 0  // doprinosi nisu po opstinama
               IF dopr->dop_tip == "N" .OR. dopr->dop_tip == " "
                  nTmpOsn := nUNetoOsnova
               ELSEIF dopr->dop_tip == "2"
                  nTmpOsn := nDoprOsnOst
               ELSEIF dopr->dop_tip == "P"
                  nTmpOsn := nDoprOsnova + nDoprOsnOst
               ENDIF
            ELSE
               nTmpOsn := nDoprOsnova
            ENDIF

            IF gVarObracun == "2"

               nBo := nUMRadn_bo

            ELSE
               nBO := ld_get_bruto_osnova( nTmpOsn, cRTipRada, nKoefLO )
            ENDIF

            @ PRow(), nC1 SAY nBO PICT gpici

            nPom := round2( Max( dlimit, iznos / 100 * nBO ), gZaok2 )

            IF dopr->id == "1X"
               nUDoprIz += nPom
            ENDIF

            IF cUmPD == "D"
               nPom2 := round2( Max( dlimit, iznos / 100 * nBO2 ), gZaok2 )
            ENDIF

            IF Round( iznos, 4 ) = 0 .AND. dlimit > 0
               nPom := dlimit * nljudi
               // nije po opstinama
               IF cUmPD == "D"
                  nPom2 := dlimit * nljudi
                  // nije po opstinama ?!?nLjudi
               ENDIF
            ENDIF
            @ PRow(), PCol() + 1 SAY nPom PICT gpici
            IF cUmPD == "D"
               @ PRow(), PCol() + 1 SAY nPom2 PICT gpici
               @ PRow(), PCol() + 1 SAY nPom - nPom2 PICT gpici
               rekap_ld( "DOPR" + dopr->id, nGodina, nMjesec, nPom - nPom2, 0 )
            ELSE
               rekap_ld( "DOPR" + dopr->id, nGodina, nMjesec, nPom, nBO,, "(" + AllTrim( Str( nLjudi ) ) + ")" )
            ENDIF
         ENDIF

      ELSE

         // beneficirani doprinosi
         nPom2 := get_benef_osnovica( a_benef, idkbenef )

         IF Round2( nPom2, gZaok2 ) <> 0
            @ PRow(), PCol() + 1 SAY nPom2 PICT gpici
            nC1 := PCol() + 1
            @ PRow(), PCol() + 1 SAY nPom := Round2( Max( dlimit, iznos / 100 * nPom2 ), gZaok2 ) PICT gpici
         ENDIF
      ENDIF

      IF Right( id, 1 ) == "X"
         ? cLinija
         ?
         nDopr += nPom
         IF cUmPD == "D"
            nDopr2 += nPom2
         ENDIF
      ENDIF

      SKIP


   ENDDO

   ? cLinija
   ? "  " + _l( "Ukupno Doprinosi" )
   @ PRow(), nc1 SAY Space( Len( gpici ) )
   @ PRow(), PCol() + 1 SAY nDopr  PICT gpici

   IF cUmPD == "D"
      @ PRow(), PCol() + 1 SAY nDopr2  PICT gpici
      @ PRow(), PCol() + 1 SAY nDopr - nDopr2  PICT gpici
   ENDIF

   ? cLinija

   RETURN .T.
