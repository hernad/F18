/*
 * This file is part of the bring.out knowhow ERP, a free and open source
 * Enterprise Resource Planning software suite,
 * Copyright (c) 1994-2018 by bring.out d.o.o Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including knowhow ERP specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_knowhow.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */

#include "f18.ch"



CLASS VirmExportTxt

   METHOD New()
   METHOD params()
   METHOD export()

   METHOD export_setup()
   METHOD export_setup_read_params()
   METHOD export_setup_write_params()

   METHOD export_setup_duplicate()

   DATA export_params
   DATA formula_params
   DATA export_total
   DATA export_count

   PROTECTED:

   METHOD create_txt_from_dbf()
   METHOD _dbf_struct()
   METHOD create_export_dbf()
   METHOD fill_data_from_virm()
   METHOD get_export_line_macro()
   METHOD get_macro_line()
   METHOD get_export_params()
   METHOD get_export_list()
   METHOD copy_existing_formula()

ENDCLASS



METHOD VirmExportTxt:New()

   ::export_params := hb_Hash()
   ::formula_params := hb_Hash()
   ::export_total := 0
   ::export_count := 0

   RETURN SELF



// -----------------------------------------------------------
// struktura pomocne tabele
// -----------------------------------------------------------
METHOD VirmExportTxt:_dbf_struct()

   LOCAL _dbf := {}
   LOCAL nI, _a_tmp

   // struktura...
   AAdd( _dbf, { "RBR", "N",  3, 0 } )
   AAdd( _dbf, { "MJESTO", "C", 30, 0 } )

   AAdd( _dbf, { "PRIM_RN", "C", 16, 0 } )
   AAdd( _dbf, { "PRIM_NAZ", "C", 50, 0 } )
   AAdd( _dbf, { "PRIM_MJ", "C", 30, 0 } )

   AAdd( _dbf, { "POS_RN", "C", 16, 0 } )
   AAdd( _dbf, { "POS_NAZ", "C", 50, 0 } )
   AAdd( _dbf, { "POS_MJ", "C", 30, 0 } )

   AAdd( _dbf, { "SVRHA", "C", 140, 0 } )
   AAdd( _dbf, { "SIFRA_PL", "C",   6, 0 } )

   AAdd( _dbf, { "DAT_VAL", "D",   8, 0 } )
   AAdd( _dbf, { "PER_OD", "D",   8, 0 } )
   AAdd( _dbf, { "PER_DO", "D",   8, 0 } )

   AAdd( _dbf, { "TIP_ST", "C",   1, 0 } )
   AAdd( _dbf, { "TIP_DOK", "C",   1, 0 } )
   AAdd( _dbf, { "V_UPL", "C",   1, 0 } )
   AAdd( _dbf, { "OPCINA", "C",   3, 0 } )
   AAdd( _dbf, { "BPO", "C",  13, 0 } )

   AAdd( _dbf, { "V_PRIH", "C",   6, 0 } )
   AAdd( _dbf, { "BUDZET", "C",   7, 0 } )
   AAdd( _dbf, { "PNABR", "C",  10, 0 } )

   AAdd( _dbf, { "IZNOS", "N",  15, 2 } )

   AAdd( _dbf, { "TOT_IZN", "N",  15, 2 } )
   AAdd( _dbf, { "TOT_ST", "N",  15, 2 } )

   RETURN _dbf


// -----------------------------------------------------------
// kreiranje pomocne tabele
// -----------------------------------------------------------
METHOD VirmExportTxt:create_export_dbf()

   LOCAL _dbf
   LOCAL _table_name := "export"

   // struktura dbf-a
   _dbf := ::_dbf_struct()

   SELECT ( F_TMP_1 )
   USE

   FErase( my_home() + _table_name + ".dbf" )
   FErase( my_home() + _table_name + ".cdx" )

   dbCreate( my_home() + _table_name + ".dbf", _dbf )

   SELECT ( F_TMP_1 )
   USE
   my_use_temp( "EXP_BANK", my_home() + _table_name + ".dbf", .F., .F. )


   INDEX on ( Str( rbr, 3 ) ) TAG "1"

   RETURN .T.




// -----------------------------------------------------------
// parametri tekuceg exporta
// -----------------------------------------------------------

