#!/bin/bash
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
  echo "Por favor ejecuta este script como root (sudo $0)"
  exit 1
fi

echo "=== Configuración ASUSCTL ==="

# Actualizar sistema (opcional: puedes comentar si no quieres actualizar siempre)
echo "Actualizando paquetes..."
pacman -Syu --noconfirm

# Instalar asusctl y dependencias solo si no están presentes
for pkg in asusctl supergfxctl; do
    if ! pacman -Qi "$pkg" &>/dev/null; then
        echo "Instalando $pkg..."
        pacman -S --noconfirm "$pkg"
    else
        echo "$pkg ya está instalado, saltando..."
    fi
done

# Habilitar servicio principal asusd
echo "Habilitando asusd.service..."
systemctl enable --now asusd.service

# Crear servicio systemd para aplicar perfil performance solo si no existe
SERVICE_FILE="/etc/systemd/system/asusctl-profile.service"
if [[ ! -f "$SERVICE_FILE" ]]; then
    echo "Creando servicio systemd para establecer perfil performance..."
    cat <<EOF > "$SERVICE_FILE"
[Unit]
Description=Set ASUSCTL profile to Performance at boot
After=asusd.service
Requires=asusd.service

[Service]
Type=oneshot
ExecStart=/usr/bin/asusctl profile -P performance
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

    # Recargar systemd y habilitar servicio
    systemctl daemon-reload
    systemctl enable --now asusctl-profile.service
    echo "Servicio asusctl-profile.service creado y habilitado."
else
    echo "Servicio asusctl-profile.service ya existe, saltando creación."
fi

echo "✅ Configuración completada. asusctl se iniciará con el sistema y usará el perfil Performance."

