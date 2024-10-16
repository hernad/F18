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


// -------------------------------------------
// ukupno radnik
// -------------------------------------------
FUNCTION izracunaj_uneto_usati_za_radnika()

   LOCAL i, nArr
   LOCAL hData := hb_Hash()
   LOCAL nSati := 0
   LOCAL nNeto := 0
   LOCAL nIznos := 0
   LOCAL nOdbici := 0

   PRIVATE cTmp := ""

   nArr := Select()

   FOR i := 1 TO cLDPolja

      cTmp := PadL( AllTrim( Str( i ) ), 2, "0" )

      select_o_tippr( cTmp )

      IF tippr->( Found() ) .AND. tippr->aktivan == "D"

         nIznos += _I&cTmp

         IF tippr->ufs == "D"
            nSati += _S&cTmp
         ENDIF

         IF tippr->uneto == "D"
            nNeto += _I&cTmp
         ELSE
            nOdbici += _I&cTmp
         ENDIF

      ENDIF

   NEXT

   hData[ "uneto" ] := nNeto
   hData[ "usati" ] := nSati
   hData[ "uodbici" ] := nOdbici
   hData[ "iznos" ] := nIznos

   Select( nArr )

   RETURN hData



/*
 *     Parametri obracuna
 *   param: nMjesec - mjesec
 *   param: nGodina - godina
 *   param: cObr - broj obracuna
 *   param: cIdRj - id radna jedinica
 */
FUNCTION ld_pozicija_parobr( nMjesec, nGodina, cObr, cIdRj )

   LOCAL nNaz
   LOCAL nRec1 := 0
   LOCAL nRec2 := 0
   LOCAL nRec3 := 0
   LOCAL nRet := 1
   LOCAL cMj, cGod

   IF cObr == nil
      cObr := ""
   ENDIF

   IF cIDRJ == nil
      cIDRJ := ""
   ENDIF

   PushWa()

   cMj := Str( nMjesec, 2, 0 )
   cGod := Str( nGodina, 4, 0 )

   select_o_parobr( cMj + cGod + cObr )

   IF Eof()

      // ponovo pretrazi ali bez godine, ima godina = prazan zapis !!!
      nRet := 2
      select_o_parobr( cMj + Space( 4 ) + cObr )

      IF field->id <> cMj
         nRet := 0
         SKIP -1
      ENDIF
   ENDIF

   PopWa()

   RETURN nRet



/*
 *     Izracunavanje formula
 *   param: nInputF -
 *   param: fPrikaz - prikazi .t.
 */

FUNCTION ld_eval_formula( nInputF ) // , fPrikaz )

   LOCAL oErr

   PRIVATE cFormula

   // IF PCount() == 1
   // fPrikaz := .T.
   // ENDIF
   BEGIN SEQUENCE WITH {| err | Break( err ) }

      cFormula := Trim( tippr->formula )

      IF ( tippr->fiksan <> "D" )

         IF Empty( cFormula ) // ako je fiksan iznos nista ne izracunavaj!
            nInputF := 0
         ELSE
            ?E "ld_eval_formula:", cFormula
            nInputF := &cFormula
         ENDIF
         nInputF := Round( nInputF, gZaok )
      ENDIF


   RECOVER USING oErr

      cMsg := RECI_GDJE_SAM + " " + oErr:description + " LD FORMULA: " + cFormula
      ?E cMsg

      // log_write( cMsg, 1 )
      Alert( cMsg )
      RaiseError( cMsg )

   END SEQUENCE

   RETURN .T.



/* Prosj3(cTip, cTip2)
 *     Prosjek 3 mjeseca
 *   param: cTip
 *   param: cTip2
 */

