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



FUNCTION kalk_prenos_fakt()

   LOCAL cIdFirma := self_organizacija_id(), cIdTipDok := "10", cBrDok := Space( 8 ), cBrFakt
   LOCAL cDir := Space( 25 ), cFaktFirma := "", lRJKonto := .F.
   LOCAL lRJKon97 := .F.
   LOCAL lRJKon97_2 := .F.
   LOCAL cFF97 := ""
   LOCAL cFF97_2 := ""
   LOCAL cIdFakt97 := "01"
   LOCAL cIdFakt97_2 := "19"

   //cOldVar10 := my_get_from_ini( "PrenosKALK10_FAKT", "NazivPoljaCijeneKojaSePrenosiIzKALK", "-", KUMPATH )   // nekad bilo FCJ
   //cOldVar16 := my_get_from_ini( "PrenosKALK16_FAKT", "NazivPoljaCijeneKojaSePrenosiIzKALK", "-", KUMPATH )   // nekad bilo NC

   //o_fakt_dbf()

   o_fakt_pripr()
   //o_partner()
   //o_konto()
   o_kalk_pripr()
   //o_rj()

   SET ORDER TO TAG "ID"
   SELECT kalk_pripr

   Box(, 3, 60 )

   DO WHILE .T.

      cIdFirma := kalk_pripr->idfirma

      //SELECT RJ
      //GO TOP

      IF kalk_pripr->idvd $ "97"
         EXIT
      ELSE
         cFaktFirma := cIdFirma
      ENDIF

      SELECT kalk_pripr

      // cFaktFirma je uvedena za slucaj komisiona koji se treba voditi u
      // FAKT-u pod drugom radnom jedinicom (definicija u parametrima - gKomFakt)
      // gKomKonto je konto komisiona definisan takodje u parametrima

      IF kalk_pripr->idvd == "16" .AND. kalk_pripr->idkonto == gKomKonto
         cFaktFirma := gKomFakt
      ENDIF

      cIdTipDok := kalk_pripr->idvd
      cBrDok := kalk_pripr->brdok

      READ

      //SELECT fakt

      PRIVATE gNumDio := 5
      PRIVATE cIdFakt := ""

      IF kalk_pripr->idvd $ "97"

         cBrFakt := cIdTipDok + "-" + Right( AllTrim( cBrDok ), 5 )

         IF lRJKon97

         @ box_x_koord() + 2, box_y_koord() + 2 SAY "Broj dokumenta u modulu FAKT: " + cFF97 + " - " + cIdFakt97 + " - " + cBrFakt

            //SEEK cFF97 + cIdFakt97 + cBrFakt
            IF find_fakt_dokument( cFF97, cIdFakt97, cBrFakt )
            //IF Found()
               Beep( 4 )
               Box(, 1, 50 )
               @ box_x_koord() + 1, box_y_koord() + 2 SAY8 "U FAKT već postoji ovaj dokument !!"
               Inkey( 0 )
               BoxC()
               EXIT
            ENDIF

         ENDIF

         IF lRJKon97_2
            //SEEK cFF97_2 + cIdFakt97_2 + cBrFakt

            @ box_x_koord() + 3, box_y_koord() + 2 SAY "Broj dokumenta u modulu FAKT: " + cFF97_2 + " - " + cIdFakt97_2 + " - " + cBrFakt

            //IF Found()
            IF find_fakt_dokument( cFF97_2, cIdFakt97_2, cBrFakt )
               Beep( 4 )
               Box(, 1, 50 )
               @ box_x_koord() + 1, box_y_koord() + 2 SAY8 "U FAKT već postoji ovaj dokument !!"
               Inkey( 0 )
               BoxC()
               EXIT
            ENDIF
         ENDIF

      ELSEIF kalk_pripr->idvd $ "10#16#PR#RN"

         cIdFakt := "01"
         cBrFakt := fakt_novi_broj_dokumenta( cFaktFirma, cIdFakt )

         //SEEK cFaktFirma + cIdFakt + cBrFakt
         //find_fakt_dokument( cFaktFirma, cIdFakt, cBrFakt )

      ELSE

         IF kalk_pripr->idvd $ "11#12#13"
            cIdFakt := "13"
         ELSEIF kalk_pripr->idvd $ "95#96"
            cIdFakt := "19"
         ENDIF

         cBrFakt := fakt_novi_broj_dokumenta( cFaktFirma, cIdFakt )

         //SEEK cFaktFirma + cIdFakt + cBrFakt
         //find_fakt_dokument( cFaktFirma, cIdFakt, cBrFakt )

      ENDIF

      IF kalk_pripr->idvd <> "97"

         @ box_x_koord() + 2, box_y_koord() + 2 SAY "Broj dokumenta u modulu FAKT: " + cFaktFirma + " - " + cIdFakt + " - " + cBrFakt

         IF find_fakt_dokument( cFaktFirma, cIdFakt, cBrFakt )
            Beep( 4 )
            Box(, 1, 50 )
            @ box_x_koord() + 1, box_y_koord() + 2 SAY8 "U FAKT već postoji ovaj dokument !!"
            Inkey( 0 )
            BoxC()
            EXIT
         ENDIF

      ENDIF

      SELECT kalk_pripr

      fFirst := .T.

      DO WHILE !Eof() .AND. cIdFirma + cIdTipDok + cBrDok == kalk_pripr->IdFirma + kalk_pripr->IdVD + kalk_pripr->BrDok

         PRIVATE nKolicina := kalk_pripr->( kolicina - gkolicina - gkolicin2 )

         IF kalk_pripr->idvd $ "12#13"
            // ove transakcije su storno otpreme
            nKolicina := -nKolicina
         ENDIF

         IF kalk_pripr->idvd $ "PR#RN"
            IF kalk_pripr->rbr > 899
               SKIP
               LOOP
            ENDIF
         ENDIF

         SELECT fakt_pripr


    //     ELSEIF ( kalk_pripr->idvd == "16" ) // .AND. IsVindija() )
    //        APPEND BLANK
    //        REPLACE kolicina WITH nKolicina



            HSEEK cFaktFirma + cIdFakt + cBrFakt + TRANSFORM(kalk_pripr->rbr, '999')
            IF Found()
               RREPLACE kolicina WITH kolicina + nkolicina
            ELSE
               APPEND BLANK
               REPLACE kolicina WITH nkolicina
            ENDIF


         IF fFirst

               select_o_partner( kalk_pripr->idpartner )

               IF kalk_pripr->idvd $ "11#12#13#95#PR#RN"
                  select_o_konto( kalk_pripr->idkonto )
                  cTxta := PadR( kalk_pripr->idkonto, 30 )
                  cTxtb := PadR( konto->naz, 30 )
                  cTxtc := PadR( "", 30 )
               ELSE
                  cTxta := PadR( naz, 30 )
                  cTxtb := PadR( naz2, 30 )
                  cTxtc := PadR( mjesto, 30 )
               ENDIF

               Inkey( 0 )

               cTxt := Chr( 16 ) + " " + Chr( 17 ) + ;
                  Chr( 16 ) + " " + Chr( 17 ) + ;
                  Chr( 16 ) + cTxta + Chr( 17 ) + Chr( 16 ) + cTxtb + Chr( 17 ) + ;
                  Chr( 16 ) + cTxtc + Chr( 17 )

               fFirst := .F.

               SELECT fakt_pripr
               RREPLACE txt WITH cTxt

         ENDIF

         FOR i := 1 TO 2


               RREPLACE idfirma WITH IF( cFaktFirma != cIdFirma .OR. lRJKonto, cFaktFirma, kalk_pripr->idfirma ), ;
                    rbr WITH TRANSFORM(kalk_pripr->Rbr, '999'),;
                    idtipdok WITH cIdFakt, brdok WITH cBrFakt


            my_rlock()

            REPLACE idpartner WITH kalk_pripr->idpartner
            REPLACE datdok WITH kalk_pripr->datdok
            REPLACE idroba WITH kalk_pripr->idroba
            REPLACE cijena WITH kalk_pripr->vpc      // bilo je fcj sto je pravo bezveze
            REPLACE rabat WITH 0               // kakav crni rabat
            REPLACE dindem WITH "KM "

            //IF kalk_pripr->idvd == "10" .AND. cOldVar10 <> "-"
            //   REPLACE cijena WITH kalk_pripr->( &cOldVar10 )
            //ELSEIF kalk_pripr->idvd == "16" .AND. cOldVar16 <> "-"
            //   REPLACE cijena WITH kalk_pripr->( &cOldVar16 )

            IF kalk_pripr->idvd $ "11#12#13"
               REPLACE cijena WITH kalk_pripr->mpcsapp   // ove dokumente najvise interesuje mpc!
            ELSEIF kalk_pripr->idvd $ "PR#RN"
               REPLACE cijena WITH kalk_pripr->vpc
            ELSEIF kalk_pripr->idvd $ "95"
               REPLACE cijena WITH kalk_pripr->VPC
            ELSEIF kalk_pripr->idvd $ "16"
               REPLACE cijena WITH kalk_pripr->vpc       // i ovdje je bila nc pa sam stavio vpc
            ENDIF

            my_unlock()

            IF kalk_pripr->idvd <> "97"
               EXIT
            ENDIF
         NEXT

         SELECT kalk_pripr
         SKIP
      ENDDO

      Beep( 1 )

      EXIT
   ENDDO
   Boxc()

   my_close_all_dbf()

   // fakt trazi ove varijabl
   glRadNal := .F.
   glDistrib := .F.

   fakt_azuriraj_dokumente_u_pripremi( .T. )

   my_close_all_dbf()

   RETURN .T.
