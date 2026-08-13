#!/bin/bash
# =============================================
# Database:    Oracle 19c/21c
# Author:      Suleman
# Description: RMAN Recovery Scenarios
# =============================================

ORACLE_SID="COMPANYDB"
ORACLE_HOME="/u01/app/oracle/product/19c/dbhome_1"
LOG_DIR="/backup/oracle/logs"
DATE=$(date +%Y%m%d_%H%M%S)

export ORACLE_SID=$ORACLE_SID
export ORACLE_HOME=$ORACLE_HOME
export PATH=$ORACLE_HOME/bin:$PATH

# -----------------------------------------------
# SCENARIO 1: Complete Database Recovery
# -----------------------------------------------
complete_recovery() {
    echo "Starting Complete Database Recovery..."
    $ORACLE_HOME/bin/rman target / << EOF

    # Startup in mount mode
    STARTUP MOUNT;

    # Restore and recover database
    RESTORE DATABASE;
    RECOVER DATABASE;

    # Open database with resetlogs
    ALTER DATABASE OPEN RESETLOGS;

    EXIT;
EOF
}

# -----------------------------------------------
# SCENARIO 2: Point-In-Time Recovery
# -----------------------------------------------
point_in_time_recovery() {
    local RECOVERY_TIME=$1  # Format: 'YYYY-MM-DD HH24:MI:SS'
    echo "Starting Point-In-Time Recovery to: $RECOVERY_TIME"

    $ORACLE_HOME/bin/rman target / << EOF

    STARTUP MOUNT;

    RUN {
        # Set recovery target time
        SET UNTIL TIME "$RECOVERY_TIME";

        RESTORE DATABASE;
        RECOVER DATABASE;
    }

    ALTER DATABASE OPEN RESETLOGS;
    EXIT;
EOF
}

# -----------------------------------------------
# SCENARIO 3: Recover Single Datafile
# -----------------------------------------------
recover_datafile() {
    local DATAFILE=$1
    echo "Recovering datafile: $DATAFILE"

    $ORACLE_HOME/bin/rman target / << EOF

    # Offline the damaged datafile
    SQL "ALTER DATABASE DATAFILE '$DATAFILE' OFFLINE";

    # Restore and recover
    RESTORE DATAFILE '$DATAFILE';
    RECOVER DATAFILE '$DATAFILE';

    # Bring back online
    SQL "ALTER DATABASE DATAFILE '$DATAFILE' ONLINE";

    EXIT;
EOF
}

# -----------------------------------------------
# Main - Run based on argument
# -----------------------------------------------
case "$1" in
    "complete")
        complete_recovery
        ;;
    "pitr")
        point_in_time_recovery "$2"
        ;;
    "datafile")
        recover_datafile "$2"
        ;;
    *)
        echo "Usage: $0 {complete|pitr 'YYYY-MM-DD HH:MM:SS'|datafile '/path/file.dbf'}"
        exit 1
        ;;
esac
