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


FUNCTION os_rpt_default_valute()

   LOCAL GetList := {}

   LOCAL nArr := Select()

   IF ( gDrugaVal == "D" .AND. cTip == valuta_domaca_skraceni_naziv() )
      Box(, 5, 70 )
      @ box_x_koord() + 2, box_y_koord() + 2 SAY "Pomocna valuta      " GET cBBV PICT "@!" VALID ImaUSifVal( cBBV )
      @ box_x_koord() + 3, box_y_koord() + 2 SAY "Omjer pomocna/domaca" GET nBBK WHEN {|| nBBK := OmjerVal( cBBV, cTip ), .T. } PICT "999999999.999999999"
      READ
      BoxC()
   ELSE
      cBBV := cTip
      nBBK := 1
   ENDIF
   SELECT ( nArr )

   RETURN .T.


FUNCTION PrikazVal()
   RETURN ( IIF( gDrugaVal == "D", " VALUTA:'" + Trim( cBBV ) + "'", "" ) )


/*
-- FUNCTION os_kartica_sredstva()

   o_os_sii_promj()
   o_os_sii()

   cId := Space( Len( id ) )

   cPicSif := "@!"

   // zadajmo jedno ili sva sredstva
   // ------------------------------
   Box( "#PREGLED KARTICE SREDSTVA", 4, 77 )
   @ box_x_koord() + 2, box_y_koord() + 2 SAY "Inventurni broj (prazno-sva sredstva)" GET cid VALID Empty( cId ) .OR. p_os( @cId ) PICT cPicSif
   READ
   ESC_BCR
   BoxC()

   // nadjimo sve postojece sezone
   // ----------------------------
   aSezone := ASezona( KUMPATH )
   cTekSez := Str ( Year( Date() ), 4 )
   FOR i := Len( aSezone ) TO 1 STEP -1
      IF aSezone[ i, 1 ] > cTekSez .OR. aSezone[ i, 1 ] < "1995" .OR. ;
            !File( KUMPATH + aSezone[ i, 1 ] + "\OS.DBF" ) .OR. ;
            !File( KUMPATH + aSezone[ i, 1 ] + "\OS.CDX" ) .OR. ;
            !File( KUMPATH + aSezone[ i, 1 ] + "\PROMJ.DBF" ) .OR. ;
            !File( KUMPATH + aSezone[ i, 1 ] + "\PROMJ.CDX" )
         ADel( aSezone, i )
         ASize( aSezone, Len( aSezone ) -1 )
      ENDIF
   NEXT
   ASort( aSezone,,, {| x, y| x[ 1 ] < y[ 1 ] } )

   IF Len( aSezone ) < 1
      MsgBeep( "Nema proslih sezona pa kartice nisu potrebne!" )
      CLOSERET
   ENDIF

   // pootvarajmo baze OS i PROMJ iz svih postojecih sezona
   // -----------------------------------------------------
   FOR i := 1 TO Len( aSezone )
      USE ( KUMPATH + aSezone[ i, 1 ] + "\OS" )    NEW Alias ( "OS" + aSezone[ i, 1 ] )
      SET ORDER TO TAG "1"
      USE ( KUMPATH + aSezone[ i, 1 ] + "\PROMJ" ) NEW Alias ( "PROMJ" + aSezone[ i, 1 ] )
      SET ORDER TO TAG "1"
   NEXT

   select_o_os_or_sii()
   IF Empty( cId )
      // sve kartice
      GO TOP
   ELSE
      // jedna kartica
      HSEEK cId
   ENDIF

   IF Eof()
      MsgBeep( "U radnom podrucju nema nijednog sredstva!" )
      CLOSERET
   ENDIF

   START PRINT CRET
   P_COND2

   DO WHILE !Eof()
      cInvBr := id
      aPom := aPom2 := {}
      nLastNV := nLastOV := 0
      FOR i := 1 TO Len( aSezone )
         cSez := aSezone[ i, 1 ]
         SELECT ( "OS" + cSez ); HSEEK cInvBr
         IF Found()
            aPom2 := {}
            SELECT ( "PROMJ" + cSez ); HSEEK cInvBr
            IF Found()
               DO WHILE !Eof() .AND. id == cInvBr
                  // IF otpvr==0
                  // nabavka - prvo evidentiranje
                  AAdd( aPom2, { datum, nabvr, 0, 0, otpvr, 0, 0 } )
                  AAdd( aPom2, { CToD( "31.12." + cSez ), 0, revd, 0, amp, revp, 0 } )
                  // ELSE
                  // AADD(aPom2,{CTOD("31.12."+cSez),0,revd,0,amp,revp,0})
                  // ENDIF
                  SKIP 1
               ENDDO
            ENDIF
            SELECT ( "OS" + cSez )
            IF Len( aPom ) > 0
               AAdd( aPom, { CToD( "31.12." + cSez ), 0, revd, 0, amp, revp, 0 } )
               IF Round( nabvr, 2 ) <> Round( nLastNV, 2 )
                  // denominacija ili greska !
                  // ( greska je ako nisu preneseni efekti am.i rev. u slj.godinu
                  // ili ako je posljednji pokrenuti obracun prethodne godine
                  // razlicit od konacnog )
                  nKD  := IF( nLastNV = 0, 0, nabvr / nLastNV )
                  nKD2 := IF( nLastOV = 0, 0, otpvr / nLastOV )
                  AAdd( aPom, { CToD( "01.01." + cSez ), 0, 0, nKD, 0, 0, nKD2 } )
               ENDIF
            ELSE
               // nabavka - prvo evidentiranje
               AAdd( aPom, { datum, nabvr, 0, 0, otpvr, 0, 0 } )
               AAdd( aPom, { CToD( "31.12." + cSez ), 0, revd, 0, amp, revp, 0 } )
            ENDIF
            nLastNV := nabvr + revd
            nLastOV := otpvr + revp + amp
            FOR j := 1 TO Len( aPom2 )
               nLastNV += ( aPom2[ j, 2 ] + aPom2[ j, 3 ] )
               nLastOV += ( aPom2[ j, 5 ] + aPom2[ j, 6 ] )
               AAdd( aPom, aPom2[ j ] )
            NEXT
         ENDIF
      NEXT
      select_o_os_or_sii()

      IF Len( aPom ) > 0
         ASort( aPom,,, {| x, y| x[ 1 ] < y[ 1 ] } )
         IF Len( aPom ) + 11 + PRow() > 64 + dodatni_redovi_po_stranici()
            FF
         ENDIF
         ?
         ? "INVENTURNI BROJ:", cInvBr
         ? "NAZIV          :", naz
         ? "OPIS           :", opis, IIF( !datotp_prazan(), "OTPIS: " + Trim( opisotp ) + " " + DToC( datotp ) + " !", "" )
         ? "��������������������������������������������������������������������������������������������������������������������������������Ŀ"
         ? "�        �       N A B A V N A    V R I J E D N O S T         �       O T P I S A N A    V R I J E D N O S T       �             �"
         ? "� DATUM  ���������������������������������������������������������������������������������������������������������Ĵ   SADASNJA  �"
         ? "�        �PRVA/DODATNA�REVALORIZAC.�KOEF.DENOM. � U K U P N A �AMORTIZACIJA�REVALORIZAC.�KOEF.DENOM. � U K U P N A �  VRIJEDNOST �"
         ? "��������������������������������������������������������������������������������������������������������������������������������Ĵ"
         cK := "�"
         cT := "999999999.99"
         cTU := "9999999999.99"
         nNV := nOV := 0
         FOR i := 1 TO Len( aPom )
            nNV += ( aPom[ i, 2 ] + aPom[ i, 3 ] )
            nOV += ( aPom[ i, 5 ] + aPom[ i, 6 ] )
            IF aPom[ i, 4 ] <> 0
               nNV := aPom[ i, 4 ] * nNV
            ENDIF
            IF aPom[ i, 7 ] <> 0
               nOV := aPom[ i, 7 ] * nOV
            ENDIF
            lErr := .F.
            IF Round( aPom[ i, 4 ], 2 ) <> Round( aPom[ i, 7 ], 2 )
               lErr := .T.
            ENDIF
            ? cK
            ?? aPom[ i, 1 ]          ; ?? cK
            ?? TRANSMN( aPom[ i, 2 ], cT ); ?? cK
            ?? TRANSMN( aPom[ i, 3 ], cT ); ?? cK
            ?? TRANSMN( aPom[ i, 4 ], cT ); ?? cK
            ?? TRANS( nNV, cTU )     ; ?? cK
            ?? TRANSMN( aPom[ i, 5 ], cT ); ?? cK
            ?? TRANSMN( aPom[ i, 6 ], cT ); ?? cK
            ?? TRANSMN( aPom[ i, 7 ], cT ); ?? cK
            ?? TRANS( nOV, cTU )     ; ?? cK
            ?? TRANS( nNV - nOV, cTU ) ; ?? cK
            IF lErr; ?? " ERR?!"; ENDIF
         NEXT
         ? "����������������������������������������������������������������������������������������������������������������������������������"
         ?
      ENDIF

      IF !Empty( cId )
         EXIT
      ELSE
         SKIP 1
      ENDIF
   ENDDO

   FF
   ENDPRINT

   CLOSERET

   RETURN
// }
*/


// -----------------------------------------------------------
// vraca niz poddirektorija koji nemaju ekstenziju u nazivu
// a nalaze se u direktoriju cPath (npr. "c:\sigma\fin\kum1\")
// -----------------------------------------------------------
STATIC FUNCTION ASezona( cPath )

   // {
   LOCAL aSezone
   aSezone := Directory( cPath + "*.", "DV" )
   FOR i := Len( aSezone ) TO 1 STEP -1
      IF ( aSezone[ i, 1 ] == "." .OR. aSezone[ i, 1 ] == ".." )
         ADel( aSezone, i )
         ASize( aSezone, Len( aSezone ) -1 )
      ENDIF
   NEXT

   RETURN aSezone
// }



FUNCTION TranSMN( x, cT )

   // {

   RETURN IF( x == 0, Space( Len( TRANS( x, cT ) ) ), TRANS( x, cT ) )
// }
