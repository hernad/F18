#include "f18.ch"

MEMVAR Kol, ImeKol

STATIC s_cLastFtxtIdShow := "  "


FUNCTION p_fakt_ftxt( cId, dx, dy )

   LOCAL xRet
   LOCAL nDbfArea := Select()
   LOCAL nBottom
   LOCAL nTop
   LOCAL nLeft
   LOCAL nRight
   LOCAL nBoxHeight := f18_max_rows() - 20
   LOCAL nBoxWidth := f18_max_cols() - 3
   LOCAL nI
   PRIVATE ImeKol
   PRIVATE Kol

   PushWA()

   IF cId != NIL .AND. !Empty( cId )
      select_o_fakt_txt( "XXXXXXX" ) // cId je zadan, otvoriti samo dummy tabelu sa 0 zapisa
   ELSE
      select_o_fakt_txt()
   ENDIF

   ImeKol := {}
   Kol := {}

   AAdd( ImeKol, { PadR( "ID", 2 ),   {|| id },     "id", {|| .T. }, {|| validacija_postoji_sifra( wid ) }    } )
   // add_mcode( @ImeKol )
   // AAdd( ImeKol, { "Naziv",  {|| naz },  "naz", {|| .T. }, {|| wNaz := StrTran( wnaz, "##", hb_eol() ), .T. }, NIL, "@S50" } )
   AAdd( ImeKol, { "Naziv",  {|| naz },  "naz", {|| fakt_ftxt_naz_tarabiraj( @wNaz ) }, {|| .T. }, NIL, "@S50" } )

   FOR nI := 1 TO Len( ImeKol )
      AAdd( Kol, nI )
   NEXT

   nBottom := 12
   nTop := 3
   nLeft := 1
   nRight := f18_max_cols() - 3

   Box_crno_na_zuto( nTop, nLeft, nBottom, nRight, "Pregled uzoraka teksta na kraju fakture:" )

   @ nBottom, 0 SAY ""

   xRet := p_sifra( F_FAKT_FTXT, 1, nBoxHeight, nBoxWidth, "Faktura - tekst na kraju fakture", @cId, , , {|| fakt_ftxt_keyboard_handler( nTop, nLeft, 8, nRight ) } )

   box_crno_na_zuto_end()

   SELECT ( nDbfArea )
   PopWa()

   RETURN xRet


STATIC FUNCTION fakt_ftxt_naz_tarabiraj( cNaz )

   cNaz := StrTran( cNaz, NRED_DOS, "##" )
   cNaz := StrTran( cNaz, hb_eol(), "##" )

   RETURN .T.


/*
 *     Prikazuje uzorak teksta
 */

FUNCTION fakt_ftxt_keyboard_handler( nTopPos, nLeftPos, nBottomPos, nTxtLenght )

   LOCAL nI := 0

   // LOCAL cFaktTxt
   LOCAL aFtxt := {}

   IF s_cLastFtxtIdShow == field->id
      RETURN DE_CONT
   ENDIF

   // Tb:RefreshCurrent()
   @ nTopPos, 6 SAY "uzorak teksta id: " + field->id
   s_cLastFtxtIdShow := field->id

   aFtxt := fakt_txt_clean_array( field->naz )
   // aFtxt := decode_string_to_array( cFaktTxt, nTxtLenght - 1 - nLeftPos, "##" )

   FOR nI := 1 TO nBottomPos
      IF nI > Len( aFtxt )
         @ nTopPos + nI, nLeftPos + 1 SAY Space( nTxtLenght - 1 - nLeftPos )
      ELSE
         @ nTopPos + nI, nLeftPos + 1 SAY PadR( aFtxt[ nI ], nTxtLenght - 1 - nLeftPos )
      ENDIF
   NEXT

   RETURN DE_CONT


