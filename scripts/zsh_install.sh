#!/bin/bash

# Script de instalación de ZSH, Oh My Zsh y plugins para Ubuntu 24.04+
# Compatible con Ubuntu 22.04, 24.04 y versiones LTS más recientes
# Basado en la documentación oficial:
# - https://ohmyz.sh/
# - https://github.com/zsh-users/zsh-autosuggestions
# - https://github.com/zsh-users/zsh-syntax-highlighting
# - https://github.com/carloscuesta/materialshell

# Salir inmediatamente si un comando falla
set -e

# Función para mostrar separadores y mensajes de sección
show_section() {
    echo -e "\n==================================================================="
    echo "🔷 $1"
    echo "==================================================================="
}

# Función para mostrar mensajes de proceso
show_process() {
    echo -e "\n▶️ $1"
}

# Función para verificar si un comando existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Inicio del script
show_section "INICIANDO INSTALACIÓN DE ZSH Y OH MY ZSH"
echo "Este script instalará ZSH, Oh My Zsh y plugins en su sistema."
echo "Se realizarán los siguientes pasos:"
echo "  1. Verificación e instalación de ZSH"
echo "  2. Configuración de ZSH como shell predeterminado"
echo "  3. Instalación de Oh My Zsh"
echo "  4. Instalación de plugins (autosuggestions y syntax-highlighting)"
echo "  5. Instalación del tema materialshell"
echo "  6. Configuración del archivo .zshrc"
echo "  7. Cambio automático a ZSH al finalizar"

# Verificar si ZSH ya está instalado
show_section "VERIFICANDO INSTALACIÓN DE ZSH"
if command_exists zsh; then
    show_process "ZSH ya está instalado en el sistema. Verificando versión..."
    zsh --version
    read -p "¿Desea continuar con la reinstalación? (s/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Ss]$ ]]; then
        echo "Omitiendo la instalación de ZSH."
    else
        show_process "Reinstalando ZSH..."
        echo "Actualizando índice de paquetes..."
        sudo apt update
        echo "Instalando ZSH..."
        sudo apt install -y zsh
    fi
else
    show_process "ZSH no está instalado. Procediendo con la instalación..."
    echo "Actualizando índice de paquetes..."
    sudo apt update
    echo "Instalando ZSH..."
    sudo apt install -y zsh
fi

# Configurar ZSH como shell predeterminado
show_section "CONFIGURANDO ZSH COMO SHELL PREDETERMINADO"
if [[ $SHELL != *"zsh"* ]]; then
    show_process "Estableciendo ZSH como shell predeterminado..."
    chsh -s $(which zsh)
    echo "ZSH ha sido configurado como su shell predeterminado."
    echo "Los cambios tendrán efecto después de cerrar sesión y volver a iniciarla."
else
    show_process "ZSH ya es su shell predeterminado."
fi

# Verificar si Oh My Zsh ya está instalado
show_section "INSTALANDO OH MY ZSH"
if [ -d "$HOME/.oh-my-zsh" ]; then
    show_process "Oh My Zsh ya está instalado en el sistema."
    read -p "¿Desea reinstalar Oh My Zsh? (s/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        echo "Eliminando la instalación existente de Oh My Zsh..."
        rm -rf "$HOME/.oh-my-zsh"
        echo "Instalando Oh My Zsh..."
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    fi
else
    show_process "Instalando Oh My Zsh..."
    echo "Descargando e instalando Oh My Zsh desde el repositorio oficial..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# Instalación de plugins
show_section "INSTALANDO PLUGINS DE ZSH"

# Plugin zsh-autosuggestions
show_process "Verificando plugin zsh-autosuggestions..."
ZSH_AUTOSUGGESTIONS_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
if [ -d "$ZSH_AUTOSUGGESTIONS_DIR" ]; then
    echo "El plugin zsh-autosuggestions ya está instalado."
    read -p "¿Desea actualizarlo? (s/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        echo "Actualizando zsh-autosuggestions..."
        cd "$ZSH_AUTOSUGGESTIONS_DIR" && git pull
    fi
else
    echo "Instalando plugin zsh-autosuggestions..."
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
fi

# Plugin zsh-syntax-highlighting
show_process "Verificando plugin zsh-syntax-highlighting..."
ZSH_SYNTAX_HIGHLIGHTING_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"
if [ -d "$ZSH_SYNTAX_HIGHLIGHTING_DIR" ]; then
    echo "El plugin zsh-syntax-highlighting ya está instalado."
    read -p "¿Desea actualizarlo? (s/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        echo "Actualizando zsh-syntax-highlighting..."
        cd "$ZSH_SYNTAX_HIGHLIGHTING_DIR" && git pull
    fi
else
    echo "Instalando plugin zsh-syntax-highlighting..."
    git clone https://github.com/zsh-users/zsh-syntax-highlighting ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
fi

# Instalación del tema materialshell
show_section "INSTALANDO TEMA MATERIALSHELL"
show_process "Descargando e instalando tema materialshell..."
MATERIALSHELL_THEME_PATH="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/materialshell.zsh-theme"

wget -q https://raw.githubusercontent.com/carloscuesta/materialshell/master/materialshell.zsh -O "$MATERIALSHELL_THEME_PATH"

if [ $? -eq 0 ]; then
    echo "✅ El tema materialshell se ha instalado correctamente."
    # Asegurar permisos correctos
    chmod 644 "$MATERIALSHELL_THEME_PATH"
else
    echo "❌ Error al instalar el tema materialshell."
    exit 1
fi

# Configuración del archivo .zshrc
show_section "CONFIGURANDO ARCHIVO .ZSHRC"
show_process "Actualizando configuración de plugins y tema..."
ZSHRC="$HOME/.zshrc"

# Crear backup del archivo .zshrc original
echo "Creando copia de seguridad del archivo .zshrc..."
cp "$ZSHRC" "${ZSHRC}.backup.$(date +%Y%m%d%H%M%S)"

# Actualizar la línea de plugins en .zshrc
echo "Habilitando plugins zsh-autosuggestions y zsh-syntax-highlighting..."
sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' "$ZSHRC"

# Actualizar el tema en .zshrc
echo "Estableciendo materialshell como tema predeterminado..."
sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="materialshell"/' "$ZSHRC"

# Finalización e inicio automático de ZSH
show_section "¡INSTALACIÓN COMPLETADA!"
echo "✅ ZSH, Oh My Zsh, plugins y tema han sido instalados y configurados correctamente."
echo "⚠️ NOTA: Para futuras sesiones, ZSH será su shell predeterminado."
echo "💡 Iniciando ZSH automáticamente..."

# Ejecutar ZSH para aplicar los cambios inmediatamente
exec zsh
