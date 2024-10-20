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


STATIC PicDEM := "9999999999.99"
STATIC PicBHD := "9999999999.99"
STATIC PicKol := "9999999999.999"


// --------------------------------------
// kartice, glavni menij
// --------------------------------------
FUNCTION mat_kartica()

   LOCAL _opc := {}
   LOCAL _opcexe := {}
   LOCAL _izbor := 1

   AAdd( _opc, "1. sintetika      " )
   AAdd( _opcexe, {|| KSintKont() } )
   AAdd( _opc, "2. analitika" )
   AAdd( _opcexe, {|| KAnalK() } )
   AAdd( _opc, "3. subanalitika " )
   AAdd( _opcexe, {|| KSuban() } )


   f18_menu( "kca", .F., _izbor, _opc, _opcexe )

   my_close_all_dbf()

   RETURN


// --------------------------------------
// sinteticka kartica
// --------------------------------------
FUNCTION KSintKont()

   LOCAL nC1 := 30

   o_partner()

   cIdFirma := self_organizacija_id()
   qqKonto := Space( 100 )
   Box( "KSK", 4, 60, .F. )
   DO WHILE .T.
      @ box_x_koord() + 1, box_y_koord() + 2 SAY "SINTETICKA KARTICA"

      @ box_x_koord() + 3, box_y_koord() + 2 SAY "Firma "; ?? self_organizacija_id(), "-", self_organizacija_naziv()

      @ box_x_koord() + 4, box_y_koord() + 2 SAY KonSeks( "KONTO" ) + ":  " GET qqKonto PICTURE "@S50"
      READ;  ESC_BCR
      aUsl1 := Parsiraj( qqKonto, "IdKonto", "C" )
      IF aUsl1 <> NIL
         EXIT
      ENDIF
   ENDDO

   BoxC()

   cIdFirma := Left( cIdFirma, 2 )

   O_MAT_SINT
   o_konto()

   SELECT mat_sint
   SET FILTER TO Tacno( aUsl1 ) .AND. IdFirma == cIdFirma
   GO TOP

   EOF CRET

   START PRINT CRET

   m := "------- ---- -----------"
   FOR nI := 1 TO 4
      m += " " + Replicate( "-", Len( PicDEM ) )
   NEXT

   DO WHILE !Eof()
      // firma

      nUkDug := 0
      nUkPot := 0
      nUkDug2 := 0
      nUkPot2 := 0
      cIdKonto := IdKonto

      IF PRow() <> 0
         FF
         ZaglKSintK()
      ENDIF

      DO WHILE !Eof() .AND. cIdFirma = IdFirma .AND. cIdKonto = IdKonto
         IF PRow() == 0; ZaglKSintK(); ENDIF
         IF PRow() > 65; FF; ZaglKSintK(); ENDIF
         ? IdVN, brnal, rbr, "  ", datnal
         nC1 := PCol() + 3
         @ PRow(), PCol() + 3 SAY Dug PICTURE picDEM
         nUkDug += Dug
         @ PRow(), PCol() + 1 SAY Pot PICTURE picDEM
         nUkPot += Pot
         @ PRow(), PCol() + 1 SAY Dug2 PICTURE picBHD
         nUkDug2 += Dug2
         @ PRow(), PCol() + 1 SAY Pot2 PICTURE picBHD
         nUkPot2 += Pot2
         SKIP
      ENDDO

      IF PRow() > 61; FF; ZaglKSintK(); ENDIF
      ? m
      ? "UKUPNO:"
      @ PRow(), nC1 SAY nUkDug        PICTURE picDEM
      @ PRow(), PCol() + 1 SAY nUkPot  PICTURE picDEM
      @ PRow(), PCol() + 1 SAY nUkDug2 PICTURE picBHD
      @ PRow(), PCol() + 1 SAY nUkPot2 PICTURE picBHD
      ?  m
      ? "SALDO:"
      nSaldo := nUkDug - nUkPot
      nSaldo2 := nUkDug2 - nUkPot2
      IF nSaldo > 0
         @ PRow(), nC1 SAY nSaldo        PICTURE picDEM
         @ PRow(), PCol() + 1 SAY 0       PICTURE picDEM
         @ PRow(), PCol() + 1 SAY nSaldo2 PICTURE picBHD
      ELSE
         nSaldo := -nSaldo
         @ PRow(), PCol() + 1 SAY 0       PICTURE picDEM
         @ PRow(), PCol() + 1 SAY nSaldo  PICTURE picDEM
         @ PRow(), PCol() + 1 SAY 0       PICTURE picBHD
         @ PRow(), PCol() + 1 SAY nSaldo2 PICTURE picBHD
      ENDIF
      ? m
      nUkDug := nUkPot := nUkDug2 := nUkPot2 := 0

   ENDDO

   FF
   ENDPRINT

   my_close_all_dbf()

   RETURN


