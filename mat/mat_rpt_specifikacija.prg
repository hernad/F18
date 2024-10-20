/*
 * This file is part of the bring.out FMK, a free and open source
 * accounting software suite,
 * Copyright (c) 1996-2011 by bring.out doo Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including FMK specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_FMK.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */


#include "f18.ch"

// RUDNIK - pregled isporucenog materijala
// po mjestima troskova
FUNCTION PoMjeTros()

   o_partner()
   O_MAT_SUBAN

   qqRoba1 := Space( 60 ); cRoba1 := Space( 10 )
   qqRoba2 := Space( 60 ); cRoba2 := Space( 10 )
   qqRoba3 := Space( 60 ); cRoba3 := Space( 10 )
   qqRoba4 := Space( 60 ); cRoba4 := Space( 10 )
   qqRoba5 := Space( 60 ); cRoba5 := Space( 10 )
   qqRoba6 := Space( 60 ); cRoba6 := Space( 10 )
   qqIDVN := Space( 30 )
   dDatOd := CToD( "" ); dDatDo := Date(); gOstr := "D"; gTabela := 1

   o_params()
   PRIVATE cSection := "5", cHistory := " "; aHistory := {}
   Params1()
   RPar( "d1", @dDatOd ); RPar( "d2", @dDatDo )
   RPar( "O1", @cRoba1 ); RPar( "O2", @cRoba2 ); RPar( "O3", @cRoba3 )
   RPar( "O4", @cRoba4 ); RPar( "O5", @cRoba5 ); RPar( "O6", @cRoba6 )
   RPar( "F1", @qqRoba1 ); RPar( "F2", @qqRoba2 ); RPar( "F3", @qqRoba3 )
   RPar( "F4", @qqRoba4 ); RPar( "F5", @qqRoba5 ); RPar( "F6", @qqRoba6 )
   RPar( "F7", @qqIDVN )

   qqRoba1 := PadR( qqRoba1, 60 ); qqRoba2 := PadR( qqRoba2, 60 ); qqRoba3 := PadR( qqRoba3, 60 )
   qqRoba4 := PadR( qqRoba4, 60 ); qqRoba5 := PadR( qqRoba5, 60 ); qqRoba6 := PadR( qqRoba6, 60 )
   qqIDVN := PadR( qqIDVN, 30 )


   Box(, 12, 70 )
   DO WHILE .T.
      @ box_x_koord() + 1, box_y_koord() + 15 SAY "NAZIV               USLOV"
      @ box_x_koord() + 2, box_y_koord() + 2 SAY "Asortiman 1" GET cRoba1
      @ box_x_koord() + 2, box_y_koord() + 26 GET qqRoba1    PICT "@!S30"
      @ box_x_koord() + 3, box_y_koord() + 2 SAY "Asortiman 2" GET cRoba2
      @ box_x_koord() + 3, box_y_koord() + 26 GET qqRoba2    PICT "@!S30"
      @ box_x_koord() + 4, box_y_koord() + 2 SAY "Asortiman 3" GET cRoba3
      @ box_x_koord() + 4, box_y_koord() + 26 GET qqRoba3    PICT "@!S30"
      @ box_x_koord() + 5, box_y_koord() + 2 SAY "Asortiman 4" GET cRoba4
      @ box_x_koord() + 5, box_y_koord() + 26 GET qqRoba4    PICT "@!S30"
      @ box_x_koord() + 6, box_y_koord() + 2 SAY "Asortiman 5" GET cRoba5
      @ box_x_koord() + 6, box_y_koord() + 26 GET qqRoba5    PICT "@!S30"
      @ box_x_koord() + 7, box_y_koord() + 2 SAY "Asortiman 6" GET cRoba6
      @ box_x_koord() + 7, box_y_koord() + 26 GET qqRoba6    PICT "@!S30"

      @ box_x_koord() + 9, box_y_koord() + 2 SAY "Za period od" GET dDatOD
      @ box_x_koord() + 9, Col() + 2 SAY "do" GET dDatDo
      @ box_x_koord() + 10, box_y_koord() + 2 SAY "Uslov za vrstu naloga" GET qqIDVN PICT "@!"
      @ box_x_koord() + 11, box_y_koord() + 2 SAY "Ukljuceno ostranicavanje ? (D/N)" GET gOstr VALID gOstr $ "DN" PICT "@!"
      @ box_x_koord() + 11, box_y_koord() + 38 SAY "Tip tabele (0/1/2)" GET gTabela VALID gTabela < 3 .AND. gTabela >= 0 PICT "9"
      read; ESC_BCR
      aUsl1 := Parsiraj( qqRoba1, "IDROBA" )
      aUsl2 := Parsiraj( qqRoba2, "IDROBA" )
      aUsl3 := Parsiraj( qqRoba3, "IDROBA" )
      aUsl4 := Parsiraj( qqRoba4, "IDROBA" )
      aUsl5 := Parsiraj( qqRoba5, "IDROBA" )
      aUsl6 := Parsiraj( qqRoba6, "IDROBA" )
      aUsl7 := Parsiraj( qqIDVN, "IDVN" )
      IF aUsl1 <> NIL .AND. aUsl2 <> NIL .AND. aUsl3 <> NIL .AND. aUsl4 <> NIL .AND. ;
            aUsl5 <> NIL .AND. aUsl6 <> NIL .AND. aUsl7 <> NIL
         EXIT
      ENDIF
   ENDDO
   BoxC()


   qqRoba1 := Trim( qqRoba1 ); qqRoba2 := Trim( qqRoba2 ); qqRoba3 := Trim( qqRoba3 )
   qqRoba4 := Trim( qqRoba4 ); qqRoba5 := Trim( qqRoba5 ); qqRoba6 := Trim( qqRoba6 )
   qqIDVN := Trim( qqIDVN )

   WPar( "d1", dDatOd ) ; WPar( "d2", dDatDo )
   WPar( "O1", cRoba1 ) ; WPar( "O2", cRoba2 ) ; WPar( "O3", cRoba3 )
   WPar( "O4", cRoba4 ) ; WPar( "O5", cRoba5 ) ; WPar( "O6", cRoba6 )
   WPar( "F1", qqRoba1 ); WPar( "F2", qqRoba2 ); WPar( "F3", qqRoba3 )
   WPar( "F4", qqRoba4 ); WPar( "F5", qqRoba5 ); WPar( "F6", qqRoba6 )
   WPar( "F7", qqIDVN )

   SELECT params; USE

   SELECT mat_suban

   Box(, 2, 30 )
   nSlog := 0; nUkupno := RECCOUNT2()
   cSort1 := "IDPARTNER"
   cFilt  := "DATDOK>=dDatOd .and. DATDOK<=dDatDo .and. Tacno(aUsl7) .and. U_I=='2'"
   INDEX ON &cSort1 TO "TMPMAT" FOR &cFilt Eval( TekRec() ) EVERY 1
   BoxC()

   GO TOP
   IF Eof(); Msg( "Ne postoje trazeni podaci...", 6 ); closeret; ENDIF

   START PRINT CRET

   PRIVATE cIdPartner := "", cNPartnera := ""
   PRIVATE nRoba1 := 0, nRoba2 := 0, nRoba3 := 0, nRoba4 := 0, nRoba5 := 0, nRoba6 := 0

   aKol := { { "SIFRA", {|| cIdPartner         }, .F., "C", 6, 0, 1, 1 }, ;
      { "PARTNER/MJESTO TROSKA", {|| cNPartnera }, .F., "C", 50, 0, 1, 2 }, ;
      { cRoba1, {|| nRoba1             }, .T., "N", 10, 2, 1, 3 }, ;
      { cRoba2, {|| nRoba2             }, .T., "N", 10, 2, 1, 4 }, ;
      { cRoba3, {|| nRoba3             }, .T., "N", 10, 2, 1, 5 }, ;
      { cRoba4, {|| nRoba4             }, .T., "N", 10, 2, 1, 6 }, ;
      { cRoba5, {|| nRoba5             }, .T., "N", 10, 2, 1, 7 }, ;
      { cRoba6, {|| nRoba6             }, .T., "N", 10, 2, 1, 8 } }

   P_10CPI
   ?? self_organizacija_naziv()
   ?
   ? "DATUM:", SrediDat( Date() )
   ? "USLOV ZA VRSTU NALOGA:" + IF( Empty( qqIDVN ), "SVI NALOZI", Trim( qqIDVN ) )

   print_lista_2( aKol, {|| FSvaki1() },, gTabela,, ;
      , "Isporuceni asortiman - pregled po kupcima za period od " + DToC( ddatod ) + " do " + DToC( ddatdo ), ;
      {|| FFor1() }, IF( gOstr == "D",, -1 ),,,,, )

   ENDPRINT

   CLOSERET

