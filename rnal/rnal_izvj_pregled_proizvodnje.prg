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

STATIC __doc_no
STATIC __nvar1
STATIC __nvar2
STATIC __l_zaok := 0
STATIC __dmg := 0

STATIC __op_1 := 0
STATIC __op_2 := 0
STATIC __op_3 := 0
STATIC __op_4 := 0
STATIC __op_5 := 0
STATIC __op_6 := 0
STATIC __op_7 := 0
STATIC __op_8 := 0
STATIC __op_9 := 0
STATIC __op_10 := 0
STATIC __op_11 := 0
STATIC __op_12 := 0

STATIC __opu_1 := ""
STATIC __opu_2 := ""
STATIC __opu_3 := ""
STATIC __opu_4 := ""
STATIC __opu_5 := ""
STATIC __opu_6 := ""
STATIC __opu_7 := ""
STATIC __opu_8 := ""
STATIC __opu_9 := ""
STATIC __opu_10 := ""
STATIC __opu_11 := ""
STATIC __opu_12 := ""

// ------------------------------------------
// osnovni poziv pregleda proizvodnje
// ------------------------------------------
FUNCTION m_get_rpro()

   LOCAL dD_From := CToD( "" )
   LOCAL dD_to := danasnji_datum()
   LOCAL nOper := 0
   LOCAL cArticle := Space( 100 )
   LOCAL aError
   LOCAL _export
   LOCAL _rpt_file := my_home() + "_tmp1.dbf"

#ifdef __PLATFORM__WINDOWS

   _rpt_file := '"' + _rpt_file + '"'
#endif

   rnal_o_sif_tables()

   // daj uslove izvjestaja
   IF _g_vars( @dD_From, @dD_To, @nOper, @cArticle, @_export ) == 0
      RETURN .T.
   ENDIF

   DO CASE

   CASE __nvar1 = 1
      // kreiraj specifikaciju po elementima
      aError := _cre_sp_el( dD_from, dD_to, nOper, cArticle )
   CASE __nvar1 = 2
      // kreiraj sp. po artiklima
      aError := _cre_sp_art( dD_from, dD_to, nOper, cArticle )

   ENDCASE

   lPrint := .T.

   IF Len( aError ) > 0

      // ima gresaka
      _p_error( aError )

      IF Pitanje(, "Ipak pregledati izvjestaj (D/N) ?", "D" ) == "N"
         lPrint := .F.
      ENDIF

   ENDIF

   IF lPrint == .T. .AND. _export == "N"
      // printaj specifikaciju
      _p_rpt_spec( dD_from, dD_to )
   ENDIF

   IF _export == "D"
      my_close_all_dbf()
      f18_run( _rpt_file )
   ENDIF

   RETURN .T.


// ----------------------------------------
// ispis gresaka
// ----------------------------------------
STATIC FUNCTION _p_error( aArr )

   LOCAL i
   LOCAL cLine
   LOCAL cTxt

   cLine := Replicate( "-", 5 )
   cLine += Space( 1 )
   cLine += Replicate( "-", 30 )
   cLine += Space( 1 )
   cLine += Replicate( "-", 10 )
   cLine += Space( 1 )
   cLine += Replicate( "-", 4 )

   cTxt := PadR( "r.br", 5 )
   cTxt += Space( 1 )
   cTxt += PadR( "opis greske", 30 )
   cTxt += Space( 1 )
   cTxt += PadR( "dokument", 10 )
   cTxt += Space( 1 )
   cTxt += PadR( "st.", 4 )

   START PRINT CRET

   ?
   ? cLine
   ? cTxt
   ? cLine

   FOR i := 1 TO Len( aArr )

      ? PadL( AllTrim( Str ( i ) ), 4 ) + "."
      @ PRow(), PCol() + 1 SAY PadR( aArr[ i, 1 ], 30 )
      @ PRow(), PCol() + 1 SAY docno_str( aArr[ i, 2 ] )
      @ PRow(), PCol() + 1 SAY docit_str( aArr[ i, 3 ] )

   NEXT

   FF
   ENDPRINT

   RETURN .T.



