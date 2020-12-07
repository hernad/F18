#include "f18.ch"

MEMVAR gBrojacKalkulacija

STATIC s_cXlsxName := NIL
STATIC s_pWorkBook, s_pWorkSheet, s_nWorkSheetRow
STATIC s_pMoneyFormat, s_pDateFormat

FUNCTION parametri_eNabavke

    LOCAL nX := 1
    LOCAL GetList := {}

    LOCAL cIdKontoDobav := PadR( fetch_metric( "fin_enab_idkonto_dob", NIL, "43" ), 7 )
    
    LOCAL cIdKontoPDV := PadR( fetch_metric( "fin_enab_idkonto_pdv", NIL, "270" ), 7 )
    LOCAL cIdKontoPDVNP := PadR( fetch_metric( "fin_enab_idkonto_pdv_np", NIL, "27690" ), 7 )

    LOCAL cIdKontoPDVUvoz := PadR( fetch_metric( "fin_enab_idkonto_pdv_u", NIL, "271" ), 7 )
    LOCAL cIdKontoPDVUvozNP := PadR( fetch_metric( "fin_enab_idkonto_pdv_u_np", NIL, "27691" ), 7 )

    LOCAL cIdKontoPDVAvansi := PadR( fetch_metric( "fin_enab_idkonto_pdv_a", NIL, "272" ), 7 )
    LOCAL cIdKontoPDVAvansiNP := PadR( fetch_metric( "fin_enab_idkonto_pdv_a_np", NIL, "27692" ), 7 )

    LOCAL cIdKontoPDVUslugeStranaLica := PadR( fetch_metric( "fin_enab_idkonto_pdv_ust", NIL, "273" ), 7 )
    LOCAL cIdKontoPDVUslugeStranaLicaNP := PadR( fetch_metric( "fin_enab_idkonto_pdv_ust_np", NIL, "27693" ), 7 )

    LOCAL cIdKontoPDVPolj := PadR( fetch_metric( "fin_enab_idkonto_pdv_p", NIL, "274" ), 7 )
    LOCAL cIdKontoPDVPoljNP := PadR( fetch_metric( "fin_enab_idkonto_pdv_p_np", NIL, "27694" ), 7 )

    LOCAL cIdKontoPDVSchema := PadR( fetch_metric( "fin_enab_idkonto_pdv_schema", NIL, "275" ), 7 )
    LOCAL cIdKontoPDVSchemaNP := PadR( fetch_metric( "fin_enab_idkonto_pdv_schema_np", NIL, "27695" ), 7 )

    LOCAL cIdKontoPDVOstalo := PadR( fetch_metric( "fin_enab_idkonto_pdv_ostalo", NIL, "278" ), 7 )
    LOCAL cIdKontoPDVOstaloNP := PadR( fetch_metric( "fin_enab_idkonto_pdv_ostalo_np", NIL, "27698" ), 7 )

    LOCAL cNabExcludeIdvn := PadR( fetch_metric( "fin_enab_idvn_exclude", NIL, "I1,I2,IB,B1,B2,B3,PD" ), 100 )
    LOCAL cNabIdvn05 := PadR( fetch_metric( "fin_enab_idvn_05", NIL, "05,06,07" ), 100 )

    LOCAL cEnabUvozSwitchKALK := PadR( fetch_metric( "fin_enab_uvoz_switch_kalk", NIL, "N" ), 1 )

    Box(, 17, 80 )

       @ box_x_koord() + nX++, box_y_koord() + 2 SAY "***** eIsporuke PARAMETRI *****"
       @ box_x_koord() + nX++, box_y_koord() + 2 SAY8 "Konto klasa dobavljaci        " GET cIdKontoDobav
       nX++
       @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Konto PDV domaci posl. svrhe  " GET cIdKontoPDV VALID P_Konto(@cIdKontoPDV)
       @ box_x_koord() + nX++, col() + 2 SAY8 "Konto PDV domaci VANPOSLOVNE  " GET cIdKontoPDVNP VALID P_Konto(@cIdKontoPDVNP)

       @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Konto PDV uvoz                " GET cIdKontoPDVUvoz VALID P_Konto(@cIdKontoPDVUvoz)
       @ box_x_koord() + nX++, col() + 2 SAY8 "Konto PDV uvoz VANPOSLOVNO    " GET cIdKontoPDVUvozNP VALID P_Konto(@cIdKontoPDVUvozNP)

       @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Konto PDV dati avansi         " GET cIdKontoPDVAvansi VALID P_Konto(@cIdKontoPDVAvansi)
       @ box_x_koord() + nX++, col() + 2 SAY8 "Konto PDV dati avansi VANPOSL " GET cIdKontoPDVAvansiNP VALID P_Konto(@cIdKontoPDVAvansiNP)

       @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Konto PDV usluge strana lica  " GET cIdKontoPDVUslugeStranaLica VALID P_Konto(@cIdKontoPDVUslugeStranaLica)
       @ box_x_koord() + nX++, col() + 2 SAY8 "usluge strana lica VANPOSL    " GET cIdKontoPDVUslugeStranaLicaNP VALID P_Konto(@cIdKontoPDVUslugeStranaLicaNP)

       @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Konto PDV paušal poljoprivr.  " GET cIdKontoPDVPolj VALID P_Konto(@cIdKontoPDVPolj)
       @ box_x_koord() + nX++, col() + 2 SAY8 "paušal poljoprivr. VANPOSL    " GET cIdKontoPDVPoljNP VALID P_Konto(@cIdKontoPDVPoljNP)

       @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Konto PDV posebna schema      " GET cIdKontoPDVSchema VALID P_Konto(@cIdKontoPDVSchema)
       @ box_x_koord() + nX++, col() + 2 SAY8 "posebna schema VANPOSL        " GET cIdKontoPDVSchemaNP VALID P_Konto(@cIdKontoPDVSchemaNP)

       @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Konto PDV ostalo              " GET cIdKontoPDVOstalo VALID P_Konto(@cIdKontoPDVOstalo)
       @ box_x_koord() + nX++, col() + 2 SAY8 "Konto PDV ostalo VANPOSL      " GET cIdKontoPDVOstaloNP VALID P_Konto(@cIdKontoPDVOstaloNP)


       nX++
       @ box_x_koord() + nX++, box_y_koord() + 2 SAY8 "FIN nalozi koji su isključuju iz generacije e-nabavki"
       @ box_x_koord() + nX++, box_y_koord() + 2 SAY8 "(blagajna, izvodi, obračun PDV)" GET cNabExcludeIdvn PICTURE "@S35" 


       @ box_x_koord() + nX++, box_y_koord() + 2 SAY8 "FIN nalozi koji odredjuju ostale e-nabavke"
       @ box_x_koord() + nX++, box_y_koord() + 2 SAY8 "(tip 05)" GET cNabIdvn05 PICTURE "@S35" 

       nX++
       @ box_x_koord() + nX++, box_y_koord() + 2 SAY8 "Kontiranje KALK 10/uvoz zamijeniti sa FIN-gen enabavke (D/N):" GET cEnabUvozSwitchKALK ;
           PICTURE "@!" VALID cEnabUvozSwitchKALK $ "DN"
       READ
    BoxC()

    IF Lastkey() == K_ESC
       RETURN .F.
    ENDIF


    set_metric( "fin_enab_idkonto_dob", NIL, cIdKontoDobav)

    set_metric( "fin_enab_idkonto_pdv", NIL, cIdKontoPDV)
    set_metric( "fin_enab_idkonto_pdv_np", NIL, cIdKontoPDVNP )

    
    set_metric( "fin_enab_idkonto_pdv_u", NIL, cIdKontoPDVUvoz)
    set_metric( "fin_enab_idkonto_pdv_u_np", NIL, cIdKontoPDVUvozNP)

    set_metric( "fin_enab_idkonto_pdv_a", NIL, cIdKontoPDVAvansi)
    set_metric( "fin_enab_idkonto_pdv_a_np", NIL, cIdKontoPDVAvansiNP)
    

    set_metric( "fin_enab_idkonto_pdv_ust", NIL, cIdKontoPDVUslugeStranaLica)
    set_metric( "fin_enab_idkonto_pdv_ust_np", NIL, cIdKontoPDVUslugeStranaLicaNP)

    set_metric( "fin_enab_idkonto_pdv_p", NIL, cIdKontoPDVPolj)
    set_metric( "fin_enab_idkonto_pdv_p_np", NIL, cIdKontoPDVPoljNP)

    set_metric( "fin_enab_idkonto_pdv_schema", NIL, cIdKontoPDVSchema)
    set_metric( "fin_enab_idkonto_pdv_schema_np", NIL, cIdKontoPDVSchemaNP)

    set_metric( "fin_enab_idkonto_pdv_ostalo", NIL, cIdKontoPDVOstalo)
    set_metric( "fin_enab_idkonto_pdv_ostalo_np", NIL, cIdKontoPDVOstaloNP)
    
    set_metric( "fin_enab_idvn_exclude", NIL, Trim(cNabExcludeIdvn) )
    set_metric( "fin_enab_idvn_05", NIL, Trim(cNabIdvn05) )

    set_metric( "fin_enab_uvoz_switch_kalk", NIL, cEnabUvozSwitchKALK )

    RETURN .T.


FUNCTION get_sql_expression_exclude_idvns(cNabExcludeIdvn)
    
    LOCAL nI, nNumTokens
    LOCAL cTmp, cTmps

     nNumTokens := NumToken( cNabExcludeIdvn, "," )
     cTmps := ""
     FOR nI := 1 TO nNumTokens
       cTmp := Token( cNabExcludeIdvn, ",", nI )
       cTmps += sql_quote( cTmp )
       IF nI < nNumTokens
         cTmps += ","
       ENDIF
     NEXT

    RETURN cTmps


