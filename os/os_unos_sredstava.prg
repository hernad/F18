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


FUNCTION unos_osnovnih_sredstava()

   LOCAL hRec
   LOCAL cIdAmortizacija
   LOCAL GetList := {}

   PRIVATE cIdSredstvo := Space( 10 )
   PRIVATE cIdRj := Space( 4 )

   Box( "#UNOS PROMJENA NAD STALNIM SREDSTVIMA", f18_max_rows() -5, f18_max_cols() -5 )

   DO WHILE .T.

      BoxCLS()

      _o_tables()

      set_cursor_on()

      cPicSif := "@!"

      //IF gIBJ == "D"

         @ box_x_koord() + 1, box_y_koord() + 2 SAY "Sredstvo:       " GET cIdSredstvo VALID P_OS( @cIdSredstvo, 1, 35 ) PICT cPicSif
         READ

         nDbfArea := Select()

         select_o_os_or_sii()
         GO TOP
         SEEK cIdSredstvo
         cIdRj := field->idrj
         cIdAmortizacija := field->idam

         SELECT ( nDbfArea )

         @ box_x_koord() + 2, box_y_koord() + 2 SAY "Radna jedinica: " GET cIdRj VALID {|| P_RJ( @cIdRj, 2, 35 ), cIdRj := PadR( cIdRj, 4 ), .T. }
         READ

         ESC_BCR

      //ELSE

      //   DO WHILE .T.

      //      @ box_x_koord() + 1, box_y_koord() + 2 SAY "Sredstvo:       " GET cIdSredstvo PICT cPicSif
      //      @ box_x_koord() + 2, box_y_koord() + 2 SAY "Radna jedinica: " GET cIdRj
      //      READ

      //      ESC_BCR

      //      select_o_os_or_sii()

      //      SEEK cIdSredstvo
      //      cIdAmortizacija := field->idam

      //      DO WHILE !Eof() .AND. cIdSredstvo == field->id .AND. cIdRj != field->idrj
      //         SKIP 1
      //      ENDDO

        //    IF cIdSredstvo != field->id .OR. cIdRj != field->idrj
      //         Msg( "Izabrano sredstvo ne postoji!", 5 )
        //    ELSE
        //       select_o_rj( cIdRj )

        //       IF gOsSii == "O"
        //          @ box_x_koord() + 1, box_y_koord() + 35 SAY os->naz
        //       ELSE
        //          @ box_x_koord() + 1, box_y_koord() + 35 SAY sii->naz
        //       ENDIF

          //     @ box_x_koord() + 2, box_y_koord() + 35 SAY RJ->naz

          //     EXIT

        //    ENDIF

        // ENDDO

      //ENDIF

      select_o_amort( cIdAmortizacija )

      select_o_os_or_sii()

      IF ( cIdRj <> field->idrj )

         IF Pitanje(, "Jeste li sigurni da zelite promijeniti radnu jedinicu ovom sredstvu? (D/N)", " " ) == "D"
            hRec := dbf_get_rec()
            hRec[ "idrj" ] := cIdRj
            update_rec_server_and_dbf( Alias(), hRec, 1, "FULL" )
         ELSE
            cIdRj := field->idrj
            select_o_rj( cIdRj )
            select_o_os_or_sii()
            @ box_x_koord() + 2, box_y_koord() + 2 SAY "Radna jedinica: " GET cIdRj
            @ box_x_koord() + 2, box_y_koord() + 35 SAY RJ->naz
            CLEAR GETS
         ENDIF
      ENDIF

      @ box_x_koord() + 3, box_y_koord() + 2 SAY "Datum nabavke: "
      ?? field->datum

      IF !Empty( field->datotp )
         @ box_x_koord() + 3, box_y_koord() + 38 SAY "Datum otpisa: "
         ?? field->datotp
      ENDIF

      @ box_x_koord() + 4, box_y_koord() + 2 SAY "Nabavna vr.:"
      ?? Transform( field->nabvr, gPicI )
      @ box_x_koord() + 4, Col() + 2 SAY "Ispravka vr.:"
      ?? Transform( field->otpvr, gPicI )
      aVr := { field->nabvr, field->otpvr, 0 }

      // recno(), datum, DatOtp, NabVr, OtpVr, KumAmVr
      aSred := { { 0, field->datum, field->datotp, field->nabvr, field->otpvr, 0 } }

      PRIVATE dDatNab := field->datum
      PRIVATE dDatOtp := field->datotp
      PRIVATE cOpisOtp := field->opisotp

      os_select_promj()

      ImeKol := {}

      AAdd( ImeKol, { "DATUM",            {|| os_select_promj_area(), field->datum }                          } )
      AAdd( ImeKol, { "OPIS",             {|| field->opis }                          } )
      AAdd( ImeKol, { PadR( "Nabvr", 11 ),   {|| Transform( field->nabvr, gpici ) }     } )
      AAdd( ImeKol, { PadR( "OtpVr", 11 ),   {|| Transform( field->otpvr, gpici ) }     } )
      //AAdd( ImeKol, { PadR( "Kumul.SadVr", 11 ), {|| Transform( os_sadasnja_vrijednost(), gpici ) }     } )

      Kol := {}

      FOR i := 1 TO Len( ImeKol )
         AAdd( Kol, i )
      NEXT

      set_cursor_on()

      @ box_x_koord() + 20, box_y_koord() + 2 SAY "<ENT> Ispravka, <c-T> Brisi, <c-N> Nove prom, <c-O> Otpis, <c-I> Novi ID"

      os_unos_show_sadasnja_vrijednost( cIdSredstvo, @aVr, @aSred )

      DO WHILE .T.
         BrowseKey( box_x_koord() + 8, box_y_koord() + 1, box_x_koord() + f18_max_rows() - 5, box_y_koord() + f18_max_cols() -5, ;
             ImeKol, {| Ch| unos_os_promj_key_handler( Ch ) }, "id==cIdSredstvo", cIdSredstvo, 2, NIL, NIL, {|| os_sadasnja_vrijednost( @aSred ) < 0 } )


         IF ( aVr[ 1 ] -aVr[ 2 ] >= 0 )
            IF aVr[ 3 ] < 0
               MsgBeep( "Greska: sadasnja vrijednost sa uracunatom amortizacijom manja od nule! #Ispravite gresku!" )
            ELSE
               EXIT
            ENDIF
         ELSE
            MsgBeep( "Greska: sadasnja vrijednost manja od nule ! Ispravite gresku !" )
         ENDIF
         EXIT

      ENDDO

      my_close_all_dbf()
   ENDDO

   BoxC()

   //my_close_all_dbf()

   RETURN .T.


