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


FUNCTION kalk_azuriraj_sve_u_pripremi( lStampaj )
   RETURN kalk_azuriranje_dokumenta( .T., lStampaj )


FUNCTION kalk_azuriranje_dokumenta_auto_bez_stampe()
   RETURN kalk_azuriranje_dokumenta( .T., .F. )

FUNCTION kalk_azuriranje_dokumenta( lAuto, lStampaj )

   LOCAL lViseDok := .F.
   LOCAL aRezim := {}
   LOCAL aOstaju := {}
   LOCAL lGenerisiZavisne := .F.

   // LOCAL lBrStDoks := .F.

   IF lAuto == NIL
      lAuto := .F.
   ENDIF

   IF lStampaj == NIL
      lStampaj := .T.
   ENDIF

   IF !lAuto .AND. Pitanje(, "Želite li izvršiti ažuriranje KALK dokumenta (D/N) ?", "N" ) == "N"
      RETURN .F.
   ENDIF

   o_kalk_pripr()
   SELECT kalk_pripr
   GO TOP

   IF kalk_dokument_postoji( kalk_pripr->idfirma, kalk_pripr->idvd, kalk_pripr->brdok )
      MsgBeep( "Dokument " + kalk_pripr->idfirma + "-" + kalk_pripr->idvd + "-" + ;
         AllTrim( kalk_pripr->brdok ) + " već postoji u bazi !#Promjenite broj dokumenta pa ponovite proceduru ažuriranja." )
      RETURN .F.
   ENDIF

   SELECT kalk_pripr
   GO TOP

   IF !provjeri_redni_broj()
      MsgBeep( "Redni brojevi dokumenta nisu ispravni !" )
      RETURN .F.
   ENDIF

   o_kalk_pripr2()
   my_dbf_zap()
   USE

   lViseDok := kalk_provjeri_duple_dokumente( @aRezim )

   o_kalk_za_azuriranje( .T. )

   // SELECT kalk_doks
   // IF FieldPos( "ukstavki" ) <> 0
   // lBrStDoks := .T.
   // ENDIF

   IF nije_dozvoljeno_azuriranje_sumnjivih_stavki() .AND. !kalk_provjera_integriteta( @aOstaju, lViseDok )
      RETURN .F.
   ENDIF

   IF !kalk_provjera_cijena()
      RETURN .F.
   ENDIF

   lGenerisiZavisne := kalk_check_generisati_zavisne_dokumente( lAuto )

   IF lGenerisiZavisne
      kalk_nivelacija_11()
      kalk_generisi_prijem16_iz_otpreme96()
      kalk_13_to_11()
      kalk_generisi_95_za_manjak_16_za_visak()
   ENDIF

   IF !kalk_azur_sql()
      MsgBeep( "Neuspješno ažuriranja KALK dokumenta u SQL bazu !" )
      RETURN .F.
   ENDIF

   DokAttr():new( "kalk", F_KALK_ATTR ):zap_attr_dbf()

   kalk_gen_zavisni_fin_fakt_nakon_azuriranja( lGenerisiZavisne, lAuto, lStampaj )

   IF lViseDok == .T. .AND. Len( aOstaju ) > 0
      kalk_ostavi_samo_duple( aOstaju )
   ELSE
      SELECT kalk_pripr
      my_dbf_zap()
   ENDIF

   IF lGenerisiZavisne == .T.
      kalk_vrati_iz_pripr2()
   ENDIF

   my_close_all_dbf()

   RETURN .T.



