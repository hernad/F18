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

MEMVAR GetList

STATIC s_nFiskalniUredjajId := 0
STATIC s_hFiskalniParams
STATIC s_lFiskalniSilentPrint := .F.
STATIC s_cFiskalniEmailTo := NIL
STATIC s_lFiskalniPartnerIno
STATIC s_lFiskalniPartnerPDV
STATIC cFiskalniVrstaPlacanja
STATIC s_lFiskalniPrikaziPartnera
STATIC s_cFiskalniDrajverTremol := "TREMOL"
STATIC s_cFiskalniDrajverFPRINT := "FPRINT"
STATIC s_cFiskalniDrajverFLINK := "FLINK"
STATIC s_cFiskalniDrajverHCP := "HCP"
STATIC s_cFiskalniDrajverTRING := "TRING"
STATIC s_cFiskalniUredjaj


FUNCTION param_racun_na_email( cEmailTo )

   IF cEmailTo != NIL
      s_cFiskalniEmailTo := fetch_metric( "fakt_dokument_na_email", my_user(), "" )
   ENDIF

   RETURN s_cFiskalniEmailTo



FUNCTION fakt_fiskalni_racun( cIdFirma, cIdTipDok, cBrDok, lAutoPrint, hDeviceParams )

   LOCAL nErrorLevel := 0
   LOCAL cFiskalniDrajver
   LOCAL nStorno := 0
   LOCAL aRacunStavkeData, aPartnerData
   LOCAL _cont := "1"
   LOCAL lRacunBezgBezPartnera

   IF !fiscal_opt_active()
      RETURN nErrorLevel
   ENDIF

   IF ( lAutoPrint == NIL )
      lAutoPrint := .F.
   ENDIF

   IF lAutoPrint
      s_lFiskalniSilentPrint := .T.
   ENDIF

   IF hDeviceParams == NIL
      RETURN nErrorLevel
   ENDIF

   s_hFiskalniParams := hDeviceParams
   cFiskalniDrajver := AllTrim( hDeviceParams[ "drv" ] )
   lRacunBezgBezPartnera := ( hDeviceParams[ "vp_no_customer" ] == "D" )

   s_cFiskalniUredjaj := cFiskalniDrajver

   IF postoji_fiskalni_racun( cIdFirma, cIdTipDok, cBrDok, cFiskalniDrajver )
      MsgBeep( "Za dokument " + cIdFirma + "-" + cIdTipDok + "-" + AllTrim( cBrDok ) + " već postoji izdan fiskalni račun !" )
      RETURN nErrorLevel
   ENDIF

   nStorno := fakt_is_storno_dok( cIdFirma, cIdTipDok, cBrDok )
   IF  nStorno == -1 // error
      RETURN nErrorLevel
   ENDIF

   IF nStorno == 1
      IF !fakt_reklamirani_racun_preduslovi( cIdFirma, cIdTipDok, cBrDok, hDeviceParams )
         PopWa()
         PopwA()
         RETURN nErrorLevel
      ENDIF
   ENDIF

   aPartnerData := fakt_fiscal_podaci_partnera( cIdFirma, cIdTipDok, cBrDok, ( nStorno == 1 ), lRacunBezgBezPartnera )
   IF ValType( aPartnerData ) == "L"
      RETURN 1
   ENDIF

   aRacunStavkeData := fakt_gen_array_racun_stavke_from_fakt_dokument( cIdFirma, cIdTipDok, cBrDok, ( nStorno == 1 ), aPartnerData )

   IF ValType( aRacunStavkeData ) == "L"  .OR. aRacunStavkeData == NIL
      RETURN 1
   ENDIF

   DO CASE

   CASE cFiskalniDrajver == "TEST"
      nErrorLevel := 0

   CASE cFiskalniDrajver == s_cFiskalniDrajverFPRINT
      nErrorLevel := fakt_to_fprint( cIdFirma, cIdTipDok, cBrDok, aRacunStavkeData, aPartnerData, ( nStorno == 1 ) )

   CASE cFiskalniDrajver == s_cFiskalniDrajverTremol

      nErrorLevel := fakt_to_tremol( cIdFirma, cIdTipDok, cBrDok, aRacunStavkeData, aPartnerData, ( nStorno == 1 ) )

   CASE cFiskalniDrajver == s_cFiskalniDrajverHCP
      nErrorLevel := fakt_fisk_fiskalni_isjecak_hcp( cIdFirma, cIdTipDok, cBrDok, aRacunStavkeData, aPartnerData, ( nStorno == 1 ) )

   CASE cFiskalniDrajver == s_cFiskalniDrajverFLINK
      nErrorLevel := fakt_to_flink( s_hFiskalniParams, cIdFirma, cIdTipDok, cBrDok, aRacunStavkeData, aPartnerData, ( nStorno == 1 ) )

   CASE cFiskalniDrajver == s_cFiskalniDrajverTRING
      nErrorLevel := fakt_to_tring( cIdFirma, cIdTipDok, cBrDok, aRacunStavkeData, aPartnerData, ( nStorno == 1 ) )

   ENDCASE

   DirChange( my_home() )

   log_write_file( "FISK_RN: " + cFiskalniDrajver + " za dokument: " + ;
      AllTrim( cIdFirma ) + "-" + AllTrim( cIdTipDok ) + "-" + AllTrim( cBrDok ) + ;
      " err level: " + AllTrim( Str( nErrorLevel ) ) + ;
      " partner: " + iif( aPartnerData <> NIL, AllTrim( aPartnerData[ 1, 1 ] ) + ;
      " - " + AllTrim( aPartnerData[ 1, 2 ] ), "NIL" ), 2 )

   IF nErrorLevel > 0
      log_write_file( "FISK_RN_ERROR:" + AllTrim( Str( nErrorLevel ) ) )
      MsgBeep( "Problem sa štampanjem na fiskalni uređaj !" )
   ENDIF

   RETURN nErrorLevel


