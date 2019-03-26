CREATE EXTENSION IF NOT EXISTS pg_cron;
GRANT USAGE ON SCHEMA cron TO postgres;

DELETE from cron.job where database='{{ db_name }}';
INSERT INTO cron.job (schedule, command, nodename, nodeport, database, username)
   VALUES ('*/15 * * * *', $$SELECT {{ item_prodavnica }}.run_cron()$$, 'localhost', 5432, '{{ db_name }}', 'postgres');
