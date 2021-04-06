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

MEMVAR cIdRadn, cIdRj, nGodina, nMjesec, lNovi, cObracun, gObracun, gVarObracun


FUNCTION ld_unos_obracuna()

   LOCAL lSaveObracun
   LOCAL hLdRec
   LOCAL _fields
   LOCAL _pr_kart_pl := fetch_metric( "ld_obracun_prikaz_kartice_na_unosu", NIL, "N" )
   LOCAL nI

   // ove varijable koriste formule garant ?
   PRIVATE lNovi
   PRIVATE GetList
   PRIVATE nPlacenoRSati
   PRIVATE cIdRadn, cIdRj, nGodina, nMjesec, cObracun

   cIdRj := gLDRadnaJedinica

   cIdRadn := Space( LEN_IDRADNIK )
   GetList := {}

   nGodina := ld_tekuca_godina()
   nMjesec := ld_tekuci_mjesec()
   cObracun := gObracun

   // select_o_ld()

   DO WHILE .T.

      lSaveObracun := .F.
      ld_unos_obracuna_box( @lSaveObracun )

      IF ( lSaveObracun )

         seek_ld( cIdRj,  nGodina,  nMjesec,  iif( ld_vise_obracuna(), cObracun, "" ),  cIdRadn )
         cIdRadn := field->idRadn

         IF ( _UIznos < 0 )
            MsgBeep( "Radnik ne može imati platu u negativnom iznosu !"  )
         ENDIF

         nPom := 0

         FOR nI := 1 TO cLDPolja
            cPom := PadL( AllTrim( Str( nI ) ), 2, "0" )
            nPom += Abs( _I&cPom ) + Abs( _S&cPom )
         NEXT

         IF ( nPom <> 0 )

            hLdRec := get_hash_record_from_global_vars()
            hLdRec[ "varobr" ] := gVarObracun

            IF !update_rec_server_and_dbf( "ld_ld",  hLdRec, 1, "FULL" )
               delete_with_rlock()
            ELSE
               log_write( "F18_DOK_OPER: ld, " + iif( lNovi, "unos novog", "korekcija" ) + " obracuna plate - radnik: " + ld->idradn + ", mjesec: " + AllTrim( Str( ld->mjesec ) ) + ", godina: " + AllTrim( Str( ld->godina ) ), 2 )
            ENDIF

         ELSE
            IF lNovi
               delete_with_rlock()
            ENDIF
         ENDIF

         IF _pr_kart_pl == "D"
            ld_kartica_plate( cIdRj, ld_tekuci_mjesec(), ld_tekuca_godina(), cIdRadn, iif( ld_vise_obracuna(), gObracun, NIL ) )
         ENDIF

      ELSE

         SELECT ( F_LD )
         IF !Used()
            RETURN .F.
         ENDIF

         SELECT ld

         IF lNovi
            delete_with_rlock()
         ENDIF

         RETURN .F.

      ENDIF

      SELECT ld
      USE

      Beep( 1 )

   ENDDO

   RETURN .T.




