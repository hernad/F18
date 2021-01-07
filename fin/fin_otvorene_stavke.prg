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

STATIC s_cKupciLike := NIL // konta koja se prilikom azuriranja koriste za brisanje markera otvorenih stavki


FUNCTION fin_otvorene_stavke_meni()

   LOCAL aOpc := {}
   LOCAL aOpcExe := {}
   LOCAL nIzbor := 1

   PRIVATE gnLost := 0

   AAdd( aOpc, "1. ručno zatvaranje                                 " )
   AAdd( aOpcExe, {|| fin_rucno_zatvaranje_otvorenih_stavki() } )

   AAdd( aOpc, "2. automatsko zatvaranje" )
   AAdd( aOpcExe, {|| fin_automatsko_zatvaranje_otvorenih_stavki() } )

   AAdd( aOpc, "3. kartica otvorenih stavki" )
   AAdd( aOpcExe, {|| fin_suban_kartica( .T. ) } )

   AAdd( aOpc, "4. uporedna kartica dva konta" )
   AAdd( aOpcExe, {|| fin_suban_kartica2( .T. ) } )

   AAdd( aOpc, "5. specifikacija otvorenih stavki" )
   AAdd( aOpcExe, {|| fin_specif_otvorene_stavke() } )

   AAdd( aOpc, "6. ios" )
   AAdd( aOpcExe, {|| fin_ios_meni() } )
   AAdd( aOpc, "7. kartice grupisane po brojevima veze" )
   AAdd( aOpcExe, {|| fin_kartica_otvorene_stavke_po_broju_veze( NIL, NIL, NIL, NIL, .T. ) } )

   AAdd( aOpc, "8. kompenzacija" )
   AAdd( aOpcExe, {|| Kompenzacija() } )

   // AAdd( aOpc, "9. asistent otvorenih stavki" )
   // AAdd( aOpcExe, {|| fin_asistent_otv_st() } )

   AAdd( aOpc, "B. brisanje svih markera otvorenih stavki" )
   AAdd( aOpcExe, {|| fin_brisanje_markera_otvorenih_stavki() } )

   f18_menu( "oasi", .F., nIzbor, aOpc, aOpcExe )

   RETURN .T.



FUNCTION fin_brisanje_markera_otvorenih_stavki()

   LOCAL lRet := .F.
   LOCAL lOk := .T.
   LOCAL hParams, cSql

   IF Pitanje(, "Pobrisati sve markere otvorenih stavki (D/N) ?", "N" ) == "N"
      RETURN .F.
   ENDIF

   IF Pitanje(, "Jeste li sigurni ?!", "N" ) == "N"
      RETURN .F.
   ENDIF
   cSql := "update " + f18_sql_schema( "fin_suban" ) + " set otvst=' ' where otvst='9';"
   cSql += "select count(*) from " + f18_sql_schema( "fin_suban" ) + " where otvst='9'"
   MsgO( "Brisanje markera... molimo sačekajte trenutak ..." )
   lRet := use_sql( "del_ostav", cSql )
   MsgC()

   MsgBeep( "ostav cnt=" + Str( del_ostav->COUNT, 5 ) )

   RETURN lRet



FUNCTION param_otvorene_stavke_kupci_konto_like( cSet )

      LOCAL cParamName := "fin_ostav_kupci_konto_like"

      IF s_cKupciLike == NIL
         s_cKupciLike := fetch_metric( cParamName, NIL,  "211%" )
      ENDIF

      IF cSet != NIL
         s_cKupciLike := Trim( cSet )
         set_metric( cParamName, NIL, cSet )
      ENDIF

      RETURN s_cKupciLike


   /*

   brisanje markera za stavke nalog koji se vraca u pripremu

  -- UPDATE fmk.fin_suban set otvst=' '
  --  FROM
  -- ( select idfirma,idkonto,idpartner,brdok from fmk.fin_suban where idfirma='10' and idvn='61' and brnal='00000001' and otvst='9' ) as SUBQ
  --  WHERE fmk.fin_suban.idfirma=SUBQ.idfirma and fmk.fin_suban.idpartner=SUBQ.idpartner and fmk.fin_suban.brdok=SUBQ.brdok

   */

