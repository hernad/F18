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
STATIC cKalkPath
STATIC cSifPath
STATIC cPm
STATIC cTDSrc
STATIC nZaok
STATIC nZaok2
STATIC cIdTar
STATIC cIdPart

STATIC cSBRdok  // setuj broj dokumenta
STATIC cOpis

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

FUNCTION tops_kif( dD1, dD2, cSezona )

   // {
   LOCAL nCount
   LOCAL cIdfirma

   IF cSezona == nil
      cSezona := ""
   ENDIF

   dDatOd := dD1
   dDatDo := dD2

   epdv_otvori_kif_priprema()

   SELECT F_SG_KIF
   IF !Used()
      o_sg_kif()
   ENDIF

   SELECT sg_kif
   GO TOP
   nCount := 0
   DO WHILE !Eof()

      nCount ++

      IF Upper( aktivan ) == "N"
         SKIP
         LOOP
      ENDIF

      @ box_x_koord() + 1, box_y_koord() + 2 SAY "SG_KIF : " + Str( nCount )

      IF g_src_modul( src ) == "POS"

         cTdSrc := td_src

         // set id tarifu u kif dokumentu
         cIdTar := s_id_tar
         cIdPart := s_id_part

         cKatP := kat_p
         cKatP2 := kat_p_2

         cOpis := naz

         cRazbDan := razb_dan

         IF !Empty( id_kto )
            cPm := PadR( id_kto, 2 )
         ENDIF

         // setuj broj dokumenta
         cSBRdok := s_br_dok

         PRIVATE cFormBPdv := form_b_pdv
         PRIVATE cFormPdv := form_pdv


         PRIVATE cTarFormula := ""
         PRIVATE cTarFilter := ""


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


         nZaok := zaok
         nZaok2 := zaok2

         // za jednu shema gen stavku formiraj kif
         gen_sg_item( cSezona )

      ENDIF

      SELECT sg_kif
      SKIP

   ENDDO


   // ------------------------------------------
   // ------------------------------------------

STATIC FUNCTION  gen_sg_item( cSezona )

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

   // za jedan dokument
   LOCAL dDMinD
   LOCAL dDMaxD

   LOCAL lSkip
   LOCAL nCijena

   LOCAL cIdPos

   // otvori pos tabelu
   // ------------------------------------------


   cPomPath :=  "POS"
   cPomSPath :=  ""

   SELECT ( F_POS )
   cKalkPath := cPomPath
   IF Used()
      USE
   ENDIF
   my_use ( cPomPath )

   cSifPath := cPomSPath


   //SELECT F_TARIFA
   //IF !Used()
  //    o_tarifa()
   //ENDIF

   //SELECT F_SIFK
  // IF !Used()
//      o_sifk()
//   ENDIF

