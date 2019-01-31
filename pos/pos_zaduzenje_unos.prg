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

/* pos_zaduzenje(cIdVd)
 *     Dokument zaduzenja
 *
 *  cIdVD -  16 ulaz
 *           95 otpis
 *           IN inventura
 *           NI nivelacija
 *           96 razduzenje sirovina - ako se radi o proizvodnji
 *           PD - predispozicija
 *
 *  pos_zaduzenje odjeljenje/punktova robama/sirovinama
 *       lForsSir .T. - radi se o forsiranom zaduzenju odjeljenja
 *                           sirovinama
 */
FUNCTION pos_zaduzenje

   PARAMETERS cIdVd

   LOCAL _from_kalk := .F.
   LOCAL cOdg
   LOCAL nSign

   IF gSamoProdaja == "D" .AND. ( cIdVd <> POS_VD_REKLAMACIJA )
      MsgBeep( "Ne možete vršiti unos zaduženja !" )
      RETURN .F.
   ENDIF

   PRIVATE ImeKol := {}
   PRIVATE Kol := {}
   PRIVATE oBrowse
   PRIVATE cBrojZad
   PRIVATE cIdOdj
   PRIVATE cRsDbf
   PRIVATE bRSblok
   PRIVATE cIdVd
   PRIVATE cRobSir := " "
   PRIVATE dDatRada := Date()
   PRIVATE cBrDok := nil

   IF cIdVd == NIL
      cIdVd := "16"
   ELSE
      cIdVd := cIdVd
   ENDIF

   ImeKol := { { "Sifra",    {|| idroba },      "idroba" }, ;
      { "Naziv",    {|| RobaNaz  },   "RobaNaz" }, ;
      { "JMJ",      {|| JMJ },         "JMJ"       }, ;
      { "Kolicina", {|| kolicina   }, "Kolicina"  }, ;
      { "Cijena",   {|| Cijena },      "Cijena"    } ;
      }
   Kol := { 1, 2, 3, 4, 5 }

   o_pos_tables()

   Box(, 6, 60 )

   cIdOdj := Space( 2 )
   // cIdDio := Space( 2 )
   cRazlog := Space( 40 )
   cIdOdj2 := Space( 2 )
   cIdPos := gIdPos

   SET CURSOR ON

   // IF gVodiOdj == "D"
   // @ box_x_koord() + 3, box_y_koord() + 3 SAY   " Odjeljenje:" GET cIdOdj VALID P_Odj ( @cIdOdj, 3, 28 )
   // IF cIdVD == "PD"
   // @ box_x_koord() + 4, box_y_koord() + 3 SAY " Prenos na :" GET cIdOdj2 VALID P_Odj ( @cIdOdj2, 4, 28 )
   // ENDIF
   // ENDIF

   @ box_x_koord() + 6, box_y_koord() + 3 SAY " Datum dok:" GET dDatRada PICT "@D" VALID dDatRada <= Date()
   READ
   ESC_BCR

   BoxC()

   bRSblok := {| x, y | pos_postoji_roba( @_idroba, x, y ), pos_set_key_handler_ispravka_zaduzenja() }
   cUI_I := R_I
   cUI_U := R_U

   SELECT PRIPRZ

   IF RecCount2() > 0
      SELECT _POS
      AppFrom( "PRIPRZ", .F. )
   ENDIF

   SELECT priprz
   my_dbf_zap()

   IF !pos_vrati_dokument_iz_pripr( cIdVd, gIdRadnik, cIdOdj ) // , cIdDio )
      my_close_all_dbf()
      RETURN .F.
   ENDIF

   fSadAz := .F.

   IF ( cIdVd <> POS_VD_REKLAMACIJA ) .AND. pos_preuzmi_iz_kalk( @cIdVd, @cBrDok )

      _from_kalk := .T.

      IF priprz->( RecCount2() ) > 0

         IF cBrDok <> NIL .AND. Pitanje(, "Odštampati prenesni dokument na štampac (D/N) ?", "N" ) == "D"

            IF cIdVd $ "16#96#95#98"
               pos_stampa_zaduzenja( cIdVd, cBrDok )
            ELSEIF cIdVd $ "IN#NI"
               pos_stampa_zaduzenja_inventure()
            ENDIF

            // o_pos_tables()
            IF Pitanje(, "Ako je sve u redu, želite li staviti dokument na stanje (D/N) ?", " " ) == "D"
               fSadAz := .T.
            ENDIF

         ENDIF
      ENDIF

   ENDIF

   IF cIdVD == "NI"

      my_close_all_dbf()
      pos_inventura_nivelacija( .F., .T., fSadaz, dDatRada )
      RETURN .T.

   ELSEIF cIdVd == "IN"

      my_close_all_dbf()
      pos_inventura_nivelacija( .T., .T., fSadAz, dDatRada )
      RETURN .T.

   ENDIF

   SELECT ( F_PRIPRZ )

   IF !Used()
      RETURN .F.
   ENDIF

   IF !fSadAz

      SELECT PRIPRZ
      SET ORDER TO
      GO  TOP

      BOX (, 20, 77,, { "<*> - Ispravka stavke ", "Storno - negativna količina" } )
      @ box_x_koord(), box_y_koord() + 4 SAY8 PadC( "PRIPREMA " + NaslovDok( cIdVd ) ) COLOR f18_color_invert()

      oBrowse := pos_form_browse( box_x_koord() + 6, box_y_koord() + 1, box_x_koord() + 19, box_y_koord() + 77, ImeKol, Kol, ;
         { hb_UTF8ToStrBox( BROWSE_PODVUCI_2 ), hb_UTF8ToStrBox( BROWSE_PODVUCI ), hb_UTF8ToStrBox( BROWSE_COL_SEP ) }, 0 )
      oBrowse:autolite := .F.

      pos_set_key_handler_ispravka_zaduzenja()

      SELECT PRIPRZ

      Scatter()

      _IdPos := cIdPos
      _IdVrsteP := cIdOdj2
      _IdOdj := cIdOdj
      // _IdDio := cIdDio
      _IdVd := cIdVd
      _BrDok := Space( FIELD_LEN_POS_BRDOK )
      _Datum := dDatRada
      _Smjena := gSmjena
      _IdRadnik := gIdRadnik
      _IdCijena := "1"
      _Prebacen := OBR_NIJE
      _MU_I := cUI_U
      IF cIdVd == POS_VD_OTPIS
         _MU_I := cUI_I
      ENDIF

      SET CURSOR ON

      DO WHILE .T.

         DO WHILE !oBrowse:Stabilize() .AND. ( ( Ch := Inkey() ) == 0 )
         ENDDO

         _idroba := Space ( Len ( _idroba ) )
         _Kolicina := 0
         _cijena := 0
         _ncijena := 0
         _marza2 := 0
         _TMarza2 := "%"
         fMarza := " "

         @ box_x_koord() + 2, box_y_koord() + 25 SAY Space( 40 )

         IF gDuzSifre <> NIL .AND. gDuzSifre > 0
            cDSFINI := AllTrim( Str( gDuzSifre ) )
         ELSE
            cDSFINI := my_get_from_ini( 'SifRoba', 'DuzSifra', '10' )
         ENDIF

         @ box_x_koord() + 2, box_y_koord() + 5 SAY " Artikal:" GET _idroba PICT "@!S" + cDSFINI ;
            WHEN {|| _idroba := PadR( _idroba, Val( cDSFINI ) ), .T. } ;
            VALID Eval ( bRSblok, 2, 25 ) .AND. ( gDupliArt == "D" .OR. ZadProvDuple( _idroba ) )
         @ box_x_koord() + 4, box_y_koord() + 5 SAY8 "Količina:" GET _Kolicina PICT "999999.999" ;
            WHEN{|| ShowGets(), .T. } VALID ZadKolOK( _Kolicina )

         IF gZadCij == "D"
            @ box_x_koord() + 3, box_y_koord() + 35  SAY "N.cijena:" GET _ncijena PICT "99999.9999"
            @ box_x_koord() + 3, box_y_koord() + 56  SAY "Marza:" GET _TMarza2  VALID _Tmarza2 $ "%AU" PICTURE "@!"
            @ box_x_koord() + 3, Col() + 2 GET _Marza2 PICTURE "9999.99"
            @ box_x_koord() + 3, Col() + 1 GET fMarza PICT "@!" VALID {|| _marza2 := iif( _cijena <> 0 .AND. Empty( fMarza ), 0, _marza2 ), kalk_marza_11( fmarza ), _cijena := iif( _cijena == 0, _cijena := _nCijena * ( tarifa->zpp / 100 + ( 1 + TARIFA->Opp / 100 ) * ( 1 + TARIFA->PPP / 100 ) ), _cijena ), fMarza := " ", .T. }
            @ box_x_koord() + 4, box_y_koord() + 35 SAY "MPC SA POREZOM:" GET _cijena  PICT "99999.999" VALID {|| _marza2 := 0, kalk_marza_11(), ShowGets(), .T. }
         ENDIF

         READ

         IF ( LastKey() == K_ESC )
            EXIT
         ELSE

            StUSif()
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

            oBrowse:goBottom()
            oBrowse:refreshAll()
            oBrowse:dehilite()

         ENDIF

      ENDDO

      pos_unset_key_handler_ispravka_zaduzenja()

      BoxC()

   ENDIF

   SELECT PRIPRZ

   IF RecCount2() > 0

      // SELECT pos_doks
      // SET ORDER TO TAG "1"

      IF !_from_kalk
         cBrDok := pos_novi_broj_dokumenta( cIdPos, iif( cIdvd == "PD", "16", cIdVd ) )
      ENDIF

      SELECT PRIPRZ

      Beep( 4 )

      IF !fSadAz .AND. Pitanje(, "Želite li odštampati dokument (D/N) ?", "N" ) == "D"
         pos_stampa_zaduzenja( cIdVd, cBrDok )
         o_pos_tables()
      ENDIF

      IF fSadAz .OR. Pitanje(, "Želite li staviti dokument na stanje (D/N) ?", "D" ) == "D"
         pos_azuriraj_zaduzenje( cBrDok, cIdVD )
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


