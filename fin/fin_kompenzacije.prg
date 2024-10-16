/*
 * This file is part of the bring.out knowhow ERP, a free and open source
 * Enterprise Resource Planning software suite,
 * Copyright (c) 1994-2024 by bring.out doo Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including FMK specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_knowhow.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */


#include "f18.ch"

STATIC picBHD
STATIC picDEM



FUNCTION kompenzacija()

   LOCAL _is_gen := .F.
   LOCAL hVars := hb_Hash()
   LOCAL nI, _n
   LOCAL nRedova := f18_max_rows() - 10
   LOCAL nKolona := f18_max_cols() - 6
   LOCAL cIdKonto, cIdKonto2
   LOCAL nBoxY1, nBoxY2

   picBHD := FormPicL( gPicBHD, 16 )
   picDEM := FormPicL( pic_iznos_eur(), 12 )

   _o_tables()

   hVars[ "konto" ] := ""
   hVars[ "konto2" ] := ""
   hVars[ "partn" ] := ""
   hVars[ "dat_od" ] := Date()
   hVars[ "dat_do" ] := Date()
   hVars[ "po_vezi" ] := "D"
   hVars[ "prelom" ] := "N"
   hVars[ "firma" ] := self_organizacija_id()

   IF Pitanje(, "Izgenerisati stavke za kompenzaciju (D/N) ?", "N" ) == "D"

      _is_gen := .T.

      IF !_get_vars( @hVars )
         RETURN .F.
      ENDIF

      cIdKonto := hVars[ "konto" ]
      cIdKonto2 := hVars[ "konto2" ]

   ELSE

      cIdKonto := PadR( "", 7 )
      cIdKonto2 := cIdKonto

   ENDIF

   IF _is_gen
      _gen_kompen( hVars )
   ENDIF

   ImeKol := { ;
      { "Br.racuna", {|| PadR( brdok, 10 )    }, "brdok"    }, ;
      { "Iznos",     {|| iznosbhd }, "iznosbhd" }, ;
      { "Marker",    {|| marker }, "marker" } ;
      }

   Kol := {}
   FOR nI := 1 TO Len( ImeKol )
      AAdd( Kol, nI )
   NEXT

   Box(, nRedova, nKolona )

   @ box_x_koord(), box_y_koord() + 30 SAY ' KREIRANJE OBRASCA "IZJAVA O KOMPENZACIJI" '

   @ box_x_koord() + nRedova - 4, box_y_koord() + 1 SAY Replicate( "=", nKolona )
   @ box_x_koord() + nRedova - 3, box_y_koord() + 1 SAY8 "  <K> izaberi/ukini račun za kompenzaciju"
   @ box_x_koord() + nRedova - 2, box_y_koord() + 1 SAY8 "<c+P> štampanje kompenzacije                  <T> promijeni tabelu"
   @ box_x_koord() + nRedova - 1, box_y_koord() + 1 SAY8 "<c+N> nova stavka                           <c+T> brisanje                 <ENTER> ispravka stavke "

   FOR nI := 1 TO ( nRedova - 4 )
      @ box_x_koord() + nI, box_y_koord() + Abs( nKolona / 2 ) SAY "|"
   NEXT

   SELECT komp_pot
   GO TOP

   SELECT komp_dug
   GO TOP

   nBoxY1 := box_y_koord()
   nBoxY2 := box_y_koord() + Abs( nKolona / 2 ) + 1

   DO WHILE .T.

      IF Alias() == "KOMP_DUG"
         box_y_koord( nBoxY1 )
      ELSEIF Alias() == "KOMP_POT"
         box_y_koord( nBoxY2 )
      ENDIF

      my_browse( "komp1", nRedova - 7, Abs( nKolona / 2 ) - 1, {| nCh | key_handler( nCh, hVars ) }, "", if( Alias() == "KOMP_DUG", "DUGUJE " + cIdKonto, "POTRAZUJE " + cIdKonto2 ), , , , , 1 )

      IF LastKey() == K_ESC
         EXIT
      ENDIF

   ENDDO

   BoxC()

   my_close_all_dbf()

   RETURN .T.


