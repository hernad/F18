/*
 * This file is part of the bring.out knowhow ERP, a free and open source
 * ERP software suite,
 * Copyright (c) 1994-2018 by bring.out d.o.o Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including knowhow ERP specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_knowhow.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */

#include "f18.ch"

STATIC __tbl_suban := "fin_suban"
STATIC __tbl_nalog := "fin_nalog"
STATIC __tbl_anal := "fin_anal"
STATIC __tbl_sint := "fin_sint"


FUNCTION fin_azuriranje_naloga( lAutomatikaAzuriranja )

   LOCAL oServer := sql_data_conn()
   LOCAL aNalozi, nI
   LOCAL cIdFirma, cIdVn, cBrNal
   LOCAL lViseNalogaUPripremi := .F.
   LOCAL lOk := .T.
   LOCAL hParams := hb_Hash()
   LOCAL cOdgovorDupliNalog := "N"
   LOCAL lAutomatskiIzbrisatiPostojeci := .T.
   LOCAL cMsg

   IF ( lAutomatikaAzuriranja == NIL )
      lAutomatikaAzuriranja := .F.
   ENDIF

   o_fin_za_azuriranje()

   IF fin_pripr->( RecCount() == 0 ) //.OR. ( !lAutomatikaAzuriranja .AND. Pitanje(, "Izvršiti ažuriranje fin naloga ? (D/N)?", "D" ) == "N" )
      RETURN .F.
   ENDIF

#ifdef F18_DEBUG_FIN_AZUR
   AltD() // F18_DEBUG_FIN_AZUR
#endif
   aNalozi := fin_nalozi_iz_pripreme_u_matricu()

   IF Len( aNalozi ) > 1
      lViseNalogaUPripremi := .T.
   ENDIF

   IF lViseNalogaUPripremi
      fin_gen_ptabele_auto_bez_stampe()
      o_fin_za_azuriranje()
   ENDIF

   IF !fin_provjera_prije_azuriranja_naloga( lAutomatikaAzuriranja, aNalozi )
      RETURN .F.
   ENDIF

   IF lAutomatikaAzuriranja
      cOdgovorDupliNalog := "D"
   ENDIF

   FOR nI := 1 TO Len( aNalozi ) // brisanje duplih naloga
      altd()
      cIdFirma := aNalozi[ nI, 1 ]
      cIdVn := aNalozi[ nI, 2 ]
      cBrNal := aNalozi[ nI, 3 ]
      IF fin_dokument_postoji( cIdFirma, cIdVn, cBrNal )
         IF lAutomatskiIzbrisatiPostojeci .OR. Pitanje( , "Izbrisati postojeći FIN nalog: "  + cIdFirma + "-" + cIdVn + "-" + cBrNal + " ?", cOdgovorDupliNalog ) == "D"
            IF fin_nalog_brisi_iz_kumulativa( cIdFirma, cIdVn, cBrNal )
               cMsg :=  "Brisanje duplog fin naloga: " + cIdFirma + "-" + cIdVn + "-" + cBrNal
               MsgBeep( cMsg )
               log_write( "F18_DOK_OPER: " + cMsg, 2 )
            ELSE
               MsgBeep( "Greška sa brisanjem FIN naloga " + cIdFirma + "-" + cIdVn + "-" + cBrNal + "!#Poništavam operaciju." )
            ENDIF
         ENDIF
      ENDIF
   NEXT


   FOR nI := 1 TO Len( aNalozi )

      run_sql_query( "BEGIN" )
      cIdFirma := aNalozi[ nI, 1 ]
      cIdVn := aNalozi[ nI, 2 ]
      cBrNal := aNalozi[ nI, 3 ]

      IF fin_dokument_postoji( cIdFirma, cIdVn, cBrNal )
         MsgBeep( "Nalog " + cIdFirma + "-" + cIdVn + "-" + AllTrim( cBrNal ) + " već postoji ažuriran !" )
         automatska_obrada_error( .T. )
         IF !lViseNalogaUPripremi
            run_sql_query( "ROLLBACK" )
            RETURN .F.
         ELSE
            LOOP
         ENDIF
      ENDIF

      IF !fin_azur_sql( oServer, cIdFirma, cIdVn, cBrNal )
         run_sql_query( "ROLLBACK" )
         log_write( "F18_DOK_OPER: greška kod ažuriranja fin naloga: " + cIdFirma + "-" + cIdVn + "-" + cBrNal, 2 )
         MsgBeep( "Problem sa ažuriranjem naloga na SQL server !" )
         RETURN .F.

      ENDIF

      fin_pripr_delete( cIdFirma + cIdVn + cBrNal )
      run_sql_query( "COMMIT" )
      log_write( "F18_DOK_OPER: azuriranje fin naloga: " + cIdFirma + "-" + cIdVn + "-" + cBrNal, 2 )

   NEXT

   SELECT fin_pripr
   my_dbf_pack()
   fin_brisi_p_tabele( .T. )

   RETURN .T.



