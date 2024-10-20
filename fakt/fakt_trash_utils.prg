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


// -------------------------------------
// opcija pregleda smeca
// -------------------------------------

FUNCTION Pripr9View()

   PRIVATE aUslFirma := self_organizacija_id()
   PRIVATE aUslDok := Space( 50 )
   PRIVATE dDat1 := CToD( "" )
   PRIVATE dDat2 := Date()

   Box(, 10, 60 )
   @ 1 + box_x_koord(), 2 + box_y_koord() SAY "Uslovi pregleda smeca:" COLOR f18_color_i()
   @ 3 + box_x_koord(), 2 + box_y_koord() SAY "Firma (prazno-sve)" GET aUslFirma PICT "@S40"
   @ 4 + box_x_koord(), 2 + box_y_koord() SAY "Vrste dokumenta (prazno-sve)" GET aUslDok PICT "@S20"
   @ 5 + box_x_koord(), 2 + box_y_koord() SAY "Datum od" GET dDat1
   @ 5 + box_x_koord(), 20 + box_y_koord() SAY "do" GET dDat2
   READ
   BoxC()

   IF LastKey() == K_ESC
      RETURN
   ENDIF

   // postavi filter
   P9SetFilter( aUslFirma, aUslDok, dDat1, dDat2 )

   //PRIVATE gVarijanta := "2"

   PRIVATE PicV := "99999999.9"
   ImeKol := { ;
      { "F.", {|| IdFirma                  }, "IdFirma"     }, ;
      { "VD", {|| IdTipDok                 }, "IdTipDok"    }, ;
      { "BrDok", {|| BrDok                    }, "BrDok"       }, ;
      { "Dat.dok", {|| DatDok                   }, "DatDok"      }, ;
      { "Partner", {|| PadR( _get_partner( idpartner ), 50 )  }, "idpartner" } ;
      }

   Kol := {}
   FOR i := 1 TO Len( ImeKol )
      AAdd( Kol, i )
   NEXT

   Box(, 20, 77 )
   @ box_x_koord() + 17, box_y_koord() + 2 SAY "<c-T>  Brisi stavku                              "
   @ box_x_koord() + 18, box_y_koord() + 2 SAY "<c-F9> Brisi sve     "
   @ box_x_koord() + 19, box_y_koord() + 2 SAY "<P> Povrat dokumenta u pripremu "
   @ box_x_koord() + 20, box_y_koord() + 2 SAY "               "

   my_browse( "PRIPR9", 20, 77, {|| fa_pripr9_key_handler() }, "<P>-povrat dokumenta u pripremu", "Pregled smeca...", , , , , 4 )
   BoxC()

   RETURN


FUNCTION fa_pripr9_key_handler()

   DO CASE
   CASE Ch == K_CTRL_T
      // brisanje dokumenta iz pripr9
      fakt_brisi_smece( idfirma, idtipdok, brdok )
      RETURN DE_REFRESH
   CASE Ch == k_ctrl_f9()
      // brisanje kompletnog pripr9
      bris_svo_smece()
      RETURN DE_REFRESH
   CASE Chr( Ch ) $ "pP" // povrat dokumenta u pripremu
      PovPr9()
      P9SetFilter( aUslFirma, aUslDok, dDat1, dDat2 )
      RETURN DE_REFRESH
   ENDCASE

   RETURN DE_CONT

   RETURN


STATIC FUNCTION PovPr9()

   LOCAL nArr

   nArr := Select()

   povrat_smece( idfirma, idtipdok, brdok )

   SELECT ( nArr )

   RETURN DE_CONT



STATIC FUNCTION P9SetFilter( aUslFirma, aUslDok, dDat1, dDat2 )

   O_FAKT_PRIPR9
   SET ORDER TO TAG "1"

   // obavezno postavi filter po rbr
   cFilter := "rbr == '  1'"

   IF !Empty( aUslFirma )
      cFilter += " .and. idfirma='" + aUslFirma + "'"
   ENDIF

   IF !Empty( aUslDok )
      aUslDok := Parsiraj( aUslDok, "idtipdok" )
      cFilter += " .and. " + aUslDok
   ENDIF

   IF !Empty( dDat1 )
      cFilter += " .and. datdok >= " + dbf_quote( dDat1 )
   ENDIF

   IF !Empty( dDat2 )
      cFilter += " .and. datdok <= " + dbf_quote( dDat2 )
   ENDIF

   SET FILTER to &cFilter

   GO TOP

   RETURN .T.


STATIC FUNCTION _get_partner( cIdPartner )

   LOCAL nTArea
   LOCAL cPartner

   nTArea := Select()
   IF select_o_partner( cIdPartner )
      cPartner := field->naz
   ELSE
      cPartner := "????????"
   ENDIF

   SELECT ( nTArea )

   RETURN cPartner



// -------------------------------------------------
// brisi dokument iz smeca
// -------------------------------------------------
FUNCTION fakt_brisi_smece( cIdF, cIdTipDok, cBrDok )

   IF Pitanje(, "Sigurno zelite izbrisati dokument?", "N" ) == "N"
      RETURN .F.
   ENDIF

   SELECT fakt_pripr9
   SEEK cIdF + cIdTipDok + cBrDok // fakt_pripr9
   my_flock()
   DO WHILE !Eof() .AND. cIdF == IdFirma .AND. cIdTipDok == Idtipdok .AND. cBrDok == BrDok
      SKIP 1
      nRec := RecNo()
      SKIP -1
      DELETE
      GO nRec
   ENDDO
   my_unlock()
   my_dbf_pack()

   RETURN .T.