STATIC FUNCTION _get_vars( hParams )

   LOCAL cIdFirma := self_organizacija_id()
   LOCAL dDatOd := CToD( "" )
   LOCAL dDatDo := CToD( "" )
   LOCAL cIdKonto := PadR( "", 7 )
   LOCAL cIdKonto2 := PadR( "", 7 )
   LOCAL cIdPartner := PadR( "", 6 )
   LOCAL cPrikazDatumaSaBrojemRacunaDN := "D"
   LOCAL cSabratiPoBrojevimaVeze := "D"
   LOCAL cPrebijenoStanjeDN := "N"
   LOCAL nX := 1
   LOCAL lRet := .T.
   LOCAL GetList := {}

   cIdKonto := fetch_metric( "fin_komen_konto", my_user(), cIdKonto )
   cIdKonto2 := fetch_metric( "fin_komen_konto_2", my_user(), cIdKonto2 )
   cIdPartner := fetch_metric( "fin_komen_partn", my_user(), cIdPartner )
   dDatOd := fetch_metric( "fin_komen_datum_od", my_user(), dDatOd )
   dDatDo := fetch_metric( "fin_komen_datum_do", my_user(), dDatDo )
   cSabratiPoBrojevimaVeze := fetch_metric( "fin_komen_po_vezi", my_user(), cSabratiPoBrojevimaVeze )
   cPrebijenoStanjeDN := fetch_metric( "fin_komen_prelomljeno", my_user(), cPrebijenoStanjeDN )
   cPrikazDatumaSaBrojemRacunaDN := fetch_metric( "fin_komen_br_racuna_sa_datumom", my_user(), cPrikazDatumaSaBrojemRacunaDN )

   Box( "", 18, 65 )

   set_cursor_on()

   @ box_x_koord() + nX, box_y_koord() + 2 SAY 'KREIRANJE OBRASCA "IZJAVA O KOMPENZACIJI"'

   nX := nX + 4

   DO WHILE .T.

      //IF gNW == "D"
         @ box_x_koord() + nX, box_y_koord() + 2 SAY "Firma "
         ?? self_organizacija_id(), "-", PadR( self_organizacija_naziv(), 30 )
      //ELSE
      //   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Firma: " GET cIdFirma VALID {|| p_partner( @cIdFirma ), cIdFirma := Left( cIdFirma, 2 ), .T. }
      //ENDIF

      ++nX
      @ box_x_koord() + nX, box_y_koord() + 2 SAY "Konto duguje   " GET cIdKonto  VALID p_konto( @cIdKonto )
      ++nX
      @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Konto potražuje" GET cIdKonto2  VALID p_konto( @cIdKonto2 ) .AND. cIdKonto2 > cIdKonto
      ++nX
      @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Partner-dužnik " GET cIdPartner VALID p_partner( @cIdPartner )  PICT "@!"
      ++nX
      @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Datum dokumenta od:" GET dDatOd
      @ box_x_koord() + nX, Col() + 2 SAY "do" GET dDatDo   VALID dDatOd <= dDatDo

      ++nX
      ++nX
      @ box_x_koord() + nX, box_y_koord() + 2 SAY "Sabrati po brojevima veze D/N ?"  GET cSabratiPoBrojevimaVeze VALID cSabratiPoBrojevimaVeze $ "DN" PICT "@!"
      @ box_x_koord() + nX, Col() + 2 SAY "Prikaz prebijenog stanja " GET cPrebijenoStanjeDN VALID cPrebijenoStanjeDN $ "DN" PICT "@!"
      ++nX
      @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Prikaz datuma sa brojem računa (D/N) ?"  GET cPrikazDatumaSaBrojemRacunaDN VALID cPrikazDatumaSaBrojemRacunaDN $ "DN" PICT "@!"

      READ
      ESC_BCR

      EXIT

   ENDDO

   BoxC()

   IF LastKey() == K_ESC
      lRet := .F.
      RETURN lRet
   ENDIF

   set_metric( "fin_komen_konto", my_user(), cIdKonto )
   set_metric( "fin_komen_konto_2", my_user(), cIdKonto2 )
   set_metric( "fin_komen_partn", my_user(), cIdPartner )
   set_metric( "fin_komen_datum_od", my_user(), dDatOd )
   set_metric( "fin_komen_datum_do", my_user(), dDatDo )
   set_metric( "fin_komen_po_vezi", my_user(), cSabratiPoBrojevimaVeze )
   set_metric( "fin_komen_prelomljeno", my_user(), cPrebijenoStanjeDN )
   set_metric( "fin_komen_br_racuna_sa_datumom", my_user(), cPrikazDatumaSaBrojemRacunaDN )

   hParams[ "konto" ] := cIdKonto
   hParams[ "konto2" ] := cIdKonto2
   hParams[ "partn" ] := cIdPartner
   hParams[ "dat_od" ] := dDatOd
   hParams[ "dat_do" ] := dDatDo
   hParams[ "po_vezi" ] := cSabratiPoBrojevimaVeze
   hParams[ "prelom" ] := cPrebijenoStanjeDN
   hParams[ "firma" ] := cIdFirma
   hParams[ "sa_datumom" ] := cPrikazDatumaSaBrojemRacunaDN

   RETURN lRet





