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

STATIC s_oPDF
STATIC s_cLinija
STATIC s_nRobaNazivDuzina := 66
MEMVAR cIdFirma, cIdVd, cBrDok

FUNCTION kalk_stampa_dok_im()

   LOCAL nColIdRoba, nColKolicina
   LOCAL nCol1 := 0
   LOCAL nCol2 := 0
   LOCAL nPom := 0
   LOCAL nTotalVisak, nTotalManjak, nU4
   LOCAL nTot5 := 0
   LOCAL nTot6 := 0
   LOCAL nTot7 := 0
   LOCAL nTot8 := 0
   LOCAL nTot9 := 0
   LOCAL nTota := 0
   LOCAL nTotb := 0
   LOCAL nTotc := 0
   LOCAL nTotd := 0
   LOCAL nTotKol := 0
   LOCAL nTotGKol := 0
   LOCAL nStr
   LOCAL cIdPartner
   LOCAL cBrFaktP
   LOCAL xPrintOpt, bZagl, cNaslov

   // LOCAL dDatFaktP
   LOCAL cIdKonto
   LOCAL cSamoObrazac, cPrikazCijene, cCijenaTip, nCijena, nC1, nColTotal

   PRIVATE nKalkPrevoz
   PRIVATE nKalkCarDaz
   PRIVATE nKalkZavTr
   PRIVATE nKalkBankTr
   PRIVATE nKalkSpedTr
   PRIVATE nKalkMarzaVP
   PRIVATE nKalkMarzaMP

   // nStr := 0
   cIdPartner := kalk_pripr->IdPartner
   cBrFaktP   := kalk_pripr->BrFaktP
   // dDatFaktP  := kalk_pripr->DatFaktP
   cIdKonto   := kalk_pripr->IdKonto
   cIdFirma := kalk_pripr->IdFirma
   cIdVd := kalk_pripr->Idvd
   cBrDok := kalk_pripr->brdok

   select_o_konto( cIdkonto )
   SELECT kalk_pripr


   cSamoObrazac := Pitanje(, "Prikaz samo obrasca inventure? (D/N)" )
   cPrikazCijene := "D"
   IF cSamoObrazac == "D"
      cPrikazCijene := Pitanje(, "Prikazati cijenu na obrascu? (D/N)" )
   ENDIF
   cCijenaTip := Pitanje(, "Na obrascu prikazati VPC (D) ili NC (N)?", "N" )

   cNaslov := "INVENTURA MAGACIN " + cIdFirma + "-" + cIdVD + "-" + cBrDok + " / " + AllTrim( konto->naz ) + " , Datum: " + DToC( kalk_pripr->DatDok )
   s_oPDF := PDFClass():New()
   xPrintOpt := hb_Hash()
   xPrintOpt[ "tip" ] := "PDF"
   xPrintOpt[ "layout" ] := "landscape"
   xPrintOpt[ "opdf" ] := s_oPDF
   xPrintOpt[ "font_size"] := 9
   IF f18_start_print( NIL, xPrintOpt,  cNaslov ) == "X"
      RETURN .F.
   ENDIF

   bZagl := {|| zagl() }

   SELECT kalk_pripr

   nTotalVisak := 0
   nTotalManjak := 0
   nTot5 := 0
   nTot6 := 0
   nTot7 := 0
   nTot8 := 0
   nTot9 := 0
   nTota := 0
   nTotb := 0
   nTotc := 0
   nTotd := 0
   nTotKol := 0
   nTotGKol := 0

   Eval( bZagl )
   DO WHILE !Eof() .AND. cIdFirma == kalk_pripr->IdFirma .AND.  cBrDok == kalk_pripr->BrDok .AND. cIdVD == kalk_pripr->IdVd

      kalk_set_vars_troskovi_marzavp_marzamp()
      kalk_pozicioniraj_roba_tarifa_by_kalk_fields()

      // SKol := kalk_pripr->Kolicina

      IF cCijenaTIP == "N"
         nCijena := field->nc
      ELSE
         nCijena := field->vpc
      ENDIF

      check_nova_strana( bZagl, s_oPDF )

      @ PRow() + 1, 0 SAY  kalk_pripr->Rbr PICTURE "XXX"
      @ PRow(), nColIdRoba := PCol() + 1 SAY  kalk_pripr->idroba
      @ PRow(), PCol() + 1  SAY PadR( Trim( ROBA->naz ), s_nRobaNazivDuzina )
      @ PRow(), PCol() + 1  SAY ROBA->jmj
      nColKolicina := PCol() + 1

      @ PRow() + 1, nColIdRoba SAY kalk_pripr->IdTarifa
      IF roba_barkod_pri_unosu() .AND. !Empty( roba->barkod )
         ?? " BK: " + ROBA->barkod
      ENDIF

      IF cSamoObrazac == "D"
         @ PRow(), nColKolicina SAY kalk_pripr->Kolicina  PICTURE Replicate( "_", Len( kalk_pic_kolicina_bilo_gpickol() ) )
         @ PRow(), PCol() + 1 SAY kalk_pripr->GKolicina  PICTURE Replicate( " ", Len( kalk_pic_kolicina_bilo_gpickol() ) )
      ELSE
         @ PRow(), nColKolicina SAY kalk_pripr->Kolicina  PICTURE kalk_pic_kolicina_bilo_gpickol()
         @ PRow(), PCol() + 1 SAY kalk_pripr->GKolicina  PICTURE kalk_pic_kolicina_bilo_gpickol()
      ENDIF
      nC1 := PCol() + 1

      IF cSamoObrazac == "D"
         @ PRow(), PCol() + 1 SAY kalk_pripr->gkolicina * nCijena  PICTURE Replicate( " ", Len( kalk_pic_iznos_bilo_gpicdem() ) )
         @ PRow(), PCol() + 1 SAY kalk_pripr->kolicina * nCijena   PICTURE Replicate( "_", Len( kalk_pic_iznos_bilo_gpicdem() ) )
         @ PRow(), PCol() + 1 SAY kalk_pripr->Kolicina - GKolicina  PICTURE Replicate( " ", Len( kalk_pic_kolicina_bilo_gpickol() ) )
      ELSE
         @ PRow(), PCol() + 1 SAY kalk_pripr->gkolicina * nCijena PICTURE kalk_pic_iznos_bilo_gpicdem() // knjizna vrijednost
         @ PRow(), PCol() + 1 SAY kalk_pripr->kolicina * nCijena  PICTURE kalk_pic_iznos_bilo_gpicdem() // popisana vrijednost
         @ PRow(), PCol() + 1 SAY kalk_pripr->Kolicina - kalk_pripr->GKolicina  PICTURE kalk_pic_kolicina_bilo_gpickol() // visak-manjak
      ENDIF

      IF ( cPrikazCijene == "D" )
         @ PRow(), PCol() + 1 SAY nCijena  PICTURE PicCDEM // veleprodajna cij
      ELSE
         @ PRow(), PCol() + 1 SAY nCijena  PICTURE Replicate( " ", Len( kalk_pic_iznos_bilo_gpicdem() ) )
      ENDIF

      nTotb += kalk_pripr->gkolicina * nCijena
      nTotc += kalk_pripr->kolicina * nCijena
      nU4 := nCijena * ( kalk_pripr->Kolicina - kalk_pripr->gKolicina )

      IF nU4 > 0 // popisana - knjizna > 0 - visak
         nTotalVisak += nU4
      ELSE
         nTotalManjak += -nU4
      ENDIF

      nTotKol += kalk_pripr->kolicina
      nTotGKol += kalk_pripr->gkolicina

      IF cSamoObrazac == "D"
         @ PRow(), PCol() + 1 SAY nU4  PICT Replicate( " ", Len( kalk_pic_iznos_bilo_gpicdem() ) )
      ELSE
         @ PRow(), PCol() + 1 SAY nU4 PICT iif( nU4 > 0, kalk_pic_iznos_bilo_gpicdem(), Replicate( " ", Len( kalk_pic_iznos_bilo_gpicdem() ) ) )
         @ PRow(), PCol() + 1 SAY iif( nU4 < 0, - nU4, nU4 ) PICT iif( nU4 < 0, kalk_pic_iznos_bilo_gpicdem(), Replicate( " ", Len( kalk_pic_iznos_bilo_gpicdem() ) ) )
      ENDIF

      SKIP

   ENDDO

   check_nova_strana( bZagl, s_oPDF, .F., 5 )
   IF cSamoObrazac == "D"
      kalk_clanovi_komisije()
      f18_end_print( NIL, xPrintOpt )
      RETURN .T.
   ENDIF


   check_nova_strana( bZagl, s_oPDF, .F., 3 )
   ? s_cLinija
   @ PRow() + 1, 0 SAY "Ukupno:"
   @ PRow(), ( PCol() * 6 ) + 2 SAY nTotKol PICT kalk_pic_kolicina_bilo_gpickol()
   @ PRow(), PCol() + 1 SAY nTotGKol PICT kalk_pic_kolicina_bilo_gpickol()
   @ PRow(), PCol() + 1 SAY nTotb PICT kalk_pic_iznos_bilo_gpicdem()
   @ PRow(), PCol() + 1 SAY nTotc PICT kalk_pic_iznos_bilo_gpicdem()
   @ PRow(), PCol() + 1 SAY Space( Len( kalk_pic_iznos_bilo_gpicdem() ) )
   @ PRow(), PCol() + 1 SAY Space( Len( kalk_pic_iznos_bilo_gpicdem() ) )
   nColTotal := PCol() + 1

   IF nTotalVisak > 0
      @ PRow(), nColTotal SAY nTotalVisak PICT kalk_pic_iznos_bilo_gpicdem()
   ELSE
      @ PRow(), nColTotal SAY Space( Len( kalk_pic_iznos_bilo_gpicdem() ) )
   ENDIF
   IF nTotalManjak > 0
      @ PRow(), PCol() + 1 SAY nTotalManjak PICT kalk_pic_iznos_bilo_gpicdem()
   ELSE
      @ PRow(), PCol() + 1 SAY Space( Len( kalk_pic_iznos_bilo_gpicdem() ) )
   ENDIF

   ?
   IF nTotalVisak - nTotalManjak > 0
      @ PRow(), nColTotal SAY nTotalVisak - nTotalManjak PICT kalk_pic_iznos_bilo_gpicdem()
      @ PRow(), PCol() + 1 SAY Space( Len( kalk_pic_iznos_bilo_gpicdem() ) )
   ELSE
      @ PRow(), nColTotal SAY Space( Len( kalk_pic_iznos_bilo_gpicdem() ) )
      @ PRow(), PCol() + 1 SAY - nTotalVisak + nTotalManjak PICT kalk_pic_iznos_bilo_gpicdem()
   ENDIF
   ? s_cLinija

   f18_end_print( NIL, xPrintOpt )

   RETURN .T.


