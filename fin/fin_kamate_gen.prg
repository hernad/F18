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


FUNCTION prenos_fin_kam()

   LOCAL cIdKonto := PadR( "2110", 7 )
   LOCAL dDatObracuna := Date()
   LOCAL nMinimumDanaZaObracun := 0
   LOCAL _zatvorene := "D"
   LOCAL nDodajDanaDatValEmpty := 30
   LOCAL _partneri := Space( 100 )
   LOCAL _usl, _rec
   LOCAL _filter := ""
   LOCAL GetList := {}
   LOCAL cIdPartner, nOsnovniDug, cBrojDokumenta
   LOCAL nTekuciRec

   select_o_kam_pripr()
   o_konto()
   //o_partner()

   Box( "#PRENOS RACUNA ZA OBRACUN FIN->KAM", 8, 65 )

   @ box_x_koord() + 1, box_y_koord() + 2 SAY "Konto:         " GET cIdKonto VALID P_Konto( @cIdKonto )
   @ box_x_koord() + 2, box_y_koord() + 2 SAY "Datum obracuna:" GET dDatObracuna
   @ box_x_koord() + 3, box_y_koord() + 2 SAY "Uzeti u obzir samo racune cije je"
   @ box_x_koord() + 4, box_y_koord() + 2 SAY "valutiranje starije od (br.dana)" GET nMinimumDanaZaObracun PICT "9999999"
   @ box_x_koord() + 5, box_y_koord() + 2 SAY "Uzeti u obzir stavke koje su zatvorene? (D/N)" GET _zatvorene PICT "@!" VALID _zatvorene $ "DN"
   @ box_x_koord() + 6, box_y_koord() + 2 SAY "Ukoliko nije naveden datum valutiranja"
   @ box_x_koord() + 7, box_y_koord() + 2 SAY "na datum dokumenta dodaj (br.dana)    " GET nDodajDanaDatValEmpty PICT "99"
   @ box_x_koord() + 8, box_y_koord() + 2 SAY "Partneri" GET _partneri PICT "@!S50"

   DO WHILE .T.

      READ
      ESC_BCR

      _usl := Parsiraj( _partneri, "IdPartner", "C" )

      IF _usl <> NIL
         EXIT
      ENDIF

   ENDDO

   BoxC()

   MsgO( "Prenos podataka sa servera ..." )
   find_suban_by_konto_partner( self_organizacija_id(), cIdKonto, _partneri, NIL, "IdFirma,IdKonto,IdPartner,brdok" )
   MsgC()

   IF !Empty( _usl )
      _filter := _usl
      SET FILTER to &_filter
   ELSE
      SET FILTER TO
   ENDIF
   GO TOP

   DO WHILE !Eof() .AND. field->idkonto == cIdKonto .AND. field->idfirma == self_organizacija_id()

      cIdPartner := field->idpartner // osnovni dug
      nOsnovniDug := 0

      DO WHILE !Eof() .AND. field->idkonto == cIdKonto .AND. field->idpartner == cIdPartner .AND. field->idfirma == self_organizacija_id()

         cBrojDokumenta := field->brdok

         _duguje := 0
         _potrazuje := 0
         dDatOdZaBrDok := CToD( "" )

         cTmpBrDok := "XYZYXYYXXX"

         DO WHILE !Eof() .AND. field->idkonto == cIdKonto .AND. field->idpartner == cIdPartner ;
               .AND. field->brdok == cBrojDokumenta  .AND. field->idfirma == self_organizacija_id()

            IF ( field->brdok == cTmpBrDok ) .OR. ( field->datdok > dDatObracuna ) .OR. ;
               ( fix_dat_var( field->datval, .T. ) > dDatObracuna )
               SKIP
               LOOP
            ENDIF

            IF field->otvst = "9" .AND. _zatvorene == "N" // samo otvorene stavke
               IF field->d_p == "1"
                  nOsnovniDug += field->iznosbhd
               ELSE
                  nOsnovniDug -= field->iznosbhd
               ENDIF
               SKIP
               LOOP
            ENDIF

            IF field->d_p == "1"

               IF Empty( dDatOdZaBrDok )
                  IF Empty( fix_dat_var( field->datval, .T. ) )
                     dDatOdZaBrDok := field->datdok + nDodajDanaDatValEmpty
                  ELSE
                     dDatOdZaBrDok := fix_dat_var( field->datval, .T. ) // datum valutiranja
                  ENDIF
               ENDIF

               _duguje += field->iznosbhd
               nOsnovniDug += field->iznosbhd

            ELSE

               IF !Empty( dDatOdZaBrDok )  // vec je nastalo dugovanje
                  dDatOdZaBrDok := field->datdok
               ENDIF

               _potrazuje += field->iznosbhd
               nOsnovniDug -= field->iznosbhd

            ENDIF

            IF !Empty( dDatOdZaBrDok )

               SELECT kam_pripr

               IF ( field->idpartner + field->idkonto + field->brdok == cIdPartner + cIdKonto + cBrojDokumenta )
                  // vec postoji prosli dio racuna, njega zatvoriti sa predhodnim danom
                  IF field->datod >= dDatOdZaBrDok // slijedeca promjena na isti datum
                     RREPLACE field->osnovica WITH field->osnovica + suban->( iif( d_p == "1", iznosbhd, -iznosbhd ) )
                     SELECT suban
                     SKIP
                     LOOP
                  ELSE
                     RREPLACE field->datdo WITH dDatOdZaBrDok - 1
                  ENDIF

               ELSE // ovaj brdok se prvi put pojavljuje

                  // IF ( field->idpartner + field->idkonto + field->brdok <> cIdPartner + cIdKonto + cBrojDokumenta ) ;
                  // .AND. ( dDatObracuna - nMinimumDanaZaObracun < dDatOdZaBrDok ) // onda ne pohranjuj
                  IF ( dDatObracuna - nMinimumDanaZaObracun ) >= dDatOdZaBrDok
                     // cTmpBrDok := cBrojDokumenta
                     // ELSE
                     APPEND BLANK
                     RREPLACE idpartner WITH cIdPartner, ;
                        idkonto WITH cIdKonto, ;
                        osnovica WITH _duguje - _potrazuje, ;
                        brdok WITH cBrojDokumenta, ;
                        datod WITH dDatOdZaBrDok, ;
                        datdo WITH dDatObracuna
                  ELSE
                     cTmpBrDok := cBrojDokumenta
                  ENDIF

               ENDIF


            ENDIF

            SELECT suban
            SKIP

         ENDDO

      ENDDO

      SELECT kam_pripr
      nTekuciRec := RecNo()
      SEEK cIdPartner // kam_pripr

      my_flock()

      DO WHILE !Eof() .AND. cIdPartner == field->idpartner
         REPLACE field->osndug WITH nOsnovniDug // nafiluj osnovni dug
         SKIP
      ENDDO

      my_unlock()

      GO nTekuciRec
      SELECT suban

   ENDDO

   SELECT kam_pripr
   SET ORDER TO TAG "1"
   GO TOP

   cTmpBrDok := "XYZXYZSC"

   DO WHILE !Eof()
      SKIP
      nTekuciRec := RecNo()
      SKIP -1
      IF field->datod <= field->datdo .AND. cTmpBrDok == field->brdok .AND. field->osndug = 0
         SKIP // ako se radi o zadnjoj uplati vec postojeceg racuna ne brisi !
         LOOP
      ENDIF

      IF field->datod >= field->datdo .OR. field->osndug <= 0
         my_delete()
      ELSE
         cTmpBrDok := field->brdok
      ENDIF

      GO nTekuciRec

   ENDDO

   GO TOP

   my_dbf_pack()

   my_close_all_dbf()

   RETURN .T.
