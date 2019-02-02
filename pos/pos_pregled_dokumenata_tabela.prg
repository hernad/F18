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

STATIC cIdPos
STATIC cIdVd
STATIC cBrDok
STATIC dDatum
STATIC cIdRadnik


FUNCTION pos_lista_azuriranih_dokumenata()

   LOCAL aOpc
   LOCAL GetList := {}

   // LOCAL _prikaz_partnera := .F.
   PRIVATE cFilter := ".t."
   PRIVATE ImeKol := {}
   PRIVATE Kol := {}

   cIdVd := "  "
   dDatOd := Date() - 1
   dDatDo := Date()

   Box(, 3, 60 )
   @ box_x_koord() + 1, box_y_koord() + 2 SAY "Datumski period:" GET dDatOd
   @ box_x_koord() + 1, Col() + 2 SAY "-" GET dDatDo
   @ box_x_koord() + 3, box_y_koord() + 2 SAY "Vrste (prazno-svi)" GET cIdVd PICT "@!"
   READ
   BoxC()

   IF LastKey() == K_ESC
      RETURN .F.
   ENDIF

   // _o_pos_prepis_tbl()

   AAdd( ImeKol, { "Vrsta", {|| IdVd } } )
   AAdd( ImeKol, { "Broj ", {|| PadR( IF( !Empty( IdPos ), Trim( IdPos ) + "-", "" ) + AllTrim( BrDok ), 9 ) } } )
   AAdd( ImeKol, { "Fisk.rn", {|| fisc_rn } } )

   // IF _prikaz_partnera
   // SELECT pos_doks
   // SET RELATION TO idPartner INTO partn
   // AAdd( ImeKol, { PadR( "Partner", 25 ), {|| PadR( Trim( idPartner ) + "-" + Trim( partn->naz ), 25 ) } } )
   // ENDIF

   AAdd( ImeKol, { "VP", {|| IdVrsteP } } )
   AAdd( ImeKol, { "Datum", {|| datum } } )

   AAdd( ImeKol, { "Smj", {|| smjena } } )

   AAdd( ImeKol, { PadC( "Iznos", 10 ), {|| pos_iznos_dokumenta( NIL ) } } )
   AAdd( ImeKol, { "Radnik", {|| IdRadnik } } )


   FOR i := 1 TO Len( ImeKol )
      AAdd( Kol, i )
   NEXT


   seek_pos_doks_za_period( NIL, cIdVd, dDatOd, dDatDo )
   SET CURSOR ON

   // IF !Empty( dDatOd ) .OR. !Empty( dDatDo )
   // cFilter += ".and. Datum>=" + dbf_quote( dDatOD ) + ".and. Datum<=" + dbf_quote( dDatDo )
   // ENDIF
   // IF !Empty( cIdVd )
   // cFilter += ".and. IdVd=" + dbf_quote( cIdVd )
   // ENDIF
// IF !( cFilter == ".t." )
// SET FILTER TO &cFilter
// ENDIF

// GO TOP

   aOpc := { "<ENTER> Odabir", "<E> eksport" }

   IF pos_upravnik() .OR. pos_admin()
      AAdd( aOpc, "<F2> - promjena vrste placanja" )
   ENDIF


   my_browse( "pos_doks", f18_max_rows() - 10, f18_max_cols() - 15, ;  // params cImeBoxa, xw, yw
      {|| pos_stampa_dokumenta_key_handler( dDatOd, dDatDo ) }, _u( "  ŠTAMPA AŽURIRANOG DOKUMENTA  " ), "POS", ; // bUserF, cMessTop, cMessBot
      .F., aOpc ) // lInvert, aMessage

   CLOSE ALL

   RETURN .T.



