/*
 * This file is part of the bring.out knowhow ERP, a free and open source
 * Enterprise Resource Planning software suite,
 * Copyright (c) 1994-2018 by bring.out d.o.o Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including knowhow ERP specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_knowhow.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */

#include "f18.ch"
#include "f18_color.ch"

STATIC s_lPtxt := NIL

MEMVAR GetList

FUNCTION set_parametre_f18_aplikacije( lUpravoSetovani )

   LOCAL nX := 1
   LOCAL nPosX
   LOCAL nPosY
   LOCAL _left := 20
   LOCAL _fin, _kalk, _fakt, _epdv, _virm, _ld, _os, _rnal, _mat  // , _reports, _kadev
   LOCAL _pos
   LOCAL _email_server, _email_port, _email_username, _email_userpass, _email_from
   LOCAL _email_to, _email_cc
   LOCAL _proper_name, _params
   LOCAL _log_delete_interval
   LOCAL nBackupOrgInterval, nBackupServerInterval
   LOCAL _backup_removable, _backup_ping_time
   LOCAL _rpt_page_len, _bug_report
   LOCAL _log_level
   LOCAL cLdRekapDbf, cLegacyKalkPr, cLegacyPTxt, cDownloadF18LO
   LOCAL cErrMsg
   LOCAL cCheckUpdates := fetch_metric( "F18_check_updates", my_user(), "D" )
   LOCAL cF18Verzija := Padr( fetch_metric( "F18_verzija", NIL, F18_VERZIJA ), 4)
   LOCAL cF18VerzijaKanal := Padr( fetch_metric( "F18_verzija_kanal", my_user(), "S" ), 1)
   LOCAL cF18Varijanta := Padr( fetch_metric( "F18_varijanta", NIL, F18_VARIJANTA ), 5 )
   LOCAL cScreen

   save screen to cScreen

   info_bar( "init", "set_parametre_f18_aplikacije - start" )

   _fin := fetch_metric( "main_menu_fin", my_user(), "D" )
   _kalk := fetch_metric( "main_menu_kalk", my_user(), "D" )

   IF fetch_metric_error() > 1
      cErrMsg := "problem komunikacije sa serverom ?!#fetch_metric_error:" + AllTrim( Str( fetch_metric_error() ) )
      ?E cErrMsg
      IF is_in_main_thread()
         MsgBeep( cErrMsg )
      ENDIF
      RESTORE SCREEN FROM cScreen
      RETURN .F.
   ENDIF
   _fakt := fetch_metric( "main_menu_fakt", my_user(), "D" )
   _ld := fetch_metric( "main_menu_ld", my_user(), "N" )
   _epdv := fetch_metric( "main_menu_epdv", my_user(), "N" )
   _virm := fetch_metric( "main_menu_virm", my_user(), "N" )
   _os := fetch_metric( "main_menu_os", my_user(), "N" )
   _rnal := fetch_metric( "main_menu_rnal", my_user(), "N" )
   _mat := fetch_metric( "main_menu_mat", my_user(), "N" )
   _pos := fetch_metric( "main_menu_pos", my_user(), "N" )
   // _reports := fetch_metric( "main_menu_reports", my_user(), "N" )
   // _kadev := fetch_metric( "main_menu_kadev", my_user(), "N" )

   _email_server := PadR( fetch_metric( "email_server", my_user(), "" ), 100 )
   _email_port := fetch_metric( "email_port", my_user(), 25 )
   _email_username := PadR( fetch_metric( "email_user_name", my_user(), "" ), 100 )
   _email_userpass := PadR( fetch_metric( "email_user_pass", my_user(), "" ), 50 )
   _email_from := PadR( fetch_metric( "email_from", my_user(), "" ), 100 )
   _email_to := PadR( fetch_metric( "email_to_default", my_user(), "" ), 500 )
   _email_cc := PadR( fetch_metric( "email_cc_default", my_user(), "" ), 500 )

   IF fetch_metric_error() > 1
      IF is_in_main_thread()
         MsgBeep( "problem komunikacije sa serverom ?!#fetch_metric_error:" + AllTrim( Str( fetch_metric_error() ) ) )
      ENDIF
      RESTORE SCREEN FROM cScreen
      RETURN .F.
   ENDIF

   _proper_name := PadR( fetch_metric( "my_proper_name", my_user(), "" ), 50 )

   _log_delete_interval := fetch_metric( "log_delete_level", NIL, 30 )

   nBackupOrgInterval := fetch_metric( "backup_company_interval", my_user(), 0 )
   nBackupServerInterval := fetch_metric( "backup_server_interval", my_user(), 0 )
   _backup_removable := PadR( fetch_metric( "backup_removable_drive", my_user(), "" ), 300 )

