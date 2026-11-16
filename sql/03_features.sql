-- Step 10. Create the typed table for the ranking inputs.
CREATE TABLE IF NOT EXISTS aml_transaction_review.transactions (
    source_row_id BIGINT UNSIGNED NOT NULL PRIMARY KEY,
    transaction_timestamp DATETIME NOT NULL,
    from_bank VARCHAR(7) NOT NULL,
    from_account VARCHAR(9) NOT NULL,
    amount_paid DECIMAL(19,6) NOT NULL,
    payment_currency VARCHAR(17) NOT NULL,
    is_laundering TINYINT UNSIGNED NOT NULL,
    CONSTRAINT chk_transactions_is_laundering
        CHECK (is_laundering IN (0, 1))
) ENGINE = InnoDB DEFAULT CHARACTER SET = ascii COLLATE = ascii_bin;
########################################################

-- Step 11. Load the typed transaction table.
INSERT INTO aml_transaction_review.transactions (
    source_row_id,
    transaction_timestamp,
    from_bank,
    from_account,
    amount_paid,
    payment_currency,
    is_laundering
)
SELECT
    source_row_id,
    STR_TO_DATE(transaction_timestamp, '%Y/%m/%d %H:%i'),
    from_bank,
    from_account,
    CAST(amount_paid AS DECIMAL(19,6)),
    payment_currency,
    CAST(is_laundering AS UNSIGNED)
FROM aml_transaction_review.transactions_raw;
########################################################

-- Step 12. Reconcile the typed table with the source.
SELECT
    COUNT(*) AS typed_rows,
    MIN(source_row_id) AS first_id,
    MAX(source_row_id) AS last_id,
    MIN(transaction_timestamp) AS first_timestamp,
    MAX(transaction_timestamp) AS last_timestamp,
    COUNT(DISTINCT payment_currency) AS payment_currencies
FROM aml_transaction_review.transactions;
########################################################

-- Step 13. Index the sender key and transaction time.
CREATE INDEX idx_transactions_sender_time
ON aml_transaction_review.transactions (
    from_bank,
    from_account,
    transaction_timestamp
);
########################################################

-- Step 14. Trace the prior 24-hour history for one transaction.
SELECT
    target.source_row_id AS target_id,
    target.transaction_timestamp AS target_time,
    earlier.source_row_id AS prior_id,
    earlier.transaction_timestamp AS prior_time
FROM aml_transaction_review.transactions AS target
JOIN aml_transaction_review.transactions AS earlier
    ON earlier.from_bank = target.from_bank
   AND earlier.from_account = target.from_account
   AND earlier.transaction_timestamp >= DATE_SUB(
       target.transaction_timestamp, INTERVAL 24 HOUR
   )
   AND earlier.transaction_timestamp < target.transaction_timestamp
WHERE target.source_row_id = 1431160
ORDER BY earlier.transaction_timestamp, earlier.source_row_id;
########################################################

-- Step 15. Check the rolling count on two transactions in the same minute.
WITH sender_history AS (
    SELECT
        source_row_id,
        transaction_timestamp,
        COUNT(*) OVER (
            PARTITION BY from_bank, from_account
            ORDER BY transaction_timestamp
            RANGE BETWEEN INTERVAL 24 HOUR PRECEDING
                      AND INTERVAL 1 MINUTE PRECEDING
        ) AS prior_24h_count
    FROM aml_transaction_review.transactions
    WHERE from_bank = '013862'
      AND from_account = '803262600'
)
SELECT source_row_id, transaction_timestamp, prior_24h_count
FROM sender_history
WHERE source_row_id IN (1431160, 1431162)
ORDER BY source_row_id;
########################################################

