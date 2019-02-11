/*
 * This file is part of the bring.out knowhow ERP, a free and open source
 * Enterprise Resource Planning suite,
 * Copyright (c) 1994-2018 by bring.out d.o.o Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including knowhow ERP specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_knowhow.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */


#include "f18.ch"


FUNCTION fakt_meni_gen_ugov()

   PRIVATE DFTkolicina := 1
   PRIVATE DFTidroba := PadR( "", 10 )
   PRIVATE DFTvrsta := "1"
   PRIVATE DFTidtipdok := "10"
   PRIVATE DFTdindem := "KM "
   PRIVATE DFTidtxt := "10"
   PRIVATE DFTzaokr := 2
   PRIVATE DFTiddodtxt := "  "

   // PRIVATE gGenUgV2 := "1"
   PRIVATE gFinKPath := Space( 50 )

   DFTParUg( .T. )

   ugov_generacija()

   RETURN .T.




FUNCTION ugov_generacija()

   LOCAL dDatObr
   LOCAL dDatVal
   LOCAL dDatLUpl
   LOCAL cKtoDug
   LOCAL cKtoPot
   LOCAL cOpis
   LOCAL cFilter

   // LOCAL lSetParams := .F.
   LOCAL cUId
   LOCAL cUPartner
   LOCAL nSaldo
   LOCAL nSaldoPDV
   LOCAL cNBrDok
   LOCAL nUkupnoFaktura
   // LOCAL nMjesec
   // LOCAL nGodina
   LOCAL dDatGen := Date()
   LOCAL cFaktOd
   LOCAL cFaktDo
   LOCAL cIdArt
   LOCAL cIdFirma
   LOCAL nTArea
   LOCAL cDestin
   LOCAL nGenCh
   LOCAL cGenTipDok := ""
   LOCAL cDatLFakt
   LOCAL dLFakt
   LOCAL hRec
   LOCAL nCount := 0
   LOCAL cAutoAzuriranjeDN
   LOCAL aDokumentiGenerisani := {}
   LOCAL cDefDest

   o_ugov_tabele()

   IF !ugov_generacija_parametri( @dDatObr, @dDatGen, @dDatVal, @dDatLUpl, ;
         @cKtoDug, @cKtoPot, @cOpis, @cIdArt, @nGenCh, @cDestin, @cDatLFakt, @dLFakt, @cAutoAzuriranjeDN )
      RETURN .F.
   ENDIF

   o_fakt_pripr()


   IF RecCount2() <> 0
      MsgBeep( "U pripremi postoje dokumenti#Prekidam generaciju!" )
      my_close_all_dbf()
      RETURN .F.
   ENDIF

   IF postoji_generacija_u_gen_ug( dDatObr, cIdArt )
      RETURN .F.
   ENDIF

   IF !o_gen_ug( dDatObr )
      APPEND BLANK
   ENDIF
   hRec := dbf_get_rec()
   hRec[ "dat_obr" ] := dDatObr
   hRec[ "dat_gen" ] := dDatGen
   hRec[ "dat_u_fin" ] := dDatLUpl
   hRec[ "kto_kup" ] := cKtoDug
   hRec[ "kto_dob" ] := cKtoPot
   hRec[ "opis" ] := cOpis
   update_rec_server_and_dbf( "fakt_gen_ug", hRec, 1, "FULL" )

   o_aktivni_ugovori()

   nSaldo := 0
   nSaldoPDV := 0
   // nNBrDok := ""

   nUkupnoFaktura := 0

   IF nGenCh == 1
      cGenTipDok := "10"
   ENDIF

   IF nGenCh == 2
      cGenTipDok := "20"
   ENDIF

   Box(, 3, 60 )

   @ box_x_koord() + 1, box_y_koord() + 2 SAY "Generacija ugovora u toku..."

   cFaktOd := ""
   cFaktDo := ""


   DO WHILE !Eof()

      IF !da_li_ima_u_rugov( ugov->id, cIdArt )
         SELECT ugov
         SKIP
         LOOP
      ENDIF


      IF !ugov_treba_generisati( ugov->id, dDatObr, cDatLFakt, dLFakt )
         SELECT ugov
         SKIP
         LOOP
      ENDIF

      IF !Empty( cIdArt )
         cIdFirma := get_id_firma_by_roba_k2( cIdArt )
      ELSE
         cIdFirma := self_organizacija_id()
      ENDIF

      ++nCount
      IF Empty( cGenTipDok )
         cGenTipDok := ugov->idtipdok
         IF Empty( ugov->idtipdok )
            MsgBeep( "ugov tipdok nije popunjen ?! " + ugov->id )
         ENDIF
         SELECT ugov
         SKIP
      ENDIF


      cNBrDok := fakt_novi_broj_dokumenta( cIdFirma, cGenTipDok )

      IF nCount == 1
         cFaktOd := cNBrDok
      ENDIF

      cUId := ugov->id
      cUPartner := ugov->idpartner

      IF cDestin <> NIL .AND. cDestin == "D"   // destinacije
         cDefDest := ugov->def_dest
      ELSE
         cDefDest := nil
      ENDIF

      @ box_x_koord() + 2, box_y_koord() + 2 SAY "Ug / Partner -> " + cUId + " / " + cUPartner

      generacija_ugovora_za_partnera( cUId, cUPartner, dDatObr, dDatVal, @nSaldo, @nSaldoPDV, @nUkupnoFaktura, @cNBrDok, ;
         cIdArt, cIdFirma, cDefDest, cGenTipDok, @aDokumentiGenerisani )

      SELECT ugov
      SKIP

   ENDDO

   cFaktDo := cNBrDok


   IF !Empty( cIdArt )
      ?E "ugov gen kraj artikal=", cIdArt  // fakturisanje pojedinacnog artikla ne upisujemo u gen_ug
   ELSE

      IF o_gen_ug( dDatObr ) // upisi u gen_ug salda
         hRec := dbf_get_rec()
         hRec[ "fakt_br" ] := nUkupnoFaktura
         hRec[ "saldo" ] := nSaldo
         hRec[ "saldo_pdv" ] := nSaldoPDV
         hRec[ "dat_gen" ] := dDatGen
         hRec[ "dat_val" ] := dDatVal
         hRec[ "brdok_od" ] := cFaktOd
         hRec[ "brdok_do" ] := cFaktDo
         update_rec_server_and_dbf( "fakt_gen_ug", hRec, 1, "FULL" )
      ENDIF

   ENDIF

   BoxC()

   ugov_prikazi_info_o_generaciji( dDatObr )  // prikazi info generacije

   IF cAutoAzuriranjeDN == "D"
      fakt_azuriraj_dokumente_u_pripremi( .T. )
   ENDIF

   info_generated_data( aDokumentiGenerisani )  // prikazi info o generisanim dokumentima

   RETURN .T.


