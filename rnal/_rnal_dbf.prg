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


FUNCTION select_o_dbf_aops()
   RETURN select_o_dbf( "AOPS", F_AOPS, "rnal_aops", "1" )

FUNCTION select_o_dbf_e_aops()
   RETURN select_o_dbf( "E_AOPS", F_E_AOPS, "rnal_e_aops", "1" )

FUNCTION select_o_dbf_e_att()
   RETURN select_o_dbf( "E_ATT", F_E_ATT, "rnal_e_att", "1" )

FUNCTION select_o_dbf_e_gr_att()
   RETURN select_o_dbf( "E_GR_ATT", F_E_GR_ATT, "rnal_e_gr_att", "1" )

FUNCTION select_o_dbf_e_gr_Val()
   RETURN select_o_dbf( "E_GR_VAL", F_E_GR_VAL, "rnal_e_gr_val", "1" )

FUNCTION select_o_dbf_aops_att()
   RETURN select_o_dbf( "AOPS_ATT", F_AOPS_ATT, "aops_att", "1" )

FUNCTION select_o_dbf_articles()
   RETURN select_o_dbf( "ARTICLES", F_ARTICLES, "articles", "1" )

FUNCTION select_o_dbf_e_groups()
   RETURN select_o_dbf( "E_GROUPS", F_E_GROUPS, "e_groups", "1" )

FUNCTION select_o_dbf_elements()
   RETURN select_o_dbf( "ELEMENTS", F_ELEMENTS, "elements", "1" )
