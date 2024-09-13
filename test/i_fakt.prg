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

STATIC __keystrokes := {}
STATIC __test_vars

// jedan poziv test_keystroke treba samo jednu sekvencu poslati
STATIC __keystroke_step



FUNCTION setup_i_fakt()

   // iskljucimo rnal
   get_set_user_param( "main_menu_rnal", "N" )
   ref_lot( "N" )
   fakt_opis_stavke( "N" )
   fakt_vrste_placanja( "N" )
   destinacije( "N" )

   // procitaj parametre
   fakt_params( .T. )


   // ------------------------------------
   // fakt integracijski testovi
   // ------------------------------------

FUNCTION i_fakt()

   LOCAL _omodul

   setup_i_fakt()

   _omodul := TFaktMod():new( nil, "FAKT", f18_ver(), f18_ver_date(), "test", "test" )


   goModul := _omodul

   // setuj zaglavlje fakture
   i_zaglavlje_fakture()
   // povrat 99-10-77777
   i_povrat_fakture()
   // napravi 99-10-77777 i azuriraj
   i_napravi_fakturu()

FUNCTION i_zaglavlje_fakture()

   LOCAL _stavke

   _stavke := hb_Hash()

   test_var( "ok", .F. )

   _stavke[ 'keys' ] := {}
   _stavke[ 'get' ]  := {}

   AAdd( _stavke[ 'keys' ],  { ;
      "<CTRLT>", "bring.out test", "<ENTER>", ;   // naziv
   "<CTRLT>", "IT knowhow", "<ENTER>", ;
      "<CTRLT>", "Juraja Najtharta 3", "<ENTER>";
      } )
   AAdd( _stavke[ 'get' ], 'GFNAZIV' )


   AAdd( _stavke[ 'keys' ],  { ;
      "<CTRLT>", "218000000006", "<ENTER>" ;   // gFIdBroj
   } )
   AAdd( _stavke[ 'get' ], 'GFIDBROJ' )


   AAdd( _stavke[ 'keys' ],  { ;
      "<CTRLT>", "+387 33 269 291, fax: +387 33269292", "<ENTER>"; // telefon
   } )
   AAdd( _stavke[ 'get' ], 'GFTELEFON' )


   AAdd( _stavke[ 'keys' ],  { ;
      "<CTRLT>", "office@bring.out.ba", "<ENTER>";  // gFEmail
   } )
   AAdd( _stavke[ 'get' ], 'GFEMAIL' )


   AAdd( _stavke[ 'keys' ],  { ;
      "<CTRLT>", "VOLSKBANK 1410000000000001", "<ENTER>"; // banka1
   } )
   AAdd( _stavke[ 'get' ], 'GFBANKA1' )


   AAdd( _stavke[ 'keys' ],  { ;
      "<CTRLT>", "BBI 990000000000001", "<ENTER>", ; // banka2
   "<CTRLT>", "<ENTER>", ;  // banka 3
   "<CTRLT>", "<ENTER>", ;  // banka 4
   "<CTRLT>", "<ENTER>" ;  // banka 5
   } )
   AAdd( _stavke[ 'get' ], 'GFBANKA2' )

   AAdd( _stavke[ 'keys' ],  { ;
      "<CTRLT>", "DR1", "<ENTER>", ; // dodatni tekst 1
   "<CTRLT>", "DR2", "<ENTER>", ;
      "<CTRLT>", "DR3", "<ENTER>", ;
      "<PGDN>" ;
      } )
   AAdd( _stavke[ 'get' ], 'GFTEXT1' )

   test_procedure_with_keystrokes( {|| fakt_zagl_params() },  gen_test_keystrokes( _stavke ) )

   RETURN



