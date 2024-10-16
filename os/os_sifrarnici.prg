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


FUNCTION os_sifarnici()

   LOCAL nIzbor := 1
   LOCAL aOpc := {}
   LOCAL aOpcExe := {}
   LOCAL _opis

   _opis := "osnovna sredstva"

   IF gOsSii == "S"
      _opis := "sitan inventar"
   ENDIF

   AAdd( aOpc, PadR( "1. " + _opis, 40 ) )
   AAdd( aOpcExe, {|| p_os() } )

   AAdd( aOpc, "2. koeficijenti amortizacije"  )
   AAdd( aOpcExe, {|| p_amort() } )
   AAdd( aOpc, "3. koeficijenti revalorizacije" )
   AAdd( aOpcExe, {|| p_reval() } )
   AAdd( aOpc, "4. radne jedinice" )
   AAdd( aOpcExe, {|| p_rj() } )
   AAdd( aOpc, "---------------------------" )
   AAdd( aOpcExe, {|| NIL } )
   AAdd( aOpc, "6. konta" )
   AAdd( aOpcExe, {|| p_konto() } )
   //AAdd( aOpc, "7. grupacije K1" )
   //AAdd( aOpcExe, {|| p_k1() } )

   AAdd( aOpc, "8. partneri" )
   AAdd( aOpcExe, {|| p_partner() } )
   AAdd( aOpc, "9. valute" )
   AAdd( aOpcExe, {|| P_Valute() } )

   _o_sif_tables()

   f18_menu( "sifre", .F., nIzbor, aOpc, aOpcExe )

   my_close_all_dbf()

   RETURN .T.



FUNCTION P_OS( cId, dx, dy )

   LOCAL lNovi := .T., lRet
   LOCAL nWa := F_OS
   PRIVATE ImeKol
   PRIVATE Kol

   IF gOsSii == "S"
      nWa := F_SII
   ENDIF

   PushWA()

   IF cId != NIL .AND. !Empty( cId )
      select_o_os( "XXXXXXX" ) // cId je zadan, otvoriti samo dummy tabelu sa 0 zapisa
   ELSE
      select_o_os()
   ENDIF

   ImeKol := { { PadR( "Inv.Broj", 15 ), {|| id },     "id", {|| select_o_os_or_sii(), .T. }, {|| validacija_postoji_sifra( wId ) .AND. os_promjena_id_zabrana( lNovi ) } }, ;
      { PadR( "Naziv", 30 ), {|| naz },     "naz"      }, ;
      { PadR( "Kolicina", 8 ), {|| kolicina },    "kolicina"     }, ;
      { PadR( "jmj", 3 ), {|| jmj },    "jmj"     }, ;
      { PadR( "Datum", 8 ), {|| Datum },    "datum"     }, ;
      { PadR( "RJ", 2 ),    {|| idRj },    "idRj", {|| .T. }, {|| P_Rj( @wIdRj ) }   }, ;
      { PadR( "Konto", 7 ), {|| idkonto },    "idkonto", {|| .T. }, {|| P_Konto( @wIdKonto ) }     }, ;
      { PadR( "StAm", 8 ),  {|| IdAm },  "IdAm", {|| .T. }, {|| P_Amort( @wIdAm ) } }, ;
      { PadR( "StRev", 5 ), {|| IdRev + " " },  "IdRev", {|| .T. }, {|| P_Reval( @wIdRev ) }   }, ;
      { PadR( "NabVr", 15 ), {|| nabvr },  "nabvr", {|| .T. }, {|| os_validate_vrijednost( wnabvr, wotpvr ) } }, ;
      { PadR( "OtpVr", 15 ), {|| otpvr },  "otpvr", {|| .T. },  {|| os_validate_vrijednost( wnabvr, wotpvr ) }  };
      }

   /*
   IF os_sii_da_li_postoji_polje( "K1" )
      AAdd ( ImeKol, { PadC( "K1", 4 ), {|| k1 }, "k1", {|| .T. }, {|| P_K1( @wK1 ) } } )
    //  AAdd ( ImeKol, { PadC( "K1", 4 ), {|| k1 }, "k1", {|| .T. }, {|| .T. } } )
      AAdd ( ImeKol, { PadC( "K2", 2 ), {|| k2 }, "k2"   } )
      AAdd ( ImeKol, { PadC( "K3", 2 ), {|| k3 }, "k3"   } )
      AAdd ( ImeKol, { PadC( "Opis", 2 ), {|| opis }, "opis"   } )
   ENDIF
   */

   IF os_fld_partn_exist()
      AAdd ( ImeKol, { "Dobavljac", {|| idPartner }, "idPartner", {|| .T. }, {|| p_partner( @wIdPartner ) }   } )
   ENDIF

   IF os_sii_da_li_postoji_polje( "brsoba" )
      AAdd ( ImeKol, { PadC( "BrSoba", 6 ), {|| brsoba }, "brsoba"   } )
   ENDIF

   PRIVATE Kol := {}

   FOR i := 1 TO Len( ImeKol )
      AAdd( Kol, i )
   NEXT

   lRet := p_sifra( nWa, 1, f18_max_rows() - 15, f18_max_cols() - 15, "Lista stalnih sredstava", @cId, dx, dy, {| Ch | os_sif_key_handler( Ch, @lNovi ) } )

   PopWA()

   return lRet



FUNCTION os_validate_vrijednost( wNabVr, wOtpVr )

   @ box_x_koord() + 11, box_y_koord() + 50 SAY ( wNabvr - wOtpvr )

   RETURN .T.



