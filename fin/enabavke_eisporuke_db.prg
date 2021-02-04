#include "f18.ch"
#include "enabavke_eisporuke.ch"

FUNCTION db_create_enabavke_eisporuke(lSilent)

    LOCAL hDbServerParams := my_server_params()
    LOCAL cQuery
    LOCAL oQuery

    IF lSilent == NIL
        lSilent := .F.
    ENDIF

    IF !lSilent
        IF !spec_funkcije_sifra( "ADMIN" )
            MsgBeep( "Opcija zaštićena šifrom !" )
            RETURN .F.
        ENDIF
    ENDIF

    IF !F18Admin():relogin_as_admin( hDbServerParams[ "database" ] )
        Alert("Ne mogu se relogirati kao admin?!")
        RETURN .F.
    ENDIF


    // enabavke idseq
    cQuery := "CREATE sequence if not exists public.enabavke_id_seq;"
    // eisporuke idseq
    cQuery += "CREATE sequence if not exists public.eisporuke_id_seq;"
    run_sql_query( cQuery )

    // enabavke
    cQuery := "CREATE TABLE if not exists public.enabavke("
    cQuery += " enabavke_id  integer not null default nextval('enabavke_id_seq'),"
    cQuery += " tip varchar(2) constraint allowed_enabavke_vrste check (tip in ('01', '02', '03', '04', '05')),"
    cQuery += " porezni_period varchar(4),"
    cQuery += " br_fakt varchar(100) not NULL,"
    cQuery += " dat_fakt date not null,"
    cQuery += " dat_fakt_prijem date,"
    cQuery += " dob_naz varchar(100) not null,"
    cQuery += " dob_sjediste varchar(100),"
    cQuery += " dob_pdv varchar(12),"
    cQuery += " dob_jib varchar(13),"
    cQuery += " fakt_iznos_bez_pdv numeric(24,2) not null,"
    cQuery += " fakt_iznos_sa_pdv numeric(24,2) not null,"
    cQuery += " fakt_iznos_poljo_pausal numeric(24,2),"
    cQuery += " fakt_iznos_pdv numeric(24,2),"
    cQuery += " fakt_iznos_pdv_np numeric(24,2),"
    cQuery += " fakt_iznos_pdv_np_32 numeric(24,2),"
    cQuery += " fakt_iznos_pdv_np_33 numeric(24,2),"
    cQuery += " fakt_iznos_pdv_np_34 numeric(24,2)," 
    cQuery += " fin_idfirma varchar(2) not null,"
    cQuery += " fin_idvn varchar(2) not null,"
    cQuery += " fin_brnal varchar(8) not null,"
    cQuery += " fin_rbr int not null,"
    cQuery += " opis varchar(500),"
    cQuery += " jci varchar(20),"
    cQuery += " osn_pdv0 numeric(24,2),"
    cQuery += " osn_pdv17 numeric(24,2),"
    cQuery += " osn_pdv17np numeric(24,2),"
    cQuery += " fakt_iznos_dob numeric(24,2)"
    cQuery += ");"
    cQuery += "COMMENT ON COLUMN enabavke.tip IS '01-roba i usluge iz zemlje, 02-vlastita potrosnja vanposlovne svrhe, 03-avansna faktura dati avans,04-JCI uvoz, 05 - ostalo: fakture za primljene usluge ino itd';"
        
    cQuery += 'ALTER SEQUENCE public.enabavke_id_seq OWNER TO "admin";'
    cQuery += 'GRANT ALL ON TABLE public.enabavke TO "admin";'
    cQuery += "GRANT ALL ON TABLE public.enabavke TO xtrole;"

    cQuery += "DROP INDEX if exists enabavke_fin_nalog;"
    cQuery += "CREATE unique INDEX enabavke_fin_nalog ON public.enabavke USING btree (fin_idfirma, fin_idvn, fin_brnal, fin_rbr, extract(year from dat_fakt_prijem));"

    cQuery += 'ALTER TABLE public.eNabavke OWNER TO "admin";'
    cQuery += 'GRANT ALL ON TABLE public.eNabavke TO "admin";'
    cQuery += "GRANT ALL ON TABLE public.eNabavke TO xtrole;"
    
    // eisporuke
    cQuery += "CREATE TABLE if not exists public.eisporuke  ("
    cQuery += " eisporuke_id  integer not null default nextval('eisporuke_id_seq'),"
    cQuery += " tip varchar(2) constraint allowed_eisporuke_vrste check (tip in ('01', '02', '03', '04', '05')),"
    cQuery += " porezni_period varchar(4),"
    cQuery += " br_fakt varchar(100) not NULL,"
    cQuery += " dat_fakt date not null,"
    cQuery += " kup_naz varchar(100) not null,"
    cQuery += " kup_sjediste varchar(100),"
    cQuery += " kup_pdv varchar(12),"
    cQuery += " kup_jib varchar(13),"
    cQuery += " fakt_iznos_sa_pdv numeric(24,2) not null,"
    cQuery += " fakt_iznos_sa_pdv_interna numeric(24,2),"
    cQuery += " fakt_iznos_sa_pdv0_izvoz numeric(24,2),"
    cQuery += " fakt_iznos_sa_pdv0_ostalo numeric(24,2),"
    cQuery += " fakt_iznos_bez_pdv numeric(24,2) not null,"
    cQuery += " fakt_iznos_pdv numeric(24,2),"
    cQuery += " fakt_iznos_bez_pdv_np numeric(24,2) not null,"
    cQuery += " fakt_iznos_pdv_np numeric(24,2),"
    cQuery += " fakt_iznos_pdv_np_32 numeric(24,2),"
    cQuery += " fakt_iznos_pdv_np_33 numeric(24,2),"
    cQuery += " fakt_iznos_pdv_np_34 numeric(24,2),"
    cQuery += " fin_idfirma varchar(2) not null,"
    cQuery += " fin_idvn varchar(2) not null,"
    cQuery += " fin_brnal varchar(8) not null,"
    cQuery += " fin_rbr int not null,"
    cQuery += " opis varchar(500),"
    cQuery += " jci varchar(20)"
    cQuery += ");"
    cQuery += "COMMENT ON COLUMN eisporuke.tip IS '01-roba i usluge iz zemlje, 02-vlastita potrosnja vanposlovne svrhe, 03-avansna faktura primljeni avans,04-JCI izvoz, 05 - ostalo: fakture usluge stranom licu itd';"
    cQuery += 'ALTER SEQUENCE public.eisporuke_id_seq OWNER TO "admin";'
    cQuery += 'GRANT ALL ON TABLE public.eisporuke TO "admin";'
    cQuery += 'GRANT ALL ON TABLE public.eisporuke TO xtrole;'

    cQuery += "DROP INDEX if exists eisporuke_fin_nalog;"
    cQuery += "CREATE unique INDEX eisporuke_fin_nalog ON public.eisporuke USING btree (fin_idfirma, fin_idvn, fin_brnal, fin_rbr, extract(year from dat_fakt));"

    cQuery += 'ALTER TABLE public.eisporuke OWNER TO "admin";'
    cQuery += 'GRANT ALL ON TABLE public.eisporuke TO "admin";'
    cQuery += 'GRANT ALL ON TABLE public.eisporuke TO xtrole;'

    cQuery += 'ALTER TABLE public.enabavke ADD column IF NOT EXISTS idkonto varchar(7);'
    cQuery += 'ALTER TABLE public.enabavke ADD column IF NOT EXISTS idkonto_np varchar(7);'

#ifdef F18_V3
    cQuery += 'ALTER TABLE fmk.kalk_kalk ALTER column brfaktp TYPE varchar(20);'
    cQuery += 'ALTER TABLE fmk.kalk_doks ALTER column brfaktp TYPE varchar(20);'
#endif

    cQuery += 'ALTER TABLE public.eisporuke ADD column IF NOT EXISTS idkonto_pdv varchar(7);'
    cQuery += 'ALTER TABLE public.eisporuke ADD column IF NOT EXISTS idkonto_kup varchar(7);'
    cQuery += 'ALTER TABLE public.eisporuke ADD column IF NOT EXISTS idpartner varchar(6);'

    oQuery := run_sql_query( cQuery )
    
    IF sql_error_in_query( oQuery, "UPDATE" )
        error_bar( "alter_table", cQuery )
        Alert(_u("Greška! DB_UPDATE nije izvršen"))
    ELSE
       set_metric("fin_enab_eisp_db", NIL, DB_VER)
       Alert("tabele enabavke/eisporuke kreirane - ver: " + AllTrim(Str(DB_VER)))
    ENDIF

    
    QUIT_1

    RETURN .T.