FUNCTION fakt_reklamirani_racun_box( nBrReklamiraniRacun )

   Box(, 1, 60 )
   @ box_x_koord() + 1, box_y_koord() + 2 SAY8 "Reklamiramo fiskalni račun broj:" ;
      GET nBrReklamiraniRacun PICT "999999999" VALID ( nBrReklamiraniRacun > 0 )
   READ
   BoxC()

   IF LastKey() == K_ESC .AND. nBrReklamiraniRacun == 0
      nBrReklamiraniRacun := -1
   ENDIF

   RETURN nBrReklamiraniRacun



STATIC FUNCTION idpartner_sa_fakt_dokumenta( cIdFirma, cIdTipDok, cBrDok )

   seek_fakt_doks( cIdFirma, cIdTipDok, cBrDok )

   cIdPartner := fakt_doks->idpartner

   RETURN cIdPartner



STATIC FUNCTION fakt_izracunaj_ukupnu_vrijednost_racuna( cIdFirma, cIdTipDok, cBrDok )

   LOCAL nUkupno := 0
   LOCAL aIznosi, _data_total
   LOCAL cIdPartner := ""

   select_o_roba()

   SELECT ( F_TARIFA )
   IF !Used()
      o_tarifa()
   ENDIF

   cIdPartner := idpartner_sa_fakt_dokumenta( cIdFirma, cIdTipDok, cBrDok )
   aIznosi := fakt_get_iznos_za_dokument( cIdFirma, cIdTipDok, cBrDok )
   _data_total := fakt_izracunaj_total( aIznosi, cIdPartner, cIdTipDok )

   nUkupno := _data_total[ "ukupno" ]

   RETURN nUkupno



STATIC FUNCTION fakt_reklamirani_racun_preduslovi( cIdFirma, cIdTipDok, cBrDok, hFiskalniDevParams, lForsirano )

   LOCAL lRet := .T.
   LOCAL nDepozit := 0
   LOCAL nErr := 0
   LOCAL aIznosi, _data_total

   // #34537
   IF AllTrim( hFiskalniDevParams[ "drv" ] ) <> "FPRINT"
      RETURN lRet
   ENDIF

   IF lForsirano == NIL
      lForsirano := .F.
   ENDIF

   IF !lForsirano
      MsgBeep( "Želite izdati reklamirani račun.#Prije toga je neophodno da postoji minimalan depozit u uređaju." )
   ENDIF

   IF !lForsirano .AND. Pitanje(, "Da li je potrebno napraviti unos depozita (D/N) ?", " " ) == "N"
      RETURN lRet
   ENDIF

   nDepozit := Abs( fakt_izracunaj_ukupnu_vrijednost_racuna( cIdFirma, cIdTipDok, cBrDok ) )
   nDepozit := Round( nDepozit + 1, 0 )

   fprint_delete_answer( hFiskalniDevParams )
   fprint_unos_pologa( hFiskalniDevParams, nDepozit, .T. )
   nErr := fprint_read_error( hFiskalniDevParams, 0 )

   IF nErr <> 0
      lRet := .F.
      MsgBeep( "Neuspješan unosa depozita u uređaj !" )
      RETURN lRet
   ENDIF

   RETURN lRet




/*

 Opis: ispituje da li je za dokument napravljen fiskalni račun

 Usage: postoji_fiskalni_racun( cIdFirma, idtipdok, cBrDok, cFiskalniModel ) -> SQL upit se šalje prema serveru

   Parameters:
     - cIdFirma
     - idtipdok
     - cBrDok
     - cFiskalniModel - cFiskalniModel uređaja, proslijeđuje se rezultat funkcije fiskalni_uredjaj_model()

   Retrun:
    .T. ako postoji fiskalni račun, .F. ako ne

*/

FUNCTION postoji_fiskalni_racun( cIdFirma, cIdTipDok, cBrDok, cFiskalniModel )

   LOCAL lRet := .F.
   LOCAL cWhere

   IF cFiskalniModel == NIL
      cFiskalniModel := fiskalni_uredjaj_model()
   ENDIF

   cWhere := " idfirma = " + sql_quote( cIdFirma )
   cWhere += " AND idtipdok = " + sql_quote( cIdTipDok )
   cWhere += " AND brdok = " + sql_quote( cBrDok )

   IF AllTrim( cFiskalniModel ) $ "FPRINT#HCP"
      cWhere += " AND ( ( iznos > 0 AND fisc_rn > 0 ) "
      cWhere += "  OR ( iznos < 0 AND fisc_st > 0 ) ) "
   ELSE
      cWhere += " AND ( iznos > 0 AND fisc_rn > 0 ) "
   ENDIF

   IF table_count( f18_sql_schema( "fakt_doks" ), cWhere ) > 0
      lRet := .T.
   ENDIF

   RETURN lRet


STATIC FUNCTION fakt_is_storno_dok( cIdFirma, cIdTipDok, cBrDok )

   LOCAL nStorno := 0 // 0 - nije storno, 1 - storno, -1 = error
   LOCAL nTrec

   IF !seek_fakt( cIdFirma, cIdTipDok, cBrDok )
      MsgBeep( "NE Može se locirati dokument: " + cIdFirma + "-" + cIdTipDok + "-" + AllTrim( cBrDok ) + "  (is storno) ?!"  )
      RETURN -1
   ENDIF

   nTrec := RecNo()
   DO WHILE !Eof() .AND. field->idfirma == cIdFirma .AND. field->idtipdok == cIdTipDok .AND. field->brdok == cBrDok

      IF field->kolicina < 0
         nStorno := 1
         EXIT
      ENDIF
      SKIP

   ENDDO

   GO ( nTrec )

   RETURN nStorno



STATIC FUNCTION fakt_fiscal_o_tables()

   // o_tarifa()
   // o_fakt_doks_dbf()
   // o_fakt_dbf()
   // o_roba()
   // o_sifk()
   // o_sifv()

   RETURN .T.



