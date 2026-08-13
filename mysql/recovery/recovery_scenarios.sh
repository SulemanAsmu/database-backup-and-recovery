#!/bin/bash
# =============================================
# Database:    MySQL 8.0
# Author:      Suleman
# Description: MySQL Recovery Scenarios
# =============================================

DB_HOST="localhost"
DB_USER="root"
DB_PASS="your_root_password"
DB_NAME="CompanyDB"
BACKUP_DIR="/backup/mysql/full"
BINLOG_DIR="/backup/mysql/binlogs"
DATE=$(date +%Y%m%d_%H%M%S)

# -----------------------------------------------
# SCENARIO 1: Full Restore from mysqldump
# -----------------------------------------------
full_restore() {
    local BACKUP_FILE=$1
    echo "Restoring from: $BACKUP_FILE"

    # Drop and recreate database
    mysql --host=$DB_HOST \
          --user=$DB_USER \
          --password=$DB_PASS \
          -e "DROP DATABASE IF EXISTS $DB_NAME;
              CREATE DATABASE $DB_NAME
              CHARACTER SET utf8mb4
              COLLATE utf8mb4_unicode_ci;"

    # Restore from backup
    gunzip -c $BACKUP_FILE | \
    mysql --host=$DB_HOST \
          --user=$DB_USER \
          --password=$DB_PASS \
          $DB_NAME

    if [ $? -eq 0 ]; then
        echo "✅ Full Restore Completed"
    else
        echo "❌ Restore FAILED!"
        exit 1
    fi
}

# -----------------------------------------------
# SCENARIO 2: Point-In-Time Recovery
# -----------------------------------------------
point_in_time_recovery() {
    local BACKUP_FILE=$1
    local STOP_DATETIME=$2  # Format: "2024-01-15 14:30:00"

    echo "Restoring to point in time: $STOP_DATETIME"

    # Step 1: Restore full backup
    full_restore $BACKUP_FILE

    # Step 2: Apply binary logs up to recovery point
    mysqlbinlog \
        --stop-datetime="$STOP_DATETIME" \
        $BINLOG_DIR/mysql-bin.* | \
    mysql --host=$DB_HOST \
          --user=$DB_USER \
          --password=$DB_PASS \
          $DB_NAME

    echo "✅ Point-In-Time Recovery Completed to: $STOP_DATETIME"
}

# -----------------------------------------------
# SCENARIO 3: Restore Single Table
# -----------------------------------------------
restore_single_table() {
    local BACKUP_FILE=$1
    local TABLE_NAME=$2

    echo "Restoring table: $TABLE_NAME"

    # Extract only the specific table from dump
    gunzip -c $BACKUP_FILE | \
    awk "/^-- Table structure for table \`$TABLE_NAME\`/,\
         /^-- Table structure for table \`/" | \
    mysql --host=$DB_HOST \
          --user=$DB_USER \
          --password=$DB_PASS \
          $DB_NAME

    echo "✅ Table $TABLE_NAME Restored"
}

# Main
case "$1" in
    "full")
        full_restore "$2"
        ;;
    "pitr")
        point_in_time_recovery "$2" "$3"
        ;;
    "table")
        restore_single_table "$2" "$3"
        ;;
    *)
        echo "Usage:"
        echo "  $0 full /path/to/backup.sql.gz"
        echo "  $0 pitr /path/to/backup.sql.gz 'YYYY-MM-DD HH:MM:SS'"
        echo "  $0 table /path/to/backup.sql.gz TABLE_NAME"
        ;;
esac
