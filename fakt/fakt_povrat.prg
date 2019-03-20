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


FUNCTION povrat_fakt_dokumenta( cIdFirma, cIdTipDok, cBrDok )

   LOCAL hParams := hb_Hash()
   LOCAL lBrisatiKumulativ := .T.
   LOCAL hRec
   LOCAL _field_ids, _where_block
   LOCAL nTrec
   LOCAL oFaktAttr, hAttrId
   LOCAL lOk := .T.
   LOCAL nRet := 0
   LOCAL GetList := {}
   LOCAL cTabela

   IF ( PCount() == 0 )
      hParams[ "idfirma" ]  := self_organizacija_id()
      hParams[ "idtipdok" ] := Space( 2 )
      hParams[ "brdok" ]    := Space( 8 )
   ELSE
      hParams[ "idfirma" ]  := cIdFirma
      hParams[ "idtipdok" ] := cIdTipDok
      hParams[ "brdok" ]    := cBrDok
   ENDIF

   // o_fakt_dbf()
   select_o_fakt_pripr()
   // o_fakt_doks2_dbf()
   // o_fakt_doks_dbf()

   // SELECT fakt
   // SET FILTER TO

   // SET ORDER TO TAG "1"

   IF PCount() == 0
      IF !uslovi_za_povrat_dokumenta( @hParams )
         my_close_all_dbf()
         RETURN nRet
      ENDIF
   ENDIF

   IF !dokument_se_moze_vratiti_u_pripremu( hParams )
      my_close_all_dbf()
      RETURN nRet
   ENDIF

   cIdFirma  := hParams[ "idfirma" ]
   cIdTipDok := hParams[ "idtipdok" ]
   cBrDok    := PADR( hParams[ "brdok" ], FIELD_LEN_FAKT_BRDOK )

   IF Pitanje( "FAKT_POV_DOK", "Dokument " + cIdFirma + "-" + cIdTipDok + "-" + cBrDok + " vratiti u pripremu (D/N) ?", "D" ) == "N"
      my_close_all_dbf()
      RETURN nRet
   ENDIF

   IF !seek_fakt( cIdFirma, cIdTipDok, cBrDok )
      MsgBeep( "Traženi dokument: " + cIdFirma  + "-" + cIdTipDok + "-" + cBrDok + " ne postoji ažuriran u fakt_fakt !?" )
   ENDIF

   IF ( fakt->m1 == "X" )
      MsgBeep( "Radi se o izgenerisanom dokumentu !" )
      IF Pitanje( "IZGEN_CONT", "Želite li nastaviti (D/N) ?", "N" ) == "N"
         my_close_all_dbf()
         RETURN nRet
      ENDIF
   ENDIF


   fakt_kopiraj_dokument_u_tabelu_pripreme( cIdFirma, cIdTipDok, cBrDok )

   hAttrId := hb_Hash()
   hAttrId[ "idfirma" ] := cIdFirma
   hAttrId[ "idtipdok" ] := cIdTipDok
   hAttrId[ "brdok" ] := cBrDok

   oFaktAttr := DokAttr():New( "fakt", F_FAKT_ATTR )
   oFaktAttr:hAttrId := hAttrId
   oFaktAttr:get_attr_from_server_to_dbf()

   // IF test == .T.
   // lBrisatiKumulativ := .T.
   // ELSE
   lBrisatiKumulativ := Pitanje( "FAKT_POV_KUM", "Želite li izbrisati dokument iz datoteke kumulativa (D/N) ?", "N" ) == "D"
   // ENDIF

   IF !lBrisatiKumulativ
      resetuj_markere_generisanog_dokumenta( cIdFirma, cIdTipDok, cBrDok )
   ENDIF

   IF lBrisatiKumulativ

      seek_fakt( "XX" )
      seek_fakt_doks( "XX" )
      seek_fakt_doks2( "XX" )

      run_sql_query( "BEGIN" )
      IF !f18_lock_tables( { "fakt_fakt", "fakt_doks", "fakt_doks2" }, .T. )
         run_sql_query( "ROLLBACK" )
         MsgBeep( "Ne mogu zaključati fakt tablele.#Prekidam operaciju." )
         RETURN nRet
      ENDIF

      Box(, 5, 70 )

      @ box_x_koord() + 4, box_y_koord() + 2 SAY "brisanje : fakt_fakt_atributi"
      lOk := oFaktAttr:delete_attr_from_server()


      IF lOk
         cTabela := "fakt_fakt"
         @ box_x_koord() + 1, box_y_koord() + 2 SAY "brisanje : " + cTabela
         // select_o_fakt_dbf()
         lOk := delete_rec_server_and_dbf( cTabela, hParams, 2, "CONT" )
      ENDIF


      IF lOk
         cTabela := "fakt_doks"
         @ box_x_koord() + 2, box_y_koord() + 2 SAY "brisanje : " + cTabela
         // select_o_fakt_doks_dbf()
         lOk := delete_rec_server_and_dbf( cTabela, hParams, 1, "CONT" )
      ENDIF


      IF lOk
         cTabela := "fakt_doks2"
         @ box_x_koord() + 3, box_y_koord() + 2 SAY "brisanje : " + cTabela
         // select_o_fakt_doks2_dbf()

         lOk := delete_rec_server_and_dbf( cTabela, hParams, 1, "CONT" )
      ENDIF

      BoxC()

      IF lOk
         nRet := 1
         hParams := hb_Hash()
         hParams[ "unlock" ] := { "fakt_fakt", "fakt_doks", "fakt_doks2" }
         run_sql_query( "COMMIT", hParams )
         log_write( "F18_DOK_OPER: fakt povrat dokumenta u pripremu: " + cIdFirma + "-" + cIdTipDok + "-" + cBrDok, 2 )

      ELSE
         run_sql_query( "ROLLBACK" )
         log_write( "F18_DOK_OPER: greška kod povrata dokumenta u pripremu: " + cIdFirma + "-" + cIdTipDok + "-" + cBrDok, 2 )
         MsgBeep( "Greška kod povrata dokumenta u pripremu.#Operacija prekinuta." )
      ENDIF

   ENDIF

   my_close_all_dbf()

   RETURN nRet



