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

MEMVAR ImeKol, Kol, GetList
MEMVAR wId, wNaz, wIdRj, wVr_invalid, wSt_invalid
MEMVAR cFooter, lPInfo

STATIC __filter_radn := .F.

FUNCTION P_Radn( cId, nDeltaX, nDeltaY )

   LOCAL nI, lRet
   LOCAL cPom, nPom, cPom2
   LOCAL aKol

   PRIVATE ImeKol
   PRIVATE kol
   PRIVATE cFooter := ""
   PRIVATE lPInfo := .F.

   IF PCount() = 0
      lPInfo := .T.
   ENDIF

   PushWA()

   select_o_radn()
   aktivni_radnici_filter( .T. ) // filterisanje tabele radnika

   ImeKol := {}
   AAdd( ImeKol, { PadR( "Id", 6 ), {|| field->id }, "id", {|| .T. }, {|| validacija_postoji_sifra( wId, "1" ) } } )
   AAdd( ImeKol, { PadR( "Prezime", 20 ), {|| field->naz }, "naz" } )
   AAdd( ImeKol, { PadR( "Ime roditelja", 15 ), {|| field->imerod }, "imerod" } )
   AAdd( ImeKol, { PadR( "Ime", 15 ), {|| field->ime }, "ime" } )
   AAdd( ImeKol, { PadR( iif( gBodK == "1",  "Br.bodova",  "Koeficij." ), 10 ), {|| field->brbod }, "brbod" } )
   AAdd( ImeKol, { PadR( "MinR%", 5 ), {|| field->kminrad }, "kminrad" } )


   AAdd( ImeKol, { PadR( "Koef.l.odb.", 15 ), {|| field->klo }, "klo" } )
   AAdd( ImeKol, { PadR( "Tip rada", 15 ), {|| field->tiprada }, "tiprada", ;
      {|| .T. }, {|| wtiprada $ " #I#A#S#N#P#U#R" .OR. MsgTipRada() } } )

   IF RADN->( FieldPos( "SP_KOEF" ) ) <> 0
      AAdd( ImeKol, { PadR( "prop.koef", 15 ), {|| field->sp_koef }, "sp_koef" } )
   ENDIF

   IF RADN->( FieldPos( "OPOR" ) ) <> 0
      AAdd( ImeKol, { PadR( "oporeziv", 15 ), {|| field->opor }, "opor" } )
   ENDIF

   IF RADN->( FieldPos( "TROSK" ) ) <> 0
      AAdd( ImeKol, { _l( PadR( "koristi trosk.", 15 ) ), {|| field->trosk }, "trosk" } )
   ENDIF


   AAdd( ImeKol, { _l( PadR( "StrSpr", 6 ) ), {|| PadC( field->Idstrspr, 6 ) }, "idstrspr", ;
      {|| .T. }, {|| P_StrSpr( @wIdStrSpr ) } } )
   AAdd( ImeKol, { _l( PadR( "V.Posla", 6 ) ), {|| PadC( field->IdVPosla, 6 ) }, "IdVPosla", ;
      {|| .T. }, {|| Empty( wIdvposla ) .OR. P_VPosla( @wIdVPosla ) } } )
   AAdd( ImeKol, { _l( PadR( "Ops.Stan", 8 ) ), {|| PadC( field->IdOpsSt, 8 ) }, "IdOpsSt", ;
      {|| .T. }, {|| P_Ops( @wIdOpsSt ) } } )
   AAdd( ImeKol, { _l( PadR( "Ops.Rada", 8 ) ), {|| PadC( field->IdOpsRad, 8 ) }, "IdOpsRad", ;
      {|| .T. }, {|| P_Ops( @wIdOpsRad ) } } )
   AAdd( ImeKol, { _l( PadR( "Maticni Br.", 13 ) ), {|| PadC( field->matbr, 13 ) }, "MatBr", ;
      {|| .T. }, {|| .T. } } )
   AAdd( ImeKol, { _l( PadR( "Dat.Od", 8 ) ), {|| field->datod }, "datod", {|| .T. }, {|| .T. } } )
   AAdd( ImeKol, { _l( PadR( "POL", 3 ) ), {|| PadC( field->pol, 3 ) }, "POL", {|| .T. }, {|| wPol $ "MZ" } } )
   AAdd( ImeKol, { PadR( "K1", 2 ), {|| PadC( field->k1, 2 ) }, "K1", {|| .T. }, {|| .T. } } )
   AAdd( ImeKol, { PadR( "K2", 2 ), {|| PadC( field->k2, 2 ) }, "K2", {|| .T. }, {|| .T. } } )
   AAdd( ImeKol, { PadR( "K3", 2 ), {|| PadC( field->k3, 2 ) }, "K3", {|| .T. }, {|| .T. } } )
   AAdd( ImeKol, { PadR( "K4", 2 ), {|| PadC( field->k4, 2 ) }, "K4", {|| .T. }, {|| .T. } } )
   AAdd( ImeKol, { _l( PadR( "PorOl", 6 ) ), {|| field->porol }, "POROL", {|| .T. }, {|| .T. } } )

   AAdd( ImeKol, { _l( PadR( "Radno mjesto", 30 ) ), {|| field->rmjesto }, "RMJESTO", {|| .T. }, {|| .T. } } )

   AAdd( ImeKol, { _l( PadR( "Br.Knjizice ", 12 ) ), {|| PadC( field->brknjiz, 12 ) }, "brknjiz", {|| .T. }, {|| .T. } } )

   AAdd( ImeKol, { _l( PadR( "Br.Tekuceg rac.", 20 ) ), {|| PadC( field->brtekr, 20 ) }, "brtekr", {|| .T. }, {|| .T. } } )

   AAdd( ImeKol, { _l( PadR( "Isplata", 7 ) ), {|| PadC( field->isplata, 7 ) }, "isplata", {|| .T. }, {|| wIsplata $ "  #TR#SK#BL" .OR. MsgIspl() } } )
   AAdd( ImeKol, { _l( PadR( "Banka", 6 ) ), {|| PadC( field->idbanka, 6 ) }, "idbanka", {|| .T. }, {|| Empty( WIDBANKA ) .OR. P_Kred( @wIdbanka ) } } )

   AAdd( ImeKol, { _l( PadR( "OSN.Bol", 11 ) ), {|| field->osnbol }, "osnbol" } )

   IF radn->( FieldPos( "N1" ) <> 0 )
      AAdd( ImeKol, { PadC( "N1", 12 ), {|| field->n1 }, "n1" } )
      AAdd( ImeKol, { PadC( "N2", 12 ), {|| field->n2 }, "n2" } )
      AAdd( ImeKol, { PadC( "N3", 12 ), {|| field->n3 }, "n3" } )
   ENDIF

   IF radn->( FieldPos( "IDRJ" ) <> 0 )
      AAdd( ImeKol, { "ID RJ", {|| field->idrj }, "idrj", ;
         {|| .T. }, {|| Empty( wIdRj ) .OR. P_LD_Rj( @wIdRj ) } } )
   ENDIF

   // Dodaj specificna polja za popunu obrasca DP
   IF radn->( FieldPos( "STREETNAME" ) <> 0 )
      AAdd( ImeKol, { PadC( "Ime ul.", 40 ), {|| field->streetname }, "streetname" } )
      AAdd( ImeKol, { PadC( "Broj ul.", 10 ), {|| field->streetnum }, "streetnum" } )
      AAdd( ImeKol, { PadC( "Zaposl.od", 12 ), {|| field->hiredfrom }, "hiredfrom", ;
         {|| .T. }, {|| P_HiredFrom( @wHiredfrom ) } } )
      AAdd( ImeKol, { PadC( "Zaposl.do", 12 ), {|| field->hiredto }, "hiredto" } )
   ENDIF

   IF radn->( FieldPos( "AKTIVAN" ) ) <> 0
      AAdd( ImeKol, { "Aktivan?", {|| field->aktivan }, "aktivan" } )
   ENDIF

   IF radn->( FieldPos( "BEN_SRMJ" ) ) <> 0
      AAdd( ImeKol, { "Benef.sifra", {|| field->ben_srmj }, "ben_srmj" } )
   ENDIF

   Kol := {}

   IF gMinR == "B"
      ImeKol[ 6 ] := { PadR( "MinR", 7 ), {|| Transform( field->kminrad, "9999.99" ) }, "kminrad" }
   ENDIF

   FOR nI := 1 TO 9
      cPom := "S" + AllTrim( Str( nI ) )
      nPom := Len( ImeKol )
      IF radn->( FieldPos( cPom ) <> 0 )
         // cPom2 := my_get_from_ini( "LD", "OpisRadn" + cPom, "KOEF_" + cPom, KUMPATH )
         cPom2 := "KOEF_" + cPom
         AAdd( ImeKol, { cPom + "(" + cPom2 + ")", {|| &cPom. }, cPom } )
      ENDIF
   NEXT

   aKol := { PadR( "vr.invalid", 10 ), {|| Transform( field_num_nil( field->vr_invalid ), "9" ) }, "vr_invalid", ;
      {|| .T. }, {|| Wvr_invalid == 0 .OR. valid_vrsta_invaliditeta( Wvr_invalid ) }, NIL,  "9" }

   AAdd( ImeKol,  aKol )
   aKol := { PadR( "st.invalid", 10 ), {|| Transform( field_num_nil( field->st_invalid ), "999" ) }, "st_invalid", ;
      {|| .T. }, {|| Wst_invalid >= 0 }, NIL, "999"  }
   AAdd( ImeKol,  aKol )

   FOR nI := 1 TO Len( ImeKol )
      AAdd( Kol, nI )
   NEXT

   lRet := p_sifra( F_RADN, 1, f18_max_rows() - 15, f18_max_cols() - 15, "Lista radnika" + Space( 5 ) + "<S> filter radnika on/off", @cId, nDeltaX, nDeltaY, ;
      {| Ch | browse_edit_radnik( Ch ) },,,,, { "ID" } )

   PopWa( F_RADN )

   RETURN lRet


