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

STATIC PicDEM := "99999999.99"
STATIC PicBHD := "9999999999.99"
STATIC PicKol := "9999999.99"


// ---------------------------------------------
// inventura - menij
// ---------------------------------------------
FUNCTION mat_inventura()

   LOCAL _opc := {}
   LOCAL _opcexe := {}
   LOCAL _izbor := 1

   AAdd( _opc, "1. unos,ispravka stvarnih kolicina            " )
   AAdd( _opcexe, {|| mat_unos_pop_listi() } )
   AAdd( _opc, "2. pregled unesenih kolicina" )
   AAdd( _opcexe, {|| mat_pregl_unesenih_stavki() } )
   AAdd( _opc, "3. obracun inventure" )
   AAdd( _opcexe, {|| mat_obracun_inv() } )
   AAdd( _opc, "4. nalog sravnjenja" )
   AAdd( _opcexe, {|| mat_nal_inventure() } )
   AAdd( _opc, "5. inventura - obrac r.por" )
   AAdd( _opcexe, {|| mat_inv_obr_poreza() } )

   f18_menu( "invnt", .F., _izbor, _opc, _opcexe )

   my_close_all_dbf()

   RETURN


// -------------------------------------------
// unos kolicina
// -------------------------------------------
FUNCTION mat_unos_pop_listi()

   LOCAL _opc := {}
   LOCAL _opcexe := {}
   LOCAL _izbor := 1

   AAdd( _opc, "1. generisanje stavki inventure             " )
   AAdd( _opcexe, {|| mat_inv_gen() } )
   AAdd( _opc, "2. pregled tabele " )
   AAdd( _opcexe, {|| mat_inv_tabela() } )
   AAdd( _opc, "3. popisna lista za inveturisanje" )
   AAdd( _opcexe, {|| mat_popisna_lista() } )

   f18_menu( "bedpl", .F., _izbor, _opc, _opcexe )

   my_close_all_dbf()

   RETURN


// ------------------------------------------------
// ispravka stvarnih kolicina
// ------------------------------------------------
FUNCTION mat_inv_gen()

   LOCAL _id_firma := self_organizacija_id()
   LOCAL _datum := Date()
   LOCAL _konto := Space( 7 )
   LOCAL _r_br
   LOCAL _kolicina
   LOCAL _iznos
   LOCAL _iznos_2
   LOCAL _cijena
   LOCAL cIdRoba
   LOCAL _vars := hb_Hash()
   LOCAL _partner, _partn_usl, _id_partner
   LOCAL _filter

   o_konto()
   o_partner()

   IF !_get_inv_vars( @_vars )
      my_close_all_dbf()
      RETURN
   ENDIF

   _konto := _vars[ "konto" ]
   _datum := _vars[ "datum" ]
   _id_firma := Left( _vars[ "id_firma" ], 2 )
   _partner := _vars[ "partner" ]
   _id_partner := ""

   O_MAT_INVENT
   O_MAT_SUBAN

   msgO( "Generisem stavke inventure..." )

   SELECT MAT_INVENT
   my_dbf_zap()


   _r_br := 0
   _kolicina := 0
   _iznos := 0
   _iznos_2 := 0
   _cijena := 0

   SELECT mat_suban
   SET ORDER TO TAG "3"

   _filter := "datdok <= " + dbf_quote( _datum )

   IF !Empty( _partner )
      _id_partner := _partner
      _filter += ".and. idpartner == " + dbf_quote( _partner )
   ENDIF

   SET FILTER TO &( _filter )

   SEEK _id_firma + _konto

   NFOUND CRET

   DO WHILE !Eof() .AND. _id_firma == field->IdFirma .AND. _konto == field->Idkonto

      cIdRoba := field->idroba
      _kolicina := 0
      _iznos := 0
      _iznos_2 := 0

      DO WHILE !Eof() .AND. _id_firma == field->IdFirma .AND. _konto == field->IdKonto .AND. cIdRoba == field->IdRoba

         IF field->d_p = "1"
            _kolicina += field->Kolicina
         ELSE
            _kolicina -= field->Kolicina
         ENDIF

         IF field->d_p = "1"
            _iznos += field->Iznos
            _iznos_2 += field->Iznos2
         ELSE
            _iznos -= field->Iznos
            _iznos_2 -= field->Iznos2
         ENDIF

         SKIP

      ENDDO

      IF Round( _kolicina, 4 ) <> 0
         _cijena := _iznos / _kolicina
      ELSEIF Round( _iznos, 4 ) <> 0
         _cijena := 0
      ENDIF

      SELECT MAT_INVENT
      APPEND BLANK

      _vars := dbf_get_rec()
      _vars[ "idroba" ] := cIdRoba
      _vars[ "rbr" ] := Str( ++_r_br, 4 )
      _vars[ "kolicina" ] := _kolicina
      _vars[ "cijena" ] := _cijena
      _vars[ "iznos" ] := _iznos
      _vars[ "iznos2" ] := _iznos_2
      _vars[ "idpartner" ] := _id_partner

      dbf_update_rec( _vars )

      SELECT mat_suban

   ENDDO

   msgC()

   my_close_all_dbf()

   RETURN




