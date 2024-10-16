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


FUNCTION calc_mbruto()

   LOCAL lRet := .T.

   IF ld->I01 = 0
      lRet := .F.
   ENDIF

   RETURN lRet


FUNCTION _calc_tpr( nIzn, lCalculate )

   LOCAL nRet := nIzn
   LOCAL cTR

   IF lCalculate == nil
      lCalculate := .F.
   ENDIF

   cTR := get_ld_rj_tip_rada( ld->idradn, ld->idrj )

   IF gPrBruto == "X" .AND. ( tippr->uneto == "D" .OR. lCalculate == .T. )
      nRet := ld_get_bruto_osnova( nIzn, cTR, ld->ulicodb )
   ENDIF

   RETURN nRet


FUNCTION tr_list()
   RETURN "I#N"


FUNCTION get_ld_rj_tip_rada( cIdRadn, cRj )

   LOCAL cTipRada := " "

   PushWa()

   select_o_ld_rj( cRJ )

   IF ld_rj->( FieldPos( "tiprada" ) ) <> 0
      cTipRada := ld_rj->tiprada
   ENDIF

   IF Empty( cTipRada )
      select_o_radn( cIdRadn )
      cTipRada := radn->tiprada
   ENDIF

   PopWa()

   RETURN cTipRada



FUNCTION g_oporeziv( cIdRadn, cRj )

   LOCAL cOpor := " "
   LOCAL nTArea := Select()

   select_o_ld_rj( cRJ )

   IF ld_rj->( FieldPos( "opor" ) ) <> 0
      cOpor := ld_rj->opor
   ENDIF

   IF Empty( cOpor )
      select_o_radn( cIdRadn )
      cOpor := radn->opor
   ENDIF

   SELECT ( nTArea )

   RETURN cOpor



FUNCTION MsgTipRada()

   LOCAL x := 1

   Box(, 10, 66 )
   @ box_x_koord() + x, box_y_koord() + 2 SAY _l( "Vazece sifre su: ' ' - zateceni neto (bez promjene ugovora o radu)" )
   ++x
   @ box_x_koord() + x, box_y_koord() + 2 SAY _l( "                 'N' - neto placa (neto + porez)" )
   ++x
   @ box_x_koord() + x, box_y_koord() + 2 SAY _l( "                 'I' - neto-neto placa (zagarantovana)" )
   ++x
   @ box_x_koord() + x, box_y_koord() + 2 SAY _l( "                 -------------------------------------------------" )
   ++x
   @ box_x_koord() + x, box_y_koord() + 2 SAY _l( "                 'S' - samostalni poslodavci" )
   ++x
   @ box_x_koord() + x, box_y_koord() + 2 SAY _l( "                 'U' - ugovor o djelu" )
   ++x
   @ box_x_koord() + x, box_y_koord() + 2 SAY _l( "                 'A' - autorski honorar" )
   ++x
   @ box_x_koord() + x, box_y_koord() + 2 SAY _l( "                 'P' - clan.predsj., upr.odbor, itd..." )
   ++x
   @ box_x_koord() + x, box_y_koord() + 2 SAY _l( "                 -------------------------------------------------" )
   ++x
   @ box_x_koord() + x, box_y_koord() + 2 SAY _l( "                 'R' - obracun za rs" )

   Inkey( 0 )
   BoxC()

   RETURN .F.


FUNCTION get_dopr( cDopr, cTipRada )

   LOCAL nTArea := Select()
   LOCAL nIzn := 0

   IF cTipRada == nil
      cTipRada := " "
   ENDIF

   o_dopr()
   GO TOP
   SEEK cDopr
   DO WHILE !Eof() .AND. dopr->id == cDopr

      // provjeri tip rada
      IF Empty( dopr->tiprada ) .AND. cTipRada $ tr_list()
         // ovo je u redu...
      ELSEIF ( cTipRada <> dopr->tiprada )
         SKIP
         LOOP
      ENDIF

      nIzn := dopr->iznos

      EXIT

   ENDDO

   SELECT ( nTArea )

   RETURN nIzn



FUNCTION radn_oporeziv( cIdRadn, cRj )

   LOCAL lRet := .T.
   LOCAL nTArea := Select()
   LOCAL cOpor

   cOpor := g_oporeziv( cIdRadn, cRj )

   IF cOpor == "N"
      lRet := .F.
   ENDIF

   SELECT ( nTArea )

   RETURN lRet



