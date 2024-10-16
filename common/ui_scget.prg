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


THREAD STATIC  __get_list


// state variables for active READ
STATIC FORMAT
STATIC Updated := .F.
STATIC KillReadSC
STATIC BumpTop
STATIC BumpBot
STATIC LastExit
STATIC LastPos
STATIC ActiveGet
STATIC ReadProcName
STATIC ReadProcLine


// Modifications
#ifndef NOCHANGES

// Time-out variable
STATIC lTimedOut := .F.
STATIC nTimeOut

// GOTOGET and START AT get variable
STATIC nToGet

// Exit at Get variable
STATIC nAtGet

#endif






/***
* GetPreValidate()
* Test entry condition (WHEN clause) for a GET.
*/
FUNCTION GetPreValSC( get )

   LOCAL saveUpdated
   LOCAL lWhen := .T.

   IF ( get:preBlock <> NIL )

      saveUpdated := Updated

      lWhen := Eval( get:preBlock, get )

      get:Display()

      ShowScoreBoard()
      Updated := saveUpdated

   ENDIF


   IF ( KillReadSC )
      // MsgBeep("KillreadSC=.t./1")
      lWhen := .F.
      get:exitState := GE_ESCAPE
      // provokes ReadModal() exit

   ELSEIF ( !lWhen )
      get:exitState := GE_WHEN
      // indicates failure

   ELSE
      get:exitState := GE_NOEXIT
      // prepares for editing

   ENDIF

   RETURN ( lWhen )



/***
* GetPstValSC()
* Test exit condition (VALID clause) for a GET.
*
* NOTE: bad dates are rejected in such a way as to preserve edit buffer.
*/

FUNCTION GetPstValSC( get )

   LOCAL saveUpdated
   LOCAL changed, valid := .T.

   IF ( get:exitState == GE_ESCAPE )
      RETURN ( .T. )
      // NOTE
   ENDIF

   IF ( get:BadDate() )
      get:Home()
      DateMsg()
      ShowScoreboard()
      RETURN ( .F. )     // NOTE
   ENDIF


   // if editing occurred, assign the new value to the variable
   IF ( get:changed )
      get:Assign()
      Updated := .T.
   ENDIF


   // reform edit buffer, set cursor to home position, redisplay
   get:Reset()


   // check VALID condition if specified
   IF ( get:postBlock <> NIL )

      saveUpdated := Updated

      // S87 compat.
      SetPos( get:row, get:col + Len( get:buffer ) )

      valid := Eval( get:postBlock, get )

      // reset compat. pos
      SetPos( get:row, get:col )

      ShowScoreBoard()
      get:UpdateBuffer()

      Updated := saveUpdated

      IF ( KillReadSC )

         // MsgBeep("KillreadSC=.t./2")

         // provokes ReadModal() exit
         get:exitState := GE_ESCAPE
         valid := .T.
      END

   ENDIF

   RETURN ( valid )




/***
* GetDoSetKSC()
* Process SET KEY during editing.
*/
FUNCTION GetDoSetKSC( keyBlock, get )

   LOCAL saveUpdated

   // if editing has occurred, assign variable
   IF ( get:changed )
      get:Assign()
      Updated := .T.
   END


   saveUpdated := Updated

   Eval( keyBlock, ReadProcName, ReadProcLine, ReadVar() )

   ShowScoreboard()
   get:UpdateBuffer()

   Updated := saveUpdated


   IF ( KillReadSC )

      // MsgBeep("KillreadSC=.t. / 3")
      get:exitState := GE_ESCAPE  // provokes ReadModal() exit
   END

   RETURN



/*
*
* READ services
*
*/


/***
* SettleSC()
*
* Returns new position in array of Get objects, based on
*
*  - current position
*  - exitState of Get object at current position
*
* NOTE return value of 0 indicates termination of READ
* NOTE exitState of old Get is transferred to new Get
*/
STATIC FUNCTION SettleSC( GetList, pos )

   LOCAL lExitState

   // MsgBeep(STR(Len(GetList)))


   IF ( pos == 0 )
      lExitState := GE_DOWN
   ELSE
      lExitState := GetList[ pos ]:exitState
   ENDIF


   IF ( lExitState == GE_ESCAPE )
      // MsgBeep("escape ...")
      RETURN 0
   ENDIF

   IF ( lExitState == GE_WRITE )
      // MsgBeep("pg_down")
      RETURN 0
   ENDIF


   IF ( lExitState <> GE_WHEN )
      // reset state info
      LastPos := pos
      BumpTop := .F.
      BumpBot := .F.

   ELSE
      // re-use last exitState, do not disturb state info
      lExitState := LastExit

   ENDIF


