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


FUNCTION print_opomena_pred_tuzbu( hParams )

   ? Replicate( "=", 80 )
   ?U "   Preduzeće   :", hParams[ "naziv" ]
   ?U "     Adresa    :", hParams[ "ptt" ] + " " + AllTrim( hParams[ "mjesto" ] ), ", ", AllTrim( hParams[ "adresa" ] )
   ?U "            tel:", hParams[ "tel" ], "fax:", hParams[ "fax" ]
   ?U "     Žiro račun:", hParams[ "ziror" ]
   ?U "        ID Broj:", hParams[ "idbr" ]
   ?U Replicate( "=", 80 )
   ?
   ?
   ? Replicate( "-", 80 )
   ?U "Prima KUPAC:"
   ?U "----------------------------------------"
   ?U "Id-Naziv:", hParams[ "kupac_1" ]
   ?U "  Adresa:", hParams[ "kupac_3" ]
   ?U "  Mjesto:", hParams[ "kupac_2" ]
   ?U " ID Broj:", hParams[ "kupac_idbr" ]
   ? Replicate( "-", 80 )
   ?
   ?U Space( 44 ), hParams[ "mjesto" ],  "Datum:",  hParams[ "datum" ]
   ?
   ?U "PREDMET: OPOMENA PRED TUŽBU"
   ?U
   ?U "Poštovani, "
   ?U " "
   ?U "S obzirom na neizmirenje Vaših obaveza u Ugovorenim rokovima, prisiljeni"
   ?U "smo da Vam uputimo ovu opomenu."
   ?U
   ?U "Prilažemo Vam kamatni list prema važećim zakonskim stopama."
   ?U
   ?U "Molimo Vas da u ROKU OD 7 dana izmirite dospjeli dug po računima ..", kalk_say_iznos( hParams[ "osndug" ], "99999999.99" ), " KM,"
   ?U "te kamatu u visini    .............................................", kalk_say_iznos( hParams[ "kamate" ], "99999999.99" ), " KM."
   ?U "U suprotnom, bićemo prisiljeni da svoja prava ostvarimo sudskim putem."
   ?U
   ?U "Ovaj dopis sa obračunom kamata šaljemo Vam poštom sa povratnicom."

   RETURN .T.
