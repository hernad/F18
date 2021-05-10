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


MEMVAR _kome_zr, _ko_zr, _dat_upl, _svrha_doz, _mjesto // ove vars moraju biti public


FUNCTION unos_virmana()

   LOCAL i

   o_virm_tabele_unos_print()

   ImeKol := {}
   Kol := {}

   // _st_ - stavke markirane kao odštampane(*)/neodštampane
   AAdd( ImeKol, { "R.br.", {|| virm_pripr->_st_ + Str( virm_pripr->rbr, 3 ) } } )
   AAdd( ImeKol, { _u( "Pošaljioc ŽR" ), {|| virm_pripr->ko_zr },   "ko_zr" } )
   AAdd( ImeKol, { _u( "Primalac br ŽR" ), {|| virm_pripr->kome_zr }, "kome_zr" } )
   AAdd( ImeKol, { _u( "ŽR Opis" ), {|| Left( virm_pripr->kome_txt, 30 ) } } )
   AAdd( ImeKol, { "Iznos", {|| virm_pripr->Iznos }, "Iznos" } )
   AAdd( ImeKol, { "Dat.Upl", {|| virm_pripr->dat_upl }, "dat_upl" } )
   AAdd( ImeKol, { "POd", {|| virm_pripr->POd }, "POd" } )
   AAdd( ImeKol, { "PDo", {|| virm_pripr->PDo }, "PDo" } )
   AAdd( ImeKol, { "PNABR", {|| virm_pripr->PNABR }, "PNABR" } )
   AAdd( ImeKol, { "Hitno", {|| virm_pripr->Hitno }, "Hitno" } )
   AAdd( ImeKol, { "IdJPrih", {|| virm_pripr->IdJprih }, "IdJPrih" } )
   AAdd( ImeKol, { "VUPl", {|| virm_pripr->VUPl }, "VUPl" } )
   AAdd( ImeKol, { "IdOps", {|| virm_pripr->IdOps }, "IdOps" } )
   AAdd( ImeKol, { PadR( "Pos.opis", 30 ), {|| virm_pripr->ko_txt }, "ko_txt" } )
   AAdd( ImeKol, { PadR( "Prim.opis", 30 ), {|| virm_pripr->kome_txt }, "kome_txt" } )
   AAdd( ImeKol, { "IznosSTR", {|| virm_pripr->IznosSTR }, "Iznos S" } )

   FOR i := 1 TO Len( ImeKol )
      AAdd( Kol, i )
   NEXT

   @ 12, 0 SAY ""

   my_browse( "PripVir", f18_max_rows() - 10, f18_max_cols() - 12, {|| virm_browse_key_handler() }, "", "Priprema virmana", ;
      .F., { "<c-N>   Nova uplatnica", "<c-T>   Brisi ", ;
      "<Enter> Ispravi uplatnicu", "<c-F9>  Brisi sve", ;
      "<c-P>   Stampanje", ;
      "<a-P>   (R)ekapitulacija" }, 2,,, )

   my_close_all_dbf()

   RETURN .T.


