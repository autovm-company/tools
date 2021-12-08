#!/bin/bash

# FIND DETAILS
details=$(cat /etc/os-release)

# FIND DIST
dist=$(echo "$details" | grep ^ID= | grep -Eo [a-z]+)

# FIND VERSION
version=$(echo "$details" | grep ^VERSION= | grep -Eo [0-9]+ | head -n 1)

# FIND NAME
name=$(ls /sys/class/net | head -n 1)

# NETMASK SCRIPT
cat <<EOF > /etc/cidr.py

import argparse

parser = argparse.ArgumentParser()
parser.add_argument('netmask')
args = parser.parse_args()

cidr = 0

for bits in args.netmask.split('.'):

    bits = bin(int(bits)).count('1')

    cidr = cidr + bits

print(cidr)

EOF

# UBUNTU
function ubuntuIP {

cat <<EOF > /etc/network/interfaces
auto lo
iface lo inet loopback
auto $name
iface $name inet static
address @address
netmask @netmask
gateway @gateway
dns-nameservers 4.2.2.4 8.8.4.4
EOF

# START
ifup $name

}

# UBUNTU
function ubuntuIPWithRoute {

cat <<EOF > /etc/network/interfaces
auto lo
iface lo inet loopback
auto $name
iface $name inet static
address @address
netmask @netmask
broadcast @address
post-up route add @gateway dev $name
post-up route add default gw @gateway
pre-down route del @gateway dev $name
pre-down route del default gw @gateway
dns-nameservers 4.2.2.4 8.8.4.4
EOF

# START
ifup $name

}

# DEBIAN
function debianIP {

cat <<EOF > /etc/network/interfaces
auto lo
iface lo inet loopback
auto $name
iface $name inet static
address @address
netmask @netmask
gateway @gateway
dns-nameservers 4.2.2.4 8.8.4.4
EOF

# START
ifup $name

}

# DEBIAN
function debianIPWithRoute {

cat <<EOF > /etc/network/interfaces
auto lo
iface lo inet loopback
auto $name
iface $name inet static
address @address
netmask @netmask
broadcast @address
post-up route add @gateway dev $name
post-up route add default gw @gateway
pre-down route del @gateway dev $name
pre-down route del default gw @gateway
dns-nameservers 4.2.2.4 8.8.4.4
EOF

# START
ifup $name

}

# CENTOS
function centosIP {

cat <<EOF > /etc/sysconfig/network-scripts/ifcfg-$name
DEVICE=$name
TYPE=Ethernet
IPADDR=@address
NETMASK=@netmask
GATEWAY=@gateway
ONBOOT=YES
DNS1=4.2.2.4
DNS2=8.8.4.4
EOF

# START
ifup $name

}

# NETMASK TO CIDR
if which python3; then

    cidr=$(python3 /etc/cidr.py @netmask)
else

    cidr=$(python /etc/cidr.py @netmask)
fi

# NETPLAN
function netplanIP {

cat <<EOF > /etc/netplan/config.yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    $name:
      addresses: [@address/$cidr]
      gateway4: @gateway
      dhcp4: no
      nameservers:
        addresses: [4.2.2.4, 8.8.4.4]
EOF

# START
netplan apply

}

# NETPLAN
function netplanIPWithRoute {

cat <<EOF > /etc/netplan/config.yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    $name:
      addresses: [@address/$cidr]
      gateway4: @gateway
      dhcp4: no
      nameservers:
        addresses: [4.2.2.4, 8.8.4.4]
      routes:
      - to: @gateway/$cidr
        via: 0.0.0.0
        scope: link
EOF

# START
netplan apply

}

# NETPLAN
if [ -d /etc/netplan ]; then

    if [ $cidr == 32 ]; then
        netplanIPWithRoute
    else
        netplanIP
    fi
else

    # UBUNTU
    if [ "$dist" == ubuntu ]; then

        if [ $cidr == 32 ]; then
            ubuntuIPWithRoute
        else
            ubuntuIP
        fi
    fi

    # DEBIAN
    if [ "$dist" == debian ]; then

        if [ $version == 8 ]; then

            if [ $cidr == 32 ]; then
                debianIPWithRoute
            else
                debianIP
            fi
        else
            debianIP
        fi
    fi

    # CENTOS
    if [ "$dist" == centos ]; then

        centosIP
    fi

    # ALMA
    if [ "$dist" == almalinux ]; then

        centosIP
    fi

    # ROCKY
    if [ "$dist" == rocky ]; then

        centosIP
    fi
fi

# RESIZE PARTITION
(echo d; echo n; echo p; echo ; echo ; echo ; echo w; echo n; echo w) | fdisk /dev/sda

# RESIZE FILESYSTEM
partprobe && resize2fs /dev/sda1

# LOGIN BY PASSWORD
(echo @password; echo @password) | passwd @username

# LOGIN BY RSA
if [ ! -z "@publicKey" ]; then

  # RSA PUBLIC KEY
  mkdir -p $HOME/.ssh && echo "@publicKey" > $HOME/.ssh/authorized_keys
fi

# DELETE FILE
rm /home/setup.sh
