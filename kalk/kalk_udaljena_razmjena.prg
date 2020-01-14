/*
 * This file is part of the bring.out knowhow ERP, a free and open source
 * ERP software suite,
 * Copyright (c) 1994-2018 by bring.out d.o.o Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including knowhow ERP specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_knowhow.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */

#include "f18.ch"

STATIC s_cImportDbfPath
STATIC s_cExportDbfPath
STATIC s_cImportZipName
STATIC s_cExportZipName

FIELD id

FUNCTION kalk_udaljena_razmjena_podataka()

   LOCAL aOpc := {}
   LOCAL aOpcExe := {}
   LOCAL nIzbor := 1

   s_cImportDbfPath := my_home() + "export_dbf" + SLASH
   s_cExportDbfPath := my_home() + "export_dbf" + SLASH
   s_cImportZipName := "kalk_exp.zip"
   s_cExportZipName := "kalk_exp.zip"

   AAdd( aOpc, "1. => kalk export podataka               " )
   AAdd( aOpcExe, {|| kalk_export_start() } )

   AAdd( aOpc, "2. <= kalk import podataka    " )
   AAdd( aOpcExe, {|| kalk_import_start() } )

   f18_menu( "razmjena", .F., nIzbor, aOpc, aOpcExe )

   my_close_all_dbf()

   RETURN .T.



STATIC FUNCTION kalk_export_start()

   LOCAL _vars := hb_Hash()
   LOCAL _exported_rec
   LOCAL _error
   LOCAL _a_data := {}

   // uslovi exporta
   IF !_vars_export( @_vars )
      RETURN .F.
   ENDIF

   // pobrisi u folderu tmp fajlove ako postoje
   delete_exp_files( s_cExportDbfPath, "kalk" ) // pobrisi u folderu tmp fajlove ako postoje

   _exported_rec := kalk_export( _vars, @_a_data )  // exportuj podatake

   // zatvori sve tabele prije operacije pakovanja
   my_close_all_dbf()

   // arhiviraj podatke
   IF _exported_rec > 0

      _error := udaljenja_razmjena_compress_files( "kalk", s_cExportDbfPath ) // kompresuj ih u zip fajl za prenos

      // sve u redu
      IF _error == 0

         // pobrisi fajlove razmjene
         delete_exp_files( s_cExportDbfPath, "kalk" )

         // otvori folder sa exportovanim podacima
         open_folder( s_cExportDbfPath )

      ENDIF

   ENDIF

   // vrati se na glavni direktorij
   DirChange( my_home() )

   IF ( _exported_rec > 0 )

      MsgBeep( "Exportovao " + AllTrim( Str( _exported_rec ) ) + " dokumenta." )
      print_imp_exp_report( _a_data )

   ENDIF

   my_close_all_dbf()

   RETURN .T.


STATIC FUNCTION kalk_import_start()

   LOCAL nImportovanoZapisa
   LOCAL _vars := hb_Hash()
   LOCAL _imp_file
   LOCAL _a_data := {}
   LOCAL _imp_path := fetch_metric( "kalk_import_path", my_user(), PadR( "", 300 ) )
   LOCAL GetList := {}

   Box(, 1, 70 )
   @ box_x_koord() + 1, box_y_koord() + 2 SAY "import path:" GET _imp_path PICT "@S50"
   READ
   BoxC()

   IF LastKey() == K_ESC
      RETURN .F.
   ENDIF

   s_cImportDbfPath := AllTrim( _imp_path ) // snimi u parametre
   set_metric( "kalk_import_path", my_user(), _imp_path )


   _imp_file := get_import_file( "kalk", s_cImportDbfPath ) // import fajl iz liste

   IF _imp_file == NIL .OR. Empty( _imp_file )
      MsgBeep( "Nema odabranog import fajla !?" )
      RETURN .F.
   ENDIF

   IF !_vars_import( @_vars ) // parametri
      RETURN .F.
   ENDIF

   IF !import_file_exist( _imp_file )
      MsgBeep( "import fajl ne postoji !? prekidam operaciju" )
      RETURN .F.
   ENDIF


   IF razmjena_decompress_files( _imp_file, s_cImportDbfPath, s_cImportZipName ) <> 0 // dekompresovanje podataka
      // ako je bilo greske
      RETURN .F.
   ENDIF

#ifdef __PLATFORM__UNIX
   set_file_access( s_cImportDbfPath )
