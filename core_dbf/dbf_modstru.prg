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


// modifikacija struktura dbf tabele

FUNCTION modstru_form_file( cFajlCHS )

   LOCAL oFile
   LOCAL aRet := {}

   oFile := TFileRead():New( cFajlCHS )
   oFile:Open()

   DO WHILE oFile:MoreToRead()
      AAdd( aRet, oFile:ReadLine() )
   ENDDO

   oFile:Close()

   RETURN modstru( aRet )


/*
 Modstru({"*fin_budzet", "C IDKONTO C 10 0",  "A IDKONTO2 C 7 0"})
*/

FUNCTION modstru( a_commands )

   LOCAL _path, _ime_dbf := ""
   LOCAL _brisi_dbf := .F.,  _rename_dbf := NIL
   LOCAL _lin
   LOCAL _stru_changed := .F.
   LOCAL _curr_stru, _new_stru
   LOCAL _full_name
   LOCAL _msg
   LOCAL _op

   CLOSE ALL

   info_bar( "modstru", "DBF modstru start" )
   log_write( "MODSTRU cmd: " + pp( a_commands ), 3 )


   _path := my_home()

   FOR EACH _lin in a_commands

      IF Empty( _lin ) .OR.  Left( _lin, 1 ) == ";"
         LOOP
      ENDIF

      IF Left( _lin, 1 ) == "*"

         kopi( _path, _ime_dbf, _curr_stru, _new_stru, @_brisi_dbf, @_rename_dbf, @_stru_changed )

         _lin := SubStr( _lin, 2, Len( Trim( _lin ) ) -1 )

         _ime_dbf := AllTrim( _lin )


         _full_name := _path + _ime_dbf + "." + DBFEXT
         IF File( _full_name )
            SELECT 1

            _msg := "START modstru: " + _path + _ime_dbf
            log_write( _msg, 3 )
            ?E _msg

            USE  ( _path + _ime_dbf ) ALIAS OLDDBF EXCLUSIVE
         ELSE
            _ime_dbf := "*i"
            log_write( "MODSTRU, nepostojeca tabela: " +  _full_name, 2 )
            RETURN .F.
         ENDIF

         _stru_changed := .F.

         _curr_stru := dbStruct()
         _new_stru := AClone( _curr_stru )

         IF Empty( _ime_dbf )
            log_write( "MODSTRU, nije zadat DBF fajl nad kojim se vrsi modifikacija strukture !", 3 )
            CLOSE ALL
            RETURN .F.
         ENDIF

      ELSE
         _op := Rjec( @_lin )
         IF !chs_op( _op, @_lin, @_curr_stru, @_new_stru, @_brisi_dbf, @_rename_dbf, @_stru_changed )
            log_write( "MODSTRU, problem: " + _ime_dbf, 2 )
         ENDIF
      ENDIF
   NEXT

   kopi( _path, _ime_dbf, _curr_stru, _new_stru, @_brisi_dbf, @_rename_dbf, @_stru_changed )

   log_write( "END modstru ", 2 )

   info_bar( "modstru", "end of modstru" )
   CLOSE ALL

   RETURN .T.


