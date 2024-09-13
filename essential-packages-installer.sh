#!/bin/bash

# Check OS type
if [ -f /etc/debian_version ]; then
    OS="debian"
elif [ -f /etc/redhat-release ]; then
    OS="redhat"
else
    echo "Unsupported OS."
    exit 1
fi

# Ask user whether to continue with internet or offline
read -p "Do you want to continue with the internet (yes/no)? " internet_choice

# Package list
packages=(curl screen tmux wget build-essential net-tools docker-io docker-ce docker-compose)
installed=()
not_installed=()

if [[ "$internet_choice" == "yes" ]]; then
    # Online mode
    if [ "$OS" == "debian" ]; then
        sudo apt update -y
        for package in "${packages[@]}"; do
            if sudo apt install -y --force-yes "$package"; then
                installed+=("$package")
            else
                not_installed+=("$package")
            fi
        done
    elif [ "$OS" == "redhat" ]; then
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
        package_file="$offline_dir/${package}.rpm"  # Assuming .rpm for redhat and .deb for debian
        if [ "$OS" == "debian" ]; then
            package_file="$offline_dir/${package}.deb"
            if [ -f "$package_file" ]; then
                if sudo dpkg -i "$package_file"; then
                    installed+=("$package")
                else
                    not_installed+=("$package")
                fi
            else
                not_installed+=("$package")
            fi
        elif [ "$OS" == "redhat" ]; then
            if [ -f "$package_file" ]; then
                if sudo rpm -ivh "$package_file"; then
                    installed+=("$package")
                else
                    not_installed+=("$package")
                fi
            else
                not_installed+=("$package")
            fi
        fi
    done
fi

# Clear screen and report
clear
echo "Installation Summary:"
echo "Successfully installed:"
for pkg in "${installed[@]}"; do
    echo "- $pkg"
done

echo "Failed to install:"
for pkg in "${not_installed[@]}"; do
    echo "- $pkg"
done
