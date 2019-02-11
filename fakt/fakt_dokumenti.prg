/*
 * This file is part of the bring.out knowhow ERP, a free and open source
 * Enterprise Resource Planning software suite,
 * Copyright (c) 1994-2018 by bring.out d.o.o Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including knowhow ERP specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_knowhow.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */


#include "f18.ch"

MEMVAR GetList

CLASS FaktDokumenti

   DATA    aItems
   DATA    COUNT

   METHOD  count_markirani
   METHOD  New()
   METHOD  za_partnera( idfirma, idtipdok, idpartner )
   METHOD  pretvori_otpremnice_u_racun()
   METHOD  change_idtipdok_markirani( cIdTipDokNew )

   ASSIGN  locked   INLINE ::p_locked
   METHOD  Lock()

   PROTECTED:
   METHOD generisi_fakt_pripr_vars()
   METHOD  generisi_fakt_pripr()
   DATA  _sql_where
   DATA  p_idfirma
   DATA  p_idtipdok
   DATA  p_idpartner
   DATA  p_locked  INIT .F.
   DATA  p_lock_tables INIT { "fakt_fakt", "fakt_doks", "fakt_doks2" }

ENDCLASS


METHOD FaktDokumenti:New()

   ::aItems := {}
   ::COUNT := 0

   RETURN self


// -------------------------------------------
// lokuj - zabrani promjene drugih
// logika semafora ovo zahtjeva
// -------------------------------------------
METHOD FaktDokumenti:Lock()

   IF f18_lock_tables( ::p_lock_tables, .T. )
      ::p_locked := .T.
   ELSE
      ::p_locked := .F.
   ENDIF

   RETURN ::p_locked



METHOD FaktDokumenti:za_partnera( idfirma, idtipdok, idpartner )

   LOCAL cQuery
   LOCAL nCnt
   LOCAL _brdok
   LOCAL oQry
   LOCAL oItem

   ::p_idfirma := idfirma
   ::p_idtipdok := idtipdok
   ::p_idpartner := idpartner

   cQuery := "SELECT fakt_doks.idfirma, fakt_doks.idtipdok, fakt_doks.brdok FROM " + f18_sql_schema( "fakt_doks" ) + " "
   cQuery += "WHERE "

   ::_sql_where := "fakt_doks.idfirma=" + sql_quote( ::p_idfirma ) +  " AND fakt_doks.idtipdok=" + sql_quote( ::p_idtipdok ) + " AND fakt_doks.idpartner=" + sql_quote( ::p_idpartner )
   cQuery += ::_sql_where
   oQry := run_sql_query( cQuery )

   nCnt := 0
   DO WHILE !oQry:Eof()
      _brdok := oQry:FieldGet( 3 )
      // napunicemo aItems matricom FaktDokument objekata
      oItem := FaktDokument():New( ::p_idfirma, ::p_idtipdok, _brdok )
      oItem:refresh_info()
      AAdd( ::aItems, oItem )
      nCnt++
      oQry:skip()
   ENDDO

   ::COUNT := nCnt

   RETURN nCnt


METHOD FaktDokumenti:pretvori_otpremnice_u_racun()

   LOCAL _idfirma, _idtipdok, _idpartner
   LOCAL _suma := 0
   LOCAL _veza_otpr := ""
   LOCAL _datum_max := Date()
   LOCAL lOk
   LOCAL _lock_user := ""
   LOCAL _fakt_browse

   o_fakt_pripr()
   GO TOP

   IF RecCount2() <> 0
      MsgBeep( "FAKT priprema nije prazna" )
      RETURN .F.
   ENDIF

   _idfirma   := self_organizacija_id()
   _idtipdok  := "12"
   _idpartner := Space( 6 )
   _suma      := 0

   SET CURSOR ON

   Box(, f18_max_rows() - 7, f18_max_cols() - 10 )

   @ box_x_koord() + 1, box_y_koord() + 2 SAY "PREGLED OTPREMNICA:"
   @ box_x_koord() + 3, box_y_koord() + 2 SAY "Radna jedinica" GET  _idfirma PICT "@!"
   @ box_x_koord() + 3, Col() + 1 SAY " - " + _idtipdok + " / " PICT "@!"
   @ box_x_koord() + 3, Col() + 1 SAY "Partner ID:" GET _idpartner PICT "@!" ;
      VALID {|| p_partner( @_idpartner ),  ispisi_partn( _idpartner, box_x_koord() + f18_max_rows() - 12, box_y_koord() + 18 ) }

   READ

   @ box_x_koord() + f18_max_rows() - 12, box_y_koord() + 2 SAY "Partner:"
   @ box_x_koord() + f18_max_rows() - 10, box_y_koord() + 2 SAY "Komande: <SPACE> markiraj otpremnicu"

   ::za_partnera( _idfirma, _idtipdok, _idpartner )

   _fakt_browse := BrowseFaktDokumenti():New( box_x_koord() + 5, box_y_koord() + 1, box_x_koord() + f18_max_rows() - 13, f18_max_cols() - 11, self )
   _fakt_browse:set_kolone_markiraj_otpremnice()
   _fakt_browse:Browse()

   BoxC()

   IF ::count_markirani > 0
      IF ::change_idtipdok_markirani( "22" )
         ::generisi_fakt_pripr()
      ENDIF
   ELSE
      MsgBeep( "Nije odabrana nijedna otpremnica !" )
   ENDIF

   RETURN .T.


