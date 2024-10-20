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

STATIC aHeader := {}
STATIC aZaglLen := { 5, 50 }
STATIC aZagl := {}
STATIC RPT_LM  := 5
STATIC RPT_RI := 2
STATIC RPT_W2 := 45
STATIC RPT_COL := 58
STATIC RPT_GAP := 4
STATIC RPT_BOLD_DELTA := 2
STATIC nCurrLine := 0
STATIC cRptNaziv := "PDV prijava"
STATIC s_cTabela := "pdv"
STATIC cSource := "1"
STATIC dDatOd
STATIC dDatDo



FUNCTION epdv_pdv_prijava()

   LOCAL cAzurirati
   LOCAL nX
   LOCAL GetList := {}

   aDInt := epdv_rpt_d_interval ( Date() )

   dDate := Date()

   dDatOd := aDInt[ 1 ]
   dDatDo := aDInt[ 2 ]

   cAzurirati := "D"

   nX := 1
   Box(, 12, 60 )

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Period"
   nX++

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "od " GET dDatOd
   @ box_x_koord() + nX, Col() + 2 SAY "do " GET dDatDo

   nX += 2
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "obrazac se pravi na osnovu :"
   nX++
   @ box_x_koord() + nX, box_y_koord() + 2 SAY " 1 - kuf/kif"
   nX++
   @ box_x_koord() + nX, box_y_koord() + 2 SAY " 2 - pdv baze"
   nX++
   @ box_x_koord() + nX, box_y_koord() + 2 SAY " izbor ?" GET cSource PICT "@!" VALID cSource $ "12"

   READ
   nX++

   IF cSource == "1"
      @ box_x_koord() + nX, box_y_koord() + 2 SAY8 " Ažurirati podatke u PDV bazu (D/N) ?" GET cAzurirati PICT "@!" VALID cAzurirati $ "DN"
      READ

   ENDIF

   BoxC()

   IF LastKey() == K_ESC
      my_close_all_dbf()
      RETURN .F.
   ENDIF

   epdv_fill_rpt()
   show_rpt(  .F.,  .F. )

   epdv_pdv_prijava_snimi_obracun( dDatOd, dDatDo )

   RETURN .T.




STATIC FUNCTION epdv_create_r_pdv()

   LOCAL aArr := {}

   my_close_all_dbf()

   FErase ( my_home() + "epdv_r_" +  s_cTabela + ".cdx" )
   FErase ( my_home() + "epdv_r_" +  s_cTabela + ".dbf" )

   aArr := epdv_get_pdv_fields()

   dbcreate2( my_home() + "epdv_r_" + s_cTabela + ".dbf", aArr )

   RETURN .T.



STATIC FUNCTION epdv_fill_rpt()

   epdv_create_r_pdv()

   IF cSource == "1"
      epdv_prijava_fill_kuf_kif()
   ELSE
      epdv_prijava_fill_iz_pdv_tabele()
   ENDIF

   RETURN .T.