STATIC FUNCTION zap_tabele_kompenzacije()

   SELECT komp_dug
   my_dbf_zap()

   SELECT komp_pot
   my_dbf_zap()

   RETURN .T.



STATIC FUNCTION _gen_kompen( hParams )

   LOCAL cIdKonto := hParams[ "konto" ]
   LOCAL cIdKonto2 := hParams[ "konto2" ]
   LOCAL cIdPartner := hParams[ "partn" ]
   LOCAL dDatOd := hParams[ "dat_od" ]
   LOCAL dDatDo := hParams[ "dat_do" ]
   LOCAL cSabratiPoBrojevimaVeze := hParams[ "po_vezi" ]
   LOCAL cPrikazDatumaSaBrojemRacunaDN := hParams[ "sa_datumom" ]
   LOCAL cPrebijenoStanjeDN := hParams[ "prelom" ]
   LOCAL cIdFirma := hParams[ "firma" ]
   LOCAL cFilter, cBrDok
   LOCAL cIdKontoTekuci, cIdPartnerTekuci, nProlaz, lProsao
   LOCAL cOtvSt, _t_id_konto
   //LOCAL cBrDok
   LOCAL nDugujeKM, nPotrazujeKM, nDugujeEUR, nPotrazujeEUR
   LOCAL _pr_d_bhd, _pr_p_bhd, _pr_d_dem, _pr_p_dem
   LOCAL nUkupnoDugujeKM, nUkupnoPotrazujeKM, _dug_dem, _pot_dem
   LOCAL nTotalDugujeKM, nTotalPotrazujeKM, _kon_d2, _kon_p2
   LOCAL _svi_d, _svi_p, _svi_d2, _svi_p2
   LOCAL cOrderBy
   LOCAL nCount
   LOCAL _rec

   zap_tabele_kompenzacije()

   // o_suban()
   // o_tdok()

   // SELECT SUBAN


   cFilter := ".t."

   IF !Empty( dDatOd )
      cFilter += " .and. DATDOK >= " + dbf_quote( dDatOd )
   ENDIF

   IF !Empty( dDatDo )
      cFilter += " .and. DATDOK <= " + dbf_quote( dDatDo )
   ENDIF

   cOrderBy := "IdFirma,IdKonto,IdPartner,brdok,datdok"

   // IF cSabratiPoBrojevimaVeze == "D"
   // SET ORDER TO TAG "3"
   // cOrderBy := "idfirma,idvn,brnal"
   // ENDIF

   // IF !find_suban_by_konto_partner( cIdFirma, cIdKonto, cIdPartner, NIL, cOrderBy )
   // find_suban_by_konto_partner( cIdFirma, cIdKonto2, cIdPartner, NIL, cOrderBy )
   // ENDIF
   find_suban_by_konto_partner( cIdFirma, cIdKonto + ";" + cIdKonto2 + ";", cIdPartner, NIL, cOrderBy, .T. ) // lIndex = .T.


   MsgO( "setujem filter... " )
   IF cFilter == ".t."
      SET FILTER TO
   ELSE
      SET FILTER TO &( cFilter )
   ENDIF
   MsgC()

   GO TOP
   EOF CRET

   _svi_d := 0
   _svi_p := 0
   _svi_d2 := 0
   _svi_p2 := 0
   nTotalDugujeKM := 0
   nTotalPotrazujeKM := 0
   _kon_d2 := 0
   _kon_p2 := 0

   //cIdKontoTekuci := field->idkonto

   nProlaz := 0
   IF Empty( cIdPartner )
      nProlaz := 1
      HSEEK cIdFirma + cIdKonto
      IF Eof()
         nProlaz := 2
         HSEEK cIdFirma + cIdKonto2
      ENDIF
   ENDIF

   Box(, 2, 50 )

   nCount := 0

   DO WHILE .T.

      IF !Eof() .AND. field->idfirma == cIdFirma .AND. ;
            ( ( nProlaz == 0 .AND. ( field->idkonto == cIdKonto .OR. field->idkonto == cIdKonto2 ) ) .OR. ;
            ( nProlaz == 1 .AND. field->idkonto = cIdKonto ) .OR. ;
            ( nProlaz == 2 .AND. field->idkonto = cIdKonto2 ) )
      ELSE
         EXIT
      ENDIF

      nDugujeKM := 0
      nPotrazujeKM := 0
      nDugujeEUR := 0
      nPotrazujeEUR := 0
      _pr_d_bhd := 0
      _pr_p_bhd := 0
      _pr_d_dem := 0
      _pr_p_dem := 0
      nUkupnoDugujeKM := 0
      nUkupnoPotrazujeKM := 0
      _dug_dem := 0
      _pot_dem := 0

      cIdPartnerTekuci := field->idpartner
      lProsao := .F.

      DO WHILE !Eof() .AND. field->IdFirma == cIdFirma .AND. field->idpartner == cIdPartnerTekuci .AND. ( field->idkonto == cIdKonto .OR. field->idkonto == cIdKonto2 )

         cIdKontoTekuci := field->idkonto
         cOtvSt := field->otvst

         IF !( cOtvSt == "9" )

            lProsao := .T.

            SELECT suban
            IF cIdKontoTekuci == cIdKonto
               SELECT komp_dug
            ELSE
               SELECT komp_pot
            ENDIF

            my_flock()

            APPEND BLANK
            cBrDok := AllTrim( suban->brdok )

            IF Empty( cBrDok )
               cBrDok := "??????"
            ENDIF

            IF cPrikazDatumaSaBrojemRacunaDN == "D"
               cBrDok += " od " + DToC( suban->datdok )
            ENDIF

            REPLACE field->brdok WITH cBrDok

            my_unlock()

            _t_id_konto := cIdKontoTekuci
            SELECT suban

         ENDIF

         @ box_x_koord() + 1, box_y_koord() + 2 SAY "konto: " + PadR( cIdKontoTekuci, 7 ) + " partner: " + cIdPartner

         nDugujeKM := 0
         nPotrazujeKM := 0
         nDugujeEUR := 0
         nPotrazujeEUR := 0

         IF cSabratiPoBrojevimaVeze == "D"

            cBrDok := field->brdok

            DO WHILE !Eof() .AND. field->IdFirma == cIdFirma .AND. field->idpartner == cIdPartnerTekuci ;
                  .AND. ( field->idkonto == cIdKonto .OR. field->idkonto == cIdKonto2 ) .AND. field->brdok == cBrDok
               IF field->d_p == "1"
                  nDugujeKM += field->iznosbhd
                  nDugujeEUR += field->iznosdem
               ELSE
                  nPotrazujeKM += field->iznosbhd
                  nPotrazujeEUR += field->iznosdem
               ENDIF

               SKIP

            ENDDO

            IF cPrebijenoStanjeDN == "D"
               fin_prebijeno_stanje_dug_pot( @nDugujeKM, @nPotrazujeKM )
               fin_prebijeno_stanje_dug_pot( @nDugujeEUR, @nPotrazujeEUR )
            ENDIF

         ELSE

            IF field->d_p == "1"
               nDugujeKM += field->iznosbhd
               nDugujeEUR += field->iznosdem
            ELSE
               nPotrazujeKM += field->iznosbhd
               nPotrazujeEUR += field->iznosdem
            ENDIF

         ENDIF

         @ box_x_koord() + 2, box_y_koord() + 2 SAY "cnt:" + AllTrim( Str( ++nCount ) ) + " suban cnt: " + AllTrim( Str( RecNo() ) )

         IF cOtvSt == "9"
            nUkupnoDugujeKM += nDugujeKM
            nUkupnoPotrazujeKM += nPotrazujeKM
         ELSE

            // otvorena stavka
            IF _t_id_konto == cIdKonto
               SELECT komp_dug
               IF nDugujeKM > 0
                  RREPLACE field->iznosbhd WITH nDugujeKM
                  IF nPotrazujeKM > 0
                     _rec := dbf_get_rec()
                     APPEND BLANK
                     dbf_update_rec( _rec )
                     RREPLACE field->iznosbhd WITH -nPotrazujeKM
                  ENDIF
               ELSE
                  RREPLACE field->iznosbhd WITH -nPotrazujeKM
               ENDIF
            ELSE

               SELECT komp_pot
               IF nPotrazujeKM > 0
                  RREPLACE field->iznosbhd WITH nPotrazujeKM
                  IF nDugujeKM > 0
                     _rec := dbf_get_rec()
                     APPEND BLANK
                     dbf_update_rec( _rec )
                     RREPLACE field->iznosbhd WITH -nDugujeKM
                  ENDIF
               ELSE
                  RREPLACE field->iznosbhd WITH -nDugujeKM
               ENDIF
            ENDIF

            SELECT SUBAN

            nUkupnoDugujeKM += nDugujeKM
            nUkupnoPotrazujeKM += nPotrazujeKM

         ENDIF

         IF cSabratiPoBrojevimaVeze <> "D"
            SKIP
         ENDIF

         IF nProlaz == 0 .OR. nProlaz == 1
            IF ( field->idkonto <> cIdKontoTekuci .OR. field->idpartner <> cIdPartnerTekuci ) .AND. cIdKontoTekuci == cIdKonto
               HSEEK cIdFirma + cIdKonto2 + cIdPartner
            ENDIF
         ENDIF

      ENDDO

      nTotalDugujeKM += nUkupnoDugujeKM
      nTotalPotrazujeKM += nUkupnoPotrazujeKM
      _kon_d2 += _dug_dem
      _kon_p2 += _pot_dem

      IF nProlaz == 0
         EXIT
      ELSEIF nProlaz == 1
         SEEK cIdFirma + cIdKonto + cIdPartner + Chr( 255 )
         IF cIdKonto <> field->idkonto
            nProlaz := 2
            SEEK cIdFirma + cIdKonto2
            cIdPartner := Replicate( "", Len( field->idpartner ) )
            IF !Found()
               EXIT
            ENDIF
         ENDIF
      ENDIF

      IF nProlaz == 2
         DO WHILE .T.
            SEEK cIdFirma + cIdKonto2 + cIdPartner + Chr( 255 )
            nTrec := RecNo()
            IF field->idkonto == cIdKonto2
               cIdPartner := field->idpartner
               HSEEK cIdFirma + cIdKonto + cIdPartner
               IF !Found()
                  GO ( nTrec )
                  EXIT
               ELSE
                  LOOP
               ENDIF
            ENDIF
            EXIT
         ENDDO
      ENDIF

   ENDDO

   BoxC()

   RETURN .T.


