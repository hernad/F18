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


FUNCTION pos_top_narudzbe()

   LOCAL aNiz := {}, cPor, cZaduz, aVrsteP
   PRIVATE cIdPos, cRoba := Space( 60 ), dDatum0, dDatum1, nTop := 10, cSta := "I"

   dDatum0 := dDatum1 := DATE ()

   aDbf := {}
   AAdd ( aDbf, { "IdRoba",   "C", 10, 0 } )
   AAdd ( aDbf, { "Kolicina", "N", 15, 3 } )
   AAdd ( aDbf, { "Iznos",    "N", 20, 3 } )
   AAdd ( aDbf, { "Iznos2",    "N", 20, 3 } )
   AAdd ( aDbf, { "Iznos3",    "N", 20, 3 } )
   pos_cre_pom_dbf( aDbf )

   SELECT ( F_POM )
   IF Used()
      USE
   ENDIF

   my_use_temp( "POM", my_home() + "pom", .F., .T. )

   INDEX ON ( idroba ) TAG "1"
   INDEX ON ( Str( iznos, 20, 3 ) ) TAG "2"
   INDEX ON ( Str( kolicina, 15, 3 ) ) TAG "3"

   SET ORDER TO TAG "1"

   _o_tables()

   PRIVATE cIdPOS := gIdPos
   // IF gVrstaRS <> "K"
   aNiz := { { "Prodajno mjesto", "cIdPos", "cidpos='X' .or. Empty(cIdPos).or.p_pos_kase(@cIdPos)",, } }
   // ENDIF
   AAdd ( aNiz, { "Roba (prazno-sve)", "cRoba",, "@!S30", } )
   AAdd ( aNiz, { "Pregled po Iznosu/Kolicini/Oboje (I/K/O)", "cSta", "cSta$'IKO'", "@!", } )
   AAdd ( aNiz, { "Izvjestaj se pravi od datuma", "dDatum0",,, } )
   AAdd ( aNiz, { "                   do datuma", "dDatum1",,, } )
   AAdd ( aNiz, { "Koliko artikala ispisati?", "nTop", "nTop > 0",, } )
   DO WHILE .T.
      IF !VarEdit( aNiz, 10, 5, 19, 74, ;
            'USLOVI ZA IZVJESTAJ "NAJPROMETNIJI ARTIKLI"', ;
            "B1" )
         CLOSERET
      ENDIF
      cFilterRoba := Parsiraj( cRoba, "IdRoba", "C" )
      IF cFilterRoba <> NIL .AND. dDatum0 <= dDatum1
         EXIT
      ELSEIF cFilterRoba == NIL
         Msg( "Kriterij za robu nije korektno postavljen!" )
      ELSE
         Msg( "'Datum do' ne smije biti stariji nego 'datum od'!" )
      ENDIF
   ENDDO // .t.

   nTotal := 0



   START PRINT CRET
   ?
   // ZagFirma()

   ? PadC ( "NAJPROMETNIJI ARTIKLI", 40 )
   ? PadC ( "-----------------------", 40 )
   ? PadC ( "NA DAN: " + FormDat1 ( danasnji_datum() ), 40 )
   ?
   ? PadC ( "Za period od " + FormDat1 ( dDatum0 ) + " do " + FormDat1 ( dDatum1 ), 40 )
   ?

   pos_top_n_izvuci ( POS_VD_RACUN, dDatum0, cFilterRoba )
   pos_top_n_izvuci ( VD_PRR, dDatum0, cFilterRoba )

   // stampa izvjestaja
   SELECT POM
   IF cSta $ "IO"
      ?
      ? PadC ( "POREDAK PO IZNOSU", 40 )
      ?
      ? PadR( "ID ROBA", 10 ), PadR ( "Naziv robe", 20 ), PadC ( "Vrijednost", 19 )
      ? REPL( "-", 10 ), REPL ( "-", 20 ), REPL ( "-", 19 )
      nCnt := 1
      SET ORDER TO TAG "2"
      GO BOTTOM
      DO WHILE !Bof() .AND. nCnt <= nTop
         select_o_roba( POM->IdRoba )
         ? roba->Id, Left ( roba->Naz, 20 ), Str ( POM->Iznos, 19, 2 )
         SELECT POM
         nCnt++
         SKIP -1
      ENDDO
   ENDIF

   IF cSta $ "KO"

      SELECT POM
      ?
      ? PadC ( "POREDAK PO KOLICINI", 40 )
      ?
      ? PadR( "ID ROBA", 10 ), PadR ( "Naziv robe", 20 ), PadC ( "Kolicina", 15 )
      ? REPL( "-", 10 ), REPL ( "-", 20 ), REPL ( "-", 15 )

      nCnt := 1

      SET ORDER TO TAG "3"
      GO BOTTOM

      DO WHILE !Bof() .AND. nCnt <= nTop
         select_o_roba( POM->IdRoba )
         ? roba->Id, Left ( roba->Naz, 20 ), Str ( POM->Kolicina, 15, 3 )
         SELECT POM
         nCnt++
         SKIP -1
      ENDDO

   ENDIF

   ?


   ENDPRINT

   CLOSE ALL

   RETURN .T.



