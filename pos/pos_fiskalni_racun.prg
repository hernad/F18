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

STATIC s_nFiskalniUredjajId := 0
STATIC s_hFiskalniUredjajParams
STATIC s_cFiskalniDrajverTremol := "TREMOL"
STATIC s_cFiskalniDrajverFPRINT := "FPRINT"
STATIC s_cFiskalniDrajverFLINK := "FLINK"
STATIC s_cFiskalniDrajverHCP := "HCP"
STATIC s_cFiskalniDrajverTRING := "TRING"
STATIC s_cFiskalniDrajverNaziv


/*
  pos_fiskaliziraj_racun( @hParams ) => set hParams["fiskalni_broj"]
*/

FUNCTION pos_fiskaliziraj_racun( hParams )

   LOCAL nDeviceId
   LOCAL hDeviceParams
   LOCAL lRet := .F.
   LOCAL hRet

   /*
   IF hParams[ "idpos" ] = "2 "
      Alert("Debug stampa fisk racun")
   ENDIF
   */

   IF hParams[ "fiskalni_izdat" ]
      // fiskalni račun je u ranijem pokušaju odštampan ali proces nije završen do kraja, ažuriranje u bazu nije uspjelo
      // hParams["fiskalni_broj"] - broj fiskalnog racuna
      RETURN pos_set_broj_fiskalnog_racuna( hParams )
   ENDIF

   nDeviceId := odaberi_fiskalni_uredjaj( NIL, .T., .F. )
   IF nDeviceId <> NIL .AND. nDeviceId > 0
      hDeviceParams := get_fiscal_device_params( nDeviceId, my_user() )
      IF hDeviceParams == NIL
         RETURN lRet
      ENDIF
   ELSE
      error_bar( "fisk", "Error GEN_FISK_RN: " +  hParams[ "brdok" ] )
      RETURN lRet
   ENDIF

   // hRet["error"], hRet["broj"]
   hRet := pos_send_to_fiskalni_printer( hParams, hDeviceParams )
   IF hRet["error"] <> 0
      log_write_file( "FISK_RN_ERROR:" + AllTrim( Str( hRet["error"] ) ) )
      MsgBeep( "Greška pri štampi fiskalnog računa: " + AllTrim( hParams[ "brdok" ] ) + " !?##Račun će ostati u pripremi" )
      RETURN .F.
   ENDIF

   hParams["fiskalni_broj"] := hRet["broj"] 

   RETURN .T.


