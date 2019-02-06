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

/*
 *   param: fstara - .f. znaci poziv iz tabele pripreme, .t. radi se o azuriranoj kalkulaciji pa se prvo getuje broj dokumenta (cIdFirma,cIdVD,cBrdok)
 *     Pravi rekapitulaciju kalkulacija a ako je ulazni parametar fstara==.t. poziva se i kontiranje dokumenta
 */

FUNCTION kalk_kontiranje_gen_finmat()

   PARAMETERS fStara, cIdFirma, cIdVd, cBrDok, lAuto

   LOCAL nPom
   LOCAL fPrvi
   LOCAL n1 := 0, n2 := 0, n3 := 0, n4 := 0, n5 := 0, n6 := 0, n7 := 0, n8 := 0, n9 := 0, na := 0, nb := 0
   LOCAL nTot1 := 0, nTot2 := 0, nTot3 := 0, nTot4 := 0, nTot5 := 0, nTot6 := 0, nTot7 := 0, nTot8 := 0, nTot9 := 0, nTota := 0, nTotb := 0, nTotC := 0
   LOCAL nCol1 := 0, nCol2 := 0, nCol3 := 0
   LOCAL cFinAutoBrojDN := "N"
   LOCAL GetList := {}

   // LOCAL nZaokruzenje := gZaokr
   LOCAL nZaokruzenje := 12
   LOCAL nKolicina

   // kontira se vise kalkulacija
   LOCAL lViseKalk := .F.
   LOCAL _predispozicija := .F.
   LOCAL aPorezi

   aPorezi := {}

   IF PCount() == 0
      fStara := .F.
   ENDIF

   IF lAuto == nil
      lAuto := .F.
   ENDIF


   fprvi := .T. // prvi prolaz

   // DO WHILE .T.

   _predispozicija := .F.

   kalk_open_tabele_za_kontiranje()

   IF fStara
      kalk_otvori_kumulativ_kao_pripremu( cIdFirma, cIdVd, cBrDok )
   ELSE
      select_o_kalk_pripr()
   ENDIF

   SELECT finmat
   my_dbf_zap()

   SELECT KALK_PRIPR

   SET ORDER TO TAG "1" // idfirma+ idvd + brdok+rbr

   IF fPrvi
      IF cIdFirma == NIL // nisu prosljedjeni parametri

         cIdFirma := IdFirma
         cIdVD := IdVD
         cBrdok := brdok
         IF Empty( cIdFirma )
            cIdFirma := self_organizacija_id()
         ENDIF
         lViseKalk := .F.

      ELSE
         lViseKalk := .T. // parametri su prosljedjeni RekapK funkciji
      ENDIF
      fPrvi := .F.

   ENDIF

   IF fStara

      IF !lViseKalk

         Box( "", 1, 50 )
         SET CURSOR ON
         @ box_x_koord() + 1, box_y_koord() + 2 SAY "Dokument broj:"

         @ box_x_koord() + 1, Col() + 2  SAY cIdFirma

         @ box_x_koord() + 1, Col() + 1 SAY "-" GET cIdVD
         @ box_x_koord() + 1, Col() + 1 SAY "-" GET cBrDok
         READ
         ESC_BCR
         BoxC()
      ENDIF

      IF fStara
         kalk_otvori_kumulativ_kao_pripremu( cIdFirma, cIdVd, cBrDok )
      ENDIF

      HSEEK cIdFirma + cIdVd + cBrDok // kalk_pripr

   ELSE
      GO TOP
      cIdFirma := IdFirma
      cIdVD := IdVD
      cBrdok := brdok
   ENDIF


   IF field->idvd == "80" .AND. !Empty( field->idkonto2 ) // potrebno je ispitati da li je predispozicija !
      _predispozicija := .T.
   ENDIF


   IF Eof()
      RETURN .F.
   ENDIF

   IF fStara .AND. lAuto == .F.

      // - info o izabranom dokumentu -
      Box( "#DOKUMENT " + cIdFirma + "-" + cIdVd + "-" + cBrDok, 9, 77 )

      cDalje := "D"
      cAutoRav := param_fin_automatska_ravnoteza_kod_azuriranja()

      select_o_partner( KALK_PRIPR->IDPARTNER )
      select_o_konto( KALK_PRIPR->MKONTO )
      cPom := naz
      select_o_konto( KALK_PRIPR->PKONTO )
      SELECT kalk_pripr
      @ box_x_koord() + 2, box_y_koord() + 2 SAY "DATUM------------>"             COLOR "W+/B"
      @ box_x_koord() + 2, Col() + 1 SAY DToC( DATDOK )                   COLOR "N/W"
      @ box_x_koord() + 3, box_y_koord() + 2 SAY "PARTNER---------->"             COLOR "W+/B"
      @ box_x_koord() + 3, Col() + 1 SAY IDPARTNER + "-" + PadR( partn->naz, 20 ) COLOR "N/W"
      @ box_x_koord() + 4, box_y_koord() + 2 SAY "KONTO MAGACINA--->"             COLOR "W+/B"
      @ box_x_koord() + 4, Col() + 1 SAY MKONTO + "-" + PadR( cPom, 49 )       COLOR "N/W"
      @ box_x_koord() + 5, box_y_koord() + 2 SAY "KONTO PRODAVNICE->"             COLOR "W+/B"
      @ box_x_koord() + 5, Col() + 1 SAY PKONTO + "-" + PadR( KONTO->naz, 49 ) COLOR "N/W"
      @ box_x_koord() + 7, box_y_koord() + 2 SAY8 "Automatski uravnoteži dokument? (D/N)" GET cAutoRav VALID cAutoRav $ "DN" PICT "@!"
      @ box_x_koord() + 8, box_y_koord() + 2 SAY8 "Želite li kontirati dokument? (D/N)" GET cDalje VALID cDalje $ "DN" PICT "@!"
      @ box_x_koord() + 9, box_y_koord() + 2 SAY8 "Automatski broj fin.naloga? (D/N)" GET cFinAutoBrojDN VALID cFinAutoBrojDN $ "DN" PICT "@!"

      READ

      BoxC()

      IF LastKey() == K_ESC .OR. cDalje <> "D"

         RETURN .F.

      ENDIF

   ENDIF

   nStr := 0
   nTot1 := nTot2 := nTot3 := nTot4 := nTot5 := nTot6 := nTot7 := nTot8 := nTot9 := nTota := nTotb := nTotC := 0

   DO WHILE !Eof() .AND. cIdFirma == field->idfirma .AND. cIdvd == field->idvd

      cBrDok := BrDok
      cIdPartner := IdPartner
      cBrFaktP := BrFaktP
      dDatFaktP := DatFaktP
      cIdKonto := IdKonto
      cIdKonto2 := IdKonto2


      //select_o_konto( cIdKonto )

      select_o_konto( cIdKonto2 )
      SELECT KALK_PRIPR


      cIdd := idpartner + brfaktp + idkonto + idkonto2


      DO WHILE !Eof() .AND. cIdFirma == IdFirma .AND.  cBrDok == BrDok .AND. cIdVD == IdVD

         IF cIdVd == "97"
            IF field->tbanktr == "X"
               SKIP
               LOOP
            ENDIF
         ENDIF


         // iznosi troskova koji se izracunavaju u kalk_set_troskovi_priv_vars_ntrosakx_nmarzax()
         PRIVATE nPrevoz, nCarDaz, nZavTr, nBankTr, nSpedTr, nMarza, nMarza2

         nFV := FCj * Kolicina

         //IF gKalo == "1"
        //    nKolicina := kalk_pripr->( Kolicina - GKolicina - GKolicin2 )
        // ELSE
            nKolicina := kalk_pripr->Kolicina
        // ENDIF

         select_o_roba( KALK_PRIPR->IdRoba )

         select_o_tarifa( KALK_PRIPR->idtarifa )

         SELECT KALK_PRIPR

         set_pdv_array_by_koncij_region_roba_idtarifa_2_3( pkonto, idroba, @aPorezi )
         kalk_set_troskovi_priv_vars_ntrosakx_nmarzax()
         set_pdv_public_vars()

         SELECT finmat
         APPEND BLANK

         REPLACE IdFirma   WITH kalk_PRIPR->IdFirma, ;
            IdKonto   WITH kalk_PRIPR->IdKonto, ;
            IdKonto2  WITH kalk_pripr->IdKonto2, ;
            IdTarifa  WITH kalk_pripr->IdTarifa, ;
            IdPartner WITH kalk_pripr->IdPartner, ;
            IdZaduz   WITH kalk_pripr->IdZaduz, ;
            IdZaduz2  WITH kalk_pripr->IdZaduz2, ;
            BrFaktP   WITH kalk_pripr->BrFaktP, ;
            DatFaktP  WITH kalk_pripr->DatFaktP, ;
            IdVD      WITH kalk_pripr->IdVD, ;
            BrDok     WITH kalk_pripr->BrDok, ;
            DatDok    WITH kalk_pripr->DatDok, ;
            GKV       WITH Round( kalk_PRIPR->( GKolicina * FCJ2 ), nZaokruzenje ), ;   // vrijednost transp.kala
         GKV2      WITH Round( kalk_PRIPR->( GKolicin2 * FCJ2 ), nZaokruzenje ), ;   // vrijednost ostalog kala
         Prevoz    WITH Round( kalk_PRIPR->( nPrevoz * nKolicina ), nZaokruzenje ), ;
            CarDaz    WITH Round( kalk_PRIPR->( nCarDaz * nKolicina ), nZaokruzenje ), ;
            BankTr    WITH Round( kalk_PRIPR->( nBankTr * nKolicina ), nZaokruzenje ), ;
            SpedTr    WITH Round( kalk_PRIPR->( nSpedTr * nKolicina ), nZaokruzenje ), ;
            ZavTr     WITH Round( kalk_PRIPR->( nZavTr * nKolicina ), nZaokruzenje ), ;
            NV        WITH Round( kalk_PRIPR->( NC * ( Kolicina - GKolicina - GKolicin2 ) ), nZaokruzenje ), ;
            Marza     WITH Round( kalk_PRIPR->( nMarza * ( Kolicina - GKolicina - GKolicin2 ) ), nZaokruzenje ), ;           // marza se ostvaruje nad stvarnom kolicinom
         VPV       WITH Round( kalk_PRIPR->( VPC * ( Kolicina - GKolicina - GKolicin2 ) ), nZaokruzenje )        // vpv se formira nad stvarnom kolicinom


         nPom := kalk_pripr->( RabatV / 100 * VPC * Kolicina )
         nPom := Round( nPom, nZaokruzenje )
         REPLACE RABATV  WITH nPom


         nPom := kalk_pripr->( nMarza2 * ( Kolicina - GKolicina - GKolicin2 ) )
         nPom := Round( nPom, nZaokruzenje )
         REPLACE Marza2 WITH nPom

         IF kalk_pripr->idvd $ "14#94"
            nPom := kalk_pripr->( VPC * ( 1 -RabatV / 100 ) * MPC / 100 * Kolicina )
         ELSE
            nPom := kalk_pripr->( MPC * ( Kolicina - GKolicina - GKolicin2 ) )
         ENDIF
         nPom := Round( nPom, nZaokruzenje )
         REPLACE MPV WITH nPom


         // aIPor := kalk_porezi_maloprodaja_legacy_array( aPorezi, nKolicina * field->mpc, nKolicina * field->mpcSaPP, field->nc )
         // nPom := kalk_pripr->( aIPor[ 1 ] * ( Kolicina - GKolicina - GKolicin2 ) )

         // PDV
         REPLACE Porez WITH Round( kalk_porezi_maloprodaja( NIL, aPorezi, nKolicina * kalk_pripr->mpcSaPP ), nZaokruzenje )
         // ??E field->porez, "+"

         // ugostiteljstvo porez na potr
         // REPLACE Porez2    WITH Round( kalk_PRIPR->( aIPor[ 3 ] * ( Kolicina - GKolicina - GKolicin2 ) ), nZaokruzenje )


         nPom := kalk_pripr->( MPCSaPP * ( Kolicina - GKolicina - GKolicin2 ) )
         nPom := Round( nPom, nZaokruzenje )
         REPLACE MPVSaPP WITH nPom

         // porezv je aIPor[2] koji se ne koristi
         // nPom := kalk_pripr->( aIPor[ 2 ] * ( Kolicina - GKolicina - GKolicin2 ) )
         // nPom := Round( nPom, nZaokruzenje )
         // REPLACE Porezv WITH nPom

         REPLACE idroba    WITH kalk_pripr->idroba
         REPLACE  Kolicina  WITH kalk_pripr->( Kolicina - GKolicina - GKolicin2 )

         IF !( kalk_pripr->IdVD $ "IM#IP" )
            REPLACE   FV        WITH Round( nFV, nZaokruzenje ), ;
               Rabat     WITH Round( kalk_pripr->( nFV * Rabat / 100 ), nZaokruzenje )
         ENDIF

         IF field->idvd == "IP"
            REPLACE  GKV2  WITH Round( kalk_pripr->( ( Gkolicina - Kolicina ) * MPcSAPP ), nZaokruzenje ), ;
               GKol2 WITH kalk_pripr->( Gkolicina - Kolicina )
         ENDIF

         IF field->idvd $ "14#94"
            REPLACE  MPVSaPP   WITH  kalk_pripr->( VPC * ( 1 -RabatV / 100 ) * ( Kolicina - GKolicina - GKolicin2 ) )
         ENDIF


         //IF gKalo == "2" .AND.  kalk_pripr->idvd $ "10#81"  // kalo ima vrijednost po NC
        //    REPLACE GKV   WITH Round( kalk_pripr->( GKolicina * NC ), nZaokruzenje ), ;   // vrijednost transp.kala
        //    GKV2  WITH Round( kalk_pripr->( GKolicin2 * NC ), nZaokruzenje ), ;   // vrijednost ostalog kala
        //    GKol  WITH Round( kalk_pripr->GKolicina, nZaokruzenje ), ;
        //       GKol2 WITH Round( kalk_pripr->GKolicin2, nZaokruzenje ), ;
        //       POREZV WITH Round( nMarza * kalk_pripr->( GKolicina + Gkolicin2 ), nZaokruzenje ) // negativna marza za kalo
         //ENDIF

         IF kalk_pripr->IDVD $ "18#19"
            REPLACE Kolicina WITH 0
         ENDIF

         IF ( kalk_pripr->IdVD $ "41#42" )
            REPLACE Rabat WITH kalk_pripr->RabatV * kalk_pripr->kolicina // popust maloprodaje se smjesta ovdje
            IF AllTrim( self_organizacija_naziv() ) == "TEST FIRMA"
               MsgBeep( "Popust MP = finmat->rabat " + Str( Rabat, 10, 2 ) )
            ENDIF
         ENDIF


         IF _predispozicija // napuni marker da se radi o predispoziciji
            REPLACE k1 WITH "P"
         ENDIF

         SELECT kalk_pripr
         SKIP
      ENDDO // brdok

      IF fStara
         EXIT
      ENDIF


   ENDDO // idfirma,idvd


   IF fStara .AND. lAuto == .F.

      IF !lViseKalk
         my_close_all_dbf()
      ENDIF

      // ovo ispod kontiranje se koristi kada se kontira azurirani dokument
      kalk_kontiranje_fin_naloga( .F., NIL, lViseKalk, NIL, cFinAutoBrojDN == "D" )  // kontiranje dokumenta

      IF cAutoRav == "D" // automatska ravnoteza naloga
         kontrola_zbira_naloga_u_pripremi( .T. )
      ENDIF

   ENDIF


   IF !lViseKalk
      my_close_all_dbf()
      RETURN .F.
   ENDIF

   RETURN .T.
