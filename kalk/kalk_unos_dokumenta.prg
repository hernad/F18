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
#include "f18_color.ch"

#define BOX_HEIGHT (f18_max_rows() - 8)
#define BOX_WIDTH  (f18_max_cols() - 6)

THREAD STATIC pIdlePause
THREAD STATIC s_lAsistentStart := .F. // asistent pokrenut
THREAD STATIC s_lAsistentPause := .F. // asistent u stanju pauze
THREAD STATIC s_nAsistentPauseSeconds := 0
THREAD STATIC s_nKalkEditLastKey := 0

MEMVAR GetList
MEMVAR _TBankTr
MEMVAR PicDEM, PicProc, PicCDem, PicKol, gPICPROC, nKalkStrana
MEMVAR ImeKol, Kol
MEMVAR picv
MEMVAR gBrojacKalkulacija
MEMVAR Ch
MEMVAR opc, Izbor, h

MEMVAR aPorezi
MEMVAR _idfirma, _idvd, _brdok, _datdok, _mkonto, _pkonto, _idkonto, _idkonto2, _vpc, _nc, _mpcsapp, _kolicina
MEMVAR _TMarza
MEMVAR cSection, cHistory, aHistory
MEMVAR nKalkRBr, _rbr
MEMVAR nVPV16, nMPV80, nNVPredhodna
MEMVAR _ERROR


STATIC cENTER := Chr( K_ENTER ) + Chr( K_ENTER ) + Chr( K_ENTER )

FUNCTION kalk_header_get1( lNoviDokument )

   LOCAL GetList := {}

   // LOCAL cOpisDokumenta := SPACE(100)

   IF lNoviDokument
      _idfirma := self_organizacija_id()
   ENDIF

   IF lNoviDokument .AND. _TBankTr == "X"
      _TBankTr := "%"
   ENDIF

   @  box_x_koord() + 1, box_y_koord() + 2 SAY "cIdFirma: "
   ?? self_organizacija_id(), "-", self_organizacija_naziv()
   @  box_x_koord() + 2, box_y_koord() + 2 SAY "KALKULACIJA: "
   @  box_x_koord() + 2, Col() SAY "Vrsta:" GET _idvd VALID P_TipDok( @_idvd, 2, 25 ) PICT "@!"

   READ

   ESC_RETURN 0

   IF lNoviDokument .AND. gBrojacKalkulacija == "D" .AND. ( _idfirma <> kalk_pripr->idfirma .OR. _idvd <> kalk_pripr->idvd )
      _brDok := get_kalk_brdok( _idfirma, _idvd, @_idkonto, @_idkonto2 )
      AltD()
      SELECT kalk_pripr
   ENDIF

   @ box_x_koord() + 2, box_y_koord() + 40  SAY "Broj:" GET _brdok VALID {|| !kalk_dokument_postoji( _idfirma, _idvd, _brdok ) }
   @ box_x_koord() + 2, Col() + 2 SAY "Datum:" GET _datdok VALID {||  datum_not_empty_upozori_godina( _datDok, "Datum KALK" ) }
   @ box_x_koord() + 3, box_y_koord() + 2  SAY "Rbr:" GET nKalkRBr PICT '9999' VALID {|| valid_kalk_rbr_stavke( _idvd ) }

   // IF nKalkRbr == 1 .AND. !is_kalk_asistent_started()
   // @ Row(), Col() + 2 SAY8 "Opis:" GET cOpisDokumenta PICT "@S52"
   // ENDIF

   READ
   ESC_RETURN 0

   RETURN 1


FUNCTION kalk_pripr_obrada_stavki_sa_asistentom()

   RETURN kalk_pripr_obrada( .T. ) // kalk unos sa pozovi asistenta


