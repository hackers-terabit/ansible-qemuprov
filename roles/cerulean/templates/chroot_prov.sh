#!/bin/bash
PROFILE=""

function configure_chroot {
prof="$(eselect profile list | sed -nr  's#^\ +\[([0-9]+)\]\ +{{vm_gentoo_profile}}\ ?\**$#\1#p')" && 
eselect profile set $prof

echo 'root:{{vm_gentoo_default_root_pass}}' | chpasswd  &&
echo '{{vm_timezone}}' > /etc/timezone &&
emerge --config sys-libs/timezone-data 

rc-update add sshd default
rc-update add local default
}


## "main"

configure_chroot
exit 
