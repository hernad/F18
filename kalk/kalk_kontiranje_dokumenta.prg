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

STATIC dDatMax

MEMVAR gAFin, gAMat, gFunKon1, gFunKon2
MEMVAR dDatVal // funkcija datval setuje privatnu varijablu dDatVal
MEMVAR GetList

/*

 kontiranje naloga

 lAutomatskiSetBrojNaloga - .t. automatski se odrjedjuje broj naloga koji se formira,
                            .f. unosi se broj formiranog naloga
 lAGen - automatsko generisanje
 lViseKalk - vise kalkulacija
 cNalog - zadani broj FIN naloga, ako je EMPTY() ne uzima se !

*/

FUNCTION kalk_kontiranje_fin_naloga( lAutomatskiSetBrojNaloga, lAGen, lViseKalk, cNalog, lAutoBrojac )

   LOCAL cIdFirma
   LOCAL cIdVd
   LOCAL cBrDok
   LOCAL lAFin
   LOCAL lAMat
   LOCAL lAFin2
   LOCAL lAMat2
   LOCAL nRecNo
   LOCAL lPrvoDzok := ( fetch_metric( "kalk_kontiranje_prioritet_djokera", NIL, "N" ) == "D" )
   LOCAL hParamsFakt := fakt_params()
   LOCAL hRecTrfp, cStavka
   LOCAL cGlavniKonto
   LOCAL lPostoji
   LOCAL nCnt
   // LOCAL lVrsteP := hParamsFakt[ "fakt_vrste_placanja" ]
   LOCAL cBrNalogFin, cBrNalogMat
   LOCAL cIdVnTrFP
   LOCAL GetList := {}
   LOCAL nRbr
   LOCAL dDatFaktP
   LOCAL cPom, cPomFK777
   LOCAL cIdKonto
   LOCAL nIznosKontiratiKM, nIznosKontiratiDEM
   LOCAL dDatDok, cIdPartner
   
   LOCAL cBrFakt1, cBrFakt2, cBrFakt3, cBrFakt4, cBrFakt5
   LOCAL dDatFakt1, dDatFakt2, dDatFakt3, dDatFakt4, dDatFakt5
   LOCAL cRj1, cRj2
   LOCAL nLen
   LOCAL nStranaValutaIznos
   LOCAL nKursPomocna
   LOCAL cEnabUvozSwitchKALK := fetch_metric( "fin_enab_uvoz_switch_kalk", NIL, "N" )

   PRIVATE p_cKontoKontiranje1, p_cKontoKontiranje2, p_cKontoKontiranje3
   PRIVATE p_cPartnerKontiranje1, p_cPartnerKontiranje2, p_cPartnerKontiranje3, p_cPartnerKontiranje4


   // LOCAL cIdVrsteP

   cRj1 := ""
   cRj2 := ""
   IF ( lAGen == NIL )
      lAGen := .F.
   ENDIF
   IF ( lViseKalk == NIL )
      lViseKalk := .F.
   ENDIF
   IF ( dDatMax == NIL )
      dDatMax := CToD( "" )
   ENDIF
   IF ( lAutoBrojac == NIL )
      lAutoBrojac := .T.
   ENDIF

   SELECT F_FINMAT
   IF !Used()
      o_finmat()
   ENDIF

   IF lAutomatskiSetBrojNaloga == NIL
      lAutomatskiSetBrojNaloga := .F.
   ENDIF

   IF ( cNalog == NIL )
      IF is_kalk_fin_isti_broj()
         cNalog := finmat->brdok
         IF Val( AllTrim( cNalog ) ) > 0 // 00001 => 00000001, ako je 00001/BH ostaviti
            cNalog := PadL( AllTrim( cNalog ), 8, "0" )
         ENDIF
      ENDIF
   ENDIF

   lAFin := ( gAFin == "D" )
   IF lAFin
      IF finmat->idvd $ "49#71#79#21#22#72#29#02"
         RETURN .F.
      ENDIF
      lAfin := .T.
   ENDIF

   IF !lAFin
      RETURN .F.
   ENDIF

   lAFin2 := !lAutomatskiSetBrojNaloga
   lAMat := ( lAutomatskiSetBrojNaloga .AND. gAMat == "D" )
   IF lAMat .AND. f18_use_module( "mat" )
      Beep( 1 )
      lAMat := Pitanje(, "Formirati MAT nalog?", "D" ) == "D"
      O_TRMP
   ENDIF

   lAMat2 := ( !lAutomatskiSetBrojNaloga .AND. gAMat <> "0" )
   cBrNalogFin := ""
   cBrNalogMat := ""

   IF lAFin .OR. lAFin2
      select_o_fin_pripr()
      SET ORDER TO TAG "1"
      GO TOP
      my_dbf_zap()
      o_nalog()
      SET ORDER TO TAG "1"

   ENDIF

   SELECT finmat
   GO TOP
   cGlavniKonto := finmat_glavni_konto( finmat->idvd )
   select_o_koncij( cGlavniKonto )

   IF cEnabUvozSwitchKALK == "D"
      // kalk_10_gen_uvoz( finmat->brdok ) => .F. ako su spediterski troskovi 0
      IF kalk_10_gen_uvoz( finmat->brdok )
         my_close_all_dbf()
         RETURN .T.
      ENDIF
   ENDIF

   // select_o_trfp()
   use_sql_trfp( koncij->shema, finmat->IdVD )
   IF EOF()
      info_bar("kont", "TRFP prazno: " + koncij->shema + "-" + finmat->IdVD)
      my_close_all_dbf()
      RETURN .T.
   ENDIF
   // SEEK finmat->IdVD + koncij->shema

   cIdVnTrFP := trfp->IdVN
   // uzmi vrstu naloga koja ce se uzeti u odnosu na prvu kalkulaciju
   // koja se kontira

   // IF KONCIJ->( FieldPos( "FN14" ) ) <> 0 .AND. !Empty( KONCIJ->FN14 ) .AND. finmat->IDVD == "14"
   // cIdVnTrFP := KONCIJ->FN14
   // ENDIF

   IF lAFin .OR. lAFin2
      IF Empty( cNalog )
         IF lAutoBrojac
            cBrNalogFin := fin_novi_broj_dokumenta( finmat->idfirma, cIdVnTrFP )
         ELSE
            cBrNalogFin := fin_prazan_broj_naloga()
         ENDIF
      ELSE
         cBrNalogFin := cNalog // ako je zadat broj naloga taj i uzmi
      ENDIF

   ENDIF
   SELECT finmat
   GO TOP

   dDatNal := finmat->datdok
   IF lAGen == .F.

      Box( "brn?", 5, 55 )
      set_cursor_on()

      IF lAutomatskiSetBrojNaloga
         IF !lAFin
            cBrNalogFin := ""
         ELSE
            @ box_x_koord() + 1, box_y_koord() + 2  SAY "Broj naloga u FIN  " + finmat->idfirma + " - " + cIdVnTrFP + " - " + cBrNalogFin
         ENDIF

         IF !lAMat
            cBrNalogMat := ""
         ELSE
            @ box_x_koord() + 2, box_y_koord() + 2 SAY "Broj naloga u MAT  " + finmat->idfirma + " - " + cIdVnTrFP + " - " + cBrNalogMat
         ENDIF

         @ box_x_koord() + 4, box_y_koord() + 2 SAY "Datum naloga: "
         ?? dDatNal

         IF lAFin .OR. lAMat
            Inkey( 2 )
         ENDIF

      ELSE
         IF lAFin2
            @ box_x_koord() + 1, box_y_koord() + 2 SAY "Broj naloga u FIN  " + finmat->idfirma + " - " + cIdVnTrFP + " -" GET cBrNalogFin
         ENDIF

         IF lAMat2
            @ box_x_koord() + 2, box_y_koord() + 2 SAY "Broj naloga u MAT  " + finmat->idfirma + " - " + cIdVnTrFP + " -" GET cBrNalogMat
         ENDIF

         @ box_x_koord() + 5, box_y_koord() + 2 SAY "(ako je broj naloga prazan - ne vrsi se kontiranje)"
         READ
         ESC_BCR
      ENDIF

      BoxC()

   ENDIF

   nRbr := 0

   // start kontiranje
   SELECT finmat
   nCnt := 0
   Box( "<CENTAR>", 5, 70 )
   @ box_x_koord() + 1, box_y_koord() + 2 SAY  koncij->shema + " : KALK: " + finmat->brdok + "-" + " BRF: " + AllTrim( finmat->brfaktp )
   @ box_x_koord() + 2, box_y_koord() + 2 SAY  "    -> FINMAT -> FIN " + cIdVnTrFP + " - " + cBrNalogFin

   DO WHILE !Eof()

      cIDVD := finmat->IdVD
      cBrDok := finmat->BrDok

      IF ValType( p_cKontoKontiranje1 ) <> "C"
         p_cKontoKontiranje1 := ""
         p_cKontoKontiranje2 := ""
         p_cKontoKontiranje3 := ""
         p_cPartnerKontiranje1 := p_cPartnerKontiranje2 := p_cPartnerKontiranje3 := p_cPartnerKontiranje4 := ""
         cBrFakt1 := cBrFakt2 := cBrFakt3 := cBrFakt4 := cBrFakt5 := Space( 10 )
         dDatFakt1 := dDatFakt2 := dDatFakt3 := dDatFakt4 := dDatFakt5 := CToD( "" )
         cRj1 := ""
         cRj2 := ""
      ENDIF

      PRIVATE dDatVal := CToD( "" )  // inicijalizuj datum valute
      // cIdVrsteP := "  "

      DO WHILE cIdVD == finmat->IdVD .AND. cBrDok == finmat->BrDok .AND. !Eof()

         lDatFakt := .F.
         cGlavniKonto := finmat_glavni_konto( finmat->idvd )
         // IF finmat->idvd $ "14#95#96"
         // select_o_koncij( finmat->idkonto2 )
         // ELSE
         select_o_koncij( cGlavniKonto )
         // ENDIF
         select_o_roba( finmat->idroba )

         SELECT trfp
         GO TOP
         // SEEK cIdVD + koncij->shema
         DO WHILE !Eof() .AND. !Empty( cBrNalogFin ) // .AND. trfp->idvd == cIdVD  .AND. trfp->shema == koncij->shema

            lDatFakt := .F.
            hRecTrfp := dbf_get_rec()
            cStavka := hRecTrfp[ "id" ]

            SELECT finmat
            POREZ2 := 0 // finmat je imao polje porez2 koristeno za ppu
            // evo sta se kontira
            nIznosKontiratiDEM := &cStavka

            // SELECT trfp
            IF !Empty( hRecTrfp[ "idtarifa" ] ) .AND. hRecTrfp[ "idtarifa" ] <> finmat->idtarifa
               // ako u sifarniku parametara postoji tarifa prenosi po tarifama
               nIznosKontiratiDEM := 0
            ENDIF

            IF Empty( hRecTrfp[ "idtarifa" ] ) .AND. roba->tip $ "U"
               nIznosKontiratiDEM := 0 // roba tipa u,t
            ENDIF

            // iskoristeno u slucaju RN, gdje se za kontiranje stavke
            // 901-999 koriste sa tarifom XXXXXX
            IF finmat->idtarifa == "XXXXXX" .AND. trfp->idtarifa <> finmat->idtarifa
               nIznosKontiratiDEM := 0
            ENDIF

            IF nIznosKontiratiDEM <> 0
               // IF lPoRj // ako je iznos elementa <> 0, dodaj stavku u fpripr
               // IF TRFP->porj = "D"
               // cIdRj := KONCIJ->idrj
               // ELSEIF TRFP->porj = "S"
               // cIdRj := KONCIJ->sidrj
               // ELSE
               // cIdRj := ""
               // ENDIF
               // ENDIF

               SELECT fin_pripr
               IF hRecTrfp[ "znak" ] == "-"
                  nIznosKontiratiDEM := -nIznosKontiratiDEM
               ENDIF

               IF "#DF#" $ ( hRecTrfp[ "naz" ] )
                  lDatFakt := .T.
               ENDIF

               dDatFaktP := CToD( "" )
               IF lDatFakt
                  dDatFaktP := finmat->DatFaktP
               ENDIF

               // IF gBaznaV == "P"
               // nIznosKontiratiKM :=  nIznosKontiratiDEM * Kurs( dDatFaktP, "P", "D" )
               // ELSE
               nIznosKontiratiKM := nIznosKontiratiDEM
               // nIznosKontiratiDEM := nIznosKontiratiKM * Kurs( dDatFaktP, "D", "P" )
               // ENDIF

               IF "IDKONTO" == PadR( hRecTrfp[ "idkonto" ], 7 )
                  cIdKonto := finmat->idkonto
               ELSEIF "IDKONT2" == PadR( hRecTrfp[ "idkonto" ], 7 )
                  cIdKonto := finmat->idkonto2
               ELSE
                  cIdKonto := hRecTrfp[ "idkonto" ]
               ENDIF

               IF lPrvoDzok
                  cPomFK777 := Trim( gFunKon1 )
                  cIdkonto := StrTran( cIdkonto, "F1", &cPomFK777 )
                  cPomFK777 := Trim( gFunKon2 )
                  cIdkonto := StrTran( cIdkonto, "F2", &cPomFK777 )
                  cIdkonto := StrTran( cIdkonto, "A1", Right( Trim( finmat->idkonto ), 1 ) )
                  cIdkonto := StrTran( cIdkonto, "A2", Right( Trim( finmat->idkonto ), 2 ) )
                  cIdkonto := StrTran( cIdkonto, "B1", Right( Trim( finmat->idkonto2 ), 1 ) )
                  cIdkonto := StrTran( cIdkonto, "B2", Right( Trim( finmat->idkonto2 ), 2 ) )
               ENDIF

               IF ( cIdkonto = 'KK' )  .OR.  ( cIdkonto = 'KP' )  .OR. ( cIdkonto = 'KO' ) // pocinje sa KK, KO, KP
                  IF Right( Trim( cIdkonto ), 3 ) == "(2)"  // trazi idkonto2
                     select_o_koncij( finmat->idkonto2 )
                     cIdkonto := StrTran( cIdkonto, "(2)", "" )
                     cIdkonto := koncij->( &cIdkonto )
                     SELECT fin_pripr

                  ELSEIF Right( Trim( cIdkonto ), 3 ) == "(1)"  // trazi idkonto
                     select_o_koncij( finmat->idkonto )
                     cIdkonto := StrTran( cIdkonto, "(1)", "" )
                     cIdkonto := koncij->( &cIdkonto )
                     SELECT fin_pripr
                  ELSE
                     cIdkonto := koncij->( &cIdkonto )
                  ENDIF

               ELSEIF !lPrvoDzok
                  cPomFK777 := Trim( gFunKon1 )
                  cIdkonto := StrTran( cIdkonto, "F1", &cPomFK777 )
                  cPomFK777 := Trim( gFunKon2 )
                  cIdkonto := StrTran( cIdkonto, "F2", &cPomFK777 )
                  cIdkonto := StrTran( cIdkonto, "A1", Right( Trim( finmat->idkonto ), 1 ) )
                  cIdkonto := StrTran( cIdkonto, "A2", Right( Trim( finmat->idkonto ), 2 ) )
                  cIdkonto := StrTran( cIdkonto, "B1", Right( Trim( finmat->idkonto2 ), 1 ) )
                  cIdkonto := StrTran( cIdkonto, "B2", Right( Trim( finmat->idkonto2 ), 2 ) )
               ENDIF

               IF ValType( cIdKonto ) != "C"
                  cIdKonto := Replicate( "X", 7 )
               ENDIF
               IF ValType( p_cKontoKontiranje1 ) != "C"
                  p_cKontoKontiranje1 := Space( 7 )
               ENDIF
               IF ValType( p_cKontoKontiranje2 ) != "C"
                  p_cKontoKontiranje2 := Space( 7 )
               ENDIF
               IF ValType( p_cKontoKontiranje3 ) != "C"
                  p_cKontoKontiranje3 := Space( 7 )
               ENDIF

               cIdkonto := StrTran( cIdkonto, "?1", Trim( p_cKontoKontiranje1 ) )
               cIdkonto := StrTran( cIdkonto, "?2", Trim( p_cKontoKontiranje2 ) )
               cIdkonto := StrTran( cIdkonto, "?3", Trim( p_cKontoKontiranje3 ) )
               cIdkonto := PadR( cIdkonto, 7 )
               cBrDok := Space( 8 )
               dDatDok := finmat->datdok

               // IF hRecTrfp[ "dokument" ] == "R"
               // radni nalog
               // cBrDok := finmat->idZaduz2
               IF hRecTrfp[ "dokument" ] == "1"
                  cBrDok := finmat->brdok
               ELSEIF hRecTrfp[ "dokument" ] == "2"
                  cBrDok := finmat->brfaktp
                  dDatDok := finmat->datfaktp
               ELSEIF hRecTrfp[ "dokument" ] == "3"
                  dDatDok := dDatNal
               ELSEIF hRecTrfp[ "dokument" ] == "9"
                  dDatDok := dDatMax // koristi se za vise kalkulacija
               ENDIF

               cIdPartner := Space( 6 )
               IF hRecTrfp[ "partner" ] == "1"  // stavi Partnera
                  cIdPartner := finmat->IdPartner

               ELSEIF hRecTrfp[ "partner" ] == "A"
                  cIdpartner := p_cPartnerKontiranje1
                  IF !Empty( dDatFakt1 )
                     dDatDok := dDatFakt1
                  ENDIF
                  IF !Empty( cBrFakt1 )
                     cBrDok := cBrFakt1
                  ENDIF
               ELSEIF hRecTrfp[ "partner" ] == "B"
                  cIdpartner := p_cPartnerKontiranje2
                  IF !Empty( dDatFakt2 )
                     dDatDok := dDatFakt2
                  ENDIF
                  IF !Empty( cBrFakt2 )
                     cBrDok := cBrFakt2
                  ENDIF
               ELSEIF hRecTrfp[ "partner" ] == "C"
                  cIdpartner := p_cPartnerKontiranje3
                  IF !Empty( dDatFakt3 )
                     dDatDok := dDatFakt3
                  ENDIF
                  IF !Empty( cBrFakt3 )
                     cBrDok := cBrFakt3
                  ENDIF
               ELSEIF hRecTrfp[ "partner" ] == "D"
                  cIdpartner := p_cPartnerKontiranje4
                  IF !Empty( dDatFakt4 )
                     dDatDok := dDatFakt4
                  ENDIF
                  IF !Empty( cBrFakt4 )
                     cBrDok := cBrFakt4
                  ENDIF
               ELSEIF hRecTrfp[ "partner" ] == "E"
                  cIdpartner := cPartner5
                  IF !Empty( dDatFakt5 )
                     dDatDok := dDatFakt5
                  ENDIF
                  IF !Empty( cBrFakt5 )
                     cBrDok := cBrFakt5
                  ENDIF
               ELSEIF hRecTrfp[ "partner" ] == "O"   // stavi  banku
                  cIdpartner := KONCIJ->banka
               ENDIF

               lPostoji := .F.
               SEEK finmat->IdFirma + cIdVnTrFP + cBrNalogFin

               my_flock()
               IF Found()
                  lPostoji := .F.
                  DO WHILE !Eof() .AND. finmat->idfirma + cIdVnTrFP + cBrNalogFin == fin_pripr->IdFirma + fin_pripr->idvn + fin_pripr->BrNal
                     IF fin_pripr->IdKonto == cIdKonto .AND. fin_pripr->IdPartner == cIdPartner .AND. ;
                           hRecTrfp[ "d_p" ] == fin_pripr->d_p  .AND. fin_pripr->idtipdok == finmat->idvd .AND. ;
                           PadR( fin_pripr->brdok, 10 ) == PadR( cBrDok, 10 ) .AND. fin_pripr->datdok == dDatDok // .AND. ;
                        // iif( lPoRj, Trim( idrj ) == Trim( cIdRj ), .T. )
                        // provjeriti da li se vec nalazi stavka koju dodajemo
                        lPostoji := .T.
                        EXIT
                     ENDIF
                     SKIP
                  ENDDO

                  IF !lPostoji
                     SEEK finmat->idfirma + cIdVnTrFP + cBrNalogFin + "ZZZZ"
                     SKIP -1
                     IF fin_pripr->idfirma + fin_pripr->idvn + fin_pripr->brnal == finmat->idfirma + cIdVnTrFP + cBrNalogFin
                        nRbr := fin_pripr->Rbr + 1
                     ELSE
                        nRbr := 1
                     ENDIF
                     APPEND BLANK
                  ENDIF
               ELSE
                  SEEK finmat->idfirma + cIdVnTrFP + cBrNalogFin + "ZZZZ"
                  SKIP -1
                  IF fin_pripr->idfirma + fin_pripr->idvn + fin_pripr->brnal == finmat->idfirma + cIdVnTrFP + cBrNalogFin
                     nRbr := fin_pripr->Rbr + 1
                  ELSE
                     nRbr := 1
                  ENDIF
                  APPEND BLANK
               ENDIF

               // REPLACE iznosDEM WITH fin_pripr->iznosDEM + nIznosKontiratiDEM
               REPLACE iznosBHD WITH fin_pripr->iznosBHD + nIznosKontiratiKM
               REPLACE idKonto  WITH cIdKonto
               REPLACE IdPartner  WITH cIdPartner
               REPLACE D_P      WITH hRecTrfp[ "d_p" ]

               REPLACE fin_pripr->idFirma  WITH finmat->idfirma, ;
                  fin_pripr->IdVN     WITH cIdVnTrFP, ;
                  fin_pripr->BrNal    WITH cBrNalogFin, ;
                  fin_pripr->IdTipDok WITH finmat->IdVD, ;
                  fin_pripr->BrDok    WITH cBrDok, ;
                  fin_pripr->DatDok   WITH dDatDok, ;
                  fin_pripr->opis     WITH hRecTrfp[ "naz" ]

               IF Left( Right( hRecTrfp[ "naz" ], 2 ), 1 ) $ ".;"  // nacin zaokruzenja
                  REPLACE opis WITH Left( hRecTrfp[ "naz" ], Len( hRecTrfp[ "naz" ] ) - 2 )
               ENDIF

               IF "#V#" $  hRecTrfp[ "naz" ]  // stavi datum valutiranja
                  REPLACE datval WITH dDatVal
                  REPLACE opis WITH StrTran( hRecTrfp[ "naz" ], "#V#", "" )
                  // IF lVrsteP
                  // REPLACE k4 WITH cIdVrsteP
                  // ENDIF
               ENDIF

               // kontiraj radnu jedinicu
               IF "#RJ1#" $  hRecTrfp[ "naz" ]  // stavi datum valutiranja
                  REPLACE IdRJ WITH cRj1, fin_pripr->opis WITH StrTran( hRecTrfp[ "naz" ], "#RJ1#", "" )
               ENDIF

               IF "#RJ2#" $  hRecTrfp[ "naz" ]  // stavi datum valutiranja
                  REPLACE IdRJ WITH cRj2, fin_pripr->opis WITH StrTran( hRecTrfp[ "naz" ], "#RJ2#", "" )
               ENDIF

               // IF lPoRj
               // REPLACE IdRJ WITH cIdRj
               // ENDIF

               IF !lPostoji
                  REPLACE Rbr  WITH nRbr // fin_pripr
               ENDIF
               my_unlock()
            ENDIF // nIznosKontiratiDEM <>0

            SELECT trfp
            nCnt++
            @ box_x_koord() + 4, box_y_koord() + 15 SAY Str( nCnt, 5 )
            SKIP
         ENDDO

         SELECT finmat
         SKIP
      ENDDO
   ENDDO

   SELECT finmat
   SKIP -1
   BoxC()

   IF lAFin .OR. lAFin2
      SELECT fin_pripr
      GO TOP
      SEEK finmat->idfirma + cIdVnTrFP + cBrNalogFin
      my_flock()
      //IF Found()
      nKursPomocna := Kurs( dDatFaktP, "D", "P" )
         DO WHILE !Eof() .AND. fin_pripr->IDFIRMA + fin_pripr->IDVN + fin_pripr->BRNAL == finmat->idfirma + cIdVnTrFP + cBrNalogFin
            cPom := Right( fin_pripr->opis, 1 )
            // na desnu stranu opisa stavim npr "ZADUZ MAGACIN          0"
            // onda ce izvrsiti zaokruzenje na 0 decimalnih mjesta
            IF cPom $ "0125"
               nLen := Len( Trim( fin_pripr->opis ) )
               REPLACE opis WITH Left( Trim( fin_pripr->opis ), nLen - 1 )
               IF cPom = "5"  // zaokruzenje na 0.5 DEM
                  REPLACE iznosbhd WITH round2( fin_pripr->iznosbhd, 2 )
               ELSE
                  REPLACE iznosbhd WITH Round( fin_pripr->iznosbhd, Min( Val( cPom ), 2 ) )
               ENDIF
            ENDIF
            nStranaValutaIznos := fin_pripr->iznosbhd * nKursPomocna
            REPLACE iznosdem WITH round2( nStranaValutaIznos, 2 )
            SKIP
         ENDDO
      //ENDIF
      my_unlock()
   ENDIF


   // IF !lViseKalk // ako je vise kalkulacija ne zatvaraj tabele
   // my_close_all_dbf()
   // RETURN .T.
   // ENDIF

   RETURN .T.



