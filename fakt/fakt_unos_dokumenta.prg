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

MEMVAR ImeKol, Kol, TB

MEMVAR _datdok, _idfirma, _idtipdok, _brdok, _podbr, _tip_rabat, _idpartner
MEMVAR _cijena, _idroba, _kolicina, _rbr, _rabat, _serbr, _porez, _zaokr, _idrelac, _k1, _k2, _m1, _dindem, _idvrstep, _txt


// STATIC __fiscal_marker := .F.
// STATIC __id_firma
// STATIC __tip_dok
// STATIC __br_dok
// STATIC __r_br
STATIC s_cKeyboardEnterSequence := Chr( K_ENTER ) + Chr( K_ENTER ) + Chr( K_ENTER )
STATIC s_nFaktUnosRedniBroj


/*

-- DROP TABLE fmk.fakt_fakt;

CREATE TABLE fmk.fakt_fakt
(
  idfirma character(2) NOT NULL,
  idtipdok character(2) NOT NULL,
  brdok character varying(12) NOT NULL,
  datdok date,
  idpartner character(6),
  dindem character(3),
  zaokr numeric(1,0),
  rbr character(3) NOT NULL,
  podbr character(2),
  idroba character(10),
  serbr character(15),
  kolicina numeric(14,5),
  cijena numeric(14,5),
  rabat numeric(8,5),
  porez numeric(9,5),
  txt text,
  k1 character(4),
  k2 character(4),
  m1 character(1),
  brisano character(1),
  idroba_j character(10),
  idvrstep character(2),
  idpm character(15),
  c1 character(20),
  c2 character(20),
  c3 character(20),
  n1 numeric(10,3),
  n2 numeric(10,3),
  idrelac character(4),
  CONSTRAINT fakt_fakt_pkey PRIMARY KEY (idfirma, idtipdok, brdok, rbr)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE fmk.fakt_fakt
  OWNER TO hernad;

-- Index: fmk.fakt_fakt_datdok

-- DROP INDEX fmk.fakt_fakt_datdok;

CREATE INDEX fakt_fakt_datdok
  ON fmk.fakt_fakt
  USING btree
  (datdok);

-- Index: fmk.fakt_fakt_id1
-- DROP INDEX fmk.fakt_fakt_id1;

CREATE INDEX fakt_fakt_id1
  ON fmk.fakt_fakt
  USING btree
  (idfirma COLLATE pg_catalog."default", idtipdok COLLATE pg_catalog."default", brdok COLLATE pg_catalog."default", rbr COLLATE pg_catalog."default", idpartner COLLATE pg_catalog."default");

*/

FUNCTION fakt_unos_dokumenta()

   LOCAL nI, _x_pos, _y_pos, nX, nY
   LOCAL _opt_d, cFaktaOpcije
   LOCAL _sep := hb_UTF8ToStrBox( BROWSE_COL_SEP )
   PRIVATE ImeKol, Kol

#ifdef F18_POS

   pos_unset_key_handler_ispravka_racuna()
#endif
   zadnji_fiscal_z_report_info()

   close_open_fakt_tabele()
   select_fakt_pripr()

   // IF field->idtipdok == "IM"
   // my_close_all_dbf()
   // fakt_unos_inventure()
   // RETURN .T.
   // ENDIF

   PRIVATE ImeKol := { ;
      { "Red.br",  {|| my_dbSelectArea( F_FAKT_PRIPR ), fakt_rbr()                   } }, ;
      { "Partner/Roba",  {|| Part1Stavka() + fakt_prikazi_Roba()  } }, ;
      { _ue( "Količina" ),  {|| field->kolicina  } }, ;
      { "Cijena",    {|| field->Cijena    }, "cijena"    }, ;
      { "Rabat",    {|| Transform( field->Rabat, "999.99" ) }, "Rabat"  }, ;
      { _ue( "Real.Marža" ), {|| fakt_unos_prikaz_marza() } }, ;
      { "Nab.Cj",   {|| fakt_unos_prikaz_nab_cj() } }, ;
      { "RJ",        {|| field->idfirma                 }, "idfirma"   }, ;
      { "Serbr",     {|| field->SerBr                   }, "serbr"     }, ;
      { "Partn",     {|| field->IdPartner               }, "IdPartner" }, ;
      { "IdTipDok",  {|| field->IdTipDok                }, "Idtipdok"  }, ;
      { "DinDem",    {|| field->dindem                  }, "dindem"    }, ;
      { "Brdok",     {|| field->Brdok                   }, "Brdok"     }, ;
      { "DatDok",    {|| field->DATDOK                  }, "DATDOK"    } ;
      }

   IF fakt_pripr->( FieldPos( "idrelac" ) ) <> 0
      AAdd( ImeKol, { "ID relac.", {|| field->idrelac  }, "IDRELAC"  } )
   ENDIF

   Kol := {}
   FOR nI := 1 TO Len( ImeKol )
      AAdd( Kol, nI )
   NEXT

   // marker fiskalnih racuna
   // __fiscal_marker := .F.

   // podaci dokumenta
   // __id_firma  := field->idfirma
   // __tip_dok := field->idtipdok
   // __br_dok  := field->brdok
   // __r_br := field->rbr

   nX := f18_max_rows() - 4
   nY := f18_max_cols() - 3

   Box( , nX, nY )

   _opt_d := ( nY / 4 )

   cFaktaOpcije := _upadr(  "<c+N> Nova stavka", _opt_d ) + _sep
   cFaktaOpcije += _upadr( "<ENT> Ispravka", _opt_d ) + _sep
   cFaktaOpcije += _upadr( "<c+T> Briši stavku", _opt_d ) + _sep

   @ box_x_koord() + nX - 4, box_y_koord() + 2 SAY8 cFaktaOpcije

   cFaktaOpcije := _upadr( "<c+A> Ispravka dok.", _opt_d ) + _sep
   cFaktaOpcije += _upadr( "<c+P> Štampa (txt)", _opt_d ) + _sep
   cFaktaOpcije += _upadr( iif( is_mac(), "<P>", "<a+P>" ) + " Štampa (LO)", _opt_d ) + _sep

   @ box_x_koord() + nX - 3, box_y_koord() + 2 SAY8 cFaktaOpcije

   cFaktaOpcije := _upadr( "<a+A> Ažuriranje", _opt_d ) + _sep
   cFaktaOpcije += _upadr( "<c+F9> Briši sve", _opt_d ) + _sep
   cFaktaOpcije += _upadr( "<F5> Kontrola zbira", _opt_d ) + _sep
   cFaktaOpcije += "<T> total dokumenta"

   @ box_x_koord() + nX - 2, box_y_koord() + 2 SAY8 cFaktaOpcije

   cFaktaOpcije := _upadr( "", _opt_d ) + _sep
   cFaktaOpcije += _upadr( "", _opt_d ) + _sep
   cFaktaOpcije += _upadr( iif( is_mac(), "<0>", "<F10>" ) + " Ostale aOpcije", _opt_d ) + _sep
   cFaktaOpcije += "<O> Konverzije"
   cFaktaOpcije += "<A> Asistent"

   @ box_x_koord() + nX - 1, box_y_koord() + 2 SAY8 cFaktaOpcije

   my_browse( "PNal", nX, nY, {| nCh | fakt_pripr_keyhandler( nCh ) }, "", "FAKT Priprema...", , , , , 4 )

   BoxC()

   // my_close_all_dbf()

   RETURN .T.





