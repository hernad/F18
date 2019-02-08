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

#define F18_F18_DEFINED
#define FMK_DEFINED
#define F18_DEFINED

#include "inkey.ch"
#include "getexit.ch"
#include "box.ch"
#include "dbedit.ch"
#include "achoice.ch"

#include "hbclass.ch"
#include "fileio.ch"

#require "rddsql.ch"
#require "sddpg.ch"

#include "dbinfo.ch"
#include "error.ch"
#include "fileio.ch"
#include "hbclass.ch"


#include "set.ch"
#include "hbgtinfo.ch"
#include "common.ch"
#include "dbstruct.ch"
#include "setcurs.ch"
#include "dbedit.ch"

#include "hbthread.ch"

#include "o_f18.ch"
#include "f_f18.ch"
#include "f18_separator.ch"
#include "f18_rabat.ch"
#include "f18_request.ch"
#include "f18_cre_all.ch"

#include "pdf_cls.ch"

#include "memoedit.ch"


#define F18_DEFAULT_LOG_LEVEL_DEBUG 9
#define F18_DEFAULT_LOG_LEVEL       3

#define INFO_BAR_ROWS               2


#define D_ZELITE_LI_IZBRISATI_PRIPREMU "Želite li izbrisati pripremu !?"

#define F18_DBF_ENCODING   "CP852"
#define F18_SQL_ENCODING   "CP852"

#define MAX_THREAD_COUNT 7
#define MIN_LAST_REFRESH_SEC 10


#define F18_UTIL_VER  "1.0.0"
#define F18_UTIL_URL_BASE "https://github.com/hernad/F18_util/releases/download/"
#define F18_DOWNLOAD_URL_BASE "http://download.bring.out.ba/"
#define F18_GITHUB_DOWNLOAD_BASE_URL "https://raw.github.com/knowhow/F18_knowhow/"


#define INFO_MESSAGES_LENGTH       40
#define ERROR_MESSAGES_LENGTH      40

#define F18_PSQL_SCHEMA            "fmk"
#define F18_PSQL_SCHEMA_DOT        "fmk."

#define F18_PSQL_KNJIGOVODSTVO_SCHEMA   "fmk"



#xcommand LOG_CALL_STACK <cLogStr>                 ;
  => FOR nI := 1 TO 30                             ;
    ;  IF !Empty( ProcName( nI ) )                 ;
    ;   cMsg := Str( nI, 3 ) + " " + ProcName( nI ) + " / " + AllTrim( Str( ProcLine( nI ), 6 ) ) ;                       ;
    ;   <cLogStr> := <cLogStr> + " // " + cMsg    ;
    ;  END                                        ;
    ; NEXT

#define FIELD_LEN_FAKT_BRDOK    8

#define FIELD_LEN_KALK_BRDOK    8
#define FIELD_LEN_KALK_RBR      3
#define FIELD_ROBA_ID_LENGTH 10

#define FIELD_LEN_POS_BRDOK  8
#define POS_BRDOK_PRIPREMA   "PRIPREMA"

#define FIELD_LEN_POS_RBR    3
#define FIELD_LEN_PARTNER_ID 6

#define FIELD_LEN_KONTO_ID 7

#define FIELD_LEN_SIFK_ID 8
#define FIELD_LEN_SIFK_NAZ 25
#define FIELD_LEN_SIFK_OZNAKA  4
#define FIELD_LEN_SIFK_IDSIF   15

#define FIELD_LEN_RJ_ID 7  // sifarnik radnih jedinica id c(7)
#define FIELD_LEN_FIN_RJ_ID 6 // fin_suban.idrj c(6)
#define FIELD_LEN_FAKT_RJ_ID 2 // fakt_fakt.idfirma, unutar aplikacije se koristi kao RJ c(2)

#ifndef TEST
  #ifndef F18_RELEASE_DEFINED
      #include "f18_release.ch"
  #endif
#else
  #ifndef F18_TEST_DEFINED
      #include "f18_test.ch"
  #endif
#endif

#define CHR254   254
//#define D_STAROST_DANA   25

#define LEN_IDRADNIK 6
#define BOX_CHAR_BACKGROUND hb_UTF8ToStrBox( "░" )
#define BOX_CHAR_BACKGROUND_HEAD " "

