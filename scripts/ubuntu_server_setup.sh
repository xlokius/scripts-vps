#!/bin/bash

# ubuntu_server_setup.sh
# Script to automate installation of common tools on Ubuntu Server (24.04+)
# Includes: batcat, eza, git, wget, fastfetch

# Print colored output
print_info() {
    echo -e "\e[1;34m[INFO]\e[0m $1"
}

print_success() {
    echo -e "\e[1;32m[SUCCESS]\e[0m $1"
}

print_error() {
    echo -e "\e[1;31m[ERROR]\e[0m $1"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    print_error "Please run this script as root or with sudo"
    exit 1
fi

# Update package lists
print_info "Updating package lists..."
apt update -y || {
    print_error "Failed to update package lists"
    exit 1
}

# Install git
print_info "Installing git..."
apt install -y git || {
    print_error "Failed to install git"
    exit 1
}

# Install wget
print_info "Installing wget..."
apt install -y wget || {
    print_error "Failed to install wget"
    exit 1
}

# Install batcat (bat)
print_info "Installing batcat..."
apt install -y bat || {
    print_error "Failed to install batcat"
    exit 1
}

# Install eza (might need to be installed from external repository)
print_info "Installing eza..."
# Add PPA for eza if not available in standard repos
if ! apt-cache show eza &>/dev/null; then
    print_info "Eza not found in standard repos, adding external repository..."
    apt install -y gpg
    mkdir -p /etc/apt/keyrings
    wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | gpg --dearmor -o /etc/apt/keyrings/eza.gpg
    echo "deb [signed-by=/etc/apt/keyrings/eza.gpg] http://deb.gierens.de stable main" | tee /etc/apt/sources.list.d/eza.list
    apt update
fi

apt install -y eza || {
    print_error "Failed to install eza"
    exit 1
}

# Install fastfetch (reemplazo moderno de neofetch)
print_info "Installing fastfetch..."
# Agregar PPA para fastfetch
if ! apt-cache show fastfetch &>/dev/null; then
    print_info "Fastfetch not found in standard repos, adding PPA..."
    apt install -y software-properties-common
    add-apt-repository -y ppa:zhangsongcui3371/fastfetch
    apt update
fi

apt install -y fastfetch || {
    print_error "Failed to install fastfetch"
    exit 1
}

# Verify installations
print_info "Verifying installations..."

FAILED_PACKAGES=""

command -v git >/dev/null 2>&1 || FAILED_PACKAGES="$FAILED_PACKAGES git"
command -v wget >/dev/null 2>&1 || FAILED_PACKAGES="$FAILED_PACKAGES wget"
command -v batcat >/dev/null 2>&1 || FAILED_PACKAGES="$FAILED_PACKAGES batcat"
command -v eza >/dev/null 2>&1 || FAILED_PACKAGES="$FAILED_PACKAGES eza"
command -v fastfetch >/dev/null 2>&1 || FAILED_PACKAGES="$FAILED_PACKAGES fastfetch"

if [ -n "$FAILED_PACKAGES" ]; then
    print_error "The following packages may not have installed correctly: $FAILED_PACKAGES"
    exit 1
else
    print_success "All packages installed successfully!"
    print_info "Installed versions:"
    git --version
    wget --version | head -n1
    echo "batcat version: $(batcat --version)"
    echo "eza version: $(eza --version)"
    fastfetch --version
fi

print_success "Installation complete!"
