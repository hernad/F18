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

FUNCTION ld_specifikacija_po_rj()

   nGodina  := ld_tekuca_godina()
   cMjesecOd := cMjesecDo := ld_tekuci_mjesec()
   cObracun := " "
   qqRj := ""
   qqPrimanja := ""

   o_params()
   PRIVATE cSection := "5", cHistory := " ", aHistory := {}

   cMjesecOd := Str( cMjesecOd, 2 )
   cMjesecDo := Str( cMjesecDo, 2 )
   nGodina   := Str( nGodina, 4 )

   RPar( "p1", @cMjesecOd )
   RPar( "p2", @cMjesecDo )
   RPar( "p3", @nGodina   )
   RPar( "p8", @qqRj      )
   RPar( "p9", @cObracun  )
   RPar( "pA", @qqPrimanja )

   cMjesecOd := Val( cMjesecOd )
   cMjesecDo := Val( cMjesecDo )
   nGodina   := Val( nGodina  )
   qqRj      := PadR( qqRj, 40 )
   qqPrimanja := PadR( qqPrimanja, 100 )

   DO WHILE .T.
      Box( "#Uslovi za specifikaciju primanja po radnim jedinicama", 8, 75 )
      @ box_x_koord() + 2, box_y_koord() + 2   SAY "Radne jedinice (prazno-sve): "   GET qqRj PICT "@S20"
      @ box_x_koord() + 3, box_y_koord() + 2   SAY "Mjesec od: "                     GET cMjesecOd PICT "99"
      @ box_x_koord() + 3, Col() + 2 SAY "do"                              GET cMjesecDo PICT "99"
      @ box_x_koord() + 4, box_y_koord() + 2   SAY "Godina: "                        GET nGodina   PICT "9999"
      IF ld_vise_obracuna()
         @ box_x_koord() + 4, Col() + 2 SAY8 "Obračun:" GET cObracun WHEN ld_help_broj_obracuna( .T., cObracun ) VALID ld_valid_obracun( .T., cObracun )
      ENDIF
      @ box_x_koord() + 5, box_y_koord() + 2   SAY8 "Šifre primanja (prazno-sve):"   GET qqPrimanja PICT "@S30"
      READ
      ESC_BCR
      BoxC()
      aUslRJ   := Parsiraj( qqRj, "IDRJ" )
      aUslPrim := Parsiraj( qqPrimanja, "cIDPRIM" )
      IF aUslRJ <> NIL
         EXIT
      ENDIF
   ENDDO

   cMjesecOd := Str( cMjesecOd, 2 )
   cMjesecDo := Str( cMjesecDo, 2 )
   nGodina   := Str( nGodina, 4 )
   qqRj      := Trim( qqRj )
   qqPrimanja := Trim( qqPrimanja )

   WPar( "p1", cMjesecOd )
   WPar( "p2", cMjesecDo )
   WPar( "p3", nGodina   )
   WPar( "p8", qqRj      )
   RPar( "p9", cObracun  )
   WPar( "pA", qqPrimanja )

   SELECT PARAMS
   USE

   cMjesecOd := Val( cMjesecOd )
   cMjesecDo := Val( cMjesecDo )
   nGodina   := Val( nGodina  )

   cre_tmp_dbf_ldt22()

   otvori_tabele()

   zapuj_pomocnu_tabelu()

   aPrim  := {}       // standardna primanja
   aPrimK := {}       // primanja kao npr. krediti

   select_o_tippr()

   FOR i := 1 TO cLDPolja
      cIDPRIM := PadL( AllTrim( Str( i ) ), 2, "0" )
      IF &aUslPrim
         IF "SUMKREDITA" $ ocitaj_izbaci( F_TIPPR, cIdPrim, "formula" )
            AAdd( aPrimK, "I" + cIdPrim )
         ELSE
            AAdd( aPrim, "I" + cIdPrim )
         ENDIF
      ENDIF
   NEXT

   PRIVATE cFilt := ".t."
   IF !Empty( qqRJ )    ; cFilt += ( ".and." + aUslRJ )                ; ENDIF
   IF !Empty( cObracun ); cFilt += ( ".and. OBR==" + dbf_quote( cObracun ) ); ENDIF
   IF cMjesecOd != cMjesecDo
      cFilt := cFilt + ".and.mjesec>=" + dbf_quote( cMjesecOd ) + ;
         ".and.mjesec<=" + dbf_quote( cMjesecDo ) + ;
         ".and.godina=" + dbf_quote( nGodina )
   ELSE
      cFilt := cFilt + ".and.mjesec=" + dbf_quote( cMjesecOd ) + ;
         ".and.godina=" + dbf_quote( nGodina )
   ENDIF

   SELECT LD
   SET FILTER TO &cFilt
   GO TOP
   aRJ := {}
   DO WHILE !Eof()
      FOR i := 1 TO Len( aPrim )
         SELECT LD
         nPom := &( aPrim[ i ] )

         SELECT LDT22
         SEEK Right( aPrim[ i ], 2 ) + Space( 6 ) + LD->IDRJ // ldt22

         IF Found()
            RREPLACE iznos WITH iznos + nPom
         ELSE
            APPEND BLANK
            REPLACE idprim  WITH Right( aPrim[ i ], 2 ), ;
               idkred  WITH Space( 6 ), ;
               idrj    WITH LD->IDRJ, ;
               iznos   WITH iznos + nPom
            IF AScan( aRJ, {| x | x[ 1 ] == idrj } ) <= 0
               AAdd( aRJ, { idrj, 0 } )
            ENDIF
         ENDIF
         SELECT LD
      NEXT
      FOR i := 1 TO Len( aPrimK )
         SELECT LD

         seek_radkr( ld->godina, ld->mjesec, ld->idradn )

         IF !EOF()
            DO WHILE !Eof() .AND. Str( godina, 4 ) + Str( mjesec, 2 ) + idradn == cKljuc
               cIdKred := idkred
               nPom := 0
               DO WHILE !Eof() .AND. Str( godina, 4 ) + Str( mjesec, 2 ) + idradn + idkred == cKljuc + cIdKred
                  nPom += placeno
                  SKIP 1
               ENDDO
               nPom := -nPom      // kredit je odbitak

               SELECT LDT22
               SEEK Right( aPrimK[ i ], 2 ) + cIdKred + LD->IDRJ // ldt22

               IF Found()
                  RREPLACE iznos WITH iznos + nPom
               ELSE
                  APPEND BLANK
                  REPLACE idprim  WITH Right( aPrimK[ i ], 2 ), ;
                     idkred  WITH cIdKred, ;
                     idrj    WITH LD->IDRJ, ;
                     iznos   WITH iznos + nPom
                  IF AScan( aRJ, {| x | x[ 1 ] == idrj } ) <= 0
                     AAdd( aRJ, { idrj, 0 } )
                  ENDIF
               ENDIF
               SELECT RADKR
            ENDDO
         ENDIF
      NEXT
      SELECT ld
      SKIP 1
   ENDDO

   START PRINT CRET
   gOstr := "D"
   gTabela := 1
   cPrimanje := ""; nUkupno := 0
   nKol := 0

   aKol := { { "PRIMANJE", {|| cPrimanje }, .F., "C", 40, 0, 1, ++nKol } }

   // radne jedinice
   ASort( aRJ,,, {| x, y | x[ 1 ] < y[ 1 ] } )
   FOR i := 1 TO Len( aRJ )
      cPom := AllTrim( Str( i ) )
      AAdd( aKol, { "RJ " + aRJ[ i, 1 ], {|| aRJ[ &cPom., 2 ] }, .T., "N", 15, 2, 1, ++nKol  } )
   NEXT

   // ukupno
   AAdd( aKol, { "UKUPNO", {|| nUkupno }, .T., "N", 15, 2, 1, ++nKol } )

   P_10CPI
   ?? self_organizacija_naziv()
   ?
   ? "Mjesec: od", Str( cMjesecOd, 2 ) + ".", "do", Str( cMjesecDo, 2 ) + "."
   ?? "    Godina:", Str( nGodina, 4 )
   ?U "Obuhvaćene radne jedinice  :", IF( !Empty( qqRJ ), "'" + qqRj + "'", "SVE" )
   ?U "Obuhvaćena primanja (šifre):", "'" + qqPrimanja + "'"
   ?

   SELECT LDT22
   GO TOP

   print_lista_2( aKol,,, gTabela,, ;
      , "SPECIFIKACIJA PRIMANJA PO RADNIM JEDINICAMA", ;
      {|| formula_izvjestaja() }, IF( gOstr == "D",, - 1 ),,,,, )

   FF
   ENDPRINT

   my_close_all_dbf()

   RETURN .T.




