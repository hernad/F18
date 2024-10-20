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


STATIC s_lSanacije


FUNCTION os_obracuni()

   LOCAL _izbor := 1
   LOCAL _opc := {}
   LOCAL _opcexe := {}

   s_lSanacije := .F.

   cTip := IF( gDrugaVal == "D", valuta_domaca_skraceni_naziv(), "" )
   cBBV := cTip
   nBBK := 1

   AAdd( _opc, "1. amortizacija       " )
   AAdd( _opcexe, {|| os_obracun_amortizacije() } )
   AAdd( _opc, "2. revalorizacija" )
   AAdd( _opcexe, {|| os_obracun_revalorizacije() } )

   f18_menu( "obracun", .F., _izbor, _opc, _opcexe )

   RETURN .T.


FUNCTION os_obracun_amortizacije()

   LOCAL cAGrupe := "N"
   LOCAL nRec
   LOCAL dDatObr
   LOCAL nMjesOd
   LOCAL nMjesDo
   LOCAL cLine := ""
   LOCAL hRec
   LOCAL _san := fetch_metric( "os_obracun_sanacija", NIL, "N" )
   LOCAL _datum_otpisa
   LOCAL _iznos_sanacije := hb_Hash()
   LOCAL nTNab := 0
   LOCAL nTOtp := 0
   LOCAL nTAmortizacijaP := 0
   LOCAL hAmortizacija
   LOCAL GetList := {}
   LOCAL cIdSredstvo

   PRIVATE nGStopa := 100

   //o_amort()

   //o_os_sii()
   //o_os_sii_promj()

   dDatObr := os_datum_obracuna()
   cFiltK1 := Space( 40 )
   cVarPrik := "N"

   Box( "#OBRAČUN AMORTIZACIJE", 10, 60 )

   DO WHILE .T.

      @ box_x_koord() + 1, box_y_koord() + 2 SAY8 "Datum obračuna:" GET dDatObr
      @ box_x_koord() + 2, box_y_koord() + 2 SAY8 "Varijanta ubrzane amortizacije po grupama ?" GET cAGrupe PICT "@!"
      @ box_x_koord() + 4, box_y_koord() + 2 SAY8 "Pomnožiti obracun sa koeficijentom (%)" GET nGStopa PICT "999.99"
      @ box_x_koord() + 5, box_y_koord() + 2 SAY8 "Filter po grupaciji K1:" GET cFiltK1 PICT "@!S20"

      @ box_x_koord() + 6, box_y_koord() + 2 SAY8 "Varijanta prikaza"
      @ box_x_koord() + 7, box_y_koord() + 2 SAY8 "pred.amort + tek.amort (D/N)?" GET cVarPrik PICT "@!" VALID cVarPrik $ "DN"

      @ box_x_koord() + 9, box_y_koord() + 2 SAY8 "Obračunavati sanacije na sredstvima (D/N) ?" GET _san VALID _san $ "DN" PICT "@!"
      READ

      ESC_BCR
      aUsl1 := Parsiraj( cFiltK1, "K1" )
      IF aUsl1 <> NIL
         EXIT
      ENDIF
   ENDDO
   BoxC()

   set_metric( "os_obracun_sanacija", NIL, _san )

   IF _san == "D"
      s_lSanacije := .T.
   ENDIF

   select_o_os_or_sii()
   SET ORDER TO TAG "5"
   IF !Empty( cFiltK1 )
      SET FILTER to &aUsl1
   ENDIF

   GO TOP

   os_rpt_default_valute()

   START PRINT CRET

   P_COND2

   // stampaj header
   _p_header( @cLine, dDatObr, nGStopa, cFiltK1, cVarPrik )

   PRIVATE nOstalo := 0
   PRIVATE nUkupno := 0

   DO WHILE !Eof()

      cIdam := field->idam

      select_o_amort( cIdAm )

      select_o_os_or_sii()

      ? cLine

      ? "Amortizaciona stopa:", cIdAm, amort->naz, "  Stopa:", amort->iznos, "%"

      IF nGStopa <> 100
         ?? " ", "efektivno ", Transform( Round( amort->iznos * nGStopa / 100, 3 ), "999.999%" )
      ENDIF

      ? cLine

      PRIVATE nRGr := 0
      nRGr := RecNo()
      nOstalo := 0

      nTNab := nTOtp := nTAmortizacijaP := 0

      DO WHILE !Eof() .AND. field->idam == cIdAm

         set_global_memvars_from_dbf()

         _datum_otpisa := fix_dat_var( _datotp ) // setuj datum otpisa ako postoji

         select_o_amort( _idam )

         select_o_os_or_sii()

         IF !Empty( _datotp ) .AND. Year( _datotp ) < Year( dDatObr )

            SKIP // otpisano sredstvo, ne amortizuj
            LOOP
         ENDIF

         // izracunaj iznos sanacije ... ako postoji ?
         _iznos_sanacije := os_sii_iznos_sanacije( field->id, ;
            _datum, ;
            iif( !Empty( _datotp ), ;
            Min( dDatOBr, _datotp ), ;
            dDatObr - dana_u_mjesecu( dDatObr ) ;
            ) ;
            )

         // izracunaj amortizaciju do predh.mjeseca...
         hAmortizacija := os_izracunaj_amortizaciju( _nabvr, _otpvr, nOstalo, _datum, ;
            iif( !Empty( _datotp ), Min( dDatOBr, _datotp ), dDatObr - dana_u_mjesecu( dDatObr ) ), ;
            nGStopa, ;
            _iznos_sanacije ;
            )

          nPredAm := hAmortizacija[ "potrazuje" ]

         // izracunaj iznos sanacije ... ako postoji ?
         _iznos_sanacije := os_sii_iznos_sanacije( field->id, ;
            _datum, ;
            iif( !Empty( _datotp ), Min( dDatOBr, _datotp ), dDatObr ) ;
            )

         hAmortizacija := os_izracunaj_amortizaciju( _nabvr, _otpvr, nOstalo, _datum, ;
            iif( !Empty( _datotp ), Min( dDatOBr, _datotp ), dDatObr ), ;
            nGStopa, ;
            _iznos_sanacije ;
            )

         _amd := hAmortizacija[ "duguje" ]
         _amp := hAmortizacija[ "potrazuje" ]
         _nabvr := hAmortizacija[ "nabvr" ]
         _otpvr := hAmortizacija[ "otpvr" ]
         nOstalo := hAmortizacija[ "ostalo" ]



         IF cAGrupe == "N" // napuni _amp

            ? _id, _datum, naz

            @ PRow(), PCol() + 1 SAY _nabvr * nBBK PICT gpici
            @ PRow(), PCol() + 1 SAY _otpvr * nBBK PICT gpici

            // ako treba prikazivati rasclanjeno...
            IF cVarPrik == "D"
               @ PRow(), PCol() + 1 SAY nPredAm * nBBK PICT gpici
               @ PRow(), PCol() + 1 SAY ( _amp - nPredAm ) * nBBK PICT gpici
            ENDIF

            @ PRow(), PCol() + 1 SAY _amp * nBBK PICT gpici
            @ PRow(), PCol() + 1 SAY _datotp PICT gpici

            nUkupno += Round( _amp, 2 )

         ENDIF

         nTNab += _nabvr
         nTOtp += _otpvr
         nTAmortizacijaP += _amp

         cIdSredstvo := _id

         hRec := get_hash_record_from_global_vars()

         SET DEVICE TO SCREEN