// ---------------------------------------------------------
// vraca bruto osnovu
// nIzn - ugovoreni neto iznos
// cTipRada - vrsta/tip rada
// nLOdb - iznos licnog odbitka
// nSKoef - koeficijent kod samostalnih poslodavaca
// cTrosk - ugovori o djelu i ahon, korsiti troskove ?
// ---------------------------------------------------------
FUNCTION ld_get_bruto_osnova( nIzn, cTipRada, nLOdb, nSKoef, cTrosk )

   LOCAL nBrt := 0

   PushWa()
   IF nIzn <= 0
      PopWa()
      RETURN nBrt
   ENDIF

   IF nLOdb = nil
      nLOdb := 0
   ENDIF

   IF nSKoef = nil
      nSKoef := 0
   ENDIF

   IF cTrosk == nil
      cTrosk := ""
   ENDIF

   DO CASE
      // nesamostalni rad
   CASE Empty( cTipRada )
      nBrt := ROUND2( nIzn * parobr->k5, gZaok2 )

      // neto placa (neto + porez )
   CASE cTipRada == "N"
      nBrt := ROUND2( nIzn * parobr->k6, gZaok2 )

      // nesamostalni rad, isti neto
   CASE cTipRada == "I"
      // ako je ugovoreni iznos manji od odbitka
      IF ( nIzn < nLOdb )
         nBrt := ROUND2( nIzn * parobr->k6, gZaok2 )
      ELSE
         nBrt := ROUND2( ( ( nIzn - nLOdb ) / 0.9 + nLOdb ) / 0.69, gZaok2 )
      ENDIF

      // samostalni poslodavci
   CASE cTipRada == "S"
      nBrt := ROUND2( nIzn * nSKoef, gZaok2 )

      // predsjednicki clanovi
   CASE cTipRada == "P"
      nBrt := ROUND2( ( nIzn * 1.11111 ) / 0.96, gZaok2 )

      // republika srpska
   CASE cTipRada == "R"
      nTmp := Round( ( nLOdb * parobr->k5 ), 2 )
      nBrt := ROUND2( ( nIzn - nTmp ) / parobr->k6, gZaok2 )

      // ugovor o djelu i autorski honorar
   CASE cTipRada $ "A#U"

      IF cTipRada == "U"
         nTr := gUgTrosk
      ELSE
         nTr := gAHTrosk
      ENDIF

      IF cTrosk == "N"
         nTr := 0
      ENDIF

      nBrt := ROUND2( nIzn / ( ( ( 100 - nTr ) * 0.96 * 0.90 + nTr ) / 100 ), gZaok2 )


      IF radnik_iz_rs( radn->idopsst, radn->idopsrad ) // ako je u RS-u, nema troskova, i drugi koeficijent
         nBrt := ROUND2( nIzn * 1.111112, gZaok2 )
      ENDIF

   ENDCASE

   PopWa()

   RETURN nBrt



FUNCTION ld_bruto_isplata_ispis( nNeto, cTipRada, nLOdb, nSKoef, cTrosk )

   LOCAL cPrn := ""

   IF nLOdb = nil
      nLOdb := 0
   ENDIF

   IF nSKoef = nil
      nSKoef := 0
   ENDIF

   IF cTrosk == nil
      cTrosk := ""
   ENDIF

   DO CASE
      // nesamostalni rad
   CASE Empty( cTipRada )
      cPrn := AllTrim( Str( nNeto ) ) + " * " + ;
         AllTrim( Str( parobr->k5 ) ) + " ="

      // nerezidenti
   CASE cTipRada == "N"
      cPrn := AllTrim( Str( nNeto ) ) + " * " + ;
         AllTrim( Str( parobr->k6 ) ) + " ="

      // nesamostalni rad - isti neto
   CASE cTipRada == "I"
      cPrn := "((( " + AllTrim( Str( nNeto ) ) + " - " + ;
         AllTrim( Str( nLOdb ) ) + ")" + ;
         " / 0.9 ) + " + AllTrim( Str( nLOdb ) ) + " ) / 0.69 ="
      IF ( nNeto < nLOdb )
         cPrn := AllTrim( Str( nNeto ) ) + " * " + ;
            AllTrim( Str( parobr->k6 ) ) + " ="

      ENDIF
      // samostalni poslodavci
   CASE cTipRada == "S"
      cPrn := AllTrim( Str( nNeto ) ) + " * " + ;
         AllTrim( Str( nSKoef ) ) + " ="

      // clanovi predsjednistva
   CASE cTipRada == "P"
      cPrn := AllTrim( Str( nNeto ) ) + " * 1.11111 / 0.96 ="

      // republika srpska
   CASE cTipRada == "R"

      nTmp := Round( ( nLOdb * parobr->k5 ), 2 )

      cPrn := "( " + AllTrim( Str( nNeto ) ) + " - " + ;
         AllTrim( Str( nTmp ) ) + " ) / " + ;
         AllTrim( Str( parobr->k6 ) ) + " ="

      // ugovor o djelu
   CASE cTipRada $ "A#U"

      IF cTipRada == "U"
         nTr := gUgTrosk
      ELSE
         nTr := gAHTrosk
      ENDIF

      IF cTrosk == "N"
         nTr := 0
      ENDIF

      nProc := ( ( ( 100 - nTr ) * 0.96 * 0.90 + nTr ) / 100 )

      cPrn := AllTrim( Str( nNeto ) ) + " / " + AllTrim( Str( nProc, 12, 6 ) ) + " ="
      // ako je u RS-u, nema troskova, i drugi koeficijent
      IF radnik_iz_rs( radn->idopsst, radn->idopsrad )

         cPrn := AllTrim( Str( nNeto ) ) + " * 1.111112 ="
      ENDIF

   ENDCASE

   RETURN cPrn