// ------------------------------------------
// filterisanje tabele radnika
// ------------------------------------------
STATIC FUNCTION aktivni_radnici_filter( lFiltered )

   LOCAL cFilter := ""

   IF radn->( FieldPos( "aktivan" ) ) == 0
      RETURN .F.
   ENDIF

   IF lFiltered == nil
      lFiltered := .T.
   ENDIF

   cFilter := "aktivan $ ' #D'"

   // pozicioniraj se na radnika
   SELECT RADN

   IF lFiltered == .T. .AND. gRadnFilter == "D"
      SET FILTER TO &cFilter
      GO TOP
   ELSE
      SET FILTER TO
      GO TOP
   ENDIF

   RETURN .T.



/*
 *
 *   param: dHiredFrom
 */
FUNCTION P_HiredFrom( dHiredFrom )

   IF Empty( DToS( dHiredFrom ) ) .AND. !Empty( DToS( field->datod ) ) .AND. Pitanje(, _l( "Popuni polje na osnovu polja Datum Od" ), "D" ) == "D"
      dHiredFrom := field->datod
   ENDIF

   RETURN .T.


/* P_StreetNum(cStreetNum)
 *
 *   param: cStreetNum - vrijednost polja streetnum
 */
FUNCTION P_StreetNum( cStreetNum )

   IF Empty( field->streetnum )
      cStreetNum := Space( 5 ) + "0"
   ENDIF

   RETURN .T.


/*
// ispisuje info o poreskoj kartici
// ---------------------------------------------
STATIC FUNCTION p_pkartica( cIdRadn )

   LOCAL nTA := Select()

   O_PK_RADN
   SELECT pk_radn
   SEEK cIdRadn

   IF Found() .AND. field->idradn == cIdRadn
      @ PRow() + 8, PCol() + 8 SAY "               " COLOR "W+/W"
   ELSE
      @ PRow() + 8, PCol() + 8 SAY "pk: nepopunjena" COLOR "W+/R+"
   ENDIF

   SELECT ( nTA )

   RETURN .T.
*/


// --------------------------------------------
// radn. blok funkcije
// --------------------------------------------
FUNCTION browse_edit_radnik( Ch )

   LOCAL nMjesec := ld_tekuci_mjesec()
   LOCAL _rec
   LOCAL hParams

