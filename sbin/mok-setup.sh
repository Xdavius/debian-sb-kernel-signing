#!/usr/bin/env bash

if [ "$EUID" != 0 ]; then
   echo "This script must be run as root to write the OpenSSL MOK config file" 
   exit 1
fi

if ((BASH_VERSINFO[0] < 4)); then
   echo "This script requires at least bash version 4"
   exit 1
fi

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo "Linux operating system detected"
else
    echo "This script is for Linux operating systems"
    exit 1
fi

SCRIPT_DIR="$( cd "$( dirname "$(readlink -f "${BASH_SOURCE[0]}")" )" &> /dev/null && pwd )"
REQURIED_PACKAGES=("mokutil" "openssl" "sbsigntool" "grub-efi-amd64-signed") #deleted fwts package from ubuntu - not used

for dpkg in "${REQURIED_PACKAGES[@]}"; do
    echo -n "Checking if ${dpkg} is installed..";
    if ! dpkg -s "${dpkg}" | grep Status | grep -q installed; then
        echo "Ubuntu package ${dpkg} is required before continuing"
        echo "Install using: sudo apt install ${dpkg}"
        exit 1
    else
        echo "[ OK ]"
    fi
done

echo "
########
## Signing MOK Setup for Ubuntu

This script creates and enrolls Machine Owner Keys

It can be used for creating key to be used for signing:
  - Linux Kernel Images for Secure Boot
  - DKMS Kernel Modules such as graphics drivers in Secure Boot
  - Linux Firmware
"

create_mok_config() {
    read -rp "Generate OpenSSL MOK config file? [Y/n]
Required for the first run (default: Y): " _response
    _response=${_response:-"Y"}
    case "$_response" in
        [Yy])
        source "$SCRIPT_DIR/mok-config.sh"
        ;;
        [Nn])
        read -rp "Provide OpenSSL MOK config file path (default: /etc/ssl/openssl-mok.cnf): "
        CONFIGFILE=${CONFIGFILE:-"/etc/ssl/openssl-mok.cnf"}
        ;;
        *)
        create_mok_config
        ;;
    esac
}
create_mok_config

create_mok_certs() {
    read -rp "
Create OpenSSL MOK certificates? [Y/n]
Required for the first run (default: Y): " _response
    _response=${_response:-"Y"}
    case "$_response" in
        [Yy])
        source "$SCRIPT_DIR/mok-create.sh"
        ;;
        [Nn])
        read -rp "Provide path to existing MOK certificates (default: /var/lib/shim-signed/mok/): "
        MOK_CERT_DIR=${MOK_CERT_DIR:-"/var/lib/shim-signed/mok/"}
        mkdir -p $MOK_CERT_DIR
        read -rp "Provide the MOK certificate name (default: MOK-Kernel): "
        MOK_CERT_NAME=${MOK_CERT_NAME:-"MOK-Kernel"}
        ;;
        *)
        create_mok_certs
        ;;
    esac
}
create_mok_certs

enroll_mok_cert() {
    echo "
########
## Enroll MOK Certificate
"
    read -rp "Enroll MOK certificate to MokManager? [y/N]
Required for validating signed kernel images (default: N): " _response
    _response=${_response:-"N"}
    case "$_response" in
        [Yy])
        printf "\nImportant!: When enrolling the MOK certficate to MokManager, you will be prompted to provide a password.
Upon reboot of the system, the blue MokManager screen will appear and allow you to enroll the MOK certficate.
You will need to type the password used during this enroll process to successfully enroll the MOK.
"
        sleep 5

        if mokutil --import "${MOK_CERT_DIR}/${MOK_CERT_NAME}.der"; then
            read -rp "Do you want to reboot now to complete the MOK enroll process? [y/n]: " _response
            case "$_response" in
                [Yy])
                echo "Rebooting system.."
                sleep 2
                shutdown -r now
                ;;
                *)
                read -rp "Manually reboot to finish the MOK enrollment" _response
                ;;
            esac
        else
            echo "An error occured importing the MOK certificate"
        fi
        ;;
        [Nn])
        ;;
        *)
        enroll_mok_cert
        ;;
    esac
}

enroll_mok_cert
