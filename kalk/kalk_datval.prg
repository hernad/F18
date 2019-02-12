#include "f18.ch"

FUNCTION get_kalk_14_datval( cBrojKalk )

   LOCAL dRet

   PushWa()
   IF !find_kalk_doks_by_broj_dokumenta( self_organizacija_id(), "14", cBrojKalk )
      dRet := CToD( "" )
   ELSE
      dRet := kalk_doks->datval
   ENDIF
   PopWa()

   RETURN dRet


FUNCTION update_kalk_14_datval( cBrojKalk, dDatVal )

   LOCAL hRec

   PushWa()
   IF !find_kalk_doks_by_broj_dokumenta( self_organizacija_id(), "14", cBrojKalk )
      APPEND BLANK
   ENDIF

   hRec := dbf_get_rec()
   hRec[ "idvd" ] := "14"
   hRec[ "brdok" ] := cBrojKalk
   hRec[ "idfirma" ] := self_organizacija_id()
   hRec[ "datval" ] := dDatVal

   update_rec_server_and_dbf( "kalk_doks", hRec, 1, "FULL" )
   PopWa()

   RETURN .T.