STATIC FUNCTION virm_edit_pripr( fNovi )

   LOCAL _firma := PadR( fetch_metric( "virm_org_id", NIL, "" ), 6 )

   SET CURSOR ON

   @ box_x_koord() + 1, box_y_koord() + 2 SAY8 "Svrha plaćanja :" GET _svrha_pl PICT "@!" VALID P_Vrprim( @_svrha_pl )

   READ

   ESC_RETURN 0

   IF fNovi
      IF Empty( gDatum )
         IF gIDU == "D"
            _dat_upl := Date()  // gdatum
         ELSE
            _dat_upl := gdatum
         ENDIF
      ELSE
         _dat_upl := gdatum
      ENDIF
      _mjesto := gmjesto
      _svrha_doz := PadR( vrprim->pom_txt, Len( _svrha_doz ) )
   ENDIF

   @ box_x_koord() + 2, box_y_koord() + Col() + 2 SAY "R.br:" GET _Rbr PICT "999"

   _IdBanka := Left( _ko_zr, 3 )
   @ box_x_koord() + 3, box_y_koord() + 2 SAY8 "Pošiljaoc (sifra banke):       " GET _IdBanka VALID virm_odredi_ziro_racun( _firma, @_IdBanka )
   READ
   ESC_RETURN 0
   _ko_zr := _IdBanka
   _IdBanka2 := Left( _KOME_ZR, 3 )

   select_o_partner( _firma )

   SELECT virm_pripr
   _ko_txt := Trim( partn->naz ) + ", " + Trim( partn->mjesto ) + ", " + Trim( partn->adresa ) + ", " + Trim( partn->telefon )

   IF vrprim->IdPartner == PadR( "JP", Len( vrprim->idpartner ) )
      _bpo := gOrgJed // ova varijabla je iskoristena za broj poreskog obv.
   ELSE
      IF vrprim->dobav == "D" // ako su javni prihodi ovo se zna !
         @ box_x_koord() + 5, box_y_koord() + 2 SAY "Primaoc (partner/banka):" GET _u_korist VALID p_partner( @_u_korist )  PICT "@!"
         @ box_x_koord() + 5, Col() + 2 GET _IdBanka2 VALID {|| virm_odredi_ziro_racun( _u_korist, @_IdBanka2 ), SetPrimaoc() }
      ELSE
         _kome_txt := vrprim->naz
         _KOME_ZR := vrprim->racun
         @ box_x_koord() + 5, box_y_koord() + 2 SAY "Primaoc (partner/banka):" + Trim( _kome_txt )
      ENDIF

   ENDIF


   // na osnovu _IdBanka , _IdBanka2 odrediti racune !!

   @ box_x_koord() + 8, box_y_koord() + 2 SAY "Svrha doznake:" GET _svrha_doz  PICT "@S30"

   @ box_x_koord() + 10, box_y_koord() + 2 SAY "Mjesto" GET _mjesto  PICT "@S20"
   @ box_x_koord() + 10, Col() + 2 SAY "Datum uplate :" GET _dat_upl


   @ box_x_koord() + 8, box_y_koord() + 50 SAY "Iznos" GET _iznos PICT "99999999.99"
   @ box_x_koord() + 8, box_y_koord() + Col() + 1 SAY "Hitno" GET _hitno PICT "@!" VALID _hitno $ " X"

   READ

   ESC_RETURN 0

   _IznosSTR := iznos_virman( _iznos )


   IF vrprim->Idpartner = "JP" // javni prihod

      _vupl := "0"

      // setovanje varijabli: _KOME_ZR , _kome_txt, _budzorg
      // pretpostavke: kursor VRPRIM-> podesen na tekuce primanje
      set_jprih_globalne_varijable_kome_zr_budzorg_idjprih_idops()

      _kome_txt := vrprim->naz

      @ box_x_koord() + 5, box_y_koord() + 2 SAY "Primaoc (partner/banka):" + Trim( _kome_txt )

      IF fnovi

         IF Len( _IdJPrih ) < 6
            MsgBeep( "Sifra prihoda mora biti 6 cifara ?" )
            _IdJPrih := PadR( _IdJPrih, 6 )
         ENDIF
      ENDIF

      @ box_x_koord() + 13, box_y_koord() + 20 SAY Replicate( "-", 56 )

      @ box_x_koord() + 14, box_y_koord() + 20 SAY "Broj por.obveznika" GET _bpo
      @ box_x_koord() + 14, Col() + 2 SAY "V.uplate " GET _VUpl
      @ box_x_koord() + 14, Col() + 2 SAY8 "ŽR: " GET _kome_zr

      @ box_x_koord() + 15, box_y_koord() + 20 SAY "Vrsta prihoda     " GET _IdJPrih

      @ box_x_koord() + 17, box_y_koord() + 20 SAY8 "      Općina      " GET _IdOps
      @ box_x_koord() + 15, box_y_koord() + 60 SAY "Od:" GET _POd
      @ box_x_koord() + 16, box_y_koord() + 60 SAY "Do:" GET _PDo
      @ box_x_koord() + 17, box_y_koord() + 55 SAY "Budz.org" GET _BudzOrg
      @ box_x_koord() + 18, box_y_koord() + 20 SAY "Poziv na broj:    " GET _PNaBr

      READ

      ESC_RETURN 0

   ELSE

      @ box_x_koord() + 13,  box_y_koord() + 20 SAY Replicate( "", 56 )

      _BPO := Space( Len( _BPO ) )
      _IdOps := Space( Len( _IdOps ) )
      _IdJPrih := Space( Len( _IdJPrih ) )
      _BudzOrg := Space( Len( _BudzOrg ) )
      _PNabr := Space( Len( _PNaBr ) )
      _IdOps := Space( Len( _IdOps ) )
      _POd := CToD( "" )
      _PDo := CToD( "" )
      _VUPL = ""

   ENDIF

   RETURN 1


