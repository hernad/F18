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


FUNCTION stampa_virmana()

   LOCAL _br_virmana := 999
   LOCAL _marker := "N"
   LOCAL nI
   LOCAL _konverzija := fetch_metric( "virm_konverzija_delphirb", NIL, "5" )

   BEGIN SEQUENCE
      O_IZLAZ
      my_dbf_zap()

   RECOVER
      MsgBeep( "Vec je aktiviran delphirb ?" )
      RETURN .F.
   END SEQUENCE


   Box(, 2, 70 )
   @ box_x_koord() + 1, box_y_koord() + 2 SAY "Broj virmana od sljedece pozicije:" GET _br_virmana PICT "999"
   @ box_x_koord() + 2, box_y_koord() + 2 SAY "Uzeti u obzir markere            :" GET _marker PICT "@!" VALID _marker $ "DN"
   READ
   BoxC()

   nI := 1

   SELECT virm_pripr
   SET ORDER TO TAG "1"

   IF _marker = "D"
      GO TOP
   ENDIF

   my_flock()

   DO WHILE !Eof()

      Scatter()

      IF _marker = "D" .AND. _st_ = "*"
         SKIP
         LOOP
      ELSE
         REPLACE _st_ WITH "*"
      ENDIF

      SELECT izlaz
      APPEND BLANK

      KonvZnWin( @_ko_txt, _konverzija )
      KonvZnWin( @_kome_txt, _konverzija )
      KonvZnWin( @_svrha_doz, _konverzija )
      KonvZnWin( @_mjesto, _konverzija )

      _ko_zr    = Razrijedi( _ko_zr )       // z.racun posiljaoca
      _KOME_ZR  = Razrijedi( _KOME_ZR )     // z.racun primaoca
      _bpo      = Razrijedi( _bpo )         // broj poreznog obveznika
      _idjprih  = Razrijedi( _idjprih )     // javni prihod
      _idops    = Razrijedi( _idops )       // opstina
      _pnabr    = Razrijedi( _pnabr )       // poziv na broj
      _budzorg  = Razrijedi( _budzorg )     // budzetska organizacija
      _pod      = Razrijedi( DToC( _pod ) )         // porezni period od
      _pdo      = Razrijedi( DToC( _pdo ) )         // porezni period do
      _dat_upl  = Razrijedi( DToC( _dat_upl ) )     // datum uplate

      Gather()

      SELECT virm_pripr
      SKIP

      IF nI >= _br_virmana
         EXIT
      ENDIF
      nI++

   ENDDO

   IF Eof()
      SKIP -1
   ENDIF

   my_unlock()


   stampaj_virman_drb()

   RETURN .T.



STATIC FUNCTION stampaj_virman_drb()

   LOCAL nTrec
   LOCAL _rtm_file := "nalplac"

   SELECT virm_pripr
   nTrec := RecNo()

   USE

   SELECT izlaz
   USE

   my_close_all_dbf()

   // ovdje treba kod za filovanje datoteke IZLAZ.DBF
   IF LastKey() != K_ESC
      f18_rtm_print( _rtm_file, "izlaz", "1" )
   ENDIF

   o_virm_tabele_unos_print()
   SELECT virm_pripr
   GO ( nTrec )

   RETURN .T.
