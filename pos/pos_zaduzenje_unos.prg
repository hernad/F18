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

STATIC s_oBrowse
STATIC s_cRobaDuzinaSifre

MEMVAR Kol, ImeKol

/* pos_zaduzenje(cIdVd)
 *     Dokument zaduzenja
 *
 *  cIdVD -  16 ulaz
 *           95 otpis
 *           IN inventura
 *           NI nivelacija
 *          // 96 razduzenje sirovina - ako se radi o proizvodnji
 *         //  PD - predispozicija
 *
 *  pos_zaduzenje odjeljenje/punktova robama/sirovinama
 *       lForsSir .T. - radi se o forsiranom zaduzenju odjeljenja
 *                           sirovinama
 */

FUNCTION pos_zaduzenje( cIdVd )

   LOCAL lFromKalk := .F.
   LOCAL cOdg
   LOCAL nSign
   LOCAL GetList := {}
   LOCAL aPosKalk
   LOCAL cBrDok
   LOCAL lAzuriratiBezStampeSilent := .F.

   IF gSamoProdaja == "D" .AND. ( cIdVd <> POS_VD_REKLAMACIJA )
      MsgBeep( "Ne možete vršiti unos zaduženja !" )
      RETURN .F.
   ENDIF
   PRIVATE ImeKol := {}
   PRIVATE Kol := {}

   PRIVATE cBrojZad
   PRIVATE cRsDbf

   PRIVATE dDatRada := Date()

   IF cIdVd == NIL
      cIdVd := "16"
   ENDIF

   ImeKol := { { _u( "Šifra" ),    {|| idroba },      "idroba" }, ;
      { "Partner", {|| idPartner }, "idPartner" }, ;
      { "Naziv",    {|| RobaNaz  },   "RobaNaz" }, ;
      { "JMJ",      {|| JMJ },         "JMJ"       }, ;
      { _u( "Količina" ), {|| kolicina   }, "Kolicina"  }, ;
      { "Cijena",   {|| Cijena },      "Cijena"    } ;
      }
   Kol := { 1, 2, 3, 4, 5, 6 }

   s_cRobaDuzinaSifre := AllTrim( Str( gRobaPosDuzinaSifre ) )

   o_pos_tables()

   SELECT PRIPRZ
   Scatter()
   _IdPos := gIdPos
   _IdVd := cIdVd
   _BrDok := Space( FIELD_LEN_POS_BRDOK )
   _Datum := dDatRada
   _IdRadnik := gIdRadnik
   _IdCijena := "1"

   Box(, 6, f18_max_cols() - 15 )

   cRazlog := Space( 40 )
   // cIdOdj2 := Space( 2 )
   // cIdPos := gIdPos

   SET CURSOR ON
   @ box_x_koord() + 1, box_y_koord() + 3 SAY " Partner:" GET _idPartner PICT "@!" VALID p_partner( @_idPArtner )
   @ box_x_koord() + 2, box_y_koord() + 3 SAY " Datum dok:" GET dDatRada PICT "@D" VALID dDatRada <= Date()
   READ
   ESC_BCR
   BoxC()

   // SELECT PRIPRZ
   SET ORDER TO
   GO  TOP
   BOX (, f18_max_rows() - 12, f18_max_cols() - 10 - 1,, { _u( "<*> - Ispravka stavke " ), _u( "Storno - negativna količina" ) } )
   @ box_x_koord(), box_y_koord() + 4 SAY8 PadC( "PRIPREMA " + pos_naslov_dok_zaduzenja( cIdVd ) ) COLOR f18_color_invert()
   s_oBrowse := pos_form_browse( box_x_koord() + 6, box_y_koord() + 1, box_x_koord() + f18_max_rows() - 12, box_y_koord() + f18_max_cols() - 10, ImeKol, Kol, ;
      { hb_UTF8ToStrBox( BROWSE_PODVUCI_2 ), hb_UTF8ToStrBox( BROWSE_PODVUCI ), hb_UTF8ToStrBox( BROWSE_COL_SEP ) }, 0 )
   s_oBrowse:autolite := .F.

   pos_set_key_handler_ispravka_zaduzenja()

   SET CURSOR ON
   DO WHILE .T.

      DO WHILE !s_oBrowse:Stabilize() .AND. ( ( Ch := Inkey() ) == 0 )
      ENDDO

      _idroba := Space ( Len ( _idroba ) )
      _Kolicina := 0
      _cijena := 0
      _ncijena := 0

      @ box_x_koord() + 2, box_y_koord() + 25 SAY Space( 50 )
      @ box_x_koord() + 2, box_y_koord() + 5 SAY " Artikal:" GET _idroba PICT "@!S" + s_cRobaDuzinaSifre ;
         WHEN {|| _idroba := PadR( _idroba, Val( s_cRobaDuzinaSifre ) ), .T. } ;
         VALID pos_valid_roba_zaduzenje( @_IdRoba, 2, 35 )
      @ box_x_koord() + 4, box_y_koord() + 5 SAY8 "Količina:" GET _Kolicina PICT "999999.999" ;
         WHEN{|| ShowGets(), .T. } VALID ZadKolOK( _Kolicina )
      @ box_x_koord() + 4, box_y_koord() + 35 SAY "MPC SA PDV:" GET _cijena  PICT "99999.999" VALID {|| .T. }

      READ

      IF ( LastKey() == K_ESC )
         EXIT
      ENDIF

      // StUSif()
      SELECT PRIPRZ
      APPEND BLANK
      select_o_roba( _idRoba )
      _robanaz := roba->naz
      _jmj := roba->jmj
      _idtarifa := roba->idtarifa
      _cijena := iif( Empty( _cijena ), pos_get_mpc(), _cijena )
      _barkod := roba->barkod
      _n1 := roba->n1
      _n2 := roba->n2
      _k1 := roba->k1
      _k2 := roba->k2
      _k7 := roba->k7
      _k9 := roba->k9

      SELECT priprz
      Gather()
      s_oBrowse:goBottom()
      s_oBrowse:refreshAll()
      s_oBrowse:dehilite()

   ENDDO

   pos_unset_key_handler_ispravka_zaduzenja()
   BoxC()

   SELECT PRIPRZ

   IF RecCount2() > 0
      IF !lFromKalk
         cBrDok := pos_novi_broj_dokumenta( gIdPos, iif( cIdvd == "PD", "16", cIdVd ) )
      ENDIF

      SELECT PRIPRZ
      Beep( 4 )
      IF !lAzuriratiBezStampeSilent .AND. Pitanje(, "Želite li odštampati dokument (D/N) ?", "N" ) == "D"
         pos_stampa_zaduzenja( cIdVd, cBrDok )
         o_pos_tables()
      ENDIF

      IF lAzuriratiBezStampeSilent .OR. Pitanje(, "Želite li " + gIdPos + "-" + cIdVd + "-" + AllTrim(cBrDok) + " ažurirati (D/N) ?", "D" ) == "D"
         pos_azuriraj_zaduzenje( gIdPos, cIdVd, cBrDok )
      ELSE
         SELECT _POS
         AppFrom( "PRIPRZ", .F. )
         SELECT PRIPRZ
         my_dbf_zap()
         MsgBeep( "Dokument nije stavljen na stanje!#" + "Ostavljen je za doradu!", 20 )
      ENDIF
   ENDIF

   my_close_all_dbf()

   RETURN .T.



