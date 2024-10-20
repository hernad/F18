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


STATIC cij_decimala := 3
STATIC izn_decimala := 2
STATIC kol_decimala := 3
STATIC lZaokruziti := .T.
STATIC PDV_STOPA := 17

STATIC cLauncher1 := 'start "C:\Program Files\OpenOffice.org 2.0\program\scalc.exe"'
// zamjeniti tarabu sa brojem
STATIC cLauncher2 := ""

STATIC cLauncher := "officexp"

// 4 : 852 => US ASCII
STATIC cKonverzija := "4"

// tekuca linija reporta
STATIC nCurrLine := 0


FUNCTION krpt_export()

   LOCAL lAkciznaRoba := .F.
   LOCAL lZasticeneCijene := .F.

   cIdFirma := self_organizacija_id()
   cBrDok := PadR( "00000", 8 )
   cIdVd := "80"
   cLauncher := PadR( cLauncher, 70 )
   cZaokruziti := "D"

   Box(, 14, 70 )

   @ box_x_koord() + 1, box_y_koord() + 2 SAY "Dokument "
   @ box_x_koord() + 2, box_y_koord() + 2 SAY self_organizacija_id() + " - " GET  cIdVd
   @ box_x_koord() + 2, Col() + 2 SAY " - " GET cBrDok


   @ box_x_koord() + 4, box_y_koord() + 2 SAY PadR( "-", 30, "-" )
   @ box_x_koord() + 5, box_y_koord() + 2 SAY "Izvrsiti zaokruzenja ? " GET cZaokruziti PICT "@!" VALID cZaokruziti $ "DN"
   READ

   lZaokruziti := ( cZaokruziti == "D" )

   IF lZaokruziti
      @ box_x_koord() + 5, box_y_koord() + 2 SAY PadR( " ", 57 )
      @ box_x_koord() + 5, box_y_koord() + 2 SAY "Broj decimala cijena " GET cij_decimala PICT "9"
      @ box_x_koord() + 6, box_y_koord() + 2 SAY "               iznos " GET izn_decimala PICT "9"
      @ box_x_koord() + 7, box_y_koord() + 2 SAY "            kolicina " GET kol_decimala PICT "9"
      READ
   ENDIF

   IF cIdVd $ "IP#11#12#13#19#01#80#41#42"
      cMpcCij := "D"
      cVpcCij := "N"
   ELSE
      cMpcCij := "N"
      cVpcCij := "D"
   ENDIF

   @ box_x_koord() + 8, box_y_koord() + 2 SAY PadR( "-", 30, "-" )
   @ box_x_koord() + 9, box_y_koord() + 2 SAY "Trebate mpc cijene ? " GET cMpcCij PICT "@!" VALID cMpcCij $ "DN"
   @ box_x_koord() + 10, box_y_koord() + 2 SAY "Trebate vpc cijene ? " GET cVpcCij PICT "@!" VALID cVpcCij $ "DN"

   @ box_x_koord() + 11, box_y_koord() + 2 SAY PadR( "-", 30, "-" )
   @ box_x_koord() + 12, box_y_koord() + 2 SAY "Konverzija slova (0-8) " GET cKonverzija PICT "9"
   //@ box_x_koord() + 13, box_y_koord() + 2 SAY "Pokreni oo/office97/officexp/office2003 ?" GET cLauncher PICT "@S26" VALID set_launcher( @cLauncher )

   READ
   BoxC()

   IF LastKey() == K_ESC
      closeret
   ENDIF

   find_kalk_by_broj_dokumenta( cIdFirma, cIdVd, cBrDok )


   o_koncij()
   o_tarifa()

   select_o_konto( kalk->PKonto )

   fill_exp( cIdFirma, cIdVd, cBrDok, ( cVpcCij == "D" ), ( cMpcCij == "D" ) )

   my_close_all_dbf()



/* get_uio_fields(aArr)
 *     napuni matricu aArr sa specifikacijom polja tabele
 *   param: aArr - matrica
 */
