-- PROJECT : Customer Segmentation & RFM Analysis (E-commerce)
CREATE DATABASE online_retail;
USE online_retail;

CREATE TABLE online_retail_raw (
invoice	VARCHAR(10),
stock_code VARCHAR(10),
description	VARCHAR(255),
quantity VARCHAR(10),
invoice_date	VARCHAR(50),
price VARCHAR(20),
customer_id VARCHAR(20),
country VARCHAR(100));

SELECT COUNT(*) FROM online_retail_raw;

-- DATA CLEANING
CREATE TABLE online_retail_cleaned AS
SELECT DISTINCT 
TRIM(invoice) AS invoice_no,
TRIM(stock_code) AS stock_code,
TRIM(description) AS description,
CAST(TRIM(quantity) AS SIGNED) AS quantity, 
STR_TO_DATE(TRIM(invoice_date), '%Y-%m-%d %T') AS invoice_date,
CAST(TRIM(price) AS DECIMAL(10,2)) AS price,
CASE 
WHEN TRIM(customer_id) IN ('','NULL') OR TRIM(customer_id) IS NULL
THEN NULL
ELSE CAST(TRIM(customer_id) AS UNSIGNED)
END AS customer_id,
TRIM(country) AS country
FROM online_retail_raw;

-- Validation checks on the cleaned table
SELECT COUNT(*) FROM online_retail_cleaned;

SELECT COUNT(*) FROM online_retail_cleaned 
WHERE invoice_date IS NULL;

SELECT COUNT(*) FROM online_retail_cleaned 
WHERE customer_id = 0;

SELECT MIN(customer_id), MAX(customer_id) FROM online_retail_cleaned;

-- Count the rows we are about to remove
SELECT COUNT(*) FROM online_retail_cleaned
WHERE invoice_no like 'c%'
OR customer_id IS NULL
OR PRICE <= 0
OR quantity <=0;

CREATE TABLE clean_sales AS
SELECT *, 
quantity * price AS revenue
FROM online_retail_cleaned
WHERE customer_id IS NOT NULL
  AND invoice_no NOT LIKE 'C%'
  AND price > 0
  AND quantity > 0
  AND stock_code REGEXP '^[0-9]{5}';
  
-- Summary of the clean data
  SELECT COUNT(*) AS rows_kept,
       COUNT(DISTINCT customer_id) AS customers,
       ROUND(SUM(revenue)) AS total_revenue,
       MIN(invoice_date) AS first_date,
       MAX(invoice_date) AS last_date
FROM clean_sales;

-- RFM SEGMENTATION
-- Recency, Frequency, Monetary per customer
SELECT customer_id,
DATEDIFF('2011-12-10', MAX(invoice_date)) AS recency,
COUNT(distinct(invoice_no)) AS frequency,
ROUND(SUM(revenue), 2) AS monetary
FROM clean_sales
GROUP BY customer_id
ORDER BY monetary desc;

WITH rfm AS(
SELECT customer_id,
DATEDIFF('2011-12-10', MAX(invoice_date)) AS recency,
COUNT(DISTINCT(invoice_no)) AS frequency,
ROUND(SUM(revenue),2) AS monetary
FROM clean_sales
GROUP BY customer_id)
SELECT customer_id, recency, frequency, monetary,
NTILE(5) OVER (ORDER BY recency DESC) AS recency_score,
CASE 
WHEN frequency = 1 THEN 1
WHEN frequency = 2 THEN 2
WHEN frequency BETWEEN 3 AND 4 THEN 3
WHEN frequency BETWEEN 5 AND 8 THEN 4
ELSE 5
END AS frequency_score,
NTILE(5) OVER (ORDER BY monetary) AS monetary_score
FROM rfm
ORDER BY monetary DESC;

