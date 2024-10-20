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


FUNCTION menu_fakt_kalk_prenos_normativi()

   LOCAL _opc := {}
   LOCAL _opcexe := {}
   LOCAL _izbor := 1

   AAdd( _opc, "1. fakt->kalk 96 po normativima za period            " )
   AAdd( _opcexe, {||          kalk_fakt_kalk_prenos_normativi()  } )
   AAdd( _opc, "2. fakt->kalk 96 po normativima po fakturama" )
   AAdd( _opcexe, {||          PrenosNoFakt()  } )
   AAdd( _opc, "3. fakt->kalk 10 got.proizv po normativima za period" )
   AAdd( _opcexe, {||          fakt_kalk_prenos_normativi() } )

   f18_menu( "fkno", .F., _izbor, _opc, _opcexe )

   RETURN .T.


// -------------------------------------------------------
// prenos po normativima za period
// -------------------------------------------------------
FUNCTION kalk_fakt_kalk_prenos_normativi( dD_from, dD_to, cIdKonto2, cIdTipDok, dDatKalk, cRobaUsl, ;
      cRobaIncl, cSezona, cSirovina )

   LOCAL lTest := .F.
   LOCAL cBrDok := Space( 8 )
   LOCAL cBrKalk := Space( 8 )
   LOCAL cIdFirma := self_organizacija_id()
   LOCAL cIdKonto := PadR( "", 7 )

   IF PCount() == 0
      cIdTipDok := "10;11;12;      "
      cRobaUsl := Space( 100 )
      cRobaIncl := "I"
      dDatKalk := Date()
      cIdKonto2 := PadR( "1310", 7 )
      cSezona := ""
      cSirovina := ""
   ELSE
      lTest := .T.
   ENDIF

   o_tbl_roba( lTest, cSezona )
   o_tables()

   IF !Empty( cSirovina )
      o_r_export_legacy()
   ENDIF

   kalk_set_brkalk_za_idvd( "96", @cBrKalk )

   Box(, 15, 60 )
   DO WHILE .T.

      nRBr := 0

      IF lTest == .F.

         @ box_x_koord() + 1, box_y_koord() + 2   SAY "Broj kalkulacije 96 -" GET cBrKalk PICT "@!"
         @ box_x_koord() + 1, Col() + 2 SAY "Datum:" GET dDatKalk
         @ box_x_koord() + 3, box_y_koord() + 2   SAY "Konto razduzuje:" GET cIdKonto2 PICT "@!" VALID P_Konto( @cIdKonto2 )
         @ box_x_koord() + 4, box_y_koord() + 2   SAY "Konto zaduzuje :" GET cIdKonto  PICT "@!" VALID P_Konto( @cIdKonto )

         cIdRjFakt := cIdFirma
         dDatFOd := CToD( "" )
         dDatFDo := Date()
         @ box_x_koord() + 6, box_y_koord() + 2 SAY "RJ u FAKT: " GET  cIdRjFakt
         @ box_x_koord() + 7, box_y_koord() + 2 SAY "Dokumenti tipa iz fakt:" GET cidtipdok
         @ box_x_koord() + 8, box_y_koord() + 2 SAY "period od" GET dDAtFOd
         @ box_x_koord() + 8, Col() + 2 SAY "do" GET dDAtFDo

         @ box_x_koord() + 10, box_y_koord() + 2 SAY "Uslov za robu:" GET cRobaUsl PICT "@S40"
         @ box_x_koord() + 11, box_y_koord() + 2 SAY "Navedeni uslov [U]kljuciti / [I]skljuciti" GET cRobaIncl VALID cRobaIncl $ "UI" PICT "@!"

         READ

         IF LastKey() == K_ESC
            EXIT
         ENDIF

      ENDIF

      IF lTest == .T.
         dDatFOd := dD_from
         dDatFDo := dD_to
         cIdRjFakt := "10"
      ENDIF

      seek_fakt( cIdRjFakt )

      aNotIncl := {}

      DO WHILE !Eof() .AND. cIdRjFakt == IdFirma

         IF idtipdok $ cIdTipdok .AND. dDatFOd <= datdok .AND. dDatFDo >= datdok
            // pripada odabranom intervalu

            cFBrDok := fakt->brdok

            find_kalk_doks_by_broj_fakture( "96", PadR( cFBrDok, 10 ) )

            IF !Eof()

               cTmp := fakt->idfirma + "-" + ( cFBrDok )
               dTmpDate := fakt->datdok

               select_o_partner( fakt->idpartner )
               cTmpPartn := AllTrim( partn->naz )

               SELECT kalk_doks

               nScan := AScan( aNotIncl, {| xVar | xVar[ 1 ] == cTmp } )
               IF nScan == 0
                  AAdd( aNotIncl, { cTmp, dTmpDate, cTmpPartn, kalk_doks->idvd + "-" + kalk_doks->brdok } )
               ENDIF

               SELECT fakt
               SKIP
               LOOP

            ENDIF

            select_o_roba( fakt->idroba )
            IF !Empty( cRobaUsl ) // provjeri prije svega uslov za robu

               cTmp := Parsiraj( cRobaUsl, "idroba" )

               IF &cTmp
                  IF cRobaIncl == "I"
                     SELECT fakt
                     SKIP
                     LOOP
                  ENDIF
               ELSE
                  IF cRobaIncl == "U"
                     SELECT fakt
                     SKIP
                     LOOP
                  ENDIF
               ENDIF

            ENDIF

            IF roba->tip = "P" // radi se o proizvodu

               select_o_sastavnice( fakt->idroba )
               DO WHILE !Eof() .AND. id == fakt->idroba // prolaz kroz stavke sastavnice

                  IF !Empty( cSirovina )
                     IF cSirovina <> sast->id2
                        SKIP
                        LOOP
                     ENDIF
                  ENDIF

                  select_o_roba( sast->id2 )
                  SELECT kalk_pripr
                  LOCATE FOR idroba == sast->id2
                  IF Found()
                     RREPLACE kolicina WITH kolicina + fakt->kolicina * sast->kolicina

                  ELSE
                     SELECT kalk_pripr
                     APPEND BLANK
                     REPLACE idfirma WITH cIdFirma, ;
                        rbr  WITH ++nRbr, ;
                        idvd WITH "96", ;   // izlazna faktura
                        brdok WITH cBrKalk, ;
                        datdok WITH dDatKalk, ;
                        idtarifa WITH ROBA->idtarifa, ;
                        brfaktp WITH "", ;
                        idkonto   WITH cidkonto, ;
                        idkonto2  WITH cidkonto2, ;
                        kolicina WITH fakt->kolicina * sast->kolicina, ;
                        idroba WITH sast->id2, ;
                        nc  WITH ROBA->nc, ;
                        vpc WITH fakt->cijena, ;
                        rabatv WITH fakt->rabat, ;
                        mpc WITH fakt->porez

                     // datfaktp WITH dDatKalk, ;

                  ENDIF

                  IF !Empty( cSirovina )

                     SELECT r_export
                     APPEND BLANK

                     REPLACE field->idsast WITH cSirovina
                     REPLACE field->idroba WITH fakt->idroba
                     REPLACE field->r_naz WITH ""
                     REPLACE field->idpartner WITH fakt->idpartner
                     REPLACE field->rbr WITH VAL(fakt->rbr)
                     REPLACE field->brdok WITH fakt->idtipdok + ;
                        "-" + fakt->brdok
                     REPLACE field->kolicina WITH fakt->kolicina
                     REPLACE field->kol_sast WITH ;
                        fakt->kolicina * sast->kolicina


                  ENDIF

                  SELECT sast
                  SKIP

               ENDDO

            ENDIF // roba->tip == "P"
         ENDIF  // $ cidtipdok
         SELECT fakt
         SKIP
      ENDDO

      IF lTest == .F.

         IF Len( aNotIncl ) > 0
            rpt_not_incl( aNotIncl )
         ENDIF

         @ box_x_koord() + 10, box_y_koord() + 2 SAY "Dokumenti su preneseni !"

         kalk_fix_brdok_add_1( @cBrKalk )

         Inkey( 4 )
         @ box_x_koord() + 8, box_y_koord() + 2 SAY Space( 30 )

      ELSE
         EXIT
      ENDIF


   ENDDO
   Boxc()
   IF lTest == .F.
      closeret
   ENDIF

   RETURN .T.

