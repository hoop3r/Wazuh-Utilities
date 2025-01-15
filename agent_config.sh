#!/usr/bin/env bash

# ! - - This is under development! More to come - - !  

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root" >&2
    exit 1
fi

AGENT_CONF="/var/ossec/etc/ossec.conf"

echo "Creating backup . . ."

cp "$AGENT_CONF" "${AGENT_CONF}.bak"

# - - - Command monitoring config - - - 





# - - - Log file monitoring config - - - 






# - - - Security Configuration Assessment (SCA) config - - - 






# - - - Vulnerability detection config - - - 






# - - - File Integrity Monitoring (FIM) config - - - 

echo "List directories to add to FIM registry (use whitespace delimiter): "

read -a fim_dir

echo "Updating $AGENT_CONF . . ."
for dir in $fim_dir
do
#sed -i "s|<directories>.*</directories>|<directories>$dir</directories>|" "$AGENT_CONF"
echo "Added $dir to FIM registry."

done 

# - - - etc - - - 


