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


// zaokruzenje iznos
STATIC gZAO_IZN
// zaokruzenje cijena
STATIC gZAO_CIJ
// zaokruzenje cijena
STATIC gZAO_PDV

// picture iznos
STATIC gPIC_IZN

// picture cijena
STATIC gPIC_CIJ

// ulazni pdv koji se ne moze odbiti
// da li ulazi u statistiku krajnje potrosnje
// ako ulazi onda se stavlja polje u koje se dodaje
// " " - ne dodajes u statistiku
// "1" - federacija
// "2" - sprski republikanci
// "3" - brcko district do las vegasa
STATIC gUlPdvKp := "1"


FUNCTION epdv_parametri()

   LOCAL _izbor := 1
   LOCAL _opc := {}
   LOCAL _opcexe := {}

   AAdd( _opc, "1. osnovni podaci org.jedinice            " )
   AAdd( _opcexe, {|| parametri_organizacije() } )
   AAdd( _opc, "2. parametri izgleda  " )
   AAdd( _opcexe, {|| ed_g_params() } )

   f18_menu( "epdv_param", .F., _izbor, _opc, _opcexe )

   RETURN .T.



FUNCTION epdv_update_sifre_params()

   read_epdv_gl_params()  // procitaj globalne - kparams
   epdv_update_sif_tarifa()
   epdv_update_sif_partneri() // napuni sifk radi unosa partnera - rejon

   RETURN .T.



FUNCTION ed_g_params()

   LOCAL nX
   LOCAL GetList := {}

   gPIC_IZN := PadR( gPIC_IZN, 20 )
   gPIC_CIJ := PadR( gPIC_CIJ, 20 )

   gUlPdvKp := PadR( gUlPdvKp, 1 )

   nX := 1
   Box(, 20, 70 )

   set_cursor_on()

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "1. Zaokruzenje ***"
   nX++

   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "iznos ", 30 )   GET gZAO_IZN PICT "9"
   nX++

   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "cijena ", 30 )   GET gZAO_CIJ PICT "9"
   nX++

   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( " podaci na pdv prijavi ", 30 )   GET gZAO_PDV PICT "9"
   nX ++

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "2. Prikaz ***"
   nX ++

   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( " iznos ", 30 )   GET gPIC_IZN
   nX ++

   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( " cijena ", 30 )   GET gPIC_CIJ
   nX ++

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "3. Obracun ***"
   nX ++

   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( " ul. pdv kr.potr-stat fed-1, rs-2, bd-3", 55 )   GET gUlPdvKp VALID gUlPdvKp $ " 123"
   nX ++

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "4. Ostalo ***"
   nX ++
   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( " konta dobavljaci:", 30 ) GET gL_kto_dob  PICT "@S30"
   nX ++

   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "      konta kupci:", 30 ) GET gL_kto_kup  PICT "@S30"
   nX ++

   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "ulazni pdv:", 30 ) GET gKt_updv  PICT "@S30"
   nX ++

   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "izlazni pdv:", 30 ) GET gKt_ipdv  PICT "@S30"

   READ

   BoxC()

   gPIC_IZN := AllTrim( gPIC_IZN )
   gPIC_CIJ := AllTrim( gPIC_CIJ )

   IF LastKey() <> K_ESC
      epdv_write_gparams()
   ENDIF

   RETURN .T.