/*
    Opis: resetuje markere generisanog dokumenta u pripremi nakon povrata dokumenta
 */

STATIC FUNCTION resetuj_markere_generisanog_dokumenta( cIdFirma, cIdTipDok, cBrDok )

   LOCAL hRec

   select_o_fakt_pripr()
   GO TOP
   SET ORDER TO TAG "1"
   HSEEK cIdFirma + cIdTipDok + cBrDok // fakt_pripr

   DO WHILE !Eof() .AND. fakt_pripr->( field->idfirma + field->idtipdok + field->brdok ) ==  cIdFirma + cIdTipDok + cBrDok
      IF fakt_pripr->m1 == "X"
         hRec := dbf_get_rec()
         hRec[ "m1" ] := Space( 1 )
         dbf_update_rec( hRec )
      ENDIF
      SKIP
   ENDDO

   RETURN .T.



STATIC FUNCTION fakt_kopiraj_dokument_u_tabelu_pripreme( cIdFirma, cIdTipDok, cBrDok )

   LOCAL hRec

   select_o_fakt_pripr()

   SELECT fakt // ranije otvoren sa seek_fakt
   DO WHILE !Eof() .AND. cIdFirma == fakt->idfirma .AND. cIdTipDok == fakt->idtipdok .AND. PADR( cBrDok, FIELD_LEN_FAKT_BRDOK ) == PADR( fakt->brdok, FIELD_LEN_FAKT_BRDOK )

      //SELECT fakt
      hRec := dbf_get_rec()
      SELECT fakt_pripr
      APPEND BLANK
      dbf_update_rec( hRec )

      SELECT fakt
      SKIP

   ENDDO

   RETURN .T.





