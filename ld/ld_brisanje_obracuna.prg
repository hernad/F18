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



FUNCTION ld_brisanje_obr()

   LOCAL _opc := {}
   LOCAL _opcexe := {}
   LOCAL _izbor := 1

   AAdd( _opc, "1. brisanje obračuna za jednog radnika       " )
   AAdd( _opcexe, {|| ld_brisi_radnika() } )
   AAdd( _opc, "2. brisanje obračuna za jedan mjesec   " )
   AAdd( _opcexe, {|| BrisiMjesec() } )
   AAdd( _opc, "3. totalno brisanje radnika iz evidencije" )
   AAdd( _opcexe, {|| TotBrisRadn() } )

   f18_menu( "bris", .F., _izbor, _opc, _opcexe )

   RETURN .T.


FUNCTION ld_brisi_radnika()

   LOCAL nTrec
   LOCAL cIdRadn
   LOCAL nMjesec
   LOCAL cIdRj
   LOCAL fnovi
   LOCAL _rec
   LOCAL hParams
   LOCAL cRadnikObracun

   nUser := 001
   o_ld_radn()
   // select_o_ld()


   lLogBrRadn := .F.


   DO WHILE .T.

      cIdRadn := Space( LEN_IDRADNIK )
      cIdRj := gLDRadnaJedinica
      nMjesec := ld_tekuci_mjesec()
      nGodina := ld_tekuca_godina()
      cObracun := ld_broj_obracuna()

      Box(, 4, 60 )
      @ box_x_koord() + 1, box_y_koord() + 2 SAY "Radna jedinica: "
      QQOUTC( cIdRJ, "N/W" )
      @ box_x_koord() + 2, box_y_koord() + 2 SAY "Mjesec: "
      QQOUTC( Str( nMjesec, 2, 0 ), "N/W" )
      @ box_x_koord() + 2, Col() + 2 SAY "Obracun: "
      QQOUTC( cObracun, "N/W" )
      @ box_x_koord() + 3, box_y_koord() + 2 SAY "Godina: "
      QQOUTC( Str( nGodina, 4, 0 ), "N/W" )

      @ box_x_koord() + 4, box_y_koord() + 2 SAY "Radnik" GET cIdRadn VALID {|| cIdRadn $ "XXXXXX" .OR. P_Radn( @cIdRadn ), SetPos( box_x_koord() + 2, box_y_koord() + 20 ), QQOut( Trim( radn->naz ) + " (" + Trim( radn->imerod ) + ") " + radn->ime ), .T. }

      READ
      ESC_BCR
      BoxC()

      IF cIdRadn <> "XXXXXX"

         seek_ld( cIdRj, nGodina, nMjesec, cObracun, cIdRadn )

         cRadnikObracun := cIdRadn + " : " + Str( nMjesec, 2, 0 ) + "/" + Str( nGodina, 4, 0 ) + "/" + cObracun

         IF !Eof()

            IF Pitanje(, "Sigurno želite izbrisati " + cRadnikObracun + " ?!", "N" ) == "D"

               _rec := dbf_get_rec()
               delete_rec_server_and_dbf( "ld_ld", _rec, 1, "FULL" )

               MsgBeep( "Izbrisan obračun za radnika: " + cRadnikObracun + "  !" )


            ENDIF
         ELSE
            Msg( "Podatak ne postoji !", 4 )
         ENDIF

      ELSE
         SELECT ld
         SET ORDER TO 0
         IF FLock()

            GO TOP

            Postotak( 1, RecCount(), "Ukloni 0 zapise" )

            run_sql_query( "BEGIN" )

            IF !f18_lock_tables( { "ld_ld" }, .T. )
               run_sql_query( "ROLLBACK" )
               Postotak( 0 )
               RETURN .F.
            ENDIF

            DO WHILE !Eof()

               nPom := 0
               _rec := dbf_get_rec()

               FOR i := 1 TO cLDPolja
                  cPom := PadL( AllTrim( Str( i ) ), 2, "0" )
                  nPom += ( Abs( _I&cPom ) + Abs( _S&cPom ) )
                  // ako su sve nule
               NEXT

               IF ( Round( nPom, 5 ) = 0 )
                  delete_rec_server_and_dbf( "ld_ld", _rec, 1, "CONT" )
               ENDIF

               Postotak( 2, RecNo() )

               SKIP

            ENDDO

            Postotak( 0 )

            hParams := hb_Hash()
            hParams[ "unlock" ] := { "ld_ld" }
            run_sql_query( "COMMIT", hParams )

         ELSE
            MsgBeep( "Neko već koristi datoteku LD !" )
         ENDIF
      ENDIF

      SELECT ld
      USE
   ENDDO

   my_close_all_dbf()

   RETURN .T.



FUNCTION BrisiMjesec()

   LOCAL nMjesec
   LOCAL cIdRj
   LOCAL fnovi
   LOCAL _rec

   nUser := 001

   o_ld_radn()

   lLogBrMjesec := .F.


   DO WHILE .T.

      // select_o_ld()

      cIdRadn := Space( LEN_IDRADNIK )
      cIdRj := gLDRadnaJedinica
      nMjesec := ld_tekuci_mjesec()
      nGodina := ld_tekuca_godina()
      cObracun := gObracun

      Box(, 4, 60 )
      @ box_x_koord() + 1, box_y_koord() + 2 SAY "Radna jedinica: " GET cIdRJ
      @ box_x_koord() + 2, box_y_koord() + 2 SAY "Mjesec: "  GET nMjesec PICT "99"
      @ box_x_koord() + 2, Col() + 2 SAY "Obracun: " GET cObracun WHEN ld_help_broj_obracuna( .F., cObracun ) VALID ld_valid_obracun( .F., cObracun )
      @ box_x_koord() + 3, box_y_koord() + 2 SAY "Godina: "  GET nGodina PICT "9999"
      READ
      ClvBox()
      ESC_BCR
      BoxC()

      IF Pitanje(, "Sigurno zelite izbrisati sve podatke za RJ za ovaj mjesec !?", "N" ) == "N"
         my_close_all_dbf()
         RETURN .F.
      ENDIF

      MsgO( "Sacekajte, brisem podatke...." )

      seek_ld( cIdRj, nGodina, nMjesec, ld_broj_obracuna() )

      IF !Eof()
         _rec := dbf_get_rec()
         delete_rec_server_and_dbf( "ld_ld", _rec, 2, "FULL" )
      ENDIF

      MsgBeep( "Obracun za " + Str( nMjesec, 2 ) + " mjesec izbrisani !" )

      MsgC()
      EXIT

   ENDDO

   my_close_all_dbf()

   RETURN