FUNCTION check_eNabavke()

    LOCAL nStep, cKonto
    LOCAL cIdKontoDobav := PadR( fetch_metric( "fin_enab_idkonto_dob", NIL, "43" ), 7 )
    
    LOCAL cIdKontoPDV := PadR( fetch_metric( "fin_enab_idkonto_pdv", NIL, "270" ), 7 )
    LOCAL cIdKontoPDVNP := PadR( fetch_metric( "fin_enab_idkonto_pdv_np", NIL, "27690" ), 7 )

    LOCAL cIdKontoPDVUvoz := PadR( fetch_metric( "fin_enab_idkonto_pdv_u", NIL, "271" ), 7 )
    LOCAL cIdKontoPDVUvozNP := PadR( fetch_metric( "fin_enab_idkonto_pdv_u_np", NIL, "27691" ), 7 )

    LOCAL cIdKontoPDVAvansi := PadR( fetch_metric( "fin_enab_idkonto_pdv_a", NIL, "272" ), 7 )
    LOCAL cIdKontoPDVAvansiNP := PadR( fetch_metric( "fin_enab_idkonto_pdv_a_np", NIL, "27692" ), 7 )

    LOCAL cIdKontoPDVUslugeStranaLica := PadR( fetch_metric( "fin_enab_idkonto_pdv_ust", NIL, "273" ), 7 )
    LOCAL cIdKontoPDVUslugeStranaLicaNP := PadR( fetch_metric( "fin_enab_idkonto_pdv_ust_np", NIL, "27693" ), 7 )

    LOCAL cIdKontoPDVPolj := PadR( fetch_metric( "fin_enab_idkonto_pdv_p", NIL, "274" ), 7 )
    LOCAL cIdKontoPDVPoljNP := PadR( fetch_metric( "fin_enab_idkonto_pdv_p_np", NIL, "27694" ), 7 )

    LOCAL cIdKontoPDVSchema := PadR( fetch_metric( "fin_enab_idkonto_pdv_schema", NIL, "275" ), 7 )
    LOCAL cIdKontoPDVSchemaNP := PadR( fetch_metric( "fin_enab_idkonto_pdv_schema_np", NIL, "27695" ), 7 )

    LOCAL cIdKontoPDVOstalo := PadR( fetch_metric( "fin_enab_idkonto_pdv_ostalo", NIL, "278" ), 7 )
    LOCAL cIdKontoPDVOstaloNP := PadR( fetch_metric( "fin_enab_idkonto_pdv_ostalo_np", NIL, "27698" ), 7 )

    LOCAL cNabExcludeIdvn := TRIM( fetch_metric( "fin_enab_idvn_exclude", NIL, "I1,I2,IM,IB,B1,B2,PD" ) )
    LOCAL cSelectFields, cBrDokFinFin2, cFinNalogNalog2, cLeftJoinFin2
    LOCAL cTmps

    LOCAL dDatOd := fetch_metric( "fin_enab_dat_od", my_user(), DATE()-1 )
    LOCAL dDatDo := fetch_metric( "fin_enab_dat_do", my_user(), DATE() )
    LOCAL nX := 1
    LOCAL GetList := {}
    LOCAL cQuery, cQuery2, cQuery3, cQuery4, cQuery5, cQuery6, cQuery7
    

    Box(,3, 70)
       @ box_x_koord() + nX++, box_y_koord() + 2 SAY "***** eIsporuke Generacija *****"
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


    FOR nStep := 1 TO 2 
        cSelectFields := "SELECT fin_suban.idfirma, fin_suban.idvn, fin_suban.brnal, fin_suban.rbr, fin_suban.idkonto as idkonto, sub2.idkonto as idkonto2, fin_suban.brdok"
        cBrDokFinFin2 := "fin_suban.brdok=sub2.brdok"
        cFinNalogNalog2 := "fin_suban.idfirma=sub2.idfirma and fin_suban.idvn=sub2.idvn and fin_suban.brnal=sub2.brnal"
        cLeftJoinFin2 := " left join fmk.fin_suban sub2 on " + cFinNalogNalog2 + " and " + cBrDokFinFin2 + " and sub2.idkonto like '" + Trim(cIdKontoDobav) + "%'"

        // 2700 - roba domaci
        cQuery := cSelectFields
        cQuery += " from fmk.fin_suban "
        cQuery += cLeftJoinFin2
        cQuery += " left join fmk.partn on sub2.idpartner=partn.id"
        
        IF nStep == 1
           cKonto := Trim(cIdKontoPDV)
        ELSE
          cKonto := Trim(cIdKontoPDVNP)
        ENDIF
        cQuery += " where fin_suban.idkonto like  '"  + cKonto + "%' and fin_suban.d_p='1'" 
        cQuery += " and fin_suban.datdok >= " + sql_quote(dDatOd) + " and fin_suban.datdok <= " + sql_quote(dDatDo)
        cQuery += " and not fin_suban.idvn in (" + cTmps + ")"
        cQuery += "  and (sub2.idpartner  is null or trim(sub2.idpartner) ='')"
    
        // 2710 - uvoz
        cQuery2 := cSelectFields
        cQuery2 += " from fmk.fin_suban "
        cQuery2 += cLeftJoinFin2
        cQuery2 += " left join fmk.partn on sub2.idpartner=partn.id"
        IF nStep == 1
            cKonto := Trim(cIdKontoPDVUvoz)
         ELSE
           cKonto := Trim(cIdKontoPDVUvozNP)
        ENDIF
        cQuery2 += " where fin_suban.idkonto like  '"  + cKonto + "%' and fin_suban.d_p='1'" 
        cQuery2 += " and fin_suban.datdok >= " + sql_quote(dDatOd) + " and fin_suban.datdok <= " + sql_quote(dDatDo)
        cQuery2 += " and not fin_suban.idvn in (" + cTmps + ")"
        cQuery2 += "  and (sub2.idpartner  is null or trim(sub2.idpartner) ='')"

        // 2720 - avansi
        cQuery3 := cSelectFields
        cQuery3 += " from fmk.fin_suban "
        cQuery3 += cLeftJoinFin2
        cQuery3 += " left join fmk.partn on sub2.idpartner=partn.id"
        IF nStep == 1
            cKonto := Trim(cIdKontoPDVAvansi)
         ELSE
           cKonto := Trim(cIdKontoPDVAvansiNP)
        ENDIF
        cQuery3 += " where fin_suban.idkonto like  '"  + cKonto + "%' and fin_suban.d_p='1'" 
        cQuery3 += " and fin_suban.datdok >= " + sql_quote(dDatOd) + " and fin_suban.datdok <= " + sql_quote(dDatDo)
        cQuery3 += " and not fin_suban.idvn in (" + cTmps + ")"
        cQuery3 += "  and (sub2.idpartner  is null or trim(sub2.idpartner) ='')"

        // 2730 - strana lica
        cQuery4 := cSelectFields
        cQuery4 += " from fmk.fin_suban "
        cQuery4 += cLeftJoinFin2
        cQuery4 += " left join fmk.partn on sub2.idpartner=partn.id"
        IF nStep == 1
            cKonto := Trim(cIdKontoPDVUslugeStranaLica)
         ELSE
           cKonto := Trim(cIdKontoPDVUslugeStranaLicaNP)
        ENDIF
        cQuery4 += " where fin_suban.idkonto like  '"  + cKonto + "%' and fin_suban.d_p='1'" 
        cQuery4 += " and fin_suban.datdok >= " + sql_quote(dDatOd) + " and fin_suban.datdok <= " + sql_quote(dDatDo)
        cQuery4 += " and not fin_suban.idvn in (" + cTmps + ")"
        cQuery4 += "  and (sub2.idpartner  is null or trim(sub2.idpartner) ='')"

        // 2740 - poljo
        cQuery5 := cSelectFields
        cQuery5 += " from fmk.fin_suban "
        cQuery5 += cLeftJoinFin2
        cQuery5 += " left join fmk.partn on sub2.idpartner=partn.id"
        IF nStep == 1
            cKonto := Trim(cIdKontoPDVPolj)
         ELSE
           cKonto := Trim(cIdKontoPDVPoljNP)
        ENDIF
        cQuery5 += " where fin_suban.idkonto like  '"  + cKonto + "%' and fin_suban.d_p='1'" 
        cQuery5 += " and fin_suban.datdok >= " + sql_quote(dDatOd) + " and fin_suban.datdok <= " + sql_quote(dDatDo)
        cQuery5 += " and not fin_suban.idvn in (" + cTmps + ")"
        cQuery5 += "  and (sub2.idpartner  is null or trim(sub2.idpartner) ='')"

        // 2750 - posebna schema
        cQuery6 := cSelectFields
        cQuery6 += " from fmk.fin_suban "
        cQuery6 += cLeftJoinFin2
        cQuery6 += " left join fmk.partn on sub2.idpartner=partn.id"
        IF nStep == 1
            cKonto := Trim(cIdKontoPDVSchema)
         ELSE
           cKonto := Trim(cIdKontoPDVSchemaNP)
        ENDIF
        cQuery6 += " where fin_suban.idkonto like  '"  + cKonto + "%' and fin_suban.d_p='1'" 
        cQuery6 += " and fin_suban.datdok >= " + sql_quote(dDatOd) + " and fin_suban.datdok <= " + sql_quote(dDatDo)
        cQuery6 += " and not fin_suban.idvn in (" + cTmps + ")"
        cQuery6 += "  and (sub2.idpartner  is null or trim(sub2.idpartner) ='')"

        // 2780 - ostalo
        cQuery7 := cSelectFields
        cQuery7 += " from fmk.fin_suban "
        cQuery7 += cLeftJoinFin2
        cQuery7 += " left join fmk.partn on sub2.idpartner=partn.id"
        IF nStep == 1
            cKonto := Trim(cIdKontoPDVOstalo)
         ELSE
           cKonto := Trim(cIdKontoPDVOstaloNP)
        ENDIF
        cQuery7 += " where fin_suban.idkonto like  '"  + cKonto + "%' and fin_suban.d_p='1'" 
        cQuery7 += " and fin_suban.datdok >= " + sql_quote(dDatOd) + " and fin_suban.datdok <= " + sql_quote(dDatDo)
        cQuery7 += " and not fin_suban.idvn in (" + cTmps + ")"
        cQuery7 += "  and (sub2.idpartner  is null or trim(sub2.idpartner) ='')"

    
        IF !use_sql( "ENAB", "(" + cQuery + ") UNION (" + cQuery2 + ") UNION (" + cQuery3 + ") UNION (" + cQuery4 + ") UNION (" + cQuery5 + ") UNION (" + cQuery6 +") UNION (" + cQuery7 +")" +;
                            " order by idfirma, idvn, brnal, rbr")
            RETURN .F.
        ENDIF

        nX:=1
        Box( ,15, 85)
        @ box_x_koord() + nX++, box_y_koord() + 2 SAY "****** FIN nalozi koji nemaju zadane ispravne partnere ili veze (brdok):"
        @ box_x_koord() + nX++, box_y_koord() + 2 SAY "          " + IIF(nStep==1, "POSLOVNA", "VANPOSLOVNA") + " potrosnja"

        ++nX
        DO WHILE !EOF()
            @ box_x_koord() + nX++, box_y_koord() + 2 SAY enab->idfirma + "-" + enab->idvn + "-" + enab->brnal + " Rbr:" + str(enab->rbr,4) +;
                    " Konto: " + trim(enab->idkonto) + " / Konto2: " + trim(enab->idkonto2)
            IF nX > 13
            Inkey(0)
            nX := 1
            ENDIF
            IF LastKey() == K_ESC
                EXIT
            ENDIF
            skip
        ENDDO
        Inkey(0)
        BoxC()

        USE

    NEXT
    //MsgBeep("check eNabavke")
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

CREATE sequence if not exists enabavke_id_seq;

CREATE TABLE if not exists public.enabavke  (
    enabavke_id  integer not null default nextval('enabavke_id_seq'),
    tip varchar(2) constraint allowed_enabavke_vrste check (tip in ('01', '02', '03', '04', '05')),
    porezni_period varchar(4),
    br_fakt varchar(100) not NULL,
    dat_fakt date not null,
    dat_fakt_prijem date,
    dob_naz varchar(100) not null,
    dob_sjediste varchar(100),
    dob_pdv varchar(12),
    dob_jib varchar(13),
    fakt_iznos_bez_pdv numeric(24,2) not null,
    fakt_iznos_sa_pdv numeric(24,2) not null,
    fakt_iznos_poljo_pausal numeric(24,2),
    fakt_iznos_pdv numeric(24,2),
    fakt_iznos_pdv_np numeric(24,2),
    fakt_iznos_pdv_np_32 numeric(24,2),
    fakt_iznos_pdv_np_33 numeric(24,2),
    fakt_iznos_pdv_np_34 numeric(24,2)
   
);
    
COMMENT ON COLUMN enabavke.tip IS '01-roba i usluge iz zemlje, 02-vlastita potrosnja vanposlovne svrhe, 03-avansna faktura dati avans,04-JCI uvoz, 05 - ostalo: fakture za primljene usluge ino itd';

ALTER SEQUENCE public.enabavke_id_seq OWNER TO "admin";
GRANT ALL ON TABLE public.enabavke TO "admin";
GRANT ALL ON TABLE public.enabavke TO xtrole;


alter table enabavke add column fin_idfirma varchar(2) not null;
alter table enabavke add column fin_idvn varchar(2) not null;
alter table enabavke add column fin_brnal varchar(8) not null;
alter table enabavke add column fin_rbr int not null;
alter table enabavke add column opis varchar(500);
alter table enabavke add column jci varchar(20);
alter table enabavke add column osn_pdv0 numeric(24,2);
alter table enabavke add column osn_pdv17 numeric(24,2);
alter table enabavke add column osn_pdv17np numeric(24,2);
alter table enabavke add column fakt_iznos_dob numeric(24,2);

DROP INDEX if exists enabavke_fin_nalog;
CREATE unique INDEX enabavke_fin_nalog ON public.enabavke USING btree (fin_idfirma, fin_idvn, fin_brnal, fin_rbr);

ALTER TABLE public.eNabavke OWNER TO "admin";
GRANT ALL ON TABLE public.eNabavke TO "admin";
GRANT ALL ON TABLE public.eNabavke TO xtrole;

*/





STATIC FUNCTION db_insert_enab( hRec )

    LOCAL cQuery := "INSERT INTO public.enabavke", oRet
    
    cQuery += "(enabavke_id, tip, porezni_period, br_fakt, jci, dat_fakt, dat_fakt_prijem,"
    cQuery += "dob_naz,dob_sjediste, dob_pdv, dob_jib,"
    cQuery += "fakt_iznos_bez_pdv, osn_pdv0, osn_pdv17, osn_pdv17np, fakt_iznos_sa_pdv, fakt_iznos_dob, fakt_iznos_poljo_pausal, fakt_iznos_pdv, fakt_iznos_pdv_np, fakt_iznos_pdv_np_32, fakt_iznos_pdv_np_33, fakt_iznos_pdv_np_34,"
    cQuery += "opis, fin_idfirma, fin_idvn,fin_brnal,fin_rbr) "
    cQuery += "VALUES("
    cQuery += sql_quote(hRec["enabavke_id"]) + ","
    cQuery += sql_quote(hRec["tip"]) + ","
    cQuery += sql_quote(hRec["porezni_period"]) + ","
    cQuery += sql_quote(hRec["br_fakt"]) + ","
    cQuery += sql_quote(hRec["jci"]) + ","
    cQuery += sql_quote(hRec["dat_fakt"]) + ","
    cQuery += sql_quote(hRec["dat_fakt_prijem"]) + ","
    cQuery += sql_quote(hRec["dob_naz"]) + ","
    cQuery += sql_quote(hRec["dob_sjediste"]) + ","
    cQuery += sql_quote(hRec["dob_pdv"]) + ","
    cQuery += sql_quote(hRec["dob_jib"]) + ","
    cQuery += sql_quote(ROUND(hRec["fakt_iznos_bez_pdv"],2)) + ","
    cQuery += sql_quote(ROUND(hRec["osn_pdv0"],2)) + ","
    cQuery += sql_quote(ROUND(hRec["osn_pdv17"],2)) + ","
    cQuery += sql_quote(ROUND(hRec["osn_pdv17np"],2)) + ","
    cQuery += sql_quote(ROUND(hRec["fakt_iznos_sa_pdv"],2)) + ","
    cQuery += sql_quote(ROUND(hRec["fakt_iznos_dob"],2)) + ","
    cQuery += sql_quote(ROUND(hRec["fakt_iznos_poljo_pausal"],2)) + ","
    cQuery += sql_quote(ROUND(hRec["fakt_iznos_pdv"],2)) + ","
    cQuery += sql_quote(ROUND(hRec["fakt_iznos_pdv_np"],2)) + ","
    cQuery += sql_quote(ROUND(hRec["fakt_iznos_pdv_np_32"],2)) + ","
    cQuery += sql_quote(ROUND(hRec["fakt_iznos_pdv_np_33"],2)) + ","
    cQuery += sql_quote(ROUND(hRec["fakt_iznos_pdv_np_34"],2)) + ","
    cQuery += sql_quote(hRec["opis"]) + ","
    cQuery += sql_quote(hRec["fin_idfirma"]) + ","
    cQuery += sql_quote(hRec["fin_idvn"]) + ","
    cQuery += sql_quote(hRec["fin_brnal"]) + ","
    cQuery += sql_quote(hRec["fin_rbr"]) + ")"

    oRet := run_sql_query(cQuery)

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
v1:

 select get_sifk('PARTN', 'PDVB', sub2.idpartner) as pdv_broj, get_sifk('PARTN', 'IDBR', sub2.idpartner) as jib, 
        ((case when sub2.d_p='1' then 1 else -1 end) * sub2.iznosbhd - (case when fin_suban.d_p='2' then 1 else -1 end) * fin_suban.iznosbhd) * -1 as bez_pdv,
        (case when fin_suban.d_p='2' then 1 else -1 end) * fin_suban.iznosbhd * -1 as pdv, 
        (case when sub2.d_p='1' then 1 else -1 end) * sub2.iznosbhd * -1 as iznos_sa_pdv,
        fin_suban.idkonto, partn.id, partn.naz, sub2.idkonto, fin_suban.* from fmk.fin_suban

     left join fmk.fin_suban sub2 on fin_suban.idfirma=sub2.idfirma and fin_suban.idvn=sub2.idvn and fin_suban.brnal=sub2.brnal and fin_suban.brdok=sub2.brdok and sub2.idkonto like '4%'
     
     left join fmk.partn on sub2.idpartner=partn.id
      
     where fin_suban.idkonto like  '270%' and fin_suban.datdok >= '2020-10-01' and fin_suban.datdok <= '2020-10-31' 
           and not fin_suban.idvn in ('PD','IB');