#endif


   nImportovanoZapisa := kalk_import_podataka( _vars, @_a_data )

   my_close_all_dbf()
   delete_exp_files( s_cImportDbfPath, "kalk" )  // brisi fajlove importa

   IF ( nImportovanoZapisa > 0 ) // nakon uspjesnog importa

      IF Pitanje(, "Pobrisati obrađeni zip fajl razmjene ?", "D" ) == "D"
         delete_zip_files( _imp_file )
      ENDIF

      MsgBeep( "Importovao " + AllTrim( Str( nImportovanoZapisa ) ) + " dokumenta." )
      print_imp_exp_report( _a_data ) // printaj izvjestaj

   ENDIF


   DirChange( my_home() ) // vrati se na home direktorij nakon svega

   RETURN .T.


// -------------------------------------------
// uslovi exporta dokumenta
// -------------------------------------------
STATIC FUNCTION _vars_export( hParams )

   LOCAL _ret := .F.
   LOCAL _dat_od := fetch_metric( "kalk_export_datum_od", my_user(), Date() - 30 )
   LOCAL _dat_do := fetch_metric( "kalk_export_datum_do", my_user(), Date() )
   LOCAL _konta := fetch_metric( "kalk_export_lista_konta", my_user(), PadR( "1320;", 200 ) )
   LOCAL _vrste_dok := fetch_metric( "kalk_export_vrste_dokumenata", my_user(), PadR( "10;11;", 200 ) )
   LOCAL cExportSifarnika := fetch_metric( "kalk_export_sifrarnik", my_user(), "D" )
   LOCAL _exp_path := fetch_metric( "kalk_export_path", my_user(), PadR( "", 300 ) )
   LOCAL nX := 1
   LOCAL GetList := {}

   IF Empty( AllTrim( _exp_path ) )
      _exp_path := PadR( s_cExportDbfPath, 300 )
   ENDIF

   Box(, 15, 70 )

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "*** Uslovi exporta dokumenata"

   ++ nX
   ++ nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Vrste dokumenata:" GET _vrste_dok PICT "@S40"

   ++ nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Datumski period od" GET _dat_od
   @ box_x_koord() + nX, Col() + 1 SAY "do" GET _dat_do

   nX += 2
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Uzeti u obzir sljedeća konta:" GET _konta PICT "@S30"

   nX += 2
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Eksportovati šifarnike (D/N/F) ?" GET cExportSifarnika PICT "@!" VALID cExportSifarnika $ "DNF"

   nX += 2
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Eksport lokacija:" GET _exp_path PICT "@S50"

   READ

   BoxC()

   // snimi parametre
   IF LastKey() <> K_ESC

      _ret := .T.

      set_metric( "kalk_export_datum_od", my_user(), _dat_od )
      set_metric( "kalk_export_datum_do", my_user(), _dat_do )
      set_metric( "kalk_export_lista_konta", my_user(), _konta )
      set_metric( "kalk_export_vrste_dokumenata", my_user(), _vrste_dok )
      set_metric( "kalk_export_sifrarnik", my_user(), cExportSifarnika )
      set_metric( "kalk_export_path", my_user(), _exp_path )

      // export path, set static var
      s_cExportDbfPath := AllTrim( _exp_path )

      hParams[ "datum_od" ] := _dat_od
      hParams[ "datum_do" ] := _dat_do
      hParams[ "konta" ] := _konta
      hParams[ "vrste_dok" ] := _vrste_dok
      hParams[ "export_sif" ] := cExportSifarnika

   ENDIF

   RETURN _ret



