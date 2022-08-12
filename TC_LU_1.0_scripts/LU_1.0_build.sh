#!/bin/bash

echo "Enter the sudo password: "
read PW

echo "Enter Thundercomm Email:"
read TUMAIL
echo "Enter Thundercomm Password:"
read TUPASS

echo "(II) User Home Dir: $HOME"
export TOP_DIR = ${HOME}/Thundercomm
echo "(II) Set TOP Dir: $TOP_DIR"
export HOST_DIR = ${TOP_DIR}/SDK.turbox.rb5165-LU1.0-dev
echo "(II) Set Host Dir: $HOST_DIR"

echo "(!!) Stop and remove docker container that named ubuntu-18.04"
echo $PW | sudo docker stop $(sudo docker ps -aqf "name=ubuntu-18.04")
echo $PW | sudo docker rm $(sudo docker ps -aqf "name=ubuntu-18.04")
echo $PW | sudo docker load < ubuntu-18.04.tar

mkdir -P ${HOST_DIR}

echo "(II) Run container (The path /home/user/host/ in container is mapped to host=> ${HOST_DIR})"
echo $PW | sudo docker run -v ${HOST_DIR}:/home/user/host/ -d --name ubuntu-1804 –p 36000:22 ubuntu:18.04

export CONPASS = "******"
echo "Connect to container by SSH, user password is ******"
echo "${CONPASS}" | ssh -o StrictHostKeyChecking=no -p 36000 user@127.0.0.1

echo "machine partner.thundercomm.com login ${TUMAIL} password ${TUPASS}" >> ~/.netrc
echo $PW | sudo apt update


