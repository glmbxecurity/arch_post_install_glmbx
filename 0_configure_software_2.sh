#!/bin/bash
set -e

# --- Configuración Kitty ---
if command -v kitty &>/dev/null; then
    CONFIG_DIR="$HOME/.config/kitty"
    CONFIG_FILE="$CONFIG_DIR/kitty.conf"
    mkdir -p "$CONFIG_DIR"

    cat > "$CONFIG_FILE" << 'EOF'
# -------------------------
# Configuración de Kitty
# -------------------------
background_opacity 0.85
background #1e1e2e
font_family FiraCode Nerd Font
font_size 12.0
cursor_shape block
cursor_blinking yes
scrollback_lines 10000
enable_audio_bell no
hide_mouse_when_typing yes
EOF

    echo "✅ Configuración de Kitty creada en $CONFIG_FILE"
else
    echo "⚠️ Kitty no encontrado, saltando configuración..."
fi

# --- Autostart Plank ---
AUTOSTART_DIR="$HOME/.config/autostart"
mkdir -p "$AUTOSTART_DIR"

if command -v plank >/dev/null 2>&1; then
    cat > "$AUTOSTART_DIR/plank.desktop" << 'EOF'
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
