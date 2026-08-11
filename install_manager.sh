#!/bin/bash

# install_manager.sh
# Script principal para gestionar la instalación de varios programas y herramientas
# Compatible con Ubuntu 22.04, 24.04 y versiones LTS más recientes
# Ofrece un menú interactivo para seleccionar qué scripts ejecutar

# Color definitions
BLUE='\e[1;34m'
GREEN='\e[1;32m'
RED='\e[1;31m'
YELLOW='\e[1;33m'
CYAN='\e[1;36m'
MAGENTA='\e[1;35m'
DIM='\e[2m'
NC='\e[0m' # No Color

# Logging configuration
LOG_DIR="/var/log/vps-setup"
LOG_FILE="${LOG_DIR}/install_$(date +%Y%m%d_%H%M%S).log"

# Initialize logging
init_logging() {
    mkdir -p "${LOG_DIR}"
    touch "${LOG_FILE}"
    chmod 644 "${LOG_FILE}"
    echo "========================================" >> "${LOG_FILE}"
    echo "Instalación iniciada: $(date)" >> "${LOG_FILE}"
    echo "Usuario: $(whoami)" >> "${LOG_FILE}"
    echo "Sistema: $(lsb_release -d 2>/dev/null | cut -f2 || cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)" >> "${LOG_FILE}"
    echo "========================================" >> "${LOG_FILE}"
}

# Log message to file
log_message() {
    local level="$1"
    local message="$2"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [${level}] ${message}" >> "${LOG_FILE}"
}

# Print colored output
print_header() {
    echo -e "\n${BLUE}=====================================================${NC}"
    echo -e "${BLUE}    $1${NC}"
    echo -e "${BLUE}=====================================================${NC}\n"
    log_message "HEADER" "$1"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
    log_message "INFO" "$1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
    log_message "SUCCESS" "$1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    log_message "ERROR" "$1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
    log_message "WARNING" "$1"
}

# Comprueba la conectividad sin imprimir mensajes para poder reutilizarla en el panel.
has_internet_connection() {
    if ping -c 1 -W 5 8.8.8.8 &>/dev/null || ping -c 1 -W 5 1.1.1.1 &>/dev/null; then
        return 0
    fi

    return 1
}

# Check internet connectivity
check_internet() {
    print_info "Verificando conectividad a internet..."
    if has_internet_connection; then
        print_success "Conectividad a internet verificada"
        return 0
    fi

    print_error "No se detectó conexión a internet"
    print_error "Por favor, verifique su conexión e intente de nuevo"
    exit 1
}

# Check if script is run as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        print_error "Este script debe ejecutarse como root o con sudo"
        exit 1
    fi
}

# Path to installation scripts
SCRIPTS_DIR="$(dirname "$(readlink -f "$0")")"
SCRIPTS_SUBDIR="${SCRIPTS_DIR}/scripts"

# Lista de scripts de instalación
INSTALL_SCRIPTS=(
    "ubuntu_server_setup.sh:Instalar herramientas básicas (batcat, eza, git, wget, neofetch)"
    "docker_and_compose_install.sh:Instalar Docker y Docker Compose"
    "zsh_install.sh:Instalar ZSH y configurarlo"
)

# Lista de scripts de post-instalación
POST_INSTALL_SCRIPTS=(
    "zsh_aliases_setup.sh:Configurar aliases útiles para ZSH"
)