//   SELECT F_SIFV
//   IF !Used()
//      o_sifv()
//   ENDIF


   SELECT POS
   PRIVATE cFilter := ""


   cFilter :=  dbf_quote( dDatOd ) + " <= datum .and. " + dbf_quote( dDatDo ) + ">= datum"

   // setuj tip dokumenta
   cFilter :=  cFilter + ".and. IdVD == " + dbf_quote( cTdSrc )

   IF !Empty( cTarFilter )
      cFilter += ".and. " + cTarFilter
   ENDIF

   IF !Empty( cPm )
      cFilter +=  ".and. IdPos == " + dbf_quote( cPm )
   ENDIF


   // "1", "IdPos+IdVd+dtos(datum)+BrDok+IdRoba+IdCijena"
   SET ORDER TO TAG "1"
   SET FILTER TO &cFilter

   GO TOP

   // prosetajmo kroz pos tabelu
   nCount := 0
   DO WHILE !Eof()

      // napuni P_KIF i setuj mem vars
      // ----------------------------------------------
      SELECT p_kif
      Scatter()
      // ----------------------------------------------


      SELECT POS
      dDMin := datum
      dDMax := datum

      // ove var moraju biti private da bi se mogle macro-om evaluirati
      PRIVATE _uk_b_pdv := 0
      PRIVATE _popust := 0

      DO WHILE !Eof() .AND.  ( datum == dDMax )

         SELECT pos

         cBrdok := pos->brdok
         cIdTipDok := pos->idvd
         cIdPos := pos->IdPos

         // datum kif-a
         _datum := pos->datum
         _id_part := ""
         _opis := cOpis

         IF !Empty( cIdPart )
            _id_part := cIdPart
         ENDIF

         // lIno := partner_is_ino(_id_part)
         // lPdvObveznik := partner_is_pdv_obveznik(_id_part)

         lIno := .F.
         lPdvObveznik := .F.

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

            // samo ne-pdv obveznici, ako je ino preskoci
            IF lIno
               lSkip := .T.
            ENDIF

         CASE cKatP == "3"
            // ino
            IF !lIno
               lSkip := .T.
            ENDIF

         ENDCASE


         nCount ++

         cPom := "TOPS : " + cIdPos + "-" + cIdTipDok + "-" + cBrDok
         @ box_x_koord() + 3, box_y_koord() + 2 SAY cPom

         cPom := "TOPS cnt : " + Str( nCount, 6 )
         @ box_x_koord() + 4, box_y_koord() + 2 SAY cPom


         // tarifa koja se nalazi unutar dokumenta
         cDokTar := ""

         SELECT POS


         dDMinD := datum
         dDMaxD := datum

         DO WHILE !Eof() .AND. cBrDok == brdok .AND. cIdTipDok == IdVd .AND. cIdPos == IdPos
            IF lSkip
               SKIP
               LOOP
            ENDIF

            // na nivou dokumenta utvrdi min max datum
            IF dDMinD > datum
               dDMinD := datum
            ENDIF

            IF dDMaxD < datum
               dDMaxD := datum
            ENDIF

            // na nivou dat opsega utvrdi min max datum
            IF dDMin > datum
               dDMinD := datum
            ENDIF

            IF dDMax < datum
               dDMax := datum
            ENDIF


            // pozicioniraj se na artikal u sifranriku robe
            select_o_roba( pos->idroba )
            SELECT POS

            cDokTar := pos->idTarifa
            _id_tar := pos->idTarifa

            nCijena := cijena / ( 1 + get_stopa_pdv_za_tarifu( cDokTar ) / 100 )
            // u posu se pohranjuje vrijednost u KM popusta
            // u odnosu na cijenu

            // vrati popust
            nCPopust := tops_popust()

            // izracuna koliko je to bez pdv-a
            nCPopust := nCPopust / ( 1 + get_stopa_pdv_za_tarifu( cDokTar ) / 100 )

            _uk_b_pdv += Round( kolicina * ( nCijena - nCPopust ), nZaok )
            _popust +=  Round( kolicina * ( nCPopust ), nZaok )

            SELECT POS
            SKIP
         ENDDO


         IF ( cRazbDan == "D" )
            // razbij po danima
            IF dDMinD <> dDMaxD
               MsgBeep( "U dokumentu " + cIdPos + "-" + cIdTipDok + "-" + cBrDok + "  se nalaze datumi " + DToC( dDMaxD ) + "-" + DToC( dDMaxD ) + "##" + ;
                  "To nije uredu je se promet razbija po danima !!!" )
            ENDIF

         ENDIF

         IF cRazbDan <> "D"
            // nije po danima
            // za jedan dokument se uzima
            EXIT
            // ako pak jeste "D" onda se vrti u petlji
         ENDIF

         // datumski interval
      ENDDO

      // za datum uzmi datum dokumenta ili najveci datum gore pronadjen
      _datum := dDMax

      IF lSkip
         // vrati se gore
         SELECT POS
         LOOP
      ENDIF

      _uk_b_pdv := Round( _uk_b_pdv, nZaok2 )
      _uk_popust := Round( _popust, nZaok2 )

      IF !Empty( cIdTar )
         // uzmi iz sg sifrarnika tarifu kojom treba setovati
         _id_tar := cIdTar
      ELSE
         // uzmi iz dokumenta
         _id_tar := cDokTar
      ENDIF

      IF !Empty( cSBrDok )
         _src_br := cSBrDok
         _src_br_2 := cSBrDok
      ELSE

         // broj dokumenta
         _src_br := cBrDok
         _src_br_2 := cBrDok
      ENDIF



      PRIVATE _uk_pdv :=  _uk_b_pdv * (  get_stopa_pdv_za_tarifu( _id_tar ) / 100 )

      IF !Empty( cFormBPDV )
         _i_b_pdv := &cFormBPdv
      ELSE
         // nema formule koristi ukupan iznos bez pdv-a
         _i_b_pdv := _uk_b_pdv
      ENDIF
      _i_b_pdv := Round( _i_b_pdv, nZaok )

      IF !Empty( cFormPDV )
         _i_pdv := &cFormPdv
      ELSE
         // nema formule koristi ukupan iznos bez pdv-a
         _i_pdv :=  _uk_pdv
      ENDIF
      _i_pdv := Round( _i_pdv, nZaok )

      // snimi gornje podatke
      SELECT P_KIF
      APPEND BLANK
      Gather()


      SELECT POS
   ENDDO

   RETURN .T.


STATIC FUNCTION tops_popust()


   RETURN pos->NCijena