FUNCTION ld_rekalkulacija_primanja()

   LOCAL lSaveObracun
   LOCAL hLdRec
   LOCAL _fields
   LOCAL nI
   LOCAL nCount := 0

   // ove varijable koriste formule garant ?
   PRIVATE lNovi := .F.
   PRIVATE GetList
   PRIVATE nPlacenoRSati
   PRIVATE cIdRadn, cIdRj, nGodina, nMjesec, cObracun
   PRIVATE cPom, nPom, cIdPrimanje

   cIdRj := gLDRadnaJedinica

   cIdRadn := Space( LEN_IDRADNIK )
   GetList := {}

   IF !spec_funkcije_sifra( "LD21" )
      MsgBeep( "Opcija onemogućena !" )
      RETURN .F.
   ENDIF

   nGodina := ld_tekuca_godina()
   nMjesec := ld_tekuci_mjesec()
   cObracun := gObracun

   ld_pozicija_parobr( nMjesec, nGodina, iif( ld_vise_obracuna(), cObracun, ), cIdRj )

   seek_ld( cIdRj,  nGodina,  nMjesec,  iif( ld_vise_obracuna(), cObracun, "" ), NIL, NIL, "LD_2" )
   Box( , 5, 70 )

   DO WHILE !Eof()
      select_o_ld_radn( ld_2->idRadn )

      SELECT LD_2
      set_global_vars_from_dbf() // _i01, _s01, _i03, etc ...

      @ box_x_koord() + 1, box_y_koord() + 2  SAY8 "IDRADN: " + ld_2->idradn

      FOR nI := 1 TO cLDPolja // PUBLIC cLDPolja := 60

         cIdPrimanje := PadL( AllTrim( Str( nI ) ), 2, "0" )
         select_o_tippr( cIdPrimanje )


         IF tippr->aktivan == "D" .AND. "PAROBR" $ Upper( tippr->formula )

            _UIznos := _UIznos - _i&cIdPrimanje
            IF tippr->uneto == "D"           // izbij ovu stavku iz postojeceg obracuna
               _Uneto := _UNeto - _i&cIdPrimanje
            ELSE
               _UOdbici := _UOdbici - _i&cIdPrimanje
            ENDIF

            // preracunaj ovu stavku prema formuli

            cFormula := Trim( tippr->formula )
            IF ( tippr->fiksan <> "D" ) // ako je fiksan iznos nista ne izracunavaj!
               IF Empty( cFormula )
                  _i&cIdPrimanje := 0
               ELSE
                  _i&cIdPrimanje := &cFormula
               ENDIF
               _i&cIdPrimanje := Round( _i&cIdPrimanje, gZaok )
            ENDIF

            _UIznos += _i&cIdPrimanje               // vratiti preracunati iznos
            IF tippr->uneto == "D"
               _Uneto += _i&cIdPrimanje
            ELSE
               _UOdbici += _i&cIdPrimanje
            ENDIF

         ENDIF

      NEXT

      kalkulacija_obracuna_plate_za_radnika( lNovi )

      SELECT LD_2
      hLdRec := get_hash_record_from_global_vars()
      hLdRec[ "varobr" ] := gVarObracun

      // nPom := 0
      // FOR nI := 1 TO cLDPolja
      // cPom := PadL( AllTrim( Str( nI ) ), 2, "0" )  // cPom := 01, 02, 03 ...
      // nPom += Abs( _I&cPom ) + Abs( _S&cPom )
      // NEXT
      // IF ( nPom <> 0 ) // iznos ili vrijeme


      seek_ld( cIdRj,  nGodina,  nMjesec,  iif( ld_vise_obracuna(), cObracun, "" ), ld_2->idradn )
      IF update_rec_server_and_dbf( "ld_ld",  hLdRec, 1, "FULL" )
         // delete_with_rlock()
         // ELSE
         log_write( "REKALK obracuna plate - radnik: " + ld_2->idradn + ", mjesec: " + AllTrim( Str( ld_2->mjesec ) ) + ", godina: " + AllTrim( Str( ld_2->godina ) ), 2 )
      ENDIF
      // ENDIF
      nCount++
      SELECT LD_2
      SKIP
   ENDDO
   BoxC()

   SELECT LD_2
   USE

   MsgBeep( "rekalkulacija izvršena za " + AllTrim( Str( nCount ) ) + " radnika" )

   RETURN .T.


FUNCTION QQOUTC( cTekst, cBoja )

   @ Row(), Col() SAY cTekst COLOR cBoja

   RETURN .T.



