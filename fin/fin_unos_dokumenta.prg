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

STATIC s_nFinPriprRedniBroj


MEMVAR Ch, KursLis, gnLOst, gPotpis, lBlagAsis, cBlagIDVN
MEMVAR Kol, ImeKol

MEMVAR _idkonto, _idpartner, _funk, _fond, _idfirma, _brnal, _datval, _datdok, _otvst, _idrj, _idvn, _brdok, _k1, _k2, _k3, _k4, _rbr

STATIC s_cIdRjTekuca := ""

FUNCTION fin_unos_naloga()

   LOCAL hFinParams := fin_params()
   PRIVATE KursLis := "1"
   PRIVATE gnLOst := 0
   PRIVATE gPotpis := "N"

   // info_bar( "fin", "read_params" )
   // fin_read_params()
   // info_bar( "fin", "read_params_end" )

   s_cIdRjTekuca := GetTekucaRJ()
   lBlagAsis := .F.
   cBlagIDVN := "66"

   fin_knjizenje_naloga()

   my_close_all_dbf()

   RETURN .T.


/*
 Priprema za knjizenje naloga
 */

FUNCTION fin_knjizenje_naloga()

   LOCAL _sep := hb_UTF8ToStrBox( BROWSE_COL_SEP )
   LOCAL _w := 25
   LOCAL _d := f18_max_cols() - 6
   LOCAL _x_row := f18_max_rows() - 5
   LOCAL _y_row := _d
   LOCAL aFinUnosOpcije
   LOCAL _help_columns := 4
   LOCAL _opts := {}, _opt_d
   LOCAL i

   o_fin_edit()

   ImeKol := { ;
      { "F.",            {|| my_dbSelectArea( F_FIN_PRIPR ), field->IdFirma }, "IdFirma" }, ;
      { "VN",            {|| field->IdVN    }, "IdVN" }, ;
      { "Br.",           {|| field->BrNal   }, "BrNal" }, ;
      { "R.br",          {|| Str( field->RBr, 5, 0 ) }, "rbr", {|| wRbr() }, {|| .T. } }, ;
      { "Konto",         {|| field->IdKonto }, "IdKonto", {|| .T. }, {|| P_Konto( @_IdKonto ), .T. } }, ;
      { "Partner",       {|| field->IdPartner }, "IdPartner" }, ;
      { "Br.veze ",      {|| field->BrDok   }, "BrDok" }, ;
      { "Datum",         {|| field->DatDok  }, "DatDok" }, ;
      { "D/P",           {|| field->D_P     }, "D_P" }, ;
      { "Iznos " + AllTrim( valuta_domaca_skraceni_naziv() ), {|| Transform( field->IznosBHD, FormPicL( gPicBHD, 15 ) ) }, "iznosbhd" }, ;
      { "Iznos " + AllTrim( ValPomocna() ), {|| Transform( field->IznosDEM, FormPicL( pic_iznos_eur(), 10 ) ) }, "iznosdem" }, ;
      { "Opis",          {|| PadR( Left( field->Opis, 37 ) + iif( Len( AllTrim( field->Opis ) ) > 37, "...", "" ), 40 )  }, "OPIS" }, ;
      { "K1",            {|| field->k1      }, "k1" }, ;
      { "K2",            {|| field->k2      }, "k2" }, ;
      { "K3",            {|| K3Iz256( field->k3 )   }, "k3" }, ;
      { "K4",            {|| field->k4      }, "k4" } ;
      }


   Kol := {}

   FOR i := 1 TO 16
      AAdd( Kol, i )
   NEXT

   IF gFinRj == "D" .AND. fin_pripr->( FieldPos( "IDRJ" ) ) <> 0
      AAdd( ImeKol, { "RJ", {|| IdRj }, "IdRj" } )
      AAdd( Kol, 17 )
   ENDIF

   Box( , _x_row, _y_row )

   _opt_d := ( _d / 4 ) - 1

   aFinUnosOpcije := _upadr( " <c+N> Nova stavka", _opt_d ) + _sep
   aFinUnosOpcije += _upadr( " <ENT> Ispravka", _opt_d ) + _sep
   aFinUnosOpcije += _upadr( " <c+T> Briši stavku", _opt_d ) + _sep
   aFinUnosOpcije += _upadr( " <P> Povrat naloga", _opt_d )

   @ box_x_koord() + _x_row - 3, box_y_koord() + 2 SAY8 aFinUnosOpcije

   aFinUnosOpcije := _upadr( " <c+A> Ispravka stavki", _opt_d ) + _sep
   aFinUnosOpcije += _upadr( " <c+P> Štampa naloga", _opt_d ) + _sep
   aFinUnosOpcije += _upadr( " <a+A> Ažuriranje", _opt_d ) + _sep
   aFinUnosOpcije += _upadr( " <X> Ažur.bez štampe", _opt_d )

   @ box_x_koord() + _x_row - 2, box_y_koord() + 2 SAY8 aFinUnosOpcije

   aFinUnosOpcije := _upadr( iif( is_mac(), " <9>", " <c+F9>" ) + " Briši sve", _opt_d ) + _sep
   aFinUnosOpcije += _upadr( " <F5> Kontrola zbira", _opt_d ) + _sep
   aFinUnosOpcije += _upadr( " <a+F5> Pr.dat", _opt_d ) + _sep
   aFinUnosOpcije += _upadr( " <a+B> Blagajna", _opt_d )

   @ box_x_koord() + _x_row - 1, box_y_koord() + 2 SAY8 aFinUnosOpcije

   aFinUnosOpcije := _upadr( " <a+T> Briši po uslovu", _opt_d ) + _sep
   aFinUnosOpcije += _upadr( " <B> odredi broj dokumenta", _opt_d ) + _sep
   aFinUnosOpcije += _upadr( " <F9> sredi Rbr.", _opt_d ) + _sep
   aFinUnosOpcije += _upadr( " <F10> Ostale opcije", _opt_d ) + _sep


   @ box_x_koord() + _x_row, box_y_koord() + 2 SAY8 aFinUnosOpcije

   my_browse( "PN2", _x_row, _y_row, {| nCh | edit_fin_pripr_key_handler( nCh ) }, "", "FIN Priprema", , , , , _help_columns )

   BoxC()

   my_close_all_dbf()

   RETURN .T.




