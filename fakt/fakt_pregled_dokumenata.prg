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

STATIC s_bFaktDoksPeriod

FUNCTION fakt_pregled_liste_dokumenata()

   LOCAL cF18User :=  f18_user() // "<>"
   LOCAL nCol1 := 0
   LOCAL nUl, nIzl, nRbr
   LOCAL m
   LOCAL cObjekatId
   LOCAL dDatod, dDatdo
   LOCAL hParams := fakt_params()
   LOCAL lVrstePlacanja := hParams[ "fakt_vrste_placanja" ]
   LOCAL lFaktObjekti := hParams[ "fakt_objekti" ]

   // LOCAL _vezni_dokumenti := hParams[ "fakt_dok_veze" ]
   // LOCAL lOpcine := .T.
   LOCAL cValute := Space( 3 )
   LOCAL cFilter := ".t."
   LOCAL cFilterOpcinaReferent
   LOCAL cSamoRobaDN := "N"
   LOCAL bFilter
   LOCAL GetList := {}
   LOCAL cUslovIdPartner, cFilterSifraKupca
   LOCAL cUslovTipDok
   LOCAL cUslovFaktBrDok, cFilterBrFaktDok
   LOCAL cOrderBy, cSort := "D"
   LOCAL cOpcine30, cIdRefer

   PRIVATE cImekup, cIdFirma

   // o_vrstep()
   // o_ops()
   // o_valute()
   // o_rj()
   // o_fakt_objekti()

   // o_fakt_dbf()
   // o_partner()
   // o_fakt_doks_dbf()

   qqVrsteP := Space( 20 )
   dDatVal0 := dDatVal1 := CToD( "" )

   cIdFirma := self_organizacija_id()
   dDatOd := CToD( "" )
   dDatDo := Date()
   cUslovTipDok := ""
   cUslovIdPartner := Space( 20 )
   cTabela := "N"
   cUslovFaktBrDok := Space( 40 )
   cImeKup := Space( 20 )
   cOpcine30 := Space( 30 )
   cIdRefer := SPACE(10)

   IF lFaktObjekti
      cObjekatId := Space( 10 )
   ENDIF

   Box( , 20, 77 )

   cIdFirma := fetch_metric( "fakt_stampa_liste_id_firma", cF18User, cIdFirma )
   cUslovTipDok := fetch_metric( "fakt_stampa_liste_dokumenti", cF18User, cUslovTipDok )
   dDatOd := fetch_metric( "fakt_stampa_liste_datum_od", cF18User, dDatOd )
   dDatDo := fetch_metric( "fakt_stampa_liste_datum_do", cF18User, dDatDo )
   cTabela := fetch_metric( "fakt_stampa_liste_tabelarni_pregled", cF18User, cTabela )
   cImeKup := fetch_metric( "fakt_stampa_liste_ime_kupca", cF18User, cImeKup )
   cUslovIdPartner := fetch_metric( "fakt_stampa_liste_partner", cF18User, cUslovIdPartner )
   cUslovFaktBrDok := fetch_metric( "fakt_stampa_liste_broj_dokumenta", cF18User, cUslovFaktBrDok )

   cImeKup := PadR( cImeKup, 20 )
   cUslovIdPartner := PadR( cUslovIdPartner, 20 )
   cUslovTipDok := PadR( cUslovTipDok, 2 )

   DO WHILE .T.

      // IF gNW $ "DR"
      cIdFirma := PadR( cIdFirma, 2 )

      fakt_getlist_rj_read( box_x_koord() + 1, box_y_koord() + 2, @GetList, @cIdFirma )

      READ
      // ELSE
      // @ box_x_koord() + 1, box_y_koord() + 2 SAY "Firma: " GET cIdFirma valid {|| p_partner( @cIdFirma ), cIdFirma := Left( cIdFirma, 2 ), .T. }
      // ENDIF

      @ box_x_koord() + 2, box_y_koord() + 2 SAY "Tip dokumenta (prazno svi tipovi)" GET cUslovTipDok PICT "@!"
      @ box_x_koord() + 3, box_y_koord() + 2 SAY "Od datuma " GET dDatOd
      @ box_x_koord() + 3, Col() + 1 SAY "do" GET dDatDo
      @ box_x_koord() + 5, box_y_koord() + 2 SAY8 "Ime kupca počinje sa (prazno svi)" GET cImeKup PICT "@!"
      @ box_x_koord() + 6, box_y_koord() + 2 SAY8 "Uslov po šifri kupca (prazno svi)" GET cUslovIdPartner PICT "@!" ;
         VALID {|| valid_sifra_partner( @cUslovIdPartner, @cFilterSifraKupca ) }
      @ box_x_koord() + 7, box_y_koord() + 2 SAY "Broj dokumenta (prazno svi)" GET cUslovFaktBrDok PICT "@!"

      @ box_x_koord() + 9, box_y_koord() + 2 SAY "Tabelarni pregled" GET cTabela VALID cTabela $ "DN" PICT "@!"

      cRTarifa := "N"
      @ box_x_koord() + 11, box_y_koord() + 2 SAY "Rekapitulacija po tarifama ?" GET cRTarifa VALID cRtarifa $ "DN" PICT "@!"

      IF lVrstePlacanja
         @ box_x_koord() + 12, box_y_koord() + 2 SAY "----------------------------------------"
         @ box_x_koord() + 13, box_y_koord() + 2 SAY "Za fakture (Tip dok.10):"
         @ box_x_koord() + 14, box_y_koord() + 2 SAY8 "Način placanja:" GET qqVrsteP
         @ box_x_koord() + 15, box_y_koord() + 2 SAY8 "Datum valutiranja od" GET dDatVal0
         @ box_x_koord() + 15, Col() + 2 SAY "do" GET dDatVal1
         @ box_x_koord() + 16, box_y_koord() + 2 SAY "----------------------------------------"
      ENDIF

      @ box_x_koord() + 17, box_y_koord() + 2 SAY8 "Općina (prazno-sve): "  GET cOpcine30
      @ box_x_koord() + 17, COL() + 2 SAY8 "Referent: "  GET cIdRefer PICT "@!" VALID Empty(cIdRefer) .OR. P_Refer(@cIdRefer)

      IF lFaktObjekti
         @ box_x_koord() + 18, box_y_koord() + 2 SAY "Objekat (prazno-svi): "  GET cObjekatId VALID Empty( cObjekatId ) .OR. p_fakt_objekti( @cObjekatId )
      ENDIF

      @ box_x_koord() + 19, box_y_koord() + 2 SAY "Valute ( /KM/EUR)"  GET cValute
      @ box_x_koord() + 19, Col() + 2 SAY8 " samo dokumenti koji sadrže robu D/N"  GET cSamoRobaDN PICT "@!" VALID cSamoRobaDN $ "DN"

      @ box_x_koord() + 20, box_y_koord() + 2 SAY8 "Sort (D)atdok/(B)rdok"  GET cSort PICT "@!" VALID cSort $ "DB"

      READ

      ESC_BCR

      cFilterBrFaktDok := Parsiraj( cUslovFaktBrDok, "BRDOK", "C" )
      cFilterSifraKupca := Parsiraj( cUslovIdPartner, "IDPARTNER", "C" )
      aUslVrsteP := Parsiraj( qqVrsteP, "IDVRSTEP", "C" )
      cFilterOpcinaReferent := Parsiraj( cOpcine30, "flt_fakt_partner('id')", "C" )
      IF !Empty(cIdRefer)
        cFilterOpcinaReferent += ".and. flt_fakt_partner('idrefer')==" + sql_quote(cIdRefer)
      ENDIF
      altd()

      IF cFilterBrFaktDok <> NIL .AND. cFilterSifraKupca <> NIL .AND. ( !lVrstePlacanja .OR. aUslVrsteP <> NIL )
         EXIT // nema greske u filter uslovima
      ENDIF

   ENDDO

   cUslovTipDok := Trim( cUslovTipDok )
   cUslovIdPartner := Trim( cUslovIdPartner )

   set_metric( "fakt_stampa_liste_id_firma", f18_user(), cIdFirma )
   set_metric( "fakt_stampa_liste_dokumenti", f18_user(), cUslovTipDok )
   set_metric( "fakt_stampa_liste_datum_od", f18_user(), dDatOd )
   set_metric( "fakt_stampa_liste_datum_do", f18_user(), dDatDo )
   set_metric( "fakt_stampa_liste_tabelarni_pregled", f18_user(), cTabela )
   set_metric( "fakt_stampa_liste_ime_kupca", f18_user(), cImeKup )
   set_metric( "fakt_stampa_liste_partner", f18_user(), cUslovIdPartner )
   set_metric( "fakt_stampa_liste_broj_dokumenta", f18_user(), cUslovFaktBrDok )

   BoxC()

   // SELECT partn
   // radi filtera cFilterOpcinaReferent partneri trebaju biti na ID-u indeksirani
   // SET ORDER TO TAG "ID"

   // SET ORDER TO TAG "1"
   // GO TOP

   IF !Empty( dDatVal0 ) .OR. !Empty( dDatVal1 )
      cFilter += ".and. ( !idtipdok='10' .or. datpl>=" + _filter_quote( dDatVal0 ) + ".and. datpl<=" + _filter_quote( dDatVal1 ) + ")"
   ENDIF

   IF !Empty( qqVrsteP )
      cFilter += ".and. (!idtipdok='10' .or. " + aUslVrsteP + ")"
   ENDIF

   IF !Empty( cUslovTipDok )
      cFilter += ".and. idtipdok==" + _filter_quote( cUslovTipDok )
   ENDIF

   IF !Empty( dDatOd ) .OR. !Empty( dDatDo )
      cFilter += ".and. datdok>=" + _filter_quote( dDatOd ) + ".and. datdok<=" + _filter_quote( dDatDo )
   ENDIF

   IF !Empty( cImekup )
      cFilter += ".and. partner=" + _filter_quote( Trim( cImeKup ) )
   ENDIF

   IF !Empty( cIdFirma )
      cFilter += ".and. IdFirma=" + _filter_quote( cIdFirma )
   ENDIF

   IF !Empty( cOpcine30 ) .OR. !Empty( cIdRefer )
      cFilter += ".and. " + cFilterOpcinaReferent
   ENDIF

   IF lFaktObjekti .AND. !Empty( cObjekatId )
      cFilter += ".and. faktcObjekatId()==" + _filter_quote( cObjekatId )
   ENDIF

   IF !Empty( cUslovFaktBrDok )
      cFilter += ".and." + cFilterBrFaktDok
   ENDIF

   IF !Empty( cUslovIdPartner )
      cFilter += ".and." + cFilterSifraKupca
   ENDIF

   IF !Empty( cValute )
      cFilter += ".and. dindem = " + _filter_quote( cValute )
   ENDIF

   IF cSamoRobaDN == "D"
      cFilter += ".and. fakt_dokument_sadrzi_robu()"
   ENDIF

   IF cFilter == ".t. .and."
      cFilter := SubStr( cFilter, 9 )
   ENDIF

   // IF cFilter == ".t."
   // SET FILTER TO
   // ELSE
   // SET FILTER TO &cFilter
   // ENDIF
   bFilter := {|| &cFilter }

   IF cSort == "D"
      cOrderBy := "idfirma,datdok,idtipdok,brdok"
   ELSE
      cOrderBy := "idfirma,idtipdok,brdok,datdok"
   ENDIF

   s_bFaktDoksPeriod := {|| find_fakt_doks_za_period( cIdFirma, dDatOd, dDatDo, "FAKT_DOKS_PREGLED", cOrderBy ),  dbSetFilter( bFilter, cFilter ), dbGoTop() }

   Eval( s_bFaktDoksPeriod )
   @ f18_max_rows() - 4, f18_max_cols() - 3 SAY Str( rloptlevel(), 2 )

   cUslovTipDok := Trim( cUslovTipDok )


   EOF CRET

   IF cTabela == "D"
      fakt_lista_dokumenata_tabelarni_pregled( lVrstePlacanja )
   ELSE
      gaZagFix := { 3, 3 }
      fakt_stampa_liste_dokumenata( dDatOd, dDatDo, cUslovTipDok, cIdFirma, cObjekatId, cImeKup, cFilterOpcinaReferent, cValute )
   ENDIF

   my_close_all_dbf()

   RETURN .T.


