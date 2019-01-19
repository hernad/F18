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




// -----------------------------------------------------------------------
// setuje u parametrima robu koja ce se pojavljivati na izvjestajima
// -----------------------------------------------------------------------
STATIC FUNCTION set_articles()

   LOCAL _x := 1
   LOCAL _count := 40
   LOCAL _tmp, nI
   LOCAL _ok := .T.
   LOCAL _art_1, _art_2, _art_3, _art_4, _art_5, _art_6, _art_7, _art_8, _art_9, _art_10
   LOCAL _art_11, _art_12, _art_13, _art_14, _art_15, _art_16, _art_17, _art_18, _art_19, _art_20
   LOCAL _art_21, _art_22, _art_23, _art_24, _art_25, _art_26, _art_27, _art_28, _art_29, _art_30
   LOCAL _art_31, _art_32, _art_33, _art_34, _art_35, _art_36, _art_37, _art_38, _art_39, _art_40
   LOCAL _var, _valid_block

   // procitaj paramtre iz sql/db
   FOR nI := 1 TO _count
      _var := "_art_" + AllTrim( Str( nI ) )
      &_var := PadR( fetch_metric( "fakt_pregled_prodaje_rpt_artikal_" + PadL( AllTrim( Str( nI ) ), 2, "0" ), NIL, Space( 10 ) ), 10 )
   NEXT

   Box(, ( _count / 2 ) + 3, 65 )

   @ box_x_koord() + _x, box_y_koord() + 2 SAY "Izvjestaj se pravi za sljedece artikle:"

   ++_x
   ++_x

   nI := 1

   // prikaz u 2 reda
   FOR nI := 1 TO _count

      _var := "_art_" + AllTrim( Str( nI ) )
      _valid_block := "EMPTY(_art_" + AllTrim( Str( nI ) ) + ") .or. P_Roba(@_art_" + AllTrim( Str( nI ) ) + ")"

      IF nI % 2 == 0
         @ box_x_koord() + _x, Col() + 2 SAY "Artikal " +  PadL( AllTrim( Str( nI ) ), 2 ) + ":" GET &_var VALID &_valid_block
         ++_x
      ELSE
         @ box_x_koord() + _x, box_y_koord() + 2 SAY "Artikal " +  PadL( AllTrim( Str( nI ) ), 2 ) + ":" GET &_var VALID &_valid_block
      ENDIF

   NEXT

   READ

   BoxC()

   // snimi parametre
   IF LastKey() != K_ESC
      // snimi parametre
      nI := 1
      FOR nI := 1 TO _count
         _var := "_art_" + AllTrim( Str( nI ) )
         set_metric( "fakt_pregled_prodaje_rpt_artikal_" + PadL( AllTrim( Str( nI ) ), 2, "0" ), NIL, AllTrim( &_var ) )
      NEXT
   ENDIF

   RETURN _ok




// --------------------------------------------
// vraca matricu sa robom i definicijom polja
// praznu
// --------------------------------------------
STATIC FUNCTION _g_ini_roba()

   LOCAL _arr := {}
   LOCAL nI
   LOCAL _param_count := 40
   LOCAL _item
   LOCAL _count := 0

   FOR nI := 1 TO _param_count

      // item uzimam iz sql/db
      _item := fetch_metric( "fakt_pregled_prodaje_rpt_artikal_" + PadL( AllTrim( Str( nI ) ), 2, "0" ), NIL, "" )

      IF !Empty( _item )
         ++_count
         AAdd( _arr, { _item, "ROBA" + AllTrim( Str( _count ) ), 0 } )
      ENDIF

   NEXT

   RETURN _arr



