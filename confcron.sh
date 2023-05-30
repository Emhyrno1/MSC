#!/bin/bash

# Check if the script is running as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

# Get OS type
OS="`cat /etc/*-release | grep '^NAME=' | sed 's/NAME="//g' | sed 's/"//g' | awk '{print $1}'`"

# Update and upgrade the system
if [ "$OS" == "Debian" ] || [ "$OS" == "Ubuntu" ]; then
    apt-get update && apt-get upgrade -y
    apt-get install wget curl iproute2 -y
elif [ "$OS" == "CentOS" ] || [ "$OS" == "Rocky" ]; then
    yum update -y
    yum install wget curl cronie -y
    systemctl start crond && systemctl enable crond
fi

# Enable BBR, FQ_CODEL, and TFO
if grep -q "net.core.default_qdisc" /etc/sysctl.conf; then
    sed -i 's/^net.core.default_qdisc=.*/net.core.default_qdisc=fq_codel/' /etc/sysctl.conf
else
    echo "net.core.default_qdisc=fq_codel" >> /etc/sysctl.conf
fi

if grep -q "net.ipv4.tcp_congestion_control" /etc/sysctl.conf; then
    sed -i 's/^net.ipv4.tcp_congestion_control=.*/net.ipv4.tcp_congestion_control=bbr/' /etc/sysctl.conf
else
    echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
fi

if grep -q 'net.ipv4.tcp_fastopen' /etc/sysctl.conf; then
    sed -i 's/^net.ipv4.tcp_fastopen=.*/net.ipv4.tcp_fastopen=3/' /etc/sysctl.conf
else
    echo 'net.ipv4.tcp_fastopen=3' >> /etc/sysctl.conf
fi

# Apply the changes
sysctl -p

# Add cron job for reboot if it does not already exist
if ! crontab -l | grep -q "/sbin/reboot"; then
    echo "0 0 * * * /sbin/reboot" | crontab -
fi

# Print success message
echo "Configuration applied successfully"