STATIC FUNCTION edit_fakt_priprema( lFaktNoviRec, hFaktItemsAttributi )

   LOCAL aTipoviDokumenata := {}
   LOCAL aH
   LOCAL nRokPlacanja := 0
   LOCAL lAvansniRacun
   LOCAL cOpis := ""
   LOCAL nMenu := fakt_tip_dokumenta_default_menu()
   LOCAL cConvertDN := "N"
   LOCAL nX := 1
   LOCAL lOdabirFaktTxt := .F.
   LOCAL cFaktTxtListaUzoraka
   LOCAL nX2, nXPartner, nYPartner, _tip_cijene
   LOCAL cRefBroj, cLotBroj
   LOCAL hFaktParams := fakt_params()
   LOCAL hFaktTxt
   LOCAL nRokPlacanjaDefault := fakt_rok_placanja_dana()
   LOCAL GetList := {}
   LOCAL nSnimi_m_x, nSnimi_m_y
   LOCAL cIdTipDokStari

   aTipoviDokumenata := fakt_tip_dok_arr()
   aH := {}
   ASize( aH, Len( aTipoviDokumenata ) )
   AFill( aH, "" )

   IF hFaktItemsAttributi <> NIL

      IF hFaktParams[ "fakt_opis_stavke" ]
         IF lFaktNoviRec
            cOpis := PadR( "", 300 )
         ELSE
            cOpis := PadR( hFaktItemsAttributi[ "opis" ], 300 )
         ENDIF
      ENDIF

      IF hFaktParams[ "ref_lot" ]

         IF lFaktNoviRec
            cRefBroj := PadR( "", 50 )
            cLotBroj := PadR( "", 50 )
         ELSE
            cRefBroj := PadR( hFaktItemsAttributi[ "ref" ], 50 )
            cLotBroj := PadR( hFaktItemsAttributi[ "lot" ], 50 )
         ENDIF
      ENDIF

   ENDIF


   set_cursor_on()

   IF lFaktNoviRec  // nova stavka

      cConvertDN := "D"
      _serbr := Space( Len( field->serbr ) )
      _cijena := 0
      _kolicina := 0

      // IF gResetRoba == "D"
      _idRoba := Space( 10 )
      // ENDIF

      IF s_nFaktUnosRedniBroj == 1

         nMenu := iif( Val( gIMenu ) < 1, Asc( gIMenu ) - 55, Val( gIMenu ) )
         _idfirma := self_organizacija_id()
         IF !Empty( hFaktParams[ "def_rj" ] )
            _idfirma := hFaktParams[ "def_rj" ]
         ENDIF
         _idtipdok := "10"
         _datdok := Date()
         _zaokr := 2
         _dindem := Left( ValBazna(), 3 )
         _m1 := " "
         _brdok := PadR( Replicate( "0", gNumDio ), 8 )
      ENDIF

      hFaktTxt := fakt_ftxt_decode_string( "" )
      hFaktTxt[ "datpl" ] := _datDok
      hFaktTxt[ "datotp" ] := _datdok // inicijalizirati dat isporuke = "datotp"  = fakt.datdok

   ELSE
      hFaktTxt := fakt_ftxt_decode_string( _txt )
      nMenu := AScan( aTipoviDokumenata, {| x | _idtipdok == Left( x, 2 ) } )
   ENDIF


   _podbr := Space( 2 )
   _tip_rabat := "%"

   IF ( s_nFaktUnosRedniBroj == 1 .AND. Val( _podbr ) < 1 )

      IF RecCount() == 0
         _idFirma := self_organizacija_id()
      ENDIF

      IF !Empty( hFaktParams[ "def_rj" ] )
         _idfirma := hFaktParams[ "def_rj" ]
      ENDIF

      @ box_x_koord() + nX, box_y_koord() + 2 SAY PadR( self_organizacija_naziv(), 20 )

      fakt_getlist_rj_read( box_x_koord() + nX, Col() + 2, @GetList, @_idFirma, .F. )
      // @ box_x_koord() + nX, Col() + 2 SAY " RJ:" GET _idfirma PICT "@!" VALID {|| Empty( _idfirma ) .OR. _idfirma == self_organizacija_id() ;
      // .OR. P_RJ( @_idfirma ) .AND. V_Rj(), _idfirma := Left( _idfirma, 2 ), .T. }

      READ

      nSnimi_m_x := box_x_koord()
      nSnimi_m_y := box_y_koord()

      cIdTipDokStari := field->idtipdok

      nMenu := meni_fiksna_lokacija( 5, 30, aTipoviDokumenata, nMenu )

      box_x_koord( nSnimi_m_x )
      box_y_koord( nSnimi_m_y )

      ESC_RETURN 0

      IF aTipoviDokumenata == NIL .OR. Len( aTipoviDokumenata ) == 0
         MsgBeep( "Odabir vrste dokumenta se vrši sa ENTER !" )
         RETURN 0
      ENDIF

      IF nMenu == NIL .OR. nMenu > Len( aTipoviDokumenata ) .OR. nMenu < 0
         MsgBeep( "Nepostojeća aOpcija !" )
         RETURN 0
      ENDIF

      _idtipdok := Left( aTipoviDokumenata[ nMenu ], 2 )

      ++nX
      @ box_x_koord() + nX, box_y_koord() + 2 SAY PadR( fakt_naziv_dokumenta( @aTipoviDokumenata, _idtipdok ), 40 )

      IF !lFaktNoviRec .AND. s_nFaktUnosRedniBroj == 1
         IF _idtipdok <> cIdTipDokStari .AND. !Empty( field->brdok ) .AND. AllTrim( field->brdok ) <> "00000"
            MsgBeep( "Vršite promjenu vrste dokumenta. Obratiti pažnju na broj !" )
            IF Pitanje(, "Resetovati broj dokumenta na 00000 (D/N) ?", "D" ) == "D"
               _brdok := PadR( Replicate( "0", gNumDio ), 8 )
            ENDIF
         ENDIF
      ENDIF

      DO WHILE .T.

         nX := 2

         @  box_x_koord() + nX, box_y_koord() + 45 SAY "Datum:" GET _datdok
         @  box_x_koord() + nX, Col() + 1 SAY "Broj:" GET _brdok VALID !Empty( _brdok )

         nX += 2
         @ nXPartner := box_x_koord() + nX, nYPartner := box_y_koord() + 2 SAY "Partner:" GET _idpartner PICT "@!"   VALID {|| fakt_valid_partner( @_idpartner, nXPartner, nYPartner ) }

         nX += 2

         IF hFaktParams[ "fakt_dok_veze" ]
            @ box_x_koord() + nX, box_y_koord() + 2 SAY "Vezni dok:" GET hFaktTxt[ "dokument_veza" ]  PICT "@S20"
         ENDIF

         ++nX
         IF hFaktParams[ "destinacije" ]
            @ box_x_koord() + nX, box_y_koord() + 2 SAY "Dest:" GET hFaktTxt[ "destinacija" ] PICT "@S20"
         ENDIF

         IF ( hFaktParams[ "fakt_objekti" ] .AND. _idtipdok $ "10#11#12#13" )
            @ box_x_koord() + nX, Col() + 1 SAY "Objekat:" GET hFaktTxt[ "objekti" ] ;
               VALID p_fakt_objekti( @hFaktTxt[ "objekti" ] ) PICT "@!"
         ENDIF

         nX2 := 4

         IF _idtipdok $ "10#11"

            @ box_x_koord() + nX2, box_y_koord() + 51 SAY8 "Otpremnica broj:" GET hFaktTxt[ "brotp" ] PICT "@S20" WHEN fakt_unos_w_brotp( lFaktNoviRec )
            ++nX2
            @ box_x_koord() + nX2, box_y_koord() + 51 SAY8 "          datum:" GET hFaktTxt[ "datotp" ]
            ++nX2
            @ box_x_koord() + nX2, box_y_koord() + 51 SAY8 "Ugovor/narudžba:" GET hFaktTxt[ "brnar" ] PICT "@S20"

            IF lFaktNoviRec .AND. nRokPlacanjaDefault > 0
               nRokPlacanja := nRokPlacanjaDefault
            ENDIF

            ++nX2
            @ box_x_koord() + nX2, box_y_koord() + 51 SAY8 "Rok plać.(dana):" GET nRokPlacanja PICT "999" ;
               WHEN valid_rok_placanja( @nRokPlacanja, @_datDok, @hFaktTxt[ "datpl" ], "0", lFaktNoviRec ) ;
               VALID valid_rok_placanja( nRokPlacanja, @_datDok, @hFaktTxt[ "datpl" ], "1", lFaktNoviRec )
            ++nX2
            @ box_x_koord() + nX2, box_y_koord() + 51 SAY8 "Datum plaćanja :" GET hFaktTxt[ "datpl" ] ;
               VALID valid_rok_placanja( nRokPlacanja, @_datDok, @hFaktTxt[ "datpl" ], "2", lFaktNoviRec )

            IF hFaktParams[ "fakt_vrste_placanja" ] // fakt.idvrstep
               ++nX
               @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Način plaćanja" GET _idvrstep PICT "@!" VALID Empty( _idvrstep ) .OR. P_VRSTEP( @_idvrstep, 9, 20 )
            ENDIF


         ELSEIF ( _idtipdok == "06" )

            ++nX2
            @ box_x_koord() + nX2, box_y_koord() + 51 SAY "Po ul.fakt.broj:" GET hFaktTxt[ "brotp" ] PICT "@S20" WHEN fakt_unos_w_brotp( lFaktNoviRec )
            ++nX2
            @ box_x_koord() + nX2, box_y_koord() + 51 SAY "       i UCD-u :" GET hFaktTxt[ "brnar" ] PICT "@S20"

         ELSE
            ++nX2
            @ box_x_koord() + nX2, box_y_koord() + 51 SAY " datum isporuke:" GET hFaktTxt[ "datotp" ]

         ENDIF

         // IF ( fakt_pripr->( FieldPos( "idrelac" ) ) <> 0 .AND.
         IF _idtipdok $ "#11#"
            ++nX2
            @ box_x_koord() + nX2, box_y_koord() + 51  SAY "       Relacija:" GET _idrelac PICT "@S10" // fakt.idrelac
         ENDIF

         nX += 3

         IF _idTipDok $ "10#11#12#19#20#25#26#27"
            @ box_x_koord() + nX, box_y_koord() + 2 SAY "Valuta ?" GET _dindem PICT "@!"
         ELSE
            @ box_x_koord() + nX, box_y_koord() + 2 SAY " "
         ENDIF

         IF _idtipdok $ "10"

            lAvansniRacun := "N"

            IF _idvrstep == "AV"
               lAvansniRacun := "D"
            ENDIF

            @ box_x_koord() + nX, Col() + 4 SAY8 "Avansni račun (D/N)?:" GET lAvansniRacun PICT "@!" VALID lAvansniRacun $ "DN"

         ENDIF

         //IF ( gIspPart == "N" )
            READ
         //ENDIF

         ESC_RETURN 0

         select_fakt_pripr()

         EXIT

      ENDDO

   ELSE

      @ box_x_koord() + nX, box_y_koord() + 2 SAY PadR( self_organizacija_naziv(), 20 )

      ?? "  RJ:", _idfirma
      nX += 2
      @ box_x_koord() + nX, box_y_koord() + 2 SAY PadR( fakt_naziv_dokumenta( @aTipoviDokumenata, _idtipdok ), 35 )
      @ box_x_koord() + nX, box_y_koord() + 45 SAY "Datum: "
      ?? _datdok

      @ box_x_koord() + nX, Col() + 1 SAY "Broj: "
      ?? _brdok
      hFaktTxt[ "txt2" ] := ""

   ENDIF

   nX := 13
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "R.br: " GET s_nFaktUnosRedniBroj PICT "9999"

   nX := 15
   @ box_x_koord() + nX, box_y_koord() + 2  SAY "Artikal: " GET _IdRoba PICT "@!S10" ;
      WHEN {|| _idroba := PadR( _idroba, Val( gDuzSifIni ) ), W_Roba() } ;
      VALID {|| fakt_valid_roba( _IdFirma, _IdTipDok, @_IdRoba, @hFaktTxt[ "opis_usluga" ], _IdPartner, lFaktNoviRec, 15 ) }


   ++nX
   // IF ( gSamokol != "D" .AND. !glDistrib )
   // IF !glDistrib
   @ box_x_koord() + nX, box_y_koord() + 2 SAY get_serbr_opis() + " " GET _serbr PICT "@S15" WHEN _podbr <> " ."
   // ENDIF

   _tip_cijene := "1"

   IF ( gVarC $ "123" .AND. _idtipdok $ "10#12#20#21#25" )
      @ box_x_koord() + nX, box_y_koord() + 59 SAY "Cijena (1/2/3):" GET _tip_cijene
   ENDIF

   IF hFaktParams[ "fakt_opis_stavke" ]
      ++nX
      @ box_x_koord() + nX, box_y_koord() + 2 SAY "Opis:" GET cOpis PICT "@S50"
   ENDIF

   IF hFaktParams[ "ref_lot" ]
      ++nX
      @ box_x_koord() + nX, box_y_koord() + 2 SAY "REF:" GET cRefBroj PICT "@S10"
      @ box_x_koord() + nX, box_y_koord() + 2 SAY "/ LOT:" GET cLotBroj PICT "@S10"
   ENDIF

   nX += 3
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Količina: "  GET _kolicina PICT fakt_pic_kolicina() VALID fakt_v_kolicina( _tip_cijene )


   // IF gSamokol != "D"

   @ box_x_koord() + nX, Col() + 2 SAY IF( _idtipdok $ "13#23" .AND. ( gVar13 == "2" .OR. glCij13Mpc ), ;
      "MPC.s.PDV", "Cijena (" + AllTrim( valuta_domaca_skraceni_naziv() ) + ")" ) GET _cijena PICT fakt_pic_cijena() ;
      WHEN  _podbr <> " ." ;
      VALID fakt_valid_cijena( _cijena, _idtipdok, lFaktNoviRec )


   IF ( PadR( _dindem, 3 ) <> PadR( valuta_domaca_skraceni_naziv(), 3 ) )
      @ box_x_koord() + nX, Col() + 2 SAY "Pr"  GET cConvertDN ;
         PICT "@!"  VALID fakt_valid_preracun_cijene_u_valutu_dokumenta( @cConvertDN, _dindem, _datdok, @_cijena )
   ENDIF

   IF !( _idtipdok $ "12#13" ) .OR. ( _idtipdok == "12" .AND. gV12Por == "D" )

      @ box_x_koord() + nX, Col() + 2 SAY "Rabat:" GET _rabat PICT fakt_pic_cijena()  ;
         WHEN _podbr <> " ." .AND. ! _idtipdok $ "15"

      @ box_x_koord() + nX, Col() + 1 GET _tip_rabat PICT "@!" ;
         WHEN {|| _tip_rabat := "%", ! _idtipdok $ "11#27#15" .AND. _podbr <> " ." } ;
         VALID _tip_rabat $ "% AUCI" .AND. fakt_unos_v_rabat( _tip_rabat )

   ENDIF

   // ENDIF

   READ

   IF lAvansniRacun == "D"
      _idvrstep := "AV"
   ENDIF

   ESC_RETURN 0

   lOdabirFaktTxt := .T.

   // IF _IdTipDok $ "13" .OR. gSamoKol == "D"
   // lOdabirFaktTxt := .F.
   // ENDIF

   IF _idtipdok == "12"
      // IF IsKomision( _idpartner )
      // lOdabirFaktTxt := .T.
      // ELSE
      lOdabirFaktTxt := .F.
      // ENDIF
   ENDIF

   IF lOdabirFaktTxt
      fakt_unos_set_fakt_txt_opis( @hFaktTxt[ "txt2" ], s_nFaktUnosRedniBroj, _idtipdok, _idpartner )
   ENDIF

   IF ( _podbr == " ." .OR. roba->tip = "U" .OR. ( s_nFaktUnosRedniBroj == 1 .AND. Val( _podbr ) < 1 ) )
      _txt := fakt_ftxt_encode_5( hFaktTxt )
   ELSE
      _txt := ""
   ENDIF

   _rbr := rbr_u_char( s_nFaktUnosRedniBroj )

   IF hFaktParams[ "fakt_opis_stavke" ]
      hFaktItemsAttributi[ "opis" ] := cOpis
   ENDIF
   IF hFaktParams[ "ref_lot" ]
      hFaktItemsAttributi[ "ref" ] := cRefBroj
      hFaktItemsAttributi[ "lot" ] := cLotBroj
   ENDIF