// --------------------------------
// validacija broja naloga
// --------------------------------
STATIC FUNCTION __val_nalog( cNalog )

   LOCAL lRet := .T.
   LOCAL cTmp
   LOCAL cChar
   LOCAL i

   cTmp := Right( cNalog, 4 )

   // vidi jesu li sve brojevi
   FOR i := 1 TO Len( cTmp )

      cChar := SubStr( cTmp, i, 1 )

      IF cChar $ "0123456789"
         LOOP
      ELSE
         lRet := .F.
         EXIT
      ENDIF

   NEXT

   RETURN lRet



/* Konto(nBroj, cDef, cTekst)
 *   param: nBroj - koju varijablu punimo (1-p_cKontoKontiranje1,2-p_cKontoKontiranje2,3-p_cKontoKontiranje3)
 *   param: cDef - default tj.ponudjeni tekst
 *   param: cTekst - opis podatka koji se unosi
 *     Edit proizvoljnog teksta u varijablu p_cKontoKontiranje1,p_cKontoKontiranje2 ili p_cKontoKontiranje3 ukoliko je izabrana varijabla duzine 0 tj.nije joj vec dodijeljena vrijednost
 *  return 0


    Konto(1, "10", "Dobavljac domaci-10 strani-20")

   Funkciju koriste sheme kontiranja kalk-fin
 */

