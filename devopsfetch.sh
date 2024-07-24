#!/bin/bash

# Log file path
LOG_FILE="/var/log/devopsfetch.log"

# Function to log activities
log_activity() {
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo "[$timestamp] $1" >> "$LOG_FILE"
}

# Log script start
log_activity "Script started with arguments: $*"

# Function to display help information
display_help() {
    echo "Usage: devopsfetch [OPTION]... [ARGUMENT]..."
    echo "Collect and display system information for DevOps purposes."
    echo
    echo "Options:"
    echo "  -p, --port [PORT]     Display active ports or info for a specific port"
    echo "  -d, --docker [NAME]   List Docker images/containers or info for a specific container/image"
    echo "  -n, --nginx [DOMAIN]  Display Nginx domains or config for a specific domain"
    echo "  -u, --users [USER]    List users and last login times or info for a specific user"
    echo "  -t, --time RANGE      Display activities within a specified time range"
    echo "  -h, --help            Display this help message"
    echo
    echo "Time range format examples:"
    echo "  devopsfetch -t 5m              (last 5 minutes)"
    echo "  devopsfetch -t '2 hours'       (last 2 hours)"
    echo "  devopsfetch -t 1d              (last day)"
    echo "  devopsfetch -t '2024-07-18 2024-07-22'  (specific date range)"
    echo "  devopsfetch -t 2024-07-21      (specific date)"
}

# Function to format output in a table
format_table() {
    column -t -s $'\t'
}

check_docker_permission() {
    if ! docker info >/dev/null 2>&1; then
        echo "Error: Unable to connect to Docker. Make sure Docker is running and you have the necessary permissions."
        echo "Try running the script with sudo or add your user to the docker group."
        log_activity "Error: Docker permission check failed"
        exit 1
    fi
}

display_ports() {
    local port_filter=$1
    log_activity "Displaying ports information. Filter: $port_filter"
    if [ -z "$port_filter" ]; then
        sudo lsof -i -nP | awk '
        NR==1 {
            $1 = "SERVICES";
            $NF = "ADDRESS:PORT";
            $(NF+1) = "STATE";
            print;
            next;
        }
        {
            port = "";
            state = "";
            split($NF, a, ":");
            if (length(a) > 1) {
                split(a[length(a)], b, ")");
                port = b[1];
                if (length(b) > 1) state = b[2];
            }
            if ($4 ~ /^UDP/) {
                state = "";
                $(NF+1) = state;
                $NF = port;
            } else if ($4 ~ /^TCP/) {
                if (state == "") state = "(LISTEN)";
                $(NF+1) = state;
                $NF = port;
            }
            print;
        }
        ' | column -t
    else
        sudo lsof -i :$port_filter -nP | awk '
        NR==1 {print; next}
        $9 ~ /:'$port_filter'($|\))/ {print}
        ' | column -t
    fi
}

display_docker() {
    check_docker_permission
    local container=$1
    log_activity "Displaying Docker information. Container/Image: $container"
    if [ -z "$container" ]; then
        echo "Docker Images:"
        docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.ID}}\t{{.Size}}\t{{.CreatedAt}}" | format_table
        echo -e "\nAll Docker Containers (including exited):"
        docker ps -a --format "table {{.ID}}\t{{.Image}}\t{{.Command}}\t{{.CreatedAt}}\t{{.Status}}\t{{.Ports}}\t{{.Names}}" | format_table
    else
        echo "Information for container/image $container:"
        if docker inspect "$container" >/dev/null 2>&1; then
            docker inspect "$container" | jq '.'
        elif docker image inspect "$container" >/dev/null 2>&1; then
            docker image inspect "$container" | jq '.[0] | {ID: .Id, RepoTags: .RepoTags, Size: .Size, Created: .Created, DockerVersion: .DockerVersion}'
        else
            echo "No container or image found with the name or ID: $container"
        fi
    fi
}

