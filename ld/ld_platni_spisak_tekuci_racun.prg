#include "f18.ch"

MEMVAR cTpr, cLDPolja

FUNCTION ld_platni_spisak_tekuci_racun( cVarijanta )

   LOCAL nC1 := 20
   LOCAL cVarSort
   LOCAL GetList := {}

   LOCAL nIznosZaIsplatu, nIzbitiIzNeto, nIzbitiIzOstalo, nUneto2
   LOCAL cRekapTipoviOut := fetch_metric("ld_rekap_out", NIL, SPACE(10))
   LOCAL cPrikazTODN := "N", lPrikazTO

   cIdRadn := Space( LEN_IDRADNIK )
   cIdRj := gLDRadnaJedinica
   nMjesec := ld_tekuci_mjesec()
   nGodina := ld_tekuca_godina()
   cObracun := gObracun
   cVarSort := "2"
   cProred := "N"
   cPrikIzn := "D"
   nProcenat := 100
   nZkk := gZaok

   // o_kred()
   o_ld_rj()
   o_ld_radn()
   // select_o_ld()

   PRIVATE cIsplata := ""
   PRIVATE cLokacija
   PRIVATE cConstBrojTR
   PRIVATE nH
   PRIVATE cParKonv

   IF cVarijanta == "1"
      cIsplata := "TR"
   ELSE
      cIsplata := "SK"
   ENDIF

   cZaBanku := "N"
   cIDBanka := Space( LEN_IDRADNIK )
   cDrugiDio := "D"
   cVarSort := fetch_metric( "ld_platni_spisak_sortiranje", my_user(), cVarSort )

   Box(, 12, 50 )

   @ box_x_koord() + 1, box_y_koord() + 2 SAY "Radna jedinica (prazno-sve): "  GET cIdRJ
   @ box_x_koord() + 2, box_y_koord() + 2 SAY "Mjesec: "  GET  nMjesec  PICT "99"
   @ box_x_koord() + 2, Col() + 2 SAY "Obracun: "  GET  cObracun WHEN ld_help_broj_obracuna( .T., cObracun ) VALID ld_valid_obracun( .T., cObracun )
   @ box_x_koord() + 3, box_y_koord() + 2 SAY "Godina: "  GET  nGodina  PICT "9999"
   @ box_x_koord() + 4, box_y_koord() + 2 SAY "Prored:"   GET  cProred  PICT "@!"  VALID cProred $ "DN"
   @ box_x_koord() + 5, box_y_koord() + 2 SAY "Prikaz iznosa:" GET cPrikIzn PICT "@!" VALID cPrikizn $ "DN"
   @ box_x_koord() + 6, box_y_koord() + 2 SAY "Prikaz u procentu %:" GET nprocenat PICT "999.99"
   @ box_x_koord() + 7, box_y_koord() + 2 SAY "Banka        :" GET cIdBanka VALID P_Kred( @cIdBanka )
   @ box_x_koord() + 8, box_y_koord() + 2 SAY "Sortirati po(1-sifri,2-prezime+ime)"  GET cVarSort VALID cVarSort $ "12"  PICT "9"
   @ box_x_koord() + 11, box_y_koord() + 2 SAY "Spremiti izvjestaj za banku (D/N)" GET cZaBanku PICT "@!"

   IF !Empty(cRekapTipoviOut)
     @ box_x_koord() + 12, box_y_koord() + 2 SAY "Prikaz TO (D/N)" GET cPrikazTODN PICT "@!"
   ENDIF

   READ

   clvbox()

   ESC_BCR

   IF nProcenat <> 100
      @ box_x_koord() + 9, box_y_koord() + 2 SAY "zaokruzenje" GET nZkk PICT "99"
      @ box_x_koord() + 10, box_y_koord() + 2 SAY "Prikazati i drugi spisak (za " + LTrim( Str( 100 - nProcenat, 6, 2 ) ) + "%-tni dio)" GET cDrugiDio VALID cDrugiDio $ "DN" PICT "@!"
      READ
   ELSE
      cDrugiDio := "N"
   ENDIF

   BoxC()

   set_metric( "ld_platni_spisak_sortiranje", my_user(), cVarSort )

   IF cZaBanku == "D"
      CreateFileBanka()
   ENDIF

   // SELECT ld
   // CREATE_INDEX("LDi1","str(godina)+idrj+str(mjesec)+idradn","LD")
   // CREATE_INDEX("LDi2","str(godina)+str(mjesec)+idradn","LD")

   cObracun := Trim( cObracun )

   IF Empty( cIdRj )

      cIdRj := ""

      IF cVarSort == "1"
         // SET ORDER TO TAG ( ld_index_tag_vise_obracuna( "2" ) )
         // HSEEK Str( nGodina, 4 ) + Str( nMjesec, 2 ) + cObracun
         seek_ld_2( NIL, nGodina, nMjesec, cObracun )
      ELSE
         seek_ld( NIL, nGodina, nMjesec, cObracun )
         Box(, 2, 30 )
         nSlog := 0
         cSort1 := "SortPrez(IDRADN)"
         cFilt := iif( Empty( nMjesec ), ".t.", "MJESEC==" + _filter_quote( nMjesec ) ) + ".and." + IIF( Empty( nGodina ), ".t.", "GODINA==" + _filter_quote( nGodina ) )
         IF ld_vise_obracuna()
            cFilt += ".and. obr=" + _filter_quote( cObracun )
         ENDIF
         INDEX ON &cSort1 TO "tmpld" FOR &cFilt
         BoxC()
         GO TOP
      ENDIF

   ELSE

      IF cVarSort == "1"
         // SET ORDER TO TAG ( ld_index_tag_vise_obracuna( "1" ) )
         // HSEEK Str( nGodina, 4 ) + cidrj + Str( nMjesec, 2 ) + cObracun
         seek_ld( cIdRj, nGodina, nMjesec, cObracun )
      ELSE
         seek_ld( cIdRj, nGodina, nMjesec, cObracun )
         Box(, 2, 30 )
         nSlog := 0
         cSort1 := "SortPrez(IDRADN)"
         cFilt := "IDRJ==" + _filter_quote( cIdRj ) + ".and." + IIF( Empty( nMjesec ), ".t.", "MJESEC==" + _filter_quote( nMjesec ) ) + ".and." + IIF( Empty( nGodina ), ".t.", "GODINA==" + _filter_quote( nGodina ) )
         IF ld_vise_obracuna()
            cFilt += ".and. obr=" + _filter_quote( cObracun )
         ENDIF
         INDEX ON &cSort1 TO "tmpld" FOR &cFilt
         BoxC()
         GO TOP
      ENDIF

   ENDIF

   EOF CRET

   nStrana := 0

   // linija za zaglavlje
   m := Replicate( "-", 5 )
   m += Space( 1 )
   m += Replicate( "-", 6 )
   m += Space( 1 )
   m += Replicate( "-", 13 )
   m += Space( 1 )
   m += Replicate( "-", 35 )
   m += Space( 1 )
   m += Replicate( "-", 11 )
   m += Space( 1 )
   m += Replicate( "-", 25 )

   bZagl := {|| ld_zagl_spisak_tekuci_racun() }

   select_o_ld_rj( ld->idrj )
   SELECT ld

   START PRINT CRET

   nPocRec := RecNo()

   FOR nDio := 1 TO IIF( cDrugiDio == "D", 2, 1 )

      IF nDio == 2
         GO ( nPocRec )
      ENDIF

      Eval( bZagl )

      nT1 := 0
      nT2 := 0
      nT3 := 0
      nT4 := 0
      nRbr := 0

      DO WHILE !Eof() .AND.  nGodina == godina .AND. idrj = cIdRj .AND. nMjesec = mjesec .AND. !( ld_vise_obracuna() .AND. !Empty( cObracun ) .AND. obr <> cObracun )

         IF ld_vise_obracuna() .AND. Empty( cObracun )
            ScatterS( godina, mjesec, idrj, idradn )
         ELSE
            Scatter()
         ENDIF

         select_o_radn( _idradn )
         SELECT ld

         IF radn->isplata <> cIsplata .OR. radn->idbanka <> cIdBanka
            // samo za tekuce racune
            SKIP
            LOOP
         ENDIF


         ? Str( ++nRbr, 4 ) + ".", idradn, radn->matbr, RADNIK_PREZ_IME

         IF cZaBanku == "D"
            cZaBnkRadnik := FormatSTR( AllTrim( RADNZABNK ), 40 )
         ENDIF

         nC1 := PCol() + 1


         ld_izbiti_iz_ukupno( cRekapTipoviOut, cPrikazTODN == "D", @nIzbitiIzNeto, @nIzbitiIzOstalo )
         // _uneto2 :=  _ubruto - _udopr  _uporez
         // _uiznos = _uneto2 + _uodbici

         IF nIzbitiIzNeto <> 0
            nUNeto2 := ld_obracun_radnik_neto2(_IdRadn, _IdRj, _I01, _UNeto - nIzbitiIzNeto, _USati, _UlicOdb)
            nIznosZaIsplatu := nUneto2 + _uodbici - nIzbitiIzOstalo
         ELSE
            nIznosZaIsplatu := _uIznos
         ENDIF

         IF cPrikIzn == "D"
            IF nProcenat <> 100
               IF nDio == 1
                  @ PRow(), PCol() + 1 SAY Round( nIznosZaIsplatu * nProcenat / 100, nzkk ) PICT gpici
               ELSE
                  @ PRow(), PCol() + 1 SAY Round( nIznosZaIsplatu, nZkk ) - Round( nIznosZaIsplatu * nProcenat / 100, nzkk ) PICT gpici
               ENDIF
            ELSE
               @ PRow(), PCol() + 1 SAY nIznosZaIsplatu PICT gpici
               IF cZaBanku == "D"
                  cZaBnkIznos := FormatSTR( AllTrim( Str( nIznosZaIsplatu ), 8, 2 ), 8, .T. )
               ENDIF
            ENDIF
         ELSE
            @ PRow(), PCol() + 1 SAY Space( Len( gpici ) )
         ENDIF

         IF cIsplata == "TR"
            @ PRow(), PCol() + 4 SAY PadL( radn->brtekr, 22 )
            IF cZaBanku == "D"
               cZaBnkTekRn := FormatSTR( AllTrim( radn->brtekr ), 25, .F., "" )
            ENDIF
         ELSE
            @ PRow(), PCol() + 4 SAY PadL( radn->brknjiz, 22 )
            IF cZaBanku == "D"
               cZaBnkTekRn := FormatSTR( AllTrim( radn->brknjiz ), 25, .F., "" )
            ENDIF
         ENDIF

         IF cProred == "D"
            ?
         ENDIF

         nT1 += _usati
         nT2 += _uneto
         nT3 += _uodbici

         IF nProcenat <> 100
            IF nDio == 1
               nT4 += Round( nIznosZaIsplatu * nProcenat / 100, nZkk )
            ELSE
               nT4 += ( Round( nIznosZaIsplatu, nZkk ) - Round( nIznosZaIsplatu * nProcenat / 100, nZKK ) )
            ENDIF
         ELSE
            nT4 += nIznosZaIsplatu
         ENDIF

         SKIP

         // upisi u fajl za banku
         IF cZaBanku == "D"

            cUpisiZaBanku := ""
            cUpisiZaBanku += cZaBnkTekRn
            cUpisiZaBanku += cZaBnkRadnik
            cUpisiZaBanku += cZaBnkIznos

            // napravi konverziju
            KonvZnWin( @cUpisiZaBanku, cParKonv )

            Write2File( nH, cUpisiZaBanku, .T. )

            // reset varijable
            cUpisiZaBanku := ""

         ENDIF

      ENDDO


      ? m

      ? Space( 1 ) + _l( "UKUPNO:" )

      IF cPrikIzn == "D"
         @ PRow(), nC1 SAY nT4 PICT gPici
      ENDIF

      ? m

      ? p_potpis()

      FF

   NEXT

   IF cZaBanku == "D"
      CloseFileBanka( nH )
   ENDIF

   ENDPRINT

   my_close_all_dbf()

   RETURN .T.



