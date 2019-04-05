# F18 klijent, lista promjena

## 2019-04-05

-  KALK 11 fix gkolicin2 22->11 BUG
-  KALK KARTICA PROD popust

## 2019-04-04

-  KALK 11 stdok prevrne prodavnica-magacin

## 2019-04-02

-  KALK 81 fix

## 2019-03-29

-  KALK kontiranje grande na kvadrat cleanup
-  gBaznaValuta out
-  kurs() kraju generacije fin_pripr

## 2019-03-28

-  ažuriranje KALK-FIN sa što manje pitanja
-  ažuriranje KALK-FIN fin priprema brisanje
-  fix kontiranje 11

## 2019-03-27

-  revert select_o_trfp use via use_sql_trfp()
-  kalk brojaci PSQL/SP
-  kalk 11, 21 - kontrola postojanja brfaktp
-  pos roba, partn readonly
-  cleanup - zabrana CTRL_F9

## 2019-03-26

- FIX KALK 22-11

## 2019-03-25

- POS kada ima vise cijena, prikazati stanje
- POS 89 -> KALK 81 workflow
- KALK 81, 89 stampa PDF

## 2019-03-24

- KALK maloprodaja konverzije
- fix build

## 2019-03-22

- POS 22 workflow
- POS stanje i kartice
- FIX pos stanje

## 2019-03-21

- 02 - zaduženje roba sa količinom 0
- POS realizacija kase
- kontiranje 42-ke u shemama kontiranja ima POREZ2
- FIN nalog pdf
- POS pracenje stanja vraceno
- POS fix pos_osob init
- KALK 21 generacija


## 2019-03-20

- f18.sifk, f18.sifv cleanup
- pos_osob, vrstep - fmk schema pos out
- fiskalni parametri
- fiskalni loop fix
- fiskalne funkcije belaji
- osnovne info fix

## 2019-03-19

- out sql_cleanup, sql_cleanup_all
- parametar `db_version`, out tabela schema_migrations

## 2019-03-16

- POS TREMOL fiskalne funkcije
- roba_id uuid - blacklist

## 2019-03-14

- KALK 02, POS 42 - KALK 49

## 2019-03-12

- TKV v2

## 2019-03-06

- POS PM  --pos-pm

## 2019-03-06

- KALK TKV fix KO

## 2019-02-26

- KALK IM obrazac PDF


## 2019-02-25

- KALK 16, 95, 96

## 2019-02-23

- ci fix
- debug pdf-view inkey(0.2) -> inkey(0)

## 2019-02-20

- KALK, POS maloprodaja init

## 2019-02-07

- POS grande cleanup/1

## 2019-01-30

- FAKT azur: bugfix: `IF s_hF18Dbfs[ cDatabase ][ cItem ][ "wa" ] == hItem[ "wa" ]` => `IF s_hF18Dbfs[ cDatabase ][ cItem ][ "table" ] == hItem[ "table" ]`
- DEBUG windows setprc(0,0), outstd(""), inkey(0.2)
- DEBUG windows PDF output

## 2019-01-29

- windows terminal save screen/restore kad je hb_cdpSelect( "SLWIN" ) - brljotina
- DEBUG `[vscode]` output
- OutStd(...vscode...)
- `F18_ESHELL=1`, PDF `[vscode#pdf.view]<file>[vscode#end]`

## 2019-01-28

- bruto bilansi pdf: fix paginacija, rekapitulacija po klasama na novu stranu
- bruto bilans pdf: analitika, sintetika

## 2019-01-25

- command line parametri: `-ua` - admin user, `-up` - admin password
- `<shift+F10>` - admin meni

## 2019-01-23

- F18_HOME envar - nova lokacija podataka
- refaktor f18_use_module(), fix F_FAKT_PRIPR_DUPLO
- cre_dbfs when --epdv: `IF get_f18_param("run") == "epdv" .OR. f18_use_module( "epdv" )`

## 2019-01-22

- EXE/../F18_util, EXE/../F18_template
- run --dbf-prefix, os, ld, fakt, ePDV
- PQReceive()

## 2019-01-19

- merge origin/3-fix
- azure-pipelines CHANGELOG.md trigger
- bintray hernad -> bringout

## 3.1.319-std, 2019-01-10

- IM cijena (vpc=nc)


## 3.1.318-std, 2019-01-08

- FAKT partn.idrefer specifikacija prodaje po količinama

## 3.1.317-std, 2019-01-08