FUNCTION unos_os_promj_key_handler( Ch )

   LOCAL cDn := "N"
   LOCAL nRet := DE_CONT
   LOCAL nRec0 := RecNo()
   LOCAL hRec
   LOCAL nTrec
   LOCAL cNoviInventurniBroj
   LOCAL _prom_dat, _prom_opis, _prom_nv, _prom_ov
   LOCAL GetList := {}

   DO CASE

   CASE Ch == K_ENTER  .OR. Ch == K_CTRL_N

      IF Ch == K_ENTER
          IF Empty( field->Id )
             RETURN DE_CONT
          ENDIF
      ENDIF

      IF Ch == K_CTRL_N
         GO BOTTOM
         SKIP 1
      ENDIF

      os_select_promj_area()

      hRec := dbf_get_rec()

      _prom_dat := hRec[ "datum" ]
      _prom_opis := hRec[ "opis" ]
      _prom_nv := hRec[ "nabvr" ]
      _prom_ov := hRec[ "otpvr" ]

      Box(, 5, 50 )
      @ box_x_koord() + 1, box_y_koord() + 2 SAY "Datum:" GET _prom_dat VALID os_validate_date( @_prom_dat )
      @ box_x_koord() + 2, box_y_koord() + 2 SAY "Opis:"  GET _prom_opis
      @ box_x_koord() + 4, box_y_koord() + 2 SAY "nab vr" GET _prom_nv PICT "9999999.99"
      @ box_x_koord() + 5, box_y_koord() + 2 SAY "OTP vr" GET _prom_ov PICT "9999999.99"
      READ

      BoxC()

      IF LastKey() == K_ESC
         GO ( nRec0 )
         nRet := DE_CONT
      ELSE

         IF CH == K_CTRL_N
            APPEND BLANK
         ENDIF

         hRec[ "id" ] := cIdSredstvo
         hRec[ "opis" ] := _prom_opis
         hRec[ "datum" ] := _prom_dat
         hRec[ "nabvr" ] := _prom_nv
         hRec[ "otpvr" ] := _prom_ov

         update_rec_server_and_dbf( Alias(), hRec, 1, "FULL" )

         os_unos_show_sadasnja_vrijednost( cIdSredstvo, @aVr, @aSred )

         nRet := DE_REFRESH

      ENDIF

   CASE Ch == K_CTRL_T

      IF pitanje(, "Sigurno želite izbrisati promjenu ?", "N" ) == "D"
         os_select_promj_area()
         hRec := dbf_get_rec()
         delete_rec_server_and_dbf( Alias(), hRec, 1, "FULL" )
         os_unos_show_sadasnja_vrijednost( cIdSredstvo, @aVr, @aSred )
      ENDIF

      RETURN DE_REFRESH

   CASE Ch == K_CTRL_O

      select_o_os_or_sii()
      nKolotp := field->kolicina

      Box(, 5, 50 )

      @ box_x_koord() + 1, box_y_koord() + 2 SAY "Otpis sredstva"
      @ box_x_koord() + 3, box_y_koord() + 2 SAY "Datum: " GET dDatOtp VALID dDatOtp > dDatNab .OR. Empty( dDatOtp )
      @ box_x_koord() + 4, box_y_koord() + 2 SAY "Opis : " GET cOpisOtp

      IF field->kolicina > 1
         @ box_x_koord() + 5, box_y_koord() + 2 SAY8 "Količina koja se otpisuje:" GET nKolotp PICT "999999.99" VALID ( nKolotp <= field->kolicina .AND. nKolotp >= 1 )
      ENDIF

      READ

      BoxC()

      IF LastKey() == K_ESC
         os_select_promj_area()
         RETURN DE_CONT
      ENDIF

      fRastavljeno := .F.

      IF nKolotp < field->kolicina

         select_o_os_or_sii()

         hRec := dbf_get_rec()

         nNabVrJ := hRec[ "nabvr" ] / hRec[ "kolicina" ]
         nOtpVrJ := hRec[ "otpvr" ] / hRec[ "kolicina" ]

         // postojeci inv broj
         hRec[ "kolicina" ] := hRec[ "kolicina" ] - nKolOtp
         hRec[ "nabvr" ] := nNabVrj * hRec[ "kolicina" ]
         hRec[ "otpvr" ] := nOtpVrj * hRec[ "kolicina" ]

         update_rec_server_and_dbf( Alias(), hRec, 1, "FULL" )


         hRec := dbf_get_rec()
         APPEND BLANK

         hRec[ "kolicina" ] := nKolOtp
         hRec[ "nabvr" ] := nNabvrj * nKolotp
         hRec[ "otpvr" ] := nOtpvrj * nKolotp
         hRec[ "id" ] := Left( hRec[ "id" ], 9 ) + "O"
         hRec[ "datotp" ] := dDatotp
         hRec[ "opisotp" ] := cOpisOtp

         update_rec_server_and_dbf( Alias(), hRec, 1, "FULL" )

         fRastavljeno := .T.

      ELSE

         select_o_os_or_sii()
         hRec := dbf_get_rec()
         hRec[ "datotp" ] := dDatOtp
         hRec[ "opisotp" ] := cOpisOtp

         update_rec_server_and_dbf( Alias(), hRec, 1, "FULL" )

      ENDIF

      os_select_promj()

      @ box_x_koord() + 5, box_y_koord() + 38 SAY "Datum otpisa: "

      IF gOsSii == "O"
         ?? os->datotp
      ELSE
         ?? sii->datotp
      ENDIF

      IF fRastavljeno
         Msg( "Postojeći inv broj je rastavljen na dva-otpisani i neotpisani" )
         RETURN DE_ABORT
      ELSE
         RETURN DE_REFRESH
      ENDIF

   CASE Ch == K_CTRL_I

      Box(, 4, 50 )
      cNoviInventurniBroj := Space( 10 )
      @ box_x_koord() + 1, box_y_koord() + 2 SAY "Promjena inventurnog broja:"
      @ box_x_koord() + 3, box_y_koord() + 2 SAY "Novi inventurni broj:" GET cNoviInventurniBroj VALID !Empty( cNoviInventurniBroj )
      READ
      BoxC()

      ESC_RETURN DE_CONT

      select_o_os_or_sii()

      SEEK cNoviInventurniBroj

      IF Found()
         Beep( 1 )
         Msg( "Vec postoji sredstvo sa istim inventurnim brojem !" )
      ELSE

         os_select_promj( cIdSredstvo )
         nTrec := 0

         DO WHILE !Eof() .AND. cIdSredstvo == field->id
            SKIP
            nTrec := RecNo()
            SKIP -1
            hRec := dbf_get_rec()
            hRec[ "id" ] := cNoviInventurniBroj
            update_rec_server_and_dbf( Alias(), hRec, 1, "FULL" )
            GO ( nTrec )
         ENDDO
         SEEK cNoviInventurniBroj

         select_o_os_or_sii()
         SEEK cIdSredstvo
         hRec := dbf_get_rec()
         hRec[ "id" ] := cNoviInventurniBroj
         update_rec_server_and_dbf( Alias(), hRec, 1, "FULL" )
         cIdSredstvo := cNoviInventurniBroj
      ENDIF

      os_select_promj_area()
      RETURN DE_REFRESH

   OTHERWISE
      RETURN DE_CONT

   ENDCASE

   RETURN nRet


