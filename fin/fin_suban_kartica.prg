/*
 * This file is part of the bring.out knowhow ERP, a free and open source
 * ERP software suite,
 * Copyright (c) 1994-2024 by bring.out d.o.o Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including knowhow ERP specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_knowhow.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */

#include "f18.ch"

MEMVAR m
MEMVAR gFinFunkFond, gFinRJ
MEMVAR cIdFirma, cIdKonto, fk1, fk2, fk3, fk4, cK1, cK2, cK3, cK4
MEMVAR nStr
MEMVAR gPicBHD, picDEM, picBHD, lOtvoreneStavke
MEMVAR dDatOd, dDatDo
MEMVAR cPrikazK1234, p_cValutaDom1Eur2Obje3, cKumulativniPrometBez1Sa2
MEMVAR cUslovUpperBrDok, cUslovIdKonto, cUslovIdPartner, cUslovNazivKonta
FIELD iznosbhd, iznosdem, d_p, otvst, idpartner, idfirma, idkonto, datdok, datval, brdok, brnal,  idrj, funk, fond, Rbr

STATIC s_cXlsxName := NIL
STATIC s_pWorkBook, s_pWorkSheet, s_nWorkSheetRow
STATIC s_pMoneyFormat, s_pDateFormat
STATIC s_nOpisRptLength := 40
STATIC s_cPortretDN := "D"
STATIC s_lSifkPRMJ := NIL

STATIC s_cIdPartnerPredhodni := "XX", s_cProdajnoMjestoPredhodno := "XX"

