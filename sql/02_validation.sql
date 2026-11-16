-- Step 06. Check timestamp coverage and format before conversion.
SELECT
    MIN(transaction_timestamp) AS first_timestamp,
    MAX(transaction_timestamp) AS last_timestamp,
    COUNT(DISTINCT LEFT(transaction_timestamp, 10)) AS observed_dates,
    SUM(NOT REGEXP_LIKE(
        COALESCE(transaction_timestamp, ''),
        '^[0-9]{4}/[0-9]{2}/[0-9]{2} [0-9]{2}:[0-9]{2}$'
    )) AS missing_or_bad_format
FROM aml_transaction_review.transactions_raw;
########################################################

-- Step 07. Check for missing fields used by the rankings.
SELECT
    SUM(COALESCE(TRIM(from_bank), '') = '') AS missing_from_bank,
    SUM(COALESCE(TRIM(from_account), '') = '') AS missing_from_account,
    SUM(COALESCE(TRIM(amount_paid), '') = '') AS missing_amount_paid,
    SUM(COALESCE(TRIM(payment_currency), '') = '') AS missing_payment_currency
FROM aml_transaction_review.transactions_raw;
########################################################

-- Step 08. Check the format and precision of amount_paid.
SELECT
    SUM(NOT REGEXP_LIKE(
        COALESCE(amount_paid, ''),
        '^[0-9]+([.][0-9]+)?$'
    )) AS bad_amount_format,
    MAX(CHAR_LENGTH(SUBSTRING_INDEX(amount_paid, '.', 1))) AS max_whole_digits,
    MAX(CASE
        WHEN INSTR(amount_paid, '.') > 0
            THEN CHAR_LENGTH(SUBSTRING_INDEX(amount_paid, '.', -1))
        ELSE 0
    END) AS max_fractional_digits
FROM aml_transaction_review.transactions_raw;
########################################################

-- Step 09. Check text widths, currency coverage, and label validity.
SELECT
    MAX(CHAR_LENGTH(from_bank)) AS max_bank_length,
    MAX(CHAR_LENGTH(from_account)) AS max_account_length,
    MAX(CHAR_LENGTH(payment_currency)) AS max_currency_length,
    COUNT(DISTINCT payment_currency) AS payment_currencies,
    SUM(COALESCE(is_laundering, '') NOT IN ('0', '1')) AS invalid_labels
FROM aml_transaction_review.transactions_raw;
########################################################






























































