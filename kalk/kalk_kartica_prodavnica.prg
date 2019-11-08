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


STATIC s_cLine
STATIC s_cTxt1
// STATIC __txt2
// STATIC __txt3


FUNCTION kalk_kartica_prodavnica()

   PARAMETERS cIdFirma, cIdRoba, cIdKonto

   LOCAL cLine
   LOCAL cTxt1
   LOCAL cTxt2
   LOCAL cTxt3
   LOCAL lRokTrajanja, hAttriId, _item_istek_roka
   LOCAL nNc, nSredNc, nOdstupanje, cTransakcija
   LOCAL cPrikSredNc := "N"
   LOCAL cIdvd := Space( 100 )
   LOCAL hParams := hb_Hash(), cExportDN := "N", lExport := .F.
   LOCAL GetList := {}
   LOCAL cIdRobaTackaZarez := cIdRoba
   LOCAL lRobaTackaZarez := .F.
   LOCAL cOrderBy

   LOCAL nUlaz, nIzlaz
   LOCAL nMPV, nNV
   //LOCAL nMPVP

   PRIVATE PicCDEM := kalk_prosiri_pic_cjena_za_2()
   PRIVATE PicProc := gPicProc
   PRIVATE PicDEM := kalk_prosiri_pic_iznos_za_2()
   PRIVATE PicKol := kalk_prosiri_pic_kolicina_za_2()
   PRIVATE nMarza, nMarza2, nPRUC, aPorezi

   //lRokTrajanja := fetch_metric( "kalk_definisanje_roka_trajanja", NIL, "N" ) == "D"

   // o_tarifa()