// ----------------------------------------------
// zaglavlje sinteticke kartice
// ----------------------------------------------
STATIC FUNCTION ZaglKSintK()

   LOCAL _line1, _line2, _line3

   _line1 := "*NALOG * R. *  DATUM    *"
   _line2 := "*      * Br *            "
   _line3 := "*      *    *  NALOGA   *"

   _line1 += PadC( "I Z N O S  U  " + valuta_domaca_skraceni_naziv(), ( Len( PicDEM ) * 2 ) + 1 )
   _line1 += "*"
   _line1 += PadC( "I Z N O S  U  " + ValPomocna(), ( Len( PicDEM ) * 2 ) + 1 )
   _line1 += "*"

   _line2 += Replicate( "-", ( Len( PICDEM ) * 2 ) + 1 )
   _line2 += " "
   _line2 += Replicate( "-", ( Len( PICDEM ) * 2 ) + 1 )

   _line3 += PadC( "DUGUJE", Len( PICDEM ) ) + "*"
   _line3 += PadC( "POTRAZUJE", Len( PICDEM ) ) + "*"
   _line3 += PadC( "DUGUJE", Len( PICDEM ) ) + "*"
   _line3 += PadC( "POTRAZUJE", Len( PICDEM ) ) + "*"

   ?? "MAT.P: SINTETICKA KARTICA   NA DAN "
   @ PRow(), PCol() + 1 SAY Date()

   select_o_partner( cIdFirma )

   ? "FIRMA:", cIdFirma, PadR( partn->naz, 25 ), PadR( partn->naz2, 25 )

   select_o_konto( cIdKonto )

   ? KonSeks( "KONTO" ) + ":", cIdkonto, AllTrim( konto->naz )

   ? m
   ? _line1
   ? _line2
   ? _line3
   ? m

   SELECT mat_sint

   RETURN


// -----------------------------------------
// analiticka kartica
// -----------------------------------------
FUNCTION KAnalK()

   LOCAL _izbor := 1
   LOCAL _opc := {}
   LOCAL _opcexe := {}

   AAdd( _opc, "1. kartica za pojedinacni konto         " )
   AAdd( _opcexe, {|| KAnKPoj() } )
   AAdd( _opc, "2. kartica po svim kontima" )
   AAdd( _opcexe, {|| KAnKKonto() } )

   f18_menu( "ksix", .F., _izbor, _opc, _opcexe )

   RETURN




