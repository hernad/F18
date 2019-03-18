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

MEMVAR m_x, m_y
/*
 *  Import sifarnika partnera
 */

FUNCTION kalk_import_txt_partner()

   LOCAL cFFilt, lEdit

   PRIVATE cExpPath
   PRIVATE cImpFile

   cExpPath := get_liste_za_import_path()

   cFFilt := "p*.p??"

   IF get_file_list( cFFilt, cExpPath, @cImpFile ) == 0  // pregled fajlova za import, te setuj varijablu cImpFile
      RETURN .F.
   ENDIF

   IF fajl_get_broj_linija( cImpFile ) == 0 // provjeri da li je fajl za import prazan
      MsgBeep( "Odabrani fajl je prazan!#Prekid operacije !" )
      RETURN .F.
   ENDIF

   PRIVATE aDbf := {}
   PRIVATE aRules := {}


   set_adbf_kalk_imp_temp_for_partnere( @aDbf )

   import_txt_set_a_rules_partn( @aRules ) // setuj pravila upisa podataka u temp tabelu

   kalk_imp_txt_to_temp( aDbf, aRules, cImpFile ) // prebaci iz txt => temp tbl

   IF kalk_impt_txt_check_partnere() > 0
      IF Pitanje(, "Izvršiti import partnera (D/N)?", "D" ) == "N"
         MsgBeep( "Opcija prekinuta!" )
         RETURN .F.
      ENDIF
   ELSE
      MsgBeep( "Nema novih partnera za import !" )
      RETURN .F.
   ENDIF

   // ova opcija ipak i nije toliko dobra da se radi!
   //
   // lEdit := Pitanje(,"Izvrsiti korekcije postojecih podataka (D/N)?", "N") == "D"
   lEdit := .F.

   IF kalk_imp_temp_to_partn( lEdit ) == 0
      MsgBeep( "Operacija prekinuta!" )
      RETURN .F.
   ENDIF

   MsgBeep( "Operacija završena !" )

   kalk_imp_brisi_txt( cImpFile )

   RETURN .T.



FUNCTION kalk_import_txt_roba()

   LOCAL lEdit

   PRIVATE cExpPath
   PRIVATE cImpFile

   cExpPath := get_liste_za_import_path()

   cFFilt := "S*.S??"


   IF get_file_list( cFFilt, cExpPath, @cImpFile ) == 0 // pregled fajlova za import, te setuj varijablu cImpFile
      RETURN .F.
   ENDIF


   IF fajl_get_broj_linija( cImpFile ) == 0  // provjeri da li je fajl za import prazan
      MsgBeep( "Odabrani fajl je prazan!#Prekidam operaciju !" )
      RETURN .F.
   ENDIF

   PRIVATE aDbf := {}
   PRIVATE aRules := {} // setuj polja temp tabele u matricu aDbf
   set_adbf_roba( @aDbf ) // setuj pravila upisa podataka u temp tabelu
   import_txt_set_a_rules_roba( @aRules )


   kalk_imp_txt_to_temp( aDbf, aRules, cImpFile )  // prebaci iz txt => temp tbl

   IF kalk_imp_txt_check_roba() > 0
      IF Pitanje(, "Importovati nove cijene u šifarnika robe (D/N)?", "D" ) == "N"
         MsgBeep( "Opcija prekinuta!" )
         RETURN .F.
      ENDIF
   ELSE
      MsgBeep( "Nema novih stavki za import !" )
      RETURN .F.
   ENDIF

   lEdit := .F.

   IF !kalk_imp_temp_to_roba( lEdit )
      MsgBeep( "Operacija prekinuta!" )
      RETURN .F.
   ENDIF

   MsgBeep( "Operacija završena !" )

   kalk_imp_brisi_txt( cImpFile )

   RETURN .T.



STATIC FUNCTION kalk_imp_temp_to_roba()

   LOCAL cTmpSif, hRec, lOk := .T., hParams, lPromjena