STATIC FUNCTION ld_unos_obracuna_box( lSaveObracun )

   LOCAL nULicOdb
   LOCAL cMinRadOpis, cMinRadPict
   LOCAL cTrosk
   LOCAL cOpor
   LOCAL _radni_sati := fetch_metric( "ld_radni_sati", NIL, "N" )
   LOCAL nO_ret
   LOCAL cRadnikObracun

   cIdRadn := Space( 6 )
   nMjesec := ld_tekuci_mjesec()
   nGodina := ld_tekuca_godina()


   lLogUnos := .F.

   OObracun()

   lNovi := .F.

   Box( , f18_max_rows() - 3, f18_max_cols() - 10 )

   @ box_x_koord() + 1, box_y_koord() + 2 SAY "Radna jedinica: "
   QQOutC( cIdRJ, "GR+/N" )

   // IF gUNMjesec == "D"
   // @ box_x_koord() + 1, Col() + 2 SAY _l( "Mjesec: " )  GET nMjesec PICT "99"
   // ELSE
   @ box_x_koord() + 1, Col() + 2 SAY _l( "Mjesec: " )
   QQOutC( Str( nMjesec, 2 ), "GR+/N" )
   // ENDIF

   IF ld_vise_obracuna()
      // IF gUNMjesec == "D"
      // @ box_x_koord() + 1, Col() + 2 SAY8 _l( "Obračun: " ) GET cObracun WHEN ld_help_broj_obracuna( .F., cObracun ) VALID ld_valid_obracun( .F., cObracun )
      // ELSE
      @ box_x_koord() + 1, Col() + 2 SAY8  "Obračun: "
      QQOutC( cObracun, "GR+/N" )
      // ENDIF
   ENDIF

   @ box_x_koord() + 1, Col() + 2 SAY _l( "Godina: " )

   QQOutC( Str( nGodina, 4 ), "GR+/N" )

   @ box_x_koord() + 2, box_y_koord() + 2 SAY  "Radnik:" GET cIdRadn VALID {|| P_Radn( @cIdRadn ), SetPos( box_x_koord() + 2, box_y_koord() + 17 ), ;
      QQOut( PadR( Trim( radn->naz ) + " (" + Trim( radn->imerod ) + ") " + Trim( radn->ime ), 28 ) ), .T. }

   READ

   clvbox()

   ESC_BCR

   nO_Ret := ld_pozicija_parobr( nMjesec, nGodina, iif( ld_vise_obracuna(), cObracun, NIL ), cIdRj )

   IF nO_ret == 0

      MsgBeep( "Ne postoje unešeni parametri obračuna za " + Str( nMjesec, 2 ) + "/" + Str( nGodina, 4 ) + " !" )
      BoxC()
      RETURN .F.

   ELSEIF nO_ret == 2

      MsgBeep( "Ne postoje unešeni parametri obračuna za " + Str( nMjesec, 2 ) + "/" + Str( nGodina, 4 ) + " !" + ;
         "#Koristit ću postojeće parametre." )
   ENDIF

   SELECT radn

   cTR := get_ld_rj_tip_rada( cIdRadn, cIdRj )
   cOpor := g_oporeziv( cIdRadn, cIdrj )
   cTrosk := radn->trosk
   nULicOdb := ( radn->klo * gOsnLOdb )

   IF cTR $ "A#U#S"
      nULicOdb := 0
   ENDIF

   IF ld_vise_obracuna() .AND. cObracun <> "1"
      nULicOdb := 0
   ENDIF

   cRadnikObracun := cIdRadn + " : " + Str( nMjesec, 2, 0 ) + "/" + Str( nGodina, 4, 0 ) + "/" + cObracun

   seek_ld( cIdRj,  nGodina,  nMjesec,  iif( ld_vise_obracuna(), cObracun, "" ),  cIdRadn )

   IF !Eof()
      MsgBeep( "Već postoji obračun za radnika: " + cRadnikObracun + " !" )
      lNovi := .F.
      set_global_vars_from_dbf()
   ELSE
      lNovi := .T.
      APPEND BLANK
      set_global_vars_from_dbf()

      _godina := nGodina
      _idrj   := cIdRj
      _idradn := cIdRadn
      _mjesec := nMjesec
      _ulicodb := nULicOdb
      IF LD->( FieldPos( "TROSK" ) ) <> 0
         _trosk := cTrosk
         _opor := cOpor
      ENDIF

      IF ld_vise_obracuna()
         _obr := cObracun
      ENDIF

   ENDIF


   IF lNovi
      _brbod := radn->brbod
      _kminrad := radn->kminrad
      _idvposla := radn->idvposla
      _idstrspr := radn->idstrspr
   ENDIF

   ld_pozicija_parobr( nMjesec, nGodina, iif( ld_vise_obracuna(), cObracun, ), cIdRj )

   IF gTipObr == "1"
      @ box_x_koord() + 3, box_y_koord() + 2   SAY iif( gBodK == "1", _l( "Broj bodova" ), _l( "Koeficijent" ) ) GET _brbod PICT "99999.99" VALID FillBrBod( _brbod )
   ELSE
      @ box_x_koord() + 3, box_y_koord() + 2   SAY _l( "Plan.osnov ld" ) GET _brbod PICT "99999.99" VALID FillBrBod( _brbod )
   ENDIF

   SELECT ld

   @ box_x_koord() + 3, Col() + 2 SAY IF( gBodK == "1", _l( "Vrijednost boda" ), _l( "Vr.koeficijenta" ) ); @ Row(), Col() + 1 SAY parobr->vrbod  PICT "99999.99999"

   IF gMinR == "B"
      cMinRadOpis := "Minuli rad (bod)"
      cMinRadPict := "9999.99"
   ELSE
      cMinRadPict := "99.99%"
      cMinRadOpis := "Koef.minulog rada"
   ENDIF

   @ box_x_koord() + 3, Col() + 2 SAY cMinRadOpis GET _kminrad PICT cMinRadPict VALID set_koeficijent_minulog_rada( _kminrad )

   @ box_x_koord() + 4, box_y_koord() + 2 SAY8 "Lič.odb:" GET _ulicodb PICT "9999.99"
   @ box_x_koord() + 4, Col() + 1 SAY _l( "Vrsta posla koji radnik obavlja" ) GET _IdVPosla VALID ( Empty( _idvposla ) .OR. P_VPosla( @_IdVPosla, 4, 55 ) ) .AND. FillVPosla()

   READ

   IF _radni_sati == "D"
      @ box_x_koord() + 4, box_y_koord() + 85 SAY "R.sati:" GET _radSat
   ENDIF

   READ

   IF _radni_sati == "D"
      nSatiPreth := 0
      nSatiPreth := FillRadSati( cIdRadn, _radSat )
   ENDIF

   IF gSihtarica == "D"
      UzmiSiht()
   ENDIF

   ld_unos_obracuna_tipovi_primanja()


   SELECT ld

   kalkulacija_obracuna_plate_za_radnika( lNovi )

   ld_unos_obracuna_footer( @lSaveObracun )

   IF _radni_sati == "D" .AND. lSaveObracun == .F.
      delRadSati( cIdRadn, nSatiPreth )
   ENDIF

   BoxC()

   RETURN .T.