STATIC FUNCTION kalk_vrati_iz_pripr2()

   LOCAL lPrebaci := .F.
   LOCAL hRec

   o_kalk_pripr()
   o_kalk_pripr2()

   IF field->idvd $ "18#19"
      IF kalk_pripr2->( reccount2() ) <> 0
         Beep( 1 )
         Box(, 4, 70 )
         @ box_x_koord() + 1, box_y_koord() + 2 SAY "1. Cijene robe su promijenjene."
         @ box_x_koord() + 2, box_y_koord() + 2 SAY "2. Formiran je dokument nivelacije:" + kalk_pripr2->( idfirma + "-" + idvd + "-" + brdok )
         @ box_x_koord() + 3, box_y_koord() + 2 SAY8 "3. Nove cijene su stavljene u šifarnik."
         @ box_x_koord() + 4, box_y_koord() + 2 SAY "4. Obradite ovaj dokument."
         Inkey( 0 )
         BoxC()
         lPrebaci := .T.
      ENDIF

   ELSEIF field->idvd $ "95"
      IF kalk_pripr2->( reccount2() ) <> 0
         Beep( 1 )
         Box(, 4, 70 )
         @ box_x_koord() + 1, box_y_koord() + 2 SAY "1. Formiran je dokument 95 na osnovu inventure."
         @ box_x_koord() + 4, box_y_koord() + 2 SAY "3. Obradite ovaj dokument."
         Inkey( 0 )
         BoxC()
         lPrebaci := .T.
      ENDIF

   ELSEIF field->idvd $ "16" .AND. gGen16 == "1"

      IF kalk_pripr2->( reccount2() ) <> 0 // nakon otpreme doprema
         Beep( 1 )
         Box(, 4, 70 )
         @ box_x_koord() + 1, box_y_koord() + 2 SAY "1. Roba je otpremljena u magacin " + kalk_pripr2->idkonto
         @ box_x_koord() + 2, box_y_koord() + 2 SAY "2. Formiran je dokument dopreme:" + kalk_pripr2->( idfirma + "-" + idvd + "-" + brdok )
         @ box_x_koord() + 3, box_y_koord() + 2 SAY "3. Obradite ovaj dokument."
         Inkey( 0 )
         BoxC()
         lPrebaci := .T.
      ENDIF

   ELSEIF field->idvd $ "11"
      // nakon povrata unos u drugu prodavnicu
      IF kalk_pripr2->( reccount2() ) <> 0
         Beep( 1 )
         Box(, 4, 70 )
         @ box_x_koord() + 1, box_y_koord() + 2 SAY "1. Roba je prenesena u prodavnicu " + kalk_pripr2->idkonto
         @ box_x_koord() + 2, box_y_koord() + 2 SAY8 "2. Formiran je dokument zaduženja:" + kalk_pripr2->( idfirma + "-" + idvd + "-" + brdok )
         @ box_x_koord() + 3, box_y_koord() + 2 SAY "3. Obradite ovaj dokument."
         Inkey( 0 )
         BoxC()
         lPrebaci := .T.
      ENDIF
   ENDIF

   IF lPrebaci == .T.

      SELECT kalk_pripr2
      DO WHILE !Eof()

         hRec := dbf_get_rec()
         SELECT kalk_pripr
         APPEND BLANK
         dbf_update_rec( hRec )
         SELECT kalk_pripr2
         SKIP

      ENDDO

      SELECT kalk_pripr2
      my_dbf_zap()

   ENDIF

   RETURN .T.


/*
   generisanje zavisnih dokumenata (fin, fakt) nakon azuriranja kalkulacije
   mozda cemo dobiti i nove dokumente u pripremi
*/

STATIC FUNCTION kalk_gen_zavisni_fin_fakt_nakon_azuriranja( lGenerisi, lAuto, lStampa )

   LOCAL lForm11 := .F.
   LOCAL cNext11 := ""
   LOCAL lgAFin := gAFin
   LOCAL lgAMat := gAMat

   o_kalk_za_azuriranje()

   IF kalk_generisati_11()
      lForm11 := .T.
      cNext11 := kalk_get_next_broj_v5( self_organizacija_id(), "11", NIL )
      kalk_gen_11_iz_10( cNext11 )
   ENDIF


   IF lGenerisi
      kalk_kontiranje_gen_finmat()
      kalk_generisi_finansijski_nalog( lAuto, lStampa )

      gAFin := lgAFin
      gAMat := lgAMat
      kalk_generisi_fakt_dokument()

   ENDIF

   IF lForm11
      kalk_get_11_from_pripr9_smece( cNext11 )
   ENDIF

   RETURN .T.