/*
   IF lPInfo == .T.
      // ispisi info o poreskoj kartici
      p_pkartica( field->id )
   ENDIF
*/

   __filter_radn := .F.

   IF ( Ch == K_ALT_M )

      Box(, 4, 60 )
      @ box_x_koord() + 1, box_y_koord() + 2 SAY "Postavljenje koef. minulog rada:"
      @ box_x_koord() + 2, box_y_koord() + 2 SAY "Pazite da ovu opciju ne izvrsite vise puta za isti mjesec !"
      @ box_x_koord() + 4, box_y_koord() + 2 SAY "Mjesec:" GET nMjesec PICT "99"
      READ
      BoxC()

      IF ( LastKey() == K_ESC )
         RETURN DE_CONT
      ENDIF

      MsgO( "Prolazim kroz tabelu radnika.." )

      SELECT radn
      GO TOP

      run_sql_query( "BEGIN" )
      IF !f18_lock_tables( { "ld_radn" }, .T. )
         run_sql_query( "ROLLBACK" )
         RETURN .F.
      ENDIF


      DO WHILE !Eof()

         _rec := dbf_get_rec()

         IF Month( _rec[ "datod" ] ) == nMjesec

            IF _rec[ "pol" ] == "M"
               _rec[ "kminrad" ] := _rec[ "kminrad" ] + gMRM
            ELSEIF pol == "Z"
               _rec[ "kminrad" ] := _rec[ "kminrad" ] + gMRZ
            ENDIF

         ENDIF

         IF _rec[ "kminrad" ] > 20 // ogranicenje minulog rada
            _rec[ "kminrad" ] := 20
         ENDIF

         update_rec_server_and_dbf( "ld_radn", _rec, 1, "CONT" )

         SKIP
      ENDDO


      hParams := hb_Hash()
      hParams[ "unlock" ] := { "ld_radn" }
      run_sql_query( "COMMIT", hParams )

      MsgC()

      GO TOP
      RETURN DE_REFRESH

   ELSEIF ( Ch == K_CTRL_T )

      IF postoje_krediti_za_radnika( radn->id )
         Beep( 1 )
         Msg(  "Stavka radnika se ne moze brisati jer se vec nalazi u obracunu!"  )
         RETURN 7
      ENDIF

   ELSEIF ( Ch == K_F2 )


      IF postoje_krediti_za_radnika( radn->id )
         RETURN 99
      ENDIF

/*
   ELSEIF ( Upper( Chr( Ch ) ) == "P" )

      // poreska kartica, vraca faktor odbitka
      nFakt := p_kartica( field->id )

      SELECT radn

      IF nFakt >= 0 .AND. nFakt <> radn->klo
         IF Pitanje(, "Postaviti novi faktor licnog odbitka ?", "D" ) == "D"
            _rec := dbf_get_rec()
            _rec[ "klo" ] := nFakt
            update_rec_server_and_dbf( "ld_radn", _rec, 1, "FULL" )
         ENDIF
      ENDIF

      RETURN DE_CONT
*/

/*
   ELSEIF ( Upper( Chr( Ch ) ) == "D" )

      pk_delete( field->id )

      SELECT radn
      RETURN DE_CONT

   ELSEIF Ch == K_CTRL_G

      // setovanje datuma u poreskim karticama
      IF pitanje(, "setovati datum poreskih kartica ?", "N" ) == "D"

         pk_set_date()
         SELECT radn
         RETURN DE_CONT

      ENDIF
*/
   ELSEIF ( Upper( Chr( Ch ) ) == "Q" )

      _filter_radn()   // filter po ime, prezime
      __filter_radn := .T.
      RETURN DE_REFRESH

   ELSEIF ( Upper( Chr( Ch ) ) == "S" )

      // filter po radnicima
      cTmp := dbFilter()

      IF Empty( cTmp )
         MsgBeep( "prikazuju se samo aktivni radnici ..." )
         aktivni_radnici_filter( .T. )
         RETURN DE_REFRESH
      ELSE
         MsgBeep( "vracam filter na sve radnike ...." )
         aktivni_radnici_filter( .F. )
         RETURN DE_REFRESH
      ENDIF

   ENDIF

   RETURN DE_CONT



FUNCTION postoje_krediti_za_radnika( cIdRadn )

   PushWa()
   seek_radkr_2( radn->id )
   IF !Eof()
      PopWa()
      RETURN .T.
   ENDIF

   PopWa()

   RETURN .F.

// ---------------------------------------------------------------
// filter tabele radnika po pojedinim poljima
// ---------------------------------------------------------------
STATIC FUNCTION _filter_radn()

   LOCAL _ok := .F.
   LOCAL _filter := ""
   LOCAL _ime, _prezime, _imerod
   LOCAL nX := 1
   LOCAL _sort := 2
   PRIVATE GetList := {}

   _ime := Space( 200 )
   _prezime := _ime
   _imerod := _ime

   Box(, 6, 70 )

   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "*** FILTER ŠIFARNIKA RADNIKA"

   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "     IME:" GET _ime PICT "@S40"

   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY " PREZIME:" GET _prezime PICT "@S40"

   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "RODITELJ:" GET _imerod PICT "@S40"

   nX += 2
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Sortiranje: 1 - sifra, 2 - prezime:" GET _sort PICT "9" VALID _sort >= 1 .AND. _sort <= 2

   READ

   BoxC()

   IF LastKey() == K_ESC
      RETURN _ok
   ENDIF

   IF !Empty( _prezime )
      IF !Empty( _filter )
         _filter += " .AND. "
      ENDIF
      IF Right( AllTrim( _prezime ), 1 ) <> ";"
         _prezime := AllTrim( _prezime ) + ";"
      ENDIF
      _filter += parsiraj( Upper( _prezime ), "UPPER(naz)" )
   ENDIF

   IF !Empty( _ime )
      IF !Empty( _filter )
         _filter += " .AND. "
      ENDIF
      IF Right( AllTrim( _ime ), 1 ) <> ";"
         _ime := AllTrim( _ime ) + ";"
      ENDIF
      _filter += parsiraj( Upper( _ime ), "UPPER(ime)" )
   ENDIF

   IF !Empty( _imerod )
      IF !Empty( _filter )
         _filter += " .AND. "
      ENDIF
      IF Right( AllTrim( _imerod ), 1 ) <> ";"
         _imerod := AllTrim( _imerod ) + ";"
      ENDIF
      _filter += parsiraj( Upper( _imerod ), "UPPER(imerod)" )
   ENDIF

   IF Empty( _filter )

      SET FILTER TO   // ukidam filter, setujem pravi sort
      SET ORDER TO TAG "1"
      GO TOP

      RETURN _ok

   ENDIF

   SET FILTER TO &( _filter )

   IF _sort == 2
      SET ORDER TO TAG "2"
   ELSE
      SET ORDER TO TAG "1"
   ENDIF

   GO TOP
   _ok := .T.

   RETURN _ok




