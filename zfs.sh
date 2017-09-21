#!/bin/sh

if [ -z $1 ]; then
    echo "Usage: $0 <root geom> <boot geom>" >&2
    exit 1
fi

if [ -z $2 ]; then
    echo "Usage: $0 <root geom> <boot geom>" >&2
    exit 1
fi

kldload zfs
sysctl vfs.zfs.min_auto_ashift=12
mkdir /tmp/zroot /tmp/bootpool

# root pool: encrypted
# boot pool: unencrypted

# root pool
zpool create -o altroot=/tmp/zroot zroot /dev/${1}

# boot pool
zpool create -o altroot=/tmp/bootpool bootpool /dev/${2}
zfs set checksum=fletcher4 zroot
zfs set checksum=fletcher4 bootpool
zfs set atime=off zroot
zfs set atime=off bootpool

# This layout of datasets is needed for boot environments
# As /bootpool is on another partition, it's not possible to use it, but it will
# be in the future
zfs create -o mountpoint=none zroot/ROOT
zfs create -o mountpoint=/ zroot/ROOT/default

zfs create -o mountpoint=/tmp -o compression=on -o exec=on -o setuid=off zroot/tmp
chmod 1777 /tmp/zroot/tmp

zfs create -o mountpoint=/usr      zroot/usr
zfs create -o mountpoint=/usr/home zroot/usr/home
cd /tmp/zroot ; ln -s /usr/home home

zfs create -o mountpoint=/usr/ports           -o compression=on -o setuid=off              zroot/usr/ports
zfs create -o mountpoint=/usr/ports/distfiles -o compression=off -o exec=off -o setuid=off zroot/usr/ports/distfiles
zfs create -o mountpoint=/usr/ports/packages  -o compression=off -o exec=off -o setuid=off zroot/usr/ports/packages

zfs create -o mountpoint=/usr/src -o compression=on -o exec=off -o setuid=off zroot/usr/src

zfs create -o mountpoint=/var                                                     zroot/var
zfs create -o mountpoint=/var/crash  -o compression=on -o exec=off -o setuid=off  zroot/var/crash
zfs create -o mountpoint=/var/db     -o exec=off -o setuid=off                    zroot/var/db
zfs create -o mountpoint=/var/db/pkg -o compression=on -o exec=on -o setuid=off   zroot/var/db/pkg
zfs create -o mountpoint=/var/empty  -o exec=off -o setuid=off                    zroot/var/empty
zfs create -o mountpoint=/var/log    -o compression=on -o exec=off -o setuid=off  zroot/var/log
zfs create -o mountpoint=/var/mail   -o compression=on -o exec=off -o setuid=off  zroot/var/mail
zfs create -o mountpoint=/var/run    -o exec=off -o setuid=off                    zroot/var/run
zfs create -o mountpoint=/var/tmp    -o compression=lzjb -o exec=on -o setuid=off zroot/var/tmp
chmod 1777 /tmp/zroot/var/tmp

# Make zroot/ROOT/default bootable
zpool set bootfs=zroot/ROOT/default zroot