FUNCTION kalk_pripr_obrada( lAsistentObrada )

   LOCAL nMaxCol := f18_max_cols() - 3
   LOCAL nMaxRow := f18_max_rows() - 4
   LOCAL nI
   LOCAL cOpcijaRed, nWidth
   LOCAL cSeparator := hb_UTF8ToStrBox( BROWSE_COL_SEP )
   LOCAL cPicKol := "999999.999"
   LOCAL bPodvuci := {|| iif( field->ERROR == "1", .T., .F. ) }

   hb_default( @lAsistentObrada, .F. )
   o_kalk_edit()
   kalk_is_novi_dokument( .F. )

   PRIVATE PicCDEM := kalk_pic_cijena_bilo_gpiccdem()
   PRIVATE PicProc := gPicProc
   PRIVATE PicDEM := kalk_pic_iznos_bilo_gpicdem()
   PRIVATE Pickol := kalk_pic_kolicina_bilo_gpickol()
   PRIVATE PicV := "99999999.9"

   PRIVATE ImeKol := {}
   PRIVATE Kol := {}

   AAdd( ImeKol, { "F.", {|| my_dbSelectArea( F_KALK_PRIPR ), field->idfirma   }, "idfirma"   } )
   AAdd( ImeKol, { "VD", {|| field->IdVD                      }, "IdVD"        } )
   AAdd( ImeKol, { "BrDok", {|| field->BrDok                  }, "BrDok"       } )
   AAdd( ImeKol, { "R.Br", {|| field->Rbr                     }, "Rbr"         } )
   AAdd( ImeKol, { "Dat.Kalk", {|| field->DatDok              }, "DatDok"      } )
   //AAdd( ImeKol, { "Dat.Fakt", {|| field->DatFaktP            }, "DatFaktP"    } )
   AAdd( ImeKol, { "K.mag. ", {|| field->mkonto               }, "mKonto"     } )
   AAdd( ImeKol, { "K.prod.", {|| field->pkonto               }, "pKonto"    } )
   AAdd( ImeKol, { "IdRoba", {|| field->IdRoba                }, "IdRoba"      } )
   IF roba_barkod_pri_unosu()
      AAdd( ImeKol, { "Barkod", {|| roba_ocitaj_barkod( field->idroba ) }, "IdRoba" } )
   ENDIF
   AAdd( ImeKol, { _u( "Količina" ), {|| say_kolicina( field->Kolicina, "99999.999" ) }, "kolicina"    } )
   AAdd( ImeKol, { "IdTarifa", {|| field->idtarifa }, "idtarifa"    } )
   AAdd( ImeKol, { "F.Cj.", {|| say_cijena( field->FCJ, "99999.999" ) }, "fcj"         } )
   AAdd( ImeKol, { "Nab.Cj.", {|| say_cijena( field->NC, "99999.999" ) }, "nc"          } )
   AAdd( ImeKol, { "VPC", {|| say_cijena( field->VPC, "99999.999" ) }, "vpc"         } )
   AAdd( ImeKol, { "MPC", {|| say_cijena( field->MPC, "99999.999" )  }, "mpc"         } )
   AAdd( ImeKol, { "MPCsaPDV", {|| say_cijena( field->MPCSaPP, "99999.999" )  }, "mpcsapp"     } )
   AAdd( ImeKol, { "Br.Fakt", {|| field->brfaktp }, "brfaktp"     } )
   AAdd( ImeKol, { "Partner", {|| field->idpartner }, "idpartner"   } )
   AAdd( ImeKol, { "E", {|| field->error },  "error"       } )

   FOR nI := 1 TO Len( ImeKol )
      AAdd( Kol, nI )
   NEXT

   Box(, nMaxRow, nMaxCol )

   nWidth := nMaxCol / 4  - 1
   cOpcijaRed :=  _upadr( "<c+N> Nova stavka", nWidth ) + cSeparator
   cOpcijaRed +=  _upadr( "<ENT> Ispravka", nWidth ) + cSeparator
   cOpcijaRed +=  _upadr( "<c+T> Briši stavku", nWidth ) + cSeparator
   cOpcijaRed +=  _upadr( "<K> Kalk.cijena",  nWidth ) + cSeparator

   @ box_x_koord() + nMaxRow - 3, box_y_koord() + 2 SAY8 cOpcijaRed
   cOpcijaRed :=  _upadr( "<c+A> Ispravka", nWidth ) + cSeparator
   cOpcijaRed +=  _upadr( "<c+P> Štampa dok.", nWidth ) + cSeparator
   cOpcijaRed +=  _upadr( "<a+A>|<X> Ažuriranje", nWidth ) + cSeparator
   cOpcijaRed +=  _upadr( "<Q> Etikete", nWidth )  + cSeparator

   @ box_x_koord() + nMaxRow - 2, box_y_koord() + 2 SAY8 cOpcijaRed
   cOpcijaRed := _upadr( "<a+K> Kontiranje", nWidth ) + cSeparator
   cOpcijaRed += _upadr( "<c+F9> Briši sve", nWidth ) + cSeparator
   cOpcijaRed += _upadr( "<a+P> Štampa pripreme", nWidth ) + cSeparator
   cOpcijaRed += _upadr( "<E> greške, <I> info", nWidth ) + cSeparator

   @ box_x_koord() + nMaxRow - 1, box_y_koord() + 2 SAY8 cOpcijaRed
   cOpcijaRed := _upadr( "<c+F8> Rasp.troškova", nWidth ) + cSeparator
   cOpcijaRed += _upadr( "<A> Asistent", nWidth ) + cSeparator
   cOpcijaRed += _upadr( "<F10> Dodatne opc.", nWidth ) + cSeparator

   @ box_x_koord() + nMaxRow, box_y_koord() + 2 SAY8 cOpcijaRed

   pIdlePause  := hb_idleAdd( {|| kalk_asistent_pause_handler( lAsistentObrada ) } )

   IF lAsistentObrada
      KEYBOARD Chr( K_LEFT )
   ENDIF
   my_browse( "PNal", nMaxRow, nMaxCol, {| lPrviPoziv | kalk_pripr_key_handler( lAsistentObrada ) }, "<F5>-kartica magacin, <F6>-kartica prodavnica", "Priprema...", , , , bPodvuci, 4 )

   BoxC()

   @ f18_max_rows(), 1 SAY Space( 12 ) // standardni handleri, pausa out
   hb_idleDel( pIdlePause )

   IF lAsistentObrada .AND. !kalk_asistent_pause()
      kalk_asistent_stop()
   ENDIF

   RETURN .T.


