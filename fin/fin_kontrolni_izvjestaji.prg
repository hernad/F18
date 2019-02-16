/*
 * This file is part of the bring.out knowhow ERP, a free and open source
 * ERP software suite,
 * Copyright (c) 1994-2018 by bring.out d.o.o Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including knowhow ERP specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_knowhow.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */

#include "f18.ch"


FUNCTION fin_kontrolni_izvjestaji_meni()

   PRIVATE opc := {}
   PRIVATE opcexe := {}
   PRIVATE Izbor := 1

   AAdd( opc, "N. podešenje brojača naloga" )
   AAdd( opcexe, {|| fin_set_param_broj_dokumenta() } )
   AAdd( opc, "R. fmk pravila - rules " )
   AAdd( opcexe, {|| p_rules(,,, aRuleCols, bRuleBlock ) } )

   f18_menu_sa_priv_vars_opc_opcexe_izbor( "adm" )

   RETURN .T.


FUNCTION fin_valid_provjeri_postoji_nalog( cIdFirma, cIdVn, cBrNal )

   IF find_nalog_by_broj_dokumenta( cIdFirma, cIdVn, cBrNal )
      error_bar( "fin_unos", " Dupli nalog " + cIdFirma + "-" + cIdvn + "-" + cBrNal )
      RETURN .F.
   ENDIF

   RETURN .T.