FUNCTION edit_fin_priprema( lNovaStavka )

   LOCAL _fakt_params := fakt_params()
   LOCAL hFinParams := fin_params()
   LOCAL lOstavDUMMY := .F.
   LOCAL lDugmeOtvoreneStavke
   LOCAL nFinRbr := fin_pripr_redni_broj()
   LOCAL lConfirmEnter
   LOCAL GetList := {}

   hb_default( @lNovaStavka, .F. )

   fin_pripr_nova_stavka( lNovaStavka )

   IF fin_pripr_nova_stavka() .AND. fin_pripr_redni_broj() == 1
      _IdFirma := self_organizacija_id()
   ENDIF

   IF fin_pripr_nova_stavka()
      _OtvSt := " "
   ENDIF

   IF ( ( gFinRj == "D" ) .AND. fin_pripr_nova_stavka() )
      _idrj := s_cIdRjTekuca
   ENDIF

   SET CURSOR ON
   // lConfirmEnter := Set( _SET_CONFIRM, .F. )
   lConfirmEnter := Set( _SET_CONFIRM )
   lDugmeOtvoreneStavke := .T.


   @  box_x_koord() + 1, box_y_koord() + 2 SAY8 "Firma: "
   ?? self_organizacija_id(), "-", self_organizacija_naziv()
   @  box_x_koord() + 3, box_y_koord() + 2 SAY "NALOG: "
   @  box_x_koord() + 3, box_y_koord() + 14 SAY "Vrsta:" GET _idvn VALID p_fin_vrsta_naloga( @_IdVN, 3, 26 ) PICT "@!"

   READ

   ESC_RETURN 0

   IF fin_pripr_nova_stavka() .AND. ( _idfirma <> idfirma .OR. _idvn <> idvn )

      _brnal := fin_prazan_broj_naloga()
      SELECT  fin_pripr

   ENDIF


   hb_SetKey( iif( is_mac(), hb_keyNew( "K", HB_KF_CTRL ), K_ALT_K ), {|| fin_unos_konverzija_valute( "_IZNOSDEM", GetList ) } )
   hb_SetKey( iif( is_mac(), hb_keyNew( "O", HB_KF_CTRL ), K_ALT_O ), {|| fin_unos_asistent_gen_otvorene_stavke() } )

   // SET KEY K_ALT_O TO

   @ box_x_koord() + 3, box_y_koord() + 55 SAY "Broj:" GET _brnal VALID fin_valid_provjeri_postoji_nalog( _idfirma, _idvn, _brnal ) .AND. !Empty( _brnal )
   @ box_x_koord() + 5, box_y_koord() + 2 SAY "Redni broj stavke naloga:" GET nFinRbr PICTURE "99999" ;
      WHEN {|| fin_pripr_redni_broj( nFinRbr ), .T. } VALID {|| lDugmeOtvoreneStavke := .T., fin_pripr_redni_broj( nFinRbr ), .T. }

   @ box_x_koord() + 7, box_y_koord() + 2 SAY "DOKUMENT: "

   IF hFinParams[ "fin_tip_dokumenta" ]
      @ box_x_koord() + 7, box_y_koord() + 14  SAY "Tip:" GET _IdTipDok VALID browse_tdok( @_IdTipDok, 7, 26 )
   ENDIF

   IF ( IsRamaGlas() )
      @ box_x_koord() + 8, box_y_koord() + 2 SAY8 "Vezni broj (račun/r.nalog):"  GET _BrDok VALID BrDokOK()
   ELSE
      @ box_x_koord() + 8, box_y_koord() + 2 SAY "Vezni broj:" GET _brdok
   ENDIF

   @ box_x_koord() + 8, box_y_koord() + Col() + 2  SAY "Datum:" GET _DatDok VALID {||  datum_not_empty_upozori_godina( _datDok, "Datum FIN dokumenta" ) }

   IF gDatVal == "D"
      @ box_x_koord() + 8, Col() + 2 SAY "Valuta: " GET _DatVal
   ENDIF

   @ box_x_koord() + 11, box_y_koord() + 2 SAY "Opis: " GET _opis WHEN {|| .T. } VALID {|| .T. } PICT "@S" + AllTrim( Str( f18_max_cols() - 8 ) )

   IF hFinParams[ "fin_k1" ]
      @ box_x_koord() + 11, Col() + 2 SAY "K1" GET _k1 PICT "@!"
   ENDIF

   IF hFinParams[ "fin_k2" ]
      @ box_x_koord() + 11, Col() + 2 SAY "K2" GET _k2 PICT "@!"
   ENDIF


   IF hFinParams[ "fin_k3" ]