FUNCTION kalk_pripr_key_handler( lAsistentObrada )

   LOCAL cLogInfo
   LOCAL hRec
   LOCAL cStavka

   hb_default( @lAsistentObrada, .F. )

   IF lAsistentObrada .AND. !kalk_asistent_pause()
      kalk_asistent_start()
      IF !kalk_asistent_pause()
         kalk_asistent_send_esc() // prekid browse funkcije
         RETURN DE_ABORT
      ENDIF
   ENDIF

   IF ( Ch == K_CTRL_T .OR. Ch == K_ENTER ) .AND. Eof()
      RETURN DE_CONT
   ENDIF

   select_o_kalk_pripr()
   kalk_edit_last_key( Ch )

   DO CASE

   CASE Upper( Chr( Ch ) ) == "C" // Asistent Continue
      RETURN DE_CONT

   CASE Ch == K_ALT_K
      RETURN kalk_kontiraj_alt_k()

   CASE Ch == K_SH_F9
      renumeracija_kalk_pripr( NIL, NIL, .F. )
      RETURN DE_REFRESH

   CASE Ch == K_SH_F8
      IF kalk_pripr_brisi_od_do()
         RETURN DE_REFRESH
      ENDIF

   CASE Ch == K_ALT_L

      my_close_all_dbf()
      fakt_labeliranje_barkodova()
      o_kalk_edit()

      RETURN DE_REFRESH

   CASE Upper( Chr( Ch ) ) == "Q"

      IF Pitanje(, "Štampa naljepnica za robu (D/N) ?", "D" ) == "D"
         kalk_roba_naljepnice_stampa()
         o_kalk_edit()
         GO TOP
         RETURN DE_REFRESH

      ENDIF

      RETURN DE_CONT

   CASE is_key_alt_a( Ch ) .OR. Ch == Asc( 'x' ) .OR. Ch == Asc( 'X' )

      hRec := dbf_get_rec()
      my_close_all_dbf()
      kalk_azuriranje_dokumenta( .F. )  // .F. - lAuto - postaviti pitanja, hoces-neces uravnoteziti, stampati
      kalk_last_dok_info( hRec )
      o_kalk_edit()

      RETURN DE_REFRESH

   CASE Ch == K_CTRL_P
      my_close_all_dbf()
      kalk_stampa_dokumenta_priprema()
      my_close_all_dbf()
      o_kalk_edit()

      RETURN DE_REFRESH

   CASE Ch == K_CTRL_T
      IF Pitanje(, "Želite izbrisati ovu stavku (D/N) ?", "D" ) == "D"
         cLogInfo := kalk_pripr->idfirma + "-" + kalk_pripr->idvd + "-" + kalk_pripr->brdok
         cStavka := kalk_pripr->rbr
         // cArtikal := kalk_pripr->idroba
         // nKolicina := kalk_pripr->kolicina
         // nNc := kalk_pripr->nc
         // nVpc := kalk_pripr->vpc
         my_delete()
         log_write( "F18_DOK_OPER: kalk, brisanje stavke u pripremi: " + cLogInfo + " stavka br: " + cStavka, 2 )
         RETURN DE_REFRESH
      ENDIF

      RETURN DE_CONT


   CASE Ch == K_ENTER
      kalk_is_novi_dokument( .F. )
      RETURN kalk_ispravka_postojeca_stavka()

   CASE Ch == K_CTRL_N
      kalk_is_novi_dokument( .T. )
      RETURN kalk_unos_nova_stavka()

   CASE ( Ch == K_CTRL_A )
      RETURN kalk_edit_sve_stavke( .F., .F. )

   CASE Ch == K_CTRL_F8 .OR. ( is_mac() .AND. Ch == K_F8 )
      kalk_raspored_troskova()
      RETURN DE_REFRESH

   CASE Ch == k_ctrl_f9()
      IF Pitanje(, "Želite izbrisati kompletnu tabelu pripreme (D/N) ?", "N" ) == "D"
         cStavka := kalk_pripr->idfirma + "-" + kalk_pripr->idvd + "-" + kalk_pripr->brdok
         my_dbf_zap()
         log_write( "F18_DOK_OPER: kalk, brisanje pripreme: " + cStavka, 2 )
         RETURN DE_REFRESH
      ENDIF
      RETURN DE_CONT

   CASE Upper( Chr( Ch ) ) == "A" // .OR. lAsistentObrada

      kalk_asistent_pause( .F. )
      kalk_asistent_start()
      kalk_asistent_stop()
      kalk_asistent_pause( .F. )

      RETURN DE_REFRESH

   CASE Upper( Chr( Ch ) ) == "K"
      kalkulacija_cijena( .F. )
      SELECT kalk_pripr
      GO TOP
      RETURN DE_CONT

   CASE IsDigit( Chr( Ch ) )
      Msg( "Ako želite započeti unos novog dokumenta: <Ctrl-N>" )
      RETURN DE_CONT

   CASE Ch == K_F10
      RETURN kalk_meni_f10()

   CASE Ch == K_F5
      kalk_kartica_magacin_u_pripremi()
      RETURN DE_CONT

   CASE Ch == K_F6
      kalk_kartica_prodavnica_f6()
      RETURN DE_CONT

   ENDCASE

   RETURN DE_CONT


FUNCTION kalk_edit_last_key( nSet )

   IF nSet != NIL
      s_nKalkEditLastKey := nSet
   ENDIF

   RETURN s_nKalkEditLastKey


