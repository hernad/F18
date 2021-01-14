#include "f18.ch"

STATIC s_cXlsxName := NIL
STATIC s_pWorkBook, s_pWorkSheet, s_nWorkSheetRow
STATIC s_pMoneyFormat, s_pDateFormat

FUNCTION parametri_eIsporuke

    LOCAL nX := 1
    LOCAL GetList := {}

    LOCAL cIdKontoKupac := PadR( fetch_metric( "fin_eisp_idkonto_kup", NIL, "21" ), 7 )
    LOCAL cIdKontoPDV := PadR( fetch_metric( "fin_eisp_idkonto_pdv", NIL, "470" ), 7 )
    LOCAL cIdKontoPDVAvansi := PadR( fetch_metric( "fin_eisp_idkonto_pdv_a", NIL, "471" ), 7 )
    LOCAL cIdKontoPDVInterne := PadR( fetch_metric( "fin_eisp_idkonto_pdv_int", NIL, "472" ), 7 )

    LOCAL cIdKontoPDVNeFBiH := PadR( fetch_metric( "fin_eisp_idkonto_pdv_nepdv_1", NIL, "4730" ), 7 )
    LOCAL cIdKontoPDVNeRS := PadR( fetch_metric( "fin_eisp_idkonto_pdv_nepdv_2", NIL, "4731" ), 7 )
    LOCAL cIdKontoPDVNeBD := PadR( fetch_metric( "fin_eisp_idkonto_pdv_nepdv_3", NIL, "4732" ), 7 )

    
    LOCAL cIdKontoPDVUslugeStranaLica := PadR( fetch_metric( "fin_eisp_idkonto_pdv_ust", NIL, "474" ), 7 )
    LOCAL cIdKontoPDVSchema := PadR( fetch_metric( "fin_eisp_idkonto_pdv_schema", NIL, "475" ), 7 )
    LOCAL cIdKontoPDVOstalo := PadR( fetch_metric( "fin_eisp_idkonto_pdv_ostalo", NIL, "478" ), 7 )
    LOCAL cNabExcludeIdvn := PadR( fetch_metric( "fin_enab_idvn_exclude", NIL, "I1,I2,IB,B1,B2,B3,PD" ), 100 )

    Box(, 18, 80 )

       @ box_x_koord() + nX++, box_y_koord() + 2 SAY "***** eIsporuke PARAMETRI *****"

       @ box_x_koord() + nX++, box_y_koord() + 2 SAY8 "Konto kupac                             " GET cIdKontoKupac

       nX++
       @ box_x_koord() + nX++, box_y_koord() + 2 SAY8 "Konto PDV pdv obveznici                 " GET cIdKontoPDV VALID P_Konto(@cIdKontoPDV)
       @ box_x_koord() + nX++, box_y_koord() + 2 SAY8 "Konto PDV primljeni avansi              " GET cIdKontoPDVAvansi VALID P_Konto(@cIdKontoPDVAvansi)
       @ box_x_koord() + nX++, box_y_koord() + 2 SAY8 "Konto PDV interne fakture neposl. svrhe " GET cIdKontoPDVInterne VALID P_Konto(@cIdKontoPDVInterne)

       nX++
       @ box_x_koord() + nX++, box_y_koord() + 2 SAY8 "Konto PDV nepdv obveznici FBiH          " GET cIdKontoPDVNeFBiH VALID P_Konto(@cIdKontoPDVNeFBiH)
       @ box_x_koord() + nX++, box_y_koord() + 2 SAY8 "Konto PDV nepdv obveznici RS            " GET cIdKontoPDVNeRS VALID P_Konto(@cIdKontoPDVNeRS)
       @ box_x_koord() + nX++, box_y_koord() + 2 SAY8 "Konto PDV nepdv obveznici BD            " GET cIdKontoPDVNeBD VALID P_Konto(@cIdKontoPDVNeBD)

       @ box_x_koord() + nX++, box_y_koord() + 2 SAY8 "Konto PDV usluge strana lica            " GET cIdKontoPDVUslugeStranaLica VALID P_Konto(@cIdKontoPDVUslugeStranaLica)
       @ box_x_koord() + nX++, box_y_koord() + 2 SAY8 "Konto PDV posebna schema                " GET cIdKontoPDVSchema VALID P_Konto(@cIdKontoPDVSchema)
       
       @ box_x_koord() + nX++, box_y_koord() + 2 SAY8 "Konto PDV ostalo                        " GET cIdKontoPDVOstalo VALID P_Konto(@cIdKontoPDVOstalo)


       @ box_x_koord() + nX++, box_y_koord() + 2 SAY8 "FIN nalozi koji su isključuju iz generacije e-nabavki/isporuka"
       @ box_x_koord() + nX++, box_y_koord() + 2 SAY8 "(blagajna, izvodi, obračun PDV)" GET cNabExcludeIdvn PICTURE "@S35" 

       READ
    BoxC()

    IF Lastkey() == K_ESC
       RETURN .F.
    ENDIF

    set_metric( "fin_eisp_idkonto_kup", NIL, cIdKontoKupac)
    set_metric( "fin_eisp_idkonto_pdv", NIL, cIdKontoPDV)
    set_metric( "fin_eisp_idkonto_pdv_a", NIL, cIdKontoPDVAvansi)
    set_metric( "fin_eisp_idkonto_pdv_int", NIL, cIdKontoPDVInterne)

    set_metric( "fin_eisp_idkonto_pdv_nepdv_1", NIL, cIdKontoPDVNeFBiH)
    set_metric( "fin_eisp_idkonto_pdv_nepdv_2", NIL, cIdKontoPDVNeRS)
    set_metric( "fin_eisp_idkonto_pdv_nepdv_3", NIL, cIdKontoPDVNeBD)

    set_metric( "fin_eisp_idkonto_pdv_ust", NIL, cIdKontoPDVUslugeStranaLica)
    set_metric( "fin_eisp_idkonto_pdv_schema", NIL, cIdKontoPDVSchema)
    set_metric( "fin_eisp_idkonto_pdv_ostalo", NIL, cIdKontoPDVOstalo)
    set_metric( "fin_enab_idvn_exclude", NIL, Trim(cNabExcludeIdvn))


    RETURN .T.