FUNCTION read_epdv_gl_params()

   gZAO_IZN := 2
   gZAO_CIJ := 3
   gZAO_PDV := 0
   gPIC_IZN := "9999999.99"
   gPIC_CIJ := "9999999.99"
   gUlPdvKp := "1"

   gZAO_IZN := fetch_metric( "epdv_zaokruzenje_iznosa", nil, gZAO_IZN )
   gZAO_CIJ := fetch_metric( "epdv_zaokruzenje_cijene", nil, gZAO_CIJ )
   gZAO_PDV := fetch_metric( "epdv_zaokruzenje_pdv", nil, gZAO_PDV )

   gPIC_IZN := fetch_metric( "epdv_picture_iznos", nil, gPIC_IZN )
   gPIC_CIJ := fetch_metric( "epdv_picture_cijena", nil, gPIC_CIJ )

   gUlPDVKp := fetch_metric( "epdv_ulazni_pdv_krajnja_potrosnja", nil, gUlPdvKp )

   gL_kto_dob := fetch_metric( "epdv_lista_konta_dobavljaca", nil, gL_kto_dob )
   gL_kto_kup := fetch_metric( "epdv_lista_konta_kupaca", nil, gL_kto_kup )
   gkt_updv := fetch_metric( "epdv_konto_ulazni_pdv", nil, gkt_updv )
   gkt_ipdv := fetch_metric( "epdv_konto_izlazni_pdv", nil, gkt_ipdv )

   RETURN .T.



FUNCTION epdv_write_gparams()

   set_metric( "epdv_zaokruzenje_iznosa", nil, gZAO_IZN )
   set_metric( "epdv_zaokruzenje_cijene", nil, gZAO_CIJ )
   set_metric( "epdv_zaokruzenje_pdv", nil, gZAO_PDV )

   set_metric( "epdv_picture_iznos", nil, gPIC_IZN )
   set_metric( "epdv_picture_cijena", nil, gPIC_CIJ )

   set_metric( "epdv_ulazni_pdv_krajnja_potrosnja", nil, gUlPdvKp )

   set_metric( "epdv_lista_konta_dobavljaca", nil, gL_kto_dob )
   set_metric( "epdv_lista_konta_kupaca", nil, gL_kto_kup )
   set_metric( "epdv_konto_ulazni_pdv", nil, gkt_updv )
   set_metric( "epdv_konto_izlazni_pdv", nil, gkt_ipdv )

   RETURN .T.



FUNCTION read_pdv_pars( dPotDatum, cPotMjesto, cPotOb, cPdvPovrat )

   dPotDatum := fetch_metric( "epdv_prijava_datum", nil, dPotDatum )
   dPotMjesto := fetch_metric( "epdv_prijava_mjesto", nil, cPotMjesto )
   cPotOb := fetch_metric( "epdv_prijava_obveznik", nil, cPotOb )
   cPdvPovrat := fetch_metric( "epdv_prijava_povrat", nil, cPdvPovrat )

   RETURN .T.


FUNCTION save_pdv_pars( dPotDatum, cPotMjesto, cPotOb, cPdvPovrat )

   set_metric( "epdv_prijava_datum", nil, dPotDatum )
   set_metric( "epdv_prijava_mjesto", nil, cPotMjesto )
   set_metric( "epdv_prijava_obveznik", nil, cPotOb )
   set_metric( "epdv_prijava_povrat", nil, cPdvPovrat )

   RETURN .T.


// SET - GET sekcija  za PIC i ZAO vrijednostai


FUNCTION ZAO_IZN( xVal )

   IF xVal <> nil
      gZAO_IZN := xVal
   ENDIF

   RETURN gZAO_IZN


FUNCTION ZAO_CIJ( xVal )

   IF xVal <> nil
      gZAO_CIJ := xVal
   ENDIF

   RETURN gZAO_CIJ


FUNCTION ZAO_PDV( xVal )

   IF xVal <> nil
      gZAO_PDV := xVal
   ENDIF

   RETURN gZAO_PDV



FUNCTION PIC_IZN( xVal )

   IF xVal <> nil
      gPIC_IZN := xVal
   ENDIF

   RETURN gPIC_IZN


FUNCTION PIC_CIJ( xVal )

   IF xVal <> nil
      gPIC_CIJ := xVal
   ENDIF

   RETURN gPIC_CIJ



FUNCTION gUlPdvKp( xVal )

   IF xVal <> nil
      gUlPdvKp := xVal
   ENDIF

   RETURN gUlPdvKp
