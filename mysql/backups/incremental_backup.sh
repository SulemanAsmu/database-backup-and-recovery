#!/bin/bash
# =============================================
# Database:    MySQL 8.0
# Author:      Suleman
# Description: MySQL Incremental Backup
#              Using Binary Logs
#              Enables Point-In-Time Recovery
# Schedule:    Every 2 hours
# =============================================

DB_HOST="localhost"
DB_USER="backup_user"
DB_PASS="your_backup_password"
BACKUP_DIR="/backup/mysql/binlogs"
LOG_DIR="/backup/mysql/logs"
MYSQL_DATA="/var/lib/mysql"
DATE=$(date +%Y%m%d_%H%M%S)
LOG_FILE="$LOG_DIR/binlog_backup_$DATE.log"

mkdir -p $BACKUP_DIR $LOG_DIR

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a $LOG_FILE
}

log_message "Starting Binary Log Backup..."

# -----------------------------------------------
# Flush binary logs to start new log file
# -----------------------------------------------
mysql \
    --host=$DB_HOST \
    --user=$DB_USER \
    --password=$DB_PASS \
    -e "FLUSH BINARY LOGS;"

# -----------------------------------------------
# Copy binary log files
# -----------------------------------------------
mysqlbinlog \
    --read-from-remote-server \
    --host=$DB_HOST \
    --user=$DB_USER \
    --password=$DB_PASS \
    --raw \
    --stop-never-slave-server-id=1 \
    --to-last-log \
    --result-file=$BACKUP_DIR/ \
    mysql-bin.000001 &

log_message "✅ Binary Log Backup Running"

# -----------------------------------------------
# Check binary log status
# -----------------------------------------------
mysql \
    --host=$DB_HOST \
    --user=$DB_USER \
    --password=$DB_PASS \
    -e "SHOW MASTER STATUS\G" >> $LOG_FILE

log_message "Binary Log backup completed"
