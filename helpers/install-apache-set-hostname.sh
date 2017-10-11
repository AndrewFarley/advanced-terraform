#!/bin/bash

# First a brief fix for nameservers (this is because instances aren't meant to be in the public subnet!!!)
echo "nameserver 4.2.2.1" > /etc/resolv.conf

# Set hostname from terraform
OURHOSTNAME="${terraform_hostname}"
echo "$OURHOSTNAME" > /etc/hostname
hostname "$OURHOSTNAME"
echo "$OURHOSTNAME 127.0.0.1" >> /etc/hosts

# Then install apache, to prove this server is up and userdata functions
apt install apache2 -y
