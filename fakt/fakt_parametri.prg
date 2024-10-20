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

STATIC s_hFaktParams := NIL



FUNCTION fakt_params_meni()

   LOCAL nIzbor := 1
   LOCAL aOpc := {}
   LOCAL aOpcExe := {}

   PRIVATE cSection := "1"
   PRIVATE cHistory := " "
   PRIVATE aHistory := {}

   // o_roba()
   // o_params()
   // SELECT params
   // USE


   AAdd( aOpc, "1. postaviti osnovne podatke o firmi           " )
   AAdd( aOpcExe, {|| parametri_organizacije() } )

   AAdd( aOpc, "2. postaviti varijante obrade dokumenata       " )
   AAdd( aOpcExe, {|| fakt_par_varijante_prikaza() } )

   AAdd( aOpc, "3. izgled dokumenata      " )
   AAdd( aOpcExe, {|| par_fakt_izgled_dokumenta() } )


   AAdd( aOpc, "4. izgled dokumenata - zaglavlje " )
   AAdd( aOpcExe, {|| fakt_zagl_params() } )


   AAdd( aOpc, "5. nazivi dokumenata i teksta na kraju (potpis)" )
   AAdd( aOpcExe, {|| fakt_par_nazivi_dokumenata() } )

   AAdd( aOpc, "6. prikaza cijena, iznos " )
   AAdd( aOpcExe, {|| fakt_par_cijene() } )

   AAdd( aOpc, "F. fiskalni parametri  " )
   AAdd( aOpcExe, {|| fiskalni_parametri_za_korisnika() } )

   AAdd( aOpc, "P. parametri labeliranja, barkod stampe  " )
   AAdd( aOpcExe, {|| label_params() } )

   AAdd( aOpc, "R. postaviti parametre - razno                 " )
   AAdd( aOpcExe, {|| fakt_par_razno() } )


   f18_menu( "fpar", .F., nIzbor, aOpc, aOpcExe )


   fakt_params( .T. )

   RETURN NIL


// -------------------------------------------------------------
// postavi parametre unosa fakt_dokumenta
// -------------------------------------------------------------
PROCEDURE fakt_params( lRead )

   IF lRead == NIL
      lRead = .F.
   ENDIF

   IF lRead .OR. s_hFaktParams == NIL

      s_hFaktParams := hb_Hash()

      // TODO: prebaciti na get_set sistem
      s_hFaktParams[ "def_rj" ] := fetch_metric( "fakt_default_radna_jedinica", my_user(), Space( 2 ) )
      s_hFaktParams[ "barkod" ] := fetch_metric( "fakt_prikaz_barkod", my_user(), "0" )

      // TODO: ugasiti ovaj globalni parametar
      IF destinacije() == "D"
         s_hFaktParams[ "destinacije" ] := .T.
      ELSE
         s_hFaktParams[ "destinacije" ] := .F.
      ENDIF

      s_hFaktParams[ "fakt_dok_veze" ] := iif( fakt_dok_veze() == "D", .T., .F. )
      s_hFaktParams[ "fakt_opis_stavke" ] := iif( fakt_opis_stavke() == "D", .T., .F. )
      s_hFaktParams[ "fakt_prodajna_mjesta" ] := iif( fakt_prodajna_mjesta() == "D", .T., .F. )
      s_hFaktParams[ "ref_lot" ] := iif( ref_lot() == "D", .T., .F. )
      s_hFaktParams[ "fakt_vrste_placanja" ] := iif( fakt_vrste_placanja() == "D", .T., .F. )
      s_hFaktParams[ "fakt_objekti" ] := iif( fakt_objekti() == "D", .T., .F. )
      s_hFaktParams[ "fakt_otpr_22_brojac" ] := iif( fakt_otpr_22_brojac() == "D", .T., .F. )
      s_hFaktParams[ "fakt_otpr_gen" ] := iif( fakt_otpr_gen() == "D", .T., .F. )
      s_hFaktParams[ "kontrola_brojaca" ] := iif( fakt_kontrola_brojaca_par() == "D", .T., .F. )

   ENDIF

   RETURN s_hFaktParams



// ------------------------------------------
// setuju parametre pri pokretanju modula
// napuni sifrarnike
// ------------------------------------------
FUNCTION fakt_set_params()

   PUBLIC gPtxtC50 := .T.  // PTXT 01.50 compatibility switch

   fill_part()

   RETURN .T.


/*
 *     Podesenja parametri-razno
 */
