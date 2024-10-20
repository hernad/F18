/*
 * This file is part of the bring.out knowhow ERP, a free and open source
 * Enterprise Resource Planning software suite,
 * Copyright (c) 1994-2024 by bring.out d.o.o Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including knowhow ERP specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_knowhow.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */

#include "f18.ch"


// ------------------------------------------
// kompresuj fajlove i vrati path
// ------------------------------------------
FUNCTION udaljenja_razmjena_compress_files( cProgModul, export_dbf_path )

   LOCAL _files
   LOCAL _error
   LOCAL _zip_path, _zip_name, _file
   LOCAL __path, __name, __ext

   _files := _file_list( export_dbf_path, cProgModul )    // lista fajlova za kompresovanje

   _file := zip_name( cProgModul, export_dbf_path )

   hb_FNameSplit( _file, @__path, @__name, @__ext )

   _zip_path := __path
   _zip_name := __name + __ext

   _error := zip_files( _zip_path, _zip_name, _files )

   RETURN _error


// --------------------------------------------
// promjena privilegija fajlova
// --------------------------------------------
FUNCTION set_file_access( file_path, mask )

   LOCAL _ret := .T.
   PRIVATE _cmd

   IF file_path == NIL
      file_path := ""
   ENDIF

   IF mask == NIL
      mask := ""
   ENDIF

   _cmd := "chmod ugo+w " + file_path + mask + "*.*"

   RUN &_cmd

   RETURN _ret


// -----------------------------------------
// otvara listu fajlova za import
// vraca naziv fajla za import
// -----------------------------------------
FUNCTION get_import_file( cProgModul, import_dbf_path )

   LOCAL _file
   LOCAL _filter

   IF cProgModul == NIL
      cProgModul := "kalk"
   ENDIF

   _filter := AllTrim( cProgModul ) + "*.*"

   IF get_file_list( _filter, import_dbf_path, @_file ) == 0
      _file := ""
   ENDIF

   RETURN _file


// ------------------------------------------------------
// Pregled liste exportovanih dokumenata te odabir
// zeljenog fajla z import
// - param cFilter - filter naziva dokumenta
// - param cPath - putanja do exportovanih dokumenata
// ------------------------------------------------------
FUNCTION get_file_list( cFilter, cPath, cFileToImport )

   LOCAL cFajlIme
   LOCAL nIzbor

   OpcF := {}
   

   aFiles := Directory( cPath + cFilter )  // cFilter := "*.txt"

   IF Len( aFiles ) == 0 // da li postoje fajlovi
      MsgBeep( "U direktoriju za prenos nema podataka!##" + cPath + cFilter )
      RETURN 0
   ENDIF

   // sortiraj po datumu
   ASort( aFiles,,, {| x, y | x[ 3 ] > y[ 3 ] } )
   AEval( aFiles, {| elem | AAdd( OpcF, PadR( elem[ 1 ], 15 ) + " " + DToC( elem[ 3 ] ) ) }, 1 )
   // sortiraj listu po datumu
   ASort( OpcF,,, {| x, y | Right( x, 10 ) > Right( y, 10 ) } )

   h := Array( Len( OpcF ) )
   FOR i := 1 TO Len( h )
      h[ i ] := ""
   NEXT

   // selekcija fajla
   nIzbor := 1
   lRet := .F.
   //DO WHILE .T. .AND. LastKey() != K_ESC
   
      nIzbor := meni_0( "imp", OpcF, NIL, nIzbor, .F., .T. ) // odaberi pa zavrsi

      IF nIzbor == 0
         //EXIT
         RETURN 0
      ELSE
         cFajlIme := Trim( Left( OpcF[ nIzbor ], 15 ) )
         cFileToImport := Trim( cPath ) + cFajlIme
         IF Pitanje( , "Želite li izvršiti import fajla " + cFajlIme + " ?", "D" ) == "D"

            RETURN 1
         ELSE
            RETURN 0
         ENDIF
      ENDIF
   //ENDDO

   //IF lRet
   //   RETURN 1
   //ELSE
   //   RETURN 0
   //ENDIF

   RETURN 0

/*
 update tabele konto na osnovu pomocne tabele
*/