STATIC FUNCTION ugov_generacija_parametri( dDatObr, dDatGen, dDatVal, dDatLUpl, ;
      cKtoDug, cKtoPot, cOpis, cIdArt, nGenCh, cDestin, cDatLFakt, dLFakt, cAutoAzur )

   LOCAL dPom
   LOCAL nX := 2
   LOCAL nBoxLen := 20
   LOCAL nMjesec, nGodina
   LOCAL GetList := {}

   dDatGen := Date()

   // datum posljednjeg fakturisanja
   dLFakt := get_zadnje_fakturisanje_po_ugovoru()
   // datum posljenje uplate u fin
   dDatLUpl := CToD( "" )
   // konto kupac
   cKtoDug := fetch_metric( "ugovori_konto_duguje", NIL, PadR( "2110", 7 ) )
   // konto dobavljac
   cKtoPot := fetch_metric( "ugovori_konto_potrazuje", NIL, PadR( "5410", 7 ) )
   // opis
   cOpis := PadR( "", 100 )


   cIdArt := PadR( "", 10 ) // artikal

   // destinacije
   cDestin := "N"
   // datum posljednjeg fakturisanja partnera
   cDatLFakt := "N"
   cAutoAzur := "D"


   nGenCh := 0

   IF dDatObr == nil
      dDatObr := Date()
   ENDIF
   IF dDatVal == nil
      dDatVal := Date()
   ENDIF

   dPom := dDatObr

   nMjesec := Month( dPom )  // mjesec na koji se odnosi fakturisanje
   nGodina := Year( dPom )

   Box( "#PARAMETRI ZA GENERACIJU FAKTURA PO UGOVORIMA", 22, 70 )

   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "Gen. ?/fakt/ponuda (0/1/2)", nBoxLen + 6 ) GET nGenCh PICT "9"

   nX += 1
   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "Datum fakturisanja", nBoxLen ) GET dDatGen

   nX += 2
   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "Datum valute", nBoxLen ) GET dDatVal

   nX += 2
   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "Fakt.za mjesec", nBoxLen ) GET nMjesec PICT "99" VALID nMjesec >= 1 .OR. nMjesec <= 12
   @ box_x_koord() + nX, Col() + 2 SAY "godinu" GET nGodina PICT "9999"

   nX += 2
   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "Konto duguje", nBoxLen ) GET cKtoDug VALID P_Konto( @cKtoDug )

   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "Konto potrazuje", nBoxLen ) GET cKtoPot VALID P_Konto( @cKtoPot )

   nX += 2
   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "Dat.zadnje upl.fin", nBoxLen ) GET dDatLUpl WHEN {|| dDatLUpl := dDatGen - 1, .T. }

   nX += 2
   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "Fakturisati artikal (prazno-svi)", nBoxLen + 10 ) GET cIdArt VALID Empty( cIdArt ) .OR. p_roba( @cIdArt )

   nX += 2
   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "Opis", nBoxLen ) GET cOpis ;
      WHEN  {|| cOpis := iif( Empty( cOpis ), PadR( "Obracun " + fakt_do( dDatObr ), 100 ), cOpis ), .T. }  PICT "@S40"

   nX += 2
   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "Uzeti u obzir destinacije ?", nBoxLen + 10 ) GET cDestin VALID cDestin $ "DN" PICT "@!"

   nX += 1
   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "Gledati datum zadnjeg fakturisanja ?", nBoxLen + 16 ) GET cDatLFakt VALID cDatLFakt $ "DN" PICT "@!"

   nX += 1
   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "Datum zadnjeg fakturisanja ?", nBoxLen + 16 ) GET dLFakt


   nX += 1
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 PadL( "Automatski ažuriraj fakture (D/N) ?", nBoxLen + 16 ) GET cAutoAzur ;
      VALID cAutoAzur $ "DN" PICT "@!"

   READ

   BoxC()

   IF LastKey() == K_ESC
      RETURN .F.
   ENDIF

   dDatObr := mo_ye( nMjesec, nGodina )

   set_metric( "ugovori_konto_duguje", NIL, cKtoDug )
   set_metric( "ugovori_konto_potrazuje", NIL, cKtoPot )

   RETURN .T.





