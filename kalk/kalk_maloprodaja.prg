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

STATIC s_cRadnaProdavnica := "XX"

MEMVAR ImeKol, Kol

FUNCTION kalk_maloprodaja()

   LOCAL aOpc := {}
   LOCAL aOpcExe := {}
   LOCAL nIzbor := 1
   LOCAL bTekProdavnica := {|| "1. radna prodavnica: '" +  radna_prodavnica() + "' : " +  get_pkonto_by_prodajno_mjesto( radna_prodavnica() ) }

   AAdd( aOpc, bTekProdavnica )
   AAdd( aOpcExe, {|| kalk_mp_set_radna_prodavnica() } )
   AAdd( aOpc,   "2. inicijalizacija" )
   AAdd( aOpcExe, {|| kalk_mp_inicijalizacija() } )
   AAdd( aOpc,   "3. cijene" )
   AAdd( aOpcExe, {|| p_roba_prodavnica() } )

   f18_menu( "mp", .F.,  nIzbor, aOpc, aOpcExe )

   //f18_sql_schema( "roba" )
   RETURN .T.


FUNCTION kalk_mp_set_radna_prodavnica()

   LOCAL cProdajnoMjesto := "1 "
   LOCAL GetList := {}

   Box(, 3, 60 )
   @ box_x_koord() + 1, box_y_koord() + 2 SAY "Prodajno mjesto" GET cProdajnoMjesto VALID !Empty( cProdajnoMjesto )

   READ
   BoxC()

   IF LastKey() == K_ESC
      RETURN .F.
   ENDIF

   // p15.roba
   s_cRadnaProdavnica := cProdajnoMjesto
   set_a_sql_sifarnik( radna_prodavnica_roba_sql_tabela(), "ROBA_PRODAVNICA", F_ROBA_PRODAVNICA )

   RETURN .T.

FUNCTION radna_prodavnica( cSet )

   IF cSet != NIL
      s_cRadnaProdavnica := cSet
   ENDIF

   RETURN PadR( s_cRadnaProdavnica, 2 )


FUNCTION radna_prodavnica_sql_schema()

      RETURN "p" + AllTrim( s_cRadnaProdavnica )

FUNCTION radna_prodavnica_roba_sql_tabela()

   RETURN "p" + AllTrim( s_cRadnaProdavnica ) + ".roba"


FUNCTION dbUseArea_run_query( cQuery, nWa, cAlias )

   LOCAL oError

   SELECT ( nWa )
   BEGIN SEQUENCE WITH {| err | Break( err ) }
      dbUseArea( .F., "SQLMIX", cQuery,  cAlias, NIL, NIL )
   RECOVER USING oError
      ?E cQuery, oError:description
      RaiseError( "dbUseArea SQLMIX: qry=" + cQuery )
   END SEQUENCE

   RETURN .T.


FUNCTION get_pkonto_by_prodajno_mjesto( cIdProdajnoMjesto )

   LOCAL cQuery := "select id from " + f18_sql_schema( "koncij" ) + " where idprodmjes=" + sql_quote( cIdProdajnoMjesto ) + " LIMIT 1"

   dbUseArea_run_query( cQuery, F_TMP_1, "TMP" )

   RETURN TMP->id



FUNCTION kalk_mp_inicijalizacija()

   LOCAL cPKonto := get_pkonto_by_prodajno_mjesto( radna_prodavnica() )
   LOCAL cQuery := "select distinct(idroba), " + f18_sql_schema( "roba" ) + ".mpc2" +;
         " from " + f18_sql_schema( "kalk_kalk" ) + ;
         " LEFT JOIN " + f18_sql_schema( "roba" ) + " ON " + f18_sql_schema( "kalk_kalk") + ".idroba = roba.id" +;
         " WHERE " + f18_sql_schema( "kalk_kalk" ) + ".pkonto=" + sql_quote( cPKonto ) +;
         " AND roba.mpc2 <> 0" +;
         " ORDER BY idroba"

   /*
   -- select distinct(idroba), fmk.roba.mpc2 from fmk.kalk_kalk
     LEFT JOIN fmk.roba ON kalk_kalk.idroba = roba.id
    where kalk_kalk.pkonto='13315  ' and roba.mpc2 <> 0
    */

   IF ( radna_prodavnica() == "XX" )
      Alert( "setovati prodavnicu!" )
      RETURN .F.
   ENDIF

   dbUseArea_run_query( cQuery, F_TMP_1, "TMP" )

   Box( "#" + radna_prodavnica() + " / " + cPKonto, 1, 50 )

   cQuery := "delete from " + radna_prodavnica_roba_sql_tabela()
   dbUseArea_run_query( cQuery, F_TMP_2, "TMP2" )

   SELECT TMP
   GO TOP
   DO WHILE !Eof()
      @ box_x_koord() + 1, box_y_koord() + 2 SAY TMP->IDROBA
      cQuery := "insert into " + radna_prodavnica_roba_sql_tabela() + " select * from " + f18_sql_schema( "roba" ) + " where id=" + sql_quote( TMP->idroba )
      dbUseArea_run_query( cQuery, F_TMP_2, "TMP2" )
      SELECT TMP
      SKIP
   ENDDO
   BoxC()

   RETURN .T.


