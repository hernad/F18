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

FUNCTION pos_odredi_smjenu( lOdredi )

   LOCAL cOK := " "
   PRIVATE dDatum := danasnji_datum()
   PRIVATE cSmjena := Str( Val( gSmjena ) + 1, Len( gSmjena ) )
   PRIVATE d_Pos := d_Doks := CToD( "" )
   PRIVATE s_Pos := s_Doks := " "


   cSmjena := "1"
   gSmjena := cSmjena

   pos_status_traka()
   CLOSERET


   IF lOdredi == nil
      lOdredi := .T.
   ENDIF

   o_pos__pos()
   // o_pos_doks()
   // SET ORDER TO TAG "2"  // IdVd+DTOS (Datum)+Smjena
   seek_pos_doks( NIL, POS_VD_RACUN, NIL, NIL, "2" ) // + Chr ( 254 )
   IF Eof() .OR. pos_doks->IdVd <> POS_VD_RACUN
      SKIP -1
   ENDIF

   // ako je slucajno mijenjan IdPos
   DO WHILE !Bof() .AND. pos_doks->IdVd == POS_VD_RACUN .AND. pos_doks->IdPos <> gIdPos
      SKIP -1
   ENDDO
   IF pos_doks->IdVd == POS_VD_RACUN
      d_Doks := pos_doks->Datum     // posljednji datum i smjena u kojoj
      s_Doks := pos_doks->Smjena    // je kasa radila, prema DOKS
   ENDIF

   SELECT _POS
   SET ORDER TO TAG "2"
   SEEK "42" // _POS
   IF Found()
      // d_Pos := _POS->Datum
      DO WHILE !Eof() .AND. _POS->IdVd == POS_VD_RACUN
         IF _POS->m1 <> "Z"
            // racun nije zakljucen, a samo mi je to interesantno
            d_Pos := _POS->Datum
            IF _POS->Smjena > s_Pos
               s_Pos := _POS->Smjena
            ENDIF
         ENDIF
         SKIP
      ENDDO
   ENDIF

   IF d_Pos > d_Doks
      // postoji promet u _POS i to nezakljucen
      dDatum := d_Pos
      cSmjena := s_Pos
   ENDIF


   Box(, 8, 50 )
   @ box_x_koord(), box_y_koord() + 1 SAY " DEFINISANJE DATUMA " COLOR f18_color_invert()

   DO WHILE !( cOK $ "Dd" )
      BoxCLS()
      @ box_x_koord() + 2, box_y_koord() + 5 SAY " DATUM:" GET dDatum VALID DatumOK ()
      @ box_x_koord() + 4, box_y_koord() + 5 SAY "SMJENA:" GET cSmjena VALID cSmjena $ "123"
      SET CURSOR ON
      @ box_x_koord() + 6, box_y_koord() + 5 SAY "Unos u redu (D/N)" GET cOK VALID cOK $ "DN" PICT "@!"
      READ
      IF LastKey() == K_ESC
         LOOP
      ENDIF
      IF ProvKonzBaze( dDatum, cSmjena )
         EXIT
      ENDIF
      cOK := " "
   ENDDO
   BoxC()

   gSmjena := cSmjena


   pos_status_traka()
   CLOSE ALL

   RETURN .T.



STATIC FUNCTION DatumOK()

   IF dDatum > Date()
      MsgBeep( "Morate unijeti datum jedna ili manji od danasnjeg!" )
      RETURN ( .F. )
   ENDIF

   RETURN ( .T. )



STATIC FUNCTION SmjenaOK()

   IF Empty( s_Pos )
      // nema prometa u _POS (nezakljucenog)
      IF d_Doks == dDatum .AND. cSmjena < s_Doks
         MsgBeep ( "Postoje zakljuceni racuni iz smjene " + cSmjena + "!" )
         IF Pitanje(, "Zelite li nastaviti?", "N" ) == "N"
            RETURN ( .F. )
         ENDIF
      ENDIF
      RETURN ( .T. )
   ENDIF

   IF cSmjena > s_Pos
      MsgBeep ( "Postoje NEZAKLJUCENI racuni iz smjene " + cSmjena + "!" )
      IF Pitanje(, "Zelite li nastaviti?", "N" ) == "N"
         RETURN ( .F. )
      ENDIF
   ENDIF

   IF cSmjena < s_Pos
      MsgBeep ( "Postoje NEZAKLJUCENI racuni iz starije smjene " + cSmjena + "!" )
      RETURN ( .F. )
   ENDIF

   RETURN ( .T. )
// }



/* ProvKonzBaze(dDatum,cSmjena)
 *     Provjerava konzistentnost podataka.
 *     Ako su svi racuni zakljuceni ova funkcija ZAPPuje POS.
 *   param: dDatum
 *   param: cSmjena
 */

FUNCTION ProvKonzBaze( dDatum, cSmjena )

   // {
   LOCAL dPrevDat
   LOCAL cPrevSmj
   LOCAL aRadnici := {}
   LOCAL nA

   IF Empty( d_POS )
      // nema nezakljucenog prometa u _POS
      ? dDatum, d_Doks, cSmjena, s_Doks
      IF ( dDatum < d_DOKS ) .OR. ( dDatum == d_DOKS ) .AND. ( cSmjena < s_DOKS )
         MsgBeep ( "Postoji zakljucen promet na#datum " + FormDat1 ( d_DOKS ) + " u smjeni " + s_DOKS )
         IF !pos_admin()
            MsgBeep ( "Vraćate se na unos!" )
            RETURN ( .F. )
         ELSE
            MsgBeep ( "Rad nastavlja SISTEM ADMINISTRATOR!!!" )
         ENDIF
      ENDIF
      IF !( d_DOKS == dDatum .AND. s_DOKS == cSmjena )
         SELECT _POS
         my_dbf_zap()
      ENDIF
      RETURN .T.
   ENDIF

   IF d_POS == dDatum
      // ima nezakljucenog prometa
      IF cSmjena < s_Pos
         MsgBeep ( "Postoje NEZAKLJUCENI racuni iz starije smjene " + cSmjena + "!#" + "Vracate se na unos!!!" )
         CLOSE ALL
         RETURN ( .F. )
      ENDIF
      // IF gVsmjene == "D"
      // MsgBeep ( "POTREBNO JE UNIJETI RACUNE KOJE STE IZDAVALI#" + "BEZ UNOSA U KASU", 20 )
      // ENDIF
      CLOSE ALL
      RETURN ( .T. )
   ENDIF

   // IF gVsmjene == "N"
   SELECT _POS
   my_dbf_zap()
   // RETURN .T.
   // ENDIF


   RETURN .T.
