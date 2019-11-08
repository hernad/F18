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


FUNCTION pos_preuzmi_iz_kalk( cIdTipDok, cBrDok )

   LOCAL _imp_table := ""
   LOCAL _destination := ""
   LOCAL _br_dok
   LOCAL _val_otpremnica
   LOCAL _val_zaduzenje
   LOCAL _val_inventura
   LOCAL _val_nivelacija
   LOCAL cIdPos //, cIdPos
   LOCAL lOk := .T.

   cIdPos := gIdPos
   //cIdPos := Space( 2 )
   _val_otpremnica := "95"
   _val_zaduzenje := "11#12#13#80#81"
   _val_inventura := "IP"
   _val_nivelacija := "19"

   _destination := AllTrim( gKalkDest )

   SET CURSOR ON
   o_pos_priprz()

   _br_dok := Space( FIELD_LEN_POS_BRDOK )

   IF priprz->( RecCount2() ) == 0 .AND. Pitanje( , "Preuzeti dokumente iz KALK-a", "N" ) == "N"
      RETURN .F.
   ENDIF

   IF !get_import_file( _br_dok, @_destination, @_imp_table )
      RETURN .F.
   ENDIF

   SELECT ( F_TMP_KATOPS )
   my_use_temp( "KATOPS", _imp_table )

   _id_tip_dok := _get_vd( katops->idvd )
   cIdTipDok := _id_tip_dok

   //SELECT pos_doks
   //SET ORDER TO TAG "1"

   _br_dok := pos_novi_broj_dokumenta( cIdPos, cIdTipDok )
   cBrDok := _br_dok

   SELECT katops
   GO TOP

   MsgO( "kalk -> priprema, update roba " )

   DO WHILE !Eof()
      IF ( katops->idpos == cIdPos )
         IF import_row( _id_tip_dok, _br_dok, "" ) == 0
            lOk := .F.
            EXIT
         ENDIF
      ENDIF
      SELECT katops
      SKIP
   ENDDO

   SELECT katops
   USE

   MsgC()

   IF !lOk
      MsgBeep( "Procedura importa nije uspješna !" )
   ENDIF

   IF lOk
      _brisi_fajlove_importa( _imp_table )
   ENDIF

   RETURN .T.



STATIC FUNCTION _get_vd( cIdVd )

   LOCAL _ret := "16"

   DO CASE
   CASE cIdVd $ "11#80#81"
      _ret := "16"
   CASE cIdVd $ "19"
      _ret := "NI"
   CASE cIdVd $ "IP"
      _ret := "IN"
   ENDCASE

   RETURN _ret


STATIC FUNCTION _brisi_fajlove_importa( cImportFile )

   FileDelete( cImportFile )
   FileDelete( StrTran( cImportFile, ".dbf", ".txt" ) )

   RETURN .T.


STATIC FUNCTION uslovi_za_insert_ispunjeni()

   LOCAL lOk := .T.

   IF Abs( katops->mpc ) - Abs( Val( Str( katops->mpc, 8, 3 ) ) ) <> 0
      MsgBeep( "Cijena artikla: " + AllTrim( katops->idroba ) + " van dozvoljenog ranga: " + AllTrim( Str( katops->mpc ) ) )
      lOk := .F.
   ENDIF

   RETURN lOk


STATIC FUNCTION import_row( cIdTipDk, cBrDok, cIdOdj )

   LOCAL nDbfArea := Select()

   IF !uslovi_za_insert_ispunjeni()
      RETURN 0
   ENDIF

   SELECT priprz
   APPEND BLANK

   REPLACE idroba WITH katops->idroba
   REPLACE cijena WITH katops->mpc

   REPLACE kolicina WITH katops->kolicina

   IF cIdTipDk == "NI"
      REPLACE ncijena WITH katops->mpc2
   ENDIF

   IF cIdTipDk == "IN"
      REPLACE kolicina WITH katops->kol2
      REPLACE kol2 WITH katops->kolicina
   ENDIF

   REPLACE idtarifa WITH katops->idtarifa
   REPLACE jmj WITH katops->jmj
   REPLACE robanaz WITH katops->naziv
   REPLACE k1 WITH katops->k1
   REPLACE k2 WITH katops->k2
   REPLACE k7 WITH katops->k7
   REPLACE k8 WITH katops->k8
   REPLACE k9 WITH katops->k9
   REPLACE n1 WITH katops->n1
   REPLACE n2 WITH katops->n2
   REPLACE barkod WITH katops->barkod
   REPLACE PREBACEN WITH OBR_NIJE
   REPLACE IDRADNIK WITH gIdRadnik
   REPLACE IdPos WITH KATOPS->IdPos
   REPLACE IdOdj WITH cIdOdj
   REPLACE IdVd WITH cIdTipDk
   REPLACE Smjena WITH gSmjena
   REPLACE BrDok WITH cBrDok
   REPLACE DATUM WITH gDatum

   SELECT ( nDbfArea )

   RETURN 1