FUNCTION p_roba_prodavnica( cId, dx, dy, cTagTraziPoSifraDob )

   LOCAL xRet
   LOCAL bRoba
   LOCAL lArtGroup := .F.
   LOCAL nBrowseRobaNazivLen := 40
   LOCAL nI
   LOCAL cPomTag
   LOCAL cPom, cPom2

   PRIVATE ImeKol
   PRIVATE Kol

   IF cTagTraziPoSifraDob == NIL
      cTagTraziPoSifraDob := ""
   ENDIF

   IF ( radna_prodavnica() == "XX" )
      Alert( "setovati prodavnicu!" )
      RETURN .F.
   ENDIF
   ImeKol := {}

   PushWA()

   SELECT F_ROBA_PRODAVNICA
   USE

   IF cId != NIL .AND. !Empty( cId )
      select_o_roba_prodavnica( "XXXXXXX" ) // cId je zadan, otvoriti samo dummy tabelu sa 0 zapisa
   ELSE
      select_o_roba_prodavnica()
   ENDIF

   AAdd( ImeKol, { PadC( "ID", 10 ),  {|| field->id }, "id", {|| .T. }, {|| valid_sifarnik_id_postoji( wId ) } } )
   AAdd( ImeKol, { PadC( "Naziv", nBrowseRobaNazivLen ), {|| PadR( field->naz, nBrowseRobaNazivLen ) }, "naz", {|| .T. }, {|| .T. } } )
   AAdd( ImeKol, { PadC( "JMJ", 3 ), {|| field->jmj },   "jmj"    } )

   // AAdd( ImeKol, { PadC( "PLU kod", 8 ),  {|| PadR( fisc_plu, 10 ) }, "fisc_plu", {|| .T. }, {|| .T. } } )
   AAdd( ImeKol, { PadC( "S.dobav.", 13 ), {|| PadR( sifraDob, 13 ) }, "sifradob"   } )


   // AAdd( ImeKol, { PadC( "VPC", 10 ), {|| Transform( field->VPC, "999999.999" ) }, "vpc", NIL, NIL, NIL, kalk_pic_cijena_bilo_gpiccdem()  } )
   // AAdd( ImeKol, { PadC( "VPC2", 10 ), {|| Transform( field->VPC2, "999999.999" ) }, "vpc2", NIL, NIL, NIL, kalk_pic_cijena_bilo_gpiccdem()   } )
   // AAdd( ImeKol, { PadC( "Plan.C", 10 ), {|| Transform( field->PLC, "999999.999" ) }, "PLC", NIL, NIL, NIL, kalk_pic_cijena_bilo_gpiccdem()    } )
   // AAdd( ImeKol, { PadC( "MPC1", 10 ), {|| Transform( field->MPC, "999999.999" ) }, "mpc", NIL, NIL, NIL, kalk_pic_cijena_bilo_gpiccdem()  } )

   AAdd( ImeKol, { PadC( "MPC2", 10 ), {|| Transform( field->MPC2, "999999.999" ) }, "mpc2", NIL, NIL, NIL, mp_pic_cijena()  } )