// o_roba()
// o_sifk()
// o_sifv()

   SELECT kalk_imp_temp
   GO TOP

   IF  !begin_sql_tran_lock_tables( { "roba" } )
      MsgBeep( "roba sql lock neuspjesno !? STOP!" )
      RETURN .F.
   ENDIF

   Box(, 3, 60 )
   DO WHILE !Eof()

      cTmpSif := AllTrim( kalk_imp_temp->sifradob )

      IF find_roba_by_sifradob( cTmpSif )


         @ m_x + 1, m_y + 2 SAY "      ID: " + roba->id
         @ m_x + 2, m_y + 2 SAY "SIFRADOB: " + kalk_imp_temp->sifradob

         lPromjena := .F. // desila se promjena cijene

         hRec := dbf_get_rec()
         IF kalk_imp_temp->idpm == "001" // mjenja se VPC
            lPromjena :=  ( hRec[ "vpc" ] <> kalk_imp_temp->mpc )
            hRec[ "vpc" ] := kalk_imp_temp->mpc


         ELSEIF kalk_imp_temp->idpm == "002" // mjenja se VPC2
            lPromjena :=  ( hRec[ "vpc2" ] <> kalk_imp_temp->mpc )
            hRec[ "vpc2" ] := kalk_imp_temp->mpc


         ELSEIF kalk_imp_temp->idpm == "003"   // mjenja se MPC
            lPromjena :=  ( hRec[ "mpc" ] <> kalk_imp_temp->mpc )
            hRec[ "mpc" ] := kalk_imp_temp->mpc


         ENDIF

         IF lPromjena
            lOk := lOk .AND. update_rec_server_and_dbf( "roba", hRec, 1, "CONT" )
         ENDIF

      ENDIF


      SELECT kalk_imp_temp
      SKIP

   ENDDO

   BoxC()


   IF lOk
      hParams := hb_Hash()
      hParams[ "unlock" ] :=  { "roba" }
      run_sql_query( "COMMIT", hParams )
   ELSE
      run_sql_query( "ROLLBACK" )
      MsgBeep( "SQL roba transakcija neuspjesna !" )
   ENDIF

   RETURN .T.


   /*
    *     Setovanje pravila upisa zapisa u temp tabelu
    *   param: aRule - matrica pravila
    */

STATIC FUNCTION import_txt_set_a_rules_partn( aRule )

   // id
   AAdd( aRule, { "SUBSTR(cVar, 1, 6)" } )
   // naz
   AAdd( aRule, { "SUBSTR(cVar, 8, 25)" } )
   // ptt
   AAdd( aRule, { "SUBSTR(cVar, 34, 5)" } )
   // mjesto
   AAdd( aRule, { "SUBSTR(cVar, 40, 16)" } )
   // adresa
   AAdd( aRule, { "SUBSTR(cVar, 57, 24)" } )
   // ziror
   AAdd( aRule, { "SUBSTR(cVar, 82, 22)" } )
   // telefon
   AAdd( aRule, { "SUBSTR(cVar, 105, 12)" } )
   // fax
   AAdd( aRule, { "SUBSTR(cVar, 118, 12)" } )
   // idops
   AAdd( aRule, { "SUBSTR(cVar, 131, 4)" } )
   // rokpl
   AAdd( aRule, { "VAL(SUBSTR(cVar, 136, 5))" } )
   // porbr
   AAdd( aRule, { "SUBSTR(cVar, 143, 16)" } )
   // idbroj
   AAdd( aRule, { "SUBSTR(cVar, 160, 16)" } )
   // ustn
   AAdd( aRule, { "SUBSTR(cVar, 177, 20)" } )
   // brupis
   AAdd( aRule, { "SUBSTR(cVar, 198, 20)" } )
   // brjes
   AAdd( aRule, { "SUBSTR(cVar, 219, 20)" } )

   RETURN .T.



/*
  *  Provjerava i daje listu nepostojecih partnera pri importu liste partnera
*/
STATIC FUNCTION kalk_impt_txt_check_partnere()

   LOCAL i, aPomPart := kalk_imp_partn_exist( .T. )

   IF ( Len( aPomPart ) > 0 )

      start_print_editor()

      ?U "Lista nepostojećih partnera:"
      ? "----------------------------"
      ?
      FOR i := 1 TO Len( aPomPart )
         ? aPomPart[ i ]
      NEXT
      ?
      end_print_editor()

   ENDIF

   RETURN Len( aPomPart )



