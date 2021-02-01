#include "f18.ch"

MEMVAR gBrojacKalkulacija

FUNCTION fin_gen_uvoz(cBrKalk, cIdKonto, dDatDok, cIdDobavljac, cBrFakt, nDobavIznos, nSpedIznos, nPrevoznikIznos, nZavTrIznos)

    LOCAL nX := 1
    LOCAL GetList := {}
    LOCAL nJCI := 0
    LOCAL cPictIznos := "99999999.99"

    LOCAL hParams := hb_hash()
    LOCAL hRec := hb_hash()
    LOCAL cKey, nRbr
    LOCAL nTmp
    LOCAL cJCIBR
    LOCAL nDadzbine
    LOCAL nSpedOsnPDV0

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

    hParams["fin_uvoz_jci_broj"]:= fetch_metric( "fin_uvoz_jci_broj", my_user(), SPACE(20) )

    IF ValType(hParams["fin_uvoz_jci_broj"]) <> "C"
        hParams["fin_uvoz_jci_broj"] := SPACE(20)
    ENDIF
    hParams["fin_uvoz_jci_broj"] := Padr(hParams["fin_uvoz_jci_broj"], 20) 

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

    // spediter
    hParams["fin_uvoz_sped_kto"]:= PADR(fetch_metric("fin_uvoz_sped_kto", my_user(), "4320" ), 7)
    hParams["fin_uvoz_sped_partn"]:= PADR(fetch_metric( "fin_uvoz_sped_partn", my_user(), "" ), 6)
    hParams["fin_uvoz_uio_partn"] := PADR(fetch_metric( "fin_uvoz_uio_partn", my_user(), "" ), 6)

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
    hParams["fin_uvoz_sped_placa_uio"]:= PADR(fetch_metric( "fin_uvoz_sped_placa_uio", my_user(), "N" ), 1)

    // prevoz
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

    // ZAVTR
    hParams["fin_uvoz_zav_kto"]:= PADR(fetch_metric("fin_uvoz_zav_kto", my_user(), "4320" ), 7)
    hParams["fin_uvoz_zav_partn"]:= PADR(fetch_metric( "fin_uvoz_zav_partn", my_user(), "" ), 6)
    hParams["fin_uvoz_zav_brdok"]:= PADR(fetch_metric( "fin_uvoz_zav_brdok", my_user(), "" ), 10)
    IF dDatDok <> NIL
        hParams["fin_uvoz_zav_datdok"]:= dDatDok 
        hParams["fin_uvoz_zav_datval"]:= CTOD("")
        set_metric( "fin_uvoz_zav_datdok", my_user(), dDatDok)
        set_metric( "fin_uvoz_zav_datval", my_user(), CTOD(""))
    ELSE
       hParams["fin_uvoz_zav_datdok"]:= fetch_metric( "fin_uvoz_zav_datdok", my_user(), CTOD("") )
    ENDIF
    hParams["fin_uvoz_zav_datval"]:= fetch_metric( "fin_uvoz_zav_datval", my_user(), CTOD("") )
    hParams["fin_uvoz_zav_osn_pdv0"]:= fetch_metric( "fin_uvoz_zav_osn_pdv0", my_user(), 0.00 )
    IF nZavTrIznos <> NIL
        hParams["fin_uvoz_zav_iznos"] := nZavTrIznos
        set_metric( "fin_uvoz_zav_iznos", my_user(), nZavTrIznos )
    ELSE
       hParams["fin_uvoz_zav_iznos"]:= fetch_metric( "fin_uvoz_zav_iznos", my_user(), 0.00 )
    ENDIF
    hParams["fin_uvoz_zav_pdv_iznos"]:= fetch_metric( "fin_uvoz_zav_pdv_iznos", my_user(), 0 )
    hParams["fin_uvoz_zav_pdv_np_iznos"]:= fetch_metric( "fin_uvoz_zav_pdv_np_iznos", my_user(), 0 )


    hParams["fin_uvoz_kto_prevalm_potraz"]:= PADR(fetch_metric( "fin_uvoz_kto_prevalm_potraz", my_user(), "4823" ), 7)
    hParams["fin_uvoz_prevalm_iznos"]:= fetch_metric( "fin_uvoz_prevalm_iznos", my_user(), 0.0 )

    hParams["fin_uvoz_kto_car_potraz"]:= PADR(fetch_metric( "fin_uvoz_kto_car_potraz", my_user(), "4820" ), 7)
    hParams["fin_uvoz_car_iznos"]:= fetch_metric( "fin_uvoz_car_iznos", my_user(), 0.0 )

    hParams["fin_uvoz_kto_akcize_potraz"]:= PADR(fetch_metric( "fin_uvoz_kto_akcize_potraz", my_user(), "4802" ), 7)
    hParams["fin_uvoz_akcize_iznos"]:= fetch_metric( "fin_uvoz_akcize_iznos", my_user(), 0.0 )

    hParams["fin_uvoz_van_jci_pdv"]:= PADR(fetch_metric( "fin_uvoz_van_jci_pdv", my_user(), "2700" ), 7)
    hParams["fin_uvoz_van_jci_pdv_np"]:= PADR(fetch_metric( "fin_uvoz_van_jci_pdv_np", my_user(), "27690" ), 7)

    IF cIdKonto <> NIL
        hParams["fin_uvoz_kto_roba"]:= cIdKonto
        set_metric( "fin_uvoz_kto_roba", my_user(), cIdKonto )
    ELSE
        hParams["fin_uvoz_kto_roba"]:= PADR(fetch_metric( "fin_uvoz_kto_roba", my_user(), "1320" ), 7)
    ENDIF

    hParams["fin_uvoz_kto_np"]:= PADR(fetch_metric( "fin_uvoz_kto_np", my_user(), "5510" ), 7)
    
    PUBLIC gBrojacKalkulacija := fetch_metric( "kalk_brojac_kalkulacija", nil, "D" )
    kalk_duzina_brojaca_dokumenta()

    Box(, 27, 102)

       @ box_x_koord() + nX, box_y_koord() + 2 SAY "KALK 10 -" GET hParams["fin_uvoz_kalk_brdok"]  VALID {|| hParams["fin_uvoz_kalk_brdok"] := kalk_fix_brdok( hParams["fin_uvoz_kalk_brdok"] ), .T. }
       @ box_x_koord() + nX, col() + 2 SAY "FIN vrsta naloga: " GET hParams["fin_uvoz_fin_idvn"]
       @ box_x_koord() + nX++, col() + 2 SAY "broj naloga: " GET hParams["fin_uvoz_fin_brnal"]

       nX++
       @ box_x_koord() + nX, box_y_koord() + 2 SAY "JCI:" GET hParams["fin_uvoz_jci_broj"] PICT "@!" VALID !Empty(hParams["fin_uvoz_jci_broj"])
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
       @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Prevoznik kto :" GET hParams["fin_uvoz_prev_kto"]
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
       @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "ZAV.TR kto :" GET hParams["fin_uvoz_zav_kto"]
       @ box_x_koord() + nX++, col() + 2 SAY8 "partn:" GET hParams["fin_uvoz_zav_partn"] VALID Empty(hParams["fin_uvoz_zav_partn"]) .OR. P_Partner(@hParams["fin_uvoz_zav_partn"]) 
       @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "  br.fakt:" GET hParams["fin_uvoz_zav_brdok"] ;
           VALID !Empty(hParams["fin_uvoz_zav_brdok"]) .OR. Empty(hParams["fin_uvoz_zav_partn"])
       @ box_x_koord() + nX, col() + 2 SAY8 "dat.fakt:" GET hParams["fin_uvoz_zav_datdok"] ;
           WHEN {|| hParams["fin_uvoz_zav_datdok"] := IIF(Empty(hParams["fin_uvoz_zav_datdok"]), hParams["fin_uvoz_jci_datprij"], hParams["fin_uvoz_zav_datdok"]), .T.} ;
           VALID !Empty(hParams["fin_uvoz_zav_datdok"]) .OR. Empty(hParams["fin_uvoz_zav_partn"])
       @ box_x_koord() + nX, col() + 2 SAY8 "dat.val:" GET hParams["fin_uvoz_zav_datval"]    
       @ box_x_koord() + nX++, col() + 2 SAY8 "faktura ZAV.TR iznos:" GET hParams["fin_uvoz_zav_iznos"] PICT cPictIznos
       @ box_x_koord() + nX, box_y_koord() + 2 SAY "osn PDV 0% (van JCI) :" GET hParams["fin_uvoz_zav_osn_pdv0"] 
       @ box_x_koord() + nX, col() + 2 SAY "PDV van JCI iznos:" GET hParams["fin_uvoz_zav_pdv_iznos"]  PICT cPictIznos
       @ box_x_koord() + nX, col() + 2 SAY "PDV van JCI NP izn:" GET hParams["fin_uvoz_zav_pdv_np_iznos"] PICT cPictIznos

       nX += 2
       @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Prelevmani kto potraž :" GET hParams["fin_uvoz_kto_prevalm_potraz"]
       @ box_x_koord() + nX++, col() + 2 SAY8 "iznos" GET hParams["fin_uvoz_prevalm_iznos"] PICT cPictIznos

       @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "    Carina kto potraž :" GET hParams["fin_uvoz_kto_car_potraz"]
       @ box_x_koord() + nX++, col() + 2 SAY8 "iznos" GET hParams["fin_uvoz_car_iznos"] PICT cPictIznos

       @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "    Akcize kto potraž :" GET hParams["fin_uvoz_kto_akcize_potraz"]
       @ box_x_koord() + nX++, col() + 2 SAY8 "iznos" GET hParams["fin_uvoz_akcize_iznos"] PICT cPictIznos

       @ box_x_koord() + nX-3, box_y_koord() + 55 SAY8 "ŠPEDITER plaća UIO-u dadžbine (D/N/P):" GET hParams["fin_uvoz_sped_placa_uio"] PICT "@!" ;
          VALID hParams["fin_uvoz_sped_placa_uio"] $ "DNP"
       @ box_x_koord() + nX-2, box_y_koord() + 55 SAY8 "Dažbine potražuje UIO. Dobavljač UIO:" GET hParams["fin_uvoz_uio_partn"] ;
          WHEN hParams["fin_uvoz_sped_placa_uio"] == "P" ;
          VALID Empty(hParams["fin_uvoz_uio_partn"]) .OR. P_Partner(@hParams["fin_uvoz_uio_partn"])

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
      "fin_uvoz_sped_placa_uio", "fin_uvoz_uio_partn",;
      "fin_uvoz_prev_kto", "fin_uvoz_prev_partn", "fin_uvoz_prev_brdok", "fin_uvoz_prev_datdok", "fin_uvoz_prev_datval", "fin_uvoz_prev_osn_pdv0",;
      "fin_uvoz_prev_iznos", "fin_uvoz_prev_pdv_iznos", "fin_uvoz_prev_pdv_np_iznos", ;
      "fin_uvoz_zav_kto", "fin_uvoz_zav_partn", "fin_uvoz_zav_brdok", "fin_uvoz_zav_datdok", "fin_uvoz_zav_datval", "fin_uvoz_zav_osn_pdv0",;
      "fin_uvoz_zav_iznos", "fin_uvoz_zav_pdv_iznos", "fin_uvoz_zav_pdv_np_iznos",;
      "fin_uvoz_kto_prevalm_potraz", "fin_uvoz_prevalm_iznos",;
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
    hRec["opis"] := "RN " + Alltrim(hParams["fin_uvoz_dob_brdok"]) + ", "
    hRec["opis"] += "JCI: " + Alltrim(hParams["fin_uvoz_jci_broj"])
    hRec["brdok"] := hParams["fin_uvoz_dob_brdok"]
    

    // jci datum prijema i datum dokumenta razliciti
    hRec["opis"] += ", DAT-JCI: " + DTOC(hParams["fin_uvoz_jci_datdok"])
    IF hParams["fin_uvoz_jci_datprij"] <> hParams["fin_uvoz_jci_datdok"]
        hRec["opis"] += ", DAT-JCI-P: " + DTOC(hParams["fin_uvoz_jci_datprij"])
    ENDIF

    hRec["datdok"] := hParams["fin_uvoz_dob_datdok"]
    // faktura robe 30.11.2020, jci datum prijema 01.12.2020
    IF month(hParams["fin_uvoz_jci_datprij"]) <> month(hParams["fin_uvoz_dob_datdok"])
       hRec["opis"] += ", DAT-FAKT: " + DTOC(hParams["fin_uvoz_dob_datdok"])
       hRec["datdok"] := hParams["fin_uvoz_jci_datprij"]
    ENDIF

    hRec["datval"] := hParams["fin_uvoz_dob_datval"]
    hRec["idkonto"] := hParams["fin_uvoz_dob_kto"]
    hRec["idpartner"] := hParams["fin_uvoz_dob_partn"]
    hRec["d_p"] := "2"
    hRec["iznosbhd"] := hParams["fin_uvoz_dob_iznos"]
    hRec["iznosdem"] := fin_km_to_eur(hRec["iznosbhd"], hParams["fin_uvoz_jci_datprij"])
    dbf_update_rec( hRec )

    cJCIBR := "JCI BR " + Alltrim(hParams["fin_uvoz_jci_broj"])
    nDadzbine := 0

    // PDV JCI duguje
    IF hParams["fin_uvoz_jci_pdv_iznos"] > 0
      APPEND BLANK
      hRec["rbr"] := nRbr++
      hRec["opis"] := cJCIBR
      hRec["brdok"] := hParams["fin_uvoz_dob_brdok"]
      hRec["datdok"] := hParams["fin_uvoz_jci_datprij"]
      hRec["datval"] := CTOD("")
      hRec["idkonto"] := hParams["fin_uvoz_jci_pdv_kto"] 
      hRec["idpartner"] := ""
      hRec["d_p"] := "1"
      hRec["iznosbhd"] := hParams["fin_uvoz_jci_pdv_iznos"]
      nDadzbine += hParams["fin_uvoz_jci_pdv_iznos"]
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
        nDadzbine += hParams["fin_uvoz_jci_pdv_np_iznos"]
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

    IF hParams[ "fin_uvoz_sped_placa_uio" ] == "N"
        // jci UIO potrazuje
        APPEND BLANK
        hRec["rbr"] := nRbr++
        hRec["opis"] := cJCIBR
        hRec["brdok"] := Alltrim(hParams["fin_uvoz_jci_broj"])
        hRec["datdok"] := hParams["fin_uvoz_jci_datprij"]
        hRec["datval"] := CTOD("")
        hRec["idkonto"] := hParams["fin_uvoz_jci_kto_potraz"]
        hRec["idpartner"] := ""
        hRec["d_p"] := "2"
        hRec["iznosbhd"] := hParams["fin_uvoz_jci_pdv_iznos"] + hParams["fin_uvoz_jci_pdv_np_iznos"]
        hRec["iznosdem"] := fin_km_to_eur(hRec["iznosbhd"], hParams["fin_uvoz_jci_datprij"])
        dbf_update_rec( hRec )
    ENDIF

    IF ROUND(hParams["fin_uvoz_prevalm_iznos"], 2) > 0
        IF hParams[ "fin_uvoz_sped_placa_uio" ] == "N"
            // prelevmani potrazuje
            APPEND BLANK
            hRec["rbr"] := nRbr++
            hRec["opis"] := "PRELEVMANI " + cJCIBR 
            hRec["brdok"] := Alltrim(hParams["fin_uvoz_jci_broj"])
            hRec["datdok"] := hParams["fin_uvoz_jci_datprij"]
            hRec["datval"] := CTOD("")
            hRec["idkonto"] := hParams["fin_uvoz_kto_prevalm_potraz"]
            hRec["idpartner"] := ""
            hRec["d_p"] := "2"
            hRec["iznosbhd"] := hParams["fin_uvoz_prevalm_iznos"]
            hRec["iznosdem"] := fin_km_to_eur(hRec["iznosbhd"], hParams["fin_uvoz_jci_datprij"])
            dbf_update_rec( hRec )
        ENDIF
        nDadzbine += hParams["fin_uvoz_prevalm_iznos"]
    ENDIF

    IF ROUND(hParams["fin_uvoz_car_iznos"], 2) > 0
        IF hParams[ "fin_uvoz_sped_placa_uio" ] == "N"
            // carine potrazuje
            APPEND BLANK
            hRec["rbr"] := nRbr++
            hRec["opis"] := "CARINE " + cJCIBR
            hRec["brdok"] := Alltrim(hParams["fin_uvoz_jci_broj"])
            hRec["datdok"] := hParams["fin_uvoz_jci_datprij"]
            hRec["datval"] := CTOD("")
            hRec["idkonto"] := hParams["fin_uvoz_kto_car_potraz"]
            hRec["idpartner"] := ""
            hRec["d_p"] := "2"
            hRec["iznosbhd"] := hParams["fin_uvoz_car_iznos"]
            hRec["iznosdem"] := fin_km_to_eur(hRec["iznosbhd"], hParams["fin_uvoz_jci_datprij"])
            dbf_update_rec( hRec )
        ELSE
            nDadzbine += hParams["fin_uvoz_car_iznos"]
        ENDIF
    ENDIF

    IF ROUND(hParams["fin_uvoz_akcize_iznos"], 2) > 0
        IF hParams[ "fin_uvoz_sped_placa_uio" ] == "N"
            // akcize potrazuje
            APPEND BLANK
            hRec["rbr"] := nRbr++
            hRec["opis"] := "AKCIZE " + cJCIBR 
            hRec["brdok"] := Alltrim(hParams["fin_uvoz_jci_broj"])
            hRec["datdok"] := hParams["fin_uvoz_jci_datprij"]
            hRec["datval"] := CTOD("")
            hRec["idkonto"] := hParams["fin_uvoz_kto_akcize_potraz"]
            hRec["idpartner"] := ""
            hRec["d_p"] := "2"
            hRec["iznosbhd"] := hParams["fin_uvoz_akcize_iznos"]
            hRec["iznosdem"] := fin_km_to_eur(hRec["iznosbhd"], hParams["fin_uvoz_jci_datprij"])
            dbf_update_rec( hRec )
        ELSE
            nDadzbine += hParams["fin_uvoz_akcize_iznos"]
        ENDIF
    ENDIF

    IF !Empty(hParams["fin_uvoz_sped_partn"])
        // spediter
        APPEND BLANK
        hRec["rbr"] := nRbr++
    
        IF hParams["fin_uvoz_sped_placa_uio"] == "D"
            nSpedOsnPDV0 := hParams["fin_uvoz_sped_osn_pdv0"] + nDadzbine
        ELSE
            nSpedOsnPDV0 := hParams["fin_uvoz_sped_osn_pdv0"]
        ENDIF
        hRec["opis"] := "OSN-PDV0: " + AllTrim(Transform(nSpedOsnPDV0, cPictIznos)) + " ; "
        hRec["opis"] += "SPEDITER RN " + AllTrim(hParams["fin_uvoz_sped_brdok"]) + ", " + cJCIBR
        hRec["brdok"] := hParams["fin_uvoz_sped_brdok"]
        hRec["datdok"] := hParams["fin_uvoz_sped_datdok"]
        IF month(hParams["fin_uvoz_jci_datprij"]) <> month(hParams["fin_uvoz_sped_datdok"])
            hRec["opis"] += ", DAT-FAKT: " + DTOC(hParams["fin_uvoz_sped_datdok"])
            hRec["datdok"] := hParams["fin_uvoz_jci_datprij"]
        ENDIF
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
            hRec["opis"] := "SPEDITER RN " + AllTrim(hParams["fin_uvoz_sped_brdok"]) + " (VAN JCI PDV) "
            hRec["brdok"] := hParams["fin_uvoz_sped_brdok"]
            hRec["datdok"] := hParams["fin_uvoz_jci_datprij"]
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
            hRec["opis"] := "SPEDITER RN " + AllTrim(hParams["fin_uvoz_sped_brdok"]) + " (VAN JCI PDV VANPOSL) "
            hRec["brdok"] := hParams["fin_uvoz_sped_brdok"]
            hRec["datdok"] := hParams["fin_uvoz_jci_datprij"]
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
            hRec["opis"] := "SPEDITER RN " + AllTrim(hParams["fin_uvoz_sped_brdok"]) + " (VAN JCI PDV VANPOSL) PROTUSTAV"
            hRec["brdok"] := ""
            hRec["datdok"] := hParams["fin_uvoz_jci_datprij"]
            hRec["datval"] := CTOD("")
            hRec["idkonto"] := hParams["fin_uvoz_van_jci_pdv_np"]
            hRec["idpartner"] := ""
            hRec["d_p"] := "2"
            hRec["iznosbhd"] := hParams["fin_uvoz_sped_pdv_np_iznos"]
            hRec["iznosdem"] := fin_km_to_eur(hRec["iznosbhd"], hParams["fin_uvoz_jci_datprij"])
            dbf_update_rec( hRec )
        ENDIF
    ELSE
        hParams["fin_uvoz_sped_iznos"] := 0 
        hParams["fin_uvoz_sped_pdv_iznos"] := 0
    ENDIF

    IF !Empty(hParams["fin_uvoz_prev_partn"])
        // prevoznik
        APPEND BLANK
        hRec["rbr"] := nRbr++
        hRec["opis"] := "OSN-PDV0: " + AllTrim(Transform(hParams["fin_uvoz_prev_osn_pdv0"], cPictIznos)) + " ; "
        hRec["opis"] += "PREVOZ RN " + AllTrim(hParams["fin_uvoz_prev_brdok"]) + ", " + cJCIBR
        hRec["brdok"] := hParams["fin_uvoz_prev_brdok"]
        hRec["datdok"] := hParams["fin_uvoz_prev_datdok"]
        IF month(hParams["fin_uvoz_jci_datprij"]) <> month(hParams["fin_uvoz_prev_datdok"])
            hRec["opis"] += ", DAT-FAKT: " + DTOC(hParams["fin_uvoz_prev_datdok"])
            hRec["datdok"] := hParams["fin_uvoz_jci_datprij"]
        ENDIF
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
            hRec["opis"] := "PREVOZ RN " + AllTrim(hParams["fin_uvoz_prev_brdok"]) + " (VAN JCI PDV)"
            hRec["datdok"] := hParams["fin_uvoz_jci_datprij"]
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
            hRec["opis"] := "PREVOZ RN " + AllTrim(hParams["fin_uvoz_prev_brdok"]) + " (VAN JCI PDV VANPOSL)"
            hRec["brdok"] := hParams["fin_uvoz_prev_brdok"]
            hRec["datdok"] := hParams["fin_uvoz_jci_datprij"]
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
            hRec["opis"] := "PREVOZ RN " + AllTrim(hParams["fin_uvoz_prev_brdok"]) + " (VAN JCI PDV VANPOSL) PROTUSTAV"
            hRec["brdok"] := ""
            hRec["datdok"] := hParams["fin_uvoz_jci_datprij"]
            hRec["datval"] := CTOD("")
            hRec["idkonto"] := hParams["fin_uvoz_van_jci_pdv_np"]
            hRec["idpartner"] := ""
            hRec["d_p"] := "2"
            hRec["iznosbhd"] := hParams["fin_uvoz_prev_pdv_np_iznos"]
            hRec["iznosdem"] := fin_km_to_eur(hRec["iznosbhd"], hParams["fin_uvoz_jci_datprij"])
            dbf_update_rec(hRec )
        ENDIF
    ELSE
        hParams["fin_uvoz_prev_iznos"] := 0 
        hParams["fin_uvoz_prev_pdv_iznos"] := 0
    ENDIF

    IF !Empty(hParams["fin_uvoz_zav_partn"])
        // ZAVTR
        APPEND BLANK
        hRec["rbr"] := nRbr++
        hRec["opis"] := "OSN-PDV0: " + AllTrim(Transform(hParams["fin_uvoz_zav_osn_pdv0"], cPictIznos)) + " ; "
        hRec["opis"] += "ZAVTR RN " + AllTrim(hParams["fin_uvoz_zav_brdok"]) + ", " + cJCIBR
        hRec["brdok"] := hParams["fin_uvoz_zav_brdok"]
        hRec["datdok"] := hParams["fin_uvoz_zav_datdok"]
        IF month(hParams["fin_uvoz_jci_datprij"]) <> month(hParams["fin_uvoz_zav_datdok"])
            hRec["opis"] += ", DAT-FAKT: " + DTOC(hParams["fin_uvoz_zav_datdok"])
            hRec["datdok"] := hParams["fin_uvoz_jci_datprij"]
        ENDIF
        hRec["datval"] := hParams["fin_uvoz_zav_datval"]
        hRec["idkonto"] := hParams["fin_uvoz_zav_kto"]
        hRec["idpartner"] := hParams["fin_uvoz_zav_partn"]
        hRec["d_p"] := "2"
        hRec["iznosbhd"] := hParams["fin_uvoz_zav_iznos"]
        hRec["iznosdem"] := fin_km_to_eur(hRec["iznosbhd"], hParams["fin_uvoz_jci_datprij"])
        dbf_update_rec( hRec )

        IF hParams["fin_uvoz_zav_pdv_iznos"] <> 0
            // ZAVTR PDV poslovni
            APPEND BLANK
            hRec["rbr"] := nRbr++
            hRec["opis"] := "ZAVTR RN " + AllTrim(hParams["fin_uvoz_zav_brdok"]) + " (VAN JCI PDV)"
            hRec["datdok"] := hParams["fin_uvoz_jci_datprij"]
            hRec["datval"] := CTOD("")
            hRec["brdok"] := hParams["fin_uvoz_zav_brdok"]
            hRec["idkonto"] := hParams["fin_uvoz_van_jci_pdv"]
            hRec["idpartner"] := ""
            hRec["d_p"] := "1"
            hRec["iznosbhd"] := hParams["fin_uvoz_zav_pdv_iznos"]
            hRec["iznosdem"] := fin_km_to_eur(hRec["iznosbhd"], hParams["fin_uvoz_jci_datprij"])
            dbf_update_rec(hRec)  
        ENDIF


        IF hParams["fin_uvoz_zav_pdv_np_iznos"] <> 0
            // ZAVTR PDV vanposlovni
            APPEND BLANK
            hRec["rbr"] := nRbr++
            hRec["opis"] := "ZAVTR RN " + AllTrim(hParams["fin_uvoz_zav_brdok"]) + " (VAN JCI PDV VANPOSL)"
            hRec["brdok"] := hParams["fin_uvoz_zav_brdok"]
            hRec["datdok"] := hParams["fin_uvoz_jci_datprij"]
            hRec["datval"] := CTOD("")
            hRec["idkonto"] := hParams["fin_uvoz_van_jci_pdv_np"]
            hRec["idpartner"] := ""
            hRec["d_p"] := "1"
            hRec["iznosbhd"] := hParams["fin_uvoz_zav_pdv_np_iznos"]
            hRec["iznosdem"] := fin_km_to_eur(hRec["iznosbhd"], hParams["fin_uvoz_jci_datprij"])
            dbf_update_rec(hRec )

            // ZAVTR PDV vanposlovni protustav
            APPEND BLANK
            hRec["rbr"] := nRbr++
            hRec["opis"] := "ZAVTR RN " + AllTrim(hParams["fin_uvoz_zav_brdok"]) + " (VAN JCI PDV VANPOSL) PROTUSTAV"
            hRec["brdok"] := ""
            hRec["datdok"] := hParams["fin_uvoz_jci_datprij"]
            hRec["datval"] := CTOD("")
            hRec["idkonto"] := hParams["fin_uvoz_van_jci_pdv_np"]
            hRec["idpartner"] := ""
            hRec["d_p"] := "2"
            hRec["iznosbhd"] := hParams["fin_uvoz_zav_pdv_np_iznos"]
            hRec["iznosdem"] := fin_km_to_eur(hRec["iznosbhd"], hParams["fin_uvoz_jci_datprij"])
            dbf_update_rec(hRec )
        ENDIF
    ELSE
        hParams["fin_uvoz_zav_iznos"] := 0 
        hParams["fin_uvoz_zav_pdv_iznos"] := 0
    ENDIF

    // roba 1320 zaduzuje
    APPEND BLANK
    hRec["rbr"] := nRbr++
    hRec["idkonto"] := hParams["fin_uvoz_kto_roba"]
    hRec["idpartner"] := ""
    hRec["brdok"] := hParams["fin_uvoz_kalk_brdok"]
    hRec["datdok"] := hParams["fin_uvoz_jci_datprij"]
    hRec["datval"] := CTOD("")
    hRec["opis"] := "ROBA ZADUZUJE PO " + cJCIBR
    hRec["d_p"] := "1"
    hRec["iznosbhd"] :=  hParams["fin_uvoz_dob_iznos"]  +;
       (hParams["fin_uvoz_sped_iznos"] - hParams["fin_uvoz_sped_pdv_iznos"] ) +;
       (hParams["fin_uvoz_prev_iznos"] - hParams["fin_uvoz_prev_pdv_iznos"] ) +;
       (hParams["fin_uvoz_zav_iznos"] - hParams["fin_uvoz_zav_pdv_iznos"] ) +;
       hParams["fin_uvoz_prevalm_iznos"] + hParams["fin_uvoz_car_iznos"] + hParams["fin_uvoz_akcize_iznos"] 
       
    IF hParams["fin_uvoz_sped_placa_uio"] == "D"
        // ako je spediter platio dazbine UIO-u unutar svoje fakture, onda taj dio izbiti iz nabavne vrijednosti robe
        hRec["iznosbhd"] -=  nDadzbine
    ENDIF

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

    IF hParams["fin_uvoz_sped_placa_uio"] == "P"
            // jci UIO potrazuje
            APPEND BLANK
            hRec["rbr"] := nRbr++
            hRec["opis"] := TRIM( cJCIBR ) + " ENAB:PRESKOCI"
            hRec["brdok"] := Alltrim(hParams["fin_uvoz_jci_broj"])
            hRec["datdok"] := hParams["fin_uvoz_jci_datprij"]
            hRec["datval"] := CTOD("")
            hRec["idkonto"] := PADR("4320", 7)
            hRec["idpartner"] := hParams["fin_uvoz_uio_partn"]
            hRec["d_p"] := "2"
            hRec["iznosbhd"] := nDadzbine
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

    LOCAL cQuery := "select brfaktp, datdok, idpartner, mkonto from kalk_kalk where idvd='10'"
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
    cIdKonto := klk->mkonto

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
    fin_gen_uvoz(cBrKalk, cIdKonto, dDatDok, cIdDobavljac, cBrFakt, nDobavIznos, nSpedIznos, nPrevoznikIznos)

   
    RETURN .T.