FUNCTION Prosj3( cTip, cTip2 )

   // cTip1
   // "1"  -> prosjek neta/ satu
   // "2"  -> prosjek ukupnog primanja/satu
   // "3"  -> prosjek neta
   // "4"  -> prosjek ukupnog primanja
   // "5"  -> prosjek ukupnog primanja/ukupno sati
   // "6"  -> prosjek ukupnih "raznih" primanja/satu
   // "7"  -> prosjek ukupnih "raznih" primanja/ukupno sati
   // "8"  -> prosjek ukupnih "raznih" primanja
   //
   // cTip2
   // "1"  -> striktno predhodna 3 mjeseca
   // "2"  -> vracam se mjesec unazad u kome nije bilo godisnjeg

   LOCAL nMj1 := nMj2 := nMj3 := 0, nDijeli := 0, cmj1 := cmj2 := cmj3 := "", nPomak := 0, i := 0
   LOCAL nSS1 := 0, nSS2 := 0, nSS3 := 0, nSumsat := 0
   LOCAL nSP1 := 0, nsp2 := 0, nsp3 := 0

   PushWA()

   //SELECT LD
   // "1","str(godina)+idrj+str(mjesec)+idradn"
   // "2","str(godina)+str(mjesec)+idradn"
   //SET ORDER TO TAG ( ld_index_tag_vise_obracuna( "2", "I" ) )

   i := 0
   IF cTip2 == "2" // "2"  -> vracam se mjesec unazad u kome nije bilo godisnjeg
      DO WHILE .T.
         ++i
         IF _Mjesec - i < 1
            // SEEK Str( _Godina - 1, 4 ) + Str( 12 + _Mjesec - i, 2 ) + _idradn
            seek_ld( NIL, _Godina - 1, 12 + _Mjesec - i, NIL, _idradn )
            cMj1 := Str( 12 + _mjesec - i, 2 ) + "." + Str( _godina - 1, 4 )
         ELSE
            // SEEK Str( _Godina, 4 ) + Str( _mjesec - i, 2 ) + _idradn
            seek_ld( NIL, _Godina, _Mjesec - i, NIL, _idradn )
            cMj1 := Str( _mjesec - i, 2 ) + "." + Str( _godina, 4 )
         ENDIF
         IF &gFUGod <> 0  // formula za godisnji, default: I06
            nPomak++
         ELSE
            EXIT
         ENDIF
         IF i > 12  // nema podataka
            EXIT
         ENDIF
      ENDDO
   ENDIF

   IF _mjesec - 1 - nPomak < 1
      // SEEK Str( _Godina - 1, 4 ) + Str( 12 + _Mjesec - 1 - nPomak, 2 ) + _idradn
      seek_ld( NIL, _Godina - 1, 12 + _Mjesec - 1 - nPomak, NIL, _idradn )
      cMj1 := Str( 12 + _mjesec - 1 - nPomak, 2 ) + "." + Str( _godina - 1, 4 )
   ELSE
      // SEEK Str( _Godina, 4 ) + Str( _Mjesec - 1 - nPomak, 2 ) + _idradn
      seek_ld( NIL, _Godina, _Mjesec - 1 - nPomak, NIL, _idradn )
      cMj1 := Str( _mjesec - 1 - nPomak, 2 ) + "." + Str( _godina, 4 )
   ENDIF

   IF !Eof()
      IF ld_vise_obracuna()
         ScatterS( godina, mjesec, idrj, idradn, "w" )
      ELSE
         wUneto := field->uneto
         wUsati := field->usati
      ENDIF
      IF cTip $ "13"  // tip "1"  -> prosjek neta/ satu, "3"  -> prosjek neta
         nMj1 := wUNeto
      ELSEIF cTip $ "678"
         nMj1 := URPrim()
      ELSE
         nMj1 := UPrim() // tip "2"  -> prosjek ukupnog primanja/satu, "5"  -> prosjek ukupnog primanja/ukupno sati
      ENDIF
      IF cTip $ "126"
         nSS1 := wUSati
         nSP1 := nMj1
         IF wUsati <> 0
            nMj1 := nMj1 / wUSati
         ELSE
            nMj1 := 0
         ENDIF
      ELSEIF cTip $ "5"
         nSS1 := USati()
      ELSEIF cTip $ "7"
         nSS1 := URSati()
      ENDIF
      IF nMj1 <> 0
         ++nDijeli
      ENDIF
   ENDIF

   IF _mjesec - 2 - nPomak < 1
      // SEEK Str( _Godina - 1, 4 ) + Str( 12 + _Mjesec - 2 - nPomak, 2 ) + _idradn
      seek_ld( NIL, _Godina - 1, 12 + _Mjesec - 2 - nPomak, NIL, _idradn )
      cMj2 := Str( 12 + _mjesec - 2 - nPomak, 2 ) + "." + Str( _godina - 1, 4 )
   ELSE
      // SEEK Str( _Godina, 4 ) + Str( _Mjesec - 2 - nPomak, 2 ) + _idradn
      seek_ld( NIL, _Godina,  _Mjesec - 2 - nPomak, NIL, _idradn )
      cMj2 := Str( _mjesec - 2 - nPomak, 2 ) + "." + Str( _godina, 4 )
   ENDIF
   IF !Eof()
      IF ld_vise_obracuna()
         ScatterS( godina, mjesec, idrj, idradn, "w" )
      ELSE
         wuneto := uneto
         wusati := usati
      ENDIF
      IF cTip $ "13"
         nMj2 := wUNeto
      ELSEIF cTip $ "678"
         nMj2 := URPrim()
      ELSE
         nMj2 := UPrim()
      ENDIF
      IF cTip $ "126"
         nSS2 := wUSati
         nSP2 := nMj2
         IF wusati <> 0
            nMj2 := nMj2 / wUSati
         ELSE
            nMj2 := 0
         ENDIF
      ELSEIF cTip $ "5"
         nSS2 := USati()
      ELSEIF cTip $ "7"
         nSS2 := URSati()
      ENDIF
      IF nMj2 <> 0
         ++nDijeli
      ENDIF
   ENDIF

   IF _mjesec - 3 - nPomak < 1
      // SEEK Str( _Godina - 1, 4 ) + Str( 12 + _Mjesec - 3 - nPomak, 2 ) + _idradn
      seek_ld( NIL, _Godina - 1,  12 + _Mjesec - 3 - nPomak, NIL, _idradn )
      cMj3 := Str( 12 + _mjesec - 3 - nPomak, 2 ) + "." + Str( _godina - 1, 4 )
   ELSE
      // SEEK Str( _Godina, 4 ) + Str( _Mjesec - 3 - nPomak, 2 ) + _idradn
      seek_ld( NIL, _Godina, _Mjesec - 3 - nPomak, NIL, _idradn )
      cMj3 := Str( _mjesec - 3 - nPomak, 2 ) + "." + Str( _godina, 4 )
   ENDIF

   IF !Eof()
      IF ld_vise_obracuna()
         ScatterS( godina, mjesec, idrj, idradn, "w" )
      ELSE
         wuneto := field->uneto
         wusati := field->usati
      ENDIF
      IF cTip $ "13"
         nMj3 := wUNeto
      ELSEIF cTip $ "678"
         nMj3 := URPrim()
      ELSE
         nMj3 := UPrim()
      ENDIF
      IF cTip $ "126"
         nSS3 := wUSati
         nSP3 := nMj3
         IF wusati <> 0
            nMj3 := nMj3 / wUSati
         ELSE
            nMj3 := 0
         ENDIF
      ELSEIF cTip $ "5"
         nSS3 := USati()
      ELSEIF cTip $ "7"
         nSS3 := URSati()
      ENDIF
      IF nMj3 <> 0
         ++nDijeli
      ENDIF
   ENDIF

   IF nDijeli == 0
      nDijeli := 99999999
   ENDIF

   nSumsat := iif( nSS1 + nSS2 + nSS3 <> 0, nSS1 + nSS2 + nSS3, 99999999 )

   Box( "#" +  _idradn + " " + IIF( cTip $ "57", "UKUPNA PRIMANJA", "Prosjek" ) + " ZA MJESECE UNAZAD:", 6, 60 )
   @ box_x_koord() + 2, box_y_koord() + 2 SAY cmj1; @ Row(), Col() + 2 SAY nMj1 PICT "999999.999"
   IF cTip $ "126"; ?? "  primanja/sati:"; ?? nSP1, "/", nSS1; ENDIF
   IF cTip $ "57"; ?? "  sati:"; ?? nSS1; ENDIF
   @ box_x_koord() + 3, box_y_koord() + 2 SAY cmj2; @ Row(), Col() + 2 SAY nMj2 PICT "999999.999"
   IF cTip $ "126"; ?? "  primanja/sati:"; ?? nsp2, "/", nSS2; ENDIF
   IF cTip $ "57"; ?? "  sati:"; ?? nSS2; ENDIF
   @ box_x_koord() + 4, box_y_koord() + 2 SAY cmj3; @ Row(), Col() + 2 SAY nMj3 PICT "999999.999"
   IF cTip $ "126"; ?? "  primanja/sati:"; ?? nsp3, "/", nSS3; ENDIF
   IF cTip $ "57"; ?? "  sati:"; ?? nSS3; ENDIF
   @ box_x_koord() + 6, box_y_koord() + 2 SAY "Prosjek"
   @ Row(), Col() + 2 SAY ( nMj3 + nMj2 + nMj1 ) / iif( cTip $ "57", nSumsat, nDijeli ) PICT "999999.999"

   IF SELECT( "LD_2" ) == 0  // nije pokrenuto iz rekalkulacije Primanja
      Inkey( 0 )
   ENDIF

   BoxC()

   PopWa()

   RETURN ( nMj3 + nMj2 + nMj1 ) / iif( cTip $ "57", nSumsat, nDijeli )



