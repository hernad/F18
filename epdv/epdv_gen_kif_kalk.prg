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
STATIC cTDSrc
STATIC nZaok
STATIC nZaok2
STATIC cIdTar
STATIC cIdPart
STATIC cSBRdok
STATIC cOpis
STATIC cKatP
STATIC cKatP2
STATIC cRazbDan

FUNCTION kalk_kif( dD1, dD2, cSezona )

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

      IF g_src_modul( src ) == "KALK"

         cTdSrc := td_src

         // set id tarifu u kif dokumentu
         cIdTar := s_id_tar
         cIdPart := s_id_part

         cKatP := kat_p
         cKatP2 := kat_p_2

         cOpis := naz

         cRazbDan := razb_dan

         // setuj broj dokumenta
         cSBRdok := s_br_dok

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

         gen_kalk_kif_item( cSezona )

      ENDIF

      SELECT sg_kif
      SKIP

   ENDDO



FUNCTION close_open_kalk_epdv_tables()

   //o_kalk()
   close_open_kuf_kif_sif()

   RETURN .T.



STATIC FUNCTION gen_kalk_kif_item( cSezona )

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
   LOCAL cBrFaktP

   close_open_kalk_epdv_tables()

   find_kalk_za_period( self_organizacija_id(), cTdSrc, NIL, NIL, dDatOd, dDatDo )

   SELECT KALK
   PRIVATE cFilter := ".T."

   //cFilter :=  dbf_quote( dDatOd ) + " <= datdok .and. " + dbf_quote( dDatDo ) + ">= datdok"
   //cFilter :=  cFilter + ".and. IdVD == " + dbf_quote( cTdSrc ) // setuj tip dokumenta

   IF !Empty( cTarFilter )
      cFilter += ".and. " + cTarFilter
   ENDIF

   IF !Empty( cKtoFilter )
      cFilter +=  ".and. " + cKtoFilter
   ENDIF

   //SET ORDER TO TAG "1"  // "1","IdFirma+idtipdok+brdok+rbr+podbr"
   SET FILTER TO &cFilter
   GO TOP

   // prosetajmo kroz kalk tabelu
   nCount := 0
   DO WHILE !Eof()

      // napuni P_KIF i setuj mem vars
      // ----------------------------------------------
      SELECT p_kif
      Scatter()

      SELECT KALK

      dDMin := datdok
      dDMax := datdok

      // ove var moraju biti private da bi se mogle macro-om evaluirati
      PRIVATE _uk_b_pdv := 0
      PRIVATE _popust := 0

      // datumski period
      DO WHILE !Eof() .AND.  ( datdok == dDMax )

         SELECT kalk

         cBrdok := kalk->brdok

         cIdTipDok := kalk->idvd
         cIdFirma := kalk->IdFirma

         // datum kif-a
         _datum := kalk->datdok
         _id_part := kalk->idpartner
         _opis := cOpis

         IF !Empty( cIdPart )
            _id_part := cIdPart
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



         nCount ++

         cPom := "KALK : " + cIdFirma + "-" + cIdTipDok + "-" + cBrDok
         @ box_x_koord() + 3, box_y_koord() + 2 SAY cPom

         cPom := "KALK cnt : " + Str( nCount, 6 )
         @ box_x_koord() + 4, box_y_koord() + 2 SAY cPom



         // tarifa koja se nalazi unutar dokumenta
         cDokTar := ""


         dDMinD := datdok
         dDMaxD := datdok


         // broj fakture partnera
         cBrFaktP := kalk->brfaktp

         DO WHILE !Eof() .AND. cBrDok == brdok .AND. cIdTipDok == IdVd .AND. cIdFirma == IdFirma
            IF lSkip
               SKIP
               LOOP
            ENDIF

            // na nivou dokumenta utvrdi min max datum
            IF dDMinD > datdok
               dDMinD := datdok
            ENDIF

            IF dDMaxD < datdok
               dDMaxD := datdok
            ENDIF

            // na nivou dat opsega utvrdi min max datum
            IF dDMin > datdok
               dDMinD := datdok
            ENDIF

            IF dDMax < datdok
               dDMax := datdok
            ENDIF

            select_o_roba( kalk->idroba )
            SELECT KALK
            cDokTar := roba->idTarifa

            _id_tar := kalk->idTarifa


            IF cTDSrc $ "41#42"
               nCijena := mpc
               // u gornjoj cijeni je uracunat popust
               nPopust := 0

            ELSEIF cTdSrc $ "14#11"
               nCijena := vpc
               nPopust := rabatv

            ELSE
               nCijena := vpc
               nPopust := rabatv
            ENDIF



            _uk_b_pdv += Round( kolicina * ( nCijena * ( 1 - nPopust / 100 ) ), nZaok )
            _popust +=  Round( kolicina * ( nCijena *  nPopust / 100 ), nZaok )

            SELECT KALK
            SKIP
         ENDDO


         IF ( cRazbDan == "D" )
            // razbij po danima
            IF dDMinD <> dDMaxD
               MsgBeep( "U dokumentu " + cIdFirma + "-" + cIdTipDok + "-" + cBrDok + "  se nalaze datumi " + DToC( dDMaxD ) + "-" + DToC( dDMaxD ) + "##" + ;
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
         SELECT KALK
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
         _src_br := cBrFaktP
         _src_br_2 := cBrFaktP
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


      SELECT KALK
   ENDDO

   RETURN
