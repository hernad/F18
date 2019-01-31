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

MEMVAR gcF9usmece

FUNCTION fakt_azuriraj_dokumente_u_pripremi( lSilent )

   LOCAL aFaktDoks := {}
   LOCAL cIdFirma
   LOCAL cBrDok
   LOCAL cIdTipDok
   LOCAL lOk
   LOCAL cMsg
   LOCAL nI

   IF ( lSilent == NIL )
      lSilent := .F.
   ENDIF

   close_open_fakt_tabele()

   IF ( !lSilent .AND. Pitanje( "FAKT_AZUR", "Sigurno želite izvršiti ažuriranje (D/N) ?", "N" ) == "N" )
      RETURN aFaktDoks
   ENDIF

   SELECT fakt_pripr
   USE

   o_fakt_pripr()
   GO TOP

   aFaktDoks := fakt_dokumenti_pripreme_u_matricu()

   IF Len( aFaktDoks ) == 0
      MsgBeep( "Postojeći dokumenti u pripremi već postoje ažurirani u bazi !" )
      RETURN aFaktDoks
   ENDIF

   IF Len( aFaktDoks ) == 1
      SELECT fakt_pripr
      GO TOP
      IF !provjeri_redni_broj()
         MsgBeep( "Redni brojevi u dokumentu nisu ispravni !" )
         RETURN aFaktDoks
      ENDIF
   ENDIF

   DokAttr():New( "fakt", F_FAKT_ATTR ):cleanup_attrs( F_FAKT_PRIPR, aFaktDoks )

   lOk := .T.

   MsgO( "Ažuriranje dokumenata u toku ..." )

   FOR nI := 1 TO Len( aFaktDoks )

      cIdFirma   := aFaktDoks[ nI, 1 ]
      cIdTipDok := aFaktDoks[ nI, 2 ]
      cBrDok     := aFaktDoks[ nI, 3 ]

      IF fakt_dokument_postoji( cIdFirma, cIdTipDok, cBrDok )
         MsgBeep( "Dokument " + cIdFirma + "-" + cIdTipDok + "-" + AllTrim( cBrDok ) + " već postoji ažuriran u bazi !" )
         lOk := .F.
      ENDIF

      IF lOk .AND. fakt_azur_sql( cIdFirma, cIdTipDok, cBrDok  )

/*
         IF lOk .AND. !fakt_azur_dbf( cIdFirma, cIdTipDok, cBrDok )
            cMsg := "Neuspješno DBF ažuriranje dokumenta: " + cIdFirma + "-" + cIdTipDok + "-" + cBrDok
            log_write( cMsg, 1 )
            MsgBeep( cMsg )
            lOk := .F.
         ELSE
            log_write( "F18_DOK_OPER: azuriranje fakt dokumenta: " + cIdFirma + "-" + cIdTipDok + "-" + cBrDok, 2 )
         ENDIF
*/

      ELSE
         cMsg := "Neuspješno SQL ažuriranje dokumenta: " + cIdFirma + "-" + cIdTipDok + "-" + cBrDok
         log_write( cMsg, 1 )
         MsgBeep( cMsg )
         lOk := .F.
      ENDIF

   NEXT

   MsgC()

   IF !lOk
      RETURN aFaktDoks
   ENDIF

   SELECT fakt_pripr

   MsgO( "FAKT brišem tabele pripreme ..." )

   SELECT fakt_pripr
   my_dbf_zap()
   DokAttr():New( "fakt", F_FAKT_ATTR ):zap_attr_dbf()

   MsgC()

   // my_close_all_dbf()

   RETURN aFaktDoks


STATIC FUNCTION fakt_seek_pripr_dokument( cIdFirma, cIdTipDok, cBrDok )

   LOCAL lRet := .F.

   o_fakt_pripr()

   SELECT fakt_pripr
   SET ORDER TO TAG "1"
   GO TOP
   SEEK cIdFirma + cIdTipDok + cBrDok // fakt_pripr

   IF Found()
      lRet := .T.
   ENDIF

   RETURN lRet