STATIC FUNCTION kalkulisi_uneto_usati_uiznos_za_radnika()

   LOCAL hData

   _usati := 0
   _uneto := 0
   _uiznos := 0
   _uodbici := 0

   hData := izracunaj_uneto_usati_za_radnika()

   _usati := hData[ "usati" ]
   _uneto := hData[ "uneto" ]
   _uodbici := hData[ "uodbici" ]
   _uiznos := hData[ "uneto" ] + hData[ "uodbici" ]

   RETURN NIL



STATIC FUNCTION izracunaj_ukupno_za_isplatu_za_radnika( cTipRada, cTrosk, nTrosk, lInRs )

   _uiznos := ROUND2( _uneto2 + _uodbici, gZaok2 )

   IF cTipRada $ "U#A" .AND. cTrosk <> "N"
      _uIznos := ROUND2( _uiznos + nTrosk, gZaok2 )
      IF lInRS == .T.
         _uIznos := _uneto
      ENDIF
   ENDIF

   IF cTipRada $ "S"
      _uiznos := _uneto
   ENDIF

   RETURN NIL



STATIC FUNCTION kalkulacija_obracuna_plate_za_radnika( lNovi )

   LOCAL nTArea, nI

   kalkulisi_uneto_usati_uiznos_za_radnika()

   nKLO := radn->klo
   cTipRada := get_ld_rj_tip_rada( _idradn, _idrj )
   nSPr_koef := 0
   nTrosk := 0
   nBrOsn := 0
   cOpor := " "
   cTrosk := " "
   lInRS := .F.
   lInRs := radnik_iz_rs( radn->idopsst, radn->idopsrad )

   FOR nI := 1 TO cLDPolja // 40

      cTp := PadL( AllTrim( Str( nI ) ), 2, "0" )
      xVar := "_I" + cTp

      nTArea := Select()

      select_o_tippr( cTp )

      SELECT ( nTArea )

      IF tippr->uneto == "D"
         _nakn_opor += &( xVar )
      ELSEIF tippr->uneto == "N"
         _nakn_neop += &( xVar )
      ENDIF

      SELECT ( nTArea )

   NEXT

   IF radn->( FieldPos( "opor" ) ) <> 0
      cOpor := radn->opor
   ENDIF

   IF radn->( FieldPos( "trosk" ) ) <> 0
      cTrosk := radn->trosk
   ENDIF

   IF cTipRada == "S"
      IF radn->( FieldPos( "SP_KOEF" ) ) <> 0
         nSPr_koef := radn->sp_koef
      ENDIF
   ENDIF

   IF cTipRada $ "A#U#P#S"
      _ULicOdb := 0
   ENDIF

   _UBruto := ld_get_bruto_osnova( _UNeto, cTipRada, _ULicOdb, nSPr_koef, cTrosk )

   IF cTipRada == "U" .AND. cTrosk <> "N"
      nTrosk := ROUND2( _UBruto * ( gUgTrosk / 100 ), gZaok2 )
      IF lInRS == .T.
         nTrosk := 0
      ENDIF
      _UBruto := _UBruto - nTrosk
   ENDIF

   IF cTipRada == "A" .AND. cTrosk <> "N"

      nTrosk := ROUND2( _UBruto * ( gAhTrosk / 100 ), gZaok2 )
      IF lInRS == .T.
         nTrosk := 0
      ENDIF
      _UBruto := _UBruto - nTrosk
   ENDIF

   nMinBO := _UBruto
   IF cTipRada $ " #nI#N"
      IF _I01 = 0
         // ne racunaj min.bruto osnovu
      ELSE
         nMinBO := ld_min_bruto_osnova( _UBruto, _USati )
      ENDIF
   ENDIF

   nDop := u_dopr_iz( nMinBO, cTipRada )
   _udopr := nDop
   _udop_st := 31.0
   nPorOsnovica := ( ( _ubruto - _udopr ) - _ulicodb )

   IF nPorOsnovica < 0 .OR. !radn_oporeziv( _idradn, _idrj )
      nPorOsnovica := 0
   ENDIF

   _uporez := izr_porez( nPorOsnovica, "B" )
   _upor_st := 10.0

   IF !radn_oporeziv( _idradn, _idrj )
      _uporez := 0
      _upor_st := 0
   ENDIF

   _uneto2 := Round( ( ( _ubruto - _udopr ) - _uporez ), gZaok2 )

   IF cTipRada $ " #nI#N#"
      nMinNeto := min_neto( _uneto2, _usati )
      _uneto2 := nMinNeto
   ENDIF

   izracunaj_ukupno_za_isplatu_za_radnika( cTipRada, cTrosk, nTrosk, lInRs )

   IF Round( _uneto2, 2 ) <> 0 .AND. LastKey() <> K_ESC .AND. ld_obracunaj_odbitak_za_elementarne_nepogode( lNovi )

      // zato što naknadno radimo definisanje tip primanja, moramo napraviti rekalkulaciju
      hData := izracunaj_uneto_usati_za_radnika()
      _uodbici := hData[ "uodbici" ]
      izracunaj_ukupno_za_isplatu_za_radnika( cTipRada, cTrosk, nTrosk, lInRs )

      IF lNovi
         MsgBeep( "Za radnika je obračnuat odbitak radi elementarnih nepogoda." )
      ENDIF
   ENDIF

   RETURN .T.