#ifdef F18_EXPERIMENT
   IF AllTrim( _rbr ) == "1"
      show_last_racun( _idpartner, _destinacija, _idroba )
   ENDIF
#endif

   RETURN 1




STATIC FUNCTION fakt_unos_prikaz_marza()

   IF field->IdTipDok == "10" .OR. field->IdTipDok == "20"
      RETURN Transform( get_realizovana_marza( NIL, field->idRoba, field->datDok, field->Cijena * ( 1 - field->Rabat / 100 ) ), "999.99" )
   ENDIF

   RETURN "000.00"


STATIC FUNCTION fakt_unos_prikaz_nab_cj()

   IF field->IdTipDok == "10" .OR. field->IdTipDok == "20"
      RETURN Transform( get_nabavna_cijena_from_konto_roba_stanje( NIL, field->idRoba, field->DatDok ), "99999.999" )
   ENDIF

   RETURN "00000.000"




STATIC FUNCTION fakt_valid_partner( cIdPartner, nXPartner, nYPartner )

   p_partner( @cIdPartner )
   IF Empty( cIdPartner )
      RETURN .F.
   ENDIF

   ispisi_partn( cIdPartner, nXPartner, nYPartner + 18 )

   IF gFaktPrikazFinSaldaKupacDobavljac == "D"
      fin_partner_prikaz_stanja_ekran( PadR( _idpartner, 6 ), gFinKtoDug, gFinKtoPot )
   ENDIF

   RETURN .T.

