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

FUNCTION pos_fiskalni_racun( cIdPos, dDatDok, cBrDok, hFiskalniParams, nUplaceniIznos )

   LOCAL nErrorLevel := 0
   LOCAL cFiskalniDravjerIme
   LOCAL lStorno
   LOCAL aItems

   IF nUplaceniIznos == NIL
      nUplaceniIznos := 0
   ENDIF
   IF hFiskalniParams == NIL
      RETURN nErrorLevel
   ENDIF

   s_nFiskalniUredjajId := hFiskalniParams[ "id" ]
   s_hFiskalniUredjajParams := hFiskalniParams
   cFiskalniDravjerIme := s_hFiskalniUredjajParams[ "drv" ]
   s_cFiskalniDrajverNaziv := cFiskalniDravjerIme
   lStorno := pos_is_storno( cIdPos, "42", dDatDok, cBrDok )
   aItems := pos_fiscal_stavke_racuna( cIdPos, "42", dDatDok, cBrDok, lStorno, nUplaceniIznos )
   IF aItems == NIL
      RETURN 1
   ENDIF

   DO CASE

   CASE cFiskalniDravjerIme == "TEST"
      nErrorLevel := 0

   CASE cFiskalniDravjerIme == s_cFiskalniDrajverFPRINT
      nErrorLevel := pos_to_fprint( cIdPos, "42", dDatDok, cBrDok, aItems, lStorno )

   CASE cFiskalniDravjerIme == s_cFiskalniDrajverFLINK
      nErrorLevel := pos_to_flink( cIdPos, "42", dDatDok, cBrDok, aItems, lStorno )

   CASE cFiskalniDravjerIme == s_cFiskalniDrajverTRING
      nErrorLevel := pos_to_tring( cIdPos, "42", dDatDok, cBrDok, aItems, lStorno )

   CASE cFiskalniDravjerIme == s_cFiskalniDrajverHCP
      nErrorLevel := pos_to_hcp( cIdPos, "42", dDatDok, cBrDok, aItems, lStorno, nUplaceniIznos )

   CASE cFiskalniDravjerIme == s_cFiskalniDrajverTremol
      nErrorLevel := pos_to_tremol( cIdPos, "42", dDatDok, cBrDok, aItems, lStorno, NIL )

   ENDCASE

   IF nErrorLevel > 0
      IF cFiskalniDravjerIme == s_cFiskalniDrajverTremol
         nErrorLevel := pos_to_tremol( cIdPos, "42", dDatDok, cBrDok, aItems, lStorno, "2" )
         IF nErrorLevel > 0
            MsgBeep( "Problem sa štampanjem na fiskalni uređaj !" )
         ENDIF
      ELSE
         MsgBeep( "Problem sa štampanjem na fiskalni uređaj !" )
      ENDIF
   ENDIF

   RETURN nErrorLevel


STATIC FUNCTION pos_fiscal_stavke_racuna( cIdPos, cIdVd, dDatDok, cBrDok, lStorno, nUplaceniIznos )

   LOCAL aItems := {}
   LOCAL nPLU
   LOCAL cBrojFiskRNStorno := ""
   LOCAL nPOSRabatProcenat
   LOCAL cRobaBarkod, cIdRoba, cRobaNaziv, cJMJ
   LOCAL nRbr := 0
   LOCAL nPosRacunUkupno
   LOCAL cVrstaPlacanja
   LOCAL nLevel

   IF nUplaceniIznos == NIL
      nUplaceniIznos := 0
   ENDIF

   IF !seek_pos_doks( cIdPos, cIdVd, dDatDok, cBrDok ) // mora postojati ažurirani pos račun
      RETURN NIL
   ENDIF
   cVrstaPlacanja := pos_get_vrsta_placanja_0123( field->idvrstep )
   IF cVrstaPlacanja <> "0"
      nPosRacunUkupno := pos_iznos_racuna( cIdPos, cIdVd, dDatDok, cBrDok )
   ELSE
      nPosRacunUkupno := 0
   ENDIF
   IF nUplaceniIznos > 0
      nPosRacunUkupno := nUplaceniIznos
   ENDIF

   IF !seek_pos_pos( cIdPos, cIdVd, dDatDok, cBrDok )
      RETURN NIL
   ENDIF
   DO WHILE !Eof() .AND. pos->idpos == cIdPos .AND. pos->idvd == cIdVd  .AND. DToS( pos->Datum ) == DToS( dDatDok ) .AND. pos->brdok == cBrDok

      nPOSRabatProcenat := 0
      IF lStorno
         cBrojFiskRNStorno := AllTrim( Str( pos_storno_broj_rn( cIdPos, cIdVd, dDatDok, cBrDok ) ) )
      ENDIF
      cIdRoba := field->idroba

      select_o_roba( cIdRoba )
      nPLU := roba->fisc_plu
      IF s_hFiskalniUredjajParams[ "plu_type" ] == "D"
         nPLU := auto_plu( NIL, NIL, s_hFiskalniUredjajParams )
      ENDIF

      IF s_cFiskalniDrajverNaziv == "FPRINT" .AND. nPLU == 0
         MsgBeep( "PLU artikla = 0, to nije moguće !" )
         RETURN NIL
      ENDIF

      cRobaBarkod := roba->barkod
      cJMJ := roba->jmj

      SELECT pos
      IF field->ncijena > 0  // cijena = 100, ncijena = 90, popust = 10
         nPOSRabatProcenat := ( ( field->cijena - field->ncijena ) / field->cijena ) * 100
      ENDIF

      cRobaNaziv := fiscal_art_naz_fix( roba->naz, s_hFiskalniUredjajParams[ "drv" ] )
      AAdd( aItems, { ;
         cBrDok, ;
         AllTrim( Str( ++nRbr ) ), ;
         cIdRoba, ;
         cRobaNaziv, ;
         pos->cijena, ;
         Abs( pos->kolicina ), ;
         pos->idtarifa, ;
         cBrojFiskRNStorno, ;
         nPLU, ;
         pos->cijena, ;
         nPOSRabatProcenat, ;
         cRobaBarkod, ;
         cVrstaPlacanja, ;
         nPosRacunUkupno, ;
         dDatDok, ;
         cJMJ } )

      SKIP

   ENDDO

   IF Len( aItems ) == 0
      MsgBeep( "Nema stavki za štampu na fiskalni uređaj !" )
      RETURN NIL
   ENDIF

   nLevel := 1
   IF provjeri_kolicine_i_cijene_fiskalnog_racuna( @aItems, lStorno, nLevel, s_hFiskalniUredjajParams[ "drv" ] ) < 0
      RETURN NIL
   ENDIF

   RETURN aItems