FUNCTION pos_stampa_dokumenta_key_handler( dDatum0, dDatum1 )

   LOCAL cLevel
   LOCAL cOdg
   LOCAL nRecNo
   LOCAL ctIdPos
   LOCAL dtDatum
   LOCAL hRec, _id_pos, _id_vd, _dat_dok, _br_dok
   LOCAL nDbfArea := Select()
   LOCAL _tbl_filter := dbFilter()
   LOCAL _rec_no, _ok
   LOCAL _tbl_pos := "pos_pos"
   LOCAL _tbl_doks := "pos_doks"
   LOCAL hParams := hb_Hash()

   IF Ch == 0
      RETURN ( DE_CONT )
   ENDIF

   IF LastKey() == K_ESC
      RETURN ( DE_ABORT )
   ENDIF

   _rec_no := RecNo()

   DO CASE

   CASE Ch == K_F2 .AND. ( pos_admin() .OR. pos_upravnik() )

      IF Pitanje(, "Želite li promijeniti vrstu plaćanja (D/N) ?", "N" ) == "D"

         cVrPl := field->idvrstep

         IF !VarEdit( { { "Nova vrsta placanja", "cVrPl", "Empty (cVrPl).or.P_VrsteP(@cVrPl)", "@!", } }, 10, 5, 14, 74, 'PROMJENA VRSTE PLACANJA, DOKUMENT:' + idvd + "/" + idpos + "-" + brdok + " OD " + DToC( datum ), "B1" )
            RETURN DE_CONT
         ENDIF

         hRec := dbf_get_rec()
         hRec[ "idvrstep" ] := cVrPl

         update_rec_server_and_dbf( "pos_doks", hRec, 1, "FULL" )

         RETURN DE_REFRESH

      ENDIF

      RETURN DE_CONT


   CASE Ch == k_ctrl_f9()

      _id_pos := field->idpos
      _id_vd := field->idvd
      _br_dok := field->brdok
      _dat_dok := field->datum

      _rec_no := RecNo()

      IF Pitanje(, "Želite li zaista izbrisati dokument (D/N) ?", "N" ) == "D"

         pos_brisi_dokument( _id_pos, _id_vd, _dat_dok, _br_dok )
         _o_pos_prepis_tbl()
         SELECT ( nDbfArea )
         SET FILTER TO &_tbl_filter
         GO ( _rec_no )

         RETURN DE_REFRESH

      ENDIF

      RETURN DE_CONT

   CASE Ch == K_ENTER

      DO CASE

      CASE pos_doks->IdVd == POS_VD_RACUN


