#!/usr/bin/env bash
#
# Under development
#

sysctl -w vm.max_map_count=262144

git clone https://github.com/wazuh/wazuh-docker.git -b v4.10.1

docker compose -f generate-indexer-certs.yml run --rm generator

docker compose up -d 

# change passwords 

docker compose down 

echo "Please enter the new password:"
read -s NEW_PASSWORD

# generate hash 

echo "Generating password hash..."
HASH=$(docker run --rm -ti wazuh/wazuh-indexer:4.10.1 bash /usr/share/wazuh-indexer/plugins/opensearch-security/tools/hash.sh <<< "$NEW_PASSWORD")

# check if has gen was successful

if [ -z "$HASH" ]; then
    echo "Failed to generate password hash"
    exit 1
fi

echo "Password hash generated: $HASH"

# update internal users file 

INTERNAL_USERS_FILE="config/wazuh_indexer/internal_users.yml"

# check if the file exists

if [ ! -f "$INTERNAL_USERS_FILE" ]; then
    echo "File $INTERNAL_USERS_FILE not found!"
    exit 1
fi

# update the hash for the admin user

echo "Updating password for the admin user..."
sed -i "s|^  hash:.*admin.*|  hash: \"$HASH\"|" "$INTERNAL_USERS_FILE"

# update hash for other users 

echo "Updating password for the kibanaserver user..."
sed -i "s|^  hash:.*kibanaserver.*|  hash: \"$HASH\"|" "$INTERNAL_USERS_FILE"

echo "Password hash updated in $INTERNAL_USERS_FILE"

# update docker compose file 

DOCKER_COMPOSE_FILE="docker-compose.yml"

# check if the file exists

if [ ! -f "$DOCKER_COMPOSE_FILE" ]; then
    echo "File $DOCKER_COMPOSE_FILE not found!"
    exit 1
fi

# update the password for all occurrences of INDEXER_PASSWORD in docker-compose.yml

echo "Updating INDEXER_PASSWORD in docker-compose.yml..."
sed -i "s|INDEXER_PASSWORD=.*|INDEXER_PASSWORD=$NEW_PASSWORD|" "$DOCKER_COMPOSE_FILE"

# update the password for all occurrences of DASHBOARD_PASSWORD in docker-compose.yml

echo "Updating DASHBOARD_PASSWORD in docker-compose.yml..."
sed -i "s|DASHBOARD_PASSWORD=.*|DASHBOARD_PASSWORD=$NEW_PASSWORD|" "$DOCKER_COMPOSE_FILE"

echo "Password updated in $DOCKER_COMPOSE_FILE"

docker-compose up -d

# apply changes 

docker exec -it single-node-wazuh.indexer-1 bash

export INSTALLATION_DIR=/usr/share/wazuh-indexer
CACERT=$INSTALLATION_DIR/certs/root-ca.pem
KEY=$INSTALLATION_DIR/certs/admin-key.pem
CERT=$INSTALLATION_DIR/certs/admin.pem
export JAVA_HOME=/usr/share/wazuh-indexer/jdk

bash /usr/share/wazuh-indexer/plugins/opensearch-security/tools/securityadmin.sh -cd /usr/share/wazuh-indexer/opensearch-security/ -nhnv -cacert  $CACERT -cert $CERT -key $KEY -p 9200 -icl

# update the wazuh-wui password in config/wazuh_dashboard/wazuh.yml

WAZUH_YML_FILE="config/wazuh_dashboard/wazuh.yml"

# check if the file exists

if [ ! -f "$WAZUH_YML_FILE" ]; then
    echo "File $WAZUH_YML_FILE not found!"
    exit 1
fi

# update the password for the wazuh-wui user in wazuh.yml

echo "Updating wazuh-wui password in $WAZUH_YML_FILE..."
sed -i "s|password: \".*\"|password: \"$NEW_PASSWORD\"|" "$WAZUH_YML_FILE"

echo "Wazuh API user password updated in $WAZUH_YML_FILE"

docker-compose down

docker-compose up -d