FUNCTION fin_brisanje_markera_otvorenih_stavki_vezanih_za_nalog( cIdFirma, cIdVn, cBrNal )

   LOCAL cSql
   LOCAL cKupciLike := param_otvorene_stavke_kupci_konto_like()

   IF Empty( cKupciLike ) // markeri otvorenih stavki se ne diraju prilikom povrata dokumenta u pripremu
      RETURN .T.
   ENDIF

   MsgO( "Brisanje markera otvorenih stavki " + cKupciLike )
   cSql := "UPDATE " + f18_sql_schema( "fin_suban" ) + " set otvst=' ' FROM "
   cSql += "( select idfirma,idkonto,idpartner,brdok from  " + f18_sql_schema( "fin_suban" ) + " WHERE "
   cSql += "idfirma=" + sql_quote( cIdFirma )
   cSql += "AND idvn=" + sql_quote( cIdVn )
   cSql += "AND brnal=" + sql_quote( cBrNal )
   cSql += "AND idkonto like " + sql_quote( cKupciLike )
   cSql += ") AS SUBQ "
   cSql += "WHERE " + f18_sql_schema( "fin_suban" ) + ".idfirma=SUBQ.idfirma and " + f18_sql_schema( "fin_suban" ) + ".idpartner=SUBQ.idpartner and " + f18_sql_schema( "fin_suban" ) + ".brdok=SUBQ.brdok"

   run_sql_query( cSql )
   MsgC()

   RETURN .T.




FUNCTION fin_kartica_otvorene_stavke_po_broju_veze( cIdFirma, cIdKonto, cIdPartner, cBrDok, lUnesiPodatke, lBezPitanjaPartnerKonto, bFilter )

   LOCAL nCol1 := 72, cSvi := "N", cSviD := "N", lPrikazDatumDokumentaIValutiranje := .F.
   LOCAL GetList := {}
   LOCAL cPrelomljeno

   IF lBezPitanjaPartnerKonto == NIL
      lBezPitanjaPartnerKonto := .F.
   ENDIF

   // PRIVATE cIdPartner

   cDokument := Space( 8 )
   picBHD := FormPicL( gPicBHD, 14 )
   picDEM := FormPicL( pic_iznos_eur(), 10 )

   IF lBezPitanjaPartnerKonto .OR. Pitanje(, "Želite li prikaz sa datumima dokumenta i valutiranja ? (D/N)", "D" ) == "D"
      lPrikazDatumDokumentaIValutiranje := .T.
   ENDIF

   IF lUnesiPodatke == NIL
      lUnesiPodatke := .F.
   ENDIF

   IF fin_dvovalutno()
      M := "----------- ------------- -------------- -------------- ---------- ---------- ---------- --"
   ELSE
      M := "----------- ------------- -------------- -------------- --"
   ENDIF

   IF lPrikazDatumDokumentaIValutiranje
      m := "-------- -------- -------- " + m
   ENDIF

   nStr := 0
   fVeci := .F.
   cPrelomljeno := "N"

   IF lBezPitanjaPartnerKonto

      cSvi := "D"

   ELSEIF lUnesiPodatke

      // o_suban()
      // o_partner()
      // o_konto()
      cIdFirma := self_organizacija_id()
      cIdkonto := Space( 7 )
      cIdPartner := Space( 6 )

      Box(, 5, 60 )
      // IF gNW == "D"
      @ box_x_koord() + 1, box_y_koord() + 2 SAY "Firma "; ?? self_organizacija_id(), "-", self_organizacija_naziv()
      // ELSE
      // @ box_x_koord() + 1, box_y_koord() + 2 SAY "Firma: " GET cIdFirma VALID {|| p_partner( @cIdFirma ), cidfirma := Left( cidfirma, 2 ), .T. }
      // ENDIF
      @ box_x_koord() + 2, box_y_koord() + 2 SAY "Konto:               " GET cIdkonto   PICT "@!"  VALID p_konto( @cIdkonto )
      @ box_x_koord() + 3, box_y_koord() + 2 SAY "Partner (prazno svi):" GET cIdpartner PICT "@!"  VALID Empty( cIdpartner )  .OR. ( "." $ cIdpartner ) .OR. ( ">" $ cidpartner ) .OR. p_partner( @cIdPartner )
      @ box_x_koord() + 5, box_y_koord() + 2 SAY "Prikaz prebijenog stanja " GET cPrelomljeno VALID cPrelomljeno $ "DN" PICT "@!"
      READ
      ESC_BCR
      Boxc()
   ELSE
      IF Pitanje(, "Želite li napraviti ovaj izvjestaj za sve partnere ?", "N" ) == "D"
         cSvi := "D"
      ENDIF
   ENDIF

   IF !lBezPitanjaPartnerKonto .AND. Pitanje(, "Prikazati dokumente sa saldom 0 ?", "N" ) == "D"
      cSviD := "D"
   ENDIF

   IF lBezPitanjaPartnerKonto
      // onda svi
   ELSEIF !lUnesiPodatke