METHOD VirmExportTxt:params()

   LOCAL _ok := .F.
   LOCAL _name
   LOCAL _export := "D"
   LOCAL _obr := "1"
   LOCAL _file_name := PadR( "export_virm.txt", 50 )
   LOCAL _id_formula := fetch_metric( "virm_export_banke_tek", my_user(), 1 )
   LOCAL _x := 1

   Box(, 15, 70 )

   @ box_x_koord() + _x, box_y_koord() + 2 SAY "Tekuca formula eksporta (1 ... n):" GET _id_formula PICT "999" VALID ::get_export_params( @_id_formula )

   READ

   IF LastKey() == K_ESC
      ::export_params := NIL
      BoxC()
      RETURN _ok
   ENDIF

   _file_name := ::formula_params[ "file" ]
   _name := ::formula_params[ "name" ]

   ++ _x
   ++ _x
   @ box_x_koord() + _x, box_y_koord() + 2 SAY Replicate( "-", 60 )

   ++ _x
   @ box_x_koord() + _x, box_y_koord() + 2 SAY "  Odabrana varijanta: " + PadR( _name, 30 )

   ++ _x
   @ box_x_koord() + _x, box_y_koord() + 2 SAY "Naziv izlaznog fajla: " + PadR( _file_name, 20 )

   ++ _x
   ++ _x
   @ box_x_koord() + _x, box_y_koord() + 2 SAY "Export podataka (D/N)?" GET _export VALID _export $ "DN" PICT "@!"

   READ

   BoxC()

   IF LastKey() == K_ESC .OR. _export == "N"
      ::export_params := NIL
      RETURN _ok
   ENDIF

   set_metric( "virm_export_banke_tek", my_user(), _id_formula )

   ::export_params := hb_Hash()
   ::export_params[ "fajl" ] := _file_name
   ::export_params[ "formula" ] := _id_formula
   ::export_params[ "separator" ] := ::formula_params[ "separator" ]
   ::export_params[ "separator_formula" ] := ::formula_params[ "separator_formula" ]

   _ok := .T.

   RETURN _ok



// ----------------------------------------------------------
// dupliciranje postavke eksporta
// ----------------------------------------------------------
METHOD VirmExportTxt:export_setup_duplicate()

   LOCAL _existing := 1
   LOCAL _new := 0
   LOCAL oExisting := VirmExportTxt():New()
   LOCAL oNew := VirmExportTxt():New()
   PRIVATE GetList := {}

   Box(, 3, 60 )

   @ box_x_koord() + 1, box_y_koord() + 2 SAY "*** DUPLICIRANJE POSTAVKI EKSPORTA"
   @ box_x_koord() + 2, box_y_koord() + 2 SAY "Koristiti postojece podesenje broj:" GET _existing PICT "999"
   @ box_x_koord() + 3, box_y_koord() + 2 SAY "      Kreirati novo podesenje broj:" GET _new PICT "999"

   READ

   BoxC()

   IF LastKey() == K_ESC
      RETURN
   ENDIF

   IF _new > 0 .AND. _new <> _existing

      oExisting:export_setup_read_params( _existing )

      oNew:formula_params := oExisting:formula_params
      oNew:export_setup_write_params( _new )

   ENDIF

   RETURN .T.



// ----------------------------------------------------------
// kopiranje formule iz postojece formule
// ----------------------------------------------------------
METHOD VirmExportTxt:copy_existing_formula( id_formula, var )

   LOCAL oExport := VirmExportTxt():New()
   LOCAL _tmp
   PRIVATE GetList := {}

   IF Left( id_formula, 1 ) == "#"
      id_formula := StrTran( AllTrim( id_formula ), "#", "" )
   ELSE
      RETURN .T.
   ENDIF

   // uzmi postojecu formulu...
   IF oExport:get_export_params( Val( id_formula ) )

      _tmp := oExport:get_export_line_macro( var )

      IF !Empty( _tmp  )
         id_formula := PadR( _tmp, 500 )
      ELSE
         MsgBeep( "Zadata formula ne postoji !?" )
      ENDIF

   ENDIF

   RETURN .T.




