/*
 * This file is part of the bring.out FMK, a free and open source
 * accounting software suite,
 * Copyright (c) 1994-2018 by bring.out d.o.o Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including knowhow ERP specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_knowhow.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */

#include "f18.ch"

STATIC s_cXlsxName := NIL
STATIC s_pWorkBook, s_pWorkSheet, s_nWorkSheetRow
STATIC s_pMoneyFormat, s_pDateFormat

FUNCTION fin_pregled_promjena_na_racunu()

   LOCAL GetList := {}

   qqIDVN  := "I1;I2;"
   qqKonto := "20;"
   qqKonto2 := ""
   dOd     := dDo := Date()
   cNazivFirme := self_organizacija_naziv()
   GetList := {}

   PRIVATE picBHD := FormPicL( gPicBHD, 16 )
   PRIVATE picDEM := FormPicL( pic_iznos_eur(), 12 )

   o_params()
   PRIVATE cSection := "o", cHistory := " ", aHistory := {}
   RPar( "q1", @qqIDVN )
   RPar( "q2", @qqKonto )
   RPar( "q6", @qqKonto2 )
   RPar( "q3", @dOd )
   RPar( "q4", @dDo )
   RPar( "q5", @cNazivFirme )
   SELECT PARAMS
   USE

   qqIDVN      := PadR( qqIDVN, 60 )
   qqKonto     := PadR( qqKonto, 60 )
   qqKonto2     := PadR( qqKonto2, 60 )
   cNazivFirme := PadR( cNazivFirme, 60 )


   Box( "#PREGLED PROMJENA NA RACUNU", 8, 75 )
   DO WHILE .T.
      @ box_x_koord() + 2, box_y_koord() + 2 SAY8 "Vrste naloga za knjizenje izvoda:" GET qqIDVN  PICT "@S20"
      @ box_x_koord() + 3, box_y_koord() + 2 SAY8 "Konto/konta ziro racuna         :" GET qqKonto PICT "@S20"
      @ box_x_koord() + 4, box_y_koord() + 2 SAY8 "Protukonta                      :" GET qqKonto2 PICT "@S20"
      @ box_x_koord() + 5, box_y_koord() + 2 SAY8 "Period od datuma:" GET dOd
      @ box_x_koord() + 6, Col() + 2 SAY "do datuma:" GET dDo
      @ box_x_koord() + 7, box_y_koord() + 2 SAY "Puni naziv firme:" GET cNazivFirme PICT "@S35"
      READ
      ESC_BCR
      cUslovIDVN := Parsiraj( qqIDVN, "IDVN" )
      cUslovKonto := Parsiraj( qqKonto, "IDKONTO" )
      cUslovKonto2 := Parsiraj( qqKonto2, "IDKONTO" )
      IF cUslovIDVN <> NIL .AND. cUslovKonto <> NIL .AND. cUslovKonto2 <> NIL
         EXIT
      ENDIF
   ENDDO
   BoxC()

   s_cXlsxName := my_home_root() + "uplate_" + dtos(dOd) + "_" + dtos(dDo) + ".xlsx"
  
   qqIDVN      := Trim( qqIDVN      )
   qqKonto     := Trim( qqKonto     )
   qqKonto2     := Trim( qqKonto2     )
   cNazivFirme := Trim( cNazivFirme )

   o_params()
   PRIVATE cSection := "o", cHistory := " ", aHistory := {}
   WPar( "q1", qqIDVN )
   WPar( "q2", qqKonto )
   WPar( "q6", qqKonto2 )
   WPar( "q3", dOd )
   WPar( "q4", dDo )
   WPar( "q5", cNazivFirme )
   SELECT PARAMS
   USE

   //o_konto()
   //o_partner()
   //o_suban()


   //IF !Empty( dOd ); cFilter += ( ".and. DATDOK>=" + dbf_quote( dOd ) ); ENDIF
   //IF !Empty( dDo ); cFilter += ( ".and. DATDOK<=" + dbf_quote( dDo ) ); ENDIF

   MsgO( "Preuzimanje podataka sa SQL servera ..." )
   find_suban_za_period( NIL, dOd, dDo, "idfirma,datdok,idkonto,idpartner,brdok" )
   Msgc()

   //cSort := "dtos(datdok)"
   cFilter := cUslovIDVN
   //INDEX ON &cSort TO "SUBTMP" FOR &cFilter
   SET FILTER TO &cFilter
   // SET FILTER TO &cFilter
   GO TOP

   nDug := 0
   nPot := 0

   m := "------ -------- " + REPL( "-", FIELD_PARTNER_ID_LENGTH ) + " " + REPL( "-", 40 ) + " " + REPL( "-", 16 )
   z := "R.BR. * DATUM  *" + PadC( "PARTN.", FIELD_PARTNER_ID_LENGTH ) + "*" + PadC( "NAZIV PARTNERA ILI OPIS PROMJENE", 40 ) + "*" + PadC( "UPLATA KM", 16 )

   IF !start_print()
      RETURN .F.
   ENDIF
   nStranica := 0
   ZagPPR( "U" )

   nCnt := 0

   GO TOP
   DO WHILE !Eof()

      IF PRow() > 60 + dodatni_redovi_po_stranici()
         FF
         ZagPPR( "U" )
      ENDIF

      IF &cUslovKonto // koji blentav izvjestaj - zadajes konto koji preskaces
         SKIP 1
         LOOP
      ENDIF

      IF suban->d_p == "2" // najcesce su to konta kupaca
         IF ! &cUslovKonto2 
            SKIP 1
            LOOP
         ENDIF

         ? Str( ++nCnt, 6 ), promjene_redIspisa("2")
         xlsx_export_fill_row()
         nPot += iznosbhd
      ENDIF

      SKIP

   ENDDO

   ? m
   ? "UKUPNO UPLATE" + PadL( Transform( nPot, picbhd ), 67 )
   ? m

   ?

   IF PRow() > 60 + dodatni_redovi_po_stranici()
      FF
      ZagPPR( "I" )
   ELSE
      ? "PREGLED ISPLATA:"
      ? m; ? z; ? m
   ENDIF

   nCnt := 0

   GO TOP
   DO WHILE !Eof()

      IF PRow() > 60 + dodatni_redovi_po_stranici()
         FF
         ZagPPR( "I" )
      ENDIF

      IF &cUslovKonto
         SKIP 1
         LOOP
      ENDIF

      IF suban->d_p == "1" // najcesce konta dobavljaca
         IF ! &cUslovKonto2 
            SKIP 1
            LOOP
         ENDIF
         ? Str( ++nCnt, 6 ), promjene_redIspisa("1")
         nDug += iznosbhd
      ENDIF

      SKIP

   ENDDO

   ? m
   ? "UKUPNO ISPLATE" + PadL( Transform( nDug, picbhd ), 66 )
   ? m

   FF
   end_print()

   my_close_all_dbf()
   workbook_close( s_pWorkBook )
   s_pWorkBook := NIL
   s_pWorkSheet := NIL
   f18_open_mime_document( s_cXlsxName )

   RETURN .T.