STATIC FUNCTION pos_valid_roba_zaduzenje( cIdRoba, nX, nY )

   LOCAL lOk

   lOk := pos_postoji_roba( @cIdroba, nX, nY )
   cIdroba := PadR( cIdroba, Val( s_cRobaDuzinaSifre ) )

   RETURN lOk .AND. ( gDupliArt == "D" .OR.  pos_zaduzenje_provjeri_duple_stavke( cIdroba ) )



/*
// ----------------------------------------------------------
// setuje u sifranik mpc
// ----------------------------------------------------------
-- FUNCTION StUSif()

   LOCAL nDbfArea := Select()
   LOCAL hRec
   LOCAL _tmp

   IF gSetMPCijena == "1"
      _tmp := "mpc"
   ELSE
      _tmp := "mpc" + AllTrim( gSetMPCijena )
   ENDIF

// --   IF gZadCij == "D"
//
//       IF _cijena <> pos_get_mpc() .AND. Pitanje(, "Staviti u šifarnik novu cijenu? (D/N)", "D" ) == "D"
//
//          SELECT ( F_ROBA )
//          hRec := dbf_get_rec()
//          hRec[ _tmp ] := _cijena
//
//          update_rec_server_and_dbf( "roba", hRec, 1, "FULL" )
//
//          SELECT ( nDbfArea )
//       ENDIF
//
//    ENDIF


   RETURN .T.
*/


STATIC FUNCTION pos_set_key_handler_ispravka_zaduzenja()

   SetKey( Asc( "*" ), {|| pos_ispravi_zaduzenje() } )

   RETURN .T.


FUNCTION pos_unset_key_handler_ispravka_zaduzenja()

   SetKey( Asc( "*" ), NIL )

   RETURN .F.