// -------------------------------------------
// uslovi importa dokumenta
// -------------------------------------------
STATIC FUNCTION _vars_import( hParams )

   LOCAL _ret := .F.
   LOCAL _dat_od := fetch_metric( "kalk_import_datum_od", my_user(), CToD( "" ) )
   LOCAL _dat_do := fetch_metric( "kalk_import_datum_do", my_user(), CToD( "" ) )
   LOCAL _konta := fetch_metric( "kalk_import_lista_konta", my_user(), PadR( "", 200 ) )
   LOCAL _vrste_dok := fetch_metric( "kalk_import_vrste_dokumenata", my_user(), PadR( "", 200 ) )
   LOCAL _zamjeniti_dok := fetch_metric( "kalk_import_zamjeniti_dokumente", my_user(), "N" )
   LOCAL lZamijenitiSifre := fetch_metric( "kalk_import_zamjeniti_sifre", my_user(), "N" )
   LOCAL _iz_fmk := fetch_metric( "kalk_import_iz_fmk", my_user(), "N" )
   LOCAL _imp_path := fetch_metric( "kalk_import_path", my_user(), PadR( "", 300 ) )
   LOCAL nX := 1
   LOCAL cPript := fetch_metric( "kalk_import_pript", my_user(), "N" )
   LOCAL GetList := {}

   IF Empty( AllTrim( _imp_path ) )
      _imp_path := PadR( s_cImportDbfPath, 300 )
   ENDIF

   Box(, 15, 70 )

   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "*** Uslovi importa dokumenata"
   ++ nX
   ++ nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Vrste dokumenata (prazno-sve):" GET _vrste_dok PICT "@S30"
   ++ nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Datumski period od" GET _dat_od
   @ box_x_koord() + nX, Col() + 1 SAY8 "do" GET _dat_do
   ++ nX
   ++ nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Uzeti u obzir sljedeća konta:" GET _konta PICT "@S30"
   ++ nX
   ++ nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Zamijeniti postojeće dokumente novim (D/N):" GET _zamjeniti_dok PICT "@!" VALID _zamjeniti_dok $ "DN"

   ++ nX

   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Zamijeniti postojeće šifre novim (D/N):" GET lZamijenitiSifre PICT "@!" VALID lZamijenitiSifre $ "DN"

//   ++ nX
//   ++ nX
//   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Import fajl dolazi iz FMK (D/N) ?" GET _iz_fmk PICT "@!" VALID _iz_fmk $ "DN"
   ++ nX
   ++ nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Lokacija importa:" GET _imp_path PICT "@S50"

   nX += 2
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "pript->obrada->kalk:" GET cPript PICT "@!" VALID cPript $ "DN"

   READ

   BoxC()

   // snimi parametre
   IF LastKey() <> K_ESC

      _ret := .T.
      set_metric( "kalk_import_datum_od", my_user(), _dat_od )
      set_metric( "kalk_import_datum_do", my_user(), _dat_do )
      set_metric( "kalk_import_lista_konta", my_user(), _konta )
      set_metric( "kalk_import_vrste_dokumenata", my_user(), _vrste_dok )
      set_metric( "kalk_import_zamjeniti_dokumente", my_user(), _zamjeniti_dok )
      set_metric( "kalk_import_zamjeniti_sifre", my_user(), lZamijenitiSifre )
      set_metric( "kalk_import_iz_fmk", my_user(), _iz_fmk )
      set_metric( "kalk_import_path", my_user(), _imp_path )
      set_metric( "kalk_import_pript", my_user(), cPript )

      // set static var
      s_cImportDbfPath := AllTrim( _imp_path )

      hParams[ "datum_od" ] := _dat_od
      hParams[ "datum_do" ] := _dat_do
      hParams[ "konta" ] := _konta
      hParams[ "vrste_dok" ] := _vrste_dok
      hParams[ "zamjeniti_dokumente" ] := _zamjeniti_dok
      hParams[ "zamjeniti_sifre" ] := lZamijenitiSifre
      hParams[ "import_iz_fmk" ] := _iz_fmk
      hParams[ "pript" ] := ( cPript == "D" )

   ENDIF

   RETURN _ret



