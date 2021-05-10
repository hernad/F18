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


STATIC DUZ_STRANA := 64
STATIC s_cVarijantaObracuna
STATIC s_cRadnisatiDN := "N"


FUNCTION ld_kartica_plate( cIdRj, nMjesec, nGodina, cIdRadn, cObrac )

   LOCAL i
   LOCAL aNeta := {}
   LOCAL cRadniSatiDN := fetch_metric( "ld_radni_sati", NIL, "N" )
   LOCAL GetList := {}
   LOCAL cKarticaSifreTO := fetch_metric("ld_kartica_sifre_to", NIL, SPACE(10))
   LOCAL cKarticaTODN := fetch_metric("ld_kartica_to_dn", my_user(), "N")

   lSkrivena := .F.
   PRIVATE cLDLijevaMargina := ""

   s_cRadnisatiDN := cRadniSatiDN

   l2kolone := .F.

   cVarSort := "1"

   PRIVATE cNKNS
   cNKNS := "N"

   IF ( PCount() < 4 )
      cIdRadn := Space( LEN_IDRADNIK )
      cIdRj := gLDRadnaJedinica
      nMjesec := ld_tekuci_mjesec()
      nGodina := ld_tekuca_godina()
      cObracun := gObracun

      o_ld_parametri_obracuna()
      o_ld_rj()
      o_ld_radn()
      o_ld_vrste_posla()
      // O_RADKR
      o_kred()
      // select_o_ld()

   ELSE
      cObracun := cObrac
   ENDIF