//if left( cIdSredstvo, 6 ) == "022015"
//altd()
//endif
         select_o_os_or_sii()
         update_rec_server_and_dbf( Alias(), hRec, 1, "FULL" )

         SET DEVICE TO PRINTER

//if left( cIdSredstvo, 4 ) == "0140"
//altd()
//endif
         // amortizacija promjena
         os_select_promj( cIdSredstvo )

         DO WHILE !Eof() .AND. field->id == cIdSredstvo .AND. field->datum <= dDatObr

            set_global_memvars_from_dbf()

            IF s_lSanacije .AND. Left( field->opis, 2 ) == "#S"
               // ovo preskacemo za obracun...
               nPredAm := 0
               _amp := 0

               // suma sumarum sanacije... jer moze biti i drugih sredstava i promjena
               nTAmortizacijaP += _amp
               nTNab += _nabvr
               nTOtp += _otpvr

            ELSE

               // izracunaj za predh.mjesec...
               hAmortizacija := os_izracunaj_amortizaciju( _nabvr, _otpvr, nOstalo, _datum, dDatObr - dana_u_mjesecu( dDatObr ), nGStopa )
               nPredAm := hAmortizacija[ "potrazuje" ]

               hAmortizacija := os_izracunaj_amortizaciju( _nabvr, _otpvr, nOstalo, _datum, dDatObr, nGStopa )

               _amd := hAmortizacija[ "duguje" ]
               _amp := hAmortizacija[ "potrazuje" ]
               _nabvr := hAmortizacija[ "nabvr" ]
               _otpvr := hAmortizacija[ "otpvr" ]
               nOstalo := hAmortizacija[ "ostalo" ]

            ENDIF

            IF cAGrupe == "N"

               ? Space( 10 ), _datum, opis

               @ PRow(), PCol() + 1 SAY _nabvr * nBBK PICT gpici
               @ PRow(), PCol() + 1 SAY _otpvr * nBBK PICT gpici

               IF cVarPrik == "D"
                  @ PRow(), PCol() + 1 SAY nPredAm * nBBK PICT gpici
                  @ PRow(), PCol() + 1 SAY ( _amp - nPredam ) * nBBK PICT gpici
               ENDIF

               @ PRow(), PCol() + 1 SAY _amp * nBBK PICT gpici
               @ PRow(), PCol() + 1 SAY _datum_otpisa PICT gpici

               nUkupno += Round( _amp, 2 )

            ENDIF

            hRec := get_hash_record_from_global_vars()

            SET DEVICE TO SCREEN

            os_select_promj_area()
            update_rec_server_and_dbf( Alias(), hRec, 1, "FULL" )

            SET DEVICE TO PRINTER

            SKIP

         ENDDO

         select_o_os_or_sii()
         SKIP

         // prikaz ukupnog obracuna sanacije...
         IF cAGrupe == "N" .AND. _iznos_sanacije[ "nabvr" ] <> 0
            ? Space( 35 ) + Replicate( "-", 60 )
            ? PadL( "Ukupni obracun sanacija:", 50 )
            @ PRow(), PCol() + 1 SAY nTNab PICT gpici
            @ PRow(), PCol() + 1 SAY nTOtp PICT gpici
            @ PRow(), PCol() + 1 SAY nTAmortizacijaP PICT gpici
            ?
         ENDIF

      ENDDO

      // drugi prolaz
      IF cAGrupe == "D"

         select_o_os_or_sii()
         GO nRGr

         DO WHILE !Eof() .AND. field->idam == cIdAm

            set_global_memvars_from_dbf()

            // setuj datum otpisa
            _datum_otpisa := fix_dat_var( _datotp )

            IF !Empty( _datotp ) .AND. Year( _datotp ) < Year( dDatobr )
               // otpisano sredstvo, ne amortizuj
               SKIP
               LOOP
            ENDIF

            IF _nabvr > 0
               IF _nabvr - _otpvr - _amp > 0
                  // ostao je neamortizovani dio
                  PRIVATE nAm2 := Min( _nabvr - _otpvr - _amp, nOstalo )
                  nOstalo := nOstalo - nAm2
                  _amp := _amp + nAm2
               ENDIF
            ELSE

               _nabvr := -_nabvr
               _otpvr := -_otpvr
               _amp := -_amp

               IF _nabvr - _otpvr - _amp > 0
                  // ostao je neamortizovani dio
                  PRIVATE nAm2 := Min( ( _nabvr - _otpvr - _amp ), nOstalo )
                  nOstalo := nOstalo - nAm2
                  _amp := _amp + nAm2
               ENDIF

               _nabvr := -_nabvr
               _otpvr := -_otpvr
               _amp := -_amp
            ENDIF

            ? _id, _datum, naz

            @ PRow(), PCol() + 1 SAY _nabvr * nBBK PICT gpici
            @ PRow(), PCol() + 1 SAY _otpvr * nBBK PICT gpici

            IF cVarPrik == "D"

               @ PRow(), PCol() + 1 SAY 0 PICT gpici
               @ PRow(), PCol() + 1 SAY 0 PICT gpici

            ENDIF

            @ PRow(), PCol() + 1 SAY _amp * nBBK PICT gpici
            @ PRow(), PCol() + 1 SAY fix_dat_var( _datotp ) PICT gpici

            nUkupno += Round( _amp, 2 )

            cIdSredstvo := _id

            hRec := get_hash_record_from_global_vars()

            SET DEVICE TO SCREEN

            select_o_os_or_sii_area()
            update_rec_server_and_dbf( Alias(), hRec, 1, "FULL" )

            SET DEVICE TO PRINTER