- FAKT lista dokumenata partn.idrefer

## 3.1.316-std, 2018-09-30

- appveyor F18_RNAL out

## 3.1.216-std, 2018-09-26

- naša slova "prosječna ..."

## 3.1.214-std, 2018-06-27
### CORE
- f18_editor linux async

## 3.1.213-std, 2018-06-21
### CORE
- F18_ELECTRON_HOST - HB_INKEY_ALL / F18_GUI - HB_INKEY_EXT

## 3.1.212-std, 2018-06-04
### KALK
- fix: KALK IP ručni unos(popisana količina, mpc, nc)
- fix: KALK prodavnice rekapitulacija tarifa ažurirani dokument

## 3.1.204-std, 2018-05-16
### OS
- fix: OS export datopt

## 3.1.203-std, 2018-03-21
### CORE
- fix: Odabir organizacija > 120

## 3.1.199-std, 2018-03-20
### CORE
- ENTER keystorm fix

## 3.1.190-std, 2018-03-02
### CORE
- Prefix u svim sql upitima gdje se pojavljuje public.usr: `set search_path to fmk,public;` select ... from public.usr

## 3.1.183-std, 2018-02-19
### OS
- os_promj crna rupa fix

## 3.1.180-std, 2018-02-16
### OS
- fix os_promj sem
### KALK
- fix sast admin promjena učešća sirovine u sastavnicama

## 3.1.179-std, 2018-02-15
### OS
- unos OS, amort prikaz sve stope
### KALK
- ulazna kalkulacija, provjera odstupanja nabavne cijene iznad praga 99.99%
- kartica magacin, prodavnica - unos po barkodovima fix

## 3.1.171-std, 2018-01-11
### FIN
- datval fix, početno stanje po otvorenim stavkama

## 3.1.153-std, 2017-11-23
### CORE
- sif partner F9 - auto novi id

### FAKT
- fakt pratiti stanje roba, S - sifarnik FAKT stanje pregled

## 3.1.147-std, 2017-11-17
### CORE
- Wpar +bug NIL var
- LD obr 2001 cleanup bug * koef NIL

## 3.1.140-std, 2017-10-27
### VIRM
- bugfix cre virm_pripr.dbf

## 3.1.135-std, 2017-10-25
### LD
- debug5 specif 2001

## 3.1.118-std, 2017-10-19
### CORE
- kada smo u modulu kalk stanje robe "S" - prikaz stanja magacinskih konta
- ROBA: kod unosa nove šifre ili ispravke polja barkod ispitati da li već postoji barkod

## 3.1.117-std, 2017-10-16
### KALK-POS
- kalk razduženje magacina na osnovu pos realizacije
- POS stanje robe = kalk magacin stanje

## 3.1.116-std, 2017-10-13
### CORE
- cleanup f18_start_edit, editor B/W, ESC izlaz
### KALK
- kalk - pos procedura cleanup
- kalk parametrizirano (opet) kalk konverzija valute KM/EUR pri unosu dokumenata 10, 81

## 3.1.113-std, 2017-10-12
### CORE
- Pretraga šifri: "SO. " - sortiraj po nazivu, traži sve što počinje sa "SO"

## 3.1.112-std, 2017-10-12
### FAKT
- barkod terminal import - is_roba_aktivna(), na terminal se eksportuju samo aktivni artikli, oni koji postoje u prometu kalk_kalk

## 3.1.108-std, 2017-10-12
### POS
- pos semafori out

## 3.1.106-std, 2017-10-11
### KALK
- unos barkod = D, fix unos dokumenata

## 3.1.104-std, 2017-10-09
### FAKT
- kartica od-do

## 3.1.101-std, 2017-09-19
### FIN
- ostav F5-F6 debug

## 3.1.100-std, 2017-09-13
### CORE
- p_sifra empty - prikazati sve šifre
### FIN
- IOS template update
- FAKT-FIN kontiranje hack zaokruženje izbačen

## 3.1.97-std, 2017-09-12
### FIN
- IOS saldo 0 print D/N
### FAKT
- FAKT pregled dokumenata sort (D)atdok/(B)rdok

## 3.1.95-std, 2017-09-07
### CORE
- upgrade pitati samo prilikom prvog ulaska u aplikaciju

## 3.1.94-std, 2017-09-06
### FIN
- BUGFIX: fin otvorene stavke ručno zatvaranje F5-F6, kartica za odredjeni broj veze sort po datumu
### FAKT
- BUGFIX: kalk_2_fakt

