#/bin/bash
GPG_CONF={{conf_path}}/gpg-gen.conf
function print_usage_and_exit {
echo "Usage:"
echo "$0 init /path/publicsigningkey.pub"
echo "$0 import /path/newpublickey.pub"
echo "$0 keygen /key/path/ recipient"
echo "$0 delpub \"real name\""

exit	
}
function gpg_remove_allpub {
echo "delpub $@"
while $(gpg --list-keys 2>&1 | grep -sq "$2");
   do
    gpg --yes --batch --delete-key "$2";
   done
}

function make_key {
echo "make key $@"
if [ $# -le 2 ]
then
  print_usage_and_exit
fi

head -c 1 /dev/random > /dev/null 2>&1
RND="$2/${3}.key"
if [ -e "$RND" ]
then 
shred -fuzv -n 5 -s 2k --random-source=/dev/urandom "$RND"
fi

if [ -e "$RND.gpg" ]
then
  shred -fuzv -n 5 -s 2k --random-source=/dev/urandom "$RND.gpg"
fi

dd bs={{vm_keyfile_size}}  count=1 if=/dev/urandom of="$RND"
gpg --trust-model always -e --output "$RND.gpg" -u "{{vm_gpg_real_name}}" -r "$3" "$RND"
shred -fuzv -n 5 -s 2k --random-source=/dev/urandom "$RND"
return $?
}

function gpg_import {
echo "gpg_import $@"
gpg --import "$2"
return $?
}

function gpg_init {
echo "gpg_init $@"

gpg --list-keys  {{vm_gpg_real_name}} > /dev/null 2>&1

if [ $? -ge 1 ]
then
  echo "No key found for {{vm_gpg_real_name}}, Creating new one based on $GPG_CONF"
  head -c 1 /dev/random > /dev/null 2>&1
  gpg --batch --gen-key "$GPG_CONF"
else
  echo "GPG key found for {{vm_gpg_real_name}}, Nothing to init"
fi
  gpg --export -a "{{vm_gpg_real_name}}" > $2
return $?
}

##################
export GNUPGHOME="{{conf_path}}/gnupg/"

if [ $# -le 1 ]
then
   print_usage_and_exit
fi

case $1 in 
  init)
      gpg_init $@ ;;
  import)
      gpg_import $@ ;;
  keygen)
      make_key "$@" ;;
  delpub)
      gpg_remove_allpub "$@" ;;
  *)
      print_usage_and_exit ;;
esac

