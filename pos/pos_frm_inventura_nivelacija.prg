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

STATIC _saldo_izn := 0
STATIC _saldo_kol := 0

FUNCTION pos_inventura_nivelacija()

   PARAMETERS fInvent, fIzZad, fSadAz, dDatRada, stanje_dn

   LOCAL i := 0
   LOCAL j := 0
   LOCAL fPocInv := .F.
   LOCAL fPreuzeo := .F.
   LOCAL cNazDok
   LOCAL nCnt

   PRIVATE cRSdbf
   PRIVATE cRSblok
   PRIVATE cUI_U
   PRIVATE cUI_I
   PRIVATE cIdVd

   IF gSamoProdaja == "D"
      MsgBeep( "Ne možete vršiti unos zaduženja !" )
      RETURN .F.
   ENDIF

   IF dDatRada == nil
      dDatRada := gDatum
   ENDIF

   IF stanje_dn == nil
      stanje_dn := "N"
   ENDIF

   IF fInvent == nil
      fInvent := .T.
   ENDIF

   IF fInvent
      cIdVd := VD_INV
   ELSE
      cIdVd := VD_NIV
   ENDIF

   IF fInvent
      cNazDok := "INVENTUR"
   ELSE
      cNazDok := "NIVELACIJ"
   ENDIF

   IF fIzZad == nil
      fIzZad := .F.
   ENDIF

   IF fSadAz == nil
      fSadAz := .F.
   ENDIF

   IF fIzZad
   ELSE
      PRIVATE cIdOdj := Space( 2 )
      //PRIVATE cIdDio := Space( 2 )
   ENDIF

   o_pos_tables()

   SET CURSOR ON

   IF !fIzZad

      aNiz := {}

      //IF gVodiOdj == "D"
      //   AAdd( aNiz, { "Sifra odjeljenja", "cIdOdj", "P_Odj(@cIdOdj)",, } )
      //ENDIF

      //IF gPostDO == "D" .AND. fInvent
      //   AAdd( aNiz, { "Sifra dijela objekta", "cIdDio", "P_Dio(@cIdDio)",, } )
      //ENDIF

      AAdd( aNiz, { "Datum rada", "dDatRada", "dDatRada <= DATE()",, } )

      IF fInvent
         AAdd( aNiz, { "Inventura sa gen.stanja (D/N) ?", "stanje_dn", "stanje_dn $ 'DN'", "@!", } )
      ENDIF

      IF !VarEdit( aNiz, 9, 15, 15, 64, cNazDok + "A", "B1" )
         CLOSE ALL
         RETURN .F.
      ENDIF

   ENDIF

   //SELECT ODJ

   cRSdbf := "ROBA"
   cUI_U := R_U
   cUI_I := R_I

   IF !pos_vrati_dokument_iz_pripr( cIdVd, gIdRadnik, cIdOdj )
      my_close_all_dbf()
      RETURN .F.
   ENDIF

   SELECT priprz

   IF RecCount2() == 0
      fPocInv := .T.
   ELSE
      fPocInv := .F.
      dDatRada := priprz->datum
   ENDIF

   IF fPocInv

      cBrDok := pos_novi_broj_dokumenta( gIdPos, cIdVd )
      fPreuzeo := .F.

      IF !fPreuzeo
         o_pos_tables()
      ENDIF

      IF stanje_dn == "N" .AND. cIdVd == VD_INV
         fPocInv := .F.
      ENDIF

      IF fPocInv .AND. !fPreuzeo .AND. cIdVd == VD_INV

         MsgO( "GENERIŠEM DATOTEKU " + cNazDok + "E" )

         SELECT priprz
         Scatter()

         //SELECT pos
         //SET ORDER TO TAG "2"
         //SEEK cIdOdj
         seek_pos_pos_2( cIdOdj )
         DO WHILE !Eof() .AND. field->idodj == cIdOdj

            IF pos->datum > dDatRada
               SKIP
               LOOP
            ENDIF

            nKolicina := 0
            _idroba := pos->idroba
            DO WHILE !Eof() .AND. pos->( idodj + idroba ) == ( cIdOdj + _idroba ) .AND. pos->datum <= dDatRada

               //IF !Empty( cIdDio ) .AND. pos->iddio <> cIdDio
                //  SKIP
                  //LOOP
               //ENDIF

               IF pos->idvd == "96"
                  SKIP
                  LOOP
               ENDIF

               IF pos->idvd $ "16#00"
                  nKolicina += pos->kolicina

               ELSEIF pos->idvd $ "42#96#01#IN#NI"
                  DO CASE
                  CASE pos->idvd == VD_INV
                     nKolicina -= pos->kolicina - pos->kol2
                  CASE pos->idvd == VD_NIV
                  OTHERWISE
                     nKolicina -= pos->kolicina
                  ENDCASE
               ENDIF
               SKIP
            ENDDO

            IF Round( nKolicina, 3 ) <> 0

               select_o_roba( _idroba )
               _cijena := pos_get_mpc()
               _ncijena := pos_get_mpc()
               _robanaz := _field->naz
               _jmj := _field->jmj
               _idtarifa := _field->idtarifa

               SELECT priprz

               _IdOdj := cIdOdj
               //_IdDio := cIdDio
               _BrDok := cBrDok
               _IdVd := cIdVd
               _Prebacen := OBR_NIJE
               _IdCijena := "1"
               _IdRadnik := gIdRadnik
               _IdPos := gIdPos
               _datum := dDatRada
               _Smjena := gSmjena
               _Kol2 := nKolicina
               _MU_I := cUI_I

               APPEND BLANK
               Gather()
               SELECT pos

            ENDIF

         ENDDO

         MsgC()

      ELSE
         SELECT priprz
         my_dbf_zap()
      ENDIF

   ELSE

      SELECT priprz
      GO TOP
      cBrDok := priprz->brdok

   ENDIF

   IF !fSadAz

      ImeKol := {}

      AAdd( ImeKol, { "Sifra i naziv", {|| idroba + "-" + Left( robanaz, 25 ) } } )
      AAdd( ImeKol, { "BARKOD", {|| barkod } } )
      IF cIdVd == VD_INV
         AAdd( ImeKol, { "Knj.kol.", {|| Str( kolicina, 9, 3 ) } } )
         AAdd( ImeKol, { "Pop.kol.", {|| Str( kol2, 9, 3 ) }, "kol2" } )
      ELSE
         AAdd( ImeKol, { "Kolicina", {|| Str( kolicina, 9, 3 ) } } )
      ENDIF
      AAdd( ImeKol, { "Cijena ", {|| Str( cijena, 7, 2 ) } } )

      IF cIdVd == VD_NIV
         AAdd( ImeKol, { "Nova C.",     {|| Str( ncijena, 7, 2 ) } } )
      ENDIF

      AAdd( ImeKol, { "Tarifa ", {|| idtarifa } } )
      AAdd( ImeKol, { "Datum ", {|| datum } } )

      Kol := {}

      FOR nCnt := 1 TO Len( ImeKol )
         AAdd( Kol, nCnt )
      NEXT

      SELECT priprz
      SET ORDER TO TAG "1"

      DO WHILE .T.

         SELECT priprz
         GO TOP

         @ 12, 0 SAY ""

         SET CURSOR ON

         my_browse( "PripInv", f18_max_rows() -15, f18_max_cols() -3, {|| EditInvNiv( dDatRada ) }, ;
            "Broj dokumenta: " + AllTrim( cBrDok ) + " datum: " + DToC( dDatRada ), ;
            "PRIPREMA " + cNazDok + "E", nil, ;
            { "<c-N>   Dodaj stavku", "<Enter> Ispravi stavku", "<a-P>   Popisna lista", "<c-P>   Stampanje", "<c-A> cirk ispravka", "<D> ispravi datum" }, 2, , , )

         IF priprz->( RecCount() ) == 0
            pos_reset_broj_dokumenta( gIdPos, cIdVd, cBrDok )
            CLOSE ALL
            RETURN .F.
         ENDIF

         i := KudaDalje( "ZAVRSAVATE SA PRIPREMOM " + cNazDok + "E. STA RADITI S NJOM?", { ;
            "NASTAVICU S NJOM KASNIJE", ;
            "AZURIRATI (ZAVRSENA JE)", ;
            "TREBA JE IZBRISATI", ;
            "VRATI PRIPREMU " + cNazDok + "E" } )

         IF i == 1

            SELECT _POS
            AppFrom( "PRIPRZ", .F. )
            SELECT PRIPRZ
            my_dbf_zap()
            my_close_all_dbf()
            RETURN .T.

         ELSEIF i == 3

            IF Pitanje(, D_ZELITE_LI_IZBRISATI_PRIPREMU, "N" ) == "D"

               SELECT PRIPRZ
               my_dbf_zap()
               pos_reset_broj_dokumenta( gIdPos, cIdVd, cBrDok )
               my_close_all_dbf()
               RETURN .T.

            ELSE

               SELECT _POS
               AppFrom( "PRIPRZ", .F. )
               SELECT PRIPRZ
               my_dbf_zap()
               my_close_all_dbf()
               RETURN .T.

            ENDIF

         ELSEIF i == 4

            SELECT PRIPRZ
            GO TOP
            LOOP

         ENDIF

         IF i == 2
            EXIT
         ENDIF

      ENDDO

   ENDIF

   check_before_azur( dDatRada )

   pos_azuriraj_inventura_nivelacija()
   my_close_all_dbf()

   RETURN .T.