/*
      IF Type( 'TB' ) = "O"
         IF ValType( aPPos[ 1 ] ) = "C"
            cIdPartner := aPPos[ 1 ]
         ELSE
            cIdPartner := Eval( TB:getColumn( aPPos[ 1 ] ):Block )
         ENDIF
      ENDIF
*/

   ELSE

      IF "." $ cIdpartner
         cIdpartner := StrTran( cIdpartner, ".", "" )
         cIdPartner := Trim( cIdPartner )
      ENDIF

      IF ">" $ cIdpartner
         cIdpartner := StrTran( cIdpartner, ">", "" )
         cIdPartner := Trim( cIdPartner )
         fVeci := .T.
      ENDIF

      IF Empty( cIdpartner )
         cIdpartner := ""
      ENDIF

      cSvi := cIdpartner

   ENDIF

   IF lBezPitanjaPartnerKonto .OR. lPrikazDatumDokumentaIValutiranje

      SELECT ( F_TRFP2 )
      IF !Used()
         o_trfp2()
      ENDIF

      HSEEK "99 " + Left( cIdKonto, 1 )
      DO WHILE !Eof() .AND. IDVD == "99" .AND. Trim( idkonto ) != Left( cIdKonto, Len( Trim( idkonto ) ) )
         SKIP 1
      ENDDO

      IF IDVD == "99" .AND. Trim( idkonto ) == Left( cIdKonto, Len( Trim( idkonto ) ) )
         cDugPot := D_P
      ELSE
         cDugPot := "1"
         Box( , 3, 60 )
         @ box_x_koord() + 2, box_y_koord() + 2 SAY8 "Konto " + cIdKonto + " duguje / potražuje (1/2)" GET cDugpot  VALID cdugpot $ "12" PICT "9"
         READ
         Boxc()
      ENDIF

      fin_create_pom_table( lBezPitanjaPartnerKonto )

   ENDIF


   IF !lBezPitanjaPartnerKonto
      START PRINT RET
   ENDIF

   nUkDugBHD := nUkPotBHD := 0

   // SELECT suban
   // SET ORDER TO TAG "3"

   IF cSvi == "D"
      find_suban_by_konto_partner(  cIdFirma, cIdkonto, NIL, NIL, "IdFirma,IdKonto,IdPartner,brdok" )

   ELSE
      find_suban_by_konto_partner(  cIdFirma, cIdkonto, cIdPartner, NIL, "IdFirma,IdKonto,IdPartner,brdok" )
   ENDIF

   DO WHILE !Eof() .AND. idfirma == cIdfirma .AND. cIdKonto == IdKonto

      IF bFilter <> NIL
         IF !Eval( bFilter )
            SKIP
            LOOP
         ENDIF
      ENDIF

      cIdPartner := idpartner

      nUDug2 := nUPot2 := 0
      nUDug := nUPot := 0
      fPrviprolaz := .T.

      DO WHILE !Eof() .AND. idfirma == cIdfirma .AND. cIdKonto == IdKonto .AND. cIdPartner == IdPartner

         IF bFilter <> NIL
            IF !Eval( bFilter )
               SKIP
               LOOP
            ENDIF
         ENDIF

         cBrDok := BrDok
         cOtvSt := otvst
         nDug2 := nPot2 := 0
         nDug := nPot := 0
         aFaktura := { CToD( "" ), CToD( "" ), CToD( "" ) }

         DO WHILE !Eof() .AND. idfirma == cidfirma .AND. cIdKonto == IdKonto .AND. cIdPartner == IdPartner .AND. brdok == cBrDok
            IF D_P == "1"
               nDug += IznosBHD
               nDug2 += IznosDEM
            ELSE
               nPot += IznosBHD
               nPot2 += IznosDEM
            ENDIF

            IF lPrikazDatumDokumentaIValutiranje .AND. D_P == cDugPot
               aFaktura[ 1 ] := DATDOK
               aFaktura[ 2 ] := fix_dat_var( DATVAL, .T. )
            ENDIF

            IF lBezPitanjaPartnerKonto
               // poziv iz procedure RekPPG()
               // za izvjestaj maksuz radjen za Opresu³22.03.01.³
               // ------------------------------------ÀÄ MSÄÄÄÄÄÙ
               IF aFaktura[ 3 ] < iif( Empty( fix_dat_var( DATVAL, .T. ) ), DatDok, DatVal )
                  // datum zadnje promjene iif ubacen 03.11.2000 eh
                  // ----------------------------------------------
                  aFaktura[ 3 ] := iif( Empty( fix_dat_var( DATVAL, .T. ) ), DatDok, DatVal )
               ENDIF
            ELSE
               // kao u asist.otv.stavki - koristi npr. Exclusive³22.03.01.³
               // -----------------------------------------------ÀÄ MSÄÄÄÄÄÙ
               IF aFaktura[ 3 ] < DatDok
                  aFaktura[ 3 ] := DatDok
               ENDIF
            ENDIF

            SKIP 1
         ENDDO

         IF cSvid == "N" .AND. Round( nDug - nPot, 2 ) == 0
            // nista
         ELSE
            IF lPrikazDatumDokumentaIValutiranje
               fPrviProlaz := .F.
               IF cPrelomljeno == "D"
                  IF ( ndug - npot ) > 0
                     nDug := nDug - nPot
                     nPot := 0
                  ELSE
                     nPot := nPot - nDug
                     nDug := 0
                  ENDIF
                  IF ( ndug2 - npot2 ) > 0
                     nDug2 := nDug2 - nPot2
                     nPot2 := 0
                  ELSE
                     nPot2 := nPot2 - nDug2
                     nDug2 := 0
                  ENDIF
               ENDIF
               //
               SELECT POM
               APPEND BLANK
               Scatter()
               _idpartner := cIdPartner
               _datdok    := aFaktura[ 1 ]
               _datval    := fix_dat_var( aFaktura[ 2 ], .T. )
               _datzpr    := aFaktura[ 3 ]
               IF Empty( _DatDok ) .AND. Empty( _DatVal )
                  _DatVal := _DatZPR
               ENDIF
               _brdok     := cBrDok
               _dug       := nDug
               _pot       := nPot
               _dug2      := nDug2
               _pot2      := nPot2
               _otvst     := cOtvSt
               Gather()
               SELECT SUBAN
            ELSE
               IF !lBezPitanjaPartnerKonto
                  IF PRow() > 52 + dodatni_redovi_po_stranici()
                     FF
                     fin_zagl_ostav_grupisano_po_br_veze( cIdFirma, cIdKonto, cIdPartner, .T., lPrikazDatumDokumentaIValutiranje )
                     fPrviProlaz := .F.
                  ENDIF
                  IF fPrviProlaz
                     fin_zagl_ostav_grupisano_po_br_veze( cIdFirma, cIdKonto, cIdPartner, NIL, lPrikazDatumDokumentaIValutiranje )
                     fPrviProlaz := .F.
                  ENDIF
                  ? PadR( cBrDok, 10 )
                  nCol1 := PCol() + 1
               ENDIF
               IF cPrelomljeno == "D"
                  IF ( ndug - npot ) > 0
                     nDug := nDug - nPot
                     nPot := 0
                  ELSE
                     nPot := nPot - nDug
                     nDug := 0
                  ENDIF
                  IF ( ndug2 - npot2 ) > 0
                     nDug2 := nDug2 - nPot2
                     nPot2 := 0
                  ELSE
                     nPot2 := nPot2 - nDug2
                     nDug2 := 0
                  ENDIF
               ENDIF
               IF !lBezPitanjaPartnerKonto
                  @ PRow(), nCol1 SAY nDug PICTURE picBHD
                  @ PRow(), PCol() + 1  SAY nPot PICTURE picBHD
                  @ PRow(), PCol() + 1  SAY nDug - nPot PICTURE picBHD
                  IF fin_dvovalutno()
                     @ PRow(), PCol() + 1  SAY nDug2 PICTURE picdem
                     @ PRow(), PCol() + 1  SAY nPot2 PICTURE picdem
                     @ PRow(), PCol() + 1  SAY nDug2 - nPot2 PICTURE picdem
                  ENDIF
                  @ PRow(), PCol() + 2  SAY cOtvSt
               ENDIF
               nUDug += nDug; nUPot += nPot
               nUDug2 += nDug2; nUPot2 += nPot2
            ENDIF
         ENDIF

      ENDDO
      // partner

      IF !lBezPitanjaPartnerKonto

         IF PRow() > 58 + dodatni_redovi_po_stranici()
            FF
            fin_zagl_ostav_grupisano_po_br_veze( cIdFirma, cIdKonto, cIdPartner, .T., lPrikazDatumDokumentaIValutiranje )
         ENDIF

         IF !lPrikazDatumDokumentaIValutiranje .AND. !fPrviProlaz
            // bilo je stavki
            ? M
            ? "UKUPNO:"
            @ PRow(), nCol1 SAY nUDug PICTURE picBHD
            @ PRow(), PCol() + 1 SAY nUPot PICTURE picBHD
            @ PRow(), PCol() + 1 SAY nUDug - nUPot PICTURE picBHD
            IF fin_dvovalutno()
               @ PRow(), PCol() + 1 SAY nUDug2 PICTURE picdem
               @ PRow(), PCol() + 1 SAY nUPot2 PICTURE picdem
               @ PRow(), PCol() + 1 SAY nUDug2 - nUPot2 PICTURE picdem
            ENDIF
            ? m
         ENDIF
      ENDIF

      IF lBezPitanjaPartnerKonto
         // idu svi
      ELSEIF lUnesiPodatke // iz menija
         IF ( !fveci .AND. idpartner = cSvi ) .OR. fVeci
            IF !lPrikazDatumDokumentaIValutiranje .AND. !fPrviProlaz
               ? ;  ? ; ?
            ENDIF
         ELSE
            EXIT
         ENDIF
      ELSE
         IF cSvi <> "D"
            EXIT
         ELSE
            IF !lPrikazDatumDokumentaIValutiranje .AND. !fPrviProlaz
               ? ;  ? ; ?
            ENDIF
         ENDIF
      ENDIF // lUnesiPodatke
   ENDDO

   IF !lBezPitanjaPartnerKonto .AND. lPrikazDatumDokumentaIValutiranje   // ako je EXCLUSIVE, sada tek stampaj
      SELECT POM
      GO TOP
      DO WHILE !Eof()
         fPrviProlaz := .T.
         cIdPartner := IDPARTNER
         nUDug := nUPot := nUDug2 := nUPot2 := 0
         DO WHILE !Eof() .AND. cIdPartner == IdPartner
            IF PRow() > 52 + dodatni_redovi_po_stranici()
              FF
              fin_zagl_ostav_grupisano_po_br_veze( cIdFirma, cIdKonto, cIdPartner, .T., lPrikazDatumDokumentaIValutiranje )
              fPrviProlaz := .F.
            ENDIF
            IF fPrviProlaz
               fin_zagl_ostav_grupisano_po_br_veze( cIdFirma, cIdKonto, cIdPartner, NIL, lPrikazDatumDokumentaIValutiranje )
               fPrviProlaz := .F.
            ENDIF
            SELECT POM
            ? datdok, datval, datzpr, PadR( brdok, 10 )
            nCol1 := PCol() + 1
            ?? " "
            ?? Transform( dug, picbhd ), Transform( pot, picbhd ), Transform( dug - pot, picbhd )
            IF fin_dvovalutno()
               ?? " " + Transform( dug2, picdem ), Transform( pot2, picdem ), Transform( dug2 - pot2, picdem )
            ENDIF
            ?? "  " + otvst
            nUDug += Dug; nUPot += Pot
            nUDug2 += Dug2; nUPot2 += Pot2
            SKIP 1
         ENDDO
         IF PRow() > 58 + dodatni_redovi_po_stranici()
           FF
           fin_zagl_ostav_grupisano_po_br_veze( cIdFirma, cIdKonto, cIdPartner, .T., lPrikazDatumDokumentaIValutiranje )
         ENDIF
         SELECT POM
         IF !fPrviProlaz  // bilo je stavki
            ? M
            ? "UKUPNO:"
            @ PRow(), nCol1 SAY nUDug PICTURE picBHD
            @ PRow(), PCol() + 1 SAY nUPot PICTURE picBHD
            @ PRow(), PCol() + 1 SAY nUDug - nUPot PICTURE picBHD
            IF fin_dvovalutno()
               @ PRow(), PCol() + 1 SAY nUDug2 PICTURE picdem
               @ PRow(), PCol() + 1 SAY nUPot2 PICTURE picdem
               @ PRow(), PCol() + 1 SAY nUDug2 - nUPot2 PICTURE picdem
            ENDIF
            ? m
         ENDIF
         ? ; ? ; ?
      ENDDO
   ENDIF

   IF lBezPitanjaPartnerKonto
      RETURN ( NIL )
   ENDIF

   FF

   end_print()

   SELECT ( F_POM )
   USE
   SELECT SUBAN
   USE

   /*
   IF lUnesiPodatke
      //CLOSERET
      SELECT SUBAN
      USE
   ENDIF
      RETURN ( NIL )
   ENDIF
   */

   RETURN .T.


