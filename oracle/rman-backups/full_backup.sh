#!/bin/bash
# =============================================
# Database:    Oracle 19c/21c
# Author:      Suleman
# Description: RMAN Full Database Backup Script
# Schedule:    Every Sunday at 00:00
# =============================================

# -----------------------------------------------
# Configuration Variables
# -----------------------------------------------
ORACLE_SID="COMPANYDB"
ORACLE_HOME="/u01/app/oracle/product/19c/dbhome_1"
BACKUP_DIR="/backup/oracle/full"
LOG_DIR="/backup/oracle/logs"
DATE=$(date +%Y%m%d_%H%M%S)
LOG_FILE="$LOG_DIR/full_backup_$DATE.log"
RETENTION_DAYS=30

# -----------------------------------------------
# Setup Environment
# -----------------------------------------------
export ORACLE_SID=$ORACLE_SID
export ORACLE_HOME=$ORACLE_HOME
export PATH=$ORACLE_HOME/bin:$PATH

# Create directories if they don't exist
mkdir -p $BACKUP_DIR
mkdir -p $LOG_DIR

# -----------------------------------------------
# Function: Log Message
# -----------------------------------------------
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a $LOG_FILE
}

# -----------------------------------------------
# Function: Send Alert (customize for your setup)
# -----------------------------------------------
send_alert() {
    local STATUS=$1
    local MESSAGE=$2
    echo "[$STATUS] $MESSAGE" >> $LOG_FILE
    # Add email or SMS alert here
    # mail -s "Oracle Backup $STATUS" dba@company.com <<< "$MESSAGE"
}

# -----------------------------------------------
# Start Backup
# -----------------------------------------------
log_message "========================================"
log_message "Oracle Full Backup Started"
log_message "Database: $ORACLE_SID"
log_message "Backup Dir: $BACKUP_DIR"
log_message "========================================"

$ORACLE_HOME/bin/rman target / << EOF >> $LOG_FILE 2>&1

# Configure RMAN settings
CONFIGURE RETENTION POLICY TO RECOVERY WINDOW OF $RETENTION_DAYS DAYS;
CONFIGURE BACKUP OPTIMIZATION ON;
CONFIGURE CONTROLFILE AUTOBACKUP ON;
CONFIGURE CONTROLFILE AUTOBACKUP FORMAT
    FOR DEVICE TYPE DISK TO '$BACKUP_DIR/cf_%F';
CONFIGURE DEFAULT DEVICE TYPE TO DISK;
CONFIGURE CHANNEL DEVICE TYPE DISK
    FORMAT '$BACKUP_DIR/full_%d_%T_%U';
CONFIGURE COMPRESSION ALGORITHM 'MEDIUM';

# Run Full Backup
RUN {
    # Allocate 2 parallel channels for faster backup
    ALLOCATE CHANNEL ch1 DEVICE TYPE DISK
        FORMAT '$BACKUP_DIR/full_%d_%T_%U_ch1'
        MAXPIECESIZE 10G;
    ALLOCATE CHANNEL ch2 DEVICE TYPE DISK
        FORMAT '$BACKUP_DIR/full_%d_%T_%U_ch2'
        MAXPIECESIZE 10G;

    # Backup entire database including archived logs
    BACKUP AS COMPRESSED BACKUPSET
        DATABASE
        PLUS ARCHIVELOG
        TAG 'FULL_BACKUP_$DATE';

    # Backup current controlfile
    BACKUP CURRENT CONTROLFILE
        TAG 'CTL_FULL_$DATE';

    # Backup SPFile
    BACKUP SPFILE
        TAG 'SPF_FULL_$DATE';

    # Release channels
    RELEASE CHANNEL ch1;
    RELEASE CHANNEL ch2;
}

# Delete old archived logs after backup
DELETE NOPROMPT ARCHIVELOG ALL
    COMPLETED BEFORE 'SYSDATE-1';

# Crosscheck and delete obsolete backups
CROSSCHECK BACKUP;
DELETE NOPROMPT OBSOLETE;

# List backup summary
LIST BACKUP SUMMARY;

EXIT;
EOF

# -----------------------------------------------
# Check if backup succeeded
# -----------------------------------------------
if [ $? -eq 0 ]; then
    log_message "✅ Full Backup Completed Successfully"
    send_alert "SUCCESS" "Oracle Full Backup completed: $DATE"
else
    log_message "❌ Full Backup FAILED!"
    send_alert "FAILED" "Oracle Full Backup FAILED: $DATE - Check $LOG_FILE"
    exit 1
fi

# -----------------------------------------------
# Delete old log files
# -----------------------------------------------
find $LOG_DIR -name "full_backup_*.log" \
    -mtime +$RETENTION_DAYS -delete

log_message "Old logs cleaned up"
log_message "========================================"
log_message "Backup Process Finished"
log_message "========================================"
