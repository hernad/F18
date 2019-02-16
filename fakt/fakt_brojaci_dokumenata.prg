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


FUNCTION fakt_stanje_artikla( cIdRj, cIdroba, nUl, nIzl, nRezerv, nRevers, lSilent )

   IF ( lSilent == NIL )
      lSilent := .F.
   ENDIF

   IF ( !lSilent )
      lBezMinusa := .F.
   ENDIF

   select_o_roba( cIdRoba )
   IF ( roba->tip == "U" )
      RETURN 0
   ENDIF

   IF ( !lSilent )
      MsgO( "Izračunavam trenutno stanje artikla ..." )
   ENDIF

   seek_fakt_3( NIL, cIdRoba )

   nUl := 0
   nIzl := 0
   nRezerv := 0
   nRevers := 0

   DO WHILE ( !Eof() .AND. cIdRoba == field->idRoba )
      IF ( fakt->idFirma <> cIdRj )
         SKIP
         LOOP
      ENDIF
      IF ( Left( field->idTipDok, 1 ) == "0" )
         // ulaz
         nUl += kolicina
      ELSEIF ( Left( field->idTipDok, 1 ) == "1" )
         // izlaz faktura
         IF !( Left( field->serBr, 1 ) == "*" .AND. field->idTipDok == "10" )
            nIzl += field->kolicina
         ENDIF
      ELSEIF ( field->idTipDok $ "20#27" )
         IF ( Left( field->serBr, 1 ) == "*" )
            nRezerv += field->kolicina
         ENDIF
      ELSEIF ( field->idTipDok == "21" )
         nRevers += field->kolicina
      ENDIF
      SKIP
   ENDDO

   IF ( !lSilent )
      MsgC()
   ENDIF

   RETURN .T.


FUNCTION fakt_mpc_iz_sifrarnika()

   LOCAL nCV := 0

   IF rj->( FieldPos( "tip" ) ) <> 0

      IF RJ->tip == "N1"
         nCV := roba->nc
      ELSEIF RJ->tip == "M1"
         nCV := roba->mpc
      ELSEIF RJ->tip == "M2"
         nCV := roba->mpc2
      ELSEIF RJ->tip == "M3"
         nCV := roba->mpc3
      ELSEIF RJ->tip == "M4"
         nCV := roba->mpc4
         // ELSEIF RJ->tip == "M5"
         // nCV := roba->mpc5
         // ELSEIF RJ->tip == "M6"
         // nCV := roba->mpc6
      ELSE
         nCV := roba->vpc
      ENDIF
   ELSE
      nCV := roba->vpc
   ENDIF

   RETURN nCV



FUNCTION fakt_vpc_iz_sifrarnika()

   LOCAL nCV := 0

   IF rj->tip == "V1"
      nCV := roba->vpc
   ELSEIF rj->tip == "V2"
      nCV := roba->vpc2
   ELSE
      nCV := roba->vpc
   ENDIF

   RETURN nCV



// ----------------------------------------------
// napuni sifrarnik sifk  sa poljem za unos
// podatka o PDV oslobadjanju
// ---------------------------------------------
FUNCTION fill_part()

   LOCAL lFound
   LOCAL cSeek
   LOCAL cNaz
   LOCAL cId
   LOCAL cOznaka

   fill_sifk_partn( "PDVO", "PDV oslob. ZPDV", "08", 3 )
   fill_sifk_partn( "PROF", "Profil partn.", "09", 25 )


   RETURN .T.





// ----------------------------------------------------------
// vraca numericki dio za broj dokumenta iz parametra
// ----------------------------------------------------------
FUNCTION fakt_brdok_numdio()
   RETURN fetch_metric( "fakt_numericki_dio_dokumenta", NIL, 5 )


