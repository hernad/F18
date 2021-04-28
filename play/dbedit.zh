procedure main( cDbf, cFilter )

IF cFilter != NIL
   ? "filter:", cFilter
   inkey(5)
ENDIF
   
use (cDbf)
set filter to &cFilter
  
go top

count to nCnt

? "cnt=", nCnt
inkey(5)
 
dbedit()
