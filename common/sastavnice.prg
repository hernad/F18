/*
 * This file is part of the bring.out FMK, a free and open source
 * accounting software suite,
 * Copyright (c) 1994-2018 by bring.out doo Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including FMK specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_FMK.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */


#include "f18.ch"

MEMVAR wId, wTip, wIdTarifa, wId2
MEMVAR ImeKol, Kol
MEMVAR cIdProizvodTekuci // show_sast, PRIVATE var cIdProizvodTekuci

/*

-- Table: fmk.sast

-- DROP TABLE fmk.sast;

CREATE TABLE fmk.sast
(
  id character(10),              PROIZVOD
  match_code character(10),
  r_br numeric(4,0),
  id2 character(10),              SIROVINA
  kolicina numeric(20,5),
  k1 character(1),
  k2 character(1),
  n1 numeric(20,5),
  n2 numeric(20,5)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE fmk.sast
  OWNER TO hernad;

-- Index: fmk.sast_id1

-- DROP INDEX fmk.sast_id1;

CREATE INDEX sast_id1
  ON fmk.sast
  USING btree
  (id COLLATE pg_catalog."default", id2 COLLATE pg_catalog."default");




*/


/*
  CREATE_INDEX( "ID", "ID+ID2", sast )
  CREATE_INDEX( "IDRBR", "ID+STR(R_BR,4,0)+ID2", sast )
  CREATE_INDEX( "NAZ", "ID2+ID", _sast )
*/

FUNCTION p_roba_sastavnice( cId, dx, dy )

   PRIVATE ImeKol
   PRIVATE Kol

   o_roba_tip_p()

   set_a_kol( @ImeKol, @Kol )

   RETURN p_sifra( F_ROBA_P, "ID", f18_max_rows() - 15, f18_max_cols() - 3, ;
      "Gotovi proizvodi: <ENTER> Unos norme, <Ctrl-F4> Kopiraj normu, <F7>-lista norm.", ;
      @cId, dx, dy, {| nCh | sast_key_handler( nCh ) } )



STATIC FUNCTION show_sast()

   PRIVATE cIdProizvodTekuci
   PRIVATE ImeKol
   PRIVATE Kol

   // roba->id
   cIdProizvodTekuci := roba_p->id

   PushWA()

   // SELECT sast
   // SET ORDER TO TAG "idrbr"
   // SET FILTER TO field->id == cIdProizvodTekuci
   // GO TOP

   o_sastavnice( cIdProizvodTekuci, "IDRBR" )

   // setuj kolone sastavnice tabele
   sast_a_kol( @ImeKol, @Kol )

   p_sifra( F_SAST, "IDRBR", f18_max_rows() - 18, 80, cIdProizvodTekuci + "-" + Left( roba_p->naz, 40 ),,,, {| nCh | EdSastBlok( nCh ) },,,, .F. )

   PopWa()

   SELECT sast
   SET FILTER TO

   SELECT roba_p
   // SET ORDER TO TAG "idun"

   RETURN .T.



STATIC FUNCTION sast_key_handler( nCh )

   LOCAL nTRec, nReturn

   nTRec := RecNo()

   nReturn := DE_CONT

   DO CASE

   CASE nCh == k_ctrl_f9()
      // brisanje sastavnica i proizvoda
      bris_sast()
      nReturn := 7

   CASE nCh == K_ENTER
      // prikazi sastavnicu
      show_sast()
      nReturn := DE_REFRESH

   CASE ( nCh == K_CTRL_F4 )

      sastavnica_copy() // kopiranje sastavnica u drugi proizvod
      nReturn := DE_REFRESH

   CASE nCh == K_F7

      sastavnice_lista() // lista sastavnica
      nReturn := DE_REFRESH

   CASE nCh == K_F10
      // ostale opcije
      ost_opc_sast()
      nReturn := DE_CONT

   ENDCASE

   // SET ORDER TO TAG "ID"
   GO ( nTRec )

   RETURN nReturn


