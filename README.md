# DevopsFetch

Devopsfetch is a command line too that collects and displays system information, including active ports, user logins, Nginx configurations, Docker images, and container statuses.

## Features
- Ports: DevOpsfetch displays all active ports and associated services. It also provides detailed information about specific ports.
- Docker: It lists all Docker images with their details (repository, tag, image ID, size, creation date), shows all Docker containers (including exited ones) with comprehensive information and offers detailed inspection of specific containers or images
- Nginx: It displays all Nginx domains and their corresponding ports, and provides configuration details for specific domains
- Users: It lists all system users along with their last login times and provides detailed information about specific users.
- Time Range: It allows filtering of activities within a specified time range.
- Continuous Monitoring: It enables continuous monitoring of user activities.
- Log Rotation: It implements automatic log rotation using logrotate to manage log file sizes efficiently.

## Prerequisites
Before installing DevopsFetch, ensure you meet the following requirements:

- A Linux-based operating system with root or sudo access
- Docker installed and running
- Nginx installed and configured

## Installation

Follow these steps to set up DevopsFetch on your machine:

1.  Clone the Repository
```
git clone https://github.com/FavourDaniel/devopsfetch.git
```
2. Navigate to the DevopsFetch directory:
```
cd devopsfetch
```
3. Make the scripts executable:
```
chmod +x devopsfetch.sh
chmod +x install_devopsfetch.sh
```
4. Run the installation script with root privileges:
```
sudo ./install_devopsfetch.sh
```

This script will:
- Install necessary dependencies
- Set up log rotation
- Configure the DevopsFetch service for continuous monitoring

## Usage Examples
DevopsFetch offers a variety of commands to retrieve system information:

### Port Information
- Display all active ports and services
```
sudo ./devopsfetch.sh -p
sudo ./devopsfetch.sh --port
```
- Get detailed information about a specific port
```
sudo ./devopsfetch.sh -p <port-number>
```
### Docker Information

- List all Docker images and containers
```
sudo ./devopsfetch.sh -d
sudo ./devopsfetch.sh --docker
```
- Get detailed information about a specific container or image:
```
sudo ./devopsfetch.sh --docker <container_name>
sudo ./devopsfetch.sh -d <container_name>
```
### Nginx Information

- Display all Nginx domains and their ports
```
sudo ./devopsfetch.sh -n
sudo ./devopsfetch.sh --nginx
```
- Get configuration details for a specific domain
```
sudo ./devopsfetch.sh -n <domain>
sudo ./devopsfetch.sh --nginx <domain>
```

### User Information
- List all users and their last login times
```
sudo ./devopsfetch.sh -u
sudo ./devopsfetch.sh --users
```
- Get detailed information about a specific user
```
sudo ./devopsfetch.sh -u <username>
sudo ./devopsfetch.sh --users <username>
```
### Time Range Filtering

- Display activities within a specified time range
```
sudo ./devopsfetch.sh -t <time-range>
sudo ./devopsfetch.sh --time <time-range>
```
### Help

- Get usage instructions for the program
```
sudo ./devopsfetch.sh -h
sudo ./devopsfetch.sh --help
```

## Logging Mechanism

DevopsFetch implements a robust logging system to track its activities:

- Log file location: `/var/log/devopsfetch.log`
- Log rotation configuration:

```
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
```
- To view the logs
```
cat /var/log/devopsfetch.log
```
or 
```
tail -<number-of-logs-lines> /var/log/devopsfetch.log
```

## Continuous Monitoring

DevopsFetch can run as a service for continuous monitoring:

- Start the service
```
`sudo systemctl start devopsfetch.service
```
- Stop the service
```
sudo systemctl stop devopsfetch.service
```
- Check service status
```
sudo systemctl status devopsfetch.service
```

## Troubleshooting

If you encounter any issues:
1. Check the log file for error messages
```
cat /var/log/devopsfetch.log
```
2. Ensure all prerequisites are correctly installed
3. Verify that you have the necessary permissions to run the script

