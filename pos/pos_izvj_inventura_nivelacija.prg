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


FUNCTION pos_stampa_zaduzenja_inventure( lPrikazStavke0Nepromjenjene, lAzurirana )

   LOCAL cRobaNaz
   LOCAL cJmj
   LOCAL cIdRoba
   LOCAL nCij
   LOCAL nCij2

   // koristi privatne vars:
   // Ako je  cIdvD = NI - nivelacija
   // cIdVD = IN - inventura
   //
   // stampa invenure / nivelacije

   LOCAL cPom, cNule := "D", cNiv := "N", nSir := 80, nRobSir := 29
   LOCAL aTarife := {}
   LOCAL lInventura := .T.

   IF lPrikazStavke0Nepromjenjene == NIL
      lPrikazStavke0Nepromjenjene := .F.
   ENDIF
   IF lAzurirana == NIL
      lAzurirana := .F.
   ENDIF

   nSir := 40

   IF cIdVd == "IN"
      IF ! lPrikazStavke0Nepromjenjene
         cNule := Pitanje(, "Stampati stavke sa popisanom kolicinom 0  (D/N)?", "D" )
      ENDIF
      lInventura := .T.
   ELSE
      cNiv := Pitanje(, "Stampati samo stavke sa promijenjenom cijenom (D/N)?", "N" )
      lInventura := .F.
   ENDIF

   IF lAzurirana
      SELECT POS
   ELSE
      SELECT PRIPRZ
   ENDIF

   GO TOP


   START PRINT CRET


   cPom := iif ( lInventura, ;
      iif ( lPrikazStavke0Nepromjenjene, "Inventurna/popisna lista ", "INVENTURA " ), ;
      "NIVELACIJA " )
   cPom += AllTrim ( field->IdPos ) + "-"

   ? PadC ( cPom + AllTrim ( field->BrDok ), nSir )


   SELECT PRIPRZ

   ?

   ?    " ------------- ---------------------- ---"
   ?    "  Sifra           Artikal             jmj"
   ?    " ------------- ---------------------- ---"
   IF lInventura
      ? " Knj. Kol  Pop.kol.   Cijena     +/-"
   ELSE
      ? "  Stanje          Cijena           Nova c."
   ENDIF
   IF lInventura
      m := "--------- --------- -------- ------------"
   ELSE
      m := "  ------------ ------------ ------------"
   ENDIF

   ? m

   nCij := 0
   nKVr := nPopVr := 0
   nStVr := nNVR := 0

   IF lAzurirana
      SELECT POS
   ELSE
      SELECT PRIPRZ
   ENDIF
   cBroj := DToS( field->datum ) + field->brdok   // stampaj broj

   DO WHILE !Eof() .AND. field->idvd == cIdvd .AND.  cBroj == DToS( field->datum ) + field->brdok
      IF lPrikazStavke0Nepromjenjene .OR. ;
            ( cNiv == "N" .OR. ( cNiv == "D" .AND. field->cijena <> field->ncijena ) ) .AND. ;
            ( cNule == "D" .OR. ( cNule == "N" .AND. field->Kol2 <> 0 ) ) ;
            .AND.  ( field->Kolicina <> 0 .OR. field->Kol2 <> 0 )

         cIdRoba := field->idroba
         nCij := field->cijena
         nCij2 := field->ncijena

         IF lAzurirana
            PushWa()
            select_o_roba( cIdRoba )
            cRobaNaz := field->naz
            cJmj := field->jmj
            PopWa()
         ELSE
            cJmj := field->jmj
            cRobaNaz := field->robanaz
         ENDIF

         ? " " + cIdRoba
         ?? " " + PadR ( cRobaNaz, 23 )
         ?? " " + PadR ( "(" + cJmj + ")", 5 )


         ?
         IF lPrikazStavke0Nepromjenjene
            ?? " " + "________.___", "_________.___", Str ( nCij, 8, 2 )
         ELSE
            IF lInventura
               ? Str( field->kolicina, 9, 1 ), Str( field->kol2, 9, 1 ), ;
                  Str ( nCij, 8, 1 ), Str ( field->kolicina - field->kol2, 12, 2 )
               ? m
            ELSE
               // nivelacija
               ? Str( field->kolicina, 14, 3 ), Str ( nCij, 12, 2 ), Str ( nCij2, 12, 2 )
               ? m
            ENDIF
         ENDIF // lPrikazStavke0Nepromjenjene


         nIzn := 0
         IF lInventura
            nKVr += nCij * field->Kolicina
            nPopVr += nCij * field->Kol2        // po starim cijenama
            nIzn := nCij * field->Kol2
         ELSE
            // nivelacija
            nStVr += nCij * field->Kolicina
            nNVr  += nCij2 * field->Kolicina
            nIzn := ( nCij2 - nCij ) * Kolicina
         ENDIF

         pos_setuj_tarife( field->IdRoba, nIzn, @aTarife )


      ENDIF // lPrikazStavke0Nepromjenjene .or. cnule=="N"
      SKIP
   ENDDO // !eof()

   IF !lPrikazStavke0Nepromjenjene .AND. lInventura
      ?
      ? "Ukupno knjizna  vrijednost:", Str( nKVr, 10, 2 )
      ? "Ukupno popisana vrijednost:", Str( nPopVr, 10, 2 )
      ?
      IF Round( nKVr - nPopVr, 3 ) <> 0
         IF nKvr - nPopVr > 0
            ? " Razlika MANJAK ...........", Str( nKVr - nPopVr, 10, 2 )
         ELSE
            ? " Razlika VISAK ............", Str( nKVr - nPopVr, 10, 2 )
         ENDIF
      ENDIF
   ENDIF

   IF !lPrikazStavke0Nepromjenjene .AND. Round( nStVr - nNVR, 3 ) <> 0
      nStVr += nPopVr
      nNVr  += nPopVr
      ?
      ? "PROMJENA CIJENA :"
      ?
      ? "Stara vrijednost zaliha ", Str( nStVr, 10, 2 )
      ? "Nova  vrijednost zaliha ", Str( nNVr, 10, 2 )
      ?
      ? "Razlika vrijednosti    :", Str( nNVr - nStVr, 10, 2 )
   ENDIF

   pos_rekapitulacija_tarifa( aTarife )

   // PaperFeed ()

   ENDPRINT

   RETURN .T.


