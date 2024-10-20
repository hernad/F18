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


FUNCTION Adresar()

   PushWA()

   //o_adresar()
   // Select( F_SIFK )
   // IF !Used()
   // o_sifk()
   // ENDIF

   // Select( F_SIFV )
   // IF !Used()
   // use_sql_sifv( PadR( "ADRES", 8 ) )
   // ENDIF
   p_adresar()

   USE

   PopWa()

   RETURN NIL


FUNCTION p_adresar( cId, dx, dy )

   LOCAL fkontakt := .F.
   PRIVATE ImeKol := {}
   PRIVATE Kol := {}

   o_adres()

   IF FieldPos( "Kontakt" ) <> 0
      fKontakt := .T.
   ENDIF

   AAdd( ImeKol, { "Naziv firme", {|| id     }, "id" } )
   AAdd( ImeKol, { "Telefon ", {|| naz }, "naz" } )
   AAdd( ImeKol, { "Telefon 2", {|| tel2 }, "tel2" } )
   AAdd( ImeKol, { "FAX      ", {|| tel3 }, "tel3" } )
   IF fkontakt
      AAdd( ImeKol, { "RJ ", {|| rj  }, "rj" } )
   ENDIF
   AAdd( ImeKol, { "Adresa", {|| adresa  }, "adresa"   } )
   AAdd( ImeKol, { "Mjesto", {|| mjesto  }, "mjesto"   } )
   IF fkontakt
      AAdd( ImeKol, { "PTT", {|| PTT }, "PTT"  } )
      AAdd( ImeKol, { "Drzava", {|| drzava     }, "drzava"  } )
   ENDIF
   AAdd( ImeKol, { "Dev.ziro-r.", {|| ziror   }, "ziror"   } )
   AAdd( ImeKol, { "Din.ziro-r.", {|| zirod  },  "zirod"   } )

   IF fkontakt
      AAdd( ImeKol, { "Kontakt", {|| kontakt     }, "kontakt"  } )
      AAdd( ImeKol, { "K7", {|| k7 }, "k7"  } )
      AAdd( ImeKol, { "K8", {|| k8 }, "k8"  } )
      AAdd( ImeKol, { "K9", {|| k9 }, "k9"  } )
   ENDIF

   FOR i := 1 TO Len( ImeKol )
      AAdd( Kol, i )
   NEXT

   PushWA()

   sifk_fill_ImeKol( PadR( "ADRES", 8 ), @ImeKol, @Kol )

   PopWa()

   RETURN p_sifra( F_ADRES, 1, f18_max_rows() - 10, f18_max_cols() - 5, "Adresar:", @cId, dx, dy, {| Ch | AdresBlok( Ch ) } )




FUNCTION Pkoverte()

   IF Pitanje(, "Stampati koverte ?", "N" ) == "N"
      RETURN DE_CONT
   ENDIF

   aDBF := {}
   AAdd( aDBf, { 'ID', 'C',  50,   0 } )
   AAdd( aDBf, { 'RJ', 'C',  30,   0 } )
   AAdd( aDBf, { 'KONTAKT', 'C',  30,   0 } )
   AAdd( aDBf, { 'NAZ', 'C',  15,   0 } )
   AAdd( aDBf, { 'TEL2', 'C',  15,   0 } )
   AAdd( aDBf, { 'TEL3', 'C',  15,   0 } )
   AAdd( aDBf, { 'MJESTO', 'C',  15,   0 } )
   AAdd( aDBf, { 'PTT', 'C',  6,   0 } )
   AAdd( aDBf, { 'ADRESA', 'C',  50,   0 } )
   AAdd( aDBf, { 'DRZAVA', 'C',  22,   0 } )
   AAdd( aDBf, { 'ziror', 'C',  30,   0 } )
   AAdd( aDBf, { 'zirod', 'C',  30,   0 } )
   AAdd( aDBf, { 'K7', 'C',  1,   0 } )
   AAdd( aDBf, { 'K8', 'C',  2,   0 } )
   AAdd( aDBf, { 'K9', 'C',  3,   0 } )
   DBCREATE2( "koverte", aDBf )

   usex ( "koverte", NIL, .T. )
   my_dbf_zap()

   INDEX ON  "id+naz"  TAG "ID"

   SELECT adres
   GO TOP
   MsgO( "Priprema koverte.dbf" )

   cIniName := my_home() + 'ProIzvj.ini'

   cWinKonv := my_get_from_ini( "DelphiRb", "Konverzija", "3" )
   DO WHILE !Eof()
      Scatter()
      SELECT koverte
      APPEND BLANK
      KonvZnWin( @_Id, cWinKonv )
      KonvZnWin( @_Adresa, cWinKonv )
      KonvZnWin( @_Naz, cWinKonv )
      KonvZnWin( @_RJ, cWinKonv )
      KonvZnWin( @_KONTAKT, cWinKonv )
      KonvZnWin( @_Mjesto, cWinKonv )
      Gather()
      SELECT adres
      SKIP
   ENDDO

   MsgC()

   SELECT koverte
   USE

   f18_rtm_print( "adres", "koverte", "id" )

   RETURN DE_CONT


FUNCTION AdresBlok( Ch )

   IF Ch == K_F8  // koverte
      PKoverte()
   ENDIF

   RETURN DE_CONT