// ----------------------------------------------------------
// kalkulise iznose na osnovu datih parametara
// [ "PDV17", 10.55 ]
// [ "PDV17", 3.22 ]
// => sve sabere, zaokruzi FIKSNO na 2 DECIMALE pa da hash[
//     "ukupno"
//     "osnovica"
//     "pdv"
// ]

// ----------------------------------------------------------
STATIC FUNCTION fakt_izracunaj_total( aTarifaIznos, cIdPartner, cIdTipDok )

   LOCAL hTotal := hb_Hash()
   LOCAL cIdTarifa, nI, nIznos
   LOCAL nDbfArea := Select()

   hTotal[ "ukupno" ] := 0
   hTotal[ "pdv" ] := 0
   hTotal[ "osnovica" ] := 0

   FOR nI := 1 TO Len( aTarifaIznos )

      cIdTarifa := PadR( aTarifaIznos[ nI, 1 ], 6 )
      nIznos := aTarifaIznos[ nI, 2 ]

      select_o_tarifa( cIdTarifa )

      IF cIdTipDok $ "11#13#23"
         IF !partner_is_ino( cIdPartner ) .AND. !is_part_pdv_oslob_po_clanu( cIdPartner ) .AND. tarifa->pdv > 0
            hTotal[ "ukupno" ] := hTotal[ "ukupno" ] + nIznos
            hTotal[ "osnovica" ] := hTotal[ "osnovica" ] + ( nIznos / ( 1 + tarifa->pdv / 100 ) )
            hTotal[ "pdv" ] := hTotal[ "pdv" ] + ( ( nIznos / ( 1 + tarifa->pdv / 100 ) ) * ( tarifa->pdv / 100 ) )
         ELSE
            hTotal[ "ukupno" ] := hTotal[ "ukupno" ] + nIznos
            hTotal[ "osnovica" ] := hTotal[ "osnovica" ] + nIznos
         ENDIF
      ELSE
         IF !partner_is_ino( cIdPartner ) .AND. !is_part_pdv_oslob_po_clanu( cIdPartner ) .AND. tarifa->pdv > 0
            hTotal[ "ukupno" ] := hTotal[ "ukupno" ] + ( nIznos * ( 1 + tarifa->pdv / 100 ) )
            hTotal[ "osnovica" ] := hTotal[ "osnovica" ] + nIznos
            hTotal[ "pdv" ] := hTotal[ "pdv" ] + ( nIznos * ( tarifa->pdv / 100 ) )
         ELSE
            hTotal[ "ukupno" ] := hTotal[ "ukupno" ] + nIznos
            hTotal[ "osnovica" ] := hTotal[ "osnovica" ] + nIznos
         ENDIF
      ENDIF
   NEXT


   hTotal[ "ukupno" ] := Round( hTotal[ "ukupno" ], 2 ) // svesti na dvije decimale
   hTotal[ "osnovica" ] := Round( hTotal[ "osnovica" ], 2 )
   hTotal[ "pdv" ] := Round( hTotal[ "pdv" ], 2 )

   SELECT ( nDbfArea )

   RETURN hTotal




STATIC FUNCTION fakt_get_iznos_za_dokument( cIdFirma, cIdTipDok, cBrDok )

   LOCAL aFakturaIznos := {}
   LOCAL cIdTarifa, cIdRoba, nPos
   LOCAL nKolicina, nRabat, nCijena, nIznos

   seek_fakt( cIdFirma, cIdTipDok, cBrDok )
   DO WHILE !Eof() .AND. field->idfirma == cIdFirma .AND. field->idtipdok == cIdTipDok .AND. field->brdok == cBrDok

      cIdRoba := field->idroba
      nCijena := field->cijena
      nKolicina := field->kolicina
      nRabat := field->rabat

      select_o_roba( cIdRoba )
      select_o_tarifa( roba->idtarifa )

      cIdTarifa := tarifa->id

      SELECT fakt

      IF field->dindem == Left( ValBazna(), 3 )
         nIznos := Round( nKolicina * nCijena * fakt_preracun_cijene() * ( 1 - nRabat / 100 ), fakt_zaokruzenje() )
      ELSE
         nIznos := Round( nKolicina * nCijena * fakt_preracun_cijene() * ( 1 - nRabat / 100 ), fakt_zaokruzenje() )
      ENDIF

      IF RobaZastCijena( cIdTarifa )
         cIdTarifa := PadR( "PDV17", 6 )
      ENDIF

      nPos := AScan( aFakturaIznos, {| VAR | VAR[ 1 ] == cIdTarifa } )

      IF nPos == 0
         AAdd( aFakturaIznos, { PadR( cIdTarifa, 6 ), nIznos } )
      ELSE
         aFakturaIznos[ nPos, 2 ] := aFakturaIznos[ nPos, 2 ] + nIznos
      ENDIF

      SKIP

   ENDDO

   RETURN aFakturaIznos



