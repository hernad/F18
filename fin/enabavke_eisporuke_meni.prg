#include "f18.ch"

#define DB_VER 7

FUNCTION fin_eIsporukeNabavkeMenu()

    LOCAL aOpc := {}
    LOCAL aOpcexe := {}
    LOCAL nIzbor := 1
    LOCAL nDbVer

    nDbVer := fetch_metric("fin_enab_eisp_db", NIL, 0)

    IF nDbVer < DB_VER
        db_create_enabavke_eisporuke(.T.)
    ENDIF

    AAdd( aOpc, "0. upute http://download.bring.out.ba/enabavke_eisporuke.pdf" )
    AAdd( aOpcexe, {|| otvori_eisp_enab_uputstvo() } )

    AAdd( aOpc, "1. enabavke                                                " )
    AAdd( aOpcexe, {|| fin_eNabavke() } )

    AAdd( aOpc, "2. eisporuke                          " )
    AAdd( aOpcexe, {|| fin_eisporuke() } )

    AAdd( aOpc, "P. obračun PDV na osnovu generisanih enab/eisp" )
    AAdd( aOpcexe, {|| eNab_eIsp_PDV() } )

    AAdd( aOpc, "U. fin generacija uvoz" )
    AAdd( aOpcexe, {|| fin_gen_uvoz() } )


    AAdd( aOpc, "X. admin - init tabele enab/eisp " )
    AAdd( aOpcexe, {|| db_create_enabavke_eisporuke() } )
    

    f18_menu( "f_eni", .F., nIzbor, aOpc, aOpcexe )
 
    RETURN .T.


STATIC FUNCTION fin_eNabavke()

    LOCAL aOpc := {}
    LOCAL aOpcexe := {}
    LOCAL nIzbor := 1

    AAdd( aOpc, "1. parametri enabavke                                   " )
    AAdd( aOpcexe, {|| parametri_eNabavke() } )

    AAdd( aOpc, "2. provjera knjiženja enabavke                          " )
    AAdd( aOpcexe, {|| check_eNabavke() } )

    AAdd( aOpc, "3. generacija enabavke                                  " )
    AAdd( aOpcexe, {|| gen_eNabavke() } )

    AAdd( aOpc, "4. enabavke štampa excel/libreoffice xlsx" )
    AAdd( aOpcexe, {|| export_eNabavke() } )

   
    f18_menu( "fin_en", .F., nIzbor, aOpc, aOpcexe )
 
    RETURN .T.


STATIC FUNCTION fin_eIsporuke()

        LOCAL aOpc := {}
        LOCAL aOpcexe := {}
        LOCAL nIzbor := 1

        AAdd( aOpc, "1. parametri eisporuke                                 " )
        AAdd( aOpcexe, {|| parametri_eIsporuke() } )
    
        AAdd( aOpc, "2. provjera knjiženja eisporuke                        " )
        AAdd( aOpcexe, {|| check_eIsporuke() } )

        AAdd( aOpc, "3. generacija eisporuke                                " )
        AAdd( aOpcexe, {|| gen_eIsporuke() } )
    
        AAdd( aOpc, "4. eisporuke štampa excel/libreoffice xlsx             " )
        AAdd( aOpcexe, {|| export_eIsporuke() } )
          
    
        f18_menu( "fin_ei", .F., nIzbor, aOpc, aOpcexe )
     
        RETURN .T.


