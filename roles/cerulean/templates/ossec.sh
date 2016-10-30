#!/bin/bash
#Simple script to download,sha256sum check the download ,extract and intsall OSSEC HIDS
INSTALL_LOCATION="{{vm_ossec_location}}"
PUBKEY_URL="https://ossec.github.io/files/OSSEC-PGP-KEY.asc"
OSSEC_URL="https://bintray.com/artifact/download/ossec/ossec-hids/ossec-hids-2.8.3.tar.gz"
GOODSUM='917989e23330d18b0d900e8722392cdbe4f17364a547508742c0fd005a1df7dd'
#set -x
function fetch_ossec(){
#I would gpg check here but OSSEC's current key has expired and they will not renew until the 2.9 release"
wget -q  -O "$(basename $OSSEC_URL)" "$OSSEC_URL" 
sha256sum "$(basename $OSSEC_URL)" | grep -q  "$GOODSUM"
if [ $? -ge 1 ];then
 echo "Error verifying download with sha256sum."
 exit 1
fi

tar -xf "$(basename $OSSEC_URL)" 
if [ $? -ge 1 ]; then
  echo "Error extracting downloaded tarball"
  exit 1
fi
cd "$(basename $OSSEC_URL|sed 's/\(.*\).tar.gz/\1/')"
return $?
}
function run_installer(){
if ! [ -e "$PWD/install.sh" ]; then
  echo "Error, install.sh not found in the current directory $PWD"
  exit 1
fi

echo "Installation in progress. Please stand-by..."

USER_DELETE_DIR="y" \
USER_WHITE_LIST="n" \
USER_ENABLE_FIREWALL_RESPONSE="{{vm_ossec_firewall_response}}" \
USER_ENABLE_SYSLOG="{{vm_ossec_syslog}}" \
USER_ENABLE_ACTIVE_RESPONSE="{{vm_ossec_active_response}}" \
USER_ENABLE_ROOTCHECK="{{vm_ossec_rootkit}}" \
USER_ENABLE_SYSCHECK="{{vm_ossec_syscheck}}" \
USER_DIR="$INSTALL_LOCATION" \
USER_ENABLE_EMAIL="n" \
USER_INSTALL_TYPE="{{vm_ossec_type}}" \
USER_CLEANINSTALL="yes" \
USER_NO_STOP="no" \
USER_LANGUAGE="{{vm_ossec_language}}" \
./install.sh > /tmp/ossec_installation.log 2>&1
if [ $?  -le 0 ]; then
  rm /tmp/ossec_installation.log #in case comilation/installation fails - keep the log.
fi
}

fetch_ossec
if [ $? -ge 1 ]; then
  echo "Error fetching the ossec tar archive"
  exit 1
fi
run_installer

