#!/bin/bash

# Install necessary dependencies and set up fq_codel, bbr, and tfo
# Add a cron job to reboot every day at 00:00 UTC

DISTRO=$(awk -F= '/^NAME/{print $2}' /etc/os-release)

if [[ "$DISTRO" == *"CentOS"* ]] || [[ "$DISTRO" == *"Rocky Linux"* ]] || [[ "$DISTRO" == *"Red Hat"* ]]; then
    yum install -y epel-release
    yum install -y curl wget iproute-tc
    INTERFACE=$(ip route | awk '/default/ { print $5 }')
    sed -i '/net.core.default_qdisc/d' /etc/sysctl.conf
    echo "net.core.default_qdisc=fq_codel" >> /etc/sysctl.conf
    sed -i '/net.ipv4.tcp_congestion_control/d' /etc/sysctl.conf
    echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
    sed -i '/net.ipv4.tcp_fastopen/d' /etc/sysctl.conf
    echo "net.ipv4.tcp_fastopen=3" >> /etc/sysctl.conf
    sysctl -p
    echo "0 0 * * * root /sbin/reboot" >> /etc/crontab
elif [[ "$DISTRO" == *"Debian"* ]] || [[ "$DISTRO" == *"Ubuntu"* ]]; then
    apt-get update
    apt-get install -y curl wget iproute2
    INTERFACE=$(ip route | awk '/default/ { print $5 }')
    sed -i '/net.core.default_qdisc/d' /etc/sysctl.conf
    echo "net.core.default_qdisc=fq_codel" >> /etc/sysctl.conf
    sed -i '/net.ipv4.tcp_congestion_control/d' /etc/sysctl.conf
    echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
    sed -i '/net.ipv4.tcp_fastopen/d' /etc/sysctl.conf
    echo "net.ipv4.tcp_fastopen=3" >> /etc/sysctl.conf
    sysctl -p
    echo "0 0 * * * root /sbin/reboot" >> /etc/crontab
fi