STATIC FUNCTION virm_browse_key_handler()

   LOCAL nRec := RecNo()

   IF ( Ch == K_CTRL_T .OR. Ch == K_ENTER ) .AND. reccount2() == 0
      RETURN DE_CONT
   ENDIF

   SELECT virm_pripr

   DO CASE

   CASE Ch == K_ALT_P .OR. Upper( Chr( Ch ) ) == "R"

      _rekapitulacija_uplata()
      GO ( nRec )
      RETURN DE_CONT

   CASE Ch == K_ALT_M
      cDN := " "
      Box(, 2, 70 )
      @ box_x_koord() + 1, box_y_koord() + 2 SAY8 "Želite sve stavke označiti odštampane/neodštampane ( /*) ?" ;
         GET  cDN VALID cdn $ " *" PICT "@!"
      READ
      BoxC()
      SELECT virm_pripr
      GO TOP
      DO WHILE !Eof()
         REPLACE _ST_ WITH cDN
         SKIP
      ENDDO
      GO TOP
      RETURN DE_REFRESH

   CASE Chr( Ch ) $ "eE"

      virm_export_banke()

      RETURN DE_CONT

   CASE Ch == Asc( " " )
      // ako je _ST_ = " " onda stavku treba odstampati
      // _ST_ = "*" onda stavku ne treba stampati
      my_rlock()
      IF field->_ST_ =  "*"
         REPLACE _st_ WITH  " "
      ELSE
         REPLACE _st_ WITH "*"
      ENDIF
      my_unlock()
      RETURN DE_REFRESH

   CASE Ch == K_CTRL_T
      RETURN browse_brisi_stavku()

   CASE Ch == K_CTRL_P
      stampa_virmana()
      RETURN DE_REFRESH

   CASE Ch == K_CTRL_A
      PushWA()
      SELECT virm_pripr
      // go top
      Box( "c_A", 20, 75, .F., "Ispravka stavki" )
      nDug := 0; nPot := 0
      DO WHILE !Eof()
         skip; nTR2 := RecNo(); SKIP - 1
         Scatter()
         @ box_x_koord() + 1, box_y_koord() + 1 CLEAR TO box_x_koord() + 19, box_y_koord() + 74
         IF virm_edit_pripr( .F. ) == 0
            EXIT
         ELSE
            // BrisiPBaze()
         ENDIF
         SELECT virm_pripr
         my_rlock()
         Gather()
         my_unlock()

         GO nTR2
      ENDDO
      PopWA()
      BoxC()
      RETURN DE_REFRESH

   CASE Ch == K_CTRL_N

      // nove stavke

      nDug := 0
      nPot := 0
      nPrvi := 0

      GO BOTTOM

      Box( "c-N", f18_max_rows() - 11, f18_max_cols() - 5, .F., "Unos novih stavki" )

      DO WHILE .T.

         Scatter()
         _rbr := _rbr + 1
         @ box_x_koord() + 1, box_y_koord() + 1 CLEAR TO box_x_koord() + ( f18_max_rows() - 12 ), box_y_koord() + ( f18_max_cols() - 5 )
         IF virm_edit_pripr( .T. ) == 0
            EXIT
         ENDIF
         Inkey( 10 )
         SELECT virm_pripr
         APPEND BLANK
         my_rlock()
         Gather()
         my_unlock()
      ENDDO

      BoxC()
      RETURN DE_REFRESH

   CASE Ch == K_ENTER

      Box( "ent", f18_max_rows() - 11, f18_max_cols() - 5, .F. )

      Scatter()
      IF virm_edit_pripr( .F. ) == 0
         BoxC()
         RETURN DE_CONT
      ELSE
         SELECT virm_pripr
         my_rlock()  // snimiti unos
         Gather()
         my_unlock()

         BoxC()
         RETURN DE_REFRESH
      ENDIF

   CASE Ch == k_ctrl_f9()
      RETURN browse_brisi_pripremu()

   ENDCASE

   RETURN DE_CONT





