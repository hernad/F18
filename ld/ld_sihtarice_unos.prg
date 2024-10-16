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


FUNCTION UnosSiht()

   LOCAL cIdradn, cIdRj, nGodina, nMjesec

   IF .T.
      MsgBeep( "http://redmine.bring.out.ba/issues/25986" )
      RETURN .F.
   ENDIF

   PRIVATE GetList := {}
   DO WHILE .T. // G.PETLJA

      nGodina := _Godina
      nMjesec := _Mjesec
      cIDradn := _Idradn
      cIDrj := _IdRj

      o_norsiht()   // sifrarnik normi koje se koriste u sihtarici
      o_tprsiht()   // tipovi primanja koji se unose u kroz sihtarice


      o_radsiht()

      Scatter()
      _Godina := nGodina
      _Mjesec := nmjesec
      eIdradn := cIdRAdn
      _IdRj := cIdRj
      _Dan := 1
      _DanDio := " "


      IF _BrBod = 0
         _BrBod := radn->brbod
      ENDIF

      Box(, 6, 68 )
      @ box_x_koord() + 0, box_y_koord() + 2 SAY "SIHTARICA:"

      nDan := 1
      DO WHILE .T.

         @ box_x_koord() + 1, box_y_koord() + 2 SAY "Dan" GET _dan PICT "99"
         @ box_x_koord() + 1, Col() + 2 SAY "Dio dana" GET _dandio VALID _dandio $ " 12345678" PICT "@!"
         @ box_x_koord() + 1, Col() + 2 SAY "Broj bodova" GET _BrBod PICT "99999.999"  ;
            WHEN {|| _BrBod := BodovaNaDan( ngodina, nmjesec, cidradn, cidrj, _dan, _dandio ), ;
            _Brbod := iif( _BrBod = 0, radn->brbod, _BrBod ), .T. }
         READ

         IF LastKey() = K_ESC; exit; ENDIF
         IF _Dan > 31 .OR. _dan = 0; exit; ENDIF


         SELECT TPRSiht; GO top; _idtippr := ID
         DO WHILE .T.

            @ box_x_koord() + 2, box_y_koord() + 2 SAY "   Primanje" GET _idtippr ;
               VALID  Empty( _idtippr ) .OR. P_TPRSiht( @_idtippr, 2, 25 ) PICT "@!"

            READ
            IF LastKey() = K_ESC
               EXIT
            ENDIF
            SELECT RADSIHT
            SEEK Str( _godina, 4 ) + Str( _mjesec, 2 ) + _IdRadn + _IdRj + Str( _dan, 2 ) + _dandio + _idtippr
            IF Found() // uzmi tekuce vrijednosti
               _izvrseno := izvrseno
               _bodova := bodova
               _idnorsiht := idnorsiht
            ELSE
               _bodova := 0
               _izvrseno := 0
               _idnorsiht := Space( 4 )
            ENDIF
            SELECT TPRSiht
            HSEEK _idtippr

            IF tprSiht->k1 = "F"
               @ box_x_koord() + 3, box_y_koord() + 2 SAY "Sifra Norme" GET _IdNorSiht  VALID  P_NorSiht( @_idNorSiht )

            ELSE
               _IdNorSiht := Space( 4 )
               @ box_x_koord() + 3, box_y_koord() + 2 SAY Space( 25 )
            ENDIF


            @ box_x_koord() + 3, box_y_koord() + 40 SAY "    Izvrseno" GET _Izvrseno  PICT "999999.999" ;
               WHEN !Empty( _idtippr )

            @ box_x_koord() + 5, box_y_koord() + 40 SAY "Ukupno bodova" GET _Bodova PICT "99999999.99" ;
               WHEN   {|| _Bodova := _BrBod * _izvrseno / iif( TPRSiht->k1 = "F", NorSiht->Iznos, 1 ), .F. }

            READ

            IF Empty( _idtippr )
               // ako je primanje prazno - prevrni na slijedeci dan
               EXIT
            ENDIF
            SELECT RADSIHT
            SEEK Str( _godina, 4 ) + Str( _mjesec, 2 ) + _IdRadn + _IdRj + Str( _dan, 2 ) + _dandio + _idtippr

            IF Round( _izvrseno, 4 ) <> 0 .OR. Round( _Bodova, 4 ) <> 0   // nije nulirano
               IF !Found()
               APPEND blank
               ENDIF
               Gather()
            ELSE
               IF Found() // a sadr§aj je 0
                  my_delete()
               ENDIF
            ENDIF

            SELECT TPRSiht
            SEEK _idtippr
            SKIP
            _idtippr := id

            IF Eof(); exit; ENDIF
         ENDDO
         ++_Dan ; IF _Dan > 31 .OR. _dan = 0; exit; ENDIF
      ENDDO

      Boxc()

      // zavrseno azuriranje RADSIHT
      // **************************************************************
      START PRINT CRET

      P_12CPI
      ? tip_organizacije() + ":", self_organizacija_naziv()
      ?? "; Radna jedinica:", cIdRj
      ?
      ? "Godina:", Str( ngodina, 4 ), "/", Str( nmjesec, 2 )
      ?
      ? "*** Pregled Sihtarice za:"
      ?? cIDradn, radn->naz
      ?
      P_COND2

      Linija()
      ?
      SELECT TPRSiht; GO TOP
      ?? Space( 3 ) + " " + Space( 6 ) + " "
      fPrvi := .T.
      DO WHILE !Eof()
         IF fprvi
            ?? Space( 4 ) + " "
            fprvi := .F.
         ENDIF
         ?? PadC( id, 22 )
         SKIP
      ENDDO
      SELECT TPRSiht; GO TOP
      ?
      ?? Space( 3 ) + " " + Space( 6 ) + " "
      fPRvi := .T.
      DO WHILE !Eof()
         IF fprvi
            ?? Space( 4 ) + " "
            fprvi := .F.
         ENDIF
         ?? PadC( AllTrim( naz ), 22 )
         SKIP
      ENDDO
      ?
      ?? Space( 3 ) + " " + Space( 6 ) + " "
      SELECT TPRSiht; GO TOP
      fPRvi := .T.
      DO WHILE !Eof()
         IF fprvi
            ?? Space( 4 ) + " "
            fprvi := .F.
         ENDIF
         ?? PadC( "izvrseno/bodova", 22 )
         SKIP
      ENDDO

      Linija()

      PRIVATE aSihtUk := {}

      FOR i := 1 TO TPRSiht->( reccount2() )
         AAdd( aSihtUk, 0 )
      NEXT

      FOR nDan := 1  TO 31

         FOR nDanDio := 0 TO 8
            cDanDio := IF( nDanDio == 0, " ", Str( nDanDio, 1 ) )


            _BrBod := BodovaNaDan( ngodina, nmjesec, cidradn, cidrj, ndan, cDanDio )

            IF _brbod == 0 .AND. !Empty( cDanDio )
               LOOP
            ENDIF

            IF cDanDio == " "
               ? Str( ndan, 3 )
            ELSE
               ? " /" + cDanDio
            ENDIF
            ?? Str( _BrBod, 6, 2 )

            ?? " "

            SELECT TPRSiht
            GO TOP

            fPRvi := .T.

            nPozicija := 0
            DO WHILE !Eof()
               ++nPozicija

               SELECT RADSIHT
               SEEK Str( ngodina, 4 ) + Str( nmjesec, 2 ) + cIdRadn + cIdRj + Str( ndan, 2 ) + cDanDio + tprsiht->id

               // utvrdi çifru norme za dan
               IF fprvi   // odstampaj sifru norme
                  IF  dan = ndan .AND. dandio == cDanDio .AND. idtippr = "01"
                     ?? idNorSiht + " "
                  ELSE
                     ?? Space( 4 ) + " "
                  ENDIF
                  fPRvi := .F.
               ENDIF

               IF Found()
                  Scatter()
                  ?? Str( _Izvrseno, 10, 2 ), Str( _Bodova, 10, 2 ) + " "
                  aSihtUk[ nPozicija ] += _Bodova
               ELSE
                  ?? Space( 22 )
                  aSihtUk[ nPozicija ] += 0
               ENDIF

               SELECT TPRSiht;  SKIP
            ENDDO
         NEXT
      NEXT

      Linija()
      ?
      ?? Space( 3 ) + " " + Space( 6 ) + " "
      SELECT TPRSiht; GO TOP
      fPRvi := .T.
      i := 0
      _BrBod := radn->brbod
      IF _brbod = 0
         MsgBeep( "U sifrarniku radnika definisite broj bodova za radnika !" )
      ENDIF

      DO WHILE !Eof()
         ++i
         IF fprvi
            ?? Space( 4 ) + " "
            fprvi := .F.
         ENDIF
         ?? Space( 10 ), Str( aSihtUk[ i ], 10, 2 )
         cPom := id  // napuni Karticu radnika !!!!!
         IF _Brbod <> 0
            _S&cPom := aSihtUk[ i ] / _Brbod
         ENDIF
         SKIP
      ENDDO
      Linija()
      FF
      ENDPRINT

      IF pitanje(, "Zavrsili ste unos sihtarice ?", "D" ) == "D"
         EXIT
      ENDIF


   ENDDO // glavna petlja


   SELECT ld

   RETURN ( NIL )