FUNCTION fakt_par_razno()

   LOCAL _def_rj := fetch_metric( "fakt_default_radna_jedinica", my_user(), Space( 2 ) )
   LOCAL _prik_bk := fetch_metric( "fakt_prikaz_barkod", my_user(), "0" )
   LOCAL _ext_pdf := fetch_metric( "fakt_dokument_pdf_lokacija", my_user(), PadR( "", 300 ) )
   LOCAL cUnosBarKodDN := fetch_metric( "fakt_unos_artikala_po_barkodu", my_user(), "N" )
   LOCAL _pm := fakt_prodajna_mjesta()
   LOCAL _rabat := fetch_metric( "pregled_rabata_kod_izlaza", my_user(), "N" )
   LOCAL _racun_na_email := PadR( fetch_metric( "fakt_dokument_na_email", my_user(), "" ), 300 )
   LOCAL _def_vp_template := PadR( fetch_metric( "fakt_default_odt_template", my_user(), "" ), 20 )
   LOCAL _def_mp_template := PadR( fetch_metric( "fakt_default_odt_mp_template", my_user(), "" ), 20 )
   LOCAL _def_kol_template := PadR( fetch_metric( "fakt_default_odt_kol_template", my_user(), "" ), 20 )
   LOCAL nX := 1
   LOCAL _unos_ref_lot := ref_lot()
   LOCAL _unos_opisa := fakt_opis_stavke()
   LOCAL _unos_objekta := fakt_objekti()
   LOCAL cFaktVrstePlacanja := fakt_vrste_placanja()
   LOCAL _unos_dest := destinacije()
   LOCAL _unos_br_veza := fakt_dok_veze()
   LOCAL _otpr_brojac_22 := fakt_otpr_22_brojac()
   LOCAL _otpr_gen := fakt_otpr_gen()
   LOCAL _kontrola_brojaca := fakt_kontrola_brojaca_par()
   LOCAL nRokPlDana := fakt_rok_placanja_dana()
   PRIVATE GetList := {} // ne diraj read_dn_parametar trazi da je GetList privatna var
   PRIVATE cSection := "1"
   PRIVATE cHistory := " "
   PRIVATE aHistory := {}

   o_params()

   gKomLin := PadR( gKomLin, 70 )

   Box(, f18_max_rows() - 5, f18_max_cols() - 15, .F., "OSTALI PARAMETRI (RAZNO)" )

   nX := 2
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Fakt tekući dokument (1-9)" GET gIMenu VALID gIMenu $ "123456789" PICT "@!"
   nX += 2
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Tekuća radna jedinica kod unosa dokumenta:" GET _def_rj
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Unos dokumenata pomoću barkod-a (D/N) ?" GET cUnosBarKodDN VALID cUnosBarKodDN $ "DN" PICT "@!"
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Pregled zadnjih izlaza kod unosa dokumenta (D/N) ?" GET _rabat VALID _rabat $ "DN" PICT "@!"
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Dužina sifre artikla sintetički " GET gnDS VALID gnDS > 0 PICT "9"
   // ++nX
   // @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Voditi samo količine " GET gSamoKol PICT "@!" VALID gSamoKol $ "DN"
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Tekuća vrijednost za rok placanja  " GET nRokPlDana PICT "999"
   ++nX
   // @ box_x_koord() + nX, box_y_koord() + 2 SAY "Uvijek resetuj artikal pri unosu dokumenata (D/N)" GET gResetRoba PICT "@!" VALID gResetRoba $ "DN"
   // ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Prikaz barkod-a na fakturi (0/1/2)" GET _prik_bk VALID _prik_bk $ "012"

   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Račun na email:" GET _racun_na_email PICT "@S50"
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "LibreOffice fakturu konvertuj u PDF na lokaciju:" GET _ext_pdf PICT "@S35"

   nX += 2
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "   Uzorak fakture (VP):" GET _def_vp_template PICT "@S35"
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "   Uzorak fakture (MP):" GET _def_mp_template PICT "@S35"
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "     Uzorak otpremnice:" GET _def_kol_template PICT "@S35"

   nX += 2
   read_dn_parametar( "Praćenje po destinacijama", box_x_koord() + nX, box_y_koord() + 2, @_unos_dest )
   ++nX
   read_dn_parametar( "Unos brojeva veze", box_x_koord() + nX, box_y_koord() + 2, @_unos_br_veza )
   ++nX
   read_dn_parametar( "Fakturisanje po prodajnim mjestima", box_x_koord() + nX, box_y_koord() + 2, @_pm )
   ++nX
   read_dn_parametar( "Fakturisanje po objektima", box_x_koord() + nX, box_y_koord() + 2, @_unos_objekta )
   ++nX
   read_dn_parametar( "Fakturisanje po vrstama placanja", box_x_koord() + nX, box_y_koord() + 2, @cFaktVrstePlacanja )
   ++nX
   read_dn_parametar( "Fakt dodatni opis po stavkama", box_x_koord() + nX, box_y_koord() + 2, @_unos_opisa )
   ++nX
   read_dn_parametar( "REF/LOT brojevi", box_x_koord() + nX, box_y_koord() + 2, @_unos_ref_lot )
   ++nX
   read_dn_parametar( "Brojač otpremnica po dokumentu 22 (D/N)", box_x_koord() + nX, box_y_koord() + 2, @_otpr_brojac_22 )
   ++nX
   read_dn_parametar( "Generacija otpremnica ver.2 (D/N)", box_x_koord() + nX, box_y_koord() + 2, @_otpr_gen )
   ++nX
   read_dn_parametar( "Kontrola brojača dokumenta (D/N)", box_x_koord() + nX, box_y_koord() + 2, @_kontrola_brojaca )
   ++nX

   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Ispis računa MP na traku (D/N/X)" GET gMPPrint  PICT "@!"   VALID gMPPrint $ "DNXT"

   READ

   IF gMPPrint $ "DXT"

      ++nX
      @ box_x_koord() + nX, box_y_koord() + 2 SAY "Oznaka lokalnog porta za stampu: LPT" GET gMPLocPort VALID gMPLocPort $ "1234567" PICT "@!"
      ++nX
      @ box_x_koord() + nX, box_y_koord() + 2 SAY "Redukcija trake (0/1/2):" GET gMPRedTraka VALID gMPRedTraka $ "012"
      ++nX
      @ box_x_koord() + nX, box_y_koord() + 2 SAY "Ispis id artikla na racunu (D/N):"  GET gMPArtikal VALID gMPArtikal $ "DN" PICT "@!"
      ++nX
      @ box_x_koord() + nX, box_y_koord() + 2 SAY "Ispis cjene sa pdv (2) ili bez (1):" GET gMPCjenPDV  VALID gMPCjenPDV $ "12"
      READ

   ENDIF

   BoxC()

   gKomLin := Trim( gKomLin )

   IF LastKey() <> K_ESC

      // set_metric( "fakt_voditi_samo_kolicine", NIL, gSamoKol )
      set_metric( "fakt_rok_placanja_tekuca_vrijednost", my_user(), nRokPlDana )
      // set_metric( "fakt_reset_artikla_na_unosu", my_user(), gResetRoba )
      set_metric( "fakt_meni_tekuci", my_user(), gIMenu )
      set_metric( "fakt_default_radna_jedinica", my_user(), _def_rj )
      set_metric( "fakt_prikaz_barkod", my_user(), _prik_bk )
      set_metric( "fakt_dokument_pdf_lokacija", my_user(), _ext_pdf )
      set_metric( "fakt_unos_artikala_po_barkodu", my_user(), cUnosBarKodDN )
      set_metric( "pregled_rabata_kod_izlaza", my_user(), _rabat )
      set_metric( "fakt_dokument_na_email", my_user(), AllTrim( _racun_na_email ) )
      set_metric( "fakt_default_odt_template", my_user(), AllTrim( _def_vp_template ) )
      set_metric( "fakt_default_odt_mp_template", my_user(), AllTrim( _def_mp_template ) )
      set_metric( "fakt_default_odt_kol_template", my_user(), AllTrim( _def_kol_template ) )

      destinacije( _unos_dest )
      fakt_opis_stavke( _unos_opisa )
      fakt_objekti( _unos_objekta )
      ref_lot( _unos_ref_lot )
      fakt_prodajna_mjesta( _pm )
      fakt_vrste_placanja( cFaktVrstePlacanja )
      fakt_dok_veze( _unos_br_veza )
      fakt_otpr_22_brojac( _otpr_brojac_22 )
      fakt_otpr_gen( _otpr_gen )
      fakt_kontrola_brojaca_par( _kontrola_brojaca )

      // setuj mi default odt template ako treba
      __default_odt_template()

      Wpar( "NF", gFNar )
      Wpar( "UF", gFUgRab )
      Wpar( "ds", gnDS )
      WPar( "if", gImeF )
      WPar( "95", gKomLin )
      //WPar( "Fi", @gIspPart )
      WPar( "mP", gMpPrint )
      WPar( "mL", gMpLocPort )
      WPar( "mT", gMpRedTraka )
      WPar( "mA", gMpArtikal )
      WPar( "mC", gMpCjenPDV )

   ENDIF

   RETURN .T.



