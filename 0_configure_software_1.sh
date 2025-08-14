#!/bin/bash
set -e

# --- Configuración OpenRGB / i2c-dev ---
if command -v OpenRGB &>/dev/null; then
    echo "OpenRGB detectado. Configurando módulo i2c-dev..."

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

    if ! lsmod | grep -q "^i2c_dev"; then
        modprobe i2c-dev
        echo "Módulo i2c-dev cargado en el sistema actual."
    else
        echo "Módulo i2c-dev ya está cargado."
    fi
else
    echo "OpenRGB no está instalado, se omite configuración."
fi

# --- Configuración libvirt / virsh ---
TARGET_USER=${SUDO_USER:-$USER}

if command -v virsh >/dev/null 2>&1; then
    echo "Configurando libvirt para usuario: $TARGET_USER"

    usermod -aG libvirt "$TARGET_USER"
    usermod -aG kvm "$TARGET_USER"

    systemctl restart libvirtd

    if ! virsh net-info default >/dev/null 2>&1; then
        if [ -f /etc/libvirt/qemu/networks/default.xml ]; then
            virsh net-define /etc/libvirt/qemu/networks/default.xml
        else
            echo "ERROR: /etc/libvirt/qemu/networks/default.xml no encontrado"
        fi
    fi

    virsh net-start default >/dev/null 2>&1 || true
    virsh net-autostart default >/dev/null 2>&1
    echo "Red 'default' configurada y activa"
else
    echo "Libvirt/virsh no está instalado, se omite configuración."
fi
