#!/usr/bin/env bash
#
# Author: Nicholas Hooper
# Description:
# Initializes Wazuh Server Central Components via Docker 
# Usage:
# ./<Script_Name>


if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root" >&2
    exit 1
fi


if ! command -v docker &> /dev/null
then
    echo "docker could not be found, please install docker."
    exit 1
fi

if ! command -v git &> /dev/null
then
    echo "git could not be found, please install git."
    exit 1
fi


sysctl -w vm.max_map_count=262144

if [ ! -d "wazuh-docker" ]; then

    git clone https://github.com/wazuh/wazuh-docker.git -b v4.10.1
else
    echo "directory 'wazuh-docker' already exists - skipping clone."

    cd wazuh-docker && git pull origin v4.10.1
    cd ..
fi

cd ./wazuh-docker/single-node || { echo "Failed to enter wazuh-docker directory"; exit 1; }

docker-compose -f generate-indexer-certs.yml run --rm generator

docker-compose up -d
