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


STATIC s_cFaktPicCijena, s_cFaktPicKolicina, s_cFaktPicIznos
STATIC s_cKalkPicCijena, s_cKalkPicKolicina, s_cKalkPicIznos
STATIC s_cFinPicEur

FUNCTION pic_iznos_eur( cSet )

   IF s_cFinPicEur == NIL
      s_cFinPicEur := fetch_metric( "fin_picdem", NIL,  "9999999.99" )
   ENDIF

   IF cSet != NIL
      s_cFinPicEur := cSet
      set_metric( "fin_picdem", NIL, cSet )
   ENDIF

   RETURN s_cFinPicEur



FUNCTION kalk_pic_iznos_bilo_gpicdem( cSet )

   IF s_cKalkPicIznos == NIL
      s_cKalkPicIznos := fetch_metric( "kalk_format_prikaza_iznosa", NIL,   "9999999.99" )
   ENDIF

   IF cSet != NIL
      s_cKalkPicIznos := cSet
      set_metric( "kalk_format_prikaza_iznosa", NIL, cSet )
   ENDIF

   RETURN s_cKalkPicIznos


FUNCTION kalk_pic_cijena_bilo_gpiccdem( cSet )

   IF s_cKalkPicCijena == NIL
      s_cKalkPicCijena := fetch_metric( "kalk_format_prikaza_cijene", NIL,  "999999.999" )
   ENDIF

   IF cSet != NIL
      s_cKalkPicCijena := cSet
      set_metric( "kalk_format_prikaza_cijene", NIL, cSet )
   ENDIF

   RETURN s_cKalkPicCijena



FUNCTION kalk_pic_kolicina_bilo_gpickol( cSet )

   IF s_cKalkPicKolicina == NIL
      s_cKalkPicKolicina := fetch_metric( "kalk_format_prikaza_kolicine", NIL,  "999999.999" )
   ENDIF

   IF cSet != NIL
      s_cKalkPicKolicina := cSet
      set_metric( "kalk_format_prikaza_kolicine", NIL, cSet )
   ENDIF

   RETURN s_cKalkPicKolicina



FUNCTION fakt_pic_cijena( cSet )

   IF s_cFaktPicCijena == NIL
      s_cFaktPicCijena := fetch_metric( "fakt_prikaz_cijene", NIL,  "99999999.99" )
   ENDIF

   IF cSet != NIL
      s_cFaktPicCijena := cSet
      set_metric( "fakt_prikaz_cijene", NIL, cSet )
   ENDIF

   RETURN s_cFaktPicCijena



FUNCTION fakt_pic_kolicina( cSet )

   IF s_cFaktPicKolicina == NIL
      s_cFaktPicKolicina := fetch_metric( "fakt_prikaz_kolicine", NIL,  "9999999.999" )
   ENDIF

   IF cSet != NIL
      s_cFaktPicKolicina := cSet
      set_metric( "fakt_prikaz_kolicine", NIL, cSet )
   ENDIF

   RETURN s_cFaktPicKolicina



FUNCTION fakt_pic_iznos( cSet )

   IF s_cFaktPicIznos == NIL
      s_cFaktPicIznos := fetch_metric( "fakt_prikaz_iznosa", NIL, "99999999.99" )
   ENDIF

   IF cSet != NIL
      set_metric( "fakt_prikaz_iznosa", NIL, cSet )
      s_cFaktPicIznos := cSet
   ENDIF

   RETURN s_cFaktPicIznos



FUNCTION kalk_prosiri_pic_iznos_za_2()
   RETURN "99" + kalk_pic_iznos_bilo_gpicdem()


FUNCTION kalk_prosiri_pic_kolicina_za_2()
   RETURN "99" + kalk_pic_kolicina_bilo_gpickol()

FUNCTION kalk_prosiri_pic_cjena_za_2()
   RETURN "99" + kalk_pic_cijena_bilo_gpiccdem()


FUNCTION  os_pic_kolicina()
   RETURN  "99999.99"