STATIC FUNCTION fakt_gen_array_racun_stavke_from_fakt_dokument( cIdFirma, cIdTipDok, cBrDok, lStorno, aPartner )

   LOCAL aRacunData := {}
   LOCAL _n_rn_broj, _rn_iznos, _rn_rabat, _rn_datum, cFiskalniReklamiraniRnBroj
   LOCAL _vrsta_pl, cIdPartner, nTotalRacuna, nRacunFaktTotal
   LOCAL _art_id, nRobaFiscPLU, cNazivArtikla, cRobaJmj, cVrstaPlacanja
   LOCAL cArtikalBarkod, _rn_rbr, aMemo
   LOCAL lPopustNaTeretProdavca := .F.
   LOCAL lInoPartner := .F.
   LOCAL _partn_pdv := .T.
   LOCAL _a_iznosi := {}
   LOCAL hDataItem, _data_total, aArray, nStornoIdentifikator, cRacunBroj
   LOCAL cMemoOpis, nCijena, cIdTarifa, cStornoRacunOpis,  _vr_plac, nKolicina
   LOCAL nI, nItemLevelCheck

   // 0 - gotovina
   // 3 - ziralno / virman

   cVrstaPlacanja := "0"

   IF aPartner <> NIL
      cVrstaPlacanja := aPartner[ 1, 6 ]
      lInoPartner := aPartner[ 1, 7 ]
      _partn_pdv := aPartner[ 1, 8 ]
   ELSE
      cVrstaPlacanja := cFiskalniVrstaPlacanja
      lInoPartner := s_lFiskalniPartnerIno
      _partn_pdv := s_lFiskalniPartnerPDV
   ENDIF

   IF lStorno == NIL
      lStorno := .F.
   ENDIF

   fakt_fiscal_o_tables()

   seek_fakt_doks( cIdFirma, cIdTipDok, cBrDok )

   _n_rn_broj := Val( AllTrim( field->brdok ) )
   cFiskalniReklamiraniRnBroj := field->fisc_rn

   _rn_iznos := field->iznos
   _rn_rabat := field->rabat
   _rn_datum := field->datdok
   cIdPartner := field->idpartner

   _a_iznosi := fakt_get_iznos_za_dokument( cIdFirma, cIdTipDok, cBrDok )
   _data_total := fakt_izracunaj_total( _a_iznosi, cIdPartner, cIdTipDok )

   IF !seek_fakt( cIdFirma, cIdTipDok, cBrDok )
      MsgBeep( "Račun ne posjeduje niti jednu stavku#Štampanje onemogućeno !" )
      RETURN NIL
   ENDIF

   IF lStorno
      cFiskalniReklamiraniRnBroj := fakt_reklamirani_racun_box( cFiskalniReklamiraniRnBroj )
   ENDIF

   IF cFiskalniReklamiraniRnBroj == -1
      MsgBeep( "Broj veze računa mora biti setovan" )
      RETURN NIL
   ENDIF

   // i total sracunaj sa pdv
   // upisat cemo ga u svaku stavku matrice
   // to je total koji je bitan kod regularnih racuna
   // pdv, ne pdv obveznici itd...
   // nTotalRacuna := _uk_sa_pdv( cIdTipDok, cIdPartner, _rn_iznos )

   nTotalRacuna := _data_total[ "ukupno" ]
   nRacunFaktTotal := 0

   DO WHILE !Eof() .AND. field->idfirma == cIdFirma .AND. field->idtipdok == cIdTipDok .AND. field->brdok == cBrDok

      select_o_roba( fakt->idroba )

      SELECT fakt

      nStornoIdentifikator := 0

      IF ( field->kolicina < 0 ) .AND. !lStorno
         nStornoIdentifikator := 1
      ENDIF

      cRacunBroj := fakt->brdok
      _rn_rbr := fakt->rbr

      aMemo := fakt_ftxt_decode( fakt->txt )

      _art_id := fakt->idroba
      cArtikalBarkod := AllTrim( roba->barkod )

      IF roba->tip == "U" .AND. Empty( AllTrim( roba->naz ) )

         cMemoOpis := AllTrim( aMemo[ 1 ] )

         IF Empty( cMemoOpis )
            cMemoOpis := "artikal bez naziva"
         ENDIF

         cNazivArtikla := AllTrim( fiscal_art_naz_fix( cMemoOpis, s_hFiskalniParams[ "drv" ] ) )
      ELSE
         cNazivArtikla := AllTrim( fiscal_art_naz_fix( roba->naz, s_hFiskalniParams[ "drv" ] ) )
      ENDIF

      cRobaJmj := AllTrim( roba->jmj )
      nRobaFiscPLU := roba->fisc_plu

      IF s_hFiskalniParams[ "plu_type" ] == "D" .AND.  ;
            ( s_hFiskalniParams[ "vp_sum" ] <> 1 .OR. cIdTipDok $ "11" .OR. Len( _a_iznosi ) > 1 )

         nRobaFiscPLU := auto_plu( NIL, NIL,  s_hFiskalniParams )

         IF s_cFiskalniUredjaj == "FPRINT" .AND. nRobaFiscPLU == 0
            MsgBeep( "PLU artikla = 0, to nije moguce !" )
            RETURN NIL
         ENDIF

      ENDIF

      //nCijena := roba->mpc
      cIdTarifa := AllTrim( roba->idtarifa )

      
      IF field->dindem != Left( ValBazna(), 3 )
           /////////// FIX BUG zaokr na 2 DEC /////////////////
           nCijena :=  field->cijena
      ELSE
          aArray := {}
          AAdd( aArray, { cIdTarifa, field->cijena } )
          hDataItem := fakt_izracunaj_total( aArray, cIdPartner, cIdTipDok )
          nCijena := hDataItem[ "ukupno" ]
      ENDIF    
      nCijena := field->cijena

      IF cIdTipDok == "10"
         _vr_plac := "3"
      ENDIF

      nKolicina := Abs( field->kolicina )

      IF !lInoPartner .AND. !_partn_pdv .AND. RobaZastCijena( roba->idtarifa )
         lPopustNaTeretProdavca := .T.
         _rn_rabat := 0
      ELSE
         _rn_rabat := Abs ( field->rabat )
      ENDIF

      IF lInoPartner == .T.
         cIdTarifa := "PDV0"
      ENDIF

      cStornoRacunOpis := ""

      IF cFiskalniReklamiraniRnBroj > 0
         cStornoRacunOpis := AllTrim( Str( cFiskalniReklamiraniRnBroj ) )
      ENDIF

      IF field->dindem == Left( ValBazna(), 3 )
         nRacunFaktTotal += Round( nKolicina * nCijena * fakt_preracun_cijene() * ( 1 - _rn_rabat / 100 ), fakt_zaokruzenje() )
      ELSE
         nRacunFaktTotal += Round( nKolicina * nCijena * fakt_preracun_cijene() * ( 1 - _rn_rabat / 100 ), fakt_zaokruzenje() )
      ENDIF

      // 1 - broj racuna
      // 2 - redni broj
      // 3 - id roba
      // 4 - roba naziv
      // 5 - cijena
      // 6 - kolicina
      // 7 - tarifa
      // 8 - broj racuna za storniranje
      // 9 - roba plu
      // 10 - plu cijena
      // 11 - popust
      // 12 - barkod
      // 13 - vrsta placanja
      // 14 - total racuna
      // 15 - datum racuna
      // 16 - roba jmj

      AAdd( aRacunData, { cRacunBroj, ;
         _rn_rbr, ;
         _art_id, ;
         cNazivArtikla, ;
         nCijena, ;
         nKolicina, ;
         cIdTarifa, ;
         cStornoRacunOpis, ;
         nRobaFiscPLU, ;
         nCijena, ;
         _rn_rabat, ;
         cArtikalBarkod, ;
         cVrstaPlacanja, ;
         nTotalRacuna, ;
         _rn_datum, ;
         cRobaJmj } )

      SKIP

   ENDDO

   IF lPopustNaTeretProdavca .OR. lInoPartner
      FOR nI := 1 TO Len( aRacunData )
         aRacunData[ nI, 14 ] := nRacunFaktTotal
      NEXT
   ENDIF

   IF cIdTipDok $ "10" .AND. Len( _a_iznosi ) < 2
      set_fiscal_rn_zbirni( @aRacunData )
   ENDIF

   nItemLevelCheck := 2

   IF provjeri_kolicine_i_cijene_fiskalnog_racuna( @aRacunData, lStorno, nItemLevelCheck, s_hFiskalniParams[ "drv" ] ) < 0
      RETURN NIL
   ENDIF

   RETURN aRacunData