STATIC FUNCTION chs_op( op, lin, curr_stru, new_stru, brisi_dbf, rename_dbf, stru_changed )

   LOCAL _ime_p, _tip, _len, _dec
   LOCAL _ime_p_2, _tip_2, _len_2, _dec_2
   LOCAL _pos, _pos_2
   LOCAL _l := lin

   op := AllTrim( op )

   DO CASE

   CASE op == "IZBRISIDBF"
      brisi_dbf := .T.

   CASE op == "IMEDBF"
      rename_dbf := Rjec( @lin )

   CASE op == "A"
      _ime_p := Rjec( @lin )
      _tip := Rjec( @lin )
      _len := Val( Rjec( @lin ) )
      _dec := Val( Rjec( @lin ) )
      IF !( _len > 0 .AND. _len > _dec ) .OR. ( _tip == "C" .AND. _dec > 0 ) .OR. !( _tip $ "CNDMIYB" )
         log_write( "MODSTRU, greska: dodavanje polja, linija: " + _l, 5 )
         RETURN .F.
      ENDIF

      _pos := AScan( curr_stru, {| x| x[ 1 ] == _ime_p } )
      IF _pos <> 0
         log_write( "MODSTRU, greska: polje " + _ime_p + " vec postoji u DBF-u, linija: " + _l, 5 )
         RETURN .F.
      ENDIF

      log_write( "MODSTRU, dodajem polje: " + _ime_p + ", tip: " + _tip + ", duzina: " + AllTrim( Str( _len ) ) + ", dec: " + AllTrim( Str( _dec ) ), 5 )
      AAdd( new_stru, { _ime_p, _tip, _len, _dec } )

      stru_changed := .T.

   CASE op == "D"

      _ime_p := Upper( Rjec( @lin ) )
      _pos := AScan( new_stru, {| x| x[ 1 ] == _ime_p } )
      IF _pos <> 0
         log_write( "MODSTRU, brisem polje: " + _ime_p, 5 )
         ADel ( new_stru, _pos )
         // prepakuj array
         Prepakuj( @new_stru )
         stru_changed := .T.
      ELSE
         log_write( "MODSTRU, greska: brisanje nepostojeceg polja, linija: " + _l, 5 )
         RETURN .F.
      ENDIF

   CASE op == "C"

      _ime_p := Upper ( Rjec( @lin ) )
      _tip :=   Rjec( @lin )
      _len :=   Val( Rjec( @lin ) )
      _dec :=   Val( Rjec( @lin ) )

      _pos := AScan( curr_stru, {| x| x[ 1 ] == _ime_p .AND. x[ 2 ] == _tip .AND. x[ 3 ] == _len .AND. x[ 4 ] == _dec } )
      IF _pos == 0
         log_write( "MODSTRU, greska: zadana je promjena nepostojeceg polja, linija: " + _l, 5 )
         RETURN .F.
      ENDIF

      _ime_p_2 := Upper( Rjec( @lin ) )
      _tip_2 := Upper( Rjec( @lin ) )
      _len_2 := Val( Rjec( @lin ) )
      _dec_2 := Val( Rjec( @lin ) )

      _pos_2 := AScan( curr_stru, {| x| x[ 1 ] == _ime_p_2 } )
      IF _pos_2 <> 0 .AND.  _ime_p <> _ime_p_2
         log_write( "MODSTRU, greska: zadana je promjena u postojece polje, linija: " + _l, 5 )
         RETURN .F.
      ENDIF
      stru_changed := .T.

      IF _tip == _tip_2
         stru_changed := .T.
      ENDIF

      IF ( _tip == "N" .AND. _tip_2 == "BY" )
         stru_changed := .T.
      ENDIF

      IF ( _tip == "N" .AND. _tip_2 == "C" )
         stru_changed := .T.
      ENDIF

      IF ( _tip == "C" .AND. _tip_2 == "N" )
         stru_changed := .T.
      ENDIF

      IF ( _tip == "C" .AND. _tip_2 == "D" )
         stru_changed := .T.
      ENDIF

      IF !stru_changed
         log_write( "MODSTRU, greska: neispravna konverzija, linija: " + _l, 5 )
         RETURN .F.
      ENDIF

      AAdd( curr_stru[ _pos ], _ime_p_2 )
      AAdd( curr_stru[ _pos ], _tip_2 )
      AAdd( curr_stru[ _pos ], _len_2 )
      AAdd( curr_stru[ _pos ], _dec_2 )


      _pos := AScan( new_stru, {| x| x[ 1 ] == _ime_p .AND. x[ 2 ] == _tip .AND. x[ 3 ] == _len .AND. x[ 4 ] == _dec } )
      new_stru[ _pos ] := { _ime_p_2, _tip_2, _len_2, _dec_2 }

      log_write( "MODSTRU, vrsim promjenu: " + _ime_p + ", tip: " + _tip + ", duzina: " + AllTrim( Str( _len ) ) + ", dec: " + AllTrim( Str( _dec ) ) + " -> " + _ime_p_2 + ", tip: " + _tip_2 + ", duzina: " + AllTrim( Str( _len_2 ) ) + ", dec: " +  AllTrim( Str( _dec_2 ) ), 5 )

      stru_changed := .T.

   OTHERWISE
      log_write( "MODSTRU, greska nepostojeca operacija: " + op, 5 )
      RETURN .F.

   END CASE

   RETURN .T.


