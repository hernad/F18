#include "f18.ch"

FUNCTION lisec_export_credit_limit()
    
  
   LOCAL dDatdo := Date()
   LOCAL GetList := {}
   LOCAL cIdPartner := 0
   LOCAL cAvansi :=0

   LOCAL cIdKonto1 := fetch_metric("fin_lisec_kupci_1", my_user(), PADR('2110',7))
   LOCAL cIdKonto2 := fetch_metric("fin_lisec_kupci_2", my_user(), PADR('2100',7))
   LOCAL cIdKonto3 := fetch_metric("fin_lisec_kupci_3", my_user(), PADR('2120',7))
   LOCAL cIdKonto4 := fetch_metric("fin_lisec_kupci_4", my_user(), PADR('2119',7))
   LOCAL cIdKonto5 := fetch_metric("fin_lisec_kupci_5", my_user(), PADR('2129',7))
   LOCAL cIdKonto6 := fetch_metric("fin_lisec_kupci_6", my_user(), PADR('',7))
   LOCAL cIdKontoA1 := fetch_metric("fin_lisec_kupci_a1", my_user(), PADR('4340',7))
   LOCAL cIdKontoA2 := fetch_metric("fin_lisec_kupci_a2", my_user(), PADR('XXXX',7))
   

   Box(, 11, 60)
     @ box_x_koord() + 1, box_y_koord() + 2 SAY "Stanje na dan"  GET dDatDo
     @ box_x_koord() + 3, box_y_koord() + 2 SAY "     1. konto:"  GET cIdKonto1
     @ box_x_koord() + 4, box_y_koord() + 2 SAY "     2. konto:"  GET cIdKonto2
     @ box_x_koord() + 5, box_y_koord() + 2 SAY "     3. konto:"  GET cIdKonto3
     @ box_x_koord() + 6, box_y_koord() + 2 SAY "     4. konto:"  GET cIdKonto4
     @ box_x_koord() + 7, box_y_koord() + 2 SAY "     5. konto:"  GET cIdKonto5
     @ box_x_koord() + 8, box_y_koord() + 2 SAY "     6. konto:"  GET cIdKonto6
     @ box_x_koord() + 9, box_y_koord() + 2 SAY "Avansi domaci:"  GET cIdKontoA1
     @ box_x_koord() + 10, box_y_koord() + 2 SAY "Avansi strani:"  GET cIdKontoA2
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
   set_metric("fin_lisec_kupci_a1", my_user(), cIdKontoA1)
   set_metric("fin_lisec_kupci_a2", my_user(), cIdKontoA2)

   lisec_export_kupci_stanje( cIdKonto1, cIdKonto2, cIdKonto3, cIdKonto4, cIdKonto5, cIdKonto6, cIdKontoA1, cIdKontoA2, dDatDo)

   
   RETURN .T.


