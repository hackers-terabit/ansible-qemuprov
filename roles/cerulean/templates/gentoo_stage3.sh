#!/bin/bash
## copyleft @terabit
#set -x
MIRROR_PATH="https://lug.mtu.edu/gentoo/"
STAGE3_PATH=""
AUTO_BUILD_PATH="releases/amd64/autobuilds/"
LATEST_PATH="$AUTO_BUILD_PATH/latest-stage3-amd64-hardened.txt"
STAGE3_BASE=""
PORTAGE_URL="https://cosmos.illinois.edu//pub/gentoo/snapshots/portage-latest.tar.bz2"
PORTAGE_BASE=""
INSTALL_DIR="./work"
WORK="{{work_path}}"

function die {
if [ "$1" -ge 1 ]
then
  echo "$2"
  exit "$1"
fi
}

function download_install_files {
gpg --keyid-format=0xlong --keyserver hkps://pgp.mit.edu --recv  '0x13EBBDBEDE7A12775DFDB1BABB572E0E2D182910'
die $? "Error recieving gpg keys from the key server"
gpg --keyid-format=0xlong --keyserver hkps://pgp.mit.edu --recv '0xDCD05B71EAB94199527F44ACDB6B8C1F96D8BF6D'
die $? "Error recieving portage snapshot signing keys" 
if ! [ -e "$STAGE3_BASE" ] 
then
wget -O "$STAGE3_BASE" "$STAGE3_PATH"
die $? "Error downloading stage3"
wget -O "$STAGE3_BASE.CONTENTS" "$STAGE3_PATH.CONTENTS"
die $? "Error downloading .CONTENTS file that contains a list of all files inside the stage tarball"
wget -O "$STAGE3_BASE.DIGESTS" "$STAGE3_PATH.DIGESTS"
die $? "Error downloading DIGESTS file that contains checksums of the stage file, in different algorithms"
wget -O "$STAGE3_BASE.DIGESTS.asc" "$STAGE3_PATH.DIGESTS.asc"
die $? "Error downloading DIGESTS.asc file that, like the .DIGESTS file, contains checksums of the stage file in different algorithms, but is also cryptographically signed to ensure it is provided by the Gentoo project"
fi

out="$(gpg --status-fd 2  --verify $STAGE3_BASE.DIGESTS.asc 2>&1|grep 'VALID\|GOODSIG')" && 
echo $out |  grep -E 'GOODSIG BB572E0E2D182910.*VALIDSIG 13EBBDBEDE7A12775DFDB1BABB572E0E2D182910'
die $? "Error verifying DIGESTS.asc with gpg"

grep --no-group-separator -A1 SHA512 "$STAGE3_BASE.DIGESTS.asc" > "$STAGE3_BASE.DIGESTS.asc.sha512"
die $? "Error grepping .asc file"
sha512sum -c "$STAGE3_BASE.DIGESTS.asc.sha512"
die $? "FATAL ERROR: stage3 tarball hash verification failed aborting immediately."
if ! [ -e "$PORTAGE_BASE" ]
then
wget -O "$PORTAGE_BASE" "$PORTAGE_URL"
die $? "Error fetching portage tarball"
wget -O "$PORTAGE_BASE.gpgsig" "$PORTAGE_URL.gpgsig"
die $? "Error fetching portage tarball gpg signature."
wget -O "$PORTAGE_BASE.md5sum" "$PORTAGE_URL.md5sum"
die $? "Error fetching md5sum for portage tarball"
fi
out="$(gpg --status-fd 2  --verify $PORTAGE_BASE.gpgsig $PORTAGE_BASE 2>&1|grep 'VALID\|GOODSIG' )" &&
echo $out | grep -E  'EC590EEAC9189250.*E1D6ABB63BFCFB4BA02FDF1CEC590EEAC9189250'
die $? "Error verifying portage snapshot with gpg"

md5sum -c "$PORTAGE_BASE.md5sum"
die $? "Error verifying portage snapshot with md5"

}


function extract_install_files {
echo "Extracting installation files.."
if ! [ -e "$INSTALL_DIR" ] 
then 
  echo "Installation directory needs to exist before this script is run,exiting" #need to mount it before running this
  exit 1
fi

tar -C "$INSTALL_DIR" -xf "$STAGE3_BASE"
die $? "Error extracting stage3 tarball"

tar -C "$INSTALL_DIR/usr/" -xf "$PORTAGE_BASE"
die $? "Error extracting portage snapshot tarball"
}


STAGE3_PATH="$MIRROR_PATH/$AUTO_BUILD_PATH/$(curl -LsS "$MIRROR_PATH/$LATEST_PATH" | grep -v '#' | awk '{print $1}')"
STAGE3_BASE=$(basename "$STAGE3_PATH")
PORTAGE_BASE=$(basename "$PORTAGE_URL")
## "main"
if [ $# -le 0 ] 
then 
echo "Usage: $0 <installation directory>"
exit 1
fi


INSTALL_DIR="$1"
cd $WORK &&
download_install_files &&
extract_install_files
