#!/bin/bash

function changeme {
echo "******** Please change default root password ********"
fail=1
while [ fail -ge 1 ]
do
  passwd root
  fail=$?
done
echo "******** Please change default password for {{vm_user}} ********"
fail=1
while [ fail -ge 1 ]
do
  passwd {{vm_user}}
  fail=$?
done
}

changeme

echo "Installation  has completed."
echo "Please check out the following installed applications:"
echo "glsa-check - for making sure this system is not vulnerable to any known gentoo linux security advisories."
echo "aide - for system and file integrity validation."
echo "pass - a command line password manager."
echo "passook,pwgen - password generators"
echo "chkrootkit - Finds any known rootkits on this system"
echo "clamav - a free anti-virus"
echo "lynis - an automated system hardening checker."
echo "Additionally these and other applications generate logs (under /var/log/), be sure to regularly audit these logs for anomalies."
echo "The network configuration is currently managed by /etc/local.d/prov_net.start, Once you have configured your gentoo system with proper network and firewall configuration according to your needs,please remove this file"
echo "To start X11 (if installed) please login as {{vm_user}} and type 'startx'"
echo "Thank you for using this automated provisioning system."
echo "Feel free to pop in ##hackers on chat.freenode.net for any questions/support"

rm /etc/local.d/end_prov.start #remove self
rm /postprov.tar.xz