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


FUNCTION TAppModNew( oParent, cVerzija, cPeriod, cKorisn, cSifra, p3, p4, p5, p6, p7 )

   LOCAL oObj

   oObj := TAppMod():new()

   RETURN oObj


CLASS TAppMod

   DATA cName
   DATA oParent
   DATA oDesktop
   DATA cVerzija
   DATA cPeriod
   DATA cKorisn
   DATA cSifra
   DATA cP3
   DATA cP4
   DATA cP5
   DATA cP6
   DATA cP7
   DATA lStarted
   DATA lTerminate

   METHOD NEW
   METHOD hasParent
   METHOD setParent
   METHOD getParent
   METHOD setName
   METHOD RUN
   METHOD QUIT
   METHOD gProc
   METHOD gParams
   METHOD setTGVars

ENDCLASS


METHOD New( oParent, cModul, cVerzija, cPeriod, cKorisn, cSifra, p3, p4, p5, p6, p7 ) CLASS TAppMod

   ::lStarted := nil
   ::cName := cModul
   ::oParent := oParent
   ::cVerzija := cVerzija
   ::cPeriod := cPeriod
   ::cKorisn := cKorisn
   ::cSifra := cSifra
   ::cP3 := p3
   ::cP4 := p4
   ::cP5 := p5
   ::cP6 := p6
   ::cP7 := p7
   ::lTerminate := .F.

   RETURN .T.


METHOD hasParent()

   RETURN !( ::oParent == NIL )


METHOD setParent( oParent )

   ::parent := oParent

   RETURN .T.


METHOD getParent()
   RETURN ::oParent


METHOD setName()

   ::cName := "F18"

   RETURN .T.


METHOD run()

   IF ::oDesktop == NIL
      ::oDesktop := TDesktopNew()
   ENDIF

   IF ::lStarted == NIL
      ::lStarted := .F.
   ENDIF

   add_global_idle_handlers()  // BUG_CPU100
   start_f18_program_module( self, .T. )

   ::lStarted := .T.

   IF ::lTerminate
      ::quit()
      RETURN .F.
   ENDIF

   ::MMenu() // osnovni meni programskog modula
   remove_global_idle_handlers()

   RETURN .T.


METHOD gProc( nKey, nKeyHandlerRetEvent )

   LOCAL lPushWa
   LOCAL nI

   pq_receive()

   DO CASE

#ifdef __PLATFORM__DARWIN
   CASE ( nKey == K_F12 )
#else
   CASE ( nKey == K_INS )
#endif
      show_insert_over_stanje( .T. )
      // RETURN DE_CONT

   CASE nKey == Asc( "i" ) .OR. nKey == Asc( "I" )
      show_infos()
      // RETURN DE_CONT

   CASE nKey == Asc( "e" ) .OR. nKey == Asc( "E" )
      show_errors()
      // RETURN DE_CONT

   CASE ( nKey == K_SH_F1 )
      f18_kalkulator()

   CASE ( nKey == K_SH_F6 )
      f18_promjena_sezone()

   CASE ( nKey == K_SH_F2 .OR. nKey == K_CTRL_F2 )
      PPrint()

   CASE nKey == iif( is_mac(), K_F10, K_SH_F10 )
      ::gParams()

   CASE nKey == iif( is_mac(), K_F9, K_SH_F9 )
      Adresar()

   CASE nKey == K_F1
      k_f1()

   CASE nKey == K_F12
      k_f12()

   OTHERWISE
      IF !( "U" $ Type( "gaKeys" ) )
         FOR nI := 1 TO Len( gaKeys )
            IF ( nKey == gaKeys[ nI, 1 ] )
               Eval( gaKeys[ nI, 2 ] )
            ENDIF
         NEXT
      ENDIF
   ENDCASE

   RETURN nKeyHandlerRetEvent


/*   izlazak iz aplikacijskog modula
 *  lVratiSeURP - default vrijednost .t.; kada je .t. vrati se u radno podrucje; .f. ne mjenjaj radno podrucje
 */

METHOD quit( lVratiseURP )

   LOCAL cKontrDbf

   my_close_all_dbf()
   IF ( lVratiseURP == NIL )
      lVratiseURP := .T.
   ENDIF

   RETURN .T.


METHOD gparams()

   my_login():administratorske_opcije( 10, 10 )

   RETURN .T.



/*
 *  Setuje globalne varijable, te setuje incijalne vrijednosti objekata koji pripadaju glavnom app objektu
 */

METHOD setTGVars()

   info_bar( ::cName, ::cName + " set_tg_vars start " )


   IF ( ::oDesktop != NIL )
      ::oDesktop := nil
   ENDIF

   PUBLIC cZabrana := "Opcija nedostupna za ovaj nivo !"

   ::oDesktop := TDesktopNew()

   info_bar( ::cName, ::cName + " set_tg_vars end" )

   RETURN .T.


PROCEDURE k_f1()

   IF is_windows()
      // Run("mode con: cols=120 lines=40")
   ELSE
      // Run("stty cols 120 rows 40")
   ENDIF
   // info_bar( "tty", "120 x 40" )

   RETURN


PROCEDURE k_f12()

   LOCAL cEkran := SaveScreen( 0, 0, Row(), Col() )

   // IF is_windows()
   // Run("mode con: cols=120 lines=40")
   // ELSE
   // Run("stty cols 120 rows 40")
   // ENDIF
   info_bar( "tty", "refresh" )

   RestScreen( 0, 0, Row(), Col(), cEkran )

   RETURN