// o_sifk()
// o_sifv()
   // o_roba()
   // o_konto()
   // o_partner()

   cPredh := "N"
   dDatOd := Date()
   dDatDo := Date()
   aPorezi := {}
   nMarza := nMarza2 := nPRUC := 0

   IF cIdKonto == NIL

      cIdFirma := self_organizacija_id()
      cIdRoba := Space( 10 )
      cIdKonto := PadR( "1330", 7 )
      cPredh := "N"
      cIdRoba := fetch_metric( "kalk_kartica_prod_id_roba", my_user(), cIdRoba )
      cIdKonto := fetch_metric( "kalk_kartica_prod_id_konto", my_user(), cIdKonto )
      dDatOd := fetch_metric( "kalk_kartica_prod_datum_od", my_user(), dDatOd )
      dDatDo := fetch_metric( "kalk_kartica_prod_datum_do", my_user(), dDatDo )
      cPredh := fetch_metric( "kalk_kartica_prod_prethodni_promet", my_user(), cPredh )

      Box(, 11, 60 )

      DO WHILE .T.

         @ box_x_koord() + 1, box_y_koord() + 2 SAY "Firma "
         ?? self_organizacija_id(), "-", self_organizacija_naziv()

         @ box_x_koord() + 2, box_y_koord() + 2 SAY "Konto " GET cIdKonto VALID P_Konto( @cIdKonto )

         form_get_roba_id( @cIdRoba, box_x_koord() + 3, box_y_koord() + 2, @GetList )

         @ box_x_koord() + 5, box_y_koord() + 2 SAY "Datum od " GET dDatOd
         @ box_x_koord() + 5, Col() + 2 SAY "do" GET dDatDo
         @ box_x_koord() + 6, box_y_koord() + 2 SAY "sa prethodnim prometom (D/N)" GET cPredh PICT "@!" VALID cpredh $ "DN"
         @ box_x_koord() + 7, box_y_koord() + 2 SAY "Tip dokumenta (;) :"  GET cIdVd PICT "@S20"

         @ box_x_koord() + 9, box_y_koord() + 2 SAY "Prikaz srednje nabavne cijene ?" GET cPrikSredNc VALID cPrikSredNc $ "DN" PICT "@!"

         @ box_x_koord() + 11, box_y_koord() + 2 SAY "Export XLSX:"  GET cExportDn PICT "@!" VALID cExportDN $ "DN"

         READ
         ESC_BCR

         EXIT

      ENDDO

      BoxC()

      IF LastKey() != K_ESC
         set_metric( "kalk_kartica_prod_id_roba", my_user(), cIdRoba )
         set_metric( "kalk_kartica_prod_id_konto", my_user(), cIdKonto )
         set_metric( "kalk_kartica_prod_datum_od", my_user(), dDatOd )
         set_metric( "kalk_kartica_prod_datum_do", my_user(), dDatDo )
         set_metric( "kalk_kartica_prod_prethodni_promet", my_user(), cPredh )
      ENDIF

      IF cExportDN == "D"
         lExport := .T.
         create_dbf_r_export( kalk_kartica_prodavnica_export_dbf_struct() )
      ENDIF

      IF Empty( cIdRoba )
         IF Pitanje(, "Niste zadali šifru artikla, izlistati sve kartice (D/N) ?", "N" ) == "N"
            my_close_all_dbf()
            RETURN .F.
         ELSE
            cIdRobaTackaZarez := ""
            lRobaTackaZarez := .T.
         ENDIF

      ELSE
         cIdRobaTackaZarez := cIdRoba
         lRobaTackaZarez := .F.
      ENDIF

      IF Right( Trim( cIdroba ), 1 ) == ";"
         lRobaTackaZarez := .T.
         cIdRobaTackaZarez := Trim( StrTran( cIdroba, ";", "" ) )
      ENDIF


   ENDIF

   nKolicina := 0

   // IF server_db_version() >= 25
   // cOrderBy := "idfirma,pkonto,idroba,datdok,obradjeno,pu_i,idvd"
   // ELSE
   cOrderBy := "idfirma,pkonto,idroba,datdok,pu_i,idvd"
   // ENDIF

   MsgO( "Preuzimanje podataka sa SQL servera ..." )

   IF Empty( cIdRoba )
      find_kalk_by_pkonto_idroba_idvd( cIdFirma, cIdVd, cIdKonto, NIL, cOrderBy )
   ELSE
      find_kalk_by_pkonto_idroba_idvd( cIdFirma, cIdVd, cIdKonto, cIdRoba, cOrderBy )
   ENDIF

   MsgC()

   PRIVATE cFilt := ".t."

   IF !( cFilt == ".t." )
      SET FILTER TO &cFilt
   ENDIF

   GO TOP
   EOF CRET

   gaZagFix := { 7, 3 }

   START PRINT CRET

   ?
   nLen := 1

   _set_zagl( @cLine, @cTxt1 )
   s_cLine := cLine
   s_cTxt1 := cTxt1

   nTStrana := 0

   Zagl()

   nCol1 := 10
   nUlaz := nIzlaz := 0
   nMPV := nNV := 0
   //nMPVP := 0
   fPrviProl := .T.

   DO WHILE !Eof() .AND. iif( lRobaTackaZarez, field->idfirma + field->pkonto + field->idroba >= cIdFirma + cIdKonto + cIdRobaTackaZarez, field->idfirma + field->pkonto + field->idroba == cIdFirma + cIdKonto + cIdRobaTackaZarez )

      cIdRoba := field->idroba

      select_o_roba( cIdRoba )
      select_o_tarifa( roba->idtarifa )

      ? s_cLine

      ? "Artikal:", cIdRoba, "-", Trim( Left( roba->naz, 40 ) ) + ;
         iif( roba_barkod_pri_unosu(), " BK: " + roba->barkod, "" ) + " (" + AllTrim( roba->jmj ) + ")"

      ? s_cLine

      SELECT kalk

      nCol1 := 10
      nUlaz := nIzlaz := 0
      nNV := nMPV := 0
      fPrviProl := .T.
      nRabat := 0
      nColDok := 9
      nColFCJ2 := 68

      DO WHILE !Eof() .AND. cIdfirma + cIdkonto + cIdroba == field->idFirma + field->pkonto + field->idroba

         IF field->datdok < dDatOd .AND. cPredh == "N"
            SKIP
            LOOP
         ENDIF

         IF field->datdok > dDatDo
            SKIP
            LOOP
         ENDIF

         IF cPredh == "D" .AND. field->datdok >= dDatod .AND. fPrviProl

            fPrviprol := .F.

            ? "Stanje do ", dDatOd

            @ PRow(), 35 SAY say_kolicina( nUlaz )
            @ PRow(), PCol() + 1 SAY say_kolicina( nIzlaz       )
            @ PRow(), PCol() + 1 SAY say_kolicina( nUlaz - nIzlaz )

            IF Round( nUlaz - nIzlaz, 4 ) <> 0
               @ PRow(), PCol() + 1 SAY say_cijena( nNV / ( nUlaz - nIzlaz ) )
               @ PRow(), PCol() + 1 SAY say_kolicina( 0            )
               @ PRow(), PCol() + 1 SAY say_cijena( nMPV / ( nUlaz - nIzlaz ) )
            ELSEIF Round( nMpv, 3 ) <> 0
               @ PRow(), PCol() + 1 SAY say_kolicina( 0  )
               @ PRow(), PCol() + 1 SAY say_kolicina( 0  )
               @ PRow(), PCol() + 1 SAY PadC( "ERR", Len( piccdem ) )
            ELSE
               @ PRow(), PCol() + 1 SAY say_kolicina( 0            )
            ENDIF
         ENDIF

         IF ( PRow() - dodatni_redovi_po_stranici() ) > 62
            FF
            Zagl()
         ENDIF

         IF field->pu_i == "1"

            nUlaz += field->kolicina - field->GKolicina - field->GKolicin2

            IF field->datdok >= dDatod

               ? field->datdok, field->idvd + "-" + field->brdok, field->idtarifa, field->idpartner

               nCol1 := PCol() + 1

               @ PRow(), PCol() + 1 SAY say_kolicina( field->kolicina )
               @ PRow(), PCol() + 1 SAY say_kolicina( 0 )
               @ PRow(), PCol() + 1 SAY say_kolicina( nUlaz - nIzlaz )
               nNc := field->nc
               cTransakcija := "   U"
               IF field->kolicina < 0
                  cTransakcija := "-U=I"
               ENDIF
               @ PRow(), PCol() + 1 SAY say_cijena( nNc )
               @ PRow(), PCol() + 1 SAY say_cijena( field->vpc )
               @ PRow(), PCol() + 1 SAY say_cijena( field->mpcsapp )

            ENDIF

            //nMPVP += field->mpcsapp * field->kolicina
            nMPV += field->mpcsapp * field->kolicina
            nNV += field->nc * field->kolicina

            IF field->datdok >= dDatOd
               @ PRow(), PCol() + 1 SAY kalk_say_iznos( nMpv )
            ENDIF