// --------------------------------------------------------------------------
// Provjerava i daje listu promjena na robi
// --------------------------------------------------------------------------
STATIC FUNCTION kalk_imp_txt_check_roba()

   LOCAL i, cLine, aPomRoba := {}
   LOCAL nCijena
   LOCAL aRet, cInd

   // o_roba()
   SELECT kalk_imp_temp
   GO TOP


   DO WHILE !Eof()

      IF find_roba_by_sifradob( Trim( kalk_imp_temp->sifradob ) )
         cInd := "1"
      ELSE
         cInd := "0"
      ENDIF
      AAdd( aPomRoba, { cInd, Trim( kalk_imp_temp->sifradob ), kalk_imp_temp->idpm, kalk_imp_temp->mpc, roba->id, roba->vpc, roba->vpc2, roba->mpc, kalk_imp_temp->naz } )


      SELECT kalk_imp_temp
      SKIP

   ENDDO


   IF ( Len( aPomRoba ) > 0 )

      START PRINT EDITOR

      ?U "Lista promjena u šifarniku robe:"
      ?U "---------------------------------------------------------------------------------"
      ?U "šifraDob    naziv                          TIP       stara cijena -> nova cijena "
      ?U "----------------------------------------------------------------------------------"
      ?U

      FOR i := 1 TO Len( aPomRoba )


         cLine := aPomRoba[ i, 2 ]
         cLine += " " + aPomRoba[ i, 9 ]

         IF aPomRoba[ i, 1 ] == "1"

            IF aPomRoba[ i, 3 ] == "001"
               nCijena := aPomRoba[ i, 6 ] // vpc
               cLine += " VPC "

            ELSEIF aPomRoba[ i, 3 ] == "002"
               nCijena := aPomRoba[ i, 7 ]  // vpc2
               cLine += " VP2 "

            ELSEIF aPomRoba[ i, 3 ] == "003"
               nCijena := aPomRoba[ i, 8 ] // mpc
               cLine += " MPC "

            ENDIF

            cLine += Str( nCijena, 12, 2 )
            cLine += Str( aPomRoba[ i, 4 ], 12, 2 )

            IF !( nCijena == aPomRoba[ i, 4 ] ) // ako je cijena txt ista kao sifarnik, ne prikazuj
               ? cLine
               // ?? " x"
            ENDIF

         ELSE
            ? cLine, " ovog artikla nema u sifarniku !"
         ENDIF


      NEXT

      ?

      FF
      ENDPRINT

   ENDIF

   RETURN Len( aPomRoba )








/*
    *     kopira podatke iz pomocne tabele u tabelu PARTN
    *   param: lEditOld - ispraviti stare zapise
*/

