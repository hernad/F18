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


STATIC __MAX_QT := 99999.999
STATIC __MIN_QT := 0.001
STATIC __MAX_PRICE := 999999.99
STATIC __MIN_PRICE := 0.01
STATIC __MAX_PERC := 99.99
STATIC __MIN_PERC := -99.99



/*
 fajl za fiskalni stampac
*/

FUNCTION fiscal_out_filename( cFiskalniFileName, cFiskalniRacunBroj, cTrigerPLUiliCLIiliRCP )

   LOCAL cRet, _rn
   LOCAL _f_name := AllTrim( cFiskalniFileName )

   IF cTrigerPLUiliCLIiliRCP == nil
      cTrigerPLUiliCLIiliRCP := ""
   ENDIF

   cTrigerPLUiliCLIiliRCP := AllTrim( cTrigerPLUiliCLIiliRCP )

   DO CASE


   CASE "$rn" $ _f_name // po broju racuna ( TREMOL )

      IF Empty( cFiskalniRacunBroj )
         cRet := StrTran( _f_name, "$rn", "0000" )
      ELSE
         // broj racuna.xml
         _rn := PadL( AllTrim( cFiskalniRacunBroj ), 8, "0" )
         // ukini znak "/" ako postoji
         _rn := StrTran( _rn, "/", "" )
         cRet := StrTran( _f_name, "$rn", _rn )
      ENDIF

      cRet := Upper( cRet )


   CASE "TR$" $ _f_name // po trigeru ( HCP, TRING )

      // odredjuje PLU ili CLI ili RCP na osnovu trigera
      cRet := StrTran( _f_name, "TR$", cTrigerPLUiliCLIiliRCP )
      cRet := Upper( cRet )

      IF ".XML" $ Upper( cTrigerPLUiliCLIiliRCP )
         cRet := cTrigerPLUiliCLIiliRCP
      ENDIF


   OTHERWISE  // ostale verijante
      cRet := _f_name

   ENDCASE

   RETURN cRet


// ---------------------------------------------------
// ispravi naziv artikla
// ---------------------------------------------------
FUNCTION fiscal_art_naz_fix( naz, cDriver )

   LOCAL cRet := ""

   DO CASE
   CASE cDriver == "FPRINT"
      cRet := StrTran( naz, ";", "" )
   OTHERWISE
      cRet := naz
   ENDCASE

   RETURN cRet




// -------------------------------------------------
// generise novi plu kod za sifru
// -------------------------------------------------
FUNCTION gen_plu( nVal )

   LOCAL nPlu := 0

   IF ( ( Ch == K_CTRL_N ) .OR. ( Ch == K_F4 ) )

      IF LastKey() == K_ESC
         RETURN .F.
      ENDIF

      nVal := roba_max_fiskalni_plu() + 1

   ENDIF

   RETURN .T.


// -------------------------------------------------------
// generisi PLU kodove za postojece stavke sifraranika
// -------------------------------------------------------
FUNCTION gen_all_plu( lSilent )

   LOCAL lRet := .F.
   LOCAL lOk := .T.
   LOCAL nPLU := 0
   LOCAL lReset := .F.
   LOCAL nP_PLU := 0
   LOCAL nCnt
   LOCAL _rec
   LOCAL hParams

   IF lSilent == nil
      lSilent := .F.
   ENDIF

   IF lSilent == .F. .AND. !spec_funkcije_sifra( "GENPLU" )
      MsgBeep( "Neispravnan unos lozinke !" )
      RETURN .F.
   ENDIF

   IF lSilent == .F. .AND. Pitanje(, "Resetovati postojeće PLU", "N" ) == "D"
      lReset := .T.
   ENDIF

   IF lSilent == .T.
      lReset := .F.
   ENDIF

   run_sql_query( "BEGIN" )
   IF !f18_lock_tables( { "roba" }, .T. )
      run_sql_query( "ROLLBACK" )
      MsgBeep( "Ne mogu zaključati ROBA !#Prekidam operaciju." )
      RETURN lRet
   ENDIF

   /*
   o_roba()
   SELECT ROBA
   GO TOP


   // prvo mi nadji zadnji PLU kod
   SELECT roba
   SET ORDER TO TAG "PLU"
   GO TOP
   SEEK Str( 9999999999, 10 )
   SKIP -1
   nP_PLU := field->fisc_plu
   */

   nP_PLU := roba_max_fiskalni_plu()

   nCnt := 0

   o_roba()
   Box(, 1, 50 )
   DO WHILE !Eof()

      IF lReset == .F.
         // preskoci ako vec postoji PLU i
         // neces RESET
         IF field->fisc_plu <> 0
            SKIP
            LOOP
         ENDIF
      ENDIF

      ++ nCnt
      ++ nP_PLU

      _rec := dbf_get_rec()
      _rec[ "fisc_plu" ] := nP_PLU

      lOk := update_rec_server_and_dbf( "roba", _rec, 1, "CONT" )

      IF !lOk
         EXIT
      ENDIF

      @ box_x_koord() + 1, box_y_koord() + 2 SAY PadR( "idroba: " + field->id + " -> PLU: " + AllTrim( Str( nP_PLU ) ), 30 )

      SKIP

   ENDDO

   BoxC()

   IF lOk
      lRet := .T.
      hParams := hb_Hash()
      hParams[ "unlock" ] :=  { "roba" }
      run_sql_query( "COMMIT", hParams )
   ELSE
      run_sql_query( "ROLLBACK" )
   ENDIF

   IF nCnt > 0
      IF !lSilent
         MsgBeep( "Generisano " + AllTrim( Str( nCnt ) ) + " PLU kodova." )
      ENDIF
   ENDIF

   RETURN lRet