FUNCTION check_eIsporuke()

    LOCAL cIdKontoKupac := PadR( fetch_metric( "fin_eisp_idkonto_kup", NIL, "21" ), 7 )


    LOCAL cIdKontoPDV := trim( fetch_metric( "fin_eisp_idkonto_pdv", NIL, "470" ))
    LOCAL cIdKontoPDVAvansi := trim( fetch_metric( "fin_eisp_idkonto_pdv_a", NIL, "471"))
    LOCAL cIdKontoPDVInterne := trim( fetch_metric( "fin_eisp_idkonto_pdv_int", NIL, "472" ))

    LOCAL cIdKontoPDVNeFBiH := trim( fetch_metric( "fin_eisp_idkonto_pdv_nepdv_1", NIL, "4730" ) )
    LOCAL cIdKontoPDVNeRS := trim( fetch_metric( "fin_eisp_idkonto_pdv_nepdv_2", NIL, "4731" ) )
    LOCAL cIdKontoPDVNeBD := trim( fetch_metric( "fin_eisp_idkonto_pdv_nepdv_3", NIL, "4732" ) )

    
    LOCAL cIdKontoPDVUslugeStranaLica := trim( fetch_metric( "fin_eisp_idkonto_pdv_ust", NIL, "474" ))
    LOCAL cIdKontoPDVSchema := trim( fetch_metric( "fin_eisp_idkonto_pdv_schema", NIL, "475" ))
    LOCAL cIdKontoPDVOstalo :=trim( fetch_metric( "fin_eisp_idkonto_pdv_ostalo", NIL, "478" ))

    LOCAL cNabExcludeIdvn := TRIM( fetch_metric( "fin_enab_idvn_exclude", NIL, "I1,I2,IM,IB,B1,B2,PD" ) )
    LOCAL cSelectFields, cFinNalogNalog2, cLeftJoinFin2
    LOCAL cTmps

    LOCAL dDatOd := fetch_metric( "fin_enab_dat_od", my_user(), DATE()-1 )
    LOCAL dDatDo := fetch_metric( "fin_enab_dat_do", my_user(), DATE() )
    LOCAL nX := 1
    LOCAL GetList := {}
    LOCAL cQuery, cQuery2, cQuery3, cQuery4, cQuery5, cQuery6
    

    Box(,3, 70)
       @ box_x_koord() + nX++, box_y_koord() + 2 SAY "***** eIsporuke PROVJERA *****"
       @ box_x_koord() + nX, box_y_koord() + 2 SAY "Za period od:" GET dDatOd
       @ box_x_koord() + nX++, col() + 2 SAY "Za period od:" GET dDatDo
       READ
    BoxC()


    IF Lastkey() == K_ESC
      RETURN .F.
    ENDIF

    set_metric( "fin_enab_dat_od", my_user(), dDatOd )
    set_metric( "fin_enab_dat_do", my_user(), dDatDo )

    cTmps := get_sql_expression_exclude_idvns(cNabExcludeIdvn)
    cSelectFields := "SELECT fin_suban.idfirma, fin_suban.idvn, fin_suban.brnal, fin_suban.rbr, fin_suban.idkonto as idkonto, sub2.idkonto as idkonto2,"
    cSelectFields += "fin_suban.BrDok brdok, sub2.brdok brdok2, fin_suban.idpartner"
    cFinNalogNalog2 := "fin_suban.idfirma=sub2.idfirma and fin_suban.idvn=sub2.idvn and fin_suban.brnal=sub2.brnal"
   
    // 470
    cQuery := cSelectFields
    cQuery += " from fmk.fin_suban "
   
    
    cLeftJoinFin2 := " left join fmk.fin_suban sub2 on " + cFinNalogNalog2 + " and fin_suban.brdok=sub2.brdok" +;
      " and (sub2.idkonto like '" + Trim(cIdKontoPDV) +;
      "%' OR sub2.idkonto like '" + Trim(cIdKontoPDVSchema) +;
      "%' OR sub2.idkonto like '" + Trim(cIdKontoPDVInterne) +;
      "%' OR sub2.idkonto like '" + Trim(cIdKontoPDVAvansi) +;
      "%' OR sub2.idkonto like '" + Trim(cIdKontoPDVUslugeStranaLica) +;
      "%' OR sub2.idkonto like '" + Trim(cIdKontoPDVOstalo) +;
      "%' OR sub2.idkonto like '" + Trim(cIdKontoPDVNeFBiH) +;
      "%' OR sub2.idkonto like '" + Trim(cIdKontoPDVNeRS) +;
      "%' OR sub2.idkonto like '" + Trim(cIdKontoPDVNeBD) + "%')"

    cQuery += cLeftJoinFin2

    cQuery += " left join fmk.partn on sub2.idpartner=partn.id"
    cQuery += " where fin_suban.idkonto like  '"  + Trim(cIdKontoKupac) + "%'"
    cQuery += " and fin_suban.datdok >= " + sql_quote(dDatOd) + " and fin_suban.datdok <= " + sql_quote(dDatDo)
    cQuery += " and not fin_suban.idvn in (" + cTmps + ")"

    // kupac duguje
    cQuery += " and fin_suban.d_p='1'"

    // nema pridruzenog konta pdv ili je brdok empty
    cQuery += " and (sub2.idkonto is null or trim(sub2.idkonto)='' or trim(fin_suban.brdok)='' )"

   
    IF !use_sql( "EISP", cQuery + " order by idfirma, idvn, brnal, rbr, brdok")
        RETURN .F.
    ENDIF

    nX:=1
    Box( ,15, 85)
    @ box_x_koord() + nX++, box_y_koord() + 2 SAY "****** FIN nalozi koji nemaju zadane ispravne partnere ili veze (brdok):"
    @ box_x_koord() + nX++, box_y_koord() + 2 SAY "       (Provjerite da li je Partner INO ili oslobodjen po ZPDV)         "

    ++nX
    DO WHILE !EOF()

        IF !is_part_pdv_oslob_po_clanu(eisp->idpartner) .AND. !partner_is_ino(eisp->idpartner )
          @ box_x_koord() + nX++, box_y_koord() + 2 SAY eisp->idfirma + "-" + eisp->idvn + "-" + eisp->brnal + " Rbr:" + str(eisp->rbr,4) +;
                   " Konto:" + trim(eisp->idkonto) + " / " + trim(eisp->idkonto2)
          
        ENDIF
        IF nX > 13
           Inkey(0)
           nX := 3
        ENDIF
        IF LastKey() == K_ESC
            EXIT
        ENDIF
        skip
    ENDDO
    Inkey(0)
    BoxC()

    USE
    RETURN .T.


STATIC FUNCTION create_csv( cFile )

    IF cFile == nil
        cFile := my_home() + "data.csv"
    ENDIF
     
    SET PRINTER to ( cFile )
    SET PRINTER ON
    SET CONSOLE OFF
     
    RETURN .T.

STATIC FUNCTION close_csv()

    SET PRINTER TO
    SET PRINTER OFF
    SET CONSOLE ON
     
    RETURN .T.


/*

CREATE sequence if not exists eisporuke_id_seq;

CREATE TABLE if not exists public.eisporuke  (
    eisporuke_id  integer not null default nextval('eisporuke_id_seq'),
    tip varchar(2) constraint allowed_eisporuke_vrste check (tip in ('01', '02', '03', '04', '05')),
    porezni_period varchar(4),
    br_fakt varchar(100) not NULL,
    dat_fakt date not null,
    kup_naz varchar(100) not null,
    kup_sjediste varchar(100),
    kup_pdv varchar(12),
    kup_jib varchar(13), 
    fakt_iznos_sa_pdv numeric(24,2) not null,
    fakt_iznos_sa_pdv_interna numeric(24,2),
    fakt_iznos_sa_pdv0_izvoz numeric(24,2),
    fakt_iznos_sa_pdv0_ostalo numeric(24,2),
    fakt_iznos_bez_pdv numeric(24,2) not null,
    fakt_iznos_pdv numeric(24,2),
    fakt_iznos_bez_pdv_np numeric(24,2) not null,
    fakt_iznos_pdv_np numeric(24,2),
    fakt_iznos_pdv_np_32 numeric(24,2),
    fakt_iznos_pdv_np_33 numeric(24,2),
    fakt_iznos_pdv_np_34 numeric(24,2)
);
    
COMMENT ON COLUMN eisporuke.tip IS '01-roba i usluge iz zemlje, 02-vlastita potrosnja vanposlovne svrhe, 03-avansna faktura primljeni avans,04-JCI izvoz, 05 - ostalo: fakture usluge stranom licu itd';

ALTER SEQUENCE public.eisporuke_id_seq OWNER TO "admin";
GRANT ALL ON TABLE public.eisporuke TO "admin";
GRANT ALL ON TABLE public.eisporuke TO xtrole;


alter table eisporuke add column fin_idfirma varchar(2) not null;
alter table eisporuke add column fin_idvn varchar(2) not null;
alter table eisporuke add column fin_brnal varchar(8) not null;
alter table eisporuke add column fin_rbr int not null;
alter table eisporuke add column opis varchar(500);
alter table eisporuke add column jci varchar(20);

DROP INDEX if exists eisporuke_fin_nalog;
CREATE unique INDEX eisporuke_fin_nalog ON public.eisporuke USING btree (fin_idfirma, fin_idvn, fin_brnal, fin_rbr);

ALTER TABLE public.eisporuke OWNER TO "admin";
GRANT ALL ON TABLE public.eisporuke TO "admin";
GRANT ALL ON TABLE public.eisporuke TO xtrole;

*/
STATIC FUNCTION db_insert_eisp( hRec )

    LOCAL cQuery := "INSERT INTO public.eisporuke", oRet
    LOCAL oError
    
    cQuery += "(eisporuke_id, tip, porezni_period, br_fakt, jci, dat_fakt, "
    cQuery += "kup_naz,kup_sjediste, kup_pdv, kup_jib,"
    cQuery += "fakt_iznos_sa_pdv,fakt_iznos_sa_pdv_interna,fakt_iznos_sa_pdv0_izvoz,fakt_iznos_sa_pdv0_ostalo,fakt_iznos_bez_pdv,fakt_iznos_pdv,fakt_iznos_bez_pdv_np,"
    cQuery += "fakt_iznos_pdv_np,fakt_iznos_pdv_np_32,fakt_iznos_pdv_np_33,fakt_iznos_pdv_np_34,"
    cQuery += "opis, fin_idfirma, fin_idvn,fin_brnal,fin_rbr) "
    cQuery += "VALUES("
    cQuery += sql_quote(hRec["eisporuke_id"]) + ","
    cQuery += sql_quote(hRec["tip"]) + ","
    cQuery += sql_quote(hRec["porezni_period"]) + ","
    cQuery += sql_quote(hRec["br_fakt"]) + ","
    cQuery += sql_quote(hRec["jci"]) + ","
    cQuery += sql_quote(hRec["dat_fakt"]) + ","
    cQuery += sql_quote(hRec["kup_naz"]) + ","
    cQuery += sql_quote(hRec["kup_sjediste"]) + ","
    cQuery += sql_quote(hRec["kup_pdv"]) + ","
    cQuery += sql_quote(hRec["kup_jib"]) + ","
    cQuery += sql_quote(ROUND(hRec["fakt_iznos_sa_pdv"],2)) + ","
    cQuery += sql_quote(ROUND(hRec["fakt_iznos_sa_pdv_interna"],2)) + ","
    cQuery += sql_quote(ROUND(hRec["fakt_iznos_sa_pdv0_izvoz"],2)) + ","
    cQuery += sql_quote(ROUND(hRec["fakt_iznos_sa_pdv0_ostalo"],2)) + ","

    cQuery += sql_quote(ROUND(hRec["fakt_iznos_bez_pdv"],2)) + ","
    cQuery += sql_quote(ROUND(hRec["fakt_iznos_pdv"],2)) + ","

    cQuery += sql_quote(ROUND(hRec["fakt_iznos_bez_pdv_np"],2)) + ","
    cQuery += sql_quote(ROUND(hRec["fakt_iznos_pdv_np"],2)) + ","
    cQuery += sql_quote(ROUND(hRec["fakt_iznos_pdv_np_32"],2)) + ","
    cQuery += sql_quote(ROUND(hRec["fakt_iznos_pdv_np_33"],2)) + ","
    cQuery += sql_quote(ROUND(hRec["fakt_iznos_pdv_np_34"],2)) + ","
    cQuery += sql_quote(hRec["opis"]) + ","
    cQuery += sql_quote(hRec["fin_idfirma"]) + ","
    cQuery += sql_quote(hRec["fin_idvn"]) + ","
    cQuery += sql_quote(hRec["fin_brnal"]) + ","
    cQuery += sql_quote(hRec["fin_rbr"]) + ")"

    BEGIN SEQUENCE WITH {| err| Break( err ) }
        oRet := run_sql_query(cQuery)
    RECOVER USING oError
        error_bar( "eisp_ins:" + oError:description )  
    END SEQUENCE

    IF sql_error_in_query( oRet, "INSERT" )
      RETURN .F.
    ENDIF

    RETURN .T.