/*
   Opis: da li je račun bezgotovinski u zavisnosti od tipa dokumenta i vrste plaćanja
*/

STATIC FUNCTION racun_bezgotovinski( cIdTipDok, cVrstaPlacanja )

   IF cIdTipDok == "10" .AND. cVrstaPlacanja <> "G "
      RETURN .T.
   ENDIF

   IF cIdTipDok == "11" .AND. cVrstaPlacanja == "VR"
      RETURN .T.
   ENDIF

   RETURN .F.



/*
   Opis: vraća "kod" vrste plaćanja za fiskalni uređaj u zavisnosti od vrste dokumenta i vrste plaćanja

   Return:
     - "0" - gotovina
     - "1" - kartica
     - "3" - virman
*/
STATIC FUNCTION vrsta_placanja_za_fiskalni_uredjaj( cIdTipDok, cVrstaPlacanja )

   LOCAL cVrPlac := "0"

   IF ( cIdTipDok $ "#10#" .AND. !cVrstaPlacanja == "G " ) .OR. ( cIdTipDok == "11" .AND. cVrstaPlacanja == "VR" )
      cVrPlac := "3"
   ELSEIF ( cIdTipDok == "10" .AND. cVrstaPlacanja == "G " )
      cVrPlac := "0"
   ENDIF

   IF cIdTipDok $ "#11#" .AND. cVrstaPlacanja == "KT"
      cVrPlac := "1"
   ENDIF

   RETURN cVrPlac


/*
   Opis: da li se vrsta dokumenta može poslati na fiskalni uređaj
*/
STATIC FUNCTION dokument_se_moze_fiskalizovati( cIdTipDok )

   IF cIdTipDok $ "10#11"
      RETURN .T.
   ENDIF

   RETURN .F.



/*
   Opis: da li su podaci partnera za ispis na fiskalni račun kompletni
         naziv, adresa, ptt, telefon
*/
STATIC FUNCTION is_podaci_partnera_kompletirani( cIdPartner, cIdBrojPartner )

   LOCAL lRet := .T.

   select_o_partner( cIdPartner )

   IF !Found()
      lRet := .F.
      RETURN lRet
   ENDIF

   IF Empty( cIdBrojPartner )
      lRet := .F.
   ENDIF

   IF lRet .AND. Empty( partn->naz )
      lRet := .F.
   ENDIF
   IF lRet .AND. Empty( partn->adresa )
      lRet := .F.
   ENDIF
   IF lRet .AND. Empty( partn->ptt )
      lRet := .F.
   ENDIF
   IF lRet .AND. Empty( partn->mjesto )
      lRet := .F.
   ENDIF

   RETURN lRet


STATIC FUNCTION racun_bezgotovinski_bez_partnera_pitanje()

   IF Pitanje(, "Račun je bezgotovinski, podaci partnera nisu kompletirani. Želite nastaviti (D/N) ?", "N" ) == "D"
      IF Pitanje(, "Sigurno želite štampati fiskalni račun bez podataka kupca (D/N) ?", "N" ) == "D"
         RETURN .T.
      ENDIF
   ENDIF

   RETURN .F.



/*
   Opis: vraća matricu napunjenu sa podacima partnera kao i informacije o vrsti plaćanja, da li partner pdv obveznik
         na osnovu ažuriranog fakt dokumenta

   Usage: fakt_fiscal_podaci_partnera( cIdFirma, cIdTipDok, cBrDok, lStorno, lRacunBezPartnera )

   Parametri:
      - cIdFirma - fakt_doks->idfirma
      - cIdTipDok - fakt_doks->idtipdok
      - cBrDok - fakt_doks->brdok
      - lStorno - .T. račun je storno
      - lRacunBezPartnera - .T. bezgotovinski račun je moguć bez partnera

   Return:
      - .F. - podaci partnera nisu kompletirani ili ispravni, ima ID broj, PDV broj, ali fali adresa
      - NIL - podaci partnera ne treba da se uzimaju kod štampe fiskalnog računa
      - {} - podaci partnera { identifikacioni broj, naziv, adresa, telefon, ... }

   Primjer:

      aPartner := fakt_fiscal_podaci_partnera( "10", "10", "00001", .F., .F. )

      IF aPartner == .F.
            => partner ima podešene idbroj, pdv broj ali podaci partnera nisu kompletni, fiskalni račun nije moguće napraviti
      IF aPartner == NIL
            => na fiskalnom račun partner i njegovi podaci će biti ignorisani

*/