FUNCTION os_unos_show_sadasnja_vrijednost( cIdSredstvo, aVr, aSred )

   LOCAL _arr := Select()
   LOCAL nTrec := 0
   LOCAL nI := 0
   LOCAL hAmortizacija
   LOCAL dDatOtp

   select_o_os_or_sii()
   aVr[ 1 ] := field->nabvr
   aVr[ 2 ] := field->otpvr

   dDatOtp := field->datOtp

   os_select_promj( cIdSredstvo )

   FOR nI := Len( aSred ) TO 1 STEP -1
      IF aSred[ nI, 1 ] > 0 .AND. aSred[ nI, 1 ] < 999999
         ADel( aSred, nI )
         ASize( aSred, Len( aSred ) - 1 )
      ENDIF
   NEXT

   DO WHILE !Eof() .AND. field->id == cIdSredstvo
      aVr[ 1 ] += field->nabvr
      aVr[ 2 ] += field->otpvr
      AAdd( aSred, { RecNo(), field->datum, dDatOtp, field->nabvr, field->otpvr, 0 } )
      SKIP 1
   ENDDO

   ASort( aSred,,, {| x, y| x[ 2 ] < y[ 2 ] } )

   nI := 1

   FOR nI := 1 TO Len( aSred )

      _nabvr := aSred[ nI, 4 ]
      _otpvr := aSred[ nI, 5 ]

      //_amd := 0
      //_amp := 0

      nOstalo := 0
      _datum := aSred[ nI, 2 ]
      _datotp := aSred[ nI, 3 ]

      hAmortizacija := os_izracunaj_amortizaciju( _nabvr, _otpvr, nOstalo, _datum, iif( !Empty( _datotp ), Min( os_datum_obracuna(), _datotp ), os_datum_obracuna() ), 100 )

      _amd := hAmortizacija[ "duguje" ]
      _amp := hAmortizacija[ "potrazuje" ]

      // napuni _amp
      aSred[ nI, 6 ] := _amp
   NEXT

   SKIP -1
   IF field->id == cIdSredstvo
      aVr[ 3 ] := os_sadasnja_vrijednost( @aSred )
   ENDIF

   @ box_x_koord() + 6, box_y_koord() + 1 SAY " UKUPNO:   Nab.vr.="         COLOR "W+/B"
   @ Row(), Col()  SAY TRANS( aVr[ 1 ], "9999999.99" )        COLOR "GR+/B"

   @ Row(), Col()  SAY ",    Otp.vr.="         COLOR "W+/B"
   @ Row(), Col()  SAY TRANS( aVr[ 2 ], "9999999.99" )        COLOR "GR+/B"

   @ Row(), Col()  SAY ",    Sad.vr.="         COLOR "W+/B"
   @ Row(), Col()  SAY TRANS( aVr[ 1 ] - aVr[ 2 ], "9999999.99" ) COLOR IIF( aVr[ 1 ] - aVr[ 2 ] < 0, "GR+/R", "GR+/B" )

