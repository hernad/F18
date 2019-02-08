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


STATIC aBoxStack := {}
STATIC nPos := 0
STATIC cPokPonovo := "Pokušati ponovo (D/N) ?"
STATIC nPreuseLevel := 0


FUNCTION Gather( cZn )

   LOCAL i, aStruct
   LOCAL bFieldBlock
   LOCAL cImePolja
   LOCAL cVar
   LOCAL cMsg, oErr

   IF cZn == nil
      cZn := "_"
   ENDIF
   aStruct := dbStruct()

   BEGIN SEQUENCE WITH {| err | Break( err ) }

      FOR i := 1 TO Len( aStruct )
         bFieldBlock := FieldBlock( cImePolja := fix_dat_var( aStruct[ i, 1 ] ) )
         cVar := cZn + cImePolja
         Eval( bFieldBlock, Eval( MemVarBlock( cVar ) ) )
      NEXT

   RECOVER USING oErr

      Alert("gather error:" + oErr:description)
      cMsg := RECI_GDJE_SAM + " ne postoji/neispravna MEMVAR " + cVar + " trenutna tabela: " + Alias()
      ?E cMsg
      log_write( cMsg, 1 )
      Alert( cMsg )
      RaiseError( cMsg )

   END SEQUENCE

   RETURN NIL


/* Scatter
  *    vrijednosti field varijabli tekuceg sloga prebacuje u public varijable
  *
  *  param: cZn - Default = "_"; odredjuje prefixs varijabli koje ce generisati
  *
  * code
  *
  *  use ROBA
  *  Scatter("_")
  *  ? _id, _naz, _jmj
  *
  * endcode
  *
  */

FUNCTION Scatter( cZn, lUtf )
   RETURN set_global_vars_from_dbf( cZn, lUtf )


// --------------------------------------------------
// TODO: ime set_global_vars_from_dbf je legacy
// --------------------------------------------------
FUNCTION set_global_vars_from_dbf( cVarPrefix, lConvertToUtf )

   LOCAL nI, aDbStruct, cFieldName, cFieldType, cFieldWidth, _var
   LOCAL lSql := ( my_rddName() ==  "SQLMIX" )

   PRIVATE cImeP, cVar

   IF cVarPrefix == NIL
      cVarPrefix := "_"
   ENDIF

   hb_default( @lConvertToUtf, .F. )

   aDbStruct := dbStruct()

   FOR nI := 1 TO Len( aDbStruct )
      cFieldName := aDbStruct[ nI, 1 ]
      cFieldType := aDbStruct[ nI, 2 ]
      cFieldWidth := aDbStruct[ nI, 3 ]

      IF !( "#" + cFieldName + "#" $ "#BRISANO#_OID_#_COMMIT_#" )
         _var := cVarPrefix + cFieldName
         // kreiram public varijablu sa imenom vrijednosti _var varijable
         __mvPublic( _var ) // wNaz
         Eval( MemVarBlock( _var ), Eval( FieldBlock( cFieldName ) ) ) // wNaz <-- SADRŽAJ

         IF cFieldType == "C" .OR. cFieldType == "M"  // memo or char -- Valtype( &_var ) == "C"

            IF cFieldType == "C" .AND. &_var == "" // sql empty field = ""
               &_var := Space( cFieldWidth )
            ENDIF

            IF lSql .AND. F18_SQL_ENCODING == "UTF8"// sql tabela utf->str
               &_var := hb_UTF8ToStr( &_var )
            ENDIF

            IF lConvertToUtf // str->utf
               &_var := hb_StrToUTF8( &_var )
            ENDIF
         ENDIF

      ENDIF
   NEXT

   RETURN .T.