FUNCTION SetPrimaoc()

   _KOME_ZR := _idbanka2

   select_o_partner( _u_korist )

   // --- Uslov za ispis adrese u polju primaoca (MUP ZE-DO)
   IF my_get_from_ini( "Primaoc", "UnosAdrese", "N", KUMPATH ) == "D"
      _kome_txt := AllTrim( naz ) + ", " + AllTrim( mjesto ) + ", " + AllTrim( adresa )
   ELSE
      _kome_txt := AllTrim( naz ) + ", " + AllTrim( mjesto )
   ENDIF

   SELECT virm_pripr

   RETURN .T.



FUNCTION UplDob()

   LOCAL lVrati := .F.

   SELECT VRPRIM
   GO TOP
   HSEEK _svrha_pl
   IF dobav == "D"; lVrati := .T. ; ENDIF
   SELECT virm_pripr

   RETURN lVrati




FUNCTION IniProm()        // autom.popunjavanje nekih podataka

   SELECT VRPRIM
   IF dobav == "D"
      IF Empty( _nacpl ) .AND. Empty( _iznos ) .AND. Empty( _svrha_doz )
         _svrha_doz := PadR( pom_txt, Len( _svrha_doz ) )
         _nacpl := nacin_pl
      ENDIF
      select_o_partner( _u_korist )

      _kome_txt := Trim( naz ) + mjesto
      // _KOME_ZR := virm_odredi_ziro_racun(_u_korist,_KOME_ZR)

   ELSE
      _u_korist := Space( Len( _u_korist ) )
      IF Empty( _nacpl ) .AND. Empty( _iznos ) .AND. Empty( _svrha_doz )

         _svrha_doz := PadR( pom_txt, Len( _svrha_doz ) )
         _kome_txt := naz
         // _nacpl:=nacin_pl
         // _kome_sj:=SPACE(LEN(_kome_sj))

      ENDIF
   ENDIF
   SELECT virm_pripr

   RETURN .T.



FUNCTION ValPl()

   LOCAL lVrati := .F.

   IF _nacpl $ "12"
      lVrati := .T.
      IF Empty( _u_korist )
         _KOME_ZR := VRPRIM->racun
      ELSE
         _KOME_ZR := iif( _nacpl == "1", PARTN->ziror, PARTN->dziror )
      ENDIF
   ENDIF

   RETURN lVrati