STATIC FUNCTION key_handler( Ch, hParams )

   LOCAL nTr2
   LOCAL GetList := {}
   LOCAL nRec := RecNo()
   LOCAL nX := box_x_koord()
   LOCAL nY := box_y_koord()
   LOCAL nVrati := DE_CONT
   LOCAL nWA

   IF !( ( Ch == K_CTRL_T .OR. Ch == K_ENTER ) .AND. reccount2() == 0 )

      DO CASE

      CASE Ch == Asc( "K" ) .OR. Ch == Asc( "k" )

         RREPLACE field->marker WITH if( field->marker == "K", " ", "K" )
         nVrati := DE_REFRESH

      CASE Ch == K_CTRL_P

         nWA := Select()
         print_kompen( hParams )

         SELECT ( nWA )
         nVrati := DE_CONT

      CASE Ch == K_CTRL_N

         GO BOTTOM
         SKIP 1
         Scatter()
         Box(, 5, 70 )
         @ box_x_koord() + 2, box_y_koord() + 2 SAY8 "Br.računa " GET _brdok
         @ box_x_koord() + 3, box_y_koord() + 2 SAY8 "Iznos     " GET _iznosbhd
         READ
         BoxC()
         IF LastKey() == K_ESC
            GO ( nRec )
         ELSE
            APPEND BLANK
            Gather()
            nVrati := DE_REFRESH
         ENDIF

      CASE Ch == K_CTRL_T

         nVrati := browse_brisi_stavku()

      CASE Ch == K_ENTER

         Scatter()

         Box(, 5, 70 )
         @ box_x_koord() + 2, box_y_koord() + 2 SAY8 "Br.računa " GET _brdok
         @ box_x_koord() + 3, box_y_koord() + 2 SAY8 "Iznos     " GET _iznosbhd
         READ
         BoxC()

         IF LastKey() == K_ESC
            GO ( nRec )
         ELSE
            my_rlock()
            Gather()
            my_unlock()
            nVrati := DE_REFRESH
         ENDIF

      CASE Ch == Asc( "T" ) .OR. Ch == Asc( "t" )

         IF Alias() == "KOMP_DUG"
            SELECT komp_pot
            GO TOP
         ELSEIF Alias() == "KOMP_POT"
            SELECT komp_dug
            GO TOP
         ENDIF

         nVrati := DE_ABORT

      ENDCASE

   ENDIF

   box_x_koord( nX )
   box_y_koord( nY )

   RETURN nVrati