STATIC FUNCTION pos_to_fprint( cIdPos, cIdVd, dDatDok, cBrDok, aRacunStavke, lStorno )

   LOCAL nErrorLevel
   LOCAL nBrojFiskalnoRacuna := 0

   fprint_delete_answer( s_hFiskalniUredjajParams )
   fiskalni_fprint_racun( s_hFiskalniUredjajParams, aRacunStavke, NIL, lStorno )

   nErrorLevel := fprint_read_error( s_hFiskalniUredjajParams, @nBrojFiskalnoRacuna )
   IF nErrorLevel = -9
      IF Pitanje(, "Da li je nestalo trake ?", "N" ) == "D"
         IF Pitanje(, "Zamjenite traku i pritisnite 'D'", "D" ) == "D"
            nErrorLevel := fprint_read_error( s_hFiskalniUredjajParams, @nBrojFiskalnoRacuna )
         ENDIF
      ENDIF
   ENDIF

   IF nBrojFiskalnoRacuna <= 0
      nErrorLevel := 1
   ENDIF

   IF nErrorLevel <> 0
      IF pos_da_li_je_racun_fiskalizovan( @nBrojFiskalnoRacuna )
         nErrorLevel := 0
      ELSE
         fprint_delete_out( s_hFiskalniUredjajParams )
         MsgBeep( "Greška kod štampanja fiskalnog računa !" )
      ENDIF

   ENDIF

   IF ( nBrojFiskalnoRacuna > 0 .AND. nErrorLevel == 0 )
      pos_set_broj_fiskalnog_racuna( cIdPos, cIdVd, dDatDok, cBrDok, nBrojFiskalnoRacuna )
      MsgO( "Kreiran fiskalni račun broj: " + AllTrim( Str( nBrojFiskalnoRacuna ) ) )
      Sleep( 2 )
      MsgC()
   ENDIF

   RETURN nErrorLevel



STATIC FUNCTION pos_to_flink( cIdPos, cIdVd, dDatDok, cBrDok, aRacunStavke, lStorno )

   LOCAL nErrorLevel := 0

   // idemo sada na upis rn u fiskalni fajl
   nErrorLevel := fiskalni_flink_racun( s_hFiskalniUredjajParams, aRacunStavke, lStorno )

   RETURN nErrorLevel


STATIC FUNCTION pos_to_tremol( cIdPos, cIdVd, dDatDok, cBrDok, aRacunStavke, lStorno, cContinue )

   LOCAL nErrorLevel := 0
   LOCAL cFiskalniFajl
   LOCAL nBrojFiskalnoRacuna := 0
   LOCAL aRacunHeader := NIL

   IF cContinue == NIL
      cContinue := "0"
   ENDIF


   nErrorLevel := fiskalni_tremol_racun( s_hFiskalniUredjajParams, aRacunStavke, aRacunHeader, lStorno, cContinue )
   IF cContinue <> "2"
      cFiskalniFajl := fiscal_out_filename( s_hFiskalniUredjajParams[ "out_file" ], cBrDok )
      IF tremol_cekam_fajl_odgovora( s_hFiskalniUredjajParams, cFiskalniFajl )
         nErrorLevel := tremol_read_error( s_hFiskalniUredjajParams, cFiskalniFajl, @nBrojFiskalnoRacuna )
         IF nErrorLevel == 0 .AND. !lStorno .AND. nBrojFiskalnoRacuna > 0
            pos_set_broj_fiskalnog_racuna( cIdPos, cIdVd, dDatDok, cBrDok, nBrojFiskalnoRacuna )
            MsgBeep( "Kreiran fiskalni račun: " + AllTrim( Str( nBrojFiskalnoRacuna ) ) )
         ENDIF
      ENDIF
      // obrisi fajl da ne bi ostao kada server proradi ako je greska
      FErase( s_hFiskalniUredjajParams[ "out_dir" ] + cFiskalniFajl )

   ENDIF

   RETURN nErrorLevel