STATIC FUNCTION fakt_azur_sql( cIdFirma, cIdTipDok, cBrDok )

   LOCAL lOk
   LOCAL _tbl_fakt, _tbl_doks, _tbl_doks2
   LOCAL cTempFaktId
   LOCAL hRec
   LOCAL aIdsFakt  := {}
   LOCAL aIdsFaktDoks  := {}
   LOCAL aIdsFaktDoks2 := {}
   LOCAL oAttr
   LOCAL hParams

   // my_close_all_dbf()

   _tbl_fakt  := "fakt_fakt"
   _tbl_doks  := "fakt_doks"
   _tbl_doks2 := "fakt_doks2"

   Box(, 5, 60 )

   lOk := .T.

   o_fakt_pripr()

   IF !fakt_seek_pripr_dokument( cIdFirma, cIdTipDok, cBrDok )
      Alert( "U tabeli pripreme ne postoji dokument: " + cIdFirma + "-" + cIdTipDok + "-" + cBrDok )
      RETURN .F.
   ENDIF


   run_sql_query( "BEGIN" )

   IF !f18_lock_tables( { "fakt_fakt", "fakt_doks", "fakt_doks2" }, .T. )
      run_sql_query( "ROLLBACK" )
      MsgBeep( "Ne mogu zaključati tabele.#Prekidam operaciju." )
      RETURN .F.
   ENDIF

   close_open_fakt_tabele()
   seek_fakt( "XXX" )
   seek_fakt_doks( "XXX" )
   seek_fakt_doks2( "XXX" )

   fakt_seek_pripr_dokument( cIdFirma, cIdTipDok, cBrDok )
   hRec := dbf_get_rec()

   cTempFaktId := hRec[ "idfirma" ] + hRec[ "idtipdok" ] + hRec[ "brdok" ]
   AAdd( aIdsFakt, "#2" + cTempFaktId )

   @ box_x_koord() + 1, box_y_koord() + 2 SAY "fakt_fakt -> server: " + cTempFaktId

   DO WHILE !Eof() .AND. fakt_pripr->idfirma == cIdFirma .AND. fakt_pripr->idtipdok == cIdTipDok .AND. PADR( fakt_pripr->brdok, FIELD_LEN_FAKT_BRDOK ) == PADR( cBrDok, FIELD_LEN_FAKT_BRDOK )
      hRec := dbf_get_rec()
      IF !sql_table_update( "fakt_fakt", "ins", hRec )
         lOk := .F.
         EXIT
      ENDIF
      SELECT FAKT_PRIPR
      SKIP
   ENDDO


   IF lOk == .T.
      @ box_x_koord() + 2, box_y_koord() + 2 SAY "fakt_doks -> server: " + cTempFaktId
      AAdd( aIdsFaktDoks, cTempFaktId )
      SELECT fakt_pripr
      hRec := get_fakt_doks_data( cIdFirma, cIdTipDok, cBrDok )
      IF !sql_table_update( "fakt_doks", "ins", hRec )
         lOk := .F.
      ENDIF
   ENDIF


   IF lOk == .T.
      @ box_x_koord() + 3, box_y_koord() + 2 SAY "fakt_doks2 -> server: " + cTempFaktId
      AAdd( aIdsFaktDoks2, cTempFaktId )
      hRec := get_fakt_doks2_data( cIdFirma, cIdTipDok, cBrDok )
      SELECT fakt_pripr
      IF !sql_table_update( "fakt_doks2", "ins", hRec )
         lOk := .F.
      ENDIF
   ENDIF


   IF lOk == .T.
      @ box_x_koord() + 4, box_y_koord() + 2 SAY "fakt_atributi -> server "
      oAttr := DokAttr():New( "fakt", F_FAKT_ATTR )
      oAttr:hAttrId[ "idfirma" ] := cIdFirma
      oAttr:hAttrId[ "idtipdok" ] := cIdTipDok
      oAttr:hAttrId[ "brdok" ] := cBrDok
      lOk := oAttr:push_attr_from_dbf_to_server()
   ENDIF

   IF !lOk
      run_sql_query( "ROLLBACK" )
   ELSE

      @ box_x_koord() + 4, box_y_koord() + 2 SAY "push ids to semaphore: " + cTempFaktId
      push_ids_to_semaphore( _tbl_fakt, aIdsFakt   )
      push_ids_to_semaphore( _tbl_doks, aIdsFaktDoks   )
      push_ids_to_semaphore( _tbl_doks2, aIdsFaktDoks2  )

      hParams := hb_Hash()
      hParams[ "unlock" ] :=  { "fakt_fakt", "fakt_doks", "fakt_doks2" }
      run_sql_query( "COMMIT", hParams )


   ENDIF

   BoxC()

   RETURN lOk


