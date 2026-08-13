#!/bin/bash
# =============================================
# Database:    Oracle 19c/21c
# Author:      Suleman
# Description: Archive Log Backup
#              Runs every 2 hours
#              Enables Point-In-Time Recovery
# Schedule:    Every 2 hours via cron
#              0 */2 * * * /scripts/archivelog_backup.sh
# =============================================

ORACLE_SID="COMPANYDB"
ORACLE_HOME="/u01/app/oracle/product/19c/dbhome_1"
BACKUP_DIR="/backup/oracle/archivelogs"
LOG_DIR="/backup/oracle/logs"
DATE=$(date +%Y%m%d_%H%M%S)
LOG_FILE="$LOG_DIR/archlog_$DATE.log"

export ORACLE_SID=$ORACLE_SID
export ORACLE_HOME=$ORACLE_HOME
export PATH=$ORACLE_HOME/bin:$PATH

mkdir -p $BACKUP_DIR $LOG_DIR

$ORACLE_HOME/bin/rman target / << EOF >> $LOG_FILE 2>&1

RUN {
    ALLOCATE CHANNEL ch1 DEVICE TYPE DISK
        FORMAT '$BACKUP_DIR/arch_%d_%T_%U';

    # Backup all archived logs not yet backed up
    BACKUP AS COMPRESSED BACKUPSET
        ARCHIVELOG ALL NOT BACKED UP
        TAG 'ARCHLOG_$DATE'
        DELETE INPUT;   -- Delete after backup to save space

    RELEASE CHANNEL ch1;
}

EXIT;
EOF

if [ $? -eq 0 ]; then
    echo "[$(date)] ✅ Archivelog Backup Completed" >> $LOG_FILE
else
    echo "[$(date)] ❌ Archivelog Backup FAILED!"   >> $LOG_FILE
    exit 1
fi
