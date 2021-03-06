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


FUNCTION mat_izvjestaji()

   LOCAL _opc := {}
   LOCAL _opcexe := {}
   LOCAL _izbor := 1

   // PRIVATE PicDEM:="99999999.99"
   // PRIVATE PicBHD:="999999999.99"
   // PRIVATE PicKol:="999999.999"

   AAdd( _opc, "1. kartica                                " )
   AAdd( _opcexe, {|| mat_kartica() } )
   AAdd( _opc, "2. specifikacija" )
   AAdd( _opcexe, {|| mat_specifikacija() } )
   AAdd( _opc, "3. specifikacija sinteticki" )
   AAdd( _opcexe, {|| mat_sint_specifikacija() } )
   AAdd( _opc, "4. porez na realizaciju" )
   AAdd( _opcexe, {|| pornar() } )

   // rudnik varijanta, treba parametar
   AAdd( _opc, "5. materijal po mjestima troska" )
   AAdd( _opcexe, {|| pomjetros() } )

   AAdd( _opc, "6. cijena artikla po dobavljacima" )
   AAdd( _opcexe, {|| cardob() } )
   AAdd( _opc, "7. specifikacija artikla po mjestu troska" )
   AAdd( _opcexe, {|| iartpopogonima() } )
   AAdd( _opc, "8. specifikacija zaliha po roc.intervalima" )
   AAdd( _opcexe, {|| mat_spec_br_dan() } )

   f18_menu( "matizv", .F., _izbor, _opc, _opcexe )

   my_close_all_dbf()

   RETURN
