#!/usr/bin/bash

sudo mkdir -p /var/lib/shim-signed/mok/

sudo openssl req -config ./mokconfig.cnf \
         -new -x509 -newkey rsa:2048 \
         -nodes -days 36500 -outform DER \
         -keyout /var/lib/shim-signed/mok/MOK.priv \
         -out /var/lib/shim-signed/mok/MOK.der

sudo openssl x509 -in /var/lib/shim-signed/mok/MOK.der -inform DER -outform PEM -out /var/lib/shim-signed/mok/MOK.pem

sudo mokutil --import /var/lib/shim-signed/mok/MOK.der

sudo mokutil --list-enrolled

# Sign Kernel if needed

#sudo apt install -y sbsigntool

#sudo sbsign --key MOK.priv --cert MOK.pem /boot/vmlinuz-[KERNEL-VERSION]-generic --output /boot/vmlinuz-[KERNEL-VERSION]-generic.signed
#sudo cp /boot/initrd.img-[KERNEL-VERSION]-generic{,.signed}
#sudo update-grub

#sudo mv /boot/vmlinuz-[KERNEL-VERSION]-generic{.signed,}
#sudo mv /boot/initrd.img-[KERNEL-VERSION]-generic{.signed,}
#sudo update-grub
