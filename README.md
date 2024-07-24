# DevopsFetch

Devopsfetch is a command line too that collects and displays system information, including active ports, user logins, Nginx configurations, Docker images, and container statuses.

## Installation
Follow the below steps to setup Devopsfetch on your machine.

1.  Clone the Repository
```
git clone https://github.com/FavourDaniel/devopsfetch.git
```
- Change directory
```
cd devopsfetch
```
- Make the script executable
```
chmod +x install_devopsfetch.sh
```
- Run the script
```
sudo ./install_devopsfetch.sh
```

## Usage Examples
- Display all active ports and services
```
sudo ./devopsfetch.sh -p
sudo ./devopsfetch.sh --port
```
- Get detailed information about a specific port
```
sudo ./devopsfetch.sh -p <port-number>
```
- List all Docker images and containers
```
sudo ./devopsfetch.sh -d
sudo ./devopsfetch.sh --docker
```
- Display all Nginx domains and their ports
```
sudo ./devopsfetch.sh -n
sudo ./devopsfetch.sh --nginx
```
- List all users and their last login times
```
sudo ./devopsfetch.sh -u
sudo ./devopsfetch.sh --users
```
- Get detailed information about a specific user
```
sudo ./devopsfetch.sh -u <username>
```
- Display activities within a specified time range
```
sudo ./devopsfetch.sh -t <time-range>
sudo ./devopsfetch.sh --time <time-range>
```
- Get usage instructions for the program
```
sudo ./devopsfetch.sh -h
sudo ./devopsfetch.sh --help
```

## Logging Mechanism

The logging mechanism used here is
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

To retrieve the logs
```
cat /var/log/devopsfetch.log
```
