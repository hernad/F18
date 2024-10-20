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

STATIC s_cPomBrDok := ""

FUNCTION fin_rucno_zatvaranje_otvorenih_stavki()

   LOCAL cSort := "D"
   LOCAL GetList := {}
   LOCAL hParams := hb_Hash()
   LOCAL cIdFirma, cIdPartner, cIdKonto, cIdRj

   open_otv_stavke_tabele()

   cIdFirma := self_organizacija_id()
   cIdPartner := Space( FIELD_LEN_PARTNER_ID )

   picD := FormPicL( "9 " + gPicBHD, 14 )
   picDEM := FormPicL( "9 " + pic_iznos_eur(), 9 )

   cIdKonto := Space( FIELD_LEN_KONTO_ID )

   Box(, 7, 66, )

   set_cursor_on()

   @ box_x_koord() + 1, box_y_koord() + 2 SAY "ISPRAVKA BROJA VEZE - OTVORENE STAVKE"
   @ box_x_koord() + 3, box_y_koord() + 2 SAY "Firma "; ?? self_organizacija_id(), "-", self_organizacija_naziv()

   @ box_x_koord() + 4, box_y_koord() + 2 SAY "Konto  " GET cIdKonto  VALID  p_konto( @cIdKonto )
   @ box_x_koord() + 5, box_y_koord() + 2 SAY "Partner" GET cIdPartner VALID Empty( cIdPartner ) .OR. p_partner( @cIdPartner ) PICT "@!"

   @ box_x_koord() + 6, box_y_koord() + 2 SAY "Sortiranje B/D (broj veze/datum) " GET cSort VALID cSort $ "BD" PICT "@!"

   IF gFinRj == "D"
      cIdRj := Space( FIELD_LEN_FIN_RJ_ID )
      @ box_x_koord() + 7, box_y_koord() + 2 SAY "RJ" GET cIdrj PICT "@!" VALID Empty( cIdrj ) .OR. P_Rj( @cIdrj )
   ENDIF


   READ
   ESC_BCR

   BoxC()

   IF Empty( cIdpartner )
      cIdPartner := ""
   ENDIF

   cIdFirma := Left( cIdFirma, 2 )

   Box(, f18_max_rows() - 5, f18_max_cols() - 10 )

   ImeKol := {}
   AAdd( ImeKol, { "O",          {|| OtvSt }             } )
   AAdd( ImeKol, { "Partn.",     {|| IdPartner }         } )
   AAdd( ImeKol, { "Br.Veze",    {|| BrDok }             } )
   AAdd( ImeKol, { "Dat.Dok.",   {|| DatDok }            } )
   AAdd( ImeKol, { "Opis",       {|| PadR( opis, 20 ) }, "opis",  {|| .T. }, {|| .T. }, "V"  } )
   AAdd( ImeKol, { PadR( "Duguje " + AllTrim( valuta_domaca_skraceni_naziv() ), 13 ), {|| Str( ( iif( D_P == "1", iznosbhd, 0 ) ), 13, 2 ) }     } )
   AAdd( ImeKol, { PadR( "Potraz." + AllTrim( valuta_domaca_skraceni_naziv() ), 13 ),   {|| Str( ( iif( D_P == "2", iznosbhd, 0 ) ), 13, 2 ) }     } )
   AAdd( ImeKol, { "M1",         {|| m1 }                } )
   AAdd( ImeKol, { PadR( "Iznos " + AllTrim( ValPomocna() ), 14 ),  {|| Str( iznosdem, 14, 2 ) }                       } )
   AAdd( ImeKol, { "nalog",      {|| idvn + "-" + brnal + "/" + Str( rbr, 5, 0 ) }                  } )
   Kol := {}

   FOR i := 1 TO Len( ImeKol )
      AAdd( Kol, i )
   NEXT

   PRIVATE aPPos := { 2, 3 }
   PRIVATE bGoreRed := NIL
   PRIVATE bDoleRed := NIL
   PRIVATE bDodajRed := NIL
   PRIVATE fTBNoviRed := .F. // trenutno smo u novom redu ?
   PRIVATE TBCanClose := .T. // da li se moze zavrsiti unos podataka ?
   PRIVATE bZaglavlje := NIL
   // PRIVATE TBSkipBlock := {| nSkip| fin_otvorene_stavke_browse_skip( nSkip ) }
   PRIVATE nTBLine := 1      // tekuca linija-kod viselinijskog browsa
   PRIVATE nTBLastLine := 1  // broj linija kod viselinijskog browsa
   PRIVATE TBPomjerise := "" // ako je ">2" pomjeri se lijevo dva
   PRIVATE TBScatter := "N"  // uzmi samo tekuce polje
   adImeKol := {}

   FOR i := 1 TO Len( ImeKol )
      AAdd( adImeKol, ImeKol[ i ] )
   NEXT

   adKol := {}
   FOR i := 1 TO Len( adImeKol )
      AAdd( adKol, i )
   NEXT

   MsgO( "Preuzimam podatke sa SQL servera ..." )

   IF cSort == "B"
      cOrderBy := "IdFirma,IdKonto,IdPartner,brdok,datdok"
   ELSE
      cOrderBy := "IdFirma,IdKonto,IdPartner,datdok,brdok"
   ENDIF

   // find_suban_by_konto_partner(  cIdFirma, cIdkonto, cIdPartner, NIL, cOrderBy )
   hParams[ "idfirma" ] := cIdFirma
   hParams[ "idkonto" ] := cIdKonto
   hParams[ "idpartner" ] := cIdPartner
   hParams[ "order_by" ] := cOrderBy
   hParams[ "alias" ] := "SUBAN_PREGLED"
   hParams[ "wa" ] := F_SUBAN_PREGLED
   find_suban_by_konto_partner( @hParams )
   MsgC()

   // SELECT SUBAN
   // SET ORDER TO TAG "1"

   IF gFinRj == "D" .AND. !Empty( cIdRJ )
      SET FILTER TO IDRJ == cIdRj
      GO TOP
   ENDIF

   // PRIVATE bBKUslov := {|| idFirma + idkonto + idpartner == cIdFirma + cIdkonto + cIdpartner }
   PRIVATE bBkTrazi := {|| cIdFirma + cIdkonto + cIdPartner }

   set_cursor_on()

   PRIVATE cPomBrDok := Space( 10 )

   // SEEK Eval( bBkUslov )

   fin_otvorene_stavke_opcije_browse_pregleda( cIdKonto )

   my_browse( "Ost", f18_max_rows() - 10, f18_max_cols() - 10, {| nCh | fin_rucno_zatvaranje_otv_stavki_key_handler( nCh, NIL ) }, ;
      "", "", .F., NIL, 1, {|| otvst == "9" }, 6, 0, NIL, NIL )
   // {| nSkip| fin_otvorene_stavke_browse_skip( nSkip ) } )

   BoxC()

   my_close_all_dbf()

   RETURN .T.