FUNCTION fin_suban_kartica( lOtvst ) // param lOtvst  - .t. otvorene stavke

   LOCAL cBrza := "D"
   LOCAL nC1 := 37
   LOCAL nCOpis := 0
   LOCAL cOpis := ""
   LOCAL cBoxName
   LOCAL dPom := CToD( "" )
   LOCAL cOpcine := Space( 20 )
   LOCAL cExpXlsx
   LOCAL aExpFields
   LOCAL cIdVn
   LOCAL cBrNal
   LOCAL s_cBrVeze
   LOCAL nRbr
   LOCAL dDatVal
   LOCAL dDatDok
   LOCAL s_cOpis
   LOCAL cPartnerNaziv
   LOCAL cKontoNaziv
   LOCAL nDuguje
   LOCAL nPotrazuje
   LOCAL hFinParams := fin_params()
   LOCAL hFaktParams := fakt_params()
   LOCAL cLibreOffice := "N"
   LOCAL nX := 2
   LOCAL bZagl  :=  {|| zagl_suban_kartica( cBrza ) }
   LOCAL lKarticaNovaStrana := .F.
   LOCAL nTmp
   LOCAL cOrderBy
   LOCAL lPrviProlaz
   LOCAL cIdVnIzvod := "61"
   LOCAL cSpojiDP := "2" // spoji potrazuje - uplate = 2, spoji dugovanja = 1
   LOCAL lSpojiUplate := .F., nSpojeno := 0
   LOCAL pRegex, aMatch
   LOCAL oPDF, xPrintOpt
   LOCAL bEvalSubanKartFirma, bEvalSubanKartKonto, bEvalSubanKartPartner
   LOCAL nPDugBHD, nPPotBHD, nPDugDEM, nPPotDEM   // prethodni promet
   LOCAL nDugBHD, nPotBHD, nDugDEM, nPotDEM
   LOCAL nZDugBHD, nZPotBHD, nZDugDEM, nZPotDEM // zatvorene stavke
   LOCAL cPredhodniPromet // 1 - bez, 2 - sa
   LOCAL hRec
   LOCAL cFilterBrDok := ""
   LOCAL GetList := {}
   LOCAL cNaslov
   LOCAL cRasclaniti := "N"
   LOCAL cUslovIdVn := Space( 40 )
   LOCAL cIdRj, cFunk, cFond
   LOCAL cFilter
   LOCAL cIdPartner
   LOCAL cRasclan
   LOCAL nCnt
   LOCAL nC7 := 0
   LOCAL nKonD, nKonP, nKonP2, nKonD2
   LOCAL cFilterNazivKonta, cFilterIdKonto, cFilterIdPartner, cFilterIdVn
   LOCAL nSviD, nSviP, nSviD2, nSviP2
   LOCAL cUplate

   PRIVATE fK1 := hFinParams[ "fin_k1" ]
   PRIVATE fK2 := hFinParams[ "fin_k2" ]
   PRIVATE fK3 := hFinParams[ "fin_k3" ]
   PRIVATE fK4 := hFinParams[ "fin_k4" ]

   PRIVATE cIdFirma := self_organizacija_id()
   PRIVATE lOtvoreneStavke := lOtvSt
  // PRIVATE c1K1Z := "N"
   PRIVATE picBHD := FormPicL( gPicBHD, 16 )
   PRIVATE picDEM := FormPicL( pic_iznos_eur(), 12 )

   PRIVATE cPrikazK1234 := "2" // default prikazati datval

   p_cValutaDom1Eur2Obje3 := "1"
   dDatOd := CToD( "" )
   dDatDo := CToD( "" )
   cKumulativniPrometBez1Sa2 := "1"
   cPredhodniPromet := "1"
   cUslovIdKonto := ""
   cUslovIdPartner := ""
   cUslovUpperBrDok := Space( 40 )
   cUslovNazivKonta := Space( 40 )

   IF PCount() == 0
      lOtvoreneStavke := .F.
   ENDIF

   cKumulativniPrometBez1Sa2 := fetch_metric( "fin_kart_kumul", my_user(), cKumulativniPrometBez1Sa2 )
   cPredhodniPromet := fetch_metric( "fin_kart_predhodno_stanje", my_user(), cPredhodniPromet )
   cBrza := fetch_metric( "fin_kart_brza", my_user(), cBrza )
   cIdFirma := fetch_metric( "fin_kart_org_id", my_user(), cIdFirma )
   cUslovIdKonto := fetch_metric( "fin_kart_konto", my_user(), cUslovIdKonto )
   cUslovIdPartner := fetch_metric( "fin_kart_partner", my_user(), cUslovIdPartner )
   cUslovUpperBrDok := Padr(fetch_metric( "fin_kart_broj_dokumenta", my_user(), cUslovUpperBrDok ), 40)
   dDatOd := fetch_metric( "fin_kart_datum_od", my_user(), dDatOd )
   dDatDo := fetch_metric( "fin_kart_datum_do", my_user(), dDatDo )
   p_cValutaDom1Eur2Obje3 := fetch_metric( "fin_kart_valuta", my_user(), p_cValutaDom1Eur2Obje3 )
   //c1K1Z := fetch_metric( "fin_kart_kz", my_user(), c1K1Z )
   cPrikazK1234 := fetch_metric( "fin_kart_k14", my_user(), cPrikazK1234 )
   cIdFirma := self_organizacija_id()
   s_cPortretDN := fetch_metric( "fin_kart_suban_portret", my_user(), "N")
   cExpXlsx := fetch_metric( "fin_kart_suban_xlsx", my_user(), "N")

   cK1 := "9"
   cK2 := "9"
   cK3 := "99"
   cK4 := "99"
   cIdRj := Replicate( "9", FIELD_LEN_FIN_RJ_ID )
   cFunk := "99999"
   cFond := "9999"

   // Partner - prikaz prodajnog mjesta
   IF use_sql_sifk( "PARTN", "PRMJ")
      s_lSifkPRMJ := .T.
   else
      s_lSifkPRMJ := .F.
   ENDIF
   
   DO WHILE .T.
      GetList := {}
      nX := 2
      cBoxName := "SUBANALITIČKA KARTICA"
      IF lOtvoreneStavke
         cBoxName += " - OTVORENE STAVKE"
      ENDIF

      Box( "#" + cBoxName, 25, 65 )

      set_cursor_on()
      @ box_x_koord() + nX, box_y_koord() + 2 SAY "LibreOffice kartica (D/N) ?" GET cLibreOffice PICT "@!"
      READ

      IF cLibreOffice == "D"
         BoxC()
         RETURN fin_suban_kartica_sql( lOtvSt )
      ENDIF

      kartica_otvori_tabele()

      ++nX
      @ box_x_koord() + ( ++nX ), box_y_koord() + 2 SAY "BEZ/SA kumulativnim prometom  (1/2):" GET cKumulativniPrometBez1Sa2
      @ box_x_koord() + ( ++nX ), box_y_koord() + 2 SAY "BEZ/SA prethodnim prometom (1/2):" GET cPredhodniPromet
      @ box_x_koord() + ( ++nX ), box_y_koord() + 2 SAY "Brza kartica (D/N)" GET cBrza PICT "@!" VALID cBrza $ "DN"
      READ

         
      @ box_x_koord() + ( ++nX ), box_y_koord() + 2 SAY "Firma "
      ?? self_organizacija_id(), "-", self_organizacija_naziv()

      IF cBrza == "D"
         cUslovIdKonto := PadR( cUslovIdKonto, 7 )
         cUslovIdPartner := PadR( cUslovIdPartner, 6 )
         @ box_x_koord() + ( ++nX ), box_y_koord() + 2 SAY "Konto  " GET cUslovIdKonto  VALID p_konto( @cUslovIdKonto )
         @ box_x_koord() + ( ++nX ), box_y_koord() + 2 SAY "Partner" GET cUslovIdPartner VALID Empty( cUslovIdPartner ) .OR. RTrim( cUslovIdPartner ) == ";" .OR. p_partner( @cUslovIdPartner ) PICT "@!"
      ELSE
         cUslovIdKonto := PadR( cUslovIdKonto, 100 )
         cUslovIdPartner := PadR( cUslovIdPartner, 100 )
         @ box_x_koord() + ( ++nX ), box_y_koord() + 2 SAY "Konto  " GET cUslovIdKonto  PICTURE "@!S50"
         @ box_x_koord() + ( ++nX ), box_y_koord() + 2 SAY "Partner" GET cUslovIdPartner PICTURE "@!S50"
      ENDIF

      @ box_x_koord() + ( ++nX ), box_y_koord() + 2 SAY "Datum dokumenta od:" GET dDatod
      @ box_x_koord() + nX, Col() + 2 SAY "do" GET dDatDo   VALID dDatOd <= dDatDo
      @ box_x_koord() + ( ++nX ), box_y_koord() + 2 SAY "Uslov za vrstu naloga (prazno-sve)" GET cUslovIdVn PICT "@!S20"

      IF fin_dvovalutno()
         @ box_x_koord() + ( ++nX ), box_y_koord() + 2 SAY "Kartica za " + AllTrim( valuta_domaca_skraceni_naziv() ) + "/" + AllTrim( ValPomocna() ) + "/" + AllTrim( valuta_domaca_skraceni_naziv() ) + "-" + AllTrim( ValPomocna() ) + " (1/2/3)"  GET p_cValutaDom1Eur2Obje3 VALID p_cValutaDom1Eur2Obje3 $ "123"
      ELSE
         p_cValutaDom1Eur2Obje3 := "1"
      ENDIF

      @ box_x_koord() + ( ++nX ), box_y_koord() + 2 SAY8 "Prikaz  K1-K4 (1); Dat.Valute (2); oboje (3)" + iif( hFinParams[ "fin_tip_dokumenta" ], "; ništa (4)", "" )  GET cPrikazK1234 VALID cPrikazK1234 $ "123" + iif( hFinParams[ "fin_tip_dokumenta" ], "4", "" )
      cRasclaniti := "N"

      IF gFinRJ == "D"
         @ box_x_koord() + ( ++nX ), box_y_koord() + 2 SAY8 "Raščlaniti po RJ/FUNK/FOND; "  GET cRasclaniti PICT "@!" VALID cRasclaniti $ "DN"
      ENDIF

      fin_get_k1_k4_funk_fond( @GetList, 14 )
      

      @ Row() + 1, box_y_koord() + 2 SAY8 "Uslov za broj veze: " GET cUslovUpperBrDok PICT "@!S30"
      @ Row() + 1, box_y_koord() + 2 SAY8 "(prazno-svi; 61_SP_2-spoji uplate za naloge tipa 61;"
      @ Row() + 1, box_y_koord() + 2 SAY8 " **_SP_2 - kupci spojiti uplate za sve vrste naloga) "
      //@ Row() + 1, box_y_koord() + 2 SAY8 " **_SP_1 - dobavljači spojiti plaćanja za sve vrste naloga)"

      IF cBrza <> "D"
         @ Row() + 1, box_y_koord() + 2 SAY8 "Uslov za naziv konta (prazno-svi) " GET cUslovNazivKonta PICT "@!S20"
      ENDIF
      @ Row() + 1, box_y_koord() + 2 SAY8 "Općina (prazno-sve):" GET cOpcine

      @ Row() + 2, box_y_koord() + 2 SAY8 "Portret prikaz D/N? " GET s_cPortretDN VALID s_cPortretDN $ "DN" PICTURE "@!"

      @ Row() + 1, box_y_koord() + 2 SAY "Export u XLSX (D/N)?"  GET cExpXlsx PICT "@!" VALID cExpXlsx $ "DN"

      READ
      ESC_BCR

      IF cExpXlsx == "D"
         s_cXlsxName := my_home_root() + "fin_suban_kartica.xlsx"
      ENDIF

      pRegex := hb_regexComp( "(..)_SP_(\d)" )
      aMatch := hb_regex( pRegex, cUslovUpperBrDok )
      IF Len( aMatch ) > 0 // aMatch[1]="61_SP_2", aMatch[2]=61, aMatch[3]=2
         cIdVnIzvod :=  aMatch[ 2 ]
         cSpojiDP := aMatch[ 3 ]
   
         lSpojiUplate := .T.
         IF LEFT( cUslovIdKonto, 2 ) == "43" .AND. cSpojiDP == "2" // kartica dobavljaca, ignorisi spajanje potrazne strane
            lSpojiUplate := .F.
         ENDIF
      ENDIF

      IF !( cPrikazK1234 $ "123" )
         cPrikazK1234 := "3"
      ENDIF

      IF p_cValutaDom1Eur2Obje3 == "3"
         nC1 := 59 + iif( hFinParams[ "fin_tip_dokumenta" ], 17, 0 )
      ELSE
         nC1 := 63 + iif( hFinParams[ "fin_tip_dokumenta" ], 17, 0 )
      ENDIF

      IF p_cValutaDom1Eur2Obje3 == "3"
         cKumulativniPrometBez1Sa2 := "1"
      ENDIF

      cFilterIdVn := parsiraj( cUslovIdVn, "IDVN", "C" )
      cFilterNazivKonta := Parsiraj( cUslovNazivKonta, "UPPER(naz)", "C" )

      BoxC()

      IF cBrza == "D"
         IF cFilterIdVn <> NIL
            EXIT
         ENDIF
      ELSE
         cUslovIdKonto := Trim( cUslovIdKonto )
         cUslovIdPartner := Trim( cUslovIdPartner )
         cFilterIdKonto := parsiraj( cUslovIdKonto, "IdKonto", "C" )
         cFilterIdPartner := parsiraj( cUslovIdPartner, "IdPartner", "C" )
         IF cFilterIdKonto <> NIL .AND. cFilterIdPartner <> NIL .AND. cFilterIdVn <> NIL
            EXIT
         ENDIF
      ENDIF

   ENDDO
   

   set_metric( "fin_kart_kumul", my_user(), cKumulativniPrometBez1Sa2 )
   set_metric( "fin_kart_predhodno_stanje", my_user(), cPredhodniPromet )
   set_metric( "fin_kart_brza", my_user(), cBrza )
   set_metric( "fin_kart_org_id", my_user(), cIdFirma )
   set_metric( "fin_kart_konto", my_user(), cUslovIdKonto )
   set_metric( "fin_kart_partner", my_user(), cUslovIdPartner )
   set_metric( "fin_kart_broj_dokumenta", my_user(), cUslovUpperBrDok )
   set_metric( "fin_kart_datum_od", my_user(), dDatOd )
   set_metric( "fin_kart_datum_do", my_user(), dDatDo )
   set_metric( "fin_kart_valuta", my_user(), p_cValutaDom1Eur2Obje3 )
   set_metric( "fin_kart_k14", my_user(), cPrikazK1234 )
   set_metric( "fin_kart_suban_portret", my_user(), s_cPortretDN)
   set_metric( "fin_kart_suban_xlsx", my_user(), cExpXlsx)

   IF !lSpojiUplate
      IF ("_SP_" $ cUslovUpperBrDok) // ignorisi _SP_2;
         cUslovUpperBrDok := ""
      ENDIF
      cFilterBrDok := Parsiraj( cUslovUpperBrDok, "UPPER(BRDOK)", "C" )
   ELSE
      cUslovUpperBrDok := ""
   ENDIF

   cIdFirma := Trim( cIdFirma )

   IF s_cPortretDN == "D"
      s_nOpisRptLength := 20
   ELSE
      s_nOpisRptLength := 40
   ENDIF

   IF p_cValutaDom1Eur2Obje3 == "3"
      IF hFinParams[ "fin_tip_dokumenta" ] .AND. cPrikazK1234 == "4"
         m := "--- -------- ---- ---------------- ---------- -------- " + Replicate( "-", s_nOpisRptLength ) + " ---------------- ---------------- --------------- ------------- ------------ ------------"
      ELSEIF hFinParams[ "fin_tip_dokumenta" ]
         m := "--- -------- ---- ---------------- ---------- -------- -------- " + Replicate( "-", s_nOpisRptLength ) + " ---------------- ---------------- --------------- ------------- ------------ ------------"
      ELSE
         m := "--- -------- ---- ---------- -------- -------- " + Replicate( "-", s_nOpisRptLength ) + " ---------------- ---------------- --------------- ------------- ------------ ------------"
      ENDIF

   ELSEIF cKumulativniPrometBez1Sa2 == "1"

      IF hFinParams[ "fin_tip_dokumenta" ]
         m := "--- -------- ---- ---------------- ---------- -------- -------- " + Replicate( "-", s_nOpisRptLength ) + " ---------------- ----------------- ---------------"
      ELSE
         m := "--- -------- ---- ---------- -------- -------- " + Replicate( "-", s_nOpisRptLength ) + " ---------------- ----------------- ---------------"
      ENDIF

   ELSE

      IF hFinParams[ "fin_tip_dokumenta" ] .AND. cPrikazK1234 == "4"
         m := "--- -------- ---- ---------------- ---------- -------- " + Replicate( "-", s_nOpisRptLength ) + " ---------------- ----------------- ---------------- ----------------- ---------------"
      ELSEIF hFinParams[ "fin_tip_dokumenta" ]
         m := "--- -------- ---- ---------------- ---------- -------- -------- " + Replicate( "-", s_nOpisRptLength ) + " ---------------- ----------------- ---------------- ----------------- ---------------"
      ELSE
         m := "--- -------- ---- ---------- -------- -------- " + Replicate( "-", s_nOpisRptLength ) + " ---------------- ----------------- ---------------- ----------------- ---------------"
      ENDIF

   ENDIF

   //lVrsteP := .F.

   cOrderBy := "IdFirma,IdKonto,IdPartner,datdok,idvn,brnal,otvst,d_p,brdok"
   MsgO( "Preuzimanje podataka sa SQL servera ..." )
   IF cBrza == "D"
      IF RTrim( cUslovIdPartner ) == ";" // ne kontam kada se ovo desava
         IF cPredhodniPromet == "2" // sa predhodnim prometom
            find_suban_by_konto_partner( cIdFirma, cUslovIdKonto, NIL, NIL, cOrderBy )
         ELSE
            find_suban_by_konto_partner_za_period( cIdFirma, cUslovIdKonto, NIL, dDatOd, dDatDo, NIL, cOrderBy )
         ENDIF  
         
      ELSE
         IF cPredhodniPromet == "2"
            find_suban_by_konto_partner( cIdFirma, cUslovIdKonto, cUslovIdPartner, NIL, cOrderBy )
         ELSE
            find_suban_by_konto_partner_za_period( cIdFirma, cUslovIdKonto, cUslovIdPartner, dDatOd, dDatDo, NIL, cOrderBy )
         ENDIF
      ENDIF
   ELSE
      IF cPredhodniPromet == "2" // sa predhodnim prometom
         o_sql_suban_kto_partner( cIdFirma )
      ELSE
         o_sql_suban_kto_partner_za_period( cIdFirma, dDatOd, dDatDo )
      ENDIF
   ENDIF
   MsgC()

   IF !Used()
      MsgBeep( "ERROR SQL podaci ?! " + ;
         "#konto=" + AllTrim( cUslovIdKonto ) + "#partner=" + AllTrim( cUslovIdPartner ) )
      RETURN .F.
   ENDIF
   GO TOP

   //IF hFaktParams[ "fakt_vrste_placanja" ]
   //   lVrsteP := .T.
   //   o_vrstep()
   //ENDIF

   SELECT SUBAN
   info_bar("sub_kart", "suban_rec: " + AllTrim(Str(reccount())))
   fin_cisti_polja_k4k4_funk_fond( .T., @cIdRj, @cK1, @cK2, @cK3, @cK4, @cFunk, @cFond )

   cFilter := ".t." + iif( !Empty( cUslovIdVn ), ".and." + cFilterIdVn, "" ) + ;
      iif( cBrza == "N", ".and." + cFilterIdKonto + ".and." + cFilterIdPartner, "" ) + ;
      iif( Empty( dDatOd ) .OR. cPredhodniPromet == "2", "", ".and.DATDOK>=" + dbf_quote( dDatOd ) ) + ;
      iif( Empty( dDatDo ), "", ".and.DATDOK<=" + dbf_quote( dDatDo ) ) + ;
      iif( fk1 .AND. Len( ck1 ) <> 0, ".and.k1=" + dbf_quote( ck1 ), "" ) + ;
      iif( fk2 .AND. Len( ck2 ) <> 0, ".and.k2=" + dbf_quote( ck2 ), "" ) + ;
      iif( fk3 .AND. Len( ck3 ) <> 0, ".and.k3=ck3", "" ) + ;
      iif( fk4 .AND. Len( ck4 ) <> 0, ".and.k4=" + dbf_quote( ck4 ), "" ) + ;
      iif( gFinRj == "D" .AND. Len( cIdrj ) <> 0, ".and.idrj=" + dbf_quote( cIdRJ ), "" ) + ;
      iif( gFinFunkFond == "D" .AND. Len( cFunk ) <> 0, ".and.funk=" + dbf_quote( cFunk ), "" ) + ;
      iif( gFinFunkFond == "D" .AND. Len( cFond ) <> 0, ".and.fond=" + dbf_quote( cFond ), "" ) // + ;

   IF !lSpojiUplate .AND. !Empty( cUslovUpperBrDok )
      cFilter += ( ".and." + cFilterBrDok )
   ENDIF

   cFilter := StrTran( cFilter, ".t..and.", "" )
   IF Len( cIdFirma ) < 2  // .OR. gDugiUslovFirmaRJFinSpecif == "D"
      SET INDEX TO
      IF cRasclaniti == "D"
         INDEX ON idkonto + idpartner + idrj + funk + fond TO SUBSUB FOR &cFilter
      ELSEIF cBrza == "D" .AND. RTrim( cUslovIdPartner ) == ";"
         INDEX ON IdKonto + DToS( DatDok ) + idpartner TO SUBSUB FOR &cFilter
      ELSE
         INDEX ON IdKonto + IdPartner + DToS( DatDok ) + BrNal + Str( RBr, 5, 0 ) TO SUBSUB FOR &cFilter
      ENDIF
   ELSE
      IF cRasclaniti == "D"
         SET INDEX TO
         INDEX ON idfirma + idkonto + idpartner + idrj + funk + fond TO SUBSUB FOR &cFilter
      ELSE
         IF cFilter == ".t."
            SET FILTER TO
         ELSE
            SET FILTER TO &cFilter
         ENDIF
      ENDIF
   ENDIF

   GO TOP

   EOF RET
   nStr := 0
   nSviD := 0
   nSviP := 0
   nSviD2 := 0
   nSviP2 := 0

   oPDF := PDFClass():New()
   xPrintOpt := hb_Hash()
   xPrintOpt[ "tip" ] := "PDF"
   
   xPrintOpt[ "layout" ] := "landscape"
   IF cKumulativniPrometBez1Sa2 == "2" .AND. p_cValutaDom1Eur2Obje3 == "3" // sa kumulativnim prometom
      xPrintOpt[ "font_size" ] := 7.5
   ELSE
      xPrintOpt[ "font_size" ] := 9.5
      xPrintOpt[ "layout" ] := IIF( s_cPortretDN == "D", "portrait", "landscape" )
   ENDIF
   xPrintOpt[ "opdf" ] := oPDF
   xPrintOpt[ "left_space" ] := 0

   cNaslov := "SUBANALITIČKA KARTICA [" + ;
       AllTrim( iif( p_cValutaDom1Eur2Obje3 == "1", valuta_domaca_skraceni_naziv(), iif( p_cValutaDom1Eur2Obje3 == "2", ValPomocna(), valuta_domaca_skraceni_naziv() + "-" + ValPomocna() ) )) +;
       "] za period " + DToC(dDatOd) + " - " + DToC(dDatDo) +;
       " na dan: " + DTOC( Date() )


   IF f18_start_print( NIL, xPrintOpt,  cNaslov ) == "X"
      RETURN .F.
   ENDIF

   nCnt := 0
   prikaz_k1_k4_rj()
   cIdKonto := field->IdKonto
   bEvalSubanKartFirma := {|| !Eof() .AND. field->IdFirma == cIdFirma }
   bEvalSubanKartKonto := {|| !Eof() .AND. cIdKonto == suban->IdKonto .AND. suban->IdFirma == cIdFirma }
   bEvalSubanKartPartner :=  {|| !Eof() .AND. cIdKonto == suban->IdKonto .AND. ( cIdPartner == suban->IdPartner ;
      .OR. ( cBrza == "D" .AND. RTrim( cUslovIdPartner ) == ";" ) ) .AND. RasclanRjFunkFond( cRasclaniti, cRasclan ) .AND. suban->IdFirma == cIdFirma }


   Eval( bZagl )
   // Nivo 0 - SVE
   DO WHILE Eval( bEvalSubanKartFirma )
      nKonD := 0
      nKonP := 0
      nKonD2 := 0
      nKonP2 := 0
      cIdKonto := IdKonto

      IF !Empty( cUslovNazivKonta )
         select_o_konto( cIdKonto )
         IF !( &( cFilterNazivKonta ) )
            SELECT suban
            SKIP 1
            LOOP
         ELSE
            SELECT suban
         ENDIF
      ENDIF

      // Nivo 1 - Konto
      DO WHILE Eval( bEvalSubanKartKonto )

         cKontoNaziv := ""
         cPartnerNaziv := ""
         nPDugBHD := 0
         nPPotBHD := 0
         nPDugDEM := 0
         nPPotDEM := 0  // prethodni promet
         nDugBHD := 0
         nPotBHD := 0
         nDugDEM := 0
         nPotDEM := 0
         nZDugBHD := 0 // zatvorene stavke
         nZPotBHD := 0
         nZDugDEM := 0
         nZPotDEM := 0
         cIdPartner := suban->IdPartner

         IF !Empty( cOpcine )
            select_o_partner( cIdPartner )
            IF !( Found() .AND. partn->id == cIdPartner .AND. AllTrim( partn->idops ) $ AllTrim( cOpcine ) )
               select suban
               SKIP
               LOOP
            ENDIF
         ENDIF

         IF cRasclaniti == "D"
            cRasclan := field->idrj + field->funk + field->fond
         ELSE
            cRasclan := ""
         ENDIF

         check_nova_strana( bZagl, oPdf, .F., 6 )
         ? m
         ? "KONTO:  "
         @ PRow(), PCol() + 1 SAY cIdKonto

         select_o_konto( cIdKonto )
         cKontoNaziv := field->naz
         @ PRow(), PCol() + 2 SAY cKontoNaziv
         ? "Partner: "
         @ PRow(), PCol() + 1 SAY iif( cBrza == "D" .AND. RTrim( cUslovIdPartner ) == ";", ":  SVI", cIdPartner )
         IF cRasclaniti == "D"
            select_o_rj( cRasclan )
            ? "        "
            @ PRow(), PCol() + 1 SAY Left( cRasclan, 6 ) + "/" + SubStr( cRasclan, 7, 5 ) + "/" + SubStr( cRasclan, 12 ) + " / " + get_rj_naz( Left( cRasclan, 6 ) )
            SELECT konto
         ENDIF

         IF !( cBrza == "D" .AND. RTrim( cUslovIdPartner ) == ";" )
            select_o_partner( cIdPartner )
            cPartnerNaziv := field->naz
            @ PRow(), PCol() + 1 SAY AllTrim( field->naz )
            @ PRow(), PCol() + 1 SAY AllTrim( field->naz2 )
            @ PRow(), PCol() + 1 SAY field->ZiroR
         ENDIF

         SELECT SUBAN

         check_nova_strana( bZagl, oPdf )
         //IF c1K1z != "D"
         ? m
         //ENDIF

         // NIVO 2 - Partner
         lPrviProlaz := .T.  // prvi prolaz
         DO WHILE Eval( bEvalSubanKartPartner )

            IF check_nova_strana( bZagl, oPdf, .F., 4, 0 )
               ? m
               ?U "KONTO: "
               @ PRow(), PCol() + 1 SAY cIdKonto
               select_o_konto( cIdKonto )
               @ PRow(), PCol() + 2 SAY konto->naz
               ?U "Partner: "
               @ PRow(), PCol() + 1 SAY iif( cBrza == "D" .AND. RTrim( cUslovIdPartner ) == ";", ":  SVI", cIdPartner )
               IF !( cBrza == "D" .AND. RTrim( cUslovIdPartner ) == ";" )
                  select_o_partner( cIdPartner )
                  @ PRow(), PCol() + 1 SAY AllTrim( partn->naz )
                  @ PRow(), PCol() + 1 SAY AllTrim( partn->naz2 )
                  @ PRow(), PCol() + 1 SAY AllTrim( partn->ZiroR )
               ENDIF
               ??U "  "
               @ PRow(), PCol() + 1 SAY Left( cRasclan, 6 ) + "/" + SubStr( cRasclan, 7, 5 ) + "/" + SubStr( cRasclan, 12 )
               SELECT SUBAN
               ? m
            ENDIF

            IF cPredhodniPromet == "2" .AND. lPrviProlaz
               lPrviProlaz := .F.

               DO WHILE  Eval( bEvalSubanKartPartner ) .AND. ( dDatOd > field->DatDok )

                  IF lOtvoreneStavke .AND. OtvSt == "9"
                     IF field->d_P == "1"
                        nZDugBHD += suban->iznosbhd
                        nZDugDEM += suban->iznosdem
                     ELSE
                        nZPotBHD += suban->iznosbhd
                        nZPotDEM += suban->iznosdem
                     ENDIF
                  ELSE
                     IF field->d_P == "1"
                        nPDugBHD += suban->iznosbhd
                        nPDugDEM += suban->iznosdem
                     ELSE
                        nPPotBHD += suban->iznosbhd
                        nPPotDEM += suban->iznosdem
                     ENDIF
                  ENDIF
                  SKIP
               ENDDO  // prethodni promet

               ? "PROMET DO "; ?? dDatOd
               IF p_cValutaDom1Eur2Obje3 == "3"
                  IF hFinParams[ "fin_tip_dokumenta" ]
                     @ PRow(), 83 + iif( cPrikazK1234 == "4", 8, 17 ) SAY ""
                  ELSE
                     @ PRow(), 83 SAY ""
                  ENDIF
               ELSE
                  IF hFinParams[ "fin_tip_dokumenta" ]
                     @ PRow(), 87 + iif( cPrikazK1234 == "4", 8, 17 ) SAY ""
                  ELSE
                     @ PRow(), 87 SAY ""
                  ENDIF
               ENDIF

               nC1 := PCol() + 1
               IF p_cValutaDom1Eur2Obje3 == "1"
                  @ PRow(), PCol() + 1 SAY nPDugBHD PICTURE picBHD
                  @ PRow(), PCol() + 1 SAY nPPotBHD PICTURE picBHD
                  nDugBHD += nPDugBHD
                  nPotBHD += nPPotBHD
               ELSEIF p_cValutaDom1Eur2Obje3 == "2"   // devize
                  @ PRow(), PCol() + 1 SAY nPDugDEM PICTURE picbhd
                  @ PRow(), PCol() + 1 SAY nPPotDEM PICTURE picbhd
                  nDugDEM += nPDugDEM
                  nPotDEM += nPPotDEM
               ELSEIF p_cValutaDom1Eur2Obje3 == "3"   // devize
                  @ PRow(), PCol() + 1 SAY nPDugBHD PICTURE picBHD
                  @ PRow(), PCol() + 1 SAY nPPotBHD PICTURE picBHD
                  nDugBHD += nPDugBHD
                  nPotBHD += nPPotBHD
                  @ PRow(), PCol() + 1 SAY nDugBHD - nPotBHD PICT picbhd
                  @ PRow(), PCol() + 1 SAY nPDugDEM PICTURE picdem
                  @ PRow(), PCol() + 1 SAY nPPotDEM PICTURE picdem
                  nDugDEM += nPDugDEM
                  nPotDEM += nPPotDEM
                  @ PRow(), PCol() + 1 SAY nDugDEM - nPotDEM PICT picdem
               ENDIF

               IF cKumulativniPrometBez1Sa2 == "2"  // sa kumulativom
                  IF p_cValutaDom1Eur2Obje3 == "1"
                     @ PRow(), PCol() + 1 SAY nDugBHD PICTURE picbhd
                     @ PRow(), PCol() + 1 SAY nPotBHD PICTURE picbhd
                  ELSE
                     @ PRow(), PCol() + 1 SAY nDugDEM PICTURE picbhd
                     @ PRow(), PCol() + 1 SAY nPotDEM PICTURE picbhd
                  ENDIF
               ENDIF

               IF p_cValutaDom1Eur2Obje3 == "1"  // KM
                  @ PRow(), PCol() + 1 SAY nDugBHD - nPotBHD PICT picbhd
               ELSEIF p_cValutaDom1Eur2Obje3 == "2"
                  @ PRow(), PCol() + 1 SAY nDugDEM - nPotDEM PICT picbhd
               ENDIF

               IF !Eval( bEvalSubanKartPartner )
                  LOOP
               ENDIF

            ENDIF

            hRec := dbf_get_rec()
            nSpojeno := 0

            DO WHILE lSpojiUplate .AND. hRec[ "datdok" ] == suban->datdok .AND. ;
                  suban->idvn == hRec[ "idvn" ] .AND. suban->d_p == hRec[ "d_p" ] .AND. ;
                  ( suban->idvn == cIdVnIzvod .OR. cIdVnIzvod == "**" ) .AND. suban->d_p == cSpojiDP .AND. Eval( bEvalSubanKartPartner )

               IF nSpojeno > 0
                  hRec[ "iznosbhd" ] += field->iznosbhd
                  hRec[ "iznosdem" ] += field->iznosdem
                  IF hRec[ "idvn" ] == "03" // kompenzacije
                     cUplate := "kompenzacije"
                  ELSE // "61"
                     cUplate := "uplate"
                  ENDIF
                  hRec[ "opis" ] := iif( cSpojiDP == "2", cUplate, "placanja" ) + " na dan " + DToC( field->datdok )
                  hRec[ "brdok" ] := iif( hRec[ "otvst" ] == "9", "Z", "O" ) + "-" + DToC( field->datdok )
               ENDIF
               nSpojeno++
               SKIP
            ENDDO

            IF nSpojeno > 0
               SKIP -1
            ENDIF

            IF !( lOtvoreneStavke .AND. hRec[ "otvst" ] == "9" )
               cIdVn := hRec[ "idvn" ]
               cBrNal := hRec[ "brnal" ]
               nRbr := hRec[ "rbr" ]
               dDatDok := hRec[ "datdok" ]
               dDatVal := fix_dat_var( hRec[ "datval" ], .T. )
               s_cOpis := hRec[ "opis" ]
               s_cBrVeze := hRec[ "brdok" ]

               ++nCnt
               IF nCnt % 100 == 0
                  info_bar("suban_kart", )
                  info_bar("sub_kart", "suban: " + AllTrim(Str(nCnt)) + " / " + AllTrim(Str(suban->(reccount()))))
               ENDIF
               ? hRec[ "idvn" ] // ---- POCETAK STAVKE KARTICE ----
               @ PRow(), PCol() + 1 SAY hRec[ "brnal" ]
               @ PRow(), PCol() + 1 SAY hRec[ "rbr" ] PICT "99999"
               IF hFinParams[ "fin_tip_dokumenta" ]
                  @ PRow(), PCol() + 1 SAY hRec[ "idtipdok" ]
                  select_o_tdok( SUBAN->IdTipDok )
                  @ PRow(), PCol() + 1 SAY PadR( tdok->naz, 13 )
               ENDIF

               SELECT SUBAN
               @ PRow(), PCol() + 1 SAY PadR( hRec[ "brdok" ], 10 )
               @ PRow(), PCol() + 1 SAY hRec[ "datdok" ]

               IF cPrikazK1234 == "1"
                  @ PRow(), PCol() + 1 SAY hRec[ "k1" ] + "-" + hRec[ "k2" ] + "-" + K3Iz256( hRec[ "k3" ] ) + hRec[ "k4" ]
               ELSEIF cPrikazK1234 == "2"
                  @ PRow(), PCol() + 1 SAY get_datval_field()
               ELSEIF cPrikazK1234 == "3"
                  nC7 := PCol() + 1
                  @ PRow(), nC7 SAY get_datval_field()
               ENDIF

               IF p_cValutaDom1Eur2Obje3 == "3"
                  s_nOpisRptLength := 36
                  nCOpis := PCol() + 1
                  @ PRow(), PCol() + 1 SAY PadR( cOpis := AllTrim( hRec[ "opis" ] ), s_nOpisRptLength )
               ELSE
                  nCOpis := PCol() + 1
                  @ PRow(), PCol() + 1 SAY PadR( cOpis := AllTrim( hRec[ "opis" ] ), s_nOpisRptLength )
               ENDIF
               nC1 := PCol() + 1
            ENDIF

            IF p_cValutaDom1Eur2Obje3 == "1"
               IF lOtvoreneStavke .AND. hRec[ "otvst" ] == "9"
                  IF hRec[ "d_p" ] == "1"
                     nZDugBHD += hRec[ "iznosbhd" ]   // zatvorena stavka
                  ELSE
                     nZPotBHD += hRec[ "iznosbhd" ]
                  ENDIF
               ELSE
                  IF hRec[ "d_p" ] == "1"
                     @ PRow(), PCol() + 1 SAY hRec[ "iznosbhd" ] PICTURE picBHD
                     @ PRow(), PCol() + 1 SAY 0 PICT picBHD
                     nDugBHD += hRec[ "iznosbhd" ]
                  ELSE
                     @ PRow(), PCol() + 1 SAY 0 PICT picBHD
                     @ PRow(), PCol() + 1 SAY hRec[ "iznosbhd" ] PICTURE picBHD
                     nPotBHD += hRec[ "iznosbhd" ]
                  ENDIF
                  IF cKumulativniPrometBez1Sa2 == "2"   // kumulativni promet
                     @ PRow(), PCol() + 1 SAY nDugBHD PICT picbhd
                     @ PRow(), PCol() + 1 SAY nPotBHD PICT picbhd
                  ENDIF
               ENDIF

            ELSEIF p_cValutaDom1Eur2Obje3 == "2" // dvovalutno

               IF lOtvoreneStavke .AND. hRec[ "otvst" ] == "9"
                  IF hRec[ "d_p" ] == "1"
                     nZDugDEM += hRec[ "iznosdem" ]
                  ELSE
                     nZPotDEM += hRec[ "iznosdem" ]
                  ENDIF
               ELSE
                  IF hRec[ "d_p" ] == "1"
                     @ PRow(), PCol() + 1 SAY hRec[ "iznosdem" ] PICTURE picbhd
                     @ PRow(), PCol() + 1 SAY 0 PICTURE picbhd
                     nDugDEM += IznosDEM
                  ELSE
                     @ PRow(), PCol() + 1 SAY 0        PICTURE picbhd
                     @ PRow(), PCol() + 1 SAY hRec[ "iznosdem" ] PICTURE picbhd
                     nPotDEM += hRec[ "iznosdem" ]
                  ENDIF
                  IF cKumulativniPrometBez1Sa2 == "2" // kumulativni promet
                     @ PRow(), PCol() + 1 SAY nDugDEM PICT picbhd
                     @ PRow(), PCol() + 1 SAY nPotDEM PICT picbhd
                  ENDIF

               ENDIF

            ELSEIF p_cValutaDom1Eur2Obje3 == "3"
               IF lOtvoreneStavke .AND. hRec[ "otvst" ] == "9"
                  IF hRec[ "d_p" ] == "1"
                     nZDugBHD += hRec[ "iznosbhd" ]
                     nZDugDEM += hRec[ "iznosdem" ]
                  ELSE
                     nZPotBHD += hRec[ "iznosbhd" ]
                     nZPotDEM += hRec[ "iznosdem" ]
                  ENDIF
               ELSE  // otvorene stavke
                  IF D_P == "1"
                     @ PRow(), PCol() + 1 SAY hRec[ "iznosbhd" ]  PICTURE picBHD
                     @ PRow(), PCol() + 1 SAY 0        PICTURE picBHD
                     nDugBHD += hRec[ "iznosbhd" ]
                  ELSE
                     @ PRow(), PCol() + 1 SAY 0        PICTURE picBHD
                     @ PRow(), PCol() + 1 SAY hRec[ "iznosbhd" ] PICTURE picBHD
                     nPotBHD += hRec[ "iznosbhd" ]
                  ENDIF
                  @ PRow(), PCol() + 1 SAY nDugBHD - nPotBHD PICT picbhd
                  IF D_P == "1"
                     @ PRow(), PCol() + 1 SAY hRec[ "iznosdem" ] PICTURE picdem
                     @ PRow(), PCol() + 1 SAY 0        PICTURE picdem
                     nDugDEM += hRec[ "iznosdem" ]
                  ELSE
                     @ PRow(), PCol() + 1 SAY 0        PICTURE picdem
                     @ PRow(), PCol() + 1 SAY hRec[ "iznosdem" ] PICTURE picdem
                     nPotDEM += hRec[ "iznosdem" ]
                  ENDIF
                  @ PRow(), PCol() + 1 SAY nDugDEM - nPotDEM PICT picdem
               ENDIF
            ENDIF

            IF !( lOtvoreneStavke .AND. hRec[ "otvst" ] == "9" ) // ako se radi o otvorenim stavkama, prikazati samo ono sto nije zatvoreno
               IF p_cValutaDom1Eur2Obje3 = "1"
                  @ PRow(), PCol() + 1 SAY nDugBHD - nPotBHD PICT picbhd // saldo KM
               ELSEIF p_cValutaDom1Eur2Obje3 == "2"
                  @ PRow(), PCol() + 1 SAY nDugDEM - nPotDEM PICT picbhd // saldo EUR
               ENDIF
               IF cPrikazK1234 == "3"
                  @ PRow() + 1, nC7 SAY hRec[ "k1" ] + "-" + hRec[ "k2" ] + "-" + K3Iz256( hRec[ "k3" ] ) + hRec[ "k4" ]
                  IF gFinRj == "D"
                     @ PRow(), PCol() + 1 SAY "RJ:" + hRec[ "idrj" ]
                  ENDIF
                  IF gFinFunkFond == "D"
                     @ PRow(), PCol() + 1 SAY "Funk.:" + hRec[ "funk" ]
                     @ PRow(), PCol() + 1 SAY "Fond.:" + hRec[ "fond" ]
                  ENDIF
               ENDIF
            ENDIF
            fin_print_ostatak_opisa( @cOpis, nCOpis, {|| check_nova_strana( bZagl, oPDF ) }, s_nOpisRptLength )
            IF cExpXlsx == "D" .AND. !( lOtvoreneStavke .AND. hRec[ "otvst" ] == "9" )
               IF  hRec[ "d_p" ] == "1"
                  nDuguje := hRec[ "iznosbhd" ]
                  nPotrazuje := 0
               ELSE
                  nDuguje := 0
                  nPotrazuje :=  hRec[ "iznosbhd" ]
               ENDIF
               xlsx_export_fill_row( cIdKonto, cKontoNaziv, cIdPartner, cPartnerNaziv, cIdVn, cBrNal, nRbr, s_cBrVeze, dDatDok, dDatVal, s_cOpis, nDuguje, nPotrazuje, nDugBHD - nPotBHD )
            ENDIF

            SKIP 1
         ENDDO

         check_nova_strana( bZagl, oPdf, .F., 3 )
         ? M
         ? "UKUPNO:" + cIdkonto + iif( cBrza == "D" .AND. RTrim( cUslovIdPartner ) == ";", "", " - " + cIdPartner )

         IF cRasclaniti == "D"
            @ PRow(), PCol() + 1 SAY Left( cRasclan, 6 ) + "/" + SubStr( cRasclan, 7, 5 ) + "/" + SubStr( cRasclan, 12 ) + " / " + get_rj_naz( Left( cRasclan, 6 ) )
         ENDIF
         IF p_cValutaDom1Eur2Obje3 == "1"
            @ PRow(), nC1      SAY nDugBHD PICTURE picBHD
            @ PRow(), PCol() + 1 SAY nPotBHD PICTURE picBHD
            IF cKumulativniPrometBez1Sa2 == "2"
               @ PRow(), PCol() + 1 SAY nDugBHD PICT picbhd
               @ PRow(), PCol() + 1 SAY nPotBHD PICT picbhd
            ENDIF
            @ PRow(), PCol() + 1 SAY nDugBHD - nPotBHD PICT picbhd
         ELSEIF p_cValutaDom1Eur2Obje3 == "2"
            @ PRow(), nC1      SAY nDugDEM PICTURE picBHD
            @ PRow(), PCol() + 1 SAY nPotDEM PICTURE picBHD
            IF cKumulativniPrometBez1Sa2 == "2"
               @ PRow(), PCol() + 1 SAY nDugDEM PICT picbhd
               @ PRow(), PCol() + 1 SAY nPotDEM PICT picbhd
            ENDIF
            @ PRow(), PCol() + 1 SAY nDugDEM - nPotDEM PICT picbhd
         ELSEIF  p_cValutaDom1Eur2Obje3 == "3"
            @ PRow(), nC1      SAY nDugBHD PICTURE picBHD
            @ PRow(), PCol() + 1 SAY nPotBHD PICTURE picBHD
            @ PRow(), PCol() + 1 SAY nDugBHD - nPotBHD PICT picbhd

            @ PRow(), PCol() + 1      SAY nDugDEM PICTURE picdem
            @ PRow(), PCol() + 1 SAY nPotDEM PICTURE picdem
            @ PRow(), PCol() + 1 SAY nDugDEM - nPotDEM PICT picdem
         ENDIF

         IF lOtvoreneStavke
            ? "Promet zatvorenih stavki:"
            IF p_cValutaDom1Eur2Obje3 == "1"
               @ PRow(), nC1      SAY nZDugBHD PICTURE picBHD
               @ PRow(), PCol() + 1 SAY nZPotBHD PICTURE picBHD
               IF cKumulativniPrometBez1Sa2 == "2"
                  @ PRow(), PCol() + 1 SAY nZDugBHD PICT picbhd
                  @ PRow(), PCol() + 1 SAY nZPotBHD PICT picbhd
               ENDIF
               @ PRow(), PCol() + 1 SAY nZDugBHD - nZPotBHD PICT picbhd

            ELSEIF p_cValutaDom1Eur2Obje3 == "2"
               @ PRow(), nC1      SAY nZDugDEM PICTURE picBHD
               @ PRow(), PCol() + 1 SAY nZPotDEM PICTURE picBHD
               IF cKumulativniPrometBez1Sa2 == "2"
                  @ PRow(), PCol() + 1 SAY nZDugDEM PICT picbhd
                  @ PRow(), PCol() + 1 SAY nZPotDEM PICT picbhd
               ENDIF
               @ PRow(), PCol() + 1 SAY nZDugDEM - nZPotDEM PICT picbhd
            ELSEIF  p_cValutaDom1Eur2Obje3 == "3"
               @ PRow(), nC1      SAY nZDugBHD PICTURE picBHD
               @ PRow(), PCol() + 1 SAY nZPotBHD PICTURE picBHD
               @ PRow(), PCol() + 1 SAY nZDugBHD - nZPotBHD PICT picbhd

               @ PRow(), PCol() + 1 SAY nZDugDEM PICTURE picdem
               @ PRow(), PCol() + 1 SAY nZPotDEM PICTURE picdem
               @ PRow(), PCol() + 1 SAY nZDugDEM - nZPotDEM PICT picdem
            ENDIF
         ENDIF

         ? M

         nKonD += nDugBHD
         nKonP += nPotBHD
         nKonD2 += nDugDEM
         nKonP2 += nPotDEM

         check_nova_strana( bZagl, oPdf, .F., 0, 1 )

      ENDDO // konto

      IF cBrza == "N"

         check_nova_strana( bZagl, oPdf, .F., 3 )
         ? M
         ?U "UKUPNO ZA KONTO: " + cIdKonto
         IF p_cValutaDom1Eur2Obje3 == "1"
            @ PRow(), nC1            SAY nKonD  PICTURE picBHD
            @ PRow(), PCol() + 1       SAY nKonP  PICTURE picBHD
            IF cKumulativniPrometBez1Sa2 == "2"
               @ PRow(), PCol() + 1       SAY nKonD  PICTURE picBHD
               @ PRow(), PCol() + 1       SAY nKonP  PICTURE picBHD
            ENDIF
            @ PRow(), PCol() + 1  SAY nKonD - nKonP PICT picbhd
         ELSEIF p_cValutaDom1Eur2Obje3 == "2"
            @ PRow(), nC1            SAY nKonD2 PICTURE picBHD
            @ PRow(), PCol() + 1       SAY nKonP2 PICTURE picBHD
            IF cKumulativniPrometBez1Sa2 == "2"
               @ PRow(), PCol() + 1       SAY nKonD2 PICTURE picBHD
               @ PRow(), PCol() + 1       SAY nKonP2 PICTURE picBHD
            ENDIF
            @ PRow(), PCol() + 1  SAY nKonD2 - nKonP2 PICT picbhd
         ELSEIF p_cValutaDom1Eur2Obje3 == "3"
            @ PRow(), nC1            SAY nKonD  PICTURE picBHD
            @ PRow(), PCol() + 1       SAY nKonP  PICTURE picBHD
            @ PRow(), PCol() + 1  SAY nKonD - nKonP PICT picbhd
            @ PRow(), PCol() + 1       SAY nKonD2 PICTURE picdem
            @ PRow(), PCol() + 1       SAY nKonP2 PICTURE picdem
            @ PRow(), PCol() + 1  SAY nKonD2 - nKonP2 PICT picdem

         ENDIF
         ? M


         IF lKarticaNovaStrana
            check_nova_strana( bZagl, oPDF, .T. )
         ELSE
            check_nova_strana( bZagl, oPDF, .F., 0, 1 ) // dodaj 1 prazan red
         ENDIF


      ENDIF

      nSviD += nKonD; nSviP += nKonP
      nSviD2 += nKonD2; nSviP2 += nKonP2

   ENDDO

   IF cBrza == "N"

      check_nova_strana( bZagl, oPdf, .F., 4 )
      ? M
      ?U "UKUPNO ZA SVA KONTA:"
      IF p_cValutaDom1Eur2Obje3 == "1"
         @ PRow(), nC1       SAY nSviD        PICTURE picBHD
         @ PRow(), PCol() + 1  SAY nSviP        PICTURE picBHD
         IF cKumulativniPrometBez1Sa2 == "2"
            @ PRow(), PCol() + 1  SAY nSviD        PICTURE picBHD
            @ PRow(), PCol() + 1  SAY nSviP        PICTURE picBHD
         ENDIF
         @ PRow(), PCol() + 1  SAY nSviD - nSviP  PICTURE picBHD
      ELSEIF p_cValutaDom1Eur2Obje3 == "2"
         @ PRow(), nC1       SAY nSviD2        PICTURE picBHD
         @ PRow(), PCol() + 1  SAY nSviP2        PICTURE picBHD
         IF cKumulativniPrometBez1Sa2 == "2"
            @ PRow(), PCol() + 1  SAY nSviD2       PICTURE picBHD
            @ PRow(), PCol() + 1  SAY nSviP2       PICTURE picBHD
         ENDIF
         @ PRow(), PCol() + 1  SAY nSviD2 - nSviP2 PICTURE picBHD
      ELSEIF p_cValutaDom1Eur2Obje3 == "3"
         @ PRow(), nC1       SAY nSviD        PICTURE picBHD
         @ PRow(), PCol() + 1  SAY nSviP        PICTURE picBHD
         @ PRow(), PCol() + 1  SAY nSviD - nSviP  PICTURE picBHD
         @ PRow(), PCol() + 1  SAY nSviD2        PICTURE picdem
         @ PRow(), PCol() + 1  SAY nSviP2        PICTURE picdem
         @ PRow(), PCol() + 1  SAY nSviD2 - nSviP2 PICTURE picdem
      ENDIF
      ? M
      ?

   ENDIF

   end_print( xPrintOpt )

   IF cExpXlsx == "D"
      my_close_all_dbf()
      workbook_close( s_pWorkBook )
      s_pWorkBook := NIL
      s_pWorkSheet := NIL
      f18_open_mime_document( s_cXlsxName )
      //open_exported_xlsx()
   ENDIF

   my_close_all_dbf()

   RETURN .T.


