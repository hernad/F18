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

FUNCTION fakt_fin_prenos()

   LOCAL nNV := 0, nFV := 0
   LOCAL nTot1, nTot2, nTot3, nTot4, nTot5, nTot6, nTot7, nTot8, nTot9, nTota, nTotb
   LOCAL cIdRjFakt
   LOCAL hParamsFaktDoks := hb_hash()
   LOCAL aMemo, dDatVal


   o_params()
   PRIVATE cSection := "(", cHistory := " "; aHistory := {}

   // lNCPoSast := ( my_get_from_ini( "FAKTFIN", "NCPoSastavnici", "N", KUMPATH ) == "D" )
   // cKonSir   := PadR( my_get_from_ini( "FAKTFIN", "KontoSirovinaIzSastavnice", "1010", KUMPATH ), 7 )
   cKonSir := "1010"

   gFaktKum := ""

   gDzokerF1 := ""

   cOdradjeno := "D"

   Rpar( "a1", @gFaktKum )
   Rpar( "a2", @gDzokerF1 )


   gDzokerF1 := Trim( gDzokerF1 )

   IF Empty( gFaktKum ) .OR. cOdradjeno = "N"
      gFaktKum := Trim( StrTran( cDirRad, "FIN", "FAKT" ) ) + SLASH
      Wpar( "a1", @gFaktKum )
   ENDIF


   cIdRjFakt := "10"
   cIdFakt := "10"
   dDAtOd := Date()
   dDatDo := Date()
   qqDok := Space( 30 )
   cSetPAr := "N"
   cSetIdRj := "N"

   Box(, 10, 60 )
   @ box_x_koord() + 1, box_y_koord() + 2 SAY "RJ u fakt:" GET cIdRjFakt
   @ box_x_koord() + 1, Col() + 2 SAY "postaviti IdRj u FIN ?" GET cSetIdRj PICT "@!" VALID ( cSetIdRj $ "DN" )

   @ box_x_koord() + 2, box_y_koord() + 2 SAY "Vrsta dokumenta u fakt:" GET cIdFakt
   @ box_x_koord() + 3, box_y_koord() + 2 SAY "Dokumenti u periodu:" GET dDAtOd
   @ box_x_koord() + 3, Col() + 2 SAY "do" GET dDatDo
   @ box_x_koord() + 5, box_y_koord() + 2 SAY "Broj dokumenta" GET qqDok

   @ box_x_koord() + 6, box_y_koord() + 2 SAY "Podesiti parametre prenosa" GET cSetPAr VALID csetpar $ "DN" PICT "@!"
   READ
   IF cSetPar == "D"
      gFaktKum := PadR( gFaktKum, 35 )

      gDzokerF1 := PadR( gDzokerF1, 80 )
      @ box_x_koord() + 8, box_y_koord() + 2 SAY "FAKT Kumulativ" GET gFaktKum  PICT "@S25"
      @ box_x_koord() + 9, box_y_koord() + 2 SAY "Dzoker F1(formula)" GET gDzokerF1  PICT "@S25"

      READ
      gFaktKum := Trim( gFaktKum )

      gDzokerF1 := Trim( gDzokerF1 )
      Wpar( "a1", @gFaktKum )
      Wpar( "a2", @gDzokerF1 )

   ENDIF

   BoxC()

   SELECT params
   USE

   IF LastKey() == K_ESC
      my_close_all_dbf()
      RETURN .F.
   ENDIF


   O_FINMAT
   // o_konto()
   // o_partner()
   // o_tdok()
   // o_roba()
   // o_tarifa()

   // IF lNCPoSast
   // o_sastavnice()
   // SET ORDER TO TAG "1"
   // ENDIF


   SELECT FINMAT
   my_dbf_zap()

   aUsl := Parsiraj( qqDok, "Brdok", "C" )

   PRIVATE cFilter := "DatDok>=" + dbf_quote( dDatOd ) + ".and.DatDok<=" + dbf_quote( dDatDo ) + ".and. idtipdok==" + dbf_quote( cIdFakt ) + ".and. IdFirma==" + dbf_quote( cIdRjFakt )

   IF aUsl <> ".t."
      cFilter += ".and." + aUsl
   ENDIF

   find_fakt_za_period( cIdRjFakt, dDatOd, dDatDo, NIL, NIL, "3" )
   SET FILTER TO &cFilter
   GO TOP


   nTot1 := nTot2 := nTot3 := nTot4 := nTot5 := nTot6 := nTot7 := nTot8 := nTot9 := nTota := nTotb := 0
   DO WHILE !Eof()

      cIdFirma := fakt->IdFirma
      cBrDok := fakt->BrDok
      cIdTipDok := fakt->IdTipdok

      SELECT fakt

      cIdPartner := fakt->idpartner
      IF Empty( fakt->IdPartner )
         Box(, 6, 66 )
         aMemo := fakt_ftxt_decode( fakt->txt )
         IF Len( aMemo ) >= 5
            @ box_x_koord() + 1, box_y_koord() + 2 SAY "FAKT broj:" + BrDOK
            @ box_x_koord() + 2, box_y_koord() + 2 SAY PadR( Trim( aMemo[ 3 ] ), 30 )
            @ box_x_koord() + 3, box_y_koord() + 2 SAY PadR( Trim( aMemo[ 4 ] ), 30 )
            @ box_x_koord() + 4, box_y_koord() + 2 SAY PadR( Trim( aMemo[ 5 ] ), 30 )
         ELSE
            cTxt := ""
         ENDIF
         @ box_x_koord() + 6, box_y_koord() + 2 SAY "Sifra partnera:"  GET cIdpartner PICT "@!" VALID p_partner( @cIdPartner )
         READ
         BoxC()
      ENDIF


      /*
       SELECT(F_FAKT_DOKS)
       hParamsFaktDoks["idfirma"] := fakt->idfirma
       hParamsFaktDoks["idvn"] := fakt->idtipdok
       hParamsFaktDoks["brdok"] := fakt->brdok
       hParamsFaktDoks["area"] := F_FAKT_DOKS
       hParamsFaktDoks["alias"] := "FAKT_DOKS"
       hParamsFaktDoks["indeks"] := .F.
       use_sql_fakt_doks( hParamsFaktDoks )
       */
      
      SELECT FAKT

      DO WHILE !Eof() .AND. cIdFirma == fakt->IdFirma .AND.  cBrDok == fakt->BrDok .AND. cIdTipDok == fakt->IdTipDok

         nFV := fakt->Cijena * fakt->Kolicina
         nRabat := fakt->Cijena * fakt->kolicina * fakt->Rabat / 100

         select_o_roba( FAKT->IdRoba )
         select_o_tarifa( roba->idtarifa )
         SELECT fakt

         dDatVal := CTOD("")
         IF Val(fakt->rbr) == 1 // prva stavka
            aMemo := fakt_ftxt_decode( fakt->txt )
            IF Len( aMemo ) >= 9
               altd()
               dDatVal := CTOD(aMemo[9])
            ENDIF
         ENDIF
            
         nNV := 0
