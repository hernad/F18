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


STATIC F_RN_TXT := "RACUN_TXT"
STATIC _F_VRN_TXT := "FV*.TXT"
STATIC _F_MRN_TXT := "FM*.TXT"
STATIC F_RN_PLA := "RACUN_PLA"
STATIC _F_VRN_PLA := "FV*.PLA"
STATIC _F_MRN_PLA := "FM*.PLA"
STATIC F_RN_MEM := "RACUN_MEM"
STATIC _F_VRN_MEM := "FV*.MEM"
STATIC _F_MRN_MEM := "FM*.MEM"
STATIC F_SEMAFOR := "SEMAFOR"
STATIC _F_SEMAFOR := "FS*.TXT"
STATIC F_NIV := "NIVELACIJA"
STATIC _F_NIV := "FN*.TXT"

STATIC F_FPOR := "POREZI"
STATIC _F_FPOR := "F_POR.TXT"

STATIC F_FPART := "PARTNERI"
STATIC _F_FPART := "F_KUPCI.TXT"

STATIC F_FROBA := "ROBA"
STATIC _F_FROBA := "F_ROBA.TXT"

STATIC F_FROBGR := "ROBAGRUPE"
STATIC _F_FROBGR := "F_GRUPE.TXT"

STATIC F_FOBJ := "OBJEKTI"
STATIC _F_FOBJ := "F_OBJ.TXT"

STATIC F_FOPER := "OPERATERI"
STATIC _F_FOPER := "F_OPER.TXT"

// pos komande
STATIC F_POS_RN := "POS_RN"

// komande semafora
// -------------------------------------------
// 0 - stampanje racuna maloprodaje
// 1 - stampanje storno racuna maloprodaje
// 2 - unos nove sifre u fiskalni uredjaj
// 3 - nivelacija robe
// 4 - stampanje dnevnog izvjestaja
// 13 - upis sifara robe u fisk.uredjaj
// 14 - upis grupe sifara robe u fisk.uredjaj
// 20 - stampanje racuna veleprodaje
// 21 - stampanje storno racuna veleprodaje
// 50 - uplata u kasu
// 51 - isplata iz kase


// (F_V_RACUN.TXT) aItems: treba da sadrzi
// [1] - broj racuna
// [2] - tip racuna
// [3] - identifikator storno stavke
// [4] - fiskalna sifra robe
// [5] - naziv roba
// [6] - barkod
// [7] - grupa robe
// [8] - poreska stopa identifikator
// [9] - cijena robe
// [10] - kolicina robe

// (F_V_RACUN.MEM) aTxt: treba da sadrzi
// [1] - red 1
// [2] - red 2
// [3] - red 3
// [4] - red 4

// (F_V_RACUN.PLA) : aPla_data
// [1] - broj racuna
// [2] - tip racuna
// [3] - nacin placanja
// [4] - uplaceno novca
// [5] - total racuna
// [6] - povrat novca

// (SEMAFOR.TXT) : aSem_data
// [1] - broj racuna / nivelacije / operacije
// [2] - tip knjizenja - komanda operacije
// [3] - print memo identifikator - od broja
// [4] - print memo identifikator - do broja
// [5] - fiskalna sifra kupca za veleprodaju ili 0
// [6] - broj reklamnog racuna

// (NIVELACIJA.TXT) : aNiv_data
// [1] - broj nivelacije
// [2] - sifra robe
// [3] - naziv robe
// [4] - bar kod
// [5] - sifra grupe robe
// [6] - sifra poreske stope
// [7] - cijena robe



// -------------------------------------------------------
// racun veleprodaje
// cFPath - destination path
// aItems - matrica sa stavkama racuna
// aTxt - dodatni tekst racuna
// cRnNum - broj racuna
// nTotal - total racuna
// -------------------------------------------------------
FUNCTION flink_racun_veleprodaja( cFPath, aItems, aTxt, aPla_data, aSem_data )

   // cFPath := my_home()

   // uzmi strukturu tabele za f_v_racun.txt
   aS_rn_txt := fiskalni_get_struct_za_gen_fajlova( F_RN_TXT )
   // uzmi strukturu tabele za f_v_racun.mem
   aS_rn_mem := fiskalni_get_struct_za_gen_fajlova( F_RN_MEM )
   // uzmi strukturu tabele za f_v_racun.pla
   aS_rn_pla := fiskalni_get_struct_za_gen_fajlova( F_RN_PLA )
   // uzmi strukturu tabele za semafor
   aS_semafor := fiskalni_get_struct_za_gen_fajlova( F_SEMAFOR )


   // broj racuna
   nInvoice := aItems[ 1, 1 ]

   cPom := f_filename( _F_VRN_TXT, nInvoice )

   // upisi aItems prema aVRnTxt u my_home() + "F_V_RACUN.TXT"
   fiskalni_array_to_fajl( cFPath, cPom, aS_rn_txt, aItems )

   IF Len( aTxt ) <> 0

      cPom := f_filename( _F_VRN_MEM, nInvoice )
      // upisi zatim stavke u fajl "F_V_RACUN.MEM"
      fiskalni_array_to_fajl( cFPath, cPom, aS_rn_mem, aTxt )
   ENDIF

   cPom := f_filename( _F_VRN_PLA, nInvoice )
   // upisi zatim stavke u fajl "F_V_RACUN.PLA"
   fiskalni_array_to_fajl( cFPath, cPom, aS_rn_pla, aPla_Data )

   cPom := f_filename( _F_SEMAFOR, nInvoice )

   fiskalni_array_to_fajl( cFPath, cPom, aS_semafor, aSem_Data ) // upisi i semafor "F_SEMAFOR.TXT"

   RETURN .T.



