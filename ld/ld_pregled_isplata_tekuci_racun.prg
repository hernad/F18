#include "f18.ch"


FUNCTION ld_pregled_isplate_za_tekuci_racun( cVarijanta )

   LOCAL nC1 := 20
   LOCAL GetList := {}
   LOCAL cFilt := ".t."
   LOCAL cIsplata := ""

   cIdRadn := Space( LEN_IDRADNIK )
   cIdRj := gLDRadnaJedinica
   nMjesec := ld_tekuci_mjesec()
   nGodina := ld_tekuca_godina()
   cObracun := gObracun
   cVarSort := "2"
   cIdTipPr := "  "


   // o_tippr()
   // o_kred()
   // o_ld_rj()
   // o_ld_radn()
   // select_o_ld()
   // SET RELATION TO idradn into radn

   cProred := "N"
   cPrikIzn := "D"
   nZkk := gZaok

   // PRIVATE cIsplata := ""
   PRIVATE cLokacija
   PRIVATE cConstBrojTR
   PRIVATE nH

   IF cVarijanta == "1"
      cIsplata := "TR"
   ELSE
      cIsplata := "SK"
   ENDIF

   cIDBanka := Space( FIELD_LD_RADN_IDBANKA )
   // cVarSort := fetch_metric( "ld_platni_spisak_sortiranje", my_user(), "2" )

   Box(, 10, 50 )
   @ box_x_koord() + 1, box_y_koord() + 2 SAY "Radna jedinica (prazno-sve): "  GET cIdRJ
   @ box_x_koord() + 2, box_y_koord() + 2 SAY "Mjesec: "  GET  nMjesec  PICT "99"
   @ box_x_koord() + 2, Col() + 2 SAY "Obracun: "  GET  cObracun WHEN ld_help_broj_obracuna( .T., cObracun ) VALID ld_valid_obracun( .T., cObracun )
   @ box_x_koord() + 3, box_y_koord() + 2 SAY "Godina: "  GET  nGodina  PICT "9999"
   @ box_x_koord() + 4, box_y_koord() + 2 SAY "Prored:"   GET  cProred  PICT "@!"  VALID cProred $ "DN"
   @ box_x_koord() + 5, box_y_koord() + 2 SAY "Prikaz iznosa:" GET cPrikIzn PICT "@!" VALID cPrikizn $ "DN"
   @ box_x_koord() + 6, box_y_koord() + 2 SAY "Primanje (prazno-sve ukupno):" GET cIdTipPr VALID Empty( cIdTipPr ) .OR. P_TipPr( @cIdTipPr )
   @ box_x_koord() + 7, box_y_koord() + 2 SAY "Banka (prazno-sve) :" GET cIdBanka VALID Empty( cIdBanka ) .OR. P_Kred( @cIdBanka )
   // box_x_koord() + 8, box_y_koord() + 2 SAY "Sortirati po(1-sifri,2-prezime+ime)"  GET cVarSort VALID cVarSort $ "12"  PICT "9"
   // mislim da ako sortiranje ne bi bilo po prezimenu filter ne bi funkcionisao ...  ovo je grozno napravljeno (sort + filter) :(

   READ

   clvbox()
   ESC_BCR

   BoxC()

   set_metric( "ld_platni_spisak_sortiranje", my_user(), cVarSort )


   // SELECT ld
   // CREATE_INDEX("LDi1","str(godina)+idrj+str(mjesec)+idradn","LD")
   // CREATE_INDEX("LDi2","str(godina)+str(mjesec)+idradn","LD")

   cObracun := Trim( cObracun )

   IF Empty( cIdRj )
      seek_ld( NIL, nGodina, nMjesec, cObracun )
      cIdRj := ""
      Box(, 2, 30 )
      nSlog := 0
      nUkupno := RECCOUNT2()
      IF cVarSort == "1"
         cSort1 := "ld_radn_idbanka()+ld->IDRADN"
      ELSE
         cSort1 := "ld_radn_idbanka()+SortPrez(ld->IDRADN)"
      ENDIF
      IF Empty( cIdBanka )
         cFilt := "ld_radn_isplata()==" + _filter_quote( cIsplata )
      ELSE
         cFilt := "ld_radn_isplata()==" + _filter_quote( cIsplata ) + ".and.radn->idBanka==" + _filter_quote( cIdBanka )
      ENDIF
      // cFilt := cFilt + IIF( Empty( nMjesec ), ".t.", "MJESEC==" + _filter_quote( nMjesec ) ) + ".and." + IIF( Empty( nGodina ), ".t.", "GODINA==" + _filter_quote( nGodina ) )

      IF ld_vise_obracuna()
         cFilt += ".and. obr=" + _filter_quote( cObracun )
      ENDIF
      INDEX ON &cSort1 TO "tmpld" FOR &cFilt
      BoxC()
      GO TOP
   ELSE

      seek_ld( cIdRj, nGodina, nMjesec, cObracun )
      Box(, 2, 30 )
      nSlog := 0
      nUkupno := RECCOUNT2()
      IF cVarSort == "1"
         cSort1 := "ld_radn_idbanka()+ld->IDRADN"
      ELSE
         cSort1 := "ld_radn_idbanka()+SortPrez(ld->IDRADN)"
      ENDIF
      IF Empty( cIdBanka )
         cFilt := "ld_radn_isplata()==" + _filter_quote( cIsplata )
      ELSE
         cFilt := "ld_radn_isplata()==" + _filter_quote( cIsplata ) + ".and.radn->idBanka==" + _filter_quote( cIdBanka )
      ENDIF
      // cFilt := cFilt + "IDRJ==" + _filter_quote( cIdRj ) + ".and." + IF( Empty( nMjesec ), ".t.", "MJESEC==" + _filter_quote( nMjesec ) ) + ".and." + IF( Empty( nGodina ), ".t.", "GODINA==" + _filter_quote( nGodina ) )
      IF ld_vise_obracuna()
         cFilt += ".and. obr=" + _filter_quote( cObracun )
      ENDIF
      INDEX ON &cSort1 TO "tmpld" FOR &cFilt
      BoxC()
      GO TOP
   ENDIF

   EOF CRET

   nStrana := 0
   m := "----- ------ ----------------------------------- ----------- -------------------------"
   bZagl := {|| ld_zagl_pregled_isplate_za_tekuci_racun( cIsplata ) }

   select_o_ld_rj( ld->idrj )

   SELECT ld

   START PRINT CRET

   DO WHILE !Eof()

      select_o_radn( idradn )
      SELECT LD

      cIdTBanka := radn->idBanka
      nStrana := 0

      Eval( bZagl )

      nT1 := 0
      nT2 := 0
      nT3 := 0
      nT4 := 0
      nRbr := 0

      DO WHILE !Eof() .AND.  nGodina == godina .AND. idrj = cIdRj .AND. nMjesec = mjesec .AND. !( ld_vise_obracuna() .AND. !Empty( cObracun ) .AND. obr <> cObracun ) .AND. radn->idBanka == cIdTBanka

         IF ld_vise_obracuna() .AND. Empty( cObracun )
            ScatterS( godina, mjesec, idrj, idradn )
         ELSE
            Scatter()
         ENDIF

         IF Empty( cIdTipPr )
            nIznosTP := _uiznos
         ELSE
            nIznosTP := _I&cIdTipPr
         ENDIF

         IF nIznosTP = 0
            SKIP
            LOOP
         ENDIF


         ? Str( ++nRbr, 4 ) + ".", idradn, RADNIK_PREZ_IME
         cZaBnkRadnik := FormatSTR( RADNZABNK, 40 )

         nC1 := PCol() + 1
         IF cPrikIzn == "D"
            @ PRow(), PCol() + 1 SAY nIznosTP PICT gpici
            cZaBnkIznos := FormatSTR( AllTrim( Str( nIznosTP ) ), 20 )
         ELSE
            @ PRow(), PCol() + 1 SAY Space( Len( gpici ) )
         ENDIF
         IF cIsplata == "TR"
            @ PRow(), PCol() + 4 SAY PadL( radn->brtekr, 22 )
            cZaBnkTekRN := FormatSTR( AllTrim( radn->brtekr ), 6 )
         ELSE
            @ PRow(), PCol() + 4 SAY PadL( radn->brknjiz, 22 )
         ENDIF
         IF cProred == "D"
            ?
         ENDIF


         nT1 += _usati
         nT2 += _uneto
         nT3 += _uodbici
         nT4 += nIznosTP
         SKIP
      ENDDO

      ? m
      ? Space( 1 ) + _l( "UKUPNO:" )
      IF cPrikIzn == "D"
         @ PRow(), nC1 SAY nT4 PICT gpici
      ENDIF
      ? m

      ? p_potpis()

      FF

   ENDDO


   ENDPRINT

   my_close_all_dbf()

   RETURN .T.