// --------------------------
// obrada sihtarice
// TODO: mrtva funkcija
// --------------------------
FUNCTION UzmiSiht()

   IF .T.
      MsgBeep( "http://redmine.bring.out.ba/issues/25986" )

      RETURN .F.
   ENDIF

   o_params()

   PRIVATE cZadnjiRadnik := cIdRadn
   PRIVATE cSection := "S"

   RPar( "zr", @cZadnjiRAdnik )


   o_radsiht()


   SELECT radsiht
   SEEK Str( _godina, 4 ) + Str( nMjesec, 2 ) + cZadnjiRadnik + cIdRj
   IF Found() // ovaj je radnik fakat radjen
      SEEK Str( _godina, 4 ) + Str( nMjesec, 2 ) + cidradn + cIdRj
      IF !Found()
         // ako je ovaj radnik vec radjen ne pitaj nista za preuzimanje
         IF pitanje(, 'Zelite li preuzeti sihtaricu od radnika ' + cZadnjiRadnik + ' D/N', 'D' ) == 'D'
            SELECT radsiht
            SEEK Str( _godina, 4 ) + Str( nMjesec, 2 ) + cZadnjiRadnik + cIdRj
            PRIVATE nTSrec := 0
            DO WHILE !Eof() .AND. ( Str( godina, 4 ) + Str( mjesec, 2 ) + idradn + IdRj ) == ( Str( _godina, 4 ) + Str( nMjesec, 2 ) + cZadnjiRadnik + cIdRj )
               SKIP
               nTSrec := RecNo()
               SKIP -1
               Scatter( 'w' )
               wIdRadn := cidradn
               // sve je isto osim sifre radnika
               APPEND BLANK
               Gather( 'w' )
               GO nTSrec
            ENDDO
         ENDIF // pitanje
      ENDIF
   ENDIF

   Unossiht()

   SELECT params
   PRIVATE cSection := "S"
   SELECT radsiht
   SEEK Str( _godina, 4 ) + Str( nMjesec, 2 ) + cIdRadn + cIdRj
   IF Found()  // nesto je bilo u sihtarici
      SELECT params
      cZadnjiRadnik := cIdRadn
      WPar( "zr", cZadnjiRAdnik )
   ENDIF

   SELECT params
   USE
   SELECT radsiht
   USE

   RETURN