STATIC FUNCTION fakt_pripr_keyhandler( Ch )

   LOCAL hFaktPriprRec, nI, nJ, nDbfArea

   // LOCAL _ret
   LOCAL cPom
   LOCAL aFaktAzuriraniDokumenti := {}
   LOCAL nFiskalDeviceId := 0
   LOCAL hFiskalDevParams
   LOCAL lFiskalniStampati := fiscal_opt_active()
   LOCAL hFaktParams := fakt_params()
   LOCAL _dok := hb_Hash()
   LOCAL oAttr
   LOCAL _hAttrId
   LOCAL cIdFirma, cIdTipDok, cBrDok
   LOCAL cKeyboardSekvenca

   select_fakt_pripr()

   DO CASE

/* budalestina
   CASE __fiscal_marker == .T.

      __fiscal_marker := .F.

      IF !lFiskalniStampati
         RETURN DE_CONT
      ENDIF

      IF fakt_pripr->( RecCount() ) <> 0
         MsgBeep( "Priprema nije prazna, štampa fisk.racuna nije moguca!" )
         RETURN DE_CONT
      ENDIF

      IF Pitanje(, "Odštampati račun na fiskalni printer ?", "D" ) == "N"
         RETURN DE_CONT
      ENDIF

      nFiskalDeviceId := odaberi_fiskalni_uredjaj( __tip_dok, .F., .F. )

      IF nFiskalDeviceId > 0

         hFiskalDevParams := get_fiscal_device_params( nFiskalDeviceId, my_user() )
         IF hFiskalDevParams == NIL
            RETURN DE_CONT
         ENDIF

      ELSE
         RETURN DE_CONT
      ENDIF

      IF hFiskalDevParams[ "print_fiscal" ] == "N"
         MsgBeep( "Nije Vam dozvoljena aOpcija za stampu fiskalnih računa !" )
         RETURN DE_CONT
      ENDIF

      MsgO( "Štampa na fiskalni printer u toku..." )

      fakt_fiskalni_racun( __id_firma, __tip_dok, __br_dok, .F., hFiskalDevParams )

      MsgC()

      select_fakt_pripr()

      IF hFiskalDevParams[ "print_a4" ] $ "D#G#X"

         IF hFiskalDevParams[ "print_a4" ] $ "D#X" .AND. Pitanje(, "Štampati fakturu ?", "N" ) == "D"
            fakt_stamp_txt_dokumenta( __id_firma, __tip_dok, __br_dok )
            close_open_fakt_tabele()
            select_fakt_pripr()
         ENDIF

         IF hFiskalDevParams[ "print_a4" ] $ "G#X" .AND. Pitanje(, "Štampati LibreOffice fakturu ?", "N" ) == "D"
            fakt_stampa_dok_odt( __id_firma, __tip_dok, __br_dok )
            close_open_fakt_tabele()
            select_fakt_pripr()
         ENDIF

         RETURN DE_REFRESH

      ENDIF

      RETURN DE_CONT
*/

   CASE Upper( Chr( Ch ) ) == "T"

      _total_dokumenta()
      RETURN DE_REFRESH

   CASE ( Ch == K_CTRL_T )

      IF fakt_brisi_stavku_pripreme() == 1
         RETURN DE_REFRESH
      ELSE
         RETURN DE_CONT
      ENDIF

   CASE Ch == K_ENTER

      IF Eof()
         MsgBeep( "Priprema prazna" )
         RETURN DE_CONT
      ENDIF

      IF fakt_ispravi_dokument( hFaktParams )
         RETURN DE_REFRESH
      ELSE
         RETURN DE_CONT
      ENDIF

   CASE Ch == K_CTRL_A

      fakt_prodji_kroz_stavke( hFaktParams )
      RETURN DE_REFRESH

   CASE Ch == K_CTRL_N

      fakt_unos_nove_stavke()
      RETURN DE_REFRESH

   CASE Ch == K_CTRL_P

      fakt_print_dokument()

#ifdef TEST
      push_test_tag( "FAKT_CTRLP_END" )
#endif

      RETURN DE_REFRESH

   CASE Ch == iif( is_mac(), Asc( "P" ), K_ALT_P )

      fakt_unos_set_broj_dokumenta()

      IF !CijeneOK( "Stampanje" )
         RETURN DE_REFRESH
      ENDIF

      fakt_stampa_dok_odt( NIL, NIL, NIL )

      close_open_fakt_tabele()

#ifdef TEST
      push_test_tag( "FAKT_ALTP_END" )
#endif

      RETURN DE_REFRESH


   CASE Ch == K_ALT_L

      my_close_all_dbf()
      fakt_labeliranje_barkodova()
      close_open_fakt_tabele()

#ifdef TEST
      push_test_tag( "FAKT_ALTP_END" )