#define oF_ERROR_MIN          1
#define oF_CREATE_OBJECT      1
#define oF_OPEN_FILE          2
#define oF_READ_FILE          3
#define oF_CLOSE_FILE         4
#define oF_ERROR_MAX          4
#define oF_DEFAULT_READ_SIZE  4096


#define K_UNDO          K_CTRL_U
// format of array used to preserve state variables
#define GSV_KILLREAD  1
#define GSV_BUMPTOP  2
#define GSV_BUMPBOT  3
#define GSV_LASTEXIT  4
#define GSV_LASTPOS  5
#define GSV_ACTIVEGET  6
#define GSV_READVAR   7
#define GSV_READPROCNAME 8
#define GSV_READPROCLINE 9

#define GSV_COUNT  9



// CDX
#define CDX_INDICES
#undef NTX_INDICES
#define INDEXEXT      "cdx"
#define OLD_INDEXEXT  "ntx"
#define DBFEXT        "dbf"
#define MEMOEXT       "fpt"

#define  INDEXEXTENS  "cdx"
#define  MEMOEXTENS   "fpt"

#define RDDENGINE "DBFCDX"
#define DBFENGINE "DBFCDX"
// CDX end



#define SEMAPHORE_LOCK_RETRY_IDLE_TIME 1
#define SEMAPHORE_LOCK_RETRY_NUM 100
#define SEMAPHORE_LOCK_TIME 10



#define RPT_PAGE_LEN fetch_metric( "rpt_duzina_stranice", my_user(), 60 )

#define F18_CLIENT_ID_INI_SECTION "client_id"
#define F18_SCREEN_INI_SECTION "F18_screen"
#define F18_DBF_INI_SECTION "F18_dbf"

#define F18_SECUR_WARRNING "Opcija nije dostupna za ovaj nivo !#Da bi koristili opciju potrebna podesenja privilegija"


// F18.log, F18_2.log, F18_3.log ...
#define F18_LOG_FILE "F18.log"
#define OUTF_FILE "outf.txt"
#define OUT_ODT_FILE "out.odt"
#define DATA_XML_FILE "data.xml"

#command QUIT_1                    => ErrorLevel(1); my_server_close() ; __Quit()

#command @ <row>, <col> SAY8 <exp> [PICTURE <pic>] [COLOR <clr>] => ;
         DevPos( <row>, <col> ) ; DevOutPict( hb_utf8toStr( <exp> ), <pic> [, <clr>] )
#command @ <row>, <col> SAY8 <exp> [COLOR <clr>] => ;
         DevPos( <row>, <col> ) ; DevOut( hb_utf8toStr( <exp> ) [, <clr>] )

#command @ <row>, <col> SAY8 <say> [<sayexp,...>] GET <get> [<getexp,...>] => ;
         @ <row>, <col> SAY8 <say> [ <sayexp>] ;;
         @ Row(), Col() + 1 GET <get> [ <getexp>]


#command ?U  [<explist,...>]         => QOutU( <explist> )
#command ??U [<explist,...>]         => QQOutU( <explist> )
#translate _ue( <arg> )              => hb_UTF8ToStr( <arg> )

#command RREPLACE <f1> WITH <v1> [, <fN> WITH <vN> ]    ;
      => my_rlock();
         ;   _FIELD-><f1> := <v1> [; _FIELD-><fN> := <vN>];
         ;my_unlock()


#define EXEPATH   my_home_root()
#define SIFPATH   my_home()


#define KUMPATH   my_home()
#define CURDIR    my_home()

#define I_ID 1
#define DE_ADD  5
#define DE_DEL  6


#define RECI_GDJE_SAM   PROCNAME(1) + " (" + ALLTRIM(STR(PROCLINE(1))) + ")"
#define RECI_GDJE_SAM0  PROCNAME(0) + " (" + ALLTRIM(STR(PROCLINE(0))) + ")"

#command ESC_EXIT  => if lastkey()=K_ESC;
                      ;exit             ;
                      ;endif

#command ESC_RETURN <x> => if lastkey()=K_ESC;
                           ;return <x>       ;
                           ;end

#command ESC_RETURN    => if lastkey()=K_ESC;
                           ;return          ;
                           ;end

#command HSEEK <xpr>     => dbSeek(<xpr> ,.f.)

#command MSEEK <xpr>             => dbSeek(<xpr> )


