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

## build notes, appveyor, bintray, downloads.bring.out.ba


### github push


Push 3.1.204 release

     git commit -am "BUILD_RELEASE 3.1.318"
     git tag 3.1.318
     git push origin 3-std --tags


#### bintray zip-ovi publikovanje na greenbox downloads.bring.out.ba

  * https://bintray.com/hernad/F18/F18-linux-x86
  * https://bintray.com/hernad/F18/F18-windows-x86

On greenbox-1 as root(https://redmine.bring.out.ba/issues/36922):

    VER=3.1.204

    cd /data_0/f18-downloads_0/downloads.bring.out.ba/www/files/tmp
    rm *.zip F18 F18.exe
    curl -L  https://bintray.com/hernad/F18/download_file?file_path=F18_windows_x86_${VER}.zip  > win.zip
    unzip win.zip
    ls -lh F18.exe
    gzip -c F18.exe > F18_Windows_${VER}.gz
    mv F18_Windows_${VER}.gz /data_0/f18-downloads_0/downloads.bring.out.ba/www/files/
    ls -lh /data_0/f18-downloads_0/downloads.bring.out.ba/www/files/F18_Windows_${VER}.gz
    echo kraj windows

    cd /data_0/f18-downloads_0/downloads.bring.out.ba/www/files/tmp
    rm *.zip F18 F18.exe
    curl -L  https://bintray.com/hernad/F18/download_file?file_path=F18_linux_x86_${VER}.zip  > linux.zip
    unzip linux.zip
    ls -lh F18
    gzip -c F18 > F18_Ubuntu_i686_${VER}.gz
    mv F18_Ubuntu_i686_${VER}.gz /data_0/f18-downloads_0/downloads.bring.out.ba/www/files/
    ls -lh /data_0/f18-downloads_0/downloads.bring.out.ba/www/files/F18_Ubuntu_i686_${VER}.gz
    echo kraj linux


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


## Appveyor CI


show postgresql server version:

       ./F18 -h 192.168.168.112 -u postgres -p Password12! -d F18_test --show-postgresql-version



[![Build status](https://ci.appveyor.com/api/projects/status/eg8qsklygduukk87?svg=true)](https://ci.appveyor.com/project/hernad/f18-knowhow)
