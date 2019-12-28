
#include "getexit.ch"
#include "inkey.ch"


clear


hb_setKey( K_CTRL_C, { | o |  Inkey(0), Alert( Chr( LastKey() ) ), SetPos( 10, 10), QQout(  __GetListActive():Get():varGet() ) } )

cTest := "ABCD"

@ 5, 5 SAY "Test:" GET cTest

oGet := ATail( GetList )

//oGet:reader := { | oGet | custom_reader( oGet ) }

? "reader:", Len(GetList), oGet:className, oGet:varGet(), oGet:reader()

? "ok"
inkey(0)


READ

? "Test=", cTest

inkey(0)

return


PROCEDURE custom_reader( oGet )

   LOCAL nKey, nKeyStd, bKeyBlock
   LOCAL oGetList := __GetListActive()

//   IF ! wvw_cbIsFocused( , oGet:cargo )
//      wvw_cbSetFocus( , oGet:cargo )
//   ENDIF

   oGet:setfocus()
   nKeyStd := hb_keyStd( nKey := Inkey( 0, hb_bitOr( Set( _SET_EVENTMASK ), HB_INKEY_EXT ) ) )

   DO CASE
   CASE nKeyStd == K_ENTER
      // NOTE that in WVW_CB_KBD_CLIPPER mode we will never get here
      oGet:exitState := GE_DOWN

   CASE nKeyStd == K_UP
      oGet:exitState := GE_UP

   CASE nKeyStd == K_SH_TAB
      oGet:exitState := GE_UP

   CASE nKeyStd == K_DOWN
      // NOTE that in WVW_CB_KBD_STANDARD mode we will never get here
      oGet:exitState := GE_DOWN

   CASE nKeyStd == K_TAB
      oGet:exitState := GE_DOWN

   CASE nKeyStd == K_ESC
      IF Set( _SET_ESCAPE )
         oGet:exitState := GE_ESCAPE
      ENDIF

   CASE nKeyStd == K_PGUP
      oGet:exitState := GE_WRITE

   CASE nKeyStd == K_PGDN
      oGet:exitState := GE_WRITE

   CASE nKeyStd == K_CTRL_HOME
      oGet:exitState := GE_TOP

   CASE nKeyStd == K_LDBLCLK
      // is there any GET object hit?
      IF Empty( HitTest( oGetList:aGetList, MRow(), MCol() ) )
         oGet:exitState := GE_NOEXIT
      ELSE
         oGet:exitState := GE_MOUSEHIT
      ENDIF

   CASE HB_ISEVALITEM( bKeyBlock := SetKey( nKey ) ) .OR. ;
        HB_ISEVALITEM( bKeyBlock := SetKey( nKeyStd ) )

      oGetList:GetDoSetKey( bKeyBlock )  // Eval(bKeyBlock)
      oGet:exitState := GE_NOEXIT

   ENDCASE

   IF oGet:exitState != GE_NOEXIT
      //SetWinFocus( NIL )  // assume current window
      oGet:killfocus()
   ENDIF

   RETURN
