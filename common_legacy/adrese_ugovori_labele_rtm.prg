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


FUNCTION ugov_stampa_naljenica()

   LOCAL cIdRoba, cIdPartner, cPTT, cMjesto
   LOCAL cSortiranje, dDatDo, cGledatiTekuciDatumDN
   LOCAL _filter := ""
   LOCAL _index_sort := ""
   LOCAL hRec, cFiltUslovPartner, _usl_mjesto, _usl_ptt
   LOCAL lImaDestinacija
   LOCAL nCount := 0
   LOCAL _total_kolicina := 0
   LOCAL GetList := {}

   PushWA()

   _open_tables()

   cIdRoba := PadR( fetch_metric( "ugovori_naljepnice_idroba", my_user(), Space( 10 ) ), 10 )
   cIdPartner := PadR( fetch_metric( "ugovori_naljepnice_partner", my_user(), Space( 300 ) ), 300 )
   cPTT := PadR( fetch_metric( "ugovori_naljepnice_ptt", my_user(), Space( 300 ) ), 300 )
   cMjesto := PadR( fetch_metric( "ugovori_naljepnice_mjesto", my_user(), Space( 300 ) ), 300 )
   cSortiranje := fetch_metric( "ugovori_naljepnice_sort", my_user(), "4" )

   dDatDo := Date()
   cGledatiTekuciDatumDN := "N"

   Box(, 15, 77 )

   DO WHILE .T.

      @ box_x_koord() + 0, box_y_koord() + 5 SAY "POSTAVLJENJE USLOVA ZA PRAVLJENJE LABELA"
      @ box_x_koord() + 2, box_y_koord() + 2 SAY "Artikal  :" GET cIdRoba VALID P_Roba( @cIdRoba ) PICT "@!"
      @ box_x_koord() + 3, box_y_koord() + 2 SAY "Partner  :" GET cIdPartner PICT "@S50!"
      @ box_x_koord() + 4, box_y_koord() + 2 SAY "Mjesto   :" GET cMjesto PICT "@S50!"
      @ box_x_koord() + 5, box_y_koord() + 2 SAY "PTT      :" GET cPTT PICT "@S50!"
      @ box_x_koord() + 6, box_y_koord() + 2 SAY8 "Gledati tekući datum (D/N):" GET cGledatiTekuciDatumDN VALID cGledatiTekuciDatumDN $ "DN" PICT "@!"
      @ box_x_koord() + 7, box_y_koord() + 2 SAY8 "**** Način sortiranja podataka u pregledu: "
      @ box_x_koord() + 8, box_y_koord() + 2 SAY8 " 1 - količina + mjesto + naziv"
      @ box_x_koord() + 9, box_y_koord() + 2 SAY8 " 2 - mjesto + naziv + količina"
      @ box_x_koord() + 10, box_y_koord() + 2 SAY8 " 3 - PTT + mjesto + naziv + kolicina"
      @ box_x_koord() + 11, box_y_koord() + 2 SAY8 " 4 - količina + PTT + mjesto + naziv"
      @ box_x_koord() + 12, box_y_koord() + 2 SAY8 " 5 - idpartner"
      @ box_x_koord() + 13, box_y_koord() + 2 SAY8 " 6 - količina"
      @ box_x_koord() + 14, box_y_koord() + 2 SAY8 "odabrana vrijednost:" GET cSortiranje VALID cSortiranje $ "1234567" PICT "9"
      READ

      IF LastKey() == K_ESC
         BoxC()
         RETURN .F.
      ENDIF

      cFiltUslovPartner := Parsiraj( cIdPartner, "IDPARTNER" )
      _usl_ptt  := Parsiraj( cPTT, "PTT"       )
      _usl_mjesto := Parsiraj( cMjesto, "MJESTO" )

      IF cFiltUslovPartner <> NIL .AND. _usl_mjesto <> NIL .AND. _usl_ptt <> NIL
         EXIT
      ENDIF

   ENDDO

   BoxC()

   set_metric( "ugovori_naljepnice_idroba", my_user(), cIdRoba )
   set_metric( "ugovori_naljepnice_partner", my_user(), AllTrim( cIdPartner ) )
   set_metric( "ugovori_naljepnice_ptt", my_user(), AllTrim( cPTT ) )
   set_metric( "ugovori_naljepnice_mjesto", my_user(), AllTrim( cMjesto ) )
   set_metric( "ugovori_naljepnice_sort", my_user(), cSortiranje )

   _index_sort := _index_sort + AllTrim( cSortiranje )
   _create_labelu_dbf()

   //IF is_dest()
    //  SELECT dest
    //  SET FILTER TO
   //ENDIF

   //SELECT ugov
   //SET FILTER TO

   //SELECT rugov
   //SET FILTER TO

   //IF !Empty( cIdRoba )
  //    SET FILTER TO idroba == cIdRoba
   //ENDIF
   o_rugov_roba( cIdRoba )

   GO TOP

   Box(, 3, 60 )

   DO WHILE !Eof() // RUGOV

      //SELECT ugov
      //SET ORDER TO TAG "ID"
      //GO TOP
      //SEEK rugov->id
      //IF !Found()
      IF !o_ugov( rugov->id )
         error_bar( "label", "Ugovor rugov.id: " + rugov->id + " ne postoji" )
         SELECT rugov
         SKIP
         LOOP
      ENDIF

      @ box_x_koord() + 1, box_y_koord() + 2 SAY "Ugovor ID: " + PadR( rugov->id, 10 )
      @ box_x_koord() + 2, box_y_koord() + 2 SAY PadR( "", 60 )
      @ box_x_koord() + 3, box_y_koord() + 2 SAY PadR( "", 60 )


      IF field->aktivan == "N"
         SELECT rugov
         SKIP
         LOOP
      ENDIF

      IF field->lab_prn == "N"
         SELECT rugov
         SKIP
         LOOP
      ENDIF

      IF cGledatiTekuciDatumDN == "D" .AND. ( dDatDo > ugov->datdo )
         SELECT rugov
         SKIP
         LOOP
      ENDIF

      IF !Empty( cIdPartner )
         IF !( &cFiltUslovPartner )
            SELECT rugov
            SKIP
            LOOP
         ENDIF
      ENDIF

      IF !select_o_partner( ugov->idpartner )
         error_bar( "label", "Partner ugov.partner: " + ugov->idpartner + " ne postoji" )
         SELECT rugov
         SKIP
         LOOP
      ENDIF

      IF !Empty( cPTT )
         IF !( &_usl_ptt )
            SELECT rugov
            SKIP
            LOOP
         ENDIF
      ENDIF

      IF !Empty( cMjesto )
         IF !( &_usl_mjesto )
            SELECT rugov
            SKIP
            LOOP
         ENDIF
      ENDIF

      SELECT labelu
      APPEND BLANK

      hRec := dbf_get_rec()

      hRec[ "idpartner" ] := ugov->idpartner
      hRec[ "kolicina" ] := rugov->kolicina
      hRec[ "idroba" ] := rugov->idroba
      hRec[ "kol_c" ] := PadL( AllTrim( Str( rugov->kolicina, 12, 0 ) ), 5, "0" )

      _total_kolicina += rugov->kolicina

      @ box_x_koord() + 2, box_y_koord() + 2 SAY "Partner: " + ugov->idpartner

      lImaDestinacija := .F.

      IF !Empty( rugov->dest )

         IF find_dest_by_iddest_idpartn(  rugov->dest, ugov->idpartner)
            lImaDestinacija := .T.
         ENDIF

      ENDIF

      SELECT labelu
      IF lImaDestinacija

         hRec[ "destin" ] := dest->id
         hRec[ "naz" ] := dest->naziv
         hRec[ "naz2" ] := dest->naziv2
         hRec[ "ptt" ] := Upper( dest->ptt )
         hRec[ "mjesto" ] := Upper( dest->mjesto )
         hRec[ "telefon" ] := dest->telefon
         hRec[ "fax" ] := dest->fax
         hRec[ "adresa" ] := dest->adresa

      ELSE

         hRec[ "destin" ] := ""
         hRec[ "naz" ] := partn->naz
         hRec[ "naz2" ] := partn->naz2
         hRec[ "ptt" ] := Upper( partn->ptt )
         hRec[ "mjesto" ] := Upper( partn->mjesto )
         hRec[ "telefon" ] := partn->telefon
         hRec[ "fax" ] := partn->fax
         hRec[ "adresa" ] := partn->adresa

      ENDIF

      dbf_update_rec( hRec )

      @ box_x_koord() + 3, box_y_koord() + 2 SAY "Ukupno prebaceno: " + AllTrim( Str( ++nCount ) )

      SELECT rugov
      SKIP

   ENDDO

   BoxC()

   IF nCount == 0
      MsgBeep( "Nema generisanih adresa !" )
      SELECT ugov
      RETURN .F.
   ENDIF

   label_to_lab2( _index_sort )

   MsgBeep( "Ukupno generisano " + AllTrim( Str( nCount ) ) +  " naljepnica, količina: " + AllTrim( Str( _total_kolicina, 12, 0 ) ) )

   stampa_pregleda_naljepnica( _index_sort )

   f18_rtm_print( "labelu", "lab2", "1", NIL, "labeliranje" )

   _open_tables()

   PopWA()

   RETURN .T.