FUNCTION kalk_ispravka_postojeca_stavka()

   LOCAL cIdKonto1, cIdKonto2
   LOCAL hParams := hb_Hash()
   LOCAL hDok
   LOCAL _opis, hKalkAtributi
   LOCAL hOldDokument, hRecNoviDokument
   LOCAL oAttr, nTrec

   hOldDokument := hb_Hash()
   _opis := fetch_metric( "kalk_dodatni_opis_kod_unosa_dokumenta", NIL, "N" ) == "D"

   IF RecCount() == 0
      Msg( "Ako želite započeti unos novog dokumenta: <Ctrl-N>" )
      RETURN DE_CONT
   ENDIF

   Scatter()
   IF Left( _idkonto2, 3 ) = "XXX"
      Beep( 2 )
      Msg( "Ne možete ispravljati protustavke !" )
      RETURN DE_CONT
   ENDIF

   nKalkRbr := rbr_u_num( _Rbr )
   _ERROR := ""

   Box( "ist", BOX_HEIGHT, BOX_WIDTH, .F. )

   hOldDokument[ "idfirma" ] := _idfirma
   hOldDokument[ "idvd" ] := _idvd
   hOldDokument[ "brdok" ] := _brdok

   hDok := hb_Hash()
   hDok[ "idfirma" ] := _idfirma
   hDok[ "idtipdok" ] := _idvd
   hDok[ "brdok" ] := _brdok
   hDok[ "rbr" ] := _rbr

   IF _opis
      hParams[ "opis" ] := get_kalk_attr_opis( hDok, .F. )
   ENDIF

   IF kalk_edit_stavka( .F., @hParams ) == K_ESC
      BoxC()
      RETURN DE_CONT
   ELSE

      BoxC()
      IF _error <> "1"
         _error := "0"
      ENDIF

      IF _idvd == "16"
         nVPV16 := _vpc * _kolicina
      ELSE
         nMPV80 := _mpcsapp * _kolicina
      ENDIF
      nNVPredhodna := _nc * _kolicina

      my_rlock()
      Gather()
      my_unlock()

      hKalkAtributi := hb_Hash()
      hKalkAtributi[ "idfirma" ] := field->idfirma
      hKalkAtributi[ "idtipdok" ] := field->idvd
      hKalkAtributi[ "brdok" ] := field->brdok
      hKalkAtributi[ "rbr" ] := field->rbr

      oAttr := DokAttr():new( "kalk", F_KALK_ATTR )
      oAttr:hAttrId := hKalkAtributi
      oAttr:push_attr_from_mem_to_dbf( hParams )

      SELECT kalk_pripr

      IF nKalkRbr == 1
         nTrec := RecNo()
         hRecNoviDokument := dbf_get_rec()
         kalk_izmjeni_sve_stavke_dokumenta( hOldDokument, hRecNoviDokument )
         SELECT kalk_pripr
         GO ( nTrec )
      ENDIF

      IF _idvd $ "16#80" .AND. !Empty( _idkonto2 ) // protustavka

         IF _idvd == "80" // prvi konto je prodavnicki
            cIdKonto1 := _pkonto
            cIdKonto2 := _idkonto2
            _pkonto := _idkonto2 // konto protustavke je _idkonto predhodne stavke
            _idkonto2 := "XXX"   // _idkonto2 se oznacava kao protustavka
         ENDIF

         IF _idvd == "16" // priv konto je magacinski
            cIdKonto1 := _mkonto
            cIdKonto2 := _idkonto2
            _mkonto := _idkonto2 // konto protustavke je _idkonto predhodne stavke
            _idkonto2 := "XXX"
         ENDIF

         _kolicina := - kalk_pripr->kolicina
         nKalkRbr := rbr_u_num( _rbr ) + 1
         _rbr := rbr_u_char( nKalkRbr )

         Box( "", BOX_HEIGHT, BOX_WIDTH, .F., "Protustavka" )

         SEEK _idfirma + _idvd + _brdok + _rbr
         _tbanktr := "X"
         DO WHILE !Eof() .AND. _idfirma + _idvd + _brdok + _rbr == field->idfirma + field->idvd + field->brdok + field->rbr
            IF Left( kalk_pripr->idkonto2, 3 ) == "XXX"
               Scatter()
               _tbanktr := ""
               EXIT
            ENDIF
            SKIP
         ENDDO

         IF _idvd == "80"
            _pkonto := cIdKonto2
         ELSE
            _mkonto := cIdKonto2
         ENDIF
         _idkonto2 := "XXX"

         IF _idvd == "16"
            kalk_get_1_16()
         ELSE
            kalk_get_1_80_protustavka()
         ENDIF

         IF _tbanktr == "X"
            APPEND ncnl
         ENDIF

         IF _error <> "1"
            _error := "0"
         ENDIF

         my_rlock()
         Gather()
         my_unlock()

         BoxC()

      ENDIF

      RETURN DE_REFRESH

   ENDIF

   RETURN DE_CONT



STATIC FUNCTION kalk_kontiraj_alt_k()

   LOCAL cBrNal := NIL

   my_close_all_dbf()

   kalk_kontiranje_gen_finmat()

   IF Pitanje(, "Želite li izvršiti kontiranje dokumenta (D/N) ?", "D" ) == "D"
      kalk_kontiranje_fin_naloga( NIL, NIL, NIL, cBrNal )
   ENDIF

   o_kalk_edit()

   RETURN DE_REFRESH


