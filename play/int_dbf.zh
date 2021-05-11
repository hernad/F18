PROCEDURE SG_Integers() // Set / Get test for INTEGER fields

LOCAL nRecno := 0,;
 aStru9 := { { 'INT1', "I", 1, 0 },;
 { 'NUM1', "N", 4, 0 },;
 { 'EQL1', "L", 1, 0 },; 
 { 'INT11', "I", 1, 1 },;
 { 'NUM11', "N", 5, 1 },;
 { 'EQL11', "L", 1, 0 },; 
 { 'INT2', "I", 2, 0 },;
 { 'NUM2', "N", 8, 0 },;
 { 'EQL2', "L", 1, 0 },; 
 { 'INT22', "I", 8, 2 },;
 { 'NUM22', "N",12, 2 },;
 { 'EQL22', "L", 1, 0 },; 
 { 'INT3', "I", 3, 0 },;
 { 'NUM3', "N", 8, 0 },;
 { 'EQL3', "L", 1, 0 },; 
 { 'INT32', "I", 3, 2 },;
 { 'NUM32', "N",12, 2 },;
 { 'EQL32', "L", 1, 0 },; 
 { 'INT4', "I", 4, 0 },;
 { 'NUM4', "N",12, 0 },;
 { 'EQL4', "L", 1, 0 },; 
 { 'INT42', "I", 4, 2 },;
 { 'NUM42', "N",14, 2 },;
 { 'EQL42', "L", 1, 0 },; 
 { 'INT8', "I", 8, 0 },;
 { 'NUM8', "N", 21, 0 },;
 { 'EQL8', "L", 1, 0 },; 
 { 'INT84', "I", 8, 4 },;
 { 'NUM84', "N", 21, 4 },;
 { 'EQL84', "L", 1, 0 } } 

 DBCREATE( "SG_Integers", aStru9 )
 USE SG_Integers

 APPEND BLANK 
 replace int1 with 60
 replace int2 with 120

 ? "int1", int1, "int2", int2


 APPEND BLANK 
 replace int1 with -90
 replace int2 with -220

 ? "int1", int1, "int2", int2
