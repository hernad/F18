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

FUNCTION cre_all_rnal( ver )

   LOCAL aDbf
   LOCAL _alias, _table_name
   LOCAL _created
   LOCAL _tbl

   aDbf := a_docs()
   _alias := "DOCS"
   _table_name := "rnal_docs"

   IF_NOT_FILE_DBF_CREATE

   // 0.8.6
   IF ver[ "current" ] > 0 .AND. ver[ "current" ] < 00806
      FOR EACH _tbl in { _table_name, "rnal__docs" }
         modstru( { "*" + _tbl, "C OPERATER_I N 3 0 OPERATER_I N 10 0" } )
      NEXT
   ENDIF

   // 0.9.0
   IF ver[ "current" ] > 0 .AND. ver[ "current" ] < 00900
      FOR EACH _tbl in { _table_name }
         modstru( { "*" + _tbl, "A DOC_TYPE C 2 0" } )
      NEXT
   ENDIF


   CREATE_INDEX( "1", "STR(doc_no,10)", _alias )
   CREATE_INDEX( "A", "STR(doc_status,2)+STR(doc_no,10)", _alias )
   CREATE_INDEX( "2", "STR(doc_priori,4)+DTOS(doc_date)+STR(doc_no,10)", _alias )
   CREATE_INDEX( "3", "STR(doc_priori,4)+DTOS(doc_dvr_da)+STR(doc_no,10)", _alias )
   CREATE_INDEX( "D1", "DTOS(doc_date)+STR(doc_no,10)", _alias )
   CREATE_INDEX( "D2", "DTOS(doc_dvr_da)+STR(doc_no,10)", _alias )
   AFTER_CREATE_INDEX

   _alias := "_DOCS"
   _table_name := "rnal__docs"

   IF_NOT_FILE_DBF_CREATE

   // 0.9.0
   IF ver[ "current" ] > 0 .AND. ver[ "current" ] < 00900
      FOR EACH _tbl in { _table_name }
         modstru( { "*" + _tbl, "A DOC_TYPE C 2 0" } )
      NEXT
   ENDIF

   CREATE_INDEX( "1", "STR(doc_no,10)", _alias )
   CREATE_INDEX( "A", "STR(doc_status,2)+STR(doc_no,10)", _alias )
   CREATE_INDEX( "2", "STR(doc_priori,4)+DTOS(doc_date)+STR(doc_no,10)", _alias )
   CREATE_INDEX( "3", "STR(doc_priori,4)+DTOS(doc_dvr_da)+STR(doc_no,10)", _alias )
   CREATE_INDEX( "D1", "DTOS(doc_date)+STR(doc_no,10)", _alias )
   CREATE_INDEX( "D2", "DTOS(doc_dvr_da)+STR(doc_no,10)", _alias )

   aDbf := a_doc_it()
   _alias := "DOC_IT"
   _table_name := "rnal_doc_it"

   IF_NOT_FILE_DBF_CREATE


   CREATE_INDEX( "1", "STR(doc_no,10)+STR(doc_it_no,4)+STR(art_id,10)", _alias )
   CREATE_INDEX( "2", "STR(art_id,10)+STR(doc_no,10)+STR(doc_it_no,4)", _alias )
   CREATE_INDEX( "3", "STR(doc_no,10)+STR(art_id,10)", _alias )
   AFTER_CREATE_INDEX

   _alias := "_DOC_IT"
   _table_name := "rnal__doc_it"

   IF_NOT_FILE_DBF_CREATE

   CREATE_INDEX( "1", "STR(doc_no,10)+STR(doc_it_no,4)+STR(art_id,10)", _alias )
   CREATE_INDEX( "2", "STR(art_id,10)+STR(doc_no,10)+STR(doc_it_no,4)", _alias )
   CREATE_INDEX( "3", "STR(doc_no,10)+STR(art_id,10)", _alias )


   aDbf := a_doc_it2()
   _alias := "DOC_IT2"
   _table_name := "rnal_doc_it2"

   IF_NOT_FILE_DBF_CREATE

   // 0.9.4
   IF ver[ "current" ] > 0 .AND. ver[ "current" ] < 00904
      FOR EACH _tbl in { _table_name, "rnal__doc_it2" }
         modstru( { "*" + _tbl, "A JMJ C 3 0", "A JMJ_ART C 3 0" } )
      NEXT
   ENDIF


   CREATE_INDEX( "1", "STR(doc_no,10)+STR(doc_it_no,4)+STR(it_no,4)", _alias )
   CREATE_INDEX( "2", "art_id+STR(doc_no,10)+STR(doc_it_no,4)", _alias )
   CREATE_INDEX( "3", "STR(doc_no,10)+art_id", _alias )
   AFTER_CREATE_INDEX

   _alias := "_DOC_IT2"
   _table_name := "rnal__doc_it2"

   IF_NOT_FILE_DBF_CREATE

   CREATE_INDEX( "1", "STR(doc_no,10)+STR(doc_it_no,4)+STR(it_no,4)", _alias )
   CREATE_INDEX( "2", "art_id+STR(doc_no,10)+STR(doc_it_no,4)", _alias )
   CREATE_INDEX( "3", "STR(doc_no,10)+art_id", _alias )


   aDbf := a_doc_ops()
   _alias := "DOC_OPS"
   _table_name := "rnal_doc_ops"

   IF_NOT_FILE_DBF_CREATE

   // 0.9.0
   IF ver[ "current" ] > 0 .AND. ver[ "current" ] < 00900
      FOR EACH _tbl in { _table_name }
         modstru( { "*" + _tbl, "A OP_STATUS C 1 0", "A OP_NOTES C 250 0" } )
      NEXT
   ENDIF


   CREATE_INDEX( "1", "STR(doc_no,10)+STR(doc_it_no,4)+STR(doc_op_no,4)", _alias )
   CREATE_INDEX( "2", "STR(doc_no,10)+STR(doc_it_no,4)+STR(doc_it_el_,10)", _alias )
   AFTER_CREATE_INDEX

   _alias := "_DOC_OPS"
   _table_name := "rnal__doc_ops"

   IF_NOT_FILE_DBF_CREATE

   // 0.9.0
   IF ver[ "current" ] > 0 .AND. ver[ "current" ] < 00900
      FOR EACH _tbl in { _table_name }
         modstru( { "*" + _tbl, "A OP_STATUS C 1 0", "A OP_NOTES C 250 0" } )
      NEXT
   ENDIF

   CREATE_INDEX( "1", "STR(doc_no,10)+STR(doc_it_no,4)+STR(doc_op_no,4)", _alias )
   CREATE_INDEX( "2", "STR(doc_no,10)+STR(doc_it_no,4)+STR(doc_it_el_,10)", _alias )

   _alias := "_DOC_OPST"
   _table_name := "rnal__doc_opst"

   IF_NOT_FILE_DBF_CREATE

   // 0.9.0
   IF ver[ "current" ] > 0 .AND. ver[ "current" ] < 00900
      FOR EACH _tbl in { _table_name }
         modstru( { "*" + _tbl, "A OP_STATUS C 1 0", "A OP_NOTES C 250 0" } )
      NEXT
   ENDIF

   CREATE_INDEX( "1", "STR(doc_no,10)+STR(doc_it_no,4)+STR(doc_op_no,4)", _alias )
   CREATE_INDEX( "2", "STR(doc_no,10)+STR(doc_it_no,4)+STR(doc_it_el_,10)", _alias )

   aDbf := a_articles()
   _alias := "ARTICLES"
   _table_name := "rnal_articles"

   IF_NOT_FILE_DBF_CREATE

   CREATE_INDEX( "1", "STR(art_id,10)", _alias )
   CREATE_INDEX( "2", "PADR(art_desc,100)", _alias )
   AFTER_CREATE_INDEX


   aDbf := a_elements()
   _alias := "ELEMENTS"
   _table_name := "rnal_elements"

   IF_NOT_FILE_DBF_CREATE

   CREATE_INDEX( "1", "STR(art_id,10)+STR(el_no,4)+STR(el_id,10)", _alias )
   CREATE_INDEX( "2", "STR(el_id,10)", _alias )
   AFTER_CREATE_INDEX

   aDbf := a_e_aops()
   _alias := "E_AOPS"
   _table_name := "rnal_e_aops"

   IF_NOT_FILE_DBF_CREATE

   CREATE_INDEX( "1", "STR(el_id,10)+STR(el_op_id,10)", _alias )
   CREATE_INDEX( "2", "STR(el_op_id,10)", _alias )
   AFTER_CREATE_INDEX


   aDbf := a_e_att()
   _alias := "E_ATT"
   _table_name := "rnal_e_att"

   IF_NOT_FILE_DBF_CREATE

   CREATE_INDEX( "1", "STR(el_id,10)+STR(el_att_id,10)", _alias )
   CREATE_INDEX( "2", "STR(el_att_id,10)", _alias )
   AFTER_CREATE_INDEX


   aDbf := a_e_groups()
   _alias := "E_GROUPS"
   _table_name := "rnal_e_groups"

   IF_NOT_FILE_DBF_CREATE

   CREATE_INDEX( "1", "STR(e_gr_id,10)", _alias )
   CREATE_INDEX( "2", "PADR(e_gr_desc,20)", _alias )
   AFTER_CREATE_INDEX


   aDbf := a_e_gr_att()
   _alias := "E_GR_ATT"
   _table_name := "rnal_e_gr_att"

   IF_NOT_FILE_DBF_CREATE

   CREATE_INDEX( "1", "STR(e_gr_at_id,10,0)", _alias )
   CREATE_INDEX( "2", "STR(e_gr_id,10,0)+e_gr_at_re+STR(e_gr_at_id,10)", _alias )
   AFTER_CREATE_INDEX


   aDbf := a_e_gr_val()
   _alias := "E_GR_VAL"
   _table_name := "rnal_e_gr_val"

   IF_NOT_FILE_DBF_CREATE

   CREATE_INDEX( "1", "STR(e_gr_vl_id,10,0)", _alias )
   CREATE_INDEX( "2", "STR(e_gr_at_id,10,0)+STR(e_gr_vl_id,10,0)", _alias )
   AFTER_CREATE_INDEX


   aDbf := a_customs()
   _alias := "CUSTOMS"
   _table_name := "rnal_customs"

   IF_NOT_FILE_DBF_CREATE

   CREATE_INDEX( "1", "STR(cust_id,10)", _alias )
   AFTER_CREATE_INDEX


   aDbf := a_contacts()
   _alias := "CONTACTS"
   _table_name := "rnal_contacts"

   IF_NOT_FILE_DBF_CREATE

   CREATE_INDEX( "1", "STR(cont_id,10)", _alias )
   CREATE_INDEX( "2", "STR(cust_id,10)+STR(cont_id,10)", _alias )
   CREATE_INDEX( "3", "STR(cust_id,10)+cont_desc", _alias )
   CREATE_INDEX( "4", "cont_desc", _alias )
   AFTER_CREATE_INDEX

   aDbf := a_objects()
   _alias := "OBJECTS"
   _table_name := "rnal_objects"

   IF_NOT_FILE_DBF_CREATE

   CREATE_INDEX( "1", "STR(obj_id,10)", _alias )
   CREATE_INDEX( "2", "STR(cust_id,10)+STR(obj_id,10)", _alias )
   CREATE_INDEX( "3", "STR(cust_id,10)+obj_desc", _alias )
   CREATE_INDEX( "4", "obj_desc", _alias )
   AFTER_CREATE_INDEX


   aDbf := a_aops()
   _alias := "AOPS"
   _table_name := "rnal_aops"

   IF_NOT_FILE_DBF_CREATE

   CREATE_INDEX( "1", "STR(aop_id,10)", _alias )
   AFTER_CREATE_INDEX


   aDbf := a_aops_att()
   _alias := "AOPS_ATT"
   _table_name := "rnal_aops_att"

   IF_NOT_FILE_DBF_CREATE

   CREATE_INDEX( "1", "STR(aop_att_id,10)", _alias )
   CREATE_INDEX( "2", "STR(aop_id,10)+STR(aop_att_id,10)", _alias )
   AFTER_CREATE_INDEX

