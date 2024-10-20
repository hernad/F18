/*
 * This file is part of the bring.out FMK, a free and open source
 * accounting software suite,
 * Copyright (c) 1996-2011 by bring.out doo Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including FMK specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_FMK.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */

#include "f18.ch"


// --------------------------------------------------
// lista naloga otvorenih na tekuci dan
// --------------------------------------------------
FUNCTION lst_tek_dan()

   LOCAL cLine
   LOCAL nOperater
   LOCAL GetList := {}
   LOCAL dDatum := danasnji_datum()

   O_DOCS
   O_CUSTOMS
   O_CONTACTS

   nOperater := f18_get_user_id( f18_user() )

   Box( , 1, 60 )
   @ box_x_koord() + 1, box_y_koord() + 2 SAY "Operater (0 - svi)" GET nOperater PICT "9999999999"
   READ
   BoxC()

   SELECT docs
   SET ORDER TO TAG "D1"
   GO TOP

   SEEK DToS( dDatum )

   r_l_get_line( @cLine )

   START PRINT CRET

   ?
   ? "Lista naloga otvorenih na tekuci dan " + DToC( dDatum )

   ?

   r_list_zagl()

   DO WHILE !Eof() .AND. DToS( field->doc_date ) == DToS( dDatum )

      // ako je za teku�eg operatera
      IF nOperater <> 0
         IF field->operater_i <> nOperater
            SKIP
            LOOP
         ENDIF
      ENDIF

      // ako je nalog zatvoren, preskoci
      IF ( field->doc_status == 1 ) .OR. ( field->doc_status == 2 )
         SKIP
         LOOP
      ENDIF


      cPom := ""
      cPom += PadR( docno_str( field->doc_no ), 10 )
      cPom += " "
      cPom += PadR( DToC( field->doc_dvr_da ), 8 )
      cPom += " "
      cPom += PadR( field->doc_dvr_ti, 8 )
      cPom += " "
      cPom += show_customer( field->cust_id, field->cont_id )

      ? cPom

      SKIP
   ENDDO

   ? cLine

   FF
   ENDPRINT

   RETURN

// ---------------------------------------------------
// prikaz partnera / kontakta
// ---------------------------------------------------
STATIC FUNCTION show_customer( nCust_id, nCont_id )

   LOCAL cRet
   LOCAL cCust
   LOCAL cCont

   cCust := AllTrim( g_cust_desc( nCust_id ) )
   cCont := AllTrim( g_cont_desc( nCont_id ) )

   cRet := cCust

   IF !Empty( cCont ) .AND. cCont <> "?????"
      cRet += " / " + cCont
   ENDIF

   RETURN cRet



// ------------------------------------
// zaglavlje liste
// ------------------------------------
STATIC FUNCTION r_list_zagl()

   LOCAL cLine
   LOCAL cText

   r_l_get_line( @cLine )

   cText := PadC( "Br.naloga", 10 )
   cText += " "
   cText += PadC( "Dat.isp", 8 )
   cText += " "
   cText += PadC( "Vri.isp", 8 )
   cText += " "
   cText += PadR( "Narucioc / kontakt - naziv", 60 )

   ? cLine
   ? cText
   ? cLine

   RETURN


// ---------------------------------------
// vraca liniju za zaglavlje
// ---------------------------------------
STATIC FUNCTION r_l_get_line( cLine )

   cLine := Replicate( "-", 10 )
   cLine += " "
   cLine += Replicate( "-", 8 )
   cLine += " "
   cLine += Replicate( "-", 8 )
   cLine += " "
   cLine += Replicate( "-", 60 )

   RETURN


// --------------------------------------------------
// lista naloga od izabranog datuma
// --------------------------------------------------
FUNCTION lst_ch_date()

   LOCAL cLine
   LOCAL dDate := danasnji_datum()
   LOCAL nOperater

   nOperater := f18_get_user_id( f18_user() )

   Box(, 3, 60 )

   @ box_x_koord() + 1, box_y_koord() + 2 SAY "Operater (0 - svi)" GET nOperater PICT "9999999999"

   @ box_x_koord() + 3, box_y_koord() + 2 SAY "Listaj naloge >= datum" GET dDate

   READ

   BoxC()

   IF LastKey() == K_ESC
      RETURN
   ENDIF

   O_DOCS
   O_CUSTOMS
   O_CONTACTS

   SELECT docs
   SET ORDER TO TAG "D1"
   GO TOP

   SEEK DToS( dDate )

   r_l_get_line( @cLine )

   START PRINT CRET

   ?
   ? "Lista naloga >= datumu: " + DToC( dDate )

   ?

   r_list_zagl()

   DO WHILE !Eof() .AND. DToS( field->doc_date ) >= DToS( dDate )

      // operater uslov
      IF nOperater <> 0
         IF field->operater_i <> nOperater
            SKIP
            LOOP
         ENDIF
      ENDIF


      // ako je nalog zatvoren, preskoci
      IF ( field->doc_status == 1 ) .OR. ( field->doc_status == 2 )

         SKIP
         LOOP

      ENDIF

      cPom := ""
      cPom += PadR( docno_str( field->doc_no ), 10 )
      cPom += " "
      cPom += PadR( DToC( field->doc_dvr_da ), 8 )
      cPom += " "
      cPom += PadR( field->doc_dvr_ti, 8 )
      cPom += " "
      cPom += show_customer( field->cust_id, field->cont_id )

      ? cPom

      SKIP
   ENDDO

   ? cLine

   FF
   ENDPRINT

   RETURN