/***
* move
*/
   DO CASE
   CASE ( lExitState == GE_UP )
      pos--

   CASE ( lExitState == GE_DOWN )
      pos++

   CASE ( lExitState == GE_TOP )
      pos := 1
      BumpTop := .T.
      exitState := GE_DOWN

   CASE ( lExitState == GE_BOTTOM )
      pos := Len( GetList )
      BumpBot := .T.
      lExitState := GE_UP

   CASE ( lExitState == GE_ENTER )
      pos++

   CASE ( lExitState < 0 .AND. -lExitState <= Len( GetList ) )
      pos := -lExitState
      lExitState := GE_NOEXIT


   ENDCASE


/**
 * bounce
*/
   IF ( pos == 0 )
      // bumped top

      IF ( !ReadExitSC() .AND. !BumpBot )
         BumpTop := .T.
         pos := LastPos
         lExitState := GE_DOWN
      ENDIF

   ELSEIF ( pos == Len( GetList ) + 1 )
      // bumped bottom

      IF ( !ReadExitSC() .AND. lExitState <> GE_ENTER .AND. !BumpTop )
         BumpBot := .T.
         pos := LastPos
         lExitState := GE_UP
      ELSE

         // MsgBeep("settle 0-2")
         pos := 0
      ENDIF
   ENDIF


   // record exit state
   LastExit := lExitState

   IF ( pos <> 0 )
      GetList[ pos ]:exitState := lExitState
   ENDIF

   RETURN ( pos )



/***
* PstActGetSc()
* Post active GET for ReadVar(), GetActive().
*/
STATIC PROCEDURE PstActGetSC( get )

   GetActive( get )
   ReadVar( GetReadVSC( get ) )

   ShowScoreBoard()

   RETURN



/***
* ClrGetSysVarSC()
* Save and clear READ state variables. Return array of saved values.
*
* NOTE: 'Updated' status is cleared but not saved (S87 compat.).
*/
STATIC FUNCTION ClrGetSysVarSC()

   LOCAL saved[ GSV_COUNT ]

   saved[ GSV_KILLREAD ] := KillReadSC
   KillReadSC := .F.

   saved[ GSV_BUMPTOP ] := BumpTop
   BumpTop := .F.

   saved[ GSV_BUMPBOT ] := BumpBot
   BumpBot := .F.

   saved[ GSV_LASTEXIT ] := LastExit
   LastExit := 0

   saved[ GSV_LASTPOS ] := LastPos
   LastPos := 0

   saved[ GSV_ACTIVEGET ] := GetActive( NIL )

   saved[ GSV_READVAR ] := ReadVar( "" )

   saved[ GSV_READPROCNAME ] := ReadProcName
   ReadProcName := ""

   saved[ GSV_READPROCLINE ] := ReadProcLine
   ReadProcLine := 0

   Updated := .F.

   RETURN ( saved )



/***
*   RstGetSysVarSC()
* Restore READ state variables from array of saved values.
*
* NOTE: 'Updated' status is not restored (S87 compat.).
*/
STATIC FUNCTION RstGetSysVarSC( saved )

   KillReadSC := saved[ GSV_KILLREAD ]

   BumpTop := saved[ GSV_BUMPTOP ]

   BumpBot := saved[ GSV_BUMPBOT ]

   LastExit := saved[ GSV_LASTEXIT ]

   LastPos := saved[ GSV_LASTPOS ]

   GetActive( saved[ GSV_ACTIVEGET ] )

   ReadVar( saved[ GSV_READVAR ] )

   ReadProcName := saved[ GSV_READPROCNAME ]

   ReadProcLine := saved[ GSV_READPROCLINE ]

   RETURN