STATIC FUNCTION kalk_generisi_fakt_dokument()

   LOCAL cOdg := "D"

   o_kalk_pripr()

   IF !f18_use_module( "fakt" )
      RETURN .F.
   ENDIF

   IF gAFakt != "D"
      RETURN .F.
   ENDIF

   IF field->idvd $ "10#12#13#16#11#95#96#97#PR#RN"

      IF field->idvd $ "16#96"
         cOdg := "N"
      ENDIF

      IF Pitanje(, "Formirati dokument u FAKT ?", cOdg ) == "D"
         kalk_prenos_fakt()
         o_kalk_za_azuriranje()
      ENDIF

   ENDIF

   RETURN .T.


// ----------------------------------------------------------------
// ova opcija ce pobrisati iz pripreme samo one dokumente koji
// postoje medju azuriranim
// ----------------------------------------------------------------
STATIC FUNCTION kalk_ostavi_samo_duple( lViseDok, aOstaju )

   SELECT kalk_pripr // izbrisi samo azurirane

   GO TOP
   my_flock()
   DO WHILE !Eof()
      SKIP 1
      nRecNo := RecNo()
      SKIP -1
      IF AScan( aOstaju, field->idfirma + field->idvd + field->brdok ) = 0
         DELETE
      ENDIF
      GO ( nRecNo )
   ENDDO
   my_unlock()
   my_dbf_pack()

   MsgBeep( "U kalk_pripremi su ostali dokumenti koji izgleda da vec postoje medju azuriranim!" )

   RETURN .T.



STATIC FUNCTION kalk_check_generisati_zavisne_dokumente( lAuto )

   LOCAL lGen := .F.

   IF nije_dozvoljeno_azuriranje_sumnjivih_stavki()
      lGen := .T.
   ELSE
      IF kalk_metoda_nc() == " "
         lGen := .F.
      ELSEIF lAuto == .T.
         lGen := .T.
      ELSE
         lGen := Pitanje(, "Želite li formirati zavisne dokumente pri ažuriranju (D/N) ?", "D" ) == "D"
      ENDIF
   ENDIF

   RETURN lGen



STATIC FUNCTION kalk_provjera_cijena()

   LOCAL cIdFirma
   LOCAL cIdVd
   LOCAL cBrDok

   o_kalk_pripr()

   SELECT kalk_pripr
   GO TOP

   DO WHILE !Eof()

      cIdFirma := field->idfirma
      cIdVd := field->idvd
      cBrDok := field->brdok

      DO WHILE !Eof() .AND. cIdfirma == field->idfirma .AND. cIdvd == field->idvd .AND. cBrdok == field->brdok
         IF field->idvd == "11" .AND. field->vpc == 0
            Beep( 1 )
            Msg( 'VPC = 0, pozovite "savjetnika" sa <Alt-H>!' )
            my_close_all_dbf()
            RETURN .F.
         ENDIF
         SKIP
      ENDDO

      SELECT kalk_pripr

   ENDDO

   RETURN .T.