STATIC FUNCTION get_id_firma_by_roba_k2( cIdRoba )

   LOCAL nTArea := Select()
   LOCAL cFirma := self_organizacija_id()

   IF select_o_roba( cIdRoba )
      IF !Empty( field->k2 ) .AND. Len( AllTrim( field->k2 ) ) == 2
         cFirma := AllTrim( field->k2 )
      ENDIF
   ENDIF

   SELECT ( nTArea )

   RETURN cFirma



STATIC FUNCTION ugov_treba_generisati( cUgovId, dDatObr, cDatLFakt, dLFakt )

   LOCAL nPMonth
   LOCAL nPYear
   LOCAL i
   LOCAL lNasaoObracun

   // predhodni obracun
   LOCAL dPObr
   LOCAL cNFakt

   IF cDatLFakt == nil
      cDatLFakt := "N"
   ENDIF

   PushWA()

   dPom := dDatObr

   o_ugov( cUgovId, NIL, F_POM, "POM" )

   IF cDatLFakt == "D" // datum zadnjeg fakturisanja
      IF !Empty( pom->dat_l_fakt ) .AND. pom->dat_l_fakt < dLFakt
         USE
         PopWa()
         RETURN .F.
      ENDIF
   ENDIF

   IF pom->datdo < dDatObr  // istekao je krajnji rok trajanja ugovora
      USE
      PopWa()
      RETURN .F.
   ENDIF


   cFNivo := pom->f_nivo    // nivo fakturisanja G - godisnji

   // SELECT gen_ug_p
   // SET ORDER TO TAG "DAT_OBR"


   IF pom->f_nivo == "G"  // GODISNJI NIVO

      dPObr := pom->dat_l_fakt
      USE
      PopWa()

      IF dDatObr - 365 >= dPObr
         RETURN .T.
      ELSE
         RETURN .F.
      ENDIF

   ELSE

      lNasaoObracun := .F.

      FOR i := 1 TO 6   // gledamo obracune u predhodnih 6 mjeseci

         // predhodni mjesec (datum) u odnosu na dPom
         dPObr := predhodni_mjesec( dPom )


         // SELECT gen_ug_p    // ima li ovaj obracun pohranjen
         // SEEK DToS( dPObr ) + cUgovId + ugov->IdPartner

         // IF Found()
         IF o_gen_ug_p( dPObr, cUgovId, pom->idPartner )
            lNasaoObracun := .T.
            EXIT
         ELSE
            // nisam nasao ovaj obracun, pokusaj ponovo mjesec ispred
            dPom := dPObr
         ENDIF
      NEXT

      IF !lNasaoObracun
         // nisam nasao obracun, ovo je prva generacija pa je u ugov upisan datum posljednjeg obracuna
         dPObr := pom->dat_l_fakt
      ELSE
         // ako su rucno pravljene fakture (unaprijed) u ugov se upisuje do kada je to pravljeno
         IF pom->dat_l_fakt >= dDatObr
            dPObr := pom->dat_l_fakt
         ENDIF
      ENDIF

      USE
      PopWa()

      IF dDatObr > dPObr
         RETURN .T.
      ELSE
         RETURN .F.
      ENDIF
   ENDIF

   RETURN .T.




