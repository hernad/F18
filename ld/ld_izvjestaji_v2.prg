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


FUNCTION ld_pregled_primanja_za_period()

   LOCAL nC1 := 20

   cIdRadn := Space( 6 )
   cIdRj := gLDRadnaJedinica
   nGodina := ld_tekuca_godina()
   cObracun := gObracun

   o_ld_rj()
   o_ld_radn()
   // select_o_ld()

   PRIVATE cTip := "  "
   cDod := "N"
   cKolona := Space( 20 )
   Box(, 6, 75 )
   cMjesecOd := cMjesecDo := ld_tekuci_mjesec()
   @ box_x_koord() + 1, box_y_koord() + 2 SAY "Radna jedinica (prazno-sve): "  GET cIdRJ
   @ box_x_koord() + 2, box_y_koord() + 2 SAY "Mjesec od: "  GET  cMjesecOd  PICT "99"
   @ box_x_koord() + 2, Col() + 2 SAY "do" GET cMjesecDO  PICT "99"
   IF ld_vise_obracuna()
      @ box_x_koord() + 2, Col() + 2 SAY "Obracun:" GET cObracun WHEN ld_help_broj_obracuna( .T., cObracun ) VALID ld_valid_obracun( .T., cObracun )
   ENDIF
   @ box_x_koord() + 3, box_y_koord() + 2 SAY "Godina: "  GET  nGodina  PICT "9999"
   @ box_x_koord() + 4, box_y_koord() + 2 SAY "Tip primanja: "  GET  cTip
   @ box_x_koord() + 5, box_y_koord() + 2 SAY "Prikaz dodatnu kolonu: "  GET  cDod PICT "@!" VALID cdod $ "DN"
   read; clvbox(); ESC_BCR
   IF cDod == "D"
      @ box_x_koord() + 6, box_y_koord() + 2 SAY "Naziv kolone:" GET cKolona
      READ
   ENDIF
   fRacunaj := .F.
   IF Left( cKolona, 1 ) = "="
      fRacunaj := .T.
      ckolona := StrTran( cKolona, "=", "" )
   ELSE
      ckolona := "radn->" + ckolona
   ENDIF
   BoxC()

   set_tippr_ili_tippr2( cObracun )


   select_o_tippr( cTip )
   EOF CRET

   seek_ld( NIL, nGodina, NIL, NIL, NIL,  "4" )  // seek_ld( cIdRj, nGodina, nMjesec, cObracun, cIdRadn, cTag )

   IF ld_vise_obracuna() .AND. !Empty( cObracun )
      SET FILTER TO obr == cObracun

   ENDIF

   // SET ORDER TO TAG ( ld_index_tag_vise_obracuna( "4" ) )
   // HSEEK Str( nGodina, 4 )
   //SET ORDER TO TAG "4"
   GO TOP

   EOF CRET

   nStrana := 0
   m := "----- ------ ---------------------------------- " + "-" + REPL( "-", Len( gPicS ) ) + " ----------- -----------"
   IF cdod == "D"
      IF Type( ckolona ) $ "UUIUE"
         Msg( "Nepostojeca kolona" )
         closeret
      ENDIF
   ENDIF
   bZagl := {|| ZPregPrimPer() }

   select_o_ld_rj( ld->idrj )
   SELECT ld

   START PRINT CRET
   P_10CPI

   Eval( bZagl )

   nRbr := 0
   nT1 := nT2 := nT3 := nT4 := 0
   nC1 := 10

   DO WHILE !Eof() .AND.  nGodina == godina

      IF PRow() > RPT_PAGE_LEN
         FF; Eval( bZagl )
      ENDIF


      cIdRadn := idradn

      select_o_radn( cIdRadn )
      SELECT ld

      wi&cTip := 0
      ws&cTip := 0

      IF fracunaj
         nKolona := 0
      ENDIF
      DO WHILE  !Eof() .AND. nGodina == godina .AND. idradn == cIdradn
         Scatter()
         IF !Empty( cidrj ) .AND. _idrj <> cidrj
            skip; LOOP
         ENDIF
         IF cMjesecod > _mjesec .OR. cMjesecdo < _mjesec
            skip; LOOP
         ENDIF
         wi&cTip += _I&cTip
         IF !( ld_vise_obracuna() .AND. Empty( cObracun ) .AND. _obr <> "1" )
            ws&cTip += _S&cTip
         ENDIF
         IF fRacunaj
            nKolona += &cKolona
         ENDIF
         SKIP
      ENDDO

      IF wi&cTip <> 0 .OR. ws&cTip <> 0
         ? Str( ++nRbr, 4 ) + ".", cIdradn, RADNIK_PREZ_IME
         nC1 := PCol() + 1
         IF tippr->fiksan == "P"
            @ PRow(), PCol() + 1 SAY ws&cTip  PICT "999.99"
         ELSE
            @ PRow(), PCol() + 1 SAY ws&cTip  PICT gpics
         ENDIF
         @ PRow(), PCol() + 1 SAY wi&cTip  PICT gpici
         nT1 += ws&cTip; nT2 += wi&cTip
         IF cdod == "D"
            IF fracunaj
               @ PRow(), PCol() + 1 SAY nKolona PICT gpici
            ELSE
               @ PRow(), PCol() + 1 SAY &ckolona
            ENDIF
         ENDIF

      ENDIF

      SELECT ld
   ENDDO

   IF PRow() > 60; FF; Eval( bZagl ); ENDIF
   ? m
   ? " UKUPNO:"
   @ PRow(), nC1 SAY  nT1 PICT gpics
   @ PRow(), PCol() + 1 SAY  nT2 PICT gpici
   ? m
   ?
   ? p_potpis()

   FF
   ENDPRINT
   my_close_all_dbf()

   RETURN .T.




