#include "f18.ch"
#include "enabavke_eisporuke.ch"

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

    AAdd( aOpc, "Z. zaključavanje poreznog perioda" )
    AAdd( aOpcexe, {|| fin_lock_porezni_period() } )

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

    
STATIC FUNCTION fin_lock_porezni_period()

  LOCAL dDatOd := fetch_metric( "fin_enab_dat_od", my_user(), DATE()-1 )
  LOCAL dDatDo := fetch_metric( "fin_enab_dat_do", my_user(), DATE() )
  LOCAL cPorezniPeriod := RIGHT(AllTrim(STR(Year(dDatOd))), 2) + PADL(AllTrim(STR(Month(dDatOd))), 2, "0")

  IF Pitanje( ,"Zaključati porezni period '" + cPorezniPeriod + "' D/N?", " " ) == "D"
     IF Pitanje(," Jeste li sigurni da želite zaključati '" + cPorezniPeriod + "' (D/N) ?!",  " " ) == "D"
        set_metric("fin_enab_eisp_lock", NIL, cPorezniPeriod)
        set_metric("fin_enab_eisp_lock_user", NIL, my_user()) 
     ENDIF
  ENDIF


  RETURN .T.

/*
   => .T. ako je moguce raditi generaciju porezni period
   => .F. ako je zakljucan
*/
FUNCTION enab_eisp_check_porezni_period(cPorezniPeriod)
  
  IF fetch_metric("fin_enab_eisp_lock", NIL, "") >= cPorezniPeriod
     Alert(_u("Porezni period '" + fetch_metric("fin_enab_eisp_lock", NIL, "") + ;
             "' je zaključao korisnik '" + fetch_metric("fin_enab_eisp_lock_user", NIL, '') + "'" ;
          ))
      Alert(_u("Generacija nije moguća"))
      RETURN .F.
  ENDIF
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
