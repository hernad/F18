#include "f18.ch"

STATIC s_cKalkAutoImportPodatakaKonto := nil


/*
 *   Brisanje fajla cTxtFile
 *   param: cTxtFile - fajl za brisanje
 */
FUNCTION kalk_imp_brisi_txt( cTxtFile )

   CLEAR TYPEAHEAD
   // postavi pitanje za brisanje fajla
   IF Pitanje(, "Pobrisati txt fajl " + cTxtFile + " (D/N)?", "D" ) == "N"
      RETURN .F.
   ENDIF

   IF FErase( cTxtFile ) == -1
      MsgBeep( "Ne mogu izbrisati " + cTxtFile )
   ENDIF

   RETURN .T.


FUNCTION cre_kalk_priprt()

   // LOCAL cKalkPript := "kalk_pript"

   my_close_all_dbf()

      /*
         FErase( my_home() + cKalkPript + ".dbf" )
         FErase( my_home() + cKalkPript + ".cdx" )

         o_kalk_pripr()

         // napravi pript sa strukturom tabele kalk_pripr
         COPY STRUCTURE EXTENDED to ( my_home() + "struct" )
         CREATE ( my_home() + cKalkPript ) from ( my_home() + "struct" )

         USE

         SELECT ( F_PRIPT )
         my_use_temp( "PRIPT", my_home() + cKalkPript, .F., .T. )

         INDEX on ( idfirma + idvd + brdok ) TAG "1"
         INDEX on ( idfirma + idvd + brdok + idroba ) TAG "2"

         USE
      */
   o_kalk_pript()
   my_dbf_zap()

   RETURN .T.




/*
    *     Obrada importovanih dokumenata pript -> pripr
    *     ( funkcija se koristi i za prenos kalk -> kalk)
    *     lOstaviBrdok - kalk_imprort sa udaljene lokacije koristi brojeve
*/

