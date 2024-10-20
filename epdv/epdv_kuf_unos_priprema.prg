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


STATIC FUNCTION epdv_kuf_tbl_priprema()

   LOCAL _row := f18_max_rows() - 4
   LOCAL _col := f18_max_cols() - 3

   Box(, _row, _col )

   @ box_x_koord() + _row - 2, box_y_koord() + 2 SAY8 "<c-N>  Nove stavke    | <ENT> Ispravi stavku   | <c-T> Briši stavku         "
   @ box_x_koord() + _row - 1, box_y_koord() + 2 SAY8 "<c-A>  Ispravka Naloga| <c-P> Štampa dokumenta | <a-A> Ažuriranje           "
   @ box_x_koord() + _row, box_y_koord() + 2 SAY8 "<a-P>  Povrat dok.    | <a-X> Renumeracija"

   PRIVATE ImeKol
   PRIVATE Kol

   select_o_epdv_p_kuf()
   SET ORDER TO TAG "br_dok"
   GO TOP

   set_a_kol_kuf( @Kol, @ImeKol )
   my_browse( "ekuf", _row, _col, {| nCh | epdv_kuf_key_handler( nCh ) }, "", "KUF Priprema...", , , , , 3 )
   BoxC()
   my_close_all_dbf()

   RETURN .T.


STATIC FUNCTION set_a_kol_kuf( aKol, aImeKol )

   aImeKol := {}

   AAdd( aImeKol, { "Br.dok", {|| Transform( br_dok, "99999" ) }, "br_dok", {|| .T. }, {|| .T. } } )
   AAdd( aImeKol, { "R.br", {|| Transform( r_br, "99999" ) }, "r_br", {|| .T. }, {|| .T. } } )

   AAdd( aImeKol, { "Datum", {|| datum }, "datum", {|| .T. }, {|| .T. } } )
   AAdd( aImeKol, { PadR( "Tarifa", 6 ), {|| id_tar }, "id_tar", {|| .T. }, {|| .T. } } )
   AAdd( aImeKol, { PadR( "Dobavljac", 15 ), {|| PadR( s_partner( id_part ), 13 ) + ".." }, "opis", {|| .T. }, {|| .T. } } )
   AAdd( aImeKol, { PadR( "Broj dobavljaca - Opis", 37 ), {|| PadR( AllTrim( src_br_2 ) + "-" + opis, 35 ) + ".." }, "", {|| .T. }, {|| .T. } } )
   AAdd( aImeKol, { "Izn.b.pdv", {|| Transform( i_b_pdv, PIC_IZN() ) }, "i_b_pdv", {|| .T. }, {|| .T. } } )
   AAdd( aImeKol, { "Izn.pdv", {|| Transform( i_pdv, PIC_IZN() ) }, "i_pdv", {|| .T. }, {|| .T. } } )
   AAdd( aImeKol, { "Izn.s.pdv", {|| Transform( i_b_pdv + i_pdv, PIC_IZN() ) }, "", {|| .T. }, {|| .T. } } )

   aKol := {}
   FOR i := 1 TO Len( aImeKol )
      AAdd( aKol, i )
   NEXT

   RETURN .T.


STATIC FUNCTION epdv_kuf_edit_item( lNova )

   LOCAL cIspravno := "D"
   LOCAL nI_s_pdv := 0
   LOCAL nX := 2
   LOCAL nXPart := 0
   LOCAL nYPart := 22
   LOCAL GetList := {}

   Box(, f18_max_rows() - 10, f18_max_cols() - 12 )
   IF lNova
      _br_dok := 0
      _r_br := epdv_priprema_next_r_br( "P_KUF" )
      _id_part := Space( Len( id_part ) )
      _id_tar := PadR( "PDV17", Len( id_tar ) )
      _datum := Date()
      _opis := Space( Len( opis ) )
      _i_b_pdv := 0
      _i_pdv := 0
      _src_br_2 := Space( Len( src_br_2 ) )
   ENDIF

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "R.br: " GET _r_br  PICT "999999"

   @ box_x_koord() + nX, Col() + 2 SAY "datum: " GET _datum
   nX += 2

   nXPart := nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Dobavljač: " GET _id_part VALID epdv_valid_partner( @_id_part, @_id_tar, "KUF", .T. ) PICT "@!"

   nX += 2

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Broj fakture " GET _src_br_2
   nX++

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Opis stavke: " GET _opis ;
      WHEN {|| SetPos( box_x_koord() + nXPart, box_y_koord() + nYPart ), QQOut( s_partner( _id_part ) ), .T. } PICT "@S50"

   nX += 2

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Iznos bez PDV (osnovica): " GET _i_b_pdv PICT PIC_IZN()
   ++nX

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "tarifa: " GET _id_tar VALID epdv_valid_id_tar( @_id_tar, @_i_b_pdv, @_i_pdv,  Col(), lNova ) PICT "@!"

   ++nX

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "   Iznos PDV: " GET _i_pdv WHEN {||  .T. }  VALID {|| nI_s_pdv := _i_b_pdv + _i_pdv, .T. } PICT PIC_IZN()
   ++nX

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Iznos sa PDV: " GET nI_s_pdv WHEN {|| .F. } PICT PIC_IZN()
   nX += 2

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Ispravno (D/N) ?" GET cIspravno  PICT "@!"
   ++nX

   READ

   SELECT F_P_KUF
   BoxC()

   ESC_RETURN .F.

   IF cIspravno == "D"
      RETURN .T.
   ENDIF

   RETURN .F.