/*
 *     Racuna ukupna primanja
 */

FUNCTION UPrim()

   LOCAL c719

   IF ld_vise_obracuna()
      c719 := UbaciPrefix( gFUPrim, "w" )
   ELSE
      c719 := gFUPrim
   ENDIF

   RETURN &c719


/*
 *     Racuna ukupne sate
 */
FUNCTION USati()

   IF Empty( gFUSati )
      RETURN 0
   ENDIF
   c719 := UbaciPrefix( gFUSati, "w" )

   RETURN &c719



/*
 *     Ukupna razna primanja
 */
FUNCTION URPrim()

   IF Empty( gFURaz )
      RETURN 0
   ENDIF

   c719 := UbaciPrefix( gFURaz, "w" )

   RETURN &c719


// -----------------------------------------------
// Ukupna razna primanja sati
// -----------------------------------------------
FUNCTION URSati()

   IF Empty( gFURSati )
      RETURN 0
   ENDIF

   c719 := UbaciPrefix( gFURSati, "w" )

   RETURN &c719


FUNCTION Prosj1( cTip, cTip2, cF0 )

   // if cTip== "1"  -> prosjek neta/ satu
   // if ctip== "2"  -> prosjek ukupnog primanja/satu
   // if cTip=="3"  -> prosjek neta
   // if cTip=="4"  -> prosjek ukupnog primanja
   // if cTip=="5"  -> prosjek ukupnog primanja/ukupno sati
   // if cTip== "6"  -> prosjek ukupnih "raznih" primanja/satu
   // if cTip== "7"  -> prosjek ukupnih "raznih" primanja/ukupno sati
   // if cTip== "8"  -> prosjek ukupnih "raznih" primanja

   // if cTip2=="1"  -> prosli mjesec i  primanje <> 0
   // if ctip2=="2"  -> predhodni mjesec za koji je UNeto==UPrim() i primanje <> 0
   // if ctip2=="3"  -> predhodni mjesec za koji je UNeto==URPrim() i primanje <> 0
   //
   // cF0 = "_i18"  - ne uzimaj mjesec ako je _i18<>0
   // ************************************************
   LOCAL nMj1 := 0, i := 0
   PRIVATE cFormula
   PushWA()

   IF cF0 == NIL
      cFormula := "0"
   ELSE
      cFormula := cF0
   ENDIF

   //SELECT LD
   // "1","str(godina)+idrj+str(mjesec)+idradn"
   // "2","str(godina)+str(mjesec)+idradn"
   // SET ORDER TO TAG ( ld_index_tag_vise_obracuna( "2", "I" ) )

   i := 0

   DO WHILE .T.
      ++i
      IF _mjesec - i < 1
         // SEEK Str( _godina - 1, 4 ) + Str( 12 + _mjesec - i, 2 ) + _idradn
         seek_ld_2( NIL, _godina - 1,  12 + _mjesec - i, NIL, _idradn )
         cMj1 := Str( 12 + _mjesec - i, 2 ) + "." + Str( _godina - 1, 4 )
      ELSE
         // SEEK Str( _godina, 4 ) + Str( _mjesec - i, 2 ) + _idradn
         seek_ld_2( NIL, _godina,  _mjesec - i, NIL, _idradn )
         cMj1 := Str( _mjesec - i, 2 ) + "." + Str( _godina, 4 )
      ENDIF

      IF !Eof()
         IF ld_vise_obracuna()
            ScatterS( godina, mjesec, idrj, idradn, "w" )
         ELSE
            wUneto := field->uneto
            wUsati := field->usati
         ENDIF
         IF cTip $ "13"
            nMj1 := wUNeto
         ELSEIF cTip $ "678"
            nMj1 := URPrim()
         ELSE
            nMj1 := UPrim()
         ENDIF
         IF cTip $ "126"
            IF wusati <> 0
               nMj1 := nMj1 / wUSati
            ELSE
               nMj1 := 0
            ENDIF
         ELSEIF cTip $ "5"
            IF USati() <> 0
               nMj1 := nMj1 / USati()
            ELSE
               nMj1 := 0
            ENDIF
         ELSEIF cTip $ "7"  // Prosj1( "7")
            IF URSati() <> 0
               nMj1 := nMj1 / URSati()
            ELSE
               nMj1 := 0
            ENDIF
         ENDIF
      ELSE
         MsgBeep( "Prosjek je uzet iz šifarnika radnika - OSN.BOL. !"  )
         select_o_radn( _IdRadn )

         nMj1 := osnbol
         SELECT LD
         EXIT
      ENDIF

      IF nMj1 == 0
         LOOP
      ENDIF

      IF &cFormula <> 0
         LOOP
      ENDIF

      IF cTip2 == "1"  // gleda se prosli mjesec
         EXIT
      ELSEIF cTip2 == "3"
         IF Round( wUNeto, 2 ) == Round( URPrim(), 2 )
            EXIT
         ENDIF
      ELSE
         IF Round( wUNeto, 2 ) == Round( UPrim(), 2 )
            EXIT
         ENDIF
      ENDIF

   ENDDO

   Box(, 4, 50 )
   @ box_x_koord() + 1, box_y_koord() + 2 SAY8 "PRIMANJE ZA PROŠLI MJESEC:"
   @ box_x_koord() + 2, box_y_koord() + 2 SAY  cmj1; @ Row(), Col() + 2 SAY nMj1 PICT "999999.999"
   @ box_x_koord() + 4, box_y_koord() + 2 SAY "Prosjek"; @ Row(), Col() + 2 SAY nMj1 PICT "999999.999"

   IF SELECT( "LD_2" ) == 0  // nije pokrenuto iz rekalkulacije primanja
      Inkey( 0 )
   ENDIF
   
   BoxC()

   PopWa()

   RETURN  nMj1