STATIC FUNCTION predhodni_mjesec( dPom )

   LOCAL nPMonth
   LOCAL nPYear

   nPMonth := Month( dPom ) - 1
   nPYear := Year( dPom )

   IF nPMonth == 0
      // dPom je bio 01/YYYY
      nPMonth := 12
      nPYear--
   ENDIF

   RETURN  dPObr := mo_ye( nPMonth, nPYear )



STATIC FUNCTION da_li_ima_u_rugov( cIdUgovor, cIdRoba )

   LOCAL nTArr
   LOCAL lRet := .F.

   nTArr := Select()

   // SELECT rugov

   IF cIdRoba == nil
      cIdRoba := ""
   ENDIF

   IF Empty( cIdRoba )
      o_rugov( cIdUgovor )
   ELSE
      o_rugov( cIdUgovor, cIdRoba )
   ENDIF

   IF !Eof()
      lRet := .T.
   ENDIF

   SELECT ( nTArr )

   RETURN lRet



STATIC FUNCTION ugov_prikazi_info_o_generaciji( dDat )

   LOCAL cPom

   IF o_gen_ug( dDat )
      // SELECT
      // SET ORDER TO TAG "dat_obr"
      // GO TOP
      // SEEK DToS( dDat )
      // IF Found()

      cPom := "Generisani ugovor za " + DToC( dDat )
      cPom += "##"
      cPom += "Broj faktura: " + AllTrim( Str( field->fakt_br ) )
      cPom += "#"
      cPom += "Saldo: " + AllTrim( Str( field->saldo, 12, 2 ) )
      cPom += "#"
      cPom += "PDV: " + AllTrim( Str( field->saldo_pdv, 12, 2 ) )
      cPom += "#"
      cPom += "Fakture od: " + AllTrim( gen_ug->brdok_od ) + " - " + AllTrim( gen_ug->brdok_do )

      MsgBeep( cPom )

   ENDIF

   RETURN .T.



/*
 aData - sadrzi matricu generisanih faktura sa opisima
*/

