# Hardened gentoo automated provision

This is still under development but it does work to a certain degree.

This ansible playbook and accompanying scripts will ssh into a machine and configure a hardend-gentoo qemu/kvm virtual-machine. 

It will use the variables under `roles/cerulean/vars/main.yaml`  and the kernel configuration under r`oles/cerulean/files/kernel_config` to:
 

 - Create an encrypted virtual machine disk ( you will need to store your keyring off the host when not in use,for good security).
 - Configure and install gentoo -hardend into a temporary chroot directory, it will then create  a stage4 archive of the install and deploy it on every Virtual-Machine's encrypted disk.
 -  During the previous step it should also have extracted an archive (`roles/cerulean/files/postprov.tar.xz`) containing configurations needed to make the sytem work as desired and add basic init services. 


Right now the network configuration is a bit iffy but it works fine for me, you can adjust static IP network configuration per host in he `hosts` file. After this script is finished, it should have deployed a basic virtual  machine with hardened configurations, Grsec/pax (You'll have to configure your own rbac policies).

It also deploys the virtual machines with basic tools needed to secure and audit the system:

- Anti-malware - clamav(unofficial signatures included)
- System auditing - lynis acct audit sysstat aide glsa-check(for gentoo linux security advisory checking of the system)
- Rootkit and malicious file detection- rkhunter chkrootkit 
- Network monitoring and security -  arpon    tcpdump tcpdump mtr traceroute whois
- Password manager and generators -  pass passook pwgen 
- Graphical enviornment - X11,awesome (window manager),Firefox 

#Requirements and usage

The target host should be a hardware server (not a VM). it needs to have qemu properly installed and configured,support KVM and allow chroot'ing. You will also need to now the root password of target host (for obvious reasons). 

Usage: 

    ansible-playbook -i hosts -kK  main.yml 

Add -vvv to see a more detailed output. this will take many hours as you can imagine but that's mostly there is to it.
#Todo

- OSSEC (HIDS/HIPS) automated deployment and configuration
- Manage browser configuration and profiles during provision 
- Automate initial audit and pass/fail system based on test results
- backup existing VM images before overwriting them (in case the provision fails)
- Port the current role (cerulean) to a baremetal deployment role.This will require a separate script(s) to start a pxe server boot a live environment over PXE.
- Lots of clean up , there are more than a few "hacky" configurations and scripts that should be improved and cleaned up.
- Testing, would be nice if others help test this.  