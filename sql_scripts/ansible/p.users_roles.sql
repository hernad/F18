CREATE SCHEMA IF NOT EXISTS {{ prod_schema }};


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


GRANT ALL ON SCHEMA {{ prod_schema }} TO xtrole;
ALTER ROLE admin SUPERUSER INHERIT CREATEDB CREATEROLE REPLICATION;

-- admin pripada xtrole grupi
GRANT xtrole TO admin;
-- npr. p16 pripada xtrole grupi
GRANT xtrole TO {{ db_user }};
