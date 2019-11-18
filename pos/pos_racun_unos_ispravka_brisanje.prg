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

MEMVAR _idroba, _cijena, _ncijena, _kolicina, _jmj, _robanaz, _idtarifa

FUNCTION pos_racun_ispravka()

   LOCAL aConds
   LOCAL aProcs
   LOCAL cColor

   pos_unset_key_handler_ispravka_racuna()

   cColor := SetColor()
   prikaz_dostupnih_opcija_crno_na_zuto( { ;
      _u( " <B>-Briši stavku" ), ;
      _u( " <Esc>-Završi" ) } )
   SetColor( cColor )

   pos_racun_browse_objekat():autolite := .T.
   pos_racun_browse_objekat():configure()
   aConds := { {| nCh | Upper( Chr( nCh ) ) == "B" } }
   aProcs := { {|| pos_brisi_stavku_racuna() } }

   ShowBrowse( pos_racun_browse_objekat(), aConds, aProcs )
   pos_racun_browse_objekat():autolite := .F.
   pos_racun_browse_objekat():dehilite()
   pos_racun_browse_objekat():stabilize()
   pos_set_key_handler_ispravka_racuna()
   box_crno_na_zuto_end()

   RETURN .T.

FUNCTION pos_ispravi_stavku_racuna()

   LOCAL GetList := {}

   SELECT _pos_pripr
   IF RecCount2() == 0
      MsgBeep ( "Račun ne sadrži niti jednu stavku!#Ispravka nije moguća!", 20 )
      RETURN ( DE_CONT )
   ENDIF

   Scatter()
   set_cursor_on()
   Box(, 3, 80 )
   @ box_x_koord() + 1, box_y_koord() + 3 SAY8 "    Artikal:" GET _idroba PICT PICT_POS_ARTIKAL ;
      WHEN pos_when_racun_artikal( @_idroba ) VALID pos_valid_racun_artikal( @_idroba, GetList, 1, 28 )
   @ box_x_koord() + 2, box_y_koord() + 3 SAY8 "     Cijena:" GET _Cijena  PICTURE "99999.999" WHEN pos_when_racun_cijena_ncijena( _idroba, _cijena, _ncijena )
   @ box_x_koord() + 3, box_y_koord() + 3 SAY8 "   količina:" GET _Kolicina VALID pos_valid_racun_kolicina( _idroba, @_kolicina, _cijena, _ncijena ) PICT "999999.999"

   READ

   SELECT _pos_pripr
   @ box_x_koord() + 3, box_y_koord() + 25 SAY Space( 11 )

   IF LastKey() <> K_ESC
      IF ( _pos_pripr->IdRoba <> _IdRoba  .OR. roba->tip == "T" ) .OR. _pos_pripr->Kolicina <> _Kolicina
         _robanaz := roba->naz
         _jmj := roba->jmj
         IF !( roba->tip == "T" )
            _cijena := pos_get_mpc( roba->id )
         ENDIF
         _idtarifa := roba->idtarifa
         //pos_racun_iznos( pos_racun_iznos() + _cijena * _kolicina - _pos_pripr->cijena * _pos_pripr->kolicina )
         //pos_racun_popust( pos_racun_popust() + _ncijena * _kolicina - _pos_pripr->ncijena * _pos_pripr->kolicina )

         my_rlock()
         Gather()
         my_unlock()

         // ELSEIF ( _pos_pripr->Kolicina <> _Kolicina )
         // pos_racun_iznos( pos_racun_iznos() + _cijena * _kolicina - _pos_pripr->cijena * _pos_pripr->kolicina)
         // pos_racun_popust( pos_racun_popust() + _ncijena * _kolicina - _pos_pripr->ncijena * _pos_pripr->kolicina)
         //
         // RREPLACE Kolicina WITH _Kolicina
      ENDIF
   ENDIF
   BoxC()

   pos_racun_prikazi_ukupno()
   pos_racun_browse_objekat():refreshCurrent()
   DO WHILE !pos_racun_browse_objekat():stable
      pos_racun_browse_objekat():Stabilize()
   ENDDO

   RETURN ( DE_CONT )



FUNCTION pos_brisi_stavku_racuna()

   SELECT _pos_pripr

   IF RecCount2() == 0
      MsgBeep ( "Priprema računa je prazna !#Brisanje nije moguće !", 20 )
      RETURN ( DE_REFRESH )
   ENDIF

   Beep ( 2 )
   //pos_racun_iznos( pos_racun_iznos() - _pos_pripr->cijena * _pos_pripr->kolicina )
   //pos_racun_popust( pos_racun_popust() - _pos_pripr->ncijena * _pos_pripr->kolicina )
   pos_racun_sumarno_stavka( _pos_pripr->idroba, _pos_pripr->cijena, _pos_pripr->ncijena, 0 )
   my_delete()
   pos_racun_prikazi_ukupno()

   pos_racun_browse_objekat():refreshAll()
   DO WHILE !pos_racun_browse_objekat():stable
      pos_racun_browse_objekat():Stabilize()
   ENDDO

   RETURN ( DE_REFRESH )