#endif

      RETURN DE_REFRESH

   CASE is_key_alt_a( Ch )

      fakt_unos_set_broj_dokumenta()

      IF fakt_postoji_li_rupa_u_brojacu( field->idfirma, field->idtipdok, field->brdok ) > 0
         RETURN DE_REFRESH
      ENDIF

      cIdFirma  := field->idfirma
      cIdTipDok := field->idtipdok
      cBrDok  := field->brdok

      IF !CijeneOK( "Azuriranje" )
         RETURN DE_REFRESH
      ENDIF

      IF !valid_dodaj_taksu_za_gorivo()
         RETURN DE_REFRESH
      ENDIF

      my_close_all_dbf()

      aFaktAzuriraniDokumenti := fakt_azuriraj_dokumente_u_pripremi()

      close_open_fakt_tabele()

      IF lFiskalniStampati .AND. cIdTipDok $ "10#11" .AND. aFaktAzuriraniDokumenti <> NIL .AND. Len( aFaktAzuriraniDokumenti ) == 1

         // cIdFirma := aFaktAzuriraniDokumenti[ 1, 1 ]
         // cIdTipDok := aFaktAzuriraniDokumenti[ 1, 2 ]
         // cBrDok := aFaktAzuriraniDokumenti[ 1, 3 ]

         // __fiscal_marker := .T.

         // IF fakt_pripr->( RecCount() ) <> 0
         // MsgBeep( "Priprema nije prazna, štampa fisk.racuna nije moguca!" )
         // RETURN DE_CONT
         // ENDIF

         IF Pitanje(, "Odštampati račun " + cIdFirma + "-" + cIdTipDok + "-" + AllTrim( cBrDok ) +  " na fiskalni printer ?", "D" ) == "N"
            RETURN DE_REFRESH
         ENDIF

         nFiskalDeviceId := odaberi_fiskalni_uredjaj( cIdTipDok, .F., .F. )

         IF nFiskalDeviceId > 0
            hFiskalDevParams := get_fiscal_device_params( nFiskalDeviceId, my_user() )
            IF hFiskalDevParams == NIL
               RETURN DE_REFRESH
            ENDIF
         ELSE
            RETURN DE_REFRESH
         ENDIF

         IF hFiskalDevParams[ "print_fiscal" ] == "N"
            MsgBeep( "Nije Vam dozvoljena aOpcija za štampu fiskalnih računa !" )
            RETURN DE_REFRESH
         ENDIF

         MsgO( "Štampa " + cIdFirma + "-" + cIdTipDok + "-" + AllTrim( cBrDok ) + " na fiskalni printer u toku..." )
         fakt_fiskalni_racun( cIdFirma, cIdTipDok, cBrDok, .F., hFiskalDevParams )
         MsgC()

         select_fakt_pripr()

         IF hFiskalDevParams[ "print_a4" ] $ "D#G#X"

            IF hFiskalDevParams[ "print_a4" ] $ "D#X" .AND. Pitanje(, "Štampati fakturu " + cIdFirma + "-" + cIdTipDok + "-" + cBrDok + " ?", "N" ) == "D"
               fakt_stamp_txt_dokumenta( cIdFirma, cIdTipDok, cBrDok )
               close_open_fakt_tabele()
               select_fakt_pripr()
            ENDIF

            IF hFiskalDevParams[ "print_a4" ] $ "G#X" .AND. Pitanje(, "Štampati LibreOffice fakturu " + cIdFirma + "-" + cIdTipDok + "-" + cBrDok + "?", "N" ) == "D"
               fakt_stampa_dok_odt( cIdFirma, cIdTipDok, cBrDok )
               close_open_fakt_tabele()
               select_fakt_pripr()
            ENDIF

         ENDIF

         RETURN DE_REFRESH

      ENDIF

      RETURN DE_REFRESH


   CASE Ch == k_ctrl_f9()

      fakt_brisanje_pripreme()
      RETURN DE_REFRESH


   CASE Ch == K_F5

      fakt_kzb()
      RETURN DE_CONT


   CASE Upper( Chr( Ch ) ) == "O"

      nDbfArea := Select()

      IF reccount2() <> 0
         fakt_generisi_racun_iz_pripreme()
      ELSE
         aFaktAzuriraniDokumenti := FaktDokumenti():New()
         aFaktAzuriraniDokumenti:pretvori_otpremnice_u_racun()
      ENDIF

      SELECT ( nDbfArea )
      RETURN DE_REFRESH

   CASE Upper( Chr( Ch ) ) == "A"

      // PRIVATE _broj_entera := 30

      FOR nI := 1 TO Int( RecCount2() / 15 ) + 1
         cKeyboardSekvenca := Chr( K_CTRL_A )
         FOR nJ := 1 TO Min( RecCount2(), 15 ) * 20
            cKeyboardSekvenca += s_cKeyboardEnterSequence
         NEXT
         KEYBOARD cKeyboardSekvenca
      NEXT

      RETURN DE_REFRESH

      // ostale aOpcije nad dokumentom

   CASE Ch == iif( is_mac(), Asc( "0" ), K_F10 )

      popup_fakt_unos_dokumenta()
      SetLastKey( K_CTRL_PGDN )
      RETURN DE_REFRESH

   CASE Ch == K_F11

      Pripr9View()
      select_fakt_pripr()
      GO TOP

      RETURN DE_REFRESH


   CASE Ch == K_ALT_N

      fakt_print_narudzbenica_priprema()
      RETURN DE_REFRESH


   CASE Ch == K_ALT_E

      IF Pitanje(, "Exportovati dokument u LibreOffice ?", "D" ) == "D"
         fakt_export_dokument_lo()
         close_open_fakt_tabele()
         select_fakt_pripr()
         GO TOP
      ENDIF

      RETURN DE_CONT

   ENDCASE

   RETURN DE_CONT




STATIC FUNCTION fakt_prodji_kroz_stavke( hFaktParams )

   LOCAL nDug
   LOCAL nRecNo, hFaktPriprRec
   LOCAL _items_atrib
   LOCAL hPostojeciFaktRec

   PushWA()

   select_fakt_pripr()

   Box( "pst", f18_max_rows() - 5, f18_max_cols() - 10, .F. )

   nDug := 0

   DO WHILE !Eof()

      SKIP
      nRecNo := RecNo()
      SKIP - 1

      set_global_vars_from_dbf( "_" )

      hPostojeciFaktRec := hb_Hash()
      hPostojeciFaktRec[ "idfirma" ] := _idfirma
      hPostojeciFaktRec[ "idtipdok" ] := _idtipdok
      hPostojeciFaktRec[ "brdok" ] := _brdok
      hPostojeciFaktRec[ "rbr" ] := _rbr

      _items_atrib := hb_Hash()

      IF hFaktParams[ "fakt_opis_stavke" ]
         _items_atrib[ "opis" ] := get_fakt_attr_opis( hPostojeciFaktRec, .F. )
      ENDIF

      IF hFaktParams[ "ref_lot" ]
         _items_atrib[ "ref" ] := get_fakt_attr_ref( hPostojeciFaktRec, .F. )
         _items_atrib[ "lot" ] := get_fakt_attr_lot( hPostojeciFaktRec, .F. )
      ENDIF

      _podbr := Space( 2 )
      s_nFaktUnosRedniBroj := rbr_u_num( _rbr )

      BoxCLS()

      IF edit_fakt_priprema( .F., @_items_atrib ) == 0
         EXIT
      ENDIF

      nDug += Round( _cijena * _kolicina * fakt_preracun_cijene() * ;
         ( 1 - _rabat / 100 ) * ( 1 + _porez / 100 ), fakt_zaokruzenje() )

      @ box_x_koord() + 23, box_y_koord() + 2 SAY "ZBIR DOKUMENTA:"
      @ box_x_koord() + 23, Col() + 1 SAY nDug PICT "9 999 999 999.99"

      InkeySc( 10 )

      select_fakt_pripr()
      fakt_dodaj_ispravi_stavku( .F., hPostojeciFaktRec, _items_atrib )
      fakt_promjena_cijene_u_sif()

      GO nRecNo

   ENDDO

   PopWA()
   BoxC()

   RETURN .T.


// -------------------------------------------------------------------------------------------------------
// dodaje ili ispravlja stavku u tabeli FAKT_PRIPR
// lNovi - logički uslov nova stavka .T. ili .F.
// hFaktStavkaAttribut - hash matrica sa podacima stavke ( idfirma, idtipdok, brdok, rbr ) prije upisivanja u DBF
// hFaktItemsAttributi - hash matrica sa atributima definisanim na stavci kod unosa
// -------------------------------------------------------------------------------------------------------
STATIC FUNCTION fakt_dodaj_ispravi_stavku( lNovi, hFaktStavkaAttribut, hFaktItemsAttributi )

   LOCAL oAttr, hFaktPriprRec, _item_after_hash
   LOCAL hFaktStavkaAttributNovi := hb_Hash()

   IF lNovi == .T.
      APPEND BLANK
   ENDIF

   hFaktPriprRec := get_hash_record_from_global_vars( "_" ) // dodaj zapis u tabelu FAKT_PRIPR
   dbf_update_rec( hFaktPriprRec, .F. )

   // hash matrica koja sadrži update-ovan zapis
   hFaktStavkaAttributNovi[ "idfirma" ] := fakt_pripr->idfirma
   hFaktStavkaAttributNovi[ "idtipdok" ] := fakt_pripr->idtipdok
   hFaktStavkaAttributNovi[ "brdok" ] := fakt_pripr->brdok
   hFaktStavkaAttributNovi[ "rbr" ] := fakt_pripr->rbr

   // ažuriraj atribute u FAKT_FAKT_ATTRUTI
   oAttr := DokAttr():new( "fakt", F_FAKT_ATTR )
   oAttr:hAttrId := hFaktStavkaAttributNovi

   IF !lNovi .AND. ( hFaktStavkaAttribut[ "rbr" ] <> hFaktStavkaAttributNovi[ "rbr" ] )
      oAttr:hAttrId[ "update_rbr" ] := hFaktStavkaAttribut[ "rbr" ]
      oAttr:update_attr_rbr()
   ENDIF

   oAttr:push_attr_from_mem_to_dbf( hFaktItemsAttributi )

   fakt_promjena_cijene_u_sif()

   // nešto što mjenja sve stavke dokumenta u pripremi ako se promjeni prva stavka
   // promjena broja dokumenta i slično
   IF s_nFaktUnosRedniBroj == 1 .AND. !lNovi
      izmjeni_sve_stavke_dokumenta( hFaktStavkaAttribut, hFaktStavkaAttributNovi )
   ENDIF

   RETURN .T.