// ------------------------------------------------------------------------
// uslovi izvjestaja specifikacije
// ------------------------------------------------------------------------
STATIC FUNCTION _g_vars( dDatFrom, dDatTo, nOperater, cArticle, cExport )

   LOCAL nRet := 1
   LOCAL nBoxX := 20
   LOCAL nBoxY := 70
   LOCAL nX := 1
   LOCAL nOp1 := nOp2 := nOp3 := nOp4 := nOp5 := nOp6 := 0
   LOCAL nOp7 := nOp8 := nOp9 := nOp10 := nOp11 := nOp12 := 0
   LOCAL cOp1 := cOp2 := cOp3 := cOp4 := cOp5 := cOp6 := Space( 10 )
   LOCAL cOp7 := cOp8 := cOp9 := cOp10 := cOp11 := cOp12 := Space( 10 )
   LOCAL nTArea := Select()
   LOCAL nVar1 := 1
   LOCAL cPartn := "N"
   LOCAL cDmg := "N"
   LOCAL cZaok := "N"
   PRIVATE GetList := {}

   cOp1 := fetch_metric( "rnal_rpt_pro_op1", my_user(), cOp1 )
   cOp2 := fetch_metric( "rnal_rpt_pro_op2", my_user(), cOp2 )
   cOp3 := fetch_metric( "rnal_rpt_pro_op3", my_user(), cOp3 )
   cOp4 := fetch_metric( "rnal_rpt_pro_op4", my_user(), cOp4 )
   cOp5 := fetch_metric( "rnal_rpt_pro_op5", my_user(), cOp5 )
   cOp6 := fetch_metric( "rnal_rpt_pro_op6", my_user(), cOp6 )
   cOp7 := fetch_metric( "rnal_rpt_pro_op7", my_user(), cOp7 )
   cOp8 := fetch_metric( "rnal_rpt_pro_op8", my_user(), cOp8 )
   cOp9 := fetch_metric( "rnal_rpt_pro_op9", my_user(), cOp9 )
   cOp10 := fetch_metric( "rnal_rpt_pro_op10", my_user(), cOp10 )
   cOp11 := fetch_metric( "rnal_rpt_pro_op11", my_user(), cOp11 )
   cOp12 := fetch_metric( "rnal_rpt_pro_op12", my_user(), cOp12 )
   dDatFrom := fetch_metric( "rnal_rpt_pro_datum_od", my_user(), dDatFrom )
   dDatTo := fetch_metric( "rnal_rpt_pro_datum_do", my_user(), dDatTo )
   nVar1 := fetch_metric( "rnal_rpt_pro_varijanta", my_user(), nVar1 )
   cPartn := fetch_metric( "rnal_rpt_pro_partner", my_user(), cPartn )
   cZaok := fetch_metric( "rnal_rpt_pro_zaokruzenje", my_user(), cZaok )
   cDmg := fetch_metric( "rnal_rpt_pro_lom", my_user(), cDmg )
   cExport := "N"

   Box(, nBoxX, nBoxY )

   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "*** Pregled učinka proizvodnje"

   nX += 2
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Obuhvatiti period od:" GET dDatFrom
   @ box_x_koord() + nX, Col() + 1 SAY "do:" GET dDatTo

   nX += 2
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Artikal/element (prazno-svi):" GET cArticle PICT "@S30"

   nX += 1
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "-------------- operacije "

   nX += 1
   nTmp := nX

   // prvi red operacija
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "op. 1:" GET cOp1 ;
      VALID {|| AllTrim( cOp1 ) == "0" .OR. s_aops( @cOp1, cOp1 ), set_var( @nOp1, @cOp1 ), ;
      show_it( g_aop_desc( nOp1 ), 10 ) }

   nX += 1

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "op. 2:" GET cOp2 ;
      VALID {|| AllTrim( cOp2 ) == "0" .OR. s_aops( @cOp2, cOp2 ), set_var( @nOp2, @cOp2 ), ;
      show_it( g_aop_desc( nOp2 ), 10 ) }

   nX += 1

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "op. 3:" GET cOp3 ;
      VALID {|| AllTrim( cOp3 ) == "0" .OR. s_aops( @cOp3, cOp3 ), set_var( @nOp3, @cOp3 ), ;
      show_it( g_aop_desc( nOp3 ), 10 ) }

   nX += 1

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "op. 4:" GET cOp4 ;
      VALID {|| AllTrim( cOp4 ) == "0" .OR. s_aops( @cOp4, cOp4 ), set_var( @nOp4, @cOp4 ), ;
      show_it( g_aop_desc( nOp4 ), 10 ) }

   nX += 1

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "op. 5:" GET cOp5 ;
      VALID {|| AllTrim( cOp5 ) == "0" .OR. s_aops( @cOp5, cOp5 ), set_var( @nOp5, @cOp5 ), ;
      show_it( g_aop_desc( nOp5 ), 10 ) }

   nX += 1

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "op. 6:" GET cOp6 ;
      VALID {|| AllTrim( cOp6 ) == "0" .OR. s_aops( @cOp6, cOp6 ), set_var( @nOp6, @cOp6 ), ;
      show_it( g_aop_desc( nOp6 ), 10 ) }

   // drugi red operacija

   nTmp2 := Col() + 15

   @ box_x_koord() + nTmp, nTmp2 SAY "op. 7:" GET cOp7 ;
      VALID {|| AllTrim( cOp7 ) == "0" .OR. s_aops( @cOp7, cOp7 ), set_var( @nOp7, @cOp7 ), ;
      show_it( g_aop_desc( nOp7 ), 10 ) }

   nTmp += 1

   @ box_x_koord() + nTmp, nTmp2 SAY "op. 8:" GET cOp8 ;
      VALID {|| AllTrim( cOp8 ) == "0" .OR. s_aops( @cOp8, cOp8 ), set_var( @nOp8, @cOp8 ), ;
      show_it( g_aop_desc( nOp8 ), 10 ) }

   nTmp += 1

   @ box_x_koord() + nTmp, nTmp2 SAY "op. 9:" GET cOp9 ;
      VALID {|| AllTrim( cOp9 ) == "0" .OR. s_aops( @cOp9, cOp9 ), set_var( @nOp9, @cOp9 ), ;
      show_it( g_aop_desc( nOp9 ), 10 ) }

   nTmp += 1

   @ box_x_koord() + nTmp, nTmp2 SAY "op.10:" GET cOp10 ;
      VALID {|| AllTrim( cOp10 ) == "0" .OR. s_aops( @cOp10, cOp10 ), set_var( @nOp10, @cOp10 ), ;
      show_it( g_aop_desc( nOp10 ), 10 ) }

   nTmp += 1

   @ box_x_koord() + nTmp, nTmp2 SAY "op.11:" GET cOp11 ;
      VALID {|| AllTrim( cOp11 ) == "0" .OR. s_aops( @cOp11, cOp11 ), set_var( @nOp11, @cOp11 ), ;
      show_it( g_aop_desc( nOp11 ), 10 ) }

   nTmp += 1

   @ box_x_koord() + nTmp, nTmp2 SAY "op.12:" GET cOp12 ;
      VALID {|| AllTrim( cOp12 ) == "0" .OR. s_aops( @cOp12, cOp12 ), set_var( @nOp12, @cOp12 ), ;
      show_it( g_aop_desc( nOp12 ), 10 ) }

   nX += 2

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "-------------- ostali uslovi "

   nX += 1

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Operater (0 - svi op.):" GET nOperater VALID {|| nOperater == 0  } PICT "9999999999"

   nX += 1

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Izvjestaj po (1) elementima (2) artiklima" ;
      GET nVar1 VALID nVar1 > 0 .AND. nVar1 < 3 PICT "9"

   nX += 1

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Izvjestaj se formira po partnerima (D/N)?" ;
      GET cPartn VALID cPartn $ "DN" PICT "@!"

   nX += 1

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Zaokruzenje po GN-u (D/N)?" ;
      GET cZaok VALID cZaok $ "DN" PICT "@!"

   nX += 1

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Kontrolisati lom (D/N)?" ;
      GET cDmg VALID cDmg $ "DN" PICT "@!"

   nX += 1

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Eksport izvjestaja (D/N)?" ;
      GET cExport VALID cExport $ "DN" PICT "@!"


   READ
   BoxC()

   IF LastKey() == K_ESC
      nRet := 0
   ENDIF

   set_metric( "rnal_rpt_pro_op1", my_user(), cOp1 )
   set_metric( "rnal_rpt_pro_op2", my_user(), cOp2 )
   set_metric( "rnal_rpt_pro_op3", my_user(), cOp3 )
   set_metric( "rnal_rpt_pro_op4", my_user(), cOp4 )
   set_metric( "rnal_rpt_pro_op5", my_user(), cOp5 )
   set_metric( "rnal_rpt_pro_op6", my_user(), cOp6 )
   set_metric( "rnal_rpt_pro_op7", my_user(), cOp7 )
   set_metric( "rnal_rpt_pro_op8", my_user(), cOp8 )
   set_metric( "rnal_rpt_pro_op9", my_user(), cOp9 )
   set_metric( "rnal_rpt_pro_op10", my_user(), cOp10 )
   set_metric( "rnal_rpt_pro_op11", my_user(), cOp11 )
   set_metric( "rnal_rpt_pro_op12", my_user(), cOp12 )
   set_metric( "rnal_rpt_pro_datum_od", my_user(), dDatFrom )
   set_metric( "rnal_rpt_pro_datum_do", my_user(), dDatTo )
   set_metric( "rnal_rpt_pro_varijanta", my_user(), nVar1 )
   set_metric( "rnal_rpt_pro_partner", my_user(), cPartn )
   set_metric( "rnal_rpt_pro_zaokruzenje", my_user(), cZaok )
   set_metric( "rnal_rpt_pro_lom", my_user(), cDmg )

   // parametri staticki
   __nvar1 := nVar1
   __nvar2 := 2
   __l_zaok := 0

   // partner
   IF cPartn == "D"
      __nvar2 := 1
   ENDIF

   // zaokruzenje
   IF cZaok == "D"
      __l_zaok := 1
   ENDIF

   IF cDmg == "D"
      __dmg := 1
   ENDIF

   // operacije
   __op_1 := nOp1
   __op_2 := nOp2
   __op_3 := nOp3
   __op_4 := nOp4
   __op_5 := nOp5
   __op_6 := nOp6
   __op_7 := nOp7
   __op_8 := nOp8
   __op_9 := nOp9
   __op_10 := nOp10
   __op_11 := nOp11
   __op_12 := nOp12

   // daj mi jedinice mjere za operacije
   __opu_1 := g_aop_unit( __op_1 )
   __opu_2 := g_aop_unit( __op_2 )
   __opu_3 := g_aop_unit( __op_3 )
   __opu_4 := g_aop_unit( __op_4 )
   __opu_5 := g_aop_unit( __op_5 )
   __opu_6 := g_aop_unit( __op_6 )
   __opu_7 := g_aop_unit( __op_7 )
   __opu_8 := g_aop_unit( __op_8 )
   __opu_9 := g_aop_unit( __op_9 )
   __opu_10 := g_aop_unit( __op_10 )
   __opu_11 := g_aop_unit( __op_11 )
   __opu_12 := g_aop_unit( __op_12 )

   RETURN nRet



