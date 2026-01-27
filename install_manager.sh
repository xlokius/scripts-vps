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

# Check internet connectivity
check_internet() {
    print_info "Verificando conectividad a internet..."
    if ping -c 1 -W 5 8.8.8.8 &>/dev/null || ping -c 1 -W 5 1.1.1.1 &>/dev/null; then
        print_success "Conectividad a internet verificada"
        return 0
    else
        print_error "No se detectó conexión a internet"
        print_error "Por favor, verifique su conexión e intente de nuevo"
        exit 1
    fi
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

    echo -e "\n${YELLOW}${category_name}:${NC}"

    local counter=0
    for script_info in "${script_array[@]}"; do
        IFS=':' read -r script_name script_desc <<< "${script_info}"
        local item_index=$((start_index + counter))

        if script_exists "${script_name}"; then
            echo -e "  ${item_index}. ${GREEN}${script_name}${NC} - ${script_desc}"
        else
            echo -e "  ${item_index}. ${RED}${script_name}${NC} - ${script_desc} ${RED}(No disponible)${NC}"
        fi

        counter=$((counter + 1))
    done
}

# Function to display menu and get user selection
display_menu() {
    print_header "GESTOR DE INSTALACIÓN"

    echo "Seleccione los scripts a ejecutar (separados por comas):"

    # Display installation scripts
    display_script_category "SCRIPTS DE INSTALACIÓN" INSTALL_SCRIPTS[@] 1

    # Display post-installation scripts
    local post_start_index=$((${#INSTALL_SCRIPTS[@]} + 1))
    display_script_category "SCRIPTS DE POST-INSTALACIÓN" POST_INSTALL_SCRIPTS[@] ${post_start_index}

    echo
    echo "  i. Ejecutar todos los scripts de instalación"
    echo "  p. Ejecutar todos los scripts de post-instalación"
    echo "  a. Ejecutar todos los scripts (instalación y post-instalación)"
    echo "  q. Salir"
    echo

    read -p "Selección: " selection

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