STATIC FUNCTION lisec_export_kupci_stanje( cIdKonto1, cIdKonto2, cIdKonto3, cIdKonto4, cIdKonto5, cIdKonto6, cIdKontoA1, cIdKontoA2, dDatDo)

    LOCAL cQueryMain, cQuery, cQueryADomaci, cQueryAStrani, oDataSet, oRow, cKonta, cKontoAvDomaci, cKontoAvStrani
    LOCAL cIdFirma := self_organizacija_id()
    LOCAL nIdPartner, nSaldo, nCnt
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


    /* sa avansima
        select id_lisec, idpartner, sum(saldo) from     
    (
    (select * FROM (SELECT fmk.lisec_kust.kunr as id_lisec, idpartner, 
                SUM( CASE WHEN d_p = '1' THEN iznosbhd ELSE -iznosbhd END ) AS saldo
        FROM fmk.fin_suban
        LEFT JOIN fmk.lisec_kust on trim(fmk.lisec_kust.kust_kto_buch)=trim(fmk.fin_suban.idpartner)
        WHERE idkonto in ( '2110   ' )
        GROUP BY idpartner, kunr) lisec_saldo
            where id_lisec is not null
            ORDER BY id_lisec)
    union
    (select * FROM (SELECT fmk.lisec_kust.kunr as id_lisec, idpartner, 
                round(SUM( CASE WHEN d_p = '1' THEN iznosbhd ELSE -iznosbhd END )*1.17,2) AS saldo
        FROM fmk.fin_suban
        LEFT JOIN fmk.lisec_kust on trim(fmk.lisec_kust.kust_kto_buch)=trim(fmk.fin_suban.idpartner)
        WHERE idkonto in ( '4340   ' )
        GROUP BY idpartner, kunr) lisec_saldo
            where id_lisec is not null
            ORDER BY id_lisec)
    union     
    (select * FROM (SELECT fmk.lisec_kust.kunr as id_lisec, idpartner, 
                SUM( CASE WHEN d_p = '1' THEN iznosbhd ELSE -iznosbhd END ) AS saldo
        FROM fmk.fin_suban
        LEFT JOIN fmk.lisec_kust on trim(fmk.lisec_kust.kust_kto_buch)=trim(fmk.fin_suban.idpartner)
        WHERE idkonto in ( '4341   ' )
        GROUP BY idpartner, kunr) lisec_saldo
            where id_lisec is not null
            ORDER BY id_lisec )
    ) svi 
    group by id_lisec, idpartner
    order by id_lisec
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
 
    cQueryADomaci := "select * FROM (SELECT fmk.lisec_kust.kunr as id_lisec, idpartner, round(SUM( CASE WHEN d_p = '1' THEN iznosbhd ELSE -iznosbhd END )*1.17,2) AS saldo" +;
        " FROM fmk.fin_suban" +;
        " LEFT JOIN fmk.lisec_kust on trim(fmk.lisec_kust.kust_kto_buch)=trim(fmk.fin_suban.idpartner)" + ;
        " WHERE idkonto=" + sql_quote(cIdKontoA1)
    IF dDatDo <> NIL
       cQueryADomaci += " AND datdok <= " + sql_quote( dDatDo )
    ENDIF
    cQueryADomaci += " AND idfirma = " + sql_quote( cIdFirma ) +;
        " GROUP BY idpartner, kunr) lisec_saldo" +;
        " WHERE id_lisec is not NULL" +; 
        " ORDER BY id_lisec"

    cQueryAStrani := "select * FROM (SELECT fmk.lisec_kust.kunr as id_lisec, idpartner, round(SUM( CASE WHEN d_p = '1' THEN iznosbhd ELSE -iznosbhd END )*1.17,2) AS saldo" +;
        " FROM fmk.fin_suban" +;
        " LEFT JOIN fmk.lisec_kust on trim(fmk.lisec_kust.kust_kto_buch)=trim(fmk.fin_suban.idpartner)" + ;
        " WHERE idkonto=" + sql_quote(cIdKontoA2)
    IF dDatDo <> NIL
        cQueryAStrani += " AND datdok <= " + sql_quote( dDatDo )
    ENDIF
    cQueryAStrani += " AND idfirma = " + sql_quote( cIdFirma ) +;
        " GROUP BY idpartner, kunr) lisec_saldo" +;
        " WHERE id_lisec is not NULL" +; 
        " ORDER BY id_lisec"
    altd()
    cQueryMain := "SELECT id_lisec, idpartner, sum(saldo) as saldo_svi FROM ("
    cQueryMain += "(" + cQuery + ")"
    cQueryMain += " union "
    cQueryMain += "(" + cQueryADomaci + ")"
    cQueryMain += " union "
    cQueryMain += "(" + cQueryAStrani + ")"
    cQueryMain += ") svi"
    cQueryMain += " group by id_lisec, idpartner"
    cQueryMain += " order by id_lisec"    
    
    oDataSet := run_sql_query( cQueryMain )

    nCnt :=0
    Box(,3, 60)
    DO WHILE !oDataSet:Eof()
        nCnt++

        oRow := oDataSet:GetRow()
        nIdPartner := oRow:FieldGet( oRow:FieldPos( "id_lisec" ) )
        nSaldo := oRow:FieldGet( oRow:FieldPos( "saldo_svi" ) )
        @ box_x_koord() + 1, box_y_koord() + 1 SAY nIdPartner        
        @ box_x_koord() + 1, col() + 2 SAY nSaldo     

        FWrite( nH, AllTrim(Str(nIdPartner, 10)) + " 51 " +  AllTrim(STR(nSaldo, 15, 2)) + hb_eol() )
        oDataSet:Skip()
        
    ENDDO
    BoxC()

    FClose( nH )
     
    MsgBeep("Obradjeno :" + STR(nCnt, 5, 0) + " zapisa" + "##" + cLokacijaExport + "#" + cFileName )
 
    RETURN .T.