-- Assign each customer to one of 7 segments
CREATE TABLE rfm_category AS
WITH rfm AS(
SELECT customer_id,
DATEDIFF('2011-12-10', MAX(invoice_date)) AS recency,
COUNT(DISTINCT(invoice_no)) AS frequency,
ROUND(SUM(revenue),2) AS monetary
FROM clean_sales
GROUP BY customer_id),
score AS (
SELECT customer_id, recency, frequency, monetary,
NTILE(5) OVER (ORDER BY recency DESC) AS recency_score,
CASE 
WHEN frequency = 1 THEN 1
WHEN frequency = 2 THEN 2
WHEN frequency BETWEEN 3 AND 4 THEN 3
WHEN frequency BETWEEN 5 AND 8 THEN 4
ELSE 5
END AS frequency_score,
NTILE(5) OVER (ORDER BY monetary) AS monetary_score
FROM rfm ),
category_wise AS (
SELECT customer_id, recency, frequency, monetary, recency_score, frequency_score, monetary_score,
CASE
WHEN recency_score >= 4 AND frequency_score >= 4 AND monetary_score >= 4
THEN 'champions'
WHEN recency_score >= 3 AND frequency_score>= 3
THEN 'loyal'
WHEN recency_score >= 4 AND frequency_score <= 2
THEN 'new'
WHEN recency_score = 3 AND frequency_score <= 2
THEN 'needs attention'
WHEN recency_score <= 2 AND frequency_score >= 4 AND monetary_score >= 4
THEN 'cant lose them'
WHEN recency_score <=2 AND frequency_score>= 3
THEN 'at risk'
ELSE 'lost'
END AS category
FROM score)
SELECT * FROM category_wise;

SELECT category, 
COUNT(*) AS total_no,
ROUND(100*COUNT(*)/ SUM(COUNT(*)) OVER(),2) AS category_pct,
ROUND(SUM(monetary),2) AS money_they_bring,
ROUND(SUM(monetary)/SUM(SUM(monetary)) OVER() *100,2) AS money_they_bring_pct,
ROUND(SUM(monetary) / SUM(frequency), 2) AS aov,
ROUND(AVG(recency),1) AS avg_recency
FROM rfm_category
GROUP BY category
ORDER BY money_they_bring DESC;

-- BACKTEST (what did each segment do in the next 6 months?)
CREATE TABLE rfm_category_2 AS
WITH rfm AS(
SELECT customer_id,
DATEDIFF('2011-04-01', MAX(invoice_date)) AS recency,
COUNT(DISTINCT(invoice_no)) AS frequency,
ROUND(SUM(revenue),2) AS monetary
FROM clean_sales
WHERE invoice_date < '2011-04-01'
GROUP BY customer_id),
score AS (
SELECT customer_id, recency, frequency, monetary,
NTILE(5) OVER (ORDER BY recency DESC) AS recency_score,
CASE 
WHEN frequency = 1 THEN 1
WHEN frequency = 2 THEN 2
WHEN frequency BETWEEN 3 AND 4 THEN 3
WHEN frequency BETWEEN 5 AND 8 THEN 4
ELSE 5
END AS frequency_score,
NTILE(5) OVER (ORDER BY monetary) AS monetary_score
FROM rfm ),
category_wise AS (
SELECT customer_id, recency, frequency, monetary, recency_score, frequency_score, monetary_score,
CASE
WHEN recency_score >= 4 AND frequency_score >= 4 AND monetary_score >= 4
THEN 'champions'
WHEN recency_score >= 3 AND frequency_score>= 3
THEN 'loyal'
WHEN recency_score >= 4 AND frequency_score <= 2
THEN 'new'
WHEN recency_score = 3 AND frequency_score <= 2
THEN 'needs attention'
WHEN recency_score <= 2 AND frequency_score >= 4 AND monetary_score >= 4
THEN 'cant lose them'
WHEN recency_score <=2 AND frequency_score>= 3
THEN 'at risk'
ELSE 'lost'
END AS category
FROM score)
SELECT * FROM category_wise;

SELECT category,count(*)
FROM rfm_category_2
GROUP BY category;

-- Who bought between April and September 2011?
CREATE TABLE future_buyers AS
SELECT customer_id,
COUNT(DISTINCT(invoice_no)) AS future_orders,
ROUND(SUM(revenue), 2) AS future_revenue
FROM clean_sales
WHERE invoice_date >= '2011-04-01'
AND invoice_date < '2011-10-01'
GROUP BY customer_id;

SELECT COUNT(*) AS future_buyers FROM future_buyers;