FUNCTION virm_odredi_ziro_racun( cIdPartn, cDefault, fSilent )

   LOCAL nX, nY, i
   LOCAL Izbor, nTIzbor
   PRIVATE aBanke
   PRIVATE GetList := {}

   IF fsilent = NIL
      fsilent := .T.
   ENDIF

   nX := box_x_koord()
   nY := box_y_koord()

   IF cDefault = NIL
      cDefault := "??FFFX"
   ENDIF

   aBanke := array_from_sifv( "PARTN", "BANK", cIdPartn )

   PushWA()

   SELECT banke
   nTIzbor := 1

   FOR i := 1 TO Len( aBanke )

      IF Left( aBanke[ i ], Len( cDefault ) ) = cDefault
         nTIzbor := i
         IF fSilent
            cDefault := Left( aBanke[ nTIzbor ], 16 )
            PopWA()
            RETURN .T.
         ENDIF
      ENDIF

      SEEK ( Left( aBanke[ i ], 3 ) )

      aBanke[ i ] := PadR( Trim( aBanke[ i ] ) + ":" + PadR( naz, 20 ), 50 )

   NEXT

   PopWa()

   SELECT virm_pripr

   izbor := nTIzbor

   IF Len( aBanke ) > 1  // ako ima vise banaka
      IF !fSilent
         MsgBeep( "Partner " + cIdPartn + " ima racune kod vise banaka, odaberite banku." )
      ENDIF

      PRIVATE h[ Len( aBanke ) ]

      AFill( h, "" )

      DO WHILE .T.

         izbor := meni_0( "ab-1", aBanke, izbor, .F., "1" )

         IF izbor = 0
            EXIT
         ELSE
            nTIzbor := izbor
            izbor := 0
         ENDIF

      ENDDO

      izbor := nTIzbor

      box_x_koord( nX )
      box_y_koord( nY )

   ELSEIF Len( aBanke ) == 1

      cDefault := Left( aBanke[ izbor ], 16 )       // ako je jedna banka
      RETURN .T.

   ELSE

      // potrazi ga u partn->ziror
      cDefault := ""
      select_o_partner( cIdpartn )

      cDefault := partn->ziror

      IF !Empty( cDefault )
         RETURN .T.
      ELSE
         MsgBeep( "Nema unesena niti jedna banka za partnera: '" + cIdPartn + "'" )
         cDefault := ""
         RETURN .T.
      ENDIF

   ENDIF

   cDefault := Left( aBanke[ izbor ], 16 )

   RETURN .T.





// ----------------------------------------
// rekapitulacija uplata
// ----------------------------------------
STATIC FUNCTION _rekapitulacija_uplata()

   LOCAL _arr := {}

   SELECT virm_pripr

   PushWA()

   START PRINT RET
   ?
   P_COND

   _arr := { ;
      { "PRIMALAC", {|| kome_txt }, .F., "C", 55, 0, 1, 1 }, ;
      { "ŽIRO RACUN", {|| kome_zr }, .F., "C", 16, 0, 1, 2 }, ;
      { "IZNOS      ", {|| iznos }, .T., "N", 15, 2, 1, 3 } ;
      }
   GO TOP

   print_lista_2( _arr, , 2, gTabela, {|| .T. }, "4", "REKAPITULACIJA UPLATA", {|| .T. } )

   ENDPRINT

   O_VIRM_PRIPR

   PopWA()

   RETURN .T.


STATIC FUNCTION FormNum1( nIznos )

   LOCAL cVrati

   cVrati := Transform( nIznos, gpici )
   cVrati := StrTran( cVrati, ".", ":" )
   cVrati := StrTran( cVrati, ",", "." )
   cVrati := StrTran( cVrati, ":", "," )

   RETURN cVrati



FUNCTION o_virm_tabele_unos_print()

  // o_sifk()
//   o_sifv()
   o_jprih()
   o_banke()
   o_vrprim()
//   select_o_partner()
   select_o_virm_pripr()

   RETURN .T.



FUNCTION virm_o_tables_razmjena()

   o_banke()
   select_o_jprih()

   o_kred()

   select_o_rekld()
  // select_o_partner()

   o_ldvirm()

   select_o_virm_pripr()

   RETURN .T.
