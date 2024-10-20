/*
 * This file is part of the bring.out knowhow ERP, a free and open source
 * Enterprise Resource Planning suite,
 * Copyright (c) 1994-2024 by bring.out d.o.o Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including knowhow ERP specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_knowhow.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */


#include "f18.ch"

MEMVAR ImeKol, Kol, wIdKonto

FUNCTION p_trfp_kalk_fin( cId, dx, dy )

   LOCAL xRet
   LOCAL cShema := Space( 1 )
   LOCAL cKavd := Space( 2 )
   PRIVATE imekol, kol

   ImeKol := {  ;
      { "Kalk",  {|| PadC( IdVD, 4 ) },    "IdVD"                  }, ;
      { PadC( "Shema", 5 ),    {|| PadC( shema, 5 ) },      "shema"                    }, ;
      { PadC( "ID", 10 ),    {|| dbf_get_rec()[ "id" ] },      "id"                    }, ;
      { PadC( "Naziv", 20 ), {|| dbf_get_rec()[ "naz" ] },     "naz"                   }, ;
      { "Konto  ", {|| idkonto },        "Idkonto", {|| .T. }, {|| ( "KO" $ wIdkonto ) .OR. ( "KP" $ wIdkonto ) .OR. ( "KK" $ widkonto ) .OR. ( "?" $ widkonto ) .OR. ( "A" $ widkonto ) .OR. ( "B" $ widkonto ) .OR. ( "F" $ widkonto ) .OR. ( "IDKONT" $ widkonto ) .OR.  P_konto( @wIdkonto ) }   }, ;
      { "Tarifa", {|| idtarifa },        "IdTarifa"              }, ;
      { "D/P",   {|| PadC( D_P, 3 ) },      "D_P"                   }, ;
      { "Znak",    {|| PadC( Znak, 4 ) },        "ZNAK"                  }, ;
      { "Dokument", {|| PadC( Dokument, 8 ) },   "Dokument"              }, ;
      { "Partner", {|| PadC( Partner, 7 ) },     "Partner"               }, ;
      { "IDVN",    {|| PadC( idvn, 4 ) },        "idvn"                  };
      }
   Kol := { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11 }

   trfp_filter( @cShema, @cKavd )

   SELECT ( F_TRFP )
   USE
   use_sql_trfp( cShema, cKavd )

   SET ORDER TO TAG "ID"
   GO TOP

   xRet := p_sifra( F_TRFP, 1, 15, 76, "Sheme kontiranja KALK->FIN", @cId, dx, dy, {| Ch| TRfpb( Ch ) } )

   RETURN xRet




STATIC FUNCTION trfp_filter( cShema, cVd )

   IF Pitanje(, "Želite li postaviti filter za odredjenu shemu", "N" ) == "D"
      Box(, 1, 60 )
      @ box_x_koord() + 1, box_y_koord() + 2 SAY "Odabir sheme:" GET cShema  PICT "@!"
      @ box_x_koord() + 1, Col() + 2 SAY "vrsta dokumenta (prazno sve)" GET cVd PICT "@!"
      READ
      BoxC()
      IF Empty( cShema )
         cSchema := NIL
      ENDIF
      IF Empty( cVD )
         cVD := NIL
      ENDIF
   ELSE
      cShema := NIL
      cVD := NIL
   ENDIF

   RETURN .T.