STATIC FUNCTION zagl()

   LOCAL nI, cHeader1, cHeader2

   s_cLinija := "---"
   s_cLinija += Space( 1 )
   cHeader1 := "*R *"
   cHeader2 := "*br*"

   s_cLinija += Replicate( "-", 10 ) // cIdroba
   s_cLinija += Space( 1 )

   s_cLinija += Replicate( "-", s_nRobaNazivDuzina )
   s_cLinija += Space( 1 )

   cHeader1 += PadC( "ID", 10 ) + "*"
   cHeader2 += PadC( " ", 10 ) + "*"

   cHeader1 += PadC( "Roba", s_nRobaNazivDuzina ) + "*"
   cHeader2 += PadC( " ", s_nRobaNazivDuzina ) + "*"

   s_cLinija += "---"
   s_cLinija += Space( 1 )

   cHeader1 += "JMJ*"
   cHeader2 += "   *"

   cHeader1 += PadC( _u( "Popisana" ), 10 ) + "*"
   cHeader2 += PadC( _u( "kol" ), 10 ) + "*"

   cHeader1 += PadC( _u( "Knjižna" ), 10 ) + "*"
   cHeader2 += PadC( _u( "kol" ), 10 ) + "*"

   cHeader1 += PadC( _u( "Knjižna" ), 10 ) + "*"
   cHeader2 += PadC( _u( "vrij." ), 10 ) + "*"

   cHeader1 += PadC( _u( "Popisana" ), 10 ) + "*"
   cHeader2 += PadC( _u( "vrij." ), 10 ) + "*"

   cHeader1 += PadC( _u( "Razlika" ), 10 ) + "*"
   cHeader2 += PadC( _u( "(količina)" ), 10 ) + "*"

   cHeader1 += PadC( _u( "Cijena" ), 10 ) + "*"
   cHeader2 += PadC( _u( " " ), 10 ) + "*"

   cHeader1 += PadC( _u( "VIŠAK" ), 10 ) + "*"
   cHeader2 += PadC( _u( " " ), 10 ) + "*"

   cHeader1 += PadC( _u( "MANJAK" ), 9 ) + "*"
   cHeader2 += PadC( _u( " " ), 9 ) + "*"

   FOR nI := 1 TO 7
      s_cLinija += Replicate( "-", 10 )
      s_cLinija += Space( 1 )
   NEXT

   s_cLinija += Replicate( "-", 10 )
   s_cLinija += Space( 1 )

   ? s_cLinija
   ? cHeader1
   ? cHeader2
   ?U s_cLinija