FUNCTION KAnKPoj()

   cIdFirma := "  "
   qqKonto := Space( 100 )

   o_partner()

   Box( "KANP", 3, 70, .F. )

   DO WHILE .T.
      @ box_x_koord() + 1, box_y_koord() + 6 SAY "ANALITICKA KARTICA"

         @ box_x_koord() + 2, box_y_koord() + 2 SAY "Firma "; ?? self_organizacija_id(), "-", self_organizacija_naziv()
         cIdFirma := self_organizacija_id()

      @ box_x_koord() + 3, box_y_koord() + 2 SAY KonSeks( "KONTO  " ) + "  : " GET qqKonto  PICTURE "@S50"
      READ;  ESC_BCR

      aUsl1 := Parsiraj( qqKonto, "IdKonto", "C" )
      IF aUsl1 <> NIL; exit; ENDIF
   ENDDO

   BoxC()

   O_MAT_ANAL
   o_konto()

   SELECT mat_anal
   SET FILTER TO Tacno( aUsl1 ) .AND. IdFirma == cIdFirma
   GO TOP
   EOF CRET

   START PRINT CRET

   m := "-- ---- --- -------- "
   FOR nI := 1 TO 4
      m += " " + Replicate( "-", Len( PICDEM ) )
   NEXT

   a := 0
   DO WHILE !Eof()

      cIdKonto := IdKonto
      IF a <> 0; EJECTA0; ZaglKAnalK(); ENDIF
      nUkDug := nUkPot := nUkDug2 := nUkPot2 := 0
      DO WHILE !Eof() .AND. cIdKonto == IdKonto // konto
         IF A == 0; ZaglKAnalK(); ENDIF
         IF A > 64; EJECTA0; ZaglKAnalK(); ENDIF
         @++A, 0      SAY IdVN
         @ A, PCol() + 1 SAY BrNal
         @ A, PCol() + 1 SAY RBr
         @ A, PCol() + 1 SAY DatNal
         @ A, PCol() + 1 SAY Dug PICTURE picDEM
         @ A, PCol() + 1 SAY Pot PICTURE picDEM
         @ A, PCol() + 1 SAY Dug2 PICTURE picBHD
         @ A, PCol() + 1 SAY Pot2 PICTURE picBHD
         nUkDug += Dug; nUkPot += Pot; nUkDug2 += Dug2; nUkPot2 += Pot2
         SKIP
      ENDDO

      @++A, 0 SAY m
      @++A, 0 SAY "UKUPNO:"
      @ A, 21       SAY nUkDug  PICTURE picDEM
      @ A, PCol() + 1 SAY nUkPot  PICTURE picDEM
      @ A, PCol() + 1 SAY nUkDug2 PICTURE picBHD
      @ A, PCol() + 1 SAY nUkPot2  PICTURE picBHD
      @++A, 0 SAY m
      @++A, 0 SAY "SALDO:"
      nSaldo := nUkDug - nUkPot
      nSaldo2 := nUkDug2 - nUkPot2
      IF nSaldo >= 0
         @ A, 21 SAY nSaldo PICTURE picDEM
         @ A, PCol() + 1 SAY 0 PICTURE picDEM
         @ A, PCol() + 1 SAY nSaldo2 PICTURE picBHD
      ELSE
         nSaldo := -nSaldo
         @ A, 21 SAY 0 PICTURE picDEM
         @ A, PCol() + 1 SAY nSaldo PICTURE picDEM
         @ A, PCol() + 1 SAY 0 PICTURE picBHD
         @ A, PCol() + 1 SAY nSaldo2 PICTURE picBHD
      ENDIF
      @++A, 0 SAY m
      nUkDug := nUkPot := nUkDug2 := nUkPot2 := 0

   ENDDO // eof

   EJECTNA0

   ENDPRINT

   SET FILTER TO
   my_close_all_dbf()

   RETURN


STATIC FUNCTION ZaglKAnalK()

   LOCAL _line1, _line2, _line3

   _line1 := "*V* BR *  DATUM   *"
   _line2 := "* *NAL *           "
   _line3 := "*N*    *  NALOGA  *"

   _line1 += PadC( "I Z N O S  U  " + valuta_domaca_skraceni_naziv(), ( Len( PicDEM ) * 2 ) + 2 ) + "*"
   _line1 += PadC( "I Z N O S  U  " + ValPomocna(), ( Len( PicDEM ) * 2 ) + 2 )

   _line2 += Replicate( "-", ( Len( PICDEM ) * 2 ) + 1 )
   _line2 += " " + Replicate( "-", ( Len( PICDEM ) * 2 ) + 1 )

   _line3 += PadC( "DUGUJE", Len( PICDEM ) ) + "*"
   _line3 += PadC( "POTRAZUJE", Len( PICDEM ) ) + "*"
   _line3 += PadC( "DUGUJE", Len( PICDEM ) ) + "*"
   _line3 += PadC( "POTRAZUJE", Len( PICDEM ) ) + "*"

   P_COND
   @ a, 0  SAY "MAT.P: KARTICA - ANALITICKI " + KonSeks( "KONTO" ) + " - ZA POJEDINACNI " + KonSeks( "KONTO" )
   @++A, 0 SAY "FIRMA:"; @ A, PCol() + 1 SAY cIdFirma
   select_o_partner( cIdFirma )
   @ A, PCol() + 1 SAY naz; @ A, PCol() + 1 SAY naz2

   @++A, 0 SAY KonSeks( "KONTO" ) + ":"; @ A, PCol() + 1 SAY cIdKonto
   select_o_konto( cIdKonto )
   @ A, PCol() + 1 SAY naz

   @++A, 0 SAY m
   @++A, 0 SAY _line1
   @++A, 0 SAY _line2
   @++A, 0 SAY _line3
   @++A, 0 SAY m

   SELECT mat_anal

   RETURN



