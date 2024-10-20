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


STATIC dDatOd
STATIC dDatDo
STATIC cFinPath
STATIC cSifPath
STATIC cTDSrc
STATIC nZaok
STATIC nZaok2
STATIC cIdTar
STATIC cIdPart
// setuj broj dokumenta
STATIC cSBRdok
STATIC s_cOpis

// kategorija partnera
// 1-pdv obv
// 2-ne pdv obvz
STATIC cKatP

// kategorija partnera 2
// 1-fed
// 2-rs
// 3-bd
STATIC cKatP2

// razbij po danima
STATIC cRazbDan


FUNCTION epdv_generacija_fin_kuf( dD1, dD2, cSezona )

   LOCAL nCount
   LOCAL cIdfirma

   IF cSezona == nil
      cSezona := ""
   ENDIF

   dDatOd := dD1
   dDatDo := dD2
   epdv_otvori_kuf_priprema()

   select_o_sg_kuf()

   SELECT sg_kuf
   GO TOP
   nCount := 0
   DO WHILE !Eof()

      nCount++
      IF Upper( aktivan ) == "N"
         SKIP
         LOOP
      ENDIF

      @ box_x_koord() + 1, box_y_koord() + 2 SAY "SG_KUF : " + Str( nCount )

      IF g_src_modul( src ) == "FIN"

         cTdSrc := sg_kuf->td_src
         cIdTar := sg_kuf->s_id_tar // set id tarifu u kuf dokumentu
         cIdPart := sg_kuf->s_id_part
         cKatP := sg_kuf->kat_p
         cKatP2 := sg_kuf->kat_p_2
         s_cOpis := sg_kuf->naz
         cRazbDan := razb_dan
         cSBRdok := s_br_dok // setuj broj dokumenta

         PRIVATE cFormBPdv := form_b_pdv
         PRIVATE cFormPdv := form_pdv


         PRIVATE cTarFormula := ""
         PRIVATE cTarFilter := ""

         PRIVATE cKtoFormula := ""
         PRIVATE cKtoFilter := ""


         IF ";" $ id_tar
            cTarFilter := Parsiraj( id_tar, "IdTarifa" )
            cTarFormula := ""

         ELSEIF ( "(" $ id_tar ) .AND. ( ")" $ id_tar )
            // zadaje se formula
            cTarFormula := id_tar
            cTarFilter := ""
         ELSE
            cTarFilter := ""
            cTarFormula := ""
         ENDIF

         IF ";" $ id_kto
            cKtoFilter := Parsiraj( id_kto, AllTrim( id_kto_naz ) )
            cKtoFormula := ""

         ELSEIF ( "(" $ id_kto ) .AND. ( ")" $ id_kto )
            // zadaje se formula
            cKtoFormula := id_kto
            cKtoFilter := ""
         ELSE
            cKtoFilter := ""
            cKtoFormula := ""
         ENDIF

         nZaok := zaok
         nZaok2 := zaok2

         gen_fin_kuf_item( cSezona ) // za jednu shema gen stavku formiraj kuf

      ENDIF

      SELECT sg_kuf
      SKIP

   ENDDO