STATIC FUNCTION generacija_ugovora_za_partnera( cUId, cUPartn, dDatObr, dDatVal, nGSaldo, nGSaldoPDV, nUkupnoFaktura, cBrDok, cArtikal, cFirma, cDestin, cFTipDok, aData )

   LOCAL dDatGen
   LOCAL cIdUgov
   LOCAL i
   LOCAL nRbr
   LOCAL nCijena
   LOCAL nFaktIzn := 0
   LOCAL nFaktPDV := 0
   LOCAL cTxt1
   LOCAL cTxt2
   LOCAL cTxt3
   LOCAL cTxt4
   LOCAL cTxt5
   LOCAL nSaldoKup := 0
   LOCAL nSaldoDob := 0
   LOCAL dPUplKup := CToD( "" )
   LOCAL dPPromKup := CToD( "" )
   LOCAL dPPRomDob := CToD( "" )
   LOCAL cPom
   LOCAL nCount
   LOCAL nPorez
   LOCAL cKtoPot
   LOCAL cKtoDug
   LOCAL dDatLFakt
   LOCAL nMjesec
   LOCAL nGodina
   LOCAL lFromDest
   LOCAL hRec
   LOCAL cDestinacija

   o_gen_ug( dDatObr )

   cKtoPot := gen_ug->kto_dob
   cKtoDug := gen_ug->kto_kup
   dDatLUpl := gen_ug->dat_u_fin
   dDatGen := gen_ug->dat_gen
   nMjesec := gen_ug->( Month( dat_obr ) )
   nGodina := gen_ug->( Year( dat_obr ) )

   nastimaj_se_na_partner_by_id( cUPartn )

   IF Empty( cFTipDok )
      cFTipdok := ugov->idtipdok
   ENDIF

   nRbr := 0
   cIdUgov := ugov->id

   SELECT rugov
   nCount := 0

   // prodji kroz rugov
   DO WHILE !Eof() .AND. ( id == cUId )

      lFromDest := .F.

      IF !Empty( cArtikal )

         IF cArtikal <> rugov->idroba // ako postoji zadata roba i ako rugov->idroba nije predmet fakturisanja preskoci tu stavku
            SELECT rugov
            SKIP
            LOOP
         ENDIF

      ENDIF

      nCijena := rugov->cijena
      nKolicina := rugov->kolicina
      nRabat := rugov->rabat


      IF cDestin <> NIL .AND. !Empty( cDestin )   // nastimaj destinaciju

         IF nastimaj_se_na_dest_by_partn_dest( cUPartn, cDestin )    // postoji def. destinacija za svu robu
            lFromDest := .T.
         ENDIF

      ELSEIF cDestin <> NIL .AND. Empty( cDestin )

         IF nastimaj_se_na_dest_by_partn_dest( cUPartn, rugov->dest )  // za svaku robu treba posebna faktura
            lFromDest := .T.
         ENDIF

         IF lFromDest == .T. .AND. nCount > 0  // novi broj dokumenta

            ++nUkupnoFaktura   // uvecaj uk.broj gen.faktura
            nRbr := 0    // resetuj brojac stavki na 0

            cBrDok := fakt_novi_broj_dokumenta( cFirma, cFTipDok )    // uvecaj broj dokumenta

         ENDIF

      ENDIF

      nastimaj_se_na_roba_by_id( rugov->idroba )   // nastimaj roba na rugov-idroba
      select_o_tarifa( roba->idtarifa )
      nPorez := tarifa->pdv

      SELECT fakt_pripr
      APPEND BLANK

      ++nCount

      Scatter()

      IF roba->tip == "U"
         // aMemo[1]
         // pronadji djoker #ZA_MJ#
         cPom := str_za_mj( roba->naz, nMjesec, nGodina )
         fakt_add_to_public_var_txt_uokviri_sa_chr16_chr17( cPom )
      ELSE
         // aMemo[1]
         fakt_add_to_public_var_txt_uokviri_sa_chr16_chr17( "", .T. )
      ENDIF


      IF nRbr == 0   // samo na prvoj stavci generisi txt

         // nadji tekstove
         cTxt1 := f_ftxt( ugov->idtxt )
         cTxt2 := f_ftxt( ugov->iddodtxt )
         cTxt3 := f_ftxt( ugov->txt2 )
         cTxt4 := f_ftxt( ugov->txt3 )
         cTxt5 := f_ftxt( ugov->txt4 )

         SELECT fakt_pripr

         // aMemo[2]
         cPom := cTxt1 + cTxt2 + cTxt3 + cTxt4 + cTxt5
         // dodaj u polje _txt
         fakt_add_to_public_var_txt_uokviri_sa_chr16_chr17( cPom )

         // dodaj podatke o partneru

         // aMemo[3]
         // naziv partnera
         cPom := AllTrim( partn->naz )
         fakt_add_to_public_var_txt_uokviri_sa_chr16_chr17( cPom )

         // adresa
         // aMemo[4]
         cPom := AllTrim( partn->adresa )
         fakt_add_to_public_var_txt_uokviri_sa_chr16_chr17( cPom )

         // ptt i mjesto
         // aMemo[5]
         cPom := AllTrim( partn->ptt )
         cPom += " "
         cPom += AllTrim( partn->mjesto )
         fakt_add_to_public_var_txt_uokviri_sa_chr16_chr17( cPom )

         // br.otpremnice i datum
         // aMemo[6,7]
         fakt_add_to_public_var_txt_uokviri_sa_chr16_chr17( "", .T. )
         fakt_add_to_public_var_txt_uokviri_sa_chr16_chr17( "", .T. )

         // br. ugov
         // aMemo[8]
         fakt_add_to_public_var_txt_uokviri_sa_chr16_chr17( ugov->id, .T. )

         cPom := DToC( dDatGen )

         // datum isporuke
         // aMemo[9]
         cPom := DToC( dDatVal )
         fakt_add_to_public_var_txt_uokviri_sa_chr16_chr17( cPom )

         // datum valute
         // aMemo[10]
         fakt_add_to_public_var_txt_uokviri_sa_chr16_chr17( cPom )

         cDestinacija := ""

         IF lFromDest == .T.

            // dodaj prazne zapise
            cPom := " "
            FOR i := 11 TO 17
               fakt_add_to_public_var_txt_uokviri_sa_chr16_chr17( cPom, .T. )
            NEXT

            // uzmi iz destinacije
            cPom := ""
            cPom += AllTrim( dest->naziv )

            IF !Empty( dest->naziv2 )
               cPom += " "
               cPom += AllTrim( dest->naziv2 )
            ENDIF

            IF !Empty( dest->mjesto )
               cPom += ", "
               cPom += AllTrim( dest->mjesto )
            ENDIF

            IF !Empty( dest->adresa )
               cPom += ", "
               cPom += AllTrim( dest->adresa )
            ENDIF

            IF !Empty( dest->ptt )
               cPom += ", "
               cPom += AllTrim( dest->ptt )
            ENDIF

            IF !Empty( dest->telefon )
               cPom += ", tel: "
               cPom += AllTrim( dest->telefon )
            ENDIF

            IF !Empty( dest->fax )
               cPom += ", fax: "
               cPom += AllTrim( dest->fax )
            ENDIF

            cDestinacija := cPom
            fakt_add_to_public_var_txt_uokviri_sa_chr16_chr17( cPom, .T. )

         ENDIF

      ENDIF

      SELECT fakt_pripr

      _idfirma := cFirma
      _idpartner := cUPartn
      _zaokr := ugov->zaokr
      _rbr := Str( ++nRbr, 3 )
      _idtipdok := cFTipDok
      _brdok := cBrDok
      _datdok := dDatGen
      _datpl := dDatGen
      _kolicina := nKolicina
      _idroba := rugov->idroba
      _cijena := nCijena


      IF _cijena == 0   // setuj iz sifrarnika
         fakt_setuj_cijenu( "1" )
         nCijena := _cijena
      ENDIF

      _rabat := rugov->rabat

      // ne smije se setovati porez u tabeli pripreme,
      // napravit ce kurslus !!
      // _porez := rugov->porez

      _dindem := ugov->dindem

      nFaktIzn += nKolicina * nCijena
      nFaktPDV += nFaktIzn * ( nPorez / 100 )

      nGSaldo += nFaktIzn
      nGSaldoPDV += nFaktPDV

      // dodaj u kontrolnu matricu sta je generisano
      dodaj_u_kontrolnu_matricu_generisano( @aData, _idfirma, _idtipdok, _brdok, _idpartner, cDestinacija )

      my_rlock()
      Gather()
      my_unlock()

      _txt := ""

      SELECT rugov
      SKIP

   ENDDO


   nSaldoKup := get_fin_partner_saldo( cUPartn, cKtoDug )  // saldo kupca
   nSaldoDob := get_fin_partner_saldo( cUPartn, cKtoPot )  // saldo dobavljaca
   dPUplKup := g_dpupl_part( cUPartn, cKtoDug )    // datum zadnje uplate kupca
   dPPromKup := datum_posljednje_promjene_kupac_dobavljac( cUPartn, cKtoDug )    // datum zadnje promjene kupac
   dPPromDob := datum_posljednje_promjene_kupac_dobavljac( cUPartn, cKtoPot )  // datum zadnje promjene dobavljac

   dodati_stavku_u_gen_ug_p( dDatObr, cUId, cUPartn, nSaldoKup, nSaldoDob, dPUplKup, dPPromKup, dPPromDob, nFaktIzn, nFaktPdv )

   // uvecaj broj faktura
   ++nUkupnoFaktura

   // SELECT gen_ug
   // SET ORDER TO TAG "dat_obr"
   // SEEK DToS( dDatGen )

   // IF Found()
   IF o_gen_ug( dDatGen )

      hRec := dbf_get_rec()
      // broj prve fakture
      IF Empty( field->brdok_od )
         hRec[ "brdok_od" ] := cBrDok
      ENDIF
      hRec[ "brdok_do" ] := cBrDok
      update_rec_server_and_dbf( Alias(), hRec, 1, "FULL" )
   ENDIF

   // vrati se na pripremu i pregledaj djokere na _TXT
   SELECT fakt_pripr
   nTRec := RecNo()

   // vrati se na prvu stavku ove fakture
   SKIP -( nCount - 1 )

   Scatter()

   fakt_txt_fill_djokeri( nSaldoKup, nSaldoDob, dPUplKup, dPPromKup, dPPromDob, dDatLUpl, cUPartn )

   my_rlock()
   Gather()
   my_unlock()

   GO ( nTRec )

   RETURN .T.