/*
STATIC FUNCTION fakt_azur_dbf( cIdFirma, cIdTipDok, cBrDok, lSilent )

   LOCAL _a_memo
   LOCAL hRec
   LOCAL _fakt_totals
   LOCAL _fakt_doks_data
   LOCAL _fakt_doks2_data
   LOCAL cMsg

   close_open_fakt_tabele()

   Box( "#Proces ažuriranja dbf-a u toku", 3, 60 )

   @ box_x_koord() + 1, box_y_koord() + 2 SAY "fakt_pripr -> fakt_fakt"
   fakt_seek_pripr_dokument( cIdFirma, cIdTipDok, cBrDok )

   DO WHILE !Eof() .AND. field->idfirma == cIdFirma .AND. field->idtipdok == cIdTipDok .AND. field->brdok == cBrDok

      SELECT fakt_pripr
      hRec := dbf_get_rec()

      select_o_fakt_dbf()
      APPEND BLANK
      dbf_update_rec( hRec, .T. )

      SELECT fakt_pripr
      SKIP

   ENDDO

   @ box_x_koord() + 2, box_y_koord() + 2 SAY "fakt_doks " + cIdFirma + cIdTipDok + cBrDok

   IF seek_fakt_doks( cIdFirma, cIdTipDok, cBrDok )
   //IF !Eof()
      hRec := get_fakt_doks_data( cIdFirma, cIdTipDok, cBrDok )
      hb_HDel( hRec, "brisano" )
      hb_HDel( hRec, "sifra" )

      select_o_fakt_doks_dbf()
      APPEND BLANK
      dbf_update_rec( hRec, .T. )

   ELSE

      cMsg := "ERR: " + RECI_GDJE_SAM0 + " postoji zapis u fakt_doks : " + cIdFirma + cIdTipDok + cBrDok
      Alert( cMsg )
      log_write( cMsg, 5 )

   ENDIF


   @ box_x_koord() + 3, box_y_koord() + 2 SAY "fakt_doks2 " + cIdFirma + cIdTipDok + cBrDok

   IF seek_fakt_doks2( cIdFirma, cIdTipDok, cBrDok )
   //IF !Eof()
      hRec := get_fakt_doks2_data( cIdFirma, cIdTipDok, cBrDok )
      select_o_fakt_doks2_dbf()
      APPEND BLANK
      dbf_update_rec( hRec, .T. )

   ELSE
      cMsg := "ERR: " + RECI_GDJE_SAM0 + " postoji zapis u fakt_doks2 : " + cIdFirma + cIdTipDok + cBrDok
      Alert( cMsg )
      log_write( cMsg, 5 )
   ENDIF

   BoxC()

   fakt_seek_pripr_dokument( cIdFirma, cIdTipDok, cBrDok )

   RETURN .T.
*/

/*
   Opis: formira string naziva partnera za tabelu FAKT_DOKS polje "partner"

   Format: naziv adresa, ptt mjesto

   Primjer: "bring.out" d.o.o. Juraja Najtharta 3, 71000 Sarajevo
*/

STATIC FUNCTION naziv_partnera_za_tabelu_doks( cId_partner )

   LOCAL cRet := ""
   LOCAL nDbfArea := Select()

   select_o_partner( cId_partner )

   cRet := AllTrim( partn->naz )
   cRet += " "
   cRet += AllTrim( partn->adresa )
   cRet += ","
   cRet += AllTrim( partn->ptt )
   cRet += " "
   cRet += AllTrim( partn->mjesto )

   cRet := PadR( cRet, FAKT_DOKS_PARTNER_LENGTH )

   SELECT ( nDbfArea )

   RETURN cRet


/*
   Opis: formira hash string podataka za tabelu FAKT_DOKS2 kod ažuriranja dokumenta
*/

