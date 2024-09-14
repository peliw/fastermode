#!/bin/bash

# Function to validate yes/no inputs
validate_yes_no() {
    local answer
    while true; do
        read -p "$1 (yes/y or no/n): " answer
        case "$answer" in
            [yY][eE][sS]|[yY]) echo "yes"; break;;
            [nN][oO]|[nN]) echo "no"; break;;
            *) clear; echo "XXX     Invalid input. Please enter yes/y or no/n.";;
        esac
    done
}

if command -v dpkg &> /dev/null; then
    PACKAGE_TYPE="deb"
elif command -v rpm &> /dev/null; then
    PACKAGE_TYPE="rpm"
else
    echo "XXX     Unsupported package management system. Only .deb and .rpm are supported."
    exit 1
fi
clear
echo "###     Do you want to continue online installation or using offline packages?"
internet_choice=$(validate_yes_no ">>>     yes: ONLINE | no : OFFLINE?")

# General package list
general_packages=(curl screen tmux wget build-essential net-tools)
# Docker-related packages
docker_packages=(docker-io docker-ce docker-compose docker-cli)
clear
# Print the list of packages to install
echo "###      General Packages to be installed:"
echo "${general_packages[@]}"
echo "###      Docker Packages to be installed (optional)}"
echo "${docker_packages[@]}"

# Ask if the user wants to install Docker and related packages
install_docker_choice=$(validate_yes_no ">>>     Do you want to install Docker and related packages")

# Merge general and docker packages if user agrees to install Docker
if [[ "$install_docker_choice" == "yes" ]]; then
    packages=("${general_packages[@]}" "${docker_packages[@]}")
else
    packages=("${general_packages[@]}")
fi

# Initialize arrays to track installation status
installed=()
not_installed=()

if [[ "$internet_choice" == "yes" ]]; then
    # Online mode
    if [ "$PACKAGE_TYPE" == "deb" ]; then
        sudo apt update -y
        for package in "${packages[@]}"; do
            if sudo apt install -y --force-yes "$package"; then
                installed+=("$package")
            else
                not_installed+=("$package")
            fi
        done
    elif [ "$PACKAGE_TYPE" == "rpm" ]; then
        sudo yum update -y
        for package in "${packages[@]}"; do
            if sudo yum install -y "$package"; then
                installed+=("$package")
            else
                not_installed+=("$package")
            fi
        done
    fi
else
    # Offline mode
    offline_dir="./offline-installation"
    for package in "${packages[@]}"; do
        package_file="$offline_dir/${package}.${PACKAGE_TYPE}"
        if [ -f "$package_file" ]; then
            if [ "$PACKAGE_TYPE" == "deb" ]; then
                if sudo dpkg -i "$package_file"; then
                    installed+=("$package")
                else
                    not_installed+=("$package")
                fi
            elif [ "$PACKAGE_TYPE" == "rpm" ]; then
                if sudo rpm -ivh "$package_file"; then
                    installed+=("$package")
                else
                    not_installed+=("$package")
                fi
            fi
        else
            not_installed+=("$package")
        fi
    done
fi

# Clear screen and report
clear
echo "###     Installation Summary:"
if [ ${#installed[@]} -eq 0 ]; then
    echo "XXX     Successfully installed: No packages were installed successfully."
else
    echo "###     Successfully installed:"
    for pkg in "${installed[@]}"; do
        echo "- $pkg"
    done
fi

if [ ${#not_installed[@]} -eq 0 ]; then
    echo "###     Failed to install: None"
else
    echo "XXX     Failed to install:"
    for pkg in "${not_installed[@]}"; do
        echo "- $pkg"
    done
fi