FUNCTION fakt_povrat_po_kriteriju( cBrDok, dDatdok, cIdTipDok, cIdFirma )

   LOCAL nRec
   LOCAL nTrec
   LOCAL hParams := hb_Hash()
   LOCAL cFilter
   LOCAL cIdFirmaTekuci
   LOCAL cBrDokTekuci
   LOCAL cIdTipDokTekuci
   LOCAL hRec
   LOCAL lOk := .T.

   IF PCount() <> 0

      hParams[ "brdok" ] := PadR( cBrDok, 200 )

      IF dDatdok == NIL
         dDatdok := CToD( "" )
      ENDIF

      hParams[ "datumi" ] := PadR( DToC( dDatdok ), 200 )

      IF cIdTipDok == NIL
         cIdTipDok := ";"
      ENDIF

      hParams[ "idtipdok" ] := PadR( cIdTipDok, 200 )
      hParams[ "rj" ] := self_organizacija_id()

   ELSE

      hParams[ "brdok" ] := Space( 200 )
      hParams[ "datumi" ] := Space( 200 )
      hParams[ "idtipdok" ] := Space( 200 )
      hParams[ "rj" ] := self_organizacija_id()

   ENDIF

   // o_fakt_dbf()
   // o_fakt_pripr()
   // o_fakt_doks_dbf()
   // o_fakt_doks2_dbf()

   // SELECT fakt_doks
   // SET ORDER TO TAG "1"

   IF !uslovi_za_povrat_prema_kriteriju( @hParams )
      my_close_all_dbf()
      RETURN .F.
   ENDIF

   Beep( 6 )

   IF Pitanje( "", "Da li ste sigurni da želite vratiti sve dokumente prema kriteriju (D/N) ?", "N" ) == "N"
      my_close_all_dbf()
      RETURN .F.
   ENDIF

   cFilter := hParams[ "uslov_dokumenti" ]

   IF !Empty( hParams[ "uslov_datumi" ] )
      cFilter += " .and. " + hParams[ "uslov_datumi" ]
   ENDIF

   cFilter += " .and. " + hParams[ "uslov_tipovi" ]

   IF !Empty( hParams[ "rj" ] )
      cFilter += " .and. idfirma==" + dbf_quote( hParams[ "rj" ] )
   ENDIF

   cFilter := StrTran( cFilter, ".t..and.", "" )

   seek_fakt_doks()
   IF cFilter == ".t."
      SET FILTER TO
   ELSE
      SET FILTER TO &cFilter
   ENDIF
   GO TOP

   run_sql_query( "BEGIN" )

   IF !f18_lock_tables( { "fakt_doks", "fakt_doks2", "fakt_fakt" }, .T. )
      run_sql_query( "ROLLBACK" )
      MsgBeep( "Ne mogu zaključati tabele.#Prekidam operaciju." )
      RETURN .F.
   ENDIF

   DO WHILE !Eof()

      SKIP 1
      nTrec := RecNo()
      SKIP -1

      cIdFirmaTekuci := field->idfirma
      cIdTipDokTekuci := field->idtipdok
      cBrDokTekuci := field->brdok

      IF !seek_fakt( cIdFirmaTekuci, cIdTipDokTekuci, cBrDokTekuci )
         // IF Eof()
         SELECT fakt_doks // nema stavki, sljedeci fakt dokument
         SKIP
         LOOP
      ENDIF

      fakt_kopiraj_dokument_u_tabelu_pripreme( cIdFirmaTekuci, cIdTipDokTekuci, cBrDokTekuci )

      MsgO( "Brišem dokumente iz kumulativa: " + cIdFirmaTekuci + "-" + cIdTipDokTekuci + "-" + PadR( cBrDokTekuci, 10 ) )


      SELECT fakt_doks
      hRec := dbf_get_rec()
      lOk := delete_rec_server_and_dbf( "fakt_doks", hRec, 1, "CONT" )

      IF !seek_fakt( cIdFirmaTekuci, cIdTipDokTekuci, cBrDokTekuci )
         // IF !Found()

         hRec := dbf_get_rec()
         lOk := delete_rec_server_and_dbf( "fakt_fakt", hRec, 2, "CONT" )

         IF lOk
            seek_fakt_doks2( cIdFirmaTekuci, cIdTipDokTekuci, cBrDokTekuci )
            IF !Eof()
               hRec := dbf_get_rec()
               lOk := delete_rec_server_and_dbf( "fakt_doks2", hRec, 1, "CONT" )
            ENDIF
         ENDIF

         IF lOk
            log_write( "F18_DOK_OPER: fakt povrat dokumenta prema kriteriju: " + cIdFirmaTekuci + "-" + cIdTipDokTekuci + "-" + cBrDokTekuci, 2 )
         ENDIF

         IF !lOk
            EXIT
         ENDIF

      ENDIF

      MsgC()

      SELECT fakt_doks
      GO ( nTrec )

   ENDDO

   IF lOk
      hParams := hb_Hash()
      hParams[ "unlock" ] := { "fakt_doks", "fakt_doks2", "fakt_fakt" }
      run_sql_query( "COMMIT", hParams )

   ELSE
      run_sql_query( "ROLLBACK" )
      MsgBeep( "Problem sa povratom dokumenta u pripremu.#Poništavam operaciju." )
   ENDIF

   my_close_all_dbf()

   RETURN lOk