FUNCTION Predhodni( nI, cVar, cObr )

   LOCAL cKljuc := ""

   IF cObr == NIL
      cObr := "1"
   ENDIF

   PRIVATE cPom := ""


   IF "U" $ Type( "lRekalk" ); lRekalk := .F. ; ENDIF

   IF lRekalk .AND. !TPImaPO( SubStr( cVar, 3 ) )
      // pri rekalkulaciji ne racunaj
      // predhodni ukoliko u formuli
      // nema parametara obracuna
      RETURN 0
   ENDIF

   PushWA()

   // CREATE_INDEX("LDi1","str(godina)+idrj+str(mjesec)+idradn","LD")
   // CREATE_INDEX("LDi2","str(godina)+str(mjesec)+idradn","LD")
   // SET ORDER TO TAG ( ld_index_tag_vise_obracuna( "2", "I" ) )

   IF _Mjesec - nI < 1
      // HSEEK Str( _Godina - 1, 4 ) + Str( 12 + _Mjesec - 1, 2 ) + _idradn
      seek_ld_2( NIL, _Godina - 1, 12 + _Mjesec - 1, NIL, _idradn )
   ELSE
      // HSEEK Str( _Godina, 4 ) + Str( _Mjesec - nI, 2 ) + _idradn
      seek_ld_2( NIL, _Godina, _Mjesec - nI, NIL, _idradn )
   ENDIF

   cPom := cVar
   cField = SubStr( cPom, 2 )

   IF ld_vise_obracuna()
      &cPom := 0
      cKljuc := Str( godina, 4 ) + Str( mjesec, 2 ) + idradn
      IF !Empty( cObr )
         DO WHILE !Eof() .AND. Str( godina, 4 ) + Str( mjesec, 2 ) + idradn == cKljuc
            IF obr == cObr
               &cPom += &cField
            ENDIF
            SKIP 1
         ENDDO
      ELSE
         DO WHILE !Eof() .AND. Str( godina, 4 ) + Str( mjesec, 2 ) + idradn == cKljuc
            &cPom += &cField
            SKIP 1
         ENDDO
      ENDIF
   ELSE
      &cPom := &cField
   ENDIF

   PopWa()

   RETURN 0