FUNCTION ld_zagl_spisak_tekuci_racun()

   select_o_kred( cIdBanka )

   SELECT ld

   ?

   P_12CPI
   P_COND

   ? _l( "Poslovna BANKA:" ) + Space( 1 ), cIDBanka, "-", kred->naz
   ?
   ? Upper( tip_organizacije() ) + ":", self_organizacija_naziv()
   ?

   IF Empty( cIdRj )
      ? _l( "Pregled za sve RJ ukupno:" )
   ELSE
      ? _l( "RJ:" ), cIdRj, ld_rj->naz
   ENDIF

   ?? Space( 2 ) + _l( "Mjesec:" ), Str( nMjesec, 2 ) + IspisObr()
   ?? Space( 4 ) + _l( "Godina:" ), Str( nGodina, 5 )

   DevPos( PRow(), 74 )

   ?? _l( "Str." ), Str( ++nStrana, 3 )
   ?

   IF nProcenat <> 100

      ?
      ? _l( "Procenat za isplatu:" )
      IF nDio == 1
         @ PRow(), PCol() + 1 SAY nProcenat PICT "999.99%"
      ELSE
         @ PRow(), PCol() + 1 SAY 100 - nProcenat PICT "999.99%"
      ENDIF
      ?

   ENDIF

   ?
   ? m
   ? _l( "Rbr   Sifra    JMB                 Naziv radnika               " ) + iif( cPrikIzn == "D", _l( "ZA ISPLATU" ), "          " ) + iif( cIsplata == "TR", Space( 9 ) + _l( "Broj T.Rac" ), Space( 8 ) + _l( "Broj St.knj" ) )
   ? m

   RETURN .T.