STATIC FUNCTION say_number( nNumber )
    RETURN AllTRIM(TRANSFORM(nNumber, "9999999999999999999999.99"))


STATIC FUNCTION say_string( cString, nLen, lToUTF)
    LOCAL cTmp
    
    IF lToUTF == NIL
        lToUTF := .T.
    ENDIF

    // ukloniti ";" -> "/"
    cTmp := STRTRAN(cString, ";", "/")
    cTmp := PADR( cTmp, nLen )
    cTmp := TRIM( cTmp )

    if lToUTF
        cTmp := hb_StrToUTF8(cTmp)
    ENDIF

    RETURN cTmp


/*

  select  (case when sub2.d_p='1' then 1 else -1 end) * sub2.iznosbhd - (case when fin_suban.d_p='2' then 1 else -1 end) * fin_suban.iznosbhd as bez_pdv,
        (case when fin_suban.d_p='2' then 1 else -1 end) * fin_suban.iznosbhd as pdv, 
        (case when sub2.d_p='1' then 1 else -1 end) * sub2.iznosbhd as iznos_sa_pdv,

        get_sifk('PARTN', 'PDVB', sub2.idpartner), get_sifk('PARTN', 'IDBR', sub2.idpartner), partn.naz, sub2.idkonto, fin_suban.* from fmk.fin_suban 
   left join fmk.fin_suban sub2 on fin_suban.idfirma=sub2.idfirma and fin_suban.idvn=sub2.idvn and fin_suban.brnal=sub2.brnal and fin_suban.brdok=sub2.brdok and sub2.idkonto like '2%'
   left join fmk.partn on sub2.idpartner=partn.id
   where fin_suban.idkonto like  '47%' and fin_suban.datdok >= '2020-10-01' and fin_suban.datdok <= '2020-10-31' and not fin_suban.idvn in ('PD','IB');



*/
STATIC FUNCTION gen_eisporuke_stavke(nRbr, dDatOd, dDatDo, cPorezniPeriod, cTipDokumenta, cIdKonto, cNabExcludeIdvn, ;
    lPDVNule, lOsnovaNula, cMjestoKrajnjePotrosnjeIn, hUkupno )

    LOCAL cSelectFields, cBrDokFinFin2, cFinNalogNalog2, cLeftJoinFin2
    LOCAL cQuery, cTmps
    LOCAL cCSV := ";"
    LOCAL n32, n33, n34
    LOCAL cPDVBroj, cJib
    LOCAL nInternaSaPDV, nNePDVObveznikSaPDV, nDaPDVObveznikSaPDV
    LOCAL nPDVInterna, nPDVDaPDVObveznik, nPDVNePDVObveznik
    LOCAL nOsnovicaNePdvObveznik, nOsnovicaDaPDVObveznik      
    LOCAL nOsnovicaInterna, nOsnovicaIzvoz, nOsnovicaPDV0Oostalo
    LOCAL hRec := hb_hash()
    LOCAL cKto
    LOCAL cBrDok
    LOCAL cTipDokumenta2
    LOCAL cMjestoKrajnjePotrosnje


    LOCAL cIdKontoKupac := trim(fetch_metric( "fin_eisp_idkonto_kup", NIL, '21'))
    LOCAL cIdKontoDobavljac := trim(fetch_metric( "fin_enab_idkonto_dob", NIL, '43'))
    
    cTmps := get_sql_expression_exclude_idvns(cNabExcludeIdvn)
    
    /*
        cIdKonto == NIL u slucaju PDV 0%:
        // 04 izvoz
        // 01 isporuke oslobodjenje po ZPDV PDV-a
    */
    IF cIdKonto == NIL
        // PDV0 gleda se samo kupac
        cSelectFields := "SELECT get_sifk('PARTN', 'PDVB', COALESCE(fin_suban.idpartner,'9999999')) as pdv_broj, get_sifk('PARTN', 'IDBR', COALESCE(fin_suban.idpartner,'9999999')) as jib,"
        cSelectFields += "(case when fin_suban.d_p='1' then 1 else -1 end) * fin_suban.iznosbhd as iznos_sa_pdv,"
        cSelectFields += "0 as pdv,"
        cSelectFields += "0 as bez_pdv,"
        cSelectFields += "0 as from_opis_osn_pdv17,"
        cSelectFields += "substring(fin_suban.opis from 'JCI:\s*(\d+)') as JCI,"
        cSelectFields += "fin_suban.idkonto as idkonto, fin_suban.idfirma, fin_suban.idvn, fin_suban.brnal, fin_suban.rbr,"
        
    ELSE
        cSelectFields := "SELECT get_sifk('PARTN', 'PDVB', COALESCE(sub2.idpartner,'9999999')) as pdv_broj, get_sifk('PARTN', 'IDBR', COALESCE(sub2.idpartner,'9999999')) as jib,"
        cSelectFields += "((case when sub2.d_p='1' then 1 else -1 end) * sub2.iznosbhd - (case when fin_suban.d_p='2' then 1 else -1 end) * fin_suban.iznosbhd)  as bez_pdv,"
        cSelectFields += "(case when fin_suban.d_p='2' then 1 else -1 end) * fin_suban.iznosbhd  as pdv,"
        cSelectFields += "(case when sub2.d_p='1' then 1 else -1 end) * sub2.iznosbhd  as iznos_sa_pdv,"
        cSelectFields += "'' as JCI,"
        cSelectFields += "COALESCE(substring(sub2.opis from 'OSN-PDV17:\s*([-+\d.]+)')::DECIMAL, -9999999.99) as from_opis_osn_pdv17,"
        cSelectFields += "fin_suban.idkonto as idkonto, sub2.idkonto as idkonto2, fin_suban.idfirma, fin_suban.idvn, fin_suban.brnal, fin_suban.rbr,"
    ENDIF

    cSelectFields += "fin_suban.brdok, fin_suban.opis, fin_suban.d_p, fin_suban.datdok, fin_suban.datval,"
    cSelectFields += "partn.id as partn_id, partn.naz as partn_naz, partn.adresa as partn_adresa, partn.ptt as partn_ptt, partn.mjesto as partn_mjesto, partn.rejon partn_rejon,"
    cSelectFields += "COALESCE(eisporuke.fin_rbr,-99999) eisp_rbr"     

    cBrDokFinFin2 := "fin_suban.brdok=sub2.brdok"
    cFinNalogNalog2 := "fin_suban.idfirma=sub2.idfirma and fin_suban.idvn=sub2.idvn and fin_suban.brnal=sub2.brnal"

       
    // 4740 - PDV  obracunat na fakture dobavljaca - usluge stranih lica 
    IF lOsnovaNula == NIL
        lOsnovaNula := .F.
    ENDIF
    IF lOsnovaNula
        // kod usluga stranih lica 4740, ino-dobavljac usluga se koristi kao kupac 
        cKto := trim(cIdKontoDobavljac)
    ELSE
        cKto := trim(cIdKontoKupac)
    ENDIF

    IF cIdKonto == NIL
       // povezi kupca sa '47%'
       cKto := LEFT(fetch_metric( "fin_eisp_idkonto_pdv", NIL, "470" ), 2) 
       cLeftJoinFin2 := " left join fmk.fin_suban sub2 on " + cFinNalogNalog2 + " and " + cBrDokFinFin2 + " and sub2.idkonto like '" + Trim(cKto) + "%'"
    ELSE
       // povezi konto PDV sa kupcom
       cLeftJoinFin2 := " left join fmk.fin_suban sub2 on " + cFinNalogNalog2 + " and " + cBrDokFinFin2 + " and sub2.idkonto like '" + cKto + "%'"
    ENDIF

    cQuery := cSelectFields
    cQuery += " from fmk.fin_suban "

    cQuery += cLeftJoinFin2 
    IF cIdKonto == NIL
      cQuery += " left join fmk.partn on fin_suban.idpartner=partn.id"
    ELSE
      cQuery += " left join fmk.partn on sub2.idpartner=partn.id"
    ENDIF

    cQuery += " left join public.eisporuke on fin_suban.idfirma=eisporuke.fin_idfirma and fin_suban.idvn=eisporuke.fin_idvn and fin_suban.brnal=eisporuke.fin_brnal and fin_suban.rbr=eisporuke.fin_rbr" 
    
    IF cIdKonto == NIL
       cQuery += " where fin_suban.idkonto like  '"  + Trim(cIdKontoKupac) + "%'"
    ELSE
       cQuery += " where fin_suban.idkonto like  '"  + Trim(cIdKonto) + "%'"
    ENDIF

    cQuery += " and fin_suban.datdok >= " + sql_quote(dDatOd) + " and fin_suban.datdok <= " + sql_quote(dDatDo)
    cQuery += " and not fin_suban.idvn in (" + cTmps + ")"
    cQuery += " and COALESCE(substring(fin_suban.opis from 'EISP:\s*(PRESKOCI)'), '')<>'PRESKOCI'"

    /*
        cIdKonto == NIL u slucaju PDV 0%:
        // 04 izvoz
        // 01 isporuke oslobodjenje po ZPDV PDV-a
    */
    IF cIdKonto == NIL
        // konto kupac duguje
        cQuery += " and fin_suban.d_p='1'"
        // NE SMIJE postojati povezan konto 47% sa kupcem
        cQuery += " and sub2.idkonto is null"
    ELSE
        // konto PDV potrazuje
       cQuery += " and fin_suban.d_p='2'"
       IF cMjestoKrajnjePotrosnjeIn == NIL
         // mora postojati partner ako nije definisano mjesto krajnje potrosnje
         cQuery += "  and NOT (sub2.idpartner is null or trim(sub2.idpartner) ='')"
       ENDIF
    ENDIF

    ?E cQuery

    SELECT F_TMP
    IF !use_sql( "EISP",  cQuery + " order by fin_suban.datdok, fin_suban.idfirma, fin_suban.idvn, fin_suban.brnal, fin_suban.rbr")
        RETURN .F.
    ENDIF

    DO WHILE !EOF()

        cMjestoKrajnjePotrosnje := cMjestoKrajnjePotrosnjeIn

        hRec["eisporuke_id"] := nRbr
        hRec["porezni_period"] := cPorezniPeriod
        hRec["br_fakt"] := eisp->brdok
        hRec["dat_fakt"] := eisp->datdok
        hRec["jci"] := eisp->jci

        IF eisp->eisp_rbr <> -99999
            // vec postoji stavka 21% u tabeli eisporuke
            SKIP
            LOOP
        ENDIF

        IF cTipDokumenta == "04"
            IF Empty(eisp->jci)
              skip
              loop
            ENDIF
            
        ENDIF

        IF cTipDokumenta == "04"
            cBrDok := eisp->jci
        else   
           cBrDok := eisp->brdok
        ENDIF

        IF cMjestoKrajnjePotrosnje <> NIL .AND. Empty(eisp->partn_id)
            SWITCH cMjestoKrajnjePotrosnje
                CASE "2" // RS
                   hRec["kup_naz"] := say_string("NEIMENOVANI KUPAC RS", 100, .F.)
                   hRec["kup_sjediste"] := say_string("RS", 100, .F.)
                   EXIT
                CASE "3" // BD
                    hRec["kup_naz"] := say_string("NEIMENOVANI KUPAC BD", 100, .F.)
                    hRec["kup_sjediste"] := say_string("BD", 100, .F.)
                   EXIT
                OTHERWISE
                   // FBiH
                   hRec["kup_naz"] := say_string("NEIMENOVANI KUPAC FBiH", 100, .F.)
                   hRec["kup_sjediste"] := say_string("FBiH", 100, .F.)
                   EXIT     
            ENDSWITCH
            
            IF cTipDokumenta == "02"
               cPDVBroj  := fetch_metric( "fin_enab_my_pdv", NIL, PadR( "<POPUNI>", 12 ) )
               hRec["kup_naz"] := say_string("INTERNA FAKTURA", 100, .F.)
               hRec["kup_sjediste"] := say_string("INTERNA FAKTURA", 100, .F.)
            ELSE
               cPDVBroj := ""  
            ENDIF

            cJib := REPLICATE("9", 13)
            hRec["kup_pdv"] := cPDVBroj
            hRec["kup_jib"] := cJib


        ELSE
           hRec["kup_naz"] := say_string(eisp->partn_naz, 100, .F.)
           hRec["kup_sjediste"] := say_string(trim(eisp->partn_ptt) + " " + trim(eisp->partn_mjesto) + " " + trim(eisp->partn_adresa), 100, .F.)

           cPDVBroj := eisp->pdv_broj
           // 04 - izvoz, lPDVNule - usluge stranih lica
           IF cTipDokumenta == "04" .OR. lPDVNule
                cPDVBroj := REPLICATE("0",12)
           ENDIF
           hRec["kup_pdv"] := cPDVBroj
           cJib := eisp->jib
           IF LEN(TRIM(cJib)) < 13
                cJib := ""
           ENDIF
           hRec["kup_jib"] := cJib
        ENDIF

        IF cMjestoKrajnjePotrosnje == NIL
            // nije definsano mjesto kranje potrosnje

            IF (Empty(cPDVBroj) .AND. Len(cJib) == 13)
               // samo ako je NEPDV obveznik 
               cMjestoKrajnjePotrosnje := eisp->partn_rejon
               IF Empty(cMjestoKrajnjePotrosnje)
                  // FBiH
                  cMjestoKrajnjePotrosnje := "1"
               ENDIF
            ELSE
                // PDV obveznik
                cMjestoKrajnjePotrosnje := "0"
            ENDIF
        ENDIF


        nOsnovicaInterna := 0
        nOsnovicaIzvoz := 0
        nOsnovicaPDV0Oostalo := 0
        nOsnovicaNePdvObveznik := 0
        nOsnovicaDaPdvObveznik := 0
        
        nPDVDaPdvObveznik := 0
        nPDVNePdvObveznik := 0
        nPDVInterna := 0
        
        nInternaSaPDV := 0
        nNePDVObveznikSaPDV := 0
        nDaPDVObveznikSaPDV := 0
        cTipDokumenta2 := cTipDokumenta

        IF lOsnovaNula
            // 4740 - usluge strana lica
            nOsnovicaDaPdvObveznik := 0
            nPDVDaPDVObveznik := eisp->pdv
            nDaPDVObveznikSaPDV := eisp->pdv

        ELSEIF cTipDokumenta == "04" 
            // izvoz
            nOsnovicaIzvoz := eisp->iznos_sa_pdv

        ELSEIF cTipDokumenta <> "04" .AND. ROUND(eisp->pdv, 2) == 0

            // PDV0 ostalo
            cTipDokumenta2 := "05"
            nOsnovicaPDV0Oostalo := eisp->iznos_sa_pdv
        
        ELSEIF cTipDokumenta == "02" .OR. cMjestoKrajnjePotrosnje $ "123"
            
            // 02 - interna faktura vlastita potrosnja
            // (Empty(cPDVBroj) .AND. Len(cJib) == 13) - domaci NE-PDV obveznik 
           

            IF cMjestoKrajnjePotrosnje $ "123" .AND. Empty(eisp->partn_id)
               IF cTipDokumenta == "02"
                  // 4720
                  nPDVInterna := eisp->pdv
                  nOsnovicaInterna := ROUND(nPDVInterna / 0.17, 2)
               ELSE 
                  // 4730, 4731, 4732 bez partnera osnovica se utvrdjuje na osnovu PDV
                  nPDVNePDVObveznik := eisp->pdv
                  nOsnovicaNePdvObveznik := ROUND(nPDVNePDVObveznik / 0.17, 2)
                  nNePDVObveznikSaPDV := nOsnovicaNePdvObveznik + nPDVNePDVObveznik 
               ENDIF
            ELSE

               //u slucaju interne fakture, 4320/PARTNER pdv broj mora biti jednak sopstvenom PDV broju 
               IF cTipDokumenta == "02" .AND. cPDVBroj <> eisp->pdv_broj 
                 Alert("02:INT.FAKT ERR PDV partner<>" + eisp->pdv_broj)
               ENDIF 

               nPDVNePDVObveznik := eisp->pdv
               nOsnovicaNePdvObveznik := eisp->bez_pdv
               nNePDVObveznikSaPDV := eisp->iznos_sa_pdv
               
            ENDIF

        ELSE
            // PDV obveznik
            nPDVDaPDVObveznik := eisp->pdv

            nDaPDVObveznikSaPDV := eisp->iznos_sa_pdv
            nOsnovicaDaPdvObveznik := eisp->bez_pdv
            
            IF ROUND(eisp->from_opis_osn_pdv17, 2) <> -9999999.99
                nOsnovicaDaPDVObveznik := eisp->from_opis_osn_pdv17
            ENDIF
        ENDIF

        n32 := 0
        n33 := 0
        n34 := 0
        IF cTipDokumenta == "02" .OR. cMjestoKrajnjePotrosnje $ "123"
            SWITCH cMjestoKrajnjePotrosnje
                    CASE "2" // RS
                       n33 := eisp->pdv
                       EXIT
                    CASE "3" // BD
                       n34 := eisp->pdv
                       EXIT
                    OTHERWISE
                       // FBiH
                       n32 :=  eisp->pdv
                       EXIT     
            ENDSWITCH

        ENDIF

        hRec["tip"] := cTipDokumenta2

        hRec["fakt_iznos_sa_pdv_interna"] := nOsnovicaInterna + nPDVInterna
        hRec["fakt_iznos_sa_pdv0_izvoz"] := nOsnovicaIzvoz
        hRec["fakt_iznos_sa_pdv0_ostalo"] := nOsnovicaPDV0Oostalo
        
        hRec["fakt_iznos_bez_pdv"] := nOsnovicaDaPDVObveznik
        hRec["fakt_iznos_pdv"] :=  nPDVDaPDVObveznik
        
        hRec["fakt_iznos_bez_pdv_np"] := nOsnovicaNePdvObveznik + nOsnovicaInterna
        hRec["fakt_iznos_pdv_np"] := nPDVNePDVObveznik + nPDVInterna
        
        hRec["fakt_iznos_sa_pdv"] := (nOsnovicaDaPDVObveznik + nPDVDaPDVObveznik) + (nOsnovicaNePdvObveznik + nPDVNePDVObveznik)

        hRec["fakt_iznos_pdv_np_32"] := n32 
        hRec["fakt_iznos_pdv_np_33"] := n33
        hRec["fakt_iznos_pdv_np_34"] := n34
        
        hRec["fin_idfirma"] := eisp->idfirma
        hRec["fin_idvn"] := eisp->idvn
        hRec["fin_brnal"] := eisp->brnal
        hRec["fin_rbr"] := eisp->rbr
        hRec["opis"] := eisp->opis

        IF hRec["kup_jib"] == REPLICATE("9", 13)
            hRec["kup_jib"] := ""
            cJib := ""
        ENDIF
        db_insert_eisp( hRec)


        // Vrsta sloga 2 = slogovi isporuka
        ? "2" + cCSV
        ?? cPorezniPeriod + cCSV
        ?? PADL(AllTrim(STR(nRbr,10,0)), 10, "0") + cCSV
        ?? cTipDokumenta2 + cCSV

        // 5. broj fakture ili dokumenta
        ?? say_string(cBrDok, 100) + cCSV
        // 6. datum fakture ili dokumenta
        ?? STRTRAN(sql_quote(eisp->datdok),"'","") + cCSV
        // 7. naziv kupca
        ?? say_string(hRec["kup_naz"], 100) + cCSV
        // 8. Sjediste kupca
        ?? say_string(hRec["kup_sjediste"], 100) + cCSV
        // 9. PDV dobav
        ??  cPDVBroj + cCSV
        // 10. JIB dobav
        ?? cJib + cCSV

        // 11. iznos sa PDV
        // nije interna vanposlovno NITI izvoz NITI PDV0 po ostalim osnovama
        ?? say_number(hRec["fakt_iznos_sa_pdv"]) + cCSV
        hUkupno["sa_pdv"] += hRec["fakt_iznos_sa_pdv"]

        // 12. iznos interne fakture vanposlovne svrhe
        ?? say_number(hRec["fakt_iznos_sa_pdv_interna"]) + cCSV
        hUkupno["sa_pdv_interna"] += hRec["fakt_iznos_sa_pdv_interna"]
        // 13. iznos izvozne fakture JCI
        ?? say_number(hRec["fakt_iznos_sa_pdv0_izvoz"]) + cCSV
        hUkupno["sa_pdv0_izvoz"] += hRec["fakt_iznos_sa_pdv0_izvoz"]

        // 14. iznos ostale isporuke PDV0
        ?? say_number(hRec["fakt_iznos_sa_pdv0_ostalo"]) + cCSV
        hUkupno["sa_pdv0_ostalo"] += hRec["fakt_iznos_sa_pdv0_ostalo"]

        // 15. osnovica za obracun izvršenu registrovanom obvezniku PDV
        ?? say_number(hRec["fakt_iznos_bez_pdv"]) + cCSV
        hUkupno["bez_pdv_posl"] += hRec["fakt_iznos_bez_pdv"]

        // 16. PDV izvršen registrovanom obvezniku PDV
        ?? say_number(hRec["fakt_iznos_pdv"]) + cCSV
        hUkupno["posl"] += hRec["fakt_iznos_pdv"]

        // 17. osnovica za obracun izvršenu NEregistrovanom obvezniku PDV
        ?? say_number(hRec["fakt_iznos_bez_pdv_np"]) + cCSV
        hUkupno["bez_pdv_np"] += hRec["fakt_iznos_bez_pdv_np"]

        // 18. PDV izvršen NEregistrovanom obvezniku PDV
        ?? say_number(hRec["fakt_iznos_pdv_np"]) + cCSV
        hUkupno["np"] += hRec["fakt_iznos_pdv_np"]

        hUkupno["np_32"] += n32
        hUkupno["np_33"] += n33
        hUkupno["np_34"] += n34

        // 19. iznos izlaznog PDV-a koji si unosi u polje 32 PDV FBiH
        ?? say_number(n32) + cCSV
        // 20.  iznos izlaznog PDV-a koji si unosi u polje 33 PDV RS
        ?? say_number(n33) + cCSV
        // 21.  iznos izlaznog PDV-a koji si unosi u polje 34 PDV Brcko
        ?? say_number(n34)

        hUkupno["redova"] += 1
        nRbr ++

        SKIP
    ENDDO

    USE

    RETURN .T.



