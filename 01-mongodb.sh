
#!/bin/bash

USER_ID=$(id -u)
SCRIPT_NAME=$(basename "$0" .sh)
LOGS_FOLDER="/var/log/roboshop"
LOGS_FILE="${LOGS_FOLDER}/${SCRIPT_NAME}.log"

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

# Check root privileges
if [ "$USER_ID" -ne 0 ]; then
    echo -e "${R}Please run this script with sudo access.${N}"
    exit 1
fi

# Create log directory
mkdir -p "$LOGS_FOLDER" || {
    echo "Failed to create log directory: $LOGS_FOLDER"
    exit 1
}

echo "Script started execution at $(date '+%F %T')" >> "$LOGS_FILE"

# Validate command status
validate() {
    local status="$1"
    local message="$2"

    if [ "$status" -ne 0 ]; then
        echo -e "${message}..${R}FAILED${N}" | tee -a "$LOGS_FILE"
        exit 1
    else
        echo -e "${message}..${G}SUCCESS${N}" | tee -a "$LOGS_FILE"
    fi
}

# Copy MongoDB repository configuration
cp mongo.repo /etc/yum.repos.d/mongo.repo 2>> "$LOGS_FILE"
validate "$?" "Adding MongoDB repository"

# Install MongoDB
dnf install mongodb-org -y >> "$LOGS_FILE" 2>&1
validate "$?" "Installing MongoDB"

# Enable MongoDB service
systemctl enable mongod >> "$LOGS_FILE" 2>&1
validate "$?" "Enabling MongoDB"

# Start MongoDB service
systemctl start mongod >> "$LOGS_FILE" 2>&1
validate "$?" "Starting MongoDB"

# Allow MongoDB to accept remote connections
sed -i 's/127\.0\.0\.1/0.0.0.0/g' /etc/mongod.conf >> "$LOGS_FILE" 2>&1
validate "$?" "Updating MongoDB remote connections"

# Restart MongoDB to apply configuration
systemctl restart mongod >> "$LOGS_FILE" 2>&1
validate "$?" "Restarting MongoDB"

echo "Script completed successfully at $(date '+%F %T')" | tee -a "$LOGS_FILE"
