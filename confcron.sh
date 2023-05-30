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
    yum install wget curl -y
fi

# Enable BBR and FQ CODEL
echo "net.core.default_qdisc=fq_codel" >> /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf

# Enable TFO
echo 'net.ipv4.tcp_fastopen=3' >> /etc/sysctl.conf

# Apply the changes
sysctl -p

# Add cron job for reboot
echo "0 0 * * * root /sbin/reboot" >> /etc/crontab

# Print success message
echo "Configuration applied successfully"