// ------------------------------------------------------------
// resetuje brojač dokumenta ako smo pobrisali dokument
// ------------------------------------------------------------
FUNCTION fakt_reset_broj_dokumenta( cIdFirma, cIdTipDok, broj_dokumenta )

   LOCAL _param
   LOCAL _broj := 0

   // param: fakt/10/10
   _param := "fakt" + "/" + cIdFirma + "/" + cIdTipDok
   _broj := fetch_metric( _param, NIL, _broj )

   IF Val( PadR( broj_dokumenta, fakt_brdok_numdio() ) ) == _broj
      --_broj
      // smanji globalni brojac za 1
      set_metric( _param, NIL, _broj )
   ENDIF

   RETURN .T.



// ---------------------------------------------------------------
// vraca prazan broj dokumenta
// ---------------------------------------------------------------
FUNCTION fakt_prazan_broj_dokumenta()
   RETURN PadR( PadL( AllTrim( Str( 0 ) ), fakt_brdok_numdio(), "0" ), 8 )



// ------------------------------------------------------------------
// fakt, uzimanje novog broja za fakt dokument
// ------------------------------------------------------------------
FUNCTION fakt_novi_broj_dokumenta( cIdFirma, cIdTipDok, cSufix )

   LOCAL _broj := 0
   LOCAL _broj_doks := 0
   LOCAL _param
   LOCAL _tmp, _rest
   LOCAL cRet := ""
   LOCAL nDbfArea := Select()
   LOCAL _num_dio := fakt_brdok_numdio()

   IF cSufix == nil
      cSufix := ""
   ENDIF

   // param: fakt/10/10
   _param := "fakt" + "/" + cIdFirma + "/" + cIdTipDok
   _broj := fetch_metric( _param, NIL, _broj )

   // konsultuj i doks uporedo
   // o_fakt_doks_dbf()
   // SET ORDER TO TAG "1"
   // GO TOP
   // SEEK cIdFirma + cIdTipDok + "Ž"
   // SKIP -1
   seek_fakt_doks( cIdFirma, cIdTipDok )

   IF field->idfirma == cIdFirma .AND. field->idtipdok == cIdTipDok
      _broj_doks := Val( PadR( field->brdok, _num_dio ) )
   ELSE
      _broj_doks := 0
   ENDIF

   _broj := Max( _broj, _broj_doks ) // uzmi sta je vece, doks broj ili globalni brojac
   ++_broj // uvecaj broj

   // ovo ce napraviti string prave duzine...
   cRet := PadL( AllTrim( Str( _broj ) ), _num_dio, "0" )

   IF !Empty( cSufix )
      cRet := cRet + cSufix
   ENDIF

   cRet := PadR( cRet, 8 )
   set_metric( _param, NIL, _broj ) // upisi ga u globalni parametar

   SELECT ( nDbfArea )

   RETURN cRet



FUNCTION fakt_unos_set_broj_dokumenta()

   LOCAL cNoviBrojDokumenta
   LOCAL nTrec
   LOCAL _firma, _td, _null_brdok
   LOCAL _fakt_params := fakt_params()
   LOCAL oAttr
   LOCAL cIdTipDokTrazi

   PushWA()

   SELECT fakt_pripr
   GO TOP

   _null_brdok := PadR( Replicate( "0", fakt_brdok_numdio() ), 8 )
   _firma := field->idfirma
   _td := field->idtipdok

   // brojaci otpremnica po tip-u "22"
   IF _td == "12" .AND. _fakt_params[ "fakt_otpr_22_brojac" ]
      cIdTipDokTrazi := "22"
   ELSE
      cIdTipDokTrazi := _td
   ENDIF

   IF field->brdok <> _null_brdok
      // nemam sta raditi, broj je vec setovan
      PopWa()
      RETURN .F.
   ENDIF

   cNoviBrojDokumenta := fakt_novi_broj_dokumenta( _firma, cIdTipDokTrazi )

   SELECT fakt_pripr
   SET ORDER TO TAG "1"
   GO TOP

   my_flock()
   DO WHILE !Eof()

      SKIP 1
      nTrec := RecNo()
      SKIP -1
      IF field->idfirma == _firma .AND. field->idtipdok == _td .AND. field->brdok == _null_brdok
         REPLACE field->brdok WITH cNoviBrojDokumenta
      ENDIF
      GO ( nTrec )

   ENDDO
   my_unlock()

   oAttr := DokAttr():new( "fakt", F_FAKT_ATTR )
   oAttr:open_attr_dbf()

   SET ORDER TO TAG "1"
   GO TOP

   my_flock()
   DO WHILE !Eof()
      SKIP 1
      nTrec := RecNo()
      SKIP -1

      IF field->idfirma == _firma .AND. field->idtipdok == _td .AND. field->brdok == _null_brdok
         REPLACE field->brdok WITH cNoviBrojDokumenta
      ENDIF
      GO ( nTrec )

   ENDDO
   my_unlock()

   USE

   PopWa()

   RETURN .T.


