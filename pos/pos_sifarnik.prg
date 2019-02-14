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

MEMVAR ImeKol, Kol, gIdPos

FUNCTION p_pos_kase( cId, dx, dy )

   PRIVATE ImeKol
   PRIVATE Kol

   select_o_pos_kase()

   ImeKol := {}
   AAdd( ImeKol, { "Sifra/ID kase", {|| id }, "id" } )
   AAdd( ImeKol, { "Naziv kase", {|| Naz }, "Naz" } )
   AAdd( ImeKol, { "Lokacija kumulativa", {|| pPath }, "pPath" } )
   Kol := { 1, 2, 3 }

   RETURN p_sifra( F_KASE, 1, 10, 77, "Šifanik kasa/prodajnih mjesta", @cId, dx, dy )



FUNCTION Id2Naz()

   LOCAL nSel := Select()

   PushWA()
   select_o_roba( sast->id2 )
   popwa()

   RETURN Left( roba->naz, 25 )


FUNCTION LMarg()
   RETURN "   "



FUNCTION P_Odj( cId, dx, dy )

   PRIVATE ImeKol
   PRIVATE Kol := {}

   select_o_pos_odj()

   ImeKol := { { "ID ", {|| id }, "id", {|| .T. }, {|| validacija_postoji_sifra( wId ) } }, { PadC( "Naziv", 25 ), {|| naz }, "naz" }, { "Konto u KALK", {|| IdKonto }, "IdKonto" } }

   FOR i := 1 TO Len( ImeKol )
      AAdd( Kol, i )
   NEXT

   RETURN p_sifra( F_ODJ, 1, 10, 40, "Šifarnik odjeljenja", @cId, dx, dy )


/*
-- FUNCTION P_Dio( cId, dx, dy )

   PRIVATE ImeKol
   PRIVATE Kol := {}

   ImeKol := { { "ID ", {|| id }, "id", {|| .T. }, {|| validacija_postoji_sifra( wId ) } }, { PadC( "Naziv", 25 ), {|| naz }, "naz" } }

   FOR i := 1 TO Len( ImeKol )
      AAdd( Kol, i )
   NEXT

   RETURN p_sifra( F_DIO, 1, 10, 55, "Šifrarnik dijelova objekta", @cid, dx, dy )
*/

FUNCTION p_pos_strad( cId, dx, dy )

   LOCAL lRet

   PRIVATE ImeKol
   PRIVATE Kol := {}

   ImeKol := { { "ID ",  {|| id },       "id", {|| .T. }, {|| validacija_postoji_sifra( wId ) }      }, ;
      { PadC( "Naziv", 15 ), {|| naz },       "naz"       }, ;
      { "Prioritet", {|| PadC( prioritet, 9 ) }, "prioritet", {|| .T. }, {|| ( "0" <= wPrioritet ) .AND. ( wPrioritet <= "3" ) } } ;
      }

   PushWa()
   select_o_pos_strad()

   FOR i := 1 TO Len( ImeKol )
      AAdd( Kol, i )
   NEXT

   lRet := p_sifra( F_STRAD, 1, 10, 55, "Šifarnik statusa radnika", @cid, dx, dy )
   PopWA()

   RETURN lRet


FUNCTION P_Osob( cId, dx, dy )

   LOCAL xRet, i

   PRIVATE ImeKol
   PRIVATE Kol := {}

   // SELECT F_OSOB
   // IF !Used()
   // o_pos_osob()
   // ENDIF
   PushWa()

   select_o_pos_osob()


   ImeKol := { { "ID ",          {|| id },    "id", {|| .T. }, {|| validacija_postoji_sifra( wId ) } }, ;
      { PadC( "Naziv", 40 ), {|| naz },  "naz"    }, ;
      { "Korisn.sifra", {|| korsif }, "korsif" }, ;
      { "Status",       {|| STATUS }, "status" };
      }

   FOR i := 1 TO Len( ImeKol )
      AAdd( Kol, i )
   NEXT

   xRet := p_sifra( F_OSOB, 2, 10, 55, "Šifarnik osoblja", @cid, dx, dy, {| nCh | pos_osob_key_handler( nCh ) } )
   PopWa()

   RETURN xRet


