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



//#xcommand O_TRFP3    => select (F_TRFP3)   ;  use_sql_sif  ("trfp3")     ; set order to tag "ID"
#xcommand O_TRMP     => select (F_TRMP)    ;  use_sql_sif  ("trmp")      ; set order to tag "ID"


#xcommand o_vrstep()   => o_vrste_placanja()
#xcommand O_PKONTO   => select (F_PKONTO); use_sql_pkonto()  ; set order to tag "ID"
#xcommand O_KS       => select (F_KS);     use_sql_ks() ; set order to tag "ID"


#xcommand O_VOZILA   => SELECT (F_VOZILA)  ;  my_use  ("vozila")    ; set order to tag "ID"

#xcommand O_RELATION => SELECT (F_RELATION);  my_use ("relation")  ; set order to tag "1"

//#xcommand O_ULIMIT   => o_ulimit()
#xcommand O_TIPBL    => SELECT (F_TIPBL)   ;  my_use ("tipbl")      ; set order to tag "1"



// grupe i karakteristike
// #xcommand O_STRINGS  => select(F_STRINGS)  ;  my_use ("strings")   ; set order to tag "1"

// temp tabela za izvjestaje

#xcommand O_TEMP     => select (F_TEMP)    ; my_usex ("temp")


// fmk rules
#xcommand O_RULES  => select (F_RULES); use_sql_rules() ; set order to tag "2"

/*
// tabele DOK_SRC
--#xcommand O_DOKSRC    => SELECT (F_DOKSRC)  ; my_use ("doksrc")    ; set order to tag "1"
--#xcommand O_P_DOKSRC  => SELECT (F_P_DOKSRC); my_usex ("p_doksrc")  ; set order to tag "1"
*/

// stampa PDV racuna
#xcommand O_DRN       => select(F_DRN)      ; my_use ("drn")      ; set order to tag "1"
#xcommand O_RN        => select(F_RN)       ; my_use ("rn")       ; set order to tag "1"
#xcommand O_DRNTEXT   => select(F_DRNTEXT)  ; my_use ("drntext")  ; set order to tag "1"

// tabele provjere integriteta
//#xcommand O_DINTEG1 => SELECT (F_DINTEG1)   ; my_usex ("dinteg1")  ; set order to tag "1"
//#xcommand O_DINTEG2 => SELECT (F_DINTEG2)   ; my_usex ("dinteg2")  ; set order to tag "1"
//#xcommand O_INTEG1  => SELECT (F_INTEG1)    ; my_usex ("integ1")   ; set order to tag "1"
//#xcommand O_INTEG2  => SELECT (F_INTEG2)    ; my_usex ("integ2")   ; set order to tag "1"
//#xcommand O_ERRORS  => SELECT (F_ERRORS)    ; my_usex ("errors")   ; set order to tag "1"

// modul FIN


#xcommand O_KOMP_DUG    => select (F_FIN_KOMP_DUG);  my_use ("komp_dug")
#xcommand O_KOMP_POT    => select (F_FIN_KOMP_POT);  my_use ("komp_pot")




// modul KALK
#xcommand O_KALK_S_PRIPR  => select(F_KALK_PRIPR); my_usex ( "kalk_pripr") ; set order to tag "1"


#xcommand O__KALK         => select(F__KALK); my_usex ("_kalk" )
#xcommand O_KALK_FINMAT   => select(F_KALK_FINMAT); my_usex ("kalk_finmat")    ; set order to tag "1"


//#xcommand O_KALKX         => select(F_KALK);  usex  (KUMPATH +"kalk")  ; set order to tag "1"


//#xcommand XO_KALK         => select (F_FAKT);  my_use ("kalk2", "kalk_kalk" ) ; set order to tag "1"

#xcommand O_PORMP          => select(F_PORMP); usex ("pormp")     ; set order to tag "1"
#xcommand O_PRODNC         => select(F_PRODNC);  my_use  ("prodnc")  ; set order to tag "PRODROBA"
#xcommand O_RVRSTA         => select(F_RVRSTA);  my_use  ("rvrsta")  ; set order to tag "ID"