FUNCTION PrimSM( cOznaka, cTipPr )

   //
   // cOznaka - oznaka primanja u smecu
   // cTipPr  - "01, "02" , ...
   // "NE" - neto
   // izlaz = primanje iz smeca
   // ***********************************
   LOCAL nRez := 0

   PRIVATE cTipa := ""
   // "LDSMi1","Obr+str(godina)+str(mjesec)+idradn+idrj",my_home()+"LDSM")

   PRIVATE cpom := ""

   PushWA()

   SELECT ( F_LDSM )
   IF !Used()
      O_LDSM
   ENDIF

   SEEK cOznaka + Str( _godina ) + Str( _mjesec ) + _idradn + _idrj // ldsm
   IF cTippr == "NE"
      nRez := UNETO
   ELSE
      cTipa := "I" + cTipPr
      nRez := &cTipa
   ENDIF

   PopWa()

   RETURN nRez


FUNCTION Fill( xValue, xIzn )

   IF Type( xIzn ) <> "UI" .AND. Type( xIzn ) <> "UE"
      xVAlue := &xIzn
      ShowGets()
   ENDIF

   RETURN 0



FUNCTION FillR( xValue, xIzn )

   LOCAL _rec

   PushWA()
   SELECT radn

   _rec := dbf_get_rec()
   _rec[ Lower( xValue ) ] := xIzn

   update_rec_server_and_dbf( "ld_radn", _rec, 1, "FULL" )

   PopWa()

   RETURN xIzn


