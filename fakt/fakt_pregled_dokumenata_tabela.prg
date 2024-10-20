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

MEMVAR ImeKol
FIELD idfirma, idtipdok, brdok, rezerv, idvrstep, datdok, partner, iznos, rabat

STATIC s_lBrowseInitialized  := .F.

FUNCTION fakt_lista_dokumenata_tabelarni_pregled( lVrstePlacanja )

   LOCAL i
   LOCAL nWidthMeni := 30
   LOCAL nX, nY
   LOCAL hFaktParams := fakt_params()
   LOCAL cFiskalniUredjajModel := fiskalni_uredjaj_model()

   ImeKol := {}
   AAdd( ImeKol, { "F",            {|| is_fiskaliziran( cFiskalniUredjajModel ) } } )
   AAdd( ImeKol, { "RJ",           {|| fakt_doks_pregled->idfirma }  } )
   AAdd( ImeKol, { "VD",           {|| fakt_doks_pregled->idtipdok } } )
   AAdd( ImeKol, { "Brdok",        {|| fakt_doks_pregled->brdok + fakt_doks_pregled->rezerv } } )
   AAdd( ImeKol, { "VP",           {|| fakt_doks_pregled->idvrstep } } )
   AAdd( ImeKol, { "Datum",        {|| fakt_doks_pregled->Datdok } } )
   AAdd( ImeKol, { "Partner",      {|| PadR( fakt_doks_pregled->partner, 45 ) } } )
   AAdd( ImeKol, { "Ukupno",       {|| fakt_doks_pregled->iznos + fakt_doks_pregled->rabat } } )
   AAdd( ImeKol, { "Rabat",        {|| fakt_doks_pregled->rabat } } )
   AAdd( ImeKol, { "Ukupno-Rab ",  {|| fakt_doks_pregled->iznos } } )

   IF lVrstePlacanja
      AAdd( ImeKol, { _u( "Način placanja" ), {|| fakt_doks_pregled->idvrstep } } )
   ENDIF

   // datum otpremnice datum valute
   AAdd( ImeKol, { _u( "Datum plaćanja" ), {|| fakt_doks_pregled->datpl } } )
   AAdd( ImeKol, { "Dat.otpr",       {|| fakt_doks_pregled->dat_otpr } } )
   AAdd( ImeKol, { "Dat.val.",       {|| fakt_doks_pregled->dat_val } } )

   // AAdd( ImeKol, { "Fisk.rn",        {|| PadR( prikazi_brojeve_fiskalnog_racuna( fisc_rn, fisc_st ), 20 ) } } )
   AAdd( ImeKol, { "Fisk.vr",        {|| PadR( DToC( fisc_date ) + " " + AllTrim( fisc_time ), 20 ) } } )

   // prikaz operatera
   AAdd( ImeKol, { "Operater",       {|| GetUserName( field->oper_id ) } } )

   // veza sa dokumentima
   IF hFaktParams[ "fakt_dok_veze" ]
      AAdd( ImeKol, { "Vezni dokumenti", {|| PadR( get_fakt_vezni_dokumenti( idfirma, idtipdok, brdok ), 50 ) } } )
   ENDIF

   Kol := {}
   FOR i := 1 TO Len( ImeKol )
      AAdd( Kol, i )
   NEXT

   nX := f18_max_rows() - 4
   nY := f18_max_cols() - 3

   Box( , nX, nY )

   @ box_x_koord() + nX - 4, box_y_koord() + 2 SAY8 _upadr( " <ENTER> Štampa TXT", nWidthMeni ) + ;
      BROWSE_COL_SEP + _upadr( " < P > Povrat dokumenta", nWidthMeni ) + ;
      BROWSE_COL_SEP + _upadr( " < I > Informacije", nWidthMeni )
   @ box_x_koord() + nX - 3, box_y_koord() + 2 SAY8 _upadr( " <a+P> ili <L> Štampa ODT", nWidthMeni ) + ;
      BROWSE_COL_SEP + _upadr( " < S > Storno dokument", nWidthMeni ) + ;
      BROWSE_COL_SEP + _upadr( " < c+V > Postavi vezu fisk.", nWidthMeni )
   @ box_x_koord() + nX - 2, box_y_koord() + 2 SAY8 _upadr( " < R > Štampa fisk.računa", nWidthMeni ) + ;
      BROWSE_COL_SEP + _upadr( " < F > ponuda->račun", nWidthMeni ) + ;
      BROWSE_COL_SEP + _upadr( " < F5 > osvježi ", nWidthMeni )
   @ box_x_koord() + nX - 1, box_y_koord() + 2 SAY8 _upadr( " < W > Dupliciraj", nWidthMeni ) + ;
      BROWSE_COL_SEP + _upadr( " < K > Ispravka podataka", nWidthMeni ) + ;
      BROWSE_COL_SEP + _upadr( " < T > Duplikat fiskalnog rn.", nWidthMeni )


   fUPripremu := .F.

   adImeKol := {}

   PRIVATE  bGoreRed := NIL
   PRIVATE  bDoleRed := NIL
   PRIVATE  bDodajRed := NIL
   PRIVATE  TBInitialized := .F.
   PRIVATE  fTBNoviRed := .F. // trenutno smo u novom redu ?
   PRIVATE  TBCanClose := .T. // da li se moze zavrsiti unos podataka ?
   PRIVATE  bZaglavlje := NIL
   // zaglavlje se edituje kada je kursor u prvoj koloni
   // prvog reda
   // PRIVATE  TBSkipBlock := {| nSkip | SkipDB( nSkip, @nTBLine ) }

   PRIVATE  nTBLine := 1      // tekuca linija-kod viselinijskog browsa
   PRIVATE  nTBLastLine := 1  // broj linija kod viselinijskog browsa
   PRIVATE  TBPomjerise := "" // ako je ">2" pomjeri se lijevo dva
   // ovo se mo§e setovati u when/valid fjama

   PRIVATE  TBScatter := "N"  // uzmi samo tekuce polje

   FOR i := 1 TO Len( ImeKol )
      AAdd( adImeKol, ImeKol[ i ] )
   NEXT

   ASize( adImeKol, Len( adImeKol ) + 1 )
   AIns( adImeKol, 6 )
   adImeKol[ 6 ] := { "ID PARTNER", {|| idpartner }, "idpartner", {|| .T. }, {|| p_partner( @widpartner ) }, "V" }

   adKol := {}
   FOR i := 1 TO Len( adImeKol )
      AAdd( adKol, i )
   NEXT

   my_browse( "", nX - 3, nY, {| nCh | fakt_pregled_dokumenata_browse_key_handler( nCh, cFiskalniUredjajModel ) }, "", "", .F., ;
      NIL, NIL, NIL, 2,  NIL, NIL ) // , {| nSkip | fakt_pregled_dokumenata_skip_block( nSkip ) } ) // aOpcije, nFreeze, bPodvuci, nPrazno, nGPrazno, aPoredak, bSkipBlock

   BoxC()

   IF fUpripremu
      my_close_all_dbf()
      fakt_unos_dokumenta()
   ENDIF

   my_close_all_dbf()

   RETURN .T.