STATIC FUNCTION xlsx_export_fill_row( cIdKonto, cKontoNaziv, cIdPartner, cPartnerNaziv, cIdVn, cBrNal, nRbr, cBrVeze, dDatdok, dDatVal, cOpis, nDug, nPot, nSaldo )

   LOCAL nI
   LOCAL aKarticaKolone
   LOCAL cProdajnoMjesto

 
   aKarticaKolone := {}
   AADD(aKarticaKolone, { "C", "Konto ID", 8, Trim(cIdKonto) })
   AADD(aKarticaKolone, { "C", "Partner ID", 8, Trim(cIdPartner) })
   
   IF s_lSifkPRMJ
      IF cIdPartner == s_cIdPartnerPredhodni
         cProdajnoMjesto := s_cProdajnoMjestoPredhodno
      ELSE
         cProdajnoMjesto := AllTrim( get_partn_sifk_sifv( "PRMJ", cIdPartner ) )
         s_cIdPartnerPredhodni := cIdPartner 
         s_cProdajnoMjestoPredhodno := cProdajnoMjesto
      ENDIF
      AADD(aKarticaKolone, { "C", "Pr.MJ", 6, cProdajnoMjesto })    
   ENDIF

   AADD(aKarticaKolone, { "C", "VN", 5, cIdVn })
   AADD(aKarticaKolone, { "C", "Br.Nal", 12, Trim(cBrNal) })
   AADD(aKarticaKolone, { "N", "Rbr", 7, nRbr })
   AADD(aKarticaKolone, { "C", "Br.Veze", 17, Trim(cBrVeze) })
   AADD(aKarticaKolone, { "D", "Dat.Dok", 12, dDatDok })
   AADD(aKarticaKolone, { "D", "Valuta", 12, dDatVal })
   AADD(aKarticaKolone, { "C", "Opis", 40, Trim(cOpis)  })
   AADD(aKarticaKolone, { "M", "Duguje", 15, nDug })
   AADD(aKarticaKolone, { "M", "Potrazuje", 15, nPot })        
   AADD(aKarticaKolone, { "M", "Saldo", 15, nSaldo })     
   
   
   IF s_pWorkSheet == NIL
      
      s_pWorkBook := workbook_new( s_cXlsxName )
      s_pWorkSheet := workbook_add_worksheet(s_pWorkBook, NIL)

      s_pMoneyFormat := workbook_add_format(s_pWorkBook)
      format_set_num_format(s_pMoneyFormat, /*"#,##0"*/ "#0.00" )

      s_pDateFormat := workbook_add_format(s_pWorkBook)
      format_set_num_format(s_pDateFormat, "d.mm.yy")
    
      
      /* Set the column width. */
       for nI := 1 TO LEN(aKarticaKolone)
         // worksheet_set_column(lxw_worksheet *self, lxw_col_t firstcol, lxw_col_t lastcol, double width, lxw_format *format)
         worksheet_set_column(s_pWorkSheet, nI - 1, nI - 1, aKarticaKolone[ nI, 3], NIL)
       next


      //nema smisla header kada imamo vise konta ili vise partnera
      //worksheet_write_string( s_pWorkSheet, 0, 0,  "Konto:", NIL)
      //worksheet_write_string( s_pWorkSheet, 0, 1,  hb_StrToUtf8(cIdKonto + " - " + Trim( cKontoNaziv)), NIL)
      //worksheet_write_string( s_pWorkSheet, 1, 0,  "Partner:", NIL)
      //worksheet_write_string( s_pWorkSheet, 1, 1,  hb_StrToUtf8(cIdPartner + " - " + Trim(cPartnerNaziv)), NIL)
    
       /* Set header */
       s_nWorkSheetRow := 0
       for nI := 1 TO LEN(aKarticaKolone)
         worksheet_write_string( s_pWorkSheet, s_nWorkSheetRow, nI - 1,  aKarticaKolone[nI, 2], NIL)
       next
       
   ENDIF


   s_nWorkSheetRow++

   FOR nI := 1 TO LEN(aKarticaKolone)
          IF aKarticaKolone[ nI, 1 ] == "C"
             worksheet_write_string( s_pWorkSheet, s_nWorkSheetRow, nI - 1,  hb_StrToUtf8(aKarticaKolone[nI, 4]), NIL)
          ELSEIF aKarticaKolone[ nI, 1 ] == "M"
             worksheet_write_number( s_pWorkSheet, s_nWorkSheetRow, nI - 1,  aKarticaKolone[nI, 4], s_pMoneyFormat)
          ELSEIF aKarticaKolone[ nI, 1 ] == "N"
            worksheet_write_number( s_pWorkSheet, s_nWorkSheetRow, nI - 1,  aKarticaKolone[nI, 4], NIL)
         ELSEIF aKarticaKolone[ nI, 1 ] == "D"
            worksheet_write_datetime( s_pWorkSheet, s_nWorkSheetRow, nI - 1,  aKarticaKolone[nI, 4], s_pDateFormat)
         ENDIF
   NEXT
        
   RETURN .T.