STATIC FUNCTION check_before_azur( dDatRada )

   LOCAL _ret := .T.
   LOCAL hRec

   MsgO( "Provjera unesenih podataka prije ažuriranja u toku ..." )

   SELECT priprz
   GO TOP
   DO WHILE !Eof()

      IF field->datum <> dDatRada
         hRec := dbf_get_rec()
         hRec[ "datum" ] := dDatRada
         dbf_update_rec( hRec )
      ENDIF
      SKIP
   ENDDO

   SELECT priprz
   GO TOP

   MsgC()

   RETURN _ret



FUNCTION EditInvNiv( dat_inv_niv )

   LOCAL nRec := RecNo()
   LOCAL i := 0
   LOCAL lVrati := DE_CONT
   LOCAL _dat

   DO CASE

   CASE Ch == K_CTRL_P

      pos_stampa_zaduzenja_inventure()

      o_pos_tables()
      SELECT priprz
      GO nRec
      lVrati := DE_REFRESH


   CASE Upper( Chr( Ch ) ) == "D"

      _dat := Date()

      Box(, 1, 50 )
      @ box_x_koord() + 1, box_y_koord() + 2 SAY "Postavi datum na:" GET _dat
      READ
      BoxC()

      IF LastKey() <> K_ESC
         check_before_azur( _dat )
         TB:RefreshAll()
         DO WHILE !TB:stable .AND. ( Ch := Inkey() ) == 0
            Tb:stabilize()
         ENDDO
         lVrati := DE_REFRESH
      ENDIF

   CASE Ch == K_ALT_P

      IF cIdVd == VD_INV
         pos_stampa_zaduzenja_inventure( .T. )
         o_pos_tables()
         SELECT priprz
         GO nRec
         lVrati := DE_REFRESH
      ENDIF

   CASE Ch == K_ENTER

      _calc_priprz()
      IF !( pos_ed_priprema_inventura( 1, dat_inv_niv ) == 0 )
         lVrati := DE_REFRESH
      ENDIF

   CASE Ch == K_CTRL_O

      IF update_ip_razlika() == 1
         lVrati := DE_REFRESH
      ENDIF

   CASE Ch == K_CTRL_U

      update_knj_kol()
      lVrati := DE_REFRESH

   CASE Ch == K_CTRL_A

      DO WHILE !Eof()
         IF pos_ed_priprema_inventura( 1, dat_inv_niv ) == 0
            EXIT
         ENDIF
         SKIP
      ENDDO

      IF Eof()
         SKIP -1
      ENDIF

      lVrati := DE_REFRESH

   CASE Ch == K_CTRL_N

      _calc_priprz()
      pos_ed_priprema_inventura( 0, dat_inv_niv )
      lVrati := DE_REFRESH

   CASE Ch == K_CTRL_T

      lVrati := DE_CONT
      IF Pitanje(, "Stavku " + AllTrim( priprz->idroba ) + " izbrisati ?", "N" ) == "D"
         my_delete_with_pack()
         lVrati := DE_REFRESH
      ENDIF

   ENDCASE

   RETURN lVrati


