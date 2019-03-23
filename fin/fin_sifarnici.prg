/*
 * This file is part of the bring.out FMK, a free and open source
 * accounting software suite,
 * Copyright (c) 1994-2018 by bring.out d.o.o Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including knowhow ERP specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_knowhow.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */


#include "f18.ch"



/* P_PKonto(cId,dx,dy)
 *     Otvara sifrarnik prenosa konta u novu godinu
 *   param: cId
 *   param: dx
 *   param: dy
 */

FUNCTION P_PKonto( CId, dx, dy )

   PRIVATE ImeKol, Kol

   ImeKol := { { "ID  ",  {|| id },   "id", {|| .T. }, {|| validacija_postoji_sifra( wid ) }    }, ;
      { PadC( "Tip prenosa", 25 ), {|| PadC( TipPkonto( tip ), 25 ) },     "tip", {|| .T. }, {|| wtip $ "123456" }     };
      }
   Kol := { 1, 2 }

   RETURN p_sifra( F_PKONTO, 1, 10, 60, "MatPod: Način prenosa konta u novu godinu", @cId, dx, dy )



/* TipPKonto(cTip)
 *     Tip prenosa konta u novu godinu
 *   param: cTip
 */

FUNCTION TipPKonto( cTip )

   IF cTip = "2"
      RETURN "po saldu partnera"
   ELSEIF cTip = "1"
      RETURN "po otvorenim stavkama"
   ELSEIF cTip = "3"
      RETURN "otv.st. bez sabiranja"
   ELSEIF cTip = "4"
      RETURN "po rj,funk,fond"
   ELSEIF cTip = "5"
      RETURN "po rj,fond"
   ELSEIF cTip = "6"
      RETURN "po rj"
   ELSE
      RETURN "??????????????"
   ENDIF

FUNCTION P_Funk( cId, dx, dy )

   PRIVATE imekol, kol

   o_funk()
   ImeKol := { { PadR( "Id", 5 ), {|| id }, "id", {|| .T. }, {|| validacija_postoji_sifra( wid ) } }, ;
      { PadR( "Naziv", 50 ), {||  naz }, "naz" } ;
      }
   Kol := { 1, 2 }

   RETURN p_sifra( F_FUNK, 1, 10, 70, "Lista funkcionalne klasifikacije", @cId, dx, dy )



FUNCTION o_funk( cId )

   SELECT ( F_FUNK )
   use_sql_funk( cId )
   SET ORDER TO TAG "ID"

   RETURN !Eof()


FUNCTION select_o_funk( cId )

   SELECT ( F_FUNK )
   IF Used()
      IF RecCount() > 1 .AND. cId == NIL
         RETURN .T.
      ELSE
         USE // samo zatvoriti postojecu tabelu, pa ponovo otvoriti sa cId
      ENDIF
   ENDIF

   RETURN o_funk( cId )



FUNCTION use_sql_funk( cId )

   LOCAL cSql
   LOCAL cTable := "fin_funk"

   SELECT ( F_FUNK )
   IF !use_sql_sif( cTable, .T., "FUNK", cId )
      RETURN .F.
   ENDIF

   IF cId != NIL
      SEEK cId
   ENDIF

   RETURN !Eof()




// -------------------------------------------
// kamatne stope
// -------------------------------------------
FUNCTION P_KS( cId, dx, dy )

   LOCAL nI
   PRIVATE imekol := {}
   PRIVATE kol := {}

   O_KS

   AAdd( imekol, { PadR( "ID", 3 ), {|| id }, "id", {|| .T. }, {|| validacija_postoji_sifra( wid ) } } )
   AAdd( imekol, { PadR( "Tip", 3 ), {|| PadC( tip, 3 ) }, "tip" } )
   AAdd( imekol, { PadR( "DatOd", 8 ), {|| datod }, "datod" } )
   AAdd( imekol, { PadR( "DatDo", 8 ), {|| datdo }, "datdo" } )
   AAdd( imekol, { PadR( "Rev", 6 ), {|| strev }, "strev" } )
   AAdd( imekol, { PadR( "Kam", 6 ), {|| stkam }, "stkam" } )
   AAdd( imekol, { PadR( "DENOM", 15 ), {|| den }, "den" } )
   AAdd( imekol, { PadR( "Duz.", 4 ), {|| duz }, "duz" } )

   FOR nI := 1 TO Len( imekol )
      AAdd( kol, nI )
   NEXT

   RETURN p_sifra( F_KS, 1, f18_max_rows() - 10, f18_max_cols() - 5, "Lista kamatni stopa", @cId, dx, dy )




