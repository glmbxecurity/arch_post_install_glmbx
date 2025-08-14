#!/bin/bash
# Script para instalar tema Orchis y los iconos Tela en Arch (o cualquier distro)

set -e  # parar en caso de error

cd "$HOME"

# --- Instalar Orchis Theme ---
if [ -d "$HOME/Orchis-theme" ]; then
  rm -rf "$HOME/Orchis-theme"
fi
git clone https://github.com/vinceliuice/Orchis-theme.git
cd Orchis-theme
./install.sh -t all
cd ..

# --- Instalar Tela Icon Theme ---
if [ -d "$HOME/Tela-icon-theme" ]; then
  rm -rf "$HOME/Tela-icon-theme"
fi
git clone https://github.com/vinceliuice/Tela-icon-theme.git
cd Tela-icon-theme
./install.sh -a
cd ..

# --- Limpiar directorios ---
rm -rf "$HOME/Orchis-theme" "$HOME/Tela-icon-theme"

echo "✅ Instalación completada: Orchis (tema) y Tela (iconos)"
#!/bin/bash

# Comprobar si rofi está instalado
if command -v rofi >/dev/null 2>&1; then
    echo "✅ Rofi detectado, instalando temas..."
    
    # Clonar la colección de temas en el home del usuario
    cd "$HOME" || exit
    if [ ! -d "rofi-themes-collection" ]; then
        git clone https://github.com/lr-tech/rofi-themes-collection.git
    else
        echo "ℹ️ La colección ya está clonada, se actualizará"
        cd rofi-themes-collection && git pull
    fi

    # Crear carpeta de temas si no existe
    mkdir -p ~/.local/share/rofi/themes/

    cp -r ~/rofi-themes-collection/themes/* ~/.local/share/rofi/themes/

    echo "✅ Temas copiados a ~/.local/share/rofi/themes/"
    echo "Para cambiar de tema, ejecuta: rofi-theme-selector"
else
    echo "ℹ️ Rofi no está instalado, se omite la instalación de temas"
fi
