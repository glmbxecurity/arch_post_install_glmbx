# Arch Linux Post-Install AIO

Este repositorio contiene un conjunto de scripts para configurar y personalizar Arch Linux después de una instalación limpia. Está diseñado para automatizar tareas de instalación de software, configuración del sistema y personalización del usuario, de manera semiautomática y controlada.  

  
El proyecto está orientado inicialmente a mi propio equipo. En mi caso, utilizo asusctl para gestionar mi ASUS, y dispongo de un disco NVMe adicional que monto y enlazo a mi directorio $HOME. Desde ese mismo NVMe copio el túnel de WireGuard a /etc/wireguard.
El software incluido está seleccionado según mis necesidades y preferencias personales, al igual que la configuración por defecto. No obstante, el proyecto es totalmente adaptable: puede descargarse y modificarse libremente. Para ello se han añadido dos archivos de configuración que permiten personalizar el software a instalar, mientras que el script 00_setup.sh ofrece la posibilidad de decidir qué scripts ejecutar.

---

## Contenido

- **Scripts de instalación y configuración**  
  Cada script realiza una tarea específica, que puede requerir permisos de root o de usuario.

- **00_setup.sh**  
  Menú principal que permite ejecutar todos los scripts o seleccionarlos individualmente. Detecta si cada script necesita ejecutarse como root o como usuario normal.

---

## Scripts y su función

| Script | Tipo | Descripción |
|--------|------|-------------|
| `0_install_software.sh` | root | Instala el software base y paquetes esenciales en el sistema. |
| `0_configure_root.sh` | root | Configura aspectos del usuario root, como perfiles y permisos. |
| `0_configure_user.sh` | user | Configura el entorno del usuario principal (aliases, dotfiles, etc). |
| `1_nvme_mount.sh` | root | Monta automáticamente particiones NVMe según configuración. |
| `2_conf_wireguard.sh` | root | Configura WireGuard VPN con claves y archivos de configuración. |
| `3_asusctl_service.sh` | root | Configura y habilita el servicio `asusctl` para control de hardware en laptops ASUS. |
| `4_install_thenes_icons.sh` | user | Instala el tema de escritorio Orchis y los iconos Tela sin necesidad de root. También instala temas de Rofi si está presente. |
| `5_x11vnc_server.sh` | user | Configura un servidor VNC basado en `x11vnc` para el usuario. |
| `6_restore_config_dir.sh` | root | Restaura backups de `~/.config` para cualquier usuario del sistema. |
| `7_extra_backup_config_dir.sh` | user | Crea backups adicionales de `~/.config` del usuario actual. |

---

## Requisitos

- Arch Linux (o derivadas)
- DE **Cinnamon**
- `bash`  
- `git`  
- `whiptail` para el menú interactivo
- Acceso a `sudo` para scripts que requieren root

---

## Uso

```bash
git clone https://github.com/glmbxecurity/arch_post_install_glmbx.git
cd arch_post_install_glmbx
sudo bash 00_setup.sh
```

## Programas peronalizados
Si queremos crear nuestra propia lista de programas, basta con poner el nombre del programa seguido de un = y el repositorio donde se encuentra. si está en aur poner aur y se instalará con yay. si está en los repos de arch, poner official y se instalará con pacman. El nombre del paquete en el fichero de configuración debe coincidir exactamente con el nombre real en los repositorios para que lo sepa encontrar.
