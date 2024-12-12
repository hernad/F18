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

#include "f18.ch"
#include "f18_color.ch"

STATIC __relogin_opt := .F.


#ifndef TEST

FUNCTION Main( p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11 )

   LOCAL _arg_v := hb_Hash()

   cre_arg_v_hash( @_arg_v, p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11 )
   set_f18_params( p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11 )
   harbour_init()

   init_parameters_cache()
   set_f18_current_directory()
   set_f18_home_root()
   set_global_vars_0()
   f18_error_block()

   set_screen_dimensions()

   naslovni_ekran_splash_screen( "F18", f18_ver() )


   IF no_sql_mode()
      set_f18_home( "f18_test" )
      RETURN .T.
   ENDIF


   f18_login_loop( NIL, _arg_v )

   RETURN .T.

#endif




FUNCTION f18_login_loop( lAutoConnect, hProgramParametri )

   LOCAL oLogin

   IF lAutoConnect == NIL
      lAutoConnect := .T.
   ENDIF

   oLogin := my_login()

   DO WHILE .T.

      oLogin:postgres_db_login( lAutoConnect )

      IF !oLogin:lPostgresDbSpojena
         QUIT_1
      ELSE
         lAutoConnect := .T.
      ENDIF

      IF !oLogin:odabir_organizacije()

         IF fetch_metric_error() > 0
            MsgBeep( "fetch metric error ?! : Cnt: "  + AllTrim( Str( fetch_metric_error() ) ) )
            RETURN .F.
         ENDIF

         IF LastKey() == K_ESC
            RETURN .F.
         ENDIF

      ELSE
         // IF oLogin:lOrganizacijaSpojena

         // show_sacekaj()
         // oLogin:disconnect_postgresql()

         oLogin:disconnect_user_database()
         IF oLogin:connect_user_database()
            f18_programski_moduli_meni( hProgramParametri )
         ELSE
            MsgBeep( "Spajanje na bazu traženog preduzeća/organizacije neuspješno !?" )
         ENDIF

         // ENDIF
      ENDIF

   ENDDO

   RETURN .T.


/*
    vraca hash matricu sa parametrima
*/

STATIC FUNCTION cre_arg_v_hash( hash )

   LOCAL nI := 2
   LOCAL _param
   LOCAL _count := 0

   hash := hb_Hash()
   hash[ "p1" ] := NIL
   hash[ "p2" ] := NIL
   hash[ "p3" ] := NIL
   hash[ "p4" ] := NIL
   hash[ "p5" ] := NIL
   hash[ "p6" ] := NIL
   hash[ "p7" ] := NIL
   hash[ "p8" ] := NIL
   hash[ "p9" ] := NIL
   hash[ "p10" ] := NIL
   hash[ "p11" ] := NIL

   DO WHILE nI <= PCount()

      _param := hb_PValue( nI++ ) // ucitaj parametar
      hash[ "p" + AllTrim( Str( ++_count ) ) ] := _param // p1, p2, p3...
   ENDDO

   RETURN .T.