// -----------------------------------------------------------
// generisanje podataka u pomocnu tabelu iz sql-a
// -----------------------------------------------------------
METHOD VirmExportTxt:fill_data_from_virm()

   LOCAL _ok := .F.
   LOCAL _count, hRec
   LOCAL nTotal := 0

   SELECT ( F_VIPRIPR )
   IF !Used()
      O_VIRM_PRIPR
   ENDIF

   SELECT virm_pripr
   SET ORDER TO TAG "1"
   GO TOP

   IF RecCount() == 0
      MsgBeep( "U pripremi nema virmana !" )
      RETURN _ok
   ENDIF

   _count := 0

   DO WHILE !Eof()

      nTotal += field->iznos
      ++ _count

      SELECT exp_bank
      APPEND BLANK
      hRec := dbf_get_rec()

      // popuni sada hRec
      hRec[ "rbr" ] := virm_pripr->rbr

      // mjesto
      hRec[ "mjesto" ] := Upper( virm_pripr->mjesto )

      // podaci posiljaoca i primaoca
      hRec[ "prim_rn" ] := virm_pripr->kome_zr
      hRec[ "prim_naz" ] := Upper( virm_pripr->kome_txt )
      hRec[ "prim_mj" ] := Upper( virm_pripr->kome_sj )

      IF Empty( hRec[ "prim_mj" ] )
         hRec[ "prim_mj" ] := hRec[ "mjesto" ]
      ENDIF

      hRec[ "pos_rn" ] := virm_pripr->ko_zr
      hRec[ "pos_naz" ] := Upper( virm_pripr->ko_txt )
      hRec[ "pos_mj" ] := Upper( virm_pripr->ko_sj )

      IF Empty( hRec[ "pos_mj" ] )
         hRec[ "pos_mj" ] := hRec[ "mjesto" ]
      ENDIF

      // svrha uplate
      hRec[ "svrha" ] := Upper( virm_pripr->svrha_doz )

      // sifra placanja po sifraniku TRN.DAT
      // ako je sifra duzine 4 za sifru se popuni sa 2 karaktera prazna
      hRec[ "sifra_pl" ] := virm_pripr->svrha_pl

      // datum valute
      hRec[ "dat_val" ] := virm_pripr->dat_upl

      // porezni period od-do
      hRec[ "per_od" ] := virm_pripr->pod
      hRec[ "per_do" ] := virm_pripr->pdo

      // tip stavke, fiskno "1"
      hRec[ "tip_st" ] := "1"

      // tip dokumenta:
      // 0 - nalog za prenos
      // 1 - nalog za placanje JP
      hRec[ "tip_dok" ] := "1"

      // vrsta uplate:
      // 0, 1 ili 2
      hRec[ "v_upl" ] := "0"

      // broj poreznog obveznika
      hRec[ "bpo" ] := virm_pripr->bpo

      // opcina
      hRec[ "opcina" ] := virm_pripr->idops

      // vrsta prihoda
      hRec[ "v_prih" ] := virm_pripr->idjprih

      // budzetska organizacija
      hRec[ "budzet" ] := virm_pripr->budzorg

      // poziv na broj
      hRec[ "pnabr" ] := virm_pripr->pnabr

      // iznos virmana
      hRec[ "iznos" ] := virm_pripr->iznos

      // total stavki...
      hRec[ "tot_st" ] := 0

      // total iznos...
      hRec[ "tot_izn" ] := 0

      dbf_update_rec( hRec )

      SELECT virm_pripr
      SKIP

   ENDDO

   // ubaci mi podatke o totalima u polja...
   SELECT exp_bank
   SET ORDER TO TAG "1"
   GO TOP

   DO WHILE !Eof()

      hRec := dbf_get_rec()
      hRec[ "tot_izn" ] := nTotal
      hRec[ "tot_st" ] := _count

      dbf_update_rec( hRec )

      SKIP

   ENDDO

   GO TOP

   ::export_total := nTotal
   ::export_count := _count

   _ok := .T.

   RETURN _ok





// -----------------------------------------------------------
// vraca liniju koja ce sluziti kao makro za odsjecanje i prikaz
// teksta
// -----------------------------------------------------------
METHOD VirmExportTxt:get_export_line_macro( var )

   LOCAL _struct

   DO CASE
   CASE var == "i"
      // item line
      _struct := AllTrim( ::formula_params[ "formula" ] )
   CASE var == "h1"
      // header 1
      _struct := AllTrim( ::formula_params[ "head_1" ] )
   CASE var == "h2"
      // header 2
      _struct := AllTrim( ::formula_params[ "head_2" ] )
   CASE var == "f1"
      // footer 1
      _struct := AllTrim( ::formula_params[ "footer_1" ] )
   CASE var == "f2"
      // footer 2
      _struct := AllTrim( ::formula_params[ "footer_2" ] )
   OTHERWISE
      MsgBeep( "macro not defined !" )
      _struct := ""
   ENDCASE

   RETURN _struct



