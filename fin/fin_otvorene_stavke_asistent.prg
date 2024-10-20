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

/*

FUNCTION fin_asistent_otv_st()

   LOCAL nSaldo
   LOCAL nSljRec
   LOCAL nOdem
   LOCAL _rec, _rec_suban
   LOCAL _max_rows := f18_max_rows() - 5
   LOCAL _max_cols := f18_max_cols() - 5
   LOCAL nRecBrDok
   PRIVATE cIdKonto
   PRIVATE cIdFirma
   PRIVATE cIdPartner
   PRIVATE cBrDok

   o_konto()
   -- o_partner()
   o_suban()

   // ovo su parametri kartice
   cIdFirma := self_organizacija_id()
   cIdKonto := Space( Len( suban->idkonto ) )
   cIdPartner := Space( Len( suban->idPartner ) )

   cIdFirma := fetch_metric( "fin_kartica_id_firma", my_user(), cIdFirma )
   cIdKonto := fetch_metric( "fin_kartica_id_konto", my_user(), cIdKonto )
   cIdPartner := fetch_metric( "fin_kartica_id_partner", my_user(), cIdPartner )

   cIdKonto := PadR( cidkonto, Len( suban->idkonto ) )
   cIdPartner := PadR( cidpartner, Len( suban->idPartner ) )
   // kupci cDugPot:=1
   cDugPot := "1"

   Box(, 3, 60 )
   @ box_x_koord() + 1, box_y_koord() + 2 SAY "Konto   " GET cIdKonto   VALID p_konto( @cIdKonto )  PICT "@!"
   @ box_x_koord() + 2, box_y_koord() + 2 SAY "Partner " GET cIdPartner VALID p_partner( @cIdPartner ) PICT "@!"
   @ box_x_koord() + 3, box_y_koord() + 2 SAY "Konto duguje / potrazuje" GET cDugPot when {|| cDugPot := iif( cidkonto = '54', '2', '1' ), .T. } VALID  cdugpot $ "12"
   READ
   BoxC()

   IF LastKey() == K_ESC
      RETURN .F.
   ENDIF

   set_metric( "fin_kartica_id_firma", my_user(), cIdFirma )
   set_metric( "fin_kartica_id_konto", my_user(), cIdKonto )
   set_metric( "fin_kartica_id_partner", my_user(), cIdPartner )

   // kreiraj oext
   IF !cre_osuban_dbf()
      RETURN .F.
   ENDIF


   MsgO( "Preuzimanje podataka sa SQL servera ..." )
   // SELECT suban
   // SEEK cIdfirma + cIdkonto + cIdpartner
   find_suban_by_konto_partner( cIdfirma, cIdkonto, cIdpartner, NIL, "IdFirma,IdKonto,IdPartner,brdok" )
   MsgC()

   Box(, 1, 70 )
   // ukupan broj storno racuna za partnera
   nBrojStornoRacuna := 0

   DO WHILE !Eof() .AND. field->idfirma + field->idkonto + field->idpartner == cIdfirma + cIdkonto + cIdpartner

      cBrDok := field->brdok
      nSaldo := 0
      nRecBrDokStart := RecNo()

      @ box_x_koord() + 1, box_y_koord() + 2 SAY field->idfirma + "-" + field->idkonto + "-" +  field->idpartner + " / " +  field->brdok

      // proracunaj saldo za partner+dokument
      DO WHILE !Eof() .AND. cIdfirma + cIdkonto + cIdpartner + cBrdok == field->idfirma + field->idkonto + field->idpartner + field->brdok

         IF cDugPot = field->d_p .AND. Empty( field->brdok )
            MsgBeep( "Postoje nepopunjen brojevi veze :" + ;
               field->idvn + "-" + field->brdok + "/" + field->rbr + "##Morate ih popuniti !" )
            my_close_all_dbf()
            RETURN .F.
         ENDIF

         IF field->d_p = "1"
            nSaldo += field->iznosbhd
         ELSE
            nSaldo -= field->iznosbhd
         ENDIF
         SKIP
      ENDDO


      IF Round( nSaldo, 4 ) <> 0 // saldo za dokument + partner postoji
         // napuni tabelu osuban za partner+dokument
         // SEEK cIdfirma + cIdkonto + cIdpartner + cBrdok
         GO nRecBrDokStart
         lStorno := .F.

         DO WHILE !Eof() .AND. cIdfirma + cIdkonto + cIdpartner + cBrdok == ;
               field->idfirma + field->idkonto + field->idpartner + field->brdok

            SELECT suban
            _rec_suban := dbf_get_rec()

            SELECT osuban
            APPEND BLANK

            dbf_update_rec( _rec_suban ) // upisi sve u osuban iz suban

            // a sada poradi na ovom zapisu
            _rec := dbf_get_rec()

            _rec[ "_recno" ] := suban->( RecNo() )
            _rec[ "_ppk1" ] := ""
            _rec[ "_obrdok" ] := _rec[ "brdok" ]

            IF ( _rec[ "iznosbhd" ] < 0 .AND. _rec[ "d_p" ] == cDugPot )
               lStorno := .T.
            ENDIF

            IF ( ( nSaldo > 0 .AND. cDugPot = "2" ) ) .AND. _rec[ "d_p" ] <> cDugPot
               // neko je bez veze zatvorio uplate (ili se mozda radi o avansima)
               _rec[ "brdok" ] := avans_br_dok()
            ENDIF

            dbf_update_rec( _rec )

            SELECT suban
            SKIP

         ENDDO

         IF lStorno
            ++nBrojStornoRacuna
         ENDIF

      ENDIF

   ENDDO

   BoxC()

   SELECT osuban
   SET ORDER TO TAG "DATUM"  // DToS( datdok ) + DToS( iif( Empty( DatVal ), DatDok, DatVal ) )

   Box(, 1, 75 )
   DO WHILE .T.


      SELECT osuban // svaki put prolazak ispocetka
      GO TOP


      lNasaoRacun := .F. // varijabla koja kazuje da je racun/storno racun nadjen

      // prvi krug  (nadji ukupno stvorene obaveze za jednog partnera
      nZatvori := 0


      cZatvori := Chr( 200 ) + Chr( 255 ) // nijedan brdok dokument u bazi ne moze biti chr(200)+chr(255)
      dDatDok := CToD( "" )

      nZatvoriStorno := 0
      cZatvoriStorno := Chr( 200 ) + Chr( 255 )
      dDatDokStorno := CToD( "" )

      DO WHILE !Eof() // ovdje su sada sve stavke za jednog partnera, sortirane hronoloski

         IF Empty( field->_ppk1 ) // neobradjene stavke


            IF !lNasaoRacun .AND. field->d_p == cDugPot // nastanak duga

               IF ( field->iznosbhd > 0 )
                  IF nBrojStornoRacuna > 0
                     // prvo se moraju zatvoriti storno racuni
                     // zato preskacemo sve pozitivne racune koji se nalaze ispred

                     // MsgBeep("debug: pozitivne preskacem " + STR(nBrojStornoRacuna) + "  BrDok:" +  brdok )
                     SKIP
                     LOOP
                  ENDIF

                  @ box_x_koord() + 1, box_y_koord() + 2 SAY "      racun: " + field->brdok
                  cZatvori := field->brdok // racun
                  nZatvori := field->iznosbhd
                  dDatDok := field->datdok
                  cZatvoriStorno := Chr( 200 ) + Chr( 255 )

               ELSE

                  @ box_x_koord() + 1, box_y_koord() + 2 SAY "storno racun: " + field->brdok

                  cZatvoriStorno := field->brdok // storno racun
                  nZatvoriStorno := field->iznosbhd
                  dDatDokStorno := field->datdok
                  cZatvori := Chr( 200 ) + Chr( 255 )
                  --nBrojStornoRacuna
                  // MsgBeep("debug: -- " + STR(nBrojStornoRacuna) + " / BrDok:" + BrDok)

               ENDIF

               lNasaoRacun := .T.

               _rec := dbf_get_rec()
               _rec[ "_ppk1" ] := "1"
               dbf_update_rec( _rec )

               GO TOP // prosli smo ovo
               // krenuti od pocetka da sabrati cZatvori
               LOOP

            ELSEIF lNasaoRacun .AND. ( cZatvori == field->brdok )

               // sve ostale stavke koje su hronoloski starije
               // koje imaju isti broj dokumenta kao nadjeni racun
               // saberi

               IF field->d_p == cDugPot
                  nZatvori += field->iznosbhd
               ELSE
                  nZatvori -= field->iznosbhd
               ENDIF

               _rec := dbf_get_rec()
               _rec[ "_ppk1" ] := "1"
               dbf_update_rec( _rec )
               // prosli smo ovo - marker


            ELSEIF lNasaoRacun .AND. ( cZatvoriStorno == field->brdok )

               // isto vrijedi i za stavke iza storno racuna a koje imaju isti broj veze

               IF field->d_p == cDugPot
                  nZatvoriStorno += field->iznosbhd
               ELSE
                  nZatvoriStorno -= field->iznosbhd
               ENDIF

               _rec := dbf_get_rec()
               _rec[ "_ppk1" ] := "1"
               dbf_update_rec( _rec )
               // prosli smo ovo

            ENDIF

         ENDIF
         SKIP
      ENDDO

      IF !lNasaoRacun
         // nema racuna za zatvoriti
         MsgBeep( "prosao sve racune - nisam  nista nasao - izlazim" )
         EXIT
      ENDIF

      // drugi krug - sada se formiraju uplate
      // MsgBeep(" 2.krug: idem sada formirati uplate - zatvaranje racuna ")
      lNasaoRacun := .F.
      GO TOP


      DO WHILE !Eof()

         IF Empty( field->_ppk1 )


            IF field->d_p <> cDugPot // potrazna strana

               nUplaceno := field->iznosbhd

               // prvo cemo se rijesiti storno racuna, ako ih ima
               IF nUplaceno > 0  .AND. Abs( nZatvoriStorno ) > 0 .AND. ( dDatDokStorno <= field->datdok )

                  SKIP
                  nSljRec := RecNo()
                  SKIP -1
                  nOdem := field->iznosdem - nZatvoriStorno * field->iznosdem / field->iznosbhd

                  _rec := dbf_get_rec()

                  // zatvaram storno racun
                  @ box_x_koord() + 1, box_y_koord() + 2 SAY "2. krug zatvori storno " + cZatvoriStorno
                  _rec[ "brdok" ] := cZatvoriStorno
                  _rec[ "_ppk1" ] := "1"
                  _rec[ "iznosbhd" ] := nZatvoriStorno
                  _rec[ "iznosdem" ] := field->iznosdem - nODem

                  dbf_update_rec( _rec )

                  _rec := dbf_get_rec()
                  _rec[ "iznosbhd" ] := nUplaceno - nZatvoriStorno
                  _rec[ "iznosdem" ] := nOdem

                  IF Round( _rec[ "iznosbhd" ], 4 ) <> 0 .AND. Round( nOdem, 4 ) <> 0

                     // prebacujem ostatak uplate na novu stavku
                     APPEND BLANK

                     _rec[ "brdok" ] := avans_br_dok()
                     _rec[ "_ppk1" ] := ""

                     // resetuj broj zapisa iz suban tabele !
                     _rec[ "_recno" ] := 0

                     // sredi redni broj stavke
                     // na osnovu zadnjeg broja unutar naloga
                     _rec[ "rbr" ] := fin_nalog_sljedeci_redni_broj( _rec[ "idfirma" ], _rec[ "idvn" ], _rec[ "brnal" ] )

                     dbf_update_rec( _rec )

                  ENDIF

                  nZatvoriStorno := 0
                  GO nSljRec
                  LOOP


               ELSEIF nUplaceno > 0 .AND. nZatvori > 0


                  IF nZatvori >= nUplaceno // pozitivni iznosi

                     _rec := dbf_get_rec()
                     @ box_x_koord() + 1, box_y_koord() + 2 SAY "2. krug zatvori " + cZatvori
                     _rec[ "brdok" ] := cZatvori
                     _rec[ "_ppk1" ] := "1"
                     dbf_update_rec( _rec )
                     nZatvori -= nUplaceno

                  ELSEIF nZatvori < nUplaceno

                     SKIP // imamo i ostatak sredstava razbiti uplatu !!
                     nSljRec := RecNo()
                     SKIP -1

                     nOdem := field->iznosdem - nZatvori * field->iznosdem / field->iznosbhd

                     _rec := dbf_get_rec()

                     _rec[ "brdok" ] := cZatvori
                     _rec[ "_ppk1" ] := "1"
                     _rec[ "iznosbhd" ] := nZatvori
                     _rec[ "iznosdem" ] := field->iznosdem - nODem

                     dbf_update_rec( _rec )

                     _rec := dbf_get_rec()

                     _rec[ "iznosbhd" ] := nUplaceno - nZatvori
                     _rec[ "iznosdem" ] := nOdem

                     IF Round( _rec[ "iznosbhd" ], 4 ) <> 0 .AND. Round( nOdem, 4 ) <> 0

                        APPEND BLANK

                        _rec[ "brdok" ] := avans_br_dok()
                        _rec[ "_ppk1" ] := ""

                        // resetuj broj zapisa iz suban tabele !
                        _rec[ "_recno" ] := 0

                        // sredi redni broj stavke
                        // na osnovu zadnjeg broja unutar naloga
                        _rec[ "rbr" ] := fin_nalog_sljedeci_redni_broj( _rec[ "idfirma" ], _rec[ "idvn" ], _rec[ "brnal" ] )

                        dbf_update_rec( _rec )

                     ENDIF

                     nZatvori := 0

                     GO nSljRec
                     LOOP

                  ENDIF

                  IF nZatvori <= 0
                     EXIT
                  ENDIF

               ENDIF

            ENDIF

         ENDIF

         SKIP

      ENDDO




   ENDDO // do while .T.

   BoxC()

   // !!! markiraj stavke koje su postale zatvorene
   SET ORDER TO TAG "3" // osuban
   GO TOP

   DO WHILE !Eof()

      cBrDok := brdok
      nSaldo := 0
      nSljRec := RecNo()

      DO WHILE !Eof() .AND. cidfirma + cidkonto + cidpartner + cbrdok == idfirma + idkonto + idpartner + brdok

         IF d_p == "1"
            nSaldo += iznosbhd
         ELSE
            nSaldo -= iznosbhd
         ENDIF
         SKIP
      ENDDO

      IF Round( nSaldo, 4 ) == 0
         GO nSljRec
         DO WHILE !Eof() .AND. cidfirma + cidkonto + cidpartner + cbrdok == idfirma + idkonto + idpartner + brdok
            _rec := dbf_get_rec()
            _rec[ "otvst" ] := "9"
            dbf_update_rec( _rec )
            SKIP
         ENDDO
      ENDIF
   ENDDO

   SELECT ( F_SUBAN )
   USE
   SELECT ( F_OSUBAN )
   USE


   SELECT ( F_SUBAN )  //  osuban alias suban radi stampe kartice
   my_use_temp( "SUBAN", my_home() + my_dbf_prefix() + "osuban", .F., .F. )

   SELECT suban
   SET ORDER TO TAG "1"
   // IdFirma+IdKonto+IdPartner+dtos(DatDok)+BrNal+RBr

   IF RecCount() = 0
      USE
      MsgBeep( "Nema otvorenih stavki" )
      RETURN .F.
   ENDIF

   Box(, _max_rows, _max_cols )

   ImeKol := {}
   AAdd( ImeKol, { "Orig.Brdok",    {|| _OBrDok }                  } )
   AAdd( ImeKol, { "Br.Veze",     {|| BrDok }                          } )
   AAdd( ImeKol, { "Dat.Dok.",   {|| DatDok }                         } )
   AAdd( ImeKol, { "Dat.Val.",   {|| DatVal }                         } )
   AAdd( ImeKol, { PadR( "Duguje " + AllTrim( valuta_domaca_skraceni_naziv() ), 18 ), {|| Str( ( iif( D_P == "1", iznosbhd, 0 ) ), 18, 2 ) }     } )
   AAdd( ImeKol, { PadR( "Potraz." + AllTrim( valuta_domaca_skraceni_naziv() ), 18 ), {|| Str( ( iif( D_P == "2", iznosbhd, 0 ) ), 18, 2 ) }     } )
   AAdd( ImeKol, { "M1",         {|| m1 }                          } )
   AAdd( ImeKol, { PadR( "Iznos " + AllTrim( ValPomocna() ), 14 ),  {|| Str( iznosdem, 14, 2 ) }                       } )
   AAdd( ImeKol, { "nalog",    {|| idvn + "-" + brnal + "/" + Str( rbr, 5, 0 ) }                  } )
   AAdd( ImeKol, { "O",          {|| OtvSt }                          } )
   AAdd( ImeKol, { "Partner",     {|| IdPartner }                          } )

   Kol := {}
   FOR i := 1 TO Len( ImeKol )
      AAdd( Kol, i )
   NEXT

   PRIVATE  bGoreRed := NIL
   PRIVATE  bDoleRed := NIL
   PRIVATE  bDodajRed := NIL
   PRIVATE  fTBNoviRed := .F. // trenutno smo u novom redu ?
   PRIVATE  TBCanClose := .T. // da li se moze zavrsiti unos podataka ?
   PRIVATE  bZaglavlje := NIL
   // zaglavlje se edituje kada je kursor u prvoj koloni
   // prvog reda
   //PRIVATE  TBSkipBlock := {| nSkip| fin_otvorene_stavke_browse_skip( nSkip ) }
   PRIVATE  nTBLine := 1      // tekuca linija-kod viselinijskog browsa
   PRIVATE  nTBLastLine := 1  // broj linija kod viselinijskog browsa
   PRIVATE  TBPomjerise := "" // ako je ">2" pomjeri se lijevo dva
   // ovo se mo§e setovati u when/valid fjama
   PRIVATE  TBScatter := "N"  // uzmi samo tekue polje
   adImeKol := {}

   FOR i := 1 TO Len( ImeKol )
      AAdd( adImeKol, ImeKol[ i ] )
   NEXT

   adKol := {}

   FOR i := 1 TO Len( adImeKol )
      AAdd( adKol, i )
   NEXT

   PRIVATE bBKUslov := {|| idFirma + idkonto + idpartner = cidFirma + cidkonto + cidpartner }
   PRIVATE bBkTrazi := {|| cIdFirma + cIdkonto + cIdPartner }
   PRIVATE aPPos := { cIdPartner, 1 }  // pozicija kolone partner, broj veze

   set_cursor_on()

   @ box_x_koord() + ( _max_rows - 5 ), box_y_koord() + 1 SAY "****************  REZULTATI ASISTENTA ************"
   @ box_x_koord() + ( _max_rows - 4 ), box_y_koord() + 1 SAY REPL( "=", f18_max_cols() - 2 )
   @ box_x_koord() + ( _max_rows - 3 ), box_y_koord() + 1 SAY " <F2> Ispravka broja dok.       <c-P> Print      <a-P> Print Br.Dok           "
   @ box_x_koord() + ( _max_rows - 2 ), box_y_koord() + 1 SAY8 " <K> Uključi/isključi račun za kamate "
   @ box_x_koord() + ( _max_rows - 1 ), box_y_koord() + 1 SAY8 ' < F6 > Štampanje izvršenih promjena  '

   PRIVATE cPomBrDok := Space( 10 )

   SEEK Eval( bBkTrazi )

   my_browse( "Ost", _max_rows, _max_cols, {|| rucno_zatvaranje_otv_stavki_key_handler( .T. ) }, "", "", .F., NIL, 1, {|| brdok <> _obrdok }, 6, 0, ;  // zadnji par: nGPrazno
   NIL, NIL )
   //{| nSkip| fin_otvorene_stavke_browse_skip( nSkip ) } )

   BoxC()

   GO TOP

   fPromjene := .F.
   DO WHILE !Eof()
      IF _obrdok <> brdok
         fPromjene := .T.
         EXIT
      ENDIF
      SKIP
   ENDDO

   IF fpromjene
      GO TOP
      IF Pitanje(, "Prikazati rezultate asistenta (D/N) ?", "N" ) = "D"
         fin_ostav_stampa_azuriranih_promjena()
      ENDIF
   ELSE
      SELECT suban
      USE
      RETURN
   ENDIF

   SELECT ( F_OSUBAN )
   USE
   SELECT ( F_SUBAN )
   USE

   MsgBeep( "U slucaju da ažurirate rezultate asistenta#program će izmijeniti sadržaj subanalitičkih podataka !" )

--   IF Pitanje(, "Želite li izvrsiti ažuriranje rezultata asistenta u kumulativ (D/N) ?", "N" ) == "D"

      SELECT ( F_OSUBAN )
      my_use_temp( "OSUBAN", my_home() + my_dbf_prefix() + "osuban", .F., .T. )

      o_suban()

      IF !promjene_otvorenih_stavki_se_mogu_azurirati()
         my_close_all_dbf()
         RETURN .F.
      ENDIF

      IF !brisi_otvorene_stavke_iz_tabele_suban()
         MsgBeep( "Greška sa brisanjem stavki iz tabele SUBAN !" )
         my_close_all_dbf()
         RETURN .F.
      ENDIF

      IF !dodaj_promjene_iz_osuban_u_suban()
         MsgBeep( "Greška kod dodavanja stavki u kumulativnu SUBAN tabelu !" )
         my_close_all_dbf()
         RETURN .F.
      ENDIF

      MsgBeep( "Promjene su izvršene - provjerite podatke na kartici !" )

   ENDIF

   my_close_all_dbf()

   RETURN .T.


STATIC FUNCTION cre_osuban_dbf()

   LOCAL _table := "osuban"
   LOCAL _struct
   LOCAL _ret := .T.

   FErase( my_home() + my_dbf_prefix() + _table + ".cdx" )

   o_suban()
   SET ORDER TO TAG "3"

   // uzmi suban strukturu
   _struct := suban->( dbStruct() )

   // dodaj nova polja u strukturu
   AAdd( _struct, { "_RECNO", "N",  8,  0 } )
   AAdd( _struct, { "_PPK1", "C",  1,  0 } )
   AAdd( _struct, { "_OBRDOK", "C", 10,  0 } )

   SELECT ( F_OSUBAN )

   // kreiraj tabelu
   dbCreate( my_home() + my_dbf_prefix() + "osuban.dbf", _struct )

   // otvori osuban ekskluzivno
   SELECT ( F_OSUBAN )
   my_use_temp( "OSUBAN", my_home() + my_dbf_prefix() + _table + ".dbf", .F., .T. )

   // kreiraj indekse
   INDEX ON IdFirma + IdKonto + IdPartner + DToS( DatDok ) + BrNal + Str( RBr, 5, 0 ) TAG "1"
   INDEX ON idfirma + idkonto + idpartner + brdok TAG "3"
   INDEX ON DToS( datdok ) + DToS( iif( Empty( DatVal ), DatDok, DatVal ) ) TAG "DATUM"

   RETURN _ret



STATIC FUNCTION promjene_otvorenih_stavki_se_mogu_azurirati()

   LOCAL lRet := .F.

   SELECT osuban
   GO TOP

   DO WHILE !Eof()

      IF osuban->_recno == 0
         SKIP
         LOOP
      ENDIF

      SELECT suban
      GO osuban->_recno

      IF Eof() .OR. idfirma <> osuban->idfirma .OR. idvn <> osuban->idvn .OR. brnal <> osuban->brnal .OR. idkonto <> osuban->idkonto .OR. idpartner <> osuban->idpartner .OR. d_p <> osuban->d_p
         lRet := .F.
         MsgBeep( "Izgleda da je drugi korisnik radio na ovom partneru#Prekidam operaciju !" )
         EXIT
      ENDIF

      SELECT osuban
      SKIP

   ENDDO

   RETURN lRet



STATIC FUNCTION dodaj_promjene_iz_osuban_u_suban()

   LOCAL _rec
   LOCAL lRet := .F.
   LOCAL lOk := .T.
   LOCAL hParams

   run_sql_query( "BEGIN" )

   IF !f18_lock_tables( { "fin_suban" }, .T. )
      run_sql_query( "ROLLBACK" )
      MsgBeep( "Ne mogu zaključati tabelu fin_suban !#Operacija poništena." )
      RETURN lRet
   ENDIF

   SELECT osuban
   GO TOP

   DO WHILE !Eof()

      _rec := dbf_get_rec()

      hb_HDel( _rec, "_recno" )
      hb_HDel( _rec, "_ppk1" )
      hb_HDel( _rec, "_obrdok" )

      SELECT suban
      APPEND BLANK

      lOk := update_rec_server_and_dbf( "fin_suban", _rec, 1, "CONT" )

      IF !lOk
         EXIT
      ENDIF

      SELECT osuban
      SKIP

   ENDDO

   IF lOk
      lRet := .T.
      hParams := hb_Hash()
      hParams[ "unlock" ] := { "fin_suban" }
      run_sql_query( "COMMIT", hParams )
   ELSE
      run_sql_query( "ROLLBACK" )
   ENDIF

   RETURN lRet



STATIC FUNCTION brisi_otvorene_stavke_iz_tabele_suban()

   LOCAL _rec
   LOCAL lOk := .T.
   LOCAL lRet := .F.
   LOCAL hParams

   run_sql_query( "BEGIN" )

   IF !f18_lock_tables( { "fin_suban" }, .T. )
      run_sql_query( "ROLLBACK" )
      MsgBeep( "Problem sa zaključavanjem tabele fin_suban !#Prekidam operaciju." )
      RETURN lRet
   ENDIF

   SELECT osuban
   GO TOP

   DO WHILE !Eof()

      IF osuban->_recno == 0
         SKIP
         LOOP
      ENDIF

      SELECT suban
      GO osuban->_recno

      IF !Eof()
         _rec := dbf_get_rec()
         lOk := delete_rec_server_and_dbf( "fin_suban", _rec, 1, "CONT" )
      ENDIF

      IF !lOk
         EXIT
      ENDIF

      SELECT osuban
      SKIP

   ENDDO

   IF lOk
      lRet := .T.
      hParams := hb_Hash()
      hParams[ "unlock" ] := { "fin_suban" }
      run_sql_query( "COMMIT", hParams )
   ELSE
      run_sql_query( "ROLLBACK" )
   ENDIF

   RETURN lRet



*/