// ----------------------------------------------------------
// setuje u sifranik mpc
// ----------------------------------------------------------
FUNCTION StUSif()

   LOCAL nDbfArea := Select()
   LOCAL hRec
   LOCAL _tmp

   IF gSetMPCijena == "1"
      _tmp := "mpc"
   ELSE
      _tmp := "mpc" + AllTrim( gSetMPCijena )
   ENDIF

   IF gZadCij == "D"

      IF _cijena <> pos_get_mpc() .AND. Pitanje(, "Staviti u šifarnik novu cijenu? (D/N)", "D" ) == "D"

         SELECT ( F_ROBA )
         hRec := dbf_get_rec()
         hRec[ _tmp ] := _cijena

         update_rec_server_and_dbf( "roba", hRec, 1, "FULL" )

         SELECT ( nDbfArea )
      ENDIF

   ENDIF

   RETURN .T.



FUNCTION pos_set_key_handler_ispravka_zaduzenja()

   SetKey( Asc( "*" ), {|| IspraviZaduzenje() } )

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



/* ZadProvDuple(cSif)
 *     Provjera postojanja sifre u zaduzenju
 *   param: cSif
 *
 */
FUNCTION ZadProvDuple( cSif )

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



/* IspraviZaduzenje()
 *     Ispravka zaduzenja od strane korisnika
 */