STATIC FUNCTION zapuj_pomocnu_tabelu()

   SELECT ldt22
   my_dbf_zap()

   RETURN .T.



STATIC FUNCTION otvori_tabele()

   // o_tippr()
   //o_kred()
   //O_RADKR
   //SET ORDER TO TAG "1"
   //o_ld_rj()
   //o_ld_radn()
   //select_o_ld()
   O_LDT22
   SET ORDER TO TAG "1"

   //SELECT ld

   RETURN .T.



STATIC FUNCTION cre_tmp_dbf_ldt22()

   LOCAL _alias, _table_name, aDbf

   _alias := "LDT22"
   _table_name := "ldt22"

   aDbf := {    { "IDPRIM",  "C",  2, 0 }, ;
      { "IDKRED",  "C",  6, 0 }, ;
      { "IDRJ",  "C",  2, 0 }, ;
      { "IZNOS",  "N", 18, 4 } ;
      }

   IF_NOT_FILE_DBF_CREATE

   CREATE_INDEX( "1", "idprim+idkred+idrj", _alias )

   RETURN .T.



STATIC FUNCTION formula_izvjestaja()

   LOCAL i, nPos, cIdPrim, cIdKred, cIdRj

   IF Empty( idkred )
      cPrimanje := idprim + "-" + ocitaj_izbaci( F_TIPPR, idprim, "naz" )
   ELSE
      cPrimanje := idprim + "-" + idkred + "-" + get_kred_naz( idkred )
   ENDIF
   cIdPrim := idprim
   cIdKred := idkred
   FOR i := 1 TO Len( aRJ ); aRJ[ i, 2 ] := 0; NEXT
   nUkupno := 0
   DO WHILE !Eof() .AND. cIdPrim + cIdKred == idprim + idkred
      cIdRJ := idrj
      nPos := AScan( aRJ, {| x | x[ 1 ] == cIdRj } )
      DO WHILE !Eof() .AND. cIdPrim + cIdKred + cIdRj == idprim + idkred + idrj
         aRJ[ nPos, 2 ] += iznos
         nUkupno     += iznos
         SKIP 1
      ENDDO
   ENDDO
   SKIP -1

   RETURN .T.
