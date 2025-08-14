#!/bin/bash
set -e

CONF_FILE="./programs.conf"

if [[ $EUID -ne 0 ]]; then
  echo "Por favor ejecuta este script como root (sudo $0)"
  exit 1
fi

if [[ ! -f "$CONF_FILE" ]]; then
  echo "No se encontró archivo de configuración: $CONF_FILE"
  exit 1
fi

# --- Instalar dialog si no existe ---
if ! command -v dialog &>/dev/null; then
  pacman -Sy --noconfirm dialog
fi

# --- Leer programas y construir lista para dialog ---
PROG_LIST=("ALL" "Seleccionar todos los programas" "off")
while IFS= read -r line; do
  [[ "$line" =~ ^#.*$ || -z "$line" ]] && continue
  name=$(echo "$line" | cut -d= -f1)
  PROG_LIST+=("$name" "" "off")
done < "$CONF_FILE"

# --- Menú de selección ---
CHOICES=$(dialog --stdout --checklist "Selecciona los programas a instalar" 0 0 0 "${PROG_LIST[@]}")

# Si cancelado
if [[ -z "$CHOICES" ]]; then
  echo "Instalación cancelada."
  exit 0
fi

# --- Si se seleccionó ALL, usar todos los programas ---
if echo "$CHOICES" | grep -q "ALL"; then
  CHOICES=$(grep -vE '^#|^$' "$CONF_FILE" | cut -d= -f1)
fi

# Separar en oficiales y AUR
PKGS_OFFICIAL=()
PKGS_AUR=()
for prog in $CHOICES; do
  prog=$(echo $prog | tr -d '"')
  type=$(grep "^$prog=" "$CONF_FILE" | cut -d= -f2)
  if [[ "$type" == "official" ]]; then
    PKGS_OFFICIAL+=("$prog")
  else
    PKGS_AUR+=("$prog")
  fi
done

# --- Función para instalar yay ---
install_yay() {
  if ! command -v yay &>/dev/null; then
    echo "Instalando yay (AUR helper)..."
    pacman -Sy --needed --noconfirm git base-devel
    sudo -u "$SUDO_USER" bash -c 'git clone https://aur.archlinux.org/yay.git /tmp/yay && cd /tmp/yay && makepkg -si --noconfirm'
  fi
}

clear
echo "******* Instalando programas seleccionados *******"

# Actualizar sistema
pacman -Syu --noconfirm

# Instalar oficiales
if [[ ${#PKGS_OFFICIAL[@]} -gt 0 ]]; then
  echo "Instalando paquetes oficiales: ${PKGS_OFFICIAL[*]}"
  pacman -S --needed --noconfirm "${PKGS_OFFICIAL[@]}"
fi

# Instalar AUR
if [[ ${#PKGS_AUR[@]} -gt 0 ]]; then
  install_yay
  echo "Instalando paquetes AUR: ${PKGS_AUR[*]}"
  sudo -u "$SUDO_USER" yay -S --needed --noconfirm "${PKGS_AUR[@]}"
fi

# Activar servicios conocidos
for svc in libvirtd tailscaled asusd; do
  if systemctl list-unit-files | grep -q "$svc"; then
    systemctl enable --now "$svc"
  fi
done

echo "******* Instalación completada *******"