STATIC FUNCTION fakt_ispravi_dokument( hFaktParams )

   LOCAL lRet := .T.
   LOCAL _items_atrib := hb_Hash()
   LOCAL hPostojeciFaktRec, _item_after

   Box( "ist", f18_max_rows() - 5, f18_max_cols() - 10, .F. )

   set_global_vars_from_dbf( "_" )

   hPostojeciFaktRec := hb_Hash()
   hPostojeciFaktRec[ "idfirma" ] := _idfirma
   hPostojeciFaktRec[ "idtipdok" ] := _idtipdok
   hPostojeciFaktRec[ "brdok" ] := _brdok
   hPostojeciFaktRec[ "rbr" ] := _rbr

   s_nFaktUnosRedniBroj := rbr_u_num( _rbr )
   IF hFaktParams[ "fakt_opis_stavke" ]
      _items_atrib[ "opis" ] := get_fakt_attr_opis( hPostojeciFaktRec, .F. )
   ENDIF

   IF hFaktParams[ "ref_lot" ]
      _items_atrib[ "ref" ] := get_fakt_attr_ref( hPostojeciFaktRec, .F. )
      _items_atrib[ "lot" ] := get_fakt_attr_lot( hPostojeciFaktRec, .F. )
   ENDIF

   IF edit_fakt_priprema( .F., @_items_atrib ) == 0
      lRet := .F.
   ELSE
      fakt_dodaj_ispravi_stavku( .F., hPostojeciFaktRec, _items_atrib )
      lRet := .T.
   ENDIF

   BoxC()

   TB:RefreshAll()
   DO WHILE !TB:stable
      Tb:stabilize()
   ENDDO

   RETURN lRet




STATIC FUNCTION fakt_unos_nove_stavke()

   LOCAL _items_atrib
   LOCAL _total := 0

   SELECT fakt_pripr
   GO TOP
   DO WHILE !Eof()
      _total += Round( fakt_pripr->cijena * fakt_pripr->kolicina * fakt_preracun_cijene() * ( 1 - fakt_pripr->rabat / 100 ) * ( 1 + fakt_pripr->porez / 100 ), fakt_zaokruzenje() )
      SKIP
   ENDDO
   GO BOTTOM

   Box( "knjn", f18_max_rows() - 5, f18_max_cols() - 10, .F., "Unos nove stavke" )

   DO WHILE .T.

      set_global_vars_from_dbf( "_" )
      _podbr := Space( 2 )

      IF AllTrim( _podbr ) == "." .AND. Empty( _idroba )
         s_nFaktUnosRedniBroj := rbr_u_num( _rbr )
         _podbr := " 1"

      ELSEIF _podbr >= " 1"
         s_nFaktUnosRedniBroj := rbr_u_num( _rbr )
         _podbr := Str( Val( _podbr ) + 1, 2, 0 )

      ELSE
         s_nFaktUnosRedniBroj := rbr_u_num( _rbr ) + 1
         _podbr := "  "
      ENDIF

      BoxCLS()

      _items_atrib := hb_Hash()

      IF edit_fakt_priprema( .T., @_items_atrib ) == 0
         EXIT
      ENDIF

      _total += Round( _cijena * _kolicina * fakt_preracun_cijene() * ( 1 - _rabat / 100 ) * ( 1 + _porez / 100 ), fakt_zaokruzenje() )

      @ box_x_koord() + f18_max_rows() - 11, box_y_koord() + 2 SAY "ZBIR DOKUMENTA:"
      @ box_x_koord() + f18_max_rows() - 11, Col() + 2 SAY _total PICT "9 999 999 999.99"

      InkeySc( 10 )

      select_fakt_pripr()
      fakt_dodaj_ispravi_stavku( .T., NIL, _items_atrib )

   ENDDO

   BoxC()

   RETURN .T.


FUNCTION fakt_zaokruzenje()
   RETURN 2





#ifdef F18_EXPERIMENT
// ----------------------------------------------------------------------------------------
STATIC FUNCTION show_last_racun( cIdPartner, cDestinacija, cIdRoba )

   cRacun := "00000000"
   cDestinacija := AllTrim( cDestinacija )
   select_fakt_pripr()
   PushWA()

   GO TOP

   Box( , 6, 100 )
   DO WHILE !Eof()
      @ box_x_koord() + 1, box_y_koord() + 2 SAY "Partner: " + cIdPartner
      @ box_x_koord() + 2, box_y_koord() + 2 SAY "Destinacija: " + cDestinacija
      @ box_x_koord() + 3, box_y_koord() + 2 SAY "Rbr: " + field->rbr
      @ box_x_koord() + 4, box_y_koord() + 2 SAY "Roba: " + field->idroba + " kol: " + AllTrim( Str( field->kolicina, 6, 2 ) )
      @ box_x_koord() + 5, box_y_koord() + 2 SAY8 "Raniji račun: " + fakt_za_destinaciju( cIDPartner, cDestinacija, field->idroba )

      Inkey( 0 )
      SKIP
   ENDDO
   PopWa()
   BoxC()

   RETURN .T.



FUNCTION fakt_za_destinaciju( cIdPartner, cDestinacija, cIdRoba )

   LOCAL cQuery, oRez
   LOCAL cBrDok, oRow

   cQuery := "SELECT brdok FROM " + f18_sql_schema( "fakt_fakt" ) + ;
      " WHERE idtipdok='10' AND kolicina>0  AND txt like '%" + cDestinacija + "%' AND idpartner=" + sql_quote( cIdPartner )

   oRez := run_sql_query( cQuery )
   IF sql_error_in_query )( oRez )
      RETURN -1
   ENDIF

   cBrDok := ""
   DO WHILE !oRez:Eof()
      oRow := oRez:getRow()
      cBrDok += oRow:FieldGet( 1 ) + "/"
      oRez:skip()
   ENDDO

   RETURN cBrDok

// ----------------------------------------------------------------------------------------
#endif


STATIC FUNCTION fakt_print_dokument()

   LOCAL aFaktDokumenti

   fakt_unos_set_broj_dokumenta()

   aFaktDokumenti := fakt_dokumenti_pripreme_u_matricu()

   IF Len( aFaktDokumenti ) == 0
      MsgBeep( "Dokument u pripremi već ažuriran!" )
   ENDIF

   DokAttr():New( "fakt", F_FAKT_ATTR ):cleanup_attrs( F_FAKT_PRIPR, aFaktDokumenti )

   close_open_fakt_tabele()

   IF !CijeneOK( "Stampanje" )
      RETURN DE_REFRESH
   ENDIF

   gPtxtC50 := .F.

   fakt_stamp_txt_dokumenta( NIL, NIL, NIL )
   close_open_fakt_tabele()

   RETURN .T.




STATIC FUNCTION _f_idpm( cIdPm )

   cIdPM := Upper( cIdPM )

   RETURN .T.



FUNCTION valid_rok_placanja( nRokPl, dDatDok, dDatPl,  cVarijanta01X, lNovi )

   LOCAL lRokPlacanjaMozeNula := .T.
   LOCAL nRokPlacanjaDefault := fakt_rok_placanja_dana()

   // ako je dozvoljen rok.placanja samo > 0
   IF gVFRP0 == "D"
      lRokPlacanjaMozeNula := .F.
   ENDIF

   IF cVarijanta01X == "0"

      IF nRokPl < 0
         RETURN .T.
      ENDIF

      IF !lNovi
         IF Empty( dDatPl )
            nRokPl := 0
         ELSE
            nRokPl := dDatpl - dDatdok
         ENDIF
      ENDIF

   ELSEIF cVarijanta01X == "1"

      IF !lRokPlacanjaMozeNula
         IF nRokPl < 1
            MsgBeep( "Obavezno unjeti broj dana !" )
            RETURN .F.
         ENDIF
      ENDIF

      IF nRokPl < 0
         // moras unijeti pozitivnu vrijednost ili 0
         MsgBeep( "Unijeti broj dana !" )
         RETURN .F.
      ENDIF

      IF nRokPl = 0 .AND. nRokPlacanjaDefault < 0
         dDatPl := CToD( "" )
      ELSE
         dDatPl := dDatdok + nRokPl
      ENDIF

   ELSE

      IF Empty( dDatpl )
         nRokPl := 0
      ELSE
         nRokPl := dDatpl - dDatdok
      ENDIF

   ENDIF

   ShowGets()

   RETURN .T.