/*
      IF my_get_from_ini( "FIN", "LimitiPoUgovoru_PoljeK3", "N", SIFPATH ) == "D"
         _k3 := K3Iz256( _k3 )
         @ box_x_koord() + 11, Col() + 2 SAY "K3" GET _k3 VALID Empty( _k3 ) .OR. P_ULIMIT( @_k3 ) PICT "999"
      ELSE
*/
      @ box_x_koord() + 11, Col() + 2 SAY "K3" GET _k3 PICT "@!"
// ENDIF
   ENDIF

   IF hFinParams[ "fin_k4" ]
      IF _fakt_params[ "fakt_vrste_placanja" ]
         @ box_x_koord() + 11, Col() + 2 SAY "K4" GET _k4 VALID Empty( _k4 ) .OR. P_VRSTEP( @_k4 ) PICT "@!"
      ELSE
         @ box_x_koord() + 11, Col() + 2 SAY "K4" GET _k4 PICT "@!"
      ENDIF
   ENDIF

   IF gFinRj == "D"
      @ box_x_koord() + 11, Col() + 2 SAY "RJ" GET _idrj VALID Empty( _idrj ) .OR. P_Rj( @_idrj ) PICT "@!"
   ENDIF

   IF gFinFunkFond == "D"
      @ box_x_koord() + 12, box_y_koord() + 22 SAY "      Funk." GET _Funk VALID Empty( _Funk ) .OR. P_Funk( @_Funk ) PICT "@!"
      @ box_x_koord() + 12, box_y_koord() + 44 SAY "      Fond." GET _Fond VALID Empty( _Fond ) .OR. P_Fond( @_Fond ) PICT "@!"
   ENDIF

   @ box_x_koord() + 13, box_y_koord() + 2 SAY "Konto  :" GET _IdKonto PICT "@!" ;
      VALID  P_Konto( @_IdKonto, 13, 20 ) .AND. !Empty( _IdKonto ) .AND. BrDokOK() .AND. MinKtoLen( _IdKonto ) .AND. fin_pravilo_konto()


   @ box_x_koord() + 14, box_y_koord() + 2 SAY "Partner:" GET _IdPartner PICT "@!" ;
      VALID  {|| iif( Empty( _idpartner ), say_from_valid( 14, 20, Space( 25 ) ), ), ;
      ( p_partner( @_IdPartner, 14, 20 ) ) .AND. fin_pravilo_partner() .AND. ;
      iif( g_knjiz_help == "D" .AND. !Empty( _idpartner ), fin_partner_prikaz_stanja_ekran( _idpartner, _idkonto, NIL ), .T. ) } ;
      WHEN {|| iif( ChkKtoMark( _idkonto ), .T., .F. ) }


   @ box_x_koord() + 16, box_y_koord() + 2  SAY8 "Duguje/Potražuje (1/2):" GET _D_P VALID V_DP() .AND. fin_pravilo_dug_pot() .AND. fin_pravilo_broj_veze()

   @ box_x_koord() + 16, box_y_koord() + 46  GET _IznosBHD  PICTURE "999999999999.99"  WHEN {|| .T. } VALID {|| lDugmeOtvoreneStavke := .T., .T. }

   @ box_x_koord() + 17, box_y_koord() + 46  GET _IznosDEM  PICTURE '9999999999.99'  WHEN {|| fin_unos_konverzija_valute( "_IZNOSBHD", GetList ),  .T. } ;
      VALID {|| lDugmeOtvoreneStavke := .F., .T. }


   @ box_x_koord() + 16, box_y_koord() + 65 GET lOstavDUMMY PUSHBUTTON  CAPTION "(Alt-O) Otvorene stavke"   ;
      WHEN {|| lDugmeOtvoreneStavke } ;
      SIZE X 20 Y 2 FOCUS {|| lDugmeOtvoreneStavke := .T., fin_unos_asistent_gen_otvorene_stavke(), lDugmeOtvoreneStavke := .F. }



   READ


   Set( _SET_CONFIRM, lConfirmEnter )
   IF ( gFinRj == "D" .AND. s_cIdRjTekuca <> _idrj )
      s_cIdRjTekuca := _idrj
      SetTekucaRJ( s_cIdRjTekuca )
   ENDIF

   _IznosBHD := Round( _iznosbhd, 2 )
   _IznosDEM := Round( _iznosdem, 2 )

   ESC_RETURN 0

   // SET KEY K_ALT_K TO
   hb_SetKey( iif( is_mac(), hb_keyNew( "K", HB_KF_CTRL ), K_ALT_K ), NIL )
   hb_SetKey( iif( is_mac(), hb_keyNew( "O", HB_KF_CTRL ), K_ALT_O ), NIL )

   _k3 := K3U256( _k3 )
   _Rbr := fin_pripr_redni_broj()

   SELECT fin_pripr

   RETURN 1



FUNCTION fin_pripr_redni_broj( nSet )

   IF nSet != NIL
      s_nFinPriprRedniBroj := nSet
   ENDIF

   RETURN s_nFinPriprRedniBroj


