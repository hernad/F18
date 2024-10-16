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

#define F_T_PROMVP  245

/* GetPrVPParams(cProdId, dDatOd, dDatDo, dDatDok, cTipNal, cShema)
 *     Setuj parametre prenosa
 *   param: cProdId - id prodavnice
 *   param: dDatOd - datum prenosa od
 *   param: dDatDo - datum prenosa do
 *   param: dDatDok - datum dokumenta
 */
FUNCTION GetPrVPParams( cProdId, dDatOd, dDatDo, dDatDok, cTipNal, cShema )

   dDatOd := Date() -30
   dDatDo := Date()
   dDatDok := Date()
   cProdId := Space( 2 )
   cTipNal := "  "
   cShema := " "

   Box( "#Kontiranje evidencije vrsta placanja", 7, 60 )
   @ box_x_koord() + 2, box_y_koord() + 2 SAY "TOPS - prodajno mjesto:" GET cProdId VALID !Empty( cProdId )
   @ box_x_koord() + 3, box_y_koord() + 2 SAY "Datum od" GET dDatOd VALID !Empty( dDatOd )
   @ box_x_koord() + 3, box_y_koord() + 20 SAY "do" GET dDatDo VALID !Empty( dDatDo )

   @ box_x_koord() + 5, box_y_koord() + 2 SAY "Vrsta naloga:" GET cTipNal VALID !Empty( cTipNal )
   @ box_x_koord() + 6, box_y_koord() + 2 SAY "Datum knjizenja:" GET dDatDok VALID !Empty( dDatDok )
   @ box_x_koord() + 7, box_y_koord() + 2 SAY "Shema:" GET cShema
   READ
   BoxC()

   IF LastKey() = K_ESC
      RETURN .F.
   ELSE
      RETURN .T.
   ENDIF

   RETURN .T.




/* Azur2Pripr(cBrojNal, dDatNal)
 *     Azuriranje stavke u pripremu
 *   param: cBrojNal - broj naloga
 *   param: dDatNal - datum naloga
 */
STATIC FUNCTION Azur2Pripr( cBrojNal, dDatNal )

   LOCAL nArr

   nArr := Select()

   SELECT fin_pripr
   APPEND BLANK
   REPLACE idvn WITH trfp2->idvn
   REPLACE idfirma WITH self_organizacija_id()
   REPLACE brnal WITH cBrojNal
   REPLACE rbr WITH Str( ++nRBr, 4 )
   REPLACE datdok WITH dDatNal
   REPLACE idkonto WITH cIdKonto
   REPLACE d_p WITH trfp2->d_p
   REPLACE iznosbhd WITH nIznos
   REPLACE iznosdem WITH nIznDEM
   REPLACE brdok WITH cBrDok
   REPLACE opis WITH Trim( trfp2->naz )

   SELECT ( nArr )

   RETURN




/* NaDan(cField)
 *     Vraca ukupan iznos pologa (cField) za datumski period
 *   param: cField - polje, npr "POLOG01"
 */
FUNCTION NaDan( cField )

   LOCAL nArr

   nArr := Select()
   SELECT F_T_PROMVP
   SET ORDER TO TAG "1"
   GO TOP

   nIznos := 0
   DO WHILE !Eof()
      IF ( field->pm <> cProdId )
         SKIP
         LOOP
      ENDIF
      IF ( field->datum > dDatDo .OR. field->datum < dDatOd )
         SKIP
         LOOP
      ENDIF
      nIznos := field->&cField
      nIznDem := nIznos * Kurs( dDatDok, "D", "P" )
      Azur2Pripr( cBrNal, field->datum )
      SKIP 1
   ENDDO

   SELECT ( nArr )

   RETURN 1



/* GetVrPlIznos(cField)
 *     Vraca iznos pologa za datumski period
 *   param: cField - polje, npr "POLOG01"
 */
STATIC FUNCTION GetVrPlIznos( cField )

   LOCAL nArr

   nArr := Select()
   SELECT F_T_PROMVP
   SET ORDER TO TAG "1"
   GO TOP

   nIzn := 0
   DO WHILE !Eof()
      IF ( field->pm <> cProdId )
         SKIP
         LOOP
      ENDIF
      IF ( field->datum > dDatDo .OR. field->datum < dDatOd )
         SKIP
         LOOP
      ENDIF
      nIzn += field->&cField
      SKIP
   ENDDO

   SELECT ( nArr )

   RETURN nIzn




/* O_PrVP_DB()
 *     Otvaranje neophodnih tabela
 */
STATIC FUNCTION O_PrVP_DB()

  //o_koncij()
   //o_partner()
   o_suban()
   //o_konto()
   //select_o_fakt_objekti()
   o_nalog()
   o_fin_pripr()
   o_trfp2()

   RETURN .T.



/* GetTopsParams(cTKPath, cProdKonto)
 *     Setuje TOPS kumpath i idkonto
 *   param: cTKPath - kumpath tops
 *   param: cProdKonto - prodavnicki konto
 */
STATIC FUNCTION GetTopsParams( cTKPath, cProdKonto )

   o_koncij()
   SELECT koncij
   // setuj filter po cProdId
   SET FILTER TO idprodmjes = cProdId
   GO TOP
   IF field->idprodmjes <> cProdId
      MsgBeep( "Ne postoji prodajno mjesto:" + cProdId + "##Prekidam operaciju!" )
      RETURN .F.
   ENDIF

   cTKPath := AllTrim( koncij->kumtops )
   cProdKonto := koncij->id

   // vrati filter
   SET FILTER TO

   IF Empty( cTKPath )
      MsgBeep( "Nije podesen kumpath TOPS-a u tabeli KONCIJ!" )
      RETURN .F.
   ENDIF
   IF Empty( cProdKonto )
      MsgBeep( "Ne postoji prodavnicki konto!" )
      RETURN .F.
   ENDIF

   RETURN .T.