/*

    --     IF lNCPoSast .AND. ROBA->tip == "P"
            SELECT SAST
            HSEEK FAKT->idroba
            DO WHILE !Eof() .AND. id == FAKT->idroba
               nNV += FAKT->kolicina * SAST->kolicina * get_nabavna_cijena_iz_kalk( SAST->id2, cKonSir )
               SKIP 1
            ENDDO
         ENDIF
*/
         SELECT FINMAT
         APPEND BLANK
         cIdVD := fakt->IdTipdok
         RREPLACE IdFirma   WITH self_organizacija_id(), ;
            IdTarifa  WITH roba->IdTarifa, ;
            IdPartner WITH cIdPartner, ;
            IdVD      WITH cIdVD, ;
            BrDok     WITH fakt->BrDok, ;
            DatDok    WITH fakt->DatDok, ;
            FV        WITH nFV, ;
            NV        WITH nNV, ;
            Marza     WITH 0, ;
            VPV       WITH nFV, ;
            RABATV    WITH nRabat, ;
            Porez     WITH IIF( cIdVD <> "11", ( nFV - nRabat ) * fakt->( porez / 100 ), ;
            fakt_porez_11( nFV, nRabat ) ), ;
            idroba    WITH fakt->idroba, ;
            Kolicina  WITH fakt->Kolicina,;
            DATFAKTP  WITH dDatVal
         

            //POREZV    WITH IOF( cIdVD <> "11", Porez, fakt_porez_11( "PPU" ) ), ;
            //POREZ2    WITH IOF( cIdVD <> "11", 0,  fakt_porez_11( "PPP" ) ), ;

         IF ( cSetIdRj == "D" )
            RREPLACE IdRj WITH cIdRjFakt
         ENDIF

