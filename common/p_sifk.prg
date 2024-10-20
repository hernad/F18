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



FUNCTION P_Sifk( cId, nDeltaX, nDeltaY )

   LOCAL i
   PRIVATE imekol, kol

   Kol := {}

   o_sifk() // P_SIFK
   
   ImeKol := { { PadR( "Id", 15 ),      {|| id }, "id"  }, ;
      { PadR( "Naz", 25 ),     {||  naz }, "naz" }, ;
      { PadR( "Sort", 4 ),     {|| sort }, "sort" }, ;
      { PadR( "Oznaka", 4 ),   {||  oznaka }, "oznaka" }, ;
      { PadR( "Veza", 4 ),     {|| veza }, "veza" }, ;
      { PadR( "Izvor", 15 ),   {|| izvor }, "izvor" }, ;
      { PadR( "Uslov", 30 ),   {|| PadR( uslov, 30 ) }, "uslov" }, ;
      { PadR( "Tip", 3 ),      {|| tip }, "tip" }, ;
      { PadR( "Unique", 3 ),   {|| f_unique }, "f_unique", NIL, NIL, NIL, NIL, NIL, NIL, 20 }, ;
      { _u( "Duž" ),      {|| field->duzina + 0 }, "duzina" }, ;
      { PadR( "Dec", 3 ),      {|| f_decimal }, "f_decimal" }, ;
      { PadR( "K Validacija", 50 ), {|| PadR( KValid, 50 ) }, "KValid" }, ;
      { PadR( "K When", 50 ),  {|| KWhen }, "KWhen" }, ;
      { PadR( "UBrowsu", 4 ),  {|| UBrowsu }, "UBrowsu" }, ;
      { PadR( "EdKolona", 4 ), {|| field->edkolona + 0 }, "EdKolona" }, ;
      { PadR( "K1", 4 ),       {|| k1 }, "k1" }, ;
      { PadR( "K2", 4 ),       {|| k2 }, "k2" }, ;
      { PadR( "K3", 4 ),       {|| k3 }, "k3" }, ;
      { PadR( "K4", 4 ),       {|| k4 }, "k4" }             ;
      }

   FOR i := 1 TO Len( ImeKol )
      AAdd( Kol, i )
   NEXT

   RETURN p_sifra( F_SIFK, 1, f18_max_rows() -15, f18_max_cols() -15, "sifk - Karakteristike", @cId, nDeltaX, nDeltaY )