#command EJECTA0          => qqout(chr(13)+chr(10)+chr(12))  ;
                           ; setprc(0,0)             ;
                           ; A:=0

#command EJECTNA0         => qqout(chr(13)+chr(10)+chr(18)+chr(12))  ;
                           ; setprc(0,0)             ;
                           ; A:=0


#command FF                 => gPFF()
#command P_FF               => gPFF()

#xcommand P_INI              =>  gpini()
#xcommand P_NR              =>   gpnr()
#xcommand P_COND             =>  gpCOND()
#xcommand P_COND2            =>  gpCOND2()
#xcommand P_10CPI            =>  gP10CPI()
#xcommand P_12CPI            =>  gP12CPI()
#xcommand F10CPI            =>  gP10CPI()
#xcommand F12CPI            =>  gP12CPI()
#xcommand P_B_ON             =>  gPB_ON()
#xcommand P_B_OFF            =>  gPB_OFF()
#xcommand P_I_ON             =>  gPI_ON()
#xcommand P_I_OFF            =>  gPI_OFF()
#xcommand P_U_ON             =>  gPU_ON()
#xcommand P_U_OFF            =>  gPU_OFF()

#xcommand P_PO_P             =>  gPO_Port()
#xcommand P_PO_L             =>  gPO_Land()
#xcommand P_RPL_N            =>  gRPL_Normal()
#xcommand P_RPL_G            =>  gRPL_Gusto()


#xcommand INI              =>  gPB_ON()
#xcommand B_ON             =>  gPB_ON()
#xcommand B_OFF            =>  gPB_OFF()
#xcommand I_ON             =>  gPI_ON()
#xcommand I_OFF            =>  gPI_OFF()
#xcommand U_ON             =>  gPU_ON()
#xcommand U_OFF            =>  gPU_OFF()

#xcommand PO_P             =>  gPO_Port()
#xcommand PO_L             =>  gPO_Land()
#xcommand RPL_N            =>  gRPL_Normal()
#xcommand RPL_G            =>  gRPL_Gusto()



#xcommand CLOSERET2      => RETURN my_close_all_dbf()
#xcommand CLOSERET       => RETURN my_close_all_dbf()


#xcommand ESC_BCR   =>  if LastKey() == K_ESC     ;
                         ; my_close_all_dbf()     ;
                         ; BoxC()                 ;
                         ;return .F.              ;
                         ;endif


#xcommand START PRINT EDITOR => PRIVATE __print_opt := "0" ;
          ; if EMPTY(f18_start_print(NIL, @__print_opt))       ;
          ;    my_close_all_dbf()             ;
          ;    return .F.                  ;
          ;endif

#xcommand START PRINT CRET <x>  => PRIVATE __print_opt := NIL ;
                                  ; if EMPTY(f18_start_print(NIL, @__print_opt))       ;
                                  ;    my_close_all_dbf()             ;
                                  ;    return <x>                     ;
                                  ;endif

#xcommand STARTPRINT CRET <x>  => PRIVATE __print_opt := NIL ;
                                  ; if EMPTY(f18_start_print(NIL, @__print_opt))       ;
                                  ;    my_close_all_dbf()             ;
                                  ;    return <x>                     ;
                                  ;endif

#xcommand STARTPRINT CRET       => PRIVATE __print_opt := NIL ;
                                  ; if EMPTY(f18_start_print(NIL, @__print_opt))       ;
                                  ;    my_close_all_dbf()             ;
                                  ;    return .F.                     ;
                                  ;endif





#xcommand START PRINT CRET  =>    private __print_opt := NIL ;
                                  ; if f18_start_print(NIL, @__print_opt) == "X"  ;
                                  ;    my_close_all_dbf()             ;
                                  ;    return .F.                     ;
                                  ;endif

#xcommand START PRINT RET <x>  =>  private __print_opt := NIL ;
                                  ;if f18_start_print(NIL, @__print_opt) == "X"   ;
                                  ; return <x>            ;
                                  ;endif

#xcommand START PRINT RET      =>  ;private __print_opt := NIL ;
                                  ;if f18_start_print(NIL, @__print_opt) == "X"  ;
                                  ;  return NIL             ;
                                  ;endif