/*
         IF cIDVD == "11" .AND. lNCPoSast .AND. TARIFA->mpp <> 0 .AND. FieldPos( "POREZ3" ) > 0
            RREPLACE porez3 WITH fakt_porez_11( "MPP" )
         ENDIF
  */
         SELECT fakt
         SKIP
      ENDDO // brdok

   ENDDO

   SELECT finmat
   IF reccount2() > 0
      my_close_all_dbf()
      fin_kontiranje_naloga( dDatDo )
   ELSE
      MsgBeep( "Nema dokumenata za prenos ..." )
   ENDIF

   RETURN .T.



FUNCTION fakt_porez_11( nFV, nRabat )

   LOCAL nVrati, nCSP
   LOCAL nPDV

  // nMPP := tarifa->mpp / 100
  nPDV := tarifa->opp / 100
  // nPP := tarifa->zpp / 100
  // nPPU := tarifa->ppp / 100

   nCSP := nFV - nRabat     // cijena sa porezima

   nVrati := nCSP * ( nPDV / 100 ) / ( 1 + nPDV / 100 )

/*
   IF gUVarPP == "T"
      nPor1 := nCSP * nPPP / ( 1 + nPPP )
      nPor2 := ( nCSP - nPor1 - nNV ) * nMPP / ( 1 + nMPP )
      nPor3 := ( nCSP - nPor2 ) * nPP
      DO CASE
      CASE cVar == "PP"
         nVrati := nPor3
      CASE cVar == "PPP"
         nVrati := nPor1
      CASE cVar == "PPU"
         nVrati := 0
      CASE cVar == "MPP"
         nVrati := nPor2
      ENDCASE
      RETURN nVrati
   ENDIF
*/

/*
   IF  gUVarPP == "D"
      nD := 1 + TARIFA->zpp / 100 + TARIFA->ppp / 100
   ELSE
      nD := ( 1 + TARIFA->opp / 100 ) * ( 1 + TARIFA->ppp / 100 ) + TARIFA->zpp / 100
   ENDIF
*/

/*
   DO CASE
   CASE cVar == "PP"
      nVrati := nCSP * ( TARIFA->zpp / 100 ) / nD
   CASE cVar == "PPU"
      IF gUVarPP == "D"
         nVrati := nCSP * ( TARIFA->ppp / 100 ) / nD
      ELSE
         nVrati := nCSP * ( TARIFA->ppp / 100 ) * ( 1 + TARIFA->opp / 100 ) / nD
      ENDIF
   CASE cVar == "PPP"
      IF gUVarPP == "D"
         nVrati := nCSP * ( TARIFA->opp / 100 ) / ( ( 1 + TARIFA->opp / 100 ) * nD )
      ELSE
         nVrati := nCSP * ( TARIFA->opp / 100 ) / nD
      ENDIF

   CASE cVar == "MPP"
      IF gUVarPP == "D"
         nMPVBP := nCSP / ( ( 1 + TARIFA->opp / 100 ) * nD )
      ELSE
         nMPVBP := nCSP / nD
      ENDIF
      nPom   := nMPVBP - nNV
      nVrati := Max( nCSP * ( TARIFA->dlruc / 100 ) * ( TARIFA->mpp / 100 ), TARIFA->mpp * nPom / ( 100 + TARIFA->mpp ) )
   END CASE
*/
   RETURN nVrati




/*
 *     Kontiranje naloga
 *   param: dDatNal  - datum naloga
 */