#xcommand O_REKAP2         => select(F_REKAP2)   ;  my_use  ("rekap2")   ; set order to tag "1"
#xcommand O_REKA22         => select(F_REKA22)   ;  my_use  ("reka22")   ; set order to tag "1"
#xcommand O_R_UIO          => select(F_R_UIO)    ;  my_use  ("r_uio")
#xcommand O_RPT_TMP        => select(F_RPT_TMP)  ;  my_use  ("rpt_tmp")





// fakt pripr

#xcommand O_FAKT_PRIPRRP   => select (F_FAKT_PRIPR)     ; my_use ("fakt_pripr")   ; set order to tag  "1"

// fakt tmp
#xcommand O__FAKT          => select(F__FAKT)      ; my_use ("_fakt")
#xcommand O_FAKT_PRIPR9    => select (F_FAKT_PRIPR9)    ; my_use  ("fakt_pripr9") ; set order to tag  "1"
#xcommand O_FAKT_ATTR     => select (F_FAKT_ATTR) ; my_use ("fakt_attr") ; set order to tag  "1"

#xcommand O__SDIM          => select(F__SDIM)      ; my_use ("_sdim"); set order to tag "1"


#xcommand O_POMGN          => select (F_POMGN)     ; my_use  ("pomgn"); set order to tag "4"
#xcommand O_POM            => select (F_POM)       ; my_usex ("pom")
#xcommand O_SDIM           => select (F_SDIM)      ; my_use  ("sdim"); set order to tag "1"
//#xcommand O_KALPOS         => SELECT (F_KALPOS)    ; my_use  ("kalpos"); set order to tag "1"
#xcommand O_CROBA          => SELECT (F_CROBA)     ; my_use  ("croba"); set order to tag "IDROBA"

#xcommand O_FADO           => select (F_FADO)      ; my_use  ("fado")    ; set order to tag "ID"
#xcommand O_FADE           => select (F_FADE)      ; my_use  ("fade")    ; set order to tag "ID"


#xcommand O_UPL            => select (F_UPL)       ; my_usex  ("upl")      ; set order to tag "1"

#xcommand O_DOKSTXT        => select (F_DOKSTXT)   ; my_use  ("dokstxt") ; set order to tag "ID"

// modul RNAL
#xcommand O__DOCS => select (F__DOCS); my_use ("_docs"); set order to tag "1"
#xcommand O__DOC_IT => select (F__DOC_IT); my_use ("_doc_it"); set order to tag "1"
#xcommand O__DOC_IT2 => select (F__DOC_IT2); my_use ("_doc_it2"); set order to tag "1"
#xcommand O__DOC_OPS => select (F__DOC_OPS); my_use ("_doc_ops"); set order to tag "1"
#xcommand O__DOC_OPST => select (F__DOC_OPST); my_use ("_doc_opst"); set order to tag "1"
#xcommand O_T_DOCIT => select (F_T_DOCIT); my_use ("t_docit"); set order to tag "1"
#xcommand O_T_DOCIT2 => select (F_T_DOCIT2); my_use ("t_docit2"); set order to tag "1"
#xcommand O_T_DOCOP => select (F_T_DOCOP); my_use ("t_docop"); set order to tag "1"
#xcommand O_T_PARS => my_use ("t_pars"); set order to tag "id_par"
#xcommand O__TMP1 => select (F__TMP1); my_use ("_tmp1"); set order to tag "1"
#xcommand O__TMP2 => select (F__TMP2); my_use ("_tmp2"); set order to tag "1"

#xcommand O_DOCS => select (F_DOCS); my_use ("docs"); set order to tag "1"
#xcommand O_DOC_IT => select (F_DOC_IT); my_use ("doc_it"); set order to tag "1"
#xcommand O_DOC_IT2 => select (F_DOC_IT2); my_use ("doc_it2"); set order to tag "1"
#xcommand O_DOC_OPS => select (F_DOC_OPS); my_use ("doc_ops"); set order to tag "1"
#xcommand O_E_GROUPS => select_o_dbf_e_groups()
#xcommand O_CUSTOMS => select(F_CUSTOMS); my_use ("customs"); set order to tag "1"
#xcommand O_OBJECTS => select(F_OBJECTS); my_use ("objects"); set order to tag "1"
#xcommand O_CONTACTS => select(F_CONTACTS); my_use ("contacts"); set order to tag "1"