FUNCTION ld_izbiti_iz_ukupno( cRekapTipoviOut, lPrikazTO, nIzbitiIzNeto, nIzbitiIzOstalo )

   LOCAL i, cTprField
   
   LOCAL bIskljuciPrimanja := { | cTip | !Empty(cRekapTipoviOut) .AND. cTip $ cRekapTipoviOut }

   IF lPrikazTO // rekapitulacija TO - samo primanja navedena u cRekaptTipoviOut, npr. "08,32"
      bIskljuciPrimanja := { | cTip | !Empty(cRekapTipoviOut) .AND. !(cTip $ cRekapTipoviOut) }
   ENDIF

   PRIVATE cTpr

   nIzbitiIzNeto := 0
   nIzbitiIzOstalo := 0

   FOR i := 1 TO cLDPolja // cLDPolja public var

      cTprField := PadL( AllTrim( Str( i ) ), 2, "0" )
      select_o_tippr( cTprField )
      SELECT ld

      cTpr := "_I" + cTprField
      IF Eval(bIskljuciPrimanja, cTprField)
         // tip primanja npr. TO neoporezivi izbaciti
         IF tippr->uneto == "D"
            nIzbitiIzNeto += &cTpr
         ELSE
            nIzbitiIzOstalo += &cTpr
         ENDIF
         loop
      ENDIF

   NEXT


RETURN .T.