/*
   aDbf := a_ral()
   _alias := "RAL"
   _table_name := "rnal_ral"

   IF_NOT_FILE_DBF_CREATE

   CREATE_INDEX( "1", "STR(id,5)+STR(gl_tick,2)", _alias )
   CREATE_INDEX( "2", "descr", _alias )
   AFTER_CREATE_INDEX
*/

   cre_relacije_fakt( ver )

   RETURN .T.




FUNCTION rnal_a_ral()

   LOCAL aDbf := {}

   AAdd( aDbf, { "id", "N", 5, 0 } )
   AAdd( aDbf, { "gl_tick", "N", 2, 0 } )
   AAdd( aDbf, { "descr", "C", 50, 0 } )
   AAdd( aDbf, { "en_desc", "C", 50, 0 } )
   AAdd( aDbf, { "col_1", "N", 8, 0 } )
   AAdd( aDbf, { "col_2", "N", 8, 0 } )
   AAdd( aDbf, { "col_3", "N", 8, 0 } )
   AAdd( aDbf, { "col_4", "N", 8, 0 } )
   AAdd( aDbf, { "colp_1", "N", 12, 5 } )
   AAdd( aDbf, { "colp_2", "N", 12, 5 } )
   AAdd( aDbf, { "colp_3", "N", 12, 5 } )
   AAdd( aDbf, { "colp_4", "N", 12, 5 } )

   RETURN aDbf


