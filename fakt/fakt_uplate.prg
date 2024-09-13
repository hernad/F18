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
#define X_POS_STANJE f18_max_rows() - 7
#define Y_POS_STANJE f18_max_cols() - 45


FUNCTION fakt_uplate()



   //o_partner()
   O_UPL

   cIdPartner := Space( 6 )
   dDatOd := CToD( "" )
   dDatDo := Date()
   qqTipDok := PadR( "10;", 40 )

   ImeKol := {}
   Kol := {}

   AAdd( ImeKol, { "DATUM UPLATE",    {|| DATUPL   }   } )
   AAdd( ImeKol, { PadC( "OPIS", 30 ),    {|| OPIS     }   } )
   AAdd( ImeKol, { PadC( "IZNOS", 12 ),    {|| IZNOS    }   } )

   FOR i := 1 TO Len( ImeKol )
      AAdd( Kol, i )
   NEXT

   PRIVATE bPartnerUslov := {|| idpartner == cIdpartner }
   PRIVATE bBkTrazi := {|| cIdPartner }
   // Brows ekey uslova

   Box(, f18_max_rows() -5, f18_max_cols() -10 )
   DO WHILE .T.

      @ box_x_koord() + 0, box_y_koord() + 20 SAY PadC( " EVIDENCIJA UPLATA - KUPCI ", 35, Chr( 205 ) )
      @ box_x_koord() + 1, box_y_koord() + 2 SAY8 "Šifra partnera:" GET cIdPartner VALID p_partner( @cIdPartner, 1, 26 )
      @ box_x_koord() + 2, box_y_koord() + 2 SAY8 "Tip dokumenta zaduženja:" GET qqTipDok PICT "@!S20"
      @ box_x_koord() + 3, box_y_koord() + 2 SAY8 "Zaduženja od datuma    :"  GET dDatOd
      @ box_x_koord() + 3, Col() + 1 SAY "do:"  GET dDatDo
      READ
      ESC_BCR

      aUslTD := Parsiraj( qqTipdok, "IdTipdok", "C" )
      IF aUslTD == nil
         MsgBeep( "Provjerite uslov za tip dokumenta !" )
         LOOP
      ENDIF

      // utvrdimo ukupno zaduzenje
      nUkZaduz := UkZaduz()

      set_cursor_on()

      // utvrdimo ukupan iznos uplata
      nUkUplata := UkUplata()

      SELECT ( F_UPL )
      GO TOP

      @ box_x_koord() + X_POS_STANJE - 2, box_y_koord() + 1        SAY REPL( "=", 70 )
      @ box_x_koord() + X_POS_STANJE - 1, box_y_koord() + Y_POS_STANJE SAY8 " (+)     ZADUŽENJE:"
      @ box_x_koord() + X_POS_STANJE - 0, box_y_koord() + Y_POS_STANJE SAY " (-)       UPLATIO:"
      @ box_x_koord() + X_POS_STANJE + 1, box_y_koord() + Y_POS_STANJE SAY " ------------------"
      @ box_x_koord() + X_POS_STANJE + 2, box_y_koord() + Y_POS_STANJE SAY " (=) PREOSTALI DUG:"

      DajStanjeKupca()

      @ box_x_koord() + 4, box_y_koord() + 1 SAY REPL( "=", 70 )

      SEEK cIdPartner // uplate
      my_browse( "EvUpl", f18_max_rows() -5, f18_max_cols() -10, {|| fakt_ed_uplata() }, "", "<c-N> nova uplata  <F2> ispravka  <c-T> brisanje  <c-P> stampanje", ;
         .F., NIL, 1, NIL, 4, 3, NIL, {| nSkip| fakt_uplate_skip_block( nSkip ) } )

   ENDDO
   BoxC()

   my_close_all_dbf()

   RETURN NIL

*/