FUNCTION mat_inv_tabela()

   LOCAL _cnt
   LOCAL _header := ""
   PRIVATE kol := {}
   PRIVATE imekol := {}

   O_MAT_INVENT
   // o_roba()
   // o_sifk()
   // o_sifv()
   // o_partner()

   SELECT MAT_INVENT
   GO TOP

   SET ORDER TO TAG "1"

   AAdd( ImeKol, { "R.br", {|| rbr } } )
   AAdd( ImeKol, { PadR( "Roba", 60 ), {|| pr_roba( idroba ) } } )
   AAdd( ImeKol, { "Cijena", {|| cijena } } )
   AAdd( ImeKol, { "Kolicina", {|| kolicina } } )
   AAdd( ImeKol, { "Iznos " + valuta_domaca_skraceni_naziv(), {|| iznos } } )
   AAdd( ImeKol, { "Partner", {|| idpartner } } )

   FOR _cnt := 1 TO Len( ImeKol )
      AAdd( Kol, _cnt )
   NEXT

   _header := "<c-T> Brisi stavku <ENT> Ispravka <c-A> Ispravka svih stavki <c-N> Nova stavka <c-Z> Brisi"

   my_browse( "USKSP", f18_max_rows() - 4, f18_max_cols() - 3, {|| _ed_pop_list_khandler() }, _header, ;
      "Pregled popisne liste..." )

   my_close_all_dbf()

   RETURN .T.


// prikaz naziva robe u tabeli pregleda inventure
STATIC FUNCTION pr_roba( id_roba )

   LOCAL _txt := "!!! u sifrarniku nema stavke"
   LOCAL nDbfArea := Select()

   SELECT roba
   HSEEK id_roba

   IF Found()
      _txt := PadL( AllTrim( id_roba ), 10 )
      _txt += " - "
      _txt += PadR( AllTrim( roba->naz ), 40 )
   ENDIF

   SELECT ( nDbfArea )

   RETURN _txt

// -----------------------------------------------
// -----------------------------------------------
STATIC FUNCTION _ed_pop_list_khandler()

   LOCAL _new
   LOCAL _vars
   LOCAL _r_br

   DO CASE

      // nova ili ispravka
   CASE Ch == K_ENTER .OR. Ch == K_CTRL_N

      _new := .F.

      IF Ch == K_CTRL_N
         _new := .T.
      ENDIF

      IF Ch == K_CTRL_N
         APPEND BLANK
      ENDIF

      _vars := dbf_get_rec()

      Box( "edpopl", 6, 70, .F., "Stavka popisne liste" )

      SET CURSOR ON

      _r_br := Val( _vars[ "rbr" ] )

      _form_data( @_r_br, @_vars )

      READ

      _vars[ "rbr" ] := PadL( AllTrim( Str( _r_br, 4 ) ), 4 )

      BoxC()

      IF LastKey() == K_ESC .AND. _new == .T.
         my_delete_with_pack()
         RETURN DE_CONT
      ENDIF

      dbf_update_rec( _vars )

      RETURN DE_REFRESH

   CASE Ch == K_CTRL_A

      GO TOP

      Box( "edpopl", 6, 70, .F., "Ispravka popisne liste.." )

      DO WHILE !Eof()

         _vars := dbf_get_rec()

         SET CURSOR ON

         _r_br := Val( _vars[ "rbr" ] )
         _form_data( @_r_br, @_vars )

         READ

         _vars[ "rbr" ] := PadL( AllTrim( Str( _r_br, 4 ) ), 4 )
         IF LastKey() == K_ESC
            BoxC()
            RETURN DE_REFRESH
         ENDIF

         dbf_update_rec( _vars )

         IF LastKey() == K_PGUP
            SKIP -1
         ELSE
            SKIP
         ENDIF
      ENDDO

      BoxC()

      SKIP -1
      RETURN DE_REFRESH

   CASE Ch == K_CTRL_T

      IF Pitanje( "ppl", "Zelite izbrisati ovu stavku (D/N) ?", "N" ) == "D"
         my_delete_with_pack()
         RETURN DE_REFRESH
      ENDIF
      RETURN DE_CONT

   CASE Ch == K_CTRL_Z

      IF Pitanje( "ppl", "Zelite sve stavke (D/N) !!!!????", "N" ) == "D"
         my_dbf_zap()

         GO TOP
         RETURN DE_REFRESH
      ENDIF
      RETURN DE_CONT

   ENDCASE

   RETURN DE_CONT