/*
 *     Punjenje pomocne baze realizacijom po robama
 */

FUNCTION pos_top_n_izvuci( cIdVd, dDatum0, cFilterRoba )

   LOCAL nNeplaca

   seek_pos_doks_2( cIdVd, dDatum0 )

   // SELECT pos_doks
   // SEEK cIdVd + DToS ( dDatum0 )

   DO WHILE !Eof() .AND. pos_doks->IdVd == cIdVd .AND. pos_doks->Datum <= dDatum1

      IF ( !pos_admin() .AND. pos_doks->idpos = "X" ) .OR. ;
            ( pos_doks->IdPos = "X" .AND. AllTrim( cIdPos ) <> "X" ) .OR. ;
            ( !Empty( cIdPos ) .AND. pos_doks->IdPos <> cIdPos )
         SKIP
         LOOP
      ENDIF

      seek_pos_pos( pos_doks->IdPos, pos_doks->IdVd, pos_doks->datum, pos_doks->BrDok )
      IF !( cFilterRoba == ".t." )
         SET FILTER TO &cFilterRoba
      ENDIF
      GO TOP


      DO WHILE !Eof() .AND. POS->( IdPos + IdVd + DToS( datum ) + BrDok ) == pos_doks->( IdPos + IdVd + DToS( datum ) + BrDok )

         select_o_roba( pos->idroba )
         IF roba->( FieldPos( "idodj" ) ) <> 0
            select_o_pos_odj( roba->idodj )
         ENDIF
         nNeplaca := 0
         // IF Right( odj->naz, 5 ) == "#1#0#"  // proba!!!
         // nNeplaca := pos->( Kolicina * Cijena )
         // ELSEIF Right( odj->naz, 6 ) == "#1#50#"
         // nNeplaca := pos->( Kolicina * Cijena ) / 2
         // ENDIF

         // IF gPopVar = "P"
         nNeplaca += pos->( kolicina * NCijena )
         // ENDIF

         SELECT POM
         GO TOP
         HSEEK POS->IdRoba // POM

         IF !Found ()
            APPEND BLANK
            REPLACE IdRoba   WITH POS->IdRoba, ;
               Kolicina WITH POS->Kolicina, ;
               Iznos    WITH POS->Kolicina * POS->Cijena, ;
               iznos3   WITH nNeplaca
            // IF gPopVar == "P"
            REPLACE iznos2   WITH pos->ncijena * pos->kolicina
            // ENDIF
         ELSE
            REPLACE Kolicina WITH Kolicina + POS->Kolicina, ;
               Iznos WITH Iznos + POS->Kolicina * POS->Cijena, ;
               iznos3 WITH iznos3 + nNePlaca
            // IF gPopVar == "P"
            REPLACE iznos2   WITH iznos2 + pos->ncijena * pos->kolicina
            // ENDIF
         END

         SELECT POS
         SKIP

      ENDDO
      SELECT pos_doks
      SKIP

   ENDDO

   RETURN .T.


STATIC FUNCTION _o_tables()

   o_pos_kumulativne_tabele()

   RETURN .T.