/*
STATIC FUNCTION fakt_ed_uplata()

   LOCAL fK1 := .F.
   LOCAL nRet := DE_CONT

   DO CASE
   CASE Ch == K_F2  .OR. Ch == K_CTRL_N

      dDatUpl := IF( Ch == K_F2, DATUPL, Date()           )
      cOpis   := IF( Ch == K_F2, OPIS, Space( Len( OPIS ) ) )
      nIznos  := IF( Ch == K_F2, IZNOS, 0                )

      Box( , 3, 60, .F. )
      @ box_x_koord() + 0, box_y_koord() + 10 SAY PadC( IF( Ch == K_F2, "ISPRAVKA EVIDENTIRANE", "EVIDENTIRANJE NOVE" ) + " STAVKE", 40, Chr( 205 ) )
      @ box_x_koord() + 1, box_y_koord() + 2 SAY "Datum uplate" GET dDatUpl
      @ box_x_koord() + 2, box_y_koord() + 2 SAY "Opis        " GET cOpis
      @ box_x_koord() + 3, box_y_koord() + 2 SAY "Iznos       " GET nIznos PICT fakt_pic_iznos()
      READ
      BoxC()

      IF Ch == K_CTRL_N .AND. LastKey() <> K_ESC
         APPEND BLANK
         REPLACE idpartner WITH cidpartner
      ENDIF

      IF LastKey() <> K_ESC
         REPLACE Datupl WITH dDatUpl, opis WITH cOpis, iznos WITH nIznos
         nUkUplata := UkUplata()
         DajStanjeKupca()
         nRet := DE_REFRESH
      ENDIF

   CASE Ch == K_CTRL_T

      IF Pitanje(, "Izbrisati stavku (D/N) ?", "N" ) == "D"

         delete_with_rlock()
         my_dbf_pack()
         nUkUplata := UkUplata()
         DajStanjeKupca()
         nRet := DE_REFRESH

      ENDIF

   CASE Ch == K_CTRL_P

      StKartKup()
      nRet := DE_REFRESH

   ENDCASE

   RETURN nRet

*/

/*
// ------------------------------------
// DajStanjeKupca()
// Vraca stanje kupca
// ------------------------------------
FUNCTION DajStanjeKupca()

   @ box_x_koord() + X_POS_STANJE - 1, box_y_koord() + Y_POS_STANJE + 20 SAY Str( nUkZaduz, 15, 2 ) COLOR "N/W"
   @ box_x_koord() + X_POS_STANJE, box_y_koord() + Y_POS_STANJE + 20 SAY Str( nUkUplata, 15, 2 ) COLOR "N/W"
   @ box_x_koord() + X_POS_STANJE + 2, box_y_koord() + Y_POS_STANJE + 20 SAY Str( nUkZaduz - nUkUplata, 15, 2 ) COLOR "N/W"

   RETURN NIL

// --------------------------------
// UkZaduz()
// Ukupno zaduzenje
// --------------------------------
FUNCTION UkZaduz()

   LOCAL nArr := Select(), nVrati := 0

   seek_fakt_doks_6( self_organizacija_id(), cIdPartner )  // "6","IdFirma+idpartner+idtipdok"

   DO WHILE !Eof() .AND. idpartner == cIdPartner
      IF datdok >= dDatOd .AND. datdok <= dDatDo .AND. &aUslTD
         nVrati += Round( iznos, fakt_zaokruzenje() )
      ENDIF
      SKIP 1
   ENDDO

   SELECT ( nArr )

   RETURN nVrati

*/

/*
 *     Ukupno uplata
 *   param: lPushWA - .t.-skeniraj pa vrati stanje baze uplata, .f.-ne radi to


FUNCTION UkUplata( lPushWA )

   LOCAL nArr := Select(), nVrati := 0

   IF lPushWA == nil
      lPushWA := .T.
   ENDIF

   SELECT ( F_UPL )

   IF lPushWA
      PushWA()
      SET ORDER TO TAG "2"
   ENDIF

   SEEK cIdPartner // uplate

   DO WHILE !Eof() .AND. idpartner == cIdPartner
      IF datupl >= dDatOd .AND. datupl <= dDatDo
         nVrati += iznos
      ENDIF
      SKIP 1
   ENDDO

   IF lPushWA
      PopWA()
   ENDIF

   SELECT ( nArr )

   RETURN nVrati

*/