STATIC FUNCTION pos_to_hcp( cIdPos, cIdVd, dDatDok, cBrDok, aRacunStavke, lStorno, nUplaceniIznos )

   LOCAL nErrorLevel := 0
   LOCAL nBrojFiskalnoRacuna := 0

   IF nUplaceniIznos == NIL
      nUplaceniIznos := 0
   ENDIF
   nErrorLevel := fiskalni_hcp_racun( s_hFiskalniUredjajParams, aRacunStavke, NIL, lStorno, nUplaceniIznos )
   IF nErrorLevel == 0
      nBrojFiskalnoRacuna := fiskalni_hcp_get_broj_racuna( s_hFiskalniUredjajParams, lStorno )
      IF nBrojFiskalnoRacuna > 0
         pos_set_broj_fiskalnog_racuna( cIdPos, cIdVd, dDatDok, cBrDok, nBrojFiskalnoRacuna )
         MsgBeep( "Kreiran fiskalni racun: " + AllTrim( Str( nBrojFiskalnoRacuna ) ) )
      ENDIF

   ENDIF

   RETURN nErrorLevel


FUNCTION pos_set_broj_fiskalnog_racuna( cIdPos, cIdVd, dDatDok, cBrDok, nBrojFiskRacuna )

   LOCAL cQuery, oRet

   cQuery := "SELECT " + pos_prodavnica_sql_schema() + ".broj_fiskalnog_racuna(" + ;
      sql_quote( cIdPos ) + "," + ;
      sql_quote( cIdVd ) + "," + ;
      sql_quote( dDatDok ) + "," + ;
      sql_quote( cBrDok ) + "," + ;
      sql_quote( nBrojFiskRacuna ) + ")"

   oRet := run_sql_query( cQuery )
   IF is_var_objekat_tpqquery( oRet )
      IF oRet:FieldGet( 1 ) > 0
         RETURN .T.
      ENDIF
   ENDIF

   RETURN .F.


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

 FUNCTION p15.fisk_broj_rn_by_storno_ref( uuidFiskStorniran text ) RETURNS integer
*/
FUNCTION pos_fisk_broj_rn_by_storno_ref( cUUIDFiskStorniran )

   LOCAL cQuery, oRet, nValue

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


// FUNCTION p15.pos_is_storno( cIdPos varchar, cIdVd varchar, dDatDok date, cBrDok varchar) RETURNS boolean

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
   LOCAL nDbfArea := Select()
   LOCAL cVrstaPlacanjaNaziv := ""

   IF Empty( cIdVrstePlacanja ) .OR. cIdVrstePlacanja == "01"
      RETURN cRet
   ENDIF

   select_o_vrstep( cIdVrstePlacanja )
   cVrstaPlacanjaNaziv := Upper( AllTrim( vrstep->naz ) )
   DO CASE
   CASE "KARTICA" $ cVrstaPlacanjaNaziv
      cRet := "1"
   CASE "CEK" $ cVrstaPlacanjaNaziv
      cRet := "2"
   CASE "VIRMAN" $ cVrstaPlacanjaNaziv
      cRet := "3"
   OTHERWISE
      cRet := "0"
   ENDCASE

   SELECT ( nDbfArea )

   RETURN cRet


STATIC FUNCTION pos_to_tring( cIdPos, cIdVd, dDatDok, cBrDok, aRacunStavke, lStorno )

   LOCAL nErrorLevel := 0

   nErrorLevel := tring_rn( s_hFiskalniUredjajParams, aRacunStavke, NIL, lStorno )

   RETURN nErrorLevel



/* -------------------------------------------
 popravlja naziv artikla


STATIC FUNCTION _fix_naz( cR_naz, cNaziv )

   cNaziv := PadR( cR_naz, 30 )

   DO CASE

   CASE AllTrim( flink_type() ) == "FLINK"
      cNaziv := Lower( cNaziv )
      cNaziv := StrTran( cNaziv, ",", "." )

   ENDCASE

   RETURN .T.
*/

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
FUNCTION pos_da_li_je_racun_fiskalizovan( nFiskalniBroj )

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
