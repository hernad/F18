#include "f18.ch"

STATIC aHeader := {}
STATIC aZaglLen := { 5, 50 }
STATIC aZagl := {}
STATIC RPT_LM  := 5
STATIC RPT_RI := 2
STATIC RPT_W2 := 45
STATIC RPT_COL := 58
STATIC RPT_GAP := 4
STATIC RPT_BOLD_DELTA := 2
STATIC nCurrLine := 0
STATIC cRptNaziv := "PDV prijava"
STATIC s_cTabela := "pdv"
STATIC cSource := "1"
STATIC dDatOd
STATIC dDatDo

FUNCTION print_pdv( hPDV )

    LOCAL nLenUk
    LOCAL nPom1
    LOCAL nPom2
    LOCAL cPom
    LOCAL nCurrLine, nPageLimit, nRow
 
    nCurrLine := 0
 
    START PRINT CRET
    ?
    nPageLimit := 65
 
    nRow := 0
 
 
    P_COND
    ?
    ?? rpt_lm()
    ?? PadL( "Obrazac P PDV", RPT_COL * 2 + RPT_GAP )
 
    ?
    ?? rpt_lm()
    ?? PadC( " ", RPT_COL * 2 + RPT_GAP )
    ?? rpt_lm()
 
    ?
    P_10CPI
 
    P_10CPI
    ?? Space( 10 )
    ?? PadC( "P D V   P R I J A V A", Round( ( RPT_COL * 2 + RPT_GAP ) / 2, 0 ) )
 
    B_OFF
 
    show_raz_1()
 
    P_12CPI
    
    ?? rpt_lm()
    ?? "1. Identifikacioni broj : "
    ?? hPDV["id_br"]
 
    ?? Space( 6 )
    ?? "2. Period : "
    ?? hPDV["dat_od"]
    ?? " - "
    ?? hPDV["dat_do"]

    /*
    show_raz_1()
 
    ?? rpt_lm()
    ?? "3. Naziv poreskog obveznika : "
    //?? po_naziv
 
    show_raz_1()
 
    ?? rpt_lm()
    ?? "4. Adresa : "
    //?? po_adresa
 
    show_raz_1()
 
    ?? rpt_lm()
    ??U "5. Poštanski broj/Mjesto : "
    //?? po_ptt
    ?? " / "
    //?? po_mjesto
    */
 
    show_raz_1()
 
    P_COND
 
    ?
    ?? rpt_lm()
    B_ON
    U_ON
    ?? PadR( "I. Isporuke i nabavke (iznosi bez PDV-a)", RPT_COL - RPT_BOLD_DELTA )
    U_OFF
    B_OFF
 
    show_raz_1()
 
    ?? rpt_lm()
    ?? Space( RPT_RI )
 
    cPom := PadR( "11. Oporezive isporuke, osim onih u 12 i 13 ", RPT_W2 ) + Transform( hPDV["11"], PIC_IZN() )
    ?? PadL( cPom, RPT_COL - RPT_RI + 1 )
 
    ?? Space( RPT_GAP )
 
    ?? Space( RPT_RI )
    cPom := PadR( "21. SVE nabavke osim 22 i 23 ", RPT_W2 ) + Transform( hPDV["21"], PIC_IZN() )
    ?? PadL( cPom, RPT_COL - RPT_RI + 1 )
 
    show_raz_1()
    ?? rpt_lm()
    cPom := PadR( "12. Vrijednost izvoza ", RPT_W2 ) + Transform( hPDV["12"], PIC_IZN() )
    // sirina kolone - indent
    ?? Space( RPT_RI )
    ?? PadL( cPom, RPT_COL - RPT_RI + 1 )
 
    ?? Space( RPT_GAP )
 
    ?? Space( RPT_RI )
    cPom := PadR( "22. Vrijednost uvoza ", RPT_W2 ) + Transform( hPDV["22"], PIC_IZN() )
    ?? PadL( cPom, RPT_COL - RPT_RI + 1 )
 
    show_raz_1()
    ?? rpt_lm()
    ?? Space( RPT_RI )
 
    cPom := PadR( _u("13. Isp. oslobođene PDV-a "), RPT_W2 ) + Transform( hPDV["13"], PIC_IZN() )
    ?? PadL( cPom, RPT_COL - RPT_RI + 1 )
 
    ?? Space( RPT_GAP )
 
    ?? Space( RPT_RI )
    cPom := PadR( _u("23. Vrijednost nab. od poljoprivrednika "), RPT_W2 ) + Transform( hPDV["23"], PIC_IZN() )
    ?? PadL( cPom, RPT_COL - RPT_RI + 1 )
 
    show_raz_1()
 
    ?
    ?? rpt_lm()
 
    B_ON
    U_ON
    ?? PadR( "II. Izlazni PDV", RPT_COL - RPT_BOLD_DELTA )
    U_OFF
    B_OFF
 
    ?? Space( RPT_GAP )
    B_ON
    U_ON
    ?? PadL( "Ulazni PDV  ", RPT_COL - RPT_BOLD_DELTA )
    U_OFF
    B_OFF
 
    show_raz_1()
    ?
    ?? rpt_lm()
    ?? Space( RPT_RI )
 
    B_ON
    ?? PadR( " ", RPT_COL - RPT_RI )
    B_OFF
    ?? Space( RPT_GAP )
 
    ?? Space( RPT_RI )
 
    B_ON
    ?? PadR( _u("PDV obračunat na ulaze (dobra i usluge)"), RPT_COL - RPT_RI )
    B_OFF
 
 
    show_raz_1()
 
    ?? rpt_lm()
    ?? Space( RPT_RI )
    cPom := " "
    ?? PadL( cPom, RPT_COL - RPT_RI + 1 )
 
    ?? Space( RPT_GAP )
 
    ?? Space( RPT_RI )
    cPom := PadR( "41. Od reg. PDV obveznika osim 42 i 43", RPT_W2 ) + Transform( hPDV["41"], PIC_IZN() )
    ?? PadL( cPom, RPT_COL - RPT_RI + 1 )
 
    show_raz_1()
 
    ?? rpt_lm()
    ?? Space( RPT_RI )
 
    cPom := " "
    ?? PadR( cPom, RPT_COL - RPT_RI + 1 )
 
    ?? Space( RPT_GAP )
 
    ?? Space( RPT_RI )
    cPom := PadR( "42. PDV na uvoz ", RPT_W2 ) + Transform( hPDV["42"], PIC_IZN() )
    ?? PadL( cPom, RPT_COL - RPT_RI + 1 )
 
    show_raz_1()
    ?? rpt_lm()
    ?? Space( RPT_RI )
    cPom := ""
    ?? PadL( cPom, RPT_COL - RPT_RI + 1 )
 
    ?? Space( RPT_GAP )
 
    ?? Space( RPT_RI )
    cPom := PadR( _u("43. Paušalna naknada za poljoprivrednike "), RPT_W2 ) + Transform( hPDV["43"], PIC_IZN() )
    ?? PadL( cPom, RPT_COL - RPT_RI + 1 )
 
    show_raz_1()
    show_raz_1()
 
    ?? rpt_lm()
    ?? Space( RPT_RI )
    cPom :=  PadR( _u("51. PDV obračunat na izlaz(dobra i usluge) "),  RPT_W2 - RPT_BOLD_DELTA ) + Transform( hPDV["51"], PIC_IZN() )
    B_ON
    ?? PadL( cPom, RPT_COL - RPT_RI - RPT_BOLD_DELTA + 1 )
    B_OFF
 
    ?? Space( RPT_GAP )
 
    ?? Space( RPT_RI )
    B_ON
    cPom := PadR( "61. Ulazni PDV (ukupno) ", RPT_W2 - RPT_BOLD_DELTA ) + Transform( hPDV["61"], PIC_IZN() )
    ?? PadL( cPom, RPT_COL - RPT_RI - RPT_BOLD_DELTA + 1 )
    B_OFF
 
    show_raz_1()
    show_raz_1()
 
    ?? rpt_lm()
    ?? Space( RPT_RI )
    cPom := PadR( "71. Obaveza PDV-a za uplatu/povrat ", RPT_W2 - RPT_BOLD_DELTA ) + Transform( hPDV["71"], PIC_IZN() )
    B_ON
    ?? PadL( cPom, RPT_COL - RPT_RI - RPT_BOLD_DELTA + 1 )
    B_OFF
 
    ?? Space( RPT_GAP )
 
    ?? Space( RPT_RI )
    cPom := PadR( "80. Zahtjev za povrat ", RPT_W2 - RPT_BOLD_DELTA - 5 ) + " <" + iif( "N" == "D", "X", " " ) + ">"
    B_ON
    ?? PadL( cPom, RPT_COL - RPT_RI - RPT_BOLD_DELTA  + 1 )
    B_OFF
 
    show_raz_1()
 
    ?
    ?? rpt_lm()
 
    B_ON
    U_ON
    ?? PadR( _u("III. STATISTIČKI PODACI"), RPT_COL - RPT_BOLD_DELTA )
    U_OFF
    B_OFF
 
    show_raz_1()
    ?? rpt_lm()
    ?? Space( RPT_RI )
    cPom := "PDV isporuke licima koji nisu reg. PDV obveznici u:"
    ?? cPom
 
    show_raz_1()
 
    ?? rpt_lm()
    ?? Space( RPT_RI )
    cPom := PadR( "32. Federacije BiH ", RPT_W2 ) + Transform( hPDV["32"], PIC_IZN() )
    ?? PadL( cPom, RPT_COL - RPT_RI + 1 )
 
    show_raz_1()
 
    ?? rpt_lm()
    ?? Space( RPT_RI )
    cPom := PadR( "33. Republike Srpske ", RPT_W2 ) + Transform( hPDV["33"], PIC_IZN() )
    ?? PadL( cPom, RPT_COL - RPT_RI + 1 )
 
    show_raz_1()
    ?? rpt_lm()
    ?? Space( RPT_RI )
    cPom := PadR( _u("34. Brčko Distrikta "), RPT_W2 ) + Transform( hPDV["34"], PIC_IZN() )
    ?? PadL( cPom, RPT_COL - RPT_RI + 1 )
 
    show_raz_1()
    show_raz_1()
 
    ?? rpt_lm()
    ??U "Pod krivičnom i materijalnom odgovornošću potvrđujem da su podaci u PDV prijavi potpuni i tačni"
 
    /*
    show_raz_1()
    show_raz_1()
 
    ?? rpt_lm()
    ?? "Mjesto : "
    U_ON
 
    //cPom := AllTrim( pot_mjesto )
    //?? PadC( cPom, Len( pot_mjesto ) )
    U_OFF
 
    ?? Space( 35 )
    ?? "Potpis obveznika"
 
    show_raz_1()
 
    ?? rpt_lm()
 
    ?? "Datum : "
    U_ON
    //?? pot_datum
    U_OFF
 
    ?? Space( 50 )
    U_ON
    //cPom := AllTrim( pot_ob )
    ?? PadC( cPom, 55 )
    U_OFF
 
    show_raz_1()
    ?? rpt_lm()
    ?? Space( 86 )
    ?? "Ime, prezime"
    */
 
    FF
    ENDPRINT
 
    RETURN .T.


STATIC FUNCTION show_raz_1()

        ?
        ?
     
RETURN .T.

STATIC FUNCTION rpt_lm()

        RETURN Space( RPT_LM )