v2:

ovdje je primarni konto 43%

select (case when s1.from_opis_osn_pdv17 is not null then s1.from_opis_osn_pdv17 else round(iznos_pdv/0.17,2) end)  as osn_pdv, * from  (
select get_sifk('PARTN', 'PDVB', fin_suban.idpartner) as pdv_broj, get_sifk('PARTN', 'IDBR', fin_suban.idpartner) as jib, fin_suban.brdok,
        (case when fin_suban.d_p='2' then 1 else -1 end) * fin_suban.iznosbhd as iznos_fakture,
        (case when sub2.d_p='1' then 1 else -1 end) * sub2.iznosbhd as iznos_pdv,
        (case when sub3.d_p='1' then 1 else -1 end) * sub3.iznosbhd as iznos_pdv_np,
        substring(fin_suban.opis from 'JCI:\s+(\d+)') as JCI,
        substring(fin_suban.opis from 'OSN-PDV0:\s+([\d.]+)')::DECIMAL as from_opis_osn_pdv,
        substring(fin_suban.opis from 'OSN-PDV17:\s+([\d.]+)')::DECIMAL as from_opis_osn_pdv17,
        substring(fin_suban.opis from 'OSN-PDV17NP:\s+([\d.]+)')::DECIMAL as from_opis_osn_pdv17np,
        fin_suban.idkonto, partn.id, partn.naz, sub2.idkonto, sub3.idkonto, fin_suban.* from fmk.fin_suban
     left join fmk.fin_suban sub2 on fin_suban.idfirma=sub2.idfirma and fin_suban.idvn=sub2.idvn and fin_suban.brnal=sub2.brnal and fin_suban.brdok=sub2.brdok and sub2.idkonto like '27%'
     left join fmk.fin_suban sub3 on fin_suban.idfirma=sub3.idfirma and fin_suban.idvn=sub3.idvn and fin_suban.brnal=sub3.brnal and fin_suban.brdok=sub3.brdok and sub3.idkonto like '2789%'
     left join fmk.partn on sub2.idpartner=partn.id
     where fin_suban.idkonto like  '43%' and fin_suban.datdok >= '2020-11-01' and fin_suban.datdok <= '2020-11-30'
           and not fin_suban.idvn in ('PD','IB')
) as s1

*/
STATIC FUNCTION gen_enabavke_stavke(nRbr, dDatOd, dDatDo, cPorezniPeriod, cTipDokumenta, cIdKonto, cIdKontoNP, cNabExcludeIdvn, cNabIdvn05, ;
    lUslugeStranogLica, lSamoPDV0, lSchema, hUkupno )

    LOCAL cSelectFields, cBrDokFinFin2, cFinNalogNalog2, cLeftJoinFin2, cBrDokFinFin3, cFinNalogNalog3, cLeftJoinFin3 
    LOCAL cQuery, cTmps
    LOCAL cCSV := ";"
    LOCAL n32, n33, n34
    LOCAL cPDVBroj, cJib
    LOCAL nPDVNP, nPDVPosl
    LOCAL hRec := hb_hash()
    LOCAL cTipDokumenta2
    LOCAL nUndefined := -9999999.99
    LOCAL cBrDok
    LOCAL dDatFakt, dDatFaktPrij
    LOCAL cIdKontoDobav := Trim( fetch_metric( "fin_enab_idkonto_dob", NIL, "43" ))

    cTmps := get_sql_expression_exclude_idvns(cNabExcludeIdvn)

    cSelectFields := "SELECT get_sifk('PARTN', 'PDVB', fin_suban.idpartner) as pdv_broj, get_sifk('PARTN', 'IDBR', fin_suban.idpartner) as jib,"
    
    cSelectFields += "(case when fin_suban.d_p='2' then 1 else -1 end) * fin_suban.iznosbhd as iznos_sa_pdv,"
    cSelectFields += "(case when sub2.d_p='1' then 1 else -1 end) * sub2.iznosbhd as iznos_pdv,"
    cSelectFields += "(case when sub3.d_p='1' then 1 else -1 end) * sub3.iznosbhd as iznos_pdv_np,"

    // iz opisa ako ima ekstraktovati JCI, PDV0 osnovicu, PDV17 osnovicu, PDV17 neposlovnu osnovicu
    cSelectFields += "substring(fin_suban.opis from 'JCI:\s+(\d+)') as JCI,"
    cSelectFields += "COALESCE(substring(fin_suban.opis from 'OSN-PDV0:\s*([\d.]+)')::DECIMAL, -9999999.99) as from_opis_osn_pdv0,"
    cSelectFields += "COALESCE(substring(fin_suban.opis from 'OSN-PDV17:\s*([\d.]+)')::DECIMAL, -9999999.99) as from_opis_osn_pdv17,"
    cSelectFields += "COALESCE(substring(fin_suban.opis from 'OSN-PDV17NP:\s*([\d.]+)')::DECIMAL, -9999999.99) as from_opis_osn_pdv17np,"
    cSelectFields += "COALESCE(substring(fin_suban.opis from 'DAT-FAKT:\s*([\d.]+)'), 'UNDEF') as from_opis_dat_fakt,"
    cSelectFields += "COALESCE(substring(fin_suban.opis from 'MJ-KP:\s*(\d)'), 'X') as from_opis_mj_kp,"

    //cSelectFields += "((case when sub2.d_p='1' then 1 else -1 end) * sub2.iznosbhd - (case when fin_suban.d_p='2' then 1 else -1 end) * fin_suban.iznosbhd) * -1 as bez_pdv,"
    //cSelectFields += "(case when fin_suban.d_p='2' then 1 else -1 end) * fin_suban.iznosbhd * -1 as pdv,"
    //cSelectFields += "(case when sub2.d_p='1' then 1 else -1 end) * sub2.iznosbhd * -1 as iznos_sa_pdv,"
    
    cSelectFields += "fin_suban.idkonto as idkonto, partn.id, partn.naz, partn.adresa, sub2.idkonto as idkonto2, sub3.idkonto as idkonto3, fin_suban.idfirma, fin_suban.idvn, fin_suban.brnal, fin_suban.rbr,"
    cSelectFields += "fin_suban.brdok, fin_suban.opis, fin_suban.d_p, fin_suban.datdok, fin_suban.datval,"
    cSelectFields += "partn.id as partn_id, partn.naz as partn_naz, partn.adresa as partn_adresa, partn.ptt as partn_ptt, partn.mjesto as partn_mjesto, partn.rejon partn_rejon,"

    // postoji li vec enabavke stavka
    cSelectFields += "COALESCE(enabavke.fin_rbr,-99999) enab_rbr"

    cBrDokFinFin2 := "fin_suban.brdok=sub2.brdok"
    cFinNalogNalog2 := "fin_suban.idfirma=sub2.idfirma and fin_suban.idvn=sub2.idvn and fin_suban.brnal=sub2.brnal"
    cLeftJoinFin2 := " left join fmk.fin_suban sub2 on " + cFinNalogNalog2 + " and " + cBrDokFinFin2 + " and sub2.idkonto like '" + Trim(cIdKonto) + "%' and sub2.d_p='1'"

    cBrDokFinFin3 := "fin_suban.brdok=sub3.brdok"
    cFinNalogNalog3 := "fin_suban.idfirma=sub3.idfirma and fin_suban.idvn=sub3.idvn and fin_suban.brnal=sub3.brnal"
    cLeftJoinFin3 := " left join fmk.fin_suban sub3 on " + cFinNalogNalog3 + " and " + cBrDokFinFin3 + " and sub3.idkonto like '" + Trim(cIdKontoNP) + "%' and sub3.d_p='1'"

    cQuery := cSelectFields
    cQuery += " from fmk.fin_suban "
    cQuery += cLeftJoinFin2
    cQuery += cLeftJoinFin3
    cQuery += " left join fmk.partn on fin_suban.idpartner=partn.id"

    cQuery += " left join public.enabavke on fin_suban.idfirma=enabavke.fin_idfirma and fin_suban.idvn=enabavke.fin_idvn and fin_suban.brnal=enabavke.fin_brnal and fin_suban.rbr=enabavke.fin_rbr"
 
    cQuery += " where fin_suban.idkonto like  '" + Trim(cIdKontoDobav) + "%'" 
    // dobavljac potrazuje, sub2.d_p, sub3.d_p duguje
    cQuery += " and fin_suban.d_p='2'"
    cQuery += " and fin_suban.datdok >= " + sql_quote(dDatOd) + " and fin_suban.datdok <= " + sql_quote(dDatDo)
    cQuery += " and not fin_suban.idvn in (" + cTmps + ")"

    IF !lSamoPDV0 
        // mora postojati sub2.idkonto ili sub3.idkonto

        cQuery +=" and (sub2.idkonto is not null or sub3.idkonto is not null)"
    ENDIF

    //cQuery += "  and NOT (sub2.idpartner is null or trim(sub2.idpartner) ='')"
 
    IF !use_sql( "ENAB",  cQuery + " order by fin_suban.datdok, fin_suban.idfirma, fin_suban.idvn, fin_suban.brnal, fin_suban.rbr")
        RETURN .F.
    ENDIF

    DO WHILE !EOF()

  
        IF cTipDokumenta == "04"
           hRec["jci"] := enab->jci
        ELSE
           hRec["jci"] := ""
        ENDIF


        cPDVBroj := enab->pdv_broj 
        cJib := enab->jib

        IF (LEN(TRIM(cJib))<13 .AND. LEN(TRIM(cJib))>0) .AND. LEN(TRIM(cPDVBroj))<12
            // ino dobavljac
            cJib := ""
            cPDVBroj := REPLICATE("0", 12)
        ENDIF
        hRec["dob_jib"] := cJib
        hRec["dob_pdv"] := cPDVBroj

        IF enab->enab_rbr <> -99999
            // vec postoji stavka 43% u tabeli enabavke
            SKIP
            LOOP
        ENDIF

        IF Empty(enab->partn_id)
            // stavka 43% moze biti i 4300 (primljeni avans) bez partnera
            SKIP
            LOOP
        ENDIF

        IF lUslugeStranogLica
            IF cPDVBroj <> REPLICATE("0", 12)
                // dobaci dobavljac
                // preskoci domace dobavljace
                IF ABS(round(enab->iznos_pdv,2)) + ABS(round(enab->iznos_pdv_np,2)) > 0
                    Alert("05:" + Trim(cIdKonto) + " Partner: " + enab->partn_id + " nije strani dobavljac a mora biti?!")
                ENDIF
                skip
                loop
            ENDIF
        ENDIF

        // ako je uvoz, mora biti definisan jci
        IF cTipDokumenta == "04" .AND. empty( enab->jci )
            SKIP
            LOOP
        ENDIF


        // tip dokumenta nije uvoz, a ima JCI - preskoci
        IF cTipDokumenta != "04" .AND. !empty( enab->jci )
            SKIP    
            LOOP
        ENDIF


        cTipDokumenta2 := cTipDokumenta
        // iznos PDVNP > PDV
        IF cTipDokumenta == "01"
            IF (ABS(enab->iznos_pdv_np) > ABS(enab->iznos_pdv))
               // vanposlovna potrosnja
               cTipDokumenta2 := "02"
            ELSE
               cTipDokumenta2 := "01"
            ENDIF
        ENDIF

        // ako se radi o vrsti naloga koji zelimo oznaciti u CSV kao tip '05'
        IF enab->idvn $ cNabIdvn05
            cTipDokumenta2 := "05"
        ENDIF

        hRec["tip"] := cTipDokumenta2

        hRec["enabavke_id"] := nRbr
        
        hRec["porezni_period"] := cPorezniPeriod
        hRec["br_fakt"] := enab->brdok
        

        IF cTipDokumenta == "04"
           cBrDok := enab->jci
        else   
           cBrDok := enab->brdok
        ENDIF

        IF enab->from_opis_dat_fakt <> "UNDEF"
            dDatFakt := CTOD(enab->from_opis_dat_fakt)
            dDatFaktPrij := enab->datdok
        ELSE
            dDatFakt := enab->datdok
            dDatFaktPrij := enab->datdok
        ENDIF

        hRec["dat_fakt"] := dDatFakt
        hRec["dat_fakt_prijem"] := dDatFaktPrij
        hRec["dob_naz"] := say_string(enab->partn_naz, 100, .F.)
        hRec["dob_sjediste"] := say_string(trim(enab->partn_ptt) + " " + trim(enab->partn_mjesto) + " " + trim(enab->partn_adresa), 100, .F.)


        IF cTipDokumenta == "04" .AND. !Empty(cJib)
            // ovo su zavisni troskovi - domaci dobavljaci, preskoci
            //MsgBeep( "ERR-SKIP: Domaći dobavljač " + enab->partn_id + "vrši uvoz ?!")
            SKIP
            LOOP
        ENDIF


        //IF cTipDokumenta == "02"
        nPDVNP := enab->iznos_pdv_np
        //    nPDVPosl := 0
        
        //ELSE
        //    nPDVNP := 0
        nPDVPosl := enab->iznos_pdv
        //ENDIF

        n32 := 0
        n33 := 0
        n34 := 0

        // ako je sjediste preduzeca FBiH, onda se svaka nabavka
        // tretira krajnjom potrosnjom u FBiH
        // medjutim ako ima poslovnice u drugom entitetu, i ta poslovnica napravi krajnju potrosnju to se evidentira kao krajnja potrosnja u drugom entitetu
        // MJ-KP: 1 - FBiH
        // MJ-KP: 2 - RS
        // MJ-KP: 3 - BD

        IF enab->from_opis_mj_kp <> 'X'
            //IF cTipDokumenta == "02" // vanposlovno
            SWITCH enab->from_opis_mj_kp
                     CASE "2" // RS
                       n33 := nPDVNP
                       EXIT
                     CASE "3" // BD
                       n34 := nPDVNP
                       EXIT
                    OTHERWISE
                       // FBiH
                       n32 :=  nPDVNP
                       EXIT     
            ENDSWITCH
            //ENDIF
        ELSE
            // nije navedeno MJ-KP, po defaultu mjesto kranje potrosnje FBiH
            n32 := nPDVNP
        ENDIF

        hRec["osn_pdv0"] := nUndefined
        hRec["osn_pdv17"] := nUndefined
        hRec["osn_pdv17np"] := nUndefined


        IF lSchema
            hRec[ "osn_pdv17"] := 0
            hRec[ "osn_pdv17np"] := 0
        ELSE
            // osnovica PDV
            IF enab->from_opis_osn_pdv17 <> nUndefined
                hRec["osn_pdv17"] := enab->from_opis_osn_pdv17
            ELSE
                hRec["osn_pdv17"] := ROUND(enab->iznos_pdv / 0.17, 2)
            ENDIF
            IF enab->from_opis_osn_pdv17np <> nUndefined
                hRec["osn_pdv17np"] := enab->from_opis_osn_pdv17np
            ELSE
                hRec["osn_pdv17np"] := ROUND(enab->iznos_pdv_np / 0.17, 2)
            ENDIF
        ENDIF


        IF enab->from_opis_osn_pdv0 <> nUndefined
            hRec["osn_pdv0"] := enab->from_opis_osn_pdv0
        ELSE
            IF cTipDokumenta == "04"
                // stavka uvoza ne sadrzi PDV 0% osnovicu 
                hRec["osn_pdv0"] := 0
            ELSE
                if lUslugeStranogLica
                   // proracun osnovice PDV0 na osnovu cijene sa PDV i ostalih osnovica
                   hRec["osn_pdv0"] := enab->iznos_sa_pdv - hRec["osn_pdv17"] - hRec["osn_pdv17np"]
                ELSE
                   IF lSchema
                      hRec[ "osn_pdv0" ] := 0
                   ELSE
                      // proracun osnovice PDV0 na osnovu cijene sa PDV i ostalih osnovica
                      hRec["osn_pdv0"] := enab->iznos_sa_pdv - hRec["osn_pdv17"] * 1.17 - hRec["osn_pdv17np"] * 1.17
                   ENDIF
                ENDIF
            ENDIF
        ENDIF

        hRec["fakt_iznos_bez_pdv"] := hRec["osn_pdv17"] + hRec["osn_pdv17np"] + hRec["osn_pdv0"]
     
        // iznos fakture dobavljaca
        hRec["fakt_iznos_dob"] := enab->iznos_sa_pdv

        hRec["fakt_iznos_poljo_pausal"] := 0
        hRec["fakt_iznos_pdv"] := nPDVPosl
        hRec["fakt_iznos_pdv_np"] := nPDVNP
        hRec["fakt_iznos_pdv_np_32"] := n32 
        hRec["fakt_iznos_pdv_np_33"] := n33
        hRec["fakt_iznos_pdv_np_34"] := n34

        if lUslugeStranogLica
            // iznos sa PDV u ovom slucaju ne odgovara iznosu fakture dobavljaca nego je uvecan za PDV
            hRec["fakt_iznos_sa_pdv"] := hRec["osn_pdv0"] + hRec["osn_pdv17"] * 1.17 + hRec["osn_pdv17np"] * 1.17
        ELSE
            //IF cTipDokumenta == "04"
               hRec["fakt_iznos_sa_pdv"] := hRec["fakt_iznos_bez_pdv"] + nPDVPosl + nPDVNP
            //ELSE
            //   IF lSchema
            //       hRec["fakt_iznos_sa_pdv"] := enab->iznos_sa_pdv
            //   ELSE 
            //   hRec["fakt_iznos_sa_pdv"] := enab->iznos_sa_pdv
            //ENDIF
        ENDIF

        hRec["fin_idfirma"] := enab->idfirma
        hRec["fin_idvn"] := enab->idvn
        hRec["fin_brnal"] := enab->brnal
        hRec["fin_rbr"] := enab->rbr
        hRec["opis"] := enab->opis
        db_insert_enab( hRec)


        // Vrsta sloga 2 = slogovi nabavki
        ? "2" + cCSV
        ?? cPorezniPeriod + cCSV
        ?? PADL(AllTrim(STR(nRbr,10,0)), 10, "0") + cCSV
        ?? cTipDokumenta2 + cCSV
        // 5. broj fakture ili dokumenta ili JCI ako je tip dokumenta = "04" - uvoz
        ?? say_string(cBrDok, 100) + cCSV
        // 6. datum fakture ili dokumenta
        ?? STRTRAN(sql_quote(dDatFakt),"'","") + cCSV
        // 7. datum prijema
        ?? STRTRAN(sql_quote(dDatFaktPrij),"'","") + cCSV
        // 8. naziv dobavljaca
        ?? say_string(enab->partn_naz, 100) + cCSV
        // Sjediste dobavljaca
        ?? say_string(trim(enab->partn_ptt) + " " + trim(enab->partn_mjesto) + " " + trim(enab->partn_adresa), 100) + cCSV


        // 10. PDV dobav
        ??  cPDVBroj + cCSV
        // 11. JIB dobav
        ?? cJib + cCSV
        // 12. bez PDV
        ?? say_number(hRec["fakt_iznos_bez_pdv"]) + cCSV
        hUkupno["bez"] += hRec["fakt_iznos_bez_pdv"]

        // 13. sa PDV
        ?? say_number(hRec["fakt_iznos_sa_pdv"]) + cCSV
        hUkupno["sa_pdv"] += hRec["fakt_iznos_sa_pdv"]

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
   left join fmk.fin_suban sub2 on fin_suban.brdok=sub2.brdok and fin_suban.idfirma=sub2.idfirma and fin_suban.idvn=sub2.idvn and fin_suban.brnal=sub2.brnal and (sub2.idkonto like '27%' or sub2.idkonto like '2789%')
   where trim(fin_suban.idkonto) like '432%' and 
         fin_suban.datdok >= '2020-10-01' and fin_suban.datdok <= '2020-10-31'
         and sub2.idkonto is null
        and not fin_suban.idvn in ('PD','IB', 'B1', 'B2', 'B3');
    