FUNCTION update_table_konto( lZamijenitiSifre )

   LOCAL lRet := .F.
   LOCAL lOk := .T.
   LOCAL hRec
   LOCAL _sif_exist := .T.
   LOCAL hParams

   run_sql_query( "BEGIN" )
   // IF !f18_lock_tables( { "konto" }, .T. )
   // run_sql_query( "ROLLBACK" )
   // RETURN lRet
   // ENDIF

   SELECT e_konto
   SET ORDER TO TAG "ID"
   GO TOP

   DO WHILE !Eof()

      hRec := dbf_get_rec()
      update_rec_konto_struct( @hRec )

      _sif_exist := .T.
      IF !select_o_konto( hRec[ "id" ] )
         _sif_exist := .F.
      ENDIF

      IF !_sif_exist .OR. ( _sif_exist .AND. lZamijenitiSifre == "D" )

         @ box_x_koord() + 3, box_y_koord() + 2 SAY "import konto id: " + hRec[ "id" ] + " : " + PadR( hRec[ "naz" ], 20 )

         SELECT konto
         IF !_sif_exist
            APPEND BLANK
         ENDIF

         lOk := update_rec_server_and_dbf( "konto", hRec, 1, "CONT" )

         IF !lOk .AND. !_sif_exist
            delete_with_rlock()
         ENDIF

      ENDIF

      IF !lOk
         EXIT
      ENDIF

      SELECT e_konto
      SKIP

   ENDDO

   IF lOk
      lRet := .T.
      hParams := hb_Hash()
      // hParams[ "unlock" ] :=  { "konto" }
      run_sql_query( "COMMIT", hParams )

   ELSE
      run_sql_query( "ROLLBACK" )
   ENDIF

   RETURN lRet



/*
   update tabele partnera na osnovu pomocne tabele
*/

FUNCTION update_table_partn( lZamijenitiSifre )

   LOCAL lRet := .F.
   LOCAL lOk := .T.
   LOCAL hRec
   LOCAL _sif_exist := .T.
   LOCAL hParams

   run_sql_query( "BEGIN" )
   // IF !f18_lock_tables( { "partn" }, .T. )
   // run_sql_query( "ROLLBACK" )
   // RETURN lRet
   // ENDIF

   SELECT e_partn
   SET ORDER TO TAG "ID"
   GO TOP

   DO WHILE !Eof()

      hRec := dbf_get_rec()

      update_rec_partn_struct( @hRec )

      _sif_exist := .T.
      IF !select_o_partner( hRec[ "id" ] )
         _sif_exist := .F.
      ENDIF

      IF !_sif_exist .OR. ( _sif_exist .AND. lZamijenitiSifre == "D" )

         @ box_x_koord() + 3, box_y_koord() + 2 SAY "import partn id: " + hRec[ "id" ] + " : " + PadR( hRec[ "naz" ], 20 )

         SELECT partn

         IF !_sif_exist
            APPEND BLANK
         ENDIF

         lOk := update_rec_server_and_dbf( "partn", hRec, 1, "CONT" )

         IF !lOk .AND. !_sif_exist
            delete_with_rlock()
         ENDIF

      ENDIF

      IF !lOk
         EXIT
      ENDIF

      SELECT e_partn
      SKIP

   ENDDO

   IF lOk
      lRet := .T.
      hParams := hb_Hash()
      // hParams[ "unlock" ] :=  { "partn" }
      run_sql_query( "COMMIT", hParams )
   ELSE
      run_sql_query( "ROLLBACK" )
   ENDIF

   RETURN lRet



FUNCTION update_table_roba( lZamijenitiSifre )

   LOCAL lRet := .F.
   LOCAL lOk := .T.
   LOCAL hRec
   LOCAL _sif_exist := .T.
   LOCAL hParams

   run_sql_query( "BEGIN" )
   // IF !f18_lock_tables( { "roba" }, .T. )
   // run_sql_query( "ROLLBACK" )
   // RETURN lRet
   // ENDIF

   SELECT e_roba
   SET ORDER TO TAG "ID"
   GO TOP

   DO WHILE !Eof()

      hRec := dbf_get_rec()
      update_rec_roba_struct( @hRec )

      _sif_exist := .T.
      IF ! select_o_roba( hRec[ "id" ] )
         _sif_exist := .F.
      ENDIF

      IF !_sif_exist .OR. ( _sif_exist .AND. lZamijenitiSifre == "D" )

         @ box_x_koord() + 3, box_y_koord() + 2 SAY "import roba id: " + hRec[ "id" ] + " : " + PadR( hRec[ "naz" ], 20 )

         SELECT roba
         IF !_sif_exist
            APPEND BLANK
         ENDIF

         lOk := update_rec_server_and_dbf( "roba", hRec, 1, "CONT" )

         IF !lOk .AND. !_sif_exist
            delete_with_rlock()
         ENDIF

      ENDIF

      IF !lOk
         EXIT
      ENDIF

      SELECT e_roba
      SKIP

   ENDDO

   IF lOk
      lRet := .T.
      hParams := hb_Hash()
      // hParams[ "unlock" ] :=  { "roba" }
      run_sql_query( "COMMIT", hParams )

   ELSE
      run_sql_query( "ROLLBACK" )
   ENDIF

   RETURN lRet



