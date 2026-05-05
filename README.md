# 📦 Operations Performance Metrics Dashboard
### A MySQL Portfolio Project for Data Analyst Job Applications

---

## 📌 Project Overview

This project simulates a real-world **operations analytics** use case for a logistics or e-commerce business.

Using MySQL, I designed a relational database schema, seeded it with realistic order data, and wrote a series of analytical queries — from core KPIs to advanced window function analysis — to measure and monitor operational performance.

This project demonstrates my ability to translate business requirements into structured SQL code and produce insights that operations and management teams can act on.

---

## 🗂️ Repository Structure

```
ops_dashboard/
│
├── 01_schema.sql          # Database and table creation
├── 02_sample_data.sql     # 50 rows of realistic sample data
├── 03_kpi_metrics.sql     # Core KPI calculations
├── 04_advanced_analysis.sql  # Window functions, CTEs, rolling averages
├── 05_business_kpis.sql   # Executive-level business KPI queries
└── README.md              # This file
```

---

## 🎯 KPIs Analysed

| KPI | Description |
|-----|-------------|
| **Average Processing Time** | Mean time (mins) from order placement to delivery |
| **Order Fulfillment Rate** | % of orders successfully delivered |
| **Cancellation Rate** | % of orders cancelled before delivery |
| **SLA Compliance Rate** | % of deliveries completed within 60-minute SLA |
| **Average Order Value (AOV)** | Mean revenue per delivered order |
| **Orders per Location** | Volume and performance breakdown by city |
| **Orders per Courier** | Workload and success rate per courier |
| **Daily Delivery Success Rate** | Day-by-day delivery outcomes with target status |
| **Weekly Delivery Time Trend** | Week-over-week speed and SLA trends |
| **Failed Order Analysis** | Failure hotspots by location and courier |
| **Courier Performance Ranking** | Composite ranked leaderboard with categories |
| **Peak Hour Analysis** | Intra-day demand and success rate patterns |

---

## 🛠️ SQL Concepts Demonstrated

| Concept | Used In |
|---------|---------|
| `CREATE TABLE`, `PRIMARY KEY`, `CHECK` constraints | `01_schema.sql` |
| `INSERT INTO`, `ENUM` data types | `02_sample_data.sql` |
| `COUNT`, `SUM`, `AVG`, `MIN`, `MAX` | `03_kpi_metrics.sql` |
| `CASE WHEN` expressions | `03_kpi_metrics.sql`, `05_business_kpis.sql` |
| `GROUP BY`, `HAVING` | `03_kpi_metrics.sql`, `05_business_kpis.sql` |
| `TIMESTAMPDIFF()` | `03_kpi_metrics.sql`, `04_advanced_analysis.sql` |
| `RANK()`, `DENSE_RANK()` window functions | `04_advanced_analysis.sql`, `05_business_kpis.sql` |
| `LAG()` window function | `04_advanced_analysis.sql` |
| Rolling averages (`ROWS BETWEEN`) | `04_advanced_analysis.sql` |
| Cumulative totals (`UNBOUNDED PRECEDING`) | `04_advanced_analysis.sql` |
| Subqueries and derived tables | `04_advanced_analysis.sql` |
| `NULLIF()` for safe division | `03_kpi_metrics.sql`, `04_advanced_analysis.sql` |
| `WEEK()`, `DATE()`, `HOUR()` date functions | `05_business_kpis.sql` |

---

## 🗃️ Dataset Structure

```
Table: orders
├── order_id        INT (PK, AUTO_INCREMENT)
├── order_time      DATETIME
├── delivery_time   DATETIME (NULL if not delivered)
├── order_value     DECIMAL(10,2)
├── location        VARCHAR(100)
├── courier_id      VARCHAR(20)
└── order_status    ENUM('Delivered', 'Cancelled', 'Failed')
```

**Sample size:** 50 rows spanning 4 weeks across 5 cities and 5 couriers.

---

## 💡 Business Value

This dashboard directly supports the following operational objectives:

- **Reduce delivery failures** by identifying underperforming couriers and problem locations
- **Monitor SLA compliance** to protect customer satisfaction and client contracts
- **Optimise courier deployment** using peak-hour and workload analysis
- **Track revenue performance** week-over-week to support business planning
- **Prioritise escalations** using traffic-light tiering (GREEN / AMBER / RED)

---

## 🚀 How to Run

1. Make sure you have **MySQL 8.0+** installed (window functions require 8.0+).
2. Run the files in order:

```sql
SOURCE 01_schema.sql;
SOURCE 02_sample_data.sql;
SOURCE 03_kpi_metrics.sql;
SOURCE 04_advanced_analysis.sql;
SOURCE 05_business_kpis.sql;
```

Or open each file individually in **MySQL Workbench** and execute in sequence.

---

## 👤 Author

**[Your Name]**
Data Analyst | MySQL · Python · Power BI  
[LinkedIn Profile] | [GitHub Profile]

---

## 📄 License

This project is open source and available for use in personal portfolios and learning.