STATIC FUNCTION fakt_fiscal_podaci_partnera( cIdFirma, cIdTipDok, cBrDok, lStorno, lBezgRacunBezPartnera )

   LOCAL aRet := {}
   LOCAL cIdPartner
   LOCAL cIdVrsteP
   LOCAL cVrstaPlacanja := "0"
   LOCAL cIdPartnerBroj
   LOCAL lPartnClan
   LOCAL _podaci_kompletirani

   IF lBezgRacunBezPartnera == NIL
      lBezgRacunBezPartnera := .F.
   ENDIF

   s_lFiskalniPrikaziPartnera := .T.
   s_lFiskalniPartnerIno := .F.
   s_lFiskalniPartnerPDV := .T.

   seek_fakt_doks( cIdFirma, cIdTipDok, cBrDok )

   cIdPartner := field->idpartner
   cIdVrsteP := field->idvrstep

   IF Empty( cIdPartner )
      MsgBeep( "Šifra partnera ne postoji, izdavanje računa nije moguće !" )
      RETURN .F.
   ENDIF

   cIdPartnerBroj := AllTrim( firma_id_broj( cIdPartner ) )
   cFiskalniVrstaPlacanja := vrsta_placanja_za_fiskalni_uredjaj( cIdTipDok, cIdVrsteP )
   lPartnClan := is_part_pdv_oslob_po_clanu( cIdPartner )

   IF partner_is_ino( cIdPartner )
      s_lFiskalniPartnerIno := .T.
      s_lFiskalniPartnerPDV := .F.
      RETURN NIL
   ENDIF

   IF !is_idbroj_13cifara( cIdPartnerBroj )
      s_lFiskalniPrikaziPartnera := .F.
   ENDIF

   _podaci_kompletirani := is_podaci_partnera_kompletirani( cIdPartner, cIdPartnerBroj )

   IF racun_bezgotovinski( cIdTipDok, cIdVrsteP ) .AND. ( !s_lFiskalniPrikaziPartnera .OR. !_podaci_kompletirani )
      IF lBezgRacunBezPartnera .AND. racun_bezgotovinski_bez_partnera_pitanje()
         s_lFiskalniPrikaziPartnera := .F.
      ELSE
         MsgBeep( "Podaci partnera nisu kompletirani#Operacija štampe zaustavljena !" )
         RETURN .F.
      ENDIF
   ENDIF

   IF s_lFiskalniPrikaziPartnera .AND. !_podaci_kompletirani
      s_lFiskalniPrikaziPartnera := .F.
   ENDIF

   IF lPartnClan
      s_lFiskalniPartnerIno := .T.
      s_lFiskalniPartnerPDV := .F.
   ELSEIF partner_is_pdv_obveznik( cIdPartner )
      s_lFiskalniPartnerIno := .F.
      s_lFiskalniPartnerPDV := .T.
   ELSE
      s_lFiskalniPartnerIno := .F.
      s_lFiskalniPartnerPDV := .F.
   ENDIF

   IF !s_lFiskalniPrikaziPartnera
      RETURN NIL
   ENDIF

   AAdd( aRet, { cIdPartnerBroj, partn->naz, partn->adresa, partn->ptt, partn->mjesto, cFiskalniVrstaPlacanja, s_lFiskalniPartnerIno, s_lFiskalniPartnerPDV } )

   RETURN aRet




STATIC FUNCTION fakt_to_fprint( cIdFirma, cIdTipDok, cBrDok, aRacunData, aRacunHeader, lStorno )

   LOCAL cPath := s_hFiskalniParams[ "out_dir" ]
   LOCAL cFileName := s_hFiskalniParams[ "out_file" ]
   LOCAL nBrojFiskalnogRacuna := 0
   LOCAL nTotal := aRacunData[ 1, 14 ]
   LOCAL cPartnNaziv
   LOCAL nErrorLevel

   fprint_delete_answer( s_hFiskalniParams )
   fiskalni_fprint_racun( s_hFiskalniParams, aRacunData, aRacunHeader, lStorno )

   nErrorLevel := fprint_read_error( s_hFiskalniParams, @nBrojFiskalnogRacuna, lStorno )

   IF nErrorLevel == -9
      IF Pitanje(, "Da li je nestalo trake (D/N) ?", "N" ) == "D"
         IF Pitanje(, "Ubacite traku i pritisnite 'D'", " " ) == "D"
            nErrorLevel := fprint_read_error( s_hFiskalniParams, @nBrojFiskalnogRacuna, lStorno )
         ENDIF
      ENDIF
   ENDIF

   IF nErrorLevel == 2 .AND. lStorno
      error_bar( "fisc", "FPRINT ERR reklamirani fiskalni račun" )
      IF obrada_greske_na_liniji_55_reklamirani_racun( cIdFirma, cIdTipDok, cBrDok, s_hFiskalniParams )
         MsgBeep( "Ponoviti izdavanje reklamiranog računa na fiskalni uređaj." )
         RETURN 0
      ENDIF
   ENDIF

   IF nBrojFiskalnogRacuna <= 0
      nErrorLevel := 1
   ENDIF

   IF nErrorLevel <> 0
      error_bar( "fisc", "FPRINT ERR fiskalni racun" )
      obradi_gresku_izdavanja_fiskalnog_racuna( s_hFiskalniParams, nErrorLevel )
      RETURN nErrorLevel
   ENDIF

   IF !Empty( param_racun_na_email() ) .AND. cIdTipDok $ "#11#"
      cPartnNaziv := _get_partner_for_email( cIdFirma, cIdTipDok, cBrDok )
      fakt_fisk_send_email( nBrojFiskalnogRacuna, cIdTipDok + "-" + AllTrim( cBrDok ), cPartnNaziv, NIL, nTotal )
   ENDIF

   fakt_fisk_stavi_u_fakturu( cIdFirma, cIdTipDok, cBrDok, nBrojFiskalnogRacuna, lStorno )

   IF !s_lFiskalniSilentPrint
      MsgBeep( "Kreiran fiskalni račun broj: " + AllTrim( Str( nBrojFiskalnogRacuna ) ) )
   ENDIF

   RETURN nErrorLevel




