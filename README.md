# Wide World Importers Analysis

**By Mariam A. Korany**

---

## Database
This analysis project explores the **Wide World Importers database**, a sample dataset designed by Microsoft, representing a company with extensive **sales, purchasing, and warehouse** data. The project focuses on identifying patterns, customer segments, and operational inefficiencies to support strategic decision-making.

The analysis covers the following key data areas:
- **Warehouse Schema**: Stock items, stock transactions, and warehouse data.
- **Sales Schema**: Customer transactions, invoices, orders, and special deals.
- **Purchasing Schema**: Purchase orders, suppliers, and supplier transactions.
- **Application Schema**: Information related to cities, countries, delivery methods, transaction types, and more.

---

## Objective
The primary goal was to derive actionable insights from sales and inventory data to help the company improve customer targeting, enhance warehouse efficiency, and optimize resource allocation.

---

## Summary of Findings

### Inventory Management
- **Insight**: Strong sales were observed, totaling $198.04M, but costs were high at $112.31M.
- **Recommendation**: Automate processes and optimize the supply chain to reduce operational costs.

### Customer Segmentation
- **Insight**: Adults emerged as the largest customer segment, with preferences for black and white products.
- **Recommendation**: Focus marketing on adult-oriented items and introduce more variations in sizes and colors.

### Warehouse Efficiency
- **Insight**: Uneven stock distribution was noted, with a high concentration in bin location D-3.
- **Recommendation**: Implement a Warehouse Management System (WMS) to ensure balanced inventory and real-time adjustments.

### Sales Operations
- **Insight**: Wide World Importers serves 655 cities, primarily through novelty shops, yet only employs 10 salespersons.
- **Recommendation**: Increase the number of sales representatives to adequately cover the market and support business growth.

### Backorder Management
- **Insight**: High backorder volume (7.54K) with an average fulfillment time of 4.31 days.
- **Recommendation**: Improve demand forecasting and streamline the fulfillment process to reduce wait times.

---

## Methodology

- **SQL**: Used to explore the database, identifying and addressing null values in each schema and parsing JSON columns. Relevant SQL queries can be found [here](SQL_Queries.sql).
- **Python**: Applied for data cleaning, including deduplication, and extracting missing attributes like color information from stock item names. Python scripts are available [here](Python_PreprocessingandConnectingSQLServer.ipynb).
- **Power BI**: Utilized for visualization by importing both SQL queries or tables and Python code.

---

## Project Files

- **[SQL Queries](SQL_Queries.sql)**
- **[Python Notebooks](Python_PreprocessingandConnectingSQLServer.ipynb)**
- **[Images](./Images)**: Visual representations of analysis findings.

---

Thank you for reviewing this project! Please feel free to reach out with any questions or feedback.
