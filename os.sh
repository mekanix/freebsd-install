#!/bin/sh

if [ -z ${1} ]; then
    echo "Usage: $0 <geom>" >&2
    exit 1
fi

if [ -f /usr/freebsd-dist/base.txz ]; then
    cp /usr/freebsd-dist/base.txz /tmp/zroot
    cp /usr/freebsd-dist/kernel.txz /tmp/zroot
else
    fetch http://ftp.freebsd.org/pub/FreeBSD/releases/amd64/11.1-RELEASE/base.txz   -o /tmp/zroot/base.txz
    fetch http://ftp.freebsd.org/pub/FreeBSD/releases/amd64/11.1-RELEASE/kernel.txz -o /tmp/zroot/kernel.txz
fi
cd /tmp/zroot

echo "Extracting base"
tar xf /tmp/zroot/base.txz
echo "Extracting kernel"
tar xf /tmp/zroot/kernel.txz

cat << EOF > /tmp/zroot/etc/fstab
# Device                       Mountpoint              FStype  Options         Dump    Pass#
/dev/gpt/swap                  none                    swap    sw              0       0
EOF

chroot /tmp/zroot passwd
chroot /tmp/zroot tzsetup
chroot /tmp/zroot make -C /etc/mail aliases

mv /tmp/zroot/boot /tmp/bootpool/bootpool/
cd /tmp/zroot
ln -s bootpool/boot
mv /tmp/${1}.key /tmp/bootpool/bootpool/boot/encryption.key

echo 'zfs_enable="YES"' >>/tmp/zroot/etc/rc.conf
echo 'hostname="feebsd1"' >>/tmp/zroot/etc/rc.conf
echo 'ifconfig_vtnet0="DHCP"' >>/tmp/zroot/etc/rc.conf

echo 'aesni_load="YES"' >>/tmp/bootpool/bootpool/boot/loader.conf
echo 'geom_eli_load="YES"' >>/tmp/bootpool/bootpool/boot/loader.conf
echo 'geom_eli_passphrase_prompt="YES"' >>/tmp/bootpool/bootpool/boot/loader.conf
echo 'kern.geom.label.disk_ident.enable="0"' >>/tmp/bootpool/bootpool/boot/loader.conf
echo 'kern.geom.label.gptid.enable="0"' >>/tmp/bootpool/bootpool/boot/loader.conf
echo 'vfs.root.mountfrom="zfs:zroot/ROOT/default"' >>/tmp/bootpool/bootpool/boot/loader.conf
echo 'zfs_load="YES"' >>/tmp/bootpool/bootpool/boot/loader.conf
echo "geli_${1}_keyfile0_load=\"YES\"" >>/tmp/bootpool/bootpool/boot/loader.conf
echo "geli_${1}_keyfile0_name=\"/boot/encryption.key\"" >>/tmp/bootpool/bootpool/boot/loader.conf
echo "geli_${1}_keyfile0_type=\"${1}:geli_keyfile0\"" >>/tmp/bootpool/bootpool/boot/loader.conf

cd /
zfs umount -a
zfs set readonly=on zroot/var/empty
