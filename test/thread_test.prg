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
#include "hbthread.ch"

#define F_TEST_SEM_1 9001
#define F_TEST_SEM_2 9002

thread static _t_var := 0

function test_thread()
local nI, _threads, _ret, _sum


_threads:= {}

for nI := 1 TO 5
  AADD( _threads, hb_threadStart( @th_func() ) )
next

_sum := 0

AEval( _threads, { |th_id| hb_threadJoin( th_id, @_ret ), _sum += _ret } )
TEST_LINE(_sum, 50)

_t_var += 2

for nI := 1 TO 2
  AADD( _threads, hb_threadStart( @th_func_2() ) )
next
AEval( _threads, { |th_id| hb_threadJoin( th_id) } )
TEST_LINE(_t_var, 2)

return .t.


function th_func()
return 10


// -------------------------
// -------------------------
function th_func_2()
local nI

for nI :=1 to  10
  _t_var += 10
  ? "spavam ..."
  hb_IdleSleep(0.5)
next

TEST_LINE(_t_var, 100)
return