FUNCTION GatherR( cZn )

   LOCAL i, j, aStruct

   IF cZn == nil
      cZn := "_"
   ENDIF
   aStruct := dbStruct()
   SkratiAZaD( @aStruct )
   WHILE .T.

      FOR j := 1 TO Len( aRel )
         IF aRel[ j, 1 ] == Alias()  // {"K_0","ID","K_1","ID",1}
            // matrica relacija
            cVar := cZn + aRel[ j, 2 ]
            xField := &( aRel[ j, 2 ] )
            IF &cVar == xField // ako nije promjenjen broj
               LOOP
            ENDIF
            SELECT ( aRel[ j, 3 ] )
            SET ORDER TO aRel[ j, 5 ]
            DO WHILE .T.
               IF FLock()
                  SEEK xField
                  DO WHILE &( aRel[ j, 4 ] ) == xField .AND. !Eof()
                     SKIP
                     nRec := RecNo()
                     SKIP -1
                     field->&( aRel[ j, 4 ] ) := &cVar
                     GO nRec
                  ENDDO

               ELSE
                  Inkey( 0.4 )
                  LOOP
               ENDIF
               EXIT
            ENDDO // .t.
            SELECT ( aRel[ j, 1 ] )
         ENDIF
      NEXT    // j


      FOR i := 1 TO Len( aStruct )
         cImeP := aStruct[ i, 1 ]
         cVar := cZn + cImeP
         field->&cImeP := &cVar
      NEXT
      EXIT
   END

   RETURN NIL


/*
*      Gather ne versi rlock-unlock
*   note Gather2 pretpostavlja zakljucan zapis !!
*/

FUNCTION Gather2( cVarPrefix )

   LOCAL nI, aDbStruct
   LOCAL bFieldBlock, _var, cImePolja

   IF cVarPrefix == nil
      cVarPrefix := "_"
   ENDIF

   aDbStruct := dbStruct()

   FOR nI := 1 TO Len( aDbStruct )
      cImePolja := aDbStruct[ nI, 1 ]
      bFieldBlock := FieldBlock( cImePolja )
      _var :=  cVarPrefix + cImePolja

      IF  !( "#" + cImePolja + "#"  $ "#BRISANO#_SITE_#_OID_#_USER_#_COMMIT_#_DATAZ_#_TIMEAZ_#" )
         Eval( bFieldBlock, Eval( MemVarBlock( _var ) ) )
      ENDIF
   NEXT

   RETURN .T.


FUNCTION delete2()

   LOCAL nRec

   DO WHILE .T.

      IF my_rlock()
         dbdelete2()
         my_unlock()
         EXIT
      ELSE
         Inkey( 0.4 )
         LOOP
      ENDIF

   ENDDO

   RETURN NIL


FUNCTION dbdelete2()

   IF !Eof() .OR. !Bof()
      dbDelete()
   ENDIF

   RETURN NIL


/*
*
* fcisti =  .t. - pocisti polja
*           .f. - ostavi stare vrijednosti polja
* funl    = .t. - otkljucaj zapis, pa zakljucaj zapis
*           .f. - ne diraj (pretpostavlja se da je zapis vec zakljucan)
*/

FUNCTION appblank2( fcisti, funl )

   LOCAL aStruct, i, nPrevOrd
   LOCAL cImeP

   IF fcisti == nil
      fcisti := .T.
   ENDIF

   nPrevOrd := IndexOrd()

   dbAppend( .T. )

   IF fcisti // ako zelis pocistiti stare vrijednosti
      aStruct := dbStruct()
      FOR i := 1 TO Len( aStruct )
         cImeP := aStruct[ i, 1 ]
         IF !( "#" + cImeP + "#"  $ "#BRISANO#_OID_#_COMMIT_#" )
            DO CASE
            CASE aStruct[ i, 2 ] == 'C'
               field->&cImeP := ""
            CASE aStruct[ i, 2 ] == 'N'
               field->&cImeP := 0
            CASE aStruct[ i, 2 ] == 'D'
               field->&cImeP := CToD( "" )
            CASE aStruct[ i, 2 ] == 'L'
               field->&cImeP := .F.
            ENDCASE
         ENDIF
      NEXT
   ENDIF  // fcisti

   ordSetFocus( nPrevOrd )

   RETURN NIL


