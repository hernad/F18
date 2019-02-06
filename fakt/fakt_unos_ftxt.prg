#include "f18.ch"


// =========================================================

/*
    *   Ispravka teksta ispod fakture (poziv iz menija)
    *   param: lSilent
    *   param: bFunc

    poziv: 1. fakt priprema podmenu opcija CASE izbor == 3
           2. generacija fakt dokumenta - predracun u racun

*/

FUNCTION fakt_ispravka_ftxt()

   LOCAL nRbr, hRec, hFaktTxt

   hRec := dbf_get_rec()

   hFaktTxt := fakt_ftxt_decode_string( hRec[ "txt" ] )

   fakt_unos_set_fakt_txt_opis( @hFaktTxt[ "txt2" ], rbr_u_num( hRec[ "rbr" ] ), hRec[ "idtipdok" ], hRec[ "idpartner" ] )

   hRec[ "txt" ] := fakt_ftxt_encode_5( hFaktTxt )

   dbf_update_rec( hRec )

   RETURN .T.



FUNCTION fakt_unos_set_fakt_txt_opis( cTxtOpis, nRedBr, cIdTipDok, cIdPartner )

   LOCAL cIdFaktTxt := "  "
   LOCAL aList := {}
   LOCAL i
   LOCAL nCount := 1
   LOCAL cFaktTxtListaUzoraka

   // IF cFaktTxtListaUzoraka == nil
   // cFaktTxtListaUzoraka := ""
   // ENDIF

   IF nRedBr > 1
      RETURN .F.
   ENDIF

   cFaktTxtListaUzoraka := fakt_get_lista_ftxt_za_tip_dok( cIdTipDok )
   cFaktTxtListaUzoraka := AllTrim( cFaktTxtListaUzoraka )

   IF !Empty( cFaktTxtListaUzoraka )
      IF Empty( cTxtOpis )
         info_bar( "fakt_txt", "FAKT TipDok=" + cIdTipDok + " Uzorci:" + cFaktTxtListaUzoraka )
         IF Pitanje(, "TD: " + cIdTipDok + " ima predefinisane uzorke, koristiti ih ?", "D" ) == "N"
            cFaktTxtListaUzoraka := ""
         ENDIF
         aList := TokToNiz( cFaktTxtListaUzoraka, ";" )
      ENDIF
   ENDIF


   IF cIdTipDok $ "10#20" .AND. partner_is_ino( cIdPartner )
      fakt_ftxt_ino_klauzula()
      IF Empty( AllTrim( cTxtOpis ) )
         AAdd( aList, "IN" )
      ENDIF
   ENDIF

   IF !Empty( cFaktTxtListaUzoraka )
      FOR i := 1 TO Len( aList )
         cIdFaktTxt := aList[ i ]
         fakt_ftxt_add_text_by_id( @cTxtOpis, cIdFaktTxt )
         cIdFaktTxt := "MX"
         // ++nCount
      NEXT
      fakt_ftxt_add_text_by_id( @cTxtOpis, "DI" ) // dokument izradio
   ENDIF


   // IF ( nRedBr == 1 )  // .AND. Val( hRec[ "podbr" ] ) < 1 )
   cIdFaktTxt := "  "
   fakt_unos_ftxt_box( @cTxtOpis, @cIdFaktTxt, nCount )
   // ENDIF

   RETURN .T.



// g10Ftxt - 10 dodatni txt = "P1;P2"

FUNCTION fakt_get_lista_ftxt_za_tip_dok( cIdTd )

   LOCAL cFaktTxtListaUzoraka := ""
   LOCAL cVal
   PRIVATE cTmptxt

   IF !Empty( cIdTd ) .AND. cIdTD $ "10#11#12#13#15#20#21#22#23#25#26#27"

      cTmptxt := "g" + cIdTd + "Ftxt"
      cVal := &cTmptxt

      IF !Empty( cVal )
         cFaktTxtListaUzoraka := AllTrim( cVal )
      ENDIF

   ENDIF

   RETURN cFaktTxtListaUzoraka



FUNCTION fakt_unos_ftxt_box( cTxt, cIdFaktTxt, nCount )

   LOCAL lRet := .T.
   LOCAL GetList := {}

   Box(, 11, f18_max_cols() - 9 )

   DO WHILE .T.

      @ box_x_koord() + 1, box_y_koord() + 1 SAY8 "Odaberi uzorak teksta iz šifarnika:"  GET cIdFaktTxt PICT "@!"
      @ box_x_koord() + 11, box_y_koord() + 1 SAY8 "<c+W> dodaj novi ili snimi i izađi <ESC> poništi"

      READ

      IF LastKey() == K_ESC
         EXIT
      ENDIF

      IF LastKey() <> K_ESC .AND. !Empty( cIdFaktTxt )
         IF cIdFaktTxt <> "MX"
            p_fakt_ftxt( @cIdFaktTxt )
            fakt_ftxt_add_text_by_id( @cTxt, cIdFaktTxt )
            // ++nCount
            cIdFaktTxt := "  "
         ENDIF
      ENDIF

      SetColor( f18_color_invert() )

      PRIVATE fUMemu := .T.

      cTxt := MemoEdit( cTxt, box_x_koord() + 3, box_y_koord() + 1, box_x_koord() + 9, box_y_koord() + f18_max_cols() - 9 )

      fUMemu := NIL
      SetColor( f18_color_normal() )

      IF LastKey() == K_ESC
         EXIT
      ENDIF

      IF LastKey() == K_CTRL_W
         IF Pitanje(, "Nastaviti sa unosom teksta ? (D/N)", "N" ) == "N"
            lRet := .F.
            EXIT
         ENDIF
      ENDIF

   ENDDO
   BoxC()

   RETURN lRet
