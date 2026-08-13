#!/bin/bash
# =============================================
# Database:    PostgreSQL 15
# Author:      Suleman
# Description: PostgreSQL Backup Script
#              pg_dump and pg_basebackup
# Schedule:    Every Sunday at 00:00
# =============================================

DB_HOST="localhost"
DB_PORT="5432"
DB_USER="postgres"
DB_NAME="companydb"
BACKUP_DIR="/backup/postgresql/full"
LOG_DIR="/backup/postgresql/logs"
DATE=$(date +%Y%m%d_%H%M%S)
LOG_FILE="$LOG_DIR/pg_backup_$DATE.log"
RETENTION_DAYS=30

export PGPASSWORD="your_password"

mkdir -p $BACKUP_DIR $LOG_DIR

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a $LOG_FILE
}

log_message "========================================"
log_message "PostgreSQL Backup Started"
log_message "Database: $DB_NAME"
log_message "========================================"

# -----------------------------------------------
# Method 1: pg_dump - Single Database
#            Logical backup (SQL format)
# -----------------------------------------------
log_message "Running pg_dump..."

pg_dump \
    --host=$DB_HOST \
    --port=$DB_PORT \
    --username=$DB_USER \
    --format=custom \
    --compress=9 \
    --blobs \
    --verbose \
    --file=$BACKUP_DIR/${DB_NAME}_$DATE.dump \
    $DB_NAME >> $LOG_FILE 2>&1

if [ $? -eq 0 ]; then
    log_message "✅ pg_dump Completed"
else
    log_message "❌ pg_dump FAILED!"
    exit 1
fi

# -----------------------------------------------
# Method 2: pg_dumpall - All Databases
#            Including roles and tablespaces
# -----------------------------------------------
log_message "Running pg_dumpall..."

pg_dumpall \
    --host=$DB_HOST \
    --port=$DB_PORT \
    --username=$DB_USER \
    --globals-only \
    --file=$BACKUP_DIR/globals_$DATE.sql >> $LOG_FILE 2>&1

log_message "✅ Globals backup completed"

# -----------------------------------------------
# Method 3: pg_basebackup - Physical Backup
#            For streaming replication setup
# -----------------------------------------------
log_message "Running pg_basebackup..."

pg_basebackup \
    --host=$DB_HOST \
    --port=$DB_PORT \
    --username=replication_user \
    --pgdata=$BACKUP_DIR/basebackup_$DATE \
    --format=tar \
    --gzip \
    --compress=9 \
    --progress \
    --checkpoint=fast \
    --wal-method=stream >> $LOG_FILE 2>&1

log_message "✅ pg_basebackup Completed"

# Cleanup old backups
find $BACKUP_DIR -name "*.dump" -mtime +$RETENTION_DAYS -delete
find $BACKUP_DIR -name "*.sql"  -mtime +$RETENTION_DAYS -delete

log_message "========================================"
log_message "All PostgreSQL Backups Completed"
log_message "========================================"
