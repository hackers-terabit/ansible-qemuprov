#!/bin/bash
PROFILE=""
function die {
if [ "$1" -ge 1 ]
then
  echo "$2"
  exit "$1"
fi
}

function configure_chroot {
prof="$(eselect profile list | sed -nr  's#^\ +\[([0-9]+)\]\ +{{vm_gentoo_profile}}\ ?\**$#\1#p')" && 
eselect profile set $prof

echo 'root:{{vm_gentoo_default_root_pass}}' | chpasswd  &&

echo '{{vm_timezone}}' > /etc/timezone &&
emerge --config sys-libs/timezone-data 
rm /etc/localtime
ln -s /usr/share/zoneinfo/UTC /etc/localtime


useradd -d '/home/{{vm_user}}' -m '{{vm_user}}'
gpasswd -a '{{vm_user}}' wheel
gpasswd -a '{{vm_user}}' audio
gpasswd -a '{{vm_user}}' video

emerge -q {{vm_package_list_0}} > /dev/null &&
emerge -q {{vm_package_list_1}} > /dev/null &&
emerge -q {{vm_package_list_2}} > /dev/null && 
#the following packages will be installed always too complex to handle through ansible dynamically.
emerge -q clamav clamav-unofficial-sigs lynis acct audit rkhunter chkrootkit sysklogd gentoolkit arpon sysstat aide ntpclient pass passook tcpdump  pwgen  diffmask flaggie install-mask portpeek tcpdump mtr traceroute whois wgetpaste ntp > /dev/null
die $? "Errors encountered while installing packages in chroot,please debug manually"

cd / && tar -xf /postprov.tar.xz 
rm /etc/issue 
ln -s /etc/motd /etc/issue
#this will take a while :(
freshclam 

rc-update add alsasound default
rc-update add arpon default  
rc-update add auditd default 
rc-update add acct default  
rc-update add fsck default  
rc-update add iptables default
rc-update add ntp-client default
rc-update add sysklogd default  
rc-update add sysstat default 
rc-update add sysctl default 
rc-update add clamd default  
rc-update add sshd default
rc-update add local default
rc-update add rsyslog default


}


## "main"

configure_chroot
exit 


