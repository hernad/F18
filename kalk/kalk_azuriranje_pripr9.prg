
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


/*
      
*/
FUNCTION kalk_azuriranje_pripr_smece_pripr9()
   
   LOCAL lGen := .F.
   LOCAL cPametno := "D"
   LOCAL aDokumentiPriprema
   LOCAL nI, hRec, nScan
   LOCAL cIdFirma, cIdVd, cBrDok
   LOCAL lDupli

   o_kalk_pripr9()
   o_kalk_pripr()

   SELECT kalk_pripr
   GO TOP

   IF kalk_pripr->( RecCount() ) == 0
      RETURN .F.
   ENDIF

   IF Pitanje( "#PRIPR->SMECE", "Želite li pripremu prebaciti u smeće (D/N) ?", "N" ) == "N"
      RETURN .F.
   ENDIF

   aDokumentiPriprema := kalk_dokumenti_iz_pripreme_u_matricu()

   // aDokument[4] == 1 ako ga ima u smecu, 0 ako ga nema u smecu 
   postoji_li_dokument_u_pripr9( @aDokumentiPriprema )

   SELECT kalk_pripr
   GO TOP

   lDupli := .F. // postoje i u pripremu i u smecu

   DO WHILE !Eof()

      nScan := AScan( aDokumentiPriprema, {| aDokument | aDokument[ 1 ] == kalk_pripr->idfirma .AND. aDokument[ 2 ] == kalk_pripr->idvd .AND. aDokument[ 3 ] == kalk_pripr->brdok } )

      altd()
      
      IF nScan > 0 
         
         IF aDokumentiPriprema[ nScan, 4 ] == 0 // postoji u pripremi, nema ga u smecu

            cIdFirma := kalk_pripr->idfirma
            cIdVd := kalk_pripr->idvd
            cBrDok := kalk_pripr->brdok

            DO WHILE !Eof() .AND. kalk_pripr->idfirma + kalk_pripr->idvd + kalk_pripr->brdok == cIdFirma + cIdVd + cBrDok

               hRec := dbf_get_rec()

               SELECT kalk_pripr9
               APPEND BLANK

               dbf_update_rec( hRec )

               SELECT kalk_pripr
               SKIP

            ENDDO

            log_write( "F18_DOK_OPER: kalk, prenos dokumenta iz pripreme u smece: " + cIdFirma + "-" + cIdVd + "-" + cBrDok, 2 )

         ELSE
            // vec postoji u smecu
            lDupli := .T.
            info_bar("smece", "SMECE DUPLI: " + aDokumentiPriprema[nScan, 1] + "-" + aDokumentiPriprema[nScan, 2] + "-" + aDokumentiPriprema[nScan, 3] )
            SELECT KALK_PRIPR
            SKIP
         ENDIF
      ENDIF

   ENDDO

   IF lDupli
      MsgBeep("Postoje dokumenti u smeću pod istim brojem!#Zato se priprema ne prazni")
   ELSE
      SELECT kalk_pripr
      my_dbf_zap()
   ENDIF

   my_close_all_dbf()

   RETURN .T.



