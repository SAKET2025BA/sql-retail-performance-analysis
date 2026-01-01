--Step 1 — Table Profiling

--1A) Confirm table exists + get row count
SELECT COUNT(*) AS row_count
FROM public.superstore_orders;

--1B) See the column names + data types
SELECT
  column_name,
  data_type
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'superstore_orders'
ORDER BY ordinal_position;

--1C) Quick sample (to understand what each field looks like)
SELECT *
FROM public.superstore_orders
LIMIT 25;

--1D) Check duplicates using the most likely “order line” key
SELECT
  order_id,
  product_id,
  COUNT(*) AS cnt
FROM public.superstore_orders
GROUP BY order_id, product_id
HAVING COUNT(*) > 1
ORDER BY cnt DESC
LIMIT 25;

--Step 2: Data Quality Checks
--2A) Check for NULLs in critical fields
SELECT
  COUNT(*) FILTER (WHERE order_id IS NULL) AS null_order_id,
  COUNT(*) FILTER (WHERE order_date IS NULL) AS null_order_date,
  COUNT(*) FILTER (WHERE sales IS NULL) AS null_sales,
  COUNT(*) FILTER (WHERE quantity IS NULL) AS null_quantity,
  COUNT(*) FILTER (WHERE profit IS NULL) AS null_profit
FROM public.superstore_orders;

--2B) Check negative or zero values (red flags)
SELECT
  COUNT(*) FILTER (WHERE sales <= 0)    AS bad_sales,
  COUNT(*) FILTER (WHERE quantity <= 0) AS bad_quantity
FROM public.superstore_orders;

--2C) Profit sanity (losses are allowed — but let’s quantify)
SELECT
  COUNT(*) FILTER (WHERE profit < 0)  AS loss_orders,
  COUNT(*) FILTER (WHERE profit = 0)  AS zero_profit_orders,
  COUNT(*) FILTER (WHERE profit > 0)  AS profit_orders
FROM public.superstore_orders;

--2D) Date logic check (shipping before order?)
SELECT COUNT(*) AS invalid_ship_dates
FROM public.superstore_orders
WHERE ship_date < order_date;

--Step 3: Build the Clean Analytical Layer (CTE)
WITH base_orders AS (
  SELECT
    row_id,
    order_id,
    order_date,
    ship_date,
    ship_mode,
    customer_id,
    customer_name,
    segment,
    country,
    product_id,
	CASE
      WHEN ship_date >= order_date THEN (ship_date - order_date)
      ELSE 0
    END AS shipping_days
  FROM public.superstore_orders
)
SELECT *
FROM base_orders
LIMIT 20;

--Step 4: KPI Layer (Sales, Profit, Margin, Shipping)
WITH base_orders AS (
  SELECT
    row_id,
    order_id,
    order_date,
    ship_date,
    ship_mode,
    customer_id,
    customer_name,
    segment,
    country,
    product_id,
    sales,
    profit,
    quantity,
    discount,
    CASE
      WHEN ship_date >= order_date THEN (ship_date - order_date)
      ELSE 0
    END AS shipping_days
  FROM public.superstore_orders
),
kpis AS (
  SELECT
    *,
    CASE
      WHEN sales = 0 THEN NULL
      ELSE ROUND((profit / sales)::numeric, 4)
    END AS profit_margin
  FROM base_orders
)
SELECT
  COUNT(*) AS rows,
  COUNT(DISTINCT order_id) AS orders,
  ROUND(SUM(sales)::numeric, 2) AS total_sales,
  ROUND(SUM(profit)::numeric, 2) AS total_profit,
  ROUND(AVG(profit_margin)::numeric, 4) AS avg_margin,
  ROUND(AVG(shipping_days)::numeric, 2) AS avg_shipping_days
FROM kpis;

-- Step 6 (Business Question 1)
--Q1: Which customer segment drives profit — by volume or by margin?
WITH base_orders AS (
  SELECT
    row_id,
    order_id,
    order_date,
    ship_date,
    ship_mode,
    customer_id,
    customer_name,
    segment,
    country,
    product_id,
    sales,
    profit,
    quantity,
    discount,
    CASE
      WHEN ship_date >= order_date THEN (ship_date - order_date)
      ELSE 0
    END AS shipping_days
  FROM public.superstore_orders
)
SELECT
  segment,
  COUNT(*) AS line_items,
  COUNT(DISTINCT order_id) AS orders,
  ROUND(SUM(sales)::numeric, 2) AS total_sales,
  ROUND(SUM(profit)::numeric, 2) AS total_profit,
  ROUND((SUM(profit) / NULLIF(SUM(sales), 0))::numeric, 4) AS overall_margin,
  ROUND(AVG(discount)::numeric, 4) AS avg_discount
FROM base_orders
GROUP BY segment
ORDER BY total_profit DESC;


--Q2: Are discounts driving losses?
WITH base_orders AS (
  SELECT
    sales,
    profit,
    discount
  FROM public.superstore_orders
)
SELECT
  ROUND(discount::numeric, 2) AS discount_bucket,
  COUNT(*) AS line_items,
  ROUND(SUM(sales)::numeric, 2) AS total_sales,
  ROUND(SUM(profit)::numeric, 2) AS total_profit,
  ROUND((SUM(profit) / NULLIF(SUM(sales), 0))::numeric, 4) AS margin
FROM base_orders
GROUP BY ROUND(discount::numeric, 2)
ORDER BY discount_bucket;

--Q3: Which ship modes are operationally efficient AND profitable?
WITH base_orders AS (
  SELECT
    ship_mode,
    sales,
    profit,
    CASE
      WHEN ship_date >= order_date THEN (ship_date - order_date)
      ELSE 0
    END AS shipping_days
  FROM public.superstore_orders
)
SELECT
  ship_mode,
  COUNT(*) AS line_items,
  ROUND(SUM(sales)::numeric, 2) AS total_sales,
  ROUND(SUM(profit)::numeric, 2) AS total_profit,
  ROUND((SUM(profit) / NULLIF(SUM(sales), 0))::numeric, 4) AS margin,
  ROUND(AVG(shipping_days)::numeric, 2) AS avg_shipping_days,
  PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY shipping_days) AS median_shipping_days
FROM base_orders
GROUP BY ship_mode
ORDER BY total_profit DESC;