STATIC FUNCTION FFor1()

   cIdPartner := idpartner
   nRoba1 := nRoba2 := nRoba3 := nRoba4 := nRoba5 := nRoba6 := 0
   cNPartnera := ocitaj_izbaci( F_PARTN, idpartner, "TRIM(naz)+' '+TRIM(naz2)" )
   DO WHILE !Eof() .AND. idpartner == cIdPartner
      IF Tacno( aUsl1 ); nRoba1 += kolicina; ENDIF
      IF Tacno( aUsl2 ); nRoba2 += kolicina; ENDIF
      IF Tacno( aUsl3 ); nRoba3 += kolicina; ENDIF
      IF Tacno( aUsl4 ); nRoba4 += kolicina; ENDIF
      IF Tacno( aUsl5 ); nRoba5 += kolicina; ENDIF
      IF Tacno( aUsl6 ); nRoba6 += kolicina; ENDIF
      SKIP 1
   ENDDO
   SKIP -1

   RETURN .T.


STATIC FUNCTION FSvaki1()
   RETURN


STATIC FUNCTION TekRec()

   nSlog++
   @ box_x_koord() + 1, box_y_koord() + 2 SAY PadC( AllTrim( Str( nSlog ) ) + "/" + AllTrim( Str( nUkupno ) ), 20 )
   @ box_x_koord() + 2, box_y_koord() + 2 SAY "Obuhvaceno: " + Str( 0 )

   RETURN ( NIL )