/*
    *  "prvi red" + hb_eol() + "drugi red" => { "prvi red", "drugi red" }
    *  param cTxt   - tekst
    *  param nKol   - broj kolona


FUNCTION decode_string_to_array( cTxt, nKol, cSeparator )

   LOCAL aVrati := {}, lNastavi := .T., cPom := "", aPom := {}, nI := 0
   LOCAL nPoz := 0

   IF cSeparator == NIL
      cSeparator := NRED_DOS
   ENDIF

   cTxt := Trim( cTxt )
   DO WHILE lNastavi
      nPoz := At( NRED_DOS, cTxt )
      IF nPoz > 0
         cPom := Left( cTxt, nPoz - 1 )
         IF nPoz - 1 > nKol
            cPom := Trim( LomiGa( cPom, 1, 5, nKol ) )
            FOR  nI := 1  TO  Int( ( Len( cPom ) - 1 ) / nKol ) + 1
               AAdd( aVrati, SubStr( cPom, ( nI - 1 ) * nKol + 1, nKol ) )
            NEXT
         ELSE
            AAdd( aVrati, cPom )
         ENDIF
         cTxt := SubStr( cTxt, nPoz + 2 )
      ELSEIF !Empty( cTxt )
         cPom := Trim( cTxt )
         IF Len( cPom ) > nKol
            cPom := Trim( LomiGa( cPom, 1, 5, nKol ) )
            FOR  nI := 1  TO  Int( ( Len( cPom ) - 1 ) / nKol ) + 1
               AAdd( aVrati, SubStr( cPom, ( nI - 1 ) * nKol + 1, nKol ) )
            NEXT
         ELSE
            AAdd( aVrati, cPom )
         ENDIF
         lNastavi := .F.
      ELSE
         lNastavi := .F.
      ENDIF
   ENDDO

   RETURN aVrati
*/


FUNCTION fakt_ftxt_decode_string( cFaktTxt )

   LOCAL hFaktParams := fakt_params()
   LOCAL aMemo := fakt_ftxt_decode( cFaktTxt )
   LOCAL nLen := Len( aMemo )
   LOCAL hFaktTxt := hb_Hash()

   IF hFaktParams[ "destinacije" ]
      hFaktTxt[ "destinacija" ] := PadR( "", 500 )
   ENDIF

   IF hFaktParams[ "fakt_dok_veze" ]
      hFaktTxt[ "dokument_veza" ] := PadR( "", 500 )
   ENDIF

   IF hFaktParams[ "fakt_objekti" ]
      hFaktTxt[ "objekti" ] := Space( 10 )
   ENDIF

   hFaktTxt[ "opis_usluga" ] := ""
   hFaktTxt[ "txt2" ] := ""

   hFaktTxt[ "partner_txt_a" ] := ""
   hFaktTxt[ "partner_txt_b" ] := ""
   hFaktTxt[ "partner_txt_c" ] := ""

   hFaktTxt[ "brotp" ] := Space( 50 )
   hFaktTxt[ "datotp" ] := CToD( "" )
   hFaktTxt[ "brnar" ] := Space( 50 )
   hFaktTxt[ "datpl" ] := CToD( "" )
   hFaktTxt[ "veza_otpremnice" ] := ""
   hFaktTxt[ "destinacija" ] := SPACE( 100 )
   hFaktTxt[ "dokument_veza" ] := PadR( "", 500 )
   hFaktTxt[ "objekti" ] := ""

   hFaktTxt[ "d2k1" ] := Space( 15 )
   hFaktTxt[ "d2k2" ] := Space( 15 )
   hFaktTxt[ "d2k3" ] := Space( 15 )
   hFaktTxt[ "d2k4" ] := Space( 20 )
   hFaktTxt[ "d2k5" ] := Space( 20 )
   hFaktTxt[ "d2n1" ] := Space( 12 )
   hFaktTxt[ "d2n2" ] := Space( 12 )

   IF cFaktTxt == NIL .OR. Empty( cFaktTxt )
      RETURN hFaktTxt
   ENDIF


   IF nLen > 0
      hFaktTxt[ "opis_usluga" ] := aMemo[ 1 ]
   ENDIF

   IF nLen >= 2
      hFaktTxt[ "txt2" ] := aMemo[ 2 ]
   ENDIF

   hFaktTxt[ "partner_txt_a" ] := aMemo[ 3 ]
   hFaktTxt[ "partner_txt_b" ] := aMemo[ 4 ]
   hFaktTxt[ "partner_txt_c" ] := aMemo[ 5 ]

   IF nLen >= 9
      hFaktTxt[ "brotp" ] := aMemo[ 6 ]
      hFaktTxt[ "datotp" ] := CToD( aMemo[ 7 ] )
      hFaktTxt[ "brnar" ] := aMemo[ 8 ]
      hFaktTxt[ "datpl" ] := CToD( aMemo[ 9 ] )
   ENDIF

   IF nLen >= 10 .AND. !Empty( aMemo[ 10 ] )
      hFaktTxt[ "veza_otpremnice" ] := aMemo[ 10 ]
   ENDIF

   IF nLen >= 11
      hFaktTxt[ "d2k1" ] := aMemo[ 11 ]
   ENDIF

   IF nLen >= 12
      hFaktTxt[ "d2k2" ] := aMemo[ 12 ]
   ENDIF

   IF nLen >= 13
      hFaktTxt[ "d2k3" ] := aMemo[ 13 ]
   ENDIF

   IF nLen >= 14
      hFaktTxt[ "d2k4" ] := aMemo[ 14 ]
   ENDIF

   IF nLen >= 15
      hFaktTxt[ "d2k5" ] := aMemo[ 15 ]
   ENDIF

   IF nLen >= 16
      hFaktTxt[ "d2n1" ] := aMemo[ 16 ]
   ENDIF

   IF nLen >= 17
      hFaktTxt[ "d2n2" ] := aMemo[ 17 ]
   ENDIF

   IF hFaktParams[ "destinacije" ] .AND. nLen >= 18 // parametri - mnozina - desinacijE
      hFaktTxt[ "destinacija" ] := PadR( AllTrim( aMemo[ 18 ] ), 500 ) // hFaktTxt - jednina - destinacijA
   ENDIF

   IF hFaktParams[ "fakt_dok_veze" ] .AND. nLen >= 19
      hFaktTxt[ "dokument_veza" ] := PadR( AllTrim( aMemo[ 19 ] ), 500 )
   ENDIF

   IF hFaktParams[ "fakt_objekti" ] .AND. nLen >= 20
      hFaktTxt[ "objekti" ] := PadR( aMemo[ 20 ], 10 )
   ENDIF

   RETURN hFaktTxt