STATIC FUNCTION print_kompen( hParams )

   LOCAL _id_pov := Space( 6 )
   LOCAL _id_partn := Space( 6 )
   LOCAL _br_komp := Space( 10 )
   LOCAL nX := 1
   LOCAL _dat_komp := Date()
   LOCAL _rok_pl := 7
   LOCAL _valuta := "D"
   LOCAL _saldo
   LOCAL lRet := .T.
   LOCAL cFilter := "komp*.odt"
   LOCAL _template := ""
   LOCAL _templates_path := f18_template_location()
   LOCAL _xml_file := my_home() + "data.xml"
   LOCAL GetList := {}

   IF !Empty( hParams[ "partn" ] )
      _id_partn := hParams[ "partn" ]
   ENDIF

   download_template( "komp_01.odt", "7623ca44a8f2a0126dbb73540943e974f2e860cf884189ea9c5c67294cd87bc4" )

   _id_pov := fetch_metric( "fin_kompen_id_povjerioca", my_home(), _id_pov )
   _br_komp := fetch_metric( "fin_kompen_broj", my_home(), _br_komp )
   _rok_pl := fetch_metric( "fin_kompen_rok_placanja", my_home(), _rok_pl )
   _valuta := fetch_metric( "fin_kompen_valuta", my_home(), _valuta )

   Box(, 10, 50 )
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Datum kompenzacije: " GET _dat_komp

   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Rok plaćanja (dana): " GET _rok_pl VALID _rok_pl >= 0 PICT "999"
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Valuta kompenzacije (D/P): " GET _valuta  VALID _valuta $ "DP"  PICT "!@"
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Broj kompenzacije: " GET _br_komp

   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Šifra (ID) povjerioca: " GET _id_pov VALID p_partner( @_id_pov ) PICT "@!"
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "   Šifra (ID) dužnika: " GET _id_partn VALID p_partner( @_id_partn ) PICT "@!"
   READ
   BoxC()

   IF LastKey() == K_ESC
      lRet := .F.
      RETURN lRet
   ENDIF

   set_metric( "fin_kompen_id_povjerioca", my_home(), _id_pov )
   set_metric( "fin_kompen_broj", my_home(), _br_komp )
   set_metric( "fin_kompen_rok_placanja", my_home(), _rok_pl )
   set_metric( "fin_kompen_valuta", my_home(), _valuta )

   hParams[ "id_pov" ] := _id_pov
   hParams[ "komp_broj" ] := _br_komp
   hParams[ "rok_pl" ] := _rok_pl
   hParams[ "valuta" ] := _valuta
   hParams[ "datum" ] := _dat_komp

   IF Empty( hParams[ "partn" ] )
      hParams[ "partn" ] := _id_partn
   ENDIF

   IF !_gen_xml( hParams, _xml_file )
      lRet := .F.
      RETURN lRet
   ENDIF

   IF get_file_list_array( _templates_path, cFilter, @_template, .T. ) == 0
      RETURN .F.
   ENDIF

   IF generisi_odt_iz_xml( _template, _xml_file )
      prikazi_odt()
   ENDIF

   RETURN lRet