FUNCTION fin_otvorene_stavke_opcije_browse_pregleda( cIdKonto )

   LOCAL nX, nY

   nX := box_x_koord() + f18_max_rows() - 15
   nY := box_y_koord() + 1

   @ nX,     nY SAY " <F2>   Ispravka broja dok.       <c-P> Print   <a-P> Print Br.Dok          "
   @ nX + 1, nY SAY8 " <K>    Uključi/isključi račun za kamate         <F5> uzmi broj dok.        "
   @ nX + 2, nY SAY '<ENTER> Postavi/ukini zatvaranje                 <F6> "nalijepi" broj dok.  '

   @ nX + 3, nY SAY REPL( hb_UTF8ToStrBox( BROWSE_PODVUCI), f18_max_cols() - 12 )

   @ nX + 4, nY SAY ""

   ?? "Konto:", cIdKonto

   RETURN .T.


FUNCTION open_otv_stavke_tabele( lOsuban )

   IF lOSuban == NIL
      lOSuban := .F.
   ENDIF

   // o_partner()
   //o_konto()
   //o_rj()

   IF lOSuban

      SELECT ( F_SUBAN )
      USE
      SELECT ( F_OSUBAN )
      USE

      // otvaram osuban kao suban alijas
      // radi stampe kartice itd...
      SELECT ( F_SUBAN )
      my_use_temp( "SUBAN", my_home() + + my_dbf_prefix() + "osuban", .F., .F. )

   ELSE
      o_suban()
   ENDIF

   RETURN .T.
