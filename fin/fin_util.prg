/*
 * This file is part of the bring.out FMK, a free and open source
 * accounting software suite,
 * Copyright (c) 1994-2018 by bring.out d.o.o Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including knowhow ERP specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_knowhow.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */

#include "f18.ch"


// ----------------------------------
// fix brnal
// ----------------------------------
FUNCTION fin_fix_broj_naloga( cBrNal )

   IF Right( AllTrim( cBrNal ), 1 ) == "*"
      cBrNal := StrTran( cBrNal, "*", "" )
      cBrNal := PadL( AllTrim( cBrNal ), 8 )
   ELSEIF Left( AllTrim( cBrNal ), 1 ) == "*"
      cBrNal := StrTran( cBrNal, "*", "" )
      cBrNal := PadR( AllTrim( cBrNal ), 8 )
   ELSE
      IF !Empty( AllTrim( cBrNal ) ) .AND. Len( AllTrim( cBrNal ) ) < 8
         cBrNal := PadL( AllTrim( cBrNal ), 8, "0" )
      ENDIF
   ENDIF

   RETURN .T.


FUNCTION Izvj0()

   RETURN fin_izvjestaji()



FUNCTION Preknjizenje()

   RETURN fin_preknjizenje_konta()


/*
FUNCTION Prebfin_kartica()

   RETURN fin_prekart()
*/


/*
FUNCTION GenPocStanja()

   PrenosFin()

   RETURN
*/



// ------------------------------------------------------
// stampa ostatka opisa
// ------------------------------------------------------
FUNCTION fin_print_ostatak_opisa( cOpis, nCO, bUslov, nSirina )

   LOCAL aOpis, nI

   IF nSirina == NIL
      nSirina := 20
   ENDIF

   aOpis := SjeciStr(cOpis, nSirina)
   IF Empty(AllTrim(aOpis[1]))
      RETURN .T.
   ENDIF

   FOR nI:=1 TO LEN(aOpis)
      IF bUslov != NIL
         Eval( bUslov )
      ENDIF
      @ PRow() + 1, nCO SAY PadR( aOpis[nI], nSirina )
   NEXT

   RETURN .T.


/*

FUNCTION check_ima_u_suban_nema_u_nalog()

   LOCAL nI
   LOCAL _area
   LOCAL _alias
   LOCAL _n_scan
   LOCAL _a_error := {}
   LOCAL _broj_naloga := ""

   my_close_all_dbf()

   o_nalog()
   o_suban()
   o_anal()
   o_sint()

   FOR nI := 1 TO 3

      IF nI == 1
         _alias := "suban"
      ELSEIF nI == 2
         _alias := "anal"
      ELSE
         _alias := "sint"
      ENDIF

      SELECT &_alias
      GO TOP

      DO WHILE !Eof() .AND. Inkey() != 27

         SELECT nalog
         GO TOP
         SEEK &_alias->( idfirma + idvn + brnal )

         IF !Found()

            SELECT &_alias

            _broj_naloga := field->idfirma + "-" + field->idvn + "-" + field->brnal
            _n_scan := AScan( _a_error, {| _var| _var[ 1 ] == _alias .AND. _var[ 2 ] == _broj_naloga } )

            // dadaj u matricu gresaka, ako nema tog naloga
            IF _n_scan == 0
               AAdd( _a_error, { _alias, _broj_naloga } )
            ENDIF

         ENDIF

         SELECT &_alias
         SKIP 1

      ENDDO
   NEXT

   // ispisi greske ako postoje !
   _ispisi_greske( _a_error )

   my_close_all_dbf()

   RETURN
*/

// -----------------------------------------------
// ispis gresaka nakon provjere
// -----------------------------------------------
STATIC FUNCTION _ispisi_greske( a_error )

   LOCAL nI

   IF Len( a_error ) == 0 .OR. a_error == NIL
      RETURN .T.
   ENDIF


   IF !start_print()
      RETURN .F.
   ENDIF

   ?
   ? "Pregled ispravnosti podataka:"
   ? "============================="
   ?
   ? "Potrebno odraditi korekciju sljedecih naloga:"
   ? "---------------------------------------------"

   FOR nI := 1 TO Len( a_error )

      ? PadL( "tabela: " + a_error[ nI, 1 ], 15 ) + ", " + a_error[ nI, 2 ]

   NEXT

   ?
   ? "NAPOMENA:"
   ? "========="
   ? "Naloge je potrebno vratiti u pripremu, provjeriti njihovu ispravnost"
   ? "sa papirnim kopijama te zatim ponovo azurirati."

   FF
   end_print()

   RETURN .T.





FUNCTION fin_storno_naloga()

   RETURN fin_povrat_naloga( .T. )


// ---------------------------------------------
// vraca unos granicnog datuma za report
// ---------------------------------------------
STATIC FUNCTION _g_gr_date()

   LOCAL dDate := Date()
   LOCAL GetList := {}

   Box(, 1, 45 )
   @ box_x_koord() + 1, box_y_koord() + 2 SAY "Unesi granicni datum" GET dDate
   READ
   BoxC()

   IF LastKey() == K_ESC
      RETURN NIL
   ENDIF

   RETURN dDate