FUNCTION fin_create_pom_table( lBezPitanjaPartnerKonto, nParLen )

   LOCAL i
   LOCAL nPartLen
   LOCAL _alias := "POM"
   LOCAL _ime_dbf := my_home() + my_dbf_prefix() + "pom"
   LOCAL aDbf, aGod

   IF lBezPitanjaPartnerKonto == NIL
      lBezPitanjaPartnerKonto := .F.
   ENDIF

   SELECT ( F_POM )
   USE

   IF nParLen == nil
      nParLen := 6
   ENDIF

   FErase( _ime_dbf + ".dbf" )
   FErase( _ime_dbf + ".cdx" )

   aDbf := {}
   AAdd( aDBf, { 'IDPARTNER', 'C',  nParLen,  0 } )
   AAdd( aDBf, { 'DATDOK', 'D',  8,  0 } )
   AAdd( aDBf, { 'DATVAL', 'D',  8,  0 } )
   AAdd( aDBf, { 'BRDOK', 'C', 10,  0 } )
   AAdd( aDBf, { 'DUG', 'N', 17,  2 } )
   AAdd( aDBf, { 'POT', 'N', 17,  2 } )
   AAdd( aDBf, { 'DUG2', 'N', 15,  2 } )
   AAdd( aDBf, { 'POT2', 'N', 15,  2 } )
   AAdd( aDBf, { 'OTVST', 'C',  1,  0 } )
   AAdd( aDBf, { 'DATZPR', 'D',  8,  0 } )

   IF lBezPitanjaPartnerKonto
      FOR i := 1 TO Len( aGod )
         AAdd( aDBf, { 'GOD' + aGod[ i, 1 ], 'N', 15,  2 } )
      NEXT
      AAdd( aDBf, { 'GOD' + Str( Val( aGod[ i - 1, 1 ] ) - 1, 4 ), 'N', 15,  2 } )
      AAdd( aDBf, { 'GOD' + Str( Val( aGod[ i - 1, 1 ] ) - 2, 4 ), 'N', 15,  2 } )
   ENDIF

   dbCreate( _ime_dbf + ".dbf", aDbf )
   USE

   SELECT ( F_POM )
   my_use_temp( _alias, _ime_dbf, .F., .T. )

   INDEX ON ( IDPARTNER + DToS( DATDOK ) + DToS( iif( Empty( DATVAL ), DATDOK, DATVAL ) ) + BRDOK ) TAG "1"

   SET ORDER TO TAG "1"
   GO TOP

   RETURN .T.






