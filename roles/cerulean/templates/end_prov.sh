#!/bin/bash

function changeme {
fail=1
while [ $fail -ge 1 ]
do
  echo "******** Please change the default root password ********"
  timeout 60 passwd root
  $fail=$?
done
fail=1
while [ $fail -ge 1 ]
do
  echo "******** Please change the password for {{vm_user}} ********"
  timeout 60 passwd {{vm_user}}
  $fail=$?
done
}

changeme

echo "Installation  has completed."
echo "Please check out the following installed applications:"
echo "glsa-check - for making sure this system is not vulnerable to any known gentoo linux security advisories."
echo "aide - for system and file integrity validation."
echo "pass - a command line password manager."
echo "passook,pwgen - password generators"
echo "chkrootkit,rkhunter - Finds any known rootkits on this system"
echo "clamav - a free anti-virus"
echo "auditd - Audit the system"
echo "OSSEC - A host based intrusion detection and prevention system"
echo "lynis - an automated system hardening checker."
echo "paxtest,checksec.sh - Test various hardening properties of the system"
echo "Additionally these and other applications generate logs (under /var/log/), be sure to regularly audit these logs for anomalies."
echo "To start X11 (if installed) please login as {{vm_user}} and type 'startx'"
echo "Firefox (Browser),Geany(Text editor) and other helpful basic graphical applicatiosn have been installed as well."
echo "Please review /var/log/provision.log for any failures and important messages that were generated during provision time."

echo "Thank you for using this automated provisioning system."
echo "Feel free to pop in ##hackers on chat.freenode.net for any questions/support"

#rm /etc/local.d/end_prov.start #remove self
rm /postprov.tar.xz