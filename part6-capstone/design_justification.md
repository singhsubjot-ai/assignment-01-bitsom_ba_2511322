# Capstone Design Justification — AI-Powered Hospital Data System

## Storage Systems

The four hospital goals each require a different storage paradigm:

**Goal 1 — Predict Patient Readmission Risk**  
Historical treatment data (lab results, diagnoses, discharge summaries, medications) must be stored in a **columnar data warehouse** (e.g., BigQuery, Snowflake, or Amazon Redshift). Readmission prediction requires training ML models on years of patient history across millions of rows. Columnar storage enables the fast full-column scans needed for feature extraction (average length of stay, comorbidity counts, re-admission intervals). An OLAP warehouse is the correct fit here, as these are batch analytical reads, not individual record lookups.

**Goal 2 — Plain-English Queries on Patient History**  
Doctor queries like *"Has this patient had a cardiac event before?"* require a **vector database** (e.g., Pinecone, Weaviate, or pgvector on PostgreSQL). Clinical notes and discharge summaries are embedded as dense vectors; the doctor's natural-language question is embedded at query time and the top-K semantically similar clinical chunks are retrieved via approximate nearest-neighbour search. The underlying clinical text lives in an **object store** (S3/GCS) as source documents. A pure relational lookup cannot handle paraphrased medical concepts.

**Goal 3 — Monthly Management Reports**  
Bed occupancy rates, department-wise costs, and length-of-stay summaries feed into the **same data warehouse** used for Goal 1. Reporting tools (Power BI, Looker, Tableau) connect directly to the warehouse via JDBC/ODBC. Pre-computed summary tables (materialized views) are refreshed nightly so dashboards load in sub-seconds.

**Goal 4 — Real-Time ICU Vitals Streaming**  
ICU monitors emit continuous time-series data (heart rate, SpO₂, blood pressure) at high frequency. This requires a **streaming message broker** (Apache Kafka) to ingest the feed, and a **time-series database** (InfluxDB or TimescaleDB) for millisecond-precision storage and querying. A relational OLTP database cannot sustain the write throughput of dozens of ICU devices firing at 1-second intervals.

The day-to-day clinical record system (patient registrations, admissions, prescriptions, billing) lives in a **relational OLTP database** (PostgreSQL or MySQL) that feeds all downstream systems via ETL pipelines.

---

## OLTP vs OLAP Boundary

The **OLTP boundary** ends at the hospital's operational PostgreSQL database. This database handles everything that requires immediate, consistent read-writes: patient check-ins, medication orders, billing transactions, and staff scheduling. It is optimised for low-latency single-row operations with full ACID guarantees.

The **OLAP boundary** begins at the ETL/ELT pipeline (Apache Airflow or dbt) that extracts data from PostgreSQL nightly and loads it into the columnar data warehouse. Once in the warehouse, data is immutable and optimised for analytical queries — GROUP BY over millions of rows, time-based aggregations, and ML feature pipelines. Real-time ICU data crosses a separate streaming boundary: Kafka consumers write vitals into InfluxDB continuously, and a separate batch job aggregates hourly summaries into the warehouse for inclusion in management reports.

The boundary is enforced architecturally: no BI tool or ML job reads directly from the OLTP database. This protects operational performance and prevents long-running analytical queries from locking clinical transactions.

---

## Trade-offs

**Trade-off: Complexity vs Integration**  
This architecture uses five distinct storage systems (PostgreSQL, Kafka, InfluxDB, Data Warehouse, Vector DB). The primary trade-off is **operational complexity**: each system requires separate deployment, monitoring, backup policies, and expertise. A hospital's IT team may lack Kafka or InfluxDB experience, and inter-system data pipelines introduce failure points — if the ETL job fails, management reports become stale.

**Mitigation:**  
The risk is mitigated by using a **managed cloud service layer** wherever possible: Amazon MSK (managed Kafka), Amazon Timestream (managed time-series), BigQuery (serverless warehouse), and Pinecone (managed vector DB). This eliminates infrastructure management and reduces the team's operational burden to pipeline logic only. A **unified data orchestration tool** (Apache Airflow with health-check DAGs) provides a single pane of glass for monitoring all pipelines, with alerting on failure. Finally, a phased rollout — starting with Goals 3 and 4 (reporting + streaming), then Goals 1 and 2 (ML + RAG) — reduces risk by validating each storage component before adding the next.