#xcommand O_E_GR_ATT => select_o_dbf_e_gr_att()
#xcommand O_E_GR_VAL => select_o_dbf_e_gr_val()
#xcommand O_AOPS => select_o_dbf_aops()
#xcommand O_AOPS_ATT => select_o_dbf_aops_att()
#xcommand O_ARTICLES => select_o_dbf_articles()
#xcommand O_ELEMENTS => select_o_dbf_elements()
#xcommand O_E_AOPS => select_o_dbf_e_aops()
#xcommand O_E_ATT => select_o_dbf_e_att()
#xcommand O_RAL => use_sql_rnal_ral()


#xcommand O__RADN   => select (F__RADN)   ;  my_use ("_radn")


#xcommand O_RADKRX  => select (F_RADKR)   ;  my_use ("radkr")    ; set order to tag "0"
#xcommand O__RADKR  => select (F__RADKR)  ;  my_use ("_radkr")

//#xcommand O_LDX     => select (F_LD)      ;  my_use ("ld")       ; set order to tag "1"

#xcommand O_LDSM    => select (F_LDSM)    ;  my_use ("ldsm")     ; set order to tag "1"
#xcommand O_LDSMX   => select (F_LDSM)    ;  my_use ("ldsm")     ; set order to tag "0"
#xcommand O_OPSLD   => select (F_OPSLD)   ;  my_usex ("opsld")    ; set order to tag "1"
#xcommand O_REKLD0  => select (F_REKLD)   ;  my_usex ("rekld")

#xcommand O_REKLDP  => select (F_REKLDP)  ;  my_usex ("rekldp")  ; set order to tag "1"


#xcommand O__KRED   => select (F__KRED)   ;  my_use ("_kred")    ; set order to tag "ID"



//#xcommand O_PK_RADN => select (F_PK_RADN)  ; my_use ("pk_radn")   ; set order to tag "1"
//#xcommand O_PK_DATA => select (F_PK_DATA)  ; my_use ("pk_data")   ; set order to tag "1"

#xcommand O_LDT22 => select (F_LDT22)  ; my_use ("LDT22")        ; set order to tag "1"



// modul OS
//#xcommand O_INVENT       => select (F_INVENT)  ; my_use ("invent") ; set order to tag "1"



// modul POS


#xcommand O__POS_DOKSP  => select(F__DOKSP) ; my_use("_pos_doksp")

#xcommand O_STRAD     => o_pos_strad()