//altd()
            // amortizacija promjena
            os_select_promj( cIdSredstvo )
            //HSEEK cIdSredstvo

            DO WHILE !Eof() .AND. field->id == cIdSredstvo .AND. field->datum <= dDatObr

               set_global_memvars_from_dbf()

               IF _nabvr > 0
                  IF _nabvr - _otpvr - _amp > 0
                     // ostao je neamortizovani dio
                     PRIVATE nAm2 := Min( _nabvr - _otpvr - _amp, nOstalo )
                     nOstalo := nOstalo - nAm2
                     _amp := _amp + nAm2
                  ENDIF
               ELSE
                  _nabvr := -_nabvr
                  _otpvr := -_otpvr
                  _amp := -_amp
                  IF _nabvr - _otpvr - _amp > 0
                     // ostao je neamortizovani dio
                     PRIVATE nAm2 := Min( _nabvr - _otpvr - _amp, nOstalo )
                     nOstalo := nOstalo - nAm2
                     _amp := _amp + nAm2
                  ENDIF
                  _nabvr := -_nabvr
                  _otpvr := -_otpvr
                  _amp := -_amp
               ENDIF

               ? Space( 10 ), _datum, _opis
               @ PRow(), PCol() + 1 SAY _nabvr * nBBK PICT gpici
               @ PRow(), PCol() + 1 SAY _otpvr * nBBK PICT gpici

               IF cVarPrik == "D"
                  @ PRow(), PCol() + 1 SAY 0 PICT gpici
                  @ PRow(), PCol() + 1 SAY 0 PICT gpici
               ENDIF

               @ PRow(), PCol() + 1 SAY _amp * nBBK PICT gpici

               nUkupno += Round( _amp, 2 )

               // sinhronizuj podatke sql/server
               hRec := get_hash_record_from_global_vars()

               SET DEVICE TO SCREEN