STATIC FUNCTION _calc_priprz()

   LOCAL _saldo_kol, _saldo_izn

   PushWa()

   SELECT priprz
   GO TOP

   _saldo_kol := 0
   _saldo_izn := 0

   DO WHILE !Eof()

      IF field->idvd == "IN"
         _saldo_kol += field->kol2
         _saldo_izn += ( field->kol2 * field->cijena )
      ELSE
         _saldo_kol += field->kolicina
         _saldo_kol += ( field->kolicina * field->cijena )
      ENDIF

      SKIP

   ENDDO

   PopWa()

   RETURN .T.



FUNCTION pos_ed_priprema_inventura( nInd, datum )

   LOCAL nVrati := 0
   LOCAL aNiz := {}
   LOCAL nRec := RecNo()
   LOCAL _r_tar, _r_barkod, _r_jmj, _r_naz
   LOCAL _duz_sif := "10"
   LOCAL _pict := "9999999.99"
   LOCAL _last_read_var

   IF gDuzSifre <> NIL .AND. gDuzSifre > 0
      _duz_sif := AllTrim( Str( gDuzSifre ) )
   ENDIF

   SET CURSOR ON

   SELECT priprz

   DO WHILE .T.

      SET CONFIRM ON

      Box(, 7, f18_max_cols() -5, .T. )

      @ box_x_koord() + 0, box_y_koord() + 1 SAY " " + IF( nInd == 0, "NOVA STAVKA", "ISPRAVKA STAVKE" ) + " "

      Scatter()

      @ box_x_koord() + 1, box_y_koord() + 31 SAY PadR( "", 35 )
      @ box_x_koord() + 6, box_y_koord() + 2 SAY "... zadnji artikal: " + AllTrim( _idroba ) + " - " + PadR( _robanaz, 25 ) + "..."
      @ box_x_koord() + 7, box_y_koord() + 2 SAY "stanje unosa - kol: " + AllTrim( Str( _saldo_kol, 12, 2 ) ) + ;
         " total: " + AllTrim( Str( _saldo_izn, 12, 2 ) )

      select_o_roba( _idroba )

      IF nInd == 1
         @ box_x_koord() + 0, box_y_koord() + 1 SAY _idroba + " : " + AllTrim( naz ) + " (" + AllTrim( idtarifa ) + ")"
      ENDIF

      SELECT priprz

      IF nInd == 0

         _idodj := cIdOdj
        // _iddio := cIdDio
         _idroba := Space( 10 )
         nKolicina := 0
         _kol2 := 0
         _brdok := cBrDok
         _idvd := cIdVd
         _prebacen := OBR_NIJE
         _idcijena := "1"
         _idradnik := gIdRadnik
         _idpos := gIdPos
         _cijena := 0
         _ncijena := 0
         _datum := datum
         _smjena := gSmjena
         _mu_i := cUI_I

      ENDIF

      nLX := box_x_koord() + 1

      @ nLX, box_y_koord() + 3 SAY "      Artikal:" GET _idroba ;
         PICT PICT_POS_ARTIKAL ;
         WHEN {|| _idroba := PadR( _idroba, Val( _duz_sif ) ), .T. } ;
         VALID valid_pos_inv_niv( cIdVd, nInd )

      nLX++

      IF cIdVd == VD_INV
         @ nLX, box_y_koord() + 3 SAY8 "Knj. količina:" GET nKolicina PICT _pict ;
            WHEN {|| .F. }
      ELSE
         @ nLX, box_y_koord() + 3 SAY8 "     Količina:" GET nKolicina PICT _pict ;
            WHEN {|| .T. }
      ENDIF

      nLX++

      IF cIdVd == VD_INV

         @ nLX, box_y_koord() + 3 SAY8 "Pop. količina:" GET _kol2 PICT _pict ;
            VALID _pop_kol( _kol2 ) ;
            WHEN {|| .T. }

         nLX++

      ENDIF

      @ nLX, box_y_koord() + 3 SAY "       Cijena:" GET _cijena PICT _pict ;
         WHEN {|| .T. } ;
         VALID {|| _cijena < 999999.99 }

      IF cIdVd == VD_NIV

         nLX++

         @ nLX, box_y_koord() + 3 SAY "  Nova cijena:" GET _ncijena PICT _pict ;
            WHEN {|| .T. }

      ENDIF

      READ

      IF LastKey() == K_ESC

         BoxC()

         TB:RefreshAll()
         DO WHILE !TB:stable .AND. ( Ch := Inkey() ) == 0
            Tb:stabilize()
         ENDDO

         EXIT

      ENDIF

      IF nInd == 0

         SELECT priprz
         GO TOP
         SEEK _idroba // PRIPRZ

         IF !Found()
            APPEND BLANK
         ENDIF

      ENDIF

      select_o_roba( _idroba )

      _r_tar := field->idtarifa
      _r_barkod := field->barkod
      _r_naz := field->naz
      _r_jmj := field->jmj

      SELECT priprz

      _idtarifa := _r_tar
      _barkod := _r_barkod
      _robanaz := _r_naz
      _jmj := _r_jmj

      _kol2 := ( priprz->kol2 + _kol2 )

      my_rlock()
      Gather()
      my_unlock()

      _saldo_kol += priprz->kol2
      _saldo_izn += ( priprz->kol2 * priprz->cijena )

      IF nInd == 0

         TB:RefreshAll()

         DO WHILE !TB:stable .AND. ( Ch := Inkey() ) == 0
            Tb:stabilize()
         ENDDO

      ENDIF

      IF nInd == 1
         nVrati := 1
         BoxC()
         EXIT
      ENDIF

      BoxC()

   ENDDO

   GO nRec

   RETURN nVrati