STATIC FUNCTION obradi_gresku_izdavanja_fiskalnog_racuna( hFiskalniDevParams, nErrorLevel )

   LOCAL cPath := hFiskalniDevParams[ "out_dir" ]
   LOCAL cFilename := hFiskalniDevParams[ "out_file" ]
   LOCAL cMsg

   fprint_delete_out( cPath + cFilename )

   cMsg := "ERR FISC: stampa racuna err:" + AllTrim( Str( nErrorLevel ) ) + "##" + cPath + cFilename

   log_write( cMsg, 2 )
   MsgBeep( cMsg )

   RETURN .T.



/*
   Opis: obrada kod greške na liniji 55
*/
STATIC FUNCTION obrada_greske_na_liniji_55_reklamirani_racun( cIdFirma, cIdTipDok, cBrDok, hFiskalniDevParams )

   LOCAL lRet := .T.
   LOCAL nErr
   LOCAL lForsirano := .T.

   MsgBeep( "Greška se desila kod izdavanja reklamiranog računa.#Mogući uzrok je nedostatak depozita u uređaju." )

   IF Pitanje(, "Želite li otkloniti uzrok dodavanjem depozita (D/N) ?", " " ) == "N"
      RETURN lRet
   ENDIF

   fprint_delete_answer( hFiskalniDevParams )

   fprint_komanda_301_zatvori_racun( hFiskalniDevParams )

   nErr := fprint_read_error( hFiskalniDevParams, 0 )

   IF nErr <> 0
      lRet := .F.
      MsgBeep( "Neuspješan pokušaj poništavanja računa. Pozovite servis bring.out !" )
      RETURN lRet
   ENDIF

   IF !fakt_reklamirani_racun_preduslovi( cIdFirma, cIdTipDok, cBrDok, hFiskalniDevParams, lForsirano )
      lRet := .F.
      RETURN lRet
   ENDIF

   RETURN lRet



STATIC FUNCTION _get_partner_for_email( cIdFirma, cIdTipDok, cBrDok )

   LOCAL cRet := ""
   LOCAL nDbfArea := Select()
   LOCAL cIdPartner
   LOCAL cIdVrstePlacanja

   seek_fakt_doks( cIdFirma, cIdTipDok, cBrDok )

   cIdPartner := field->idpartner
   cIdVrstePlacanja := field->idvrstep

   IF select_o_partner( cIdPartner )
      cRet := AllTrim( field->naz )
   ENDIF

   IF !Empty( cIdVrstePlacanja )
      cRet += ", v.pl: " + cIdVrstePlacanja
   ENDIF

   SELECT ( nDbfArea )

   RETURN cRet



/*
   izdavanje fiskalnog isjecka na TREMOL uredjaj
*/

STATIC FUNCTION fakt_to_tremol( cIdFirma, cIdTipDok, cBrDok, aRacunData, aRacunHeader, lStorno )

   LOCAL nErrorLevel := 0
   LOCAL cFiskalniIme
   LOCAL nBrojFiskalnogRacuna := -1
   LOCAL nTremolCeka := -1

   nErrorLevel := fiskalni_tremol_racun( s_hFiskalniParams, aRacunData, aRacunHeader, lStorno ) // stampaj racun
   cFiskalniIme := AllTrim( fiscal_out_filename( s_hFiskalniParams[ "out_file" ], cBrDok ) )
   nTremolCeka := tremol_cekam_fajl_odgovora( s_hFiskalniParams, cFiskalniIme, s_hFiskalniParams[ "timeout" ] )


   IF nTremolCeka >= 0
      IF nTremolCeka > 0
         log_write_file( "FISK_RN: prodavac manuelno naveo broj racuna " + AllTrim( Str( nTremolCeka ) ), 2 )
         nErrorLevel := 0
         nBrojFiskalnogRacuna := nTremolCeka
      ELSE
         nErrorLevel := tremol_read_output( s_hFiskalniParams, cFiskalniIme, @nBrojFiskalnogRacuna )
      ENDIF
   ELSE
      nErrorLevel := -99
   ENDIF

   IF nErrorLevel == 0 .AND. !lStorno // vrati broj fiskalnog racuna
      IF nBrojFiskalnogRacuna > 0
         IF !s_lFiskalniSilentPrint
            MsgBeep( "Kreiran fiskalni račun br: " + AllTrim( Str( nBrojFiskalnogRacuna ) ) )
         ENDIF
         fakt_fisk_stavi_u_fakturu( cIdFirma, cIdTipDok, cBrDok, nBrojFiskalnogRacuna ) // ubaci broj fiskalnog racuna u fakturu

      ENDIF
      FErase( s_hFiskalniParams[ "out_dir" ] + cFiskalniIme )
   ENDIF

   RETURN nErrorLevel


STATIC FUNCTION fakt_fisk_fiskalni_isjecak_hcp( cIdFirma, cIdTipDok, cBrDok, aRacunData, aRacunHeader, lStorno )

   LOCAL nErrorLevel := 0
   LOCAL nBrojFiskalnogRacuna := 0

   nErrorLevel := fiskalni_hcp_racun( s_hFiskalniParams, aRacunData, aRacunHeader, lStorno, aRacunData[ 1, 14 ] )
   IF nErrorLevel == 0

      nBrojFiskalnogRacuna := fiskalni_hcp_get_broj_racuna( s_hFiskalniParams, lStorno )
      IF nBrojFiskalnogRacuna > 0
         fakt_fisk_stavi_u_fakturu( cIdFirma, cIdTipDok, cBrDok, nBrojFiskalnogRacuna, lStorno )
      ENDIF

   ENDIF

   RETURN nErrorLevel



/*
   napravi zbirni racun ako je potrebno
*/

