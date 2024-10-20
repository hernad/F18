#include "f18.ch"

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
    LOCAL cIdKontoPDVUvoz := Trim( fetch_metric( "fin_enab_idkonto_pdv_u", NIL, "271" ))
    LOCAL cIdKontoPDVUvozNP := Trim( fetch_metric( "fin_enab_idkonto_pdv_u_np", NIL, "27691" ))

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

    hPDV["id_br"] := cPDV
    hPDV["dat_od"] := dDatOd
    hPDV["dat_do"] := dDatDo
    hPdv["11"] := 0.00
    hPdv["12"] := 0.00
    hPdv["13"] := 0.00
    hPdv["21"] := 0.00
    hPdv["22"] := 0.00
    hPdv["23"] := 0.00
    hPdv["41"] := 0.00
    hPdv["42"] := 0.00
    hPdv["43"] := 0.00
    hPdv["51"] := 0.00
    hPdv["61"] := 0.00
    hPdv["71"] := 0.00
    hPdv["32"] := 0.00
    hPdv["33"] := 0.00
    hPdv["34"] := 0.00
    


    SELECT F_TMP
 
    cQuery := "select sum(fakt_iznos_pdv_np_32) as fakt_iznos_pdv_np_32, sum(fakt_iznos_pdv_np_33) as fakt_iznos_pdv_np_33, sum(fakt_iznos_pdv_np_34) as fakt_iznos_pdv_np_34" 
    cQuery += " FROM public.enabavke WHERE porezni_period=" + sql_quote(cPorezniPeriod) 
    use_sql("ENAB", cQuery)
    hPDV["32"] += enab->fakt_iznos_pdv_np_32
    hPDV["33"] += enab->fakt_iznos_pdv_np_33
    hPDV["34"] += enab->fakt_iznos_pdv_np_34
    use


    // uvoz tip=04
    cQuery := "select sum(fakt_iznos_bez_pdv) as fakt_iznos_bez_pdv" 
    cQuery += " FROM public.enabavke WHERE porezni_period=" + sql_quote(cPorezniPeriod)
    cQuery += " AND tip='04'"
    use_sql("ENAB", cQuery)
    hPDV["22"] := enab->fakt_iznos_bez_pdv
    use

    // uvoz tip=04, samo PDV po JCI
    cQuery := "select sum(fakt_iznos_pdv) as iznos_pdv" 
    cQuery += " FROM public.enabavke WHERE porezni_period=" + sql_quote(cPorezniPeriod)
    cQuery += " AND tip='04'"
    cQuery += " AND (idkonto like '" +  cIdKontoPDVUvoz + "%' OR idkonto_np like '" + cIdKontoPDVUvozNP + "%')"
    use_sql("ENAB", cQuery)
    // PDV na uvoz
    hPDV["42"] := enab->iznos_pdv
    use
    
    // uvoz tip=04, osnovica na osnovu domaceg prometa speditera kod fakture uvoza (domaci PDV-a u fakturi speditera)
    cQuery := "select sum(fakt_iznos_pdv + fakt_iznos_pdv_np)/0.17 as osnovica_pdv" 
    cQuery += " FROM public.enabavke WHERE porezni_period=" + sql_quote(cPorezniPeriod)
    cQuery += " AND tip='04'"
    cQuery += " AND NOT (idkonto like '" +  cIdKontoPDVUvoz + "%' OR idkonto_np like '" + cIdKontoPDVUvozNP + "%')"
    use_sql("ENAB", cQuery)
    // dio unutar uvoza koji se odnosi na domaci promet
    hPDV["21"] := enab->osnovica_pdv
    use

    //  sve nabavke iznos bez pdv
    cQuery := "select sum(fakt_iznos_bez_pdv) as fakt_iznos_bez_pdv" 
    cQuery += " FROM public.enabavke WHERE porezni_period=" + sql_quote(cPorezniPeriod)
    use_sql("ENAB", cQuery)
    hPDV["21"] += enab->fakt_iznos_bez_pdv - hPDV["23"] - hPDV["22"]
    hPDV["21"] := pdv_prijava_zaok_decimal(hPDV["21"])
    hPDV["22"] := pdv_prijava_zaok_decimal(hPDV["22"])

    //  poljop naknada 
    cQuery := "select sum(fakt_iznos_bez_pdv) as fakt_iznos_bez_pdv, sum(fakt_iznos_poljo_pausal) as iznos_pausal" 
    cQuery += " FROM public.enabavke WHERE porezni_period=" + sql_quote(cPorezniPeriod)
    cQuery += " AND fakt_iznos_poljo_pausal<>0"
    use_sql("ENAB", cQuery)
    hPDV["23"] := pdv_prijava_zaok_decimal(enab->fakt_iznos_bez_pdv)
    // pausalna naknada za poljop
    hPDV["43"] := pdv_prijava_zaok_decimal(enab->iznos_pausal)
    use

    //  sve nabavke iznos pdv
    cQuery := "select sum(fakt_iznos_pdv) as iznos_pdv" 
    cQuery += " FROM public.enabavke WHERE porezni_period=" + sql_quote(cPorezniPeriod)
    use_sql("ENAB", cQuery)

    // ulazni pdv (odbitni - samo poslovna potrosnja) - uvoz - poljop pausal naknada
    hPDV["41"] := enab->iznos_pdv - hPDV["42"] - hPDV["43"]
    hPdv["41"] := pdv_prijava_zaok_decimal(hPDV["41"])
    hPdv["42"] := pdv_prijava_zaok_decimal(hPDV["42"])
    hPdv["43"] := pdv_prijava_zaok_decimal(hPDV["43"])

    use
    hPDV["61"] := pdv_prijava_zaok_decimal(hPDV["41"] + hPDV["42"] + hPDV["43"])

    // isporuke izvoz tip=04 ali i stavke prevoza po CLAN27
    cQuery := "select sum(fakt_iznos_sa_pdv0_izvoz) as fakt_iznos" 
    cQuery += " FROM public.eisporuke WHERE porezni_period=" + sql_quote(cPorezniPeriod)
    //cQuery += " AND tip='04'"
    use_sql("EISP", cQuery)
    hPDV["12"] += pdv_prijava_zaok_decimal(eisp->fakt_iznos)
    use

   
    // oslobodjeno po clanu 24 i 25 ide u polje PDV 13
    cQuery := "select sum(fakt_iznos_sa_pdv0_ostalo) as fakt_iznos FROM public.eisporuke" 
    cQuery += " LEFT JOIN fmk.fin_suban on eisporuke.fin_idfirma=fin_suban.idfirma and eisporuke.fin_idvn=fin_suban.idvn and eisporuke.fin_brnal=fin_suban.brnal and eisporuke.fin_rbr=fin_suban.rbr and extract(year from  fin_suban.datdok)=extract(year from eisporuke.dat_fakt)"
    cQuery += " WHERE porezni_period=" + sql_quote(cPorezniPeriod)
    cQuery += " and (substr(get_sifk('PARTN', 'PDVO', COALESCE(fin_suban.idpartner,'')),1,2) IN ('24','25') OR trim(eisporuke.kup_pdv0_clan) IN ('24','25'))"
    use_sql("EISP", cQuery)
    hPDV["13"] := pdv_prijava_zaok_decimal(eisp->fakt_iznos)
    use

    // ovo se ne moze desiti - od verzije 3.3.70 u polje fakt_iznos_sa_pdv0_ostalo idu samo oslobodjenja po clanu 24,25
    //// 1)
    //// oslobodjeno po ostalim clanovima ide u polje PDV 11
    //cQuery := "select sum(fakt_iznos_sa_pdv0_ostalo) as fakt_iznos FROM public.eisporuke" 
    //cQuery += " LEFT JOIN fmk.fin_suban on eisporuke.fin_idfirma=fin_suban.idfirma and eisporuke.fin_idvn=fin_suban.idvn and eisporuke.fin_brnal=fin_suban.brnal and eisporuke.fin_rbr=fin_suban.rbr and extract(year from  fin_suban.datdok)=extract(year from eisporuke.dat_fakt)"
    //cQuery += " WHERE porezni_period=" + sql_quote(cPorezniPeriod)
    //cQuery += " and NOT (substr(get_sifk('PARTN', 'PDVO', COALESCE(fin_suban.idpartner,'')),1,2) IN ('24','25') OR trim(eisporuke.kup_pdv0_clan) IN ('24','25'))"
    //use_sql("EISP", cQuery)
    //hPDV["11"] := eisp->fakt_iznos
    //use

    // ovo se ne moze desiti vise od verzije 3.3.70
    //// 2)
    //// oslobodjeno po clanu 15, vrijednost fakture se nalazi u fakt_iznos_sa_pdv
    //cQuery := "select sum(fakt_iznos_sa_pdv) as fakt_iznos FROM public.eisporuke" 
    //cQuery += " LEFT JOIN fmk.fin_suban on eisporuke.fin_idfirma=fin_suban.idfirma and eisporuke.fin_idvn=fin_suban.idvn and eisporuke.fin_brnal=fin_suban.brnal and eisporuke.fin_rbr=fin_suban.rbr and extract(year from  fin_suban.datdok)=extract(year from eisporuke.dat_fakt)"
    //cQuery += " WHERE porezni_period=" + sql_quote(cPorezniPeriod)
    //cQuery += " and (substr(get_sifk('PARTN', 'PDVO', COALESCE(fin_suban.idpartner,'')),1,2)='15' OR trim(eisporuke.kup_pdv0_clan)='15')"
    //use_sql("EISP", cQuery)
    //hPDV["11"] += eisp->fakt_iznos
    //use

    // 3)
    // isporuke sve iznos bez pdv osim izvoz i pdv0_ostalo clan 24 i 25
    cQuery := "select sum(fakt_iznos_bez_pdv + fakt_iznos_bez_pdv_np) as fakt_iznos_bez_pdv, sum(fakt_iznos_pdv + fakt_iznos_pdv_np) as iznos_pdv" 
    cQuery += " FROM public.eisporuke WHERE porezni_period=" + sql_quote(cPorezniPeriod)
    cQuery += " AND tip<>'04'"
    use_sql("EISP", cQuery)
    hPDV["11"] += eisp->fakt_iznos_bez_pdv
    hPDV["11"] := pdv_prijava_zaok_decimal(hPDV["11"])

    // izlazni PDV
    hPDV["51"] := pdv_prijava_zaok_decimal(eisp->iznos_pdv)
    use

    // pdv za uplatu
    hPDV["71"] := hPDV["51"] - hPDV["61"]
    hPDV["71"] := pdv_prijava_zaok_decimal(hPDV["71"])

    SELECT F_TMP
    cQuery := "select sum(fakt_iznos_pdv_np_32) as fakt_iznos_pdv_np_32, sum(fakt_iznos_pdv_np_33) as fakt_iznos_pdv_np_33, sum(fakt_iznos_pdv_np_34) as fakt_iznos_pdv_np_34" 
    cQuery += " FROM public.eisporuke WHERE porezni_period=" + sql_quote(cPorezniPeriod)
    use_sql("EISP", cQuery)
    hPDV["32"] += eisp->fakt_iznos_pdv_np_32
    hPDV["33"] += eisp->fakt_iznos_pdv_np_33
    hPDV["34"] += eisp->fakt_iznos_pdv_np_34

    hPDV["32"] := pdv_prijava_zaok_decimal(hPDV["32"])
    hPDV["33"] := pdv_prijava_zaok_decimal(hPDV["33"])
    hPDV["34"] := pdv_prijava_zaok_decimal(hPDV["34"])
    use

    DO WHILE .T.
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
        @ box_x_koord() + nX++, box_y_koord() + nCol SAY8 Padr("(43) paus nakn za poljopriv:", nWidth) + Transform(hPDV[ "43" ], cPict)

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

        @ box_x_koord() + 29, box_y_koord() + 20 SAY "<ESC> - kraj, <P> - print" COLOR f18_color_invert()

        inkey(0)
        BoxC()

        IF LastKey() == K_ESC
            EXIT
        ENDIF

        IF Upper(Chr(Lastkey())) == "P"
            print_pdv(hPDV)
        ENDIF

    ENDDO

    RETURN .T.

//
// zaokruzenje na 2 decimalna mjesta naPDV prijavi
//
FUNCTION pdv_prijava_zaok_decimal(nInput)

   RETURN ROUND(nInput, 2)
