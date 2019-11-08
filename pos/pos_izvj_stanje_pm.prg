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


STATIC cKontrolnaTabela := ""
STATIC lCekaj := .T.


FUNCTION pos_stanje_artikala_po_odjeljenjima( cD, cS )

   LOCAL nStanje
   LOCAL nSign := 1
   LOCAL cSt
   LOCAL nVrijednost
   LOCAL nCijena := 0
   LOCAL cRSdbf
   LOCAL cVrstaRs
   LOCAL fZaklj

   // ovo su ulazni parametri
   PRIVATE cDat := cD
   PRIVATE cSmjena := cS
   // PRIVATE cIdDio := Space( 2 )
   PRIVATE cIdOdj := Space( 2 )
   PRIVATE cRoba := Space( 60 )
   PRIVATE cLM := ""
   PRIVATE nSir := 40
   PRIVATE nRob := 29
   PRIVATE cNule := "N"
   PRIVATE cKontrolisi

   cKontrolisi := "N"
   cK9 := Space( 3 )
   // cVrstaRs := gVrstaRs

   IF ( PCount() == 0 )
      fZaklj := .F.
   ELSE
      fZaklj := .T.
   ENDIF

   IF !fZaklj
      PRIVATE cDat := gDatum
      PRIVATE cSmjena := " "
   ENDIF

   // o_pos_kase()
   // o_pos_odj()
   // o_sifk()
   // o_sifv()
   // o_roba()
   // o_pos_pos()

   cIdPos := gIdPos

   PRIVATE cUkupno := "N"
   PRIVATE cMink := "N"

   IF fZaklj
      // kod zakljucenja smjene
      aUsl1 := {}
   ELSE

      cIdodj := "R "
      cIdPos := gIdPos
      aNiz := {}

      // IF cVrstaRs <> "K"
      AAdd ( aNiz, { "Prodajno mjesto (prazno-svi)", "cIdPos", "cIdpos='X'.or.empty(cIdPos).or. p_pos_kase(@cIdPos)", "@!", } )
      // ENDIF
      // IF gVodiOdj == "D"
      // AAdd( aNiz, { "Roba/Sirovine", "cIdOdj", "cidodj $ 'R S '", "@!", } )
      // ENDIF

      AAdd ( aNiz, { "Artikli  (prazno-svi)", "cRoba",, "@!S30", } )
      AAdd ( aNiz, { "Izvjestaj se pravi za datum", "cDat",,, } )
      //IF gVSmjene == "D"
      //   AAdd ( aNiz, { "Smjena", "cSmjena",,, } )
      //ENDIF
      AAdd ( aNiz, { "Stampati artikle sa stanjem 0", "cNule", "cNule$'DN'", "@!", } )
      AAdd ( aNiz, { "Prikaz kolone ukupno D/N ", "cUkupno", "cUkupno$'DN'", "@!", } )
      AAdd ( aNiz, { "Prikaz samo kriticnih zaliha (D/N/O) ?", "cMinK", "cMinK$'DNO'", "@!", } )
      AAdd ( aNiz, { "Analiza - kontrolna tabela ?", "cKontrolisi", "cKontrolisi$'DN'", "@!", } )
      AAdd ( aNiz, { "Uslov po K9", "cK9",,, } )
      DO WHILE .T.
         IF !VarEdit( aNiz, 10, 5, 13 + Len( aNiz ), 74, 'USLOVI ZA IZVJESTAJ "STANJE ODJELJENJA"', "B1" )
            CLOSERET
         ENDIF
         aUsl1 := Parsiraj( cRoba, "IdRoba", "C" )
         IF aUsl1 <> NIL
            EXIT
         ELSE
            Msg( "Kriterij za artikal nije korektno postavljen!" )
         ENDIF
      ENDDO
   ENDIF

   IF cMink == "O"
      cNule := "D"
   ENDIF

   cU := R_U
   cI := R_I
   cRSdbf := "ROBA"

   IF cIdOdj = "S "
      cU := S_U
      cI := S_I
      cRSdbf := "SIROV"
   ENDIF

   // IF cVrstaRs == "S"
   // cLM := Space( 5 )
   // nSir := 80
   // nRob := 40
   // ENDIF


   cFilt := ""

   IF Empty( cIdPos )

      // "2": "IdOdj+idroba+DTOS(Datum)"
      // SET ORDER TO TAG "2"
      seek_pos_pos_2( NIL )
      // 1 artikal, 1 stavka u izvjestaju (samo TOPS)

   ELSE
      // SET ORDER TO TAG "5"
      // cFilt := "IDPOS=='" + cIdPos + "'"
      seek_pos_pos_5( cIdPos )

   ENDIF

   IF Len( aUsl1 ) > 0
      IF Empty( cFilt )
         cFilt := aUsl1
      ELSE
         cFilt += ".and." + aUsl1
      ENDIF
   ENDIF

   IF !Empty( cFilt )
      SET FILTER TO &cFilt
   ENDIF

   GO TOP

   nH := 0

   IF !fZaklj
      START PRINT CRET
      Zagl( cIdOdj, cDat, "A" )
   ENDIF

   Podvuci()

   nVrijednost := 0
   _n_rbr := 0
   _total_pst := 0
   _total_ulaz := 0
   _total_izlaz := 0
   _total_stanje := 0

   DO WHILE !Eof()

      nStanje := 0
      nPstanje := 0
      nUlaz := nIzlaz := 0
      cIdRoba := POS->IdRoba

      //
      // pocetno stanje - stanje do
      //

      nSlogova := 0

      DO WHILE !Eof() .AND. POS->IdRoba == cIdRoba .AND. ( POS->Datum < cDat .OR. ( !Empty( cSmjena ) .AND. POS->Datum == cDat .AND. POS->Smjena < cSmjena ) )

         select_o_roba( cIdRoba )
         IF ( FieldPos( "K9" ) ) <> 0 .AND. !Empty( cK9 )
            IF ( field->k9 <> cK9 )
               SELECT pos
               SKIP
               LOOP
            ENDIF
         ENDIF
         SELECT POS

         // IF !Empty ( cIdDio ) .AND. POS->IdDio <> cIdDio
         // SKIP
         // LOOP
         // ENDIF
         IF ( !pos_admin() .AND. pos->idpos = "X" ) .OR. ( !Empty( cIdPos ) .AND. pos->IdPos <> cIdPos )
            // (POS->IdPos="X".and.AllTrim(cIdPos)<>"X").or.;// ?MS
            SKIP
            LOOP
         ENDIF
         //

         IF pos->idvd == "96"
            SKIP
            LOOP   // otpremnice za robu - zdravo
         ENDIF

         ++nSlogova

         IF POS->idvd $ "16#00"
            nPstanje += POS->Kolicina
         ELSEIF POS->idvd $ "IN#NI#" + DOK_IZLAZA
            DO CASE
            CASE POS->IdVd == "IN"
               nPstanje -= ( pos->kolicina - pos->kol2 )
            CASE POS->IdVd == "NI"

            OTHERWISE // 42#01
               nPstanje -= POS->Kolicina
            ENDCASE
         ENDIF
         SKIP
      ENDDO

      //
      // realizacija specificiranog datuma/smjene
      //
      DO WHILE !Eof() .AND. POS->IdRoba == cIdRoba .AND. ( POS->Datum == cDat .OR. ( !Empty( cSmjena ) .AND. POS->Datum == cDat .AND. POS->Smjena < cSmjena ) )

         select_o_roba( cIdRoba )
         IF ( FieldPos( "K9" ) ) <> 0 .AND. !Empty( cK9 )
            IF ( field->k9 <> cK9 )
               SELECT pos
               SKIP
               LOOP
            ENDIF
         ENDIF
         SELECT POS

         // IF !Empty( cIdDio ) .AND. POS->IdDio <> cIdDio
         // SKIP
         // LOOP
         // ENDIF

         IF pos->idvd == "96"
            SKIP
            LOOP
            // otpremnice za robu - zdravo
         ENDIF
         IF ( !pos_admin() .AND. pos->idpos = "X" ) .OR. ( !Empty( cIdPos ) .AND. pos->IdPos <> cIdPos )
            // (POS->IdPos="X".and.AllTrim(cIdPos)<>"X").or.;//?MS
            SKIP
            LOOP
         ENDIF
         //
         ++nSlogova
         IF POS->idvd $ DOK_ULAZA
            nUlaz += POS->Kolicina
         ELSEIF POS->idvd $ "IN#NI#" + DOK_IZLAZA
            DO CASE
            CASE POS->IdVd == "IN"
               nIzlaz += ( pos->kolicina - pos->kol2 )
            CASE POS->IdVd == "NI"
               nIzlaz += 0
            OTHERWISE
               nIzlaz += POS->Kolicina
            ENDCASE
         ENDIF
         SKIP
      ENDDO

      //
      // stampaj
      //

      nStanje := nPstanje + ( nUlaz - nIzlaz )

      IF Round( nStanje, 4 ) <> 0 .OR. cNule == "D" .AND. !( nPstanje == 0 .AND. nUlaz == 0 .AND. nIzlaz == 0 )
         select_o_roba( cIdRoba )
         IF ( FieldPos( "K9" ) ) <> 0 .AND. !Empty( cK9 )
            IF ( field->k9 <> cK9 )
               SELECT pos
               SKIP
               LOOP
            ENDIF
         ENDIF

         IF ( FieldPos( "MINK" ) ) <> 0
            nMink := roba->mink
         ELSE
            nMink := 0
         ENDIF


         IF ( ( cMink <> "D" .AND. ( cNule == "D" .OR. Round( nStanje, 4 ) <> 0 ) ) .OR. ( cMink == "D" .AND. nMink <> 0 .AND. ( nStanje - nMink ) < 0 ) ) .AND. !( cMink == "O" .AND. nMink == 0 .AND. Round( nStanje, 4 ) == 0 )

            nCijena1 := pos_get_mpc()

            ? cLM + PadL( AllTrim( Str( ++_n_rbr, 5 ) ), 5 ) + "."
            ?? " " + cIdRoba, PadR( Naz, nRob ) + " "

            //
            // VRIJEDNOST = CIJENA U SIFRARNIKU * STANJE KOMADA
            nVrijednost += nStanje * nCijena1

            SELECT POS

            ? cLM + Space( 6 )

            ?? Str( nPstanje, 9, 3 )

            IF Round( nUlaz, 4 ) <> 0
               ?? " " + Str( nUlaz, 9, 3 )
            ELSE
               ?? Space( 10 )
            ENDIF

            IF Round( nIzlaz, 4 ) <> 0
               ?? " " + Str( nIzlaz, 9, 3 )
            ELSE
               ?? Space( 10 )
            ENDIF

            ?? " " + Str( nStanje, 10, 3 )

            ?? " " + Str( nCijena1, 10, 3 )

            ?? " " + Str( nStanje * nCijena1, 10, 3 )

            IF cMink <> "N" .AND. nMink > 0
               ? PadR( IF( cMink == "O" .AND. nMink <> 0 .AND. ( nStanje - nMink ) < 0, "*KRITICNO STANJE !*", "" ), 19 )
               ?? "  min.kolic:" + Str( nMink, 9, 3 )
            ENDIF

            _total_pst += nPStanje
            _total_ulaz += nUlaz
            _total_izlaz += nIzlaz
            _total_stanje += nStanje

         ENDIF
      ENDIF

      SELECT POS
      // preko zadanog datuma
      DO WHILE !Eof() .AND. POS->IdRoba == cIdRoba
         SKIP
      ENDDO

   ENDDO

   // IF cVrstaRs <> "S"

   Podvuci()

   ? "Ukupno stanje zaduzenja: "
   ? cLM + Space( 5 ), ;
      Str( _total_pst, 10, 2 ), ;
      Str( _total_ulaz, 10, 2 ), ;
      Str( _total_izlaz, 10, 2 ), ;
      Str( _total_stanje, 10, 2 ), ;
      Str( 0, 10, 2 ), ;
      Str( nVrijednost, 10, 2 )

   Podvuci()

   // ENDIF

   FF
   ENDPRINT

   CLOSE ALL

   RETURN .T.


