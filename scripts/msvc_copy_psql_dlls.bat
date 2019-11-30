
set PSQL_BIN=d:\x86\postgresql-10.11-1\pgsql\bin

copy %PSQL_BIN%\libpq.dll
copy %PSQL_BIN%\libcrypto*.dll
copy %PSQL_BIN%\libssl*.dll
copy %PSQL_BIN%\zlib1.dll
copy %PSQL_BIN%\libiconv-2.dll
copy %PSQL_BIN%\libintl*.dll
rem copy %PSQL_BIN%\*.dll