STATIC FUNCTION epdv_kuf_key_handler( Ch )

   LOCAL nTekRec
   LOCAL nBrDokP
   LOCAL GetList := {}

   IF ( Ch == K_CTRL_T .OR. Ch == K_ENTER ) .AND. reccount2() == 0
      RETURN DE_CONT
   ENDIF

   DO CASE

   CASE ( Ch == K_CTRL_T )

      SELECT P_KUF
      RETURN browse_brisi_stavku( .T. )

   CASE ( Ch == K_ENTER )

      SELECT P_KUF
      nTekRec := RecNo()
      my_flock()
      Scatter()
      IF epdv_kuf_edit_item( .F. )
         SELECT P_KUF
         GO nTekRec
         Gather()
         RETURN DE_REFRESH
      ENDIF
      my_unlock()
      RETURN DE_CONT

   CASE ( Ch == K_CTRL_N )

      SELECT P_KUF
      my_flock()

      DO WHILE .T.

         SELECT P_KUF
         APPEND BLANK
         nTekRec := RecNo()
         Scatter()

         IF epdv_kuf_edit_item( .T. )
            GO nTekRec
            Gather()
         ELSE
            SELECT P_KUF
            GO nTekRec
            DELETE
            EXIT
         ENDIF
      ENDDO

      my_unlock()

      SET ORDER TO TAG "BR_DOK"
      GO BOTTOM

      RETURN DE_REFRESH

   CASE ( Ch  == k_ctrl_f9() )

      IF Pitanje( , D_ZELITE_LI_IZBRISATI_PRIPREMU, "N" ) == "D"
         my_dbf_zap()
         RETURN DE_REFRESH
      ENDIF
      RETURN DE_CONT

   CASE Ch == K_CTRL_P

      nBrDokP := 0
      Box( , 2, 60 )
      @ box_x_koord() + 1, box_y_koord() + 2 SAY8 "Dokument (0-štampaj pripremu) " GET nBrDokP PICT "999999"
      READ
      BoxC()
      IF LastKey() <> K_ESC
         epdv_rpt_kuf( nBrDokP )
         my_close_all_dbf()
         epdv_otvori_kuf_priprema()
         SELECT P_KUF
         SET ORDER TO TAG "br_dok"
         RETURN DE_REFRESH
      ENDIF


      RETURN DE_CONT

   CASE is_key_alt_a( Ch )

      IF Pitanje( , "Ažurirati KUF dokument (D/N) ?", "N" ) == "D"
         epdv_azur_kuf()
         RETURN DE_REFRESH
      ELSE
         RETURN DE_CONT
      ENDIF


   CASE is_key_alt_p( Ch )

      IF Pitanje( , "Povrat KUF dokumenta u pripremu (D/N) ?", "N" ) == "D"
         nBrDokP := 0
         Box(, 1, 40 )
         @ box_x_koord() + 1, box_y_koord() + 2 SAY "KUF dokument br:" GET nBrDokP  PICT "999999"
         READ

         BoxC()

         IF LastKey() <> K_ESC
            epdv_povrat_kuf( nBrDokP )
            my_close_all_dbf()
            epdv_otvori_kuf_priprema()
            SELECT P_KUF
            SET ORDER TO TAG "br_dok"
            RETURN DE_REFRESH
         ENDIF
      ENDIF

      SELECT P_KUF
      RETURN DE_REFRESH


   CASE is_key_alt_x( Ch )

      IF Pitanje (, "Izvršiti renumeraciju KUF pripreme (D/N) ?", "N" ) == "D"
         epdv_renumeracija_rbr( "P_KUF", .F. )
      ENDIF

      SELECT P_KUF
      SET ORDER TO TAG "BR_DOK"
      GO TOP

      RETURN DE_REFRESH

   ENDCASE

   RETURN DE_CONT



FUNCTION epdv_edit_kuf()

   epdv_otvori_kuf_priprema()
   epdv_kuf_tbl_priprema()

   RETURN .T.
