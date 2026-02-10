#!/bin/bash

# install_all.sh
# Script para ejecutar automáticamente todos los scripts de instalación y post-instalación
# Compatible con Ubuntu 22.04, 24.04 y versiones LTS más recientes
# Ejecuta la opción "a" del install_manager.sh de forma no interactiva

# Color definitions
BLUE='\e[1;34m'
GREEN='\e[1;32m'
RED='\e[1;31m'
YELLOW='\e[1;33m'
NC='\e[0m' # No Color

# Logging configuration
LOG_DIR="/var/log/vps-setup"
LOG_FILE="${LOG_DIR}/install_all_$(date +%Y%m%d_%H%M%S).log"

# Initialize logging
init_logging() {
    mkdir -p "${LOG_DIR}"
    touch "${LOG_FILE}"
    chmod 644 "${LOG_FILE}"
    echo "========================================" >> "${LOG_FILE}"
    echo "Instalación completa iniciada: $(date)" >> "${LOG_FILE}"
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

# Lista de scripts de instalación (en orden de ejecución)
INSTALL_SCRIPTS=(
    "ubuntu_server_setup.sh"
    "docker_and_compose_install.sh"
    "zsh_install.sh"
)

# Lista de scripts de post-instalación
POST_INSTALL_SCRIPTS=(
    "zsh_aliases_setup.sh"
)

# Function to check if a script exists
script_exists() {
    local script_name="$1"
    [ -f "${SCRIPTS_SUBDIR}/${script_name}" ]
}

# Function to make script executable
make_executable() {
    local script_name="$1"
    if [ -f "${SCRIPTS_SUBDIR}/${script_name}" ]; then
        chmod +x "${SCRIPTS_SUBDIR}/${script_name}"
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

        # Ejecutar script en modo no interactivo y capturar salida en el log
        NONINTERACTIVE=1 "${script_path}" 2>&1 | tee -a "${LOG_FILE}"
        local exit_code=${PIPESTATUS[0]}

        if [ $exit_code -eq 0 ]; then
            print_success "Script ${script_name} ejecutado correctamente"
            log_message "SUCCESS" "Script ${script_name} completado exitosamente"
            return 0
        else
            print_error "Error al ejecutar ${script_name} (código: ${exit_code})"
            log_message "ERROR" "Script ${script_name} falló con código: ${exit_code}"
            return 1
        fi
    else
        print_error "Script ${script_name} no encontrado"
        log_message "ERROR" "Script no encontrado: ${script_name}"
        return 1
    fi
}

# Main function
main() {
    init_logging

    print_header "INSTALACIÓN COMPLETA AUTOMÁTICA"
    print_info "Log de instalación: ${LOG_FILE}"
    print_info "Este script instalará todos los componentes automáticamente"
    echo ""

    check_root
    check_internet

    # Check if scripts directory exists
    if [ ! -d "${SCRIPTS_SUBDIR}" ]; then
        print_error "Directorio de scripts no encontrado: ${SCRIPTS_SUBDIR}"
        exit 1
    fi

    local failed_scripts=""
    local total_scripts=$((${#INSTALL_SCRIPTS[@]} + ${#POST_INSTALL_SCRIPTS[@]}))
    local current_script=0

    # Execute all installation scripts
    print_header "EJECUTANDO SCRIPTS DE INSTALACIÓN"
    for script_name in "${INSTALL_SCRIPTS[@]}"; do
        current_script=$((current_script + 1))
        print_info "Progreso: ${current_script}/${total_scripts}"

        if script_exists "${script_name}"; then
            if ! execute_script "${script_name}"; then
                failed_scripts="${failed_scripts} ${script_name}"
            fi
        else
            print_warning "Script ${script_name} no disponible, omitiendo..."
            log_message "WARNING" "Script omitido (no disponible): ${script_name}"
        fi
    done

    # Execute all post-installation scripts
    print_header "EJECUTANDO SCRIPTS DE POST-INSTALACIÓN"
    for script_name in "${POST_INSTALL_SCRIPTS[@]}"; do
        current_script=$((current_script + 1))
        print_info "Progreso: ${current_script}/${total_scripts}"

        if script_exists "${script_name}"; then
            if ! execute_script "${script_name}"; then
                failed_scripts="${failed_scripts} ${script_name}"
            fi
        else
            print_warning "Script ${script_name} no disponible, omitiendo..."
            log_message "WARNING" "Script omitido (no disponible): ${script_name}"
        fi
    done

    # Final summary
    print_header "RESUMEN DE INSTALACIÓN"

    if [ -z "${failed_scripts}" ]; then
        print_success "¡Todos los scripts se ejecutaron correctamente!"
        log_message "SUCCESS" "Instalación completa finalizada sin errores"
    else
        print_error "Los siguientes scripts fallaron:${failed_scripts}"
        log_message "ERROR" "Scripts con errores:${failed_scripts}"
    fi

    log_message "INFO" "========================================"
    log_message "INFO" "Instalación finalizada: $(date)"
    log_message "INFO" "========================================"

    print_info "Log completo guardado en: ${LOG_FILE}"

    echo ""
    print_warning "NOTA: Es recomendable reiniciar la sesión o el servidor para aplicar todos los cambios"
    echo ""
}

# Run the main function
main