STATIC FUNCTION gen_fin_kuf_item( cSezona )

   LOCAL cPomPath
   LOCAL cPomSPath

   LOCAL cDokTar
   LOCAL xDummy
   LOCAL nCount
   LOCAL cPom
   LOCAL cPartRejon
   LOCAL lPdvObveznik
   LOCAL lIno
   LOCAL dDMin
   LOCAL dDMax


   LOCAL dDMinD // za jedan dokument
   LOCAL dDMaxD

   // zavisni troskovi
   LOCAL nZ1
   LOCAL nZ2
   LOCAL nZ3
   LOCAL nZ4
   LOCAL nZ5

   LOCAL lSkip
   LOCAL lSkip2
   LOCAL nIznos

   LOCAL cOpisSuban
   LOCAL nRecNoSuban

   close_open_fin_epdv_tables( dDatOd, dDatDo )


   PRIVATE cFilter := ".T."

   // cFilter :=  dbf_quote( dDatOd ) + " <= datdok .and. " + dbf_quote( dDatDo ) + ">= datdok"

   // setuj tip dokumenta
   IF !Empty( cTdSrc )
      IF Len( Trim( cTdSrc ) ) == 1
         // ako se stavi "B " onda se uzimaju svi nalozi koji pocinju
         // sa B
         cFilter :=  cFilter + ".and. IdVN = " + dbf_quote( Trim( cTdSrc ) )
      ELSE
         cFilter :=  cFilter + ".and. IdVN == " + dbf_quote( cTdSrc )
      ENDIF
   ENDIF

   IF !Empty( cTarFilter )
      cFilter += ".and. " + cTarFilter
   ENDIF

   IF !Empty( cKtoFilter )
      cFilter +=  ".and. " + cKtoFilter
   ENDIF

   SELECT SUBAN
   // SET ORDER TO TAG "4"
   SET FILTER TO &cFilter // fin_suban
   GO TOP

   nCount := 0
   DO WHILE !Eof()

      SELECT p_kuf
      Scatter()

      SELECT SUBAN

      dDMin := datdok
      dDMax := datdok

      PRIVATE _iznos := 0 // ove var moraju biti private da bi se mogle macro-om evaluirati


      DO WHILE !Eof() .AND.  ( datdok == dDMax ) // datumski period

         SELECT suban

         cBrdok := suban->brnal
         cIdTipDok := suban->IdVn
         cIdFirma := suban->IdFirma

         nRecnoSuban := suban->( RecNo() )

         _datum := suban->datdok  // datum kuf-a
         _id_part := suban->idpartner
         // ##opis## je djoker - zamjenjuje se sa opisom koji se nalazi u
         // stavci
         cOpisSuban := AllTrim( suban->opis )
         _opis := StrTran( s_cOpis, "##opis##", cOpisSuban )

         IF !Empty( cIdPart )
            IF ( AllTrim( Upper( cIdPart ) ) == "#TD#" )
               _id_part := kuf_fin_trazi_dob ( suban->( RecNo() ), suban->idfirma, suban->idvn, suban->brnal, suban->brdok, suban->rbr )
            ELSE
               _id_part := cIdPart
            ENDIF
         ENDIF

         lIno := partner_is_ino( _id_part )
         lPdvObveznik := partner_is_pdv_obveznik( _id_part )

         lSkip := .F.
         DO CASE

         CASE cKatP == "1"

            // samo pdv obveznici
            IF lIno
               lSkip := .T.
            ENDIF

            IF !lPdvObveznik
               lSkip := .T.
            ENDIF

         CASE cKatP == "2"

            IF lPdvObveznik
               lSkip := .T.
            ENDIF


            IF lIno // samo ne-pdv obveznici, ako je ino preskoci
               lSkip := .T.
            ENDIF

         CASE cKatP == "3" // ino

            IF !lIno
               lSkip := .T.
            ENDIF

         ENDCASE

         cPartRejon := part_rejon( _id_part )

         DO CASE

         CASE cKatP2 == "1"
            // samo federacija
            IF !( ( cPartRejon == " " ) .OR. ( cPartRejon == "1" ) )
               lSkip := .T.
            ENDIF

         CASE cKatP2 == "2"
            // nije rs, preskoci
            IF !( cPartRejon == "2" )
               lSkip := .T.
            ENDIF

         CASE cKatP2 == "3"
            // nije bd, preskoci
            IF !( cPartRejon == "3" )
               lSkip := .T.
            ENDIF
         ENDCASE

         nCount++

         cPom := "SUBAN : " + cIdFirma + "-" + cIdTipDok + "-" + cBrDok
         @ box_x_koord() + 3, box_y_koord() + 2 SAY cPom

         cPom := "SUBAN cnt : " + Str( nCount, 6 )
         @ box_x_koord() + 4, box_y_koord() + 2 SAY cPom

         cDokTar := ""

         dDMinD := datdok
         dDMaxD := datdok

         lSkip2 := .F.
         IF !Empty( cTarFormula )
            IF ! &( cTarFormula )
               lSkip2 := .T.
               SKIP
               LOOP
            ENDIF

         ENDIF

         IF lSkip
            SKIP
            LOOP
         ENDIF


         IF dDMinD > datdok // na nivou dokumenta utvrdi min max datum
            dDMinD := datdok
         ENDIF

         IF dDMaxD < datdok
            dDMaxD := datdok
         ENDIF


         IF dDMin > datdok  // na nivou dat opsega utvrdi min max datum
            dDMinD := datdok
         ENDIF

         IF dDMax < datdok
            dDMax := datdok
         ENDIF


         IF d_p == "1"
            nIznos := iznosbhd
         ELSE
            nIznos := -iznosbhd
         ENDIF

         cBrDok := brdok

         _iznos += nIznos

         SELECT SUBAN
         SKIP

         IF ( cRazbDan == "D" )
            IF dDMinD <> dDMaxD
               MsgBeep( "U dokumentu " + cIdFirma + "-" + cIdTipDok + "-" + cBrDok + "  se nalaze datumi " + DToC( dDMaxD ) + "-" + DToC( dDMaxD ) + "##" + ;
                  "To nije uredu je se promet razbija po danima !!!" )
            ENDIF

         ENDIF

         IF cRazbDan <> "D"
            EXIT
         ENDIF

      ENDDO

      _datum := dDMax

      IF lSkip .OR. lSkip2
         SELECT SUBAN
         LOOP
      ENDIF

      PRIVATE _uk_pdv :=  0
      PushWA()
      SELECT SUBAN
      GO ( nRecNoSuban )

      _iznos := Round( _iznos, nZaok2 )

      IF !Empty( cIdTar )
         _id_tar := cIdTar
      ELSE
         _id_tar := cDokTar
      ENDIF

      DO CASE
      CASE AllTrim( cSBrDok ) == "#EXT#"
         IF Empty( cBrDok )
            _src_br := extract_oznaka( cOpisSuban )
            _src_br_2 := _src_br
         ELSE
            _src_br := cBrDok
            _src_br_2 := cBrDok
         ENDIF

      CASE !Empty( cSBrDok )
         _src_br := cSBrDok
         _src_br_2 := cSBrDok
      OTHERWISE

         _src_br := cBrDok
         _src_br_2 := cBrDok
      ENDCASE


      IF !Empty( cFormBPDV )
         _i_b_pdv := &cFormBPdv
      ELSE
         _i_b_pdv := _iznos / 1.17
      ENDIF
      _i_b_pdv := Round( _i_b_pdv, nZaok )

      IF !Empty( cFormPDV )
         _i_pdv := &cFormPdv
      ELSE
         _i_pdv :=  _iznos / 1.17 * 0.17
      ENDIF
      _i_pdv := Round( _i_pdv, nZaok )
      PopWa()

      SELECT P_KUF
      APPEND BLANK
      Gather()

      SELECT SUBAN

   ENDDO

   RETURN .T.


