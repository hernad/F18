drop view if exists public.log;
CREATE view public.log  AS SELECT
      *
    FROM f18.log;

GRANT ALL ON public.log TO xtrole;

-- f18.log
drop view if exists public.log;
CREATE view public.log  AS SELECT
      *
    FROM f18.log;

GRANT ALL ON public.log TO xtrole;


-- public.valute
drop view if exists public.valute;
CREATE view public.valute  AS SELECT
  *
FROM
  f18.valute;

GRANT ALL ON public.valute TO xtrole;