// --------------------------------------------
// minimalni bruto
// --------------------------------------------
FUNCTION min_bruto( nBruto, nSati )

   LOCAL nRet
   LOCAL nMBO
   LOCAL nParSati
   LOCAL nTmpSati

   IF nBruto <= 0
      RETURN nBruto
   ENDIF

   // sati iz parametara obracuna
   nParSati := parobr->k1

   // puno radno vrijeme ili rad na 4 sata
   IF ( nSati = nParSati ) .OR. ( nParSati / 2 = nSati ) .OR. ( radn->k1 $ "M#P" )

      nTmpSati := nSati

      IF radn->k1 == "P"
         nTmpSati := nSati * 2
      ENDIF

      nMBO := ROUND2( nTmpSati * parobr->m_br_sat, gZaok2 )
      nRet := Max( nBruto, nMBO )
   ELSE
      nRet := nBruto
   ENDIF

   RETURN nRet



// --------------------------------------------
// minimalni neto
// --------------------------------------------
FUNCTION min_neto( nNeto, nSati )

   LOCAL nRet
   LOCAL nMNO
   LOCAL nParSati
   LOCAL nTmpSati

   IF nNeto <= 0
      RETURN nNeto
   ENDIF

   // sati iz parametara obracuna
   nParSati := parobr->k1

   // ako je rad puni ili rad na 4 sata
   IF ( nParSati = nSati ) .OR. ( nParSati / 2 = nSati ) .OR. ( radn->k1 $ "M#P" )

      nTmpSati := nSati

      IF radn->k1 == "P"
         nTmpSati := nSati * 2
      ENDIF

      nMNO := ROUND2( nTmpSati * parobr->m_net_sat, gZaok2 )
      nRet := Max( nNeto, nMNO )
   ELSE
      nRet := nNeto
   ENDIF

   RETURN nRet



// ---------------------------------------------------
// validacija tipa rada na uslovima izvjestaja
// ---------------------------------------------------
FUNCTION val_tiprada( cTR )

   IF cTR $ " #I#S#P#U#N#A#R"
      RETURN .T.
   ELSE
      RETURN .F.
   ENDIF

   RETURN


// --------------------------------
// ispisuje potpis
// --------------------------------
FUNCTION p_potpis()

   PRIVATE cP1 := gPotp1
   PRIVATE cP2 := gPotp2

   IF gPotpRpt == "N"
      RETURN ""
   ENDIF

   IF !Empty( gPotp1 )
      ?
      QQOut( &cP1 )
   ENDIF

   IF !Empty( gPotp2 )
      ?
      QQOut( &cP2 )
   ENDIF

   RETURN ""


// -----------------------------------------------------
// vraca koeficijent licnog odbitka
// -----------------------------------------------------
FUNCTION get_koeficijent_licnog_odbitka( nUOdbitak )

   LOCAL nKLO := 0

   IF nUOdbitak <> 0
      nKLO := nUOdbitak / gOsnLOdb
   ENDIF

   RETURN nKLO