STATIC FUNCTION update_rec_sifk_struct( hRec )

/*
   IF hb_HHasKey( hRec, "unique" )
      hRec[ "f_unique" ] := hRec[ "unique" ]
      hb_HDel( hRec, "unique" )
   ENDIF

   IF hb_HHasKey( hRec, "decimal" )
      hRec[ "f_decimal" ] := hRec[ "decimal" ]
      hb_HDel( hRec, "decimal" )
   ENDIF

   IF !hb_HHasKey( hRec, "match_code" ) .OR. hRec[ "match_code" ] == NIL
      hRec[ "match_code" ] := PadR( "", 10 )
   ENDIF
*/

   RETURN .T.



STATIC FUNCTION update_rec_konto_struct( hRec )

   LOCAL _struct := {}

// AAdd( _struct, "match_code" )
// AAdd( _struct, "pozbilu" )
// AAdd( _struct, "pozbils" )

// dodaj_u_hash_matricu( _struct, @hRec )

   RETURN .T.




STATIC FUNCTION dodaj_u_hash_matricu( polja, hash )

   LOCAL _field

   IF polja == NIL .OR. Len( polja ) == 0
      RETURN .F.
   ENDIF

   FOR EACH _field in polja
      IF ! hb_HHasKey( hash, _field )
         hash[ _field ] := NIL
      ENDIF
   NEXT

   RETURN .T.




STATIC FUNCTION brisi_iz_hash_matrice( polja, hash )

   LOCAL _field

   IF polja == NIL .OR. Len( polja ) == 0
      RETURN .F.
   ENDIF

   FOR EACH _field in polja
      IF hb_HHasKey( hash, _field )
         hb_HDel( hash, _field )
      ENDIF
   NEXT

   RETURN .T.




// --------------------------------------------------
// update strukture zapisa tabele partn
// --------------------------------------------------
STATIC FUNCTION update_rec_partn_struct( hRec )

   LOCAL _add := {}
   LOCAL _remove := {}

// AAdd( _add, "match_code" )
// dodaj_u_hash_matricu( _add, @hRec )

// AAdd( _remove, "brisano" )
// AAdd( _remove, "rejon" )
// brisi_iz_hash_matrice( _remove, @hRec )

   RETURN .T.



// --------------------------------------------------
// update strukture zapisa tabele roba
// --------------------------------------------------
STATIC FUNCTION update_rec_roba_struct( hRec )

   LOCAL _add := {}
   LOCAL _remove := {}

/*
   AAdd( _add, "idkonto" )
   AAdd( _add, "sifradob" )
   AAdd( _add, "strings" )
   AAdd( _add, "k7" )
   AAdd( _add, "k8" )
   AAdd( _add, "k9" )
   AAdd( _add, "mink" )
   AAdd( _add, "fisc_plu" )
   AAdd( _add, "match_code" )
   AAdd( _add, "mpc4" )
   AAdd( _add, "mpc5" )
   AAdd( _add, "mpc6" )
   AAdd( _add, "mpc7" )
   AAdd( _add, "mpc8" )
   AAdd( _add, "mpc9" )

   dodaj_u_hash_matricu( _add, @hRec )
   */

   // AAdd( _remove, "carina" )
   // AAdd( _remove, "_m1_" )
   // AAdd( _remove, "brisano" )

   brisi_iz_hash_matrice( _remove, @hRec )

   RETURN .T.



