#!/usr/bin/env bash
#
# Notes:
# IN DEVELOPMENT  --- DO NOT USE 
#

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root" >&2
    exit 1
fi

echo "Enter indexer ip: "
read WAZUH_INDEXER_IP
echo "Enter server ip: "
read WAZUH_SERVER_IP
echo "Enter dashboard ip: "
read WAZUH_DASHBOARD_IP

# download the Wazuh installation assistant and the configuration files

curl -sO https://packages.wazuh.com/4.9/wazuh-install.sh
curl -sO https://packages.wazuh.com/4.9/config.yml

INDEXER_CONF = "config.yml"

# edit ./config.yml and replace node names and IP values with the corresponding names and IP addresses. Do this for all server, indexer, and dashboard nodes. 

sed -i "s/<indexer-node-ip>/$WAZUH_INDEXER_IP/" "$INDEXER_CONF"
sed -i "s/<manager-node-ip>/$WAZUH_MANAGER_IP/" "$INDEXER_CONF"
sed -i "s/<dashboard-node-ip>/$WAZUH_DASHBOARD_IP/" "$INDEXER_CONF"

bash wazuh-install.sh --generate-config-files

bash wazuh-install.sh --wazuh-indexer node-1

bash wazuh-install.sh --start-cluster

ADMIN_PASSWORD = $(tar -axf wazuh-install-files.tar wazuh-install-files/wazuh-passwords.txt -O | grep -P "\'admin\'" -A 1)

curl -k -u admin:$ADMIN_PASSWORD https://$WAZUH_INDEXER_IP:9200

bash wazuh-install.sh --wazuh-server wazuh-1

bash wazuh-install.sh --wazuh-dashboard dashboard

tar -O -xvf wazuh-install-files.tar wazuh-install-files/wazuh-passwords.txt

curl -so wazuh-passwords-tool.sh https://packages.wazuh.com/4.9/wazuh-passwords-tool.sh

bash wazuh-passwords-tool.sh -a


