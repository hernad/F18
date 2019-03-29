/*
 * This file is part of the bring.out knowhow ERP, a free and open source
 * Enterprise Resource Planning software suite,
 * Copyright (c) 1994-2018 by bring.out doo Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including FMK specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_knowhow.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */

#include "f18.ch"

THREAD STATIC s_cTipOroganizacije

THREAD STATIC s_cFirma, s_cFirmaNaz

FUNCTION organizacija_params_init()

   s_cFirma := NIL
   s_cFirmaNaz := NIL

   RETURN .T.


FUNCTION self_organizacija_id( cId )

   IF cId != NIL
      s_cFirma := cId
      set_metric( "org_id", NIL, cId )
   ENDIF

   IF s_cFirma == NIL
      s_cFirma := fetch_metric( "org_id", NIL, "10" )
   ENDIF

   RETURN s_cFirma


FUNCTION self_organizacija_naziv( cNaz )

   IF cNaz != NIL
      s_cFirmaNaz := cNaz
      set_metric( "org_naziv", NIL, cNaz )
   ENDIF

   IF s_cFirmaNaz == NIL
      s_cFirmaNaz :=  PadR( fetch_metric( "org_naziv", NIL, "" ), 50 )
   ENDIF

   RETURN s_cFirmaNaz



FUNCTION tip_organizacije( cTip )

   IF s_cTipOroganizacije == NIL
      s_cTipOroganizacije := fetch_metric( "tip_subjekta", nil, "Preduzece" )
   ENDIF

   IF cTip != NIL
      set_metric( "tip_subjekta", nil, cTip )
      s_cTipOroganizacije := cTip
   ENDIF

   RETURN s_cTipOroganizacije



FUNCTION parametri_organizacije( lSetParams )

   LOCAL nX := 1
   LOCAL _left := 20
   LOCAL cTipOrganizacije := tip_organizacije()
   LOCAL cOrganizacijaId := self_organizacija_id()
   LOCAL cOrganizacijaNaz := self_organizacija_naziv()
   LOCAL GetList := {}

   info_bar( "init", "parametri organizacije - start" )
   IF ( lSetParams == nil )
      lSetParams := .T.
   ENDIF

   PUBLIC gZaokr := fetch_metric( "zaokruzenje", nil, gZaokr )
   IF fetch_metric_error() > 0
      RETURN .F.
   ENDIF

   PUBLIC gMjStr := fetch_metric( "org_mjesto", nil, gMjStr )

   PUBLIC gTabela := fetch_metric( "tip_tabele", nil, gTabela )
  //PUBLIC gBaznaV := fetch_metric( "bazna_valuta", nil, gBaznaV )
   PUBLIC gPDV := fetch_metric( "pdv_global", nil, gPDV )


   IF Empty( self_organizacija_naziv() )
      lSetParams := .T.
   ENDIF

   IF lSetParams == .T.  // setovati parametre org.jedinice

      Box(, 10, 70 )

      @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Inicijalna podešenja organizacije ***" COLOR f18_color_i()
      ++nX
      ++nX
      @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "Oznaka firme:", _left ) GET cOrganizacijaId
      @ box_x_koord() + nX, Col() + 2 SAY "naziv:" GET cOrganizacijaNaz PICT "@S35"

      ++nX
      @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "Grad:", _left ) GET gMjStr PICT "@S20"

      ++nX
      @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "Tip subjekta/organizacije:", _left ) GET cTipOrganizacije PICT "@S10"
      @ box_x_koord() + nX, Col() + 1 SAY "U sistemu pdv-a (D/N) ?" GET gPDV VALID gPDV $ "DN" PICT "@!"

      //++nX
      //++nX
      //@ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "Bazna valuta (D/P):", _left ) GET gBaznaV PICT "@!" VALID gBaznaV $ "DPO"

      ++nX
      @ box_x_koord() + nX, box_y_koord() + 2 SAY8 PadL( "Zaokruženje:", _left ) GET gZaokr

      READ

      BoxC()

      IF LastKey() == K_ESC
         RETURN .F.
      ENDIF

      IF LastKey() <> K_ESC
         self_organizacija_id( cOrganizacijaId )
         self_organizacija_naziv( cOrganizacijaNaz )

         set_metric( "zaokruzenje", nil, gZaokr )
         tip_organizacije( cTipOrganizacije )

         //set_metric( "bazna_valuta", nil, gBaznaV )
         set_metric( "pdv_global", nil, gPDV )
         set_metric( "org_mjesto", nil, gMjStr )
      ENDIF

   ENDIF

   info_bar( "init", "parametri organizacije - end" )

   RETURN .T.



FUNCTION SetValuta()
   RETURN .T.
