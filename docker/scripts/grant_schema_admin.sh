#!/bin/bash

DATABASE=proba_2018
OWNER=admin


CMD="ALTER DATABASE $DATABASE OWNER TO admin;"
su postgres -c "psql postgres -c \"$CMD\""


#CMD="REASSIGN OWNED BY postgres TO admin;"
#su postgres -c "psql $DATABASE -c \"$CMD\""


#https://stackoverflow.com/questions/1348126/modify-owner-on-all-tables-simultaneously-in-postgresql


CMD="SELECT 'ALTER TABLE '|| schemaname || '.' || tablename ||' OWNER TO $OWNER;'"
CMD+="FROM pg_tables WHERE NOT schemaname IN ('pg_catalog', 'information_schema')"
CMD+="ORDER BY schemaname, tablename;"
su postgres -c "psql $DATABASE -c \"$CMD\"" > /tmp/alter_tables.sql
su postgres -c "psql $DATABASE  < /tmp/alter_tables.sql"


CMD="SELECT 'ALTER SEQUENCE '|| sequence_schema || '.' || sequence_name ||' OWNER TO $OWNER;'"
CMD+="FROM information_schema.sequences WHERE NOT sequence_schema IN ('pg_catalog', 'information_schema')"
CMD+="ORDER BY sequence_schema, sequence_name;"
su postgres -c "psql $DATABASE -c \"$CMD\"" > /tmp/alter_sequences.sql
su postgres -c "psql $DATABASE  < /tmp/alter_sequences.sql"


CMD="ALTER schema fmk OWNER TO admin;"
su postgres -c "psql $DATABASE -c \"$CMD\""


CMD="GRANT ALL ON ALL TABLES IN SCHEMA fmk TO admin;"
su postgres -c "psql $DATABASE -c \"$CMD\""

CMD="GRANT ALL ON ALL SEQUENCES IN SCHEMA fmk TO admin;"
su postgres -c "psql $DATABASE -c \"$CMD\""


CMD="GRANT ALL ON ALL FUNCTIONS IN SCHEMA fmk TO admin;"
su postgres -c "psql $DATABASE -c \"$CMD\""