// ------------------------------------
// forma za unos podataka
// ------------------------------------
STATIC FUNCTION _form_data( r_br, vars )

   LOCAL _ed_id_roba
   LOCAL _ed_cijena
   LOCAL _ed_kolicina
   LOCAL _ed_iznos

   _ed_id_roba := vars[ "idroba" ]
   _ed_cijena := vars[ "cijena" ]
   _ed_kolicina := vars[ "kolicina" ]
   _ed_iznos := vars[ "iznos" ]

   @ box_x_koord() + 1, box_y_koord() + 2 SAY "Red.br:  " GET r_br PICT "9999"
   @ box_x_koord() + 3, box_y_koord() + 2 SAY "Roba:    " GET _ed_id_roba VALID P_Roba( @_ed_id_roba, 3, 24 )
   @ box_x_koord() + 4, box_y_koord() + 2 SAY "Cijena:  " GET _ed_cijena PICT PicDEM
   @ box_x_koord() + 5, box_y_koord() + 2 SAY "Kolicina:" GET _ed_kolicina PICT PicKol ;
      VALID {|| _ed_iznos := _ed_cijena * _ed_kolicina, ;
      QQOut( "  Iznos:", Transform( _ed_iznos, PicDEM ) ), Inkey( 5 ), .T. }

   vars[ "idroba" ] := _ed_id_roba
   vars[ "cijena" ] := _ed_cijena
   vars[ "kolicina" ] := _ed_kolicina
   vars[ "iznos" ] := _ed_iznos

   RETURN



// -------------------------------------------------
// vraca uslove standardne kod inventure
// -------------------------------------------------
STATIC FUNCTION _get_inv_vars( vars )

   LOCAL _ret := .T.
   LOCAL _id_firma := self_organizacija_id()
   LOCAL _konto := Space( 7 )
   LOCAL _datum := Date()
   LOCAL _partner := Space( 6 )

   _id_firma := fetch_metric( "mat_inv_firma", my_user(), _id_firma )
   _konto := fetch_metric( "mat_inv_konto", my_user(), _konto )
   _datum := fetch_metric( "mat_inv_datum", my_user(), _datum )
   _partner := fetch_metric( "mat_inv_partner", my_user(), _partner )

   Box( "", 5, 60, .F. )

   @ box_x_koord() + 1, box_y_koord() + 6 SAY  "PREGLED UNESENIH KOLICINA"


    @ box_x_koord() + 2, box_y_koord() + 2 SAY "Firma "
    ?? self_organizacija_id(), "-", self_organizacija_naziv()


   @ box_x_koord() + 3, box_y_koord() + 2 SAY "  Konto " GET _konto ;
      VALID P_Konto( @_konto )
   @ box_x_koord() + 4, box_y_koord() + 2 SAY "Partner " GET _partner ;
      VALID Empty( _partner ) .OR. p_partner( @_partner )
   @ box_x_koord() + 5, box_y_koord() + 2 SAY "  Datum " GET _datum

   READ

   BoxC()

   IF LastKey() == K_ESC
      _ret := .F.
      RETURN _ret
   ENDIF

   // snimi u hash matricu parametre...
   vars[ "id_firma" ] := Left( _id_firma, 2 )
   vars[ "konto" ] := _konto
   vars[ "datum" ] := _datum
   vars[ "partner" ] := _partner

   // snimi u sql/db
   set_metric( "mat_inv_firma", my_user(), _id_firma )
   set_metric( "mat_inv_konto", my_user(), _konto )
   set_metric( "mat_inv_datum", my_user(), _datum )
   set_metric( "mat_inv_partner", my_user(), _partner )

   RETURN _ret