#ifdef __PLATFORM__WINDOWS
   _backup_ping_time := fetch_metric( "backup_windows_ping_time", my_user(), 0 )
#else
   _backup_ping_time := 0
#endif

   _rpt_page_len := fetch_metric( "rpt_duzina_stranice", my_user(), RPT_PAGE_LEN )
   _bug_report := fetch_metric( "bug_report_email", my_user(), "A" )
   _log_level := fetch_metric( "log_level", NIL, 3 )

   // cLdRekapDbf := fetch_metric( "legacy_ld_rekap_dbf", NIL, "N" )
   cLegacyKalkPr := fetch_metric( "legacy_kalk_pr", NIL, "N" )
   cLegacyPTxt := fetch_metric( "legacy_ptxt", NIL, "D" )
   cDownloadF18LO := fetch_metric( "F18_LO", my_user(), "N" )


   IF lUpravoSetovani == nil
      lUpravoSetovani := .F.
   ENDIF

   IF !lUpravoSetovani

      CLEAR SCREEN
      ?
      nPosX := 1
      nPosY := 2

      @ nPosX, nPosY SAY "Odabir modula za glavni meni ***" COLOR f18_color_i()
      @ nPosX + nX, nPosY SAY Space( 2 ) + "FIN:" GET _fin PICT "@!"
      @ nPosX + nX, Col() + 1 SAY "KALK:" GET _kalk PICT "@!"
      @ nPosX + nX, Col() + 1 SAY "FAKT:" GET _fakt PICT "@!"
      @ nPosX + nX, Col() + 1 SAY "ePDV:" GET _epdv PICT "@!"
      @ nPosX + nX, Col() + 1 SAY "LD:" GET _ld PICT "@!"
      @ nPosX + nX, Col() + 1 SAY "VIRM:" GET _virm PICT "@!"
      @ nPosX + nX, Col() + 1 SAY "OS/SII:" GET _os PICT "@!"
      @ nPosX + nX, Col() + 1 SAY "POS:" GET _pos PICT "@!"
      @ nPosX + nX, Col() + 1 SAY "MAT:" GET _mat PICT "@!"
      @ nPosX + nX, Col() + 1 SAY "RNAL:" GET _rnal PICT "@!"
      // @ nPosX + nX, Col() + 1 SAY "KADEV:" GET _kadev PICT "@!"
      // @ nPosX + nX, Col() + 1 SAY "REPORTS:" GET _reports PICT "@!"

      nX += 2
      @ nPosX + nX, nPosY SAY8 "Matični podaci korisnika ***" COLOR f18_color_i()
      nX++
      @ nPosX + nX, nPosY SAY PadL( "Puno ime i prezime:", _left ) GET _proper_name PICT "@S30"

      nX += 2
      @ nPosX + nX, nPosY SAY "Email parametri ***" COLOR f18_color_i()
      ++nX
      @ nPosX + nX, nPosY SAY PadL( "email server:", _left ) GET _email_server PICT "@S30"
      @ nPosX + nX, Col() + 1 SAY "port:" GET _email_port PICT "9999"
      ++nX
      @ nPosX + nX, nPosY SAY PadL( "username:", _left ) GET _email_username PICT "@S30"
      @ nPosX + nX, Col() + 1 SAY "password:" GET _email_userpass PICT "@S30" COLOR F18_COLOR_PASSWORD
      ++nX
      @ nPosX + nX, nPosY SAY PadL( "moja email adresa:", _left ) GET _email_from PICT "@S40"
      ++nX
      @ nPosX + nX, nPosY SAY8 PadL( "slati poštu na adrese:", _left ) GET _email_to PICT "@S70"

      ++nX
      @ nPosX + nX, nPosY SAY PadL( "cc adrese:", _left ) GET _email_cc PICT "@S70"

      nX += 2
      @ nPosX + nX, nPosY SAY "Parametri log-a ***" COLOR f18_color_i()
      ++nX
      @ nPosX + nX, nPosY SAY8 "Briši stavke log tabele starije od broja dana (def. 30):" GET _log_delete_interval PICT "9999"

      nX += 2
      @ nPosX + nX, nPosY SAY "Backup parametri ***" COLOR f18_color_i()
      ++nX
      @ nPosX + nX, nPosY SAY8 "Automatski backup podataka organizacije (interval dana 0 - ne radi ništa):" GET nBackupOrgInterval PICT "999"
      ++nX
      @ nPosX + nX, nPosY SAY8 "Automatski backup podataka servera (interval 0 - ne radi ništa):" GET nBackupServerInterval PICT "999"

      ++nX
      @ nPosX + nX, nPosY SAY "Udaljena backup lokacija:" GET _backup_removable PICT "@S60"

