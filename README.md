# DBT Analytics Workshop 🚀

A comprehensive dbt (data build tool) learning project designed for hands-on practice with data transformations, testing, and quality assurance. This repository contains a complete dbt project structure with real-world examples including streaming data analysis, customer cohorts, and subscription analytics using **DuckDB** as the analytical database.

## 🎯 Project Purpose

This project serves as a learning playground and QA environment for:
- **Data Modeling**: Building dimensional models and analytics tables
- **Testing**: Implementing data quality tests and validation
- **Seeds**: Managing reference data and lookup tables
- **Macros**: Creating reusable SQL functions
- **Documentation**: Generating and maintaining data lineage
- **DuckDB Integration**: Fast analytics with embedded database

## 📊 What's Inside

### Models
- `churn_analysis.sql` - Customer churn prediction and analysis
- `cohort_analysis.sql` - Customer cohort behavior tracking
- Dimensional models for streaming analytics

### Seeds
- `events.csv` - Sample event data for testing
- `subscriptions.csv` - Customer subscription reference data
- Additional lookup tables

### Tests
- Schema tests for data validation
- Custom data quality checks
- Referential integrity tests

## 🚀 Quick Start

### Prerequisites
- Python 3.7+
- dbt-core and dbt-duckdb installed

### Setup Instructions

1. **Clone the repository**
   ```bash
   git clone https://github.com/J0BS013/dbt-analytical-streaming-data.git
   cd dbt-analytical-streaming-data
   ```

2. **Create virtual environment (recommended)**
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

3. **Install dependencies**
   ```bash
   pip install -r requirements.txt
   # OR install manually:
   pip install dbt-core dbt-duckdb
   ```

4. **Configure DuckDB connection**
   ```bash
   # The project is pre-configured to use DuckDB
   # Check profiles.yml for connection details
   dbt debug  # Test your connection
   ```

5. **Load seed data**
   ```bash
   dbt seed
   ```

6. **Run the models**
   ```bash
   dbt run
   ```

7. **Run tests**
   ```bash
   dbt test
   ```

8. **Generate documentation**
   ```bash
   dbt docs generate
   dbt docs serve
   ```

## 🧪 Testing Examples

### Basic Commands
```bash
# Run all models
dbt run

# Run specific model
dbt run --models churn_analysis

# Run models with dependencies
dbt run --models +churn_analysis

# Run downstream models
dbt run --models churn_analysis+

# Run tests only
dbt test

# Test specific model
dbt test --models cohort_analysis
```

### Advanced Testing
```bash
# Run models with full refresh
dbt run --full-refresh

# Test data freshness
dbt source freshness

# Run specific tag
dbt run --models tag:analytics

# Dry run (compile only)
dbt compile

# Run and test together
dbt build
```

### Data Quality Validation
```bash
# Run schema tests
dbt test --select test_type:schema

# Run data tests
dbt test --select test_type:data

# Generate and serve documentation
dbt docs generate && dbt docs serve

# Check model freshness
dbt source freshness --select source:raw_data
```

### DuckDB Specific Commands
```bash
# Connect directly to DuckDB
duckdb streaming_project.duckdb

# Query your models directly
duckdb streaming_project.duckdb -c "SELECT * FROM churn_analysis LIMIT 10;"

# Export results
dbt run && duckdb streaming_project.duckdb -c "COPY (SELECT * FROM cohort_analysis) TO 'output.csv' (HEADER, DELIMITER ',')"
```

## 📁 Project Structure

```
streaming_project/
├── analyses/           # Analytical SQL files
├── macros/            # Reusable SQL macros
├── models/            # dbt models
│   ├── staging/       # Raw data transformations
│   ├── intermediate/  # Business logic layer  
│   └── marts/         # Final analytics tables
├── seeds/             # CSV reference data
│   ├── events.csv
│   └── subscriptions.csv
├── snapshots/         # SCD Type 2 tables
├── tests/             # Custom data tests
├── target/            # Compiled SQL (git ignored)
├── dbt_project.yml    # Project configuration
├── profiles.yml       # Database connections
├── requirements.txt   # Python dependencies
└── README.md          # This file
```

## 🦆 Why DuckDB?

This project uses **DuckDB** as the analytical database because:
- **Fast**: Optimized for analytical workloads
- **Embedded**: No server setup required
- **SQL Compatible**: Standard SQL with analytical extensions
- **Portable**: Single file database
- **Python Integration**: Great for data science workflows



### Manual requirements.txt
```txt
dbt-core>=1.6.0
dbt-duckdb>=1.6.0
```

## 🧪 Sample Queries to Test

After running `dbt run`, try these queries in DuckDB:

```sql
-- Check model results
SELECT * FROM churn_analysis LIMIT 5;

-- Analyze cohort data
SELECT 
    cohort_month,
    COUNT(*) as customers,
    AVG(revenue) as avg_revenue
FROM cohort_analysis 
GROUP BY cohort_month 
ORDER BY cohort_month;

-- Data quality check
SELECT 
    COUNT(*) as total_records,
    COUNT(DISTINCT customer_id) as unique_customers
FROM events;
```

## 📚 Resources

- [dbt Documentation](https://docs.getdbt.com/)
- [dbt-DuckDB Documentation](https://github.com/duckdb/dbt-duckdb)
- [DuckDB Documentation](https://duckdb.org/docs/)
- [dbt Learn](https://learn.getdbt.com/)
- [dbt Community](https://community.getdbt.com/)

## 📄 License

This project is open source and available under the [MIT License](LICENSE).

---

**Happy modeling with DuckDB!** 🦆🎉
