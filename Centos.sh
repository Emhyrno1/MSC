#!/bin/bash

# Check if script is running as root, if not, exit.
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# Update the system and install necessary packages
yum update -y
yum install wget curl -y
yum install epel-release -y
yum install iproute -y
yum install docker -y

# Start docker service
systemctl start docker

# Enable docker service
systemctl enable docker

# Get the primary network interface
INTERFACE=$(ip route | grep default | sed -e "s/^.*dev.//" -e "s/.proto.*//")

# Check if fq_codel is available and if it is, set it
if tc qdisc add dev ${INTERFACE} root fq_codel 2>/dev/null; then
    echo "Successfully set qdisc to fq_codel"
else
    echo "fq_codel not available, skipping setting qdisc"
fi

# Install BBR
wget --no-check-certificate https://github.com/teddysun/across/raw/master/bbr.sh && chmod +x bbr.sh && bash bbr.sh

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
for i in {1..3}
do
    source <(curl -L https://github.com/trojanpanel/install-script/raw/main/archive/install_script_v2.0.5.sh)
done

echo "Configuration applied successfully"
