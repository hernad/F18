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


FUNCTION ShowKreditor( cKreditor )

   LOCAL nArr

   nArr := Select()

   select_o_kred( cKreditor )

   IF !Eof()
      ? AllTrim( field->id ) + "-" + ( field->naz )
      ? "-" + AllTrim( field->fil ) + "-"
      ? AllTrim( field->adresa ) + ", " + field->ptt + " " + AllTrim( field->mjesto )
   ELSE
      ? _l( "...Nema unesenih podataka...za kreditora..." )
   ENDIF

   SELECT ( nArr )

   RETURN


FUNCTION ShowPPDef()

   ? Space( 5 ) + _l( "Obracunski radnik:" ) + Space( 35 ) + _l( "SEF SLUZBE:" )
   ?
   ? Space( 5 ) + "__________________" + Space( 35 ) + "__________________"

   RETURN


FUNCTION ShowPPFakultet()

   ? Space( 5 ) + _l( "Likvidator:       " ) + Space( 35 ) + _l( "Dekan fakulteta:  " )
   ?
   ? Space( 5 ) + "__________________" + Space( 35 ) + "__________________"

   RETURN


/* ShiwHiredFromTo(dHiredFrom, dHiredTo)
 *     Prikaz podataka angazovan od, angazovan do na izvjestajima, ako je dHiredTo prazno onda prikazuje Trenutno angazovan...
 *   param: dHiredFrom - angazovan od datum
 *   param: dHiredTo - angazovan do datum
 */
FUNCTION ld_angazovan_od_do( dHiredFrom, dHiredTo, cLM )

   // {
   cHiredFrom := DToC( dHiredFrom )
   cHiredTo := DToC( dHiredTo )

   ? cLM + _l( "Angazovan od: " ) + cHiredFrom
   ?? ",  " + _l( "Angazovan do: " )

   IF !Empty( DToS( dHiredTo ) )
      ?? cHiredTo
   ELSE
      ?? _l( "Trenutno angazovan" )
   ENDIF

   RETURN .T.



// ----------------------------------------------
// vraca liniju za doprinose
// ----------------------------------------------
FUNCTION _gdoprline( cDoprSpace )

   LOCAL cLine

   cLine := cLDLijevaMargina
   cLine += Replicate( "-", 4 )
   cLine += Space( 1 )
   cLine += Replicate( "-", 23 )
   cLine += Space( 1 )
   cLine += Replicate( "-", 8 )
   cLine += Space( 1 )
   cLine += Replicate( "-", 13 )
   cLine += Space( 1 )
   cLine += Replicate( "-", 13 )

   RETURN cLine



// -------------------------------------------------
// vraca liniju za podvlacenje tipova primanja
// -------------------------------------------------
FUNCTION _gtprline()

   LOCAL cLine

   cLine := cLDLijevaMargina
   cLine += Replicate( "-", 23 )
   cLine += Space( 1 )
   cLine += Replicate( "-", 8 )
   cLine += Space( 2 )
   cLine += Replicate( "-", 16 )
   cLine += Space( 3 )
   cLine += Replicate( "-", 18 )

   RETURN cLine


// -------------------------------------------------
// vraca liniju za podvlacenje tipova primanja
// -------------------------------------------------
FUNCTION _gmainline()

   LOCAL cLine

   cLine := cLDLijevaMargina
   cLine += Replicate( "-", 52 )
   cLine += Space( 1 )
   cLine += Replicate( "-", 18 )

   RETURN cLine



