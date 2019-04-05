DROP FUNCTION IF EXISTS {{ item_prodavnica }}.cron_akcijske_cijene_nivelacija_start() CASCADE;
DROP FUNCTION IF EXISTS {{ item_prodavnica }}.cron_akcijske_cijene_nivelacija_end() CASCADE;
DROP FUNCTION IF EXISTS {{ item_prodavnica }}.nivelacija_start_create(uuidPos uuid);
DROP FUNCTION IF EXISTS {{ item_prodavnica }}.nivelacija_end_create(uuidPos uuid);
