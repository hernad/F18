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


FUNCTION mat_prenos_fakmat()

   LOCAL _izbor := 1
   LOCAL _opc := {}
   LOCAL _opcexe := {}

   AAdd( _opc, "1. prenos fakt -> mat      " )
   AAdd( _opcexe, {|| prenos() } )
   AAdd( _opc, "2. parametri" )
   AAdd( _opcexe, {|| parametri_prenosa() } )

   f18_menu( "osn", .F., _izbor, _opc, _opcexe )

   RETURN



STATIC FUNCTION parametri_prenosa()

   o_params()
   // select 99; use (my_home()+"params") index (my_home()+"parai1")
   PRIVATE cSection := "T", cHistory := " "; aHistory := {}

   gDirFakt := PadR( gDirFakt, 25 )
   Box(, 4, 70 )
   @ box_x_koord() + 1, box_y_koord() + 2 SAY "Direktorij u kome se nalazi FAKT.DBF:" GET gDirFakt
   @ box_x_koord() + 3, box_y_koord() + 2 SAY "Vrsta mat_naloga u mat   :" GET gVN
   @ box_x_koord() + 4, box_y_koord() + 2 SAY "Vrsta dokumenta mat  :" GET gVD
   READ
   BoxC()
   gDirFakt := Trim( gDirFakt )
   WPar( "df", gDirFakt )
   WPar( "fi", self_organizacija_id() )
   WPar( "vn", gVN )
   WPar( "vd", gVD )
   SELECT 99; USE

   RETURN