METHOD FaktDokumenti:generisi_fakt_pripr_vars( hParams )

   LOCAL lOk := .T.
   LOCAL _sumiraj := "N"
   LOCAL _tip_rn := 1
   LOCAL _valuta := PadR( valuta_domaca_skraceni_naziv(), 3 )

   hParams := hb_Hash()

   Box(, 6, 65 )

   @ box_x_koord() + 1, box_y_koord() + 2 SAY "Sumirati stavke otpremnica (D/N) ?" GET _sumiraj VALID _sumiraj $ "DN" PICT "@!"
   @ box_x_koord() + 3, box_y_koord() + 2 SAY "Formirati tip racuna: 1 (veleprodaja)"
   @ box_x_koord() + 4, box_y_koord() + 2 SAY "                      2 (maloprodaja)" GET _tip_rn ;
      VALID ( _tip_rn > 0 .AND. _tip_rn < 3 ) PICT "9"

   @ box_x_koord() + 6, box_y_koord() + 2 SAY "Valuta (KM/EUR):" GET _valuta VALID !Empty( _valuta ) PICT "@!"

   READ

   BoxC()

   IF LastKey() == K_ESC
      lOk := .F.
      RETURN lOk
   ENDIF

   hParams[ "tip_racuna" ] := _tip_rn
   hParams[ "sumiraj" ] := _sumiraj
   hParams[ "valuta" ] := Upper( _valuta )

   RETURN lOk



METHOD FaktDokumenti:count_markirani()

   LOCAL oItem, nCnt

   nCnt := 0
   FOR EACH oItem IN ::aItems
      IF oItem:mark
         nCnt++
      ENDIF
   NEXT

   RETURN nCnt


METHOD FaktDokumenti:change_idtipdok_markirani( cIdTipDokNew )

   LOCAL oItem, cBroj := "XX", lOk := .T.
   LOCAL hParams
   LOCAL oErr

   run_sql_query( "BEGIN; SET TRANSACTION ISOLATION LEVEL SERIALIZABLE" )

   IF !::lock
      run_sql_query( "ROLLBACK" )
      MsgBeep( "Neuspješno zaključavanje tabela, operacija " + ::p_idtipdok + "=>" + cIdTipDokNew + " otkazana !" )
      RETURN .F.
   ENDIF

   BEGIN SEQUENCE WITH {| err | err:cargo := { ProcName( 1 ), ProcName( 2 ), ProcLine( 1 ), ProcLine( 2 ) }, Break( err ) }

      FOR EACH oItem IN ::aItems
         IF oItem:mark
            cBroj := oItem:broj
            IF !oItem:change_idtipdok( cIdTipDokNew )
               run_sql_query( "ROLLBACK" )
               lOk := .F.
               BREAK
            ENDIF
         ENDIF
      NEXT

      hParams := hb_Hash()
      hParams[ "unlock" ] :=  ::p_lock_tables
      run_sql_query( "COMMIT", hParams )
      lOk := .T.

   RECOVER USING oErr

      MsgBeep( "Neuspješna konverzija " + cBroj + " idtpdok => " + cIdTipDokNew + " !##"  )
      lOk := .F.

   ENDSEQUENCE

   close_open_fakt_tabele()

   ::p_idtipdok := cIdTipDokNew

   RETURN lOk