//altd()
               os_select_promj_area()
               update_rec_server_and_dbf( Alias(), hRec, 1, "FULL" )

               SET DEVICE TO PRINTER

               SKIP

            ENDDO

            select_o_os_or_sii()
            SKIP

         ENDDO

         ? cLine
         ? "Za grupu ", cIdAm, "ostalo je nerasporedjeno", Transform( nOstalo * nBBK, gPici )
         ? cLine

      ENDIF
      // grupa

   ENDDO

   ? cLine
   ?
   ? "Ukupan iznos amortizacije:"

   @ PRow(), PCol() + 1 SAY nUkupno * nBBK PICT "99,999,999,999,999"

   FF
   ENDPRINT

   my_close_all_dbf()

   RETURN .T.



// ------------------------------------------------------------------
// prikaz headera
// ------------------------------------------------------------------
STATIC FUNCTION _p_header( cLine, dDatObr, nGStopa, cFiltK1, cVar )

   LOCAL cTxt := ""

   // linija
   cLine := ""
   cLine += Replicate( "-", 10 )
   cLine += " "
   cLine += Replicate( "-", 8 )
   cLine += " "
   cLine += Replicate( "-", 29 )
   cLine += " "
   cLine += Replicate( "-", 12 )
   cLine += " "
   cLine += Replicate( "-", 11 )

   IF cVar == "D"

      cLine += " "
      cLine += Replicate( "-", 11 )
      cLine += " "
      cLine += Replicate( "-", 11 )

   ENDIF

   cLine += " "
   cLine += Replicate( "-", 11 )
   cLine += " "
   cLine += Replicate( "-", 8 )

   // tekst
   cTxt += PadC( "INV.BR", 10 )
   cTxt += " "
   cTxt += PadC( "DatNab", 8 )
   cTxt += " "
   cTxt += PadC( "Sredstvo", 29 )
   cTxt += " "
   cTxt += PadC( "Nab.vr", 12 )
   cTxt += " "
   cTxt += PadC( "Otp.vr", 11 )

   IF cVar == "D"

      cTxt += " "
      cTxt += PadC( "Pred.amort", 11 )
      cTxt += " "
      cTxt += PadC( "Tek.amort", 11 )

   ENDIF

   cTxt += " "
   cTxt += PadC( "Amortiz.", 11 )
   cTxt += " "
   cTxt += PadC( "Dat.Otp", 8 )

   ?

   P_10CPI

   ? "OS: Pregled obracuna amortizacije", PrikazVal(), Space( 9 ), "Datum obracuna:", dDatObr

   IF ( nGStopa <> 100 )
      ?
      ? "Obracun se mnozi sa koeficijentom (%) ", Transform( nGStopa, "999.99" )
      ?
   ENDIF

   IF !Empty( cFiltK1 )
      ? "Filter grupacija K1 pravljen po uslovu: '" + Trim( cFiltK1 ) + "'"
   ENDIF

   P_COND

   ?
   ? cLine
   ? cTxt
   ? cLine
   ?

   RETURN .T.