// -----------------------------
// ime_dbf obavezno "fin_budzet"
// -----------------------------
FUNCTION kopi( path, ime_dbf, curr_stru, new_stru, brisi_dbf, rename_dbf, stru_changed )

   LOCAL _pos
   LOCAL _ext, _ime_old, _ime_new
   LOCAL _ime_p, _tmp
   LOCAL _ime_file, _ime_tmp, _ime_bak
   LOCAL _cdx_file
   LOCAL _f, nI, _ime_p_new
   LOCAL _cnt

   _f := path + ime_dbf + "."
   IF brisi_dbf
      SELECT OLDDBF
      USE

      FErase( _f + DBFEXT )
      log_write( "MODSTRU, brisem: " + _f + DBFEXT, 5 )

      FErase( _f +  MEMOEXT )
      log_write( "MODSTRU, brisem: " + _f + MEMOEXT, 5 )

      brisi_dbf := .F.
      RETURN .F.
   ENDIF

   IF rename_dbf != NIL

      SELECT OLDDBF
      USE
      FOR EACH _ext in { DBFEXT, MEMOEXT }

         _ime_old := _f  +  _ext
         _ime_new := path + rename_dbf + _ext
         IF FRename( _ime_old, _ime_new ) == 0
            log_write( "MODSTRU, preimenovao: " + _ime_old + " U " + _ime_new, 5 )
         ENDIF

      NEXT
      rename_dbf := NIL
   ENDIF


   IF stru_changed

      _cdx_file := path + ime_dbf + "." + INDEXEXT
      IF File( _cdx_file )
         FErase( path + _cdx_file )
      ENDIF

      FOR EACH _tmp in { MEMOEXT, INDEXEXT, DBFEXT }
         FErase( path + "modstru_tmp." + _tmp )
      NEXT

      dbCreate( my_home() + "modstru_tmp." + DBFEXT, new_stru )

      SELECT 2
      USE ( my_home() + "modstru_tmp." + DBFEXT ) ALIAS "tmp" EXCLUSIVE

      SELECT OLDDBF

      info_bar( "modstru", "modstru " + Alias() + " " +  AllTrim( Str( RecCount() ) ) )
      SET ORDER TO 0
      GO TOP

      _cnt := 0
      DO WHILE !Eof()

         SELECT tmp

         APPEND BLANK

         FOR nI := 1 TO Len( curr_stru )

            _ime_p := curr_stru[ nI, 1 ]

            IF Len( curr_stru[ nI ] ) > 4

               _ime_p_new := curr_stru[ nI, 5 ]
               DO CASE
               CASE curr_stru[ nI, 2 ] == curr_stru[ nI, 6 ]
                  Eval( FieldBlock( _ime_p_new ),  Eval( FieldWBlock( _ime_p, 1 ) ) )

               CASE ( curr_stru[ nI, 2 ] $ "BNIY" ) .AND.  ( curr_stru[ nI, 6 ] $ "BNYI" )
                  // jedan tip numerika u drugi tip numerika
                  Eval( FieldBlock( _ime_p_new ),  Eval( FieldWBlock( _ime_p, 1 ) ) )

               CASE curr_stru[ nI, 2 ] == "C" .AND. ( curr_stru[ nI, 6 ] $ "BNIY" )
                  Eval( FieldBlock( _ime_p_new ),  Val( Eval( FieldWBlock( _ime_p, 1 ) ) ) )

               CASE ( curr_stru[ nI, 2 ] $ "BNIY" ) .AND. curr_stru[ nI, 6 ] == "C"
                  Eval( FieldBlock( _ime_p_new ),  Str( Eval( FieldWBlock( _ime_p, 1 ) ) ) )

               CASE curr_stru[ nI, 2 ] == "C" .AND. curr_stru[ nI, 6 ] == "D"
                  Eval( FieldBlock( _ime_p_new ),  CToD( Eval( FieldWBlock( _ime_p, 1 ) ) ) )

               END CASE

            ELSE
               _pos := AScan( new_stru, {| x| _ime_p == x[ 1 ] } )
               IF _pos <> 0
                  Eval( FieldBlock( _ime_p ),  Eval( FieldWBlock( _ime_p, 1 ) ) )
               ENDIF
            ENDIF
         NEXT

         SELECT OLDDBF

         ++ _cnt
         IF ( _cnt % 5 ) == 0
            ?E ime_dbf, _cnt
         ENDIF

         SKIP

      ENDDO

      CLOSE ALL

      FOR EACH _tmp in { DBFEXT, MEMOEXT, INDEXEXT }

         _ime_file := _f + _tmp
         // modstru_tmp.dbf
         _ime_tmp := my_home() + "modstru_tmp." + _tmp
         // fin_suban.dbf_bak
         _ime_bak := _f + _tmp + "_bak"

         IF File( _ime_file )
            FErase( _ime_bak )
            FRename( _ime_file, _ime_bak )
            FRename( _ime_tmp, _ime_file )
         ENDIF

      NEXT

   ENDIF

   RETURN .T.



FUNCTION Rjec( cLin )

   LOCAL cOp, nPos

   nPos := At( " ", cLin )
   IF nPos == 0 .AND. !Empty( cLin ) // zadnje polje
      cOp := AllTrim( clin )
      cLin := ""
      RETURN cOp
   ENDIF

   cOp  := AllTrim( Left( cLin, nPos - 1 ) )
   cLin := Right( cLin, Len( cLin ) -nPos )
   cLin := AllTrim( cLin )

   RETURN cOp


FUNCTION Prepakuj( aNStru )

   LOCAL i, aPom

   aPom := {}

   FOR i := 1 TO Len( aNStru )
      IF aNStru[ i ] <> nil
         AAdd( aPom, aNStru[ i ] )
      ENDIF
   NEXT

   aNStru := AClone( aPom )

   RETURN NIL