/*

// ----------------------------------------------------------------
// report sa greskama sa datumom na nalozima izazvanim opcijom
// "Unos datuma naloga = 'D'"
//
// ----------------------------------------------------------------
FUNCTION daterr_rpt()

   LOCAL __brnal
   LOCAL __idfirma
   LOCAL __idvn
   LOCAL __t_date
   LOCAL dSubanDate
   LOCAL nTotErrors := 0
   LOCAL nNalCnt := 0
   LOCAL nMonth
   LOCAL nSubanKto
   LOCAL nGrDate
   LOCAL nGrMonth
   LOCAL nGrSaldo := 0

   my_close_all_dbf()

   o_suban()
   SELECT suban
   SET ORDER TO TAG "10" // idfirma+idvn+brnal+idkonto+datdok

   o_anal()
   SELECT anal
   SET ORDER TO TAG "2"

   o_nalog()
   SELECT nalog
   SET ORDER TO TAG "1"
   GO TOP

   // granicni datum
   dGrDate := nil

   IF pitanje(, "Gledati granicni datum ?", "N" ) == "D"
      dGrDate := _g_gr_date()
   ENDIF

   IF !start_print()
      RETURN .F.
   ENDIF

   ? "------------------------------------------------"
   ? "Lista naloga sa neispravnim datumima:"
   ? "------------------------------------------------"
   ? "       broj           datum    datum    datum   "
   ? " R.br  naloga         naloga   suban.   anal.   "
   ? "                               prva.st  prva.st "
   ? "------ ------------- -------- -------- -------- "

   DO WHILE !Eof()

      // init. variables

      __idfirma := field->idfirma
      __brnal := field->brnal
      __idvn := field->idvn

      // datum naloga
      __t_date := field->datnal

      ++ nNalCnt

      // provjeri suban.dbf

      SELECT suban
      GO TOP
      SEEK __idfirma + __idvn + __brnal

      IF !Found()

         SELECT nalog
         SKIP
         LOOP

      ENDIF

      dSubanDate := field->datdok



      IF __t_date <> dSubanDate // 1. provjeri prvo da li je razlicit datum naloga i subanalitike

         // uzmi datum sa prve stavke subanilitike

         cSubanKto := field->idkonto
         nMonth := Month( field->datdok )

         DO WHILE !Eof() .AND. field->idfirma == __idfirma ;
               .AND. field->idvn == __idvn ;
               .AND. field->brnal == __brnal ;
               .AND. field->idkonto == cSubanKto

            IF Month( field->datdok ) == nMonth
               dSubanDate := field->datdok
            ENDIF

            SKIP

         ENDDO


         SELECT anal  // provjeri analitiku
         GO TOP
         SEEK __idfirma + __idvn + __brnal

         IF !Found()
            SELECT nalog
            SKIP
            LOOP
         ENDIF

         IF field->datnal <> dSubanDate

            ++ nTotErrors

            ? Str( nTotErrors, 5 ) + ") " + __idfirma + "-" + ;
               __idvn + "-" + AllTrim( __brnal ), __t_date, dSubanDate, field->datnal


         ENDIF


      ENDIF


      // 2. provjeri granicni datum

      IF dGrDate <> nil

         SELECT suban
         GO TOP
         SEEK __idfirma + __idvn + __brnal

         lManji := .F.
         lVeci := .F.



         nGrMonth := Month( dGrDate )  // mjesec granicnog datuma

         // to znaci da nalog mora da sadrzi samo taj mjesec ili manji

         // prodji po nalogu
         DO WHILE !Eof() .AND. suban->( idfirma + idvn + brnal ) == ;
               ( __idfirma + __idvn + __brnal )

            // ako u subanalitici ima manji datum od
            // granicnog datuma
            IF suban->datdok <= dGrDate

               lManji := .T.

               // saldiraj ga
               IF suban->d_p == "1"
                  nGrSaldo += suban->iznosbhd
               ELSE
                  nGrSaldo -= suban->iznosbhd
               ENDIF

            ENDIF

            // ako u subanalitici ima veci datum od granicnog datuma i iskace iz mjeseca
            IF suban->datdok > dGrDate .AND. ;
                  Month( suban->datdok ) > nGrMonth

               lVeci := .T.
            ENDIF

            SKIP

         ENDDO

         // ako unutar jednog naloga ima i veci i manji datum od granicnog datuma pretpostavljamo da je to error

         IF lManji == .T. .AND. lVeci == .T.

            ++ nTotErrors

            ? Str( nTotErrors, 5 ) + ") " + __idfirma + "-" + ;
               __idvn + "-" + AllTrim( __brnal ), ;
               nalog->datnal, "ERR: granicni datum"

         ENDIF

      ENDIF


      SELECT nalog
      SKIP

   ENDDO

   IF nTotErrors == 0
      ?
      ? "   !!!!! Nema gresaka !!!!!"
      ?
   ENDIF

   IF dGrDate <> NIL .AND. nGrSaldo <> 0

      ?
      ? " Razlika utvrdjena po granicnom datumu =", Str( nGrSaldo, 12, 2 )
      ?

   ENDIF

   my_close_all_dbf()

   ff
   end_print()

   RETURN

*/

FUNCTION BBMnoziSaK( cTip )

   LOCAL nArr := Select()

   IF cTip == valuta_domaca_skraceni_naziv() .AND. my_get_from_ini( "FIN", "BrutoBilansUDrugojValuti", "N", KUMPATH ) == "D"
      Box(, 5, 70 )
      @ box_x_koord() + 2, box_y_koord() + 2 SAY "Pomocna valuta      " GET cBBV PICT "@!" VALID ImaUSifVal( cBBV )
      @ box_x_koord() + 3, box_y_koord() + 2 SAY "Omjer pomocna/domaca" GET nBBK WHEN {|| nBBK := OmjerVal2( cBBV, cTip ), .T. } PICT "999999999.999999999"
      READ
      BoxC()
   ELSE
      cBBV := cTip
      nBBK := 1
   ENDIF

   SELECT ( nArr )

   RETURN