/*
        --    IF lRokTrajanja
               hAttriId := hb_Hash()
               hAttriId[ "idfirma" ] := field->idfirma
               hAttriId[ "idtipdok" ] := field->idvd
               hAttriId[ "brdok" ] := field->brdok
               hAttriId[ "rbr" ] := field->rbr
               _item_istek_roka := CToD( get_kalk_attr_rok( hAttriId, .T. ) )
               IF DToC( _item_istek_roka ) <> DToC( CToD( "" ) )
                  @ PRow(), PCol() + 1 SAY  "rok: " + DToC( _item_istek_roka )
               ENDIF
            ENDIF
*/

         ELSEIF field->pu_i == "5" .AND. !( field->idvd $ "12#13#22" )

            aPorezi := {}

            nIzlaz += field->kolicina

            set_pdv_array_by_koncij_region_roba_idtarifa_2_3( field->pkonto, field->idroba, @aPorezi, field->idtarifa )
            aIPor := kalk_porezi_maloprodaja_legacy_array( aPorezi, field->mpc, field->mpcsapp, field->nc )
            nPor1 := aIPor[ 1 ]
            set_pdv_public_vars()

            IF field->datdok >= dDatod

               ? field->datdok, field->idvd + "-" + field->brdok, field->idtarifa, field->idpartner

               nCol1 := PCol() + 1
               @ PRow(), PCol() + 1 SAY say_kolicina( 0 )
               @ PRow(), PCol() + 1 SAY say_kolicina( field->kolicina )
               @ PRow(), PCol() + 1 SAY say_kolicina( nUlaz - nIzlaz )
               nNc := field->nc
               cTransakcija := "   I"
               IF field->kolicina < 0
                  cTransakcija := "-I=U"
               ENDIF
               @ PRow(), PCol() + 1 SAY say_cijena( nNc )
               @ PRow(), PCol() + 1 SAY say_cijena( field->mpc )
               @ PRow(), PCol() + 1 SAY say_cijena( field->mpcsapp )

            ENDIF

            //nMPVP -= ( field->mpc + nPor1 ) * field->kolicina
            nMPV -= field->mpcsapp * field->kolicina
            nNV -= field->nc * field->kolicina

            IF field->datdok >= dDatOd
               @ PRow(), PCol() + 1 SAY kalk_say_iznos( nMpv )
            ENDIF

         ELSEIF field->pu_i == "I"
            nIzlaz += field->gkolicin2

            IF field->datdok >= dDatod
               ? field->datdok, field->idvd + "-" + field->brdok, field->idtarifa, field->idpartner
               nCol1 := PCol() + 1
               @ PRow(), PCol() + 1 SAY say_kolicina( 0 )
               @ PRow(), PCol() + 1 SAY say_kolicina( field->gkolicin2 )
               @ PRow(), PCol() + 1 SAY say_kolicina( nUlaz - nIzlaz )
               nNc := field->nc
               cTransakcija := " INV"
               @ PRow(), PCol() + 1 SAY say_cijena( nNc )
               @ PRow(), PCol() + 1 SAY say_cijena( 0 )
               @ PRow(), PCol() + 1 SAY say_cijena( field->mpcsapp )
            ENDIF

            //nMPVP -= field->mpcsapp * field->gkolicin2
            nMPV -= field->mpcsapp * field->gkolicin2
            nNV -= field->nc * field->gkolicin2

            IF field->datdok >= dDatod
               @ PRow(), PCol() + 1 SAY kalk_say_iznos( nMpv )
            ENDIF

         ELSEIF field->pu_i == "5" .AND. ( field->idvd $ "12#13#22" )

            nUlaz -= field->kolicina

            IF field->datdok >= dDatod
               ? field->datdok, field->idvd + "-" + field->brdok, field->idtarifa, field->idpartner
               nCol1 := PCol() + 1
               @ PRow(), PCol() + 1 SAY say_kolicina( - ( field->kolicina ) )
               @ PRow(), PCol() + 1 SAY say_kolicina( 0 )
               @ PRow(), PCol() + 1 SAY say_kolicina( nUlaz - nIzlaz )
               nNc := field->nc
               cTransakcija := "   I"
               IF field->kolicina < 0
                  cTransakcija := "-I=U"
               ENDIF
               @ PRow(), PCol() + 1 SAY say_cijena( nNc )
               @ PRow(), PCol() + 1 SAY say_cijena( field->vpc )
               @ PRow(), PCol() + 1 SAY say_cijena( field->mpcsapp )
            ENDIF

            //nMPVP -= field->mpcsapp * field->kolicina
            nMPV -= field->mpcsapp * field->kolicina
            nNV -= field->nc * field->kolicina

            IF field->datdok >= dDatod
               @ PRow(), PCol() + 1 SAY kalk_say_iznos( nMpv )
            ENDIF

         ELSEIF field->pu_i == "3"

            // nivelacija

            IF field->datdok >= dDatod
               ? field->datdok, field->idvd + "-" + field->brdok, field->idtarifa, field->idpartner
               nCol1 := PCol() + 1
               @ PRow(), PCol() + 1 SAY say_kolicina( field->kolicina )
               @ PRow(), PCol() + 1 SAY say_kolicina( 0 )
               @ PRow(), PCol() + 1 SAY say_kolicina( nUlaz - nIzlaz )
               @ PRow(), PCol() + 1 SAY say_cijena( field->fcj )
               @ PRow(), PCol() + 1 SAY say_cijena( field->mpcsapp )
               @ PRow(), PCol() + 1 SAY say_cijena( field->fcj + field->mpcsapp )
            ENDIF

            //nMPVP += field->mpcsapp * field->kolicina
            nMPV += field->mpcsapp * field->kolicina

            IF field->datdok >= dDatod
               @ PRow(), PCol() + 1 SAY kalk_say_iznos( nMpv )
            ENDIF

         ENDIF

         IF cPrikSredNc == "D"

            IF Round( nUlaz - nIzlaz, 4 ) == 0
               nSredNc := 0
               nOdstupanje := 0
            ELSE
               nSredNc := nNv / ( nUlaz - nIzlaz )
               IF Round( nSredNC, 4 ) == 0
                  nOdstupanje := 0
               ELSE
                  nOdstupanje := Round( ( nSredNc - nNc ) / nSredNc * 100, 0 )
               ENDIF
            ENDIF

            ? Space( 71 ), cTransakcija, " SNc:", say_kolicina( nSredNc ), ""

            IF Abs( nOdstupanje ) > 60
               ?? ">>>> ODST SNc-Nc: "
            ELSE
               ?? "     odst snc-nc: "
            ENDIF
            ?? AllTrim(  say_kolicina( Abs( nOdstupanje ) ) ) + "%"
            ?
         ENDIF

         IF lExport
            hParams[ "idkonto" ] := cIdKonto
            hParams[ "idroba" ] := cIdRoba
            hParams[ "kolicina" ] := field->kolicina
            hParams[ "brdok" ] := field->brdok
            hParams[ "idvd" ] := field->idvd
            hParams[ "datdok" ] := field->datdok
            hParams[ "brfaktp" ] := field->brfaktp
            hParams[ "nc" ] := nNc
            hParams[ "nv" ] := nNV
            hParams[ "rabatv" ] := field->rabatv
            hParams[ "vpc" ] := field->vpc
            hParams[ "mpc" ] := field->mpcsapp
            hParams[ "stanje" ] := nUlaz - nIzlaz

            kalk_kartica_prodavnica_add_item_to_r_export( hParams )
         ENDIF

         SKIP

      ENDDO

      ? s_cLine
      ? "Ukupno:"

      @ PRow(), nCol1 SAY say_kolicina( nUlaz )
      @ PRow(), PCol() + 1 SAY say_kolicina( nIzlaz )
      @ PRow(), PCol() + 1 SAY say_kolicina( nUlaz - nIzlaz )
      IF Round( nUlaz - nIzlaz, 4 ) <> 0
         @ PRow(), PCol() + 1 SAY say_cijena( nNV / ( nUlaz - nIzlaz ) )
         @ PRow(), PCol() + 1 SAY say_kolicina( 0 )
         @ PRow(), PCol() + 1 SAY say_cijena( nMPV / ( nUlaz - nIzlaz ) )
      ELSEIF Round( nMpv, 3 ) <> 0
         @ PRow(), PCol() + 1 SAY say_kolicina( 0 )
         @ PRow(), PCol() + 1 SAY say_kolicina( 0 )
         @ PRow(), PCol() + 1 SAY PadC( "ERR", Len( piccdem ) )
      ELSE
         @ PRow(), PCol() + 1 SAY say_kolicina( 0 )
      ENDIF

      @ PRow(), PCol() + 1 SAY kalk_say_iznos( nMpv )

      ? s_cLine
      ?
      ? Replicate( "-", 60 )
      //? "     Ukupna vrijednost popusta u mp:", Str( Abs( nMPVP - nMPV ), 12, 2 )
      //? "Ukupna prodajna vrijednost - popust:", Str( nMPVP, 12, 2 )
      ? "  Ukupna maloprodajna vrijednost:", Str( nMPV, 12, 2 )
      ? Replicate( "-", 60 )
      ?

   ENDDO

   my_close_all_dbf()
   IF lExport
      open_r_export_table()
   ENDIF

   FF
   ENDPRINT

   RETURN .T.