STATIC FUNCTION ld_unos_obracuna_footer( lSaveObracun )

   // direktno se unose globalne vars iz tabele ld: ld->usati, ld->lucodb, ... ld->uiznos

   @ box_x_koord() + 19, box_y_koord() + 2 SAY "Ukupno sati:"
   @ Row(), Col() + 1 SAY _usati PICT gPics
   @ box_x_koord() + 19, Col() + 2 SAY "Uk.lic.odb.:"
   @ Row(), Col() + 1 SAY _ulicodb PICT gPici
   @ box_x_koord() + 20, box_y_koord() + 2 SAY "Primanja:"
   @ Row(), Col() + 1 SAY _uneto PICT gPici
   @ box_x_koord() + 20, Col() + 2 SAY "Odbici:"
   @ Row(), Col() + 1 SAY _uodbici PICT gPici
   @ box_x_koord() + 20, Col() + 2 SAY "UKUPNO ZA ISPLATU:"
   @ Row(), Col() + 1 SAY _uiznos PICT gPici

   @ box_x_koord() + 21, box_y_koord() + 2 SAY "Vrsta isplate (1 - 17):" GET _v_ispl // globalna field varijabla ld->v_ispl

   @ box_x_koord() + 22, box_y_koord() + 10 SAY "Pritisni <ENTER> za snimanje, <ESC> napustanje"
   READ

   Inkey( 0 )

   DO WHILE LastKey() <> K_ESC .AND. LastKey() <> K_ENTER
      Inkey( 0 )
   ENDDO

   IF LastKey() == K_ESC
      MsgBeep( "Obračun NIJE pohranjen !" )
      lSaveObracun := .F.
   ELSE
      MsgBeep( "Obračun je pohranjen !" )
      lSaveObracun := .T.
   ENDIF

   RETURN .T.



