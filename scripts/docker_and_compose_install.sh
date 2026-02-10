#!/bin/bash

# Docker and Docker Compose Installation Script for Ubuntu 24.04+
# Based on DigitalOcean guides and official Docker documentation
# Compatible with Ubuntu 22.04, 24.04 and newer LTS versions

# Exit immediately if a command exits with a non-zero status
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

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Inicio del script
show_section "INICIANDO INSTALACIÓN DE DOCKER Y DOCKER COMPOSE"
echo "Este script instalará Docker y Docker Compose en su sistema Ubuntu."
echo "Se realizarán los siguientes pasos:"
echo "  1. Verificación de instalación previa"
echo "  2. Instalación de dependencias necesarias"
echo "  3. Configuración del repositorio oficial de Docker"
echo "  4. Instalación de Docker Engine y Docker Compose"
echo "  5. Configuración de permisos de usuario"
echo "  6. Verificación de la instalación"

# Check if Docker is already installed
show_section "VERIFICANDO INSTALACIÓN PREVIA"
if command_exists docker; then
    show_process "Docker ya está instalado en el sistema. Verificando versión..."
    docker --version

    # Check if running non-interactively (piped or from another script)
    if [ ! -t 0 ] || [ -n "$NONINTERACTIVE" ]; then
        echo "Modo no interactivo detectado. Omitiendo reinstalación de Docker."
        exit 0
    fi

    read -p "¿Desea continuar con la reinstalación? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Omitiendo la instalación de Docker."
        exit 0
    fi
fi

show_section "PREPARANDO EL SISTEMA"
show_process "Actualizando índice de paquetes..."
echo "Esto puede tomar unos momentos dependiendo de la velocidad de su conexión."
sudo apt update

show_process "Instalando paquetes prerequisitos..."
echo "Instalando: apt-transport-https, ca-certificates, curl, software-properties-common, gnupg, lsb-release"
echo "Estos paquetes son necesarios para añadir repositorios HTTPS y manejar claves GPG."
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common gnupg lsb-release

show_section "CONFIGURANDO REPOSITORIO DE DOCKER"
show_process "Añadiendo la clave GPG oficial de Docker..."
echo "La clave GPG verifica la autenticidad de los paquetes de Docker."
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

show_process "Configurando el repositorio de Docker..."
echo "Añadiendo el repositorio oficial de Docker para Ubuntu $(lsb_release -cs)."
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

show_process "Actualizando índice de paquetes con el repositorio de Docker..."
sudo apt update

show_section "INSTALANDO DOCKER ENGINE Y DOCKER COMPOSE"
show_process "Instalando Docker Engine y herramientas relacionadas..."
echo "Instalando los siguientes paquetes:"
echo "  - docker-ce: Motor principal de Docker"
echo "  - docker-ce-cli: Interfaz de línea de comandos"
echo "  - containerd.io: Runtime de contenedores"
echo "  - docker-buildx-plugin: Plugin para construir imágenes"
echo "  - docker-compose-plugin: Plugin para Docker Compose"
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

show_process "Configurando permisos de usuario..."
echo "Añadiendo el usuario actual (${USER}) al grupo 'docker'."
echo "Esto permitirá ejecutar comandos de Docker sin necesidad de sudo."
sudo usermod -aG docker ${USER}

show_process "Docker Compose está instalado a través del plugin docker-compose-plugin"
echo "A partir de Docker 20.10, Docker Compose se integra como un plugin."

show_section "VERIFICANDO LA INSTALACIÓN"
show_process "Verificando la instalación de Docker..."
echo "Ejecutando contenedor de prueba 'hello-world'..."
sudo docker run hello-world

show_process "Verificando la instalación de Docker Compose..."
echo "Comprobando la versión de Docker Compose..."
docker compose version

show_section "¡INSTALACIÓN COMPLETADA!"
echo "✅ Docker y Docker Compose han sido instalados correctamente."
echo "⚠️ NOTA: Es posible que necesite cerrar sesión y volver a iniciarla para que los cambios"
echo "   en la membresía del grupo 'docker' surtan efecto."
echo "💡 Para usar Docker sin sudo inmediatamente, ejecute: newgrp docker"
echo "\nGracias por utilizar este script de instalación."