FUNCTION kalk_unos_nova_stavka()

   LOCAL hParams := hb_Hash()
   LOCAL hDok, hKalkAtributi
   LOCAL hOldDokument := hb_Hash()
   LOCAL hRecNoviDokument
   LOCAL oAttr
   LOCAL _opis
   LOCAL _rbr_uvecaj := 0
   LOCAL cIdKonto1, cIdKonto2

   _opis := fetch_metric( "kalk_dodatni_opis_kod_unosa_dokumenta", NIL, "N" ) == "D"

   Box( "knjn", BOX_HEIGHT, BOX_WIDTH, .F., "Unos novih stavki" )

   _TMarza := "A"

   GO BOTTOM
   IF Left( field->idkonto2, 3 ) = "XXX"
      _rbr_uvecaj := 1
      SKIP -1
   ENDIF

   cIdKonto1 := ""
   cIdKonto2 := ""

   DO WHILE .T.

      Scatter()
      hParams := hb_Hash()

      IF _opis
         hParams[ "opis" ] := Space( 300 )
      ENDIF

      _ERROR := ""

      IF _idvd $ "16#80" .AND. _idkonto2 = "XXX"
         _idkonto := cIdKonto1
         _idkonto2 := cIdKonto2
      ENDIF

      IF _idvd == "PR" // locirati se na zadnji proizvod
         DO WHILE !Bof() .AND. Val( field->rBr ) > 9
            IF Val( field->rBr ) > 9
               SKIP -1
            ELSE
               EXIT
            ENDIF
         ENDDO
         Scatter()

      ENDIF

      IF fetch_metric( "kalk_reset_artikla_kod_unosa", my_user(), "N" ) == "D"
         _idroba := Space( 10 )
      ENDIF

      _Kolicina := _GKolicina := _GKolicin2 := 0
      _FCj := _FCJ2 := _Rabat := 0

      IF !( _idvd $ "10#81" )
         _Prevoz := _Prevoz2 := _Banktr := _SpedTr := _CarDaz := _ZavTr := 0
      ENDIF

      _NC := _VPC := _VPCSaP := _MPC := _MPCSaPP := 0

      nKalkRbr := rbr_u_num( _rbr ) + 1 + _rbr_uvecaj

      hOldDokument[ "idfirma" ] := _idfirma
      hOldDokument[ "idvd" ] := _idvd
      hOldDokument[ "brdok" ] := _brdok

      IF kalk_edit_stavka( .T., @hParams ) == K_ESC
         EXIT
      ENDIF

      APPEND BLANK

      IF _error <> "1"
         _error := "0"
      ENDIF

      IF _idvd == "16"
         nVPV16 := _vpc * _kolicina
      ELSE
         nMPV80 := _mpcsapp * _kolicina
      ENDIF
      nNVPredhodna := _nc * _kolicina

      Gather()

      hKalkAtributi := hb_Hash()
      hKalkAtributi[ "idfirma" ] := field->idfirma
      hKalkAtributi[ "idtipdok" ] := field->idvd
      hKalkAtributi[ "brdok" ] := field->brdok
      hKalkAtributi[ "rbr" ] := field->rbr

      oAttr := DokAttr():new( "kalk", F_KALK_ATTR )
      oAttr:hAttrId := hKalkAtributi
      oAttr:push_attr_from_mem_to_dbf( hParams )

      IF nKalkRbr == 1
         SELECT kalk_pripr
         nTrec := RecNo()
         hRecNoviDokument := dbf_get_rec()
         kalk_izmjeni_sve_stavke_dokumenta( hOldDokument, hRecNoviDokument )
         SELECT kalk_pripr
         GO ( nTrec )
      ENDIF

      IF _idvd $ "16#80" .AND. !Empty( _idkonto2 )

         cIdKonto1 := _idkonto
         cIdKonto2 := _idkonto2

         _idkonto := cIdKonto2
         _idkonto2 := "XXX"
         _kolicina := -kolicina

         nKalkRbr := rbr_u_num( _rbr ) + 1
         _Rbr := rbr_u_char( nKalkRbr )

         Box( "", BOX_HEIGHT, BOX_WIDTH, .F., "Protustavka" )

         IF _idvd == "16"
            kalk_get_16_1()

         ELSE
            kalk_get_1_80_protustavka()
         ENDIF

         APPEND BLANK

         IF _error <> "1"
            _error := "0"
         ENDIF

         Gather()

         BoxC()

         _idkonto := cIdKonto1
         _idkonto2 := cIdKonto2

      ENDIF

   ENDDO

   BoxC()

   RETURN DE_REFRESH



FUNCTION kalk_edit_sve_stavke( lAsistentObrada, lStartPocetak )

   LOCAL hParams := hb_Hash()
   LOCAL hDok
   LOCAL oAttr, hKalkAtributi, hOldDokument, hRecNoviDokument
   LOCAL _opis
   LOCAL nTr2
   LOCAL nDug, nPot, nTrec
   LOCAL cIdKonto1, cIdKonto2

   PushWA()

   select_o_kalk_pripr()
   IF lStartPocetak
      GO TOP
   ENDIF
   hb_default( @lStartPocetak, .F. )

   _opis := fetch_metric( "kalk_dodatni_opis_kod_unosa_dokumenta", NIL, "N" ) == "D"

   Box( "anal", BOX_HEIGHT, BOX_WIDTH, .F., "Ispravka naloga" )

   nDug := 0
   nPot := 0

   DO WHILE !Eof()

      SKIP
      nTR2 := RecNo()
      SKIP -1

      hOldDokument := dbf_get_rec()
      Scatter()

      _error := ""

      IF Left( _idkonto2, 3 ) == "XXX"  // 80-ka
         SKIP 1
         SKIP 1
         nTR2 := RecNo()
         SKIP -1
         Scatter()
         _error := ""
         IF Left( _idkonto2, 3 ) == "XXX"
            EXIT
         ENDIF
      ENDIF

      nKalkRbr := rbr_u_num( _rbr )

      IF lAsistentObrada .AND. !kalk_asistent_pause()
         kalk_asistent_send_entere()
         hb_idleSleep( 0.1 )
      ENDIF

      hDok := hb_Hash()
      hDok[ "idfirma" ] := _idfirma
      hDok[ "idtipdok" ] := _idvd
      hDok[ "brdok" ] := _brdok
      hDok[ "rbr" ] := _rbr

      IF _opis
         hParams[ "opis" ] := get_kalk_attr_opis( hDok, .F. )
      ENDIF

      IF kalk_edit_stavka( .F., @hParams ) == K_ESC
         IF lAsistentObrada
            automatska_obrada_error( .T. ) // iz stavke se izaslo sa ESC tokom automatske obrade
         ENDIF
         EXIT
      ENDIF

      SELECT kalk_pripr

      IF _error <> "1"
         _error := "0"
      ENDIF

      nMPV80 := _mpcsapp * _kolicina  // vrijednost prosle stavke
      nNVPredhodna := _nc * _kolicina

      my_rlock()
      Gather()
      my_unlock()

      oAttr := DokAttr():new( "kalk", F_KALK_ATTR )
      oAttr:hAttrId := hDok
      oAttr:push_attr_from_mem_to_dbf( hParams )

      SELECT kalk_pripr

      IF nKalkRbr == 1
         nTrec := RecNo()
         hRecNoviDokument := dbf_get_rec()
         kalk_izmjeni_sve_stavke_dokumenta( hOldDokument, hRecNoviDokument )
         SELECT kalk_pripr
         GO ( nTrec )
      ENDIF

      IF _idvd $ "16#80" .AND. !Empty( _idkonto2 )

         cIdKonto1 := _idkonto
         cIdKonto2 := _idkonto2
         _idkonto := cIdKonto2
         _idkonto2 := "XXX"
         _kolicina := -kolicina

         nKalkRbr := rbr_u_num( _rbr ) + 1
         _Rbr := rbr_u_char( nKalkRbr )

         Box( "", BOX_HEIGHT, BOX_WIDTH, .F., "Protustavka" )

         SEEK _idfirma + _idvd + _brdok + _rbr
         _tbanktr := "X"
         DO WHILE !Eof() .AND. _idfirma + _idvd + _brdok + _rbr == field->idfirma + field->idvd + field->brdok + field->rbr
            IF Left( field->idkonto2, 3 ) == "XXX"
               Scatter()
               _tbanktr := ""
               EXIT
            ENDIF
            SKIP
         ENDDO
         _idkonto := cIdKonto2
         _idkonto2 := "XXX"
         IF _idvd == "16"
            kalk_get_1_16()
         ELSE
            kalk_get_1_80_protustavka()
         ENDIF

         IF _tbanktr == "X"
            APPEND ncnl
         ENDIF
         IF _error <> "1"
            _error := "0" // stavka onda postavi ERROR
         ENDIF

         my_rlock()
         Gather()
         my_unlock()
         BoxC()
      ENDIF
      GO nTR2

   ENDDO

   Beep( 1 )
   PopWA()
   BoxC()

   RETURN DE_REFRESH



