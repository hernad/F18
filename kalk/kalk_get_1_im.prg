/*
 * This file is part of the bring.out knowhow ERP, a free and open source
 * Enterprise Resource Planning software suite,
 * Copyright (c) 1994-2011 by bring.out doo Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including FMK specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_knowhow.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */

#include "f18.ch"

MEMVAR GetList, nKalkStrana
MEMVAR _idfirma, _idvd, _idroba, _mkonto, _idkonto, _datdok, _datfaktp

FUNCTION kalk_get_1_im()

   LOCAL nFaktVPC
   LOCAL nKolicinaNaStanju := 0
   LOCAL nKolicinaZadnjaNabavka := 0
   LOCAL nNabCjZadnjaNabavka := 0

   IF Empty( _mkonto )
      _mkonto := _idkonto
   ENDIF

   _DatFaktP := _datdok
   @ box_x_koord() + 8, box_y_koord() + 2  SAY "Konto koji zaduzuje" GET _mkonto VALID  P_Konto( @_mkonto, 8, 30 ) PICT "@!"
   READ
   ESC_RETURN K_ESC

   @ box_x_koord() + 10, box_y_koord() + 66 SAY "Tarif.br->"
   kalk_unos_get_roba_id( @GetList, @_idRoba, @_idTarifa, _IdVd, kalk_is_novi_dokument(), box_x_koord() + 10, box_y_koord() + 2 )
   @ box_x_koord() + 11, box_y_koord() + 70 GET _IdTarifa VALID P_Tarifa( @_IdTarifa )
   READ
   ESC_RETURN K_ESC
   IF roba_barkod_pri_unosu()
      _idRoba := Left( _idRoba, 10 )
   ENDIF

   select_o_tarifa( _IdTarifa )
   SELECT kalk_pripr

   @ box_x_koord() + 13, box_y_koord() + 2  SAY8 "Knjižna kolicina " GET _GKolicina PICTURE PicKol WHEN {|| iif( kalk_metoda_nc() == " ", .T., .F. ) }
   @ box_x_koord() + 13, Col() + 2 SAY8 "Popisana Količina" GET _Kolicina PICTURE PicKol
   READ

   IF kalk_is_novi_dokument()
      _VPC := kalk_vpc_za_koncij()
      _NC := roba->NC
      SELECT kalk_pripr
   ENDIF
   kalk_get_nabavna_mag( _datdok, _idfirma, _idroba, _mkonto, @nKolicinaNaStanju, @nKolicinaZadnjaNabavka, @nNabCjZadnjaNabavka, @_nc )

   @ box_x_koord() + 15, box_y_koord() + 2 SAY8 "NC:" GET _nc PICT picdem
   @ box_x_koord() + 15, COL() + 2 SAY8 "VPC:" GET _vpc PICT picdem

   READ
   ESC_RETURN K_ESC

   //_MKonto := _Idkonto
   _MU_I := "I" // inventura
   _PKonto := ""
   _PU_I := ""

   nKalkStrana := 3

   RETURN LastKey()
