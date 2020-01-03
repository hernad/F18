DO $$
BEGIN

CREATE PUBLICATION f18_sifre_{{ tekuca_godina }};
ALTER PUBLICATION f18_sifre_{{ tekuca_godina }} ADD TABLE f18.valute;
ALTER PUBLICATION f18_sifre_{{ tekuca_godina }} ADD TABLE f18.partn;
ALTER PUBLICATION f18_sifre_{{ tekuca_godina }} ADD TABLE f18.tarifa;
ALTER PUBLICATION f18_sifre_{{ tekuca_godina }} ADD TABLE f18.sifk;
ALTER PUBLICATION f18_sifre_{{ tekuca_godina }} ADD TABLE f18.sifv;


EXCEPTION WHEN OTHERS THEN
   RAISE INFO 'f18_sifre_{{ tekuca_godina }} publikacija postoji replikaciju postoji';
END;
$$;