STATIC FUNCTION prenos()

   LOCAL gVn := "10"
   LOCAL cIdFirma := self_organizacija_id(), cIdTipDok := "11", cBrdok := Space( 8 ), cBrMat := "", ;
      cIdZaduz := Space( 6 )

   O_MAT_PRIPR
   O_MAT_NALOG

   o_valute()


   dDatMat := Date()
   cIdKonto := cIdKonto2 := Space( 7 )
   //cIdZaduz2 := Space( 6 )

   SELECT mat_nalog
   SET ORDER TO TAG "1"
   SEEK cidfirma + gVN + "X"
   SKIP -1
   IF idvn <> gVN
      cbrmat := "0"
   ELSE
      cbrmat := brnal
   ENDIF

   Box(, 15, 60 )

   cbrmat := PadL( AllTrim( Str( Val( cbrmat ) + 1 ) ), 4, "0" )
   DO WHILE .T.

      nRBr := 0
      @ box_x_koord() + 1, box_y_koord() + 2   SAY "Broj mat_naloga mat " + gVN + " -" GET cBrMat PICT "@!"
      @ box_x_koord() + 1, Col() + 2 SAY "Datum:" GET dDatMat
      @ box_x_koord() + 3, box_y_koord() + 2   SAY "Konto zaduzuje :" GET cIdKonto  PICT "@!" VALID P_Konto( @cIdKonto )
      //@ box_x_koord() + 3, Col() + 2 SAY "Zaduzuje:" GET cIdZaduz  PICT "@!"      VALID Empty( cidzaduz2 ) .OR. p_partner( @cIdZaduz )

      @ box_x_koord() + 6, box_y_koord() + 2 SAY "Broj fakture: " + cIdFirma
      @ box_x_koord() + 6, Col() + 1 SAY "- " + cidtipdok
      @ box_x_koord() + 6, Col() + 1 SAY "-" GET cBrDok
      READ
      IF LastKey() == K_ESC; exit; ENDIF


      //SELECT fakt
      //SEEK cIdFirma + cIdTipDok + cBrDok
      IF !find_fakt_dokument( cIdFirma, cIdTipDok, cBrDok )
      //IF !Found()
         Beep( 4 )
         @ box_x_koord() + 14, box_y_koord() + 2 SAY "Ne postoji ovaj dokument !!"
         Inkey( 4 )
         @ box_x_koord() + 14, box_y_koord() + 2 SAY Space( 30 )
         LOOP
      ELSE
         aMemo := fakt_ftxt_decode( txt )
         IF Len( aMemo ) >= 5
            @ box_x_koord() + 10, box_y_koord() + 2 SAY Trim( amemo[ 3 ] )
            @ box_x_koord() + 11, box_y_koord() + 2 SAY Trim( amemo[ 4 ] )
            @ box_x_koord() + 12, box_y_koord() + 2 SAY Trim( amemo[ 5 ] )
         ELSE
            cTxt := ""
         ENDIF
         Inkey( 0 )
         // cIdPartner:=space(6)
         // @ box_x_koord()+14,box_y_koord()+2 SAY "Sifra partnera:"  GET cIdpartner pict "@!" valid p_partner(@cIdPartner)
         READ

         SELECT mat_pripr
         LOCATE FOR BrDok = cBrDok // faktura je vec prenesena
         IF Found()
            Beep( 4 )
            @ box_x_koord() + 8, box_y_koord() + 2 SAY "Dokument je vec prenesen !!"
            Inkey( 4 )
            @ box_x_koord() + 8, box_y_koord() + 2 SAY Space( 30 )
            LOOP
         ENDIF
         GO BOTTOM
         IF brnal == cBrMat; nRbr := Val( Rbr ); ENDIF
         SELECT fakt
         DO WHILE !Eof() .AND. cIdFirma + cIdTipDok + cBrDok == IdFirma + IdTipDok + BrDok
            select_o_roba( fakt->idroba )

            SELECT fakt
            IF AllTrim( podbr ) == "."
               SKIP
               LOOP
            ENDIF
            IF fakt->cijena <> roba->mpc  // nivelacija
               select_o_roba( fakt->idroba )
               SELECT mat_pripr
               APPEND BLANK
               REPLACE idfirma WITH fakt->idfirma, ;
                  rbr     WITH Str( ++nRbr, 4 ), ;
                  idvn WITH gVN, ;   // izlazna faktura
               idtipdok WITH gVD, ;
                  brnal WITH cBrMat, ;
                  datdok WITH dDatMat, ;
                  brdok WITH fakt->brdok, ;
                  datdok WITH fakt->datdok, ;
                  idkonto   WITH cidkonto, ;
                  idzaduz  WITH cidzaduz, ;
                  datkurs WITH fakt->datdok, ;
                  kolicina WITH 0, ;
                  idroba WITH fakt->idroba, ;
                  cijena WITH 0, ;
                  u_i WITH "1", ;
                  d_p WITH "1", ;
                  iznos with ( fakt->cijena - roba->mpc ) * fakt->kolicina, ;
                  iznos2 WITH iznos * Kurs( datdok )

            ENDIF
            SELECT mat_pripr
            APPEND BLANK
            REPLACE idfirma WITH fakt->idfirma, ;
               rbr     WITH Str( ++nRbr, 4 ), ;
               idvn WITH gVN, ;   // izlazna faktura
            idtipdok WITH gVD, ;
               brnal WITH cBrMat, ;
               datdok WITH dDatMat, ;
               brdok WITH fakt->brdok, ;
               datdok WITH fakt->datdok, ;
               idkonto   WITH cidkonto, ;
               idzaduz  WITH cidzaduz, ;
               datkurs WITH fakt->datdok, ;
               kolicina WITH fakt->kolicina, ;
               idroba WITH fakt->idroba, ;
               cijena WITH fakt->cijena, ;
               u_i WITH "2", ;
               d_p WITH "2", ;
               iznos WITH cijena * kolicina, ;
               iznos2 WITH iznos * Kurs( datdok )

            SELECT fakt
            SKIP
         ENDDO
         @ box_x_koord() + 8, box_y_koord() + 2 SAY "Dokument je prenesen !!"
         Inkey( 4 )
         @ box_x_koord() + 8, box_y_koord() + 2 SAY Space( 30 )
      ENDIF

   ENDDO
   Boxc()
   my_close_all_dbf()

   RETURN