STATIC FUNCTION get_import_file( cBrDok, cDestinacijaDir, cFile )

   LOCAL _filter
   LOCAL cIdPos, cPrefixLocal
   LOCAL _imp_files := {}
   LOCAL _opc := {}
   LOCAL _h, nI
   LOCAL nIzbor
   LOCAL lPrenijeti

   _filter := 2
   cIdPos := AllTrim( gIdPos )

   IF !Empty( cIdPos )
      //cIdPos := cIdPos
      cPrefixLocal := ( Trim( cIdPos ) ) + SLASH
   ELSE
      cPrefixLocal := ""
   ENDIF

   cDestinacijaDir := AllTrim( gKalkDest ) + cPrefixLocal

   brisi_stare_fajlove( cDestinacijaDir )

   _imp_files := Directory( cDestinacijaDir + "kt*.dbf" )

   ASort( _imp_files,,, {| x, y| DToS( x[ 3 ] ) + x[ 4 ] > DToS( y[ 3 ] ) + y[ 4 ] } )

   AEval( _imp_files, {| elem| AAdd( _opc, PadR( elem[ 1 ], 15 ) + UChkPostoji() + " " + DToC( elem[ 3 ] ) + " " + elem[ 4 ] ) }, 1 )

   ASort( _opc,,, {| x, y| Right( x, 17 ) > Right( y, 17 ) } )

   _h := Array( Len( _opc ) )
   FOR nI := 1 TO Len( _h )
      _h[ nI ] := ""
   NEXT

   IF Len( _opc ) == 0
      MsgBeep( "U direktoriju za prenos nema podataka /P" )
      CLOSE ALL
      RETURN .F.
   ENDIF


   nIzbor := 1
   lPrenijeti := .F.
   DO WHILE .T.
      nIzbor := meni_0( "k2p", _opc, nIzbor, .F. )
      IF nIzbor == 0
         EXIT
      ELSE
         cFile := Trim( cDestinacijaDir ) + Trim( Left( _opc[ nIzbor ], 15 ) )
         IF Pitanje(, "Prenijeti " + Right( cFile, 30 ) + " ?", "D" ) == "D"
            lPrenijeti := .T.
            nIzbor := 0
         ENDIF
      ENDIF
   ENDDO

   IF !lPrenijeti
      RETURN .F.
   ENDIF

   RETURN .T.


//STATIC FUNCTION GetPm( cIdPos )
//   LOCAL _pm
//   _pm := AllTrim( cIdPos )
//   RETURN _pm



//STATIC FUNCTION _o_real_table()

//   o_roba()
//   o_pos_kase()
//   o_pos_pos()
//   o_pos_doks()

//   RETURN .T.