STATIC FUNCTION get_exp_fields( aArr, cIdVd, lVpcCij, lMpcCij )

   IF lZaokruziti
      nCijDec := cij_decimala
      nKolDec := kol_decimala
      nIznDec := izn_decimala
   ELSE
      nCijDec := 4
      nKolDec := 4
      nIznDec := 3
   ENDIF

   AAdd( aArr, { "rbr",   "N",  5, 0 } )
   AAdd( aArr, { "id_roba",   "C",  10, 0 } )
   AAdd( aArr, { "naziv_roba",   "C",  40, 0 } )

   AAdd( aArr, { "jmj",  "C",  3, 0 } )

   AAdd( aArr, { "id_tarifa",   "C",  6, 0 } )

   // stopa
   AAdd( aArr, { "st_tarifa",   "N",  10, 4 } )

   // preracunata stopa
   AAdd( aArr, { "pst_tarifa",   "N",  10, 4 } )


   AAdd( aArr, { "kol",  "N",  15, nKolDec } )

   IF ( cIdVD == "IP" ) .OR. ( cIdVD == "IM" )
      AAdd( aArr, { "kol_knjiz",  "N",  15, nKolDec } )
   ENDIF

   IF lVpcCij
      AAdd( aArr, { "cij_vpc_d",  "N",  10, nCijDec } )
      AAdd( aArr, { "cij_vpc_1",  "N",  10, nCijDec } )
      AAdd( aArr, { "cij_vpc_2",  "N",  10, nCijDec } )
   ENDIF


   IF lMpcCij
      AAdd( aArr, { "cij_mpc_d",  "N",  10, nCijDec } )
      AAdd( aArr, { "cij_mpc_1",  "N",  10, nCijDec } )
      AAdd( aArr, { "cij_mpc_2",  "N",  10, nCijDec } )
   ENDIF


   AAdd( aArr, { "cij_nab_d",  "N",  10, nCijDec } )
   AAdd( aArr, { "cij_nab",  "N",  10, nCijDec } )

   AAdd( aArr, { "cij_nov_1",  "N",  10, nCijDec } )
   AAdd( aArr, { "cij_nov_2",  "N",  10, nCijDec } )

   RETURN .T.



FUNCTION kcreate_dbf_r_export( cIdVd, lVpcCij, lMpcCij )

   LOCAL cExpTbl := "r_export.dbf"
   LOCAL aArr := {}

   my_close_all_dbf()

   // ferase ( my_home() + "R_EXPORT.CDX" )

   get_exp_fields( @aArr, cIdVd, lVpcCij, lMpcCij )
   // kreiraj tabelu
   dbcreate2( my_home() + cExpTbl, aArr )

   // kreiraj indexe
   // CREATE_INDEX("ROB", "idRoba", my_home() +  cExpTbl, .t.)
   // CREATE_INDEX("TAR", "idTarifa+idRoba", my_home() +  cExpTbl, .t.)

   RETURN .T.