/*

 -- 4321 - dobavljaci nepdv obveznici, ili fakture PDV0  4320 - ali u opisu ima PDV0 (isporukka dobrara i usluge na koje se ne obracunava pdv)
   select get_sifk('PARTN', 'PDVB', idpartner) as pdv_broj, get_sifk('PARTN', 'IDBR', idpartner) as jib,  
        (case when d_p='2' then 1 else -1 end) * iznosbhd as iznos,
        fin_suban.idkonto, partn.id, partn.naz, idkonto, fin_suban.* from fmk.fin_suban 
   left join fmk.partn on fin_suban.idpartner=partn.id
   where (trim(fin_suban.idkonto) = '4321' or (trim(fin_suban.idkonto) = '4320' and opis like '%PDV0%' )) and 
         fin_suban.datdok >= '2020-10-01' and fin_suban.datdok <= '2020-10-31' 
        and not fin_suban.idvn in ('PD','IB', 'B1', 'B2', 'B3');


Ovaj upit je bolji:

 -- 4321 - dobavljaci nepdv obveznici, ili fakture PDV0  4320 - ali u opisu ima PDV0 (isporukka dobrara i usluge na koje se ne obracunava pdv)
select get_sifk('PARTN', 'PDVB', fin_suban.idpartner) as pdv_broj, get_sifk('PARTN', 'IDBR', fin_suban.idpartner) as jib,  
        (case when fin_suban.d_p='2' then 1 else -1 end) * fin_suban.iznosbhd as iznos,
        fin_suban.idkonto, partn.id, partn.naz, fin_suban.idkonto, sub2.idkonto as idkonto2
   from fmk.fin_suban 
   left join fmk.partn on fin_suban.idpartner=partn.id
   left join fmk.fin_suban sub2 on fin_suban.brdok=sub2.brdok and fin_suban.idfirma=sub2.idfirma and fin_suban.idvn=sub2.idvn and fin_suban.brnal=sub2.brnal and (sub2.idkonto like '27%' or sub2.idkonto like '5559%')
   where trim(fin_suban.idkonto) like '432%' and 
         fin_suban.datdok >= '2020-10-01' and fin_suban.datdok <= '2020-10-31'
         and sub2.idkonto is null
        and not fin_suban.idvn in ('PD','IB', 'B1', 'B2', 'B3');

STATIC FUNCTION gen_isporuke_stavke_pdv0(nRbr, dDatOd, dDatDo, cPorezniPeriod, cTipDokumenta, cPDVNPExclude, cNabExcludeIdvn, lPDVNule, hUkupno )

    LOCAL cSelectFields, cBrDokFinFin2, cFinNalogNalog2, cLeftJoinFin2
    LOCAL cQuery, cTmps
    LOCAL cCSV := ";"
    LOCAL n32, n33, n34
    LOCAL cPDVBroj, cJib
    LOCAL nPDVNP, nPDVPosl
    LOCAL hRec := hb_hash()

    
    cTmps := get_sql_expression_exclude_idvns(cNabExcludeIdvn)

    cSelectFields := "SELECT get_sifk('PARTN', 'PDVB', fin_suban.idpartner) as pdv_broj, get_sifk('PARTN', 'IDBR', fin_suban.idpartner) as jib,"
    cSelectFields += "(case when fin_suban.d_p='2' then 1 else -1 end) * fin_suban.iznosbhd as iznos,"
    cSelectFields += "fin_suban.idkonto as idkonto, partn.id, partn.naz, partn.adresa, fin_suban.idfirma, fin_suban.idvn, fin_suban.brnal,fin_suban.rbr,"
    cSelectFields += "fin_suban.brdok, fin_suban.opis, fin_suban.d_p, fin_suban.datdok, fin_suban.datval,"
    cSelectFields += "partn.id as partn_id, partn.naz as partn_naz, partn.adresa as partn_adresa, partn.ptt as partn_ptt, partn.mjesto as partn_mjesto, partn.rejon partn_rejon"
    
    cBrDokFinFin2 := "fin_suban.brdok=sub2.brdok"
    cFinNalogNalog2 := "fin_suban.idfirma=sub2.idfirma and fin_suban.idvn=sub2.idvn and fin_suban.brnal=sub2.brnal"
    // ovdje fin_suban 43% konto povezujemo sa sub2.idkonto 27%/5559% i ocekujemo DA NEMA VEZE - da ne postoji uparen konto PDV-a ! 
    cLeftJoinFin2 := " left join fmk.fin_suban sub2 on " + cFinNalogNalog2 + " and " + cBrDokFinFin2 
    cLeftJoinFin2 += "  and (sub2.idkonto like '27%' or sub2.idkonto like '" + trim( cPDVNPExclude) + "%')"

    cQuery := cSelectFields
    cQuery += " from fmk.fin_suban "
    cQuery += " left join fmk.partn on fin_suban.idpartner=partn.id"
    cQuery += cLeftJoinFin2
    cQuery += " where fin_suban.datdok >= " + sql_quote(dDatOd) + " and fin_suban.datdok <= " + sql_quote(dDatDo)
    cQuery += " and not fin_suban.idvn in (" + cTmps + ")"
    cQuery += " and sub2.idkonto is null"
    cQuery += " and trim(fin_suban.idkonto) like '432%'"
    // or (trim(fin_suban.idkonto) = '4320' and opis like '%PDV0%' )) and 
 

    IF !use_sql( "ENAB",  cQuery + " order by fin_suban.datdok, fin_suban.idfirma, fin_suban.idvn, fin_suban.brnal, fin_suban.rbr")
        RETURN .F.
    ENDIF
        
    DO WHILE !EOF()


        hRec["enabavke_id"] := nRbr
        hRec["tip"] := cTipDokumenta
        hRec["porezni_period"] := cPorezniPeriod
        hRec["br_fakt"] := eisp->brdok
        hRec["dat_fakt"] := eisp->datdok
        hRec["dat_fakt_prijem"] := eisp->datdok
        hRec["dob_naz"] := say_string(eisp->partn_naz, 100, .F.)
        hRec["dob_sjediste"] := say_string(trim(eisp->partn_ptt) + " " + trim(eisp->partn_mjesto) + " " + trim(eisp->partn_adresa), 100, .F.)

        cPDVBroj := eisp->pdv_broj 
        // uvoz
        IF cTipDokumenta == "04" .OR. lPDVNule
            cPDVBroj := REPLICATE("0",12)
        ENDIF
        hRec["dob_pdv"] := cPDVBroj
        cJib := eisp->jib
        IF LEN(TRIM(cJib)) < 13
            cJib := ""
        ENDIF
        hRec["dob_jib"] := cJib

        nPDVPosl := 0
        nPDVNP := 0
        n32 := 0
        n33 := 0
        n34 := 0

        hRec["fakt_iznos_bez_pdv"] := eisp->iznos
        hRec["fakt_iznos_sa_pdv"] := eisp->iznos
        hRec["fakt_iznos_poljo_pausal"] := 0

        hRec["fakt_iznos_pdv"] := nPDVPosl
        hRec["fakt_iznos_pdv_np"] := nPDVNP
        hRec["fakt_iznos_pdv_np_32"] := n32 
        hRec["fakt_iznos_pdv_np_33"] := n33
        hRec["fakt_iznos_pdv_np_34"] := n34
        hRec["fin_idfirma"] := eisp->idfirma
        hRec["fin_idvn"] := eisp->idvn
        hRec["fin_brnal"] := eisp->brnal
        hRec["fin_rbr"] := eisp->rbr
        hRec["opis"] := eisp->opis
        db_insert_enab( hRec)

        // Vrsta sloga 2 = slogovi nabavki
        ? "2" + cCSV
        ?? cPorezniPeriod + cCSV
        ?? PADL(AllTrim(STR(nRbr, 10, 0)), 10, "0") + cCSV
        ?? cTipDokumenta + cCSV
        // 5. broj fakture ili dokumenta
        ?? say_string(eisp->brdok, 100) + cCSV
        // 6. datum fakture ili dokumenta
        ?? STRTRAN(sql_quote(eisp->datdok),"'","") + cCSV
        // 7. datum prijema
        ?? STRTRAN(sql_quote(eisp->datdok),"'","") + cCSV
        // 8. naziv dobavljaca
        ?? say_string(eisp->partn_naz, 100) + cCSV
        // Sjediste dobavljaca
        ?? say_string(trim(eisp->partn_ptt) + " " + trim(eisp->partn_mjesto) + " " + trim(eisp->partn_adresa), 100) + cCSV

      
        // 10. PDV dobav
        ??  cPDVBroj + cCSV
        // 11. JIB dobav
        ?? cJib + cCSV
        // 12. bez PDV
        ?? say_number(eisp->iznos) + cCSV
        hUkupno["bez"] += eisp->iznos

        // 13. sa PDV
        ?? say_number(eisp->iznos) + cCSV
        hUkupno["sa_pdv"] += eisp->iznos

        // 14. pausalna naknada
        ?? say_number(0) + cCSV
        hUkupno["paus"] += 0

        
        hUkupno["np"] += nPDVNP
        hUkupno["posl"] += nPDVPosl

        // 15. ulazni pdv 
        ?? say_number(nPDVPosl + nPDVNP) + cCSV
        
        // 16. ulazni PDV koji se moze odbiti
        ?? say_number(nPDVPosl) + cCSV
 
        // 17. ulazni PDV koji se ne moze odbiti
        ?? say_number(nPDVNP) + cCSV
        
        hUkupno["np_32"] += n32
        hUkupno["np_33"] += n33
        hUkupno["np_34"] += n34

        // 17. ulazni PDV koji se ne moze odbiti, ulazi u polje 32 PDV FBiH
        ?? say_number(n32) + cCSV
        // 17. ulazni PDV koji se ne moze odbiti, ulazi u polje 33 PDV RS
        ?? say_number(n33) + cCSV
        // 17. ulazni PDV koji se ne moze odbiti, ulazi u polje 34 PDV Brcko
        ?? say_number(n34)

        hUkupno["redova"] += 1
        nRbr++

        SKIP
    ENDDO

    USE

    RETURN .T.
*/