STATIC FUNCTION _gen_xml( hParams, cXmlFile )

   LOCAL lRet := .T.
   LOCAL _id_pov, _br_komp, _rok_pl, _valuta
   LOCAL dDatOd, dDatDo, _partner
   LOCAL _temp_duz := .T.
   LOCAL _temp_pov := .T.
   LOCAL _br_st := 0
   LOCAL _ukupno_duz := 0
   LOCAL _ukupno_pov := 0
   LOCAL _broj_dok_duz, _broj_dok_pov
   LOCAL _iznos_duz, _iznos_pov
   LOCAL _dat_komp

   _id_pov := hParams[ "id_pov" ]
   _br_komp := hParams[ "komp_broj" ]
   _rok_pl := hParams[ "rok_pl" ]
   _valuta := hParams[ "valuta" ]
   _partner := hParams[ "partn" ]
   dDatOd := hParams[ "dat_od" ]
   dDatDo := hParams[ "dat_do" ]
   _dat_komp := hParams[ "datum" ]

   create_xml( cXmlFile )

   xml_head()

   xml_subnode( "kompen", .F. )

   // povjerioc
   IF !_fill_partn( _id_pov, "pov" )
      RETURN .F.
   ENDIF

   // duznik
   IF !_fill_partn( _partner, "duz" )
      RETURN .F.
   ENDIF

   SELECT komp_dug
   GO TOP
   SELECT komp_pot
   GO TOP

   _skip_t_marker( @_temp_duz, @_temp_pov )

   xml_subnode( "tabela", .F. )

   SELECT komp_pot

   DO WHILE _temp_duz .OR. _temp_pov

      ++_br_st

      xml_subnode( "item", .F. )

      _broj_stavke := AllTrim( Str( _br_st ) )

      _iznos_pov := 0
      _iznos_duz := 0

      _broj_dok_duz := ""
      _broj_dok_pov := ""

      IF _temp_pov
         _broj_dok_pov := AllTrim( field->brdok )
         _iznos_pov := field->iznosbhd
      ENDIF

      xml_node( "rbr", _broj_stavke )
      xml_node( "dok_pov", to_xml_encoding( _broj_dok_pov ) )
      xml_node( "izn_pov", AllTrim( Str( _iznos_pov, 17, 2 ) ) )

      SELECT komp_dug

      IF _temp_duz
         _broj_dok_duz := AllTrim( field->brdok )
         _iznos_duz := field->iznosbhd
      ENDIF

      xml_node( "dok_duz", to_xml_encoding( _broj_dok_duz  ) )
      xml_node( "izn_duz", AllTrim( Str( _iznos_duz, 17, 2 ) ) )

      xml_subnode( "item", .T. )

      _ukupno_duz += _iznos_duz
      _ukupno_pov += _iznos_pov

      SKIP 1

      SELECT komp_pot
      SKIP 1

      _skip_t_marker( @_temp_duz, @_temp_pov )

   ENDDO

   xml_subnode( "tabela", .T. )

   // totali
   xml_node( "total_duz", AllTrim( Str( _ukupno_duz, 17, 2 ) ) )
   xml_node( "total_pov", AllTrim( Str( _ukupno_pov, 17, 2 ) ) )
   xml_node( "total_komp", AllTrim( Str( Min( Abs( _ukupno_duz ), Abs( _ukupno_pov ) ), 17, 2 ) ) )
   xml_node( "saldo", AllTrim( Str( Abs( _ukupno_duz - _ukupno_pov ), 17, 2 ) ) )

   // generalni podaci kompenzacije
   xml_node( "broj", to_xml_encoding( AllTrim( _br_komp ) ) )
   xml_node( "rok_pl", to_xml_encoding( AllTrim( Str( _rok_pl ) ) ) )
   xml_node( "valuta", AllTrim( _valuta ) )
   xml_node( "per_od", DToC( dDatOd ) )
   xml_node( "per_do", DToC( dDatDo ) )
   xml_node( "datum", DToC( _dat_komp ) )

   xml_subnode( "kompen", .T. )

   close_xml()

   RETURN lRet