FUNCTION TekRec()

   @ box_x_koord() + 1, box_y_koord() + 2 SAY RecNo()

   RETURN NIL


FUNCTION ObrM4()

   CLOSERET

   RETURN .T.


FUNCTION ZPregPrimPer()

   P_12CPI
   ? Upper( Trim( tip_organizacije() ) ) + ":", self_organizacija_naziv()
   ?
   ? "Pregled primanja za period od", cMjesecOd, "do", cMjesecDo, "mjesec " + IspisObr()
   ?? nGodina
   ?
   IF Empty( cIdRj )
      ? "Pregled za sve RJ ukupno:"
   ELSE
      ? "RJ:", cIdRj, ld_rj->naz
   ENDIF
   ?? Space( 4 ), "Str.", Str( ++nStrana, 3 )
   ?
   ? "Pregled za tip primanja:", ctip, tippr->naz

   ? m
   ? " Rbr  Sifra           Naziv radnika               " + iif( tippr->fiksan == "P", " %  ", "Sati" ) + "      Iznos"
   ? m

FUNCTION ZSRO()

   P_COND
   ? Upper( tip_organizacije() ) + ":", self_organizacija_naziv()
   ?
   IF Empty( cidrj )
      ? "Pregled za sve RJ ukupno:"
   ELSE
      ? "RJ:", cidrj, ld_rj->naz
   ENDIF
   ?? "  Mjesec:", Str( nMjesec, 2 ) + IspisObr()
   ?? "    Godina:", Str( nGodina, 5 )
   DevPos( PRow(), 74 )
   ?? "Str.", Str( ++nStrana, 3 )
   IF !Empty( cvposla )
      ? "Vrsta posla:", cvposla, "-", vposla->naz
   ENDIF
   IF !Empty( cKBenef )
      ? "Stopa beneficiranog r.st:", ckbenef, "-", kbenef->naz, ":", kbenef->iznos
   ENDIF
   ? m
   ? " Rbr * Sifra*         Naziv radnika            *  Sati *   Neto    *  Odbici   * ZA ISPLATU*"
   ? "     *      *                                  *       *           *           *           *"
   ? m

   RETURN .T.



