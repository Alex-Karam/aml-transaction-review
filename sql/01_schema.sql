-- Step 01: Check which directory MySQL can read for file imports.
SELECT
    VERSION() AS mysql_version,
    @@GLOBAL.secure_file_priv AS secure_file_priv;
########################################################

-- Step 02: Create the schema for the AML Transaction Review project.
CREATE SCHEMA IF NOT EXISTS aml_transaction_review;
########################################################

-- Step 03. Create the raw staging table in CSV column order.
-- MySQL assigns source_row_id during import. The CSV supplies the other columns.
CREATE TABLE IF NOT EXISTS aml_transaction_review.transactions_raw (
    source_row_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    transaction_timestamp TEXT,
    from_bank TEXT,
    from_account TEXT,
    to_bank TEXT,
    to_account TEXT,
    amount_received TEXT,
    receiving_currency TEXT,
    amount_paid TEXT,
    payment_currency TEXT,
    payment_format TEXT,
    is_laundering TEXT
) ENGINE = InnoDB DEFAULT CHARACTER SET = utf8mb4;
########################################################

-- Step 04. Load the verified CSV into the empty staging table.
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/HI-Small_Trans.csv'
INTO TABLE aml_transaction_review.transactions_raw
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(
    transaction_timestamp,
    from_bank,
    from_account,
    to_bank,
    to_account,
    amount_received,
    receiving_currency,
    amount_paid,
    payment_currency,
    payment_format,
    is_laundering
);
########################################################

-- Step 05. Reconcile the staging table with the source CSV.
SELECT
    COUNT(*) AS loaded_rows,
    MIN(source_row_id) AS first_id,
    MAX(source_row_id) AS last_id
FROM aml_transaction_review.transactions_raw;
########################################################



















