/*
   Opis: puni matricu sa nalozima iz pripreme, može ih biti različitih
*/

STATIC FUNCTION fin_nalozi_iz_pripreme_u_matricu()

   LOCAL aNalozi := {}
   LOCAL nPos

   SELECT fin_pripr
   SET ORDER TO TAG "1"
   GO TOP

   DO WHILE !Eof()

      nPos := AScan( aNalozi, {| var| VAR[ 1 ] == field->idfirma .AND. ;
         VAR[ 2 ] == field->idvn .AND. ;
         VAR[ 3 ] == field->brnal  } )

      IF nPos == 0
         AAdd( aNalozi, { field->idfirma, field->idvn, field->brnal } )
      ENDIF

      SKIP
   ENDDO

   GO TOP

   RETURN aNalozi



FUNCTION fin_azur_sql( oServer, cIdFirma, cIdVn, cBrNal )

   LOCAL lOkAzuriranje := .T.
   LOCAL _ids := {}
   LOCAL _tmp_id, _count, _tmp_doc, hRec, _msg, nI
   LOCAL _ids_doc := {}
   LOCAL _ids_tmp := {}
   LOCAL _ids_suban := {}
   LOCAL _ids_sint := {}
   LOCAL _ids_anal := {}
   LOCAL _ids_nalog := {}
   LOCAL _n := 1

   Box(, 5, 60 )

   _tmp_id := "x"

   SELECT psuban
   SET ORDER TO TAG "1"
   GO TOP
   SEEK cIdFirma + cIdVn + cBrNal

   _count := 0

   DO WHILE !Eof() .AND. field->idfirma == cIdFirma .AND. field->idvn == cIdVn .AND. field->brnal == cBrNal

      hRec := dbf_get_rec()

      ++ _count

      IF _count == 1

         _tmp_id := hRec[ "idfirma" ] + hRec[ "idvn" ] + hRec[ "brnal" ]

         AAdd( _ids_suban, "#2" + _tmp_id )
         AAdd( _ids_anal, "#2" + _tmp_id )
         AAdd( _ids_sint, "#2" + _tmp_id )

         AAdd( _ids_nalog, _tmp_id )

         @ box_x_koord() + 1, box_y_koord() + 2 SAY "fin_suban -> server: " + _tmp_id

      ENDIF

      IF !sql_table_update( "fin_suban", "ins", hRec )
         lOkAzuriranje := .F.
         EXIT
      ENDIF

      SKIP

   ENDDO


   IF lOkAzuriranje

      @ box_x_koord() + 2, box_y_koord() + 2 SAY "fin_anal -> server"

      SELECT panal
      SET ORDER TO TAG "1"
      GO TOP
      SEEK cIdFirma + cIdVn + cBrNal

      DO WHILE !Eof() .AND. field->idfirma == cIdFirma .AND. field->idvn == cIdVn .AND. field->brnal == cBrNal

         hRec := dbf_get_rec()

         IF !sql_table_update( "fin_anal", "ins", hRec )
            lOkAzuriranje := .F.
            EXIT
         ENDIF

         SKIP

      ENDDO

   ENDIF


   IF lOkAzuriranje

      @ box_x_koord() + 3, box_y_koord() + 2 SAY "fin_sint -> server"

      SELECT psint
      SET ORDER TO TAG "1"
      GO TOP
      SEEK cIdFirma + cIdVn + cBrNal

      DO WHILE !Eof() .AND. field->idfirma == cIdFirma .AND. field->idvn == cIdVn .AND. field->brnal == cBrNal

         hRec := dbf_get_rec()

         IF !sql_table_update( "fin_sint", "ins", hRec )
            lOkAzuriranje := .F.
            EXIT
         ENDIF

         SKIP

      ENDDO

   ENDIF

   IF lOkAzuriranje

      @ box_x_koord() + 4, box_y_koord() + 2 SAY "fin_nalog -> server"

      SELECT pnalog
      SET ORDER TO TAG "1"
      GO TOP
      SEEK cIdFirma + cIdVn + cBrNal

      DO WHILE !Eof() .AND. field->idfirma == cIdFirma .AND. field->idvn == cIdVn .AND. field->brnal == cBrNal

         hRec := dbf_get_rec() // pnalog

         IF !sql_table_update( "fin_nalog", "ins", hRec )
            lOkAzuriranje := .F.
            EXIT
         ENDIF

         SKIP

      ENDDO

   ENDIF

