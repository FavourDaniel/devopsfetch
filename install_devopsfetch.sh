#!/bin/bash

# Installation script for devopsfetch


# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root"
    exit 1
fi


# Install dependencies
apt-get update
apt-get install -y lsof jq docker.io nginx


# Create the log file and set permissions
touch /var/log/devopsfetch.log
chmod 644 /var/log/devopsfetch.log


# Copy devopsfetch script to /usr/local/bin
cp devopsfetch.sh /usr/local/bin/
chmod +x /usr/local/bin/devopsfetch.sh


# Create a systemd service file
cat << EOF > /etc/systemd/system/devopsfetch.service
[Unit]
Description=DevOpsFetch Continuous Monitoring
After=network.target

[Service]
ExecStart=/usr/local/bin/devopsfetch -t now now
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd, enable and start the service
systemctl daemon-reload
systemctl enable devopsfetch.service
systemctl start devopsfetch.service

# Set up log rotation
cat << EOF > /etc/logrotate.d/devopsfetch
/var/log/devopsfetch.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 644 root root
    postrotate
        systemctl reload devopsfetch.service > dev/null 2> /dev/null || true
    endscript
}
EOF

echo "DevOpsFetch has been installed and configured."
echo "The continuous monitoring service is now running."
echo "Logs are being written to /var/log/devopsfetch.log"
echo "Log rotation has been set up to manage the log file size."