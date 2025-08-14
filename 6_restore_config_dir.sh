#!/bin/bash
# restore_config_dir.sh
# Restaurar backup de .config desde el directorio actual
# Diseñado para ejecutarse como root

set -e

if [[ $EUID -ne 0 ]]; then
    echo "Por favor ejecuta este script como root (sudo $0)"
    exit 1
fi

# Detectar backups disponibles
BACKUPS=(config_backup_*.tar.gz)
if [ ${#BACKUPS[@]} -eq 0 ]; then
    echo "No se encontraron backups en el directorio actual."
    exit 1
fi

# Listar backups
echo "Backups disponibles:"
for i in "${!BACKUPS[@]}"; do
    echo "$((i+1))) ${BACKUPS[$i]}"
done

# Seleccionar backup
read -rp "Seleccione el número del backup a restaurar: " BACKUP_NUM
if ! [[ "$BACKUP_NUM" =~ ^[0-9]+$ ]] || [ "$BACKUP_NUM" -lt 1 ] || [ "$BACKUP_NUM" -gt "${#BACKUPS[@]}" ]; then
    echo "Selección inválida."
    exit 1
fi
SELECTED_BACKUP="${BACKUPS[$((BACKUP_NUM-1))]}"

# Detectar usuarios según carpetas en /home
USERS=()
for d in /home/*/ ; do
    [ -d "$d" ] || continue
    USERS+=("$(basename "$d")")
done

if [ ${#USERS[@]} -eq 0 ]; then
    echo "No se encontraron usuarios disponibles para restaurar."
    exit 1
fi

# Listar usuarios
echo "Usuarios disponibles:"
for i in "${!USERS[@]}"; do
    echo "$((i+1))) ${USERS[$i]}"
done

# Seleccionar usuario
read -rp "Seleccione el número del usuario al que restaurar: " USER_NUM
if ! [[ "$USER_NUM" =~ ^[0-9]+$ ]] || [ "$USER_NUM" -lt 1 ] || [ "$USER_NUM" -gt "${#USERS[@]}" ]; then
    echo "Selección inválida."
    exit 1
fi
TARGET_USER="${USERS[$((USER_NUM-1))]}"
USER_HOME="/home/$TARGET_USER"

# Crear carpeta .config si no existe
mkdir -p "$USER_HOME/.config"

# Restaurar backup
echo "Restaurando $SELECTED_BACKUP para el usuario $TARGET_USER..."
tar -xzf "$SELECTED_BACKUP" -C "$USER_HOME"

# Ajustar permisos
chown -R "$TARGET_USER:$TARGET_USER" "$USER_HOME/.config"

echo "✅ Restauración completada correctamente para $TARGET_USER."