FUNCTION f18_programski_moduli_meni( hProgramArgumenti )

   LOCAL aMeniOpcije := {}
   LOCAL aMeniExec := {}
   LOCAL nMeniIzbor
   LOCAL mnu_left := 2
   LOCAL mnu_top := 5
   LOCAL mnu_bottom := 23
   LOCAL mnu_right := 65
   LOCAL nX := 1
   LOCAL hDbParams
   LOCAL _count := 0

   // LOCAL oBackup := F18Backup():New()
   LOCAL _user_roles := f18_user_roles_info()
   LOCAL cServerDbVersion
   LOCAL _tmp
   LOCAL cOldColors

   // info_bar( "init", "gen f18_programski_moduli_meni start" )

   IF hProgramArgumenti == NIL
      cre_arg_v_hash( @hProgramArgumenti ) // napravi NIL parametre
   ENDIF

   DO WHILE .T.

      cOldColors := SetColor( F18_COLOR_ORGANIZACIJA )
      cServerDbVersion := get_version_str( server_db_version( .T. ) )

      ++_count
      CLEAR SCREEN
      hDbParams := my_server_params()

      nX := 1
      @ nX, mnu_left + 1 SAY8 "Tekuća baza: " + AllTrim( hDbParams[ "database" ] ) + " / db ver: " + cServerDbVersion + " / nivo log: " + AllTrim( Str( log_level() ) )
      ++nX
      @ nX, mnu_left + 1 SAY "   Korisnik: " + AllTrim( hDbParams[ "user" ] ) + "   gr: " + _user_roles + " VER: " + f18_ver()
      ++nX
      @ nX, mnu_left SAY Replicate( "-", 55 )


      // IF _count == 1 .OR. __relogin_opt // backup okidamo samo na prvom ulasku ili na opciji relogina

      // IF oBackup:locked( .F. ) // provjera da li je backup locked ?
      // oBackup:unlock()
      // ENDIF

      // f18_auto_backup_data( 1 ) // automatski backup podataka preduzeca
      // __relogin_opt := .F.

      // ENDIF

      aMeniOpcije := {}
      aMeniExec := {}

      set_program_module_menu( @aMeniOpcije, @aMeniExec, hProgramArgumenti[ "p3" ], hProgramArgumenti[ "p4" ], hProgramArgumenti[ "p5" ], hProgramArgumenti[ "p6" ], hProgramArgumenti[ "p7" ] )
      // info_bar( "init", "gen f18_programski_moduli_meni end" )

      nMeniIzbor := meni_0_inkey( mnu_top, mnu_left, mnu_bottom, mnu_right, aMeniOpcije, 1 )
      SetColor( cOldColors )

      DO CASE
      CASE nMeniIzbor == 0

         // IF !oBackup:locked
         EXIT
         // ELSE
         // MsgBeep( oBackup:backup_in_progress_info() )
         // ENDIF

      CASE nMeniIzbor > 0
         IF nMeniIzbor <= Len( aMeniExec )
            Eval( aMeniExec[ nMeniIzbor ] )
         ENDIF
      ENDCASE

      LOOP

   ENDDO

   // info_bar( hDbParams[ "database" ], "f18_programski_moduli_meni end" )

   RETURN .T.



STATIC FUNCTION set_program_module_menu( aMeniOpcije, aMeniExec, p3, p4, p5, p6, p7 )

   LOCAL _count := 0
   LOCAL cMenuBrojac
   LOCAL cVersion

#ifndef F18_DEBUG

   IF f18_preporuci_upgrade( @cVersion )

      AAdd( aMeniOpcije,  " U. F18 upgrade -> " + cVersion  )
      AAdd( aMeniExec, {|| F18Admin():update_app(), .T. } )

      AAdd( aMeniOpcije, "---------------------------------------------" )
      AAdd( aMeniExec, {|| NIL } )
   ENDIF

