#!/bin/bash

function make_img {
qemu-img create -f {{vm_format}} '{{vm_path}}/{{vm_class}}.{{item}}.img' {{vm_size}}
return $?
}
function shredfile {
shred -fuz -n 5  --random-source=/dev/urandom $1
if [ $? -ge 1 ]
then
exit 1
fi

}
function create_luks {
head -c 1 /dev/random > /dev/null 2>&1 #make sure linux inits urandom entropy before key is created
gpg -d --output {{vm_key_path}}/{{vm_gpg_real_name}}.key --yes {{data_path}}/{{vm_gpg_real_name}}.gpg
/sbin/cryptsetup -q  -c {{vm_crypto_config}} -s {{vm_keysize}} -h {{vm_hash}} --keyfile-size={{vm_keyfile_size}} -d '{{vm_key_path}}/{{vm_gpg_real_name}}.key' luksFormat '{{vm_path}}/{{vm_class}}.{{item}}.img'
ret=$?
shredfile {{vm_key_path}}/{{vm_gpg_real_name}}.key
return $ret
}

function open_luks {
if ! [ -e '/dev/mapper/{{vm_class}}.{{item}}' ]
then
gpg -d --output {{vm_key_path}}/{{vm_gpg_real_name}}.key --yes {{data_path}}/{{vm_gpg_real_name}}.gpg
/sbin/cryptsetup -q  --keyfile-size={{vm_keyfile_size}}  -d '{{vm_key_path}}/{{vm_gpg_real_name}}.key' luksOpen  '{{vm_path}}/{{vm_class}}.{{item}}.img' '{{vm_class}}.{{item}}'
ret=$?
shredfile {{vm_key_path}}/{{vm_gpg_real_name}}.key

return $ret
fi
}

function close_luks {
/sbin/cryptsetup -q  luksClose '{{vm_class}}.{{item}}'
chown -R {{fact_remote_user}} /home/{{fact_remote_user}}
}

function fill_luks {
if ! [ -e '/dev/mapper/{{vm_class}}.{{item}}' ]
then
   echo "Error,Luks volume has not been opened"
else
dd if=/dev/zero of='/dev/mapper/{{vm_class}}.{{item}}' bs=512k
fi

return 0
}

function make_fs {
echo "~~~~~ about to run:mkfs.{{vm_fs}} {{vm_fs_opts}} '/dev/mapper/{{vm_class}}.{{item}}'"

mkfs.{{vm_fs}} {{vm_fs_opts}} '/dev/mapper/{{vm_class}}.{{item}}'
return $?
}


export GNUPGHOME="{{conf_path}}/gnupg/"

make_img

if [ $? -ge 1 ] 
then
  echo "Error making qemu image"
  exit 1
else
  echo "Created qemu image"
fi

create_luks

if [ $? -ge 1 ] 
then
  echo "Error creating encrypted luks volume image"
  exit 1
else
  echo "Created encrypted luks volume image"
fi

open_luks
if [ $? -ge 1 ] 
then
  echo "Error opening luks volume"
  exit 1
else
  echo "Opened luks volume"
fi

fill_luks

if [ $? -ge 1 ] 
then
  echo "Error filling luks volume with all zeros"
  exit 1
else
  echo "Finished filling luks volume with zeroes"
fi

make_fs

if [ $? -ge 1 ] 
then
  echo "Error creating file system"
  exit 1
else
  echo "Created file system"
fi

#close_luks

echo "Finished setting up virtual machine"