// ---------------------------------------------------------
// lista naloga prispjelih za realizaciju na tekuci dan
// ---------------------------------------------------------
FUNCTION lst_real_tek_dan()

   LOCAL dDatum := danasnji_datum()
   LOCAL cLine
   LOCAL nOperater
   LOCAL cCurrent := "D"
   LOCAL GetList := {}

   O_DOCS
   O_CUSTOMS
   O_CONTACTS

   nOperater := f18_get_user_id( f18_user() )

   Box(, 3, 60 )
   @ box_x_koord() + 1, box_y_koord() + 2 SAY "Operater (0 - svi)" GET nOperater PICT "9999999999"
   @ box_x_koord() + 3, box_y_koord() + 2 SAY "Nalozi prispjeli samo na tekuci dan ?" GET cCurrent PICT "@!" VALID cCurrent $ "DN"
   READ
   BoxC()

   SELECT docs
   SET ORDER TO TAG "D2"
   GO TOP

   SEEK DToS( dDatum )

   r_l_get_line( @cLine )

   START PRINT CRET

   ?
   ? "Lista naloga prispjelih za realizaciju na tekuci dan " + DToC( dDatum )
   ?

   r_list_zagl()

   DO WHILE !Eof() .AND. DToS( field->doc_dvr_da ) >= DToS( dDatum )

      // uslov po operateru
      IF nOperater <> 0
         IF field->operater_i <> nOperater
            SKIP
            LOOP
         ENDIF
      ENDIF

      // samo tekuci dan!
      IF cCurrent == "D"
         IF DToS( field->doc_dvr_da ) <> DToS( dDatum )
            SKIP
            LOOP
         ENDIF
      ENDIF

      // ako je zatvoren, preskoci..
      IF field->doc_status == 1 .OR. ;
            field->doc_status == 2
         SKIP
         LOOP
      ENDIF

      nDoc_no := field->doc_no

      cPom := ""
      cPom += PadR( docno_str( nDoc_no ), 10 )
      cPom += " "
      cPom += PadR( DToC( field->doc_dvr_da ), 8 )
      cPom += " "
      cPom += PadR( field->doc_dvr_ti, 8 )
      cPom += " "
      cPom += show_customer( field->cust_id, field->cont_id )

      ? cPom


      SELECT docs

      SKIP
   ENDDO

   ? cLine

   FF
   ENDPRINT

   RETURN



// ---------------------------------------------------------
// lista naloga van roka na tekuci dan
// ---------------------------------------------------------
FUNCTION lst_vrok_tek_dan()

   LOCAL dDatum := danasnji_datum()
   LOCAL cLine
   LOCAL nDoc_no
   LOCAL cLog
   LOCAL nDays := 0
   LOCAL nOperater
   LOCAL cEmail := "N"
   LOCAL i
   LOCAL aLog
   LOCAL cPrinter

   nOperater := f18_get_user_id( f18_user() )

   Box(, 5, 65 )

   @ box_x_koord() + 1, box_y_koord() + 2 SAY "Operater (0 - svi)" GET nOperater PICT "9999999999"

   @ box_x_koord() + 3, box_y_koord() + 2 SAY "Uzeti u obzir do br.predh.dana:" GET nDays PICT "99999"

   @ box_x_koord() + 5, box_y_koord() + 2 SAY "Slati report email-om ?" GET cEmail PICT "@!" VALID cEmail $ "DN"

   READ

   BoxC()

   O_DOCS
   O_CUSTOMS
   O_CONTACTS

   SELECT docs
   SET ORDER TO TAG "D2"
   GO TOP

   r_l_get_line( @cLine )

   IF cEmail == "D"
      cPrinter := gPrinter
      gPrinter := "0"
   ENDIF

   START PRINT CRET

   ?
   ? "Lista naloga van roka na tekuci dan " + DToC( dDatum )
   ?

   r_list_zagl()

   DO WHILE !Eof()

      IF nOperater <> 0
         IF field->operater_i <> nOperater
            SKIP
            LOOP
         ENDIF
      ENDIF

      IF field->doc_status == 1 .OR. ;
            field->doc_status == 2
         SKIP
         LOOP
      ENDIF

      IF dDatum <= field->doc_dvr_da
         SKIP
         LOOP
      ENDIF

      IF nDays <> 0
         IF ( dDatum - nDays ) <= doc_dvr_da
            SKIP
            LOOP
         ENDIF
      ENDIF

      nDoc_no := field->doc_no

      cPom := ""
      cPom += PadR( docno_str( nDoc_no ), 10 )
      cPom += " "
      cPom += PadR( DToC( field->doc_dvr_da ), 8 )
      cPom += " "
      cPom += PadR( field->doc_dvr_ti, 8 )
      cPom += " "
      cPom += show_customer( field->cust_id, field->cont_id )

      ? cPom

      use_sql_doc_log( nDoc_no )
      SEEK docno_str( nDoc_no )

      cLog := ""

      DO WHILE !Eof() .AND. field->doc_no == nDoc_no

         cLog := DToC( field->doc_log_da )
         cLog += " / "
         cLog += AllTrim( field->doc_log_ti )
         cLog += " : "
         cLog += AllTrim( field->doc_log_de )

         SKIP
      ENDDO

      IF "Inicij" $ cLog
         cLog := ""
      ENDIF

      IF !Empty( cLog )

         aLog := SjeciStr( cLog, 60 )

         FOR i := 1 TO Len( aLog )

            ?U Space( 29 ) + aLog[ i ]

         NEXT

      ENDIF

      SELECT docs
      SKIP

   ENDDO

   ? cLine

   FF
   ENDPRINT

   IF cEmail == "D"
      gPrinter := cPrinter
      _subject := "Lista naloga van roka na tekuci dan"
      _body := _subject
      _attach := { my_home() + "outf.txt" }
      _mail_params := f18_email_prepare( _subject, _body )
      f18_send_email( _mail_params, _attach )
   ENDIF

   RETURN .T.
