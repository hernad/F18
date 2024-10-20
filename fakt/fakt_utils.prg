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



FUNCTION _uk_sa_pdv( cIdTipDok, cPartner, nIznos )

   LOCAL nRet := 0
   LOCAL nTArea := Select()

   IF cIdTipDok $ "11#13#23"
      nRet := nIznos
   ELSE
      IF !partner_is_ino( cPartner ) .AND. !is_part_pdv_oslob_po_clanu( cPartner )
         nRet := ( nIznos * 1.17 )
      ELSE
         nRet := nIznos
      ENDIF
   ENDIF

   SELECT ( nTArea )

   RETURN nRet



FUNCTION _osnovica( cIdTipDok, cPartner, nIznos )

   LOCAL nRet := 0
   LOCAL nTArea := Select()

   IF cIdTipDok $ "11#13#23"
      nRet := ( nIznos / 1.17 )
   ELSE
      nRet := nIznos
   ENDIF

   SELECT ( nTArea )

   RETURN nRet



FUNCTION _pdv( cIdTipDok, cPartner, nIznos )

   LOCAL nRet := 0
   LOCAL nTArea := Select()

   IF cIdTipDok $ "11#13#23"
      nRet := ( nIznos / 1.17 ) * 0.17
   ELSE
      IF !partner_is_ino( cPartner ) .AND. !is_part_pdv_oslob_po_clanu( cPartner )
         nRet := ( nIznos * 0.17 )
      ELSE
         nRet := 0
      ENDIF
   ENDIF

   SELECT ( nTArea )

   RETURN nRet




FUNCTION fakt_objekat_naz( id_obj )

   LOCAL _ret := ""

   PushWA()

   IF select_o_fakt_objekti( id_obj )
      _ret := AllTrim( field->naz )
   ENDIF

   PopWa()

   RETURN _ret



// --------------------------------------------------
// Vraca objekat iz tabele fakt
// ako se zadaje bez parametara pretpostavlja se da je
// napravljena tabela relacije fakt_doks->fakt
// --------------------------------------------------
FUNCTION fakt_objekat_id( cIdFirma, id_tipdok, cBrDok )

   LOCAL _ret := ""
   LOCAL aMemo

   PushWA()
   IF cIdFirma == NIL
      cIdFirma = fakt->idfirma
      id_tipdok = fakt->idtipdok
      cBrDok = fakt->brdok
   ENDIF

   //SELECT ( F_FAKT )

   //IF !Used()
    //  o_fakt_dbf()
   //ENDIF

   IF !seek_fakt( cIdFirma, id_tipdok, cBrDok ) // + "  1"
   //IF Eof()
      _ret := Space( 10 )
   ELSE
      aMemo := fakt_ftxt_decode( fakt->txt )
      IF Len( aMemo ) >= 20
         _ret := PadR( aMemo[ 20 ], 10 )
      ENDIF
   ENDIF

   PopWa()

   RETURN _ret



FUNCTION fakt_memo_field_to_txt( memo_field )

   LOCAL _txt := ""
   LOCAL _val := ""
   LOCAL nI

   FOR nI := 1 TO Len( memo_field )

      _tmp := memo_field[ nI ]

      IF ValType( _tmp ) == "D"
         _val := DToC( _tmp )
      ELSEIF ValType( _tmp ) == "N"
         _val := Val( _tmp )
      ELSE
         _val := _tmp
      ENDIF

      _txt += Chr( 16 ) + _val + Chr( 17 )

   NEXT

   RETURN _txt



FUNCTION get_fakt_vezni_dokumenti( cIdFirma, cIdTipDok, cBrDok )

   LOCAL _t_arr := Select()
   LOCAL _ret := ""
   LOCAL aMemo



   IF !seek_fakt( cIdFirma, cIdTipDok, cBrDok )
   //IF Eof()
      RETURN _ret
   ENDIF

   aMemo := fakt_ftxt_decode( fakt->txt )

   IF Len( aMemo ) >= 19
      _ret := aMemo[ 19 ]
   ENDIF

   SELECT ( _t_arr )

   RETURN _ret



FUNCTION fakt_priprema_prazna()

   LOCAL _ret := .T.
   LOCAL nDbfArea := Select()

   SELECT ( F_FAKT_PRIPR )
   IF !Used()
      o_fakt_pripr()
   ENDIF

   IF RECCOUNT2() == 0
      SELECT ( nDbfArea )
      RETURN _ret
   ENDIF

   _ret := .F.

   IF Pitanje(, "Priprema modula FAKT nije prazna, izbrisati postojeće stavke (D/N) ?", "N" ) == "D"

      SELECT fakt_pripr
      my_dbf_zap()
      _ret := .T.

   ENDIF

   SELECT ( nDbfArea )

   RETURN _ret