FUNCTION P_TRFP2( cId, dx, dy )

   LOCAL cShema := Space( 1 )
   LOCAL cFavd := Space( 2 )
   PRIVATE imekol, kol

   ImeKol := {  ;
      { "VD",  {|| PadC( IdVD, 4 ) },    "IdVD"                  }, ;
      { PadC( "Shema", 5 ),    {|| PadC( shema, 5 ) },      "shema"                    }, ;
      { PadC( "ID", 10 ),    {|| id },      "id"                    }, ;
      { PadC( "Naziv", 20 ), {|| naz },     "naz"                   }, ;
      { "Konto  ", {|| idkonto },        "Idkonto", {|| .T. }, {|| ( "?" $ widkonto ) .OR. ( "A" $ widkonto ) .OR. ( "B" $ widkonto ) .OR. ( "IDKONT" $ widkonto ) .OR.  p_konto( @wIdkonto ) }   }, ;
      { "Tarifa", {|| idtarifa },        "IdTarifa"              }, ;
      { "D/P",   {|| PadC( D_P, 3 ) },      "D_P"                   }, ;
      { "Znak",    {|| PadC( Znak, 4 ) },        "ZNAK"                  }, ;
      { "Dokument", {|| PadC( Dokument, 8 ) },   "Dokument"              }, ;
      { "Partner", {|| PadC( Partner, 7 ) },     "Partner"               }, ;
      { "IDVN",    {|| PadC( idvn, 4 ) },        "idvn"                  };
      }
   Kol := { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11 }

   trfp_filter( @cShema, @cFavd )

   SELECT ( F_TRFP2 )
   USE
   use_sql_trfp2( cShema, cFavd )

   SET ORDER TO TAG "ID"
   GO TOP

   p_sifra( F_TRFP2, 1, 15, 76, "Šeme kontiranja FAKT->FIN", @cId, dx, dy )

   RETURN .T.


FUNCTION TrfpB( Ch )

   LOCAL cShema2 := "1"
   LOCAL cTekShema
   LOCAL cIdvd := ""
   LOCAL nRec := 0
   LOCAL cDirSa := PadR( my_home() + "sif0", 20 )
   LOCAL cPobSt := "D"

   IF Ch == K_CTRL_F4

      cidvd := idvd
      cTekShema := shema
      Box(, 1, 60 )
      @ box_x_koord() + 1, box_y_koord() + 1 SAY "Napraviti novu shemu kontiranja za dokumente " + cidvd GET cShema VALID cShema <> shema
      READ
      IF LastKey() == K_ESC; BoxC(); RETURN DE_CONT; ENDIF
      BoxC()
      GO TOP
      DO WHILE !Eof()
         IF idvd == cidvd  .AND. shema == cTekShema
            Scatter()
            SKIP
            nRec := RecNo()
            SKIP -1
            _Shema := cShema
            appblank2( .F., .T. )
            Gather()
            GO nRec
         ELSE
            SKIP
         ENDIF
      ENDDO
      RETURN DE_REFRESH

   ELSEIF Ch == K_CTRL_F5

      cidvd := "  "
      cShema2 := " "

      cShema2 := "E"


      IF Pitanje(, "Preuzeti sheme kontiranja?", "D" ) == "D"


         Box(, 3, 70 )
         @ box_x_koord() + 1,  box_y_koord() + 2 SAY "Preuzeti podatke sa:" GET cDirSa VALID PostTRFP( cDirSa )
         @ box_x_koord() + 2,  box_y_koord() + 2 SAY "Odabir sheme:" GET cShema2  PICT "@!"
         @ box_x_koord() + 2, Col() + 2 SAY "vrsta kalkulacije (prazno sve)" GET cIdVd PICT "@!"
         @ box_x_koord() + 3,  box_y_koord() + 2 SAY "Pobrisati postojecu shemu za izabrane kalkulacije? (D/N)" GET cPobSt VALID cPobSt $ "DN" PICT "@!"
         READ
         IF LastKey() == K_ESC
            BoxC()
            RETURN DE_CONT
         ENDIF
         BoxC()

      ELSE
         IF Pitanje(, "Vratiti sheme koje su postojale prije zadnjeg preuzimanja shema?", "N" ) == "D"
            UndoSheme()
            RETURN DE_REFRESH
         ELSE
            RETURN DE_CONT
         ENDIF
      ENDIF

      UndoSheme( .T. )

      SELECT TRFP
      SET FILTER TO

      IF cPobSt == "D"
         GO TOP
         DO WHILE !Eof()
            IF ( Idvd == cIdVD .OR. Empty( cIdVd ) )  .AND. shema == cShema2
               SKIP
               nRec := RecNo()
               SKIP -1
               DELETE
               GO nRec
            ELSE
               SKIP
            ENDIF
         ENDDO
      ENDIF

      USE ( Trim( cDirSa ) + "TRFP.DBF" ) ALIAS TRFPN new
      SET ORDER TO TAG "ID"

      GO TOP
      nCnt := 0
      DO WHILE !Eof()
         IF ( TRFPN->idvd == cIdVd .OR. Empty( cIdVd ) ) .AND. TRFPN->shema == cShema2
            Scatter()
            SELECT TRFP
            nCnt++
            appblank2( .F., .T. )
            Gather()
            SELECT TRFPN
         ENDIF
         SKIP 1
      ENDDO
      USE
      SELECT TRFP
      MsgBeep( "Dodano u TRFP " + Str( nCnt ) + " stavki##" + ;
         "Ne zaboravite na odgovarajuca konta u sifrarnik#" + ;
         "konta-tipovi cijena dodati Shema='" + cShema2 + "'" )
      RETURN DE_REFRESH
   ENDIF

   RETURN DE_CONT