STATIC FUNCTION zav_tr( nZ1, nZ2, nZ3, nZ4, nZ5 )

   LOCAL Skol := 0
   LOCAL nPPP := 0
   //LOCAL gKalo := "0"

   SELECT SUBAN

   //IF gKalo == "1"
    //  Skol := Kolicina - GKolicina - GKolicin2
   //ELSE
      Skol := Kolicina
   //ENDIF

   nPPP := 1

   IF TPrevoz == "%"
      nPrevoz := Prevoz / 100 * FCj2
   ELSEIF TPrevoz == "A"
      nPrevoz := Prevoz
   ELSEIF TPrevoz == "U"
      IF skol <> 0
         nPrevoz := Prevoz / SKol
      ELSE
         nPrevoz := 0
      ENDIF
   ELSE
      nPrevoz := 0
   ENDIF
   nZ1 := nPrevoz

   IF TCarDaz == "%"
      nCarDaz := CarDaz / 100 * FCj2
   ELSEIF TCarDaz == "A"
      nCarDaz := CarDaz
   ELSEIF TCarDaz == "U"
      IF skol <> 0
         nCarDaz := CarDaz / SKol
      ELSE
         nCarDaz := 0
      ENDIF
   ELSE
      nCarDaz := 0
   ENDIF
   nZ2 := nCarDaz

   IF TZavTr == "%"
      nZavTr := ZavTr / 100 * FCj2
   ELSEIF TZavTr == "A"
      nZavTr := ZavTr
   ELSEIF TZavTr == "U"
      IF skol <> 0
         nZavTr := ZavTr / SKol
      ELSE
         nZavTr := 0
      ENDIF
   ELSE
      nZavTr := 0
   ENDIF
   nZ3 := nZavTr


   IF TBankTr == "%"
      nBankTr := BankTr / 100 * FCj2
   ELSEIF TBankTr == "A"
      nBankTr := BankTr
   ELSEIF TBankTr == "U"
      IF skol <> 0
         nBankTr := BankTr / SKol
      ELSE
         nBankTr := 0
      ENDIF
   ELSE
      nBankTr := 0
   ENDIF
   nZ4 := nBankTr

   IF TSpedTr == "%"
      nSpedTr := SpedTr / 100 * FCj2
   ELSEIF TSpedTr == "A"
      nSpedTr := SpedTr
   ELSEIF TSpedTr == "U"
      IF skol <> 0
         nSpedTr := SpedTr / SKol
      ELSE
         nSpedTr := 0
      ENDIF
   ELSE
      nSpedTr := 0
   ENDIF
   nZ5 := nSpedTr

   RETURN .T.



STATIC FUNCTION kuf_fin_trazi_dob( nRecNo, cIdFirma, cIdVn, cBrNal, cBrDok, nRbr )

   LOCAL i

   PushWa()
   SELECT SUBAN
   PushWA()

   SELECT suban
   SET FILTER TO

   FOR i := -3 TO 3

      GO ( nRecNo )
      SKIP i
      cKto := Left( idkonto, 3 )

      IF ( cKto $ AllTrim( gL_kto_dob ) ) .AND. ( IdFirma ==  cIdFirma ) .AND. ( IdVn == cIdVn ) .AND. ( BrNal == cBrNal ) .AND. ( BrDok == cBrDok )
         cIdPartner := suban->idpartner
         PopWa()
         PopWa()
         RETURN cIdPartner
      ENDIF

   NEXT

   PopWa()
   PopWa()

   RETURN ""