FUNCTION o_roba_tip_p( cId )

   LOCAL cAlias := "ROBA_P"
   LOCAL cSqlQuery := "select * from " + f18_sql_schema( "roba")
   LOCAL cIdSql

   cSqlQuery += " WHERE tip='P'"
   SELECT F_ROBA_P
   IF !use_sql( NIL, cSqlQuery, cAlias )
      RETURN .F.
   ENDIF
   INDEX ON field->ID TAG "ID" TO ( cAlias )
   INDEX ON field->NAZ TAG "NAZ" TO ( cAlias )
   SET ORDER TO TAG "ID"
   GO TOP

   IF cId != NIL
      SEEK cId
      IF !Found()
         GO TOP
      ENDIF
   ENDIF

   GO TOP

   RETURN !Eof()


// ---------------------------------
// setovanje kolona tabele
// ---------------------------------
STATIC FUNCTION set_a_kol( aImeKol, aKol )

   LOCAL cPom
   LOCAL cPom2, nI

   aImeKol := {}
   aKol := {}

   AAdd( aImeKol, { PadC( "ID", 10 ), {|| field->id }, "id", {|| .T. }, {|| valid_sifarnik_id_postoji( wId ) } } )
   AAdd( aImeKol, { PadC( "Naziv", 20 ), {|| PadR( field->naz, 20 ) }, "naz" } )
   AAdd( aImeKol, { PadC( "JMJ", 3 ), {|| field->jmj }, "jmj" } )
   AAdd( aImeKol, { PadC( "VPC", 10 ), {|| Transform( field->VPC, "999999.999" ) }, "vpc" } )
   AAdd( aImeKol, { PadC( "VPC2", 10 ), {|| Transform( field->VPC2, "999999.999" ) }, "vpc2" } )
   AAdd( aImeKol, { PadC( "MPC", 10 ), {|| Transform( field->MPC, "999999.999" ) }, "mpc" } )

   FOR nI := 2 TO 3
      cPom := "MPC" + AllTrim( Str( nI ) )
      cPom2 := '{|| transform(' + cPom + ',"999999.999")}'
      AAdd ( aImeKol, { PadC( cPom, 10 ), ;
         &( cPom2 ), ;
         cPom } )
   NEXT

   AAdd( aImeKol, { PadC( "NC", 10 ), {|| Transform( field->NC, "999999.999" ) }, "NC" } )

   AAdd( aImeKol, { "Tarifa", {|| field->IdTarifa }, "IdTarifa", {|| .T. }, {|| P_Tarifa( @wIdTarifa ), roba_opis_edit() } } )

   AAdd( aImeKol, { "K1", {|| field->K1 }, "K1", {|| .T. }, {|| .T. } } )
   AAdd( aImeKol, { "Tip", {|| " " + field->Tip + " " }, "Tip", {|| wTip := "P", .T. }, {|| wTip $ "P" } } )

   FOR nI := 1 TO Len( aImeKol )
      AAdd( aKol, nI )
   NEXT

   RETURN .T.



STATIC FUNCTION ost_opc_sast() // ostale opcije nad sastavnicama

   LOCAL hOpc := {}
   LOCAL hOpcExe := {}
   LOCAL _izbor := 1
   LOCAL _am_x := box_x_koord()
   LOCAL _am_y := box_y_koord()

   AAdd( hOpc, "1. zamjena sirovine u svim sastavnicama                 " )
   AAdd( hOpcExe, {|| sast_repl_all() } )

   AAdd( hOpc, "2. promjena učesća pojedine sirovine u svim sastavnicama" )
   AAdd( hOpcExe, {|| sast_promjena_ucesca_materijala() } )
   AAdd( hOpc, "------------------------------------" )
   AAdd( hOpcExe, {|| notimp() } )
   AAdd( hOpc, "L. pregled sastavnica sa pretpostavkama sirovina" )
   AAdd( hOpcExe, {|| pr_pr_sast() } )
   AAdd( hOpc, "M. lista sastavnica koje (ne)sadrze sirovinu x" )
   AAdd( hOpcExe, {|| pr_ned_sast() } )
   AAdd( hOpc, "D. šifre sa duplim sastavnicama" )
   AAdd( hOpcExe, {|| sastavnice_duple() } )
   AAdd( hOpc, "P. pregled brojnog stanja sastavnica" )
   AAdd( hOpcExe, {|| pr_br_sast() } )

   // AAdd( hOpc, "E. export sastavnice -> dbf" )
   // AAdd( hOpcExe, {|| _exp_sast_dbf() } )

   // AAdd( hOpc, "F. export roba -> dbf" )
   // AAdd( hOpcExe, {|| exp_roba_dbf() } )

   f18_menu( "o_sast", .F., _izbor, hOpc, hOpcExe )

   box_x_koord( _am_x )
   box_y_koord( _am_y )

   RETURN .T.



