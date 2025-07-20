# 🛒 Zepto E-commerce SQL Data Analysis Project

This is a complete SQL-based data analysis project built using an e-commerce inventory dataset. The goal is to simulate real-world analytics tasks performed by data analysts in retail and quick-commerce industries.

---

## 📌 Project Objective

The purpose of this project is to:
- Create and manage an inventory database
- Clean and prepare the dataset for analysis
- Perform exploratory data analysis using SQL
- Derive meaningful business insights from the data

---

## 📁 Dataset Overview

The dataset contains e-commerce inventory information across various categories. Each row represents a unique product SKU (Stock Keeping Unit). The data includes:

- `sku_id`: Unique identifier  
- `name`: Product name  
- `category`: Product type (e.g., Fruits, Snacks, etc.)  
- `mrp`: Maximum Retail Price (in ₹)  
- `discountPercent`: Discount offered  
- `discountedSellingPrice`: Final price after discount  
- `availableQuantity`: Quantity available  
- `weightInGms`: Weight of product  
- `outOfStock`: Boolean flag for availability  
- `quantity`: Quantity per package  

---

## 🔧 Project Steps

### 1. Database and Table Creation

```sql
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
  quantity INTEGER
);
```

---

### 2. Data Import

```sql
\copy zepto(category,name,mrp,discountPercent,availableQuantity,
            discountedSellingPrice,weightInGms,outOfStock,quantity)
FROM 'data/zepto_v2.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', QUOTE '"', ENCODING 'UTF8');
```

---

### 3. Data Cleaning

```sql
-- Remove rows where price is zero
DELETE FROM zepto
WHERE mrp = 0 OR discountedSellingPrice = 0;

-- Convert paise to rupees (if required)
UPDATE zepto
SET mrp = mrp / 100,
    discountedSellingPrice = discountedSellingPrice / 100
WHERE mrp > 1000;
```

---

### 4. Exploratory Data Analysis

```sql
-- Total number of records
SELECT COUNT(*) FROM zepto;

-- Check for nulls
SELECT 
  SUM(CASE WHEN category IS NULL THEN 1 ELSE 0 END) AS null_category,
  SUM(CASE WHEN name IS NULL THEN 1 ELSE 0 END) AS null_name,
  SUM(CASE WHEN mrp IS NULL THEN 1 ELSE 0 END) AS null_mrp,
  SUM(CASE WHEN discountedSellingPrice IS NULL THEN 1 ELSE 0 END) AS null_discountedSellingPrice
FROM zepto;

-- Distinct product categories
SELECT DISTINCT category FROM zepto;

-- In-stock vs out-of-stock
SELECT outOfStock, COUNT(*) FROM zepto GROUP BY outOfStock;

-- Duplicate product names
SELECT name, COUNT(*) 
FROM zepto
GROUP BY name
HAVING COUNT(*) > 1
ORDER BY COUNT(*) DESC;
```

---

### 5. Business Insights via SQL

```sql
-- Top 10 highest discounts
SELECT name, category, mrp, discountedSellingPrice, discountPercent
FROM zepto
ORDER BY discountPercent DESC
LIMIT 10;

-- High MRP items that are out of stock
SELECT name, mrp, outOfStock
FROM zepto
WHERE outOfStock = true AND mrp > 500
ORDER BY mrp DESC;

-- Estimated revenue by category
SELECT category, 
       SUM(discountedSellingPrice * availableQuantity) AS estimated_revenue
FROM zepto
WHERE outOfStock = false
GROUP BY category
ORDER BY estimated_revenue DESC;

-- Expensive products with minimal discount
SELECT name, mrp, discountPercent
FROM zepto
WHERE mrp > 500 AND discountPercent < 10
ORDER BY mrp DESC;

-- Top 5 categories with highest average discount
SELECT category, 
       ROUND(AVG(discountPercent), 2) AS avg_discount
FROM zepto
GROUP BY category
ORDER BY avg_discount DESC
LIMIT 5;

-- Price per gram
SELECT name, 
       discountedSellingPrice, 
       weightInGms, 
       ROUND(discountedSellingPrice::numeric / weightInGms, 2) AS price_per_gram
FROM zepto
WHERE weightInGms > 0
ORDER BY price_per_gram ASC
LIMIT 10;

-- Categorize by weight
SELECT name, weightInGms,
       CASE 
         WHEN weightInGms <= 500 THEN 'Low'
         WHEN weightInGms BETWEEN 501 AND 1500 THEN 'Medium'
         ELSE 'Bulk'
       END AS weight_category
FROM zepto;

-- Total weight by category
SELECT category, SUM(weightInGms * availableQuantity) AS total_weight_grams
FROM zepto
WHERE outOfStock = false
GROUP BY category
ORDER BY total_weight_grams DESC;
```

---

## 🖥️ Tools & Technologies

- SQL (PostgreSQL)  
- pgAdmin  
- CSV Data Handling  
- Data Cleaning and Transformation  
- Business-Focused Querying  

---

## 📂 Folder Structure

```
📁 Zepto-SQL-Analysis/
│
├── zepto_SQL_analysis.sql        # All SQL queries
├── zepto_v2.csv                  # Dataset
└── README.md                     # Project Documentation
```

