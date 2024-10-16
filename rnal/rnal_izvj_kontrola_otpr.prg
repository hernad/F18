/*
 * This file is part of the bring.out FMK, a free and open source
 * accounting software suite,
 * Copyright (c) 1996-2011 by bring.out doo Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including FMK specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_FMK.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */

#include "f18.ch"

// -----------------------------------------------------
// provjera podataka, sta je prebaceno od otpremnica
// -----------------------------------------------------
FUNCTION m_rpt_check()

   LOCAL dD_from
   LOCAL dD_to
   LOCAL nOper
   LOCAL cStatus
   LOCAL nVar := 0
   LOCAL _export
   LOCAL _rpt_file := my_home() + "_tmp1.dbf"

#ifdef __PLATFORM__WINDOWS

   _rpt_file := '"' + _rpt_file + '"'
#endif

   // uslovi izvjestaja
   IF std_vars( @dD_from, @dD_to, @nOper, @cStatus, @_export ) = 0
      RETURN
   ENDIF

   IF Pitanje(, "Prikazati samo naloge koji nisu prebaceni ? (D/N)", "D" ) == "D"
      nVar := 1
   ENDIF

   // napravi report
   _cre_report( dD_from, dD_to, nOper, cStatus )

   IF _export == "N"
      // rpt
      _gen_rpt( dD_from, dD_to, nOper, nVar )
   ELSE
      // lansiraj dbf...
      f18_run( _rpt_file )
   ENDIF

   RETURN .T.



// ------------------------------------------------------
// stampa izvjestaja
// ------------------------------------------------------
STATIC FUNCTION _gen_rpt( dD_from, dD_to, nOper, nVar )

   LOCAL cLine

   START PRINT CRET

   ?

   P_COND

   _rpt_head( @cLine, dD_from, dD_to )

   SELECT _tmp1
   GO TOP

   DO WHILE !Eof()

      // samo prikazi one koji nisu prebaceni
      IF nVar = 1
         IF AllTrim( field->fakt_d1 ) + ;
               AllTrim( field->pos_d1 ) <> "??"

            // preskoci ovaj zapis
            SKIP
            LOOP

         ENDIF
      ENDIF

      ? field->doc_no
      @ PRow(), PCol() + 1 SAY PadR( field->customer, 30 )
      @ PRow(), PCol() + 1 SAY field->doc_date
      @ PRow(), PCol() + 1 SAY field->dvr_date
      @ PRow(), PCol() + 1 SAY field->fakt_d1
      // @ prow(), pcol()+1 SAY field->fakt_d2

      SKIP

   ENDDO

   ? cLine

   my_close_all_dbf()

   FF
   ENDPRINT

   RETURN


// -------------------------------------------------
// header izvjestaja
// -------------------------------------------------
STATIC FUNCTION _rpt_head( cLine, dD_from, dD_to )

   LOCAL cTxt

   ? "------------------------------"
   ? "Dokumenti koji nisu obradjeni:"
   ? "------------------------------"
   ? "Datum od " + DToC( dD_from ) + " do " + DToC( dD_to )

   cLine := Replicate( "-", 10 )
   cLine += Space( 1 )
   cLine += Replicate( "-", 30 )
   cLine += Space( 1 )
   cLine += Replicate( "-", 8 )
   cLine += Space( 1 )
   cLine += Replicate( "-", 8 )
   cLine += Space( 1 )
   cLine += Replicate( "-", 10 )

   cTxt := PadR( "Broj nal.", 10 )
   cTxt += Space( 1 )
   cTxt += PadR( "Kupac", 30 )
   cTxt += Space( 1 )
   cTxt += PadR( "Datum", 8 )
   cTxt += Space( 1 )
   cTxt += PadR( "Ispor.", 8 )
   cTxt += Space( 1 )
   cTxt += PadR( "FAKT", 10 )

   ? cLine
   ? cTxt
   ? cLine

   RETURN