*/
/*
STATIC FUNCTION gen_enabavke_stavke_pdv0(nRbr, dDatOd, dDatDo, cPorezniPeriod, cTipDokumenta, cPDVNPExclude, cNabExcludeIdvn, lPDVNule, hUkupno )

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
    // ovdje fin_suban 43% konto povezujemo sa sub2.idkonto 27%/2789% i ocekujemo DA NEMA VEZE - da ne postoji uparen konto PDV-a ! 
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
        hRec["br_fakt"] := enab->brdok
        hRec["jci"] := ""
        hRec["dat_fakt"] := enab->datdok
        hRec["dat_fakt_prijem"] := enab->datdok
        hRec["dob_naz"] := say_string(enab->partn_naz, 100, .F.)
        hRec["dob_sjediste"] := say_string(trim(enab->partn_ptt) + " " + trim(enab->partn_mjesto) + " " + trim(enab->partn_adresa), 100, .F.)

        cPDVBroj := enab->pdv_broj 
        // uvoz
        IF cTipDokumenta == "04" .OR. lPDVNule
            cPDVBroj := REPLICATE("0",12)
        ENDIF
        hRec["dob_pdv"] := cPDVBroj
        cJib := enab->jib
        IF LEN(TRIM(cJib)) < 13
            cJib := ""
        ENDIF
        hRec["dob_jib"] := cJib

        nPDVPosl := 0
        nPDVNP := 0
        n32 := 0
        n33 := 0
        n34 := 0

        hRec["fakt_iznos_bez_pdv"] := enab->iznos

        // osnovica PDV
        hRec["osn_pdv0"] := 0
        hRec["osn_pdv17"] := 0
        hRec["osn_pdv17np"] := 0

        hRec["fakt_iznos_sa_pdv"] := enab->iznos
        hRec["fakt_iznos_poljo_pausal"] := 0

        hRec["fakt_iznos_pdv"] := nPDVPosl
        hRec["fakt_iznos_pdv_np"] := nPDVNP
        hRec["fakt_iznos_pdv_np_32"] := n32 
        hRec["fakt_iznos_pdv_np_33"] := n33
        hRec["fakt_iznos_pdv_np_34"] := n34
        hRec["fin_idfirma"] := enab->idfirma
        hRec["fin_idvn"] := enab->idvn
        hRec["fin_brnal"] := enab->brnal
        hRec["fin_rbr"] := enab->rbr
        hRec["opis"] := enab->opis
        db_insert_enab( hRec)

        // Vrsta sloga 2 = slogovi nabavki
        ? "2" + cCSV
        ?? cPorezniPeriod + cCSV
        ?? PADL(AllTrim(STR(nRbr, 10, 0)), 10, "0") + cCSV
        ?? cTipDokumenta + cCSV
        // 5. broj fakture ili dokumenta
        ?? say_string(enab->brdok, 100) + cCSV
        // 6. datum fakture ili dokumenta
        ?? STRTRAN(sql_quote(enab->datdok),"'","") + cCSV
        // 7. datum prijema
        ?? STRTRAN(sql_quote(enab->datdok),"'","") + cCSV
        // 8. naziv dobavljaca
        ?? say_string(enab->partn_naz, 100) + cCSV
        // Sjediste dobavljaca
        ?? say_string(trim(enab->partn_ptt) + " " + trim(enab->partn_mjesto) + " " + trim(enab->partn_adresa), 100) + cCSV

      
        // 10. PDV dobav
        ??  cPDVBroj + cCSV
        // 11. JIB dobav
        ?? cJib + cCSV
        // 12. bez PDV
        ?? say_number(enab->iznos) + cCSV
        hUkupno["bez"] += enab->iznos

        // 13. sa PDV
        ?? say_number(enab->iznos) + cCSV
        hUkupno["sa_pdv"] += enab->iznos

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

FUNCTION gen_eNabavke()
    
    LOCAL nX := 1 

    LOCAL cIdKontoPDV := PadR( fetch_metric( "fin_enab_idkonto_pdv", NIL, "270" ), 7 )
    LOCAL cIdKontoPDVNP := PadR( fetch_metric( "fin_enab_idkonto_pdv_np", NIL, "27690" ), 7 )

    LOCAL cIdKontoPDVUvoz := PadR( fetch_metric( "fin_enab_idkonto_pdv_u", NIL, "271" ), 7 )
    LOCAL cIdKontoPDVUvozNP := PadR( fetch_metric( "fin_enab_idkonto_pdv_u_np", NIL, "27691" ), 7 )

    LOCAL cIdKontoPDVAvansi := PadR( fetch_metric( "fin_enab_idkonto_pdv_a", NIL, "272" ), 7 )
    LOCAL cIdKontoPDVAvansiNP := PadR( fetch_metric( "fin_enab_idkonto_pdv_a_np", NIL, "27692" ), 7 )

    LOCAL cIdKontoPDVUslugeStranaLica := PadR( fetch_metric( "fin_enab_idkonto_pdv_ust", NIL, "273" ), 7 )
    LOCAL cIdKontoPDVUslugeStranaLicaNP := PadR( fetch_metric( "fin_enab_idkonto_pdv_ust_np", NIL, "27693" ), 7 )

    LOCAL cIdKontoPDVPolj := PadR( fetch_metric( "fin_enab_idkonto_pdv_p", NIL, "274" ), 7 )
    LOCAL cIdKontoPDVPoljNP := PadR( fetch_metric( "fin_enab_idkonto_pdv_p_np", NIL, "27694" ), 7 )

    LOCAL cIdKontoPDVSchema := PadR( fetch_metric( "fin_enab_idkonto_pdv_schema", NIL, "275" ), 7 )
    LOCAL cIdKontoPDVSchemaNP := PadR( fetch_metric( "fin_enab_idkonto_pdv_schema_np", NIL, "27695" ), 7 )

    LOCAL cIdKontoPDVOstalo := PadR( fetch_metric( "fin_enab_idkonto_pdv_ostalo", NIL, "278" ), 7 )
    LOCAL cIdKontoPDVOstaloNP := PadR( fetch_metric( "fin_enab_idkonto_pdv_ostalo_np", NIL, "27698" ), 7 )

    LOCAL cNabExcludeIdvn := PadR( fetch_metric( "fin_enab_idvn_exclude", NIL, "I1,I2,IB,B1,B2,B3,PD" ), 100 )
    LOCAL cNabIdvn05 := PadR( fetch_metric( "fin_enab_idvn_05", NIL, "05,06,07" ), 100 )


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
        IF !use_sql( "ENAB", "select max(enabavke_id) as max from public.enabavke where porezni_period<>" + sql_quote(cPorezniPeriod))
            MsgBeep("enabavke sql tabela nedostupna?!")
            BoxC()
            RETURN .F.
        ENDIF
        nRbr := enab->max + 1
        USE
        SELECT F_TMP
        BEGIN SEQUENCE WITH {| err| Break( err ) }
            IF !use_sql( "ENAB", "select max(g_r_br) as max from fmk.epdv_kuf")
                //MsgBeep("fmk.epdv_kuf sql tabela nedostupna?!")
            ENDIF
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
        run_sql_query("DELETE from public.enabavke where porezni_period=" + sql_quote(cPorezniPeriod))
        nCnt := table_count( "public.enabavke", "porezni_period=" + sql_quote(cPorezniPeriod))
        IF nCnt > 0
            MsgBeep("Za porezni period " + cPorezniPeriod + " postoje zapisi?!##STOP")
        RETURN .F.
        ENDIF
    ENDIF

    DirChange( cLokacijaExport )
    info_bar( "csv", "lokacija csv: " + cLokacijaExport )
    
    cExportFile := cPDV + "_"

 
    cExPortFile += cPorezniPeriod
    
    cExportFile += "_1_" 

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
    // 4. tip datoteke - 1 Nabavke
    ?? "1" + cCSV
    // 5. redni broj datoteke
    ?? PADL( AllTrim(STR(nFileNo, 2)), 2, "0") + cCSV
    // 6. datum kreiranja YYY-MM-YY
    ?? STRTRAN(sql_quote(date()),"'","") + cCSV
    // 7. vrijeme
    ?? Time()

    hUkupno["bez"] := 0
    hUkupno["sa_pdv"] := 0
    hUkupno["paus"] := 0
    hUkupno["posl"] := 0
    hUkupno["np"] := 0
    hUkupno["np_32"] := 0
    hUkupno["np_33"] := 0
    hUkupno["np_34"] := 0
    hUkupno["redova"] := 0


    // 05 tip ostalo u CSV - usluge strana lica internet fakture
    gen_enabavke_stavke(@nRbr, dDatOd, dDatDo, cPorezniPeriod, "05", cIdKontoPDVUslugeStranaLica, cIdKontoPDVUslugeStranaLicaNP, cNabExcludeIdvn, cNabIdvn05, .T., .F., .F., @hUkupno)

    // 03 dati avansi
    gen_enabavke_stavke(@nRbr, dDatOd, dDatDo, cPorezniPeriod, "03", cIdKontoPDVAvansi, cIdKontoPDVAvansiNP, cNabExcludeIdvn, cNabIdvn05, .F., .F., .F., @hUkupno)

    // posebna schema u gradjevinarstvu
    gen_enabavke_stavke(@nRbr, dDatOd, dDatDo, cPorezniPeriod, "01", cIdKontoPDVSchema, cIdKontoPDVSchemaNP, cNabExcludeIdvn, cNabIdvn05, .F., .F., .T., @hUkupno)

    // poljoprivreda
    gen_enabavke_stavke(@nRbr, dDatOd, dDatDo, cPorezniPeriod, "05", cIdKontoPDVPolj, cIdKontoPDVPoljNP, cNabExcludeIdvn, cNabIdvn05, .F., .F., .F., @hUkupno)

    // 04 uvoz
    gen_enabavke_stavke(@nRbr, dDatOd, dDatDo, cPorezniPeriod, "04", cIdKontoPDVUvoz, cIdKontoPDVUvozNP, cNabExcludeIdvn, cNabIdvn05, .F., .F., .F., @hUkupno)

    // 05 - knjizenja ostalo 278
    gen_enabavke_stavke(@nRbr, dDatOd, dDatDo, cPorezniPeriod, "05", cIdKontoPDVOstalo, cIdKontoPDVOstaloNP, cNabExcludeIdvn, cNabIdvn05, .F., .F., .F., @hUkupno)


    // 01 standardne nabavke moraju biti na kraju
    gen_enabavke_stavke(@nRbr, dDatOd, dDatDo, cPorezniPeriod, "01", cIdKontoPDV, cIdKontoPDVNP, cNabExcludeIdvn, cNabIdvn05, .F., .T., .F., @hUkupno)

    
    // NEPDV obveznici i fakture koje ne sadrze PDV (npr postanske usluge)
    // gen_enabavke_stavke_pdv0(@nRbr, dDatOd, dDatDo, cPorezniPeriod, "02", cIdKontoPDVNP, cNabExcludeIdvn, .F., @hUkupno)


    // 1. 3 - prateći slog
    ? "3" + cCSV
    // 2. ukupan iznos faktura bez PDV
    ?? say_number( hUkupno["bez"] ) + cCSV
    // 3. ukupan iznos faktura sa PDV
    ?? say_number( hUkupno["sa_pdv"] ) + cCSV
    // 4. ukupan iznos poljop paushalne naknade
    ?? say_number( hUkupno["paus"] ) + cCSV
    // 5. ukupan iznos ulaznog pdv (sve)
    ?? say_number( hUkupno["posl"] + hUkupno["np"] ) + cCSV
    // 6. ukupan ulazni pdv koji se moze odbiti (poslovni)
    ?? say_number( hUkupno["posl"] ) + cCSV
    // 7. ukupan ulazni pdv koji se ne moze odbiti (vanposlovni)
    ?? say_number( hUkupno["np"] ) + cCSV
    // 8. ukupan PDV koji se ne moze odbiti 32 PDV prijava
    ?? say_number( hUkupno["np_32"] ) + cCSV
    // 9. ukupan PDV koji se ne moze odbiti 33 PDV prijava
    ?? say_number( hUkupno["np_33"] ) + cCSV
    // 10. ukupan PDV koji se ne moze odbiti 34 PDV prijava
    ?? say_number( hUkupno["np_34"] ) + cCSV
    // 11. ukupan broj redova (sirine 10)
    ?? AllTrim(Str(hUkupno["redova"] ))


    close_csv()
       
    DirChange( my_home() )
     
  
    f18_copy_to_desktop( cLokacijaExport, cExportFile, cExportFile )
     

    RETURN .T.
       
    

STATIC FUNCTION xlsx_export_fill_row()

        LOCAL nI
        LOCAL aKolona

      
        aKolona := {}
        AADD(aKolona, { "N", "Rbr. nabavke", 10, enab->enabavke_id })
        AADD(aKolona, { "C", "Tip", 3, enab->tip })

     
        AADD(aKolona, { "C", "Por.Per", 8, enab->porezni_period })
        AADD(aKolona, { "C", "Br.Fakt", 20, enab->br_fakt })
        AADD(aKolona, { "C", "JCI", 20, enab->jci })
        AADD(aKolona, { "D", "Dat.fakt", 12, enab->dat_fakt })
        AADD(aKolona, { "D", "Dat.f.prij", 12, enab->dat_fakt_prijem })

 
        AADD(aKolona, { "M", "Fakt dob.izn", 15, enab->fakt_iznos_dob })

        AADD(aKolona, { "C", "Dobavljac naziv", 60, enab->dob_naz })
        AADD(aKolona, { "C", "Dobavljac sjediste", 100, enab->dob_sjediste })

        AADD(aKolona, { "C", "Dob. PDV", 12, enab->dob_pdv })
        AADD(aKolona, { "C", "Dob. JIB", 13, enab->dob_jib })

        AADD(aKolona, { "M", "Osnov.PDV 0%", 15, enab->osn_pdv0 })
        AADD(aKolona, { "M", "Osn.PDV 17% posl", 15, enab->osn_pdv17 })
        AADD(aKolona, { "M", "Osn.PDV 17% nepo", 15, enab->osn_pdv17np }) 
        
        AADD(aKolona, { "M", "Fakt.BEZ PDV", 15, enab->fakt_iznos_bez_pdv })
        AADD(aKolona, { "M", "Fakt.SA PDV", 15, enab->fakt_iznos_sa_pdv })

       
        AADD(aKolona, { "M", "poljop. pausal", 15, enab->fakt_iznos_poljo_pausal })
        AADD(aKolona, { "M", "Ulazni PDV sve", 15, enab->fakt_iznos_pdv + enab->fakt_iznos_pdv_np })
        AADD(aKolona, { "M", "Ulazni PDV posl", 15, enab->fakt_iznos_pdv })
        AADD(aKolona, { "M", "Ulazni PDV neposl", 15, enab->fakt_iznos_pdv_np })
        AADD(aKolona, { "M", "PDV neposl 32", 15, enab->fakt_iznos_pdv_np_32 })
        AADD(aKolona, { "M", "PDV neposl 33", 15, enab->fakt_iznos_pdv_np_33 })
        AADD(aKolona, { "M", "PDV neposl 34", 15, enab->fakt_iznos_pdv_np_34 })
        AADD(aKolona, { "C", "Opis", 200, enab->opis })
        AADD(aKolona, { "C", "FIN nalog", 20, enab->fin_idfirma + "-" + enab->fin_idvn + "-" + enab->fin_brnal + "/" + Alltrim(Str(enab->fin_rbr)) })


        
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
     

        

FUNCTION export_eNabavke()


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
    s_cXlsxName := my_home_root() + "enabavke_" + dtos(dDatOd) + "_" + dtos(dDatDo) + ".xlsx"

    cQuery := "select * from public.enabavke where dat_fakt_prijem >=" + sql_quote(dDatOd) + " AND dat_fakt_prijem <=" + sql_quote(dDatDo)
    cQuery += " ORDER BY enabavke_id"

    SELECT F_TMP
    use_sql("ENAB", cQuery)
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


FUNCTION opis_enabavka(cIdKonto, cOpis)

    LOCAL pRegexJCI := hb_regexComp( "JCI:\s+([\d]+)" )
    LOCAL pRegexOsnPDV17 := hb_regexComp( "OSN-PDV17:\s*([\d.]+)" )
    LOCAL pRegexOsnPDV17NP := hb_regexComp( "OSN-PDV17NP:\s*([\d.]+)" )
    LOCAL pRegexOsnPDV0 := hb_regexComp( "OSN-PDV0:\s*([\d.]+)" )
    LOCAL pRegexDatFakt := hb_regexComp( "DAT-FAKT:\s*([\d.]+)" )
    LOCAL aMatch
    LOCAL hRez := hb_hash()
    LOCAL nX

    
    IF LEFT(cIdKonto, 3) $ "431#433"

        hRez[ "jci" ] := "UNDEF"
        hRez[ "osn_pdv17" ] := "UNDEF"
        hRez[ "osn_pdv17np" ] := "UNDEF"

        aMatch := hb_regex( pRegexJCI, cOpis )
        IF Len( aMatch ) > 0
           hRez[ "jci" ] := aMatch[ 2 ]
        ENDIF

        aMatch := hb_regex( pRegexOsnPDV17, cOpis )
        IF Len( aMatch ) > 0
           hRez[ "osn_pdv17" ] := aMatch[ 2 ]
        ENDIF

        aMatch := hb_regex( pRegexOsnPDV17NP, cOpis )
        IF Len( aMatch ) > 0
           hRez[ "osn_pdv17np" ] := aMatch[ 2 ]
        ENDIF

        Box(, 6, 60)
        @ box_x_koord() + 1, box_y_koord() + 2 SAY "Carinski dokument    : " + hRez["jci"]
        @ box_x_koord() + 2, box_y_koord() + 2 SAY "[JCI]             ->   " + hRez["jci"]


         @ box_x_koord() + 3, box_y_koord() + 2 SAY "osnovica PDV17-posl  : " + hRez["osn_pdv17"]
         @ box_x_koord() + 4, box_y_koord() + 2 SAY "[OSN-PDV17]       ->   " + Str(val(hRez["osn_pdv17"]), 12, 2)

         @ box_x_koord() + 5, box_y_koord() + 2 SAY "osnovica PDV17-neposl: " + hRez["osn_pdv17np"]
         @ box_x_koord() + 6, box_y_koord() + 2 SAY "[OSN-PDV17NP]     ->   " + Str(val(hRez["osn_pdv17np"]), 12, 2)
         inkey(0)
         BoxC()
      
    ENDIF


    hRez[ "dat_fakt" ] := "UNDEF"
    hRez[ "osn_pdv0" ] := "UNDEF"
    hRez[ "osn_pdv17" ] := "UNDEF"
    hRez[ "osn_pdv17np" ] := "UNDEF"

    IF LEFT(cIdKonto, 3) == "432"

        aMatch := hb_regex( pRegexDatFakt, cOpis )
        IF Len( aMatch ) > 0
           hRez[ "dat_fakt" ] := aMatch[ 2 ]
        ENDIF

        aMatch := hb_regex( pRegexOsnPDV0, cOpis )
        IF Len( aMatch ) > 0
           hRez[ "osn_pdv0" ] := aMatch[ 2 ]
        ENDIF

        aMatch := hb_regex( pRegexOsnPDV17, cOpis )
        IF Len( aMatch ) > 0
           hRez[ "osn_pdv17" ] := aMatch[ 2 ]
        ENDIF

        aMatch := hb_regex( pRegexOsnPDV17NP, cOpis )
        IF Len( aMatch ) > 0
           hRez[ "osn_pdv17np" ] := aMatch[ 2 ]
        ENDIF

        nX := 1
        Box(, 7, 60)

         @ box_x_koord() + nX++, box_y_koord() + 2 SAY "Datum fakture        : " + hRez["dat_fakt"]
         @ box_x_koord() + nX, box_y_koord() + 2 SAY "[DAT-FAKT]        ->   " + DToC(CtoD(hRez["dat_fakt"]))


         @ box_x_koord() + nX++, box_y_koord() + 2 SAY "osnovica PDV0        : " + hRez["osn_pdv0"]
         @ box_x_koord() + nX, box_y_koord() + 2 SAY "[OSN-PDV0]        ->   " + Str(val(hRez["osn_pdv0"]), 12, 2)

         @ box_x_koord() + nX++, box_y_koord() + 2 SAY "osnovica PDV17-posl  : " + hRez["osn_pdv17"]
         @ box_x_koord() + nX, box_y_koord() + 2 SAY "[OSN-PDV17]       ->   " + Str(val(hRez["osn_pdv17"]), 12, 2)

         @ box_x_koord() + nX++, box_y_koord() + 2 SAY "osnovica PDV17-neposl: " + hRez["osn_pdv17np"]
         @ box_x_koord() + nX, box_y_koord() + 2 SAY "[OSN-PDV17NP]     ->   " + Str(val(hRez["osn_pdv17np"]), 12, 2)
         inkey(0) 
        BoxC()

    ENDIF

    RETURN .T.




FUNCTION fin_gen_uvoz(cBrKalk, dDatDok, cIdDobavljac, cBrFakt, nDobavIznos, nSpedIznos, nPrevoznikIznos)

    LOCAL nX := 1
    LOCAL GetList := {}
    LOCAL nJCI := 0
    LOCAL cPictIznos := "99999999.99"

    LOCAL hParams := hb_hash()
    LOCAL hRec := hb_hash()
    LOCAL cKey, nRbr
    LOCAL nTmp

 

    IF cBrKalk <> NIL
        set_metric("fin_uvoz_kalk_brdok", my_user(), cBrKalk )
        hParams["fin_uvoz_kalk_brdok"] := cBrKalk
    ELSE
        hParams["fin_uvoz_kalk_brdok"]:= PADR(fetch_metric("fin_uvoz_kalk_brdok", my_user(), "" ), 8)
    ENDIF

    hParams["fin_uvoz_fin_idvn"]:= PADR(fetch_metric("fin_uvoz_fin_idvn", my_user(), "10" ), 2)
    
    IF cBrKalk <> NIL
       hParams["fin_uvoz_fin_brnal"] := cBrKalk
    ELSE
       hParams["fin_uvoz_fin_brnal"] := REPLICATE("0", 8)
    ENDIF
   
    hParams["fin_uvoz_jci_broj"]:= fetch_metric( "fin_uvoz_jci_broj", my_user(), 0 )

    IF dDatDok <> NIL
        hParams["fin_uvoz_jci_datdok"]:= dDatDok
        hParams["fin_uvoz_jci_datprij"]:= dDatDok
        set_metric( "fin_uvoz_jci_datdok", my_user(), dDatDok )
        set_metric( "fin_uvoz_jci_datprij", my_user(), dDatDok )
    ELSE
       hParams["fin_uvoz_jci_datdok"]:= fetch_metric( "fin_uvoz_jci_datdok", my_user(), CTOD("") )
       hParams["fin_uvoz_jci_datprij"]:= fetch_metric( "fin_uvoz_jci_datprij", my_user(), CTOD("") )
    ENDIF

    hParams["fin_uvoz_jci_pdv_kto"]:= PADR(fetch_metric( "fin_uvoz_jci_pdv_kto", my_user(), "2710" ), 7)
    hParams["fin_uvoz_jci_pdv_np_kto"]:= PADR(fetch_metric( "fin_uvoz_jci_pdv_np_kto", my_user(), "27691" ), 7)
    hParams["fin_uvoz_jci_pdv_iznos"]:= fetch_metric( "fin_uvoz_jci_pdv_iznos", my_user(), 0 )
    hParams["fin_uvoz_jci_pdv_np_iznos"]:= fetch_metric( "fin_uvoz_jci_pdv_np_iznos", my_user(), 0 )
    hParams["fin_uvoz_jci_kto_potraz"]:= PADR(fetch_metric( "fin_uvoz_jci_kto_potraz", my_user(), "4840" ), 7)

    hParams["fin_uvoz_dob_kto"]:= PADR(fetch_metric("fin_uvoz_dob_kto", my_user(), "4330" ), 7)

    IF cIdDobavljac <> NIL
        hParams["fin_uvoz_dob_partn"] := cIdDobavljac
        set_metric( "fin_uvoz_dob_partn", my_user(), cIdDobavljac )
    ELSE
        hParams["fin_uvoz_dob_partn"]:= PADR(fetch_metric( "fin_uvoz_dob_partn", my_user(), "" ), 6)
    ENDIF

    IF cBrFakt <> NIL
       hParams["fin_uvoz_dob_brdok"]:= cBrFakt
       set_metric( "fin_uvoz_dob_brdok", my_user(), cBrFakt )
    ELSE
       hParams["fin_uvoz_dob_brdok"]:= PADR(fetch_metric( "fin_uvoz_dob_brdok", my_user(), "" ), 10)
    ENDIF

    IF dDatDok <> NIL
        hParams["fin_uvoz_dob_datdok"]:= dDatDok
        hParams["fin_uvoz_dob_datval"]:= CTOD("")
        set_metric( "fin_uvoz_dob_datdok", my_user(), dDatDok )
        set_metric( "fin_uvoz_dob_datval", my_user(), CTOD("") )
    ELSE
       hParams["fin_uvoz_dob_datdok"]:= fetch_metric( "fin_uvoz_dob_datdok", my_user(), CTOD("") )
       hParams["fin_uvoz_dob_datval"]:= fetch_metric( "fin_uvoz_dob_datval", my_user(), CTOD("") )
    ENDIF
    

    IF nDobavIznos <> NIL
       hParams["fin_uvoz_dob_iznos"]:= nDobavIznos
       set_metric( "fin_uvoz_dob_iznos", my_user(), nDobavIznos )
    ELSE
       hParams["fin_uvoz_dob_iznos"]:= fetch_metric( "fin_uvoz_dob_iznos", my_user(), 0.00 )
    ENDIF
    hParams["fin_uvoz_sped_kto"]:= PADR(fetch_metric("fin_uvoz_sped_kto", my_user(), "4320" ), 7)
    hParams["fin_uvoz_sped_partn"]:= PADR(fetch_metric( "fin_uvoz_sped_partn", my_user(), "" ), 6)
    hParams["fin_uvoz_sped_brdok"]:= PADR(fetch_metric( "fin_uvoz_sped_brdok", my_user(), "" ), 10)
    
    IF dDatDok <> NIL
        hParams["fin_uvoz_sped_datdok"]:= dDatDok
        hParams["fin_uvoz_sped_datval"]:= CTOD("")
        set_metric( "fin_uvoz_sped_datdok", my_user(), dDatDok )
        set_metric( "fin_uvoz_sped_datval", my_user(), CTOD("") )
    ELSE
       hParams["fin_uvoz_sped_datdok"]:= fetch_metric( "fin_uvoz_sped_datdok", my_user(), CTOD("") )
       hParams["fin_uvoz_sped_datval"]:= fetch_metric( "fin_uvoz_sped_datval", my_user(), CTOD("") )
    ENDIF
    
    hParams["fin_uvoz_sped_osn_pdv0"]:= fetch_metric( "fin_uvoz_sped_osn_pdv0", my_user(), 0.00 )
    
    IF nSpedIznos <> NIL
        hParams["fin_uvoz_sped_iznos"] := nSpedIznos
        set_metric( "fin_uvoz_sped_iznos", my_user(), nSpedIznos )
    ELSE
       hParams["fin_uvoz_sped_iznos"]:= fetch_metric( "fin_uvoz_sped_iznos", my_user(), 0.00 )
    ENDIF
    hParams["fin_uvoz_sped_pdv_iznos"]:= fetch_metric( "fin_uvoz_sped_pdv_iznos", my_user(), 0 )
    hParams["fin_uvoz_sped_pdv_np_iznos"]:= fetch_metric( "fin_uvoz_sped_pdv_np_iznos", my_user(), 0 )

    hParams["fin_uvoz_prev_kto"]:= PADR(fetch_metric("fin_uvoz_prev_kto", my_user(), "4320" ), 7)
    hParams["fin_uvoz_prev_partn"]:= PADR(fetch_metric( "fin_uvoz_prev_partn", my_user(), "" ), 6)
    hParams["fin_uvoz_prev_brdok"]:= PADR(fetch_metric( "fin_uvoz_prev_brdok", my_user(), "" ), 10)
    IF dDatDok <> NIL
        hParams["fin_uvoz_prev_datdok"]:= dDatDok 
        hParams["fin_uvoz_prev_datval"]:= CTOD("")
        set_metric( "fin_uvoz_prev_datdok", my_user(), dDatDok)
        set_metric( "fin_uvoz_prev_datval", my_user(), CTOD(""))
    ELSE
       hParams["fin_uvoz_prev_datdok"]:= fetch_metric( "fin_uvoz_prev_datdok", my_user(), CTOD("") )
    ENDIF
    hParams["fin_uvoz_prev_datval"]:= fetch_metric( "fin_uvoz_prev_datval", my_user(), CTOD("") )
    hParams["fin_uvoz_prev_osn_pdv0"]:= fetch_metric( "fin_uvoz_prev_osn_pdv0", my_user(), 0.00 )
    IF nPrevoznikIznos <> NIL
        hParams["fin_uvoz_prev_iznos"] := nPrevoznikIznos
        set_metric( "fin_uvoz_prev_iznos", my_user(), nPrevoznikIznos )
    ELSE
       hParams["fin_uvoz_prev_iznos"]:= fetch_metric( "fin_uvoz_prev_iznos", my_user(), 0.00 )
    ENDIF
    hParams["fin_uvoz_prev_pdv_iznos"]:= fetch_metric( "fin_uvoz_prev_pdv_iznos", my_user(), 0 )
    hParams["fin_uvoz_prev_pdv_np_iznos"]:= fetch_metric( "fin_uvoz_prev_pdv_np_iznos", my_user(), 0 )


    hParams["fin_uvoz_kto_prevalm_potraz"]:= PADR(fetch_metric( "fin_uvoz_kto_prevalm_potraz", my_user(), "4823" ), 7)
    hParams["fin_uvoz_prevalm_iznos"]:= fetch_metric( "fin_uvoz_prevalm_iznos", my_user(), 0.0 )

    hParams["fin_uvoz_kto_car_potraz"]:= PADR(fetch_metric( "fin_uvoz_kto_car_potraz", my_user(), "4820" ), 7)
    hParams["fin_uvoz_car_iznos"]:= fetch_metric( "fin_uvoz_car_iznos", my_user(), 0.0 )

    hParams["fin_uvoz_kto_akcize_potraz"]:= PADR(fetch_metric( "fin_uvoz_kto_akcize_potraz", my_user(), "4802" ), 7)
    hParams["fin_uvoz_akcize_iznos"]:= fetch_metric( "fin_uvoz_akcize_iznos", my_user(), 0.0 )

    hParams["fin_uvoz_van_jci_pdv"]:= PADR(fetch_metric( "fin_uvoz_van_jci_pdv", my_user(), "2700" ), 7)
    hParams["fin_uvoz_van_jci_pdv_np"]:= PADR(fetch_metric( "fin_uvoz_van_jci_pdv_np", my_user(), "27690" ), 7)

    hParams["fin_uvoz_kto_roba"]:= PADR(fetch_metric( "fin_uvoz_kto_roba", my_user(), "1320" ), 7)
    hParams["fin_uvoz_kto_np"]:= PADR(fetch_metric( "fin_uvoz_kto_np", my_user(), "5510" ), 7)
    
    PUBLIC gBrojacKalkulacija := fetch_metric( "kalk_brojac_kalkulacija", nil, "D" )
    kalk_duzina_brojaca_dokumenta()

    Box(, 23, 102)

       @ box_x_koord() + nX, box_y_koord() + 2 SAY "KALK 10 -" GET hParams["fin_uvoz_kalk_brdok"]  VALID {|| hParams["fin_uvoz_kalk_brdok"] := kalk_fix_brdok( hParams["fin_uvoz_kalk_brdok"] ), .T. }
       @ box_x_koord() + nX, col() + 2 SAY "FIN vrsta naloga: " GET hParams["fin_uvoz_fin_idvn"]
       @ box_x_koord() + nX++, col() + 2 SAY "broj naloga: " GET hParams["fin_uvoz_fin_brnal"]

       nX++
       @ box_x_koord() + nX, box_y_koord() + 2 SAY "JCI:" GET hParams["fin_uvoz_jci_broj"] PICT "99999999" VALID hParams["fin_uvoz_jci_broj"] > 0
       @ box_x_koord() + nX, col() + 2 SAY "datum JCI:" GET hParams["fin_uvoz_jci_datdok"] VALID !Empty(hParams["fin_uvoz_jci_datdok"])
       @ box_x_koord() + nX, col() + 2 SAY "datum prijema:" GET hParams["fin_uvoz_jci_datprij"] VALID !Empty(hParams["fin_uvoz_jci_datprij"]) .AND. ;
           hParams["fin_uvoz_jci_datprij"] >= hParams["fin_uvoz_jci_datdok"]

       @ box_x_koord() + nX++, col() + 2 SAY8 "Kto potraž:" GET hParams["fin_uvoz_jci_kto_potraz"] VALID P_Konto(@hParams["fin_uvoz_jci_kto_potraz"])
       
       @ box_x_koord() + nX, box_y_koord() + 2 SAY "PDV JCI kto:" GET hParams["fin_uvoz_jci_pdv_kto"]
       @ box_x_koord() + nX, col() + 2 SAY "iznos:" GET hParams["fin_uvoz_jci_pdv_iznos"] PICT cPictIznos
       @ box_x_koord() + nX, col() + 2 SAY "PDV JCI vanspolovno (NP) kto:" GET hParams["fin_uvoz_jci_pdv_np_kto"]  
       @ box_x_koord() + nX, col() + 2 SAY "iznos:" GET hParams["fin_uvoz_jci_pdv_np_iznos"] PICT cPictIznos ;
            VALID hParams["fin_uvoz_jci_pdv_iznos"] + hParams["fin_uvoz_jci_pdv_np_iznos"] > 0

       nX += 2
       @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Dobavljač kto:" GET hParams["fin_uvoz_dob_kto"]
       @ box_x_koord() + nX++, col() + 2 SAY8 "partn:" GET hParams["fin_uvoz_dob_partn"] VALID P_Partner(@hParams["fin_uvoz_dob_partn"])
       @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "   br.fakt:" GET hParams["fin_uvoz_dob_brdok"]
       @ box_x_koord() + nX, col() + 2 SAY8 "dat.fakt:" GET hParams["fin_uvoz_dob_datdok"] ;
           WHEN {|| hParams["fin_uvoz_dob_datdok"] := IIF(Empty(hParams["fin_uvoz_dob_datdok"]), hParams["fin_uvoz_jci_datprij"], hParams["fin_uvoz_dob_datdok"]), .T.} ;
           VALID !Empty(hParams["fin_uvoz_dob_datdok"])
       @ box_x_koord() + nX, col() + 2 SAY8 "dat.val:" GET hParams["fin_uvoz_dob_datval"]
       @ box_x_koord() + nX, col() + 2 SAY8 "faktura dobavljac iznos:" GET hParams["fin_uvoz_dob_iznos"] PICT cPictIznos
 
       nX += 2
       @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Konto PDV (van JCI) spediter/prevoznik poslovni:" GET hParams["fin_uvoz_van_jci_pdv"]
       @ box_x_koord() + nX, col() + 2 SAY8 "vanposlovni:" GET hParams["fin_uvoz_van_jci_pdv_np"]

       nX += 2
       @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Špediter kto :" GET hParams["fin_uvoz_sped_kto"]
       @ box_x_koord() + nX++, col() + 2 SAY8 "partn:" GET hParams["fin_uvoz_sped_partn"] VALID Empty(hParams["fin_uvoz_sped_partn"]) .OR. P_Partner(@hParams["fin_uvoz_sped_partn"])
       @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "   br.fakt:" GET hParams["fin_uvoz_sped_brdok"] ;
            VALID !Empty(hParams["fin_uvoz_sped_brdok"]) .OR. Empty(hParams["fin_uvoz_sped_partn"])
       @ box_x_koord() + nX, col() + 2 SAY8 "dat.fakt:" GET hParams["fin_uvoz_sped_datdok"] ;
            WHEN {|| hParams["fin_uvoz_sped_datdok"] := IIF(Empty(hParams["fin_uvoz_sped_datdok"]), hParams["fin_uvoz_jci_datprij"], hParams["fin_uvoz_sped_datdok"]), .T.} ;
            VALID !Empty(hParams["fin_uvoz_sped_datdok"]) .OR. Empty(hParams["fin_uvoz_sped_partn"])
       @ box_x_koord() + nX, col() + 2 SAY8 "dat.val:" GET hParams["fin_uvoz_sped_datval"]
       @ box_x_koord() + nX++, col() + 2 SAY8 "faktura spediter iznos:" GET hParams["fin_uvoz_sped_iznos"] PICT cPictIznos
       @ box_x_koord() + nX, box_y_koord() + 2 SAY "osn PDV 0% (van JCI) :" GET hParams["fin_uvoz_sped_osn_pdv0"]  
       @ box_x_koord() + nX, col() + 2 SAY "PDV van JCI iznos:" GET hParams["fin_uvoz_sped_pdv_iznos"]  PICT cPictIznos
       @ box_x_koord() + nX, col() + 2 SAY "PDV van JCI NP izn:" GET hParams["fin_uvoz_sped_pdv_np_iznos"] PICT cPictIznos

       nX += 2
       @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Prevoznik kto :" GET hParams["fin_uvoz_sped_kto"]
       @ box_x_koord() + nX++, col() + 2 SAY8 "partn:" GET hParams["fin_uvoz_prev_partn"] VALID Empty(hParams["fin_uvoz_prev_partn"]) .OR. P_Partner(@hParams["fin_uvoz_prev_partn"]) 
       @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "  br.fakt:" GET hParams["fin_uvoz_prev_brdok"] ;
           VALID !Empty(hParams["fin_uvoz_prev_brdok"]) .OR. Empty(hParams["fin_uvoz_prev_partn"])
       @ box_x_koord() + nX, col() + 2 SAY8 "dat.fakt:" GET hParams["fin_uvoz_prev_datdok"] ;
           WHEN {|| hParams["fin_uvoz_prev_datdok"] := IIF(Empty(hParams["fin_uvoz_prev_datdok"]), hParams["fin_uvoz_jci_datprij"], hParams["fin_uvoz_prev_datdok"]), .T.} ;
           VALID !Empty(hParams["fin_uvoz_prev_datdok"]) .OR. Empty(hParams["fin_uvoz_prev_partn"])
       @ box_x_koord() + nX, col() + 2 SAY8 "dat.val:" GET hParams["fin_uvoz_prev_datval"]    
       @ box_x_koord() + nX++, col() + 2 SAY8 "faktura prevoz iznos:" GET hParams["fin_uvoz_prev_iznos"] PICT cPictIznos
       @ box_x_koord() + nX, box_y_koord() + 2 SAY "osn PDV 0% (van JCI) :" GET hParams["fin_uvoz_prev_osn_pdv0"] 
       @ box_x_koord() + nX, col() + 2 SAY "PDV van JCI iznos:" GET hParams["fin_uvoz_prev_pdv_iznos"]  PICT cPictIznos
       @ box_x_koord() + nX, col() + 2 SAY "PDV van JCI NP izn:" GET hParams["fin_uvoz_prev_pdv_np_iznos"] PICT cPictIznos

       nX += 2
       @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Prevalmani kto potraž :" GET hParams["fin_uvoz_kto_prevalm_potraz"]
       @ box_x_koord() + nX++, col() + 2 SAY8 "iznos" GET hParams["fin_uvoz_prevalm_iznos"] PICT cPictIznos

       @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "    Carina kto potraž :" GET hParams["fin_uvoz_kto_car_potraz"]
       @ box_x_koord() + nX++, col() + 2 SAY8 "iznos" GET hParams["fin_uvoz_car_iznos"] PICT cPictIznos

       @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "    Akcize kto potraž :" GET hParams["fin_uvoz_kto_akcize_potraz"]
       @ box_x_koord() + nX++, col() + 2 SAY8 "iznos" GET hParams["fin_uvoz_akcize_iznos"] PICT cPictIznos

       nX++
       @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "  Roba zadužuje kto :" GET hParams["fin_uvoz_kto_roba"]
       @ box_x_koord() + nX, col() + 2 SAY8 "vansposlovna potrošnja kto :" GET hParams["fin_uvoz_kto_np"]

       READ
    BoxC()

    IF LastKey() == K_ESC
       RETURN .F.
    ENDIF


    FOR EACH cKey in { "fin_uvoz_kalk_brdok", "fin_uvoz_fin_idvn", "fin_uvoz_jci_broj", "fin_uvoz_jci_datdok",;
      "fin_uvoz_jci_datprij", "fin_uvoz_jci_pdv_kto", "fin_uvoz_jci_pdv_np_kto", "fin_uvoz_jci_pdv_iznos",;
      "fin_uvoz_jci_pdv_np_iznos", "fin_uvoz_jci_kto_potraz", "fin_uvoz_dob_kto", "fin_uvoz_dob_partn", "fin_uvoz_dob_brdok",;
      "fin_uvoz_dob_datdok", "fin_uvoz_dob_datval", "fin_uvoz_dob_iznos", "fin_uvoz_sped_kto", "fin_uvoz_sped_partn", "fin_uvoz_sped_brdok",;
      "fin_uvoz_sped_datdok", "fin_uvoz_sped_datval", "fin_uvoz_sped_osn_pdv0", "fin_uvoz_sped_iznos", "fin_uvoz_sped_pdv_iznos", "fin_uvoz_sped_pdv_np_iznos",;
      "fin_uvoz_prev_kto", "fin_uvoz_prev_partn", "fin_uvoz_prev_brdok", "fin_uvoz_prev_datdok", "fin_uvoz_prev_datval", "fin_uvoz_prev_osn_pdv0",;
      "fin_uvoz_prev_iznos", "fin_uvoz_prev_pdv_iznos", "fin_uvoz_prev_pdv_np_iznos", "fin_uvoz_kto_prevalm_potraz", "fin_uvoz_prevalm_iznos",;
      "fin_uvoz_kto_car_potraz", "fin_uvoz_car_iznos", "fin_uvoz_kto_akcize_potraz", "fin_uvoz_akcize_iznos", "fin_uvoz_van_jci_pdv",;
      "fin_uvoz_van_jci_pdv_np", "fin_uvoz_kto_roba", "fin_uvoz_kto_np" }
      set_metric( cKey, my_user(), hParams[ cKey] )
    NEXT


    o_fin_edit()
    my_flock()

    nRbr := 1

    APPEND BLANK
    hRec := dbf_get_rec()

    hRec["idfirma"] := "10"
    hRec["idvn"] := hParams["fin_uvoz_fin_idvn"]
    hRec["brnal"] := hParams["fin_uvoz_fin_brnal"]

    // dobavljac robe potrazuje
    hRec["rbr"] := nRbr++
    hRec["opis"] := ""
    hRec["brdok"] := hParams["fin_uvoz_dob_brdok"]
    hRec["datdok"] := hParams["fin_uvoz_jci_datprij"]
    hRec["opis"] := "JCI: " + Alltrim(Str(hParams["fin_uvoz_jci_broj"])) + ","
    IF hParams["fin_uvoz_jci_datprij"] <>  hParams["fin_uvoz_jci_datdok"]
        hRec["opis"] += " DAT-FAKT: " + DTOC(hParams["fin_uvoz_jci_datdok"])
    ENDIF
    hRec["datval"] := hParams["fin_uvoz_dob_datval"]
    hRec["idkonto"] := hParams["fin_uvoz_dob_kto"]
    hRec["idpartner"] := hParams["fin_uvoz_dob_partn"]
    hRec["d_p"] := "2"
    hRec["iznosbhd"] := hParams["fin_uvoz_dob_iznos"]
    hRec["iznosdem"] := fin_km_to_eur(hRec["iznosbhd"], hParams["fin_uvoz_jci_datprij"])
    dbf_update_rec( hRec )


    // PDV JCI duguje
    IF hParams["fin_uvoz_jci_pdv_iznos"] > 0
      APPEND BLANK
      hRec["rbr"] := nRbr++
      hRec["opis"] := ""
      hRec["brdok"] := hParams["fin_uvoz_dob_brdok"]
      hRec["datdok"] := hParams["fin_uvoz_jci_datprij"]
      hRec["datval"] := CTOD("")
      hRec["idkonto"] := hParams["fin_uvoz_jci_pdv_kto"] 
      hRec["idpartner"] := ""
      hRec["d_p"] := "1"
      hRec["iznosbhd"] := hParams["fin_uvoz_jci_pdv_iznos"]
      hRec["iznosdem"] := fin_km_to_eur(hRec["iznosbhd"], hParams["fin_uvoz_jci_datprij"])
      dbf_update_rec( hRec )
    ENDIF

    // PDV uvoz NP JCI duguje
    IF hParams["fin_uvoz_jci_pdv_np_iznos"] > 0
        APPEND BLANK
        hRec["rbr"] := nRbr++
        hRec["opis"] := "PDV uvoz neposlovna potrosnja"
        hRec["brdok"] := hParams["fin_uvoz_dob_brdok"]
        hRec["datdok"] := hParams["fin_uvoz_jci_datprij"]
        hRec["datval"] := CTOD("")
        hRec["idkonto"] := hParams["fin_uvoz_jci_pdv_np_kto"] 
        hRec["idpartner"] := ""
        hRec["d_p"] := "1"
        hRec["iznosbhd"] := hParams["fin_uvoz_jci_pdv_np_iznos"]
        hRec["iznosdem"] := fin_km_to_eur(hRec["iznosbhd"], hParams["fin_uvoz_jci_datprij"])
        dbf_update_rec( hRec )

        APPEND BLANK
        hRec["rbr"] := nRbr++
        hRec["opis"] := "protustav PDV uvoz neposlovna potrosnja"
        hRec["brdok"] := ""
        hRec["datdok"] := hParams["fin_uvoz_jci_datprij"]
        hRec["datval"] := CTOD("")
        hRec["idkonto"] := hParams["fin_uvoz_jci_pdv_np_kto"] 
        hRec["idpartner"] := ""
        hRec["d_p"] := "2"
        hRec["iznosbhd"] := hParams["fin_uvoz_jci_pdv_np_iznos"]
        hRec["iznosdem"] := fin_km_to_eur(hRec["iznosbhd"], hParams["fin_uvoz_jci_datprij"])
        dbf_update_rec( hRec )
    ENDIF

    // jci UIO potrazuje
    APPEND BLANK
    hRec["rbr"] := nRbr++
    hRec["opis"] := ""
    hRec["brdok"] := Alltrim(Str(hParams["fin_uvoz_jci_broj"]))
    hRec["datdok"] := hParams["fin_uvoz_jci_datprij"]
    hRec["datval"] := CTOD("")
    hRec["idkonto"] := hParams["fin_uvoz_jci_kto_potraz"]
    hRec["idpartner"] := ""
    hRec["d_p"] := "2"
    hRec["iznosbhd"] := hParams["fin_uvoz_jci_pdv_iznos"] + hParams["fin_uvoz_jci_pdv_np_iznos"]
    hRec["iznosdem"] := fin_km_to_eur(hRec["iznosbhd"], hParams["fin_uvoz_jci_datprij"])
    dbf_update_rec( hRec )

    IF ROUND(hParams["fin_uvoz_prevalm_iznos"], 2) > 0
        // prevalmani potrazuje
        APPEND BLANK
        hRec["rbr"] := nRbr++
        hRec["opis"] := "obaveze prevalmani"
        hRec["brdok"] := Alltrim(Str(hParams["fin_uvoz_jci_broj"]))
        hRec["datdok"] := hParams["fin_uvoz_jci_datprij"]
        hRec["datval"] := CTOD("")
        hRec["idkonto"] := hParams["fin_uvoz_kto_prevalm_potraz"]
        hRec["idpartner"] := ""
        hRec["d_p"] := "2"
        hRec["iznosbhd"] := hParams["fin_uvoz_prevalm_iznos"]
        hRec["iznosdem"] := fin_km_to_eur(hRec["iznosbhd"], hParams["fin_uvoz_jci_datprij"])
        dbf_update_rec( hRec )
    ENDIF

    IF ROUND(hParams["fin_uvoz_car_iznos"], 2) > 0
        // carine potrazuje
        APPEND BLANK
        hRec["rbr"] := nRbr++
        hRec["opis"] := "obaveze carine"
        hRec["brdok"] := Alltrim(Str(hParams["fin_uvoz_jci_broj"]))
        hRec["datdok"] := hParams["fin_uvoz_jci_datprij"]
        hRec["datval"] := CTOD("")
        hRec["idkonto"] := hParams["fin_uvoz_kto_car_potraz"]
        hRec["idpartner"] := ""
        hRec["d_p"] := "2"
        hRec["iznosbhd"] := hParams["fin_uvoz_car_iznos"]
        hRec["iznosdem"] := fin_km_to_eur(hRec["iznosbhd"], hParams["fin_uvoz_jci_datprij"])
        dbf_update_rec( hRec )
    ENDIF

    IF ROUND(hParams["fin_uvoz_akcize_iznos"], 2) > 0
        // akcize potrazuje
        APPEND BLANK
        hRec["rbr"] := nRbr++
        hRec["opis"] := "obaveze akcize"
        hRec["brdok"] := Alltrim(Str(hParams["fin_uvoz_jci_broj"]))
        hRec["datdok"] := hParams["fin_uvoz_jci_datprij"]
        hRec["datval"] := CTOD("")
        hRec["idkonto"] := hParams["fin_uvoz_kto_akcize_potraz"]
        hRec["idpartner"] := ""
        hRec["d_p"] := "2"
        hRec["iznosbhd"] := hParams["fin_uvoz_akcize_iznos"]
        hRec["iznosdem"] := fin_km_to_eur(hRec["iznosbhd"], hParams["fin_uvoz_jci_datprij"])
        dbf_update_rec( hRec )
    ENDIF

    IF !Empty(hParams["fin_uvoz_sped_partn"])
        // spediter
        APPEND BLANK
        hRec["rbr"] := nRbr++
        hRec["opis"] := "spediter "
        hRec["opis"] += "OSN-PDV0: " + AllTrim(Transform(hParams["fin_uvoz_sped_osn_pdv0"], cPictIznos))
        hRec["brdok"] := hParams["fin_uvoz_sped_brdok"]
        hRec["datdok"] := hParams["fin_uvoz_sped_datdok"]
        hRec["datval"] := hParams["fin_uvoz_sped_datval"]
        hRec["idkonto"] := hParams["fin_uvoz_sped_kto"]
        hRec["idpartner"] := hParams["fin_uvoz_sped_partn"]
        hRec["d_p"] := "2"
        hRec["iznosbhd"] := hParams["fin_uvoz_sped_iznos"]
        hRec["iznosdem"] := fin_km_to_eur(hRec["iznosbhd"], hParams["fin_uvoz_jci_datprij"])
        dbf_update_rec( hRec )

        IF hParams["fin_uvoz_sped_pdv_iznos"] <> 0
            // spediter PDV poslovni
            APPEND BLANK
            hRec["rbr"] := nRbr++
            hRec["opis"] := "spediter van JCI PDV poslovni"
            hRec["brdok"] := hParams["fin_uvoz_sped_brdok"]
            hRec["datdok"] := hParams["fin_uvoz_sped_datdok"]
            hRec["datval"] := CTOD("")
            hRec["idkonto"] := hParams["fin_uvoz_van_jci_pdv"]
            hRec["idpartner"] := ""
            hRec["d_p"] := "1"
            hRec["iznosbhd"] := hParams["fin_uvoz_sped_pdv_iznos"]
            hRec["iznosdem"] := fin_km_to_eur(hRec["iznosbhd"], hParams["fin_uvoz_jci_datprij"])
            dbf_update_rec( hRec )
        ENDIF


        IF hParams["fin_uvoz_sped_pdv_np_iznos"] <> 0
            // spediter PDV vanposlovni
            APPEND BLANK
            hRec["rbr"] := nRbr++
            hRec["opis"] := "spediter van JCI PDV vanposlovni"
            hRec["brdok"] := hParams["fin_uvoz_sped_brdok"]
            hRec["datdok"] := hParams["fin_uvoz_sped_datdok"]
            hRec["datval"] := CTOD("")
            hRec["idkonto"] := hParams["fin_uvoz_van_jci_pdv_np"]
            hRec["idpartner"] := ""
            hRec["d_p"] := "1"
            hRec["iznosbhd"] := hParams["fin_uvoz_sped_pdv_np_iznos"]
            hRec["iznosdem"] := fin_km_to_eur(hRec["iznosbhd"], hParams["fin_uvoz_jci_datprij"])
            dbf_update_rec( hRec )

            APPEND BLANK
            // spediter PDV vanposlovni protustav
            hRec["rbr"] := nRbr++
            hRec["opis"] := "spediter van JCI PDV vanposlovni protustav"
            hRec["brdok"] := ""
            hRec["datdok"] := hParams["fin_uvoz_sped_datdok"]
            hRec["datval"] := CTOD("")
            hRec["idkonto"] := hParams["fin_uvoz_van_jci_pdv_np"]
            hRec["idpartner"] := ""
            hRec["d_p"] := "2"
            hRec["iznosbhd"] := hParams["fin_uvoz_sped_pdv_np_iznos"]
            hRec["iznosdem"] := fin_km_to_eur(hRec["iznosbhd"], hParams["fin_uvoz_jci_datprij"])
            dbf_update_rec( hRec )

        ENDIF
    ENDIF

    IF !Empty(hParams["fin_uvoz_prev_partn"])
        // prevoznik
        APPEND BLANK
        hRec["rbr"] := nRbr++
        hRec["opis"] := "prevoz "
        hRec["opis"] += "OSN-PDV0: " + AllTrim(Transform(hParams["fin_uvoz_prev_osn_pdv0"], cPictIznos))
        hRec["brdok"] := hParams["fin_uvoz_prev_brdok"]
        hRec["datdok"] := hParams["fin_uvoz_prev_datdok"]
        hRec["datval"] := hParams["fin_uvoz_prev_datval"]
        hRec["idkonto"] := hParams["fin_uvoz_prev_kto"]
        hRec["idpartner"] := hParams["fin_uvoz_prev_partn"]
        hRec["d_p"] := "2"
        hRec["iznosbhd"] := hParams["fin_uvoz_prev_iznos"]
        hRec["iznosdem"] := fin_km_to_eur(hRec["iznosbhd"], hParams["fin_uvoz_jci_datprij"])
        dbf_update_rec( hRec )

        IF hParams["fin_uvoz_prev_pdv_iznos"] <> 0
            // prevoz PDV poslovni
            APPEND BLANK
            hRec["rbr"] := nRbr++
            hRec["opis"] := "prevoz van JCI PDV poslovni"
            hRec["datdok"] := hParams["fin_uvoz_prev_datdok"]
            hRec["datval"] := CTOD("")
            hRec["brdok"] := hParams["fin_uvoz_prev_brdok"]
            hRec["idkonto"] := hParams["fin_uvoz_van_jci_pdv"]
            hRec["idpartner"] := ""
            hRec["d_p"] := "1"
            hRec["iznosbhd"] := hParams["fin_uvoz_prev_pdv_iznos"]
            hRec["iznosdem"] := fin_km_to_eur(hRec["iznosbhd"], hParams["fin_uvoz_jci_datprij"])
            dbf_update_rec(hRec)  
        ENDIF


        IF hParams["fin_uvoz_prev_pdv_np_iznos"] <> 0
            // prevoz PDV vanposlovni
            APPEND BLANK
            hRec["rbr"] := nRbr++
            hRec["opis"] := "prevoz van JCI PDV vanposlovni"
            hRec["brdok"] := hParams["fin_uvoz_prev_brdok"]
            hRec["datdok"] := hParams["fin_uvoz_prev_datdok"]
            hRec["datval"] := CTOD("")
            hRec["idkonto"] := hParams["fin_uvoz_van_jci_pdv_np"]
            hRec["idpartner"] := ""
            hRec["d_p"] := "1"
            hRec["iznosbhd"] := hParams["fin_uvoz_prev_pdv_np_iznos"]
            hRec["iznosdem"] := fin_km_to_eur(hRec["iznosbhd"], hParams["fin_uvoz_jci_datprij"])
            dbf_update_rec(hRec )

            // prevoz PDV vanposlovni protustav
            APPEND BLANK
            hRec["rbr"] := nRbr++
            hRec["opis"] := "prevoz van JCI PDV vanposlovni protustav"
            hRec["brdok"] := ""
            hRec["datdok"] := hParams["fin_uvoz_prev_datdok"]
            hRec["datval"] := CTOD("")
            hRec["idkonto"] := hParams["fin_uvoz_van_jci_pdv_np"]
            hRec["idpartner"] := ""
            hRec["d_p"] := "2"
            hRec["iznosbhd"] := hParams["fin_uvoz_prev_pdv_np_iznos"]
            hRec["iznosdem"] := fin_km_to_eur(hRec["iznosbhd"], hParams["fin_uvoz_jci_datprij"])
            dbf_update_rec(hRec )
        ENDIF
    ENDIF


    // roba 1320 zaduzuje
    APPEND BLANK
    hRec["rbr"] := nRbr++
    hRec["idkonto"] := hParams["fin_uvoz_kto_roba"]
    hRec["idpartner"] := ""
    hRec["brdok"] := hParams["fin_uvoz_kalk_brdok"]
    hRec["datdok"] := hParams["fin_uvoz_jci_datprij"]
    hRec["datval"] := CTOD("")
    hRec["opis"] := "roba zaduzuje"
    hRec["d_p"] := "1"
    hRec["iznosbhd"] :=  hParams["fin_uvoz_dob_iznos"]  +;
       (hParams["fin_uvoz_sped_iznos"] - hParams["fin_uvoz_sped_pdv_iznos"] ) +;
       (hParams["fin_uvoz_prev_iznos"] - hParams["fin_uvoz_prev_pdv_iznos"] ) +;
       hParams["fin_uvoz_prevalm_iznos"] + hParams["fin_uvoz_car_iznos"] + + hParams["fin_uvoz_akcize_iznos"]
    hRec["iznosdem"] := fin_km_to_eur(hRec["iznosbhd"], hParams["fin_uvoz_jci_datprij"])
    dbf_update_rec( hRec )


    // neposlovni uvoz
    nTmp := hParams["fin_uvoz_jci_pdv_np_iznos"] + hParams["fin_uvoz_sped_pdv_np_iznos"] + hParams["fin_uvoz_prev_pdv_np_iznos"]
    IF Round(nTmp, 2) <> 0
       APPEND BLANK
       hRec["rbr"] := nRbr++
       hRec["opis"] := "uvoz vanposlovno"
       hRec["idkonto"] := hParams["fin_uvoz_kto_np"]
       hRec["idpartner"] := ""
       hRec["datdok"] := hParams["fin_uvoz_jci_datprij"]
       hRec["datval"] := CTOD("")
       hRec["d_p"] := "1"
       hRec["iznosbhd"] :=  nTmp
       hRec["iznosdem"] := fin_km_to_eur(hRec["iznosbhd"], hParams["fin_uvoz_jci_datprij"])
       dbf_update_rec( hRec )
    ENDIF
   
    my_unlock()


    RETURN .T.


 STATIC FUNCTION fin_km_to_eur( nKM, dDatDok )

    LOCAL dKurs
   
    dKurs := Kurs( dDatDok )
     
    IF Round( dKurs, 4 ) == 0
        RETURN 0
    ELSE
        RETURN  nKM / dKurs
    ENDIF
        
    RETURN 0


FUNCTION kalk_10_gen_uvoz( cBrKalk )

    LOCAL cQuery := "select brfaktp, datdok, idpartner from kalk_kalk where idvd='10'"
    LOCAL cQuery2
    LOCAL cBrFakt, dDatDok, cIdDobavljac
    LOCAL nDobavIznos, nSpedIznos, nPrevoznikIznos


    cQuery += " and brdok=" + sql_quote(cBrKalk) + " limit 1"

    SELECT F_TMP
    IF !use_sql( "KLK", cQuery)
        Alert("QRY: KALK 10-" + cBrKalk + " ne postoji?!")
        RETURN .F.
    ENDIF


    dDatDok := klk->datdok
    cBrFakt := klk->brfaktp
    cIdDobavljac := klk->idpartner

    USE

    cQuery2 := "SELECT sum(fcj*kolicina) as fv,"
    cQuery2 += " sum(case when tspedtr='U' then spedtr else  fcj*spedtr*kolicina end) spedtr,"
    cQuery2 += " sum(case when tzavtr='U' then zavtr else  fcj*zavtr*kolicina end) prevoz"
    cQuery2 += " FROM kalk_kalk where idvd='10' and brdok=" + sql_quote(cBrKalk)

    IF !use_sql( "KLK", cQuery2)
        Alert("QRY2: KALK 10-" + cBrKalk + " ne postoji?!")
        RETURN .F.
    ENDIF

    nDobavIznos := klk->fv
    nSpedIznos := klk->spedtr
    nPrevoznikIznos := klk->prevoz

    USE

    IF ROUND(nSpedIznos, 2) == 0
        // ovo nije uvoz, spediterski troskovi su 0
        RETURN .F.
    ENDIF

    //fin_gen_uvoz(cBrKalk, dDatDok, cIdDobavljac, cBrFaktP, nDobavIznos, nSpedIznos, nPrevoznikIznos)
    fin_gen_uvoz(cBrKalk, dDatDok, cIdDobavljac, cBrFakt, nDobavIznos, nSpedIznos, nPrevoznikIznos)

   
    RETURN .T.

