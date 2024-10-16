/*
 * This file is part of the bring.out FMK, a free and open source
 * accounting software suite,
 * Copyright (c) 1994-2024 by bring.out d.o.o Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including knowhow ERP specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_knowhow.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */

#include "f18.ch"

/* \file fmk/fin/specif/ramaglas/rpt/1g/rpt_strn.prg
 *     Specifikacije troskova radnih naloga - "pogonsko knjigovodstvo"
 */


/* SpecTrosRN()
 *     Specifikacija troskova po radnim nalozima (tj.objektima)
 */

FUNCTION SpecTrosRN()

   picBHD := FormPicL( "9 " + gPicBHD, 17 )

   cIdFirma := self_organizacija_id()
   qqRN := Space( 40 )
   dOd := CToD( "" )
   dDo := Date()


   Box( "#SPECIFIKACIJA TROSKOVA PO RADNIM NALOZIMA", 10, 75 )


   @ box_x_koord() + 2, box_y_koord() + 2 SAY "Firma "
   ?? self_organizacija_id(), "-", self_organizacija_naziv()


   @ box_x_koord() + 4, box_y_koord() + 2 SAY "Radni nalozi (uslov):" GET qqRN
   @ box_x_koord() + 5, box_y_koord() + 2 SAY "Period: od datuma" GET dOd
   @ box_x_koord() + 5, Col() + 2 SAY "do datuma" GET dDo

   DO WHILE .T.
      READ
      ESC_BCR
      aUsl1 := Parsiraj( qqRN, "brDok", "C" )
      aUsl2 := Parsiraj( "TD;", "konto->oznaka", "C" )
      IF aUsl1 <> NIL .AND. aUsl2 <> NIL
         EXIT
      ENDIF
   ENDDO

   BoxC()

   cIdFirma := Left( cIdFirma, 2 )

   //select_o_fakt_objekti()
   //o_konto()
   o_suban()

// 1) utvrditi ukupne troskove (nUkTros)
   cPom := my_get_from_ini( "Troskovi", "Uslov", 'idKonto="3"', KUMPATH )
   SET FILTER TO &cPom
   GO TOP
   nUkTros := 0
   DO WHILE !Eof()
      nUkTros := nUkTros + IF( field->d_p = "1", 1, - 1 ) * field->iznosBHD
      SKIP 1
   ENDDO
   SET FILTER TO
// ------------------------------

   SELECT SUBAN
   SET RELATION TO idKonto INTO konto

   PRIVATE cFilt1 := "IdFirma=='" + cIdFirma + "'.and." + aUsl1 + ".and." + aUsl2
   PRIVATE cSort := "brDok+idKonto"
   INDEX ON &cSort TO VEZSUB FOR &cFilt1


   GO TOP
   EOF CRET

   PRIVATE m
   m := Replicate( "-", 83 )

   nUkDirTros := 0
   nUkTDP := 0
   aTDP := {}
   aTD := {}

   aIzvj := {}

   DO WHILE ( !Eof() )
      cBrDok := field->brDok
      SELECT fakt_objekti
      HSEEK PadR( cBrDok, 10 )
      AAdd( aIzvj, { cBrDok } )
      nTekRN := Len( aIzvj )
      AAdd( aIzvj[ nTekRN ], "" )
      AAdd( aIzvj[ nTekRN ], "Broj radnog naloga : " + cBrDok )
      AAdd( aIzvj[ nTekRN ], "Naziv radnog naloga: " + field->naz )
      AAdd( aIzvj[ nTekRN ], m )
      SELECT suban
      nUkupno := 0
      DO WHILE ( !Eof() .AND. field->brDok == cBrDok )
         cIdKonto := field->idKonto
         cNazKonta := konto->naz
         nIznos := 0
         lTDP := ( konto->oznaka = "TDP" )
         DO WHILE ( !Eof() .AND. field->brDok == cBrDok .AND. field->idKonto == cIdKonto )
            IF d_p == "1"
               nIznos += iznosbhd
            ELSE
               nIznos -= iznosbhd
            ENDIF
            SKIP 1
         ENDDO
// 2) utvrditi ukupne direktne troskove (nUkDirTros)
         nUkDirTros += nIznos
// -------------------------------
         IF lTDP
// 4) utvrditi trosak plata proizvodnih radnika po radnom nalogu (aTDP[x])
            nPom := AScan( aTDP, {| x | x[ 1 ] == cBrDok } )
            IF nPom > 0
               aTDP[ nPom, 2 ] := aTDP[ nPom, 2 ] + nIznos
            ELSE
               AAdd( aTDP, { cBrDok, nIznos } )
            ENDIF
// ----------------------------------------------
// 5) utvrditi ukupni trosak plata proizvodnih radnika (nUkTDP)
            nUkTDP := nUkTDP + nIznos
// ----------------------------------------------
         ENDIF
         nUkupno += nIznos
         AAdd( aIzvj[ nTekRN ], cIdKonto + "-" + cNazKonta + " " + Transform( nIznos, picBHD ) )
      ENDDO
      AAdd( aIzvj[ nTekRN ], m )
      AAdd( aIzvj[ nTekRN ], PadR( "UKUPNO DIREKTNI TROSKOVI", Len( cIdKonto + cNazKonta ) + 1 ) + " " + Transform( nUkupno, picBHD ) )
      AAdd( aIzvj[ nTekRN ], m )
      AAdd( aTD, { cBrDok, nUkupno } )
   ENDDO

// 3) ukupni rezijski troskovi (nUkRezTros = nUkTros - nUkDirTros)
   nUkRezTros := nUkTros - nUkDirTros

   IF !start_print()
      RETURN .F.
   ENDIF
   ?
   FOR i := 1 TO Len( aIzvj )
      cBrDok := aIzvj[ i, 1 ]
      FOR j := 2 TO Len( aIzvj[ i ] )
         ? aIzvj[ i, j ]
      NEXT
      nPom := AScan( aTDP, {| x | x[ 1 ] == cBrDok } )
      IF nPom > 0
// 6) rezijski troskovi po radnom nalogu = nUkRezTros * aTDP[x] / nUkTDP
         nRezTrosRN := nUkRezTros * aTDP[ nPom, 2 ] / nUkTDP
// ------------------------------------------------
         nPom2 := AScan( aTD, {| x | x[ 1 ] == cBrDok } )
         IF nPom2 > 0
            nDirTrosRN := aTD[ nPom2, 2 ]
         ELSE
            nDirTrosRN := 0
         ENDIF
         ? PadR( "RASPOREDJENI REZIJSKI TROSKOVI", Len( cIdKonto + cNazKonta ) + 1 ) + " " + Transform( nRezTrosRN, picBHD )
         ? StrTran( m, "-", "=" )
         ? PadR( "U K U P N I   T R O S K O V I", Len( cIdKonto + cNazKonta ) + 1 ) + " " + Transform( nDirTrosRN + nRezTrosRN, picBHD )
         ? m
      ENDIF
      ?
      FF
   NEXT

   end_print()

   closeret

   RETURN