// --------------------------------------------------------------
// provjeri linkove sa maloprodajnim racunima
// --------------------------------------------------------------
FUNCTION chk_dok_11()

   LOCAL dD_from := danasnji_datum()
   LOCAL dD_to := dD_from
   LOCAL aMemo
   LOCAL cMemo
   LOCAL aTmp
   LOCAL i
   LOCAL nNalog
   LOCAL cFaktDok
   LOCAL cReset := "N"

   PRIVATE GetList := {}

   Box(, 2, 60 )

   @ box_x_koord() + 1, box_y_koord() + 2 SAY "za datum od" GET dD_from
   @ box_x_koord() + 1, Col() + 1 SAY "do" GET dD_to

   @ box_x_koord() + 2, box_y_koord() + 2 SAY "resetuj broj veze u RNAL (D/N)?" ;
      GET cReset VALID cReset $ "DN" PICT "@!"

   READ
   BoxC()

   IF LastKey() == K_ESC
      RETURN
   ENDIF

   // otvori fakt doks
   //o_fakt_doks_dbf()

   // otvori potrebne tabele
   rnal_o_tables( .F. )

   SELECT fakt_doks
   GO TOP

   MsgO( "Popunjavam veze ..." )

   DO WHILE !Eof()

      // gledaj samo mp racune
      IF ( field->idtipdok <> "11" ) .OR. ( AllTrim( field->rbr ) <> "1" )
         SKIP
         LOOP
      ENDIF

      // provjeri datum faktura
      IF ( field->datdok > dD_to ) .OR. ( field->datdok < dD_from )
         SKIP
         LOOP
      ENDIF

      cFaktDok := AllTrim( field->brdok )

      // uzmi memo polje
      aMemo := fakt_ftxt_decode( field->txt )

      IF Len( aMemo ) > 18
         // ovo je polje koje sadrzi brojeve veza...
         cMemo := aMemo[ 19 ]
      ELSE
         cMemo := ""
      ENDIF

      IF !Empty( cMemo )

         // ubaci u matricu...
         aTmp := TokToNiz( cMemo, ";" )

         // obradi svaki pojedinacni nalog
         FOR i := 1 TO Len( aTmp )

            // evo broj naloga
            nNalog := Val( AllTrim( aTmp[ i ] ) )

            // prekontrolisi ga sada u rnal-u
            SELECT docs
            GO TOP
            SEEK docno_str( nNalog )

            _rec := dbf_get_rec()

            IF Found()

               IF cReset == "D"
                  // resetuj polje fmk_doc prije svega
                  _rec[ "fmk_doc" ] := ""
               ENDIF

               _rec[ "fmk_doc" ] := _add_to_field( ;
                  AllTrim( field->fmk_doc ), ;
                  cFaktDok + "M" )

               update_rec_server_and_dbf( "fakt_doks", _rec, 1, "FULL" )

            ENDIF

         NEXT

      ENDIF

      SELECT fakt_doks
      SKIP
   ENDDO

   MsgC()

   // prekini vezu sa doks
   SELECT ( F_FAKT_DOKS )
   USE

   RETURN