STATIC FUNCTION set_fiscal_rn_zbirni( aRacunData )

   LOCAL aRacunLocal := {}
   LOCAL nTotal := 0
   LOCAL nKolicina := 1
   LOCAL cNazivArtikla := ""
   LOCAL _len := Len( aRacunData )

   IF s_hFiskalniParams[ "vp_sum" ] < 1 .OR. ;
         s_hFiskalniParams[ "plu_type" ] == "P" .OR. ;
         ( s_hFiskalniParams[ "vp_sum" ] > 1 .AND. s_hFiskalniParams[ "vp_sum" ] < _len )
      // ova opcija se ne koristi
      // ako je iskljucena opcija
      // ili ako je sifra artikla genericki PLU
      // ili ako je zadato da ide iznad neke vrijednosti stavki na racunu
      RETURN .F.
   ENDIF

   cNazivArtikla := "Stav.RN:"

   IF s_cFiskalniUredjaj  $ "#FPRINT#HCP#TRING#"
      cNazivArtikla += " " + AllTrim( aRacunData[ 1, 1 ] )
   ENDIF

   // ukupna vrijednost racuna za sve stavke matrice je ista popunjena
   nTotal := ROUND2( aRacunData[ 1, 14 ], 2 )

   IF !Empty( aRacunData[ 1, 8 ] )
      // ako je storno racun, napravi korekciju da je iznos pozitivan
      nTotal := Abs( nTotal )
   ENDIF

   // dodaj u aRacunLocal zbirnu stavku
   AAdd( aRacunLocal, { aRacunData[ 1, 1 ], ;
      aRacunData[ 1, 2 ], ;
      "", ;
      cNazivArtikla, ;
      nTotal, ;
      nKolicina, ;
      aRacunData[ 1, 7 ], ;
      aRacunData[ 1, 8 ], ;
      auto_plu( NIL, NIL, s_hFiskalniParams ), ;
      nTotal, ;
      0, ;
      "", ;
      aRacunData[ 1, 13 ], ;
      nTotal, ;
      aRacunData[ 1, 15 ], ;
      aRacunData[ 1, 16 ] } )


   aRacunData := aRacunLocal

   RETURN .T.



// -------------------------------------------------------------------
// setovanje broja fiskalnog racuna u dokumentu
// -------------------------------------------------------------------
STATIC FUNCTION fakt_fisk_stavi_u_fakturu( cFirma, cTD, cBroj, nFiscal, lStorno )

   LOCAL nTArea := Select()
   LOCAL hRec

   IF lStorno == nil
      lStorno := .F.
   ENDIF

   seek_fakt_doks( cFirma, cTD, cBroj )
   hRec := dbf_get_rec()
   IF lStorno == .T.
      hRec[ "fisc_st" ] := nFiscal
   ELSE
      hRec[ "fisc_rn" ] := nFiscal
   ENDIF

   hRec[ "fisc_date" ] := Date()
   hRec[ "fisc_time" ] := PadR( Time(), 10 )

   IF !update_rec_server_and_dbf( "fakt_doks", hRec, 1, "FULL" )
      MsgBeep( "Problem setovanja veze fiskalnog računa!#Operacija prekinuta." )
   ENDIF

   SELECT ( nTArea )

   RETURN .T.



// -------------------------------------------------------------
// izdavanje fiskalnog isjecka na TFP uredjaj - tring
// -------------------------------------------------------------
STATIC FUNCTION fakt_to_tring( cIdFirma, cIdTipDok, cBrDok, aRacunData, aRacunHeader, lStorno )

   LOCAL nErrorLevel := 0
   LOCAL _trig := 1
   LOCAL nBrojFiskalnogRacuna := 0

   IF lStorno
      _trig := 2
   ENDIF

   // brisi ulazne fajlove, ako postoje
   tring_delete_out( s_hFiskalniParams, _trig )

   // ispisi racun
   tring_rn( s_hFiskalniParams, aRacunData, aRacunHeader, lStorno )

   // procitaj gresku
   nErrorLevel := tring_read_error( s_hFiskalniParams, @nBrojFiskalnogRacuna, _trig )

   IF nBrojFiskalnogRacuna <= 0
      nErrorLevel := 1
   ENDIF

   // pobrisi izlazni fajl
   tring_delete_out( s_hFiskalniParams, _trig )

   IF nErrorLevel <> 0
      // ostavit cu answer fajl za svaki slucaj!
      // pobrisi izlazni fajl ako je ostao !
      MsgBeep( "Postoji greška sa stampanjem !" )
   ELSE
      tring_delete_answer( s_hFiskalniParams, _trig )
      // ubaci broj fiskalnog racuna u fakturu
      fakt_fisk_stavi_u_fakturu( cIdFirma, cIdTipDok, cBrDok, nBrojFiskalnogRacuna )
      MsgBeep( "Kreiran fiskalni racun broj: " + AllTrim( Str( nBrojFiskalnogRacuna ) ) )
   ENDIF

   RETURN nErrorLevel



FUNCTION fisc_isjecak( cFirma, cTipDok, cBrDok )

   LOCAL nTArea   := Select()
   LOCAL nFisc_no := 0

   seek_fakt_doks( cFirma, cTipDok, cBrDok )
   IF !Eof() // ako postoji broj reklamiranog racuna, onda uzmi taj
      IF field->fisc_st <> 0
         nFisc_no := field->fisc_st
      ELSE
         nFisc_no := field->fisc_rn
      ENDIF
   ENDIF
   SELECT ( nTArea )

   RETURN AllTrim( Str( nFisc_no ) )



STATIC FUNCTION fakt_fisk_send_email( fisc_rn, fakt_dok, kupac, eml_file, u_total )

   LOCAL _subject, _body
   LOCAL hMailParams
   LOCAL _to := AllTrim( param_racun_na_email() )

   _subject := "Racun: "
   _subject += AllTrim( Str( fisc_rn ) )
   _subject += ", " + fakt_dok
   _subject += ", " + to_xml_encoding( kupac )
   _subject += ", iznos: " + AllTrim( Str( u_total, 12, 2 ) )
   _subject += " KM"

   _body := "podaci kupca i racuna"

   hMailParams := f18_email_prepare( _subject, _body, NIL, _to )
   f18_send_email( hMailParams, NIL )

   RETURN NIL