STATIC FUNCTION kalk_imp_temp_to_partn( lEditOld )

   LOCAL hRec, lNovi, cTmpPar

   // o_partner()
   // o_sifk()
   // o_sifv()

   SELECT kalk_imp_temp
   GO TOP

   lNovi := .F.

   DO WHILE !Eof()


      SELECT partn // pronadji partnera
      cTmpPar := AllTrim( kalk_imp_temp->idpartner )
      SEEK cTmpPar

      // ako si nasao:
      // 1. ako je lEditOld .t. onda ispravi postojeci
      // 2. ako je lEditOld .f. onda preskoci
      IF Found()
         IF !lEditOld
            SELECT kalk_imp_temp
            SKIP
            LOOP
         ENDIF
         lNovi := .F.
      ELSE
         lNovi := .T.
      ENDIF


      SELECT partn // dodaj zapis u partn

      IF lNovi
         APPEND BLANK
      ENDIF

      IF !lNovi .AND. !lEditOld
         SELECT kalk_imp_temp
         SKIP
         LOOP
      ENDIF

      hRec := dbf_get_rec()

      hRec[ "id" ] := kalk_imp_temp->idpartner
      cNaz := kalk_imp_temp->naz
      hRec[ "naz" ] := KonvZnWin( @cNaz, "8" )
      hRec[ "ptt" ] := kalk_imp_temp->ptt
      cMjesto := kalk_imp_temp->mjesto
      hRec[ "mjesto" ] := KonvZnWin( @cMjesto, "8" )
      cAdres := kalk_imp_temp->adresa
      hRec[ "adresa" ] := KonvZnWin( @cAdres, "8" )
      hRec[ "ziror" ] := kalk_imp_temp->ziror
      hRec[ "telefon" ] := kalk_imp_temp->telefon
      hRec[ "fax" ] := kalk_imp_temp->fax
      hRec[ "idops" ] := kalk_imp_temp->idops

      update_rec_server_and_dbf( Alias(), hRec, 1, "FULL" )

      // ubaci --vezne-- podatke i u sifK tabelu
      USifK( "PARTN", "ROKP", kalk_imp_temp->idpartner, kalk_imp_temp->rokpl )

      // USifK( "PARTN", "PORB", kalk_imp_temp->idpartner, kalk_imp_temp->porbr )

      // USifK( "PARTN", "REGB", kalk_imp_temp->idpartner, kalk_imp_temp->idbroj )
      // USifK( "PARTN", "USTN", kalk_imp_temp->idpartner, kalk_imp_temp->ustn )

      /*
      USifK( "PARTN", "BRUP", kalk_imp_temp->idpartner, kalk_imp_temp->brupis )
      USifK( "PARTN", "BRJS", kalk_imp_temp->idpartner, kalk_imp_temp->brjes )
      */

      SELECT kalk_imp_temp
      SKIP
   ENDDO

   RETURN 1






// ---------------------------------------------
// pravila za import tabele robe
// ---------------------------------------------
STATIC FUNCTION import_txt_set_a_rules_roba( aRule )

   // idpm
   AAdd( aRule, { "SUBSTR(cVar, 1, 3)" } )
   // datum
   AAdd( aRule, { "SUBSTR(cVar, 5, 10)" } )
   // sifra dobavljaca
   AAdd( aRule, { "SUBSTR(cVar, 16, 6)" } )
   // naziv
   AAdd( aRule, { "SUBSTR(cVar, 22, 30)" } )
   // mpc
   AAdd( aRule, { "VAL( STRTRAN( SUBSTR(cVar, 53, 10), ',', '.' ) )" } )

   RETURN .T.


/*
       *     Set polja tabele partner
       *   param: aDbf - matrica sa def.polja
*/

STATIC FUNCTION set_adbf_kalk_imp_temp_for_partnere( aDbf )

   AAdd( aDbf, { "idpartner", "C", 6, 0 } )
   AAdd( aDbf, { "naz", "C", 25, 0 } )
   AAdd( aDbf, { "ptt", "C", 5, 0 } )
   AAdd( aDbf, { "mjesto", "C", 16, 0 } )
   AAdd( aDbf, { "adresa", "C", 24, 0 } )
   AAdd( aDbf, { "ziror", "C", 22, 0 } )
   AAdd( aDbf, { "telefon", "C", 12, 0 } )
   AAdd( aDbf, { "fax", "C", 12, 0 } )
   AAdd( aDbf, { "idops", "C", 4, 0 } )
   AAdd( aDbf, { "rokpl", "N", 5, 0 } )
   AAdd( aDbf, { "porbr", "C", 16, 0 } )
   AAdd( aDbf, { "idbroj", "C", 16, 0 } )
   AAdd( aDbf, { "ustn", "C", 20, 0 } )
   AAdd( aDbf, { "brupis", "C", 20, 0 } )
   AAdd( aDbf, { "brjes", "C", 20, 0 } )

   RETURN .T.



// -------------------------------------
// matrica sa strukturom
// tabele ROBA
// -------------------------------------
STATIC FUNCTION set_adbf_roba( aDbf )

   AAdd( aDbf, { "idpm", "C", 3, 0 } )
   AAdd( aDbf, { "datum", "C", 10, 0 } )
   AAdd( aDbf, { "sifradob", "C", 10, 0 } )
   AAdd( aDbf, { "naz", "C", 30, 0 } )
   AAdd( aDbf, { "mpc", "N", 15, 5 } )

   RETURN .T.
