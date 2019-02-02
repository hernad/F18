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

/*  Partneri van prometa
 */

FUNCTION PartVanProm()

   LOCAL   dDatOd := CToD ( "" ), dDatDo := Date ()
   PRIVATE picBHD := FormPicL( gPicBHD, 16 )
   PRIVATE picDEM := FormPicL( pic_iznos_eur(), 12 )
   PRIVATE cIdKonto := Space ( 7 ), cIdFirma := Space ( Len ( self_organizacija_id() ) ), ;
      cKrit := Space ( 60 ), aUsl

   o_konto()
   //o_partner()
   o_suban()

   Box (, 11, 60 )
   @ box_x_koord(), box_y_koord() + 15 SAY "PREGLED PARTNERA BEZ PROMETA"
   IF gNW == "D"
      cIdFirma := self_organizacija_id()
      @ box_x_koord() + 2, box_y_koord() + 2 SAY "Firma "; ?? self_organizacija_id(), "-", self_organizacija_naziv()
   ELSE
      @ box_x_koord() + 2, box_y_koord() + 2 SAY "Firma: " GET cIdFirma valid {|| p_partner( @cIdFirma ), cIdfirma := Left( cidfirma, 2 ), .T. }
   ENDIF
   @ box_x_koord() + 4, box_y_koord() + 2 SAY " Konto (prazno-svi)" GET cIdKonto ;
      VALID Empty ( cIdKonto ) .OR. p_konto ( @cIdKonto )
   @ box_x_koord() + 6, box_y_koord() + 2 SAY "Kriterij za telefon" GET cKrit PICT "@S30@!";
      VALID {|| aUsl := Parsiraj ( cKrit, "Telefon" ), ;
      iif ( aUsl == NIL, .F., .T. ) }
   @ box_x_koord() + 8, box_y_koord() + 2 SAY "         Pocevsi od" GET dDatOd ;
      VALID dDatOd <= dDatDo
   @ box_x_koord() + 10, box_y_koord() + 2 SAY "       Zakljucno sa" GET dDatDo ;
      VALID dDatOd <= dDatDo
   READ
   ESC_BCR
   BoxC()


   IF !start_print()
      RETURN .F.
   ENDIF

   INI
   ?
   F10CPI
   ?? Space ( 5 ) + "Firma:", self_organizacija_naziv()
   ? PadC ( "PARTNERI BEZ PROMETA", 80 )
   ? PadC ( "na dan " + DToC ( Date() ) + ".", 80 )
   ?
   PushWa()
   select_o_konto( cIdKonto )
   ? Space ( 5 ) + "    Konto:", ;
      iif ( Empty ( cIdKonto ), "SVI", cIdKonto + konto->Naz )
   PopWa()
   
   ? Space ( 5 ) + " Kriterij:", cKrit
   ? Space ( 5 ) + "Za period:", IIF ( Empty ( dDatOd ), "", DToC ( dDatOd ) + " " ) + ;
      "do", DToC ( dDatDo )
   ?
   ? Space ( 5 ) + PadR( "Sifra", FIELD_LEN_PARTNER_ID ), PadR( "NAZIV", 25 ), ;
      PadR ( "MJESTO", Len ( PARTN->Mjesto ) ), PadR ( "ADRESA", Len ( PARTN->Adresa ) )
   ? Space ( 5 ) + REPL( "-", FIELD_LEN_PARTNER_ID ), REPL ( "-", 25 ), ;
      REPL ( "-", Len ( PARTN->Mjesto ) ), REPL ( "-", Len ( PARTN->Adresa ) )

   nBrPartn := 0
   SELECT SUBAN
   SET ORDER TO TAG "2"

   select_o_partner()
   IF !Empty ( aUsl )
      SET FILTER to &aUsl
   ENDIF
   GO TOP
   WHILE ! Eof()
      fNema := .T.
      SELECT SUBAN
      SEEK cIdFirma + PARTN->Id
      WHILE ! Eof() .AND. SUBAN->( IdFirma + IdPartner ) == ( cIdFirma + PARTN->Id )
         IF ( Empty ( cIdKonto ) .OR. SUBAN->IdKonto == cIdKonto ) .AND. ;
               dDatOd <= DatDok .AND. DatDok <= dDatDo
            fNema := .F.
            EXIT
         ENDIF
         SKIP
      END
      IF fNema
         ? Space ( 5 ) + PARTN->Id, PadR( PARTN->Naz, 25 ), PARTN->Mjesto, PARTN->Adresa
         nBrPartn ++
      ENDIF
      SELECT PARTN // while
      SKIP
   END
   ? Space ( 5 ) + REPL( "-", FIELD_LEN_PARTNER_ID ), REPL ( "-", 25 ), ;
      REPL ( "-", Len ( PARTN->Mjesto ) ), REPL ( "-", Len ( PARTN->Adresa ) )
   ?
   ? Space ( 5 ) + "Ukupno izlistano", AllTrim ( Str ( nBrPartn ) ), ;
      "partnera bez prometa"
   EJECT
   end_print()
   CLOSERET

   RETURN .T.