// ---------------------------------------------
// prikazi sta nije ukljuceno u prenos
// ---------------------------------------------
STATIC FUNCTION rpt_not_incl( aArr )

   LOCAL i
   LOCAL nCnt := 0

   START PRINT CRET

   ? "----------------------------------------------"
   ? "U prenosu nisu ukljuceni sljedeci dokumenti:"
   ? "----------------------------------------------"

   ?
   ? "---- ----------- ----------- -------- --------------------------------------"
   ? "rbr  br.dok      br.dok       datum   partner"
   ? "     u fakt      u kalk"
   ? "---- ----------- ----------- -------- --------------------------------------"

   FOR i := 1 TO Len( aArr )

      // rbr             brdok f.   brdok k.  datum       partner
      ? Str( ++nCnt, 3 ) + ".", aArr[ i, 1 ], aArr[ i, 4 ], aArr[ i, 2 ], aArr[ i, 3 ]

   NEXT

   ?
   ? "Ovi dokumenti su preneseni opcijom prenosa po"
   ? "broju fakture."

   FF
   ENDPRINT

   RETURN .T.


// -------------------------------------
// otvori tabele za prenos
// -------------------------------------
STATIC FUNCTION o_tables()

   o_kalk_pripr()

   RETURN .T.


// -------------------------------------------
// otvaranje roba - sast
// -------------------------------------------
STATIC FUNCTION o_tbl_roba( lTest, cSezSif )

   IF lTest == .T.
      my_close_all_dbf()

      // cSifPath := PadR( SIFPATH, 14 )
      // "c:\sigma\sif1\"

      // IF !Empty( cSezSif ) .AND. cSezSif <> "RADP"
      // cSifPath += cSezSif + SLASH
      // ENDIF

      // SELECT ( F_ROBA )
      // USE
      // SELECT ( F_ROBA )
      // USE ( cSifPath + "ROBA" ) ALIAS "ROBA"
      // SET ORDER TO TAG "ID"

      // SELECT ( F_SAST )
      // USE
      // SELECT ( F_SAST )
      // USE ( cSifPath + "SAST" ) ALIAS "SAST"
      // SET ORDER TO TAG "ID"

   ELSE
      // o_roba()
      // o_sastavnice()
   ENDIF

   RETURN .T.