// napuni r_uio
STATIC FUNCTION fill_exp( cIdFirma, cIdVd,  cBrDok, lVpcCij, lMpcCij )

   LOCAL cPom1
   LOCAL cPom2
   LOCAL cKomShow

   PRIVATE cKom

   // + stavka preknjizenja = pdv
   // - stavka = ppp

   kcreate_dbf_r_export( cIdVd, lVpcCij, lMpcCij )

   o_r_export_legacy()
   // set ORDER to TAG "ROB"

   SELECT ( F_KALK )


   SELECT ( F_TARIFA )
   IF !Used()
      o_tarifa()
   ENDIF


   // prvo gledam ppp stavke - negativne stavke
   // u drugom krugu gledam pdv - pozitivne stavke

   Box(, 3, 60 )


   SELECT KALK

   nCount := 0

   // redni broj  u export tabeli
   nRbr := 0

   FOR nKrug := 1 TO 1

      SEEK cIdFirma + cIdVd + cBrDok
      DO WHILE !Eof() .AND. ( IdFirma == cIdFirma ) .AND. ( IdVd == cIdVd )  .AND. ( BrDok == cBrdok )

         ++nCount

         cIdTarifa := idTarifa
         cIdRoba := IdRoba

         @ box_x_koord() + 1, box_y_koord() + 2 SAY "Krug " + Str( nKrug, 1 ) + " " + Str( nCount, 6 )
         @ box_x_koord() + 2, box_y_koord() + 2 SAY cIdRoba + "/" + cIdTarifa
         SELECT r_export


         ++nRbr
         APPEND BLANK
         REPLACE rbr WITH nRbr, id_tarifa WITH cIdTarifa, id_roba WITH cIdRoba

         select_o_roba(  cIdRoba )
         select_o_tarifa( cIdTarifa )

         cPom1 := KonvznWin( Left( roba->naz, 40 ), cKonverzija )
         cPom2 := KonvznWin( roba->jmj, cKonverzija )

         SELECT r_export
         REPLACE jmj WITH cPom2, ;
            naziv_roba WITH cPom1, ;
            pst_tarifa WITH ( 1 - 1 / ( 1 + tarifa->pdv / 100 ) ) * 100, ;
            st_tarifa WITH tarifa->pdv

         REPLACE cij_nab_d WITH kalk->nc, ;
            cij_nab WITH roba->nc

         IF lMpcCij
            REPLACE cij_mpc_d WITH kalk->mpcsapp, ;
               cij_mpc_1 WITH roba->mpc, ;
               cij_mpc_2 WITH roba->mpc2
         ENDIF

         IF lVpcCij
            REPLACE cij_vpc_d WITH kalk->vpc, ;
               cij_vpc_1 WITH roba->vpc, ;
               cij_vpc_2 WITH roba->vpc2
         ENDIF

         IF roba->( FieldPos( "zanivel" ) <> 0 )
            REPLACE cij_nov_1 WITH roba->zanivel, ;
               cij_nov_2 WITH roba->zaniv2
         ENDIF

         REPLACE kol WITH kalk->kolicina

         IF ( cIdVD == "IP" ) .OR. ( cIdVd == "IM" )
            REPLACE kol_knjiz WITH kalk->gkolicina
         ENDIF

         SELECT KALK
         SKIP

      ENDDO

   NEXT

   BoxC()

   my_close_all_dbf()

   // cLauncher := AllTrim( cLauncher )
   // IF ( cLauncher == "start" )
   // cKom := cLauncher + " " + my_home()
   // ELSE
   // cKom := cLauncher + " " + my_home() + "r_export.dbf"
   // ENDIF

   MsgBeep( "Tabela " + my_home() + "r_export.dbf je formirana, i ima:" + Str( nRbr, 5 ) + "stavki##" + ;
      "Sa opcijom Open file se ova tabela ubacuje u excel #" + ;
      "Nakon importa uradite Save as, i odaberite format fajla XLS ! ##" + ;
      "Tako dobijeni xls fajl mozete mijenjati #" + ;
      "prema svojim potrebama ..." )


   open_exported_xlsx( my_home() + "r_export.dbf" )

   RETURN .T.


/*
STATIC FUNCTION msoff_start( cVersion )

   LOCAL cPom :=  'start "C:\Program Files\Microsoft Office\Office#\excel.exe"'

   IF ( cVersion == "XP" )
      // office XP
      RETURN StrTran( cPom,  "#", "10" )
   ELSEIF ( cVersion == "2000" )
      // office 2000
      RETURN StrTran( cPom, "#", "9" )
   ELSEIF ( cVersion == "2003" )
      // office 2003
      RETURN StrTran( cPom, "#", "11" )
   ELSEIF ( cVersion == "97" )
      // office 97
      RETURN StrTran( cPom, "#", "8" )
   ELSE
      // office najnoviji 2005?2006
      RETURN StrTran( cPom, "#", "12" )
   ENDIF
*/
