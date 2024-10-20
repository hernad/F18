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


FUNCTION say_kolicina( nVar, cPic )

   hb_default( @cPic, kalk_prosiri_pic_kolicina_za_2() )

   RETURN say_pict( nVar, cPic, .T. )


FUNCTION kalk_say_iznos( nVar, cPic )

   hb_default( @cPic, kalk_prosiri_pic_iznos_za_2() )

   RETURN say_pict( nVar, cPic )


FUNCTION say_cijena( nVar, cPic )

   hb_default( @cPic, kalk_prosiri_pic_cjena_za_2() )

   RETURN say_pict( nVar, cPic )


FUNCTION say_pict( nVar, cPicture, lZero )

   LOCAL nLen, cPic1, cPic2, cIspis, nI

   hb_default( @lZero, .F. )

   IF ValType( nVar ) == "C" // npr. "[NIV]"
      RETURN PadC( nVar, Len( cPicture ) )
   ENDIF

   cPic1 := StrTran( cPicture, "@Z ", "" )
   cPic1 := StrTran( cPic1, " ", "" )
   nLen := Len( cPic1 )

   nVar := Round( nVar, 4 )
   FOR nI := 0 TO 3  // 99999, 9999.9, 999.99, 99.999
      IF nI == 0
         cPic2 := Replicate( "9", nLen )
      ELSE
         cPic2 := Replicate( "9", nLen - nI - 1 ) + "." + Replicate( "9", nI )
      ENDIF

      IF lZero
         cPic2 := "@Z " + cPic2
      ENDIF
      cIspis := Transform( nVar, cPic2 ) // 5.2 "999999" => "    5"

      IF Val( cIspis ) == nVar
         RETURN cIspis
      ENDIF

   NEXT

   RETURN Transform( nVar, cPicture ) // ako nista ne odgovara


/*
      sredjivanje formata ispisa
*/
FUNCTION pic_format( cPicture, nNum )

   LOCAL cPictureOut

   IF "*" $ Transform( nNum, cPicture )
      cPictureOut := StrTran( cPicture, ".", "9" ) // jednostavno ukini decimalno mjesto kod ispisa
   ELSE
      cPictureOut := cPicture
   ENDIF

   RETURN cPictureOut