FUNCTION fin_kontiranje_naloga( dDatNal )

   LOCAL cidfirma, cidvd, cbrdok, lafin, lafin2
   LOCAL cPdvBroj, cJiB
   LOCAL GetList := {}
   LOCAL cIdPartner, cIdKonto
   LOCAL cNePDV
   LOCAL dDatVal

   // o_roba()
   O_FINMAT
   o_trfp2()
   o_koncij()
   o_valute()

   lAFin := .T.
   IF lafin
      Beep( 1 )
      lafin := Pitanje(, "Formirati FIN nalog?", "D" ) == "D"
   ENDIF

   cBrNalF := ""

   // o_nalog()
   o_fin_pripr()

   SELECT FINMAT
   GO TOP
   SELECT trfp2
   SEEK finmat->IdVD + " "

   cIdVN := IdVN   // uzmi vrstu naloga koja ce se uzeti u odnosu na prvu kalkulaciju koja se kontira

   IF lAFin
      cBrNalF := fin_novi_broj_dokumenta( finmat->idfirma, cIdVn )
      // SELECT nalog
      // USE
   ENDIF

   SELECT finmat
   GO TOP

   Box( "brn?", 5, 55 )
   // dDatNal:=datdok
   SET CURSOR ON
   @ box_x_koord() + 1, box_y_koord() + 2  SAY "Broj naloga u FIN  " + finmat->idfirma + " - " + cidvn + " -" GET cBrNalF
   @ box_x_koord() + 5, box_y_koord() + 2 SAY "(ako je broj naloga prazan - ne vrsi se kontiranje)"
   READ
   ESC_BCR
   BoxC()
   nRbr := 0; nRbr2 := 0

   MsgO( "Prenos FAKT -> FIN" )

   SELECT finmat
   PRIVATE cKonto1 := NIL
   PRIVATE KursLis := "1"

   DO WHILE !finmat->( Eof() )    // finmat

      cIDVD := IdVD
      cBrDok := BrDok
      IF ValType( cKonto1 ) <> "C"
         PRIVATE cKonto1 := ""; cKonto2 := "";cKonto3 := ""
         PRIVATE cPartner1 := ""; cPartner2 := cPartner3 := ""
      ENDIF
      DO WHILE cIdVD == IdVD .AND. cBrDok == BrDok .AND. !Eof()

         select_o_roba( finmat->idroba )

         SELECT trfp2
         SEEK cIdVD + " "

         DO WHILE !Empty( cBrNalF ) .AND. trfp2->idvd == cIDVD  .AND. trfp2->shema == " " .AND. !Eof()

            cStavka := Id

            SELECT finmat
            nIz := &cStavka // evaluacija fakt->fin formule

            SELECT trfp2
            IF !Empty( trfp2->idtarifa ) .AND. trfp2->idtarifa <> finmat->idtarifa
               // ako u {ifrarniku parametara postoji tarifa prenosi po tarifama
               nIz := 0
            ENDIF

            IF nIz <> 0

               // ako je iznos elementa <> 0, dodaj stavku u fpripr
               SELECT fin_pripr
               IF trfp2->znak == "-"
                  nIz := -nIz
               ENDIF

               nIz := round7( nIz, Right( TRFP2->naz, 2 ) )

               // DEM - pomocna valuta
               nIz2 := nIz * Kurs( dDatNal, "D", "P" )

               cIdKonto := trfp2->Idkonto
               cIdKonto := StrTran( cIdKonto, "?1", Trim( cKonto1 ) )
               cIdKonto := StrTran( cIdKonto, "?2", Trim( cKonto2 ) )
               cIdKonto := StrTran( cIdKonto, "?3", Trim( cKonto3 ) )

               IF "F1" $ cIdKonto
                  IF Empty( gDzokerF1 )
                     cPom := ""
                  ELSE
                     cPom := &gDzokerF1
                  ENDIF
                  cIdKonto := StrTran( cIdKonto, "F1", cPom )
               ENDIF

               cIdKonto := PadR( cIdKonto, 7 )
               cIdPartner := Space( 6 )
               dDatNal := CTOD("")
               IF trfp2->Partner == "1"  // stavi Partnera
                  cIdpartner := FINMAT->IdPartner
                  dDatVal := FINMAT->DATFAKTP
               ELSEIF trfp2->Partner == "A"   // stavi  Lice koje se zaduz2
                  cIdpartner := PadR( cPartner1, 7 )
               ELSEIF trfp2->Partner == "B"   // stavi  Lice koje se zaduz2
                  cIdpartner := PadR( cPartner2, 7 )
               ELSEIF trfp2->Partner == "C"   // stavi  Lice koje se zaduz2
                  cIdpartner := PadR( cPartner3, 7 )

               ELSEIF trfp2->Partner == "K"   // krajnja potrosnja
                   
                  //cPdvBroj := get_partn_pdvb( FINMAT->IdPartner )
                  //cJIB := get_partn_idbr( FINMAT->IdPartner )

                  //IF LEN(Trim(cPdvBroj)) < 12 // krajnja potrosnja
                     // 4700 -> 4730
                     // 4701 -> 4731
                  //   cIdKonto := LEFT(cIdKonto, 2) + "3" + SUBSTR(cIdKonto, 4)
                  //ENDIF
                  altd()

                  cNePDV := partn_nepdv( FINMAT->IdPartner )
                  SWITCH cNePDV
                     CASE "0"
                        // pdv obveznik
                        // cIdKonto ne mjenjati
                        EXIT
                     CASE "1"
                        // NEPDV FBiH
                        cIdKonto := PADR("4730", 7)
                        EXIT
                     CASE "2"
                        // NEPDV RS
                        cIdKonto := PADR("4731", 7)
                        EXIT
                     CASE "3"
                        // NEPDV BD
                        cIdKonto := PADR("4732", 7)
                        EXIT
                  ENDSWITCH

               ENDIF


               SELECT fin_pripr

               cBrDok := Space( 8 )
               dDatDok := FINMAT->datdok
               IF trfp2->Dokument == "1"
                  cBrDok := FINMAT->brdok
               ELSEIF trfp2->Dokument == "3"
                  dDatDok := dDatNal
               ENDIF

               fExist := .F.
               SEEK FINMAT->IdFirma + cIdVn + cBrNalF
               IF fin_pripr->( Found() )
                  fExist := .F.
                  DO WHILE FINMAT->idfirma + cIdvn + cBrNalF == fin_pripr->IdFirma + fin_pripr->idvn + fin_pripr->BrNal
                     IF IdKonto == cIdKonto .AND. IdPartner == cIdPartner .AND. trfp2->d_p == d_p  .AND. idtipdok == FINMAT->idvd .AND. PadR( brdok, 10 ) == PadR( cBrDok, 10 ) .AND. datdok == dDatDok
                        // provjeriti da li se vec nalazi stavka koju dodajemo
                        fExist := .T.
                        EXIT
                     ENDIF
                     SKIP
                  ENDDO
                  IF !fExist
                     GO BOTTOM
                     nRbr := fin_pripr->Rbr + 1
                     APPEND BLANK
                  ENDIF
               ELSE
                  GO BOTTOM
                  nRbr := fin_pripr->rbr + 1
                  APPEND BLANK
               ENDIF

               RREPLACE iznosDEM WITH iznosDEM + nIz2, ;
                  iznosBHD WITH iznosBHD + nIz, ;
                  idKonto  WITH cIdKonto, ;
                  IdPartner  WITH cIdPartner, ;
                  D_P      WITH trfp2->d_P, ;
                  idFirma  WITH FINMAT->idfirma, ;
                  IdVN     WITH cidvn, ;
                  BrNal    WITH cBrNalF, ;
                  IdTipDok WITH FINMAT->IdVD, ;
                  BrDok    WITH cBrDok, ;
                  DatDok   WITH dDatDok, ;
                  DatVal   WITH dDatVal, ;
                  opis     WITH trfp2->naz

               IF !fExist
                  RREPLACE Rbr  WITH nRbr
               ENDIF

            ENDIF // nIz <>0

            SELECT trfp2
            SKIP
         ENDDO // trfp2->id==cIDVD


         SELECT FINMAT
         SKIP
      ENDDO

   ENDDO

   IF lAFin

      SELECT fin_pripr
      GO TOP

      my_flock()
      DO WHILE !Eof()

         cPom := Right( Trim( fin_pripr->opis ), 1 )