//   IF s_cRadnisatiDN == "D"
  //    O_RADSAT
  // ENDIF

   PRIVATE nC1 := 20 + Len( cLDLijevaMargina )

   cVarijanta := " "
   c2K1L := "D"

   IF ( PCount() < 4 )
      o_params()
      PRIVATE cSection := "4"
      PRIVATE cHistory := " "
      PRIVATE aHistory := {}
      RPar( "VS", @cVarSort )
      RPar( "2K", @c2K1L )
      RPar( "NK", @cNKNS )
      cIdRadn := Space( LEN_IDRADNIK )
      Box(, 9, 75 )
      @ box_x_koord() + 1, box_y_koord() + 2 SAY _l( "Radna jedinica (prazno-sve rj): " )  GET cIdRJ VALID Empty( cidrj ) .OR. P_LD_RJ( @cidrj )
      @ box_x_koord() + 2, box_y_koord() + 2 SAY _l( "Mjesec: " ) GET nMjesec PICT "99"
      IF ld_vise_obracuna()
         @ box_x_koord() + 2, Col() + 2 SAY _l( "Obracun: " ) GET cObracun WHEN ld_help_broj_obracuna( .T., cObracun ) VALID ld_valid_obracun( .T., cObracun )
      ENDIF
      @ box_x_koord() + 3, box_y_koord() + 2 SAY _l( "Godina: " ) GET nGodina PICT "9999"
      @ box_x_koord() + 4, box_y_koord() + 2 SAY _l( "Radnik (prazno-svi radnici): " )  GET  cIdRadn  VALID Empty( cIdRadn ) .OR. P_Radn( @cIdRadn )
      @ box_x_koord() + 5, box_y_koord() + 2 SAY _l( "Varijanta ( /5): " )  GET  cVarijanta VALID cVarijanta $ " 5"
      @ box_x_koord() + 6, box_y_koord() + 2 SAY _l( "Ako su svi radnici, sortirati po (1-sifri,2-prezime+ime)" )  GET cVarSort VALID cVarSort $ "12"  PICT "9"
      @ box_x_koord() + 7, box_y_koord() + 2 SAY _l( "Dvije kartice na jedan list ? (D/N)" )  GET c2K1L VALID c2K1L $ "DN"  PICT "@!"
      @ box_x_koord() + 8, box_y_koord() + 2 SAY _l( "Ispis svake kartice krece od pocetka stranice? (D/N)" )  GET cNKNS VALID cNKNS $ "DN"  PICT "@!"

      IF !Empty(cKarticaSifreTO)
         @ box_x_koord() + 9, box_y_koord() + 2 SAY8 "Ispis kartice TO? (D/N)"  GET cKarticaTODN VALID cKarticaTODN $ "DN"  PICT "@!"
      ENDIF

      READ

      clvbox()
      ESC_BCR
      BoxC()
      SELECT params
      WPar( "VS", cVarSort )
      WPar( "2K", c2K1L )
      WPar( "NK", cNKNS )
      SELECT PARAMS
      USE
      set_metric("ld_kartica_to_dn", my_user(), cKarticaTODN)
      set_tippr_ili_tippr2( cObracun )
   ENDIF


   ld_porezi_i_doprinosi_iz_sezone( nGodina, nMjesec )

   IF cVarijanta == "5"
      O_LDSM
   ENDIF


   cIdRadn := Trim( cIdradn )

   IF Empty( cIdRadn ) .AND. cVarSort == "2"
      IF Empty( cIdRj )
         IF ld_vise_obracuna() .AND. !Empty( cObracun )
            seek_ld( NIL, nGodina, nMjesec, cObracun, cIdRadn )
            INDEX ON Str( field->godina ) + Str( field->mjesec ) + field->obr + SortPrez( field->idradn ) + field->idrj TO "tmpld"
            // SEEK Str( nGodina, 4 ) + Str( nMjesec, 2 ) + cObracun + cIdRadn
            GO TOP

         ELSE
            seek_ld( NIL, nGodina, nMjesec, NIL, cIdRadn )
            INDEX ON Str( field->godina ) + Str( field->mjesec ) + SortPrez( field->idradn ) + idrj TO "tmpld"
            // SEEK Str( nGodina, 4 ) + Str( nMjesec, 2 ) + cIdRadn
            GO TOP
         ENDIF
         cIdrj := ""
      ELSE

         IF ld_vise_obracuna() .AND. !Empty( cObracun )
            // SEEK Str( nGodina, 4 ) + cIdrj + Str( nMjesec, 2 ) + cObracun + cIdRadn
            seek_ld( cIdRj, nGodina, nMjesec, cObracun, cIdRadn )
            INDEX ON Str( field->godina ) + field->idrj + Str( field->mjesec ) + field->obr + SortPrez( field->idradn ) TO "tmpld"
            GO TOP
         ELSE
            seek_ld( cIdRj, nGodina, nMjesec, NIL, cIdRadn )
            INDEX ON Str( field->godina ) + field->idrj + Str( field->mjesec ) + SortPrez( field->idradn ) TO "tmpld"
            // SEEK Str( nGodina, 4 ) + cIdrj + Str( nMjesec, 2 ) + cIdRadn
            GO TOP
         ENDIF
      ENDIF

   ELSE
      IF Empty( cIdrj )
         // SET ORDER TO TAG ( ld_index_tag_vise_obracuna( "2" ) )
         // SEEK Str( nGodina, 4 ) + Str( nMjesec, 2 ) + iif( ld_vise_obracuna() .AND. !Empty( cObracun ), cObracun, "" ) + cIdRadn
         seek_ld_2( NIL, nGodina, nMjesec, iif( ld_vise_obracuna() .AND. !Empty( cObracun ), cObracun, NIL ), cIdRadn )
         cIdrj := ""
      ELSE
         seek_ld( cIdRj, nGodina, nMjesec, iif( ld_vise_obracuna() .AND. !Empty( cObracun ), cObracun, NIL ), cIdRadn )
         IF PCount() < 4
            SET ORDER TO TAG ( ld_index_tag_vise_obracuna( "1" ) )
         ENDIF
         // SEEK Str( nGodina, 4 ) + cidrj + Str( nMjesec, 2 ) + iif( ld_vise_obracuna() .AND. !Empty( cObracun ), cObracun, "" ) + cIdRadn
      ENDIF
   ENDIF

   EOF CRET

   nStrana := 0

   select_o_vposla( ld->idvposla )
   select_o_ld_rj( ld->idrj )

   SELECT ld

   IF PCount() >= 4
      START PRINT RET
   ELSE
      START PRINT CRET
   ENDIF

   ?
   P_12CPI

   ld_pozicija_parobr( nMjesec, nGodina, iif( ld_vise_obracuna(), cObracun, ), cIdRj )

   PRIVATE lNKNS
   lNKNS := ( cNKNS == "D" )

   nRbrKart := 0

   bZagl := {|| ld_zagl_kartica() }

   nT1 := nT2 := nT3 := nT4 := 0

   // -- Prikaz samo odredjenih doprinosa na kartici plate
   // -- U fmk.ini /kumpath se definisu koji dopr. da se prikazuju
   // -- Po defaultu stoji prazno - svi doprinosi

   //cPrikDopr := my_get_from_ini( "LD", "DoprNaKartPl", "D", KUMPATH )
   //cPrikDopr := "D"
   //lPrikSveDopr := ( cPrikDopr == "D" )
   lPrikSveDopr := .T.

   DO WHILE !Eof() .AND. nGodina == godina .AND. idrj = cidrj .AND. nMjesec = mjesec .AND. idradn = cIdRadn .AND. !( ld_vise_obracuna() .AND. !Empty( cObracun ) .AND. obr <> cObracun )

      aNeta := {}

      IF ld_vise_obracuna() .AND. Empty( cObracun )
         ScatterS( Godina, Mjesec, IdRJ, IdRadn )
      ELSE
         Scatter()
      ENDIF

      cRTRada := get_ld_rj_tip_rada( _idradn, _idrj )

      select_o_radn( _idradn )
      select_o_vposla( _idvposla )
      select_o_ld_rj( _idrj )

      SELECT ld

      AAdd( aNeta, { vposla->idkbenef, _UNeto } )

      s_cVarijantaObracuna := get_varobr()

      IF cRTRada == "S"
         ld_kartica_plate_samostalni( cIdRj, nMjesec, nGodina, cIdRadn, cObrac, @aNeta )
      ELSEIF cRTRada $ "AU"
         ld_kartica_plate_ugovori( cIdRj, nMjesec, nGodina, cIdRadn, cObrac, @aNeta )
      ELSEIF cRTRada == "P"
         ld_kartica_plate_upravni_odbor( cIdRj, nMjesec, nGodina, cIdRadn, cObrac, @aNeta )
      ELSE
         ld_kartica_redovan_rad( cIdRj, nMjesec, nGodina, cIdRadn, cObrac, @aNeta, cKarticaSifreTO, cKarticaTODN == "D" )
      ENDIF

      nT1 += _usati
      nT2 += _uneto
      nT3 += _uodbici
      nT4 += _uiznos

      SELECT ld
      SKIP 1
   ENDDO

   IF PCount() >= 4  // predji na drugu stranu
      FF
   ENDIF

   ENDPRINT

   IF PCount() < 4
      my_close_all_dbf()
   ELSE // pcount >= "4"

  //    IF s_cRadnisatiDN == "D"
    //     O_RADSAT
  //    ENDIF

      o_ld_parametri_obracuna()
      o_ld_rj()
      o_ld_radn()
      o_ld_vrste_posla()
      // O_RADKR
      o_kred()

      // select_o_ld()
      // SET ORDER TO tag ( ld_index_tag_vise_obracuna( "1" ) )

   ENDIF

   RETURN .T.