FUNCTION KAnKKonto()

   cIdFirma := "  "

   o_partner()
   O_MAT_ANAL

   Box( "kankko", 2, 60, .F. )
   @ box_x_koord() + 1, box_y_koord() + 2 SAY "ANALITICKA KARTICA - PO " + KonSeks( "KONT" ) + "IMA"

      @ box_x_koord() + 2, box_y_koord() + 2 SAY "Firma "; ?? self_organizacija_id(), "-", self_organizacija_naziv()
      cIdFirma := self_organizacija_id()

   READ;  ESC_BCR
   BoxC()

   O_MAT_SUBAN

   SELECT mat_anal
   SET ORDER TO TAG "2"
   SEEK cIdFirma
   NFOUND CRET

   START PRINT CRET
   A := 0

   m := "------- ---------------------------------"
   FOR nI := 1 TO 6
      m += " " + Replicate( "-", Len( PICDEM ) )
   NEXT

   nUkDug := nUkUkDug := nUkPot := nUkUkPot := 0
   nUkDug2 := nUkUk2Dug := nUkPot2 := nUkUk2Pot := 0
   DO WHILE !Eof() .AND. cIdFirma = IdFirma

      cIdKonto := IdKonto

      DO WHILE !Eof() .AND. cIdFirma = IdFirma .AND. cIdKonto = IdKonto
         nUkDug += Dug; nUkPot += Pot
         nUkDug2 += Dug2; nUkPot2 += Pot2
         SKIP
      ENDDO

      IF A == 0; ZagKKAnalK();ENDIF
      IF A > 62; EJECTA0; ZagKKAnalK();ENDIF
      nSaldo := nUkDug - nUkPot
      nSaldo2 := nUkDug2 - nUkPot2

      @++A, 1 SAY cIdKonto
      select_o_konto( cIdKonto )
      @ A, 8 SAY Naz PICTURE Replicate( "X", 32 )

      @ A, 42       SAY nUkDug  PICTURE PicDEM
      @ A, PCol() + 1 SAY nUkPot  PICTURE PicDEM
      @ A, PCol() + 1 SAY nSaldo  PICTURE PicDEM
      @ A, PCol() + 1 SAY nUkDug2 PICTURE PicBHD
      @ A, PCol() + 1 SAY nUkPot2 PICTURE PicBHD
      @ A, PCol() + 1 SAY nSaldo2 PICTURE PicBHD
      nUkUkDug += nUkDug; nUkUkPot += nUkPot
      nUkUk2Dug += nUkDug2; nUkUk2Pot += nUkPot2
      nUkDug := nUkPot := nUkDug2 := nUkPot2 := 0
      SELECT mat_anal
   ENDDO

   IF A > 62; EJECTA0; ZagKKAnalK();ENDIF
   nUkSaldo := nUkUkDug - nUkUkPot
   nUk2Saldo := nUkUk2Dug - nUkUk2Pot
   @++A, 0 SAY M
   @++A, 0 SAY "UKUPNO ZA FIRMU:"
   @ A, 42       SAY nUkUkDug  PICTURE PicDEM
   @ A, PCol() + 1 SAY nUkUkPot  PICTURE PicDEM
   @ A, PCol() + 1 SAY nUkSaldo  PICTURE PicDEM
   @ A, PCol() + 1 SAY nUkUk2Dug PICTURE PicBHD
   @ A, PCol() + 1 SAY nUkUk2Pot PICTURE PicBHD
   @ A, PCol() + 1 SAY nUk2Saldo PICTURE PicBHD
   @++A, 0 SAY M
   nUkUkDug := nUkUkPot := nUkUk2Dug := nUkUk2Pot := 0

   EJECTNA0
   ENDPRINT
   my_close_all_dbf()

   RETURN