STATIC FUNCTION epdv_prijava_fill_kuf_kif()

   LOCAL nBPdv
   LOCAL nUkIzPdv := 0
   LOCAL nUkUlPdv := 0
   LOCAL nUlPdvKp := 0
   LOCAL nCount
   LOCAL GetList := {}
     LOCAL hParams

   aMyFirma := my_firma( .T. )

   select_o_epdv_r_pdv()
   APPEND BLANK

   Scatter()

   _po_naziv := aMyFirma[ 1 ]
   _id_br := aMyFirma[ 2 ]
   _po_ptt := aMyFirma[ 3 ]
   _po_mjesto := aMyFirma[ 4 ]
   _po_adresa := aMyFirma[ 5 ]

   PRIVATE cFilter := ""

   //cFilter := dbf_quote( dDatOd ) + " <= datum .and. " + dbf_quote( dDatDo ) + ">= datum"

   //select_o_epdv_kuf()
   hParams := hb_hash()
   find_epdv_kuf_za_period( dDatOd, dDatDo, hParams, "br_dok" )
   //SET FILTER TO &cFilter
   GO TOP

   Box(, 3, 60 )

   nCount := 0

   DO WHILE !Eof() // kuf

      ++nCount

      @ box_x_koord() + 2, box_y_koord() + 2 SAY "KUF" + Str( nCount, 6, 0 )

      cIdTar := id_tar
      nBPdv := i_b_pdv
      nPdv := i_pdv

      DO CASE

      CASE t_u_poup( cIdTar )
         _u_nab_21 += nBPdv
         _u_pdv_41 += nPdv
         nUkUlPdv += nPdv

      CASE epdv_tarifa_nabavke_uvoz( cIdTar )
         _u_uvoz += nBPdv
         _u_pdv_uv += nPdv
         nUkUlPdv += nPdv

      CASE t_u_polj( cIdTar )
         _u_nab_23 += nBPdv
         _u_pdv_43 += nPdv
         nUkUlPdv += nPdv

      CASE epdv_tarifa_nabavke_od_poljoprivrednika( cIdTar )
         _u_nab_23 += nBPdv

      CASE t_u_n_poup( cIdTar )
         _u_nab_21 += nBPdv
         nUlPdvKp += nPdv

      OTHERWISE
         _u_nab_21 += nBPdv

      ENDCASE

      SELECT KUF

      SKIP

   ENDDO

   SELECT r_pdv
   my_rlock()
   Gather()
   my_unlock()

   SELECT KUF
   USE

   Beep( 1 )

   //cFilter := dbf_quote( dDatOd ) + " <= datum .and. " + dbf_quote( dDatDo ) + ">= datum"
   find_epdv_kif_za_period( dDatOd, dDatDo, hParams, "br_dok" )
   // select_o_epdv_kif()
   //SET FILTER TO &cFilter

   GO TOP

   IF !Empty( gUlPdvKp() )
      DO CASE
      CASE gUlPdvKp() == "1"
         _i_pdv_nr1 += nUlPdvKp
      CASE gUlPdvKp() == "2"
         _i_pdv_nr2 += nUlPdvKp
      CASE gUlPdvKp() == "3"
         _i_pdv_nr3 += nUlPdvKp
      ENDCASE
   ENDIF

   DO WHILE !Eof() // kif

      ++nCount

      @ box_x_koord() + 2, box_y_koord() + 2 SAY "KIF" + Str( nCount, 6, 0 )

      cIdTar := id_tar
      nBPdv := i_b_pdv
      nPdv := i_pdv

      DO CASE

      CASE t_i_opor( cIdTar )
         _i_opor += nBPdv

      CASE epdv_tarifa_isporuke_izvoz( cIdTar )
         _i_izvoz += nBPdv
      CASE epdv_tarifa_isporuke_neoporezivo_osim_izvoza( cIdTar )
         _i_neop += nBPdv

      ENDCASE


      IF Round( get_stopa_pdv_za_tarifu( cIdTar ), 2 ) > 0

         nUkIzPdv += nPdv

         IF partner_is_pdv_obveznik( kif->id_part )
            _i_pdv_r += nPdv

         ELSE
            cRejon := part_rejon( kif->id_part )

            DO CASE
            CASE cRejon == "2"
               _i_pdv_nr2 += nPdv

            CASE cRejon == "3"
               _i_pdv_nr3 += nPdv

            CASE cRejon == "4"
               _i_pdv_nr4 += nPdv

            OTHERWISE
               _i_pdv_nr1 += nPdv

            ENDCASE
         ENDIF

      ENDIF

      SELECT KIF
      SKIP

   ENDDO

   SELECT r_pdv
   read_pdv_pars( @_pot_datum, @_pot_mjesto, @_pot_ob, @_pdv_povrat )

   _pot_datum := Date()

   Box(, 8, 65 )
   @ box_x_koord() + 1, box_y_koord() + 2 SAY "Prenos PDV-a iz predhodnog perioda (KM) ?" GET _u_pdv_pp ;
      PICT PIC_IZN()

   @ box_x_koord() + 3, box_y_koord() + 2 SAY "- Potpis -----------------"
   @ box_x_koord() + 4, box_y_koord() + 2 SAY "Datum :" GET _pot_datum ;
      VALID {|| _pot_mjesto := PadR( _po_mjesto, Len( _pot_mjesto ) ), .T. }
   @ box_x_koord() + 5, box_y_koord() + 2 SAY "Mjesto :" GET _pot_mjesto  VALID {|| _pot_datum := Date(), .T. }

   @ box_x_koord() + 6, box_y_koord() + 2 SAY "Ime i prezime ? " GET _pot_ob  PICT "@S30"

   @ box_x_koord() + 8, box_y_koord() + 2 SAY "Zahtjev za povrat ako je preplata (D/N) ? " GET _pdv_povrat VALID _pdv_povrat $ "DN" PICT "@!"

   READ

   save_pdv_pars( _pot_datum, _pot_mjesto, _pot_ob, _pdv_povrat )

   BoxC()

   SELECT r_pdv

   _per_od := dDatOd
   _per_do := dDatDo

   nUkUlPdv += _u_pdv_pp
   _u_pdv_41 += _u_pdv_pp

   _u_pdv_uk := nUkUlPdv

   _i_pdv_uk := nUkIzPdv

   epdv_zaokruzenje_pdv_prijava()

   nPdvSaldo := _i_pdv_uk -  _u_pdv_uk
   _pdv_uplati := nPdvSaldo

   my_rlock()
   Gather()
   my_unlock()

   SELECT KIF
   USE

   Beep( 1 )


   BoxC()

   RETURN .T.



