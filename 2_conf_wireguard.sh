CONF_FILE="./post_install.conf"
source "$CONF_FILE"
echo "Copiando configuracion wireguard" 
sudo cp $WG_SOURCE_FILE $WG_DEST_FILE
echo OK