FUNCTION mat_pregl_unesenih_stavki()

   LOCAL _id_firma
   LOCAL _partner
   LOCAL _konto
   LOCAL _datum
   LOCAL _r_br
   LOCAL _vars := hb_Hash()

   O_MAT_INVENT
   // o_roba()
   // o_sifk()
   // o_sifv()
   // o_konto()
   // o_partner()

   IF !_get_inv_vars( @_vars )
      my_close_all_dbf()
      RETURN
   ENDIF

   _konto := _vars[ "konto" ]
   _datum := _vars[ "datum" ]
   _id_firma := Left( _vars[ "id_firma" ], 2 )
   _partner := _vars[ "partner" ]

   SELECT MAT_INVENT
   SET ORDER TO TAG "1"
   GO TOP

   START PRINT CRET
   ?

   _r_br := 0

   m := "---- ---------- ---------------------------------------- --- ---------- ------------ -------------"

   ZPrUnKol( _vars, m )

   nU := 0
   nC1 := 60

   DO WHILE !Eof()

      IF PRow() > 62
         FF
         ZPrUnKol( _vars, m )
      ENDIF

      SELECT roba
      HSEEK MAT_INVENT->IdRoba
      SELECT mat_invent

      @ PRow() + 1, 0 SAY ++_r_br PICTURE '9999'
      @ PRow(), PCol() + 1 SAY field->idroba
      @ PRow(), PCol() + 1 SAY PadR( roba->naz, 40 )
      @ PRow(), PCol() + 1 SAY roba->jmj
      @ PRow(), PCol() + 1 SAY field->Kolicina PICTURE '999999.999'
      @ PRow(), PCol() + 1 SAY field->Cijena PICTURE '99999999.999'
      nC1 := PCol() + 1
      @ PRow(), PCol() + 1 SAY nIznos := field->Cijena * field->kolicina PICTURE '999999999.99'
      nU += nIznos

      SKIP
   ENDDO

   IF PRow() > 60
      FF
      ZPrUnKol( _vars, m )
   ENDIF

   ? m
   ? "UKUPNO:"
   @ PRow(), nC1 SAY nU PICTURE '999999999.99'
   ? m

   ENDPRINT
   my_close_all_dbf()

   RETURN


// zaglavlje
STATIC FUNCTION ZPrUnKol( vars, line )

   P_COND
   ?

   @ PRow(), 0 SAY "MAT.P: PREGLED UNESENIH KOLICINA NA DAN:"
   @ PRow(), PCol() + 1 SAY vars[ "datum" ]
   @ PRow() + 1, 0 SAY "Firma:"
   @ PRow(), PCol() + 1 SAY vars[ "id_firma" ]

   select_o_partner( vars[ "id_firma" ] )

   @ PRow(), PCol() + 1 SAY AllTrim( field->naz )
   @ PRow(), PCol() + 1 SAY AllTrim( field->naz2 )

   select_o_partner( vars[ "partner" ] )
   @ PRow() + 1, 0 SAY "Partner:"
   @ PRow(), PCol() + 1 SAY AllTrim( field->naz )
   @ PRow(), PCol() + 1 SAY AllTrim( field->naz2 )

   select_o_konto( vars[ "konto" ] )

   ? "Konto: ", vars[ "konto" ], AllTrim( field->naz )

   SELECT MAT_INVENT

   ? line

   ? "*R. *  SIFRA   *         NAZIV ARTIKLA                  *J. * KOLICINA *   CIJENA   *   IZNOS    *"
   ? "*B. * ARTIKLA  *                                        *MJ.*          *            *            *"

   ? line

   RETURN