STATIC FUNCTION a_docs()

   LOCAL aDbf

   aDbf := {}
   AAdd( aDBf, { "doc_no", "N", 10, 0 } )
   AAdd( aDBf, { "doc_date", "D", 8, 0 } )
   AAdd( aDBf, { "doc_time", "C", 8, 0 } )
   AAdd( aDBf, { "doc_dvr_da", "D", 8, 0 } )
   AAdd( aDBf, { "doc_dvr_ti", "C", 8,  0 } )
   AAdd( aDBf, { "doc_ship_p", "C", 200, 0 } )
   AAdd( aDBf, { "cust_id", "N", 10, 0 } )
   AAdd( aDBf, { "cont_id", "N", 10, 0 } )
   AAdd( aDBf, { "obj_id", "N", 10, 0 } )
   AAdd( aDBf, { "cont_add_d", "C", 200, 0 } )
   AAdd( aDBf, { "doc_pay_id", "N", 4, 0 } )
   AAdd( aDBf, { "doc_paid", "C", 1, 0 } )
   AAdd( aDBf, { "doc_pay_de", "C", 100, 0 } )
   AAdd( aDBf, { "doc_priori", "N", 4, 0 } )
   AAdd( aDBf, { "doc_desc", "C", 200, 0 } )
   AAdd( aDBf, { "doc_sh_des", "C", 100, 0 } )
   AAdd( aDBf, { "doc_status", "N", 2, 0 } )
   AAdd( aDBf, { "doc_type", "C", 2, 0 } )
   AAdd( aDBf, { "operater_i", "N", 10, 0 } )
   AAdd( aDBf, { "doc_in_fmk", "N", 1, 0 } )
   AAdd( aDBf, { "fmk_doc", "C", 150, 0 } )
   AAdd( aDBf, { "doc_llog", "N", 10, 0 } )

   RETURN aDbf