// ----------------------------
// koliko dana ima u mjesecu
// ----------------------------
FUNCTION dana_u_mjesecu( dDate )

   LOCAL nDana

   DO CASE
   CASE Month( dDate ) == 1
      nDana := 31
   CASE Month( dDate ) == 2
      nDana := 28
   CASE Month( dDate ) == 3
      nDana := 31
   CASE Month( dDate ) == 4
      nDana := 30
   CASE Month( dDate ) == 5
      nDana := 31
   CASE Month( dDate ) == 6
      nDana := 30
   CASE Month( dDate ) == 7
      nDana := 31
   CASE Month( dDate ) == 8
      nDana := 31
   CASE Month( dDate ) == 9
      nDana := 30
   CASE Month( dDate ) == 10
      nDana := 31
   CASE Month( dDate ) == 11
      nDana := 30
   CASE Month( dDate ) == 12
      nDana := 31
   ENDCASE

   RETURN nDana




FUNCTION os_sii_iznos_sanacije( id, datum_od, datum_do )

   LOCAL _nab := 0
   LOCAL _otp := 0
   LOCAL cQuery, _data, oRow
   LOCAL _hash := hb_Hash()

   _hash[ "otpvr" ] := 0
   _hash[ "nabvr" ] := 0

   IF gOsSII == "S" .OR. s_lSanacije == .F.
      RETURN _hash
   ENDIF

   cQuery := "SELECT "
   cQuery += " id, "
   cQuery += " opis, "
   cQuery += " datum, "
   cQuery += " nabvr, "
   cQuery += " otpvr "
   cQuery += "FROM " + F18_PSQL_SCHEMA_DOT + "os_promj "
   cQuery += "WHERE id = " + sql_quote( id )
   cQuery += "  AND opis LIKE '#S%' "
   cQuery += "  AND " + _sql_date_parse( "datum", datum_od, datum_do )
   cQuery += "ORDER BY datum "

   _data := run_sql_query( cQuery )

   IF !is_var_objekat_tpqquery( _data )
      RETURN _hash
   ENDIF

   _data:GoTo( 1 )

   DO WHILE !_data:Eof()
      oRow := _data:GetRow()
      _nab += oRow:FieldGet( oRow:FieldPos( "nabvr" ) )
      _otp += oRow:FieldGet( oRow:FieldPos( "otpvr" ) )
      _data:SKIP()
   ENDDO

   _hash[ "otpvr" ] := _otp
   _hash[ "nabvr" ] := _nab

   RETURN _hash




