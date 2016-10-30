#!/bin/bash
## A very simple script to fetch grsec patch and the linux vanilla kernel corresponding to the grsec patch.
## it proceeds to verify the download with gpg,extract it,apply the patch,configure the kernel and build it.
## note that  a '.config' file pertaining to the kernel configuration options of your liking needs to be present
## in the same directory as this script. due to the use of olddefconfig, if the new kernel has new options,
## they will be set to their defaults.
##
## This script is very "rough on the edges" ,it's not meant to be fancy or impressive,it's very simple an does the job
## Fairly well enough (at least for now).
## @copyleft terabit
########################################################################################################################

KVER=""
URL_PATCH=""
URL_KERNEL=""
URL_KERNEL_SIGN=""
ARCH="x86_64"
INSTALL_DIR="{{kernel_path}}"
WORK_DIR="{{kernel_path}}"
J="{{ansible_processor_cores}}"

function die {
if [ "$1" -ge 1 ]
then
  echo "$2"
  exit "$1"
fi
}
function fetch_grsec {
wget -q -O "$LATEST" "$URL_PATCH"
die $? "Failed fetching grsec test patch"
wget -q -O "$LATEST.sig" "$URL_PATCH.sig"
die $? "Failed fetching grsec signature"

gpg --keyid-format=0xlong --fetch 'https://pgp.mit.edu/pks/lookup?op=get&search=0xDE9452CE46F42094907F108B44D1C0F82525FE49'
die $? "Failed  Importing Grsec signing public key"

gpg --verify "$LATEST.sig"  "$LATEST"
die $? "FATAL ERROR: GPG verification of the grsec patch failed,either the download failed or someone is doing something nasty...."


}

function fetch_kernel {
wget -q -O "linux-$KVER.tar.xz" "$URL_KERNEL"
die $? "Failed fetching kernel tarball"

wget -q -O "linux-$KVER.tar.sign"  "$URL_KERNEL_SIGN"
die $? "Failed fetching kernel tarball signature"

unxz -f "linux-$KVER.tar.xz"
die $? "Failed extracting the kernel"

gpg --keyid-format=0xlong --fetch 'https://pgp.mit.edu/pks/lookup?op=get&search=0x647F28654894E3BD457199BE38DBBDC86092693E'
die $? "Failed fetching public key from a keyserver."

gpg --verify "linux-$KVER.tar.sign"
die $? "FATAL ERROR: Kernel tarball GPG verification has failed, aborting. Either the download failed or somone is doing something nasty..."

tar -xf "linux-$KVER.tar"
die $? "Error extracting the already verified kernel tarball...this is weird."

}

function patch_kernel {

cd "linux-$KVER"
patch -p1 < "../$LATEST" > /dev/null
cd ..

}

function make_kernel {
cd "linux-$KVER" && cp "../.config" ./
die $? "Error changing directories or copying preloaded kernelconfig"

make olddefconfig
die $? "Error applying preloaded kernel configuration"

make -j$J > ../buildoutput 2>&1
die $? "Error  building the kernel"
INSTALL_MOD_PATH="$INSTALL_DIR" make -j$J modules_install >> ../buildoutput 2>&1
die $? "Error installing kernel modules"
INSTALL_HDR_PATH="$INSTALL_DIR/usr/" make -j$J headers_install >> ../buildoutput 2>&1 
cp "arch/$ARCH/boot/bzImage" "$INSTALL_DIR/kernel_grsec_latest"
die $? "Error copying kernel image to the installation directory"

cd .. && rm -rf grsecurity* && linux-*
sha512sum "$INSTALL_DIR/kernel_grsec_latest" > "$INSTALL_DIR/kernel_grsec_latest.sha512" &&
echo "KERNEL_BUILD_FINISHED" >> buildoutput
return 0
}


##  "main" 


LATEST=$(curl -sS https://grsecurity.net/latest_test_patch)
KVER=$(echo $LATEST| sed -nr 's/^grsecurity-[0-9]\.1-(.*)-.*\.patch/\1/p')
URL_PATCH="https://grsecurity.net/test/$LATEST"
URL_KERNEL="https://cdn.kernel.org/pub/linux/kernel/v4.x/linux-$KVER.tar.xz"
URL_KERNEL_SIGN="https://cdn.kernel.org/pub/linux/kernel/v4.x/linux-$KVER.tar.sign"

if ! [ -e "$WORK_DIR" ];
then 
  mkdir -p "$WORK_DIR"
  die $? "Unable to create working directory"
fi
cd "$WORK_DIR"
if  [ "$(sha512sum -c $INSTALL_DIR/kernel_grsec_latest.sha512)" ]
then
echo "KERNEL_CHECKSUM_MATCH<->SKIPPING_BUILD"
exit
fi
fetch_grsec &&
fetch_kernel &&
patch_kernel &&
make_kernel
