CREATE EXTENION IF NOT EXISTS pg_cron;
GRANT USAGE ON SCHEMA cron TO postgres;

INSERT INTO cron.job (schedule, command, nodename, nodeport, database, username)
   VALUES ('*/2 * * * *', $$select {{ item_prodavnica }}.run_cron()$$, 'localhost', 5432, {{ db_name }}, 'postgres');
