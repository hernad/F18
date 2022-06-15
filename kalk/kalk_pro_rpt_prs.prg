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

/*

// -----------------------------------------------------
// report: specifikacija po sastavnicama
// -----------------------------------------------------
FUNCTION rpt_prspec()

   LOCAL cBrFakt
   LOCAL cValuta
   LOCAL dDatOd
   LOCAL dDatDo
   LOCAL cRekap
   LOCAL cExpDbf

   IF _get_vars( @cBrFakt, @cValuta, ;
         @dDatOd, @dDatDo, @cRekap, @cExpDbf ) == 0
      RETURN
   ENDIF

   IF cRekap == "N" .OR. Pitanje(, "Generisati stavke izvjestaja (D/N", "D" ) == "D"
      _gen_rpt( cBrFakt, cValuta, dDatOd, dDatDo, cRekap )
   ENDIF


   IF cExpDbf == "D"

      IF cRekap == "D"
         MsgBeep( "Moguce exportovati samo specifikacija !" )
         RETURN
      ENDIF

      open_r_export_table()

      RETURN

   ENDIF

   IF cRekap == "D"
      _show_rekap( cValuta, cBrFakt )
      RETURN
   ENDIF
   _show_rpt( cValuta )

   RETURN




// -----------------------------------------------
// forma sa uslovima izvjestaja
// -----------------------------------------------
STATIC FUNCTION _get_vars( cBrFakt, cValuta, dDOd, dDdo, cRekap, cExpDbf )

   LOCAL GetList := {}

   cBrFakt := Space( 10 )
   cValuta := "KM "
   dDOd := Date()
   dDDo := Date()
   cRekap := "N"
   cExpDbf := "N"

   Box(, 8, 60 )

   @ box_x_koord() + 1, box_y_koord() + 2 SAY "Broj fakture dokumenta 'PR':" GET cBrFakt VALID !Empty( cBrFakt )

   @ box_x_koord() + 2, box_y_koord() + 2 SAY "Izvjestaj pravi u valuti (KM/EUR):" GET cValuta VALID !Empty( cValuta )

   @ box_x_koord() + 3, box_y_koord() + 2 SAY "Datum od:" GET dDOd

   @ box_x_koord() + 4, box_y_koord() + 2 SAY "Datum do:" GET dDDo

   @ box_x_koord() + 6, box_y_koord() + 2 SAY "Napravi samo rekapitulaciju po tarifama:" GET cRekap VALID cRekap $ "DN" PICT "@!"

   @ box_x_koord() + 8, box_y_koord() + 2 SAY "Exportovati tabelu u dbf ?" GET cExpDbf VALID cExpDbf $ "DN" PICT "@!"

   READ
   BoxC()

   IF LastKey() == K_ESC
      RETURN 0
   ENDIF

   RETURN 1



// ---------------------------------------------
// generisi report u pomocnu tabelu
// ---------------------------------------------
STATIC FUNCTION _gen_rpt( cBrFakt, cValuta, dDatOd, dDatDo, cRekap )

   LOCAL aFields
   LOCAL nKolPrim
   LOCAL nKolSec
   LOCAL cJmjPrim
   LOCAL cJmjSec
   LOCAL cSastId
   LOCAL cRobaId
   LOCAL _idx

   aFields := _g_fields()
   create_dbf_r_export( aFields )

   _idx := my_home() + "brfakt_pr.idx"

   o_r_export()
   o_kalk()
//   o_roba()
  -- o_sifk()
   o_sifv()

   SELECT kalk

   GO TOP

   // kreiraj index
   INDEX ON ( "brfakt" ) TO ( _idx ) FOR ( idfirma == self_organizacija_id() .AND. Idv == "PR" )
   dbSetIndex( _idx )

   GO TOP
   DO WHILE !Eof() .AND. field->brfaktp == cBrFakt

      // redni broj > 900 su sastavnice
      // a sve do toga je proizvod

      IF Val( field->rbr ) >= 900

         // ovo je sastavnica, uzmi ID
         cSastId := field->idroba

         SELECT roba
         SET ORDER TO TAG "ID"
         SEEK cSastId

         // naziv sastavnice
         cSastNaz := field->naz
         // jedinica mjere - primarna (KOM, MET)
         cJmjPrim := field->jmj


         SELECT kalk
      ELSE

         // ovo je proizvod, uzmi samo id
         cRobaId := field->idroba

         SKIP
         LOOP

      ENDIF

      SELECT r_export
      APPEND BLANK

      // id proizvoda
      REPLACE field->idroba WITH cRobaId

      // id sastavnice
      REPLACE field->idsast WITH cSastId

      // naziv sastavnice
      REPLACE field->sastnaz WITH cSastNaz

      // carinski tarifni broj
      // uzmi iz sifk ("ROBA", "TARB")
      REPLACE field->ctarbr WITH get_roba_sifk_sifv( "TARB", cSastId, .F. )

      // primarna jedinica mjere sastavnice
      REPLACE field->jmjprim WITH cJmjPrim

      // kolicina iz kalk-a, u primarnoj jedinici mjere
      nKolPrim := kalk->kolicina
      REPLACE field->kolprim WITH nKolPrim

      // sekundarna jedinica mjere
      // sracunaj odmah sve za upis u tabelu
      cJmjSec := ""
      nKolSec := svedi_na_jedinicu_mjere( 1, cSastId, @cJmjSec )
      REPLACE field->jmjsec WITH cJmjSec

      // kolicina u sekundarnoj jmj po 1 komadu
      REPLACE field->kolseck WITH nKolSec

      // kolicina u drugoj jedinici mjere
      REPLACE field->kolsec WITH Round( nKolPrim * nKolSec, 4 )

      // cijena sastavnice
      REPLACE field->cijena WITH kalk->nc


      // cijena po komadu kg
      REPLACE field->izn1 WITH Round( field->cijena / nKolSec, 4 )

      // ukupno u kg
      REPLACE field->izn2 WITH Round( field->kolprim * field->cijena, 4 )

      SELECT kalk
      SKIP

   ENDDO

   FErase( _idx )

   my_close_all_dbf()

   RETURN



// -------------------------------------
// vraca polja pomocne tabele
// -------------------------------------
STATIC FUNCTION _g_fields()

   LOCAL aFld := {}

   AAdd( aFld, { "idroba", "C", 10, 0 } )
   AAdd( aFld, { "idsast", "C", 10, 0 } )
   AAdd( aFld, { "sastnaz", "C", 40, 0 } )
   AAdd( aFld, { "ctarbr", "C", 20, 0 } )

   AAdd( aFld, { "jmjprim", "C", 3, 0 } )
   AAdd( aFld, { "jmjsec", "C", 3, 0 } )

   AAdd( aFld, { "kolprim",   "N", 15, 5 } )
   AAdd( aFld, { "kolsec",   "N", 15, 5 } )
   AAdd( aFld, { "kolseck", "N", 15, 5 } )
   AAdd( aFld, { "cijena",  "N", 15, 5 } )
   AAdd( aFld, { "izn1",   "N", 15, 5 } )
   AAdd( aFld, { "izn2",   "N", 15, 5 } )

   RETURN aFld



// ---------------------------------------------
// prikazi report iz tabele
// ---------------------------------------------
STATIC FUNCTION _show_rpt( cValuta )

   LOCAL cLine

   // kreiraj indexe
   o_r_export()
   INDEX ON r_export->idroba + r_export->idsast TAG "1"

   SELECT r_export

   SET ORDER TO TAG "1"

   GO TOP


   START PRINT CRET

   // zaglavlje specifikacije
   _z_spec( @cLine, cValuta )

   cXRoba := "XX"

   nCnt := 0

   nTKPrim := 0
   nTKSec := 0
   nTIznU := 0

   DO WHILE !Eof()

      cRobaId := field->idroba

      // RBR + ROBA
      IF cRobaId <> cXRoba
         ? Str( ++nCnt, 3 ) + "."
         @ PRow(), PCol() + 1 SAY cRobaId
      ELSE
         // ako je ista roba - ne prikazuj je...
         ? Space( 4 )
         @ PRow(), PCol() + 1 SAY Space( 10 )
      ENDIF

      // ID sastavnica
      @ PRow(), PCol() + 1 SAY field->idsast

      // naziv sastavnice
      @ PRow(), PCol() + 1 SAY field->sastnaz

      // carinski tarifni broj
      @ PRow(), PCol() + 1 SAY field->ctarbr

      // kolicina primarna  (komadi ili metri)
      @ PRow(), PCol() + 1 SAY Str( field->kolprim, 12, 2 )

      nTKPrim += field->kolprim

      // kolicina sekundarna SIFK (kg po komadu)
      @ PRow(), PCol() + 1 SAY Str( field->kolseck, 12, 2 )

      // kolicina sekundarna SIFK (ukupno)
      @ PRow(), PCol() + 1 SAY Str( field->kolsec, 12, 2 )

      nTKSec += field->kolsec

      // cijena po jmj
      @ PRow(), PCol() + 1 SAY Str( field->izn1, 12, 2 )

      // ukupna vrijednost
      @ PRow(), PCol() + 1 SAY Str( field->izn2, 12, 2 )

      nTIznU += field->izn2

      IF _nstr()
         FF
      ENDIF

      // setuj pom.varijablu za robu
      cXRoba := cRobaId

      SKIP
   ENDDO

   IF _nstr()
      FF
   ENDIF

   ? cLine

   ? PadR( "UKUPNO:", 88 )

   @ PRow(), PCol() + 1 SAY Str( nTKPrim, 12, 2 )
   @ PRow(), PCol() + 1 SAY PadR( "", 12 )
   @ PRow(), PCol() + 1 SAY Str( nTKSec, 12, 2 )
   @ PRow(), PCol() + 1 SAY PadR( "", 12 )
   @ PRow(), PCol() + 1 SAY Str( nTIznU, 12, 2 )

   ? cLine

   FF
   ENDPRINT

   RETURN


// ---------------------------------------------
// provjeri za novu stranicu...
// ---------------------------------------------
STATIC FUNCTION _nstr()

   IF PRow() > 65
      RETURN .T.
   ENDIF

   RETURN .F.




// ---------------------------------------------
// zaglavlje specifikacije
// ---------------------------------------------
STATIC FUNCTION _z_spec( cLine, cValuta )

   LOCAL cTxt1 := ""
   LOCAL cTxt2 := ""
   LOCAL cRazmak := Space( 1 )

   cLine := ""

   // linija zaglavlja
   cLine += Replicate( "-", 4 )
   cLine += cRazmak
   cLine += Replicate( "-", 10 )
   cLine += cRazmak
   cLine += Replicate( "-", 10 )
   cLine += cRazmak
   cLine += Replicate( "-", 40 )
   cLine += cRazmak
   cLine += Replicate( "-", 20 )
   cLine += cRazmak
   cLine += Replicate( "-", 12 )
   cLine += cRazmak
   cLine += Replicate( "-", 12 )
   cLine += cRazmak
   cLine += Replicate( "-", 12 )
   cLine += cRazmak
   cLine += Replicate( "-", 12 )
   cLine += cRazmak
   cLine += Replicate( "-", 12 )

   // tekstualni dio zaglavlja - 1 red
   cTxt1 += PadR( "R.br", 4 )
   cTxt1 += cRazmak
   cTxt1 += PadR( "Proizvod", 10 )
   cTxt1 += cRazmak
   cTxt1 += PadR( "Sifra i naziv sastavnice", 51 )
   cTxt1 += cRazmak
   cTxt1 += PadC( "Carinski", 20 )
   cTxt1 += cRazmak
   cTxt1 += PadC( "Normativ", 12 )
   cTxt1 += cRazmak
   cTxt1 += PadC( "Masa (kg/kom", 12 )
   cTxt1 += cRazmak
   cTxt1 += PadC( "Ukupna masa", 12 )
   cTxt1 += cRazmak
   cTxt1 += PadC( "Cijena", 12 )
   cTxt1 += cRazmak
   cTxt1 += PadC( "Ukupna", 12 )

   // tekstualni dio zaglavlja - 2 red
   cTxt2 += PadR( "", 4 )
   cTxt2 += cRazmak
   cTxt2 += PadR( "", 10 )
   cTxt2 += cRazmak
   cTxt2 += PadR( "", 51 )
   cTxt2 += cRazmak
   cTxt2 += PadC( "tarifni br.", 20 )
   cTxt2 += cRazmak
   cTxt2 += PadC( "(m, kom)", 12 )
   cTxt2 += cRazmak
   cTxt2 += PadC( "kg/met)", 12 )
   cTxt2 += cRazmak
   cTxt2 += PadC( "(kg)", 12 )
   cTxt2 += cRazmak
   cTxt2 += PadC( "(kg)", 12 )
   cTxt2 += cRazmak
   cTxt2 += PadC( "vr. (" + AllTrim( cValuta ) + ")", 12 )


   ?

   P_COND2

   B_ON

   ? "Specifikacija sastavnica i normativima za proizvode po fakturi"

   B_OFF

   ? "na dan:", DToC( Date() )
   ?

   ? cLine
   ? cTxt1
   ? cTxt2
   ? cLine

   RETURN



// ---------------------------------------------
// zaglavlje rekapitulacije
// ---------------------------------------------
STATIC FUNCTION _z_rekap( cLine, cValuta, cFaktBr )

   LOCAL cTxt1 := ""
   LOCAL cTxt2 := ""
   LOCAL cRazmak := Space( 1 )

   cLine := ""

   // linija zaglavlja
   cLine += Replicate( "-", 4 )
   cLine += cRazmak
   cLine += Replicate( "-", 20 )
   cLine += cRazmak
   cLine += Replicate( "-", 40 )
   cLine += cRazmak
   cLine += Replicate( "-", 16 )
   cLine += cRazmak
   cLine += Replicate( "-", 12 )
   cLine += cRazmak
   cLine += Replicate( "-", 12 )

   // tekstualni dio zaglavlja - 1 red
   cTxt1 += PadR( "R.br", 4 )
   cTxt1 += cRazmak
   cTxt1 += PadC( "Carinska", 20 )
   cTxt1 += cRazmak
   cTxt1 += PadC( "Opis", 40 )
   cTxt1 += cRazmak
   cTxt1 += PadC( "Utroseno", 16 )
   cTxt1 += cRazmak
   cTxt1 += PadC( "Tezina", 12 )
   cTxt1 += cRazmak
   cTxt1 += PadC( "Ukupna", 12 )

   // tekstualni dio zaglavlja - 2 red
   cTxt2 += PadR( "", 4 )
   cTxt2 += cRazmak
   cTxt2 += PadC( "tarifni br.", 20 )
   cTxt2 += cRazmak
   cTxt2 += PadC( "", 40 )
   cTxt2 += cRazmak
   cTxt2 += PadC( "isporuka", 16 )
   cTxt2 += cRazmak
   cTxt2 += PadC( "(kg)", 12 )
   cTxt2 += cRazmak
   cTxt2 += PadC( "vr. (" + AllTrim( cValuta ) + ")", 12 )

   ?

   P_COND

   B_ON

   ? PadC( "REKAPITULACIJA PO TARIFNIM OZNAKAMA", 60 )

   B_OFF

   ?
   ? PadC( "prilog fakturi: " + cFaktBr, 60 )
   ?
   ?

   ? cLine
   ? cTxt1
   ? cTxt2
   ? cLine

   RETURN


// ---------------------------------------------------
// prikazi rekapitulaciju
// ---------------------------------------------------
STATIC FUNCTION _show_rekap( cValuta, cFaktBr )

   LOCAL cLine
   LOCAL aTmp
   LOCAL i

   o_r_export()

   INDEX ON r_export->ctarbr TAG "2"

   SELECT r_export
   SET ORDER TO TAG "2"

   GO TOP

   START PRINT CRET

   // daj zaglavlje rekapitulacije
   _z_rekap( @cLine, cValuta, cFaktBr )

   nCnt := 0

   nUTKPrim := 0
   nUTKSek := 0
   nUTIznU := 0

   DO WHILE !Eof()

      cCTarBr := field->ctarbr

      nTKPrim := 0
      nTKSek := 0
      nTIznU := 0

      DO WHILE !Eof() .AND. field->ctarbr == cCTarBr

         // ukupno primarna jmj (kom, met)
         nTKPrim += field->kolprim
         // oznaka primarne jedinice
         cJmjPrim := field->jmjprim
         // ukupno u sekundarnoj jmj (kg)
         nTKSek += field->kolsec
         // ukupna vrijednost
         nTIznU += field->kolprim * field->cijena

         SKIP
      ENDDO

      nUTKPrim += nTKPrim
      nUTKSek += nTKSek
      nUTIznU += nTIznU

      ++ nCnt

      // ispisi ove sume...

      ? Str( nCnt, 3 ) + "."

      @ PRow(), PCol() + 1 SAY cCTarBr

      cCTarOpis := my_get_from_ini( "CarTarife", AllTrim( cCTarBr ), ;
         "????", KUMPATH )

      aTmp := SjeciStr( cCTarOpis, 40 )

      @ PRow(), PCol() + 1 SAY PadR( aTmp[ 1 ], 40 )

      @ PRow(), PCol() + 1 SAY Str( nTKPrim, 12, 2 )

      @ PRow(), PCol() + 1 SAY cJmjPrim

      @ PRow(), PCol() + 1 SAY Str( nTKSek, 12, 2 )

      @ PRow(), PCol() + 1 SAY Str( nTIznU, 12, 2 )

      // ostatak opisa tarife stavi u druge redove
      IF Len( aTmp ) > 1

         FOR i := 2 TO Len( aTmp )

            ? Space( 25 )

            @ PRow(), PCol() + 1 SAY PadR( aTmp[ i ], 40 )

         NEXT

      ENDIF

   ENDDO

   ? cLine
   ? PadR( "UKUPNO:", 83 )
   @ PRow(), PCol() + 1 SAY Str( nUTKSek, 12, 2 )
   @ PRow(), PCol() + 1 SAY Str( nUTIznU, 12, 2 )
   ? cLine


   FF
   ENDPRINT

   RETURN


*/