STATIC FUNCTION Linija()

   ?
   ?? PadC( "---", 3 ) + " " + Replicate( "-", 6 ) + " "

   fprvi := .T.
   SELECT TPRSiht
   GO TOP
   GO TOP

   DO WHILE !Eof()
      IF fprvi
         ?? Replicate( "-", 4 ) + " "
         fprvi := .F.
      ENDIF
      ?? Replicate( "-", 10 ) + " " + Replicate( "-", 10 ) + " "
      SKIP
   ENDDO

   RETURN ( NIL )


// -------------------------------
// -------------------------------
FUNCTION P_TPRSiht( cId, dx, dy )

   LOCAL nArr

   nArr := Select()
   PRIVATE imekol
   PRIVATE kol

   SELECT ( F_TPRSIHT )
   IF ( !Used() )
      o_tprsiht()
   ENDIF
   SELECT ( nArr )

   ImeKol := { { PadR( "Id", 4 ), {|| id }, "id", {|| .T. }, {|| validacija_postoji_sifra( wid ) } }, ;
      { PadR( "Naziv", 30 ), {||  naz }, "naz" }, ;
      { PadC( "K1", 3 ), {|| PadC( K1, 3 ) }, "k1"  }  ;
      }
   Kol := { 1, 2, 3 }

   RETURN p_sifra( F_TPRSIHT, 1, 10, 55, "Lista: Tipovi primanja u sihtarici", @cId, dx, dy )
