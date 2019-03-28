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

MEMVAR dDatVal // funkcija datval setuje privatnu varijablu dDatVal

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
   LOCAL _fakt_params := fakt_params()
   LOCAL nIznosKontiratiDEM
   LOCAL hRecTrfp, cStavka

   PRIVATE lVrsteP := _fakt_params[ "fakt_vrste_placanja" ]

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

   //SELECT F_TRFP
   //USE
   //o_trfp()

   //SELECT F_KONCIJ
   //IF !Used()
    //  o_koncij()
   //ENDIF

   //IF FieldPos( "IDRJ" ) <> 0
  //  lPoRj := .T.
   //ELSE
    //  lPoRj := .F.
   //ENDIF

   //SELECT F_VALUTE
   //IF !Used()
    //  o_valute()
   //ENDIF

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
      IF finmat->idvd $ "49#71#79#21#22"
          RETURN .F.
      ENDIF
      Beep( 1 )
      IF !lAGen
         lAfin := Pitanje(, "KALK: Formirati FIN nalog?", "D" ) == "D"
      ELSE
         lAfin := .T.
      ENDIF
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

   cBrNalF := ""
   cBrNalM := ""

   IF lAFin .OR. lAFin2

      select_o_fin_pripr()
      SET ORDER TO TAG "1"
      GO TOP
      //IF reccount2()
      //  MsgBeep("FIN priprema izbrisana !")
      //ENDIF
      my_dbf_zap()
      o_nalog()
      SET ORDER TO TAG "1"

   ENDIF

   SELECT finmat
   GO TOP

   IF finmat->idvd $ "14#95#96"
      select_o_koncij( finmat->idkonto2 )
   ELSE
      select_o_koncij( finmat->idkonto )
   ENDIF

   select_o_trfp()
   SEEK finmat->IdVD + koncij->shema

   cIdVN := field->IdVN
   // uzmi vrstu naloga koja ce se uzeti u odnosu na prvu kalkulaciju
   // koja se kontira

   IF KONCIJ->( FieldPos( "FN14" ) ) <> 0 .AND. !Empty( KONCIJ->FN14 ) .AND. finmat->IDVD == "14"
      cIdVN := KONCIJ->FN14
   ENDIF

   IF lAFin .OR. lAFin2

      IF Empty( cNalog )

         IF lAutoBrojac
            cBrNalF := fin_novi_broj_dokumenta( finmat->idfirma, cIdVn )
         ELSE
            cBrNalF := fin_prazan_broj_naloga()
         ENDIF
      ELSE
         cBrNalF := cNalog // ako je zadat broj naloga taj i uzmi
      ENDIF

   ENDIF

   SELECT finmat
   GO TOP

   dDatNal := datdok

   IF lAGen == .F.

      Box( "brn?", 5, 55 )

      SET CURSOR ON

      IF lAutomatskiSetBrojNaloga
         IF !lAFin
            cBrNalF := ""
         ELSE
            @ box_x_koord() + 1, box_y_koord() + 2  SAY "Broj naloga u FIN  " + finmat->idfirma + " - " + cIdvn + " - " + cBrNalF
         ENDIF

         IF !lAMat
            cBrBalM := ""
         ELSE
            @ box_x_koord() + 2, box_y_koord() + 2 SAY "Broj naloga u MAT  " + finmat->idfirma + " - " + cIdvn + " - " + cBrNalM
         ENDIF

         @ box_x_koord() + 4, box_y_koord() + 2 SAY "Datum naloga: "

         ?? dDatNal

         IF lAFin .OR. lAMat
            Inkey( 3 )
         ENDIF

      ELSE
         IF lAFin2
            @ box_x_koord() + 1, box_y_koord() + 2 SAY "Broj naloga u FIN  " + finmat->idfirma + " - " + cIdvn + " -" GET cBrNalF
         ENDIF

         IF lAMat2
            @ box_x_koord() + 2, box_y_koord() + 2 SAY "Broj naloga u MAT  " + finmat->idfirma + " - " + cIdvn + " -" GET cBrNalM
         ENDIF

         @ box_x_koord() + 5, box_y_koord() + 2 SAY "(ako je broj naloga prazan - ne vrsi se kontiranje)"
         READ
         ESC_BCR
      ENDIF

      BoxC()

   ENDIF

   nRbr := 0
   nRbr2 := 0

   SELECT finmat
   MsgO( "KALK(shema, [" + AllTrim( finmat->brdok ) + "/" + AllTrim( finmat->brfaktp ) + "]) -> FINMAT -> FIN / " + cIdVN + " - " + cBrNalF  )

   PRIVATE cKonto1 := NIL

   DO WHILE !Eof()

      cIDVD := finmat->IdVD
      cBrDok := finmat->BrDok

      IF ValType( cKonto1 ) <> "C"
         PRIVATE cKonto1 := ""
         PRIVATE cKonto2 := ""
         PRIVATE cKonto3 := ""
         PRIVATE cPartner1 := cPartner2 := cPartner3 := cPartner4 := cPartner5 := ""
         PRIVATE cBrFakt1 := cBrFakt2 := cBrFakt3 := cBrFakt4 := cBrFakt5 := Space( 10 )
         PRIVATE dDatFakt1 := dDatFakt2 := dDatFakt3 := dDatFakt4 := dDatFakt5 := CToD( "" )
         PRIVATE cRj1 := ""
         PRIVATE cRj2 := ""
      ENDIF

      PRIVATE dDatVal := CToD( "" )  // inicijalizuj datum valute
      PRIVATE cIdVrsteP := "  " // i vrstu placanja

      DO WHILE cIdVD == finmat->IdVD .AND. cBrDok == finmat->BrDok .AND. !Eof()

         lDatFakt := .F.

         IF finmat->idvd $ "14#95#96"
            select_o_koncij( finmat->idkonto2 )
         ELSE
            select_o_koncij( finmat->idkonto )
         ENDIF

         select_o_roba( finmat->idroba )

         SELECT trfp
         GO TOP
         SEEK cIdVD + koncij->shema

         DO WHILE !Eof() .AND. !Empty( cBrNalF ) .AND. trfp->idvd == cIDVD  .AND. trfp->shema == koncij->shema

            lDatFakt := .F.
            hRecTrfp := dbf_get_rec()
            cStavka := hRecTrfp[ "id" ]

            SELECT finmat
            POREZ2 := 0 // finmat je imao polje porez2 koristeno za ppu
            nIznosKontiratiDEM := &cStavka

            SELECT trfp

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

               //IF lPoRj // ako je iznos elementa <> 0, dodaj stavku u fpripr
              //    IF TRFP->porj = "D"
              //       cIdRj := KONCIJ->idrj
              //    ELSEIF TRFP->porj = "S"
              //       cIdRj := KONCIJ->sidrj
              //    ELSE
              //       cIdRj := ""
              //    ENDIF
               //ENDIF

               SELECT fin_pripr

               IF hRecTrfp[ "znak" ] == "-"
                  nIznosKontiratiDEM := -nIznosKontiratiDEM
               ENDIF

               IF "#DF#" $ ( hRecTrfp[ "naz" ] )
                  lDatFakt := .T.
               ENDIF

               dDFDok := CToD( "" )
               IF lDatFakt
                  dDFDok := finmat->DatFaktP
               ENDIF

               IF gBaznaV == "P"
                  nIznosKontiratiKM :=  nIznosKontiratiDEM * Kurs( dDFDok, "P", "D" )
               ELSE
                  nIznosKontiratiKM := nIznosKontiratiDEM
                  nIznosKontiratiDEM := nIznosKontiratiKM * Kurs( dDFDok, "D", "P" )

               ENDIF

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
               IF ValType( cKonto1 ) != "C"
                  cKonto1 := Space( 7 )
               ENDIF
               IF ValType( cKonto2 ) != "C"
                  cKonto2 := Space( 7 )
               ENDIF
               IF ValType( cKonto3 ) != "C"
                  cKonto3 := Space( 7 )
               ENDIF

               cIdkonto := StrTran( cIdkonto, "?1", Trim( cKonto1 ) )
               cIdkonto := StrTran( cIdkonto, "?2", Trim( cKonto2 ) )
               cIdkonto := StrTran( cIdkonto, "?3", Trim( cKonto3 ) )

               cIdkonto := PadR( cIdkonto, 7 )
               cBrDok := Space( 8 )
               dDatDok := finmat->datdok

               //IF hRecTrfp[ "dokument" ] == "R"
                  // radni nalog
                //  cBrDok := finmat->idZaduz2
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
                  cIdpartner := cPartner1
                  IF !Empty( dDatFakt1 )
                     DatDok := dDatFakt1
                  ENDIF
                  IF !Empty( cBrFakt1 )
                     cBrDok := cBrFakt1
                  ENDIF
               ELSEIF hRecTrfp[ "partner" ] == "B"
                  cIdpartner := cPartner2
                  IF !Empty( dDatFakt2 )
                     dDatDok := dDatFakt2
                  ENDIF
                  IF !Empty( cBrFakt2 )
                     cBrDok := cBrFakt2
                  ENDIF
               ELSEIF hRecTrfp[ "partner" ] == "C"
                  cIdpartner := cPartner3
                  IF !Empty( dDatFakt3 )
                     dDatDok := dDatFakt3
                  ENDIF
                  IF !Empty( cBrFakt3 )
                     cBrDok := cBrFakt3
                  ENDIF
               ELSEIF hRecTrfp[ "partner" ] == "D"
                  cIdpartner := cPartner4
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

               fExist := .F.
               SEEK finmat->IdFirma + cIdvn + cBrNalF

               my_flock()
               IF Found()
                  fExist := .F.
                  DO WHILE !Eof() .AND. finmat->idfirma + cIdvn + cBrNalF == IdFirma + idvn + BrNal
                     IF IdKonto == cIdKonto .AND. IdPartner == cIdPartner .AND. ;
                           hRecTrfp[ "d_p" ] == d_p  .AND. idtipdok == finmat->idvd .AND. ;
                           PadR( brdok, 10 ) == PadR( cBrDok, 10 ) .AND. datdok == dDatDok //.AND. ;
                           //iif( lPoRj, Trim( idrj ) == Trim( cIdRj ), .T. )
                        // provjeriti da li se vec nalazi stavka koju dodajemo
                        fExist := .T.
                        EXIT
                     ENDIF
                     SKIP
                  ENDDO

                  IF !fExist

                     SEEK finmat->idfirma + cIdVN + cBrNalF + "ZZZZ" // fin_pripr
                     SKIP -1
                     IF fin_pripr->( idfirma + idvn + brnal ) == finmat->idfirma + cIdVN + cBrNalF
                        nRbr := fin_pripr->Rbr + 1
                     ELSE
                        nRbr := 1
                     ENDIF
                     APPEND BLANK
                  ENDIF
               ELSE

                  SEEK finmat->idfirma + cIdVN + cBrNalF + "ZZZZ" // fin_pripr
                  SKIP -1
                  IF idfirma + idvn + brnal == finmat->idfirma + cIdVN + cBrNalF
                     nRbr := Rbr + 1
                  ELSE
                     nRbr := 1
                  ENDIF
                  APPEND BLANK
               ENDIF

               REPLACE iznosDEM WITH iznosDEM + nIznosKontiratiDEM
               REPLACE iznosBHD WITH iznosBHD + nIznosKontiratiKM
               REPLACE idKonto  WITH cIdKonto
               REPLACE IdPartner  WITH cIdPartner
               REPLACE D_P      WITH hRecTrfp[ "d_p" ]

               REPLACE fin_pripr->idFirma  WITH finmat->idfirma, ;
                  fin_pripr->IdVN     WITH cIdVN, ;
                  fin_pripr->BrNal    WITH cBrNalF, ;
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
                  IF lVrsteP
                     REPLACE k4 WITH cIdVrsteP
                  ENDIF
               ENDIF

               // kontiraj radnu jedinicu
               IF "#RJ1#" $  hRecTrfp[ "naz" ]  // stavi datum valutiranja
                  REPLACE IdRJ WITH cRj1, opis WITH StrTran( hRecTrfp[ "naz" ], "#RJ1#", "" )
               ENDIF

               IF "#RJ2#" $  hRecTrfp[ "naz" ]  // stavi datum valutiranja
                  REPLACE IdRJ WITH cRj2, opis WITH StrTran( hRecTrfp[ "naz" ], "#RJ2#", "" )
               ENDIF

               //IF lPoRj
                //  REPLACE IdRJ WITH cIdRj
               //ENDIF

               IF !fExist
                  REPLACE Rbr  WITH nRbr // fin_pripr
               ENDIF
               my_unlock()
            ENDIF // nIznosKontiratiDEM <>0

            SELECT trfp
            SKIP
         ENDDO // trfp->id==cIDVD


         SELECT finmat
         SKIP
      ENDDO
   ENDDO

   SELECT finmat
   SKIP -1

   IF lAFin .OR. lAFin2
      SELECT fin_pripr
      GO TOP
      SEEK finmat->idfirma + cIdVN + cBrNalF
      my_flock()
      IF Found()
         DO WHILE !Eof() .AND. IDFIRMA + IDVN + BRNAL == finmat->idfirma + cIdVN + cBrNalF
            cPom := Right( opis, 1 )
            // na desnu stranu opisa stavim npr "ZADUZ MAGACIN          0"
            // onda ce izvrsiti zaokruzenje na 0 decimalnih mjesta
            IF cPom $ "0125"
               nLen := Len( Trim( opis ) )
               REPLACE opis WITH Left( Trim( opis ), nLen - 1 )
               IF cPom = "5"  // zaokruzenje na 0.5 DEM
                  REPLACE iznosbhd WITH round2( iznosbhd, 2 )
                  REPLACE iznosdem WITH round2( iznosdem, 2 )
               ELSE
                  REPLACE iznosbhd WITH Round( iznosbhd, Min( Val( cPom ), 2 ) )
                  REPLACE iznosdem WITH Round( iznosdem, Min( Val( cPom ), 2 ) )
               ENDIF
            ENDIF
            SKIP
         ENDDO
      ENDIF
      my_unlock()
   ENDIF

   MsgC()

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
 *   param: nBroj - koju varijablu punimo (1-cKonto1,2-cKonto2,3-cKonto3)
 *   param: cDef - default tj.ponudjeni tekst
 *   param: cTekst - opis podatka koji se unosi
 *     Edit proizvoljnog teksta u varijablu ckonto1,ckonto2 ili ckonto3 ukoliko je izabrana varijabla duzine 0 tj.nije joj vec dodijeljena vrijednost
 *  return 0
 */

