#!/bin/bash

useradd -m "demo"
echo "demo:123" | chpasswd
usermod -aG sudo "demo"
echo "AllowUsers demo ubuntu" >> /etc/ssh/sshd_config
#echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config
sed -i "s/^.*PasswordAuthentication no.*/# &/" "/etc/ssh/sshd_config.d/60-cloudimg-settings.conf"
echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config.d/60-cloudimg-settings.conf
systemctl restart ssh


set -e
apt-get update -y
apt-get install -y nginx
systemctl enable nginx
systemctl start nginx
echo "Deployed via Terraform at $(date)" > /var/www/html/index.html