FUNCTION fin_zagl_ostav_grupisano_po_br_veze( cIdFirma, cIdKonto, cIdPartner, fStrana, lPrikazDatumDokumentaIValutiranje )

   ?
   IF fin_dvovalutno()
      IF lPrikazDatumDokumentaIValutiranje
         P_COND
      ELSE
         F12CPI
      ENDIF
   ELSE
      F10CPI
   ENDIF
   IF fStrana == NIL
      fStrana := .F.
   ENDIF

   IF nStr = 0
      fStrana := .T.
   ENDIF

   ?? "FIN.P: OTV.STAVKE - PREGLED (GRUPISANO PO BROJEVIMA VEZE)  NA DAN "; ?? Date()
   IF fStrana
      @ PRow(), 110 SAY "Str:" + Str( ++nStr, 3 )
   ENDIF

   select_o_partner( cIdFirma )
   ? "FIRMA:", cIdFirma, "-", self_organizacija_naziv()

   select_o_konto( cIdKonto )
   ? "KONTO  :", cIdKonto, field->naz

   select_o_partner( cIdPartner )
   ? "PARTNER:", cIdPartner, Trim( partn->naz ), " ", Trim( partn->naz2 ), " ", Trim( partn->mjesto )

   SELECT suban
   ? M
   ?
   IF lPrikazDatumDokumentaIValutiranje
      ?? "Dat.dok.*Dat.val.*Dat.ZPR.* "
   ELSE
      ?? "*"
   ENDIF
   IF fin_dvovalutno()
      ?? "  BrDok   *   dug " + valuta_domaca_skraceni_naziv() + "  *   pot " + valuta_domaca_skraceni_naziv() + "   *  saldo  " + valuta_domaca_skraceni_naziv() + " * dug " + ValPomocna() + " * pot " + ValPomocna() + " *saldo " + ValPomocna() + "*O*"
   ELSE
      ?? "  BrDok   *   dug " + valuta_domaca_skraceni_naziv() + "  *   pot " + valuta_domaca_skraceni_naziv() + "   *  saldo  " + valuta_domaca_skraceni_naziv() + " *O*"
   ENDIF
   ? M

   SELECT SUBAN

   RETURN .T.