STATIC FUNCTION update_ip_razlika()

   LOCAL cIdOdj := Space( 2 )
   LOCAL nKolicinaZaInventuru, ip_roba
   LOCAL _rec2, hRec

   IF Pitanje(, "Generisati razliku artikala sa stanja ?", "N" ) == "N"
      RETURN 0
   ENDIF

   MsgO( "GENERIŠEM RAZLIKU NA OSNOVU STANJA" )

   SELECT priprz
   GO TOP
   _rec2 := dbf_get_rec()

   //SELECT pos
   //SET ORDER TO TAG "2"
   // "2", "IdOdj + idroba + DTOS(Datum)
   //SEEK cIdOdj
   seek_pos_pos_2( cIdOdj )

   DO WHILE !Eof() .AND. field->idodj == cIdOdj

      IF pos->datum > dDatRada
         SKIP
         LOOP
      ENDIF

      nKolicinaZaInventuru := 0
      ip_roba := pos->idroba

      SELECT priprz
      SET ORDER TO TAG "1"
      GO TOP
      SEEK PadR( ip_roba, 10 ) // PRIPRZ

      IF Found() .AND. field->idroba == PadR( ip_roba, 10 )
         SELECT pos
         SKIP
         LOOP
      ENDIF

      SELECT pos

      DO WHILE !Eof() .AND. pos->( idodj + idroba ) == ( cIdOdj + ip_roba ) .AND. pos->datum <= dDatRada

         //IF !Empty( cIdDio ) .AND. pos->iddio <> cIdDio
          //  SKIP
        //    LOOP
         //ENDIF

         IF pos->idvd $ "16#00"
            nKolicinaZaInventuru += pos->kolicina

         ELSEIF pos->idvd $ "42#96#01#IN#NI"
            DO CASE
            CASE pos->idvd == VD_INV
               nKolicinaZaInventuru -= pos->kolicina - pos->kol2
            CASE pos->idvd == VD_NIV
            OTHERWISE
               nKolicinaZaInventuru -= pos->kolicina
            ENDCASE
         ENDIF

         SKIP

      ENDDO

      IF Round( nKolicinaZaInventuru, 3 ) <> 0

         select_o_roba( ip_roba )

         SELECT priprz
         APPEND BLANK

         hRec := dbf_get_rec()
         hRec[ "cijena" ] := pos_get_mpc()
         hRec[ "ncijena" ] := 0
         hRec[ "idroba" ] := ip_roba
         hRec[ "barkod" ] := roba->barkod
         hRec[ "robanaz" ] := roba->naz
         hRec[ "jmj" ] := roba->jmj
         hRec[ "idtarifa" ] := roba->idtarifa
         hRec[ "kol2" ] := 0
         hRec[ "kolicina" ] := nKolicinaZaInventuru
         hRec[ "brdok" ] := _rec2[ "brdok" ]
         hRec[ "datum" ] := _rec2[ "datum" ]
         hRec[ "idcijena" ] := _rec2[ "idcijena" ]
         hRec[ "idpos" ] := _rec2[ "idpos" ]
         hRec[ "idradnik" ] := _rec2[ "idradnik" ]
         hRec[ "idvd" ] := _rec2[ "idvd" ]
         hRec[ "mu_i" ] := _rec2[ "mu_i" ]
         hRec[ "prebacen" ] := _rec2[ "prebacen" ]
         hRec[ "smjena" ] := _rec2[ "smjena" ]

         dbf_update_rec( hRec )

      ENDIF

      SELECT pos

   ENDDO

   SELECT priprz
   GO TOP

   TB:RefreshAll()

   DO WHILE !TB:stable .AND. ( Ch := Inkey() ) == 0
      Tb:stabilize()
   ENDDO

   RETURN 1