// -----------------------------------------------------------
// provjerava postoji li rupa u brojacu dokumenata
// -----------------------------------------------------------
FUNCTION fakt_postoji_li_rupa_u_brojacu( cIdFirma, cIdTipDok, cBrDok )

   LOCAL nRet := 0
   LOCAL cQuery, _table
   LOCAL _max_dok, _par_dok, _param
   LOCAL hParams := fakt_params()
   LOCAL cIdTipDokTrazi, _tmp
   LOCAL _inc_error

   // parametar ako treba
   IF !hParams[ "kontrola_brojaca" ]
      RETURN 0 // 0-nema greska
   ENDIF

   IF "/S" $ cBrDok // storno dokument ne kontrolisi
      RETURN 0
   ENDIF

   // brojaci otpremnica po tip-u "22"
   IF cIdTipDok == "12" .AND. hParams[ "fakt_otpr_22_brojac" ]
      cIdTipDokTrazi := "22"
   ELSE
      cIdTipDokTrazi := cIdTipDok
   ENDIF

   cQuery := " SELECT MAX( brdok ) FROM " + F18_PSQL_SCHEMA_DOT + "fakt_doks " + ;
      " WHERE idfirma = " + sql_quote( cIdFirma ) + ;
      " AND idtipdok = " + sql_quote( cIdTipDokTrazi )


   _table := run_sql_query( cQuery )
   _dok := _table:FieldGet( 1 )
   _tmp := TokToNiz( _dok, "/" )
   IF Len( _tmp ) > 0
     _max_dok := Val( AllTrim( _tmp[ 1 ] ) )
   ELSE
     _max_dok := 0
   endif

   // param: fakt/10/10
   _param := "fakt" + "/" + cIdFirma + "/" + cIdTipDokTrazi
   _par_dok := fetch_metric( _param, NIL, 0 )

   _inc_error := _par_dok - _max_dok // provjera brojaca server dokument <> server param

   IF _inc_error > 30

      // eto greske !!!!
      MsgBeep( "Postoji greska sa brojacem dokumenta#Dokumenti: " + AllTrim( Str( _max_dok ) ) + ;
         ", parametri: " + AllTrim( Str( _par_dok ) ) + "#" + ;
         "Provjerite brojac" )
      nRet := 1
      RETURN nRet

   ENDIF

   // provjera priprema <> server
   _tmp := TokToNiz( cBrDok, "/" )
   IF Len( _tmp  ) == 0
      RETURN 0
   ENDIF
  
   _inc_error := Abs( _max_dok - Val( AllTrim( _tmp[ 1 ] ) ) )

   IF _inc_error > 30

      MsgBeep( "Postoji greška sa brojačem dokumenta#Priprema: " + AllTrim( cBrDok ) + ;
         ", server dokument: " + AllTrim( Str( _max_dok ) ) + "#" + ;
         "Provjerite brojač" )
      nRet := 1
      RETURN nRet

   ENDIF

   RETURN nRet