#command STARTPRINTPORT CRET <p>, <x> =>  PRIVATE __print_opt := NIL ;
                                        ;IF !SPrint2(<p>)       ;
                                        ;my_close_all_dbf()             ;
                                        ;return <x>            ;
                                        ;endif

#command STARTPRINTPORT CRET <p>   => PRIVATE __print_opt := NIL ;
                                     ;if !Sprint2(<p>)          ;
                                     ;my_close_all_dbf()        ;
                                     ;return <p>               ;
                                     ;endif

#command END PRN2 <x> => Eprint2(<x>)
#command ENDPRN2 <x> => Eprint2(<x>)

#command END PRN2     => Eprint2()
#command ENDPRN2     => Eprint2()


#command END PRINT => f18_end_print(NIL, __print_opt)

#command ENDPRINT => f18_end_print(NIL, __print_opt)


#command EOF CRET <x> =>  if EofFndret(.T., .T.)       ;
                          ;return <x>                  ;
                          ;endif

#command EOF CRET     =>  if EofFndret(.T., .T.)         ;
                          ;return .F.                     ;
                          ;endif

#command EOF RET <x> =>   if EofFndret(.T., .F.)    ;
                          ; return <x>               ;
                          ;endif

#command EOF RET     =>   if EofFndret(.T., .F.)          ;
                          ;    return .F.                 ;
                          ;endif

#command NFOUND CRET <x> =>  if EofFndret(.F., .T.)      ;
                             ;    return <x>             ;
                             ;endif

#command NFOUND CRET     =>  if EofFndret(.F., .T.)        ;
                             ;   return .F.                ;
                             ;endif

#command NFOUND RET <x> =>  if EofFndret(.F., .F.)       ;
                            ;   return  <x>             ;
                            ;endif

#command NFOUND RET     =>  if EofFndret(.F., .F.)       ;
                            ;   return  .F.              ;
                            ;endif

#define SLASH  HB_OSPATHSEPARATOR()



#define NRED_DOS Chr(13)+Chr(10)

#define P_NRED QOUT()

#xcommand DO WHILESC <exp>      => while <exp>                     ;
                                   ;if inkey()==27                 ;
                                   ; dbcloseall()                  ;
                                   ;   SET(_SET_DEVICE,"SCREEN")   ;
                                   ;   SET(_SET_CONSOLE,"ON")      ;
                                   ;   SET(_SET_PRINTER,"")        ;
                                   ;   SET(_SET_PRINTFILE,"")      ;
                                   ;   MsgC()                      ;
                                   ;   return                      ;
                                   ;endif

#command KRESI <x> NA <len> =>  <x>:=left(<x>,<len>)

// Force reread/redisplay of all data rows
#define DE_REF      12

#command DEL2                                                            ;
      => (nArr)->(DbDelete2())                                            ;
        ;(nTmpArr)->(DbDelete2())

#define DBFBASEPATH "C:" + SLASH +  "SIGMA"

#define P_KUMPATH  1
#define P_SIFPATH  2
#define P_PRIVPATH 3
#define P_TEKPATH  4
#define P_MODULPATH  5
#define P_KUMSQLPATH 6
#define P_ROOTPATH 7
#define P_EXEPATH 8
#define P_SECPATH 9

#command @ <row>, <col> GETB <var>                                      ;
                        [PICTURE <pic>]                                 ;
                        [VALID <valid>]                                 ;
                        [WHEN <when>]                                   ;
                        [SEND <msg>]                                    ;
                                                                        ;
      => SetPos( box_x_koord()+<row>, box_y_koord()+<col> )                                 ;
       ; AAdd(                                                          ;
               GetList,                                                 ;
               _GET_( <var>, <(var)>, <pic>, <{valid}>, <{when}> )      ;
             )                                                          ;
      [; ATail(GetList):<msg>]



#command @ <row>, <col> SAYB <sayxpr>                                   ;
                        [<sayClauses,...>]                              ;
                        GETB <var>                                      ;
                        [<getClauses,...>]                              ;
                                                                        ;
      => @ <row>, <col> SAYB <sayxpr> [<sayClauses>]                    ;
       ; @ Row(), Col()+1 GETB <var> [<getClauses>]



#command @ <row>, <col> SAYB <xpr>                                      ;
                        [PICTURE <pic>]                                 ;
                        [COLOR <color>]                                 ;
                                                                        ;
      => DevPos( box_x_koord()+<row>, box_y_koord()+<col> )                                 ;
       ; DevOutPict( <xpr>, <pic> [, <color>] )

