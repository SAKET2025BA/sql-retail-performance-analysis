--Step 1: Segment Contribution to Total Sales & Profit
WITH segment_kpis AS (
  SELECT
    segment,
    SUM(sales) AS total_sales,
    SUM(profit) AS total_profit
  FROM public.superstore_orders
  GROUP BY segment
)
SELECT
  segment,
  ROUND(total_sales::numeric, 2) AS total_sales,
  ROUND(total_profit::numeric, 2) AS total_profit,
  ROUND(
    total_sales / SUM(total_sales) OVER (),
    4
  ) AS sales_contribution_pct,
 ROUND(
    total_profit / SUM(total_profit) OVER (),
    4
  ) AS profit_contribution_pct
FROM segment_kpis
ORDER BY total_profit DESC;

--Step 2: Rank Products by Profit Within Each Category
WITH product_profit AS (
  SELECT
    category,
    product_id,
    SUM(profit) AS total_profit
  FROM public.superstore_orders
  GROUP BY category, product_id
)
SELECT
  category,
  product_id,
  ROUND(total_profit::numeric, 2) AS total_profit,
  RANK() OVER (
    PARTITION BY category
    ORDER BY total_profit DESC
  ) AS profit_rank
FROM product_profit
ORDER BY category, profit_rank;

--Step 3: Top 5 Products per Category
WITH product_profit AS (
  SELECT
    category,
    product_id,
    SUM(profit) AS total_profit
  FROM public.superstore_orders
  GROUP BY category, product_id
),
ranked AS (
  SELECT
    category,
    product_id,
    total_profit,
    ROW_NUMBER() OVER (
      PARTITION BY category
      ORDER BY total_profit DESC
    ) AS rn
  FROM product_profit
)
SELECT
  category,
  product_id,
  ROUND(total_profit::numeric, 2) AS total_profit,
  rn AS rank_in_category
FROM ranked
WHERE rn <= 5
ORDER BY category, rank_in_category;

/*Step 4: Pareto Analysis (Cumulative Profit Contribution)
Do a small number of products drive most of the profit?*/
WITH product_profit AS (
  SELECT
    product_id,
    SUM(profit) AS total_profit
  FROM public.superstore_orders
  GROUP BY product_id
),
ranked AS (
  SELECT
    product_id,
    total_profit,
    ROW_NUMBER() OVER (ORDER BY total_profit DESC) AS profit_rank,
    SUM(total_profit) OVER (
      ORDER BY total_profit DESC
      ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) / SUM(total_profit) OVER () AS cumulative_profit_pct
  FROM product_profit
)
SELECT
  profit_rank,
  ROUND(cumulative_profit_pct, 4) AS cumulative_profit_pct
FROM ranked
WHERE cumulative_profit_pct >= 0.80
ORDER BY profit_rank
LIMIT 1;