/* RedIspisa()
 *
 */

STATIC FUNCTION promjene_redIspisa(cDP)

   LOCAL cVrati := ""

   cVrati := DToC( datdok ) + " " + idpartner + " "
   IF Empty( idpartner )
      cVrati += PadR( opis, 40 )
   ELSE
      PushWa()
      select_o_partner( field->idpartner )
      cVrati += PadR( partn->naz, 40 )
      PopWa()
   ENDIF

   cVrati += ( " " + Transform( iznosbhd, picbhd ) )


   RETURN cVrati

   
/* ZagPPR(cI)
 *     Zaglavlje pregleda promjena na racunu
 *   param: cI
 */
STATIC FUNCTION ZagPPR( cI )

   ? cNazivFirme
   ? PadL( "Str." + AllTrim( Str( ++nStranica ) ), 80 )
   ? PadC(  "PREGLED PROMJENA NA RACUNU", 80 )
   ? PadC( "ZA PERIOD " + DToC( dOd ) + " - " + DToC( dDo ), 80 )
   ?
   IF cI == "U"
      ? "PREGLED UPLATA:"
   ELSE
      ? "PREGLED ISPLATA:"
   ENDIF
   ? m; ? z; ? m

RETURN .T.


STATIC function get_partn_naz(cIdPartner)
  LOCAL cNaziv
  PushWa()
  select_o_partner( cIdPartner )
  cNaziv := PadR( partn->naz, 60 )
  PopWa()

