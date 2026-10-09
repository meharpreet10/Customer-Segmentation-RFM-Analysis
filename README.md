
## Customer Segmentation & RFM Analysis: Retention Budget Allocation

Tools: MySQL 8 | Power BI | Excel (data prep) Data: UCI Online Retail II (UK online retailer, Dec 2009 - Dec 2011, about 1M transactions)

## Business problem

An e-commerce company has about 5,850 identified customers and a GBP 50,000 retention budget for the next quarter. Spending is currently uniform or based on gut feel, which wastes money on customers who would buy anyway and on customers who are already gone.

Question: Which customer segments should we spend on, how much, and with what tactic, to maximise incremental profit?

## Approach
Cleaned about 1M raw transactions (guests, cancellations, bad prices and quantities, non-product codes).
Segmented customers with RFM scoring into 7 groups.
Backtested the segments: built them as of 31 Mar 2011 and measured who actually bought again in the next 6 months (Apr - Sep 2011).
Modelled ROI per segment using the backtest rates plus stated assumptions for uplift, margin and cost.
Allocated the budget in proportion to net profit, with caps on low-value segments.
Stress-tested the answer with low, base and high campaign-uplift scenarios.
Built a 3-page Power BI dashboard on top of the MySQL tables.

## Key findings
Finding	Evidence
Revenue is highly concentrated	Champions are 21% of customers but 68% of revenue. Champions + Loyal are 44% of customers and 83% of revenue.
Champions would buy anyway	88.1% repurchased in the next 6 months with no campaign. Discounts here mostly give away margin.
Lost customers are not zero	21.5% still bought again, but they spend little (about GBP 113 per customer over 6 months).
Cant Lose Them is the biggest opportunity	Only 35.8% came back, but they have the highest AOV (about GBP 694) and are 205 customers.
Money at risk	At Risk + Cant Lose Them = 711 customers and about GBP 1.5M of past revenue now going quiet.
The ranking is robust	Cant Lose Them is #1 and New is #2 in low, base and high uplift scenarios.

## Recommended budget split (GBP 50,000)
Segment	Tactic	Budget	Share
Cant Lose Them	Personal outreach + offer	GBP 11,096	22.2%
New	Second-purchase incentive	GBP 10,438	20.9%
At Risk	Win-back offer	GBP 9,562	19.1%
Loyal	Loyalty points	GBP 9,251	18.5%
Champions	Early access and perks (no discounts)	GBP 3,853	7.7%
Needs Attention	Free-shipping nudge	GBP 3,298	6.6%
Lost	Cheap automated email	GBP 2,500	5.0%

Rule used: budget is proportional to expected net profit, with caps for Lost (5%), Champions (10%) and Needs Attention (10%). Money freed by the caps goes to the four uncapped segments, in proportion to their profit. The caps are judgement calls, not data results.

## Dashboard

### Page 1: Customer Overview
Customers, revenue, and the Pareto effect by segment.

![Customer Overview](https://github.com/meharpreet10/Customer-Segmentation-RFM-Analysis/blob/main/Customer%20Overview.png?raw=true)

### Page 2: Backtest
Repurchase rate, revenue per customer and AOV by segment.

![Backtest](https://github.com/meharpreet10/Customer-Segmentation-RFM-Analysis/blob/main/Backtest.png?raw=true)

### Page 3: ROI and Budget
Net profit, low/base/high scenarios, and the action plan table (segment, tactic, budget).

![ROI and Budget](https://github.com/meharpreet10/Customer-Segmentation-RFM-Analysis/blob/main/ROI%20and%20Budget.png?raw=true)

## Data preparation and cleaning
The two sheets of the Excel file were appended in Power Query. The overlapping days (1 - 9 Dec 2010) were removed to avoid double counting. The result was saved as CSV and loaded into MySQL as text columns, then converted to proper types.
DISTINCT removed exact duplicate rows (raw rows 1,044,848 -> 1,033,036 rows).
Rows removed from the analysis table clean_sales:
No customer ID: 235,151 rows (22.8%)
Cancellations (invoice starts with C): 19,104 rows
Zero or negative price: 6,037 rows
Zero or negative quantity: 22,496 rows (includes the cancellations)
Stock codes not starting with 5 digits (postage, fees, discounts, test rows)
Final analysis table: 776,577 rows, 5,852 customers, about GBP 17.07M revenue.

## Method details
Snapshot date: 2011-12-10 (day after the last transaction).
Recency and Monetary: scored 1 - 5 using NTILE(5).
Frequency: scored with fixed thresholds (1, 2, 3-4, 5-8, 9+ orders), because many customers share the same order count and NTILE would split them arbitrarily.
Segments: champions, loyal, new, needs attention, cant lose them, at risk, lost (rules in the SQL file).
Backtest: segments built using only data before 2011-04-01. Behaviour measured from 2011-04-01 to 2011-09-30.
ROI formula: net profit = customers x uplift x margin x AOV - customers x cost per customer

## Assumptions (not measured from data)
Input	Value
Gross margin	30%
Uplift (extra customers won back)	1% Champions, 3% Loyal, 8% New, 5% Needs Attention, 7% At Risk, 10% Cant Lose Them, 2% Lost
Contact cost per customer	GBP 0.30 - 3.00, depending on the tactic
Scenarios	Uplift x 0.5 (low), x 1.0 (base), x 1.5 (high)

The dataset contains no campaign history, so uplift and cost are assumptions, tested through the scenarios.

## Limitations
No real campaign or A/B test data. Uplift is assumed, not measured.
Discount cost is not modelled. ROI covers contact cost only, so it is an upper bound.
About 23% of rows had no customer ID and were excluded. Results apply to identified customers only.
Many buyers appear to be businesses (some placed over 100 orders), so behaviour differs from consumer e-commerce.
One retailer with a strong Nov/Dec peak. The backtest window (Apr - Sep 2011) excludes the peak, which may understate repurchase.
Profit is assumed to scale linearly with spend. In practice returns shrink as spend rises.
Cap values (5% and 10%) are judgement calls.

## Project Files

| File | Description |
|---|---|
| [SQL script](https://github.com/meharpreet10/Customer-Segmentation-RFM-Analysis/blob/main/RFM%20PROJECT%202_SQL.sql) | Full MySQL code: cleaning, RFM segments, backtest, ROI model, budget split, sensitivity analysis |
| [Power BI dashboard (PDF)](https://github.com/meharpreet10/Customer-Segmentation-RFM-Analysis/blob/main/RFM%20project%202%20powerbi.pdf) | 3-page dashboard export |

## Connect with Me

**Meharpreet Kaur**
Aspiring Data / Business Analyst

[LinkedIn](https://www.linkedin.com/in/meharpreet-kaur-59bb75356/)  |  [GitHub](https://github.com/meharpreet10)