// -------------------------------------------
// brisi sve iz smeca
// -------------------------------------------
FUNCTION bris_svo_smece()

   IF Pitanje( , "Sigurno zelite izbrisati sve zapise?", "N" ) == "N"
      RETURN
   ENDIF

   SELECT fakt_pripr9
   GO TOP
   my_dbf_zap()

   nTArea := Select()


   SELECT ( nTArea )

   RETURN

FUNCTION azuriraj_smece( lSilent )

   IF lSilent == nil
      lSilent := .F.
   ENDIF

   IF lSilent == .F. .AND. Pitanje( "p1", "Želite li dokument prebaciti u smece (D/N) ?", "D" ) == "N"
      RETURN
   ENDIF

   O_FAKT_PRIPR9
   o_fakt_pripr()

   lFound := .F.
   nCount := 0

   DO WHILE !Eof()

      ++ nCount
      lFound := .F.
      nRecNo := RecNo()

      cIdfirma := idfirma
      cIdTipDok := idtipdok
      cBrDok := brdok

      DO WHILE !Eof() .AND. idfirma == cIdFirma .AND. idtipdok == cIdtipdok  .AND. brdok == cBrDok
         SKIP
      ENDDO

      SELECT fakt_pripr9
      SEEK cIdFirma + cIdtipdok + cBrDok // fakt_pripr9

      IF Found()
         // ima vec u smecu !
         lFound := .T.

         IF lSilent == .F.
            MsgBeep( "U smecu vec postoji isti dokument !" )
            closeret
         ENDIF

      ENDIF

      SELECT fakt_pripr

      IF lFound == .T.

         GO ( nRecNO )

         my_flock()
         // zamjeni brdok sa 00001-1
         DO WHILE !Eof() .AND. idfirma == cIdFirma ;
               .AND. idtipdok == cIdTipDok ;
               .AND. brdok == cBrDok

            REPLACE brdok WITH PadR( brdok, 5 ) + "-" + AllTrim( Str( nCount ) )
            SKIP
         ENDDO
         my_unlock()

         GO ( nRecNo )

      ENDIF

   ENDDO

   SELECT fakt_pripr
   GO TOP

   DO WHILE !Eof()

      _rec := dbf_get_rec()

      SELECT fakt_pripr9
      APPEND BLANK
      dbf_update_rec( _rec )

      SELECT fakt_pripr
      SKIP

   ENDDO

   SELECT fakt_pripr
   my_dbf_zap()

   IF lSilent == .F.
      my_close_all_dbf()
   ENDIF

   RETURN


// ---------------------------------------------------
// povrat dokumenta iz smeca
// ---------------------------------------------------
FUNCTION povrat_smece( cIdFirma, cIdtipdok, cBrDok )

   LOCAL nRec

   lSilent := .T.

   O_FAKT_PRIPR9
   o_fakt_pripr()

   SELECT fakt_pripr9
   SET ORDER TO TAG 1

   // ako nema parametara funkcije
   IF ( PCount() == 0 )
      lSilent := .F.
   ENDIF

   IF !lSilent
      cIdFirma := self_organizacija_id()
      cIdtipdok := Space( Len( field->idtipdok ) )
      cBrDok := Space( Len( field->brdok ) )
   ENDIF

   IF !lSilent
      Box( "", 1, 40 )
      @ box_x_koord() + 1, box_y_koord() + 2 SAY "Dokument:"
      @ box_x_koord() + 1, Col() + 1 GET cIdFirma
      @ box_x_koord() + 1, Col() + 1 SAY "-" GET cIdtipdok
      @ box_x_koord() + 1, Col() + 1 SAY "-" GET cBrdok
      READ
      ESC_BCR
      BoxC()
   ENDIF

   IF Pitanje( "", "Iz smeca " + cIdFirma + "-" + cIdtipdok + "-" + AllTrim( cBrDok ) + " povuci u pripremu (D/N) ?", "D" ) == "N"

      IF !lSilent
         my_close_all_dbf()
         RETURN .T.
      ELSE
         RETURN .T.
      ENDIF

   ENDIF

   SELECT fakt_pripr9
   HSEEK cIdFirma + cIdtipdok + cBrDok // fakt_pripr9

   MsgO( "PRIPREMA" )

   DO WHILE !Eof() .AND. cIdFirma == IdFirma .AND. cIdtipdok == Idtipdok .AND. cBrDok == BrDok
      SELECT fakt_pripr9
      Scatter()
      SELECT fakt_pripr
      APPEND BLANK
      _ERROR := ""
      Gather2()
      SELECT fakt_pripr9
      SKIP
   ENDDO

   SELECT fakt_pripr9
   SEEK cIdFirma + cIdTipDok + cBrDok // fakt_pripr9
   my_flock()
   DO WHILE !Eof() .AND. cIdFirma == IdFirma .AND. cIdtipdok == Idtipdok .AND. cBrDok == BrDok
      SKIP 1
      nRec := RecNo()
      SKIP -1
      DELETE
      GO nRec
   ENDDO
   my_unlock()

   USE

   MsgC()

   IF !lSilent
      my_close_all_dbf()
      RETURN .T.
   ENDIF

   O_FAKT_PRIPR9
   SELECT fakt_pripr9

   RETURN .T.
