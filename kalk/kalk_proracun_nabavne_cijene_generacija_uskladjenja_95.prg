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

FUNCTION kalk_gen_uskladjenje_nc_95( hParams )

   LOCAL cIdFirma := self_organizacija_id(), cIdRoba
   LOCAL cBrDok
   LOCAL hRec
   LOCAL nKolicina, nKolZn, nNcZadnjaNabavka, nSrednjaNabavnaCijena
   LOCAL nNabavnaVrijednost, nSrednjaNcPoUlazima
   LOCAL nRbr, dDatDo, nOdstupanje
   LOCAL nCnt, cInfo

   hb_default( @hParams, hb_Hash() )
   hParams[ "idkonto" ] := PadR( "1320", 7 )
   hParams[ "datdok" ] := Date()
   hParams[ "prag" ] := prag_odstupanja_nc_sumnjiv()

   select_o_kalk_pripr()
   IF reccount2() > 0
      IF Pitanje(, "Brisati pripremu ?", "N" ) == "D"
         my_dbf_zap()
      ELSE
         MsgBeep( "kalk priprema nije prazna!# STOP" )
         RETURN .F.
      ENDIF
   ENDIF

   IF hb_HHasKey( hParams, "brdok" ) // uzmi dokument cije ce stavke biti osnova npr. 10-10-000222
      find_kalk_by_broj_dokumenta( hParams[ "idfirma" ], hParams[ "idvd" ], hParams[ "brdok" ], "kalk_select", F_KALK_SELECT )
      hParams[ "idkonto" ] := field->mkonto // iz dokumenta uzeti konto i datum do koga se kartica sravnjava
      hParams[ "datdok" ] := field->datdok
      hParams[ "brfaktp" ] := field->idvd + "-" + SubStr( field->brdok, 2 ) // idvd=10, brdok=01000055 => 10-1000055
      cInfo := "prema ulazu: " + hParams[ "idfirma" ] + "-" + hParams[ "idvd" ] + "-" + hParams[ "brdok" ]
   ELSE

      IF !get_vars( @hParams )
         RETURN .F.
      ENDIF

      MsgO( "Preuzimanje podataka sa servera ..." )
      find_kalk_by_mkonto_idroba( cIdFirma, hParams[ "idkonto" ], NIL, ;
         "kalk_kalk.idroba,kalk_kalk.mkonto", NIL, "kalk_select", "kalk_kalk.idroba" )
      // ( cIdFirma, cIdKonto, cIdRoba, cOrderBy, lReport, cAlias )
      MsgC()

      hParams[ "brfaktp" ] := "NC" + DToS( hParams[ "datdok" ] ) // oznaka npr. NC20160901
      cInfo := "lager magacin: " + hParams[ "idkonto" ]
   ENDIF

   GO TOP


   IF Eof()
      MsgBeep( "nema stavki za obradu !? STOP" )
      RETURN .F.
   ENDIF


   cBrDok := kalk_get_next_broj_v5( cIdFirma, "95", NIL )

   SELECT kalk_select

   nRbr := 1
   nCnt := 0
   DO WHILE !kalk_select->( Eof() )

      cIdroba := field->idroba
      dDatDo := hParams[ "datdok" ]
      Scatter() // public vars zapisa
      kalk_pozicioniraj_roba_tarifa_by_kalk_fields()

      kalk_get_nabavna_mag( dDatDo, cIdFirma, cIdRoba, hParams[ "idkonto" ], ;
         @nKolicina, @nKolZN, @nNcZadnjaNabavka, @nSrednjaNabavnaCijena, ;
         @nNabavnaVrijednost, @nSrednjaNcPoUlazima, .T. )

      SELECT kalk_pripr

      hRec := dbf_get_rec()
      hRec[ "idfirma" ] := cIdFirma
      hRec[ "idvd" ] := "95"
      hRec[ "brdok" ] := cBrDok
      hRec[ "brfaktp" ] := hParams[ "brfaktp" ]
      hRec[ "idkonto2" ] := hParams[ "idkonto" ]
      hRec[ "mkonto" ] := hParams[ "idkonto" ]
      hRec[ "mu_i" ] := "5"
      IF Round( nKolicina, 3 ) == 0
         hRec[ "kolicina" ] := 1
         IF Round( nNabavnaVrijednost, 3 ) == 0
            nOdstupanje := 0
         ELSE
            hRec[ "nc" ] := nNabavnaVrijednost + 0.000001 // kartica ima NV, a kolicinu 0, popraviti
            nOdstupanje := 1000
         ENDIF
      ELSE
         hRec[ "kolicina" ] := nKolicina
         hRec[ "nc" ] := nNabavnaVrijednost / nKolicina // srednja nc po kartici
         nOdstupanje := Min( Abs( nSrednjaNcPoUlazima ), Abs( hRec[ "nc" ] ) )
         IF nOdstupanje > 0 // procenat odstupanja srednje nc po ulazima od srednje nc po kartici
            nOdstupanje := Abs( nSrednjaNcPoUlazima - hRec[ "nc" ] ) / nOdstupanje * 100
         ENDIF
      ENDIF

      IF nOdstupanje < hParams[ "prag" ] // nije znacajno odstupanje
         SELECT kalk_select
         SKIP
         LOOP
      ENDIF

      hRec[ "idroba" ] := cIdRoba
      hRec[ "datdok" ] := hParams[ "datdok" ]
      hRec[ "rbr" ] := Str( nRbr++, 3 )
      hRec[ "idtarifa" ] := roba->idtarifa


      SELECT kalk_pripr
      APPEND BLANK
      dbf_update_rec( hRec )
      nCnt++
      APPEND BLANK
      IF Abs( Round( nKolicina, 3 ) ) == 0
         hRec[ "kolicina" ] := -1
         hRec[ "nc" ] := 0.000001
      ELSE
         hRec[ "kolicina" ] := -nKolicina
         hRec[ "nc" ] := nSrednjaNcPoUlazima
      ENDIF
      hRec[ "rbr" ] := Str( nRbr++, 3 )
      dbf_update_rec( hRec )

      SELECT kalk_select
      SKIP
   ENDDO

   MsgBeep( "Usklađenje NC " + cInfo + "#izvršeno za " + AllTrim( Str( nCnt ) ) + " artikala" )

   RETURN .T.


STATIC FUNCTION get_vars( hParams )

   LOCAL GetList := {}

   Box( "bv", 5, 75 )
   @ box_x_koord() + 1, box_y_koord() + 2 SAY "  Magacinski konto: " GET  hParams[ "idkonto" ]
   @ box_x_koord() + 2, box_y_koord() + 2 SAY "   Datum dokumenta: " GET hParams[ "datdok" ]
   @ box_x_koord() + 3, box_y_koord() + 2 SAY "prag odstupanja NC: " GET hParams[ "prag" ]

   READ
   BoxC()

   IF LastKey() == K_ESC
      RETURN .F.
   ENDIF

   RETURN .T.
