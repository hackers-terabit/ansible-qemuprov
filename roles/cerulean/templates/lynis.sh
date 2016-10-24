#!/bin/bash
LYNIS_DOWNLOAD="https://cisofy.com/files/lynis-2.3.4.tar.gz"
LYNIS_DOWNLOAD_SIG="https://cisofy.com/files/lynis-2.3.4.tar.gz.asc"
function die {
if [ "$1" -ge 1 ]
then
  echo "$2"
  exit "$1"
fi
}

function download_and_verify {
gpg --keyid-format=0xlong --keyserver hkps://hkps.pool.sks-keyservers.net  --recv '0x429A566FD5B79251' > /dev/null
die $? "Error importing CISOfy signing key"

wget -q -O 'lynis.tar.gz' "$LYNIS_DOWNLOAD" > /dev/null && 
wget -q -O 'lynis.tar.gz.asc' "$LYNIS_DOWNLOAD_SIG"  > /dev/null
die $? "Error fetching Lynis or it's signing key"

out="$(gpg --status-fd 2  --verify lynis.tar.gz.asc 2>&1 |grep 'VALID\|GOODSIG')" &&
echo $out | grep -E 'GOODSIG 429A566FD5B79251 CISOfy.*VALIDSIG 73AC9FC55848E977024D1A61429A566FD5B79251' > /dev/null
die $? 'Critical Error. unable to verify the downloaded lynis tar archive'

}

function extract_and_run {
tar -xf 'lynis.tar.gz' && cd lynis &&
./lynis audit system --verbose 
}
download_and_verify
extract_and_run