PROCEDURE kalk_asistent_pause_handler( lAsistentObrada )

   LOCAL cButton

   hb_default( @lAsistentObrada, .F. )
   IF ( Seconds() - s_nAsistentPauseSeconds ) < 1
      RETURN
   ENDIF

   IF !is_kalk_asistent_started()
      // .AND. !kalk_asistent_pause()
      RETURN
   ENDIF

   IF !kalk_asistent_pause()
      cButton := "< As Pause >"
   ELSE
      cButton := "< As Cont  >"
   ENDIF

   hb_DispOutAt( f18_max_rows(), 1, cButton, F18_COLOR_INFO_PANEL )

   IF  MINRECT( f18_max_rows(), 1, f18_max_rows(), 12 ) .OR. ;
         ( kalk_asistent_pause() .AND. Upper( Chr( kalk_edit_last_key() ) ) == "C" )

      IF kalk_asistent_pause() // switch pause
         kalk_asistent_pause( .F. )
         KEYBOARD Chr ( K_LEFT ) // bilo koja tipka da se okine keyboard handler
      ELSE
         MsgBeep( "Asistent : " + cButton + " pauza##" + "Nastavak: ukucati 'C' ili miš na dugme <As Cont>" )
         kalk_asistent_pause( .T. )
         CLEAR TYPEAHEAD
         KEYBOARD Chr ( K_ESC ) // povrat u browse objekat

      ENDIF
      kalk_edit_last_key( 0 )
   ENDIF

   RETURN


FUNCTION kalk_asistent_pause( lSet )

   IF lSet != NIL
      s_lAsistentPause := lSet
      s_nAsistentPauseSeconds := Seconds()
   ENDIF

   RETURN s_lAsistentPause


FUNCTION kalk_asistent_start()

   s_lAsistentStart := .T.
   kalk_edit_sve_stavke( .T., .T. )

   RETURN DE_REFRESH


FUNCTION kalk_asistent_send_esc()

   KEYBOARD Chr( K_ESC )

   RETURN DE_REFRESH


FUNCTION kalk_asistent_send_entere()

   LOCAL nKekk, cSekv

   CLEAR TYPEAHEAD // kalk_unos_asistent_send_entere
   cSekv := ""
   FOR nKekk := 1 TO 17
      cSekv += cEnter
   NEXT
   KEYBOARD cSekv

   RETURN .T.


FUNCTION kalk_asistent_stop()

   CLEAR TYPEAHEAD
   s_lAsistentStart := .F.

   RETURN .T.


FUNCTION is_kalk_asistent_started()

   RETURN s_lAsistentStart


FUNCTION kalk_edit_stavka( lNoviDokument, hParams )

   LOCAL nRet, nR

   // PRIVATE nMarza := 0
   // PRIVATE nMarza2 := 0

   PRIVATE PicDEM := "9999999.99999999"
   PRIVATE PicKol := kalk_pic_kolicina_bilo_gpickol()

   nKalkStrana := 1

   DO WHILE .T.

      @ box_x_koord() + 1, box_y_koord() + 1 CLEAR TO box_x_koord() + BOX_HEIGHT, box_y_koord() + BOX_WIDTH

      SetKey( K_PGDN, {|| NIL } )
      SetKey( K_PGUP, {|| NIL } )
      SetKey( K_CTRL_K, {|| a_val_convert() } )

      IF nKalkStrana == 1
         nR := kalk_unos_1( lNoviDokument, @hParams )
      ELSEIF nKalkStrana == 2
         nR := kalk_unos_2( lNoviDokument )
      ENDIF

      SetKey( K_PGDN, NIL )
      SetKey( K_PGUP, NIL )
      SetKey( K_CTRL_K, NIL )

      SET ESCAPE ON

      IF nR == K_ESC
         EXIT
      ELSEIF nR == K_PGUP
         --nKalkStrana
      ELSEIF nR == K_PGDN .OR. nR == K_ENTER
         ++nKalkStrana
      ENDIF

      IF nKalkStrana == 0
         nKalkStrana++
      ELSEIF nKalkStrana >= 3
         EXIT
      ENDIF

   ENDDO

   nRet := LastKey()
   IF ( nRet ) <> K_ESC
      _Rbr := rbr_u_char( nKalkRbr )
      // _Dokument := P_TipDok( _IdVD, - 2 )
      RETURN nRet
   ENDIF

   RETURN nRet


/*
 *  Prva strana/prozor maske unosa/ispravke stavke dokumenta
 */

