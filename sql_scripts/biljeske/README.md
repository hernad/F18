

<pre>
Ernads-iMac:sql_scripts hernad$ ./push_script_to_server.sh  f18-test firma_2014 test.sql
date    
------------
 2015-01-23
(1 row)
</pre>


<pre>

firma_2014=# select * from public.sp_konto_stanje( 'm', rpad('1320',7) , '0X000Y', '2015-01-23');
 ulaz | izlaz |     nv_u     |    nv_i     
------+-------+--------------+-------------
 2185 |  1621 | 734.33179145 | 504.5198262

</pre>
