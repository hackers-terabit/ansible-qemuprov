#!/bin/bash
PROFILE=""

function configure_chroot {
prof="$(eselect profile list | sed -nr  's#^\ +\[([0-9]+)\]\ +{{vm_gentoo_profile}}\ ?\**$#\1#p')" && 
eselect profile set $prof

chpasswd root:{{vm_gentoo_default_root_pass}} &&
echo '{{vm_timezone}}' > /etc/timezone &&
emerge --config sys-libs/timezone-data 

rc-update add sshd default
rc-update add local default
}


## "main"
if [ $# -le 0 ] 
then 
echo "Usage: $0 <chroot directory>"
exit 1
fi
chroot "$1"
configure_chroot
exit 