FUNCTION kalk_unos_1( lNoviDokument, hParams )

   PRIVATE lKalkIzgenerisaneStavke := .F.
   PRIVATE Getlist := {}

   IF kalk_header_get1( lNoviDokument ) == 0
      RETURN K_ESC
   ENDIF

   SELECT kalk_pripr

   IF _idvd != "PR"
      SET FILTER TO
   ENDIF

   IF _idvd == "10"

      RETURN kalk_get_1_10()

   ELSEIF _idvd == "11"
      RETURN kalk_get_1_11()

   ELSEIF _idvd == "12"
      RETURN kalk_get_1_12()

   ELSEIF _idvd == "13"
      RETURN kalk_get_1_12()

   ELSEIF _idvd == "14"
      RETURN kalk_get_1_14()

   ELSEIF _idvd == "KO"
      RETURN kalk_get_1_14()

   ELSEIF _idvd == "16"
      RETURN kalk_get_1_16()

   ELSEIF _idvd == "18"
      RETURN kalk_get_1_18()

   ELSEIF _idvd == "19"
      RETURN kalk_get_1_19()

   ELSEIF _idvd $ "41#42"
      RETURN kalk_get_1_41_42()

   ELSEIF _idvd == "81"
      RETURN kalk_unos_dok_81( @hParams )

   ELSEIF _idvd == "80"
      RETURN kalk_get1_80( @hParams )

   ELSEIF _idvd $ "95#96#97"
      RETURN kalk_get_1_95()

   ELSEIF _idvd $  "94"    // storno fakture, storno otpreme, doprema
      RETURN kalk_get_1_94()

   ELSEIF _idvd == "IM"
      RETURN kalk_get_1_im()

   ELSEIF _idvd == "IP"
      RETURN kalk_get_1_ip()

   ELSEIF _idvd == "RN"
      RETURN GET1_RN()

   ELSEIF _idvd == "PR"
      RETURN kalk_unos_dok_pr()
   ELSE
      RETURN K_ESC
   ENDIF

   RETURN .T.


FUNCTION ispisi_naziv_konto( x, y, len )

   LOCAL cNaz := ""

   PushWa()
   SELECT F_KONTO

   IF !Used()
      PopWa()
      RETURN .F.
   ENDIF

   cNaz := AllTrim( field->naz )
   @ x, y SAY PadR( cNaz, len )

   PopWa()

   RETURN .T.


FUNCTION ispisi_naziv_partner( x, y, len )

   LOCAL cNaz := ""

   PushWa()
   SELECT F_PARTN

   IF !Used()
      PopWa()
      RETURN .F.
   ENDIF

   cNaz := AllTrim( field->naz )

   @ x, y SAY PadR( cNaz, len )

   PopWa()

   RETURN .T.


FUNCTION ispisi_naziv_roba( x, y, len )

   LOCAL cNaz := ""

   PushWa()
   SELECT F_ROBA

   IF !Used()
      PopWa()
      RETURN .F.
   ENDIF
   cNaz := AllTrim( field->naz )

   IF Len( cNaz ) >= len
      cNaz := PadR( cNaz, len - 6 )
   ENDIF
   cNaz += " (" + AllTrim( field->jmj ) + ")"

   @ x, y SAY PadR( cNaz, len )

   PopWa()

   RETURN .T.


FUNCTION kalk_unos_2()

   IF _idvd == "RN"
      RETURN Get2_RN()
   ELSEIF _idvd == "PR"
      RETURN kalk_get_pr_2()
   ENDIF

   RETURN K_ESC


FUNCTION valid_kalk_rbr_stavke( cIdVd )

   RETURN .T.


STATIC FUNCTION kalk_izmjeni_sve_stavke_dokumenta( old_dok, new_dok )

   LOCAL _old_firma := old_dok[ "idfirma" ]
   LOCAL _old_brdok := old_dok[ "brdok" ]
   LOCAL _old_tipdok := old_dok[ "idvd" ]
   LOCAL hRec, _tek_dok, nTrec
   LOCAL _new_firma := new_dok[ "idfirma" ]
   LOCAL _new_brdok := new_dok[ "brdok" ]
   LOCAL _new_tipdok := new_dok[ "idvd" ]
   LOCAL oAttr
   LOCAL _vise_konta := fetch_metric( "kalk_dokument_vise_konta", NIL, "N" ) == "D"

   SELECT kalk_pripr
   GO TOP

   SEEK _new_firma + _new_tipdok + _new_brdok

   IF !Found()
      RETURN .F.
   ENDIF

   _tek_dok := dbf_get_rec()

   GO TOP
   SEEK _old_firma + _old_tipdok + _old_brdok

   IF !Found()
      RETURN .F.
   ENDIF

   DO WHILE !Eof() .AND. field->idfirma + field->idvd + field->brdok == _old_firma + _old_tipdok + _old_brdok

      SKIP 1
      nTrec := RecNo()
      SKIP -1

      hRec := dbf_get_rec()
      hRec[ "idfirma" ] := _tek_dok[ "idfirma" ]
      hRec[ "idvd" ] := _tek_dok[ "idvd" ]
      hRec[ "brdok" ] := _tek_dok[ "brdok" ]
      hRec[ "datdok" ] := _tek_dok[ "datdok" ]

      IF !_vise_konta
         hRec[ "idpartner" ] := _tek_dok[ "idpartner" ]
      ENDIF
      IF !( hRec[ "idvd" ] $ "16#80" ) .AND. !_vise_konta
         hRec[ "idkonto" ] := _tek_dok[ "idkonto" ]
         hRec[ "idkonto2" ] := _tek_dok[ "idkonto2" ]
         hRec[ "pkonto" ] := _tek_dok[ "pkonto" ]
         hRec[ "mkonto" ] := _tek_dok[ "mkonto" ]
      ENDIF
      dbf_update_rec( hRec )
      GO ( nTrec )

   ENDDO
   GO TOP

   oAttr := DokAttr():new( "kalk", F_KALK_ATTR )
   oAttr:open_attr_dbf()

   GO TOP

   DO WHILE !Eof()

      SKIP 1
      nTrec := RecNo()
      SKIP -1

      hRec := dbf_get_rec()
      hRec[ "idfirma" ] := _tek_dok[ "idfirma" ]
      hRec[ "idtipdok" ] := _tek_dok[ "idvd" ]
      hRec[ "brdok" ] := _tek_dok[ "brdok" ]

      dbf_update_rec( hRec )
      GO ( nTrec )

   ENDDO

   USE
   SELECT kalk_pripr
   GO TOP

   RETURN .T.


