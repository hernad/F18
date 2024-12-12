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


#xcommand O_PKONTO   => select (F_PKONTO); use_sql_pkonto()  ; set order to tag "ID"
#xcommand O_KS       => select (F_KS);     use_sql_ks() ; set order to tag "ID"


//#xcommand O__ROBA    => select (F__ROBA)   ;  my_usex("cIdRoba")
//#xcommand O__PARTN   => select (F__PARTN)  ;  my_use  ("_partn")


#xcommand O_VOZILA   => SELECT (F_VOZILA)  ;  my_use  ("vozila")    ; set order to tag "ID"

#xcommand O_RELATION => SELECT (F_RELATION);  my_use ("relation")  ; set order to tag "1"
#xcommand O_FINMAT   => select (F_FINMAT)  ;  my_use ("finmat")    ; set order to tag "1"
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
#xcommand O_KALK_ATTR     => select (F_KALK_ATTR) ; my_use ("kalk_attr") ; set order to tag  "1"

#xcommand O__SDIM          => select(F__SDIM)      ; my_use ("_sdim"); set order to tag "1"


#xcommand O_POMGN          => select (F_POMGN)     ; my_use  ("pomgn"); set order to tag "4"
#xcommand O_POM            => select (F_POM)       ; my_usex ("pom")
#xcommand O_SDIM           => select (F_SDIM)      ; my_use  ("sdim"); set order to tag "1"

#xcommand O_CROBA          => SELECT (F_CROBA)     ; my_use  ("croba"); set order to tag "IDROBA"

#xcommand O_FADO           => select (F_FADO)      ; my_use  ("fado")    ; set order to tag "ID"
#xcommand O_FADE           => select (F_FADE)      ; my_use  ("fade")    ; set order to tag "ID"


#xcommand O_UPL            => select (F_UPL)       ; my_usex  ("upl")      ; set order to tag "1"

#xcommand O_DOKSTXT        => select (F_DOKSTXT)   ; my_use  ("dokstxt") ; set order to tag "ID"


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

#xcommand O__RADN   => select (F__RADN)   ;  my_use ("_radn")






//#xcommand O_PK_RADN => select (F_PK_RADN)  ; my_use ("pk_radn")   ; set order to tag "1"
//#xcommand O_PK_DATA => select (F_PK_DATA)  ; my_use ("pk_data")   ; set order to tag "1"



// modul OS
//#xcommand O_INVENT       => select (F_INVENT)  ; my_use ("invent") ; set order to tag "1"


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