FUNCTION fakt_zagl_params()

   LOCAL nSay := 17
   LOCAL sPict := "@S55"
   LOCAL nX := 1
   LOCAL GetList := {}

   PRIVATE cSection := "1"
   PRIVATE cHistory := " "
   PRIVATE aHistory := {}

   gFNaziv := PadR( gFNaziv, 250 )
   gFPNaziv := PadR( gFPNaziv, 250 )
   gFIdBroj := PadR( gFIdBroj, 13 )
   gFText1 := PadR( gFText1, 72 )
   gFText2 := PadR( gFText2, 72 )
   gFText3 := PadR( gFText3, 72 )
   gFTelefon := PadR( gFTelefon, 72 )
   gFEmailWeb := PadR( gFEmailWeb, 72 )

   Box( , 21, 77, .F., "Izgleda dokumenata - zaglavlje" )

   // opci podaci
   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "Puni naziv firme:", nSay ) GET gFNaziv  PICT sPict
   nX++

   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "Dodatni opis:", nSay ) GET gFPNaziv  PICT sPict
   nX++

   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "Adresa firme:", nSay ) GET gFAdresa PICT sPict
   nX++

   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "Ident.broj:", nSay ) GET gFIdBroj
   nX++

   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "Telefoni:", nSay ) GET gFTelefon  PICT sPict
   nX++

   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "email/web:", nSay ) GET gFEmailWeb PICT sPict
   nX++

   // banke
   @ box_x_koord() + nX,  box_y_koord() + 2 SAY PadL( "Banka 1:", nSay ) GET gFBanka1 PICT sPict
   nX++

   @ box_x_koord() + nX,  box_y_koord() + 2 SAY PadL( "Banka 2:", nSay ) GET gFBanka2 PICT sPict
   nX++

   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "Banka 3:", nSay ) GET gFBanka3 PICT sPict
   nX++

   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "Banka 4:", nSay ) GET gFBanka4 PICT sPict
   nX++

   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "Banka 5:", nSay ) GET gFBanka5 PICT sPict
   nX += 2

   // dodatni redovi
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Proizvoljan sadrzaj na kraju"
   nX++

   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "Red 1:", nSay ) GET gFText1 PICT sPict
   nX++


   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "Red 2:", nSay ) GET gFText2 PICT sPict
   nX++

   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "Red 3:", nSay ) GET gFText3 PICT sPict
   nX += 2

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Koristiti tekstualno zaglavlje (D/N)?" GET gStZagl  VALID gStZagl $ "DN" PICT "@!"
   nX += 2

   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "Slika na vrhu fakture (redova):", nSay + 15 ) GET gFPicHRow PICT "99"

   nX += 1
   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "Slika na dnu fakture (redova):", nSay + 15 ) GET gFPicFRow PICT "99"
   READ

   BoxC()

   IF ( LastKey() <> K_ESC )
      set_metric( "org_naziv", NIL, gFNaziv )
      set_metric( "org_naziv_dodatno", NIL, gFPNaziv )
      set_metric( "org_adresa", NIL, gFAdresa )
      set_metric( "org_pdv_broj", NIL, gFIdBroj )
      set_metric( "fakt_zagl_banka_1", NIL, gFBanka1 )
      set_metric( "fakt_zagl_banka_2", NIL, gFBanka2 )
      set_metric( "fakt_zagl_banka_3", NIL, gFBanka3 )
      set_metric( "fakt_zagl_banka_4", NIL, gFBanka4 )
      set_metric( "fakt_zagl_banka_5", NIL, gFBanka5 )
      set_metric( "fakt_zagl_telefon", NIL, gFTelefon )
      set_metric( "fakt_zagl_email", NIL, gFEmailWeb )
      set_metric( "fakt_zagl_dtxt_1", NIL, gFText1 )
      set_metric( "fakt_zagl_dtxt_2", NIL, gFText2 )
      set_metric( "fakt_zagl_dtxt_3", NIL, gFText3 )
      set_metric( "fakt_zagl_koristiti_txt", NIL, gStZagl )
      set_metric( "fakt_zagl_pic_header", NIL, gFPicHRow )
      set_metric( "fakt_zagl_pic_footer", NIL, gFPicFRow )
   ENDIF

   RETURN .T.



