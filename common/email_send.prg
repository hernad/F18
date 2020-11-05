/*
 * This file is part of the bring.out knowhow ERP, a free and open source
 * Enterprise Resource Planning software suite,
 * Copyright (c) 1994-2018 by bring.out doo Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including FMK specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_knowhow.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */

#include "f18.ch"

#include "simpleio.ch"

// ---------------------------------------------------------
// mail_params = hb_hash()
// attachments = {}
//
// koristi se na sljedeci nacin:
// -------------------------------------------------------
// // priprema podataka za slanje na osnovu parametara f18
// // sve sto ne navedemo bit ce dafault iz postavki
//
// _mail_params := f18_email_prepare( subject, body )
//
// // fajlovi za slanje
//
// _attach := { fajl1, fajl2, fajl3 } ili nil
//
// // glavna funkcija koja salje email na destinaciju
//
// f18_email_send( _mail_params, _attach )
//
//
// ---------------------------------------------------------
FUNCTION f18_email_send( mail_params, attach )

   LOCAL _pop_srv := ""
   LOCAL _smtp_pass := ""
   LOCAL _pop_auth := .F.
   LOCAL _no_auth := NIL
   LOCAL _timeout := NIL
   LOCAL _tls := .F.
   LOCAL _encoding := ""
   LOCAL _charset := "UTF-8"
   LOCAL _priority := NIL
   LOCAL _read := NIL
   LOCAL _trace := .F.
   LOCAL _ret := .F.
   LOCAL _files := NIL
   LOCAL _server, _port, _user, _pass, _from, _to, _cc, _bcc, _repl_to, _body, _subject

   _server := mail_params[ "server" ]
   _port := mail_params[ "port" ]
   _user := mail_params[ "user_name" ]
   _pass := mail_params[ "user_password" ]
   _from := mail_params[ "mail_from" ]
   _to := mail_params[ "mail_to" ]
   _cc := mail_params[ "mail_cc" ]
   _bcc := mail_params[ "mail_bcc" ]
   _repl_to := mail_params[ "mail_reply_to" ]
   _body := mail_params[ "mail_body" ]
   _subject := mail_params[ "mail_subject" ]
   _trace := mail_params[ "trace" ]
   _smtp_pass := mail_params[ "smtp_password" ]
   _no_auth := mail_params[ "no_auth" ]

   IF attach <> NIL .AND. Len( attach ) <> 0
      _files := attach
   ENDIF


   IF tip_MailSend( _server, ;
         _port, ;
         _from, ;
         _to, ;
         _cc, ;
         _bcc, ;
         _body, ;
         _subject, ;
         _files, ;
         _user, ;
         _pass, ;
         _pop_srv, ;
         _priority, ;
         _read, ;
         _trace, ;
         _pop_auth, ;
         _no_auth, ;
         _timeout, ;
         _repl_to, ;
         _tls, ;
         _smtp_pass, ;
         _charset, ;
         _encoding )

      _ret := .T.

   ELSE

      error_bar( "email", "Email pristup ne radi !" )
      _ret := .F.

   ENDIF

   RETURN _ret



// -----------------------------------------------------------------
// iscitaj porametre i pripremi za slanje email-a
// -----------------------------------------------------------------
FUNCTION f18_email_prepare( subject, body, m_from, m_to, m_cc, m_bcc, m_reply )

   LOCAL _mail_params := hb_Hash()

   _mail_params[ "trace" ] := .F.
   _mail_params[ "no_auth" ] := NIL
   _mail_params[ "server" ] := AllTrim( fetch_metric( "email_server", my_user(), "" ) )
   _mail_params[ "port" ] := fetch_metric( "email_port", my_user(), 25 )
   _mail_params[ "user_name" ] := AllTrim( fetch_metric( "email_user_name", my_user(), "" ) )
   _mail_params[ "user_password" ] := AllTrim( fetch_metric( "email_user_pass", my_user(), "" ) )
   _mail_params[ "smtp_password" ] := ""

   IF m_from == NIL
      _mail_params[ "mail_from" ] := AllTrim( fetch_metric( "email_from", my_user(), "" ) )
   ELSE
      _mail_params[ "mail_from" ] := m_from
   ENDIF

   IF m_to == NIL
      _mail_params[ "mail_to" ] := { AllTrim( fetch_metric( "email_to_default", my_user(), "" ) ) }
   ELSE
      _mail_params[ "mail_to" ] := get_email_array( m_to )
   ENDIF

   IF m_cc == NIL
      _mail_params[ "mail_cc" ] := { AllTrim( fetch_metric( "email_cc_default", my_user(), "" ) ) }
   ELSE
      _mail_params[ "mail_cc" ] := get_email_array( m_cc )
   ENDIF

   IF m_bcc == NIL
      _mail_params[ "mail_bcc" ] := ""
   ELSE
      _mail_params[ "mail_bcc" ] := get_email_array( m_bcc )
   ENDIF

   IF m_reply == NIL
      _mail_params[ "mail_reply_to" ] := ""
   ELSE
      _mail_params[ "mail_reply_to" ] := m_reply
   ENDIF

   IF body == NIL
      _mail_params[ "mail_body" ] := "empty body"
   ELSE
      _mail_params[ "mail_body" ] := body
   ENDIF

   IF subject == NIL
      _mail_params[ "mail_subject" ] := "empty subject"
   ELSE
      _mail_params[ "mail_subject" ] := subject
   ENDIF

   RETURN _mail_params



// ---------------------------------------------------------
// vraca array email-ova na osnovu stringa
// ---------------------------------------------------------
STATIC FUNCTION get_email_array( email_string )

   LOCAL _arr := {}

   _arr := TokToNiz( email_string, "," )

   RETURN _arr



// --------------------------------------------------------
// testiranje slanja email-a
// --------------------------------------------------------
FUNCTION f18_email_test()

   LOCAL _mail_params
   LOCAL _subject := "Test email generated by Harbour"
   LOCAL _body := "Test email generated by Harbour & F18"
   LOCAL _to := fetch_metric( "fakt_dokument_na_email", my_user(), "" )
   LOCAL _attach := nil

   IF Empty( _to )
      MsgBeep( "Nije podesen primaoc u fakt/parametri/razno !!!" )
      RETURN
   ENDIF

   _mail_params := f18_email_prepare( _subject, _body, NIL, _to )

   f18_email_send( _mail_params, _attach )

   RETURN .T.




/*
   Opis: vraća hash matricu pripremljenu za slanje emaila u podršku
*/

FUNCTION email_hash_za_podrska_bring_out( subject, body )

   LOCAL _mail_params, _from, _to
   LOCAL _srv, _port, _username, _pwd

   _to := "F18@bug.out.ba"
   _from := "F18@bug.out.ba"
   _srv := "smtp.bug.out.ba"
   _port := 999
   _username := "xx"
   _pwd := "xx"

   _mail_params := f18_email_prepare( subject, body, _from, _to )

   _mail_params["server"] := _srv
   _mail_params["port"] := _port
   _mail_params["user_name"] := _username
   _mail_params["user_password"] := _pwd
   _mail_params["trace"] := .f.
   _mail_params["mail_cc"] := ""
   _mail_params["mail_bcc"] := ""
   _mail_params["mail_reply_to"] := ""

   RETURN _mail_params