STATIC FUNCTION epdv_zaokruzenje_pdv_prijava()

   _u_nab_21 := Round( _u_nab_21, ZAO_PDV() )
   _u_uvoz := Round( _u_uvoz, ZAO_PDV() )
   _u_nab_23 := Round( _u_nab_23, ZAO_PDV() )


   _u_pdv_41 := Round( _u_pdv_41, ZAO_PDV() )
   _u_pdv_uv := Round( _u_pdv_uv, ZAO_PDV() )
   _u_pdv_43 := Round( _u_pdv_43, ZAO_PDV() )


   _i_opor := Round( _i_opor, ZAO_PDV() )
   _i_izvoz := Round( _i_izvoz, ZAO_PDV() )
   _i_neop := Round( _i_neop, ZAO_PDV() )


   _i_pdv_r := Round( _i_pdv_r, ZAO_PDV() )

   _i_pdv_nr1 := Round( _i_pdv_nr1, ZAO_PDV() )
   _i_pdv_nr2 := Round( _i_pdv_nr2, ZAO_PDV() )
   _i_pdv_nr3 := Round( _i_pdv_nr3, ZAO_PDV() )
   _i_pdv_nr4 := Round( _i_pdv_nr4, ZAO_PDV() )

   _u_pdv_uk := Round( _u_pdv_uk, ZAO_PDV() )
   _i_pdv_uk := Round( _i_pdv_uk, ZAO_PDV() )

   RETURN .T.


STATIC FUNCTION epdv_prijava_fill_iz_pdv_tabele()

   //select_o_epdv_pdv()


   //SET ORDER TO TAG "period"

   //SEEK DToS( dDatOd ) + DToS( dDatDo )


  // IF !Found()
  IF !find_epdv_pdv_za_period( dDatOd, dDatDo )
      Beep( 2 )
      MsgBeep( "Ne postoji pohranjen PDV obračun #za period " + DToC( dDatOd ) + "-" + DToC( dDatDo ) )
      USE
      RETURN .F.
   ENDIF

   select_o_epdv_r_pdv()
   APPEND BLANK

   SELECT ( F_PDV )
   Scatter()

   SELECT ( F_R_PDV )
   my_rlock()
   Gather()
   my_unlock()

   SELECT ( F_PDV )
   USE

   RETURN .T.