FUNCTION gen_eIsporuke()
    
    LOCAL nX := 1
    LOCAL cIdKontoPDV := PadR( fetch_metric( "fin_eisp_idkonto_pdv", NIL, "470" ), 7 )
    LOCAL cIdKontoPDVAvansi := PadR( fetch_metric( "fin_eisp_idkonto_pdv_a", NIL, "471" ), 7 )
    LOCAL cIdKontoPDVInterne := PadR( fetch_metric( "fin_eisp_idkonto_pdv_int", NIL, "472" ), 7 )

    LOCAL cIdKontoPDVNeFBiH := trim( fetch_metric( "fin_eisp_idkonto_pdv_nepdv_1", NIL, "4730" ))
    LOCAL cIdKontoPDVNeRS := trim( fetch_metric( "fin_eisp_idkonto_pdv_nepdv_2", NIL, "4731" ))
    LOCAL cIdKontoPDVNeBD := trim( fetch_metric( "fin_eisp_idkonto_pdv_nepdv_3", NIL, "4732" ))

    LOCAL cIdKontoPDVUslugeStranaLica := PadR( fetch_metric( "fin_eisp_idkonto_pdv_ust", NIL, "474" ), 7 )
    LOCAL cIdKontoPDVSchema := PadR( fetch_metric( "fin_eisp_idkonto_pdv_schema", NIL, "475" ), 7 )
    LOCAL cIdKontoPDVOstalo := PadR( fetch_metric( "fin_eisp_idkonto_pdv_ostalo", NIL, "478" ), 7 )
    LOCAL cNabExcludeIdvn := PadR( fetch_metric( "fin_enab_idvn_exclude", NIL, "I1,I2,IB,B1,B2,B3,PD" ), 100 )


    LOCAL cPDV  := fetch_metric( "fin_enab_my_pdv", NIL, PadR( "<POPUNI>", 12 ) )
    LOCAL dDatOd := fetch_metric( "fin_enab_dat_od", my_user(), DATE()-1 )
    LOCAL dDatDo := fetch_metric( "fin_enab_dat_do", my_user(), DATE() )
    LOCAL cExportFile, nFileNo
    LOCAL cCSV := ";"
    LOCAL cPorezniPeriod
    LOCAL hUkupno := hb_hash()
    LOCAL nRbr := 0
    LOCAL nRbr2 := 0
    LOCAL cBrisatiDN := "N"
    LOCAL nCnt
    LOCAL oError

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

        SELECT F_TMP
        IF !use_sql( "EISP", "select max(eisporuke_id) as max from public.eisporuke where porezni_period<>" + sql_quote(cPorezniPeriod))
            MsgBeep("eisporuke sql tabela nedostupna?!")
            BoxC()
            RETURN .F.
        ENDIF
        nRbr := eisp->max + 1
        USE
        SELECT F_TMP
        BEGIN SEQUENCE WITH {| err| Break( err ) }
            use_sql( "EISP", "select max(g_r_br) as max from fmk.epdv_kif")
            nRbr2 := enab->max + 1
            USE
        RECOVER USING oError
        END SEQUENCE

        nRbr := Round(Max(nRbr, nRbr2), 0)
        
        @ box_x_koord() + nX++, box_y_koord() + 2 SAY " brisati period " + cPorezniPeriod +" pa ponovo generisati?:" GET cBrisatiDN PICT "@!" VALID cBrisatiDN $ "DN"
        @ box_x_koord() + nX++, box_y_koord() + 2 SAY "Redni broj naredne eIsporuke:" GET nRbr PICT 99999
        READ
    BoxC()

    IF Lastkey() == K_ESC
        RETURN .F.
     ENDIF
     
    set_metric( "fin_enab_my_pdv", NIL, cPDV )
    set_metric( "fin_enab_dat_od", my_user(), dDatOd )
    set_metric( "fin_enab_dat_do", my_user(), dDatDo )

    IF DirChange( cLokacijaExport ) != 0
           nCreate := MakeDir ( cLokacijaExport )
           IF nCreate != 0
              MsgBeep( "kreiranje " + cLokacijaExport + " neuspješno ?!" )
              log_write( "dircreate err:" + cLokacijaExport, 6 )
              RETURN .F.
           ENDIF
    ENDIF

    IF cBrisatiDN == "D"
        run_sql_query("DELETE from public.eisporuke where porezni_period=" + sql_quote(cPorezniPeriod))
        nCnt := table_count( "public.eisporuke", "porezni_period=" + sql_quote(cPorezniPeriod))
        IF nCnt > 0
            MsgBeep("Za porezni period " + cPorezniPeriod + " postoje zapisi?!##STOP")
        RETURN .F.
        ENDIF
    ENDIF

    DirChange( cLokacijaExport )
    info_bar( "csv", "lokacija csv: " + cLokacijaExport )
    
    cExportFile := cPDV + "_"

 
    cExPortFile += cPorezniPeriod
    
    cExportFile += "_2_" 

    nFileNo := 1
    cExPortFile += PADL( AllTrim(STR(nFileNo, 2)), 2, "0")
    cExportFile += ".csv"

    info_bar( "csv", "kreiranje: " + cExportFile )

    create_csv( cExportFile )
    // slog zaglavlja
    // 1. vrsta sloga
    ?? "1" + cCSV
    // 2. PDV broj
    ?? cPDV + cCSV
    // 3. YYMM
    ?? cPorezniPeriod + cCSV
    // 4. tip datoteke - 2 isporuke
    ?? "2" + cCSV
    // 5. redni broj datoteke
    ?? PADL( AllTrim(STR(nFileNo, 2)), 2, "0") + cCSV
    // 6. datum kreiranja YYY-MM-YY
    ?? STRTRAN(sql_quote(date()),"'","") + cCSV
    // 7. vrijeme
    ?? Time()


    hUkupno["sa_pdv"] := 0
    hUkupno["sa_pdv_interna"] := 0
    hUkupno["sa_pdv0_izvoz"] := 0
    hUkupno["sa_pdv0_ostalo"] := 0

    hUkupno["bez_pdv_posl"] := 0
    hUkupno["posl"] := 0

    hUkupno["bez_pdv_np"] := 0
    hUkupno["np"] := 0

    hUkupno["np_32"] := 0
    hUkupno["np_33"] := 0
    hUkupno["np_34"] := 0
    hUkupno["redova"] := 0

    // 01 standardne isporuke 4700  ; lPDVNule .F. (koristi se kod 4740 - usluge stranih lica), 
    //                                lOsnovaNula .F. (koristi se kod 4740 - usluge stranih lica), cMjestoKrajnjePotrosnje NIL
    gen_eisporuke_stavke(@nRbr, dDatOd, dDatDo, cPorezniPeriod, "01", cIdKontoPDV, cNabExcludeIdvn, .F., .F., NIL, @hUkupno)


    // 01 standardne isporuke 4730 - ne PDV obveznici krajnja potrosnja; ; lPDVNule .F., lOsnovaNula .F., 
    // cMjestoKrajnjePotrosnje="1" FBiH
    gen_eisporuke_stavke(@nRbr, dDatOd, dDatDo, cPorezniPeriod, "01", cIdKontoPDVNeFBiH, cNabExcludeIdvn, .F., .F., "1", @hUkupno)

    // 01 standardne isporuke 4731 - ne PDV obveznici krajnja potrosnja; ; lPDVNule .F., lOsnovaNula .F., 
    // cMjestoKrajnjePotrosnje="2" RS
    gen_eisporuke_stavke(@nRbr, dDatOd, dDatDo, cPorezniPeriod, "01", cIdKontoPDVNeRS, cNabExcludeIdvn, .F., .F., "2", @hUkupno)

    // 01 standardne isporuke 4732 - ne PDV obveznici krajnja potrosnja; ; lPDVNule .F., lOsnovaNula .F.,
    // cMjestoKrajnjePotrosnje="3" BD
    gen_eisporuke_stavke(@nRbr, dDatOd, dDatDo, cPorezniPeriod, "01", cIdKontoPDVNeBD, cNabExcludeIdvn, .F., .F., "3", @hUkupno)
    
    // 02 interne fakture - sopstvena krajnja potrosnja; ; lPDVNule .F., lOsnovaNula .F., 
    // cMjestoKrajnjePotrosnje="1" sopstvena krajnja potrosnja je uvijek FBiH
    gen_eisporuke_stavke(@nRbr, dDatOd, dDatDo, cPorezniPeriod, "02", cIdKontoPDVInterne, cNabExcludeIdvn, .F., .F., "1", @hUkupno)

    // 05 ostale isporuke - usluge stranih lica 4740, lPDVNule = .T., lOsnovaNula = .T.
    gen_eisporuke_stavke(@nRbr, dDatOd, dDatDo, cPorezniPeriod, "05", cIdKontoPDVUslugeStranaLica, cNabExcludeIdvn, .T., .T., NIL, @hUkupno)
  
    // 01 standardne isporuke, 4750 - po posebnoj shemi
    gen_eisporuke_stavke(@nRbr, dDatOd, dDatDo, cPorezniPeriod, "01", cIdKontoPDVSchema, cNabExcludeIdvn, .F., .F., NIL, @hUkupno)

    // 04 izvoz
    gen_eisporuke_stavke(@nRbr, dDatOd, dDatDo, cPorezniPeriod, "04", NIL, cNabExcludeIdvn, .F., .F., NIL, @hUkupno)

    // 01 isporuke oslobodjenje po ZPDV PDV-a
    gen_eisporuke_stavke(@nRbr, dDatOd, dDatDo, cPorezniPeriod, "01", NIL, cNabExcludeIdvn, .F., .F., NIL, @hUkupno)

    // 03 primljeni avansi
    gen_eisporuke_stavke(@nRbr, dDatOd, dDatDo, cPorezniPeriod, "03", cIdKontoPDVAvansi, cNabExcludeIdvn, .F., .F., NIL, @hUkupno)

    // 01 PDV ostalo 4780 (npr. knjizna odobrenja kupcima)
    gen_eisporuke_stavke(@nRbr, dDatOd, dDatDo, cPorezniPeriod, "01", cIdKontoPDVOstalo, cNabExcludeIdvn, .F., .F., NIL, @hUkupno)


    // 1. 3 - prateći slog
    ? "3" + cCSV
    // 2. ukupan iznos fakture
    ?? say_number( hUkupno["sa_pdv"] ) + cCSV
    // 3. ukupan iznos interne fakture u vanposlovne svrhe
    ?? say_number( hUkupno["sa_pdv_interna"] ) + cCSV
    // 4. ukupan iznos fakture za izvozne isporuke
    ?? say_number( hUkupno["sa_pdv0_izvoz"] ) + cCSV
    // 5. ukupan iznos fakture za ostale isporuke oslobodjene PDV
    ?? say_number( hUkupno["sa_pdv0_ostalo"] ) + cCSV

    // 6. ukupna osnovica za obracun PDV za isporuku izvrsenu registrovanom obvezniku PDV-a
    ?? say_number( hUkupno["bez_pdv_posl"] ) + cCSV
    // 7. ukupan iznos izlaznog PDV za isporuku izvrsenu registrovanom obvezniku PDV-a
    ?? say_number( hUkupno["posl"] ) + cCSV

    // 8. ukupna osnovica za obracun PDV za isporuku izvrsenu NEregistrovanom obvezniku PDV-a
    ?? say_number( hUkupno["bez_pdv_np"] ) + cCSV
    // 9. ukupan iznos izlaznog PDV za isporuku izvrsenu NEregistrovanom obvezniku PDV-a
    ?? say_number( hUkupno["np"] ) + cCSV


    // 10. ukupan izlazni PDV koji se ne moze odbiti 32 PDV prijava
    ?? say_number( hUkupno["np_32"] ) + cCSV
    // 11. ukupan izlazni PDV koji se ne moze odbiti 33 PDV prijava
    ?? say_number( hUkupno["np_33"] ) + cCSV
    // 12. ukupan izlazni PDV koji se ne moze odbiti 34 PDV prijava
    ?? say_number( hUkupno["np_34"] ) + cCSV
    // 13. ukupan broj redova (sirine 10)
    ?? AllTrim(Str(hUkupno["redova"] ))


    close_csv()
       
    DirChange( my_home() )
     
  
    f18_copy_to_desktop( cLokacijaExport, cExportFile, cExportFile )
     

    RETURN .T.
       
    
    