#ifdef __PLATFORM__WINDOWS
      ++nX
      @ nPosX + nX, nPosY SAY "Ping time kod backup komande:" GET _backup_ping_time PICT "99"
#endif

      nX += 2
      @ nPosX + nX, nPosY SAY "Ostali parametri ***" COLOR f18_color_i()
      ++nX
      @ nPosX + nX, nPosY SAY8 "Dužina stranice za izvještaje ( def: 60 ):" GET _rpt_page_len PICT "999"

      ++nX
      @ nPosX + nX, nPosY SAY "BUG report na email (D/N/A/0):" GET _bug_report PICT "!@" VALID _bug_report $ "DNA0"

      @ nPosX + nX, Col() + 2 SAY "Nivo logiranja (0..9)" GET _log_level PICT "9" VALID _log_level >= 0 .AND. _log_level < 10

      nX += 2
      @ nPosX + nX, nPosY SAY "Kompatibilnost ***" COLOR f18_color_i()
      ++nX
      // @ nPosX + nX, nPosY SAY "LD rekap dbf:" GET cLdRekapDbf PICT "!@" VALID cLdRekapDbf $ "DN"
      @ nPosX + nX, nPosY SAY "KALK PR:" GET cLegacyKalkPr PICT "!@" VALID cLegacyKalkPr $ "DN"
      @ nPosX + nX, Col() + 2 SAY "PTXT:" GET cLegacyPTxt PICT "!@" VALID cLegacyPTxt $ "DN"
      @ nPosX + nX, Col() + 2 SAY "F18 LO (D/N/0):" GET cDownloadF18LO PICT "!@" VALID cDownloadF18LO $ "DN0"
      @ nPosX + nX, Col() + 2 SAY "F18 updates (D/N):" GET cCheckUpdates PICT "!@" VALID cCheckUpdates $ "DN"
      @ nPosX + nX, Col() + 2 SAY "F18 verzija:" GET cF18Verzija VALID AllTrim( cF18Verzija ) $ "3#4#5#6"
      @ nPosX + nX, Col() + 2 SAY "-" GET cF18Varijanta VALID AllTrim( cF18Varijanta ) $ "std#vindi#pos#rnal"
      @ nPosX + nX, Col() + 2 SAY "/" GET cF18VerzijaKanal PICT "!@" VALID AllTrim( cF18VerzijaKanal ) $ "SEX"

      READ

      IF LastKey() == K_ESC
         RESTORE SCREEN FROM cScreen
         RETURN .F.
      ENDIF

      set_metric( "main_menu_fin", my_user(), _fin )
      set_metric( "main_menu_kalk", my_user(), _kalk )
      set_metric( "main_menu_fakt", my_user(), _fakt )
      set_metric( "main_menu_ld", my_user(), _ld )
      set_metric( "main_menu_virm", my_user(), _virm )
      set_metric( "main_menu_os", my_user(), _os )
      set_metric( "main_menu_epdv", my_user(), _epdv )
      set_metric( "main_menu_rnal", my_user(), _rnal )
      set_metric( "main_menu_mat", my_user(), _mat )
      set_metric( "main_menu_pos", my_user(), _pos )
      // set_metric( "main_menu_kadev", my_user(), _kadev )
      // set_metric( "main_menu_reports", my_user(), _reports )
      set_metric( "email_server", my_user(), AllTrim( _email_server ) )
      set_metric( "email_port", my_user(), _email_port )
      set_metric( "email_user_name", my_user(), AllTrim( _email_username ) )
      set_metric( "email_user_pass", my_user(), AllTrim( _email_userpass ) )
      set_metric( "email_from", my_user(), AllTrim( _email_from ) )
      set_metric( "email_to_default", my_user(), AllTrim( _email_to ) )
      set_metric( "email_cc_default", my_user(), AllTrim( _email_cc ) )
      set_metric( "my_proper_name", my_user(), AllTrim( _proper_name ) )
      set_metric( "log_delete_level", NIL, _log_delete_interval )
      set_metric( "backup_company_interval", my_user(), nBackupOrgInterval )
      set_metric( "backup_server_interval", my_user(), nBackupServerInterval )
      set_metric( "backup_removable_drive", my_user(), AllTrim( _backup_removable ) )
      set_metric( "rpt_duzina_stranice", my_user(), _rpt_page_len )
      set_metric( "bug_report_email", my_user(), _bug_report )

      set_metric( "log_level", NIL, _log_level )
      log_level( _log_level )