FUNCTION StampaPLI( cBrDok )

   LOCAL cPom

   SELECT PRIPRZ                // invent
   GO TOP
   START PRINT RET
   cPom := "INVENTURNA-POPISNA LISTA BR. "
   cPom += AllTrim ( PRIPRZ->IdPos ) + "-"
   ? PadC ( cPom + AllTrim ( cBrDok ), 40 )
   ?

   ?
   ? "Sifra    Naziv robe"
   ? "            Stanje    Popisana kolicina"
   ? "----------------------------------------"
   DO WHILE ! Eof ()
      ? IdRoba + " " + RobaNaz
      ? Space ( 10 ) + Str ( Kolicina, 10, 3 ) + "  " + "____________,_____"
      ? "----------------------------------------"
      SKIP
   ENDDO

   ENDPRINT

   RETURN .T.



FUNCTION pos_prepis_inventura_nivelacija( lInventura )

   // prepisace azuriranu fakturu

   PRIVATE cRsDBF, cRsBlok
   IF lInventura
      PRIVATE cIdVd := "IN"
   ELSE
      PRIVATE cIdVd := "NI"
   ENDIF

   SELECT pos

   PushWA()
   USE

   SELECT pos_doks

   seek_pos_pos( pos_doks->IdPos, pos_doks->IdVd, pos_doks->datum, pos_doks->BrDok )

   cRSdbf := "ROBA"
   cRSblok := "P_Roba(@_IdRoba)"
   cUI_U   := R_U
   cUI_I   := R_I


   pos_stampa_zaduzenja_inventure( .F., .T. )  // drugi parametar kaze da se radi o azuriranom dok

   // o_pos_doks()
   // o_pos_pos()

   PopWa()

   SELECT pos_doks

   RETURN .T.
