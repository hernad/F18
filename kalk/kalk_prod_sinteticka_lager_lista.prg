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


FUNCTION sint_lager_lista_prodavnice()

   PicCDEM := kalk_prosiri_pic_cjena_za_2()
   PicDEM := kalk_prosiri_pic_iznos_za_2()

   cIdFirma := self_organizacija_id()
   qqKonto := PadR( "132;", 60 )
   // o_sifk()
// o_sifv()
// o_roba()
   // o_konto()
   // o_partner()

   dDatOd := CToD( "" )
   dDatDo := Date()
   qqRoba := Space( 60 )
   qqTarifa := Space( 60 )
   qqidvd := Space( 60 )
   PRIVATE cERR := "D"
   PRIVATE cPNab := "N"
   PRIVATE cNula := "D"
   PRIVATE cTU := "N"
   PRIVATE cPredhStanje := "N"

   Box(, 12, 66 )
   cGrupacija := Space( 4 )
   DO WHILE .T.

     @ box_x_koord() + 1, box_y_koord() + 2 SAY "Firma "
     ?? self_organizacija_id(), "-", self_organizacija_naziv()

      @ box_x_koord() + 2, box_y_koord() + 2 SAY "Prodavnice" GET qqKonto  PICT "@!S50"
      @ box_x_koord() + 3, box_y_koord() + 2 SAY "Artikli   " GET qqRoba PICT "@!S50"
      @ box_x_koord() + 4, box_y_koord() + 2 SAY "Tarife    " GET qqTarifa PICT "@!S50"
      @ box_x_koord() + 5, box_y_koord() + 2 SAY "Vrste dokumenata  " GET qqIDVD PICT "@!S30"
      @ box_x_koord() + 6, box_y_koord() + 2 SAY "Prikaz Nab.vrijednosti D/N" GET cPNab  VALID cpnab $ "DN" PICT "@!"
      @ box_x_koord() + 7, box_y_koord() + 2 SAY "Prikaz stavki kojima je MPV 0 D/N" GET cNula  VALID cNula $ "DN" PICT "@!"
      @ box_x_koord() + 8, box_y_koord() + 2 SAY "Prikaz ERR D/N" GET cERR  VALID cERR $ "DN" PICT "@!"
      @ box_x_koord() + 9, box_y_koord() + 2 SAY "Datum od " GET dDatOd
      @ box_x_koord() + 9, Col() + 2 SAY "do" GET dDatDo
      @ box_x_koord() + 10, box_y_koord() + 2 SAY "Prikaz robe tipa T/U  (D/N)" GET cTU VALID cTU $ "DN" PICT "@!"
      @ box_x_koord() + 12, box_y_koord() + 2 SAY "Odabir grupacije (prazno-svi) GET" GET cGrupacija PICT "@!"
      READ
      ESC_BCR

      PRIVATE aUsl1 := Parsiraj( qqRoba, "IdRoba" )
      PRIVATE aUsl2 := Parsiraj( qqTarifa, "IdTarifa" )
      PRIVATE aUsl3 := Parsiraj( qqIDVD, "idvd" )
      PRIVATE aUsl4 := Parsiraj( qqkonto, "pkonto" )
      IF aUsl1 <> NIL
         EXIT
      ENDIF
      IF aUsl2 <> NIL
         EXIT
      ENDIF
      IF aUsl3 <> NIL
         EXIT
      ENDIF
   ENDDO
   BoxC()

   o_koncij()
   o_kalk()

   PRIVATE cFilt1 := ""
   cFilt1 := "!EMPTY(pu_i).and." + aUsl1 + ".and." + aUsl4
   cFilt1 := StrTran( cFilt1, ".t..and.", "" )
   IF !( cFilt1 == ".t." )
      SET FILTER TO &cFilt1
   ENDIF

   SELECT kalk
   SET ORDER TO TAG "6"
   // CREATE_INDEX("6","idFirma+IdTarifa+idroba",KUMPATH+"KALK")
   HSEEK cidfirma
   EOF CRET

   nLen := 1

   aRptText := {}
   AAdd( aRptText, { 5, "R.", "br." } )
   AAdd( aRptText, { 10, " Artikal", " 1 " } )
   AAdd( aRptText, { 20, " Naziv", " 2 " } )
   AAdd( aRptText, { 3, "jmj", " 3 " } )
   IF cPredhStanje == "D"
      AAdd( aRptText, { 10, " Predh.st", " kol/MPV " } )
   ENDIF
   AAdd( aRptText, { Len( kalk_pic_kolicina_bilo_gpickol() ), " ulaz", " 4 " } )
   AAdd( aRptText, { Len( kalk_pic_kolicina_bilo_gpickol() ), " izlaz", " 5 " } )
   AAdd( aRptText, { Len( kalk_pic_kolicina_bilo_gpickol() ), " STANJE", " 4-5 " } )
   AAdd( aRptText, { Len( PicDem ), " MPV.Dug", " 6 " } )
   AAdd( aRptText, { Len( PicDem ), " MPV.Pot", " 7 " } )
   AAdd( aRptText, { Len( PicDem ), " MPV", " 6-7 " } )
   AAdd( aRptText, { Len( PicDem ), " MPCSAPP", " 8 " } )

   PRIVATE cLine := SetRptLineAndText( aRptText, 0 )
   PRIVATE cText1 := SetRptLineAndText( aRptText, 1, "*" )
   PRIVATE cText2 := SetRptLineAndText( aRptText, 2, "*" )

   start PRINT cret
   ?

   SELECT kalk

   PRIVATE nTStrana := 0
   PRIVATE bZagl := {|| Zaglsint_lager_lista_prodavnice( .T. ) }

   nTUlaz := nTIzlaz := 0
   nTMPVU := nTMPVI := nTNVU := nTNVI := 0
   nTRabat := 0
   nCol1 := nCol0 := 50
   nRbr := 0

   PRIVATE lSMark := .F.
   IF Right( Trim( qqRoba ), 1 ) = "*"
      lSMark := .T.
   ENDIF

   Eval( bZagl )

   DO WHILE !Eof() .AND. cidfirma == idfirma .AND.  ispitaj_prekid()
      cIdRoba := Idroba
      select_o_roba( cIdRoba )
      SELECT kalk
      nUlaz := nIzlaz := 0
      nMPVU := nMPVI := nNVU := nNVI := 0
      nRabat := 0

      IF Len( aUsl2 ) <> 0
         IF !Tacno( aUsl2 )
            SKIP
            LOOP
         ENDIF
      ENDIF

      IF cTU == "N" .AND. roba->tip $ "TU"
         SKIP
         LOOP
      ENDIF

      IF !Empty( cGrupacija )
         IF cGrupacija <> roba->k1
            SKIP
            LOOP
         ENDIF
      ENDIF

      DO WHILE !Eof() .AND. cIdFirma + cIdRoba == idFirma + idroba .AND. ispitaj_prekid()
         IF !Empty( cGrupacija )
            IF cGrupacija <> roba->k1
               SKIP
               LOOP
            ENDIF
         ENDIF

         IF datdok < dDatOd .OR. datdok > dDatDo
            SKIP
            LOOP
         ENDIF

         IF cTU == "N" .AND. roba->tip $ "TU"
            SKIP
            LOOP
         ENDIF

         IF Len( aUsl3 ) <> 0
            IF !Tacno( aUsl3 )
               SKIP
               LOOP
            ENDIF
         ENDIF

         IF pu_i == "1"
            kalk_sumiraj_kolicinu( field->kolicina, 0, @nUlaz, 0 )
            nCol1 := PCol() + 1
            nMPVU += mpcsapp * kolicina
            nNVU += nc * ( kolicina )
         ELSEIF pu_i == "5"
            IF idvd $ "12#13"
               kalk_sumiraj_kolicinu( - field->kolicina, 0, @nUlaz, 0 )
               nMPVU -= mpcsapp * kolicina
               nNVU -= nc * kolicina
            ELSE
               kalk_sumiraj_kolicinu( 0, field->kolicina, 0, @nIzlaz )
               nMPVI += mpcsapp * kolicina
               nNVI += nc * kolicina
            ENDIF
         ELSEIF pu_i == "3"
            // nivelacija
            nMPVU += mpcsapp * kolicina
         ELSEIF pu_i == "I"
            kalk_sumiraj_kolicinu( 0, field->gkolicin2, 0, @nIzlaz )
            nMPVI += mpcsapp * gkolicin2
            nNVI += nc * gkolicin2
         ENDIF
         SKIP
      ENDDO

      NovaStrana( bZagl )
      select_o_roba( cidroba )
      SELECT kalk
      aNaz := Sjecistr( roba->naz, 20 )

      ? Str( ++nrbr, 4 ) + ".", cIdRoba
      nCr := PCol() + 1
      @ PRow(), PCol() + 1 SAY aNaz[ 1 ]
      @ PRow(), PCol() + 1 SAY roba->jmj
      nCol0 := PCol() + 1
      @ PRow(), PCol() + 1 SAY nUlaz PICT kalk_pic_kolicina_bilo_gpickol()
      @ PRow(), PCol() + 1 SAY nIzlaz PICT kalk_pic_kolicina_bilo_gpickol()
      @ PRow(), PCol() + 1 SAY nUlaz - nIzlaz PICT kalk_pic_kolicina_bilo_gpickol()

      nCol1 := PCol() + 1
      @ PRow(), PCol() + 1 SAY nMPVU PICT picdem
      @ PRow(), PCol() + 1 SAY nMPVI PICT picdem
      @ PRow(), PCol() + 1 SAY nMPVU - NMPVI PICT picdem

      select_o_roba( cIdRoba )
      _mpc := kalk_get_mpc_by_koncij_pravilo()
      SELECT kalk

      IF Round( nUlaz - nIzlaz, 4 ) <> 0
         @ PRow(), PCol() + 1 SAY ( nMPVU - nMPVI ) / ( nUlaz - nIzlaz ) PICT piccdem
         IF Round( ( nMPVU - nMPVI ) / ( nUlaz - nIzlaz ), 4 ) <> Round( _mpc, 4 )
            IF ( cERR == "D" )
               ?? " ERR"
            ENDIF
         ENDIF
      ELSE
         @ PRow(), PCol() + 1 SAY 0 PICT picdem
         IF Round( ( nMPVU - nMPVI ), 4 ) <> 0
            ?? " ERR"
         ENDIF
      ENDIF

      @ PRow() + 1, 0 SAY ""
      IF Len( aNaz ) == 2
         @ PRow(), nCR  SAY aNaz[ 2 ]
      ENDIF
      IF cPnab == "D"
         @ PRow(), nCol0 SAY Space( Len( kalk_pic_kolicina_bilo_gpickol() ) )
         @ PRow(), PCol() + 1 SAY Space( Len( kalk_pic_kolicina_bilo_gpickol() ) )
         IF Round( nulaz - nizlaz, 4 ) <> 0
            @ PRow(), PCol() + 1 SAY ( nNVU - nNVI ) / ( nUlaz - nIzlaz ) PICT picdem
         ENDIF
         @ PRow(), nCol1 SAY nNVU PICT picdem
         @ PRow(), PCol() + 1 SAY nNVI PICT picdem
         @ PRow(), PCol() + 1 SAY nNVU - nNVI PICT picdem
         @ PRow(), PCol() + 1 SAY _MPC PICT piccdem
      ENDIF
      nTULaz += nUlaz
      nTIzlaz += nIzlaz
      nTMPVU += nMPVU
      nTMPVI += nMPVI
      nTNVU += nNVU
      nTNVI += nNVI
      nTRabat += nRabat
   ENDDO

   NovaStrana( bZagl, 3 )

   ? cLine
   ? "UKUPNO:"
   @ PRow(), nCol0 SAY ntUlaz PICT kalk_pic_kolicina_bilo_gpickol()
   @ PRow(), PCol() + 1 SAY ntIzlaz PICT kalk_pic_kolicina_bilo_gpickol()
   @ PRow(), PCol() + 1 SAY ntUlaz - ntIzlaz PICT kalk_pic_kolicina_bilo_gpickol()
   nCol1 := PCol() + 1
   @ PRow(), PCol() + 1 SAY ntMPVU PICT picdem
   @ PRow(), PCol() + 1 SAY ntMPVI PICT picdem
   @ PRow(), PCol() + 1 SAY ntMPVU - NtMPVI PICT picdem

   IF cpnab == "D"
      @ PRow() + 1, nCol1 SAY ntNVU PICT picdem
      @ PRow(), PCol() + 1 SAY ntNVI PICT picdem
      @ PRow(), PCol() + 1 SAY ntNVU - ntNVI PICT picdem
   ENDIF

   ? cLine

   FF
   ENDPRINT

   my_close_all_dbf()

   RETURN


// zaglavlje sint.lager lista
FUNCTION Zaglsint_lager_lista_prodavnice( lSint )

   IF lSint == NIL
      lSint := .F.
   ENDIF

   Preduzece()

   P_COND

   ?? "KALK: SINTETICKA LAGER LISTA PRODAVNICA ZA PERIOD", dDatOd, "-", dDatDo, " NA DAN "
   ?? Date(), Space( 12 ), "Str:", Str( ++nTStrana, 3 )

   IF !lSint .AND. !Empty( qqIdPartn )
      ? "Obuhvaceni sljedeci partneri:", Trim( qqIdPartn )
   ENDIF

   IF lSint
      ? "Kriterij za prodavnice:", qqKonto
   ELSE
      select_o_konto( cIdKonto )
      ? "Prodavnica:", cIdKonto, "-", konto->naz
   ENDIF

   ? cLine
   ? cText1
   ? cText2
   ? cLine

   RETURN .T.