// ------------------------------------
// ispravka sastavnice
// ------------------------------------
STATIC FUNCTION EdSastBlok( char )

   DO CASE
   CASE char == k_ctrl_f9()
      MsgBeep( "Nedozvoljena opcija !!!" )
      RETURN 7
   ENDCASE

   RETURN DE_CONT



STATIC FUNCTION sast_a_kol( aImeKol, aKol )

   LOCAL nI

   aImeKol := {}
   aKol := {}


   AAdd( aImeKol, { "R.Br", {|| Str( field->r_br, 4 ) }, "r_br", {|| .T. }, {|| .T. } } )
   AAdd( aImeKol, { _u( "Šifra sirovine" ), {|| field->id2 }, "id2", {|| .T. }, {|| wId := cIdProizvodTekuci, p_roba( @wId2 ) } } )
   AAdd( aImeKol, { _u( "Količina" ), {|| field->kolicina }, "kolicina" } )

   FOR nI := 1 TO Len( aImeKol )
      AAdd( aKol, nI )
   NEXT

   RETURN .T.



FUNCTION o_sastavnice( cId, cTag )

   LOCAL cTabela := "sast", cAlias := "SAST"

   SELECT ( F_SAST )
   IF !use_sql_sif  ( cTabela, .T., cAlias, cId  )
      error_bar( "o_sql", "open sql " + cTabela )
      RETURN .F.
   ENDIF
   // SET ORDER TO TAG "ID"
   IF cTag == NIL
      cTag := "ID"
   ENDIF
   ordSetFocus( cTag )
   IF cId != NIL
      SEEK cId
   ENDIF

   RETURN !Eof()



FUNCTION select_o_sastavnice( cId, cTag )

   SELECT ( F_SAST )
   IF Used()
      IF RecCount() > 1 .AND. cId == NIL
         RETURN .T.
      ELSE
         USE // samo zatvoriti postojecu tabelu, pa ponovo otvoriti sa cId
      ENDIF
   ENDIF

   RETURN o_sastavnice( cId, cTag )

/*
FUNCTION exp_roba_dbf() // export robe u dbf

   LOCAL aDbf := {}

   AAdd( aDbf, { "ID", "C", 10, 0 } )
   AAdd( aDbf, { "NAZIV", "C", 200, 0 } )
   AAdd( aDbf, { "JMJ", "C", 3, 0 } )
   AAdd( aDbf, { "NC", "N", 12, 2 } )
   AAdd( aDbf, { "VPC", "N", 12, 2 } )
   AAdd( aDbf, { "MPC", "N", 12, 2 } )

  -- IF !xlsx_export_init( aDbf )
      RETURN .F.
   ENDIF

   o_r_export_legacy()
   o_roba()
   SELECT roba
   SET ORDER TO TAG "ID"
   GO TOP

   Box(, 1, 50 )
   DO WHILE !Eof()

      @ box_x_koord() + 1, box_y_koord() + 2 SAY "upisujem: " + roba->id

      SELECT r_export
      APPEND BLANK

      REPLACE field->id WITH roba->id
      REPLACE field->naziv WITH roba->naz
      REPLACE field->jmj WITH roba->jmj
      REPLACE field->nc WITH roba->nc
      REPLACE field->vpc WITH roba->vpc
      REPLACE field->mpc WITH roba->mpc

      SELECT roba
      SKIP
   ENDDO

   BoxC()

   MsgBeep( "Podaci se nalaze u " + my_home() + "r_export.dbf tabeli !" )

   SELECT r_export
   USE

   RETURN .T.
*/