#ifdef __PLATFORM__WINDOWS
      set_metric( "backup_windows_ping_time", my_user(), _backup_ping_time )
#endif

      // set_metric( "legacy_ld_rekap_dbf", NIL, cLdRekapDbf )
      set_metric( "legacy_kalk_pr", NIL, cLegacyKalkPr )
      set_metric( "legacy_ptxt", NIL, cLegacyPTxt )
      set_metric( "F18_LO", my_user(), cDownloadF18LO )
      set_metric( "F18_check_updates", my_user(), cCheckUpdates )
      set_metric( "F18_verzija", NIL, cF18Verzija )
      set_metric( "F18_varijanta", NIL, cF18Varijanta )
      set_metric( "F18_verzija_kanal", my_user(), cF18VerzijaKanal )
      info_bar( "init", "set_parametre_f18_aplikacije - end" )

   ENDIF

   RESTORE SCREEN FROM cScreen

   RETURN .T.



/*
   Opis: ispituje da li je modul aktivan za tekućeg korisnika

   Usage: f18_use_module( 'kalk' ) => .T. ili .F.

   Params:
      cModuleName - naziv modula 'kalk', 'fin'
*/

FUNCTION f18_use_module( cModuleName )

   LOCAL cDefaultDN := "N"

   LOCAL cModulRun := get_f18_param("run")

   IF cModulRun != "<undefined>"
      IF cModuleName == cModulRun
          RETURN .T.
      ENDIF

      IF cModulRun == "pos" // pokrenut POS, use npr. FIN 
          RETURN .F.
      ENDIF
   ENDIF

   IF cModuleName == "tops"
      cModuleName := "pos"
   ENDIF

   IF cModuleName $ "fin#kalk#fakt"
      cDefaultDN := "D"
   ENDIF

   IF fetch_metric( "main_menu_" + cModuleName, my_user(), cDefaultDN ) == "D"
      RETURN .T.
   ENDIF

   RETURN .F.



/*
   Opis: setuje modul kao aktivan ili ne za tekućeg korisnika

   Usage: f18_set_use_module( 'kalk', .T. ) => modul KALK za korisnika je aktivan

   Params:
       cModuleName - naziv modula 'kalk', 'fin'
       lset - .T. aktivan, .F. neaktivan
*/
FUNCTION f18_set_use_module( cModuleName, lset )

   LOCAL _ret := .F.
   LOCAL _set := "N"

   IF cModuleName == "tops"
      cModuleName := "pos"
   ENDIF

   IF lset == NIL
      lset := .T.
   ENDIF

   IF lset
      _set := "D"
   ENDIF

   set_metric( "main_menu_" + cModuleName, my_user(), _set )

   RETURN _ret




FUNCTION is_legacy_kalk_pr()

   RETURN fetch_metric( "legacy_kalk_pr", NIL, "D" ) == "D"


/*
    print txt dokument, ne PDF
*/
FUNCTION is_legacy_ptxt()

   IF legacy_ptxt() != NIL
      RETURN legacy_ptxt()
   ENDIF

   RETURN fetch_metric( "legacy_ptxt", NIL, "D" ) == "D"


FUNCTION legacy_ptxt( lSet )

     IF lSet != NIL
        s_lPtxt := lSet
     ENDIF

     RETURN s_lPtxt