STATIC FUNCTION dodati_stavku_u_gen_ug_p( dDatObr, cIdUgov, cUPartner,  ;
      nSaldoKup, nSaldoDob, dPUplKup, dPPromKup, dPPromDob, nFaktIzn, nFaktPdv )

   LOCAL hRec

   // SELECT gen_ug_p
   // SET ORDER TO TAG "dat_obr"
   // SEEK DToS( dDatObr ) + cIdUgov + cUPartner

   // IF !Found()
   IF !o_gen_ug_p( dDatObr, cIdUgov, cUPartner )
      APPEND BLANK
   ENDIF

   hRec := dbf_get_rec()

   hRec[ "dat_obr" ] := dDatObr
   hRec[ "id_ugov" ] := cIdUgov
   hRec[ "idpartner" ] := cUPartner
   hRec[ "saldo_kup" ] := nSaldoKup
   hRec[ "saldo_dob" ] := nSaldoDob
   hRec[ "d_p_upl_ku" ] := dPUplKup
   hRec[ "d_p_prom_k" ] := dPPromKup
   hRec[ "d_p_prom_d" ] := dPPromDob
   hRec[ "f_iznos" ] := nFaktIzn
   hRec[ "f_iznos_pd" ] := nFaktPDV

   update_rec_server_and_dbf( "fakt_gen_ug_p", hRec, 1, "FULL" )

   RETURN .T.