FUNCTION pos_prenos_inv_2_kalk( cIdPos, cIdTipDk, dDatDok, cBrDok )

   LOCAL nRbr, hRec
   LOCAL nKolicina
   LOCAL nIznos
   LOCAL nDbfArea := Select()
   LOCAL _count
   LOCAL cIdRoba

   IF cIdTipDk <> VD_INV
      RETURN .F.
   ENDIF

   cre_pom_topska_dbf()

   //_o_real_table()

   IF !pos_dokument_postoji( cIdPos, cIdTipDk, dDatDok, cBrDok )
      MsgBeep( "Dokument: " + cIdPos + "-" + cIdTipDk + "-" + PadL( cBrDok, 6 ) + " ne postoji !" )
      RETURN .F.
   ENDIF

   nRbr := 0
   nKolicina := 0
   nIznos := 0

   //SELECT pos
   //SET ORDER TO TAG "1"
   //GO TOP
   //SEEK cIdPos + cIdTipDk + DToS( dDatDok ) + cBrDok

   IF !seek_pos_pos( cIdPos, cIdTipDk, dDatDok, cBrDok )
   //IF !Found()
      MsgBeep( "POS tabela nema stavki !" )
      SELECT ( nDbfArea )
      RETURN .F.
   ENDIF

   MsgO( "Eksport dokumenta u toku ..." )

   DO WHILE !Eof() .AND. field->idpos == cIdPos .AND. field->idvd == cIdTipDk .AND. ;
         field->datum == dDatDok .AND. field->brdok == cBrDok

      cIdRoba := field->idroba

      select_o_roba( cIdRoba )

      SELECT pom
      APPEND BLANK

      hRec := dbf_get_rec()

      hRec[ "idpos" ] := pos->idpos
      hRec[ "idvd" ] := pos->idvd
      hRec[ "datum" ] := pos->datum
      hRec[ "brdok" ] := pos->brdok
      hRec[ "kolicina" ] := pos->kolicina
      hRec[ "idroba" ] := pos->idroba
      hRec[ "idtarifa" ] := pos->idtarifa
      hRec[ "kol2" ] := pos->kol2
      hRec[ "mpc" ] := pos->cijena
      hRec[ "stmpc" ] := pos->ncijena
      hRec[ "barkod" ] := roba->barkod
      hRec[ "robanaz" ] := roba->naz
      hRec[ "jmj" ] := roba->jmj

      dbf_update_rec( hRec )

      ++nRbr

      SELECT pos
      SKIP

   ENDDO

   MsgC()

   IF nRbr == 0
      MsgBeep( "Ne postoji niti jedna stavka u eksport tabeli !" )
      SELECT ( nDbfArea )
      RETURN .F.
   ENDIF

   SELECT pom
   USE

   cTopskaFile := pos_kalk_create_topska_dbf( cIdPos, dDatDok, dDatDok, cIdTipDk, "tk_p" )
   MsgBeep( "Kreiran fajl " + cTopskaFile + "#broj stavki: " + AllTrim( Str( nRbr ) ) )


   SELECT ( nDbfArea )

   RETURN .T.