STATIC FUNCTION ld_zagl_kartica()

   ++nRBrKart

   // nova stranica odredjuje odakle ce se poceti stampati
   // gura karticu do polovine stranice ako fali redova
   IF !lNKNS .AND. !( gPrBruto $ "DX" ) .AND. c2K1L == "D" .AND. ( nRBrKart % 2 ) == 0
      DO WHILE PRow() < 34
         ?
      ENDDO
   ENDIF

   ?U "OBRAČUN PLATE ZA" + Space( 1 ) + Str( mjesec, 2 ) + "/" + Str( godina, 4 ) + " (obr. " + IspisObr() + ")", " ZA " + Upper( Trim( tip_organizacije() ) ), self_organizacija_naziv()
   ? "RJ:", idrj, ld_rj->naz
   ? idradn, "-", RADNIK_PREZ_IME, "  Mat.br:", radn->matbr
   ld_angazovan_od_do( radn->hiredfrom, radn->hiredto, "" )
   ? _l( "Radno mjesto:" ), radn->rmjesto, "  STR.SPR:", IDSTRSPR
   ? _l( "Vrsta posla:" ), idvposla, vposla->naz, "         Radi od:", radn->datod
   ? IF( gBodK == "1", _l( "Broj bodova :" ), _l( "Koeficijent :" ) ), Transform( brbod, "99999.99" ), Space( 24 )
   IF gMinR == "B"
      ?? _l( "Minuli rad:" ), Transform( kminrad, "9999.99" )
   ELSE
      ?? _l( "K.Min.rada:" ), Transform( kminrad, "99.99%" )
   ENDIF
   ? IF( gBodK == "1", _l( "Vrijednost boda:" ), _l( "Vr.koeficijenta:" ) ), Transform( parobr->vrbod, "99999.99999" )

   IF radn->n1 <> 0 .OR. radn->n2 <> 0
      ? _l( "N1:" ), Transform( radn->n1, "99999999.9999" )
      ?? Space( 2 ) + ;
         _l( "N2:" ), Transform( radn->n2, "99999999.9999" )
   ENDIF

   IF s_cVarijantaObracuna == "2"
      ?? Space( 2 ) +  "Koef.licnog odbitka:", AllTrim( Str( get_koeficijent_licnog_odbitka( ld->ulicodb ) ) )
   ENDIF

   IF s_cRadnisatiDN == "D"
      ?? Space( 2 ) + _l( "Radni sati:   " ) + AllTrim( Str( ld->radsat ) )
   ENDIF

   RETURN .T.


