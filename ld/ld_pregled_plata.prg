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

MEMVAR m, nVrstaInvaliditeta, nStepenInvaliditeta, cPom

FUNCTION ld_pregled_plata()

   LOCAL nC1 := 20, i
   LOCAL cPrBruto := "N"

   LOCAL nIznosVanNetaPozitivneStavke, nIznosVanNetaNegativneStavke, nIznosMinuliRad
   LOCAL cIdMinuli
   LOCAL nNetoZaIzbiti, nVanNetoZaIzbiti // ako je neko primanje iz neta, ili van neta stavljeno kao "primanje_out"
   LOCAL nUkupnoRedovanRad, nUkupnoMinuliRad // varijanta izvjestaja 2
   LOCAL nNetoNaRuke, nUkupnoSati, nUkupnoPrimanja, nUkunoNetoPrimanja, nUkupnoZaIsplatu
   LOCAL nUkupnoIznosVanNetaOstaleNaknade, nUkupnoIznosVanNetaOdbici
   LOCAL GetList := {}

   LOCAL hParams := hb_Hash()

   hParams[ "primanja_out" ] := ""

   cIdRadn := Space( LEN_IDRADNIK )
   cIdRj := gLDRadnaJedinica
   nMjesec := ld_tekuci_mjesec()
   nGodina := ld_tekuca_godina()
   cObracun := gObracun
   cVarSort := "2"

   PRIVATE cPom

   // o_koef_beneficiranog_radnog_staza()
   // o_ld_vrste_posla()
   // o_ld_rj()
   // o_dopr()
   // o_por()
   // o_ld_radn()
   // select_o_ld()
   // o_ld_parametri_obracuna()
   o_params()

   PRIVATE cSection := "4"
   PRIVATE cHistory := " "
   PRIVATE aHistory := {}

   RPar( "VS", @cVarSort )
   RPar( "PI", @hParams[ "primanja_out" ] )
   hParams[ "primanja_out" ] := PadR( hParams[ "primanja_out" ], 50 )

   PRIVATE cKBenef := " "
   PRIVATE cVPosla := "  "

   PRIVATE nStepenInvaliditeta := 0
   PRIVATE nVrstaInvaliditeta := 0

   cIdMinuli := "17"
   cKontrola := "N"

   Box(, 17, 75 )
   @ box_x_koord() + 1, box_y_koord() + 2 SAY8 "Radna jedinica (prazno-sve): "  GET cIdRJ
   @ box_x_koord() + 2, box_y_koord() + 2 SAY8 "Mjesec: "  GET  nMjesec  PICT "99"
   IF ld_vise_obracuna()
      @ box_x_koord() + 2, Col() + 2 SAY8 "Obračun:" GET cObracun WHEN ld_help_broj_obracuna( .T., cObracun ) VALID ld_valid_obracun( .T., cObracun )
   ENDIF
   @ box_x_koord() + 3, box_y_koord() + 2 SAY8 "Godina: "  GET  nGodina  PICT "9999"
   @ box_x_koord() + 4, box_y_koord() + 2 SAY8 "Koeficijent benef.radnog staža (prazno-svi): "  GET  cKBenef VALID Empty( cKBenef ) .OR. P_KBenef( @cKBenef )
   @ box_x_koord() + 5, box_y_koord() + 2 SAY8 "Vrsta posla (prazno-svi): "  GET  cVPosla
   @ box_x_koord() + 7, box_y_koord() + 2 SAY8 "Šifra primanja minuli: "  GET  cIdMinuli PICT "@!"
   @ box_x_koord() + 8, box_y_koord() + 2 SAY8 "Sortirati po (1-šifri, 2-prezime+ime)"  GET cVarSort VALID cVarSort $ "12"  PICT "9"
   @ box_x_koord() + 9, box_y_koord() + 2 SAY "Prikaz bruto iznosa ?" GET cPrBruto VALID cPrBruto $ "DN" PICT "@!"
   @ box_x_koord() + 11, box_y_koord() + 2 SAY8 "Kontrola (br.-dopr.-porez)+(prim.van neta)-(odbici)=(za isplatu)? (D/N)" GET cKontrola VALID cKontrola $ "DN" PICT "@!"


   @ box_x_koord() + 13, box_y_koord() + 2 SAY8 "Vrsta invaliditeta (0 sve)  : "  GET  nVrstaInvaliditeta  PICT "9" VALID nVrstaInvaliditeta == 0 .OR. valid_vrsta_invaliditeta( @nVrstaInvaliditeta )
   @ box_x_koord() + 14, box_y_koord() + 2 SAY8 "Stepen invaliditeta (>=)    : "  GET  nStepenInvaliditeta  PICT "999" VALID valid_stepen_invaliditeta( @nStepenInvaliditeta )


   @ box_x_koord() + 16, box_y_koord() + 2 SAY8 "Iz pregleda izbaciti slijedeća primanja :" GET hParams[ "primanja_out" ] PICT  "@S20"
   READ

   clvbox()
   ESC_BCR
   BoxC()

   WPar( "VS", cVarSort )
   WPar( "PI", hParams[ "primanja_out" ] )
   SELECT PARAMS
   USE

   ld_pozicija_parobr( nMjesec, nGodina, iif( ld_vise_obracuna(), cObracun, ) )

   set_tippr_ili_tippr2( cObracun )

   IF !Empty( cKbenef )
      select_o_kbenef( cKbenef )
   ENDIF

   IF !Empty( cVPosla )
      select_o_vposla( cVposla )
   ENDIF

   // SELECT ld
   // USE
   use_sql_ld_ld( nGodina, nMjesec, nMjesec, nVrstaInvaliditeta, nStepenInvaliditeta )

   // 1 - "str(godina)+idrj+str(mjesec)+idradn"
   // 2 - "str(godina)+str(mjesec)+idradn"
   IF Empty( cIdrj )
      cIdrj := ""
      IF cVarSort == "1"
         // SET ORDER TO TAG ( ld_index_tag_vise_obracuna( "2" ) )
         // HSEEK Str( nGodina, 4, 0 ) + Str( nMjesec, 2, 0 ) + iif( ld_vise_obracuna() .AND. !Empty( cObracun ), cObracun, "" )
         seek_ld_2( NIL, nGodina, nMjesec, iif( ld_vise_obracuna() .AND. !Empty( cObracun ), cObracun, NIL ) )
      ELSE
         Box(, 2, 30 )
         nSlog := 0
         cSort1 := "SortPrez(IDRADN)"
         cFilt := IF( Empty( nMjesec ), ".t.", "MJESEC==" + _filter_quote( nMjesec ) ) + ".and." + ;
            iif( Empty( nGodina ), ".t.", "GODINA==" + _filter_quote( nGodina ) )
         IF ld_vise_obracuna() .AND. !Empty( cObracun )
            cFilt += ".and.OBR=" + _filter_quote( cObracun )
         ENDIF
         INDEX ON &cSort1 TO "tmpld" FOR &cFilt
         BoxC()
         GO TOP
      ENDIF
   ELSE
      IF cVarSort == "1"
         SET ORDER TO TAG ( ld_index_tag_vise_obracuna( "1" ) )
         HSEEK Str( nGodina, 4 ) + cIdrj + Str( nMjesec, 2 ) + if( ld_vise_obracuna() .AND. !Empty( cObracun ), cObracun, "" )
      ELSE
         Box(, 2, 30 )
         nSlog := 0
         cSort1 := "SortPrez(IDRADN)"
         cFilt := "IDRJ==" + _filter_quote( cIdRj ) + ".and." + ;
            iif( Empty( nMjesec ), ".t.", "MJESEC==" + _filter_quote( nMjesec ) ) + ".and." + ;
            iif( Empty( nGodina ), ".t.", "GODINA==" + _filter_quote( nGodina ) )
         IF ld_vise_obracuna() .AND. !Empty( cObracun )
            cFilt += ".and.OBR==" + _filter_quote( cObracun )
         ENDIF
         INDEX ON &cSort1 TO "tmpld" FOR &cFilt
         BoxC()
         GO TOP
      ENDIF
   ENDIF

   EOF CRET

   nStrana := 0

   IF gVarPP == "2"
      m := "----- ------ ---------------------------------- " + "-" + REPL( "-", Len( gPicS ) ) + " ----------- ----------- ----------- ----------- ----------- -----------"
   ELSE
      m := "----- ------ ---------------------------------- " + "-" + REPL( "-", Len( gPicS ) ) + " ----------- ----------- ----------- -----------"
   ENDIF

   m += " " + Replicate( "-", 11 )
   m += " " + Replicate( "-", 11 )
   m += " " + Replicate( "-", 11 )
   m += " " + Replicate( "-", 11 )
   m += " " + Replicate( "-", 11 )
   m += " " + Replicate( "-", 11 )

   IF cPrBruto == "D"
      m += " " + Replicate( "-", 12 )
   ENDIF


   bZagl := {|| zagl_pregled_plata( @hParams ) }

   select_o_ld_rj( ld->idrj )
   SELECT ld

   START PRINT CRET

   P_12CPI

   Eval( bZagl )

   nRbr := 0
   nUkupnoRedovanRad := nUkupnoMinuliRad := 0
   nUkupnoSati := nUkupnoPrimanja := 0
   nUkupnoIznosVanNetaOstaleNaknade := nUkupnoIznosVanNetaOdbici := nUkupnoZaIsplatu := nT5 := 0
   nIznosVanNetaPozitivneStavke := 0
   nIznosVanNetaNegativneStavke := 0
   nNetoZaIzbiti  := 0  // ako se navode "primanja_out" ovdje se racuna iznos neto primanja out
   nVanNetoZaIzbiti := 0  // ako se navode "primanja_out" ovdje se racuna iznos van neto primanja out
   nULicOdb := 0
   nUBruto := 0
   nUDoprIz := 0
   nUPorez := 0
   nUNetNr := 0
   nUkunoNetoPrimanja := 0

   DO WHILE !Eof() .AND.  nGodina == ld->godina .AND. ld->idrj = cIdrj .AND. nMjesec = ld->mjesec ;
         .AND. !( ld_vise_obracuna() .AND. !Empty( cObracun ) .AND. ld->obr <> cObracun )

      ld_pozicija_parobr( ld->mjesec, ld->godina, iif( ld_vise_obracuna(), cObracun, ), ld->idrj )

      IF ld_vise_obracuna() .AND. Empty( cObracun )
         ScatterS( ld->godina, ld->mjesec, ld->idrj, ld->idradn )
      ELSE
         Scatter()
      ENDIF


      select_o_radn( _idradn )
      select_o_vposla( _idvposla )
      select_o_kbenef( vposla->idkbenef )
      SELECT ld

      IF !Empty( cVposla ) .AND. cVposla <> Left( _idvposla, 2 )
         SKIP
         LOOP
      ENDIF

      IF !Empty( cKbenef ) .AND. cKbenef <> kbenef->id
         SKIP
         LOOP
      ENDIF

      nIznosVanNetaPozitivneStavke := 0
      nIznosVanNetaNegativneStavke := 0
      nNetoZaIzbiti := 0
      nVanNetoZaIzbiti := 0
      nIznosMinuliRad := 0

      FOR i := 1 TO cLDPolja

         cPom := PadL( AllTrim( Str( i ) ), 2, "0" )
         select_o_tippr( cPom )
         SELECT ld

         IF tippr->( Found() ) .AND. tippr->aktivan == "D" // aktivno primanje

            nIznos := _I&cPom

            IF tippr->uneto == "N" .AND. nIznos <> 0 // van neto primanja

               IF !Empty( hParams[ "primanja_out" ] ) .AND. cPom $ hParams[ "primanja_out" ] // preskoci ovo van-neta primanje
                  nVanNetoZaIzbiti += Iznos
                  LOOP
               ENDIF

               IF nIznos > 0
                  nIznosVanNetaPozitivneStavke += nIznos
               ELSE
                  nIznosVanNetaNegativneStavke += nIznos
               ENDIF

            ELSEIF tippr->uneto == "D" .AND. nIznos <> 0 // u neto primanja

               IF !Empty( hParams[ "primanja_out" ] ) .AND. cPom $ hParams[ "primanja_out" ] // preskoci ovo neto primanje
                  nNetoZaIzbiti += nIznos
                  LOOP
               ENDIF

               IF cPom == cIdMinuli
                  nIznosMinuliRad := nIznos
               ENDIF

            ENDIF
         ENDIF

      NEXT


      cRTipRada := ""
      nPrKoef := 0
      cOpor := ""
      cTrosk := ""
      nLicOdb := 0
      nNetoNaRuke := 0
      nNeto := 0

      SELECT ld

      cRTipRada := get_ld_rj_tip_rada( _idradn, ld->idrj )
      nPrKoef := radn->sp_koef
      cOpor := radn->opor
      cTrosk := radn->trosk
      nLicOdb := _ulicodb

      nBO := ld_get_bruto_osnova( _uneto - nNetoZaIzbiti, cRTipRada, nLicOdb, nPrKoef, cTrosk )
      nMBO := nBO

      IF ld_calc_min_bruto_yes_no()
         nMBO := ld_min_bruto_osnova( nBo, ld->usati )
      ENDIF

      nBrOsn := nBo

      IF cRTipRada == "A" .AND. cTrosk <> "N"
         nTrosk := nBO * ( gAhTrosk / 100 )
         nBrOsn := nBO - nTrosk
      ELSEIF cRTipRada == "U" .AND. cTrosk <> "N"
         nTrosk := nBO * ( gUgTrosk / 100 )
         nBrOsn := nBO - nTrosk
      ENDIF

      nDoprIz := u_dopr_iz( nMBO, cRTipRada )

      nPorez := 0
      IF radn_oporeziv( _idradn, ld->idrj ) .AND. cRTipRada <> "S"
         nPorez := izr_porez( nBrOsn - nDoprIz - nLicOdb, "B" )
      ENDIF

      nNeto := ( nBrOsn - nDoprIz )
      nNetoNaRuke := ( nBrOsn - nDoprIz - nPorez )

      SELECT ld

      ? Str( ++nRbr, 4 ) + ".", _idradn, RADNIK_PREZ_IME
      nC1 := PCol() + 1

      @ PRow(), PCol() + 1 SAY _usati PICT gpics

      IF gVarPP == "2"
         @ PRow(), PCol() + 1 SAY _uneto - nNetoZaIzbiti - nIznosMinuliRad PICT gpici
         @ PRow(), PCol() + 1 SAY nIznosMinuliRad PICT gpici
      ENDIF

      @ PRow(), PCol() + 1 SAY _uneto - nNetoZaIzbiti PICT gpici
      @ PRow(), PCol() + 1 SAY nBrOsn PICT gpici  // bruto
      @ PRow(), PCol() + 1 SAY nDoprIz PICT gpici
      @ PRow(), PCol() + 1 SAY nLicOdb PICT gpici
      @ PRow(), PCol() + 1 SAY nPorez PICT gpici
      @ PRow(), PCol() + 1 SAY nNeto PICT gpici
      @ PRow(), PCol() + 1 SAY nNetoNaRuke PICT gpici
      @ PRow(), PCol() + 1 SAY nIznosVanNetaPozitivneStavke PICT gpici
      @ PRow(), PCol() + 1 SAY nIznosVanNetaNegativneStavke PICT gpici
      @ PRow(), PCol() + 1 SAY _uiznos - nNetoZaIzbiti - nVanNetoZaIzbiti PICT gpici // ukupno za isplatu

      IF cKontrola == "D"
         nKontrola := ( nBrOsn - nDoprIz - nPorez ) + nIznosVanNetaPozitivneStavke + nIznosVanNetaNegativneStavke
         IF Round( _uiznos - nNetoZaIzbiti - nVanNetoZaIzbiti, 2 ) == Round( nKontrola, 2 )
            // nista
         ELSE
            @ PRow(), PCol() + 1 SAY "ERR"
         ENDIF
      ENDIF

      nUkupnoSati += _usati

      nUkupnoRedovanRad += _uneto - nNetoZaIzbiti - nIznosMinuliRad  // koristi se samo za varijantu 2
      nUkupnoMinuliRad += nIznosMinuliRad // koristi se samo za varijantu 2

      nUkupnoPrimanja += _uneto - nNetoZaIzbiti // koristi se samo za varijantu 1
      nUkupnoIznosVanNetaOstaleNaknade += nIznosVanNetaPozitivneStavke
      nUkupnoIznosVanNetaOdbici += nIznosVanNetaNegativneStavke
      nUkupnoZaIsplatu += _uiznos - nNetoZaIzbiti - nVanNetoZaIzbiti
      nULicOdb += nLicOdb
      nUBruto += nBrOsn
      nUDoprIz += nDoprIz
      nUPorez += nPorez
      nUNetNr += nNetoNaRuke
      nUkunoNetoPrimanja += nNeto

      SKIP

   ENDDO

   ? m
   ? Space( 1 ) + _l( "UKUPNO:" )
   @ PRow(), nC1 SAY  nUkupnoSati PICT gpics

   IF gVarPP == "2"
      @ PRow(), PCol() + 1 SAY nUkupnoRedovanRad PICT gpici
      @ PRow(), PCol() + 1 SAY nUkupnoMinuliRad PICT gpici
   ENDIF

   @ PRow(), PCol() + 1 SAY nUkupnoPrimanja PICT gpici
   @ PRow(), PCol() + 1 SAY nUBruto PICT gpici // bruto
   @ PRow(), PCol() + 1 SAY nUDoprIz PICT gpici // doprinosi
   @ PRow(), PCol() + 1 SAY nULicOdb PICT gpici // licni odbici
   @ PRow(), PCol() + 1 SAY nUPorez PICT gpici // porez
   @ PRow(), PCol() + 1 SAY nUkunoNetoPrimanja PICT gpici // neto
   @ PRow(), PCol() + 1 SAY nUNetNR PICT gpici // neto na ruke
   @ PRow(), PCol() + 1 SAY nUkupnoIznosVanNetaOstaleNaknade PICT gpici // ostale naknade
   @ PRow(), PCol() + 1 SAY nUkupnoIznosVanNetaOdbici PICT gpici // odbici
   @ PRow(), PCol() + 1 SAY nUkupnoZaIsplatu PICT gpici // za isplatu

   ? m
   ?
   ? p_potpis()

   FF
   ENDPRINT

   my_close_all_dbf()

   RETURN .T.