STATIC FUNCTION show_rpt()

   LOCAL nLenUk
   LOCAL nPom1
   LOCAL nPom2

   nCurrLine := 0

   START PRINT CRET
   ?
   nPageLimit := 65

   nRow := 0

   r_zagl()

   SELECT r_pdv
   SET ORDER TO TAG "1"
   GO TOP


   P_COND
   ?
   ?? rpt_lm()
   ?? PadL( "Obrazac P PDV, ver 01.12", RPT_COL * 2 + RPT_GAP )

   ?
   ?? rpt_lm()
   ?? PadC( " ", RPT_COL * 2 + RPT_GAP )
   ?? rpt_lm()

   ?
   P_10CPI

   P_10CPI
   ?? Space( 10 )
   ?? PadC( "P D V   P R I J A V A", Round( ( RPT_COL * 2 + RPT_GAP ) / 2, 0 ) )

   B_OFF

   show_raz_1()

   P_12CPI

   ?? rpt_lm()
   ?? "1. Identifikacioni broj : "
   ?? id_br

   ?? Space( 6 )
   ?? "2. Period : "
   ?? per_od
   ?? " - "
   ?? per_do

   show_raz_1()

   ?? rpt_lm()
   ?? "3. Naziv poreskog obveznika : "
   ?? po_naziv

   show_raz_1()

   ?? rpt_lm()
   ?? "4. Adresa : "
   ?? po_adresa

   show_raz_1()

   ?? rpt_lm()
   ??U "5. Poštanski broj/Mjesto : "
   ?? po_ptt
   ?? " / "
   ?? po_mjesto

   show_raz_1()

   P_COND

   ?
   ?? rpt_lm()
   B_ON
   U_ON
   ?? PadR( "I. Isporuke i nabavke (iznosi bez PDV-a)", RPT_COL - RPT_BOLD_DELTA )
   U_OFF
   B_OFF

   show_raz_1()

   ?? rpt_lm()
   ?? Space( RPT_RI )

   cPom := PadR( "11. Oporezive isporuke, osim onih u 12 i 13 ", RPT_W2 ) + Transform( i_opor, PIC_IZN() )
   ?? PadL( cPom, RPT_COL - RPT_RI + 1 )

   ?? Space( RPT_GAP )

   ?? Space( RPT_RI )
   cPom := PadR( "21. SVE nabavke osim 22 i 23 ", RPT_W2 ) + Transform( u_nab_21, PIC_IZN() )
   ?? PadL( cPom, RPT_COL - RPT_RI + 1 )

   show_raz_1()
   ?? rpt_lm()
   cPom := PadR( "12. Vrijednost izvoza ", RPT_W2 ) + Transform( i_izvoz, PIC_IZN() )
   // sirina kolone - indent
   ?? Space( RPT_RI )
   ?? PadL( cPom, RPT_COL - RPT_RI + 1 )

   ?? Space( RPT_GAP )

   ?? Space( RPT_RI )
   cPom := PadR( "22. Vrijednost uvoza ", RPT_W2 ) + Transform( u_uvoz, PIC_IZN() )
   ?? PadL( cPom, RPT_COL - RPT_RI + 1 )

   show_raz_1()

   ?? rpt_lm()
   ?? Space( RPT_RI )

   cPom := PadR( "13. Isp. oslobođene PDV-a ", RPT_W2 ) + Transform( i_neop, PIC_IZN() )
   ??U PadL( cPom, RPT_COL - RPT_RI + 1 )

   ?? Space( RPT_GAP )

   ?? Space( RPT_RI )
   cPom := PadR( "23. Vrijednost nab. od poljoprivrednika ", RPT_W2 ) + Transform( u_nab_23, PIC_IZN() )
   ?? PadL( cPom, RPT_COL - RPT_RI + 1 )

   show_raz_1()

   ?
   ?? rpt_lm()

   B_ON
   U_ON
   ?? PadR( "II. Izlazni PDV", RPT_COL - RPT_BOLD_DELTA )
   U_OFF
   B_OFF

   ?? Space( RPT_GAP )
   B_ON
   U_ON
   ?? PadL( "Ulazni PDV  ", RPT_COL - RPT_BOLD_DELTA )
   U_OFF
   B_OFF

   show_raz_1()
   ?
   ?? rpt_lm()
   ?? Space( RPT_RI )

   B_ON
   ?? PadR( " ", RPT_COL - RPT_RI )
   B_OFF
   ?? Space( RPT_GAP )

   ?? Space( RPT_RI )

   B_ON
   ??U PadR( "PDV obračunat na ulaze (dobra i usluge)", RPT_COL - RPT_RI )
   B_OFF


   show_raz_1()

   ?? rpt_lm()
   ?? Space( RPT_RI )
   cPom := " "
   ?? PadL( cPom, RPT_COL - RPT_RI + 1 )

   ?? Space( RPT_GAP )

   ?? Space( RPT_RI )
   cPom := PadR( "41. Od reg. PDV obveznika osim 42 i 43", RPT_W2 ) + Transform( u_pdv_41, PIC_IZN() )
   ?? PadL( cPom, RPT_COL - RPT_RI + 1 )

   show_raz_1()

   ?? rpt_lm()
   ?? Space( RPT_RI )

   cPom := " "
   ?? PadR( cPom, RPT_COL - RPT_RI + 1 )

   ?? Space( RPT_GAP )

   ?? Space( RPT_RI )
   cPom := PadR( "42. PDV na uvoz ", RPT_W2 ) + Transform( u_pdv_uv, PIC_IZN() )
   ?? PadL( cPom, RPT_COL - RPT_RI + 1 )

   show_raz_1()
   ?? rpt_lm()
   ?? Space( RPT_RI )
   cPom := ""
   ?? PadL( cPom, RPT_COL - RPT_RI + 1 )

   ?? Space( RPT_GAP )

   ?? Space( RPT_RI )
   cPom := PadR( "43. Paušalna naknada za poljoprivrednike ", RPT_W2 ) + Transform( u_pdv_43, PIC_IZN() )
   ??U PadL( cPom, RPT_COL - RPT_RI + 1 )

   show_raz_1()
   show_raz_1()

   ?? rpt_lm()
   ?? Space( RPT_RI )
   cPom :=  PadR( "51. PDV obračunat na izlaz(dobra i usluge) ",  RPT_W2 - RPT_BOLD_DELTA ) + Transform( i_pdv_uk, PIC_IZN() )
   B_ON
   ??U PadL( cPom, RPT_COL - RPT_RI - RPT_BOLD_DELTA + 1 )
   B_OFF

   ?? Space( RPT_GAP )

   ?? Space( RPT_RI )
   B_ON
   cPom := PadR( "61. Ulazni PDV (ukupno) ", RPT_W2 - RPT_BOLD_DELTA ) + Transform( u_pdv_uk, PIC_IZN() )
   ?? PadL( cPom, RPT_COL - RPT_RI - RPT_BOLD_DELTA + 1 )
   B_OFF

   show_raz_1()
   show_raz_1()

   ?? rpt_lm()
   ?? Space( RPT_RI )
   cPom := PadR( "71. Obaveza PDV-a za uplatu/povrat ", RPT_W2 - RPT_BOLD_DELTA ) + Transform( pdv_uplati, PIC_IZN() )
   B_ON
   ?? PadL( cPom, RPT_COL - RPT_RI - RPT_BOLD_DELTA + 1 )
   B_OFF

   ?? Space( RPT_GAP )

   ?? Space( RPT_RI )
   cPom := PadR( "80. Zahtjev za povrat ", RPT_W2 - RPT_BOLD_DELTA - 5 ) + " <" + iif( pdv_povrat == "D", "X", " " ) + ">"
   B_ON
   ?? PadL( cPom, RPT_COL - RPT_RI - RPT_BOLD_DELTA  + 1 )
   B_OFF

   show_raz_1()

   ?
   ?? rpt_lm()

   B_ON
   U_ON
   ??U PadR( "III. STATISTIČKI PODACI", RPT_COL - RPT_BOLD_DELTA )
   U_OFF
   B_OFF

   show_raz_1()
   ?? rpt_lm()
   ?? Space( RPT_RI )
   cPom := "PDV isporuke licima koji nisu reg. PDV obveznici u:"
   ?? cPom

   show_raz_1()

   ?? rpt_lm()
   ?? Space( RPT_RI )
   cPom := PadR( "32. Federacije BiH ", RPT_W2 ) + Transform( i_pdv_nr1, PIC_IZN() )
   ?? PadL( cPom, RPT_COL - RPT_RI + 1 )

   show_raz_1()

   ?? rpt_lm()
   ?? Space( RPT_RI )
   cPom := PadR( "33. Republike Srpske ", RPT_W2 ) + Transform( i_pdv_nr2, PIC_IZN() )
   ?? PadL( cPom, RPT_COL - RPT_RI + 1 )

   show_raz_1()
   ?? rpt_lm()
   ?? Space( RPT_RI )
   cPom := PadR( "34. Brčko Distrikta ", RPT_W2 ) + Transform( i_pdv_nr3, PIC_IZN() )
   ??U PadL( cPom, RPT_COL - RPT_RI + 1 )

   show_raz_1()
   show_raz_1()

   ?? rpt_lm()
   ??U "Pod krivičnom i materijalnom odgovornošću potvrđujem da su podaci u PDV prijavi potuni i tačni"

   show_raz_1()
   show_raz_1()

   ?? rpt_lm()
   ?? "Mjesto : "
   U_ON

   cPom := AllTrim( pot_mjesto )
   ?? PadC( cPom, Len( pot_mjesto ) )
   U_OFF

   ?? Space( 35 )
   ?? "Potpis obveznika"

   show_raz_1()

   ?? rpt_lm()

   ?? "Datum : "
   U_ON
   ?? pot_datum
   U_OFF

   ?? Space( 50 )
   U_ON
   cPom := AllTrim( pot_ob )
   ?? PadC( cPom, 55 )
   U_OFF

   show_raz_1()
   ?? rpt_lm()
   ?? Space( 86 )
   ?? "Ime, prezime"

   FF
   ENDPRINT

   RETURN .T.



