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



FUNCTION ld_kartica_plate_za_vise_mjeseci()

   LOCAL nC1 := 20
   LOCAL i

   cIdRadn := fetch_metric( "ld_izvj_radnik", my_user(), Space( LEN_IDRADNIK ) )
   cIdRj := gLDRadnaJedinica
   nMjesec := ld_tekuci_mjesec()
   cMjesec2 := ld_tekuci_mjesec()
   nGodina := ld_tekuca_godina()
   cObracun := gObracun
   cRazdvoji := "N"

   brisi_tmp__ld()
   otvori_tabele()

   cSatiVO := "S"

   Box(, 6, 77 )
   @ box_x_koord() + 1, box_y_koord() + 2 SAY "Radna jedinica (prazno-sve rj): "  GET cIdRJ VALID Empty( cidrj ) .OR. P_LD_RJ( @cidrj )
   @ box_x_koord() + 2, box_y_koord() + 2 SAY "od mjeseca: "  GET  nMjesec  PICT "99"
   @ box_x_koord() + 2, Col() + 2 SAY "do"  GET  cMjesec2  PICT "99"
   @ box_x_koord() + 2, Col() + 2 SAY8 "Obračun:" GET cObracun WHEN ld_help_broj_obracuna( .T., cObracun ) VALID ld_valid_obracun( .T., cObracun )
   @ box_x_koord() + 3, box_y_koord() + 2 SAY "Godina: "  GET  nGodina  PICT "9999"
   @ box_x_koord() + 4, box_y_koord() + 2 SAY "Radnik (prazno-svi radnici):" GET cIdRadn  VALID Empty( cIdRadn ) .OR. P_Radn( @cIdRadn )
   @ box_x_koord() + 5, box_y_koord() + 2 SAY "Razdvojiti za radnika po RJ:" GET cRazdvoji PICT "@!";
      WHEN Empty ( cIdRj ) VALID cRazdvoji $ "DN"
   READ
   clvbox()
   ESC_BCR
   
   IF Empty( cObracun )
      @ box_x_koord() + 6, box_y_koord() + 2 SAY8 "Prikaz sati (S-sabrati sve obračune , 1-obračun 1 , 2-obračun 2, ... )" GET cSatiVO VALID cSatiVO $ "S123456789" PICT "@!"
      READ
      ESC_BCR
   ENDIF
   BoxC()

   set_metric( "ld_izvj_radnik", my_user(), cIdRadn )


   cIdRadn := Trim( cIdradn )
   IF Empty( cIdrj )
      // SET ORDER TO TAG ( ld_index_tag_vise_obracuna( "4" ) )
      // SEEK Str( nGodina, 4 ) + cIdRadn
      seek_ld( NIL, nGodina, NIL, NIL, cIdRadn, "4" )
      cIdrj := ""

   ELSE
      // SET ORDER TO TAG ( ld_index_tag_vise_obracuna( "3" ) )
      // SEEK Str( nGodina, 4 ) + cIdrj + cIdRadn
      seek_ld( cIdRj, nGodina, NIL, NIL, cIdRadn, "3" )

   ENDIF

   IF !Empty( cObracun )
      SET FILTER TO obr = cObracun
   ENDIF

   EOF CRET


   nStrana := 0

   bZagl := {|| zaglavlje_izvjestaja() }

   select_o_vposla( ld->idvposla )
   select_o_ld_rj( ld->idrj )

   SELECT ld

   IF PCount() == 4
      START PRINT RET
   ELSE
      START PRINT CRET
      ?
   ENDIF

   SELECT ld
   nT1 := nT2 := nT3 := nT4 := 0

   DO WHILE !Eof() .AND.  nGodina == godina .AND. idrj = cIdrj .AND. idradn = cIdRadn

      xIdRadn := idradn
      IF cRazdvoji == "N"
         Scatter( "w" )
         FOR i := 1 TO cLDPolja
            cPom := PadL( AllTrim( Str( i ) ), 2, "0" )
            ws&cPom := 0
            wi&cPom := 0
            wUNeto := wUSati := wUIznos := 0
         NEXT
      ENDIF

      IF cRazdvoji == "N"
         select_o_radn( xIdradn )
         select_o_vposla( ld->idvposla )
         select_o_ld_rj( ld->idrj )

         SELECT ld
         Eval( bZagl )
      ENDIF

      DO WHILE !Eof() .AND.  nGodina == godina .AND. idrj = cIdrj .AND. idradn == xIdRadn

         m := "----------------------- --------  ----------------   ------------------"

         select_o_radn( xIdradn )
         SELECT ld

         IF ( mjesec < nMjesec .OR. mjesec > cMjesec2 )
            SKIP
            LOOP
         ENDIF
         Scatter()
         IF cRazdvoji == "D"

            SELECT _LD
            HSEEK xIdRadn + LD->IdRj // _ld
            IF !Found()
               APPEND BLANK
            ENDIF
            Scatter ( "w" )
            FOR i := 1 TO cLDpolja
               cPom := PadL( AllTrim( Str( i ) ), 2, "0" )
               IF !ld_vise_obracuna() .OR. cSatiVO == "S" .OR. cSatiVO == _obr
                  ws&cPom += _S&cPom
               ENDIF
               wi&cPom += _I&cPom
            NEXT
            wUIznos += _UIznos
            IF !ld_vise_obracuna() .OR. cSatiVO == "S" .OR. cSatiVO == _obr
               wUSati += _USati
            ENDIF
            wUNeto += _UNeto
            wIdRj := _IdRj
            wIdRadn := xIdRadn
            Gather( "w" )
            SELECT LD
            SKIP
            LOOP
         ENDIF

         cUneto := "D"
         FOR i := 1 TO cLDPolja
            cPom := PadL( AllTrim( Str( i ) ), 2, "0" )
            select_o_tippr( cPom )
            IF !ld_vise_obracuna() .OR. cSatiVO == "S" .OR. cSatiVO == _obr
               ws&cPom += _S&cPom
            ENDIF
            wi&cPom += _I&cPom
         NEXT


         wUIznos += _UIznos
         IF !ld_vise_obracuna() .OR. cSatiVO == "S" .OR. cSatiVO == _obr
            wUSati += _USati
         ENDIF
         wUNeto += _UNeto

         SELECT ld
         SKIP

      ENDDO

      IF cRazdvoji == "N"
         ? m
         ? _l( " Vrsta                  Opis         sati/iznos             ukupno" )
         ? m
         cUneto := "D"
         FOR i := 1 TO cLDPolja
            cPom := PadL( AllTrim( Str( i ) ), 2, "0" )
            select_o_tippr( cPom )

            IF tippr->uneto == "N" .AND. cUneto == "D"
               cUneto := "N"
               ? m
               ? _l( "UKUPNO NETO:" )
               @ PRow(), nC1 + 8  SAY  wUSati  PICT gpics
               ?? _l( " sati" )
               @ PRow(), 60 SAY wUNeto PICT gpici; ?? "", gValuta
               ? m
            ENDIF

            IF tippr->( Found() ) .AND. tippr->aktivan == "D"
               IF wi&cpom <> 0 .OR. ws&cPom <> 0
                  ? tippr->id + "-" + tippr->naz, tippr->opis
                  nC1 := PCol()
                  IF tippr->fiksan $ "DN"
                     @ PRow(), PCol() + 8 SAY ws&cPom  PICT gpics; ?? " s"
                     @ PRow(), 60 SAY wi&cPom        PICT gpici
                  ELSEIF tippr->fiksan == "P"
                     @ PRow(), PCol() + 8 SAY ws&cPom  PICT "999.99%"
                     @ PRow(), 60 SAY wi&cPom        PICT gpici
                  ELSEIF tippr->fiksan == "B"
                     @ PRow(), PCol() + 8 SAY ws&cPom  PICT "999999"; ?? " b"
                     @ PRow(), 60 SAY wi&cPom        PICT gpici
                  ELSEIF tippr->fiksan == "C"
                     @ PRow(), 60 SAY wi&cPom        PICT gpici
                  ENDIF
               ENDIF
            ENDIF
         NEXT
         ? m
         ?  _l( "UKUPNO ZA ISPLATU" )
         @ PRow(), 60 SAY wUIznos PICT gpici; ?? "", gValuta
         ? m
         IF PRow() > 31
            FF
         ELSE
            ?
            ?
            ?
            ?
         ENDIF
      ELSE
         SELECT _LD
         GO TOP
         select_o_radn( _LD->idradn )
         select_o_vposla( _LD->idvposla )

         SELECT _LD
         Eval( bZagl )
         ?
         WHILE ! Eof()
            select_o_ld_rj( _ld->idrj )
            SELECT _ld
            QOut( "RJ:", idrj, ld_rj->naz )
            ? m
            ? _l( " Vrsta                  Opis         sati/iznos             ukupno" )
            ? m
            //
            Scatter( "w" )
            cUneto := "D"
            FOR i := 1 TO cLDPolja
               cPom := PadL( AllTrim( Str( i ) ), 2, "0" )
               select_o_tippr( cPom )
               IF tippr->uneto == "N" .AND. cUneto == "D"
                  cUneto := "N"
                  ? m
                  ? _l( "UKUPNO NETO:" )
                  @ PRow(), nC1 + 8  SAY  wUSati  PICT gpics; ?? " sati"
                  @ PRow(), 60 SAY wUNeto PICT gpici; ?? "", gValuta
                  ? m
               ENDIF

               IF tippr->( Found() ) .AND. tippr->aktivan == "D"
                  IF wi&cpom <> 0 .OR. ws&cPom <> 0
                     ? tippr->id + "-" + tippr->naz, tippr->opis
                     nC1 := PCol()
                     IF tippr->fiksan $ "DN"
                        @ PRow(), PCol() + 8 SAY ws&cPom  PICT gpics; ?? " s"
                        @ PRow(), 60 SAY wi&cPom        PICT gpici
                     ELSEIF tippr->fiksan == "P"
                        @ PRow(), PCol() + 8 SAY ws&cPom  PICT "999.99%"
                        @ PRow(), 60 SAY wi&cPom        PICT gpici
                     ELSEIF tippr->fiksan == "B"
                        @ PRow(), PCol() + 8 SAY ws&cPom  PICT "999999"; ?? " b"
                        @ PRow(), 60 SAY wi&cPom        PICT gpici
                     ELSEIF tippr->fiksan == "C"
                        @ PRow(), 60 SAY wi&cPom        PICT gpici
                     ENDIF
                  ENDIF
               ENDIF
            NEXT
            ? m
            ?  "UKUPNO ZA ISPLATU U RJ", _LD->IdRj
            @ PRow(), 60 SAY wUIznos PICT gpici
            ?? "", gValuta
            ? m
            IF PRow() > 60 + dodatni_redovi_po_stranici()
               FF
            ELSE
               ?
               ?
            ENDIF
            SELECT _LD
            SKIP
         ENDDO
      ENDIF
      SELECT ld

   ENDDO

   FF
   ENDPRINT
   my_close_all_dbf()

   RETURN



