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

FUNCTION ld_ispravka_kredita

   PARAMETERS cIdRadn, cIdKred, cNaOsnovu

   IF PCount() == 0
      cIdRadn := Space( LEN_IDRADNIK )
      cIdKRed := Space( _LK_ )
      cNaOsnovu := Space( 20 )
   ENDIF

   ld_otvori_tabele_kredita()

   // SELECT radkr
   // SET ORDER TO TAG "2"
   o_radkr_1rec()

   Box(, 19, 77 )
   ImeKol := {}
   AAdd( ImeKol, { "Godina", {|| Str( godina, 4, 0 ) } } )
   AAdd( ImeKol, { "Mjesec", {|| Str( mjesec, 2, 0 ) } } )
   AAdd( ImeKol, { "Iznos", {|| iznos } } )
   AAdd( ImeKol, { "Otplaceno", {|| placeno } } )
   AAdd( ImeKol, { "NaOsnovu", {|| naosnovu } } )
   Kol := {}
   FOR i := 1 TO Len( ImeKol )
      AAdd( Kol, i )
   NEXT

   set_cursor_on()

   @ box_x_koord() + 1, box_y_koord() + 2 SAY "KREDIT - pregled, ispravka"
   @ box_x_koord() + 2, box_y_koord() + 2 SAY "Radnik:   " GET cIdRadn  ;
      VALID {|| P_Radn( @cIdRadn ), SetPos( box_x_koord() + 2, box_y_koord() + 20 ), ;
      QQOut( Trim( radn->naz ) + " (" + Trim( radn->imerod ) + ") " + radn->ime ), ;
      P_Krediti( cIdRadn, @cIdKred, @cNaOsnovu ), .T. }

   @ box_x_koord() + 3, box_y_koord() + 2 SAY "Kreditor: " GET cIdKred  VALID P_Kred( @cIdKred, 3, 21 ) PICT "@!"
   @ box_x_koord() + 4, box_y_koord() + 2 SAY "Na osnovu:" GET cNaOsnovu PICT "@!"

   IF PCount() == 0
      READ
      ESC_BCR
   ELSE
      GetList := {}
   ENDIF

   cNaOsnovu := PadR( cNaOsnovu, Len( radkr->naosnovu ) )
   seek_radkr_2( cIdRadn, cIdKred, cNaOsnovu )

   BrowseKey( box_x_koord() + 6, box_y_koord() + 1, box_x_koord() + 19, box_y_koord() + 77, ImeKol, {| Ch | ld_krediti_key_handler( Ch ) }, "idradn+idkred+naosnovu=cidradn+cidkred+cnaosnovu", cIdRadn + cIdKred + cNaOsnovu, 2,, )

   BoxC()

   my_close_all_dbf()

   RETURN .T.


FUNCTION ld_krediti_key_handler( Ch )

   LOCAL cDn := "N"
   LOCAL nRet := DE_CONT
   LOCAL nRec := RecNo()
   LOCAL _placeno, _iznos, _rec
   LOCAL hParams

   SELECT radkr

   DO CASE

   CASE Ch == K_ENTER

      hRec := dbf_get_rec()

      _iznos := hRec[ "iznos" ]
      _placeno := hRec[ "placeno" ]

      Box(, 6, 70 )

      @ box_x_koord() + 1, box_y_koord() + 2 SAY8 "Ručna ispravka rate !"
      @ box_x_koord() + 3, box_y_koord() + 2 SAY "Iznos  " GET _iznos PICT gpici
      @ box_x_koord() + 4, box_y_koord() + 2 SAY "Placeno" GET _placeno PICT gpici

      cNaOsnovu2 := cNaOsnovu

      @ box_x_koord() + 6, box_y_koord() + 2 SAY "Na osnovu" GET cNaOsnovu2

      READ

      IF ( cNaOsnovu2 <> field->naosnovu ) .AND. Pitanje( , "Želite li promijeniti osnov kredita ? (D/N)", "N" ) == "D"

         seek_radkr_2( cIdRadn, cIdKred, cNaOsnovu )


         run_sql_query( "BEGIN" )
         // IF !f18_lock_tables( { "ld_radkr" }, .T. )
         // run_sql_query( "ROLLBACK" )
         // RETURN .F.
         // ENDIF


         DO WHILE !Eof() .AND. ( field->idradn + field->idkred + field->naosnovu ) == ( cIdRadn + cIdKred + cNaOsnovu )

            SKIP 1
            nRecK := RecNo()
            SKIP -1

            hRec := dbf_get_rec()
            hRec[ "naosnovu" ] := cNaOsnovu2

            update_rec_server_and_dbf( "ld_radkr", hRec, 1, "CONT" )

            GO ( nRecK )

         ENDDO


         hParams := hb_Hash()
         // hParams[ "unlock" ] := { "ld_radkr" }
         run_sql_query( "COMMIT", hParams )

      ENDIF

      READ

      BoxC()

      GO ( nRec )

      hRec := dbf_get_rec()
      hRec[ "naosnovu" ] := cNaOsnovu2
      hRec[ "placeno" ] := _placeno
      hRec[ "iznos" ] := _iznos

      update_rec_server_and_dbf( "ld_radkr", hRec, 1, "FULL" )

      log_write( "F18_DOK_OPER: ld korekcija kredita, rucna ispravka rate - radnik: " + cIdRadn + ", iznos: " + AllTrim( Str( radkr->placeno, 12, 2 ) ) + "/" + AllTrim( Str( radkr->iznos, 12, 2 ) ), 2 )

      SELECT radkr

      nRet := DE_REFRESH

   CASE Ch == K_CTRL_N
      nRet := DE_REFRESH
   CASE Ch == K_CTRL_T
      nRet := DE_REFRESH
   CASE Ch == K_CTRL_P
      PushWA()
      // StRjes(radkr->idradn,radkr->idkred,radkr->naosnovu)
      PopWA()
      nRet := DE_REFRESH
   CASE Ch == K_F10
      nRet := DE_REFRESH
   ENDCASE

   RETURN nRet