STATIC FUNCTION kalk_export( hParams, a_details )

   LOCAL _ret := 0
   LOCAL cIdFirma, cIdVd, cBrDok
   LOCAL aDoksRec
   LOCAL nCnt := 0
   LOCAL _dat_od, _dat_do, _konta, _vrste_dok, cExportSif
   LOCAL cUslMagacinKonto, cUslProdKonto
   LOCAL _id_partn, _p_konto, _m_konto
   LOCAL cIdRoba
   LOCAL aDokDetail
   LOCAL hRec

   _dat_od := hParams[ "datum_od" ]
   _dat_do := hParams[ "datum_do" ]
   _konta := AllTrim( hParams[ "konta" ] )
   _vrste_dok := AllTrim( hParams[ "vrste_dok" ] )
   cExportSif := AllTrim( hParams[ "export_sif" ] )

   _cre_exp_tbls( s_cExportDbfPath ) // kreiraj tabele exporta
   kalk_o_exp_tabele( s_cExportDbfPath ) // otvori export tabele za pisanje podataka

   kalk_o_tabele()

   Box(, 2, 65 )

   @ box_x_koord() + 1, box_y_koord() + 2 SAY "... export kalk dokumenata u toku"

   find_kalk_doks_by_tip_datum( self_organizacija_id(), NIL, _dat_od, _dat_do )

   DO WHILE !Eof()

      cIdFirma := field->idfirma
      cIdVd := field->idvd
      cBrDok := field->brdok
      _id_partn := field->idpartner
      _p_konto := field->pkonto
      _m_konto := field->mkonto

      IF !Empty( _konta ) // lista konta

         cUslMagacinKonto := Parsiraj( AllTrim( _konta ), "mkonto" )
         cUslProdKonto := Parsiraj( AllTrim( _konta ), "pkonto" )
         IF !( &cUslMagacinKonto )
            IF !( &cUslProdKonto )
               SKIP
               LOOP
            ENDIF
         ENDIF

      ENDIF

      IF !Empty( _vrste_dok ) // lista dokumenata
         IF !( field->idvd $ _vrste_dok )
            SKIP
            LOOP
         ENDIF
      ENDIF


      aDoksRec := dbf_get_rec()   // ako je sve zadovoljeno dodaj zapis u tabelu e_doks

      aDokDetail := hb_Hash()
      aDokDetail[ "dokument" ] := aDoksRec[ "idfirma" ] + "-" + aDoksRec[ "idvd" ] + "-" + aDoksRec[ "brdok" ]
      aDokDetail[ "idpartner" ] := aDoksRec[ "idpartner" ]
      aDokDetail[ "idkonto" ] := ""
      aDokDetail[ "partner" ] := ""
      aDokDetail[ "iznos" ] := 0
      aDokDetail[ "datum" ] := aDoksRec[ "datdok" ]
      aDokDetail[ "tip" ] := "export"

      // dodaj u detalje
      export_import_add_to_details( @a_details, aDokDetail )

      SELECT e_doks
      APPEND BLANK
      dbf_update_rec( aDoksRec )

      ++ nCnt
      @ box_x_koord() + 2, box_y_koord() + 2 SAY PadR(  PadL( AllTrim( Str( nCnt ) ), 6 ) + ". " + "dokument: " + cIdFirma + "-" + cIdVd + "-" + AllTrim( cBrDok ), 50 )

      // dodaj zapis i u tabelu e_kalk
      find_kalk_by_broj_dokumenta( cIdFirma, cIdVd, cBrDok )

      DO WHILE !Eof() .AND. field->idfirma == cIdFirma .AND. field->idvd == cIdVd .AND. field->brdok == cBrDok

         cIdRoba := field->idroba

         // upisi zapis u tabelu e_kalk
         aDoksRec := dbf_get_rec()
         SELECT e_kalk
         APPEND BLANK
         dbf_update_rec( aDoksRec )


         IF select_o_roba( cIdRoba ) .AND. cExportSif == "D"
            hRec := dbf_get_rec()
            SELECT e_roba
            SET ORDER TO TAG "ID"
            SEEK cIdRoba
            IF !Found()
               APPEND BLANK
               dbf_update_rec( hRec )
               razmjena_fill_sifk_sifv( "ROBA", cIdRoba ) // napuni i sifk, sifv parametre
            ENDIF
         ENDIF


         SELECT kalk
         SKIP

      ENDDO

      IF select_o_partner( _id_partn ) .AND. cExportSif == "D"
         aDoksRec := dbf_get_rec()
         SELECT e_partn
         SET ORDER TO TAG "ID"
         SEEK _id_partn // e_partn
         IF !Found()
            APPEND BLANK
            dbf_update_rec( aDoksRec )
            razmjena_fill_sifk_sifv( "PARTN", _id_partn ) // napuni i sifk, sifv parametre
         ENDIF
      ENDIF



      IF select_o_konto( _m_konto ) .AND. cExportSif == "D"
         aDoksRec := dbf_get_rec()
         SELECT e_konto
         SET ORDER TO TAG "ID"
         SEEK _m_konto
         IF !Found()
            APPEND BLANK
            dbf_update_rec( aDoksRec )
         ENDIF
      ENDIF

      // zatim P_KONTO
      IF select_o_konto( _p_konto ) .AND. cExportSif == "D"
         aDoksRec := dbf_get_rec()
         SELECT e_konto
         SET ORDER TO TAG "ID"
         SEEK _p_konto
         IF !Found()
            APPEND BLANK
            dbf_update_rec( aDoksRec )
         ENDIF
      ENDIF

      SELECT kalk_doks
      SKIP

   ENDDO


   IF cExportSif == "F" // full export sifarnika robe

      o_roba()
      nCnt := 0
      DO WHILE !Eof()
         hRec := dbf_get_rec()
         SELECT e_roba
         SET ORDER TO TAG "ID"
         APPEND BLANK
         dbf_update_rec( hRec )
         @ box_x_koord() + 2, box_y_koord() + 2 SAY PadR(  PadL( AllTrim( Str( ++nCnt ) ), 6 ) + ". " + "roba: " + hRec[ "id" ] , 50 )
         razmjena_fill_sifk_sifv( "ROBA", hRec[ "id" ] ) // napuni i sifk, sifv parametre

         SELECT ROBA
         SKIP
      ENDDO

      o_partner()
      DO WHILE !Eof()
         hRec := dbf_get_rec()
         SELECT e_partn
         SET ORDER TO TAG "ID"
         APPEND BLANK
         dbf_update_rec( hRec )
         @ box_x_koord() + 2, box_y_koord() + 2 SAY PadR(  PadL( AllTrim( Str( ++nCnt ) ), 6 ) + ". " + "partn: " + hRec[ "id" ] , 50 )
         razmjena_fill_sifk_sifv( "PARTN", hRec[ "id" ] ) // napuni i sifk, sifv parametre
         SELECT PARTN
         SKIP
      ENDDO

   ENDIF

   BoxC()

   IF ( nCnt > 0 )
      _ret := nCnt
   ENDIF

   RETURN _ret