FUNCTION get_fakt_doks2_data( cIdFirma, cIdTipDok, cBrDok )

   LOCAL hFaktData := hb_Hash()
   LOCAL aMemo

   select_o_fakt_pripr()
   GO TOP
   SEEK cIdFirma + cIdTipDok + cBrDok // fakt_pripr

   hFaktData[ "idfirma" ]  := field->idfirma
   hFaktData[ "brdok" ]    := field->brdok
   hFaktData[ "idtipdok" ] := field->idtipdok

   aMemo := fakt_ftxt_decode( field->txt )

   hFaktData[ "k1" ] := if( Len( aMemo ) >= 11, aMemo[ 11 ], "" )
   hFaktData[ "k2" ] := if( Len( aMemo ) >= 12, aMemo[ 12 ], "" )
   hFaktData[ "k3" ] := if( Len( aMemo ) >= 13, aMemo[ 13 ], "" )
   hFaktData[ "k4" ] := if( Len( aMemo ) >= 14, aMemo[ 14 ], "" )
   hFaktData[ "k5" ] := if( Len( aMemo ) >= 15, aMemo[ 15 ], "" )
   hFaktData[ "n1" ] := if( Len( aMemo ) >= 16, Val( AllTrim( aMemo[ 16 ] ) ), 0 )
   hFaktData[ "n2" ] := if( Len( aMemo ) >= 17, Val( AllTrim( aMemo[ 17 ] ) ), 0 )

   RETURN hFaktData


/*
   Opis: formira hash string podataka za tabelu FAKT_DOKS kod ažuriranja dokumenta
*/

FUNCTION get_fakt_doks_data( cIdFirma, cIdTipDok, cBrDok )

   LOCAL _fakt_totals
   LOCAL hFaktData
   LOCAL aMemo

   hFaktData := hb_Hash()
   hFaktData[ "idfirma" ]  := cIdFirma
   hFaktData[ "idtipdok" ] := cIdTipDok
   hFaktData[ "brdok" ]    := cBrDok

   select_o_fakt_pripr()
   HSEEK cIdFirma + cIdTipDok + cBrDok // fakt_pripr

   aMemo := fakt_ftxt_decode( field->txt )

   hFaktData[ "datdok" ]  := field->datdok
   hFaktData[ "dindem" ]  := field->dindem
   hFaktData[ "rezerv" ] := " "
   hFaktData[ "m1" ] := field->m1
   hFaktData[ "idpartner" ] := field->idpartner
   hFaktData[ "partner" ] := naziv_partnera_za_tabelu_doks( field->idpartner )
   hFaktData[ "oper_id" ] := f18_get_user_id()
   hFaktData[ "sifra" ] := Space( 6 )
   hFaktData[ "brisano" ] := Space( 1 )
   hFaktData[ "idvrstep" ] := field->idvrstep
   hFaktData[ "datpl" ] := field->datdok
   hFaktData[ "idpm" ] := field->idpm
   hFaktData[ "dat_isp" ]  := iif( Len( aMemo ) >= 7, CToD( aMemo[ 7 ] ), CToD( "" ) )
   hFaktData[ "dat_otpr" ] := iif( Len( aMemo ) >= 7, CToD( aMemo[ 7 ] ), CToD( "" ) )
   hFaktData[ "dat_val" ]  := iif( Len( aMemo ) >= 9, CToD( aMemo[ 9 ] ), CToD( "" ) )
   hFaktData[ "fisc_rn" ] := field->fisc_rn
   hFaktData[ "fisc_st" ] := 0
   hFaktData[ "fisc_date" ] := CToD( "" )
   hFaktData[ "fisc_time" ] := PadR( "", 10 )

   _fakt_totals := izracunaj_ukupni_iznos_dokumenta_iz_pripreme( cIdFirma, cIdTipDok, cBrDok )

   hFaktData[ "iznos" ] := _fakt_totals[ "iznos" ]
   hFaktData[ "rabat" ] := _fakt_totals[ "rabat" ]

   RETURN hFaktData



/*
   Opis: izračunava vrijednost dokumenta iz tabele pripreme FAKT_PRIPR za polja
           FAKT_DOKS->IZNOS
           FAKT_DOKS->RABAT

   Returns:
       hash matrica sljedećih članova
              _fakt_total["iznos"]
              _fakt_total["rabat"]
*/

