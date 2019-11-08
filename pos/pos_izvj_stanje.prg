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

FUNCTION pos_stanje_artikala

   PARAMETERS cDat, cSmjena

   LOCAL nStanje
   LOCAL nSign := 1
   LOCAL cSt
   LOCAL nVrijednost
   LOCAL nCijena := 0
   LOCAL cRSdbf

   // PRIVATE cIdDio := Space ( 2 )
   PRIVATE cIdOdj := Space ( 2 )
   PRIVATE cRoba := Space( 60 )
   PRIVATE cLM := ""
   PRIVATE nSir := 40
   PRIVATE nRob := 29
   PRIVATE cNule := "N"

   fZaklj := iif ( PCount() == 0, .F., .T. )

   IF !fZaklj
      PRIVATE cDat := gDatum, cSmjena := " "
   ENDIF

   // o_pos_kase()
   // o_pos_odj()
   // o_sifk()
   // o_sifv()
   // o_roba()
   // o_pos_pos()

   cIdPos := gIdPos

   IF fZaklj
      // kod zakljucenja smjene
      aUsl1 := ".t."
   ELSE

      aNiz := {}
      // IF cVrstaRs <> "K"
      AAdd ( aNiz, { "Prodajno mjesto (prazno-svi)", "cIdPos", "cIdpos='X'.or.empty(cIdPos).or. p_pos_kase(@cIdPos)", "@!", } )
      // ENDIF

      // IF gVodiodj == "D"
      // AAdd( aNiz, { "Odjeljenje (prazno-sva)", "cIdOdj", "Empty (cIdOdj).or.P_Odj(@cIdOdj)", "@!", } )
      // ENDIF

      AAdd ( aNiz, { "Artikli  (prazno-svi)", "cRoba",, "@!S30", } )
      AAdd ( aNiz, { "Izvjestaj se pravi za datum", "cDat",,, } )

      //IF gVSmjene == "D"
      //   AAdd ( aNiz, { "Smjena", "cSmjena",,, } )
      //ENDIF

      AAdd ( aNiz, { "Stampati artikle sa stanjem 0", "cNule", "cNule$'DN'", "@!", } )
      DO WHILE .T.
         IF !VarEdit( aNiz, 10, 5, 21, 74, 'USLOVI ZA IZVJESTAJ "STANJE ODJELJENJA"', "B1" )
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

   IF !Empty ( cIdOdj )
      select_o_pos_odj( cIdOdj )
      IF Zaduzuje == "S"
         cU := S_U
         cI := S_I
         cRSdbf := "SIROV"
      ELSE
         cU := R_U
         cI := R_I
         cRSdbf := "ROBA"
      ENDIF
   ENDIF

   // SELECT POS
   // SET ORDER TO TAG "2"
   // ("2", "IdOdj+idroba+DTOS(Datum)", KUMPATH+"POS")

   // SEEK cIdOdj
   seek_pos_pos_2( cIdOdj )

   IF !( aUsl1 == ".t." )
      SET FILTER TO &aUsl1
   ENDIF
   GO TOP

   EOF CRET

   xIdOdj := "??"
   _n_rbr := 0


   // pravljenje izvjestaja
   IF !fZaklj
      START PRINT CRET
      Zagl( cIdOdj, cDat )
   ENDIF


   IF !Empty( cIdOdj )
      Podvuci()
   ENDIF

   DO WHILE !Eof()

      IF !Empty( cIdOdj ) .AND. POS->IdOdj <> cIdOdj
         EXIT
      ENDIF

      nStanje := 0
      nVrijednost := 0

      _idodj := pos->IdOdj

      IF Empty( cIdOdj ) .AND. _IdOdj <> xIdOdj

         IF fZaklj
            Zagl( _IdOdj, NIL )
         ENDIF

         Podvuci()

         xIdOdj := _IdOdj

         select_o_pos_odj( _IdOdj )

         ? cLM + Id + "-" + Naz

         Podvuci()

         cU := R_U
         cI := R_I
         cRSdbf := "ROBA"

         SELECT POS

      ENDIF

      // 1) pocetno stanje - vrijednost ... sve ispod datuma zadanog izvjestajem
      DO WHILE !Eof() .AND. pos->idodj == _idodj

         nStanje := 0
         nVrijednost := 0
         nPstanje := 0
         nUlaz := nIzlaz := 0
         cIdRoba := pos->idroba

         DO WHILE !Eof() .AND. pos->idodj == _idodj .AND. ;
               pos->idRoba == cIdRoba .AND. ;
               ( pos->datum < cDat .OR. ( !Empty ( cSmjena ) .AND. pos->datum == cDat .AND. pos->smjena < cSmjena ) )

            // IF !Empty( cIdDio ) .AND. POS->IdDio <> cIdDio
            // SKIP
            // LOOP
            // ENDIF

            IF ( !pos_admin() .AND. pos->idpos = "X" ) .OR. ( !Empty( cIdPos ) .AND. IdPos <> cIdPos )
               // (POS->IdPos="X" .and. AllTrim (cIdPos)<>"X") .or. ;   // ?MS
               SKIP
               LOOP
            ENDIF

            IF ( pos->idvd == "96" )
               SKIP
               LOOP
               // preskoci
            ENDIF

            IF POS->idvd $ "16#00"
               nPstanje += POS->Kolicina
               nVrijednost += POS->Kolicina * POS->Cijena
            ELSEIF POS->idvd $ "IN#NI#" + DOK_IZLAZA
               DO CASE
               CASE POS->IdVd == "IN"
                  // if pos->kolicina <> 0
                  nPstanje -= ( POS->Kolicina - POS->Kol2 )
                  nVrijednost += ( POS->Kol2 - POS->Kolicina ) * POS->Cijena
                  // else
                  // nPstanje := pos->kol2
                  // nVrijednost := pos->kol2 * pos->cijena
                  // endif
               CASE POS->IdVd == "NI"
                  // ne mijenja kolicinu
                  nVrijednost := POS->Kolicina * POS->Cijena
               OTHERWISE
                  nPstanje -= POS->Kolicina
                  nVrijednost -= POS->Kolicina * POS->Cijena
               ENDCASE
            ENDIF
            SKIP
         ENDDO

         // 2) stanje na tekuci dan
         DO WHILE !Eof() .AND. pos->idodj == _idodj .AND. ;
               pos->idroba == cIdRoba .AND. ;
               ( pos->datum == cDat .OR. ( !Empty( cSmjena ) .AND. POS->Datum == cDat .AND. POS->Smjena < cSmjena ) )

            // IF !Empty( cIdDio ) .AND. POS->IdDio <> cIdDio
            // SKIP
            // LOOP
            // ENDIF
            IF ( !pos_admin() .AND. pos->idpos = "X" ) .OR. ( !Empty( cIdPos ) .AND. IdPos <> cIdPos )
               // (POS->IdPos="X" .and. AllTrim (cIdPos)<>"X") .or. ;  // ?MS
               SKIP
               LOOP
            ENDIF
            //

            IF pos->idvd == "96"
               SKIP
               LOOP   // otpremnice za robu - zdravo
            ENDIF

            IF POS->idvd $ "16#00"
               nUlaz += pos->Kolicina
               nVrijednost += POS->Kolicina * POS->Cijena
            ELSEIF pos->idvd $  "IN#NI#" + DOK_IZLAZA
               DO CASE
               CASE POS->IdVd == "IN"
                  // if pos->kolicina <> 0
                  nIzlaz += ( pos->kolicina - pos->kol2 )
                  nVrijednost += ( pos->kol2 - pos->kolicina ) * POS->Cijena
                  // else
                  // nIzlaz := pos->kol2
                  // nVrijednost := pos->kol2 * pos->cijena
                  // endif
               CASE POS->IdVd == "NI"
                  // ne mijenja kolicinu
                  nVrijednost := POS->Kolicina * POS->Cijena
               OTHERWISE
                  nIzlaz += POS->Kolicina
                  nVrijednost -= POS->Kolicina * POS->Cijena
               ENDCASE
            ENDIF
            SKIP
         ENDDO

         nStanje := nPstanje + nUlaz - nIzlaz

         IF Round( nStanje, 4 ) <> 0 .OR. cNule == "D"

            select_o_roba( cIdRoba )

            ? cLM + PadL( AllTrim( Str( ++_n_rbr, 5 ) ), 5 ) + ")"
            ?? cIdRoba, PadR( roba->naz, nRob ) + " "

            //
            SELECT POS

            ?
            ?? Str ( nPstanje, 9, 3 )

            IF Round ( nUlaz, 4 ) <> 0
               ?? " " + Str( nUlaz, 9, 3 )
            ELSE
               ?? Space ( 10 )
            ENDIF

            IF Round ( nIzlaz, 4 ) <> 0
               ?? " " + Str( nIzlaz, 9, 3 )
            ELSE
               ?? Space ( 10 )
            ENDIF

            ?? " " + Str ( nStanje, 10, 3 )

            ?? " " + Str( roba->mpc, 10, 3 )

            ?? " " + Str( nStanje * roba->mpc, 10, 3 )

         ENDIF

         DO WHILE ( !Eof() .AND. POS->IdOdj == _IdOdj .AND. POS->IdRoba == cIdRoba )
            SKIP
         ENDDO
      ENDDO

      IF fZaklj
         PaperFeed()
         ENDPRINT
      ENDIF
   ENDDO

   IF !fZaklj
      PaperFeed ()
      ENDPRINT
   ENDIF

   CLOSE ALL

   RETURN .T.




