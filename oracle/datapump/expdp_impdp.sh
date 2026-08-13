#!/bin/bash
# =============================================
# Database:    Oracle 19c/21c
# Author:      Suleman
# Description: Oracle Data Pump Export/Import
#              Logical backup for migration
#              and archiving
# =============================================

ORACLE_SID="COMPANYDB"
ORACLE_HOME="/u01/app/oracle/product/19c/dbhome_1"
DUMP_DIR="/backup/oracle/datapump"
LOG_DIR="/backup/oracle/logs"
DATE=$(date +%Y%m%d_%H%M%S)
DB_USER="system"
DB_PASS="your_password"

export ORACLE_SID=$ORACLE_SID
export ORACLE_HOME=$ORACLE_HOME
export PATH=$ORACLE_HOME/bin:$PATH

mkdir -p $DUMP_DIR $LOG_DIR

# -----------------------------------------------
# EXPORT: Full Database
# -----------------------------------------------
full_export() {
    echo "Starting Full Database Export..."
    $ORACLE_HOME/bin/expdp $DB_USER/$DB_PASS \
        FULL=Y \
        DIRECTORY=DATA_PUMP_DIR \
        DUMPFILE=full_export_$DATE.dmp \
        LOGFILE=full_export_$DATE.log \
        COMPRESSION=ALL \
        PARALLEL=4

    if [ $? -eq 0 ]; then
        echo "✅ Full Export Completed: full_export_$DATE.dmp"
    else
        echo "❌ Full Export FAILED!"
        exit 1
    fi
}

# -----------------------------------------------
# EXPORT: Specific Schema
# -----------------------------------------------
schema_export() {
    local SCHEMA=$1
    echo "Exporting schema: $SCHEMA"

    $ORACLE_HOME/bin/expdp $DB_USER/$DB_PASS \
        SCHEMAS=$SCHEMA \
        DIRECTORY=DATA_PUMP_DIR \
        DUMPFILE=${SCHEMA}_export_$DATE.dmp \
        LOGFILE=${SCHEMA}_export_$DATE.log \
        COMPRESSION=ALL

    echo "✅ Schema Export Completed: ${SCHEMA}_export_$DATE.dmp"
}

# -----------------------------------------------
# EXPORT: Specific Tables
# -----------------------------------------------
table_export() {
    local SCHEMA=$1
    local TABLES=$2  # Comma separated: "EMP,DEPT,ORDERS"
    echo "Exporting tables: $TABLES"

    $ORACLE_HOME/bin/expdp $DB_USER/$DB_PASS \
        TABLES=$SCHEMA.$TABLES \
        DIRECTORY=DATA_PUMP_DIR \
        DUMPFILE=tables_export_$DATE.dmp \
        LOGFILE=tables_export_$DATE.log \
        COMPRESSION=ALL

    echo "✅ Table Export Completed"
}

# -----------------------------------------------
# IMPORT: Full Database
# -----------------------------------------------
full_import() {
    local DUMPFILE=$1
    echo "Starting Full Database Import from: $DUMPFILE"

    $ORACLE_HOME/bin/impdp $DB_USER/$DB_PASS \
        FULL=Y \
        DIRECTORY=DATA_PUMP_DIR \
        DUMPFILE=$DUMPFILE \
        LOGFILE=full_import_$DATE.log \
        TABLE_EXISTS_ACTION=REPLACE \
        PARALLEL=4

    echo "✅ Full Import Completed"
}

# -----------------------------------------------
# IMPORT: Schema with Remap
# -----------------------------------------------
schema_remap_import() {
    local DUMPFILE=$1
    local SOURCE_SCHEMA=$2
    local TARGET_SCHEMA=$3

    echo "Importing $SOURCE_SCHEMA → $TARGET_SCHEMA"

    $ORACLE_HOME/bin/impdp $DB_USER/$DB_PASS \
        SCHEMAS=$SOURCE_SCHEMA \
        DIRECTORY=DATA_PUMP_DIR \
        DUMPFILE=$DUMPFILE \
        LOGFILE=schema_import_$DATE.log \
        REMAP_SCHEMA=$SOURCE_SCHEMA:$TARGET_SCHEMA \
        TABLE_EXISTS_ACTION=REPLACE

    echo "✅ Schema Import with Remap Completed"
}

# Main
case "$1" in
    "full_export")   full_export ;;
    "schema_export") schema_export "$2" ;;
    "table_export")  table_export "$2" "$3" ;;
    "full_import")   full_import "$2" ;;
    "schema_import") schema_remap_import "$2" "$3" "$4" ;;
    *)
        echo "Usage:"
        echo "  $0 full_export"
        echo "  $0 schema_export SCHEMA_NAME"
        echo "  $0 table_export SCHEMA TABLE1,TABLE2"
        echo "  $0 full_import dumpfile.dmp"
        echo "  $0 schema_import dumpfile.dmp SOURCE TARGET"
        ;;
esac