/***
* GetReadVSC()
* Set READVAR() value from a GET.
*/
STATIC FUNCTION GetReadVSC( get )

   LOCAL name := Upper( get:name )
   LOCAL i

   // #ifdef SUBSCRIPT_IN_READVAR

 /***
 * The following code includes subscripts in the name returned by
 * this function, if the get variable is an array element.
 *
 * Subscripts are retrieved from the get:subscript instance variable.
 *
 * NOTE: incompatible with Summer 87
 */

   IF ( get:subscript <> NIL )
      FOR i := 1 TO Len( get:subscript )
         name += "[" + LTrim( Str( get:subscript[ i ] ) ) + "]"
      NEXT
   END

   // #endif

   RETURN ( name )



/*
*
* system services
*
*/



/***
* __KillReadSC()
*   CLEAR GETS service
*/
FUNCTION __KillReadSC()

   KillReadSC := .T.

   // MsgBeep("KillreadSC=.t./4")

   RETURN





/***
* ReadExitSC()
*/
FUNCTION ReadExitSC( lNew )
   RETURN ( Set( _SET_EXIT, lNew ) )



/*
*
* wacky compatibility services
*
*/


// display coordinates for SCOREBOARD
#define SCORE_ROW  0
#define SCORE_COL  60


/***
*   ShowScoreboard()
*/
STATIC PROCEDURE ShowScoreboard()

   LOCAL nRow, nCol

   IF ( Set( _SET_SCOREBOARD ) )
      nRow := Row()
      nCol := Col()

      SetPos( SCORE_ROW, SCORE_COL )
      DispOut( if( Set( _SET_INSERT ), "Ins", "   " ) )
      SetPos( nRow, nCol )
   ENDIF

   RETURN



/***
* DateMsg()
*/
STATIC PROCEDURE DateMsg()

   LOCAL nRow, nCol

   IF ( Set( _SET_SCOREBOARD ) )
      nRow := Row()
      nCol := Col()

      SetPos( SCORE_ROW, SCORE_COL )
      DispOut( "Invalid Date" )
      SetPos( nRow, nCol )

      WHILE ( NextKey() == 0 )
      END

      SetPos( SCORE_ROW, SCORE_COL )
      DispOut( "            " )
      SetPos( nRow, nCol )

   END

   RETURN



//
// Time-Out?
//
// /

FUNCTION TimedOut()
   RETURN ( lTimedOut )

/**
 *
 * Time-Out feature
 *
 */

STATIC FUNCTION MyInKeySc()

   LOCAL nKey
   LOCAL nBroji2
   LOCAL nCursor

   nBroji2 := Seconds()
   nTimeout := Seconds()

   nKey := Inkey()

   RETURN ( nKey )

/*
 * Go to a particular get
 */

FUNCTION GoToGet( nGet )

   GetActive():exitState := -nGet

   // !!!!NOTE!!!!

   RETURN ( .T. )

/*
 *
 * What was the Get?
 *
 */

FUNCTION ExitAtGet()
   RETURN ( nAtGet )


FUNCTION ShowGets()

   AEval( GetList, {| oE|  oE:Display() } )

   RETURN .T.

FUNCTION RefreshGets()

   AEval( MGetList, {| oE|  oE:Display() } )

   RETURN .T.


// -----------------------------
// -----------------------------
FUNCTION InkeySc( nSec )

   IF ( nSec == 0 )
      RETURN Inkey()
   ELSE
      RETURN Inkey( nSec )
   ENDIF


   // --------------------------------------------------------------------
   // sva polja disableujemo osim onoga na koje zelimo "skociti"
   // -------------------------------------------------------------------

FUNCTION get_field_set_focus( f_name )

   LOCAL nI

   __get_list := {}

   FOR nI := 1 TO Len( GetList )
      AAdd( __get_list, GetList[ nI ]:PreBlock )

      IF GetList[ nI ]:name() == f_name
         GetList[ nI ]:PreBlock := {|| restore_get_list(), .T. }
      ELSE
         GetList[ nI ]:PreBlock := {|| .F. }
      ENDIF
   NEXT

   RETURN .T.


FUNCTION restore_get_list()

   LOCAL nI

   FOR nI := 1 TO Len( GetList )
      GetList[ nI ]:PreBlock := __get_list[ nI ]
   NEXT

   FOR nI := Len( GetList ) TO 1 STEP -1
      ADel( __get_list, nI )
   NEXT

   __get_list := NIL

   RETURN .T.



FUNCTION read_dn_parametar( caption, xpos, ypos, value )

   @ xpos, ypos SAY8 caption + " (D/N) ?" GET value VALID value $ "DN" PICT "@!"

   RETURN value
