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

function dbf_test()
local nI
local _plaho_dugacko_polje
local _ime_f
local _dbf_struct := {}
local _field_10

_ime_f := "test_dbf_1"


_plaho_dugacko_polje := "ja_sam_plaho_dugacko_polje"

ferase_dbf(_ime_f)


AADD(_dbf_struct,      { 'ID' ,  'C' ,   2 ,  0 })
AADD(_dbf_struct,      { 'NAZ' , 'C' ,  10 ,  0 })
AADD(_dbf_struct,      { _plaho_dugacko_polje , 'C' ,  20 ,  0 })

DBCREATE2(_ime_f, _dbf_struct)

CREATE_INDEX("ID",  "id", _ime_f)
CREATE_INDEX("NAZ", "naz", _ime_f)
CREATE_INDEX("NAZ2", LEFT(_plaho_dugacko_polje, 10) , _ime_f)

my_usex(_ime_f)


_field_10 := LEFT(_plaho_dugacko_polje, 10)

APPEND BLANK
field->ja_sam_pla := "t"
field->&_field_10  := "test"

TEST_LINE( FIELDPOS(_plaho_dugacko_polje), 0)
TEST_LINE( FIELDPOS(_field_10), 3)
TEST_LINE( field->ja_sam_pla, PADR("test", 20) )


return .t.
