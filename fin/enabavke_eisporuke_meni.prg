#include "f18.ch"

FUNCTION fin_eIsporukeNabavkeMenu()

    LOCAL aOpc := {}
    LOCAL aOpcexe := {}
    LOCAL nIzbor := 1

    AAdd( aOpc, "1. parametri enabavke                                   " )
    AAdd( aOpcexe, {|| parametri_eNabavke() } )

    AAdd( aOpc, "2. provjera knjiženja enabavke                          " )
    AAdd( aOpcexe, {|| check_eNabavke() } )

    AAdd( aOpc, "3. generacija enabavke                                  " )
    AAdd( aOpcexe, {|| gen_eNabavke() } )

    AAdd( aOpc, "4. eksport enabavke xlsx                                " )
    AAdd( aOpcexe, {|| export_eNabavke() } )

    AAdd( aOpc, "5. parametri eisporuke                                   " )
    AAdd( aOpcexe, {|| parametri_eIsporuke() } )

    AAdd( aOpc, "6. generacija eisporuke                                  " )
    AAdd( aOpcexe, {|| gen_eIsporuke() } )

    AAdd( aOpc, "7. eksport eisporuke xlsx                                " )
    AAdd( aOpcexe, {|| export_eIsporuke() } )
 
    AAdd( aOpc, "9. obračun PDV na osnovu izgenerisanih enabavki/eisporuka" )
    AAdd( aOpcexe, {|| eNab_eIsp_PDV() } )


    AAdd( aOpc, "X. fin generacija uvoz" )
    AAdd( aOpcexe, {|| fin_gen_uvoz() } )
  


    f18_menu( "fin_eispn", .F., nIzbor, aOpc, aOpcexe )
 
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

    // isporuke PDV0 po ostalim osnovama
    cQuery := "select sum(fakt_iznos_sa_pdv0_ostalo) as fakt_iznos" 
    cQuery += " FROM public.eisporuke WHERE porezni_period=" + sql_quote(cPorezniPeriod)
    use_sql("EISP", cQuery)
    hPDV["13"] := ROUND(eisp->fakt_iznos, 0)
    use

    // isporuke sve iznos bez pdv osim izvoz i pdv0_ostalo
    cQuery := "select sum(fakt_iznos_bez_pdv + fakt_iznos_bez_pdv_np) as fakt_iznos_bez_pdv, sum(fakt_iznos_pdv + fakt_iznos_pdv_np) as iznos_pdv" 
    cQuery += " FROM public.eisporuke WHERE porezni_period=" + sql_quote(cPorezniPeriod)
    cQuery += " AND tip<>'04' and fakt_iznos_sa_pdv0_ostalo=0 and fakt_iznos_sa_pdv0_izvoz=0"
    use_sql("EISP", cQuery)
    hPDV["11"] := ROUND(eisp->fakt_iznos_bez_pdv, 0)
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
    @ box_x_koord() + nX++, box_y_koord() + nCol SAY8 Padr("(42) paus naknada za pojopriv: ", nWidth) + Transform(hPDV[ "43" ], cPict)

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