-- Step 16. Save the prior 24-hour count for every transaction.
CREATE TABLE aml_transaction_review.transaction_history (
    source_row_id BIGINT UNSIGNED NOT NULL PRIMARY KEY,
    prior_24h_count INT UNSIGNED NOT NULL
) ENGINE = InnoDB
AS
SELECT
    source_row_id,
    COUNT(*) OVER (
        PARTITION BY from_bank, from_account
        ORDER BY transaction_timestamp
        RANGE BETWEEN INTERVAL 24 HOUR PRECEDING
                  AND INTERVAL 1 MINUTE PRECEDING
    ) AS prior_24h_count
FROM aml_transaction_review.transactions;
########################################################

-- Step 17. Verify the saved history table.
SELECT
    COUNT(*) AS history_rows,
    MIN(source_row_id) AS first_id,
    MAX(source_row_id) AS last_id,
    MAX(CASE WHEN source_row_id = 1431160 THEN prior_24h_count END) AS count_1431160,
    MAX(CASE WHEN source_row_id = 1431162 THEN prior_24h_count END) AS count_1431162
FROM aml_transaction_review.transaction_history;
########################################################

-- Step 18. Count transactions by date before choosing the time windows.
SELECT
    DATE(transaction_timestamp) AS transaction_date,
    COUNT(*) AS transaction_count
FROM aml_transaction_review.transactions
GROUP BY transaction_date
ORDER BY transaction_date;
########################################################

-- Step 19. Join the ranking inputs and assign chronological splits.
CREATE OR REPLACE VIEW aml_transaction_review.v_ranking_inputs AS
SELECT
    tx.source_row_id,
    tx.transaction_timestamp,
    CASE
        WHEN tx.transaction_timestamp < '2022-09-07 00:00:00' THEN 'train'
        WHEN tx.transaction_timestamp < '2022-09-09 00:00:00' THEN 'validation'
        ELSE 'test'
    END AS split_name,
    tx.amount_paid,
    tx.payment_currency,
    history.prior_24h_count
FROM aml_transaction_review.transactions AS tx
JOIN aml_transaction_review.transaction_history AS history
    ON history.source_row_id = tx.source_row_id
WHERE tx.transaction_timestamp >= '2022-09-02 00:00:00'
  AND tx.transaction_timestamp < '2022-09-11 00:00:00';
########################################################

-- Step 20. Reconcile the ranking inputs by split.
SELECT
    split_name,
    COUNT(*) AS transaction_count,
    MIN(transaction_timestamp) AS first_timestamp,
    MAX(transaction_timestamp) AS last_timestamp,
    COUNT(DISTINCT payment_currency) AS payment_currencies
FROM aml_transaction_review.v_ranking_inputs
GROUP BY split_name
ORDER BY first_timestamp;
########################################################

-- Step 21. Export the training and validation data for Python.
SELECT
    inputs.source_row_id,
    inputs.transaction_timestamp,
    inputs.split_name,
    inputs.amount_paid,
    inputs.payment_currency,
    inputs.prior_24h_count,
    tx.is_laundering
FROM aml_transaction_review.v_ranking_inputs AS inputs
JOIN aml_transaction_review.transactions AS tx
    ON tx.source_row_id = inputs.source_row_id
WHERE inputs.split_name IN ('train', 'validation')
INTO OUTFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/aml_ranking_development.tsv'
CHARACTER SET utf8mb4
FIELDS TERMINATED BY '\t'
LINES TERMINATED BY '\n';
########################################################

-- Step 33. Export the held-out test window after freezing the rankings.
SELECT
    inputs.source_row_id,
    inputs.transaction_timestamp,
    inputs.split_name,
    inputs.amount_paid,
    inputs.payment_currency,
    inputs.prior_24h_count,
    tx.is_laundering
FROM aml_transaction_review.v_ranking_inputs AS inputs
JOIN aml_transaction_review.transactions AS tx
    ON tx.source_row_id = inputs.source_row_id
WHERE inputs.split_name = 'test'
INTO OUTFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/aml_ranking_test.tsv'
CHARACTER SET utf8mb4
FIELDS TERMINATED BY '\t'
LINES TERMINATED BY '\n';
########################################################


















































































