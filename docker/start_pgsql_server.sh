#!/bin/bash

#DOCKER_IMAGE=sameersbn/postgresql:10
#DOCKER_IMAGE=psql_tds_fdw
DOCKER_IMAGE=f18_postgresql:10-1

if [ -d $HOME/F18_docker/postgresql_data ] ; then
   POSTGRESQL_DATA=$HOME/F18_docker/postgresql_data
else
   POSTGRESQL_DATA=$PWD/postgresql_data
fi


if [ -z "$PG_PASSWORD" ] ; then
   echo "set envar PG_PASSWORD"
   exit 1
fi


if [ -f /etc/redhat-release ] ; then
   echo "setenforce 0!"
   sudo setenforce 0
fi

if [ ! -d $POSTGRESQL_DATA ] ; then
    tar xvf postgresql_data.tgz
else
    echo "$POSTGRESQL_DATA postoji"
fi


PG_DOCKER_NAME="F18_test_db"

docker rm -f $PG_DOCKER_NAME

docker run \
  --name $PG_DOCKER_NAME -itd --restart always \
  --env 'PG_PASSWORD=$PG_PASSWORD' \
  -v $PWD/data:/data \
  -v $PWD/scripts:/scripts \
  -v $POSTGRESQL_DATA:/var/lib/postgresql \
  -p 5432:5432 \
  $DOCKER_IMAGE \
  -c logging_collector=on

docker logs $PG_DOCKER_NAME

echo "lokacija skripti /scripts/"
docker exec -ti $PG_DOCKER_NAME bash