FUNCTION MsgIspl()

   Box(, 3, 50 )
   @ box_x_koord() + 1, box_y_koord() + 2 SAY8 "Vazeće šifre su: TR - tekući racun   "
   @ box_x_koord() + 2, box_y_koord() + 2 SAY8 "                 SK - štedna knjizica"
   @ box_x_koord() + 3, box_y_koord() + 2 SAY8 "                 BL - blagajna"
   Inkey( 0 )
   BoxC()

   RETURN .F.




FUNCTION P_ParObr( cId, nDeltaX, nDeltaY )

   LOCAL _tmp_id
   LOCAL nI
   PRIVATE imekol := {}
   PRIVATE kol := {}

   AAdd( ImeKol, { PadR( "mjesec", 8 ),  {|| field->id }, "id", {|| iif( ValType( wId ) == "C", Eval( MemVarBlock( "wId" ), Val( wId ) ), NIL ), .T. },;
         NIL, NIL, "99" } )
   AAdd( ImeKol, { "godina", {|| field->godina }, "godina", {|| iif( ValType( wId ) == "N", Eval( MemVarBlock( "wID" ), Str( wId, 2 ) ), NIL ), .T. },;
         NIL, NIL, "9999" } )
   AAdd( ImeKol, { PadR( "obracun", 10 ), {|| field->obr }, "obr" } )

   //IF my_get_from_ini( "LD", "VrBodaPoRJ", "N", KUMPATH ) == "D"
    //  AAdd( ImeKol, { "rj", {|| field->IDRJ }, "IDRJ" } )
   //ENDIF

   AAdd( ImeKol, { PadR( "opis", 10 ), {|| field->naz }, "naz" } )
   AAdd( ImeKol, { PadR( iif( gBodK == "1", "vrijednost boda", "vr.koeficijenta" ), 15 ),  {|| field->vrbod }, "vrbod" } )
   AAdd( ImeKol, { PadR( "n.koef.1", 8 ), {|| field->k5 }, "k5"  } )
   AAdd( ImeKol, { PadR( "n.koef.2", 8 ), {|| field->k6 }, "k6"  } )
   AAdd( ImeKol, { PadR( "n.koef.3", 8 ), {|| field->k7 }, "k7"  } )
   AAdd( ImeKol, { PadR( "n.koef.4", 8 ), {|| field->k8 }, "k8"  } )
   AAdd( ImeKol, { PadR( "br.sati", 5 ),  {|| field->k1 }, "k1"  } )
   AAdd( ImeKol, { PadR( "prosj.LD", 12 ),{|| field->Prosld }, "PROSLD"  }  )
   AAdd( ImeKol, { PadR( "mn sat.", 12 ), {|| field->m_net_sat }, "m_net_sat"  } )
   AAdd( ImeKol, { PadR( "mb sat.", 12 ), {|| field->m_br_sat }, "m_br_sat"  } )

   FOR nI := 1 TO Len( ImeKol )
      AAdd( kol, nI )
   NEXT

   RETURN p_sifra( F_PAROBR, 1, f18_max_rows() - 15, f18_max_cols() - 20, _u( "Parametri obračuna" ), @cId, nDeltaX, nDeltaY )


FUNCTION g_tp_naz( cId )

   LOCAL nTArea := Select()
   LOCAL xRet := ""

   select_o_tippr( cId )


   IF Found()
      xRet := AllTrim( tippr->naz )
   ENDIF

   SELECT ( nTArea )

   RETURN xRet




FUNCTION P_TipPr( cId, nDeltaX, nDeltaY )

   LOCAL nI, lRet
   PRIVATE ImeKol := {}
   PRIVATE Kol := {}

   AAdd( ImeKol, { PadR( "Id", 2 ), {|| field->id }, "id", {|| .T. }, {|| validacija_postoji_sifra( wid ) } } )
   AAdd( ImeKol, { PadR( "Naziv", 20 ), {||  field->naz }, "naz" } )
   AAdd( ImeKol, { "Aktivan", {||  PadC( field->aktivan, 7 ) }, "aktivan" } )
   AAdd( ImeKol, { "Fiksan", {||  PadC( field->fiksan, 7 ) }, "fiksan" } )
   AAdd( ImeKol, { PadR( "U fond s.", 10 ), {||  PadC( field->ufs, 10 ) }, "ufs" } )
   AAdd( ImeKol, { PadR( "U neto", 6 ), {||  PadC( field->uneto, 6 ) }, "uneto" } )

   AAdd( ImeKol, { PadR( "tp.tip", 6 ), {||  field->tpr_tip }, "tpr_tip", {|| .T. }, {|| v_tpr_tip( wtpr_tip ) } } )

   AAdd( ImeKol, { PadR( "Formula", 200 ), {|| field->formula }, "formula"  } )
   AAdd( ImeKol, { PadR( "Opis", 8 ), {|| field->opis }, "opis"  } )

   FOR nI := 1 TO Len( ImeKol )
      AAdd( Kol, nI )
   NEXT

   select_o_tippr()

   lRet := p_sifra( F_TIPPR, 1, f18_max_rows() - 15, f18_max_cols() - 25, "LD Tipovi primanja", @cId, nDeltaX, nDeltaY, {| Ch | TprBl( Ch ) },,,,, { "ID" } )

   RETURN lRet



// -----------------------------------------
// valid tpr_tip
// -----------------------------------------
FUNCTION v_tpr_tip( cTip )

   IF Empty( cTip )
      MsgBeep( "Tip moze biti:##prazno - standardno#N - neto#2 - naknade za rad#X - neoporezive stavke, krediti itd..." )
   ENDIF

   RETURN .T.


// ----------------------------------------
// valid dop_tip
// ----------------------------------------
FUNCTION v_dop_tip( cTip )

   IF Empty( cTip )
      MsgBeep( "Tip moze biti:##prazno - standardno#N - neto#2 - ostale naknade#P - neto + ostale naknade#B - bruto#R - neto na ruke" )
   ENDIF

   RETURN .T.



FUNCTION TprBl( Ch )

   RETURN DE_CONT