FUNCTION kalk_imp_obradi_sve_dokumente_iz_pript( nPocniOd, lStampaj, lOstaviBrdok )

   LOCAL dDatVal
   LOCAL cNoviKalkBrDok := ""
   LOCAL nUvecaj := 0
   LOCAL cMKonto, cPKonto
   LOCAL nTekucaWA, nStCnt, cBBTipDok
   LOCAL nPTRec, nPCRec, cBRdok, cFirma, cIdVd
   LOCAL hRec

   o_kalk_pripr()
   o_kalk_pript()

   automatska_obrada_error( .F. )

   IF lStampaj == nil
      lStampaj := .T.
   ENDIF

   IF nPocniOd == nil
      nPocniOd := 0
   ENDIF

   hb_default( @lOstaviBrdok, .F. ) // ostavi broj dokumenta koji se nalazi u pript

   // IF Pitanje(, "Automatski asistent i ažuriranje naloga (D/N)?", "D" ) == "D"
   // s_lAutom := .T.
   // ENDIF


   SELECT pript // iz kalk_pript prebaci u kalk_pripr jednu po jednu kalkulaciju
   SET ORDER TO TAG "1"

   IF nPocniOd == 0
      GO TOP
   ELSE
      GO nPocniOd
   ENDIF


   cBBTipDok := Space( 30 ) // uzmi parametre koje ces dokumente prenositi
   Box(, 3, 70 )
   @ 1 + box_x_koord(), 2 + box_y_koord() SAY "Prenos sljedecih tipova dokumenata ( kalk pript -> pripr) :"
   @ 3 + box_x_koord(), 2 + box_y_koord() SAY "Tip dokumenta (prazno-svi):" GET cBBTipDok PICT "@S25"
   READ
   BoxC()

   IF !Empty( cBBTipDok )
      cBBTipDok := AllTrim( cBBTipDok )
   ENDIF

   // SetKey(K_F3,{|| kalk_imp_set_check_point(nPTRec)})

   Box(, 10, 79 )
   @ 1 + box_x_koord(), 2 + box_y_koord() SAY8 "Obrada dokumenata iz pomoćne tabele:" COLOR f18_color_i()
   @ 2 + box_x_koord(), 2 + box_y_koord() SAY8 "======================================="

   DO WHILE !Eof()

      nPTRec := RecNo()
      nPCRec := nPTRec
      cBrDok := field->brdok
      cFirma := field->idfirma
      cIdVd  := field->idvd
      cPKonto := field->pkonto
      cMKonto := field->mkonto

      IF !Empty( cBBTipDok ) .AND. !( cIdVd $ cBBTipDok )
         SKIP
         LOOP
      ENDIF

      nTekucaWA := Select()

      IF lOstaviBrdok
         cNoviKalkBrDok := cBrDok
         IF !kalk_broj_ima_sufiks( cBrDok )
            MsgBeep( "kalk_import - pript, brojevi dokumenata moraju imati sufiks !## STOP!" )
            RETURN .F.
         ENDIF
      ELSE
         cNoviKalkBrDok := kalk_get_next_broj_v5( cFirma, cIdVd, kalk_konto_za_brojac( cIdVd, cMKonto, cPKonto ) )  // daj konacni novi broj dokumenta kalk
      ENDIF

      SELECT ( nTekucaWA )

      @ 3 + box_x_koord(), 2 + box_y_koord() SAY "KALK IMP Prebacujem: " + cFirma + "-" + cIdVd + "-" + cBrDok + " /"  + cNoviKalkBrDok

      nStCnt := 0
      DO WHILE !Eof() .AND. field->brdok == cBrDok .AND. field->idfirma == cFirma .AND. field->idvd == cIdVd


         SELECT kalk_pripr // jedan po jedan row azuriraj u kalk_pripr
         APPEND BLANK

         SELECT pript
         dDatVal := pript->datval
         hRec := dbf_get_rec()

         SELECT kalk_pripr
         hRec[ "brdok" ] := cNoviKalkBrDok
         hb_HDel( hRec, "datval" ) // datval se posebno azurira u kalk_doks
         dbf_update_rec( hRec )

         IF hRec[ "idvd" ] == "14"
            update_kalk_14_datval( cNoviKalkBrDok, dDatVal )
         ENDIF

         SELECT pript
         SKIP
         ++nStCnt

         nPTRec := RecNo()

         @ 5 + box_x_koord(), 13 + box_y_koord() SAY Space( 5 )
         @ 5 + box_x_koord(), 2 + box_y_koord() SAY "Broj stavki:" + AllTrim( Str( nStCnt ) )
      ENDDO


      // IF s_lAutom // nakon što smo prebacili dokument u kalk_pripremu oznaciti dokle smo stigli

      IF automatska_obrada_error()
         MsgBeep( "prekid operacije importa - greške u automatskoj obradi!" )
         BoxC()
         RETURN .F.
      ENDIF

      kalk_imp_set_check_point( nPCRec ) // snimi zapis u params da znas dokle si dosao
      IF kalk_imp_obradi_dokument_u_pripremi( cIdVd, lStampaj )
         kalk_imp_set_check_point( nPTRec )
      ELSE
         MsgBeep( "prekid operacije importa !" )
         BoxC()
         RETURN .F.
      ENDIF
      o_kalk_pript()
      // ENDIF

      SELECT pript
      GO nPTRec

   ENDDO

   BoxC()

   IF automatska_obrada_error()
      RETURN .F.
   ENDIF

   RETURN .T.


/*
       *  Obrada jednog dokumenta
       *  param cIdVd - id vrsta dokumenta
*/

