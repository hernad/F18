/*
 * This file is part of the bring.out FMK, a free and open source
 * accounting software suite,
 * Copyright (c) 1996-2011 by bring.out doo Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including FMK specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_FMK.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */


#include "f18.ch"

/*
FUNCTION kalk_nivelacija_11()

   LOCAL _sufix, hRec

   o_kalk_pripr2()
   o_kalk_pripr()

   SELECT kalk_pripr
   GO TOP

   PRIVATE cIdFirma := field->idfirma
   PRIVATE cIdVD := field->idvd
   PRIVATE cBrDok := field->brdok

   IF !( cIdvd $ "11#81" ) .AND. !Empty( kalk_metoda_nc() )
      my_close_all_dbf()
      RETURN .F.
   ENDIF

   PRIVATE cBrNiv := "0"

   cBrNiv := kalk_get_next_broj_v5( self_organizacija_id(), "19", kalk_pripr->idkonto  )

   SELECT kalk_pripr
   GO TOP
   PRIVATE nRBr := 0
   cPromCj := "D"
   fNivelacija := .F.

   DO WHILE !Eof() .AND. cIdFirma == idfirma .AND. cIdvd == idvd .AND. cBrdok == brdok

      hRec := dbf_get_rec()

      scatter()

      select_o_koncij( hRec[ "idkonto" ] )
      select_o_roba( hRec[ "idroba" ] )
      select_o_tarifa( roba->idtarifa )
      SELECT roba

      PRIVATE nMPC := 0
      nMPC := kalk_get_mpc_by_koncij_pravilo()

      IF dozvoljeno_azuriranje_sumnjivih_stavki()
         kalk_mpc_sa_pdv_sa_kartice( @nMPC, hRec[ "idfirma" ], hRec[ "pkonto" ], hRec[ "idroba" ] )
         SELECT kalk_pripr
      ENDIF

      IF hRec[ "mpcsapp" ] <> nMPC // izvrsiti nivelaciju

         IF !fNivelacija
            // prva stavka za nivelaciju
            cPromCj := Pitanje(, "Postoje promjene cijena. Staviti nove cijene u sifrarnik ?", "D" )
         ENDIF
         fNivelacija := .T.

         PRIVATE nKolZn := nKolicinaNaStanju := nc1 := nc2 := 0

         kalk_get_nabavna_prod( hRec[ "idfirma" ], hRec[ "idroba" ], hRec[ "idkonto" ], @nKolicinaNaStanju, @nKolZN, @nc1, @nc2 )


         SELECT kalk_pripr2

         hRec[ "idpartner" ] := ""
         hRec[ "vpc" ] := 0
         hRec[ "gkolicina" ] := 0
         hRec[ "gkolicin2" ] := 0
         hRec[ "marza2" ] := 0
         hRec[ "tmarza2" ] := "A"

         PRIVATE cOsn := "2", nKalkStaraCijena := nKalkNovaCijena := 0

         nKalkStaraCijena := nMPC
         nKalkNovaCijena := kalk_pripr->MPCSaPP

         hRec[ "mpcsapp" ] := nKalkNovaCijena - nKalkStaraCijena
         hRec[ "mpc" ] := 0
         hRec[ "fcj" ] := nKalkStaraCijena

         IF hRec[ "mpc" ] <> 0
            hRec[ "mpcsapp" ] := ( 1 + tarifa->pdv / 100 ) * hRec[ "mpc" ]
         ELSE
            hRec[ "mpc" ] := hRec[ "mpcsapp" ] / ( 1 + tarifa->pdv / 100 )
         ENDIF

         IF cPromCj == "D"
            select_o_koncij( hRec[ "idkonto" ] )
            SELECT roba
            roba_set_mcsapp_na_osnovu_koncij_pozicije( hRec[ "fcj" ] + hRec[ "mpcsapp" ] )
         ENDIF

         SELECT kalk_pripr2

         hRec[ "pkonto" ] := hRec[ "idkonto" ]
         hRec[ "pu_i" ] := "3"
         hRec[ "mkonto" ] := ""
         hRec[ "mu_i" ] := ""

         hRec[ "kolicina" ] := nKolicinaNaStanju
         hRec[ "brdok" ] := cBrniv
         hRec[ "idvd" ] := "19"

         hRec[ "tbanktr" ] := "X"
         hRec[ "error" ] := ""

         IF Round( hRec[ "kolicina" ], 3 ) <> 0
            APPEND ncnl
            hRec[ "rbr" ] :=  ++nRbr
            dbf_update_rec( hRec )
         ENDIF

      ENDIF

      SELECT kalk_pripr
      SKIP

   ENDDO

   my_close_all_dbf()

   RETURN .T.
*/