// ----------------------------------------------
// kreiraj specifikaciju
// izvjestaj se primarno puni u _tmp0 tabelu
// ----------------------------------------------
STATIC FUNCTION _cre_sp_el( dD_from, dD_to, nOper, cArticle )

   LOCAL nDoc_no
   LOCAL cArt_id
   LOCAL aArt := {}
   LOCAL aElem := {}
   LOCAL cCust_desc
   LOCAL nAop_1 := nAop_2 := nAop_3 := nAop_4 := nAop_5 := nAop_6 := 0
   LOCAL nAop_7 := nAop_8 := nAop_9 := nAop_10 := nAop_11 := nAop_12 := 0
   LOCAL nEl_cnt
   LOCAL nCont_id
   LOCAL nCust_id
   LOCAL aErr := {}

   // kreiraj tmp tabelu
   aField := _spec_fields()

   cre_tmp1( aField )
   o_tmp1()

   // kreiraj indekse
   IF __nvar2 = 2
      INDEX ON art_id + Str( tick, 10, 2 ) TAG "1"
   ELSE
      INDEX ON customer + art_id + Str( tick, 10, 2 ) TAG "1"
   ENDIF

   // otvori potrebne tabele
   rnal_o_tables( .F. )

   SELECT docs
   GO TOP

   Box(, 1, 50 )

   DO WHILE !Eof()

      nDoc_no := field->doc_no

      @ box_x_koord() + 1, box_y_koord() + 2 SAY "... vrsim odabir stavki ... nalog: " + AllTrim( Str( nDoc_no ) )

      nCust_id := field->cust_id
      nCont_id := field->cont_id

      // provjeri da li ovaj dokument zadovoljava kriterij

      IF field->doc_status > 1

         // uslov statusa dokumenta
         SKIP
         LOOP

      ENDIF

      IF DToS( field->doc_date ) > DToS( dD_To ) .OR. ;
            DToS( field->doc_date ) < DToS( dD_From )

         // datumski period
         SKIP
         LOOP

      ENDIF

      IF nOper <> 0

         // po operateru

         IF AllTrim( Str( field->operater_i ) ) <> ;
               AllTrim( Str( nOper ) )

            SKIP
            LOOP

         ENDIF
      ENDIF

      // daj mi kupca
      cCust_desc := _cust_cont( nCust_id, nCont_id )

      // idi na stavke naloga
      SELECT doc_it
      SEEK docno_str( nDoc_no )

      // prodji kroz stavke naloga
      DO WHILE !Eof() .AND. field->doc_no == nDoc_no

         nDoc_it_no := field->doc_it_no
         cDoc_it_type := field->doc_it_typ
         nArt_id := field->art_id

         // artikal nedefinisan
         IF nArt_id = 0

            // dodaj u greske
            AAdd( aErr, { "artikal 0", nDoc_no, nDoc_it_no } )

            SKIP
            LOOP
         ENDIF

         nQtty := field->doc_it_qtt

         nHeight := field->doc_it_hei
         nH_orig := nHeight

         nWidth := field->doc_it_wid
         nW_orig := nWidth

         nH2 := field->doc_it_h2
         nW2 := field->doc_it_w2

         aArt := {}
         aElem := {}

         rnal_matrica_artikla( nArt_id, @aArt )

         IF Len( aArt ) == 0

            _scan := AScan( aErr, {|val| val[ 1 ] == "artikal " + AllTrim( Str( nArt_id ) ) } )
            IF _scan == 0
               AAdd( aErr, { "artikal " + AllTrim( Str( nArt_id ) ), nDoc_no, nDoc_it_no } )
            ENDIF

            SELECT doc_it
            SKIP
            LOOP

         ENDIF

         _g_art_elements( @aElem, nArt_id )

         FOR nEl_cnt := 1 TO Len( aElem )

            nEl_no := aElem[ nEl_cnt, 1 ]

            // broj elementa, 1, 2, 3 ...
            nElem_no := aElem[ nEl_cnt, 3 ]

            // provjeri zaokruzenja
            IF __l_zaok = 1

               l_woZaok := .F.

               IF l_woZaok == .F.
                  l_woZaok := is_kaljeno( aArt, ;
                     nDoc_no, nDoc_it_no, nEl_no, .F. )
               ENDIF

               IF l_woZaok == .F.
                  l_woZaok := is_emajl( aArt, ;
                     nDoc_no, nDoc_it_no, nEl_no, .F. )
               ENDIF

               IF l_woZaok == .F.
                  l_woZaok := is_vglass( aArt )
               ENDIF

               IF l_woZaok == .F.
                  l_woZaok := is_plex( aArt )
               ENDIF

               // zaokruzi vrijednosti
               nHeight := obrl_zaok( nHeight, aArt, l_woZaok )
               nWidth := obrl_zaok( nWidth, aArt, l_woZaok )

            ENDIF

            nDmg := 0

            IF __dmg = 1
               nDmg := calc_dmg( nDoc_no, nDoc_it_no, ;
                  nArt_id, nElem_no )
            ENDIF

            // ukupna kvadratura
            nTot_m2 := c_ukvadrat( nQtty, nWidth, nHeight )

            // ukupno duzinski
            nTot_m := c_duzinski( nQtty, nWidth, nHeight )

            // vrati opis za ovaj artikal
            cArt_id := g_el_descr( aArt, nElem_no )

            IF cArt_id == "unknown"

               AAdd( aErr, { "element unknown", nDoc_no, ;
                  nDoc_it_no } )

               LOOP

            ENDIF

            // uslov po artiklu, ako je zadato
            IF !Empty( cArticle )

               IF AllTrim( cArt_id ) $ cArticle
                  // ovo je ok
               ELSE
                  LOOP
               ENDIF

            ENDIF

            // opis artikla
            cArt_desc := AllTrim( aElem[ nEl_cnt, 2 ] )

            // vidi o kojem se tipu elementa radi
            nTmp := AScan( aArt, {|xVal| xVal[ 1 ] == nElem_no } )

            // je li "G" ili "F" ili ...
            cEl_type := AllTrim( aArt[ nTmp, 2 ] )

            nTick := 0

            IF cEl_type == "G"

               // debljina stakla
               nTick := g_gl_el_tick( aArt, nElem_no )

            ELSE
               // debljina ostalih elemenata
               nTick := g_el_tick( aArt, nElem_no )

               // ako je frame, obracun je drugaciji
               IF cEl_type == "F"

                  nTot_m2 := 0

                  // ( ( mm_2_m(nH_orig) + ;
                  // mm_2_m( nW_orig ) ) * 2 ) * nQtty

               ENDIF

            ENDIF

            _ins_tmp1( cCust_desc, ;
               cArt_id, ;
               cArt_desc, ;
               nTick, ;
               nWidth, ;
               nHeight, ;
               nQtty, ;
               nDmg, ;
               nTot_m, ;
               nTot_m2, ;
               nAop_1, ;
               nAop_2, ;
               nAop_3, ;
               nAop_4, ;
               nAop_5, ;
               nAop_6, ;
               nAop_7, ;
               nAop_8, ;
               nAop_9, ;
               nAop_10, ;
               nAop_11, ;
               nAop_12 )


            // da li ovaj artikal ima u elementima operacija ?

            SELECT e_aops
            GO TOP
            SEEK elid_str( nEl_no )

            DO WHILE !Eof() .AND. field->el_id = nEl_no

               // operacija-1  .T. ?
               IF _in_oper_( __op_1, field->aop_id )
                  nAop_1 := _calc_oper( nQtty, nWidth, nHeight, ;
                     __op_1, __opu_1, cAopValue )
               ENDIF

               // operacija-2  .T. ?
               IF _in_oper_( __op_2, field->aop_id )
                  nAop_2 := _calc_oper( nQtty, nWidth, nHeight, ;
                     __op_2, __opu_2, cAopValue )
               ENDIF

               // operacija-3  .T. ?
               IF _in_oper_( __op_3, field->aop_id )
                  nAop_3 := _calc_oper( nQtty, nWidth, nHeight, ;
                     __op_3, __opu_3, cAopValue )
               ENDIF

               // operacija-4  .T. ?
               IF _in_oper_( __op_4, field->aop_id )
                  nAop_4 := _calc_oper( nQtty, nWidth, nHeight, ;
                     __op_4, __opu_4, cAopValue )
               ENDIF

               // operacija-5  .T. ?
               IF _in_oper_( __op_5, field->aop_id )
                  nAop_5 := _calc_oper( nQtty, nWidth, nHeight, ;
                     __op_5, __opu_5, cAopValue )
               ENDIF

               // operacija-6  .T. ?
               IF _in_oper_( __op_6, field->aop_id )
                  nAop_6 := _calc_oper( nQtty, nWidth, nHeight, ;
                     __op_6, __opu_6, cAopValue )
               ENDIF

               // operacija-7  .T. ?
               IF _in_oper_( __op_7, field->aop_id )
                  nAop_7 := _calc_oper( nQtty, nWidth, nHeight, ;
                     __op_7, __opu_7, cAopValue )
               ENDIF

               // operacija-8  .T. ?
               IF _in_oper_( __op_8, field->aop_id )
                  nAop_8 := _calc_oper( nQtty, nWidth, nHeight, ;
                     __op_8, __opu_8, cAopValue )
               ENDIF

               // operacija-9  .T. ?
               IF _in_oper_( __op_9, field->aop_id )
                  nAop_9 := _calc_oper( nQtty, nWidth, nHeight, ;
                     __op_9, __opu_9, cAopValue )
               ENDIF

               // operacija-10  .T. ?
               IF _in_oper_( __op_10, field->aop_id )
                  nAop_10 := _calc_oper( nQtty, nWidth, nHeight, ;
                     __op_10, __opu_10, cAopValue )
               ENDIF

               // operacija-11  .T. ?
               IF _in_oper_( __op_11, field->aop_id )
                  nAop_11 := _calc_oper( nQtty, nWidth, nHeight, ;
                     __op_11, __opu_11, cAopValue )
               ENDIF

               // operacija-12  .T. ?
               IF _in_oper_( __op_12, field->aop_id )
                  nAop_12 := _calc_oper( nQtty, nWidth, nHeight, ;
                     __op_12, __opu_12, cAopValue )
               ENDIF

               IF ( nAop_1 + nAop_2 + nAop_3 + ;
                     nAop_4 + nAop_5 + nAop_6 + ;
                     nAop_7 + nAop_8 + nAop_9 + ;
                     nAop_10 + nAop_11 + nAop_12 ) > 0

                  _ins_op1( cCust_desc, ;
                     cArt_id, ;
                     nTick, ;
                     nAop_1, ;
                     nAop_2, ;
                     nAop_3, ;
                     nAop_4, ;
                     nAop_5, ;
                     nAop_6, ;
                     nAop_7, ;
                     nAop_8, ;
                     nAop_9, ;
                     nAop_10, ;
                     nAop_11, ;
                     nAop_12 )

               ENDIF

               // resetuj vrijednosti
               nAop_1 := 0
               nAop_2 := 0
               nAop_3 := 0
               nAop_4 := 0
               nAop_5 := 0
               nAop_6 := 0
               nAop_7 := 0
               nAop_8 := 0
               nAop_9 := 0
               nAop_10 := 0
               nAop_11 := 0
               nAop_12 := 0

               SELECT e_aops
               SKIP

            ENDDO

            // provjeri da li ima operacija
            SELECT doc_ops
            SET ORDER TO TAG "2"
            SEEK docno_str( nDoc_no ) + docit_str( nDoc_it_no ) + ;
               docno_str( nEl_no )

            DO WHILE !Eof() .AND. field->doc_no == nDoc_no ;
                  .AND. field->doc_it_no == nDoc_it_no ;
                  .AND. field->doc_it_el_ == nEl_no

               // element artikla nad kojim je operacija
               // izvrsena

               cAopValue := field->aop_value

               // operacija-1  .T. ?
               IF _in_oper_( __op_1, field->aop_id )
                  nAop_1 := _calc_oper( nQtty, nWidth, nHeight, ;
                     __op_1, __opu_1, cAopValue )
               ENDIF

               // operacija-2  .T. ?
               IF _in_oper_( __op_2, field->aop_id )
                  nAop_2 := _calc_oper( nQtty, nWidth, nHeight, ;
                     __op_2, __opu_2, cAopValue )
               ENDIF

               // operacija-3  .T. ?
               IF _in_oper_( __op_3, field->aop_id )
                  nAop_3 := _calc_oper( nQtty, nWidth, nHeight, ;
                     __op_3, __opu_3, cAopValue )
               ENDIF

               // operacija-4  .T. ?
               IF _in_oper_( __op_4, field->aop_id )
                  nAop_4 := _calc_oper( nQtty, nWidth, nHeight, ;
                     __op_4, __opu_4, cAopValue )
               ENDIF

               // operacija-5  .T. ?
               IF _in_oper_( __op_5, field->aop_id )
                  nAop_5 := _calc_oper( nQtty, nWidth, nHeight, ;
                     __op_5, __opu_5, cAopValue )
               ENDIF

               // operacija-6  .T. ?
               IF _in_oper_( __op_6, field->aop_id )
                  nAop_6 := _calc_oper( nQtty, nWidth, nHeight, ;
                     __op_6, __opu_6, cAopValue )
               ENDIF

               // operacija-7  .T. ?
               IF _in_oper_( __op_7, field->aop_id )
                  nAop_7 := _calc_oper( nQtty, nWidth, nHeight, ;
                     __op_7, __opu_7, cAopValue )
               ENDIF

               // operacija-8  .T. ?
               IF _in_oper_( __op_8, field->aop_id )
                  nAop_8 := _calc_oper( nQtty, nWidth, nHeight, ;
                     __op_8, __opu_8, cAopValue )
               ENDIF

               // operacija-9  .T. ?
               IF _in_oper_( __op_9, field->aop_id )
                  nAop_9 := _calc_oper( nQtty, nWidth, nHeight, ;
                     __op_9, __opu_9, cAopValue )
               ENDIF

               // operacija-10  .T. ?
               IF _in_oper_( __op_10, field->aop_id )
                  nAop_10 := _calc_oper( nQtty, nWidth, nHeight, ;
                     __op_10, __opu_10, cAopValue )
               ENDIF

               // operacija-11  .T. ?
               IF _in_oper_( __op_11, field->aop_id )
                  nAop_11 := _calc_oper( nQtty, nWidth, nHeight, ;
                     __op_11, __opu_11, cAopValue )
               ENDIF

               // operacija-12  .T. ?
               IF _in_oper_( __op_12, field->aop_id )
                  nAop_12 := _calc_oper( nQtty, nWidth, nHeight, ;
                     __op_12, __opu_12, cAopValue )
               ENDIF

               IF ( nAop_1 + nAop_2 + nAop_3 + ;
                     nAop_4 + nAop_5 + nAop_6 + ;
                     nAop_7 + nAop_8 + nAop_9 + ;
                     nAop_10 + nAop_11 + nAop_12 ) > 0

                  _ins_op1( cCust_desc, ;
                     cArt_id, ;
                     nTick, ;
                     nAop_1, ;
                     nAop_2, ;
                     nAop_3, ;
                     nAop_4, ;
                     nAop_5, ;
                     nAop_6, ;
                     nAop_7, ;
                     nAop_8, ;
                     nAop_9, ;
                     nAop_10, ;
                     nAop_11, ;
                     nAop_12 )
               ENDIF

               // resetuj vrijednosti
               nAop_1 := 0
               nAop_2 := 0
               nAop_3 := 0
               nAop_4 := 0
               nAop_5 := 0
               nAop_6 := 0
               nAop_7 := 0
               nAop_8 := 0
               nAop_9 := 0
               nAop_10 := 0
               nAop_11 := 0
               nAop_12 := 0

               SELECT doc_ops
               SKIP

            ENDDO

         NEXT

         SELECT doc_it
         SKIP

      ENDDO

      SELECT docs
      SKIP

   ENDDO

   BoxC()

   SELECT _tmp1
   USE

   RETURN aErr