/* AppFrom(cFDbf, fOtvori)
*     apenduje iz cFDbf-a u tekucu tabelu
*   param: cFDBF - ime dbf-a
*   param: fOtvori - .t. - otvori DBF, .f. - vec je otvorena
*/

FUNCTION AppFrom( cFDbf, fOtvori )

   LOCAL nArr

   nArr := Select()

   cFDBF := ToUnix( cFDBF )

   DO WHILE .T.
      IF !FLock()
         Inkey( 0.4 )
         LOOP
      ENDIF
      EXIT
   ENDDO

   IF fotvori
      USE ( cFDbf ) new
   ELSE
      SELECT ( cFDbF )
   ENDIF

   GO TOP

   DO WHILE !Eof()
      SELECT ( nArr )
      Scatter( "f" )

      SELECT ( cFDBF )
      Scatter( "f" )

      SELECT ( nArr )   // prebaci se u tekuci fajl-u koji zelis staviti zapise
      appblank2( .F., .F. )
      Gather2( "f" ) // pretpostavlja zakljucan zapis

      SELECT ( cFDBF )
      SKIP
   ENDDO
   IF fOtvori
      USE // zatvori from DBF
   ENDIF

   dbUnlock()
   SELECT ( nArr )

   RETURN .T.


FUNCTION PrazanDbf()
   RETURN .F.



FUNCTION seek2( cArg )

   dbSeek( cArg )

   RETURN NIL

// -------------------------------------------------------------------
// brise sve zapise - ako jmarkira za brisanje sve zapise u bazi
// ako je exclusivno otvorena - __dbZap, ako je shared,
// markiraj za deleted sve zapise
//
// - pack - prepakuj zapise
// -------------------------------------------------------------------

FUNCTION zapp( PACK )

   LOCAL bErr

   IF !Used()
      RETURN .F.
   ENDIF

   IF PACK == NIL
      PACK := .F.
   ENDIF


   BEGIN SEQUENCE WITH {| err | Break( err ) }

      __dbZap()
      ?E "ZAP exclusive OK: " + Alias()
      IF PACK
         __dbPack()
      ENDIF

   RECOVER

      ?E "zap shared: " + Alias()
      PushWA()
      DO WHILE .T.
         SET ORDER TO 0
         GO TOP
         DO WHILE !Eof()
            delete_with_rlock()
            SKIP
         ENDDO
         EXIT
      ENDDO
      PopWa()

   END SEQUENCE

   RETURN .T.



FUNCTION nErr( oe )

   break oe



/*  EofFndRet(ef, close)
 *  Daje poruku da ne postoje podaci
 *  param ef = .t.   gledaj eof();  ef == .f. gledaj found()
 *  return  .t. ako ne postoje podaci
 */

FUNCTION EofFndRet( lEof, lClose )

   LOCAL fRet := .F., cStr := "Ne postoje traženi podaci !"

   IF lEof // eof()
      IF Eof()
         Beep( 1 )
         Msg( cStr, 6 )
         fRet := .T.
      ENDIF
   ELSE
      IF !Found()
         Beep( 1 )
         Msg( cStr, 6 )
         fRet := .T.
      ENDIF
   ENDIF

   IF lClose .AND. fRet
      my_close_all_dbf()
   ENDIF

   RETURN fRet


/* spec_funkcije_sifra(cSif)
 *     zasticene funkcije sistema
 *
 * za programske funkcije koje samo serviser
 * treba da zna, tj koje obicni korisniku
 * nece biti dokumentovane
 *
 *  Default cSif=SIGMAXXX
 *
 * \return .t. kada je lozinka ispravna
*/

