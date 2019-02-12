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

MEMVAR cPolje

MEMVAR ImeKol, Kol

FUNCTION P_Tarifa( cId, dx, dy )

   LOCAL i

   PRIVATE ImeKol
   PRIVATE Kol

   ImeKol := {}
   Kol := {}

   PushWA()
   IF cId != NIL .AND. !Empty( cId )
      select_o_tarifa( "XXXXXXX" ) // cId je zadan, otvoriti samo dummy tabelu sa 0 zapisa
   ELSE
      select_o_tarifa()
   ENDIF

   AAdd( ImeKol, { "ID", {|| tarifa->id }, "id", {|| .T. }, {|| valid_sifarnik_id_postoji( wId ) }  } )
   AAdd( ImeKol, { PadC( "Naziv", 35 ), {|| PadR( ToStrU( tarifa->naz ), 35 ) }, "naz" } )
   AAdd( ImeKol,  { "PDV ", {|| tarifa->pdv },  "pdv", NIL, NIL, NIL, "999.99" } )

   FOR i := 1 TO Len( ImeKol )
      AAdd( Kol, i )
   NEXT

   lRet := p_sifra( F_TARIFA, 1, f18_max_rows() - 15, f18_max_cols() - 25, "Tarifne grupe", @cid, dx, dy )

   PopWa()

   RETURN lRet



/*
 *   Ispitivanje tarife, te punjenje matrice aPorezi
 * param: cIdKonto - Oznaka konta
 * param: cIdRoba - Oznaka robe
 * param: aPorezi - matrica za vrijednosti poreza
 * param: cIdTar - oznaka tarife, ovaj parametar je nil, ali se koristi za izvjestaje radi starih dokumenata (gdje je bilo promjene tarifa)
 */

FUNCTION set_pdv_array_by_koncij_region_roba_idtarifa_2_3( cIdKonto, cIdRoba, aPorezi, cIdTar )

   LOCAL cTarifa
   LOCAL lUsedRoba
   LOCAL lUsedTarifa
   LOCAL cIdTarifa


   PRIVATE cPolje

   lUsedRoba := .T.
   lUsedTarifa := .T.

   PushWA()

   IF Empty( cIdKonto )
      cPolje := "IdTarifa"

   ELSE
      IF select_o_koncij( cIdKonto )
         cPolje := "IdTarifa"
      ELSE

         // IF ( koncij->region == "1" .OR. koncij->region == " " )
         cPolje := "IdTarifa"
         // ELSEIF koncij->region == "2"
         // cPolje := "IdTarifa2"
         // ELSEIF koncij->region == "3"
         // cPolje := "IdTarifa3"
         // ELSE
         // cPolje := "IdTarifa"
         // ENDIF

      ENDIF
   ENDIF

   IF cIdTar == nil
      select_o_roba( cIdRoba )
      cTarifa := &cPolje  // F18 roba ima samo idtarifa
      select_o_tarifa( cTarifa )
      cIdTarifa := tarifa->id
   ELSE
      cTarifa := cIdTar
      select_o_tarifa( cTarifa )
      cIdTarifa := cIdTar
   ENDIF

   set_pdv_array( @aPorezi )

   PopWa()

   RETURN cIdTarifa







/* MpcSaPor(nMpcBP, aPorezi, aPoreziIzn)
 *     Racuna maloprodajnu cijenu sa porezom
 *   param: nMpcBP Maloprodajna cijena bez poreza
 *   param: aPorezi Matrica poreza
 *   param: aPoreziIzn Matrica sa izracunatim porezima
 */
FUNCTION MpcSaPor( nMPCBp, aPorezi, aPoreziIzn )

   LOCAL nPom
   LOCAL nMPP
   LOCAL nPP
   LOCAL nPPP

   nPDV := aPorezi[ POR_PDV ] / 100

   nPP := 0



   // bez poreza * ( 0.17 + 0 + 1)
   nPom := nMpcBp * ( nPDV + nPP + 1 )

   RETURN nPom


/*
 *     Racuna maloprodajnu cijenu bez poreza
 *   param: nMpcSaPP maloprodajna cijena sa porezom
 *   param: aPorezi Matrica poreza
 *   param: nRabat Rabat
 *   param: nNC Nabavna cijena
 */

FUNCTION MpcBezPor( nMpcSaPP, aPorezi, nRabat, nNC )

   LOCAL nStopa
   LOCAL nPor1
   LOCAL nPor2
   LOCAL nPom
   LOCAL nMPP
   LOCAL nPP
   LOCAL nPDV
   LOCAL nBrutoMarza
   LOCAL nMpcBezPor

   IF nRabat == nil
      nRabat := 0
   ENDIF

   nPDV := aPorezi[ POR_PDV ]

   nPP := 0

   RETURN nMpcSaPP / ( ( nPDV + nPP ) / 100 + 1 )








