
#include "f18.ch"


FUNCTION fin_specif_suban_proizv_sort()

   LOCAL cSqlWhere
   LOCAL bZagl :=  {|| zagl_fin_specif( cSpecifSkracenaVarijantaDN ) }
   LOCAL oPDF, xPrintOpt

   LOCAL _fin_params := fin_params()
   LOCAL _fakt_params := fakt_params()

   PRIVATE fK1 := _fin_params[ "fin_k1" ]
   PRIVATE fK2 := _fin_params[ "fin_k2" ]
   PRIVATE fK3 := _fin_params[ "fin_k3" ]
   PRIVATE fK4 := _fin_params[ "fin_k4" ]

   PRIVATE cSk := "N"
   PRIVATE cSpecifSkracenaVarijantaDN := "N"

   cIdFirma := self_organizacija_id()
   picBHD := FormPicL( "9 " + gPicBHD, 20 )

   dDatOd := dDatDo := CToD( "" )
   qqkonto := Space( 7 )
   qqPartner := Space( 60 )
   qqTel := Space( 60 )
   cTip := "1"
   qqBrDok := ""

   Box( "", 20, 65 )

   set_cursor_on()

   PRIVATE cSort := "1"

   cK1 := cK2 := "9"
   cK3 := cK4 := "99"
   cIdRj := REPLICATE("9", FIELD_LEN_FIN_RJ_ID )
   cFunk := "99999"
   cFond := "9999"

   PRIVATE nC := 65

   DO WHILE .T.
      @ box_x_koord() + 1, box_y_koord() + 6 SAY "SPECIFIKACIJA SUBANALITIKA - PROIZV.SORT."

      @ box_x_koord() + 3, box_y_koord() + 2 SAY "Firma "; ?? self_organizacija_id(), "-", self_organizacija_naziv()

      @ box_x_koord() + 4, box_y_koord() + 2 SAY "Konto   " GET qqkonto  PICT "@!" VALID P_Konto( @qqkonto )
      @ box_x_koord() + 5, box_y_koord() + 2 SAY "Partner " GET qqPartner PICT "@!S50"
      @ box_x_koord() + 6, box_y_koord() + 2 SAY "Datum dokumenta od" GET dDatOd
      @ box_x_koord() + 6, Col() + 2 SAY "do" GET dDatDo


      @ box_x_koord() + 9, box_y_koord() + 2 SAY "Kriterij za telefon" GET qqTel PICT "@!S30"
      @ box_x_koord() + 11, box_y_koord() + 2 SAY "Sortirati po: konto+telefon+partn (1)" GET cSort VALID csort $ "12"

      @ box_x_koord() + 15, box_y_koord() + 2 SAY ""

      IF fk1
         @ box_x_koord() + 15, box_y_koord() + 2 SAY "K1 (9 svi) :" GET cK1
      ENDIF
      IF fk2
         @ box_x_koord() + 15, Col() + 2 SAY "K2 (9 svi) :" GET cK2
      ENDIF
      IF fk3
         @ box_x_koord() + 15, Col() + 2 SAY "K3 (" + cK3 + " svi):" GET cK3
      ENDIF
      IF fk4
         @ box_x_koord() + 15, Col() + 2 SAY "K4 (99 svi):" GET cK4
      ENDIF

      READ
      ESC_BCR

      cFilterIdPartner := Parsiraj( qqPartner, "IdPartner" )
      cFilterPartnerTelefon := Parsiraj( qqTel, "suban_partn_telefon()" )

      IF cFilterIdPartner <> NIL // cFilterPartnerTelefon <> NIL .AND.
         EXIT
      ENDIF

   ENDDO

   BoxC()

   cIdFirma := Left( cIdFirma, 2 )

   nTmpArr := 0
   nArr := 0
   cImeTmp := ""

   // O_SUBAN
   // SET RELATION TO suban->idpartner INTO partn

   IF cK1 == "9"
      cK1 := ""
   ENDIF
   IF cK2 == "9"
      cK2 := ""
   ENDIF
   IF cK3 == REPL( "9", Len( cK3 ) )
      cK3 := ""
   ELSE
      cK3 := k3u256( cK3 )
   ENDIF
   IF cK4 == "99"
      cK4 := ""
   ENDIF

   cSqlWhere := parsiraj_sql( "idkonto", qqKonto )
   cSqlWhere += " AND " + parsiraj_sql( "idpartner", Trim( qqPartner ) )

   MsgO( "Preuzimanje podataka sa SQL servera ..." )
   find_suban_za_period( cIdFirma, dDatOd, dDatDo, "idfirma,idkonto,idpartner,brdok", cSqlWhere )
   Msgc()


   IF cSort == "1"
      cSort1 := "idfirma + idkonto + suban_partn_telefon() + idpartner"
   ENDIF

   PRIVATE cFilt1 := "idfirma == " + _filter_quote( cIdFirma ) + " .and. idkonto == '" + qqkonto + "'"


   IF ( fk1 .AND. fk2 .AND. fk3 .AND. fk4 )
      cFilt1 += iif( Empty( cFilt1 ), "", ".and." ) + "(k1=ck1 .and. k2=ck2 .and. k3=ck3 .and. k4=ck4)"
   ENDIF

   IF cFilterIdPartner <> ".t."
      cFilt1 += ".and.(" + cFilterIdPartner + ")"
   ENDIF
   IF cFilterPartnerTelefon <> ".t."
      cFilt1 += ".and.(" + cFilterPartnerTelefon + ")"
   ENDIF

   SET FILTER TO &cFilt1

   Box(, 1, 30 )

   INDEX ON &cSort1 TAG "TELSORT"
   SET ORDER TO TAG "TELSORT"
   GO TOP

   BoxC()

   Pic := PicBhd


   IF !is_legacy_ptxt()
      oPDF := PDFClass():New()
      xPrintOpt := hb_Hash()
      xPrintOpt[ "tip" ] := "PDF"
      xPrintOpt[ "layout" ] := "portrait"
      xPrintOpt[ "font_size" ] := 7
      xPrintOpt[ "opdf" ] := oPDF
      xPrintOpt[ "left_space" ] := 0
   ENDIF

   nStr := 0
   IF cTip == "3"
      m := "------  " + Replicate( "-", FIELD_LEN_PARTNER_ID ) + " ------------------------------------------------- --------------------- --------------------"
   ELSE
      m := "------  " + Replicate( "-", FIELD_LEN_PARTNER_ID ) + " ------------------------------------------------- --------------------- -------------------- --------------------"
   ENDIF

   IF !start_print( xPrintOpt )
      RETURN .F.
   ENDIF

   Eval( bZagl )

   nUd := nUp := 0      // DIN
   nUd2 := nUp2 := 0    // DEM

   DO WHILE !Eof()

      SELECT suban
      nKd := nKp := 0
      nKd2 := nKp2 := 0
      cIdkonto := idkonto

      IF cSort == "1"
         select_o_partner( suban->idPartner )
         cTelefon := partn->telefon
         select SUBAN
         bUslov := {|| select_o_partner( suban->idpartner ), dbSelectArea( F_SUBAN ), cTelefon == partn->telefon  }
         cNaslov := partn->telefon + "-" + partn->mjesto
      ENDIF


      DO WHILE !Eof() .AND. idfirma == cIdfirma .AND. idkonto == cIdkonto .AND. Eval( bUslov )

         nD := nP := 0
         nD2 := nP2 := 0
         check_nova_strana( bZagl, oPDF )
         cIdPartner := IdPartner
         cNazPartn := PadR( partn->naz, 25 )
         DO WHILE !Eof() .AND. idfirma == cidfirma .AND. idkonto == cidkonto .AND. Eval( bUslov ) .AND. IdPartner == cIdPartner
            IF d_P == "1"
               nD += iznosbhd; nD2 += iznosdem
            ELSE
               nP += iznosbhd; nP2 += iznosdem
            ENDIF
            SELECT suban
            SKIP
         ENDDO

         check_nova_strana( bZagl, oPDF )

         ? cIdkonto, cIdPartner, ""
         IF !Empty( cIdPartner )
            ?? PadR( cNazPARTN, 50 - DifIdp( cIdPartner ) )
         ELSE
            select_o_konto( cIdkonto )
            SELECT SUBAN
            ?? PadR( KONTO->naz, 50 )
         ENDIF

         nC := PCol() + 1
         IF cTip == "1"
            @ PRow(), PCol() + 1 SAY nd PICT pic
            @ PRow(), PCol() + 1 SAY np PICT pic
            @ PRow(), PCol() + 1 SAY nd - np PICT pic
         ELSEIF cTip == "2"
            @ PRow(), PCol() + 1 SAY nd2 PICT pic
            @ PRow(), PCol() + 1 SAY np2 PICT pic
            @ PRow(), PCol() + 1 SAY nd2 - np2 PICT pic
         ELSE
            @ PRow(), PCol() + 1 SAY nd - np PICT pic
            @ PRow(), PCol() + 1 SAY nd2 - np2 PICT pic
         ENDIF
         nKd += nd; nKp += np  // ukupno  za klasu
         nKd2 += nd2; nKp2 += np2  // ukupno  za klasu
      ENDDO  // cSort

      check_nova_strana( bZagl, oPDF )

      ? m
      IF cSort == "1"
         ?  "Ukupno za:", cNaslov, ":"
      ENDIF
      IF cTip == "1"
         @ PRow(), nC       SAY nKd PICT pic
         @ PRow(), PCol() + 1 SAY nKp PICT pic
         @ PRow(), PCol() + 1 SAY nKd - nKp PICT pic
      ELSEIF cTip == "2"
         @ PRow(), nC       SAY nKd2 PICT pic
         @ PRow(), PCol() + 1 SAY nKp2 PICT pic
         @ PRow(), PCol() + 1 SAY nKd2 - nKp2 PICT pic
      ELSE
         @ PRow(), nC       SAY nKd - nKP PICT pic
         @ PRow(), PCol() + 1 SAY nKd2 - nKP2 PICT pic
      ENDIF
      ? m
      nUd += nKd; nUp += nKp   // ukupno za sve
      nUd2 += nKd2; nUp2 += nKp2   // ukupno za sve
   ENDDO
   check_nova_strana( bZagl, oPDF )
   ? m
   ? " UKUPNO:"
   IF cTip == "1"
      @ PRow(), nC       SAY nUd PICT pic
      @ PRow(), PCol() + 1 SAY nUp PICT pic
      @ PRow(), PCol() + 1 SAY nUd - nUp PICT pic
   ELSEIF cTip == "2"
      @ PRow(), nC       SAY nUd2 PICT pic
      @ PRow(), PCol() + 1 SAY nUp2 PICT pic
      @ PRow(), PCol() + 1 SAY nUd2 - nUp2 PICT pic
   ELSE
      @ PRow(), nC       SAY nUd - nUP PICT pic
      @ PRow(), PCol() + 1 SAY nUd2 - nUP2 PICT pic
   ENDIF
   ? m

   IF is_legacy_ptxt()
      FF
   ENDIF
   end_print( xPrintOpt )

   RETURN .T.


FUNCTION suban_partn_telefon()

   LOCAL cTelefon

   select_o_partner( suban->idpartner )
   cTelefon := partn->telefon
   SELECT suban

   RETURN cTelefon
