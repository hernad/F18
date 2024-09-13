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

STATIC __keystrokes := {}
STATIC __test_vars
STATIC __task
STATIC __test_tags := {}

// #define SLOW_TESTS

// jedan poziv test_keystroke treba samo jednu sekvencu poslati
STATIC __keystroke_step


// --- keystroke lib functions --

// na osnovu ovoga mozemo dva razlicita poziva funkcije Pitanje() razluciti
// a to nam treba kod keystrokes testova
FUNCTION push_test_tag( tag )

   IF tag == NIL
      tag := "NIL"
   ENDIF

   log_write( "push_test_tag:" + tag, 3 )
   AAdd( __test_tags, tag )

   RETURN


FUNCTION pop_test_tag()

   IF Len( __test_tags ) > 0
      log_write( "pop_test_tag:" + get_test_tag(), 3 )
      ADel( __test_tags, Len( __test_tags ) )
   ENDIF

   RETURN

// -----------------------------------------
// posljednji test tag na stacku
// -----------------------------------------
FUNCTION get_test_tag()

   IF Len( __test_tags ) > 0
      RETURN __test_tags[ Len( __test_tags ) ]
   ELSE
      RETURN "XX"
   ENDIF

   // -------------------------------------------------
   // stavke['keys'] := { { 'A', '<ENTER>' }, {'B', '<PGDN'}
   // stavke['get'] := { "VAR_A", "VAR_B" }
   // -------------------------------------------------

FUNCTION gen_test_keystrokes( stavke )

   LOCAL _ret := hb_Hash()
   LOCAL _kod, nI, _j, _num
   LOCAL _keys
   LOCAL _a_new

   _keys := {}
   FOR nI := 1 TO Len( stavke[ 'get' ] )
      _a_new := { stavke[ 'get' ][ nI ] }
      to_keystrokes( stavke[ 'keys' ][ nI ], @_a_new )

      // if VALTYPE(_a_new[1] ) != "C"
      // Alert(ALLTRIM(STR(nI)) + "/" + pp(_a_new[1]) + " ?!")
      // endif
      AAdd( _keys, _a_new )
   NEXT

   _ret[ "keys" ] := _keys

   RETURN _ret


// --------------------------------------
// --------------------------------------
FUNCTION test_var( key, value )

   IF __test_vars == NIL
      __test_vars := hb_Hash()
   ENDIF

   IF value != NIL
      __test_vars[ key ] := value
   ENDIF

   RETURN __test_vars[ key ]



FUNCTION stop_keystrokes_task()

   hb_idleDel( __task )

   RETURN



FUNCTION test_procedure_with_keystrokes( b_proc, h_keystrokes )

   LOCAL _task, _var_key, _key_test, _key_tests := {}
   LOCAL _tmp
   LOCAL nI := 1
   LOCAL _cnt := 0

   // key sekvenca koju treba izvrsiti
   AAdd( _key_tests, h_keystrokes )

   FOR EACH _key_test IN _key_tests

      __keystrokes := _key_test[ "keys" ]
      __keystroke_step := 1

      CLEAR TYPEAHEAD
      SET CONFIRM ON
      __task := hb_idleAdd( {|| SetPos( MaxRow() -2, MaxCol() -10 ),  DispOut( _cnt++ ), test_keystrokes() } )

      Eval( b_proc )

      log_write( "uklanjam idleadd task", 3 )
      stop_keystrokes_task()


      nI++
   NEXT

   RETURN