STATIC FUNCTION pos_send_to_fiskalni_printer( hParams, hFiskalniParams )

   LOCAL cIdPos, dDatDok, cBrDok
   LOCAL nErrorLevel := 0
   LOCAL cFiskalniDravjerIme
   LOCAL lStorno
   LOCAL aStavkeRacuna
   LOCAL nStorno
   LOCAL nUplaceno
   LOCAL nFiskalniRnKojiSeStornira
   LOCAL GetList := {}
   LOCAL hRet := hb_hash()

   hRet["error"] := 0
   hRet["broj"] := 0

   IF hFiskalniParams == NIL
      RETURN hRet
   ENDIF

   cIdPos := hParams[ "idpos" ]
   dDatDok := hParams[ "datum" ]
   cBrDok := hParams[ "brdok" ]
   nUplaceno := hParams[ "uplaceno" ]

   s_nFiskalniUredjajId := hFiskalniParams[ "id" ]
   s_hFiskalniUredjajParams := hFiskalniParams
   cFiskalniDravjerIme := s_hFiskalniUredjajParams[ "drv" ]
   s_cFiskalniDrajverNaziv := cFiskalniDravjerIme

   // lStorno := pos_is_storno( cIdPos, "42", dDatDok, cBrDok )
   IF nUplaceno == -1 // fiskalizacija azuriranog racuna
      IF pos_iznos_racuna( cIdPos, "42", dDatDok, cBrDok ) < 0
         nFiskalniRnKojiSeStornira := 0
         Box(, 1, 60 )
         @ box_x_koord() + 1, box_y_koord() + 2 SAY8 "Broj fisk rn koji se stornira: " GET nFiskalniRnKojiSeStornira
         READ
         BoxC()
         IF LastKey() <> K_ESC
            nStorno := nFiskalniRnKojiSeStornira
         ELSE
            hRet["error"] := 1
            RETURN hRet
         ENDIF
      ELSE
         nStorno := 0
      ENDIF
   ELSE
      nStorno := pos_racun_u_pripremi_broj_storno_rn()
   ENDIF
   lStorno := nStorno > 0

   aStavkeRacuna := pos_fiskalni_stavke_racuna( cIdPos, "42", dDatDok, cBrDok, nStorno, nUplaceno )
   IF aStavkeRacuna == NIL /*.OR. pitanje(,"simulirati gresku", "N") == "D"*/
      hRet["error"] := 1
      RETURN hRet
   ENDIF

   DO CASE

   CASE cFiskalniDravjerIme == "TEST"
      hRet["error"] := 0
      hRet["broj"] := 0
      RETURN hRet

   CASE cFiskalniDravjerIme == s_cFiskalniDrajverFPRINT
      RETURN pos_to_fprint( cIdPos, "42", dDatDok, cBrDok, aStavkeRacuna, lStorno )

   CASE cFiskalniDravjerIme == s_cFiskalniDrajverFLINK
      RETURN pos_to_flink( cIdPos, "42", dDatDok, cBrDok, aStavkeRacuna, lStorno )

   CASE cFiskalniDravjerIme == s_cFiskalniDrajverTRING
      RETURN pos_to_tring( cIdPos, "42", dDatDok, cBrDok, aStavkeRacuna, lStorno )

   CASE cFiskalniDravjerIme == s_cFiskalniDrajverHCP
      RETURN pos_to_hcp( cIdPos, "42", dDatDok, cBrDok, aStavkeRacuna, lStorno, nUplaceno )

   CASE cFiskalniDravjerIme == s_cFiskalniDrajverTremol
      RETURN pos_to_tremol( cIdPos, "42", dDatDok, cBrDok, aStavkeRacuna, lStorno )

   ENDCASE

   RETURN hRet
   


STATIC FUNCTION pos_racun_u_pripremi_broj_storno_rn()

   LOCAL nStorno

   PushWa()
   SELECT _pos_pripr
   GO TOP
   nStorno := _pos_pripr->fisk_rn
   PopWa()

   RETURN nStorno