FUNCTION spec_funkcije_sifra( cSif )

   LOCAL lGw_Status, cSifra

   lGw_Status := IF( "U" $ Type( "GW_STATUS" ), "-", gw_status )

   GW_STATUS := "-"

   IF cSif == NIL
      cSif := "SIGMAXXX"
   ELSE
      cSif := PadR( cSif, 8 )
   ENDIF

   Box(, 2, 70 )
   cSifra := Space( 8 )
   @ box_x_koord() + 1, box_y_koord() + 2 SAY8 "Šifra za korištenje specijalnih funkcija:"
   cSifra := Upper( GetSecret( cSifra ) )
   BoxC()

   IF LASTKEY() == K_ESC
      return .F.
   ENDIF

   GW_STATUS := lGW_Status

   IF AllTrim( cSifra ) == AllTrim( cSif )
      RETURN .T.
   ELSE
      RETURN .F.
   ENDIF



/* O_POMDB(nArea,cImeDBF)
 *     otvori pomocnu tabelu, koja ako se nalazi na CDU npr se kopira u lokalni
 *   direktorij pa zapuje
 */

FUNCTION O_POMDB( nArea, cImeDBF )

   SELECT ( nArea )

   IF Right( Upper( cImeDBF ), 4 ) <> "." + DBFEXT
      cImeDBF := cImeDBf + "." + DBFEXT
   ENDIF
   cImeCDX := StrTran( Upper( cImeDBF ), "." + DBFEXT, "." + INDEXEXT )
   cImeCDX := ToUnix( cImeCDX )

   usex ( my_home() + cImeDBF )

   RETURN



FUNCTION DbfArea( tbl, VAR )

   LOCAL _rec
   LOCAL _only_basic_params := .T.

   IF ( VAR == NIL )
      VAR := 0
   ENDIF

   _rec := get_a_dbf_rec( Lower( tbl ), _only_basic_params )

   RETURN _rec[ "wa" ]




FUNCTION NDBF( tbl )
   RETURN DbfArea( tbl )



FUNCTION NDBFPos( tbl )
   RETURN DbfArea( tbl, 1 )



FUNCTION F_Baze( tbl )

   LOCAL _dbf_tbl
   LOCAL _area := 0
   LOCAL _rec
   LOCAL _only_basic_params := .T.

   _rec := get_a_dbf_rec( Lower( tbl ), _only_basic_params )

   // ovo je work area
   IF _rec <> NIL
      _area := _rec[ "wa" ]
   ENDIF

   IF _area <= 0
      my_close_all_dbf()
      // QUIT_1
   ENDIF

   RETURN _area



FUNCTION Sel_Bazu( tbl )

   LOCAL _area

   _area := F_baze( tbl )

   IF _area > 0
      SELECT ( _area )
   ELSE
      my_close_all_dbf()
      // QUIT_1
   ENDIF

   RETURN .T.


FUNCTION gaDBFDir( nPos )
   RETURN my_home()



FUNCTION O_Bazu( tbl )

   my_use( Lower( tbl ) )

   RETURN .T.



FUNCTION ExportBaze( cBaza )

   LOCAL nArr := Select()

   FErase( cBaza + "." + INDEXEXT )
   FErase( cBaza + "." + DBFEXT )
   cBaza += "." + DBFEXT
   COPY STRUCTURE EXTENDED TO ( my_home() + "struct" )
   CREATE ( cBaza ) FROM ( my_home() + "struct" ) NEW
   MsgO( "apendujem..." )
   APPEND FROM ( Alias( nArr ) )
   MsgC()
   USE
   SELECT ( nArr )

   RETURN


/*
  ImdDBFCDX(cIme)
    suban     -> suban.CDX
    suban.DBF -> suban.CDX
*/
FUNCTION ImeDBFCDX( cIme, ext )

   IF ext == NIL
      ext := INDEXEXT
   ENDIF

   cIme := Trim( StrTran( ToUnix( cIme ), "." + DBFEXT, "." + ext ) )

   IF Right ( cIme, 4 ) <> "." + ext
      cIme := cIme + "." + ext
   ENDIF

   RETURN  cIme