FUNCTION P_Fond( cId, dx, dy )

   PRIVATE imekol, kol

   o_fond()
   ImeKol := { { PadR( "Id", 3 ), {|| id }, "id", {|| .T. }, {|| validacija_postoji_sifra( wid ) } }, ;
      { PadR( "Naziv", 50 ), {||  naz }, "naz" } ;
      }
   Kol := { 1, 2 }

   RETURN p_sifra( F_FOND, 1, 10, 70, "Lista: Fondovi", @cId, dx, dy )



FUNCTION o_fond( cId )

   SELECT ( F_FOND )
   use_sql_fond( cId )
   SET ORDER TO TAG "ID"

   RETURN !Eof()


FUNCTION select_o_fond( cId )

   SELECT ( F_FOND )
   IF Used()
      IF RecCount() > 1 .AND. cId == NIL
         RETURN .T.
      ELSE
         USE // samo zatvoriti postojecu tabelu, pa ponovo otvoriti sa cId
      ENDIF
   ENDIF

   RETURN o_fond( cId )



FUNCTION use_sql_fond( cId )

   LOCAL cSql
   LOCAL cTable := "fin_fond"

   SELECT ( F_FOND )
   IF !use_sql_sif( cTable, .T., "FOND", cId )
      RETURN .F.
   ENDIF

   IF cId != NIL
      SEEK cId
   ENDIF

   RETURN !Eof()



/* P_BuIz(cId,dx,dy)
 *     Otvara sifrarnik konta-izuzetci
 *   param: cId
 *   param: dx
 *   param: dy


FUNCTION P_BuIz( cId, dx, dy )

   PRIVATE imekol, kol

   ImeKol := { { PadR( "Konto", 10 ), {|| id }, "id", {|| .T. }, {|| validacija_postoji_sifra( wid ) } }, ;
      { PadR( "pretvori u", 10 ), {||  naz }, "naz" } ;
      }
   Kol := { 1, 2 }

   RETURN p_sifra( F_BUIZ, 1, 10, 70, "Lista: konta-izuzeci u sortiranju", @cId, dx, dy )

 */



/* P_Budzet(cId,dx,dy)
 *     Otvara sifrarnik plana budzeta
 *   param: cId
 *   param: dx
 *   param: dy


FUNCTION P_Budzet( cId, dx, dy )

   PRIVATE imekol, kol

   ImeKol := { { "Glava",   {|| idrj }, "idrj",, {|| Empty( wIdRj ) .OR. P_RJ ( @wIdRj ) } }, ;
      { "Konto",   {|| Idkonto }, "Idkonto",, {|| gPregledSifriIzMenija := .F., p_konto ( @wIdkonto ), gPregledSifriIzMenija := .T., .T. } }, ;
      { "Iznos",   {|| Iznos }, "iznos" }, ;
      { "Rebalans", {|| rebiznos }, "rebiznos" }, ;
      { "Fond",   {|| Fond }, "fond", {|| gPregledSifriIzMenija := .F., wfond $ "N1 #N2 #N3 " .OR. Empty( wFond ) .OR. P_FOND( @wFond ), gPregledSifriIzMenija := .T., .T. }  }, ;
      { "Funk",   {|| Funk }, "funk", {|| gPregledSifriIzMenija := .F., Empty( wFunk ) .OR. P_funk( @wFunk ), gPregledSifriIzMenija := .T., .T. } };
      }
   Kol := { 1, 2, 3, 4, 5, 6 }

   RETURN p_sifra( F_BUDZET, 1, 10, 55, "Plan budzeta za tekucu godinu", @cId, dx, dy )
 */