STATIC FUNCTION update_knj_kol()

   SELECT priprz
   GO TOP

   DO WHILE !Eof()
      Scatter()
      RacKol( _idodj, _idroba, @nKolicina )
      SELECT priprz
      Gather()
      SKIP
   ENDDO

   TB:RefreshAll()

   DO WHILE !TB:stable .AND. ( Ch := Inkey() ) == 0
      Tb:stabilize()
   ENDDO

   SELECT priprz
   GO TOP

   RETURN .T.


STATIC FUNCTION valid_pos_inv_niv( cIdVd, ind )

   LOCAL _area := Select()

   pos_postoji_roba( @_IdRoba, 1, 31 )

   RacKol( _idodj, _idroba, @nKolicina )

   _set_cijena_artikla( cIdVd, _idroba )

   IF ind == 0 .AND. !_postoji_artikal_u_pripremi( _idroba )
      SELECT ( _area )
   ENDIF

   IF cIdVD == VD_INV
      get_field_set_focus( "_kol2" )
   ELSE
      get_field_set_focus( "_cijena" )
   ENDIF

   SELECT ( _area )

   RETURN .T.


FUNCTION _pop_kol( kol )

   LOCAL _ok := .T.

   IF kol > 200
      IF Pitanje(, "Da li je " + AllTrim( Str( kol, 12, 2 ) ) + " ispravna količina (D/N) ?", "N" ) == "N"
         _ok := .F.
      ENDIF
   ENDIF

   RETURN _ok