FUNCTION P_TipPr2( cId, nDeltaX, nDeltaY )

   PRIVATE imekol
   PRIVATE kol

   ImeKol := { { PadR( "Id", 2 ), {|| id }, "id", {|| .T. }, {|| validacija_postoji_sifra( wid ) } }, ;
      { PadR( "Naziv", 20 ), {||  naz }, "naz" }, ;
      {      "Aktivan", {||  PadC( aktivan, 7 ) }, "aktivan" }, ;
      {      "Fiksan", {||  PadC( fiksan, 7 ) }, "fiksan" }, ;
      { PadR( "U fond s.", 10 ), {||  PadC( ufs, 10 ) }, "ufs" }, ;
      { PadR( "U neto", 6 ), {||  PadC( uneto, 6 ) }, "uneto" }, ;
      { PadR( "Formula", 200 ), {|| formula }, "formula"  }, ;
      { PadR( "Opis", 8 ), {|| opis }, "opis"  } ;
      }
   Kol := { 1, 2, 3, 4, 5, 6, 7, 8 }

   o_tippr2()

   RETURN p_sifra( F_TIPPR2, 1, f18_max_rows() - 15, f18_max_cols() - 20, _l( "Tipovi primanja za obračun 2" ),  @cId, nDeltaX, nDeltaY, ;
      {| Ch | Tpr2Bl( Ch ) },,,,, { "ID" } )



FUNCTION Tpr2Bl( Ch )

   RETURN DE_CONT



FUNCTION P_LD_RJ( cId, nDeltaX, nDeltaY )

   LOCAL lRet
   PRIVATE imekol := {}
   PRIVATE kol := {}

   PushWA()
   select_o_ld_rj()

   AAdd( ImeKol, { PadR( "Id", 2 ),      {|| id }, "id", {|| .T. }, {|| validacija_postoji_sifra( wid ) } } )
   AAdd( ImeKol, { PadR( "Naziv", 35 ), {||  naz }, "naz" } )

   IF ld_rj->( FieldPos( "TIPRADA" ) ) <> 0
      AAdd( ImeKol, { "tip rada", {||  tiprada }, "tiprada", {|| .T. }, {|| wtiprada $ " #I#A#S#N#P#U#R#" .OR. MsgtipRada() }  } )
   ENDIF
   IF ld_rj->( FieldPos( "OPOR" ) ) <> 0
      AAdd( ImeKol, { "oporeziv", {||  opor }, "opor"  } )
   ENDIF

   FOR nI := 1 TO Len( ImeKol )
      AAdd( Kol, nI )
   NEXT

   lRet := p_sifra( F_LD_RJ, 1, f18_max_rows() - 15, 60, "LD radne jedinice", @cId, nDeltaX, nDeltaY )

   PopWa( F_LD_RJ )

   RETURN lRet



// vraca PU code opstine
FUNCTION get_ops_idj( cId )

   LOCAL cRet := ""

   PushWa()

   select_o_ops( cId )
   IF !Eof()
      cRet := field->idj
   ENDIF

   PopWA()

   RETURN cRet



FUNCTION P_Kred( cId, nDeltaX, nDeltaY )

   LOCAL lRet
   PRIVATE imekol, kol

   PushWa()

   select_o_kred()

   ImeKol := { { PadR( "Id", 6 ), {|| id }, "id", {|| .T. }, {|| validacija_postoji_sifra( wid ) } }, ;
      { PadR( "Naziv", 30 ), {||  naz }, "naz" }, ;
      { PadR( "Adresa", 30 ), {||  adresa }, "adresa" }, ;
      { PadR( "Mjesto", 20 ), {||  mjesto }, "mjesto" }, ;
      { PadR( "PTT", 5 ), {||  ptt }, "ptt" }, ;
      { PadR( "Filijala", 30 ), {||  fil }, "fil" }, ;
      { PadR( "Racun", 20 ), {||  ziro }, "ziro" }, ;
      { PadR( "Partija", 20 ), {||  zirod }, "zirod" }                 ;
      }

   Kol := { 1, 2, 3, 4, 5, 6, 7, 8 }

   o_kred()

   lRet := p_sifra( F_KRED, 1, f18_max_rows() - 15, f18_max_cols() - 20, _u( "Lista kreditora" ), @cId, nDeltaX, nDeltaY )

   PopWa( F_KRED )

   RETURN lRet


FUNCTION KrBlok( Ch )

   IF ( Ch == K_CTRL_T )
      seek_radkr_2( NIL, kred->id )
      IF !Eof()
         Beep( 1 )
         Msg( "Firma se ne moze brisati jer je vec korištena u obračunu!" )
         RETURN 7
      ENDIF
   ELSEIF ( Ch == K_F2 )
      seek_radkr_2( NIL, kred->id )
      IF !Eof()
         RETURN 99
      ENDIF
   ENDIF

   RETURN DE_CONT

/*

-- FUNCTION ImaURadKr( cKljuc, cTag )

   LOCAL lVrati := .F.
   LOCAL lUsed := .T.
   LOCAL nArr := Select()

   //SELECT ( F_RADKR )

   //IF !Used()
      lUsed := .F.
    //  O_RADKR
   //ELSE
    //  PushWA()
   //ENDIF

   SET ORDER TO TAG ( cTag )
  -- SEEK cKljuc

   lVrati := Found()

   IF !lUsed
      USE
   ELSE
      PopWA()
   ENDIF

   SELECT ( nArr )

   RETURN lVrati
*/

/*
FUNCTION ImaUObrac( cKljuc, cTag )

   LOCAL lVrati := .F.
   LOCAL lUsed := .T.
   LOCAL nArr := Select()

   // SELECT ( F_LD )

   // IF !Used()
   // lUsed := .F.
   //select_o_ld()
   // ELSE
   // PushWA()
   // ENDIF

   SET ORDER TO TAG ( cTag )
   SEEK cKljuc

   lVrati := Found()

   // IF !lUsed
   // USE
   // ELSE
   // PopWA()
   // ENDIF

   IF !lVrati  // ako nema u LD, provjerimo ima li u 1.dijelu obracuna (smece)
      SELECT ( F_LDSM )
      IF !Used()
         lUsed := .F.
         O_LDSM
      ELSE
         PushWA()
      ENDIF
      SET ORDER TO TAG ( cTag )
      SEEK cKljuc
      lVrati := Found()
      IF !lUsed
         USE
      ELSE
         PopWA()
      ENDIF
   ENDIF
   SELECT ( nArr )

   RETURN lVrati
*/


FUNCTION p_ld_por( cId, nDeltaX, nDeltaY )

   LOCAL nI, lRet
   LOCAL _st_stopa := fetch_metric( "ld_porezi_stepenasta_stopa", NIL, "N" )
   LOCAL nI2
   PRIVATE Imekol := {}
   PRIVATE Kol := {}

   AAdd( ImeKol, { PadR( "Id", 2 ), {|| id }, "id", {|| .T. }, {|| validacija_postoji_sifra( wid ) } } )