STATIC FUNCTION xlsx_export_fill_row()

    LOCAL nI
    LOCAL aKolona

    
    aKolona := {}
    AADD(aKolona, { "N", "Rbr. isporuke", 10, eisp->eisporuke_id })
    AADD(aKolona, { "C", "Tip", 3, eisp->tip })

    
    AADD(aKolona, { "C", "Por.Per", 8, eisp->porezni_period })
    AADD(aKolona, { "C", "Br.Fakt", 20, eisp->br_fakt })
    AADD(aKolona, { "C", "JCI", 10, eisp->jci })
    AADD(aKolona, { "D", "Dat.fakt", 12, eisp->dat_fakt })

    AADD(aKolona, { "C", "Kupac naziv", 60, eisp->kup_naz })
    AADD(aKolona, { "C", "Kupac sjediste", 100, eisp->kup_sjediste })
    AADD(aKolona, { "C", "Kup. PDV", 12, eisp->kup_pdv })
    AADD(aKolona, { "C", "Kup. JIB", 13, eisp->kup_jib })

    AADD(aKolona, { "M", "Fakt.SA PDV", 15, eisp->fakt_iznos_sa_pdv })
    AADD(aKolona, { "M", "F.SA PDV interna", 15, eisp->fakt_iznos_sa_pdv_interna })
    AADD(aKolona, { "M", "Fakt izvoz", 15, eisp->fakt_iznos_sa_pdv0_izvoz })
    AADD(aKolona, { "M", "Fakt PDV0 ostalo", 15, eisp->fakt_iznos_sa_pdv0_ostalo })

    AADD(aKolona, { "M", "F.bez PDV", 15, eisp->fakt_iznos_bez_pdv })
    AADD(aKolona, { "M", "F. PDV", 15, eisp->fakt_iznos_pdv })

    AADD(aKolona, { "M", "F.bez PDV NP", 15, eisp->fakt_iznos_bez_pdv_np })
    AADD(aKolona, { "M", "F. PDV NP", 15, eisp->fakt_iznos_pdv_np })

    AADD(aKolona, { "M", "PDV neposl 32", 15, eisp->fakt_iznos_pdv_np_32 })
    AADD(aKolona, { "M", "PDV neposl 33", 15, eisp->fakt_iznos_pdv_np_33 })
    AADD(aKolona, { "M", "PDV neposl 34", 15, eisp->fakt_iznos_pdv_np_34 })
    AADD(aKolona, { "C", "Opis", 200, eisp->opis })
    AADD(aKolona, { "C", "FIN nalog", 20, eisp->fin_idfirma + "-" + eisp->fin_idvn + "-" + eisp->fin_brnal + "/" + Alltrim(Str(eisp->fin_rbr)) })

    
    IF s_pWorkSheet == NIL
        
        s_pWorkBook := workbook_new( s_cXlsxName )
        s_pWorkSheet := workbook_add_worksheet(s_pWorkBook, NIL)
    
        s_pMoneyFormat := workbook_add_format(s_pWorkBook)
        format_set_num_format(s_pMoneyFormat, /*"#,##0"*/ "#0.00" )
    
        s_pDateFormat := workbook_add_format(s_pWorkBook)
        format_set_num_format(s_pDateFormat, "d.mm.yy")
        
        
        /* Set the column width. */
        for nI := 1 TO LEN(aKolona)
            // worksheet_set_column(lxw_worksheet *self, lxw_col_t firstcol, lxw_col_t lastcol, double width, lxw_format *format)
            worksheet_set_column(s_pWorkSheet, nI - 1, nI - 1, aKolona[ nI, 3], NIL)
        next
    
    
        //nema smisla header kada imamo vise konta ili vise partnera
        //worksheet_write_string( s_pWorkSheet, 0, 0,  "Konto:", NIL)
        //worksheet_write_string( s_pWorkSheet, 0, 1,  hb_StrToUtf8(cIdKonto + " - " + Trim( cKontoNaziv)), NIL)
        //worksheet_write_string( s_pWorkSheet, 1, 0,  "Partner:", NIL)
        //worksheet_write_string( s_pWorkSheet, 1, 1,  hb_StrToUtf8(cIdPartner + " - " + Trim(cPartnerNaziv)), NIL)
        
        /* Set header */
        s_nWorkSheetRow := 0
        for nI := 1 TO LEN(aKolona)
            worksheet_write_string( s_pWorkSheet, s_nWorkSheetRow, nI - 1,  aKolona[nI, 2], NIL)
        next
        
    ENDIF
    
    
    s_nWorkSheetRow++
    
    FOR nI := 1 TO LEN(aKolona)
            IF aKolona[ nI, 1 ] == "C"
                worksheet_write_string( s_pWorkSheet, s_nWorkSheetRow, nI - 1,  hb_StrToUtf8(aKolona[nI, 4]), NIL)
            ELSEIF aKolona[ nI, 1 ] == "M"
                worksheet_write_number( s_pWorkSheet, s_nWorkSheetRow, nI - 1,  aKolona[nI, 4], s_pMoneyFormat)
            ELSEIF aKolona[ nI, 1 ] == "N"
                worksheet_write_number( s_pWorkSheet, s_nWorkSheetRow, nI - 1,  aKolona[nI, 4], NIL)
            ELSEIF aKolona[ nI, 1 ] == "D"
                worksheet_write_datetime( s_pWorkSheet, s_nWorkSheetRow, nI - 1,  aKolona[nI, 4], s_pDateFormat)
            ENDIF
    NEXT
            
    RETURN .T.
     

        