/*
   IF lOkAzuriranje
      lOkAzuriranje := push_ids_to_semaphore( __tbl_suban, _ids_suban ) .AND. ;
         push_ids_to_semaphore( __tbl_sint, _ids_sint  ) .AND. ;
         push_ids_to_semaphore( __tbl_anal, _ids_anal  ) .AND. ;
         push_ids_to_semaphore( __tbl_nalog, _ids_nalog )
   ENDIF
*/

   BoxC()

   RETURN lOkAzuriranje



STATIC FUNCTION fin_provjera_prije_azuriranja_naloga( auto, aListaNaloga )

   LOCAL nSelectArea, nI, nTrec
   LOCAL cIdFirma, cIdVn, cBrNal
   LOCAL _vise_naloga := .F.
   LOCAL lOkAzuriranje := .F.

   nSelectArea := Select()
#ifdef F18_DEBUG_FIN_AZUR
   AltD() // F18_DEBUG_FIN_AZUR
#endif

   IF Len( aListaNaloga ) > 1
      _vise_naloga := .T.
   ENDIF

   IF !_vise_naloga .AND. fin_p_nalog_bez_provjere( auto )
      lOkAzuriranje := .T.
      RETURN lOkAzuriranje
   ENDIF


   IF !fin_p_tabele_provjera( aListaNaloga )

      IF !_vise_naloga
         MsgBeep( "Potrebno izvršiti štampu naloga prije ažuriranja !" )
      ENDIF

      RETURN lOkAzuriranje

   ENDIF

   IF !fin_provjeri_konto_partn( aListaNaloga )
      MsgBeep( "Ispravite greške sa nepostojećim šiframa pa pokusajte ponovo !" )
      RETURN lOkAzuriranje
   ENDIF

   FOR nI := 1 TO Len( aListaNaloga )

      cIdFirma := aListaNaloga[ nI, 1 ]
      cIdVn := aListaNaloga[ nI, 2 ]
      cBrNal := aListaNaloga[ nI, 3 ]

      SELECT fin_pripr
      SET ORDER TO TAG "1"
      GO TOP
      SEEK cIdFirma + cIdVn + cBrNal

      nTrec := RecNo()

      IF Len( AllTrim( field->brnal ) ) < 8
         MsgBeep( "Broj naloga mora biti sa vodećim nulama !" )
         SELECT ( nSelectArea )
         RETURN lOkAzuriranje
      ENDIF

      IF !fin_p_provjeri_redni_broj( cIdFirma, cIdVn, cBrNal )
         SELECT ( nSelectArea )
         RETURN lOkAzuriranje
      ENDIF


      IF !fin_saldo_provjera_psuban( cIdFirma, cIdVn, cBrNal )
         SELECT ( nSelectArea )
         RETURN lOkAzuriranje
      ENDIF

   NEXT

   lOkAzuriranje := .T.

   RETURN lOkAzuriranje