FUNCTION flink_racun_maloprodaja( cFPath, aItems, aTxt, aPla_data, aSem_data )

   // cFPath := my_home()
   LOCAL cPom

   // uzmi strukturu tabele za f_v_racun.txt
   aS_rn_txt := fiskalni_get_struct_za_gen_fajlova( F_RN_TXT )
   // uzmi strukturu tabele za f_v_racun.mem
   aS_rn_mem := fiskalni_get_struct_za_gen_fajlova( F_RN_MEM )
   // uzmi strukturu tabele za f_v_racun.pla
   aS_rn_pla := fiskalni_get_struct_za_gen_fajlova( F_RN_PLA )
   // uzmi strukturu tabele za semafor
   aS_semafor := fiskalni_get_struct_za_gen_fajlova( F_SEMAFOR )

   // broj racuna
   nInvoice := aItems[ 1, 1 ]

   cPom := f_filename( _F_MRN_TXT, nInvoice )
   // upisi aItems prema aVRnTxt u my_home() + "F_V_RACUN.TXT"
   fiskalni_array_to_fajl( cFPath, cPom, aS_rn_txt, aItems )

   IF Len( aTxt ) <> 0
      cPom := f_filename( _F_MRN_MEM, nInvoice )
      // upisi zatim stavke u fajl "F_V_RACUN.MEM"
      fiskalni_array_to_fajl( cFPath, cPom, aS_rn_mem, aTxt )
   ENDIF

   cPom := f_filename( _F_MRN_PLA, nInvoice )
   // upisi zatim stavke u fajl "F_V_RACUN.PLA"
   fiskalni_array_to_fajl( cFPath, cPom, aS_rn_pla, aPla_Data )

   cPom := f_filename( _F_SEMAFOR, nInvoice )
   // upisi i semafor "F_SEMAFOR.TXT"
   fiskalni_array_to_fajl( cFPath, cPom, aS_semafor, aSem_Data )

   RETURN .T.


// ----------------------------------------------------
// sredjuje naziv fajla za fiskalni stampac
// ----------------------------------------------------
STATIC FUNCTION f_filename( cPattern, nInvoice )

   LOCAL cRet := ""

   cRet := StrTran( cPattern, "*", AllTrim( Str( nInvoice ) ) )

   RETURN cRet



/*

// ---------------------------------
// inicijalizacija tabela sifrarnika
// ---------------------------------
FUNCTION fisc_init( cFPath, aPor, aRoba, aRobGr, aPartn, aObj, aOper )

   aS_por := fiskalni_get_struct_za_gen_fajlova( F_FPOR )
   aS_roba := fiskalni_get_struct_za_gen_fajlova( F_FROBA )
   aS_robgr := fiskalni_get_struct_za_gen_fajlova( F_FROBGR )
   aS_partn := fiskalni_get_struct_za_gen_fajlova( F_FPART )
   aS_obj := fiskalni_get_struct_za_gen_fajlova( F_FOBJ )
   aS_oper := fiskalni_get_struct_za_gen_fajlova( F_FOPER )

   // upisi poreze
   fiskalni_array_to_fajl( cFPath, _F_FPOR, aS_por, aPor )

   // upisi robu
   fiskalni_array_to_fajl( cFPath, _F_FROBA, aS_roba, aRoba )

   // upisi grupe robe
   fiskalni_array_to_fajl( cFPath, _F_FROBGR, aS_robgr, aRobGr )

   // upisi partnere
   fiskalni_array_to_fajl( cFPath, _F_FPART, aS_partn, aPartn )

   // upisi objekte
   fiskalni_array_to_fajl( cFPath, _F_FOBJ, aS_obj, aObj )

   // upisi operatere
   fiskalni_array_to_fajl( cFPath, _F_FOPER, aS_oper, aOper )

   RETURN .T.

*/