FUNCTION izracunaj_ukupni_iznos_dokumenta_iz_pripreme( cIdFirma, cIdTipDok, cBrDok )

   LOCAL _fakt_total := hb_Hash()
   LOCAL _cij_sa_por := 0
   LOCAL _rabat := 0
   LOCAL _uk_sa_rab := 0
   LOCAL _uk_rabat := 0
   LOCAL _dod_por := 0
   LOCAL _din_dem

   SELECT fakt_pripr
   GO TOP
   SEEK cIdFirma + cIdTipDok + cBrDok // fakt_pripr

   _din_dem := field->dindem

   DO WHILE !Eof() .AND. field->idfirma == cIdFirma .AND. field->idtipdok == cIdTipDok .AND. field->brdok == cBrDok

      IF _din_dem == Left( ValBazna(), 3 )

         _cij_sa_por := Round( field->kolicina * field->cijena * fakt_preracun_cijene() * ( 1 - field->rabat / 100 ), fakt_zaokruzenje() )
         _rabat := Round( field->kolicina * field->cijena * fakt_preracun_cijene() * field->rabat / 100, fakt_zaokruzenje() )
         _dod_por := Round( _cij_sa_por * field->porez / 100, fakt_zaokruzenje() )

      ELSE

         _cij_sa_por := Round( field->kolicina * field->cijena * ;
            fakt_preracun_cijene() * ( 1 - field->Rabat / 100 ), fakt_zaokruzenje() )

         _rabat := Round( field->kolicina * field->cijena * ;
            fakt_preracun_cijene() * field->rabat / 100, fakt_zaokruzenje() )

         _dod_por := Round( _cij_sa_por * field->porez / 100, fakt_zaokruzenje() )

      ENDIF

      _uk_sa_rab += _cij_sa_por + _dod_por
      _uk_rabat += _rabat

      SKIP

   ENDDO

   _fakt_total[ "iznos" ] := _uk_sa_rab
   _fakt_total[ "rabat" ] := _uk_rabat

   RETURN _fakt_total


/*
   Opis: vraća dokumente iz pripreme u matricu u formatu:

        array[ cIdFirma, cIdTipDok, cBrDok ]

   Napomena: u pripremi može biti više dokumenata
*/

FUNCTION fakt_dokumenti_pripreme_u_matricu()

   LOCAL _fakt_doks := {}
   LOCAL cIdFirma
   LOCAL cIdTipDok
   LOCAL cBrDok

   SELECT fakt_pripr
   GO TOP

   DO WHILE !Eof()

      cIdFirma := field->idfirma
      cIdTipDok := field->idtipdok
      cBrDok := field->brdok

      DO WHILE !Eof() .AND. ( field->idfirma + field->idtipdok + field->brdok ) == ;
            ( cIdFirma + cIdTipDok + cBrDok )
         SKIP
      ENDDO

      IF !fakt_dokument_postoji( cIdFirma, cIdTipDok, cBrDok )
         AAdd( _fakt_doks, { cIdFirma, cIdTipDok, cBrDok } )
      ENDIF

      SELECT fakt_pripr

   ENDDO

   RETURN _fakt_doks


FUNCTION close_open_fakt_tabele( lOpenFaktAsPripr )

   my_close_all_dbf()

   IF lOpenFaktAsPripr == NIL
      lOpenFaktAsPripr := .F.
   ENDIF


   IF !lOpenFaktAsPripr
      o_fakt_pripr()
      SELECT fakt_pripr
      SET ORDER TO TAG "1"
      GO TOP
   ENDIF

   RETURN .T.




FUNCTION fakt_sredi_redni_broj_u_pripremi()

   LOCAL nTrec, hRec
   LOCAL _firma, _broj, _tdok
   LOCAL _cnt

   o_fakt_pripr()
   SET ORDER TO TAG "1"
   GO TOP

   DO WHILE !Eof()

      _firma := field->idfirma
      _tdok  := field->idtipdok
      _broj  := field->brdok
      _cnt   := 0

      DO WHILE !Eof() .AND. field->idfirma == _firma .AND. field->idtipdok == _tdok .AND. field->brdok == _broj

         SKIP 1
         nTrec := RecNo()
         SKIP -1

         hRec := dbf_get_rec()
         hRec[ "rbr" ] := PadL( AllTrim( Str( ++_cnt ) ), 3, 0 )
         dbf_update_rec( hRec )

         GO ( nTrec )

      ENDDO

   ENDDO

   RETURN 0