// OPCINA - pregled cijene artikla po dobavljacima
FUNCTION CArDob()

  // o_roba()
  // o_sifk()
   //o_sifv()
  // o_partner()
   O_MAT_SUBAN

   qqIDVN := Space( 30 )
   qqRoba := ""
   dDatOd := CToD( "" ); dDatDo := Date(); gOstr := "D"; gTabela := 1

   o_params()
   PRIVATE cSection := "6", cHistory := " "; aHistory := {}
   Params1()
   RPar( "d1", @dDatOd ); RPar( "d2", @dDatDo )
   RPar( "F7", @qqIDVN )
   RPar( "c5", @qqRoba )

   qqIDVN := PadR( qqIDVN, 30 )

   Box(, 7, 70 )
   DO WHILE .T.
      qqRoba := PadR( qqRoba, 10 )
      @ box_x_koord() + 1, box_y_koord() + 2   SAY "Sifra artikla  " GET qqRoba    PICT "@!" VALID P_Roba( @qqRoba )
      @ box_x_koord() + 3, box_y_koord() + 2 SAY "Za period od" GET dDatOD
      @ box_x_koord() + 3, Col() + 2 SAY "do" GET dDatDo
      @ box_x_koord() + 5, box_y_koord() + 2 SAY "Uslov za vrstu naloga" GET qqIDVN PICT "@!"
      @ box_x_koord() + 7, box_y_koord() + 2 SAY "Ukljuceno ostranicavanje ? (D/N)" GET gOstr VALID gOstr $ "DN" PICT "@!"
      @ box_x_koord() + 7, box_y_koord() + 38 SAY "Tip tabele (0/1/2)" GET gTabela VALID gTabela < 3 .AND. gTabela >= 0 PICT "9"
      read; ESC_BCR
      aUsl7 := Parsiraj( qqIDVN, "IDVN" )
      IF aUsl7 <> NIL
         EXIT
      ENDIF
   ENDDO
   BoxC()


   qqIDVN := Trim( qqIDVN )

   WPar( "d1", dDatOd ) ; WPar( "d2", dDatDo )
   WPar( "F7", qqIDVN )
   WPar( "c5", qqRoba )

   SELECT params
   USE

   SELECT mat_suban
   SET ORDER TO TAG "9"


   // Box(,2,30)
   // nSlog:=0
   // nUkupno:=RECCOUNT2()
   // cSort1 := "DESCEND(DTOS(DATDOK))+IDPARTNER"

   cFilt  := "DATDOK>=dDatOd .and. DATDOK<=dDatDo .and. Tacno(aUsl7) .and. IDROBA==qqRoba .and. U_I=='1'"

   // INDEX ON &cSort1 TO "TMPMAT" FOR &cFilt EVAL(TekRec()) EVERY 1
   // BoxC()

   SET FILTER to &cFilt
   GO TOP

   IF Eof()
      Msg( "Ne postoje trazeni podaci...", 6 )
      my_close_all_dbf()
      RETURN
   ENDIF

   START PRINT CRET

   PRIVATE cIdPartner := "", cNPartnera := "", aDobav := {}

   aKol := { { "SIFRA", {|| cIdPartner         }, .F., "C", 6, 0, 1, 1 }, ;
      { "DOBAVLJAC", {|| cNPartnera         }, .F., "C", 50, 0, 1, 2 }, ;
      { "DATUM", {|| DATDOK             }, .F., "D", 8, 0, 1, 3 }, ;
      { "CIJENA", {|| IF( kolicina == 0, IZNOS, IZNOS / KOLICINA )     }, .F., "N", 12, 2, 1, 4 } }

   P_10CPI
   ?? self_organizacija_naziv()
   ?
   ? "DATUM:", SrediDat( Date() )
   ? "USLOV ZA VRSTU NALOGA:" + IF( Empty( qqIDVN ), "SVI NALOZI", Trim( qqIDVN ) )

   print_lista_2( aKol, {|| FSvaki1() },, gTabela,, ;
      , "Pregled cijena za " + qqRoba + "-" + Trim( ROBA->naz ) + " za period od " + DToC( ddatod ) + " do " + DToC( ddatdo ), ;
      {|| FFor2() }, IF( gOstr == "D",, -1 ),,,,,, .F. )

   ENDPRINT

   my_close_all_dbf()

   RETURN


STATIC FUNCTION FFor2()

   LOCAL lVrati := .F.

   cIdPartner := idpartner
   IF AScan( aDobav, cIdpartner ) == 0
      lVrati := .T.
      AAdd( aDobav, cIdPartner )
      cNPartnera := ocitaj_izbaci( F_PARTN, idpartner, "TRIM(naz)+' '+TRIM(naz2)" )
   ENDIF

   RETURN lVrati