// ----------------------------------
// _a_init := { "WID" }
// to_keystrokes({"99", "<ENTER>2"}, @_a_init)
// ----------------------------------
FUNCTION to_keystrokes( a_polja, a_init )

   LOCAL nI, _j, _num, _key

   FOR nI := 1 TO Len( a_polja )

      IF ValType( a_polja[ nI ] ) == "B"

         AAdd( a_init, a_polja[ nI ] )
         LOOP

      ELSEIF ValType( a_polja[ nI ] ) <> "C"
         _msg := "apolja clanovi moraju biti char" + pp( a_polja[ nI ] )
         Alert( _msg )
         log_write( _msg, 2 )
         QUIT
      ENDIF

      DO CASE

      CASE Left( a_polja[ nI ], 8 ) == "<CTRLF9>"
         _key := Left( a_polja[ nI ], 8 )
         _num := SubStr( a_polja[ nI ], 9 )

      CASE Left( a_polja[ nI ], 7 ) == "<ENTER>" .OR. ;
            Left( a_polja[ nI ], 7 ) == "<CTRLT>" .OR. ;
            Left( a_polja[ nI ], 7 ) == "<CTRLN>" .OR. ;
            Left( a_polja[ nI ], 7 ) == "<CTRLP>"

         // <ENTER5> => 5 x enter
         _key := Left( a_polja[ nI ], 7 )
         _num := SubStr( a_polja[ nI ], 8 )
      CASE Left( a_polja[ nI ], 6 ) == "<DOWN>" .OR. ;
            Left( a_polja[ nI ], 6 ) == "<PGDN>" .OR. ;
            Left( a_polja[ nI ], 6 ) == "<HOME>" .OR. ;
            Left( a_polja[ nI ], 6 ) == "<ALTA>" .OR. ;
            Left( a_polja[ nI ], 6 ) == "<ALTP>" .OR. ;
            Left( a_polja[ nI ], 6 ) == "<LEFT>"


         _key := Left( a_polja[ nI ], 6 )
         _num := SubStr( a_polja[ nI ], 7 )


      CASE Left( a_polja[ nI ], 5 ) == "<ESC>"
         // <ESC> => 1 x escape
         _key := Left( a_polja[ nI ], 5 )
         _num := SubStr( a_polja[ nI ], 6 )

      OTHERWISE
         AAdd( a_init, a_polja[ nI ] )
         LOOP
      END CASE

      IF _num == ""
         _num := "1"
      ENDIF


      FOR _j := 1 TO Val( _num )
         DO CASE

         CASE _key == "<CTRLF9>"
            AAdd( a_init, k_ctrl_f9() )

         CASE _key == "<ESC>"
            AAdd( a_init, K_ESC )

         CASE _key == "<ENTER>"
            AAdd( a_init, K_ENTER )

         CASE _key == "<LEFT>"
            AAdd( a_init, K_LEFT )

         CASE _key == "<ALTA>"
            AAdd( a_init, K_ALT_A )

         CASE _key == "<ALTP>"
            AAdd( a_init, K_ALT_P )

         CASE _key == "<CTRLN>"
            AAdd( a_init, K_CTRL_N )

         CASE _key == "<CTRLT>"
            AAdd( a_init, K_CTRL_T )

         CASE _key == "<CTRLP>"
            AAdd( a_init, K_CTRL_P )

         CASE _key == "<HOME>"
            AAdd( a_init, K_HOME )

         CASE _key == "<PGDN>"
            AAdd( a_init, K_PGDN )

         CASE _key == "<DOWN>"
            AAdd( a_init, K_DOWN )

         END CASE
      NEXT


   NEXT

   RETURN a_init