// ----------------------------------------------
// kreiraj specifikaciju po artiklima
// izvjestaj se primarno puni u _tmp0 tabelu
// ----------------------------------------------
STATIC FUNCTION _cre_sp_art( dD_from, dD_to, nOper, cArticle )

   LOCAL nDoc_no
   LOCAL cArt_id
   LOCAL nTick := 0
   LOCAL aArt := {}
   LOCAL nCount := 0
   LOCAL cCust_desc
   LOCAL nAop_1 := nAop_2 := nAop_3 := nAop_4 := nAop_5 := nAop_6 := 0
   LOCAL nAop_7 := nAop_8 := nAop_9 := nAop_10 := nAop_11 := nAop_12 := 0
   LOCAL nCont_id
   LOCAL nCust_id
   LOCAL aErr := {}

   // kreiraj tmp tabelu
   aField := _spec_fields()

   cre_tmp1( aField )
   o_tmp1()

   // kreiraj indekse
   IF __nvar2 = 2
      INDEX ON art_id + Str( tick, 10, 2 ) TAG "1"
   ELSE
      INDEX ON customer + art_id + Str( tick, 10, 2 ) TAG "1"
   ENDIF

   // otvori potrebne tabele
   rnal_o_tables( .F. )

   SELECT elements
   SET ORDER TO TAG "1"
   SELECT e_aops
   SET ORDER TO TAG "1"

   SELECT docs
   GO TOP

   Box(, 1, 50 )

   DO WHILE !Eof()

      nDoc_no := field->doc_no

      @ box_x_koord() + 1, box_y_koord() + 2 SAY8 "... vršim odabir stavki ... nalog: " + AllTrim( Str( nDoc_no ) )

      nCust_id := field->cust_id
      nCont_id := field->cont_id

      // provjeri da li ovaj dokument zadovoljava kriterij

      IF field->doc_status > 1

         // uslov statusa dokumenta
         SKIP
         LOOP

      ENDIF

      IF DToS( field->doc_date ) > DToS( dD_To ) .OR. ;
            DToS( field->doc_date ) < DToS( dD_From )

         // datumski period
         SKIP
         LOOP

      ENDIF

      IF nOper <> 0

         // po operateru

         IF AllTrim( Str( field->operater_i ) ) <> ;
               AllTrim( Str( nOper ) )

            SKIP
            LOOP

         ENDIF
      ENDIF

      // daj mi kupca
      cCust_desc := _cust_cont( nCust_id, nCont_id )

      // pronadji stavku u items
      // i daj osnovne parametre, kolicinu, sirinu, visinu...

      SELECT doc_it
      SET ORDER TO TAG "1"
      GO TOP
      SEEK docno_str( nDoc_no )

      // prodji kroz stavke naloga

      DO WHILE !Eof() .AND. field->doc_no = nDoc_no

         nArt_id := field->art_id

         IF nArt_id = 0
            AAdd( aErr, { "artikal 0", nDoc_no, nDoc_it_no } )
            SKIP
            LOOP
         ENDIF

         SELECT articles
         SEEK artid_str( nArt_id )

         cArt_id := field->art_desc

         // uslov po artiklu, ako postoji
         IF !Empty( cArticle )
            IF AllTrim( cArt_id ) $ cArticle
               // ovo je ok
            ELSE
               SELECT doc_it
               SKIP
               LOOP
            ENDIF
         ENDIF

         cArt_desc := field->art_full_d

         SELECT doc_it

         nDoc_it_no := field->doc_it_no
         cDoc_it_type := field->doc_it_typ

         nQtty := field->doc_it_qtt

         nHeight := field->doc_it_hei
         nWidth := field->doc_it_wid

         // ostecenih stavki
         nDmg := 0

         aArt := {}
         rnal_matrica_artikla( nArt_id, @aArt )

         nGlass_cnt := g_gl_count( aArt )

         // koliko ima elemenenata
         // nElement_cnt := g_el_count( aArt )

         // ako radis zaokruzenja
         IF __l_zaok = 1

            // bez zaokruzenja !
            l_woZaok := .F.

            IF l_woZaok == .F.
               l_woZaok := is_kaljeno( aArt, nDoc_no, nDoc_it_no, NIL, .F. )
            ENDIF

            IF l_woZaok == .F.
               l_woZaok := is_emajl( aArt, nDoc_no, nDoc_it_no, NIL, .F. )
            ENDIF

            IF l_woZaok == .F.
               l_woZaok := is_vglass( aArt )
            ENDIF

            IF l_woZaok == .F.
               l_woZaok := is_plex( aArt )
            ENDIF

            // zaokruzi vrijednosti
            nHeight := obrl_zaok( nHeight, aArt, l_woZaok )
            nWidth := obrl_zaok( nWidth, aArt, l_woZaok )

         ENDIF

         // kalkulisi ostecenja na staklu
         IF __dmg = 1
            nDmg := calc_dmg( nDoc_no, nDoc_it_no, nArt_id )
         ENDIF

         // koliko kvadrata ?
         nTot_m2 := c_ukvadrat( nQtty, nWidth, nHeight )
         nTot_m2 := nTot_m2 * nGlass_cnt

         // koliko duzinski ima stakla
         nTot_m := c_duzinski( nQtty, nWidth, nHeight )
         nTot_m := nTot_m * nGlass_cnt

         nTick := 0

         // upisi vrijednost
         _ins_tmp1( cCust_desc, ;
            cArt_id, ;
            cArt_desc, ;
            nTick, ;
            nWidth, ;
            nHeight, ;
            nQtty, ;
            nDmg, ;
            nTot_m, ;
            nTot_m2, ;
            nAop_1, ;
            nAop_2, ;
            nAop_3, ;
            nAop_4, ;
            nAop_5, ;
            nAop_6, ;
            nAop_7, ;
            nAop_8, ;
            nAop_9, ;
            nAop_10, ;
            nAop_11, ;
            nAop_12 )

         // resetuj vrijednosti
         nAop_1 := 0
         nAop_2 := 0
         nAop_3 := 0
         nAop_4 := 0
         nAop_5 := 0
         nAop_6 := 0
         nAop_7 := 0
         nAop_8 := 0
         nAop_9 := 0
         nAop_10 := 0
         nAop_11 := 0
         nAop_12 := 0

         // da li ovaj artikal ima u elementima operacija ?

         SELECT elements
         GO TOP
         SEEK artid_str( nArt_id )

         cAopValue := ""

         DO WHILE !Eof() .AND. field->art_id = nArt_id

            nEl_id := field->el_id

            SELECT e_aops
            GO TOP
            SEEK elid_str( nEl_id )

            DO WHILE !Eof() .AND. field->el_id = nEl_id

               // operacija-1  .T. ?
               IF _in_oper_( __op_1, field->aop_id )
                  nAop_1 := _calc_oper( nQtty, nWidth, nHeight, ;
                     __op_1, __opu_1, cAopValue )
               ENDIF

               // operacija-2  .T. ?
               IF _in_oper_( __op_2, field->aop_id )
                  nAop_2 := _calc_oper( nQtty, nWidth, nHeight, ;
                     __op_2, __opu_2, cAopValue )
               ENDIF

               // operacija-3  .T. ?
               IF _in_oper_( __op_3, field->aop_id )
                  nAop_3 := _calc_oper( nQtty, nWidth, nHeight, ;
                     __op_3, __opu_3, cAopValue )
               ENDIF

               // operacija-4  .T. ?
               IF _in_oper_( __op_4, field->aop_id )
                  nAop_4 := _calc_oper( nQtty, nWidth, nHeight, ;
                     __op_4, __opu_4, cAopValue )
               ENDIF

               // operacija-5  .T. ?
               IF _in_oper_( __op_5, field->aop_id )
                  nAop_5 := _calc_oper( nQtty, nWidth, nHeight, ;
                     __op_5, __opu_5, cAopValue )
               ENDIF

               // operacija-6  .T. ?
               IF _in_oper_( __op_6, field->aop_id )
                  nAop_6 := _calc_oper( nQtty, nWidth, nHeight, ;
                     __op_6, __opu_6, cAopValue )
               ENDIF

               // operacija-7  .T. ?
               IF _in_oper_( __op_7, field->aop_id )
                  nAop_7 := _calc_oper( nQtty, nWidth, nHeight, ;
                     __op_7, __opu_7, cAopValue )
               ENDIF

               // operacija-8  .T. ?
               IF _in_oper_( __op_8, field->aop_id )
                  nAop_8 := _calc_oper( nQtty, nWidth, nHeight, ;
                     __op_8, __opu_8, cAopValue )
               ENDIF

               // operacija-9  .T. ?
               IF _in_oper_( __op_9, field->aop_id )
                  nAop_9 := _calc_oper( nQtty, nWidth, nHeight, ;
                     __op_9, __opu_9, cAopValue )
               ENDIF

               // operacija-10  .T. ?
               IF _in_oper_( __op_10, field->aop_id )
                  nAop_10 := _calc_oper( nQtty, nWidth, nHeight, ;
                     __op_10, __opu_10, cAopValue )
               ENDIF

               // operacija-11  .T. ?
               IF _in_oper_( __op_11, field->aop_id )
                  nAop_11 := _calc_oper( nQtty, nWidth, nHeight, ;
                     __op_11, __opu_11, cAopValue )
               ENDIF

               // operacija-12  .T. ?
               IF _in_oper_( __op_12, field->aop_id )
                  nAop_12 := _calc_oper( nQtty, nWidth, nHeight, ;
                     __op_12, __opu_12, cAopValue )
               ENDIF

               IF ( nAop_1 + nAop_2 + nAop_3 + ;
                     nAop_4 + nAop_5 + nAop_6 + ;
                     nAop_7 + nAop_8 + nAop_9 + ;
                     nAop_10 + nAop_11 + nAop_12 ) > 0

                  _ins_op1( cCust_desc, ;
                     cArt_id, ;
                     nTick, ;
                     nAop_1, ;
                     nAop_2, ;
                     nAop_3, ;
                     nAop_4, ;
                     nAop_5, ;
                     nAop_6, ;
                     nAop_7, ;
                     nAop_8, ;
                     nAop_9, ;
                     nAop_10, ;
                     nAop_11, ;
                     nAop_12 )

               ENDIF

               // resetuj vrijednosti
               nAop_1 := 0
               nAop_2 := 0
               nAop_3 := 0
               nAop_4 := 0
               nAop_5 := 0
               nAop_6 := 0
               nAop_7 := 0
               nAop_8 := 0
               nAop_9 := 0
               nAop_10 := 0
               nAop_11 := 0
               nAop_12 := 0

               SELECT e_aops
               SKIP

            ENDDO

            SELECT elements
            SKIP
         ENDDO


         // prebaci se na operacije i vidi da li one zadovoljavaju
         SELECT doc_ops
         SEEK docno_str( nDoc_no ) + docit_str( nDoc_it_no )

         DO WHILE !Eof() .AND. field->doc_no = nDoc_no ;
               .AND. field->doc_it_no = nDoc_it_no

            // element artikla nad kojim je operacija izvrsena
            nEl_no := field->doc_it_el_
            cAopValue := field->aop_value

            aElem := {}
            nElem_no := 0

            // operacija-1  .T. ?
            IF _in_oper_( __op_1, field->aop_id )
               nAop_1 := _calc_oper( nQtty, nWidth, nHeight, ;
                  __op_1, __opu_1, cAopValue )
            ENDIF

            // operacija-2  .T. ?
            IF _in_oper_( __op_2, field->aop_id )
               nAop_2 := _calc_oper( nQtty, nWidth, nHeight, ;
                  __op_2, __opu_2, cAopValue )
            ENDIF

            // operacija-3  .T. ?
            IF _in_oper_( __op_3, field->aop_id )
               nAop_3 := _calc_oper( nQtty, nWidth, nHeight, ;
                  __op_3, __opu_3, cAopValue )
            ENDIF

            // operacija-4  .T. ?
            IF _in_oper_( __op_4, field->aop_id )
               nAop_4 := _calc_oper( nQtty, nWidth, nHeight, ;
                  __op_4, __opu_4, cAopValue )
            ENDIF

            // operacija-5  .T. ?
            IF _in_oper_( __op_5, field->aop_id )
               nAop_5 := _calc_oper( nQtty, nWidth, nHeight, ;
                  __op_5, __opu_5, cAopValue )
            ENDIF

            // operacija-6  .T. ?
            IF _in_oper_( __op_6, field->aop_id )
               nAop_6 := _calc_oper( nQtty, nWidth, nHeight, ;
                  __op_6, __opu_6, cAopValue )
            ENDIF

            // operacija-7  .T. ?
            IF _in_oper_( __op_7, field->aop_id )
               nAop_7 := _calc_oper( nQtty, nWidth, nHeight, ;
                  __op_7, __opu_7, cAopValue )
            ENDIF

            // operacija-8  .T. ?
            IF _in_oper_( __op_8, field->aop_id )
               nAop_8 := _calc_oper( nQtty, nWidth, nHeight, ;
                  __op_8, __opu_8, cAopValue )
            ENDIF

            // operacija-9  .T. ?
            IF _in_oper_( __op_9, field->aop_id )
               nAop_9 := _calc_oper( nQtty, nWidth, nHeight, ;
                  __op_9, __opu_9, cAopValue )
            ENDIF

            // operacija-10  .T. ?
            IF _in_oper_( __op_10, field->aop_id )
               nAop_10 := _calc_oper( nQtty, nWidth, nHeight, ;
                  __op_10, __opu_10, cAopValue )
            ENDIF

            // operacija-11  .T. ?
            IF _in_oper_( __op_11, field->aop_id )
               nAop_11 := _calc_oper( nQtty, nWidth, nHeight, ;
                  __op_11, __opu_11, cAopValue )
            ENDIF

            // operacija-12  .T. ?
            IF _in_oper_( __op_12, field->aop_id )
               nAop_12 := _calc_oper( nQtty, nWidth, nHeight, ;
                  __op_12, __opu_12, cAopValue )
            ENDIF

            IF ( nAop_1 + nAop_2 + nAop_3 + ;
                  nAop_4 + nAop_5 + nAop_6 + ;
                  nAop_7 + nAop_8 + nAop_9 + ;
                  nAop_10 + nAop_11 + nAop_12 ) > 0

               _ins_op1( cCust_desc, ;
                  cArt_id, ;
                  nTick, ;
                  nAop_1, ;
                  nAop_2, ;
                  nAop_3, ;
                  nAop_4, ;
                  nAop_5, ;
                  nAop_6, ;
                  nAop_7, ;
                  nAop_8, ;
                  nAop_9, ;
                  nAop_10, ;
                  nAop_11, ;
                  nAop_12 )

            ENDIF

            // resetuj vrijednosti
            nAop_1 := 0
            nAop_2 := 0
            nAop_3 := 0
            nAop_4 := 0
            nAop_5 := 0
            nAop_6 := 0
            nAop_7 := 0
            nAop_8 := 0
            nAop_9 := 0
            nAop_10 := 0
            nAop_11 := 0
            nAop_12 := 0

            SELECT doc_ops
            SKIP

         ENDDO

         SELECT doc_it
         SKIP

      ENDDO

      SELECT docs
      SKIP
   ENDDO

   BoxC()

   SELECT _tmp1
   USE

   RETURN aErr


