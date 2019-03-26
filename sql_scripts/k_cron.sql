CREATE EXTENION IF NOT EXISTS pg_cron;
GRANT USAGE ON SCHEMA cron TO postgres;

INSERT INTO cron.job (schedule, command, nodename, nodeport, database, username)
   VALUES ('*/2 * * * *', $$select public.run_cron()$$, 'localhost', 5432, {{ server_db }}, 'postgres');