/*

FUNCTION KorekTar()

   LOCAL cTekIdTarifa
   LOCAL cPriprema

   IF !spec_funkcije_sifra( "SIGMATAR" )
      RETURN .F.
   ENDIF

   my_close_all_dbf()

   o_roba()

   SELECT 0

   cIdVD := Space( 2 )
   cIdTarifa := Space( 6 )

   SET CURSOR ON

   cPriprema := "D"

   Box(, 3, 60 )
   @ box_x_koord() + 1, box_y_koord() + 2 SAY "Vrsta dokumenta (prazno svi)" GET cIdVD
   @ box_x_koord() + 2, box_y_koord() + 2 SAY "Tarifa koju treba zamijeniti (prazno svi)" GET cIdTarifa PICT "@!"
   IF gModul == "KALK"
      @ box_x_koord() + 3, box_y_koord() + 2 SAY "Izvrsiti korekciju nad pripremom D/N ? " GET cPriprema PICT "@!" VALID cPriprema  $ "DN"
   ENDIF

   READ
   Boxc()
   IF LastKey() == K_ESC
      RETURN
   ENDIF

   nKumArea := 0

   IF gModul == "KALK"
      IF cPriprema == "D"
         USE ( my_home() + "PRIPR" )
      ELSE
         USE ( KUMPATH + "KALK" )
      ENDIF
   ELSEIF gModul == "POS"
      USE ( KUMPATH + "POS" )
   ELSE
      CLOSERET
   ENDIF
   nKumArea := Select()

   nC := 0
   Box(, 1, 50 )
   GO TOP
   DO WHILE !Eof()
      IF ( Empty( cIdVD ) .OR. cIdvd == IDVD ) .AND. ( Empty( cIdTarifa ) .OR. cIdTarifa == ( nKumArea )->IdTarifa )
         SELECT roba; HSEEK ( nKumArea )->idroba
         IF !Found()
            MsgBeep( "Artikal " + ( nKumArea )->idroba + " ne postoji u sifraniku robe" )
         ELSE
            SELECT ( nKumArea )

            PRIVATE aPorezi := {}
            IF gModul == "KALK"
               cTekIdTarifa := set_pdv_array_by_koncij_region_roba_idtarifa_2_3( ( nKumArea )->PKONTO, ( nKumArea )->IdRoba, @aPorezi )
            ELSE
               cTekIdTarifa := roba->IdTarifa
            ENDIF
            IF ( nKumArea )->IdTarifa <> cTekIdTarifa
               SELECT ( nKumArea )
               @ box_x_koord() + 1, box_y_koord() + 2 SAY ++Nc PICT "999999"
               @ box_x_koord() + 1, Col() + 2 SAY IdTarifa
               @ box_x_koord() + 1, Col() + 2 SAY "->"
               @ box_x_koord() + 1, Col() + 2 SAY cTekIdTarifa

               REPLACE IdTarifa WITH cTekIdTarifa
               // REPLSQL IdTarifa with cTekIdTarifa
            ENDIF
         ENDIF
      ENDIF
      SELECT ( nKumArea )
      SKIP 1
   ENDDO
   BoxC()

   Select( nKumArea )
   USE

   CLOSERET

   RETURN
*/



/*  kalk_porezi_maloprodaja_legacy_array(aPorezi, nMpc, nMpcSaPP, nNc)
 *    Racunanje poreza u maloprodaji
 *  param: aPorezi Matrica poreza
 *  param: nMpc Maloprodajna cijena
 *  param: nMpcSaPP Maloprodajna cijena sa porezom
 *  param: nNc Nabavna cijena
*/
FUNCTION kalk_porezi_maloprodaja_legacy_array( aPorezi, nMpc, nMpcSaPP, nNc )

   LOCAL nIznPRuc
   LOCAL nP1, nP2, nP3

   // PDV
   nP1 := kalk_porezi_maloprodaja( aPorezi, nMpc, nMpcSaPP )
   nP2 := 0
   nP3 := 0

   RETURN { nP1, nP2, nP3 }


// formatiraj stopa pdv kao string
// " 17 %"
// "15.5%"
FUNCTION stopa_pdv( nPdv )

   IF nPdv == nil
      nPdv := tarifa->pdv
   ENDIF

   IF Round( nPdv, 1 ) == Round( nPdv, 0 )
      RETURN Str( nPdv, 3, 0 ) + " %"
   ENDIF

   RETURN Str( nPdv, 3, 1 ) + "%"
