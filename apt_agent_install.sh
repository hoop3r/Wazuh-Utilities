#!/usr/bin/env bash
#
# Author: Nicholas Hooper
# Description:
# Install & Configure Wazuh Agent ( apt )
# Usage:
# ./<Script_Name>

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root" >&2
    exit 1
fi

WAZUH_GPG_KEY="https://packages.wazuh.com/key/GPG-KEY-WAZUH"
KEYRING_PATH="/usr/share/keyrings/wazuh.gpg"
WAZUH_REPO_FILE="/etc/apt/sources.list.d/wazuh.list"
AGENT_CONF="/var/ossec/etc/ossec.conf"

read -p "Enter manager IP: " WAZUH_MANAGER

echo "Creating backup . . ."

cp "$AGENT_CONF" "${AGENT_CONF}.bak"

echo "Importing Wazuh GPG key..."
if ! curl -s "$WAZUH_GPG_KEY" | gpg --no-default-keyring --keyring gnupg-ring:"$KEYRING_PATH" --import; then
    echo "Failed to import Wazuh GPG key." >&2
    exit 1
fi
chmod 644 "$KEYRING_PATH"

echo "Adding Wazuh repository to $WAZUH_REPO_FILE..."
echo "deb [signed-by=$KEYRING_PATH] https://packages.wazuh.com/4.x/apt/ stable main" >"$WAZUH_REPO_FILE"

echo "Updating package lists..."
apt update

echo "Installing Wazuh agent..."
if ! apt install -y wazuh-agent; then
    echo "Failed to install Wazuh agent." >&2
    exit 1
fi

echo "Configuring and starting Wazuh agent..."
systemctl daemon-reload
systemctl enable wazuh-agent || {
    echo "Failed to enable wazuh-agent service."
    exit 1
}
systemctl start wazuh-agent || {
    echo "Failed to start wazuh-agent service."
    exit 1
}

if [[ -f $AGENT_CONF ]]; then
    echo "Updating config in $AGENT_CONF..."
    sed -i "s#<address>.*</address>#<address>$WAZUH_MANAGER</address>#g" "$AGENT_CONF"
    # 
    systemctl restart wazuh-agent || {
        echo "Failed to restart wazuh-agent after configuration."
        exit 1
    }
else
    echo "Configuration file $AGENT_CONF not found. Please update the Wazuh manager IP manually." >&2
fi

echo "Disabling Wazuh repository..."
sed -i "s/^deb/#deb/" "$WAZUH_REPO_FILE"

echo "Refreshing package lists after disabling the Wazuh repository..."
if ! apt update; then
    echo "Failed to update package lists after disabling the repository." >&2
    exit 1
fi

echo "Wazuh agent installation complete."



