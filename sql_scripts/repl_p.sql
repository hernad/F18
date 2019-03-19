GRANT ALL ON SCHEMA f18 TO replikant;
REVOKE ALL PRIVILEGES ON DATABASE "{{ item_prodavnica }}.{{ server_db}}" FROM replikant;
REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public FROM replikant;
GRANT ALL PRIVILEGES ON DATABASE "{{ item_prodavnica }}.{{ server_db }}" TO replikant;

GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA f18 TO replikant;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA {{ item_prodavnica }} TO replikant;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO replikant;