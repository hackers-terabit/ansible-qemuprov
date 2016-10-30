#!/bin/bash
PROFILE=""
MUST_HAVE="clamav clamav-unofficial-sigs lynis acct audit rkhunter chkrootkit sysklogd gentoolkit arpon sysstat aide ntpclient pass passook tcpdump  pwgen  diffmask flaggie install-mask portpeek tcpdump  traceroute whois wgetpaste ntp gradm paxtest gtk-theme-switch mrxvt geany"

function die {
if [ "$1" -ge 1 ]
then
  echo "$2"
  exit "$1"
fi
}
function try_emerge {
emerge --autounmask-write -uq $@ 2>&1 | tee /var/log/provision.log > /tmp/emergelog
grep -q 'utounmask' /tmp/emerge4
if [ $? -le 0 ]
then
  etc-update --automode -5
  echo "Re-attempting emerge after autounmask changes."
  emerge --keep-going --autounmask-write -uq $@ 2>&1 | tee /var/log/provision.log
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

emerge --sync

try_emerge "{{vm_package_list_0}}"
try_emerge "{{vm_package_list_1}}"
try_emerge "{{vm_package_list_2}}"

#the following packages will be installed always too complex to handle through ansible dynamically.
try_emerge "$MUST_HAVE"

cd / && tar -xf /postprov.tar.xz 
rm /etc/issue 
ln -s /etc/motd /etc/issue
paxctl -c /opt/firefox/firefox 
paxctl -m /opt/firefox/firefox # :'(
pxctl -c /usr/sbin/clamd
paxctl -m /usr/sbin/clamd
paxctl -c /usr/bin/clamconf
paxctl -m /usr/bin/clamconf

#the default postprov.tar.xz should include this default firefox profile
#as well as a modified firefox-bin script to that tries to use this profile-dir if present.
if [ -e '/usr/share/firefox-profile.tar.xz' ]
then
  mkdir -p /home/{{vm_user}}/firefox-profile && cd /home/{{vm_user}}/firefox-profile
  && tar -xf /usr/share/firefox-profile.tar.xz
fi

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

/usr/local/bin/ossec.sh
}


## "main"

configure_chroot
exit 