FUNCTION fakt_dokument_postoji( cFirma, cTipDok, cBroj )

   LOCAL lExist := .F.
   LOCAL cWhere

   cWhere := " idfirma = " + sql_quote( cFirma )
   cWhere += " AND idtipdok = " + sql_quote( cTipDok )
   cWhere += " AND brdok = " + sql_quote( cBroj )

   IF table_count( F18_PSQL_SCHEMA_DOT + "fakt_doks", cWhere ) > 0
      lExist := .T.
   ENDIF

   IF !lExist
      IF table_count( F18_PSQL_SCHEMA_DOT + "fakt_fakt", cWhere ) > 0
         lExist := .T.
      ENDIF
   ENDIF

   RETURN lExist


FUNCTION fakt_set_param_broj_dokumenta()

   LOCAL _param
   LOCAL _broj := 0
   LOCAL _broj_old
   LOCAL _firma := self_organizacija_id()
   LOCAL _tip_dok := "10"

   Box(, 2, 60 )

   @ box_x_koord() + 1, box_y_koord() + 2 SAY "Dokument:" GET _firma
   @ box_x_koord() + 1, Col() + 1 SAY "-" GET _tip_dok

   READ

   IF LastKey() == K_ESC
      BoxC()
      RETURN .F.
   ENDIF

   // param: fakt/10/10
   _param := "fakt" + "/" + _firma + "/" + _tip_dok
   _broj := fetch_metric( _param, NIL, _broj )
   _broj_old := _broj

   @ box_x_koord() + 2, box_y_koord() + 2 SAY "Zadnji broj dokumenta:" GET _broj PICT "999999"

   READ

   BoxC()

   IF LastKey() != K_ESC
      // snimi broj u globalni brojac
      IF _broj <> _broj_old
         set_metric( _param, NIL, _broj )
      ENDIF
   ENDIF

   RETURN .T.



FUNCTION fakt_admin_menu()

   LOCAL aOpc := {}
   LOCAL aOpcExe := {}
   LOCAL nIzbor := 1

   AAdd( aOpc, "1. podešavanje brojača dokumenta " )
   AAdd( aOpcExe, {|| fakt_set_param_broj_dokumenta() } )
   AAdd( aOpc, "2. fakt export (r_exp) " )
   AAdd( aOpcExe, {|| fakt_export_tbl_fakt() } )

   f18_menu( "fain", .F., nIzbor, aOpc, aOpcExe )

   RETURN .T.



