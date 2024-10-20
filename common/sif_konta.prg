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

MEMVAR ImeKol, Kol

FIELD id, naz
MEMVAR wId

FUNCTION P_Konto( cId, dx, dy )

   LOCAL lRet, i

   PRIVATE ImeKol
   PRIVATE Kol

   ImeKol := {}
   Kol := {}

   PushWA()

   IF cId != NIL .AND. !Empty( cId )
      select_o_konto( "XXXXXXX" ) // cId je zadan, otvoriti samo dummy tabelu sa 0 zapisa
   ELSE
      select_o_konto()
   ENDIF


   AAdd( ImeKol, { PadC( "ID", 7 ), {|| id }, "id", {|| .T. }, {|| valid_sifarnik_id_postoji( wId ) } } )
   AAdd( ImeKol, { "Naziv", {|| naz }, "naz" } )

   FOR i := 1 TO Len( ImeKol )
      AAdd( Kol, i )
   NEXT

   lRet := p_sifra( F_KONTO, 1, f18_max_rows() -15, f18_max_cols() -20, "LKT: Lista: Konta", @cId, dx, dy )

   PopWa()

   RETURN lRet






/*
    *     Obradjuje funkcije nad sifrarnikom konta
    *   param: Ch  - pritisnuti taster
*/

FUNCTION KontoBlok( Ch )

   LOCAL nRec := RecNo(), cId := ""
   LOCAL cSif := KONTO->id, cSif2 := ""

   // @ box_x_koord()+11,45 SAY "<a-P> - stampa k.plana"

   IF Ch == K_CTRL_T .AND. gSKSif == "D"

      // provjerimo da li je sifra dupla
      PushWA()
      SET ORDER TO TAG "ID"
      SEEK cSif
      SKIP 1
      cSif2 := KONTO->id
      PopWA()
      IF !( cSif == cSif2 )
         IF is_konto_ima_u_prometu( KONTO->id )
            Beep( 1 )
            Msg( "Stavka konta se ne moze brisati jer se vec nalazi u knjizenjima!" )
            RETURN 7
         ENDIF
      ENDIF

   ELSEIF Ch == K_F2 .AND. gSKSif == "D"
      IF is_konto_ima_u_prometu( KONTO->id )
         RETURN 99
      ENDIF
   ENDIF

   IF Ch <> K_ALT_P
      RETURN DE_CONT
   ENDIF

   PRIVATE cKonto := Space( 60 )
   PRIVATE cSirIs := "0", cOdvKlas := "N", cOstran := "D"

   DO WHILE .T.
      IF !VarEdit( { { "Konto (prazno-sva)", "cKonto",, "@!S30", }, ;
            { "Sirina ispisa (0 - 10CPI, 1 - 12CPI, 2 - 17CPI, 3 - 20CPI)", "cSirIs", "cSirIs$'0123'",, }, ;
            { "Odvajati klase novom stranicom (D - da, N - ne) ?", "cOdvKlas", "cOdvKlas$'DN'", "@!", }, ;
            { "Ukljuceno ostranicavanje ? (D - da, N - ne) ?", "cOstran", "cOstran$'DN'", "@!", } }, ;
            10, 3, 17, 76, ;
            'POSTAVLJANJE USLOVA ZA PRIKAZ KONTA', ;
            "B1" )
         RETURN DE_CONT
      ENDIF
      aUsl1 := Parsiraj( cKonto, "id" )
      IF aUsl1 <> NIL
         EXIT
      ELSE
         MsgBeep ( "Kriterij za konto nije korektno postavljen!" )
      ENDIF
   ENDDO


   SET FILTER TO &aUsl1


   IF !start_print()
      RETURN .F.
   ENDIF

   ?
   B_ON
   ? "K O N T N I    P L A N"
   ? "----------------------"
   B_OFF
   ?

   IF cSirIs == "1"
      F12CPI
   ELSEIF cSirIs == "2"
      P_COND
   ELSEIF cSirIs == "3"
      P_COND2
   ENDIF

   GO TOP
   DO WHILE ! Eof()
      cId := RTrim( id )

      ? Space( IF( Len( cId ) > 3, 6, IF( Len( cId ) == 3, 3, Len( cId ) -1 ) ) )
      ?? PadR( cId, 15 -PCol(), "." )
      ?? naz
      SKIP 1
      IF cOdvKlas == "D" .AND. Left( cId, 1 ) != Left( id, 1 ) .OR. cOstran == "D" .AND. PRow() > 60 + dodatni_redovi_po_stranici()
         FF
         LOOP
      ENDIF
      IF Len( cId ) > 3 .AND. Len( RTrim( id ) ) < 4 .OR. Len( cId ) == Len( RTrim( id ) ) .AND. Len( cId ) < 4 .OR. Left( cId, 3 ) != Left( id, 3 )
         ?
      ENDIF
   ENDDO

   FF
   end_print()

   SET FILTER TO

   GO nRec

   RETURN DE_CONT



/*
      Funkcija vraca vrijednost polja naziv po zadatom idkonto
*/

FUNCTION GetNameFromKonto( cIdKonto )

   LOCAL nArr, cRet

   nArr := Select()
   select_o_konto( cIdKonto )
   cRet := AllTrim( field->naz )
   SELECT ( nArr )

   RETURN cRet