// --------------------------------------------------
// vraca matricu sa definicijom polja exp.tabele
// aRoba = [ field_naz, sifra_robe, opis_robe   ]
// --------------------------------------------------
STATIC FUNCTION _g_exp_fields( article_arr )

   LOCAL aFields := {}
   LOCAL nI

   AAdd( aFields, { "rbr", "C", 10, 0 } )
   AAdd( aFields, { "distrib", "C", 60, 0 } )
   AAdd( aFields, { "pm_idbroj", "C", 13, 0 } )
   AAdd( aFields, { "pm_naz", "C", 100, 0 } )
   AAdd( aFields, { "pm_tip", "C", 20, 0 } )
   AAdd( aFields, { "pm_mjesto", "C", 20, 0 } )
   AAdd( aFields, { "pm_ptt", "C", 10, 0 } )
   AAdd( aFields, { "pm_adresa", "C", 60, 0 } )
   AAdd( aFields, { "pm_kt_br", "C", 20, 0 } )

   FOR nI := 1 TO Len( article_arr )
      AAdd( aFields, { article_arr[ nI, 2 ], "N", 15, 5 } )
   NEXT

   AAdd( aFields, { "ukupno", "N", 15, 5 } )

   RETURN aFields


// -------------------------------------------
// filuje export tabelu sa podacima
// -------------------------------------------
STATIC FUNCTION fill_exp_tbl( cRbr, cDistrib, cPmId, cPmNaz, ;
      cPmTip, cPmMj, cPmPtt, cPmAdr, cPmKtBr, aRoba )

   LOCAL nDbfArea
   LOCAL nI
   LOCAL _total := 0

   nDbfArea := Select()

   o_r_export()
   APPEND BLANK
   REPLACE field->rbr WITH cRbr
   REPLACE field->distrib WITH cDistrib
   REPLACE field->pm_idbroj WITH cPmId
   REPLACE field->pm_naz WITH cPmNaz
   REPLACE field->pm_tip WITH cPmTip
   REPLACE field->pm_mjesto WITH cPmMj
   REPLACE field->pm_ptt WITH cPmPtt
   REPLACE field->pm_adresa WITH cPmAdr
   REPLACE field->pm_kt_br WITH cPmKtBr

   // dodaj za robu...
   FOR nI := 1 TO Len( aRoba )
      REPLACE field->&( aRoba[ nI, 2 ] ) WITH aRoba[ nI, 3 ]
      _total += aRoba[ nI, 3 ]
   NEXT

   REPLACE field->ukupno WITH _total

   SELECT ( nDbfArea )

   RETURN