STATIC FUNCTION _set_zagl( cLine, cTxt1 )

   LOCAL aKProd := {}
   LOCAL nPom

   nPom := 8
   AAdd( aKProd, { nPom, PadC( "Datum", nPom ) } )
   nPom := 11
   AAdd( aKProd, { nPom, PadC( "Dokument", nPom ) } )
   nPom := 6
   AAdd( aKProd, { nPom, PadC( "Tarifa", nPom ) } )
   nPom := 6
   AAdd( aKProd, { nPom, PadC( "Partn", nPom ) } )

   nPom := Len( kalk_prosiri_pic_kolicina_za_2() )
   AAdd( aKProd, { nPom, PadC( "Ulaz", nPom ) } )
   AAdd( aKProd, { nPom, PadC( "Izlaz", nPom ) } )
   AAdd( aKProd, { nPom, PadC( "Stanje", nPom ) } )

   nPom := Len( kalk_prosiri_pic_iznos_za_2() )
   AAdd( aKProd, { nPom, PadC( "NC", nPom ) } )
   AAdd( aKProd, { nPom, PadC( "PC", nPom ) } )
   AAdd( aKProd, { nPom, PadC( "PC sa PDV", nPom ) } )
   AAdd( aKProd, { nPom, PadC( "PV", nPom ) } )

   cLine := SetRptLineAndText( aKProd, 0 )
   cTxt1 := SetRptLineAndText( aKProd, 1, "*" )

   RETURN .T.



