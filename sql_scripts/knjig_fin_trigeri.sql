
CREATE OR REPLACE FUNCTION public.on_suban_insert_update_delete()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF 
AS $BODY$

BEGIN

        IF (TG_OP = 'DELETE') THEN
            -- INSERT INTO emp_audit SELECT 'D', now(), user, OLD.*;
            RETURN OLD;
        ELSIF (TG_OP = 'UPDATE') THEN
            -- INSERT INTO emp_audit SELECT 'U', now(), user, NEW.*;
            RETURN NEW;
        ELSIF (TG_OP = 'INSERT') THEN
            --IF NEW.otvst <> '9' THEN
            PERFORM zatvori_otvst( NEW.IdKonto, NEW.IdPartner, NEW.BrDok );
            --END IF;
            RETURN NEW;
        END IF;
        RETURN NULL; -- result is ignored since this is an AFTER 
    END;
$BODY$;

ALTER FUNCTION public.on_suban_insert_update_delete() OWNER TO admin;


DROP TRIGGER IF EXISTS suban_insert_upate_delete ON fmk.fin_suban;
CREATE TRIGGER suban_insert_upate_delete
    AFTER INSERT OR DELETE OR UPDATE 
    ON fmk.fin_suban
    FOR EACH ROW
    EXECUTE PROCEDURE public.on_suban_insert_update_delete();