FUNCTION ZagKKAnalK()

   LOCAL _line1, _line2, _line3

   _line1 := KonSeks( "*KONTO " ) + "*  NAZIV " + KonSeks( "KONTA " ) + "               *"
   _line2 := "                                          "
   _line3 := "*       *                                 *"

   _line1 += PadC( "I Z N O S  U  " + valuta_domaca_skraceni_naziv(), ( Len( PicDEM ) * 2 ) + 3 ) + "*"
   _line1 += PadC( "I Z N O S  U  " + ValPomocna(), ( Len( PicDEM ) * 2 ) + 3 )

   _line2 += Replicate( "-", ( Len( PICDEM ) * 3 ) + 1 )
   _line2 += " " + Replicate( "-", ( Len( PICDEM ) * 3 ) + 1 )

   _line3 += PadC( "DUGUJE", Len( PICDEM ) ) + "*"
   _line3 += PadC( "POTRAZUJE", Len( PICDEM ) ) + "*"
   _line3 += PadC( "SALDO", Len( PICDEM ) ) + "*"
   _line3 += PadC( "DUGUJE", Len( PICDEM ) ) + "*"
   _line3 += PadC( "POTRAZUJE", Len( PICDEM ) ) + "*"
   _line3 += PadC( "SALDO", Len( PICDEM ) ) + "*"


   P_COND
   @ a, 0  SAY "MAT.P: KARTICA STANJA PO ANALITICKIM " + KonSeks( "KONT" ) + "IMA NA DAN "; @ A, PCol() + 1 SAY Date()
   @ A, 0 SAY "FIRMA:"
   @ A, 10 SAY cIdFirma
   select_o_partner( cIdFirma )
   @ A, PCol() + 2 SAY naz; @ A, PCol() + 1 SAY naz2

   @++A, 0 SAY m
   @++A, 0 SAY _line1
   @++A, 0 SAY _line2
   @++A, 0 SAY _line3
   @++A, 0 SAY m

   SELECT mat_anal

   RETURN