FUNCTION UndoSheme( lKopi )

   LOCAL cPom := "170771.POM", cStari := SIFPATH + "TRFP.ST", cTekuci := SIFPATH + "TRFP.DBF"
   LOCAL cStari2 := SIFPATH + "TRFPI1.ST", cTekuci2 := SIFPATH + "TRFP.CDX"

   IF lKopi == NIL; lKopi := .F. ; ENDIF
   IF lKopi
      SELECT TRFP
      PushWA()
      USE
      COPY File ( cTekuci ) TO ( cStari )
      COPY File ( cTekuci2 ) TO ( cStari2 )
      o_trfp()
      PopWA()
   ELSE
      IF File( cStari ) .AND. File( cStari2 )
         SELECT TRFP
         PushWA()
         USE
         FRename( cStari, cPom ); FRename( cTekuci, cStari );  FRename( cPom, cTekuci )
         FRename( cStari2, cPom ); FRename( cTekuci2, cStari2 ); FRename( cPom, cTekuci2 )
         o_trfp()
         PopWA()
      ENDIF
   ENDIF

   RETURN
// }

FUNCTION PostTRFP( cDirSa )

   // {
   LOCAL lVrati := .F.
   IF File( Trim( cDirSa ) + "TRFP.DBF" )
      IF File( Trim( cDirSa ) + "TRFP.CDX" )
         lVrati := .T.
      ELSE
         Msg( "Na zadanoj poziciji ne postoji fajl TRFP.CDX !" )
      ENDIF
   ELSE
      Msg( "Na zadanoj poziciji ne postoji fajl TRFP.DBF !" )
   ENDIF

   RETURN lVrati



FUNCTION v_setform()

   LOCAL cscsr

   IF File( SIFPATH + gSetForm + "TRXX.ZIP" ) .AND. pitanje(, "Sifranik parametara kontiranja iz arhive br. " + gSetForm + " ?", "N" ) == "D"
      PRIVATE ckomlin := "unzip  -o -d " + SIFPATH + gSetForm + "TRXX.ZIP " + SIFPATH
      SAVE SCREEN TO cscr
      cls
      ! &cKomLin
      RESTORE SCREEN FROM cscr
      SELECT F_TRFP
      IF !Used(); o_trfp(); ENDIF
      p_trfp_kalk_fin()
      SELECT F_TRMP
      IF !Used(); O_TRMP; ENDIF
      SELECT trfp; USE
      SELECT trmp; USE
      SELECT params
   ELSEIF  pitanje(, "Tekuce parametre kontiranja staviti u arhivu br. " + gSetForm + " ?", "N" ) == "D"
      PRIVATE ckomlin := "zip " + SIFPATH + gSetForm + "TRXX.ZIP " + SIFPATH + "TR??.DBF " + SIFPATH + "TR??I?.NTX"
      SAVE SCREEN TO cscr
      cls
      ! &cKomLin
      RESTORE SCREEN FROM cscr
   ENDIF

   RETURN .T.