FUNCTION kalk_zagl_firma()

   P_12CPI
   U_OFF
   B_OFF
   I_OFF
   ? "Subjekt:"
   U_ON
   ?? PadC( Trim( tip_organizacije() ) + " " + Trim( self_organizacija_naziv() ), 39 )
   U_OFF
   ? "Prodajni objekat:"
   U_ON
   ?? PadC( AllTrim( NazProdObj() ), 30 )
   U_OFF
   ? "(poslovnica-poslovna jedinica)"
   ? "Datum:"
   U_ON
   ?? PadC( SrediDat( kalk_pripr->DATDOK ), 18 )
   U_OFF
   ?
   ?

   RETURN .T.


STATIC FUNCTION NazProdObj()

   LOCAL cVrati := ""

   select_o_konto( kalk_pripr->pkonto )
   cVrati := konto->naz
   SELECT kalk_pripr

   RETURN cVrati


/*
 *     Mijenja predznak kolicini u svim stavkama u kalk_pripremi
 */
FUNCTION kalk_plus_minus_kol()

   o_kalk_edit()
   SELECT kalk_pripr
   GO TOP
   my_flock()
   DO WHILE !Eof()
      Scatter()
      _kolicina := -_kolicina
      _ERROR := " "
      Gather()
      SKIP 1
   ENDDO
   my_unlock()
   kalk_asistent_start()  // kalk_plus_minus_kol
   my_close_all_dbf()

   RETURN .T.


/*
 *     Formira diskontnu maloprodajnu cijenu u svim stavkama u kalk_pripremi
 */
FUNCTION kalk_set_diskont_mpc()

   aPorezi := {}
   o_kalk_edit()
   SELECT kalk_pripr
   GO TOP
   my_flock()

   DO WHILE !Eof()
      select_o_roba(  kalk_pripr->idroba )
      select_o_tarifa( ROBA->idtarifa )
      set_pdv_array_by_koncij_region_roba_idtarifa_2_3( kalk_pripr->pKonto, kalk_pripr->idRoba, @aPorezi )
      SELECT kalk_pripr
      Scatter()

      _mpcSaPP := MpcSaPor( roba->vpc, aPorezi )

      _ERROR := " "
      Gather()
      SKIP 1
   ENDDO

   my_unlock()
   kalk_asistent_start()
   my_close_all_dbf()

   RETURN .T.


/*
 *     Maloprodajne cijene svih artikala u kalk_pripremi kopira u sifrarnik robe
 */
FUNCTION MPCSAPPuSif()

   LOCAL cIdKonto

   o_kalk_edit()
   SELECT kalk_pripr
   GO TOP
   DO WHILE !Eof()
      cIdKonto := kalk_pripr->pkonto
      select_o_koncij( cIdKonto )
      SELECT kalk_pripr
      DO WHILE !Eof() .AND. kalk_pripr->pkonto == cIdKonto
         select_o_roba(  kalk_pripr->idroba )
         IF Found()
            roba_set_mcsapp_na_osnovu_koncij_pozicije( kalk_pripr->mpcsapp, .F. )
         ENDIF
         SELECT kalk_pripr
         SKIP 1
      ENDDO
   ENDDO
   my_close_all_dbf()

   RETURN .T.


/*
 *  brief Filuje VPC u svim stavkama u kalk_pripremi odgovarajucom VPC iz sifrarnika robe
 */
FUNCTION kalk_iz_vpc_sif_u_vpc_dokumenta()

   o_kalk_edit()
   SELECT kalk_pripr
   GO TOP
   my_flock()
   DO WHILE !Eof()
      select_o_roba(  kalk_pripr->idroba )
      select_o_koncij( kalk_pripr->mkonto )

      SELECT kalk_pripr
      Scatter()
      _vpc := kalk_vpc_za_koncij()
      _ERROR := " "
      Gather()
      SKIP 1
   ENDDO
   my_unlock()

   kalk_asistent_start() // kalk_iz_vpc_sif_u_vpc_dokumenta
   my_close_all_dbf()

   RETURN .T.


FUNCTION kalk_open_tables_unos( lAzuriraniDok, cIdFirma, cIdVD, cBrDok )

   IF lAzuriraniDok
      open_kalk_as_pripr( cIdFirma, cIdVd, cBrDok ) // .T. => SQL table
   ELSE
      o_kalk_pripr()
   ENDIF

   RETURN .T.


FUNCTION kalkulacija_ima_sve_cijene( cIdFirma, cIdVd, cBrDok )

   LOCAL cOk := ""
   LOCAL _area := Select()
   LOCAL nTrec := RecNo()

   DO WHILE !Eof() .AND. field->idfirma + field->idvd + field->brdok == cIdFirma + cIdVd + cBrDok

      IF field->idvd $ "11#41#42#RN#19"
         IF field->fcj == 0
            cOk += AllTrim( field->rbr ) + ";"
         ENDIF
      ELSEIF field->idvd $ "10#16#96#94#95#14#80#81#"
         IF field->nc == 0
            cOk += AllTrim( field->rbr ) + ";"
         ENDIF
      ENDIF
      SKIP

   ENDDO

   SELECT ( _area )
   GO ( nTrec )

   RETURN cOk


FUNCTION o_kalk_edit()

   o_kalk_pripr()
   SELECT kalk_pripr
   SET ORDER TO TAG "1"
   GO TOP

   RETURN .T.
