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



/*
// prenos podataka LD->FIN

FUNCTION LdFin()

   LOCAL cPath
   LOCAL nIznos
   PRIVATE cShema := fetch_metric( "fin_prenos_ld_shema", my_user(), "1" )
   PRIVATE dDatum := Date()
   PRIVATE _godina := fetch_metric( "fin_prenos_ld_godina", my_user(), Year( Date() ) )
   PRIVATE _mjesec := fetch_metric( "fin_prenos_ld_mjesec", my_user(), Month( Date() ) )
   PRIVATE broj_radnika := 0

   Box( "#KONTIRANJE OBRACUNA PLATE", 10, 75 )
   @ box_x_koord() + 2, box_y_koord() + 2 SAY "GODINA:" GET _godina PICT "9999"
   @ box_x_koord() + 3, box_y_koord() + 2 SAY "MJESEC:" GET _mjesec PICT "99"
   @ box_x_koord() + 5, box_y_koord() + 2 SAY "Shema kontiranja:" GET cShema PICT "@!"
   @ box_x_koord() + 6, box_y_koord() + 2 SAY "Datum knjizenja :" GET dDatum
   READ
   BoxC()

   IF LastKey() == K_ESC
      my_close_all_dbf()
      RETURN
   ENDIF

   // snimi parametre
   set_metric( "fin_prenos_ld_shema", my_user(), cShema )
   set_metric( "fin_prenos_ld_godina", my_user(), _godina )
   set_metric( "fin_prenos_ld_mjesec", my_user(), _mjesec )

   o_fakt_objekti()
   o_nalog()
   o_fin_pripr()
   O_TRFP3
   open_rekld()

   IF RecCount() == 0
      MsgBeep( "Potrebno pokrenuti specifikaciju u modulu LD !" )
      my_close_all_dbf()
      RETURN
   ENDIF

   SELECT trfp3
   SET FILTER TO shema = cShema
   GO TOP

   cBrNal := fin_prazan_broj_naloga()

   SELECT trfp3

   nRBr := 0
   nIznos := 0

   DO WHILE !Eof()

      PRIVATE cPom := trfp3->id

      IF "#RN#" $ cPom

         SELECT fakt_objekti
         GO TOP

         DO WHILE !Eof()
            cPom := trfp3->id
            cBrDok := fakt_objekti->id
            cPom := StrTran( cPom, "#RN#", cBrDok )
            nIznos := &cPom
            IF Round( nIznos, 2 ) <> 0
               SELECT fin_pripr
               APPEND BLANK
               REPLACE idvn     WITH trfp3->idvn
               REPLACE idfirma  WITH self_organizacija_id()
               REPLACE brnal    WITH cBrNal
               REPLACE rbr      WITH Str( ++nRBr, 4 )
               REPLACE datdok   WITH dDatum
               REPLACE idkonto  WITH trfp3->idkonto
               REPLACE d_p      WITH trfp3->d_p
               REPLACE iznosbhd WITH nIznos
               REPLACE brdok    WITH cBrDok
               REPLACE opis     WITH Trim( trfp3->naz ) + " " + Str( _mjesec, 2 ) + "/" + Str( _godina, 4 )
               SELECT fakt_objekti
            ENDIF
            SKIP 1
         ENDDO
         SELECT trfp3

      ELSEIF "#AH#" $ cPom
         cPom := StrTran( cPom, "#AH#", "" )
         cIznos := &cPom
         SELECT trfp3
      ELSE

         nIznos := &cPom
         cBrDok := ""

         IF Round( nIznos, 2 ) <> 0

            SELECT fin_pripr
            APPEND BLANK

            REPLACE idvn     WITH trfp3->idvn
            REPLACE idfirma  WITH self_organizacija_id()
            REPLACE brnal    WITH cBrNal
            REPLACE rbr      WITH Str( ++nRBr, 4 )
            REPLACE datdok   WITH dDatum
            REPLACE idkonto  WITH trfp3->idkonto
            REPLACE d_p      WITH trfp3->d_p
            REPLACE iznosbhd WITH nIznos
            REPLACE brdok    WITH cBrDok
            REPLACE opis     WITH Trim( trfp3->naz ) + " " + Str( _mjesec, 2 ) + "/" + Str( _godina, 4 )
            SELECT trfp3
         ENDIF
      ENDIF
      SKIP 1
   ENDDO

   my_close_all_dbf()

   RETURN

*/

// ------------------------------------------------------------
// autorski honorari prenos REKLD
// cTag: "2" - po partneru, "3" - izdanju, "4" - izdanje partner
// cOpis: trazi opis pri trazenju
// ------------------------------------------------------------
FUNCTION ah_rld( cId, cTag, cOpis )

   LOCAL nTArea := Select()
   LOCAL nIzn1 := 0
   LOCAL nIzn2 := 0
   LOCAL cTmp := ""

   IF cTag == nil
      cTag := "1"
   ENDIF
   IF cOpis == nil
      cOpis := ""
   ENDIF

   SELECT rekld
   SET ORDER TO tag &cTag
   GO TOP
   SEEK Str( _godina, 4, 0 ) + Str( _mjesec, 2, 0 ) + cId

   DO WHILE !Eof() .AND. godina == Str( _godina, 4, 0 ) .AND. mjesec == Str( _mjesec, 2, 0 ) .AND. AllTrim( id ) == cId

      cTmp := field->idpartner
      cIzdanje := field->izdanje

      nIzn1 := 0
      nIzn2 := 0

      DO WHILE !Eof() .AND. godina == Str( _godina, 4 ) .AND. ;
            mjesec == Str( _mjesec, 2 ) .AND. ;
            AllTrim( id ) == cId .AND. ;
            IIF( cTag == "2" .OR. cTag == "4", idpartner == cTmp, .T. ) .AND. ;
            IIF( cTag == "3" .OR. cTag == "4", izdanje == cIzdanje, .T. )

         IF !Empty( cOpis ) .AND. At( cOpis, cIzdanje ) == 0
            SKIP
            LOOP
         ENDIF

         nIzn1 += iznos1
         nIzn2 += iznos2

         SKIP
      ENDDO

      cBrDok := ""

      IF cTag == "3" .OR. cTag == "1" .OR. cTag == "4"
         cTmp := ""
      ENDIF

      // dodaj u pripremu
      IF Round( nIzn1, 2 ) <> 0

         SELECT fin_pripr
         APPEND BLANK

         REPLACE idvn WITH trfp3->idvn
         REPLACE idfirma WITH self_organizacija_id()
         REPLACE brnal WITH cBrNal
         REPLACE rbr WITH Str( ++nRBr, 4 )
         REPLACE datdok WITH dDatum
         REPLACE idkonto WITH trfp3->idkonto
         REPLACE d_p WITH trfp3->d_p
         REPLACE iznosbhd WITH nIzn1
         REPLACE idpartner WITH cTmp
         REPLACE brdok WITH cBrDok

         cNalOpis := Trim( trfp3->naz ) + " za " + Str( _mjesec, 2, 0 ) + "/" + Str( _godina, 4, 0 )

         REPLACE opis WITH cNalOpis

      ENDIF

      SELECT rekld
   ENDDO

   SELECT ( nTArea )

   RETURN .T.