/*
STATIC FUNCTION fakt_uplate_skip_block( nRequest )


   LOCAL nCount
   nCount := 0
   IF LastRec() != 0
      IF ! Eval( bPartnerUslov )
         SEEK Eval( bBkTrazi )
         IF ! Eval( bPartnerUslov )
            GO BOTTOM
            SKIP 1
         ENDIF
         nRequest = 0
      ENDIF
      IF nRequest > 0
         DO WHILE nCount < nRequest .AND. Eval( bPartnerUslov )
            SKIP 1
            IF Eof() .OR. !Eval( bPartnerUslov )
               SKIP -1
               EXIT
            ENDIF
            nCount++
         ENDDO
      ELSEIF nRequest < 0
         DO WHILE nCount > nRequest .AND. Eval( bPartnerUslov )
            SKIP -1
            IF ( Bof() )
               EXIT
            ENDIF
            nCount--
         ENDDO
         IF ( !Eval( bPartnerUslov ) )
            SKIP 1
            nCount++
         ENDIF
      ENDIF
   ENDIF

   RETURN ( nCount )

*/

/* StKartKup()
 *     Stanje na kartici kupca


STATIC FUNCTION StKartKup()

   LOCAL nRec := 0

   START PRINT CRET
   ?
   nRec := RecNo()
   GO TOP

   P_10CPI
   ? "FAKT, " + DToC( Date() ) + ", KARTICA KUPCA"
   ? "-----------------------------"
   ?
   ? "ZA PERIOD: OD " + DToC( dDatOd ) + " DO " + DToC( dDatDo )
   ? "KUPAC:", cIdPartner, "-", PARTN->naz
   ?
   ? "-------- " + REPL( "-", Len( opis ) ) + " " + REPL( "-", 10 )
   ? "DAT.UPL.³" + PadC( "OPIS", Len( opis ) ) + "³" + PadC( "IZNOS", 10 )
   ? "-------- " + REPL( "-", Len( opis ) ) + " " + REPL( "-", 10 )

   SEEK cIdPartner // uplate
   DO WHILE !Eof() .AND. idpartner == cIdPartner
      ? datupl
      ?? "|" + opis + "|"
      ?? TRANS( iznos, "9999999.99" )
      SKIP 1
   ENDDO

   ? "-------- " + REPL( "-", Len( opis ) ) + " " + REPL( "-", 10 )
   ?
   ?U " UKUPNO ZADUŽENJE", TRANS( nUkZaduz, "9999999.99" )
   ? "  - UKUPNO UPLATE", TRANS( nUkUplata, "9999999.99" )
   ? "-----------------", "----------"
   ? "  = PREOSTALI DUG", TRANS( nUkZaduz - nUkUplata, "9999999.99" )
   ?

   GO ( nRec )

   FF
   ENDPRINT

   RETURN NIL

*/

// -----------------------------------------------------------------------
// SaldaKupaca(lPocStanje)
// Izvjestaj koji aje salda svih kupaca
// lPocStanje - .t.-generisi i pocetno stanje, .f.-daj samo pregled
// -----------------------------------------------------------------------

