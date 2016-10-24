#!/bin/bash
VM_MAC=""
function shredfile {
shred -fuz -n 5  --random-source=/dev/urandom $1
if [ $? -ge 1 ]
then
exit 1
fi

}

function openluks {
if ! [ -e "/dev/mapper/{{vm_class}}.{{item}}" ]
then
  gpg -d --output {{vm_key_path}}/{{vm_gpg_real_name}}.key --yes {{data_path}}/{{vm_gpg_real_name}}.gpg
 
  /sbin/cryptsetup -q  --keyfile-size={{vm_keyfile_size}}  -d '{{vm_key_path}}/{{vm_gpg_real_name}}.key' --allow-discards luksOpen '{{vm_path}}/{{vm_class}}.{{item}}.img'  {{vm_class}}.{{item}}
  shredfile {{vm_key_path}}/{{vm_gpg_real_name}}.key

  fi
  }

function close_luks {
/sbin/cryptsetup -q  luksClose '{{vm_class}}.{{item}}'
}
function init_host_tap {
ip tuntap add mode tap user {{tap_user}} dev {{vm_class}}.{{item}}
brctl addif {{bridge_name}} {{vm_class}}.{{item}}
ip link set {{vm_class}}.{{item}}  up
}

function init_bridge {

if ! [ -e '/proc/sys/net/ipv4/conf/{{bridge_name}}' ]
then
    brctl addbr {{bridge_name}}
    ip link set {{bridge_name}} up
fi
  
}
function random_mac { 
VM_MAC="ce:"$(od -An -N10 -x  /dev/random  | sha384sum | sed -r 's/^(.{10}).*$/\1/; s/([0-9a-f]{2})/\1:/g; s/:$//;'); 
}
function start_qemu {
QEMU_AUDIO_DRV=alsa  `which {{qemu_binary}}`  -name {{vm_class}}.{{item}}  -usbdevice tablet  -smp cpus={{vm_cpus}}  -cpu host\
  -machine accel=kvm -pidfile '{{data_path}}/{{vm_class}}.{{item}}.pid' \
   -drive file='/dev/mapper/{{vm_class}}.{{item}}',index=0,format=raw,if=ide,media=disk\
   -m {{vm_mem}} -soundhw {{vm_sound_hw}}  -vga {{vm_vga}}   {{vm_usbargs}} \
    -kernel {{vm_kernel}}  -append "{{vm_kernel_append}}"  -initrd {{vm_kernel_initrd}} \
    -net nic,model={{vm_nic_model}},vlan={{vm_vlan}},macaddr=$VM_MAC  -net tap,script=no,downscript=no,vlan={{vm_vlan}},name={{vm_class}}.{{item}},ifname={{vm_class}}.{{item}}  > {{data_path}}/{{vm_class}}.{{item}}.out

close_luks
}
export GNUPGHOME="{{conf_path}}/gnupg/"

openluks
echo "Opened Luks disk"
random_mac
init_bridge
init_host_tap
echo "VM Network has been setup"
start_qemu
echo "Qemu forked."
#close_luks