// -------------------------------------------------------
// prenos po normativima po broju faktura
// -------------------------------------------------------
FUNCTION PrenosNoFakt()

   LOCAL cIdFirma := self_organizacija_id()
   LOCAL cIdTipDok := "10"
   LOCAL cBrDok := Space( 8 )
   LOCAL cBrKalk := Space( 8 )
   LOCAL cFaBrDok := Space( 8 )

   // otvori tabele prenosa
   o_tables()

   dDatKalk := Date()
   cIdKonto := PadR( "", 7 )
   cIdKonto2 := PadR( "1310", 7 )

   cBrkalk := Space( 8 )

   kalk_set_brkalk_za_idvd( "96", @cBrKalk )

   Box(, 15, 60 )


   DO WHILE .T.

      nRBr := 0

      @ box_x_koord() + 1, box_y_koord() + 2   SAY "Broj kalkulacije 96 -" GET cBrKalk PICT "@!"
      @ box_x_koord() + 1, Col() + 2 SAY "Datum:" GET dDatKalk
      @ box_x_koord() + 3, box_y_koord() + 2   SAY "Konto razduzuje:" GET cIdKonto2 PICT "@!" VALID P_Konto( @cIdKonto2 )
      @ box_x_koord() + 4, box_y_koord() + 2   SAY "Konto zaduzuje :" GET cIdKonto  PICT "@!" VALID P_Konto( @cIdKonto )

      cIdRjFakt := cIdFirma

      @ box_x_koord() + 6, box_y_koord() + 2 SAY "RJ u FAKT: " GET  cIdRjFakt
      @ box_x_koord() + 7, box_y_koord() + 2 SAY "Dokument tipa u fakt:" GET cIdTipDok
      @ box_x_koord() + 8, box_y_koord() + 2 SAY "Broj dokumenta u fakt:" GET cFaBrDok

      READ

      IF LastKey() == K_ESC
         EXIT
      ENDIF

      seek_fakt( cIdRjFakt )
      DO WHILE !Eof() .AND. cIdRjFakt == IdFirma

         IF idtipdok = cIdTipdok .AND. cFaBrDok = brdok

            select_o_roba( fakt->idroba )
            IF roba->tip = "P"
               // radi se o proizvodu
               select_o_sastavnice( fakt->idroba )
               DO WHILE !Eof() .AND. id == fakt->idroba
                  // setaj kroz sast
                  select_o_roba( sast->id2 )
                  SELECT kalk_pripr
                  LOCATE FOR idroba == sast->id2
                  IF Found()
                     RREPLACE kolicina WITH kolicina + fakt->kolicina * sast->kolicina
                  ELSE
                     SELECT kalk_pripr
                     APPEND BLANK
                     REPLACE idfirma WITH cIdFirma, ;
                        rbr  WITH ++nRbr, ;
                        idvd WITH "96", ;
                        brdok WITH cBrKalk, ;
                        datdok WITH dDatKalk, ;
                        idtarifa WITH ROBA->idtarifa, ;
                        brfaktp WITH fakt->brdok, ;
                        idpartner WITH fakt->idpartner, ;
                        idkonto   WITH cidkonto, ;
                        idkonto2  WITH cidkonto2, ;
                        kolicina WITH fakt->kolicina * sast->kolicina, ;
                        idroba WITH sast->id2, ;
                        nc  WITH ROBA->nc, ;
                        vpc WITH fakt->cijena, ;
                        rabatv WITH fakt->rabat, ;
                        mpc WITH fakt->porez

                     // datfaktp WITH dDatKalk, ;
                  ENDIF

                  SELECT sast
                  SKIP
               ENDDO

            ENDIF
         ENDIF

         SELECT fakt
         SKIP
      ENDDO

      @ box_x_koord() + 10, box_y_koord() + 2 SAY "Dokumenti su preneseni !!"

      kalk_fix_brdok_add_1( @cBrKalk )
      cFaBrDok := UBrojDok( Val( Left( cFaBrDok, 5 ) ) + 1, 5, Right( cFaBrDok, 3 ) )

      Inkey( 4 )
      @ box_x_koord() + 8, box_y_koord() + 2 SAY Space( 30 )

   ENDDO

   Boxc()
   closeret

   RETURN .T.