FUNCTION SortOpSt( cId )

   LOCAL cVrati := "", nArr := Select()

   select_o_radn( cId )
   cVrati := field->IdOpsSt
   SELECT ( nArr )

   RETURN cVrati



FUNCTION IzracDopr( cDopr, nKLO, cTipRada, nSpr_koef )

   LOCAL nArr := Select(), nDopr := 0, nPom := 0, nPom2 := 0, nPom0 := 0, nBrutoOsnova := 0, nBFOsn := 0
   LOCAL aBeneficirani := {}

   IF nKLO == nil
      nKLO := 0
   ENDIF

   IF cTipRada == nil
      cTipRada := ""
   ENDIF

   IF nSPr_koef == nil
      nSPr_koef := 0
   ENDIF

   ld_pozicija_parobr( mjesec, godina, IF( ld_vise_obracuna(), cObracun, ), cIdRj )

   IF gVarObracun == "2"

      nBrutoOsnova := ld_get_bruto_osnova( Max( _UNeto, PAROBR->prosld * gPDLimit / 100 ), cTipRada, nKlo, nSPr_koef )

      IF is_radn_k4_bf_ide_u_benef_osnovu()

         IF !Empty( gBFForm )
            gBFForm := StrTran( gBFForm, "_", "" )
         ENDIF

         nBFOsn := ld_get_bruto_osnova( _UNeto - IF( !Empty( gBFForm ), &gBFForm, 0 ), cTipRada, nKlo, nSPr_koef )

         add_to_a_benef( @aBeneficirani, AllTrim( radn->k3 ), ld_beneficirani_stepen(), nBFOsn )

      ENDIF

      IF cTipRada $ " #I#N"
         // minimalni bruto osnov
         IF ld_calc_min_bruto_yes_no()
            nBrutoOsnova := ld_min_bruto_osnova( nBrutoOsnova, ld->usati )
         ENDIF
      ENDIF

   ELSE
      nBrutoOsnova := round2( parobr->k3 / 100 * Max( _UNeto, PAROBR->prosld * gPDLimit / 100 ), gZaok2 )
   ENDIF

   select_o_dopr()
   GO TOP

   DO WHILE !Eof()

      IF gVarObracun == "2"
         IF cTipRada $ "I#N" .AND. Empty( dopr->tiprada )
            // ovo je uredu !
         ELSEIF dopr->tiprada <> cTipRada
            SKIP 1
            LOOP
         ENDIF
      ENDIF

      IF !( id $ cDopr )
         SKIP 1
         LOOP
      ENDIF

      ld_opstina_stanovanja_rada( DOPR->poopst )   // ? mozda ovo rusi koncepciju zbog sorta na LD-u

      IF !ld_ima_u_ops_porez_ili_doprinos( "DOPR", DOPR->id )
         SKIP 1
         LOOP
      ENDIF

      IF !Empty( dopr->idkbenef )
         // beneficirani
         nPom := Max( dlimit, Round( iznos / 100 * get_benef_osnovica( aBeneficirani, dopr->idkbenef ), gZaok2 ) )
      ELSE
         nPom := Max( dlimit, Round( iznos / 100 * nBrutoOsnova, gZaok2 ) )
      ENDIF

      IF Round( iznos, 4 ) = 0 .AND. dlimit > 0
         // fuell boss
         // kartica plate
         nPom := 1 * dlimit
      ENDIF

      nDopr += nPom

      // resetuj matricu a_benef, posto nam treba za radnika
      aBeneficirani := {}

      SKIP 1

   ENDDO

   SELECT ( nArr )

   RETURN ( nDopr )


FUNCTION SortPre2()
   RETURN ( RADN->( naz + ime + imerod ) + idradn )