/*
 *     Podvlaci red u izvjestaju stanje odjeljenja/dijela objekta
 */

STATIC FUNCTION Podvuci()

   ?
   ?? REPL( "-", 6 ), REPL ( "-", 9 ), REPL ( "-", 9 ), REPL ( "-", 9 ), REPL ( "-", 10 ), REPL( "-", 10 ), REPL( "-", 10 )

   RETURN .T.


/* Zagl(cIdOdj,dDat, cVrstaRs)
 *     Ispis zaglavlja izvjestaja stanje odjeljenja/dijela objekta
 */

STATIC FUNCTION Zagl( cIdOdj, dDat, cVrstaRs )

   IF dDat == NIL
      dDat := gDatum
   ENDIF

   ?
   // ZagFirma()

   P_10CPI
   ? PadC( "STANJE ODJELJENJA NA DAN " + FormDat1( dDat ), nSir )
   ? PadC( "-----------------------------------", nSir )

   IF cVrstaRs <> "K"
      ? cLM + "Prod. mjesto:" + iif ( Empty( cIdPos ), "SVE", find_pos_kasa_naz( cIdPos ) )
   ENDIF
   //IF gvodiodj == "D"
  //    ? cLM + "Odjeljenje : " + cIdOdj + "-" + RTrim( find_pos_odj_naziv( cIdOdj ) )
   //ENDIF

   ? cLM + "Artikal    : " + IF( Empty( cRoba ), "SVI", RTrim( cRoba ) )
   ?
   ? cLM + Space( 6 ) + PadR ( "Sifra", 10 ), PadR ( "Naziv artikla", nRob ) + " "
   ? cLM
   ?? "R.broj", "P.stanje ", PadC ( "Ulaz", 9 ), PadC ( "Izlaz", 9 ), PadC ( "Stanje", 10 ), PadC( "Cijena", 10 ), PadC( "Total", 10 )
   ? cLM

   RETURN