// ---------------------------------------------
// mat_subanaliticka kartica
// ---------------------------------------------
FUNCTION KSuban()

   LOCAL cIdRoba := ""
   LOCAL _partner := ""
   LOCAL _konto := ""
   LOCAL _filter := ".t."
   LOCAL _brza_k := "D"
   LOCAL _preth_p := "1"
   LOCAL _col_1
   LOCAL _col_2
   LOCAL _id_firma := self_organizacija_id()
   LOCAL _dat_od := CToD( "" )
   LOCAL _dat_do := CToD( "" )

   //o_partner()
   //o_konto()
   o_sifk()
   o_sifv()
   //o_roba()

   Box( "", 10, 70, .F. )

   o_params()
   PRIVATE cSection := "4", cHistory := " ", aHistory := {}
   Params1()
   RPar( "c1", @_brza_k )
   RPar( "c2", @_id_firma )
   RPar( "c3", @_konto )
   RPar( "c4", @_partner )
   RPar( "c5", @cIdRoba )
   RPar( "c6", @_preth_p )
   RPar( "d1", @_dat_od )
   RPar( "d2", @_dat_do )


    _id_firma := self_organizacija_id()

   @ box_x_koord() + 1, box_y_koord() + 2 SAY "SUBANALITICKA KARTICA"

   @ box_x_koord() + 2, box_y_koord() + 2 SAY "Brza kartica (D/N)" GET _brza_k PICT "@!" VALID _brza_k $ "DN"

   READ

   DO WHILE .T.


         @ box_x_koord() + 3, box_y_koord() + 2 SAY "Firma "
         ?? self_organizacija_id(), "-", self_organizacija_naziv()


      IF _brza_k == "D"
         _konto := PadR( _konto, 7 )
         cIdRoba := PadR( cIdRoba, 10 )
         @ box_x_koord() + 4, box_y_koord() + 2 SAY KonSeks( "Konto  " ) + "        " GET _konto ;
            PICT "@!" VALID P_Konto( @_konto )
         @ box_x_koord() + 5, box_y_koord() + 2 SAY "Sifra artikla  " GET cIdRoba ;
            PICT "@!" VALID P_Roba( @cIdRoba )
      ELSE
         _konto := PadR( _konto, 60 )
         _partner := PadR( _partner, 60 )
         cIdRoba := PadR( cIdRoba, 80 )
         @ box_x_koord() + 4, box_y_koord() + 2 SAY KonSeks( "Konto  " ) + "        " GET _konto ;
            PICT "@S50"
         @ box_x_koord() + 5, box_y_koord() + 2 SAY "Partner        " GET _partner ;
            PICT "@S50"
         @ box_x_koord() + 6, box_y_koord() + 2 SAY "Sifra artikla  " GET cIdRoba ;
            PICT "@S50"
      ENDIF

      @ box_x_koord() + 8, box_y_koord() + 2 SAY "BEZ/SA predhodnim prometom (1/2):" GET _preth_p VALID _preth_p $ "12"
      @ box_x_koord() + 10, box_y_koord() + 2 SAY "Datum dokumenta od:" GET _dat_od
      @ box_x_koord() + 10, Col() + 2 SAY "do" GET _dat_do VALID _dat_do >= _dat_do

      READ
      ESC_BCR

      IF _brza_k == "N"
         _usl_partner := Parsiraj( _partner, "IdPartner", "C" )
         _usl_roba := Parsiraj( cIdRoba, "IdRoba", "C" )
         _usl_konto := Parsiraj( _konto, "IdKonto", "C" )
         IF _usl_partner <> NIL .AND. _usl_roba <> NIL .AND. _usl_konto <> NIL
            EXIT
         ENDIF
      ELSE
         EXIT
      ENDIF

   ENDDO

   BoxC()


   WPar( "c1", _brza_k )
   WPar( "c2", PadR( _id_firma, 2 ) )
   WPar( "c3", _konto )
   WPar( "c4", _partner )
   WPar( "c5", cIdRoba )
   WPar( "c6", _preth_p )
   WPar( "d1", _dat_od )
   WPar( "d2", _dat_do )
   SELECT params
   USE

   O_MAT_SUBAN
   o_tdok()

   SELECT mat_suban
   SET ORDER TO TAG "3"

   IF _brza_k == "D"
      IF _preth_p == "1"
         IF !Empty( _dat_od ) .AND. !Empty( _dat_do )
            SET FILTER TO  _dat_od <= DatDok .AND. _dat_do >= DatDok
         ELSE
            SET FILTER TO
         ENDIF
      ELSE
         // sa predhodnim prometom
         IF  !Empty( _dat_do )
            SET FILTER TO  _dat_do >= DatDok
         ELSE
            SET FILTER TO
         ENDIF
      ENDIF

      HSEEK _id_firma + _konto + cIdRoba

   ELSE

      IF _preth_p == "1"

         IF !Empty( _dat_od ) .AND. !Empty( _dat_do )
            _filter += " .and. (DatDok >= " + ;
               dbf_quote( _dat_od ) + ;
               " .and. DatDok <= " + ;
               dbf_quote( _dat_do ) + ")"
         ENDIF
      ELSE

         IF !Empty( _dat_do )
            _filter += " .and. (DatDok <= " + ;
               dbf_quote( _dat_do ) + ")"

         ENDIF
      ENDIF

      IF !Empty( _partner )
         _filter += " .and. " + _usl_partner
      ENDIF

      IF !Empty( _konto )
         _filter += " .and. " + _usl_konto
      ENDIF

      IF !Empty( cIdRoba )
         _filter += " .and. " + _usl_roba
      ENDIF

      SET FILTER TO &( _filter )
      HSEEK _id_firma

   ENDIF

   // cBrza

   EOF CRET

   m := "-- ---- -- -------- -------- ------"

   FOR nI := 1 TO 3
      m += " " + Replicate( "-", Len( PICKOL ) )
   NEXT

   nI := 1
   FOR nI := 1 TO 5
      m += " " + Replicate( "-", Len( PICDEM ) )
   NEXT

   nStr := 0
   START PRINT CRET

   A := 0
   _col_1 := 0
   _col_2 := 0

   DO WHILE !Eof() .AND. IdFirma == _id_firma

      IF _brza_k == "D"
         IF _konto <> IdKonto .OR. cIdRoba <> IdRoba
            EXIT
         ENDIF
      ENDIF

      cIdKonto := IdKonto
      cIdRoba := IdRoba

      nUlazK := 0
      nIzlazK := 0
      nDugI := 0
      nPotI := 0
      nDugI2 := 0
      nPotI2 := 0

      ZaglKSif( _id_firma, cIdRoba, cIdKonto, m )

      IF _preth_p = "2"

         DO WHILE !Eof() .AND. IdFirma == _id_firma .AND. IdKonto == cIdKonto .AND. IdRoba == cIdRoba .AND. datdok < _dat_od
            IF U_I = "1"
               nUlazK += Kolicina
            ELSE
               nIzlazK += Kolicina
            ENDIF

            IF D_P = "1"
               nDugI += Iznos
               nDugI2 += Iznos2
            ELSE
               nPotI += Iznos
               nPotI2 += Iznos2
            ENDIF
            SKIP
         ENDDO
         ? "Promet do", _dat_od
         @ PRow(), 36 SAY nUlazK PICT pickol
         @ PRow(), PCol() + 1 SAY nIzlazK PICT pickol
         @ PRow(), PCol() + 1 SAY nUlazK - nIzlazK PICT pickol
         IF Round( nUlazK - nIzlazK, 4 ) <> 0
            nCijena = ( nDugI - nPotI ) / ( nUlazK - nIzlazK )
         ELSE
            nCijena := 0
         ENDIF
         @ PRow(), PCol() + 1 SAY nCijena PICT "9999999.999"
         @ PRow(), PCol() + 1 SAY nDugI PICT picdem
         @ PRow(), PCol() + 1 SAY nPotI PICT picdem
         @ PRow(), PCol() + 1 SAY nDugI2 PICT picbhd
         @ PRow(), PCol() + 1 SAY nPotI2 PICT picbhd

      ENDIF

      DO WHILE !Eof() .AND. IdFirma == _id_firma .AND. IdKonto == cIdKonto .AND. IdRoba == cIdRoba
         SELECT mat_suban

         IF PRow() > 61
            FF
            ZaglKSif( _id_firma, cIdRoba, cIdKonto, m )
         ENDIF
         @ PRow() + 1, 0 SAY IdVN
         @ PRow(), PCol() + 1 SAY BrNal
         @ PRow(), PCol() + 1 SAY IdTipDok
         @ PRow(), PCol() + 1 SAY BrDok
         @ PRow(), PCol() + 1 SAY DatDok
         @ PRow(), PCol() + 1 SAY IdPartner
         _col_1 := PCol() + 1
         IF U_I = "1"
            @ PRow(), PCol() + 1 SAY Kolicina PICTURE PicKol
            @ PRow(), PCol() + 1 SAY 0 PICTURE PicKol
            nUlazK += Kolicina
         ELSE
            @ PRow(), PCol() + 1 SAY 0 PICTURE PicKol
            @ PRow(), PCol() + 1 SAY Kolicina PICTURE PicKol
            nIzlazK += Kolicina
         ENDIF
         @ PRow(), PCol() + 1 SAY nUlazK - nIzlazK PICT pickol
         @ PRow(), PCol() + 1 SAY iif( Round( Kolicina, 4 ) <> 0, Iznos / Kolicina, 0 ) PICT PICDEM

         _col_2 := PCol() + 1
         IF D_P = "1"
            @ PRow(), PCol() + 1 SAY Iznos PICTURE PicDem
            @ PRow(), PCol() + 1 SAY 0 PICTURE PicDem
            @ PRow(), PCol() + 1 SAY Iznos2 PICTURE PicBHD
            @ PRow(), PCol() + 1 SAY 0 PICTURE PicBHD
            nDugI += Iznos
            nDugI2 += Iznos2
         ELSE
            @ PRow(), PCol() + 1 SAY 0 PICTURE PicDem
            @ PRow(), PCol() + 1 SAY Iznos PICTURE PicDem
            @ PRow(), PCol() + 1 SAY 0 PICTURE PicBHD
            @ PRow(), PCol() + 1 SAY Iznos PICTURE PicBHD
            nPotI += Iznos
            nPotI2 += Iznos2
         ENDIF
         SELECT mat_suban
         SKIP
      ENDDO

      IF PRow() > 59
         FF
         ZaglKSif( _id_firma, cIdRoba, cIdKonto, m )
      ENDIF

      ? m
      ? "UKUPNO:"
      @ PRow(), _col_1 SAY nUlazK PICTURE PicKol
      @ PRow(), PCol() + 1 SAY nIzlazK PICTURE PicKol
      @ PRow(), PCol() + 1 SAY nUlazK - nIzlazK PICTURE PicKol
      @ PRow(), _col_2    SAY nDugI PICTURE PicDEM
      @ PRow(), PCol() + 1 SAY nPotI PICTURE PicDEM
      @ PRow(), PCol() + 1 SAY nDugI2 PICTURE PicBHD
      @ PRow(), PCol() + 1 SAY nPotI2 PICTURE PicBHD
      ? m
      ? "SALDO:"

      nSaldoI := nDugI - nPotI
      nSaldoI2 := nDugI2 - nPotI2
      nSaldoK := nUlazK - nIzlazK
      nCijena := 0; nCijena2 := 0
      IF Round( nSaldoK, 4 ) <> 0
         nCijena = nSaldoI / nSaldoK
         nCijena2 := nSaldoI2 / nSaldoK
      ELSE
         nCijena := nCijena2 := 0
      ENDIF
      @ PRow(), PCol() + 2     SAY "CIJENA:"
      @ PRow(), PCol() + 1 SAY nCijena  PICTURE "999999.999"
      @ PRow(), PCol() + 1 SAY ValPomocna()

      IF nSaldoK > 0
         @ PRow(), _col_1 SAY nSaldoK PICTURE PicKol
         @ PRow(), PCol() + 1 SAY 0   PICTURE PicKol
      ELSE
         nSaldoK := -nSaldoK
         @ PRow(), _col_1    SAY 0       PICTURE PicKol
         @ PRow(), PCol() + 1 SAY nSaldoK PICTURE PicKol
      ENDIF
      @ PRow(), PCol() + 1 SAY Space( Len( pickol ) )

      IF nSaldoI > 0
         @ PRow(), _col_2 SAY nSaldoI PICTURE PicDEM
         @ PRow(), PCol() + 1 SAY 0 PICTURE PicDEM
      ELSE
         nSaldoI := -nSaldoI
         @ PRow(), _col_2  SAY 0         PICTURE PicDEM
         @ PRow(), PCol() + 1 SAY nSaldoI PICTURE PicDEM
      ENDIF
      IF nSaldoI2 > 0
         @ PRow(), PCol() + 1 SAY nSaldoI2 PICTURE PicBHD
         @ PRow(), PCol() + 1 SAY 0        PICTURE PicBHD
      ELSE
         nSaldoI2 := -nSaldoI2
         @ PRow(), PCol() + 1 SAY 0         PICTURE PicBHD
         @ PRow(), PCol() + 1 SAY nSaldoI2  PICTURE PicBHD
      ENDIF

      ? m
      ?
   ENDDO

   FF
   ENDPRINT

   my_close_all_dbf()

   RETURN