FUNCTION Konto( nBroj, cDef, cTekst )

   LOCAL GetList := {}

   IF ( nBroj == 1 .AND. Len( p_cKontoKontiranje1 ) <> 0 ) .OR. ;
         ( nBroj == 2 .AND. Len( p_cKontoKontiranje2 ) <> 0 ) .OR. ;
         ( nBroj == 3 .AND. Len( p_cKontoKontiranje3 ) <> 0 )
      RETURN 0
   ENDIF

   Box(, 2, 60 )
   set_cursor_on()
   @ box_x_koord() + 1, box_y_koord() + 2 SAY cTekst
   IF nBroj == 1
      p_cKontoKontiranje1 := cDef
      @ Row(), Col() + 1 GET p_cKontoKontiranje1
   ELSEIF nBroj == 2
      p_cKontoKontiranje2 := cDef
      @ Row(), Col() + 1 GET p_cKontoKontiranje2
   ELSE
      p_cKontoKontiranje3 := cDef
      @ Row(), Col() + 1 GET p_cKontoKontiranje3
   ENDIF
   READ
   BoxC()

   RETURN 0


// Primjer SetKonto(1, partner_is_ino(finmat->IdPartner) , "30", "31")
//
FUNCTION SetKonto( nBroj, lValue, cTrue, cFalse )

   LOCAL cPom

   IF ( nBroj == 1 .AND. Len( p_cKontoKontiranje1 ) <> 0 ) .OR. ;
         ( nBroj == 2 .AND. Len( p_cKontoKontiranje2 ) <> 0 ) .OR. ;
         ( nBroj == 3 .AND. Len( p_cKontoKontiranje3 ) <> 0 )
      RETURN 0
   ENDIF

   IF lValue
      cPom := cTrue
   ELSE
      cPom := cFalse
   ENDIF

   IF nBroj == 1
      p_cKontoKontiranje1 := cPom
   ELSEIF nBroj == 2
      p_cKontoKontiranje2 := cPom
   ELSE
      p_cKontoKontiranje3 := cPom
   ENDIF

   RETURN 0