FUNCTION fakt_ftxt_encode_5( hFaktTxt )

   LOCAL _tmp
   LOCAL hFaktParams := fakt_params()
   LOCAL cTxt
   LOCAL cDestinacija, cDokumentVeze, cObjekti

   // odsjeci na kraju prazne linije
   // hFaktTxt[ "txt2" ] := OdsjPLK( hFaktTxt[ "txt2" ] )

   IF !Empty( hFaktTxt[ "veza_otpremnice" ] ) .AND. ( ! "Račun formiran na osnovu:" $ hFaktTxt[ "txt2" ] )
      hFaktTxt[ "txt2" ] := hFaktTxt[ "txt2" ] + NRED_DOS + hFaktTxt[ "veza_otpremnice" ]
   ENDIF

   cTxt := Chr( 16 ) + Trim( hFaktTxt[ "opis_usluga" ] ) + Chr( 17 )
   cTxt += Chr( 16 ) + hFaktTxt[ "txt2" ] + Chr( 17 )
   cTxt += Chr( 16 ) + hFaktTxt[ "partner_txt_a" ] + Chr( 17 )
   cTxt += Chr( 16 ) + hFaktTxt[ "partner_txt_b" ] + Chr( 17 )
   cTxt += Chr( 16 ) + hFaktTxt[ "partner_txt_c" ] + Chr( 17 )

   // 6 - br otpr
   cTxt += Chr( 16 ) + hFaktTxt[ "brotp" ] + Chr( 17 )
   // 7 - dat otpr
   cTxt += Chr( 16 ) + DToC( hFaktTxt[ "datotp" ] ) + Chr( 17 )
   // 8 - br nar
   cTxt += Chr( 16 ) + hFaktTxt[ "brnar" ] + Chr( 17 )
   // 9 - dat nar
   cTxt += Chr( 16 ) + DToC( hFaktTxt[ "datpl" ] ) + Chr( 17 )
   // 10
   cTxt += Chr( 16 ) + hFaktTxt[ "veza_otpremnice" ] + Chr( 17 )
   // 11
   cTxt += Chr( 16 ) + hFaktTxt[ "d2k1" ] + Chr( 17 )
   cTxt += Chr( 16 ) + hFaktTxt[ "d2k2" ] + Chr( 17 )
   cTxt += Chr( 16 ) + hFaktTxt[ "d2k3" ] + Chr( 17 )
   cTxt += Chr( 16 ) + hFaktTxt[ "d2k4" ] + Chr( 17 )
   cTxt += Chr( 16 ) + hFaktTxt[ "d2k5" ] + Chr( 17 )
   cTxt += Chr( 16 ) + hFaktTxt[ "d2n1" ] + Chr( 17 )
   cTxt += Chr( 16 ) + hFaktTxt[ "d2n2" ] + Chr( 17 )

   IF hFaktParams[ "destinacije" ]
      cDestinacija := hFaktTxt[ "destinacija" ]
   ELSE
      cDestinacija := ""
   ENDIF

   // 18 - Destinacija
   cTxt += Chr( 16 ) + AllTrim( cDestinacija ) + Chr( 17 )

   // 19 - vezni dokumenti
   IF hFaktParams[ "fakt_dok_veze" ]
      cDokumentVeze := AllTrim( hFaktTxt[ "dokument_veza" ] )
   ELSE
      cDokumentVeze := ""
   ENDIF
   cTxt += Chr( 16 ) + cDokumentVeze + Chr( 17 )

   // 20 - objekti
   IF hFaktParams[ "fakt_objekti" ]
      cObjekti := hFaktTxt[ "objekti" ]
   ELSE
      cObjekti := ""
   ENDIF
   cTxt += Chr( 16 ) + cObjekti + Chr( 17 )

   RETURN cTxt


