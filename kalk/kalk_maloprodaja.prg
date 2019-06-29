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

STATIC s_nPosProdavnica := 0

MEMVAR ImeKol, Kol, Ch
MEMVAR wId, wIdTarifa, wTip, wBarKod

FUNCTION kalk_maloprodaja()

   LOCAL aOpc := {}
   LOCAL aOpcExe := {}
   LOCAL nIzbor := 1
   LOCAL bTekProdavnica := {|| PadR( "1. radna prodavnica: '" +  pos_prodavnica_str() + "' : " +  get_pkonto_by_prodajno_mjesto( pos_prodavnica() ), 46 ) }

   AAdd( aOpc, bTekProdavnica )

   AAdd( aOpcExe, {|| kalk_mp_set_pos_prodavnica() } )

   AAdd( aOpc,   "2. inicijalizacija" )
   AAdd( aOpcExe, {|| kalk_mp_inicijalizacija() } )

   AAdd( aOpc,  "3. pos realizacija [49]->[42]" )
   AAdd( aOpcExe, {|| kalk_49_to_42_unos() } )

   AAdd( aOpc,  "4. pos zaduženje iz magacina [22]->[11]" )
   AAdd( aOpcExe, {|| kalk_22_to_11_unos() } )

   AAdd( aOpc,  "5. obrada zahtjeva za sniženje [71]->[79]" )
   AAdd( aOpcExe, {|| kalk_71_to_79_unos() } )

   AAdd( aOpc,  "6. pos direktni ulaz od dobavljača [89]->[81]" )
   AAdd( aOpcExe, {|| kalk_89_to_81_unos() } )

   // AAdd( aOpc,   "3. šifre robe u prodavnici" )
   // AAdd( aOpcExe, {|| p_roba_prodavnica() } )

   f18_menu( "mp", .F.,  nIzbor, aOpc, aOpcExe )

   RETURN .T.


FUNCTION kalk_mp_set_pos_prodavnica()

   LOCAL nProdajnoMjesto := pos_prodavnica()
   LOCAL GetList := {}

   Box(, 3, 60 )
   @ box_x_koord() + 1, box_y_koord() + 2 SAY "Prodajno mjesto" GET nProdajnoMjesto VALID nProdajnoMjesto <> 0 PICT "999"
   READ
   BoxC()

   IF LastKey() == K_ESC
      RETURN .F.
   ENDIF

   // p15.roba
   pos_prodavnica( nProdajnoMjesto )

   set_a_sql_sifarnik( pos_prodavnica_roba_sql_tabela(), "ROBA_PRODAVNICA", F_ROBA_PRODAVNICA )

   RETURN .T.


FUNCTION pos_prodavnica_param( nSet )

   LOCAL nProdavnica

   IF nSet <> NIL
      f18_set_metric( "public", "pos_prod", NIL, nSet )
      nProdavnica := nSet
   ELSE
      nProdavnica := f18_fetch_metric( "public", "pos_prod", NIL, 0 )
   ENDIF

   RETURN nProdavnica


FUNCTION pos_prodavnica( nSet )

   IF nSet != NIL
      s_nPosProdavnica := nSet
      pos_prodavnica_param( nSet )
   ELSE
      s_nPosProdavnica := pos_prodavnica_param()
   ENDIF

   RETURN s_nPosProdavnica


FUNCTION pos_prodavnica_str()
   RETURN AllTrim( Str( pos_prodavnica() ) )


FUNCTION pos_prodavnica_sql_schema()

   RETURN "p" + AllTrim( Str( s_nPosProdavnica ) )

FUNCTION pos_prodavnica_roba_sql_tabela()

   RETURN pos_prodavnica_sql_schema() + ".roba"


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


FUNCTION get_pkonto_by_prodajno_mjesto( nProdavnica )

   LOCAL cQuery := "select id from " + f18_sql_schema( "koncij" ) + " where prod=" + sql_quote( nProdavnica ) + " LIMIT 1"

   IF nProdavnica == 0
      RETURN PadC( "<?>",  FIELD_LENGTH_IDKONTO )
   ENDIF
   dbUseArea_run_query( cQuery, F_TMP_1, "TMP" )

   RETURN TMP->id


FUNCTION set_prodavnica_by_pkonto( cPKonto )

      LOCAL cQuery := "select prod from " + f18_sql_schema( "koncij" ) + " where trim(id)=" + sql_quote( Trim(cPKonto) ) + " LIMIT 1"
      LOCAL nProdavnica
      dbUseArea_run_query( cQuery, F_TMP_1, "TMP" )
      nProdavnica := TMP->prod
      USE
      pos_prodavnica( nProdavnica )
      RETURN nProdavnica


