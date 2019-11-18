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

FUNCTION kontiranje_vise_dokumenata_period_auto()

   LOCAL dDatOd := Date() - 30
   LOCAL dDatDo := Date()
   LOCAL cIdVD := "14"
   LOCAL cId_mkto := PadR( "", 100 )
   LOCAL cId_pkto := PadR( "", 100 )
   LOCAL cAutomatskiSetBrojNaloga := "N"
   LOCAL lAutomatskiSetBrojNaloga := .F.
   LOCAL GetList := {}

   Box( , 6, 65 )

   @ box_x_koord() + 1, box_y_koord() + 2 SAY "Datum od:" GET dDatOd
   @ box_x_koord() + 1, Col() + 1 SAY "do:" GET dDatDo

   @ box_x_koord() + 2, box_y_koord() + 2 SAY "tipovi dokumenata (prazno siv):" GET cIdVD  PICT "@S20"

   @ box_x_koord() + 3, box_y_koord() + 2 SAY "mag.konta (prazno-sva):" GET cId_mkto PICT "@S20"
   @ box_x_koord() + 4, box_y_koord() + 2 SAY " pr.konta (prazno-sva):" GET cId_pkto PICT "@S20"

   IF is_kalk_fin_isti_broj() // ako je parametar fin-kalk broj identican, onda uvijek
      cAutomatskiSetBrojNaloga := "D"
   ELSE
      @ box_x_koord() + 6, box_y_koord() + 2 SAY "Automatska generacija brojeva FIN naloga ?" GET cAutomatskiSetBrojNaloga PICT "@!"
   ENDIF

   READ

   BoxC()

   IF LastKey() == K_ESC
      RETURN .F.
   ENDIF

   IF cAutomatskiSetBrojNaloga == "D"
      lAutomatskiSetBrojNaloga := .T.
   ENDIF

   kalk_kontiranje_dokumenata( lAutomatskiSetBrojNaloga, dDatOd, dDatDo, cIdVD, cId_mkto, cId_pkto )

   RETURN .T.



STATIC FUNCTION kalk_kontiranje_dokumenata( lAutomatskiSetBrojNaloga, dDatOd, dDatDo, cIdVD, cId_mkto, cId_pkto )

   LOCAL nCount := 0
   LOCAL nTNRec
   LOCAL cBrFinNalog := NIL
   LOCAL cIdFirmaTekuci, cIdVdTekuci, cBrdokTekuci
   LOCAL lError := .F.

   hb_default( @lAutomatskiSetBrojNaloga, .T. )

   IF Empty( cIdVD )
      cIdVD := NIL
   ENDIF

   find_kalk_doks_by_tip_datum( NIL, cIdVD, dDatOd, dDatDo )

   cId_mkto := AllTrim( cId_mkto )
   cId_pkto := AllTrim( cId_pkto )

   GO TOP // kalk_doks

   DO WHILE !Eof()

      IF !Empty( cId_mkto ) // provjeri magacinska konta
         IF ! ( AllTrim( field->mkonto ) $ cId_mkto )
            SKIP
            LOOP
         ENDIF
      ENDIF


      IF !Empty( cId_pkto ) // provjeri prodavnicka konta
         IF !( AllTrim( field->pkonto ) $ cId_pkto )
            SKIP
            LOOP
         ENDIF
      ENDIF

      nTNRec := RecNo()
      cIdFirmaTekuci := field->idfirma
      cIdVdTekuci := field->idvd
      cBrdokTekuci := field->brdok

      kalk_kontiranje_gen_finmat( .T., cIdFirmaTekuci, cIdVdTekuci, cBrdokTekuci, .T. )  // napuni FINMAT

      // IF is_kalk_fin_isti_broj()
      // cBrFinNalog := cBrdokTekuci
      // ENDIF

      IF !kalk_kontiranje_fin_naloga( lAutomatskiSetBrojNaloga, .T., .T., NIL, lAutomatskiSetBrojNaloga ) // kontiraj
                      // parametri ( lAutomatskiSetBrojNaloga, lAGen := .T., lViseKalk := .T., cNalog := NIL, lAutoBrojac )
         lError := .T.
         EXIT
      ENDIF

      ++ nCount

      SELECT kalk_doks
      GO ( nTNRec )
      SKIP

   ENDDO

   IF lError
      MsgBeep( "Generacija fin dokumenta za KALK( " + cIdFirmaTekuci + " - " + cIdVdTekuci + " - " + cBrdokTekuci + " ) neuspješna !? STOP!" )
   ENDIF

   IF nCount > 0
      MsgBeep( "Uspješno kontirano " + AllTrim( Str( nCount ) ) + " dokumenata !" )
   ENDIF

   RETURN !lError




/*
 kontiraj vise dokumenata u jedan

FUNCTION kalk_kontiranje_dokumenata_period()

   LOCAL nCount
   LOCAL aD
   LOCAL dDatOd
   LOCAL dDatDo
   LOCAL cVrsta
   LOCAL cMKonto
   LOCAL cPKonto

   aD := kalk_rpt_datumski_interval( Date() )

   cVrsta := Space( 2 )

   dDatOd := aD[ 1 ]
   dDatDo := aD[ 2 ]

   cMKonto := PadR( "", 7 )
   cPKonto := PadR( "", 7 )

   set_cursor_on()
   Box(, 6, 60 )
   @ box_x_koord() + 1, box_y_koord() + 2 SAY  "Vrsta kalkulacije " GET cVrsta PICT "@!" VALID !Empty( cVrsta )

   @ box_x_koord() + 3, box_y_koord() + 2 SAY  "Magacinski konto (prazno svi) " GET cMKonto  PICT "@!"

   @ box_x_koord() + 4, box_y_koord() + 2 SAY "Prodavnicki kto (prazno svi)  " GET cPKonto PICT "@!"


   @ box_x_koord() + 6, box_y_koord() + 2 SAY  "Kontirati za period od " GET dDatOd
   @ box_x_koord() + 6, Col() + 2  SAY  " do " GET dDatDo

   READ

   BoxC()

   // koristi se kao datum kontiranja za trfp.dokument = "9"
   dDatMax := dDatDo

   IF LastKey() == K_ESC
      my_close_all_dbf()
      RETURN .F.
   ENDIF

   my_use_refresh_stop()


   IF Select( "kalk_pripr" ) > 0
      SELECT KALK_PRIPR
      USE
   ENDIF

   SELECT F_KALK_DOKS
   IF !Used()
      o_kalk_doks()
   ENDIF


   // "1","IdFirma+idvd+brdok"
   PRIVATE cFilter := "DatDok >= "  + dbf_quote( dDatOd ) + ".and. DatDok <= " + dbf_quote( dDatDo ) + ".and. IdVd==" + dbf_quote( cVrsta )

   IF !Empty( cMKonto )
      cFilter += ".and. mkonto==" + dbf_quote( cMKonto )
   ENDIF

   IF !Empty( cPKonto )
      cFilter += ".and. pkonto==" + dbf_quote( cPKonto )
   ENDIF

   SET FILTER TO &cFilter
   GO TOP


   nCount := 0
   DO WHILE !Eof()
      nCount ++
      cIdFirma := idFirma
      cIdVd := idvd
      cBrDok := brdok

      kalk_kontiranje_gen_finmat( .T., cIdFirma, cIdVd, cBrDok )

      SELECT KALK_DOKS
      SKIP
   ENDDO

   MsgBeep(  "Obradjeno " + AllTrim( Str( nCount, 7, 0 ) ) + " dokumenata" )

   my_use_refresh_start()
   my_close_all_dbf()

   RETURN .T.
*/