FUNCTION fakt_brisanje_pripreme()

   LOCAL cIdFirma, cIdTipDok, cBrDok
   LOCAL oAttr

   IF Pitanje(, D_ZELITE_LI_IZBRISATI_PRIPREMU, "N" ) == "D"

      SELECT fakt_pripr
      GO TOP

      cIdFirma := field->idfirma
      cIdTipDok := field->idtipdok
      cBrDok := field->brdok

      oAttr := DokAttr():new( "fakt", F_FAKT_ATTR )
      oAttr:hAttrId[ "idfirma" ] := cIdFirma
      oAttr:hAttrId[ "idtipdok" ] := cIdTipDok
      oAttr:hAttrId[ "brdok" ] := cBrDok

      IF gcF9usmece == "D"
         oAttr:delete_attr_from_dbf()
         azuriraj_smece( .T. )
         log_write( "F18_DOK_OPER: fakt, prenosa dokumenta iz pripreme u smece: " + cIdFirma + "-" + cIdTipDok + "-" + cBrDok, 2 )
         SELECT fakt_pripr
      ELSE
         my_dbf_zap()
         oAttr:zap_attr_dbf()
         log_write( "F18_DOK_OPER: fakt, brisanje dokumenta iz pripreme: " + cIdFirma + "-" + cIdTipDok + "-" + cBrDok, 2 )
         fakt_reset_broj_dokumenta( cIdFirma, cIdTipDok, cBrDok )
      ENDIF

   ENDIF

   RETURN .T.


FUNCTION fakt_generisi_storno_dokument( cIdFirma, cIdTipDok, cBrDok )

   LOCAL cFaktNoviBrDok
   LOCAL hRec
   LOCAL nCount
   LOCAL nFiskalniRn
   LOCAL lFiskalni := fiscal_opt_active()

   IF Pitanje( "FORM_STORNO", "Formirati storno dokument (D/N) ?", "D" ) == "N"
      RETURN .F.
   ENDIF

   o_fakt_pripr()
   SELECT fakt_pripr

   IF fakt_pripr->( RECCOUNT2() ) <> 0
      MsgBeep( "Priprema nije prazna !" )
      RETURN .F.
   ENDIF

   // o_fakt_dbf()
   // o_fakt_doks_dbf()
   // o_roba()
   // o_partner()

   cFaktNoviBrDok := AllTrim( cBrDok ) + "/S"

   IF Len( AllTrim( cFaktNoviBrDok ) ) > 8
      cFaktNoviBrDok := Right( AllTrim( cBrDok ), 6 ) + "/S"
   ENDIF

   nCount := 0

   seek_fakt_doks( cIdFirma, cIdTipDok, cBrDok )

   nFiskalniRn := 0

   IF lFiskalni
      nFiskalniRn := field->fisc_rn
   ENDIF

   seek_fakt( cIdFirma, cIdTipDok, cBrDok )
   DO WHILE !Eof() .AND. field->idfirma == cIdFirma  .AND. field->idtipdok == cIdTipDok .AND. field->brdok == cBrDok

      hRec := dbf_get_rec()

      SELECT fakt_pripr
      APPEND BLANK

      hRec[ "kolicina" ] := ( hRec[ "kolicina" ] * -1 )
      hRec[ "brdok" ] := cFaktNoviBrDok
      hRec[ "datdok" ] := Date()
      hRec[ "idvrstep" ] := ""

      IF lFiskalni
         hRec[ "fisc_rn" ] := nFiskalniRn
      ENDIF

      dbf_update_rec( hRec )
      SELECT fakt
      SKIP

      ++nCount

   ENDDO

   IF nCount > 0
      MsgBeep( "Formiran je dokument " + cIdFirma + "-" + ;
         cIdTipDok + "-" + AllTrim( cFaktNoviBrDok ) + ;
         " u pripremi !" )
   ENDIF

   RETURN .T.