/*
         // na desnu stranu opisa stavim npr "ZADUZ MAGACIN          0"
         // onda ce izvrsiti zaokruzenje na 0 decimalnih mjesta
         IF cPom $ "0125"
            info_bar( "fin_kont", "Fin kontiranje HACK Zaokr : " + Trim( fin_pripr->opis ) + " ZAOKR: " + cPom )
            nLen := Len( Trim( opis ) )
            REPLACE opis WITH Left( Trim( opis ), nLen - 1 )
            REPLACE iznosbhd WITH Round( iznosbhd, iif( Val( cPom ) == 0 .AND. cPom != "0", 2, Val( cPom ) ) )
            REPLACE iznosdem WITH Round( iznosdem, iif( Val( cPom ) == 0 .AND. cPom != "0", 2, Val( cPom ) ) )

            IF cPom = "5"
               REPLACE iznosbhd WITH round2( iznosbhd, 2 )
               REPLACE iznosdem WITH round2( iznosdem, 2 )
            ENDIF
         ENDIF // cpom
*/
         SKIP
      ENDDO // fpripr

      my_unlock()
   ENDIF // lafin , lafin2

   MsgC()

   closeret

   RETURN .T.



FUNCTION Altd0()


   RETURN 0

/* RasKon(cRoba,aSifre,aKonta)
 *     Trazi poziciju cRoba u aSifre i ako nadje vraca element iz aKonta koji je na nadjenoj poziciji
 *   param: cRoba
 *   param: aSifre
 *   param: aKonta
 */

