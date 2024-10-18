#include "f18.ch"

FUNCTION lisec_export_credit_limit()
    
  
   LOCAL dDatdo := Date()
   LOCAL GetList := {}
   LOCAL cIdPartner := 0

   LOCAL cIdKonto1 := fetch_metric("fin_lisec_kupci_1", my_user(), PADR('2110',7))
   LOCAL cIdKonto2 := fetch_metric("fin_lisec_kupci_2", my_user(), PADR('2100',7))
   LOCAL cIdKonto3 := fetch_metric("fin_lisec_kupci_3", my_user(), PADR('2120',7))
   LOCAL cIdKonto4 := fetch_metric("fin_lisec_kupci_4", my_user(), PADR('2119',7))
   LOCAL cIdKonto5 := fetch_metric("fin_lisec_kupci_5", my_user(), PADR('2129',7))
   LOCAL cIdKonto6 := fetch_metric("fin_lisec_kupci_6", my_user(), PADR('',7))
   

   Box(, 9, 60)
     @ box_x_koord() + 1, box_y_koord() + 2 SAY "Stanje na dan"  GET dDatDo
     @ box_x_koord() + 3, box_y_koord() + 2 SAY "   1. konto:"  GET cIdKonto1
     @ box_x_koord() + 4, box_y_koord() + 2 SAY "   2. konto:"  GET cIdKonto2
     @ box_x_koord() + 5, box_y_koord() + 2 SAY "   3. konto:"  GET cIdKonto3
     @ box_x_koord() + 6, box_y_koord() + 2 SAY "   4. konto:"  GET cIdKonto4
     @ box_x_koord() + 7, box_y_koord() + 2 SAY "   5. konto:"  GET cIdKonto5
     @ box_x_koord() + 8, box_y_koord() + 2 SAY "   6. konto:"  GET cIdKonto6
     
     READ
   BoxC()

   IF LastKey() == K_ESC
      RETURN .F.
   ENDIF

   set_metric("fin_lisec_kupci_1", my_user(), cIdKonto1)
   set_metric("fin_lisec_kupci_2", my_user(), cIdKonto2)
   set_metric("fin_lisec_kupci_3", my_user(), cIdKonto3)
   set_metric("fin_lisec_kupci_4", my_user(), cIdKonto4)
   set_metric("fin_lisec_kupci_5", my_user(), cIdKonto5)
   set_metric("fin_lisec_kupci_6", my_user(), cIdKonto6)

   lisec_export_kupci_stanje( cIdKonto1, cIdKonto2, cIdKonto3, cIdKonto4, cIdKonto5, cIdKonto6, dDatDo)

   
   RETURN .T.


STATIC FUNCTION lisec_export_kupci_stanje( cIdKonto1, cIdKonto2, cIdKonto3, cIdKonto4, cIdKonto5, cIdKonto6, dDatDo)

    LOCAL cQuery, oDataSet, oRow, cKonta
    LOCAL cIdFirma := self_organizacija_id()
    LOCAL cIdPartner, nSaldo, nCnt
    LOCAL nH
    LOCAL cFileName := "TFLIORDER.TXT", lCreate

    LOCAL cLokacijaExport := my_home() + "lisec" + SLASH

    IF DirChange( cLokacijaExport ) != 0
       lCreate := MakeDir ( cLokacijaExport )
       IF lCreate != 0
          MsgBeep( "kreiranje " + cLokacijaExport + " neuspjesno ?!" )
          log_write( "dircreate err:" + cLokacijaExport, 6 )
          RETURN .F.
       ENDIF
    ENDIF

    cKonta := ""
    IF !Empty(cIdKonto1)
        IF !Empty(cKonta)
            cKonta += ","
        ENDIF
        cKonta += sql_quote(cIdKonto1)
    ENDIF
    IF !Empty(cIdKonto2)
        IF !Empty(cKonta)
            cKonta += ","
        ENDIF
        cKonta += sql_quote(cIdKonto2)
    ENDIF
    IF !Empty(cIdKonto3)
        IF !Empty(cKonta)
            cKonta += ","
        ENDIF
        cKonta += sql_quote(cIdKonto3)
    ENDIF
    IF !Empty(cIdKonto4)
        IF !Empty(cKonta)
            cKonta += ","
        ENDIF
        cKonta += sql_quote(cIdKonto4)
    ENDIF
    IF !Empty(cIdKonto5)
        IF !Empty(cKonta)
            cKonta += ","
        ENDIF
        cKonta += sql_quote(cIdKonto5)
    ENDIF
    IF !Empty(cIdKonto6)
        IF !Empty(cKonta)
            cKonta += ","
        ENDIF
        cKonta += sql_quote(cIdKonto6)
    ENDIF

    Ferase( cLokacijaExport + cFileName )
    IF File( cLokacijaExport + cFileName )
        Alert("Fajl već otvoren " + cFileName + " ?!")
        RETURN .F.
    ENDIF

    nH := FCreate( cLokacijaExport + cFileName )

    // idlisec=60 => kust_kto='999472   '
    // select kust_kto_buch from fmk.lisec_kust 
    //  where vk_ek=0 and kunr=60 

    /*
    select * FROM (SELECT fmk.lisec_kust.kunr as id_lisec, idpartner, 
             SUM( CASE WHEN d_p = '1' THEN iznosbhd ELSE -iznosbhd END ) AS saldo
       FROM fmk.fin_suban
       LEFT JOIN fmk.lisec_kust on trim(fmk.lisec_kust.kust_kto_buch)=fmk.fin_suban.idpartner
       WHERE idkonto in ( '2110   ' )
       GROUP BY idpartner, kunr) lisec_saldo
        where id_lisec is not null
        ORDER BY id_lisec
    */

    cQuery := "select * FROM (SELECT fmk.lisec_kust.kunr as id_lisec, idpartner, SUM( CASE WHEN d_p = '1' THEN iznosbhd ELSE -iznosbhd END ) AS saldo" +;
       " FROM fmk.fin_suban" +;
       " LEFT JOIN fmk.lisec_kust on trim(fmk.lisec_kust.kust_kto_buch)=trim(fmk.fin_suban.idpartner)" + ;
       " WHERE idkonto in (" + cKonta + ")"

    IF dDatDo <> NIL
       cQuery += " AND datdok <= " + sql_quote( dDatDo )
    ENDIF

    cQuery += " AND idfirma = " + sql_quote( cIdFirma ) +;
       " GROUP BY idpartner, kunr) lisec_saldo" +;
       " WHERE id_lisec is not NULL" +; 
       " ORDER BY id_lisec"
 

    oDataSet := run_sql_query( cQuery )

    nCnt :=0
    Box(,3, 60)
    DO WHILE !oDataSet:Eof()
        nCnt++

        oRow := oDataSet:GetRow()
        cIdPartner := oRow:FieldGet( oRow:FieldPos( "id_lisec" ) )
        nSaldo := oRow:FieldGet( oRow:FieldPos( "saldo" ) )
        @ box_x_koord() + 1, box_y_koord() + 1 SAY cIdPartner        
        @ box_x_koord() + 1, col() + 2 SAY nSaldo     

        FWrite( nH, AllTrim(Str(cIdPartner, 10, 2)) + " 51 " +  AllTrim(STR(nSaldo, 15, 2)) + hb_eol() )
        oDataSet:Skip()
        
    ENDDO
    BoxC()

    FClose( nH )
     
    MsgBeep("Obradjeno :" + STR(nCnt, 5, 0) + " zapisa" + "##" + cLokacijaExport + "#" + cFileName )
 
    RETURN .T.