STATIC FUNCTION kalk_provjera_integriteta( aDoks, lViseDok )

   LOCAL nBrDoks
   LOCAL cIdFirma
   LOCAL cIdVd
   LOCAL cBrDok
   LOCAL dDatDok
   LOCAL cIdZaduz2

   o_kalk_za_azuriranje()

   SELECT kalk_pripr
   GO TOP

   nBrDoks := 0

   DO WHILE !Eof()

      ++nBrDoks

      cIdFirma := field->idfirma
      cIdVd := field->idvd
      cBrDok := field->brdok
      dDatDok := field->datdok
      cIdzaduz2 := field->idzaduz2

      DO WHILE !Eof() .AND. cIdFirma == field->idfirma .AND. cIdVd == field->idvd .AND. cBrdok == field->brdok

         IF kalk_metoda_nc() <> " " .AND. ( field->error == "1" .AND. field->tbanktr == "X" )
            Beep( 2 )
            MSG( "Izgenerisane stavke su ispravljane, ažuriranje neće biti izvršeno !", 6 )
            my_close_all_dbf()
            RETURN .F.
         ENDIF

         IF kalk_metoda_nc() <> " " .AND. field->error == "1"
            Beep( 2 )
            MSG( "Utvrđena greška pri obradi dokumenta, rbr: " + field->rbr, 6 )
            my_close_all_dbf()
            RETURN .F.
         ENDIF

         // TODO: cleanup sumnjive stavke
         // IF kalk_metoda_nc() <> " " .AND. field->error == " "
         //
         // MsgBeep( "Dokument je izgenerisan, pokrenuti opciju <A> za obradu", 6 )
         // my_close_all_dbf()
         // RETURN .F.
         // ENDIF

         IF dDatDok <> field->datdok
            Beep( 2 )
            IF Pitanje(, "Datum različit u odnosu na prvu stavku. Ispraviti (D/N) ?", "D" ) == "D"
               RREPLACE field->datdok WITH dDatDok
            ELSE
               my_close_all_dbf()
               RETURN .F.
            ENDIF
         ENDIF

         IF field->idvd <> "24" .AND. Empty( field->mu_i ) .AND. Empty( field->pu_i )
            Beep( 2 )
            Msg( "Stavka broj " + field->rbr + ". neobrađena (pu_i, mu_i), sa <A> pokrenite obradu" )
            my_close_all_dbf()
            RETURN .F.
         ENDIF

         IF cIdzaduz2 <> field->idzaduz2
            Beep( 2 )
            Msg( "Stavka broj " + field->rbr + ". različito polje RN u odnosu na prvu stavku" )
            my_close_all_dbf()
            RETURN .F.
         ENDIF

         SKIP

      ENDDO

      IF find_kalk_doks_by_broj_dokumenta( cIdFirma, cIdvd, cBrDok )
         error_bar( cIdfirma + "-" + cIdvd + "-" + cBrdok, "Postoji dokument na stanju: " + cIdFirma + "-" + cIdvd + "-" + AllTrim( cBrDok ) )
         IF !lViseDok
            my_close_all_dbf()
            RETURN .F.
         ELSE
            AAdd( aDoks, cIdFirma + cIdVd + cBrDok )
         ENDIF
      ENDIF

      SELECT kalk_pripr

   ENDDO

   IF kalk_metoda_nc() <> " " .AND. nBrDoks > 1
      Beep( 1 )
      Msg( "U pripremi se nalazi više dokumenata.#Prebaci ih u smeće, pa obradi pojedinačno." )
      my_close_all_dbf()
      RETURN .F.
   ENDIF

   my_close_all_dbf()

   RETURN .T.



STATIC FUNCTION kalk_provjeri_duple_dokumente( aRezim )

   LOCAL lViseDok := .F.

   o_kalk_pripr()
   GO BOTTOM

   cTest := field->idfirma + field->idvd + field->brdok
   GO TOP

   // TODO: cleanup vise dokumenata u pripreme
   IF cTest <> field->idfirma + field->idvd + field->brdok
      // Beep( 1 )
      // Msg( "U pripremi je vise dokumenata! Ukoliko želite da ih ažurirate sve#" + ;
      // "odjednom (npr.ako ste ih preuzeli sa drugog racunara putem diskete)#" + ;
      // "na sljedeće pitanje odgovorite sa 'D' i dokumenti ce biti ažurirani#" + ;
      // "bez provjera koje se vrše pri redovnoj obradi podataka." )
      // IF Pitanje(, "Želite li bezuslovno dokumente azurirati? (D/N)", "N" ) == "D"

      lViseDok := .T.
      aRezim := {}

      // AAdd( aRezim, gCijene )
      // AAdd( aRezim, kalk_metoda_nc() )
      // gCijene   := "1"
      // kalk_metoda_nc() := " "
      // ENDIF

   ELSEIF nije_dozvoljeno_azuriranje_sumnjivih_stavki()
      // ako je samo jedan dokument u kalk_pripremi

      DO WHILE !Eof()

         // TODO: cleanup sumnjive stavke
         IF field->ERROR == "1"
            error_bar( field->idfirma + "-" + field->idvd + "-" + field->brdok, " /  Rbr." + field->rbr + " sumnjiva! " )
            IF Pitanje(, "Želite li dokument ažurirati bez obzira na sumnjive stavke? (D/N)", "N" ) == "D"
               aRezim := {}
               // AAdd( aRezim, gCijene )
               // AAdd( aRezim, kalk_metoda_nc() )
               // gCijene   := "1"
            ENDIF
            EXIT
         ENDIF
         SKIP 1
      ENDDO

   ENDIF

   RETURN lViseDok