FUNCTION epdv_trazi_pdv_dobav( nRecNo, cIdFirma, cIdVn, cBrNal, cBrDok, nRbr, cOpis )

   LOCAL nPdvIznos
   LOCAL i

   IF nRecno == nil
      nRecno := suban->( RecNo() )
      cIdFirma := suban->IdFirma
      cIdVn := suban->IdVn
      cBrNal := suban->brNal
      cBrDok := suban->BrDok
      nRbr := suban->Rbr
      cOpis := suban->opis
   ENDIF

   PushWa()
   SELECT SUBAN
   PushWA()

   // SELECT suban_2
   SELECT suban

   nPdvIznos := 0

   FOR i := -15 TO 15

      GO ( nRecNo )
      SKIP i

      cKto := Left( idkonto, 3 )

      IF cKto $ AllTrim( gKt_updv ) .AND. ( IdFirma ==  cIdFirma ) .AND. ( IdVn == cIdVn ) .AND. ( BrNal == cBrNal ) .AND. ;
            ( ( !Empty( BrDok ) .AND. ( BrDok == cBrDok ) ) .OR. opis_i_oznaka( cOpis, opis ) )

         IF d_p == "1"
            nPdvIznos := iznosbhd
         ELSE
            nPdvIznos := -iznosbhd
         ENDIF

         PopWa()
         PopWa()
         RETURN nPdvIznos
      ENDIF

   NEXT

   PopWa()
   PopWa()

   RETURN nPdvIznos


// ----------------------------
// opis ista oznaka
// pretpostavlja se ovaj format
// opis: "neki_tekst<SEPARATOR>oznaka"
// oznaka slova brojeve
// <SEPARATOR> = ".", SPACE
// ----------------------------
FUNCTION opis_i_oznaka( cOpis1, cOpis2 )

   LOCAL cOzn1, cOzn2

   cOzn1 := extract_oznaka( cOpis1 )
   cOzn2 := extract_oznaka( cOpis2 )

   IF Empty( cOzn1 ) .OR. Empty( cOzn2 )
      RETURN .F.
   ENDIF

   RETURN ( cOzn1 == cOzn2 )

// ---------------------------------
// ekstraktuje oznaku koja se nalazi
// na kraju stringa
// "SPEDITER 16/06 => "16/06"
// "FAKT.DOB.16/06 => "16/06"
// ---------------------------------
STATIC FUNCTION extract_oznaka( cOpis )

   LOCAL i, nLen, cPom, cChar

   cPom := ""

   cOpis := Trim( cOpis )
   nLen := Len( cOpis )
   FOR i := nLen TO 1 STEP -1
      cChar := SubStr( cOpis, i, 1 )
      IF cChar $ " ."
         EXIT
      ELSE
         cPom := cChar + cPom
      ENDIF
   NEXT

   RETURN cPom


/*
   trazi odredjeni konto unutar tekuceg naloga
*/

FUNCTION epdv_trazi_konto_unutar_naloga( cIdKonto, nRecNo, cIdFirma, cIdVn, cBrNal, cBrDok, nRbr, cOpis )

   LOCAL nIznos := 0
   LOCAL i

   cIdKonto := PadR( cIdKonto, Len( suban->IdKonto ) )
   IF nRecno == nil
      nRecno := suban->( RecNo() )
      cIdFirma := suban->IdFirma
      cIdVn := suban->IdVn
      cBrNal := suban->brNal
      cBrDok := suban->BrDok
      nRbr := suban->Rbr
      cOpis := suban->opis
   ENDIF

   PushWa()
   SELECT SUBAN
   PushWA()

   // SELECT suban_2
   SELECT suban
   SET FILTER TO

   FOR i := -15 TO 15

      GO ( nRecNo )
      SKIP i

      IF ( cIdKonto == IdKonto ) .AND. ( IdFirma ==  cIdFirma ) .AND. ( IdVn == cIdVn ) .AND. ( BrNal == cBrNal ) .AND. ( BrDok == cBrDok )

         IF ( d_p == "1" )
            nIznos := iznosbhd
         ELSE
            nIznos := -iznosbhd
         ENDIF

         PopWa()
         PopWa()
         RETURN nIznos
      ENDIF

   NEXT

   PopWa()
   PopWa()

   RETURN nIznos


// sg_kuf formile koriste funkciju ovog imena

FUNCTION trazi_kto( cIdKonto, nRecNo, cIdFirma, cIdVn, cBrNal, cBrDok, nRbr, cOpis )
   RETURN epdv_trazi_konto_unutar_naloga( cIdKonto, nRecNo, cIdFirma, cIdVn, cBrNal, cBrDok, nRbr, cOpis )
