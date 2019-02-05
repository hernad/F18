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


FUNCTION Get1_RN()

   LOCAL nNV

   IF nRbr == 1 .AND. kalk_is_novi_dokument()
      _DatFaktP := _datdok
   ENDIF

   IF nRbr > 900
      beep( 2 )
      Msg( "Razduzenja materijala se ne mogu ispravljati" )
      KEYBOARD K_ESC
      nKalkStrana := 3
      RETURN  LastKey()
   ENDIF

   IF nRbr == 1  .OR. !kalk_is_novi_dokument() .OR. gMagacin == "1"
      @  box_x_koord() + 6, box_y_koord() + 2   SAY8 "  ZATVORITI RADNI NALOG :" GET _IdZaduz2 PICT "@!"
      @  box_x_koord() + 7, box_y_koord() + 2   SAY8 "Mag. proizvodnje u toku :" GET _IdKonto2 PICT "@!" VALID P_Konto( @_IdKonto2 )
      @ box_x_koord() + 10, box_y_koord() + 2   SAY8 "Mag. gotovih proizvoda zadužuje:" GET _IdKonto VALID  P_Konto( @_IdKonto, 24 ) PICT "@!"
      READ
      _BrFaktP := _idzaduz2
      // sada trazim trebovanja u proizvod. u toku i filujem u stavke od 100 pa nadalje
      // ove stavke imace  mu_i=="5", mkonto=_idkonto2, nc,nv
      // "KALKi7","idFirma+mkonto+IDZADUZ2+idroba+dtos(datdok)","KALK")

      nTPriPrec := RecNo()


      SELECT kalk_pripr
      GO BOTTOM
      my_flock()
      DO WHILE !Bof() .AND. Val( rbr ) > 900
         SKIP -1
         nTrec := RecNo()
         SKIP
         my_delete()
         GO nTrec
      ENDDO
      my_unlock()
      my_dbf_pack()

      // SELECT kalk_doks
      // SET ORDER TO TAG "2"
      // CREATE_INDEX("DOKSi2","IdFirma+MKONTO+idzaduz2+idvd+brdok","DOKS")


      IF find_kalk_doks_by_broj_radnog_naloga( _IdFirma, _IdKonto, _IdZaduz2, "RN" )  // npr: 10-1200-564-RN, gdje je 1200 magacin gotovih proizvoda
         Beep( 2 )
         Msg( "Vec postoji dokument RN broj " + kalk_doks->brdok + " za radni nalog:"  + _IdZaduz2 )
         SELECT kalk_pripr
         KEYBOARD K_ESC
         nKalkStrana := 3
         RETURN  LastKey()
      ENDIF

      find_kalk_doks_by_broj_radnog_naloga( _IdFirma, _IdKonto2, _IdZaduz2, NIL ) // 10-1100-564, 1100 - magacin sirovina, gdje su ovo ulazi
      GO TOP
      nII := 0
      nCntR := 0
      DO WHILE !Eof() // proci kroz sve kalk dokumente za odredjeni idzaduz2 - broj radnog naloga

         find_kalk_by_broj_dokumenta( kalk_doks->idfirma,  kalk_doks->idvd, kalk_doks->brdok )
         nKolicina := 0
         nNabV := 0
         DO WHILE !Eof() // napuni kalk_pripr sa ovim kalk dokumentom

            SELECT kalk_pripr
            SET ORDER TO TAG "3" // kalk pripr tag 3 idFirma+idvd+brdok+idroba+rbr
            SEEK _idfirma + _idvd + _brdok + kalk->idroba + "9" // nadji odgovoarajucu stavku iznad 900

            IF !Found()
               ++nCntR
               APPEND BLANK
               REPLACE idfirma WITH _idfirma, idvd WITH _idvd, brdok WITH _brdok, ;
                  rbr  WITH Str( 900 + nCntR, 3 ), idroba WITH kalk->idroba, ;
                  mkonto WITH kalk->mkonto, ;
                  mu_i WITH "5", ;
                  error WITH "0", ;
                  datdok WITH _datdok, ;
                  datfaktp WITH _datdok, ;
                  idzaduz2 WITH _idzaduz2, ;
                  idkonto WITH _idkonto, idkonto2 WITH _idkonto2, ;
                  idtarifa WITH "XXXXXX", ;
                  brfaktp WITH _brfaktp

            ENDIF

            my_rlock()
            IF KALK->mu_i == "1"
               REPLACE kolicina WITH kalk->kolicina + kolicina,  nc WITH nc + kalk->( kolicina * nc )
            ELSEIF KALK->mu_i = "5"
               REPLACE kolicina WITH -kalk->kolicina + kolicina, nc WITH nc - kalk->( kolicina * nc )
            ENDIF
            my_unlock()

            SELECT kalk_pripr
            SET ORDER TO TAG "1"
            SELECT kalk
            SKIP

         ENDDO

         SELECT kalk_doks
         SKIP
      ENDDO

      SELECT kalk_pripr
      SET ORDER TO TAG "1"
      GO TOP
      nNV := 0
      my_flock()
      DO WHILE !Eof()
         IF Val( RBr ) > 900
            nNV += field->NC  // ovo je u stvari nabavna vrijednost
            REPLACE NC WITH field->NC / field->Kolicina,  vpc WITH field->NC, fcj WITH field->nc
         ENDIF
         SKIP
      ENDDO
      my_unlock()

      GO  nTPriPrec
      SELECT kalk_pripr
      // IF gNW <> "X"
      // @ box_x_koord() + 10, box_y_koord() + 42  SAY "Zaduzuje: "   GET _IdZaduz  PICT "@!" VALID Empty( _idZaduz ) .OR. p_partner( @_IdZaduz, 24 )
      // ENDIF
      READ

      ESC_RETURN K_ESC
   ELSE

      @ box_x_koord() + 10, box_y_koord() + 2   SAY "Mag. gotovih proizvoda zaduzuje "
      ?? _IdKonto
      // IF gNW <> "X"
      // @ box_x_koord() + 10, box_y_koord() + 42  SAY "Zaduzuje: "; ?? _IdZaduz
      // ENDIF
   ENDIF


   @ box_x_koord() + 11, box_y_koord() + 66 SAY "Tarif.br->"
   @ box_x_koord() + 12, box_y_koord() + 2  SAY "Proizvod  " GET _IdRoba PICT "@!" ;
      valid  {|| P_Roba( @_IdRoba ), say_from_valid( 12, 25, Trim( roba->naz ) + " (" + ROBA->jmj + ")", 40 ), ;
      _IdTarifa := iif( kalk_is_novi_dokument(), ROBA->idtarifa, _IdTarifa ), .T. }
   @ box_x_koord() + 12, box_y_koord() + 70 GET _IdTarifa VALID P_Tarifa( @_IdTarifa )

   read
   ESC_RETURN K_ESC

   select_o_koncij( _idkonto )
   SELECT kalk_pripr

   _MKonto := _Idkonto
   _MU_I := "1"
   // check_datum_posljednje_kalkulacije()

   select_o_tarifa( _IdTarifa  )
   SELECT kalk_pripr  // napuni tarifu

   @ box_x_koord() + 13, box_y_koord() + 2   SAY8 "Količina " GET _Kolicina PICTURE PicKol VALID _Kolicina <> 0
   READ
   IF kalk_is_novi_dokument()
      select_o_roba( _IdRoba )
      IF koncij->naz == "P2"
         _VPC := PlC
      ELSE
         _VPC := KoncijVPC()
      ENDIF
      _TCarDaz := "%"
      _CarDaz := 0
   ENDIF

   SELECT kalk_pripr
   IF _tmarza <> "%"  // procente ne diraj
      _Marza := 0
   ENDIF

   IF nRbr == 1
      _fcj := _fcj2 := nNV / _kolicina
   ENDIF

   @ box_x_koord() + 15, box_y_koord() + 2   SAY "N.CJ.(DEM/JM):"
   @ box_x_koord() + 15, box_y_koord() + 50  GET _FCJ PICTURE PicDEM VALID _fcj > 0 when {|| _fcj := iif( nRbr > 1 .AND. kalk_is_novi_dokument(), _vpc, _fcj ), V_kol10() }