FUNCTION edit_fin_pripr_key_handler( nCh )

   LOCAL nTr2
   LOCAL lLogUnos := .F.
   LOCAL lLogBrisanje := .F.
   LOCAL _log_info
   LOCAL nBoxVisina := f18_max_rows() - 5
   LOCAL cFinBrojDokumenta

   IF Select( "fin_pripr" ) == 0
      o_fin_pripr()
   ELSE
      SELECT FIN_PRIPR
   ENDIF

   IF ( nCh == K_CTRL_T .OR. nCh == K_ENTER ) .AND. RecCount2() == 0
      RETURN DE_CONT
   ENDIF


   DO CASE

   CASE nCh == K_ALT_F5 // setuj datdok na osnovu datval

      IF set_datval_datdok()
         RETURN DE_REFRESH
      ELSE
         RETURN DE_CONT
      ENDIF

   CASE nCh == K_F8 // brisi stavke u pripremi od - do

      IF fin_pripr_brisi_stavke_od_do() == 1
         RETURN DE_REFRESH
      ELSE
         RETURN DE_CONT
      ENDIF

   CASE nCh == K_F9

      sredi_rbr_fin_nalog()
      RETURN DE_REFRESH

   CASE nCh == K_ALT_T

      IF brisi_fin_pripr_po_uslovu()
         RETURN DE_REFRESH
      ELSE
         RETURN DE_CONT
      ENDIF

   CASE nCh == K_CTRL_T

      IF Pitanje(, "Želite izbrisati ovu stavku ?", "D" ) == "D"

         cFinBrojDokumenta := field->idfirma + "-" + field->idvn + "-" + field->brnal
         cStavka := Str( field->rbr, 5 )
         cBKonto := field->idkonto
         cBDP := field->d_p
         dBDatnal := field->datdok
         cBIznos := Str( field->iznosbhd )

         my_rlock()
         DELETE
         my_unlock()
         nTrec := RecNo()
         my_dbf_pack()
         GO ( nTrec )

         BrisiPBaze()

         log_write( "F18_DOK_OPER: fin, brisanje stavke u pripremi: " + AllTrim( cFinBrojDokumenta ) + " stavka br: " + cStavka, 2 )

         RETURN DE_REFRESH
      ENDIF

      RETURN DE_CONT

   CASE nCh == K_F5

      kontrola_zbira_naloga_u_pripremi()
      RETURN DE_REFRESH

   CASE nCh == K_ENTER

      Box( "ist", nBoxVisina, f18_max_cols() - 8, .F. )
      set_global_vars_from_dbf( "_" )

      fin_pripr_redni_broj( _Rbr )

      IF edit_fin_priprema( .F. ) == 0
         BoxC()
         RETURN DE_REFRESH // radi asistenta otvorenih stavki
      ELSE
         dbf_update_rec( get_hash_record_from_global_vars( "_" ), .F. )
         BrisiPBaze()
         BoxC()
         RETURN DE_REFRESH
      ENDIF

   CASE nCh == K_CTRL_A

      PushWA()
      SELECT fin_pripr

      Box( "anal", nBoxVisina, f18_max_cols() - 10, .F., "Ispravka naloga" )

      nDug := 0
      nPot := 0

      DO WHILE !Eof()
         SKIP

         nTR2 := RecNo()
         SKIP -1
         set_global_vars_from_dbf()
         fin_pripr_redni_broj( _Rbr )

         @ box_x_koord() + 1, box_y_koord() + 1 CLEAR TO box_x_koord() + f18_max_rows() - 8, box_y_koord() + f18_max_cols() - 10
         IF edit_fin_priprema( .F. ) == 0
            EXIT
         ELSE
            BrisiPBaze()
         ENDIF
         IF _D_P == '1'
            nDug += _IznosBHD
         ELSE
            nPot += _IznosBHD
         ENDIF

         @ box_x_koord() + nBoxVisina - 2, box_y_koord() + 2 SAY "ZBIR NALOGA:"
         @ box_x_koord() + nBoxVisina - 2, box_y_koord() + 15 SAY nDug PICTURE '9 999 999 999.99'
         @ box_x_koord() + nBoxVisina - 2, box_y_koord() + 36 SAY nPot PICTURE '9 999 999 999.99'
         @ box_x_koord() + nBoxVisina - 2, box_y_koord() + 57 SAY nDug - nPot PICTURE '9 999 999 999.99'
         Inkey( 10 )

         SELECT fin_pripr
         dbf_update_rec( get_hash_record_from_global_vars(), .F. )
         GO nTR2
      ENDDO

      PopWA()
      BoxC()
      RETURN DE_REFRESH

   CASE nCh == K_CTRL_N

      SELECT fin_pripr
      nDug := 0
      nPot := 0
      nPrvi := 0
      GO TOP
      DO WHILE ! Eof()  // kompletan nalog suma
         IF D_P = '1'
            nDug += IznosBHD
         ELSE
            nPot += IznosBHD
         ENDIF
         SKIP
      ENDDO
      GO BOTTOM

      Box( "knjn", nBoxVisina, f18_max_cols() - 7,  .F., "Knjizenje naloga - nove stavke" )

      DO WHILE .T.

         set_global_vars_from_dbf()
         _idPartner := Space( Len( _idPartner ) )

         IF ( IsRamaGlas() )
            _idKonto := Space( Len( _idKonto ) )
            _brDok := Space( Len( _brDok ) )
         ENDIF

         fin_pripr_redni_broj( _Rbr + 1 )

         @ box_x_koord() + 1, box_y_koord() + 1 CLEAR TO box_x_koord() + f18_max_rows() - 5, box_y_koord() + f18_max_cols() - 8

         IF edit_fin_priprema( .T. ) == 0
            EXIT
         ELSE
            BrisiPBaze()
         ENDIF

         IF _D_P = '1'
            nDug += _IznosBHD
         ELSE
            nPot += _IznosBHD
         ENDIF
         @ box_x_koord() + nBoxVisina - 2, box_y_koord() + 2 SAY "ZBIR NALOGA:"
         @ box_x_koord() + nBoxVisina - 2, box_y_koord() + 15 SAY nDug PICTURE '9 999 999 999.99'
         @ box_x_koord() + nBoxVisina - 2, box_y_koord() + 36 SAY nPot PICTURE '9 999 999 999.99'
         @ box_x_koord() + nBoxVisina - 2, box_y_koord() + 57 SAY nDug - nPot PICTURE '9 999 999 999.99'

         Inkey( 10 )

         SELECT fin_pripr
         APPEND BLANK
         dbf_update_rec( get_hash_record_from_global_vars(), .F. )

      ENDDO
      BoxC()

      RETURN DE_REFRESH

   CASE nCh == k_ctrl_f9()

      IF Pitanje(, "Želite li izbrisati pripremu !?", "N" ) == "D"

         _log_info := fin_pripr->idfirma + "-" + fin_pripr->idvn + "-" + fin_pripr->brnal
         fin_reset_broj_dokumenta( fin_pripr->idfirma, fin_pripr->idvn, fin_pripr->brnal )

         my_dbf_zap()
         BrisiPBaze()

         log_write( "F18_DOK_OPER: fin, brisanje pripreme: " + _log_info, 2  )

      ENDIF

      RETURN DE_REFRESH

   CASE nCh == K_CTRL_P

      fin_set_broj_dokumenta()
      fin_nalog_k_ctrl_p()
      o_fin_edit()

      RETURN DE_REFRESH


   CASE Upper( Chr( nCh ) ) == "X"

      fin_azuriraj_x()
      RETURN DE_REFRESH


   CASE is_key_alt_a( nCh )

      fin_set_broj_dokumenta()
      fin_azuriranje_naloga()
      o_fin_edit()
      RETURN DE_REFRESH

   CASE Upper( Chr( nCh ) ) == "B"
      fin_set_broj_dokumenta()
      RETURN DE_REFRESH

   CASE nCh == K_ALT_B

      fin_set_broj_dokumenta()
      my_close_all_dbf()
      fin_blagajna_dnevni_izvjestaj()
      o_fin_edit()

      RETURN DE_REFRESH

      // CASE Ch == K_ALT_I

      // fin_set_broj_dokumenta()
      // OiNIsplate()

      // RETURN DE_CONT

   CASE nCh == iif( is_mac(), Asc( "0" ), K_F10 )

      fin_knjizenje_ostale_opcije()
      RETURN DE_REFRESH

   CASE Upper( Chr( nCh ) ) == "P"

      IF RecCount2() != 0
         MsgBeep( "Povrat nije nedozvoljen, priprema nije prazna !" )
         RETURN DE_CONT
      ENDIF

      my_close_all_dbf()
      fin_povrat_naloga()
      o_fin_edit()

      RETURN DE_REFRESH

   ENDCASE

   RETURN DE_CONT



