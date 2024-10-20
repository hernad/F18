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

MEMVAR ImeKol, Kol

FUNCTION p_ugov( cId, dx, dy )

   LOCAL i
   LOCAL cHeader := ""
   LOCAL cFieldId
   LOCAL xRet

   PRIVATE DFTkolicina := 1
   PRIVATE DFTidroba := PadR( "", 10 )
   PRIVATE DFTvrsta := "1"
   PRIVATE DFTidtipdok := "10"
   PRIVATE DFTdindem := "KM "
   PRIVATE DFTidtxt := "10"
   PRIVATE DFTzaokr := 2
   PRIVATE DFTiddodtxt := Space( 2 )

   // PRIVATE gGenUgV2 := "1"
   PRIVATE gFinKPath := Space( 50 )

   PRIVATE ImeKol
   PRIVATE Kol

   PushWA()

   cHeader += "Ugovori: "
   cHeader += "<F3> ispravi id, "
   cHeader += "<F5> stavke ugovora, "
   // cHeader += "<F6> lista za K1='G', "
   cHeader += "<R> set.poslj.fakt, "
   cHeader += "<P> pregl.destin."

   // o_ugov_tabele()

   DFTParUg( .T. )

   o_ugov() // browse svi ugovori

   set_a_kol( @ImeKol, @Kol )


   set_fld_id( @cFieldId, cId )  // setuj polje pri otvaranju za sortiranje

   xRet := p_sifra( F_UGOV, cFieldId, f18_max_rows() - 10, f18_max_cols() - 3, cHeader, @cId, dx, dy, {| Ch | ugov_key_handler( Ch ) } )

   PopWa()

   RETURN xRet


// ----------------------------------------------
// setovanje vrijednosti polja ID pri otvaranju
// ----------------------------------------------
STATIC FUNCTION set_fld_id( cVal, cId )

   cVal := "ID"

   IF ( gVFU == "1" ) .OR. ( cId == NIL )
      cVal := "ID"
   ELSE
      cVal := "NAZ2"
   ENDIF

   RETURN .T.



STATIC FUNCTION set_a_kol( aImeKol, aKol )

   LOCAL i

   aImeKol := {}
   aKol := {}

   AAdd( aImeKol, { "Ugovor", {|| PadR( Trim( id ) + "/" + Trim( IdPartner ) + ":" + get_partner_name_mjesto( IdPartner ), 34 ) }, "Idpartner", {|| valid_sifarnik_id_postoji( wid ), .T. }, {|| p_partner( @wIdPartner ) } } )

   AAdd( aImeKol, { "Opis", {|| PadR( Trim( naz ) + ": " + vrati_opis_ugovora( id ), 30 )  }, "naz" } )
   AAdd( aImeKol, { "DatumOd", {|| DatOd }, "DatOd" } )
   AAdd( aImeKol, { "DatumDo", {|| DatDo }, "DatDo" } )
   AAdd( aImeKol, { "Aktivan", {|| Aktivan }, "Aktivan", {|| .T. }, {|| wAKtivan $ "DN" } } )
   AAdd( aImeKol, { "Lab.print", {|| lab_prn }, "lab_prn" } )
   AAdd( aImeKol, { "TipDok", {|| IdTipdok }, "IdTipDok" } )
   AAdd( aImeKol, { "Vrsta", {|| vrsta }, "Vrsta" } )

   IF ugov->( FieldPos( "F_NIVO" ) ) <> 0
      AAdd( aImeKol, { "Nivo.f", {|| f_nivo }, "f_nivo" } )
      AAdd( aImeKol, { "P.nivo.dana", {|| f_p_d_nivo }, "f_p_d_nivo",,, "99999" } )
      AAdd( aImeKol, { "Fakturisano do", {|| fakt_do() }, "zaokr"  } )
      AAdd( aImeKol, { "Poslj.faktur.", {|| dat_l_fakt }, "dat_l_fakt"  } )
   ENDIF

   AAdd( aImeKol, { "TXT 1", {|| IdTxt }, "IdTxt", {|| .T. }, {|| p_fakt_ftxt( @wIdTxt ) } } )

   IF ugov->( FieldPos( "IDDODTXT" ) ) <> 0
      AAdd( aImeKol, { "TXT 2", {|| IdDodTxt }, "IdDodTxt", {|| .T. }, {|| p_fakt_ftxt( @wIdDodTxt ) } } )
   ENDIF

   IF ugov->( FieldPos( "TXT2" ) ) <> 0
      AAdd( aImeKol, { "TXT 3", {|| txt2 }, "txt2", {|| .T. }, {|| p_fakt_ftxt( @wTxt2 ) } } )
      AAdd( aImeKol, { "TXT 4", {|| txt3 }, "txt3", {|| .T. }, {|| p_fakt_ftxt( @wTxt3 ) } } )
      AAdd( aImeKol, { "TXT 5", {|| txt4 }, "txt4", {|| .T. }, {|| p_fakt_ftxt( @wTxt4 ) } } )
   ENDIF

   AAdd( aImeKol, { "KM/EUR", {|| DINDEM }, "DINDEM" } )

   // IF ( ugov->( FieldPos( "A1" ) ) <> 0 )
   // IF my_get_from_ini( 'Fakt_Ugovori', "A1", 'D' ) == "D"
   AAdd( aImeKol, { "A1", {|| A1 }, "A1" } )
   // ENDIF
   // IF my_get_from_ini( 'Fakt_Ugovori', "A2", 'D' ) == "D"
   AAdd( aImeKol, { "A2", {|| A2 }, "A2" } )
   // ENDIF
   // IF my_get_from_ini( 'Fakt_Ugovori', "B1", 'D' ) == "D"
   AAdd( aImeKol, { "B1", {|| B1 }, "B1" } )
   // ENDIF
   // IF my_get_from_ini( 'Fakt_Ugovori', "B2", 'D' ) == "D"
   AAdd( aImeKol, { "B2", {|| B2 }, "B2" } )
   // ENDIF
   // ENDIF

   FOR i := 1 TO Len( aImeKol )
      AAdd( aKol, i )
   NEXT

   RETURN .T.