FUNCTION fakt_par_cijene()

   LOCAL nX
   LOCAL cCijena := fakt_pic_cijena()
   LOCAL cIznos := fakt_pic_iznos()
   LOCAL cKolicina := fakt_pic_kolicina()
   LOCAL GetList := {}

   fakt_pic_kolicina( StrTran( fakt_pic_kolicina(), "@Z ", "" ) )

   nX := 1
   Box(, 6, 60, .F., "PARAMETRI PRIKAZA" )

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Prikaz cijene   " GET cCijena
   nX++

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Prikaz iznosa   " GET cIznos
   nX++

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Prikaz kolicine " GET cKolicina
   nX++

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Na kraju fakture izvrsiti zaokruzenje" GET gFZaok PICT "99"
   nX++

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Zaokruzenje 5 pf (D/N)?" GET gZ_5pf PICT "@!" VALID gZ_5pf $ "DN"

   READ

   BoxC()

   IF ( LastKey() <> K_ESC )

      fakt_pic_cijena( cCijena )
      fakt_pic_iznos( cIznos )
      fakt_pic_kolicina( cKolicina )
      set_metric( "fakt_zaokruzenje", NIL, gFZaok )
      set_metric( "fakt_zaokruzenje_5_pf", NIL, gZ_5pf )

   ENDIF

   RETURN .T.



FUNCTION fakt_par_varijante_prikaza()

   LOCAL GetList := {}

   o_params()

   Box(, 23, 76, .F., "VARIJANTE OBRADE DOKUMENATA" )
   @ box_x_koord() + 1, box_y_koord() + 2 SAY8 "Unos Dat.pl, otpr., narudzbe D/N (1/2) ?" GET gDoDPar VALID gDodPar $ "12" PICT "@!"
   @ box_x_koord() + 1, box_y_koord() + 46 SAY8 "Dat.pl.u svim v.f.9 (D/N)?" GET gDatVal VALID gDatVal $ "DN" PICT "@!"
   @ box_x_koord() + 2, box_y_koord() + 2 SAY8 "Generacija ulaza prilikom izlaza 13" GET gProtu13 VALID gProtu13 $ "DN" PICT "@!"
   @ box_x_koord() + 4, box_y_koord() + 2 SAY8 "Maloprod.cijena za 13-ku ( /1/2/3/4/5/6)   " GET g13dcij VALID g13dcij $ " 123456"
   @ box_x_koord() + 5, box_y_koord() + 2 SAY8 "Varijanta dokumenta 13 (1/2)   " GET gVar13 VALID gVar13 $ "12"
   @ box_x_koord() + 6, box_y_koord() + 2 SAY8 "Varijanta numeracije dokumenta 13 (1/2)   " GET gVarNum VALID gVarNum $ "12"
   @ box_x_koord() + 7, box_y_koord() + 2 SAY8 "Pratiti trenutnu količinu D/N ?" GET gFaktPratitiKolicinuDN PICT "@!" VALID gFaktPratitiKolicinuDN $ "DN"
   @ box_x_koord() + 7, Col() + 1 SAY "Pratiti cijene na unosu D/N ?" GET gPratiC PICT "@!" VALID gPratiC $ "DN"
   @ box_x_koord() + 8, box_y_koord() + 2 SAY  "Koristenje VP cijene:"
   @ box_x_koord() + 9, box_y_koord() + 2 SAY  "  ( ) samo VPC   (X) koristiti samo MPC    (1) VPC1/VPC2 "
   @ box_x_koord() + 10, box_y_koord() + 2 SAY "  (2) VPC1/VPC2 putem rabata u odnosu na VPC1   (3) NC "
   @ box_x_koord() + 11, box_y_koord() + 2 SAY "  (4) Uporedo vidi i MPC............" GET gVarC
   @ box_x_koord() + 12, box_y_koord() + 2 SAY "U fakturi maloprodaje koristiti:"
   @ box_x_koord() + 13, box_y_koord() + 2 SAY "  (1) MPC iz sifrarnika  (2) VPC + PPP + PPU   (3) MPC2 "
   @ box_x_koord() + 14, box_y_koord() + 2 SAY "  (4) MPC3  (5) MPC4  (6) MPC5  (7) MPC6 ....." GET gMP VALID gMP $ "1234567"
   @ box_x_koord() + 15, box_y_koord() + 2 SAY "Numericki dio broja dokumenta:" GET gNumDio PICT "99"
   @ box_x_koord() + 16, box_y_koord() + 2 SAY "Upozorenje na promjenu radne jedinice:" GET gDetPromRj PICT "@!" VALID gDetPromRj $ "DN"
   @ box_x_koord() + 17, box_y_koord() + 2 SAY "Var.otpr.-12 sa porezom :" GET gV12Por PICT "@!" VALID gV12Por $ "DN"
   @ box_x_koord() + 17, box_y_koord() + 35 SAY "Var.fakt.po ugovorima (1/2) :" GET gVFU PICT "9" VALID gVFU $ "12"
   @ box_x_koord() + 18, box_y_koord() + 2 SAY "Var.fakt.rok plac. samo vece od 0 :" GET gVFRP0 PICT "@!" VALID gVFRP0 $ "DN"
   @ box_x_koord() + 20, box_y_koord() + 2 SAY "Prikaz samo kolicina na dokumentima (0/D/N)" GET gPSamoKol PICT "@!" VALID gPSamoKol $ "0DN"

   @ box_x_koord() + 22, box_y_koord() + 2 SAY "Koristiti rabat iz sif.robe (polje N1) ?" GET gRabIzRobe PICT "@!" VALID gRabIzRobe $ "DN"
   @ box_x_koord() + 23, box_y_koord() + 2 SAY "Brisi direktno u smece" GET gcF9usmece PICT "@!" VALID gcF9usmece $ "DN"
   @ box_x_koord() + 23, Col() + 2 SAY "Timeout kod azuriranja" GET gAzurTimeout PICT "9999"

   READ

   BoxC()

   IF ( LastKey() <> K_ESC )

      set_metric( "fakt_datum_placanja_otpremnica", NIL, gDoDPar )
      set_metric( "fakt_datum_placanja_svi_dokumenti", NIL, gDatVal )
      set_metric( "fakt_numericki_dio_dokumenta", NIL, gNumDio )
      set_metric( "fakt_prikaz_samo_kolicine", NIL, gPSamoKol )
      set_metric( "fakt_povrat_u_smece", NIL, gcF9usmece )
      set_metric( "fakt_varijanta_dokumenta_13", NIL, gVar13 )

      WPar( "pd", gProtu13 )
      WPar( "dc", g13dcij )
      WPar( "vn", gVarNum )
      WPar( "pk", gFaktPratitiKolicinuDN )
      WPar( "pc", gPratiC )
      WPar( "50", gVarC )
      WPar( "mp", gMP )
      WPar( "PR", gDetPromRj )
      WPar( "vp", gV12Por )
      WPar( "vu", gVFU )
      WPar( "v0", gVFRP0 )
      WPar( "g1", gKarC1 )
      WPar( "g2", gKarC2 )
      WPar( "g3", gKarC3 )
      WPar( "g4", gKarN1 )
      WPar( "g5", gKarN2 )

      WPar( "rR", gRabIzRobe )
      WPar( "Fz", gAzurTimeout )

   ENDIF

   RETURN .T.


