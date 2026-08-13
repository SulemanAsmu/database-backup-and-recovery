# database-backup-and-recovery
Professional Database Backup and Recovery Scripts - Full, Incremental, Differential Backups and Recovery Strategies | Oracle | MySQL | PostgreSQL | MariaDB | MSSQL

# 💾 Database Backup and Recovery - DBA Portfolio

## 📋 Description
This repository contains professional backup and recovery scripts
that demonstrate my experience in protecting and recovering
databases across multiple platforms.

## 🛠️ Database Platforms Covered

| Database             | Version  | Backup Methods                              |
|---------------------|----------|---------------------------------------------|
| Oracle               | 19c/21c  | RMAN, Data Pump, Cold Backup                |
| MySQL                | 8.0      | mysqldump, mysqlpump, XtraBackup            |
| PostgreSQL           | 15       | pg_dump, pg_basebackup, PITR                |
| MariaDB              | 10.6     | mysqldump, Mariabackup                      |
| Microsoft SQL Server | 2019     | Full, Differential, Transaction Log         |

## 📁 Backup Types Covered

### Full Backup
- Complete copy of entire database
- Longest to run but simplest to restore
- Foundation for all other backup types

### Incremental Backup
- Only changes since last backup
- Faster and smaller than full backup
- Requires full backup to restore

### Differential Backup
- Changes since last FULL backup
- Balance between full and incremental
- Faster restore than incremental

### Transaction Log Backup
- Records of all transactions
- Enables Point-In-Time Recovery (PITR)
- Minimal data loss in case of failure

## 🏆 Backup Strategy Used