/*
FUNCTION print_porezna_faktura( lOpcine )

   LOCAL cIdFirma, cIdTipDok, cBrDok

   SELECT fakt_doks
   //nTrec := RecNo()

   cIdFirma := idfirma
   cIdTipDok := idtipdok
   cBrDok := brdok

   close_open_fakt_tabele()

   fakt_stamp_txt_dokumenta( cIdFirma, cIdTipdok, cBrdok )

   SELECT ( F_FAKT_DOKS )
   USE

   //o_fakt_doks_dbf()

   RETURN DE_CONT
*/

FUNCTION fakt_print_odt( lOpcine )

   LOCAL cIdFirma := fakt_doks_pregled->idfirma
   LOCAL cIdTipDok := fakt_doks_pregled->idtipdok
   LOCAL cBrDok := fakt_doks_pregled->brdok

   // LOCAL nTrec := RecNo()

   // my_close_all_dbf()

   fakt_stampa_dok_odt( cIdFirma, cIdTipDok, cBrDok )

/*
   close_open_fakt_tabele()
   SELECT ( F_FAKT_DOKS )
   USE
   //o_fakt_doks_dbf()
   //o_partner()
   SELECT fakt_doks
   IF cFilter == ".t."
      SET FILTER TO
   ELSE
      SET FILTER TO &cFilter
   ENDIF
   GO nTrec
*/

   RETURN DE_CONT