STATIC FUNCTION ugov_key_handler( Ch )

   LOCAL GetList := {}
   //LOCAL nRec := 0
   LOCAL nDbfArea := Select()

   DO CASE

   CASE ( Ch == K_CTRL_T )
      // brisi ugovor
      IF br_ugovor() == 1
         RETURN DE_REFRESH
      ENDIF
      RETURN DE_CONT

   CASE Upper( Chr( Ch ) ) == "R" // setuj datum do kojeg si fakturisao

      IF set_datl_fakt() == 1
         RETURN DE_REFRESH
      ELSE
         RETURN DE_CONT
      ENDIF

   CASE Upper( Chr( Ch ) ) == "P"

      p_destinacije( NIL, ugov->idpartner )

      RETURN DE_CONT

   CASE ( Ch == K_CTRL_G )

      // automatsko generisanje novih ugovora
      // za sve partnere sa podacima
      // prethodnog ugovora
      gen_ug_part()

   CASE ( Ch == K_F2 )
      // ispravka ugovora
      edit_ugovor( .F. )
      RETURN 7

   CASE ( Ch == K_F3 )
      IF Pitanje(, "Promjena broja ugovora ?", "N" ) == "D"
         ugovor_promjeni_id( id )
      ENDIF
      RETURN DE_REFRESH


   CASE ( Ch == K_CTRL_N )

      edit_ugovor( .T. ) // novi ugovor
      RETURN 7

   CASE ( Ch == K_F5 )

      browse_rugov( ugov->id )
      RETURN 6 // DE_CONT2

      // CASE ( Ch == K_F6 )
      // I_ListaUg()

   CASE ( Ch == K_ALT_L )

      //nRec := RecNo()

      ugov_stampa_naljenica()
      // o_rugov()
      // o_dest()
      // o_ugov()

      //GO ( nRec )

   ENDCASE

   RETURN DE_CONT


// -------------------------------------------------
// postavi datum posljedjeg fakturisanja
// -------------------------------------------------
FUNCTION set_datl_fakt()

   LOCAL dDatL := Date()
   LOCAL cProm := "N"
   PRIVATE GetList := {}

   Box(, 5, 60 )

   @ box_x_koord() + 1, box_y_koord() + 2 SAY "SETOVANJE DATUMA POSLJEDNJEG FAKTURISANJA:"
   @ box_x_koord() + 3, box_y_koord() + 2 SAY "Postavi datum na:" GET dDatL
   @ box_x_koord() + 5, box_y_koord() + 2 SAY8 "Izvršiti promjenu (D/N)?" GET cProm VALID cProm $ "DN" PICT "@!"

   READ
   BoxC()

   IF LastKey() <> K_ESC .AND. cProm == "D"

      SELECT ugov
      GO TOP

      DO WHILE !Eof()
         IF ugov->f_nivo == "G"
            REPLACE dat_l_fakt WITH dDatL
         ENDIF
         SKIP
      ENDDO

      RETURN 1
   ENDIF

   RETURN 0


// -----------------------------------------------------------
// generacija novog ugovora za partnera na osnovu prethodnog
// -----------------------------------------------------------
FUNCTION gen_ug_part()

   LOCAL cArtikal
   LOCAL cArtikalOld
   LOCAL cDN
   LOCAL nTRec

   IF Pitanje(, 'Generisanje ugovora za partnere (D/N)?', 'N' ) == 'D'
      SELECT rugov
      cArtikal := idroba
      cArtikalOld := idroba
      cDN := "N"
      Box(, 3, 50 )
      @ box_x_koord() + 1, box_y_koord() + 5 SAY8 "Generiši ugovore za artikal: " GET cArtikal
      @ box_x_koord() + 2, box_y_koord() + 5 SAY8 "Preuzmi podatke artikla: " GET cArtikalOld
      @ box_x_koord() + 3, box_y_koord() + 5 SAY8 "Zamjenu vršiti samo za aktivne (D/N): " GET cDN VALID cDN $ "DN"
      READ
      BoxC()

      IF LastKey() == K_ESC
         RETURN DE_CONT
      ENDIF

      IF cDN == "D"
         SET RELATION TO id into ugov
      ENDIF

      DO WHILE !Eof()
         SKIP
         nTrec := RecNo()
         SKIP -1
         IF cDN == "D" .AND. ugov->aktivan == "D" .AND. cArtikalOld == idroba .OR. cDN == "N" .AND. cArtikalOld == idroba
            Scatter()
            APPEND BLANK
            _idroba := cArtikal
            Gather()
            @ box_x_koord() + 1, box_y_koord() + 2 SAY8 "Obuhvaćeno: " + Str( nTrec )
            GO nTrec
         ELSE
            GO nTrec
         ENDIF
      ENDDO
      SET RELATION TO
      SELECT ugov
   ENDIF

   RETURN DE_CONT