FUNCTION ZadKolOK( nKol )

   IF LastKey() = K_UP
      RETURN .T.
   ENDIF
   IF nKol = 0
      MsgBeep( "Količina mora biti različita od nule!#Ponovite unos!", 20 )
      RETURN ( .F. )
   ENDIF

   RETURN ( .T. )



FUNCTION pos_zaduzenje_provjeri_duple_stavke( cSif )

   LOCAL lFlag := .T.

   SELECT PRIPRZ
   SET ORDER TO TAG "1"
   nPrevRec := RecNo()
   SEEK cSif
   IF Found()
      MsgBeep( "Na zaduženju se vec nalazi isti artikal!#" + "U slučaju potrebe ispravite stavku zaduženja!", 20 )
      lFlag := .F.
   ENDIF
   SET ORDER TO
   GO ( nPrevRec )

   RETURN ( lFlag )



FUNCTION pos_ispravi_zaduzenje()

   LOCAL cGetId
   LOCAL nGetKol
   LOCAL aConds
   LOCAL aProcs

altd()
   pos_unset_key_handler_ispravka_zaduzenja()

   cGetId := _idroba
   nGetKol := _Kolicina

   prikaz_dostupnih_opcija_crno_na_zuto( { "<Enter>-Ispravi stavku", "<B>-Brisi stavku", "<Esc>-Zavrsi" } )

   s_oBrowse:autolite := .T.
   s_oBrowse:configure()
   aConds := { {| Ch | Ch == Asc ( "b" ) .OR. Ch == Asc ( "B" ) }, {| Ch | Ch == K_ENTER } }
   aProcs := { {|| pos_brisi_stavku_zaduzenja() }, {|| pos_ispravi_stavku_zaduzenja() } }
   ShowBrowse( s_oBrowse, aConds, aProcs )
   s_oBrowse:autolite := .F.
   s_oBrowse:dehilite()
   s_oBrowse:stabilize()

   //box_crno_na_zuto_end()
   _idroba := cGetId
   _Kolicina := nGetKol

   pos_set_key_handler_ispravka_zaduzenja()

   RETURN .T.



FUNCTION pos_brisi_stavku_zaduzenja()

   SELECT PRIPRZ
   IF RecCount2() == 0
      MsgBeep( "Zaduženje nema nijednu stavku!#Brisanje nije moguće!", 20 )
      RETURN ( DE_CONT )
   ENDIF
   Beep( 2 )
   my_delete_with_pack()
   s_oBrowse:refreshAll()

   RETURN ( DE_CONT )


FUNCTION pos_ispravi_stavku_zaduzenja()

   LOCAL PrevRoba
   LOCAL nARTKOL := 2
   LOCAL nKOLKOL := 4
   LOCAL GetList := {}

   IF RecCount2() == 0
      MsgBeep( "Zaduženje nema nijednu stavku!#Ispravka nije moguća!", 20 )
      RETURN ( DE_CONT )
   ENDIF

   PrevRoba := _IdRoba := PRIPRZ->idroba
   _Kolicina := PRIPRZ->Kolicina
   Box(, 3, 60 )
   @ box_x_koord() + 1, box_y_koord() + 3 SAY8 "Novi artikal:" GET _idroba PICTURE "@K" ;
      VALID pos_valid_roba_zaduzenje( @_IdRoba, 1, 30 )
   // VALID Eval ( bRobaPosValid, 1, 27 ) .AND. ( _IdRoba == PrevRoba .OR. pos_zaduzenje_provjeri_duple_stavke ( _idroba ) )
   @ box_x_koord() + 2, box_y_koord() + 3 SAY8 "Nova količina:" GET _Kolicina VALID ZadKolOK ( _Kolicina )
   READ

   IF LastKey() <> K_ESC
      my_rlock()
      IF _idroba <> PrevRoba
         REPLACE RobaNaz WITH roba->Naz, Jmj WITH roba->Jmj, Cijena WITH roba->Cijena, IdRoba WITH _IdRoba
      ENDIF
      REPLACE Kolicina WITH _Kolicina
      my_unlock()
   ENDIF

   BoxC()
   s_oBrowse:refreshCurrent()

   RETURN ( DE_CONT )


FUNCTION pos_naslov_dok_zaduzenja( cIdVd )

   DO CASE
   CASE cIdVd == "16"
      RETURN "ZADUŽENJE"
   CASE cIdVd == "PD"
      RETURN "PREDISPOZICIJA"
   CASE cIdVd == "95"
      RETURN "OTPIS"
   CASE cIdVd == "98"
      RETURN "REKLAMACIJA"
   OTHERWISE
      RETURN "????"
   ENDCASE

   RETURN .T.