FUNCTION GETR( cPrompt, xValue )

   LOCAL nRezult
   LOCAL _rec
   PRIVATE Getlist := {}

   PushWA()
   SELECT radn

   nRezult := &xValue

   Box(, 2, 60 )
   @ box_x_koord() + 1, box_y_koord() + 2 SAY cPrompt GET nRezult
   READ
   BoxC()

   IF LastKey() == K_ESC
      RETURN &xValue
   ENDIF

   _rec := dbf_get_rec()
   _rec[ Lower( xValue ) ] := nRezult

   update_rec_server_and_dbf( "ld_radn", _rec, 1, "FULL" )

   PopWa()

   RETURN nRezult




FUNCTION FillBrBod( _brbod )

   LOCAL _vars

   IF ( radn->brbod <> _brbod )

      IF Pitanje(, _l( "Staviti u sifrarnik radnika ovu vrijednost D/N?" ), "N" ) == "D"

         SELECT radn
         _vars := dbf_get_rec()
         _vars[ "brbod" ] := _brbod

         update_rec_server_and_dbf( "ld_radn", _vars, 1, "FULL" )

      ENDIF

   ENDIF

   IF Select( "ld" ) == 0
      Alert( "fillbrbod Alias ld not ?!" )
   ENDIF

   RETURN .T.