STATIC FUNCTION brisi_tmp__ld()

   o__ld()
   my_dbf_zap()

   RETURN .T.


STATIC  FUNCTION o__ld()

   SELECT ( F__LD )
   IF Used()
      USE
   ENDIF
   my_use ( "_ld" )
   SET ORDER TO TAG "1"

   RETURN .T.


STATIC FUNCTION zaglavlje_izvjestaja()

   ?U "OBRAČUN "

   IF Empty( cObracun )
      ?? "'SVI'"
   ELSE
      ?? "'" + cObracun + "'"
   ENDIF

   ?? " PLATE ZA PERIOD OD " + Str( nMjesec, 2 ) + " DO " + Str( cMjesec2, 2 )
   ?? " / " + Str( godina, 4 )
   ?? " ZA " + Upper( Trim( tip_organizacije() ) )
   ?? " " + AllTrim( self_organizacija_naziv() )
   ? "RJ: " + idrj + " " + AllTrim( ld_rj->naz )
   ? idradn + "-" + RADNIK_PREZ_IME + " Mat.br: " + radn->matbr + " STR.SPR: " + idstrspr
   ? "Vrsta posla: " + idvposla + "-" + AllTrim( vposla->naz )
   ?? "   U radnom odnosu od: "  + DToC( radn->datod )

   RETURN .T.



STATIC FUNCTION otvori_tabele()

   set_tippr_ili_tippr2( cObracun )

   // o_ld_parametri_obracuna()
   // o_ld_rj()
   // o_ld_radn()
   // o_ld_vrste_posla()
   // O_RADKR
   // o_kred()
   o__ld()

   // select_o_ld()

   RETURN .T.