// --------------------------------------
// --------------------------------------
FUNCTION test_keystrokes()

   LOCAL _var_name
   LOCAL nI, _j, _expected_var_name
   LOCAL _buffer, _current_tag, _tag

   log_write( "START test_keystrokes: " + AllTrim( Str( __keystroke_step ) ), 3 )

   FOR nI := 1 TO Len( __keystrokes )

      IF ( __keystroke_step ) <> nI
         log_write( "test_keystrokes loop" + AllTrim( Str( nI ) ), 3 )

         IF nI == Len( __keystrokes )
            stop_keystrokes_task()
         ENDIF
         LOOP
      ENDIF

      _expected_var_name := __keystrokes[ nI, 1 ]

      IF ValType( _expected_var_name ) == "B"
         // npr. { {|| !eof()},  {|| delete_with_rlock()},  {|| log_write("ne treba nista brisati", 2)} }

         // izvrsi trazeni izraz
         _ret := Eval( _expected_var_name )
         IF _ret
            _bl2 := __keystrokes[ nI, 2 ]
         ELSE

            _bl2 := __keystrokes[ nI, 3 ]
         ENDIF

         IF ( ValType( _bl2 ) == "B" )
            Eval( _bl2 )

         ELSEIF ( ValType( _bl2 ) == "A" )

            // moze biti array tipki
            _buffer := {}
            FOR _j := 1 TO Len( _bl2 )
               AAdd( _buffer, _bl2[ _j ] )
            NEXT
            put_to_keyboard_buffer( _buffer )

         ELSE
            Alert( " bl 2 mora biti B ili A" )
         ENDIF


         __keystroke_step ++
         LOOP
      ENDIF

      IF ValType( _expected_var_name ) == "C"

         _expected_var_name := Upper( _expected_var_name )

         IF Left( _expected_var_name, 1 ) == "#"

            // gledaj test tagove
            _tag := SubStr( _expected_var_name, 2 )
            _current_tag := get_test_tag()
            log_write( "test tag current" + pp( _current_tag ) + " expected tag: " + pp( _tag ), 3 )
            IF _tag != _current_tag
               log_write( "test tag current <> expected", 3 )
               EXIT
            ENDIF


         ELSEIF  _expected_var_name == "DBEDIT"
            IF  ProcName( 3 ) == "OBJDBEDIT"
               // nalazimo se u objdbeditu
               // to i zelimo
               log_write( "DBEDIT step: " + AllTrim( Str( nI ) ), 3 )
            ELSE
               log_write( "nismo se jos vratili u DBEDIT: " + AllTrim( Str( nI ) ) + "procname 4-1:" + ProcName( 4 ) + " / " +  ProcName( 3 ) + " / " + ProcName( 2 ) + "/" + ProcName( 1 ), 3 )
               EXIT
            ENDIF
         ELSE
            _var_name := ReadVar()
            log_write( "READVAR: " + _var_name + " expected_var_name: " + _expected_var_name + "procname 6-3:" + ProcName( 6 ) + " / " +  ProcName( 5 ) + " / " + ProcName( 4 ) + "/" + ProcName( 3 ), 3 )

            IF ( _var_name != _expected_var_name )
               // ako tekuca get varijabla nije identicna ocekivanoj, ne salji keytroke
               log_write( "READVAR<>expected - loop", 3 )
               EXIT
            ENDIF

         ENDIF
      ENDIF

      _buffer := {}
      FOR _j := 2 TO Len( __keystrokes[ nI ] )
         AAdd( _buffer, __keystrokes[ nI, _j ] )
      NEXT
      log_write( "test step " + pp( nI ) + "buffer " + pp( _buffer ), 3 )
      put_to_keyboard_buffer( _buffer )

      __keystroke_step ++


   NEXT

   RETURN .T.


STATIC FUNCTION put_to_keyboard_buffer( buffer )

   LOCAL nI

   // CLEAR TYPEAHEAD
   FOR nI := 1 TO Len( buffer )

      IF ValType( buffer[ nI ] ) == "C" .OR.  ValType( buffer[ nI ] ) == "N"
         hb_keyPut( buffer[ nI ] )
      ELSEIF ValType( buffer[ nI ] ) == "B"
         // ako je kodni blok izvrsi ga
         Eval( buffer[ nI ] )
      ELSE
         Alert( "buffer tip: "  + ValType( buffer[ nI ] ) + " ?!" )
      ENDIF

#ifdef SLOW_TESTS
      hb_idleSleep( 0.2 )
#endif

   NEXT

   RETURN .T.
