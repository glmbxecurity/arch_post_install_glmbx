#!/bin/bash
# backup_config.sh
# Hace un backup del directorio ~/.config en el directorio actual

# Carpeta a respaldar
SRC_DIR="$HOME/.config"

# Nombre del backup con fecha
BACKUP_FILE="config_backup_$(date +%Y%m%d_%H%M%S).tar.gz"

# Crear el backup
tar -czf "$PWD/$BACKUP_FILE" -C "$HOME" ".config"

echo "Backup creado: $PWD/$BACKUP_FILE"

