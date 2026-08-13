#!/bin/bash
# =============================================
# Database:    MySQL 8.0
# Author:      Suleman
# Description: MySQL Full Backup Script
#              Using mysqldump
# Schedule:    Every Sunday at 00:00
# =============================================

DB_HOST="localhost"
DB_PORT="3306"
DB_USER="backup_user"
DB_PASS="your_backup_password"
DB_NAME="CompanyDB"
BACKUP_DIR="/backup/mysql/full"
LOG_DIR="/backup/mysql/logs"
DATE=$(date +%Y%m%d_%H%M%S)
LOG_FILE="$LOG_DIR/full_backup_$DATE.log"
RETENTION_DAYS=30

mkdir -p $BACKUP_DIR $LOG_DIR

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a $LOG_FILE
}

log_message "========================================"
log_message "MySQL Full Backup Started"
log_message "Database: $DB_NAME"
log_message "========================================"

# -----------------------------------------------
# Full Backup with mysqldump
# -----------------------------------------------
mysqldump \
    --host=$DB_HOST \
    --port=$DB_PORT \
    --user=$DB_USER \
    --password=$DB_PASS \
    --single-transaction \
    --routines \
    --triggers \
    --events \
    --hex-blob \
    --master-data=2 \
    --flush-logs \
    $DB_NAME | gzip > $BACKUP_DIR/full_${DB_NAME}_$DATE.sql.gz

if [ $? -eq 0 ]; then
    BACKUP_SIZE=$(du -sh $BACKUP_DIR/full_${DB_NAME}_$DATE.sql.gz | cut -f1)
    log_message "✅ Full Backup Completed"
    log_message "File: full_${DB_NAME}_$DATE.sql.gz"
    log_message "Size: $BACKUP_SIZE"
else
    log_message "❌ Full Backup FAILED!"
    exit 1
fi

# -----------------------------------------------
# Backup all databases
# -----------------------------------------------
log_message "Backing up all databases..."

mysqldump \
    --host=$DB_HOST \
    --user=$DB_USER \
    --password=$DB_PASS \
    --all-databases \
    --single-transaction \
    --routines \
    --triggers \
    --events \
    --flush-privileges | gzip > \
    $BACKUP_DIR/all_databases_$DATE.sql.gz

log_message "✅ All Databases Backup Completed"

# -----------------------------------------------
# Cleanup old backups
# -----------------------------------------------
log_message "Cleaning up backups older than $RETENTION_DAYS days..."
find $BACKUP_DIR -name "*.sql.gz" -mtime +$RETENTION_DAYS -delete
log_message "Cleanup completed"
log_message "========================================"
