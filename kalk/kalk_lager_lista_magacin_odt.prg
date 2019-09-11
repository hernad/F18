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


FUNCTION kalk_magacin_llm_odt( hParams )

   IF !_gen_xml( hParams )
      MsgBeep( "Problem sa generisanjem podataka ili nema podataka !" )
      RETURN .F.
   ENDIF

   download_template( "kalk_llm.odt", "ccf6c854f27e109357678b781716f38ba58bd72f7c901e699317fc04cc5031df" )

   IF generisi_odt_iz_xml( "kalk_llm.odt", my_home() + "data.xml" )
      prikazi_odt()
   ENDIF

   RETURN .T.


STATIC FUNCTION _gen_xml( hParams )

   LOCAL _idfirma := hParams[ "idfirma" ]
   LOCAL _sintk := hParams[ "idkonto" ]
   LOCAL _art_naz := hParams[ "roba_naz" ]
   LOCAL _group_1 := hParams[ "group_1" ]
   LOCAL _group_2 := hParams[ "group_2" ]
   LOCAL lPrikazatiNulaNV := hParams[ "nule" ]
   LOCAL _svodi_jmj := hParams[ "svodi_jmj" ]
   LOCAL _vpc_iz_sif := hParams[ "vpc_sif" ]
   LOCAL _idroba, _idkonto, _vpc_sif, _jmj
   LOCAL _rbr := 0
   LOCAL _t_ulaz_p := _t_izlaz_p := 0
   LOCAL _ulaz, _izlaz, _vpv_u, _vpv_i, _vpv_ru, _vpv_ri, _nv_u, _nv_i
   LOCAL _t_ulaz, _t_izlaz, _t_vpv_u, _t_vpv_i, _t_vpv_ru, _t_vpv_ri, _t_nv_u, _t_nv_i, _t_nv, _t_rabat
   LOCAL _rabat
   LOCAL _ok := .F.
   LOCAL nKonvertJmj := 1
   LOCAL nKolicinaStanje := 0

   _t_ulaz := _t_izlaz := _t_nv_u := _t_nv_i := _t_vpv_u := _t_vpv_i := 0
   _t_rabat := _t_vpv_ru := _t_vpv_ri := _t_nv := 0

   select_o_konto( hParams[ "idkonto" ] )

   SELECT kalk

   create_xml( my_home() + "data.xml" )
   xml_head()

   xml_subnode( "ll", .F. )

   // header
   xml_node( "dat_od", DToC( hParams[ "datum_od" ] ) )
   xml_node( "dat_do", DToC( hParams[ "datum_do" ] ) )
   xml_node( "dat", DToC( Date() ) )
   xml_node( "kid", to_xml_encoding( hParams[ "idkonto" ] ) )
   xml_node( "knaz", to_xml_encoding( AllTrim( konto->naz ) ) )
   xml_node( "fid", to_xml_encoding( self_organizacija_id() ) )
   xml_node( "fnaz", to_xml_encoding( self_organizacija_naziv() ) )
   xml_node( "tip", "MAGACIN" )

   DO WHILE !Eof() .AND. field->idfirma + field->mkonto = _idfirma + _sintk .AND. ispitaj_prekid()

      _idroba := field->idroba

      _ulaz := 0
      _izlaz := 0

      _vpv_u := 0
      _vpv_i := 0

      _vpv_ru := 0
      _vpv_ri := 0

      _nv_u := 0
      _nv_i := 0

      _rabat := 0

      select_o_roba( _idroba )

      IF ( !Empty( _art_naz ) .AND. At( AllTrim( _art_naz ), AllTrim( roba->naz ) ) == 0 )
         SELECT kalk
         SKIP
         LOOP
      ENDIF

      IF !Empty( _group_1 ) .OR. !Empty( _group_2 )
         IF !IsInGroup( _group_1, _group_2, roba->id )
            SELECT kalk
            SKIP
            LOOP
         ENDIF
      ENDIF

      SELECT kalk

      IF roba->tip $ "TUY"
         SKIP
         LOOP
      ENDIF

      _idkonto := field->mkonto

      DO WHILE !Eof() .AND. _idfirma + _idkonto + _idroba == field->idfirma + field->mkonto + field->idroba .AND. ispitaj_prekid()

         IF roba->tip $ "TU"
            SKIP
            LOOP
         ENDIF

         IF field->mu_i == "1"
            IF !( field->idvd $ "12#22#94" )
               _kolicina := field->kolicina - field->gkolicina - field->gkolicin2
               _ulaz += _kolicina
               kalk_sumiraj_kolicinu( _kolicina, 0, @_t_ulaz_p, @_t_izlaz_p )
               IF koncij->naz == "P2"
                  _vpv_u += Round( roba->plc * ( kolicina - gkolicina - gkolicin2 ), gZaokr )
                  _vpv_ru += Round( roba->plc * ( kolicina - gkolicina - gkolicin2 ), gZaokr )
               ELSE
                  _vpv_u += Round( roba->vpc * ( kolicina - gkolicina - gkolicin2 ), gZaokr )
                  _vpv_ru += Round( field->vpc * ( kolicina - gkolicina - gkolicin2 ), gZaokr )
               ENDIF

               _nv_u += Round( nc * ( kolicina - gkolicina - gkolicin2 ), gZaokr )
            ELSE
               _kolicina := -field->kolicina
               _izlaz += _kolicina
               kalk_sumiraj_kolicinu( 0, _kolicina, @_t_ulaz_p, @_t_izlaz_p )
               IF koncij->naz == "P2"
                  _vpv_i -= Round( roba->plc * kolicina, gZaokr )
                  _vpv_ri -= Round( roba->plc * kolicina, gZaokr )
               ELSE
                  _vpv_i -= Round( roba->vpc * kolicina, gZaokr )
                  _vpv_ri -= Round( field->vpc * kolicina, gZaokr )
               ENDIF
               _nv_i -= Round( nc * kolicina, gZaokr )
            ENDIF

         ELSEIF field->mu_i == "5"
            _kolicina := field->kolicina
            _izlaz += _kolicina
            kalk_sumiraj_kolicinu( 0, _kolicina, @_t_ulaz_p, @_t_izlaz_p )
            IF koncij->naz == "P2"
               _vpv_i += Round( roba->plc * kolicina, gZaokr )
               _vpv_ri += Round( roba->plc * kolicina, gZaokr )
            ELSE
               _vpv_i += Round( roba->vpc * kolicina, gZaokr )
               _vpv_ri += Round( field->vpc * kolicina, gZaokr )
            ENDIF
            _rabat += Round(  rabatv / 100 * vpc * kolicina, gZaokr )
            _nv_i += Round( nc * kolicina, gZaokr )

         ELSEIF field->mu_i == "8"
            _kolicina := -field->kolicina
            _izlaz += _kolicina
            kalk_sumiraj_kolicinu( 0, _kolicina, @_t_ulaz_p, @_t_izlaz_p )
            IF koncij->naz == "P2"
               _vpv_i += Round( roba->plc * ( - kolicina ), gZaokr )
               _vpv_ri += Round( roba->plc * ( - kolicina ), gZaokr )
            ELSE
               _vpv_i += Round( roba->vpc * ( - kolicina ), gZaokr )
               _vpv_ri += Round( field->vpc * ( - kolicina ), gZaokr )
            ENDIF
            _rabat += Round(  rabatv / 100 * vpc * ( - kolicina ), gZaokr )
            _nv_i += Round( nc * ( - kolicina ), gZaokr )
            _kolicina := -field->kolicina
            _ulaz += _kolicina
            kalk_sumiraj_kolicinu( _kolicina, 0, @_t_ulaz_p, @_t_izlaz_p )

            IF koncij->naz == "P2"
               _vpv_u += Round( - roba->plc * ( kolicina - gkolicina - gkolicin2 ), gZaokr )
               _vpv_ru += Round( - roba->plc * ( kolicina - gkolicina - gkolicin2 ), gZaokr )
            ELSE
               _vpv_u += Round( - roba->vpc * ( kolicina - gkolicina - gkolicin2 ), gZaokr )
               _vpv_ru += Round( - field->vpc * ( kolicina - gkolicina - gkolicin2 ), gZaokr )
            ENDIF

            _nv_u += Round( - nc * ( kolicina - gkolicina - gkolicin2 ), gZaokr )
         ENDIF

         SKIP

      ENDDO

      IF lPrikazatiNulaNV .OR. ( Round( _ulaz - _izlaz, 4 ) <> 0 .OR. Round( _nv_u - _nv_i, 4 ) <> 0 )

         xml_subnode( "items", .F. )

         xml_node( "rbr", AllTrim( Str( ++_rbr ) ) )
         xml_node( "id", to_xml_encoding( _idroba ) )
         xml_node( "naz", to_xml_encoding( AllTrim( roba->naz ) ) )
         xml_node( "tar", to_xml_encoding( AllTrim( roba->idtarifa ) ) )
         xml_node( "barkod", to_xml_encoding( AllTrim( roba->barkod ) ) )

         _jmj := roba->jmj
         _vpc_sif := roba->vpc
         _nc_sif := roba->nc

         IF _svodi_jmj
            nKonvertJmj := svedi_na_jedinicu_mjere( 1, _idroba, @_jmj )
            _jmj := PadR( _jmj, Len( roba->jmj ) )
         ELSE
            nKonvertJmj := 1
         ENDIF

         xml_node( "jmj", to_xml_encoding( _jmj ) )
         xml_node( "vpc", Str( _vpc_sif, 12, 3 ) )

         xml_node( "ulaz", Str( nKonvertJmj * _ulaz, 12, 3 )  )
         xml_node( "izlaz", Str( nKonvertJmj * _izlaz, 12, 3 )  )
         xml_node( "stanje", Str( nKonvertJmj * ( _ulaz - _izlaz ), 12, 3 )  )

         xml_node( "nvu", Str( _nv_u, 12, 3 )  )
         xml_node( "nvi", Str( _nv_i, 12, 3 )  )
         xml_node( "nv", Str( _nv_u - _nv_i, 12, 3 )  )

         nKolicinaStanje := nKonvertJmj * ( _ulaz - _izlaz )
         __nv := ( _nv_u - _nv_i )

         IF Round( nKolicinaStanje, 4 ) == 0 .OR. Round( __nv, 4 ) == 0
            _nc := 0
         ELSE
            _nc := Round( __nv / nKolicinaStanje, 3 )
         ENDIF

         xml_node( "nc", Str( _nc, 12, 3 ) )

         IF _vpc_iz_sif
            xml_node( "vpvu", Str( _vpv_u, 12, 3 )  )
            xml_node( "rabat", Str( _rabat, 12, 3 )  )
            xml_node( "vpvi", Str( _vpv_i, 12, 3 )  )
            xml_node( "vpv", Str( _vpv_u - _vpv_i, 12, 3 )  )
         ELSE
            xml_node( "vpvu", Str( _vpv_ru, 12, 3 )  )
            xml_node( "rabat", Str( _rabat, 12, 3 )  )
            xml_node( "vpvi", Str( _vpv_ri, 12, 3 )  )
            xml_node( "vpv", Str( _vpv_ru - _vpv_ri, 12, 3 )  )
         ENDIF

         // kontrola !
         IF _nc_sif <> _nc
            xml_node( "err", "ERR" )
         ELSE
            xml_node( "err", "" )
         ENDIF

         xml_subnode( "items", .T. )

      ENDIF

      _t_ulaz += nKonvertJmj * _ulaz
      _t_izlaz += nKonvertJmj * _izlaz
      _t_rabat += _rabat
      _t_nv_u += _nv_u
      _t_nv_i += _nv_i
      _t_nv += ( _nv_u - _nv_i )
      _t_vpv_u += _vpv_u
      _t_vpv_i += _vpv_i
      _t_vpv_ru += _vpv_ru
      _t_vpv_ri += _vpv_ri

   ENDDO

   xml_node( "ulaz", Str( _t_ulaz, 12, 3 ) )
   xml_node( "izlaz", Str( _t_izlaz, 12, 3 ) )
   xml_node( "stanje", Str( _t_ulaz - _t_izlaz, 12, 3 ) )
   xml_node( "nvu", Str( _t_nv_u, 12, 3 ) )
   xml_node( "nvi", Str( _t_nv_i, 12, 3 ) )
   xml_node( "nv", Str( _t_nv, 12, 3 ) )

   IF _vpc_iz_sif
      xml_node( "vpvu", Str( _t_vpv_u, 12, 3 )  )
      xml_node( "rabat", Str( _t_rabat, 12, 3 )  )
      xml_node( "vpvi", Str( _t_vpv_i, 12, 3 )  )
      xml_node( "vpv", Str( _t_vpv_u - _t_vpv_i, 12, 3 )  )
   ELSE
      xml_node( "vpvu", Str( _t_vpv_ru, 12, 3 )  )
      xml_node( "rabat", Str( _t_rabat, 12, 3 )  )
      xml_node( "vpvi", Str( _t_vpv_ri, 12, 3 )  )
      xml_node( "vpv", Str( _t_vpv_ru - _t_vpv_ri, 12, 3 )  )
   ENDIF

   xml_subnode( "ll", .T. )

   close_xml()

   my_close_all_dbf()

   IF _rbr > 0
      _ok := .T.
   ENDIF

   RETURN _ok
