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

