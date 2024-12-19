#!/usr/bin/env bash

# UNDER DEVELOPMENT

# References:
#
#   https://documentation.wazuh.com/current/installation-guide/wazuh-indexer/installation-assistant.html
#   https://documentation.wazuh.com/current/installation-guide/wazuh-server/installation-assistant.html
#   https://documentation.wazuh.com/current/installation-guide/wazuh-dashboard/installation-assistant.html
#   https://documentation.wazuh.com/current/user-manual/user-administration/password-management.html


if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root" >&2
    exit 1
fi

WAZUH_INSTALL_URL="https://packages.wazuh.com/4.9"
INSTALL_SCRIPT="wazuh-install.sh"
CONFIG_FILE="config.yml"

read -p "Enter indexer IP: " WAZUH_INDEXER_IP
read -p "Enter server IP: " WAZUH_SERVER_IP
read -p "Enter dashboard IP: " WAZUH_DASHBOARD_IP

curl -sO "$WAZUH_INSTALL_URL/$INSTALL_SCRIPT" || { echo "Failed to download $INSTALL_SCRIPT"; exit 1; }
curl -sO "$WAZUH_INSTALL_URL/$CONFIG_FILE" || { echo "Failed to download $CONFIG_FILE"; exit 1; }

echo "Updating config file... "

sed -i "s/<indexer-node-ip>/$WAZUH_INDEXER_IP/" "$CONFIG_FILE"
sed -i "s/<manager-node-ip>/$WAZUH_SERVER_IP/" "$CONFIG_FILE"
sed -i "s/<dashboard-node-ip>/$WAZUH_DASHBOARD_IP/" "$CONFIG_FILE"

bash "$INSTALL_SCRIPT" --generate-config-files || { echo "Failed to generate configuration files"; exit 1; }

echo "Installing Wazuh indexer... "

bash "$INSTALL_SCRIPT" --wazuh-indexer node-1 || { echo "Failed to install Wazuh Indexer"; exit 1; }
bash "$INSTALL_SCRIPT" --start-cluster || { echo "Failed to start Wazuh cluster"; exit 1; }

ADMIN_PASSWORD = $(tar -axf wazuh-install-files.tar wazuh-install-files/wazuh-passwords.txt -O | grep -P "\'admin\'" -A 1)

curl -k -u "admin:$ADMIN_PASSWORD" "https://$WAZUH_INDEXER_IP:9200" || { echo "Failed to verify Elasticsearch"; exit 1; }

echo "Installing Wazuh server & dashboard... "

bash "$INSTALL_SCRIPT" --wazuh-server wazuh-1 || { echo "Failed to install Wazuh Server"; exit 1; }
bash "$INSTALL_SCRIPT" --wazuh-dashboard dashboard || { echo "Failed to install Wazuh Dashboard"; exit 1; }

echo "Updating credentials... "

tar -O -xvf wazuh-install-files.tar wazuh-install-files/wazuh-passwords.txt || { echo "Failed to display passwords"; exit 1; }

curl -so wazuh-passwords-tool.sh "$WAZUH_INSTALL_URL/wazuh-passwords-tool.sh" || { echo "Failed to download password tool"; exit 1; }
bash wazuh-passwords-tool.sh -a || { echo "Failed to execute password tool"; exit 1; }