STATIC FUNCTION ld_radn_idbanka()

   select_o_radn( ld->idradn )
   SELECT LD

   RETURN radn->idbanka


STATIC FUNCTION ld_radn_isplata()

   select_o_radn( ld->idradn )
   SELECT LD

   RETURN radn->isplata


FUNCTION ld_zagl_pregled_isplate_za_tekuci_racun( cIsplata )

   ?
   P_12CPI

   select_o_kred( cIdTBanka )
   SELECT ld

   ?
   ? _l( "Poslovna BANKA:" ) + Space( 1 ), cIDTBanka, "-", kred->naz
   ?
   ? Upper( tip_organizacije() ) + ":", self_organizacija_naziv()
   ?

   IF Empty( cidrj )
      ? _l( "Pregled za sve RJ ukupno:" )
   ELSE
      ? _l( "RJ:" ), cIdRj, ld_rj->naz
   ENDIF

   ?? Space( 2 ) + _l( "Mjesec:" ), Str( nMjesec, 2 ) + IspisObr()
   ?? Space( 4 ) + _l( "Godina:" ), Str( nGodina, 5 )
   DevPos( PRow(), 74 )
   ?? _l( "Str." ), Str( ++nStrana, 3 )
   ?
   IF Empty( cIdTipPr )
      ? _l( "PLATNI SPISAK" )
   ELSE
      ? _l( "ISPLATA TIPA PRIMANJA:" ), cIdTipPr, TIPPR->naz
   ENDIF
   ?
   ? m
   ? _l( "Rbr   Sifra           Naziv radnika               " ) + iif( cPrikIzn == "D", _l( "ZA ISPLATU" ), "          " ) + iif( cIsplata == "TR", Space( 9 ) + _l( "Broj T.Rac" ), Space( 8 ) + _l( "Broj St.knj" ) )
   ? m

   RETURN .T.