STATIC FUNCTION _fill_partn( part_id, node_name )

   LOCAL lRet := .T.

   IF node_name == NIL
      node_name := "pov"
   ENDIF

   select_o_partner( part_id )

   IF !Found()
      MsgBeep( "Partner " + part_id + " ne postoji u sifrarniku !" )
      RETURN .F.
   ENDIF

   xml_subnode( node_name, .F. )

   // podaci povjerioca
   //
   // <pov>
   // <id>-</id>
   // <....
   // </pov>

   xml_node( "id", to_xml_encoding( AllTrim( field->id ) ) )
   xml_node( "naz", to_xml_encoding( AllTrim( field->naz ) ) )
   xml_node( "naz2", to_xml_encoding( AllTrim( field->naz2 ) ) )
   xml_node( "mjesto", to_xml_encoding( AllTrim( field->mjesto ) ) )
   xml_node( "d_ziror", to_xml_encoding( AllTrim( field->ziror ) ) )
   xml_node( "s_ziror", to_xml_encoding( AllTrim( field->dziror ) ) )
   xml_node( "tel", AllTrim( field->telefon ) )
   xml_node( "fax", AllTrim( field->fax ) )
   xml_node( "adr", to_xml_encoding ( AllTrim( field->adresa ) ) )
   xml_node( "ptt", AllTrim( field->ptt ) )

   xml_node( "id_broj", AllTrim( firma_pdv_broj( part_id ) ) )
   // xml_node( "por_broj", AllTrim( get_partn_sifk_sifv( "PORB", part_id, .F. ) ) )

   xml_subnode( node_name, .T. )

   RETURN lRet


STATIC FUNCTION _skip_t_marker( _mark_12, _mark_60 )

   LOCAL nArr := Select()

   SELECT komp_dug
   DO WHILE field->marker != "K" .AND. !Eof()
      SKIP 1
   ENDDO
   IF Eof()
      _mark_12 := .F.
   ENDIF

   SELECT komp_pot
   DO WHILE field->marker != "K" .AND. !Eof()
      SKIP 1
   ENDDO
   IF Eof()
      _mark_60 := .F.
   ENDIF

   SELECT ( nArr )

   RETURN NIL



STATIC FUNCTION _o_tables()

   O_KOMP_POT
   O_KOMP_DUG
   // o_konto()
   // o_partner()

   RETURN .T.
