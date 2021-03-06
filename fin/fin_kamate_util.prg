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


// -----------------------------------
// ctrl-K - generisi mjesecne uplate
// ----------------------------------
FUNCTION fin_kamate_generisi_mj_uplate()

   LOCAL nRataIznos
   LOCAL nDanUplate
   LOCAL cNaredni

   nRataIznos := 313
   nDanUplate := 15
   cNaredni := "T"

   Box(, 3, 70 )

   @ box_x_koord() + 1, box_y_koord() + 2 SAY "Iznos mjesecne rate ?" GET nRataIznos ;
      PICT "99999.99"

   @ box_x_koord() + 2, box_y_koord() + 2 SAY "Uplata na dan u mjesecu ?"  GET nDanUplate ;
      PICT "99"

   @ box_x_koord() + 3, box_y_koord() + 2 SAY "Uplata pocinje od tekuceg od ovog (T) ili narednog (N) mjeseca ?"  GET cNaredni  ;
      PICT "@!" ;
      VALID cNaredni $ "TN"
   READ
   BoxC()

   IF LastKey() == K_ESC
      RETURN 0
   ENDIF

   fill( nRataIznos, nDanUplate, ( cNaredni == "N" ) )



STATIC FUNCTION fill( nRataIznos, nDanUplate, lNaredni )

   SELECT kam_pripr
   GO TOP

   my_flock()

   Scatter()
   nOsn := _osnovica
   nMonth := Month( _datOd )
   nYear := Year( _datOd )

   IF lNaredni
      add_month( @nMonth, @nYear )
   ENDIF

   _datDo := d_m_y( nDanUplate, nMonth, nYear )

   Gather()

   DO WHILE !Eof()

      APPEND BLANK
      nOsn := nOsn - nRataIznos
      _osnovica := nOsn
      _osndug := nOsn
      _datOd := d_m_y( nDanUplate + 1, nMonth, nYear )
      add_month( @nMonth, @nYear )
      _datDo := d_m_y( nDanUplate, nMonth, nYear )

      Gather()

      // glavnica je potrosena
      IF Round( nOsn, 2 ) <= 0
         EXIT
      ENDIF

   ENDDO

   my_unlock()

   RETURN


// ---------------------------------------
// dodaj mjesec
// --------------------------------------
STATIC FUNCTION add_month( nMonth, nYear )

   IF nMonth == 12
      nYear ++
      nMonth := 1
   ELSE
      nMonth ++
   ENDIF

   RETURN .T.



STATIC FUNCTION d_m_y( nDay, nMonth, nYear )

   LOCAL cPom

   cPom := ""
   cPom += PadL( AllTrim( Str( nYear ) ), 4, "0" )
   cPom += PadL( AllTrim( Str( nMonth ) ), 2, "0" )
   cPom += PadL( AllTrim( Str( nDay ) ), 2, "0" )

   RETURN SToD( cPom )


// -------------------------------------------------
// kontrola cjelovitosti kamatnih stopa
// -------------------------------------------------
FUNCTION kontrola_cjelovitosti_ks()

   LOCAL _dat2

   O_KS
   GO TOP

   _dat2 := field->DatDo
   SKIP 1

   DO WHILE !Eof()

      IF DToC( field->DatOd - 1 ) != DToC( _dat2 )
         Msg( 'Pogresan "DatOd" na stopi ID=' + id + ' !', 3 )
      ENDIF
      _dat2 := field->DatDo
      SKIP 1
   ENDDO

   my_close_all_dbf()

   RETURN .T.
