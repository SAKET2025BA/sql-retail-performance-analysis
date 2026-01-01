# SQL Retail Performance Analysis (Superstore)

Retail performance analysis using SQL, CTEs, and window functions on Superstore sales data.

## Project Goals
- Build a clean analytical layer from raw retail orders
- Generate business KPIs for sales and profit performance
- Analyze customer segments, products, and categories
- Apply window functions for ranking and contribution analysis
- Perform Pareto (80/20) analysis to identify high-impact products

## Dataset
- Table: `public.superstore_orders`
- Source: SQL Online IDE (Superstore dataset)
- Contains order-level data including sales, profit, discounts, shipping details, products, and customer segments

> Note: Raw CSV is not uploaded; analysis is performed directly on the SQL table.

## Key SQL Techniques Used
- Common Table Expressions (CTEs)
- Aggregations and `GROUP BY`
- Window Functions (`RANK()`, `ROW_NUMBER()`, `SUM() OVER`)
- Percentage contribution analysis
- Pareto (80/20) cumulative profit analysis
- Business-focused query structuring

## Key Business Insights

### Segment Contribution Analysis
- Consumer segment contributes the highest share of total sales
- Home Office shows relatively higher profit contribution compared to its sales share
- Corporate segment delivers stable and consistent profitability

**Insight:**  
High sales volume does not always translate into the highest profitability.

### Product Profit Ranking
- Products are ranked within each category using window functions
- Top-performing products are clearly identified for focused decision-making

**Insight:**  
Category-level ranking enables better pricing, inventory, and promotion strategies.

### Pareto (80/20) Analysis
- Approximately the top ~164 products contribute ~80% of total profit

**Insight:**  
Profit is highly concentrated — optimizing top products yields maximum business impact.

## Repository Structure
sql/
├── README.md
├── Day_17_SQL_Mini_Project_Superstore_Analysis.sql
└── Day_18_SQL_Window_Functions_Pareto_Analysis.sql

## How to Use
1. Open any `.sql` file inside the `sql/` folder
2. Run queries sequentially in a PostgreSQL-compatible environment
3. Each script is fully commented and structured step-by-step

## Author
Saket Kumar Mallik  
MBA (Business Analytics)