STATIC FUNCTION pos_fiskalni_stavke_racuna( cIdPos, cIdVd, dDatDok, cBrDok, nStorno, nUplaceniIznos )

   LOCAL aStavkeRacuna := {}
   LOCAL nPLU
   LOCAL cBrojFiskRNStorno := ""
   LOCAL nPOSRabatProcenat
   LOCAL cRobaBarkod, cIdRoba, cRobaNaziv, cJMJ
   LOCAL nRbr := 0
   LOCAL nPosRacunUkupno
   LOCAL cVrstaPlacanja
   LOCAL nLevel
   LOCAL aStavka
   LOCAL lStorno
   LOCAL lTmpTabele := .T.

   lStorno := ( nStorno > 0 )
   IF nUplaceniIznos == NIL
      nUplaceniIznos := 0
   ENDIF

   IF nUplaceniIznos < 0
      // fiskalizacija azuriranog racuna, vec smo pozicionirani na pos_doks
   ELSE
      IF !seek_pos_doks_tmp( cIdPos, cIdVd, dDatDok, cBrdok)
        lTmpTabele := .F.
        IF !seek_pos_doks( cIdPos, cIdVd, dDatDok, cBrDok ) // mora postojati ažurirani pos račun
           RETURN NIL
        ENDIF
      ENDIF
   ENDIF
   cVrstaPlacanja := pos_get_vrsta_placanja_0123( pos_doks->idvrstep)
   // IF cVrstaPlacanja <> "0"
   nPosRacunUkupno := pos_iznos_racuna( cIdPos, cIdVd, dDatDok, cBrDok, lTmpTabele)
   // ELSE
   // nPosRacunUkupno := 0
   // ENDIF
   IF nUplaceniIznos > 0
      nPosRacunUkupno := nUplaceniIznos
   ENDIF

   IF !seek_pos_pos_tmp( cIdPos, cIdVd, dDatDok, cBrDok )
     IF !seek_pos_pos( cIdPos, cIdVd, dDatDok, cBrDok )
         RETURN NIL
     ENDIF
   ENDIF
   DO WHILE !Eof() .AND. pos->idpos == cIdPos .AND. pos->idvd == cIdVd  .AND. DToS( pos->Datum ) == DToS( dDatDok ) .AND. pos->brdok == cBrDok

      aStavka := Array( 16 )
      IF nStorno > 0
         cBrojFiskRNStorno := AllTrim( Str( nStorno, 10, 0 ) )
      ENDIF
      cIdRoba := field->idroba

      select_o_roba( cIdRoba )
      nPLU := roba->fisc_plu
      IF s_hFiskalniUredjajParams[ "plu_type" ] == "D"
         altd()
         nPLU := auto_plu( .F., .F., s_hFiskalniUredjajParams )
      ENDIF

      IF s_cFiskalniDrajverNaziv == "FPRINT" .AND. nPLU == 0
         MsgBeep( "PLU artikla = 0, to nije moguće !" )
         RETURN NIL
      ENDIF

      cRobaBarkod := roba->barkod
      cJMJ := roba->jmj

      SELECT pos
      nPOSRabatProcenat := 0
      IF field->ncijena > 0  // cijena = 100, ncijena = 90, popust = 10
         nPOSRabatProcenat := ( ( field->cijena - field->ncijena ) / field->cijena ) * 100
      ENDIF

      cRobaNaziv := fiscal_art_naz_fix( roba->naz, s_hFiskalniUredjajParams[ "drv" ] )
      aStavka[ FISK_INDEX_BRDOK ] := AllTrim(cIdPos) + "-" + AllTrim(cBrDok)
      aStavka[ FISK_INDEX_RBR ] := AllTrim( Str( ++nRbr ) )
      aStavka[ FISK_INDEX_IDROBA ] := cIdRoba
      aStavka[ FISK_INDEX_ROBANAZIV ] := cRobaNaziv
      aStavka[ FISK_INDEX_CIJENA ] := pos->cijena
      aStavka[ FISK_INDEX_KOLICINA ] := Abs( pos->kolicina )
      aStavka[ FISK_INDEX_TARIFA ] := pos->idtarifa
      aStavka[ FISK_INDEX_FISK_RACUN_STORNIRATI ] := cBrojFiskRNStorno
      aStavka[ FISK_INDEX_PLU ] := nPLU
      aStavka[ FISK_INDEX_PLU_CIJENA ] := pos->cijena
      aStavka[ FISK_INDEX_POPUST ] := nPOSRabatProcenat
      aStavka[ FISK_INDEX_BARKOD ] := cRobaBarkod
      aStavka[ FISK_INDEX_VRSTA_PLACANJA ] := cVrstaPlacanja
      aStavka[ FISK_INDEX_TOTAL ] := nPosRacunUkupno
      aStavka[ FISK_INDEX_DATUM ] := dDatDok
      aStavka[ FISK_INDEX_JMJ ] :=  cJMJ
      AAdd( aStavkeRacuna, aStavka )
      SKIP
   ENDDO

   IF Len( aStavkeRacuna ) == 0
      MsgBeep( "Nema stavki za štampu na fiskalni uređaj !" )
      RETURN NIL
   ENDIF

   nLevel := 1
   IF provjeri_kolicine_i_cijene_fiskalnog_racuna( @aStavkeRacuna, lStorno, nLevel, s_hFiskalniUredjajParams[ "drv" ] ) < 0
      RETURN NIL
   ENDIF

   RETURN aStavkeRacuna


