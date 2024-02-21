#!/usr/bin/bash

sb_install() {
sudo mkdir -p /var/lib/shim-signed/mok/

sudo openssl req -config ./mokconfig.cnf \
         -new -x509 -newkey rsa:2048 \
         -nodes -days 36500 -outform DER \
         -keyout /var/lib/shim-signed/mok/MOK.priv \
         -out /var/lib/shim-signed/mok/MOK.der

sudo openssl x509 -in /var/lib/shim-signed/mok/MOK.der -inform DER -outform PEM -out /var/lib/shim-signed/mok/MOK.pem

}

kernel_sign() {

if [[ ! -f /usr/bin/sbsign ]]; then
    sudo apt install -y sbsigntool
fi
sudo install -Dm755 "zz-signing" "/etc/kernel/postinst.d/zz-signing"
sudo chown root:root /etc/kernel/postinst.d/zz-signing
sudo chmod u+rx /etc/kernel/postinst.d/zz-signing

}

import_mok() {

sudo mokutil --import /var/lib/shim-signed/mok/MOK.der
}

show_mok() {
sudo mokutil --list-enrolled
}

help() {

echo "
USAGE : sbsetup [OPTION]

    install    : Install mok files and autosign kernel script, and setup import of MOK
    show       : Show installed MOK files
    uninstall  : Uninstall mok files and autosign kernel script

    help       : Show this message
"


}


case $1 in
install)
    sb_install
    kernel_sign
    import_mok
;;
show)
    show_mok
;;
uninstall)

;;
help)
    help
;;
*)
    help
;;
esac

# Sign Kernel if needed

#sudo apt install -y sbsigntool

#sudo sbsign --key MOK.priv --cert MOK.pem /boot/vmlinuz-[KERNEL-VERSION]-generic --output /boot/vmlinuz-[KERNEL-VERSION]-generic.signed
#sudo cp /boot/initrd.img-[KERNEL-VERSION]-generic{,.signed}
#sudo update-grub

#sudo mv /boot/vmlinuz-[KERNEL-VERSION]-generic{.signed,}
#sudo mv /boot/initrd.img-[KERNEL-VERSION]-generic{.signed,}
#sudo update-grub