FUNCTION set_koeficijent_minulog_rada( k_min_rad )

   LOCAL _fields

   IF radn->kminrad <> k_min_rad
      IF Pitanje( , "Staviti u šifarnik radnika ovu vrijednost (D/N) ?", "N" ) == "D"

         SELECT radn
         _fields := dbf_get_rec()
         _fields[ "kminrad" ] := k_min_rad
         update_rec_server_and_dbf( "ld_radn", _fields, 1, "FULL" )
         SELECT ld
      ENDIF
   ENDIF

   RETURN .T.



FUNCTION FillVPosla()

   LOCAL _rec

   IF radn->idvposla <> _idvposla
      IF Pitanje( , _l( "Staviti u sifrarnik radnika ovu vrijednost D/N?" ), "N" ) == "D"

         SELECT radn
         _rec := dbf_get_rec()
         _rec[ "idvposla" ] := _idvposla
         update_rec_server_and_dbf( "ld_radn", _vars, 1, "FULL" )
         SELECT ld
      ENDIF
   ENDIF

   RETURN .T.



// vraca naziv radnika
FUNCTION g_naziv( cRadn )

   LOCAL cStr := ""
   LOCAL nTArea := Select()

   select_o_radn( cRadn )
   cStr := AllTrim( radn->ime ) + " " + AllTrim( radn->naz )
   SELECT ( nTArea )

   RETURN cStr


// *****************************
// izracun bruto iznosa
// *****************************
FUNCTION Bruto( nbruto, ndopr )

   nBruto := _UNETO
   nPorDopr := 0

   SELECT ( F_POR )

   IF !Used()
      o_por()
   ENDIF

   SELECT ( F_DOPR )

   IF !Used()
      o_dopr()
   ENDIF

   SELECT ( F_KBENEF )

   IF !Used()
      o_koef_beneficiranog_radnog_staza()
   ENDIF

   nBO := 0
   nBo := parobr->k3 / 100 * Max( _UNeto, PAROBR->prosld * gPDLimit / 100 )

   select_o_por()
   GO TOP

   nPom := nPor := 0
   nC1 := 30
   nPorOl := 0

   DO WHILE !Eof()
      nPom := Max( dlimit, Round( iznos / 100 * Max( _UNeto, PAROBR->prosld * gPDLimit / 100 ), gZaok ) )
      nPor += nPom
      SKIP
   ENDDO

   nBruto += nPor
   nPorDopr += nPor

   IF radn->porol <> 0  // poreska olaksica
      nPorOl := parobr->prosld * radn->porol / 100
      IF nPorOl > nPor // poreska olaksica ne moze biti veca od poreza
         nPorOl := nPor
      ENDIF
      nBruto -= nPorol
      nPorDopr -= nPorOl
   ENDIF
   IF radn->porol <> 0
      // ? m
      // ? "Ukupno Porez"
      // @ prow(),nC1 SAY space(len(gpici))
      // @ prow(),39 SAY nPor-nPorOl pict gpici
      // ? m
   ENDIF

   select_o_dopr()
   GO TOP

   nPom := nDopr := 0
   nC1 := 20

   DO WHILE !Eof()  // DOPRINOSI
      IF Right( id, 1 ) <> "X"
         SKIP
         LOOP
      ENDIF
      // ? id,"-",naz
      // @ prow(),pcol()+1 SAY iznos pict "99.99%"
      IF Empty( idkbenef ) // doprinos udara na neto
         // @ prow(),pcol()+1 SAY nBO pict gpici
         // nC1:=pcol()+1
         nPom := Max( dlimit, Round( iznos / 100 * nBO, gZaok ) )
         nBruto += nPom
         nPorDopr += nPom
      ELSE
         nPom0 := AScan( aNeta, {| x | x[ 1 ] == idkbenef } )
         IF nPom0 <> 0
            nPom2 := parobr->k3 / 100 * aNeta[ nPom0, 2 ]
         ELSE
            nPom2 := 0
         ENDIF
         IF Round( nPom2, gZaok ) <> 0
            // @ prow(),pcol()+1 SAY nPom2 pict gpici
            // nC1:=pcol()+1
            nPom := Max( dlimit, Round( iznos / 100 * nPom2, gZaok ) )
            nBruto += nPom
            nPorDopr += nPom
         ENDIF
      ENDIF

      SKIP
   ENDDO // doprinosi
   // ? m
   // ? "UKUPNO POREZ+DOPRINOSI"
   // @ prow(),39 SAY nPorDopr pict gpici
   // ? m
   // ? "BRUTO IZNOS"
   // @ prow(),60 SAY nBruto pict gpici
   // ? m

   RETURN ( nBruto )




