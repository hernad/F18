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


// KUF

//FUNCTION select_o_epdv_kuf()
//   RETURN select_o_dbf( "KUF", F_KUF, "epdv_kuf", "DATUM" )


FUNCTION select_o_epdv_p_kuf()
   RETURN select_o_dbf( "P_KUF", F_P_KUF, "epdv_p_kuf", "DATUM" )

FUNCTION select_o_epdv_r_kuf()
   RETURN select_o_dbf( "R_KUF", F_R_KUF, "epdv_r_kuf", "br_dok" )



// KIF

//FUNCTION select_o_epdv_kif()
//   RETURN select_o_dbf( "KIF", F_KIF, "epdv_kif", "DATUM" )


// set_a_dbf_temp( "epdv_p_kif", "P_KIF", F_P_KIF )

FUNCTION select_o_epdv_p_kif()
   RETURN select_o_dbf( "P_KIF", F_P_KIF, "epdv_p_kif", "DATUM" )

FUNCTION select_o_epdv_r_kif()
   RETURN select_o_dbf( "R_KIF", F_R_KIF, "epdv_r_kif", "br_dok" )





// PDV

//FUNCTION select_o_epdv_pdv()
//   RETURN select_o_dbf( "PDV", F_PDV, "epdv_pdv", "period" )

FUNCTION select_o_epdv_r_pdv()
   RETURN select_o_dbf( "R_PDV", F_R_PDV, "epdv_r_pdv", NIL )