// ----------------------------------------------------------------------
// Prenos FAKT -> KALK 10 po normativima
// ----------------------------------------------------------------------
FUNCTION fakt_kalk_prenos_normativi()

   LOCAL cIdFirma := self_organizacija_id()
   LOCAL cIdTipDok := "10;11;12;      "
   LOCAL cBrDok := Space( 8 )
   LOCAL cBrKalk := Space( 8 )
   LOCAL GetList := {}

   o_kalk_pripr()

   dDatKalk := Date()
   cIdKonto := PadR( "5100", 7 )

   kalk_set_brkalk_za_idvd( "10", @cBrKalk )

   Box(, 15, 60 )

   kalk_fix_brdok_add_1( @cBrKalk )

   DO WHILE .T.

      nRBr := 0
      nRbr2 := 900
      @ box_x_koord() + 1, box_y_koord() + 2   SAY "Broj kalkulacije 10 -" GET cBrKalk PICT "@!"
      @ box_x_koord() + 1, Col() + 2 SAY "Datum:" GET dDatKalk
      @ box_x_koord() + 4, box_y_koord() + 2   SAY "Konto got. proizvoda zaduzuje :" GET cIdKonto  PICT "@!" VALID P_Konto( @cIdKonto )

      cIdRjFakt := cIdFirma
      dDatFOd := CToD( "" )
      dDatFDo := Date()
      @ box_x_koord() + 6, box_y_koord() + 2 SAY "RJ u FAKT: " GET  cIdRjFakt
      @ box_x_koord() + 7, box_y_koord() + 2 SAY "Dokumenti tipa iz fakt:" GET cidtipdok
      @ box_x_koord() + 8, box_y_koord() + 2 SAY "period od" GET dDAtFOd
      @ box_x_koord() + 8, Col() + 2 SAY "do" GET dDAtFDo
      READ

      IF LastKey() == K_ESC
         EXIT
      ENDIF

      seek_fakt( cIdRjFakt )
      // IF !provjerisif_izbaciti_ovu_funkciju( "!eof() .and. '" + cIdRjFakt + "'==IdFirma", "IDROBA", F_ROBA, "idtipdok $ '" + cIdTipdok + "' .and. dDatFOd<=datdok .and. dDatFDo>=datdok" )
      // MsgBeep( "U ovom dokumentu nalaze se sifre koje ne postoje u tekucem sifrarniku!#Prenos nije izvrsen!" )
      // LOOP
      // ENDIF

      DO WHILE !Eof() .AND. cIdRjFakt == IdFirma

         IF idtipdok $ cIdTipdok .AND. dDatFOd <= datdok .AND. dDatFDo >= datdok // pripada odabranom intervalu

            select_o_roba( fakt->idroba )
            IF roba->tip = "P"
               // radi se o proizvodu

               select_o_roba( fakt->idroba )

               SELECT kalk_pripr
               LOCATE FOR idroba == fakt->idroba
               IF Found()
                  RREPLACE kolicina WITH kolicina + fakt->kolicina
               ELSE
                  SELECT kalk_pripr
                  APPEND BLANK
                  REPLACE idfirma WITH cIdFirma, ;
                     rbr  WITH nRbr, ;
                     idvd WITH "10", ;   // izlazna faktura
                     brdok WITH cBrKalk, ;
                     datdok WITH dDatKalk, ;
                     idtarifa WITH ROBA->idtarifa, ;
                     brfaktp WITH "", ;
                     idkonto   WITH cidkonto, ;
                     idroba WITH fakt->idroba, ;
                     vpc WITH fakt->cijena, ;
                     rabatv WITH fakt->rabat, ;
                     kolicina WITH fakt->kolicina, ;
                     mpc WITH fakt->porez

                  // datfaktp WITH dDatKalk, ;
               ENDIF

            ENDIF
         ENDIF

         SELECT fakt
         SKIP
      ENDDO

      SELECT kalk_pripr
      GO TOP

      DO WHILE !Eof()
         select_o_sastavnice( kalk_pripr->idroba )
         DO WHILE !Eof() .AND. id == kalk_pripr->idroba
            // setaj kroz sast
            // utvr|ivanje nabavnih cijena po sastavnici !!!!!
            select_o_roba( sast->id2 )

            SELECT kalk_pripr
            // roba->nc - nabavna cijena sirovine
            // sast->kolicina - kolicina po jedinici mjera
            RREPLACE fcj WITH fcj + ( roba->nc * sast->kolicina )

            SELECT sast
            SKIP
         ENDDO


         IF select_o_roba( kalk_pripr->idroba )
            hRec := dbf_get_rec()
            hRec[ "nc" ] := kalk_pripr->fcj // nafiluj nabavne cijene proizvoda u sifarnik robe
            update_rec_server_and_dbf( "roba", hRec, 1, "FULL" )
         ENDIF

         SELECT kalk_pripr
         SKIP

      ENDDO

      @ box_x_koord() + 10, box_y_koord() + 2 SAY "Dokumenti su preneseni !"

      kalk_fix_brdok_add_1( @cBrKalk )

      Inkey( 4 )
      @ box_x_koord() + 8, box_y_koord() + 2 SAY Space( 30 )

   ENDDO

   Boxc()

   my_close_all_dbf()

   RETURN .T.