/*
FUNCTION fakt_ftxt_encode_2( aFaktTxtIn, cBrNar, cBrOtpr, dDatOtpr, dDatPl )

   LOCAL cFaktTxtNovi, nI

   // roba tip U
   cFaktTxtNovi := Chr( 16 ) + aFaktTxtIn[ 1 ] + Chr( 17 )
   // dodatni tekst fakture
   cFaktTxtNovi += Chr( 16 ) + aFaktTxtIn[ 2 ] + Chr( 17 )
   // naziv partnera
   cFaktTxtNovi += Chr( 16 ) + AllTrim( partn->naz ) + Chr( 17 )
   // partner 2 podaci
   cFaktTxtNovi += Chr( 16 ) + AllTrim( partn->adresa ) + ", Tel:" + AllTrim( partn->telefon ) + Chr( 17 )
   // partner 3 podaci
   cFaktTxtNovi += Chr( 16 ) + AllTrim( partn->ptt ) + " " + AllTrim( partn->mjesto ) + Chr( 17 )
   // broj otpremnice
   cFaktTxtNovi += Chr( 16 ) + cBrOtpr + Chr( 17 )
   // datum otpremnice
   cFaktTxtNovi += Chr( 16 ) + DToC( dDatOtpr ) + Chr( 17 )
   // broj narudzbenice
   cFaktTxtNovi += Chr( 16 ) + cBrNar + Chr( 17 )
   // datum placanja
   cFaktTxtNovi += Chr( 16 ) + DToC( dDatPl ) + Chr( 17 )

   IF Len( aFaktTxtIn ) > 9
      FOR nI := 10 TO Len( aFaktTxtIn )
         cFaktTxtNovi += Chr( 16 ) + aFaktTxtIn[ nI ] + Chr( 17 )
      NEXT
   ENDIF

   RETURN cFaktTxtNovi
*/

/*
FUNCTION fakt_ftxt_encode_3( cTxt1, cTxt2, cPartner_txt_a, cPartner_txt_b, cPartner_txt_c, ;
      _BrOtp, _BrNar, _DatOtp, _DatPl, cVezaOtpremnica, ;
      _dest, _m_dveza )

   RETURN Chr( 16 ) + Trim( cTxt1 ) + Chr( 17 ) + Chr( 16 ) + cTxt2 + Chr( 17 ) + ;
      Chr( 16 ) + Trim( cPartner_txt_a ) + Chr( 17 ) + Chr( 16 ) + cPartner_txt_b + Chr( 17 ) + ;
      Chr( 16 ) + Trim( cPartner_txt_c ) + Chr( 17 ) + ;
      Chr( 16 ) + _BrOtp + Chr( 17 ) + ;
      Chr( 16 ) + DToC( _DatOtp ) + Chr( 17 ) + ;
      Chr( 16 ) + _BrNar + Chr( 17 ) + ;
      Chr( 16 ) + DToC( _DatPl ) + Chr( 17 ) + ;
      iif( Empty ( cVezaOtpremnica ), "", Chr( 16 ) + cVezaOtpremnica + Chr( 17 ) ) + ;
      Chr( 16 ) + Chr( 17 ) + ;
      Chr( 16 ) + Chr( 17 ) + ;
      Chr( 16 ) + Chr( 17 ) + ;
      Chr( 16 ) + Chr( 17 ) + ;
      Chr( 16 ) + Chr( 17 ) + ;
      Chr( 16 ) + Chr( 17 ) + ;
      Chr( 16 ) + Chr( 17 ) + ;
      Chr( 16 ) + Trim( _dest ) + Chr( 17 ) + ;
      Chr( 16 ) + Trim( _m_dveza ) + Chr( 17 )
*/