/*
         cOdg := "D"
         IF glRetroakt
            cOdg := Pitanje(, "Štampati tekući račun? (D-da,N-ne,S-sve račune u izabranom periodu)", "D", "DNS" )
         ENDIF

         IF cOdg == "S"

            ctIdPos := gIdPos
            SEEK ctIdPos + POS_VD_RACUN

            START PRINT CRET

            DO WHILE !Eof() .AND. IdPos + IdVd == ctIdPos + POS_VD_RACUN
               IF ( datum <= dDatum1 )
                  pos_racun_stampa_priprema( IdPos, DToS( datum ) + BrDok, .F., glRetroakt )
               ENDIF
               SELECT pos_doks
               SKIP 1
            ENDDO

            ENDPRINT
*/
         // ELSEIF cOdg == "D"

         hParams[ "idpos" ] := pos_doks->idpos
         hParams[ "datum" ] := pos_doks->datum
         hParams[ "brdok" ] := pos_doks->brdok
         hParams[ "napuni_dbf" ] := .F.
         pos_racun_stampa_priprema( hParams )
         // ENDIF

      CASE pos_doks->IdVd == "16"
         pos_stampa_azuriranog_zaduzenja( "ZADUŽENJE" )

      CASE pos_doks->IdVd == POS_VD_OTPIS
         pos_stampa_azuriranog_zaduzenja( "OTPIS" )

      CASE pos_doks->IdVd == POS_VD_REKLAMACIJA
         pos_stampa_azuriranog_zaduzenja( "REKLAMACIJA" )


      CASE pos_doks->IdVd == "IN"
         pos_prepis_inventura_nivelacija( .T. )

      CASE pos_doks->IdVd == POS_VD_NIV
         pos_prepis_inventura_nivelacija( .F. )
         RETURN ( DE_REFRESH )

      CASE pos_doks->IdVd == VD_PRR
         pos_kumulativ_prometa()

      CASE pos_doks->IdVd == POS_VD_POCETNO_STANJE
         pos_prepis_pocetno_stanje()

      ENDCASE

   CASE Ch == Asc( "F" ) .OR. Ch == Asc( "f" )

      hParams[ "idpos" ] := pos_doks->idpos
      hParams[ "datum" ] := pos_doks->datum
      hParams[ "brdok" ] := pos_doks->brdok
      hParams[ "napuni_dbf" ] := .T.
      pos_racun_stampa_priprema( hParams )

      //SELECT pos_doks
      pos_porezna_faktura_traka( .T. )

      SELECT pos_doks

      RETURN ( DE_REFRESH )


   CASE Ch == K_CTRL_P

      pos_stampa_dokumenta()

   CASE Ch == Asc( "E" ) .OR. Ch == Asc( "e" )

      IF field->idvd == "IN"
         IF Pitanje(, "Eksportovati dokument (D/N) ?", "N" ) == "D"
            pos_prenos_inv_2_kalk( field->idpos, field->idvd, field->datum, field->brdok )
         ENDIF
      ELSE
         MsgBeep( "Ne postoji metoda eksporta za ovu vrstu dokumenta !" )
      ENDIF

      RETURN ( DE_CONT )

   CASE Ch == Asc( "P" ) .OR. Ch == Asc( "p" )

      _id_pos := field->idpos
      _id_vd := field->idvd
      _br_dok := field->brdok
      _dat_dok := field->datum

      IF field->idvd <> POS_VD_INV
         MsgBeep( "Ne postoji metoda povrata za ovu vrstu dokumenta !" )
         RETURN ( DE_CONT )
      ENDIF

      IF Pitanje(, "Dokument " + _id_pos + "-" + _id_vd + "-" + _br_dok + " povući u pripremu (D/N) ?", "N" ) == "N"
         RETURN ( DE_CONT )
      ENDIF

      IF field->idvd == POS_VD_INV

         pos_povrat_dokumenta_u_pripremu()
         pos_brisi_dokument( _id_pos, _id_vd, _dat_dok, _br_dok )

         _o_pos_prepis_tbl()
         SELECT pos_doks
         SET FILTER TO &_tbl_filter
         GO TOP

         MsgBeep( "Dokument je vraćen u pripremu inventure ..." )

         RETURN ( DE_REFRESH )

      ENDIF

      RETURN ( DE_CONT )


   ENDCASE

   _o_pos_prepis_tbl()
   SELECT pos_doks
   SET FILTER TO &( _tbl_filter )
   GO ( _rec_no )

   RETURN ( DE_CONT )