METHOD FaktDokumenti:generisi_fakt_pripr()

   LOCAL lSumirati := .F.
   LOCAL nVPiliMPRacun := 1
   LOCAL _n_tip_dok, _dat_max, nTrec, _t_fakt_rec
   LOCAL cVezaOtpremnice, _broj_dokumenta
   LOCAL _id_partner, _rec
   LOCAL lOk := .T.
   LOCAL oItem, _msg
   LOCAL hGenParams, _valuta
   LOCAL _first
   LOCAL oQry
   LOCAL _datum_max
   LOCAL cSql
   LOCAL hFaktRec

   IF !::generisi_fakt_pripr_vars( @hGenParams ) // parametri generisanja...
      RETURN .F.
   ENDIF

   lSumirati := hGenParams[ "sumiraj" ] == "D"
   nVPiliMPRacun := hGenParams[ "tip_racuna" ]
   _valuta := hGenParams[ "valuta" ]

   IF nVPiliMPRacun == 1
      _n_tip_dok := "10"
   ELSE
      _n_tip_dok := "11"
   ENDIF

   cSql := "SELECT idroba, cijena, COALESCE(substring(txt from '\x10(.*?)\x11\x10.*?\x11' ), '') AS opis_usluga, "
   IF lSumirati
      cSql += "sum(kolicina), max(datdok), max(txt)"
   ELSE
      cSql += "kolicina, datdok, txt"
   ENDIF
   cSql += " FROM " + f18_sql_schema( "fakt_fakt" ) + " "
   cSql += " LEFT JOIN " + f18_sql_schema( "roba" ) + " "
   cSql += " ON fakt_fakt.idroba=roba.id "
   cSql += " WHERE "
   cSql += "idfirma=" + sql_quote( ::p_idfirma ) + " AND  idtipdok=" + sql_quote( ::p_idtipdok )
   cSql += " AND brdok IN ("

   cVezaOtpremnice := ""
   _first := .T.
   FOR EACH oItem IN ::aItems
      IF oItem:mark
         IF _first
            _first := .F.
         ELSE
            cSql += ","
            cVezaOtpremnice += ","
         ENDIF
         cSql += sql_quote( oItem:brdok )
         cVezaOtpremnice += Trim( oItem:brdok )
      ENDIF
   NEXT

   cSql += ")"

   IF lSumirati
      cSql += " group by idroba,cijena,opis_usluga order by idroba,cijena,opis_usluga"
   ELSE
      cSql += " order by idroba,cijena,opis_usluga"
   ENDIF

   oQry := run_sql_query( cSql )

   SELECT fakt_pripr
   hFaktRec := dbf_get_rec()

   hFaktRec[ "idfirma" ]   := ::p_idfirma
   hFaktRec[ "idpartner" ] := ::p_idpartner
   hFaktRec[ "brdok" ]     := fakt_prazan_broj_dokumenta()
   hFaktRec[ "datdok" ]    := Date()
   hFaktRec[ "idtipdok" ]  := _n_tip_dok
   hFaktRec[ "dindem" ]    := Left( _valuta, 3 )
   _datum_max := Date()

   DO WHILE !oQry:Eof()

      hFaktRec[ "idroba" ]   :=  _to_str( oQry:FieldGet( 1 ) )
      hFaktRec[ "cijena" ]   := oQry:FieldGet( 2 )
      // ovo polje ipak ne trebamo
      // _opis_usluga := oQry:FieldGet(3)
      hFaktRec[ "kolicina" ] := oQry:FieldGet( 4 )
      hFaktRec[ "datdok" ]   := oQry:FieldGet( 5 )
      hFaktRec[ "txt" ]      := _to_str( oQry:FieldGet( 6 ) )

      IF hFaktRec[ "datdok" ] > _datum_max
         _datum_max := hFaktRec[ "datdok" ]
      ENDIF

      IF nVPiliMPRacun == 2
         // radi se o mp racunu, izracunaj cijenu sa pdv
         hFaktRec[ "cijena" ] := Round( _uk_sa_pdv( ::p_idtipdok, ::p_idpartner, hFaktRec[ "cijena" ] ), 2 )
      ENDIF

      APPEND BLANK
      dbf_update_rec( hFaktRec )

      oQry:skip()

   ENDDO

   cVezaOtpremnice := "Račun formiran na osnovu otpremnica: " + cVezaOtpremnice
   renumeracija_fakt_pripr( cVezaOtpremnice, _datum_max )

   RETURN lOk



