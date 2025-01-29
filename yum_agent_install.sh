#!/usr/bin/env bash
#
# Author: Nicholas Hooper
# Description:
# Install & Configure Wazuh Agent ( yum )
# Usage:
# ./<Script_Name>

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root." >&2
   exit 1
fi

WAZUH_GPG_KEY="https://packages.wazuh.com/key/GPG-KEY-WAZUH"
WAZUH_REPO_FILE="/etc/yum.repos.d/wazuh.repo"
AGENT_CONF="/var/ossec/etc/ossec.conf"

read -p "Enter manager IP: " WAZUH_MANAGER

echo "Importing Wazuh GPG key..."
rpm --import "$WAZUH_GPG_KEY" || { echo "Failed to import GPG key"; exit 1; }

echo "Creating Wazuh repository file at $WAZUH_REPO_FILE..."
cat > "$WAZUH_REPO_FILE" << EOF
[wazuh]
gpgcheck=1
gpgkey=$WAZUH_GPG_KEY
enabled=1
name=EL-\$releasever - Wazuh
baseurl=https://packages.wazuh.com/4.x/yum/
protect=1
EOF

echo "Installing Wazuh agent..."
if ! yum install -y wazuh-agent; then
    echo "Failed to install Wazuh agent. Exiting." >&2
    exit 1
fi

echo "Configuring and starting Wazuh agent..."
systemctl daemon-reload
systemctl enable wazuh-agent || { echo "Failed to enable wazuh-agent"; exit 1; }
systemctl start wazuh-agent || { echo "Failed to start wazuh-agent"; exit 1; }

echo "Disabling Wazuh repository..."
sed -i "s/^enabled=1/enabled=0/" "$WAZUH_REPO_FILE"

if [[ -f $AGENT_CONF ]]; then
    echo "Updating config in $AGENT_CONF..."
    sed -i "s#<address>.*</address>#<address>$WAZUH_MANAGER</address>#g" "$AGENT_CONF"
    # 
    systemctl restart wazuh-agent || { echo "Failed to restart wazuh-agent after configuration"; exit 1; }
else
    echo "Configuration file $AGENT_CONF not found. Please update the Wazuh manager IP manually."
fi

echo "Wazuh agent installation and configuration complete"