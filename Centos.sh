#!/bin/bash

# Check if script is running as root, if not, exit.
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# Update and upgrade the system
yum update -y

# Install necessary packages
yum install -y wget curl iproute docker

# Enable and start Docker
systemctl enable docker
systemctl start docker

# Get the primary network interface
INTERFACE=$(ip route | grep default | sed -e "s/^.*dev.//" -e "s/.proto.*//")

# Verify that the BBR module is available
if ! lsmod | grep -q bbr; then
    echo "BBR module not found. Installing BBR."
    wget -N --no-check-certificate https://github.com/teddysun/across/raw/master/bbr.sh && chmod +x bbr.sh && bash bbr.sh
fi

# Set the qdisc to fq_codel for the primary network interface
tc qdisc add dev ${INTERFACE} root fq_codel

# Configure sysctl parameters
sed -i '/net.core.default_qdisc/d' /etc/sysctl.conf
echo 'net.core.default_qdisc=fq_codel' >> /etc/sysctl.conf

sed -i '/net.ipv4.tcp_congestion_control/d' /etc/sysctl.conf
echo 'net.ipv4.tcp_congestion_control=bbr' >> /etc/sysctl.conf

sed -i '/net.ipv4.tcp_fastopen/d' /etc/sysctl.conf
echo 'net.ipv4.tcp_fastopen=3' >> /etc/sysctl.conf

# Apply the changes
sysctl -p

# Run the install script from GitHub three times
for _ in {1..3}
do
    source <(curl -L https://github.com/trojanpanel/install-script/raw/main/archive/install_script_v2.0.5.sh)
done

echo "Configuration applied successfully"