// modul MAT
#xcommand O_MAT_PRIPR    =>  select(F_MAT_PRIPR); my_use("mat_pripr") ; set order to tag "1"
#xcommand O_MAT_PRIPRRP  =>  select(F_MAT_PRIPR); my_use("mat_priprrp", "mat_pripr"); set order to tag "1"
#xcommand O_MAT_SUBAN    =>  select(F_MAT_SUBAN); my_use( "mat_suban" ); set order to tag "1"
#xcommand O_MAT_SUBANX   =>  select(F_MAT_SUBAN); my_use( "mat_suban" ); set order to tag "1"
#xcommand O_MAT_SUBAN2   =>  select(F_MAT_SUBAN); my_use( "mat_pripr", "mat_suban" ); set order to tag "4"
#xcommand O_MAT_ANAL     =>  select(F_MAT_ANAL); my_use( "mat_anal" ); set order to tag "1"
#xcommand O_MAT_SINT     =>  select(F_MAT_SINT); my_use( "mat_sint" ); set order to tag "1"
#xcommand O_MAT_NALOG    =>  select(F_MAT_NALOG); my_use( "mat_nalog" ); set order to tag "1"
#xcommand O_IZDEF        =>  select(F_IZDEF); my_use ( "izdef" ); set order to tag "1"
#xcommand O_IZOP         =>  select(F_IZOP ); my_use ( "izop" ); set order to tag "1"
#xcommand O_MAT_PNALOG   =>  select(F_MAT_PNALOG); my_use( "mat_pnalog" ); set order to tag "1"
#xcommand O_MAT_PSUBAN   =>  select(F_MAT_PSUBAN); my_use( "mat_psuban" ); set order to tag "1"
#xcommand O_MAT_PSUBAN2  =>  select(F_MAT_PSUBAN); my_use( "mat_suban", "mat_psuban" ); set order to tag "1"
#xcommand O_MAT_PANAL    =>  select(F_MAT_PANAL) ; my_use( "mat_panal") ; set order to tag "1"
#xcommand O_MAT_PANAL2   =>  select(F_MAT_PANAL) ; my_use( "mat_anal", "mat_panal"); set order to tag "1"
#xcommand O_MAT_PSINT    =>  select(F_MAT_PSINT) ; my_use( "mat_psint" ) ; set order to tag "1"
#xcommand O_MAT_INVENT   =>  select(F_MAT_INVENT); my_use( "mat_invent" ); set order to tag "1"
#xcommand O_KARKON       =>  select(F_KARKON); my_use ( "karkon" ); set order to tag "ID"

// modul VIRM
#xcommand O_VIRM_PRIPR   => select (F_VIPRIPR); my_use("virm_pripr") ; set order to tag "1"


//#xcommand O_KALVIR   => select (F_KALVIR) ; my_use ("kalvir") ; set order to tag "ID"
#xcommand O_IZLAZ   => select (F_IZLAZ) ; my_use ("izlaz") ; set order to tag "1"


// --------------------------------------------------------------------------------------
// legacy - izbaciti donje tabele
// --------------------------------------------------------------------------------------
//#xcommand O_ADRES     => select (F_ADRES)     ; my_use ( "adres" )  ; set order to tag "ID"

// proizvoljni izvjestaji
//#xcommand O_KONIZ  => select (F_KONIZ) ; my_use("koniz") ; set order to tag "ID"
//#xcommand O_IZVJE  => select (F_IZVJE) ; my_use("izvje") ; set order to tag "ID"
//#xcommand O_ZAGLI  => select (F_ZAGLI) ; my_use("zagli") ; set order to tag "ID"
//#xcommand O_KOLIZ  => select (F_KOLIZ) ; my_use("koliz") ; set order to tag "ID"



//#xcommand O_GPARAMSP  => select (F_GPARAMSP)  ; my_use ( "gparams" )  ; set order to tag  "ID"
//#xcommand O_MPARAMS   => select (F_MPARAMS)   ;  my_use ( "mparams" ) ; set order  to tag  "ID"
//#xcommand O_KPARAMS   => select (F_KPARAMS)   ; my_use ( "kparams" )  ; set order to tag  "ID"

//#xcommand O_SECUR     => select (F_SECUR)     ; my_use ( "secur" )    ; set order to tag "ID"

//#xcommand O_LOGK     => select (F_LOGK)    ; my_use  ("logk")          ; set order to tag "NO"
//#xcommand O_LOGKD    => select (F_LOGKD); my_use  ("logd")        ; set order to tag "NO"

// security system tabele
//#xcommand O_EVENTS  => select (F_EVENTS); my_use ("events") ; set order to tag "ID"
//#xcommand O_USERS  => select (F_USERS); my_use ("users") ; set order to tag "ID"
//#xcommand O_GROUPS  => select (F_GROUPS); my_use ("groups") ; set order to tag "ID"


#xcommand O_FIN_PRIPRRP   => select (F_FIN_PRIPR); my_usex("fin_priprrp", "fin_pripr"); set order to tag "1"

//#xcommand O_KALKSEZ        => select(F_KALK);  my_use  ("kalk")  ; set order to tag "1"
//#xcommand O_ROBASEZ        => select(F_ROBA);  my_use  ("roba")  ; set order to tag "ID"