FUNCTION mat_obracun_inv()

   cIdF := self_organizacija_id()
   cIdK := Space( 7 )
   cIdD := Date()
   cIdF := Left( cIdF, 2 )

   o_partner(); o_konto()
   Box( "", 4, 60 )
   @ box_x_koord() + 1, box_y_koord() + 6 SAY "OBRACUN INVENTURE"

  @ box_x_koord() + 2, box_y_koord() + 2 SAY "Firma "; ?? self_organizacija_id(), "-", self_organizacija_naziv()

   @ box_x_koord() + 3, box_y_koord() + 2 SAY "Konto  " GET cIdK VALID P_Konto( @cIdK )
   @ box_x_koord() + 4, box_y_koord() + 2 SAY "Datum  " GET cIdD
   READ; ESC_BCR
   BoxC()

   picD := '@Z 99999999999.99'
   picD1 := '@Z 99999999.99'
   picK := '@Z 99999.99'

   O_MAT_INVENT
   // o_roba()
   // o_sifk()
   // o_sifv()
   O_MAT_SUBAN
   SET ORDER TO TAG "3"
   SET FILTER TO DatDok <= cIdD

   SELECT MAT_INVENT
   GO TOP

   START PRINT CRET

   A := 0

   nRBr := 0
   SK := SV := 0
   KK := KV := 0
   VK := VV := MK := MV := 0

   SV1 := KV1 := 0
   VV1 := MV1 := 0

   DO WHILE !Eof()

      IF A == 0
         P_COND
         @ A, 0 SAY "MAT.P:INVENTURNA LISTA NA DAN:"; @ A, PCol() + 1 SAY cIdD
         @++A, 0 SAY "Firma:"
         @ A, PCol() + 1 SAY cIdF
         select_o_partner( cIdF )
         @ A, PCol() + 1 SAY naz; @ A, PCol() + 1 SAY naz2

         @++A, 0 SAY "KONTO:"
         @ A, PCol() + 1 SAY cIdK
         select_o_konto( cIdK )
         @ A, PCol() + 1 SAY naz
         SELECT MAT_INVENT
         A += 2
         @++A, 0 SAY "---- ---------- -------------------- --- ---------- -------------------- -------------------- -------------------- ---------------------"
         @++A, 0 SAY "*R. *  SIFRA   *  NAZIV ARTIKLA     *J. *  CIJENA  *   STVARNO STANJE   *   KNJIZNO STANJE   *   RAZLIKA VISAK    *   RAZLIKA MANJAK   *"
         @++A, 0 SAY "                                                    -------------------- -------------------- -------------------- ---------------------"
         @++A, 0 SAY "*B. * ARTIKLA  *                    *MJ.*          *KOLICINA*   IZNOS   *KOLICINA*   IZNOS   *KOLICINA*   IZNOS   *KOLICINA*   IZNOS   *"
         @++A, 0 SAY "---- ---------- -------------------- --- ---------- -------- ----------- -------- ----------- -------- ----------- -------- ------------"
      ENDIF

      IF A > 63; EJECTA0;  ENDIF

      SK := Kolicina; SV := Iznos

      cIdRoba := IdRoba
      SELECT mat_suban
      SEEK cIdF + cIdK + cIdRoba
      kK := kV := 0         // KK - knjizena kolicina, KV - knjizena vrijednost
      DO WHILE !Eof() .AND. cIdF = IdFirma .AND. cIdK = IdKonto .AND. cIdRoba = IdRoba
         IF D_P = "1"; kK += Kolicina; ELSE; kK -= Kolicina; ENDIF
         IF D_P = "1"; kV += Iznos; ELSE; kV -= Iznos; ENDIF
         SKIP
      ENDDO



      RK := SK - KK
      RV := SV - KV

      VK := MK := 0
      IF RK >= 0; VK := RK; ELSE; MK := -RK; ENDIF
      VV := MV := 0
      IF RV >= 0; VV := RV; ELSE; MV := -RV; ENDIF


      @++A, 0 SAY ++nRBr PICTURE "9999"
      @ A, 5 SAY cIdRoba
      SELECT ROBA; HSEEK cIdRoba
      @ A, 16 SAY Naz PICTURE Replicate ( "X", 20 )
      @ A, 37 SAY jmj
      SELECT MAT_INVENT
      @ A, 40       SAY  Cijena PICTURE picD1
      @ A, PCol() + 1 SAY  Round( SK, 2 ) PICTURE picK
      @ A, PCol() + 1 SAY  Round( SV, 2 ) PICTURE picD1
      @ A, PCol() + 1 SAY  Round( KK, 2 )  PICTURE picK
      @ A, PCol() + 1 SAY  Round( KV, 2 ) PICTURE picD1
      @ A, PCol() + 1 SAY  Round( VK, 2 ) PICTURE picK
      @ A, PCol() + 1 SAY  Round( VV, 2 ) PICTURE picD1
      @ A, PCol() + 1 SAY  Round( MK, 2 ) PICTURE picK
      @ A, PCol() + 1 SAY  Round( MV, 2 ) PICTURE picD1

      SKIP
      SV1 += SV; KV1 += KV
      VV1 += VV; MV1 += MV

   ENDDO

   @++A, 0 SAY "---- ---------- -------------------- --- ---------- -------- ----------- -------- ----------- -------- ----------- -------- ------------"
   @++A, 0 SAY "UKUPNO:"
   @ a, 40       SAY 0 PICTURE PicD1
   @ A, PCol() + 1 SAY 0 PICTURE picK
   @ A, PCol() + 1 SAY Round( SV1, 2 ) PICTURE picD1
   @ A, PCol() + 1 SAY 0 PICTURE PicK
   @ A, PCol() + 1 SAY Round( KV1, 2 ) PICTURE picD1
   @ A, PCol() + 1 SAY 0 PICTURE PicK
   @ A, PCol() + 1 SAY Round( VV1, 2 ) PICTURE picD1
   @ A, PCol() + 1 SAY 0 PICTURE PicK
   @ A, PCol() + 1 SAY Round( MV1, 2 ) PICTURE picD1
   @++A, 0 SAY "---- ---------- -------------------- --- ---------- -------- ----------- -------- ----------- -------- ----------- -------- ------------"

   EJECTNA0
   ENDPRINT
   my_close_all_dbf()

   RETURN


