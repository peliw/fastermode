#!/bin/bash

# Check if the OS supports .deb or .rpm packages
if command -v dpkg &> /dev/null; then
    PACKAGE_TYPE="deb"
elif command -v rpm &> /dev/null; then
    PACKAGE_TYPE="rpm"
else
    echo "Unsupported package management system. Only .deb and .rpm are supported."
    exit 1
fi

read -p "Do you want to continue with the internet (yes/no)? " internet_choice

# General package list - custom your proper package list here
general_packages=(curl screen tmux wget build-essential net-tools)
# Docker-related packages
docker_packages=(docker-io docker-ce docker-compose docker-cli)

echo "General Packages to be installed: ${general_packages[@]}"
echo "Docker Packages to be installed (optional): ${docker_packages[@]}"

read -p "Do you want to install Docker engine (yes/no)? " install_docker_choice

# Merge general and docker packages if user agrees to install Docker
if [[ "$install_docker_choice" == "yes" ]]; then
    packages=("${general_packages[@]}" "${docker_packages[@]}")
else
    packages=("${general_packages[@]}")
fi

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

# final report
clear
echo "Installation Summary:"
echo "Successfully installed packages:"
for pkg in "${installed[@]}"; do
    echo "- $pkg"
done

echo "Failed to install:"
for pkg in "${not_installed[@]}"; do
    echo "- $pkg"
done