FUNCTION fiskalni_get_last_plu( nFiskDeviceId )

   LOCAL nFiskPLU := 0
   LOCAL _param_name := _get_auto_plu_param_name( nFiskDeviceId )

   nFiskPLU := fetch_metric( _param_name, nil, nFiskPLU )

   RETURN nFiskPLU




// --------------------------------------------------
// generisanje novog plug kod-a inkrementalno
// --------------------------------------------------
FUNCTION auto_plu( lResetPLU, lSilentMode, hFiskalniParams )

   LOCAL nFiskPLU := 0
   LOCAL nDbfArea := Select()
   LOCAL _param_name := _get_auto_plu_param_name( hFiskalniParams[ "id" ] )

   IF lResetPLU == nil
      lResetPLU := .F.
   ENDIF

   IF lSilentMode == nil
      lSilentMode := .F.
   ENDIF

   IF lResetPLU = .T.
      // uzmi inicijalni plu iz parametara
      nFiskPLU := hFiskalniParams[ "plu_init" ]
   ELSE
      nFiskPLU := fetch_metric( _param_name, nil, nFiskPLU )
      // prvi put pokrecemo opciju, uzmi init vrijednost !
      IF nFiskPLU == 0
         nFiskPLU := hFiskalniParams[ "plu_init" ]
      ENDIF
      // uvecaj za 1
      ++ nFiskPLU
   ENDIF

   IF lResetPLU .AND. !lSilentMode
      IF !spec_funkcije_sifra( "RESET" )
         MsgBeep( "Unesena pogrešna šifra !" )
         SELECT ( nDbfArea )
         RETURN nFiskPLU
      ENDIF
   ENDIF

   // upisi u sql/db
   set_metric( _param_name, nil, nFiskPLU )

   IF lResetPLU = .T. .AND. !lSilentMode
      MsgBeep( "Setovan početni PLU na: " + AllTrim( Str( nFiskPLU ) ) )
   ENDIF

   SELECT ( nDbfArea )

   RETURN nFiskPLU


// -----------------------------------------------------------------
// "auto_plu_dev_1" - auto plu device 1
// "auto_plu_dev_2" - auto plu device 2
// -----------------------------------------------------------------
STATIC FUNCTION _get_auto_plu_param_name( nFiskDeviceId )

   LOCAL cTmp := "auto_plu"
   LOCAL cRet

   cRet := cTmp + "_dev_" + AllTrim( Str( nFiskDeviceId ) )

   RETURN cRet



FUNCTION fiskalni_tarifa( cIdTarifa, cPDVDN, cDriver )

   LOCAL cIdTarifaFiskalni := "2"
   LOCAL cTmp


   cTmp := Left( Upper( AllTrim( cIdTarifa ) ), 4 ) // PDV17 -> PDV1 ili PDV7NP -> PDV7 ili PDV0IZ -> PDV0 ili PDVM