STATIC FUNCTION kalk_import_podataka( hParams, a_details )

   LOCAL _ret := 0
   LOCAL cIdFirma, cIdVd, cBrDok
   LOCAL aDoksRec
   LOCAL nCnt := 0
   LOCAL _dat_od, _dat_do, _konta, _vrste_dok, _zamjeniti_dok, lZamijenitiSifre, _iz_fmk
   LOCAL cUslMagacinKonto, cUslProdKonto
   LOCAL _roba_id, _partn_id, _konto_id
   LOCAL _sif_exist
   LOCAL _fmk_import := .F.
   LOCAL nRedniRbroj := 0
   LOCAL _total_doks := 0
   LOCAL _total_kalk := 0
   LOCAL nGlavniBrojac := 0
   LOCAL aDokDetail
   LOCAL lOk := .T.
   LOCAL hRec
   LOCAL lFullTransaction

   _dat_od := hParams[ "datum_od" ]
   _dat_do := hParams[ "datum_do" ]
   _konta := hParams[ "konta" ]
   _vrste_dok := hParams[ "vrste_dok" ]
   _zamjeniti_dok := hParams[ "zamjeniti_dokumente" ]
   lZamijenitiSifre := hParams[ "zamjeniti_sifre" ]
   _iz_fmk := hParams[ "import_iz_fmk" ]


   IF _iz_fmk == "D"
      _fmk_import := .T.
   ENDIF

   kalk_o_exp_tabele( s_cImportDbfPath, _fmk_import )
   kalk_o_tabele()

   SELECT e_doks
   _total_doks := RECCOUNT2()

   SELECT e_kalk
   _total_kalk := RECCOUNT2()


   IF hParams[ "pript" ]
      IF pitanje(, "izbrisati tabele pripreme fin_pripr, kalk_pripr, pript ?", "D" ) == "N"
         RETURN .F.
      ENDIF
      select_o_fin_pripr()
      my_dbf_zap()
      USE
      select_o_kalk_pripr()
      my_dbf_zap()
      USE
      select_o_kalk_pript()
      my_flock()
      my_dbf_zap()

   ELSE
      o_kalk()   // za azuriranje
      o_kalk_doks() // za azuriranje
      run_sql_query( "BEGIN" )
      IF !f18_lock_tables( { "kalk_kalk", "kalk_doks" }, .T. )
         run_sql_query( "ROLLBACK" )
         MsgBeep( "Ne mogu zaključati tabele !#Prekidam operaciju." )
         RETURN nCnt
      ENDIF

   ENDIF

   SELECT e_doks
   SET ORDER TO TAG "1"
   GO TOP

   Box(, 3, 70 )

   @ box_x_koord() + 1, box_y_koord() + 2 SAY PadR( "... import kalk dokumenata u toku ", 69 ) COLOR f18_color_i()
   @ box_x_koord() + 2, box_y_koord() + 2 SAY "broj zapisa doks/" + AllTrim( Str( _total_doks ) ) + ", kalk/" + AllTrim( Str( _total_kalk ) )

   DO WHILE !Eof()

      cIdFirma := field->idfirma
      cIdVd := field->idvd
      cBrDok := field->brdok
      _dat_dok := field->datdok

      IF _dat_od <> CToD( "" )
         IF field->datdok < _dat_od
            SELECT e_doks
            SKIP
            LOOP
         ENDIF
      ENDIF

      IF _dat_do <> CToD( "" )
         IF field->datdok > _dat_do
            SELECT e_doks
            SKIP
            LOOP
         ENDIF
      ENDIF

      IF !Empty( _konta )

         cUslMagacinKonto := Parsiraj( AllTrim( _konta ), "mkonto" )
         cUslProdKonto := Parsiraj( AllTrim( _konta ), "pkonto" )

         IF !( &cUslMagacinKonto )
            IF !( &cUslProdKonto )
               SELECT e_doks
               SKIP
               LOOP
            ENDIF
         ENDIF

      ENDIF

      IF !Empty( _vrste_dok )
         IF !( field->idvd $ _vrste_dok )
            SELECT e_doks
            SKIP
            LOOP
         ENDIF
      ENDIF

      IF find_kalk_doks_by_broj_dokumenta( cIdFirma, cIdVd, cBrDok )

         aDokDetail := hb_Hash()
         aDokDetail[ "dokument" ] := cIdFirma + "-" + cIdVd + "-" + cBrDok
         aDokDetail[ "datum" ] := _dat_dok
         aDokDetail[ "idpartner" ] := ""
         aDokDetail[ "partner" ] := ""
         aDokDetail[ "idkonto" ] := ""
         aDokDetail[ "iznos" ] := 0

         IF _zamjeniti_dok == "D"
            aDokDetail[ "tip" ] := "delete"
            export_import_add_to_details( @a_details, aDokDetail )
            lOk := del_kalk_doc( cIdFirma, cIdVd, cBrDok )

         ELSE

            aDokDetail[ "tip" ] := "x"
            export_import_add_to_details( @a_details, aDokDetail )
            SELECT e_doks
            SKIP
            LOOP

         ENDIF

      ENDIF

      IF !lOk
         EXIT
      ENDIF

      SELECT e_doks
      aDoksRec := dbf_get_rec()

      aDokDetail := hb_Hash()
      aDokDetail[ "dokument" ] := aDoksRec[ "idfirma" ] + "-" + aDoksRec[ "idvd" ] + "-" + aDoksRec[ "brdok" ]
      aDokDetail[ "idpartner" ] := aDoksRec[ "idpartner" ]
      aDokDetail[ "idkonto" ] := ""
      aDokDetail[ "partner" ] := ""
      aDokDetail[ "iznos" ] := 0
      aDokDetail[ "datum" ] := aDoksRec[ "datdok" ]
      aDokDetail[ "tip" ] := "import"
      export_import_add_to_details( @a_details, aDokDetail )

      IF !hParams[ "pript" ]
         SELECT kalk_doks
         APPEND BLANK
         lOk := update_rec_server_and_dbf( "kalk_doks", aDoksRec, 1, "CONT" )
         IF !lOk
            EXIT
         ENDIF
      ENDIF

      ++ nCnt
      @ box_x_koord() + 3, box_y_koord() + 2 SAY PadR( PadL( AllTrim( Str( nCnt ) ), 5 ) + ". dokument: " + cIdFirma + "-" + cIdVd + "-" + cBrDok, 60 )

      SELECT e_kalk
      SET ORDER TO TAG "1"
      GO TOP
      SEEK cIdFirma + cIdVd + cBrDok

      nRedniRbroj := 0

      DO WHILE !Eof() .AND. e_kalk->idfirma == cIdFirma .AND. e_kalk->idvd == cIdVd .AND. e_kalk->brdok == cBrDok

         aDoksRec := dbf_get_rec()

         // hb_HDel( aDoksRec, "roktr" )
         hb_HDel( aDoksRec, "datkurs" )

         IF ValType( aDoksRec[ "rbr" ] ) == "N"
            aDoksRec[ "rbr" ] := ++nRedniRbroj
         ELSE
            aDoksRec[ "rbr" ] := PadL( AllTrim( Str( ++nRedniRbroj ) ), 3 )
         ENDIF

         nGlavniBrojac += nRedniRbroj

         @ box_x_koord() + 3, box_y_koord() + 40 SAY "stavka: " + AllTrim( Str( nGlavniBrojac ) ) + " / " +  ToStr( aDoksRec[ "rbr" ] )

         IF hParams[ "pript" ]
            hRec := dbf_get_rec()
            SELECT pript
            APPEND BLANK
            dbf_update_rec( hRec )
         ELSE

            SELECT kalk
            APPEND BLANK
            lOk := update_rec_server_and_dbf( "kalk_kalk", aDoksRec, 1, "CONT" )
            IF !lOk
               EXIT
            ENDIF

         ENDIF

         SELECT e_kalk
         SKIP

      ENDDO

      IF !lOk
         EXIT
      ENDIF

      SELECT e_doks
      SKIP

   ENDDO


   IF nCnt >= 0 .AND. lOk

      @ box_x_koord() + 3, box_y_koord() + 2 SAY PadR( "", 69 )
      update_table_roba( lZamijenitiSifre )
      update_table_partn( lZamijenitiSifre )
      update_table_konto( lZamijenitiSifre )

      IF hParams[ "pript" ]
         lFullTransaction := .T.
      ELSE
         lFullTransaction := .F.
      ENDIF

      update_sifk_sifv( lFullTransaction )

   ENDIF

   IF hParams[ "pript" ]
      SELECT pript
      my_unlock()
      kalk_imp_obradi_sve_dokumente_iz_pript( 0, .F., .T. ) // .F. - ne stampati, .T. - ostaviti broj dokumenta koji stoji u pript

   ELSE  // dokumenti idu direktno na stanje
      IF lOk
         hParams := hb_Hash()
         hParams[ "unlock" ] := { "kalk_doks", "kalk_kalk" }
         run_sql_query( "COMMIT", hParams )
      ELSE
         run_sql_query( "ROLLBACK" )
         MsgBeep( "Problem sa ažuriranjem dokumenta na server !" )
      ENDIF
   ENDIF


   BoxC()

   IF nCnt > 0
      _ret := nCnt
   ENDIF

   RETURN _ret



