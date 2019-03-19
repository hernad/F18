CREATE SCHEMA IF NOT EXISTS {{ prod_schema }};

DROP ROLE IF EXISTS xtrole;
CREATE ROLE xtrole NOSUPERUSER INHERIT NOCREATEDB NOCREATEROLE NOREPLICATION;

GRANT ALL ON SCHEMA {{ prod_schema }} TO xtrole;
ALTER ROLE admin SUPERUSER INHERIT CREATEDB CREATEROLE REPLICATION;

-- admin pripada xtrole grupi
GRANT xtrole TO admin;
-- npr. p16 pripada xtrole grupi
GRANT xtrole TO {{ db_user }};