//   IF POR->( FieldPos( "ALGORITAM" ) ) <> 0 .AND. _st_stopa == "D"
//      AAdd( ImeKol, { "Algor.", {|| algoritam }, "algoritam" } )
//   ENDIF

   AAdd( ImeKol, { PadR( "Naziv", 20 ), {|| naz }, "naz" } )
   AAdd( ImeKol, { PadR( "Iznos", 20 ), {||  Transform( iznos, "99.99" ) }, "iznos", {|| iif( POR->( FieldPos( "ALGORITAM" ) ) <> 0, wh_oldpor( walgoritam ), .T. ) } } )
   AAdd( ImeKol, { PadR( "Donji limit", 12 ), {||  Transform( dlimit, "99999.99" ) }, "dlimit" } )
   AAdd( ImeKol, { PadR( "PoOpst", 6 ), {||  poopst }, "poopst" } )

   AAdd( ImeKol, { "p.tip", {|| por_tip }, "por_tip" } )

/*
   IF POR->( FieldPos( "ALGORITAM" ) ) <> 0 .AND. _st_stopa == "D"

      AAdd( ImeKol, { "St.1", {|| s_sto_1 }, "s_sto_1", {|| ld_when_porez( walgoritam ) } } )
      AAdd( ImeKol, { "Izn.1", {|| s_izn_1 }, "s_izn_1", {|| ld_when_porez( walgoritam ) } } )
      AAdd( ImeKol, { "St.2", {|| s_sto_2 }, "s_sto_2", {|| ld_when_porez( walgoritam ) } } )
      AAdd( ImeKol, { "Izn.2", {|| s_izn_2 }, "s_izn_2", {|| ld_when_porez( walgoritam ) } } )
      AAdd( ImeKol, { "St.3", {|| s_sto_3 }, "s_sto_3", {|| ld_when_porez( walgoritam ) } } )
      AAdd( ImeKol, { "Izn.3", {|| s_izn_3 }, "s_izn_3", {|| ld_when_porez( walgoritam ) } } )
      AAdd( ImeKol, { "St.4", {|| s_sto_4 }, "s_sto_4", {|| ld_when_porez( walgoritam ) } } )
      AAdd( ImeKol, { "Izn.4", {|| s_izn_4 }, "s_izn_4", {|| ld_when_porez( walgoritam ) } } )
      AAdd( ImeKol, { "St.5", {|| s_sto_5 }, "s_sto_5", {|| ld_when_porez( walgoritam ) } } )
      AAdd( ImeKol, { "Izn.5", {|| s_izn_5 }, "s_izn_5", {|| ld_when_porez( walgoritam ) } } )

   ENDIF
*/

   FOR nI := 1 TO Len( ImeKol )
      AAdd( Kol, nI )
   NEXT

   PushWA()

   select_o_por()
   o_sifk( "POR" )
   o_sifv()

   SELECT sifk
   SET ORDER TO TAG "ID"
   SEEK "POR" // sifk

   DO WHILE !Eof() .AND. ID = "POR"
      AAdd ( ImeKol, {  get_sifk_naz( "POR", SIFK->Oznaka ) } )
      AAdd ( ImeKol[ Len( ImeKol ) ], &( "{|| ToStr(get_sifk_sifv('POR','" + sifk->oznaka + "')) }" ) )
      AAdd ( ImeKol[ Len( ImeKol ) ], "SIFK->" + SIFK->Oznaka )

      IF ( sifk->edkolona > 0 )
         FOR nI2 := 4 TO 9
            AAdd( ImeKol[ Len( ImeKol ) ], NIL  )
         NEXT
         AAdd( ImeKol[ Len( ImeKol ) ], sifk->edkolona  )
      ELSE
         FOR nI2 := 4 TO 10
            AAdd( ImeKol[ Len( ImeKol ) ], NIL  )
         NEXT
      ENDIF

      // postavi picture za brojeve
      IF ( sifk->Tip = "N" )
         IF ( f_decimal > 0 )
            ImeKol[ Len( ImeKol ), 7 ] := Replicate( "9", sifk->duzina - sifk->f_decimal - 1 ) + "." + Replicate( "9", sifk->f_decimal )
         ELSE
            ImeKol[ Len( ImeKol ), 7 ] := Replicate( "9", sifk->duzina )
         ENDIF
      ENDIF

      AAdd( Kol, iif( sifk->UBrowsu = '1', ++nI, 0 ) )
      SKIP
   ENDDO


   lRet := p_sifra( F_POR, 1, f18_max_rows() - 15, f18_max_cols() - 20, "Lista poreza na platu", ;
      @cId, nDeltaX, nDeltaY, {| Ch | PorBl( Ch ) } )


   PopWa( F_POR )

   RETURN lRet


// -------------------------------
// when porez
// -------------------------------
FUNCTION ld_when_porez( cAlg )

   LOCAL lRet := .F.

   IF cAlg == "S"
      lRet := .T.
   ENDIF

   RETURN lRet


// -------------------------------
// when stari porez
// -------------------------------
FUNCTION wh_oldpor( cAlg )

   LOCAL lRet := .F.

   IF Empty( cAlg ) .OR. cAlg <> "S"
      lRet := .T.
   ENDIF

   RETURN lRet