STATIC FUNCTION ld_unos_obracuna_tipovi_primanja()

   LOCAL nI
   PRIVATE cIdTP := "  "
   PRIVATE nRedTP := 4
   PRIVATE cVarTP
   PRIVATE cIznosTP

   cTipPrC := " "

   FOR nI := 1 TO cLDPolja
      IF nI < 10
         cIdTP := "0" + AllTrim( Str( nI ) )
         cVarTP := "_S0" + AllTrim( Str( nI ) )
         cIznosTP := "_I0" + AllTrim( Str( nI ) )
         cPoljeIznos := "I0" + AllTrim( Str( nI ) )
         cPoljeSati := "S0" + AllTrim( Str( nI ) )
      ELSE
         cIdTP := AllTrim( Str( nI ) )
         cVarTP := "_S" + AllTrim( Str( nI ) )
         cIznosTP := "_I" + AllTrim( Str( nI ) )
         cPoljeIznos := "nI" + AllTrim( Str( nI ) )
         cPoljeSati := "S" + AllTrim( Str( nI ) )
      ENDIF

      nRedTP++

      select_o_tippr( cIdTP )
      SELECT ld


      cWhenLDUnos := "ld_when_unos(" + dbf_quote( cIdTp ) + ")"
      cValidLDUnos := "ld_eval_formula(@" + cIznosTP + ")"

      IF ( tippr->( Found() ) .AND. tippr->aktivan == "D" )
         IF ( tippr->fiksan $ "DN" )
            @ box_x_koord() + nRedTP, box_y_koord() + 2 SAY tippr->id + "-" + tippr->naz + " (SATI) " ;
               GET &cVarTP PICT gPics WHEN &cWhenLDUnos VALID &cValidLDUnos
         ELSEIF ( tippr->fiksan == "P" )
            @ box_x_koord() + nRedTP, box_y_koord() + 2 SAY tippr->id + "-" + tippr->naz + " (%)    " ;
               GET &cVarTP. PICT "999.99" WHEN &cWhenLDUnos VALID &cValidLDUnos
         ELSEIF tippr->fiksan == "B"
            @ box_x_koord() + nRedTP, box_y_koord() + 2 SAY tippr->id + "-" + tippr->naz + "(BODOVA)" ;
               GET &cVarTP. PICT gPici WHEN &cWhenLDUnos VALID &cValidLDUnos
         ELSEIF tippr->fiksan == "C"
            @ box_x_koord() + nRedTP, box_y_koord() + 2 SAY tippr->id + "-" + tippr->naz + "        " ;
               GET cTipPrC WHEN &cWhenLDUnos VALID &cValidLDUnos
         ENDIF

         @ box_x_koord() + nRedTP, box_y_koord() + 50 SAY "IZNOS" GET &cIznosTP PICT gPici
      ENDIF

      IF ( nI % 17 == 0 )
         READ
         @ box_x_koord() + 5, box_y_koord() + 2 CLEAR TO box_x_koord() + 21, box_y_koord() + 69
         nRedTP := 4
      ENDIF

      IF ( nI == cLDPolja )
         READ
      ENDIF

   NEXT

   RETURN .T.