/*
   FOR nI := 2 TO 2

      cPom := "mpc" + AllTrim( Str( nI ) )
      cPom2 := '{|| transform(' + cPom + ',"999999.999")}'


          cPrikazi := fetch_metric( "roba_prikaz_" + cPom, NIL, "D" )

          IF cPrikazi == "D"
             AAdd( ImeKol, { PadC( Upper( cPom ), 10 ), &( cPom2 ), cPom, NIL, NIL, NIL, kalk_pic_cijena_bilo_gpiccdem() } )
          ENDIF


   NEXT
*/
   // AAdd( ImeKol, { PadC( "NC", 10 ), {|| Transform( field->NC, kalk_pic_cijena_bilo_gpiccdem() ) }, "NC", NIL, NIL, NIL, kalk_pic_cijena_bilo_gpiccdem()  } )
   AAdd( ImeKol, { "Tarifa", {|| field->IdTarifa }, "IdTarifa", {|| .T. }, {|| P_Tarifa( @wIdTarifa ) }   } )
   // AAdd( ImeKol, { "Tip", {|| " " + field->Tip + " " }, "Tip", {|| .T. }, {|| wTip $ " TUCKVPSXY" }, NIL, NIL, NIL, NIL, 27 } )
   AAdd ( ImeKol, { PadC( "BARKOD", 14 ), {|| field->BARKOD }, "BarKod", {|| .T. }, {|| roba_valid_barkod( Ch, @wId, @wBarkod ) }  } )

   // AAdd ( ImeKol, { PadC( "MINK", 10 ), {|| Transform( field->MINK, "999999.99" ) }, "MINK"   } )

   // AAdd ( ImeKol, { PadC( "K1", 4 ), {|| field->k1 }, "k1"   } )
   // AAdd ( ImeKol, { PadC( "K2", 4 ), {|| field->k2 }, "k2", {|| .T. }, {|| .T. }, NIL, NIL, NIL, NIL, 35   } )
   // AAdd ( ImeKol, { PadC( "N1", 12 ), {|| field->N1 }, "N1"   } )
   // AAdd ( ImeKol, { PadC( "N2", 12 ), {|| field->N2 }, "N2", {|| .T. }, {|| .T. }, NIL, NIL, NIL, NIL, 35   } )

   AAdd ( ImeKol, { PadC( "Nova cijena", 20 ), {|| Transform( zanivel, "999999.999" ) }, "zanivel", NIL, NIL, NIL, mp_pic_cijena() } )
   // AAdd ( ImeKol, { PadC( "Nova cijena/2", 20 ), {|| Transform( zaniv2, "999999.999" ) }, "zaniv2", NIL, NIL, NIL, kalk_pic_cijena_bilo_gpiccdem()  } )

   // AAdd ( ImeKol, { "Id konto", {|| idkonto }, "idkonto", {|| .T. }, {|| Empty( widkonto ) .OR. P_Konto( @widkonto ) }   } )


   Kol := {}

   FOR nI := 1 TO Len( ImeKol )
      AAdd( Kol, nI )
   NEXT

   /*
   SELECT ROBA_PRODAVNICA
   sifk_fill_ImeKol( "ROBA", @ImeKol, @Kol )
   */

   // bRoba := {| Ch | kalk_roba_key_handler( Ch ) }
   bRoba := NIL

   IF is_roba_trazi_po_sifradob() .AND. !Empty( cTagTraziPoSifraDob )
      cPomTag := Trim( cTagTraziPoSifraDob )
      IF find_roba_by_sifradob( cId )
         cId := roba->id
      ENDIF
   ELSE
      cPomTag := "ID"
   ENDIF

   xRet := p_sifra( F_ROBA_PRODAVNICA, ( cPomTag ), f18_max_rows() - 11, f18_max_cols() - 5, "Artikli prodavnica " + radna_prodavnica(), @cId, dx, dy, bRoba,,,,, { "ID" } )

   PopWa()

   RETURN xRet



FUNCTION select_o_roba_prodavnica( cId )

   SELECT ( F_ROBA_PRODAVNICA )
   IF Used()
      IF RecCount() > 1 .AND. cId == NIL
         RETURN .T.
      ELSEIF cId != NIL .AND. cId == roba->id
         RETURN .T. // vec pozicionirani na roba.id
      ELSE
         USE // samo zatvoriti postojecu tabelu, pa ponovo otvoriti sa cId
      ENDIF
   ENDIF

   RETURN o_roba_prodavnica( cId )


FUNCTION o_roba_prodavnica( cId )

   LOCAL cTabela := radna_prodavnica_roba_sql_tabela()

   SELECT ( F_ROBA_PRODAVNICA )
   IF !use_sql_sif( cTabela, .T., "ROBA_PRODAVNICA", cId  )
      error_bar( "o_sql", "open sql " + cTabela )
      RETURN .F.
   ENDIF
   SET ORDER TO TAG "ID"
   IF cId != NIL
      SEEK cId
   ENDIF

   RETURN !Eof()

FUNCTION mp_pic_cijena()

   RETURN "999999.99"
