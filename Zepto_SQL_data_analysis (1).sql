-- ==========================================================
-- 📌 Drop and create main product table: ZEPTO
-- ==========================================================
DROP TABLE IF EXISTS zepto;

CREATE TABLE zepto (
  sku_id SERIAL PRIMARY KEY,
  category VARCHAR(120),
  name VARCHAR(150) NOT NULL,
  mrp NUMERIC(8,2),
  discountPercent NUMERIC(5,2),
  availableQuantity INTEGER,
  discountedSellingPrice NUMERIC(8,2),
  weightInGms INTEGER,
  outOfStock BOOLEAN,	
  quantity INTEGER,
  supplier_id INTEGER
);

-- ==========================================================
-- 📌 Data Exploration
-- ==========================================================

-- 📌 Q1. What is the total number of rows?
SELECT COUNT(*) FROM zepto;

-- 📌 Q2. Show a sample of 10 rows.
SELECT * FROM zepto
LIMIT 10;

-- 📌 Q3. Find rows with NULL values.
SELECT * FROM zepto
WHERE name IS NULL OR
      category IS NULL OR
      mrp IS NULL OR
      discountPercent IS NULL OR
      discountedSellingPrice IS NULL OR
      weightInGms IS NULL OR
      availableQuantity IS NULL OR
      outOfStock IS NULL OR
      quantity IS NULL;

-- 📌 Q4. What are the distinct product categories?
SELECT DISTINCT category
FROM zepto
ORDER BY category;

-- 📌 Q5. Count of products in stock vs out of stock.
SELECT outOfStock, COUNT(sku_id)
FROM zepto
GROUP BY outOfStock;

-- 📌 Q6. Which product names appear more than once?
SELECT name, COUNT(sku_id) AS num_skus
FROM zepto
GROUP BY name
HAVING COUNT(sku_id) > 1
ORDER BY num_skus DESC;

-- ==========================================================
-- 📌 Data Cleaning
-- ==========================================================

-- 📌 Q7. Which products have MRP or selling price = 0?
SELECT * FROM zepto
WHERE mrp = 0 OR discountedSellingPrice = 0;

-- 📌 Q8. Delete products with MRP = 0.
DELETE FROM zepto
WHERE mrp = 0;

-- 📌 Q9. Convert paise to rupees for MRP and selling price.
UPDATE zepto
SET mrp = mrp / 100.0,
    discountedSellingPrice = discountedSellingPrice / 100.0;

-- 📌 Q10. Check conversion.
SELECT mrp, discountedSellingPrice FROM zepto;

-- ==========================================================
-- 📌 Basic Analysis
-- ==========================================================

-- 📌 Q11. Top 10 best-value products by discount %.
SELECT name, mrp, discountPercent
FROM zepto
ORDER BY discountPercent DESC
LIMIT 10;

-- 📌 Q12. Products with High MRP (> ₹300) but Out of Stock.
SELECT name, mrp
FROM zepto
WHERE outOfStock = TRUE AND mrp > 300
ORDER BY mrp DESC;

-- 📌 Q13. Estimated revenue per category.
SELECT category,
       SUM(discountedSellingPrice * availableQuantity) AS total_revenue
FROM zepto
GROUP BY category
ORDER BY total_revenue DESC;

-- 📌 Q14. Products with MRP > ₹500 & discount < 10%.
SELECT name, mrp, discountPercent
FROM zepto
WHERE mrp > 500 AND discountPercent < 10
ORDER BY mrp DESC, discountPercent DESC;

-- 📌 Q15. Top 5 categories with highest avg discount %.
SELECT category,
       ROUND(AVG(discountPercent),2) AS avg_discount
FROM zepto
GROUP BY category
ORDER BY avg_discount DESC
LIMIT 5;

-- 📌 Q16. Price per gram for products >100g.
SELECT name, weightInGms, discountedSellingPrice,
       ROUND(discountedSellingPrice/weightInGms,2) AS price_per_gram
FROM zepto
WHERE weightInGms >= 100
ORDER BY price_per_gram;

-- 📌 Q17. Group products into Low, Medium, Bulk by weight.
SELECT name, weightInGms,
       CASE WHEN weightInGms < 1000 THEN 'Low'
            WHEN weightInGms < 5000 THEN 'Medium'
            ELSE 'Bulk'
       END AS weight_category
FROM zepto;

-- 📌 Q18. Total inventory weight per category.
SELECT category,
       SUM(weightInGms * availableQuantity) AS total_weight
FROM zepto
GROUP BY category
ORDER BY total_weight DESC;

-- ==========================================================
-- 📌 Extra Tables: Orders & Suppliers for Joins & Advanced Queries
-- ==========================================================

-- 📌 Drop and create Orders table.
DROP TABLE IF EXISTS orders;

CREATE TABLE orders (
  order_id SERIAL PRIMARY KEY,
  sku_id INTEGER REFERENCES zepto(sku_id),
  order_date DATE,
  quantity_ordered INTEGER,
  order_amount NUMERIC(10,2)
);

-- 📌 Drop and create Suppliers table.
DROP TABLE IF EXISTS suppliers;

CREATE TABLE suppliers (
  supplier_id SERIAL PRIMARY KEY,
  name VARCHAR(100),
  region VARCHAR(50)
);

-- ==========================================================
-- 📌 Advanced Analysis with Joins, CTEs, Windows
-- ==========================================================

