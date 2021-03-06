/*
 * This file is part of the bring.out FMK, a free and open source
 * accounting software suite,
 * Copyright (c) 1996-2011 by bring.out doo Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including FMK specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_FMK.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */


#include "f18.ch"


STATIC __partn
STATIC _x_pos
STATIC _y_pos


FUNCTION browse_rugov( cId )

   LOCAL nLenTbl := 12
   LOCAL nWidthTbl := 65
   LOCAL GetList := {}

   PRIVATE cIdUgov

   PRIVATE ImeKol
   PRIVATE Kol

   _x_pos := Min( 20, f18_max_rows() - 10 )
   _y_pos := f18_max_cols() - 15

   cIdUgov := cId

   Box(, _x_pos, _y_pos )


   set_a_kol( @ImeKol, @Kol )
   o_rugov( cIdUgov )

   set_cursor_on()

   @ box_x_koord() + 1, box_y_koord() + 1 SAY ""

   ?? "Ugovor:", ugov->id, ugov->naz, ugov->DatOd

   __partn := ugov->idpartner

   my_browse( "", _x_pos, _y_pos, {|| ugov_browse_key_handler( cIdUgov ) }, "", "",,,,, 2 )


   SELECT ugov
   BoxC()

   SET FILTER TO

   RETURN .T.

/*
STATIC FUNCTION set_f_tbl( cIdUgov )

   LOCAL cFilt := ""

   cFilt := "id == " + dbf_quote( cIdUgov )
   SET FILTER TO &cFilt
   GO TOP

   RETURN .T.
*/


// -------------------------------------
// setovanje kolona pregleda
// -------------------------------------
STATIC FUNCTION set_a_kol( aImeKol, aKol )

   aImeKol := {}
   aKol := {}

   AAdd( aImeKol, { "ID roba",   {|| IdRoba } } )
   AAdd( aImeKol, { PadC( "Kol.", Len( fakt_pic_kolicina() ) ), {|| Transform( Kolicina, fakt_pic_kolicina() ) } } )

   IF rugov->( FieldPos( "cijena" ) ) <> 0
      AAdd( aImeKol, { "Cijena", {|| Transform( cijena, fakt_pic_iznos() ) },  "cijena"    } )
   ENDIF

   AAdd( aImeKol, { "Rabat",   {|| Rabat }  } )
   AAdd( aImeKol, { "Porez",   {|| Porez }  } )

   // IF rugov->( FieldPos( "K1" ) ) <> 0
   AAdd( aImeKol, { "K1", {|| K1 },    "K1"    } )
   AAdd( aImeKol, { "K2", {|| K2 },    "K2"    } )
   // ENDIF

   // IF rugov->( FieldPos( "dest" ) ) <> 0
   AAdd( aImeKol, { "Dest.", {|| get_dest_info( __partn, dest, 65 ) }, "dest"  } )
   // ENDIF

   FOR i := 1 TO Len( aImeKol )
      AAdd( aKol, i )
   NEXT

   RETURN .T.



STATIC FUNCTION ugov_browse_key_handler( cIdUgov )

   LOCAL nRet := DE_CONT
   LOCAL _rec

   // prikazi destinaciju
   s_box_dest()

   DO CASE

   CASE Ch == K_CTRL_N

      nRet := edit_rugov( .T. )

   CASE Ch == K_F2

      nRet := edit_rugov( .F. )

   CASE Ch == K_CTRL_T

      IF Pitanje(, "Izbrisati stavku ?", "N" ) == "D"
         _rec := dbf_get_rec()
         delete_rec_server_and_dbf( Alias(), _rec, 1, "FULL" )
      ENDIF

      nRet := DE_REFRESH
   ENDCASE

   RETURN nRet



// prikazuje box sa informacijama o destinaciji...
STATIC FUNCTION s_box_dest()

   get_dest_binfo( _x_pos, _y_pos, __partn, rugov->dest )

   RETURN .T.