// ----------------------------------------------------------
// brisi dokument iz doks-a
// ----------------------------------------------------------
STATIC FUNCTION del_kalk_doc( id_firma, id_vd, br_dok )

   LOCAL nDbfArea := Select()
   LOCAL _del_rec
   LOCAL _ret := .F.

   IF find_kalk_doks_by_broj_dokumenta( id_firma, id_vd, br_dok )
      _ret := .T.
      _del_rec := dbf_get_rec()
      delete_rec_server_and_dbf( "kalk_doks", _del_rec, 1, "CONT" )
   ENDIF


   IF find_kalk_by_broj_dokumenta( id_firma, id_vd, br_dok )
      _del_rec := dbf_get_rec()
      delete_rec_server_and_dbf( "kalk_kalk", _del_rec, 2, "CONT" )
   ENDIF

   SELECT ( nDbfArea )

   RETURN _ret



// ----------------------------------------
// kreiranje tabela razmjene
// ----------------------------------------
STATIC FUNCTION _cre_exp_tbls( cDbfPath )

   LOCAL _cre

   IF cDbfPath == NIL
      cDbfPath := my_home() + my_dbf_prefix()
   ENDIF

   // provjeri da li postoji direktorij, pa ako ne - kreiraj
   direktorij_kreiraj_ako_ne_postoji( cDbfPath )


   o_kalk()
   COPY STRUCTURE EXTENDED to ( cDbfPath + "struct" )
   USE
   CREATE ( cDbfPath + "e_kalk" ) from ( cDbfPath + "struct" )


   o_kalk_doks()
   COPY STRUCTURE EXTENDED to ( cDbfPath + "struct" )
   USE
   CREATE ( cDbfPath + "e_doks" ) from ( cDbfPath + "struct" )


   o_roba() // tabela roba
   COPY STRUCTURE EXTENDED to ( cDbfPath + "struct" )
   USE
   CREATE ( cDbfPath + "e_roba" ) from ( cDbfPath + "struct" )


   o_partner() // tabela partn
   COPY STRUCTURE EXTENDED to ( cDbfPath + "struct" )
   USE
   CREATE ( cDbfPath + "e_partn" ) from ( cDbfPath + "struct" )

   o_konto()
   COPY STRUCTURE EXTENDED to ( cDbfPath + "struct" )
   USE
   CREATE ( cDbfPath + "e_konto" ) from ( cDbfPath + "struct" )

   o_sifk( "XXXX" )
   COPY STRUCTURE EXTENDED to ( cDbfPath + "struct" )
   USE
   CREATE ( cDbfPath + "e_sifk" ) from ( cDbfPath + "struct" )

   o_sifv( "XXXX" )
   COPY STRUCTURE EXTENDED to ( cDbfPath + "struct" )
   USE
   CREATE ( cDbfPath + "e_sifv" ) from ( cDbfPath + "struct" )

   RETURN .T.