FUNCTION i_povrat_fakture()

   LOCAL _tmp, _a_polja, _stavka_dok
   LOCAL _stavke := hb_Hash()

   _stavke[ 'keys' ] := {}
   _stavke[ 'get' ]  := {}

   test_var( "fakt_pov", 0 )


   AAdd( _stavke[ 'keys' ],  { ;
      "99", "<ENTER>", "10", "<ENTER>", "77777", "<ENTER>";
      } )
   AAdd( _stavke[ 'get' ], '_FIRMA' )

   AAdd( _stavke[ 'keys' ],  { ;
      "D", "<ENTER>"  ;
      } )
   AAdd( _stavke[ 'get' ], '#FAKT_POV_DOK' )

   AAdd( _stavke[ 'keys' ],  { ;
      "D", "<ENTER>"  ;
      } )
   AAdd( _stavke[ 'get' ], '#FAKT_POV_KUM' )

   test_procedure_with_keystrokes( {|| povrat_fakt_dokumenta() },  gen_test_keystrokes( _stavke ) )

   CLOSE ALL
  // o_fakt_dbf()
   // rec_99 treba da sadrzi broj zapisa
   COUNT FOR ( IdFirma == "99" .AND. IdTipDok == "10" .AND. brdok == PadR( "77777", 8 ) ) TO _tmp
   // setuj test var rec_99 sa _tmp
   test_var( "fakt_pov", _tmp )

   TEST_LINE( test_var( "fakt_pov" ) == 0,  .T. )

   RETURN .T.



FUNCTION i_napravi_fakturu()

   LOCAL _tmp, _a_polja, _stavka_dok
   LOCAL _stavke := hb_Hash()
   LOCAL _fakt_outf, _fakt_out_odt, _b_print

   // uporedi test/data/fakt_1.txt sa outf.txt koji je izgenerisan
   _fakt_outf := txt_print_file_name()
   _fakt_out_odt := my_home() + OUT_ODT_FILE


   push_test_tag( "XX" )

   _stavke[ 'keys' ] := {}
   _stavke[ 'get' ]  := {}

   test_var( "fakt_77", 0 )


   // brisi sve stavke
   AAdd( _stavke[ 'keys' ],  { "<CTRLF9>" } )
   AAdd( _stavke[ 'get' ], "DBEDIT" )

   AAdd( _stavke[ 'keys' ],  { "D", "<ENTER>" } )
   AAdd( _stavke[ 'get' ], "#FAKT_BRISI_PRIPR" )


   // c-N
   AAdd( _stavke[ 'keys' ],  { ;
      "<CTRLN>" ;
      } )
   AAdd( _stavke[ 'get' ], 'DBEDIT' )

   // dodaj stavku 1

   AAdd( _stavke[ 'keys' ],  { ;
      "99", "<ENTER>2", "31.12.12", "<ENTER>", ;
      "77777", "<ENTER>", "999999", "<ENTER>"  ;
      } )
   // fire keystrokes kada dodjes do _IDFIRMA get polja
   AAdd( _stavke[ 'get' ], '_IDFIRMA' )

   AAdd( _stavke[ 'keys' ],  { ;
      "OTP-111", "<ENTER>", "10.12.12", "<ENTER>", ;
      "NAR-9852", "<ENTER>", "7", "<ENTER>", "07.01.13", "<ENTER>";
      } )
   AAdd( _stavke[ 'get' ], '_BROTP' )