// --------------------------------------------
// izracun amortizacije
// d1 - od mjeseca
// d2 - do mjeseca
// nOstalo se uvecava za onaj dio koji se na
// nekom sredstvu ne moze amortizovati
// --------------------------------------------
FUNCTION os_izracunaj_amortizaciju( nNabVr, nOtpVr, nOstalo, d1, d2, nGAmort, sanacije )

   LOCAL nMjesOd
   LOCAL nMjesDo
   LOCAL nIzn
   LOCAL fStorno
   LOCAL nSanacijeNab
   LOCAL nSanacijeOtp
   LOCAL hAmortizacija := hb_hash()

   IF gMetodObr == "1" // tekuca metoda
      RETURN os_proracun_amortizacija_od_do( nNabVr, nOtpvr, nOstalo, d1, d2, nGAmort, sanacije )
   ENDIF

   IF sanacije == NIL
      nSanacijeNab := 0
      nSanacijeOtp := 0
   ELSE
      nSanacijeNab := sanacije[ "nabvr" ]
      nSanacijeOtp := sanacije[ "otpvr" ]
   ENDIF

   // ako je metoda obracuna od 1 u narednom mjesecu
   fStorno := .F.

   IF ( gVarDio == "D" ) .AND. !Empty( gDatDio )
      d1 := Max( d1, gDatDio )
   ENDIF

   IF Year( d1 ) < Year( d2 )
      nMjesOd := 1
   ELSE
      nMjesOd := Month( d1 ) + 1
   ENDIF

   IF Day( d2 ) >= 28 .OR. gVObracun == "2"
      nMjesDo := Month( d2 ) + 1
   ELSE
      nMjesDo := Month( d2 )
   ENDIF

   IF nNabVr < 0
      // stornirani dio
      fStorno := .T.
      nNabVr := - nNabvr
      nOtpVr := - nOtpvr
   ENDIF

   nIzn := Round( ( nNabvr - nSanacijeNab ) * Round( amort->iznos * iif( nGamort <> 100, nGamort / 100, 1 ), 3 ) / 100 * ;
      ( nMjesDo - nMjesOD ) / 12, 2 )

   hAmortizacija[ "duguje" ] := 0

   IF ( nNabvr - nOtpvr - nIzn ) < 0
      hAmortizacija[ "potrazuje" ] := nNabvr - nOtpvr
      nOstalo += nIzn - ( nNabvr - nOtpvr )
   ELSE
      hAmortizacija[ "potrazuje" ] := nIzn
   ENDIF

   IF hAmortizacija[ "potrazuje"]  < 0
      hAmortizacija[ "potrazuje" ] := 0
   ENDIF

   IF fStorno
      nNabvr := - nNabvr
      nOtpvr := - nOtpvr
      hAmortizacija[ "potrazuje" ] := - hAmortizacija[ "potrazuje" ]
   ENDIF

   hAmortizacija[ "nabvr" ] := nNabVr
   hAmortizacija[ "otpvr" ] := nOtpVr
   hAmortizacija[ "ostalo" ] := nOstalo

   RETURN hAmortizacija



// --------------------------------------------
// izracun amortizacije 2006 >
// d1 - od mjeseca
// d2 - do mjeseca
// --------------------------------------------
FUNCTION os_proracun_amortizacija_od_do( nNabVr, nOtpVr, nOstalo, d1, d2, nGAmort, sanacije )

   LOCAL nMjesOd
   LOCAL nMjesDo
   LOCAL nIzn
   LOCAL fStorno
   LOCAL nSanacijeNab := 0
   LOCAL nSanacijeOtp := 0
   LOCAL hAmortizacija := hb_hash()

   IF sanacije == NIL
      nSanacijeNab := 0
      nSanacijeOtp := 0
   ELSE
      nSanacijeNab := sanacije[ "nabvr" ]
      nSanacijeOtp := sanacije[ "otpvr" ]
   ENDIF

   fStorno := .F.

   IF ( gVarDio == "D" ) .AND. !Empty( gDatDio )
      d1 := Max( d1, gDatDio )
   ENDIF

   nTekMjesec := Month( d1 )
   nTekDan := Day( d1 )
   nTekBrDana := dana_u_mjesecu( d1 )

   IF Year( d1 ) < Year( d2 )
      nMjesOd := 1
   ELSE
      nMjesOd := Month( d1 ) + 1
   ENDIF

   IF Day( d2 ) >= 28 .OR. gVObracun == "2"
      nMjesDo := Month( d2 ) + 1
   ELSE
      nMjesDo := Month( d2 )
   ENDIF

   IF nNabvr < 0
      // stornirani dio
      fStorno := .T.
      nNabvr := - nNabvr
      nOtpvr := - nOtpvr
   ENDIF

   nIzn := 0

   IF Year( d1 ) == Year( d2 )
      // tekuci mjesec
      // samo za tekucu sezonu
      nIzn += Round( ( nNabvr - nSanacijeNab ) * Round( amort->iznos * iif( nGamort <> 100, nGamort / 100, 1 ), 3 ) / 100 * ( ( ( nTekBrDana - nTekDan ) / nTekBrDana ) / 12 ), 2 )
   ENDIF

   // ostali mjeseci
   nIzn += Round( ( nNabvr - nSanacijeNab ) * Round( amort->iznos * iif( nGamort <> 100, nGamort / 100, 1 ), 3 ) / 100 * ( nMjesDo - nMjesOd ) / 12, 2 )

   hAmortizacija[ "duguje" ] := 0

   IF ( nNabvr - nOtpvr - nIzn ) < 0
      hAmortizacija[ "potrazuje" ] := nNabvr - nOtpvr
      nOstalo +=  nIzn - ( nNabvr - nOtpvr )
   ELSE
      hAmortizacija[ "potrazuje" ] := nIzn
   ENDIF

   IF hAmortizacija[ "potrazuje" ] < 0
      hAmortizacija[ "potrazuje" ] := 0
   ENDIF

   IF fStorno
      nNabvr := - nNabvr
      nOtpvr := - nOtpvr
      hAmortizacija[ "potrazuje" ] := - hAmortizacija[ "potrazuje" ]
   ENDIF

   hAmortizacija[ "nabvr" ] := nNabVr
   hAmortizacija[ "otpvr" ] := nOtpVr
   hAmortizacija[ "ostalo" ] := nOstalo

   RETURN hAmortizacija