FUNCTION os_sif_key_handler( Ch, lNovi )

   LOCAL nWa := F_OS_PROMJ
   LOCAL hRec
   LOCAL _sr_id

   lNovi := .T.

   IF gOsSii == "S"
      nWa := F_SII_PROMJ
   ENDIF

   _sr_id := field->id

   DO CASE

   CASE ( Ch == K_CTRL_T )

      SELECT ( nWa )
      lUsedPromj := .T.

      IF !Used()
         lUsedPromj := .F.
         o_os_sii_promj()
      ENDIF

      os_select_promj( _sr_id )
      //
      //SEEK _sr_id

      IF Found()
         Beep( 1 )
         Msg( "Sredstvo se ne moze brisati - prvo izbrisi promjene !" )
      ELSE
         select_o_os_or_sii()
         IF Pitanje(, "Sigurno zelite izbrisati ovo sredstvo ?", "N" ) == "D"
            hRec := dbf_get_rec()
            delete_rec_server_and_dbf( Alias(), hRec, 1, "FULL" )
         ENDIF
      ENDIF
      IF !lUsedPromj
         os_select_promj()
         USE
      ENDIF
      select_o_os_or_sii()

      RETURN 7
      // kao de_refresh, ali se zavrsava izvrsenje f-ja iz ELIB-a

   CASE ( Ch == K_F2 )
      // ispravka stavke
      lNovi := .F.

   ENDCASE

   RETURN DE_CONT



FUNCTION os_promjena_id_zabrana( lNovi )

   IF !lNovi .AND. wId <> field->id
      Beep( 1 )
      Msg( "Promjenu inventurnog broja ne vrsiti ovdje !" )
      RETURN .F.
   ENDIF

   RETURN .T.


FUNCTION P_AMORT( cId, dx, dy )

   LOCAL lRet
   PRIVATE ImeKol, Kol

   PushWA()

   IF cId != NIL .AND. !Empty( cId )
      select_o_amort( "XXXXXXX" ) // cId je zadan, otvoriti samo dummy tabelu sa 0 zapisa
   ELSE
      select_o_amort()
   ENDIF

   ImeKol := { { PadR( "Id", 8 ), {|| id },     "id", {|| .T. }, {|| validacija_postoji_sifra( wid ) }    }, ;
      { PadR( "Naziv", 25 ), {|| naz },     "naz"      }, ;
      { PadR( "Iznos", 7 ), {|| iznos },    "iznos"     };
      }
   Kol := { 1, 2, 3 }

   lRet := p_sifra( F_AMORT, 1, f18_max_rows() - 15, f18_max_cols() - 15, "Lista koeficijenata amortizacije", @cId, dx, dy )

   PopWa()

   RETURN lRet


FUNCTION P_REVAL( cId, dx, dy )

   LOCAL lRet
   PRIVATE ImeKol, Kol

   PushWA()

   IF cId != NIL .AND. !Empty( cId )
      select_o_reval( "XXXXXXX" ) // cId je zadan, otvoriti samo dummy tabelu sa 0 zapisa
   ELSE
      select_o_reval()
   ENDIF

   ImeKol := { { PadR( "Id", 4 ), {|| id },  "id", {|| .T. }, {|| validacija_postoji_sifra( wid ) }    }, ;
      { PadR( "Naziv", 10 ), {|| naz },     "naz"      }, ;
      { PadR( "I1", 7 ), {|| i1 },    "i1"     }, ;
      { PadR( "I2", 7 ), {|| i2 },    "i2"     }, ;
      { PadR( "I3", 7 ), {|| i3 },    "i3"     }, ;
      { PadR( "I4", 7 ), {|| i4 },    "i4"     }, ;
      { PadR( "I5", 7 ), {|| i5 },    "i5"     }, ;
      { PadR( "I6", 7 ), {|| i6 },    "i6"     }, ;
      { PadR( "I7", 7 ), {|| i7 },    "i7"     }, ;
      { PadR( "I8", 7 ), {|| i8 },    "i8"     }, ;
      { PadR( "I9", 7 ), {|| i9 },    "i9"     }, ;
      { PadR( "I10", 7 ), {|| i10 },    "i10"     }, ;
      { PadR( "I11", 7 ), {|| i11 },    "i11"     }, ;
      { PadR( "I12", 7 ), {|| i12 },    "i12"     };
      }
   Kol := { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14 }

   lRet := p_sifra( F_REVAL, 1, f18_max_rows() - 15, f18_max_cols() - 15, "Lista koeficijenata revalorizacije", @cId, dx, dy )
   PopWA()

   RETURN lRet



STATIC FUNCTION validacija_postoji_sifra( wid )

   LOCAL nTrec := RecNo()
   LOCAL _ret

   SEEK wId

   IF Found() .AND. Ch == K_CTRL_N
      Beep( 3 )
      _ret := .F.
   ELSE
      _ret := .T.
   ENDIF
   GO nTrec

   RETURN _ret



// --------------------------------------------------------------
// provjerava postojanje polja idpartner u os/sii tabelama
// --------------------------------------------------------------
FUNCTION os_fld_partn_exist()
   RETURN os_sii_da_li_postoji_polje( "idpartner" )



STATIC FUNCTION _o_sif_tables()

   o_valute()
// o_konto()

   o_os_sii()

   // o_amort()
   // o_reval()
   // o_rj()
// o_k1()
   // o_partner()
   // o_sifk()
   // o_sifv()

   RETURN .T.