/*
FUNCTION fakt_ftxt_encode_4( cTxt1, cTxt2, cPartner_txt_a, cPartner_txt_b, cPartner_txt_c, _BrOtp, _DatOtp, ;
      _BrNar, _DatPl, _VezOtpr, d2k1, d2k2, d2k3, d2k4, d2k5, d2n1, d2n2 )

   RETURN Chr( 16 ) + Trim( cTxt1 ) + Chr( 17 ) + Chr( 16 ) + cTxt2 + Chr( 17 ) + ;
      Chr( 16 ) + Trim( cPartner_txt_a ) + Chr( 17 ) + Chr( 16 ) + cPartner_txt_b + Chr( 17 ) + ;
      Chr( 16 ) + Trim( cPartner_txt_c ) + Chr( 17 ) + ;
      Chr( 16 ) + _BrOtp + Chr( 17 ) + ;
      Chr( 16 ) + DToC( _DatOtp ) + Chr( 17 ) + ;
      Chr( 16 ) + _BrNar + Chr( 17 ) + ;
      Chr( 16 ) + DToC( _DatPl ) + Chr( 17 ) + ;
      iif ( Empty ( _VezOtpr ), Chr( 16 ) + "" + Chr( 17 ), Chr( 16 ) + _VezOtpr + Chr( 17 ) ) + ;
      Chr( 16 ) + d2k1 + Chr( 17 ) + ;
      Chr( 16 ) + d2k2 + Chr( 17 ) + ;
      Chr( 16 ) + d2k3 + Chr( 17 ) + ;
      Chr( 16 ) + d2k4 + Chr( 17 ) + ;
      Chr( 16 ) + d2k5 + Chr( 17 ) + ;
      Chr( 16 ) + d2n1 + Chr( 17 ) + ;
      Chr( 16 ) + d2n2 + Chr( 17 )
*/



FUNCTION fakt_ftxt_sub_renumeracija_pripreme( cTxt2 )

   LOCAL cId := "  "
   LOCAL cUserName

   IF _IdTipDok $ "10#20" .AND. partner_is_ino( _IdPartner )
      fakt_ftxt_ino_klauzula()
      IF Empty( AllTrim( cTxt2 ) )
         cId := "IN"
      ENDIF
   ENDIF


   IF Empty( AllTrim( cTxt2 ) )
      cId := "KS"
   ENDIF


   IF ( nRbr == 1 .AND. Val( _podbr ) < 1 )

      Box(, 9, 75 )

      @ box_x_koord() + 1, box_y_koord() + 1  SAY "Uzorak teksta (<c-W> za kraj unosa teksta):"  GET cId PICT "@!"
      READ

      IF LastKey() <> K_ESC .AND. !Empty( cId )

         p_fakt_ftxt( @cId )

         select_o_fakt_txt( cId )

         SELECT fakt_pripr

         cTxt2 := Trim( FAKT_FTXT->naz )

         cUserName := f18_user_name()

         IF !Empty( cUserName ) .AND. cUserName <> "?user?"
            cTxt2 += "Dokument izradio: " + cUserName
         ENDIF

         SELECT fakt_pripr

         // IF glDistrib .AND. _IdTipdok == "26"
         // IF cId $ ";"
         // _k2 := "OPOR"
         // ELSE
         // _k2 := ""
         // ENDIF
         // ENDIF

      ENDIF

      SetColor( f18_color_invert()  )

      PRIVATE fUMemu := .T.
      cTxt2 := MemoEdit( cTxt2, box_x_koord() + 3, box_y_koord() + 1, box_x_koord() + 9, box_y_koord() + 76 )

      fUMemu := NIL

      SetColor( f18_color_normal() )

      BoxC()

   ENDIF

   RETURN .T.




FUNCTION fakt_ftxt_ino_klauzula()

   LOCAL hRec

   PushWA()

   IF !select_o_fakt_txt( "IN" )

      APPEND BLANK
      hRec := dbf_get_rec()

      hRec[ "id" ] := "IN"
      hRec[ "naz" ] := "Porezno oslobadjanje na osnovu (nulta stopa) na osnovu clana 27. stav 1. tacka 1. ZPDV - izvoz dobara iz BIH"
      update_rec_server_and_dbf( "fakt_ftxt", hRec, 1, "FULL" )

   ENDIF

   PopWa()

   RETURN .T.



