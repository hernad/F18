#include "f18.ch"

MEMVAR ImeKol, Kol

// k1 - karakteristike

/*
FUNCTION P_K1( cId, dx, dy )

   LOCAL _area, nI
   PRIVATE ImeKol := {}
   PRIVATE Kol := {}

   _area := Select()

   o_k1()

   AAdd( ImeKol, { "ID", {|| id }, "id" } )
   //add_mcode( @ImeKol )
   AAdd( ImeKol, { "Naziv", {|| naz }, "naz" } )

   FOR nI := 1 TO Len( ImeKol )
      AAdd( Kol, nI )
   NEXT

   SELECT ( _area )

   RETURN p_sifra( F_K1, I_ID, 10, 60, "Lista - K1", @cId, dx, dy )
*/

/* fn P_VrsteP(cId,dx,dy)
 */

FUNCTION P_VrsteP( cId, dx, dy )

   LOCAL i
   PRIVATE ImeKol, Kol := {}

   // koristi ga POS 
   // takodje postoje tragovi koristenja u FAKT, ali vidim da je u knjig vrstep reccount=0 

   o_vrstep()
   IF reccount() == 0
      select(F_VRSTEP)
      use
      IF programski_modul() == "POS"
          pos_fill_vrste_placanja()
      ENDIF
      o_vrstep()
   ENDIF

   ImeKol := { { "ID ",             {|| id },  "id", {|| .T. }, {|| valid_sifarnik_id_postoji( wId ) }      }, ;
      { PadC( "Naziv", 20 ), {|| PadR( ToStrU( naz ), 20 ) },  "naz" };
      }

   FOR i := 1 TO Len( ImeKol )
      AAdd( Kol, i )
   NEXT

   RETURN p_sifra( F_VRSTEP, 1, 10, 55, "Šifarnik vrsta plaćanja", @cid, dx, dy )


FUNCTION pos_fill_vrste_placanja()

   LOCAL cShema := pos_prodavnica_sql_schema()
   LOCAL cQuery, oQry
   
   
   cQuery := "INSERT INTO " + cShema + ".vrstep (id,naz) VALUES"
   cQuery += "    ('01','GOTOVINA            ')"
   cQuery += "     ,('KT','KARTICA             ')"
   cQuery += "     ,('VR','VIRMAN              ')"
   cQuery += "     ,('CK','CEK                 ')"
   cQuery += "; select count(*) from " + cShema + ".vrstep"

   oQry := run_sql_query( cQuery )

   IF sql_error_in_query( oQry, "SELECT" )
      RETURN .F.
   ENDIF
   RETURN .T.
