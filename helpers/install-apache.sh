#!/bin/bash

# First a brief fix for nameservers (this is because instances aren't meant to be in the public subnet!!!)
echo "nameserver 4.2.2.1" > /etc/resolv.conf

# Then install apache, to prove this server is up and userdata functions
apt install apache2 -y