#endif

   IF f18_use_module( "fin" )
      cMenuBrojac := PadL( AllTrim( Str( ++_count ) ), 2 )
      AAdd( aMeniOpcije, cMenuBrojac + ". FIN   # finansijsko poslovanje                 " )
      AAdd( aMeniExec, {|| MainFin( my_user(), "dummy", p3, p4, p5, p6, p7 ) } )
   ENDIF

   IF f18_use_module( "kalk" )
      cMenuBrojac := PadL( AllTrim( Str( ++_count ) ), 2 )
      AAdd( aMeniOpcije, cMenuBrojac + ". KALK  # robno-materijalno poslovanje" )
      AAdd( aMeniExec, {|| MainKalk( my_user(), "dummy", p3, p4, p5, p6, p7 ) } )
   ENDIF

   IF f18_use_module( "fakt" )
      cMenuBrojac := PadL( AllTrim( Str( ++_count ) ), 2 )
      AAdd( aMeniOpcije, cMenuBrojac + ". FAKT  # fakturisanje" )
      AAdd( aMeniExec, {|| MainFakt( my_user(), "dummy", p3, p4, p5, p6, p7 ) } )
   ENDIF

   IF f18_use_module( "epdv" )
      cMenuBrojac := PadL( AllTrim( Str( ++_count ) ), 2 )
      AAdd( aMeniOpcije, cMenuBrojac + ". ePDV  # elektronska evidencija PDV-a" )
      AAdd( aMeniExec, {|| MainEpdv( my_user(), "dummy", p3, p4, p5, p6, p7 ) } )
   ENDIF

   IF f18_use_module( "ld" )
      cMenuBrojac := PadL( AllTrim( Str( ++_count ) ), 2 )
      AAdd( aMeniOpcije, cMenuBrojac + ". LD    # obračun plata" )
      AAdd( aMeniExec, {|| MainLd( my_user(), "dummy", p3, p4, p5, p6, p7 ) } )
   ENDIF


   IF f18_use_module( "os" )
      cMenuBrojac := PadL( AllTrim( Str( ++_count ) ), 2 )
      AAdd( aMeniOpcije, cMenuBrojac + ". OS/SII# osnovna sredstva i sitan inventar" )
      AAdd( aMeniExec, {|| MainOs( my_user(), "dummy", p3, p4, p5, p6, p7 ) } )
   ENDIF

   IF f18_use_module( "virm" )
      cMenuBrojac := PadL( AllTrim( Str( ++_count ) ), 2 )
      AAdd( aMeniOpcije, cMenuBrojac + ". VIRM  # virmani" )
      AAdd( aMeniExec, {|| MainVirm( my_user(), "dummy", p3, p4, p5, p6, p7 ) } )
   ENDIF

#ifdef F18_RNAL
   IF f18_use_module( "rnal" )
      cMenuBrojac := PadL( AllTrim( Str( ++_count ) ), 2 )
      AAdd( aMeniOpcije, cMenuBrojac + ". RNAL  # radni nalozi" )
      AAdd( aMeniExec, {|| MainRnal( my_user(), "dummy", p3, p4, p5, p6, p7 ) } )
   ENDIF
#endif

#ifdef F18_POS
   IF f18_use_module( "pos" )
      cMenuBrojac := PadL( AllTrim( Str( ++_count ) ), 2 )
      AAdd( aMeniOpcije, cMenuBrojac + ". POS   # maloprodajna kasa" )
      AAdd( aMeniExec, {|| MainPos( my_user(), "dummy", p3, p4, p5, p6, p7 ) } )
   ENDIF
#endif

#ifdef F18_MAT
   IF f18_use_module( "mat" )
      cMenuBrojac := PadL( AllTrim( Str( ++_count ) ), 2 )
      AAdd( aMeniOpcije, cMenuBrojac + ". MAT   # materijalno" )
      AAdd( aMeniExec, {|| MainMat( my_user(), "dummy", p3, p4, p5, p6, p7 ) } )
   ENDIF
#endif

   AAdd( aMeniOpcije, "---------------------------------------------" )
   AAdd( aMeniExec, {|| NIL } )

   AAdd( aMeniOpcije, " S. promjena sezone" )
   AAdd( aMeniExec, {|| f18_promjena_sezone() } )
   AAdd( aMeniOpcije, " B. backup podataka" )
   AAdd( aMeniExec, {|| f18_backup_now() } )
   AAdd( aMeniOpcije, " U. upgrade (nadogradnja) aplikacije" )
   AAdd( aMeniExec, {|| f18_update_available_version(), F18Admin():update_app() } )

   AAdd( aMeniOpcije, " P. parametri aplikacije" )
   AAdd( aMeniExec, {|| set_parametre_f18_aplikacije() } )
   AAdd( aMeniOpcije, " W. pregled log-a" )
   AAdd( aMeniExec, {|| f18_view_log() } )

// AAdd( aMeniOpcije, " V. vpn podrška" )
// AAdd( aMeniExec, {|| vpn_support() } )


   AAdd( aMeniOpcije, " X. diag info" )
   AAdd( aMeniExec, {|| diag_info() } )

   RETURN .T.


FUNCTION hb_SendMail( ... )
   RETURN tip_MailSend( ... )