FUNCTION Konto( nBroj, cDef, cTekst )

   PRIVATE GetList := {}

   IF ( nBroj == 1 .AND. Len( cKonto1 ) <> 0 ) .OR. ;
         ( nBroj == 2 .AND. Len( cKonto2 ) <> 0 ) .OR. ;
         ( nBroj == 3 .AND. Len( cKonto3 ) <> 0 )
      RETURN 0
   ENDIF

   Box(, 2, 60 )
   SET CURSOR ON
   @ box_x_koord() + 1, box_y_koord() + 2 SAY cTekst
   IF nBroj == 1
      cKonto1 := cDef
      @ Row(), Col() + 1 GET cKonto1
   ELSEIF nBroj == 2
      cKonto2 := cDef
      @ Row(), Col() + 1 GET cKonto2
   ELSE
      cKonto3 := cDef
      @ Row(), Col() + 1 GET cKonto3
   ENDIF
   READ
   BoxC()

   RETURN 0


// Primjer SetKonto(1, partner_is_ino(finmat->IdPartner) , "30", "31")
//
FUNCTION SetKonto( nBroj, lValue, cTrue, cFalse )

   LOCAL cPom

   IF ( nBroj == 1 .AND. Len( cKonto1 ) <> 0 ) .OR. ;
         ( nBroj == 2 .AND. Len( cKonto2 ) <> 0 ) .OR. ;
         ( nBroj == 3 .AND. Len( cKonto3 ) <> 0 )
      RETURN 0
   ENDIF

   IF lValue
      cPom := cTrue
   ELSE
      cPom := cFalse
   ENDIF

   IF nBroj == 1
      cKonto1 := cPom
   ELSEIF nBroj == 2
      cKonto2 := cPom
   ELSE
      cKonto3 := cPom
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
   SET CURSOR ON
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
   ELSEIF mu_i = "P"
      nNV += field->nc * ( field->kolicina - field->gkolicina - field->gkolicin2 )
      nVPV += field->vpc * ( field->kolicina - field->gkolicina - field->gkolicin2 )
   ELSEIF mu_i = "3"
      nVPV += field->vpc * ( field->kolicina - field->gkolicina - field->gkolicin2 )
   ELSEIF mu_i == "5"
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
   ELSEIF pu_i == "3"
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
   o_konto()
   o_partner()
   o_tdok()
   // o_roba()
   o_tarifa()

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
