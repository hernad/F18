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
   METHOD globalni_key_handler
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


METHOD globalni_key_handler( nKey, nKeyHandlerRetEvent )

   LOCAL lPushWa
   LOCAL nI

   pq_receive()

   DO CASE

   CASE ( nKey == K_INS )
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

   CASE nKey == K_SH_F10
      ::gParams()

   CASE nKey == K_SH_F9
      Adresar()

   CASE nKey == K_F1
      k_f1()

   CASE nKey == K_F11
      k_f11()

   CASE nKey == K_F12
      k_f12()

   CASE nKey == K_CTRL_F12 // eShell koristi da uradi shutdown aplikacije!
      k_ctrl_f12()

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

   Box(, 5, 60)
     @ box_x_koord() + 1, box_y_koord() + 2 SAY8 "<F11> - pokretanje novog programskog modula"
     @ box_x_koord() + 2, box_y_koord() + 2 SAY8 "<F12> - pokretanje predhodne godine"

     @ box_x_koord() + 4, box_y_koord() + 2 SAY8 " <E>  - log - greške"
     @ box_x_koord() + 5, box_y_koord() + 2 SAY8 " <I>  - log - informacije"
     
     inkey(0)

   BoxC()

   RETURN


PROCEDURE k_f11()

   LOCAL cModul := PADR(gModul,6), cPredhodna := "N"
   LOCAL cCmd
   LOCAL GetList := {}

   IF is_in_eshell()
        Box(, 3, 60)
           @ box_x_koord() + 1, box_y_koord() + 2 SAY "Programski modul?" GET cModul ;
               VALID Trim(cModul) $ "POS#FIN#KALK#FAKT#OS#LD#VIRM#EPDV" PICT "@!"
           @ box_x_koord() + 2, box_y_koord() + 2 SAY "Predhodna godina D/N?" GET cPredhodna ;
               VALID cPredhodna $ "DN" PICT "@!" V
           READ
        BoxC()

        IF LastKey() == K_ESC
            RETURN
        ENDIF

        cCmd := "f18.start." + LOWER(TRIM(cModul)) + IIF( cPredhodna == "D", "_pg", "")
        // e.g. eShell cmd 'start.f18.fin_pg' 
        eshell_cmd( cCmd )
   ENDIF

   RETURN


PROCEDURE k_f12()

   IF is_in_eshell()
      IF Pitanje(, "Pokrenuti predhodnu godinu?", "N" ) == "D"
        // e.g. eShell cmd 'start.f18.fin_pg' 
        altd()
        eshell_cmd(  "f18.start." + LOWER(gModul) + "_pg")
      ENDIF
   ENDIF

   RETURN


PROCEDURE k_ctrl_f12()

   // eShell koristi da uradi shutdown aplikacije
   __Quit()   
   
   RETURN