// ------------------------------------------------
// vraca ukupnu vrijednost licnog odbitka
// ------------------------------------------------
FUNCTION g_licni_odb( cIdRadn )

   LOCAL nTArea := Select()
   LOCAL nIzn := 0

   select_o_radn( cIdRadn )

   IF field->klo <> 0
      nIzn := round2( gOsnLOdb * field->klo, gZaok2 )
   ELSE
      nIzn := 0
   ENDIF

   SELECT ( nTArea )

   RETURN nIzn



FUNCTION get_varobr()
   RETURN ld->varobr



FUNCTION ld_index_tag_vise_obracuna( cT, cI )

   IF cI == NIL
      cI := ""
   ENDIF

   IF ld_vise_obracuna() .AND. cT $ "12"
      IF cI == "I" .OR. Empty( gObracun )
         cT := cT + "U"
      ENDIF
   ENDIF

   RETURN cT





FUNCTION ld_obracun_napravljen_vise_puta()

   LOCAL nMjesec := ld_tekuci_mjesec()
   LOCAL nGodina := ld_tekuca_godina()
   LOCAL cObracun := gObracun
   LOCAL _data := {}
   LOCAL cIdRadn, nProlaz, nCount
   LOCAL nI

   Box(, 3, 50 )

   @ box_x_koord() + 1, box_y_koord() + 2 SAY " Mjesec: " GET nMjesec PICT "99"
   @ box_x_koord() + 2, box_y_koord() + 2 SAY " Godina: " GET nGodina PICT "9999"
   @ box_x_koord() + 3, box_y_koord() + 2 SAY "Obracun: " GET cObracun

   READ

   ESC_BCR

   BoxC()


   seek_ld_2( NIL,  nGodina, nMjesec, cObracun ) // hIndexes[ "2" ] := "str(godina,4,0)+str(mjesec,2,0)+obr+idradn+idrj"

   Box(, 1, 60 )

   nCount := 0

   DO WHILE !Eof() .AND. Str( nGodina, 4, 0 ) + Str( nMjesec, 2, 0 ) + cObracun == Str( field->godina, 4, 0 ) + Str( field->mjesec, 2, 0 ) + ld->obr

      cIdRadn := ld->idradn
      nProlaz := 0

      ++nCount
      @ box_x_koord() + 1, box_y_koord() + 2 SAY "Radnik: " + cIdRadn
      DO WHILE !Eof() .AND. Str( nGodina, 4, 0 ) + Str( nMjesec, 2, 0 ) + cObracun == Str( ld->godina, 4, 0 ) + Str( ld->mjesec, 2, 0 ) + ld->obr .AND. ld->idradn == cIdradn
         ++nProlaz
         SKIP
      ENDDO

      IF nProlaz > 1

         select_o_radn( cIdRadn )

         SELECT ld
         SEEK Str( nGodina, 4, 0 ) + Str( nMjesec, 2, 0 ) + cObracun + cIdRadn
         DO WHILE !Eof() .AND. Str( field->godina, 4 ) + Str( field->mjesec, 2 ) + field->obr == Str( nGodina, 4, 0 ) + Str( nMjesec, 2, 0 ) + cObracun .AND. field->idradn == cIdRadn
            AAdd( _data, { field->obr, field->idradn, PadR( AllTrim( radn->naz ) + " " + AllTrim( radn->ime ), 20 ), field->idrj, field->uneto, field->usati } )
            SKIP
         ENDDO

      ENDIF

   ENDDO

   BoxC()

   IF Len( _data ) == 0
      my_close_all_dbf()
      RETURN .F.
   ENDIF

   START PRINT CRET

   ? _l( "Radnici obradjeni vise puta za isti mjesec -" ), nGodina, "/", nMjesec
   ?
   ? _l( "OBR RADNIK                      RJ     neto        sati" )
   ? "--- ------ -------------------- -- ------------- ----------"

   FOR nI := 1 TO Len( _data )

      ? PadR( _data[ nI, 1 ], 3 ), _data[ nI, 2 ], _data[ nI, 3 ], _data[ nI, 4 ], _data[ nI, 5 ], _data[ nI, 6 ]

   NEXT

   FF
   ENDPRINT

   my_close_all_dbf()

   RETURN .T.



FUNCTION ld_gen_virm()

   IF !f18_use_module( "virm" )
      RETURN .F.
   ENDIF

   O_VIRM_PRIPR
   my_dbf_zap()

   MsgBeep( "Opcija podrazumjeva da ste prozvali rekapitulaciju plate" )

   virm_set_global_vars()
   virm_prenos_ld( .T. )
   unos_virmana()

   my_close_all_dbf()

   RETURN .T.






