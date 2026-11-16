# Two alerts from the simulated review queue

These examples came from the frozen depth-4 tree's 500-slot review queue for 9 September 2022. Source row IDs link the notes to Step 36 of the [analysis notebook](../01_aml_ranking.ipynb).

Both senders had zero recorded outgoing transactions in the prior 24 hours. The tree routed both transactions to leaf 12, where the history percentile was at most 13.51% and the amount percentile was above 82.86% and at most 88.15%. Thresholds are rounded. Of the 10,709 training rows in this leaf, 264 carried the simulator's laundering label, giving both alerts the same score of about 2.47%. Equal scores were ordered by timestamp and then source row ID.

## Row 3411041 · Labelled laundering

At 00:25, the sender paid **53,292.35 Saudi riyals**. That amount was at the **85.10th percentile** of Saudi riyal payments in training. The amount and prior activity put the transaction in leaf 12. It took **slot 31** in the day's queue. The simulator assigned label `1`, so this alert counted as a capture in the held-out evaluation.

## Row 4217219 · False positive

At 00:01, the sender paid **18,605.46 US dollars**, at the **87.67th percentile** of US dollar payments in training. The transaction reached the same leaf and received the same score as row 3411041. Its earlier timestamp put it ahead of row 3411041 when the scores tied. It took **slot 1**. The simulator assigned label `0`, so the review slot counted as a false positive.