STATIC FUNCTION kalk_imp_obradi_dokument_u_pripremi( cIdVd, lStampaj )

   LOCAL nRslt, lPrvi := .T.

   IF lStampaj == nil
      lStampaj := .T.
   ENDIF

   // kalk_pripr_obrada_stavki_sa_asistentom()

   // IF lStampaj == .T.
   // kalk_stampa_dokumenta( nil, nil, .T. ) // odstampaj kalk
   // ENDIF
   // kalk_azuriranje_dokumenta( .T. ) // azuriraj kalk
   // o_kalk_edit()

   kalk_asistent_pause( .F. )

   DO WHILE (  ( nRslt := provjeri_stanje_kalk_pripreme( cIdVd ) ) <> 0 )

      IF lPrvi .OR. ( nRslt == 1 ) // vezni dokument u kalk_pripremi je ok
         IF !kalk_pripr_auto_obrada_i_azuriranje( lStampaj )
            RETURN .F.
         ENDIF
      ENDIF

      IF lPrvi
         lPrvi := .F.
         LOOP
      ENDIF

      IF  nRslt >= 2 // vezni dokument u pripremi ne pripada azuriranom dokumentu, sta sa njim

         error_bar( "kalk_auto_imp", "postoji dokument u pripremi koji je sumnjiv" )
         MsgBeep( "Postoji dokument u kalk_pripremi koji je sumljiv!#Radi se o veznom dokumentu ili nekoj drugoj grešci...#Obradite ovaj dokument i autoimport ce nastaviti dalje sa radom !" )
         IF LastKey() == K_ESC
            IF Pitanje(, "Prekid operacije?", "N" ) == "D"
               RETURN .F.
            ENDIF
         ENDIF
         kalk_pripr_obrada()
         o_kalk_edit()

      ENDIF

   ENDDO

   RETURN .T.



   /*
    *   Provjeri da li je kalk_priprema prazna
    *   param: cIdVd - id vrsta dokumenta
    */

STATIC FUNCTION provjeri_stanje_kalk_pripreme( cIdVd )

   LOCAL nNrRec, nTmp, nPrviDok, cPrviDok, nUzorak

   SELECT kalk_pripr

   IF RecCount2() == 0
      RETURN 0 // provjeri da li je kalk_priprema prazna, ako je prazna vrati 0
   ENDIF

   GO TOP

   nNrRec := RecCount2()
   nTmp := 0
   cPrviDok := field->idvd
   nPrviDok := Val( cPrviDok )

   DO WHILE !Eof()
      nTmp += Val( field->idvd )
      SKIP
   ENDDO

   nUzorak := nPrviDok * nNrRec

   IF nUzorak <> nNrRec * nTmp
      RETURN 3 // ako u kalk_pripremi ima vise vrsta dokumenata vrati 3
   ENDIF

   DO CASE
   CASE cIdVd $ "14#KO"
      RETURN provjeri_vezne_dokumente_za_14( cPrviDok )


   CASE cIdVd == "41"
      RETURN provjeri_vezne_dokumente_za_41( cPrviDok )


   CASE cIdVd == "11"
      RETURN provjeri_vezne_dokumente_za_11( cPrviDok )


   CASE cIdVD == "95"
      RETURN provjeri_vezne_dokumente_za_95( cPrviDok )

   CASE cIdVD == "96"
      RETURN provjeri_vezne_dokumente_za_96( cPrviDok )
   ENDCASE

   RETURN 0



/*
    *     Provjeri vezne dokumente za tip dokumenta 14
    *   param: cVezniDok - dokument iz kalk_pripreme
    *  result vraca 1 ako je sve ok, ili 2 ako vezni dokument ne odgovara
*/

STATIC FUNCTION provjeri_vezne_dokumente_za_14( cVezniDok )

   // iza 14 ne moze biti veznih dokumenata

   RETURN 2


/*
    *     Provjeri vezne dokumente za tip dokumenta 41
*/

STATIC FUNCTION provjeri_vezne_dokumente_za_41( cVezniDok )

   IF cVezniDok $ "19"
      RETURN 1
   ENDIF

   RETURN 2


/*
    *     Provjeri vezne dokumente za tip dokumenta 11
*/
STATIC FUNCTION provjeri_vezne_dokumente_za_11( cVezniDok )

   IF cVezniDok $ "19"
      RETURN 1
   ENDIF

   RETURN 2