STATIC FUNCTION fin_provjeri_konto_partn( aListaNaloga )

   LOCAL lOkAzuriranje := .F.
   LOCAL _err := {}

   SELECT psuban
   SET ORDER TO TAG "1"
   GO TOP

   DO WHILE !Eof()
      psuban_partner_check( @_err, .T. )
      psuban_konto_check( @_err, .T. )
      SKIP
   ENDDO

   IF Len( _err ) > 0
      fin_brisi_p_tabele( .T. )
      prikazi_greske_provjere_konta_i_partnera( _err )
      o_fin_za_azuriranje()
      SELECT fin_pripr
      GO TOP
      RETURN lOkAzuriranje
   ENDIF

   lOkAzuriranje := .T.

   RETURN lOkAzuriranje


STATIC FUNCTION prikazi_greske_provjere_konta_i_partnera( err )

   LOCAL nI
   LOCAL _cnt := 0
   LOCAL _head, _line

   _head := PadR( "R.br", 5 )
   _head += Space( 1 )
   _head += PadR( "Vrsta", 10 )
   _head += Space( 1 )
   _head += PadR( "Šifra", 10 )
   _head += Space( 1 )
   _head += PadR( "Na rednom broju", 30 )

   _line := Replicate( "-", 5 )
   _line += Space( 1 )
   _line += Replicate( "-", 10 )
   _line += Space( 1 )
   _line += Replicate( "-", 10 )
   _line += Space( 1 )
   _line += Replicate( "-", 30 )

   start_print_editor()
   ?

   ?U "Lista nepostojećih šifara na dokumentu:"
   ? "===================================================="
   ?
   ? _line
   ?U _head
   ? _line

   FOR nI := 1 TO Len( err )
      ? PadL( AllTrim( Str( ++_cnt ) ), 4 ) + "."
      @ PRow(), PCol() + 1 SAY PadR( err[ nI, 1 ], 10 )
      @ PRow(), PCol() + 1 SAY PadR( err[ nI, 2 ], 10 )
      @ PRow(), PCol() + 1 SAY AllTrim( err[ nI, 3 ] )

   NEXT

   ? _line
   ?U "Prije ažuriranja naloga, u šifarnike potrebno ubaciti nabrojane šifre !"


   end_print_editor()

   RETURN .T.





STATIC FUNCTION fin_p_provjeri_redni_broj( cIdFirma, cIdVn, cBrNal )

   LOCAL lOkAzuriranje := .T.
   LOCAL _tmp

   SELECT psuban
   SET ORDER TO TAG "1"
   GO TOP
   SEEK cIdFirma + cIdVn + cBrNal

   DO WHILE !Eof() .AND. field->idfirma == cIdFirma .AND. field->idvn == cIdVn .AND. field->brnal == cBrNal

      _tmp := field->rbr

      SKIP 1

      IF _tmp == field->rbr
         lOkAzuriranje := .F.
         MsgBeep( "Nalog " + cIdFirma + "-" + cIdVn + "-" + cBrNal + " nema ispravne redne brojeve !" )
         RETURN lOkAzuriranje
      ENDIF

   ENDDO

   RETURN lOkAzuriranje





STATIC FUNCTION fin_p_nalog_bez_provjere( auto )

   LOCAL lOkAzuriranje := .F.

   SELECT psuban
   SET ORDER TO TAG "1"
   GO TOP

   IF RecCount2() > 9999 .AND. !auto
      IF Pitanje(, "Staviti na stanje bez provjere (D/N) ?", "N" ) == "D"
         lOkAzuriranje := .T.
      ENDIF
   ENDIF

   RETURN lOkAzuriranje





STATIC FUNCTION fin_p_tabele_provjera( aListaNaloga )

   LOCAL lOkAzuriranje := .F.
   LOCAL nI
   LOCAL cIdFirma, cIdVn, cBrNal

   SELECT psuban
   IF RecCount2() == 0
      RETURN .F.
   ENDIF

   SELECT panal
   IF RecCount2() == 0
      RETURN .F.
   ENDIF

   SELECT psint
   IF RecCount2() == 0
      RETURN .F.
   ENDIF

   FOR nI := 1 TO Len( aListaNaloga )

      cIdFirma := aListaNaloga[ nI, 1 ]
      cIdVn := aListaNaloga[ nI, 2 ]
      cBrNal := aListaNaloga[ nI, 3 ]

      SELECT psuban
      SET ORDER TO TAG "1"
      GO TOP
      SEEK cIdFirma + cIdVn + cBrNal

      IF !Found()
         MsgBeep( "Nalog " + cIdFirma + "-" + cIdVn + "-" + AllTrim( cBrNal ) + " ne postoji u PSUBAN !" )
         RETURN lOkAzuriranje
      ENDIF

   NEXT

   lOkAzuriranje := .T.

   RETURN lOkAzuriranje