FUNCTION SortPrez( cId ) // , lSql )

   LOCAL cVrati := ""
   LOCAL lUtf := .F.
   LOCAL nArr := Select()

   // hb_default( @lSql, .F. )

   select_o_radn( cId )

/*
   IF lSql
      cVrati := StrTran( field->naz + field->ime + field->imerod + field->id, _u( "Č" ), "CH" )
      cVrati := StrTran( cVrati, _u( "č" ), "ch" )
      cVrati := StrTran( cVrati, _u( "Ć" ), "CC" )
      cVrati := StrTran( cVrati, _u( "ć" ), "cc" )
      cVrati := StrTran( cVrati, _u( "Š" ), "SH" )
      cVrati := StrTran( cVrati, _u( "š" ), "sh" )
      cVrati := StrTran( cVrati, _u( "Ž" ), "ZZ" )
      cVrati := StrTran( cVrati, _u( "ž" ), "zz" )
      cVrati := StrTran( cVrati, _u( "Đ" ), "DJ" )
      cVrati := StrTran( cVrati, _u( "đ" ), "dj" )
      cVrati := PadR( cVrati, 100 )

   ELSE
      cVrati := field->naz + field->ime + field->imerod + field->id
   ENDIF
   */
   cVrati := field->naz + field->ime + field->imerod + field->id

   SELECT ( nArr )

   RETURN cVrati


// HACK: 2i indeks sortime pravi probleme
/*
FUNCTION SortIme( cId )

   LOCAL cVrati := ""
   LOCAL nArr := Select()

   SELECT( F_RADN )
   IF !Used()
      reopen_exclusive( "ld_radn" )
   ENDIF
   SET ORDER TO TAG "1"

  -- HSEEK cId
   cVrati := ime + naz + imerod + id

   SELECT ( nArr )

   RETURN cVrati
*/


FUNCTION NLjudi()
   RETURN "(" + AllTrim( Str( opsld->ljudi ) ) + ")"


FUNCTION ImaUOp( cPD, cSif )

   LOCAL lVrati := .T.

   IF ops->( FieldPos( "DNE" ) ) <> 0
      IF Upper( cPD ) = "P"
         lVrati := !( cSif $ OPS->pne )
      ELSE
         lVrati := !( cSif $ OPS->dne )
      ENDIF
   ENDIF

   RETURN lVrati


FUNCTION PozicOps( cSR )

   LOCAL nArr := Select()
   LOCAL cO := ""

   IF cSR == "1"
      // opstina stanovanja
      cO := radn->idopsst
   ELSEIF cSR == "2"
      // opstina rada
      cO := radn->idopsrad
   ELSE
      // " "
      cO := Chr( 255 )
   ENDIF

   select_o_ops( cO )

   SELECT ( nArr )

   RETURN .T.


FUNCTION ScatterS( cG, cM, cJ, cR, cPrefix )

   PRIVATE cP7 := cPrefix

   IF cPrefix == NIL
      Scatter()
   ELSE
      Scatter( cPrefix )
   ENDIF
   SKIP 1
   DO WHILE !Eof() .AND. mjesec = cM .AND. godina = cG .AND. idradn = cR .AND. ;
         idrj = cJ
      IF cPrefix == NIL
         FOR i := 1 TO cLDPolja
            cPom    := PadL( AllTrim( Str( i ) ), 2, "0" )
            _I&cPom += i&cPom
         NEXT
         _uneto   += uneto
         _uodbici += uodbici
         _uiznos  += uiznos
      ELSE
         FOR i := 1 TO cLDPolja
            cPom    := PadL( AllTrim( Str( i ) ), 2, "0" )
            &cP7.i&cPom += i&cPom
         NEXT
         &cP7.uneto   += uneto
         &cP7.uodbici += uodbici
         &cP7.uiznos  += uiznos
      ENDIF
      SKIP 1
   ENDDO
   SKIP -1

   RETURN

FUNCTION IspisObr()

   LOCAL cVrati := ""

   IF ld_vise_obracuna() .AND. !Empty( cObracun )
      cVrati := "/" + cObracun
   ENDIF

   RETURN cVrati


FUNCTION Obr2_9()
   RETURN ld_vise_obracuna() .AND. !Empty( cObracun ) .AND. cObracun <> "1"
