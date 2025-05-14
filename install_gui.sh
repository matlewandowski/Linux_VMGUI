#!/bin/bash

# Update package list and upgrade packages
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y xfce4 xrdp

# Set up .xsession file to start Xfce
echo "startxfce4" > /home/testuser1/.xsession

# Ensure correct ownership of .xsession
chown testuser1:testuser1 /home/testuser1/.xsession

# Add user to the ssl-cert group for xrdp to work
sudo adduser testuser1 ssl-cert

# Enable and start xrdp service
sudo systemctl enable xrdp
sudo systemctl start xrdp

# Restart xrdp to apply the new session configuration
sudo systemctl restart xrdp
