#!/bin/bash

if [ -z "$PG_PASSWORD" ] ; then
   echo "set envar PG_PASSWORD"
   exit 1
fi


if [ -f /etc/redhat-release ] ; then
   echo "setenforce 0!"
   sudo setenforce 0
fi

#if [ ! -d postgresql_data ] ; then
#    tar xvf postgresql_data.tgz
#fi


PG_DOCKER_NAME="F18_test_db"

docker rm -f $PG_DOCKER_NAME

docker run \
  --name $PG_DOCKER_NAME -itd --restart always \
  --env 'PG_PASSWORD=$PG_PASSWORD' \
  -v $PWD/data:/data \
  -v $PWD/scripts:/scripts \
  -v $PWD/postgresql_data:/var/lib/postgresql \
  -p 5432:5432 \
  sameersbn/postgresql:10

echo cekamo 5 sec
sleep 5

cat sql/F18_test_db.sql  |   docker exec --interactive $PG_DOCKER_NAME  psql  -U postgres -d postgres  -


docker logs $PG_DOCKER_NAME

echo "lokacija skripti /scripts/"
docker exec -ti $PG_DOCKER_NAME bash


