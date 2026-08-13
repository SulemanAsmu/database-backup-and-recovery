-- =============================================
-- Database:    Oracle 19c/21c
-- Author:      Suleman
-- Description: Database Recovery Scenarios
--              Common recovery situations
--              and how to handle them
-- =============================================

-- =============================================
-- SCENARIO 1: Recover a Dropped Table
--             Using Flashback (No backup needed!)
-- =============================================

-- Check if table is in Recycle Bin
SELECT
    OBJECT_NAME,
    ORIGINAL_NAME,
    OPERATION,
    TYPE,
    DROPTIME
FROM USER_RECYCLEBIN
WHERE ORIGINAL_NAME = 'EMPLOYEES'
ORDER BY DROPTIME DESC;

-- Restore table from Recycle Bin
FLASHBACK TABLE Employees TO BEFORE DROP;

-- Restore with a new name (if original still exists)
FLASHBACK TABLE Employees
    TO BEFORE DROP RENAME TO Employees_Recovered;

-- =============================================
-- SCENARIO 2: Flashback Table to Past Time
--             Undo accidental DELETE/UPDATE
-- =============================================

-- Step 1: Check current data
SELECT COUNT(*) FROM Employees;

-- Step 2: Enable row movement (required for flashback)
ALTER TABLE Employees ENABLE ROW MOVEMENT;

-- Step 3: Flashback to specific time
FLASHBACK TABLE Employees
    TO TIMESTAMP (SYSDATE - INTERVAL '30' MINUTE);

-- Step 4: Verify data restored
SELECT COUNT(*) FROM Employees;

-- Step 5: Disable row movement after flashback
ALTER TABLE Employees DISABLE ROW MOVEMENT;

-- =============================================
-- SCENARIO 3: Point-In-Time Query
--             Check what data looked like at a time
-- =============================================

-- View data as it was 1 hour ago
SELECT *
FROM Employees
AS OF TIMESTAMP (SYSDATE - INTERVAL '1' HOUR)
WHERE DepartmentID = 1;

-- Compare current vs past data
SELECT 'CURRENT' AS data_source, COUNT(*) AS emp_count
FROM Employees
WHERE Status = 'Active'
UNION ALL
SELECT 'ONE HOUR AGO', COUNT(*)
FROM Employees AS OF TIMESTAMP (SYSDATE - INTERVAL '1' HOUR)
WHERE Status = 'Active';

-- =============================================
-- SCENARIO 4: Recover Specific Rows
--             Using Flashback Query
-- =============================================

-- Find deleted rows
SELECT *
FROM Employees
AS OF TIMESTAMP (SYSDATE - INTERVAL '15' MINUTE)
WHERE EmployeeID NOT IN (
    SELECT EmployeeID FROM Employees
);

-- Re-insert the deleted rows
INSERT INTO Employees
SELECT *
FROM Employees
AS OF TIMESTAMP (SYSDATE - INTERVAL '15' MINUTE)
WHERE EmployeeID NOT IN (
    SELECT EmployeeID FROM Employees
);

COMMIT;