// ----------------------------
// Porezi i Doprinosi Iz Sezone
// ---------------------------------------------------------------------
// Ova procedura ispituje da li je za izracunavanje poreza i doprinosa
// u izvjestaju potrebno koristiti sifrarnike iz sezone. Ako se ustanovi
// da ovi sifarnici postoje u sezoni 'MMGGGG' podrazumijeva se da njih
// treba koristiti za izvjestaj. U tom slucaju zatvaraju se postojeci
// sifarnici POR i DOPR iz radnog podrucja, a umjesto njih otvaraju se
// sezonski.
// ---------------------------------------------------------------------
// cG - izvjestajna godina, cM - izvjestajni mjesec
// ---------------------------------------------------------------------
// Ukoliko izvjestaj koristi baze POR i/ili DOPR, one moraju biti
// otvorene prije pokretanje ove procedure.
// Ovu proceduru najbolje je pozivati odmah nakon upita za izvjestajnu
// godinu i mjesec (prije toga nema svrhe), a prije glavne izvjestajne
// petlje.
// ---------------------------------------------------------------------
FUNCTION ld_porezi_i_doprinosi_iz_sezone( cG, cM )

   LOCAL nArr := Select()
   LOCAL cPath
   LOCAL aSez
   LOCAL i
   LOCAL cPom
   LOCAL lPor
   LOCAL lDopr
   LOCAL cPorDir
   LOCAL cDoprDir

   IF ( cG == NIL .OR. cM == nil )
      RETURN
   ENDIF

   IF ValType( cG ) == "N"
      cG := Str( cG, 4, 0 )
   ENDIF

   IF ValType( cM ) == "N"
      cM := PadL( AllTrim( Str( cM ) ), 2, "0" )
   ENDIF

   cPath := SIFPATH
   aSez := ASezona2( cPath, cG )

   IF Len( aSez ) < 1
      RETURN
   ENDIF

   lPor := .F.
   lDopr := .F.
   cPorDir := ""
   cDoprDir := ""

   FOR i := 1 TO Len( aSez )
      cPom := Trim( aSez[ i, 1 ] )
      IF Left( cPom, 2 ) >= cM
         IF File( cpath + cPom + "\POR.DBF" )
            lPor     := .T.
            cPorDir  := cPom
         ENDIF
         IF File( cpath + cPom + "\DOPR.DBF" )
            lDopr    := .T.
            cDoprDir := cPom
         ENDIF
      ELSE
         EXIT
      ENDIF
   NEXT

   IF lPor
      SELECT ( F_POR )
      USE
      USE ( cPath + cPorDir + "\POR" )
      SET ORDER TO TAG "ID"

      IF RecCount() = 0
         // ako je sifrarnik prazan, vrati se na
         // tekuci
         SELECT F_POR
         USE
         o_por()
      ENDIF

   ENDIF

   IF lDopr
      SELECT ( F_DOPR )
      USE
      USE ( cPath + cDoprDir + "\DOPR" )
      SET ORDER TO TAG "ID"
      IF RecCount() = 0
         // ako je sifrarnik prazan, vrati se na
         // tekuci
         SELECT F_DOPR
         USE
         o_dopr()
      ENDIF

   ENDIF

   SELECT ( nArr )

   RETURN


FUNCTION ASezona2( cPath, cG, cFajl )

   LOCAL aSez
   LOCAL i
   LOCAL cPom

   IF cFajl == NIL
      cFajl := ""
   ENDIF

   aSez := Directory( cPath + "*.", "DV" )

   FOR i := Len( aSez ) TO 1 STEP -1
      IF aSez[ i, 1 ] == "." .OR. aSez[ i, 1 ] == ".."
         ADel( aSez, i )
         ASize( aSez, Len( aSez ) -1 )
      ENDIF
   NEXT

   FOR i := Len( aSez ) TO 1 STEP -1
      cPom := Trim( aSez[ i, 1 ] )
      IF Len( cPom ) <> 6 .OR. Right( cPom, 4 ) <> cG .OR. ;
            !Empty( cFajl ) .AND. !File( cPath + cPom + SLASH + cFajl )
         ADel( aSez, i )
         ASize( aSez, Len( aSez ) -1 )
      ENDIF
   NEXT
   ASort( aSez,,, {| x, y| x[ 1 ] > y[ 1 ] } )

   RETURN aSez


FUNCTION Cijelih( cPic )

   LOCAL nPom := ATTOKEN( AllTrim( cPic ), ".", 2 ) - 2

   RETURN IF( nPom < 1, Len( AllTrim( cPic ) ), nPom )

FUNCTION Decimala( cPic )

   LOCAL nPom := ATTOKEN( AllTrim( cPic ), ".", 2 )

   RETURN IF( nPom < 1, 0,  Len( SubStr( AllTrim( cPic ), nPom ) )  )


// ------------------------------------
// vraca opis tipa primanja
// ------------------------------------
FUNCTION sh_tp_opis( cIdTipPr, cRadn  )

   LOCAL cRet

   cRet := tippr->opis

   IF "##" $ cRet
      cRet := _opis_param( cRet, cRadn )
   ENDIF

   RETURN cRet


// ---------------------------------------
// vraca opis iz parametra
// ---------------------------------------
STATIC FUNCTION _opis_param( cRet, cRadn )

   LOCAL cVal := ""
   LOCAL nTArea := Select()
   PRIVATE cF_Tmp

   // opis je ##S9##
   // prvo ukini znakove "##"
   cF_Tmp := StrTran( cRet, "#", "" )

   // ako ne postoji polje...
   IF radn->( FieldPos( cF_Tmp ) ) = 0
      RETURN cVal
   ENDIF

   select_o_radn( cRadn )

   SELECT ( nTArea )

   cVal := radn->( &cF_Tmp )

   RETURN cVal