FUNCTION ArgToStr( xArg )

   IF ( xArg == NIL )
      RETURN "NIL"
   ELSE
      RETURN "'" + xArg + "'"
   ENDIF



// --------------------------------------------------
// Prerada cijene
// Ako je u polje SERBR unesen podatak KJ/KG iznos se
// dobija kao KOLICINA * CIJENA * fakt_preracun_cijene()
// varijanta R - Rudnik
// --------------------------------------------------

FUNCTION fakt_preracun_cijene()

   LOCAL _ser_br := AllTrim( _field->serbr )
   LOCAL nRet := 1

   IF !Empty( _ser_br ) .AND. _ser_br != "*" .AND. is_fakt_ugalj()
      nRet := Val( nRet ) / 1000
   ENDIF

   RETURN nRet



// Stampa dokumenta ugovor o rabatu
FUNCTION StUgRabKup()

   lUgRab := .T.
   lSSIP99 := .F.
   // StDok2()
   lUgRab := .F.

   RETURN .T.




/*
FUNCTION IspisBankeNar( cBanke )

   LOCAL aaOpc

   o_banke()
   aaOpc := TokToNiz( cBanke, "," )
   cVrati := ""

   SELECT banke
   SET ORDER TO TAG "ID"
   FOR i := 1 TO Len( aaOpc )
  --    HSEEK SubStr( aaOpc[ i ], 1, 3 )
      IF Found()
         cVrati += AllTrim( banke->naz ) + ", " + AllTrim( banke->adresa ) + ", " + AllTrim( banke->mjesto ) + ", " + AllTrim( aaOpc[ i ] ) + "; "
      ELSE
         cVrati += ""
      ENDIF
   NEXT
   SELECT partn

   RETURN cVrati
*/



/* JeStorno10()
 *     True je distribucija i TipDokumenta=10  i krajnji desni dio broja dokumenta="S"

FUNCTION JeStorno10()
--   RETURN glDistrib .AND. _idtipdok == "10" .AND. Upper( Right( Trim( _BrDok ), 1 ) ) == "S"

*/

/* RabPor10()


FUNCTION RabPor10()

   LOCAL nArr := Select()

  -- seek_fakt( _idfirma, "10", Left( _brdok, gNumDio ) )

   DO WHILE !Eof() .AND.  _idfirma + "10" + Left( _brdok, gNumDio ) == idfirma + idtipdok + Left( brdok, gNumDio ) .AND. _idroba <> idroba
      SKIP 1
   ENDDO

   IF _idfirma + "10" + Left( _brdok, gNumDio ) == idfirma + idtipdok + Left( brdok, gNumDio )
      _rabat    := rabat
      _porez    := porez
      // i cijenu, sto da ne?
      _cijena   := cijena
   ELSE
      MsgBeep( "Izabrana roba ne postoji u fakturi za storniranje!" )
   ENDIF
   SELECT ( nArr )

   RETURN .T.

*/


STATIC FUNCTION popup_fakt_unos_dokumenta()

   LOCAL aOpc[ 6 ]
   LOCAL aOpcExe := {}
   LOCAL nIzbor := 1
   LOCAL am_x := box_x_koord(), am_y := box_y_koord()

   aOpc[ 1 ] := "1. generacija faktura na osnovu ugovora            "
   AAdd( aOpcExe, {||  fakt_meni_gen_ugov() } )

   aOpc[ 2 ] := "2. sredjivanje rednih br.stavki dokumenta"
   AAdd( aOpcExe, {||  fakt_sredi_redni_broj_u_pripremi() } )

   aOpc[ 3 ] := "3. ispravka teksta na kraju fakture"
   AAdd( aOpcExe, {||  fakt_ispravka_ftxt() } )

   aOpc[ 4 ] := "4. svedi protustavkom vrijednost dokumenta na 0"
   AAdd( aOpcExe, {||  fakt_svedi_prostavkom_vrijednost_dokumenta_na_0() } )
   aOpc[ 5 ] := "5. priprema => smece"
   AAdd( aOpcExe, {||   azuriraj_smece() } )
   aOpc[ 6 ] := "6. smece    => priprema"
   AAdd( aOpcExe, {||  povrat_smece() } )

   my_close_all_dbf()

   f18_menu( "fakt0", .F., nIzbor, aOpc, aOpcExe )


   box_x_koord( am_x )
   box_y_koord( am_y )

   close_open_fakt_tabele()
   select_fakt_pripr()

   GO BOTTOM

   RETURN .T.




STATIC FUNCTION fakt_ispravka_ftxt()

   select_fakt_pripr()
   GO TOP
   // lDoks2 := .F. // ( my_get_from_ini( "FAKT", "Doks2", "N", KUMPATH ) == "D" )
   IF Val( fakt_pripr->rbr ) <> 1
      MsgBeep( "U pripremi se ne nalazi dokument" )
   ELSE
      fakt_ispravka_ftxt()
   ENDIF

   RETURN .T.


STATIC FUNCTION fakt_svedi_prostavkom_vrijednost_dokumenta_na_0()

   LOCAL nDug, cDN
   LOCAL GetList := {}

   o_fakt_pripr()
   GO TOP
   nDug := 0
   DO WHILE !Eof()
      scatter()
      nDug += Round( _Cijena * _kolicina * ( 1 - _Rabat / 100 ), fakt_zaokruzenje() )
      SKIP
   ENDDO


   _idroba := Space( 10 )
   _kolicina := 1
   _rbr := Str( rbr_u_num( _Rbr ) + 1, 3, 0 )
   _rabat := 0

   cDN := "D"
   Box(, 4, 60 )
   @ box_x_koord() + 1, box_y_koord() + 2 SAY "Artikal koji se stvara:" GET _idroba  PICT "@!" VALID P_Roba( @_idroba )
   @ box_x_koord() + 2, box_y_koord() + 2 SAY "Kolicina" GET _kolicina VALID {|| _kolicina <> 0 } PICT fakt_pic_kolicina()
   READ

   IF LastKey() == K_ESC
      BoxC()
      my_close_all_dbf()
      RETURN DE_CONT
   ENDIF


   _cijena := nDug / _kolicina
   IF _cijena < 0
      _Cijena := -_cijena
   ELSE
      _kolicina := -_kolicina
   ENDIF
   @ box_x_koord() + 3, box_y_koord() + 2 SAY "Cijena" GET _cijena  PICT fakt_pic_cijena()
   cDN := "D"
   @ box_x_koord() + 4, box_y_koord() + 2 SAY8 "Staviti cijenu u šifarnik ?" GET cDN VALID cDN $ "DN" PICT "@!"
   READ

   IF cDN == "D"
      IF roba_update_vpc( _idroba, _cijena )
         info_bar( "roba", "ROBA: " + _idroba + " update vpc=" + AllTrim( Str( nCijena, 10, 2 ) ) )
      ELSE
         error_bar( "roba", "ROBA: " + _idroba + " update vpc ERROR?!" )
      ENDIF
      SELECT fakt_pripr
   ENDIF

   IF LastKey() = K_ESC
      BoxC()
      my_close_all_dbf()
      RETURN DE_CONT
   ENDIF
   APPEND BLANK
   Gather()
   BoxC()

   RETURN .T.


// --------------------------------------------------------------------
// izmjeni sve stavke dokumenta prema tekucoj stavci
// ovo treba da radi samo na stavci broj 1
// --------------------------------------------------------------------