FUNCTION fin_otv_stavke_stampa_za_broj_veze( cIdfirma, cIdkonto, cIdPartner, cBrDok )

   LOCAL nCol1 := 35
   LOCAL nStr
   LOCAL bZagl := {|| fin_zagl_otv_st_za_broj_veze( cIdFirma, cIdKonto, cIdPartner, cBrDok, nStr ) }

   cDokument := Space( 8 )
   picBHD := FormPicL( gPicBHD, 13 )
   picDEM := FormPicL( pic_iznos_eur(), 10 )
   // IF fin_dvovalutno()
   // M := "-------- -------- " + "------- ---- -- ------------- ------------- ------------- ---------- ---------- ---------- --"
   // ELSE
   // M := "-------- -------- " + "------- ---- -- ------------- ------------- ------------- --"
   M := "-------- -------- -- -------- ----- ---------------- ------------- ------------- --"

   // ENDIF

   nStr := 0

   START PRINT RET


/*
   IF ValType( aPPos[ 1 ] ) = "C"
      PRIVATE cIdPartner := aPPos[ 1 ]
   ELSE
      PRIVATE cIdPartner := Eval( TB:getColumn( aPPos[ 1 ] ):Block )
   ENDIF
   IF ValType( aPPos[ 2 ] ) = "C"
      PRIVATE cBrDok := aPPos[ 2 ]
   ELSE
      PRIVATE cBrDok := Eval( TB:getColumn( aPPos[ 2 ] ):Block )
   ENDIF
*/

   nUkDugBHD := nUkPotBHD := 0
   // SELECT suban; SET ORDER TO TAG "3"
   // SEEK cidfirma + cidkonto + cidpartner + cBrDok

   find_suban_by_konto_partner( cIdfirma, cIdkonto, cIdpartner, cBrDok, "IdFirma,IdKonto,IdPartner,datdok,brdok" )


   nDug2 := nPot2 := 0
   nDug := nPot := 0

   Eval( bZagl )

   DO WHILE !Eof() .AND. idfirma == cIdfirma .AND. cIdKonto == IdKonto .AND. cIdPartner == IdPartner .AND. brdok == cBrDok

      NovaStrana( bZagl )
      ? datdok, datval, idvn, brnal, Str( rbr, 5, 0 ), idtipdok
      nCol1 := PCol() + 1
      IF D_P == "1"
         nDug += IznosBHD
         nDug2 += IznosDEM
         @ PRow(), PCol() + 1 SAY iznosbhd PICT picbhd
         @ PRow(), PCol() + 1 SAY Space( Len( picbhd ) )
         @ PRow(), PCol() + 1  SAY nDug - nPot PICT picbhd
         IF fin_dvovalutno()
            @ PRow(), PCol() + 1 SAY iznosdem PICT picdem
            @ PRow(), PCol() + 1 SAY Space( Len( picdem ) )
            @ PRow(), PCol() + 1  SAY nDug2 - nPot2 PICT picdem
         ENDIF
      ELSE
         nPot += IznosBHD
         nPot2 += IznosDEM
         @ PRow(), PCol() + 1 SAY Space( Len( picbhd ) )
         @ PRow(), PCol() + 1 SAY iznosbhd PICT picbhd
         @ PRow(), PCol() + 1  SAY nDug - nPot  PICT picbhd
         IF fin_dvovalutno()
            @ PRow(), PCol() + 1 SAY Space( Len( picdem ) )
            @ PRow(), PCol() + 1 SAY iznosdem PICT picdem
            @ PRow(), PCol() + 1  SAY nDug2 - nPot2  PICT picdem
         ENDIF
      ENDIF
      @ PRow(), PCol() + 2  SAY OtvSt
      SKIP
   ENDDO // partner

   NovaStrana( bZagl )

   ? m
   ? "UKUPNO:"
   @ PRow(), nCol1     SAY nDug PICTURE picBHD
   @ PRow(), PCol() + 1  SAY nPot PICTURE picBHD
   @ PRow(), PCol() + 1  SAY nDug - nPot PICTURE picBHD
   IF fin_dvovalutno()
      @ PRow(), PCol() + 1  SAY nDug2 PICTURE picdem
      @ PRow(), PCol() + 1  SAY nPot2 PICTURE picdem
      @ PRow(), PCol() + 1  SAY nDug2 - nPot2 PICTURE picdem
   ENDIF
   ? m

   FF
   end_print()