STATIC FUNCTION label_to_lab2( cIndexSort )

   LOCAL hRec
   LOCAL nCount := 0

   SELECT labelu
   SET ORDER TO tag &cIndexSort
   GO TOP

   DO WHILE !Eof()

      hRec := dbf_get_rec()

      SELECT lab2
      APPEND BLANK

      hRec[ "idx" ] := ++nCount

      dbf_update_rec( hRec )

      SELECT labelu
      SKIP

   ENDDO

   SELECT lab2
   USE

   RETURN .T.



STATIC FUNCTION stampa_pregleda_naljepnica( cIndexSort )

   LOCAL _table_type := 1
   PRIVATE _index := cIndexSort

   SELECT labelu
   SET ORDER TO tag &_index
   GO TOP

   aKol := {}

   AAdd( aKol, { "Artikal", {|| IDROBA       }, .F., "C", 10, 0, 1, 1 } )
   AAdd( aKol, { "Partner", {|| IdPartner    }, .F., "C",  6, 0, 1, 2 } )
   AAdd( aKol, { "Dest.", {|| Destin       }, .F., "C",  6, 0, 1, 3 } )
   AAdd( aKol, { "Kolicina", {|| Kolicina     }, .T., "N", 12, 0, 1, 4 } )
   AAdd( aKol, { "PTT", {|| PTT          }, .F., "C",  5, 0, 1, 5 } )
   AAdd( aKol, { "Mjesto", {|| MJESTO       }, .F., "C", 16, 0, 1, 6 } )
   AAdd( aKol, { "Naziv", {|| PadR( AllTrim( naz ) + ", " + AllTrim( naz2 ), 60 ) }, .F., "C", 60, 0, 1, 7 } )
   AAdd( aKol, { "Adresa", {|| ADRESA       }, .F., "C", 40, 0, 1, 8 } )
   AAdd( aKol, { "Telefon", {|| TELEFON      }, .F., "C", 12, 0, 1, 9 } )
   AAdd( aKol, { "Fax", {|| FAX          }, .F., "C", 12, 0, 1, 10 } )

   START PRINT CRET

   print_lista_2( aKol, NIL, NIL, _table_type, NIL, NIL, "PREGLED BAZE PRIPREMLJENIH NALJEPNICA", , , , , )

   ENDPRINT

   my_close_all_dbf()

   RETURN .T.