FUNCTION edit_rugov( lNovi )

   LOCAL cIdRoba
   LOCAL nKolicina
   LOCAL cDestinacija
   LOCAL nRabat
   LOCAL nPorez
   LOCAL nCijena
   LOCAL lCijena := .F.
   LOCAL lK1 := .F.

   // LOCAL lDest := .F.
   LOCAL cK1
   LOCAL cK2
   LOCAL nX := 1
   LOCAL nBoxLen := 20
   LOCAL hRec
   LOCAL GetList := {}

   cIdRoba := IdRoba
   nKolicina := kolicina
   nRabat := rabat
   nPorez := porez

   // IF is_dest()
   // lDest := .T.
   // ENDIF

   // IF rugov->( FieldPos( "K1" ) ) <> 0
   cK1 := k1
   cK2 := k2
   lK1 := .T.
   // ENDIF

   // IF rugov->( FieldPos( "cijena" ) ) <> 0
   nCijena := cijena
   lCijena := .T.
   // ENDIF

   // IF lDest
   cDestinacija := dest
   // ENDIF

   Box(, 8, 75, .F. )

   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "Roba", nBoxLen ) GET cIdRoba PICT "@!" VALID P_Roba( @cIDRoba )


   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "Destinacija:", nBoxLen ) GET cDestinacija PICT "@!" VALID {|| Empty( cDestinacija ) .OR. p_destinacije( @cDestinacija, __partn ) }

   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 PadL( "Količina", nBoxLen ) GET nKolicina PICT "99999999.999" VALID num_veci_od_nula( nKolicina )

   // IF lCijena
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "Cijena", nBoxLen ) GET nCijena PICT kalk_pic_cijena_bilo_gpiccdem() VALID num_veci_od_nula( nCijena )
   // ENDIF

   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "Rabat", nBoxLen ) GET nRabat PICT "99.999"

   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "Porez", nBoxLen ) GET nPorez PICT "99.99"

   // IF lK1
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "K1", nBoxLen ) GET cK1 PICT "@!"
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "K2", nBoxLen ) GET cK2 PICT "@!"
   // ENDIF

   READ

   BoxC()

   IF LastKey() == K_ESC
      RETURN DE_CONT
   ENDIF

   IF lNovi
      APPEND BLANK
      hRec := dbf_get_rec()
      hRec[ "id" ] := cIdUgov
   ELSE
      hRec := dbf_get_rec()
   ENDIF


   hRec[ "idroba" ] := cIdRoba
   hRec[ "kolicina" ] := nKolicina
   hRec[ "rabat" ] := nRabat
   hRec[ "porez" ] := nPorez

   // IF lDest
   hRec[ "dest" ] := cDestinacija
   // ENDIF

   // IF lCijena
   hRec[ "cijena" ] := nCijena
   // ENDIF

   // IF lK1
   hRec[ "k1" ] := cK1
   hRec[ "k2" ] := cK2
   // ENDIF


   IF !update_rec_server_and_dbf( Alias(), hRec, 1, "FULL" )
      delete_with_rlock()
   ENDIF

   RETURN DE_REFRESH



STATIC FUNCTION num_veci_od_nula( nNum )

   LOCAL lRet := .T.

   IF nNum <= 0
      lRet := .F.
   ENDIF

   IF lRet == .F.
      MsgBeep( "Vrijednost mora biti > 0 !" )
   ENDIF

   RETURN lRet




FUNCTION vrati_opis_ugovora( cIdUgov )

   LOCAL cOpis := ""

   PushWA()

   IF o_rugov( cIdUgov )
      cOpis += Trim( idroba ) + " " + AllTrim( Transform( kolicina, fakt_pic_kolicina() ) ) + " x " + AllTrim( Transform( cijena, fakt_pic_iznos() ) )
   ENDIF

   PopWa()

   RETURN cOpis