STATIC FUNCTION fin_rucno_zatvaranje_otv_stavki_key_handler( Ch, lOSuban )

   LOCAL hRec
   LOCAL cMark
   LOCAL cDn  := "N"
   LOCAL nRet := DE_CONT
   LOCAL cOtvSt := " "

   // LOCAL nTrec := RecNo()
   LOCAL cFilterRucnoZatvaranje := dbFilter()
   LOCAL nDbfArea := Select()
   LOCAL GetList := {}
   LOCAL cBrDok, cOpis, dDatDok, dDatVal


   IF lOSuban == NIL
      lOSuban := .F.
   ENDIF

   DO CASE

/*
   CASE Ch == K_ALT_E .AND. FieldPos( "_OBRDOK" ) = 0

      IF Pitanje(, "Preći u mod direktog unosa podataka u tabelu ? (D/N)", "D" ) == "D"
         log_write( "otovrene stavke, mod direktnog unosa = D", 5 )
         fin_otvorene_stavke_opcije_browse_pregleda( cIdKonto )
         DaTBDirektni()
      ENDIF
*/

   CASE Ch == K_ENTER

      cDn := "N"
      Box(, 3, 50 )
      @ box_x_koord() + 1, box_y_koord() + 2 SAY8 "Ne preporučuje se korištenje ove opcije !"
      @ box_x_koord() + 3, box_y_koord() + 2 SAY8 "Želite li ipak nastaviti D/N" GET cDN PICT "@!" VALID cDn $ "DN"
      READ
      BoxC()

      IF cDN == "D"

         IF field->otvst <> "9"
            cMark   := ""
            cOtvSt := "9"
         ELSE
            cMark   := "9"
            cOtvSt := " "
         ENDIF

         hRec := dbf_get_rec()
         hRec[ "otvst" ] := cOtvSt
         find_suban_za_period( "XX" )
         update_rec_server_and_dbf( "fin_suban", hRec, 1, "FULL" )
         log_write( "otvorene stavke, set marker=" + cMark, 5 )
         SELECT SUBAN_PREGLED
         REPLACE otvst WITH  cOtvSt
         nRet := DE_REFRESH

      ELSE
         nRet := DE_CONT

      ENDIF

   CASE ( Ch == Asc( "K" ) .OR. Ch == Asc( "k" ) )

      IF field->m1 <> "9"
         cOtvSt := "9"
      ELSE
         cOtvSt := " "
      ENDIF
      log_write( "otvorene stavke, marker=" + cOtvSt, 5 )
      hRec := dbf_get_rec()
      hRec[ "m1" ] := cOtvSt

      find_suban_za_period( "XX" )
      update_rec_server_and_dbf( "fin_suban", hRec, 1, "FULL" )
      SELECT SUBAN_PREGLED
      REPLACE m1 WITH cOtvSt

      nRet := DE_REFRESH

   CASE Ch == K_F2

      cBrDok := suban_pregled->BrDok
      cOpis := suban_pregled->opis
      dDatDok := suban_pregled->datdok
      dDatVal := suban_pregled->datval

      Box( "eddok", 5, 70, .F. )
      @ box_x_koord() + 1, box_y_koord() + 2 SAY "Broj Dokumenta (broj veze):" GET cBrDok
      @ box_x_koord() + 2, box_y_koord() + 2 SAY "Opis:" GET cOpis PICT "@S50"
      @ box_x_koord() + 4, box_y_koord() + 2 SAY "Datum dokumenta: "
      ?? dDatDok
      @ box_x_koord() + 5, box_y_koord() + 2 SAY "Datum valute   :" GET dDatVal
      READ
      BoxC()

      IF LastKey() <> K_ESC

         hRec := dbf_get_rec()
         hRec[ "brdok" ] := cBrDok
         hRec[ "opis" ]  := cOpis
         hRec[ "datval" ] := dDatVal
         log_write( "otvorene stavke, ispravka broja veze, set=" + cBrDok, 5 )
         find_suban_za_period( "XX" )
         update_rec_server_and_dbf( "fin_suban", hRec, 1, "FULL" )
         SELECT SUBAN_PREGLED
         REPLACE brdok WITH cBrDok, opis WITH cOpis, datval WITH dDatVal
         nRet := DE_REFRESH

      ELSE
         nRet := DE_CONT
      ENDIF


   CASE Ch == K_F5

      s_cPomBrDok := suban_pregled->BrDok

   CASE Ch == K_F6