METHOD VirmExportTxt:get_macro_line( var )

   LOCAL cMacro := ""
   LOCAL nI, _curr_struct
   LOCAL cSeparator, cSeparatorFormula
   LOCAL _a_struct

   // kreriraj makro liniju za stavku
   _curr_struct := ::get_export_line_macro( var )

   IF Empty( _curr_struct )
      RETURN cMacro
   ENDIF

   cSeparator := ::export_params[ "separator" ]
   cSeparatorFormula := ::export_params[ "separator_formula" ]
   IF cSeparator == "t" .OR. cSeparator == "T"
      cSeparator := Chr( 9 )
   ENDIF
   _a_struct := TokToNiz( _curr_struct, cSeparatorFormula )

   FOR nI := 1 TO Len( _a_struct )

      IF !Empty( _a_struct[ nI ] )

         IF nI > 1 // plusevi izmedju
            cMacro += " + "
         ENDIF

         cMacro += _a_struct[ nI ] // makro

         IF nI < Len( _a_struct )
            cMacro += ' + "' + cSeparator + '" '
         ENDIF

      ENDIF

   NEXT

   RETURN cMacro




// -----------------------------------------------------------
// pravi txt fajl na osnovu dbf tabele i makro linije
// -----------------------------------------------------------

METHOD VirmExportTxt:create_txt_from_dbf()

   LOCAL _ok := .F.
   LOCAL _output_filename
   LOCAL _output_dir
   LOCAL cLine
   LOCAL _head_1, _head_2
   LOCAL _footer_1, _footer_2
   LOCAL _force_eol

   _output_dir := my_home() + "export" + SLASH

   IF DirChange( _output_dir ) != 0
      MakeDir( _output_dir )
   ENDIF

   _output_filename := _output_dir + AllTrim( ::export_params[ "fajl" ] )  // fajl ide u my_home/export/

   _force_eol := ::formula_params[ "forsiraj_eol" ] == "D"

   SET PRINTER TO ( _output_filename )
   SET PRINTER ON
   SET CONSOLE OFF

   // predji na upis podataka
   SELECT exp_bank
   SET ORDER TO TAG "1"
   GO TOP

   // header 1
   _head_1 := ::get_macro_line( "h1" )

   IF !Empty( _head_1 )
      ?? to_win1250_encoding( hb_StrToUTF8( &( _head_1 ) ), .T. )
      IF _force_eol
         ?
      ENDIF
   ENDIF

   // header 2
   _head_2 := ::get_macro_line( "h2" )

   IF !Empty( _head_2 )
      ?? to_win1250_encoding( hb_StrToUTF8( &( _head_2 ) ), .T. )
      IF _force_eol
         ?
      ENDIF
   ENDIF

   // sada stavke.
   cLine := ::get_macro_line( "i" )

   // predji na upis podataka
   SELECT exp_bank
   SET ORDER TO TAG "1"
   GO TOP

   DO WHILE !Eof()
      // upisi u fajl
      ?? to_win1250_encoding( hb_StrToUTF8( &( cLine ) ), .T. )
      IF _force_eol
         ?
      ENDIF
      SKIP
   ENDDO

   GO TOP

   _footer_1 := ::get_macro_line( "f1" )

   IF !Empty( _footer_1 )
      ?? to_win1250_encoding( hb_StrToUTF8( &( _footer_1 ) ), .T. )
      IF _force_eol
         ?
      ENDIF
   ENDIF

   _footer_2 := ::get_macro_line( "f2" )

   IF !Empty( _footer_2 )
      ?? to_win1250_encoding( hb_StrToUTF8( &( _footer_2 ) ), .T. )
      IF _force_eol
         ?
      ENDIF
   ENDIF

   SET PRINTER TO
   SET PRINTER OFF
   SET CONSOLE ON

   IF File( _output_filename )
      open_folder( _output_dir )
      MsgBeep( "Fajl uspjesno kreiran !" )
      _ok := .T.
   ELSE
      MsgBeep( "Postoji problem sa operacijom kreiranja fajla ?!" )
   ENDIF

   // zatvori tabelu...
   SELECT exp_bank
   USE

   DirChange( my_home() )

   RETURN _ok