FUNCTION pos_pregled_stavki_racuna()

   LOCAL oBrowse
   LOCAL cPrevCol
   LOCAL hRec
   LOCAL nMaxRow := f18_max_rows() - 15
   LOCAL nMaxCol := f18_max_cols() - 35


   PRIVATE ImeKol
   PRIVATE Kol

   cPrevCol := SetColor( f18_color_invert()  )

   SELECT F__PRIPR

   IF !Used()
      O__POS_PRIPR
   ENDIF

   SELECT _pos_pripr

   my_dbf_zap()
   Scatter()

   seek_pos_pos( pos_doks->IdPos, pos_doks->IdVd,  pos_doks->datum, pos_doks->BrDok )
   DO WHILE !Eof() .AND. POS->( IdPos + IdVd + DToS( datum ) + BrDok ) == pos_doks->( IdPos + IdVd + DToS( datum ) + BrDok )

      hRec := dbf_get_rec()

      select_o_roba( hRec[ "idroba" ] )
      hRec[ "robanaz" ] := roba->naz
      hRec[ "jmj" ] := roba->jmj
      hb_HDel( hRec, "rbr" )

      SELECT _pos_pripr
      APPEND BLANK

      dbf_update_rec( hRec )
      SELECT POS
      SKIP

   ENDDO

   SELECT _pos_pripr
   GO TOP

   pos_racun_browse_kolone( @ImeKol, @Kol )

   Box(, nMaxRow, nMaxCol )

   @ box_x_koord() + 1, box_y_koord() + 19 SAY8 PadC ( "Pregled računa " + Trim( pos_doks->IdPos ) + "-" + LTrim ( pos_doks->BrDok ), 30 ) COLOR f18_color_invert()

   oBrowse := pos_form_browse( box_x_koord() + 2, box_y_koord() + 1, box_x_koord() + nMaxRow, box_y_koord() + nMaxCol, ImeKol, Kol, ;
      { hb_UTF8ToStrBox( BROWSE_PODVUCI_2 ), ;
      hb_UTF8ToStrBox( BROWSE_PODVUCI ), ;
      hb_UTF8ToStrBox( BROWSE_COL_SEP ) }, 0 )
   ShowBrowse( oBrowse, {}, {} )
   SELECT _pos_pripr
   my_dbf_zap()

   BoxC()

   SetColor ( cPrevCol )

   SELECT pos_doks

   RETURN .T.



STATIC FUNCTION pos_racun_browse_kolone( aImeKol, aKol )

   LOCAL i

   aImeKol := {}
   aKol := {}

   AAdd( aImeKol, { _u( "Šifra" ), {|| field->idroba } } )
   AAdd( aImeKol, { "Naziv", {|| Left( field->robanaz, 30 ) } } )
   AAdd( aImeKol, { _u( "Količina" ), {|| Str( field->kolicina, 7, 3 ) } } )
   AAdd( aImeKol, { "Cijena", {|| Str( field->cijena, 7, 2 ) } } )
   AAdd( aImeKol, { "Popust", {|| Str( field->ncijena, 7, 2 ) } } )
   AAdd( aImeKol, { "Ukupno", {|| Str( ( field->kolicina * field->cijena ) - ( field->kolicina * field->ncijena ), 11, 2 ) } } )
   AAdd( aImeKol, { "Tarifa", {|| idtarifa } } )

   FOR i := 1 TO Len( aImeKol )
      AAdd( aKol, i )
   NEXT

   RETURN .T.



STATIC FUNCTION _o_pos_prepis_tbl()

// SELECT ( F_PARTN )
// IF !Used()
// o_partner()
// ENDIF

   // SELECT ( F_VRSTEP )
   // IF !Used()
   // o_vrstep()
   // ENDIF


   // SELECT ( F_ODJ )
   // IF !Used()
   // o_pos_odj()
   // ENDIF

   // SELECT ( F_KASE )
   // IF !Used()
   // o_pos_kase()
   // ENDIF

// SELECT ( F_OSOB )
// IF !Used()
   // o_pos_osob()
   // SET ORDER TO TAG "NAZ"
   // ENDIF

// SELECT ( F_TARIFA )
// IF !Used()
// o_tarifa()
// ENDIF

   // SELECT ( F_VALUTE )
// IF !Used()
   // o_valute()
   // ENDIF

// SELECT ( F_SIFK )
   // IF !Used()
// o_sifk()
// ENDIF

// SELECT ( F_SIFV )
// IF !Used()
// o_sifv()
// ENDIF

// SELECT ( F_ROBA )
   // IF !Used()
   // o_roba()
// ENDIF

// SELECT ( F_POS_DOKS )
// IF !Used()
// o_pos_doks()
// ENDIF

// SELECT ( F_POS )
// IF !Used()
// o_pos_pos()
// ENDIF

   RETURN .T.