STATIC FUNCTION pos_to_fprint( cIdPos, cIdVd, dDatDok, cBrDok, aRacunStavke, lStorno )

   LOCAL nErrorLevel
   LOCAL nBrojFiskalnogRacuna := 0

   fprint_delete_answer( s_hFiskalniUredjajParams )
   fiskalni_fprint_racun( s_hFiskalniUredjajParams, aRacunStavke, NIL, lStorno )

   nErrorLevel := fprint_read_error( s_hFiskalniUredjajParams, @nBrojFiskalnogRacuna )
   IF nErrorLevel = -9
      IF Pitanje(, "Da li je nestalo trake ?", "N" ) == "D"
         IF Pitanje(, "Zamjenite traku i pritisnite 'D'", "D" ) == "D"
            log_write_file( "FISK_RN: nestalo trake - nastaviti sa cekanjem odgovora", 2 )
            nErrorLevel := fprint_read_error( s_hFiskalniUredjajParams, @nBrojFiskalnogRacuna )
         ENDIF
      ELSE
         log_write_file( "FISK_RN: nije nestalo trake", 2 )
      ENDIF
   ENDIF

   IF nBrojFiskalnogRacuna <= 0
      nErrorLevel := 1
   ENDIF

   IF nErrorLevel <> 0
      IF pos_fprint_da_li_je_racun_fiskalizovan( @nBrojFiskalnogRacuna )
         nErrorLevel := 0
      ELSE
         fprint_delete_out( s_hFiskalniUredjajParams )
         MsgBeep( "Greška kod štampanja fiskalnog računa !" )
      ENDIF

   ENDIF

   /*
   IF ( nBrojFiskalnogRacuna > 0 .AND. nErrorLevel == 0 )
      IF pos_set_broj_fiskalnog_racuna( cIdPos, cIdVd, dDatDok, cBrDok, nBrojFiskalnogRacuna )
         MsgBeep( "Kreiran fiskalni račun broj: " + AllTrim( Str( nBrojFiskalnogRacuna ) ) )
      ELSE
         nErrorLevel := FISK_ERROR_SET_BROJ_RACUNA
      ENDIF
   ENDIF
   */

   RETURN nErrorLevel