FUNCTION fakt_ispravka_podataka_azuriranog_dokumenta( cIdFirma, cIdTipDok, cBrDok )

   LOCAL nDbfArea := Select()
   LOCAL lRet := .F.
   LOCAL nX := 1
   LOCAL nCounter
   LOCAL cIdPartner
   LOCAL cBrOtpr
   LOCAL cBrNar
   LOCAL dDatOtpr
   LOCAL dDatPl
   LOCAL cFaktTxtNovi
   LOCAL cIdVrstaPlacanja
   LOCAL cTmp
   LOCAL hFaktTxt
   LOCAL lOk := .T.
   LOCAL hParams
   LOCAL hRec
   LOCAL GetList := {}

   cIdPartner := field->idpartner
   cIdVrstaPlacanja := field->idvrstep

   // SELECT ( F_FAKT )
   // IF !Used()
   // o_fakt_dbf()
   // ENDIF

   // SELECT ( F_PARTN )
   // IF !Used()
   // o_partner()
   // ENDIF

   // SELECT fakt
   // SET ORDER TO TAG "1"
   // GO TOP
   // SEEK cIdFirma + cIdTipDok + cBrDok

   seek_fakt( cIdFirma, cIdTipDok,  cBrDok )
   IF Eof()
      SELECT ( nDbfArea )
      RETURN lRet
   ENDIF

   hFaktTxt := fakt_ftxt_decode_string( field->txt )

   // cBrOtpr := aFaktTxt[ 6 ]
   // cBrNar := aFaktTxt[ 8 ]
   // dDatOtpr := CToD( aFaktTxt[ 7 ] )
   // dDatPl := CToD( aFaktTxt[ 9 ] )

   Box(, 12, 65 )

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "*** korekcija podataka dokumenta"

   ++nX
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Partner:" GET cIdPartner VALID p_partner( @cIdPartner )
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Datum otpremnice:" GET dDatOtpr
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY " Broj otpremnice:" GET hFaktTxt[ "brotp" ] PICT "@S40"
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "  Datum plaćanja:" GET hFaktTxt[ "datpl" ]
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "        Narudžba:" GET hFaktTxt[ "brnar" ] PICT "@S40"
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "  Vrsta plaćanja:" GET cIdVrstaPlacanja VALID Empty( cIdVrstaPlacanja ) .OR. P_VRSTEP( @cIdVrstaPlacanja )

   READ

   BoxC()

   IF LastKey() == K_ESC
      SELECT ( nDbfArea )
      RETURN lRet
   ENDIF

   IF Pitanje(, "Izvršiti zamjenu podataka ? (D/N)", "D" ) == "N"
      SELECT ( nDbfArea )
      RETURN lRet
   ENDIF

   run_sql_query( "BEGIN" )

   IF !f18_lock_tables( { "fakt_fakt", "fakt_doks" }, .T. )
      run_sql_query( "ROLLBACK" )
      MsgBeep( "Ne mogu napraviti zaključavanje tabela.#Prekidam operaciju." )
      SELECT ( nDbfArea )
      RETURN lRet
   ENDIF

   select_o_partner( cIdPartner )

   cTmp := AllTrim( field->naz ) + "," + AllTrim( field->ptt ) + " " + AllTrim( field->mjesto )

   seek_fakt_doks( cIdFirma, cIdTipDok, cBrDok )
   IF Eof()
      hParams := hb_Hash()
      hParams[ "unlock" ] := { "fakt_fakt", "fakt_doks" }
      run_sql_query( "COMMIT", hParams )
      MsgBeep( "Dokument ne postoji, nije ništa zamjenjeno !" )
      RETURN lRet
   ENDIF

   hRec := dbf_get_rec()
   hRec[ "idpartner" ] := cIdPartner
   hRec[ "partner" ] := cTmp
   hRec[ "idvrstep" ] := cIdVrstaPlacanja

   lOk := update_rec_server_and_dbf( "fakt_doks", hRec, 1, "CONT" )

   IF !lOk
      run_sql_query( "ROLLBACK" )
      MsgBeep( "Postoji problem sa zamjenom podataka#Prekidam operaciju." )
      RETURN lRet
   ENDIF

   seek_fakt( cIdFirma, cIdTipDok, cBrDok )

   nCounter := 1
   DO WHILE !Eof() .AND. field->idfirma == cIdFirma .AND. field->idtipdok == cIdTipDok .AND. field->brdok == cBrDok

      hRec := dbf_get_rec()
      hRec[ "idpartner" ] := cIdPartner
      hRec[ "idvrstep" ] := cIdVrstaPlacanja

      IF nCounter == 1

         // cFaktTxtNovi := fakt_ftxt_encode_2( aFaktTxt, cBrNar, cBrOtpr, dDatOtpr, dDatPl )
         hFaktTxt[ "partner_txt_a" ] := AllTrim( partn->naz )
         hFaktTxt[ "partner_txt_b" ] := AllTrim( partn->adresa ) + ", Tel:" + AllTrim( partn->telefon )
         hFaktTxt[ "partner_txt_c" ] :=  AllTrim( partn->ptt ) + " " + AllTrim( partn->mjesto )

         hRec[ "txt" ] := fakt_ftxt_encode_5( hFaktTxt )
      ENDIF

      lOk := update_rec_server_and_dbf( "fakt_fakt", hRec, 1, "CONT" )

      IF !lOk
         EXIT
      ENDIF

      ++nCounter
      SKIP
   ENDDO

   IF lOk
      lRet := .T.
      hParams := hb_Hash()
      hParams[ "unlock" ] := { "fakt_fakt", "fakt_doks" }
      run_sql_query( "COMMIT", hParams )
   ELSE
      run_sql_query( "ROLLBACK" )
      lRet := .F.
   ENDIF

   SELECT ( nDbfArea )

   RETURN lRet