/*
   koristi se u gen_ugovori_2.prg, fakt_barkod_terminal.prg
*/

FUNCTION fakt_add_to_public_var_txt_uokviri_sa_chr16_chr17( cVal, lEmpty )

   LOCAL nTArr

   nTArr := Select()

   IF lEmpty == nil
      lEmpty := .F.
   ENDIF

   IF !lEmpty .AND. Empty( cVal )  // ako je prazno nemoj dodavati
      RETURN .F.
   ENDIF
   _txt += Chr( 16 ) + cVal + Chr( 17 )

   SELECT ( nTArr )

   RETURN .T.



FUNCTION fakt_ftxt_add_text_by_id( cTxt, cIdFaktTxt )

   LOCAL cUserName

   IF Empty( cIdFaktTxt )
      RETURN .F.
   ENDIF

   IF cIdFaktTxt == "DI" // poseban tip DI: dokument izradio
      cUserName := f18_user_name()
      IF !Empty( cUserName ) .AND. cUserName <> "?user?"
         IF !( "Dokument izradio:" $ cTxt )
            cTxt += NRED_DOS + "Dokument izradio: " + cUserName
            RETURN .T.
         ENDIF
      ENDIF
   ENDIF

   IF !select_o_fakt_txt( cIdFaktTxt )
      SELECT fakt_pripr
      RETURN .F.
   ENDIF

   SELECT fakt_pripr
   IF !Empty( cTxt )
      cTxt += NRED_DOS
   ENDIF
   cTxt += Trim( FAKT_FTXT->naz )

   RETURN .T.


FUNCTION f18_user_name()

   RETURN AllTrim( GetFullUserName( f18_get_user_id() ) )



FUNCTION fakt_ftxt_encode_gen_ugovori( cFTxtNaz, cTxt1, cPartner_txt_a, cPartner_txt_b, cPartner_txt_c, cVezaUgovor, cDodTxt )

   RETURN Chr( 16 ) + cTxt1 + Chr( 17 ) + ;
      Chr( 16 ) + Trim( cFTxtNaz ) + Chr( 13 ) + Chr( 10 ) + ;
      cVezaUgovor + Chr( 13 ) + Chr( 10 ) + ;
      cDodTxt + Chr( 17 ) + Chr( 16 ) + ;
      cPartner_txt_a + Chr( 17 ) + Chr( 16 ) + cPartner_txt_b + Chr( 17 ) + ;
      Chr( 16 ) + cPartner_txt_c + Chr( 17 )



/*
   FUNCTION OdsjPLK( cTxt )

      LOCAL i

      FOR i := Len( cTxt ) TO 1 STEP -1
         IF !( SubStr( cTxt, i, 1 ) $ Chr( 13 ) + Chr( 10 ) + " " )
            EXIT
         ENDIF
      NEXT

      RETURN Left( cTxt, i )
*/


FUNCTION fakt_ftxt_decode( cTxt )

   // Struktura cTxt-a je: Chr(16) txt1 Chr(17)  Chr(16) txt2 Chr(17) ...
   LOCAL aMemo := {}
   LOCAL nI, cPom, fPoc, nLen

   fPoc := .F.
   cPom := ""

   FOR nI := 1 TO Len( cTxt )

      IF  SubStr( cTxt, nI, 1 ) == Chr( 16 )
         fPoc := .T.
      ELSEIF  SubStr( cTxt, nI, 1 ) == Chr( 17 )
         fPoc := .F.
         AAdd( aMemo, cPom )
         cPom := ""
      ELSEIF fPoc
         cPom := cPom + SubStr( cTxt, nI, 1 )
      ENDIF
   NEXT

   nLen := Len( aMemo )

   // uvijek neka vrati polje od 20 elemenata

   FOR nI := 1 TO ( 20 - nLen )
      AAdd( aMemo, "" )
   NEXT

   RETURN aMemo