STATIC FUNCTION pos_to_tremol( cIdPos, cIdVd, dDatDok, cBrDok, aRacunStavke, lStorno )

   LOCAL nErrorLevel
   LOCAL cFiskalniFajlOdgovor
   LOCAL nBrojFiskalnogRacuna := 0
   LOCAL aRacunHeader := NIL
   LOCAL cFileWithPath
   LOCAL nTotal
   LOCAL nTremolCeka
   LOCAL bOutputHandler := {| cOutput | pos_pripr_set_opis( cOutput ) }  // sadrzaj xml-a staviti u polje _pos_pripr->opis
   LOCAL hRet := hb_hash()

   hRet["error"] := 0
   hRet["broj"] := 0

   nErrorLevel := fiskalni_tremol_racun( s_hFiskalniUredjajParams, aRacunStavke, aRacunHeader, lStorno, bOutputHandler )
   cFiskalniFajlOdgovor := fiscal_out_filename( s_hFiskalniUredjajParams[ "out_file" ], cBrDok )
   nTremolCeka := tremol_cekam_fajl_odgovora( s_hFiskalniUredjajParams, cFiskalniFajlOdgovor )
   IF nTremolCeka >= 0
      IF nTremolCeka > 0
         log_write_file( "FISK_RN: prodavac manuelno naveo broj računa " + AllTrim( Str( nTremolCeka ) ), 2 )
         nErrorLevel := 0
         nBrojFiskalnogRacuna := nTremolCeka
      ELSE
         nErrorLevel := tremol_read_output( s_hFiskalniUredjajParams, cFiskalniFajlOdgovor, @nBrojFiskalnogRacuna, @nTotal )
      ENDIF

      IF nErrorLevel <> 0
         hRet["error"] := nErrorLevel
         RETURN hRet
      ENDIF
      IF nBrojFiskalnogRacuna <= 0
         /*
         IF pos_set_broj_fiskalnog_racuna( cIdPos, cIdVd, dDatDok, cBrDok, nBrojFiskalnogRacuna )
            MsgBeep( "Kreiran fiskalni račun: " + AllTrim( Str( nBrojFiskalnogRacuna ) ) )
         ELSE
            nErrorLevel := FISK_ERROR_SET_BROJ_RACUNA
         ENDIF
         */
         hRet["error"] := FISK_ERROR_GET_BROJ_RACUNA
      ELSE
         hRet["error"] := 0
         hRet["broj"] := nErrorLevel
      ENDIF
   ELSE
      hRet["error"] := FISK_NEMA_ODGOVORA
   ENDIF

   log_write_file( "FISK_RN: TREMOL " +  AllTrim( cIdPos ) + "-" + AllTrim( cIdVd ) + "-" + AllTrim( cBrDok ) + ;
      " err level: " + AllTrim( Str( nErrorLevel ) ), 2 )

   RETURN hRet


STATIC FUNCTION pos_to_hcp( cIdPos, cIdVd, dDatDok, cBrDok, aRacunStavke, lStorno, nUplaceniIznos )

   LOCAL nErrorLevel := 0
   LOCAL nBrojFiskalnogRacuna := 0
   LOCAL hRet := hb_hash()

   hRet["error"] := 0
   hRet["broj"] := 0

   IF nUplaceniIznos == NIL
      nUplaceniIznos := 0
   ENDIF
   nErrorLevel := fiskalni_hcp_racun( s_hFiskalniUredjajParams, aRacunStavke, NIL, lStorno, nUplaceniIznos )
   IF nErrorLevel == 0
      nBrojFiskalnogRacuna := fiskalni_hcp_get_broj_racuna( s_hFiskalniUredjajParams, lStorno )
      IF nBrojFiskalnogRacuna <= 0
         /*
         IF pos_set_broj_fiskalnog_racuna( cIdPos, cIdVd, dDatDok, cBrDok, nBrojFiskalnogRacuna )
            MsgBeep( "Kreiran fiskalni račun: " + AllTrim( Str( nBrojFiskalnogRacuna ) ) )
         ELSE
            nErrorLevel := FISK_ERROR_SET_BROJ_RACUNA
         ENDIF
         */
         hRet["error"] := FISK_ERROR_GET_BROJ_RACUNA
      ELSE
         hRet["error"] := 0
         hRet["broj"] := nBrojFiskalnogRacuna
      ENDIF

   ENDIF

   RETURN hRet


STATIC FUNCTION pos_to_flink( cIdPos, cIdVd, dDatDok, cBrDok, aRacunStavke, lStorno )

   LOCAL nErrorLevel := 0
   LOCAL hParams := hb_hash()
   LOCAL hRet := hb_hash()

   hRet["error"] := 0
   hRet["broj"] := 0

   hParams["idpos"] := cIdPos
   hParams["idvd"] := cIdVd
   hParams["datum"] := dDatDok
   hParams["brdok"] := cBrDok

   nErrorLevel := fiskalni_flink_racun( s_hFiskalniUredjajParams, aRacunStavke, lStorno )

   /*
   IF pos_tmp_to_pos( hParams ) == -1
      RETURN -100
   ENDIF
   */
   hRet["error"] := nErrorLevel
 
   RETURN hRet