STATIC FUNCTION fin_brisi_p_tabele( close_all )

   IF close_all == NIL
      close_all := .F.
   ENDIF

   SELECT PNALOG
   my_dbf_zap()

   SELECT PSUBAN
   my_dbf_zap()

   SELECT PANAL
   my_dbf_zap()

   SELECT PSINT
   my_dbf_zap()

   IF close_all
      my_close_all_dbf()
   ENDIF

   RETURN .T.



FUNCTION psuban_partner_check( arr, silent )

   LOCAL lOkAzuriranje := .T.
   LOCAL nPos

   IF Empty( psuban->idpartner )
      RETURN lOkAzuriranje
   ENDIF

   IF silent == NIL
      silent := .F.
   ENDIF

   select_o_partner( psuban->idpartner )

   IF !Found()

      lOkAzuriranje := .F.

      nPos := AScan( arr, {| val| val[ 1 ] + val[ 2 ] == "PARTN" + psuban->idpartner } )

      IF nPos == 0
         AAdd( arr, { "PARTN", psuban->idpartner, Str( psuban->rbr, 5, 0 ) } )
      ENDIF

      IF !silent
         MsgBeep( "Stavka br." + psuban->rbr + " : Nepostojeća šifra partnera!#Partner id: " + psuban->idpartner )
      ENDIF

   ENDIF

   SELECT psuban

   RETURN lOkAzuriranje



FUNCTION psuban_konto_check( arr, silent )

   LOCAL lOkAzuriranje := .T.
   LOCAL nPos

   IF Empty( psuban->idkonto )
      RETURN lOkAzuriranje
   ENDIF

   IF silent == NIL
      silent := .F.
   ENDIF

   IF !select_o_konto( psuban->idkonto )

      lOkAzuriranje := .F.

      nPos := AScan( arr, {| val| val[ 1 ] + val[ 2 ] == "KONTO" + psuban->idkonto } )

      IF nPos == 0
         AAdd( arr, { "KONTO", psuban->idkonto, Str( psuban->rbr, 5, 0 ) } )
      ENDIF

      IF !silent
         MsgBeep( "Stavka br." + psuban->rbr + " : Nepostojeća šifra konta!#Konto id: " + psuban->idkonto )
      ENDIF

   ENDIF

   SELECT psuban

   RETURN lOkAzuriranje



FUNCTION panal_anal( cNalogId )

   LOCAL hRec

   @ box_x_koord() + 3, box_y_koord() + 2 SAY "ANALITIKA       "

   SELECT panal
   SEEK cNalogId

   DO WHILE !Eof() .AND. cNalogId == IdFirma + IdVn + BrNal

      hRec := dbf_get_rec()

      SELECT ANAL
      APPEND BLANK

      dbf_update_rec( hRec, .F. )

      SELECT PANAL
      SKIP

   ENDDO

   RETURN .T.




FUNCTION psint_sint( cNalogId )

   LOCAL hRec

   @ box_x_koord() + 3, box_y_koord() + 2 SAY "SINTETIKA       "
   SELECT PSINT
   SEEK cNalogId

   DO WHILE !Eof() .AND. cNalogId == IdFirma + IdVn + BrNal

      hRec := dbf_get_rec()

      SELECT SINT

      APPEND BLANK
      dbf_update_rec( hRec, .F. )

      SELECT PSINT
      SKIP

   ENDDO

   RETURN .T.