FUNCTION RasKon( cRoba, aSifre, aKonta )

   LOCAL nPom

   nPom := AScan( aSifre, cRoba )

   RETURN IF( nPom > 0, aKonta[ nPom ], "" )




/* PrStopa(nProc)
 *      Preracunata stopa
 *  \nProc - Broj
 */

FUNCTION PrStopa( nProc )

   RETURN ( if( nProc == 0, 0, 1 / ( 1 + 1 / ( nProc / 100 ) ) ) )




/* IzKalk(cIdRoba,cKonSir,cSta)
 *
 *   param: cIdRoba
 *   param: cKonSir
 *   param: cSta
 */

FUNCTION get_nabavna_cijena_iz_kalk( cIdRoba, cKonSir )

   LOCAL x := 0, nArr := Select(), nNV, nUlaz, nIzlaz

   find_kalk_by_mkonto_idroba( self_organizacija_id(), cKonSir, cIdRoba )

   nNV := nUlaz := nIzlaz := 0
   DO WHILE !Eof() .AND. idfirma + mkonto + idroba == self_organizacija_id() + cKonSir + cIdRoba
      IF mu_i == "1" .AND. !( idvd $ "12#22#94" )
         nUlaz  += kolicina - gkolicina - gkolicin2
         nNV    += nc * ( kolicina - gkolicina - gkolicin2 )
      ELSEIF mu_i == "5"
         nIzlaz += kolicina
         nNV    -= nc * ( kolicina )
      ELSEIF mu_i == "1" .AND. ( idvd $ "12#22#94" )    // povrat
         nIzlaz -= kolicina
         nNV    += nc * ( kolicina )
      ENDIF
      SKIP 1
   ENDDO
   IF nUlaz - nIzlaz <> 0
      x := nNV / ( nUlaz - nIzlaz )
   ENDIF
   IF x <= 0
      MsgBeep( "GRESKA! Artikal:" + cIdRoba + ", konto:" + cKonSir + ", NC=" + Str( x ) + " !?" + ;
         "#FAKT dok.:" + FAKT->( idfirma + "-" + idtipdok + "-" + brdok ) + ", stavka br." + FAKT->rbr + ;
         "#Proizvod:" + FAKT->idroba )
   ENDIF

   SELECT ( nArr )

   RETURN x