FUNCTION pos_set_broj_fiskalnog_racuna( hParams )

   LOCAL cQuery, oRet, oError, lRet := .F.
 
   LOCAL cIdPos, cIdVd, dDatDok, cBrDok, nBrojFiskRacuna


   cIdPos := hParams["idpos"]
   cIdVd := hParams["idvd"]
   dDatDok := hParams["datum"]
   cBrDok := hParams["brdok"]
   nBrojFiskRacuna := hParams["fiskalni_broj"]
   
  
   // flink ne setuje broj racuna, zato stavljamo uvijek -1, cime se setuje fisk_doks setuje broj racuna=NULL
   IF is_flink_fiskalni()
       nBrojFiskRacuna := -1
   ENDIF


   cQuery := "SELECT " + pos_prodavnica_sql_schema() + ".broj_fiskalnog_racuna(" + ;
      sql_quote( cIdPos ) + "," + ;
      sql_quote( cIdVd ) + "," + ;
      sql_quote( dDatDok ) + "," + ;
      sql_quote( cBrDok ) + "," + ;
      sql_quote( nBrojFiskRacuna ) + ")"

   BEGIN SEQUENCE WITH {| err | Break( err ) }

      oRet := run_sql_query( cQuery )
      IF is_var_objekat_tpqquery( oRet )
         IF oRet:FieldGet( 1 ) <> 0 .OR. nBrojFiskRacuna == -1
            lRet := .T.
         ENDIF
      ENDIF

   RECOVER USING oError
      Alert( _u( "Setovanje FISK broja " + AllTrim( Str( nBrojFiskRacuna ) ) + " neuspješno. Dupli broj?!" ) )
   END SEQUENCE

   RETURN lRet




FUNCTION pos_get_broj_fiskalnog_racuna_str( cIdPos, cIdVd, dDatDok, cBrDok )

   RETURN PadL( AllTrim( Str( pos_get_broj_fiskalnog_racuna( cIdPos, cIdVd, dDatDok, cBrDok ) ) ), 6 )


FUNCTION pos_get_broj_fiskalnog_racuna( cIdPos, cIdVd, dDatDok, cBrDok )

   LOCAL cQuery, oRet, nValue

   IF Empty( cIdPos )
      RETURN 0
   ENDIF

   cQuery := "SELECT " + pos_prodavnica_sql_schema() + ".broj_fiskalnog_racuna(" + ;
      sql_quote( cIdPos ) + "," + ;
      sql_quote( cIdVd ) + "," + ;
      sql_quote( dDatDok ) + "," + ;
      sql_quote( cBrDok ) + ", NULL)"

   oRet := run_sql_query( cQuery )
   IF is_var_objekat_tpqquery( oRet )

      nValue := oRet:FieldGet( 1 )
      IF nValue <> NIL
         RETURN nValue
      ELSE
         RETURN 0
      ENDIF
   ENDIF

   RETURN 0


FUNCTION pos_get_fiskalni_dok_id( cIdPos, cIdVd, dDatDok, cBrDok )

   LOCAL cQuery, oRet, cValue

   IF Empty( cIdPos )
      RETURN 0
   ENDIF

   cQuery := "SELECT " + pos_prodavnica_sql_schema() + ".fisk_dok_id(" + ;
      sql_quote( cIdPos ) + "," + ;
      sql_quote( cIdVd ) + "," + ;
      sql_quote( dDatDok ) + "," + ;
      sql_quote( cBrDok ) + ")"

   oRet := run_sql_query( cQuery )
   IF is_var_objekat_tpqquery( oRet )
      cValue := oRet:FieldGet( 1 )
      IF cValue <> NIL
         RETURN cValue
      ELSE
         RETURN ""
      ENDIF
   ENDIF

   RETURN ""



// CREATE OR REPLACE FUNCTION p15.set_ref_storno_fisk_dok( cIdPos varchar, cIdVd varchar, dDatDok date, cBrDok varchar, uuidFiskStorniran text ) RETURNS void