STATIC FUNCTION zagl_pregled_plata( hParams )

   ?

   P_COND2

   ? Upper( tip_organizacije() ) + ":", self_organizacija_naziv()
   ?

   IF Empty( cIdrj )
      ? "Pregled za sve RJ ukupno:"
   ELSE
      ? "RJ:", cIdRj, ld_rj->naz
   ENDIF

   ?? Space( 2 ) + "Mjesec:", Str( nMjesec, 2 ) + IspisObr()
   ?? Space( 4 ) + "Godina:", Str( nGodina, 5 )

   ?? Space( 10 ), " Str.", Str( ++nStrana, 3 )

   IF nVrstaInvaliditeta > 0 .OR. nStepenInvaliditeta > 0
      ?
   ENDIF
   IF nVrstaInvaliditeta > 0
      ?? " Vr.invaliditeta:", Str( nVrstaInvaliditeta, 1, 0 )
   ENDIF
   IF nStepenInvaliditeta > 0
      ?? " St.invaliditeta", Str( nStepenInvaliditeta, 3, 0 )
   ENDIF


   IF !Empty( hParams[ "primanja_out" ] )
      ?U "Iz pregleda izbačena slijedeća primanja: ", hParams[ "primanja_out" ]
   ENDIF

   IF !Empty( cVposla )
      ? "Vrsta posla:", cVposla, "-", vposla->naz
   ENDIF
   IF !Empty( cKBenef )
      ? "Stopa beneficiranog r.st:", cKbenef, "-", kbenef->naz, ":", kbenef->iznos
   ENDIF

   ? m

   IF gVarPP == "2"
      ?U " Rbr * Šifra*         Naziv radnika            *  Sati   *   Redovan *  Minuli   *   Neto    *       VAN NETA       * ZA ISPLATU*"
      ?U "     *      *                                  *         *     rad   *   rad     *           * Primanja  * Obustave *           *"
   ELSE
      ?U " Rbr * Šifra*         Naziv radnika            *  Sati   * Primanja  * Bruto pl. * Dopr (iz) * L.odbici  *  Porez    *    Neto   *  Na ruke  *  Ostale  *  Odbici    * ZA ISPLATU*"
      ?U "     *      *                                  *         *           * 1 x koef. *  1 x 31%  *           *    10%    *   (2-3)   *  (2-3-5)  * naknade  *            *(7 + 8 + 9)*"
      ?U "     *      *                                  *         *    (1)    *    (2)    *    (3)    *    (4)    *   (5)     *    (6)    *    (7)    *    (8)   *    (9)     *    (10)   *"
   ENDIF
   ? m

   RETURN .T.