/* RJ(nBroj,cDef,cTekst)
 *   param: nBroj - koju varijablu punimo (1-cRj1,2-cRj2)
 *   param: cDef - default tj.ponudjeni tekst
 *   param: cTekst - opis podatka koji se unosi
 *     Edit proizvoljnog teksta u varijablu cRj1 ili cRj2 ukoliko je izabrana varijabla duzine 0 tj.nije joj vec dodijeljena vrijednost
 *  \return 0
 */

FUNCTION RJ( nBroj, cDef, cTekst )

   PRIVATE GetList := {}

   IF ( nBroj == 1 .AND. Len( cRJ1 ) <> 0 ) .OR. ( nBroj == 2 .AND. Len( cRj2 ) <> 0 )
      RETURN 0
   ENDIF

   Box(, 2, 60 )
   set_cursor_on()
   @ box_x_koord() + 1, box_y_koord() + 2 SAY cTekst
   IF nBroj == 1
      cRJ1 := cdef
      @ Row(), Col() + 1 GET cRj1
   ELSEIF nBroj == 2
      cRJ2 := cdef
      @ Row(), Col() + 1 GET cRj2
   ENDIF
   READ
   BoxC()

   RETURN 0


FUNCTION kalk_datval()
   RETURN datval()


/*
   setovanje datuma valutiranja pri kontiranju
   treba da setuje privatnu varijablu DatVal

    ova funkcija treba setovati PRIVATE dDatVal

*/