FUNCTION is_fakt_pratiti_kolicinu()
   RETURN gFaktPratitiKolicinuDN == "D"

FUNCTION par_fakt_izgled_dokumenta()

   LOCAL nX
   LOCAL nDx1 := 0
   LOCAL nDx2 := 0
   LOCAL nDx3 := 0
   LOCAL nSw1 := 72
   LOCAL nSw2 := 1
   LOCAL nSw3 := 72
   LOCAL nSw4 := 31
   LOCAL nSw5 := 1
   LOCAL nSw6 := 1
   LOCAL nSw7 := 0
   LOCAL _params := fakt_params()
   LOCAL _auto_odt := fetch_metric( "fakt_odt_template_auto", NIL, "D" )
   LOCAL GetList := {}

   PRIVATE cIzvj := "1"

   o_params()

   IF ValType( gTabela ) <> "N"
      gTabela := 1
   ENDIF

   RPar( "c1", @cIzvj )

   cSection := "F"
   RPar( "x1", @nDx1 )
   RPar( "x2", @nDx2 )
   RPar( "x3", @nDx3 )
   RPar( "x4", @nSw1 )
   RPar( "x5", @nSw2 )
   RPar( "x6", @nSw3 )
   RPar( "x7", @nSw4 )
   RPar( "x8", @nSw5 )
   RPar( "x9", @nSw6 )
   RPar( "y1", @nSw7 )

   cSection := "1"

   nX := 2
   Box( , 22, 76, .F., "Izgled dokumenata" )


   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Dodat.redovi po listu " GET gERedova PICT "999"
   nX++
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Lijeva margina pri stampanju " GET gnLMarg PICT "99"
   nX++

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Gornja margina " GET gnTMarg PICT "99"
   nX++
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Koristi ODT template automatski (D/N) ?" GET _auto_odt VALID _auto_odt $ "DN" PICT "!@"
   nX++
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "PDV Delphi RB prikaz (D/N)" GET gPDVDrb PICT "@!" VALID gPDVDrb $ "DN"
   nX++
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "PDV TXT dokument varijanta " GET gPDVDokVar PICT "@!" VALID gPDVDokVar $ "123"
   nX++

   nX += 2