FUNCTION ld_kartica_redova()

   LOCAL nRows := 0
   LOCAL cField
   LOCAL cFIznos := "_I"
   LOCAL cFSati := "_S"
   LOCAL nStRedova := 23

   IF gPrBruto == "X"
      nStRedova := 32
   ENDIF

   // ako nema potpisa standardnih redova je manje
   IF gPotp == "N"
      nStRedova := nStRedova - 4
   ENDIF

   // ispitaj standardna ld polja _I(nn), _S(nn)
   FOR i := 1 TO cLDPolja
      cField := PadL( AllTrim( Str( i ) ), 2, "0" )
      IF &( cFIznos + cField ) <> 0 .OR. &( cFSati + cField ) <> 0
         ++nRows
      ENDIF
   NEXT

   // ispitaj kredite
   // SELECT radkr
   // SET ORDER TO 1
   // SEEK Str( _godina, 4 ) + Str( _mjesec, 2 ) + _idradn
   seek_radkr( _godina, _mjesec, _idradn )

   DO WHILE !Eof() .AND. _godina == godina .AND. _mjesec = mjesec .AND. idradn == _idradn
      ++nRows
      SKIP
   ENDDO
   SELECT ld

   RETURN ( nRows + nStRedova )


FUNCTION ld_kartica_potpis()

   IF gPotp == "D"
      ?
      ? cLDLijevaMargina + Space( 5 ), _l( "   Obracunao:  " ), Space( 30 ), _l( "    Potpis:" )
      ? cLDLijevaMargina + Space( 5 ), "_______________", Space( 30 ), "_______________"
      ?
   ENDIF

   RETURN .T.