FUNCTION p_ld_dopr( cId, nDeltaX, nDeltaY )

   LOCAL lRet, nI
   PRIVATE imekol := {}
   PRIVATE kol := {}

   AAdd( ImeKol, { PadR( "Id", 2 ), {|| id }, "id" } )
   AAdd( ImeKol, { PadR( "Naziv", 20 ), {||  naz }, "naz" } )
   AAdd( ImeKol, { PadR( "Iznos", 20 ), {||  iznos }, "iznos" } )
   AAdd( ImeKol, { PadR( "d.tip", 6 ), {||  dop_tip }, "dop_tip", {|| .T. }, {|| v_dop_tip( wdop_tip ) } }  )
   AAdd( ImeKol, { PadR( "tip rada", 10 ), {|| tiprada }, "tiprada", {|| .T. }, {|| wtiprada $ " #I#S#N#P#U#A#R" .OR. MsgTipRada() } }  )
   AAdd( ImeKol, { PadR( "KBenef", 5 ), {|| PadC( idkbenef, 5 ) }, "idkbenef", {|| .T. }, {|| Empty( widkbenef ) .OR. P_KBenef( @widkbenef ) } } )
   AAdd( ImeKol, { PadR( "Donji limit", 12 ), {||  dlimit }, "dlimit" } )
   AAdd( ImeKol, { PadR( "PoOpst", 6 ), {||  poopst }, "poopst" }  )

   FOR nI := 1 TO Len( ImeKol )
      AAdd( Kol, nI )
   NEXT

   PushWA()

   o_sifk( "DOPR" )
   o_sifv()

   SELECT sifk
   SET ORDER TO TAG "ID"
   SEEK "DOPR" // sifk

   DO WHILE !Eof() .AND. ID = "DOPR"
      AAdd( ImeKol, { get_sifk_naz( "DOPR", SIFK->Oznaka ) } )
      AAdd( ImeKol[ Len( ImeKol ) ], &( "{|| ToStr(get_sifk_sifv('DOPR','" + sifk->oznaka + "')) }" ) )
      AAdd( ImeKol[ Len( ImeKol ) ], "SIFK->" + SIFK->Oznaka )
      IF ( sifk->edkolona > 0 )
         FOR nI2 := 4 TO 9
            AAdd( ImeKol[ Len( ImeKol ) ], NIL  )
         NEXT
         AAdd( ImeKol[ Len( ImeKol ) ], sifk->edkolona  )
      ELSE
         FOR nI2 := 4 TO 10
            AAdd( ImeKol[ Len( ImeKol ) ], NIL  )
         NEXT
      ENDIF
      // postavi picture za brojeve
      IF ( sifk->tip = "N" )
         IF ( f_decimal > 0 )
            ImeKol[ Len( ImeKol ), 7 ] := Replicate( "9", sifk->duzina - sifk->f_decimal - 1 ) + "." + Replicate( "9", sifk->f_decimal )
         ELSE
            ImeKol[ Len( ImeKol ), 7 ] := Replicate( "9", sifk->duzina )
         ENDIF
      ENDIF
      AAdd  ( Kol, iif( sifk->UBrowsu = '1', ++nI, 0 ) )
      SKIP
   ENDDO

   select_o_dopr()

   lRet := p_sifra( F_DOPR, 1, f18_max_rows() - 15, f18_max_cols() - 20, ;
      _u( "Lista doprinosa na platu" ), @cId, nDeltaX, nDeltaY, {| Ch | DoprBl( Ch ) } )

   PopWa( F_DOPR )

   RETURN lRet



FUNCTION P_KBenef( cId, nDeltaX, nDeltaY )

   LOCAL xRet
   PRIVATE Imekol
   PRIVATE kol

   PushWa()
   select_o_kbenef()

   ImeKol := { { PadR( "Id", 3 ), {|| PadC( id, 3 ) }, "id", {|| .T. }, {|| validacija_postoji_sifra( wid ) } }, ;
      { PadR( "Naziv", 8 ), {||  naz }, "naz" }, ;
      { PadR( "Iznos", 5 ), {||  iznos }, "iznos" }                       ;
      }

   Kol := { 1, 2, 3 }

   xRet := p_sifra( F_KBENEF, 1, f18_max_rows() - 15, f18_max_cols() - 20,  "Lista koef.beneficiranog radnog staza", @cId, nDeltaX, nDeltaY )

   PopWa( F_KBENEF )

   RETURN xRet



FUNCTION P_StrSpr( cId, nDeltaX, nDeltaY )

   LOCAL xRet
   PRIVATE Imekol, Kol

   ImeKol := { { PadR( "Id", 3 ), {|| id }, "id", {|| .T. }, {|| validacija_postoji_sifra( wid ) } }, ;
      { PadR( "Naziv", 20 ), {||  naz }, "naz" }, ;
      { PadR( "naz2", 6 ), {|| naz2 }, "naz2" }                     ;
      }
   Kol := { 1, 2, 3 }

   PushWa()

   select_o_str_spr()
   xRet := p_sifra( F_STRSPR, 1, f18_max_rows() - 15, f18_max_cols() - 15,  _u( "Lista: stručne spreme" ), @cId, nDeltaX, nDeltaY )

   PopWa( F_STRSPR )

   RETURN xRet



FUNCTION P_VPosla( cId, nDeltaX, nDeltaY )

   LOCAL xRet
   PRIVATE imekol
   PRIVATE kol

   ImeKol := { { PadR( "Id", 2 ), {|| id }, "id", {|| .T. }, {|| validacija_postoji_sifra( wid ) } }, ;
      { PadR( "Naziv", 20 ), {||  naz }, "naz" }, ;
      { PadR( "KBenef", 5 ), {|| PadC( idkbenef, 5 ) }, "idkbenef", {|| .T. }, {|| P_KBenef( @widkbenef ) }  }  ;
      }
   Kol := { 1, 2, 3 }


   PushWA()

   select_o_vposla()
   xRet := p_sifra( F_VPOSLA, 1, 10, 55,  "Lista: Vrste posla", @cId, nDeltaX, nDeltaY )

   PopWA()

   RETURN xRet


FUNCTION P_NorSiht( cId, nDeltaX, nDeltaY )

   LOCAL lRet
   PRIVATE imekol
   PRIVATE kol

   select_o_norsiht()

   ImeKol := { { PadR( "Id", 4 ), {|| id }, "id", {|| .T. }, {|| validacija_postoji_sifra( wid ) } }, ;
      { PadR( "Naziv", 20 ), {||  naz }, "naz" }, ;
      { PadR( "JMJ", 3 ), {|| PadC( jmj, 3 ) }, "jmj"  }, ;
      { PadR( "Iznos", 8 ), {|| Iznos }, "Iznos"  }  ;
      }
   Kol := { 1, 2, 3, 4 }

   PushWa()
   lRet := p_sifra( F_NORSIHT, 1, f18_max_rows() - 15, f18_max_cols() - 20, "Lista: Norme u sihtarici", @cId, nDeltaX, nDeltaY )
   PopWa()

   RETURN lRet