STATIC FUNCTION fin_zagl_otv_st_za_broj_veze( cIdFirma, cIdKonto, cIdPartner, cBrDok, nStr )

   ?
   IF fin_dvovalutno()
      P_COND
   ELSE
      F12CPI
   ENDIF
   ??U "FIN.P: KARTICA ZA ODREĐENI BROJ VEZE  NA DAN "; ?? Date()
   @ PRow(), 110 SAY "Str:" + Str( ++nStr, 3 )

   select_o_partner( cIdFirma )
   ? "FIRMA:", cIdFirma, partn->naz, partn->naz2

   select_o_konto( cIdKonto )
   ? "KONTO  :", cIdKonto, konto->naz

   select_o_partner( cIdPartner )
   ? "PARTNER:", cIdPartner, Trim( partn->naz ), " ", Trim( partn->naz2 ), " ", Trim( partn->mjesto )

   SELECT suban
   ? "BROJ VEZE:", cBrDok
   ? M
   // IF fin_dvovalutno()
   // ? "Dat.dok.*Dat.val." + "*NALOG * Rbr *TD*   dug " + valuta_domaca_skraceni_naziv() + "   *  pot " + valuta_domaca_skraceni_naziv() + "  *   saldo " + valuta_domaca_skraceni_naziv() + "*  dug " + ValPomocna() + "* pot " + ValPomocna() + " *saldo " + ValPomocna() + "* O"
   // ELSE
   ? "Dat.dok.*Dat.val.*VN* NALOG  * Rbr *      dug KM    *   pot KM    *   saldo KM  * O"
   // ENDIF
   ? M

   SELECT SUBAN

   RETURN .T.