/*
AADD(_stavke['keys'],  {;
     "G ", "<ENTER>";
  })
AADD(_stavke['get'], '_IDVRSTEP')
*/

   AAdd( _stavke[ 'keys' ],  { ;
      "KM", "<ENTER>", ;
      "N",  "<ENTER>" ;  // avansni racun N
   } )
   AAdd( _stavke[ 'get' ], '_DINDEM' )


   AAdd( _stavke[ 'keys' ],  { ;
      "1", "<ENTER>", ;
      "TEST1", "<ENTER>", ;
      "serbr-1", "<ENTER>" ;
      } )
   AAdd( _stavke[ 'get' ], '__REDNI_BROJ' )

   AAdd( _stavke[ 'keys' ],  { ;
      "10.00", "<ENTER>", ; // 10 kom
   "1.00",  "<ENTER>", ; // 1 cijena (ovaj je cijena i u sifarniku)
   "<ENTER>2", ;      // rabat, %rabat nista
      "<ESC>", ;          // text opis nista
      "<ENTER>" ;
      } )
   AAdd( _stavke[ 'get' ], '_KOLICINA' )

   // dodaj stavku 2
   AAdd( _stavke[ 'keys' ],  { ;
      "2", "<ENTER>",;       // rbr stavka 2
      "TEST2", "<ENTER>",  ;
      "serbr-2", "<ENTER>" ;
      } )
   AAdd( _stavke[ 'get' ], '__REDNI_BROJ' )

   AAdd( _stavke[ 'keys' ],  { ;
      "25.00", "<ENTER>", ; // 20 kom
   "2.00",  "<ENTER>", ; // 2 cijena (ovaj je cijena i u sifarniku)
   "<ENTER>2", ;      // rabat, %rabat nista
      "<ENTER>",  ;
      "<ESC>" ;
      } )
   AAdd( _stavke[ 'get' ], '_KOLICINA' )

   // stampa racuna (txt format)
   AAdd( _stavke[ 'keys' ],  { ;
      "<CTRLP>" ;
      } )
   AAdd( _stavke[ 'get' ], 'DBEDIT' )

   // prije slanja "V" izbrisi outf.txt
   AAdd( _stavke[ 'keys' ],  { ;
      {|| FErase( _fakt_outf ) }, "V", "<ENTER>" ;
      } )
   AAdd( _stavke[ 'get' ], 'CDIREKT' )

   AAdd( _stavke[ 'keys' ],  { ;
      {|| TEST_LINE( test_diff_between_files( "fakt_1.txt", _fakt_outf ), 0 ) };
      } )
   AAdd( _stavke[ 'get' ], '#FAKT_CTRLP_END' )


   // stampa racuna (odt format)
   AAdd( _stavke[ 'keys' ],  { ;
      {|| FErase( _fakt_out_odt ) },   "<ALTP>" ;
      } )
   AAdd( _stavke[ 'get' ], 'DBEDIT' )

   // stampa racuna (odt format)
   AAdd( _stavke[ 'keys' ],  { ;
      {|| TEST_LINE( test_diff_between_odt_files( "fakt_1.odt", _fakt_out_odt ), 0 ) };
      } )
   AAdd( _stavke[ 'get' ], '#FAKT_ALTP_END' )

   // azuriraj
   AAdd( _stavke[ 'keys' ],  { ;
      "<ALTA>" ;
      } )
   AAdd( _stavke[ 'get' ], 'DBEDIT' )

   // N - pitanje za azuriranje D  (test_tag)
   AAdd( _stavke[ 'keys' ],  { ;
      "D", "<ENTER>" ;
      } )
   AAdd( _stavke[ 'get' ], '#FAKT_AZUR' )


   // N - pitanje za stampu fiskalnog racuna (test_tag)
   // AADD(_stavke['keys'],  {;
   // "N", "<ENTER>" ;
   // })
   // AADD(_stavke['get'], '#ST_FISK_RN')

   // ESC iz tabele
   AAdd( _stavke[ 'keys' ],  { ;
      "<ESC>" ;
      } )
   AAdd( _stavke[ 'get' ], 'DBEDIT' )

   test_procedure_with_keystrokes( {|| fakt_unos_dokumenta() },  gen_test_keystrokes( _stavke ) )

   CLOSE ALL
  // o_fakt_dbf()
   // rec_99 treba da sadrzi broj zapisa
   COUNT FOR ( IdFirma == "99" .AND. IdTipDok == "10" .AND. brdok == PadR( "77777", 8 ) ) TO _tmp
   // setuj test var rec_99 sa _tmp
   test_var( "fakt_77", _tmp )

   TEST_LINE( test_var( "fakt_77" ) == 2,  .T. )

   RETURN
