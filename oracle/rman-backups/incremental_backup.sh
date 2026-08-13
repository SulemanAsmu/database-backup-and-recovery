#!/bin/bash
# =============================================
# Database:    Oracle 19c/21c
# Author:      Suleman
# Description: RMAN Incremental Backup Script
#              Level 0 = Full (baseline)
#              Level 1 = Changes since Level 0
# Schedule:    Monday-Saturday at 00:00
# =============================================

ORACLE_SID="COMPANYDB"
ORACLE_HOME="/u01/app/oracle/product/19c/dbhome_1"
BACKUP_DIR="/backup/oracle/incremental"
LOG_DIR="/backup/oracle/logs"
DATE=$(date +%Y%m%d_%H%M%S)
LOG_FILE="$LOG_DIR/incr_backup_$DATE.log"
DAY_OF_WEEK=$(date +%u)   # 1=Monday 7=Sunday

export ORACLE_SID=$ORACLE_SID
export ORACLE_HOME=$ORACLE_HOME
export PATH=$ORACLE_HOME/bin:$PATH

mkdir -p $BACKUP_DIR $LOG_DIR

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a $LOG_FILE
}

log_message "========================================"
log_message "Oracle Incremental Backup Started"
log_message "Day of Week: $DAY_OF_WEEK"
log_message "========================================"

# Sunday = Level 0 (baseline), Others = Level 1
if [ "$DAY_OF_WEEK" -eq 7 ]; then
    BACKUP_LEVEL=0
    BACKUP_TAG="INCR_LEVEL0_$DATE"
    log_message "Running Level 0 (Baseline) Backup"
else
    BACKUP_LEVEL=1
    BACKUP_TAG="INCR_LEVEL1_$DATE"
    log_message "Running Level 1 (Incremental) Backup"
fi

$ORACLE_HOME/bin/rman target / << EOF >> $LOG_FILE 2>&1

RUN {
    ALLOCATE CHANNEL ch1 DEVICE TYPE DISK
        FORMAT '$BACKUP_DIR/incr_$BACKUP_LEVEL_%d_%T_%U'
        MAXPIECESIZE 5G;

    # Incremental backup
    BACKUP AS COMPRESSED BACKUPSET
        INCREMENTAL LEVEL $BACKUP_LEVEL
        DATABASE
        PLUS ARCHIVELOG DELETE INPUT
        TAG '$BACKUP_TAG';

    # Always backup controlfile
    BACKUP CURRENT CONTROLFILE
        TAG 'CTL_INCR_$DATE';

    RELEASE CHANNEL ch1;
}

CROSSCHECK BACKUP;
DELETE NOPROMPT OBSOLETE;
LIST BACKUP SUMMARY;
EXIT;
EOF

if [ $? -eq 0 ]; then
    log_message "✅ Incremental Level $BACKUP_LEVEL Backup Completed"
else
    log_message "❌ Incremental Backup FAILED!"
    exit 1
fi
