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


FUNCTION zip_files( cOutputDir, cFileNameOutput, aFiles )

   LOCAL nError

   IF ( aFiles == NIL ) .OR. Len( aFiles ) == 0
      RETURN MsgBeep( "Nema fajlova za arhiviranje ?!" )
   ENDIF

   nError := zip_file( cOutputDir, cFileNameOutput, aFiles )

   RETURN nError



FUNCTION unzip_files( cZipFileDir, cZipFileName, cExtractDir, aFiles, lOverwriteFiles )

   LOCAL nError

   nError := __unzip( cZipFileDir, cZipFileName, cExtractDir, aFiles, lOverwriteFiles )

   RETURN nError



STATIC FUNCTION zip_file( cZipFileDir, cZipFileName, aFiles )

   LOCAL cZipFileHandle
   LOCAL cFile
   LOCAL nError := 0
   LOCAL nCount := 0
   LOCAL cZipFileFullName := cZipFileDir + cZipFileName
   LOCAL cFilePath, cFileExt, cFileName
   LOCAL aFile, aFajlovi

   cZipFileHandle := hb_zipOpen( cZipFileFullName ) // otvori fajl

   IF !Empty( cZipFileHandle )

      Box(, 3, 65 )
      @ box_x_koord() + 1, box_y_koord() + 2 SAY cZipFileHandle
      @ box_x_koord() + 2, box_y_koord() + 2 SAY "Kompresujem fajl: " + PadL( AllTrim( cZipFileFullName ), 40 )

      FOR EACH cFile IN aFiles

         IF !Empty( cFile )

            hb_FNameSplit( cFile, @cFilePath, @cFileName, @cFileExt ) // odvoji lokaciju fajlova i nazive
            aFajlovi := hb_DirScan( cFilePath, cFileName + cFileExt )

            FOR EACH aFile IN aFajlovi
               IF !( cFilePath + aFile[ 1 ] == cZipFileFullName )

                  ++nCount
                  @ box_x_koord() + 2, box_y_koord() + 2 SAY PadL( AllTrim( Str( nCount ) ), 3 ) + ") ..." + PadR( AllTrim( aFile[ 1 ] ), 40 )

                  // IF relative_path
                  // nError := hb_zipStoreFile( cZipFileHandle, cFilePath + aFile[ 1 ], cFilePath + aFile[ 1 ], nil )
                  // ELSE
                  nError := hb_zipStoreFile( cZipFileHandle, aFile[ 1 ], aFile[ 1 ], NIL )
                  // ENDIF

                  IF ( nError <> 0 )
                     __zip_error( nError, "operacija: kompresovanje fajla" )
                     // RETURN -99
                  ENDIF

               ENDIF
            NEXT

         ENDIF
      NEXT

      nError := hb_zipClose( cZipFileHandle, "" )
      BoxC()

   ENDIF

   IF ( nError <> 0 )
      __zip_error( nError, "operacija: zatvaranje zip fajla" )
   ENDIF

   RETURN nError



STATIC FUNCTION __zip_error( err, descr )

   LOCAL _add_msg := ""

   IF ( err <> 0 )

      IF descr == NIL
         descr := ""
      ENDIF

      IF !Empty( descr )
         _add_msg := "#" + descr
      ENDIF

      MsgBeep( "Greška pri kompresovanju ?!" + AllTrim( Str( err ) ) + _add_msg )
   ENDIF

   RETURN .F.



STATIC FUNCTION __unzip( cZipFileDir, cZipFileName, cZipFileDestination, aFiles, lOverwriteFiles )

   LOCAL cZipFileHandle
   LOCAL nError := 0
   LOCAL nCount := 0
   LOCAL lExtract := .T.
   LOCAL nScan
   LOCAL _file_in_zip
   LOCAL cZipFileFullName := cZipFileDir + cZipFileName
   LOCAL cFile, tDateTime, cTime
   LOCAL nInternalAttr, nExternalAttr, nMethod, nSize, nCompressedSize

   // paterni fajlova za ekstrakt
   IF ( aFiles == NIL )
      aFiles := {}
   ENDIF

   IF ( cZipFileDestination == NIL )
      cZipFileDestination := ""
   ENDIF

   IF ( lOverwriteFiles == NIL )
      lOverwriteFiles := .T.
   ENDIF

   // otvori zip fajl
   cZipFileHandle := hb_unzipOpen( cZipFileFullName )

   IF !Empty( cZipFileHandle )

      IF is_in_main_thread()
         Box(, 2, 75 )
         @ box_x_koord() + 1, box_y_koord() + 8 SAY Space( 50 )
         @ box_x_koord() + 1, box_y_koord() + 2 SAY "unzip: " + PadR( AllTrim( cZipFileFullName ), 50 )
      ELSE
         ?E "unzip",  cZipFileFullName
      ENDIF

      IF !Empty( cZipFileDestination )
         DirChange( cZipFileDestination )
      ENDIF

      nError := hb_unzipFileFirst( cZipFileHandle )

      DO WHILE nError == 0

         hb_unzipFileInfo( cZipFileHandle, @cFile, @tDateTime, @cTime, @nInternalAttr, @nExternalAttr, @nMethod, @nSize, @nCompressedSize )

         // hb_unzipFileInfo( hUnzip, @cZipName, @tDateTime, @cTime,
         // @nInternalAttr, @nExternalAttr,
         // @nMethod, @nSize, @nCompressedSize,
         // @lCrypted, @cComment ) --> nError

         IF ( cFile == NIL ) .OR. Empty( cFile )
            nError := hb_unzipFileNext( cZipFileHandle )
         ENDIF

         IF Len( aFiles ) > 0 // da li imamo kakve paterne ?
            nScan := AScan( aFiles, {| cPattern | hb_WildMatch( cPattern, cFile, .T. ) } )
            IF nScan == 0
               lExtract := .F.
            ENDIF
         ENDIF

   
         IF lOverwriteFiles // prvo provjeri postoji li fajl, ako je u overwrite modu

            IF nSize > 0 .AND. File( cFile )
               FErase( cFile )
            ENDIF
         ENDIF
         // ENDIF

         IF nSize > 0 .AND. lExtract

            ++nCount
            IF is_in_main_thread()
               @ box_x_koord() + 2, box_y_koord() + 5 SAY Space( 60 )
               @ box_x_koord() + 2, box_y_koord() + 2 SAY PadL( AllTrim( Str( nCount ) ), 3 ) + ") " + Left( AllTrim( cFile ), 60 )
            ELSE
               ?E  PadL( AllTrim( Str( nCount ) ), 3 ) + ") ", cFile
            ENDIF

            nError := hb_unzipExtractCurrentFile( cZipFileHandle, NIL, NIL )
            IF ( nError <> 0 )
               __zip_error( nError, "operacija: dekompresovanje fajla" )
               // RETURN -99
            ENDIF

         ENDIF

         // ovdje ne treba obrada error-a, zato sto je kraj arhive greska = -100
         nError := hb_unzipFileNext( cZipFileHandle )

      ENDDO

      nError := hb_unzipClose( cZipFileHandle, "" )
      IF is_in_main_thread()
         BoxC()
      ENDIF

   ENDIF

   IF ( nError <> 0 )
      __zip_error( nError, "operacija: zatvaranje zip fajla" )
   ENDIF

   RETURN nError
