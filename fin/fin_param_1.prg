
/*
 * This file is part of the bring.out FMK, a free and open source
 * accounting software suite,
 * Copyright (c) 1994-2024 by bring.out d.o.o Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including knowhow ERP specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_knowhow.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */

#include "f18.ch"

STATIC __fin_params := NIL

// -----------------------------------
// meni parametara
// -----------------------------------
FUNCTION mnu_fin_params()

   LOCAL _opc := {}
   LOCAL _opcexe := {}
   LOCAL _izbor := 1

   fin_read_params()

   AAdd( _opc, "1. osnovni parametri                        " )
   AAdd( _opcexe, {|| parametri_organizacije() } )
   AAdd( _opc, "2. parametri rada " )
   AAdd( _opcexe, {|| fin_parametri_obrade_naloga() } )
   AAdd( _opc, "3. parametri izgleda " )
   AAdd( _opcexe, {|| fin_parametri_izgleda() } )

   f18_menu( "fin_param", .F., _izbor, _opc, _opcexe )

   RETURN .T.




STATIC FUNCTION fin_parametri_obrade_naloga()

   LOCAL nX := 1
   LOCAL _k1 := fin_k1(), _k2 := fin_k2(), _k3 := fin_k3(), _k4 := fin_k4()
   LOCAL _tip_dok := fin_tip_dokumenta()
   LOCAL cKontoLike := PADR( param_otvorene_stavke_kupci_konto_like(), 10 )


   LOCAL GetList := {}

   Box(, 24, 70 )

   set_cursor_on()

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "*********************** Unos naloga:"

   nX := nX + 2

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Unos datuma naloga? (D/N):" GET gDatNal VALID gDatNal $ "DN" PICT "@!"

   @ box_x_koord() + nX, Col() + 2 SAY "Unos datuma valute? (D/N):" GET gDatVal VALID gDatVal $ "DN" PICT "@!"
   ++nX

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Unos radnih jedinica ? (D/N)" GET gFinRj VALID gFinRj $ "DN" PICT "@!"
   @ box_x_koord() + nX, Col() + 1 SAY "Unos tipa dokumenta ? (D/N)" GET _tip_dok VALID _tip_dok $ "DN" PICT "@!"
   ++nX

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Unos ekonomskih kategorija? (D/N)" GET gFinFunkFond VALID gFinFunkFond $ "DN" PICT "@!"
   ++nX

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Unos polja K1 - K4 ? (D/N)"
   ++nX
   read_dn_parametar( "K1", box_x_koord() + nX, box_y_koord() + 2, @_k1 )
   read_dn_parametar( "K2", box_x_koord() + nX, Col() + 2, @_k2 )
   read_dn_parametar( "K3", box_x_koord() + nX, Col() + 2, @_k3 )
   read_dn_parametar( "K4", box_x_koord() + nX, Col() + 2, @_k4 )

   nX := nX + 2
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Brojac naloga: 1 - (firma,vn,brnal), 2 - (firma,brnal)" GET gBrojacFinNaloga VALID gBrojacFinNaloga $ "12"

   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Limit za unos konta? (D/N):" GET gKtoLimit PICT "@!" VALID gKtoLimit $ "DN"

   @ box_x_koord() + nX, Col() + 2 SAY "-> vrijednost limita:" GET gnKtoLimit PICT "9" WHEN gKtoLimit == "D"


   nX := nX + 2

   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "********************** Obrada naloga:"

   nX := nX + 2
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Neophodna ravoteža naloga? (D/N):" GET gRavnot VALID gRavnot $ "DN" PICT "@!"

   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Onemogućiti povrat azuriranog naloga u pripremu? (D/N)" GET gBezVracanja VALID gBezVracanja $ "DN" PICT "@!"

   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2  SAY8 "Limit za otvorene stavke (" + valuta_domaca_skraceni_naziv() + ")" GET gnLOst PICT "99999.99"

   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Otvorene stavke, konta za koja se brišu markeri:" GET cKontoLike

   // ++ nX
   // @ box_x_koord() + nX, box_y_koord() + 2 SAY "Koristiti konta-izuzetke u FIN-BUDZET-u? (D/N)" GET gBuIz VALID gBuIz $ "DN" PICT "@!"

   //++nX
   //@ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Timeout kod ažuriranja naloga (sec.):"  GET gAzurTimeout PICT "99999"

   nX := nX + 2
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "********************** Ostalo:"

   nX := nX + 2
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Automatski pozovi kontrolu zbira datoteke svakih" GET gnKZBDana PICT "999" VALID ( gnKZBDana <= 999 .AND. gnKZBDana >= 0 )

   @ box_x_koord() + nX, Col() + 1 SAY "dana"

   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Prikaz stanja konta kod knjiženja naloga" GET g_knjiz_help PICT "@!" ;
      VALID g_knjiz_help $ "DN"


   READ

   BoxC()

   IF LastKey() <> K_ESC

      fin_write_params()
      fin_k1( _k1 )
      fin_k2( _k2 )
      fin_k3( _k3 )
      fin_k4( _k4 )
      fin_tip_dokumenta( _tip_dok )
      param_otvorene_stavke_kupci_konto_like( Trim( cKontoLike ) )

   ENDIF

   RETURN .T.