FUNCTION pnalog_nalog( cNalogId )

   LOCAL hRec

   SELECT pnalog
   SEEK cNalogId

   IF Found()

      hRec := dbf_get_rec()

      SELECT nalog
      APPEND BLANK

      dbf_update_rec( hRec, .F. )

   ELSE

      Beep( 4 )
      Msg( "Greška... ponovi štampu naloga ..." )

   ENDIF

   RETURN .T.



FUNCTION psuban_suban( cNalogId )

   LOCAL nSaldo := 0
   LOCAL nC := 0
   LOCAL hRec, hRec2

   @ box_x_koord() + 3, box_y_koord() + 2 SAY "SUBANALITIKA   "


   SELECT PSUBAN
   SEEK cNalogId

   find_suban_by_broj_dokumenta( psuban->idfirma, psuban->idvn, psuban->brnal, .T. )


   SELECT PSUBAN
   nC := 0

   DO WHILE !Eof() .AND. cNalogId == IdFirma + IdVn + BrNal

      @ box_x_koord() + 3, box_y_koord() + 25 SAY ++nC  PICT "99999999999"

      hRec := dbf_get_rec()

      IF hRec[ "d_p" ] == "1"
         nSaldo := hRec[ "iznosbhd" ]
      ELSE
         nSaldo := -hRec[ "iznosbhd" ]
      ENDIF

      find_suban_by_konto_partner( hRec[ "idfirma" ], hRec[ "idkonto" ], hRec[ "idpartner" ], hRec[ "brdok" ] )

      nRec := RecNo()
      DO WHILE  !Eof() .AND. ( hRec[ "idfirma" ] + hRec[ "idkonto" ] + hRec[ "idpartner" ] + hRec[ "brdok" ] ) == ( IdFirma + IdKonto + IdPartner + BrDok )
         IF hRec[ "d_p" ] == "1"
            nSaldo += field->IznosBHD
         ELSE
            nSaldo -= field->IznosBHD
         ENDIF
         SKIP
      ENDDO

      IF Abs( Round( nSaldo, 3 ) ) <= gnLOSt

         GO nRec
         DO WHILE  !Eof() .AND. ( hRec[ "idfirma" ] + hRec[ "idkonto" ] + hRec[ "idpartner" ] + hRec[ "brdok" ] ) == ( IdFirma + IdKonto + IdPartner + BrDok )

            hRec2 := dbf_get_rec()
            hRec2[ "otvst" ] := "9"
            update_rec_server_and_dbf( "fin_suban", hRec2, 1, "FULL" )

            SKIP

         ENDDO
         hRec[ "otvSt" ] := "9"

      ENDIF

      SELECT SUBAN
      APPEND BLANK

      dbf_update_rec( hRec, .T. )

      SELECT PSUBAN
      SKIP

   ENDDO

   RETURN .T.



FUNCTION fin_pripr_delete( cNalogId )

   LOCAL nTrec

   SELECT fin_pripr
   SEEK cNalogId

   // @ box_x_koord() + 3, box_y_koord() + 2 SAY8 "BRIŠEM PRIPREMU "
   MsgO( "Brisanje fin_pripr" )
   my_flock()

   DO WHILE !Eof() .AND. cNalogId == IdFirma + IdVn + BrNal

      SKIP
      nTrec := RecNo()
      SKIP -1
      DELETE
      GO ( nTrec )

   ENDDO

   MsgC()

   RETURN .T.


FUNCTION fin_dokument_postoji( cIdFirma, cIdVn, cBrNal )

   LOCAL lExist := .F.
   LOCAL cWhere

   cWhere := "idfirma = " + sql_quote( cIdFirma )
   cWhere += " AND idvn = " + sql_quote( cIdVn )
   cWhere += " AND brnal = " + sql_quote( cBrNal )

   IF table_count( f18_sql_schema( "fin_nalog" ), cWhere ) > 0
      lExist := .T.
   ENDIF

   RETURN lExist



FUNCTION o_fin_za_azuriranje()

   my_close_all_dbf()

   //o_konto()
   //o_partner()
   //o_sifk()
   //o_sifv()

   o_suban()
   o_anal()
   o_sint()
   o_nalog()

   o_fin_psuban()
   o_fin_panal()
   o_fin_psint()
   o_fin_pnalog()

   o_fin_pripr()

   RETURN .T.