FUNCTION fakt_pregled_dokumenata_browse_key_handler( nCh, cFiskalniUredjajModel )

   LOCAL nRet := DE_CONT
   LOCAL hRec

   // LOCAL cFilter
   LOCAL nFiskDeviceId, hFiskalniParams
   LOCAL lRefresh
   LOCAL nFaktDokTekuciZapis := RecNo()

   // LOCAL nDbfArea := Select()
   LOCAL hFiskRacunParams
   LOCAL nFiscal
   LOCAL nRekl
   LOCAL dFiscal_date
   LOCAL cFiscal_time
   LOCAL lReload
   LOCAL nPovrat
   LOCAL GetList := {}

   s_lBrowseInitialized := .T.

   // cFilter := fakt_doks_pregled->( dbFilter() )
   SELECT F_FAKT_DOKS_PREGLED
   IF !Used()
      fakt_pregled_reload_tables()
   ENDIF

   prikazi_broj_fiskalnog_racuna( cFiskalniUredjajModel )

   lRefresh := .F.
   lReload := .F.

   DO CASE

   CASE nCh == K_ENTER

      // nRet := print_porezna_faktura( lOpcine )
      fakt_stamp_txt_dokumenta( fakt_doks_pregled->IdFirma, fakt_doks_pregled->IdTipdok, fakt_doks_pregled->brdok )
      lRefresh := .T.
      lReload := .T.

   CASE nCh == K_ALT_P .OR. Upper( Chr( nCh ) ) == "L"

      nRet := fakt_print_odt( .T. )
      lRefresh := .T.
      lReload := .T.

   CASE nCh == K_F5

      // SELECT fakt_doks_pregled
      // USE
      // o_fakt_doks_dbf()
      nRet := DE_REFRESH
      lRefresh := .T.
      lReload := .T.


   CASE nCh == K_CTRL_V

      IF postoji_fiskalni_racun( fakt_doks_pregled->idfirma, fakt_doks_pregled->idtipdok, fakt_doks_pregled->brdok, cFiskalniUredjajModel )

         MsgBeep( "veza: fiskalni račun već setovana !" )
         IF Pitanje( "FAKT_PROM_VEZU", "Promjeniti postojeću vezu (D/N)?", "N" ) == "N"
            RETURN DE_CONT
         ENDIF
      ENDIF

      IF Pitanje( "FISC_NVEZA_SET", "Setovati novu vezu sa fiskalnim računom (D/N)?", "D" ) == "N"
         RETURN DE_CONT
      ENDIF

      nFiscal := fakt_doks_pregled->fisc_rn
      nRekl := fakt_doks_pregled->fisc_st
      dFiscal_date := fakt_doks_pregled->fisc_date
      cFiscal_time := PadR( fakt_doks_pregled->fisc_time, 10 )

      Box( "#" + fakt_doks_pregled->idfirma + "-" + fakt_doks_pregled->idtipdok + "-" + fakt_doks_pregled->brdok, 4, 40 )
      @ box_x_koord() + 1, box_y_koord() + 2 SAY8 "   fiskalni račun:" GET nFiscal PICT "9999999999"
      @ box_x_koord() + 2, box_y_koord() + 2 SAY8 "reklamirani račun:" GET nRekl PICT "9999999999"
      @ box_x_koord() + 3, box_y_koord() + 2 SAY8 "            datum:" GET dFiscal_date
      @ box_x_koord() + 4, box_y_koord() + 2 SAY8 "          vrijeme:" GET cFiscal_time PICT "@S10"
      READ
      BoxC()

      IF nFiscal <> field->fisc_rn .OR. nRekl <> field->fisc_st

         hRec := hb_Hash()
         hRec[ "fisc_rn" ] := nFiscal
         hRec[ "fisc_st" ] := nRekl
         hRec[ "fisc_time" ] := cFiscal_time
         hRec[ "fisc_date" ] := dFiscal_date
         fakt_doks_update_fisk_parametri_by_id( fakt_doks_pregled->idfirma, fakt_doks_pregled->idtipdok, fakt_doks_pregled->brdok, hRec )

         nRet := DE_REFRESH
         lRefresh := .T.
         lReload := .T.
      ENDIF


   CASE Upper( Chr( nCh ) ) == "K"

      IF fakt_ispravka_podataka_azuriranog_dokumenta( fakt_doks_pregled->idfirma, fakt_doks_pregled->idtipdok, fakt_doks_pregled->brdok )
         nRet := DE_REFRESH
         lRefresh := .T.
         lReload := .T.
      ENDIF

   CASE Upper( Chr( nCh ) ) == "T"

      IF !( field->idtipdok $ "10#11" )
         MsgBeep( "Opcija moguća samo za račune !" )
         RETURN DE_CONT
      ENDIF

      IF !fiscal_opt_active()
         RETURN DE_CONT
      ENDIF

      nFiskDeviceId := odaberi_fiskalni_uredjaj( field->idtipdok, .F., .F. )

      IF nFiskDeviceId > 0
         hFiskalniParams := get_fiscal_device_params( nFiskDeviceId, my_user() )
         IF hFiskalniParams == NIL
            RETURN DE_CONT
         ENDIF
      ELSE

         RETURN DE_CONT
      ENDIF

      IF hFiskalniParams[ "drv" ] <> "FPRINT"
         MsgBeep( "Opcija moguća samo za FPRINT/DATECS uređaje !" )
         RETURN DE_CONT
      ENDIF

      hFiskRacunParams := hb_Hash()

      IF field->fisc_st <> 0
         hFiskRacunParams[ "storno" ] := .T.
      ELSE
         hFiskRacunParams[ "storno" ] := .F.
      ENDIF

      hFiskRacunParams[ "datum" ] := field->fisc_date
      hFiskRacunParams[ "vrijeme" ] := field->fisc_time

      fprint_dupliciraj_racun_vrijeme( hFiskalniParams, hFiskRacunParams )

      MsgBeep( "Duplikat računa za datum: " + DToC( field->fisc_date ) + ", vrijeme: " + AllTrim( field->fisc_time ) )
      lRefresh := .T.
      lReload := .T.


   CASE Upper( Chr( nCh ) ) == "R"

      IF !fiscal_opt_active()
         RETURN DE_CONT
      ENDIF

      IF field->idtipdok $ "10#11"

         IF postoji_fiskalni_racun( fakt_doks_pregled->idfirma, fakt_doks_pregled->idtipdok, fakt_doks_pregled->brdok, cFiskalniUredjajModel )
            MsgBeep( "Fiskalni račun već štampan za ovaj dokument !#Ako je potrebna ponovna štampa resetujte broj veze." )
            RETURN DE_CONT
         ENDIF

         IF Pitanje( "ST FISK RN5", "Štampati fiskalni račun za dokument " + ;
               AllTrim( field->idfirma ) + "-" + ;
               AllTrim( field->idtipdok ) + "-" + ;
               AllTrim( field->brdok ) + " (D/N) ?", "D" ) == "D"

            nFiskDeviceId := odaberi_fiskalni_uredjaj( field->idtipdok, .F., .F. )

            IF nFiskDeviceId > 0
               hFiskalniParams := get_fiscal_device_params( nFiskDeviceId, my_user() )
               IF hFiskalniParams == NIL
                  RETURN DE_CONT
               ENDIF
            ELSE
               RETURN DE_CONT
            ENDIF
            IF hFiskalniParams[ "print_fiscal" ] == "N"
               MsgBeep( "Nije Vam dozvoljena opcija za štampu fiskalnih računa !" )
               RETURN DE_CONT
            ENDIF

            fakt_fiskalni_racun( fakt_doks_pregled->idfirma, fakt_doks_pregled->idtipdok, fakt_doks_pregled->brdok, .F., hFiskalniParams )

            // SELECT ( nDbfArea )
            // nRet := DE_REFRESH
            lRefresh := .T.
            lReload := .T.

         ENDIF

      ENDIF

   CASE Upper( Chr( nCh ) ) == "W"

      fakt_napravi_duplikat( fakt_doks_pregled->idfirma, fakt_doks_pregled->idtipdok, fakt_doks_pregled->brdok )


   CASE Upper( Chr( nCh ) ) == "S"

      fakt_generisi_storno_dokument( fakt_doks_pregled->idfirma, fakt_doks_pregled->idtipdok, fakt_doks_pregled->brdok )

      IF Pitanje(, "Preći u tabelu pripreme ?", "D" ) == "D"
         fUPripremu := .T.
         nRet := DE_ABORT
         lRefresh := .F.
      ELSE
         nRet := DE_REFRESH
         lRefresh := .T.
         lReload := .T.
      ENDIF

   CASE Upper( Chr( nCh ) ) == "N"

      fakt_print_narudzbenica( fakt_doks_pregled->idfirma, fakt_doks_pregled->idtipdok, fakt_doks_pregled->brdok )
      nRet := DE_REFRESH
      lRefresh := .T.
      lReload := .T.

   CASE Upper( Chr( nCh ) ) == "F"

      IF fakt_doks_pregled->idtipdok == "20"
         nRet := fakt_generisi_fakturu_10_iz_20( fakt_doks_pregled->idfirma, fakt_doks_pregled->idtipdok, fakt_doks_pregled->brdok )
         lRefresh := .T.
         lReload := .T.
      ELSE
         MsgBeep( "Dokument mora biti tip 20!" )
      ENDIF

   CASE Upper( Chr( nCh ) ) == "P"

      nPovrat := povrat_fakt_dokumenta( fakt_doks_pregled->idfirma, fakt_doks_pregled->idtipdok, fakt_doks_pregled->brdok )

      // o_fakt_doks_dbf()
      IF nPovrat <> 0 .AND. Pitanje(, "Preći u tabelu pripreme ?", "D" ) == "D"
         fUPripremu := .T.
         lRefresh := .F.
         lReload := .F.
         nRet := DE_ABORT
      ELSE
         nRet := DE_REFRESH
         lRefresh := .T.
         lReload := .T.
      ENDIF

   ENDCASE

   IF lRefresh

      SELECT F_FAKT_DOKS_PREGLED
      IF !Used() .OR. lReload
         fakt_pregled_reload_tables()
      ENDIF

      SELECT FAKT_DOKS_PREGLED
      GO ( nFaktDokTekuciZapis )
      nRet := DE_REFRESH

   ENDIF

   RETURN nRet

