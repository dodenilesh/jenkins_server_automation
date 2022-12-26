#!/bin/bash

set -x

# For Node
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -

sudo apt-get update -y

sleep 10

# Setting up Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -a -G docker ubuntu

#Python installation
sudo apt install software-properties-common
sudo add-apt-repository ppa:deadsnakes/ppa

sudo apt install -y python3.9 python3-pip jq unzip vim tree netcat-traditional xmlstarlet git make nodejs openjdk-17-jre-headless docker-compose


sudo npm install -g create-react-app

# AWS CLI installation
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install


sudo apt-get clean
exit 0