FUNCTION eNab_eIsp_PDV()

    LOCAL cPDV  := fetch_metric( "fin_enab_my_pdv", NIL, PadR( "<POPUNI>", 12 ) )
    LOCAL dDatOd := fetch_metric( "fin_enab_dat_od", my_user(), DATE()-1 )
    LOCAL dDatDo := fetch_metric( "fin_enab_dat_do", my_user(), DATE() )

    LOCAL cPorezniPeriod
    LOCAL hPDV := hb_hash()
    LOCAL nCnt
    LOCAL cPict := "9999999999.99"
    LOCAL nX := 1, nCol, nWidth
    LOCAL cQuery

    LOCAL GetList := {}
    LOCAL cLokacijaExport := my_home() + "export" + SLASH, nCreate


    Box(, 6, 70 )
        @ box_x_koord() + nX++, box_y_koord() + 2 SAY8 " Vaš PDV broj:" GET cPDV
        @ box_x_koord() + nX, box_y_koord() + 2 SAY "Za period od:" GET dDatOd
        @ box_x_koord() + nX++, col() + 2 SAY "Za period od:" GET dDatDo
        READ
        nX++

        // godina: 2020 -> 20   mjesec: 01, 02, 03 ...
       cPorezniPeriod := RIGHT(AllTrim(STR(Year(dDatOd))), 2) + PADL(AllTrim(STR(Month(dDatOd))), 2, "0")

    BoxC()

    IF Lastkey() == K_ESC
        RETURN .F.
     ENDIF
     
    set_metric( "fin_enab_my_pdv", NIL, cPDV )
    set_metric( "fin_enab_dat_od", my_user(), dDatOd )
    set_metric( "fin_enab_dat_do", my_user(), dDatDo )

    hPdv["11"] := 0
    hPdv["12"] := 0
    hPdv["13"] := 0
    hPdv["21"] := 0
    hPdv["22"] := 0
    hPdv["23"] := 0
    hPdv["41"] := 0
    hPdv["42"] := 0
    hPdv["43"] := 0
    hPdv["51"] := 0
    hPdv["61"] := 0
    hPdv["71"] := 0
    hPdv["32"] := 0
    hPdv["33"] := 0
    hPdv["34"] := 0


    SELECT F_TMP
 
    cQuery := "select sum(fakt_iznos_pdv_np_32) as fakt_iznos_pdv_np_32, sum(fakt_iznos_pdv_np_33) as fakt_iznos_pdv_np_33, sum(fakt_iznos_pdv_np_34) as fakt_iznos_pdv_np_34" 
    cQuery += " FROM public.enabavke WHERE porezni_period=" + sql_quote(cPorezniPeriod) 
    use_sql("ENAB", cQuery)
    hPDV["32"] += enab->fakt_iznos_pdv_np_32
    hPDV["33"] += enab->fakt_iznos_pdv_np_33
    hPDV["34"] += enab->fakt_iznos_pdv_np_34
    use

    // uvoz tip=04
    cQuery := "select sum(fakt_iznos_bez_pdv) as fakt_iznos_bez_pdv, sum(fakt_iznos_pdv + fakt_iznos_pdv_np) as iznos_pdv" 
    cQuery += " FROM public.enabavke WHERE porezni_period=" + sql_quote(cPorezniPeriod)
    cQuery += " AND tip='04'"
    use_sql("ENAB", cQuery)
    hPDV["22"] := ROUND(enab->fakt_iznos_bez_pdv, 0)
    // PDV na uvoz
    hPDV["42"] := ROUND(enab->iznos_pdv, 0)
    use

    
    //  poljop naknada 
    cQuery := "select sum(fakt_iznos_bez_pdv) as fakt_iznos_bez_pdv, sum(fakt_iznos_poljo_pausal) as iznos_pausal" 
    cQuery += " FROM public.enabavke WHERE porezni_period=" + sql_quote(cPorezniPeriod)
    cQuery += " AND fakt_iznos_poljo_pausal<>0"
    use_sql("ENAB", cQuery)
    hPDV["23"] := ROUND(enab->fakt_iznos_bez_pdv, 0)
    // pausalna naknada za poljop
    hPDV["43"] := ROUND(enab->iznos_pausal, 0)
    use

    //  sve nabavke iznos bez pdv
    cQuery := "select sum(fakt_iznos_bez_pdv) as fakt_iznos_bez_pdv, sum(fakt_iznos_pdv) as iznos_pdv" 
    cQuery += " FROM public.enabavke WHERE porezni_period=" + sql_quote(cPorezniPeriod)
    use_sql("ENAB", cQuery)
    hPDV["21"] := ROUND(enab->fakt_iznos_bez_pdv - hPDV["23"] - hPDV["22"], 0)
    // ulazni pdv (odbitni - samo poslovna potrosnja) - uvoz - poljop pausal naknada
    hPDV["41"] := ROUND(enab->iznos_pdv - hPDV["42"] - hPDV["43"], 0)
    use

    hPDV["61"] := ROUND(hPDV["41"] + hPDV["42"] + hPDV["43"], 0)


    // isporuke izvoz tip=04
    cQuery := "select sum(fakt_iznos_sa_pdv0_izvoz) as fakt_iznos" 
    cQuery += " FROM public.eisporuke WHERE porezni_period=" + sql_quote(cPorezniPeriod)
    cQuery += " AND tip='04'"
    use_sql("EISP", cQuery)
    hPDV["12"] += ROUND(eisp->fakt_iznos, 0)
    use

    altd()
    // oslobodjeno po clnu 24 i 25 ide u polje PDV 13
    cQuery := "select sum(fakt_iznos_sa_pdv0_ostalo) as fakt_iznos FROM public.eisporuke" 
    cQuery += " LEFT JOIN fmk.fin_suban on eisporuke.fin_idfirma=fin_suban.idfirma and eisporuke.fin_idvn=fin_suban.idvn and eisporuke.fin_brnal=fin_suban.brnal and eisporuke.fin_rbr=fin_suban.rbr and extract(year from  fin_suban.datdok)=extract(year from eisporuke.dat_fakt)"
    cQuery += " WHERE porezni_period=" + sql_quote(cPorezniPeriod)
    cQuery += " and (substr(get_sifk('PARTN', 'PDVO', fin_suban.idpartner),1,2) IN ('24','25') OR substring(eisporuke.opis from 'PDV0:\s*CLAN(\d+)') IN ('24','25'))"
    use_sql("EISP", cQuery)
    hPDV["13"] := ROUND(eisp->fakt_iznos, 0)
    use

    // oslobodjeno po ostalim clanovima ide u polje PDV 11
    cQuery := "select sum(fakt_iznos_sa_pdv0_ostalo) as fakt_iznos FROM public.eisporuke" 
    cQuery += " LEFT JOIN fmk.fin_suban on eisporuke.fin_idfirma=fin_suban.idfirma and eisporuke.fin_idvn=fin_suban.idvn and eisporuke.fin_brnal=fin_suban.brnal and eisporuke.fin_rbr=fin_suban.rbr and extract(year from  fin_suban.datdok)=extract(year from eisporuke.dat_fakt)"
    cQuery += " WHERE porezni_period=" + sql_quote(cPorezniPeriod)
    cQuery += " and NOT (substr(get_sifk('PARTN', 'PDVO', fin_suban.idpartner),1,2) IN ('24','25') OR substring(eisporuke.opis from 'PDV0:\s*CLAN(\d+)') IN ('24','25'))"
    use_sql("EISP", cQuery)
    hPDV["11"] := eisp->fakt_iznos
    use

    // isporuke sve iznos bez pdv osim izvoz i pdv0_ostalo clan 24 i 25
    cQuery := "select sum(fakt_iznos_bez_pdv + fakt_iznos_bez_pdv_np) as fakt_iznos_bez_pdv, sum(fakt_iznos_pdv + fakt_iznos_pdv_np) as iznos_pdv" 
    cQuery += " FROM public.eisporuke WHERE porezni_period=" + sql_quote(cPorezniPeriod)
    cQuery += " AND tip<>'04' and fakt_iznos_sa_pdv0_ostalo=0 and fakt_iznos_sa_pdv0_izvoz=0"
    use_sql("EISP", cQuery)
    hPDV["11"] += eisp->fakt_iznos_bez_pdv
    hPDV["11"] := ROUND(hPDV["11"], 0)

    // izlazni PDV
    hPDV["51"] := ROUND(eisp->iznos_pdv, 0)
    use

    // pdv za uplatu
    hPDV["71"] := hPDV["51"] - hPDV["61"]
    hPDV["71"] := ROUND(hPDV["71"], 0)

    SELECT F_TMP
    cQuery := "select sum(fakt_iznos_pdv_np_32) as fakt_iznos_pdv_np_32, sum(fakt_iznos_pdv_np_33) as fakt_iznos_pdv_np_33, sum(fakt_iznos_pdv_np_34) as fakt_iznos_pdv_np_34" 
    cQuery += " FROM public.eisporuke WHERE porezni_period=" + sql_quote(cPorezniPeriod)
    use_sql("EISP", cQuery)
    hPDV["32"] += eisp->fakt_iznos_pdv_np_32
    hPDV["33"] += eisp->fakt_iznos_pdv_np_33
    hPDV["34"] += eisp->fakt_iznos_pdv_np_34

    hPDV["32"] := ROUND(hPDV["32"], 0)
    hPDV["33"] := ROUND(hPDV["33"], 0)
    hPDV["34"] := ROUND(hPDV["34"], 0)
    use

    nX := 0
    nCol := 42
    nWidth := 25
    

    Box(, 28, 85)
    @ box_x_koord() + nX++, box_y_koord() + 2 SAY8 "Obračun PDV za: " + cPDV + " porezni period: " + cPorezniPeriod

    nX++
    @ box_x_koord() + nX++, box_y_koord() + 2 SAY8 REPLICATE("-", 78)
    @ box_x_koord() + nX++, box_y_koord() + 2 SAY8 "I. Isporuke i nabavke svi iznosi iskazani bez PDV"

    nX++
    @ box_x_koord() + nX, box_y_koord() + 2 SAY8 Padr("(11) sve isporuke : ", nWidth) + Transform(hPDV[ "11" ], cPict)
    @ box_x_koord() + nX++, box_y_koord() + nCol SAY8 Padr("(21) sve nabavke : ", nWidth) + Transform(hPDV[ "21" ], cPict)

    @ box_x_koord() + nX, box_y_koord() + 2 SAY8 Padr("(12) izvoz: ", nWidth) + Transform(hPDV[ "12" ], cPict)
    @ box_x_koord() + nX++, box_y_koord() + nCol SAY8 Padr("(22) uvoz : ", nWidth) + Transform(hPDV[ "22" ], cPict)

    @ box_x_koord() + nX, box_y_koord() + 2 SAY8 PADR("(13) oslobodjene placanja PDV: ", nWidth) + Transform(hPDV[ "13" ], cPict)
    @ box_x_koord() + nX++, box_y_koord() + nCol SAY8 PADR("(23) nabavke od poljopriv: ", nWidth) + Transform(hPDV[ "23" ], cPict)

    nX++
    @ box_x_koord() + nX++, box_y_koord() + 2 SAY8 REPLICATE("-", 78)
    @ box_x_koord() + nX++, box_y_koord() + 2 SAY8 "II. izlazni PDV"
    nX++
    @ box_x_koord() + nX++, box_y_koord() + nCol SAY8 Padr("(41) PDV na ulaz od reg.obv. PDV: ", nWidth) + Transform(hPDV[ "41" ], cPict)
    @ box_x_koord() + nX++, box_y_koord() + nCol SAY8 Padr("(42) PDV na uvoz:                 ", nWidth) + Transform(hPDV[ "42" ], cPict)
    @ box_x_koord() + nX++, box_y_koord() + nCol SAY8 Padr("(42) paus nakn za poljopriv:", nWidth) + Transform(hPDV[ "43" ], cPict)

    nX++
    @ box_x_koord() + nX++, box_y_koord() + 2 SAY8 REPLICATE("-", 78)
    @ box_x_koord() + nX, box_y_koord() + 2 SAY8 Padr("(51) PDV izlazni:   ", nWidth) + Transform(hPDV[ "51" ], cPict)
    @ box_x_koord() + nX++, box_y_koord() + nCol SAY8 Padr("(61) PDV ulazni:               ", nWidth) + Transform(hPDV[ "61" ], cPict)

    nX++
    @ box_x_koord() + nX++, box_y_koord() + 2 SAY8 REPLICATE("-", 78)
    @ box_x_koord() + nX, box_y_koord() + 2 SAY8 Padr("(71) PDV za uplatu/povrat:  ", nWidth) + Transform(hPDV[ "71" ], cPict)

    nX++
    @ box_x_koord() + nX++, box_y_koord() + 2 SAY8 REPLICATE("-", 78)
    @ box_x_koord() + nX++, box_y_koord() + 2 SAY8 "III. Podaci o krajnjoj potrošnji"
    nX++
    @ box_x_koord() + nX++, box_y_koord() + 2 SAY8 Padr("(32) FBiH: ", nWidth) + Transform(hPDV[ "32" ], cPict)
    @ box_x_koord() + nX++, box_y_koord() + 2 SAY8 Padr("(33) RS: ", nWidth) + Transform(hPDV[ "33" ], cPict)
    @ box_x_koord() + nX++, box_y_koord() + 2 SAY8 Padr("(34) BD: ", nWidth) + Transform(hPDV[ "34" ], cPict)

    inkey(0)
    BoxC()

    RETURN .T.


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
    

FUNCTION otvori_eisp_enab_uputstvo()

    LOCAL cCmd
    LOCAL cURL := "http://download.bring.out.ba/enabavke_eisporuke.pdf"
    
    IF is_linux()
        cCmd := "" //"gio open"
        f18_open_mime_document( cURL )
    ELSE 
        cCmd := f18_run("cmd /c start " + cURL)
    ENDIF
    

    RETURN .T.