// --------------------------------------------------------------------
// kalkulisi operaciju nad elementom
// nQtty - kolicina
// nH - height
// nW - width
// nOp - id operacija
// cOpU - jedinica mjere operacije
// cValue - value polja operacije iz baze "<A_B>:23#22#33" i slicno...
// lComp - .t. - komponentno staklo
// --------------------------------------------------------------------
STATIC FUNCTION _calc_oper( nQtty, nH, nW, nOp, cOpU, cValue, lComp )

   LOCAL nKol
   LOCAL nTArea := Select()
   LOCAL nU_m2 := c_ukvadrat( nQtty, nH, nW )

   IF lComp == nil
      lComp := .F.
   ENDIF

   cJoker := g_aop_joker( nOp )

   // iscupaj na osnovu jokera kako se racuna operacija
   // kolicina, m ili m2

   DO CASE
   CASE Upper( cOpU ) == "M"

      nKol := rnal_g_kol( cValue, cOpU, nQtty, nH, nW, 0, 0 )

   CASE Upper( cOpU ) == "KOM"

      nKol := rnal_g_kol( cValue, cOpU, nQtty, nH, nW, 0, 0 )

   CASE Upper( cOpU ) == "M2"

      nKol := nU_m2

   OTHERWISE

      nKol := nU_m2

   ENDCASE

   SELECT ( nTArea )

   RETURN nKol


