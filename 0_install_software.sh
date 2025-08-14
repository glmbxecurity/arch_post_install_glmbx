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

    # Verificar que SUDO_USER esté definido correctamente
    if [ -z "$SUDO_USER" ]; then
      echo "No se pudo determinar el usuario. Usando el usuario actual."
      SUDO_USER=$(whoami)
    fi

    # Usar un directorio persistente para clonar yay
    YAY_DIR="/opt/yay"

    # Crear el directorio como root y darle permisos al usuario
    sudo mkdir -p "$YAY_DIR"
    sudo chown -R "$SUDO_USER":"$SUDO_USER" "$YAY_DIR"

    # Clonar y compilar yay
    sudo -u "$SUDO_USER" bash -c "git clone https://aur.archlinux.org/yay.git $YAY_DIR && cd $YAY_DIR && makepkg -si --noconfirm"
  fi
}

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
#!/bin/bash
set -e

# Comprobar si openrgb está instalado
if ! command -v OpenRGB &>/dev/null; then
  echo "OpenRGB no está instalado. Saliendo..."
  exit 0
fi

echo "OpenRGB detectado. Configurando módulo i2c-dev..."

# Crear archivo para cargar el módulo al inicio
MODULE_CONF="/etc/modules-load.d/openrgb.conf"
if [[ ! -f "$MODULE_CONF" ]]; then
    echo "i2c-dev" > "$MODULE_CONF"
    echo "Se creó $MODULE_CONF para cargar i2c-dev al inicio."
else
    if ! grep -q "^i2c-dev$" "$MODULE_CONF"; then
        echo "i2c-dev" >> "$MODULE_CONF"
        echo "Se añadió i2c-dev a $MODULE_CONF."
    fi
fi

# Cargar el módulo inmediatamente
if ! lsmod | grep -q "^i2c_dev"; then
    modprobe i2c-dev
    echo "Módulo i2c-dev cargado en el sistema actual."
else
    echo "Módulo i2c-dev ya está cargado."
fi
#!/bin/bash
# Script para configurar Kitty con transparencia ligera solo si está instalado

# Comprobar si kitty está disponible; si no, simplemente saltar
if ! command -v kitty &> /dev/null; then
    echo "⚠️ Kitty no encontrado, saltando configuración..."
else
    CONFIG_DIR="$HOME/.config/kitty"
    CONFIG_FILE="$CONFIG_DIR/kitty.conf"

    # Crear el directorio de configuración si no existe
    mkdir -p "$CONFIG_DIR"

    # Escribir configuración
    cat > "$CONFIG_FILE" << 'EOF'
# -------------------------
# Configuración de Kitty
# -------------------------

# Transparencia (0.0 = transparente, 1.0 = opaco)
background_opacity 0.85

# Color de fondo
background #1e1e2e

# Fuente y tamaño
font_family FiraCode Nerd Font
font_size 12.0

# Cursor
cursor_shape block
cursor_blinking yes

# Scrollback
scrollback_lines 10000

# Otras opciones visuales
enable_audio_bell no
hide_mouse_when_typing yes
EOF

    echo "✅ Configuración de Kitty creada en $CONFIG_FILE"
fi

echo "✅ Recuerda lanzar OpenRGB como root"
#!/bin/bash

# Carpeta de autostart
AUTOSTART_DIR=~/.config/autostart
mkdir -p "$AUTOSTART_DIR"

# Comprobar si plank está instalado
if command -v plank >/dev/null 2>&1; then
    cat > "$AUTOSTART_DIR/plank.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Exec=plank
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=Plank
Comment=Docker para el panel
EOF
    echo "✅ Plank detectado y agregado al inicio"
else
    echo "ℹ️ Plank no está instalado, se omite agregarlo al inicio"
fi
#!/bin/bash

TARGET_USER=${1:-$SUDO_USER}  # usa el primer argumento, si no, el usuario que ejecutó sudo

if [ -z "$TARGET_USER" ]; then
    echo "No se pudo determinar el usuario. Usa: $0 <usuario>"
    exit 1
fi

if command -v virsh >/dev/null 2>&1; then
    echo "Libvirt detectado. Configurando permisos para el usuario $TARGET_USER..."

    sudo usermod -aG libvirt "$TARGET_USER"
    sudo usermod -aG kvm "$TARGET_USER"

    echo "Se añadieron los grupos. Cierra sesión y vuelve a entrar para que los cambios tengan efecto."
else
    echo "Libvirt no está instalado. No se realizaron cambios."
fi
#!/bin/bash

# Comprobar si libvirt/virsh están instalados
if ! command -v virsh >/dev/null 2>&1; then
    echo "Libvirt/virsh no está instalado. No se realizará ninguna configuración."
    exit 0
fi

# Usuario objetivo (si se ejecuta con sudo)
TARGET_USER=${SUDO_USER:-$USER}

echo "Configurando virt-manager/QEMU para usuario: $TARGET_USER"

# Añadir usuario a grupos libvirt y kvm
echo "Añadiendo $TARGET_USER a grupos libvirt y kvm..."
sudo usermod -aG libvirt "$TARGET_USER"
sudo usermod -aG kvm "$TARGET_USER"

# Reiniciar libvirt para aplicar cambios de permisos
echo "Reiniciando servicio libvirtd..."
sudo systemctl restart libvirtd

# Comprobar si la red 'default' existe
if ! virsh net-info default >/dev/null 2>&1; then
    echo "La red 'default' no existe. Creando desde archivo XML predeterminado..."
    if [ -f /etc/libvirt/qemu/networks/default.xml ]; then
        sudo virsh net-define /etc/libvirt/qemu/networks/default.xml
    else
        echo "ERROR: No existe /etc/libvirt/qemu/networks/default.xml. Instala libvirt-defaults."
        exit 1
    fi
fi

# Activar y hacer persistente la red 'default'
sudo virsh net-start default >/dev/null 2>&1 || true
sudo virsh net-autostart default >/dev/null 2>&1

# Mostrar estado final
echo "Red 'default' configurada y activa:"
virsh net-list --all

echo "Configuración completa. Cierra sesión y vuelve a entrar para que los cambios de grupo tengan efecto."
echo "Tus VMs deberían obtener IPs automáticamente vía NAT."

echo "******* Instalación completada *******"