STATIC FUNCTION a_doc_it()

   LOCAL aDbf

   aDbf := {}
   AAdd( aDBf, { "doc_no", "N", 10, 0 } )
   AAdd( aDBf, { "doc_it_no", "N", 4, 0 } )
   AAdd( aDBf, { "art_id", "N", 10, 0 } )
   AAdd( aDBf, { "doc_it_wid", "N", 15,  5 } )
   AAdd( aDBf, { "doc_it_hei", "N", 15,  5 } )
   AAdd( aDBf, { "doc_it_qtt",  "N", 15,  5 } )
   AAdd( aDBf, { "doc_it_alt",  "N", 15,  5 } )
   AAdd( aDBf, { "doc_acity",  "C", 50,  5 } )
   AAdd( aDBf, { "doc_it_sch",  "C", 1,  0 } )
   AAdd( aDBf, { "doc_it_des",  "C", 150,  0 } )
   AAdd( aDBf, { "doc_it_typ",  "C", 1,  0 } )
   AAdd( aDBf, { "doc_it_w2", "N", 15,  5 } )
   AAdd( aDBf, { "doc_it_h2", "N", 15,  5 } )
   AAdd( aDBf, { "doc_it_pos", "C", 20,  0 } )
   AAdd( aDBf, { "it_lab_pos", "C", 1,  0 } )

   RETURN aDbf