return cNaziv

STATIC FUNCTION xlsx_export_fill_row()

   LOCAL nI
   LOCAL aKolona
   LOCAL bPartnNaz := { |cIdPartner| get_partn_naz( cIdPartner ) }

   aKolona := {}

   AADD(aKolona, { "C", "PartnerId", 12, suban->idpartner })
   AADD(aKolona, { "C", "Naziv", 65, Eval(bPartnNaz, suban->idpartner)})

   AADD(aKolona, { "D", "Dat.Dok", 15, suban->datdok })
   AADD(aKolona, { "C", "Opis", 80, trim(suban->opis) })
   AADD(aKolona, { "M", "Iznos", 25, suban->iznosbhd })

   AADD(aKolona, { "C", "Konto", 7, suban->idkonto})
   AADD(aKolona, { "C", "FIN nalog", 20, suban->idfirma + "-" + suban->idvn + "-" + suban->brnal + "/" + Alltrim(Str(suban->rbr)) })

   IF s_pWorkSheet == NIL

         s_pWorkBook := workbook_new( s_cXlsxName )
         s_pWorkSheet := workbook_add_worksheet(s_pWorkBook, NIL)
      
         s_pMoneyFormat := workbook_add_format(s_pWorkBook)
         format_set_num_format(s_pMoneyFormat, /*"#,##0"*/ "#0.00" )
      
         s_pDateFormat := workbook_add_format(s_pWorkBook)
         format_set_num_format(s_pDateFormat, "d.mm.yy")
         
            
         /* Set the column width. */
         for nI := 1 TO LEN(aKolona)
            // worksheet_set_column(lxw_worksheet *self, lxw_col_t firstcol, lxw_col_t lastcol, double width, lxw_format *format)
            worksheet_set_column(s_pWorkSheet, nI - 1, nI - 1, aKolona[ nI, 3], NIL)
         next
      
         //nema smisla header kada imamo vise konta ili vise partnera
         //worksheet_write_string( s_pWorkSheet, 0, 0,  "Konto:", NIL)
         //worksheet_write_string( s_pWorkSheet, 0, 1,  hb_StrToUtf8(cIdKonto + " - " + Trim( cKontoNaziv)), NIL)
         //worksheet_write_string( s_pWorkSheet, 1, 0,  "Partner:", NIL)
         //worksheet_write_string( s_pWorkSheet, 1, 1,  hb_StrToUtf8(cIdPartner + " - " + Trim(cPartnerNaziv)), NIL)
         
         /* Set header */
         s_nWorkSheetRow := 0
         for nI := 1 TO LEN(aKolona)
            worksheet_write_string( s_pWorkSheet, s_nWorkSheetRow, nI - 1,  aKolona[nI, 2], NIL)
         next     
   ENDIF
      
      
   s_nWorkSheetRow++
      
   FOR nI := 1 TO LEN(aKolona)
         IF aKolona[ nI, 1 ] == "C"
            worksheet_write_string( s_pWorkSheet, s_nWorkSheetRow, nI - 1,  hb_StrToUtf8(aKolona[nI, 4]), NIL)
         ELSEIF aKolona[ nI, 1 ] == "M"
            worksheet_write_number( s_pWorkSheet, s_nWorkSheetRow, nI - 1,  aKolona[nI, 4], s_pMoneyFormat)
         ELSEIF aKolona[ nI, 1 ] == "N"
            worksheet_write_number( s_pWorkSheet, s_nWorkSheetRow, nI - 1,  aKolona[nI, 4], NIL)
         ELSEIF aKolona[ nI, 1 ] == "D"
            worksheet_write_datetime( s_pWorkSheet, s_nWorkSheetRow, nI - 1,  aKolona[nI, 4], s_pDateFormat)
         ENDIF
   NEXT
               
  RETURN .T.  