FUNCTION pos_set_ref_storno_fisk_dok( cIdPos, cIdVd, dDatDok, cBrDok, cUUIDFiskStorniran )

   LOCAL cQuery, oError

   IF Empty( cIdPos )
      RETURN 0
   ENDIF

   cQuery := "SELECT " + pos_prodavnica_sql_schema() + ".set_ref_storno_fisk_dok(" + ;
      sql_quote( cIdPos ) + "," + ;
      sql_quote( cIdVd ) + "," + ;
      sql_quote( dDatDok ) + "," + ;
      sql_quote( cBrDok ) + "," + ;
      sql_quote( cUUIDFiskStorniran ) +  ")"

   BEGIN SEQUENCE WITH {| err | Break( err ) }
      run_sql_query( cQuery )

   RECOVER USING  oError
      ?E oError:description
      RETURN .F.
   END SEQUENCE

   RETURN .T.

/*
   broj fiskalnog racuna koji je storno dokumenta ciji je uuid= cUUIDFiskStorniran

  PSQL FUNCTION p15.fisk_broj_rn_by_storno_ref( uuidFiskStorniran text ) RETURNS integer
*/
FUNCTION pos_fisk_broj_rn_by_storno_ref( cUUIDFiskStorniran )

   LOCAL cQuery, oRet, nValue

   IF is_flink_fiskalni()
      RETURN 0
   ENDIF

   cQuery := "SELECT " + pos_prodavnica_sql_schema() + ".fisk_broj_rn_by_storno_ref(" + ;
      sql_quote( cUUIDFiskStorniran ) +  ")"

   oRet := run_sql_query( cQuery )
   IF is_var_objekat_tpqquery( oRet )
      nValue := oRet:FieldGet( 1 )
      IF nValue <> NIL
         RETURN nValue
      ELSE
         RETURN 0
      ENDIF
   ENDIF

   RETURN 0

/*
   u p2.pos_fisk_doks.ref_storno_fisk_dok postoji ovaj racun

   FUNCTION p15.pos_is_storno( cIdPos varchar, cIdVd varchar, dDatDok date, cBrDok varchar) RETURNS boolean
*/
FUNCTION pos_is_storno( cIdPos, cIdVd, dDatDok, cBrDok )

   LOCAL cQuery, oRet, lValue

   cQuery := "SELECT " + pos_prodavnica_sql_schema() + ".pos_is_storno(" + ;
      sql_quote( cIdPos ) + "," + ;
      sql_quote( cIdVd ) + "," + ;
      sql_quote( dDatDok ) + "," + ;
      sql_quote( cBrDok ) + ")"

   oRet := run_sql_query( cQuery )
   IF is_var_objekat_tpqquery( oRet )
      lValue := oRet:FieldGet( 1 )
      IF lValue <> NIL
         RETURN lValue
      ELSE
         RETURN .F.
      ENDIF
   ENDIF

   RETURN .F.

// SELECT p15.pos_storno_broj_rn( '1 ','42','2019-03-15','       8' );  => 101

FUNCTION pos_storno_broj_rn( cIdPos, cIdVd, dDatDok, cBrDok )

   LOCAL cQuery, oRet, nValue

   cQuery := "SELECT " + pos_prodavnica_sql_schema() + ".pos_storno_broj_rn(" + ;
      sql_quote( cIdPos ) + "," + ;
      sql_quote( cIdVd ) + "," + ;
      sql_quote( dDatDok ) + "," + ;
      sql_quote( cBrDok ) + ")"

   oRet := run_sql_query( cQuery )
   IF is_var_objekat_tpqquery( oRet )
      nValue := oRet:FieldGet( 1 )
      IF nValue <> NIL
         RETURN nValue
      ELSE
         RETURN 0
      ENDIF
   ENDIF

   RETURN 0


