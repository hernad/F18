# F18

## build

[![Build status](https://ci.appveyor.com/api/projects/status/eg8qsklygduukk87?svg=true)](https://ci.appveyor.com/project/hernad/f18-knowhow)


## instalacija klijenata


### linux (ubuntu, centos)

    # bash
    curl https://raw.githubusercontent.com/knowhow/F18_knowhow/3/bin/F18_install.sh | bash

### windows

     # u powershell konzoli zadati:
     iex (new-object net.webclient).downloadstring('https://raw.githubusercontent.com/knowhow/F18_knowhow/3/bin/F18_install.ps1')



## F18 log promjena

[F18 CHANGELOG.md](CHANGELOG.md)


## F18 klijent korištenje

### vise instanci F18

    ./F18 --dbf-prefix 1
    ./F18 --dbf-prefix 2

Ovo se koristi u F18 eShell.

### run funkcije pri pokretanju klijenta

    ./F18 --run-on-start kalk_gen_uskladjenje_nc_95\(\)


### Show postgresql version


    ./F18.sh -h 127.0.0.1 -y 5432 -u user -p password -d proba_2018 --show-postgresql-version

=>

<pre>
PostgreSQL 10.4 (Ubuntu 10.4-2.pgdg18.04+1) on x86_64-pc-linux-gnu, compiled by gcc (Ubuntu 7.3.0-16ubuntu3) 7.3.0, 64-bit
</pre>


### Run module

     ./F18.sh -h 127.0.0.1 -y 5432 -u user -p password -d proba_2018 --pos  ## --{pos,fin,kalk}