FUNCTION update_sifk_sifv( lFullTransaction )

   LOCAL hRec, cTran

   hb_default( @lFullTransaction, .T. )

   IF lFullTransaction
      cTran := "FULL"
   ELSE
      cTran := "CONT"
   ENDIF

   //o_sifk() // treba za seek
   //o_sifv() // treba za brisanje
   o_sifk_sifv_empty()

   SELECT e_sifk
   SET ORDER TO TAG "ID2"
   GO TOP

   DO WHILE !Eof()

      hRec := dbf_get_rec()
      update_rec_sifk_struct( @hRec )

      SELECT sifk
      SET ORDER TO TAG "ID2"
      GO TOP
      SEEK hRec[ "id" ] + hRec[ "oznaka" ]

      IF !Found()
         APPEND BLANK
      ENDIF

      @ box_x_koord() + 3, box_y_koord() + 2 SAY "import sifk id: " + hRec[ "id" ] + ", oznaka: " + hRec[ "oznaka" ]

      update_rec_server_and_dbf( "sifk", hRec, 1, cTran )

      SELECT e_sifk
      SKIP

   ENDDO

   SELECT e_sifv
   SET ORDER TO TAG "ID"
   GO TOP
   DO WHILE !Eof() // brisanje sifv
      hRec := dbf_get_rec( .T. ) // konvertuj stringove u utf8
      SELECT sifv
      brisi_sifv_item( hRec[ "id" ], hRec[ "oznaka" ], hRec[ "idsif" ], cTran )
      SELECT e_sifv
      SKIP
   ENDDO

   SELECT e_sifv
   GO TOP
   DO WHILE !Eof() // e_sifv -> sifv

      hRec := dbf_get_rec( .T. ) // konvertuj stringove u utf8
      use_sql_sifv( hRec[ "id" ], hRec[ "oznaka" ], hRec[ "idsif" ] )
      GO TOP
      IF Eof()
         APPEND BLANK
         @ box_x_koord() + 3, box_y_koord() + 2 SAY "import sifv id: " + hRec[ "id" ] + ", oznaka: " + hRec[ "oznaka" ] + ", sifra: " + hRec[ "idsif" ]
         update_rec_server_and_dbf( "sifv", hRec, 1, cTran )
      ENDIF

      SELECT e_sifv
      SKIP
   ENDDO

   SELECT sifk
   USE
   SELECT sifv
   USE

   RETURN .T.



FUNCTION direktorij_kreiraj_ako_ne_postoji( cDbfPath )

   LOCAL _ret := .T.

   IF DirChange( cDbfPath ) != 0
      _cre := MakeDir ( cDbfPath )
      IF _cre != 0
         MsgBeep( "kreiranje " + cDbfPath + " neuspjesno ?!" )
         log_write( "dircreate err:" + cDbfPath, 7 )
         _ret := .F.
      ENDIF
   ENDIF

   RETURN _ret


// -------------------------------------------------
// brise zip fajl exporta
// -------------------------------------------------
FUNCTION delete_zip_files( zip_file )

   IF File( zip_file )
      FErase( zip_file )
   ENDIF

   RETURN .T.



// ---------------------------------------------------
// brise temp fajlove razmjene
// ---------------------------------------------------
FUNCTION delete_exp_files( cDbfPath, cProgModul )

   LOCAL _files := _file_list( cDbfPath, cProgModul )
   LOCAL _file, _tmp

   MsgO( "Brisem tmp fajlove ..." )
   FOR EACH _file in _files
      IF File( _file )
         // pobrisi dbf fajl
         FErase( _file )
         // cdx takodjer ?
         _tmp := ImeDbfCDX( _file )
         FErase( _tmp )
         // fpt takodjer ?
         _tmp := StrTran( _file, ".dbf", ".fpt" )
         FErase( _tmp )
      ENDIF
   NEXT
   MsgC()

   RETURN .T.


// -------------------------------------------------------
// da li postoji import fajl ?
// -------------------------------------------------------
FUNCTION import_file_exist( imp_file )

   LOCAL _ret := .T.

   IF ( imp_file == NIL )
      imp_file := __import_dbf_path + __import_zip_name
   ENDIF

   IF !File( imp_file )
      _ret := .F.
   ENDIF

   RETURN _ret


// --------------------------------------------
// vraca naziv zip fajla
// --------------------------------------------
FUNCTION zip_name( cProgModul, export_dbf_path )

   LOCAL _file
   LOCAL _ext := ".zip"
   LOCAL _count := 1
   LOCAL _exist := .T.

   IF cProgModul == NIL
      cProgModul := "kalk"
   ENDIF

   IF export_dbf_path == NIL
      export_dbf_path := my_home()
   ENDIF

   cProgModul := AllTrim( Lower( cProgModul ) )

   _file := export_dbf_path + cProgModul + "_exp_" + PadL( AllTrim( Str( _count ) ), 2, "0" ) + _ext

   IF File( _file )

      // generisi nove nazive fajlova
      DO WHILE _exist

         ++_count
         _file := export_dbf_path + cProgModul + "_exp_" + PadL( AllTrim( Str( _count ) ), 2, "0" ) + _ext

         IF !File( _file )
            _exist := .F.
            EXIT
         ENDIF

      ENDDO

   ENDIF

   RETURN _file