## 3.1.90-std, 2017-09-05
### FAKT
- BUGFIX: fakt-kalk normativi select_o_sastavnice()

## 3.1.89-std, 2017-09-05
### FAKT
- BUGFIX: realizacija kumulativno po partnerima, stanje robe

## 3.1.88-std, 2017-09-04
### FAKT
- BUGFIX: vrstep fakt štampa liste dokumenata

## 3.1.87-std, 2017-09-04
### FIN
- BUGFIX: fin povrat - storno, kartica po brojevima veze meni

## 3.1.84-std, 2017-08-30
### FIN
- BUGFIX: eutanazija fin ostav rucno, fin kompenz

### CORE
- p_sifra recno=0, empty  vrati FALSE

## 3.1.83-std, 2017-08-29
### FIN
- BUGFIX: unos RJ suban kartica

## 3.1.82-std, 2017-08-25
### Development
- BUGFIX: ld pregled isplata tekući račun

## 3.1.81-std, 2017-08-25
### Development
- BUGFIX: cleanup fin povrat naloga: FIN_POVRAT_NALOGA / 67, Variable does not exist CIDRJ

## 3.1.80-std, 2017-08-25
### KALK
- kalk 10 unos sirovina - fix vpc=0, prikaz prodajne cijene OUT
### FAKT
- fakt unos prikaz stanja partnera kupac/dobavljač
### Developer
- FAKT_FTXT ne FTXT, BUGFIX: SET_TABLE_VALUES_ALGORITAM_VARS / 422, FAKT_FTXT_INO_KLAUZULA / 498

## 3.1.77-std, 2017-08-24
### FIN
- Kompenzacija cleanup

## 3.1.76-std, 2017-08-22
### Developer
- FAKT -> KALK još BUGFIX, pa popravni
- FAKT 11 -> KALK 41
- FAKT export/import polje e_doks->korisnik M(10), e_doks.fpt
- FAKT open_fakt_doks_dbf OUT
- hb_SetKey( hb_keyNew( "C", HB_KF_CTRL ), {|| set_clipboard() } )
- FAKT big-ball-of-mud
- FAKT cre dbf fakt OUT
- FAKT->KALK
- fakt brdok: Left->PadR, sql: Left->rpad

## 3.1.65-std, 2017-08-21
### FAKT
- fakt_open_dbf() out, fakt sql big-bang 03
### CORE
- box_x_koord(), box_y_koord() big-bang


## 3.1.64-std, 2017-08-21
### Developer
- CORE: cleanup sifk-sifv

## 3.1.63-std, 2017-08-21
### KALK
- BUGFIX: početno stanje Alias does not exist/roba

## 3.1.62-std, 2017-08-19
### FAKT
- BUGFIX: FAKT specifikacija prodaje

## 3.1.61-std, 2017-08-18
### EPDV
- BUGFIX: https://redmine.bring.out.ba/issues/36680

## 3.1.60-std, 2017-08-18
### FAKT
- BUGFIX: https://redmine.bring.out.ba/issues/36680

