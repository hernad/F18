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

function test_migrate()
local _dir, _dir_sif, _dir_kum, _dir_2, _dbf

_dir := fmk_migrate_root()
DIRMAKE(_dir)

_dir := _dir + SLASH + "test"
DIRMAKE(_dir)

_dir_sif := _dir  + SLASH + "sif1"
DIRMAKE(_dir_sif)

_dir_kum := _dir  + SLASH + "kum1"
DIRMAKE(_dir_kum)
cre_t_1("t_fmk_1", _dir_kum)

_dir_2 := _dir_kum + SLASH + "2009"
DIRMAKE(_dir_2)
cre_t_1("t_fmk_1", _dir_2)

_dir_2 := _dir_kum + SLASH + "2010"
DIRMAKE(_dir_2)
cre_t_1("t_fmk_1", _dir_2)

fmk_migrate()

_dbf := _dir_kum + SLASH + "t_fmk_1.dbf"
add_sample_data_t_1(_dbf, 5)
TEST_LINE (FILE(_dbf) , .t.)

_dbf := _dir_kum + SLASH + "2010" + SLASH + "t_fmk_1.dbf"
add_sample_data_t_1(_dbf, 10)
TEST_LINE (FILE(_dbf) , .t.)

_dbf := _dir_kum + SLASH + "2009" + SLASH + "t_fmk_1.dbf"
add_sample_data_t_1(_dbf, 9)
TEST_LINE (FILE(_dbf), .t.)

return .t.

// ------------------------------------------
// ------------------------------------------
function cre_t_1(ime_f, location)
local _full_ime, _dbf_struct, _standard

if location == NIL
   _full_ime := f18_ime_dbf(ime_f)
   _standard := .t.
else
   _full_ime := hb_DirSepAdd(location) + ime_f
   _standard := .f.
endif

_dbf_struct := {}
AADD(_dbf_struct,      { 'ID' ,  'C' ,   4 ,  0 })
AADD(_dbf_struct,      { 'NAZ' , 'C' ,  20 ,  0 })
       
DBCREATE(_full_ime, _dbf_struct)

if _standard
   CREATE_INDEX("ID",  "id", ime_f)  
   CREATE_INDEX("NAZ", "naz", ime_f)
else
   SELECT F_TMP
   USE (_full_ime) EXCLUSIVE
   INDEX ON ID TAG "ID"
   INDEX ON NAZ TAG "NAZ"
   USE
endif

return .t.

// ---------------------------------------------
// ---------------------------------------------
function add_sample_data_t_1(dbf, num)
local nI

USE (dbf) EXCLUSIVE NEW 
for nI := 1 to num
  field->id  := STR(nI, 4)
  field->naz := "naz " + STR(nI, 4)
next
USE

return .t.
