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


FUNCTION kalk_pregled_smece_pripr9()

   LOCAL GetList := {}

   PRIVATE aUslFirma := self_organizacija_id()
   PRIVATE aUslDok := Space( 50 )
   PRIVATE dDat1 := CToD( "" )
   PRIVATE dDat2 := Date()

   Box(, 10, 60 )
   @ 1 + box_x_koord(), 2 + box_y_koord() SAY8 "Uslovi pregleda smeća:" COLOR f18_color_i()
   @ 3 + box_x_koord(), 2 + box_y_koord() SAY8 "Firma (prazno-sve)" GET aUslFirma PICT "@S40"
   @ 4 + box_x_koord(), 2 + box_y_koord() SAY8 "Vrste dokumenta (prazno-sve)" GET aUslDok PICT "@S20"
   @ 5 + box_x_koord(), 2 + box_y_koord() SAY8 "Datum od" GET dDat1
   @ 5 + box_x_koord(), 20 + box_y_koord() SAY8 "do" GET dDat2
   READ
   BoxC()

   IF LastKey() == K_ESC
      RETURN .F.
   ENDIF

   ka_pripr9_set_filter( aUslFirma, aUslDok, dDat1, dDat2 )

   // PRIVATE gVarijanta := "2"

   PRIVATE PicV := "99999999.9"
   ImeKol := { ;
      { "F.", {|| IdFirma }, "IdFirma"     }, ;
      { "VD", {|| IdVD }, "IdVD"        }, ;
      { "BrDok", {|| BrDok }, "BrDok"       }, ;
      { "Dat.Kalk", {|| DatDok }, "DatDok"      }, ;
      { "Mag konto", {|| mkonto  }, "mkonto"     }, ;
      { "Kto2", {|| IdKonto2  }, "IdKonto2"    }, ;
      { "Prod konto", {|| pkonto  }, "pkonto"    }, ;
      { "Br.Fakt", {|| brfaktp }, "brfaktp"     }, ;
      { "Partner", {|| idpartner }, "idpartner"   }, ;
      { "E", {|| error }, "error"       } ;
      }

   Kol := {}
   FOR i := 1 TO Len( ImeKol )
      AAdd( Kol, i )
   NEXT

   Box(, 20, 77 )
   @ box_x_koord() + 17, box_y_koord() + 2 SAY8 "<c-T>  Briši stavku                              "
   @ box_x_koord() + 18, box_y_koord() + 2 SAY8 "<c-F9> Briši sve     "
   @ box_x_koord() + 19, box_y_koord() + 2 SAY "<P> Povrat dokumenta u pripremu "
   @ box_x_koord() + 20, box_y_koord() + 2 SAY "               "

   IF gCijene == "1" .AND. kalk_metoda_nc() == " "
      Soboslikar( { { box_x_koord() + 17, box_y_koord() + 1, box_x_koord() + 20, box_y_koord() + 77 } }, 23, 14 )
   ENDIF

   // PRIVATE lKalkAsistentAuto := .F.

   my_browse( "KALK_PRIPR9", 20, 77, {|| ka_pripr9_key_handler() }, "<P>-povrat dokumenta u pripremu", _u("Pregled smeća..."), , , , , 4 )
   BoxC()

   RETURN .T.


/*
 *     Opcije pregleda smeca
 */
FUNCTION ka_pripr9_key_handler()

   LOCAL nArr

   DO CASE
   CASE Ch == K_CTRL_T // brisanje dokumenta iz kalk_pripr9
      kalk_del_smece_pripr9( idfirma, idvd, brdok )

      RETURN DE_REFRESH

   CASE Ch == k_ctrl_f9() // brisanje kompletnog kalk_pripr9
      kalk_pripr_smece_sve_izbrisati()
      RETURN DE_REFRESH

   CASE Chr( Ch ) $ "pP" // povrat dokumenta u kalk_pripremu


      nArr := Select()

      kalk_povrat_dokumenta_iz_pripr9( field->idfirma, field->idvd, field->brdok )

      SELECT ( nArr )
      RETURN DE_CONT

      ka_pripr9_set_filter( aUslFirma, aUslDok, dDat1, dDat2 )
      RETURN DE_REFRESH

   ENDCASE

   RETURN DE_CONT

   RETURN .T.




/* ka_pripr9_set_filter(aUslFirma, aUslDok, dDat1, dDat2)
 *     Postavlja filter na tabeli kalk_pripr9
 */
STATIC FUNCTION ka_pripr9_set_filter( aUslFirma, aUslDok, dDat1, dDat2 )

   o_kalk_pripr9()
   SET ORDER TO TAG "1"

   // obavezno postavi filter po rbr
   cFilter := "rbr == 1"

   IF !Empty( aUslFirma )
      cFilter += " .and. idfirma='" + aUslFirma + "'"
   ENDIF

   IF !Empty( aUslDok )
      aUslDok := Parsiraj( aUslDok, "idvd" )
      cFilter += " .and. " + aUslDok
   ENDIF

   IF !Empty( dDat1 )
      cFilter += " .and. datdok >= " + dbf_quote( dDat1 )
   ENDIF

   IF !Empty( dDat2 )
      cFilter += " .and. datdok <= " + dbf_quote( dDat2 )
   ENDIF

   SET FILTER TO &cFilter

   GO TOP

   RETURN .T.



FUNCTION kalk_del_smece_pripr9( cIdFirma, cIdVd, cBrDok )

   IF Pitanje(, "Sigurno želite izbrisati dokument?", "N" ) == "N"
      RETURN .F.
   ENDIF

   SELECT kalk_pripr9
   SET ORDER TO TAG "1"
   SEEK cIdFirma + cIdVd + cBrDok
   my_flock()
   DO WHILE !Eof() .AND. cIdFirma == kalk_pripr9->IdFirma .AND. cIdVD == kalk_pripr9->IdVD .AND. cBrDok == kalk_pripr9->BrDok
      SKIP 1
      nRec := RecNo()
      SKIP -1
      my_delete()
      GO nRec
   ENDDO
   my_unlock()

   RETURN .T.



STATIC FUNCTION kalk_pripr_smece_sve_izbrisati()

   IF Pitanje(, "Sigurno želite izbrisati sve iz smeća?", "N" ) == "N"
      RETURN .F.
   ENDIF

   SELECT kalk_pripr9
   GO TOP
   my_dbf_zap()

   RETURN .T.


STATIC FUNCTION Soboslikar( aNiz, nIzKodaBoja, nUKodBoja )

   LOCAL i, cEkran

   FOR i := 1 TO Len( aNiz )
      cEkran := SaveScreen( aNiz[ i, 1 ], aNiz[ i, 2 ], aNiz[ i, 3 ], aNiz[ i, 4 ] )
      cEkran := StrTran( cEkran, Chr( nIzKodaBoja ), Chr( nUKodBoja ) )
      RestScreen( aNiz[ i, 1 ], aNiz[ i, 2 ], aNiz[ i, 3 ], aNiz[ i, 4 ], cEkran )
   NEXT

   RETURN .T.
