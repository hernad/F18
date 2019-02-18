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
MEMVAR cIdFirma, cIdRoba, cIdKonto

FUNCTION kalk_kartica_prodavnica()

   PARAMETERS cIdFirma, cIdRoba, cIdKonto

   LOCAL cLine
   LOCAL cTxt1
   LOCAL cTxt2
   LOCAL cTxt3
   LOCAL nNc, nSredNc, nOdstupanje, cTransakcija
   LOCAL cPrikSredNc := "N"
   LOCAL cIdvd := Space( 100 )
   LOCAL hParams := hb_Hash(), cExportDN := "N", lExport := .F.
   LOCAL GetList := {}
   LOCAL cIdRobaTackaZarez := cIdRoba
   LOCAL lRobaTackaZarez := .F.
   LOCAL cOrderBy
   LOCAL nCol1, nCol2
   LOCAL nPDVCijena
   LOCAL nUlaz, nIzlaz
   LOCAL nMPV, nNV, nMPVDug, nMPVPot

   PRIVATE PicCDEM := kalk_prosiri_pic_cjena_za_2()
   PRIVATE PicProc := gPicProc
   PRIVATE PicDEM := kalk_prosiri_pic_iznos_za_2()
   PRIVATE PicKol := kalk_prosiri_pic_kolicina_za_2()
   PRIVATE nKalkMarzaVP, nKalkMarzaMP

   cPredh := "N"
   dDatOd := Date()
   dDatDo := Date()
   nKalkMarzaVP := nKalkMarzaMP := 0

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

      Box(, 11, 70 )

      DO WHILE .T.

         @ box_x_koord() + 1, box_y_koord() + 2 SAY "Firma "
         ?? self_organizacija_id(), "-", self_organizacija_naziv()

         @ box_x_koord() + 2, box_y_koord() + 2 SAY "Konto " GET cIdKonto VALID P_Konto( @cIdKonto )
         kalk_kartica_get_roba_id( @cIdRoba, box_x_koord() + 3, box_y_koord() + 2, @GetList )
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

   cOrderBy := "idfirma,pkonto,idroba,datdok,pu_i,idvd"
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

   set_zagl( @cLine, @cTxt1 )
   s_cLine := cLine
   s_cTxt1 := cTxt1

   nTStrana := 0

   Zagl()

   nCol1 := 10
   nCol2 := 20
   nUlaz := nIzlaz := 0
   nMPVDug := nMPVPot := 0
   nMPV := nNV := 0

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

      nCol2 := 10
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

            IF Round( nUlaz - nIzlaz, 4 ) <> 0 // kolicinski <> 0
               @ PRow(), PCol() + 1 SAY say_cijena( nNV / ( nUlaz - nIzlaz ) )
               @ PRow(), PCol() + 1 SAY say_cijena( nMPV / ( nUlaz - nIzlaz ) )
               @ PRow(), PCol() + 1 SAY kalk_say_iznos( nMPVDug )
               @ PRow(), PCol() + 1 SAY kalk_say_iznos( nMPVPot )
               @ PRow(), PCol() + 1 SAY kalk_say_iznos( nMPV )

            ELSEIF Round( nMpv, 3 ) <> 0 // kolicinski 0, ali vrijednost <> 0
               @ PRow(), PCol() + 1 SAY say_cijena( 0  )
               @ PRow(), PCol() + 1 SAY say_cijena( "ERR" )
            ELSE // sve ok
               @ PRow(), PCol() + 1 SAY say_kolicina( 0  )
            ENDIF
         ENDIF

         IF ( PRow() - dodatni_redovi_po_stranici() ) > 62
            FF
            Zagl()
         ENDIF

         IF field->pu_i == "1"

            nUlaz += field->kolicina - field->GKolicina - kalk->gkolicin2
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
               //@ PRow(), PCol() + 1 SAY say_cijena( field->vpc )
               @ PRow(), PCol() + 1 SAY say_cijena( kalk->mpcsapp )

            ENDIF

            // nMPVP += kalk->mpcsapp * field->kolicina
            nMPVDug += kalk->mpcsapp * field->kolicina
            nNV += field->nc * field->kolicina
            nMPV := nMPVDug - nMPVPot

            IF field->datdok >= dDatOd
               nCol2 := PCol() + 1
               @ PRow(), PCol() + 1 SAY kalk_say_iznos( nMpvDug )
               @ PRow(), PCol() + 1 SAY kalk_say_iznos( nMpvPot )
               @ PRow(), PCol() + 1 SAY kalk_say_iznos( nMpv )
            ENDIF

         ELSEIF field->pu_i == "5" .AND. !( field->idvd $ "12#13" )

            nIzlaz += field->kolicina
            nPDVCijena := field->mpc * pdv_procenat_by_tarifa( cIdTarifa )

            IF kalk->datdok >= dDatod

               ? kalk->datdok, field->idvd + "-" + field->brdok, field->idtarifa, field->idpartner
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
               //@ PRow(), PCol() + 1 SAY say_cijena( field->mpc )
               @ PRow(), PCol() + 1 SAY say_cijena( kalk->mpcsapp )

            ENDIF

            nMPVPot += kalk->mpcsapp * kalk->kolicina
            nNV -= kalk->nc * kalk->kolicina
            nMPV := nMPVDug - nMPVPot

            IF field->datdok >= dDatOd
               nCol2 := PCol() + 1
               @ PRow(), PCol() + 1 SAY kalk_say_iznos( nMpvDug )
               @ PRow(), PCol() + 1 SAY kalk_say_iznos( nMpvPot )
               @ PRow(), PCol() + 1 SAY kalk_say_iznos( nMpv )
            ENDIF

         ELSEIF kalk->pu_i == "I"
            nIzlaz += kalk->gkolicin2

            IF kalk->datdok >= dDatod
               ? field->datdok, field->idvd + "-" + field->brdok, field->idtarifa, field->idpartner
               nCol1 := PCol() + 1
               @ PRow(), PCol() + 1 SAY say_kolicina( 0 )
               @ PRow(), PCol() + 1 SAY say_kolicina( kalk->gkolicin2 )
               @ PRow(), PCol() + 1 SAY say_kolicina( nUlaz - nIzlaz )
               nNc := field->nc
               cTransakcija := " INV"
               @ PRow(), PCol() + 1 SAY say_cijena( nNc )
               //@ PRow(), PCol() + 1 SAY say_cijena( 0 )
               @ PRow(), PCol() + 1 SAY say_cijena( kalk->mpcsapp )
            ENDIF

            // nMPVP -= kalk->mpcsapp * kalk->gkolicin2
            nMPVPot += kalk->mpcsapp * kalk->gkolicin2
            nNV -= field->nc * kalk->gkolicin2
            nMPV := nMPVDug - nMPVPot

            IF field->datdok >= dDatod
               nCol2 := PCol() + 1
               @ PRow(), PCol() + 1 SAY kalk_say_iznos( nMpvDug )
               @ PRow(), PCol() + 1 SAY kalk_say_iznos( nMpvPot )
               @ PRow(), PCol() + 1 SAY kalk_say_iznos( nMpv )

            ENDIF

         ELSEIF field->pu_i == "5" .AND. ( field->idvd $ "12#13" )

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
               //@ PRow(), PCol() + 1 SAY say_cijena( field->vpc )
               @ PRow(), PCol() + 1 SAY say_cijena( kalk->mpcsapp )
            ENDIF

            // nMPVP -= kalk->mpcsapp * field->kolicina
            nMPVPot += kalk->mpcsapp * field->kolicina
            nNV -= field->nc * field->kolicina
            nMPV := nMPVDug - nMPVPot

            IF field->datdok >= dDatod
               nCol2 := PCol() + 1
               @ PRow(), PCol() + 1 SAY kalk_say_iznos( nMpvDug )
               @ PRow(), PCol() + 1 SAY kalk_say_iznos( nMpvPot )
               @ PRow(), PCol() + 1 SAY kalk_say_iznos( nMpv )
            ENDIF

         ELSEIF field->pu_i == "3" // nivelacija

            IF field->datdok >= dDatod
               ? field->datdok, field->idvd + "-" + field->brdok, field->idtarifa, field->idpartner
               nCol1 := PCol() + 1
               @ PRow(), PCol() + 1 SAY say_kolicina( field->kolicina )
               @ PRow(), PCol() + 1 SAY say_kolicina( "[NIV]" )
               @ PRow(), PCol() + 1 SAY say_kolicina( "St-Nova:" )
               @ PRow(), PCol() + 1 SAY say_cijena( field->fcj )
               @ PRow(), PCol() + 1 SAY say_cijena( field->fcj + kalk->mpcsapp )
            ENDIF

            nMPVDug += kalk->mpcsapp * field->kolicina // razlika nova-stara cijena
            nMPV := nMPVDug - nMPVPot

            IF field->datdok >= dDatod
               nCol2 := PCol() + 1
               @ PRow(), PCol() + 1 SAY kalk_say_iznos( nMpvDug )
               @ PRow(), PCol() + 1 SAY kalk_say_iznos( nMpvPot )
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
            hParams[ "mpc" ] := kalk->mpcsapp
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
         @ PRow(), PCol() + 1 SAY say_cijena( nMPV / ( nUlaz - nIzlaz ) )
      ELSEIF Round( nMpv, 3 ) <> 0 // kolicinski 0, ali vrijednost postoji
         @ PRow(), PCol() + 1 SAY say_cijena( 0 )
         @ PRow(), PCol() + 1 SAY say_cijena( "ERR" )
      ELSE
         @ PRow(), PCol() + 1 SAY say_cijena( 0 )
      ENDIF

      @ PRow(), nCol2 SAY kalk_say_iznos( nMpvDug )
      @ PRow(), PCol() + 1 SAY kalk_say_iznos( nMpvPot )
      @ PRow(), PCol() + 1 SAY kalk_say_iznos( nMpv )


      ? s_cLine
      ?
      ? Replicate( "-", 60 )
      // ? "     Ukupna vrijednost popusta u mp:", Str( Abs( nMPVP - nMPV ), 12, 2 )
      // ? "Ukupna prodajna vrijednost - popust:", Str( nMPVP, 12, 2 )
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


STATIC FUNCTION set_zagl( cLine, cTxt1 )

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
   //AAdd( aKProd, { nPom, PadC( "MPCbezPDV", nPom ) } )
   AAdd( aKProd, { nPom, PadC( "MPC", nPom ) } )
   AAdd( aKProd, { nPom, PadC( "MPV.Dug", nPom ) } )
   AAdd( aKProd, { nPom, PadC( "MPV.Pot", nPom ) } )
   AAdd( aKProd, { nPom, PadC( "MPV", nPom ) } )

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

   ? "Konto: ", cIdkonto, "-", konto->naz
   SELECT kalk
   P_COND
   ? s_cLine
   ? s_cTxt1
   ? s_cLine

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
