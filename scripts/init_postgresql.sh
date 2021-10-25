#!/bin/bash

if [ "$1" != "" ]; then
   SUPERUSER=$1
else
   SUPERUSER=postgres
fi

PSQLCMD="sudo -u postgres psql -t -h localhost -U $SUPERUSER"

function create_postgres {
ret=`echo "select rolname from pg_roles where rolname='postgres'" | $PSQLCMD | grep -q $USER`

if [[ "$ret" == "0" ]]; then
   echo "postgres user postoji"
else
  echo "create user postgres WITH PASSWORD 'postgres' SUPERUSER" | $PSQLCMD
fi

}


function create_user {
ret=`echo "select rolname from pg_roles where rolname='$USER'" | $PSQLCMD | grep -q $USER`

if [[ "$ret" == "0" ]]; then
   echo "$USER postoji"
else
  echo "create user $USER with password '$USER'" | $PSQLCMD
fi

SQL="grant xtrole TO test1 GRANTED BY $SUPERUSER"
echo $SQL | $PSQLCMD

}


function create_test_roles {


SQL="create role admin"
echo $SQL | $PSQLCMD


SQL="create role xtrole"
echo $SQL | $PSQLCMD

USER="test1"
create_user

USER="test2"
create_user

SQL="grant xtrole TO admin GRANTED BY $SUPERUSER"
echo $SQL | $PSQLCMD
}

create_postgres
create_test_roles