FUNCTION IspraviZaduzenje()

   LOCAL cGetId
   LOCAL nGetKol
   LOCAL aConds
   LOCAL aProcs

   pos_unset_key_handler_ispravka_zaduzenja()

   cGetId := _idroba
   nGetKol := _Kolicina

   prikaz_dostupnih_opcija( { "<Enter>-Ispravi stavku", "<B>-Brisi stavku", "<Esc>-Zavrsi" } )

   oBrowse:autolite := .T.
   oBrowse:configure()
   aConds := { {| Ch | Ch == Asc ( "b" ) .OR. Ch == Asc ( "B" ) }, {| Ch | Ch == K_ENTER } }
   aProcs := { {|| BrisStavZaduz () }, {|| EditStavZaduz () } }
   ShowBrowse( oBrowse, aConds, aProcs )
   oBrowse:autolite := .F.
   oBrowse:dehilite()
   oBrowse:stabilize()

   Prozor0()
   _idroba := cGetId
   _Kolicina := nGetKol

   pos_set_key_handler_ispravka_zaduzenja()

   RETURN .T.



/* BrisStavZaduz()
 *     Brise stavku zaduzenja
 */

FUNCTION BrisStavZaduz()

   SELECT PRIPRZ
   IF RecCount2() == 0
      MsgBeep( "Zaduženje nema nijednu stavku!#Brisanje nije moguće!", 20 )
      RETURN ( DE_CONT )
   ENDIF
   Beep( 2 )
   my_delete_with_pack()
   oBrowse:refreshAll()

   RETURN ( DE_CONT )



FUNCTION EditStavZaduz()

   LOCAL PrevRoba
   LOCAL nARTKOL := 2
   LOCAL nKOLKOL := 4
   PRIVATE GetList := {}

   IF RecCount2() == 0
      MsgBeep( "Zaduženje nema nijednu stavku!#Ispravka nije moguća!", 20 )
      RETURN ( DE_CONT )
   ENDIF

   PrevRoba := _IdRoba := PRIPRZ->idroba
   _Kolicina := PRIPRZ->Kolicina
   Box(, 3, 60 )
   @ box_x_koord() + 1, box_y_koord() + 3 SAY "Novi artikal:" GET _idroba PICTURE "@K" VALID Eval ( bRSblok, 1, 27 ) .AND. ( _IdRoba == PrevRoba .OR. ZadProvDuple ( _idroba ) )
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
   oBrowse:refreshCurrent()

   RETURN ( DE_CONT )


FUNCTION NaslovDok( cIdVd )

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