// -----------------------------------------------------------
// glavna metoda exporta
// -----------------------------------------------------------

METHOD VirmExportTxt:export()

   LOCAL _ok := .F.

   IF ::export_params == NIL
      MsgBeep( "Prekidam operaciju exporta !" )
      RETURN _ok
   ENDIF

   ::create_export_dbf() // kreiraj tabelu exporta

   IF ! ::fill_data_from_virm() // napuni je podacima iz obračuna
      MsgBeep( "Problem sa eksportom podataka !" )
      RETURN _ok
   ENDIF

   // kreiraj txt fajl na osnovu dbf tabele
   IF ! ::create_txt_from_dbf()
      RETURN _ok
   ENDIF

   _ok := .T.

   RETURN _ok



// -----------------------------------------------------------
// podesenje varijanti exporta
// -----------------------------------------------------------

METHOD VirmExportTxt:export_setup()

   LOCAL _ok := .F.
   LOCAL _x := 1
   LOCAL _id_formula := fetch_metric( "virm_export_banke_tek", my_user(), 1 )
   LOCAL _active, _formula, _filename, _name, cSeparator, cSeparatorFormula
   LOCAL _head_1, _head_2, _footer_1, _footer_2, _force_eol
   LOCAL _write_params

   Box(, 15, 70 )

#ifdef __PLATWORM__DARWIN
   ReadInsert( .T. )
#endif

   @ box_x_koord() + _x, box_y_koord() + 2 SAY "Varijanta eksporta:" GET _id_formula PICT "999"

   READ

   IF LastKey() == K_ESC
      BoxC()
      RETURN _ok
   ENDIF

   ::export_setup_read_params( _id_formula )

   _formula := ::formula_params[ "formula" ]
   _head_1 := ::formula_params[ "head_1" ]
   _head_2 := ::formula_params[ "head_2" ]
   _footer_1 := ::formula_params[ "footer_1" ]
   _footer_2 := ::formula_params[ "footer_2" ]
   _filename := ::formula_params[ "file" ]
   _name := ::formula_params[ "name" ]
   cSeparator := ::formula_params[ "separator" ]
   cSeparatorFormula := ::formula_params[ "separator_formula" ]
   _force_eol := ::formula_params[ "forsiraj_eol" ]

   IF _formula == NIL
      // tek se podesavaju parametri za ovu formulu
      _formula := Space( 1000 )
      _head_1 := _formula
      _head_2 := _formula
      _footer_1 := _formula
      _footer_2 := _formula
      _name := PadR( "XXXXX Banka", 100 )
      _filename := PadR( "", 50 )
      cSeparator := ";"
      cSeparatorFormula := ";"
      _force_eol := "D"
   ELSE
      _formula := PadR( AllTrim( _formula ), 1000 )
      _head_1 := PadR( AllTrim( _head_1 ), 1000 )
      _head_2 := PadR( AllTrim( _head_2 ), 1000 )
      _footer_1 := PadR( AllTrim( _footer_1 ), 1000 )
      _footer_2 := PadR( AllTrim( _footer_2 ), 1000 )
      _name := PadR( AllTrim( _name ), 500 )
      _filename := PadR( AllTrim( _filename ), 500 )
      cSeparator := PadR( cSeparator, 1 )
      cSeparatorFormula := PadR( cSeparatorFormula, 1 )
      _force_eol := PadR( _force_eol, 1 )
   ENDIF

   ++ _x
   ++ _x
   @ box_x_koord() + _x, box_y_koord() + 2 SAY "(*)   Naziv:" GET _name PICT "@S50" VALID !Empty( _name )

   ++ _x
   ++ _x
   @ box_x_koord() + _x, box_y_koord() + 2 SAY "(*)  Zagl.1:" GET _head_1 PICT "@S50" ;
      VALID {|| Empty( _head_1 ) .OR. ::copy_existing_formula( @_head_1, "h1" ) }

   ++ _x
   @ box_x_koord() + _x, box_y_koord() + 2 SAY "(*)  Zagl.2:" GET _head_2 PICT "@S50" ;
      VALID {|| Empty( _head_2 ) .OR. ::copy_existing_formula( @_head_2, "h2" ) }

   ++ _x
   @ box_x_koord() + _x, box_y_koord() + 2 SAY "(*) Formula:" GET _formula PICT "@S50" ;
      VALID {|| !Empty( _formula ) .AND. ::copy_existing_formula( @_formula, "i" ) }

   ++ _x
   @ box_x_koord() + _x, box_y_koord() + 2 SAY "(*)  Podn.1:" GET _footer_1 PICT "@S50" ;
      VALID {|| Empty( _footer_1 ) .OR. ::copy_existing_formula( @_footer_1, "f1" ) }

   ++ _x
   @ box_x_koord() + _x, box_y_koord() + 2 SAY "(*)  Podn.2:" GET _footer_2 PICT "@S50" ;
      VALID {|| Empty( _footer_2 ) .OR. ::copy_existing_formula( @_footer_2, "f2" ) }

   ++ _x
   ++ _x
   @ box_x_koord() + _x, box_y_koord() + 2 SAY "Naziv izlaznog fajla:" GET _filename PICT "@S40"

   ++ _x
   @ box_x_koord() + _x, box_y_koord() + 2 SAY "Separator u izl.fajlu [ ; , . t ]:" GET cSeparator

   ++ _x
   @ box_x_koord() + _x, box_y_koord() + 2 SAY "    Separator formule [ ; , . ]:" GET cSeparatorFormula

   ++ _x
   @ box_x_koord() + _x, box_y_koord() + 2 SAY "     Forsiraj kraj linije (D/N):" GET _force_eol VALID _force_eol $ "DN" PICT "!@"

   READ

   BoxC()

   IF LastKey() == K_ESC
      RETURN _ok
   ENDIF

   // write params

   set_metric( "virm_export_banke_tek", my_user(), _id_formula )

   ::formula_params[ "separator" ] := cSeparator
   ::formula_params[ "separator_formula" ] := cSeparatorFormula
   ::formula_params[ "formula" ] := _formula
   ::formula_params[ "head_1" ] := _head_1
   ::formula_params[ "head_2" ] := _head_2
   ::formula_params[ "footer_1" ] := _footer_1
   ::formula_params[ "footer_2" ] := _footer_2
   ::formula_params[ "file" ] := _filename
   ::formula_params[ "name" ] := _name
   ::formula_params[ "forsiraj_eol" ] := _force_eol

   ::export_setup_write_params( _id_formula )

   RETURN _ok