FUNCTION Test( cIdRoba )

   IF Len( Trim( cIdRoba ) ) <= 10
      cIdRoba := Left( cIdRoba, 10 )
   ELSE
      cIdRoba := cIdRoba
   ENDIF

   RETURN cIdRoba



STATIC FUNCTION Zagl()

   select_o_konto( cIdKonto )

   Preduzece()
   P_12CPI
   ?? "KARTICA PRODAVNICA za period", ddatod, "-", ddatdo, Space( 10 ), "Str:", Str( ++nTStrana, 3 )
   IspisNaDan( 10 )

   ? "Konto: ", cidkonto, "-", konto->naz
   SELECT kalk
   P_COND
   ? s_cLine
   ? s_cTxt1
   ? s_cLine

   RETURN .T.



FUNCTION naprometniji_artikli_prodavnica()

   LOCAL PicDEM := kalk_pic_iznos_bilo_gpicdem()
   LOCAL Pickol := "@Z " + kalk_pic_kolicina_bilo_gpickol()

   qqKonto := "133;"
   qqRoba  := ""
   cSta    := "O"
   dDat0   := Date()
   dDat1   := Date()
   nTop    := 20
   aNiz := {   { "Uslov za prodavnice (prazno-sve)", "qqKonto",              , "@!S30", } }
   AAdd ( aNiz, { "Uslov za robu/artikle (prazno-sve)", "qqRoba",              , "@!S30", } )
   AAdd ( aNiz, { "Pregled po Iznosu/Kolicini/Oboje (I/K/O)", "cSta", "cSta$'IKO'", "@!", } )
   AAdd ( aNiz, { "Izvjestaj se pravi od datuma", "dDat0",              ,         , } )
   AAdd ( aNiz, { "                   do datuma", "dDat1",              ,         , } )
   AAdd ( aNiz, { "Koliko artikala ispisati?", "nTop", "nTop > 0", "999", } )

   o_params()
   PRIVATE cSection := "F", cHistory := " ", aHistory := {}
   Params1()
   RPar( "c2", @qqKonto )
   RPar( "c5", @qqRoba )
   RPar( "d1", @dDat0 ); RPar( "d2", @dDat1 )

   qqKonto := PadR( qqKonto, 60 )
   qqRoba  := PadR( qqRoba, 60 )

   DO WHILE .T.
      IF !VarEdit( aNiz, 9, 1, 19, 78, ;
            'USLOVI ZA IZVJESTAJ "NAJPROMETNIJI ARTIKLI"', "B1" )
         CLOSERET
      ENDIF
      aUsl1 := Parsiraj( qqRoba, "IDROBA", "C" )
      aUsl2 := Parsiraj( qqKonto, "PKONTO", "C" )
      IF aUsl1 <> NIL .AND. aUsl2 <> NIL .AND. dDat0 <= dDat1
         EXIT
      ELSEIF aUsl2 == NIL
         Msg( "Kriterij za prodavnice nije korektno postavljen!" )
      ELSEIF aUsl1 == NIL
         Msg( "Kriterij za robu nije korektno postavljen!" )
      ELSE
         Msg( "'Datum do' ne smije biti stariji nego 'datum od'!" )
      ENDIF
   ENDDO

   WPar( "c2", qqKonto )
   WPar( "c5", qqRoba )
   WPar( "d1", dDat0 )
   WPar( "d2", dDat1 )

   SELECT params
   USE

   // o_roba()
   find_kalk_za_period( self_organizacija_id(), NIL, NIL, NIL, dDat0, dDat1, "idroba,idvd" )

   cFilt := aUsl1 + " .and. " + aUsl2 + ' .and. PU_I=="5"' + ' .and. !(IDVD $ "12#13#22")'


   SET FILTER TO &cFilt

   nMinI := 999999999999
   nMinK := 999999999999
   aTopI := {}
   aTopK := {}

   MsgO( "Priprema izvještaja..." )

   GO TOP
   DO WHILE !Eof()
      cIdRoba   := IDROBA
      nKolicina := 0
      nIznos    := 0
      DO WHILE !Eof() .AND. IDROBA == cIdRoba
         nKolicina += kolicina
         nIznos    += kolicina * mpcsapp
         SKIP 1
      ENDDO
      IF Len( aTopI ) < nTop
         AAdd( aTopI, { cIdRoba, nIznos } )
         nMinI := Min( nIznos, nMinI )
      ELSEIF nIznos > nMinI
         nPom := AScan( aTopI, {| x | x[ 2 ] <= nMinI } )
         IF nPom < 1 .OR. nPom > Len( aTopI )
            MsgBeep( "nPom=" + Str( nPom ) + " ?!" )
         ENDIF
         aTopI[ nPom ] := { cIdRoba, nIznos }
         nMinI := nIznos
         AEval( aTopI, {| x | nMinI := Min( nMinI, x[ 2 ] ) } )
      ENDIF
      IF Len( aTopK ) < nTop
         AAdd( aTopK, { cIdRoba, nKolicina } )
         nMinK := Min( nKolicina, nMinK )
      ELSEIF nKolicina > nMinK
         nPom := AScan( aTopK, {| x | x[ 2 ] <= nMinK } )
         IF nPom < 1 .OR. nPom > Len( aTopK )
            MsgBeep( "nPom=" + Str( nPom ) + " ?!" )
         ENDIF
         aTopK[ nPom ] := { cIdRoba, nKolicina }
         nMinK := nKolicina
         AEval( aTopK, {| x | nMinK := Min( nMinK, x[ 2 ] ) } )
      ENDIF
   ENDDO

   MsgC()

   ASort( aTopI,,, {| x, y | x[ 2 ] > y[ 2 ] } )
   ASort( aTopK,,, {| x, y | x[ 2 ] > y[ 2 ] } )



   START PRINT CRET
   ?
   Preduzece()
   ?? "Najprometniji artikli za period", ddat0, "-", ddat1
   ?U "Obuhvaćene prodavnice:", iif( Empty( qqKonto ), "SVE", "'" + Trim( qqKonto ) + "'" )
   ?U "Obuhvaćeni artikli   :", iif( Empty( qqRoba ), "SVI", "'" + Trim( qqRoba ) + "'" )
   ?

   IF cSta $ "IO"
      m := AllTrim( Str( Min( nTop, Len( aTopI ) ) ) ) + " NAJPROMETNIJIH ARTIKALA POSMATRANO PO IZNOSIMA:"
      ?
      ? REPL( "-", Len( m ) )
      ?
      ?U PadC( "ŠIFRA", Len( roba->id ) ) + " " + PadC( "NAZIV", 50 ) + " " + PadC( "IZNOS", 20 )
      ? REPL( "-", Len( roba->id ) ) + " " + REPL( "-", 50 ) + " " + REPL( "-", 20 )
      FOR i := 1 TO Len( aTopI )
         cIdRoba := aTopI[ i, 1 ]
         select_o_roba( cIdRoba )
         ? cIdRoba, Left( ROBA->naz, 50 ), PadC( Transform( aTopI[ i, 2 ], picdem ), 20 )
      NEXT
      ? REPL( "-", Len( id ) ) + " " + REPL( "-", 50 ) + " " + REPL( "-", 20 )

   ENDIF

   IF cSta $ "KO"

      IF cSta == "O"
         ?
         ?
         ?
      ENDIF
      m := AllTrim( Str( Min( nTop, Len( aTopK ) ) ) ) + " NAJPROMETNIJIH ARTIKALA POSMATRANO PO KOLICINAMA:"
      ?
      ? REPL( "-", Len( m ) )
      ?
      ?U PadC( "ŠIFRA", Len( roba->id ) ) + " " + PadC( "NAZIV", 50 ) + " " + PadC( "KOLIČINA", 20 )
      ? REPL( "-", Len( roba->id ) ) + " " + REPL( "-", 50 ) + " " + REPL( "-", 20 )

      FOR i := 1 TO Len( aTopK )
         cIdRoba := aTopK[ i, 1 ]
         select_o_roba( cIdRoba )
         ? cIdRoba, Left( ROBA->naz, 50 ), PadC( Transform( aTopK[ i, 2 ], pickol ), 20 )
      NEXT
      ? REPL( "-", Len( id ) ) + " " + REPL( "-", 50 ) + " " + REPL( "-", 20 )

   ENDIF

   FF

   ENDPRINT

   CLOSERET

   RETURN .T.