// --------------------------------------------------------------------
// zaglavlje
// --------------------------------------------------------------------
STATIC FUNCTION ZaglKSif( id_firma, id_roba, id_konto, line )

   ?
   P_COND2

   ?? "MAT.P: SUBANALITICKA KARTICA   NA DAN "
   @ PRow(), PCol() + 1 SAY Date()

   ? "FIRMA:"
   @ PRow(), PCol() + 1 SAY id_firma

   SELECT PARTN
   HSEEK id_firma

   @  PRow(), PCol() + 2 SAY naz
   @  PRow(), PCol() + 1 SAY naz2
   @  PRow(), 120 SAY "Str." + Str( ++nStr, 3 )

   ? "ARTIKAL:"
   @ PRow(), PCol() + 1 SAY id_roba

   select_o_roba( id_roba )

   @ PRow(), PCol() + 1 SAY naz
   @ PRow(), PCol() + 2 SAY jmj

   ? KonSeks( "KONTO" ) + ":"
   @ PRow(), PCol() + 1 SAY id_konto

   select_o_konto( id_konto )

   @ PRow(), PCol() + 1 SAY konto->naz

   ? line

   ?  "*NALOG *   D O K U M E N T         " + ;
      "*" + PadC( "KOLICINA", Len( PICKOL ) * 2 + 1 ) + ;
      "*" + PadC( "STANJE", Len( PICKOL ) ) + ;
      "*" + PadC( "CIJENA", Len( PICDEM ) ) + ;
      "*" + PadC( "I Z N O S  U " + valuta_domaca_skraceni_naziv(), ( Len( PICDEM ) * 2 ) + 1 ) + ;
      "*" + PadC( "I Z N O S  U " + ValPomocna(), ( Len( PICDEM ) * 2 ) + 1 ) + ;
      "*"

   ?  "------- --------------------------- " + ;
      Replicate( "-", Len( PICKOL ) * 3 + 2 ) + ;
      "*" + Replicate( "-", Len( PICDEM ) ) + ;
      "*" + Replicate( "-", Len( PICDEM ) * 2 + 1 ) + ;
      "*" + Replicate( "-", Len( PICDEM ) * 2 + 1 ) + ;
      "*"

   ?  "*V*BROJ*TIP* BROJ  * DATUM  * PART *" + ;
      PadC( "ULAZ", Len( PICKOL ) ) + ;
      "*" + PadC( "IZLAZ", Len( PICKOL ) ) + ;
      "*" + PadC( "STANJE", Len( PICKOL ) ) + ;
      "*" + PadC( valuta_domaca_skraceni_naziv(), Len( PICDEM ) ) + ;
      "*" + PadC( "DUGUJE", Len( PICDEM ) ) + ;
      "*" + PadC( "POTRAZUJE", Len( PICDEM ) ) + ;
      "*" + PadC( "DUGUJE", Len( PICDEM ) ) + ;
      "*" + PadC( "POTRAZUJE", Len( PICDEM ) ) + ;
      "*"
   ? line

   SELECT mat_suban

   RETURN