/*
FUNCTION SaldaKupaca( lPocStanje )

   LOCAL nUkZaduz
   LOCAL nUkUplata
   LOCAL nStrana
   LOCAL gSezonDir
   LOCAL cDirKum

   gSezonDir := goModul:oDatabase:cSezonDir
   cDirKum := goModul:oDatabase:cDirKum

   IF lPocStanje == nil
      lPocStanje := .F.
   ENDIF

   nStrana := 1

   o_fakt_doks_dbf()

   // "6","IdFirma+idpartner+idtipdok", "DOKS"
   SET ORDER TO TAG "6"
--   o_partner()
   O_UPL
   SET ORDER TO TAG "2"

   IF lPocStanje
      SELECT 0
      usex ( StrTran( cDirKum, gSezonDir, SLASH ) + "UPL", "UPLRP" )
   ENDIF

   cIdPartner := Space( 6 )
   dDatOd     := CToD( "" )
   dDatDo     := Date()
   qqTipDok   := PadR( "10;", 40 )

   Box(, 6, 70 )
   DO WHILE .T.
      IF lPocStanje
         @ box_x_koord() + 0, box_y_koord() + 10 SAY PadC( " GENERISANJE POCETNOG STANJA ZA EVIDENCIJU UPLATA KUPACA ", 55, Chr( 205 ) )
      ELSE
         @ box_x_koord() + 0, box_y_koord() + 20 SAY PadC( " LISTA SALDA KUPACA ", 35, Chr( 205 ) )
      ENDIF
      @ box_x_koord() + 2, box_y_koord() + 2 SAY "Tip dokumenta zaduzenja:" GET qqTipDok PICT "@!S20"
      @ box_x_koord() + 3, box_y_koord() + 2 SAY "Zaduzenja od datuma    :"  GET dDatOd
      @ box_x_koord() + 3, Col() + 1 SAY "do:"  GET dDatDo
      READ
      ESC_BCR

      aUslTD := Parsiraj( qqTipdok, "IdTipdok", "C" )
      IF aUslTD == nil
         MsgBeep( "Provjerite uslov za tip dokumenta !" )
         LOOP
      ENDIF

      set_cursor_on()

      EXIT

   ENDDO
   BoxC()

   SELECT ( F_PARTN )
   SET ORDER TO TAG "ID"
   GO TOP

   START PRINT CRET
   ?
   P_10CPI

   ? "SALDA KUPACA"
   ? "------------"
   ? "Za period:", dDatOd, "-", dDatDo
   ? "Tipovi dokumenata zaduzenja kupaca:", Trim( qqTipDok )

   m1 := PadC( "SIFRA I NAZIV KUPCA", Len( field->id + field->naz ) + 1 ) + " " + PadC( "ZADUZENJA", 12 ) + " " + PadC( "UPLATE", 12 ) + " " + PadC( "SALDO", 12 )
   m2 := REPL( "-", Len( field->id ) ) + " " + REPL( "-", Len( field->naz ) ) + " " + REPL( "-", 12 ) + " " + REPL( "-", 12 ) + " " + REPL( "-", 12 )

   ? m2
   ? m1
   ? m2

   nUkSaldo := 0
   nUUZaduz := 0
   nUUUplata := 0

   DO WHILE !Eof()

      cIdPartner := field->id

      // utvrdimo ukupno zaduzenje
      nUkZaduz := UkZaduz()

      // utvrdimo ukupan iznos uplata
      nUkUplata := UkUplata( .F. )

      IF ( nUkZaduz <> 0 .OR. nUkUplata <> 0 )
         IF ( PRow() > 61 + dodatni_redovi_po_stranici() )
            ? m2
            ?
            ? " " + PadC( AllTrim( Str( nStrana ) ) + ". strana", 78 )
            FF
            ? m2
            ? m1
            ? m2
            ++nStrana
         ENDIF
         ? cIdPartner, field->naz, Str( nUkZaduz, 12, 2 ), Str( nUkUplata, 12, 2 ), Str( nUkZaduz - nUkUplata, 12, 2 )
         nUUZaduz  += nUkZaduz
         nUUUplata += nUkUplata
         nUkSaldo  += nUkZaduz - nUkUplata
         IF ( lPocStanje .AND. nUkZaduz - nUkUplata <> 0 )
            SELECT UPLRP
            APPEND BLANK
            REPLACE field->datupl WITH CToD( "01.01." + Str( Val( Right( gSezonDir, 4 ) ) + 1, 4 ) ), field->idpartner WITH cIdPartner, field->opis WITH "#POCETNO STANJE#", field->iznos WITH -( nUkZaduz - nUkUplata )
            SELECT partn
         ENDIF
      ENDIF

      SKIP 1

   ENDDO

   ? m2
   ? "UKUPNO:   " + Space( 23 ) + Str( nUUZaduz, 12, 2 ) + " " + Str( nUUUplata, 12, 2 ) + " " + Str( nUkSaldo, 12, 2 )
   ?
   ? " " + PadC( AllTrim( Str( nStrana ) ) + ". i posljednja strana", 78 )
   FF
   ENDPRINT

   CLOSERET

   RETURN NIL



FUNCTION GPSUplata()

   LOCAL gSezonDir

   gSezonDir := goModul:oDatabase:cSezonDir

   IF Empty( gSezonDir )
      MsgBeep( "Morate uci u sezonsko podrucje prosle godine!" )
   ELSEIF Pitanje(, "Generisati pocetno stanje za evidenciju uplata? (D/N)", "N" ) == "D"
      SaldaKupaca( .T. )
      MsgBeep( "Generisanje pocetnog stanja za evidenciju uplata zavrseno!#Provjerite salda kupaca u tekucoj godini!" )
   ENDIF

   RETURN NIL

*/