altd()
   DO CASE

   CASE ( cTmp == "PDV1" .OR. cTmp == "PDV7" ) .AND. cPDVDN == "D"  // pdv17

      IF cDriver == "TRING" // PDV je tarifna skupina "E"
         cIdTarifaFiskalni := "E"
      ELSEIF cDriver == "FPRINT" .OR. cDriver == "FLINK"
         cIdTarifaFiskalni := "2"
      ELSEIF cDriver == "HCP"
         cIdTarifaFiskalni := "1"
      ELSEIF cDriver == "TREMOL"
         cIdTarifaFiskalni := "2"
      ENDIF

   CASE cTmp == "PDV0" .AND. cPDVDN == "D"

      IF cDriver == "TRING" // bez PDV-a je tarifna skupina "K"
         cIdTarifaFiskalni := "K"
      ELSEIF cDriver == "FPRINT" .OR. cDriver == "FLINK"
         cIdTarifaFiskalni := "4"
      ELSEIF cDriver == "HCP"
         cIdTarifaFiskalni := "3"
      ELSEIF cDriver == "TREMOL"
         cIdTarifaFiskalni := "1"
      ENDIF

   CASE cTmp == "PDVM"

      IF cDriver == "FPRINT"
         cIdTarifaFiskalni := "5"
      ELSEIF cDriver == "TRING"
         cIdTarifaFiskalni := "M"
      ENDIF

   CASE cPDVDN == "N"

      IF cDriver == "TRING" // ne-pdv obveznik, skupina "A"
         cIdTarifaFiskalni := "A"
      ELSEIF cDriver == "FPRINT" .OR. cDriver == "FLINK"
         cIdTarifaFiskalni := "1"
      ELSEIF cDriver == "HCP"
         cIdTarifaFiskalni := "0"
      ELSEIF cDriver == "TREMOL"
         cIdTarifaFiskalni := "3"
      ENDIF

   OTHERWISE

      MsgBeep( "FISK: Greška sa tarifom (" + cIdTarifa + ") ?!" )

   ENDCASE

   RETURN cIdTarifaFiskalni


FUNCTION fiskalni_vrsta_placanja( id_plac, cDriver )

   LOCAL cRet := ""

   DO CASE

   CASE id_plac == "0"

      IF cDriver == "TRING"
         cRet := "Gotovina"
      ELSEIF cDriver $ "#HCP#FPRINT#"
         cRet := id_plac
      ELSEIF cDriver == "TREMOL"
         cRet := "Gotovina"
      ENDIF

   CASE id_plac == "1"

      IF cDriver == "TRING"
         cRet := "Cek"
      ELSEIF cDriver $ "#HCP#FPRINT#"
         cRet := id_plac
      ELSEIF cDriver == "TREMOL"
         cRet := "Cek"
      ENDIF

   CASE id_plac == "2"

      IF cDriver == "TRING"
         cRet := "Virman"
      ELSEIF cDriver $ "#HCP#FPRINT#"
         cRet := id_plac
      ELSEIF cDriver == "TREMOL"
         cRet := "Kartica"
      ENDIF

   CASE id_plac == "3"

      IF cDriver == "TRING"
         cRet := "Kartica"
      ELSEIF cDriver $ "#HCP#FPRINT#"
         cRet := id_plac
      ELSEIF cDriver == "TREMOL"
         cRet := "Virman"
      ENDIF

   ENDCASE

   RETURN cRet



FUNCTION provjeri_kolicine_i_cijene_fiskalnog_racuna( aRacunStavke, lStorno, nLevel, cDriver )

   LOCAL nI, _cijena, _plu_cijena, _kolicina, _naziv
   LOCAL _fix := 0
   LOCAL nRet := 0
   LOCAL lImaGreska := .F.

   IF cDriver == NIL
      cDriver := "FPRINT"
   ENDIF

   // aData[4] - naziv
   // aData[5] - cijena
   // aData[6] - kolicina

   set_min_max_values( cDriver )

   IF lStorno == NIL
      lStorno := .F.
   ENDIF

   FOR nI := 1 TO Len( aRacunStavke )

      lImaGreska := .F.

      _cijena := Round( aRacunStavke[ nI, 5 ], 4 )
      _plu_cijena := Round( aRacunStavke[ nI, 10 ], 4 )
      _kolicina := Round( aRacunStavke[ nI, 6 ], 4 )
      _naziv := aRacunStavke[ nI, 4 ]

      IF ( !is_ispravna_kolicina( _naziv, _kolicina ) .OR. !is_ispravna_cijena( _naziv, _cijena ) ) .OR. !is_ispravna_cijena( _naziv, _plu_cijena )

         lImaGreska := .T.

         IF ( nLevel > 1 .AND. _kolicina > 1 )

            prepakuj_vrijednosti_na_100_komada( @_kolicina, @_cijena, @_plu_cijena, @_naziv )

            aRacunStavke[ nI, 5 ] := _cijena
            aRacunStavke[ nI, 10 ] := _plu_cijena
            aRacunStavke[ nI, 6 ] := _kolicina
            aRacunStavke[ nI, 4 ] := _naziv

            lImaGreska := .F.
            ++ _fix

         ENDIF

         IF lImaGreska
            EXIT
         ENDIF

      ENDIF

   NEXT

   IF _fix > 0 .AND. nLevel > 1

      MsgBeep( "Pojedini artikli na računu su prepakovani na 100 kom !" )

   ELSEIF ( _fix > 0 .AND. nLevel == 1 ) .OR. lImaGreska

      nRet := -99

      MsgBeep ( "Pojedinim artiklima je količina/cijena van dozvoljenog ranga#Prekidam operaciju !" )

      IF lStorno
         nRet := 0
      ENDIF

   ENDIF

   RETURN nRet