STATIC FUNCTION show_raz_1()

   ?
   ?

   RETURN .T.


STATIC FUNCTION r_zagl()

   LOCAL i

   P_COND
   B_ON
   FOR i := 1 TO Len( aHeader )
      ? aHeader[ i ]
      ++nCurrLine
   NEXT
   B_OFF

   P_COND2

   FOR i := 1 TO Len( aZagl )
      ++nCurrLine
      ?
      FOR nCol := 1 TO Len( aZaglLen )
         IF Left( aZagl[ i, nCol ], 1 ) = "#"

            nMergirano := Val( SubStr( aZagl[ i, nCol ], 2, 1 ) )
            cPom := SubStr( aZagl[ i, nCol ], 3, Len( aZagl[ i, nCol ] ) - 2 )
            nMrgWidth := 0
            FOR nMrg := 1 TO nMergirano
               nMrgWidth += aZaglLen[ nCol + nMrg - 1 ]
               nMrgWidth++
            NEXT
            ?? PadC( cPom, nMrgWidth )
            ?? " "
            nCol += ( nMergirano - 1 )
         ELSE
            ?? PadC( aZagl[ i, nCol ], aZaglLen[ nCol ] )
            ?? " "
         ENDIF
      NEXT
   NEXT

   RETURN .T.


STATIC FUNCTION rpt_lm()
   RETURN Space( RPT_LM )
