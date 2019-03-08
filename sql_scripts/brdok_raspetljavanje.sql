
select distinct( idvd || regexp_replace(brdok, '\d|\s', '', 'g')  ) from f18.kalk_doks;

select  regexp_replace(brdok, '\D', '', 'g'), brdok from f18.kalk_doks limit 1000;

alter table f18.kalk_doks add column id bigint;

update  f18.kalk_doks set id=0000000 + to_number(regexp_replace(brdok, '\D', '', 'g'),'99999999')
  where regexp_replace(brdok, '\d|\s', '', 'g') = '';

update  f18.kalk_doks set id=1000000 + to_number(regexp_replace(brdok, '\D', '', 'g'),'99999999')
  where regexp_replace(brdok, '\d|\s', '', 'g') = '/';

update  f18.kalk_doks set id=2000000 + to_number(regexp_replace(brdok, '\D', '', 'g'),'99999999')
  where regexp_replace(brdok, '\d|\s', '', 'g') = '/BH';

update  f18.kalk_doks set id=3000000 + to_number(regexp_replace(brdok, '\D', '', 'g'),'99999999')
  where regexp_replace(brdok, '\d|\s', '', 'g') = '/BL';

update  f18.kalk_doks set id=4000000 + to_number(regexp_replace(brdok, '\D', '', 'g'),'99999999')
  where regexp_replace(brdok, '\d|\s', '', 'g') = '/T';

update  f18.kalk_doks set id=5000000 + to_number(regexp_replace(brdok, '\D', '', 'g'),'99999999')
  where regexp_replace(brdok, '\d|\s', '', 'g') = '/TZ';

update  f18.kalk_doks set id=6000000 + to_number(regexp_replace(brdok, '\D', '', 'g'),'99999999')
  where regexp_replace(brdok, '\d|\s', '', 'g') = 'G';


select count(id), id from f18.kalk_doks
group by id
having count(id)>1;


select brdok, regexp_replace(brdok, '\D', '', 'g'), to_number(btrim(regexp_replace(brdok, '\D', '', 'g')),'99999999') from f18.kalk_doks where id=1552;


select idvd,brdok from f18.kalk_doks where 	idvd || regexp_replace(brdok, '\d|\s', '', 'g') = '89/'


-- https://blog.2ndquadrant.com/postgresql-10-identity-columns/#comment-248607


--	 https://www.cybertec-postgresql.com/en/sequences-gains-and-pitfalls/
ALTER TABLE f18.kalk_doks
ADD COLUMN id bigint
GENERATED  ALWAYS AS IDENTITY PRIMARY KEY;