/*
 *     Postavlja uslov za partnera (npr. Telefon('417'))
 *   param: cTel  - Broj telefona
 */

FUNCTION Telefon( cTel )

   LOCAL nSelect

   nSelect := Select()
   select_o_partner( suban->idpartner )
   SELECT ( nSelect )

   RETURN ( partn->telefon == cTel )



STATIC FUNCTION zagl_suban_kartica( cBrza )

   LOCAL hFinParams := fin_params()

  // IF c1K1z == NIL
  //    c1K1z := "N"
  // ENDIF

   Preduzece()

   //IF lOtvoreneStavke
   //   ?U "FIN: KARTICA OTVORENIH STAVKI "
   //ELSE
   //   ?U "FIN: SUBANALITIČKA KARTICA ZA "
   //ENDIF

   IF cBrza != "D"
      ??U " KONTO: ", cIdKonto
   ENDIF

   IF !( Empty( dDatOd ) .AND. Empty( dDatDo ) )
      ??U " ZA PERIOD: ", dDatOd, "-", dDatDo
   ENDIF
   IF !Empty( cUslovUpperBrDok )
      ?U "Izvještaj pravljen po uslovu za broj veze/računa: '" + Trim( cUslovUpperBrDok ) + "'"
   ENDIF

   SELECT SUBAN

   IF p_cValutaDom1Eur2Obje3 == "3"

      IF hFinParams[ "fin_tip_dokumenta" ] .AND. cPrikazK1234 == "4"
         ? "-(1)------------- ------------------------------------------------------------------------- --------------------------------- -------------- -------------------------- -------------"
         ? "*  NALOG         *               D  O  K  U  M  E  N  T                                    *          PROMET  " + valuta_domaca_skraceni_naziv() + "           *    SALDO     *       PROMET  " + ValPomocna() + "       *   SALDO    *"
         ? "----------------- ------------------------------------ ------------------------------------ ----------------------------------      " + valuta_domaca_skraceni_naziv() + "    * --------------------------    " + ValPomocna() + "    *"
         ? "*V.*BR     * R.  *     TIP I      *   BROJ   *  DATUM *              OPIS                  *     DUG       *       POT       *              *      DUG    *   POT      *            *"
         ? "*N.*       * Br. *     NAZIV      *          *        *                                    *               *                 *              *             *            *            *"
      ELSEIF hFinParams[ "fin_tip_dokumenta" ]
         ? "-(2)------------- ---------------------------------------------------------------------------- ----- --------------------------------- -------------- -------------------------- -------------"
         ? "*  NALOG         *                       D  O  K  U  M  E  N  T                                     *          PROMET  " + valuta_domaca_skraceni_naziv() + "           *    SALDO     *       PROMET  " + ValPomocna() + "       *   SALDO    *"
         ? "----------------- ------------------------------------ -------- ------------------------------------ ----------------------------------      " + valuta_domaca_skraceni_naziv() + "    * --------------------------    " + ValPomocna() + "    *"
         ? "*V.*BR     *  R. *     TIP I      *   BROJ   *  DATUM *" + iif( cPrikazK1234 == "1", " K1-K4  ", " VALUTA " ) + "*              OPIS                  *     DUG       *       POT       *              *      DUG    *   POT      *            *"
         ? "*N.*       *  Br.*     NAZIV      *          *        *        *                                    *               *                 *              *             *            *            *"
      ELSE
         ? "-(3)------------- ----------------------------------------------------------------- --------------------------------- -------------- -------------------------- -------------"
         ? "*  NALOG         *           D O K U M E N T                                       *          PROMET  " + valuta_domaca_skraceni_naziv() + "           *    SALDO     *       PROMET  " + ValPomocna() + "       *   SALDO    *"
         ? "----------------- ------------------- -------- ------------------------------------ ----------------------------------      " + valuta_domaca_skraceni_naziv() + "    * --------------------------    " + ValPomocna() + "    *"
         ? "*V.*BR     *  R. *   BROJ   *  DATUM *" + iif( cPrikazK1234 == "1", " K1-K4  ", " VALUTA " ) + "*              OPIS                  *     DUG       *       POT       *              *      DUG    *   POT      *            *"
         ? "*N.*       *  Br.*          *        *        *                                    *               *                 *              *             *            *            *"
      ENDIF


   ELSEIF cKumulativniPrometBez1Sa2 == "1"

      IF hFinParams[ "fin_tip_dokumenta" ]
         ?U  "-(4)------------- -------------------------------------------------------------------------------------- ---------------------------------- ---------------"
         ?U  "*  NALOG         *                       D  O  K  U  M  E  N  T                                         *           P R O M E T            *    SALDO     *"
         ?U  "----------------- ------------------------------------ -------- ---------------------------------------- ----------------------------------               *"
         ?U  "*V.*BR     * R.  *     TIP I      *  BROJ    *  DATUM *" + iif( cPrikazK1234 == "1", " K1-K4  ", " VALUTA " ) + "*              OPIS                      *    DUGUJE     *    POTRAŽUJE     *              *"
         ?U  "*N.*       * Br. *     NAZIV      *          *        *        *                    *               *                  *              *"
      ELSE
         // default
         ?U  "----------------- " + Replicate("-", 29 + s_nOpisRptLength) + " ---------------------------------- ---------------"
         ?U  "*  NALOG         *" + PadC("D O K U M E N T", 29 + s_nOpisRptLength) + "*           P R O M E T            *    SALDO     *"
         ?U  "----------------- " + "------------------- -------- " + Replicate("-", s_nOpisRptLength) + " ----------------------------------               *"
         ?U  "*V.*BR     * R.  *   BROJ   *  DATUM *" + iif( cPrikazK1234 == "1", " K1-K4  ", " VALUTA " ) + "*" + PadC("OPIS", s_nOpisRptLength) + "*    DUGUJE     *    POTRAŽUJE     *              *"
         ?U  "*N.*       * Br. *          *        *        *" + SPACE(s_nOpisRptLength) + "*               *                  *              *"
      ENDIF

   ELSE

      IF hFinParams[ "fin_tip_dokumenta" ] .AND. cPrikazK1234 == "4"
         ?U  "-(5)------------ ----------------------------------------------------------------------------- ---------------------------------- ---------------------------------- ---------------"
         ?U  "*  NALOG        *                        D  O  K  U  M  E  N  T                               *           P R O M E T            *           K U M U L A T I V      *    SALDO     *"
         ?U  "---------------- ------------------------------------ ---------------------------------------- ---------------------------------- ----------------------------------               *"
         ?U  "*V.*BR     * R. *     TIP I      *   BROJ   *  DATUM *              OPIS                      *    DUGUJE     *    POTRAŽUJE     *    DUGUJE     *    POTRAŽUJE     *              *"
         ?U  "*N.*       * Br.*     NAZIV      *          *        *                                        *               *                  *               *                  *              *"
      ELSEIF hFinParams[ "fin_tip_dokumenta" ]
         ?U  "-(6)------------ -------------------------------------------------------------------------------------- ---------------------------------- ---------------------------------- ---------------"
         ?U  "*  NALOG        *                       D  O  K  U  M  E  N  T                                         *           P R O M E T            *           K U M U L A T I V      *    SALDO     *"
         ?U  "---------------- ------------------------------------ -------- ---------------------------------------- ---------------------------------- ----------------------------------               *"
         ?U  "*V.*BR     * R. *     TIP I      *   BROJ   *  DATUM *" + iif( cPrikazK1234 == "1", " K1-K4  ", " VALUTA " ) + "*              OPIS                      *    DUGUJE     *    POTRAŽUJE     *    DUGUJE     *    POTRAŽUJE     *              *"
         ?U  "*N.*       * Br.*     NAZIV      *          *        *        *                                        *               *                  *               *                  *              *"
      ELSE
         ?U  "-(7)------------- --------------------------------------------------------------------- ---------------------------------- ---------------------------------- ---------------"
         ?U  "*  NALOG         *                    D O K U M E N T                                  *           P R O M E T            *           K U M U L A T I V      *    SALDO     *"
         ?U  "----------------- ------------------- -------- ---------------------------------------- ---------------------------------- ----------------------------------               *"
         ?U  "*V.*BR     *  R. *   BROJ   *  DATUM *" + iif( cPrikazK1234 == "1", " K1-K4  ", " VALUTA " ) + "*              OPIS                      *    DUGUJE     *    POTRAŽUJE     *    DUGUJE     *    POTRAŽUJE     *              *"
         ?U  "*N.*       *  Br.*          *        *        *                                        *               *                  *               *                  *              *"
      ENDIF

   ENDIF
   ? m

   RETURN .T.




/*
 *  Rasclanjuje SUBAN->(IdRj+Funk+Fond)
 */

FUNCTION RasclanRjFunkFond( cRasclaniti, cRasclan )

   IF cRasclaniti == "D"
      RETURN cRasclan ==  (suban->idrj + suban->funk + suban->fond)
   ELSE
      RETURN .T.
   ENDIF

   RETURN .T.



/*
     Validacija firme - unesi firmu po referenci
     cIdfirma  - id firme
 */

FUNCTION V_Firma( cIdFirma )

   p_partner( @cIdFirma )
   cIdFirma := Trim( cIdFirma )
   cIdFirma := Left( cIdFirma, 2 )

   RETURN .T.



FUNCTION fin_prebijeno_stanje_dug_pot( nDugX, nPotX )

   IF ( nDugx - nPotX ) > 0
      nDugX := nDugX - nPotX
      nPotX := 0
   ELSE
      nPotX := nPotX - nDugX
      nDugX := 0
   ENDIF

   RETURN .T.


STATIC FUNCTION kartica_otvori_tabele()

   my_close_all_dbf()

   RETURN .T.