// **********************************************
// Provjerava ima li u formuli tipa
// primanja cTP parametara obracuna ("PAROBR")
// **********************************************

FUNCTION TPImaPO( cTP )

   LOCAL lVrati := .F., nObl := Select()

   // SELECT TIPPR
   PushWA()

   select_o_tippr( cTP )

   IF ID == cTP .AND. "PAROBR" $ Upper( TIPPR->formula ); lVrati := .T. ; ENDIF


   PopWA()
   SELECT ( nObl )

   RETURN lVrati



FUNCTION BodovaNaDan( ngodina, nmjesec, cidradn, cidrj, ndan, cDanDio )

   LOCAL _BrBod := 0

   SELECT RADSIHT
   SEEK Str( ngodina, 4 ) + Str( nmjesec, 2 ) + cIdRadn + cIdRj + Str( nDan, 2 ) + cDanDio // radsiht
   // +"01"+str(ndan,2)
   // id na prvi slog
   ntRec := RecNo()   // ispisi broj bodova
   IF !Found()
      _BrBod := 0
   ELSE
      _brbod := brbod
   ENDIF

   GO nTRec

   RETURN _BrBod


FUNCTION UbaciPrefix( cU, cP )

   cU := PadR( Upper( cU ), 250 )

   cU := StrTran( cU, "I0", cP + "I0"      )
   cU := StrTran( cU, "I1", cP + "I1"      )
   cU := StrTran( cU, "I2", cP + "I2"      )
   cU := StrTran( cU, "I3", cP + "I3"      )
   cU := StrTran( cU, "I4", cP + "I4"      )

   cU := StrTran( cU, "S0", cP + "S0"      )
   cU := StrTran( cU, "S1", cP + "S1"      )
   cU := StrTran( cU, "S2", cP + "S2"      )
   cU := StrTran( cU, "S3", cP + "S3"      )
   cU := StrTran( cU, "S4", cP + "S4"      )

   cU := StrTran( cU, "USATI", cP + "USATI"   )
   cU := StrTran( cU, "UNETO", cP + "UNETO"   )
   cU := StrTran( cU, "UODBICI", cP + "UODBICI" )
   cU := StrTran( cU, "UIZNOS", cP + "UIZNOS"  )

   RETURN Trim( cU )


FUNCTION PrimLD( cOznaka, cTipPr )

   LOCAL nRez := 0, nArr := Select()
   PRIVATE cTipa := ""
   PRIVATE cpom := ""

   // select_o_ld()

   PushWA()

   // SET ORDER TO TAG "1"
   // CREATE_INDEX("1","str(godina)+idrj+str(mjesec)+obr+idradn",KUMPATH+"LD")

   // SEEK Str( _godina, 4 ) + _idrj + Str( _mjesec, 2 ) + cOznaka + _idradn
   seek_ld( _idrj, _godina, _mjesec, cOznaka, _idradn )


   IF cTippr == "NE"
      nRez := UNETO
   ELSE
      cTipa := "I" + cTipPr
      nRez := &cTipa
   ENDIF

   PopWa()

   SELECT ( nArr )

   RETURN nRez



FUNCTION Unos2()
   RETURN ( NIL )