/* renumeracija_fakt_pripr(cVezOtpr,dNajnoviji)
  *
  *   param: cVezOtpr
  *   param: dNajnoviji - datum posljednje radjene otpremnice

  // poziva se samo pri generaciji otpremnica u fakturu
*/


FUNCTION renumeracija_fakt_pripr( cVezaOtpremnica, dDatumPosljednjeOtpr )

   LOCAL hFaktTxt
   LOCAL dDatDok
   LOCAL aMemo
   LOCAL lSetujDatum := .F.
   LOCAL GetList := {}
   LOCAL nRokPl := 0
   LOCAL nRbr, nTRec

   PRIVATE cSetPor := "N"

   SELECT fakt_pripr
   SET ORDER TO TAG "1"
   GO TOP

   IF RecCount2 () == 0
      RETURN .F.
   ENDIF

   nRbr := 999
   GO BOTTOM

   my_flock()

   DO WHILE !Bof()
      REPLACE rbr WITH Str( --nRbr, 3 )
      SKIP -1
   ENDDO

   nRbr := 0
   DO WHILE !Eof()
      SKIP
      nTrec := RecNo()
      SKIP -1
      IF Empty( fakt_pripr->podbr )
         REPLACE rbr WITH Str( ++nRbr, 3, 0 )
      ELSE
         IF nRbr == 0
            nRbr := 1
         ENDIF
         REPLACE rbr WITH Str( nRbr, 3, 0 )
      ENDIF
      GO nTrec
   ENDDO

   my_unlock()

   GO TOP

   Scatter()

   IF cVezaOtpremnica == nil
      cVezaOtpremnica := ""
   ENDIF

   hFaktTxt := fakt_ftxt_decode_string( _txt )

   nRbr := 1

   Box( "#PARAMETRI DOKUMENTA:", 10, 75 )

   IF gDodPar == "1"
      @  box_x_koord() + 1, box_y_koord() + 2 SAY8 "Otpremnica broj:" GET hFaktTxt[ "brotp" ]
      @  box_x_koord() + 2, box_y_koord() + 2 SAY8 "          datum:" GET hFaktTxt[ "datotp" ]
      @  box_x_koord() + 3, box_y_koord() + 2 SAY8 "Ugovor/narudžba:" GET hFaktTxt[ "brnar" ]
      @  box_x_koord() + 4, box_y_koord() + 2 SAY8 "    Destinacija:" GET hFaktTxt[ "destinacija" ] PICT "@S45"
      @  box_x_koord() + 5, box_y_koord() + 2 SAY8 "Vezni dokumenti:" GET hFaktTxt[ "dokument_veza" ] PICT "@S45"
   ENDIF

   IF gDodPar == "1" .OR. gDatVal == "D"

      nRokPl := fakt_rok_placanja_dana()
      @  box_x_koord() + 6, box_y_koord() + 2 SAY "Datum fakture  :" GET _DatDok

      IF dDatumPosljednjeOtpr <> NIL
         @  box_x_koord() + 6, box_y_koord() + 35 SAY "Datum posljednje otpremnice:" GET dDatumPosljednjeOtpr WHEN .F. COLOR "GR+/B"
      ENDIF

      @ box_x_koord() + 7, box_y_koord() + 2 SAY8 "Rok plać.(dana):" GET nRokPl PICT "999" WHEN valid_rok_placanja( @nRokPl, @_datdok, @hFaktTxt[ "datpl" ], "0", .T. ) ;
         VALID valid_rok_placanja( nRokPl, @_datdok, @hFaktTxt[ "datpl" ], "1", .T. )
      @ box_x_koord() + 8, box_y_koord() + 2 SAY8 "Datum plaćanja :" GET hFaktTxt[ "datpl" ] VALID valid_rok_placanja( nRokPl, @_datdok, @hFaktTxt[ "datpl" ], "2", .T. )

      READ
   ENDIF

   READ

   BoxC()

   dDatDok := _datdok

   fakt_ftxt_sub_renumeracija_pripreme( @hFaktTxt[ "txt2" ] )

   IF !Empty( cVezaOtpremnica )
      IF !( "Veza otpremnice:" $ hFaktTxt[ "txt2" ] )
         hFaktTxt[ "txt2" ] += NRED_DOS + "Veza otpremnice: " + cVezaOtpremnica
      ENDIF
   ENDIF

   _txt := fakt_ftxt_encode_5( hFaktTxt )

   IF datDok <> dDatDok
      lSetujDatum := .T.
   ENDIF

   my_rlock()
   Gather()
   my_unlock()

   RETURN .T.