FUNCTION o_kalk_za_azuriranje( lRasporedTr )

   IF lRasporedTr == NIL
      lRasporedTr := .F.
   ENDIF

   my_close_all_dbf()
   o_kalk_pripr()
   // o_kalk()
   // o_kalk_doks2()
   // o_kalk_doks()

   IF lRasporedTr
      kalk_raspored_troskova_azuriranje()
   ENDIF

   RETURN .T.


STATIC FUNCTION kalk_raspored_troskova_azuriranje()

   SELECT kalk_pripr

   IF ( ( field->tprevoz == "R" .OR. field->TCarDaz == "R" .OR. field->TBankTr == "R" .OR. ;
         field->TSpedTr == "R" .OR. field->TZavTr == "R" ) .AND. field->idvd $ "10#81" )  .OR. ;
         field->idvd $ "RN"

      // o_sifk()
      // o_sifv()
      // select_o_roba()
      // o_tarifa()
      // o_koncij()

      SELECT kalk_pripr
      kalk_raspored_troskova( .T. )

   ENDIF

   RETURN .T.



STATIC FUNCTION kalk_azur_sql()

   LOCAL lOk := .T.
   LOCAL lRet := .F.
   LOCAL hRecKalkDok, hRecKalkKalk
   LOCAL _doks_nv := 0
   LOCAL _doks_vpv := 0
   LOCAL _doks_mpv := 0
   LOCAL _doks_rabat := 0
   LOCAL _tbl_kalk
   LOCAL _tbl_doks
   LOCAL nI, _n
   LOCAL _tmp_id
   LOCAL _ids := {}
   LOCAL _ids_kalk := {}
   LOCAL _ids_doks := {}
   LOCAL _log_dok := "0"
   LOCAL oAttr
   LOCAL hParams
   LOCAL bDokument := {| cIdFirma, cIdVd, cBrDok |   cIdFirma == field->idFirma .AND. ;
      cIdVd == field->IdVd .AND. cBrDok == field->BrDok }
   LOCAL cIdVd, cIdFirma, cBrDok

   _tbl_kalk := "kalk_kalk"
   _tbl_doks := "kalk_doks"

   Box(, 5, 60 )

   _tmp_id := "x"

   o_kalk_za_azuriranje()

   run_sql_query( "BEGIN" )

