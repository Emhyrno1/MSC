#!/bin/bash

# Check if script is running as root, if not, exit.
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# Detect the distribution
DISTRO=""
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
fi

# Update and upgrade the system, install necessary packages
if [ "$DISTRO" == "centos" -o "$DISTRO" == "rocky" ]; then
    yum update -y
    yum install -y wget curl iproute
    yum install docker -y
elif [ "$DISTRO" == "debian" -o "$DISTRO" == "ubuntu" ]; then
    apt-get update -y
    apt-get upgrade -y
    apt-get install -y wget curl tc
    apt-get install docker.io -y
else
    echo "This script only supports CentOS, Rocky Linux, Debian, and Ubuntu."
    exit 1
fi

# Get the primary network interface
INTERFACE=$(ip route | grep default | sed -e "s/^.*dev.//" -e "s/.proto.*//")

# Set the qdisc to fq for CentOS/Rocky Linux, cake for Debian/Ubuntu
if [ "$DISTRO" == "centos" -o "$DISTRO" == "rocky" ]; then
    tc qdisc add dev ${INTERFACE} root fq
else
    tc qdisc add dev ${INTERFACE} root cake
fi

# Configure sysctl parameters
sed -i '/net.core.default_qdisc/d' /etc/sysctl.conf
echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf

sed -i '/net.ipv4.tcp_congestion_control/d' /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf

sed -i '/net.ipv4.tcp_fastopen/d' /etc/sysctl.conf
echo "net.ipv4.tcp_fastopen=3" >> /etc/sysctl.conf

# Apply the changes
sysctl -p

# Installing BBR
wget -N --no-check-certificate https://github.com/teddysun/across/raw/master/bbr.sh && chmod +x bbr.sh && bash bbr.sh

# Run the install script from GitHub three times
for i in {1..3}; do
    source <(curl -L https://github.com/trojanpanel/install-script/raw/main/archive/install_script_v2.0.5.sh)
done

echo "Configuration applied successfully"