FUNCTION mat_nal_inventure()

   cIdF := self_organizacija_id()
   cIdK := Space( 7 )
   cIdD := Date()
   IF File( my_home() + "invent.mem" )
      RESTORE FROM ( my_home() + "invent.mem" ) additive
   ENDIF
   cIdF := Left( cIdF, 2 )
   cIdZaduz := Space( 6 )
   cidvn := "  "; cBrNal := Space( 4 )
   cIdTipDok := "09"
   o_partner(); o_konto()
   Box( "", 7, 60 )
   @ box_x_koord() + 1, box_y_koord() + 6 SAY "FORMIRANJE NALOGA IZLAZA - USAGLASAVANJE"
   @ box_x_koord() + 2, box_y_koord() + 6 SAY "KNJIZNOG I STVARNOG STANJA"
   @ box_x_koord() + 4, box_y_koord() + 2 SAY "Nalog  " GET cIdF
   @ box_x_koord() + 4, Col() + 2 SAY "-" GET cIdVN
   @ box_x_koord() + 4, Col() + 2 SAY "-" GET cBrNal
   @ box_x_koord() + 4, Col() + 4 SAY "Datum  " GET cIdD
   @ box_x_koord() + 5, box_y_koord() + 2 SAY "Tip dokumenta" GET cIdTipDok
   @ box_x_koord() + 6, box_y_koord() + 2 SAY "Konto  " GET cIdK VALID P_Konto( @cIdK )
   @ box_x_koord() + 7, box_y_koord() + 2 SAY "Zaduzuje" GET cIdZaduz VALID Empty( @cIdZaduz ) .OR. p_partner( @cIdZaduz )
   READ; ESC_BCR

   BoxC()
   SAVE TO  ( my_home() + "invent.mem" ) ALL LIKE cId?

   picD := '@Z 99999999999.99'
   picD1 := '@Z 99999999.99'
   picK := '@Z 99999.99'

   o_valute()
   O_MAT_PRIPR
   O_MAT_INVENT
   // o_roba()
   // o_sifk()
   // o_sifv()
   O_MAT_SUBAN
   SET ORDER TO TAG "3"
   SET FILTER TO DatDok <= cIdD

   SELECT MAT_INVENT
   GO TOP

   A := 0

   nRBr := 0
   SK := SV := 0
   KK := KV := 0
   VK := VV := MK := MV := 0

   SV1 := KV1 := 0
   VV1 := MV1 := 0

   nRbr := 0
   KursLis := "1"

   DO WHILE !Eof()


      SK := Kolicina; SV := Iznos

      cIdRoba := IdRoba
      SELECT mat_suban
      SEEK cIdF + cIdK + cIdRoba
      kK := kV := 0         // KK - knjizena kolicina, KV - knjizena vrijednost
      DO WHILE !Eof() .AND. cIdF = IdFirma .AND. cIdK = IdKonto .AND. cIdRoba = IdRoba
         IF D_P = "1"; kK += Kolicina; ELSE; kK -= Kolicina; ENDIF
         IF D_P = "1"; kV += Iznos; ELSE; kV -= Iznos; ENDIF
         SKIP
      ENDDO



      RK := KK - SK
      RV := KV - SV
      nCj := 0
      IF Round( rk, 3 ) <> 0; nCj := rv / rk;ENDIF

      IF Round( rk, 3 ) <> 0 .OR. Round( rv, 3 ) <> 0
         SELECT mat_pripr
         APPEND BLANK
         REPLACE idfirma WITH cidf, idvn WITH cidvn, brnal WITH cbrnal, ;
            idkonto WITH cidk, rbr WITH Str( ++nRbr, 4 ), ;
            idzaduz WITH cidzaduz, ;
            idroba WITH cidroba, u_i WITH "2", d_p WITH "2", ;
            kolicina WITH rk, cijena WITH nCj, iznos WITH rv, ;
            iznos2 WITH iznos * Kurs( cIdD ), ;
            datdok WITH cidD, datkurs WITH cidd, ;
            idtipdok WITH cIdTipDok

      ENDIF

      SELECT MAT_INVENT
      SKIP
   ENDDO

   my_close_all_dbf()

   RETURN