// ---------------------------------------
// specifikacija prodaje
// ---------------------------------------
FUNCTION fakt_kol_pregled_isporuke_robe_partneri()

   LOCAL _x := 1
   LOCAL _define := "N"
   LOCAL aRoba
   LOCAL cPartner
   LOCAL cRoba
   LOCAL cIdFirma
   LOCAL dDatod
   LOCAL dDatDo
   LOCAL cFilter
   LOCAL cDistrib

   _o_tables()

   cIdfirma := self_organizacija_id()
   dDatOd := CToD( "" )
   dDatDo := Date()
   cDistrib := PadR( "10", 6 )

   Box( "#SPECIFIKACIJA PRODAJE PO PARTNERIMA", 12, 77 )

   cIdFirma := PadR( cIdFirma, 2 )

   @ box_x_koord() + _x, box_y_koord() + 2 SAY "RJ            " GET cIdFirma ;
      VALID {|| Empty( cIdFirma ) .OR. ;
      cIdFirma == self_organizacija_id() .OR. P_RJ( @cIdFirma ), cIdFirma := Left( cIdFirma, 2 ), .T. }

   ++_x
   @ box_x_koord() + _x, box_y_koord() + 2 SAY "Od datuma " GET dDatOd
   @ box_x_koord() + _x, Col() + 1 SAY "do" GET dDatDo

   ++_x
   @ box_x_koord() + _x, box_y_koord() + 2 SAY "Distributer   " GET cDistrib VALID p_partner( @cDistrib )

   ++_x
   ++_x
   @ box_x_koord() + _x, box_y_koord() + 2 SAY "Definisi artikle za izvjestaj (D/N) ?" GET _define VALID _define $ "DN" PICT "@!"

   READ

   ESC_BCR

   BoxC()

   // definisi artikle koji ce se naci na izvjestaju...
   IF _define == "D"
      set_articles()
   ENDIF

   // inicijalizuj matricu "aRoba"
   aRoba := _g_ini_roba()

   IF Len( aRoba ) = 0
      MsgBeep( "Potrebno definisati artikle za izvjestaj !!!" )
      RETURN
   ENDIF

   aExpFields := _g_exp_fields( aRoba )
   IF !create_dbf_r_export( aExpFields )
      RETURN .F.
   ENDIF

   _o_tables()

   select_o_partner( cDistrib )
   cDistNaz := field->naz



   find_fakt_za_period( cIdFirma, dDatOd, dDatDo, NIL, NIL, "6" ) // idfirma + idpartner + idroba + idtipdok + dtos(datum)

   // postavi filter
   cFilter := "idtipdok == '10' "

   IF ( !Empty( dDatOd ) .OR. !Empty( dDatDo ) )
      cFilter += ".and.  datdok>=" + dbf_quote( dDatOd ) + " .and. datdok<=" + dbf_quote( dDatDo )
   ENDIF

   IF ( !Empty( cIdFirma ) )
      cFilter += " .and. IdFirma=" + dbf_quote( cIdFirma )
   ENDIF

   // postavi filter
   SET FILTER TO &cFilter

   SELECT fakt
   GO TOP

   nCount := 0

   Box( , 2, 50 )

   @ box_x_koord() + 1, box_y_koord() + 2 SAY "generisem podatke za xls...."

   DO WHILE !Eof() .AND. field->idfirma == cIdFirma

      // resetuj aroba matricu
      _reset_aroba( @aRoba )

      cPartner := field->idpartner

      lUbaci := .F.

      // idi za jednog partnera
      DO WHILE !Eof() .AND. field->idfirma == cIdFirma ;
            .AND. field->idpartner == cPartner

         cRoba := field->idroba
         nKol := field->kolicina

         nScan := AScan( aRoba, {| xvar | xvar[ 1 ] == AllTrim( cRoba )  } )

         // ubaci u matricu...
         IF nScan <> 0

            lUbaci := .T.

            aRoba[ nScan, 3 ] := aRoba[ nScan, 3 ] + nKol

            @ box_x_koord() + 2, box_y_koord() + 2 SAY "  scan: " + cRoba

         ENDIF

         SKIP

      ENDDO

      IF lUbaci == .T.

         select_o_partner( cPartner )
         SELECT fakt

         fill_exp_tbl( ;
            AllTrim( Str( ++nCount ) ), cDistNaz, firma_pdv_broj( cPartner ), partn->naz, ;
            get_partn_sifk_sifv( "TIP", cPartner, .F. ), ;
            partn->mjesto, ;
            partn->ptt, ;
            partn->adresa, ;
            _k_br( cPartner ), aRoba )

      ENDIF

   ENDDO

   BoxC()

   open_r_export_table()

   RETURN .T.

// ----------------------------------------
// vraca broj kuce partnera
// djemala bijedica "22" <-----
// ----------------------------------------
STATIC FUNCTION _k_br( partner_id )

   LOCAL _tmp := "bb"
   LOCAL _ret := ""

   _ret := get_partn_sifk_sifv( "KBR", partner_id, .F. )

   IF Empty( _ret )
      _ret := _tmp
   ENDIF

   RETURN _ret



// -----------------------------------------------
// resetuj vrijednosti u aRoba matrici
// -----------------------------------------------
STATIC FUNCTION _reset_aroba( arr )

   LOCAL nI

   FOR nI := 1 TO Len( arr )
      arr[ nI, 3 ] := 0
   NEXT

   RETURN .T.


STATIC FUNCTION _o_tables()

   //o_fakt_dbf()
   //o_partner()
   //o_valute()
   //o_rj()
   //o_sifk()
   //o_sifv()
   //o_roba()
   //o_ops()

   RETURN .T.
