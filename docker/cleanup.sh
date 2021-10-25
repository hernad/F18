#!/bin/bash


sudo setenforce 0
docker stop F18_test_db
sudo rm -rf postgresql_data