FUNCTION os_obracun_revalorizacije()

   LOCAL  cAGrupe := "D", nRec, dDatObr, nMjesOd, nMjesDo
   LOCAL nKoef
   LOCAL cIdSredstvo

   //o_reval()
   o_os_sii()
   //o_os_sii_promj()

   dDatObr := os_datum_obracuna()
   cFiltK1 := Space( 40 )

   Box( "#OBRACUN REVALORIZACIJE", 3, 60 )
   DO WHILE .T.
      @ box_x_koord() + 1, box_y_koord() + 2 SAY "Datum obracuna:" GET dDatObr
      @ box_x_koord() + 2, box_y_koord() + 2 SAY "Filter po grupaciji K1:" GET cFiltK1 PICT "@!S20"
      read; ESC_BCR
      aUsl1 := Parsiraj( cFiltK1, "K1" )
      IF aUsl1 <> NIL; exit; ENDIF
   ENDDO
   BoxC()

   select_o_os_or_sii()
   SET ORDER TO TAG "5"

   IF !Empty( cFiltK1 )
      SET FILTER to &aUsl1
   ENDIF
   GO TOP


   m := "---------- -------- ---- ---------------------------- ------------- ----------- ----------- ----------- ----------- -------"

   os_rpt_default_valute()

   start PRINT cret

   P_COND
   ? "OS: Pregled obracuna revalorizacije", PrikazVal(), Space( 9 ), "Datum obracuna:", dDatObr

   IF !Empty( cFiltK1 ); ? "Filter grupacija K1 pravljen po uslovu: '" + Trim( cFiltK1 ) + "'"; ENDIF

   ? m
   ? " INV.BR     DatNab  S.Rev     Sredstvo                  Nab.vr      Otp.vr+Am   Reval.DUG    Rev.POT    Rev.Am    Stopa"
   ? m

   _datotp := fix_dat_var(_datotp)

   nURevDug := 0
   nURevPot := 0
   nURevAm := 0
   DO WHILE !Eof()
      Scatter()
      _datotp := fix_dat_var(_datotp)

      IF !Empty( _datotp )  .AND. Year( _datotp ) < Year( dDatobr )    // otpisano sredstvo, ne amortizuj
         SKIP
         LOOP
      ENDIF
      select_o_reval( _idrev )
      select_o_os_or_sii()

      nRevAm := 0
      nKoef := izracunaj_os_reval( _datum, iif( !Empty( _datotp ), Min( dDatOBr, _datotp ), dDatObr ), @nRevAm )     // napuni _revp,_revd
      ? _id, _datum, _idrev, _naz
      @ PRow(), PCol() + 1 SAY _nabvr * nBBK     PICT gpici
      @ PRow(), PCol() + 1 SAY _otpvr * nBBK + _amp * nBBK     PICT gpici
      @ PRow(), PCol() + 1 SAY _revd * nBBK       PICT gpici
      @ PRow(), PCol() + 1 SAY _revp * nBBK - nRevAm * nBBK  PICT gpici
      @ PRow(), PCol() + 1 SAY nRevAm * nBBK       PICT gpici
      @ PRow(), PCol() + 1 SAY nkoef       PICT "9999.999"
      nURevDug += _revd
      nURevPot += _revp
      nURevAm += nRevAm
      Gather()

      cIdSredstvo := _id

      os_select_promj( cIdSredstvo )
      // HSEEK cIdSredstvo
      DO WHILE !Eof() .AND. id == cIdSredstvo .AND. datum <= dDatObr
         Scatter()
         nRevAm := 0
         nKoef := izracunaj_os_reval( _datum, iif( !Empty( _datotp ), Min( dDatOBr, _datotp ), dDatObr ), @nRevAm )
         ? Space( 10 ), _datum, _idrev, _opis
         @ PRow(), PCol() + 1 SAY _nabvr * nBBK      PICT gpici
         @ PRow(), PCol() + 1 SAY _otpvr * nBBK + _amp * nBBK PICT gpici
         @ PRow(), PCol() + 1 SAY _revd * nBBK       PICT gpici
         @ PRow(), PCol() + 1 SAY _revp * nBBK - nRevAm * nBBK  PICT gpici
         @ PRow(), PCol() + 1 SAY nRevAm * nBBK       PICT gpici
         @ PRow(), PCol() + 1 SAY nkoef       PICT "9999.999"
         nURevDug += _revd
         nURevPot += _revp
         nURevAm += nRevAm
         Gather()
         SKIP
      ENDDO

      select_o_os_or_sii()
      SKIP
   ENDDO
   ? m
   ?
   ?
   ? "Revalorizacija duguje           :", nURevDug * nBBK
   ?
   ? "Revalorizacija otp.vr potrazuje :", nURevPot * nBBK - nURevAm * nBBK
   ? "Revalorizacija amortizacije     :", nURevAm * nBBK
   ? "Ukupno revalorizacija potrazuje :", nURevPot * nBBK

   ? "------------------------------------------------------"
   ? "UKUPNO EFEKAT REVALORIZACIJE :", nURevDug * nBBK - nURevPot * nBBK
   ? "------------------------------------------------------"
   ?
   FF
   ENDPRINT
   closeret

   RETURN