FUNCTION rnal_g_kol( cValue, cQttyType, nKol, nQtty, nHeigh1, nWidth1 )

   LOCAL nTmp := 0

   // po metru
   IF Upper( cQttyType ) == "M"

      // po metru, znači uzmi sve stranice stakla

      IF "#D1#" $ cValue
         nTmp += nWidth1
      ENDIF

      IF "#D4#" $ cValue
            nTmp += nWidth1
      ENDIF

      IF "#D2#" $ cValue
         nTmp += nHeigh1
      ENDIF

      IF "#D3#" $ cValue
            nTmp += nHeigh1
      ENDIF

      // pretvori u metre
      nKol := ( nQtty * nTmp ) / 1000

   ENDIF

   // po m2
   IF Upper( cQttyType ) == "M2"

      nKol := c_ukvadrat( nQtty, nHeigh1, nWidth1 )

   ENDIF

   // po komadu
   IF Upper( cQttyType ) == "KOM"

      // busenje
      IF "<A_BU>" $ cValue

         // broj rupa za busenje
         cTmp := StrTran( AllTrim( cValue ), "<A_BU>:#" )
         aTmp := TokToNiz( cTmp, "#" )
         nKol := Len( aTmp )

      ELSE
         nKol := nQtty
      ENDIF

   ENDIF

   IF Empty( cQttyType )

      nKol := nQtty

   ENDIF

   RETURN nKol


// ----------------------------------------------------------
// da li je zadovoljen uslov operacije ?
// ----------------------------------------------------------
STATIC FUNCTION _in_oper_( nOp, nFldOp )

   LOCAL lRet := .F.

   // ako je operacija 0 - nista od toga
   // ili ako se ne slaze sa operacijom iz polja

   IF ( nOp <> 0 .AND. nOp = nFldOp )
      lRet := .T.
   ENDIF

   RETURN lRet



// ------------------------------------------
// stampa specifikacije
// stampa se iz _tmp0 tabele
// ------------------------------------------
STATIC FUNCTION _p_rpt_spec( dD1, dD2 )

   LOCAL nT_height := 0
   LOCAL nT_width := 0
   LOCAL nT_qtty := 0
   LOCAL nT_um2 := 0
   LOCAL nT_um := 0
   LOCAL nT_dmg := 0
   LOCAL cLine := ""
   LOCAL nCount := 0

   LOCAL nT_aop1 := 0
   LOCAL nT_aop2 := 0
   LOCAL nT_aop3 := 0
   LOCAL nT_aop4 := 0
   LOCAL nT_aop5 := 0
   LOCAL nT_aop6 := 0
   LOCAL nT_aop7 := 0
   LOCAL nT_aop8 := 0
   LOCAL nT_aop9 := 0
   LOCAL nT_aop10 := 0
   LOCAL nT_aop11 := 0
   LOCAL nT_aop12 := 0

   START PRINT CRET

   ?
   P_COND2

   _rpt_descr( dD1, dD2 )
   __rpt_info()
   _rpt_head( @cLine )

   o_tmp1()
   SELECT _tmp1
   SET ORDER TO TAG "1"
   GO TOP

   DO WHILE !Eof()

      IF _nstr()
         FF
      ENDIF

      ? PadL( AllTrim( Str( ++nCount ) ) + ".", 6 )

      IF __nvar2 = 1
         @ PRow(), PCol() + 1 SAY PadR( AllTrim( field->customer ), 30 )
      ENDIF

      @ PRow(), PCol() + 1 SAY field->art_id

      IF __nvar1 = 1
         @ PRow(), PCol() + 1 SAY Str( field->tick, 6, 2 )
      ENDIF

      @ PRow(), PCol() + 1 SAY Str( field->qtty, 12, 2 )

      IF __dmg = 1
         @ PRow(), PCol() + 1 SAY Str( field->dmg, 12, 2 )
      ENDIF

      @ PRow(), PCol() + 1 SAY Str( field->width, 12, 2 )
      @ PRow(), PCol() + 1 SAY Str( field->height, 12, 2 )
      @ PRow(), PCol() + 1 SAY Str( field->tot_m, 12, 2 )
      @ PRow(), PCol() + 1 SAY Str( field->total, 12, 2 )

      nT_height += field->height
      nT_width += field->width
      nT_um2 += field->total
      nT_um += field->tot_m
      nT_qtty += field->qtty
      nT_dmg += field->dmg

      nT_aop1 += field->aop_1
      nT_aop2 += field->aop_2
      nT_aop3 += field->aop_3
      nT_aop4 += field->aop_4
      nT_aop5 += field->aop_5
      nT_aop6 += field->aop_6
      nT_aop7 += field->aop_7
      nT_aop8 += field->aop_8
      nT_aop9 += field->aop_9
      nT_aop10 += field->aop_10
      nT_aop11 += field->aop_11
      nT_aop12 += field->aop_12

      IF __op_1 <> 0
         @ PRow(), PCol() + 1 SAY Str( field->aop_1, 12, 2 )
      ENDIF

      IF __op_2 <> 0
         @ PRow(), PCol() + 1 SAY Str( field->aop_2, 12, 2 )
      ENDIF

      IF __op_3 <> 0
         @ PRow(), PCol() + 1 SAY Str( field->aop_3, 12, 2 )
      ENDIF

      IF __op_4 <> 0
         @ PRow(), PCol() + 1 SAY Str( field->aop_4, 12, 2 )
      ENDIF

      IF __op_5 <> 0
         @ PRow(), PCol() + 1 SAY Str( field->aop_5, 12, 2 )
      ENDIF

      IF __op_6 <> 0
         @ PRow(), PCol() + 1 SAY Str( field->aop_6, 12, 2 )
      ENDIF

      IF __op_7 <> 0
         @ PRow(), PCol() + 1 SAY Str( field->aop_7, 12, 2 )
      ENDIF

      IF __op_8 <> 0
         @ PRow(), PCol() + 1 SAY Str( field->aop_8, 12, 2 )
      ENDIF

      IF __op_9 <> 0
         @ PRow(), PCol() + 1 SAY Str( field->aop_9, 12, 2 )
      ENDIF

      IF __op_10 <> 0
         @ PRow(), PCol() + 1 SAY Str( field->aop_10, 12, 2 )
      ENDIF

      IF __op_11 <> 0
         @ PRow(), PCol() + 1 SAY Str( field->aop_11, 12, 2 )
      ENDIF

      IF __op_12 <> 0
         @ PRow(), PCol() + 1 SAY Str( field->aop_12, 12, 2 )
      ENDIF

      SKIP

   ENDDO

   ? cLine

   IF __nvar2 = 1
      nLen := 66
   ELSE
      nLen := 35
   ENDIF

   ? PadR( "UKUPNO:", nLen )

   IF __nvar1 = 1
      @ PRow(), PCol() + 1 SAY PadR( "", 8 )
   ELSE
      @ PRow(), PCol() + 1 SAY PadR( "", 1 )
   ENDIF

   @ PRow(), PCol() + 1 SAY Str( nT_qtty, 12, 2 )

   IF __dmg = 1
      @ PRow(), PCol() + 1 SAY Str( nT_dmg, 12, 2 )
   ENDIF

   @ PRow(), PCol() + 1 SAY Str( nT_width, 12, 2 )
   @ PRow(), PCol() + 1 SAY Str( nT_height, 12, 2 )
   @ PRow(), PCol() + 1 SAY Str( nT_um, 12, 2 )
   @ PRow(), PCol() + 1 SAY Str( nT_um2, 12, 2 )

   IF __op_1 <> 0
      @ PRow(), PCol() + 1 SAY Str( nT_aop1, 12, 2 )
   ENDIF
   IF __op_2 <> 0
      @ PRow(), PCol() + 1 SAY Str( nT_aop2, 12, 2 )
   ENDIF
   IF __op_3 <> 0
      @ PRow(), PCol() + 1 SAY Str( nT_aop3, 12, 2 )
   ENDIF
   IF __op_4 <> 0
      @ PRow(), PCol() + 1 SAY Str( nT_aop4, 12, 2 )
   ENDIF
   IF __op_5 <> 0
      @ PRow(), PCol() + 1 SAY Str( nT_aop5, 12, 2 )
   ENDIF
   IF __op_6 <> 0
      @ PRow(), PCol() + 1 SAY Str( nT_aop6, 12, 2 )
   ENDIF
   IF __op_7 <> 0
      @ PRow(), PCol() + 1 SAY Str( nT_aop7, 12, 2 )
   ENDIF
   IF __op_8 <> 0
      @ PRow(), PCol() + 1 SAY Str( nT_aop8, 12, 2 )
   ENDIF
   IF __op_9 <> 0
      @ PRow(), PCol() + 1 SAY Str( nT_aop9, 12, 2 )
   ENDIF
   IF __op_10 <> 0
      @ PRow(), PCol() + 1 SAY Str( nT_aop10, 12, 2 )
   ENDIF
   IF __op_11 <> 0
      @ PRow(), PCol() + 1 SAY Str( nT_aop11, 12, 2 )
   ENDIF
   IF __op_12 <> 0
      @ PRow(), PCol() + 1 SAY Str( nT_aop12, 12, 2 )
   ENDIF

   ? cLine

   my_close_all_dbf()

   FF
   ENDPRINT

   RETURN