FUNCTION kalk_mp_inicijalizacija()

   LOCAL nRbr, cQuery, dDatDok := danasnji_datum(), cBrDok
   LOCAL nKolicina
   LOCAL cNulaDN := "D"
   LOCAL lPreskoci0
   LOCAL nMpc, cSigurno := Space( 4 )

   LOCAL GetList := {}
   LOCAL cPKonto := get_pkonto_by_prodajno_mjesto( pos_prodavnica() )

   IF Pitanje(, "Inicijalizovati prodavnicu " + pos_prodavnica_str() + "?", "N" ) == "N"
      RETURN .F.
   ENDIF

   Alert( _u( "Hint sigurnosni kod: Slično ko jedan avion + godina bitna za Bosnu" ) )
   Box(, 3, 60 )
   @ box_x_koord() + 1, box_y_koord() + 2 SAY8 "Sigurnosni kod operacije:" GET cSigurno PICT "@!" ;
      VALID {|| cSigurno == 'MI95' }
   @ box_x_koord() + 2, box_y_koord() + 2 SAY8 "Datum dokumente" GET dDatDok
   @ box_x_koord() + 3, box_y_koord() + 2 SAY8 "Šifre sa stanjem 0 D/N" GET cNulaDN VALID cNulaDN $ "DN" PICT "@!"

   READ
   BoxC()
   IF LastKey() == K_ESC
      RETURN .F.
   ENDIF

   cQuery := "select distinct(idroba) " + ;
      " FROM " + f18_sql_schema( "kalk_kalk" ) + ;
      " LEFT JOIN " + f18_sql_schema( "roba" ) + " ON " + f18_sql_schema( "kalk_kalk" ) + ".idroba = roba.id" + ;
      " WHERE " + f18_sql_schema( "kalk_kalk" ) + ".pkonto=" + sql_quote( cPKonto ) + ;
      " ORDER BY idroba"

   IF ( pos_prodavnica() == 0 )
      Alert( "setovati prodavnicu!" )
      RETURN .F.
   ENDIF

   dbUseArea_run_query( cQuery, F_TMP_1, "TMP" )

   // cQuery := "delete from " + pos_prodavnica_roba_sql_tabela()
   // dbUseArea_run_query( cQuery, F_TMP_2, "TMP2" )

   SELECT TMP
   GO TOP
   nRbr := 1
   select_o_kalk_pripr()
   IF RecCount() == 0 .OR. Pitanje(, "Izbrisati pripremu ?", "N" ) == "D"
      my_dbf_zap()
   ELSE
      my_close_all_dbf()
      RETURN .F.
   ENDIF

   Box( "#" + AllTrim( Str( pos_prodavnica() ) ) + " / " + cPKonto, 1, 50 )

   cBrDok := kalk_novi_brdok( "02" )
   SELECT TMP
   DO WHILE !Eof()
      @ box_x_koord() + 1, box_y_koord() + 2 SAY TMP->IDROBA
      cQuery := "SELECT * FROM public.kalk_prod_stanje_sa_kartice(" + sql_quote( cPKonto ) + "," + sql_quote( TMP->idroba ) + ")"
      dbUseArea_run_query( cQuery, F_TMP_2, "TMP2" )
      // rezultat:
      // count - broj stavki kartice, nv_dug - nv duguje, nv_pot, mpv_dug - mpv duguje, mpv_pot, kol_dug - ulaz kolicina, kol_pot - izlaz nKolicina
      // mpc_sa_pdv
      select_o_roba( tmp->idroba )
      select_o_tarifa( roba->idtarifa )

      nKolicina := tmp2->kol_dug - tmp2->kol_pot
      nMpC := tmp2->mpc_sa_pdv

      lPreskoci0 := .F.
      IF Round( nKolicina, 4 ) <= 0
         IF cNulaDN == "D"
            lPreskoci0 := .F.
            nMpc := kalk_get_mpc_by_koncij_pravilo( cPKonto )
         ELSE
            lPreskoci0 := .T.
         ENDIF
      ENDIF

      IF lPreskoci0 .OR. Round( nMpc, 4 ) == 0
         SELECT TMP
         SKIP
         LOOP
      ENDIF

      SELECT kalk_pripr
      APPEND BLANK
      REPLACE idfirma WITH self_organizacija_id(), ;
         idvd WITH "02", ;
         datdok WITH dDatDok, ;
         brdok WITH cBrDok, ;
         pkonto WITH cPKonto, ;
         pu_i WITH "0",   ;
         rbr WITH nRbr++, ;
         idroba WITH tmp->idroba, ;
         idtarifa WITH tarifa->id, ;
         kolicina WITH nKolicina, ;
         mpcsapp WITH nMpc, ;
         tmarza with "%", ;
         tmarza2 with "%", ;
         mpc WITH mpc_bez_pdv_by_tarifa( tarifa->id, nMpc )

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

   IF ( pos_prodavnica() == 0 )
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
   AAdd( ImeKol, { PadC( "S.dobav.", 13 ), {|| PadR( field->sifraDob, 13 ) }, "sifradob"   } )
   AAdd( ImeKol, { PadC( "MPC", 10 ), {|| Transform( field->MPC, "999999.999" ) }, "mpc", NIL, NIL, NIL, mp_pic_cijena()  } )
   AAdd( ImeKol, { "Tarifa", {|| field->IdTarifa }, "IdTarifa", {|| .T. }, {|| P_Tarifa( @wIdTarifa ) }   } )
   AAdd( ImeKol, { "Tip", {|| " " + field->Tip + " " }, "Tip", {|| .T. }, {|| wTip $ " TU" }, NIL, NIL, NIL, NIL, 27 } )
   AAdd ( ImeKol, { PadC( "BARKOD", 14 ), {|| field->BARKOD }, "BarKod", {|| .T. }, {|| roba_valid_barkod( Ch, @wId, @wBarkod ) }  } )

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
   xRet := p_sifra( F_ROBA_PRODAVNICA, ( cPomTag ), f18_max_rows() - 11, f18_max_cols() - 5, "Artikli prodavnica " + pos_prodavnica_str(), @cId, dx, dy, bRoba,,,,, { "ID" } )
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

   LOCAL cTabela := pos_prodavnica_roba_sql_tabela()

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