// ----------------------------------------------
// vraca matricu sa strukturom tabele DOC_IT2
// aDBF := {...}
// ----------------------------------------------
STATIC FUNCTION a_doc_it2()

   LOCAL aDbf

   aDbf := {}
   AAdd( aDBf, { "doc_no", "N", 10, 0 } )
   AAdd( aDBf, { "doc_it_no", "N", 4, 0 } )
   AAdd( aDBf, { "it_no", "N", 4, 0 } )
   AAdd( aDBf, { "art_id", "C", 10, 0 } )
   AAdd( aDBf, { "doc_it_qtt",  "N", 15,  5 } )
   AAdd( aDBf, { "doc_it_q2",  "N", 15,  5 } )
   AAdd( aDBf, { "doc_it_pri", "N", 15,  5 } )
   AAdd( aDBf, { "jmj", "C", 3,  0 } )
   AAdd( aDBf, { "jmj_art", "C", 3,  0 } )
   AAdd( aDBf, { "sh_desc", "C", 100,  0 } )
   AAdd( aDBf, { "descr", "C", 200,  0 } )

   RETURN aDbf


STATIC FUNCTION a_doc_ops()

   LOCAL aDbf

   aDbf := {}
   AAdd( aDBf, { "doc_no", "N", 10, 0 } )
   AAdd( aDBf, { "doc_it_no", "N", 4, 0 } )
   AAdd( aDBf, { "doc_it_el_", "N", 10, 0 } )
   AAdd( aDBf, { "doc_op_no", "N", 4, 0 } )
   AAdd( aDBf, { "aop_id", "N", 10,  0 } )
   AAdd( aDBf, { "aop_att_id", "N", 10,  0 } )
   AAdd( aDBf, { "aop_value", "C", 150,  0 } )
   AAdd( aDBf, { "doc_op_des", "C", 150,  0 } )
   AAdd( aDBf, { "op_status", "C", 1,  0 } )
   AAdd( aDBf, { "op_notes", "C", 250,  0 } )

   RETURN aDbf


STATIC FUNCTION a_articles()

   LOCAL aDbf

   aDbf := {}
   AAdd( aDBf, { "art_id", "N", 10, 0 } )
   AAdd( aDBf, { "art_desc", "C", 100, 0 } )
   AAdd( aDBf, { "art_full_d", "C", 250, 0 } )
   AAdd( aDBf, { "art_lab_de", "C", 200, 0 } )
   AAdd( aDBf, { "match_code", "C", 10, 0 } )

   RETURN aDbf


STATIC FUNCTION a_elements()

   LOCAL aDbf

   aDbf := {}
   AAdd( aDBf, { "el_id", "N", 10, 0 } )
   AAdd( aDBf, { "el_no", "N", 4, 0 } )
   AAdd( aDBf, { "art_id", "N", 10, 0 } )
   AAdd( aDBf, { "e_gr_id", "N", 10, 0 } )

   RETURN aDbf



STATIC FUNCTION a_e_att()

   LOCAL aDbf

   aDbf := {}
   AAdd( aDBf, { "el_att_id", "N", 10, 0 } )
   AAdd( aDBf, { "el_id", "N", 10, 0 } )
   AAdd( aDBf, { "e_gr_at_id", "N", 10, 0 } )
   AAdd( aDBf, { "e_gr_vl_id", "N", 10, 0 } )

   RETURN aDbf



STATIC FUNCTION a_e_aops()

   LOCAL aDbf

   aDbf := {}
   AAdd( aDBf, { "el_op_id", "N", 10, 0 } )
   AAdd( aDBf, { "el_id", "N", 10, 0 } )
   AAdd( aDBf, { "aop_id", "N", 10, 0 } )
   AAdd( aDBf, { "aop_att_id", "N", 10, 0 } )

   RETURN aDbf


STATIC FUNCTION a_e_groups()

   LOCAL aDbf

   aDbf := {}
   AAdd( aDBf, { "e_gr_id", "N", 10, 0 } )
   AAdd( aDBf, { "e_gr_desc", "C", 100, 0 } )
   AAdd( aDBf, { "e_gr_full_", "C", 100, 0 } )
   AAdd( aDBf, { "match_code", "C", 10, 0 } )

   RETURN aDbf



