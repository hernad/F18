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


FUNCTION TopsFakt()

   LOCAL cLokacija := PadR( "A:" + SLASH, 40 )
   LOCAL cTopsFakt
   LOCAL nRBr
   LOCAL cIdRj := self_organizacija_id()
   LOCAL cCijeneIzSif := "D"
   LOCAL cRabatDN := "N"
   LOCAL nRacuna := 0
   LOCAL nIznosR := 0

   Box( "#PREUZIMANJE TOPS->FAKT", 6, 70 )
   @ box_x_koord() + 2, box_y_koord() + 2 SAY "Lokacija datoteke TOPSFAKT je:" GET cLokacija
   @ box_x_koord() + 4, box_y_koord() + 2 SAY "Uzeti cijene iz sifrarnika ? (D/N)" GET cCijeneIzSif VALID cCijeneIzSif $ "DN" PICT "@!"
   @ box_x_koord() + 5, box_y_koord() + 2 SAY "Ostaviti rabat (ako ga je bilo)? (D/N)" GET cRabatDN VALID cRabatDN $ "DN" PICT "@!"
   READ
   IF LastKey() == K_ESC
      BoxC()
      RETURN
   ENDIF
   cTopsFakt := Trim( cLokacija ) + "TOPSFAKT.DBF"
   IF !File( cTopsFakt )
      MsgBeep( "Na zadanoj lokaciji ne postoji datoteka TOPSFAKT.DBF" )
      BoxC()
      RETURN
   ENDIF
   BoxC()

   //o_roba()
   //o_partner()
   //o_fakt_doks_dbf()
   o_fakt_pripr()

   USE ( Trim( cLokacija ) + "TOPSFAKT.DBF" ) new
   SET ORDER TO TAG "1"
   GO TOP

   cBrFakt := Space( 8 )
   cIdVdLast := "  "

   DO WHILE !Eof()
      cIdVd := idVd
      cIdPartner := idPartner
      nRBr := 1
      IF Empty( cBrFakt ) .OR. cIdVdLast <> cIdVd
         cBrFakt := fakt_naredni_broj_dokumenta( cIdRj, cIdVd, datum, cIdPartner )
      ELSE
         cBrFakt := UBrojDok( Val( Left( cBrFakt, gNumDio ) ) + 1, gNumDio, Right( cBrFakt, Len( cBrFakt ) -gNumDio ) )
      ENDIF
      cIdVdLast := cIdVd
      DO WHILE !Eof() .AND. idVd == cIdVd .AND. idPartner == cIdPartner

         IF cCijeneIzSif == "D"
            select_o_roba( topsfakt->idRoba )
         ENDIF

         SELECT fakt_pripr
         APPEND BLANK

         IF nRBr == 1
            IF cIdVd == "10"
               ++nRacuna
            ENDIF
            select_o_partner( cIdPartner )
            _Txt3a := PadR( cIdPartner + ".", 30 )
            _txt3b := _txt3c := ""
            //IzSifre( .T. )
            cTxta := _txt3a
            cTxtb := _txt3b
            cTxtc := _txt3c
            ctxt := Chr( 16 ) + " " + Chr( 17 ) + Chr( 16 ) + " " + Chr( 17 ) + Chr( 16 ) + cTxta + Chr( 17 ) + Chr( 16 ) + cTxtb + Chr( 17 ) + Chr( 16 ) + cTxtc + Chr( 17 )
            SELECT fakt_pripr
            REPLACE txt WITH ctxt
         ENDIF

         REPLACE idfirma   WITH cIdRj
         REPLACE rbr       WITH Str( nRBr, 3 )
         REPLACE idtipdok  WITH cIdVd
         REPLACE brdok     WITH cBrFakt
         REPLACE datdok    WITH topsfakt->datum
         REPLACE idpartner WITH cIdPartner
         REPLACE kolicina  WITH topsfakt->kolicina
         REPLACE idroba    WITH topsfakt->idRoba
         IF cCijeneIzSif == "D"
            REPLACE cijena    WITH roba->vpc
         ELSE
            REPLACE cijena    WITH topsfakt->mpc
         ENDIF
         IF cRabatDN == "D"
            REPLACE rabat     WITH topsfakt->stMpc
         ENDIF
         REPLACE dindem    WITH "KM"

         IF cIdVd == "10"
            nIznosR += pripr->( kolicina * ( cijena - rabat ) )
         ENDIF

         SELECT topsfakt

         ++nRBr
         SKIP 1
      ENDDO
   ENDDO


   MsgBeep( "Dokumenti su preneseni u pripremu!#" + "Broj formiranih racuna: " + AllTrim( Str( nRacuna ) ) + "#Ukupan iznos racuna:" + AllTrim( Str( nIznosR, 15, 2 ) ) )

   CLOSERET

   RETURN .T.


STATIC FUNCTION fakt_naredni_broj_dokumenta( cIdRj, cIdVd, dDo, cIdPartner )

   LOCAL nArr := Select()
   LOCAL cBrFakt

   _datdok := dDo
   _idpartner := cIdPartner
   cBrFakt := fakt_novi_broj_dokumenta( cIdRJ, cIdVd )
   SELECT ( nArr )

   RETURN cBrFakt
