#!/bin/bash

# usage
# curl https://raw.githubusercontent.com/knowhow/F18_knowhow/3/bin/F18_install.sh | bash


F18_VER=3.1.215
F18_ZIP_MD5=52255d8cbc049a20f3f160869f541bf7

F18_GZ=F18_${F18_VER}.gz
APT_INSTALL_FILES="libpq5 curl vim vim-gnome  xfonts-terminus-oblique xfonts-terminus"
RPM_INSTALL_FILES="postgresql-libs xorg-x11-fonts-misc terminus-fonts terminus-fonts-console"
RPM_I686_FILES="glibc.i686 postgresql-libs libXinerama.i686 zlib.i686 libstdc++.i686 dbus-libs.i686 libxml2.i686 glib2.i686 cairo.i686 cups-libs.i686 dbus-glib.i686 libglvnd-glx.i686 pixman.i686  gtk3.i686 libX11.i686  libXft.i686 libXpm.i686 libXext.i686 libXtst.i686 libXrandr.i686 libXrender.i686 libXinerama.i686 libXmu.i686"

OS="CENTOS7"


if lsb_release -d | grep "Ubuntu 14" ; then
  OS="UBUNTU14"
elif lsb_release -d | grep "Ubuntu 16" ; then
  OS="UBUNTU16"
fi

ubuntu_install() {

  pwd



  if ! dpkg -l | grep -q terminus ; then
     echo "sudo enabled user - enter password, install $APT_INSTALL_FILES"
     sudo apt-get update -y
     sudo apt-get install -y $APT_INSTALL_FILES
  fi



  if [ -f $F18_GZ ]  ; then
      echo "$F18_GZ postoji"
      if  ! ( md5sum $F18_GZ | grep $F18_ZIP_MD5 )  ; then
        echo "md5 sum gz wrong ! rm gz"
        rm $F18_GZ
      else
        echo "md5 sum OK"
      fi
  fi

  if [ ! -f $F18_GZ ] ; then
      echo "download $F18_VER sa bintray-a"
      curl -L https://bintray.com/hernad/F18/download_file?file_path=F18_linux_x86_$F18_VER.zip > $F18_GZ
  fi

  if [[ $OS == UBUNTU14 ]] ; then
      curl -L https://github.com/knowhow/F18_knowhow/raw/3/bin/UBUNTU14/libstdc%2B%2B.so.6 > libstdc++.so.6 
      chmod +x libstdc++.so.6
  fi

  if [ ! -f F18.png ] ; then
      curl -L https://github.com/knowhow/F18_knowhow/raw/3/bin/F18.png > F18.png
  fi

  cp $F18_GZ F18.gz
  gunzip -f F18.gz
  chmod +x F18

  ls -l F18
}


centos_install() {

  pwd



  if ! rpm -qi xfonts-terminus ; then
     echo "sudo enabled user - enter password, install $RPM_INSTALL_FILES"
     sudo yum install -y epel-release
     sudo rpm --force -i  https://download1.rpmfusion.org/free/el/rpmfusion-free-release-7.noarch.rpm
     sudo yum update -y
     sudo yum install -y $RPM_INSTALL_FILES
     sudo yum install -y http://mirror.centos.org/centos/7/os/x86_64/Packages/vim-X11-7.4.160-4.el7.x86_64.rpm

     if uname -p | grep -q x86_64 ; then
        sudo yum install -y $RPM_I686_FILES
     fi

  fi



  if [ -f $F18_GZ ]  ; then
      echo "$F18_GZ postoji"
      if  ! ( md5sum $F18_GZ | grep $F18_ZIP_MD5 )  ; then
        echo "md5 sum gz wrong ! rm gz"
        rm $F18_GZ
      else
        echo "md5 sum OK"
      fi
  fi

  if [ ! -f $F18_GZ ] ; then
      echo "download $F18_VER sa bintray-a"
      curl -L https://bintray.com/hernad/F18/download_file?file_path=F18_linux_x86_$F18_VER.zip > $F18_GZ
  fi

  if [[ $OS == UBUNTU14 ]] ; then
      curl -L https://github.com/knowhow/F18_knowhow/raw/3/bin/UBUNTU14/libstdc%2B%2B.so.6 > libstdc++.so.6 
      chmod +x libstdc++.so.6
  fi

  if [ ! -f F18.png ] ; then
      curl -L https://github.com/knowhow/F18_knowhow/raw/3/bin/F18.png > F18.png
  fi

  cp $F18_GZ F18.gz
  gunzip -f F18.gz
  chmod +x F18

  ls -l F18
}