STATIC FUNCTION Podvuci()

   ?
   ?? REPL( "-", 5 ), REPL ( "-", 9 ), REPL ( "-", 9 ), REPL ( "-", 9 ), REPL ( "-", 10 ), REPL( "-", 10 ), REPL( "-", 10 )

   RETURN .T.



STATIC FUNCTION Zagl( cIdOdj, dDat )

   IF ( dDat == NIL )
      dDat := gDatum
   ENDIF


   // ZagFirma()

   P_10CPI
   ? PadC( "STANJE ODJELJENJA NA DAN " + FormDat1( dDat ), nSir )
   ? PadC( "-----------------------------------", nSir )

   ? cLM + "Prod. mjesto:" + iif ( Empty( cIdPos ), "SVE", find_pos_kasa_naz( cIdPos ) )

   //IF gvodiodj == "D"
    //  ? cLM + "Odjeljenje : " + cIdOdj + "-" + RTrim( find_pos_odj_naziv( cIdOdj ) )
   //ENDIF

   ? cLM + "Artikal    : " + IF( Empty( cRoba ), "SVI", RTrim( cRoba ) )
   ?
   ? cLM + PadR ( "Sifra", 10 ), PadR ( "Naziv artikla", nRob ) + " "
   ? cLM
   ?? "R.broj", "P.stanje ", PadC ( "Ulaz", 9 ), PadC ( "Izlaz", 9 ), PadC ( "Stanje", 10 ), PadC( "Cijena", 10 ), PadC( "Total", 10 )
   ? cLM

   RETURN .T.
