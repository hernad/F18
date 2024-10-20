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


/*
FUNCTION virm_prenos_fin()

   LOCAL _firma := PadR( fetch_metric( "virm_org_id", NIL, "" ), 6 )

   o_jprih()
--   o_sifk()
--   o_sifv()
   o_banke()
   o_partner()
   o_vrprim()
   O_VIRM_PRIPR
   o_fin_pripr()

   cKome_Txt := ""

   qqKonto := PadR( my_get_from_ini( "VIRM", "UslKonto", "5;" ), 60 )
   dDatVir := datdok

   cDOpis := Space( 36 )

   PRIVATE cKo_txt := ""
   PRIVATE cKo_zr := ""

   Box(, 5, 70 )

   @ box_x_koord() + 1, box_y_koord() + 2 SAY "PRENOS FIN NALOGA (koji je trenutno u pripremi) u VIRM"
   cIdBanka := PadR( cko_zr, 3 )
   @ box_x_koord() + 2, box_y_koord() + 2 SAY "Posiljaoc (sifra banke):       " GET cIdBanka VALID  virm_odredi_ziro_racun( _firma, @cIdBanka )
   READ
   cKo_zr := cIdBanka

   select_o_partner( gVirmFirma )
   SELECT fin_pripr
   cKo_txt := Trim( partn->naz ) + ", " + Trim( partn->mjesto ) + ", " + Trim( partn->adresa ) + ", " + Trim( partn->telefon )
   @ box_x_koord() + 3, box_y_koord() + 2 SAY "Konta za koja se prave virmani ?"  GET qqKonto PICT "@!S30"
   @ box_x_koord() + 4, box_y_koord() + 2 SAY "Dodatak na opis:" GET cDOpis
   @ box_x_koord() + 5, box_y_koord() + 2 SAY "Datum" GET dDatVir
   READ
   ESC_BCR
   BoxC()

   UzmiIzIni( EXEPATH + "fmk.ini", "VIRM", "UslKonto", qqKonto, "WRITE" )

   SELECT fin_pripr

   PRIVATE aUsl1 := Parsiraj( qqKonto, "IdKonto" )
   IF aUsl1 <> NIL
      SET FILTER TO &aUsl1
   ENDIF
   GO TOP


   // fin_pripr finansije

   nRbr := 0
   DO WHILE !Eof()

      SELECT VRPRIM
      SET ORDER TO TAG "IDKONTO"

      IF Empty( fin_pripr->idpartner )
         HSEEK fin_pripr->( idkonto )
      ELSE
         HSEEK fin_pripr->( idkonto + idpartner )
      ENDIF

      SELECT VRPRIM
      IF Found()
         cSvrha_pl := id
      ELSE // probaj 6000, 6010 naci
         HSEEK fin_pripr->( idkonto )
         IF Found() .AND. VRPRIM->dobav == "D"
            cSvrha_pl := id
            select_o_partner( fin_pripr->idpartner )
            cU_korist := id
            cKome_txt := naz
            cKome_zr := ziror
            cKome_sj := mjesto
            cNacPl := "1"
            Box(, 3, 70 )
            _IdBanka2 := Space( 3 )
            _u_korist := cu_korist
            _kome_txt := cKome_txt
            _KOME_ZR := cKome_zr
            Beep( 1 )
            cIdBanka2 := Space( 3 )
            @ box_x_koord() + 1, box_y_koord() + 2 SAY ckome_txt + " " + fin_pripr->brdok + Str( fin_pripr->iznosbhd, 12, 2 )
            @ box_x_koord() + 2, box_y_koord() + 2 SAY "Primaoc (partner/banka):" GET _u_korist VALID p_partner( @_u_korist )  PICT "@!"
            @ box_x_koord() + 2, Col() + 2 GET _IdBanka2 VALID {|| virm_odredi_ziro_racun( cu_korist, @_IdBanka2 ), SetPrimaoc() }
            READ
            cKome_txt := _kome_txt
            cKome_zr := _KOME_ZR
            cu_korist := _u_korist

            BoxC()
            // if cnacpl=="2"
            // ckome_zr:=dziror
            // endif
         ELSE
            SELECT fin_pripr
            SKIP
            LOOP
         ENDIF
      ENDIF

      cTmp_doz := fin_pripr->brdok

      IF !Empty( cTmp_doz )
         cTmp_doz := "rn: " + cTmp_doz
      ENDIF

      select_o_partner( gVirmFirma )


      SELECT virm_pripr
      APPEND BLANK
      REPLACE rbr WITH ++nrbr, ;
         mjesto WITH gmjesto, ;
         svrha_pl WITH csvrha_pl, ;
         iznos WITH fin_pripr->iznosbhd, ;
         na_teret  WITH gVirmFirma, ;
         Ko_Txt WITH cKo_txt, ;
         Ko_ZR WITH  cKo_zr, ;
         kome_txt WITH VRPRIM->naz, ;
         kome_sj  WITH "", ;
         kome_zr WITH VRPRIM->racun, ;
         dat_upl WITH dDatVir, ;
         svrha_doz WITH Trim( VRPRIM->pom_txt ) + ;
         " " + cTmp_doz + " " + cDOpis


      // Ko_SJ  with partn->Mjesto,;
      // nacpl with VRPRIM->nacin_pl, ;
      // orgjed with gorgjed,;
      // dat_dpo with dDatVir,;
      // sifra with VRPRIM->sifra

      // if nacpl=="2"
      // replace iznos with fin_pripr->iznosDEM,;
      // ko_zr with partn->dziror
      // endif

      IF VRPRIM->dobav == "D"
         IF ValType( cKome_Txt ) <> "C"  .OR. Empty( ckome_Txt )
            Beep( 2 )
            Msg( "Nije pronadjen dobavljac !!" )
         ELSE
            REPLACE kome_txt WITH cKome_txt, ;
               kome_zr WITH cKome_zr, ;
               kome_sj WITH cKome_sj, ;
               u_korist WITH cU_korist

            // if cNacPl=="1"
            REPLACE iznos WITH fin_pripr->iznosbhd
            // nacpl with   cNacPl
            // else
            // replace iznos with fin_pripr->iznosdem ,;
            // nacpl with   cNacPl
            // endif
         ENDIF
      ENDIF

      SELECT fin_pripr
      SKIP

   ENDDO

   SELECT virm_pripr

  ---- virm_popuna_javnih_prihoda()
   // popuni polja javnih prihoda

   RETURN
*/