FUNCTION fin_azuriraj_x()

   fin_set_broj_dokumenta()

   my_close_all_dbf()
   fin_gen_ptabele_auto_bez_stampe()
   my_close_all_dbf()

   fin_azuriranje_naloga( .T. )
   o_fin_edit()

   RETURN .T.


FUNCTION WRbr()

   LOCAL hRec
   LOCAL _rec_2

   hRec := dbf_get_rec()

   IF hRec[ "rbr" ]  < 2
      @ box_x_koord() + 1, box_y_koord() + 2 SAY8 "Dokument:" GET hRec[ "idvn" ]
      @ box_x_koord() + 1, Col() + 2  GET hRec[ "brnal" ]
      READ
   ENDIF

   SET ORDER TO 0
   GO TOP
   DO WHILE !Eof()
      _rec_2 := dbf_get_rec()
      _rec_2[ "idvn" ]  := hRec[ "idvn" ]
      _rec_2[ "brnal" ] := hRec[ "brnal" ]
      dbf_update_rec( _rec_2 )
      SKIP
   ENDDO

   SET ORDER TO TAG "1"
   GO TOP

   RETURN .T.




FUNCTION o_fin_edit()

   my_close_all_dbf()

   // o_vrstep()
   // O_ULIMIT

   IF ( IsRamaGlas() )
      // select_o_fakt_objekti()
   ENDIF

   // o_rj()

   // IF gFinFunkFond == "D"
   // o_fond()
   // o_funk()
   // ENDIF

   IF !o_fin_psuban()
      RETURN .F.
   ENDIF
   IF !o_fin_panal()
      RETURN .F.
   ENDIF
   IF !o_fin_psint()
      RETURN .F.
   ENDIF
   IF !o_fin_pnalog()
      RETURN .F.
   ENDIF

   // O_PAREK
   // o_konto()
   // o_partner()
   // o_tnal()
   // o_tdok()
   // o_nalog()
   IF !o_fin_pripr()
      RETURN .F.
   ENDIF

   SELECT fin_pripr
   SET ORDER TO TAG "1"
   GO TOP

   RETURN .T.




FUNCTION MinKtoLen( cIdKonto )

   IF gKtoLimit == "N"
      RETURN .T.
   ENDIF

   IF gKtoLimit == "D" .AND. gnKtoLimit > 0
      IF Len( AllTrim( cIdKonto ) ) > gnKtoLimit
         RETURN .T.
      ELSE
         MsgBeep( "Dužina konta mora biti veća od " + AllTrim( Str( gnKtoLimit ) ) )
         RETURN .F.
      ENDIF
   ENDIF

   RETURN .T.