STATIC FUNCTION _open_tables()

   //o_ugov()
   //o_rugov()
   //o_dest()
   //o_partner()
   //o_roba()
   //o_sifk()
   //o_sifv()

  // SELECT ugov

   RETURN .T.



STATIC FUNCTION _create_labelu_dbf()

   LOCAL aDbf := {}
   LOCAL cDbfLabel := "labelu"
   LOCAL cDbfLabel2 := "lab2"

   AAdd ( aDbf, { "idroba",    "C",     10, 0 } )
   AAdd ( aDbf, { "idpartner", "C",      6, 0 } )
   AAdd ( aDbf, { "destin",  "C",      6, 0 } )
   AAdd ( aDbf, { "kol_c",     "C",      5, 0 } )
   AAdd ( aDbf, { "naz",      "C",     50, 0 } )
   AAdd ( aDbf, { "naz2",      "C",     50, 0 } )
   AAdd ( aDbf, { "ptt",      "C",    10, 0 } )
   AAdd ( aDbf, { "mjesto",   "C",    20, 0 } )
   AAdd ( aDbf, { "adresa",   "C",    50, 0 } )
   AAdd ( aDbf, { "telefon",   "C",    20, 0 } )
   AAdd ( aDbf, { "fax",   "C",    20, 0 } )
   AAdd ( aDbf, { "kolicina",  "N",     12, 0 } )
   AAdd ( aDbf, { "idx",       "N",     12, 0 } )

   SELECT ( F_LABELU )
   USE

   FErase( my_home() + my_dbf_prefix() + cDbfLabel + ".dbf" )
   FErase( my_home() + my_dbf_prefix() + cDbfLabel + ".cdx" )

   dbCreate( my_home() + my_dbf_prefix() + cDbfLabel + ".dbf", aDbf )

   SELECT ( F_LABELU )
   USE
   my_use_temp( "labelu", my_home() + my_dbf_prefix() + cDbfLabel + ".dbf", .F., .F. )

   INDEX on ( kol_c + mjesto + naz ) TAG "1"
   INDEX on ( mjesto + naz + kol_c ) TAG "2"
   INDEX on ( ptt + mjesto + naz + kol_c ) TAG "3"
   INDEX on ( kol_c + ptt + mjesto + naz ) TAG "4"
   INDEX on ( idpartner ) TAG "5"
   INDEX on ( kol_c ) TAG "6"

   FErase( my_home() + my_dbf_prefix() + cDbfLabel2 + ".dbf" )
   FErase( my_home() + my_dbf_prefix() + cDbfLabel2 + ".cdx" )

   SELECT ( F_LABELU2 )
   USE

   dbCreate( my_home() + my_dbf_prefix() + cDbfLabel2 + ".dbf", aDbf )

   SELECT ( F_LABELU2 )
   USE
   my_use_temp( "lab2", my_home()+ my_dbf_prefix() + cDbfLabel2 + ".dbf", .F., .F. )

   INDEX on ( Str( idx, 12, 0 ) ) TAG "1"

   RETURN .T.