STATIC FUNCTION a_e_gr_att()

   LOCAL aDbf

   aDbf := {}
   AAdd( aDBf, { "e_gr_at_id", "N", 10, 0 } )
   AAdd( aDBf, { "e_gr_id", "N", 10, 0 } )
   AAdd( aDBf, { "e_gr_at_de", "C", 100, 0 } )
   AAdd( aDBf, { "e_gr_at_re", "C", 1, 0 } )
   AAdd( aDBf, { "in_art_des", "C", 1, 0 } )
   AAdd( aDBf, { "e_gr_at_jo", "C", 20, 0 } )
   AAdd( aDBf, { "match_code", "C", 10, 0 } )

   RETURN aDbf



STATIC FUNCTION a_e_gr_val()

   LOCAL aDbf

   aDbf := {}
   AAdd( aDBf, { "e_gr_vl_id", "N", 10, 0 } )
   AAdd( aDBf, { "e_gr_at_id", "N", 10, 0 } )
   AAdd( aDBf, { "e_gr_vl_de", "C", 100, 0 } )
   AAdd( aDBf, { "e_gr_vl_fu", "C", 100, 0 } )
   AAdd( aDBf, { "match_code", "C", 10, 0 } )

   RETURN aDbf


STATIC FUNCTION a_aops()

   LOCAL aDbf

   aDbf := {}
   AAdd( aDBf, { "aop_id", "N", 10, 0 } )
   AAdd( aDBf, { "aop_desc", "C", 100, 0 } )
   AAdd( aDBf, { "aop_full_d", "C", 100, 0 } )
   AAdd( aDBf, { "in_art_des", "C", 1, 0 } )
   AAdd( aDBf, { "aop_joker", "C", 20, 0 } )
   AAdd( aDBf, { "aop_unit", "C", 10, 0 } )
   AAdd( aDBf, { "match_code", "C", 10, 0 } )

   RETURN aDbf


STATIC FUNCTION a_aops_att()

   LOCAL aDbf

   aDbf := {}
   AAdd( aDBf, { "aop_att_id", "N", 10, 0 } )
   AAdd( aDBf, { "aop_id", "N", 10, 0 } )
   AAdd( aDBf, { "aop_att_de", "C", 100, 0 } )
   AAdd( aDBf, { "aop_att_fu", "C", 100, 0 } )
   AAdd( aDBf, { "in_art_des", "C", 1, 0 } )
   AAdd( aDBf, { "aop_att_jo", "C", 20, 0 } )
   AAdd( aDBf, { "match_code", "C", 10, 0 } )

   RETURN aDbf


STATIC FUNCTION a_customs()

   LOCAL aDbf

   aDbf := {}
   AAdd( aDBf, { "cust_id", "N", 10, 0 } )
   AAdd( aDBf, { "cust_desc", "C", 250, 0 } )
   AAdd( aDBf, { "cust_addr", "C", 50, 0 } )
   AAdd( aDBf, { "cust_tel", "C", 100, 0 } )
   AAdd( aDBf, { "cust_ident", "C", 13, 0 } )
   AAdd( aDBf, { "match_code", "C", 10, 0 } )

   RETURN aDbf


STATIC FUNCTION a_contacts()

   LOCAL aDbf

   aDbf := {}
   AAdd( aDBf, { "cont_id", "N", 10, 0 } )
   AAdd( aDBf, { "cust_id", "N", 10, 0 } )
   AAdd( aDBf, { "cont_desc", "C", 150, 0 } )
   AAdd( aDBf, { "cont_tel", "C", 100, 0 } )
   AAdd( aDBf, { "cont_add_d", "C", 250, 0 } )
   AAdd( aDBf, { "match_code", "C", 10, 0 } )

   RETURN aDbf


STATIC FUNCTION a_objects()

   LOCAL aDbf

   aDbf := {}
   AAdd( aDBf, { "obj_id", "N", 10, 0 } )
   AAdd( aDBf, { "cust_id", "N", 10, 0 } )
   AAdd( aDBf, { "obj_desc", "C", 150, 0 } )
   AAdd( aDBf, { "match_code", "C", 10, 0 } )

   RETURN aDbf