// ---------------------------------------------------
// prenos iz materijalnog u obracun  poreza
// ---------------------------------------------------
FUNCTION mat_inv_obr_poreza()

   LOCAL cIdDir

   cIdF := self_organizacija_id()
   cIdK := Space( 7 )
   cIdD := Date()
   cIdX := Space( 35 )
   IF File( my_home() + "invent.mem" )
      RESTORE FROM ( my_home() + "invent.mem" ) additive
   ENDIF
   cIdF := Left( cIdF, 2 )
   cIdX := PadR( cIdX, 35 )
   cIdZaduz := Space( 6 )
   cidvn := "  "; cBrNal := Space( 4 )
   cIdTipDok := "09"
   o_tarifa(); o_konto()
   O_MAT_INVENT
   o_sifk()
   o_sifv()
   o_roba()
   nMjes := Month( cIdD )
   Box( "", 7, 60 )
   @ box_x_koord() + 1, box_y_koord() + 6 SAY "PRENOS INV. STANJA U OBRACUN POREZA MP"
   @ box_x_koord() + 5, box_y_koord() + 2 SAY "Mjesec " GET  nMjes PICT "99"
   @ box_x_koord() + 6, box_y_koord() + 2 SAY "Konto  " GET cIdK VALID P_Konto( @cIdK )
   READ; ESC_BCR
   BoxC()

   SAVE TO  ( my_home() + "invent.mem" ) ALL LIKE cId?

   cIdDir := gDirPor

   USE ( ciddir + "pormp" ) NEW INDEX ( ciddir + "pormpi1" ), ( ciddir + "pormpi2" ), ( ciddir + "pormpi3" )
   SET ORDER TO TAG "3"
   // str(mjesec,2)+idkonto+idtarifa+id

   SELECT MAT_INVENT
   GO TOP

   DO WHILE !Eof()

      select_o_roba( mat_invent->idroba )
      select_o_tarifa( roba->idtarifa )
      SELECT mat_invent
      nMPVSAPP := kolicina * cijena
      IF nMPVSAPP == 0; skip; loop; ENDIF
      nMPV := nMPVSAPP / ( 1 + tarifa->pdv / 100 )
      SELECT pormp
      SEEK Str( nmjes, 2 ) + cidk + roba->idtarifa + "3. SAD.INVENT"
      IF !Found()
         APPEND BLANK
      ENDIF
      REPLACE id WITH "3. SAD.INVENT", ;
         mjesec  WITH nmjes, ;
         idkonto WITH cIDK, ;
         idtarifa WITH roba->IdTarifa, ;
         znak WITH "-", ;
         MPV      WITH MPV - nMPV, ;
         MPVSaPP  WITH MPVSaPP - nMPVSAPP
      SEEK Str( nmjes + 1, 2 ) + cidk + roba->idtarifa + "1. PREDH INV."   // sljedeci mjesec
      IF !Found()
         APPEND BLANK
      ENDIF
      REPLACE id WITH "1. PREDH INV.", ;
         mjesec  WITH nmjes + 1, ;
         idkonto WITH cIDK, ;
         idtarifa WITH roba->IdTarifa, ;
         znak WITH "+", ;
         MPV      WITH MPV + nMPV, ;
         MPVSaPP  WITH MPVSaPP + nMPVSAPP


      SELECT MAT_INVENT
      SKIP
   ENDDO

   my_close_all_dbf()

   RETURN


