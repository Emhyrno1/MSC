#!/bin/bash

# Check if script is running as root, if not, exit.
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# Update and upgrade the system
apt-get update && apt-get upgrade -y

# Get the primary network interface
INTERFACE=$(ip route | grep default | sed -e "s/^.*dev.//" -e "s/.proto.*//")

# Verify that the BBR module is available
if ! lsmod | grep -q bbr; then
    echo "BBR module not found. Please upgrade your kernel or enable BBR."
    exit 1
fi

# Set the qdisc to cake for the primary network interface
tc qdisc add dev ${INTERFACE} root cake

# Configure sysctl parameters
sed -i '/net.core.default_qdisc/d' /etc/sysctl.conf
echo 'net.core.default_qdisc=cake' >> /etc/sysctl.conf

sed -i '/net.ipv4.tcp_congestion_control/d' /etc/sysctl.conf
echo 'net.ipv4.tcp_congestion_control=bbr' >> /etc/sysctl.conf

sed -i '/net.ipv4.tcp_fastopen/d' /etc/sysctl.conf
echo 'net.ipv4.tcp_fastopen=3' >> /etc/sysctl.conf

# Apply the changes
sysctl -p

echo "Configuration applied successfully"