STATIC FUNCTION prikazi_primanja()

   LOCAL nIznos := 0

   IF "U" $ Type( "cLDLijevaMargina" ); cLDLijevaMargina := ""; ENDIF
   IF "U" $ Type( "l2kolone" ); l2kolone := .F. ; ENDIF
   IF tippr->( Found() ) .AND. tippr->aktivan == "D"
      IF _I&cpom <> 0 .OR. _S&cPom <> 0
         ? cLDLijevaMargina + tippr->id + "-" + tippr->naz, tippr->opis
         nC1 := PCol()
         IF tippr->uneto == "N"
            nIznos := Abs( _I&cPom )
         ELSE
            nIznos := _I&cPom
         ENDIF
         IF tippr->fiksan $ "DN"
            @ PRow(), PCol() + 8 SAY _S&cPom  PICT gpics; ?? " s"
            @ PRow(), 60 + Len( cLDLijevaMargina ) SAY niznos        PICT gpici
         ELSEIF tippr->fiksan == "P"
            @ PRow(), PCol() + 8 SAY _S&cPom  PICT "999.99%"
            @ PRow(), 60 + Len( cLDLijevaMargina ) SAY niznos        PICT gpici
         ELSEIF tippr->fiksan == "B"
            @ PRow(), PCol() + 8 SAY Abs( _S&cPom )  PICT "999999"; ?? " b"
            @ PRow(), 60 + Len( cLDLijevaMargina ) SAY niznos        PICT gpici
         ELSEIF tippr->fiksan == "C"
            IF !( "SUMKREDITA" $ tippr->formula )
               @ PRow(), 60 + Len( cLDLijevaMargina ) SAY niznos        PICT gpici
            ENDIF
         ENDIF

         IF "SUMKREDITA" $ tippr->formula
            // SELECT radkr
            // SET ORDER TO 1
            // SEEK Str( _godina, 4 ) + Str( _mjesec, 2 ) + _idradn
            seek_radkr( _godina, _mjesec, _idradn )

            ukredita := 0
            IF l2kolone
               P_COND2
            ELSE
               P_COND
            ENDIF
            ? m2 := cLDLijevaMargina + " ------------------------------------------- --------- --------- -------"
            ? cLDLijevaMargina + "    Kreditor   /             na osnovu         Ukupno    Ostalo   Rata"
            ? m2
            DO WHILE !Eof() .AND. _godina == godina .AND. _mjesec = mjesec .AND. idradn == _idradn
               select_o_kred( radkr->idkred )

               SELECT radkr
               aIznosi := ld_iznosi_za_kredit( idradn, idkred, naosnovu, _mjesec, _godina )
               ? cLDLijevaMargina, idkred, Left( kred->naz, 15 ), PadR( naosnovu, 20 )
               @ PRow(), PCol() + 1 SAY aIznosi[ 1 ] PICT "999999.99" // ukupno
               @ PRow(), PCol() + 1 SAY aIznosi[ 1 ] - aIznosi[ 2 ] PICT "999999.99"// ukupno-placeno
               @ PRow(), PCol() + 1 SAY iznos PICT "9999.99"
               ukredita += iznos
               SKIP
            ENDDO
            IF Round( ukredita - niznos, 2 ) <> 0
               SET DEVICE TO SCREEN
               Beep( 2 )
               Msg( "Za radnika " + _idradn + " iznos sume kredita ne odgovara stanju baze kredita !", 6 )
               SET DEVICE TO PRINTER
            ENDIF

            // ? m
            IF l2kolone
               P_COND2
            ELSE
               P_12CPI
            ENDIF
            SELECT ld
         ENDIF
         IF "_K" == Right( AllTrim( tippr->opis ), 2 )
            nKumPrim := ld_kumulativna_primanja( _IdRadn, cPom )

            IF SubStr( AllTrim( tippr->opis ), 2, 1 ) == "1"
               nKumPrim := nkumprim + radn->n1
            ELSEIF  SubStr( AllTrim( tippr->opis ), 2, 1 ) == "2"
               nKumPrim := nkumprim + radn->n2
            ELSEIF  SubStr( AllTrim( tippr->opis ), 2, 1 ) == "3"
               nKumPrim := nkumprim + radn->n3
            ENDIF

            IF tippr->uneto == "N"; nKumPrim := Abs( nKumPrim ); ENDIF
            ? m2 := cLDLijevaMargina + "   ----------------------------- ----------------------------"
            ? cLDLijevaMargina + "    SUMA IZ PRETHODNIH OBRA¬UNA   UKUPNO (SA OVIM OBRA¬UNOM)"
            ? m2
            ? cLDLijevaMargina + "   " + PadC( Str( nKumPrim - nIznos ), 29 ) + " " + PadC( Str( nKumPrim ), 28 )
            ? m2
         ENDIF
      ENDIF
   ENDIF

   RETURN



FUNCTION ld_kumulativna_primanja( cIdRadn, cIdPrim )

   LOCAL j := 0, nVrati := 0, nOdGod := 0, nDoGod := 0

   cPom77 := cIdPrim
   IF cIdRadn == NIL; cIdRadn := ""; ENDIF

   //SELECT LD
   PushWA()

   //SET ORDER TO TAG ( ld_index_tag_vise_obracuna( "4" ) )
   //GO BOTTOM

   nDoGod := ld_max_godina()

   //GO TOP
   nOdGod := ld_min_godina()

   FOR j := nOdGod TO nDoGod
      //GO TOP
      //SEEK Str( j, 4 ) + cIdRadn
      seek_ld( NIL, j, NIL, NIL, cIdRadn, "4" )
      //SET ORDER TO TAG "4"
      //GO TOP

      DO WHILE godina == j .AND. cIdRadn == IdRadn
         nVrati += i&cPom77
         SKIP 1
      ENDDO

   NEXT
   SELECT LD
   PopWA()

   RETURN nVrati