// ------------------------------------
// brisanje ugovora
// ------------------------------------
FUNCTION br_ugovor()

   LOCAL lOk := .T.
   LOCAL _id_ugov
   LOCAL nTrec
   LOCAL _rec
   LOCAL _ret := 0
   LOCAL hParams

   IF Pitanje(, "Izbrisati ugovor sa pripadajućim stavkama (D/N) ?", "N" ) == "N"
      RETURN _ret
   ENDIF

   run_sql_query( "BEGIN" )
   IF !f18_lock_tables( { "fakt_ugov", "fakt_rugov" }, .T. )
      run_sql_query( "ROLLBACK" )
      MsgBeep( "Problem sa lokovanjem tabela !" )
      RETURN _ret
   ENDIF

   _id_ugov := field->id

   _rec := dbf_get_rec()
   delete_rec_server_and_dbf( "fakt_ugov", _rec, 1, "CONT" )

   SELECT rugov
   SEEK _id_ugov

   DO WHILE !Eof() .AND. _id_ugov == field->id

      SKIP
      nTrec := RecNo()
      SKIP -1

      _rec := dbf_get_rec()
      lOk := delete_rec_server_and_dbf( "fakt_rugov", _rec, 1, "CONT" )

      IF !lOk
         EXIT
      ENDIF

      GO ( nTrec )

   ENDDO

   IF lOk
      _ret := 1
      hParams := hb_Hash()
      hParams[ "unlock" ] :=  { "fakt_ugov", "fakt_rugov" }
      run_sql_query( "COMMIT", hParams )
   ELSE
      run_sql_query( "ROLLBACK" )
   ENDIF

   SELECT ugov

   RETURN _ret




FUNCTION edit_ugovor( lNovi )

   LOCAL cIdOld
   LOCAL cId
   LOCAL nTRec
   LOCAL nBoxLen := 20
   LOCAL nX := 1
   LOCAL nFaktDoMjeseca := 0
   LOCAL nFaktDoGodine := 0
   LOCAL GetList := {}
   LOCAL hRec

   IF lNovi
      nTRec := RecNo()
      GO BOTTOM
      SKIP 1
   ENDIF

   // Scatter()

   hRec := dbf_get_rec()

   IF lNovi
      hRec[ "datod" ] := Date()
      hRec[ "datdo" ] := CToD( "31.12.2059" )
      hRec[ "aktivan" ] := "D"
      hRec[ "lab_prn" ] := "D"
      hRec[ "dindem" ] := DFTdindem
      hRec[ "idtipdok" ] := DFTidtipdok
      hRec[ "zaokr" ] := DFTzaokr
      hRec[ "vrsta" ] := DFTvrsta
      hRec[ "idtxt" ] := DFTidtxt
      hRec[ "iddodtxt" ] := DFTiddodtxt

      hRec[ "f_nivo" ] := "M"
      hRec[ "f_p_d_nivo" ] := 0
      hRec[ "dat_l_fakt" ] := CToD( "" )

   ENDIF

   Box(, 20, 75, .F. )

   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "Ugovor", nBoxLen ) GET hRec[ "id" ] WHEN lNovi PICT "@!"

   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "Partner", nBoxLen ) GET hRec[ "idpartner" ] VALID {|| x := p_partner( @hRec[ "idpartner" ] ), MSAY2( box_x_koord() + 2, box_y_koord() + 35, get_partner_naziv( hRec[ "idpartner" ] ), 40 ), x } PICT "@!"
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "Def.dest", nBoxLen ) GET hRec[ "def_dest" ]  PICT "@!" VALID {|| Empty( hRec[ "def_dest" ] ) .OR. p_destinacije( @hRec[ "def_dest" ], hRec[ "idpartner" ] ) }

   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "Opis ugovora", nBoxLen ) GET hRec[ "naz" ] PICT "@!"

   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "Datum ugovora", nBoxLen ) GET hRec[ "datod" ]

   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "Datum kraja ugov.", nBoxLen ) GET hRec[ "datdo" ]

   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "Aktivan (D/N)", nBoxLen ) GET hRec[ "aktivan" ] VALID hRec[ "aktivan" ] $ "DN" PICT "@!"
   @ box_x_koord() + nX, Col() + 2 SAY PadL( "labela print (D/N)", nBoxLen ) GET hRec[ "lab_prn" ] VALID hRec[ "lab_prn" ] $ "DN" PICT "@!"

   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "Tip dokumenta", nBoxLen ) GET hRec[ "idtipdok" ] PICT "@!"

   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "Vrsta", nBoxLen ) GET hRec[ "vrsta" ] PICT "@!"


   // IF ugov->( FieldPos( "F_NIVO" ) ) <> 0

   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "Nivo fakt.", nBoxLen ) GET hRec[ "f_nivo" ] PICT "@!" VALID hRec[ "f_nivo" ] $ "MPG"

   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "Pr.nivo dana", nBoxLen ) GET hRec[ "f_p_d_nivo" ] PICT "99999" WHEN hRec[ "f_nivo" ] == "P"

   ++nX
   // mjesec
   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "Fakturisano do", nBoxLen ) GET nFaktDoMjeseca WHEN  {||  nFaktDoMjeseca := Month( ugov->dat_l_fakt ), .T. }  PICT "99"

   // godina
   @ box_x_koord() + nX, box_y_koord() + 2 + 28  SAY "/" GET nFaktDoGodine  WHEN {||  nFaktDoGodine := Year( ugov->dat_l_fakt ), .T. } ;
      VALID {||   _dat_l_fakt := mo_ye( nFaktDoMjeseca, nFaktDoGodine ), .T. } PICT "9999"

   // ENDIF

   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "Valuta (KM/EUR)", nBoxLen ) GET hRec[ "dindem" ] PICT "@!"

   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "Dod.txt 1", nBoxLen ) GET hRec[ "idtxt" ] VALID p_fakt_ftxt( @hRec[ "idtxt" ] ) PICT "@!"


   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "Dod.txt 2", nBoxLen ) GET hRec[ "iddodtxt" ] VALID p_fakt_ftxt( @hRec[ "iddodtxt" ] ) PICT "@!"

   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "Dod.txt 3", nBoxLen ) GET hRec[ "txt2" ] VALID p_fakt_ftxt( @hRec[ "txt2" ] ) PICT "@!"
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "Dod.txt 4", nBoxLen ) GET hRec[ "txt3" ] VALID p_fakt_ftxt( @hRec[ "txt3" ] ) PICT "@!"
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "Dod.txt 5", nBoxLen ) GET hRec[ "txt4" ] VALID p_fakt_ftxt( @hRec[ "txt4" ] ) PICT "@!"


   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "A1", nBoxLen ) GET hRec[ "a1" ]
   @ box_x_koord() + nX, Col() + 2 SAY PadL( "A2", nBoxLen ) GET hRec[ "a2" ]
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "B1", nBoxLen ) GET hRec[ "b1" ]
   @ box_x_koord() + nX, Col() + 2 SAY PadL( "B2", nBoxLen ) GET hRec[ "b2" ]

   READ

   BoxC()

   IF LastKey() == K_ESC
      RETURN DE_CONT
   ENDIF

   IF lNovi
      APPEND BLANK
   ENDIF

   // := get_hash_record_from_global_vars()

   IF !update_rec_server_and_dbf( Alias(), hRec, 1, "FULL" )
      delete_with_rlock()
   ELSE
      IF lNovi
         GO ( nTRec )
      ENDIF
   ENDIF

   RETURN 7