FUNCTION DatVal()

   LOCAL nUvecati := 15
   // LOCAL hRec
   LOCAL nRokPartner

   PRIVATE GetList := {}

   PushWA()
   IF find_kalk_doks_by_broj_dokumenta( finmat->idfirma, finmat->idvd, finmat->brdok )
      dDatVal := field->datval
   ELSE
      dDatVal := CToD( "" )
   ENDIF

   dDatVal := fix_dat_var( dDatVal, .T. )
   IF Empty( dDatVal )
      // IF kalk_imp_autom() // osloni se na rok placanja
      nRokPartner := get_partn_sifk_sifv( "ROKP", finmat->idpartner, .T. )
      IF ValType( nRokPartner ) == "N"
         nUvecati := nRokPartner
      ENDIF
      IF !Empty( fix_dat_var( finmat->datFaktP, .T. ) )
         dDatVal := finmat->datFaktP + nUvecati
      ENDIF
   ENDIF

   PopWa()

   RETURN 0 // funkcija se koristi u kontiranju i mora vratiti 0


FUNCTION kalk_set_doks_total_fields( nNv, nVpv, nMpv, nRabat )

   IF field->mu_i = "1"
      nNV += field->nc * ( field->kolicina - field->gkolicina - field->gkolicin2 )
      nVPV += field->vpc * ( field->kolicina - field->gkolicina - field->gkolicin2 )
   ELSEIF field->mu_i = "P"
      nNV += field->nc * ( field->kolicina - field->gkolicina - field->gkolicin2 )
      nVPV += field->vpc * ( field->kolicina - field->gkolicina - field->gkolicin2 )
   ELSEIF field->mu_i = "3"
      nVPV += field->vpc * ( field->kolicina - field->gkolicina - field->gkolicin2 )
   ELSEIF field->mu_i == "5"
      nNV -= field->nc * ( field->kolicina )
      nVPV -= field->vpc * ( field->kolicina )
      nRabat += field->vpc * ( field->rabatv / 100 ) * field->kolicina
   ENDIF

   IF field->pu_i == "1"
      IF Empty( field->mu_i )
         nNV += field->nc * field->kolicina
      ENDIF
      nMPV += field->mpcsapp * field->kolicina
   ELSEIF field->pu_i == "P"
      IF Empty( field->mu_i )
         nNV += field->nc * field->kolicina
      ENDIF
      nMPV += field->mpcsapp * field->kolicina
   ELSEIF field->pu_i == "5"
      IF Empty( field->mu_i )
         nNV -= field->nc * field->kolicina
      ENDIF
      nMPV -= field->mpcsapp * field->kolicina
   ELSEIF field->pu_i == "I"
      nMPV -= field->mpcsapp * field->gkolicin2
      nNV -= field->nc * field->gkolicin2
   ELSEIF field->pu_i == "3"
      nMPV += field->mpcsapp * field->kolicina
   ENDIF

   RETURN .T.


