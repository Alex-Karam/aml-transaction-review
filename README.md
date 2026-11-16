# AML Transaction Review

## Question

Does prior account activity help a simulated analyst find more transactions labelled as laundering within the same review capacity?

The study compares three rankings on IBM’s synthetic transactions at **500 reviews per ranking per day**. MySQL builds the transaction history, Python evaluates the rankings on a later test window, and Power BI presents the held-out counts.

[Power BI report](outputs/AML%20Transaction%20Review.pdf) · [Daily results](outputs/aml_test_ranking_results.csv) · [Analysis notebook](01_aml_ranking.ipynb) · [Two analyst case notes](docs/case_notes.md)

## Data source and definitions

The source is `HI-Small_Trans.csv` from IBM Research’s synthetic AML dataset, Kaggle version 8. It has **5,078,345 transaction rows**, timestamps recorded to the minute and 15 payment currencies. The simulator assigns `Is Laundering` to each transaction. [Kaggle dataset](https://www.kaggle.com/datasets/ealtman2019/ibm-transactions-for-anti-money-laundering-aml)

Each day, each ranking selects its own queue from the same eligible transactions. A **capture** is a reviewed transaction with label `1`. A **miss** is a transaction with label `1` outside the queue. A **false positive** is a reviewed transaction with label `0`.

## Implementation decisions

MySQL preserves bank and account IDs as text and identifies a sender by the pair of IDs. For a transaction at time `t`, history counts the sender’s outgoing transactions in `[t − 24 hours, t)`. Transactions recorded in the same minute cannot be ordered within that minute, so they share the same history cutoff.

| Window in September 2022 | Dates | Transactions |
| --- | --- | ---: |
| History warm-up | 1 September | 1,114,921 |
| Training | 2–6 September | 2,134,000 |
| Validation | 7–8 September | 965,524 |
| Held-out test | 9–10 September | 862,792 |

The cutoffs were chosen using dates and transaction volumes. The 1,108 rows in the low-volume tail from 11–18 September are outside the scoring windows. Earlier transactions can contribute to history across window boundaries. The initial 24 hours supply history for the first scored date.

- **Amount only** ranks by paid-amount percentile within the payment currency, using training amounts as the reference.
- **Amount + history** combines the same amount percentile with a percentile of the prior 24-hour count, also measured against training. The chosen weights are 75% amount and 25% history.
- **Decision tree** learns from the same two percentiles. The selected tree has maximum depth 4, Gini splits and a minimum of 1,000 training rows per leaf. Its positive-class score orders the review queue.

Both percentiles give matching training values half weight. The 500-slot budget is about 0.10% of the median training day’s volume. At the end of each day, the simulation orders the queue by descending score, then ascending timestamp and source row ID. The score uses information available at the transaction time. Training references, weights, tree, dates, budget and tie rule were saved before the test export.

## Findings

The held-out window contains **956 transactions labelled as laundering** among 862,792 transactions.

| Ranking | Reviewed | Caught | Missed | False positives |
| --- | ---: | ---: | ---: | ---: |
| Amount only | 1,000 | 7 | 949 | 993 |
| Amount + history | 1,000 | 1 | 955 | 999 |
| Decision tree | 1,000 | 53 | 903 | 947 |

Giving history a fixed positive weight caught **six fewer** labelled transactions than the amount-only rule. The trained tree caught **46 more** than the baseline at the same review capacity.

Two transactions in the tree’s review queue received the same score and had different simulator labels. The case notes trace how the amount and history features put both in the same leaf and how timestamp resolved their tie. [Case notes](docs/case_notes.md)

## Validation

- The import, typed table and history table each contained **5,078,345 rows**. The source audit found nine repeated records beyond the first occurrence across the ten transaction fields. Each row kept its source ID.
- An independent check traced four eligible earlier transactions for a sample sender. The saved window calculation returned four for both of the sender’s transactions recorded in the same minute.
- Validation used 1,000 slots per ranking. History weights of 25%, 50% and 75% each caught zero, so the tie rule selected the lowest weight. The candidate tree depths 2, 3 and 4 caught 12, 12 and 58, respectively.
- Both TSV exports reconciled to the SQL split counts. The test IDs were unique and disjoint from development. For every ranking, caught plus missed equals 956, and caught plus false positives equals 1,000. The Power BI date filter matched the notebook on both days. The reviewed PDF matches the two-day totals.

## Limitations

The results apply to two held-out days from one synthetic release at a fixed daily capacity. History covers outgoing activity from the sender over one lookback window. The test compares the full tree ranking against the amount-only rule, so it leaves the contribution of history within the tree unmeasured.

## Reproduction

1. Download the version 8 source CSV, extract it if needed, and save it under `data/raw/HI-Small_Trans.csv`. The verified original is **475,664,283 bytes**. [Version 8 single-file download](https://www.kaggle.com/api/v1/datasets/download/ealtman2019/ibm-transactions-for-anti-money-laundering-aml/HI-Small_Trans.csv?datasetVersionNumber=8)

   SHA-256 `b19d39f515523373f991b689c07e11e7b0b95c17a2c27a87d91584ae16c5b040`.

2. In MySQL 8.0, start with a fresh schema. Run Step 01 to identify the server’s file import and export directory. Copy the CSV there and adapt the server-side paths in the SQL blocks to your setup. Run the rest of [schema and import](sql/01_schema.sql), [validation](sql/02_validation.sql) and Steps 10–21 of [features and exports](sql/03_features.sql). The recorded run used MySQL 8.0.46. Step 16 can outlast the client timeout. If the connection drops, reconnect and verify the table using Step 17 before retrying.
3. In a clean project copy, create `data/model/` and copy `aml_ranking_development.tsv` into it. Open the [notebook](01_aml_ranking.ipynb) from the project root in Jupyter with pandas, NumPy, scikit-learn and joblib. Run Steps 22–32 to save the fitted rankings. The saved notebook used Python 3.14.6.
4. Run SQL Step 33 after Step 32. Copy `aml_ranking_test.tsv` into `data/model/` and run notebook Steps 34–37. Step 37 creates the six-row [report CSV](outputs/aml_test_ranking_results.csv).
5. Import the report CSV into Power BI Desktop. Treat `transaction_date` as a date and the four counts as whole numbers. Add a labelled horizontal bar chart for the sum of caught by ranking and a table of all four counts by ranking. Sort both by caught descending. Set the date dropdown to **All** for the two-day view. Hide the table’s total across rankings because each ranking uses its own queue over the same population. [Reviewed report export](outputs/AML%20Transaction%20Review.pdf)

## Contribution and attribution

Alex Karam ran the SQL and notebook, checked the results and built the Power BI report. Codex assisted with the project design, code drafting, validation checks and documentation.

IBM Research published the synthetic data used here through Erik Altman’s Kaggle listing, which records the Community Data License Agreement, Sharing, Version 1.0. [Dataset attribution and licence](https://www.kaggle.com/datasets/ealtman2019/ibm-transactions-for-anti-money-laundering-aml)

Erik Altman, Jovan Blanuša, Luc von Niederhäusern, Béni Egressy, Andreea Anghel and Kubilay Atasu describe the generator in *Realistic Synthetic Financial Transactions for Anti-Money Laundering Models*. [arXiv:2306.16424v3](https://arxiv.org/abs/2306.16424v3)