# Obtiene la IP pública sin impedir el funcionamiento del menú si el servicio no responde.
get_public_ip() {
    local public_ip=""

    if command -v curl &>/dev/null; then
        public_ip=$(curl -4fsS --connect-timeout 2 --max-time 4 https://api.ipify.org 2>/dev/null || true)
    elif command -v wget &>/dev/null; then
        public_ip=$(wget -4qO- --timeout=4 https://api.ipify.org 2>/dev/null || true)
    fi

    if [[ "${public_ip}" =~ ^[0-9]{1,3}(\.[0-9]{1,3}){3}$ ]]; then
        echo "${public_ip}"
    else
        echo "No disponible"
    fi
}

get_os_details() {
    local os_name="Linux"
    local os_version="No disponible"

    if [ -r /etc/os-release ]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        os_name="${NAME:-Linux}"
        os_version="${VERSION:-${VERSION_ID:-No disponible}}"
    fi

    printf '%s|%s\n' "${os_name}" "${os_version}"
}

print_panel_row() {
    local label="$1"
    local value="$2"
    local value_color="${3:-$YELLOW}"

    printf "${BLUE}│${NC} ${CYAN}%-16s${NC} ${BLUE}:${NC} ${value_color}%-44s${NC} ${BLUE}│${NC}\n" "${label}" "${value}"
}

display_system_panel() {
    local os_details os_name os_version public_ip internet_status internet_color
    local current_time architecture kernel_version host_name

    os_details=$(get_os_details)
    IFS='|' read -r os_name os_version <<< "${os_details}"
    public_ip=$(get_public_ip)
    current_time=$(date '+%Y-%m-%d %H:%M:%S %Z')
    architecture=$(uname -m)
    kernel_version=$(uname -r)
    host_name=$(hostname)

    if has_internet_connection; then
        internet_status="● CONECTADO"
        internet_color="${GREEN}"
    else
        internet_status="● SIN CONEXIÓN"
        internet_color="${RED}"
    fi

    if [ -t 1 ]; then
        clear
    fi

    printf '%b\n' "${BLUE}╭──────────────────────────────────────────────────────────────────╮${NC}"
    printf "${BLUE}│${NC} ${YELLOW}%-64s${NC} ${BLUE}│${NC}\n" "SCRIPTS VPS · GESTOR DE INSTALACIÓN"
    printf '%b\n' "${BLUE}├──────────────────────────────────────────────────────────────────┤${NC}"
    print_panel_row "SISTEMA" "${os_name}" "${YELLOW}"
    print_panel_row "VERSIÓN" "${os_version}" "${YELLOW}"
    print_panel_row "ARQUITECTURA" "${architecture} · kernel ${kernel_version}" "${YELLOW}"
    print_panel_row "HOSTNAME" "${host_name}" "${YELLOW}"
    print_panel_row "IP PÚBLICA" "${public_ip}" "${YELLOW}"
    print_panel_row "HORA ACTUAL" "${current_time}" "${YELLOW}"
    print_panel_row "INTERNET" "${internet_status}" "${internet_color}"
    printf '%b\n' "${BLUE}╰──────────────────────────────────────────────────────────────────╯${NC}"
}

# Function to check if a script exists
script_exists() {
    local script_name="$1"
    if [ -f "${SCRIPTS_SUBDIR}/${script_name}" ]; then
        return 0
    else
        return 1
    fi
}

# Function to make script executable
make_executable() {
    local script_name="$1"
    if [ -f "${SCRIPTS_SUBDIR}/${script_name}" ]; then
        chmod +x "${SCRIPTS_SUBDIR}/${script_name}"
        print_info "Script ${script_name} marcado como ejecutable"
    fi
}

# Function to execute a script
execute_script() {
    local script_name="$1"
    local script_path="${SCRIPTS_SUBDIR}/${script_name}"

    print_header "Ejecutando ${script_name}"
    log_message "INFO" "Iniciando ejecución de: ${script_name}"

    if script_exists "${script_name}"; then
        make_executable "${script_name}"

        # Ejecutar script y capturar salida en el log
        "${script_path}" 2>&1 | tee -a "${LOG_FILE}"
        local exit_code=${PIPESTATUS[0]}

        if [ $exit_code -eq 0 ]; then
            print_success "Script ${script_name} ejecutado correctamente"
            log_message "SUCCESS" "Script ${script_name} completado exitosamente"
        else
            print_error "Error al ejecutar ${script_name} (código: ${exit_code})"
            log_message "ERROR" "Script ${script_name} falló con código: ${exit_code}"
        fi
    else
        print_error "Script ${script_name} no encontrado"
        log_message "ERROR" "Script no encontrado: ${script_name}"
    fi
}

# Función para mostrar scripts disponibles de una categoría
display_script_category() {
    local category_name="$1"
    local script_array=("${!2}")
    local start_index="$3"

    printf '%b\n' "${MAGENTA}${category_name}${NC}"

    local counter=0
    for script_info in "${script_array[@]}"; do
        IFS=':' read -r script_name script_desc <<< "${script_info}"
        local item_index=$((start_index + counter))

        if script_exists "${script_name}"; then
            printf "  ${BLUE}[%02d]${NC} ${CYAN}%-32s${NC} ${DIM}%s${NC} ${GREEN}[LISTO]${NC}\n" "${item_index}" "${script_name}" "${script_desc}"
        else
            printf "  ${BLUE}[%02d]${NC} ${RED}%-32s${NC} ${DIM}%s${NC} ${RED}[NO DISPONIBLE]${NC}\n" "${item_index}" "${script_name}" "${script_desc}"
        fi

        counter=$((counter + 1))
    done
}

# Function to display menu and get user selection
display_menu() {
    display_system_panel
    echo
    printf '%b\n' "${BLUE}╭────────────────────── SCRIPTS DISPONIBLES ──────────────────────╮${NC}"

    # Display installation scripts
    display_script_category "SCRIPTS DE INSTALACIÓN" INSTALL_SCRIPTS[@] 1

    # Display post-installation scripts
    local post_start_index=$((${#INSTALL_SCRIPTS[@]} + 1))
    echo
    display_script_category "SCRIPTS DE POST-INSTALACIÓN" POST_INSTALL_SCRIPTS[@] ${post_start_index}

    printf '%b\n' "${BLUE}├──────────────────────────────────────────────────────────────────┤${NC}"
    printf '%b\n' "${BLUE}│${NC} ${YELLOW}[I]${NC} Instalación   ${YELLOW}[P]${NC} Post-instalación   ${YELLOW}[A]${NC} Todo   ${YELLOW}[Q]${NC} Salir  ${BLUE}│${NC}"
    printf '%b\n' "${BLUE}╰──────────────────────────────────────────────────────────────────╯${NC}"
    echo

    read -r -p $'\e[1;32mSelecciona una opción (ej. 1,3 o A): \e[0m' selection

    # Process selection
    case ${selection} in
        [0-9]*)
            # Handle individual or comma-separated numbers
            IFS=',' read -ra SELECTED_SCRIPTS <<< "${selection}"
            for sel in "${SELECTED_SCRIPTS[@]}"; do
                if [[ "${sel}" =~ ^[0-9]+$ ]]; then
                    # Validar y ejecutar script de instalación
                    if [ "${sel}" -ge 1 ] && [ "${sel}" -le "${#INSTALL_SCRIPTS[@]}" ]; then
                        IFS=':' read -r script_name script_desc <<< "${INSTALL_SCRIPTS[$(($sel - 1))]}"

                        if script_exists "${script_name}"; then
                            execute_script "${script_name}"
                        else
                            print_error "Script ${script_name} no está disponible"
                        fi
                    # Validar y ejecutar script de post-instalación
                    elif [ "${sel}" -gt "${#INSTALL_SCRIPTS[@]}" ] && [ "${sel}" -le "$((${#INSTALL_SCRIPTS[@]} + ${#POST_INSTALL_SCRIPTS[@]}))" ]; then
                        local post_index=$((${sel} - ${#INSTALL_SCRIPTS[@]} - 1))
                        IFS=':' read -r script_name script_desc <<< "${POST_INSTALL_SCRIPTS[${post_index}]}"

                        if script_exists "${script_name}"; then
                            execute_script "${script_name}"
                        else
                            print_error "Script ${script_name} no está disponible"
                        fi
                    else
                        print_error "Selección inválida: ${sel}"
                    fi
                else
                    print_error "Selección inválida: ${sel}"
                fi
            done
            ;;
        "i"|"I")
            # Execute all installation scripts
            for script_info in "${INSTALL_SCRIPTS[@]}"; do
                IFS=':' read -r script_name script_desc <<< "${script_info}"
                if script_exists "${script_name}"; then
                    execute_script "${script_name}"
                fi
            done
            ;;
        "p"|"P")
            # Execute all post-installation scripts
            for script_info in "${POST_INSTALL_SCRIPTS[@]}"; do
                IFS=':' read -r script_name script_desc <<< "${script_info}"
                if script_exists "${script_name}"; then
                    execute_script "${script_name}"
                fi
            done
            ;;
        "a"|"A")
            # Execute all available scripts (installation + post-installation)
            print_info "Ejecutando scripts de instalación..."
            for script_info in "${INSTALL_SCRIPTS[@]}"; do
                IFS=':' read -r script_name script_desc <<< "${script_info}"
                if script_exists "${script_name}"; then
                    execute_script "${script_name}"
                fi
            done

            print_info "Ejecutando scripts de post-instalación..."
            for script_info in "${POST_INSTALL_SCRIPTS[@]}"; do
                IFS=':' read -r script_name script_desc <<< "${script_info}"
                if script_exists "${script_name}"; then
                    execute_script "${script_name}"
                fi
            done
            ;;
        "q"|"Q")
            print_info "Saliendo del gestor de instalación"
            exit 0
            ;;
        *)
            print_error "Selección inválida"
            ;;
    esac
}

# Verificar disponibilidad de scripts
check_available_scripts() {
    local available_scripts=0

    # Verificar scripts de instalación
    for script_info in "${INSTALL_SCRIPTS[@]}"; do
        IFS=':' read -r script_name script_desc <<< "${script_info}"
        if script_exists "${script_name}"; then
            available_scripts=$((available_scripts + 1))
        fi
    done

    # Verificar scripts de post-instalación
    for script_info in "${POST_INSTALL_SCRIPTS[@]}"; do
        IFS=':' read -r script_name script_desc <<< "${script_info}"
        if script_exists "${script_name}"; then
            available_scripts=$((available_scripts + 1))
        fi
    done

    echo "${available_scripts}"
}

# Main function
main() {
    init_logging
    print_info "Log de instalación: ${LOG_FILE}"

    check_root
    check_internet

    # Check if scripts directory exists
    if [ ! -d "${SCRIPTS_SUBDIR}" ]; then
        print_error "Directorio de scripts no encontrado: ${SCRIPTS_SUBDIR}"
        exit 1
    fi

    # Check if any scripts are available
    local available_scripts=$(check_available_scripts)

    if [ "${available_scripts}" -eq 0 ]; then
        print_error "No se encontraron scripts de instalación en el directorio: ${SCRIPTS_SUBDIR}"
        exit 1
    fi

    # Display the menu and handle user selection
    display_menu

    print_success "Proceso de instalación completado"
    log_message "INFO" "========================================"
    log_message "INFO" "Instalación finalizada: $(date)"
    log_message "INFO" "========================================"
    print_info "Log completo guardado en: ${LOG_FILE}"
}

# Run the main function
main
