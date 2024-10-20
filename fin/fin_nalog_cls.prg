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


/* ---------------------------------------- CLASS FinNalozi ------------------------------------------------------- */

CLASS FinNalozi

   METHOD New()
   METHOD addNalog( oFinNalog )                // dodaj FinNalog
   METHOD getNalog( cIdFirma, cIdVn, cBrNal )  // nađi FinNalog na osnovu broja
   METHOD valid()
   METHOD showErrors()

   DATA aNalozi // ARRAY OF FinNalog
   DATA cErrors // sve poruke o gresci

ENDCLASS


METHOD FinNalozi:New()

   ::aNalozi := {}
   ::cErrors := ""

   RETURN Self


METHOD FinNalozi:addNalog( oFinNalog )

   AAdd( ::aNalozi, oFinNalog )

   RETURN .T.


METHOD FinNalozi:getNalog( cIdFirma, cIdVn, cBrNal )

   LOCAL nPos

   nPos := AScan( ::aNalozi, {| oNalog |  oNalog:cIdFirma == cIdFirma .AND. oNalog:cIdVN == cIdVN .AND. oNalog:cBrNal == cBrNal  } )

   IF nPos > 0
      RETURN ::aNalozi[ nPos ]
   ENDIF

   RETURN NIL


METHOD FinNalozi:valid()

   LOCAL cError, nPos

   ::cErrors := ""
   AEval( ::aNalozi, {| oNalog | oNalog:valid(), iif( oNalog:lError, ::cErrors += "#" + oNalog:cError + "#", .F. ) } )
   nPos := AScan( ::aNalozi, {| oNalog | oNalog:lError } )

   IF nPos > 0
      RETURN .F.
   ENDIF

   RETURN .T.


METHOD FinNalozi:showErrors()

   MsgBeep( ::cErrors )

   RETURN NIL

/* ---------------------------------------- CLASS FinNalog ------------------------------------------------------- */

CLASS FinNalog

   METHOD New( cIdFirma, cIdVn, cBrNal )
   METHOD addStavka( dDatDok ) // dodaj stavku u FIN nalog, interesuje nas sao datum dokumenta
   METHOD setDatumNaloga()
   METHOD cBroj()
   METHOD validDatumi()
   METHOD valid()


   DATA cIdFirma
   DATA cIdVN
   DATA cBrNal
   DATA dDatumNaloga

   DATA lError
   DATA cError

   DATA dMinDatDok  // najmanji datum dokumenta unutar naloga
   DATA dMaxDatDok  // najveći datum dokumenta

END CLASS


METHOD FinNalog:New( cIdFirma, cIdVN, cBrNal )

   ::dMinDatDok := NIL
   ::dMaxDatDok := NIL

   ::cIdFirma := cIdFirma
   ::cIdVN := cIdVN
   ::cBrNal := cBrNal

   ::lError := .F.
   ::cError := ""

   RETURN Self


METHOD FinNalog:cBroj()

   RETURN ::cIdFirma + " - " + ::cIdVn + " - " + ::cBrNal

/*
   dodajemo stavku finansijskog naloga
   interesuje nas samo datum dokumenta
*/
METHOD FinNalog:addStavka( dDatDok )

   IF ::dMinDatDok == NIL
      ::dMinDatDok := dDatDok
   ENDIF

   IF ::dMaxDatDok == NIL
      ::dMaxDatDok := dDatDok
   ENDIF

   IF dDatDok < ::dMinDatDok
      ::dMinDatDok := dDatDok
   ENDIF

   IF dDatDok > ::dMaxDatDok
      ::dMaxDatDok := dDatDok
   ENDIF

   ::setDatumNaloga()

   RETURN .T.


METHOD FinNalog:setDatumNaloga()

   LOCAL nYear, nMonth

   // hbct: Zadnji dan u mjesecu: 17.02.2014 => 28.02.2014
   ::dDatumNaloga := EoM( ::dMaxDatDok )

   RETURN .T.


METHOD FinNalog:validDatumi()

   ::cError := ""

   // godina za sve stavke mora biti ista
   IF Year( ::dMinDatDok ) != Year( ::dMaxDatDok )
      ::cError += "stavke " + ::cBroj() + " obuhvataju više od jedne godine"
      RETURN .F.
   ENDIF

   // sve stavke naloga moraju pripadati jednom mjesecu
   IF Month( ::dMinDatDok ) != Month( ::dMaxDatDok )
      IF !Empty( ::cError )
         ::cError += "#"
      ENDIF
      ::cError += "stavke " + ::cBroj() + " se odnose na više mjeseci"
      RETURN .F.
   ENDIF

   RETURN .T.


METHOD FinNalog:valid()

   LOCAL lRet

   lRet := ::validDatumi()
   ::lError := !lRet

   RETURN lRet