FUNCTION fakt_generisi_fakturu_10_iz_20( cIdFirma, cIdTipDok, cBrDok )

   LOCAL nCnt := 0
   LOCAL dDatFakt
   LOCAL dDatVal
   LOCAL dDatIsp
   LOCAL i
   LOCAL cPart
   LOCAL aMemo := {}
   LOCAL hRec
   LOCAL cNBrFakt
   LOCAL GetList := {}

   IF Pitanje(, "Generisati fakturu na osnovu ponude ?", "D" ) == "N"
      RETURN DE_CONT
   ENDIF

   o_fakt_pripr()

   IF fakt_pripr->( RecCount() ) <> 0
      MsgBeep( "Priprema mora biti prazna !" )
      RETURN DE_CONT
   ENDIF


   dDatFakt := Date()
   dDatVal := Date()
   dDatIsp := Date()
   cNBrFakt := PadR( "00000", 8 )

   Box(, 5, 55 )

   @ box_x_koord() + 1, box_y_koord() + 2 SAY "*** Parametri fakture "

   @ box_x_koord() + 3, box_y_koord() + 2 SAY "  Datum fakture: " GET dDatFakt VALID !Empty( dDatFakt )
   @ box_x_koord() + 4, box_y_koord() + 2 SAY "   Datum valute: " GET dDatVal VALID !Empty( dDatVal )
   @ box_x_koord() + 5, box_y_koord() + 2 SAY " Datum isporuke: " GET dDatIsp VALID !Empty( dDatIsp )

   READ

   BoxC()

   seek_fakt( cIdFirma, cIdTipDok, cBrDok )

   DO WHILE !Eof() .AND. field->idfirma + field->idtipdok + field->brdok == cIdFirma + cIdTipDok + cBrDok

      ++nCnt

      hRec := dbf_get_rec()
      aMemo := fakt_ftxt_decode( hRec[ "txt" ] )

      hRec[ "idtipdok" ] := "10"
      hRec[ "brdok" ] := cNBrFakt
      hRec[ "datdok" ] := dDatFakt

      IF nCnt == 1

         hRec[ "txt" ] := ""
         hRec[ "txt" ] += Chr( 16 ) + aMemo[ 1 ] + Chr( 17 )
         hRec[ "txt" ] += Chr( 16 ) + aMemo[ 2 ] + Chr( 17 )
         hRec[ "txt" ] += Chr( 16 ) + aMemo[ 3 ] + Chr( 17 )
         hRec[ "txt" ] += Chr( 16 ) + aMemo[ 4 ] + Chr( 17 )
         hRec[ "txt" ] += Chr( 16 ) + aMemo[ 5 ] + Chr( 17 )
         hRec[ "txt" ] += Chr( 16 ) + aMemo[ 6 ] + Chr( 17 )
         // datum otpremnice
         hRec[ "txt" ] += Chr( 16 ) + DToC( dDatIsp ) + Chr( 17 )
         hRec[ "txt" ] += Chr( 16 ) + aMemo[ 8 ] + Chr( 17 )
         // datum narudzbe / amemo[9]
         hRec[ "txt" ] += Chr( 16 ) + DToC( dDatVal ) + Chr( 17 )
         // datum valute / amemo[10]
         hRec[ "txt" ] += Chr( 16 ) + DToC( dDatVal ) + Chr( 17 )

         IF Len( aMemo ) > 10
            FOR i := 11 TO Len( aMemo )
               hRec[ "txt" ] += Chr( 16 ) + aMemo[ i ] + Chr( 17 )
            NEXT
         ENDIF

      ENDIF

      SELECT fakt_pripr
      APPEND BLANK
      dbf_update_rec( hRec )

      SELECT fakt
      SKIP

   ENDDO

   IF nCnt > 0
      MsgBeep( "Dokument formiran i nalazi se u pripremi. Obradite ga !" )
   ENDIF

   IF isugovori()

      IF pitanje(, "Setovati datum uplate za partnera ?", "N" ) == "D"

         IF o_ugov_partner( cPart )
            // SELECT ugov
            // SET ORDER TO TAG "PARTNER"
            // GO TOP
            // SEEK cPart // ugov

            // IF Found() .AND. field->idpartner == cPart
            hRec := dbf_get_rec()
            hRec[ "dat_l_fakt" ] := Date()
            update_rec_server_and_dbf( "fakt_ugov", hRec, 1, "FULL" )
         ENDIF

      ENDIF

   ENDIF

   RETURN DE_REFRESH