// -----------------------------------------------------------
// citanje podesenja varijanti
// -----------------------------------------------------------

METHOD VirmExportTxt:export_setup_read_params( id )

   LOCAL _param_name := "virm_export_" + PadL( AllTrim( Str( id ) ), 2, "0" ) + "_"
   LOCAL _ok := .T.

   ::formula_params := hb_Hash()
   ::formula_params[ "name" ] := fetch_metric( _param_name + "name", NIL, NIL )
   ::formula_params[ "file" ] := fetch_metric( _param_name + "file", NIL, NIL )
   ::formula_params[ "formula" ] := fetch_metric( _param_name + "formula", NIL, NIL )
   ::formula_params[ "head_1" ] := fetch_metric( _param_name + "head_1", NIL, NIL )
   ::formula_params[ "head_2" ] := fetch_metric( _param_name + "head_2", NIL, NIL )
   ::formula_params[ "footer_1" ] := fetch_metric( _param_name + "footer_1", NIL, NIL )
   ::formula_params[ "footer_2" ] := fetch_metric( _param_name + "footer_2", NIL, NIL )
   ::formula_params[ "separator" ] := fetch_metric( _param_name + "sep", NIL, NIL )
   ::formula_params[ "separator_formula" ] := fetch_metric( _param_name + "sep_formula", NIL, ";" )
   ::formula_params[ "forsiraj_eol" ] := fetch_metric( _param_name + "force_eol", NIL, NIL )

   RETURN _ok





// -----------------------------------------------------------
// snimanje podesenja varijanti
// -----------------------------------------------------------