## 3.1.59-std, 2017-08-18
### FAKT
- BUGFIX: majmune
- BUGFIX: fakt_stdok_pdv, LEFT( nil, ... ), hernad nauci se programirati :(
- BUGFIX: udaljena razmjena, fakt import
  - build bug .53 fix
  - fix: .54 Alias does not exist/fakt
### Developer
- BUGFIX: .55 f18.ch Variable does not exist/POS_VD_RACUN

## 3.1.52-std, 2017-08-15
### Developer
- ePDV sql big-bang 01
- ePDV cleanup 1-2-3

## 3.1.51-std, 2017-08-11
### Developer
- FAKT: fakt_fakt, fakt_doks, fakt_doks2 sql

## 3.1.50-std, 2017-08-11
### Developer
- BUGFIX: svašta
  - UGOV generacija radi
  - FAKT pregled dokumenata txt
  - my_browse - refresh prva stavka
  - nova baza "db_name"
  - ugov, rugov

## 3.1.46-std, 2017-08-11
### Developer
- FAKT BUGFIX: seek_fakt ne mogu locirati dokument is_storno

## 3.1.45-std, 2017-08-11
### Developer
- THREAD STATIC self_organizacija_id( cId )
- FAKT OUT_VAR: gResetRoba

## 3.1.44-std, 2017-08-11
### Developer
- POS sql big-bang 01

## 3.1.43-std, 2017-08-08

### Developer
- UGOV sql big-bang 01: ugov, rugov, dest, fakt_gen_ug, fakt_gen_ug_p prebačeni na sql, cleanup

## 3.1.42-std, 2017-08-07

### Developer
- pos.datum, ne pos.datdok
- POS vars cleanup
- POS fix dDatDok variable not found

## 3.1.40-std, 2017-08-04

### Korisnik
#### FAKT
- BUGFIX: Alias does not exist/FAKT_DOKS_PREGLED
- BUGFIX: FAKT tabelarni pregled tipka 'F' - pretvori 20->10, 'K' - ispravka podataka

### Developer
- FAKT: pregled dokumenata 'F' - pretvori 20->10
- CORE: my_browse_f18_komande_with_my_key_handler( oBrowse, nKey, nKeyHandlerRetEvent, nPored, aPoredak, bMyKeyHandler ) - bMyKeyHandler se prvi (uvijek) obrađuje
- FAKT OUT: fakt_generisi_inventuru()
- KALK: KALK_FAKT normativi prenos, fakt sql, nije testirano
- FAKT: realizacija MP fakt sql
- EPDV: fakt_gen_kif() fakt sql

## 3.1.39-std, 2017-08-04

### Developer

- FIN BUGFIX: stampa naloga: zagl_organizacija() FIX marsovac varijabla oServer, hSqlParams
- FAKT BUFGFIX: realizacija kumulativno po partnerima
- KALK 10, validacija - 'ERROR Marza > 100 000 x veća od NC:'
- FAKT tabelarni pregled dokumenata, prva kolona 'F' - is_fiskaliziran()

## 3.1.38-std, 2017-08-01

### Developer
#### FAKT
- FIX FAKT_FTXT->naz
- fakt_valid_roba()
- fakt cleanup usluge hFaktTtxt[ 'opis_usluga' ]

### Poznati problemi

- Variable does not exist/HSQLPARAMS (BUGFIX: 3.1.39)

## 3.1.37-std, 2017-07-31

### Korisnik
#### FIN
- FIX browse <c+F> oBrowse
- Obračun bring.out 07/2017 realizovan sa ovom verzijom


### Developer
#### FIN, FAKT-FIN kontiranje
- Skontao HACK: trfp2 zbog kojeg je zaokruzivao fakt-fin na jednu decimalu.
  - Ako se na kraju opisa trfp2, odnosno fin_pripr stavi jedan od znakova "0125", izvrsice se zaokruzenje round 0,1,2 ili round5. Uh.


## 3.1.36-std, 2017-07-31

### Korisnik
#### FIN
- FIX p_fin_vrsta_naloga

### Developer
#### Korisnik
- p_sifra fix SEEK cId

## 3.1.35-std, 2017-07-31

### Korisnik
#### FIN
- Unos novog naloga zabrana unosa praznog naloga

### Developer
#### FIN
- FIN nalog unos !prazan konto
- FIN priprema cleanup, OUT_PRIV_VAR: fNovi

## 3.1.34-std, 2017-07-31

### Korisnik
#### FIN
- Fix fin_specif_proizv_sort

### Developer
#### FIN
- fix hb_default( @cTipDomacaStranaObje, 1 ) // jednovalutni prikaz - KM

## 3.1.33-std, 2017-07-30

- cleanup sastavnice - sastavnice_print.prg, tag "IDRBR"
- cleanup fiskalne funkcije

## 3.1.32-std, 2017-07-30

- fix stanje, lager, uporedna kalk - fakt
- commit x 2 "FAKT sql big-bang-02" trijebljenje svih seek-ova fakt, fakt_doks, fakt_doks2
 - 74 files +1861 -1862
 - 16 files +255 - 347


## 3.1.31-std, 2017-07-29

### Developer

#### FAKT
- commit "FAKT sql big-bang-01" [3 91e2c85a7 , 99 files changed, 2147 insertions(+), 1527 deletions(-)
- Ažuriranje i dalje radi sa semaforima
- uvedene funkcije seek_fakt, seek_fakt_3 ( tag "3" ), seek_fakt_doks( cIdFirma, cIdTipDok, cBrDok )
- Kartica - SQL
- Pregled tabelarni sql FAKT_DOKS_PREGLED alias
- COOL fazon u fakt_pregled_reload_tables( cFilter ) - kodni blok Eval( s_bFaktDoksPeriod )


## 3.1.29-std, 2017-07-28

### Developer
- my_browse - fakt pregled tabela - ok
- my_browse - sinhronizacija ftxt - inkey(0) vs inkey()
- pos prebačeni svi šifarnici na sql set_a_sql_sifarnik( ... )
- Čišćenje fakt_ftxt do iznemoglosti
- sastavnice
- adresar
- NEW_ALIAS: F_FAKT_TXT, fakt_txt, FAKT_TXT

### Poznati problemi

- Variable does not exist/oBrowse

## 3.1.24-std, 2017-07-28

### Poznati problemi
- Variable does not exist/HFATTXT

## 3.1.20-std, 2017-07-26

### Developer
#### KALK

- MERGE_BRANCH 3-vindi: koncij.region za konto npr 13202 = "RS" => vpc stampa dokumenta
- MERGE_BRANCH 3-vindi: dokumenti 95, 96, 16, 11

## 3.1.17-std, 2017-07-25

### Developer

#### CORE
- RENAME_FUN_VARS: num_to_str( nNumber, nLen, nDec )
- define NRED_DOS

#### FAKT
- Debug štampa fiskalnog iz liste !OK #36677
- Debug #36676 štampa barkod labela, FAKT priprema ALT+L ne radi
- NEW_PRG_FILE: _fakt_sql.prg, fakt_ftxt.prg
- select_o_fakt_txt()
- RENAME_FUN_NAME to fakt_a_to_public_var_txt(), p_fakt_ftxt()
- fakt_txt_fill_djokeri( nSaldoKup, nSaldoDob, dPUplKup, dPPromKup, dPPromDob, dLUplata, cPartner )
- fakt_ftxt_encode( cFTxtNaz, cTxt1, cTxt3a, cTxt3b, cTxt3c, cVezaUgovor, cDodTxt )
- RENAME_FUN_NAME: ParsMemo -> fakt_ftxt_decode( cTxt ) => aMemo
- RENAME_VAR: _memo -> aMemo
- FUN_ADD: find_fakt_ftxt_by_id

#### FIN
- CLEANUP: fin_bruto_bilans_subanalitika_b.prg


## 3.1.10-std, 2017-07-25

### Developer
- BUGFIX KALK lager lista cOpcine

### Poznati problemi
- specif proizvoljni sort: Argument error/$
- Variable does not exist/CUSLOVTIPDOK
- sastavnice, adresar ne rade

## 3.1.9-std, 2017-07-25

### Korisnik

#### KALK
- Trgovačka knjig na veliko i malo (TKV, TKM)  export u XLSX

### Developer
- BUGFIX: Dokument 80 unos tarifa alias not found

## 3.1.6-std, 2017-07-24

### Korisnik

#### CORE
- F18 upgrade - ako je F18 patch broj instalirana > F18 aktuelna ne predlagati downgrade.

Primjer:

Ako je aktuelna verzija za tekući kanal (npr. S) 3.1.5, a trenutno instalirana verzija je 3.1.10, tada se ne predlaže downgrade na 3.1.5.

### Developer
- f18_update.prg - nove funkcije f18_builtin_version_h, f18_available_version_h,  f18_preporuci_upgrade( cVersion )
- OUT: f18_admin.prg upgrade_db
- razvoj prebačen u zajednički branch `3`

## 3.0.11-std, 2017-07-24

### Korisnik

#### CORE
- BUGFIX: F18 upgrade za različite kanale
- OUT: izbačen F18 template update iz priče

### Developer
- f18_admin.prg cleanup:
  - iz upotrebe izbačen UPDATE_INFO
  - templates.zip se više ne koristi, nema ga u formi za upgrade
  - lokacija F18 verzija http://download.bring.out.ba/ hardkodirana
  - OUT: update_db

## 3.0.8-std, 2017-07-24

### Korisnik

#### KALK
- specifična opcija import vindija varazdin izbačeno iz standardne verzije

#### FIN
- BUGFIX run sintetički, analitički bruto bilans
- BUGFIX lista naloga sa provjerom integriteta

### Developer
- OUT: kalk/kalk_imp_txt_racuni.prg, kalk/kalk_imp_txt_roba_partn.prg
- "trijebljenje" do iznemoglosti select_o_partner(), select_o_konto()

## Legenda

Korisnik - promjene značajne za korisnike

Developer - tehničke bilješke, promjene bitne za podršku i razvoj
