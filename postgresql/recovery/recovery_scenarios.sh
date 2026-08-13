#!/bin/bash
# =============================================
# Database:    PostgreSQL 15
# Author:      Suleman
# Description: PostgreSQL Recovery Scenarios
# =============================================

DB_HOST="localhost"
DB_PORT="5432"
DB_USER="postgres"
DB_NAME="companydb"
BACKUP_DIR="/backup/postgresql/full"

export PGPASSWORD="your_password"

# -----------------------------------------------
# SCENARIO 1: Restore from pg_dump
# -----------------------------------------------
restore_from_dump() {
    local DUMP_FILE=$1
    echo "Restoring from: $DUMP_FILE"

    # Drop and recreate database
    psql \
        --host=$DB_HOST \
        --port=$DB_PORT \
        --username=$DB_USER \
        --command="DROP DATABASE IF EXISTS $DB_NAME;"

    psql \
        --host=$DB_HOST \
        --port=$DB_PORT \
        --username=$DB_USER \
        --command="CREATE DATABASE $DB_NAME
                   WITH OWNER = $DB_USER
                   ENCODING = 'UTF8';"

    # Restore
    pg_restore \
        --host=$DB_HOST \
        --port=$DB_PORT \
        --username=$DB_USER \
        --dbname=$DB_NAME \
        --verbose \
        --no-owner \
        --jobs=4 \
        $DUMP_FILE

    if [ $? -eq 0 ]; then
        echo "✅ Restore Completed"
    else
        echo "❌ Restore FAILED!"
        exit 1
    fi
}

# -----------------------------------------------
# SCENARIO 2: Restore Single Table
# -----------------------------------------------
restore_single_table() {
    local DUMP_FILE=$1
    local TABLE_NAME=$2
    echo "Restoring table: $TABLE_NAME"

    pg_restore \
        --host=$DB_HOST \
        --port=$DB_PORT \
        --username=$DB_USER \
        --dbname=$DB_NAME \
        --table=$TABLE_NAME \
        --data-only \
        $DUMP_FILE

    echo "✅ Table $TABLE_NAME Restored"
}

# -----------------------------------------------
# SCENARIO 3: Point-In-Time Recovery (PITR)
# -----------------------------------------------
pitr_recovery() {
    local RECOVERY_TARGET=$1  # "2024-01-15 14:30:00"
    echo "PITR to: $RECOVERY_TARGET"

    # Create recovery.conf (PostgreSQL 11 and below)
    # For PostgreSQL 12+ use postgresql.conf parameters

    cat > /etc/postgresql/15/main/postgresql.conf << EOF

# PITR Recovery Settings
restore_command = 'cp /backup/postgresql/wal/%f %p'
recovery_target_time = '$RECOVERY_TARGET'
recovery_target_action = 'promote'
EOF

    echo "✅ PITR configuration set"
    echo "Restart PostgreSQL to begin recovery"
    echo "sudo systemctl restart postgresql"
}

# Main
case "$1" in
    "restore")  restore_from_dump "$2" ;;
    "table")    restore_single_table "$2" "$3" ;;
    "pitr")     pitr_recovery "$2" ;;
    *)
        echo "Usage:"
        echo "  $0 restore /path/to/backup.dump"
        echo "  $0 table /path/to/backup.dump TABLE_NAME"
        echo "  $0 pitr 'YYYY-MM-DD HH:MM:SS'"
        ;;
esac