FUNCTION kalk_povrat_dokumenta_iz_pripr9( cIdFirma, cIdVd, cBrDok )

   LOCAL nRec
   LOCAL hRec
   LOCAL GetList := {}

   lSilent := .T.

   o_kalk_pripr9()
   o_kalk_pripr()

   SELECT kalk_pripr9
   SET ORDER TO TAG "1"

   IF ( ( cIdFirma == NIL ) .AND. ( cIdVd == NIL ) .AND. ( cBrDok == NIL ) )
      lSilent := .F.
   ENDIF

   IF !lSilent
      cIdFirma := self_organizacija_id()
      cIdVD := Space( 2 )
      cBrDok := Space( 8 )
   ENDIF

   IF !lSilent
      Box( "", 1, 35 )
      @ box_x_koord() + 1, box_y_koord() + 2 SAY "Dokument:"

      @ box_x_koord() + 1, Col() + 1 SAY cIdFirma

      @ box_x_koord() + 1, Col() + 1 SAY "-" GET cIdVD
      @ box_x_koord() + 1, Col() + 1 SAY "-" GET cBrDok
      READ
      ESC_BCR
      BoxC()

      IF cBrDok = "."
         PRIVATE qqBrDok := qqDatDok := qqIdvD := Space( 80 )
         qqIdVD := PadR( cidvd + ";", 80 )
         Box(, 3, 60 )
         DO WHILE .T.
            @ box_x_koord() + 1, box_y_koord() + 2 SAY "Vrste dokum.   "  GET qqIdVD PICT "@S40"
            @ box_x_koord() + 2, box_y_koord() + 2 SAY "Broj dokumenata"  GET qqBrDok PICT "@S40"
            @ box_x_koord() + 3, box_y_koord() + 2 SAY "Datumi         " GET  qqDatDok PICT "@S40"
            READ
            PRIVATE aUsl1 := Parsiraj( qqBrDok, "BrDok", "C" )
            PRIVATE aUsl2 := Parsiraj( qqDatDok, "DatDok", "D" )
            PRIVATE aUsl3 := Parsiraj( qqIdVD, "IdVD", "C" )
            IF aUsl1 <> NIL .AND. aUsl2 <> NIL .AND. ausl3 <> NIL
               EXIT
            ENDIF
         ENDDO
         Boxc()

         IF Pitanje(, "Povući u pripremu dokumente sa ovim kriterijom ?", "N" ) == "D"
            SELECT kalk_pripr9
            PRIVATE cFilt1 := ""
            cFilt1 := "IDFIRMA==" + dbf_quote( cIdFirma ) + ".and." + aUsl1 + ".and." + aUsl2 + ".and." + aUsl3
            cFilt1 := StrTran( cFilt1, ".t..and.", "" )
            IF !( cFilt1 == ".t." )
               SET FILTER TO &cFilt1
            ENDIF

            GO TOP
            MsgO( "Prolaz kroz SMEĆE..." )
            DO WHILE !Eof()
               SELECT kalk_pripr9
               Scatter()
               SELECT kalk_pripr
               APPEND ncnl
               _ERROR := ""
               Gather2()
               SELECT kalk_pripr9
               SKIP
               nRec := RecNo()
               SKIP -1
               my_delete()
               GO nRec
            ENDDO
            MsgC()
         ENDIF
         my_close_all_dbf()
         RETURN
      ENDIF
   ENDIF

   IF Pitanje( "", "Iz smeća " + cIdFirma + "-" + cIdVD + "-" + cBrDok + " povući u pripremu (D/N) ?", "D" ) == "N"
      IF !lSilent
         my_close_all_dbf()
         RETURN
      ELSE
         RETURN
      ENDIF
   ENDIF

   SELECT kalk_pripr9

   HSEEK cIdFirma + cIdVd + cBrDok
   EOF CRET

   MsgO( "PRIPREMA" )

   DO WHILE !Eof() .AND. cIdFirma == kalk_pripr9->IdFirma .AND. cIdVD == kalk_pripr9->IdVD .AND. cBrDok == kalk_pripr9->BrDok
      SELECT kalk_pripr9
      Scatter()

      SELECT kalk_pripr
      APPEND ncnl
      _ERROR := ""
      Gather2()
      SELECT kalk_pripr9
      SKIP
   ENDDO

   SELECT kalk_pripr9
   SET ORDER TO TAG "1"
   SEEK cidfirma + cidvd + cBrDok
   my_flock()
   DO WHILE !Eof() .AND. cIdFirma == kalk_pripr9->IdFirma .AND. cIdVD == kalk_pripr9->IdVD .AND. cBrDok == kalk_pripr9->BrDok
      SKIP 1
      nRec := RecNo()
      SKIP -1
      my_delete()
      GO nRec
   ENDDO
   my_unlock()
   USE
   MsgC()

   log_write( "F18_DOK_OPER: kalk, povrat dokumenta iz smeca: " + cIdFirma + "-" + cIdVd + "-" + cBrDok, 2 )

   IF !lSilent
      my_close_all_dbf()
      RETURN
   ENDIF

   o_kalk_pripr9()
   SELECT kalk_pripr9

   RETURN



FUNCTION kalk_povrat_najstariji_dokument_iz_pripr9()

   LOCAL nRec

   o_kalk_pripr9()
   o_kalk_pripr()

   SELECT kalk_pripr9
   SET ORDER TO TAG "3" // kalk_pripr9
   cidfirma := self_organizacija_id()
   cIdVD := Space( 2 )
   cBrDok := Space( 8 )

   IF Pitanje(, "Povuci u pripremu najstariji dokument ?", "N" ) == "N"
      my_close_all_dbf()
      RETURN .F.
   ENDIF

   SELECT kalk_pripr9
   GO TOP

   cidfirma := idfirma
   cIdVD := idvd
   cBrDok := brdok

   MsgO( "PRIPREMA" )

   DO WHILE !Eof() .AND. cIdFirma == IdFirma .AND. cIdVD == IdVD .AND. cBrDok == BrDok
      SELECT kalk_pripr9
      Scatter()
      SELECT kalk_pripr
      APPEND BLANK
      _ERROR := ""
      Gather()
      SELECT kalk_pripr9
      SKIP
   ENDDO

   SET ORDER TO TAG "1"
   SELECT kalk_pripr9
   SET ORDER TO TAG "1"
   SEEK cidfirma + cidvd + cBrDok

   DO WHILE !Eof() .AND. cIdFirma == IdFirma .AND. cIdVD == IdVD .AND. cBrDok == BrDok
      SKIP 1
      nRec := RecNo()
      SKIP -1
      my_delete()
      GO nRec
   ENDDO
   USE
   MsgC()

   my_close_all_dbf()

   RETURN



STATIC FUNCTION postoji_li_dokument_u_pripr9( aDokumentiPriprema )

   LOCAL nI
   LOCAL cSeek

   FOR nI := 1 TO Len( aDokumentiPriprema )

      cSeek := aDokumentiPriprema[ nI, 1 ] + aDokumentiPriprema[ nI, 2 ] + aDokumentiPriprema[ nI, 3 ]

      SELECT kalk_pripr9
      SET ORDER TO TAG "1"
      SEEK cSeek

      IF Found()
         aDokumentiPriprema[ nI, 4 ] := 1
      ENDIF

   NEXT

   RETURN .T.
