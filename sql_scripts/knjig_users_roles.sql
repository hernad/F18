CREATE SCHEMA IF NOT EXISTS f18;
CREATE SCHEMA IF NOT EXISTS fmk;

DO
$do$
BEGIN
   IF NOT EXISTS (
      SELECT                       -- SELECT list can stay empty for this
      FROM   pg_catalog.pg_roles
      WHERE  rolname = 'xtrole') THEN

      CREATE ROLE xtrole NOSUPERUSER INHERIT NOCREATEDB NOCREATEROLE NOREPLICATION;
   END IF;
END
$do$;

GRANT ALL ON SCHEMA f18 TO xtrole;
GRANT ALL ON SCHEMA fmk TO xtrole;

ALTER ROLE admin SUPERUSER INHERIT CREATEDB CREATEROLE REPLICATION;

GRANT xtrole TO admin;

-- user npr. knjig pripada grupi xtrole;
GRANT xtrole TO {{ db_user }};


