#include "f18.ch"

FUNCTION naprometniji_artikli_prodavnica()

   LOCAL PicDEM := kalk_pic_iznos_bilo_gpicdem()
   LOCAL Pickol := "@Z " + kalk_pic_kolicina_bilo_gpickol()

   qqKonto := "133;"
   qqRoba  := ""
   cSta    := "O"
   dDat0   := Date()
   dDat1   := Date()
   nTop    := 20
   aNiz := {   { "Uslov za prodavnice (prazno-sve)", "qqKonto",              , "@!S30", } }
   AAdd ( aNiz, { "Uslov za robu/artikle (prazno-sve)", "qqRoba",              , "@!S30", } )
   AAdd ( aNiz, { "Pregled po Iznosu/Kolicini/Oboje (I/K/O)", "cSta", "cSta$'IKO'", "@!", } )
   AAdd ( aNiz, { "Izvjestaj se pravi od datuma", "dDat0",              ,         , } )
   AAdd ( aNiz, { "                   do datuma", "dDat1",              ,         , } )
   AAdd ( aNiz, { "Koliko artikala ispisati?", "nTop", "nTop > 0", "999", } )

   o_params()
   PRIVATE cSection := "F", cHistory := " ", aHistory := {}
   Params1()
   RPar( "c2", @qqKonto )
   RPar( "c5", @qqRoba )
   RPar( "d1", @dDat0 ); RPar( "d2", @dDat1 )

   qqKonto := PadR( qqKonto, 60 )
   qqRoba  := PadR( qqRoba, 60 )

   DO WHILE .T.
      IF !VarEdit( aNiz, 9, 1, 19, 78, ;
            'USLOVI ZA IZVJESTAJ "NAJPROMETNIJI ARTIKLI"', "B1" )
         CLOSERET
      ENDIF
      aUsl1 := Parsiraj( qqRoba, "IDROBA", "C" )
      aUsl2 := Parsiraj( qqKonto, "PKONTO", "C" )
      IF aUsl1 <> NIL .AND. aUsl2 <> NIL .AND. dDat0 <= dDat1
         EXIT
      ELSEIF aUsl2 == NIL
         Msg( "Kriterij za prodavnice nije korektno postavljen!" )
      ELSEIF aUsl1 == NIL
         Msg( "Kriterij za robu nije korektno postavljen!" )
      ELSE
         Msg( "'Datum do' ne smije biti stariji nego 'datum od'!" )
      ENDIF
   ENDDO

   WPar( "c2", qqKonto )
   WPar( "c5", qqRoba )
   WPar( "d1", dDat0 )
   WPar( "d2", dDat1 )

   SELECT params
   USE


   find_kalk_za_period( self_organizacija_id(), NIL, NIL, NIL, dDat0, dDat1, "idroba,idvd" )

   cFilt := aUsl1 + " .and. " + aUsl2 + ' .and. PU_I=="5"' + ' .and. !(IDVD $ "12#13#22")'


   SET FILTER TO &cFilt

   nMinI := 999999999999
   nMinK := 999999999999
   aTopI := {}
   aTopK := {}

   MsgO( "Priprema izvještaja..." )

   GO TOP
   DO WHILE !Eof()
      cIdRoba   := IDROBA
      nKolicina := 0
      nIznos    := 0
      DO WHILE !Eof() .AND. IDROBA == cIdRoba
         nKolicina += kolicina
         nIznos    += kolicina * mpcsapp
         SKIP 1
      ENDDO
      IF Len( aTopI ) < nTop
         AAdd( aTopI, { cIdRoba, nIznos } )
         nMinI := Min( nIznos, nMinI )
      ELSEIF nIznos > nMinI
         nPom := AScan( aTopI, {| x | x[ 2 ] <= nMinI } )
         IF nPom < 1 .OR. nPom > Len( aTopI )
            MsgBeep( "nPom=" + Str( nPom ) + " ?!" )
         ENDIF
         aTopI[ nPom ] := { cIdRoba, nIznos }
         nMinI := nIznos
         AEval( aTopI, {| x | nMinI := Min( nMinI, x[ 2 ] ) } )
      ENDIF
      IF Len( aTopK ) < nTop
         AAdd( aTopK, { cIdRoba, nKolicina } )
         nMinK := Min( nKolicina, nMinK )
      ELSEIF nKolicina > nMinK
         nPom := AScan( aTopK, {| x | x[ 2 ] <= nMinK } )
         IF nPom < 1 .OR. nPom > Len( aTopK )
            MsgBeep( "nPom=" + Str( nPom ) + " ?!" )
         ENDIF
         aTopK[ nPom ] := { cIdRoba, nKolicina }
         nMinK := nKolicina
         AEval( aTopK, {| x | nMinK := Min( nMinK, x[ 2 ] ) } )
      ENDIF
   ENDDO

   MsgC()

   ASort( aTopI,,, {| x, y | x[ 2 ] > y[ 2 ] } )
   ASort( aTopK,,, {| x, y | x[ 2 ] > y[ 2 ] } )



   START PRINT CRET
   ?
   Preduzece()
   ?? "Najprometniji artikli za period", ddat0, "-", ddat1
   ?U "Obuhvaćene prodavnice:", iif( Empty( qqKonto ), "SVE", "'" + Trim( qqKonto ) + "'" )
   ?U "Obuhvaćeni artikli   :", iif( Empty( qqRoba ), "SVI", "'" + Trim( qqRoba ) + "'" )
   ?

   IF cSta $ "IO"
      m := AllTrim( Str( Min( nTop, Len( aTopI ) ) ) ) + " NAJPROMETNIJIH ARTIKALA POSMATRANO PO IZNOSIMA:"
      ?
      ? REPL( "-", Len( m ) )
      ?
      ?U PadC( "ŠIFRA", Len( roba->id ) ) + " " + PadC( "NAZIV", 50 ) + " " + PadC( "IZNOS", 20 )
      ? REPL( "-", Len( roba->id ) ) + " " + REPL( "-", 50 ) + " " + REPL( "-", 20 )
      FOR i := 1 TO Len( aTopI )
         cIdRoba := aTopI[ i, 1 ]
         select_o_roba( cIdRoba )
         ? cIdRoba, Left( ROBA->naz, 50 ), PadC( Transform( aTopI[ i, 2 ], picdem ), 20 )
      NEXT
      ? REPL( "-", Len( id ) ) + " " + REPL( "-", 50 ) + " " + REPL( "-", 20 )

   ENDIF

   IF cSta $ "KO"

      IF cSta == "O"
         ?
         ?
         ?
      ENDIF
      m := AllTrim( Str( Min( nTop, Len( aTopK ) ) ) ) + " NAJPROMETNIJIH ARTIKALA POSMATRANO PO KOLICINAMA:"
      ?
      ? REPL( "-", Len( m ) )
      ?
      ?U PadC( "ŠIFRA", Len( roba->id ) ) + " " + PadC( "NAZIV", 50 ) + " " + PadC( "KOLIČINA", 20 )
      ? REPL( "-", Len( roba->id ) ) + " " + REPL( "-", 50 ) + " " + REPL( "-", 20 )

      FOR i := 1 TO Len( aTopK )
         cIdRoba := aTopK[ i, 1 ]
         select_o_roba( cIdRoba )
         ? cIdRoba, Left( ROBA->naz, 50 ), PadC( Transform( aTopK[ i, 2 ], pickol ), 20 )
      NEXT
      ? REPL( "-", Len( id ) ) + " " + REPL( "-", 50 ) + " " + REPL( "-", 20 )

   ENDIF

   FF

   ENDPRINT

   CLOSERET

   RETURN .T.