/*
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Koordinate iznad kupac/ispod kupac/nar_otp-tabela"

   nX++
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "DX-1 :" GET nDx1 ;
      PICT "99"
   @ box_x_koord() + nX, Col() + 2 SAY "DX-2 :" GET nDx2 ;
      PICT "99"
   @ box_x_koord() + nX, Col() + 2 SAY "DX-3 :" GET nDx3 ;
      PICT "99"
   nX += 2
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "SW-1 :" GET nSw1 ;
      PICT "99"
   @ box_x_koord() + nX, Col() + 2 SAY "SW-2 :" GET nSw2 ;
      PICT "99"
   @ box_x_koord() + nX, Col() + 2 SAY "SW-3 :" GET nSw3 ;
      PICT "99"
   @ box_x_koord() + nX, Col() + 2 SAY "SW-4 :" GET nSw4 ;
      PICT "99"
   @ box_x_koord() + nX, Col() + 2 SAY "SW-5 :" GET nSw5 ;
      PICT "99"
   nX += 2
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "SW-6 :" GET nSw6 ;
      PICT "9"
   @ box_x_koord() + nX, Col() + 2 SAY "SW-7 :" GET nSw7 ;
      PICT "9"
   nX += 2
*/

   // parametri fin.stanje na dod.txt
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Ispis grupacije robe poslije naziva (D/N)" GET glRGrPrn PICT "@!" VALID glRGrPrn $ "DN"

   nX += 2
   // parametri fin.stanje na dod.txt
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Prikaz fin.salda kupca/dobavljaca na dodatnom tekstu (D/N)" GET gFaktPrikazFinSaldaKupacDobavljac PICT "@!" VALID gFaktPrikazFinSaldaKupacDobavljac $ "DN"

   nX += 1
   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "Konto duguje:", 20 ) GET gFinKtoDug VALID !Empty( gFinKtoDug ) .AND. P_Konto( @gFinKtoDug ) WHEN gFaktPrikazFinSaldaKupacDobavljac == "D"

   nX += 1
   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "Konto potrazuje:", 20 ) GET gFinKtoPot VALID !Empty( gFinKtoPot ) .AND. P_Konto( @gFinKtoPot ) WHEN gFaktPrikazFinSaldaKupacDobavljac == "D"

   nX += 1
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Varijanta prikaza podataka (1/2)" GET gFaktPrikazFinSaldaKupacDobavljacVar PICT "9" VALID gFaktPrikazFinSaldaKupacDobavljacVar > 0 .AND. gFaktPrikazFinSaldaKupacDobavljacVar < 3 WHEN gFaktPrikazFinSaldaKupacDobavljac == "D"


   READ

   BoxC()

   IF ( LastKey() <> K_ESC )

      WPar( "c1", cIzvj )
      WPar( "tf", @gTipF )
      WPar( "vf", @gVarF )
      WPar( "kr", @gKriz )
      WPar( "55", @gKrizA5 )
      WPar( "vr", @gVarRF )
      WPar( "56", gnLMargA5 )
      WPar( "a5", gFormatA5 )
      WPar( "fp", gFPzag )
      WPar( "51", gFPzagA5 )
      WPar( "52", gnTMarg2A5 )
      WPar( "53", gnTMarg3A5 )
      WPar( "54", gnTMarg4A5 )
      WPar( "d1", gnTMarg2 )
      WPar( "d2", gnTMarg3 )
      WPar( "d3", gnTMarg4 )
      WPar( "cr", gZnPrec )
      WPar( "ot", gOdvT2 )
      WPar( "tb", gTabela )
      WPar( "za", gZagl )
      WPar( "zb", gbold )
      WPar( "RT", gRekTar )
      WPar( "HL", gHLinija )
      WPar( "rp", gRabProc )

      cSection := "F"
      WPar( "x1", nDx1 )
      WPar( "x2", nDx2 )
      WPar( "x3", nDx3 )
      WPar( "x4", nSw1 )
      WPar( "x5", nSw2 )
      WPar( "x6", nSw3 )
      WPar( "x7", nSw4 )
      WPar( "x8", nSw5 )
      WPar( "x9", nSw6 )
      WPar( "y1", nSw7 )

      cSection := "1"

      set_metric( "fakt_odt_template_auto", NIL, _auto_odt )

      set_metric( "fakt_ispis_grupacije_na_dokumentu", NIL, glRGrPrn )
      set_metric( "fakt_ispis_salda_kupca_dobavljaca", NIL, gFaktPrikazFinSaldaKupacDobavljac )
      set_metric( "fakt_ispis_salda_kupca_dobavljaca_varijanta", NIL, gFaktPrikazFinSaldaKupacDobavljacVar )
      set_metric( "konto_duguje", NIL, gFinKtoDug )
      set_metric( "konto_potrazuje", NIL, gFinKtoPot )

      set_metric( "fakt_dokument_dodati_redovi_po_listu", NIL, gERedova )
      set_metric( "fakt_dokument_lijeva_margina", NIL, gnLMarg )
      set_metric( "fakt_dokument_top_margina", NIL, gnTMarg )
      set_metric( "fakt_dokument_delphirb_prikaz", NIL, gPDVDrb )
      set_metric( "fakt_dokument_txt_prikaz_varijanta", NIL, gPDVDokVar )

   ENDIF

   RETURN .T.