echo $OS

cd $HOME
[ -f F18 ] && rm F18

mkdir -p $HOME/F18
cd $HOME/F18

if [[ $OS == UBUNTU* ]] ; then
   ubuntu_install
fi

if [[ $OS == CENTOS* ]] ; then
   centos_install
fi


if [[ $OS == UBUNTU14 || $OS == UBUNTU16 ]] ; then

# unity autohide
cat > F18.sh <<- EOM
#!/bin/sh

# --- echo ubuntu -----
dconf write /org/compiz/profiles/unity/plugins/unityshell/launcher-hide-mode 1

cd ${HOME}/F18
export LD_LIBRARY_PATH=${HOME}/F18
export PATH=${HOME}/F18:\$PATH
./F18

dconf write /org/compiz/profiles/unity/plugins/unityshell/launcher-hide-mode 0
EOM

else


cat > F18.sh <<- EOM
#!/bin/sh

# ---- echo centos ---

cd ${HOME}/F18
export LD_LIBRARY_PATH=${HOME}/F18
export PATH=${HOME}/F18:\$PATH
./F18

EOM

fi

cat > F18.desktop <<- EOM
[Desktop Entry]
Name=F18 klijent
Comment=F18 - knjigovodstvo za bosance
Icon=application.png
Exec=/home/hernad/F18/F18.sh
Icon=${HOME}/F18/F18.png
Type=Application
Categories=GTK;GNOME;Utility;
Terminal=false
EOM


cat > f18_editor <<- EOM
#!/bin/bash


cat \$1 | sed 's/#%.*#//g' | iconv -c -f IBM852 -t UTF-8 > \$1.conv.txt

export BANG=\!  
gvim -u ${HOME}/F18/.vimrc -c "nmap <C-P> :exe '\$BANG ptxt ' . substitute(@%, '.conv.txt', '', 'y') . ' /p'<CR>" \$1.conv.txt
EOM


cat > ${HOME}/F18/.vimrc <<- EOM
set nocompatible

set diffexpr=MyDiff()

" Use pathogen to easily modify the runtime path to include all plugins under
" the ~/.vim/bundle directory
filetype off                    " force reloading *after* pathogen loaded


set hidden
set nowrap        " don't wrap lines
set tabstop=4     " a tab is four spaces
set backspace=indent,eol,start
                  " allow backspacing over everything in insert mode
set shiftwidth=4  " number of spaces to use for autoindenting
set shiftround    " use multiple of shiftwidth when indenting with '<' and '>'
set showmatch     " set show matching parenthesis
set ignorecase    " ignore case when searching
set smartcase     " ignore case if search pattern is all lowercase,

set history=1000         " remember more commands and search history
set undolevels=1000      " use many muchos levels of undo
set wildignore=*.swp,*.bak,*.pyc,*.class
set title                " change the terminal's title
set visualbell           " don't beep
set noerrorbells         " don't beep

set nobackup
set noswapfile

" Easy window navigation
map <C-h> <C-w>h
map <C-j> <C-w>j
map <C-k> <C-w>k
map <C-l> <C-w>l

set fileencoding=utf-8
set encoding=utf-8

"izadlji sa esc
nmap <ESC> :q!<CR>
set columns=9999 lines=9999
set guioptions+=b
set guioptions-=R
set guioptions-=m  "remove menu bar
set guioptions-=T  "remove toolbar
EOM

chmod +x F18.sh
chmod +x F18.desktop
chmod +x f18_editor
xdg-open .

cd $HOME