/*
 *     Ako se radi o privremenom rezimu obrade KALK dokumenata setuju se vrijednosti parametara gCijene i kalk_metoda_nc() na vrijednosti u dvoclanom nizu aRezim


FUNCTION IspitajRezim()

   IF !Empty( aRezim )
    --  gCijene   = aRezim[ 1 ]
      kalk_metoda_nc() = aRezim[ 2 ]
   ENDIF

   RETURN .T.

 */



FUNCTION kalk_open_tabele_za_kontiranje()

   o_finmat()
   // o_konto()
   // o_partner()
   // o_tdok()
   // o_roba()
   // o_tarifa()

   RETURN .T.




FUNCTION predisp()

   LOCAL _ret := .F.

   IF field->k1 == "P"
      _ret := .T.
   ENDIF

   RETURN _ret






// Ako je dan < 10
// return { 01.predhodni_mjesec , zadnji.predhodni_mjesec}
// else
// return { 01.tekuci_mjesec, danasnji dan }

FUNCTION kalk_rpt_datumski_interval( dToday )

   LOCAL nDay, nFDOm
   LOCAL dDatOd, dDatDo

   nDay := Day( dToday )
   nFDOm := BoM( dToday )

   IF nDay < 10
      // prvi dan u tekucem mjesecu - 1
      dDatDo := nFDom - 1
      // prvi dan u proslom mjesecu
      dDatOd := BoM( dDatDo )

   ELSE
      dDatOd := nFDom
      dDatDo := dToday
   ENDIF

   RETURN { dDatOd, dDatDo }
