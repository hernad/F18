# Developer build environment

## database

### docker F18_test_db

    cd docker
    # ako postoje podaci, zelimo ispocetka
    ./cleanup.sh

    ./start_pgsql_server.sh


    # po ulasku u kontejner (root), kreiranje bjasko korisnika, hernad vec inicijalno postoji
    /scripts/create_user.sh
    # admin user obavlja administrativne poslove i ima pune privilegije
    /scripts/create_admin.sh <poseban_admin_password>

    # lista baza
    /scripts/list_databases.sh

## build notes, downloads.bring.out.ba


### github push


Push 3.1.204 release

     git commit -am "BUILD_RELEASE 3.1.318"
     git tag 3.1.318
     git push origin 3-std --tags




## Update

### Update kanal

* S - stabilne
* E - edge, posljednje verzije
* X - eksperimentalne - razvoj








## git

### delete tag

   scripts/delete_tag.sh 3.0.0


### git config --global --list

       user.email=hernad@bring.out.ba
       user.name=Ernad Husremovic
       user.signingkey=40E1A4FDE2C67C31
       credential.helper=cache --timeout=43200

 signing commits:

        git config --global commit.gpgsign true


## Windows build

### windows MSYS2

       #pacman -Sy git  mingw-w64-i686-make
       pacman -Sy   mingw-w64-i686-postgresql mingw-w64-i686-openssl
       pacman  -Sy base-devel msys2-devel mingw-w64-i686-toolchain upx p7zip