STATIC FUNCTION _nstr()

   LOCAL lRet := .F.

   IF PRow() > 62
      lRet := .T.
   ENDIF

   RETURN lRet



STATIC FUNCTION _rpt_descr( dD1, dD2 )

   LOCAL cTmp := "rpt: "

   cTmp += "Pregled ucinka proizvodnje za period "

   ? cTmp

   cTmp := " - po "

   IF __nvar1 = 1
      cTmp += "elementima "
   ELSE
      cTmp += "artiklima "
   ENDIF

   cTmp += "za period od " + DToC( dD1 ) + " do " + DToC( dD2 )

   ? cTmp

   RETURN


STATIC FUNCTION _rpt_head( cLine )

   cLine := ""
   cTxt := ""
   cTxt2 := ""

   cLine += Replicate( "-", 6 )
   cLine += Space( 1 )

   IF __nvar2 = 1
      cLine += Replicate( "-", 30 )
      cLine += Space( 1 )
   ENDIF

   cLine += Replicate( "-", 30 )
   cLine += Space( 1 )

   IF __nvar1 = 1
      cLine += Replicate( "-", 6 )
      cLine += Space( 1 )
   ENDIF

   cLine += Replicate( "-", 12 )
   cLine += Space( 1 )

   IF __dmg = 1

      cLine += Replicate( "-", 12 )
      cLine += Space( 1 )

   ENDIF

   cLine += Replicate( "-", 12 )
   cLine += Space( 1 )
   cLine += Replicate( "-", 12 )
   cLine += Space( 1 )
   cLine += Replicate( "-", 12 )
   cLine += Space( 1 )
   cLine += Replicate( "-", 12 )

   cTxt += PadR( "r.br", 6 )
   cTxt += Space( 1 )

   IF __nvar2 = 1
      cTxt += PadR( "Partner", 30 )
      cTxt += Space( 1 )
   ENDIF

   cTxt += PadR( "Artikal / element", 30 )
   cTxt += Space( 1 )

   IF __nvar1 = 1
      cTxt += PadR( "Deblj.", 6 )
      cTxt += Space( 1 )
   ENDIF

   cTxt += PadR( "Kolicina", 12 )
   cTxt += Space( 1 )

   IF __dmg = 1
      cTxt += PadR( "Ostecenih", 12 )
      cTxt += Space( 1 )
   ENDIF

   cTxt += PadR( "Uk.sirina", 12 )
   cTxt += Space( 1 )
   cTxt += PadR( "Uk.visina", 12 )
   cTxt += Space( 1 )
   cTxt += PadR( "Ukupno", 12 )
   cTxt += Space( 1 )
   cTxt += PadR( "Ukupno", 12 )

   cTxt2 += PadR( "", 6 )
   cTxt2 += Space( 1 )

   IF __nvar2 = 1
      cTxt2 += PadR( "", 30 )
      cTxt2 += Space( 1 )
   ENDIF

   cTxt2 += PadR( "", 30 )
   cTxt2 += Space( 1 )

   IF __nvar1 = 1
      cTxt2 += PadR( "(mm)", 6 )
      cTxt2 += Space( 1 )
   ENDIF

   cTxt2 += PadR( "(kom)", 12 )
   cTxt2 += Space( 1 )

   IF __dmg = 1
      cTxt2 += PadR( "(kom)", 12 )
      cTxt2 += Space( 1 )
   ENDIF

   cTxt2 += PadR( "(m)", 12 )
   cTxt2 += Space( 1 )
   cTxt2 += PadR( "(m)", 12 )
   cTxt2 += Space( 1 )
   cTxt2 += PadR( "(m)", 12 )
   cTxt2 += Space( 1 )
   cTxt2 += PadR( "(m2)", 12 )

   IF __op_1 <> 0

      cTmp := AllTrim( g_aop_desc( __op_1 ) )

      cLine += Space( 1 )
      cLine += Replicate( "-", 12 )

      cTxt += Space( 1 )
      cTxt += PadR( cTmp, 12 )

      cTxt2 += Space( 1 )
      cTxt2 += PadC( "(" + AllTrim( __opu_1 ) + ")", 12 )

   ENDIF

   IF __op_2 <> 0

      cTmp := AllTrim( g_aop_desc( __op_2 ) )
      cLine += Space( 1 )
      cLine += Replicate( "-", 12 )
      cTxt += Space( 1 )
      cTxt += PadR( cTmp, 12 )
      cTxt2 += Space( 1 )
      cTxt2 += PadC( "(" + AllTrim( __opu_2 ) + ")", 12 )

   ENDIF

   IF __op_3 <> 0

      cTmp := AllTrim( g_aop_desc( __op_3 ) )
      cLine += Space( 1 )
      cLine += Replicate( "-", 12 )
      cTxt += Space( 1 )
      cTxt += PadR( cTmp, 12 )
      cTxt2 += Space( 1 )
      cTxt2 += PadC( "(" + AllTrim( __opu_3 ) + ")", 12 )

   ENDIF

   IF __op_4 <> 0

      cTmp := AllTrim( g_aop_desc( __op_4 ) )
      cLine += Space( 1 )
      cLine += Replicate( "-", 12 )
      cTxt += Space( 1 )
      cTxt += PadR( cTmp, 12 )
      cTxt2 += Space( 1 )
      cTxt2 += PadC( "(" + AllTrim( __opu_4 ) + ")", 12 )

   ENDIF

   IF __op_5 <> 0

      cTmp := AllTrim( g_aop_desc( __op_5 ) )
      cLine += Space( 1 )
      cLine += Replicate( "-", 12 )
      cTxt += Space( 1 )
      cTxt += PadR( cTmp, 12 )
      cTxt2 += Space( 1 )
      cTxt2 += PadC( "(" + AllTrim( __opu_5 ) + ")", 12 )

   ENDIF

   IF __op_6 <> 0

      cTmp := AllTrim( g_aop_desc( __op_6 ) )
      cLine += Space( 1 )
      cLine += Replicate( "-", 12 )
      cTxt += Space( 1 )
      cTxt += PadR( cTmp, 12 )
      cTxt2 += Space( 1 )
      cTxt2 += PadC( "(" + AllTrim( __opu_6 ) + ")", 12 )

   ENDIF

   IF __op_7 <> 0

      cTmp := AllTrim( g_aop_desc( __op_7 ) )
      cLine += Space( 1 )
      cLine += Replicate( "-", 12 )
      cTxt += Space( 1 )
      cTxt += PadR( cTmp, 12 )
      cTxt2 += Space( 1 )
      cTxt2 += PadC( "(" + AllTrim( __opu_7 ) + ")", 12 )

   ENDIF

   IF __op_8 <> 0

      cTmp := AllTrim( g_aop_desc( __op_8 ) )
      cLine += Space( 1 )
      cLine += Replicate( "-", 12 )
      cTxt += Space( 1 )
      cTxt += PadR( cTmp, 12 )
      cTxt2 += Space( 1 )
      cTxt2 += PadC( "(" + AllTrim( __opu_8 ) + ")", 12 )

   ENDIF

   IF __op_9 <> 0

      cTmp := AllTrim( g_aop_desc( __op_9 ) )
      cLine += Space( 1 )
      cLine += Replicate( "-", 12 )
      cTxt += Space( 1 )
      cTxt += PadR( cTmp, 12 )
      cTxt2 += Space( 1 )
      cTxt2 += PadC( "(" + AllTrim( __opu_9 ) + ")", 12 )

   ENDIF

   IF __op_10 <> 0

      cTmp := AllTrim( g_aop_desc( __op_10 ) )
      cLine += Space( 1 )
      cLine += Replicate( "-", 12 )
      cTxt += Space( 1 )
      cTxt += PadR( cTmp, 12 )
      cTxt2 += Space( 1 )
      cTxt2 += PadC( "(" + AllTrim( __opu_10 ) + ")", 12 )

   ENDIF

   IF __op_11 <> 0

      cTmp := AllTrim( g_aop_desc( __op_11 ) )
      cLine += Space( 1 )
      cLine += Replicate( "-", 12 )
      cTxt += Space( 1 )
      cTxt += PadR( cTmp, 12 )
      cTxt2 += Space( 1 )
      cTxt2 += PadC( "(" + AllTrim( __opu_11 ) + ")", 12 )

   ENDIF

   IF __op_12 <> 0

      cTmp := AllTrim( g_aop_desc( __op_12 ) )
      cLine += Space( 1 )
      cLine += Replicate( "-", 12 )
      cTxt += Space( 1 )
      cTxt += PadR( cTmp, 12 )
      cTxt2 += Space( 1 )
      cTxt2 += PadC( "(" + AllTrim( __opu_12 ) + ")", 12 )

   ENDIF

   ? cLine
   ? cTxt
   ? cTxt2
   ? cLine

   RETURN