/*
   IF !f18_lock_tables( { _tbl_kalk, _tbl_doks }, .T. )
      run_sql_query( "ROLLBACK" )
      MsgBeep( "Ne mogu zaključati tabele !#Prekidam operaciju." )
      RETURN lRet
   ENDIF
*/

   o_kalk()  // otvoriti samo radi strukture tabele
   o_kalk_doks() // otvoriti samo radi strukture tabele

   SELECT kalk_pripr
   GO TOP


   @ box_x_koord() + 1, box_y_koord() + 2 SAY "kalk_kalk -> server: " + _tmp_id

   DO WHILE !Eof()

      cIdFirma := field->idFirma
      cIdVd := field->idVd
      cBrDok := field->brDok
      hRecKalkDok := hb_Hash()
      hRecKalkDok[ "idfirma" ] := cIdFirma
      hRecKalkDok[ "idvd" ] := cIdVd
      hRecKalkDok[ "brdok" ] := cBrDok
      hRecKalkDok[ "datdok" ] := field->datdok
      hRecKalkDok[ "brfaktp" ] := field->brfaktp
      hRecKalkDok[ "idpartner" ] := field->idpartner
      hRecKalkDok[ "idzaduz" ] := field->idzaduz
      hRecKalkDok[ "idzaduz2" ] := field->idzaduz2
      hRecKalkDok[ "pkonto" ] := field->pkonto
      hRecKalkDok[ "mkonto" ] := field->mkonto
      hRecKalkDok[ "podbr" ] := field->podbr
      hRecKalkDok[ "sifra" ] := Space( 6 )

      _tmp_id := hRecKalkDok[ "idfirma" ] + hRecKalkDok[ "idvd" ] + hRecKalkDok[ "brdok" ]
      AAdd( _ids_kalk, "#2" + _tmp_id )  // kalk_kalk brisi sve stavke za jedan dokument
      _log_dok := hRecKalkDok[ "idfirma" ] + "-" + hRecKalkDok[ "idvd" ] + "-" + hRecKalkDok[ "brdok" ]

      DO WHILE !Eof() .AND.  Eval( bDokument, cIdFirma, cIdVd, cBrDok )

         kalk_set_doks_total_fields( @_doks_nv, @_doks_vpv, @_doks_mpv, @_doks_rabat )

         hRecKalkKalk := dbf_get_rec()
         IF !sql_table_update( "kalk_kalk", "ins", hRecKalkKalk )
            lOk := .F.
            EXIT
         ENDIF

         IF hRecKalkKalk[ "idvd" ] == "97"
            hRecKalkKalk[ "tbanktr" ] := "X"
            hRecKalkKalk[ "mkonto" ] := hRecKalkKalk[ "idkonto" ]
            hRecKalkKalk[ "mu_i" ] := "1"
            hRecKalkKalk[ "rbr" ] := PadL( Str( 900 + Val( AllTrim( hRecKalkKalk[ "rbr" ] ) ), 3 ), 3 )

            IF !sql_table_update( "kalk_kalk", "ins", hRecKalkKalk )
               lOk := .F.
               EXIT
            ENDIF
         ENDIF
         SKIP
      ENDDO


      IF lOk

         hRecKalkDok[ "nv" ] := _doks_nv
         hRecKalkDok[ "vpv" ] := _doks_vpv
         hRecKalkDok[ "rabat" ] := _doks_rabat
         hRecKalkDok[ "mpv" ] := _doks_mpv

         _tmp_id := hRecKalkDok[ "idfirma" ] + hRecKalkDok[ "idvd" ] + hRecKalkDok[ "brdok" ]
         AAdd( _ids_doks, _tmp_id )

         @ box_x_koord() + 2, box_y_koord() + 2 SAY "kalk_doks -> server: " + _tmp_id
         IF !sql_table_update( "kalk_doks", "ins", hRecKalkDok )
            lOk := .F.
         ENDIF

      ENDIF

      IF lOk
         @ box_x_koord() + 3, box_y_koord() + 2 SAY "kalk_atributi -> server "
         oAttr := DokAttr():new( "kalk", F_KALK_ATTR )
         oAttr:hAttrId[ "idfirma" ] := hRecKalkDok[ "idfirma" ]
         oAttr:hAttrId[ "idtipdok" ] := hRecKalkDok[ "idvd" ]
         oAttr:hAttrId[ "brdok" ] := hRecKalkDok[ "brdok" ]
         lOk := oAttr:push_attr_from_dbf_to_server()
      ENDIF

   ENDDO


   IF !lOk

      run_sql_query( "ROLLBACK" )
      _msg := "kalk ažuriranje, trasakcija " + _tmp_id + " neuspješna ?!"
      log_write( _msg, 2 )
      MsgBeep( _msg )

   ELSE

      @ box_x_koord() + 4, box_y_koord() + 2 SAY "push ids to semaphore"
      push_ids_to_semaphore( _tbl_kalk, _ids_kalk )
      push_ids_to_semaphore( _tbl_doks, _ids_doks  )
      @ box_x_koord() + 5, box_y_koord() + 2 SAY "update semaphore version"

      hParams := hb_Hash()
      hParams[ "unlock" ] := { _tbl_kalk, _tbl_doks }
      run_sql_query( "COMMIT", hParams )

      log_write( "F18_DOK_OPER: ažuriranje kalk dokumenta: " + _log_dok, 2 )

   ENDIF

   BoxC()

   RETURN lOk




FUNCTION kalk_dokumenti_iz_pripreme_u_matricu()

   LOCAL aKalkDokumenti := {}
   LOCAL nScan

   SELECT kalk_pripr
   GO TOP

   DO WHILE !Eof()

      nScan := AScan( aKalkDokumenti, {| aVar | aVar[ 1 ] == field->idfirma .AND. aVar[ 2 ] == field->idvd .AND. aVar[ 3 ] == field->brdok  } )

      IF nScan == 0
         AAdd( aKalkDokumenti, { field->idfirma, field->idvd, field->brdok, 0 } )
      ENDIF

      SKIP

   ENDDO

   RETURN aKalkDokumenti