FUNCTION mat_popisna_lista()

   LOCAL _vars := hb_Hash()
   LOCAL _id_firma
   LOCAL _konto
   LOCAL _datum
   LOCAL _partner
   LOCAL _filter := ""
   LOCAL _my_xml := my_home() + "data.xml"

   download_template( "mat_invent.odt", "cd3fd5ebd1ac18d4b5abda4f9cbffcf01b6bc844d5725cb02dd9cce79ba235c0" )

   o_konto()
   o_partner()

   IF !_get_inv_vars( @_vars )
      my_close_all_dbf()
      RETURN .F.
   ENDIF

   _konto := _vars[ "konto" ]
   _datum := _vars[ "datum" ]
   _id_firma := Left( _vars[ "id_firma" ], 2 )
   _partner := _vars[ "partner" ]

   I := 0
   K := 0
   C := 0

   O_MAT_SUBAN
   // o_sifk()
   // o_sifv()
   // o_roba()

   SELECT mat_suban
   SET ORDER TO TAG "3"

   SET FILTER TO datdok <= _datum .AND. IF( !Empty( _partner ), idpartner == _partner, .T. )
   GO TOP

   SEEK _id_firma + _konto
   NFOUND CRET

   A := 0
   B := 0

   create_xml( _my_xml )
   xml_head()

   xml_subnode( "inv", .F. )

   DO WHILE !Eof() .AND. _id_firma == field->idfirma .AND. _konto == field->idkonto

      IF A == 0

         xml_node( "modul", "MAT" )
         xml_node( "datum", DToC( _datum ) )

         select_o_partner( _id_firma )

         xml_node( "fid", to_xml_encoding( self_organizacija_id() ) )
         xml_node( "fnaz", to_xml_encoding( self_organizacija_naziv() ) )

         IF !Empty( _konto )

            select_o_konto( _konto )

            xml_node( "kid", to_xml_encoding( _konto ) )
            xml_node( "knaz", to_xml_encoding( AllTrim( field->naz ) ) )

         ELSE

            xml_node( "kid", "" )
            xml_node( "knaz", "" )

         ENDIF

         IF !Empty( _partner )

            select_o_partner( _partner )

            xml_node( "pid", to_xml_encoding( _partner ) )
            xml_node( "pnaz", to_xml_encoding( AllTrim( field->naz ) ) )

         ELSE

            xml_node( "pid", "" )
            xml_node( "pnaz", "" )

         ENDIF

      ENDIF

      ++A

      SELECT mat_suban
      cIdRoba := IdRoba

      IF Empty( cIdRoba )
         SKIP
         LOOP
      ENDIF

      nIznos := nIznos2 := nStanje := nCijena := 0

      DO WHILE !Eof() .AND. _id_firma == field->IdFirma .AND. _konto == field->IdKonto .AND. cIdRoba == field->IdRoba

         // saberi za jednu robu

         IF field->U_I = "1"
            nStanje += field->kolicina
         ELSE
            nStanje -= field->Kolicina
         ENDIF

         IF D_P = "1"
            nIznos += field->Iznos
            nIznos2 += field->Iznos2
         ELSE
            nIznos -= field->Iznos
            nIznos2 -= field->Iznos2
         ENDIF

         SKIP

      ENDDO

      IF Round( nStanje, 4 ) <> 0 .OR. Round( nIznos, 4 ) <> 0

         // uzimaj samo one koji su na stanju  <> 0
         SELECT ROBA
         HSEEK cIdRoba

         IF Round( nStanje, 4 ) <> 0
            nCijena := nIznos / nStanje
         ELSE
            nCijena := 0
         ENDIF

         xml_subnode( "items", .F. )

         xml_node( "rbr", AllTrim( Str( ++B ) ) )
         xml_node( "rid", to_xml_encoding( field->id ) )
         xml_node( "naz", to_xml_encoding( field->naz ) )
         xml_node( "jmj", to_xml_encoding( field->jmj ) )
         xml_node( "cijena", Str( nCijena, 12, 3 )  )
         xml_node( "stanje", Str( nStanje, 12, 3 )  )

         xml_subnode( "items", .T. )

         SELECT mat_suban

      ENDIF

   ENDDO

   xml_subnode( "inv", .T. )
   close_xml()

   my_close_all_dbf()

   IF B > 0
      IF generisi_odt_iz_xml( "mat_invent.odt", _my_xml )
         prikazi_odt()
      ENDIF
   ENDIF

   RETURN .T.