/*
   Filter fakt_doks->idpartner->idops

   pretpostavlja:
   1) da je glavna tabela FAKT_DOKS
   2) da je tabela PARTN na ID indeksu
*/
FUNCTION flt_fakt_partner(cField)

   LOCAL cRet

   select_o_partner( fakt_doks_pregled->idpartner )

   IF cRet == "idops"
      cRet := partn->idops
   ELSE
      cRet := partn->idrefer
   ENDIF
   SELECT fakt_doks_pregled

   RETURN cRet


FUNCTION fakt_dokument_sadrzi_robu()

   LOCAL lRet := .F., cQuery

   cQuery := "SELECT count(fakt_fakt.idroba) AS CNT FROM fmk.fakt_fakt"
   cQuery += " LEFT JOIN " + f18_sql_schema( "roba") + " ON fakt_fakt.idroba = roba.id"
   cQuery += " WHERE roba.tip <> 'U'"
   cQuery += " AND fmk.fakt_fakt.idfirma=" + sql_quote( fakt_doks_pregled->idfirma )
   cQuery += " AND fmk.fakt_fakt.idtipdok=" + sql_quote( fakt_doks_pregled->idtipdok )
   cQuery += " AND fmk.fakt_fakt.brdok=" + sql_quote( fakt_doks_pregled->brdok )

   SELECT F_FAKT
   use_sql( "fakt_cnt", cQuery )

   IF field->CNT > 0
      lRet := .T. // ima robe unutar fakture
   ENDIF
   USE
   SELECT fakt_doks_pregled

   RETURN lRet



FUNCTION fakt_pregled_reload_tables()

   LOCAL nRec

   IF Select( "FAKT_DOKS_PREGLED" ) > 0
      SELECT FAKT_DOKS_PREGLED
      nRec := RecNo()
   ENDIF

   my_close_all_dbf()
   Eval( s_bFaktDoksPeriod )

   ?E Time(), "fakt_pregled_reload_tables"
   // SET FILTER TO &( cFilter )
   // GO TOP

   IF nRec != NIL
      GO nRec
   ENDIF

   RETURN .T.



STATIC FUNCTION valid_sifra_partner( cUslovIdPartner, cFilterSifraKupca )

   LOCAL cPom
   LOCAL nPartnera

   nPartnera := NumToken( cUslovIdPartner, ";" )

   IF nPartnera == 1 // "BRING    " -> 1, "BRING;  " -> 2
      cPom := Token( cUslovIdPartner, ";", 1 )
      P_partner( @cPom )
      cUslovIdPartner := PadR( cPom + ";", 20 )
   ENDIF

   cFilterSifraKupca := Parsiraj( cUslovIdPartner, "IDPARTNER", "C", NIL, F_PARTN )

   RETURN .T.