STATIC FUNCTION dodaj_u_kontrolnu_matricu_generisano( aData, id_firma, id_tip_dok, br_dok, id_partner, destinacija )

   LOCAL nPos := AScan( aData, {| srch | srch[ 1 ] == id_firma .AND.  srch[ 2 ] == id_tip_dok .AND.  srch[ 3 ] == br_dok } )

   IF nPos == 0
      AAdd( aData, { id_firma, id_tip_dok, br_dok, id_partner, destinacija } )
   ENDIF

   RETURN .T.


// ----------------------------------------------------------------------
// prikaz generisanih podataka
//
// aData = [ idfirma, idtipdok, brdok, idpartner, destinacija ]
// ----------------------------------------------------------------------
STATIC FUNCTION info_generated_data( aData )

   LOCAL nI
   LOCAL _cnt := 0

   START PRINT CRET

   o_partner()

   ?
   ? "Pregled generisanih dokumenata prema kupcima:"
   ? "----------------------------------------------"
   P_COND2
   ?
   ? PadR( "R.br", 5 ), PadR( "dokument", 15 ), PadR( "partner", 34 ), PadR( "destinacija", 100 )
   ? Replicate( "-", 150 )

   FOR nI := 1 TO Len( aData )

      select_o_partner( aData[ nI, 4 ] )

      ? PadL( AllTrim( Str( ++_cnt ) ), 4 ) + "."

      @ PRow(), PCol() + 1 SAY PadR( aData[ nI, 1 ] + "-" + aData[ nI, 2 ] + "-" + AllTrim( aData[ nI, 3 ] ), 15 )
      @ PRow(), PCol() + 1 SAY PadR( aData[ nI, 4 ], 6 ) + " - " + PadR( partn->naz, 25 )
      @ PRow(), PCol() + 1 SAY PadR( aData[ nI, 5 ], 100 )

   NEXT

   FF
   ENDPRINT

   RETURN .T.