STATIC FUNCTION _spec_fields()

   LOCAL aDbf := {}

   AAdd( aDbf, { "customer", "C", 100, 0 } )
   AAdd( aDbf, { "art_id",  "C", 30, 0 } )
   AAdd( aDbf, { "art_desc", "C", 100, 0 } )
   AAdd( aDbf, { "tick", "N", 10, 2 } )
   AAdd( aDbf, { "width", "N", 15, 5 } )
   AAdd( aDbf, { "height", "N", 15, 5 } )
   AAdd( aDbf, { "qtty", "N", 15, 5 } )
   AAdd( aDbf, { "dmg", "N", 15, 5 } )
   AAdd( aDbf, { "tot_m", "N", 15, 5 } )
   AAdd( aDbf, { "total", "N", 15, 5 } )
   AAdd( aDbf, { "aop_1", "N", 15, 5 } )
   AAdd( aDbf, { "aop_2", "N", 15, 5 } )
   AAdd( aDbf, { "aop_3", "N", 15, 5 } )
   AAdd( aDbf, { "aop_4", "N", 15, 5 } )
   AAdd( aDbf, { "aop_5", "N", 15, 5 } )
   AAdd( aDbf, { "aop_6", "N", 15, 5 } )
   AAdd( aDbf, { "aop_7", "N", 15, 5 } )
   AAdd( aDbf, { "aop_8", "N", 15, 5 } )
   AAdd( aDbf, { "aop_9", "N", 15, 5 } )
   AAdd( aDbf, { "aop_10", "N", 15, 5 } )
   AAdd( aDbf, { "aop_11", "N", 15, 5 } )
   AAdd( aDbf, { "aop_12", "N", 15, 5 } )

   RETURN aDbf


STATIC FUNCTION tick_str( nTick )
   RETURN Str( nTick, 10, 2 )


STATIC FUNCTION _ins_tmp1( cCust_desc, cArt_id, cArt_desc, ;
      nTick, nWidth, nHeight, nQtty, nDmg, nTot_m, nTot_m2, ;
      nAop_1, nAop_2, nAop_3, nAop_4, nAop_5, nAop_6, ;
      nAop_7, nAop_8, nAop_9, nAop_10, nAop_11, nAop_12 )

   LOCAL nTArea := Select()

   SELECT _tmp1
   SET ORDER TO TAG "1"
   GO TOP

   IF __nvar2 = 1
      SEEK PadR( cCust_desc, 100 ) + PadR( cArt_id, 30 ) + tick_str( nTick )
   ELSE
      SEEK PadR( cArt_id, 30 ) + tick_str( nTick )
   ENDIF

   IF !Found()

      APPEND BLANK

      REPLACE field->customer WITH cCust_desc

      REPLACE field->art_id WITH cArt_id
      REPLACE field->art_desc WITH cArt_desc

      REPLACE field->tick WITH nTick

   ENDIF

   // pretvori ove vrijednosti u metre
   nWidth := mm_2_m( nWidth )
   nHeight := mm_2_m( nHeight )

   my_flock()

   REPLACE field->width with ( field->width + ( nWidth * nQtty ) )
   REPLACE field->height with ( field->height + ( nHeight * nQtty ) )
   REPLACE field->qtty with ( field->qtty + nQtty )
   REPLACE field->TOTAL with ( field->total + nTot_m2 )
   REPLACE field->tot_m with ( field->tot_m + nTot_m )
   REPLACE field->dmg with ( field->dmg + nDmg )

   IF __op_1 <> 0 .AND. nAop_1 <> nil
      REPLACE field->aop_1 with ( field->aop_1 + nAop_1 )
   ENDIF

   IF __op_2 <> 0 .AND. nAop_2 <> nil
      REPLACE field->aop_2 with ( field->aop_2 + nAop_2 )
   ENDIF

   IF __op_3 <> 0 .AND. nAop_3 <> nil
      REPLACE field->aop_3 with ( field->aop_3 + nAop_3 )
   ENDIF

   IF __op_4 <> 0 .AND. nAop_4 <> nil
      REPLACE field->aop_4 with ( field->aop_4 + nAop_4 )
   ENDIF

   IF __op_5 <> 0 .AND. nAop_5 <> nil
      REPLACE field->aop_5 with ( field->aop_5 + nAop_5 )
   ENDIF

   IF __op_6 <> 0 .AND. nAop_6 <> nil
      REPLACE field->aop_6 with ( field->aop_6 + nAop_6 )
   ENDIF

   IF __op_7 <> 0 .AND. nAop_7 <> nil
      REPLACE field->aop_7 with ( field->aop_7 + nAop_7 )
   ENDIF

   IF __op_8 <> 0 .AND. nAop_8 <> nil
      REPLACE field->aop_8 with ( field->aop_8 + nAop_8 )
   ENDIF

   IF __op_9 <> 0 .AND. nAop_9 <> nil
      REPLACE field->aop_9 with ( field->aop_9 + nAop_9 )
   ENDIF

   IF __op_10 <> 0 .AND. nAop_10 <> nil
      REPLACE field->aop_10 with ( field->aop_10 + nAop_10 )
   ENDIF

   IF __op_11 <> 0 .AND. nAop_11 <> nil
      REPLACE field->aop_11 with ( field->aop_11 + nAop_11 )
   ENDIF

   IF __op_12 <> 0 .AND. nAop_12 <> nil
      REPLACE field->aop_12 with ( field->aop_12 + nAop_12 )
   ENDIF

   my_unlock()

   SELECT ( nTArea )

   RETURN


STATIC FUNCTION _ins_dmg( cCust_desc, cArt_id, nTick, nDmg )

   LOCAL nTArea := Select()

   SELECT _tmp1
   SET ORDER TO TAG "1"
   GO TOP

   IF __nvar2 = 1
      SEEK PadR( cCust_desc, 100 ) + PadR( cArt_id, 30 ) + tick_str( nTick )
   ELSE
      SEEK PadR( cArt_id, 30 ) + tick_str( nTick )
   ENDIF

   RREPLACE field->dmg with ( field->dmg + nDmg )

   SELECT ( nTArea )

   RETURN




STATIC FUNCTION _ins_op1( cCust_desc, cArt_id, nTick, ;
      nAop_1, nAop_2, nAop_3, ;
      nAop_4, nAop_5, nAop_6, ;
      nAop_7, nAop_8, nAop_9, ;
      nAop_10, nAop_11, nAop_12 )

   LOCAL nTArea := Select()

   SELECT _tmp1
   SET ORDER TO TAG "1"
   GO TOP

   IF __nvar2 = 1
      SEEK PadR( cCust_desc, 100 ) + PadR( cArt_id, 30 ) + tick_str( nTick )
   ELSE
      SEEK PadR( cArt_id, 30 ) + tick_str( nTick )
   ENDIF

   my_flock()

   IF __op_1 <> 0 .AND. nAop_1 <> nil
      REPLACE field->aop_1 with ( field->aop_1 + nAop_1 )
   ENDIF

   IF __op_2 <> 0 .AND. nAop_2 <> nil
      REPLACE field->aop_2 with ( field->aop_2 + nAop_2 )
   ENDIF

   IF __op_3 <> 0 .AND. nAop_3 <> nil
      REPLACE field->aop_3 with ( field->aop_3 + nAop_3 )
   ENDIF

   IF __op_4 <> 0 .AND. nAop_4 <> nil
      REPLACE field->aop_4 with ( field->aop_4 + nAop_4 )
   ENDIF

   IF __op_5 <> 0 .AND. nAop_5 <> nil
      REPLACE field->aop_5 with ( field->aop_5 + nAop_5 )
   ENDIF

   IF __op_6 <> 0 .AND. nAop_6 <> nil
      REPLACE field->aop_6 with ( field->aop_6 + nAop_6 )
   ENDIF

   IF __op_7 <> 0 .AND. nAop_7 <> nil
      REPLACE field->aop_7 with ( field->aop_7 + nAop_7 )
   ENDIF

   IF __op_8 <> 0 .AND. nAop_8 <> nil
      REPLACE field->aop_8 with ( field->aop_8 + nAop_8 )
   ENDIF

   IF __op_9 <> 0 .AND. nAop_9 <> nil
      REPLACE field->aop_9 with ( field->aop_9 + nAop_9 )
   ENDIF

   IF __op_10 <> 0 .AND. nAop_10 <> nil
      REPLACE field->aop_10 with ( field->aop_10 + nAop_10 )
   ENDIF

   IF __op_11 <> 0 .AND. nAop_11 <> nil
      REPLACE field->aop_11 with ( field->aop_11 + nAop_11 )
   ENDIF

   IF __op_12 <> 0 .AND. nAop_12 <> nil
      REPLACE field->aop_12 with ( field->aop_12 + nAop_12 )
   ENDIF

   my_unlock()

   SELECT ( nTArea )

   RETURN