STATIC FUNCTION pos_get_vrsta_placanja_0123( cIdVrstePlacanja )

   LOCAL cRet := "0"

   // LOCAL nDbfArea := Select()
   LOCAL cVrstaPlacanjaNaziv := ""

   IF Empty( cIdVrstePlacanja ) .OR. cIdVrstePlacanja == "01"
      RETURN cRet
   ENDIF

   IF cIdVrstePlacanja == "CK"
      RETURN "1"  // cek
   ENDIF

   IF cIdVrstePlacanja == "KT"
      RETURN "2"  // kartica   fiskalni_vrsta_placanja( id_plac, cDriver )
   ENDIF
   // select_o_vrstep( cIdVrstePlacanja )
   // cVrstaPlacanjaNaziv := Upper( AllTrim( vrstep->naz ) )
   // DO CASE
   // CASE "KARTICA" $ cVrstaPlacanjaNaziv
   // cRet := "1"
   // CASE "CEK" $ cVrstaPlacanjaNaziv
   // cRet := "2"
   // CASE "VIRMAN" $ cVrstaPlacanjaNaziv
   // cRet := "3"
   // OTHERWISE
   // cRet := "0"
   // ENDCASE

   // SELECT ( nDbfArea )

   RETURN "0"


STATIC FUNCTION pos_to_tring( cIdPos, cIdVd, dDatDok, cBrDok, aRacunStavke, lStorno )

   LOCAL nErrorLevel := 0
   LOCAL hRet := hb_hash()

   hRet["error"] := 0
   hRet["broj"] := 0

   nErrorLevel := tring_rn( s_hFiskalniUredjajParams, aRacunStavke, NIL, lStorno )

   hRet["error"] := nErrorLevel
   RETURN hRet



STATIC FUNCTION pos_pripr_set_opis( cOpis )

   SELECT _POS_PRIPR
   PushWa()

   SET ORDER TO
   GO TOP
   DO WHILE !Eof()
      RREPLACE opis WITH cOpis
      SKIP
   ENDDO
   PopWa()

   RETURN .T.



/*
      Opis: u slučaju greške sa fajlom odgovora, kada nema broja fiskalnog računa
            korisnika ispituje da li je račun fiskalizovan te nudi mogućnost ručnog unosa
            broja fiskalnog računa
      Parameters:
         nFiskalniBroj - broj fiskalnog računa, proslijeđuje se po referenci
      Return:
         .T. => trakica je izašla korektno
         .F. => račun primarno nije fiskalizovan na uređaj
         nFiskalniBroj - varijabla proslijeđena po refernci, sadrži broj fiskalnog računa
                   broj koji je korisnik unjeo na formi
*/
FUNCTION pos_fprint_da_li_je_racun_fiskalizovan( nFiskalniBroj )

   LOCAL lRet := .F.
   LOCAL nX
   LOCAL cStampano := " "
   LOCAL GetList := {}

   DO WHILE .T.

      nX := 1
      Box(, 5, 70 )
      @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Program ne može da dobije odgovor od fiskalnog uređaja !"
      ++nX
      @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Da li je račun ispravno odštampan na fiskalni uređaj (D/N) ?" GET cStampano VALID cStampano $ "DN" PICT "@!"
      READ

      IF LastKey() == K_ESC
         BoxC()
         MsgBeep( "ESC operacija nije dozvoljena. Odgovorite na postavljena pitanja." )
         LOOP
      ENDIF

      IF cStampano == "N"
         nFiskalniBroj := 0
         BoxC()
         EXIT
      ENDIF

      nX += 2
      @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Molimo unesite broj računa koji je fiskalni račun ispisao:" GET nFiskalniBroj VALID nFiskalniBroj > 0 PICT "9999999999"
      READ

      BoxC()

      IF LastKey() == K_ESC
         MsgBeep( "ESC operacija nije dozvoljena. Odgovortite na postavljena pitanja." )
         LOOP
      ENDIF

      lRet := .T.
      EXIT

   ENDDO

   RETURN lRet