STATIC FUNCTION fin_parametri_izgleda()

   LOCAL nX := 1
   LOCAL cJednoValutno := fetch_metric( "fin_izvjestaji_jednovalutno", NIL, "1" )
   LOCAL cPicEuro := pic_iznos_eur()
   LOCAL GetList := {}

   Box(, 15, 70 )

   set_cursor_on()

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "*************** Varijante izgleda i prikaza:"

   nX := nX + 2
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Potpis na kraju naloga? (D/N):" GET gPotpis VALID gPotpis $ "DN"  PICT "@!"

   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Varijanta izvještaja 0-dvovalutno 1-jednovalutno " GET cJednoValutno VALID cJednoValutno $ "01"

   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Prikaz iznosa u " + ValPomocna() GET cPicEuro

   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Prikaz iznosa u " + valuta_domaca_skraceni_naziv() GET gPicBHD

   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Sintetika i analitika se kreiraju u izvještajima? (D/N)" GET gSAKrIz VALID gSAKrIz $ "DN" PICT "@!"

   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "U subanalitici prikazati nazive i konta i partnera? (D/N)" GET gVSubOp VALID gVSubOp $ "DN" PICTURE "@!"


   //++nX
   //@ box_x_koord() + nX, box_y_koord() + 2 SAY "Dugi uslov za firmu i RJ u suban.specif.? (D/N)" GET gDugiUslovFirmaRJFinSpecif VALID gDugiUslovFirmaRJFinSpecif $ "DN" PICT "@!"

   READ
   BoxC()

   IF LastKey() <> K_ESC
      set_metric( "fin_izvjestaji_jednovalutno", NIL, cJednoValutno )
      pic_iznos_eur( cPicEuro )
      fin_write_params()
   ENDIF

   RETURN .T.



FUNCTION fin_read_params()

   gDatval := fetch_metric( "fin_evidencija_datum_valute", NIL, gDatVal )
   gDatnal := fetch_metric( "fin_evidencija_datum_naloga", NIL, gDatNal )
   gFinRj := fetch_metric( "fin_evidencija_radne_jedinice", NIL, gFinRj )
   gFinFunkFond := fetch_metric( "fin_evidencija_ekonomske_kategorije", NIL, gFinFunkFond )
   gRavnot := fetch_metric( "fin_unos_ravnoteza_naloga", NIL, gRavnot )
   gBrojacFinNaloga := fetch_metric( "fin_vrsta_brojaca_naloga", NIL, gBrojacFinNaloga )
   gnLOst := fetch_metric( "fin_limit_otvorene_stavke", NIL, gnLOst )
   //gDugiUslovFirmaRJFinSpecif := fetch_metric( "fin_dugi_uslov_za_rj", NIL, gDugiUslovFirmaRJFinSpecif )
   gBezVracanja := fetch_metric( "fin_zabrana_povrata_naloga", NIL, gBezVracanja )
   // gBuIz := fetch_metric( "fin_budzet_konta_izuzeci", nil, gBuIz )


   gPicBHD := fetch_metric( "fin_picbhd", NIL, gPicBHD )

   gSaKrIz := fetch_metric( "fin_kreiranje_sintetike", NIL, gSaKrIz )
   gVSubOp := fetch_metric( "fin_subanalitika_prikaz_naziv_konto_partner", NIL, gVSubOp )
   gAzurTimeOut := fetch_metric( "fin_azuriranje_timeout", NIL, gAzurTimeOut )

   // po user-u parametri
   gPotpis := fetch_metric( "fin_potpis_na_kraju_naloga", my_user(), gPotpis )
   gnKZBDana := fetch_metric( "fin_automatska_kontrola_zbira", my_user(), gnKZBDana )
   gnLMONI := fetch_metric( "fin_kosuljice_lijeva_margina", my_user(), gnLMONI )
   gKtoLimit := fetch_metric( "fin_unos_limit_konto", my_user(), gKtoLimit )
   gnKtoLimit := fetch_metric( "fin_unos_limit_konto_iznos", my_user(), gnKtoLimit )
   g_knjiz_help := fetch_metric( "fin_pomoc_sa_unosom", my_user(), g_knjiz_help )

   fin_params( .T. )

   RETURN .T.