STATIC FUNCTION kalk_kartica_prodavnica_add_item_to_r_export( hParams )

   LOCAL nTArea := Select()

   o_r_export()
   SELECT r_export

   APPEND BLANK
   REPLACE field->idkonto WITH hParams[ "idkonto" ], ;
      field->idvd WITH hParams[ "idvd" ], ;
      field->idroba WITH hParams[ "idroba" ], ;
      field->brdok WITH hParams[ "brdok" ], ;
      field->datdok WITH hParams[ "datdok" ], ;
      field->kolicina WITH hParams[ "kolicina" ], ;
      field->nc WITH hParams[ "nc" ], ;
      field->stanje WITH hParams[ "stanje" ], ;
      field->nv WITH hParams[ "nv" ], ;
      field->rabatv WITH hParams[ "rabatv" ], ;
      field->vpc WITH hParams[ "vpc" ], ;
      field->mpc WITH hParams[ "mpc" ], ;
      field->brfaktp WITH hParams[ "brfaktp" ]

   SELECT ( nTArea )

   RETURN .T.

FUNCTION kalk_kartica_prodavnica_export_dbf_struct()

   LOCAL aDbf := {}

   AAdd( aDbf, { "idkonto", "C", 7, 0 }  )
   AAdd( aDbf, { "idroba", "C", 10, 0 }  )
   AAdd( aDbf, { "idvd", "C", 2, 0 }  )
   AAdd( aDbf, { "brdok", "C", 8, 0 }  )
   AAdd( aDbf, { "brfaktp", "C", 10, 0 }  )
   AAdd( aDbf, { "datdok", "D", 8, 0 }  )
   AAdd( aDbf, { "kolicina", "N", 15, 3 }  )
   AAdd( aDbf, { "stanje", "N", 15, 3 }  )
   AAdd( aDbf, { "nc", "N", 15, 3 }  )
   AAdd( aDbf, { "nv", "N", 15, 3 }  )
   AAdd( aDbf, { "rabatv", "N", 15, 3 }  )
   AAdd( aDbf, { "vpc", "N", 15, 3 }  )
   AAdd( aDbf, { "mpc", "N", 15, 3 }  )

   RETURN aDbf
