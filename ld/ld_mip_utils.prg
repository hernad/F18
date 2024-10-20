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



// --------------------------------------------
// pregled tabele za MIP obrazac
// --------------------------------------------
FUNCTION ld_mip_view()

   LOCAL i
   PRIVATE Kol
   PRIVATE ImeKol

   SELECT r_export
   GO TOP

   ImeKol := {}

   AAdd( ImeKol, { "Radnik", {|| idradn } } )
   AAdd( ImeKol, { "RJ", {|| idrj } } )
   AAdd( ImeKol, { PadR( "Period", 7 ), {|| Str( godina, 4 ) + "/" + Str( mjesec, 2 ) } } )
   AAdd( ImeKol, { "V.Ispl", {|| PadR( vr_ispl, 2 ) } } )
   AAdd( ImeKol, { "Opcina", {|| PadR( r_opc, 3 ) } } )
   AAdd( ImeKol, { "Sati", {|| r_sati } } )
   AAdd( ImeKol, { "Sati b.", {|| r_satib } } )
   AAdd( ImeKol, { "Bruto", {|| bruto } } )
   AAdd( ImeKol, { "print", {|| print }, "print", {|| .T. }, {|| .T. } } )

   Kol := {}
   FOR i := 1 TO Len( ImeKol )
      AAdd( Kol, i )
   NEXT

   Box(, 20, 77 )

   @ box_x_koord() + 17, box_y_koord() + 2 SAY "<F2> Ispravi stavku                           "
   @ box_x_koord() + 18, box_y_koord() + 2 SAY "<c-T> Brisi stavku     "
   @ box_x_koord() + 19, box_y_koord() + 2 SAY "<SPACE> markiraj stavku za stampu"
   @ box_x_koord() + 20, box_y_koord() + 2 SAY "               "

   my_browse( "R_EXPORT", 20, 77, {|| EdMIP() }, "", "Pregled tabele za gen.mip obrasca", , , , {|| IIF( bol_preko == "1", .T., .F. ) }, 4 )

   BoxC()

   RETURN .T.


// ----------------------------------------
// edit mip
// ----------------------------------------
STATIC FUNCTION EdMIP()

   // prikazi na vrhu radnika
   show_radnik()

   DO CASE

   CASE Ch == K_CTRL_T
      // brisanje stavke iz pregleda
      IF Pitanje(, "Sigurno zelite izbrisati zapis ?", "N" ) == "D"
         DELETE
      ENDIF
      RETURN DE_REFRESH

   CASE Ch == K_F2
      // ispravi stavku
      RETURN EditItem()

   CASE Ch == Asc( " " ) .OR. Ch == K_ENTER

      IF Empty( field->print )
         REPLACE field->PRINT WITH "X"
      ELSE
         REPLACE field->PRINT WITH ""
      ENDIF

      RETURN DE_REFRESH

   ENDCASE

   RETURN DE_CONT



// ----------------------------------------
// ispravka stavke
// ----------------------------------------
STATIC FUNCTION edititem()

   LOCAL nX := 1

   scatter()

   Box(, 20, 70 )

   @ box_x_koord() + nX, box_y_koord() + 2 SAY AllTrim( _idradn ) + " - " + PadR( _r_ime, 30 )

   ++ nX
   ++ nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "'kod' opcine" GET _r_opc PICT "@S3"

   ++ nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "vrsta isplate" GET _vr_ispl PICT "@S10"

   ++ nX
   ++ nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "sati" GET _r_sati
   @ box_x_koord() + nX, Col() + 1 SAY "sati bolov." GET _r_satib

   ++ nX
   ++ nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "bruto" GET _bruto
   @ box_x_koord() + nX, Col() + 1 SAY "opor.prih." GET _u_opor

   ++ nX
   ++ nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "dopr.pio" GET _u_d_pio
   @ box_x_koord() + nX, Col() + 1 SAY "dopr.zdr" GET _u_d_zdr
   @ box_x_koord() + nX, Col() + 1 SAY "dopr.nez" GET _u_d_nez

   ++ nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "uk.dopr.iz" GET _u_d_iz

   ++ nX
   ++ nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "licni odbici" GET _l_odb

   ++ nX
   ++ nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "osnovica poreza" GET _osn_por
   @ box_x_koord() + nX, Col() + 1 SAY "porez" GET _izn_por

   READ
   BoxC()

   IF LastKey() == K_ESC
      RETURN DE_CONT
   ENDIF

   gather()

   RETURN DE_REFRESH


// --------------------------------------------
// prikaz radnika na vrhu forme
// --------------------------------------------
STATIC FUNCTION show_radnik()

   @ 2, 2 SAY PadR( field->r_ime, 30 ) + ;
      "(" + AllTrim( field->r_jmb ) + ")"

   RETURN
