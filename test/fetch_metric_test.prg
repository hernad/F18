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

function fetch_set_metric()
local _sect := ""
local _color, _color_2, _is_fakturisi
local _dat_1, _dat_2

_is_fakturisi := .f.
_sect := "fakturisi_ugalj"
set_metric( _sect, NIL, "!!UNSET!!")

TEST_LINE(fetch_metric(_sect, NIL, _is_fakturisi), .f.)

_is_fakturisi := .t.
set_metric( _sect, NIL, _is_fakturisi)
TEST_LINE( fetch_metric(_sect, NIL, _is_fakturisi), .t.)

_is_fakturisi := .f.
set_metric( _sect, NIL, .f.)
TEST_LINE(  fetch_metric(_sect, NIL, _is_fakturisi), .f.)

set_metric( _sect, f18_user(), "!!UNSET!!")

_sect := "desktop_color"
set_metric( _sect, "<>", "!!UNSET!!")

_color := 50
TEST_LINE(  fetch_metric(_sect, f18_user(), _color ),  50)

set_metric(_sect, f18_user(), _color)
TEST_LINE(  fetch_metric(_sect, f18_user(), _color ),  50)

_color := 50
_sect := "desktop_color"
set_metric(_sect, "<>",  101)
TEST_LINE(  fetch_metric(_sect, "<>", _color ),  101)
TEST_LINE(  fetch_metric(_sect, f18_user(), _color ),  101)

_color_2 := 70
set_metric(_sect, f18_user(), _color_2)
TEST_LINE(  fetch_metric(_sect, f18_user(), _color ),  70)


// kod char parametara ne treba zadavati default_value
_sect := "last_user"
set_metric(_sect, NIL, "hbakir")
TEST_LINE(fetch_metric(_sect), "hbakir")

// kod char parametara ne treba zadavati default_value
_sect := "nepoznata_section"
TEST_LINE(fetch_metric(_sect, NIL, "default_default"),  "default_default")

_sect := "date_begin"
_dat_1 := STOD("20111224")
_dat_2 := STOD("20110101")

// za usera hernad
set_metric(_sect, "hernad", _dat_1)

// globalni
set_metric(_sect, NIL , _dat_2)

TEST_LINE(fetch_metric(_sect, "hernad", _dat_2), _dat_1)
TEST_LINE(fetch_metric(_sect, NIL, _dat_2), _dat_2)



return