// ----------------------------------------------------
// otvaranje potrebnih tabela za prenos
// ----------------------------------------------------
STATIC FUNCTION kalk_o_tabele()

   // o_kalk()
   // o_kalk_doks()
   //o_sifk()
   //o_sifv()
   //o_konto()
   //o_partner()
  // o_roba()

   RETURN .T.



STATIC FUNCTION kalk_o_exp_tabele( cDbfPath, lFromFmk )

   LOCAL cDbfName

   IF ( cDbfPath == NIL )
      cDbfPath := my_home() + my_dbf_prefix()
   ENDIF

   IF ( lFromFmk == NIL )
      lFromFmk := .F.
   ENDIF

   // log_write( "otvaram kalk tabele importa i pravim indekse...", 9 )

   // zatvori sve prije otvaranja ovih tabela
   my_close_all_dbf()

   cDbfName := "e_kalk.dbf"
   IF lFromFmk
      cDbfName := Upper( cDbfName )
   ENDIF
   SELECT ( F_TMP_E_KALK )
   my_use_temp( "E_KALK", cDbfPath + cDbfName, .F., .T. )
   INDEX on ( idfirma + idvd + brdok ) TAG "1"
   ?E Alias(), ordKey()

   // log_write( "otvorio i indeksirao: " + cDbfPath + cDbfName, 5 )

   cDbfName := "e_doks.dbf"
   IF lFromFmk
      cDbfName := Upper( cDbfName )
   ENDIF
   SELECT ( F_TMP_E_DOKS )
   my_use_temp( "E_DOKS", cDbfPath + cDbfName, .F., .T. )
   INDEX on ( idfirma + idvd + brdok ) TAG "1"
   ?E Alias(), ordKey()
   // log_write( "otvorio i indeksirao: " + cDbfPath + cDbfName, 5 )

   cDbfName := "e_partn.dbf"
   IF lFromFmk
      cDbfName := Upper( cDbfName )
   ENDIF
   SELECT ( F_TMP_E_PARTN )
   USE
   my_use_temp( "E_PARTN", cDbfPath + cDbfName, .F., .T. )
   INDEX on ( id ) TAG "ID"
   ?E Alias(), ordKey()


   cDbfName := "e_konto.dbf"
   IF lFromFmk
      cDbfName := Upper( cDbfName )
   ENDIF
   SELECT ( F_TMP_E_KONTO )
   my_use_temp( "E_KONTO", cDbfPath + cDbfName, .F., .T. )
   INDEX on ( id ) TAG "ID"
   ?E Alias(), ordKey()

   cDbfName := "e_roba.dbf"
   IF lFromFmk
      cDbfName := Upper( cDbfName )
   ENDIF
   SELECT ( F_TMP_E_ROBA )
   my_use_temp( "E_ROBA", cDbfPath + cDbfName, .F., .T. )
   INDEX on ( id ) TAG "ID"
   ?E Alias(), ordKey()


   cDbfName := "e_sifk.dbf"
   IF lFromFmk
      cDbfName := Upper( cDbfName )
   ENDIF
   SELECT ( F_TMP_E_SIFK )
   my_use_temp( "E_SIFK", cDbfPath + cDbfName, .F., .T. )
   INDEX on ( id + sort + naz ) TAG "ID"
   INDEX on ( id + oznaka ) TAG "ID2"
   ?E Alias(), ordKey()

   cDbfName := "e_sifv.dbf"
   IF lFromFmk
      cDbfName := Upper( cDbfName )
   ENDIF
   SELECT ( F_TMP_E_SIFV )
   my_use_temp( "E_SIFV", cDbfPath + cDbfName, .F., .T. )
   INDEX on ( id + oznaka + idsif + naz ) TAG "ID"
   INDEX on ( id + idsif ) TAG "IDIDSIF"
   ?E Alias(), ordKey()

   // log_write( "otvorene sve import tabele i indeksirane...", 9 )

   RETURN .T.