FUNCTION pos_kalk_prenos_realizacije( cIdPos, dDatumOd, dDatumDo ) //, cIdVd )

   LOCAL cUslovRoba := Space( 150 )
   LOCAL cUslovArtikleUkljuciIskljuci := "U"
   LOCAL aPom := {}
   LOCAL i
   LOCAL nRbr
   LOCAL nKolicina
   LOCAL nIznos
   LOCAL cIdVd := "42"

   //LOCAL cIdPos
   //LOCAL dDatOd, dDatDo,
   LOCAL cTopskaFile
   LOCAL _tmp
   LOCAL lAutoPrenos := .F.
   LOCAL hRec
   LOCAL GetList := {}

   IF cIdPos <> NIL
      lAutoPrenos := .T.
   ELSE
      cIdPos := gIdPos
      //cIdVd := "42"
      dDatumOd := Date()
      dDatumDo := Date()
   ENDIF

   //_o_real_table()


   IF !lAutoPrenos
      SET CURSOR ON

      Box(, 4, 70, .F., " PRENOS REALIZACIJE POS->KALK   " )
      @ box_x_koord() + 1, box_y_koord() + 2 SAY "Prodajno mjesto " GET cIdPos PICT "@!" VALID !Empty( cIdPos ) .OR. p_pos_kase( @cIdPos, 5, 20 )
      @ box_x_koord() + 2, box_y_koord() + 2 SAY "Prenos za period" GET dDatumOd
      @ box_x_koord() + 2, Col() + 2 SAY "-" GET dDatumDo
      @ box_x_koord() + 3, box_y_koord() + 2 SAY "Uslov po artiklima:" GET cUslovRoba PICT "@S40"
      @ box_x_koord() + 4, box_y_koord() + 2 SAY8 "Artikle (U)ključi / (I)sključi iz prenosa:" GET cUslovArtikleUkljuciIskljuci PICT "@!" VALID cUslovArtikleUkljuciIskljuci $ "UI"

      READ
      ESC_BCR

      BoxC()

   ENDIF

   gIdPos := cIdPos

   cre_pom_topska_dbf()
   //_o_real_table()
   seek_pos_doks_2_za_period( cIdVd, dDatumOd, dDatumDo )
   //SET ORDER TO TAG "2"
   //GO TOP
   //SEEK cIdVd + DToS( dDatOd )

   EOF CRET

   nRbr := 0
   nKolicina := 0
   nIznos := 0

   IF !Empty( cUslovRoba ) .AND. Right( AllTrim( cUslovRoba ) ) <> ";"
      cUslovRoba := AllTrim( cUslovRoba ) + ";"
   ENDIF

   DO WHILE !Eof() .AND. pos_doks->IdVd == cIdVd .AND. pos_doks->Datum <= dDatumDo

      IF !Empty( cIdPos ) .AND. pos_doks->IdPos <> cIdPos
         SKIP
         LOOP
      ENDIF

      seek_pos_pos( pos_doks->IdPos, pos_doks->IdVd, pos_doks->datum, pos_doks->BrDok )
      DO WHILE !Eof() .AND. pos->IdPos + pos->IdVd + DToS( pos->datum ) + pos->Brdok  == pos_doks->IdPos + pos_doks->IdVd + DToS( pos_doks->datum ) + pos_doks->BrDok

         IF !Empty( cUslovRoba )
            _tmp := Parsiraj( cUslovRoba, "idroba" )
            if &_tmp

               IF cUslovArtikleUkljuciIskljuci == "I"
                  SKIP
                  LOOP
               ENDIF

            ELSE
               IF cUslovArtikleUkljuciIskljuci == "U"
                  SKIP
                  LOOP
               ENDIF
            ENDIF
         ENDIF

         select_o_roba( pos->idroba )

         SELECT pom
         SET ORDER TO TAG "1"
         GO TOP
         SEEK pos->idpos + pos->idroba + Str( pos->cijena, 13, 4 ) + Str( pos->ncijena, 13, 4 ) // POM

         nKolicina += pos->kolicina
         nIznos += ( pos->kolicina * pos->cijena )

         IF !Found() .OR. pom->IdTarifa <> POS->IdTarifa .OR. pom->MPC <> POS->Cijena

            APPEND BLANK
            REPLACE IdPos WITH POS->IdPos, ;
               IdRoba WITH POS->IdRoba, ;
               Kolicina WITH POS->Kolicina, ;
               IdTarifa WITH POS->IdTarifa, ;
               mpc WITH POS->Cijena, ;
               IdCijena WITH POS->IdCijena, ;
               Datum WITH dDatumDo, ;
               DatPos WITH pos->datum, ;
               brdok WITH pos->brdok, ;
               idvd WITH POS->IdVd, ;
               StMPC WITH pos->ncijena, ;
               barkod WITH roba->barkod, ;
               robanaz WITH roba->naz

            IF !Empty( pos_doks->idgost )
               REPLACE idpartner WITH pos_doks->idgost
            ENDIF

            ++nRbr
         ELSE

            hRec := dbf_get_rec()
            hRec[ "kolicina" ] := hRec[ "kolicina" ] + pos->kolicina
            dbf_update_rec( hRec )

         ENDIF

         SELECT pos
         SKIP

      ENDDO

      SELECT pos_doks
      SKIP

   ENDDO

   SELECT pom
   USE

   my_close_all_dbf()

   IF !lAutoPrenos
      pos_kalk_prenos_report( dDatumOd, dDatumDo, nKolicina, nIznos, nRbr )
      cTopskaFile := pos_kalk_create_topska_dbf( cIdPos, dDatumOd, dDatumDo, cIdVd )
      MsgBeep( "Kreiran fajl " + cTopskaFile + "#broj stavki: " + AllTrim( Str( nRbr ) ) )
   ENDIF

   RETURN .T.



