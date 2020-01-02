
-- od 2020 ovo treba biti ovako:
-- ALTER SUBSCRIPTION {{ prod_schema }}_f18_sifre_sub_{{ predhodna_godina }} DISABLE;
-- ALTER SUBSCRIPTION {{ prod_schema }}_pos_knjig_sub_{{ predhodna_godina }} DISABLE;

-- za sada, radi 2019 mora ovako:
ALTER SUBSCRIPTION {{ prod_schema }}_f18_sifre_sub DISABLE;
ALTER SUBSCRIPTION {{ prod_schema }}_pos_knjig_sub DISABLE;