// ---------------------------------------------
// promjeni broj ugovora
// ---------------------------------------------
STATIC FUNCTION ugovor_promjeni_id( cId )

   LOCAL nRecno

   cIdOld := cId
   Box(, 2, 50 )
   @ box_x_koord() + 1, box_y_koord() + 2 SAY "Broj ugovora" GET cID VALID !Empty( cId ) .AND. cId <> cIdOld
   READ
   BoxC()

   IF LastKey() == K_ESC
      RETURN DE_CONT
   ENDIF

   nRecno := RecNo()
   SEEK cId
   IF Found() .AND. ( cId <> cIdOld )
      MsgBeep( "Ugovor " + cId + " već postoji##Promjena nije moguća !" )
      GO nRecno
      RETURN DE_CONT
   ELSE
      GO nRecno
   ENDIF


   SELECT rugov
   my_flock()
   SEEK cIdOld

   DO WHILE !Eof() .AND. ( cIdOld == id )
      SKIP
      nTrec := RecNo()
      SKIP -1
      REPLACE id WITH cid
      GO nTrec
   ENDDO
   my_unlock()
   SELECT ugov
   RREPLACE id WITH cid

   RETURN .T.


/*

FUNCTION P_Ugov2( cIdPartner )

   // cidpartner - proslijediti partnera
   // iz sifrarnika partnera

   PRIVATE Imekol
   PRIVATE Kol
   PRIVATE lIzSifPArtn

   PRIVATE cFilter := ""

   IF Alias() = "PARTN"
      lIzSifPartn := .T.
   ELSE
      lIzSifPartn := .F.
   ENDIF

   SELECT ( F_UGOV )

   PRIVATE cIdUg := ID

   SELECT ( F_RUGOV )
   SET ORDER TO TAG "ID"

   cFilt := "ID = " + dbf_quote( cIdUg )
   SET FILTER TO
   SET FILTER TO &cFilt
   GO TOP

   ImeKol := {}; Kol := {}

   AAdd( ImeKol, { "IDRoba",   {|| IdRoba }, "IDROBA", {|| .T. }, {|| glDistrib .AND. Right( Trim( widroba ), 1 ) == ";" .OR. P_Roba( @widroba ) }, ">" } )

   AAdd( ImeKol, { PadC( "Kol.", Len( fakt_pic_kolicina() ) ), {|| Transform( kolicina, fakt_pic_kolicina() ) }, "KOLICINA", {|| .T. }, {|| .T. }, ">" } )

   IF rugov->( FieldPos( "K1" ) ) <> 0
      IF my_get_from_ini( 'Fakt_Ugovori', "K2", 'D' ) == "D"
         AAdd ( ImeKol, { "K1",  {|| K1 },    "K1", {|| .T. }, {|| .T. }, ">"  } )
      ENDIF
      IF my_get_from_ini( 'Fakt_Ugovori', "K2", 'D' ) == "D"
         AAdd ( ImeKol, { "K2",  {|| K2 },    "K2", {|| .T. }, {|| .T. }, ">"  } )
      ENDIF
   ENDIF

   FOR i := 1 TO Len( ImeKol ); AAdd( Kol, i ); NEXT

   Box(, 20, 72 )
   @ box_x_koord() + 19, box_y_koord() + 1 SAY "<PgDn> sljedeci, <PgUp> prethodni ³<c-N> nova stavka          "
   @ box_x_koord() + 20, box_y_koord() + 1 SAY "<TAB>  podaci o ugovoru           ³<c-L> novi ugovor          "

   PRIVATE  bGoreRed := NIL
   PRIVATE  bDoleRed := NIL
   PRIVATE  bDodajRed := NIL

   // trenutno smo u novom redu ?
   PRIVATE  fTBNoviRed := .F.
   // da li se moze zavrsiti unos podataka ?

   PRIVATE  TBCanClose := .T.



   PRIVATE  bZaglavlje := NIL

   // zaglavlje se edituje kada je kursor u prvoj koloni
   // prvog reda
   // PRIVATE  TBSkipBlock := {| nSkip| SkipDB( nSkip, @nTBLine ) }
   // tekuca linija-kod viselinijskog browsa
   PRIVATE  nTBLine := 1
   // broj linija kod viselinijskog browsa
   PRIVATE  nTBLastLine := 1
   // ako je ">2" pomjeri se lijevo dva
   // ovo se moze setovati u when/valid fjama
   PRIVATE  TBPomjerise := ""


   // uzmi samo tekuce polje
   PRIVATE  TBScatter := "N"
   PRIVATE lTrebaOsvUg := .T.

   adImeKol := {}; FOR i := 1 TO Len( ImeKol ); AAdd( adImeKol, ImeKol[ i ] ); NEXT
   adKol := {}; FOR i := 1 TO Len( adImeKol ); AAdd( adKol, i ); NEXT

   IF cIdPartner <> NIL
      Ch := K_CTRL_L
      TempIni( 'Fakt_Ugovori_Novi', 'Partner', cIdpartner, "WRITE" )
      EdUgov2()
   ELSE
      TempIni( 'Fakt_Ugovori_Novi', 'Partner', '_NIL_', "WRITE" )
      my_browse( "", 20, 72, {|| EdUgov2() }, "", "Stavke ugovora...", , , , , 2, 6 )
   ENDIF

   BoxC()
   SELECT ( F_RUGOV )
   SET FILTER TO

   SELECT ( F_UGOV )

   RETURN



FUNCTION EdUgov2()

   LOCAL _ret := -77
   LOCAL GetList := {}
   LOCAL nTrec := RecNo()
   LOCAL _t_arr := Select()
   LOCAL _rec

   DO CASE

   CASE Ch == K_TAB

      OsvjeziPrikUg( .T. )

   CASE Ch == K_CTRL_L

      _ret := OsvjeziPrikUg( .T., .T. )

      IF _ret == DE_REFRESH
         cIdUg := ugov->id
         SELECT ( _t_arr )
         SET FILTER TO
         IF !Empty( DFTidroba )
            APPEND BLANK
            _rec := dbf_get_rec()
            _rec[ "id" ] := cIdUg
            _rec[ "idroba" ] := DFTidroba
            _rec[ "kolicina" ] := DFTkolicina
            update_rec_server_and_dbf( "fakt_ugov", _rec, 1, "FULL" )
         ENDIF
         SET FILTER TO ID == cIdUg; GO TOP
      ENDIF

   CASE Ch == K_PGDN
      IF lIzSifPArtn
         DO WHILE .T.  .AND. !Eof()
            SELECT partn
            SKIP
            SELECT ugov
            SET ORDER TO TAG "PARTNER"
            SET FILTER TO
            SEEK partn->id
            IF !Found()
               SELECT partn
               LOOP
               // skaci do prvog sljedeceg ugovora
            ELSE
               EXIT
            ENDIF
            SELECT partn
         ENDDO
         IF Eof()
            SKIP -1
         ENDIF

      ELSE
         // vrti se iz liste ugovora
         SELECT UGOV
         SKIP 1
         IF Eof()
            SKIP -1
            SELECT ( _t_arr )
            RETURN ( _ret )
         ENDIF
      ENDIF

      cIdUg := ID
      SELECT ( _t_arr )
      SET FILTER TO
      SET FILTER TO ID == cIdUg
      GO TOP

      OsvjeziPrikUg( .F. )
      _ret := DE_REFRESH

   CASE Ch == K_PGUP
      IF lIzSifPArtn
         DO WHILE .T.  .AND. !Bof()
            SELECT partn
            SKIP -1
            SELECT ugov
            SET ORDER TO TAG "PARTNER"
            SET FILTER TO
            SEEK partn->id
            IF !Found()
               SELECT partn
               LOOP
               // skaci do prvog sljedeceg ugovora
            ELSE
               EXIT
            ENDIF
            SELECT partn
         ENDDO
         IF Bof()
            SKIP
         ENDIF

      ELSE
         // vrti se iz liste ugovora
         SELECT UGOV
         SKIP -1
         IF Bof()
            SELECT ( _t_arr )
            RETURN ( _ret )
         ENDIF

      ENDIF
      cIdUg := ID
      SELECT ( _t_arr )

      PRIVATE cFilt := "ID==" + dbf_quote( cIdUg )
      SET FILTER TO
      SET FILTER TO &cFilt
      GO TOP

      OsvjeziPrikUg( .F. )
      _ret := DE_REFRESH

   CASE Ch == K_CTRL_N
      IF Empty( cIdUg )
         Msg( "Prvo morate izabrati opciju <c-L> za novi ugovor!" )
         RETURN DE_CONT
      ENDIF
      GO BOTTOM
      SKIP 1
      Scatter()
      _id := cIdUg

      Box(, 8, 77 )
      @ box_x_koord() + 2, box_y_koord() + 2 SAY8 "ŠIFRA ARTIKLA:" GET _idroba ;
         VALID ( glDistrib .AND. Right( Trim( _idroba ), 1 ) == ";" ) .OR. P_Roba( @_idroba ) ;
         PICT "@!"
      @ box_x_koord() + 3, box_y_koord() + 2 SAY8 "Količina      " GET _Kolicina  ;
         PICT "99999999.999"


      IF FieldPos( "K1" ) <> 0
         IF my_get_from_ini( 'Fakt_Ugovori', "K1", 'D' ) == "D"
            @ box_x_koord() + 6, box_y_koord() + 2 SAY "K1            " GET _K1 PICT "@!"
         ENDIF
         IF my_get_from_ini( 'Fakt_Ugovori', "K2", 'D' ) == "D"
            @ box_x_koord() + 7, box_y_koord() + 2 SAY "K2            " GET _K2 PICT "@!"
         ENDIF
      ENDIF
      @ box_x_koord() + 8, box_y_koord() + 2 SAY "Destinacija   " GET _destin ;
         PICT "@!" VALID Empty( _destin ) .OR. P_Destin( @_destin )
      READ
      BoxC()

      IF LastKey() != K_ESC

         APPEND BLANK
         _vars := get_hash_record_from_global_vars()
         IF !update_rec_server_and_dbf( Alias(), _vars, 1, "FULL" )
            delete_with_rlock()
         ENDIF

         lTrebaOsvUg := .T.
      ELSE
         GO ( nTrec )
         RETURN DE_CONT
      ENDIF

      _ret := DE_REFRESH

   CASE Ch == K_CTRL_T

      IF Pitanje( , "Izbrisati stavku (D/N) ?", "N" ) == "D"
         _rec := dbf_get_rec()
         delete_rec_server_and_dbf( "fakt_ugov", _rec, 1, "FULL" )
         lTrebaOsvUg := .T.
         _ret := DE_REFRESH
      ELSE
         RETURN DE_CONT
      ENDIF

   ENDCASE

   IF lTrebaOsvUg
      OsvjeziPrikUg( .F. )
      lTrebaOsvUg := .F.
   ENDIF

   IF _ret != -77
      Ch := 0
   ELSE
      _ret := DE_CONT
   ENDIF

   RETURN _ret


// ----------------------------------------
// osvjezavanje prikaza ugovora
// ----------------------------------------
FUNCTION OsvjeziPrikUg( lWhen, lNew )

   LOCAL cPom
   LOCAL GetList := {}
   LOCAL nArr := Select()
   LOCAL nRecUg := 0
   LOCAL nRecRug := 0
   LOCAL lRefresh := .F.
   LOCAL cEkran := ""

   IF lNew == nil
      lNew := .F.
   ENDIF

   SELECT UGOV

   IF lNew
      cEkran := SaveScreen( box_x_koord() + 10, box_y_koord() + 1, box_x_koord() + 17, box_y_koord() + 72 )
      @ box_x_koord() + 10, box_y_koord() + 1 CLEAR TO box_x_koord() + 17, box_y_koord() + 72
      @ box_x_koord() + 13, box_y_koord() + 1 SAY PadC( "N O V I    U G O V O R", 72 )
      nRecUg := RecNo()
      GO BOTTOM
      SKIP 1
      Scatter( "w" )
      waktivan := "D"
      wdatod := Date()
      wdatdo := CToD( "31.12.2059" )
      wdindem   := DFTdindem
      widtipdok := DFTidtipdok
      wzaokr    := DFTzaokr
      wvrsta    := DFTvrsta
      widtxt    := DFTidtxt
      widdodtxt := DFTiddodtxt

      SKIP -1

      IF Empty( id )
         wid := PadL( "1", Len( id ), "0" )
      ELSE
         wid := PadR( NovaSifra( Trim( id ) ), Len( ID ) )
      ENDIF

   ELSE

      Scatter( "w" )

   ENDIF

   cPom := TempIni( 'Fakt_Ugovori_Novi', 'Partner', '_NIL', "READ" )
   IF cPom <> "_NIL_"
      wIdPartner := PadR( cPom, 6 )
      cPom := TempIni( 'Fakt_Ugovori_Novi', 'Partner', '_NIL_', "WRITE" )
   ENDIF

   @ box_x_koord() + 1, box_y_koord() + 1 SAY "Ugovor broj    :" GET wid WHEN lWhen VALID !lWhen .OR. !Empty( wid ) .AND. valid_sifarnik_id_postoji( wid )
   @ box_x_koord() + 1, box_y_koord() + 30 SAY "Opis ugovora   :" GET wnaz WHEN lWhen
   @ box_x_koord() + 2, box_y_koord() + 1 SAY "PARTNER        :" GET widpartner ;
      WHEN lWhen ;
      VALID !lWhen .OR. p_partner( @widpartner ) .AND. MSAY2( box_x_koord() + 2, 30, get_partner_naziv( wIdPartner ), 40 ) PICT "@!"

   @ box_x_koord() + 3, box_y_koord() + 1 SAY "DATUM UGOVORA  :" GET wdatod ;
      WHEN lWhen
   @ box_x_koord() + 3, box_y_koord() + 30 SAY "DATUM PRESTANKA:" GET wdatdo ;
      WHEN lWhen
   @ box_x_koord() + 4, box_y_koord() + 1 SAY "VRSTA UGOV.(1/2/G):" GET wvrsta ;
      WHEN lWhen ;
      VALID !lWhen .OR. wvrsta $ "12G"
   @ box_x_koord() + 4, box_y_koord() + 30 SAY "TIP DOKUMENTA  :" GET widtipdok WHEN lWhen
   @ box_x_koord() + 5, box_y_koord() + 1 SAY "AKTIVAN (D/N)  :" GET waktivan ;
      WHEN lWhen ;
      VALID !lWhen .OR. waktivan $ "DN" ;
      PICT "@!"
   @ box_x_koord() + 5, box_y_koord() + 30 SAY "VALUTA (KM/DEM):" GET wdindem ;
      WHEN lWhen ;
      PICT "@!"
   @ box_x_koord() + 6, box_y_koord() + 1 SAY "TXT-NAPOMENA   :" GET widtxt ;
      WHEN lWhen
   @ box_x_koord() + 6, box_y_koord() + 30 SAY "TXT-NAPOMENA2  :" GET widdodtxt ;
      WHEN lWhen

   READ

   IF !lWhen
      @ box_x_koord() + 2, box_y_koord() + 24 SAY "---->(" + get_partner_naziv( wIdPartner ) + ")"
   ENDIF

   IF lNew .AND. !LastKey() == K_ESC
      lRefresh := .T.
      APPEND BLANK
   ELSEIF lNew
      GO ( nRecUg )
   ENDIF

   IF lWhen .AND. !LastKey() == K_ESC
      IF wid != id
         lRefresh := .T.
         SELECT RUGOV
         SET FILTER TO
         HSEEK UGOV->id
         DO WHILE !Eof() .AND. id == UGOV->id
            SKIP 1
            nRecRug := RecNo()
            SKIP -1
            Scatter()
            _id := wid
            Gather()
            GO ( nRecRug )
         ENDDO
         cIdUg := wid
         SET FILTER TO ID == cIdUg
         GO TOP
         SELECT UGOV
      ENDIF
      Gather( "w" )
   ENDIF

   IF lWhen
      lTrebaOsvUg := .T.
   ENDIF

   IF lNew
      RestScreen( box_x_koord() + 10, box_y_koord() + 1, box_x_koord() + 17, box_y_koord() + 72, cEkran )
   ENDIF

   SELECT ( nArr )

   RETURN ( IF( lRefresh, DE_REFRESH, DE_CONT ) )




FUNCTION I_ListaUg()

   LOCAL nArr := Select()
   LOCAL i := 0

   SELECT UGOV
   PushWA()
   SET ORDER TO TAG "ID"
   SELECT RUGOV
   PushWA()
   SET ORDER TO TAG "IDROBA"

   PRIVATE nRbr := 0
   PRIVATE cSort := "1"
   PRIVATE gOstr := "D"
   PRIVATE lLin := .T.
   PRIVATE cUgovId  := ""
   PRIVATE cUgovNaz := ""
   PRIVATE cPartnNaz := ""
   PRIVATE nRugovKol := 0

   cFiltTrz := Parsiraj( 'K--T;', "ID" )

   aKol := { { "R.br.", {|| Str( nRbr, 4 ) + "."   }, .F., "C", 5, 0, 1, ++i }, ;
      { "Broj ugovora", {|| cUgovId           }, .F., 'C', 12, 0, 1, ++i }, ;
      { "Naziv objekta", {|| ROBA->naz         }, .F., 'C', 30, 0, 1, ++i }, ;
      { "Naziv zakupca", {|| cPARTNnaz         }, .F., 'C', 30, 0, 1, ++i }, ;
      { "m2 objekta", {|| nRUGOVkol         }, .F., 'N', 15, 3, 1, ++i }, ;
      { "Jedin.cijena", {|| ROBA->vpc         }, .F., 'N', 15, 2, 1, ++i }, ;
      { "Iznos", {|| nRUGOVkol * ROBA->vpc   }, ;
      .T., 'N', 15, 2, 1, ++i } }

   START PRINT CRET

   SELECT ROBA
   GO TOP

   print_lista_2( aKol, {|| ZaOdgovarajuci() },, gTabela,,, ;
      "PREGLED UGOVORA ZA " + cFiltTrz, ;
      {|| OdgovaraLi() }, iif( gOstr == "D",, - 1 ),, lLin,,, )

   ENDPRINT

   SELECT RUGOV
   PopWA()
   SELECT UGOV
   PopWA()

   SELECT ( nArr )

   RETURN


STATIC FUNCTION OdgovaraLi()
   RETURN &( cFiltTrz )


STATIC FUNCTION ZaOdgovarajuci()

   ++nRbr
   SELECT RUGOV
   HSEEK ROBA->id
   IF Found()
      nRUGOVkol := RUGOV->kolicina
      SELECT UGOV
      SEEK RUGOV->id
      IF Found()
         cUgovId   := UGOV->id
         cUgovNaz  := UGOV->naz
         select_o_partner( UGOV->idpartner )
         IF Found()
            cPartnNaz := PARTN->naz
         ELSE
            cPartnNaz := ""
         ENDIF
      ELSE
         MsgBeep( "Greška! Stavka ugovora '" + RUGOV->ID + "' postoji, ugovor ne postoji ?!" )
         IF Pitanje(, "Brisati problematičnu stavku (u RUGOV.DBF) ? (D/N)", "N" ) == "D"
            SELECT RUGOV
            DELETE
         ENDIF
         cUgovId   := ""
         cUgovNaz  := ""
         cPartnNaz := ""
      ENDIF

   ELSE
      cUgovId   := ""
      cUgovNaz  := ""
      cPartnNaz := ""
      nRugovKol := 0
   ENDIF
   SELECT ROBA

   RETURN .T.

*/