// ---------------------------------------------------------------
// glavna funkcija za kreiranje pomocne tabele
// ---------------------------------------------------------------
STATIC FUNCTION _cre_report( dD_f, dD_t, nOper, cStatus )

   LOCAL aField
   LOCAL cValue := ""
   LOCAL aValue := {}
   LOCAL nDoc_no
   LOCAL aFmk
   LOCAL cSep := ";"
   LOCAL i
   LOCAL cFFirma := "10"
   LOCAL cFTipDok := "12"
   LOCAL cPFirma := ""
   LOCAL cPTipDok := ""

   // kreiraj tmp tabelu
   aField := _rpt_fields()

   cre_tmp1( aField )
   o_tmp1()
   INDEX ON Str( doc_no, 10 ) TAG "1"

   //o_fakt_dbf()

   // otvori potrebne tabele
   rnal_o_tables( .F. )

   _main_filter( dD_f, dD_t, nOper, cStatus )

   Box(, 1, 50 )

   DO WHILE !Eof()

      // uzmi podatke dokumenta da vidis treba li da se generise
      // u izvjestaj ?

      nDoc_no := field->doc_no

      @ box_x_koord() + 1, box_y_koord() + 2 SAY "obradjujem nalog: " + AllTrim( Str( nDoc_no ) )

      dDoc_date := field->doc_date
      dDvr_date := field->doc_dvr_da
      nCust := field->cust_id
      nCont := field->cont_id
      cCustomer := AllTrim( g_cust_desc( nCust ) )
      cCustomer += "/" + AllTrim( g_cont_desc( nCont ) )
      cFmk_doc := AllTrim( field->fmk_doc )

      // idi dalje
      IF !Empty( cFmk_doc )
         SKIP
         LOOP
      ENDIF

      // da li ga ima u FAKT-u ?

      cDokument := AllTrim( Str( nDoc_no ) ) + ";"
      cF_doc1 := "?"
      cF_doc2 := "?"
      cP_doc1 := "?"

      //SELECT fakt
      //SEEK cFFirma + cFTipDok
      seek_fakt( cFFirma, cFTipDok )

      // resetuj memo vrijednost
      aMemo := {}

      DO WHILE !Eof() .AND. field->idfirma + field->idtipdok == cFFirma + cFTipDok

         // gledaj samo redni broj jedan fakture
         IF AllTrim( field->rbr ) <> "1"
            SKIP
            LOOP
         ENDIF

         // uzmi memo polje
         aMemo := fakt_ftxt_decode( field->txt )

         IF Len( aMemo ) >= 19
            cMemo := aMemo[ 19 ]
         ELSE
            cMemo := ""
         ENDIF

         // tu je !
         IF cDokument $ cMemo
            cF_doc1 := field->brdok
            EXIT
         ENDIF

         SKIP
      ENDDO

      app_to_tmp1( nDoc_no, cCustomer, dDoc_date, dDvr_date, ;
         cF_doc1, cF_doc2, cP_doc1 )

      // idemo dalje...
      SELECT docs
      SKIP

   ENDDO

   BoxC()

   SELECT _tmp1
   USE

   RETURN


// -------------------------------------------------
// dodaj u pomocnu tabelu
// -------------------------------------------------
STATIC FUNCTION app_to_tmp1( nDoc_no, cCustomer, dDate, dDel_date, ;
      cFakt_dok1, cFakt_dok2, cPos_dok1 )

   LOCAL nTArea := Select()

   SELECT _tmp1
   GO TOP
   SEEK docno_str( nDoc_no )

   IF !Found()
      APPEND BLANK
      REPLACE field->doc_no WITH nDoc_no
   ENDIF

   RREPLACE field->customer WITH cCustomer, field->doc_date WITH dDate, field->dvr_date WITH dDel_date, field->fakt_d1 WITH cFakt_dok1, field->fakt_d2 WITH cFakt_dok2, field->pos_d1 WITH cPos_dok1

   SELECT ( nTArea )

   RETURN



// -----------------------------------------
// polja tabele izvjestaja
// -----------------------------------------
STATIC FUNCTION _rpt_fields()

   LOCAL aRet := {}

   AAdd( aRet, { "doc_no", "N", 10, 0 } )
   AAdd( aRet, { "customer", "C", 50, 0 } )
   AAdd( aRet, { "doc_date", "D", 8, 0 } )
   AAdd( aRet, { "dvr_date", "D", 8, 0 } )
   AAdd( aRet, { "fakt_d1", "C", 10, 0 } )
   AAdd( aRet, { "fakt_d2", "C", 10, 0 } )
   AAdd( aRet, { "pos_d1", "C", 10, 0 } )

   RETURN aRet


// -------------------------------------------------
// filter
// -------------------------------------------------
STATIC FUNCTION _main_filter( dDFrom, dDTo, nOper, cStatus )

   LOCAL cFilter := ""

   SELECT docs

   cFilter += "(doc_status == 0 .or. doc_status > 2)"
   cFilter += " .and. DTOS(doc_date) >= " + dbf_quote( DToS( dDFrom ) )
   cFilter += " .and. DTOS(doc_date) <= " + dbf_quote( DToS( dDTo ) )

   IF nOper <> 0
      cFilter += ".and. operater_i = " + Str( nOper, 10 )
   ENDIF

   SET FILTER to &cFilter
   GO TOP

   RETURN