//   @ box_x_koord() + 7, box_y_koord() + 1 SAY8 "           Sadašnja vrijednost sa uračunatom amortizacijom=" COLOR "W+/B"
//   @ Row(), Col()  SAY TRANS( aVr[ 3 ], "9999999.99" )        COLOR IIF( aVr[ 3 ] < 0, "GR+/R", "GR+/B" )

   //GO ( nTrec )
   //SELECT ( _arr )
   select_o_os_or_sii()

   RETURN .T.



FUNCTION os_sadasnja_vrijednost( aSred )

   LOCAL nSadasnjaVr := 0
   LOCAL nI := 0

   FOR nI := 1 TO Len( aSred )
      nSadasnjaVr += ( aSred[ nI, 4 ] - aSred[ nI, 5 ] -aSred[ nI, 6 ] )
      IF nI == Len( aSred )
         aVr[ 3 ] := nSadasnjaVr
      ENDIF
      IF aSred[ nI, 1 ] == RecNo()
         EXIT
      ENDIF
   NEXT

   RETURN nSadasnjaVr




FUNCTION os_validate_date( os_date )

   LOCAL _ret := .T.

   IF os_date <= dDatNab
      Beep( 1 )
      Msg( "Datum promjene mora biti veci od datuma nabavke !" )
      _ret := .F.
   ENDIF

   IF !Empty( dDatOtp ) .AND. os_date >= dDatOtp
      Beep( 1 )
      Msg( "Datum promjene mora biti manji od datuma otpisa !" )
      _ret := .F.
   ENDIF

   RETURN _ret



STATIC FUNCTION _o_tables()

//   o_k1()
   //o_rj()
  // o_konto()
   //o_amort()
   //o_reval()
   o_os_sii()
   o_os_sii_promj()

   RETURN .T.