/*
  *     Provjeri vezne dokumente za tip dokumenta 95
*/
STATIC FUNCTION provjeri_vezne_dokumente_za_95( cVezniDok )

   IF cVezniDok $ "16"
      RETURN 1
   ENDIF

   RETURN 2

/*
 *     Provjeri vezne dokumente za tip dokumenta 96
 */
STATIC FUNCTION provjeri_vezne_dokumente_za_96( cVezniDok )

   IF cVezniDok $ "16"
      RETURN 1
   ENDIF

   RETURN 2


// ================== parametri - Rpar, WPara checkpoint ==================


/* kalk_imp_set_check_point
   *  Snima momenat do kojeg je dosao pri obradi dokumenata
*/
STATIC FUNCTION kalk_imp_set_check_point( nPRec )

   LOCAL nArr

   nArr := Select()

   o_params()
   SELECT params

   PRIVATE cSection := "K"
   PRIVATE cHistory := " "
   PRIVATE aHistory := {}

   Wpar( "is", nPRec )

   SELECT ( nArr )

   RETURN .T.



FUNCTION kalk_imp_partn_exist()

   LOCAL aRet, nCount := 0

   select_o_kalk_imp_temp()
   GO TOP

   aRet := {}

   IF FieldPos( "idtipdok" ) <> 0  .AND. kalk_imp_temp->idtipdok == "96" // ovo polje idtipdok postoji samo kada kalk_imp_temp sadrzi racune; za tip 96 polje partner je prazno
      RETURN aRet
   ENDIF

   Box( "#Sifra partnera provjera", 3, 50 )

   SELECT kalk_imp_temp
   GO TOP
   DO WHILE !Eof()
      select_o_partner( kalk_imp_temp->idpartner )
      ++nCount
      @ box_x_koord() + 1, box_y_koord() + 2 SAY Str( nCount, 5 ) + " : " + kalk_imp_temp->idpartner
      IF !Found()
         AAdd( aRet, { kalk_imp_temp->idpartner } )
      ENDIF
      SELECT kalk_imp_temp
      SKIP
   ENDDO
   BoxC()

   RETURN aRet



FUNCTION kalk_imp_txt_param_auto_import_podataka_konto( cSet )

   IF s_cKalkAutoImportPodatakaKonto == nil
      s_cKalkAutoImportPodatakaKonto := fetch_metric( "kalk_auto_import_podataka_konto", f18_user(), PadR( "1370", 7 ) )
   ENDIF

   IF cSet != NIL
      s_cKalkAutoImportPodatakaKonto := cSet
      set_metric( "kalk_auto_import_podataka_konto", f18_user(), cSet )
   ENDIF

   RETURN s_cKalkAutoImportPodatakaKonto


FUNCTION kalk_pripr_auto_obrada_i_azuriranje( lStampaj )

   hb_default( @lStampaj, .F. )

   kalk_pripr_obrada_stavki_sa_asistentom()
   IF automatska_obrada_error() .AND. Pitanje( , "Automatska obrada greške, prekid obrade ?", "D" ) == "D"
      RETURN .F.
   ELSE
      automatska_obrada_error( .F. ) // ako se trazi nastavak, onda stavi prekid
   ENDIF

   IF kalk_asistent_pause() .AND. Pitanje( , "Asistent pauza, Prekid obrade ?", "N" ) == "D"
      RETURN .F.
   ENDIF

   IF lStampaj
      //kalk_stampa_dokumenta( NIL, NIL, .T. )
      kalk_stampa_svih_dokumenata_u_pripremi()
   ENDIF

   //kalk_azuriranje_dokumenta( .T., lStampaj )
   kalk_azuriraj_sve_u_pripremi( lStampaj )
   o_kalk_edit()

   RETURN .T.


STATIC FUNCTION kalk_broj_ima_sufiks( cBrDok )

      IF "/" $ cBrdok
         RETURN .T.
      ENDIF

      IF "-" $ cBrdok
         RETURN .T.
      ENDIF

      RETURN .F.
      