STATIC FUNCTION uslovi_za_povrat_prema_kriteriju( hVars )

   LOCAL cIdTipDok := hVars[ "idtipdok" ]
   LOCAL cBrDok := hVars[ "brdok" ]
   LOCAL _datumi := hVars[ "datumi" ]
   LOCAL cIdRj := hVars[ "rj" ]
   LOCAL lRet := .T.
   LOCAL GetList := {}

   Box(, 4, 60 )
   @ box_x_koord() + 1, box_y_koord() + 2 SAY "Rj               "  GET cIdRj PICT "@!"
   @ box_x_koord() + 2, box_y_koord() + 2 SAY "Vrste dokumenata "  GET cIdTipDok PICT "@S40"
   @ box_x_koord() + 3, box_y_koord() + 2 SAY "Broj dokumenata  "  GET cBrDok PICT "@S40"
   @ box_x_koord() + 4, box_y_koord() + 2 SAY "Datumi           "  GET _datumi PICT "@S40"
   READ
   Boxc()

   IF Pitanje( "FAKT_POV_KRITER", "Dokumente sa zadanim kriterijumom vratiti u pripremu (D/N) ?", "N" ) == "N"
      lRet := .F.
      RETURN lRet
   ENDIF

   hVars[ "rj" ] := cIdRj
   hVars[ "idtipdok" ] := cIdTipDok
   hVars[ "brdok" ] := cBrDok
   hVars[ "datumi" ] := _datumi
   hVars[ "uslov_dokumenti" ] := Parsiraj( cBrDok, "brdok", "C" )
   hVars[ "uslov_datumi" ] := Parsiraj( _datumi, "datdok", "D" )
   hVars[ "uslov_tipovi" ] := Parsiraj( cIdTipDok, "idtipdok", "C" )

   RETURN lRet




STATIC FUNCTION dokument_se_moze_vratiti_u_pripremu( hVars )

   LOCAL lRet := .T.

   IF hVars[ "idtipdok" ] $ "10#11"
      IF postoji_fiskalni_racun( hVars[ "idfirma" ], hVars[ "idtipdok" ], hVars[ "brdok" ], fiskalni_uredjaj_model() )
         MsgBeep( "Za ovaj dokument je izdat fiskalni račun.#Opcija povrata je onemogućena !!!" )
         lRet := .F.
         RETURN lRet
      ENDIF
   ENDIF

   RETURN lRet


STATIC FUNCTION uslovi_za_povrat_dokumenta( hVars )

   LOCAL cIdFirma   := hVars[ "idfirma" ]
   LOCAL cIdTipDok := hVars[ "idtipdok" ]
   LOCAL cBrDok  := hVars[ "brdok" ]
   LOCAL lRet     := .T.
   LOCAL GetList := {}

   Box( "", 1, 35 )

   @ box_x_koord() + 1, box_y_koord() + 2 SAY "Dokument:"
   @ box_x_koord() + 1, Col() + 1 GET cIdFirma

   @ box_x_koord() + 1, Col() + 1 SAY "-"
   @ box_x_koord() + 1, Col() + 1 GET cIdTipDok

   @ box_x_koord() + 1, Col() + 1 SAY "-" GET cBrDok

   READ

   BoxC()

   IF LastKey() == K_ESC
      lRet := .F.
      RETURN lRet
   ENDIF

   hVars[ "idfirma" ]  := cIdFirma
   hVars[ "idtipdok" ] := cIdTipDok
   hVars[ "brdok" ]    := cBrDok

   RETURN lRet




FUNCTION fakt_napravi_duplikat( cIdFirma, cIdTipDok, cBrDok )

   LOCAL cQuery, _field
   LOCAL oTable, oRow
   LOCAL nCount := 0
   LOCAL hRec

   IF Pitanje(, "Napraviti duplikat dokumenta u tablu pripreme (D/N) ? ", "D" ) == "N"
      RETURN .T.
   ENDIF

   SELECT ( F_FAKT_PRIPR )
   IF !Used()
      o_fakt_pripr()
   ENDIF

   cQuery := "SELECT * FROM " + f18_sql_schema( "fakt_fakt" ) + ;
      " WHERE idfirma = " + sql_quote( cIdFirma ) + ;
      " AND idtipdok = " + sql_quote( cIdTipDok ) + ;
      " AND brdok = " + sql_quote( cBrDok ) + ;
      " ORDER BY idfirma, idtipdok, brdok, rbr "

   oTable := run_sql_query( cQuery )

   IF oTable:LastRec() == 0
      MsgBeep( "Traženog dokumenta nema!" )
      RETURN .T.
   ENDIF

   DO WHILE !oTable:Eof()

      oRow := oTable:GetRow()

      SELECT fakt_pripr
      APPEND BLANK
      hRec := dbf_get_rec()

      FOR EACH _field in hRec:keys
         hRec[ _field ] := oRow:FieldGet( oRow:FieldPos( _field ) )
         IF ValType( hRec[ _field ] ) == "C"
            hRec[ _field ] := hb_UTF8ToStr( hRec[ _field ] )
         ENDIF
      NEXT

      hRec[ "brdok" ] := fakt_prazan_broj_dokumenta()
      hRec[ "datdok" ] := Date()

      dbf_update_rec( hRec )

      oTable:skip()

      ++nCount

   ENDDO

   SELECT fakt_pripr
   USE

   IF nCount > 0
      MsgBeep( "Novoformirani dokument se nalazi u pripremi !" )
   ENDIF

   RETURN .T.