FUNCTION export_eIsporuke()


    LOCAL dDatOd := fetch_metric( "fin_enab_dat_od", my_user(), DATE()-1 )
    LOCAL dDatDo := fetch_metric( "fin_enab_dat_do", my_user(), DATE() )
    LOCAL nX
    LOCAL GetList := {}
    LOCAL cQuery
 
    nX := 1
    Box(, 6, 70 )
        @ box_x_koord() + nX, box_y_koord() + 2 SAY "Za period od:" GET dDatOd
        @ box_x_koord() + nX++, col() + 2 SAY "Za period od:" GET dDatDo
        READ   
    BoxC()

    IF Lastkey() == K_ESC
       RETURN .F.
    ENDIF
    s_cXlsxName := my_home_root() + "eisporuke_" + dtos(dDatOd) + "_" + dtos(dDatDo) + ".xlsx"

    cQuery := "select * from public.eisporuke where dat_fakt >=" + sql_quote(dDatOd) + " AND dat_fakt <=" + sql_quote(dDatDo)
    cQuery += " ORDER BY eisporuke_id"

    SELECT F_TMP

    use_sql("EISP", cQuery)

    IF reccount() == 0
        Alert("EISP - nema podataka za period " + DTOC(dDatOd) + "-" + DTOC(dDatDo))
        RETURN .F.
    ENDIF

    DO WHILE !EOF()
      xlsx_export_fill_row()
      SKIP
    ENDDO
    USE

    my_close_all_dbf()
    workbook_close( s_pWorkBook )
    s_pWorkBook := NIL
    s_pWorkSheet := NIL
    f18_open_mime_document( s_cXlsxName )
    
    RETURN .T.


/*
     partn_nepdv( cPartnerId ) =>

     "0" - PDV obveznik

     "1" - NE-PDV obveznik FBiH
     "2" - NE-PDV obveznik RS
     "3" - NE-PDV obveznik BD
*/
FUNCTION partn_nepdv( cPartnerId )

    LOCAL cPDV := get_partn_pdvb( cPartnerId )
    LOCAL cJib := get_partn_idbr( cPartnerId )
     
    IF LEN(cJib) == 13 .AND. LEN(cPDV) == 0
        // NEPDV obveznik
        select_o_partner( cPartnerId )
           SWITCH partn->rejon
            CASE "2"
               // RS 
               RETURN "2"
            CASE "3"
               // BD
               RETURN "3"
            otherwise
               // FBiH
               RETURN "1"
            ENDSWITCH
    ENDIF
        
    // PDV obveznik
    RETURN "0"