FUNCTION fin_jednovalutno()
   RETURN fetch_metric( "fin_izvjestaji_jednovalutno", NIL, "1" ) == "1"

FUNCTION fin_dvovalutno()
   RETURN !fin_jednovalutno()



FUNCTION fin_write_params()

   set_metric( "fin_evidencija_datum_valute", NIL, gDatVal )
   set_metric( "fin_evidencija_datum_naloga", NIL, gDatNal )
   set_metric( "fin_evidencija_radne_jedinice", NIL, gFinRj )
   set_metric( "fin_evidencija_ekonomske_kategorije", NIL, gFinFunkFond )
   set_metric( "fin_unos_ravnoteza_naloga", NIL, gRavnot )
   set_metric( "fin_vrsta_brojaca_naloga", NIL, gBrojacFinNaloga )
   set_metric( "fin_limit_otvorene_stavke", NIL, gnLOst )
   //set_metric( "fin_dugi_uslov_za_rj", NIL, gDugiUslovFirmaRJFinSpecif )
   set_metric( "fin_zabrana_povrata_naloga", NIL, gBezVracanja )
   // set_metric( "fin_budzet_konta_izuzeci", nil, gBuIz )

   set_metric( "fin_picbhd", NIL, gPicBHD )
   set_metric( "fin_kreiranje_sintetike", NIL, gSaKrIz )
   set_metric( "fin_subanalitika_prikaz_naziv_konto_partner", NIL, gVSubOp )
   set_metric( "fin_azuriranje_timeout", NIL, gAzurTimeOut )

   // po user-u
   set_metric( "fin_unos_limit_konto", my_user(), gKtoLimit )
   set_metric( "fin_unos_limit_konto_iznos", my_user(), gnKtoLimit )
   set_metric( "fin_automatska_kontrola_zbira", my_user(), gnKZBDana )
   set_metric( "fin_potpis_na_kraju_naloga", my_user(), gPotpis )
   set_metric( "fin_kosuljice_lijeva_margina", my_user(), gnLMONI )
   set_metric( "fin_pomoc_sa_unosom", my_user(), g_knjiz_help )

   RETURN .T.



FUNCTION fin_params( READ )

   IF READ == NIL
      READ := .F.
   ENDIF


   IF READ .OR. __fin_params == NIL

      __fin_params := hb_Hash()
      __fin_params[ "fin_k1" ] := iif( fin_k1() == "D", .T., .F. )
      __fin_params[ "fin_k2" ] := iif( fin_k2() == "D", .T., .F. )
      __fin_params[ "fin_k3" ] := iif( fin_k3() == "D", .T., .F. )
      __fin_params[ "fin_k4" ] := iif( fin_k4() == "D", .T., .F. )
      __fin_params[ "fin_tip_dokumenta" ] := iif( fin_tip_dokumenta() == "D", .T., .F. )

   ENDIF

   RETURN __fin_params



// ----------------------------------------------
// k1, k2, k3, k4
// ----------------------------------------------
FUNCTION fin_k1( value )

   get_set_global_param( "fin_unos_k1", value, "N" )

FUNCTION fin_k2( value )

   get_set_global_param( "fin_unos_k2", value, "N" )

FUNCTION fin_k3( value )

   get_set_global_param( "fin_unos_k3", value, "N" )

FUNCTION fin_k4( value )

   get_set_global_param( "fin_unos_k4", value, "N" )

FUNCTION fin_tip_dokumenta( value )

   get_set_global_param( "fin_unos_naloga_tip_dokumenta", value, "N" )