// ----------------------------------------------------
// vraca listu fajlova koji se koriste kod prenosa
// ----------------------------------------------------
STATIC FUNCTION _file_list( cDbfPath, cProgModul )

   LOCAL aFiles := {}

   IF cProgModul == NIL
      cProgModul := "kalk"
   ENDIF

   DO CASE

   CASE cProgModul == "kalk"

      AAdd( aFiles, cDbfPath + "e_kalk.dbf" )
      AAdd( aFiles, cDbfPath + "e_doks.dbf" )
      AAdd( aFiles, cDbfPath + "e_doks.fpt" )
      AAdd( aFiles, cDbfPath + "e_roba.dbf" )
      AAdd( aFiles, cDbfPath + "e_roba.fpt" )
      AAdd( aFiles, cDbfPath + "e_partn.dbf" )
      AAdd( aFiles, cDbfPath + "e_konto.dbf" )
      AAdd( aFiles, cDbfPath + "e_sifk.dbf" )
      AAdd( aFiles, cDbfPath + "e_sifv.dbf" )

   CASE cProgModul == "fakt"

      AAdd( aFiles, cDbfPath + "e_fakt.dbf" )
      AAdd( aFiles, cDbfPath + "e_fakt.fpt" )
      AAdd( aFiles, cDbfPath + "e_doks.dbf" )
      AAdd( aFiles, cDbfPath + "e_doks.fpt" )
      AAdd( aFiles, cDbfPath + "e_doks2.dbf" )
      AAdd( aFiles, cDbfPath + "e_roba.dbf" )
      AAdd( aFiles, cDbfPath + "e_roba.fpt" )
      AAdd( aFiles, cDbfPath + "e_partn.dbf" )
      AAdd( aFiles, cDbfPath + "e_sifk.dbf" )
      AAdd( aFiles, cDbfPath + "e_sifv.dbf" )


   CASE cProgModul == "fin"

      AAdd( aFiles, cDbfPath + "e_suban.dbf" )
      AAdd( aFiles, cDbfPath + "e_sint.dbf" )
      AAdd( aFiles, cDbfPath + "e_anal.dbf" )
      AAdd( aFiles, cDbfPath + "e_nalog.dbf" )
      AAdd( aFiles, cDbfPath + "e_partn.dbf" )
      AAdd( aFiles, cDbfPath + "e_konto.dbf" )
      AAdd( aFiles, cDbfPath + "e_sifk.dbf" )
      AAdd( aFiles, cDbfPath + "e_sifv.dbf" )

   ENDCASE

   RETURN aFiles





// ------------------------------------------
// dekompresuj fajlove i vrati path
// ------------------------------------------
FUNCTION razmjena_decompress_files( imp_file, import_dbf_path, import_zip_name )

   LOCAL _zip_name, _zip_path
   LOCAL _error
   LOCAL __name, __path, __ext

   IF ( imp_file == NIL )

      _zip_path := import_dbf_path
      _zip_name := import_zip_name

   ELSE

      hb_FNameSplit( imp_file, @__path, @__name, @__ext )
      _zip_path := __path
      _zip_name := __name + __ext

   ENDIF

   log_write( "unzip fajl:" + _zip_path + _zip_name, 7 )

   _error := unzip_files( _zip_path, _zip_name, import_dbf_path )

   RETURN _error


/*
  popunjava sifrarnike e_sifk, e_sifv
*/

FUNCTION razmjena_fill_sifk_sifv( cSifarnik, cIdSifra )

   LOCAL _rec

   PushWA()

   SELECT e_sifk

   IF RecCount2() == 0

      o_sifk()
      SELECT sifk
      SET ORDER TO TAG "ID"
      GO TOP

      DO WHILE !Eof()
         _rec := dbf_get_rec()
         SELECT e_sifk
         APPEND BLANK
         dbf_update_rec( _rec )
         SELECT sifk
         SKIP
      ENDDO

   ENDIF

   use_sql_sifv( PadR( cSifarnik, 8 ), "*", cIdSifra )
   GO TOP
   DO WHILE !Eof() .AND. field->id == PadR( cSifarnik, 8 ) .AND.    field->idsif == PadR( cIdSifra, 15 )

      _rec := dbf_get_rec()
      SELECT e_sifv
      APPEND BLANK
      dbf_update_rec( _rec )
      SELECT sifv
      SKIP
   ENDDO

   PopWa()

   RETURN .T.