FUNCTION _set_cijena_artikla( id_vd, cIdRoba )

   PushWa()

   IF id_vd == VD_INV

      select_o_roba( cIdRoba )
      _cijena := pos_get_mpc()

   ENDIF

   PopWa()

   RETURN .T.


FUNCTION _postoji_artikal_u_pripremi( cIdRoba )

   LOCAL _ok := .T.

   PushWA()

   SELECT priprz
   SET ORDER TO TAG "1"
   GO TOP
   SEEK cIdRoba // PRIPRZ

   IF Found()
      _ok := .F.
      MsgBeep( "Artikal " + AllTrim( cIdRoba ) + " se već nalazi u pripremi! Ako nastavite sa unosom #dodat će se vrijednost na postojeću stavku..." )
   ENDIF

   PopWa()

   RETURN _ok



FUNCTION RacKol( cIdOdj, cIdRoba, nKol )

   MsgO( "Računam količinu artikla ..." )

   //SELECT pos
   //SET ORDER TO TAG "2"
   nKol := 0

   seek_pos_pos_2( cIdOdj, cIdRoba )

   DO WHILE !Eof() .AND. pos->IdOdj + pos->IdRoba  == ( cIdOdj + cIdRoba ) .AND. pos->Datum <= dDatRada

      IF AllTrim( POS->IdPos ) == "X"
         SKIP
         LOOP
      ENDIF

      IF pos->idvd $ "16#00"
         nKol += pos->Kolicina
      ELSEIF POS->idvd $ "42#01#IN#NI"
         DO CASE
         CASE POS->IdVd == VD_INV
            nKol := pos->kol2
         CASE POS->idvd == VD_NIV
         OTHERWISE
            nKol -= pos->kolicina
         ENDCASE
      ENDIF
      SKIP
   ENDDO

   MsgC()

   SELECT priprz

   RETURN ( .T. )