/* CheckMark(cIdKonto)
 *     Provjerava da li je konto markiran, ako nije izbrisi zapamceni _IdPartner
 *   param: cIdKonto - oznaka konta
 *   param: cIdPartner - sifra partnera koja ce se ponuditi
 *   param: cNewPartner - zapamcena sifra partnera
 */

FUNCTION CheckMark( cIdKonto, cIdPartner, cNewPartner )

   IF ( ChkKtoMark( _idkonto ) )
      cIdPartner := cNewPartner
   ELSE
      cIdPartner := Space( 6 )
   ENDIF

   RETURN .T.



/* Partija(cIdKonto)
 *
 *   param: cIdKonto - oznaka konta


FUNCTION Partija( cIdKonto )

   IF Right( Trim( cIdkonto ), 1 ) == "*"
      SELECT parek
      HSEEK StrTran( cIdkonto, "*", "" ) + " "
      cIdkonto := idkonto
      SELECT fin_pripr
   ENDIF

   RETURN .T.

 */

// -----------------------------------------------------
// Ispis duguje/potrazuje u domacoj i pomocnoj valuti
// -----------------------------------------------------
FUNCTION V_DP()

   SetPos( box_x_koord() + 16, box_y_koord() + 30 )

   IF _d_p == "1"
      ?? "   DUGUJE"
   ELSE
      ??U "POTRAŽUJE"
   ENDIF

   ?? " " + valuta_domaca_skraceni_naziv()

   SetPos( box_x_koord() + 17, box_y_koord() + 30 )

   IF _d_p == "1"
      ?? "   DUGUJE"
   ELSE
      ??U "POTRAŽUJE"
   ENDIF

   ?? " " + ValPomocna()

   RETURN _d_p $ "12"



// -----------------------------------------------------
// konvertovanje valute u pripremi...
// -----------------------------------------------------
FUNCTION fin_konvert_valute( rec, tip )

   LOCAL _ok := .T.
   LOCAL dKurs := Kurs( rec[ "datdok" ] )

   IF tip == "P"
      rec[ "iznosbhd" ] := rec[ "iznosdem" ] * dKurs
   ELSEIF tip == "D"
      IF Round( dKurs, 4 ) == 0
         rec[ "iznosdem" ] := 0
      ELSE
         rec[ "iznosdem" ] := rec[ "iznosbhd" ] / dKurs
      ENDIF
   ENDIF

   RETURN _ok


FUNCTION fin_unos_konverzija_valute( cVar, GetList )

   LOCAL dKurs


   IF ValType( _datDok ) != "D"
      RETURN .F.
   ENDIF

   dKurs := Kurs( _datdok )

   IF cVar == "_IZNOSDEM"
      _iznosbhd := _iznosdem * dKurs
   ELSEIF cVar = "_IZNOSBHD"
      IF Round( dKurs, 4 ) == 0
         _iznosdem := 0
      ELSE
         _iznosdem := _iznosbhd / dKurs
      ENDIF
   ENDIF

   IF GetList == NIL
      RETURN .F.
   ENDIF

   AEval( GetList, {| oGet | refresh_numeric_get( oGet )  } )

   RETURN .T.


STATIC FUNCTION refresh_numeric_get( oGet )

   // ?E pp( __objgetmsglist( oGet ) )
   IF  oGet:Type()  != "U" .AND. !( "DUMMY" $ oGet:name() )
      oGet:display()
   ENDIF

   RETURN .T.


FUNCTION konverzija_km_dem( dDatDo, nIznosKM )

   LOCAL nKurs, nIznosEur

   PushWa()
   nKurs := Kurs( dDatDo )
   PopWa()

   IF Round( nKurs, 4 ) == 0
      RETURN 0
   ENDIF

   RETURN  nIznosKM / nKurs




/*
 poziva je ObjDbedit u fin_knjizenje_naloga
 c-T  -  Brisanje stavke,  F5 - kontrola zbira za jedan nalog
 F6 -  Suma naloga, ENTER-edit stavke, c-A - ispravka naloga

 setuj datval na osnovu datdok u pripremi
*/

STATIC FUNCTION set_datval_datdok()

   LOCAL _ret := .F.
   LOCAL _dana, _dat_dok, _id_konto

   IF Pitanje(, "Za konto u nalogu postaviti datum val. DATDOK->DATVAL", "N" ) == "N"
      RETURN _ret
   ENDIF

   _id_konto := Space( 7 )
   _dat_dok := Date()
   _dana := 15

   Box(, 5, 60 )

   @ box_x_koord() + 1, box_y_koord() + 2 SAY "Promjena za konto  " GET _id_konto
   @ box_x_koord() + 3, box_y_koord() + 2 SAY "Novi datum dok " GET _dat_dok
   @ box_x_koord() + 5, box_y_koord() + 2 SAY "uvecati stari datdok za (dana) " GET _dana PICT "99"

   READ

   BoxC()

   IF LastKey() == K_ESC
      RETURN _ret
   ENDIF

   SELECT fin_pripr
   GO TOP

   DO WHILE !Eof()

      IF field->idkonto == _id_konto .AND. datval_prazan()

         _ret := .T. // bilo je promjena

         hRec := dbf_get_rec()
         hRec[ "datval" ] := field->datdok + _dana
         hRec[ "datdok" ] := _dat_dok

         dbf_update_rec( hRec )

      ENDIF
      SKIP
   ENDDO

   GO TOP

   RETURN _ret







