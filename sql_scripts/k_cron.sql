CREATE EXTENSION IF NOT EXISTS pg_cron;
GRANT USAGE ON SCHEMA cron TO postgres;

DELETE from cron.job where database='{{ server_db }}';
INSERT INTO cron.job (schedule, command, nodename, nodeport, database, username)
   VALUES ('*/15 * * * *', $$SELECT public.run_cron()$$, 'localhost', 5432, '{{ server_db }}', 'postgres');