/*

FUNCTION IzfUgovor()

   IF my_get_from_ini( 'FIN', 'VidiUgovor', 'N' ) == "D"
      PushWA()

      SELECT ( F_UGOV )
      IF !Used()
  --       o_ugov()
      ENDIF

      SELECT ( F_RUGOV )
      IF !Used()
  --       o_rugov()
      ENDIF

      SELECT ( F_DEST )
      IF !Used()
         o_dest()
      ENDIF

      SELECT ( F_ROBA )
      IF !Used()
         o_roba()
      ENDIF

      SELECT ( F_TARIFA )
      IF !Used()
         o_tarifa()
      ENDIF

      PRIVATE DFTkolicina := 1
      PRIVATE DFTidroba := PadR( "ZIPS", 10 )
      PRIVATE DFTvrsta  := "1"
      PRIVATE DFTidtipdok := "20"
      PRIVATE DFTdindem := "KM "
      PRIVATE DFTidtxt := "10"
      PRIVATE DFTzaokr := 2
      PRIVATE DFTiddodtxt := "  "

      DFTParUg( .T. )

      SELECT ugov
      PRIVATE cFiltP := "Idpartner==" + dbf_quote( partn->id )
      SET FILTER TO &cFilP
      GO TOP
      IF Eof()
         MsgBeep( "Ne postoje definisani ugovori za korisnika" )
         IF pitanje(, "Želite li definisati novi ugovor ?", "N" ) == "D"
            SET FILTER TO
    --        P_UGov2( partn->id )

            SELECT partn
    --        P_Ugov2()
         ELSE
            PopWa()
            RETURN .T.
         ENDIF

      ELSE
         SELECT partn
    --     P_Ugov2()
      ENDIF


      SELECT ugov
      GO TOP
      // postoji ugovor za partnera
      IF !Eof()
         SELECT rugov
         SEEK ugov->id
         IF !Found()
            IF Pitanje(, "Sve stavke ugovora su izbrisane, izbrisati ugovor u potputnosti (D/N) ?", "D" ) == "D"
               SELECT ugov
               DELETE
            ENDIF
         ENDIF
      ENDIF

      PopWa()

   ENDIF

   RETURN .T.

*/

// ----------------------------------
// uzima prikaz .. 06/2005
// ----------------------------------
FUNCTION fakt_do( dDat )

   LOCAL cRet := ""

   IF dDat == nil
      dDat := dat_l_fakt
   ENDIF

   cRet := Str( Month( dDat ), 2 ) + "/" + Str( Year( dDat ) )

   RETURN cRet


// -------------------------------
// mo_ye(5,2006) => 01.05.06
// -------------------------------
FUNCTION mo_ye( nm, ny )

   LOCAL cPom, cPom2

   // nm = 2, ny = 2006

   cPom2 := ""

   // 2006
   cPom := AllTrim( Str( ny, 4 ) )
   cPom := PadL( cPom, 4, "0" )
   cPom2 += cPom

   // 2
   cPom := AllTrim( Str( nm, 2 ) )
   // 02
   cPom := PadL( cPom, 2, "0" )
   cPom2 += cPom


   // cPom2 = 200602
   cPom2 += "01"

   RETURN SToD( cPom2 )