METHOD VirmExportTxt:export_setup_write_params( id )

   LOCAL _param_name := "virm_export_" + PadL( AllTrim( Str( id ) ), 2, "0" ) + "_"

   set_metric( _param_name + "name", NIL, AllTrim( ::formula_params[ "name" ] ) )
   set_metric( _param_name + "file", NIL, AllTrim( ::formula_params[ "file" ] ) )
   set_metric( _param_name + "formula", NIL, AllTrim( ::formula_params[ "formula" ] ) )
   set_metric( _param_name + "head_1", NIL, AllTrim( ::formula_params[ "head_1" ] ) )
   set_metric( _param_name + "head_2", NIL, AllTrim( ::formula_params[ "head_2" ] ) )
   set_metric( _param_name + "footer_1", NIL, AllTrim( ::formula_params[ "footer_1" ] ) )
   set_metric( _param_name + "footer_2", NIL, AllTrim( ::formula_params[ "footer_2" ] ) )
   set_metric( _param_name + "sep", NIL, AllTrim( ::formula_params[ "separator" ] ) )
   set_metric( _param_name + "sep_formula", NIL, AllTrim( ::formula_params[ "separator_formula" ] ) )
   set_metric( _param_name + "force_eol", NIL, AllTrim( ::formula_params[ "forsiraj_eol" ] ) )

   RETURN .T.




METHOD VirmExportTxt:get_export_params( id )

   LOCAL _ok := .F.

   IF id == 0
      id := ::get_export_list()
   ENDIF

   IF id == 0
      MsgBeep( "Potrebno izabrati neku od varijanti !" )
      RETURN _ok
   ENDIF

   ::export_setup_read_params( id )

   if ::formula_params[ "name" ] == NIL .OR. Empty( ::formula_params[ "name" ]  )
      MsgBeep( "Za ovu varijantu ne postoji podesenje !!!#Ukucajte 0 da bi odabrali iz liste." )
   ELSE
      _ok := .T.
   ENDIF

   RETURN _ok






METHOD VirmExportTxt:get_export_list()

   LOCAL _id := 0
   LOCAL nI
   LOCAL _param_name := "virm_export_"
   LOCAL aOpc, aOpcExe, nIzbor := 1
   LOCAL _m_x := box_x_koord()
   LOCAL _m_y := box_y_koord()

   aOpc := {}
   aOpcExe := {}

   FOR nI := 1 TO 20

      ::export_setup_read_params( nI )

      if ::formula_params[ "name" ] <> NIL .AND. !Empty( ::formula_params[ "name" ] )

         _tmp := ""
         _tmp += PadL( AllTrim( Str( nI ) ) + ".", 4 )
         _tmp += PadR( ::formula_params[ "name" ], 40 )

         AAdd( aOpc, _tmp )
         AAdd( aOpcExe, {|| "" } )

      ENDIF

   NEXT

   DO WHILE .T. .AND. LastKey() != K_ESC
      nIzbor := meni_0( "choice", aOpc, NIL, nIzbor, .F. )
      IF nIzbor == 0
         EXIT
      ELSE
         _id := Val( Left ( aOpc[ nIzbor ], 3 ) )
         nIzbor := 0
      ENDIF
   ENDDO

   box_x_koord( _m_x )
   box_y_koord( _m_y )

   RETURN _id




FUNCTION virm_export_banke()

   LOCAL aOpc := {}
   LOCAL aOpcExe := {}
   LOCAL nIzbor := 1

   AAdd( aOpc, "1. export podataka za banku                " )
   AAdd( aOpcExe, {|| virm_export_txt_banka()  } )
   AAdd( aOpc, "2. postavke formula exporta   " )
   AAdd( aOpcExe, {|| virm_export_txt_setup()  } )
   AAdd( aOpc, "3. dupliciranje postojecih postavaki " )
   AAdd( aOpcExe, {|| VirmExportTxt():New():export_setup_duplicate()  } )

   f18_menu( "el", .F., nIzbor, aOpc, aOpcExe )

   RETURN





FUNCTION virm_export_txt_banka( params )

   LOCAL oExp

   oExp := VirmExportTxt():New()

   // u slucaju da nismo setovali parametre, pozovi ih
   IF params == NIL
      oExp:params()
   ENDIF

   oExp:export()

   RETURN .T.



FUNCTION virm_export_txt_setup()

   LOCAL oExp

   oExp := VirmExportTxt():New()
   oExp:export_setup()

   RETURN .T.