/*
   Zadatak: zelimo sabrati sate iz 01, 02 tipova primanja i staviti u primanje "25"
   Rjesenje: U formulu "24" (primanje ispred "24") dodajemo: .... + set_sati_tp( "25", "_S01+_S02")
*/
FUNCTION set_sati_tp( cSatiTipPrimanja, cFormula )

   cSatiTipPrimanja := "_S" + cSatiTipPrimanja

   &cSatiTipPrimanja := &cFormula

   RETURN 0


FUNCTION ld_when_unos( cTP )

   select_o_tippr( cTP )
   SELECT LD

   RETURN .T.




FUNCTION ValRNal( cPom, nI )

   IF !Empty( cPom )
      P_fakt_objekti( @cPom )
      cRNal[ nI ] := cPom
   ENDIF

   RETURN .T.




FUNCTION OObracun()

   // select_o_ld()


   // SELECT F_PAROBR
   // IF !Used()
   // o_ld_parametri_obracuna()
   // ENDIF

   // SELECT F_RADN
   // IF !Used()
   // o_ld_radn()
   // ENDIF

   // SELECT F_VPOSLA
   // IF !Used()
   // o_ld_vrste_posla()
   // ENDIF

   // SELECT F_STRSPR
   // IF !Used()
   // o_str_spr()
   // ENDIF

   // SELECT F_DOPR
   // IF !Used()
   // o_dopr()
   // ENDIF

   // SELECT F_POR
   // IF !Used()
   // o_por()
   // ENDIF

   // SELECT F_KBENEF
   // IF !Used()
   // o_koef_beneficiranog_radnog_staza()
   // ENDIF

   // SELECT F_OPS
   // IF !Used()
   // o_ops()
   // ENDIF

   // SELECT F_LD_RJ
   // IF !Used()
   // o_ld_rj()
   // ENDIF

   // SELECT F_RADKR
   // IF !Used()
   // O_RADKR
   // ENDIF

   // SELECT F_KRED
   // IF !Used()
   // o_kred()
   // ENDIF

   // SELECT F_RADSAT
   // IF !Used()
   // O_RADSAT
   // ENDIF

   IF ( IsRamaGlas() )
      MsgBeep( "http://redmine.bring.out.ba/issues/25988" )
      QUIT_1
      o_radsiht()
      o_fakt_objekti()
   ENDIF

   set_tippr_ili_tippr2( cObracun )

   RETURN .T.