FUNCTION pos_osob_key_handler( Ch )

   LOCAL lSystemLevel := ( pos_admin() )
   LOCAL nVrati := DE_CONT
   LOCAL hRec

   DO CASE

   CASE Ch == K_CTRL_N

      IF gPosSamoProdaja == "D"
         MsgBeep( "SamoProdaja=D#Nemate ovlastenje za ovu opciju !" )
         nVrati := DE_CONT
      ELSE

         IF lSystemLevel

            // setuj varijable globalne
            set_global_memvars_from_dbf()

            _korsif := Space( 6 )

            IF pos_get_osob( .T. ) <> K_ESC

               // azuriranje OSOB.DBF
               _korsif := CryptSC( _korsif )

               APPEND BLANK
               hRec := get_hash_record_from_global_vars()
               update_rec_server_and_dbf( Alias(), hRec, 1, "FULL" )

               nVrati := DE_REFRESH

            ENDIF
         ENDIF
      ENDIF

   CASE Ch == K_F2

      IF gPosSamoProdaja == "D"
         MsgBeep( "SamoProdaja=D#Nemate ovlastenje za ovu opciju !" )
         nVrati := DE_CONT
      ELSE

         IF lSystemLevel

            set_global_memvars_from_dbf()
            _korsif := CryptSC( _korsif )

            IF pos_get_osob( .F. ) <> K_ESC
               // azuriranje OSOB.DBF
               _korsif := CryptSC( _korsif )
               // daj mi iz globalnih varijabli
               hRec := get_hash_record_from_global_vars()

               update_rec_server_and_dbf( Alias(), hRec, 1, "FULL" )

               nVrati := DE_REFRESH

            ENDIF
         ENDIF
      ENDIF

   CASE Ch == K_CTRL_T

      IF gPosSamoProdaja == "D"
         MsgBeep( "Nemate ovlastenje za ovu opciju !" )
         nVrati := DE_CONT
      ELSE
         IF lSystemLevel
            IF Pitanje(, "Izbrisati korisnika " + Trim( naz ) + ":" + CryptSC( korsif ) + " D/N ?", "N" ) == "D"

               SELECT osob
               hRec := dbf_get_rec()
               delete_rec_server_and_dbf( Alias(), hRec, 1, "FULL" )
               nVrati := DE_REFRESH

            ENDIF
         ENDIF
      ENDIF
   CASE Ch == K_ESC .OR. Ch == K_ENTER
      nVrati := DE_ABORT
   ENDCASE

   IF ch == k_alt_r() .OR. ch == k_alt_s() .OR. ch == K_CTRL_N .OR. ch == K_F2 .OR. ch == K_F4 .OR. ch == K_CTRL_A .OR. ch == K_CTRL_T .OR. ch == K_ENTER
      ch := 0
   ENDIF

   RETURN nVrati




FUNCTION pos_get_osob( fNovi )

   LOCAL cLevel
   LOCAL GetList := {}

   Box( "", 4, 60, .F., "Unos novog korisnika,sifre" )

   SET CURSOR ON

   IF fNovi .OR. pos_admin()
      @ box_x_koord() + 1, box_y_koord() + 2 SAY8 "Šifra radnika (ID)." GET _id VALID validacija_postoji_sifra( _id )
   ELSE
      @ box_x_koord() + 1, box_y_koord() + 2 SAY8 "Šifra radnika (ID). " + _id
   ENDIF

   @ box_x_koord() + 2, box_y_koord() + 2 SAY "Ime radnika........" GET _naz

   READ

   select_o_pos_strad( gStRad )
   cLevel := strad->prioritet

   // SELECT strad
   select_o_pos_strad( _status )


   select_o_pos_osob()

   // level tekuceg korisnika > level
   IF ( cLevel > strad->prioritet )
      MsgBeep( "Ne mozete mjenjati sifru" )
   ELSE
      @ box_x_koord() + 3, box_y_koord() + 2 SAY "Sifra.............." GET _korsif PICTURE "@!" VALID vpsifra2( _korsif, _id )
      @ box_x_koord() + 4, box_y_koord() + 2 SAY "Status............." GET _status VALID p_pos_strad( @_status )
   ENDIF

   READ

   BoxC()

   RETURN LastKey()



STATIC FUNCTION VPSifra2( cSifra, cIme )

   LOCAL lRet := .T.
   LOCAL nObl := Select()

   IF Empty( cSifra )
      Beep ( 3 )
      RETURN ( .F. )
   ENDIF

   RETURN lRet


FUNCTION PomMenu1( aNiz )

   LOCAL xP := Row()
   LOCAL yP := Col()
   LOCAL xN
   LOCAL yN
   LOCAL dP := Len( aNiz ) + 1
   LOCAL sP := 0

   AEval( aNiz, {| x | IF( Len( x[ 1 ] + x[ 2 ] ) > sP, sP := Len( x[ 1 ] + x[ 2 ] ), ) } )
   sP += 3
   xN := IF( xP > 11, xP - dP, xP + 1 )
   yN := IF( yP > 39, yP - sP, yP + 1 )
   box_crno_na_zuto( xN, yN, xN + dP, yN + sP - 1, "POMOC" )

   FOR i := 1 TO dP - 1
      @ xN + i, yN + 1 SAY PadR( aNiz[ i, 1 ] + "-" + aNiz[ i, 2 ], sP - 2 )
   NEXT

   @ xP, yP SAY ""

   RETURN .T.



/*
FUNCTION P_Barkod( cBK )

   LOCAL fRet := .F.
   LOCAL nRec := RecNo()

   PushWA()
   SET ORDER TO TAG "BARKOD"
   SEEK cBK
   IF !Empty( cBK ) .AND. Found() .AND. nRec <> RecNo()
      MsgBeep( "Isti barkod pridruzen je sifri: " + id + " ??!" )
      PopWa()
      RETURN .F.
   ENDIF

   // trazi alternativne sifre
   IF !Empty( cBK )
      cID := ""
      ImaUSifV( "ROBA", "BARK", cBK, @cId )
      IF !Empty( cID )
         select_o_roba( cId ) // sifra nadjena!
         MsgBeep( "Isti barkod pridruzen je sifri: " + id + " ??!" )
         PopWa()
         RETURN .F.
      ENDIF
   ENDIF

   PopWa()

   RETURN .T.
*/

FUNCTION pos_roba_block( cCh )

   DO CASE

   CASE Upper( Chr( cCh ) ) == "P"
      IF gen_all_plu()
         RETURN DE_REFRESH
      ENDIF

   ENDCASE

   RETURN DE_CONT


FUNCTION pos_prodajno_mjesto()

   RETURN gIdPos
