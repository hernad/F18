#include "f18.ch"


FUNCTION epdv_pdv_prijava_snimi_obracun( dDatOd, dDatDo )

   LOCAL hRec

   select_o_epdv_r_pdv()
   // set_global_vars_from_dbf()
   hRec := dbf_get_rec()

   IF Pitanje( , "Želite li obračun pohraniti u bazu PDV prijava ?", " " ) == "D"

      // select_o_epdv_pdv()
      // SET ORDER TO TAG "period"
      // SEEK DToS( dDatOd ) + DToS( dDatDo )
      // IF !Found()
      IF !find_epdv_pdv_za_period( dDatOd, dDatDo )
         APPEND BLANK
      ELSE
         IF pdv->lock == "D"
            MsgBeep( "Vec postoji obracun koji je zakljucan #promjena NIJE snimljena !" )
            SELECT ( F_PDV )
            USE
            SELECT ( F_R_PDV )
            USE
            RETURN .F.
         ENDIF
      ENDIF

      IF Empty( pdv->datum_1 ) // datum kreiranja
         hRec[ "datum_1" ] := Date()
      ENDIF
      hRec[ "datum_2" ] := Date()   // datum azuriranja


      hRec[ "isp_opor" ] := 0 // ova polja se greskom nalaze u sql epdv_pdv tabeli pa se moraju inicijalizirati
      hRec[ "isp_izv" ] := 0 // polja su prakticno duplikati polja i_opor, i_izvoz itd
      hRec[ "isp_neopor" ] := 0
      hRec[ "isp_nep_sv" ] := 0

      hRec[ "nab_opor" ] := 0 // ista stvar za ovaj set polja
      hRec[ "nab_uvoz" ] := 0
      hRec[ "nab_ne_opo" ] := 0
      hRec[ "nab_st_sr" ] := 0

      hRec[ "u_pdv_r" ] := 0 // ne znam sta ovo polje znaci, nigdje se ne koristi
      hRec[ "pdv_prepla" ] := 0 // i ovo polje postoji samo u epdv_pdv


      hRec[ "i_u_pdv_41" ] := 0
      hRec[ "i_u_pdv_43" ] := 0

      update_rec_server_and_dbf( "epdv_pdv", hRec, 1, "FULL" )

      SELECT ( F_PDV )
      USE

   ENDIF

   RETURN .T.