// ************************
// d1 - od mjeseca, d2 do
// ************************
FUNCTION izracunaj_os_reval( d1, d2, nRevAm )

   // nRevAm - iznos revalorizacije amortizacije
   LOCAL nTrecRev
   LOCAL nMjesOD, nMjesDo, nIzn, nIzn2, nk1, nk2, nkoef

   IF Year( d1 ) < Year( d2 )
      //PushWA()
      //SELECT reval
      //nTrecRev := RecNo()
      IF select_o_reval( Str( Year( d1 ), 4 ) )
      //IF Found()
         nMjesOd := Month( d1 ) + 1
         c1 := "I" + AllTrim( Str( nMjesOd - 1 ) )
         nk1 := reval->&c1
         nMjesod := -100
      ELSE
         nMjesOd := 1
      ENDIF
      //GO nTrecRev // vrati se na tekucu poziciju
      //PopWa()
   ELSE
      // nMjesOd:=iif(day(d1)>1,month(d1)+1,month(d1))
      nMjesOd := Month( d1 ) + 1
   ENDIF
   IF Day( d2 ) >= 28 .OR. gVObracun == "2"
      nMjesDo := Month( d2 ) + 1
   ELSE
      nMjesDo := Month( d2 )
   ENDIF
   PRIVATE c1, c2 := ""
   c1 := "I" + AllTrim( Str( nMjesOd - 1 ) )
   c2 := "I" + AllTrim( Str( nMjesDo - 1 ) )
   IF nMjesOd <> -100  // ako je -100 onda je vec formiran nK1
      IF ( nMjesod - 1 ) < 1
         nk1 := 0
      ELSE
         nk1 := reval->&c1
      ENDIF
   ENDIF

   IF ( nMjesdo - 1 ) < 1
      nK2 := 0
   ELSE
      nK2 := reval->&c2
   ENDIF
   nkoef := ( nk2 + 1 ) / ( nk1 + 1 ) - 1
   nIzn := Round( _nabvr * nkoef, 2 )
   nIzn2 := Round( ( _otpvr + _amp ) * nkoef, 2 )
   nRevAm := Round( _amp * nkoef, 2 )
   _RevD := nIzn
   _RevP := nIzn2
   IF d2 < d1 // mjesdo < mjesod
      _REvd := 0
      _revp := 0
      nkoef := 0
   ENDIF

   RETURN nKoef
