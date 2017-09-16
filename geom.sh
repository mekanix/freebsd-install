#!/bin/sh

if [ -z ${1} ]; then
    echo "Usage: $0 <geom>" >&2
    exit 1
fi

dd if=/dev/zero of=/dev/$1 bs=1M count=10
gpart create -s gpt $1
gpart add -s 200M -t efi                      ${1}
gpart add -s 512k -t freebsd-boot -l boot     ${1}
gpart add -s 1G   -t freebsd-zfs  -l bootpool ${1}
gpart add -s 1G   -t freebsd-swap -l swap     ${1}
gpart add         -t freebsd-zfs  -l disk     ${1}

sysctl kern.geom.debugflags=16
dd if=/boot/boot1.efifat of=/dev/${1}p1 bs=1M
gpart bootcode -b /boot/pmbr -p /boot/gptzfsboot -i 2 $1

dd if=/dev/random of=/tmp/${1}p5.key bs=64 count=1
geli init -s 4096 -K /tmp/${1}p5.key /dev/${1}p5
geli attach -k /tmp/${1}p5.key /dev/${1}p5
geli configure -b /dev/${1}p5
