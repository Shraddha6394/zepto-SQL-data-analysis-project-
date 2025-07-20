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

Created a PostgreSQL table to structure the data:

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