FUNCTION fakt_par_nazivi_dokumenata()

   LOCAL GetList := {}

   o_params()

   g10Str := PadR( g10Str, 20 )
   // g16Str := PadR( g16Str, 20 )
   // g06Str := PadR( g06Str, 20 )
   g11Str := PadR( g11Str, 20 )
   g12Str := PadR( g12Str, 20 )
   g13Str := PadR( g13Str, 20 )
   g15Str := PadR( g15Str, 20 )
   g20Str := PadR( g20Str, 20 )
   g21Str := PadR( g21Str, 20 )
   g22Str := PadR( g22Str, 20 )
   g23Str := PadR( g23Str, 20 )
   g25Str := PadR( g25Str, 20 )
   g26Str := PadR( g26Str, 24 )
   g27Str := PadR( g27Str, 20 )

   g10ftxt := PadR( g10ftxt, 100 )
   g11ftxt := PadR( g11ftxt, 100 )
   g12ftxt := PadR( g12ftxt, 100 )
   g13ftxt := PadR( g13ftxt, 100 )
   g15ftxt := PadR( g15ftxt, 100 )
   // g16ftxt := PadR( g16ftxt, 100 )
   g20ftxt := PadR( g20ftxt, 100 )
   g21ftxt := PadR( g21ftxt, 100 )
   g22ftxt := PadR( g22ftxt, 100 )
   g23ftxt := PadR( g23ftxt, 100 )
   g25ftxt := PadR( g25ftxt, 100 )
   g26ftxt := PadR( g26ftxt, 100 )
   g27ftxt := PadR( g27ftxt, 100 )

   g10Str2T := PadR( g10Str2T, 132 )
   // g16Str2T := PadR( g16Str2T, 132 )
   // g06Str2T := PadR( g06Str2T, 132 )
   g11Str2T := PadR( g11Str2T, 132 )
   g15Str2T := PadR( g15Str2T, 132 )
   g12Str2T := PadR( g12Str2T, 132 )
   g13Str2T := PadR( g13Str2T, 132 )
   g20Str2T := PadR( g20Str2T, 132 )
   g21Str2T := PadR( g21Str2T, 132 )
   g22Str2T := PadR( g22Str2T, 132 )
   g23Str2T := PadR( g23Str2T, 132 )
   g25Str2T := PadR( g25Str2T, 132 )
   g26Str2T := PadR( g26Str2T, 132 )
   g27Str2T := PadR( g27Str2T, 132 )
   gNazPotStr := PadR( gNazPotStr, 132 )

   Box(, 22, 76, .F., "Naziv dokumenata, potpis na kraju, str. 1" )
   // @ box_x_koord() + 1, box_y_koord() + 2 SAY "06 - Tekst"      GET g06Str
   // @ box_x_koord() + 2, box_y_koord() + 2 SAY "06 - Potpis TXT" GET g06Str2T PICT"@S50"
   @ box_x_koord() + 4, box_y_koord() + 2 SAY "10 - Tekst"      GET g10Str
   @ box_x_koord() + 4, Col() + 1 SAY "d.txt lista:" GET g10ftxt PICT "@S25"
   @ box_x_koord() + 5, box_y_koord() + 2 SAY "10 - Potpis TXT" GET g10Str2T PICT"@S50"
   @ box_x_koord() + 7, box_y_koord() + 2 SAY "11 - Tekst"      GET g11Str
   @ box_x_koord() + 7, Col() + 1 SAY "d.txt lista:" GET g11ftxt PICT "@S25"
   @ box_x_koord() + 8, box_y_koord() + 2 SAY "11 - Potpis TXT" GET g11Str2T PICT "@S50"
   @ box_x_koord() + 10, box_y_koord() + 2 SAY "12 - Tekst"      GET g12Str
   @ box_x_koord() + 10, Col() + 1 SAY "d.txt lista:" GET g12ftxt PICT "@S25"
   @ box_x_koord() + 11, box_y_koord() + 2 SAY "12 - Potpis TXT" GET g12Str2T PICT "@S50"
   @ box_x_koord() + 13, box_y_koord() + 2 SAY "13 - Tekst"      GET g13Str
   @ box_x_koord() + 13, Col() + 1 SAY "d.txt lista:" GET g13ftxt PICT "@S25"
   @ box_x_koord() + 14, box_y_koord() + 2 SAY "13 - Potpis TXT" GET g13Str2T PICT "@S50"
   @ box_x_koord() + 16, box_y_koord() + 2 SAY "15 - Tekst"      GET g15Str
   @ box_x_koord() + 16, Col() + 1 SAY "d.txt lista:" GET g15ftxt PICT "@S25"
   @ box_x_koord() + 17, box_y_koord() + 2 SAY "15 - Potpis TXT" GET g15Str2T PICT "@S50"
   // @ box_x_koord() + 19, box_y_koord() + 2 SAY "16 - Tekst"      GET g16Str
   // @ box_x_koord() + 19, Col() + 1 SAY "d.txt lista:" GET g16ftxt PICT "@S25"
   // @ box_x_koord() + 20, box_y_koord() + 2 SAY "16 - Potpis TXT" GET g16Str2T PICT"@S50"
   READ
   BoxC()

   Box(, 22, 76, .F., "Naziv dokumenata, potpis na kraju, str. 2" )
   @ box_x_koord() + 1, box_y_koord() + 2 SAY "20 - Tekst"      GET g20Str
   @ box_x_koord() + 1, Col() + 1 SAY "d.txt lista:" GET g20ftxt PICT "@S25"
   @ box_x_koord() + 2, box_y_koord() + 2 SAY "20 - Potpis TXT" GET g20Str2T PICT "@S50"
   @ box_x_koord() + 4, box_y_koord() + 2 SAY "21 - Tekst"      GET g21Str
   @ box_x_koord() + 4, Col() + 1 SAY "d.txt lista:" GET g21ftxt PICT "@S25"
   @ box_x_koord() + 5, box_y_koord() + 2 SAY "21 - Potpis TXT" GET g21Str2T PICT "@S50"
   @ box_x_koord() + 7, box_y_koord() + 2 SAY "22 - Tekst"      GET g22Str
   @ box_x_koord() + 7, Col() + 1 SAY "d.txt lista:" GET g22ftxt PICT "@S25"
   @ box_x_koord() + 8, box_y_koord() + 2 SAY "22 - Potpis TXT" GET g22Str2T PICT"@S50"

   @ box_x_koord() + 10, box_y_koord() + 2 SAY "23 - Tekst"      GET g23Str
   @ box_x_koord() + 10, Col() + 1 SAY "d.txt lista:" GET g23ftxt PICT "@S25"
   @ box_x_koord() + 11, box_y_koord() + 2 SAY "23 - Potpis TXT" GET g23Str2T PICT"@S50"

   @ box_x_koord() + 13, box_y_koord() + 2 SAY "25 - Tekst"      GET g25Str
   @ box_x_koord() + 13, Col() + 1 SAY "d.txt lista:" GET g25ftxt PICT "@S25"
   @ box_x_koord() + 14, box_y_koord() + 2 SAY "25 - Potpis TXT" GET g25Str2T PICT"@S50"
   @ box_x_koord() + 16, box_y_koord() + 2 SAY "26 - Tekst"      GET g26Str
   @ box_x_koord() + 16, Col() + 1 SAY "d.txt lista:" GET g26ftxt PICT "@S25"
   @ box_x_koord() + 17, box_y_koord() + 2 SAY "26 - Potpis TXT" GET g26Str2T PICT"@S50"
   @ box_x_koord() + 19, box_y_koord() + 2 SAY "27 - Tekst"      GET g27Str
   @ box_x_koord() + 19, Col() + 1 SAY "d.txt lista:" GET g27ftxt PICT "@S25"
   @ box_x_koord() + 20, box_y_koord() + 2 SAY "27 - Potpis TXT" GET g27Str2T PICT"@S50"
   @ box_x_koord() + 22, box_y_koord() + 2 SAY "Dodatni red    " GET gNazPotStr PICT"@S50"

   READ
   BoxC()

   IF ( LastKey() <> K_ESC )

      set_metric( "fakt_dokument_dok_10_naziv", NIL, g10Str )
      set_metric( "fakt_dokument_dok_10_potpis", NIL, g10Str2T )
      set_metric( "fakt_dokument_dok_10_txt_lista", NIL, g10ftxt )
      set_metric( "fakt_dokument_dok_11_naziv", NIL, g11Str )
      set_metric( "fakt_dokument_dok_11_potpis", NIL, g11Str2T )
      set_metric( "fakt_dokument_dok_11_txt_lista", NIL, g11ftxt )
      set_metric( "fakt_dokument_dok_12_naziv", NIL, g12Str )
      set_metric( "fakt_dokument_dok_12_potpis", NIL, g12Str2T )
      set_metric( "fakt_dokument_dok_12_txt_lista", NIL, g12ftxt )
      set_metric( "fakt_dokument_dok_13_naziv", NIL, g13Str )
      set_metric( "fakt_dokument_dok_13_potpis", NIL, g13Str2T )
      set_metric( "fakt_dokument_dok_13_txt_lista", NIL, g13ftxt )
      // set_metric( "fakt_dokument_dok_16_naziv", NIL, g16Str )
      // set_metric( "fakt_dokument_dok_16_potpis", NIL, g16Str2T )
      // set_metric( "fakt_dokument_dok_16_txt_lista", NIL, g16ftxt )
      set_metric( "fakt_dokument_dok_20_naziv", NIL, g20Str )
      set_metric( "fakt_dokument_dok_20_potpis", NIL, g20Str2T )
      set_metric( "fakt_dokument_dok_20_txt_lista", NIL, g20ftxt )
      set_metric( "fakt_dokument_dok_22_naziv", NIL, g22Str )
      set_metric( "fakt_dokument_dok_22_potpis", NIL, g22Str2T )
      set_metric( "fakt_dokument_dok_22_txt_lista", NIL, g22ftxt )


      // WPar( "r3", g06Str )
      WPar( "xl", @g15Str )
      WPar( "x9", @g21Str )
      WPar( "xC", @g23Str )
      WPar( "xf", @g25Str )
      WPar( "xi", @g26Str )
      WPar( "xo", @g27Str )

      // WPar( "r4", @g06Str2T )
      WPar( "xm", @g15Str2T )
      WPar( "xa", @g21Str2T )
      WPar( "xD", @g23Str2T )
      WPar( "xg", @g25Str2T )
      WPar( "xj", @g26Str2T )
      WPar( "xp", @g27Str2T )

      WPar( "uc", @gNazPotStr )

      // liste
      WPar( "ye", @g15ftxt )
      WPar( "yh", @g21ftxt )
      WPar( "yI", @g23ftxt )
      WPar( "yj", @g25ftxt )
      WPar( "yk", @g26ftxt )
      WPar( "yl", @g27ftxt )

   ENDIF

   RETURN .T.