FUNCTION fin_ostav_stampa_azuriranih_promjena()

   aKol := {}
   AAdd( aKol, { "Originalni",    {|| _obrdok }, .F., "C", 10,  0, 1, 1    } )
   AAdd( aKol, { "Br.Veze  ",    {|| "#" }, .F., "C", 10,  0, 2, 1    } )
   AAdd( aKol, { "Br.Veze",       {|| BrDok }, .F., "C", 10, 0, 1, 2  } )

   AAdd( aKol, { "Dat.Dok",       {|| DatDok }, .F., "D", 8, 0, 1, 3  } )
   AAdd( aKol, { "Duguje",    {|| Str( ( iif( D_P == "1", iznosbhd, 0 ) ), 18, 2 ) }, .F., "C", 18, 0, 1, 4  } )
   AAdd( aKol, { "Potrazuje",    {|| Str( ( iif( D_P == "2", iznosbhd, 0 ) ), 18, 2 ) }, .F., "C", 18, 0, 1, 5  } )
   AAdd( aKol, { "Nalog",    {|| idvn + "-" + brnal + "/" + Str( rbr, 5, 0 ) }, .F., "C", 20, 0, 1, 6  } )
   AAdd( aKol, { "Partner",     {|| IdPartner }, .F., "C", 10, 0, 1, 7  } )

   GO TOP
   fPromjene := .F.
   DO WHILE !Eof()
      IF _obrdok <> brdok
         fPromjene := .T.
         EXIT
      ENDIF
      SKIP
   ENDDO

   GO TOP
   IF !start_print()
      RETURN .F.
   ENDIF

   print_lista_2( aKol,,, 0,, , "Rezultati asistenta otvorenih stavki za: " + idkonto + "/" + idpartner + " na datum:" + DToC( Date() ) )

   end_print()

   RETURN .T.
