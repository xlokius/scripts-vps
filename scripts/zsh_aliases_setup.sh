#!/bin/bash

# zsh_aliases_setup.sh
# Script para agregar alias útiles al archivo .zshrc del usuario

# Color definitions
BLUE='\e[1;34m'
GREEN='\e[1;32m'
RED='\e[1;31m'
YELLOW='\e[1;33m'
NC='\e[0m' # No Color

# Print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Función para agregar alias al .zshrc 
add_aliases_to_zshrc() {
    local home_dir="$1"
    local zshrc_file="${home_dir}/.zshrc"
    
    # Verificar si existe .zshrc
    if [ ! -f "${zshrc_file}" ]; then
        print_warning "No se encontró el archivo .zshrc en ${home_dir}"
        print_info "Creando un nuevo archivo .zshrc"
        touch "${zshrc_file}"
    fi
    
    # Verificar si los alias ya existen
    if grep -q "# Aliases configurados por zsh_aliases_setup.sh" "${zshrc_file}"; then
        print_warning "Los alias ya están configurados en ${zshrc_file}"
        print_info "Eliminando configuración previa antes de actualizarla"
        
        # Crear un archivo temporal
        local temp_file=$(mktemp)
        
        # Eliminar sección de alias anterior
        sed '/# Aliases configurados por zsh_aliases_setup.sh/,/# Fin de aliases configurados/d' "${zshrc_file}" > "${temp_file}"
        
        # Reemplazar el archivo original
        mv "${temp_file}" "${zshrc_file}"
    fi
    
    # Agregar nuevos alias al final del archivo
    print_info "Agregando aliases a ${zshrc_file}"
    cat >> "${zshrc_file}" << EOL

# Aliases configurados por zsh_aliases_setup.sh
print_info() {
    echo -e "\e[1;34m[INFO]\e[0m \$1"
}

print_info "Cargando aliases personalizados..."

# Aliases para reemplazar ls con eza
alias ls="eza -lh"
alias la="eza -lah"

# Aliases para batcat
alias bat="batcat"

# Fin de aliases configurados
EOL
    
    print_success "Aliases configurados correctamente en ${zshrc_file}"
    
    # Recargar la configuración
    if [[ "$SHELL" == *"zsh"* ]]; then
        print_info "Recargando la configuración de ZSH..."
        if [ "${home_dir}" = "$HOME" ]; then
            print_info "Aplicando cambios con 'source ${zshrc_file}'"
            source "${zshrc_file}"
        else
            print_info "No se puede recargar la configuración para otro usuario automáticamente"
            print_info "Se aplicará en la próxima sesión o al ejecutar manualmente 'source ${zshrc_file}'"
        fi
    else
        print_info "La shell actual no es ZSH, los cambios se aplicarán la próxima vez que inicie ZSH"
    fi
}

# Función principal
main() {
    print_info "Configurando aliases para Zsh..."
    
    # Verificar si no estamos como root
    if [ "$EUID" -eq 0 ]; then
        print_warning "Ejecutando como root, configurando aliases para el usuario actual y el usuario real"
        
        # Obtener usuario real (el que ejecutó sudo)
        local real_user=""
        if [ -n "$SUDO_USER" ]; then
            real_user="$SUDO_USER"
        else
            # Intentar obtener el usuario que inició la sesión
            real_user=$(logname 2>/dev/null || echo "")
        fi
        
        # Configurar para el usuario root
        add_aliases_to_zshrc "/root"
        
        # Configurar para el usuario real si existe
        if [ -n "${real_user}" ] && [ "${real_user}" != "root" ]; then
            local real_home=$(eval echo ~${real_user})
            print_info "Configurando aliases para el usuario ${real_user} (${real_home})"
            
            # Asegurarse de que el usuario tenga permisos sobre su propio .zshrc
            add_aliases_to_zshrc "${real_home}"
            chown "${real_user}":"${real_user}" "${real_home}/.zshrc"
        fi
    else
        # Usuario normal
        add_aliases_to_zshrc "$HOME"
    fi
    
    print_success "¡Configuración de aliases completada!"
    
    # Recargar la configuración zsh al final del script completo
    if [[ "$SHELL" == *"zsh"* ]]; then
        print_info "Recargando la configuración ZSH para aplicar los cambios inmediatamente..."
        # Usando la ruta completa para asegurar que funcione en todos los casos
        source "$HOME/.zshrc"
    else
        print_info "Para aplicar los cambios, ejecuta manualmente: source ~/.zshrc"
    fi
}

# Ejecutar función principal
main