FUNCTION TotBrisRadn()

   LOCAL cSigurno := "N"
   LOCAL nRec
   LOCAL hParams

   PRIVATE cIdRadn := Space( 6 )

   IF !spec_funkcije_sifra( "SIGMATB " )
      RETURN .F.
   ENDIF

   // o_ld_radn()         // id, "1"
   // O_RADKR        // idradn, "2"
   // select_o_ld()           // idradn, "RADN"
   O_LDSM         // idradn, "RADN"

   Box(, 7, 75 )
   @ box_x_koord() + 0, box_y_koord() + 5 SAY _l( "TOTALNO BRISANJE RADNIKA IZ EVIDENCIJE" )
   @ box_x_koord() + 8, box_y_koord() + 20 SAY _l( "<F5> - trazenje radnika pomocu sifrarnika" )
   SET KEY K_F5 TO TRUSif()
   DO WHILE .T.
      BoxCLS()
      IF cSigurno == "D"
         cIdRadn := Space( 6 )
         cSigurno := "N"
      ENDIF

      @ box_x_koord() + 2, box_y_koord() + 2 SAY _l( "Radnik" ) GET cIdRadn PICT "@!"
      @ box_x_koord() + 6, box_y_koord() + 2 SAY "Sigurno ga zelite obrisati (D/N) ?" GET cSigurno WHEN PrTotBR( cIdRadn ) VALID cSigurno $ "DN" PICT "@!"

      READ

      IF ( LastKey() == K_ESC )
         EXIT
      ENDIF

      IF cSigurno != "D"
         LOOP
      ENDIF


      run_sql_query( "BEGIN" )
      IF !f18_lock_tables( { "ld_ld", "ld_radkr" }, .T. )
         run_sql_query( "ROLLBACK" )
         RETURN .F.
      ENDIF

      // brisem ga iz sifarnika radnika
      // -------------------------------
      select_o_radn( cIdRadn )
      DO WHILE !Eof() .AND. id == cIdRadn
         SKIP 1
         nRec := RecNo()
         SKIP -1
         _rec := dbf_get_rec()
         delete_rec_server_and_dbf( "ld_radn", _rec, 1, "CONT" )
         GO ( nRec )
      ENDDO

      // brisem ga iz baze kredita
      // -------------------------

      seek_radkr_2( cIdRadn )
      DO WHILE !Eof() .AND. idradn == cIdRadn
         SKIP 1
         nRec := RecNo()
         SKIP -1
         _rec := dbf_get_rec()
         delete_rec_server_and_dbf( "ld_radkr", _rec, 1, "CONT" )
         GO ( nRec )
      ENDDO

      // brisem ga iz baze obracuna
      // --------------------------
      SELECT ld

      SET ORDER TO TAG "RADN"
      GO TOP
      SEEK cIdRadn
      DO WHILE !Eof() .AND. idradn == cIdRadn
         SKIP 1
         nRec := RecNo()
         SKIP -1
         _rec := dbf_get_rec()
         delete_rec_server_and_dbf( "ld_ld", _rec, 1, "CONT" )
         GO ( nRec )
      ENDDO

   ENDDO


   hParams := hb_Hash()
   hParams[ "unlock" ] := { "ld_ld", "ld_radn", "ld_radkr" }
   run_sql_query( "COMMIT", hParams )

   SET KEY K_F5 TO

   BoxC()

   my_close_all_dbf()

   RETURN .T.


FUNCTION PrTotBr( cIdRadn )

   LOCAL cBI := "W+/G"

   select_o_radn( cIdRadn )

   seek_radkr_2( cIdRadn )
   cKljuc := Str( radkr->godina, 4 ) + Str( radkr->mjesec, 2 )

   DO WHILE !Eof() .AND. idradn == cIdRadn
      IF ( cKljuc < Str( godina, 4 ) + Str( mjesec, 2 ) )
         cKljuc := Str( godina, 4 ) + Str( mjesec, 2 )
      ENDIF
      SKIP 1
   ENDDO
   SKIP -1


   select_o_radn( cIdRadn )

   cKljuc := Str( godina, 4 ) + Str( mjesec, 2 )

   DO WHILE !Eof() .AND. idradn == cIdRadn
      IF cKljuc < Str( godina, 4 ) + Str( mjesec, 2 )
         cKljuc := Str( godina, 4 ) + Str( mjesec, 2 )
      ENDIF
      SKIP 1
   ENDDO
   SKIP -1

   SELECT ( F_LDSM )
   SET ORDER TO TAG "RADN"
   GO TOP
   SEEK cIdRadn // ldsm
   cKljuc := Str( godina, 4 ) + Str( mjesec, 2 )
   DO WHILE !Eof() .AND. idradn == cIdRadn
      IF cKljuc < Str( godina, 4 ) + Str( mjesec, 2 )
         cKljuc := Str( godina, 4 ) + Str( mjesec, 2 )
      ENDIF
      SKIP 1
   ENDDO
   SKIP -1

   @ box_x_koord() + 3, box_y_koord() + 1 CLEAR TO box_x_koord() + 5, box_y_koord() + 75
   @ box_x_koord() + 3, box_y_koord() + 2 SAY "PREZIME I IME:"
   @ box_x_koord() + 3, box_y_koord() + 17 SAY IF( RADN->id == cIdRadn, RADN->( Trim( naz ) + " (" + Trim( imerod ) + ") " + Trim( ime ) ), "nema podatka" ) COLOR cBI
   @ box_x_koord() + 4, box_y_koord() + 2 SAY "POSLJEDNJI OBRACUN:"
   @ box_x_koord() + 4, box_y_koord() + 22 SAY IF( LD->idradn == cIdRadn, Str( LD->mjesec, 2 ) + "/" + Str( LD->godina, 4 ), "nema podatka" ) COLOR cBI
   @ box_x_koord() + 4, box_y_koord() + 35 SAY "RJ:"
   @ box_x_koord() + 4, box_y_koord() + 39 SAY IF( LD->idradn == cIdRadn, LD->idrj, "nema podatka" ) COLOR cBI
   @ box_x_koord() + 5, box_y_koord() + 2 SAY "POSLJEDNJA RATA KREDITA:"
   @ box_x_koord() + 5, box_y_koord() + 27 SAY IF( RADKR->idradn == cIdRadn, Str( RADKR->mjesec, 2 ) + "/" + Str( RADKR->godina, 4 ), "nema podatka" ) COLOR cBI

   RETURN iif( RADN->id == cIdRadn .OR. LD->idradn == cIdRadn .OR.  LDSM->idradn == cIdRadn .OR. RADKR->idradn == cIdRadn, .T., .F. )




FUNCTION TRUSif()

   IF ReadVar() == "CIDRADN"
      P_Radn( @cIdRadn )
      KEYBOARD Chr( K_ENTER ) + Chr( K_UP )
   ENDIF

   RETURN .T.



FUNCTION PorBl( Ch )

   LOCAL nVrati := DE_CONT
   LOCAL nRec := RecNo()
   PRIVATE GetList := {}

   RETURN nVrati




FUNCTION DoprBl( Ch )

   LOCAL nVrati := DE_CONT
   LOCAL nRec := RecNo()

   RETURN nVrati
