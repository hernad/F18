drop view if exists fmk.log;
CREATE view fmk.log  AS SELECT
      *
    FROM f18.log;

GRANT ALL ON fmk.log TO xtrole;

-- f18.log
drop view if exists fmk.log;
CREATE view fmk.log  AS SELECT
      *
    FROM f18.log;

GRANT ALL ON fmk.log TO xtrole;
