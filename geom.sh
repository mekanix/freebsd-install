#!/bin/sh

if [ -z ${1} ]; then
    echo "Usage: $0 <geom>" >&2
    exit 1
fi

dd if=/dev/zero of=/dev/$1 bs=1M count=10
gpart create -s gpt $1

# labels (-l switch) will create /dev/gpt/<label> device files
gpart add -s 200M -t efi                      ${1} # p1
gpart add -s 512k -t freebsd-boot -l boot     ${1} # p2
gpart add -s 1G   -t freebsd-zfs  -l bootpool ${1} # p3 -> /bootpool
gpart add -s 1G   -t freebsd-swap -l swap     ${1} # p4
gpart add         -t freebsd-zfs  -l disk     ${1} # p5 -> GELI encrypted /

# Let's you write the boot loader
sysctl kern.geom.debugflags=16

# Populate EFI partition (p1 in our case)
dd if=/boot/boot1.efifat of=/dev/${1}p1 bs=1M

# Install the boot loader
gpart bootcode -b /boot/pmbr -p /boot/gptzfsboot -i 2 $1

# Generate 512-bit of randomness
# It will be used as master key
dd if=/dev/random of=/tmp/${1}p5.key bs=64 count=1

# Initialize the GELI on p5 (ZFS partition) using our master key
geli init -s 4096 -K /tmp/${1}p5.key /dev/${1}p5

# Attach the newly created GELI partition
# It will create /dev/${1}p5.eli
geli attach -k /tmp/${1}p5.key /dev/${1}p5

# This tells the kernel which partition to try to decrypt before init
geli configure -b /dev/${1}p5