STATIC FUNCTION set_min_max_values( cDriver )

   DO CASE

   CASE cDriver $ "FPRINT#TRING"

      __MAX_QT := 99999.999
      __MIN_QT := 0.001
      __MAX_PRICE := 999999.99
      __MIN_PRICE := 0.01
      __MAX_PERC := 99.99
      __MIN_PERC := -99.99

   CASE cDriver $ "HCP#TREMOL"

      __MAX_QT := 99999.999
      __MIN_QT := 0.001
      __MAX_PRICE := 999999.99
      __MIN_PRICE := 0.01
      __MAX_PERC := 99.99
      __MIN_PERC := -99.99

   ENDCASE

   RETURN .T.




STATIC FUNCTION is_ispravna_kolicina( cNaziv, nKolicina )
   RETURN validator_vrijednosti( "kol_" + cNaziv, nKolicina, __MIN_QT, __MAX_QT, 3 )



STATIC FUNCTION is_ispravna_cijena( cNaziv, nCijena )
   RETURN validator_vrijednosti( "cij_" + cNaziv, nCijena, __MIN_PRICE, __MAX_PRICE, 2 )



STATIC FUNCTION validator_vrijednosti( cNaziv, nValue, nMinValue, nMaxValue, nDec )

   LOCAL cMsg

   IF nValue > nMaxValue .OR. nValue < nMinValue
      cMsg := cNaziv + " / val: " + AllTrim( Str( nValue ) ) + " min: " + AllTrim( Str( nMinValue ) ) + " max: " +  AllTrim( Str( nMaxValue ) )
      error_bar( "fisk", cMsg )
      RETURN .F.
   ENDIF


   IF nDec <> NIL .AND. ( Abs( nValue ) - Abs( Round( nValue, nDec ) ) <> 0 )
      cMsg := cNaziv + " / val: " + AllTrim( Str( nValue ) ) + " dec max: " + AllTrim( Str( nDec ) )
      error_bar( "fisk", cMsg )

      RETURN .F.
   ENDIF

   RETURN .T.



STATIC FUNCTION prepakuj_vrijednosti_na_100_komada( nQtty, nPrice, nPPrice, cName )

   nQtty := nQtty / 100
   nPrice := nPrice * 100
   nPPrice := nPPrice * 100
   cName := Left( AllTrim( cName ), 5 ) + " x100"

   RETURN .T.



FUNCTION zadnji_fiscal_z_report_info( lFiskalniDnevniIzvjestaj )

   LOCAL _param_date := "zadnji_Z_izvjestaj_datum"
   LOCAL _param_time := "zadnji_Z_izvjestaj_vrijeme"
   LOCAL _z_date := fetch_metric( _param_date, NIL, CToD( "" ) )
   LOCAL _z_time := fetch_metric( _param_time, NIL, "" )
   LOCAL _warr := fetch_metric( "fiscal_opt_usr_daily_warrning", my_user(), "N" )
   LOCAL _fiscal_use := fiscal_opt_active()

   IF lFiskalniDnevniIzvjestaj == NIL
      lFiskalniDnevniIzvjestaj := .F.
   ENDIF

   IF !_fiscal_use
      RETURN .F.
   ENDIF

   IF _warr == "N"
      RETURN .F.
   ENDIF

   IF DToC( Date() ) + AllTrim( Time() ) > DToC( _z_date ) + AllTrim( _z_time )

      MsgBeep( "Zadnji dnevni izvještaj rađen " + DToC( _z_date ) + " u " + _z_time + "#" + ;
         "Potrebno napraviti dnevni izvještaj#" + ;
         "prije izdavanja novih računa !" )

      IF lFiskalniDnevniIzvjestaj
         IF Pitanje(, "Napraviti dnevni izvještaj (D/N) ?", "N" ) == "D"
         ENDIF
      ENDIF

   ENDIF

   RETURN .T.