#command SET MRELATION                                                  ;
         [<add:ADDITIVE>]                                               ;
         [TO <key1> INTO <(alias1)> [, [TO] <keyn> INTO <(aliasn)>]]    ;
                                                                        ;
      => if ( !<.add.> )                                                ;
       ;    dbClearRel()                                                ;
       ; end                                                            ;
                                                                        ;
       ; dbSetRelation( <(alias1)>,{||'1'+<key1>}, "'1'+"+<"key1"> )      ;
      [; dbSetRelation( <(aliasn)>,{||'1'+<keyn>}, "'1'+"+<"keyn"> ) ]



#command APPEND NCNL    =>  appblank2(.f.,.f.)

#command APPEND BLANKS  => appblank2()

#command MY_DELETE      =>    delete2()

#command AP52 [FROM <(file)>]                                         ;
         [FIELDS <fields,...>]                                          ;
         [FOR <for>]                                                    ;
         [WHILE <while>]                                                ;
         [NEXT <next>]                                                  ;
         [RECORD <rec>]                                                 ;
         [<rest:REST>]                                                  ;
         [VIA <rdd>]                                                    ;
         [ALL]                                                          ;
                                                                        ;
      => __dbApp(                                                       ;
                  <(file)>, { <(fields)> },                             ;
                  <{for}>, <{while}>, <next>, <rec>, <.rest.>, <rdd>    ;
                )


#command ?C  [ <xList,...> ] => ( OutStd( hb_eol() ) [, OutStd( <xList> ) ] )
#command ??C [ <xList,...> ] => OutStd( <xList> )

#command ?E  [ <xList,...> ] => ( OutErr( hb_eol() ) [, OutErr( <xList> ) ] )
#command ??E [ <xList,...> ] => OutErr( <xList> )

// ----- fin.ch ------------
#define DABLAGAS lBlagAsis .and. _IDVN == cBlagIDVN

#define RADNIK          radn->(PADR(TRIM(naz)+" ("+TRIM(imerod)+") "+ime,35))
#define RADNIK_PREZ_IME radn->(PADR(TRIM(naz) +" ("+TRIM(imerod)+") "+ime,35))

#define RADNZABNK radn->(PADR(TRIM(naz)+" ("+TRIM(imerod)+") "+TRIM(ime), 40))


#define __g10Str2T g10Str2T
#define __g10Str g10Str

#define FAKT_DOKS_PARTNER_LENGTH 100


// definicija korisnickih nivoa
#define L_SYSTEM           "0"
#define L_ADMIN            "0"
#define L_UPRAVN           "1"
#define L_UPRAVN_2         "2"
#define L_PRODAVAC         "3"

// ulaz / izlaz roba /sirovina
#define R_U       "1"           // roba - ulaz
#define R_I       "2"           //      - izlaz
#define S_U       "3"           // sirovina - ulaz
#define S_I       "4"           //          - izlaz
#define SP_I      "I"           // inventura - stanje
#define SP_N      "N"           // nivelacija

#define KALK_IDVD_MAGACIN "10#16#18#IM"

#define POS_IDVD_ULAZI "P0#11#80#81"

#define POS_IDVD_POCETNO_STANJE_PRODAVNICA  "P0"
#define POS_IDVD_PRIJEM_PRODAVNICA          "80"
#define POS_IDVD_DOBAVLJAC_PRODAVNICA       "81"
#define POS_IDVD_OTPREMNICA_MAGACIN         "11"

#define POS_IDVD_IZLAZI_NIVELACIJE_INVENTURE "42#19#IP"
#define POS_IDVD_RACUN               "42"
#define POS_IDVD_NIVELACIJA          "19"
#define POS_IDVD_INVENTURA           "IP"       // inventura


// ako ima potrebe, brojeve zaokruzujemo na
#define N_ROUNDTO    2
//#define I_ID         1
#define I_ID2        2

#define PICT_POS_ARTIKAL "@!S10"

#define F18_VERZIJA "4"
#define F18_VARIJANTA "4s"


#define FIELD_LENGTH_LD_RADKR_NA_OSNOVU 20
#define FIELD_LD_RADN_IDBANKA 6
#define FIELD_LENGTH_IDKONTO 7
