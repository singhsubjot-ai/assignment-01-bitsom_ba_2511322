# Data Lake Architecture

## Architecture Recommendation

**Recommendation: Data Lakehouse**

For a fast-growing food delivery startup that collects GPS logs, customer text reviews, payment transactions, and restaurant menu images, a **Data Lakehouse** is the optimal choice. Here are three specific reasons:

### 1. Multi-Format, Multi-Schema Data Cannot Be Force-Fit Into a Warehouse

A traditional **Data Warehouse** expects structured, pre-modelled data — rows and columns with fixed schemas. GPS logs are semi-structured time-series streams; customer reviews are unstructured text; restaurant menu images are binary blobs. A warehouse cannot store these natively — you would need to pre-process and discard most of the richness before loading. A **Data Lake** (raw object storage like S3/GCS) can store all four raw formats natively with zero transformation, but it provides no ACID transactions, no indexing, and no query optimisation — making it unsuitable alone for analytics and ML.

A **Data Lakehouse** (built on formats like Apache Iceberg or Delta Lake on top of object storage) gives you the best of both worlds: raw file storage for images and logs, combined with ACID-compliant, SQL-queryable, schema-governed tables for transactions and structured analytics. A single platform handles all four data types.

### 2. Mixed OLTP + OLAP Workloads on the Same Data

Payment transactions must support low-latency reads for fraud detection and refund processing (OLTP patterns), while the same data needs to feed monthly revenue dashboards and ML model training (OLAP patterns). A pure Data Lake forces you to build a separate query engine on top. A Data Lakehouse natively supports both: Delta Lake's time-travel and ACID writes make it transactionally safe, while its columnar Parquet storage and metadata indexing make analytical queries fast — no ETL pipeline needed to move data from a transactional store into a warehouse.

### 3. Native Support for AI/ML Pipelines

The startup's most valuable data assets — customer review text (for NLP sentiment and recommendation models) and GPS traces (for ETA and demand prediction models) — require ML pipelines that read raw data directly. A Data Warehouse forces structured aggregates only; full raw access requires exporting back to files. A Data Lakehouse stores raw data in open formats (Parquet, ORC, JSON) that ML frameworks (Spark MLlib, HuggingFace, TensorFlow Data) read natively, eliminating costly data-movement steps. Menu images can be stored in the object-storage layer alongside their metadata tables, enabling multi-modal models without architectural gymnastics.
