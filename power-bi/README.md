# Power BI report setup

The report uses the six-row aggregate CSV from notebook Step 37. Each row represents one ranking on one held-out date. [Report data](../outputs/aml_test_ranking_results.csv) · [Reviewed PDF](../outputs/AML%20Transaction%20Review.pdf)

1. Import the CSV in Power BI Desktop. Set `ranking` to Text, `transaction_date` to Date and `reviewed`, `caught`, `missed` and `false_positives` to Whole number. Import the shared [Portfolio - Blue and Orange theme](Portfolio_Base_Theme.json) before styling the visuals.
2. Use a 1920 × 1080 canvas. The saved visual positions are rounded to whole pixels below.

   | Visual | Height | Width | Horizontal | Vertical |
   | --- | ---: | ---: | ---: | ---: |
   | Page header | 110 | 1000 | 48 | 40 |
   | Test date slicer | 104 | 360 | 1512 | 40 |
   | Caught chart | 560 | 1000 | 48 | 184 |
   | Comparison table | 272 | 800 | 1072 | 184 |

3. Add the page title **AML Transaction Review** in 24 pt bold Segoe UI. Add the context line in 14 pt regular.

   IBM synthetic AML data · Test window 9–10 September 2022 · 500 reviews per ranking per day

4. Use the raw `transaction_date` field in a dropdown slicer titled **Test date**. Build a horizontal clustered bar chart with `ranking` on the category axis and the sum of `caught` on the value axis. Set the title to **Simulated laundering transactions caught**, use outside-end data labels, set the value axis maximum to 60 and sort by caught descending.
5. Build a table grouped by ranking with the sums of reviewed, caught, missed and false positives. Use the headings **Ranking**, **Reviewed**, **Caught**, **Missed** and **False Positives**. Sort by **Caught** descending. Turn off the total row because the rankings each use their own queue.

Check that the chart and table both respond to the date slicer.

| Test date | Reviewed per ranking | Amount only caught | Amount + history caught | Decision tree caught |
| --- | ---: | ---: | ---: | ---: |
| 9 September 2022 | 500 | 1 | 1 | 4 |
| 10 September 2022 | 500 | 6 | 0 | 49 |
| All | 1,000 | 7 | 1 | 53 |

Save and export the page to PDF with **All** selected.
