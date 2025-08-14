#!/bin/bash

set -e

CONF_FILE="./post_install.conf"

if [[ $EUID -ne 0 ]]; then
  echo "Por favor ejecuta este script como root (sudo $0)"
  exit 1
fi

if [[ ! -f "$CONF_FILE" ]]; then
  echo "No se encontró archivo de configuración: $CONF_FILE"
  exit 1
fi

# Cargar configuración
source "$CONF_FILE"

clear
echo "******* Montando disco adicional según configuración *******"

# Validar disco y partición
if [[ ! -b /dev/$DISCO ]]; then
  echo "El disco /dev/$DISCO no existe."
  exit 1
fi
if [[ ! -b /dev/$PART ]]; then
  echo "La partición /dev/$PART no existe."
  exit 1
fi

# Obtener UUID y tipo de FS
UUID=$(blkid -s UUID -o value /dev/$PART)
FSTYPE=$(blkid -s TYPE -o value /dev/$PART)

if [[ -z "$UUID" || -z "$FSTYPE" ]]; then
  echo "No se pudo obtener información de /dev/$PART"
  exit 1
fi

echo "UUID detectado: $UUID"
echo "Tipo de sistema de archivos: $FSTYPE"
echo "Punto de montaje: $MOUNTPOINT"
echo "Symlink: $LINK"
echo

# Crear punto de montaje
mkdir -p "$MOUNTPOINT"

# Detectar UID y GID si el symlink apunta a /home/<usuario>
if [[ "$LINK" =~ ^/home/([^/]+)/ ]]; then
  USUARIO="${BASH_REMATCH[1]}"
  if id "$USUARIO" &>/dev/null; then
    UID_USER=$(id -u "$USUARIO")
    GID_USER=$(id -g "$USUARIO")
  else
    echo "El usuario $USUARIO no existe, usando UID/GID 0"
    UID_USER=0
    GID_USER=0
  fi
else
  UID_USER=0
  GID_USER=0
fi

# Determinar opciones de montaje
case "$FSTYPE" in
  ext4|xfs|btrfs)
    OPTIONS="defaults,rw,user"
    ;;
  ntfs)
    echo "Instalando ntfs-3g si no está presente..."
    pacman -Sy --noconfirm ntfs-3g
    OPTIONS="defaults,rw,uid=${UID_USER},gid=${GID_USER},umask=0022"
    FSTYPE="ntfs-3g"
    ;;
  exfat)
    OPTIONS="defaults,rw,uid=${UID_USER},gid=${GID_USER},umask=0022"
    ;;
  *)
    OPTIONS="defaults,rw"
    ;;
esac

# Agregar a fstab si no existe
if ! grep -q "$UUID" /etc/fstab; then
  echo "Añadiendo a /etc/fstab con opciones: $OPTIONS"
  echo "UUID=$UUID  $MOUNTPOINT  $FSTYPE  $OPTIONS  0  2" >> /etc/fstab
else
  echo "Ya existe una entrada con ese UUID en /etc/fstab."
fi

# Montar
echo "Montando partición..."
umount -f "$MOUNTPOINT" 2>/dev/null || true
mount -a

# Crear symlink
if [[ -L "$LINK" || -e "$LINK" ]]; then
  echo "El enlace o archivo $LINK ya existe. No se sobrescribirá."
else
  ln -s "$MOUNTPOINT" "$LINK"
  echo "Se creó enlace simbólico $LINK → $MOUNTPOINT"

  # Ajustar propietario si es dentro de /home/<usuario>
  if [[ -n "$USUARIO" ]]; then
    chown -h "$USUARIO":"$USUARIO" "$LINK"
    echo "Propietario del enlace cambiado a $USUARIO"
  fi
fi

echo "¡Listo! /dev/$PART montado en $MOUNTPOINT y acceso directo en $LINK"