FUNCTION set_novi_broj_jci()

    LOCAL GetList := {}
    LOCAL cOldJCI := SPACE(20)
    LOCAL cNewJCI := SPACE(20)

    LOCAL pRegexJCI := hb_regexComp( "JCI:(\s*[A-z\d]+)" )
    LOCAL pRegexJCI2 := hb_regexComp( "JCI BR(\s*[A-z\d]+)" )
    LOCAL aMatch
    LOCAL cMatch
    LOCAL nCnt
  


    Box(, 3, 60)
      @ box_x_koord() + 1, box_y_koord() + 2 SAY "Stari broj JCI:" GET cOldJCI VALID !Empty(cOldJCI)
      @ box_x_koord() + 2, box_y_koord() + 2 SAY " Novi broj JCI:" GET cNewJCI VALID !Empty(cNewJCI)
      READ
    BoxC()

    IF LastKey() == K_ESC
       RETURN .F.
    ENDIF

    cOldJCI := AllTRIM(cOldJCI)
    cNewJCI := AllTRIM(cNewJCI)

    select_o_fin_pripr()
    USE
    o_fin_pripr()
    SET ORDER TO 0
    GO TOP
    
    nCnt := 0
    DO WHILE !EOF()

        // JCI: OLDJCI
        aMatch := hb_regex( pRegexJCI, fin_pripr->opis )
        IF Len( aMatch ) > 0
           cMatch := aMatch[ 2 ]
           IF Alltrim(cMatch) == cOldJCI
             RREPLACE fin_pripr->opis WITH StrTran(fin_pripr->opis, cMatch, " " + cNewJCI)
             nCnt++
           ENDIF
        ENDIF
        // JCI BR OLDJCI
        aMatch := hb_regex( pRegexJCI2, fin_pripr->opis )
        IF Len( aMatch ) > 0
           IF Alltrim(cMatch) == cOldJCI
             cMatch := aMatch[ 2 ]
             RREPLACE fin_pripr->opis WITH StrTran(fin_pripr->opis, cMatch, " " + cNewJCI)
             nCnt++
           ENDIF
        ENDIF

        IF Trim(fin_pripr->brdok) == trim(cOldJCI)
            RREPLACE fin_pripr->brdok WITH cNewJCI
            nCnt++
        ENDIF 

        SKIP
    ENDDO
    USE
    select_o_fin_pripr()

    Alert(_u("Izvršeno promjena: " + Alltrim(Str(nCnt))))
    RETURN .T.