/* P_ParEK(cId,dx,dy)
 *     Otvara sifrarnik ekonomskih kategorija
 *   param: cId
 *   param: dx
 *   param: dy

FUNCTION P_ParEK( cId, dx, dy )

   PRIVATE imekol, kol

   ImeKol := { { "Partija", {|| IdPartija }, "idpartija",, {|| validacija_postoji_sifra ( wIdPartija ) } }, ;
      { "Konto", {|| IdKonto }, "Idkonto",, {|| gPregledSifriIzMenija := .F., p_konto ( @wIdKonto ), gPregledSifriIzMenija := .T., .T. } };
      }
   Kol := { 1, 2 }

   RETURN p_sifra( F_PAREK, 1, 10, 55, "Partije->Konta", @cId, dx, dy )

*/



/*
 *     Otvara sifrarnik shema kontiranja obracuna LD
 *   param: cId
 *   param: dx
 *   param: dy


FUNCTION P_TRFP3( cId, dx, dy )

   PRIVATE imekol, kol

   ImeKol := {  { PadC( "Shema", 5 ),    {|| PadC( shema, 5 ) },      "shema"     }, ;
      { PadC( "Formula/ID", 10 ),    {|| id },      "id"            }, ;
      { PadC( "Naziv", 20 ), {|| naz },     "naz"                   }, ;
      { "Konto  ", {|| idkonto },        "Idkonto", {|| .T. }, {|| ( "?" $ widkonto ) .OR. ( "A" $ widkonto ) .OR. ( "B" $ widkonto ) .OR. ( "IDKONT" $ widkonto ) .OR.  p_konto( @wIdkonto ) }   }, ;
      { "D/P",   {|| PadC( D_P, 3 ) },      "D_P"                   }, ;
      { "Znak",    {|| PadC( Znak, 4 ) },        "ZNAK"                  }, ;
      { "IDVN",    {|| PadC( idvn, 4 ) },        "idvn"                  };
      }
   Kol := { 1, 2, 3, 4, 5, 6, 7 }

   PRIVATE cShema := " "

   IF Pitanje(, "Želite li postaviti filter za odredjenu shemu", "N" ) == "D"
      Box(, 1, 60 )
      @ box_x_koord() + 1, box_y_koord() + 2 SAY "Odabir sheme:" GET cShema  PICT "@!"
      READ
      Boxc()
      SELECT trfp3
      cFiltTRFP3 := "shema=" + dbf_quote( cShema )
      SET FILTER TO &cFiltTRFP3
      GO TOP
   ELSE
      SELECT trfp3
      SET FILTER TO
   ENDIF

   RETURN p_sifra( F_TRFP3, 1, 15, 76, "Sheme kontiranja obracuna LD", @cId, dx, dy )

 */



FUNCTION is_konto_ima_u_prometu( cKonto )

   LOCAL cSql := "select count(*) as cnt from " + f18_sql_schema( "fin_anal" ) + " where idkonto=" + sql_quote( cKonto )
   LOCAL lRet

   PushWa()

   SELECT 0
   use_sql( "DATASET", cSql )
   lRet := ( dataset->cnt > 0 )
   USE

   PopWA()

   RETURN  lRet




/* P_ULimit(cId,dx,dy)
 *     Otvara sifrarnik limita po ugovorima
 *   param: cId
 *   param: dx
 *   param: dy


FUNCTION P_ULIMIT( cId, dx, dy )

   PRIVATE ImeKol, Kol := {}

   ImeKol := { { "ID ", {|| id       }, "id", {|| .T. }, {|| validacija_postoji_sifra( wId ) },, "999" }, ;
      { "ID partnera", {|| idpartner }, "idpartner", {|| .T. }, {|| p_partner( @wIdPartner ) } }, ;
      { "Limit", {|| f_limit    }, "f_limit"      };
      }
   FOR i := 1 TO Len( ImeKol ); AAdd( Kol, i ); NEXT

  -- RETURN p_sifra( F_ULIMIT, 1, 10, 55, "Sifrarnik limita po ugovorima", @cid, dx, dy )
 */