/*
STATIC FUNCTION fakt_pregled_dokumenata_skip_block( nRecs, cFiskalniUredjajModel )

   LOCAL nSkipped := 0

   IF LastRec() != 0
      DO CASE
      CASE nRecs == 0
         IF Eof()
            dbSkip( - 1 )
            nSkipped := -1
         ELSE
            dbSkip( 0 )
         ENDIF
      CASE nRecs > 0 .AND. RecNo() != LastRec() + 1
         DO WHILE nSkipped < nRecs
            dbSkip()
            IF Eof()
               dbSkip( - 1 )
               EXIT
            ENDIF
            nSkipped++
         ENDDO
      CASE nRecs < 0
         DO WHILE nSkipped > nRecs
            dbSkip( - 1 )
            IF Bof()
               EXIT
            ENDIF
            nSkipped--
         ENDDO
      ENDCASE
   ENDIF

   IF TBInitialized .AND. nSkipped != 0  // TBInitialized se postavlja unutar my_browse, znaci da je zavrseno inicijalno renderisanje browse objekta
      prikazi_broj_fiskalnog_racuna( cFiskalniUredjajModel )
   ENDIF

   RETURN nSkipped
*/


STATIC FUNCTION prikazi_broj_fiskalnog_racuna( cFiskalniUredjajModel )

   LOCAL cFiskalniRacun
   LOCAL cReklamiraniRacun
   LOCAL _total
   LOCAL cTxt := "", cRn

   IF fakt_doks_pregled->idtipdok $ "10#11"
      cRN := fakt_doks_pregled->idfirma + "-" + fakt_doks_pregled->idtipdok + "-" + Trim( fakt_doks_pregled->brdok )
      IF !postoji_fiskalni_racun( fakt_doks_pregled->idfirma, fakt_doks_pregled->idtipdok, fakt_doks_pregled->brdok, cFiskalniUredjajModel )
         cTxt := cRn + ": nema fiskalnog računa !"
         @ box_x_koord() + 1, box_y_koord() + 2 SAY8 PadR( cTxt, 60 ) COLOR "W/R+"
      ELSE
         cFiskalniRacun := AllTrim( Str( fakt_doks_pregled->fisc_rn ) )
         cReklamiraniRacun := AllTrim( Str( fakt_doks_pregled->fisc_st ) )
         cTxt := cRn + ": "
         IF cReklamiraniRacun <> "0"
            cTxt += "reklamirani račun: " + cReklamiraniRacun + ", "
         ENDIF
         cTxt += "fiskalni račun: " + cFiskalniRacun
         @ box_x_koord() + 1, box_y_koord() + 2 SAY8 PadR( cTxt, 60 ) COLOR "GR+/B"
      ENDIF
   ELSE
      @ box_x_koord() + 1, box_y_koord() + 2 SAY PadR( "", 60 )
   ENDIF

   RETURN .T.



STATIC FUNCTION is_fiskaliziran( cFiskalniUredjajModel )

   LOCAL cInfo := " "

   IF !postoji_fiskalni_racun( fakt_doks_pregled->idfirma, fakt_doks_pregled->idtipdok, fakt_doks_pregled->brdok, cFiskalniUredjajModel )
      cInfo := " "
   ELSE
      cInfo := "F"
   ENDIF

   // prikazi_broj_fiskalnog_racuna( cFiskalniUredjajModel )

   RETURN cInfo



STATIC FUNCTION prikazi_brojeve_fiskalnog_racuna( _f_rn, _s_rn )

   LOCAL cTxt := ""

   cTxt += AllTrim( Str( _f_rn ) )

   IF _s_rn > 0
      cTxt += " / "
      cTxt += AllTrim( Str( _s_rn ) )
   ENDIF

   RETURN cTxt
