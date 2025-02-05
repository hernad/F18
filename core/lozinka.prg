#include "f18.ch"

#define LOZINKA_LEN 4
#define MAGIC_CODE "X387"

FUNCTION f18_prijava( nX, nY )

    LOCAL nChar
    LOCAL cKorSif
    LOCAL nSifLen
    LOCAL nPom
    LOCAL cResponse
    LOCAL cBrojac
    LOCAL nPrevKorRec
    LOCAL cUserLozinka := fetch_metric( "f18_lozinka", my_user(), "" )

    CLOSE ALL
    nSifLen := LOZINKA_LEN
 
    IF Alltrim(cUserLozinka) == ""
        Alert(_u("U narednom unosu postavite lozinku dužine ") + alltrim(str(nSifLen)) + " cifre")
    ENDIF

    if cUserLozinka == MAGIC_CODE
      RETURN "1"
    endif

    DO WHILE .T.
 
       SetPos ( nX + 4, nY + 15 )
       cKorSif := Upper( f18_get_lozinka( nSifLen ) )
 #ifdef F18_DEBUG
       ?E "f18_prijava", cKorSif
 #endif
       IF Empty( cKorSif )
          MsgBeep( "ERR unijeti lozinku" )
          LOOP
       ENDIF
 

       //IF ( goModul:lTerminate )
       //   RETURN "X"
       //ENDIF
 
       set_cursor_off()
       SetColor ( f18_color_normal() )


       IF f18_check_password( cKorSif, nSifLen, @cResponse ) == 0
          LOOP
       ELSE
          EXIT
       ENDIF
 
    ENDDO
 

    RETURN cResponse


STATIC FUNCTION f18_check_password( cInput, nSifLen, cResponse )

    //cKorSif := CryptSC( PadR( Upper( Trim( cKorSif ) ), nSifLen ) )
    LOCAL cUserLozinka := fetch_metric( "f18_lozinka", my_user(), "" )
 
    // lozinka nije setovana

    if alltrim(cUserLozinka) == "" 
        IF LEN(cInput) < nSifLen
            Alert(_u("Lozinka mora biti dužine ") + Alltrim(Str(nSifLen)) + " znaka!")
            cResponse := "X"
            RETURN 1
        ELSE
            set_metric( "f18_lozinka", my_user(), AllTrim( cInput ) )
            Alert("Postavljena lozinka za unos: '" + Alltrim(cInput) + "'" )
            cResponse := "1"
            RETURN 1
        ENDIF
    endif

    
    if alltrim(cInput) == "X"
        cResponse := "X"
        RETURN 1
    elseif alltrim(cInput) == alltrim(cUserLozinka)
        cResponse := "1"
        RETURN 1
    ELSE
        MsgBeep ( "Unijeta je nepostojeća lozinka !" )
        cResponse := "E"
        RETURN 0
    ENDIF
    
    

    RETURN 0

FUNCTION f18_set_lozinka()

LOCAL cUserLozinka := fetch_metric( "f18_lozinka", my_user(), "" )
LOCAL nSifLen := 4
LOCAL cInput

cInput := Upper( f18_get_lozinka( nSifLen ) )

cInput := Alltrim(cInput)

IF LEN(cInput) < nSifLen
     Alert("Šifra mora biti dužine " + Alltrim(Str(nSifLen)) + " znaka!")

    RETURN .F.
ELSE
    set_metric( "f18_lozinka", my_user(), AllTrim( cInput ) )
    Alert("Postavljena lozinka za unos: '" + Alltrim(cInput) + "'" )

    RETURN .T.
ENDIF

RETURN .T.
 



FUNCTION f18_get_lozinka( nSiflen )

    LOCAL cKorsif, nChar

    cKorsif := ""
    Box(, 2, 30 )
    @ box_x_koord() + 2, box_y_koord() + 2 SAY "F18 Lozinka: "
 
    DO WHILE .T.
 
       nChar := Inkey( 0 )
 #ifdef F18_DEBUG
       ?E "pos_get_lozinka", nChar
 #endif
 
       IF nChar == K_ESC
          cKorsif := ""
 
       ELSEIF ( nChar == 0 ) .OR. ( nChar > 128 )
          LOOP
 
       ELSEIF ( nChar == K_ENTER )
          EXIT
 
       ELSEIF ( nChar == K_BS )
          cKorSif := Left( cKorsif, Len( cKorsif ) - 1 )
 
       ELSE
 
          IF Len( cKorsif ) >= nSifLen // max 15 znakova
             Beep( 1 )
          ENDIF
 
          IF ( nChar > 1 )
             cKorsif := cKorSif + Chr( nChar )
          ENDIF
 
       ENDIF
 
       @ box_x_koord() + 2, box_y_koord() + 15 SAY PadR( Replicate( "*", Len( cKorSif ) ), nSifLen )
       IF ( nChar == K_ESC )
          LOOP
       ENDIF
 
    ENDDO
 
    BoxC()
 
    set_cursor_on()
 
    RETURN PadR( cKorSif, nSifLen )
 