STATIC FUNCTION izmjeni_sve_stavke_dokumenta( hOldDok, hNewDok )

   LOCAL _old_firma := hOldDok[ "idfirma" ]
   LOCAL _old_brdok := hOldDok[ "brdok" ]
   LOCAL _old_tipdok := hOldDok[ "idtipdok" ]
   LOCAL hFaktPriprRec, hRec, nTekRec
   LOCAL _new_firma := hNewDok[ "idfirma" ]
   LOCAL _new_brdok := hNewDok[ "brdok" ]
   LOCAL _new_tipdok := hNewDok[ "idtipdok" ]
   LOCAL oAttr

   // treba da imam podatke koja je stavka bila prije korekcije
   // kao i koja je nova
   // misli se na "idfirma + tipdok + brdok"

   select_fakt_pripr()
   GO TOP

   // uzmi podatke sa izmjenjene stavke
   SEEK _new_firma + _new_tipdok + _new_brdok // fakt_pripr

   IF !Found()
      RETURN .F.
   ENDIF

   hRec := dbf_get_rec()

   // zatim pronadji ostale stavke bivseg dokumenta
   GO TOP
   SEEK _old_firma + _old_tipdok + _old_brdok // fakt_pripr

   IF !Found()
      RETURN .F.
   ENDIF

   DO WHILE !Eof() .AND. field->idfirma + field->idtipdok + field->brdok == ;
         _old_firma + _old_tipdok + _old_brdok

      SKIP 1
      nTekRec := RecNo()
      SKIP -1

      // napravi zamjenu podataka
      hFaktPriprRec := dbf_get_rec()
      hFaktPriprRec[ "idfirma" ] := hRec[ "idfirma" ]
      hFaktPriprRec[ "idtipdok" ] := hRec[ "idtipdok" ]
      hFaktPriprRec[ "brdok" ] := hRec[ "brdok" ]
      hFaktPriprRec[ "datdok" ] := hRec[ "datdok" ]
      hFaktPriprRec[ "idpartner" ] := hRec[ "idpartner" ]
      hFaktPriprRec[ "dindem" ] := hRec[ "dindem" ]

      dbf_update_rec( hFaktPriprRec )

      GO ( nTekRec )

   ENDDO
   GO TOP

   oAttr := DokAttr():new( "fakt", F_FAKT_ATTR )
   oAttr:open_attr_dbf()

   GO TOP

   DO WHILE !Eof()

      SKIP 1
      nTekRec := RecNo()
      SKIP -1

      hFaktPriprRec := dbf_get_rec()

      hFaktPriprRec[ "idfirma" ] := hRec[ "idfirma" ]
      hFaktPriprRec[ "idtipdok" ] := hRec[ "idtipdok" ]
      hFaktPriprRec[ "brdok" ] := hRec[ "brdok" ]

      dbf_update_rec( hFaktPriprRec )

      GO ( nTekRec )

   ENDDO
   // zatvori atribute
   USE

   select_fakt_pripr()
   GO TOP

   RETURN .T.



// -----------------------------------------------
// izvuci mi total dokumenta
// -----------------------------------------------
STATIC FUNCTION _total_dokumenta()

   LOCAL nXBox, nYBox
   LOCAL nX := 1
   LOCAL nLeft := 20
   LOCAL hFaktDokTotal := hb_Hash()

   // LOCAL nFaktDocTotal := 0
   LOCAL nDbfArea := Select()
   LOCAL cValuta

   IF fakt_pripr->( RecCount() ) == 0 .OR. !( fakt_pripr->idtipdok $ "10#11#12#20" )
      RETURN .F.
   ENDIF

   nXBox := f18_max_rows() - 20
   nYBox := f18_max_cols() - 30

   cValuta := fakt_pripr->dindem // valuta ?

   fakt_stdok_pdv( NIL, NIL, NIL, .T. ) // izvuci mi dokument u temp tabele

   _calc_totals( @hFaktDokTotal, cValuta )

   Box(, nXBox, nYBox )

   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadR( "TOTAL DOKUMENTA:", nYBox - 2 ) COLOR f18_color_i()

   ++nX
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "Osnovica: ", nLeft ) + Str( hFaktDokTotal[ "osn" ], 12, 2 )
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "Popust: ", nLeft ) + Str( hFaktDokTotal[ "pop" ], 12, 2 )
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "Osnovica - popust: ", nLeft ) + Str( hFaktDokTotal[ "osn_pop" ], 12, 2 )
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "PDV: ", nLeft ) + Str( hFaktDokTotal[ "pdv" ], 12, 2 )
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY Replicate( "=", nLeft )
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "Ukupno sa PDV (" + AllTrim( cValuta ) + "): ", nLeft ) + Str( hFaktDokTotal[ "total" ], 12, 2 )

   IF Left( cValuta, 3 ) <> Left( ValBazna(), 3 )
      ++nX
      @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "Ukupno sa PDV (" + AllTrim( ValBazna() ) + "): ", nLeft ) + Str( hFaktDokTotal[ "total2" ], 12, 2 )
   ENDIF

   WHILE Inkey( 0.1 ) != K_ESC
   END

   BoxC()

   SELECT ( nDbfArea )

   RETURN .T.


// ------------------------------------------------
// sracunaj total na osnovu stampe dokumenta
// ------------------------------------------------
STATIC FUNCTION _calc_totals( hInTotal, cValuta )

   LOCAL nDbfArea := Select()

   hInTotal[ "osn" ] := 0
   hInTotal[ "pop" ] := 0
   hInTotal[ "osn_pop" ] := 0
   hInTotal[ "pdv" ] := 0
   hInTotal[ "total" ] := 0
   hInTotal[ "total2" ] := 0

   SELECT drn
   GO TOP

   IF RecCount() <> 0

      hInTotal[ "osn" ] := field->ukbezpdv
      hInTotal[ "pop" ] := field->ukpopust
      hInTotal[ "osn_pop" ] := field->ukbpdvpop
      hInTotal[ "pdv" ] := field->ukpdv
      hInTotal[ "total" ] := field->ukupno

      IF Left( cValuta, 3 ) <> Left( ValBazna(), 3 )
         hInTotal[ "total2" ] := field->ukupno * OmjerVal( ValBazna(), cValuta, field->datdok )
      ENDIF

   ENDIF

   SELECT ( nDbfArea )

   RETURN .T.




// ---------------------------------------------------
// kontrola zbira - fakt dokument
//
// ovdje treba promjeniti logiku i uzeti stampanje
// fakture i onda ocitati podatke...
// todo
// ---------------------------------------------------
STATIC FUNCTION fakt_kzb( cIdFirma, cIdTipDok, cBrDok )

   LOCAL nDug := 0
   LOCAL nRabat := 0
   LOCAL nPDV := 0
   LOCAL cValuta := field->dindem
   LOCAL nTmp := 1

   Box(, 12, f18_max_cols() - 5 )

   IF nTmp > 9

      WHILE Inkey( 0.1 ) != K_ESC
      END

      @ box_x_koord() + 1, box_y_koord() + 2 CLEAR TO box_x_koord() + 12, f18_max_cols() - 5
      nTmp := 1
      @ box_x_koord(), box_y_koord() + 2 SAY ""

   ENDIF

   @ box_x_koord() + nTmp, box_y_koord() + 2 SAY Replicate( "-", f18_max_cols() - 10 )

   @ box_x_koord() + nTmp + 1, box_y_koord() + 2 SAY PadR( "Ukupno   ", 30 )

   @ box_x_koord() + nTmp + 1, Col() + 1 SAY nDug PICT "9999999.99"

   @ box_x_koord() + nTmp + 1, Col() + 1 SAY nRabat PICT "9999999.99"

   @ box_x_koord() + nTmp + 1, Col() + 1 SAY nDug - nRabat PICT "9999999.99"

   @ box_x_koord() + nTmp + 1, Col() + 1 SAY nPDV PICT "9999999.99"

   @ box_x_koord() + nTmp + 1, Col() + 1 SAY ( nDug - nRabat ) + nPDV PICT "9999999.99"

   @ box_x_koord() + nTmp + 1, Col() + 1 SAY "(" + cValuta + ")"

   WHILE Inkey( 0.1 ) != K_ESC
   END

   BoxC()

   RETURN .T.




FUNCTION select_fakt_pripr()

   SELECT F_FAKT_PRIPR

   IF !Used()
      close_open_fakt_tabele()
      SELECT F_FAKT_PRIPR
   ENDIF

   RETURN .T.