/*
      IF FieldPos( "_OBRDOK" ) <> 0
         // nalazimo se u asistentu
         fin_ostav_stampa_azuriranih_promjena()

         open_otv_stavke_tabele( lOSuban )
         SELECT ( nDbfArea )
         SET FILTER TO &( cFilterRucnoZatvaranje )
         //GO ( nTrec )
         //SELECT SUBAN_PREGLED


      ELSE
  */
      IF !Empty( s_cPomBrDok ) .AND. Pitanje(, "Želite li da vezni broj " + Alltrim( suban_pregled->BrDok ) + " zamijenite brojem: " + Alltrim( s_cPomBrDok ) + " ?", "D" ) == "D"
         SELECT SUBAN_PREGLED
         hRec := dbf_get_rec()
         hRec[ "brdok" ] := s_cPomBrDok
         log_write( "otvorene stavke, zamjena broja veze, set=" + s_cPomBrDok, 5 )
         find_suban_za_period( "XX" )
         update_rec_server_and_dbf( "fin_suban", hRec, 1, "FULL" )
         SELECT SUBAN_PREGLED
         replace brdok with s_cPomBrDok
      ENDIF
      // ENDIF

      nRet := DE_REFRESH

   CASE Ch == K_CTRL_P

      fin_kartica_otvorene_stavke_po_broju_veze(  suban_pregled->Idfirma, suban_pregled->Idkonto, suban_pregled->Idpartner, suban_pregled->BrDok  )

      // open_otv_stavke_tabele( lOSuban )
      // SELECT ( nDbfArea )
      // SET FILTER TO &( cFilterRucnoZatvaranje )
      // GO ( nTrec )
      // SELECT SUBAN_PREGLED
      nRet := DE_CONT

   CASE Ch == iif( is_mac(), Asc( "P" ), K_ALT_P )

      fin_otv_stavke_stampa_za_broj_veze(  suban_pregled->Idfirma, suban_pregled->Idkonto, suban_pregled->Idpartner, suban_pregled->BrDok )
      // open_otv_stavke_tabele( lOSuban )
      // SELECT ( nDbfArea )
      // SET FILTER TO &( cFilterRucnoZatvaranje )
      // GO ( nTrec )
      // SELECT SUBAN_PREGLED
      nRet := DE_CONT

   ENDCASE


   SELECT SUBAN_PREGLED

   RETURN nRet



/*

FUNCTION fin_otvorene_stavke_browse_skip( nRequest )

   LOCAL nCount

   nCount := 0

   IF LastRec() != 0

      IF ! Eval( bBKUslov )
         SEEK Eval( bBkTrazi )
         IF ! Eval( bBKUslov )
            GO BOTTOM
            SKIP 1
         ENDIF
         nRequest = 0
      ENDIF

      IF nRequest > 0
         DO WHILE nCount < nRequest .AND. Eval( bBKUslov )
            SKIP 1
            IF Eof() .OR. !Eval( bBKUslov )
               SKIP -1
               EXIT
            ENDIF
            nCount++
         ENDDO

      ELSEIF nRequest < 0
         DO WHILE nCount > nRequest .AND. Eval( bBKUslov )
            SKIP -1
            IF ( Bof() )
               EXIT
            ENDIF
            nCount--
         ENDDO
         IF !Eval( bBKUslov )
            SKIP 1
            nCount++
         ENDIF

      ENDIF

   ENDIF

   RETURN ( nCount )
*/
