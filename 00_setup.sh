#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Lista de scripts y si requieren root o no
declare -A SCRIPTS
SCRIPTS["0_install_software.sh"]="root"
SCRIPTS["0_configure_software_1.sh"]="root"
SCRIPTS["0_configure_software_2.sh"]="user"
SCRIPTS["1_nvme_mount.sh"]="root"
SCRIPTS["2_conf_wireguard.sh"]="root"
SCRIPTS["3_asusctl_service.sh"]="root"
SCRIPTS["4_install_themes_icons.sh"]="user"
SCRIPTS["5_x11vnc_server.sh"]="user"
SCRIPTS["6_restore_config_dir.sh"]="root"
SCRIPTS["7_extra_backup_config_dir.sh"]="user"

# Orden exacto de ejecución
ORDERED_SCRIPTS=(
    "0_install_software.sh"
    "0_configure_software_1.sh"
    "0_configure_software_2.sh"
    "1_nvme_mount.sh"
    "2_conf_wireguard.sh"
    "3_asusctl_service.sh"
    "4_install_themes_icons.sh"
    "5_x11vnc_server.sh"
    "6_restore_config_dir.sh"
    "7_extra_backup_config_dir.sh"
)

# Construir lista para whiptail: nombre_script OFF
OPTIONS=()
OPTIONS+=("TODOS" "Ejecutar todos los scripts listados" "OFF")
for script in "${ORDERED_SCRIPTS[@]}"; do
    OPTIONS+=("$script" "Tipo: ${SCRIPTS[$script]}" "OFF")
done

# Mostrar menú con checkboxes
SELECTED=$(whiptail --title "Arch Linux post install AIO script" \
    --checklist "Usa espacio para marcar y Enter para aceptar" 20 70 10 \
    "${OPTIONS[@]}" 3>&1 1>&2 2>&3)

EXITSTATUS=$?
if [[ $EXITSTATUS -ne 0 ]]; then
    echo "Cancelado."
    exit 0
fi

# whiptail devuelve los elementos entre comillas
SELECTED=($(echo $SELECTED | tr -d '"' ))

# Funciones para ejecutar scripts
run_as_root() {
    local script="$1"
    if [[ $EUID -ne 0 ]]; then
        echo "Ejecutando $script como root..."
        sudo bash "$SCRIPT_DIR/$script"
    else
        echo "Ejecutando $script como root..."
        bash "$SCRIPT_DIR/$script"
    fi
}

run_as_user() {
    local script="$1"
    local user="${SUDO_USER:-$USER}"
    if [[ $EUID -eq 0 && "$user" != "root" ]]; then
        echo "Ejecutando $script como usuario $user..."
        sudo -u "$user" bash "$SCRIPT_DIR/$script"
    else
        echo "Ejecutando $script como usuario actual..."
        bash "$SCRIPT_DIR/$script"
    fi
}

# Ejecutar scripts seleccionados
if [[ " ${SELECTED[@]} " =~ "TODOS" ]]; then
    echo "=== Ejecutando TODOS los scripts ==="
    for script in "${ORDERED_SCRIPTS[@]}"; do
        [[ "${SCRIPTS[$script]}" == "root" ]] && run_as_root "$script"
        [[ "${SCRIPTS[$script]}" == "user" ]] && run_as_user "$script"
    done
else
    for script in "${ORDERED_SCRIPTS[@]}"; do
        if [[ " ${SELECTED[@]} " =~ " $script " ]]; then
            [[ "${SCRIPTS[$script]}" == "root" ]] && run_as_root "$script"
            [[ "${SCRIPTS[$script]}" == "user" ]] && run_as_user "$script"
        fi
    done
fi

echo "✅ Scripts seleccionados ejecutados."