STATIC FUNCTION pos_kalk_prenos_report( dDatOd, dDatDo, nKolicina, nIznos, nBrojStavki )

   //START PRINT CRET
   start_print_editor()

   ?
   ? "PRENOS PODATAKA TOPS->KALK za ", DToC( Date() )
   ?
   ? "Datumski period od", DToC( dDatOd ), "do", DToC( dDatDo )
   ? "Broj stavki:", AllTrim( Str( nBrojStavki ) )
   ?
   ?U "Ukupna količina:", AllTrim( Str( nKolicina, 12, 2 ) )
   ?U "   Ukupan iznos:", AllTrim( Str( nIznos, 12, 2 ) )

   FF
   //ENDPRINT
   end_print_editor()

   RETURN .T.



STATIC FUNCTION cre_pom_topska_dbf()

   LOCAL aDbf := {}

   AAdd( aDBF, { "IdPos",    "C",   2, 0 } )
   AAdd( aDBF, { "IDROBA",   "C",  10, 0 } )
   AAdd( aDBF, { "ROBANAZ",  "C", 250, 0 } )
   AAdd( aDBF, { "kolicina", "N",  13, 4 } )
   AAdd( aDBF, { "kol2",     "N",  13, 4 } )
   AAdd( aDBF, { "MPC",      "N",  13, 4 } )
   AAdd( aDBF, { "STMPC",    "N",  13, 4 } )
   AAdd( aDBF, { "IDTARIFA", "C",   6, 0 } )
   AAdd( aDBF, { "IDCIJENA", "C",   1, 0 } )
   AAdd( aDBF, { "IDPARTNER", "C",  10, 0 } )
   AAdd( aDBF, { "DATUM",    "D",   8, 0 } )
   AAdd( aDBF, { "DATPOS",   "D",   8, 0 } )
   AAdd( aDBF, { "IdVd",     "C",   2, 0 } )
   AAdd( aDBF, { "BRDOK",    "C",  10, 0 } )
   AAdd( aDBF, { "M1",       "C",   1, 0 } )
   AAdd( aDBF, { "BARKOD",   "C",  13, 0 } )
   AAdd( aDBF, { "JMJ",      "C",   3, 0 } )

   //seek_pos_doks( "XX", "XX" )
   pos_cre_pom_dbf( aDbf )

   SELECT ( F_POM )
   IF Used()
      USE
   ENDIF

   my_use_temp( "POM", my_home() + "pom", .F., .T. )

   INDEX on ( idpos + idroba + Str( mpc, 13, 4 ) + Str( stmpc, 13, 4 ) ) TAG "1"

   SET ORDER TO TAG "1"

   RETURN .T.




/*
 kreira izlazni fajl za multi prodajna mjesta režim
*/

STATIC FUNCTION pos_kalk_create_topska_dbf( cIdPos, dDatOd, dDatDo, cIdTipDok, cPrefix )

   LOCAL cPrefixLocal := "tk"
   LOCAL cExportDirektorij
   LOCAL cTableName
   LOCAL _table_path
   LOCAL cFajlDestinacija := ""
   LOCAL _bytes := 0
   //LOCAL cIdPos

   IF cPrefix != NIL
      cPrefixLocal := cPrefix
   ENDIF

   IF Right( AllTrim( gKalkDest ), 1 ) <> SLASH
      gKalkDest := AllTrim( gKalkDest ) + SLASH
   ENDIF

   direktorij_kreiraj_ako_ne_postoji( AllTrim( gKalkDest ) )

   //cIdPos := GetPm( cIdPos )
   cIdPos := Alltrim( cIdPos )

   cExportDirektorij := AllTrim( gKalkDest ) + cIdPos + SLASH

   direktorij_kreiraj_ako_ne_postoji( AllTrim( cExportDirektorij ) )

   DirChange( my_home() )

   cTableName := get_tops_kalk_export_file( "1", cExportDirektorij, dDatDo, cPrefix )

   cFajlDestinacija := cExportDirektorij + cTableName + ".dbf"

   IF FileCopy( my_home() + "pom.dbf", cFajlDestinacija ) > 0
      FileCopy( txt_print_file_name(), StrTran( cFajlDestinacija, ".dbf", ".txt" ) )
   ELSE
      MsgBeep( "Problem sa kopiranjem fajla na lokaciju #" + cExportDirektorij )
   ENDIF

   RETURN cFajlDestinacija