// -----------------------------------------------
// filovanje dodatnog teksta
// cTxt - dodatni tekst
// cPartn - id partner
// -----------------------------------------------
FUNCTION porezna_faktura_dodatni_tekst( cTxt, cPartn )

   LOCAL aLines // matrica sa linijama teksta
   LOCAL nFId // polje Fnn counter od 20 pa nadalje
   LOCAL nCnt // counter upisa u DRNTEXT
   LOCAL aTxt, n, i

   porezna_faktura_fakt_txt_djokeri( @cTxt, cPartn )


   // slobodni tekst se upisuje u DRNTEXT od F20 -- F50

   // DRNTEXT.F20 = "Linija1"
   // DRNTEXT.F21 = "Linija2"
   // DRNTEXT.222 = "Zadnja linija - 3. kraj."

   // cTxt := StrTran( cTxt, "" + Chr( 10 ), "" )

   aLines := fakt_txt_clean_array( cTxt )

   nFId := 20
   nCnt := 0
   FOR i := 1 TO Len( aLines )
      aTxt := SjeciStr( aLines[ i ], 250 )
      FOR n := 1 TO Len( aTxt )
         add_drntext( "F" + AllTrim( Str( nFId ) ), aTxt[ n ] )
         ++nFId
         ++nCnt
      NEXT
   NEXT


   add_drntext( "P02", AllTrim( Str( nCnt ) ) )  // dodaj i parametar koliko ima linija dodatnog teksta

   RETURN .T.

STATIC FUNCTION fakt_txt_clean_array( cTxt )

   LOCAL aLines, nLen, nI

   cTxt := StrTran( cTxt, Chr( 13 ), "" )   // Chr(13) = \r ibrisati, Chr(10) = \n ce se koristit kao markeri novog reda
   cTxt := StrTran( cTxt, Chr( 141 ) + Chr( 10 ), ""  )  // Ž\n izvrnuto
   cTxt := StrTran( cTxt, Chr( 141 ), ""  )  // Ž izvrnuto

   cTxt := StrTran( cTxt, "##", "#]"  )  // ## -> EOL znak #]

   cTxt := StrTran( cTxt, Chr( 10 ), "#]" )  // Chr(10) marker novog reda -> #]

   cTxt := StrTran( cTxt, "#]#]", Chr( 200 ) + " " + Chr( 200 ) ) // ubaciti space-ove da se ne "gutaju" prazne linije unutar texta
   cTxt := StrTran( cTxt, "#]", Chr( 200 ) )
   // aLines := TokToNiz( cTxt, NRED_DOS ) // matrica sa tekstom line1, line2
   aLines := TokToNiz( cTxt, Chr( 200 ) )

   nLen := Len( aLines )

   FOR nI := 1 TO nLen - 1
      IF Empty( ATail( aLines ) )
         aLines := ASize( aLines, Len( aLines ) - 1 )
      ENDIF
   NEXT

   RETURN aLines


