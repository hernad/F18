#!/bin/bash

sudo dnf -y install freetds-devel

#curl -LO https://github.com/tds-fdw/tds_fdw/archive/v1.0.7.tar.gz
#tar -xvzf v1.0.7.tar.gz
#cd tds_fdw-1.0.7

[ -d tds_fdw ] ||  git clone https://github.com/tds-fdw/tds_fdw.git
#cd tds_fdw
#make USE_PGXS=1
#sudo make USE_PGXS=1 install
#cd ..

docker build  -t psql_tds_fdw .

