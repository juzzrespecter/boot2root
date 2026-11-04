#!/bin/bash

set -ue

OVA_FILE=HAL9042.ova
HARD_DISK_VMDK=HAL9042-disk001.vmdk
HARD_DISK_QCOW2=hal9042.qcow2

TAP_IFACE=tap0
IP_SUBNET=10.1.0.1
MASK_SUBNET=28

get_b2r_iso () {
if [ ! -f "$HARD_DISK_QCOW2" ]; then
	echo -n "Setting up boot2root iso ..."
	if [ ! -f "$OVA_FILE" ]; then
		wget -O "$OVA_FILE" "https://cdn.intra.42.fr/isos/HAL9042.ova" 
	fi
	if [ ! -f "$HARD_DISK_VMDK" ]; then
		tar fx "$OVA_FILE"
	fi
	qemu-img convert -p -f vmdk -O qcow2 HAL9042-disk001.vmdk "$HARD_DISK_QCOW2"
	echo " [ok]"
fi
}

set_up_network() {
echo -n "Setting up network ..."
sudo ip tuntap add dev "$TAP_IFACE" mode tap user "$USER"
sudo ip link set "$TAP_IFACE" up
sudo ip addr add "$IP_SUBNET"/"$MASK_SUBNET" dev "$TAP_IFACE"
echo " [ok]"

SUBNET=${IP_SUBNET%.*}
sudo dnsmasq --no-resolv --interface="$TAP_IFACE" --bind-interfaces --dhcp-range="$SUBNET.6","$SUBNET.12",12h
}

get_b2r_iso
if ! ip a show "$TAP_IFACE"; then
	set_up_network
fi
qemu-system-x86_64 -enable-kvm \
	 -m 2G \
	 -drive file="$HARD_DISK_QCOW2",if=virtio \
	 -netdev tap,id=net0,ifname="$TAP_IFACE",script=no,downscript=no \
	 -device e1000,netdev=net0