STATIC FUNCTION porezna_faktura_fakt_txt_djokeri( cTxt, cPartn )

   LOCAL cPom
   LOCAL cPom2
   LOCAL nSaldoKup
   LOCAL nSaldoDob
   LOCAL dPUplKup
   LOCAL dPPromKup
   LOCAL dPPromDob
   LOCAL cStrSlKup := "#SALDO_KUP#"
   LOCAL cStrSlDob := "#SALDO_DOB#"
   LOCAL cStrSlKD := "#SALDO_KUP_DOB#"
   LOCAL cStrDUpKup := "#D_P_UPLATA_KUP#"
   LOCAL cStrDPrKup := "#D_P_PROMJENA_KUP#"
   LOCAL cStrDPrDob := "#D_P_PROMJENA_DOB#"

   IF gFaktPrikazFinSaldaKupacDobavljac == "N"
      RETURN .F.
   ENDIF

   IF gFinKtoDug <> nil

      __KTO_DUG := gFinKtoDug
      __KTO_POT := gFinKtoPot

   ENDIF

   // varijanta prikaza salda... 1 ili 2
   __SH_SLD_VAR := gFaktPrikazFinSaldaKupacDobavljacVar

   // saldo kupca
   nSaldoKup := get_fin_partner_saldo( cPartn, __KTO_DUG, self_organizacija_id() )

   // saldo dobavljaca
   nSaldoDob := get_fin_partner_saldo( cPartn, __KTO_POT, self_organizacija_id() )

   // datum zadnje uplate kupca
   dPUplKup := g_dpupl_part( cPartn, __KTO_DUG, self_organizacija_id() )

   // datum zadnje promjene kupac
   dPPromKup := datum_posljednje_promjene_kupac_dobavljac( cPartn, __KTO_DUG, self_organizacija_id() )

   // datum zadnje promjene dobavljac
   dPPromDob := datum_posljednje_promjene_kupac_dobavljac( cPartn, __KTO_POT, self_organizacija_id() )


   // -------------------------------------------------------
   // SALDO KUPCA
   // -------------------------------------------------------
   IF At( cStrSlKup, cTxt ) <> 0

      IF gFaktPrikazFinSaldaKupacDobavljac == "D"
         cPom := AllTrim( Str( Round( nSaldoKup, 2 ) ) ) + " KM"
         cPom2 := ""

         IF __SH_SLD_VAR == 2
            cPom2 := "Vas posljednji saldo iznosi: "
         ENDIF
      ELSE

         cPom := ""
         cPom2 := ""

      ENDIF

      cTxt := StrTran( cTxt, cStrSlKup, cPom2 + " " + cPom )
   ENDIF


   // -------------------------------------------------------
   // SALDO DOBAVLJACA
   // -------------------------------------------------------
   IF At( cStrSlDob, cTxt ) <> 0

      IF gFaktPrikazFinSaldaKupacDobavljac == "D"

         cPom := AllTrim( Str( Round( nSaldoDob, 2 ) ) ) + " KM"
         cPom2 := ""

         IF __SH_SLD_VAR == 2
            cPom2 := "Nas posljednji saldo iznosi: "
         ENDIF
      ELSE

         cPom := ""
         cPom2 := ""

      ENDIF

      cTxt := StrTran( cTxt, cStrSlDob, cPom2 + " " + cPom )
   ENDIF

   // -------------------------------------------------------
   // SALDO KUPCA/DOBAVLJACA prebijeno
   // -------------------------------------------------------
   IF At( cStrSlKD, cTxt ) <> 0

      IF gFaktPrikazFinSaldaKupacDobavljac == "D"

         cPom := AllTrim( Str( Round( nSaldoKup, 2 ) - Round( nSaldoDob, 2 ) ) ) + " KM"
         cPom2 := ""

         IF __SH_SLD_VAR == 2
            cPom2 := "Prebijeno stanje kupac/dobavljac : "
         ENDIF
      ELSE

         cPom := ""
         cPom2 := ""

      ENDIF

      cTxt := StrTran( cTxt, cStrSlKD, cPom2 + " " + cPom )
   ENDIF


   // -------------------------------------------------------
   // DATUM POSLJEDNJE UPLATE KUPCA/DOBAVLJACA
   // -------------------------------------------------------
   IF At( cStrDUpKup, cTxt ) <> 0

      IF gFaktPrikazFinSaldaKupacDobavljac == "D"


         // datum posljednje uplate kupca
         cPom := DToC( dPUplKup )
         cPom2 := ""
         IF __SH_SLD_VAR == 2
            cPom2 := "Datum posljednje uplate: "
         ENDIF
      ELSE
         cPom := ""
         cPom2 := ""
      ENDIF

      cTxt := StrTran( cTxt, cStrDUpKup, cPom2 + " " + cPom )
   ENDIF

   // -------------------------------------------------------
   // DATUM POSLJEDNJE PROMJENE NA KONTU KUPCA
   // -------------------------------------------------------
   IF At( cStrDPrKup, cTxt ) <> 0

      IF gFaktPrikazFinSaldaKupacDobavljac == "D"

         // datum posljednje promjene kupac
         cPom := DToC( dPPromKup )
         cPom2 := ""
         IF __SH_SLD_VAR == 2
            cPom2 := "Datum posljednje promjene na kontu kupca: "
         ENDIF

      ELSE
         cPom := ""
         cPom2 := ""

      ENDIF

      cTxt := StrTran( cTxt, cStrDPrKup, cPom2 + " " + cPom )

   ENDIF

   // -------------------------------------------------------
   // DATUM POSLJEDNJE PROMJENE NA KONTU DOBAVLJACA
   // -------------------------------------------------------
   IF At( cStrDPrDob, cTxt ) <> 0

      IF gFaktPrikazFinSaldaKupacDobavljac == "D"
         cPom := DToC( dPPromDob ) // datum posljednje promjene dobavljac
         cPom2 := ""
         IF __SH_SLD_VAR == 2
            cPom2 := "Datum posljednje promjene na kontu dobavljaca: "
         ENDIF

      ELSE
         cPom := ""
         cPom2 := ""

      ENDIF

      cTxt := StrTran( cTxt, cStrDPrDob, cPom2 + " " + cPom )

   ENDIF

   RETURN .T.
