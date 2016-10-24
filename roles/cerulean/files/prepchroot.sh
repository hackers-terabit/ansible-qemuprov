#!/bin/bash
#meh keep it simple,why not ? :P

mount --rbind /dev $1/dev
mount --rbind /proc $1/proc
mount --rbind /sys $1/sys
cp /etc/resolv.conf $1/resolv.conf
cp /etc/mtab $1/mtab