// ----------------------------------------------------
// specificne funkcije za fakturisanje uglja
// ----------------------------------------------------
FUNCTION is_fakt_ugalj()
   RETURN .F.


// ----------------------------------------------------------------
// dodatni opis na stavke u fakt dokumentu
// ----------------------------------------------------------------
FUNCTION fakt_opis_stavke( cValue )
   RETURN get_set_global_param( "fakt_opis_stavke", cValue, "N" )


// ----------------------------------------------------------------
// unos objekata
// ----------------------------------------------------------------
FUNCTION fakt_objekti( cValue )
   RETURN get_set_global_param( "fakt_objekti", cValue, "N" )


// ----------------------------------------------------------------
// koriste se REF/LOT oznake
// ----------------------------------------------------------------
FUNCTION ref_lot( cValue )
   RETURN get_set_global_param( "ref_lot", cValue, "N" )


// ----------------------------------------------------------------
// prate se destinacije
// ----------------------------------------------------------------
FUNCTION destinacije( cValue )
   RETURN get_set_global_param( "destinacije", cValue, "N" )

// ----------------------------------------------------------------
// fakturise se po prodajnim mjestima
// ----------------------------------------------------------------
FUNCTION fakt_prodajna_mjesta( cValue )
   RETURN get_set_global_param( "fakt_prodajna_mjesta", cValue, "N" )


// ----------------------------------------------------------------
// fakturise se po prodajnim mjestima
// ----------------------------------------------------------------
FUNCTION fakt_dok_veze( cValue )
   RETURN get_set_global_param( "fakt_dok_veze", cValue, "N" )


// ----------------------------------------------------------------
// fakturise se po vrstama placanja
// ----------------------------------------------------------------
FUNCTION fakt_vrste_placanja( cValue )
   RETURN get_set_global_param( "fakt_unos_vrste_placanja", cValue, "N" )


// ----------------------------------------------------------------
// kada pravis otpremnicu pravi je po brojacu tip-a 22
// ----------------------------------------------------------------
FUNCTION fakt_otpr_22_brojac( cValue )
   RETURN get_set_global_param( "fakt_otpremnice_22_brojac", cValue, "N" )



FUNCTION fakt_otpr_gen( cValue )
   RETURN get_set_global_param( "fakt_otpremnice_gen_v2", cValue, "D" )


FUNCTION fakt_kontrola_brojaca_par( cValue )
   RETURN get_set_global_param( "fakt_kontrola_brojaca_dokumenta", cValue, "N" )
