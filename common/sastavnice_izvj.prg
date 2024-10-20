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


FUNCTION sastavnice_lista()

   LOCAL nArr := Select(), hRec, lOk, nTRec
   LOCAL cIdSastavnica

   qqProiz := Space( 60 )
   cBrisiPrekinuteSastavniceDN := "N"
   cSamoBezSast := "N"
   cNCVPC := "D"

   MsgO( "sast brisanje prazne šifre" )
   sastavnice_delete_empty_id()
   MsgC()

   DO WHILE .T.
      Box(, 7, 60 )
      @ box_x_koord() + 1, box_y_koord() + 2 SAY "Proizvodi :" GET qqProiz  PICT "@!S30"
      @ box_x_koord() + 3, box_y_koord() + 2 SAY "Brisanje prekinutih sastavnica ? (D/N)" GET cBrisiPrekinuteSastavniceDN  PICT "@!" VALID cBrisiPrekinuteSastavniceDN $ "DN"
      @ box_x_koord() + 5, box_y_koord() + 2 SAY "Prikazati samo proizvode bez sastavnica ? (D/N)" GET cSamoBezSast  PICT "@!" VALID cSamoBezSast $ "DN"
      @ box_x_koord() + 7, box_y_koord() + 2 SAY "Prikazati NC i VPC ? (D/N)" GET cNCVPC VALID cNCVPC $ "DN" PICT "@!"
      READ
      BoxC()

      IF LastKey() == K_ESC
         RETURN .F.
      ENDIF

      PRIVATE aUsl1 := Parsiraj( qqProiz, "Id" )
      IF aUsl1 <> NIL
         EXIT
      ENDIF

   ENDDO

   SELECT ( nArr )
   PushWA()

// SELECT ( F_ROBA )
// IF !Used()
// o_roba()
// ENDIF
// SET ORDER TO TAG "ID"

   o_sastavnice()


   IF cBrisiPrekinuteSastavniceDN == "D"

      run_sql_query( "BEGIN" )

      SELECT sast
      SET ORDER TO
      GO TOP
      DO WHILE !Eof()
         SKIP
         nTrec := RecNo()
         SKIP -1
         IF !select_o_roba( sast->id )  // nema "svog proizvoda"
            SELECT sast
            hRec := dbf_get_rec()
            lOk := delete_rec_server_and_dbf( Alias(), hRec, 1, "CONT" )
            IF !lOk
              error_bar( "sast", "DELETE SAST id:" + hRec[ "id" ] + " / id2: " + hRec[ "id2" ] )
            endif
         ENDIF
         SELECT sast
         GO nTRec
      ENDDO
      SELECT sast
      SET ORDER TO TAG "ID"
      GO TOP

      run_sql_query( "COMMIT" )
   ENDIF

   START PRINT CRET

   IF cSamoBezSast == "D"

      o_roba_tip_p()

      IF Len( aUsl1 ) <> 0
         aUsl1 += ".and. tip=='P'"
         SET FILTER TO &( aUsl1 )
      ELSE
         SET FILTER TO tip == "P"
      ENDIF

      m := "----------------------------------------------------------------------------------------------"
      nCol1 := 60
      P_10CPI
      ? "Pregled proizvoda koji nemaju definisane sastavnice"
      ?
      ? self_organizacija_naziv(), Space( 20 ), "na dan", Date()
      GO TOP
      P_12CPI
      ?
      nRBr := 0
      DO WHILE !Eof()
         cIdSastavnica := id
         IF !select_o_sastavnice( ROBA_P->ID )
            IF PRow() > 62 + dodatni_redovi_po_stranici()
               FF
            ENDIF
            ?U Str( ++nRBr, 3 ) + ".", roba_p->id, Left( roba_p->naz, 40 ),  roba_p->jmj
         ENDIF
         SELECT ROBA_P
         SKIP 1
      ENDDO
      ?U m

   ELSE


      SELECT sast
      IF Len( aUsl1 ) <> 0
         SET FILTER TO &( aUsl1 )
      ELSE
         SET FILTER TO
      ENDIF

      IF cNCVPC == "D"
         m := "----------------------------------------------------------------------------------------------"
         z := "                                                              Količina         NV        VPV"
      ELSE
         m := "------------------------------------------------------------------------"
         z := "                                                              Količina"
      ENDIF

      //nCol1 := 20 + Len( ROBA_P->( id + naz ) )
      nCol1 := 70

      P_10CPI

      ? "Pregled sastavnica-normativa za proizvode"
      ?
      ? self_organizacija_naziv(), Space( 20 ), "na dan", Date()

      SELECT SAST
      GO TOP

      P_COND

      DO WHILE !Eof()

         aPom := {}
         cIdSastavnica := sast->id

         select_o_roba( cIdSastavnica )

         SELECT sast

         AAdd( aPom, "" )
         AAdd( aPom, m )
         AAdd( aPom, cIdSastavnica + " " + PadR( AllTrim( roba->naz ), 40 ) + " " + roba->jmj )
         AAdd( aPom, m )
         AAdd( aPom, z )
         AAdd( aPom, m )

         nRbr := 0
         nNC := 0
         nVPC := 0

         DO WHILE !Eof() .AND. sast->id == cIdSastavnica

            cIdSast := field->id2

            select_o_roba( cIdSast )
            SELECT sast

            AAdd( aPom, Str( ++nRbr, 5 ) + ". " + ;
               cIdSast + " " + ;
               PadR( AllTrim( roba->naz ), 40 ) + " " + ;
               Transform( sast->kolicina, "999999.9999" ) + " " + ;
               IF( cNCVPC == "D", Transform( roba->nc * sast->kolicina, fakt_pic_iznos() ) + " " + ;
               Transform( roba->vpc * sast->kolicina, fakt_pic_iznos() ), "" );
               )

            nNC += roba->nc * sast->kolicina
            nVPC += roba->vpc * sast->kolicina
            SKIP 1
         ENDDO

         IF cNCVPC == "D"
            AAdd( aPom, m )
            AAdd( aPom, PadR( " Ukupno:", nCol1 ) + " " + ;
               Transform( nNC, fakt_pic_iznos() ) + " " + ;
               Transform( nVPC, fakt_pic_iznos() );
               )
         ENDIF
         AAdd( aPom, m )
         IF PRow() + Len( aPom ) > 62 + dodatni_redovi_po_stranici()
            FF
         ENDIF
         FOR i := 1 TO Len( aPom )
            ?U aPom[ i ]
         NEXT
      ENDDO

   ENDIF

   FF

   ENDPRINT
   SELECT ( nArr )
   PopWA()

   RETURN .T.
