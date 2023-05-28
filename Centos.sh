#!/bin/bash

# Check if script is running as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# Update and upgrade the system
yum update -y

# Install required packages
yum install -y wget curl tc iptables-services

# Install Docker
yum install -y yum-utils
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum install -y docker-ce docker-ce-cli containerd.io
systemctl start docker
systemctl enable docker

# Get the primary network interface
INTERFACE=$(ip route | grep default | sed -e "s/^.*dev.//" -e "s/.proto.*//")

# Set the qdisc to fq_codel for the primary network interface
tc qdisc add dev ${INTERFACE} root fq_codel

# Configure sysctl parameters
sed -i '/net.core.default_qdisc/d' /etc/sysctl.conf
echo 'net.core.default_qdisc=fq_codel' >> /etc/sysctl.conf

sed -i '/net.ipv4.tcp_congestion_control/d' /etc/sysctl.conf
echo 'net.ipv4.tcp_congestion_control=bbr' >> /etc/sysctl.conf

sed -i '/net.ipv4.tcp_fastopen/d' /etc/sysctl.conf
echo 'net.ipv4.tcp_fastopen=3' >> /etc/sysctl.conf

# Install BBR
wget -N --no-check-certificate https://github.com/teddysun/across/raw/master/bbr.sh
chmod +x bbr.sh
bash bbr.sh

# Apply the changes
sysctl -p

# Run the install script from GitHub three times
for i in 1 2 3
do
    source <(curl -L https://github.com/trojanpanel/install-script/raw/main/archive/install_script_v2.0.5.sh)
done

echo "Configuration applied successfully"