STATIC FUNCTION fin_pripr_brisi_stavke_od_do()

   LOCAL nRet := 1
   LOCAL GetList := {}
   LOCAL nOd := 0
   LOCAL nDo := 0
   LOCAL nRbr

   Box(, 1, 31 )
   @ box_x_koord() + 1, box_y_koord() + 2 SAY "Brisi stavke od:" GET nOd VALID _rbr_fix( @nOd )
   @ box_x_koord() + 1, Col() + 1 SAY "do:" GET nDo VALID _rbr_fix( @nDo )
   READ
   BoxC()

   IF LastKey() == K_ESC .OR. ;
         Pitanje(, "Sigurno zelite brisati zapise ?", "N" ) == "N"
      RETURN 0
   ENDIF

   GO TOP

   DO WHILE !Eof()

      nRbr := field->rbr

      IF nRbr >= nOd .AND. nRbr <= nDo
         my_delete()
      ENDIF

      SKIP
   ENDDO

   my_dbf_pack()

   GO TOP

   RETURN nRet


// -----------------------------------------
// fiksiranje rednog broja
// -----------------------------------------
STATIC FUNCTION _rbr_fix( cStr )

   cStr := PadL( AllTrim( cStr ), 5 )

   RETURN .T.



FUNCTION IdPartner( cIdPartner )

   LOCAL cRet

   cRet := cIdPartner

   RETURN cRet



/* DifIdP(cIdPartner)
 *     Formatira cIdPartner na 6 mjesta ako mu je duzina 8
 *   param: cIdPartner - id partnera
 */

FUNCTION DifIdP( cIdPartner )
   RETURN 0



/* BrisiPBaze()
 *     Brisi pomocne baze
 */

FUNCTION BrisiPBaze()

   PushWA()

   SELECT F_PSUBAN
   my_dbf_zap()
   SELECT F_PANAL
   my_dbf_zap()
   SELECT F_PSINT
   my_dbf_zap()
   SELECT F_PNALOG
   my_dbf_zap()

   PopWA()

   RETURN ( NIL )


/* fin_tek_rec_2()
 *     Tekuci zapis
 */

FUNCTION fin_tek_rec_2()

   nSlog++
   @ box_x_koord() + 1, box_y_koord() + 2 SAY PadC( AllTrim( Str( nSlog ) ) + "/" + AllTrim( Str( nUkupno ) ), 20 )
   @ box_x_koord() + 2, box_y_koord() + 2 SAY "Obuhvaceno: " + Str( 0 )

   RETURN ( NIL )



/* fin_knjizenje_ostale_opcije()
 *     Ostale opcije koje se pozivaju sa <F10>
 */

FUNCTION fin_knjizenje_ostale_opcije()

   PRIVATE aOpc[ 1 ]

   aOpc[ 1 ] := "1. novi datum->datum, stari datum->dat.valute "
   // aOpc[ 2 ] := "2. podijeli nalog na vise dijelova"

   h[ 1 ] := h[ 2 ] := ""
   PRIVATE Izbor := 1
   PRIVATE am_x := box_x_koord(), am_y := box_y_koord()
   my_close_all_dbf()
   DO WHILE .T.
      Izbor := meni_0( "prip", aOpc, NIL, Izbor, .F. )
      DO CASE
      CASE Izbor == 0
         EXIT
      CASE izbor == 1
         SetDatUPripr()
         // CASE izbor == 2
         // PodijeliN()
      ENDCASE
   ENDDO
   box_x_koord( am_x )
   box_y_koord( am_y )
   o_fin_edit()

   RETURN .T.


FUNCTION BrDokOK()

   LOCAL nArr
   LOCAL lOK
   LOCAL nLenBrDok

   IF ( !IsRamaGlas() )
      RETURN .T.
   ENDIF
   nArr := Select()
   lOK := .T.
   nLenBrDok := Len( _brDok )

   select_o_konto( _idkonto )
   IF field->oznaka = "TD"
      SELECT rnal
      HSEEK PadR( _brDok, 10 )
      IF !Found() .OR. Empty( _brDok )
         MsgBeep( "Unijeli ste nepostojeci broj radnog naloga. Otvaram sifrarnik radnih##naloga da biste mogli izabrati neki od postojecih!" )
         P_fakt_objekti( @_brDok, 9, 2 )
         _brDok := PadR( _brDok, nLenBrDok )
         ShowGets()
      ENDIF
   ENDIF
   SELECT ( nArr )

   RETURN lOK




FUNCTION SetTekucaRJ( cRJ )

   set_metric( "fin_knjiz_tek_rj", my_home(), cRJ )

   RETURN .T.



FUNCTION GetTekucaRJ()
   RETURN fetch_metric( "fin_knjiz_tek_rj", my_home(), PadR( "", FIELD_LEN_FIN_RJ_ID ) )