-- Repurchase rate per segment 
CREATE TABLE future_buyer_results AS
SELECT r.category,
COUNT(r.customer_id) AS present_buyers,
COUNT(f.customer_id) AS bought_again, 
ROUND(COUNT(f.customer_id)/COUNT(r.customer_id) *100,1) AS repurchaser_pct,
ROUND(COALESCE(SUM(f.future_revenue),0)/COUNT(r.customer_id),1) AS revenue_per_customer,
ROUND(COALESCE(SUM(f.future_revenue),0)/SUM(f.future_orders),1) AS future_aov
FROM rfm_category_2 r
LEFT JOIN future_buyers f
ON r.customer_id = f.customer_id
GROUP BY r.category;

SELECT * FROM future_buyer_results
ORDER BY repurchaser_pct DESC;

-- ROI MODEL
CREATE TABLE assumptions (
category VARCHAR(30),
uplift DECIMAL(10,3),
cost_per_cust DECIMAL(10,2),
margin DECIMAL(10,2));
  
INSERT INTO assumptions VALUES
('champions', 0.010, 0.50, 0.30),
('loyal', 0.030, 1.00, 0.30),
('new', 0.080, 1.50, 0.30),
('needs attention', 0.050, 1.50, 0.30),
('at risk', 0.070, 2.00, 0.30),
('cant lose them', 0.100, 3.00, 0.30),
('lost', 0.020, 0.30, 0.30);

SELECT * FROM assumptions;

-- Profit and ROI per segment
CREATE TABLE category_wise_roi AS
SELECT r.category,
COUNT(*) AS total_customer,
a.uplift,
f.future_aov,
a.margin,
a.cost_per_cust,
ROUND(COUNT(*) * a.uplift * a.margin * f.future_aov , 2) AS extra_revenue,
ROUND(a.cost_per_cust * COUNT(*),2) AS total_cost,
ROUND((COUNT(*) * a.uplift * a.margin * f.future_aov) - (a.cost_per_cust * COUNT(*)),2) AS net_profit,
ROUND((((COUNT(*) * a.uplift * a.margin * f.future_aov) - (a.cost_per_cust * COUNT(*)))/ (a.cost_per_cust * COUNT(*))),2) AS roi
FROM rfm_category r
JOIN assumptions a ON r.category = a.category
JOIN future_buyer_results f ON r.category = f.category
GROUP BY r.category, a.uplift, a.margin, a.cost_per_cust, f.future_aov
ORDER BY roi DESC;

select * from category_wise_roi;

-- BUDGET ALLOCATION
SELECT category,
ROUND((net_profit/ SUM(net_profit) OVER() *100), 2) AS net_profit_share,
ROUND(((net_profit/ SUM(net_profit) OVER()) *50000),2) AS budget_share
FROM category_wise_roi
ORDER BY net_profit_share DESC;

-- Final budget split with caps
CREATE TABLE budget_split AS
WITH capping AS (
SELECT category,
net_profit,
net_profit/ SUM(net_profit) OVER() AS raw_share,
CASE 
WHEN category = 'lost' THEN 0.05
WHEN category = 'champions' THEN 0.10
WHEN category = 'needs attention' THEN 0.10
ELSE 1.00
END AS cap
FROM category_wise_roi),
capped_share AS (
SELECT *,
LEAST(cap, raw_share) AS capped
FROM capping),
final_share_category AS (
SELECT *,
CASE 
WHEN cap = 1
THEN net_profit / SUM(CASE WHEN cap = 1 THEN net_profit END) OVER ()
       * (1 - SUM(CASE WHEN cap < 1 THEN capped END) OVER ())
ELSE capped
END AS final_share
FROM capped_share)
SELECT category, 
ROUND(raw_share*100, 2) AS raw_share_pct,
ROUND(final_share*100, 2) AS final_share_pct,
ROUND(50000 * final_share,2) AS final_amount
FROM final_share_category
ORDER BY final_amount DESC;

-- SENSITIVITY ANALYSIS
CREATE TABLE sensitivity_results AS
SELECT c.category,
s.scenario,
s.multiplier,
ROUND((c.total_customer * c.uplift * c.future_aov * c.margin * s.multiplier) - c.total_cost, 2) AS net_profit
FROM category_wise_roi c
CROSS JOIN (
SELECT 'low' AS scenario, 0.5 AS multiplier
UNION ALL SELECT 'base', 1
UNION ALL SELECT 'high', 1.5) s;

SELECT * FROM sensitivity_results
ORDER BY scenario, net_profit DESC;