-- 📌 Q19. Monthly sales trend + 3-month moving average.
SELECT DATE_TRUNC('month', order_date) AS month,
       SUM(order_amount) AS monthly_sales,
       ROUND(AVG(SUM(order_amount)) OVER (
         ORDER BY DATE_TRUNC('month', order_date)
         ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
       ), 2) AS moving_avg_3m
FROM orders
GROUP BY month
ORDER BY month;

-- 📌 Q20. SKUs with MRP above 75th percentile in category.
SELECT name, category, mrp,
       PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY mrp)
       OVER (PARTITION BY category) AS p75_category_mrp
FROM zepto
WHERE mrp > PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY mrp) OVER (PARTITION BY category);

-- 📌 Q21. Products with discount % outliers (+/- 2 std dev).
SELECT name, discountPercent
FROM zepto
WHERE discountPercent > (SELECT AVG(discountPercent) + 2 * STDDEV(discountPercent) FROM zepto)
   OR discountPercent < (SELECT AVG(discountPercent) - 2 * STDDEV(discountPercent) FROM zepto);

-- 📌 Q22. Orders count, sales, high-value orders per category.
SELECT z.category,
       COUNT(DISTINCT o.order_id) AS num_orders,
       SUM(o.order_amount) AS total_sales,
       SUM(CASE WHEN o.order_amount > 500 THEN 1 ELSE 0 END) AS high_value_orders
FROM zepto z
JOIN orders o ON z.sku_id = o.sku_id
GROUP BY z.category
ORDER BY total_sales DESC;

-- 📌 Q23. SKUs with increasing month-over-month orders.
WITH Monthly AS (
  SELECT sku_id,
         DATE_TRUNC('month', order_date) AS order_month,
         SUM(quantity_ordered) AS monthly_qty
  FROM orders
  GROUP BY sku_id, order_month
),
Ranked AS (
  SELECT *, LAG(monthly_qty) OVER (PARTITION BY sku_id ORDER BY order_month) AS prev_qty
  FROM Monthly
)
SELECT z.name, r.order_month, r.monthly_qty, r.prev_qty
FROM Ranked r
JOIN zepto z ON z.sku_id = r.sku_id
WHERE r.monthly_qty > COALESCE(prev_qty,0);

-- 📌 Q24. Order sequence number per SKU.
SELECT o.sku_id, o.order_id, o.order_date, o.quantity_ordered,
       ROW_NUMBER() OVER (PARTITION BY o.sku_id ORDER BY o.order_date) AS order_seq
FROM orders o;

-- 📌 Q25. Flag Best Sellers (total units > 500).
SELECT z.name, SUM(o.quantity_ordered) AS total_units,
       CASE WHEN SUM(o.quantity_ordered) > 500 THEN 'Best Seller' ELSE 'Normal' END AS status
FROM zepto z
JOIN orders o ON z.sku_id = o.sku_id
GROUP BY z.name
ORDER BY total_units DESC;

-- 📌 Q26. Daily sales & cumulative per category.
SELECT z.category, o.order_date,
       SUM(o.order_amount) AS daily_sales,
       SUM(SUM(o.order_amount)) OVER (PARTITION BY z.category ORDER BY o.order_date) AS cumulative_sales
FROM zepto z
JOIN orders o ON z.sku_id = o.sku_id
GROUP BY z.category, o.order_date;

-- 📌 Q27. Orders with weight group (Light, Medium, Heavy).
SELECT o.order_id, z.name, z.weightInGms,
       CASE WHEN z.weightInGms < 1000 THEN 'Light'
            WHEN z.weightInGms < 5000 THEN 'Medium'
            ELSE 'Heavy'
       END AS weight_group, o.order_amount
FROM orders o
JOIN zepto z ON z.sku_id = o.sku_id;

-- 📌 Q28. Top-selling SKU per category.
SELECT category, name, total_units
FROM (
  SELECT z.category, z.name, SUM(o.quantity_ordered) AS total_units,
         ROW_NUMBER() OVER (PARTITION BY z.category ORDER BY SUM(o.quantity_ordered) DESC) AS rn
  FROM zepto z JOIN orders o ON z.sku_id = o.sku_id
  GROUP BY z.category, z.name
) t
WHERE rn = 1;

-- 📌 Q29. SKU % share of total stock value.
SELECT name,
       discountedSellingPrice * availableQuantity AS sku_value,
       ROUND(100.0 * (discountedSellingPrice * availableQuantity) /
         SUM(discountedSellingPrice * availableQuantity) OVER (), 2) AS pct_share
FROM zepto;

-- 📌 Q30. Cumulative stock weight as SKUs are added.
SELECT name, weightInGms * availableQuantity AS total_weight,
       SUM(weightInGms * availableQuantity) OVER (ORDER BY sku_id) AS running_weight
FROM zepto;

-- 📌 Q31. Supplier avg discount > 15%.
SELECT s.name AS supplier_name, ROUND(AVG(z.discountPercent),2) AS avg_discount
FROM zepto z JOIN suppliers s ON z.supplier_id = s.supplier_id
GROUP BY s.name
HAVING AVG(z.discountPercent) > 15;

-- 📌 Q32. Region’s suppliers with highest total stock value.
SELECT s.region, SUM(z.discountedSellingPrice * z.availableQuantity) AS total_value
FROM zepto z JOIN suppliers s ON z.supplier_id = s.supplier_id
GROUP BY s.region
ORDER BY total_value DESC;