// --------------------------------------------------------
// brisanje podataka pripreme po uslovu
// --------------------------------------------------------
STATIC FUNCTION brisi_fin_pripr_po_uslovu()

   LOCAL hFinParams
   LOCAL _od_broj, _do_broj, _partn, _konto, _opis, _br_veze, _br_nal, _tip_nal
   LOCAL _deleted := .F.
   LOCAL _delete_rec := .F.
   LOCAL _ok := .F.

   IF !_brisi_pripr_uslovi( @hFinParams )
      RETURN _ok
   ENDIF

   IF Pitanje(, "Sigurno zelite izvrsiti brisanje podataka (D/N)?", "N" ) == "N"
      RETURN _ok
   ENDIF

   // ovo su dati parametri...
   _od_broj := hFinParams[ "rbr_od" ]
   _do_broj := hFinParams[ "rbr_do" ]
   _partn := hFinParams[ "partn" ]
   _konto := hFinParams[ "konto" ]
   _opis := hFinParams[ "opis" ]
   _br_veze := hFinParams[ "veza" ]
   _br_nal := hFinParams[ "broj" ]
   _tip_nal := hFinParams[ "vn" ]

   SELECT fin_pripr
   // skini order
   SET ORDER TO
   GO TOP

   DO WHILE !Eof()

      _delete_rec := .F.

      // idemo sada na uslove i brisanje podataka...
      IF !Empty( _br_nal )
         _tmp := Parsiraj( _br_nal, "brnal" )
         IF &_tmp
            _delete_rec := .T.
         ENDIF
      ENDIF

      IF !Empty( _tip_nal )
         _tmp := Parsiraj( _tip_nal, "idvn" )
         IF &_tmp
            _delete_rec := .T.
         ENDIF
      ENDIF

      IF !Empty( _partn )
         _tmp := Parsiraj( _partn, "idpartner" )
         IF &_tmp
            _delete_rec := .T.
         ENDIF
      ENDIF

      IF !Empty( _konto )
         _tmp := Parsiraj( _konto, "idkonto" )
         IF &_tmp
            _delete_rec := .T.
         ENDIF
      ENDIF

      IF !Empty( _opis )
         _tmp := Parsiraj( _opis, "opis" )
         IF &_tmp
            _delete_rec := .T.
         ENDIF
      ENDIF

      IF !Empty( _br_veze )
         _tmp := Parsiraj( _br_veze, "brdok" )
         IF &_tmp
            _delete_rec := .T.
         ENDIF
      ENDIF


      IF ( _od_broj + _do_broj ) > 0 // redni brojevi
         IF field->rbr >= _od_broj .AND.  field->rbr <= _do_broj
            _delete_rec := .T.
         ENDIF
      ENDIF

      // brisi ako treba ?
      IF _delete_rec
         _deleted := .T.
         my_delete()
      ENDIF

      SKIP

   ENDDO

   SELECT fin_pripr
   SET ORDER TO TAG "1"
   GO TOP

   IF _deleted

      _ok := .T.

      my_dbf_pack()

      // renumerisi fin pripremu...
      sredi_rbr_fin_nalog( .T. )

   ELSE
      MsgBeep( "Nema stavki za brisanje po zadanom kriteriju !" )
   ENDIF

   RETURN _ok


// -------------------------------------------------------
// uslovi brisanja pripreme po zadatom uslovu
// -------------------------------------------------------
STATIC FUNCTION _brisi_pripr_uslovi( PARAM )

   LOCAL _ok := .F.
   LOCAL _x := 1
   LOCAL _od_broja := 0
   LOCAL _do_broja := 0
   LOCAL _partn := Space( 500 )
   LOCAL _konto := Space( 500 )
   LOCAL _opis := Space( 500 )
   LOCAL _br_veze := Space( 500 )
   LOCAL _vn := Space( 200 )
   LOCAL _br_nal := Space( 500 )

   Box(, 13, 70 )

   @ box_x_koord() + _x, box_y_koord() + 2 SAY "Brisanje pripreme po zadatom uslovu ***"

   ++_x
   ++_x
   @ box_x_koord() + _x, box_y_koord() + 2 SAY "brisi od rednog broja:" GET _od_broja PICT "9999999"
   @ box_x_koord() + _x, Col() + 1 SAY "do:" GET _do_broja PICT "9999999"

   ++_x
   ++_x
   @ box_x_koord() + _x, box_y_koord() + 2 SAY "               vrste naloga:" GET _vn PICT "@S30"

   ++_x
   @ box_x_koord() + _x, box_y_koord() + 2 SAY "             brojeve naloga:" GET _br_nal PICT "@S30"

   ++_x
   ++_x
   @ box_x_koord() + _x, box_y_koord() + 2 SAY "stavke koje sadrze partnere:" GET _partn PICT "@S30"

   ++_x
   @ box_x_koord() + _x, box_y_koord() + 2 SAY "   stavke koje sadrze konta:" GET _konto PICT "@S30"

   ++_x
   @ box_x_koord() + _x, box_y_koord() + 2 SAY "    stavke koje sadrze opis:" GET _opis PICT "@S30"

   ++_x
   @ box_x_koord() + _x, box_y_koord() + 2 SAY " stavke koje sadrze br.veze:" GET _br_veze PICT "@S30"

   READ

   BoxC()

   IF LastKey() == K_ESC
      RETURN _ok
   ENDIF

   // dodaj u matricu sa parametrima
   PARAM := hb_Hash()
   PARAM[ "rbr_od" ] := _od_broja
   PARAM[ "rbr_do" ] := _do_broja
   PARAM[ "partn" ] := _partn
   PARAM[ "konto" ] := _konto
   PARAM[ "opis" ] := _opis
   PARAM[ "veza" ] := _br_veze
   PARAM[ "broj" ] := _br_nal
   PARAM[ "vn" ] := _vn

   _ok := .T.

   RETURN _ok