/*
   --IF gNW <> "X"
      @ box_x_koord() + 18, box_y_koord() + 2   SAY "Transport. kalo:"
      @ box_x_koord() + 18, box_y_koord() + 40  GET _GKolicina PICTURE PicKol

      @ box_x_koord() + 19, box_y_koord() + 2   SAY "Ostalo kalo:    "
      @ box_x_koord() + 19, box_y_koord() + 40  GET _GKolicin2 PICTURE PicKol
   ENDIF
*/

   read; ESC_RETURN K_ESC

   _FCJ2 := _FCJ * ( 1 -_Rabat / 100 )

   RETURN LastKey()





/* Get2_RN()
 *     Druga strana maske za unos dokumenta tipa RN
 */

FUNCTION Get2_RN()

   // {
   LOCAL cSPom := " (%,A,U,R) "
   PRIVATE getlist := {}

   IF Empty( _TPrevoz ); _TPrevoz := "%"; ENDIF
   IF Empty( _TCarDaz ); _TCarDaz := "%"; ENDIF
   IF Empty( _TBankTr ); _TBankTr := "%"; ENDIF
   IF Empty( _TSpedTr ); _TSpedtr := "%"; ENDIF
   IF Empty( _TZavTr );  _TZavTr := "%" ; ENDIF
   IF Empty( _TMarza );  _TMarza := "%" ; ENDIF

   @ box_x_koord() + 2, box_y_koord() + 2     SAY cRNT1 + cSPom GET _TPrevoz VALID _TPrevoz $ "%AUR" PICTURE "@!"
   @ box_x_koord() + 2, box_y_koord() + 40    GET _Prevoz PICTURE  PicDEM

   @ box_x_koord() + 3, box_y_koord() + 2     SAY cRNT2 + cSPom  GET _TBankTr VALID _TBankTr $ "%AUR" PICT "@!"
   @ box_x_koord() + 3, box_y_koord() + 40    GET _BankTr PICTURE PicDEM

   @ box_x_koord() + 4, box_y_koord() + 2     SAY cRNT3 + cSPom GET _TSpedTr VALID _TSpedTr $ "%AUR" PICT "@!"
   @ box_x_koord() + 4, box_y_koord() + 40    GET _SpedTr PICTURE PicDEM

   @ box_x_koord() + 5, box_y_koord() + 2     SAY cRNT4 + cSPom GET _TCarDaz VALID _TCarDaz $ "%AUR" PICTURE "@!"
   @ box_x_koord() + 5, box_y_koord() + 40    GET _CarDaz PICTURE PicDEM

   @ box_x_koord() + 6, box_y_koord() + 2     SAY cRNT5 + cSPom GET _TZavTr VALID _TZavTr $ "%AUR" PICTURE "@!"
   @ box_x_koord() + 6, box_y_koord() + 40    GET _ZavTr PICTURE PicDEM ;
      VALID {|| kalk_when_valid_nc_ulaz(), .T. }

   @ box_x_koord() + 8, box_y_koord() + 2     SAY "CIJENA KOST.  "
   @ box_x_koord() + 8, box_y_koord() + 50    GET _NC     PICTURE PicDEM

   IF koncij->naz <> "N1"  // vodi se po vpc
      PRIVATE cProracunMarzeUnaprijed := " "
      @ box_x_koord() + 10, box_y_koord() + 2    SAY "Magacin. Marza            :" GET _TMarza VALID _Tmarza $ "%AU" PICTURE "@!"
      @ box_x_koord() + 10, box_y_koord() + 40 GET _Marza PICTURE PicDEM
      @ box_x_koord() + 10, Col() + 1 GET cProracunMarzeUnaprijed PICT "@!"
      IF koncij->naz == "P2"
         @ box_x_koord() + 12, box_y_koord() + 2    SAY "PLANSKA CIJENA (PLC)        :"
      ELSE
         @ box_x_koord() + 12, box_y_koord() + 2    SAY "VELEPRODAJNA CJENA  (VPC)   :"
      ENDIF
      @ box_x_koord() + 12, box_y_koord() + 50 GET _VPC    PICTURE PicDEM;
         VALID {|| kalk_10_pr_rn_valid_vpc_set_marza_polje_nakon_iznosa( @cProracunMarzeUnaprijed ) }

      READ
      IF koncij->naz == "P2"
         IF roba->plc == 0
            IF Pitanje(, "Staviti PLC  u sifrarnik ?", "D" ) == "D"
               SELECT roba
               REPLACE plc WITH _vpc
               SELECT kalk_pripr
            ENDIF
         ENDIF
      ELSE
         IF KoncijVPC() == 0 .OR. Round( KoncijVPC(), 4 ) <> Round( _vpc, 4 )
            kalk_set_vpc_sifarnik( _vpc, Round( KoncijVPC(), 4 ) <> Round( _vpc, 4 ) )
         ELSE
            IF ( _vpc <> KoncijVPC() )
               Beep( 1 )
               Msg( "Cijena u sifrarniku je " + Str( KoncijVPC(), 11, 3 ), 6 )
            ENDIF
         ENDIF
      ENDIF
   ELSE
      READ
      _Marza := 0; _TMarza := "A"; _VPC := _NC
   ENDIF

   _MKonto := _Idkonto; _MU_I := "1"
   nKalkStrana := 3

   RETURN LastKey()