display_nginx_domains() {
    log_activity "Displaying Nginx domains"
    echo "Domain          Proxy                     Configuration File"
    echo "+---------------+-------------------------+----------------------------------------+"
    for conf in /etc/nginx/sites-available/*; do
        server_name=$(grep -m 1 'server_name' $conf | awk '{print $2}' | tr -d ';')
        proxy_pass=$(grep -m 1 'proxy_pass' $conf | awk '{print $2}' | tr -d ';')
        if [[ -n "$server_name" && -n "$proxy_pass" ]]; then
            printf "%-15s %-25s %-40s\n" "$server_name" "$proxy_pass" "$conf"
        fi
    done
    echo "+---------------+-------------------------+----------------------------------------+"
}

display_domain_details() {
    domain=$1
    log_activity "Displaying details for Nginx domain: $domain"
    conf_file=$(grep -rl "server_name $domain" /etc/nginx/sites-available)
    if [[ -n "$conf_file" ]]; then
        echo "Detailed configuration for $domain:"
        cat $conf_file
    else
        echo "Configuration for domain $domain not found."
    fi
}

display_users() {
    local user=$1
    log_activity "Displaying user information"
    if [ -z "$user" ]; then
        echo "Users and Last Login Times:"
        printf "%-23s %-8s %-20s %-35s %-25s\n" "USER" "PORT" "IP ADDRESS" "LAST LOGIN" "STATUS"
        lastlog | awk 'NR>1 {
            user=$1
            if ($2 == "**Never") {
                port="N/A"
                ip="N/A"
                login="Never logged in"
                timestamp=0
            } else {
                port=$2
                ip=$3
                $1=$2=$3=""
                login=substr($0,4)
                gsub(/^[ \t]+|[ \t]+$/, "", login)
                timestamp=mktime(substr(login,1,4) " " substr(login,5,3) " " substr(login,9,2) " " substr(login,12))
            }
            status=""
            cmd = "last | grep \"^" user "\" | grep -q \"still logged in\""
            if (system(cmd) == 0) status = "still logged in"
            printf "%-23s %-8s %-20s %-35s %-25s\n", user, port, ip, login, status
        }' | sort -rnk6 | cut -f1-5
    else
        echo "Detailed Information for user $user:"
        echo "----------------------------------------"
        
        IFS=':' read -r username password uid gid gecos home shell <<< "$(getent passwd "$user")"
        
        lastlog_info=$(lastlog -u "$user" | awk 'NR>1')
        if [ -n "$lastlog_info" ]; then
            read -r _ port ip_address last_login <<< "$lastlog_info"
            last_login=$(echo "$lastlog_info" | awk '{for(i=4;i<=NF;i++) printf "%s ", $i}')
        else
            port="N/A"
            ip_address="N/A"
            last_login="Never logged in"
        fi
        
        if last | grep -q "^$user.*still logged in"; then
            status="still logged in"
        else
            status=""
        fi
        
        expiration=$(chage -l "$user" | grep "Account expires" | cut -d: -f2-)
        
        groups=$(groups "$user" | cut -d: -f2-)
        
        printf "%-20s %s\n" "Username:" "$username"
        printf "%-20s %s\n" "Real Name:" "$gecos"
        printf "%-20s %s\n" "UID:" "$uid"
        printf "%-20s %s\n" "GID:" "$gid"
        printf "%-20s %s\n" "Home Directory:" "$home"
        printf "%-20s %s\n" "Shell:" "$shell"
        printf "%-20s %s\n" "Groups:" "$groups"
        echo
        echo "Last Login:"
        printf "  %-8s %-20s %-35s %-25s\n" "PORT" "IP ADDRESS" "TIME" "STATUS"
        printf "  %-8s %-20s %-35s %-25s\n" "$port" "$ip_address" "$last_login" "$status"
        echo
        printf "%-20s %s\n" "Account Expiration:" "$expiration"
        echo
        echo "Recent Login Attempts:"
        echo "----------------------------------------"
        last "$user" | head -n 5
    fi
}

parse_time_range() {
    local time_arg=$1
    log_activity "Parsing time range: $time_arg"
    local current_time=$(date +%s)
    local start_time
    local end_time=$current_time

    case $time_arg in
        *m|*minute*) 
            start_time=$((current_time - ${time_arg//[!0-9]/} * 60))
            ;;
        *h|*hour*)
            start_time=$((current_time - ${time_arg//[!0-9]/} * 3600))
            ;;
        *d|*day*)
            start_time=$((current_time - ${time_arg//[!0-9]/} * 86400))
            ;;
        [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9])
            start_time=$(date -d "$time_arg" +%s)
            end_time=$((start_time + 86400))
            ;;
        [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]" "[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9])
            start_time=$(date -d "${time_arg% *}" +%s)
            end_time=$(date -d "${time_arg#* }" +%s)
            ;;
        *)
            echo "Invalid time range format. Use -h for help."
            exit 1
            ;;
    esac

    echo "$start_time $end_time"
}

display_activities() {
    local start_time=$1
    local end_time=$2
    log_activity "Displaying system activities from $start_time to $end_time"
    echo "System Activities:"
    journalctl --since "$start_time" --until "$end_time" | tail -n 20
}

# Main script logic
if [ $# -eq 0 ]; then
    log_activity "No arguments provided. Displaying help."
    display_help
    exit 0
fi

while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--port)
            if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
                log_activity "Displaying information for port: $2"
                display_ports $2
                shift 2
            else
                log_activity "Displaying all ports"
                display_ports
                shift
            fi
            ;;
        -d|--docker)
            if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
                log_activity "Displaying information for Docker container/image: $2"
                display_docker $2
                shift 2
            else
                log_activity "Displaying all Docker information"
                display_docker
                shift
            fi
            ;;
        -n|--nginx)
            log_activity "Nginx option selected"
            if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
                log_activity "Displaying Nginx details for domain: $2"
                display_domain_details "$2"
                shift 2
            else
                log_activity "Displaying all Nginx domains"
                display_nginx_domains
                shift
            fi
            ;;
        -u|--users)
            log_activity "Users option selected"
            if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
                log_activity "Displaying information for user: $2"
                display_users $2
                shift 2
            else
                log_activity "Displaying all user information"
                display_users
                shift
            fi
            ;;
        -t|--time)
            log_activity "Time range option selected"
            if [ -n "$2" ]; then
                log_activity "Parsing time range: $2"
                time_range=$(parse_time_range "$2")
                start_time=$(date -d @${time_range% *} +'%Y-%m-%d %H:%M:%S')
                end_time=$(date -d @${time_range#* } +'%Y-%m-%d %H:%M:%S')
                log_activity "Displaying activities from $start_time to $end_time"
                echo "Displaying activities from $start_time to $end_time"
                display_activities "$start_time" "$end_time"
                shift 2
            else
                log_activity "Error: Time range argument is missing."
                echo "Error: Time range argument is missing."
                exit 1
            fi
            ;;
        -h|--help)
            log_activity "Help option selected"
            display_help
            exit 0
            ;;
        *)
            log_activity "Unknown option: $1"
            echo "Unknown option: $1"
            display_help
            exit 1
            ;;
    esac
done

# Log script end
log_activity "Script execution completed"