STATIC FUNCTION postoji_generacija_u_gen_ug( dDatObr, cIdArt )

   // SELECT gen_ug
   // SET ORDER TO TAG "dat_obr"
   // SEEK DToS( dDatObr )
   // IF !Found()

   IF !o_gen_ug( dDatObr )
      RETURN .F.
   ENDIF

   IF Pitanje(, "Obračun " + fakt_do( dDatObr ) + " postoji, ponoviti (D/N)?", "D" ) == "D"

      ugov_vrati_obracun_nazad( dDatObr, cIdArt )
      my_close_all_dbf()
      // o_ugov_tabele()
      // o_fakt_dbf()
      o_fakt_pripr()

      // SELECT gen_ug
      // SET ORDER TO TAG "dat_obr"
      // SEEK DToS( dDatObr )
      o_gen_ug( dDatObr )

      RETURN .F.
   ENDIF

   RETURN .T.



STATIC FUNCTION ugov_vrati_obracun_nazad( dDatObr, cIdArt )

   LOCAL cBrDokOdDo
   LOCAL cFirma := self_organizacija_id()

   // SELECT gen_ug
   // SET ORDER TO TAG "dat_obr"
   // GO TOP
   // SEEK DToS( dDatObr )

   // IF !Found()
   IF !o_gen_ug( dDatObr )
      MsgBeep( "Obračun " + fakt_do( dDatObr ) + " ne postoji" )
      RETURN .F.
   ENDIF

   IF !Empty( cIdArt ) // fakturisati pojedinacni artikal
      cFirma := get_id_firma_by_roba_k2( cIdArt )
   ENDIF

/*
   IF fakt_dokument_postoji( cFirma, "10", gen_ug->brdok_od ) .AND. fakt_dokument_postoji( cFirma, "10", gen_ug->brdok_do )

      cBrDokOdDo := gen_ug->brdok_od + "--" +  gen_ug->brdok_do + ";"
      fakt_povrat_po_kriteriju( cBrDokOdDo, NIL, NIL, cFirma )

   ENDIF
*/

   o_fakt_pripr()
   fakt_brisanje_pripreme()

   RETURN .T.



STATIC FUNCTION nastimaj_se_na_partner_by_id( cId )

   LOCAL nTArr

   nTArr := Select()
   select_o_partner( cId )
   SELECT ( nTArr )

   RETURN .T.



STATIC FUNCTION nastimaj_se_na_roba_by_id( cId )

   LOCAL nTArr

   nTArr := Select()
   select_o_roba( cId )
   SELECT ( nTArr )

   RETURN .T.


STATIC FUNCTION nastimaj_se_na_dest_by_partn_dest( cPartn, cDest )

   LOCAL nTArr
   LOCAL lRet := .F.

   nTArr := Select()
   // SELECT dest
   // SET ORDER TO TAG "ID"
   // GO TOP
   // SEEK cPartn + cDest
   IF find_dest_by_iddest_idpartn( cDest, cPartn )
      // IF Found()
      lRet := .T.
   ENDIF

   SELECT ( nTArr )

   RETURN lRet
